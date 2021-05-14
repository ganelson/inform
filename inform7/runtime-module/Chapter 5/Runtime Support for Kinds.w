[RTKinds::] Runtime Support for Kinds.

To compile I6 material needed at runtime to enable kinds
to function as they should.

@h Kinds as tables.

=
table *RTKinds::defined_by_table(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->named_values_created_with_table;
}

void RTKinds::set_defined_by_table(kind *K, table *t) {
	if (K == NULL) internal_error("no such kind");
	K->construct->named_values_created_with_table = t;
}

@h Kinds as I6 classes.
The noun is used to store the "classname" and "class-number". In the
compiled I6 code, some kinds will correspond to classes with systematic
names like |K24_musical_instrument|. The number 24 appearing there is the
class number; the whole text is the classname. These are used only for those
kinds being compiled to an I6 |Class|.

=
inter_name *RTKinds::I6_classname(kind *K) {
	if (Kinds::Behaviour::is_object(K)) return RTKinds::iname(K);
	internal_error("no I6 classname available");
	return NULL;
}

int RTKinds::I6_classnumber(kind *K) {
	return Kinds::Behaviour::get_range_number(K);
}

@ And here is where those range numbers come from:

@d REGISTER_NOUN_KINDS_CALLBACK RTKinds::register

=
int no_kinds_of_object = 1;
noun *RTKinds::register(kind *K, kind *super, wording W, general_pointer data) {
	noun *nt = Nouns::new_common_noun(W, NEUTER_GENDER,
		ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
		KIND_SLOW_MC, data, Task::language_of_syntax());
	NameResolution::initialise(nt);
 	if (Kinds::Behaviour::is_object(super))
 		Kinds::Behaviour::set_range_number(K, no_kinds_of_object++);
 	return nt;
}

@h Default values.
When we create a new variable (or other storage object) of a given kind, but
never say what its value is to be, Inform tries to initialise it to the
"default value" for that kind.

The following should compile a default value for $K$, and return
(a) |TRUE| if it succeeded,
(b) |FALSE| if it failed (because $K$ had no values or no default could be
chosen), but no problem message has been issued about this, or
(c) |NOT_APPLICABLE| if it failed and issued a specific problem message.

=
int RTKinds::emit_default_value(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = RTKinds::compile_default_value_vh(&VH, K, W, storage_name);
	inter_ti v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	EmitArrays::generic_entry(v1, v2);
	return rv;
}
int RTKinds::emit_default_value_as_val(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = RTKinds::compile_default_value_vh(&VH, K, W, storage_name);
	Holsters::unholster_to_code_val(Emit::tree(), &VH);
	return rv;
}
int RTKinds::compile_default_value_vh(value_holster *VH, kind *K,
	wording W, char *storage_name) {
	if (Kinds::eq(K, K_value))
		@<"Value" is too vague to be the kind of a variable@>;
	if (Kinds::Behaviour::definite(K) == FALSE)
		@<This is a kind not intended for end users at all@>;

	if ((Kinds::get_construct(K) == CON_list_of) ||
		(Kinds::eq(K, K_stored_action)) ||
		(Kinds::get_construct(K) == CON_phrase) ||
		(Kinds::get_construct(K) == CON_relation)) {
		if (Kinds::get_construct(K) == CON_list_of) {
			inter_name *N = ListLiterals::small_block(RTKindIDs::compile_default_value_inner(K));
			if (N) Emit::holster_iname(VH, N);
		} else if (Kinds::eq(K, K_stored_action)) {
			inter_name *N = StoredActionLiterals::default();
			Emit::holster_iname(VH, N);
		} else if (Kinds::get_construct(K) == CON_relation) {
			inter_name *N = RelationLiterals::default(K);
			Emit::holster_iname(VH, N);
		} else {
			inter_name *N = RTKindIDs::compile_default_value_inner(K);
			if (N) Emit::holster_iname(VH, N);
		}
		return TRUE;
	}

	if ((Kinds::get_construct(K) == CON_list_of) ||
		(Kinds::get_construct(K) == CON_phrase) ||
		(Kinds::get_construct(K) == CON_relation)) {
		inter_name *N = RTKindIDs::compile_default_value_inner(K);
		if (N) Emit::holster_iname(VH, N);
		return TRUE;
	}

	if (Kinds::eq(K, K_text)) {
		inter_name *N = TextLiterals::default_text();
		Emit::holster_iname(VH, N);
		return TRUE;
	}

	inter_ti v1 = 0, v2 = 0;
	RTKinds::get_default_value(&v1, &v2, K);
	if (v1 != 0) {
		if (Holsters::non_void_context(VH)) {
			Holsters::holster_pair(VH, v1, v2);
			return TRUE;
		}
		internal_error("thwarted on gdv inter");
	}

	if (Kinds::Behaviour::is_subkind_of_object(K))
		@<The kind must have no instances, or it would have worked@>;

	return FALSE;
}

