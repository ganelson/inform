[StandardProblems::] Supplementary Issues.

Some supplementary general sorts of problem message.

@h Contradictions.
As soon as we combine information from two sentences, we are at risk of a
contradiction of some kind:

=
void StandardProblems::two_sentences_problem(SIGIL_ARGUMENTS, parse_node *other_sentence,
	char *message, char *explanation) {
	ACT_ON_SIGIL
	if (current_sentence == other_sentence) {
		StandardProblems::sentence_problem(Task::syntax_tree(), PASS_SIGIL, message, explanation);
		return;
	}
	Problems::quote_source(1, current_sentence);
	Problems::quote_source(2, other_sentence);
	Problems::quote_text(3, message);
	Problems::quote_text(4, explanation);
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	Problems::issue_problem_segment(
		"You wrote %1, but in another sentence %2: %Sagain, %3.%Lbut %3, %4");
	Problems::issue_problem_end();
}

@ Almost exactly the same thing, but happening at arbitrary positions in the
parse tree, and concerning an instance:

=
void StandardProblems::contradiction_problem(SIGIL_ARGUMENTS, parse_node *A, parse_node *B,
		instance *I, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, A);
	Problems::quote_source(2, B);
	Problems::quote_object(3, I);
	Problems::quote_text(4, message);
	Problems::quote_text(5, explanation);
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	if (Wordings::eq(Node::get_text(A), Node::get_text(B)) == FALSE)
		Problems::issue_problem_segment("You wrote %1, but in another sentence %2: ");
	else
		Problems::issue_problem_segment("You wrote %1: ");
	Problems::issue_problem_segment("%Sagain, %3 %4.%L%3 %4, %5");
	Problems::issue_problem_end();
}

void StandardProblems::infs_contradiction_problem(SIGIL_ARGUMENTS, parse_node *A, parse_node *B,
		inference_subject *infs, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, A);
	Problems::quote_source(2, B);
	Problems::quote_subject(3, infs);
	Problems::quote_text(4, message);
	Problems::quote_text(5, explanation);
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	if (Wordings::eq(Node::get_text(A), Node::get_text(B)) == FALSE)
		Problems::issue_problem_segment("You wrote %1, but in another sentence %2: ");
	else Problems::issue_problem_segment("You wrote %1: ");
	Problems::issue_problem_segment("%Sagain, %3 %4.%L%3 %4, %5");
	Problems::issue_problem_end();
}

@h Table problems.
In principle we could treat these as sentence problems, but the "sentence"
for a table can be enormous: so we need something which can show which
table we are in, yet still only cite a small part of it --

=
void StandardProblems::table_problem(SIGIL_ARGUMENTS, table *t, table_column *tc, parse_node *data,
	char *message) {
	ACT_ON_SIGIL
	current_sentence = t->headline_fragment;
	Problems::quote_table(1, t);
	if (tc) Problems::quote_wording(2, Nouns::nominative_singular(tc->name));
	if (data) Problems::quote_source(3, data);
	Problems::issue_problem_begin(Task::syntax_tree(), "");
	Problems::issue_problem_segment(message);
	Problems::issue_problem_end();
}

@h Equation problems.
So this is where hopes are generically dashed about equations:

=
void StandardProblems::equation_problem(SIGIL_ARGUMENTS, equation *eqn, char *p, char *text) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, eqn->equation_text);
	Problems::quote_text(3, p);
	Problems::issue_problem_begin(Task::syntax_tree(), "");
	Problems::issue_problem_segment("In %1, you define an equation '%2': but ");
	Problems::issue_problem_segment(text);
	Problems::issue_problem_end();
}

void StandardProblems::equation_problem_S(SIGIL_ARGUMENTS, equation *eqn, text_stream *p, char *text) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, eqn->equation_text);
	Problems::quote_stream(3, p);
	Problems::issue_problem_begin(Task::syntax_tree(), "");
	Problems::issue_problem_segment("In %1, you define an equation '%2': but ");
	Problems::issue_problem_segment(text);
	Problems::issue_problem_end();
}

void StandardProblems::equation_symbol_problem(SIGIL_ARGUMENTS, equation *eqn, wording W, char *text) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_text(3, text);
	Problems::issue_problem_begin(Task::syntax_tree(), "");
	Problems::issue_problem_segment(
		"In %1, you define an equation which mentions the symbol '%2': but %3");
	Problems::issue_problem_end();
}

