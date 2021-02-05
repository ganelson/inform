[CoreSyntax::] Inform-Only Nodes and Annotations.

How Inform extends and annotates the syntax tree.

@h Nodes.
The syntax tree is managed by the //syntax// services module, which defines the
most basic node types, which are enumerated by constants in the form |*_NT|.
(*) Structural nodes are used to break the source text down to the sentence
level, and are arranged in a hierarchy:
(-*) Level 1 structural nodes, category |L1_NCAT|, are defined only in
//syntax: Node Types//, and are basically headings.
(-*) Level 2 structural nodes, category |L2_NCAT|, are defined both in
//syntax: Node Types// and //supervisor: Source Text//. These are top-level
declarations and assertion sentences.
(-*) Level 3 structural nodes, category |L3_NCAT|, are defined both in
//linguistics: Diagrams// and below. These are clauses in sentences.
(*) Code nodes, category |CODE_NCAT|, are defined only below. They occur only
inside imperative code (i.e. rules and phrase definitions), in subtrees headed
by a level-2 |RULE_NT| node, and they organise what is to be compiled.
(*) Specification nodes represent values or descriptions of values, and are
defined only below. These occur frequently in the parse tree as children of
code nodes, but can also be used in detached form as a way to represent, say,
the number 9, or a requirement for something. (See //values// for more.)
Specifications come in three sorts:
(-*) Rvalues, |RVALUE_NCAT|, such as numbers or texts.
(-*) Lvalues, |LVALUE_NCAT|, such as variables.
(-*) Conditions, |COND_NCAT|, representing the logical structure of conditions.

@ Further node types and annotations are created in //if: IF Module//. Just
in case that is not being compiled, the following constant needs to exist
for compilation reasons, but will never be used:

@default ACTION_NT 0x80000000

@ To take these by category:

@d MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK CoreSyntax::create_node_types

=
void CoreSyntax::create_node_types(void) {
	@<Create additional level 3 structural nodes@>;
	@<Create the code nodes@>;
	@<Create the rvalue nodes@>;
	@<Create the lvalue nodes@>;
	@<Create the condition nodes@>;
	#ifdef IF_MODULE
	IFModule::create_node_types();
	#endif
}

@

@e ALLOWED_NT                   /* "an animal is allowed to have a description" */
@e EVERY_NT                     /* "every container" */
@e ADJECTIVE_NT                 /* "open" */
@e PROPERTYCALLED_NT            /* "a man has a number called age" */
@e CREATED_NT                   /* "a vehicle called Sarah Jane's car" */

@<Create additional level 3 structural nodes@> =
	NodeType::new(ALLOWED_NT, I"ALLOWED_NT",               1, 1,     L3_NCAT, ASSERT_NFLAG);
	NodeType::new(EVERY_NT, I"EVERY_NT",                   0, INFTY, L3_NCAT, ASSERT_NFLAG);
	NodeType::new(ADJECTIVE_NT, I"ADJECTIVE_NT",           0, INFTY, L3_NCAT, ASSERT_NFLAG);
	NodeType::new(PROPERTYCALLED_NT, I"PROPERTYCALLED_NT", 2, 2,     L3_NCAT, 0);
	NodeType::new(CREATED_NT, I"CREATED_NT",               0, 0,     L3_NCAT, ASSERT_NFLAG);

@

@e CODE_NCAT
@e INVOCATION_LIST_NT           /* Single invocation of a (possibly compound) phrase */
@e CODE_BLOCK_NT                /* Holds a block of source material */
@e INVOCATION_LIST_SAY_NT       /* Single thing to be said */
@e INVOCATION_NT                /* Usage of a phrase */
@e VOID_CONTEXT_NT              /* When a void phrase is required */
@e RVALUE_CONTEXT_NT            /* Arguments, in effect */
@e LVALUE_CONTEXT_NT            /* Named storage location */
@e LVALUE_TR_CONTEXT_NT         /* Table reference */
@e SPECIFIC_RVALUE_CONTEXT_NT   /* Argument must be an exact value */
@e MATCHING_RVALUE_CONTEXT_NT   /* Argument must match a description */
@e NEW_LOCAL_CONTEXT_NT         /* Argument which creates a local */
@e LVALUE_LOCAL_CONTEXT_NT      /* Argument which names a local */
@e CONDITION_CONTEXT_NT         /* Used for "now" conditions */

@<Create the code nodes@> =
	NodeType::new(INVOCATION_LIST_NT, I"INVOCATION_LIST_NT",                0, INFTY,   CODE_NCAT, 0);
	NodeType::new(CODE_BLOCK_NT, I"CODE_BLOCK_NT",	       					0, INFTY,	CODE_NCAT, 0);
	NodeType::new(INVOCATION_LIST_NT, I"INVOCATION_LIST_NT",		   		0, INFTY,	CODE_NCAT, 0);
	NodeType::new(INVOCATION_LIST_SAY_NT, I"INVOCATION_LIST_SAY_NT",		0, INFTY,	CODE_NCAT, 0);
	NodeType::new(INVOCATION_NT, I"INVOCATION_NT",		   					0, INFTY,	CODE_NCAT, 0);
	NodeType::new(VOID_CONTEXT_NT, I"VOID_CONTEXT_NT", 						0, INFTY,	CODE_NCAT, 0);
	NodeType::new(RVALUE_CONTEXT_NT, I"RVALUE_CONTEXT_NT", 					0, INFTY,	CODE_NCAT, 0);
	NodeType::new(LVALUE_CONTEXT_NT, I"LVALUE_CONTEXT_NT", 					0, INFTY,	CODE_NCAT, 0);
	NodeType::new(LVALUE_TR_CONTEXT_NT, I"LVALUE_TR_CONTEXT_NT", 			0, INFTY,	CODE_NCAT, 0);
	NodeType::new(SPECIFIC_RVALUE_CONTEXT_NT, I"SPECIFIC_RVALUE_CONTEXT_NT",	0, INFTY,	CODE_NCAT, 0);
	NodeType::new(MATCHING_RVALUE_CONTEXT_NT, I"MATCHING_RVALUE_CONTEXT_NT",	0, INFTY,	CODE_NCAT, 0);
	NodeType::new(NEW_LOCAL_CONTEXT_NT, I"NEW_LOCAL_CONTEXT_NT",			0, INFTY,	CODE_NCAT, 0);
	NodeType::new(LVALUE_LOCAL_CONTEXT_NT, I"LVALUE_LOCAL_CONTEXT_NT",		0, INFTY,	CODE_NCAT, 0);
	NodeType::new(CONDITION_CONTEXT_NT, I"CONDITION_CONTEXT_NT",			0, INFTY,	CODE_NCAT, 0);

@ The first specification nodes are the rvalues. These express run-time values --
numbers, objects, text and so on -- but cannot be assigned to, so that in an
assignment of the form "change L to R" they can be used only as R, not L. This
is not the same thing as a constant: for instance, "location of the player"
evaluates differently at different times, but cannot be changed in an
assignment.

@e RVALUE_NCAT
@e CONSTANT_NT                  /* "7", "the can't lock a locked door rule", etc. */
@e PHRASE_TO_DECIDE_VALUE_NT    /* "holder of the black box" */

@<Create the rvalue nodes@> =
	NodeType::new(CONSTANT_NT, I"CONSTANT_NT", 								0, 0,		RVALUE_NCAT, 0);
	NodeType::new(PHRASE_TO_DECIDE_VALUE_NT, I"PHRASE_TO_DECIDE_VALUE_NT",	1, 1,		RVALUE_NCAT, PHRASAL_NFLAG);

@ Lvalue nodes represent stored data at run-time, which means that they can
be assigned to. (The traditional terms "lvalue" and "rvalue" refer to the left
and right hand side of assignment statements written |A = B|.) For instance, a
table entry qualifies as an lvalue because it can be both read and changed. To
qualify as an lvalue, text must exactly specify the storage location referred
to: "Table of Corvettes" only indicates a table, not an entry in a table, so
is merely an rvalue. Similarly, "carrying capacity" (as a property name not
indicating an owner) is a mere rvalue.

@e LVALUE_NCAT
@e LOCAL_VARIABLE_NT            /* "the running total", say */
@e NONLOCAL_VARIABLE_NT         /* "the location" */
@e PROPERTY_VALUE_NT            /* "the carrying capacity of the cedarwood box" */
@e TABLE_ENTRY_NT               /* "tonnage in row X of the Table of Corvettes" */
@e LIST_ENTRY_NT                /* "item 4 in L" */

@<Create the lvalue nodes@> =
	NodeType::new(LOCAL_VARIABLE_NT, I"LOCAL_VARIABLE_NT", 					0, 0,		LVALUE_NCAT, 0);
	NodeType::new(NONLOCAL_VARIABLE_NT, I"NONLOCAL_VARIABLE_NT", 			0, 0,		LVALUE_NCAT, 0);
	NodeType::new(PROPERTY_VALUE_NT, I"PROPERTY_VALUE_NT", 					2, 2,		LVALUE_NCAT, 0);
	NodeType::new(TABLE_ENTRY_NT, I"TABLE_ENTRY_NT", 						1, 4,		LVALUE_NCAT, 0);
	NodeType::new(LIST_ENTRY_NT, I"LIST_ENTRY_NT", 							2, 2,		LVALUE_NCAT, 0);

@ Condition nodes represent atomic conditions, and also Boolean operations on
them. It's convenient to represent these operations as nodes in their own right
rather than as (for example) phrases: this reduces parsing ambiguities, but
also makes it easier for us to manipulate the results.

@e COND_NCAT
@e LOGICAL_NOT_NT               /* "not A" */
@e LOGICAL_TENSE_NT             /* in the past, A */
@e LOGICAL_AND_NT               /* "A and B" */
@e LOGICAL_OR_NT                /* "A or B" */
@e TEST_PROPOSITION_NT          /* if "the cat is on the mat" */
@e TEST_PHRASE_OPTION_NT        /* "giving full details", say */
@e TEST_VALUE_NT                /* when a value is used as a condition */

@<Create the condition nodes@> =
	NodeType::new(LOGICAL_NOT_NT, I"LOGICAL_NOT_NT", 						1, 1,		COND_NCAT, 0);
	NodeType::new(LOGICAL_TENSE_NT, I"LOGICAL_TENSE_NT", 					1, 1,		COND_NCAT, 0);
	NodeType::new(LOGICAL_AND_NT, I"LOGICAL_AND_NT", 						2, 2,		COND_NCAT, 0);
	NodeType::new(LOGICAL_OR_NT, I"LOGICAL_OR_NT", 							2, 2,		COND_NCAT, 0);
	NodeType::new(TEST_PROPOSITION_NT, I"TEST_PROPOSITION_NT", 				0, 0,		COND_NCAT, 0);
	NodeType::new(TEST_PHRASE_OPTION_NT, I"TEST_PHRASE_OPTION_NT", 			0, 0, 		COND_NCAT, 0);
	NodeType::new(TEST_VALUE_NT, I"TEST_VALUE_NT", 							1, 1,		COND_NCAT, 0);

@ Level 4 structural nodes can only be children of |RULE_NT| nodes (level 2)
or of each other, and their children are otherwise specifications.

Specification nodes can only have each other as children.

@d PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK CoreSyntax::grant_parentage_permissions

=
void CoreSyntax::grant_parentage_permissions(void) {
	NodeType::allow_parentage_for_categories(L2_NCAT, CODE_NCAT);
	NodeType::allow_parentage_for_categories(CODE_NCAT, CODE_NCAT);
	NodeType::allow_parentage_for_categories(CODE_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(CODE_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(CODE_NCAT, COND_NCAT);
	NodeType::allow_parentage_for_categories(CODE_NCAT, UNKNOWN_NCAT);

	NodeType::allow_parentage_for_categories(COND_NCAT, COND_NCAT);
	NodeType::allow_parentage_for_categories(COND_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(COND_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(COND_NCAT, UNKNOWN_NCAT);
	NodeType::allow_parentage_for_categories(LVALUE_NCAT, COND_NCAT);
	NodeType::allow_parentage_for_categories(LVALUE_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(LVALUE_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(LVALUE_NCAT, UNKNOWN_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, COND_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, UNKNOWN_NCAT);
}

@ With one exception: when a phrase to decide a value (i.e., a function call)
occurs, its children will be invocation list nodes. This needs to be an
exception because it's an |RVALUE_NCAT| with a |CODE_NCAT| child, which
would ordinarily be forbidden.

@d PARENTAGE_EXCEPTIONS_SYNTAX_CALLBACK CoreSyntax::parentage_exceptions

=
int CoreSyntax::parentage_exceptions(node_type_t t_parent, int cat_parent,
	node_type_t t_child, int cat_child) {
	if ((t_parent == PHRASE_TO_DECIDE_VALUE_NT) &&
		(t_child == INVOCATION_LIST_NT)) return TRUE;
	return FALSE;
}

@ Inform is for the most part allowed to fool around with the parse tree,
re-typing and rearranging nodes. But specifications cannot never their types
changed, and the purpose of the following is to ensure that an internal error
is thrown if they do.

@d IMMUTABLE_NODE CoreSyntax::immutable

=
int CoreSyntax::immutable(node_type_t t) {
	if (t == UNKNOWN_NT) return FALSE;
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if ((metadata) &&
		((metadata->category == RVALUE_NCAT) ||
		(metadata->category == LVALUE_NCAT) ||
		(metadata->category == COND_NCAT))) return TRUE;
	return FALSE;
}

@ This indicates that |current_sentence| can be set to the node in question.

@d IS_SENTENCE_NODE_SYNTAX_CALLBACK CoreSyntax::second_level

=
int CoreSyntax::second_level(node_type_t t) {
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if ((metadata) && (metadata->category == L2_NCAT)) return TRUE;
	return FALSE;
}

@h Annotations.
Itemising the baubles on a Christmas tree...

@d ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK CoreSyntax::grant_annotation_permissions

=
void CoreSyntax::declare_annotations(void) {
	CoreSyntax::declare_unit();
	CoreSyntax::declare_L2_annotations();
	CoreSyntax::declare_L3_annotations();
	CoreSyntax::declare_code_annotations();
	CoreSyntax::declare_spec_annotations();
	#ifdef IF_MODULE
	IFModule::declare_annotations();
	#endif
}

void CoreSyntax::grant_annotation_permissions(void) {
	CoreSyntax::grant_unit_permissions();
	CoreSyntax::grant_L2_permissions();
	CoreSyntax::grant_L3_permissions();
	CoreSyntax::grant_code_permissions();
	CoreSyntax::grant_spec_permissions();
	#ifdef IF_MODULE
	IFModule::grant_annotation_permissions();
	#endif
}

@ The unit annotation is applied to every structural node, and indicates to
which compilation unit the node belongs.

@e unit_ANNOT /* |compilation_unit| */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(unit, compilation_unit)

@ For tedious code-sequencing reasons, the annotation functions for |unit_ANNOT|
are made in //building: Building Module//.

=
void CoreSyntax::declare_unit(void) {
	Annotations::declare_type(unit_ANNOT, CoreSyntax::write_unit_ANNOT);
}
void CoreSyntax::write_unit_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_unit(p))
		WRITE(" {unit: %d}", Node::get_unit(p)->allocation_id);
}

void CoreSyntax::grant_unit_permissions(void) {
	Annotations::allow_for_category(L1_NCAT, unit_ANNOT);
	Annotations::allow_for_category(L2_NCAT, unit_ANNOT);
	Annotations::allow_for_category(L3_NCAT, unit_ANNOT);
}

@h Annotations of Level 2 nodes.

@e classified_ANNOT /* |int|: this sentence has been classified */
@e clears_pronouns_ANNOT /* |int|: this sentence erases the current value of "it" */
@e implicit_in_creation_of_ANNOT /* |inference_subject|: for assemblies */
@e implicitness_count_ANNOT /* int: keeping track of recursive assemblies */
@e interpretation_of_subject_ANNOT /* |inference_subject|: subject, during passes */
@e verb_problem_issued_ANNOT /* |int|: has a problem message about the primary verb been issued already? */
@e you_can_ignore_ANNOT /* |int|: for assertions now drained of meaning */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(implicit_in_creation_of, inference_subject)
DECLARE_ANNOTATION_FUNCTIONS(interpretation_of_subject, inference_subject)

@ =
MAKE_ANNOTATION_FUNCTIONS(implicit_in_creation_of, inference_subject)
MAKE_ANNOTATION_FUNCTIONS(interpretation_of_subject, inference_subject)

@ =
void CoreSyntax::declare_L2_annotations(void) {
	Annotations::declare_type(
		classified_ANNOT, CoreSyntax::write_classified_ANNOT);
	Annotations::declare_type(
		clears_pronouns_ANNOT, CoreSyntax::write_clears_pronouns_ANNOT);
	Annotations::declare_type(
		implicit_in_creation_of_ANNOT, CoreSyntax::write_implicit_in_creation_of_ANNOT);
	Annotations::declare_type(
		implicitness_count_ANNOT, CoreSyntax::write_implicitness_count_ANNOT);
	Annotations::declare_type(
		interpretation_of_subject_ANNOT, CoreSyntax::write_interpretation_of_subject_ANNOT);
	Annotations::declare_type(
		verb_problem_issued_ANNOT, CoreSyntax::write_verb_problem_issued_ANNOT);
	Annotations::declare_type(
		you_can_ignore_ANNOT, CoreSyntax::write_you_can_ignore_ANNOT);
}
void CoreSyntax::write_classified_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, classified_ANNOT))
		WRITE(" {classified}");
}
void CoreSyntax::write_clears_pronouns_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, clears_pronouns_ANNOT))
		WRITE(" {clears pronouns}");
}
void CoreSyntax::write_implicit_in_creation_of_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_implicit_in_creation_of(p))
		WRITE(" {implicit in creation of: $j}", Node::get_implicit_in_creation_of(p));
}
void CoreSyntax::write_implicitness_count_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, implicitness_count_ANNOT) > 0)
		WRITE(" {implicitness: %d}", Annotations::read_int(p, implicitness_count_ANNOT));
}
void CoreSyntax::write_interpretation_of_subject_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_interpretation_of_subject(p))
		WRITE(" {interpretation of subject: $j}", Node::get_interpretation_of_subject(p));
}
void CoreSyntax::write_verb_problem_issued_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, verb_problem_issued_ANNOT))
		WRITE(" {verb problem issued}");
}
void CoreSyntax::write_you_can_ignore_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, you_can_ignore_ANNOT))
		WRITE(" {you can ignore}");
}

