[DialogueBeats::] Dialogue Beats.

To manage dialogue beats and to parse their cue paragraphs.

@h Dialogue.
This is still only partially implemented, and is aiming to implement the evolution
proposal IE-0009. See the test group |:dialogue| to exercise problem messages
in this area.

@h Scanning the dialogue sections in pass 0.
A few headings in the source text are marked as holding dialogue. Early in
Inform's run, a traverse is made (see //assertions: Passes through Major Nodes//),
during which the following function is called each time a heading is found.

Note that only sections, the lowest level of heading, can contain dialogue,
so as soon as any other heading is reached, dialogue finishes (unless it too
is so marked).

=
heading *dialogue_section_being_scanned = NULL;
dialogue_beat *previous_dialogue_beat = NULL;
dialogue_beat *current_dialogue_beat = NULL;
int dialogue_sections_are_present = FALSE;

void DialogueBeats::note_heading(heading *h) {
	if (h->holds_dialogue) dialogue_section_being_scanned = h;
	else dialogue_section_being_scanned = NULL;
	previous_dialogue_beat = NULL;
	current_dialogue_beat = NULL;
	dialogue_sections_are_present = TRUE;
	DialogueNodes::clear_precursors(0);
}

int DialogueBeats::dialogue_exists(void) {
	return dialogue_sections_are_present;
}

@h Beats.
The following is called each time the cue paragraph for a new beat is found:
a whole paragraph, which might, for example, read:
= (text as Inform 7)
	(About the carriage clock; this is the horological beat.)
=
|PN| is that text, but it has already been partially parsed:
= (text)
	DIALOGUE_CUE_NT
		DIALOGUE_CLAUSE_NT "About the carriage clock"
		DIALOGUE_CLAUSE_NT "this is the horological beat"
=
Here we have a simple tree where the beat node has any number of child nodes,
each of which is a |DIALOGUE_CLAUSE_NT|.

=
dialogue_beat *DialogueBeats::new(parse_node *PN) {
	@<See if we are expecting a dialogue beat@>;
	dialogue_beat *db = CREATE(dialogue_beat);
	Node::set_beat_defined_here(PN, db);
	wording DW = EMPTY_WORDING;
	int w1 = Annotations::read_int(PN, dialogue_during_text_w1_ANNOT);
	int w2 = Annotations::read_int(PN, dialogue_during_text_w2_ANNOT);
	wording W = Wordings::new(w1, w2);
	if ((w1 > 0) && (Wordings::nonempty(W))) DW = W;

	@<Initialise the beat@>;

	previous_dialogue_beat = current_dialogue_beat;
	current_dialogue_beat = db;
	DialogueNodes::clear_precursors(0);

	@<Parse the clauses just enough to classify them@>;
	@<Look through the clauses for a name@>;
	@<Add the beat to the world model@>;
	return db;
}

@ Note that a |DIALOGUE_CUE_NT| is only made under a section marked as containing
dialogue, so the internal error here should be impossible to hit.

@<See if we are expecting a dialogue beat@> =
	if (dialogue_section_being_scanned == NULL) internal_error("cue outside dialogue section");
	if (Annotations::read_int(PN, dialogue_level_ANNOT) > 0) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_IndentedBeat),
			"this dialogue beat seems to be indented",
			"which in dialogue would mean that it is part of something above it. "
			"But all beats (unlike lines) are free-standing, and should not be "
			"indented.");
	}

@ We represent beats internally as follows:

=
typedef struct dialogue_beat {
	struct wording beat_name;
	struct parse_node *cue_at;
	struct heading *under_heading;
	struct instance *as_instance;
	struct wording scene_name;
	struct scene *as_scene;
	struct wording during_scene_W;
	struct scene *during_scene;
	struct linked_list *required; /* of |instance| */
	int starting_beat;
	int requiring_nothing;

	struct parse_node *immediately_after;
	struct linked_list *some_time_after; /* of |parse_node| */
	struct linked_list *some_time_before; /* of |parse_node| */
	struct linked_list *about_list; /* of |parse_node| */

	struct dialogue_node *root;
	struct dialogue_beat_compilation_data compilation_data;
	CLASS_DEFINITION
} dialogue_beat;

