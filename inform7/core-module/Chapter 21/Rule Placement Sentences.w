[Rules::Placement::] Rule Placement Sentences.

To parse and act upon explicit sentences like "The fire alarm
rule is listed after the burglar alarm rule in the House Security rules."

@ Booked rules can be declared wrapping I6 routines which we assume
are defined either in the I6 template or in an I6 inclusion.

The following is called early in the run on sentences like "The can't act
in the dark rule translates into I6 as |"CANT_ACT_IN_THE_DARK_R"|." The
node |p->down->next| is the I7 name, and |p->down->next->next| is the I6
name, whose double-quotes have already been removed.

=
void Rules::Placement::declare_I6_written_rule(wording W, parse_node *p2) {
	wchar_t *I6_name = Lexer::word_text(Wordings::first_wn(ParseTree::get_text(p2)));
	rule *R = Rules::new(W, TRUE);
	Rules::set_I6_definition(R, I6_name);
}

@ In order to parse sentences about how rules are placed in rulebooks, we
need to be able to parse the relevant names. (The definite article can
optionally be used.)

=
<rulebook-name> internal {
	W = Articles::remove_the(W);
	parse_node *p = ExParser::parse_excerpt(RULEBOOK_MC, W);
	if (Rvalues::is_CONSTANT_construction(p, CON_rulebook)) {
		*XP = Rvalues::to_rulebook(p);
		return TRUE;
	}
	return FALSE;
}

<rule-name> internal {
	W = Articles::remove_the(W);
	rule *R = Rules::by_name(W);
	if (R) {
		*XP = R;
		return TRUE;
	}
	return FALSE;
}

@ This handles the special meaning "X is listed in...".

=
<listed-in-sentence-object> ::=
	listed <nounphrase> |					==> TRUE; *XP = RP[1];
	not listed <nounphrase>					==> FALSE; *XP = RP[1];

@ =
int Rules::Placement::listed_in_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule is listed in the turn sequence rulebook." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<listed-in-sentence-object>(OW))) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				ParseTree::annotate_int(V, listing_sense_ANNOT, <<r>>);
				parse_node *O = <<rp>>;
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			Rules::Placement::place_in_rulebook(V->next, V->next->next,
				ParseTree::int_annotation(V, listing_sense_ANNOT));
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
	... |											==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<nounphrase-rule> <np-rule-tail> |			==> 0; *XP = NounPhrases::PN_pair(AND_NT, Wordings::one_word(R[2]), RP[1], RP[2])
	<nounphrase-rule>								==> 0; *XP = RP[1]

<np-rule-tail> ::=
	, {_and} <nounphrase-rule-list> |				==> Wordings::first_wn(W); *XP= RP[1]
	{_,/and} <nounphrase-rule-list>					==> Wordings::first_wn(W); *XP= RP[1]

<nounphrase-rule> ::=
	... rule										==> GENERATE_RAW_NP

@ This handles the special meaning "X substitutes for Y".

=
<substitutes-for-sentence-object> ::=
	<nounphrase-rule> |							==> NOT_APPLICABLE; *XP = RP[1];
	<nounphrase-rule> if/when <nounphrase> |	==> TRUE; *XP = RP[1]; ((parse_node *) RP[1])->next = RP[2];
	<nounphrase-rule> unless <nounphrase>		==> FALSE; *XP = RP[1]; ((parse_node *) RP[1])->next = RP[2];

@ =
int Rules::Placement::substitutes_for_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes slowly rule substitutes for the time passes rule." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<substitutes-for-sentence-object>(OW))) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				ParseTree::annotate_int(V, listing_sense_ANNOT, <<r>>);
				parse_node *O = <<rp>>;
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			Rules::Placement::request_substitute(V->next, V->next->next, V->next->next->next,
				ParseTree::int_annotation(V, listing_sense_ANNOT));
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
	<rule-name> |											==> TRUE; *XP = RP[1];
	...														==> @<Issue PM_NoSuchRuleExists problem@>

<substitutes-for-sentence-object-inner> ::=
	<rule-name> |											==> TRUE; *XP = RP[1];
	...														==> @<Issue PM_NoSuchRuleExists problem@>

@<Issue PM_NoSuchRuleExists problem@> =
	*X = FALSE;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_NoSuchRuleExists));
	Problems::issue_problem_segment(
		"In %1, you gave '%2' where a rule was required.");
	Problems::issue_problem_end();

