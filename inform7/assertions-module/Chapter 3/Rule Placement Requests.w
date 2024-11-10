[RulePlacement::] Rule Placement Requests.

Special sentences for listing named rules in particular rulebooks.

@ This section covers five forms of request to change the way rules are
filed in rulebooks; the test group |:placement| exercises these.

First, this handles the special meaning "X is listed in...":

=
<listed-in-sentence-object> ::=
	listed <np-unparsed> |    ==> { TRUE, RP[1] }
	not listed <np-unparsed>  ==> { FALSE, RP[1] }

@ =
int RulePlacement::listed_in_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule is listed in the turn sequence rulebook." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<listed-in-sentence-object>(OW))) {
				Annotations::write_int(V, rule_placement_sense_ANNOT, <<r>>);
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			RulePlacement::place_in_rulebook(V->next, V->next->next,
				Annotations::read_int(V, rule_placement_sense_ANNOT));
			break;
	}
	return FALSE;
}

@ And this is where we parse lists of rule names. The verbs "to be listed",
"to substitute for" and "to do nothing" are a little too common to accept
them in all circumstances, so we require their subjects to be plausible as rule
names. All rule names end in "rule", whereas other names mostly don't, so the
following won't pick up many false positives.

=
<nounphrase-rule-list> ::=
	... |                               ==> { lookahead }
	<nounphrase-rule> <np-rule-tail> |  ==> { 0, Diagrams::new_AND(R[2], RP[1], RP[2]) }
	<nounphrase-rule>                   ==> { 0, RP[1] }

<np-rule-tail> ::=
	, {_and} <nounphrase-rule-list> |   ==> { Wordings::first_wn(W), RP[1] }
	{_,/and} <nounphrase-rule-list>     ==> { Wordings::first_wn(W), RP[1] }

<nounphrase-rule> ::=
	... rule                            ==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

@ This handles the special meaning "X substitutes for Y".

=
<substitutes-for-sentence-object> ::=
	<nounphrase-rule> |                        ==> { NOT_APPLICABLE, RP[1] }
	<nounphrase-rule> if/when <np-unparsed> |  ==> { TRUE, RP[1] }; ((parse_node *) RP[1])->next = RP[2];
	<nounphrase-rule> unless <np-unparsed>     ==> { FALSE, RP[1] }; ((parse_node *) RP[1])->next = RP[2];

@ =
int RulePlacement::substitutes_for_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes slowly rule substitutes for the time passes rule." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<substitutes-for-sentence-object>(OW))) {
				Annotations::write_int(V, rule_placement_sense_ANNOT, <<r>>);
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			RulePlacement::request_substitute(V->next, V->next->next, V->next->next->next,
				Annotations::read_int(V, rule_placement_sense_ANNOT));
			break;
	}
	return FALSE;
}

@ A sentence in the form:

>> The print fancy final score rule substitutes for the print final score rule.

It also exists in a form with a condition attached:

>> The print fancy final score rule substitutes for the print final score rule when ...

This optional tail is eventually required to match <spec-condition>,
but that parsing is done later on. For now, we only parse for rules in both the
subject and object NPs.

=
<substitutes-for-sentence-subject> ::=
	<rule-name> |    ==> { TRUE, RP[1] }
	...              ==> @<Issue PM_NoSuchRuleExists problem@>

<substitutes-for-sentence-object-inner> ::=
	<rule-name> |    ==> { TRUE, RP[1] }
	...              ==> @<Issue PM_NoSuchRuleExists problem@>

@<Issue PM_NoSuchRuleExists problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoSuchRuleExists));
	Problems::issue_problem_segment(
		"In %1, you gave '%2' where a rule was required.");
	Problems::issue_problem_end();
	==> { FALSE, - };

@ =
void RulePlacement::request_substitute(parse_node *p1, parse_node *p2, parse_node *p3,
	int sense) {
	<substitutes-for-sentence-subject>(Node::get_text(p1));
	if (<<r>> == FALSE) return;
	rule *new_rule = <<rp>>;
	<substitutes-for-sentence-object-inner>(Node::get_text(p2));
	if (<<r>> == FALSE) return;
	rule *old_rule = <<rp>>;
	wording CW = EMPTY_WORDING;
	if (p3) CW = Node::get_text(p3);
	Rules::impose_constraint(new_rule, old_rule, CW, (sense)?FALSE:TRUE);
}

@ A sentence in the form:

>> The print final score rule does nothing.
>> The print final score rule does nothing unless ....

is parsed similarly. The subject NP is an articled list, each entry of which
must be a rule, and the optional condition is put aside for later, but must
eventually match <spec-condition>.

=
<does-nothing-sentence-object> ::=
	nothing

<does-nothing-sentence-subject> ::=
	<rule-name> |    ==> { TRUE, RP[1] }
	...              ==> @<Issue PM_NoSuchRuleExists problem@>

@ =
int RulePlacement::does_nothing_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule does nothing." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<does-nothing-sentence-object>(OW))) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			RulePlacement::constrain_effect(V->next, NULL, NOT_APPLICABLE);
			break;
	}
	return FALSE;
}

