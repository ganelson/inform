[Produce::] Producing Inter.

@h Definitions.

@

@d MAX_CIP_STACK_SIZE 2

=
typedef struct site_production_data {
	struct inter_bookmark begin_bookmark;
	struct inter_bookmark locals_bookmark;
	struct inter_bookmark code_bookmark;
	struct code_insertion_point cip_stack[MAX_CIP_STACK_SIZE];
	int cip_sp;
	struct inter_package *current_inter_routine;
} site_production_data;

void Produce::clear_prdata(inter_tree *I) {
	building_site *B = &(I->site);
	B->sprdata.begin_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->sprdata.locals_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->sprdata.code_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->sprdata.cip_sp = 0;
	B->sprdata.current_inter_routine = NULL;
}

void Produce::set_function(inter_tree *I, inter_package *P) {
	I->site.sprdata.current_inter_routine = P;
}

void Produce::guard(inter_error_message *ERR) {
	if ((ERR) && (problem_count == 0)) { Inter::Errors::issue(ERR); internal_error("inter error"); }
}

inter_symbol *Produce::new_symbol(inter_symbols_table *T, text_stream *name) {
	return InterSymbolsTables::create_with_unique_name(T, name);
}

inter_symbol *Produce::define_symbol(inter_name *iname) {
	InterNames::to_symbol(iname);
	if (iname->symbol) {
		if (Inter::Symbols::is_predeclared(iname->symbol)) {
			Inter::Symbols::undefine(iname->symbol);
		}
	}
	return iname->symbol;
}

inter_symbols_table *Produce::main_scope(inter_tree *I) {
	return Inter::Packages::scope(LargeScale::main_package_if_it_exists(I));
}

inter_symbols_table *Produce::connectors_scope(inter_tree *I) {
	return Inter::Packages::scope(LargeScale::connectors_package_if_it_exists(I));
}

inter_symbol *Produce::opcode(inter_tree *I, inter_ti bip) {
	return Primitives::get(I, bip);
}

inter_ti Produce::baseline(inter_bookmark *IBM) {
	if (IBM == NULL) return 0;
	if (Inter::Bookmarks::package(IBM) == NULL) return 0;
	if (Inter::Packages::is_rootlike(Inter::Bookmarks::package(IBM))) return 0;
	if (Inter::Packages::is_codelike(Inter::Bookmarks::package(IBM)))
		return (inter_ti) Inter::Packages::baseline(Inter::Packages::parent(Inter::Bookmarks::package(IBM))) + 1;
	return (inter_ti) Inter::Packages::baseline(Inter::Bookmarks::package(IBM)) + 1;
}

void Produce::nop(inter_tree *I) {
	Produce::guard(Inter::Nop::new(Packaging::at(I), Produce::baseline(Packaging::at(I)), NULL));
}

void Produce::nop_at(inter_bookmark *IBM) {
	Produce::guard(Inter::Nop::new(IBM, Produce::baseline(IBM) + 2, NULL));
}

void Produce::version(inter_tree *I, int N) {
	Produce::guard(Inter::Version::new(Packaging::at(I), N, Produce::baseline(Packaging::at(I)), NULL));
}

void Produce::comment(inter_tree *I, text_stream *text) {
	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), Inter::Bookmarks::package(Packaging::at(I)));
	Str::copy(Inter::Warehouse::get_text(InterTree::warehouse(I), ID), text);
	Produce::guard(Inter::Comment::new(Packaging::at(I), Produce::baseline(Packaging::at(I)), NULL, ID));
}

inter_package *Produce::package(inter_tree *I, inter_name *iname, inter_symbol *ptype) {
	if (ptype == NULL) internal_error("no package type");
	inter_ti B = Produce::baseline(Packaging::at(I));
	inter_package *IP = NULL;
	TEMPORARY_TEXT(hmm)
	WRITE_TO(hmm, "%n", iname);
	Produce::guard(Inter::Package::new_package_named(Packaging::at(I), hmm, TRUE, ptype, B, NULL, &IP));
	DISCARD_TEXT(hmm)
	if (IP) Inter::Bookmarks::set_current_package(Packaging::at(I), IP);
	return IP;
}