void CoreSyntax::grant_L2_permissions(void) {
	Annotations::allow_for_category(L2_NCAT, clears_pronouns_ANNOT);
	Annotations::allow_for_category(L2_NCAT, interpretation_of_subject_ANNOT);
	Annotations::allow_for_category(L2_NCAT, verb_problem_issued_ANNOT);
	Annotations::allow(RULE_NT, indentation_level_ANNOT);
	Annotations::allow(SENTENCE_NT, implicit_in_creation_of_ANNOT);
	Annotations::allow(SENTENCE_NT, implicitness_count_ANNOT);
	Annotations::allow(SENTENCE_NT, you_can_ignore_ANNOT);
	Annotations::allow(SENTENCE_NT, classified_ANNOT);
}

@h Annotations of Level 3 nodes.

@e category_of_I6_translation_ANNOT /* int: what sort of "translates into I6" sentence this is */
@e creation_proposition_ANNOT /* |pcalc_prop|: proposition which newly created value satisfies */
@e creation_site_ANNOT /* |int|: whether an instance was created from this node */
@e defn_language_ANNOT /* |inform_language|: what language this definition is in */
@e evaluation_ANNOT /* |parse_node|: result of evaluating the text */
@e explicit_gender_marker_ANNOT  /* |int|: used by PROPER NOUN nodes for evident genders */
@e lpe_options_ANNOT /* |int|: options set for a literal pattern part */
@e multiplicity_ANNOT /* |int|: e.g., 5 for "five gold rings" */
@e new_relation_here_ANNOT /* |binary_predicate|: new relation as subject of "relates" sentence */
@e nowhere_ANNOT /* |int|: used by the spatial plugin to show this represents "nowhere" */
@e predicate_ANNOT /* |unary_predicate|: which adjective is asserted */
@e quant_ANNOT /* |quantifier|: for quantified excerpts like "three baskets" */
@e quantification_parameter_ANNOT /* |int|: e.g., 3 for "three baskets" */
@e refined_ANNOT /* |int|: this subtree has had its nouns parsed */
@e row_amendable_ANNOT /* int: a candidate row for a table amendment */
@e rule_placement_sense_ANNOT /* |int|: are we listing a rule into something, or out of it? */
@e subject_ANNOT /* |inference_subject|: what this node describes */
@e table_cell_unspecified_ANNOT /* int: used to mark table entries as unset */
@e turned_already_ANNOT /* |int|: aliasing like "player" to "yourself" performed already */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(creation_proposition, pcalc_prop)
DECLARE_ANNOTATION_FUNCTIONS(defn_language, inform_language)
DECLARE_ANNOTATION_FUNCTIONS(evaluation, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(grammar_token_relation, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(grammar_value, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(new_relation_here, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(predicate, unary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(quant, quantifier)
DECLARE_ANNOTATION_FUNCTIONS(subject, inference_subject)

@ =
MAKE_ANNOTATION_FUNCTIONS(creation_proposition, pcalc_prop)
MAKE_ANNOTATION_FUNCTIONS(defn_language, inform_language)
MAKE_ANNOTATION_FUNCTIONS(evaluation, parse_node)
MAKE_ANNOTATION_FUNCTIONS(grammar_token_relation, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(grammar_value, parse_node)
MAKE_ANNOTATION_FUNCTIONS(new_relation_here, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(predicate, unary_predicate)
MAKE_ANNOTATION_FUNCTIONS(quant, quantifier)
MAKE_ANNOTATION_FUNCTIONS(subject, inference_subject)

@ =
void CoreSyntax::declare_L3_annotations(void) {
	Annotations::declare_type(
		category_of_I6_translation_ANNOT, CoreSyntax::write_category_of_I6_translation_ANNOT);
	Annotations::declare_type(
		creation_proposition_ANNOT, CoreSyntax::write_creation_proposition_ANNOT);
	Annotations::declare_type(
		creation_site_ANNOT, CoreSyntax::write_creation_site_ANNOT);
	Annotations::declare_type(
		defn_language_ANNOT, CoreSyntax::write_defn_language_ANNOT);
	Annotations::declare_type(
		evaluation_ANNOT, CoreSyntax::write_evaluation_ANNOT);
	Annotations::declare_type(
		explicit_gender_marker_ANNOT, CoreSyntax::write_explicit_gender_marker_ANNOT);
	Annotations::declare_type(
		lpe_options_ANNOT, CoreSyntax::write_lpe_options_ANNOT);
	Annotations::declare_type(
		multiplicity_ANNOT, CoreSyntax::write_multiplicity_ANNOT);
	Annotations::declare_type(
		new_relation_here_ANNOT, CoreSyntax::write_new_relation_here_ANNOT);
	Annotations::declare_type(
		nowhere_ANNOT, CoreSyntax::write_nowhere_ANNOT);
	Annotations::declare_type(
		predicate_ANNOT, CoreSyntax::write_predicate_ANNOT);
	Annotations::declare_type(
		quant_ANNOT, CoreSyntax::write_quant_ANNOT);
	Annotations::declare_type(
		quantification_parameter_ANNOT, CoreSyntax::write_quantification_parameter_ANNOT);
	Annotations::declare_type(
		refined_ANNOT, CoreSyntax::write_refined_ANNOT);
	Annotations::declare_type(
		row_amendable_ANNOT, CoreSyntax::write_row_amendable_ANNOT);
	Annotations::declare_type(
		rule_placement_sense_ANNOT, CoreSyntax::write_rule_placement_sense_ANNOT);
	Annotations::declare_type(
		subject_ANNOT, CoreSyntax::write_subject_ANNOT);
	Annotations::declare_type(
		table_cell_unspecified_ANNOT, CoreSyntax::write_table_cell_unspecified_ANNOT);
	Annotations::declare_type(
		turned_already_ANNOT, CoreSyntax::write_turned_already_ANNOT);
}
void CoreSyntax::write_category_of_I6_translation_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {category: %d}", Annotations::read_int(p, category_of_I6_translation_ANNOT));
}
void CoreSyntax::write_creation_proposition_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_creation_proposition(p))
		WRITE(" {creation: $D}", Node::get_creation_proposition(p));
}
void CoreSyntax::write_creation_site_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, creation_site_ANNOT))
		WRITE(" {created here}");
}
void CoreSyntax::write_defn_language_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_defn_language(p))
		WRITE(" {language: %J}", Node::get_defn_language(p));
}
void CoreSyntax::write_evaluation_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_evaluation(p))
		WRITE(" {eval: $P}", Node::get_evaluation(p));
}
void CoreSyntax::write_explicit_gender_marker_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {explicit gender marker: ");
	Lcon::write_gender(OUT, Annotations::read_int(p, explicit_gender_marker_ANNOT));
	WRITE("}");
}
void CoreSyntax::write_lpe_options_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {lpe options: %04x}", Annotations::read_int(p, lpe_options_ANNOT));
}
void CoreSyntax::write_multiplicity_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, multiplicity_ANNOT))
		WRITE(" {multiplicity %d}", Annotations::read_int(p, multiplicity_ANNOT));
}
void CoreSyntax::write_new_relation_here_ANNOT(text_stream *OUT, parse_node *p) {
	binary_predicate *bp = Node::get_new_relation_here(p);
	if (bp) WRITE(" {new relation: %S}", bp->debugging_log_name);
}
void CoreSyntax::write_nowhere_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, nowhere_ANNOT))
		WRITE(" {nowhere}");
}
void CoreSyntax::write_predicate_ANNOT(text_stream *OUT, parse_node *p) {
	unary_predicate *up = Node::get_predicate(p);
	if (up) {
		WRITE(" {predicate: ");
		UnaryPredicateFamilies::log(OUT, up);
		WRITE("}");
	}
}
void CoreSyntax::write_quant_ANNOT(text_stream *OUT, parse_node *p) {
	quantifier *q = Node::get_quant(p);
	if (q) WRITE(" {quantifier: %s}", q->log_text);
}
void CoreSyntax::write_quantification_parameter_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, quantification_parameter_ANNOT) > 0)
		WRITE(" {quantification parameter: %d}",
			Annotations::read_int(p, quantification_parameter_ANNOT));
}
void CoreSyntax::write_refined_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, refined_ANNOT))
		WRITE(" {refined}");
}
void CoreSyntax::write_row_amendable_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, row_amendable_ANNOT))
		WRITE(" {row amendable}");
}
void CoreSyntax::write_rule_placement_sense_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, rule_placement_sense_ANNOT))
		WRITE(" {rule placement sense: positive}");
	else
		WRITE(" {rule placement sense: negative}");
}
void CoreSyntax::write_subject_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_subject(p))
		WRITE(" {refers: $j}", Node::get_subject(p));
}
void CoreSyntax::write_table_cell_unspecified_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, table_cell_unspecified_ANNOT))
		WRITE(" {table cell unspecified}");
}
void CoreSyntax::write_turned_already_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, turned_already_ANNOT))
		WRITE(" {turned already}");
}

