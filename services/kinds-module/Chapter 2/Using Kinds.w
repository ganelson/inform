[Kinds::Behaviour::] Using Kinds.

To determine the characteristics of different kinds, enabling them
to be used in practice.

@h Names of kinds.

=
wording Kinds::Behaviour::get_name(kind *K, int plural_form) {
	if (K == NULL) return EMPTY_WORDING;
	return Kinds::Constructors::get_name(K->construct, plural_form);
}

wording Kinds::Behaviour::get_name_in_play(kind *K, int plural_form, NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	if (K == NULL) return EMPTY_WORDING;
	return Kinds::Constructors::get_name_in_play(K->construct, plural_form, nl);
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
	if ((Kinds::Compare::le(K, K_object)) && (Kinds::Compare::eq(K, K_nil) == FALSE))
		return TRUE;
	return FALSE;
}

int Kinds::Behaviour::is_object_of_kind(kind *K, kind *L) {
	if ((Kinds::Compare::le(K, K_object)) && (Kinds::Compare::le(K, L)) &&
		(Kinds::Compare::eq(K, K_nil) == FALSE))
		return TRUE;
	return FALSE;
}

@h Definiteness.
A kind like "number" is definite. One way to be indefinite is to be a
kind of kind, like "arithmetic value":

=
int Kinds::Behaviour::is_kind_of_kind(kind *K) {
	if (K == NULL) return FALSE;
	if (K->construct->group == KIND_OF_KIND_GRP) return TRUE;
	return FALSE;
}

@ Another way is to be a kind variable, like "Q", or to be a construction
made from something indefinite, like "list of values". So the following
checks that we aren't doing that:

=
int Kinds::Behaviour::definite(kind *K) {
	if (K == NULL) return TRUE;
	if (Kinds::Constructors::is_definite(K->construct) == FALSE) return FALSE;
	int i, arity = Kinds::Constructors::arity(K->construct);
	for (i=0; i<arity; i++)
		if (Kinds::Behaviour::definite(K->kc_args[i]) == FALSE)
			return FALSE;
	return TRUE;
}

int Kinds::Behaviour::semidefinite(kind *K) {
	if (K == NULL) return TRUE;
	if (K->construct == CON_KIND_VARIABLE) return TRUE;
	if (K->construct == CON_NIL) return FALSE;
	if (Kinds::Constructors::is_definite(K->construct) == FALSE) return FALSE;
	int i, arity = Kinds::Constructors::arity(K->construct);
	if ((K->construct == CON_TUPLE_ENTRY) && (Kinds::Compare::eq(K->kc_args[1], K_nil))) arity = 1;
	if (K->construct == CON_phrase) {
		for (i=0; i<arity; i++)
			if ((Kinds::Compare::eq(K->kc_args[i], K_nil) == FALSE) &&
				(Kinds::Behaviour::semidefinite(K->kc_args[i]) == FALSE))
				return FALSE;
	} else {
		for (i=0; i<arity; i++)
			if (Kinds::Behaviour::semidefinite(K->kc_args[i]) == FALSE)
				return FALSE;
	}
	return TRUE;
}

int Kinds::Behaviour::involves_var(kind *K, int v) {
	if (K == NULL) return FALSE;
	if ((K->construct == CON_KIND_VARIABLE) && (v == K->kind_variable_number))
		return TRUE;
	int i, arity = Kinds::Constructors::arity(K->construct);
	for (i=0; i<arity; i++)
		if (Kinds::Behaviour::involves_var(K->kc_args[i], v))
			return TRUE;
	return FALSE;
}

@h (A) How this came into being.
Some kinds are built in (in that the I6 template files create them, using
the kind interpreter), while others arise from "X is a kind of value"
sentences in the source text.

Note that a kind of object counts as built-in by this test, even though it
might be a kind of object created in the source text, because at the end of
the day "object" is built in.

=
int Kinds::Behaviour::is_built_in(kind *K) {
	if (K == NULL) return FALSE;
	if (K->construct->defined_in_source_text) return FALSE;
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
	return Kinds::Constructors::is_enumeration(K->construct);
}

@ And here we perform the conversion to a unit. The return value is |TRUE|
if the kind was already a unit or was successfully converted into one,
|FALSE| if it's now too late.

=
int Kinds::Behaviour::convert_to_unit(parse_node_tree *T, kind *K) {
	if (K == NULL) return FALSE;
	return Kinds::Constructors::convert_to_unit(T, K->construct);
}

@ And similarly:

=
void Kinds::Behaviour::convert_to_enumeration(parse_node_tree *T, kind *K) {
	if (K) Kinds::Constructors::convert_to_enumeration(T, K->construct);
}

@ And similarly to switch from integer to real arithmetic.

=
void Kinds::Behaviour::convert_to_real(parse_node_tree *T, kind *K) {
	if (K) Kinds::Constructors::convert_to_real(T, K->construct);
}

@ The instances of an enumeration have the values $1, 2, 3, ..., N$ at
run-time; the following returns $N+1$, that is, a value which can be held
by the next instance to be created.

=
int Kinds::Behaviour::new_enumerated_value(parse_node_tree *T, kind *K) {
	if (K == NULL) return 0;
	Kinds::Behaviour::convert_to_enumeration(T, K);
	return K->construct->next_free_value++;
}

@ At present we aren't using named aliases for kinds, but we may in future.

=
kind *Kinds::Behaviour::stored_as(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->stored_as;
}

@h (B) Constructing kinds.


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
	if (K->construct->named_values_created_with_assertions) return TRUE;
	return FALSE;
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

@ The following is used only when the kind has named instances.

=
int Kinds::Behaviour::get_highest_valid_value_as_integer(kind *K) {
	if (K == NULL) return 0;
	kind_constructor *con = K->construct;
	#ifdef CORE_MODULE
	if (con == CON_activity) return NUMBER_CREATED(activity);
	if (con == Kinds::get_construct(K_equation)) return NUMBER_CREATED(equation);
	if (con == CON_rule) return NUMBER_CREATED(booking);
	if (con == CON_rulebook) return NUMBER_CREATED(rulebook);
	if (con == Kinds::get_construct(K_table)) return NUMBER_CREATED(table) + 1;
	if (con == Kinds::get_construct(K_use_option)) return NUMBER_CREATED(use_option);
	if (con == Kinds::get_construct(K_response)) return NUMBER_CREATED(response_message);
	#endif
	return con->next_free_value - 1;
}

@h (G) Performing arithmetic.
Comparisons made by calling an I6 routine are slower in the VM than using the
standard |<| or |>| operators for signed comparison, so we use them only if
we have to.

=
int Kinds::Behaviour::uses_signed_comparisons(kind *K) {
	if (K == NULL) return FALSE;
	if (Str::eq_wide_string(K->construct->comparison_routine, L"signed")) return TRUE;
	return FALSE;
}

text_stream *Kinds::Behaviour::get_comparison_routine(kind *K) {
	if (K == NULL) return NULL;
	if (Kinds::FloatingPoint::uses_floating_point(K))
		return K_real_number->construct->comparison_routine;
	if (Str::eq_wide_string(K->construct->comparison_routine, L"signed")) return NULL;
	return K->construct->comparison_routine;
}

#ifdef CORE_MODULE
inter_name *Kinds::Behaviour::get_comparison_routine_as_iname(kind *K) {
	return Produce::find_by_name(Emit::tree(), Kinds::Behaviour::get_comparison_routine(K));
}
#endif

@ See "Dimensions.w" for a full account of these ideas. In theory, our
polymorphic system of arithmetic allows us to add or multiply any kinds
according to rules provided in the source text. In practice we have to keep
track of dimensions, and the following routines connect the code in the
"Dimensions" section to kind structures.

