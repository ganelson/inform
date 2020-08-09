[Rulebooks::Outcomes::] Focus and Outcome.

To look after the value or action on which a rulebook acts, and the
possible outcomes it produces.

@ When a rulebook is being worked through at run-time, a special value or
situation normally gives it a focus -- something to work on. Rulebooks
can have two types:

(A) Action rulebooks, like "Instead of", which take a pattern match on
the current action as their focus: for instance, the rule "Instead of
eating something portable..." is in the "Instead of eating" rulebook but
uses "something portable" as focus.

(P) Parametrised rulebooks, like "reaching inside", take (a pattern match
on) a single parameter as their focus. For instance, "A rule for reaching
inside the flask..." has the flask as focus.

@d ACTION_FOCUS 0
@d PARAMETER_FOCUS 1

=
typedef struct focus {
	int rulebook_focus; /* always |ACTION_FOCUS| or |PARAMETER_FOCUS| */
	struct kind *kind_of_parameter; /* if created as |NO_FOCUS|, this is |NULL| */
	int rules_always_test_actor; /* for action-tied check, carry out, report */
} focus;

@ Each rulebook reaches one of three possible outcomes: success, failure and
neither (meaning that it proceeded through to the end without any positive
or negative news arising). If a rule does apply to the current
circumstances (i.e., if the parameter is matched successfully) then it can
explicitly choose to produce any of the three outcomes: if it makes no
decision, the result is that stored in the rulebook's
|default_rule_outcome| field. This is how

>> Instead of going north, say "The snow is too deep."

>> Before going north, say "Well, I'll try..."

behave differently: the instead rule halts the action, because the instead
rulebook has a default outcome of |FAILURE_OUTCOME|; the before rule allows
it to proceed, because the default is |NO_OUTCOME|.

@d UNRECOGNISED_OUTCOME -1 /* used in parsing only */
@d NO_OUTCOME 0
@d SUCCESS_OUTCOME 1
@d FAILURE_OUTCOME 2

=
typedef struct outcomes {
	int default_outcome_declared; /* flag: whether author has declared this */
	int default_rule_outcome; /* success, failure or none: see above */
	struct rulebook_outcome *default_named_outcome; /* alternative to the above */
	struct rulebook_outcome *named_outcomes;
	struct kind *value_outcome_kind;
} outcomes;

@ However, a rulebook is allowed to give special problem-specific names to
its outcomes.

=
typedef struct named_rulebook_outcome {
	struct noun *name; /* Name in source text */
	struct inter_name *nro_iname;
	CLASS_DEFINITION
} named_rulebook_outcome;

typedef struct rulebook_outcome {
	struct rulebook_outcome *next;
	struct named_rulebook_outcome *outcome_name;
	int kind_of_outcome; /* one of the three values above */
	CLASS_DEFINITION
} rulebook_outcome;

@ =
void Rulebooks::Outcomes::initialise_outcomes(outcomes *outs, kind *K, int def) {
	outs->value_outcome_kind = K;
	outs->default_outcome_declared = FALSE;
	outs->default_rule_outcome = def;
	outs->default_named_outcome = NULL;
}

void Rulebooks::Outcomes::set_default_outcome(outcomes *outs, int def) {
	outs->default_rule_outcome = def;
}

kind *Rulebooks::Outcomes::get_outcome_kind(outcomes *outs) {
	return outs->value_outcome_kind;
}

@ There are only three nameless outcomes: a rulebook can end in success, in
failure, or with no outcome. Any of these can be the default outcome, that is,
can be what rulebook does if it none of its rules cause an outcome.

=
<rulebook-default-outcome> ::=
	<rule-outcome> |  ==> @<Make this the rulebook's new default@>
	...               ==> @<Issue PM_BadDefaultOutcome problem@>

<rule-outcome> ::=
	success |         ==> { SUCCESS_OUTCOME, - }
	failure |         ==> { FAILURE_OUTCOME, - }
	no outcome        ==> { NO_OUTCOME, - }

