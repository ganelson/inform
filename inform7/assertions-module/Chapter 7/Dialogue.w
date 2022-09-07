[Dialogue::] Dialogue.

To manage dialogue beats and lines.

@ See the test group |:dialogue|.

@d MAX_DIALOGUE_LINE_NESTING 25

=
heading *dialogue_section_being_scanned = NULL;
dialogue_beat *previous_dialogue_beat = NULL;
dialogue_beat *current_dialogue_beat = NULL;
dialogue_line *precursor_dialogue_lines[MAX_DIALOGUE_LINE_NESTING];

void Dialogue::note_heading(heading *h) {
	if (h->holds_dialogue) dialogue_section_being_scanned = h;
	else dialogue_section_being_scanned = NULL;
	previous_dialogue_beat = NULL;
	current_dialogue_beat = NULL;
	for (int i=0; i<MAX_DIALOGUE_LINE_NESTING; i++)
		precursor_dialogue_lines[i] = NULL;
}

@

=
typedef struct dialogue_beat {
	struct wording beat_name;
	struct wording scene_name;
	struct parse_node *cue_at;
	struct heading *under_heading;
	struct instance *as_instance;
	struct scene *as_scene;
	
	struct parse_node *immediately_after;
	struct linked_list *some_time_after; /* of |parse_node| */
	struct linked_list *some_time_before; /* of |parse_node| */
	struct linked_list *about_list; /* of |parse_node| */

	struct dialogue_line *opening_line;
	struct dialogue_beat_compilation_data compilation_data;
	CLASS_DEFINITION
} dialogue_beat;

typedef struct dialogue_line {
	struct wording line_name;
	struct instance *as_instance;
	struct parse_node *line_at;
	struct wording speaker_text;
	struct wording speech_text;
	struct dialogue_beat *owning_beat;
	struct dialogue_line *parent_line;
	struct dialogue_line *child_line;
	struct dialogue_line *next_line;
	struct dialogue_line_compilation_data compilation_data;
	CLASS_DEFINITION
} dialogue_line;

@

=
dialogue_beat *Dialogue::create_cue(parse_node *PN) {
	if (dialogue_section_being_scanned == NULL) internal_error("cue outside dialogue section");
	if (Annotations::read_int(PN, dialogue_level_ANNOT) > 0) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_IndentedBeat),
			"this dialogue beat seems to be indented",
			"which in dialogue would mean that it is part of something above it. "
			"But all beats (unlike lines) are free-standing, and should not be "
			"indented.");
	}
	dialogue_beat *db = CREATE(dialogue_beat);
	db->beat_name = EMPTY_WORDING;
	db->scene_name = EMPTY_WORDING;
	db->cue_at = PN;
	db->under_heading = dialogue_section_being_scanned;
	db->immediately_after = NULL;
	db->some_time_after = NEW_LINKED_LIST(parse_node);
	db->some_time_before = NEW_LINKED_LIST(parse_node);
	db->about_list = NEW_LINKED_LIST(parse_node);
	db->opening_line = NULL;
	db->compilation_data = RTDialogue::new_beat(PN, db);
	db->as_scene = NULL;
	previous_dialogue_beat = current_dialogue_beat;
	current_dialogue_beat = db;
	for (int i=0; i<MAX_DIALOGUE_LINE_NESTING; i++)
		precursor_dialogue_lines[i] = NULL;

	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			<dialogue-beat-clause>(CW);
			Annotations::write_int(clause, dialogue_beat_clause_ANNOT, <<r>>);
		} else internal_error("damaged DIALOGUE_CUE_NT subtree");
	}

	int dialogue_beat_name_count = 0;
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		switch (Annotations::read_int(clause, dialogue_beat_clause_ANNOT)) {
			case BEAT_NAME_DBC:	
				<dialogue-beat-clause>(CW);
				current_dialogue_beat->beat_name = GET_RW(<dialogue-beat-clause>, 1);
				dialogue_beat_name_count++;
				break;
			case SCENE_NAME_DBC:	
				<dialogue-beat-clause>(CW);
				wording W = GET_RW(<dialogue-beat-clause>, 1);
				word_assemblage wa =
					PreformUtilities::merge(<dialogue-beat-name-construction>, 0,
						WordAssemblages::from_wording(W));
				current_dialogue_beat->beat_name = WordAssemblages::to_wording(&wa);
				wa = PreformUtilities::merge(<dialogue-beat-name-construction>, 1,
						WordAssemblages::from_wording(W));
				current_dialogue_beat->scene_name = WordAssemblages::to_wording(&wa);
				dialogue_beat_name_count++;
				break;
		}
	}

	if (dialogue_beat_name_count > 1) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BeatNamedTwice),
			"this dialogue beat seems to be named more than once",
			"which is not allowed. It can be anonymous, but otherwise can only have "
			"one name (either as a beat or as a scene, and not both).");
	}

	wording W = db->beat_name;
	if (Wordings::empty(W)) {
		TEMPORARY_TEXT(faux_name)
		WRITE_TO(faux_name, "beat-%d", db->allocation_id + 1);
		W = Feeds::feed_text(faux_name);
		DISCARD_TEXT(faux_name)
	}
	pcalc_prop *prop = Propositions::Abstract::to_create_something(K_dialogue_beat, W);
	Assert::true(prop, CERTAIN_CE);
	db->as_instance = Instances::latest();
	return db;
}

