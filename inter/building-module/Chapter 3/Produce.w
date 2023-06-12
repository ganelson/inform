[Produce::] Producing Inter.

Convenient machinery for generating individual Inter instructions.

@ This section provides a necessarily miscellaneous API for generating Inter
instructions: there are numerous different instructions, so there are many
different functions here, but there are few real ideas.

=
typedef struct site_production_data {
	struct code_insertion_point cip_stack[MAX_CIP_STACK_SIZE];
	int cip_sp;
	struct inter_bookmark function_body_start_bookmark;
	struct inter_bookmark function_locals_bookmark;
	struct inter_bookmark function_body_code_bookmark;
	struct inter_package *current_inter_function;
} site_production_data;

@ The bookmarks here are meaningless unless a function is being compiled, and
then they will be given explicit values, so it really doesn't matter what they
are initialised to. But to avoid any doubt, they will be set to the root of |I|,
even though they will never be used in that state.

=
void Produce::clear_site_data(inter_tree *I) {
	building_site *B = &(I->site);
	B->sprdata.function_body_start_bookmark = InterBookmark::at_start_of_this_repository(I);
	B->sprdata.function_locals_bookmark = InterBookmark::at_start_of_this_repository(I);
	B->sprdata.function_body_code_bookmark = InterBookmark::at_start_of_this_repository(I);
	B->sprdata.cip_sp = 0;
	B->sprdata.current_inter_function = NULL;
}

@h Code insertion points.
From the caller's point of view, the functions in this section just magically
know where in the Inter tree we want to generate code. Such a position is
called a //code_insertion_point// or CIP, and we must maintain it carefully.
We keep not just one but a stack of them, so that the caller can interrupt
one compilation activity, start another, and then resume the original.

For //inform7//, this stack in fact never exceeds size 2, i.e., that first
interruption is never interrupted. If we ever need that, we can simply raise
|MAX_CIP_STACK_SIZE|.

Each CIP contains a further stack of "noted levels" -- where certain code
blocks, belonging to loop and conditional constructs, are placed. (Every Inter
instruction has a level, meaning, its hierarchical depth within the code
package: a level 3 instruction is three code blocks deep.) One of the easiest
ways to get errors when generating Inter code is to lose track of these levels
and generate instructions which are one level off; so, managing levels here
makes the caller's life much easier.

@d MAX_CIP_STACK_SIZE 2
@d MAX_NESTED_NOTEWORTHY_LEVELS 256

=
typedef struct code_insertion_point {
	int inter_level;
	int noted_levels[MAX_NESTED_NOTEWORTHY_LEVELS];
	int noted_sp;
	int level_error_occurred;
	inter_bookmark *insertion_bm;
	inter_bookmark saved_bm;
} code_insertion_point;

@ When a new CIP is generated with a new write position, it saves a bookmark
holding the previous write position:

=
void Produce::push_new_code_position_saving(inter_tree *I, inter_bookmark *new_IBM,
	inter_bookmark old_IBM) {
	code_insertion_point cip;
	cip.inter_level = (int) (Produce::baseline(new_IBM) + 2);
	cip.noted_sp = 2;
	cip.level_error_occurred = FALSE;
	cip.insertion_bm = new_IBM;
	cip.saved_bm = old_IBM;
	if (I->site.sprdata.cip_sp >= MAX_CIP_STACK_SIZE) internal_error("CIP overflow");
	I->site.sprdata.cip_stack[I->site.sprdata.cip_sp++] = cip;
}

@ That saved position is usually the current write position, so this function is
convenient:

=
void Produce::push_new_code_position(inter_tree *I, inter_bookmark *IBM) {
	Produce::push_new_code_position_saving(I, IBM, InterBookmark::snapshot(Packaging::at(I)));
}

@ And this reverts to the previous position:

=
void Produce::pop_code_position(inter_tree *I) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP underflow");
	if ((I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1].level_error_occurred) &&
		(problem_count == 0))
		internal_error("levelling error in CIP");
	Packaging::set_at(I, I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1].saved_bm);
	I->site.sprdata.cip_sp--;
}