void CoreSyntax::grant_L3_permissions(void) {
	Annotations::allow_for_category(L3_NCAT, refined_ANNOT);
	Annotations::allow_for_category(L3_NCAT, creation_proposition_ANNOT);
	Annotations::allow_for_category(L3_NCAT, evaluation_ANNOT);
	Annotations::allow_for_category(L3_NCAT, subject_ANNOT);
	Annotations::allow_for_category(L3_NCAT, explicit_gender_marker_ANNOT);
	Annotations::allow(ADJECTIVE_NT, predicate_ANNOT);
	Annotations::allow(VERB_NT, category_of_I6_translation_ANNOT);
	Annotations::allow(VERB_NT, rule_placement_sense_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, creation_site_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, multiplicity_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, quant_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, quantification_parameter_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, predicate_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, creation_site_ANNOT);
	Annotations::allow(UNPARSED_NOUN_NT, defn_language_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, defn_language_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, lpe_options_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, multiplicity_ANNOT);
	Annotations::allow(UNPARSED_NOUN_NT, new_relation_here_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, new_relation_here_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, nowhere_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, quant_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, quantification_parameter_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, row_amendable_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, slash_dash_dash_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, table_cell_unspecified_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, turned_already_ANNOT);
}

@h Annotations of code nodes.

