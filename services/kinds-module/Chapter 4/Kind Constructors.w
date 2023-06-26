[KindConstructors::] Kind Constructors.

The mechanism by which Inform records the characteristics of different
kinds.

@ Constructors are divided into four groups:

@d PUNCTUATION_GRP 1 /* used in the construction of other kinds only */
@d PROTOCOL_GRP 2 /* such as |arithmetic value| */
@d BASE_CONSTRUCTOR_GRP 3 /* such as |number| */
@d PROPER_CONSTRUCTOR_GRP 4 /* with positive arity, such as "list of ..." */

@ Besides all the properties of kinds used in this module, Inform also needs
to store further metadata in order to be able to make the extensive run-time
code needed to support all these kinds in actual programs. All of this means
that a //kind_constructor// object is a great big rag-bag of properties, some
set by commands in Neptune files, others set by calls from Inform.

So, deep breath:

@d MAX_KIND_CONSTRUCTION_ARITY 2

=
typedef struct kind_constructor {
	struct noun *dt_tag; /* text of name */
	int group; /* one of the four values above */

	/* A: how this came into being */
	int is_incompletely_defined; /* newly defined and ambiguous as yet */
	struct parse_node *where_defined_in_source_text; /* if so */

	/* B: constructing kinds */
	int constructor_arity; /* 0 for base, 1 for unary, 2 for binary */
	int variance[MAX_KIND_CONSTRUCTION_ARITY]; /* must be |COVARIANT| or |CONTRAVARIANT| */
	int tupling[MAX_KIND_CONSTRUCTION_ARITY]; /* extent to which tupling is permitted */
	struct kind *cached_kind; /* cached result of |Kinds::base_construction| */

	/* C: compatibility with other kinds */
	struct parse_node *superkind_set_at; /* where it says, e.g., "A rabbit is a kind of animal" */
	struct kind_constructor_casting_rule *first_casting_rule; /* list of these */
	struct kind_constructor_instance_rule *first_instance_rule; /* list of these */

	/* D: how constant values of this kind are expressed */
	struct literal_pattern *ways_to_write_literals; /* list of ways to write this */
	struct table *named_values_created_with_table; /* alternatively... */
	int next_free_value; /* to make distinguishable instances of this kind */
	int constant_compilation_method; /* one of the |*_CCM| values */
	int forbid_assertion_creation; /* an enumeration which cannot be explicitly created? */

	/* E: knowledge about values of this kind */
	struct inference_subject *base_as_infs; /* inferences about properties */
	struct text_stream *default_value; /* used for built-in types only */

	/* F: behaviour as a property as well */
	int can_coincide_with_property; /* allowed to coincide in name with a property */
	struct property *coinciding_property; /* property of the same name, if any */

	/* G: performing arithmetic */
	struct text_stream *comparison_routine; /* for instance, when sorting table or list entries */
	struct dimensional_rules dim_rules; /* how arithmetic operations work here */
	struct unit_sequence dimensional_form; /* dimensions of this kind */
	int dimensional_form_fixed; /* whether they are derived */

	/* H: representing this kind at run-time */
	struct text_stream *explicit_identifier; /* to become an Inter identifier */
	int class_number; /* for classes of object */
	#ifdef CORE_MODULE
	struct kind_constructor_compilation_data compilation_data;
	#endif
	int small_block_size; /* if stored as a block value, size in words of the SB */

	/* I: storing values at run-time */
	int multiple_block; /* TRUE for flexible-size values stored on the heap */
	int heap_size_estimate; /* typical number of bytes used */
	int can_exchange; /* with external files and therefore other story files */
	struct text_stream *distinguishing_routine; /* Inter routine to see if values distinguishable */
	struct kind_constructor_comparison_schema *first_comparison_schema; /* list of these */
	struct text_stream *loop_domain_schema; /* how to compile a loop over the instances */
	struct linked_list *instances; /* if enumerated explicitly in a Neptune file */

	/* J: printing and parsing values at run-time */
	struct text_stream *print_identifier; /* an Inter identifier used for compiling printing rules */
	struct text_stream *ACTIONS_identifier; /* ditto but for ACTIONS testing command */
	struct command_grammar *understand_as_values; /* used when parsing such values */
	struct text_stream *explicit_GPR_identifier; /* routine name, when not compiled automatically */
	struct text_stream *recognition_routine; /* for recognising an explicit value as preposition */

	/* K: indexing and documentation */
	struct text_stream *specification_text; /* text for pseudo-property */
	struct text_stream *index_default_value; /* and its description in the Kinds index */
	struct text_stream *index_maximum_value; /* ditto */
	struct text_stream *index_minimum_value; /* ditto */
	int index_priority; /* from 1 (highest) to |LOWEST_INDEX_PRIORITY| (lowest) */
	int linguistic; /* divide off as having linguistics content */
	int indexed_grey_if_empty; /* shaded grey in the Kinds index */
	struct text_stream *documentation_reference; /* documentation symbol, if any */

	CLASS_DEFINITION
} kind_constructor;

