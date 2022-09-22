[DialogueChoices::] Dialogue Choices.

To manage dialogue choices.

@h Scanning the dialogue choices in pass 0.
Choices have already been parsed a little. For example,
= (text as Inform 7)
	-- (if the shortbread is carried) "Offer the shortbread"
=
will have become:
= (text)
	DIALOGUE_CHOICE_NT
		DIALOGUE_SELECTION_NT ""Offer the shortbread""
		DIALOGUE_CLAUSE_NT "if the shortbread is carried"
=

@

=
dialogue_choice *DialogueChoices::new(parse_node *PN) {
	int L = Annotations::read_int(PN, dialogue_level_ANNOT);
	if (L < 0) L = 0;
	dialogue_choice *dc = CREATE(dialogue_choice);
	@<Initialise the choice@>;
	@<Parse the clauses just enough to classify them@>;
	@<Add the choice to the world model@>;
	dc->as_node = DialogueNodes::add_to_current_beat(L, NULL, dc);
	return dc;
}

@ =
typedef struct dialogue_choice {
	struct parse_node *choice_at;
	struct wording choice_name;
	struct instance *as_instance;
	struct dialogue_node *as_node;
	struct parse_node *selection;
	struct wording selection_parameter;
	struct dialogue_beat *to_perform;
	struct dialogue_choice_compilation_data compilation_data;
	int selection_type;
	CLASS_DEFINITION
} dialogue_choice;

@<Initialise the choice@> =
	dc->choice_at = PN;
	dc->choice_name = EMPTY_WORDING;
	dc->as_node = NULL;
	dc->selection = NULL;
	dc->selection_parameter = EMPTY_WORDING;
	dc->to_perform = NULL;
	dc->selection_type = AGAIN_DSEL;
	dc->compilation_data = RTDialogueChoices::new(PN, dc);

@ Each choice produces an instance of the kind |dialogue choice|, using the name
given in its clauses if one was.

@<Add the choice to the world model@> =
	if (K_dialogue_choice == NULL) internal_error("DialogueKit has not created K_dialogue_choice");
	wording W = dc->choice_name;
	if (Wordings::empty(W)) {
		TEMPORARY_TEXT(faux_name)
		WRITE_TO(faux_name, "choice-%d", dc->allocation_id + 1);
		W = Feeds::feed_text(faux_name);
		DISCARD_TEXT(faux_name)
	}
	pcalc_prop *prop = Propositions::Abstract::to_create_something(K_dialogue_choice, W);
	Assert::true(prop, CERTAIN_CE);
	dc->as_instance = Instances::latest();

@<Parse the clauses just enough to classify them@> =
	int failed_already = FALSE;
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			if (<dialogue-choice-clause>(CW)) {
				Annotations::write_int(clause, dialogue_choice_clause_ANNOT, <<r>>);
				if (<<r>> == CHOICE_NAME_DCC) {
					wording NW = GET_RW(<dialogue-choice-clause>, 1);
					if (<instance>(NW)) {
						instance *I = <<rp>>;
						DialogueBeats::non_unique_instance_problem(I, K_dialogue_choice);
					} else {
						dc->choice_name = NW;
					}
				}
			}
		} else if (Node::is(clause, DIALOGUE_SELECTION_NT)) {
			dc->selection = clause;
			if (<dialogue-selection>(CW)) {
				dc->selection_type = <<r>>;
				switch (dc->selection_type) {
					case INSTEAD_OF_DSEL:
					case AFTER_DSEL:
					case BEFORE_DSEL:
					case PERFORM_DSEL:
						dc->selection_parameter = GET_RW(<dialogue-selection>, 1);
						break;					
				}
			} else {
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, CW);
				StandardProblems::handmade_problem(Task::syntax_tree(),
					_p_(PM_ChoiceSelectionUnknown));
				Problems::issue_problem_segment(
					"The dialogue choice offered by %1 is apparently '%2', but that "
					"isn't one of the possible ways to write a choice.");
				Problems::issue_problem_end();
				failed_already = TRUE;
			}
		} else internal_error("damaged DIALOGUE_CHOICE_NT subtree");
	}
	if (failed_already == FALSE) @<Check the flow notation@>;