@ =
void Rules::Placement::request_substitute(parse_node *p1, parse_node *p2, parse_node *p3,
	int sense) {
	<substitutes-for-sentence-subject>(ParseTree::get_text(p1));
	if (<<r>> == FALSE) return;
	rule *new_rule = <<rp>>;
	<substitutes-for-sentence-object-inner>(ParseTree::get_text(p2));
	if (<<r>> == FALSE) return;
	rule *old_rule = <<rp>>;
	wording CW = EMPTY_WORDING;
	if (p3) CW = ParseTree::get_text(p3);
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
	<rule-name> |											==> TRUE; *XP = RP[1];
	...														==> @<Issue PM_NoSuchRuleExists problem@>

@ =
int Rules::Placement::does_nothing_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule does nothing." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<does-nothing-sentence-object>(OW))) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				parse_node *O = <<rp>>;
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			Rules::Placement::constrain_effect(V->next, NULL, NOT_APPLICABLE);
			break;
	}
	return FALSE;
}

@ =
int Rules::Placement::does_nothing_if_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[2]):EMPTY_WORDING;
	wording CW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule does nothing if ..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<does-nothing-sentence-object>(OW))) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				<nounphrase>(SW);
				V->next = <<rp>>;
				<nounphrase>(CW);
				parse_node *O = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			Rules::Placement::constrain_effect(V->next, V->next->next, FALSE);
			break;
	}
	return FALSE;
}

@ =
int Rules::Placement::does_nothing_unless_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[2]):EMPTY_WORDING;
	wording CW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The time passes rule does nothing unless ..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-rule-list>(SW)) && (<does-nothing-sentence-object>(OW))) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				<nounphrase>(SW);
				V->next = <<rp>>;
				<nounphrase>(CW);
				parse_node *O = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE_FOR_RULE_FILING_SMFT:
			Rules::Placement::constrain_effect(V->next, V->next->next, TRUE);
			break;
	}
	return FALSE;
}

@ =
void Rules::Placement::constrain_effect(parse_node *p1, parse_node *p2, int sense) {
	if (ParseTree::get_type(p1) == AND_NT) {
		Rules::Placement::constrain_effect(p1->down, p2, sense);
		Rules::Placement::constrain_effect(p1->down->next, p2, sense);
		return;
	}
	<does-nothing-sentence-subject>(ParseTree::get_text(p1));
	if (<<r>> == FALSE) return;
	rule *existing_rule = <<rp>>;
	if (p2)
		Rules::impose_constraint(NULL, existing_rule, ParseTree::get_text(p2), sense);
	else
		Rules::impose_constraint(NULL, existing_rule, EMPTY_WORDING, FALSE);
}

@ =
rule *relative_to_which = NULL;

@ Explicit listing sentences allow the source text to control which rulebook(s)
a given rule appears in, and (within limits) where. A simple example:

>> The can't act in the dark rule is not listed in the visibility rules.

The subject noun phrase is an articled list, each entry of which must match:

=
<listed-in-sentence-subject> ::=
	<rule-name> |								==> TRUE; *XP = RP[1];
	...											==> FALSE; @<Issue PM_NoSuchRuleExists problem@>

@ The object NP is more flexible:

=
<listed-in-sentence-object-inner> ::=
	in any rulebook |							==> ANY_RULE_PLACEMENT
	in <destination-rulebook> |					==> MIDDLE_PLACEMENT + 1000*IN_SIDE; *XP = RP[1];
	first in <destination-rulebook> |			==> FIRST_PLACEMENT  + 1000*IN_SIDE; *XP = RP[1];
	last in <destination-rulebook> |			==> LAST_PLACEMENT   + 1000*IN_SIDE; *XP = RP[1];
	instead of <rule-name> in <rulebook-name> |	==> MIDDLE_PLACEMENT + 1000*INSTEAD_SIDE; relative_to_which = RP[1]; *XP = RP[2];
	instead of <rule-name> in ... |				==> @<Issue PM_NoSuchRulebookPlacement problem@>
	instead of ... in ... |						==> @<Issue PM_NoSuchRuleExists problem@>
	before <rule-name> in <rulebook-name> |		==> MIDDLE_PLACEMENT + 1000*BEFORE_SIDE; relative_to_which = RP[1]; *XP = RP[2];
	before <rule-name> in ... |					==> @<Issue PM_NoSuchRulebookPlacement problem@>
	before ... in ... |							==> @<Issue PM_NoSuchRuleExists problem@>
	after <rule-name> in <rulebook-name> |		==> MIDDLE_PLACEMENT + 1000*AFTER_SIDE; relative_to_which = RP[1]; *XP = RP[2];
	after <rule-name> in ... |					==> @<Issue PM_NoSuchRulebookPlacement problem@>
	after ... in ... |							==> @<Issue PM_NoSuchRuleExists problem@>
	instead of ... |							==> @<Issue PM_UnspecifiedRulebookPlacement problem@>
	before ... |								==> @<Issue PM_UnspecifiedRulebookPlacement problem@>
	after ... |									==> @<Issue PM_UnspecifiedRulebookPlacement problem@>
	...											==> @<Issue PM_ImproperRulePlacement problem@>

<destination-rulebook> ::=
	<rulebook-name> |							==> 0; *XP = RP[1];
	...											==> @<Issue PM_NoSuchRulebookPlacement problem@>

@