@h Inline definition problems.

=
void StandardProblems::inline_problem(SIGIL_ARGUMENTS, phrase *ph, text_stream *definition,
	char *message) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_stream(2, definition);
	wording XW = ToPhraseFamily::get_prototype_text(ph->from);
	Problems::quote_wording_as_source(3, XW);
	Problems::issue_problem_begin(Task::syntax_tree(), "");
	Problems::issue_problem_segment(
		"You wrote %1, which I read as making use of the phrase %3. This in turn "
		"has what's called an 'inline' definition, written in a technical notation "
		"usually needed only by the Standard Rules or other low-level extensions. "
		"The definition here is '%2' but it seems to be broken. ");
	Problems::issue_problem_segment(message);
	Problems::issue_problem_end();
}

@h Proposition type-checking problems.
Are mostly issued thus:

=
void StandardProblems::tcp_problem(SIGIL_ARGUMENTS, tc_problem_kit *tck, char *prototype) {
	if (tck->issue_error) {
		ACT_ON_SIGIL
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, tck->ew_text);
		Problems::quote_text(3, tck->intention);
		Problems::issue_problem_begin(Task::syntax_tree(), "");
		Problems::issue_problem_segment(
			"In the sentence %1, it looks as if you intend '%2' to %3, but ");
		Problems::issue_problem_segment(prototype);
		Problems::issue_problem_end();
	}
	tck->flag_problem = TRUE;
}

@h Instance problems.
Instances can be created rather indirectly (for instance, in the course of
assemblies of other instances), and their properties are sometimes inferred
from information in sentences far distant, so we can't always locate
these problems at any particular sentence.

=
void StandardProblems::object_problem(SIGIL_ARGUMENTS, instance *I,
		char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_object(1, I);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	Problems::issue_problem_segment("The %1 %2%S.%L, %3");
	Problems::issue_problem_end();
}

void StandardProblems::object_problem_at_sentence(SIGIL_ARGUMENTS, instance *I,
		char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::quote_object(4, I);
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	Problems::issue_problem_segment("You wrote %1, but the %4 %2%S.%L, %3");
	Problems::issue_problem_end();
}

void StandardProblems::subject_problem_at_sentence(SIGIL_ARGUMENTS, inference_subject *infs,
		char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_source(1, current_sentence);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::quote_subject(4, infs);
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	Problems::issue_problem_segment("You wrote %1, but the %4 %2%S.%L, %3");
	Problems::issue_problem_end();
}

@ When objects are created with bizarre names, this is usually a symptom of
some other malaise, and so we issue the following message with a little
more tact (and in particular, we don't assert very confidently that what
we are dealing with is genuinely an object).

=
void StandardProblems::subject_creation_problem(SIGIL_ARGUMENTS, inference_subject *subj,
		char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_subject(1, subj);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	wording W = InferenceSubjects::get_name_text(subj);
	if (Wordings::nonempty(W)) {
		Problems::quote_source(4, Diagrams::new_UNPARSED_NOUN(W));
		Problems::issue_problem_begin(Task::syntax_tree(), explanation);
		Problems::issue_problem_segment(
			"I've made something called %4 but it %2%S.%L, %3");
		Problems::issue_problem_end();
	} else {
		Problems::issue_problem_begin(Task::syntax_tree(), explanation);
		Problems::issue_problem_segment(
			"I've made something called '%1' but it %2%S.%L, %3");
		Problems::issue_problem_end();
	}
}

@ Information about objects is assembled in a mass of inferences. When these
contradict each other, that is usually the occasion for a contradiction
problem (see above); the following routine is used only when inferences
are implied which necessarily make no sense, rather than merely contingently
making no sense.

=
void StandardProblems::inference_problem(SIGIL_ARGUMENTS, inference_subject *infs, inference *inf,
		char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_subject(1, infs);
	Problems::quote_source(2, Inferences::where_inferred(inf));
	Problems::quote_text(3, message);
	Problems::quote_text(4, explanation);
	Problems::quote_property(5, PropertyInferences::get_property(inf));
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	Problems::issue_problem_segment(
		"You wrote %2: but the property %5 for the %1 %3%S.%L, %4");
	Problems::issue_problem_end();
}

