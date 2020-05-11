[ParseTreeUsage::] Parse Tree Usage.

Shims for the parse tree.

@h Definitions.

@

@d ANNOTATION_COPY_SYNTAX_CALLBACK ParseTreeUsage::copy_annotations

=
void ParseTreeUsage::copy_annotations(parse_node_annotation *to, parse_node_annotation *from) {
	if (from->annotation_id == proposition_ANNOT)
		to->annotation_pointer =
			STORE_POINTER_pcalc_prop(
				Calculus::Propositions::copy(
					RETRIEVE_POINTER_pcalc_prop(
						from->annotation_pointer)));
}

@

@e ALLOWED_NT           			/* "An animal is allowed to have a description" */
@e EVERY_NT             			/* "every container" */
@e COMMON_NOUN_NT       			/* "a container" */
@e ACTION_NT            			/* "taking something closed" */
@e ADJECTIVE_NT         			/* "open" */
@e PROPERTYCALLED_NT    			/* "A man has a number called age" */
@e X_OF_Y_NT            			/* "description of the painting" */
@e CREATED_NT           			/* "a vehicle called Sarah Jane's car" */

@e TOKEN_NT             			/* Used for tokens in grammar */

@e CODE_BLOCK_NT       			/* Holds a block of source material */
@e INVOCATION_LIST_SAY_NT		/* Single thing to be said */
@e INVOCATION_NT      			/* Usage of a phrase */
@e VOID_CONTEXT_NT  				/* When a void phrase is required */
@e RVALUE_CONTEXT_NT  			/* Arguments, in effect */
@e LVALUE_CONTEXT_NT 			/* Named storage location */
@e LVALUE_TR_CONTEXT_NT 			/* Table reference */
@e SPECIFIC_RVALUE_CONTEXT_NT 	/* Argument must be an exact value */
@e MATCHING_RVALUE_CONTEXT_NT 	/* Argument must match a description */
@e NEW_LOCAL_CONTEXT_NT			/* Argument which creates a local */
@e LVALUE_LOCAL_CONTEXT_NT		/* Argument which names a local */
@e CONDITION_CONTEXT_NT          /* Used for "now" conditions */

@ The next specification nodes are the rvalues. These express I6 values --
numbers, objects, text and so on -- but cannot be assigned to, so that in an
assignment of the form "change L to R" they can be used only as R, not L. This
is not the same thing as a constant: for instance, "location of the player"
evaluates differently at different times, but cannot be changed in an
assignment.

@e CONSTANT_NT					/* "7", "the can't lock a locked door rule", etc. */
@e PHRASE_TO_DECIDE_VALUE_NT		/* "holder of the black box" */

@ Lvalue nodes represent stored I6 data at run-time, which means that they can
be assigned to. (The traditional terms "lvalue" and "rvalue" refer to the left
and right hand side of assignment statements written |A = B|.) For instance, a
table entry qualifies as an lvalue because it can be both read and changed. To
qualify as an lvalue, text must exactly specify the storage location referred
to: "Table of Corvettes" only indicates a table, not an entry in a table, so
is merely an rvalue. Similarly, "carrying capacity" (as a property name not
indicating an owner) is a mere rvalue.

@e LOCAL_VARIABLE_NT				/* "the running total", say */
@e NONLOCAL_VARIABLE_NT			/* "the location" */
@e PROPERTY_VALUE_NT				/* "the carrying capacity of the cedarwood box" */
@e TABLE_ENTRY_NT				/* "tonnage in row X of the Table of Corvettes" */
@e LIST_ENTRY_NT					/* "item 4 in L" */

@ Condition nodes represent atomic conditions, and also Boolean operations on
them. It's convenient to represent these operations as nodes in their own right
rather than as (for example) phrases: this reduces parsing ambiguities, but
also makes it easier for us to manipulate the results.

@e LOGICAL_NOT_NT				/* "not A" */
@e LOGICAL_TENSE_NT				/* in the past, A */
@e LOGICAL_AND_NT				/* "A and B" */
@e LOGICAL_OR_NT					/* "A or B" */
@e TEST_PROPOSITION_NT			/* if "the cat is on the mat" */
@e TEST_PHRASE_OPTION_NT			/* "giving full details", say */
@e TEST_VALUE_NT					/* when a value is used as a condition */

@

@e LVALUE_NCAT
@e RVALUE_NCAT
@e COND_NCAT

