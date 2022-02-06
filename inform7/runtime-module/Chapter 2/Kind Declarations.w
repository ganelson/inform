[RTKindDeclarations::] Kind Declarations.

Each different kind used anywhere in the tree must be declared with an Inter
kind declaration.

@h Inames for declarations.
A few kinds can never be used in Inter code, and are therefore exempt:

=
int RTKindDeclarations::base_represented_in_Inter(kind *K) {
	if ((Kinds::Behaviour::is_kind_of_kind(K) == FALSE) &&
		(Kinds::is_proper_constructor(K) == FALSE) &&
		(K != K_void) &&
		(K != K_unknown) &&
		(K != K_nil)) return TRUE;
	return FALSE;
}

@ But all other kinds -- number, person, list of texts, whatever may be --
need to be declared, and define an Inter symbol as an identifier for that kind.
For example:
= (text as Inter)
kind K_action_name int32
kind K_list_of_texts list of K_text
=
...make two kinds available in Inter, defining |K_action_name| and |K_list_of_texts|
to refer to them.

We need to remember what we have already declared, so that we don't declare the
same kind over and over. We use two different mechanisms for this:
(*) for base kinds, storing the iname as the identifier for the associated noun,
which is quicker to look up;
(*) for constructed kinds, storing it in a |cached_kind_declaration|, which is
slower but occurs considerably less often -- there are in practice relatively
few |cached_kind_declaration| objects created.

@ So, firstly, each base kind registers a new noun for itself here:

@d REGISTER_NOUN_KINDS_CALLBACK RTKindDeclarations::register

=
int no_kinds_of_object = 1;
noun *RTKindDeclarations::register(kind *K, kind *super, wording W, general_pointer data) {
	noun *nt = Nouns::new_common_noun(W, NEUTER_GENDER,
		ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
		KIND_SLOW_MC, data, Task::language_of_syntax());
	NameResolution::initialise(nt);
 	if (Kinds::Behaviour::is_object(super))
 		Kinds::Behaviour::set_range_number(K, no_kinds_of_object++);
 	return nt;
}

@ And secondly, here's where we cache inames for constructed kinds:

=
typedef struct cached_kind_declaration {
	struct kind *noted_kind;
	struct inter_name *noted_iname;
	CLASS_DEFINITION
} cached_kind_declaration;

@ Calling //RTKindDeclarations::iname// produces the |inter_name| referring to
the kind in Inter, ensuring that it has been declared exactly once.

=
inter_name *RTKindDeclarations::iname(kind *K) {
	if (RTKindDeclarations::base_represented_in_Inter(K)) {
		noun *nt = Kinds::Behaviour::get_noun(K);
		if ((nt) && (NounIdentifiers::iname_set(nt) == FALSE))
			NounIdentifiers::set_iname(nt, RTKindDeclarations::create_iname(K));
		return NounIdentifiers::iname(nt);
	}
	if (Kinds::is_proper_constructor(K) == FALSE) internal_error("bad kind"); 

	cached_kind_declaration *dec;
	LOOP_OVER(dec, cached_kind_declaration)
		if (Kinds::eq(K, dec->noted_kind))
			return dec->noted_iname;

	dec = CREATE(cached_kind_declaration);
	dec->noted_kind = K;
	dec->noted_iname = RTKindDeclarations::create_iname(K);
	RTKindDeclarations::declare_constructed_kind(dec);
	return dec->noted_iname;
}

@ Whichever cache is used, the following generates a name like |K_list_of_numbers|
for use in the kind declaration. It is called once only for any given |K|.

Note that in order to play nicely with code in //WorldModelKit// and elsewhere,
we want the names of kinds of objects to come out the same as they traditionally
have in Inform 6 and 7 code for many years: so, for example, |K3_direction|,
not |K_direction|. We do that by throwing in the "range number". See the
function //RTKindDeclarations::register// above for how these numbers originate;
they are in registration order, which does not necessarily correspond to the
sequence in which declarations are made here.

