[FocusAndOutcome::] Focus and Outcome.

What a rulebook works on, and what it produces.

@h Focus.
The "focus" of a rulebook is what it works upon. Some rulebooks are for processing
actions, but others work on an input value. It's not obvious how to represent
action-focused rulebooks in our system of kinds. Two rejected schemes were:

(1) Regard them as "nothing-based rulebooks". But then there is no way to tell
from the kind that they are processing actions rather than performing some
other task.

(2) Regard them as "stored action-based rulebooks". But quite apart from the
unnatural look of this text, action-focus rulebooks are not really working on
a stored action -- they can only work on the current action being processed.
They actually have no parameter value at all.

And so we end up with a compromise:

(3) Regard them as "action-based rulebooks". This looks right to authors, though
it arguably abuses the word "action". But it does mean there is no way to have
a rulebook which actually has |K_action_name| as its focus kind.

People seem okay with this, but it is indeed a compromise. (In Basic Inform,
there are no actions anyway and this whole discussion is moot.) In case this
is ever reformed, the following structure abstracts the focus so that it
could in principle be differently implemented:

=
typedef struct focus {
	struct kind *focus_kind;
} focus;

int FocusAndOutcome::action_focus(focus *foc) {
	if ((foc) && (K_action_name) && (Kinds::eq(foc->focus_kind, K_action_name)))
		return TRUE;
	return FALSE;
}

kind *FocusAndOutcome::get_focus_parameter_kind(focus *foc) {
	return foc->focus_kind;
}

void FocusAndOutcome::initialise_focus(focus *foc, kind *K) {
	foc->focus_kind = K;
}