@<The kind must have no instances, or it would have worked@> =
	if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		Problems::quote_text(3, storage_name);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyKind2));
		Problems::issue_problem_segment(
			"I am unable to put any value into the %3 %1, which needs to be %2, "
			"because the world does not contain %2.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyKind));
		Problems::issue_problem_segment(
			"I am unable to find %2 to use here, because the world does not "
			"contain %2.");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@<This is a kind not intended for end users at all@> =
	if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create %1 with the kind of value '%2', "
			"because this is a kind of value which is not allowed as "
			"something to be stored in properties, variables and the "
			"like. (See the Kinds index for which kinds of value "
			"are available. The ones which aren't available are really "
			"for internal use by Inform.)");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(1, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create a value of the kind '%1' "
			"because this is a kind of value which is not allowed as "
			"something to be stored in properties, variables and the "
			"like. (See the Kinds index for which kinds of value "
			"are available. The ones which aren't available are really "
			"for internal use by Inform.)");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@<"Value" is too vague to be the kind of a variable@> =
	Problems::quote_wording_as_source(1, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"I am unable to start %1 off with any value, because the "
		"instructions do not tell me what kind of value it should be "
		"(a number, a time, some text perhaps?).");
	Problems::issue_problem_end();
	return NOT_APPLICABLE;

@ This returns either valid I6 code for the value which is the default for
$K$, or else |NULL| if $K$ has no values, or no default can be chosen.

We bend the rules and allow |nothing| as the default value of all kinds of
objects when the source text is a roomless one used only to rerelease an old
I6 story file; this effectively suppresses problem messages which the
absence of rooms would otherwise result in.

=
void RTKinds::get_default_value(inter_ti *v1, inter_ti *v2, kind *K) {
	if (K == NULL) return;

	if (Kinds::eq(K, K_object)) { *v1 = LITERAL_IVAL; *v2 = 0; return; }

	instance *I;
	LOOP_OVER_INSTANCES(I, K) {
		inter_name *N = RTInstances::value_iname(I);
		Emit::to_value_pair(v1, v2, N);
		return;
	}

	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		#ifdef IF_MODULE
		if (Task::wraps_existing_storyfile()) { *v1 = LITERAL_IVAL; *v2 = 0; return; } /* see above */
		#endif
		return;
	}

	if (Kinds::Behaviour::is_an_enumeration(K)) return;

	if (Kinds::eq(K, K_rulebook_outcome)) {
		Emit::to_value_pair(v1, v2, RTRulebooks::default_outcome_iname());
		return;
	}

	if (Kinds::eq(K, K_action_name)) {
		inter_name *wait = RTActions::double_sharp(ActionsPlugin::default_action_name());
		Emit::to_value_pair(v1, v2, wait);
		return;
	}

	text_stream *name = K->construct->default_value;

	if (Str::len(name) == 0) return;

	inter_ti val1 = 0, val2 = 0;
	if (Inter::Types::read_I6_decimal(name, &val1, &val2) == TRUE) {
		*v1 = val1; *v2 = val2; return;
	}

	inter_symbol *S = Produce::seek_symbol(Produce::main_scope(Emit::tree()), name);
	if (S) {
		Emit::symbol_to_value_pair(v1, v2, S);
		return;
	}

	if (Str::eq(name, I"true")) { *v1 = LITERAL_IVAL; *v2 = 1; return; }
	if (Str::eq(name, I"false")) { *v1 = LITERAL_IVAL; *v2 = 0; return; }

	int hl = Hierarchy::kind_default(Kinds::get_construct(K), name);
	inter_name *default_iname = Hierarchy::find(hl);
	Emit::to_value_pair(v1, v2, default_iname);
}