void Produce::annotate_symbol_t(inter_symbol *symb, inter_ti annot_ID, text_stream *S) {
	Inter::Symbols::annotate_t(Inter::Packages::tree(symb->owning_table->owning_package), symb->owning_table->owning_package, symb, annot_ID, S);
}

void Produce::annotate_symbol_w(inter_symbol *symb, inter_ti annot_ID, wording W) {
	TEMPORARY_TEXT(temp)
	WRITE_TO(temp, "%W", W);
	Inter::Symbols::annotate_t(Inter::Packages::tree(symb->owning_table->owning_package), symb->owning_table->owning_package, symb, annot_ID, temp);
	DISCARD_TEXT(temp)
}

void Produce::annotate_symbol_i(inter_symbol *symb, inter_ti annot_ID, inter_ti V) {
	Inter::Symbols::annotate_i(symb, annot_ID, V);
}

void Produce::annotate_iname_i(inter_name *N, inter_ti annot_ID, inter_ti V) {
	Inter::Symbols::annotate_i(InterNames::to_symbol(N), annot_ID, V);
}

void Produce::set_flag(inter_name *iname, int f) {
	Inter::Symbols::set_flag(InterNames::to_symbol(iname), f);
}

void Produce::clear_flag(inter_name *iname, int f) {
	Inter::Symbols::clear_flag(InterNames::to_symbol(iname), f);
}

void Produce::annotate_i(inter_name *iname, inter_ti annot_ID, inter_ti V) {
	if (iname) Produce::annotate_symbol_i(InterNames::to_symbol(iname), annot_ID, V);
}

void Produce::annotate_w(inter_name *iname, inter_ti annot_ID, wording W) {
	if (iname) Produce::annotate_symbol_w(InterNames::to_symbol(iname), annot_ID, W);
}

int Produce::read_annotation(inter_name *iname, inter_ti annot) {
	return Inter::Symbols::read_annotation(InterNames::to_symbol(iname), annot);
}


void Produce::change_translation(inter_name *iname, text_stream *new_text) {
	Inter::Symbols::set_translate(InterNames::to_symbol(iname), new_text);
}

text_stream *Produce::get_translation(inter_name *iname) {
	return Inter::Symbols::get_translate(InterNames::to_symbol(iname));
}

void Produce::code(inter_tree *I) {
	Produce::guard(Inter::Code::new(Produce::at(I), Produce::level(I), NULL));
}

void Produce::evaluation(inter_tree *I) {
	Produce::guard(Inter::Evaluation::new(Produce::at(I), Produce::level(I), NULL));
}

void Produce::reference(inter_tree *I) {
	Produce::guard(Inter::Reference::new(Produce::at(I), Produce::level(I), NULL));
}

@

@d MAX_NESTED_NOTEWORTHY_LEVELS 256

=
typedef struct code_insertion_point {
	int inter_level;
	int noted_levels[MAX_NESTED_NOTEWORTHY_LEVELS];
	int noted_sp;
	int error_flag;
	inter_bookmark *insertion_bm;
	inter_bookmark saved_bm;
} code_insertion_point;

code_insertion_point Produce::new_cip(inter_tree *I, inter_bookmark *IBM) {
	code_insertion_point cip;
	cip.inter_level = (int) (Produce::baseline(IBM) + 2);
	cip.noted_sp = 2;
	cip.error_flag = FALSE;
	cip.insertion_bm = IBM;
	cip.saved_bm = Inter::Bookmarks::snapshot(Packaging::at(I));
	return cip;
}

inter_bookmark *Produce::locals_bookmark(inter_tree *I) {
	return &(I->site.sprdata.locals_bookmark);
}

