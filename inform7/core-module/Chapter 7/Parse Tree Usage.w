[ParseTreeUsage::] Parse Tree Usage.

Shims for the parse tree.

@h Definitions.

@ Access routines will be needed for some of these, and the following
constructs them:

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(aph, adjectival_phrase)
DECLARE_ANNOTATION_FUNCTIONS(condition_tense, time_period)
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
DECLARE_ANNOTATION_FUNCTIONS(control_structure_used, control_structure_phrase)
DECLARE_ANNOTATION_FUNCTIONS(creation_proposition, pcalc_prop)
DECLARE_ANNOTATION_FUNCTIONS(defn_language, inform_language)
DECLARE_ANNOTATION_FUNCTIONS(end_control_structure_used, control_structure_phrase)
DECLARE_ANNOTATION_FUNCTIONS(evaluation, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(explicit_vh, value_holster)
DECLARE_ANNOTATION_FUNCTIONS(grammar_token_relation, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(grammar_value, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(implicit_in_creation_of, inference_subject)
DECLARE_ANNOTATION_FUNCTIONS(interpretation_of_subject, inference_subject)
DECLARE_ANNOTATION_FUNCTIONS(kind_of_new_variable, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_of_value, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_required_by_context, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_resulting, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_variable_declarations, kind_variable_declaration)
DECLARE_ANNOTATION_FUNCTIONS(explicit_iname, inter_name)
DECLARE_ANNOTATION_FUNCTIONS(modal_verb, verb_conjugation)
DECLARE_ANNOTATION_FUNCTIONS(module, compilation_module)
DECLARE_ANNOTATION_FUNCTIONS(new_relation_here, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(phrase_invoked, phrase)
DECLARE_ANNOTATION_FUNCTIONS(phrase_options_invoked, invocation_options)
DECLARE_ANNOTATION_FUNCTIONS(proposition, pcalc_prop)
DECLARE_ANNOTATION_FUNCTIONS(prep, preposition_identity)
DECLARE_ANNOTATION_FUNCTIONS(quant, quantifier)
DECLARE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(say_adjective, adjectival_phrase)
DECLARE_ANNOTATION_FUNCTIONS(say_verb, verb_conjugation)
DECLARE_ANNOTATION_FUNCTIONS(subject_term, pcalc_term)
DECLARE_ANNOTATION_FUNCTIONS(subject, inference_subject)
DECLARE_ANNOTATION_FUNCTIONS(token_as_parsed, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(token_check_to_do, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(token_to_be_parsed_against, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(vu, verb_usage)

@ So we itemise the pointer-valued annotations below, and the macro expands
to provide their get and set functions:

=
MAKE_ANNOTATION_FUNCTIONS(aph, adjectival_phrase)
MAKE_ANNOTATION_FUNCTIONS(condition_tense, time_period)
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
MAKE_ANNOTATION_FUNCTIONS(control_structure_used, control_structure_phrase)
MAKE_ANNOTATION_FUNCTIONS(creation_proposition, pcalc_prop)
MAKE_ANNOTATION_FUNCTIONS(defn_language, inform_language)
MAKE_ANNOTATION_FUNCTIONS(end_control_structure_used, control_structure_phrase)
MAKE_ANNOTATION_FUNCTIONS(evaluation, parse_node)
MAKE_ANNOTATION_FUNCTIONS(explicit_vh, value_holster)
MAKE_ANNOTATION_FUNCTIONS(grammar_token_relation, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(grammar_value, parse_node)
MAKE_ANNOTATION_FUNCTIONS(implicit_in_creation_of, inference_subject)
MAKE_ANNOTATION_FUNCTIONS(interpretation_of_subject, inference_subject)
MAKE_ANNOTATION_FUNCTIONS(kind_of_new_variable, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_of_value, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_required_by_context, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_resulting, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_variable_declarations, kind_variable_declaration)
// see codegen module for (explicit_iname, inter_name)
MAKE_ANNOTATION_FUNCTIONS(modal_verb, verb_conjugation)
// see codegen module for (module, compilation_module)
MAKE_ANNOTATION_FUNCTIONS(new_relation_here, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(phrase_invoked, phrase)
MAKE_ANNOTATION_FUNCTIONS(phrase_options_invoked, invocation_options)
MAKE_ANNOTATION_FUNCTIONS(proposition, pcalc_prop)
MAKE_ANNOTATION_FUNCTIONS(prep, preposition_identity)
MAKE_ANNOTATION_FUNCTIONS(quant, quantifier)
MAKE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(say_adjective, adjectival_phrase)
MAKE_ANNOTATION_FUNCTIONS(say_verb, verb_conjugation)
MAKE_ANNOTATION_FUNCTIONS(subject_term, pcalc_term)
MAKE_ANNOTATION_FUNCTIONS(subject, inference_subject)
MAKE_ANNOTATION_FUNCTIONS(token_as_parsed, parse_node)
MAKE_ANNOTATION_FUNCTIONS(token_check_to_do, parse_node)
MAKE_ANNOTATION_FUNCTIONS(token_to_be_parsed_against, parse_node)
MAKE_ANNOTATION_FUNCTIONS(vu, verb_usage)

@

@d PARSE_TREE_COPIER ParseTreeUsage::copy_annotations

=
void ParseTreeUsage::copy_annotations(parse_node_annotation *to, parse_node_annotation *from) {
	if (from->kind_of_annotation == proposition_ANNOT)
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

@ Next we enumerate the specification node types, beginning with the one which
signifies that text has no known meaning -- either because we tried to make
sense of it and failed, or because we are choosing not to parse it until
later on, and are representing it as unknown until then.

@e UNKNOWN_NT					/* "arfle barfle gloop" */

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

@ This is a little like itemising the baubles on a Christmas tree, but here
goes. The annotations used are identified by nonzero ID numbers, as follows:

@e action_meaning_ANNOT /* |action_pattern|: meaning in parse tree when used as noun */
@e aph_ANNOT /* |adjectival_phrase|: which adjective is asserted */
@e category_of_I6_translation_ANNOT /* int: what sort of "translates into I6" sentence this is */
@e clears_pronouns_ANNOT /* |int|: this sentence erases the current value of "it" */
@e colon_block_command_ANNOT /* int: this COMMAND uses the ":" not begin/end syntax */
@e condition_tense_ANNOT /* |time_period|: for specification nodes */
@e constant_action_name_ANNOT /* |action_name|: for constant values */
@e constant_action_pattern_ANNOT /* |action_pattern|: for constant values */
@e constant_activity_ANNOT /* |activity|: for constant values */
@e constant_binary_predicate_ANNOT /* |binary_predicate|: for constant values */
@e constant_constant_phrase_ANNOT /* |constant_phrase|: for constant values */
@e constant_enumeration_ANNOT /* |int|: which one from an enumerated kind */
@e constant_equation_ANNOT /* |equation|: for constant values */
@e constant_grammar_verb_ANNOT /* |grammar_verb|: for constant values */
@e constant_instance_ANNOT /* |instance|: for constant values */
@e constant_local_variable_ANNOT /* |local_variable|: for constant values */
@e constant_named_action_pattern_ANNOT /* |named_action_pattern|: for constant values */
@e constant_named_rulebook_outcome_ANNOT /* |named_rulebook_outcome|: for constant values */
@e constant_nonlocal_variable_ANNOT /* |nonlocal_variable|: for constant values */
@e constant_number_ANNOT /* |int|: which integer this is */
@e constant_property_ANNOT /* |property|: for constant values */
@e constant_rule_ANNOT /* |rule|: for constant values */
@e constant_rulebook_ANNOT /* |rulebook|: for constant values */
@e constant_scene_ANNOT /* |scene|: for constant values */
@e constant_table_ANNOT /* |table|: for constant values */
@e constant_table_column_ANNOT /* |table_column|: for constant values */
@e constant_text_ANNOT /* |text_stream|: for constant values */
@e constant_use_option_ANNOT /* |use_option|: for constant values */
@e constant_verb_form_ANNOT /* |verb_form|: for constant values */
@e control_structure_used_ANNOT /* |control_structure_phrase|: for CODE BLOCK nodes only */
@e converted_SN_ANNOT /* |int|: marking descriptions */
@e creation_proposition_ANNOT /* |pcalc_prop|: proposition which newly created value satisfies */
@e creation_site_ANNOT /* |int|: whether an instance was created from this node */
@e defn_language_ANNOT /* |inform_language|: what language this definition is in */
@e end_control_structure_used_ANNOT /* |control_structure_phrase|: for CODE BLOCK nodes only */
@e epistemological_status_ANNOT /* |int|: a bitmap of results from checking an ambiguous reading */
@e evaluation_ANNOT /* |parse_node|: result of evaluating the text */
@e examine_for_ofs_ANNOT /* |int|: mark this as a possible site for removing "of" tree breaks */
@e explicit_iname_ANNOT /* |inter_name|: is this value explicitly an iname? */
@e explicit_literal_ANNOT /* |int|: my value is an explicit integer or text */
@e explicit_vh_ANNOT /* |value_holster|: used for compiling I6-level properties */
@e from_text_substitution_ANNOT /* |int|: whether this is an implicit say invocation */
@e grammar_token_code_ANNOT /* int: used to identify grammar tokens */
@e grammar_token_literal_ANNOT /* int: for grammar tokens which are literal words */
@e grammar_token_relation_ANNOT /* |binary_predicate|: for relation tokens */
@e grammar_value_ANNOT /* |parse_node|: used as a marker when evaluating Understand grammar */
@e imperative_ANNOT /* |int|: marking definitions of imperative verbs */
@e implicit_in_creation_of_ANNOT /* |inference_subject|: for assemblies */
@e implicitness_count_ANNOT /* int: keeping track of recursive assemblies */
@e indentation_level_ANNOT /* |int|: for routines written with Pythonesque indentation */
@e interpretation_of_subject_ANNOT /* |inference_subject|: subject, during passes */
@e is_phrase_option_ANNOT /* |int|: this unparsed text is a phrase option */
@e kind_of_new_variable_ANNOT /* |kind|: what if anything is returned */
@e kind_of_value_ANNOT /* |kind|: for specification nodes */
@e kind_required_by_context_ANNOT /* |kind|: what if anything is expected here */
@e kind_resulting_ANNOT /* |kind|: what if anything is returned */
@e kind_variable_declarations_ANNOT /* |kind_variable_declaration|: and of these */
@e listing_sense_ANNOT /* |int|: are we listing a rule into something, or out of it? */
@e log_inclusion_sense_ANNOT /* |int|: should we include or exclude this from the debugging log? */
@e lpe_options_ANNOT /* |int|: options set for a literal pattern part */
@e modal_verb_ANNOT /* |verb_conjugation|: relevant only for that: e.g., "might" */
@e module_ANNOT /* |compilation_module|: set only for headings, routines and sentences */
@e multiplicity_ANNOT /* |int|: e.g., 5 for "five gold rings" */
@e negated_boolean_ANNOT /* int: set if adjective/verb meant negatively */
@e new_relation_here_ANNOT /* |binary_predicate|: new relation as subject of "relates" sentence */
@e nothing_object_ANNOT /* |int|: this represents |nothing| at run-time */
@e nowhere_ANNOT /* |int|: used by the spatial plugin to show this represents "nowhere" */
@e phrase_invoked_ANNOT /* |phrase|: the phrase believed to be invoked... */
@e phrase_option_ANNOT /* |int|: $2^i$ where $i$ is the option number, $0\leq i<16$ */
@e phrase_options_invoked_ANNOT /* |invocation_options|: details of any options used */
@e property_name_used_as_noun_ANNOT /* |int|: in ambiguous cases such as "open" */
@e proposition_ANNOT /* |pcalc_prop|: for specification nodes */
@e prep_ANNOT /* |preposition_identity|: for e.g. "is on" */
@e quant_ANNOT /* |quantifier|: for quantified excerpts like "three baskets" */
@e quantification_parameter_ANNOT /* |int|: e.g., 3 for "three baskets" */
@e record_as_self_ANNOT /* |int|: record recipient as |self| when writing this */
@e relationship_ANNOT /* |binary_predicate|: for RELATIONSHIP nodes */
@e resolved_ANNOT /* int: temp storage when resolving NPs */
@e response_code_ANNOT /* |int|: for responses only */
@e results_from_splitting_ANNOT /* |int|: node in a routine's parse tree from comma block notation */
@e row_amendable_ANNOT /* int: a candidate row for a table amendment */
@e save_self_ANNOT /* |int|: this invocation must save and preserve |self| at run-time */
@e say_adjective_ANNOT /* |adjectival_phrase|: ...or the adjective to be agreed with by "say" */
@e say_verb_ANNOT /* |verb_conjugation|: ...or the verb to be conjugated by "say" */
@e say_verb_negated_ANNOT /* relevant only for that */
@e self_object_ANNOT /* |int|: this represents |self| at run-time */
@e slash_class_ANNOT /* int: used when partitioning grammar tokens */
@e slash_dash_dash_ANNOT /* |int|: used when partitioning grammar tokens */
@e ssp_closing_segment_wn_ANNOT /* |int|: identifier for the last of these, or |-1| */
@e ssp_segment_count_ANNOT /* |int|: number of subsequent complex-say phrases in stream */
@e subject_ANNOT /* |inference_subject|: what this node describes */
@e subject_term_ANNOT /* |pcalc_term|: what the subject of the subtree was */
@e suppress_newlines_ANNOT /* |int|: whether the next say term runs on */
@e table_cell_unspecified_ANNOT /* int: used to mark table entries as unset */
@e text_unescaped_ANNOT /* |int|: flag used only for literal texts */
@e token_as_parsed_ANNOT /* |parse_node|: what if anything is returned */
@e token_check_to_do_ANNOT /* |parse_node|: what if anything is returned */
@e token_to_be_parsed_against_ANNOT /* |parse_node|: what if anything is returned */
@e turned_already_ANNOT /* |int|: aliasing like "player" to "yourself" performed already */
@e unproven_ANNOT /* |int|: this invocation needs run-time typechecking */
@e verb_id_ANNOT /* int: identifying what kind of VERB node */
@e verb_problem_issued_ANNOT /* |int|: has a problem message about the primary verb been issued already? */
@e vu_ANNOT /* |verb_usage|: for e.g. "does not carry" */
@e you_can_ignore_ANNOT /* |int|: for assertions now drained of meaning */

@

@e L4_NCAT
@e UNKNOWN_NCAT
@e LVALUE_NCAT
@e RVALUE_NCAT
@e COND_NCAT

@d PHRASAL_NFLAG        	0x00000004 /* compiles to a function call */

@

@d PARSE_TREE_METADATA_SETUP ParseTreeUsage::md

=
void ParseTreeUsage::md(void) {
    /* first, the structural nodes: */
	SourceText::node_metadata();

	ParseTree::md((parse_tree_node_type) { ALLOWED_NT, "ALLOWED_NT",				   					1, 1,		L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { EVERY_NT, "EVERY_NT", 				   					0, INFTY,	L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { COMMON_NOUN_NT, "COMMON_NOUN_NT",		   					0, INFTY,	L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { ACTION_NT, "ACTION_NT",				   					0, INFTY,	L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { ADJECTIVE_NT, "ADJECTIVE_NT",			   					0, INFTY,	L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { PROPERTYCALLED_NT, "PROPERTYCALLED_NT",  					2, 2,		L3_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { TOKEN_NT, "TOKEN_NT",					   					0, INFTY,	L3_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { X_OF_Y_NT, "X_OF_Y_NT",				   					2, 2,		L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { CREATED_NT, "CREATED_NT",				  					0, 0,		L3_NCAT, ASSERT_NFLAG });

	ParseTree::md((parse_tree_node_type) { CODE_BLOCK_NT, "CODE_BLOCK_NT",	       					0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { INVOCATION_LIST_NT, "INVOCATION_LIST_NT",		   			0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { INVOCATION_LIST_SAY_NT, "INVOCATION_LIST_SAY_NT",		    0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { INVOCATION_NT, "INVOCATION_NT",		   					0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { VOID_CONTEXT_NT, "VOID_CONTEXT_NT", 						0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { RVALUE_CONTEXT_NT, "RVALUE_CONTEXT_NT", 					0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { LVALUE_CONTEXT_NT, "LVALUE_CONTEXT_NT", 					0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { LVALUE_TR_CONTEXT_NT, "LVALUE_TR_CONTEXT_NT", 			0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { SPECIFIC_RVALUE_CONTEXT_NT, "SPECIFIC_RVALUE_CONTEXT_NT",	0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { MATCHING_RVALUE_CONTEXT_NT, "MATCHING_RVALUE_CONTEXT_NT",	0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { NEW_LOCAL_CONTEXT_NT, "NEW_LOCAL_CONTEXT_NT",				0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { LVALUE_LOCAL_CONTEXT_NT, "LVALUE_LOCAL_CONTEXT_NT",	0, INFTY,	L4_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { CONDITION_CONTEXT_NT, "CONDITION_CONTEXT_NT",				0, INFTY,	L4_NCAT, 0 });

	/* now the specification nodes: */

	ParseTree::md((parse_tree_node_type) { UNKNOWN_NT, "UNKNOWN_NT", 								0, 0,		UNKNOWN_NCAT, 0 });

	ParseTree::md((parse_tree_node_type) { CONSTANT_NT, "CONSTANT_NT", 							0, 0,		RVALUE_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { PHRASE_TO_DECIDE_VALUE_NT, "PHRASE_TO_DECIDE_VALUE_NT",	1, 1,		RVALUE_NCAT, PHRASAL_NFLAG });

	ParseTree::md((parse_tree_node_type) { LOCAL_VARIABLE_NT, "LOCAL_VARIABLE_NT", 				0, 0,		LVALUE_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { NONLOCAL_VARIABLE_NT, "NONLOCAL_VARIABLE_NT", 			0, 0,		LVALUE_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { PROPERTY_VALUE_NT, "PROPERTY_VALUE_NT", 				2, 2,		LVALUE_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { TABLE_ENTRY_NT, "TABLE_ENTRY_NT", 						1, 4,		LVALUE_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { LIST_ENTRY_NT, "LIST_ENTRY_NT", 						2, 2,		LVALUE_NCAT, 0 });

	ParseTree::md((parse_tree_node_type) { LOGICAL_NOT_NT, "LOGICAL_NOT_NT", 						1, 1,		COND_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { LOGICAL_TENSE_NT, "LOGICAL_TENSE_NT", 					1, 1,		COND_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { LOGICAL_AND_NT, "LOGICAL_AND_NT", 						2, 2,		COND_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { LOGICAL_OR_NT, "LOGICAL_OR_NT", 						2, 2,		COND_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { TEST_PROPOSITION_NT, "TEST_PROPOSITION_NT", 			0, 0,		COND_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { TEST_PHRASE_OPTION_NT, "TEST_PHRASE_OPTION_NT", 		0, 0, 		COND_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { TEST_VALUE_NT, "TEST_VALUE_NT", 						1, 1,		COND_NCAT, 0 });
}

@

@d ANNOTATION_PERMISSIONS_WRITER ParseTreeUsage::write_permissions

=
void ParseTreeUsage::write_permissions(void) {
	parentage_allowed[L2_NCAT][L3_NCAT] = TRUE;
	parentage_allowed[L3_NCAT][L3_NCAT] = TRUE;
	parentage_allowed[L2_NCAT][L4_NCAT] = TRUE;
	parentage_allowed[L4_NCAT][L4_NCAT] = TRUE;
	parentage_allowed[L4_NCAT][UNKNOWN_NCAT] = TRUE;

	parentage_allowed[L4_NCAT][LVALUE_NCAT] = TRUE;
	parentage_allowed[L4_NCAT][RVALUE_NCAT] = TRUE;
	parentage_allowed[L4_NCAT][COND_NCAT] = TRUE;

	parentage_allowed[LVALUE_NCAT][UNKNOWN_NCAT] = TRUE;
	parentage_allowed[RVALUE_NCAT][UNKNOWN_NCAT] = TRUE;
	parentage_allowed[COND_NCAT][UNKNOWN_NCAT] = TRUE;
	parentage_allowed[LVALUE_NCAT][LVALUE_NCAT] = TRUE;
	parentage_allowed[RVALUE_NCAT][LVALUE_NCAT] = TRUE;
	parentage_allowed[COND_NCAT][LVALUE_NCAT] = TRUE;
	parentage_allowed[LVALUE_NCAT][RVALUE_NCAT] = TRUE;
	parentage_allowed[RVALUE_NCAT][RVALUE_NCAT] = TRUE;
	parentage_allowed[COND_NCAT][RVALUE_NCAT] = TRUE;
	parentage_allowed[LVALUE_NCAT][COND_NCAT] = TRUE;
	parentage_allowed[RVALUE_NCAT][COND_NCAT] = TRUE;
	parentage_allowed[COND_NCAT][COND_NCAT] = TRUE;

	ParseTree::allow_annotation_to_category(L1_NCAT, clears_pronouns_ANNOT);
	ParseTree::allow_annotation(HEADING_NT, embodying_heading_ANNOT);
	ParseTree::allow_annotation(HEADING_NT, interpretation_of_subject_ANNOT);
	ParseTree::allow_annotation(HEADING_NT, suppress_heading_dependencies_ANNOT);
	ParseTree::allow_annotation_to_category(L1_NCAT, module_ANNOT);

	ParseTree::allow_annotation_to_category(L2_NCAT, clears_pronouns_ANNOT);
	ParseTree::allow_annotation_to_category(L2_NCAT, interpretation_of_subject_ANNOT);
	ParseTree::allow_annotation_to_category(L2_NCAT, sentence_unparsed_ANNOT);
	ParseTree::allow_annotation_to_category(L2_NCAT, verb_problem_issued_ANNOT);
	ParseTree::allow_annotation(ROUTINE_NT, indentation_level_ANNOT);
	ParseTree::allow_annotation(SENTENCE_NT, implicit_in_creation_of_ANNOT);
	ParseTree::allow_annotation(SENTENCE_NT, implicitness_count_ANNOT);
	ParseTree::allow_annotation(SENTENCE_NT, you_can_ignore_ANNOT);
	ParseTree::allow_annotation_to_category(L2_NCAT, module_ANNOT);
	LOOP_OVER_NODE_TYPES(t)
		if (ParseTree::test_flag(t, ASSERT_NFLAG))
			ParseTree::allow_annotation(t, resolved_ANNOT);

	ParseTree::allow_annotation_to_category(L3_NCAT, module_ANNOT);
	ParseTree::allow_annotation_to_category(L3_NCAT, creation_proposition_ANNOT);
	ParseTree::allow_annotation_to_category(L3_NCAT, evaluation_ANNOT);
	ParseTree::allow_annotation_to_category(L3_NCAT, subject_ANNOT);
	ParseTree::allow_annotation(ACTION_NT, action_meaning_ANNOT);
	ParseTree::allow_annotation(ADJECTIVE_NT, aph_ANNOT);
	ParseTree::allow_annotation(ADJECTIVE_NT, negated_boolean_ANNOT);
	ParseTree::allow_annotation(ADJECTIVE_NT, nounphrase_article_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, log_inclusion_sense_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, verb_id_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, imperative_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, examine_for_ofs_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, listing_sense_ANNOT);
	ParseTree::allow_annotation(COMMON_NOUN_NT, action_meaning_ANNOT);
	ParseTree::allow_annotation(COMMON_NOUN_NT, creation_site_ANNOT);
	ParseTree::allow_annotation(COMMON_NOUN_NT, implicitly_refers_to_ANNOT);
	ParseTree::allow_annotation(COMMON_NOUN_NT, multiplicity_ANNOT);
	ParseTree::allow_annotation(COMMON_NOUN_NT, quant_ANNOT);
	ParseTree::allow_annotation(COMMON_NOUN_NT, quantification_parameter_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, aph_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, category_of_I6_translation_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, creation_site_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, defn_language_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, log_inclusion_sense_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, lpe_options_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, multiplicity_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, negated_boolean_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, new_relation_here_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, nowhere_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, quant_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, quantification_parameter_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, row_amendable_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, slash_dash_dash_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, table_cell_unspecified_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, turned_already_ANNOT);
	ParseTree::allow_annotation(PROPERTY_LIST_NT, nounphrase_article_ANNOT);
	ParseTree::allow_annotation(RELATIONSHIP_NT, relationship_ANNOT);
	ParseTree::allow_annotation(TOKEN_NT, grammar_token_literal_ANNOT);
	ParseTree::allow_annotation(TOKEN_NT, grammar_token_relation_ANNOT);
	ParseTree::allow_annotation(TOKEN_NT, grammar_value_ANNOT);
	ParseTree::allow_annotation(TOKEN_NT, slash_class_ANNOT);

	ParseTree::allow_annotation_to_category(L4_NCAT, colon_block_command_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, control_structure_used_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, end_control_structure_used_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, evaluation_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, indentation_level_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, kind_of_new_variable_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, kind_required_by_context_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, results_from_splitting_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, token_as_parsed_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, token_check_to_do_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, token_to_be_parsed_against_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, verb_problem_issued_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, problem_falls_under_ANNOT);
	ParseTree::allow_annotation_to_category(L4_NCAT, module_ANNOT);
	ParseTree::allow_annotation(CODE_BLOCK_NT, sentence_unparsed_ANNOT);
	ParseTree::allow_annotation(INVOCATION_LIST_NT, from_text_substitution_ANNOT);
	ParseTree::allow_annotation(INVOCATION_LIST_NT, sentence_unparsed_ANNOT);
	ParseTree::allow_annotation(INVOCATION_LIST_SAY_NT, sentence_unparsed_ANNOT);
	ParseTree::allow_annotation(INVOCATION_LIST_SAY_NT, suppress_newlines_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, epistemological_status_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, kind_resulting_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, kind_variable_declarations_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, modal_verb_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, phrase_invoked_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, phrase_options_invoked_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, say_adjective_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, say_verb_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, say_verb_negated_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, ssp_closing_segment_wn_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, ssp_segment_count_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, suppress_newlines_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, save_self_ANNOT);
	ParseTree::allow_annotation(INVOCATION_NT, unproven_ANNOT);

	ParseTreeUsage::allow_annotation_to_specification(converted_SN_ANNOT);
	ParseTreeUsage::allow_annotation_to_specification(subject_term_ANNOT);
	ParseTreeUsage::allow_annotation_to_specification(epistemological_status_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_action_name_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_action_pattern_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_activity_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_binary_predicate_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_constant_phrase_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_enumeration_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_equation_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_grammar_verb_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_instance_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_named_action_pattern_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_named_rulebook_outcome_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_number_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_property_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_rule_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_rulebook_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_scene_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_table_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_table_column_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_text_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_use_option_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, constant_verb_form_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, explicit_literal_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, explicit_vh_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, grammar_token_code_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, kind_of_value_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, nothing_object_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, property_name_used_as_noun_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, proposition_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, response_code_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, self_object_ANNOT);
	ParseTree::allow_annotation(CONSTANT_NT, text_unescaped_ANNOT);
	ParseTree::allow_annotation(LOCAL_VARIABLE_NT, constant_local_variable_ANNOT);
	ParseTree::allow_annotation(LOCAL_VARIABLE_NT, kind_of_value_ANNOT);
	ParseTree::allow_annotation(LOGICAL_TENSE_NT, condition_tense_ANNOT);
	ParseTree::allow_annotation(NONLOCAL_VARIABLE_NT, constant_nonlocal_variable_ANNOT);
	ParseTree::allow_annotation(NONLOCAL_VARIABLE_NT, kind_of_value_ANNOT);
	ParseTree::allow_annotation(PROPERTY_VALUE_NT, record_as_self_ANNOT);
	ParseTree::allow_annotation(TEST_PHRASE_OPTION_NT, phrase_option_ANNOT);
	ParseTree::allow_annotation(TEST_PROPOSITION_NT, proposition_ANNOT);
	ParseTree::allow_annotation(UNKNOWN_NT, prep_ANNOT);
	ParseTree::allow_annotation(UNKNOWN_NT, vu_ANNOT);
}
void ParseTreeUsage::allow_annotation_to_specification(int annot) {
	ParseTree::allow_annotation(UNKNOWN_NT, annot);
	ParseTree::allow_annotation_to_category(LVALUE_NCAT, annot);
	ParseTree::allow_annotation_to_category(RVALUE_NCAT, annot);
	ParseTree::allow_annotation_to_category(COND_NCAT, annot);
}

@

@d PARENTAGE_EXCEPTIONS ParseTreeUsage::parentage_exceptions

=
int ParseTreeUsage::parentage_exceptions(node_type_t t_parent, int cat_parent,
	node_type_t t_child, int cat_child) {
	if ((t_parent == HEADING_NT) && (cat_child == L2_NCAT)) return TRUE;
	if ((t_parent == PHRASE_TO_DECIDE_VALUE_NT) && (t_child == INVOCATION_LIST_NT)) return TRUE;
	return FALSE;
}

@ Further classification:

@d IMMUTABLE_NODE ParseTreeUsage::immutable
@d SENTENCE_NODE ParseTreeUsage::second_level

=
int ParseTreeUsage::second_level(node_type_t t) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if ((metadata) && (metadata->category == L2_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::immutable(node_type_t t) {
	if (ParseTreeUsage::is_specification_node_type(t)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_specification_node_type(node_type_t t) {
	if (t == UNKNOWN_NT) return TRUE;
	parse_tree_node_type *metadata = ParseTree::node_metadata(t);
	if ((metadata) &&
		((metadata->category == RVALUE_NCAT) ||
		(metadata->category == LVALUE_NCAT) ||
		(metadata->category == COND_NCAT))) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_lvalue(parse_node *pn) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(ParseTree::get_type(pn));
	if ((metadata) && (metadata->category == LVALUE_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_rvalue(parse_node *pn) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(ParseTree::get_type(pn));
	if ((metadata) && (metadata->category == RVALUE_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_value(parse_node *pn) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(ParseTree::get_type(pn));
	if ((metadata) &&
		((metadata->category == LVALUE_NCAT) || (metadata->category == RVALUE_NCAT)))
		return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_condition(parse_node *pn) {
	parse_tree_node_type *metadata = ParseTree::node_metadata(ParseTree::get_type(pn));
	if ((metadata) && (metadata->category == COND_NCAT)) return TRUE;
	return FALSE;
}

int ParseTreeUsage::is_phrasal(parse_node *pn) {
	if (ParseTree::test_flag(ParseTree::get_type(pn), PHRASAL_NFLAG)) return TRUE;
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
	ParseTree::verify_structure(p);
	if (ParseTree::test_flag(ParseTree::get_type(p), ASSERT_NFLAG)) return TRUE;
	return FALSE;
}

@

@d PARSE_TREE_LOGGER ParseTreeUsage::log_node

=
void ParseTreeUsage::log_node(OUTPUT_STREAM, parse_node *pn) {
	if (ParseTree::get_meaning(pn)) WRITE("$M", ParseTree::get_meaning(pn));
	else WRITE("$N", pn->node_type);
	if (Wordings::nonempty(ParseTree::get_text(pn))) WRITE("'%W'", ParseTree::get_text(pn));

	if ((pn->node_type >= UNKNOWN_NT) && (pn->node_type <= TEST_VALUE_NT))
		@<Log annotations of specification nodes@>
	else
		@<Log annotations of structural nodes@>;
}

@<Log annotations of specification nodes@> =
	if (ParseTree::get_kind_of_value(pn)) WRITE("-$u", ParseTree::get_kind_of_value(pn));
	if (ParseTreeUsage::is_lvalue(pn)) Lvalues::log(pn);
	else if (ParseTreeUsage::is_rvalue(pn)) Rvalues::log(pn);
	else if (ParseTreeUsage::is_condition(pn)) Conditions::log(pn);
	if (ParseTree::get_vu(pn)) { WRITE("-vu:"); NewVerbs::log(ParseTree::get_vu(pn)); }
	if (ParseTree::get_prep(pn)) { WRITE("-prep:$p", ParseTree::get_prep(pn)); }

@ We do not log every annotation: only the few which are most illuminating.

@<Log annotations of structural nodes@> =
	int show_eval = FALSE, show_refers = FALSE;
	if (ParseTree::int_annotation(pn, creation_site_ANNOT))
		WRITE(" (created here)");
	switch(pn->node_type) {
		case ADJECTIVE_NT: show_eval = TRUE; break;
		case HEADING_NT: WRITE(" (level %d)", ParseTree::int_annotation(pn, heading_level_ANNOT)); break;
		case COMMON_NOUN_NT: show_refers = TRUE; break;
		case KIND_NT: show_refers = TRUE; break;
		case RELATIONSHIP_NT:
			Diagrams::log_node(OUT, pn);
			break;
		case PROPER_NOUN_NT:
			Diagrams::log_node(OUT, pn);
			if (ParseTree::int_annotation(pn, multiplicity_ANNOT))
				WRITE(" (x%d)", ParseTree::int_annotation(pn, multiplicity_ANNOT));
			show_refers = TRUE;
			break;
		case AVERB_NT:
			WRITE(" ($V)", ParseTree::int_annotation(pn, verb_id_ANNOT));
			Diagrams::log_node(OUT, pn);
			break;
		case TOKEN_NT: WRITE(" [%d/%d]", ParseTree::int_annotation(pn, slash_class_ANNOT),
			ParseTree::int_annotation(pn, slash_dash_dash_ANNOT)); break;
		case INVOCATION_LIST_NT:
		case CODE_BLOCK_NT: {
			control_structure_phrase *csp = ParseTree::get_control_structure_used(pn);
			WRITE("  "); ControlStructures::log(csp); WRITE(" ");
			if (pn->node_type == INVOCATION_LIST_NT)
				WRITE("%d", ParseTree::int_annotation(pn, indentation_level_ANNOT));
			else WRITE(" ");
			WRITE("  ");
			break;
		}
	}
	if (ParseTree::get_kind_required_by_context(pn))
		WRITE(" requires:$u", ParseTree::get_kind_required_by_context(pn));

	if (show_refers) {
		if (ParseTree::get_subject(pn)) { WRITE(" refers:$j", ParseTree::get_subject(pn)); }
		if (ParseTree::get_evaluation(pn)) { WRITE(" eval:$P", ParseTree::get_evaluation(pn)); }
		if (ParseTree::int_annotation(pn, implicitly_refers_to_ANNOT)) WRITE(" (implicit)");
	}
	if ((show_eval) && (ParseTree::get_evaluation(pn))) {
		WRITE(" eval:$P", ParseTree::get_evaluation(pn));
	}
	if (ParseTree::get_defn_language(pn))
		WRITE(" language:%J", ParseTree::get_defn_language(pn));
	if (ParseTree::get_creation_proposition(pn))
		WRITE(" (creation $D)", ParseTree::get_creation_proposition(pn));

@ =
void ParseTreeUsage::write_to_file(void) {
	ParseTree::write_to_file(Task::syntax_tree(), Task::parse_tree_file());
}
void ParseTreeUsage::verify(void) {
	ParseTree::verify(Task::syntax_tree());
}

@

@d PARSE_TREE_TRAVERSE_TYPE instance