@<Check the flow notation@> =
	int left_arrow = FALSE, right_arrow = FALSE, dash = FALSE;
	switch (dc->selection_type) {
		case INSTEAD_OF_DSEL:
		case AFTER_DSEL:
		case BEFORE_DSEL:
		case OTHERWISE_DSEL:
		case TEXTUAL_DSEL:
			dash = TRUE;
			break;					
		case AGAIN_DSEL:
			left_arrow = TRUE;
			break;
		case PERFORM_DSEL:
		case STOP_DSEL:
		case NEW_CHOICE_DSEL:
			right_arrow = TRUE;
			break;					
	}
	vocabulary_entry *symbol = Lexer::word(Wordings::first_wn(Node::get_text(PN)));
	if ((dash) && (symbol != DOUBLEDASH_V)) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ChoiceDashDashExpected));
		Problems::issue_problem_segment(
			"The dialogue choice offered by %1 should open with '--', "
			"since it offers a choice, rather than '->' or '<-' which "
			"relate to the flow of the script.");
		Problems::issue_problem_end();
	}
	if ((left_arrow) && (symbol != LEFTARROW_V)) {
		if ((symbol == DOUBLEDASH_V) && (PN->down) && (dc->selection == NULL)) {
			current_sentence = dc->choice_at;
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ChoiceSelectionMissing));
			Problems::issue_problem_segment(
				"The dialogue choice offered by %1 doesn't say what the option actually is, "
				"which is allowed only if it is a simple '--' used as a divider. Here, it "
				"seems to have some bracketed annotations as well. That must be wrong.");
			Problems::issue_problem_end();
		} else {		
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_ChoiceLeftArrowExpected));
			Problems::issue_problem_segment(
				"The dialogue choice offered by %1 should open with '<-', "
				"since it relates to backwards flow within the current beat, "
				"rather than '->' (forwards flow) or '--' (an option).");
			Problems::issue_problem_end();
		}
	}
	if ((right_arrow) && (symbol != RIGHTARROW_V)) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ChoiceRightArrowExpected));
		Problems::issue_problem_segment(
			"The dialogue choice offered by %1 should open with '->', "
			"since it relates to flow out of the current beat, "
			"rather than '<-' (backwards flow) or '--' (an option).");
		Problems::issue_problem_end();
	}

@ As with the analogous clauses for //Dialogue Beats//, each clause can be one
of the following possibilities:

@e CHOICE_NAME_DCC from 1
@e IF_DCC
@e UNLESS_DCC
@e PROPERTY_DCC

@ Using:

=
<dialogue-choice-clause> ::=
	this is the { ... choice } |                     ==> { CHOICE_NAME_DCC, - }
	if ... |                                         ==> { IF_DCC, - }
	unless ... |                                     ==> { UNLESS_DCC, - }
	...                                              ==> { PROPERTY_DCC, - }

@ =
void DialogueChoices::write_dcc(OUTPUT_STREAM, int c) {
	switch(c) {
		case CHOICE_NAME_DCC:           WRITE("CHOICE_NAME"); break;
		case IF_DCC:                    WRITE("IF"); break;
		case UNLESS_DCC:                WRITE("UNLESS"); break;
		case PROPERTY_DCC:              WRITE("PROPERTY"); break;
		default:                        WRITE("?"); break;
	}
}

@

@e NEW_CHOICE_DSEL from 1
@e TEXTUAL_DSEL
@e AGAIN_DSEL
@e STOP_DSEL
@e OTHERWISE_DSEL
@e INSTEAD_OF_DSEL
@e AFTER_DSEL
@e BEFORE_DSEL
@e PERFORM_DSEL

=
<dialogue-selection> ::=
	<quoted-text> |                                ==> { TEXTUAL_DSEL, - }
	another choice |                               ==> { NEW_CHOICE_DSEL, - }
	stop |                                         ==> { STOP_DSEL, - }
	otherwise |                                    ==> { OTHERWISE_DSEL, - }
	instead of ... |                               ==> { INSTEAD_OF_DSEL, - }
	after ... |                                    ==> { AFTER_DSEL, - }
	before ... |                                   ==> { BEFORE_DSEL, - }
	perform <definite-article> ... |               ==> { PERFORM_DSEL, - }
	perform ...                                    ==> { PERFORM_DSEL, - }