@h Equality tests.
For most word-value kinds, it's easy to compare two values to see if they are
equal: all we need is the |==| operator. But for pointer-value kinds, that
would simply tell us whether they point to the same block of data on the
heap, whereas we need in fact to compare the blocks they point to. So the
kind system makes it possible for each individual kind to decide how values
should be compared, returning an I6 schema prototype to compare |*1| and |*2|.

What happens at run-time when we test to see if value V equals value W,
or change storage object S so that it now contains value T, depends on the
kind of values we are discussing. If there were only word-based values in
Inform (as was the case until September 2007), there would be little to
do here, as the comparison would simply compile to |V == W|, while the
storage would be a matter of either |S = W;| or some more exotic case
along the lines of |StorageRoutineWrite(S, W);|.

But once pointers to blocks are allowed, this becomes more interesting.
Now the comparison needs to be a deep one, that is, we want to test whether
two texts (say) have the same textual content -- not whether we are
holding two pointers to the same blocks in memory, which is what a simple
comparison would achieve. Such a test is called "deep comparison", and
similarly, we must assign by transferring the contents of the blocks of
data, not merely the pointer to them, which is a "deep copy".

=
text_stream *RTKinds::interpret_test_equality(kind *left, kind *right) {
	LOGIF(KIND_CHECKING, "Interpreting equality test of kinds %u, %u\n", left, right);

	if ((Kinds::eq(left, K_truth_state)) || (Kinds::eq(right, K_truth_state)))
		return I"(*1 && true) == (*2 && true)";

	kind_constructor *L = NULL, *R = NULL;
	if ((left) && (right)) { L = left->construct; R = right->construct; }

	kind_constructor_comparison_schema *dtcs;
	for (dtcs = L->first_comparison_schema; dtcs; dtcs = dtcs->next_comparison_schema) {
		if (Str::len(dtcs->comparator_unparsed) > 0) {
			dtcs->comparator = KindConstructors::parse(dtcs->comparator_unparsed);
			Str::clear(dtcs->comparator_unparsed);
		}
		if (R == dtcs->comparator) return dtcs->comparison_schema;
	}

	if (KindConstructors::uses_pointer_values(L)) {
		if (KindConstructors::allow_word_as_pointer(L, R)) {
			local_block_value *pall =
				Frames::allocate_local_block_value(Kinds::base_construction(L));
			text_stream *promotion = Str::new();
			WRITE_TO(promotion, "*=-BlkValueCompare(*1, BlkValueCast(%S, *#2, *2))==0",
				pall->to_refer->prototype);
			return promotion;
		}
	}

	text_stream *cr = Kinds::Behaviour::get_comparison_routine(left);
	if ((Str::len(cr) == 0) ||
		(Str::eq_wide_string(cr, L"signed")) ||
		(Str::eq_wide_string(cr, L"UnsignedCompare"))) return I"*=-*1 == *2";
	return I"*=- *_1(*1, *2) == 0";
}

@h Casts at runtime.

=
int RTKinds::cast_possible(kind *from, kind *to) {
	from = Kinds::weaken(from, K_object);
	to = Kinds::weaken(to, K_object);
	if ((to) && (from) && (to->construct != from->construct) &&
		(Kinds::Behaviour::definite(to)) && (Kinds::Behaviour::definite(from)) &&
		(Kinds::eq(from, K_object) == FALSE) &&
		(Kinds::eq(to, K_object) == FALSE) &&
		(to->construct != CON_property))
		return TRUE;
	return FALSE;
}

