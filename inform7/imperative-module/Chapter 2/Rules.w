[Rules::] Rules.

Rules contain imperative code which is executed when certain actions, activities
or other processes are being followed.

@h Introduction.
Rule and phrase definitions have a similar syntax, in some ways -- they open
with a declaration, there's a colon, and then we (often) have a block of
imperative code to show what they do:
= (text as Inform 7)
RULE                                        PHRASE
Before eating:                              To extinguish (C - a candle):
	say "The candle flickers ominously."        now C is unlit;
	                                            say "Suddenly [the C] blows out."
=
Despite the similarities, rules are not the same thing as phrases. Some rules,
such as the one in this example, give a definition which looks like the body
of a phrase, and indeed inside the compiler it is stored as such, in the 
|defn_as_phrase| field of a //rule//. But other rules are written quite
differently:
= (text as Inform 7)
The can't reach inside rooms rule translates into I6 as |"CANT_REACH_INSIDE_ROOMS_R"|.
=
and this one is defined by a low-level Inter function, and not a phrase at all.
In any case, rules and phrases have quite different header syntax, and have
different dynamics altogether. In short, then: rules are not phrases.

=
typedef struct rule {
	struct wording name; /* name of the rule being booked */
	int explicitly_named; /* was this rule explicitly named when created? */

	struct kind *kind_of_rule; /* determined from its rulebook(s) */
	struct rulebook *kind_of_rule_set_from;

	struct phrase *defn_as_phrase; /* if defined by an I7 phrase */
	struct stacked_variable_owner_list *variables_visible_in_definition; /* if so */

	struct booking *automatic_booking; /* how this is placed in rulebooks */

	struct linked_list *applicability_conditions; /* of //applicability_condition// */

	struct rule_response responses[26]; /* responses (A), (B), ... */

	struct rule_indexing_data indexing_data;
	struct rule_compilation_data compilation_data;
	CLASS_DEFINITION
} rule;

@ Rules are created before their definitions can be parsed or compiled. A
typical rule like so:

>> Before eating (this is the must say grace rule): ...

causes "must say grace rule" to be registered as a constant value early in
Inform's run, allowing it to be a property value, or a table entry, for
example. Note that the rule may just as well be nameless, as it would have
been if the "(this is... )" part had been omitted.

Some rules are nameless, and there can be any number of those. But if a rule
does have a name, then that name must be unique. The following fetches the
rule called |W|, creating it if necessary.

=
rule *Rules::obtain(wording W, int named) {
	if (Wordings::nonempty(W)) {
		W = Articles::remove_the(W);
		rule *R = Rules::by_name(W);
		if (R) return R;
	}
	rule *R = CREATE(rule);
	R->name = EMPTY_WORDING;
	R->explicitly_named = named;

	R->kind_of_rule = NULL;
	R->kind_of_rule_set_from = NULL;

	R->defn_as_phrase = NULL;
	R->variables_visible_in_definition = NULL;
	R->automatic_booking = NULL;
	R->applicability_conditions = NEW_LINKED_LIST(applicability_condition);
	for (int l=0; l<26; l++) R->responses[l] = Rules::new_rule_response();
	R->compilation_data = RTRules::new_compilation_data(R);
	R->indexing_data = IXRules::new_indexing_data(R);
	if ((Wordings::nonempty(W)) && (Rules::vet_name(W))) {
		R->name = W;
		Rules::register_name(R);
	}
	return R;
}

@h Names of rules.
Rule names must pass the following sanity check:

=
int PM_RuleWithComma_issued_at = -1;
int Rules::vet_name(wording W) {
	if (<unsuitable-name>(W)) {
		if (PM_RuleWithComma_issued_at != Wordings::first_wn(W)) {
			PM_RuleWithComma_issued_at = Wordings::first_wn(W);
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_RuleWithComma),
				"a rule name is not allowed to contain punctuation, or to consist only "
				"of an article like 'a' or 'an', or to contain double-quoted text",
				"because this leads to too much ambiguity later on.");
		}
		return FALSE;
	}
	return TRUE;
}

@ The names of rules become proper nouns in the lexicon. There are typically some
hundreds of these and we make a modest speed gain by registering rule names which
end in "rule" slightly differently. (Not all rule names do: those for timed events do not.)

=
<rule-name-formal> ::=
	... rule