=
int Kinds::Behaviour::is_quasinumerical(kind *K) {
	if (K == NULL) return FALSE;
	return Kinds::Constructors::is_arithmetic(K->construct);
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
	#ifdef LITERAL_PATTERNS
	return LiteralPatterns::scale_factor(K);
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

@h (H) Representing this kind at run-time.

=
text_stream *Kinds::Behaviour::get_name_in_template_code(kind *K) {
	if (K == NULL) return I"UNKNOWN_NT";
	return K->construct->name_in_template_code;
}

@ Some kinds have a support routine:

=
void Kinds::Behaviour::write_support_routine_name(OUTPUT_STREAM, kind *K) {
	if (K == NULL) internal_error("no support name for null kind");
	if (K->construct->stored_as) K = K->construct->stored_as;
	WRITE("%S_Support", K->construct->name_in_template_code);
}

#ifdef CORE_MODULE
inter_name *Kinds::Behaviour::get_support_routine_as_iname(kind *K) {
	TEMPORARY_TEXT(N)
	Kinds::Behaviour::write_support_routine_name(N, K);
	inter_name *iname = Produce::find_by_name(Emit::tree(), N);
	DISCARD_TEXT(N)
	return iname;
}
#endif

@h (I) Storing values at run-time.
Recall that values are stored at run-time either as "word values" -- a
single I6 word -- or "pointer values" (sometimes "block values"), where
the I6 word is a pointer to a block of data on the heap. Numbers and times
are word values, texts and lists are pointer values. Which form a value
takes depends on its kind:

=
int Kinds::Behaviour::uses_pointer_values(kind *K) {
	if (K == NULL) return FALSE;
	return Kinds::Constructors::uses_pointer_values(K->construct);
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
	return K->construct->distinguisher;
}

#ifdef CORE_MODULE
inter_name *Kinds::Behaviour::get_distinguisher_as_iname(kind *K) {
	text_stream *N = Kinds::Behaviour::get_distinguisher(K);
	if (N == NULL) return NULL;
	return Produce::find_by_name(Emit::tree(), N);
}
#endif

@ Can values of this kind be serialised out to a file and read back in again
by some other Inform story file, or by this one running on a different day?

=
int Kinds::Behaviour::can_exchange(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->can_exchange;
}

@h (J) Printing and parsing values at run-time.
Each kind can provide its own I6 routine to print out a value onto screen,
in some human-readable format.

=
#ifdef CORE_MODULE
inter_name *Kinds::Behaviour::get_iname(kind *K) {
	if (K == NULL) {
		if (K_number) return Kinds::Behaviour::get_iname(K_number);
		internal_error("null kind has no printing routine");
	}
	if (K->construct->pr_iname) return K->construct->pr_iname;

	if (Kinds::Compare::eq(K, K_use_option)) {
		K->construct->pr_iname = Hierarchy::find(PRINT_USE_OPTION_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}
	if (Kinds::Compare::eq(K, K_table))  {
		K->construct->pr_iname = Hierarchy::find(PRINT_TABLE_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}
	if (Kinds::Compare::eq(K, K_rulebook_outcome))  {
		K->construct->pr_iname = Hierarchy::find(PRINT_RULEBOOK_OUTCOME_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}
	if (Kinds::Compare::eq(K, K_response))  {
		K->construct->pr_iname = Hierarchy::find(PRINT_RESPONSE_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}
	if (Kinds::Compare::eq(K, K_figure_name))  {
		K->construct->pr_iname = Hierarchy::find(PRINT_FIGURE_NAME_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}
	if (Kinds::Compare::eq(K, K_sound_name))  {
		K->construct->pr_iname = Hierarchy::find(PRINT_SOUND_NAME_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}
	if (Kinds::Compare::eq(K, K_external_file))  {
		K->construct->pr_iname = Hierarchy::find(PRINT_EXTERNAL_FILE_NAME_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}
	if (Kinds::Compare::eq(K, K_scene))  {
		K->construct->pr_iname = Hierarchy::find(PRINT_SCENE_HL);
		Hierarchy::make_available(Emit::tree(), K->construct->pr_iname);
		return K->construct->pr_iname;
	}

	package_request *R = NULL;
	int external = TRUE;
	if ((Kinds::get_construct(K) == CON_rule) ||
		(Kinds::get_construct(K) == CON_rulebook)) external = TRUE;
	if (Kinds::Behaviour::is_an_enumeration(K)) {
		R = Kinds::Behaviour::package(K); external = FALSE;
	}
	text_stream *X = K->construct->dt_I6_identifier;
	if (Kinds::Behaviour::is_quasinumerical(K)) {
		R = Kinds::Behaviour::package(K); external = FALSE;
	}
	if (Kinds::Compare::eq(K, K_time)) external = TRUE;
	if (Kinds::Compare::eq(K, K_number)) external = TRUE;
	if (Kinds::Compare::eq(K, K_real_number)) external = TRUE;
	if (Str::len(X) == 0) X = I"DecimalNumber";

	if (R) {
		if (external) {
			K->construct->pr_iname = Hierarchy::make_iname_in(PRINT_FN_HL, R);
			inter_name *actual_iname = Produce::find_by_name(Emit::tree(), X);
			Emit::named_iname_constant(K->construct->pr_iname, K_value, actual_iname);
		} else internal_error("internal but unknown kind printing routine");
	} else {
		if (external) K->construct->pr_iname = Produce::find_by_name(Emit::tree(), X);
		else internal_error("internal but unpackaged kind printing routine");
	}
	return K->construct->pr_iname;
}
package_request *Kinds::Behaviour::package(kind *K) {
	return Kinds::Constructors::package(K->construct);
}
inter_name *Kinds::Behaviour::get_inc_iname(kind *K) {
	if (K == NULL) internal_error("null kind has no inc routine");
	if (K->construct->inc_iname) return K->construct->inc_iname;
	package_request *R = Kinds::Behaviour::package(K);
	K->construct->inc_iname = Hierarchy::make_iname_in(DECREMENT_FN_HL, R);
	return K->construct->inc_iname;
}
inter_name *Kinds::Behaviour::get_dec_iname(kind *K) {
	if (K == NULL) internal_error("null kind has no dec routine");
	if (K->construct->dec_iname) return K->construct->dec_iname;
	package_request *R = Kinds::Behaviour::package(K);
	K->construct->dec_iname = Hierarchy::make_iname_in(INCREMENT_FN_HL, R);
	return K->construct->dec_iname;
}
inter_name *Kinds::Behaviour::get_ranger_iname(kind *K) {
	if (K == NULL) internal_error("null kind has no inc routine");
	if (K->construct->ranger_iname) return K->construct->ranger_iname;
	package_request *R = Kinds::Behaviour::package(K);
	K->construct->ranger_iname = Hierarchy::make_iname_in(RANGER_FN_HL, R);
	return K->construct->ranger_iname;
}
inter_name *Kinds::Behaviour::get_name_of_printing_rule_ACTIONS(kind *K) {
	if (K == NULL) K = K_number;
	if (K->construct->trace_iname) return K->construct->trace_iname;
	if (Str::len(K->construct->name_of_printing_rule_ACTIONS) > 0)
		K->construct->trace_iname = Produce::find_by_name(Emit::tree(), K->construct->name_of_printing_rule_ACTIONS);
	else
		K->construct->trace_iname = Produce::find_by_name(Emit::tree(), I"DA_Name");
	return K->construct->trace_iname;
}
#endif

@ Moving on to understanding: some kinds can be used as tokens in Understand
sentences, others can't. Thus "[time]" is a valid Understand token, but
"[stored action]" is not.

Some kinds provide have a GPR ("general parsing routine", an I6 piece of
jargon) defined somewhere in the template: if so, this returns its name;
if not, it returns |NULL|.

=
text_stream *Kinds::Behaviour::get_explicit_I6_GPR(kind *K) {
	if (K == NULL) internal_error("Kinds::Behaviour::get_explicit_I6_GPR on null kind");
	return K->construct->explicit_i6_GPR;
}

#ifdef CORE_MODULE
inter_name *Kinds::Behaviour::get_explicit_I6_GPR_iname(kind *K) {
	if (K == NULL) internal_error("Kinds::Behaviour::get_explicit_I6_GPR on null kind");
	if (Str::len(K->construct->explicit_i6_GPR) > 0)
		return Produce::find_by_name(Emit::tree(), K->construct->explicit_i6_GPR);
	return NULL;
}
#endif

@ Can the kind have a GPR of any kind in the final code?

=
int Kinds::Behaviour::offers_I6_GPR(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->has_i6_GPR;
}

@ Request that a GPR be compiled for this kind; the return value tell us whether
this will be allowed or not.

=
int Kinds::Behaviour::request_I6_GPR(kind *K) {
	if (K == NULL) return FALSE;
	if (K->construct->has_i6_GPR == FALSE) return FALSE; /* can't oblige */
	K->construct->I6_GPR_needed = TRUE; /* make note to oblige later */
	return TRUE;
}

@ Do we need to compile a GPR of our own for this kind?

=
int Kinds::Behaviour::needs_I6_GPR(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->I6_GPR_needed;
}

@ For the following, see the explanation in "Texts.i6t" in the template: a
recognition-only GPR is used for matching specific data in the course of
parsing names of objects, but not as a grammar token in its own right.

=
text_stream *Kinds::Behaviour::get_recognition_only_GPR(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->recognition_only_GPR;
}

#ifdef CORE_MODULE
inter_name *Kinds::Behaviour::get_recognition_only_GPR_as_iname(kind *K) {
	text_stream *N = Kinds::Behaviour::get_recognition_only_GPR(K);
	if (N == NULL) return NULL;
	return Produce::find_by_name(Emit::tree(), N);
}
#endif

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
text used only on the index pages, and not existing at run-time. This is
set explicitly in the source text, but initialised for built-in kinds from
the I6 template files.

=
void Kinds::Behaviour::set_specification_text(kind *K, text_stream *desc) {
	if (K == NULL) internal_error("can't set specification for null kind");
	K->construct->specification_text = Str::duplicate(desc);
}

text_stream *Kinds::Behaviour::get_specification_text(kind *K) {
	if (K == NULL) internal_error("can't get specification of null kind");
	return K->construct->specification_text;
}

