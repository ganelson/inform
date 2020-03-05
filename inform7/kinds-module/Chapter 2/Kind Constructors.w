[Kinds::Constructors::] Kind Constructors.

The mechanism by which Inform records the characteristics of different
kinds.

@h Definitions.

@ Constructors are divided into four:

@d KIND_VARIABLE_GRP 1 /* just |CON_KIND_VARIABLE| on its own */
@d KIND_OF_KIND_GRP 2 /* an indefinite base constructor such as "arithmetic value" */
@d BASE_CONSTRUCTOR_GRP 3 /* a definite one such as "number" */
@d PROPER_CONSTRUCTOR_GRP 4 /* with positive arity, such as "list of K" */

@ Inform provides much more extensive facilities for kinds than most
programming languages do for their types. As far as possible, we want to
write this code in a generalised way, rather than writing hacky routines
which each apply to a fixed, named kind. This won't always be possible, it's
true, but we can try. The only way to achieve this is to store an enormous
rag-bag of properties for every kind constructor, showing exactly how it
behaves.

All of which is by way of apology for the enormous size of the |kind_constructor|
structure. It looks impossibly large to fill out, and this is why we have the
kind interpreter (see next section) to give the I6 template the ability to
forge new kind constructors.

@d LOWEST_INDEX_PRIORITY 100

=
typedef struct kind_constructor {
	struct noun *dt_tag; /* text of name */
	int group; /* one of the four values above */

	/* A: how this came into being */
	int defined_in_source_text; /* rather than by I6 template files, i.e., by being built-in */
	int is_incompletely_defined; /* newly defined and ambiguous as yet */
	struct parse_node *where_defined_in_source_text; /* if so */
	struct kind *stored_as; /* currently unused: if this is a typedef for some construction */

	/* B: constructing kinds */
	int constructor_arity; /* 0 for base, 1 for unary, 2 for binary */
	int variance[MAX_KIND_CONSTRUCTION_ARITY]; /* must be |COVARIANT| or |CONTRAVARIANT| */
	int tupling[MAX_KIND_CONSTRUCTION_ARITY]; /* extent to which tupling is permitted */
	struct kind *cached_kind; /* cached result of |Kinds::base_construction| */

	/* C: compatibility with other kinds */
	struct parse_node *superkind_set_at; /* where it says, e.g., "A rabbit is a kind of animal" */
	struct kind_constructor_casting_rule *first_casting_rule; /* list of these */
	struct kind_constructor_instance *first_instance_rule; /* list of these */

	/* D: how constant values of this kind are expressed */
	struct literal_pattern *ways_to_write_literals; /* list of ways to write this */
	int named_values_created_with_assertions; /* such as "Train Arrival is a scene." */
	struct table *named_values_created_with_table; /* alternatively... */
	int next_free_value; /* to make distinguishable instances of this kind */
	int constant_compilation_method; /* one of the |*_CCM| values */

	/* E: knowledge about values of this kind */
	struct inference_subject *dt_knowledge; /* inferences about properties */
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
	int weak_kind_ID; /* as used at run-time by the I6 template */
	struct text_stream *name_in_template_code; /* an I6 identifier */
	#ifdef CORE_MODULE
	struct inter_name *con_iname;
	struct package_request *kc_package;
	#endif
	int small_block_size; /* if stored as a block value, size in words of the SB */

	/* I: storing values at run-time */
	int multiple_block; /* TRUE for flexible-size values stored on the heap */
	int heap_size_estimate; /* typical number of bytes used */
	int can_exchange; /* with external files and therefore other story files */
	struct text_stream *distinguisher; /* I6 routine to see if values distinguishable */
	struct kind_constructor_comparison_schema *first_comparison_schema; /* list of these */
	struct text_stream *loop_domain_schema; /* how to compile an I6 loop over the instances */

	/* J: printing and parsing values at run-time */
	#ifdef INTER_MODULE
	struct inter_name *kind_GPR_iname;
	struct inter_name *instance_GPR_iname;
	struct inter_name *first_instance_iname;
	struct inter_name *next_instance_iname;
	struct inter_name *pr_iname;
	struct inter_name *inc_iname;
	struct inter_name *dec_iname;
	struct inter_name *ranger_iname;
	struct inter_name *trace_iname;
	#endif
	struct text_stream *dt_I6_identifier; /* an I6 identifier used for compiling printing rules */
	struct text_stream *name_of_printing_rule_ACTIONS; /* ditto but for ACTIONS testing command */
	struct grammar_verb *understand_as_values; /* used when parsing such values */
	int has_i6_GPR; /* a general parsing routine exists in the I6 code for this */
	int I6_GPR_needed; /* and is actually required */
	struct text_stream *explicit_i6_GPR; /* routine name, when not compiled automatically */
	struct text_stream *recognition_only_GPR; /* for recognising an explicit value as preposition */

	/* K: indexing and documentation */
	struct text_stream *specification_text; /* text for parse_node */
	struct text_stream *constructor_description; /* text used in index pages */
	struct text_stream *index_default_value; /* and its description in the Kinds index */
	struct text_stream *index_maximum_value; /* ditto */
	struct text_stream *index_minimum_value; /* ditto */
	int index_priority; /* from 1 (highest) to |LOWEST_INDEX_PRIORITY| (lowest) */
	int linguistic; /* divide off as having linguistics content */
	int indexed_grey_if_empty; /* shaded grey in the Kinds index */
	struct text_stream *documentation_reference; /* documentation symbol, if any */

	MEMORY_MANAGEMENT
} kind_constructor;

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
int next_free_data_type_ID = 2; /* i.e., leaving room for |UNKNOWN_TY| to be 1 at run-time */
kind *latest_base_kind_of_value = NULL;