@

@e BEAT_NAME_DBC from 1
@e SCENE_NAME_DBC
@e ABOUT_DBC
@e IF_DBC
@e UNLESS_DBC
@e AFTER_DBC
@e IMMEDIATELY_AFTER_DBC
@e BEFORE_DBC
@e LATER_DBC
@e NEXT_DBC
@e GENERIC_DBC

=
<dialogue-beat-clause> ::=
	this is the { ... beat } |  ==> { BEAT_NAME_DBC, - }
	this is the ... scene |     ==> { SCENE_NAME_DBC, - }
	about ... |                 ==> { ABOUT_DBC, - }
	if ... |                    ==> { IF_DBC, - }
	unless ... |                ==> { UNLESS_DBC, - }
	after ... |                 ==> { AFTER_DBC, - }
	immediately after ... |     ==> { IMMEDIATELY_AFTER_DBC, - }
	before ... |                ==> { BEFORE_DBC, - }
	later |                     ==> { LATER_DBC, - }
	next |                      ==> { NEXT_DBC, - }
	...                         ==> { GENERIC_DBC, - }

@

=
void Dialogue::write_dbc(OUTPUT_STREAM, int c) {
	switch(c) {
		case BEAT_NAME_DBC: WRITE("BEAT_NAME"); break;
		case SCENE_NAME_DBC: WRITE("SCENE_NAME"); break;
		case ABOUT_DBC: WRITE("ABOUT"); break;
		case IF_DBC: WRITE("IF"); break;
		case UNLESS_DBC: WRITE("UNLESS"); break;
		case AFTER_DBC: WRITE("AFTER"); break;
		case IMMEDIATELY_AFTER_DBC: WRITE("IMMEDIATELY_AFTER"); break;
		case BEFORE_DBC: WRITE("BEFORE"); break;
		case LATER_DBC: WRITE("LATER"); break;
		case NEXT_DBC: WRITE("NEXT"); break;
		case GENERIC_DBC: WRITE("GENERIC"); break;
		default: WRITE("?"); break;
	}
}

@

=
<dialogue-beat-name-construction> ::=
	... beat |
	... scene

@