@d PHRASAL_NFLAG        	0x00000004 /* compiles to a function call */

@

@d MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK ParseTreeUsage::md

=
void ParseTreeUsage::md(void) {
    /* first, the structural nodes: */
	NodeType::new(ALLOWED_NT, I"ALLOWED_NT",				   				1, 1,		L3_NCAT, ASSERT_NFLAG);
	NodeType::new(EVERY_NT, I"EVERY_NT", 				   					0, INFTY,	L3_NCAT, ASSERT_NFLAG);
	NodeType::new(COMMON_NOUN_NT, I"COMMON_NOUN_NT",		   				0, INFTY,	L3_NCAT, ASSERT_NFLAG);
	NodeType::new(ACTION_NT, I"ACTION_NT",				   					0, INFTY,	L3_NCAT, ASSERT_NFLAG);
	NodeType::new(ADJECTIVE_NT, I"ADJECTIVE_NT",			   				0, INFTY,	L3_NCAT, ASSERT_NFLAG);
	NodeType::new(PROPERTYCALLED_NT, I"PROPERTYCALLED_NT",  				2, 2,		L3_NCAT, 0);
	NodeType::new(TOKEN_NT, I"TOKEN_NT",					   				0, INFTY,	L3_NCAT, 0);
	NodeType::new(X_OF_Y_NT, I"X_OF_Y_NT",				   					2, 2,		L3_NCAT, ASSERT_NFLAG);
	NodeType::new(CREATED_NT, I"CREATED_NT",				  				0, 0,		L3_NCAT, ASSERT_NFLAG);

	NodeType::new(CODE_BLOCK_NT, I"CODE_BLOCK_NT",	       					0, INFTY,	L4_NCAT, 0);
	NodeType::new(INVOCATION_LIST_NT, I"INVOCATION_LIST_NT",		   		0, INFTY,	L4_NCAT, 0);
	NodeType::new(INVOCATION_LIST_SAY_NT, I"INVOCATION_LIST_SAY_NT",		0, INFTY,	L4_NCAT, 0);
	NodeType::new(INVOCATION_NT, I"INVOCATION_NT",		   					0, INFTY,	L4_NCAT, 0);
	NodeType::new(VOID_CONTEXT_NT, I"VOID_CONTEXT_NT", 						0, INFTY,	L4_NCAT, 0);
	NodeType::new(RVALUE_CONTEXT_NT, I"RVALUE_CONTEXT_NT", 					0, INFTY,	L4_NCAT, 0);
	NodeType::new(LVALUE_CONTEXT_NT, I"LVALUE_CONTEXT_NT", 					0, INFTY,	L4_NCAT, 0);
	NodeType::new(LVALUE_TR_CONTEXT_NT, I"LVALUE_TR_CONTEXT_NT", 			0, INFTY,	L4_NCAT, 0);
	NodeType::new(SPECIFIC_RVALUE_CONTEXT_NT, I"SPECIFIC_RVALUE_CONTEXT_NT",	0, INFTY,	L4_NCAT, 0);
	NodeType::new(MATCHING_RVALUE_CONTEXT_NT, I"MATCHING_RVALUE_CONTEXT_NT",	0, INFTY,	L4_NCAT, 0);
	NodeType::new(NEW_LOCAL_CONTEXT_NT, I"NEW_LOCAL_CONTEXT_NT",			0, INFTY,	L4_NCAT, 0);
	NodeType::new(LVALUE_LOCAL_CONTEXT_NT, I"LVALUE_LOCAL_CONTEXT_NT",		0, INFTY,	L4_NCAT, 0);
	NodeType::new(CONDITION_CONTEXT_NT, I"CONDITION_CONTEXT_NT",			0, INFTY,	L4_NCAT, 0);

	/* now the specification nodes: */
	NodeType::new(CONSTANT_NT, I"CONSTANT_NT", 								0, 0,		RVALUE_NCAT, 0);
	NodeType::new(PHRASE_TO_DECIDE_VALUE_NT, I"PHRASE_TO_DECIDE_VALUE_NT",	1, 1,		RVALUE_NCAT, PHRASAL_NFLAG);

	NodeType::new(LOCAL_VARIABLE_NT, I"LOCAL_VARIABLE_NT", 					0, 0,		LVALUE_NCAT, 0);
	NodeType::new(NONLOCAL_VARIABLE_NT, I"NONLOCAL_VARIABLE_NT", 			0, 0,		LVALUE_NCAT, 0);
	NodeType::new(PROPERTY_VALUE_NT, I"PROPERTY_VALUE_NT", 					2, 2,		LVALUE_NCAT, 0);
	NodeType::new(TABLE_ENTRY_NT, I"TABLE_ENTRY_NT", 						1, 4,		LVALUE_NCAT, 0);
	NodeType::new(LIST_ENTRY_NT, I"LIST_ENTRY_NT", 							2, 2,		LVALUE_NCAT, 0);

	NodeType::new(LOGICAL_NOT_NT, I"LOGICAL_NOT_NT", 						1, 1,		COND_NCAT, 0);
	NodeType::new(LOGICAL_TENSE_NT, I"LOGICAL_TENSE_NT", 					1, 1,		COND_NCAT, 0);
	NodeType::new(LOGICAL_AND_NT, I"LOGICAL_AND_NT", 						2, 2,		COND_NCAT, 0);
	NodeType::new(LOGICAL_OR_NT, I"LOGICAL_OR_NT", 							2, 2,		COND_NCAT, 0);
	NodeType::new(TEST_PROPOSITION_NT, I"TEST_PROPOSITION_NT", 				0, 0,		COND_NCAT, 0);
	NodeType::new(TEST_PHRASE_OPTION_NT, I"TEST_PHRASE_OPTION_NT", 			0, 0, 		COND_NCAT, 0);
	NodeType::new(TEST_VALUE_NT, I"TEST_VALUE_NT", 							1, 1,		COND_NCAT, 0);
}