@ A few of the settings connect pairs of kinds together, so structures like
the following are also needed.

=
typedef struct kind_constructor_casting_rule {
	struct text_stream *cast_from_kind_unparsed; /* to the one which has the rule */
	struct kind_constructor *cast_from_kind; /* to the one which has the rule */
	struct kind_constructor_casting_rule *next_casting_rule;
} kind_constructor_casting_rule;

@ And this is the analogous structure for recording conformance:

=
typedef struct kind_constructor_instance_rule {
	struct text_stream *instance_of_this_unparsed;
	struct kind_constructor *instance_of_this;
	struct kind_constructor_instance_rule *next_instance_rule;
} kind_constructor_instance_rule;

@ And this is the analogous structure for giving Inter schemas to compare
data of two different kinds:

=
typedef struct kind_constructor_comparison_schema {
	struct text_stream *comparator_unparsed;
	struct kind_constructor *comparator;
	struct text_stream *comparison_schema;
	struct kind_constructor_comparison_schema *next_comparison_schema;
} kind_constructor_comparison_schema;

@ And this is where explicit instances are recorded:

=
typedef struct kind_constructor_instance {
	struct text_stream *natural_language_name;
	struct text_stream *identifier;
	int value;
	int value_specified;
} kind_constructor_instance;

@ The "tupling" of an argument is the extent to which an argument can be
allowed to hold a variable-length list of kinds, rather than a single one.
There aren't actually many possibilities.

@d NO_TUPLING 0 /* a single kind */
@d ALLOW_NOTHING_TUPLING 1 /* a single kind, or "nothing" */
@d ARBITRARY_TUPLING 10000 /* a list of kinds of any length */

@ Constant compilation modes are:

@d NONE_CCM 1 /* constant values of this kind cannot exist */
@d LITERAL_CCM 2 /* a numerical annotation decides the value */
@d NAMED_CONSTANT_CCM 3 /* an |instance| annotation decides the value */
@d SPECIAL_CCM 4 /* special code specific to the kind of value is needed */

@ We keep track of the newest-created base kind of value (which isn't a kind
of object) here:

= (early code)
kind *latest_base_kind_of_value = NULL;

@h Creation.
Constructors come from two sources. Built-in ones like |number| or
|list of K| come from commands in //Neptune Files//, while source-created
ones ("Air pressure is a kind of value") result in calls here from
//Kinds::new_base// -- which, as the name suggests, can only make
base kinds, not proper constructors.

Here |super| will be the super-constructor, the one which this will construct
subkinds of. In practice this will be |NULL| when |CON_VALUE| is created, and
then |CON_VALUE| for kinds like "number" or this one:

>> Weight is a kind of value.

but will be the constructor for "door" for kinds like this one:

>> Portal is a kind of door.

=
kind_constructor *KindConstructors::new(kind_constructor *super,
	text_stream *source_name, text_stream *initialisation_macro, int group) {
	kind_constructor *con = CREATE(kind_constructor);
	kind_constructor **pC = FamiliarKinds::known_con(source_name);
	if (pC) *pC = con;

	int copied = FALSE;
	if (super == Kinds::get_construct(K_value)) @<Fill in a new constructor@>
	else { @<Copy the new constructor from its superconstructor@>; copied = TRUE; }
	con->group = group;

	con->explicit_identifier = Str::duplicate(source_name);
	#ifdef CORE_MODULE
	con->compilation_data = RTKindConstructors::new_compilation_data(con);
	KindSubjects::new(con);
	#endif
	con->where_defined_in_source_text = current_sentence;

	kind **pK = FamiliarKinds::known_kind(source_name);
	if (pK) *pK = Kinds::base_construction(con);
	return con;
}

@ If our new constructor is wholly new, and isn't a subkind of something else,
we need to initialise the entire data structure; but note that, having done so,
we apply any defaults set in Neptune files.

@default LOWEST_INDEX_PRIORITY 100

