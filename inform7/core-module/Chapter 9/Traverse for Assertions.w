[Assertions::Traverse::] Traverse for Assertions.

To manage the overall process of traversing the parse tree for
assertion sentences.

@h Definitions.

@ A "traverse" of the tree is a sentence-by-sentence walk through it,
taking action at each point. Because Inform holds the entire parse tree in
memory at once, this is the same thing as what used to be called a pass
through the source code.

Because Inform syntax requires little in the way of pre-declarations, and
Inform can accept the same material in many arrangements, we get around
timing problems -- needing to know X before Y -- by traversing the tree
many times over. There is little speed penalty for this.

But the majority of the work is done on two main traverses, so that Inform
behaves like a traditional two-pass compiler when reading assertions.
The following global variable indicates which pass we're in.

During the main assertion traverses, we also keep track of whether we
are near the start of an extension file or not. (If we are, then a lone
string of text is interpreted as the rubric of the extension -- an
exception to Inform's normal rules.)

@e TRAVERSE1_SMFT
@e TRAVERSE2_SMFT
@e TRAVERSE_FOR_RULE_FILING_SMFT
@e TRAVERSE_FOR_GRAMMAR_SMFT
@e TRAVERSE_FOR_MAP1_SMFT
@e TRAVERSE_FOR_MAP2_SMFT
@e TRAVERSE_FOR_MAP_INDEX_SMFT
@e ALLOW_IN_OPTIONS_FILE_SMFT

= (early code)
int traverse; /* always 1 or 2 */
int near_start_of_extension = 0;

@ Within each main traverse, we look at each sentence and decide which
part of Inform will deal with it.

Sentence handlers provide an abstraction for that choice of what to do
with each kind of sentence, on each traverse. This is really only a
disguise for a couple of |switch| statements and a lot of function calls.
The only real purpose is to make it easier to encapsulate code for one sort
of sentence away from the others: if we were writing |C++| or Python, it
would just be a method in the class for sentences.

Properly speaking, there can be sentence handlers for any node type at the
children-of-root level of the parse tree, although we mostly use this for
|SENTENCE_NT| nodes (and then we look further at the verb type in the |VERB_NT|
first child). The main traverse is a two-pass operation, and we can supply
a routine to do something with the node on either of the passes (or neither,
or even both).

=
typedef struct sentence_handler {
	node_type_t sentence_node_type; /* usually but not always |SENTENCE_NT| */
	int verb_type; /* for those which are indeed |SENTENCE_NT| */
	int handle_on_traverse; /* 1 or 2 to restrict to that pass, or 0 for both */
	void (*handling_routine)(struct parse_node *PN); /* or NULL not to handle */
} sentence_handler;

@ A global array -- really a jump table -- records who does what:

@d MAX_OF_NTS_AND_VBS 75

=
sentence_handler *how_to_handle_nodes[MAX_OF_NTS_AND_VBS]; /* for non-|SENTENCE_NT| nodes */

@ We recognise either node types |*_NT|, or node type |SENTENCE_NT| plus an
associated verb number |*_VB|. The following macro registers a sentence handler
by entering a pointer to it into one of the above tables:

@d REGISTER_SENTENCE_HANDLER(sh_name) {
	sentence_handler *the_sh = &sh_name##_handler;
		how_to_handle_nodes[the_sh->sentence_node_type - ENUMERATED_NT_BASE] = the_sh;
}

@ The actual handlers are mostly not declared here (indeed, that's the
point of the whole exercise -- to allow them to be decentralised). But we
do need to know their names, so every |*_SH| constant below must correspond
to a sentence handler structure called |*_SH_handler| defined somewhere
else in the program.

@h Performing the traverse.
The following routine is called twice, once with |pass| equal to 1, then
with |pass| equal to 2.

|trace_sentences| is true between each pair of |TRACE_NT| nodes, if there
are any: these arise from the special debugging sentence consisting only
of an asterisk. When tracing, we print an account of what is being read to
the debugging log (both here, and in more detail elsewhere), except that
we don't bother to print details of the closing |TRACE_NT| node.

=
int sentence_handlers_initialised = FALSE;
parse_node *assembly_position = NULL; /* where assembled sentences are added */

void Assertions::Traverse::traverse1(void) {
	Assertions::Traverse::traverse(1);
}
void Assertions::Traverse::traverse2(void) {
	Assertions::Traverse::traverse(2);
}
void Assertions::Traverse::traverse(int pass) {
	Assertions::Traverse::new_discussion(); /* clear memory of what the subject and object of discussion are */
	traverse = pass;
	SyntaxTree::clear_trace(Task::syntax_tree());

	if (sentence_handlers_initialised == FALSE) @<Initialise sentence handlers@>;

	parse_node *last = NULL;
	SyntaxTree::traverse_nodep(Task::syntax_tree(), Assertions::Traverse::visit, &last);

	if (pass == 2) @<Extend the traverse to cover sentences needed when implicit kinds are set@>;
}

@ Here's a tricky timing problem, or rather, here's the fix for it. Assemblies
are made when the kinds of objects are set, and they're made by inserting
appropriate sentences. For instance, given the generalisation:

>> Every room contains a vehicle.

we would insert the following sentence into the tree:

>> Ballroom West contains a vehicle.

as soon as we discover that Ballroom West is a room. That works fine if we
discover this fact during traverses 1 or 2, but sometimes it can only be
known during the "positioning" stage, after traverse 2, when we look over
all the inferences drawn about Ballroom West. It's then too late to insert
any new sentences, or rather, it's too late to act on them.

So what we do is to call |position_objects| from the model-maker to make
any such deductions right at the end of traverse 2, and insert any sentences
arising right at the end of the source text. We then prolong traverse 2
artificially to run through those sentences.

@<Extend the traverse to cover sentences needed when implicit kinds are set@> =
	current_sentence = last;
	assembly_position = current_sentence;
	Plugins::Call::complete_model(1);
	SyntaxTree::traverse_nodep_from(last, Assertions::Traverse::visit, &last);

@ Let us go, and make our visit:

=
void Assertions::Traverse::visit(parse_node *p, parse_node **last) {
	assembly_position = current_sentence;
	compilation_unit *cm = CompilationUnits::current();
	CompilationUnits::set_current(p);
	@<Take a sceptical look at WITH nodes in the light of subsequent knowledge@>;
	*last = p;
	@<Deal with an individual sentence@>;
	CompilationUnits::set_current_to(cm);
}

@ If this hasn't already been done:

@<Initialise sentence handlers@> =
	sentence_handlers_initialised = TRUE;
	@<Empty the sentence handler tables@>;
	SHR::register_sentence_handlers();

@ At this stage, all we do is empty the tables. The reason we have to delay
before entering the valid handlers is that some of them will be defined in
sections appearing after this one in the program: since C requires all
identifiers used to be predeclared, this means we can't enter the valid
handlers until right at the end of the program. The routine which does so,
|SHR::register_sentence_handlers|, consists only of a run of
|REGISTER_SENTENCE_HANDLER| macro expansions and can be found in Chapter
14.

@<Empty the sentence handler tables@> =
	for (int i=0; i<MAX_OF_NTS_AND_VBS; i++) how_to_handle_nodes[i] = NULL;

@<Take a sceptical look at WITH nodes in the light of subsequent knowledge@> =
	if ((p->down) && (p->down->next)) {
		parse_node *apparent_subject = p->down->next;
		if ((Node::get_type(apparent_subject) == WITH_NT) &&
			(apparent_subject->down) &&
			(apparent_subject->down->next)) {
			wording W = Wordings::up_to(Node::get_text(apparent_subject->down),
				Wordings::last_wn(Node::get_text(apparent_subject->down->next)));
			parse_node *ap = Lexicon::retrieve(MISCELLANEOUS_MC, W);
			if (Rvalues::is_CONSTANT_of_kind(ap, K_action_name)) {
				Node::set_type_and_clear_annotations(apparent_subject, PROPER_NOUN_NT);
				Node::set_text(apparent_subject, W);
				apparent_subject->down = NULL;
			}
		}
	}

@<Deal with an individual sentence@> =
	if ((SyntaxTree::is_trace_set(Task::syntax_tree())) && (Node::get_type(p) != TRACE_NT))
		LOG("\n[%W]\n", Node::get_text(p));

	@<If this sentence can be handled, then do so and continue@>;

	LOG("$T\n", p);
	internal_error("uncaught assertion");

@ Note that it's entirely open for the sentence handler to choose to do nothing
on either or both traverses, so the inner |if| can happily fail.

@<If this sentence can be handled, then do so and continue@> =
	if (Node::get_type(p) == ROOT_NT) return;
	#ifndef IF_MODULE
	if (Node::get_type(p) == BIBLIOGRAPHIC_NT) return;
	#endif

	int n = (int) (Node::get_type(p) - ENUMERATED_NT_BASE);
	if (((n >= 0) && (n < MAX_OF_NTS_AND_VBS)) && (how_to_handle_nodes[n])) {
		int desired = how_to_handle_nodes[n]->handle_on_traverse;
		if (((traverse == desired) || (desired == 0)) &&
			(how_to_handle_nodes[n]->handling_routine))
			(*(how_to_handle_nodes[n]->handling_routine))(p);
		return;
	}

@h The TRACE sentence handler.
While most of the sentence handlers are scattered across the rest of Inform,
two will be given here. The first is the one which acts on |TRACE_NT| asterisks;
this is a debugging feature of Inform. An asterisk on its own toggles logging
of work on sentences. An asterisk followed by double-quoted text is a note
for the telemetry file.

=
sentence_handler TRACE_SH_handler =
	{ TRACE_NT, -1, 0, Assertions::Traverse::switch_sentence_trace };

void Assertions::Traverse::switch_sentence_trace(parse_node *PN) {
	if (Wordings::length(Node::get_text(PN)) > 1) {
		int tr = telemetry_recording;
		telemetry_recording = TRUE;
		Telemetry::write_to_telemetry_file(Lexer::word_text(Wordings::last_wn(Node::get_text(PN))));
		telemetry_recording = FALSE;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TelemetryAccepted),
			"that's a message for the Author, not me",
			"so I'll note it down in the Telemetry file (if you're keeping one.)");
		 telemetry_recording = tr;
	} else {
		SyntaxTree::toggle_trace(Task::syntax_tree());
		if (traverse == 1) Log::tracing_on(SyntaxTree::is_trace_set(Task::syntax_tree()), I"Pass 1");
		else Log::tracing_on(SyntaxTree::is_trace_set(Task::syntax_tree()), I"Pass 2");
	}
}