@ =
int RulePlacement::does_nothing_if_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[2]):EMPTY_WORDING;
	wording CW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule does nothing if ..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<does-nothing-sentence-object>(OW))) {
				<np-unparsed>(SW);
				V->next = <<rp>>;
				<np-unparsed>(CW);
				parse_node *O = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			RulePlacement::constrain_effect(V->next, V->next->next, FALSE);
			break;
	}
	return FALSE;
}

@ =
int RulePlacement::does_nothing_unless_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[2]):EMPTY_WORDING;
	wording CW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule does nothing unless ..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<does-nothing-sentence-object>(OW))) {
				<np-unparsed>(SW);
				V->next = <<rp>>;
				<np-unparsed>(CW);
				parse_node *O = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			RulePlacement::constrain_effect(V->next, V->next->next, TRUE);
			break;
	}
	return FALSE;
}

@ =
void RulePlacement::constrain_effect(parse_node *p1, parse_node *p2, int sense) {
	if (Node::get_type(p1) == AND_NT) {
		RulePlacement::constrain_effect(p1->down, p2, sense);
		RulePlacement::constrain_effect(p1->down->next, p2, sense);
		return;
	}
	<does-nothing-sentence-subject>(Node::get_text(p1));
	if (<<r>> == FALSE) return;
	rule *existing_rule = <<rp>>;
	if (p2)
		Rules::impose_constraint(NULL, existing_rule, Node::get_text(p2), sense);
	else
		Rules::impose_constraint(NULL, existing_rule, EMPTY_WORDING, FALSE);
}

@ Explicit listing sentences allow the source text to control which rulebook(s)
a given rule appears in, and (within limits) where. A simple example:

>> The can't act in the dark rule is not listed in the visibility rules.

The subject noun phrase is an articled list, each entry of which must match:

=
<listed-in-sentence-subject> ::=
	<rule-name> |    ==> { TRUE, RP[1] }
	...              ==> { FALSE, - }; @<Issue PM_NoSuchRuleExists problem@>

@ The object NP is more flexible:

=
<listed-in-sentence-object-inner> ::=
	in any rulebook |                            ==> { ANY_RULE_PLACEMENT, - }
	in <destination-rulebook> |                  ==> { MIDDLE_PLACEMENT + 1000*IN_SIDE, RP[1] }
	first in <destination-rulebook> |            ==> { FIRST_PLACEMENT  + 1000*IN_SIDE, RP[1] }
	last in <destination-rulebook> |             ==> { LAST_PLACEMENT   + 1000*IN_SIDE, RP[1] }
	very first in <destination-rulebook> |       ==> @<Issue PM_CannotPlaceVeryFirst problem@>
	very last in <destination-rulebook> |        ==> @<Issue PM_CannotPlaceVeryFirst problem@>
	instead of <rule-name> in <rulebook-name> |  ==> { MIDDLE_PLACEMENT + 1000*INSTEAD_SIDE, RP[2], <<rule:rel>> = RP[1] }
	instead of <rule-name> in ... |              ==> @<Issue PM_NoSuchRulebookPlacement problem@>
	instead of ... in ... |                      ==> @<Issue PM_NoSuchRuleExists problem@>
	before <rule-name> in <rulebook-name> |      ==> { MIDDLE_PLACEMENT + 1000*BEFORE_SIDE, RP[2], <<rule:rel>> = RP[1] }
	before <rule-name> in ... |                  ==> @<Issue PM_NoSuchRulebookPlacement problem@>
	before ... in ... |                          ==> @<Issue PM_NoSuchRuleExists problem@>
	after <rule-name> in <rulebook-name> |       ==> { MIDDLE_PLACEMENT + 1000*AFTER_SIDE, RP[2], <<rule:rel>> = RP[1] }
	after <rule-name> in ... |                   ==> @<Issue PM_NoSuchRulebookPlacement problem@>
	after ... in ... |                           ==> @<Issue PM_NoSuchRuleExists problem@>
	instead of ... |                             ==> @<Issue PM_UnspecifiedRulebookPlacement problem@>
	before ... |                                 ==> @<Issue PM_UnspecifiedRulebookPlacement problem@>
	after ... |                                  ==> @<Issue PM_UnspecifiedRulebookPlacement problem@>
	...                                          ==> @<Issue PM_ImproperRulePlacement problem@>

<destination-rulebook> ::=
	<rulebook-name> |                            ==> { 0, RP[1] }
	...                                          ==> @<Issue PM_NoSuchRulebookPlacement problem@>

@

@d ANY_RULE_PLACEMENT 1000001
@d BAD_RULE_PLACEMENT 1000000

@<Issue PM_CannotPlaceVeryFirst problem@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CannotPlaceVeryFirst));
	Problems::issue_problem_segment(
		"In %1, you asked to change or impose a 'very first' or 'very last' "
		"rule for a rulebook. But those rules are restricted and can be written "
		"only alongside the rulebook itself, and cannot afterwards be changed "
		"with sentences like this one.");
	Problems::issue_problem_end();
	==> { BAD_RULE_PLACEMENT, - };