@<Make this the rulebook's new default@> =
	if (outcomes_being_parsed->default_outcome_declared) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DefaultOutcomeTwice),
			"the default outcome for this rulebook has already been declared",
			"and this is something which can only be done once.");
	} else {
		outcomes_being_parsed->default_outcome_declared = TRUE;
		outcomes_being_parsed->default_rule_outcome = R[1];
	}

@<Issue PM_BadDefaultOutcome problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadDefaultOutcome),
		"the default outcome given for the rulebook isn't what I expected",
		"which would be one of 'default success', 'default failure' or "
		"'default no outcome'.");

@ =
int default_rbno_flag = FALSE;

@ Rulebooks can alternatively supply any number of named outcomes, though
each of these still has one of the three results noted above; which will be
"success" unless it's explicitly given.

The following parses a declaration of named outcomes. For example:

>> there is sufficient light (failure) and there is insufficient light (success)

=
<rulebook-outcome-list> ::=
	... |                                                       ==> { lookahead }
	<rulebook-outcome-setting-entry> <rulebook-outcome-tail> |  ==> { 0, - }
	<rulebook-outcome-setting-entry>                            ==> { 0, - }

<rulebook-outcome-tail> ::=
	, _and/or <rulebook-outcome-list> |                         ==> { 0, - }
	_,/and/or <rulebook-outcome-list>                           ==> { 0, - }

<rulebook-outcome-setting-entry> ::=
	<form-of-named-rule-outcome>   ==> {0, - }; if (!preform_lookahead_mode) @<Adopt this new named rule outcome@>

<form-of-named-rule-outcome> ::=
	... ( <rule-outcome> - the default ) |                      ==> { R[1], -}; default_rbno_flag = TRUE
	... ( <rule-outcome> - default ) |                          ==> { R[1], -}; default_rbno_flag = TRUE
	... ( <rule-outcome> ) |                                    ==> { R[1], -}; default_rbno_flag = FALSE
	... ( ... ) |                                               ==> @<Issue PM_BadOutcomeClarification problem@>
	...                                                         ==> { SUCCESS_OUTCOME, -}; default_rbno_flag = FALSE

<notable-rulebook-outcomes> ::=
	it is very likely |
	it is likely |
	it is possible |
	it is unlikely |
	it is very unlikely

@<Issue PM_BadOutcomeClarification problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadOutcomeClarification),
		"the bracketed clarification isn't what I expected",
		"which would be one of '(success)', '(failure)' or '(no outcome)'.");
	==> { UNRECOGNISED_OUTCOME, - };

@<Adopt this new named rule outcome@> =
	wording OW = GET_RW(<form-of-named-rule-outcome>, 1);
	int def = FALSE;
	if (default_rbno_flag) {
		if (outcomes_being_parsed->default_named_outcome) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DefaultNamedOutcomeTwice),
				"at most one of the named outcomes from a rulebook "
				"can be the default",
				"and here we seem to have two.");
			return TRUE;
		}
		def = TRUE;
		if (outcomes_being_parsed->default_outcome_declared) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DefaultOutcomeAlready),
				"the default outcome for this rulebook has already "
				"been declared",
				"and this is something which can only be done once.");
			return TRUE;
		}
		outcomes_being_parsed->default_outcome_declared = TRUE;
	}
	int koo = R[1];
	if (koo != UNRECOGNISED_OUTCOME) {
		named_rulebook_outcome *rbno = Rulebooks::Outcomes::rbno_by_name(OW);
		rulebook_outcome *ro, *last = NULL;
		int dup = FALSE;
		for (ro = outcomes_being_parsed->named_outcomes; ro; ro = ro->next) {
			if (ro->outcome_name == rbno) dup = TRUE;
			last = ro;
		}
		if (dup) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DuplicateOutcome),
				"this duplicates a previous assignment of the same outcome",
				"and to the same rulebook.");
		} else {
			rulebook_outcome *nro = CREATE(rulebook_outcome);
			nro->next = NULL;
			nro->outcome_name = rbno;
			nro->kind_of_outcome = koo;
			if (def) outcomes_being_parsed->default_named_outcome = nro;
			if (last) last->next = nro; else outcomes_being_parsed->named_outcomes = nro;
		}
	}