@<Fill in a new constructor@> =
	con->dt_tag = NULL;
	con->group = 0; /* which is invalid, so the interpreter needs to set it */

	/* A: how this came into being */
	con->is_incompletely_defined = FALSE;
	con->where_defined_in_source_text = NULL; /* but will be filled in imminently */

	/* B: constructing kinds */
	con->constructor_arity = 0; /* by default a base constructor */
	for (int i=0; i<MAX_KIND_CONSTRUCTION_ARITY; i++) {
		con->variance[i] = COVARIANT;
		con->tupling[i] = NO_TUPLING;
	}
	con->cached_kind = NULL;

	/* C: compatibility with other kinds */
	con->superkind_set_at = NULL;
	con->first_casting_rule = NULL;
	con->first_instance_rule = NULL;

	/* D: how constant values of this kind are expressed */
	con->ways_to_write_literals = NULL;
	con->named_values_created_with_table = NULL;
	con->next_free_value = 1;
	con->constant_compilation_method = NONE_CCM;
	con->forbid_assertion_creation = FALSE;

	/* E: knowledge about values of this kind */
	con->base_as_infs = NULL; /* but will be filled in imminently, in almost all cases */
	con->default_value = Str::new();

	/* F: behaviour as a property as well */
	con->can_coincide_with_property = FALSE;
	con->coinciding_property = NULL;

	/* G: performing arithmetic */
	con->comparison_routine = Str::new();
	WRITE_TO(con->comparison_routine, "UnsignedCompare");
	if ((con == CON_KIND_VARIABLE) || (con == CON_INTERMEDIATE) ||
		((Str::eq_wide_string(source_name, L"NUMBER_TY")) ||
			(Str::eq_wide_string(source_name, L"REAL_NUMBER_TY"))))
		con->dimensional_form =
			Kinds::Dimensions::fundamental_unit_sequence(NULL);
	else
		con->dimensional_form =
			Kinds::Dimensions::fundamental_unit_sequence(Kinds::base_construction(con));
	con->dimensional_form_fixed = FALSE;
	Kinds::Dimensions::dim_initialise(&(con->dim_rules));

	/* H: representing this kind at run-time */
	con->explicit_identifier = Str::new();
	con->class_number = 0;

	/* I: storing values at run-time */
	con->multiple_block = FALSE;
	con->small_block_size = 1;
	con->heap_size_estimate = 0;
	con->can_exchange = FALSE;
	con->first_comparison_schema = NULL;
	con->distinguishing_routine = NULL;
	con->loop_domain_schema = NULL;
	con->instances = NEW_LINKED_LIST(kind_constructor_instance);

	/* J: printing and parsing values at run-time */
	con->print_identifier = Str::new();
	con->ACTIONS_identifier = Str::new();

	con->understand_as_values = NULL;
	con->explicit_GPR_identifier = NULL;
	con->recognition_routine = NULL;

	/* K: indexing and documentation */
	con->specification_text = NULL;
	con->index_default_value = I"--";
	con->index_maximum_value = I"--";
	con->index_minimum_value = I"--";
	con->index_priority = LOWEST_INDEX_PRIORITY;
	if ((group == PUNCTUATION_GRP) || (group == PROTOCOL_GRP))
		con->index_priority = 0;
	con->linguistic = FALSE;
	con->indexed_grey_if_empty = FALSE;
	con->documentation_reference = NULL;

	kind_macro_definition *set_defaults = NULL;
	switch (group) {
		case PUNCTUATION_GRP: set_defaults = NeptuneMacros::parse_name(I"#PUNCTUATION"); break;
		case PROTOCOL_GRP: set_defaults = NeptuneMacros::parse_name(I"#PROTOCOL"); break;
		case BASE_CONSTRUCTOR_GRP: set_defaults = NeptuneMacros::parse_name(I"#BASE"); break;
		case PROPER_CONSTRUCTOR_GRP: set_defaults = NeptuneMacros::parse_name(I"#CONSTRUCTOR"); break;
	}
	if (set_defaults) NeptuneMacros::play_back(set_defaults, con, NULL);

	if (Str::len(initialisation_macro) > 0)
		NeptuneMacros::play_back(NeptuneMacros::parse_name(initialisation_macro), con, NULL);

@ However, if we create our constructor as a subkind, like so:

>> A turtle is a kind of animal.

then we copy the entire "animal" constructor to initialise the "turtle" one.

Note that the weak ID number is one of the things copied; this is deliberate.
It means that all kinds of object share the same weak ID as "object".

@<Copy the new constructor from its superconstructor@> =
	int I = con->allocation_id;
	void *N = con->next_structure;
	void *P = con->prev_structure;
	*con = *super;
	con->allocation_id = I;
	con->next_structure = N;
	con->prev_structure = P;
	con->cached_kind = NULL; /* otherwise the superkind's cache is used by mistake */
	con->explicit_identifier = Str::new(); /* otherwise this will be called |OBJECT_TY| by mistake */