@e colon_block_command_ANNOT /* int: this COMMAND uses the ":" not begin/end syntax */
@e control_structure_used_ANNOT /* |control_structure_phrase|: for CODE BLOCK nodes only */
@e end_control_structure_used_ANNOT /* |control_structure_phrase|: for CODE BLOCK nodes only */
@e epistemological_status_ANNOT /* |int|: a bitmap of results from checking an ambiguous reading */
@e from_text_substitution_ANNOT /* |int|: whether this is an implicit say invocation */
@e indentation_level_ANNOT /* |int|: level of Pythonesque indentation in code */
@e kind_of_new_variable_ANNOT /* |kind|: what if anything is returned */
@e kind_required_by_context_ANNOT /* |kind|: what if anything is expected here */
@e kind_resulting_ANNOT /* |kind|: what if anything is returned */
@e kind_variable_declarations_ANNOT /* |kind_variable_declaration|: and of these */
@e modal_verb_ANNOT /* |verb_conjugation|: relevant only for that: e.g., "might" */
@e phrase_invoked_ANNOT /* |phrase|: the phrase believed to be invoked... */
@e phrase_options_invoked_ANNOT /* |invocation_options|: details of any options used */
@e results_from_splitting_ANNOT /* |int|: node in a routine's parse tree from comma block notation */
@e say_adjective_ANNOT /* |adjective|: ...or the adjective to be agreed with by "say" */
@e say_verb_ANNOT /* |verb_conjugation|: ...or the verb to be conjugated by "say" */
@e say_verb_negated_ANNOT /* relevant only for that */
@e ssp_closing_segment_wn_ANNOT /* |int|: identifier for the last of these, or |-1| */
@e ssp_segment_count_ANNOT /* |int|: number of subsequent complex-say phrases in stream */
@e suppress_newlines_ANNOT /* |int|: whether the next say term runs on */
@e token_as_parsed_ANNOT /* |parse_node|: what if anything is returned */
@e token_check_to_do_ANNOT /* |parse_node|: what if anything is returned */
@e token_to_be_parsed_against_ANNOT /* |parse_node|: what if anything is returned */
@e unproven_ANNOT /* |int|: this invocation needs run-time typechecking */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(control_structure_used, control_structure_phrase)
DECLARE_ANNOTATION_FUNCTIONS(end_control_structure_used, control_structure_phrase)
DECLARE_ANNOTATION_FUNCTIONS(kind_of_new_variable, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_required_by_context, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_resulting, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_variable_declarations, kind_variable_declaration)
DECLARE_ANNOTATION_FUNCTIONS(modal_verb, verb_conjugation)
DECLARE_ANNOTATION_FUNCTIONS(phrase_invoked, phrase)
DECLARE_ANNOTATION_FUNCTIONS(phrase_options_invoked, invocation_options)
DECLARE_ANNOTATION_FUNCTIONS(say_adjective, adjective)
DECLARE_ANNOTATION_FUNCTIONS(say_verb, verb_conjugation)
DECLARE_ANNOTATION_FUNCTIONS(token_as_parsed, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(token_check_to_do, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(token_to_be_parsed_against, parse_node)

@ =
MAKE_ANNOTATION_FUNCTIONS(control_structure_used, control_structure_phrase)
MAKE_ANNOTATION_FUNCTIONS(end_control_structure_used, control_structure_phrase)
MAKE_ANNOTATION_FUNCTIONS(kind_of_new_variable, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_required_by_context, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_resulting, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_variable_declarations, kind_variable_declaration)
MAKE_ANNOTATION_FUNCTIONS(modal_verb, verb_conjugation)
MAKE_ANNOTATION_FUNCTIONS(phrase_invoked, phrase)
MAKE_ANNOTATION_FUNCTIONS(phrase_options_invoked, invocation_options)
MAKE_ANNOTATION_FUNCTIONS(say_adjective, adjective)
MAKE_ANNOTATION_FUNCTIONS(say_verb, verb_conjugation)
MAKE_ANNOTATION_FUNCTIONS(token_as_parsed, parse_node)
MAKE_ANNOTATION_FUNCTIONS(token_check_to_do, parse_node)
MAKE_ANNOTATION_FUNCTIONS(token_to_be_parsed_against, parse_node)

@ =
void CoreSyntax::declare_code_annotations(void) {
	Annotations::declare_type(
		colon_block_command_ANNOT, CoreSyntax::write_colon_block_command_ANNOT);
	Annotations::declare_type(
		control_structure_used_ANNOT, CoreSyntax::write_control_structure_used_ANNOT);
	Annotations::declare_type(
		end_control_structure_used_ANNOT, CoreSyntax::write_end_control_structure_used_ANNOT);
	Annotations::declare_type(
		epistemological_status_ANNOT, CoreSyntax::write_epistemological_status_ANNOT);
	Annotations::declare_type(
		from_text_substitution_ANNOT, CoreSyntax::write_from_text_substitution_ANNOT);
	Annotations::declare_type(
		indentation_level_ANNOT, CoreSyntax::write_indentation_level_ANNOT);
	Annotations::declare_type(
		kind_of_new_variable_ANNOT, CoreSyntax::write_kind_of_new_variable_ANNOT);
	Annotations::declare_type(
		kind_required_by_context_ANNOT, CoreSyntax::write_kind_required_by_context_ANNOT);
	Annotations::declare_type(
		kind_resulting_ANNOT, CoreSyntax::write_kind_resulting_ANNOT);
	Annotations::declare_type(
		kind_variable_declarations_ANNOT, CoreSyntax::write_kind_variable_declarations_ANNOT);
	Annotations::declare_type(
		modal_verb_ANNOT, CoreSyntax::write_modal_verb_ANNOT);
	Annotations::declare_type(
		phrase_invoked_ANNOT, CoreSyntax::write_phrase_invoked_ANNOT);
	Annotations::declare_type(
		phrase_options_invoked_ANNOT, CoreSyntax::write_phrase_options_invoked_ANNOT);
	Annotations::declare_type(
		results_from_splitting_ANNOT, CoreSyntax::write_results_from_splitting_ANNOT);
	Annotations::declare_type(
		say_adjective_ANNOT, CoreSyntax::write_say_adjective_ANNOT);
	Annotations::declare_type(
		say_verb_ANNOT, CoreSyntax::write_say_verb_ANNOT);
	Annotations::declare_type(
		say_verb_negated_ANNOT, CoreSyntax::write_say_verb_ANNOT);
	Annotations::declare_type(
		ssp_closing_segment_wn_ANNOT, CoreSyntax::write_ssp_closing_segment_wn_ANNOT);
	Annotations::declare_type(
		ssp_segment_count_ANNOT, CoreSyntax::write_ssp_segment_count_ANNOT);
	Annotations::declare_type(
		suppress_newlines_ANNOT, CoreSyntax::write_suppress_newlines_ANNOT);
	Annotations::declare_type(
		token_as_parsed_ANNOT, CoreSyntax::write_token_as_parsed_ANNOT);
	Annotations::declare_type(
		token_check_to_do_ANNOT, CoreSyntax::write_token_check_to_do_ANNOT);
	Annotations::declare_type(
		token_to_be_parsed_against_ANNOT, CoreSyntax::write_token_to_be_parsed_against_ANNOT);
	Annotations::declare_type(
		unproven_ANNOT, CoreSyntax::write_unproven_ANNOT);
}
void CoreSyntax::write_colon_block_command_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, colon_block_command_ANNOT) > 0)
		WRITE(" {colon_block_command}");
}
void CoreSyntax::write_control_structure_used_ANNOT(text_stream *OUT, parse_node *p) {
	control_structure_phrase *csp = Node::get_control_structure_used(p);
	if (csp) {
		WRITE(" {control structure: "); ControlStructures::log(OUT, csp); WRITE("}");
	}
}
void CoreSyntax::write_end_control_structure_used_ANNOT(text_stream *OUT, parse_node *p) {
	control_structure_phrase *csp = Node::get_end_control_structure_used(p);
	if (csp) {
		WRITE(" {end control structure: "); ControlStructures::log(OUT, csp); WRITE("}");
	}
}
void CoreSyntax::write_epistemological_status_ANNOT(text_stream *OUT, parse_node *p) {
	int n = Annotations::read_int(p, from_text_substitution_ANNOT);
	if (n != 0) {
		WRITE(" {epistemological_status: ");
		if (n & TESTED_DASHFLAG)         		WRITE("t");
		if (n & INTERESTINGLY_FAILED_DASHFLAG)	WRITE("i");
		if (n & GROSSLY_FAILED_DASHFLAG) 		WRITE("g");
		if (n & PASSED_DASHFLAG)         		WRITE("p");
		if (n & UNPROVEN_DASHFLAG)       		WRITE("u");
		WRITE("}");
	}
}
void CoreSyntax::write_from_text_substitution_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, from_text_substitution_ANNOT) > 0)
		WRITE(" {from text substitution}");
}
void CoreSyntax::write_indentation_level_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, indentation_level_ANNOT) > 0)
		WRITE(" {indent: %d}", Annotations::read_int(p, indentation_level_ANNOT));
}
void CoreSyntax::write_kind_of_new_variable_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_kind_of_new_variable(p))
		WRITE(" {new var: %u}", Node::get_kind_of_new_variable(p));
}
void CoreSyntax::write_kind_required_by_context_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_kind_required_by_context(p))
		WRITE(" {required: %u}", Node::get_kind_required_by_context(p));
}
void CoreSyntax::write_kind_resulting_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_kind_resulting(p))
		WRITE(" {resulting: %u}", Node::get_kind_resulting(p));
}
void CoreSyntax::write_kind_variable_declarations_ANNOT(text_stream *OUT, parse_node *p) {
	kind_variable_declaration *kvd = Node::get_kind_variable_declarations(p);
	if (kvd) {
		WRITE(" {kind variable declarations:");
		while (kvd) {
			WRITE(" %c=%u", 'A'+kvd->kv_number-1, kvd->kv_value);
			kvd = kvd->next;
		}
		WRITE("}");
	}
}
void CoreSyntax::write_modal_verb_ANNOT(text_stream *OUT, parse_node *p) {
	verb_conjugation *vc = Node::get_modal_verb(p);
	if (vc) WRITE(" {modal verb: %A}", vc->infinitive);
}
void CoreSyntax::write_phrase_invoked_ANNOT(text_stream *OUT, parse_node *p) {
	phrase *ph = Node::get_phrase_invoked(p);
	if (ph) WRITE(" {phrase invoked: %n}", Phrases::iname(ph));
}
void CoreSyntax::write_phrase_options_invoked_ANNOT(text_stream *OUT, parse_node *p) {
	invocation_options *io = Node::get_phrase_options_invoked(p);
	if (io) WRITE(" {phrase options invoked: %W}", io->options_invoked_text);
}
void CoreSyntax::write_results_from_splitting_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, results_from_splitting_ANNOT) > 0)
		WRITE(" {results_from_splitting}");
}
void CoreSyntax::write_say_adjective_ANNOT(text_stream *OUT, parse_node *p) {
	adjective *adj = Node::get_say_adjective(p);
	if (adj) {
		WRITE(" {say adjective: ");
		Adjectives::log(adj);
		WRITE("}");
	}
}
void CoreSyntax::write_say_verb_ANNOT(text_stream *OUT, parse_node *p) {
	verb_conjugation *vc = Node::get_say_verb(p);
	if (vc) WRITE(" {say verb: %A}", vc->infinitive);
}
void CoreSyntax::write_say_verb_negated_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, say_verb_negated_ANNOT) > 0)
		WRITE(" {say verb negated}");
}
void CoreSyntax::write_ssp_closing_segment_wn_ANNOT(text_stream *OUT, parse_node *p) {
	int wn = Annotations::read_int(p, ssp_closing_segment_wn_ANNOT);
	if (wn > 0) WRITE(" {ssp closing segment: %W}", Wordings::one_word(wn));
}
void CoreSyntax::write_ssp_segment_count_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {ssp_segment_count: %d}", Annotations::read_int(p, ssp_segment_count_ANNOT));
}
void CoreSyntax::write_suppress_newlines_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, suppress_newlines_ANNOT) > 0)
		WRITE(" {suppress_newlines}");
}
void CoreSyntax::write_token_as_parsed_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {token as parsed: $P}", Node::get_token_as_parsed(p));
}
void CoreSyntax::write_token_check_to_do_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {token check to do: $P}", Node::get_token_check_to_do(p));
}
void CoreSyntax::write_token_to_be_parsed_against_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {token to be parsed against: $P}", Node::get_token_to_be_parsed_against(p));
}
void CoreSyntax::write_unproven_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, unproven_ANNOT) > 0)
		WRITE(" {unproven}");
}