@ This family of constants (named rulebook outcomes) is special because it
can be used in a void context as a sort of return-from-rule phrase.

=
<named-rulebook-outcome> internal {
	parse_node *p = Lexicon::retrieve(MISCELLANEOUS_MC, W);
	if (Rvalues::is_CONSTANT_of_kind(p, K_rulebook_outcome)) {
		==> { -, Rvalues::to_named_rulebook_outcome(p) }
		return TRUE;
	}
	==> { fail nonterminal }
}

@ =
named_rulebook_outcome *Rulebooks::Outcomes::rbno_by_name(wording W) {
	parse_node *p = Lexicon::retrieve(MISCELLANEOUS_MC, W);
	if (Rvalues::is_CONSTANT_of_kind(p, K_rulebook_outcome))
		return Rvalues::to_named_rulebook_outcome(p);

	package_request *R = Hierarchy::local_package(OUTCOMES_HAP);
	Hierarchy::markup_wording(R, OUTCOME_NAME_HMD, W);

	named_rulebook_outcome *rbno = CREATE(named_rulebook_outcome);
	rbno->name = Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_named_rulebook_outcome(rbno), Task::language_of_syntax());
	rbno->nro_iname = Hierarchy::make_iname_with_memo(OUTCOME_HL, R, W);
	if (<notable-rulebook-outcomes>(W)) {
		int i = -1;
		switch (<<r>>) {
			case 0: i = RBNO4_INAME_HL; break;
			case 1: i = RBNO3_INAME_HL; break;
			case 2: i = RBNO2_INAME_HL; break;
			case 3: i = RBNO1_INAME_HL; break;
			case 4: i = RBNO0_INAME_HL; break;
		}
		if (i >= 0) {
			inter_name *iname = Hierarchy::find(i);
			Hierarchy::make_available(Emit::tree(), iname);
			Emit::named_iname_constant(iname, K_value, rbno->nro_iname);
		}
	}
	return rbno;
}

void Rulebooks::Outcomes::compile_default_outcome(outcomes *outs) {
	int rtrue = FALSE;
	rulebook_outcome *rbo = outs->default_named_outcome;
	if (rbo) {
		switch(rbo->kind_of_outcome) {
			case SUCCESS_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKSUCCEEDS_HL);
				Produce::inv_call_iname(Emit::tree(), iname);
				Produce::down(Emit::tree());
				Kinds::RunTime::emit_weak_id_as_val(K_rulebook_outcome);
				Produce::val_iname(Emit::tree(), K_value, rbo->outcome_name->nro_iname);
				Produce::up(Emit::tree());
				rtrue = TRUE;
				break;
			}
			case FAILURE_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKFAILS_HL);
				Produce::inv_call_iname(Emit::tree(), iname);
				Produce::down(Emit::tree());
				Kinds::RunTime::emit_weak_id_as_val(K_rulebook_outcome);
				Produce::val_iname(Emit::tree(), K_value, rbo->outcome_name->nro_iname);
				Produce::up(Emit::tree());
				rtrue = TRUE;
				break;
			}
		}
	} else {
		switch(outs->default_rule_outcome) {
			case SUCCESS_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKSUCCEEDS_HL);
				Produce::inv_call_iname(Emit::tree(), iname);
				Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
				rtrue = TRUE;
				break;
			}
			case FAILURE_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKFAILS_HL);
				Produce::inv_call_iname(Emit::tree(), iname);
				Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
				rtrue = TRUE;
				break;
			}
		}
	}

	if (rtrue) Produce::rtrue(Emit::tree());
}