@h The SENTENCE sentence handler.
The other special case is the handler for |SENTENCE_NT| itself.

=
sentence_handler SENTENCE_SH_handler =
	{ SENTENCE_NT, -1, 0, Assertions::Traverse::handle_sentence_with_primary_verb };

int Assertions::Traverse::special(parse_node *p) {
	if (Node::get_special_meaning(p)) return TRUE;
	return FALSE;
}

void Assertions::Traverse::handle_sentence_with_primary_verb(parse_node *p) {
	if (Annotations::read_int(p, language_element_ANNOT)) return;
	if (Annotations::read_int(p, you_can_ignore_ANNOT)) return;

	if (p->down == NULL) @<Handle a sentence with no primary verb@>;
	internal_error_if_node_type_wrong(Task::syntax_tree(), p->down, VERB_NT);
	prevailing_mood = Annotations::read_int(p->down, verbal_certainty_ANNOT);
	@<Act on the primary verb in the sentence@>;
}

@ A sentence node with no children indicates that we couldn't find any verb
earlier. This might just be a piece of quoted matter which is intended as
the description or initial appearance of the most recent object, but in all
other eventualities we must produce a "no such sentence" problem.

@<Handle a sentence with no primary verb@> =
	if (Classifying::sentence_is_textual(p)) {
		if (traverse == 2) {
			prevailing_mood = UNKNOWN_CE;
			Assertions::Traverse::set_appearance(Wordings::first_wn(Node::get_text(p)));
		}
		return;
	}
	internal_error("sentence unclassified");