@ =
void Rules::register_name(rule *R) {
	unsigned int mc = RULE_MC;
	if (<rule-name-formal>(R->name)) mc = MISCELLANEOUS_MC;
	Nouns::new_proper_noun(R->name, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		mc, Rvalues::from_rule(R), Task::language_of_syntax());
}

rule *Rules::by_name(wording W) {
	if (Wordings::empty(W)) return NULL;
	W = Articles::remove_the(W);
	unsigned int mc = RULE_MC;
	if (<rule-name-formal>(W)) mc = MISCELLANEOUS_MC;
	parse_node *p = Lexicon::retrieve(mc, W);
	if (Rvalues::is_CONSTANT_construction(p, CON_rule))
		return Rvalues::to_rule(p);
	return NULL;
}

@h The kind of a rule.
Given that Inform authors can refer to (named) rules as constant values, they
need to have kinds, and it is not obvious what those should be. Clearly
some form of "K-based rule producing L" would be reasonable, but leaving K
and L just to be "value" -- as the earliest versions of Inform 7 did, in the
mid-2000s -- would be indefinite. Constants should always have definite kinds,
because otherwise kind inference will fail on phrases like:
>> let R be the foo rule;
So we have to give each rule a definite kind. Unfortunately for us, there is
no indication of that kind in its declaration, as such: we must infer the
kind from how the rule is used, that is, from the rulebook it is put into.
And since a rule can be in multiple rulebooks, we have to check that this
does not lead to an inconsistency.

The following function is called when a rule is added to a rulebook:

=
void Rules::set_kind_from(rule *R, rulebook *RB) {
	kind *K = Rulebooks::contains_kind(RB);
	if (R->kind_of_rule) {
		if (Kinds::compatible(R->kind_of_rule, K) != ALWAYS_MATCH) {
			kind *B1 = NULL, *B2 = NULL, *P1 = NULL, *P2 = NULL;
			Kinds::binary_construction_material(R->kind_of_rule, &B1, &P1);
			Kinds::binary_construction_material(K, &B2, &P2);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, R->name);
			Problems::quote_kind(3, B1);
			Problems::quote_kind(4, P1);
			Problems::quote_kind(5, B2);
			Problems::quote_kind(6, P2);
			Problems::quote_wording_as_source(7, R->kind_of_rule_set_from->primary_name);
			Problems::quote_wording_as_source(8, RB->primary_name);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_RuleInIncompatibleRulebooks));
			Problems::issue_problem_segment(
				"You've asked to put the rule '%2' into the rulebook %8, which is based "
				"on %5 and produces %6; but it was originally written to go into a "
				"rulebook of a different kind, %7, which is based on %3 and produces %4. "
				"Because those kinds are different, '%2' can't go into %8.");
			Problems::issue_problem_end();
		}
	}
	R->kind_of_rule = K;
	R->kind_of_rule_set_from = RB;
}

@ If a rule has no known kind -- if it is not in a rulebook, for example --
then the following says it is an action-based rule producing nothing, unless
we are in Basic Inform only, in which case it is a nothing-based rule producing
nothing.

=
kind *Rules::to_kind(rule *R) {
	kind *K = R->kind_of_rule;
	if (K == NULL) {
		if (PluginManager::active(actions_plugin))
			K = Kinds::binary_con(CON_rule, K_action_name, K_void);
		else
			K = Kinds::binary_con(CON_rule, K_void, K_void);
	}
	return K;
}

@h Defining rules with imperative I7 code.
Once a rule has been created, it can be given a definition body in the form
of a //phrase// as follows:

=
void Rules::set_defn_as_phrase(rule *R, phrase *ph) {
	R->defn_as_phrase = ph;
}

phrase *Rules::get_defn_as_phrase(rule *R) {
	if (R == NULL) return NULL;
	return R->defn_as_phrase;
}

@ Inside such a definition, certain stacked variables may be in scope. For
example, if a rule is in an activity rulebook, then it will be able to see
the variables belonging to that activity.

=
void Rules::put_variables_in_scope(rule *R, stacked_variable_owner_list *stvol) {
	R->variables_visible_in_definition =
		StackedVariables::append_owner_list(R->variables_visible_in_definition, stvol);
}