@h Outcome.
This is more involved. Some rulebooks produce values (and if so, we need to
know what kind), others do not. But they also end in one of an enumerated
range of "outcomes". All rulebooks have the ability to end in success, failure
or with no outcome (which is really an outcome meaning "I was interrupted
and never finished")

@d NO_OUTCOME 0
@d SUCCESS_OUTCOME 1
@d FAILURE_OUTCOME 2

=
typedef struct outcomes {
	struct kind *outcome_kind; /* of the value produced */

	int default_outcome_declared; /* has the author declared one? */
	int default_rule_outcome; /* one of the three |*_OUTCOME| values above... */
	struct rulebook_outcome *default_named_outcome; /* ...or a named alternative */

	struct linked_list *named_outcomes; /* of |rulebook_outcome|: other possibilities */
} outcomes;

@ The source text can also have a rulebook end, say, "in a blaze of glory", or give
it other possible endings. Those, if any, are listed in the |named_outcomes|.
Note that they still have to count as failures, successes or not.

=
typedef struct rulebook_outcome {
	struct named_rulebook_outcome *outcome_name;
	int kind_of_outcome; /* one of the three |*_OUTCOME| values abov */
	CLASS_DEFINITION
} rulebook_outcome;

@ And each individual named ending corresponds to one of the following. Note
that the same named ending can be used in multiple rulebooks, and can have
a different |kind_of_outcome| in each; that's why we distinguish the
structures //rulebook_outcome// and //named_rulebook_outcome//.

=
typedef struct named_rulebook_outcome {
	struct noun *name; /* Name in source text */
	struct nro_compilation_data compilation_data;
	CLASS_DEFINITION
} named_rulebook_outcome;

@ That awkward distinction between a //rulebook_outcome// and a //named_rulebook_outcome//
brings us edge cases if a rule has been written for use in one rulebook, but then
has been explicitly listed in another, or is more than one rulebook.

Suppose R belongs to both rulebooks B1 and B2, and suppose it "ends splendidly",
that being a named outcome of both. But now suppose this is a success for B1
and a failure for B2. What do we compile in the body of R's code?

The answer is that go with B1, supposing that one to be the earliest created
rulebook.

=
rulebook_outcome *FocusAndOutcome::rbo_from_context(named_rulebook_outcome *nro, id_body *idb) {
	if (idb) {
		rulebook *B;
		LOOP_OVER(B, rulebook) {
			outcomes *outs = Rulebooks::get_outcomes(B);
			if (BookingLists::contains_ph(B->contents, idb)) {
				rulebook_outcome *ro;
				LOOP_OVER_LINKED_LIST(ro, rulebook_outcome, outs->named_outcomes)
					if (ro->outcome_name == nro)
						return ro;
			}
		}
	}
	return NULL;
}

@ And this tests whether there is any obstacle to using |nro| in the body of
phrase |idb|'s code. If a rule ends "splendidly", then that needs to be a valid
ending for all of the rulebooks holding it.

This very similar function returns |NULL| if there's no problem, or the rulebook
causing the difficulty if so.

=
rulebook *FocusAndOutcome::rulebook_not_supporting(named_rulebook_outcome *nro, id_body *idb) {
	if (idb) {
		rulebook *B;
		LOOP_OVER(B, rulebook) {
			outcomes *outs = Rulebooks::get_outcomes(B);
			if (BookingLists::contains_ph(B->contents, idb)) {
				int okay = FALSE;
				rulebook_outcome *ro;
				LOOP_OVER_LINKED_LIST(ro, rulebook_outcome, outs->named_outcomes)
					if (ro->outcome_name == nro)
						okay = TRUE;
				if (okay == FALSE) return B;
			}
		}
	}
	return NULL;
}

@ A new rulebook begins with:

=
void FocusAndOutcome::initialise_outcomes(outcomes *outs, kind *K, int def) {
	outs->outcome_kind = K;
	outs->default_outcome_declared = FALSE;
	outs->default_rule_outcome = def;
	outs->default_named_outcome = NULL;
	outs->named_outcomes = NEW_LINKED_LIST(rulebook_outcome);
}

void FocusAndOutcome::set_default_outcome(outcomes *outs, int def) {
	outs->default_rule_outcome = def;
}

kind *FocusAndOutcome::get_outcome_kind(outcomes *outs) {
	return outs->outcome_kind;
}

@ Named outcomes are indeed specified only by their names:

=
named_rulebook_outcome *FocusAndOutcome::rbno_by_name(wording W) {
	parse_node *p = Lexicon::retrieve(MISCELLANEOUS_MC, W);
	if (Rvalues::is_CONSTANT_of_kind(p, K_rulebook_outcome))
		return Rvalues::to_named_rulebook_outcome(p);

	named_rulebook_outcome *nro = CREATE(named_rulebook_outcome);
	nro->name = Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_named_rulebook_outcome(nro), Task::language_of_syntax());
	nro->compilation_data = RTRulebooks::new_nro_compilation_data(nro);
	return nro;
}

@ Those nouns can be parsed as follows, and form the constant values of the
slightly odd kind |K_rulebook_outcome|.

=
<named-rulebook-outcome> internal {
	parse_node *p = Lexicon::retrieve(MISCELLANEOUS_MC, W);
	if (Rvalues::is_CONSTANT_of_kind(p, K_rulebook_outcome)) {
		==> { -, Rvalues::to_named_rulebook_outcome(p) }
		return TRUE;
	}
	==> { fail nonterminal }
}

@ And the following adds a new outcome name to a given set of |outs|:

=
void FocusAndOutcome::fresh_outcome(outcomes *outs, wording OW, int koo, int def) {
	if (Assertions::Creator::vet_name_for_noun(OW) == FALSE) return;
	if (def) {
		if (outs->default_named_outcome) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DefaultNamedOutcomeTwice),
				"at most one of the named outcomes from a rulebook can be the default",
				"and here we seem to have two.");
			return;
		}
		if (outs->default_outcome_declared) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DefaultOutcomeAlready),
				"the default outcome for this rulebook has already been declared",
				"and this is something which can only be done once.");
			return;
		}
	}
	named_rulebook_outcome *nro = FocusAndOutcome::rbno_by_name(OW);
	if (nro) {
		rulebook_outcome *ro;
		LOOP_OVER_LINKED_LIST(ro, rulebook_outcome, outs->named_outcomes)
			if (ro->outcome_name == nro) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_DuplicateOutcome),
					"this duplicates a previous assignment of the same outcome",
					"and to the same rulebook.");
				return;
			}
	}
	rulebook_outcome *ro = CREATE(rulebook_outcome);
	ro->outcome_name = nro;
	ro->kind_of_outcome = koo;
	if (def) {
		outs->default_named_outcome = ro;
		outs->default_outcome_declared = TRUE;
	}
	ADD_TO_LINKED_LIST(ro, rulebook_outcome, outs->named_outcomes);
}