=
inter_name *RTKindDeclarations::create_iname(kind *K) {
	package_request *R = RTKindConstructors::package(K->construct);
	TEMPORARY_TEXT(KT)
	Kinds::Textual::write(KT, K);
	wording W = Feeds::feed_text(KT);
	DISCARD_TEXT(KT)
	int v = -2;
	if (Kinds::Behaviour::is_subkind_of_object(K)) v = Kinds::Behaviour::get_range_number(K);
	inter_name *iname = Hierarchy::make_iname_with_memo_and_value(KIND_CLASS_HL, R, W, v);
	if (Kinds::is_proper_constructor(K) == FALSE) Hierarchy::make_available(iname);
	return iname;
}

@h Actual declarations.
First, base kinds:

=
void RTKindDeclarations::declare_base_kinds(void) {
	kind *K; inter_ti c = 0;
	LOOP_OVER_BASE_KINDS(K)
		if (RTKindDeclarations::base_represented_in_Inter(K)) {
			RTKindDeclarations::declare_base_kind(K);
			inter_name *iname = RTKindDeclarations::iname(K);
			InterNames::annotate_i(iname, SOURCE_ORDER_IANN, c++);
		}
}

@ Note the little dance here to ensure that if K is a subkind of L, then L
is always declared before K, even if K appears before L in the original
source text.

=
void RTKindDeclarations::declare_base_kind(kind *K) {
	if (K == NULL) internal_error("tried to emit null kind");
	if (InterNames::is_defined(RTKindDeclarations::iname(K))) return;
	inter_ti dt = INT32_IDT;
	if (K == K_object) dt = ENUM_IDT;
	if (Kinds::Behaviour::is_an_enumeration(K)) dt = ENUM_IDT;
	if (K == K_truth_state) dt = INT2_IDT;
	if (K == K_text) dt = TEXT_IDT;
	if (K == K_table) dt = TABLE_IDT;
	kind *S = Latticework::super(K);
	if ((S) && (Kinds::conforms_to(S, K_object) == FALSE)) S = NULL;
	if (S) {
		RTKindDeclarations::declare_base_kind(S);
		dt = ENUM_IDT;
	}
	Emit::kind(RTKindDeclarations::iname(K), dt, S?RTKindDeclarations::iname(S):NULL,
		BASE_ICON, 0, NULL);
	if (K == K_object) {
		InterNames::set_translation(RTKindDeclarations::iname(K), I"K0_kind");
		Hierarchy::make_available(RTKindDeclarations::iname(K));
	}
}

@ And now constructed kinds.

=
void RTKindDeclarations::declare_constructed_kind(cached_kind_declaration *dec) {
	kind *K = dec->noted_kind;
	int arity = 0;
	kind *operands[MAX_KIND_ARITY];
	int icon = -1;
	inter_ti idt = ROUTINE_IDT;
	if (Kinds::get_construct(K) == CON_description)       @<Run out inter kind for description@>
	else if (Kinds::get_construct(K) == CON_list_of)      @<Run out inter kind for list@>
	else if (Kinds::get_construct(K) == CON_phrase)       @<Run out inter kind for phrase@>
	else if (Kinds::get_construct(K) == CON_rule)         @<Run out inter kind for rule@>
	else if (Kinds::get_construct(K) == CON_rulebook)     @<Run out inter kind for rulebook@>
	else if (Kinds::get_construct(K) == CON_table_column) @<Run out inter kind for column@>
	else if (Kinds::get_construct(K) == CON_relation)     @<Run out inter kind for relation@>
	else {
		LOG("Unfortunate kind is: %u\n", K);
		internal_error("unable to represent kind in inter");
	}
	if (icon < 0) internal_error("icon unset");
	Emit::kind(dec->noted_iname, idt, NULL, icon, arity, operands);
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