@<Initialise the beat@> =
	db->beat_name = EMPTY_WORDING;
	db->scene_name = EMPTY_WORDING;
	db->cue_at = PN;
	db->under_heading = dialogue_section_being_scanned;
	db->as_instance = NULL;
	db->as_scene = NULL;
	db->during_scene = NULL;
	db->during_scene_W = DW;
	db->required = NEW_LINKED_LIST(instance);
	db->starting_beat = FALSE;
	db->requiring_nothing = FALSE;
	db->immediately_after = NULL;
	db->some_time_after = NEW_LINKED_LIST(parse_node);
	db->some_time_before = NEW_LINKED_LIST(parse_node);
	db->about_list = NEW_LINKED_LIST(parse_node);
	db->root = NULL;
	db->compilation_data = RTDialogueBeats::new_beat(PN, db);

@ Each clause can be one of about 10 possibilities, as follows, and the
wording tells us immediately which possibility it is, even early in the run.
We annotate each clause with the answer. Thus we might have:
= (text)
	DIALOGUE_CUE_NT
		DIALOGUE_CLAUSE_NT "About the carriage clock" {ABOUT_DBC}
		DIALOGUE_CLAUSE_NT "this is the horological beat" {BEAT_NAME_DBC}
=

@e BEAT_NAME_DBC from 1
@e SCENE_NAME_DBC
@e ABOUT_DBC
@e IF_DBC
@e UNLESS_DBC
@e AFTER_DBC
@e IMMEDIATELY_AFTER_DBC
@e BEFORE_DBC
@e REQUIRING_NOTHING_DBC
@e REQUIRING_DBC
@e LATER_DBC
@e NEXT_DBC
@e FULLY_RECURRING_DBC
@e PROPERTY_DBC

@<Parse the clauses just enough to classify them@> =
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		if (Node::is(clause, DIALOGUE_CLAUSE_NT)) {
			<dialogue-beat-clause>(CW);
			Annotations::write_int(clause, dialogue_beat_clause_ANNOT, <<r>>);
		} else internal_error("damaged DIALOGUE_CUE_NT subtree");
	}

@ Which is done with the following:

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
	requiring nothing |         ==> { REQUIRING_NOTHING_DBC, - }
	requiring ... |             ==> { REQUIRING_DBC, - }
	later |                     ==> { LATER_DBC, - }
	next |                      ==> { NEXT_DBC, - }
	fully recurring |           ==> { FULLY_RECURRING_DBC, - }
	...                         ==> { PROPERTY_DBC, - }

<dialogue-beat-starting-name> ::=
	starting beat

@ It's convenient to be able to read this back in the debugging log, so:

=
void DialogueBeats::write_dbc(OUTPUT_STREAM, int c) {
	switch(c) {
		case BEAT_NAME_DBC: WRITE("BEAT_NAME"); break;
		case SCENE_NAME_DBC: WRITE("SCENE_NAME"); break;
		case ABOUT_DBC: WRITE("ABOUT"); break;
		case IF_DBC: WRITE("IF"); break;
		case UNLESS_DBC: WRITE("UNLESS"); break;
		case AFTER_DBC: WRITE("AFTER"); break;
		case IMMEDIATELY_AFTER_DBC: WRITE("IMMEDIATELY_AFTER"); break;
		case BEFORE_DBC: WRITE("BEFORE"); break;
		case REQUIRING_DBC: WRITE("REQUIRING"); break;
		case REQUIRING_NOTHING_DBC: WRITE("REQUIRING_NOTHING"); break;
		case LATER_DBC: WRITE("LATER"); break;
		case NEXT_DBC: WRITE("NEXT"); break;
		case FULLY_RECURRING_DBC: WRITE("FULLY RECURRING"); break;
		case PROPERTY_DBC: WRITE("PROPERTY"); break;
		default: WRITE("?"); break;
	}
}