@ We now use the other sentence-handler table, with almost the same code as
for the first (above). A small point of difference is that it's allowed for
a valid verb number to have no handler: if so, we handle the verb by doing
nothing on either traverse, of course.

@<Act on the primary verb in the sentence@> =
	if (Assertions::Traverse::special(p->down)) Assertions::Traverse::special_meaning(p);
	else Assertions::Copular::assertion(p);

@ The "appearance" is not a property as such. When a quoted piece of text
is given as a whole sentence, it might be:

(a) the "description" of a room or thing;
(b) the title of the whole work, if at the top of the main source; or
(c) the rubric of the extension, or the additional credits for an extension,
if near the top of an extension file.

The title of the work is handled elsewhere, so we worry only about (a) and (c).

=
void Assertions::Traverse::set_appearance(int wn) {
	if (near_start_of_extension >= 1) @<This is rubric or credit text for an extension@>;

	inference_subject *infs = Assertions::Traverse::get_current_subject();
	if (infs == NULL) @<Issue a problem for appearance without object@>;

	parse_node *spec = Rvalues::from_wording(Wordings::one_word(wn));
	Properties::Appearance::infer(infs, spec);
}

@ The variable |near_start_of_extension| is always 0 except at the start of
an extension (immediately after the header line), when it is set to 1. The
following increments it to 2 to allow for up to two quoted lines; the first
is the rubric, the second the credit line.

@<This is rubric or credit text for an extension@> =
	source_file *pos = Lexer::file_of_origin(wn);
	inform_extension *E = Extensions::corresponding_to(pos);
	if (E) {
		Word::dequote(wn);
		TEMPORARY_TEXT(txt)
		WRITE_TO(txt, "%W", Wordings::one_word(wn));
		switch (near_start_of_extension++) {
			case 1: Extensions::set_rubric(E, txt); break;
			case 2: Extensions::set_extra_credit(E, txt);
				near_start_of_extension = 0; break;
		}
		DISCARD_TEXT(txt)
	}
	return;