@ =
int RTKinds::emit_cast_call(kind *from, kind *to, int *down) {
	if (RTKinds::cast_possible(from, to)) {
		if (Str::len(Kinds::Behaviour::get_identifier(to)) == 0) {
			return TRUE;
		}
		if ((Kinds::FloatingPoint::uses_floating_point(from)) &&
			(Kinds::FloatingPoint::uses_floating_point(to))) {
			return TRUE;
		}
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "%S_to_%S",
			Kinds::Behaviour::get_identifier(from),
			Kinds::Behaviour::get_identifier(to));
		inter_name *iname = Produce::find_by_name(Emit::tree(), N);
		DISCARD_TEXT(N)
		EmitCode::call(iname);
		*down = TRUE;
		EmitCode::down();
		if (Kinds::Behaviour::uses_pointer_values(to)) {
			Frames::emit_new_local_value(to);
		}
		return TRUE;
	}
	return FALSE;
}

@h The heap.
Texts, lists and other flexibly-sized structures make use of a pool of
run-time storage called "the heap".

Management of the heap is delegated to runtime code in the template file
"Flex.i6t", so Inform itself needs to know surprisingly little about
how the job is done.

=
int total_heap_allocation = 0;

void RTKinds::ensure_basic_heap_present(void) {
	total_heap_allocation += 256; /* enough for the initial free-space block */
}

@ We need to provide a start-up routine which creates initial blocks of
data on the heap for any permanent storage objects (global variables,
property values, table entries, list items) of pointer-value kinds:

=
void RTKinds::compile_heap_allocator(void) {
	@<Compile a constant for the heap size needed@>;
}

@ By now, we know that we need at least |total_heap_allocation| bytes on the
heap, but the initial heap size has to be a power of 2, so we compute the
smallest such which is big enough. On Glulx, we then multiply by 4: one factor
of 2 is because the word size is twice as much -- words are 4-byte, not 2-byte
as on the Z-machine -- while the other is, basically, because we can, and
because we want to store text in particular using 2-byte characters (capable
of storing Unicode) rather than 1-byte characters as on the Z-machine. Glulx
has essentially no memory constraints compared with the Z-machine.

@<Compile a constant for the heap size needed@> =
	int max_heap = 1;
	if (total_heap_allocation < global_compilation_settings.dynamic_memory_allocation)
		total_heap_allocation = global_compilation_settings.dynamic_memory_allocation;
	while (max_heap < total_heap_allocation) max_heap = max_heap*2;
	if (TargetVMs::is_16_bit(Task::vm()))
		RTKinds::compile_nnci(Hierarchy::find(MEMORY_HEAP_SIZE_HL), max_heap);
	else
		RTKinds::compile_nnci(Hierarchy::find(MEMORY_HEAP_SIZE_HL), 4*max_heap);
	LOG("Providing for a total heap of %d, given requirement of %d\n",
		max_heap, total_heap_allocation);

@ The following routine both compiles code to create a pointer value, and
also increments the heap allocation suitably. Each pointer-value kind comes
with an estimate of its likely size needs -- its exact size needs if it is
fixed in size, and a reasonable overestimate of typical usage if it is
flexible.

The |multiplier| is used when we need to calculate the size of, say, a
list of 20 texts. For the cases above, it's always 1.

=
typedef struct heap_allocation {
	struct kind *allocated_kind;
	int stack_offset;
} heap_allocation;