void Rules::put_action_variables_in_scope(rule *R) {
	#ifdef IF_MODULE
	Rules::put_variables_in_scope(R, all_nonempty_stacked_action_vars);
	if (all_action_processing_vars == NULL) internal_error("APROC not ready");
	Rules::put_variables_in_scope(R, all_action_processing_vars);
	#endif
}




@

= (early code)
rule *rule_being_compiled = NULL; /* rule whose phrase's definition is being compiled */
rule *adopted_rule_for_compilation = NULL; /* when a new response is being compiled */
int adopted_marker_for_compilation = -1; /* when a new response is being compiled */

@ Applicability conditions are a way to control the behaviour of rules written
in somebody else's source text: for example, in the Standard Rules, or in an
extension. They were introduced to the language in January 2011 to replace
the functionality previously provided by procedural rules. For example,

>> The can't reach inside rooms rule does nothing if the player wears the black hat.

We can either cancel the rule ("does nothing") or substitute another rule
for it, and this can be either conditional or unconditional. There can be any
number of conditions attached to a given rule, so these are stored in a list.

=
typedef struct applicability_condition {
	struct wording text_of_condition;
	int sense_of_applicability; /* |TRUE| if condition must hold for rule to have effect */
	struct rule *substituted_rule; /* rule to use instead if not, or |NULL| to do nothing */
	struct parse_node *where_imposed;
	struct applicability_condition *next_applicability_condition;
	CLASS_DEFINITION
} applicability_condition;


@h Applicability constraints.

=
void Rules::impose_constraint(rule *S, rule *R, wording W, int sense) {
	applicability_condition *nac = CREATE(applicability_condition);
	@<Initialise the applicability condition@>;
	@<Add it to the list applying to R@>;
}

@<Initialise the applicability condition@> =
	nac->text_of_condition = W;
	nac->sense_of_applicability = sense;
	nac->next_applicability_condition = NULL;
	nac->where_imposed = current_sentence;
	nac->substituted_rule = S;

@<Add it to the list applying to R@> =
	ADD_TO_LINKED_LIST(nac, applicability_condition, R->applicability_conditions);

@h Logging.

=
void Rules::log(rule *R) {
	if (R == NULL) { LOG("<null-rule>"); return; }
	if (R->defn_as_phrase) LOG("[$R]", R->defn_as_phrase);
	else if (R->compilation_data.rule_extern_iname) LOG("[%n]", R->compilation_data.rule_extern_iname);
	else LOG("[-]");
}

@h Specificity of rules.
The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int Rules::compare_specificity(rule *R1, rule *R2, int dflag) {
	phrase *ph1 = R1->defn_as_phrase, *ph2 = R2->defn_as_phrase;
	ph_runtime_context_data *phrcd1 = NULL, *phrcd2 = NULL;
	if (ph1) phrcd1 = &(ph1->runtime_context_data);
	if (ph2) phrcd2 = &(ph2->runtime_context_data);
	int rv = Phrases::Context::compare_specificity(phrcd1, phrcd2);
	if (dflag) {
		if (rv != 0) LOG("Decided by Law %S that ", c_s_stage_law);
		else LOG("Decided that ");
		switch(rv) {
			case -1: LOG("(2) is more specific than (1)\n"); break;
			case 0: LOG("they are equally specific\n"); break;
			case 1: LOG("(1) is more specific than (2)\n"); break;
		}
	}
	return rv;
}

@ It may seem unlikely, but it's possible for two rules to refer to the
same routine at runtime, if two or more I7 names have been declared which
refer to the same I6 routine. So, we have the following. (It is used only
late on in the run, and never applied to undefined rules.)

=
int Rules::eq(rule *R1, rule *R2) {
	if (R2->defn_as_phrase != R1->defn_as_phrase) return FALSE;
	if ((R1->compilation_data.rule_extern_iname) && (R2->compilation_data.rule_extern_iname)) {
		if (Str::eq(R1->compilation_data.rule_extern_iname_as_text, R2->compilation_data.rule_extern_iname_as_text))
			return TRUE;
	}
	if ((R1->compilation_data.rule_extern_iname == NULL) && (R2->compilation_data.rule_extern_iname == NULL)) return TRUE;
	return FALSE;
}

@h Automatic placement into rulebooks.
Some BRs are given their placements with explicit sentences like:

>> The can't reach inside closed containers rule is listed in the reaching inside rules.

But others have their placements made implicitly in their definitions:

>> Before eating something: ...