@h Processing choices after pass 1.
It's now a little later, and the following is called to look at each choice.
There's not much to do: just to identify the beat to be performed, if there
is one.

=
void DialogueChoices::decide_choice_performs(void) {
	dialogue_choice *dc;
	LOOP_OVER(dc, dialogue_choice) {
		current_sentence = dc->choice_at;
		for (parse_node *clause = dc->choice_at->down; clause; clause = clause->next) {
			if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
				wording CW = Node::get_text(clause);
				int c = Annotations::read_int(clause, dialogue_choice_clause_ANNOT);
				switch (c) {
					case PROPERTY_DCC: {
						<dialogue-choice-clause>(CW);
						wording A = GET_RW(<dialogue-choice-clause>, 1);
						<np-articled-list>(A);
						parse_node *AL = <<rp>>;
						DialogueChoices::parse_property(dc, AL);
						break;
					}
				}
			}
		}
		if (dc->selection_type == PERFORM_DSEL) {
			dialogue_beat *db;
			LOOP_OVER(db, dialogue_beat)
				if (Wordings::match(dc->selection_parameter, db->beat_name))
					dc->to_perform = db;
			if (dc->to_perform == NULL) {
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, dc->selection_parameter);
				StandardProblems::handmade_problem(Task::syntax_tree(),
					_p_(PM_ChoicePerformsUnknown));
				Problems::issue_problem_segment(
					"The dialogue choice offered by %1 asks to perform the beat '%2', "
					"but I don't recognise that as the name of any beat in the story.");
				Problems::issue_problem_end();
			} else {
				LOG("Dialogue beat: $O\n", dc->to_perform->as_instance);
			}
		}
	}
}

void DialogueChoices::parse_property(dialogue_choice *dc, parse_node *AL) {
	if (Node::is(AL, AND_NT)) {
		DialogueChoices::parse_property(dc, AL->down);
		DialogueChoices::parse_property(dc, AL->down->next);
	} else if (Node::is(AL, UNPARSED_NOUN_NT)) {
		inference_subject *subj = Instances::as_subject(dc->as_instance);
		wording A = Node::get_text(AL);
		if (<s-value-uncached>(A)) {
			parse_node *val = <<rp>>;
			if (Rvalues::is_CONSTANT_construction(val, CON_property)) {
				property *prn = Rvalues::to_property(val);
				if (Properties::is_either_or(prn)) {
					@<Assert that the choice has this property@>;
					return;
				}
			}
			if ((Specifications::is_description(val)) || (Node::is(val, TEST_VALUE_NT))) {
				@<Assert that the choice has this property value@>;
				return;
			}
			LOG("Unexpected prop: $T\n", val);
		} else {
			LOG("Unrecognised prop: '%W'\n", A);
		}
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, A);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ChoiceMarkupUnknown));
		Problems::issue_problem_segment(
			"The dialogue choice %1 should apparently be '%2', but that "
			"isn't something I recognise as a property which a choice can have.");
		Problems::issue_problem_end();
	}
}

@<Assert that the choice has this property@> =
	pcalc_prop *prop = AdjectivalPredicates::new_atom_on_x(
		EitherOrProperties::as_adjective(prn), FALSE);
	prop = Propositions::concatenate(
		Propositions::Abstract::prop_to_set_kind(K_dialogue_choice), prop);
	Assert::true_about(prop, subj, CERTAIN_CE);

@<Assert that the choice has this property value@> =
	pcalc_prop *prop = Descriptions::to_proposition(val);
	if (prop) {
		prop = Propositions::concatenate(
			Propositions::Abstract::prop_to_set_kind(K_dialogue_choice), prop);
		Assert::true_about(prop, subj, CERTAIN_CE);
		return;
	}

@ So what remains to be done? Everything is done except for code to be compiled
at runtime. See //runtime: Dialogue Choice Instances//.
