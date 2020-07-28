[Phrases::Manager::] Construction Sequence.

To deal with all the |.i6t| interpreted commands which bring
about the compilation of phrases, and to ensure that they are used in
the correct order.

@h A day in the life.
Suppose we compare the run of Inform to a single day. At dawn the program
starts up. In the morning it finds out the names of all the constant values
defined in the source text: names like "Mrs Blenkinsop", "hatstand", and
so on. By noon it has also found out the wording used for phrases, such as
"award prize (N - a number) to (gardener - a woman)". This means that in
the afternoon it knows every name it ever will, and so it can work through
the definitions of phrases like "award prize...". In the evening, it does
some book-keeping, and at nightfall it shuts down.

We will use the story of our single day throughout this section on timing,
because everything has to happen in just the right order.

@d DAWN_PHT 0
@d EARLY_MORNING_PHT 1
@d LATE_MORNING_PHT 2
@d PRE_NOON_PHT 3
@d EARLY_AFTERNOON_PHT 4
@d MID_AFTERNOON_PHT 5
@d LATE_AFTERNOON_PHT 6
@d EVENING_PHT 7

=
int phrase_time_now = DAWN_PHT;

void Phrases::Manager::advance_phrase_time_to(int advance_to) {
	if (advance_to < phrase_time_now) {
		LOG("Advance from %d to %d\n", phrase_time_now, advance_to);
		internal_error(
			"The necessary phrase construction events are out of sequence");
	}
	phrase_time_now = advance_to;
}

@h Early morning.
We run through the phrase preambles to look for named rules like this:

>> Instead of pushing the red button (this is the fire alarm rule): ...

This looking-for-names is done by parsing the preamble text to a PHUD in
what is called "coarse mode", which can only get an approximate idea at
best: at this stage the "Instead" rulebook and the "red button" don't
exist, so most of the words here are meaningless. The PHUD which coarse
mode parsing produces is far too sketchy to use, and is thrown away.
But at least it does pick out the name "fire alarm rule", and Inform
creates an empty "rule" structure called this, registering this as the
name of a new constant.

=
void Phrases::Manager::traverse_for_names(void) {
	Phrases::Manager::advance_phrase_time_to(EARLY_MORNING_PHT);
	SyntaxTree::traverse(Task::syntax_tree(), Phrases::Manager::visit_for_names);
}

void Phrases::Manager::visit_for_names(parse_node *p) {
	if (Node::get_type(p) == RULE_NT)
		Phrases::Usage::predeclare_name_in(p);
}

@h Mid-morning.
This is when Inform is making its main traverses through assertions.
Something very useful is happening, but it's happening somewhere else.
Assertions such as

>> Instead is a rulebook.

are being read, and rulebooks are therefore being created.

We do nothing at all. We see nodes in the parse tree for phrase definitions,
but we let them go by. The |NULL|s in these two definitions tell Inform not
to do anything when the assertion traverse reaches nodes of these types:

=
sentence_handler COMMAND_SH_handler = { INVOCATION_LIST_NT, -1, 0, NULL };
sentence_handler ROUTINE_SH_handler = { RULE_NT, -1, 0, NULL };

@h Late morning.
With the assertions read, all the values have their names, and that means
we can go back to phrases like:

>> Instead of pushing the red button (this is the fire alarm rule): ...

and read them properly. So Inform now runs through the preambles again and
parses them for a second time to PHUDs, but this time in "fine mode" rather
than "coarse mode", and this time the result is not thrown away. If the
phrase is a "To..." phrase declaration, then the PHUD is pretty sketchy and
we parse more substantial PHTD and PHOD structures to accompany it. But if
it is a rule, the PHUD contains a great deal of useful information, and we
accompany it with essentially blank PHTD and PHOD structures. Either way, we
end up with a triplet of PHUD, PHTD and PHOD, and these are combined into a
new |phrase| structure. The PHSF structure is initially created as a
function of the PHTD: for example, if the phrase reads