@h Property problems.
Just occasionally there is a problem with the definition of a property in the
abstract, rather than with the actual property of some specific object.

=
void StandardProblems::property_problem(SIGIL_ARGUMENTS, property *prn, char *message, char *explanation) {
	ACT_ON_SIGIL
	Problems::quote_property(1, prn);
	Problems::quote_text(2, message);
	Problems::quote_text(3, explanation);
	Problems::issue_problem_begin(Task::syntax_tree(), explanation);
	Problems::issue_problem_segment("The %1 %2%S.%L, %3");
	Problems::issue_problem_end();
}

@h Extension problems.
These are generated when the user tries to employ a malformed extension.

=
void StandardProblems::extension_problem(SIGIL_ARGUMENTS, inform_extension *E, char *message) {
	ACT_ON_SIGIL
	Problems::quote_extension(1, E);
	Problems::quote_text(2, message);
	Problems::issue_problem_begin(Task::syntax_tree(), message);
	Problems::issue_problem_segment(
		"The extension %1, which your source text makes use of, %2.");
	Problems::issue_problem_end();
}

@h Releasing problems.
These occur when the release instructions do not make sense. Sometimes it's
possible to pin down an exact place where the difficulty occurs, but
sometimes not.

=
void StandardProblems::release_problem(SIGIL_ARGUMENTS, char *message, filename *name) {
	ACT_ON_SIGIL
	Problems::quote_text(1, message);
	TEMPORARY_TEXT(fn)
	WRITE_TO(fn, "%f", name);
	Problems::quote_stream(2, fn);
	Problems::issue_problem_begin(Task::syntax_tree(), message);
	Problems::issue_problem_segment("A problem occurred with the 'Release along with...': "
		"instructions: %1 (with the file '%2')");
	Problems::issue_problem_end();
	DISCARD_TEXT(fn)
}

void StandardProblems::release_problem_path(SIGIL_ARGUMENTS, char *message, pathname *path) {
	ACT_ON_SIGIL
	Problems::quote_text(1, message);
	TEMPORARY_TEXT(pn)
	WRITE_TO(pn, "%p", path);
	Problems::quote_stream(2, pn);
	Problems::issue_problem_begin(Task::syntax_tree(), message);
	Problems::issue_problem_segment("A problem occurred with the 'Release along with...': "
		"instructions: %1 (with the file '%2')");
	Problems::issue_problem_end();
	DISCARD_TEXT(pn)
}

void StandardProblems::release_problem_at_sentence(SIGIL_ARGUMENTS, char *message, filename *name) {
	ACT_ON_SIGIL
	Problems::quote_text(1, message);
	TEMPORARY_TEXT(fn)
	WRITE_TO(fn, "%f", name);
	Problems::quote_stream(2, fn);
	Problems::quote_source(3, current_sentence);
	Problems::issue_problem_begin(Task::syntax_tree(), message);
	Problems::issue_problem_segment("A problem occurred with the 'Release along with...': "
		"instructions (%3): %1 (with the file '%2')");
	Problems::issue_problem_end();
	DISCARD_TEXT(fn)
}

@h Cartographical problems.
The map-maker used for the World index and also the EPS-file output has its
own quaint syntax, and where there is syntax, there are error messages:

=
void StandardProblems::map_problem(SIGIL_ARGUMENTS, parse_node *q, char *message) {
	ACT_ON_SIGIL
	Problems::quote_source(1, q);
	Problems::quote_text(2, message);
	Problems::issue_problem_begin(Task::syntax_tree(), "");
	Problems::issue_problem_segment("You gave as a hint in map-making: %1. %2");
	Problems::issue_problem_end();
}

void StandardProblems::map_problem_wanted_but(SIGIL_ARGUMENTS, parse_node *q, char *i_wanted_a, int vw1) {
	ACT_ON_SIGIL
	Problems::quote_source(1, q);
	Problems::quote_text(2, i_wanted_a);
	Problems::quote_wording(3, Wordings::one_word(vw1));
	Problems::issue_problem_begin(Task::syntax_tree(), "");
	Problems::issue_problem_segment(
		"You gave as a hint in map-making: %1. But the value '%3' did not "
		"fit - it should have been %2.");
	Problems::issue_problem_end();
}