=
void Dialogue::decide_cue_sequencing(void) {
	dialogue_beat *db, *previous = NULL;
	LOOP_OVER(db, dialogue_beat) {
		current_sentence = db->cue_at;
		int iac = 0;
		for (parse_node *clause = db->cue_at->down; clause; clause = clause->next) {
			wording CW = Node::get_text(clause);
			switch (Annotations::read_int(clause, dialogue_beat_clause_ANNOT)) {
				case NEXT_DBC:
					if ((previous) && (previous->under_heading == db->under_heading)) {
						iac++;
						db->immediately_after = Rvalues::from_dialogue_beat(previous);
					} else @<Issue PM_NoPreviousBeat problem@>;
					break;
				case IMMEDIATELY_AFTER_DBC: {
					<dialogue-beat-clause>(CW);
					wording B = GET_RW(<dialogue-beat-clause>, 1);
					parse_node *desc = Dialogue::parse_beat_name(B);
					if (desc) {
						iac++;
						db->immediately_after = desc;
					}
					break;
				}
				case LATER_DBC:
					if ((previous) && (previous->under_heading == db->under_heading)) {
						parse_node *desc = Rvalues::from_dialogue_beat(previous);
						ADD_TO_LINKED_LIST(desc, parse_node, db->some_time_after);
					} else @<Issue PM_NoPreviousBeat problem@>;
					break;
				case AFTER_DBC: {
					<dialogue-beat-clause>(CW);
					wording B = GET_RW(<dialogue-beat-clause>, 1);
					parse_node *desc = Dialogue::parse_beat_name(B);
					if (desc) ADD_TO_LINKED_LIST(desc, parse_node, db->some_time_after);
					break;
				}
				case BEFORE_DBC: {
					<dialogue-beat-clause>(CW);
					wording B = GET_RW(<dialogue-beat-clause>, 1);
					parse_node *desc = Dialogue::parse_beat_name(B);
					if (desc) ADD_TO_LINKED_LIST(desc, parse_node, db->some_time_before);
					break;
				}
			}

		}
		if (Wordings::nonempty(db->scene_name)) {
			pcalc_prop *prop = Propositions::Abstract::to_create_something(K_scene, db->scene_name);
			Assert::true(prop, CERTAIN_CE);
			db->as_scene = Scenes::from_named_constant(Instances::latest());
		}
		previous = db;
		if (iac > 1) 
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DoubleImmediateBeat),
				"this dialogue beat asks to be immediately after two or more other beats",
				"either with 'next' or 'immediately after'. It can only give one.");
	}
}

@<Issue PM_NoPreviousBeat problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NoPreviousBeat),
		"this dialogue beat asks to be performed after the previous one",
		"but in this dialogue section, there is no previous one.");

@ =
parse_node *Dialogue::parse_beat_name(wording CW) {
	if (<s-type-expression-uncached>(CW)) {
		parse_node *desc = <<rp>>;
		kind *K = Specifications::to_kind(desc);
		if (Kinds::ne(K, K_dialogue_beat)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, CW);
			Problems::quote_kind(3, K);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NotABeat));
			Problems::issue_problem_segment(
				"The dialogue beat %1 refers to another beat with '%2', but that "
				"seems to describe %3.");
			Problems::issue_problem_end();
			return NULL;
		}
		return desc;
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, CW);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnrecognisedBeat));
		Problems::issue_problem_segment(
			"The dialogue beat %1 refers to another beat with '%2', but that "
			"isn't something I recognise as a description.");
		Problems::issue_problem_end();
		return NULL;
	}
}

@

=
void Dialogue::decide_cue_topics(void) {
	dialogue_beat *db;
	LOOP_OVER(db, dialogue_beat) {
		current_sentence = db->cue_at;
		for (parse_node *clause = db->cue_at->down; clause; clause = clause->next) {
			wording CW = Node::get_text(clause);
			switch (Annotations::read_int(clause, dialogue_beat_clause_ANNOT)) {
				case ABOUT_DBC: {
					<dialogue-beat-clause>(CW);
					wording A = GET_RW(<dialogue-beat-clause>, 1);
					<np-articled-list>(A);
					parse_node *AL = <<rp>>;
					Dialogue::parse_topic(db->about_list, AL);
					break;
				}
			}
		}
	}
}

void Dialogue::parse_topic(linked_list *about_list, parse_node *AL) {
	if (Node::is(AL, AND_NT)) {
		Dialogue::parse_topic(about_list, AL->down);
		Dialogue::parse_topic(about_list, AL->down->next);
	} else if (Node::is(AL, UNPARSED_NOUN_NT)) {
		wording A = Node::get_text(AL);
		LOG("Text: %W\n", A);
		if (<s-constant-value>(A)) {
			parse_node *desc = <<rp>>;
			kind *K = Specifications::to_kind(desc);
			if (Kinds::Behaviour::is_subkind_of_object(K)) {
				ADD_TO_LINKED_LIST(desc, parse_node, about_list);
			} else {
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, A);
				Problems::quote_kind(3, K);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NotAnAboutTopic));
				Problems::issue_problem_segment(
					"The dialogue beat %1 is apparently about '%2', but that "
					"seems to be %3. (Dialogue can only be about objects: "
					"people, things, rooms, that sort of stuff.)");
				Problems::issue_problem_end();
			}
		} else {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, A);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnrecognisedAboutTopic));
			Problems::issue_problem_segment(
				"The dialogue beat %1 is apparently about '%2', but that "
				"isn't something I recognise as an object. (Dialogue can "
				"only be about objects: people, things, rooms, that sort of stuff.)");
			Problems::issue_problem_end();
		}
	}
}