>> To award (points - a number): ...

then the PHTD notes that "points" is the name of a parameter whose kind is
to be "number". The stack frame, PHSF, deduces that "points" will be a
local variable of kind "number" within the phrase when it's running.
Lastly, a blank PHRCD structure is created, filling out the set of five
substructures.

As they are created, the "To..." phrases are insertion-sorted into a list of
phrases in logical precedence order. This can be done now because it relies
only on the kinds listed in the PHTD, all of which have existed since
mid-morning.

For reasons discussed below, rules are not yet sorted. But the names created
in mid-morning, such as "fire alarm rule", are associated with their
phrases, and they are marked for what's called "automatic placement". For
example, the fire alarm rule will automatically be placed into the Instead
rulebook, because its preamble begins "Instead". The reason rules are only
marked to be placed later is that placement has to occur in logical
precedence order, but rules are harder to sort than phrases. They have to be
sorted by their PHRCDs, not their PHTDs, and a PHRCD cannot even be parsed
until afternoon because the conditions for a rule often mention phrases --
for instance, "Instead of waiting when in darkness", making use of an "in
darkness" phrase. So for now we just make a mental note to do automatic
placement later on.

=
void Phrases::Manager::traverse(void) {
	Phrases::Manager::advance_phrase_time_to(LATE_MORNING_PHT);

	int progress_target = 0, progress_made = 0;
	SyntaxTree::traverse_intp(Task::syntax_tree(), Phrases::Manager::visit_to_count, &progress_target);
	SyntaxTree::traverse_intp_intp(Task::syntax_tree(), Phrases::Manager::visit_to_create, &progress_target, &progress_made);
}

void Phrases::Manager::visit_to_count(parse_node *p, int *progress_target) {
	(*progress_target)++;
}

void Phrases::Manager::visit_to_create(parse_node *p, int *progress_target, int *progress_made) {
	(*progress_made)++;
	if ((*progress_made) % 10 == 0)
		ProgressBar::update(3,
			((float) (*progress_made))/((float) (*progress_target)));

	if (Node::get_type(p) == RULE_NT) {
		Phrases::create_from_preamble(p);
	}
}

@h Just before noon.
It is now nearly noon, and things appear to be a little untidy. Why
are the "To..." phrases not yet registered with the excerpt parser?
The answer is that we needed to wait until all of the "To..." phrases
had been created as structures before we could safely proceed. The first
phrase couldn't be registered until we knew the complete logical order
of them all. Well: at last, we do know that, and can make the registration.
Phrases are the very last things to get their names in Inform (well, not
counting local variables, whose names only exist fleetingly).

=
void Phrases::Manager::register_meanings(void) {
	Phrases::Manager::advance_phrase_time_to(PRE_NOON_PHT);

	Routines::ToPhrases::register_all();
}

@h Noon.
When the final phrase is registered, the hour chimes. From this point
onwards, there's no longer any text which can't be parsed because some
of the names don't exist yet: everything exists.

@h Early afternoon.
In the afternoon, we begin by binding up the rulebooks. First, we go through
the phrases destined to be rules, and for each we translate the PHUD (which
contains mainly textual representations of the usage information, e.g.
"taking something (called the thingummy) which is in a lighted room during
Scene Two when the marble slab is open") to a PHRCD (which contains fully
parsed Inform data structures, e.g., an action pattern and a pointer to a
|scene| structure). As noted above, this often means parsing conditions
which involve phrases, and that's why we're doing it in the afternoon.

During this PHUD-to-PHRCD parsing process, we make sure that the relevant
phrase's PHSF is the current stack frame, because it's here that the names
of any callings (e.g. "thingummy") are created as local variables to be
valid throughout the phrase.

Once we're done with this, the PHUD will never be used again.

