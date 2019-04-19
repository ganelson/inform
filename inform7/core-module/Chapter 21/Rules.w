[Rules::] Rules.

Rule structures abstract the Inform 7 concept of a rule, which may
be defined either by an Inform 6 routine or by higher-level source text
from a phrase structure.

@h Definitions.

@ Rules are not the same thing as phrases. While most do have phrase-like
definitions,

>> Before eating: say "The candlelight flickers ominously."

they do not provide new syntax for the writing of other phrases; they are
often nameless, as in this example; and they are sometimes defined not by
an I7 |phrase| structure but by an I6 routine:

>> The can't reach inside rooms rule translates into I6 as |"CANT_REACH_INSIDE_ROOMS_R"|.

Note that:

(a) There is only one rule with any given name, except that there can be any
number of rules which are nameless. Rule names do not need to end in
"...rule", and though most do, rules for timed events do not.

(b) Any given rule must have a "definition" which is either an I7 |phrase|
arising from source text, or an I6 routine named in quotation marks. If the
latter, then Inform simply assumes this routine has been provided, either
by the I6 template or by an insertion.

(c) Conditions for the rule to apply -- for instance, that the action has to
be "eating" -- are stored in the |phrase| structure, not here. It follows
that an I6 routine-defined rule is used unconditionally: the expectation is
that the routine will decline to act if the situation isn't to its liking.

(d) However, the same is not true of "applicability conditions", for which
see below.

=
typedef struct rule {
	struct wording name; /* name of the rule being booked */
	int explicitly_named; /* was this rule explicitly named when created? */
	struct wording italicised_text; /* when indexing a rulebook */
	struct stacked_variable_owner_list *listed_stv_owners; /* making vars visible here */
	struct phrase *defn_as_phrase; /* the rule being booked */
	struct package_request *rule_package;
	struct inter_name *shell_routine_iname;
	struct inter_name *rule_extern_iname; /* if externally defined, this is the I6 routine */
	struct text_stream *rule_extern_iname_as_text; /* and this is it in plain text */
	struct inter_name *xiname;
	struct inter_name *rule_extern_response_handler_iname; /* and this produces any response texts it has */
	int do_not_import; /* veto importation of this from the Standard Rules precompiled inter code */
	int defn_compiled; /* has the definition of this rule, if needed, been compiled yet? */
	struct booking *automatic_booking; /* how this is placed in rulebooks */
	struct applicability_condition *first_applicability_condition; /* see below */
	struct response_message *lettered_responses[26]; /* responses (A), (B), ... */
	struct parse_node *lettered_responses_used[26]; /* responses (A), (B), ... */
	struct kind *kind_of_rule; /* determined from its rulebook(s) */
	struct rulebook *kind_of_rule_set_from;
	struct wording lettered_responses_value[26];
	MEMORY_MANAGEMENT
} rule;

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
	MEMORY_MANAGEMENT
} applicability_condition;

@h The rule structure.
Rules are created before their definitions are known. This is done so that
rules like

>> Before eating (this is the must say grace rule): ...

cause "must say grace rule" to be registered as a constant value early in
Inform's run (allowing it to be a property value, or a table entry, for
example). Note that the rule may just as well be nameless, as here:

>> Before drinking: ...

in which case |w1 == -1|. In either case, the definition should be supplied
later: see below.

=
rule *Rules::new(wording W, int named) {
	W = Articles::remove_the(W);
	rule *R = Rules::by_name(W);
	if (R) return R;
	R = CREATE(rule);
	R->kind_of_rule = NULL;
	R->defn_as_phrase = NULL;
	R->rule_extern_iname = NULL;
	R->rule_extern_iname_as_text = NULL;
	R->xiname = NULL;
	R->rule_extern_response_handler_iname = NULL;
	R->name = W;
	R->italicised_text = EMPTY_WORDING;
	R->listed_stv_owners = NULL;
	R->automatic_booking = NULL;
	R->first_applicability_condition = NULL;
	R->defn_compiled = FALSE;
	R->do_not_import = FALSE;
	R->explicitly_named = named;
	R->shell_routine_iname = NULL;
	R->rule_package = Hierarchy::local_package(RULES_HAP);
	for (int l=0; l<26; l++) {
		R->lettered_responses[l] = NULL;
		R->lettered_responses_used[l] = NULL;
		R->lettered_responses_value[l] = EMPTY_WORDING;
	}
	if (Wordings::nonempty(W)) {
		if (Rules::vet_name(W)) @<Register the name of this rule@>;
	}
	return R;
}