rulebook_outcome *Rulebooks::Outcomes::rbo_from_context(named_rulebook_outcome *rbno) {
	phrase *ph = phrase_being_compiled;
	rulebook *rb;
	if (ph == NULL) return NULL;
	LOOP_OVER(rb, rulebook) {
		outcomes *outs = Rulebooks::get_outcomes(rb);
		rulebook_outcome *ro;
		for (ro = outs->named_outcomes; ro; ro = ro->next) {
			if (ro->outcome_name == rbno) {
				if (Rules::Bookings::list_contains_ph(Rulebooks::first_booking(rb), ph))
					return ro;
			}
		}
	}
	return NULL;
}

rulebook *Rulebooks::Outcomes::allow_outcome(named_rulebook_outcome *rbno) {
	if (Phrases::Context::outcome_restrictions_waived()) return NULL;
	phrase *ph = phrase_being_compiled;
	if (ph == NULL) return NULL;
	rulebook *rb;
	LOOP_OVER(rb, rulebook) {
		outcomes *outs = Rulebooks::get_outcomes(rb);
		if (Rules::Bookings::list_contains_ph(Rulebooks::first_booking(rb), ph)) {
			int okay = FALSE;
			rulebook_outcome *ro;
			for (ro = outs->named_outcomes; ro; ro = ro->next)
				if (ro->outcome_name == rbno)
					okay = TRUE;
			if (okay == FALSE) return rb;
		}
	}
	return NULL;
}

void Rulebooks::Outcomes::compile_outcome(named_rulebook_outcome *rbno) {
	rulebook_outcome *rbo = Rulebooks::Outcomes::rbo_from_context(rbno);
	if (rbo == NULL) {
		rulebook *rb;
		LOOP_OVER(rb, rulebook) {
			outcomes *outs = Rulebooks::get_outcomes(rb);
			rulebook_outcome *ro;
			for (ro = outs->named_outcomes; ro; ro = ro->next)
				if (ro->outcome_name == rbno) {
					rbo = ro;
					break;
				}
		}
		if (rbo == NULL) internal_error("rbno with no rb context");
	}
	switch(rbo->kind_of_outcome) {
		case SUCCESS_OUTCOME: {
			inter_name *iname = Hierarchy::find(RULEBOOKSUCCEEDS_HL);
			Produce::inv_call_iname(Emit::tree(), iname);
			Produce::down(Emit::tree());
			Kinds::RunTime::emit_weak_id_as_val(K_rulebook_outcome);
			Produce::val_iname(Emit::tree(), K_value, rbno->nro_iname);
			Produce::up(Emit::tree());
			Produce::rtrue(Emit::tree());
			break;
		}
		case FAILURE_OUTCOME: {
			inter_name *iname = Hierarchy::find(RULEBOOKFAILS_HL);
			Produce::inv_call_iname(Emit::tree(), iname);
			Produce::down(Emit::tree());
			Kinds::RunTime::emit_weak_id_as_val(K_rulebook_outcome);
			Produce::val_iname(Emit::tree(), K_value, rbno->nro_iname);
			Produce::up(Emit::tree());
			Produce::rtrue(Emit::tree());
			break;
		}
		case NO_OUTCOME:
			Produce::rfalse(Emit::tree());
			break;
		default:
			internal_error("bad RBO outcome kind");
	}
}