heap_allocation RTKinds::make_heap_allocation(kind *K, int multiplier,
	int stack_offset) {
	if (Kinds::Behaviour::uses_pointer_values(K) == FALSE)
		internal_error("unable to allocate heap storage for this kind of value");
	if (Kinds::Behaviour::get_heap_size_estimate(K) == 0)
		internal_error("no heap storage estimate for this kind of value");

	total_heap_allocation += (Kinds::Behaviour::get_heap_size_estimate(K) + 8)*multiplier;

	if (Kinds::get_construct(K) == CON_relation)
		RTKindIDs::precompile_default_value(K);

	heap_allocation ha;
	ha.allocated_kind = K;
	ha.stack_offset = stack_offset;
	return ha;
}

void RTKinds::emit_heap_allocation(heap_allocation ha) {
	if (ha.stack_offset >= 0) {
		inter_name *iname = Hierarchy::find(BLKVALUECREATEONSTACK_HL);
		EmitCode::call(iname);
		EmitCode::down();
		EmitCode::val_number((inter_ti) ha.stack_offset);
		RTKindIDs::emit_strong_ID_as_val(ha.allocated_kind);
		EmitCode::up();
	} else {
		inter_name *iname = Hierarchy::find(BLKVALUECREATE_HL);
		EmitCode::call(iname);
		EmitCode::down();
		RTKindIDs::emit_strong_ID_as_val(ha.allocated_kind);
		EmitCode::up();
	}
}

@

@d BLK_FLAG_MULTIPLE 0x00000001
@d BLK_FLAG_16_BIT   0x00000002
@d BLK_FLAG_WORD     0x00000004
@d BLK_FLAG_RESIDENT 0x00000008
@d BLK_FLAG_TRUNCMULT 0x00000010