@

=
dialogue_line *current_dialogue_line = NULL;
dialogue_line *Dialogue::create_line(parse_node *PN) {
	if (dialogue_section_being_scanned == NULL) internal_error("line outside dialogue section");
	int L = Annotations::read_int(PN, dialogue_level_ANNOT);
	if (L < 0) L = 0;
	if (L >= MAX_DIALOGUE_LINE_NESTING) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OvernestedLine),
			"this dialogue line is indented further than I can cope with",
			"and indeed further than any human reader could really make sense of.");
		return NULL;
	}
	if ((L > 0) && (precursor_dialogue_lines[L-1] == NULL)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OrphanLine),
			"this dialogue line is indented too far",
			"and should either not be indented at all, or indented by just one tab "
			"stop from the line it is dependent on.");
		return NULL;
	}
	if (current_dialogue_beat == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LineWithoutBeat),
			"this dialogue line seems to appear before any beat has begun",
			"which is not allowed - every line has to be part of a 'beat', which "
			"has to be introduced with a bracketed paragraph looking like a stage "
			"direction in a play.");
		return NULL;
	}
	dialogue_line *dl = CREATE(dialogue_line);
	dl->line_name = EMPTY_WORDING;
	dl->line_at = PN;
	dl->owning_beat = current_dialogue_beat;
	dl->parent_line = NULL;
	if (L > 0) dl->parent_line = precursor_dialogue_lines[L-1];
	dl->child_line = NULL;
	dl->next_line = NULL;
	dl->compilation_data = RTDialogue::new_line(PN, dl);
	dl->speaker_text = EMPTY_WORDING;
	dl->speech_text = EMPTY_WORDING;
	
	current_dialogue_line = dl;

	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			<dialogue-line-clause>(CW);
			Annotations::write_int(clause, dialogue_line_clause_ANNOT, <<r>>);
		} else if (Node::is(clause, DIALOGUE_SPEAKER_NT)) {
			dl->speaker_text = CW;
		} else if (Node::is(clause, DIALOGUE_SPEECH_NT)) {
			dl->speech_text = CW;
		} else internal_error("damaged DIALOGUE_LINE_NT subtree");
	}

	int dialogue_line_name_count = 0;
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		switch (Annotations::read_int(clause, dialogue_line_clause_ANNOT)) {
			case LINE_NAME_DLC:	
				<dialogue-line-clause>(CW);
				current_dialogue_line->line_name = GET_RW(<dialogue-line-clause>, 1);
				dialogue_line_name_count++;
				break;
		}
	}
	if (dialogue_line_name_count > 1) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LineNamedTwice),
			"this dialogue line seems to be named more than once",
			"which is not allowed. It can be anonymous, but otherwise can only have "
			"one name.");
	}

	if (current_dialogue_beat->opening_line == NULL)
		current_dialogue_beat->opening_line = dl;
	else if (precursor_dialogue_lines[L])
		precursor_dialogue_lines[L]->next_line = dl;
	else
		precursor_dialogue_lines[L-1]->child_line = dl;

	precursor_dialogue_lines[L] = dl;
	for (int i=L+1; i<MAX_DIALOGUE_LINE_NESTING; i++) precursor_dialogue_lines[i] = NULL;

	wording W = dl->line_name;
	if (Wordings::empty(W)) {
		TEMPORARY_TEXT(faux_name)
		WRITE_TO(faux_name, "line-%d", dl->allocation_id + 1);
		W = Feeds::feed_text(faux_name);
		DISCARD_TEXT(faux_name)
	}
	pcalc_prop *prop = Propositions::Abstract::to_create_something(K_dialogue_line, W);
	Assert::true(prop, CERTAIN_CE);
	dl->as_instance = Instances::latest();

	return dl;
}

@

@e LINE_NAME_DLC from 1
@e GENERIC_DLC

=
<dialogue-line-clause> ::=
	this is the { ... line } |      ==> { LINE_NAME_DLC, - }
	...                             ==> { GENERIC_DLC, - }

@

=
void Dialogue::write_dlc(OUTPUT_STREAM, int c) {
	switch(c) {
		case LINE_NAME_DLC: WRITE("LINE_NAME"); break;
		case GENERIC_DLC: WRITE("GENERIC"); break;
		default: WRITE("?"); break;
	}
}