void Rulebooks::Outcomes::index_outcomes(OUTPUT_STREAM, outcomes *outs, int suppress_outcome) {
	if (suppress_outcome == FALSE) {
		rulebook_outcome *ro;
		for (ro = outs->named_outcomes; ro; ro = ro->next) {
			named_rulebook_outcome *rbno = ro->outcome_name;
			HTML::open_indented_p(OUT, 2, "hanging");
			WRITE("<i>outcome</i>&nbsp;&nbsp;");
			if (outs->default_named_outcome == ro) WRITE("<b>");
			WRITE("%+W", Nouns::nominative_singular(rbno->name));
			if (outs->default_named_outcome == ro) WRITE("</b> (default)");
			WRITE(" - <i>");
			switch(ro->kind_of_outcome) {
				case SUCCESS_OUTCOME: WRITE("a success"); break;
				case FAILURE_OUTCOME: WRITE("a failure"); break;
				case NO_OUTCOME: WRITE("no outcome"); break;
			}
			WRITE("</i>");
			HTML_CLOSE("p");
		}
	}
	if ((outs->default_named_outcome == NULL) &&
		(outs->default_rule_outcome != NO_OUTCOME) &&
		(suppress_outcome == FALSE)) {
		HTML::open_indented_p(OUT, 2, "hanging");
		WRITE("<i>default outcome is</i> ");
		switch(outs->default_rule_outcome) {
			case SUCCESS_OUTCOME: WRITE("success"); break;
			case FAILURE_OUTCOME: WRITE("failure"); break;
		}
		HTML_CLOSE("p");
	}
}

void Rulebooks::Outcomes::RulebookOutcomePrintingRule(void) {
	named_rulebook_outcome *rbno;
	LOOP_OVER(rbno, named_rulebook_outcome) {
		TEMPORARY_TEXT(RV)
		WRITE_TO(RV, "%+W", Nouns::nominative_singular(rbno->name));
		Emit::named_string_constant(rbno->nro_iname, RV);
		DISCARD_TEXT(RV)
	}

	inter_name *printing_rule_name = Kinds::Behaviour::get_iname(K_rulebook_outcome);
	packaging_state save = Routines::begin(printing_rule_name);
	inter_symbol *rbnov_s = LocalVariables::add_named_call_as_symbol(I"rbno");
	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, rbnov_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), PRINT_BIP);
			Produce::down(Emit::tree());
				Produce::val_text(Emit::tree(), I"(no outcome)");
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), PRINTSTRING_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, rbnov_s);
			Produce::up(Emit::tree());
			Produce::rfalse(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Routines::end(save);
}

inter_name *Rulebooks::Outcomes::get_default_value(void) {
	named_rulebook_outcome *rbno;
	LOOP_OVER(rbno, named_rulebook_outcome)
		return rbno->nro_iname;
	return NULL;
}

@ =
void Rulebooks::Outcomes::initialise_focus(focus *foc, kind *parameter_kind) {
	foc->rules_always_test_actor = FALSE;

	int parametrisation = PARAMETER_FOCUS;
	if (Kinds::Compare::eq(parameter_kind, K_action_name)) parametrisation = ACTION_FOCUS;
	else if (Kinds::Behaviour::definite(parameter_kind) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RulebookIndefinite),
			"this is a rulebook for values of a kind which isn't definite",
			"and doesn't tell me enough about what sort of value the rulebook "
			"should work on. For example, 'The mystery rules are a number based "
			"rulebook' is fine because 'number' is definite, but 'The mystery "
			"rules are a value based rulebook' is too vague.");
		parameter_kind = K_object;
	}
	foc->kind_of_parameter = parameter_kind;

	foc->rulebook_focus = parametrisation;
}

@ =
void Rulebooks::Outcomes::modify_rule_to_suit_focus(focus *foc, rule *R) {
	if (foc->rules_always_test_actor) {
		LOGIF(RULE_ATTACHMENTS,
			"Setting always test actor for destination rulebook\n");
		Rules::set_always_test_actor(R);
	}

	if (foc->rulebook_focus == PARAMETER_FOCUS){
		LOGIF(RULE_ATTACHMENTS,
			"Setting never test actor for destination rulebook\n");
		Rules::set_never_test_actor(R);
	}
}

int Rulebooks::Outcomes::get_focus(focus *foc) {
	return foc->rulebook_focus;
}

kind *Rulebooks::Outcomes::get_focus_parameter_kind(focus *foc) {
	return foc->kind_of_parameter;
}

void Rulebooks::Outcomes::set_focus_ata(focus *foc, int ata) {
	foc->rules_always_test_actor = ata;
}
