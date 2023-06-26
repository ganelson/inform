[Kinds::Behaviour::] Using Kinds.

To determine the characteristics of different kinds, enabling them
to be used in practice.

@h Names of kinds.

=
wording Kinds::Behaviour::get_name(kind *K, int plural_form) {
	if (K == NULL) return EMPTY_WORDING;
	return KindConstructors::get_name(K->construct, plural_form);
}

wording Kinds::Behaviour::get_name_in_play(kind *K, int plural_form,
	NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	if (K == NULL) return EMPTY_WORDING;
	return KindConstructors::get_name_in_play(K->construct, plural_form, nl);
}

noun *Kinds::Behaviour::get_noun(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->dt_tag;
}

int Kinds::Behaviour::get_range_number(kind *K) {
	if (K == NULL) return 0;
	return K->construct->class_number;
}

void Kinds::Behaviour::set_range_number(kind *K, int r) {
	if (K == NULL) return;
	K->construct->class_number = r;
}

@h Being an object.

=
int Kinds::Behaviour::is_object(kind *K) {
	if ((Kinds::conforms_to(K, K_object)) &&
		(Kinds::eq(K, K_nil) == FALSE) && (Kinds::eq(K, K_void) == FALSE))
		return TRUE;
	return FALSE;
}

int Kinds::Behaviour::is_subkind_of_object(kind *K) {
	if ((Kinds::conforms_to(K, K_object)) && (Kinds::eq(K, K_object) == FALSE) &&
		(Kinds::eq(K, K_nil) == FALSE) && (Kinds::eq(K, K_void) == FALSE))
		return TRUE;
	return FALSE;
}

int Kinds::Behaviour::is_object_of_kind(kind *K, kind *L) {
	if ((Kinds::conforms_to(K, K_object)) && (Kinds::conforms_to(K, L)) &&
		(Kinds::eq(K, K_nil) == FALSE) && (Kinds::eq(K, K_void) == FALSE))
		return TRUE;
	return FALSE;
}

@h Definiteness.
A kind like "number" is definite. One way to be indefinite is to be a
kind of kind, like "arithmetic value":

=
int Kinds::Behaviour::is_kind_of_kind(kind *K) {
	if (K == NULL) return FALSE;
	if (K->construct->group == PROTOCOL_GRP) return TRUE;
	return FALSE;
}

@ Another way is to be a kind variable, like "Q", or to be a construction
made from something indefinite, like "list of values". So the following
checks that we aren't doing that:

=
int Kinds::Behaviour::definite(kind *K) {
	if (K == NULL) return TRUE;
	if (KindConstructors::is_definite(K->construct) == FALSE) return FALSE;
	int arity = KindConstructors::arity(K->construct);
	for (int i=0; i<arity; i++)
		if (Kinds::Behaviour::definite(K->kc_args[i]) == FALSE)
			return FALSE;
	return TRUE;
}

int Kinds::Behaviour::semidefinite(kind *K) {
	if (K == NULL) return TRUE;
	if (K->construct == CON_KIND_VARIABLE) return TRUE;
	if (K->construct == CON_NIL) return FALSE;
	if (KindConstructors::is_definite(K->construct) == FALSE) return FALSE;
	int arity = KindConstructors::arity(K->construct);
	if ((K->construct == CON_TUPLE_ENTRY) && (Kinds::eq(K->kc_args[1], K_void))) arity = 1;
	if ((K->construct == CON_phrase) || (K->construct == CON_activity)) {
		for (int i=0; i<arity; i++)
			if ((Kinds::eq(K->kc_args[i], K_nil) == FALSE) &&
				(Kinds::Behaviour::semidefinite(K->kc_args[i]) == FALSE))
				return FALSE;
	} else {
		for (int i=0; i<arity; i++)
			if (Kinds::Behaviour::semidefinite(K->kc_args[i]) == FALSE)
				return FALSE;
	}
	return TRUE;
}

int Kinds::Behaviour::involves_var(kind *K, int v) {
	if (K == NULL) return FALSE;
	if ((K->construct == CON_KIND_VARIABLE) && (v == K->kind_variable_number))
		return TRUE;
	int i, arity = KindConstructors::arity(K->construct);
	for (i=0; i<arity; i++)
		if (Kinds::Behaviour::involves_var(K->kc_args[i], v))
			return TRUE;
	return FALSE;
}

@h (A) How this came into being.
A kind is "built in" if it was created via commands in a Neptune file:
see //Neptune Files//. It otherwise arises by being defined in source text.

Note that a kind of object counts as built-in by this test, even though it
might be a kind of object created in the source text, because at the end of
the day "object" is built in.