=
void RTKinds::emit_block_value_header(kind *K, int individual, int size) {
	if (individual == FALSE) EmitArrays::numeric_entry(0);
	int n = 0, c = 1, w = 4;
	if (TargetVMs::is_16_bit(Task::vm())) w = 2;
	while (c < (size + 3)*w) { n++; c = c*2; }
	int flags = BLK_FLAG_RESIDENT + BLK_FLAG_WORD;
	if (Kinds::get_construct(K) == CON_list_of) flags += BLK_FLAG_TRUNCMULT;
	if (Kinds::get_construct(K) == CON_relation) flags += BLK_FLAG_MULTIPLE;
	if (TargetVMs::is_16_bit(Task::vm()))
		EmitArrays::numeric_entry((inter_ti) (0x100*n + flags));
	else
		EmitArrays::numeric_entry((inter_ti) (0x1000000*n + 0x10000*flags));
	EmitArrays::iname_entry(RTKindIDs::weak_iname(K));

	EmitArrays::iname_entry(Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
}

@h Run-time support for units and enumerations.
The following generates a small suite of I6 routines associated with
each such kind, and needed at run-time.

=
int RTKinds::base_represented_in_inter(kind *K) {
	if ((Kinds::Behaviour::is_kind_of_kind(K) == FALSE) &&
		(Kinds::is_proper_constructor(K) == FALSE) &&
		(K != K_void) &&
		(K != K_unknown) &&
		(K != K_nil)) return TRUE;
	return FALSE;
}

typedef struct kind_interaction {
	struct kind *noted_kind;
	struct inter_name *noted_iname;
	CLASS_DEFINITION
} kind_interaction;

@

@d MAX_KIND_ARITY 32

=
inter_name *RTKinds::iname(kind *K) {
	if (RTKinds::base_represented_in_inter(K) == FALSE) {
		kind_interaction *KI;
		LOOP_OVER(KI, kind_interaction)
			if (Kinds::eq(K, KI->noted_kind))
				return KI->noted_iname;
	}
	inter_name *S = RTKinds::iname_inner(K);
	if (RTKinds::base_represented_in_inter(K) == FALSE) {
		kind_interaction *KI = CREATE(kind_interaction);
		KI->noted_kind = K;
		KI->noted_iname = S;
		int arity = 0;
		kind *operands[MAX_KIND_ARITY];
		int icon = -1;
		inter_ti idt = ROUTINE_IDT;
		if (Kinds::get_construct(K) == CON_description) @<Run out inter kind for description@>
		else if (Kinds::get_construct(K) == CON_list_of) @<Run out inter kind for list@>
		else if (Kinds::get_construct(K) == CON_phrase) @<Run out inter kind for phrase@>
		else if (Kinds::get_construct(K) == CON_rule) @<Run out inter kind for rule@>
		else if (Kinds::get_construct(K) == CON_rulebook) @<Run out inter kind for rulebook@>
		else if (Kinds::get_construct(K) == CON_table_column) @<Run out inter kind for column@>
		else if (Kinds::get_construct(K) == CON_relation) @<Run out inter kind for relation@>
		else {
			LOG("Unfortunate kind is: %u\n", K);
			internal_error("unable to represent kind in inter");
		}
		if (icon < 0) internal_error("icon unset");
		Emit::kind(S, idt, NULL, icon, arity, operands);
	}
	return S;
}

@<Run out inter kind for list@> =
	arity = 1;
	operands[0] = Kinds::unary_construction_material(K);
	icon = LIST_ICON;
	idt = LIST_IDT;

@<Run out inter kind for description@> =
	arity = 1;
	operands[0] = Kinds::unary_construction_material(K);
	icon = DESCRIPTION_ICON;

@<Run out inter kind for column@> =
	arity = 1;
	operands[0] = Kinds::unary_construction_material(K);
	icon = COLUMN_ICON;

@<Run out inter kind for relation@> =
	arity = 2;
	Kinds::binary_construction_material(K, &operands[0], &operands[1]);
	icon = RELATION_ICON;

@<Run out inter kind for phrase@> =
	icon = FUNCTION_ICON;
	kind *X = NULL, *result = NULL;
	Kinds::binary_construction_material(K, &X, &result);
	while (Kinds::get_construct(X) == CON_TUPLE_ENTRY) {
		kind *A = NULL;
		Kinds::binary_construction_material(X, &A, &X);
		operands[arity++] = A;
	}
	if (arity == 0) {
		operands[arity++] = NULL; /* void arguments */
	}
	operands[arity++] = result;

@<Run out inter kind for rule@> =
	arity = 2;
	Kinds::binary_construction_material(K, &operands[0], &operands[1]);
	icon = RULE_ICON;

@<Run out inter kind for rulebook@> =
	arity = 1;
	kind *X = NULL, *Y = NULL;
	Kinds::binary_construction_material(K, &X, &Y);
	operands[0] = Kinds::binary_con(CON_phrase, X, Y);
	icon = RULEBOOK_ICON;

@ =
int object_kind_count = 1;
inter_name *RTKinds::iname_inner(kind *K) {
	if (Kinds::is_proper_constructor(K)) {
		return RTKinds::constructed_kind_name(K);
	}
	if (RTKinds::base_represented_in_inter(K)) {
		return RTKinds::assure_iname_exists(K);
	}
	return NULL;
}

inter_name *RTKinds::assure_iname_exists(kind *K) {
	noun *nt = Kinds::Behaviour::get_noun(K);
	if (nt) {
		if (NounIdentifiers::iname_set(nt) == FALSE) {
			inter_name *iname = RTKinds::constructed_kind_name(K);
			NounIdentifiers::set_iname(nt, iname);
		}
	}
	return NounIdentifiers::iname(nt);
}

inter_name *RTKinds::constructed_kind_name(kind *K) {
	package_request *R2 = RTKindConstructors::kind_package(K);
	TEMPORARY_TEXT(KT)
	Kinds::Textual::write(KT, K);
	wording W = Feeds::feed_text(KT);
	DISCARD_TEXT(KT)
	int v = -2;
	if (Kinds::Behaviour::is_subkind_of_object(K)) v = RTKinds::I6_classnumber(K);
	return Hierarchy::make_iname_with_memo_and_value(KIND_CLASS_HL, R2, W, v);
}

@ =
void RTKinds::emit(kind *K) {
	if (K == NULL) internal_error("tried to emit null kind");
	if (InterNames::is_defined(RTKinds::iname(K))) return;
	inter_ti dt = INT32_IDT;
	if (K == K_object) dt = ENUM_IDT;
	if (Kinds::Behaviour::is_an_enumeration(K)) dt = ENUM_IDT;
	if (K == K_truth_state) dt = INT2_IDT;
	if (K == K_text) dt = TEXT_IDT;
	if (K == K_table) dt = TABLE_IDT;
	kind *S = Latticework::super(K);
	if ((S) && (Kinds::conforms_to(S, K_object) == FALSE)) S = NULL;
	if (S) {
		RTKinds::emit(S);
		dt = ENUM_IDT;
	}
	Emit::kind(RTKinds::iname(K), dt, S?RTKinds::iname(S):NULL, BASE_ICON, 0, NULL);
	if (K == K_object) {
		Produce::change_translation(RTKinds::iname(K), I"K0_kind");
		Hierarchy::make_available(RTKinds::iname(K));
	}
}

void RTKinds::kind_declarations(void) {
	kind *K; inter_ti c = 0;
	LOOP_OVER_BASE_KINDS(K)
		if (RTKinds::base_represented_in_inter(K)) {
			RTKinds::emit(K);
			inter_name *iname = RTKinds::iname(K);
			Produce::annotate_i(iname, SOURCE_ORDER_IANN, c++);
		}
}

void RTKinds::compile_nnci(inter_name *name, int val) {
	Emit::numeric_constant(name, (inter_ti) val);
	Hierarchy::make_available(name);
}

void RTKinds::compile_instance_counts(void) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K) {
		if ((Kinds::Behaviour::is_an_enumeration(K)) || (Kinds::Behaviour::is_object(K))) {
			TEMPORARY_TEXT(ICN)
			WRITE_TO(ICN, "ICOUNT_");
			Kinds::Textual::write(ICN, K);
			Str::truncate(ICN, 31);
			LOOP_THROUGH_TEXT(pos, ICN) {
				Str::put(pos, Characters::toupper(Str::get(pos)));
				if (Characters::isalnum(Str::get(pos)) == FALSE) Str::put(pos, '_');
			}
			inter_name *iname = Hierarchy::make_iname_with_specific_translation(ICOUNT_HL, InterSymbolsTables::render_identifier_unique(Produce::main_scope(Emit::tree()), ICN), RTKindConstructors::kind_package(K));
			Hierarchy::make_available(iname);
			DISCARD_TEXT(ICN)
			Emit::numeric_constant(iname, (inter_ti) Instances::count(K));
		}
	}

	RTKinds::compile_nnci(Hierarchy::find(MAX_FRAME_SIZE_NEEDED_HL), SharedVariables::size_of_largest_set());
	RTKinds::compile_nnci(Hierarchy::find(RNG_SEED_AT_START_OF_PLAY_HL), Task::rng_seed());
}

