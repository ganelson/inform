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
|defn_as_I7_source| field of a //rule//. But other rules are written quite
differently:
= (text as Inform 7)
The can't reach inside rooms rule translates into Inter as |"CANT_REACH_INSIDE_ROOMS_R"|.
=
and this one is defined by a low-level Inter function, and not a phrase at all.
In any case, rules and phrases have quite different header syntax, and have
different dynamics altogether. In short, then: rules are not phrases.

=
typedef struct rule {
	struct wording name; /* name of the rule being booked */

	struct kind *kind_of_rule; /* determined from its rulebook(s) */
	struct rulebook *kind_of_rule_set_from;

	struct imperative_defn *defn_as_I7_source; /* if defined by an I7 phrase */
	struct stacked_variable_owner_list *variables_visible_in_definition; /* if so */
	struct text_stream *defn_as_Inter_function; /* if not */

	struct booking *automatic_booking; /* how this is placed in rulebooks */

	struct linked_list *applicability_constraints; /* of //applicability_constraint// */

	int allows_responses; /* was this rule explicitly named when created? */
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
rule *Rules::obtain(wording W, int allow_responses) {
	if (Wordings::nonempty(W)) {
		W = Articles::remove_the(W);
		rule *R = Rules::by_name(W);
		if (R) return R;
	}
	rule *R = CREATE(rule);
	R->name = EMPTY_WORDING;

	R->kind_of_rule = NULL;
	R->kind_of_rule_set_from = NULL;

	R->defn_as_I7_source = NULL;
	R->variables_visible_in_definition = NULL;
	R->defn_as_Inter_function = NULL;

	R->automatic_booking = NULL;
	R->applicability_constraints = NEW_LINKED_LIST(applicability_constraint);

	R->allows_responses = allow_responses;
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

@ Which we wrap in a Preform nonterminal thus:

=
<rule-name> internal {
	W = Articles::remove_the(W);
	rule *R = Rules::by_name(W);
	if (R) {
		==> { -, R };
		return TRUE;
	}
	==> { fail nonterminal };
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
void Rules::set_imperative_definition(rule *R, imperative_defn *id) {
	R->defn_as_I7_source = id;
}

imperative_defn *Rules::get_imperative_definition(rule *R) {
	if (R == NULL) return NULL;
	return R->defn_as_I7_source;
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
	if (Rules::all_action_processing_variables())
		Rules::put_variables_in_scope(R, Rules::all_action_processing_variables());
	#endif
}

struct stacked_variable_owner_list *all_action_processing_vars = NULL;

stacked_variable_owner_list *Rules::all_action_processing_variables(void) {
	if (all_action_processing_vars == NULL) {
		rulebook *B = Rulebooks::std(ACTION_PROCESSING_RB);
		if (B) all_action_processing_vars =
			StackedVariables::add_owner_to_list(NULL, B->my_variables);
	}
	return all_action_processing_vars;
}

@h Defining rules with Inter functions.
When a rule is really just a wrapper for an Inter-level function, as here:
>> The can't reach inside rooms rule translates into Inter as |"CANT_REACH_INSIDE_ROOMS_R"|.
...it has no |defn_as_I7_source| and instead has the name of the Inter function
stored in |defn_as_Inter_function|.

Here |W| is the rule's name, say "can't reach inside rooms rule", and |FW|
is wording which should contain just the double-quoted function name.

=
void Rules::declare_I6_written_rule(wording W, wording FW) {
	rule *R = Rules::obtain(W, TRUE);
	R->defn_as_Inter_function = Str::new();
	WRITE_TO(R->defn_as_Inter_function, "%W", FW);
	RTRules::define_by_Inter_function(R);
}

@h Logging.

=
void Rules::log(rule *R) {
	if (R == NULL) { LOG("<null-rule>"); return; }
	if (Wordings::nonempty(R->name)) LOG("['%W':", R->name); else LOG("[");
	if (R->defn_as_I7_source)
		LOG("$R]", R->defn_as_I7_source->defines);
	else if (Str::len(R->defn_as_Inter_function) > 0)
		LOG("%S]", R->defn_as_Inter_function);
	else
		LOG("%d]", R->allocation_id);
}

@h Equality and priority.
Two different //rule// pointers can in fact refer to what will be the same rule
at run-time if this should happen:
= (text as Inform 7)
The alpha rule translates into Inter as |"SAME_R"|.
The beta rule translates into Inter as |"SAME_R"|.
=
And so we have the following:

=
int Rules::eq(rule *R1, rule *R2) {
	if ((Rules::defined(R1)) || (Rules::defined(R2))) {
		if (R2->defn_as_I7_source != R1->defn_as_I7_source) return FALSE;
		if (Str::ne(R1->defn_as_Inter_function, R2->defn_as_Inter_function)) return FALSE;
		return TRUE;
	} else {
		if (R1 != R2) return FALSE;
		return TRUE;
	}
}

int Rules::defined(rule *R) {
	if ((R->defn_as_I7_source) || (Str::len(R->defn_as_Inter_function) > 0)) return TRUE;
	return FALSE;
}

@ This |strcmp|-like function is intended to be used in sorting algorithms,
and returns 1 if |R1| is more specific than |R2|, -1 if |R2| is more specific
than |R1|, or 0 if they are equally good.

=
int Rules::cmp(rule *R1, rule *R2, int log_this) {
	imperative_defn *id1 = R1->defn_as_I7_source, *id2 = R2->defn_as_I7_source;
	ph_runtime_context_data *phrcd1 = NULL, *phrcd2 = NULL;
	if (id1) phrcd1 = &(id1->defines->runtime_context_data);
	if (id2) phrcd2 = &(id2->defines->runtime_context_data);
	int rv = Phrases::Context::compare_specificity(phrcd1, phrcd2);
	if (log_this) {
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

@h Applicability constraints.
Applicability constraints are a way to control the behaviour of rules written
in somebody else's source text: for example, in the Standard Rules, or in an
extension. They were introduced to the language in January 2011 to replace
the functionality previously provided by procedural rules. For example,

>> The can't reach inside rooms rule does nothing if the player wears the black hat.

We can either cancel the rule ("does nothing") or substitute another rule
for it, and this can be either conditional or unconditional. There can be any
number of constraints attached to a given rule, so these are stored in a list.

=
typedef struct applicability_constraint {
	struct wording text_of_condition;
	int sense_of_applicability; /* |TRUE| if condition must hold for rule to have effect */
	struct rule *substituted_rule; /* rule to use instead if not, or |NULL| to do nothing */
	struct parse_node *where_imposed;
	CLASS_DEFINITION
} applicability_constraint;

void Rules::impose_constraint(rule *S, rule *R, wording W, int sense) {
	applicability_constraint *ac = CREATE(applicability_constraint);
	ac->text_of_condition = W;
	ac->sense_of_applicability = sense;
	ac->where_imposed = current_sentence;
	ac->substituted_rule = S;
	ADD_TO_LINKED_LIST(ac, applicability_constraint, R->applicability_constraints);
}

@ If under some circumstances one rule is substituted for another, there's
the potential for something type-unsafe to happen, and the following checks
that it doesn't.

Note that we allow a rule based on nothing to substitute for a rule based on
some value (or on an action) because of course it's perfectly typesafe to ignore
the basis value entirely.

=
void Rules::check_constraints_are_typesafe(rule *R) {
	kind *KR = R->kind_of_rule;
	applicability_constraint *ac;
	LOOP_OVER_LINKED_LIST(ac, applicability_constraint, R->applicability_constraints) {
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
				StandardProblems::handmade_problem(Task::syntax_tree(),
					_p_(PM_RulesCantInterchange));
				Problems::issue_problem_segment(
					"In the sentence %1 you've asked to use the rule '%2' in place of '%3', "
					"but one is based on %4 whereas the other is %5, and those aren't "
					"interchangeable.");
				Problems::issue_problem_end();
				break;
			}
		}
	}
}

@h Automatic placement into rulebooks.
Some rules are given their placements with explicit sentences like:

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
		R->automatic_booking = RuleBookings::new(R);
	RuleBookings::request_automatic_placement(R->automatic_booking);
}

@h Actor testing.
With some rules (those which have I7 definitions and which are action based),
it's possible to change the way that applicability testing is done.

=
void Rules::set_always_test_actor(rule *R) {
	if (R->defn_as_I7_source) {
		ph_runtime_context_data *phrcd = &(R->defn_as_I7_source->defines->runtime_context_data);
		Phrases::Context::set_always_test_actor(phrcd);
	}
}

void Rules::set_never_test_actor(rule *R) {
	if (R->defn_as_I7_source) {
		ph_runtime_context_data *phrcd = &(R->defn_as_I7_source->defines->runtime_context_data);
		Phrases::Context::set_never_test_actor(phrcd);
	}
}

void Rules::set_marked_for_anyone(rule *R, int to) {
	if (R->defn_as_I7_source) {
		ph_runtime_context_data *phrcd = &(R->defn_as_I7_source->defines->runtime_context_data);
		Phrases::Context::set_marked_for_anyone(phrcd, to);
	}
}

void Rules::suppress_action_testing(rule *R) {
	if (R->defn_as_I7_source) {
		ph_runtime_context_data *phrcd = &(R->defn_as_I7_source->defines->runtime_context_data);
		Phrases::Context::suppress_action_testing(phrcd);
	}
}

void Rules::copy_actor_test_flags(rule *R_to, rule *R_from) {
	if ((R_from == NULL) || (R_to == NULL)) internal_error("improper catf");

	ph_runtime_context_data *phrcd_from = NULL;
	if (R_from->defn_as_I7_source)
		phrcd_from = &(R_from->defn_as_I7_source->defines->runtime_context_data);
	ph_runtime_context_data *phrcd_to = NULL;
	if (R_to->defn_as_I7_source)
		phrcd_to = &(R_to->defn_as_I7_source->defines->runtime_context_data);

	if (phrcd_to) {
		if ((phrcd_from == NULL) ||
			((Phrases::Context::get_marked_for_anyone(phrcd_from)) &&
				(Phrases::Context::get_marked_for_anyone(phrcd_to) == FALSE))) {
			Phrases::Context::clear_always_test_actor(phrcd_to);
			Phrases::Context::set_never_test_actor(phrcd_to);
		}
	}
}

@h Responses.
Not all rules can have responses: for example, timed event rules cannot.

=
int Rules::rule_allows_responses(rule *R) {
	if (R == NULL) return FALSE;
	return R->allows_responses;
}

@ In Inform source text, the different response texts for a rule are lettered
'A' to at most 'Z': inside the compiler, they are numbered 0 to 25. For each
possibility we store one of these:

=
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

wording Rules::get_response_content(rule *R, int code) {
	if (R == NULL) return EMPTY_WORDING;
	if ((code < 0) || (code >= 26)) return EMPTY_WORDING;
	return R->responses[code].content;
}

parse_node *Rules::get_response_sentence(rule *R, int code) {
	if (R == NULL) return NULL;
	if ((code < 0) || (code >= 26)) return NULL;
	return R->responses[code].used;
}

@ When a response is defined in the body of a rule, the |message| is
created with //Rules::set_response//:

=
void Rules::set_response(rule *R, int code, response_message *resp) {
	if (R == NULL) internal_error("null rule defines response");
	if ((code < 0) || (code >= 26)) internal_error("response out of range");
	R->responses[code].message = resp;
}

response_message *Rules::get_response(rule *R, int code) {
	if (R == NULL) return NULL;
	if ((code < 0) || (code >= 26)) return NULL;
	return R->responses[code].message;
}

@ When a response is referred to elsewhere, for example in source text which
tries to change its wording to the new text |W|, the following is called:

=
void Rules::now_rule_needs_response(rule *R, int code, wording W) {
	if (R == NULL) internal_error("null rule uses response");
	if ((code < 0) || (code >= 26)) internal_error("response out of range");
	R->responses[code].used = current_sentence;
	if (Wordings::nonempty(W)) R->responses[code].content = W;
}

@ That function did not check that the rule actually had the response it
was trying to change -- it didn't check this because, for timing reasons, it
couldn't yet do so. Instead, we check retrospectively, at a time when all
response messages have been discovered:

=
void Rules::check_response_usages(void) {
	rule *R;
	LOOP_OVER(R, rule)
		for (int l=0; l<26; l++)
			if ((R->responses[l].used) && (R->responses[l].message == NULL))
				@<Throw a used but never defined problem@>;
}

@<Throw a used but never defined problem@> =
	TEMPORARY_TEXT(offers)
	int c = 0;
	for (int l=0; l<26; l++)
		if (R->responses[l].message) {
			if (c++ > 0) WRITE_TO(offers, ", ");
			WRITE_TO(offers, "%c", 'A'+l);
		}
	if (c == 0) WRITE_TO(offers, "no lettered responses at all");
	TEMPORARY_TEXT(letter)
	PUT_TO(letter, 'A'+l);
	Problems::quote_source(1, R->responses[l].used);
	Problems::quote_wording(2, R->name);
	Problems::quote_stream(3, letter);
	Problems::quote_stream(4, offers);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoSuchResponse));
	Problems::issue_problem_segment(
		"You wrote %1, but the '%2' doesn't have a response lettered '%3'. (It has %4.)");
	Problems::issue_problem_end();
	DISCARD_TEXT(letter)
	DISCARD_TEXT(offers)