@<Issue PM_UnspecifiedRulebookPlacement problem@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnspecifiedRulebookPlacement));
	Problems::issue_problem_segment(
		"In %1, you didn't specify in which rulebook the rule was to "
		"be listed, only which existing rule it should go before or "
		"after.");
	Problems::issue_problem_end();
	==> { BAD_RULE_PLACEMENT, - };

@<Issue PM_ImproperRulePlacement problem@> =
	@<Actually issue PM_ImproperRulePlacement problem@>;
	==> { BAD_RULE_PLACEMENT, - };

@<Actually issue PM_ImproperRulePlacement problem@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ImproperRulePlacement));
	Problems::issue_problem_segment(
		"In %1, you used the special verb 'to be listed' - which specifies "
		"how rules are listed in rulebooks - in a way I didn't recognise. "
		"The usual form is: 'The summer breeze rule is listed in the "
		"meadow noises rulebook'.");
	Problems::issue_problem_end();

@<Issue PM_NoSuchRulebookPlacement problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoSuchRulebookPlacement));
	Problems::issue_problem_segment(
		"In %1, you gave '%2' where a rulebook was required.");
	Problems::issue_problem_end();

@ =
void RulePlacement::place_in_rulebook(parse_node *p1, parse_node *p2, int sense) {
	if (Node::get_type(p1) == AND_NT) {
		RulePlacement::place_in_rulebook(p1->down, p2, sense);
		RulePlacement::place_in_rulebook(p1->down->next, p2, sense);
		return;
	}
	@<Make single placement@>;
}

@<Make single placement@> =
	LOGIF(RULE_ATTACHMENTS, "Placement sentence (%d):\np1=$T\np2=$T\n", sense, p1, p2);

	int any, side, new_rule_placement;
	rulebook *given_rulebook;
	rule *given_rule, *relative_rule;
	@<Parse the wording to find how to place@>;

	if ((sense == FALSE) &&
		((new_rule_placement != MIDDLE_PLACEMENT) || (side != IN_SIDE)))
		@<Issue PM_BadRulePlacementNegation problem@>;

	if (any) @<Detach from all rulebooks@>;
	if (sense == FALSE) @<Detach only from this rulebook@>;

	booking *new_rule_booking = RuleBookings::new(given_rule);
	Rules::set_kind_from(given_rule, given_rulebook);
	if (relative_rule) {
		LOGIF(RULE_ATTACHMENTS, "Relative to which = %W\n", relative_rule->name);
		RTRulebooks::affected_by_placement(given_rulebook, current_sentence);
		if (Rulebooks::rule_in_rulebook(relative_rule, given_rulebook) == FALSE)
			@<Issue PM_PlaceWithMissingRule problem@>;
	}
	Rulebooks::attach_rule(given_rulebook, new_rule_booking, new_rule_placement,
		side, relative_rule);

@<Parse the wording to find how to place@> =
	int pc = problem_count;
	<<rule:rel>> = NULL;
	<listed-in-sentence-object-inner>(Node::get_text(p2));
	if ((problem_count > pc) || (<<r>> == BAD_RULE_PLACEMENT)) return;
	given_rulebook = <<rp>>;
	relative_rule = <<rule:rel>>;
	int pair = <<r>>;
	any = FALSE;
	if (pair == BAD_RULE_PLACEMENT) return;
	if (pair == ANY_RULE_PLACEMENT) {
		any = TRUE;
		if (sense == TRUE) { @<Actually issue PM_ImproperRulePlacement problem@>; return; }
		new_rule_placement = MIDDLE_PLACEMENT; side = IN_SIDE;
	} else {
		new_rule_placement = pair%1000; side = pair/1000;
	}
	<listed-in-sentence-subject>(Node::get_text(p1));
	if (<<r>> == FALSE) return;
	given_rule = <<rp>>;

@<Issue PM_BadRulePlacementNegation problem@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_BadRulePlacementNegation));
	Problems::issue_problem_segment(
		"In %1, you used the special verb 'to be listed' - which specifies "
		"how rules are listed in rulebooks - in a way too complicated to "
		"be accompanied by 'not', so that the result was too vague. "
		"The usual form is: 'The summer breeze rule is not listed in the "
		"meadow noises rulebook'.");
	Problems::issue_problem_end();
	return;

@<Detach from all rulebooks@> =
	rulebook *rb;
	LOOP_OVER(rb, rulebook) Rulebooks::detach_rule(rb, given_rule);
	return;

@<Detach only from this rulebook@> =
	RTRulebooks::affected_by_placement(given_rulebook, current_sentence);
	Rulebooks::detach_rule(given_rulebook, given_rule);
	return;

@<Issue PM_PlaceWithMissingRule problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, given_rulebook->primary_name);
	Problems::quote_wording(3, relative_rule->name);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_PlaceWithMissingRule));
	Problems::issue_problem_segment(
		"In %1, you talk about the position of the rule '%3' "
		"in the rulebook '%2', but in fact that rule isn't in this "
		"rulebook, so the placing instruction makes no sense.");
	Problems::issue_problem_end();
	return;