(which creates a nameless rule and implicitly places it in the "before"
rulebook). The process of placing those is called "automatic placement".

Automatic placement occurs in declaration order. This is important, because
it ensures that it is declaration order which the rule-sorting code falls back
on when it can see no other justification for placing one rule either side
of another.

=
void Rules::request_automatic_placement(rule *R) {
	if (R->automatic_booking == NULL)
		R->automatic_booking = Rules::Bookings::new(R);
	Rules::Bookings::request_automatic_placement(R->automatic_booking);
}

@h Check safety of placement constraints.
This is more interesting than it might seem. We allow a rule based on nothing
to substitute for a rule based on some value (or an action) because of course
it's perfectly typesafe to ignore the basis value entirely.

=
void Rules::check_placement_safety(void) {
	rule *R;
	LOOP_OVER(R, rule) {
		kind *KR = R->kind_of_rule;
		applicability_condition *ac;
		LOOP_OVER_LINKED_LIST(ac, applicability_condition, R->applicability_conditions) {
			if (ac->substituted_rule) {
				kind *KS = ac->substituted_rule->kind_of_rule;
				kind *B1 = NULL, *B2 = NULL, *P1 = NULL, *P2 = NULL;
				Kinds::binary_construction_material(KR, &B1, &P1);
				Kinds::binary_construction_material(KS, &B2, &P2);
				if (Kinds::eq(B1, NULL)) B1 = K_void;
				if (Kinds::eq(B2, NULL)) B2 = K_void;
				if (Kinds::eq(P1, NULL)) P1 = K_void;
				if (Kinds::eq(P2, NULL)) P2 = K_void;
				if (Kinds::eq(B2, K_void)) B2 = B1;
				kind *K1 = Kinds::binary_con(CON_rule, B1, P1);
				kind *K2 = Kinds::binary_con(CON_rule, B2, P2);
				if (Kinds::compatible(K2, K1) != ALWAYS_MATCH) {
					Problems::quote_source(1, ac->where_imposed);
					Problems::quote_wording(2, ac->substituted_rule->name);
					Problems::quote_wording(3, R->name);
					Problems::quote_kind(4, KR);
					Problems::quote_kind(5, KS);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RulesCantInterchange));
					Problems::issue_problem_segment(
						"In the sentence %1 you've asked to use the rule '%2' in "
						"place of '%3', but one is based on %4 whereas the other "
						"is %5, and those aren't interchangeable.");
					Problems::issue_problem_end();
					break;
				}
			}
		}
	}
}

@h Actor testing.
With some rules (those which have I7 definitions and which are action based),
it's possible to change the way that applicability testing is done. Since this
can only affect rules we compile ourselves, we ignore all of these calls for
rules with I6 definitions, i.e., where |defn_as_phrase| is |NULL|.

=
void Rules::set_always_test_actor(rule *R) {
	if (R->defn_as_phrase) {
		ph_runtime_context_data *phrcd = &(R->defn_as_phrase->runtime_context_data);
		Phrases::Context::set_always_test_actor(phrcd);
	}
}

void Rules::set_never_test_actor(rule *R) {
	if (R->defn_as_phrase) {
		ph_runtime_context_data *phrcd = &(R->defn_as_phrase->runtime_context_data);
		Phrases::Context::set_never_test_actor(phrcd);
	}
}

void Rules::set_marked_for_anyone(rule *R, int to) {
	if (R->defn_as_phrase) {
		ph_runtime_context_data *phrcd = &(R->defn_as_phrase->runtime_context_data);
		Phrases::Context::set_marked_for_anyone(phrcd, to);
	}
}

void Rules::suppress_action_testing(rule *R) {
	if (R->defn_as_phrase) {
		ph_runtime_context_data *phrcd = &(R->defn_as_phrase->runtime_context_data);
		Phrases::Context::suppress_action_testing(phrcd);
	}
}

void Rules::copy_actor_test_flags(rule *R_to, rule *R_from) {
	if ((R_from == NULL) || (R_to == NULL)) internal_error("improper catf");

	ph_runtime_context_data *phrcd_from = NULL;
	if (R_from->defn_as_phrase) phrcd_from = &(R_from->defn_as_phrase->runtime_context_data);
	ph_runtime_context_data *phrcd_to = NULL;
	if (R_to->defn_as_phrase) phrcd_to = &(R_to->defn_as_phrase->runtime_context_data);

	if (phrcd_to) {
		if ((phrcd_from == NULL) ||
			((Phrases::Context::get_marked_for_anyone(phrcd_from)) &&
				(Phrases::Context::get_marked_for_anyone(phrcd_to) == FALSE))) {
			Phrases::Context::clear_always_test_actor(phrcd_to);
			Phrases::Context::set_never_test_actor(phrcd_to);
		}
	}
}

