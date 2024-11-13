[MajorNodes::] Passes through Major Nodes.

To manage the overall process of traversing the parse tree for top-level
declarations and assertion sentences.

@ The first thing Inform does when compiling source text is to make three
passes through its top-level definitions: a "pre-pass", in which names of
things like tables and equations are discovered, and assertion sentences
are diagrammed; "pass 1", when instance, kinds, properties and so on are
created; and "pass 2", when property values and relationships are found.

=
void MajorNodes::pre_pass(void) {
	MajorNodes::traverse(0);
}
void MajorNodes::pass_1(void) {
	MajorNodes::traverse(1);
}
void MajorNodes::pass_2(void) {
	MajorNodes::traverse(2);
}

@ During these passes, some global state is kept here. This is not elegant,
but saves a deal of passing parameters around.

=
typedef struct pass_state {
	int pass; /* during a pass, 0, 1 or 2: 0 is the pre-pass */
	int near_start_of_extension;
	struct parse_node *assembly_position;
	struct inference_subject *object_of_sentences;
	struct inference_subject *subject_of_sentences;
	int subject_seems_to_be_plural;
} pass_state;

pass_state global_pass_state = { -1, 0, NULL, NULL, NULL, FALSE };

void MajorNodes::traverse(int pass) {
	global_pass_state.pass = pass;
	global_pass_state.near_start_of_extension = 0;
	global_pass_state.assembly_position = NULL;
	global_pass_state.object_of_sentences = NULL;
	global_pass_state.subject_of_sentences = NULL;
	global_pass_state.subject_seems_to_be_plural = FALSE;
	SyntaxTree::clear_trace(Task::syntax_tree());
	Anaphora::new_discussion();

	parse_node *last = NULL;
	SyntaxTree::traverse_nodep(Task::syntax_tree(), MajorNodes::visit, &last);

	if (pass == 1) @<Extend the pass to invented sentences from kinds@>;
	if (pass == 2) @<Extend the pass to sentences needed when implicit kinds are set@>;
}

@<Extend the pass to invented sentences from kinds@> =
	parse_node *extras = last;
	Task::add_kind_inventions();
	current_sentence = extras;
	global_pass_state.assembly_position = extras;
	global_pass_state.pass = 0;
	SyntaxTree::traverse_nodep_from(extras, MajorNodes::visit, &last);
	current_sentence = extras;
	global_pass_state.assembly_position = extras;
	global_pass_state.pass = 1;
	SyntaxTree::traverse_nodep_from(extras, MajorNodes::visit, &last);

@ Here's a tricky timing problem, or rather, here's the fix for it. Assemblies
are made when the kinds of objects are set, and they're made by inserting
appropriate sentences. For instance, given the generalisation:

>> Every room contains a vehicle.

we would insert the following sentence into the tree:

>> Ballroom West contains a vehicle.

as soon as we discover that Ballroom West is a room. That works fine if we
discover this fact during traverses 1 or 2, but sometimes the room-ness of
a room cannot be established until the world model is constructed. So we
call the model-maker right now, and prolong pass 2 artificially to pick up
any additional sentences generated.

@<Extend the pass to sentences needed when implicit kinds are set@> =
	current_sentence = last;
	global_pass_state.assembly_position = current_sentence;
	World::deduce_object_instance_kinds();
	SyntaxTree::traverse_nodep_from(last, MajorNodes::visit, &last);

@ Let us go, and make our visit:

=
void MajorNodes::visit(parse_node *p, parse_node **last) {
	global_pass_state.assembly_position = current_sentence;
	*last = p;
	@<Deal with an individual major node@>;
}

@ Headings cause us to begin a fresh topic of discussion, on a fresh piece of
paper, as it were: this wipes out any meanings of pronouns like "it" making
anaphoric references to previous sentences. In other respects, headings are for
organisation, and are not directly functional in themselves.

@<Deal with an individual major node@> =
	if ((SyntaxTree::is_trace_set(Task::syntax_tree())) && (Node::get_type(p) != TRACE_NT))
		LOG("\n[%W]\n", Node::get_text(p));

	switch (Node::get_type(p)) {
		case ROOT_NT: break;

		case HEADING_NT:   Anaphora::new_discussion();
						   if (global_pass_state.pass == 0) 
						       DialogueBeats::note_heading(Headings::from_node(p));
						   break;
		
		case BEGINHERE_NT: Anaphora::new_discussion();
			               global_pass_state.near_start_of_extension = 1; break;
		case ENDHERE_NT:   Anaphora::new_discussion();
			               global_pass_state.near_start_of_extension = 0; break;

		case IMPERATIVE_NT: @<Pass through an IMPERATIVE node@>; break;
		case DEFN_CONT_NT: break;

		case SENTENCE_NT: @<Pass through a SENTENCE node@>; break;
		case TRACE_NT: @<Pass through a TRACE node@>; break;

		case TABLE_NT: if (global_pass_state.pass == 0) Tables::create_table(p);
			break;
		case EQUATION_NT: if (global_pass_state.pass == 0) Equations::new_at(p, FALSE);
			break;
		case INFORM6CODE_NT:
			if (global_pass_state.pass == 2) InterventionRequests::make(p);
			break;
		case BIBLIOGRAPHIC_NT:
			#ifdef IF_MODULE
			if (global_pass_state.pass == 2) BibliographicData::bibliographic_data(p);
			#endif
			break;

		case DIALOGUE_CUE_NT: 
			if (global_pass_state.pass == 0) DialogueBeats::new(p);
			if (global_pass_state.pass == 1) DialogueBeats::make_tied_scene(p);
			break;
		case DIALOGUE_CHOICE_NT: 
			if (global_pass_state.pass == 0) DialogueChoices::new(p);
			break;
		case DIALOGUE_LINE_NT:
			if (global_pass_state.pass == 0) DialogueLines::new(p);
			break;

		case INVOCATION_LIST_NT:  break; /* for error recovery; shouldn't be here otherwise */
		case UNKNOWN_NT: break; /* for error recovery; shouldn't be here otherwise */

		default:
			LOG("$T\n", p);
			internal_error("passed through major node of unexpected type");
	}