@ A beat can either be named |this is the WHATEVER beat|, or |this is the WHATEVER scene|,
but not of course both. If the latter, we construct the beat name itself as
|WHATEVER beat| and the name for its associated scene as |WHATEVER scene|.

@<Look through the clauses for a name@> =
	int dialogue_beat_name_count = 0;
	for (parse_node *clause = PN->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		switch (Annotations::read_int(clause, dialogue_beat_clause_ANNOT)) {
			case BEAT_NAME_DBC:	
				<dialogue-beat-clause>(CW);
				wording NW = GET_RW(<dialogue-beat-clause>, 1);
				if (<instance>(NW)) {
					instance *I = <<rp>>;
					DialogueBeats::non_unique_instance_problem(I, K_dialogue_beat);
				} else {
					current_dialogue_beat->beat_name = NW;
					if (<dialogue-beat-starting-name>(NW))
						current_dialogue_beat->starting_beat = TRUE;
				}
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
	if (dialogue_beat_name_count > 1)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BeatNamedTwice),
			"this dialogue beat seems to be named more than once",
			"which is not allowed. It can be anonymous, but otherwise can only have "
			"one name (either as a beat or as a scene, and not both).");

@ For the sake of translation, the above name reconstruction is done with the
following Preform nonterminal:

=
<dialogue-beat-name-construction> ::=
	... beat |
	... scene

@ The following creates a dialogue beat with the given name (or an invented name
failing that) and makes it an instance of the kind |K_dialogue_beat|. This kind
definitely exists, because it is created by |DialogueKit|, which the supervisor
module has automatically added to the project on spotting that dialogue is present
in the source text.

It's a little surprising, perhaps, that we do not also create the associated
scene instance (if there is one). But this is for timing reasons: we want the
default value of |scene| to be created by the Standard Rules, which will not
happen until the next pass through the source text. If we create a scene instance
here, it will be the first to be created, and will thus become the default.

@<Add the beat to the world model@> =
	wording W = db->beat_name;
	if (Wordings::empty(W)) {
		TEMPORARY_TEXT(faux_name)
		WRITE_TO(faux_name, "beat-%d", db->allocation_id + 1);
		W = Feeds::feed_text(faux_name);
		DISCARD_TEXT(faux_name)
	}
	if (K_dialogue_beat == NULL) internal_error("DialogueKit has not created K_dialogue_beat");
	pcalc_prop *prop = Propositions::Abstract::to_create_something(K_dialogue_beat, W);
	Assert::true(prop, CERTAIN_CE);
	db->as_instance = Instances::latest();

@ This is useful in other contexts, too.

=
void DialogueBeats::non_unique_instance_problem(instance *I, kind *K) {
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Instances::get_name(I, FALSE));
	Problems::quote_source(3, Instances::get_creating_sentence(I));
	Problems::quote_kind(4, Instances::to_kind(I));
	Problems::quote_kind(5, K);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_BeatNameNotUnique));
	Problems::issue_problem_segment(
		"%1 would like to make %5 called '%2', but there is %4 already called that "
		"(created at %3).");
	Problems::issue_problem_end();
}

@h During pass 1.
This is unfinished business (see above):

=
void DialogueBeats::make_tied_scene(parse_node *p) {
	dialogue_beat *db = Node::get_beat_defined_here(p);
	if ((db) && (Wordings::nonempty(db->scene_name))) {
		pcalc_prop *prop =
			Propositions::Abstract::to_create_something(K_scene, db->scene_name);
		Assert::true(prop, CERTAIN_CE);
		db->as_scene = Scenes::from_named_constant(Instances::latest());
		Scenes::set_beat(db->as_scene, db);
	}
	if ((db) && (Wordings::nonempty(db->during_scene_W))) {
		wording W = db->during_scene_W;
		scene *S = NULL;
		if (<instance>(W)) {
			instance *I = <<rp>>;
			S = Scenes::from_named_constant(I);
		}
		if (S == NULL) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, W);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(...));
			Problems::issue_problem_segment(
				"%1 would like to make a beat which, judging by its heading, "
				"should be restricted to the scene '%2'. But there is no such scene.");
			Problems::issue_problem_end();
		}
		db->during_scene = S;
	}
}