void CoreSyntax::grant_code_permissions(void) {
	Annotations::allow_for_category(CODE_NCAT, colon_block_command_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, control_structure_used_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, end_control_structure_used_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, evaluation_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, indentation_level_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, kind_of_new_variable_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, kind_required_by_context_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, results_from_splitting_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, token_as_parsed_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, token_check_to_do_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, token_to_be_parsed_against_ANNOT);
	Annotations::allow_for_category(CODE_NCAT, verb_problem_issued_ANNOT);
	Annotations::allow(INVOCATION_LIST_NT, from_text_substitution_ANNOT);
	Annotations::allow(INVOCATION_LIST_SAY_NT, suppress_newlines_ANNOT);
	Annotations::allow(INVOCATION_NT, epistemological_status_ANNOT);
	Annotations::allow(INVOCATION_NT, kind_resulting_ANNOT);
	Annotations::allow(INVOCATION_NT, kind_variable_declarations_ANNOT);
	Annotations::allow(INVOCATION_NT, modal_verb_ANNOT);
	Annotations::allow(INVOCATION_NT, phrase_invoked_ANNOT);
	Annotations::allow(INVOCATION_NT, phrase_options_invoked_ANNOT);
	Annotations::allow(INVOCATION_NT, say_adjective_ANNOT);
	Annotations::allow(INVOCATION_NT, say_verb_ANNOT);
	Annotations::allow(INVOCATION_NT, say_verb_negated_ANNOT);
	Annotations::allow(INVOCATION_NT, ssp_closing_segment_wn_ANNOT);
	Annotations::allow(INVOCATION_NT, ssp_segment_count_ANNOT);
	Annotations::allow(INVOCATION_NT, suppress_newlines_ANNOT);
	Annotations::allow(INVOCATION_NT, save_self_ANNOT);
	Annotations::allow(INVOCATION_NT, unproven_ANNOT);

	/* this annotation is declared in the //problems// module */
	Annotations::allow_for_category(CODE_NCAT, problem_falls_under_ANNOT);
}