@ A bookmark for the current write position can now always be obtained thus:

=
inter_bookmark *Produce::at(inter_tree *I) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside function");
	return I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1].insertion_bm;
}

@h Levelling.
As noted above, Inter instructions occur at "levels" which need to be kept track
of. This returns the level at the current write position:

=
int Produce::level(inter_tree *I) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside function");
	return I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1].inter_level;
}

@ //Produce::down// is so called because it takes us one level deeper in the tree;
this increases the level by 1. Similarly, //Produce::up// heads back up towards
the root, decreasing the level by 1. The caller should be careful to ensure that
calls to these functions exactly match each other: for each down there must be
a matching up.

=
void Produce::down(inter_tree *I) {
	Produce::set_level(I, Produce::level(I) + 1);
}

void Produce::up(inter_tree *I) {
	Produce::set_level(I, Produce::level(I) - 1);
}

@ In addition, the user can call the following to jump the level to some
position with respect to the currently code block being written. This should
only be used as a last resort when the level has unavoidably been lost track of,
e.g., when a schema has to compile a fragment of a code block missing its beginning
or end.

The levelling stack is automatically maintained. As new code blocks open (or,
more properly, as Inter primitives which take code blocks are generated), the
level is automatically pushed. When the current write level washes below these
levels, the code blocks in question must be finished, and the levels are popped
automatically from the stack.

=
void Produce::set_level_to_current_code_block_plus(inter_tree *I, int delta) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &(I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1]);
	if (cip->noted_sp <= 0) {
		cip->level_error_occurred = TRUE;
		cip->noted_sp = 0;
	} else {
		Produce::set_level(I, cip->noted_levels[cip->noted_sp-1] + delta);
	}
}

@ Those public functions are powered by these private ones.

=
void Produce::note_level_of_newly_opening_code_block(inter_tree *I) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &(I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1]);
	if (cip->noted_sp >= MAX_NESTED_NOTEWORTHY_LEVELS) return;
	cip->noted_levels[cip->noted_sp++] = Produce::level(I);
}

void Produce::set_level(inter_tree *I, int N) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside function");
	code_insertion_point *cip = &(I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1]);
	if (N < 2) {
		cip->level_error_occurred = TRUE;
		N = 2;
	}
	while (cip->noted_sp > 0) {
		if (cip->noted_levels[cip->noted_sp-1] < N) break;
		cip->noted_sp--;
	}
	cip->inter_level = N;
}

@h The current function.
It is also convenient to have this section manage the business of constructing
standard function packages.

=
inter_package *Produce::function_body(inter_tree *I, packaging_state *save, inter_name *iname) {
	if (Packaging::at(I) == NULL) internal_error("no inter repository");
	if (save) {
		*save = Packaging::enter_home_of(iname);
		package_request *R = InterNames::location(iname);
		if ((R == NULL) || (R == LargeScale::main_request(I))) {
			LOG("Routine outside of package: %n\n", iname);
			internal_error("routine outside of package");
		}
	}

	inter_name *block_iname = iname;
	inter_bookmark save_ib = InterBookmark::snapshot(Packaging::at(I));
	Produce::set_function(I,
		Produce::make_and_set_package(I, block_iname, LargeScale::package_type(I, I"_code")));

	Produce::guard(CodeInstruction::new(Packaging::at(I),
		(int) Produce::baseline(Packaging::at(I)) + 1, NULL));

	I->site.sprdata.function_body_start_bookmark =
		InterBookmark::shifted(Packaging::at(I), IMMEDIATELY_AFTER_NODEPLACEMENT);

	I->site.sprdata.function_locals_bookmark =
		InterBookmark::shifted(Packaging::at(I), BEFORE_NODEPLACEMENT);

	I->site.sprdata.function_body_code_bookmark =
		InterBookmark::snapshot(Packaging::at(I));

	Produce::push_new_code_position_saving(I,
		&(I->site.sprdata.function_body_code_bookmark), save_ib);
	return I->site.sprdata.current_inter_function;
}