@

@d PARENTAGE_PERMISSIONS_SYNTAX_CALLBACK ParseTreeUsage::write_parentage_permissions

=
void ParseTreeUsage::write_parentage_permissions(void) {
	NodeType::allow_parentage_for_categories(L2_NCAT, L3_NCAT);
	NodeType::allow_parentage_for_categories(L3_NCAT, L3_NCAT);
	NodeType::allow_parentage_for_categories(L2_NCAT, L4_NCAT);
	NodeType::allow_parentage_for_categories(L4_NCAT, L4_NCAT);
	NodeType::allow_parentage_for_categories(L4_NCAT, UNKNOWN_NCAT);

	NodeType::allow_parentage_for_categories(L4_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(L4_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(L4_NCAT, COND_NCAT);

	NodeType::allow_parentage_for_categories(LVALUE_NCAT, UNKNOWN_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, UNKNOWN_NCAT);
	NodeType::allow_parentage_for_categories(COND_NCAT, UNKNOWN_NCAT);
	NodeType::allow_parentage_for_categories(LVALUE_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(COND_NCAT, LVALUE_NCAT);
	NodeType::allow_parentage_for_categories(LVALUE_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(COND_NCAT, RVALUE_NCAT);
	NodeType::allow_parentage_for_categories(LVALUE_NCAT, COND_NCAT);
	NodeType::allow_parentage_for_categories(RVALUE_NCAT, COND_NCAT);
	NodeType::allow_parentage_for_categories(COND_NCAT, COND_NCAT);
}

@

@d ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK ParseTreeUsage::write_permissions

=
void ParseTreeUsage::write_permissions(void) {
	Annotations::allow_for_category(L1_NCAT, clears_pronouns_ANNOT);
	Annotations::allow(HEADING_NT, embodying_heading_ANNOT);
	Annotations::allow(HEADING_NT, inclusion_of_extension_ANNOT);
	Annotations::allow(HEADING_NT, interpretation_of_subject_ANNOT);
	Annotations::allow(HEADING_NT, suppress_heading_dependencies_ANNOT);
	Annotations::allow(HEADING_NT, implied_heading_ANNOT);
	Annotations::allow_for_category(L1_NCAT, module_ANNOT);

	Annotations::allow_for_category(L2_NCAT, clears_pronouns_ANNOT);
	Annotations::allow_for_category(L2_NCAT, interpretation_of_subject_ANNOT);
	Annotations::allow_for_category(L2_NCAT, sentence_unparsed_ANNOT);
	Annotations::allow_for_category(L2_NCAT, verb_problem_issued_ANNOT);
	Annotations::allow(ROUTINE_NT, indentation_level_ANNOT);
	Annotations::allow(SENTENCE_NT, implicit_in_creation_of_ANNOT);
	Annotations::allow(SENTENCE_NT, implicitness_count_ANNOT);
	Annotations::allow(SENTENCE_NT, you_can_ignore_ANNOT);
	Annotations::allow_for_category(L2_NCAT, module_ANNOT);
	LOOP_OVER_ENUMERATED_NTS(t)
		if (NodeType::has_flag(t, ASSERT_NFLAG))
			Annotations::allow(t, resolved_ANNOT);

	Annotations::allow_for_category(L3_NCAT, module_ANNOT);
	Annotations::allow_for_category(L3_NCAT, creation_proposition_ANNOT);
	Annotations::allow_for_category(L3_NCAT, evaluation_ANNOT);
	Annotations::allow_for_category(L3_NCAT, subject_ANNOT);
	Annotations::allow(ACTION_NT, action_meaning_ANNOT);
	Annotations::allow(ADJECTIVE_NT, aph_ANNOT);
	Annotations::allow(ADJECTIVE_NT, negated_boolean_ANNOT);
	Annotations::allow(ADJECTIVE_NT, nounphrase_article_ANNOT);
	Annotations::allow(AVERB_NT, log_inclusion_sense_ANNOT);
	Annotations::allow(AVERB_NT, verb_id_ANNOT);
	Annotations::allow(AVERB_NT, imperative_ANNOT);
	Annotations::allow(AVERB_NT, examine_for_ofs_ANNOT);
	Annotations::allow(AVERB_NT, listing_sense_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, action_meaning_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, creation_site_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, implicitly_refers_to_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, multiplicity_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, quant_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, quantification_parameter_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, aph_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, category_of_I6_translation_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, creation_site_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, defn_language_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, log_inclusion_sense_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, lpe_options_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, multiplicity_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, negated_boolean_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, new_relation_here_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, nowhere_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, quant_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, quantification_parameter_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, row_amendable_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, slash_dash_dash_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, table_cell_unspecified_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, turned_already_ANNOT);
	Annotations::allow(PROPERTY_LIST_NT, nounphrase_article_ANNOT);
	Annotations::allow(RELATIONSHIP_NT, relationship_ANNOT);
	Annotations::allow(TOKEN_NT, grammar_token_literal_ANNOT);
	Annotations::allow(TOKEN_NT, grammar_token_relation_ANNOT);
	Annotations::allow(TOKEN_NT, grammar_value_ANNOT);
	Annotations::allow(TOKEN_NT, slash_class_ANNOT);

	Annotations::allow_for_category(L4_NCAT, colon_block_command_ANNOT);
	Annotations::allow_for_category(L4_NCAT, control_structure_used_ANNOT);
	Annotations::allow_for_category(L4_NCAT, end_control_structure_used_ANNOT);
	Annotations::allow_for_category(L4_NCAT, evaluation_ANNOT);
	Annotations::allow_for_category(L4_NCAT, indentation_level_ANNOT);
	Annotations::allow_for_category(L4_NCAT, kind_of_new_variable_ANNOT);
	Annotations::allow_for_category(L4_NCAT, kind_required_by_context_ANNOT);
	Annotations::allow_for_category(L4_NCAT, results_from_splitting_ANNOT);
	Annotations::allow_for_category(L4_NCAT, token_as_parsed_ANNOT);
	Annotations::allow_for_category(L4_NCAT, token_check_to_do_ANNOT);
	Annotations::allow_for_category(L4_NCAT, token_to_be_parsed_against_ANNOT);
	Annotations::allow_for_category(L4_NCAT, verb_problem_issued_ANNOT);
	Annotations::allow_for_category(L4_NCAT, problem_falls_under_ANNOT);
	Annotations::allow_for_category(L4_NCAT, module_ANNOT);
	Annotations::allow(CODE_BLOCK_NT, sentence_unparsed_ANNOT);
	Annotations::allow(INVOCATION_LIST_NT, from_text_substitution_ANNOT);
	Annotations::allow(INVOCATION_LIST_NT, sentence_unparsed_ANNOT);
	Annotations::allow(INVOCATION_LIST_SAY_NT, sentence_unparsed_ANNOT);
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

	ParseTreeUsage::allow_annotation_to_specification(converted_SN_ANNOT);
	ParseTreeUsage::allow_annotation_to_specification(subject_term_ANNOT);
	ParseTreeUsage::allow_annotation_to_specification(epistemological_status_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_action_name_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_action_pattern_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_activity_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_binary_predicate_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_constant_phrase_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_enumeration_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_equation_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_grammar_verb_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_instance_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_named_action_pattern_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_named_rulebook_outcome_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_number_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_property_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_rule_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_rulebook_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_scene_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_table_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_table_column_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_text_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_use_option_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_verb_form_ANNOT);
	Annotations::allow(CONSTANT_NT, explicit_literal_ANNOT);
	Annotations::allow(CONSTANT_NT, explicit_vh_ANNOT);
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
	Annotations::allow(NONLOCAL_VARIABLE_NT, constant_nonlocal_variable_ANNOT);
	Annotations::allow(NONLOCAL_VARIABLE_NT, kind_of_value_ANNOT);
	Annotations::allow(PROPERTY_VALUE_NT, record_as_self_ANNOT);
	Annotations::allow(TEST_PHRASE_OPTION_NT, phrase_option_ANNOT);
	Annotations::allow(TEST_PROPOSITION_NT, proposition_ANNOT);
	Annotations::allow(UNKNOWN_NT, prep_ANNOT);
	Annotations::allow(UNKNOWN_NT, vu_ANNOT);
}
void ParseTreeUsage::allow_annotation_to_specification(int annot) {
	Annotations::allow(UNKNOWN_NT, annot);
	Annotations::allow_for_category(LVALUE_NCAT, annot);
	Annotations::allow_for_category(RVALUE_NCAT, annot);
	Annotations::allow_for_category(COND_NCAT, annot);
}

@

@d PARENTAGE_EXCEPTIONS_SYNTAX_CALLBACK ParseTreeUsage::parentage_exceptions

=
int ParseTreeUsage::parentage_exceptions(node_type_t t_parent, int cat_parent,
	node_type_t t_child, int cat_child) {
	if ((t_parent == PHRASE_TO_DECIDE_VALUE_NT) && (t_child == INVOCATION_LIST_NT)) return TRUE;
	return FALSE;
}

@ Further classification:

@d IMMUTABLE_NODE ParseTreeUsage::immutable
@d IS_SENTENCE_NODE_SYNTAX_CALLBACK ParseTreeUsage::second_level

=
int ParseTreeUsage::second_level(node_type_t t) {
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if ((metadata) && (metadata->category == L2_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::immutable(node_type_t t) {
	if (ParseTreeUsage::is_specification_node_type(t)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_specification_node_type(node_type_t t) {
	if (t == UNKNOWN_NT) return TRUE;
	node_type_metadata *metadata = NodeType::get_metadata(t);
	if ((metadata) &&
		((metadata->category == RVALUE_NCAT) ||
		(metadata->category == LVALUE_NCAT) ||
		(metadata->category == COND_NCAT))) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_lvalue(parse_node *pn) {
	node_type_metadata *metadata = NodeType::get_metadata(Node::get_type(pn));
	if ((metadata) && (metadata->category == LVALUE_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_rvalue(parse_node *pn) {
	node_type_metadata *metadata = NodeType::get_metadata(Node::get_type(pn));
	if ((metadata) && (metadata->category == RVALUE_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_value(parse_node *pn) {
	node_type_metadata *metadata = NodeType::get_metadata(Node::get_type(pn));
	if ((metadata) &&
		((metadata->category == LVALUE_NCAT) || (metadata->category == RVALUE_NCAT)))
		return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_condition(parse_node *pn) {
	node_type_metadata *metadata = NodeType::get_metadata(Node::get_type(pn));
	if ((metadata) && (metadata->category == COND_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_phrasal(parse_node *pn) {
	if (NodeType::has_flag(Node::get_type(pn), PHRASAL_NFLAG)) return TRUE;
	return FALSE;
}

@h The assertion-maker's invariant.
Hmm: "The Assertion-Maker's Invariant" might make a good magic-realism
novel, in which an enigmatic wise man of Samarkand builds an ingenious box
from camphor-wood in which he traps the dreams of the people, who -- However.
When assertions are processed, the subtrees being compared will be required to
be such that their head nodes each pass this test:

=
int ParseTreeUsage::allow_in_assertions(parse_node *p) {
	VerifyTree::verify_structure_from(p);
	if (NodeType::has_flag(Node::get_type(p), ASSERT_NFLAG)) return TRUE;
	return FALSE;
}

@

@d PARSE_TREE_LOGGER ParseTreeUsage::log_node

=
void ParseTreeUsage::log_node(OUTPUT_STREAM, parse_node *pn) {
	if (Node::get_meaning(pn)) WRITE("$M", Node::get_meaning(pn));
	else WRITE("$N", pn->node_type);
	if (Wordings::nonempty(Node::get_text(pn))) WRITE("'%W'", Node::get_text(pn));

	if ((pn->node_type >= UNKNOWN_NT) && (pn->node_type <= TEST_VALUE_NT))
		@<Log annotations of specification nodes@>
	else
		@<Log annotations of structural nodes@>;
}

@<Log annotations of specification nodes@> =
	if (Node::get_kind_of_value(pn)) WRITE("-$u", Node::get_kind_of_value(pn));
	if (ParseTreeUsage::is_lvalue(pn)) Lvalues::log(pn);
	else if (ParseTreeUsage::is_rvalue(pn)) Rvalues::log(pn);
	else if (ParseTreeUsage::is_condition(pn)) Conditions::log(pn);
	if (Node::get_vu(pn)) { WRITE("-vu:"); NewVerbs::log(Node::get_vu(pn)); }
	if (Node::get_prep(pn)) { WRITE("-prep:$p", Node::get_prep(pn)); }

@ We do not log every annotation: only the few which are most illuminating.

@<Log annotations of structural nodes@> =
	int show_eval = FALSE, show_refers = FALSE;
	if (Annotations::read_int(pn, creation_site_ANNOT))
		WRITE(" (created here)");
	switch(pn->node_type) {
		case ADJECTIVE_NT: show_eval = TRUE; break;
		case HEADING_NT: WRITE(" (level %d)", Annotations::read_int(pn, heading_level_ANNOT)); break;
		case COMMON_NOUN_NT: show_refers = TRUE; break;
		case KIND_NT: show_refers = TRUE; break;
		case RELATIONSHIP_NT:
			Diagrams::log_node(OUT, pn);
			break;
		case PROPER_NOUN_NT:
			Diagrams::log_node(OUT, pn);
			if (Annotations::read_int(pn, multiplicity_ANNOT))
				WRITE(" (x%d)", Annotations::read_int(pn, multiplicity_ANNOT));
			show_refers = TRUE;
			break;
		case AVERB_NT:
			WRITE(" ($V)", Annotations::read_int(pn, verb_id_ANNOT));
			Diagrams::log_node(OUT, pn);
			break;
		case TOKEN_NT: WRITE(" [%d/%d]", Annotations::read_int(pn, slash_class_ANNOT),
			Annotations::read_int(pn, slash_dash_dash_ANNOT)); break;
		case INVOCATION_LIST_NT:
		case CODE_BLOCK_NT: {
			control_structure_phrase *csp = Node::get_control_structure_used(pn);
			WRITE("  "); ControlStructures::log(csp); WRITE(" ");
			if (pn->node_type == INVOCATION_LIST_NT)
				WRITE("%d", Annotations::read_int(pn, indentation_level_ANNOT));
			else WRITE(" ");
			WRITE("  ");
			break;
		}
	}
	if (Node::get_kind_required_by_context(pn))
		WRITE(" requires:$u", Node::get_kind_required_by_context(pn));

	if (show_refers) {
		if (Node::get_subject(pn)) { WRITE(" refers:$j", Node::get_subject(pn)); }
		if (Node::get_evaluation(pn)) { WRITE(" eval:$P", Node::get_evaluation(pn)); }
		if (Annotations::read_int(pn, implicitly_refers_to_ANNOT)) WRITE(" (implicit)");
	}
	if ((show_eval) && (Node::get_evaluation(pn))) {
		WRITE(" eval:$P", Node::get_evaluation(pn));
	}
	if (Node::get_defn_language(pn))
		WRITE(" language:%J", Node::get_defn_language(pn));
	if (Node::get_creation_proposition(pn))
		WRITE(" (creation $D)", Node::get_creation_proposition(pn));

@ =
void ParseTreeUsage::verify(void) {
	VerifyTree::verify_integrity(Task::syntax_tree());
	VerifyTree::verify_structure(Task::syntax_tree());
}

@

@d PARSE_TREE_TRAVERSE_TYPE instance