@h The noun.
It's a requirement that the following be called soon after the creation
of the constructor:

=
void KindConstructors::attach_noun(kind_constructor *con, noun *nt) {
	if ((con == NULL) || (nt == NULL)) internal_error("bad noun attachment");
	con->dt_tag = nt;
}

wording KindConstructors::get_name(kind_constructor *con, int plural_form) {
	if (con->dt_tag) {
		noun *nt = con->dt_tag;
		if (nt) return Nouns::nominative(nt, plural_form);
	}
	return EMPTY_WORDING;
}

wording KindConstructors::get_name_in_play(kind_constructor *con, int plural_form,
	NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	if (con->dt_tag) {
		noun *nt = con->dt_tag;
		if (nt) return Nouns::nominative_in_language(nt, plural_form, nl);
	}
	return EMPTY_WORDING;
}

noun *KindConstructors::get_noun(kind_constructor *con) {
	if (con == NULL) return NULL;
	return con->dt_tag;
}

text_stream *KindConstructors::name_in_template_code(kind_constructor *con) {
	return con->explicit_identifier;
}

@ We also need to parse this, occasionally (if we needed this more than a
small and bounded number of times we'd want a faster method, but we don't):

=
kind_constructor *KindConstructors::parse(text_stream *sn) {
	if (sn == NULL) return NULL;
	kind_constructor *con;
	LOOP_OVER(con, kind_constructor)
		if (Str::eq(sn, con->explicit_identifier))
			return con;
	return NULL;
}

@h Transformations.
Conversions of an existing constructor to make it a unit or enumeration also
require running macros in the kind interpreter:

=
int KindConstructors::convert_to_unit(kind_constructor *con) {
	if (con->is_incompletely_defined == TRUE) {
		NeptuneMacros::play_back(NeptuneMacros::parse_name(I"#UNIT"), con, NULL);
		return TRUE;
	}
	if (KindConstructors::is_arithmetic(con)) return TRUE; /* i.e., if it succeeded */
	return FALSE;
}

int KindConstructors::convert_to_enumeration(kind_constructor *con) {
	if (con->is_incompletely_defined == TRUE) {
		NeptuneMacros::play_back(NeptuneMacros::parse_name(I"#ENUMERATION"), con, NULL);
		if (con->linguistic)
			NeptuneMacros::play_back(NeptuneMacros::parse_name(I"#LINGUISTIC"), con, NULL);
		return TRUE;
	}
	if (KindConstructors::is_an_enumeration(con)) return TRUE; /* i.e., if it succeeded */
	return FALSE;
}

@ And similarly:

=
void KindConstructors::convert_to_real(kind_constructor *con) {
	NeptuneMacros::play_back(NeptuneMacros::parse_name(I"#REAL"), con, NULL);
}

@ A few base kinds are marked as "linguistic", which simply enables us to fence
them tidily off in the index.

=
void KindConstructors::mark_as_linguistic(kind_constructor *con) {
	con->linguistic = TRUE;
}

@h For construction purposes.

=
kind **KindConstructors::cache_location(kind_constructor *con) {
	if (con) return &(con->cached_kind);
	return NULL;
}

int KindConstructors::arity(kind_constructor *con) {
	if (con == NULL) return 0;
	if (con->group == PROPER_CONSTRUCTOR_GRP) return con->constructor_arity;
	return 0;
}

int KindConstructors::tupling(kind_constructor *con, int b) {
	return con->tupling[b];
}

int KindConstructors::variance(kind_constructor *con, int b) {
	return con->variance[b];
}

int KindConstructors::is_base(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if (con->group == BASE_CONSTRUCTOR_GRP) return TRUE;
	return FALSE;
}

int KindConstructors::is_proper_constructor(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if (con->group == PROPER_CONSTRUCTOR_GRP) return TRUE;
	return FALSE;
}

@h Questions about constructors.
The rest of Inform is not encouraged to poke at constructors directly; it
ought to ask questions about kinds instead (see "Using Kinds"). However:

=
int KindConstructors::is_definite(kind_constructor *con) {
	if ((con->group == BASE_CONSTRUCTOR_GRP) ||
		(con->group == PROPER_CONSTRUCTOR_GRP))
			return TRUE;
	if ((con == CON_VOID) || (con == CON_NIL) || (con == CON_INTERMEDIATE))
		return TRUE;
	return FALSE;
}