@h Processing beats after pass 1.
It's now a little later, and the following is called to look at each beat and
parse its clauses further.

=
void DialogueBeats::decide_cue_sequencing(void) {
	dialogue_beat *db, *previous = NULL;
	LOOP_OVER(db, dialogue_beat) {
		current_sentence = db->cue_at;
		@<Parse sequencing clauses@>;
		DialogueNodes::find_decisions_in_beat(db);
		previous = db;
	}
}

@ But now we take care of another five clause types, all to do with the beat being
performed only after or before other beats.

@<Parse sequencing clauses@> =
	int iac = 0;
	for (parse_node *clause = db->cue_at->down; clause; clause = clause->next) {
		wording CW = Node::get_text(clause);
		int c = Annotations::read_int(clause, dialogue_beat_clause_ANNOT);
		switch (c) {
			case NEXT_DBC:
				if ((previous) && (previous->under_heading == db->under_heading)) {
					iac++;
					db->immediately_after = Rvalues::from_instance(previous->as_instance);
				} else {
					@<Issue PM_NoPreviousBeat problem@>;
				}
				break;
			case LATER_DBC:
				if ((previous) && (previous->under_heading == db->under_heading)) {
					parse_node *desc = Rvalues::from_instance(previous->as_instance);
					ADD_TO_LINKED_LIST(desc, parse_node, db->some_time_after);
				} else {
					@<Issue PM_NoPreviousBeat problem@>;
				}
				break;
			case IMMEDIATELY_AFTER_DBC:
			case AFTER_DBC:
			case BEFORE_DBC: {
				<dialogue-beat-clause>(CW);
				wording A = GET_RW(<dialogue-beat-clause>, 1);
				<np-articled-list>(A);
				parse_node *AL = <<rp>>;
				DialogueBeats::parse_beat_list(c, db, AL, &iac);
				break;
			}
			case REQUIRING_DBC: {
				<dialogue-beat-clause>(CW);
				wording A = GET_RW(<dialogue-beat-clause>, 1);
				<np-articled-list>(A);
				parse_node *AL = <<rp>>;
				DialogueBeats::parse_required_speaker_list(db, AL);
				break;
			}
			case REQUIRING_NOTHING_DBC:
				db->requiring_nothing = TRUE;
				break;
		}
	}
	if (iac > 1) 
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DoubleImmediateBeat),
			"this dialogue beat asks to be immediately after two or more other beats",
			"either with 'next' or 'immediately after'. It can only give one.");

@<Issue PM_NoPreviousBeat problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NoPreviousBeat),
		"this dialogue beat asks to be performed after the previous one",
		"but in this dialogue section, there is no previous one.");

@ Syntactically, these clauses all take articled lists: |after X, Y and Z|, for
example. The following burrows through the resulting subtree, in which each of
|X|, |Y| and |Z| would be an |UNPARSED_NOUN_NT| node.

Semantically, we can only be immediately after one beat, so we keep a count of
those in order to produce a problem if there are too many. With regular "after"
and "before", there are no limits.

=
void DialogueBeats::parse_beat_list(int c, dialogue_beat *db, parse_node *AL, int *iac) {
	if (Node::is(AL, AND_NT)) {
		DialogueBeats::parse_beat_list(c, db, AL->down, iac);
		DialogueBeats::parse_beat_list(c, db, AL->down->next, iac);
	} else if (Node::is(AL, UNPARSED_NOUN_NT)) {
		switch(c) {
			case IMMEDIATELY_AFTER_DBC: {
				wording B = Node::get_text(AL);
				parse_node *desc = DialogueBeats::parse_beat_name(B);
				if (desc) {
					(*iac)++;
					db->immediately_after = desc;
				}
				break;
			}
			case AFTER_DBC: {
				wording B = Node::get_text(AL);
				parse_node *desc = DialogueBeats::parse_beat_name(B);
				if (desc) ADD_TO_LINKED_LIST(desc, parse_node, db->some_time_after);
				break;
			}
			case BEFORE_DBC: {
				wording B = Node::get_text(AL);
				parse_node *desc = DialogueBeats::parse_beat_name(B);
				if (desc) ADD_TO_LINKED_LIST(desc, parse_node, db->some_time_before);
				break;
			}
		}
	}
}