Note that the PHRCDs have to be parsed in source text appearance order (the
order which |LOOP_OVER| follows) so that the back reference "doing it" can
correctly refer to the most recently mentioned action.

=
void Phrases::Manager::parse_rule_parameters(void) {
	Phrases::Manager::advance_phrase_time_to(EARLY_AFTERNOON_PHT);

	phrase *ph;
	LOOP_OVER(ph, phrase) {
		current_sentence = ph->declaration_node;
		Frames::make_current(&(ph->stack_frame));
		ph->runtime_context_data =
			Phrases::Usage::to_runtime_context_data(&(ph->usage_data));
		Frames::remove_current();
	}
}

@ We can finally make the automatic placements of rules into rulebooks: so
our "fire alarm rule" will at last be placed in the "Instead" rulebook. The
PHRCDs are used to make sure it appears in the right position.

=
void Phrases::Manager::add_rules_to_rulebooks(void) {
	Phrases::Manager::advance_phrase_time_to(EARLY_AFTERNOON_PHT);
	Rules::Bookings::make_automatic_placements();
	inter_name *iname = Hierarchy::find(NUMBER_RULEBOOKS_CREATED_HL);
	Emit::named_numeric_constant(iname, (inter_ti) NUMBER_CREATED(rulebook));
	Hierarchy::make_available(Emit::tree(), iname);
}

@ It might seem as if the rulebooks are now complete, but this is not true,
because we still have to take care of manual placements like:

>> The fire alarm rule is listed in the safety procedures rulebook.

This is where we get on with that, traversing the parse tree for sentences
of this general sort. Rules can also be unlisted, or constrained to happen
only conditionally, or substituted by other rules.

=
void Phrases::Manager::parse_rule_placements(void) {
	Phrases::Manager::advance_phrase_time_to(EARLY_AFTERNOON_PHT);
	SyntaxTree::traverse(Task::syntax_tree(), Phrases::Manager::visit_to_parse_placements);
}

void Phrases::Manager::visit_to_parse_placements(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) &&
		(p->down) &&
		(Node::get_type(p->down) == VERB_NT)) {
		prevailing_mood =
			Annotations::read_int(p->down, verbal_certainty_ANNOT);
		if (Sentences::VPs::special(p->down))
			Assertions::Traverse::try_special_meaning(TRAVERSE_FOR_RULE_FILING_SMFT, p->down);
	}
}

@h Mid-afternoon.
It is now mid-afternoon, and the rulebooks are complete. It is time to
compile the I6 routines which will provide the run-time definitions of all
these phrases. This will be a long task, and much of it will be left until
the evening. But we do get rid of some easy cases now: the rules and
adjective definitions.

=
int total_phrases_to_compile = 0;
int total_phrases_compiled = 0;
void Phrases::Manager::compile_first_block(void) {
	Phrases::Manager::advance_phrase_time_to(MID_AFTERNOON_PHT);

	@<Count up the scale of the task@>;
	@<Compile definitions of rules in rulebooks@>;
	@<Compile definitions of rules left out of rulebooks@>;
	@<Compile phrases which define adjectives@>;
	@<Mark To... phrases which have definite kinds for future compilation@>;
	@<Throw problems for phrases with return kinds too vaguely defined@>;
	@<Throw problems for inline phrases named as constants@>;
}

@<Count up the scale of the task@> =
	total_phrases_compiled = 0;
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if (ph->at_least_one_compiled_form_needed)
			total_phrases_to_compile++;

@<Compile definitions of rules in rulebooks@> =
	rulebook *rb;
	LOOP_OVER(rb, rulebook)
		Rulebooks::compile_rule_phrases(rb,
			&total_phrases_compiled, total_phrases_to_compile);

@<Compile definitions of rules left out of rulebooks@> =
	rule *R;
	LOOP_OVER(R, rule)
		Rules::compile_definition(R,
			&total_phrases_compiled, total_phrases_to_compile);