@ We make a modest speed gain by registering rule names which end in "rule"
slightly differently. (Not all rule names do: those for timed events do not.)

@<Register the name of this rule@> =
	unsigned int mc = RULE_MC;
	if (<rule-name-formal>(W)) mc = MISCELLANEOUS_MC;
	Nouns::new_proper_noun(W, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		mc, Rvalues::from_rule(R));

@ Reversing the process:

=
rule *Rules::by_name(wording W) {
	if (Wordings::empty(W)) return NULL;
	W = Articles::remove_the(W);
	if (<rule-name-formal>(W)) {
		parse_node *p = ExParser::parse_excerpt(MISCELLANEOUS_MC, W);
		if (Rvalues::is_CONSTANT_construction(p, CON_rule))
			return Rvalues::to_rule(p);
	} else {
		parse_node *p = ExParser::parse_excerpt(RULE_MC, W);
		if (Rvalues::is_CONSTANT_construction(p, CON_rule))
			return Rvalues::to_rule(p);
	}
	return NULL;
}

@ =
int PM_RuleWithComma_issued_at = -1;
int Rules::vet_name(wording W) {
	if (<unsuitable-name>(W)) {
		if (PM_RuleWithComma_issued_at != Wordings::first_wn(W)) {
			PM_RuleWithComma_issued_at = Wordings::first_wn(W);
			Problems::Issue::sentence_problem(_p_(PM_RuleWithComma),
				"a rule name is not allowed to contain punctuation, or "
				"to consist only of an article like 'a' or 'an', or to "
				"contain double-quoted text",
				"because this leads to too much ambiguity later on.");
		}
		return FALSE;
	}
	return TRUE;
}

@h The kind of a rule.
Note the convention, a historical accident, really, that a rule with no known
kind is considered to be action-based and resulting in nothing.

=
kind *Rules::to_kind(rule *R) {
	kind *K = R->kind_of_rule;
	if (K == NULL) K = Kinds::binary_construction(CON_rule, K_action_name, K_nil);
	return K;
}

@h Definitions.
The definition of a rule can be either an I7 phrase, or an I6 routine, and
must be added after the rule has been created:

=
void Rules::set_I7_definition(rule *R, phrase *ph) {
	R->defn_as_phrase = ph;
}

void Rules::set_I6_definition(rule *R, wchar_t *identifier) {
	TEMPORARY_TEXT(XT);
	WRITE_TO(XT, "%w", identifier);
	R->rule_extern_iname = Hierarchy::make_iname_in(EXTERIOR_RULE_HL, R->rule_package);

	inter_name *xiname = Hierarchy::find_by_name(XT);
	Emit::named_generic_constant_xiname(R->rule_package, R->rule_extern_iname, xiname);

	R->xiname = xiname;
	R->rule_extern_iname_as_text = Str::duplicate(XT);
	DISCARD_TEXT(XT);
}

inter_name *Rules::get_handler_definition(rule *R) {
	if (R->rule_extern_response_handler_iname == NULL)
		R->rule_extern_response_handler_iname =
			Hierarchy::derive_iname_in(RESPONDER_FN_HL, R->xiname, R->rule_package);
	return R->rule_extern_response_handler_iname;
}

phrase *Rules::get_I7_definition(rule *R) {
	if (R == NULL) return NULL;
	return R->defn_as_phrase;
}

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
	applicability_condition *ac = R->first_applicability_condition;
	if (ac == NULL) R->first_applicability_condition = nac;
	else {
		while ((ac) && (ac->next_applicability_condition))
			ac = ac->next_applicability_condition;
		ac->next_applicability_condition = nac;
	}

@ The following generates code to terminate a rule early if its applicability
conditions have not been met.