void DialogueBeats::parse_required_speaker_list(dialogue_beat *db, parse_node *AL) {
	if (Node::is(AL, AND_NT)) {
		DialogueBeats::parse_required_speaker_list(db, AL->down);
		DialogueBeats::parse_required_speaker_list(db, AL->down->next);
	} else if (Node::is(AL, UNPARSED_NOUN_NT)) {
		wording B = Node::get_text(AL);
		if (<s-type-expression-uncached>(B)) {
			parse_node *desc = <<rp>>;
			instance *I = Rvalues::to_instance(desc);
			if (I) {
				kind *K = Instances::to_kind(I);
				if (Kinds::Behaviour::is_object(K)) {
					ADD_TO_LINKED_LIST(I, instance, db->required);
					return;
				}
			}
		}
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, B);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NotASpeaker));
		Problems::issue_problem_segment(
			"The dialogue beat %1 apparently requires a speaker (other than the player) "
			"called '%2' to be present in order for it to be performed, but there's "
			"nobody of that name.");
		Problems::issue_problem_end();
	}
}

parse_node *DialogueBeats::parse_beat_name(wording CW) {
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

@h Processing beats after pass 2.
It's now later still. At this point all constant values have been created, and
therefore we can safely parse |ABOUT| and |PROPERTY| clauses. Again, these are
syntactically articled lists.

=
void DialogueBeats::decide_cue_topics(void) {
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
					DialogueBeats::parse_topic(db->about_list, AL, DIALOGUE_CUE_NT);
					break;
				}
				case PROPERTY_DBC: {
					<dialogue-beat-clause>(CW);
					wording A = GET_RW(<dialogue-beat-clause>, 1);
					<np-articled-list>(A);
					parse_node *AL = <<rp>>;
					DialogueBeats::parse_property(db, AL);
					break;
				}
				case FULLY_RECURRING_DBC:
					DialogueBeats::make_fully_recurring(db);
					break;
			}
		}
	}
}

@ Topics are picked up here. For example, |about the carriage clock| results
in the |UNPARSED_NOUN_NT| node "carriage clock".

=
void DialogueBeats::parse_topic(linked_list *about_list, parse_node *AL, unsigned int nt) {
	if (Node::is(AL, AND_NT)) {
		DialogueBeats::parse_topic(about_list, AL->down, nt);
		DialogueBeats::parse_topic(about_list, AL->down->next, nt);
	} else if (Node::is(AL, UNPARSED_NOUN_NT)) {
		wording A = Node::get_text(AL);
		if (<s-type-expression-uncached>(A)) {
			parse_node *desc = <<rp>>;
			kind *K = Specifications::to_kind(desc);
			if ((Kinds::eq(K, K_object)) || (Kinds::Behaviour::is_subkind_of_object(K))) {
				ADD_TO_LINKED_LIST(desc, parse_node, about_list);
			} else {
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, A);
				Problems::quote_kind(3, K);
				if (nt == DIALOGUE_CUE_NT) {
					Problems::quote_stream(4, I"beat");
					Problems::quote_stream(5, I"about");
				} else {
					Problems::quote_stream(4, I"line");
					Problems::quote_stream(5, I"to mention");
				}
				StandardProblems::handmade_problem(Task::syntax_tree(),
					_p_(PM_NotAnAboutTopic));
				Problems::issue_problem_segment(
					"The dialogue %4 %1 is apparently %5 '%2', but that "
					"seems to be %3. (Dialogue can only be about objects: "
					"people, things, rooms, that sort of stuff.)");
				Problems::issue_problem_end();
			}
		} else {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, A);
			if (nt == DIALOGUE_CUE_NT) {
				Problems::quote_stream(4, I"beat");
				Problems::quote_stream(5, I"about");
			} else {
				Problems::quote_stream(4, I"line");
				Problems::quote_stream(5, I"to mention");
			}
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_UnrecognisedAboutTopic));
			Problems::issue_problem_segment(
				"The dialogue %4 %1 is apparently %5 '%2', but that "
				"isn't something I recognise as an object. (Dialogue can "
				"only be about objects: people, things, rooms, that sort of stuff.)");
			Problems::issue_problem_end();
		}
	}
}