@ The caller can test whether a function is being made, and find its start
position if so:

=
int Produce::function_body_is_open(inter_tree *I) {
	if (I->site.sprdata.current_inter_function) return TRUE;
	return FALSE;
}

inter_bookmark *Produce::function_body_start_bookmark(inter_tree *I) {
	return &(I->site.sprdata.function_body_start_bookmark);
}

@ The following creates a local symbol, suitable for a local variable or a
label. Note that we return an |inter_symbol|, not an iname: inames can never
refer to local resources like these.

=
inter_symbol *Produce::new_local_symbol(inter_tree *I, text_stream *name) {
	return InterSymbolsTable::create_with_unique_name(
		InterPackage::scope(I->site.sprdata.current_inter_function), name);
}

@ When the caller has finished compiling the function body, she should call:

=
void Produce::end_function_body(inter_tree *I) {
	Produce::set_function(I, NULL);
	Produce::pop_code_position(I);
}

@ If the caller doesn't want to use the mechanism above, and wants to make her
own damn packages, she can call the following: but should be careful to call
twice, first to set to the new function's package, then to reset it to |NULL|.

=
void Produce::set_function(inter_tree *I, inter_package *P) {
	I->site.sprdata.current_inter_function = P;
}

@h Making material outside of functions.
That's enough of keeping track of things: from here on, the code in this section
will actually make some Inter. The lower-down APIs in //bytecode// only return
an |inter_error_message| if something improper has been done; //inter// and
//inform7//, when generating code on their own initiative, must never trigger
Inter errors. So we will guard against them, reacting with an immediate
internal error to halt the compiler if they occur.

=
void Produce::guard(inter_error_message *ERR) {
	if ((ERR) && (problem_count == 0)) {
		InterErrors::issue(ERR); internal_error("inter error");
	}
}

@ "Level" is an issue outside of functions, too. In general, material will be
generated either inside a package or at the root level. The following returns
the level for material being generated in this location -- 0 for the root level,
or the baseline of the current package plus 1, if we're in a package.

=
inter_ti Produce::baseline(inter_bookmark *IBM) {
	if (IBM == NULL) return 0;
	inter_package *pack = InterBookmark::package(IBM);
	if (pack == NULL) return 0;
	if (InterPackage::is_a_root_package(pack)) return 0;
	if (InterPackage::is_a_function_body(pack))
		return (inter_ti) InterPackage::baseline(InterPackage::parent(pack)) + 1;
	return (inter_ti) InterPackage::baseline(pack) + 1;
}

@ Demonstrating both of these, some simple Inter instructions:

=
void Produce::nop(inter_tree *I) {
	Produce::nop_at(Packaging::at(I), 0);
}

void Produce::nop_at(inter_bookmark *IBM, inter_ti delta) {
	Produce::guard(NopInstruction::new(IBM, Produce::baseline(IBM) + delta, NULL));
}

void Produce::comment(inter_tree *I, text_stream *text) {
	inter_bookmark *IBM = Packaging::at(I);
	Produce::guard(CommentInstruction::new(IBM, text, NULL, Produce::baseline(IBM)));
}

@ Defining a constant with numerical value |val|:

=
inter_name *Produce::numeric_constant(inter_tree *I, inter_name *con_iname, kind *K,
	inter_ti val) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = InterNames::to_symbol(con_iname);
	inter_bookmark *IBM = Packaging::at(I);
	Produce::guard(ConstantInstruction::new(IBM, con_s,
		Produce::kind_to_type(K), InterValuePairs::number(val),
		Produce::baseline(IBM), NULL));
	Packaging::exit(I, save);
	return con_iname;
}

@ Defining a constant equal to the value of an already-existing symbol |val_s|:

=
inter_name *Produce::symbol_constant(inter_tree *I, inter_name *con_iname, kind *K,
	inter_symbol *val_s) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_bookmark *IBM = Packaging::at(I);
	inter_symbol *con_s = InterNames::to_symbol(con_iname);
	inter_pair val = InterValuePairs::symbolic(IBM, val_s);
	Produce::guard(ConstantInstruction::new(IBM, con_s,
		Produce::kind_to_type(K), val, Produce::baseline(IBM), NULL));
	Packaging::exit(I, save);
	return con_iname;
}

@ Note that this function does two things: creates a new package at the current
write position, and then shifts the write position into that new package:

=
inter_package *Produce::make_and_set_package(inter_tree *I, inter_name *iname,
	inter_symbol *ptype) {
	inter_package *P = NULL;
	TEMPORARY_TEXT(textual_name)
	WRITE_TO(textual_name, "%n", iname);
	Produce::guard(PackageInstruction::new(Packaging::at(I), textual_name,
		InterTypes::unchecked(), TRUE,
		ptype, Produce::baseline(Packaging::at(I)), NULL, &P));
	DISCARD_TEXT(textual_name)
	if (P) InterBookmark::move_into_package(Packaging::at(I), P);
	return P;
}

@ We make a new package and return it; but note the |+1| here -- the package
is created at the level below that in |IBM|.

=
inter_package *Produce::make_subpackage(inter_bookmark *IBM,
	text_stream *name, inter_symbol *ptype) {
	inter_package *P = NULL;
	Produce::guard(PackageInstruction::new(IBM, name, InterTypes::unchecked(), TRUE,
		ptype, (inter_ti) InterBookmark::baseline(IBM) + 1, NULL, &P));
	return P;
}

@h Making the code inside function bodies.
We begin with invocations: usages of the |inv| instruction. This of course has
three uses. First, primitives:

=
void Produce::inv_primitive(inter_tree *I, inter_ti bip) {
	inter_symbol *prim_symb = Primitives::from_BIP(I, bip);
	if ((Primitives::takes_code_blocks(bip)) &&
		(bip != CASE_BIP) && (bip != DEFAULT_BIP))
		Produce::note_level_of_newly_opening_code_block(I);
	Produce::guard(InvInstruction::new_primitive(Produce::at(I),
		prim_symb, (inter_ti) Produce::level(I), NULL));
}

@ These occur often enough to be worth defining here:

=
void Produce::rtrue(inter_tree *I) {
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, InterValuePairs::number(1)); /* that is, return "true" */
	Produce::up(I);
}

void Produce::rfalse(inter_tree *I) {
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, InterValuePairs::number(0)); /* that is, return "false" */
	Produce::up(I);
}

void Produce::push(inter_tree *I, inter_name *iname) {
	Produce::inv_primitive(I, PUSH_BIP);
	Produce::down(I);
		Produce::val_iname(I, K_value, iname);
	Produce::up(I);
}

void Produce::pull(inter_tree *I, inter_name *iname) {
	Produce::inv_primitive(I, PULL_BIP);
	Produce::down(I);
		Produce::ref_iname(I, K_value, iname);
	Produce::up(I);
}

@ Assembly language:

=
void Produce::inv_assembly(inter_tree *I, text_stream *opcode) {
	inter_bookmark *IBM = Produce::at(I);
	Produce::guard(InvInstruction::new_assembly(IBM, opcode,
		(inter_ti) Produce::level(I), NULL));
}

@ The "assembly marker" punctuation can be placed thus:

=
void Produce::assembly_marker(inter_tree *I, inter_ti which) {
	Produce::guard(AssemblyInstruction::new(Produce::at(I), which, (inter_ti) Produce::level(I), NULL));
}

@ Function calls:

=
void Produce::inv_call_symbol(inter_tree *I, inter_symbol *fn_s) {
	Produce::guard(InvInstruction::new_function_call(Produce::at(I), fn_s,
		(inter_ti) Produce::level(I), NULL));
}

void Produce::inv_call_iname(inter_tree *I, inter_name *fn_iname) {
	Produce::inv_call_symbol(I, InterNames::to_symbol(fn_iname));
}