@d ANY_RULE_PLACEMENT 1000001
@d BAD_RULE_PLACEMENT 1000000

@<Issue PM_UnspecifiedRulebookPlacement problem@> =
	*X = BAD_RULE_PLACEMENT;
	Problems::quote_source(1, current_sentence);
	Problems::Issue::handmade_problem(_p_(PM_UnspecifiedRulebookPlacement));
	Problems::issue_problem_segment(
		"In %1, you didn't specify in which rulebook the rule was to "
		"be listed, only which existing rule it should go before or "
		"after.");
	Problems::issue_problem_end();

@<Issue PM_ImproperRulePlacement problem@> =
	*X = BAD_RULE_PLACEMENT;
	@<Actually issue PM_ImproperRulePlacement problem@>;

@<Actually issue PM_ImproperRulePlacement problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::Issue::handmade_problem(_p_(PM_ImproperRulePlacement));
	Problems::issue_problem_segment(
		"In %1, you used the special verb 'to be listed' - which specifies "
		"how rules are listed in rulebooks - in a way I didn't recognise. "
		"The usual form is: 'The summer breeze rule is listed in the "
		"meadow noises rulebook'.");
	Problems::issue_problem_end();

@<Issue PM_NoSuchRulebookPlacement problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_NoSuchRulebookPlacement));
	Problems::issue_problem_segment(
		"In %1, you gave '%2' where a rulebook was required.");
	Problems::issue_problem_end();

@ =
void Rules::Placement::place_in_rulebook(parse_node *p1, parse_node *p2, int sense) {
	if (ParseTree::get_type(p1) == AND_NT) {
		Rules::Placement::place_in_rulebook(p1->down, p2, sense);
		Rules::Placement::place_in_rulebook(p1->down->next, p2, sense);
		return;
	}

	int side, new_rule_placement;
	LOGIF(RULE_ATTACHMENTS, "Placement sentence (%d):\np1=$T\np2=$T\n", sense, p1, p2);

	relative_to_which = NULL;
	int pc = problem_count;
	<listed-in-sentence-object-inner>(ParseTree::get_text(p2));
	if (problem_count > pc) return;
	rulebook *the_rulebook = <<rp>>;
	int pair = <<r>>;
	if (pair == BAD_RULE_PLACEMENT) return;
	if (pair == ANY_RULE_PLACEMENT) {
		if (sense == TRUE) {
			@<Actually issue PM_ImproperRulePlacement problem@>;
			return;
		}
		new_rule_placement = MIDDLE_PLACEMENT; side = IN_SIDE;
	} else {
		new_rule_placement = pair%1000; side = pair/1000;
	}

	if ((sense == FALSE) &&
		((new_rule_placement != MIDDLE_PLACEMENT) || (side != IN_SIDE))) {
		Problems::quote_source(1, current_sentence);
		Problems::Issue::handmade_problem(_p_(PM_BadRulePlacementNegation));
		Problems::issue_problem_segment(
			"In %1, you used the special verb 'to be listed' - which specifies "
			"how rules are listed in rulebooks - in a way too complicated to "
			"be accompanied by 'not', so that the result was too vague. "
			"The usual form is: 'The summer breeze rule is not listed in the "
			"meadow noises rulebook'.");
		Problems::issue_problem_end();
		return;
	}

	<listed-in-sentence-subject>(ParseTree::get_text(p1));
	if (<<r>> == FALSE) return;
	rule *existing_rule = <<rp>>;

	if (pair == ANY_RULE_PLACEMENT) {
		rulebook *rb;
		LOOP_OVER(rb, rulebook) Rulebooks::detach_rule(rb, existing_rule);
		return;
	}

	if (sense == FALSE) {
		Rulebooks::affected_by_placement(the_rulebook, current_sentence);
		Rulebooks::detach_rule(the_rulebook, existing_rule);
		return;
	}

	booking *new_rule_booking = Rules::Bookings::new(existing_rule);
	Rules::set_kind_from(existing_rule, the_rulebook);
	if (relative_to_which) {
		LOGIF(RULE_ATTACHMENTS, "Relative to which = %W\n", relative_to_which->name);
		Rulebooks::affected_by_placement(the_rulebook, current_sentence);
		if (Rulebooks::rule_in_rulebook(relative_to_which, the_rulebook) == FALSE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, the_rulebook->primary_name);
			Problems::quote_wording(3, relative_to_which->name);
			Problems::Issue::handmade_problem(_p_(PM_PlaceWithMissingRule));
			Problems::issue_problem_segment(
				"In %1, you talk about the position of the rule '%3' "
				"in the rulebook '%2', but in fact that rule isn't in this "
				"rulebook, so the placing instruction makes no sense.");
			Problems::issue_problem_end();
			return;
		}
	}
	Rulebooks::attach_rule(the_rulebook, new_rule_booking, new_rule_placement,
		side, relative_to_which);
}