=
int Kinds::Behaviour::is_built_in(kind *K) {
	if (K == NULL) return FALSE;
	if (K->construct->where_defined_in_source_text) return FALSE;
	return TRUE;
}

parse_node *Kinds::Behaviour::get_creating_sentence(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->where_defined_in_source_text;
}

@ When we read "Colour is a kind of value.", "colour" is uncertainly
defined at first. Later we read either "The colours are blue and pink.",
say, and then "colour" becomes an enumeration; or "450 nanometers
specifies a colour.", say, and then it becomes a unit.	Initially, then,
it has an incompletely defined flag set: once one of the conversion routines
has been used, the matter is settled and there is no going back.

=
int Kinds::Behaviour::is_uncertainly_defined(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->is_incompletely_defined;
}

@ Here we test for being an enumeration:

=
int Kinds::Behaviour::is_an_enumeration(kind *K) {
	if (K == NULL) return FALSE;
	return KindConstructors::is_an_enumeration(K->construct);
}

@ And here we perform the conversion to a unit. The return value is |TRUE|
if the kind was already a unit or was successfully converted into one,
|FALSE| if it's now too late.

=
int Kinds::Behaviour::convert_to_unit(kind *K) {
	if (K == NULL) return FALSE;
	return KindConstructors::convert_to_unit(K->construct);
}

@ And similarly:

=
void Kinds::Behaviour::convert_to_enumeration(kind *K) {
	if (K) KindConstructors::convert_to_enumeration(K->construct);
}

@ And similarly to switch from integer to real arithmetic.

=
void Kinds::Behaviour::convert_to_real(kind *K) {
	if (K) KindConstructors::convert_to_real(K->construct);
}

@ The instances of an enumeration have the values $1, 2, 3, ..., N$ at
run-time; the following returns $N+1$, that is, a value which can be held
by the next instance to be created.

=
int Kinds::Behaviour::new_enumerated_value(kind *K) {
	if (K == NULL) return 0;
	Kinds::Behaviour::convert_to_enumeration(K);
	return K->construct->next_free_value++;
}

@h (B) Command parsing.

=
int Kinds::Behaviour::is_understandable(kind *K) {
	if (K == NULL) return FALSE;
	return KindConstructors::is_understandable(K->construct);
}

text_stream *Kinds::Behaviour::GPR_identifier(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->explicit_GPR_identifier;
}

text_stream *Kinds::Behaviour::recognition_only_GPR_identifier(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->recognition_routine;
}

@h (C) Compatibility with other kinds.

=
void Kinds::Behaviour::set_superkind_set_at(kind *K, parse_node *S) {
	if (K == NULL) internal_error("set_superkind_set_at for null kind");
	K->construct->superkind_set_at = S;
}

parse_node *Kinds::Behaviour::get_superkind_set_at(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->superkind_set_at;
}

@h (D) How constant values of this kind are expressed.
Some kinds have named constants, others use a quasi-numerical notation: for
instance "maroon" might be an instance of kind "colour", while "234
kilopascals" might be a notation for a kind where constants are not named.

=
int Kinds::Behaviour::has_named_constant_values(kind *K) {
	if (K == NULL) return FALSE;
	if (Kinds::Behaviour::is_an_enumeration(K)) return TRUE;
	if (Kinds::Behaviour::is_uncertainly_defined(K)) return TRUE;
	return FALSE;
}

@ And some kinds have values which are implicit in the source text, but never
spelled out with direct assertions -- dialogue beats, for example.

=
int Kinds::Behaviour::forbid_assertion_creation(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->forbid_assertion_creation;
}

@ The following returns the compilation method (a constant in the form |*_CCM|,
defined in "Data Types.w") used when compiling an actual constant value
specification of this kind: in other words, when compiling an I6
value for a constant of this kind.

=
int Kinds::Behaviour::get_constant_compilation_method(kind *K) {
	if (K == NULL) return NONE_CCM;
	return K->construct->constant_compilation_method;
}

@h (G) Performing arithmetic.
Comparisons made by calling an I6 routine are slower in the VM than using the
standard |<| or |>| operators for signed comparison, so we use them only if
we have to.

=
int Kinds::Behaviour::uses_signed_comparisons(kind *K) {
	if (K == NULL) return FALSE;
	return KindConstructors::uses_signed_comparisons(K->construct);
}

text_stream *Kinds::Behaviour::get_comparison_routine(kind *K) {
	if (K == NULL) return NULL;
	return KindConstructors::get_comparison_fn_identifier(K->construct);
}

@ See "Dimensions.w" for a full account of these ideas. In theory, our
polymorphic system of arithmetic allows us to add or multiply any kinds
according to rules provided in the source text. In practice we have to keep
track of dimensions, and the following routines connect the code in the
"Dimensions" section to kind structures.