@h Annotations of specification nodes.

@e condition_tense_ANNOT /* |time_period|: for specification nodes */
@e constant_activity_ANNOT /* |activity|: for constant values */
@e constant_binary_predicate_ANNOT /* |binary_predicate|: for constant values */
@e constant_constant_phrase_ANNOT /* |constant_phrase|: for constant values */
@e constant_enumeration_ANNOT /* |int|: which one from an enumerated kind */
@e constant_equation_ANNOT /* |equation|: for constant values */
@e constant_instance_ANNOT /* |instance|: for constant values */
@e constant_local_variable_ANNOT /* |local_variable|: for constant values */
@e constant_named_rulebook_outcome_ANNOT /* |named_rulebook_outcome|: for constant values */
@e constant_nonlocal_variable_ANNOT /* |nonlocal_variable|: for constant values */
@e constant_number_ANNOT /* |int|: which integer this is */
@e constant_property_ANNOT /* |property|: for constant values */
@e constant_rule_ANNOT /* |rule|: for constant values */
@e constant_rulebook_ANNOT /* |rulebook|: for constant values */
@e constant_table_ANNOT /* |table|: for constant values */
@e constant_table_column_ANNOT /* |table_column|: for constant values */
@e constant_text_ANNOT /* |text_stream|: for constant values */
@e constant_use_option_ANNOT /* |use_option|: for constant values */
@e constant_verb_form_ANNOT /* |verb_form|: for constant values */
@e converted_SN_ANNOT /* |int|: marking descriptions */
@e explicit_iname_ANNOT /* |inter_name|: is this value explicitly an iname? */
@e explicit_literal_ANNOT /* |int|: my value is an explicit integer or text */
@e grammar_token_code_ANNOT /* int: used to identify grammar tokens */
@e is_phrase_option_ANNOT /* |int|: this unparsed text is a phrase option */
@e kind_of_value_ANNOT /* |kind|: for specification nodes */
@e nothing_object_ANNOT /* |int|: this represents |nothing| at run-time */
@e phrase_option_ANNOT /* |int|: $2^i$ where $i$ is the option number, $0\leq i<16$ */
@e property_name_used_as_noun_ANNOT /* |int|: in ambiguous cases such as "open" */
@e proposition_ANNOT /* |pcalc_prop|: for specification nodes */
@e record_as_self_ANNOT /* |int|: record recipient as |self| when writing this */
@e response_code_ANNOT /* |int|: for responses only */
@e save_self_ANNOT /* |int|: this invocation must save and preserve |self| at run-time */
@e self_object_ANNOT /* |int|: this represents |self| at run-time */
@e tense_marker_ANNOT /* |grammatical_usage|: for specification nodes */
@e text_unescaped_ANNOT /* |int|: flag used only for literal texts */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(constant_activity, activity)
DECLARE_ANNOTATION_FUNCTIONS(constant_binary_predicate, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(constant_constant_phrase, constant_phrase)
DECLARE_ANNOTATION_FUNCTIONS(constant_equation, equation)
DECLARE_ANNOTATION_FUNCTIONS(constant_instance, instance)
DECLARE_ANNOTATION_FUNCTIONS(constant_local_variable, local_variable)
DECLARE_ANNOTATION_FUNCTIONS(constant_named_rulebook_outcome, named_rulebook_outcome)
DECLARE_ANNOTATION_FUNCTIONS(constant_nonlocal_variable, nonlocal_variable)
DECLARE_ANNOTATION_FUNCTIONS(constant_property, property)
DECLARE_ANNOTATION_FUNCTIONS(constant_rule, rule)
DECLARE_ANNOTATION_FUNCTIONS(constant_rulebook, rulebook)
DECLARE_ANNOTATION_FUNCTIONS(constant_table_column, table_column)
DECLARE_ANNOTATION_FUNCTIONS(constant_table, table)
DECLARE_ANNOTATION_FUNCTIONS(constant_text, text_stream)
DECLARE_ANNOTATION_FUNCTIONS(constant_use_option, use_option)
DECLARE_ANNOTATION_FUNCTIONS(constant_verb_form, verb_form)

DECLARE_ANNOTATION_FUNCTIONS(condition_tense, time_period)
DECLARE_ANNOTATION_FUNCTIONS(explicit_iname, inter_name)
DECLARE_ANNOTATION_FUNCTIONS(kind_of_value, kind)
DECLARE_ANNOTATION_FUNCTIONS(proposition, pcalc_prop)
DECLARE_ANNOTATION_FUNCTIONS(tense_marker, grammatical_usage)

@ For tedious code-sequencing reasons, the annotation functions for
|explicit_iname_ANNOT| are made in //building: Building Module//.

=
MAKE_ANNOTATION_FUNCTIONS(constant_activity, activity)
MAKE_ANNOTATION_FUNCTIONS(constant_binary_predicate, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(constant_constant_phrase, constant_phrase)
MAKE_ANNOTATION_FUNCTIONS(constant_equation, equation)
MAKE_ANNOTATION_FUNCTIONS(constant_instance, instance)
MAKE_ANNOTATION_FUNCTIONS(constant_local_variable, local_variable)
MAKE_ANNOTATION_FUNCTIONS(constant_named_rulebook_outcome, named_rulebook_outcome)
MAKE_ANNOTATION_FUNCTIONS(constant_nonlocal_variable, nonlocal_variable)
MAKE_ANNOTATION_FUNCTIONS(constant_property, property)
MAKE_ANNOTATION_FUNCTIONS(constant_rule, rule)
MAKE_ANNOTATION_FUNCTIONS(constant_rulebook, rulebook)
MAKE_ANNOTATION_FUNCTIONS(constant_table_column, table_column)
MAKE_ANNOTATION_FUNCTIONS(constant_table, table)
MAKE_ANNOTATION_FUNCTIONS(constant_text, text_stream)
MAKE_ANNOTATION_FUNCTIONS(constant_use_option, use_option)
MAKE_ANNOTATION_FUNCTIONS(constant_verb_form, verb_form)

MAKE_ANNOTATION_FUNCTIONS(condition_tense, time_period)
MAKE_ANNOTATION_FUNCTIONS(kind_of_value, kind)
MAKE_ANNOTATION_FUNCTIONS(proposition, pcalc_prop)
MAKE_ANNOTATION_FUNCTIONS(tense_marker, grammatical_usage)

@

=
void CoreSyntax::declare_spec_annotations(void) {
	Annotations::declare_type(
		constant_activity_ANNOT, CoreSyntax::write_constant_activity_ANNOT);
	Annotations::declare_type(
		constant_binary_predicate_ANNOT, CoreSyntax::write_constant_binary_predicate_ANNOT);
	Annotations::declare_type(
		constant_constant_phrase_ANNOT, CoreSyntax::write_constant_constant_phrase_ANNOT);
	Annotations::declare_type(
		constant_equation_ANNOT, CoreSyntax::write_constant_equation_ANNOT);
	Annotations::declare_type(
		constant_instance_ANNOT, CoreSyntax::write_constant_instance_ANNOT);
	Annotations::declare_type(
		constant_local_variable_ANNOT, CoreSyntax::write_constant_local_variable_ANNOT);
	Annotations::declare_type(
		constant_named_rulebook_outcome_ANNOT, CoreSyntax::write_constant_named_rulebook_outcome_ANNOT);
	Annotations::declare_type(
		constant_nonlocal_variable_ANNOT, CoreSyntax::write_constant_nonlocal_variable_ANNOT);
	Annotations::declare_type(
		constant_property_ANNOT, CoreSyntax::write_constant_property_ANNOT);
	Annotations::declare_type(
		constant_rule_ANNOT, CoreSyntax::write_constant_rule_ANNOT);
	Annotations::declare_type(
		constant_rulebook_ANNOT, CoreSyntax::write_constant_rulebook_ANNOT);
	Annotations::declare_type(
		constant_table_ANNOT, CoreSyntax::write_constant_table_ANNOT);
	Annotations::declare_type(
		constant_table_column_ANNOT, CoreSyntax::write_constant_table_column_ANNOT);
	Annotations::declare_type(
		constant_text_ANNOT, CoreSyntax::write_constant_text_ANNOT);
	Annotations::declare_type(
		constant_use_option_ANNOT, CoreSyntax::write_constant_use_option_ANNOT);
	Annotations::declare_type(
		constant_verb_form_ANNOT, CoreSyntax::write_constant_verb_form_ANNOT);
	Annotations::declare_type(
		condition_tense_ANNOT, CoreSyntax::write_condition_tense_ANNOT);
	Annotations::declare_type(
		constant_enumeration_ANNOT, CoreSyntax::write_constant_enumeration_ANNOT);
	Annotations::declare_type(
		constant_number_ANNOT, CoreSyntax::write_constant_number_ANNOT);
	Annotations::declare_type(
		converted_SN_ANNOT, CoreSyntax::write_converted_SN_ANNOT);
	Annotations::declare_type(
		explicit_iname_ANNOT, CoreSyntax::write_explicit_iname_ANNOT);
	Annotations::declare_type(
		explicit_literal_ANNOT, CoreSyntax::write_explicit_literal_ANNOT);
	Annotations::declare_type(
		grammar_token_code_ANNOT, CoreSyntax::write_grammar_token_code_ANNOT);
	Annotations::declare_type(
		is_phrase_option_ANNOT, CoreSyntax::write_is_phrase_option_ANNOT);
	Annotations::declare_type(
		kind_of_value_ANNOT, CoreSyntax::write_kind_of_value_ANNOT);
	Annotations::declare_type(
		nothing_object_ANNOT, CoreSyntax::write_nothing_object_ANNOT);
	Annotations::declare_type(
		phrase_option_ANNOT, CoreSyntax::write_phrase_option_ANNOT);
	Annotations::declare_type(
		property_name_used_as_noun_ANNOT, CoreSyntax::write_property_name_used_as_noun_ANNOT);
	Annotations::declare_type(
		proposition_ANNOT, CoreSyntax::write_proposition_ANNOT);
	Annotations::declare_type(
		record_as_self_ANNOT, CoreSyntax::write_record_as_self_ANNOT);
	Annotations::declare_type(
		response_code_ANNOT, CoreSyntax::write_response_code_ANNOT);
	Annotations::declare_type(
		save_self_ANNOT, CoreSyntax::write_save_self_ANNOT);
	Annotations::declare_type(
		self_object_ANNOT, CoreSyntax::write_self_object_ANNOT);
	Annotations::declare_type(
		tense_marker_ANNOT, CoreSyntax::write_tense_marker_ANNOT);
	Annotations::declare_type(
		text_unescaped_ANNOT, CoreSyntax::write_text_unescaped_ANNOT);
}
void CoreSyntax::write_constant_activity_ANNOT(text_stream *OUT, parse_node *p) {
	activity *act = Node::get_constant_activity(p);
	if (act) WRITE(" {activity: %W}", act->name);
}
void CoreSyntax::write_constant_binary_predicate_ANNOT(text_stream *OUT, parse_node *p) {
	binary_predicate *bp = Node::get_grammar_token_relation(p);
	if (bp) WRITE(" {binary_predicate: %S}", bp->debugging_log_name);
}
void CoreSyntax::write_constant_constant_phrase_ANNOT(text_stream *OUT, parse_node *p) {
	constant_phrase *cphr = Node::get_constant_constant_phrase(p);
	if (cphr) {
		WRITE(" {constant phrase:");
		Nouns::write(OUT, cphr->name);
		WRITE("}");
	}
}
void CoreSyntax::write_constant_equation_ANNOT(text_stream *OUT, parse_node *p) {
	equation *eqn = Node::get_constant_equation(p);
	if (eqn) WRITE(" {equation: %W}", eqn->equation_text);
}
void CoreSyntax::write_constant_instance_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_instance(p)) {
		WRITE(" {instance: ");
		Instances::write(OUT, Node::get_constant_instance(p));
		WRITE("}");
	}
}
void CoreSyntax::write_constant_local_variable_ANNOT(text_stream *OUT, parse_node *p) {
	local_variable *lvar = Node::get_constant_local_variable(p);
	if (lvar) {
		WRITE(" {local: ");
		LocalVariables::write(OUT, lvar);
		WRITE(" ");
		Kinds::Textual::write(OUT, LocalVariables::unproblematic_kind(lvar));
		WRITE("}");
	}
}
void CoreSyntax::write_constant_named_rulebook_outcome_ANNOT(text_stream *OUT, parse_node *p) {
	named_rulebook_outcome *nro = Node::get_constant_named_rulebook_outcome(p);
	if (nro) {
		WRITE(" {named rulebook outcome: ");
		Nouns::write(OUT, nro->name);
		WRITE("}");
	}
}
void CoreSyntax::write_constant_nonlocal_variable_ANNOT(text_stream *OUT, parse_node *p) {
	nonlocal_variable *q = Node::get_constant_nonlocal_variable(p);
	if (q) {
		WRITE(" {nonlocal: ");
		NonlocalVariables::write(OUT, q);
		WRITE("}");
	}
}
void CoreSyntax::write_constant_property_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_property(p))
		WRITE(" {property: $Y}", Node::get_constant_property(p));
}
void CoreSyntax::write_constant_rule_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_rule(p))
		WRITE(" {rule: %W}", Node::get_constant_rule(p)->name);
}
void CoreSyntax::write_constant_rulebook_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_rulebook(p))
		WRITE(" {rulebook: %W}", Node::get_constant_rulebook(p)->primary_name);
}
void CoreSyntax::write_constant_table_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_table(p))
		WRITE(" {table: %n}", Node::get_constant_table(p)->table_identifier);
}
void CoreSyntax::write_constant_table_column_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_table_column(p)) {
		WRITE(" {table column: ");
		Nouns::write(OUT, Node::get_constant_table_column(p)->name);
		WRITE("}");
	}
}
void CoreSyntax::write_constant_text_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_text(p))
		WRITE(" {text: '%S'}", Node::get_constant_text(p));
}
void CoreSyntax::write_constant_use_option_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_use_option(p))
		WRITE(" {use option: %W}", Node::get_constant_use_option(p)->name);
}
void CoreSyntax::write_constant_verb_form_ANNOT(text_stream *OUT, parse_node *p) {
	verb_form *vf = Node::get_constant_verb_form(p);
	if (vf) {
		WRITE(" {verb form: ");
		Verbs::log_form(vf);
		WRITE("}");
	}
}
void CoreSyntax::write_condition_tense_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_condition_tense(p)) {
		WRITE(" {condition tense: ");
		Occurrence::log(OUT, Node::get_condition_tense(p));
		WRITE("}");
	}
}
void CoreSyntax::write_constant_enumeration_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {enumeration: %d}", Annotations::read_int(p, constant_enumeration_ANNOT));
}
void CoreSyntax::write_constant_number_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {number: %d}", Annotations::read_int(p, constant_number_ANNOT));
}
void CoreSyntax::write_converted_SN_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, converted_SN_ANNOT))
		WRITE(" {converted SN}");
}
void CoreSyntax::write_explicit_iname_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {explicit iname: %n}", Node::get_explicit_iname(p));
}
void CoreSyntax::write_explicit_literal_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, explicit_literal_ANNOT))
		WRITE(" {explicit literal}");
}
void CoreSyntax::write_grammar_token_code_ANNOT(text_stream *OUT, parse_node *p) {
	int gtc = Annotations::read_int(p, grammar_token_code_ANNOT);
	if (gtc != 0) {
		WRITE(" {grammar_token_code: ");
		if (gtc == NAMED_TOKEN_GTC) WRITE("named token");
		if (gtc == RELATED_GTC) WRITE("related");
		if (gtc == STUFF_GTC) WRITE("stuff");
		if (gtc == ANY_STUFF_GTC) WRITE("any stuff");
		if (gtc == ANY_THINGS_GTC) WRITE("any things");
		if (gtc == NOUN_TOKEN_GTC) WRITE("noun");
		if (gtc == MULTI_TOKEN_GTC) WRITE("multi");
		if (gtc == MULTIINSIDE_TOKEN_GTC) WRITE("multiinside");
		if (gtc == MULTIHELD_TOKEN_GTC) WRITE("multiheld");
		if (gtc == HELD_TOKEN_GTC) WRITE("held");
		if (gtc == CREATURE_TOKEN_GTC) WRITE("creature");
		if (gtc == TOPIC_TOKEN_GTC) WRITE("topic");
		if (gtc == MULTIEXCEPT_TOKEN_GTC) WRITE("multiexcept");
		WRITE("}");
	}
}
void CoreSyntax::write_is_phrase_option_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, is_phrase_option_ANNOT))
		WRITE(" {is phrase option}");
}
void CoreSyntax::write_kind_of_value_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_kind_of_value(p))
		WRITE(" {kind: %u}", Node::get_kind_of_value(p));
}
void CoreSyntax::write_nothing_object_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, nothing_object_ANNOT))
		WRITE(" {nothing}");
}
void CoreSyntax::write_phrase_option_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, phrase_option_ANNOT))
		WRITE(" {phrase option: %08x}", Annotations::read_int(p, phrase_option_ANNOT));
}
void CoreSyntax::write_property_name_used_as_noun_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, property_name_used_as_noun_ANNOT))
		WRITE(" {property name used as noun}");
}
void CoreSyntax::write_proposition_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_proposition(p)) {
		WRITE(" {proposition: ");
		Propositions::write(OUT, Node::get_proposition(p));
		WRITE("}");
	}
}
void CoreSyntax::write_record_as_self_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, record_as_self_ANNOT))
		WRITE(" {record as self}");
}
void CoreSyntax::write_response_code_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {response code: %c}", 'A' + Annotations::read_int(p, response_code_ANNOT));
}
void CoreSyntax::write_save_self_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, save_self_ANNOT))
		WRITE(" {save self}");
}
void CoreSyntax::write_self_object_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, self_object_ANNOT))
		WRITE(" {self}");
}
void CoreSyntax::write_tense_marker_ANNOT(text_stream *OUT, parse_node *p) {
	grammatical_usage *gu = Node::get_tense_marker(p);
	if (gu) {
		WRITE(" {tense marker: ");
		Stock::write_usage(OUT, gu,
			SENSE_LCW+VOICE_LCW+TENSE_LCW+PERSON_LCW+NUMBER_LCW);
		WRITE("}");
	}
}
void CoreSyntax::write_text_unescaped_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, text_unescaped_ANNOT))
		WRITE(" {text unescaped}");
}