@h Sentences adding outcomes to rulebooks.
Rulebooks do not have properties as such, but the following syntax instead creates
outcomes:

>> Visibility rules have outcomes there is sufficient light (failure) and there is insufficient light (success).

=
outcomes *outcomes_being_parsed = NULL;

void FocusAndOutcome::parse_properties(rulebook *B, wording W) {
	outcomes_being_parsed = &(B->my_outcomes);
	<rulebook-property>(W);
}

@ The following Preform grammar, then, parses text such as "outcomes there is
sufficient light (failure) and there is insufficient light (success)" and
modifies |outcomes_being_parsed| accordingly.

=
<rulebook-property> ::=
	outcome/outcomes <rulebook-outcome-list> | ==> { -, - }
	default <rulebook-default-outcome>	|      ==> { -, - }
	...                                        ==> @<Issue PM_NonOutcomeProperty problem@>

<rulebook-default-outcome> ::=
	<rule-outcome> |                           ==> @<Make this the rulebook's new default@>
	...                                        ==> @<Issue PM_BadDefaultOutcome problem@>

<rulebook-outcome-list> ::=
	... |                                      ==> { lookahead }
	<rulebook-outcome-setting-entry> <rulebook-outcome-tail> | ==> { 0, - }
	<rulebook-outcome-setting-entry>           ==> { 0, - }

<rulebook-outcome-tail> ::=
	, _and/or <rulebook-outcome-list> |        ==> { 0, - }
	_,/and/or <rulebook-outcome-list>          ==> { 0, - }

<rulebook-outcome-setting-entry> ::=
	... |                                      ==> { lookahead }
	<form-of-named-rule-outcome>               ==> @<Adopt this new named rule outcome@>

<form-of-named-rule-outcome> ::=
	... ( <rule-outcome> - the default ) |     ==> { R[1] + 100, -}
	... ( <rule-outcome> - default ) |         ==> { R[1] + 100, -}
	... ( <rule-outcome> ) |                   ==> { R[1], -}
	... ( ... ) |                              ==> @<Issue PM_BadOutcomeClarification problem@>
	...                                        ==> { SUCCESS_OUTCOME, -}

<rule-outcome> ::=
	success |                                  ==> { SUCCESS_OUTCOME, - }
	failure |                                  ==> { FAILURE_OUTCOME, - }
	no outcome                                 ==> { NO_OUTCOME, - }

@<Make this the rulebook's new default@> =
	if (outcomes_being_parsed->default_outcome_declared) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DefaultOutcomeTwice),
			"the default outcome for this rulebook has already been declared",
			"and this is something which can only be done once.");
	} else {
		outcomes_being_parsed->default_outcome_declared = TRUE;
		outcomes_being_parsed->default_rule_outcome = R[1];
	}

@<Issue PM_NonOutcomeProperty problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonOutcomeProperty),
		"the only properties of a rulebook are its outcomes",
		"for the time being at least.");

@<Issue PM_BadDefaultOutcome problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadDefaultOutcome),
		"the default outcome given for the rulebook isn't what I expected",
		"which would be one of 'default success', 'default failure' or "
		"'default no outcome'.");

@<Issue PM_BadOutcomeClarification problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_BadOutcomeClarification),
		"the bracketed clarification isn't what I expected",
		"which would be one of '(success)', '(failure)' or '(no outcome)'.");
	==> { FAILURE_OUTCOME, - };

@<Adopt this new named rule outcome@> =
	wording OW = GET_RW(<form-of-named-rule-outcome>, 1);
	int koo = R[1];
	int def = FALSE;
	if (koo >= 100) { koo -= 100; def = TRUE; }
	FocusAndOutcome::fresh_outcome(outcomes_being_parsed, OW, koo, def);