=
int Rules::compile_constraint(applicability_condition *acl) {
	for (; acl; acl = acl->next_applicability_condition) {
		current_sentence = acl->where_imposed;
		if (Wordings::nonempty(acl->text_of_condition)) {
			Emit::inv_primitive(if_interp);
			Emit::down();
			if (acl->sense_of_applicability) {
				Emit::inv_primitive(not_interp);
				Emit::down();
			}
			@<Compile the constraint condition@>;
			if (acl->sense_of_applicability) {
				Emit::up();
			}
			Emit::code();
			Emit::down();
		}
		@<Compile the rule termination code used if the constraint was violated@>;
		if (Wordings::nonempty(acl->text_of_condition)) {
			Emit::up();
			Emit::up();
		} else {
			return TRUE;
		}
	}
	return FALSE;
}

@<Compile the constraint condition@> =
	if (Wordings::nonempty(acl->text_of_condition) == FALSE) {
		Emit::val(K_truth_state, LITERAL_IVAL, 1);
	} else {
		if (<s-condition>(acl->text_of_condition)) {
			parse_node *spec = <<rp>>;
			Dash::check_condition(spec);
			Specifications::Compiler::emit_as_val(K_truth_state, spec);
		} else {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, acl->text_of_condition);
			Problems::Issue::handmade_problem(_p_(PM_BadRuleConstraint));
			Problems::issue_problem_segment(
				"In %1, you placed a constraint '%2' on a rule, but this isn't "
				"a condition I can understand.");
			Problems::issue_problem_end();
			Emit::val(K_number, LITERAL_IVAL, 1);
		}
	}

@ Note that in the does nothing case, the rule ends without result, rather than
failing; so it doesn't terminate the following of its rulebook.

@<Compile the rule termination code used if the constraint was violated@> =
	Emit::inv_primitive(return_interp);
	Emit::down();
	if (acl->substituted_rule) {
		inter_name *subbed = Rules::iname(acl->substituted_rule);
		if (Inter::Constant::is_routine(InterNames::to_symbol(subbed)) == FALSE) {
			Emit::val(K_number, LITERAL_IVAL, 0);
		} else {
			Emit::inv_call_iname(subbed);
		}
	} else {
		Emit::val(K_number, LITERAL_IVAL, 0);
	}
	Emit::up();

@h Logging.

=
void Rules::log(rule *R) {
	if (R == NULL) { LOG("<null-rule>"); return; }
	if (R->defn_as_phrase) LOG("[$R]", R->defn_as_phrase);
	else if (R->rule_extern_iname) LOG("[%n]", R->rule_extern_iname);
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
		if (rv != 0) LOG("Decided by Law %s that ", c_s_stage_law);
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
	if ((R1->rule_extern_iname) && (R2->rule_extern_iname)) {
		if (Str::eq(R1->rule_extern_iname_as_text, R2->rule_extern_iname_as_text))
			return TRUE;
	}
	if ((R1->rule_extern_iname == NULL) && (R2->rule_extern_iname == NULL)) return TRUE;
	return FALSE;
}

@h As constant values.
An interesting point is raised here. What is the kind of a rule? Clearly
it should be a "rule", but that isn't precise. Older versions of Inform
blurred this by using the indefinite "value based rule producing a value",
but this led to a number of anomalies, such as that

>> let R be the foo rule;

would fail to work because the kind of "foo rule" could not be inferred
to a definite kind. What now happens is that whenever a rule is added to
a rulebook, the following is called to notify us that it provides information
about the kind of the rule; and this enables us to check for incompatibilities.

=
void Rules::set_kind_from(rule *R, rulebook *RB) {
	kind *K = Rulebooks::contains_kind(RB);
	if (R->kind_of_rule) {
		if (Kinds::Compare::compatible(R->kind_of_rule, K) != ALWAYS_MATCH) {
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
			Problems::Issue::handmade_problem(_p_(PM_RuleInIncompatibleRulebooks));
			Problems::issue_problem_segment(
				"You've asked to put the rule '%2' into the rulebook %8, "
				"which is based on %5 and produces %6; but it was originally "
				"written to go into a rulebook of a different kind, %7, "
				"which is based on %3 and produces %4. Because those kinds "
				"are different, '%2' can't go into %8.");
			Problems::issue_problem_end();
		}
	}
	R->kind_of_rule = K;
	R->kind_of_rule_set_from = RB;
}