void Produce::inv_indirect_call(inter_tree *I, int arity) {
	Produce::inv_primitive(I, Primitives::BIP_for_indirect_call_returning_value(arity));
}

@ Instructions for changing the primitive category:

=
void Produce::code(inter_tree *I) {
	Produce::guard(CodeInstruction::new(Produce::at(I), Produce::level(I), NULL));
}

void Produce::evaluation(inter_tree *I) {
	Produce::guard(EvaluationInstruction::new(Produce::at(I), Produce::level(I), NULL));
}

void Produce::reference(inter_tree *I) {
	Produce::guard(ReferenceInstruction::new(Produce::at(I), Produce::level(I), NULL));
}

@ The |val| instruction. First, we can take the value of something identified
by an iname:

=
void Produce::val_iname(inter_tree *I, kind *K, inter_name *iname) {
	if (iname == NULL) {
		if (problem_count == 0) internal_error("no iname");
		else Produce::val(I, K_value, InterValuePairs::number(0)); /* for error recovery */
	} else {
		Produce::val_symbol(I, K, InterNames::to_symbol(iname));
	}
}

@ But that essentially reduces to this, taking the value of a symbol:

=
void Produce::val_symbol(inter_tree *I, kind *K, inter_symbol *s) {
	inter_pair val = InterValuePairs::symbolic(Packaging::at(I), s);
	Produce::val(I, K, val);
}

@ Which in turn falls into this, the general case: a value specified by an
Inter pair --

=
void Produce::val(inter_tree *I, kind *K, inter_pair val) {
	inter_symbol *val_kind = NULL;
	if ((K) && (K != K_value)) {
		val_kind = Produce::kind_to_symbol(K);
		if (val_kind == NULL) internal_error("no kind for val");
	}
	Produce::guard(ValInstruction::new(Produce::at(I), InterTypes::from_type_name(val_kind),
		Produce::level(I), val, NULL));
}

@ There remain some convenience functions for making such pairs.

=
void Produce::val_nothing(inter_tree *I) {
	Produce::val(I, K_value, InterValuePairs::number(0));
}

void Produce::val_text(inter_tree *I, text_stream *S) {
	Produce::val(I, K_value, InterValuePairs::from_text(Packaging::at(I), S));
}

void Produce::val_char(inter_tree *I, wchar_t c) {
	Produce::val(I, K_value, InterValuePairs::number((inter_ti) c));
}

void Produce::val_real(inter_tree *I, double g) {
	Produce::val(I, K_value, InterValuePairs::real(Packaging::at(I), g));
}

void Produce::val_real_from_text(inter_tree *I, text_stream *S) {
	Produce::val(I, K_value, InterValuePairs::real_from_I6_notation(Packaging::at(I), S));
}

void Produce::val_dword(inter_tree *I, text_stream *S) {
	Produce::val(I, K_value, InterValuePairs::from_singular_dword(Packaging::at(I), S));
}

@ The |ref| instruction is simpler. It makes no sense to have a storage reference
to a constant, so we only ever need to refer to inames or their symbols:

=
void Produce::ref_iname(inter_tree *I, kind *K, inter_name *iname) {
	Produce::ref_symbol(I, K, InterNames::to_symbol(iname));
}

void Produce::ref_symbol(inter_tree *I, kind *K, inter_symbol *s) {
	inter_pair val = InterValuePairs::symbolic(Packaging::at(I), s);
	inter_symbol *val_kind = NULL;
	if ((K) && (K != K_value)) {
		val_kind = Produce::kind_to_symbol(K);
		if (val_kind == NULL) internal_error("no kind for ref");
	}
	Produce::guard(RefInstruction::new(Produce::at(I), InterTypes::from_type_name(val_kind),
		Produce::level(I), val, NULL));
}

@ |cast| may yet disappear from Inter: it doesn't really accomplish anything at
present, and is more of a placeholder than anything else.