@h Creation.
Constructors come from two sources. Built-in ones like "number" or
"list of K" mainly come from the commands given in the "Load-Core.i6t"
template file, which consists almost entirely of commands for the kind
interpreter, which sets up most of the above. (Similar files for other
language plugins add the remainder.) Thus a great deal can be changed about
the interplay of kinds without altering the compiler itself.

New kinds created by the source text, by sentences like "Air pressure is a
kind of value", are always base constructors (i.e., they have arity 0); at
present there's no way to create new kinds of kinds, or new constructors, in
Inform source text. (So an extension wanting to make new constructors, say
to add new "collection classes" to Inform, will have to get its hands
dirty with Inform 6 insertions and use of the kind interpreter.)

Here |super| will be the super-constructor, the one which this will construct
subkinds of. In practice this will be |NULL| when |CON_VALUE| is created, and
then |CON_VALUE| for kinds like "number" or this one:

>> Weight is a kind of value.

but will be the constructor for "door" for kinds like this one:

>> Portal is a kind of door.

=
kind_constructor *Kinds::Constructors::new(parse_node_tree *T, kind_constructor *super, text_stream *source_name,
	text_stream *initialisation_macro) {
	kind_constructor *con = CREATE(kind_constructor);
	kind_constructor **pC = Kinds::known_constructor_name(source_name);
	if (pC) *pC = con;

	if (super == Kinds::get_construct(K_value)) @<Fill in a new constructor@>
	else @<Copy the new constructor from its superconstructor@>;

	con->name_in_template_code = Str::new();
	#ifdef CORE_MODULE
	con->con_iname = NULL;
	con->kc_package = NULL;
	#endif
	if (Str::len(source_name) > 0) WRITE_TO(con->name_in_template_code, "%S", source_name);
	#ifdef CORE_MODULE
	if ((con != CON_KIND_VARIABLE) && (con != CON_INTERMEDIATE))
		con->dt_knowledge = Kinds::Knowledge::create_for_constructor(con);
	#endif
	con->where_defined_in_source_text = current_sentence;

	kind **pK = Kinds::known_kind_name(source_name);
	if (pK) *pK = Kinds::base_construction(con);
	return con;
}

@ If our new constructor is wholly new, and isn't a subkind of something else,
we need to initialise the entire data structure; but note that, having done so,
we ask the kind interpreter to load it up with any defaults set in the
I6 template files.