@h Variables accessible from here.

=
void Rules::acquire_stvol(rule *R, stacked_variable_owner_list *stvol) {
	R->listed_stv_owners =
		StackedVariables::append_owner_list(R->listed_stv_owners, stvol);
}

void Rules::acquire_action_variables(rule *R) {
	#ifdef IF_MODULE
	Rules::acquire_stvol(R, all_nonempty_stacked_action_vars);
	if (all_action_processing_vars == NULL) internal_error("APROC not ready");
	Rules::acquire_stvol(R, all_action_processing_vars);
	#endif
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
		for (ac = R->first_applicability_condition; ac; ac = ac->next_applicability_condition) {
			if (ac->substituted_rule) {
				kind *KS = ac->substituted_rule->kind_of_rule;
				kind *B1 = NULL, *B2 = NULL, *P1 = NULL, *P2 = NULL;
				Kinds::binary_construction_material(KR, &B1, &P1);
				Kinds::binary_construction_material(KS, &B2, &P2);
				if (Kinds::Compare::eq(B1, NULL)) B1 = K_nil;
				if (Kinds::Compare::eq(B2, NULL)) B2 = K_nil;
				if (Kinds::Compare::eq(P1, NULL)) P1 = K_nil;
				if (Kinds::Compare::eq(P2, NULL)) P2 = K_nil;
				if (Kinds::Compare::eq(B2, K_nil)) B2 = B1;
				kind *K1 = Kinds::binary_construction(CON_rule, B1, P1);
				kind *K2 = Kinds::binary_construction(CON_rule, B2, P2);
				if (Kinds::Compare::compatible(K2, K1) != ALWAYS_MATCH) {
					Problems::quote_source(1, ac->where_imposed);
					Problems::quote_wording(2, ac->substituted_rule->name);
					Problems::quote_wording(3, R->name);
					Problems::quote_kind(4, KR);
					Problems::quote_kind(5, KS);
					Problems::Issue::handmade_problem(_p_(PM_RulesCantInterchange));
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

@h Run-time representation.
In I6 code, a rule is compiled to the name of the routine implementing it,
an I6 value of metaclass |Routine|. See compilation below for what rule shells
do.

=
inter_name *Rules::shell_iname(rule *R) {
	if (R->shell_routine_iname == NULL)
		R->shell_routine_iname = Hierarchy::make_iname_in(SHELL_FN_HL, R->rule_package);
	return R->shell_routine_iname;
}

inter_name *Rules::iname(rule *R) {
	if (R->defn_as_phrase) return Phrases::iname(R->defn_as_phrase);
	else if (R->rule_extern_iname) {
		if (R->first_applicability_condition) {
			return Rules::shell_iname(R);
		} else {
			return R->rule_extern_iname;
		}
	} else internal_error("tried to symbolise nameless rule");
	return NULL;
}

@h Printing rule names at run time.

=
inter_name *Rules::RulePrintingRule(void) {
	return Hierarchy::find(RULEPRINTINGRULE_HL);
}

void Rules::RulePrintingRule_routine(void) {
	packaging_state save = Routines::begin(Rules::RulePrintingRule());
	inter_symbol *R_s = LocalVariables::add_named_call_as_symbol(I"R");
	Emit::inv_primitive(ifelse_interp);
	Emit::down();
		Emit::inv_primitive(and_interp);
		Emit::down();
			Emit::inv_primitive(ge_interp);
			Emit::down();
				Emit::val_symbol(K_value, R_s);
				Emit::val(K_number, LITERAL_IVAL, 0);
			Emit::up();
			Emit::inv_primitive(lt_interp);
			Emit::down();
				Emit::val_symbol(K_value, R_s);
				Emit::val_iname(K_value, Hierarchy::find(NUMBER_RULEBOOKS_CREATED_HL));
			Emit::up();
		Emit::up();
		Emit::code();
		Emit::down();
			@<Print a rulebook name@>;
		Emit::up();
		Emit::code();
		Emit::down();
			@<Print a rule name@>;
		Emit::up();
	Emit::up();
	Routines::end(save);
}

@<Print a rulebook name@> =
	if (memory_economy_in_force) {
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(I"(rulebook ");
		Emit::up();
		Emit::inv_primitive(printnumber_interp);
		Emit::down();
			Emit::val_symbol(K_value, R_s);
		Emit::up();
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(I")");
		Emit::up();
	} else {
		Emit::inv_primitive(printstring_interp);
		Emit::down();
			Emit::inv_primitive(lookup_interp);
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(RULEBOOKNAMES_HL));
				Emit::val_symbol(K_value, R_s);
			Emit::up();
		Emit::up();
	}

@<Print a rule name@> =
	if (memory_economy_in_force) {
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(I"(rule at address ");
		Emit::up();
		Emit::inv_primitive(printnumber_interp);
		Emit::down();
			Emit::val_symbol(K_value, R_s);
		Emit::up();
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(I")");
		Emit::up();
	} else {
		rule *R;
		LOOP_OVER(R, rule) {
			if ((Wordings::nonempty(R->name) == FALSE) &&
				((R->defn_as_phrase == NULL) ||
					(R->defn_as_phrase->declaration_node == NULL) ||
					(R->defn_as_phrase->declaration_node->down == NULL)))
					continue;
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::val_symbol(K_value, R_s);
					Emit::val_iname(K_value, Rules::iname(R));
				Emit::up();
				Emit::code();
				Emit::down();
					TEMPORARY_TEXT(OUT);
					@<Print a textual name for this rule@>;
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_text(OUT);
					Emit::up();
					Emit::rtrue();
				Emit::up();
			Emit::up();
		}
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(I"(nameless rule at address ");
		Emit::up();
		Emit::inv_primitive(printnumber_interp);
		Emit::down();
			Emit::val_symbol(K_value, R_s);
		Emit::up();
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_text(I")");
		Emit::up();
	}

@<Print a textual name for this rule@> =
	if (Wordings::nonempty(R->name)) {
		CompiledText::from_text(OUT, R->name);
	} else if (R->defn_as_phrase->declaration_node) {
		CompiledText::from_text(OUT,
			Articles::remove_the(
				ParseTree::get_text(R->defn_as_phrase->declaration_node)));
	} else WRITE("%n", Rules::iname(R));

@ =
void Rules::compile_comment(rule *R, int index, int from) {
	TEMPORARY_TEXT(C);
	WRITE_TO(C, "Rule %d/%d", index, from);
	if (R->defn_as_phrase == NULL) {
		WRITE_TO(C, ": %n", R->rule_extern_iname);
	}
	Emit::comment(C);
	DISCARD_TEXT(C);
	if (R->defn_as_phrase) {
		Phrases::Usage::write_I6_comment_describing(&(R->defn_as_phrase->usage_data));
	}
}

@h Compilation.
Only those rules defined as I7 phrases need us to compile anything -- and then
what we compile, of course, is the phrase in question.

=
void Rules::compile_definition(rule *R, int *i, int max_i) {
	if (R->defn_compiled == FALSE) {
		R->defn_compiled = TRUE;
		rule_being_compiled = R;
		if (R->defn_as_phrase) {
			if ((import_mode) && (R->do_not_import == FALSE) && (Rules::portable(R))) {
				Emit::import(Rules::iname(R), R->name);
				Phrases::import(R->defn_as_phrase);
			}
			Phrases::compile(R->defn_as_phrase, i, max_i,
				R->listed_stv_owners, NULL, R->first_applicability_condition);
		}
		if ((R->rule_extern_iname) && (R->first_applicability_condition))
			@<Compile a shell routine to apply conditions to an I6 rule@>;
		rule_being_compiled = NULL;
	}
}

void Rules::unimport(rule *R) {
	if (R->defn_compiled == FALSE) { R->do_not_import = TRUE; return; }
	inter_symbol *symb = InterNames::to_symbol(Rules::iname(R));
	if (Inter::Frame::valid(&(symb->importation_frame))) {
		LOG("Unimport rule %n!\n", Rules::iname(R));
		Inter::Nop::nop_out(Emit__repository(), symb->importation_frame);
		R->defn_compiled = FALSE;
		R->do_not_import = TRUE;
		R->defn_as_phrase->imported = FALSE;
	}
}

@ This is the trickiest case: where the user has asked for something like

>> The carrying requirements rule does nothing when eating the lollipop.

and the carrying requirements rule is defined by an I6 routine, which we
are unable to modify. What we do is to create a shell routine to call it,
and put the conditions into this outer shell; we then use the outer shell
as the definition of the rule in future.

@<Compile a shell routine to apply conditions to an I6 rule@> =
	inter_name *shell_iname = Rules::shell_iname(R);
	packaging_state save = Routines::begin(shell_iname);
	if (Rules::compile_constraint(R->first_applicability_condition) == FALSE) {
		Emit::inv_primitive(return_interp);
		Emit::down();
		Emit::inv_call_iname(R->rule_extern_iname);
		Emit::up();
	}
	Routines::end(save);

@h Indexing.
Some rules are provided with index text:

=
void Rules::set_italicised_index_text(rule *R, wording W) {
	R->italicised_text = W;
}

@ A use option controls whether little rule numbers are shown in the index.
I wonder how useful this really is, but it was much requested at one time.

=
int use_numbered_rules = FALSE;

void Rules::set_numbered_rules(void) {
	use_numbered_rules = TRUE;
}

@ And off we go:

=
int Rules::index(OUTPUT_STREAM, rule *R, rulebook *owner, rule_context rc) {
	int no_responses_indexed = 0;
	if (Wordings::nonempty(R->italicised_text)) @<Index the italicised text to do with the rule@>;
	if (Wordings::nonempty(R->name)) @<Index the rule name along with Javascript buttons@>;
	if ((Wordings::nonempty(R->italicised_text) == FALSE) &&
		(Wordings::nonempty(R->name) == FALSE) && (R->defn_as_phrase))
		@<Index some text extracted from the first line of the otherwise anonymous rule@>;
	@<Index a link to the first line of the rule's definition@>;
	if (use_numbered_rules) @<Index the small type rule numbering@>;
	@<Index any applicability conditions@>;
	HTML_CLOSE("p");
	@<Index any response texts in the rule@>;
	return no_responses_indexed;
}

@<Index the italicised text to do with the rule@> =
	WRITE("<i>%+W", R->italicised_text);
	#ifdef IF_MODULE
	if (rc.scene_context) {
		WRITE(" during ");
		wording SW = PL::Scenes::get_name(rc.scene_context);
		WRITE("%+W", SW);
	}
	#endif
	WRITE("</i>&nbsp;&nbsp;");

@

@d MAX_PASTEABLE_RULE_NAME_LENGTH 500

@<Index the rule name along with Javascript buttons@> =
	HTML::begin_colour(OUT, I"800000");
	WRITE("%+W", R->name);
	HTML::end_colour(OUT);
	WRITE("&nbsp;&nbsp;");

	TEMPORARY_TEXT(S);
	WRITE_TO(S, "%+W", R->name);
	HTML::Javascript::paste_stream(OUT, S);
	WRITE("&nbsp;<i>name</i> ");

	Str::clear(S);
	WRITE_TO(S, "The %W is not listed in the %W rulebook.\n", R->name, owner->primary_name);
	HTML::Javascript::paste_stream(OUT, S);
	WRITE("&nbsp;<i>unlist</i>");
	DISCARD_TEXT(S);

	int l, c;
	for (l=0, c=0; l<26; l++)
		if (R->lettered_responses[l]) {
			c++;
		}
	if (c > 0) {
		WRITE("&nbsp;&nbsp;");
		Index::extra_link_with(OUT, 1000000+R->allocation_id, "responses");
		WRITE("%d", c);
	}

@<Index any response texts in the rule@> =
	int l, c;
	for (l=0, c=0; l<26; l++)
		if (R->lettered_responses[l]) {
			if (c == 0) Index::extra_div_open_nested(OUT, 1000000+R->allocation_id, 2);
			else HTML_TAG("br");
			Strings::index_response(OUT, R, l, R->lettered_responses[l]);
			c++;
		}
	if (c > 0) Index::extra_div_close_nested(OUT);
	no_responses_indexed = c;

@<Index some text extracted from the first line of the otherwise anonymous rule@> =
	parse_node *pn = R->defn_as_phrase->declaration_node->down;
	if ((pn) && (Wordings::nonempty(ParseTree::get_text(pn)))) {
		WRITE("(%+W", ParseTree::get_text(pn));
		if (pn->next) WRITE("; ...");
		WRITE(")");
	}

@<Index a link to the first line of the rule's definition@> =
	if (R->defn_as_phrase) {
		parse_node *pn = R->defn_as_phrase->declaration_node;
		if ((pn) && (Wordings::nonempty(ParseTree::get_text(pn))))
			Index::link(OUT, Wordings::first_wn(ParseTree::get_text(pn)));
	}

@<Index the small type rule numbering@> =
	WRITE(" ");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (R->defn_as_phrase) WRITE("%d", R->defn_as_phrase->allocation_id);
	else WRITE("primitive");
	HTML_CLOSE("span");

@<Index any applicability conditions@> =
	applicability_condition *acl;
	for (acl = R->first_applicability_condition; acl; acl = acl->next_applicability_condition) {
		HTML_TAG("br");
		Index::link(OUT, Wordings::first_wn(ParseTree::get_text(acl->where_imposed)));
		WRITE("&nbsp;%+W", ParseTree::get_text(acl->where_imposed));
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

response_message *Rules::rule_defines_response(rule *R, int code) {
	if (R == NULL) return NULL;
	if (code < 0) return NULL;
	return R->lettered_responses[code];
}

void Rules::check_response_usages(void) {
	rule *R;
	LOOP_OVER(R, rule) {
		for (int l=0; l<26; l++) {
			if ((R->lettered_responses_used[l]) &&
				(R->lettered_responses[l] == NULL)) {
				TEMPORARY_TEXT(offers);
				int c = 0;
				for (int l=0; l<26; l++)
					if (R->lettered_responses[l]) {
						c++;
						if (c > 1) WRITE_TO(offers, ", ");
						WRITE_TO(offers, "%c", 'A'+l);
					}
				TEMPORARY_TEXT(letter);
				PUT_TO(letter, 'A'+l);
				Problems::quote_source(1, R->lettered_responses_used[l]);
				Problems::quote_wording(2, R->name);
				Problems::quote_stream(3, letter);
				if (c == 0) Problems::quote_text(4, "no lettered responses at all");
				else Problems::quote_stream(4, offers);
				Problems::Issue::handmade_problem(_p_(PM_NoSuchResponse));
				Problems::issue_problem_segment(
					"You wrote %1, but the '%2' doesn't have a response "
					"lettered '%3'. (It has %4.)");
				Problems::issue_problem_end();
				DISCARD_TEXT(letter);
				DISCARD_TEXT(offers);
			}
		}
	}
}

void Rules::now_rule_defines_response(rule *R, int code, response_message *resp) {
	if (R == NULL) internal_error("null rule defines response");
	R->lettered_responses[code] = resp;
}

void Rules::now_rule_needs_response(rule *R, int code, wording W) {
	if (R == NULL) internal_error("null rule uses response");
	R->lettered_responses_used[code] = current_sentence;
	if (Wordings::nonempty(W)) R->lettered_responses_value[code] = W;
	Rules::unimport(R);
}

wording Rules::get_response_value(rule *R, int code) {
	if (R == NULL) internal_error("null rule uses response");
	return R->lettered_responses_value[code];
}

parse_node *Rules::get_response_sentence(rule *R, int code) {
	if (R == NULL) internal_error("null rule uses response");
	return R->lettered_responses_used[code];
}

ph_stack_frame *Rules::stack_frame(rule *R) {
	if ((R == NULL) || (R->defn_as_phrase == NULL)) return NULL;
	return &(R->defn_as_phrase->stack_frame);
}

int Rules::portable(rule *R) {
	if ((R) && (Wordings::nonempty(R->name)) &&
		(R->first_applicability_condition == NULL) &&
		(R->rule_extern_iname == NULL) &&
		(Modules::find(R->defn_as_phrase->declaration_node) == Modules::SR()))
		return TRUE;
	return FALSE;
}

void Rules::export_named_rules(void) {
	if (export_mode) {
		rule *R;
		LOOP_OVER(R, rule)
			if (Rules::portable(R))
				Emit::export(Rules::iname(R), R->name);
	}
}

package_request *Rules::package(rule *R) {
	return R->rule_package;
}