=
void Produce::cast(inter_tree *I, kind *F, kind *T) {
	inter_type F_t = Produce::kind_to_type(F);
	inter_type T_t = Produce::kind_to_type(T);
	Produce::guard(CastInstruction::new(Produce::at(I), F_t, T_t,
		(inter_ti) Produce::level(I), NULL));
}

inter_symbol *Produce::kind_to_symbol(kind *K) {
	#ifdef CORE_MODULE
	if ((K == NULL) || (K == K_value)) return NULL;
	return InterNames::to_symbol(RTKindDeclarations::iname(K));
	#endif
	#ifndef CORE_MODULE
	return NULL;
	#endif
}

inter_type Produce::kind_to_type(kind *K) {
	inter_type type = InterTypes::unchecked();
	inter_symbol *S = Produce::kind_to_symbol(K);
	if (S) type = InterTypes::from_type_name(S);
	return type;
}

inter_ti Produce::kind_to_TID(inter_bookmark *IBM, kind *K) {
	inter_type type = Produce::kind_to_type(K);
	return InterTypes::to_TID_at(IBM, type);
}

@ The following reserves a label, that is, declares that a given name will be
that of a label in the function currently being constructed.

Label names must begin with a |.|, and we enforce that here.

=
inter_symbol *Produce::reserve_label(inter_tree *I, text_stream *lname) {
	if (Str::get_first_char(lname) != '.') {
		TEMPORARY_TEXT(dotted)
		WRITE_TO(dotted, ".%S", lname);
		inter_symbol *lab_name = Produce::reserve_label(I, dotted);
		DISCARD_TEXT(dotted)
		return lab_name;
	}
	inter_symbol *lab_name = Produce::local_exists(I, lname);
	if (lab_name) return lab_name;
	lab_name = Produce::new_local_symbol(I, lname);
	InterSymbol::make_label(lab_name);
	return lab_name;
}

@ This places the label at the current write position:

=
void Produce::place_label(inter_tree *I, inter_symbol *lab_name) {
	Produce::guard(LabelInstruction::new(Produce::at(I), lab_name, (inter_ti) Produce::level(I), NULL));
}

@ And here we make a |lab| instruction, suitable for a jump instruction to use.

=
void Produce::lab(inter_tree *I, inter_symbol *L) {
	Produce::guard(LabInstruction::new(Produce::at(I), L, (inter_ti) Produce::level(I), NULL));
}

@ Now for local variables.

Note that this function is not intended as the way high-level code in //inform7//
should create a local variable: see //imperative: Local Variables// for that.
This function is at a lower level -- it does the necessary Inter business, but
doesn't add the name tp the current stack frame in //inform7//.

=
inter_symbol *Produce::local(inter_tree *I, kind *K, text_stream *lname, text_stream *comm) {
	if (I->site.sprdata.current_inter_function == NULL)
		internal_error("local variable emitted outside function");
	if (K == NULL) K = K_value;
	inter_symbol *local_s = Produce::new_local_symbol(I, lname);
	InterSymbol::make_local(local_s);
	inter_bookmark *locals_at = &(I->site.sprdata.function_locals_bookmark);
	if ((comm) && (Str::len(comm) > 0))
		Produce::guard(CommentInstruction::new(locals_at, comm, NULL,
			Produce::baseline(locals_at) + 1));
	inter_type type = InterTypes::unchecked();
	if ((K) && (K != K_value)) type = InterTypes::from_type_name(Produce::kind_to_symbol(K));
	Produce::guard(LocalInstruction::new(locals_at, local_s, type,
		Produce::baseline(locals_at) + 1, NULL));
	return local_s;
}

inter_symbol *Produce::local_exists(inter_tree *I, text_stream *lname) {
	return InterSymbolsTable::symbol_from_name(
		InterPackage::scope(I->site.sprdata.current_inter_function), lname);
}

@ And finally, code provenance markers:

=
void Produce::provenance(inter_tree *I, text_provenance from) {
	Produce::guard(ProvenanceInstruction::new_from_provenance(Produce::at(I), from,
		(inter_ti) Produce::level(I), NULL));
}