=
int Kinds::Behaviour::is_quasinumerical(kind *K) {
	if (K == NULL) return FALSE;
	return KindConstructors::is_arithmetic(K->construct);
}

unit_sequence *Kinds::Behaviour::get_dimensional_form(kind *K) {
	if (K == NULL) return NULL;
	if (Kinds::Behaviour::is_quasinumerical(K) == FALSE) return NULL;
	if (K->construct == CON_INTERMEDIATE) return K->intermediate_result;
	return &(K->construct->dimensional_form);
}

int Kinds::Behaviour::test_if_derived(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->dimensional_form_fixed;
}

void Kinds::Behaviour::now_derived(kind *K) {
	if (K == NULL) internal_error("can't derive null kind");
	K->construct->dimensional_form_fixed = TRUE;
}

int Kinds::Behaviour::scale_factor(kind *K) {
	if (K == NULL) return 1;
	if (K->intermediate_result)
		return Kinds::Dimensions::us_get_scaling_factor(K->intermediate_result);
	#ifdef DETERMINE_SCALE_FACTOR_KINDS_CALLBACK
	return DETERMINE_SCALE_FACTOR_KINDS_CALLBACK(K);
	#else
	return 1;
	#endif
}

@ The dimensional rules for K are the conventions on whether arithmetic
operations can be applied, and if so, what kind the result has.

=
dimensional_rules *Kinds::Behaviour::get_dim_rules(kind *K) {
	if (K == NULL) return NULL;
	return &(K->construct->dim_rules);
}

@h (H) An identifier name.

=
int Kinds::Behaviour::comes_from_Neptune(kind *K) {
	if (K == NULL) return FALSE;
	if (Str::len(K->construct->explicit_identifier) > 0) return TRUE;
	return FALSE;
}

text_stream *Kinds::Behaviour::get_identifier(kind *K) {
	if (K == NULL) return I"UNKNOWN_NT";
	return K->construct->explicit_identifier;
}

@h (I) Storing values at run-time.
Recall that values are stored at run-time either as "word values" -- a
single I6 word -- or "pointer values" (sometimes "block values"), where
the I6 word is a pointer to a block of data on the heap. Numbers and times
are word values, texts and lists are pointer values. Which form a value
takes depends on its kind:

=
int Kinds::Behaviour::uses_block_values(kind *K) {
	if (K == NULL) return FALSE;
	return KindConstructors::uses_block_values(K->construct);
}

@ Exactly how large the small block is:

=
int Kinds::Behaviour::get_small_block_size(kind *K) {
	if (K == NULL) return 0;
	return K->construct->small_block_size;
}

@ A reasonable estimate of how large the (larger!) heap block needs to be,
for a pointer-value kind, in bytes.

=
int Kinds::Behaviour::get_heap_size_estimate(kind *K) {
	if (K == NULL) return 0;
	return K->construct->heap_size_estimate;
}

@ And the following returns the name of an I6 routine to determine if two
values of $K$ are different from each other; or |NULL| to say that it's
sufficient to apply |~=| to the values.

=
text_stream *Kinds::Behaviour::get_distinguisher(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->distinguishing_routine;
}

@ Can values of this kind be serialised out to a file and read back in again
by some other Inform story file, or by this one running on a different day?

=
int Kinds::Behaviour::can_exchange(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->can_exchange;
}

@h (K) Indexing and documentation.

=
text_stream *Kinds::Behaviour::get_documentation_reference(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->documentation_reference;
}

void Kinds::Behaviour::set_documentation_reference(kind *K, text_stream *dr) {
	if (K == NULL) return;
	K->construct->documentation_reference = Str::duplicate(dr);
}

@ The following is used in the Kinds index, in the table showing the default
values for each kind:

=
text_stream *Kinds::Behaviour::get_index_default_value(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->index_default_value;
}

text_stream *Kinds::Behaviour::get_index_minimum_value(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->index_minimum_value;
}

text_stream *Kinds::Behaviour::get_index_maximum_value(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->index_maximum_value;
}

int Kinds::Behaviour::get_index_priority(kind *K) {
	if (K == NULL) return 0;
	return K->construct->index_priority;
}

int Kinds::Behaviour::indexed_grey_if_empty(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->indexed_grey_if_empty;
}

@ And every kind is allowed to have the specification pseudo-property -- a little
text used only on the index pages, and not existing at run-time.

=
void Kinds::Behaviour::set_specification_text(kind *K, text_stream *desc) {
	if (K == NULL) internal_error("can't set specification for null kind");
	K->construct->specification_text = Str::duplicate(desc);
}

text_stream *Kinds::Behaviour::get_specification_text(kind *K) {
	if (K == NULL) internal_error("can't get specification of null kind");
	return K->construct->specification_text;
}