@<Fill in a new constructor@> =
	con->dt_tag = NULL;
	con->group = 0; /* which is invalid, so the interpreter needs to set it */

	/* A: how this came into being */
	con->defined_in_source_text = FALSE;
	con->is_incompletely_defined = FALSE;
	con->where_defined_in_source_text = NULL; /* but will be filled in imminently */
	con->stored_as = NULL;

	/* B: constructing kinds */
	con->constructor_arity = 0; /* by default a base constructor */
	int i;
	for (i=0; i<MAX_KIND_CONSTRUCTION_ARITY; i++) {
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
	con->named_values_created_with_assertions = FALSE;
	con->named_values_created_with_table = NULL;
	con->next_free_value = 1;
	con->constant_compilation_method = NONE_CCM;

	/* E: knowledge about values of this kind */
	con->dt_knowledge = NULL; /* but will be filled in imminently, in almost all cases */
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
	con->weak_kind_ID = next_free_data_type_ID++;
	con->name_in_template_code = Str::new();

	/* I: storing values at run-time */
	con->multiple_block = FALSE;
	con->small_block_size = 1;
	con->heap_size_estimate = 0;
	con->can_exchange = FALSE;
	con->first_comparison_schema = NULL;
	con->distinguisher = NULL;
	con->loop_domain_schema = NULL;

	/* J: printing and parsing values at run-time */
	con->dt_I6_identifier = Str::new();
	con->name_of_printing_rule_ACTIONS = Str::new();
	#ifdef INTER_MODULE
	con->kind_GPR_iname = NULL;
	con->instance_GPR_iname = NULL;
	con->first_instance_iname = NULL;
	con->next_instance_iname = NULL;
	con->pr_iname = NULL;
	con->inc_iname = NULL;
	con->dec_iname = NULL;
	con->ranger_iname = NULL;
	con->trace_iname = NULL;
	if (Str::len(source_name) == 0) {
		package_request *R = Kinds::Constructors::package(con);
		con->pr_iname = Hierarchy::make_iname_in(PRINT_DASH_FN_HL, R);
		con->trace_iname = con->pr_iname;
	}
	#endif

	con->understand_as_values = NULL;
	con->has_i6_GPR = FALSE;
	con->I6_GPR_needed = FALSE;
	con->explicit_i6_GPR = NULL;
	con->recognition_only_GPR = NULL;

	/* K: indexing and documentation */
	con->specification_text = NULL;
	con->constructor_description = NULL;
	con->index_default_value = I"--";
	con->index_maximum_value = I"--";
	con->index_minimum_value = I"--";
	con->index_priority = LOWEST_INDEX_PRIORITY;
	con->linguistic = FALSE;
	con->indexed_grey_if_empty = FALSE;
	con->documentation_reference = NULL;

	Kinds::Interpreter::play_back_kind_macro(T,
		Kinds::Interpreter::parse_kind_macro_name(I"#DEFAULTS"), con);
	if (Str::len(initialisation_macro) > 0)
		Kinds::Interpreter::play_back_kind_macro(T,
			Kinds::Interpreter::parse_kind_macro_name(initialisation_macro), con);

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
	con->name_in_template_code = Str::new(); /* otherwise this will be called |OBJECT_TY| by mistake */

@h The noun.
It's a requirement that the following be called soon after the creation
of the constructor:

=
void Kinds::Constructors::attach_noun(kind_constructor *con, noun *nt) {
	if ((con == NULL) || (nt == NULL)) internal_error("bad noun attachment");
	con->dt_tag = nt;
}

wording Kinds::Constructors::get_name(kind_constructor *con, int plural_form) {
	if (con->dt_tag) {
		noun *nt = con->dt_tag;
		if (nt) return Nouns::get_name(nt, plural_form);
	}
	return EMPTY_WORDING;
}

wording Kinds::Constructors::get_name_in_play(kind_constructor *con, int plural_form,
	PREFORM_LANGUAGE_TYPE *nl) {
	if (con->dt_tag) {
		noun *nt = con->dt_tag;
		if (nt) return Nouns::get_name_in_play(nt, plural_form, nl);
	}
	return EMPTY_WORDING;
}

noun *Kinds::Constructors::get_noun(kind_constructor *con) {
	if (con == NULL) return NULL;
	return con->dt_tag;
}

@h Names in the I6 template.
An identifier like |WHATEVER_TY|, then, begins life in a definition inside an
I6 template file; becomes attached to a constructor here; and finally winds up
back in I6 code, because we define it as the constant for the weak kind ID
of the kind which the constructor makes:

=
#ifdef CORE_MODULE
inter_name *UNKNOWN_TY_iname = NULL;
void Kinds::Constructors::compile_I6_constants(void) {
	UNKNOWN_TY_iname = Hierarchy::find(UNKNOWN_TY_HL);
	Emit::named_numeric_constant(UNKNOWN_TY_iname, (inter_t) UNKNOWN_NT);
	Hierarchy::make_available(Emit::tree(), UNKNOWN_TY_iname);

	kind_constructor *con;
	LOOP_OVER(con, kind_constructor) {
		text_stream *tn = Kinds::Constructors::name_in_template_code(con);
		if (Str::len(tn) > 0) {
			con->con_iname = Hierarchy::make_iname_with_specific_name(WEAK_ID_HL, tn, Kinds::Constructors::package(con));
			Hierarchy::make_available(Emit::tree(), con->con_iname);
			Emit::named_numeric_constant(con->con_iname, (inter_t) con->weak_kind_ID);
		}
	}

	inter_name *hwm = Hierarchy::find(BASE_KIND_HWM_HL);
	Emit::named_numeric_constant(hwm, (inter_t) next_free_data_type_ID);
	Hierarchy::make_available(Emit::tree(), hwm);
}
inter_name *Kinds::Constructors::UNKNOWN_iname(void) {
	if (UNKNOWN_TY_iname == NULL) internal_error("no unknown yet");
	return UNKNOWN_TY_iname;
}
package_request *Kinds::Constructors::package(kind_constructor *con) {
	if (con->kc_package == NULL) {
		if (con->defined_in_source_text) {
			compilation_module *C = Modules::find(con->where_defined_in_source_text);
			con->kc_package = Hierarchy::package(C, KIND_HAP);
		} else if (con->superkind_set_at) {
			compilation_module *C = Modules::find(con->superkind_set_at);
			con->kc_package = Hierarchy::package(C, KIND_HAP);
		} else {
			con->kc_package = Hierarchy::synoptic_package(KIND_HAP);
		}
		wording W = Kinds::Constructors::get_name(con, FALSE);
		if (Wordings::nonempty(W))
			Hierarchy::markup_wording(con->kc_package, KIND_NAME_HMD, W);
		else if (Str::len(con->name_in_template_code) > 0)
			Hierarchy::markup(con->kc_package, KIND_NAME_HMD, con->name_in_template_code);
		else
			Hierarchy::markup(con->kc_package, KIND_NAME_HMD, I"(anonymous kind)");
	}
	return con->kc_package;
}
inter_name *Kinds::Constructors::iname(kind_constructor *con) {
	if (UNKNOWN_TY_iname == NULL) internal_error("no con symbols yet");
	return con->con_iname;
}
inter_name *Kinds::Constructors::first_instance_iname(kind_constructor *con) {
	return con->first_instance_iname;
}
void Kinds::Constructors::set_first_instance_iname(kind_constructor *con, inter_name *iname) {
	con->first_instance_iname = iname;
}
inter_name *Kinds::Constructors::next_instance_iname(kind_constructor *con) {
	return con->next_instance_iname;
}
void Kinds::Constructors::set_next_instance_iname(kind_constructor *con, inter_name *iname) {
	con->next_instance_iname = iname;
}
#endif

text_stream *Kinds::Constructors::name_in_template_code(kind_constructor *con) {
	return con->name_in_template_code;
}

@ We also need to parse this, occasionally (if we needed this more than a
small and bounded number of times we'd want a faster method, but we don't):

=
kind_constructor *Kinds::Constructors::parse(text_stream *sn) {
	if (sn == NULL) return NULL;
	kind_constructor *con;
	LOOP_OVER(con, kind_constructor)
		if (Str::eq(sn, con->name_in_template_code))
			return con;
	return NULL;
}

@h Transformations.
Conversions of an existing constructor to make it a unit or enumeration also
require running macros in the kind interpreter:

=
int Kinds::Constructors::convert_to_unit(parse_node_tree *T, kind_constructor *con) {
	if (con->is_incompletely_defined == TRUE) {
		Kinds::Interpreter::play_back_kind_macro(T,
			Kinds::Interpreter::parse_kind_macro_name(I"#UNIT"), con);
		return TRUE;
	}
	if (Kinds::Constructors::is_arithmetic(con)) return TRUE; /* i.e., if it succeeded */
	return FALSE;
}

int Kinds::Constructors::convert_to_enumeration(parse_node_tree *T, kind_constructor *con) {
	if (con->is_incompletely_defined == TRUE) {
		Kinds::Interpreter::play_back_kind_macro(T,
			Kinds::Interpreter::parse_kind_macro_name(I"#ENUMERATION"), con);
		if (con->linguistic)
			Kinds::Interpreter::play_back_kind_macro(T,
				Kinds::Interpreter::parse_kind_macro_name(I"#LINGUISTIC"), con);
		return TRUE;
	}
	if (Kinds::Constructors::is_enumeration(con)) return TRUE; /* i.e., if it succeeded */
	return FALSE;
}

@ And similarly:

=
void Kinds::Constructors::convert_to_real(parse_node_tree *T, kind_constructor *con) {
	Kinds::Interpreter::play_back_kind_macro(T,
		Kinds::Interpreter::parse_kind_macro_name(I"#REAL"), con);
}

@ A few base kinds are marked as "linguistic", which simply enables us to fence
them tidily off in the index.

=
void Kinds::Constructors::mark_as_linguistic(kind_constructor *con) {
	con->linguistic = TRUE;
}

@h For construction purposes.

=
kind **Kinds::Constructors::cache_location(kind_constructor *con) {
	if (con) return &(con->cached_kind);
	return NULL;
}

int Kinds::Constructors::arity(kind_constructor *con) {
	if (con == NULL) return 0;
	if (con->group == PROPER_CONSTRUCTOR_GRP) return con->constructor_arity;
	return 0;
}

int Kinds::Constructors::tupling(kind_constructor *con, int b) {
	return con->tupling[b];
}

int Kinds::Constructors::variance(kind_constructor *con, int b) {
	return con->variance[b];
}

@h Questions about constructors.
The rest of Inform is not encouraged to poke at constructors directly; it
ought to ask questions about kinds instead (see "Using Kinds"). However:

=
int Kinds::Constructors::is_definite(kind_constructor *con) {
	if ((con->group == BASE_CONSTRUCTOR_GRP) ||
		(con->group == PROPER_CONSTRUCTOR_GRP))
			return TRUE;
	return FALSE;
}

int Kinds::Constructors::get_weak_ID(kind_constructor *con) {
	if (con == NULL) return 0;
	return con->weak_kind_ID;
}

int Kinds::Constructors::is_arithmetic(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((Kinds::Constructors::is_definite(con)) &&
		(Kinds::Constructors::compatible(con,
			Kinds::get_construct(K_arithmetic_value), FALSE))) return TRUE;
	return FALSE;
}

int Kinds::Constructors::is_arithmetic_and_real(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((Kinds::Constructors::is_definite(con)) &&
		(Kinds::Constructors::compatible(con,
			Kinds::get_construct(K_real_arithmetic_value), FALSE))) return TRUE;
	return FALSE;
}

int Kinds::Constructors::is_enumeration(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((Kinds::Constructors::is_definite(con)) &&
		(Kinds::Constructors::compatible(con,
			Kinds::get_construct(K_enumerated_value), FALSE))) return TRUE;
	return FALSE;
}

@h Cast and instance lists.
Each constructor has a list of other constructors (all of the |KIND_OF_KIND_GRP|
group) which it's an instance of: value, word value, arithmetic value, and so on.

=
int Kinds::Constructors::find_cast(kind_constructor *from, kind_constructor *to) {
	if (to) {
		kind_constructor_casting_rule *dtcr;
		for (dtcr = to->first_casting_rule; dtcr; dtcr = dtcr->next_casting_rule) {
			if (Str::len(dtcr->cast_from_kind_unparsed) > 0) {
				dtcr->cast_from_kind =
					Kinds::Constructors::parse(dtcr->cast_from_kind_unparsed);
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
int Kinds::Constructors::find_instance(kind_constructor *from, kind_constructor *to) {
	kind_constructor_instance *dti;
	for (dti = from->first_instance_rule; dti; dti = dti->next_instance_rule) {
		if (Str::len(dti->instance_of_this_unparsed) > 0) {
			dti->instance_of_this =
				Kinds::Constructors::parse(dti->instance_of_this_unparsed);
			Str::clear(dti->instance_of_this_unparsed);
		}
		if (dti->instance_of_this == to) return TRUE;
	}
	return FALSE;
}

@h Compatibility.
The following tests if |from| is compatible with |to|.

=
int Kinds::Constructors::compatible(kind_constructor *from, kind_constructor *to, int allow_casts) {
	if (to == from) return TRUE;
	if ((to == NULL) || (from == NULL)) return FALSE;
	if ((allow_casts) && (Kinds::Constructors::find_cast(from, to))) return TRUE;
	if (Kinds::Constructors::find_instance(from, to)) return TRUE;
	return FALSE;
}

@ And more elaborately:

=
int Kinds::Constructors::uses_pointer_values(kind_constructor *con) {
	if (con == NULL) return FALSE;
	if ((Kinds::Constructors::is_definite(con)) &&
		(Kinds::Constructors::compatible(con, Kinds::get_construct(K_pointer_value), FALSE))) return TRUE;
	return FALSE;
}

int Kinds::Constructors::allow_word_as_pointer(kind_constructor *left, kind_constructor *right) {
	if (Kinds::Constructors::uses_pointer_values(left) == FALSE) return FALSE;
	if (Kinds::Constructors::uses_pointer_values(right) == TRUE) return FALSE;
	if (Kinds::Constructors::compatible(right, left, TRUE)) return TRUE;
	return FALSE;
}