inter_package *Produce::block(inter_tree *I, packaging_state *save, inter_name *iname) {
	if (Packaging::at(I) == NULL) internal_error("no inter repository");
	if (save) {
		*save = Packaging::enter_home_of(iname);
		package_request *R = InterNames::location(iname);
		if ((R == NULL) || (R == LargeScale::main_request(I))) {
			LOG("Routine outside of package: %n\n", iname);
			internal_error("routine outside of package");
		}
	}

	inter_name *block_iname = NULL;
	if (Packaging::housed_in_function(I, iname))
		block_iname = Packaging::make_iname_within(InterNames::location(iname), I"block");
	else internal_error("routine outside function package");
	inter_bookmark save_ib = Inter::Bookmarks::snapshot(Packaging::at(I));
	Produce::set_function(I, Produce::package(I, block_iname, PackageTypes::get(I, I"_code")));

	Produce::guard(Inter::Code::new(Packaging::at(I),
		(int) Produce::baseline(Packaging::at(I)) + 1, NULL));

	I->site.sprdata.begin_bookmark = Inter::Bookmarks::snapshot(Packaging::at(I));
	Inter::Bookmarks::set_placement(&(I->site.sprdata.begin_bookmark), IMMEDIATELY_AFTER_ICPLACEMENT);

	I->site.sprdata.locals_bookmark = I->site.sprdata.begin_bookmark;
	Inter::Bookmarks::set_placement(&(I->site.sprdata.locals_bookmark), BEFORE_ICPLACEMENT);

	I->site.sprdata.code_bookmark = Inter::Bookmarks::snapshot(Packaging::at(I));
	code_insertion_point cip = Produce::new_cip(I, &(I->site.sprdata.code_bookmark));
	Produce::push_code_position(I, cip, save_ib);
	return I->site.sprdata.current_inter_routine;
}

inter_name *Produce::kernel(inter_tree *I, inter_name *public_name) {
	if (Packaging::housed_in_function(I, public_name) == FALSE)
		internal_error("routine not housed in function");
	package_request *P = InterNames::location(public_name);
	inter_name *kernel_name = Packaging::make_iname_within(P, I"kernel");
	Produce::set_flag(kernel_name, MAKE_NAME_UNIQUE);
	return kernel_name;
}

void Produce::end_main_block(inter_tree *I, packaging_state save) {
	Packaging::exit(I, save);
}

void Produce::end_block(inter_tree *I) {
	Produce::set_function(I, NULL);
	Produce::pop_code_position(I);
}

int Produce::emitting_routine(inter_tree *I) {
	if (I->site.sprdata.current_inter_routine) return TRUE;
	return FALSE;
}

code_insertion_point Produce::begin_position(inter_tree *I) {
	code_insertion_point cip = Produce::new_cip(I, &(I->site.sprdata.begin_bookmark));
	return cip;
}

void Produce::push_code_position(inter_tree *I, code_insertion_point cip, inter_bookmark save_ib) {
	if (I->site.sprdata.cip_sp >= MAX_CIP_STACK_SIZE) internal_error("CIP overflow");
	cip.saved_bm = save_ib;
	I->site.sprdata.cip_stack[I->site.sprdata.cip_sp++] = cip;
}

int Produce::level(inter_tree *I) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &(I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1]);
	return cip->inter_level;
}

void Produce::set_level(inter_tree *I, int N) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &(I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1]);
	if (N < 2) {
		if (problem_count == 0) cip->error_flag = TRUE;
		N = 2;
	}
	while (cip->noted_sp > 0) {
		if (cip->noted_levels[cip->noted_sp-1] < N) break;
		cip->noted_sp--;
	}
	cip->inter_level = N;
}

void Produce::note_level(inter_tree *I, inter_symbol *from) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &(I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1]);
	if (cip->noted_sp >= MAX_NESTED_NOTEWORTHY_LEVELS) return;
	cip->noted_levels[cip->noted_sp++] = Produce::level(I);
}

void Produce::to_last_level(inter_tree *I, int delta) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &(I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1]);
	if (cip->noted_sp <= 0) {
		if (problem_count == 0) cip->error_flag = TRUE;
	} else {
		Produce::set_level(I, cip->noted_levels[cip->noted_sp-1] + delta);
	}
}

inter_bookmark *Produce::at(inter_tree *I) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP level accessed outside routine");
	return I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1].insertion_bm;
}

void Produce::down(inter_tree *I) {
	Produce::set_level(I, Produce::level(I) + 1);
}

void Produce::up(inter_tree *I) {
	Produce::set_level(I, Produce::level(I) - 1);
}