void CoreSyntax::grant_spec_permissions(void) {
	CoreSyntax::allow_annotation_to_specification(meaning_ANNOT);
	CoreSyntax::allow_annotation_to_specification(converted_SN_ANNOT);
	CoreSyntax::allow_annotation_to_specification(subject_term_ANNOT);
	CoreSyntax::allow_annotation_to_specification(epistemological_status_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_activity_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_binary_predicate_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_constant_phrase_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_enumeration_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_equation_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_instance_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_named_rulebook_outcome_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_number_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_property_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_rule_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_rulebook_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_table_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_table_column_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_text_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_use_option_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_verb_form_ANNOT);
	Annotations::allow(CONSTANT_NT, explicit_literal_ANNOT);
	Annotations::allow(CONSTANT_NT, grammar_token_code_ANNOT);
	Annotations::allow(CONSTANT_NT, kind_of_value_ANNOT);
	Annotations::allow(CONSTANT_NT, nothing_object_ANNOT);
	Annotations::allow(CONSTANT_NT, property_name_used_as_noun_ANNOT);
	Annotations::allow(CONSTANT_NT, proposition_ANNOT);
	Annotations::allow(CONSTANT_NT, response_code_ANNOT);
	Annotations::allow(CONSTANT_NT, self_object_ANNOT);
	Annotations::allow(CONSTANT_NT, text_unescaped_ANNOT);
	Annotations::allow(LOCAL_VARIABLE_NT, constant_local_variable_ANNOT);
	Annotations::allow(LOCAL_VARIABLE_NT, kind_of_value_ANNOT);
	Annotations::allow(LOGICAL_TENSE_NT, condition_tense_ANNOT);
	Annotations::allow(LOGICAL_TENSE_NT, tense_marker_ANNOT);
	Annotations::allow(NONLOCAL_VARIABLE_NT, constant_nonlocal_variable_ANNOT);
	Annotations::allow(NONLOCAL_VARIABLE_NT, kind_of_value_ANNOT);
	Annotations::allow(PROPERTY_VALUE_NT, record_as_self_ANNOT);
	Annotations::allow(TEST_PHRASE_OPTION_NT, phrase_option_ANNOT);
	Annotations::allow(TEST_PROPOSITION_NT, proposition_ANNOT);
	Annotations::allow(UNKNOWN_NT, preposition_ANNOT);
	Annotations::allow(UNKNOWN_NT, verb_ANNOT);
}

void CoreSyntax::allow_annotation_to_specification(int annot) {
	Annotations::allow(UNKNOWN_NT, annot);
	Annotations::allow_for_category(LVALUE_NCAT, annot);
	Annotations::allow_for_category(RVALUE_NCAT, annot);
	Annotations::allow_for_category(COND_NCAT, annot);
}

@h Copying annotations.
Propositions need to be deep-copied:

@d ANNOTATION_COPY_SYNTAX_CALLBACK CoreSyntax::copy_annotations

=
void CoreSyntax::copy_annotations(parse_node_annotation *to, parse_node_annotation *from) {
	if (from->annotation_id == proposition_ANNOT)
		to->annotation_pointer =
			STORE_POINTER_pcalc_prop(
				Propositions::copy(
					RETRIEVE_POINTER_pcalc_prop(
						from->annotation_pointer)));
}