int KindConstructors::is_understandable(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((KindConstructors::is_definite(con)) &&
		(KindConstructors::compatible(con,
			Kinds::get_construct(K_understandable_value), FALSE))) return TRUE;
	return FALSE;
}

int KindConstructors::is_arithmetic(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((KindConstructors::is_definite(con)) &&
		(KindConstructors::compatible(con,
			Kinds::get_construct(K_arithmetic_value), FALSE))) return TRUE;
	return FALSE;
}

int KindConstructors::is_arithmetic_and_real(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((KindConstructors::is_definite(con)) &&
		(KindConstructors::compatible(con,
			Kinds::get_construct(K_real_arithmetic_value), FALSE))) return TRUE;
	return FALSE;
}

int KindConstructors::is_an_enumeration(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((KindConstructors::is_definite(con)) &&
		(KindConstructors::compatible(con,
			Kinds::get_construct(K_enumerated_value), FALSE))) return TRUE;
	return FALSE;
}

@ All floating-point kinds use a common comparison function: the one for
|K_real_number|.

=
int KindConstructors::uses_signed_comparisons(kind_constructor *kc) {
	if (kc == NULL) return FALSE;
	if (Str::eq_wide_string(kc->comparison_routine, L"signed")) return TRUE;
	return FALSE;
}

text_stream *KindConstructors::get_comparison_fn_identifier(kind_constructor *kc) {
	if (kc == NULL) return NULL;
	if ((KindConstructors::is_arithmetic_and_real(kc)) && (K_real_number))
		return K_real_number->construct->comparison_routine;
	if (Str::eq_wide_string(kc->comparison_routine, L"signed")) return NULL;
	return kc->comparison_routine;
}

@h Cast and instance lists.
Each constructor has a list of other constructors (all of the |PROTOCOL_GRP|
group) which it's an instance of: value, word value, arithmetic value, and so on.

=
int KindConstructors::find_cast(kind_constructor *from, kind_constructor *to) {
	if (to) {
		kind_constructor_casting_rule *dtcr;
		for (dtcr = to->first_casting_rule; dtcr; dtcr = dtcr->next_casting_rule) {
			if (Str::len(dtcr->cast_from_kind_unparsed) > 0) {
				dtcr->cast_from_kind =
					KindConstructors::parse(dtcr->cast_from_kind_unparsed);
				Str::clear(dtcr->cast_from_kind_unparsed);
			}
			if (from == dtcr->cast_from_kind)
				return TRUE;
		}
	}
	return FALSE;
}

@ Each constructor has a list of other constructors (all of the |BASE_CONSTRUCTOR_GRP|
group or |PROPER_CONSTRUCTOR_GRP|) which it can cast to.

=
int KindConstructors::find_instance(kind_constructor *from, kind_constructor *to) {
	kind_constructor_instance_rule *dti;
	for (dti = from->first_instance_rule; dti; dti = dti->next_instance_rule) {
		if (Str::len(dti->instance_of_this_unparsed) > 0) {
			dti->instance_of_this =
				KindConstructors::parse(dti->instance_of_this_unparsed);
			Str::clear(dti->instance_of_this_unparsed);
		}
		if (dti->instance_of_this == to) return TRUE;
		if (KindConstructors::find_instance(dti->instance_of_this, to)) return TRUE;
	}
	return FALSE;
}

@ Each constructor has a list of explicitly-named instances from the Neptune
file creating it (if any were: by default this will be empty):

=
linked_list *KindConstructors::instances(kind_constructor *kc) {
	if (kc == NULL) return FALSE;
	return kc->instances;
}

@h Compatibility.
The following tests if |from| is compatible with |to|.

=
int KindConstructors::compatible(kind_constructor *from, kind_constructor *to,
	int allow_casts) {
	if (to == from) return TRUE;
	if ((to == NULL) || (from == NULL)) return FALSE;
	if ((allow_casts) && (KindConstructors::find_cast(from, to))) return TRUE;
	if (KindConstructors::find_instance(from, to)) return TRUE;
	return FALSE;
}

@ And more elaborately:

=
int KindConstructors::uses_block_values(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((KindConstructors::is_definite(con)) &&
		(KindConstructors::compatible(con, Kinds::get_construct(K_pointer_value), FALSE)))
			return TRUE;
	return FALSE;
}

int KindConstructors::allow_word_as_pointer(kind_constructor *left,
	kind_constructor *right) {
	if (KindConstructors::uses_block_values(left) == FALSE) return FALSE;
	if (KindConstructors::uses_block_values(right) == TRUE) return FALSE;
	if (KindConstructors::compatible(right, left, TRUE)) return TRUE;
	return FALSE;
}