void Produce::pop_code_position(inter_tree *I) {
	if (I->site.sprdata.cip_sp <= 0) internal_error("CIP underflow");
	if (I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1].error_flag) {
		internal_error("bad inter hierarchy");
	}
	*(Packaging::at(I)) = I->site.sprdata.cip_stack[I->site.sprdata.cip_sp-1].saved_bm;
	I->site.sprdata.cip_sp--;
}

void Produce::inv_assembly(inter_tree *I, text_stream *opcode) {
	inter_ti SID = Inter::Warehouse::create_text(InterTree::warehouse(I), Inter::Bookmarks::package(Produce::at(I)));
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), SID);
	Str::copy(glob_storage, opcode);
	Produce::guard(Inter::Inv::new_assembly(Produce::at(I), SID, (inter_ti) Produce::level(I), NULL));
}

void Produce::inv_primitive(inter_tree *I, inter_ti bip) {
	inter_symbol *prim_symb = Primitives::get(I, bip);
	if (prim_symb == NULL) {
		WRITE_TO(STDERR, "BIP = %d\n", bip);
		internal_error("undefined primitive");
	}
	if ((bip == SWITCH_BIP) ||
		(bip == IF_BIP) ||
		(bip == IFELSE_BIP) ||
		(bip == FOR_BIP) ||
		(bip == WHILE_BIP) ||
		(bip == DO_BIP) ||
		(bip == OBJECTLOOP_BIP)) Produce::note_level(I, prim_symb);
	Produce::guard(Inter::Inv::new_primitive(Produce::at(I), prim_symb, (inter_ti) Produce::level(I), NULL));
}

void Produce::inv_call(inter_tree *I, inter_symbol *prim_symb) {
	Produce::guard(Inter::Inv::new_call(Produce::at(I), prim_symb, (inter_ti) Produce::level(I), NULL));
}

void Produce::inv_call_iname(inter_tree *I, inter_name *iname) {
	inter_symbol *prim_symb = InterNames::to_symbol(iname);
	Produce::guard(Inter::Inv::new_call(Produce::at(I), prim_symb, (inter_ti) Produce::level(I), NULL));
}

void Produce::inv_indirect_call(inter_tree *I, int arity) {
	switch (arity) {
		case 0: Produce::inv_primitive(I, INDIRECT0_BIP); break;
		case 1: Produce::inv_primitive(I, INDIRECT1_BIP); break;
		case 2: Produce::inv_primitive(I, INDIRECT2_BIP); break;
		case 3: Produce::inv_primitive(I, INDIRECT3_BIP); break;
		case 4: Produce::inv_primitive(I, INDIRECT4_BIP); break;
		default: internal_error("indirect function call with too many arguments");
	}
}

void Produce::rtrue(inter_tree *I) {
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, LITERAL_IVAL, 1); /* that is, return "true" */
	Produce::up(I);
}

void Produce::rfalse(inter_tree *I) {
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, LITERAL_IVAL, 0); /* that is, return "false" */
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

void Produce::val(inter_tree *I, kind *K, inter_ti val1, inter_ti val2) {
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for val");
	Produce::guard(Inter::Val::new(Produce::at(I), val_kind, Produce::level(I), val1, val2, NULL));
}

void Produce::val_nothing(inter_tree *I) {
	Produce::val(I, K_value, LITERAL_IVAL, 0);
}

void Produce::cast(inter_tree *I, kind *F, kind *T) {
	inter_symbol *F_s = Produce::kind_to_symbol(F);
	inter_symbol *T_s = Produce::kind_to_symbol(T);
	Produce::guard(Inter::Cast::new(Produce::at(I), F_s, T_s, (inter_ti) Produce::level(I), NULL));
}

void Produce::lab(inter_tree *I, inter_symbol *L) {
	Produce::guard(Inter::Lab::new(Produce::at(I), L, (inter_ti) Produce::level(I), NULL));
}

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
	lab_name = Produce::new_local_symbol(I->site.sprdata.current_inter_routine, lname);
	Inter::Symbols::label(lab_name);
	return lab_name;
}