int Rules::rule_is_named(rule *R) {
	if (R == NULL) return FALSE;
	return R->explicitly_named;
}




typedef struct rule_response {
	struct response_message *message;
	struct parse_node *used;
	struct wording content;
} rule_response;

rule_response Rules::new_rule_response(void) {
	rule_response rr;
	rr.message = NULL;
	rr.used = NULL;
	rr.content = EMPTY_WORDING;
	return rr;
}

response_message *Rules::rule_defines_response(rule *R, int code) {
	if (R == NULL) return NULL;
	if (code < 0) return NULL;
	return R->responses[code].message;
}

void Rules::check_response_usages(void) {
	rule *R;
	LOOP_OVER(R, rule) {
		for (int l=0; l<26; l++) {
			if ((R->responses[l].used) &&
				(R->responses[l].message == NULL)) {
				TEMPORARY_TEXT(offers)
				int c = 0;
				for (int l=0; l<26; l++)
					if (R->responses[l].message) {
						c++;
						if (c > 1) WRITE_TO(offers, ", ");
						WRITE_TO(offers, "%c", 'A'+l);
					}
				TEMPORARY_TEXT(letter)
				PUT_TO(letter, 'A'+l);
				Problems::quote_source(1, R->responses[l].used);
				Problems::quote_wording(2, R->name);
				Problems::quote_stream(3, letter);
				if (c == 0) Problems::quote_text(4, "no lettered responses at all");
				else Problems::quote_stream(4, offers);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoSuchResponse));
				Problems::issue_problem_segment(
					"You wrote %1, but the '%2' doesn't have a response "
					"lettered '%3'. (It has %4.)");
				Problems::issue_problem_end();
				DISCARD_TEXT(letter)
				DISCARD_TEXT(offers)
			}
		}
	}
}

void Rules::now_rule_defines_response(rule *R, int code, response_message *resp) {
	if (R == NULL) internal_error("null rule defines response");
	R->responses[code].message = resp;
}

void Rules::now_rule_needs_response(rule *R, int code, wording W) {
	if (R == NULL) internal_error("null rule uses response");
	R->responses[code].used = current_sentence;
	if (Wordings::nonempty(W)) R->responses[code].content = W;
}

wording Rules::get_response_value(rule *R, int code) {
	if (R == NULL) internal_error("null rule uses response");
	return R->responses[code].content;
}

parse_node *Rules::get_response_sentence(rule *R, int code) {
	if (R == NULL) internal_error("null rule uses response");
	return R->responses[code].used;
}

@ Booked rules can be declared wrapping I6 routines which we assume
are defined either in the I6 template or in an I6 inclusion.

The following is called early in the run on sentences like "The can't act
in the dark rule translates into I6 as |"CANT_ACT_IN_THE_DARK_R"|." The
node |p->down->next| is the I7 name, and |p->down->next->next| is the I6
name, whose double-quotes have already been removed.

=
void Rules::declare_I6_written_rule(wording W, parse_node *p2) {
	wchar_t *I6_name = Lexer::word_text(Wordings::first_wn(Node::get_text(p2)));
	rule *R = Rules::obtain(W, TRUE);
	RTRules::set_Inter_identifier(R, I6_name);
}

@ In order to parse sentences about how rules are placed in rulebooks, we
need to be able to parse the relevant names. (The definite article can
optionally be used.)

=
<rulebook-name> internal {
	W = Articles::remove_the(W);
	parse_node *p = Lexicon::retrieve(RULEBOOK_MC, W);
	if (Rvalues::is_CONSTANT_construction(p, CON_rulebook)) {
		==> { -, Rvalues::to_rulebook(p) };
		return TRUE;
	}
	==> { fail nonterminal };
}

<rule-name> internal {
	W = Articles::remove_the(W);
	rule *R = Rules::by_name(W);
	if (R) {
		==> { -, R };
		return TRUE;
	}
	==> { fail nonterminal };
}