@<Issue a problem for appearance without object@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TextWithoutSubject),
		"I'm not sure what you're referring to",
		"that is, I can't decide to what room or thing you intend that text to belong. "
		"Perhaps you could rephrase this more explicitly? ('The description of the Inner "
		"Sanctum is...')");
	return;

@h The current object and subject.
Inform is deliberately minimal when allowing the use of pronouns which carry
meanings from one sentence to another. It is unclear exactly how natural
language does this, and while some theories are more persuasive than others,
all seem vulnerable to odd cases that they get "wrong". It's therefore
hard to program a computer to understand "it" so that human users are
happy with the result.

But we try, just a little, by keeping track of the subject and object
under discussion. Even this is tricky. Consider:

>> The Pavilion is a room. East is the Cricket Square.

East of where? Clearly of the current subject, the Pavilion (not
the room kind). On the other hand,

>> On the desk is a pencil. It has description "2B."

"It" here is the pencil, not the desk. To disentangle such things,
we keep track of two different running references: the current subject and
the current object. English is an SVO language, so that in assertions of the
form "X is Y", X is the subject and Y the object. But it will turn out to
be more complicated than that, because we disregard all references which are
not to tangible things and kinds.

=
inference_subject *object_of_sentences = NULL, *subject_of_sentences = NULL;
int subject_seems_to_be_plural = FALSE;

inference_subject *Assertions::Traverse::get_current_subject(void) {
	return subject_of_sentences;
}

inference_subject *Assertions::Traverse::get_current_object(void) {
	return object_of_sentences;
}

int Assertions::Traverse::get_current_subject_plurality(void) {
	return subject_seems_to_be_plural;
}

@ The routine |Assertions::Traverse::new_discussion| is called when we reach a
heading or other barrier in the source text, to make clear that there has
been a change of the topic discussed.

|Assertions::Traverse::change_discussion_topic| is called once at the end of
processing each assertion during each pass.

Note that we are careful to avoid changing the subject with sentences like:

>> East is the Central Plaza.

where this does not have the subject "east", but has instead an implicit
subject carried over from previous sentences.

=
void Assertions::Traverse::new_discussion(void) {
	if (subject_of_sentences)
		LOGIF(PRONOUNS, "[Forgotten subject of sentences: $j]\n", subject_of_sentences);
	if (subject_of_sentences)
		LOGIF(PRONOUNS, "[Forgotten object of sentences: $j]\n", object_of_sentences);
	subject_of_sentences = NULL; object_of_sentences = NULL;
}

void Assertions::Traverse::change_discussion_topic(inference_subject *infsx,
	inference_subject *infsy, inference_subject *infsy_full) {
	inference_subject *old_sub = subject_of_sentences, *old_obj = object_of_sentences;
	subject_seems_to_be_plural = FALSE;
	if (Wordings::length(Node::get_text(current_sentence)) > 1) near_start_of_extension = 0;
	Node::set_interpretation_of_subject(current_sentence, subject_of_sentences);

	if (Annotations::node_has(current_sentence, implicit_in_creation_of_ANNOT))
		return;
	#ifdef IF_MODULE
	if ((PL::Map::is_a_direction(infsx)) &&
			((InferenceSubjects::as_object_instance(infsx) == NULL) ||
				(InferenceSubjects::as_object_instance(infsy_full)))) infsx = NULL;
	#endif
	if (infsx) subject_of_sentences = infsx;
	if ((infsy) && (InferenceSubjects::domain(infsy) == NULL)) object_of_sentences = infsy;
	else if (infsx) object_of_sentences = infsx;

	if (subject_of_sentences != old_sub)
		LOGIF(PRONOUNS, "[Changed subject of sentences to $j]\n",
			subject_of_sentences);
	if (object_of_sentences != old_obj)
		LOGIF(PRONOUNS, "[Changed object of sentences to $j]\n",
			object_of_sentences);
}

@ Occasionally we need to force the issue, though:

=
void Assertions::Traverse::subject_of_discussion_a_list(void) {
	subject_seems_to_be_plural = TRUE;
}

@ =
void Assertions::Traverse::special_meaning(parse_node *pn) {
	Assertions::Traverse::try_special_meaning(traverse, pn->down);
}

void Assertions::Traverse::try_special_meaning(int task, parse_node *pn) {
	if (Assertions::Traverse::special(pn)) {
		special_meaning_holder *sm = Node::get_special_meaning(pn);
		if (sm) SpecialMeanings::call(sm, task, pn, NULL);
	}
}