void Produce::place_label(inter_tree *I, inter_symbol *lab_name) {
	Produce::guard(Inter::Label::new(Produce::at(I), lab_name, (inter_ti) Produce::level(I), NULL));
}

@ While it is true that this function adds a local variable to the stack frame for
the function being compiled, and returns an |inter_symbol| for it, use the proper
API in //imperative: Local Variables//.

=
inter_symbol *Produce::local(inter_tree *I, kind *K, text_stream *lname,
	inter_ti annot, text_stream *comm) {
	if (I->site.sprdata.current_inter_routine == NULL)
		internal_error("local variable emitted outside function");
	if (K == NULL) K = K_value;
	inter_symbol *local_s = Produce::new_local_symbol(I->site.sprdata.current_inter_routine, lname);
	inter_symbol *kind_s = Produce::kind_to_symbol(K);
	inter_ti ID = 0;
	if ((comm) && (Str::len(comm) > 0)) {
		ID = Inter::Warehouse::create_text(InterTree::warehouse(I),
			Inter::Bookmarks::package(Packaging::at(I)));
		Str::copy(Inter::Warehouse::get_text(InterTree::warehouse(I), ID), comm);
	}
	if (annot) Produce::annotate_symbol_i(local_s, annot, 0);
	Inter::Symbols::local(local_s);
	Produce::guard(Inter::Local::new(Produce::locals_bookmark(I), local_s, kind_s,
		ID, Produce::baseline(Produce::locals_bookmark(I)) + 1, NULL));
	return local_s;
}

inter_symbol *Produce::local_exists(inter_tree *I, text_stream *lname) {
	return InterSymbolsTables::symbol_from_name(Inter::Packages::scope(I->site.sprdata.current_inter_routine), lname);
}

inter_symbol *Produce::seek_symbol(inter_symbols_table *T, text_stream *name) {
	return InterSymbolsTables::symbol_from_name(T, name);
}

void Produce::text_value(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *text) {
	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), Inter::Bookmarks::package(Packaging::at(I)));
	text_stream *text_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, text);
	*v1 = LITERAL_TEXT_IVAL;
	*v2 = ID;
}

void Produce::real_value(inter_tree *I, inter_ti *v1, inter_ti *v2, double g) {
	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), Inter::Bookmarks::package(Packaging::at(I)));
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
	if (g > 0) WRITE_TO(glob_storage, "+");
	WRITE_TO(glob_storage, "%g", g);
	*v1 = REAL_IVAL;
	*v2 = ID;
}

void Produce::real_value_from_text(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *S) {
	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), Inter::Bookmarks::package(Packaging::at(I)));
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '$')
			PUT_TO(glob_storage, Str::get(pos));
	*v1 = REAL_IVAL;
	*v2 = ID;
}

void Produce::dword_value(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *glob) {
	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), Inter::Bookmarks::package(Packaging::at(I)));
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(glob_storage, glob);
	*v1 = DWORD_IVAL;
	*v2 = ID;
}

void Produce::plural_dword_value(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *glob) {
	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), Inter::Bookmarks::package(Packaging::at(I)));
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(glob_storage, glob);
	*v1 = PDWORD_IVAL;
	*v2 = ID;
}

void Produce::val_iname(inter_tree *I, kind *K, inter_name *iname) {
	if (iname == NULL) {
		if (problem_count == 0) internal_error("no iname");
		else Produce::val(I, K_value, LITERAL_IVAL, 0);
	} else {
		Produce::val_symbol(I, K, InterNames::to_symbol(iname));
	}
}

void Produce::val_symbol(inter_tree *I, kind *K, inter_symbol *s) {
	inter_ti val1 = 0, val2 = 0;
	inter_bookmark *IBM = Packaging::at(I);
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), s, &val1, &val2);
	Produce::val(I, K, val1, val2);
}

void Produce::val_text(inter_tree *I, text_stream *S) {
	inter_ti v1 = 0, v2 = 0;
	Produce::text_value(I, &v1, &v2, S);
	Produce::val(I, K_value, v1, v2);
}

void Produce::val_char(inter_tree *I, wchar_t c) {
	Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) c);
}