@ =
int VM_non_support_problem_issued = FALSE;
void RTKinds::notify_of_use(kind *K) {
	if (RTKinds::target_VM_supports(K) == FALSE) {
		if (VM_non_support_problem_issued == FALSE) {
			VM_non_support_problem_issued = TRUE;
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_KindRequiresGlulx));
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind(2, K);
			Problems::issue_problem_segment(
				"You wrote %1, but with the settings for this project as they are, "
				"I'm unable to make use of %2. (Try changing to Glulx on the Settings "
				"panel; that should fix it.)");
			Problems::issue_problem_end();

		}
	}
}

int RTKinds::target_VM_supports(kind *K) {
	target_vm *VM = Task::vm();
	if (VM == NULL) internal_error("target VM not set yet");
	if ((Kinds::FloatingPoint::uses_floating_point(K)) &&
		(TargetVMs::supports_floating_point(VM) == FALSE)) return FALSE;
	return TRUE;
}

@ Three method functions for the kinds family of inference subjects:

=
int RTKinds::emit_element_of_condition(inference_subject_family *family,
	inference_subject *infs, inter_symbol *t0_s) {
	kind *K = KindSubjects::to_kind(infs);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		EmitCode::inv(OFCLASS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, t0_s);
			EmitCode::val_iname(K_value, RTKinds::I6_classname(K));
		EmitCode::up();
		return TRUE;
	}
	if (Kinds::eq(K, K_object)) {
		EmitCode::val_symbol(K_value, t0_s);
		return TRUE;
	}
	return FALSE;
}