@ And properties are picked up here. So |recurring| or |spontaneous|, for
example, might be valid. The rule is that any text given must be either the
name of an either/or property or condition which a dialogue beat can have.

=
void DialogueBeats::parse_property(dialogue_beat *db, parse_node *AL) {
	if (Node::is(AL, AND_NT)) {
		DialogueBeats::parse_property(db, AL->down);
		DialogueBeats::parse_property(db, AL->down->next);
	} else if (Node::is(AL, UNPARSED_NOUN_NT)) {
		wording A = Node::get_text(AL);
		if (<s-value-uncached>(A)) {
			parse_node *val = <<rp>>;
			if (Rvalues::is_CONSTANT_construction(val, CON_property)) {
				property *prn = Rvalues::to_property(val);
				if (Properties::is_either_or(prn)) {
					DialogueBeats::apply_property(db, prn);
					return;
				}
			}
			if ((Specifications::is_description(val)) || (Node::is(val, TEST_VALUE_NT))) {
				DialogueBeats::apply_property_value(db, val);
				return;
			}
			LOG("Unexpected prop: $T\n", val);
		} else {
			LOG("Unrecognised prop: '%W'\n", A);
		}
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, A);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_UnrecognisedBeatProperty));
		Problems::issue_problem_segment(
			"The dialogue beat %1 should apparently be '%2', but that "
			"isn't something I recognise as a property which a beat can have.");
		Problems::issue_problem_end();
	}
}

@ Note the introduction into the propositions of the atom |dialogue-beat(x)|,
in order to ensure that typechecking of the proposition will correctly spot
that |x| has kind |dialogue beat|; without that, there would be problem
messages because |x| would be assumed as an |object|.

Basically, though, this asserts the property in the same way that assertion
sentences would do, and using all of the same machinery.

=
void DialogueBeats::apply_property(dialogue_beat *db, property *prn) {
	inference_subject *subj = Instances::as_subject(db->as_instance);
	pcalc_prop *prop = AdjectivalPredicates::new_atom_on_x(
		EitherOrProperties::as_adjective(prn), FALSE);
	prop = Propositions::concatenate(
		Propositions::Abstract::prop_to_set_kind(K_dialogue_beat), prop);
	Assert::true_about(prop, subj, CERTAIN_CE);
}

void DialogueBeats::apply_property_value(dialogue_beat *db, parse_node *val) {
	inference_subject *subj = Instances::as_subject(db->as_instance);
	pcalc_prop *prop = Descriptions::to_proposition(val);
	if (prop) {
		prop = Propositions::concatenate(
			Propositions::Abstract::prop_to_set_kind(K_dialogue_beat), prop);
		Assert::true_about(prop, subj, CERTAIN_CE);
	}
}

@ Making a beat fully recurring propagates its `recurring` property down through
all of the lines and choices within:

=
void DialogueBeats::make_fully_recurring(dialogue_beat *db) {
	DialogueBeats::apply_property(db, P_recurring);
	DialogueBeats::make_fully_recurring_r(db->root);
}

void DialogueBeats::make_fully_recurring_r(dialogue_node *node) {
	for (; node; node = node->next_node) {
		if (node->if_line) DialogueLines::apply_property(node->if_line, P_recurring);
		if (node->if_choice) DialogueChoices::apply_property(node->if_choice, P_recurring);
		if (node->child_node) DialogueBeats::make_fully_recurring_r(node->child_node);
	}
}					

@ So what remains to be done? Only the parsing of |IF| and |UNLESS| clauses,
which take arbitrary conditions. There's no need to do that here: we can do
that when compiling the runtime representation of a beat. See //runtime: Dialogue Beat Instances//.