void Produce::val_real(inter_tree *I, double g) {
	inter_ti v1 = 0, v2 = 0;
	Produce::real_value(I, &v1, &v2, g);
	Produce::val(I, K_value, v1, v2);
}

void Produce::val_real_from_text(inter_tree *I, text_stream *S) {
	inter_ti v1 = 0, v2 = 0;
	Produce::real_value_from_text(I, &v1, &v2, S);
	Produce::val(I, K_value, v1, v2);
}

void Produce::val_dword(inter_tree *I, text_stream *S) {
	inter_ti v1 = 0, v2 = 0;
	Produce::dword_value(I, &v1, &v2, S);
	Produce::val(I, K_value, v1, v2);
}

void Produce::ref(inter_tree *I, kind *K, inter_ti val1, inter_ti val2) {
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for ref");
	Produce::guard(Inter::Ref::new(Produce::at(I), val_kind, Produce::level(I), val1, val2, NULL));
}

void Produce::ref_iname(inter_tree *I, kind *K, inter_name *iname) {
	Produce::ref_symbol(I, K, InterNames::to_symbol(iname));
}

void Produce::ref_symbol(inter_tree *I, kind *K, inter_symbol *s) {
	inter_ti val1 = 0, val2 = 0;
	inter_bookmark *IBM = Packaging::at(I);
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), s, &val1, &val2);
	Produce::ref(I, K, val1, val2);
}

void Produce::assembly_marker(inter_tree *I, inter_ti which) {
	Produce::guard(Inter::Assembly::new(Produce::at(I), which, (inter_ti) Produce::level(I), NULL));
}

inter_symbol *Produce::new_local_symbol(inter_package *rpack, text_stream *name) {
	return InterSymbolsTables::create_with_unique_name(Inter::Packages::scope(rpack), name);
}

inter_symbol *Produce::kind_to_symbol(kind *K) {
	#ifdef CORE_MODULE
	if (K == NULL) return unchecked_interk;
	if (K == K_value) return unchecked_interk; /* for error recovery */
	return InterNames::to_symbol(RTKindDeclarations::iname(K));
	#endif
	#ifndef CORE_MODULE
	#ifdef PIPELINE_MODULE
	return RunningPipelines::get_symbol(
		RunningPipelines::current_step(), unchecked_kind_RPSYM);
	#endif
	#ifndef PIPELINE_MODULE
	return NULL;
	#endif
	#endif
}

inter_name *Produce::find_by_name(inter_tree *I, text_stream *name) {
	if (Str::len(name) == 0) internal_error("empty extern");
	inter_name *try = HierarchyLocations::find_by_name(I, name);
	if (try == NULL) {
		HierarchyLocations::ctr(I, -1, name, Translation::same(), HierarchyLocations::plug());
		try = HierarchyLocations::find_by_name(I, name);
	}
	return try;
}

inter_name *Produce::numeric_constant(inter_tree *I, inter_name *con_iname, kind *K, inter_ti val) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = Produce::define_symbol(con_iname);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(I),
		InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), con_s),
		InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), Produce::kind_to_symbol(K)),
		LITERAL_IVAL, val, Produce::baseline(Packaging::at(I)), NULL));
	Packaging::exit(I, save);
	return con_iname;
}

inter_name *Produce::symbol_constant(inter_tree *I, inter_name *con_iname, kind *K,
	inter_symbol *val_s) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = Produce::define_symbol(con_iname);
	inter_ti v1 = 0, v2 = 0;
	inter_package *pack = Inter::Bookmarks::package(Packaging::at(I));
	Inter::Symbols::to_data(Inter::Packages::tree(pack), pack, val_s, &v1, &v2);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(I),
		InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), con_s),
		InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), Produce::kind_to_symbol(K)),
		v1, v2, Produce::baseline(Packaging::at(I)), NULL));
	Packaging::exit(I, save);
	return con_iname;
}

@ We make a new package and return it:

=
inter_package *Produce::new_package_named(inter_bookmark *IBM,
	text_stream *name, inter_symbol *ptype) {
	inter_package *P = NULL;
	Produce::guard(Inter::Package::new_package_named(IBM, name, TRUE,
		ptype, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL, &P));
	return P;
}