@ This doesn't compile all adjective definitions, only the ones which supply
a whole multi-step phrase to define them -- a relatively little-used feature
of Inform.

@<Compile phrases which define adjectives@> =
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if (Phrases::Usage::get_effect(&(ph->usage_data)) ==
			DEFINITIONAL_PHRASE_EFF)
			Phrases::compile(ph, &total_phrases_compiled,
				total_phrases_to_compile, NULL, NULL, NULL);
	Adjectives::Meanings::compile_support_code();

@ As we'll see, it's legal in Inform to define "To..." phrases with vague
kinds: "To expose (X - a value)", for example. This can't be compiled as
vaguely as the definition implies, since there would be no way to know how
to store X. Instead, for each different kind of X which is actually needed,
a fresh version of the phrase is compiled -- one where X is a number, one
where it's a text, and so on. This is handled by making a "request" for the
phrase, indicating that a compiled version of it will be needed.

Since "To..." phrases are only compiled on request, we must remember to
request the boring ones with straightforward kinds ("To award (N - a number)
points", say). This is where we do it:

@<Mark To... phrases which have definite kinds for future compilation@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		kind *K = Phrases::TypeData::kind(&(ph->type_data));
		if (Kinds::Behaviour::definite(K)) {
			if (ph->at_least_one_compiled_form_needed)
				Routines::ToPhrases::make_request(ph, K, NULL, EMPTY_WORDING);
		}
	}

@<Throw problems for phrases with return kinds too vaguely defined@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		kind *KR = Phrases::TypeData::get_return_kind(&(ph->type_data));
		if ((Kinds::Behaviour::semidefinite(KR) == FALSE) &&
			(Phrases::TypeData::arithmetic_operation(ph) == -1)) {
			current_sentence = Phrases::declaration_node(ph);
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReturnKindVague));
			Problems::issue_problem_segment(
				"The declaration %1 tries to set up a phrase which decides a "
				"value which is too vaguely described. For example, 'To decide "
				"which number is the target: ...' is fine, because 'number' "
				"is clear about what kind of value should emerge; but 'To "
				"decide which value is the target: ...' is not clear enough.");
			Problems::issue_problem_end();
		}
		for (int k=1; k<=26; k++)
			if ((Kinds::Behaviour::involves_var(KR, k)) &&
				(Phrases::TypeData::tokens_contain_variable(&(ph->type_data), k) == FALSE)) {
				current_sentence = Phrases::declaration_node(ph);
				TEMPORARY_TEXT(var_letter)
				PUT_TO(var_letter, 'A'+k-1);
				Problems::quote_source(1, current_sentence);
				Problems::quote_stream(2, var_letter);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReturnKindUndetermined));
				Problems::issue_problem_segment(
					"The declaration %1 tries to set up a phrase which decides a "
					"value which is too vaguely described, because it involves "
					"a kind variable (%2) which it can't determine through "
					"usage.");
				Problems::issue_problem_end();
				DISCARD_TEXT(var_letter)
		}
	}

@<Throw problems for inline phrases named as constants@> =
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if ((Phrases::TypeData::invoked_inline(ph)) &&
			(Phrases::Usage::has_name_as_constant(&(ph->usage_data)))) {
			current_sentence = Phrases::declaration_node(ph);
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NamedInline));
			Problems::issue_problem_segment(
				"The declaration %1 tries to give a name to a phrase which is "
				"defined using inline Inform 6 code in (- markers -). Such "
				"phrases can't be named and used as constants because they "
				"have no independent existence, being instead made fresh "
				"each time they are used.");
			Problems::issue_problem_end();
		}

@h Late Afternoon.
Rules are pretty well sorted out now, but we still need to compile some I6
to show how they fit together. These miscellaneous function calls can happen
in any order, so long as they all occur in the late afternoon.

First, rules set to go off at a particular time need to have their timings
noted down:

=
void Phrases::Manager::TimedEventsTable(void) {
	Phrases::Manager::advance_phrase_time_to(LATE_AFTERNOON_PHT);
	Phrases::Timed::TimedEventsTable();
}

void Phrases::Manager::TimedEventTimesTable(void) {
	Phrases::Manager::advance_phrase_time_to(LATE_AFTERNOON_PHT);
	Phrases::Timed::TimedEventTimesTable();
}

@ Second, the rulebooks need to be compiled into I6 arrays:

=
void Phrases::Manager::rulebooks_array(void) {
	Phrases::Manager::advance_phrase_time_to(LATE_AFTERNOON_PHT);
	Rulebooks::rulebooks_array_array();
}

void Phrases::Manager::compile_rulebooks(void) {
	Phrases::Manager::advance_phrase_time_to(LATE_AFTERNOON_PHT);
	Rulebooks::compile_rulebooks();
}

void Phrases::Manager::RulebookNames_array(void) {
	Phrases::Manager::advance_phrase_time_to(LATE_AFTERNOON_PHT);
	Rulebooks::RulebookNames_array();
}

@ And finally, just as the sun slips below the horizon, we compile the code
which prints out values of the kind "rule" at run-time -- for example, taking
the address of the routine which our example rule was compiled to and then
printing out "fire alarm rule".

=
void Phrases::Manager::RulePrintingRule_routine(void) {
	Phrases::Manager::advance_phrase_time_to(LATE_AFTERNOON_PHT);
	Rules::RulePrintingRule_routine();
}

@h Evening.
The twilight gathers, but our work is far from done. Recall that we have
accumulated compilation requests for "To..." phrases, but haven't actually
acted on them yet.

We have to do this in quite an open-ended way, because compiling one phrase
can easily generate fresh requests for others. For instance, suppose we have
the definition "To expose (X - a value)" in play, and suppose that when
compiling the phrase "To advertise", Inform runs into the line "expose the
hoarding text". This causes it to issue a compilation request for "To expose
(X - a text)". Perhaps we've compiled such a form already, but perhaps we
haven't. Compilation therefore goes on until all requests have been dealt
with.

Compiling phrases also produces the need for other pieces of code to be
generated -- for example, suppose our phrase being compiled, "To advertise",
includes the text:

>> let Z be "Two for the price of one! Just [expose price]!";

We are going to need to compile "Two for the price of one! Just [expose price]!"
later on, in its own text substitution routine; but notice that it contains
the need for "To expose (X - a number)", and that will generate a further
phrase request.

Because of this and similar problems, it's impossible to compile all the
phrases alone: we must compile phrases, then things arising from them, then
phrases arising from those, then things arising from the phrases arising
from those, and so on, until we're done. The process is therefore structured
as a set of "coroutines" which each carry out as much as they can and then
hand over to the others to generate more work. (Indeed, the routine below
can be called multiple times in the course of the evening.)

=
void Phrases::Manager::compile_as_needed(void) {
	Phrases::Manager::advance_phrase_time_to(EVENING_PHT);
	rule *R;
	LOOP_OVER(R, rule)
		Rules::compile_definition(R,
			&total_phrases_compiled, total_phrases_to_compile);
	int repeat = TRUE;
	while (repeat) {
		repeat = FALSE;
		if (Routines::ToPhrases::compilation_coroutine(
			&total_phrases_compiled, total_phrases_to_compile) > 0)
			repeat = TRUE;
		if (ListTogether::compilation_coroutine() > 0)
			repeat = TRUE;
		#ifdef IF_MODULE
		if (PL::Actions::ScopeLoops::compilation_coroutine() > 0)
			repeat = TRUE;
		#endif
		if (Strings::TextSubstitutions::compilation_coroutine(FALSE) > 0)
			repeat = TRUE;
		if (Calculus::Propositions::Deferred::compilation_coroutine() > 0)
			repeat = TRUE;
	}
}