@ This is a little convoluted: see //Imperative Subtrees// for how
"acceptance" tidies up the nodes in the syntax tree corresponding to a block
of imperative code.

@<Pass through an IMPERATIVE node@> =
	if (global_pass_state.pass == 0)
		SyntaxTree::traverse_run(p, ImperativeSubtrees::accept, IMPERATIVE_NT);

@ |SENTENCE_NT| nodes are by far the most varied and difficult. In the pre-pass,
we call //Classifying::sentence// to have them diagrammed, which determines
whether they have special or regular meanings.

@<Pass through a SENTENCE node@> =
	if (global_pass_state.pass == 0) {
		Classifying::sentence(p);
	} else {
		if (SyntaxTree::is_trace_set(Task::syntax_tree())) LOG("$T", p);
		if ((Annotations::read_int(p, language_element_ANNOT) == FALSE) &&
			(Annotations::read_int(p, you_can_ignore_ANNOT) == FALSE)) {
			if (Classifying::sentence_is_textual(p)) {
				if (global_pass_state.pass == 2) {
					prevailing_mood = UNKNOWN_CE;
					Assertions::make_appearance(p);
				}
			} else {
				if (p->down == NULL) internal_error("sentence misclassified");
				internal_error_if_node_type_wrong(Task::syntax_tree(), p->down, VERB_NT);
				prevailing_mood = Annotations::read_int(p->down, verbal_certainty_ANNOT);
				if (Node::get_special_meaning(p->down)) @<Act on special meaning@>
				else @<Act on regular meaning@>;
			}
		}
	}

@ Special meanings are handled just by calling the relevant SMF functions
with one of the following task codes. They don't get the benefit of
"refinement" (see below) unless they arrange for it themselves.

@e PASS_1_SMFT
@e PASS_2_SMFT

@<Act on special meaning@> =
	if (global_pass_state.pass == 1)
		MajorNodes::try_special_meaning(PASS_1_SMFT, p->down);
	if (global_pass_state.pass == 2)
		MajorNodes::try_special_meaning(PASS_2_SMFT, p->down);

@ Regular meanings are more subtle: on pass 1, we "refine" them, which means
identifying unparsed noun phrases. //Refiner::refine_coupling//
returns |TRUE| if it succeeds in this.

After that, there are two cases: existential sentences (such as "there are
two cases") and all others (such as "regular meanings are more subtle").

The trickiest form is "There is a container with carrying capacity 30", say,
which equates |DEFECTIVE_NOUN_NT| with |WITH_NT|. This is somehow both cases
at once, and we have to perform both an existential assertion and a coupling.

@<Act on regular meaning@> =
	parse_node *px = p->down->next;
	parse_node *py = px->next;
	if ((global_pass_state.pass > 1) ||
		(Refiner::refine_coupling(px, py, FALSE))) {
		if (Node::get_type(px) == DEFECTIVE_NOUN_NT) {
			Assertions::make_existential(py);
			if (Node::get_type(py) == WITH_NT) {
				px = py->down;
				py = py->down->next;
				Annotations::write_int(current_sentence->down, sentence_is_existential_ANNOT, FALSE);
				Assertions::make_coupling(px, py);
				Anaphora::change_discussion_from_coupling(px, py);
			} else {
				Anaphora::change_discussion_from_coupling(py, py);
			}
		} else {
			Assertions::make_coupling(px, py);
			Anaphora::change_discussion_from_coupling(px, py);
		}
	}

@ =
void MajorNodes::try_special_meaning(int task, parse_node *p) {
	SpecialMeanings::call(Node::get_special_meaning(p), task, p, NULL);
}

@ A few "invention" sentences only come along later than the pre-pass, which
means they miss out on being classified at that time. When that happens, the
//syntax// module signals us by calling this function:

@d NEW_NONSTRUCTURAL_SENTENCE_SYNTAX_CALLBACK MajorNodes::extra_sentence

=
void MajorNodes::extra_sentence(parse_node *new) {
	if (global_pass_state.pass >= 0) Classifying::sentence(new);
}

@ |TRACE_NT| nodes result from asterisked sentences; this is a debugging feature of
Inform. An asterisk on its own toggles logging of work on sentences.

=
@<Pass through a TRACE node@> =
	SyntaxTree::toggle_trace(Task::syntax_tree());
	text_stream *pass_name = NULL;
	switch (global_pass_state.pass) {
		case 0: pass_name = I"Pre-Pass"; break;
		case 1: pass_name = I"Pass 1"; break;
		case 2: pass_name = I"Pass 2"; break;
	}
	Log::tracing_on(SyntaxTree::is_trace_set(Task::syntax_tree()), pass_name);

@

@d TRACING_LINGUISTICS_CALLBACK MajorNodes::trace_parsing

=
int MajorNodes::trace_parsing(int A) {
	if (SyntaxTree::is_trace_set(Task::syntax_tree())) return TRUE;
	return FALSE;
}