@ These functions emit the great stream of Inter commands needed to define the
kinds and their properties.

First, we will call |RTPropertyValues::emit_subject| for all kinds of object,
beginning with object and working downwards through the tree of its subkinds.
After that, we call it for all other kinds able to have properties, in no
particular order.

=
int RTKinds::emit_all(inference_subject_family *f, int ignored) {
	RTKinds::emit_recursive(KindSubjects::from_kind(K_object));
	return FALSE;
}

void RTKinds::emit_recursive(inference_subject *within) {
	RTPropertyValues::emit_subject(within);
	inference_subject *subj;
	LOOP_OVER(subj, inference_subject)
		if ((InferenceSubjects::narrowest_broader_subject(subj) == within) &&
			(InferenceSubjects::is_a_kind_of_object(subj))) {
			RTKinds::emit_recursive(subj);
		}
}

void RTKinds::emit_one(inference_subject_family *f, inference_subject *infs) {
	kind *K = KindSubjects::to_kind(infs);
	if ((KindSubjects::has_properties(K)) &&
		(Kinds::Behaviour::is_object(K) == FALSE))
		RTPropertyValues::emit_subject(infs);
	RTKinds::check_can_have_property(K);
}

@h Avoiding a hacky Inter-level problem.
This is a rather distasteful provision, like everything to do with Inter
translation. But we don't want to hand the problem downstream to the code
generator; we want to deal with it now. The issue arises with source text like:

>> A keyword is a kind of value. The keywords are xyzzy, plugh. A keyword can be mentioned.

where "mentioned" is implemented for objects as an attribute in Inter.

That would make it impossible for the code-generator to store the property
instead in a flat array, which is how it will want to handle properties of
values. There are ways we could fix this, but property lookup needs to be fast,
and it seems best to reject the extra complexity needed.

=
void RTKinds::check_can_have_property(kind *K) {
	if (Kinds::Behaviour::is_object(K)) return;
	if (Kinds::Behaviour::definite(K) == FALSE) return;
	property *prn;
	property_permission *pp;
	instance *I_of;
	inference_subject *infs;
	LOOP_OVER_INSTANCES(I_of, K)
		for (infs = Instances::as_subject(I_of); infs;
			infs = InferenceSubjects::narrowest_broader_subject(infs))
			LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs)
				if (((prn = PropertyPermissions::get_property(pp))) &&
					(RTProperties::can_be_compiled(prn)) &&
					(problem_count == 0) &&
					(RTProperties::has_been_translated(prn)) &&
					(Properties::is_either_or(prn)))
					@<Bitch about our implementation woes, like it's not our fault@>;
}

@<Bitch about our implementation woes, like it's not our fault@> =
	current_sentence = PropertyPermissions::where_granted(pp);
	Problems::quote_source(1, current_sentence);
	Problems::quote_property(2, prn);
	Problems::quote_kind(3, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AnomalousProperty));
	Problems::issue_problem_segment(
		"Sorry, but I'm going to have to disallow the sentence %1, even "
		"though it asks for something reasonable. A very small number "
		"of either-or properties with meanings special to Inform, like '%2', "
		"are restricted so that only kinds of object can have them. Since "
		"%3 isn't a kind of object, it can't be said to be %2. %P"
		"Probably you only need to call the property something else. The "
		"built-in meaning would only make sense if it were a kind of object "
		"in any case, so nothing is lost. Sorry for the inconvenience, all "
		"the same; there are good implementation reasons.");
	Problems::issue_problem_end();
