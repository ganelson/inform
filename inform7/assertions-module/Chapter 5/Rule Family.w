[RuleFamily::] Rule Family.

Imperative definitions of rules.

@

=
imperative_defn_family *RULE_NOT_IN_RULEBOOK_EFF_family = NULL; /* "At 9 PM: ...", "This is the zap rule: ..." */
imperative_defn_family *RULE_IN_RULEBOOK_EFF_family = NULL; /* "Before taking a container, ..." */

typedef struct rule_family_data {
	int not_in_rulebook;
	CLASS_DEFINITION
} rule_family_data;

@

=
void RuleFamily::create_family(void) {
	RULE_NOT_IN_RULEBOOK_EFF_family = ImperativeDefinitions::new_family(I"RULE_NOT_IN_RULEBOOK_EFF");
	METHOD_ADD(RULE_NOT_IN_RULEBOOK_EFF_family, CLAIM_IMP_DEFN_MTID, RuleFamily::RNIR_claim);
	METHOD_ADD(RULE_NOT_IN_RULEBOOK_EFF_family, NEW_PHRASE_IMP_DEFN_MTID, RuleFamily::rnir_new_phrase);
	RULE_IN_RULEBOOK_EFF_family     = ImperativeDefinitions::new_family(I"RULE_IN_RULEBOOK_EFF");
	METHOD_ADD(RULE_IN_RULEBOOK_EFF_family, CLAIM_IMP_DEFN_MTID, RuleFamily::RIR_claim);
	METHOD_ADD(RULE_IN_RULEBOOK_EFF_family, NEW_PHRASE_IMP_DEFN_MTID, RuleFamily::rir_new_phrase);
}

@ =
<rnir-preamble> ::=
	this is the {... rule} |                                  ==> { TRUE, - }
	this is the rule |                                        ==> @<Issue PM_NamelessRule problem@>
	this is ... rule |                                        ==> @<Issue PM_UnarticledRule problem@>
	this is ... rules |                                       ==> @<Issue PM_PluralisedRule problem@>
	<event-rule-preamble>                                     ==> { FALSE, - }

=
void RuleFamily::RNIR_claim(imperative_defn_family *self, imperative_defn *id) {
	wording W = Node::get_text(id->at);
	if (<rnir-preamble>(W)) {
		id->family = RULE_NOT_IN_RULEBOOK_EFF_family;
		rule_family_data *rfd = CREATE(rule_family_data);
		rfd->not_in_rulebook = TRUE;
		id->family_specific_data = STORE_POINTER_rule_family_data(rfd);
		if (<<r>>) {
			wording RW = GET_RW(<rnir-preamble>, 1);
			if (Rules::vet_name(RW)) Rules::obtain(RW, TRUE);
		}
	}
}

@ =
<rir-preamble> ::=
	... ( this is the {... rule} ) |                          ==> { TRUE, - }
	... ( this is the rule ) |                                ==> @<Issue PM_NamelessRule problem@>
	... ( this is ... rule ) |                                ==> @<Issue PM_UnarticledRule problem@>
	... ( this is ... rules ) |                               ==> @<Issue PM_PluralisedRule problem@>
	...                                                       ==> { FALSE, - }

@<Issue PM_NamelessRule problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamelessRule),
		"there are many rules in Inform",
		"so you need to give a name: 'this is the abolish dancing rule', say, "
		"not just 'this is the rule'.");
	==> { FALSE, - }

@<Issue PM_UnarticledRule problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnarticledRule),
		"a rule must be given a definite name",
		"which begins with 'the', just to emphasise that it is the only one "
		"with this name: 'this is the promote dancing rule', say, not just "
		"'this is promote dancing rule'.");
	==> { FALSE, - }

@<Issue PM_PluralisedRule problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PluralisedRule),
		"a rule must be given a definite name ending in 'rule' not 'rules'",
		"since the plural is only used for rulebooks, which can of course "
		"contain many rules at once.");
	==> { FALSE, - }

@ =
void RuleFamily::RIR_claim(imperative_defn_family *self, imperative_defn *id) {
	wording W = Node::get_text(id->at);
	if (<rir-preamble>(W)) {
		id->family = RULE_IN_RULEBOOK_EFF_family;
		rule_family_data *rfd = CREATE(rule_family_data);
		rfd->not_in_rulebook = FALSE;
		id->family_specific_data = STORE_POINTER_rule_family_data(rfd);
		if (<<r>>) {
			wording RW = GET_RW(<rir-preamble>, 2);
			if (Rules::vet_name(RW)) Rules::obtain(RW, TRUE);
		}
	}
}

int RuleFamily::is(imperative_defn *id) {
	if ((id->family == RULE_IN_RULEBOOK_EFF_family) ||
		(id->family == RULE_NOT_IN_RULEBOOK_EFF_family)) return TRUE;
	return FALSE;
}

int RuleFamily::not_in_rulebook(imperative_defn *id) {
	if (RuleFamily::is(id)) {
		rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
		return rfd->not_in_rulebook;
	}
	return FALSE;
}

@

=
void RuleFamily::rir_new_phrase(imperative_defn_family *self, imperative_defn *id, phrase *new_ph) {
	Rules::request_automatic_placement(
		Phrases::Usage::to_rule(&(new_ph->usage_data), id));
	new_ph->compile_with_run_time_debugging = TRUE;
}

@

=
void RuleFamily::rnir_new_phrase(imperative_defn_family *self, imperative_defn *id, phrase *new_ph) {
	Phrases::Usage::to_rule(&(new_ph->usage_data), id);
	new_ph->compile_with_run_time_debugging = TRUE;
}
