[RTRules::] Rules.

To compile the rules submodule for a compilation unit, which contains
_rule packages.

@h Compilation data.
Each |rule| object contains this data.

Everything here would be straightforward if all rules were declared with
imperative code, as of course most of them are. In that case, |local_iname|
is the function to apply the rule, and the other inames here are all null.

The difficulty arises when a rule is defined by an Inter function in some
kit. That function wasn't compiled by us, and we need to mock something up
to make it behave just as a regular rule would: in particular it needs to
be able to print response texts, and to have applicability constraints.
In these cases, |foreign_iname| is set and |local_iname| is null.

=
typedef struct rule_compilation_data {
	struct package_request *rule_package;
	struct inter_name *anchor_iname; /* for cross-references to the package */
	struct inter_name *local_iname; /* if the defining function is inside the package  */
	struct inter_name *foreign_iname; /* if it is outside */
	struct inter_name *foreign_response_handler_iname; /* in which case this produces its response texts */
	struct inter_name *shell_fn_around_foreign_iname; /* and this tests its applicability constraints */
	struct wording italicised_text; /* when indexing a rulebook */
	struct parse_node *where_declared;
} rule_compilation_data;

@ Initially, of course, we know nothing about the definition of R, and everything
is null.

=
rule_compilation_data RTRules::new_compilation_data(rule *R) {
	rule_compilation_data rcd;
	rcd.anchor_iname = NULL;
	rcd.local_iname = NULL;
	rcd.foreign_iname = NULL;
	rcd.foreign_response_handler_iname = NULL;
	rcd.shell_fn_around_foreign_iname = NULL;
	rcd.rule_package = NULL;
	rcd.italicised_text = EMPTY_WORDING;
	rcd.where_declared = current_sentence;
	return rcd;
}

@ The package is created on demand:

=
package_request *RTRules::package(rule *R) {
	if (R->compilation_data.rule_package == NULL)
		R->compilation_data.rule_package = Hierarchy::local_package_to(RULES_HAP,
			R->compilation_data.where_declared);
	return R->compilation_data.rule_package;
}

inter_name *RTRules::anchor_iname(rule *R) {
	if (R->compilation_data.anchor_iname == NULL)
		R->compilation_data.anchor_iname =
			Hierarchy::make_iname_in(RULE_ANCHOR_HL, RTRules::package(R));
	return R->compilation_data.anchor_iname;
}

@ But by the time the inames are needed, we will know whether the rule is local
or foreign.

=
int RTRules::is_local(rule *R) {
	if (R->defn_as_I7_source) return TRUE;
	return FALSE;
}
int RTRules::is_foreign(rule *R) {
	if (Str::len(R->defn_as_Inter_function) > 0) return TRUE;
	return FALSE;
}

@ The local iname is created on demand, but note that it cannot be created
unless the rule is local.

=
inter_name *RTRules::local_iname(rule *R) {
	if ((R->compilation_data.local_iname == NULL) && (RTRules::is_local(R)))
		R->compilation_data.local_iname =
			Hierarchy::make_iname_in(RULE_FN_HL, RTRules::package(R));
	return R->compilation_data.local_iname;
}

@ And correspondingly for the foreign cases:

=
inter_name *RTRules::foreign_iname(rule *R) {
	if ((R->compilation_data.foreign_iname == NULL) && (RTRules::is_foreign(R)))
		R->compilation_data.foreign_iname =
			HierarchyLocations::find_by_name(Emit::tree(), R->defn_as_Inter_function);
	return R->compilation_data.foreign_iname;
}

@ If the author wants to place applicability constraints on a rule defined in
a kit, like so:

>> The carrying requirements rule does nothing when eating the lollipop.

then how do we accommodate that? We cannot change the foreign function, so
instead we route execution through a "shell function" to test those
constraints. In pseudocode:
= (text)
SHELL() {
	if (not (eating the lollipop)) {
		RULE();
	}
}
=
The following provides an iname for that shell, constructed only if needed.

=
inter_name *RTRules::shell_iname(rule *R) {
	if ((R->compilation_data.shell_fn_around_foreign_iname == NULL) &&
		(RTRules::is_foreign(R)))
		R->compilation_data.shell_fn_around_foreign_iname =
			Hierarchy::make_iname_in(SHELL_FN_HL, RTRules::package(R));
	return R->compilation_data.shell_fn_around_foreign_iname;
}

@ Note that the response handler function must be made available to the linker,
because the idea is that the kit function will use it. For example, the code
in the kit might read like so:
= (text as Inform 6)
[ MY_FOREIGN_R;
	...
	MY_FOREIGN_RM('A');
	...
	MY_FOREIGN_RM('B');
	...
];
=
This code is making calls to a function |MY_FOREIGN_RM| which does not exist
in the kit; it's the handler function, which we will define here. But in order
for the references in the kit to match up correctly, we must therefore make
the handler available.

=
inter_name *RTRules::response_handler_iname(rule *R) {
	if ((R->compilation_data.foreign_response_handler_iname == NULL) &&
		(RTRules::is_foreign(R))) {
		R->compilation_data.foreign_response_handler_iname =
			Hierarchy::derive_iname_in(RESPONDER_FN_HL,
				RTRules::foreign_iname(R), RTRules::package(R));
		Hierarchy::make_available(R->compilation_data.foreign_response_handler_iname);
	}
	return R->compilation_data.foreign_response_handler_iname;
}

@ As any passing Ghostbusters might ask: who you gonna call? That is, if you
want to run a rule, which of these inames should be used as its function?

=
inter_name *RTRules::iname(rule *R) {
	if (RTRules::is_local(R)) {
		return RTRules::local_iname(R);
	}
	if (RTRules::is_foreign(R)) {
		if (LinkedLists::len(R->applicability_constraints) > 0) {
			return RTRules::shell_iname(R); /* which then calls the foreign iname */
		} else {
			return RTRules::foreign_iname(R);
		}
	}
	internal_error("rule is undefined and has no iname");
	return NULL;
}

@

=
void RTRules::set_italicised_index_text(rule *R, wording W) {
	R->compilation_data.italicised_text = W;
}

@h Compilation.

=
void RTRules::compile(void) {
	rule *R;
	LOOP_OVER(R, rule) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "compile rule '%W'", R->name);
		Sequence::queue(&RTRules::compilation_agent, STORE_POINTER_rule(R), desc);
	}
}

rule *rule_being_compiled = NULL; /* rule whose phrase's definition is being compiled */
rule *RTRules::rule_currently_being_compiled(void) {
	return rule_being_compiled;
}

@ This compiles (almost) everything needed for a single rule: the exception being
response handlers for foreign rules -- see //Responses::via_Inter_compilation_agent//.

=
void RTRules::compilation_agent(compilation_subtask *t) {
	rule *R = RETRIEVE_POINTER_rule(t->data);
	rule_being_compiled = R;
	package_request *P = RTRules::package(R);

	@<Compile the name and printed name metadata@>;
	@<Compile the value metadata@>;

	if (RTRules::is_local(R)) @<Compile resources for a local rule@>;
	if (RTRules::is_foreign(R)) @<Compile resources for a foreign rule@>;

	rule_being_compiled = NULL;
}

@<Compile the name and printed name metadata@> =
	wording W = EMPTY_WORDING;
	TEMPORARY_TEXT(PN)
	if (Wordings::nonempty(R->name)) {
		W = R->name;
		TranscodeText::from_text(PN, W);
	} else if (RTRules::is_local(R)) {
		W = Articles::remove_the(Node::get_text(R->defn_as_I7_source->at));
		TranscodeText::from_text(PN, W);
	} else {
		WRITE_TO(PN, "%n", RTRules::iname(R));
	}
	if (Wordings::nonempty(W))
		Hierarchy::apply_metadata_from_wording(P, RULE_NAME_MD_HL, W);
	Hierarchy::apply_metadata(P, RULE_PNAME_MD_HL, PN);
	if ((R->defn_as_I7_source) &&
		(Wordings::nonempty(Node::get_text(R->defn_as_I7_source->at))))
		Hierarchy::apply_metadata_from_number(P, RULE_AT_MD_HL,
			(inter_ti) Wordings::first_wn(Node::get_text(R->defn_as_I7_source->at)));
	DISCARD_TEXT(PN)
	if ((R->defn_as_I7_source) &&
		(Wordings::nonempty(R->defn_as_I7_source->log_text)))
		Hierarchy::apply_metadata_from_raw_wording(P, RULE_PREAMBLE_MD_HL, 
			R->defn_as_I7_source->log_text);

@<Compile the value metadata@> =
	Emit::numeric_constant(RTRules::anchor_iname(R), 1105);
	Hierarchy::apply_metadata_from_iname(P, RULE_VALUE_MD_HL, RTRules::iname(R));
	applicability_constraint *acl;
	LOOP_OVER_LINKED_LIST(acl, applicability_constraint, R->applicability_constraints) {
		package_request *EP =
			Hierarchy::package_within(RULE_APPLICABILITY_CONDITIONS_HAP, P);
		Hierarchy::apply_metadata_from_raw_wording(EP, AC_TEXT_MD_HL,
			Node::get_text(acl->where_imposed));
		Hierarchy::apply_metadata_from_number(EP, AC_AT_MD_HL,
			(inter_ti) Wordings::first_wn(Node::get_text(acl->where_imposed)));
	}

@<Compile resources for a local rule@> =
	imperative_defn *id = R->defn_as_I7_source;
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	if (Wordings::empty(rfd->constant_name))
		Hierarchy::apply_metadata_from_wording(P, RULE_NAME_MD_HL, Node::get_text(id->at));
	R->defn_as_I7_source->body_of_defn->compilation_data.at_least_one_compiled_form_needed = TRUE;
	current_sentence = R->defn_as_I7_source->at;
	CompileImperativeDefn::not_from_phrase(
		R->defn_as_I7_source->body_of_defn,
		&total_phrases_compiled, total_phrases_to_compile,
		R->variables_visible_in_definition, R);
	R->defn_as_I7_source->body_of_defn->compilation_data.at_least_one_compiled_form_needed = FALSE;

	int t = TimedRules::get_timing_of_event(id);
	if (t != NOT_A_TIMED_EVENT) {
		Hierarchy::apply_metadata_from_number(RTRules::package(R),
			RULE_TIMED_MD_HL, 1);
		if (t != NO_FIXED_TIME)
			Hierarchy::apply_metadata_from_number(RTRules::package(R),
				RULE_TIMED_FOR_MD_HL, (inter_ti) t);
	}

@ A foreign rule may need a response handler and/or a shell function. As
noted above, response handlers are compiled elsewhere, so here it's all
about the shell:

@<Compile resources for a foreign rule@> =
	if (LinkedLists::len(R->applicability_constraints) > 0) {
		inter_name *shell_iname = RTRules::shell_iname(R);
		packaging_state save = Functions::begin(shell_iname);
		if (RTRules::compile_constraint(R) == FALSE) {
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
			EmitCode::call(RTRules::foreign_iname(R));
			EmitCode::up();
		}
		Functions::end(save);
	}

@ Since it hasn't been collected yet when the rule package is first made, this
usage data has to be added to the package much later on:

=
void RTRules::annotate_timed_rules_with_usage(void) {
	rule *R;
	LOOP_OVER(R, rule) {
		imperative_defn *id = R->defn_as_I7_source;
		if (id) {
			int t = TimedRules::get_timing_of_event(id);
			if (t != NOT_A_TIMED_EVENT) {
				linked_list *L = TimedRules::get_uses_as_event(id);
				parse_node *p;
				LOOP_OVER_LINKED_LIST(p, parse_node, L) {
					package_request *TP =
						Hierarchy::package_within(TIMED_RULE_TRIGGER_HAP, RTRules::package(R));
					Hierarchy::apply_metadata_from_number(TP, RULE_USED_AT_MD_HL,
						(inter_ti) Wordings::first_wn(Node::get_text(p)));
				}
			}
		}
	}
}

@ The following, then, compiles code to test if the "applicability constraints"
have been violated. This is used not only in shell functions around kit-defined
rules, but also as part of the "firing test" of rules defined by imperative
code: see below.

It is possible for a constraint to be, basically, "never fire this rule". If
so, the function here returns |TRUE|. In that eventuality, the function call
to the rule need never be compiled.

=
int RTRules::compile_constraint(rule *R) {
	if (R) {
		applicability_constraint *acl;
		LOOP_OVER_LINKED_LIST(acl, applicability_constraint, R->applicability_constraints) {
			current_sentence = acl->where_imposed;
			if (Wordings::nonempty(acl->text_of_condition)) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
				if (acl->sense_of_applicability) {
					EmitCode::inv(NOT_BIP);
					EmitCode::down();
				}
				@<Compile the constraint condition@>;
				if (acl->sense_of_applicability) {
					EmitCode::up();
				}
				EmitCode::code();
				EmitCode::down();
			}
			@<Compile the rule termination code used if the constraint was violated@>;
			if (Wordings::nonempty(acl->text_of_condition)) {
				EmitCode::up();
				EmitCode::up();
			} else {
				return TRUE;
			}
		}
	}
	return FALSE;
}

@<Compile the constraint condition@> =
	if (Wordings::nonempty(acl->text_of_condition) == FALSE) {
		EmitCode::val_true();
	} else {
		if (<s-condition>(acl->text_of_condition)) {
			parse_node *spec = <<rp>>;
			Dash::check_condition(spec);
			CompileValues::to_code_val_of_kind(spec, K_truth_state);
		} else {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, acl->text_of_condition);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadRuleConstraint));
			Problems::issue_problem_segment(
				"In %1, you placed a constraint '%2' on a rule, but this isn't "
				"a condition I can understand.");
			Problems::issue_problem_end();
			EmitCode::val_number(1);
		}
	}

@ Note that in the does nothing case, the rule ends without result, rather than
failing; so it doesn't terminate the following of its rulebook.

@<Compile the rule termination code used if the constraint was violated@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
	if (acl->substituted_rule) {
		inter_name *subbed = RTRules::iname(acl->substituted_rule);
		EmitCode::call(subbed);
	} else {
		EmitCode::val_number(0);
	}
	EmitCode::up();

@h Compiling the firing test.
Each rule compiles to a function, and that function is called whenever the
opportunity might exist for the rule to fire: but it still sometimes won't
fire, because the conditions might not be met. In pseudocode, the function
looks like this:
= (text)
	if (firing-condition-1) {
		if (firing-condition-2) {
			...
			return some-default-outcome;
		} else {
			fail 2
		}
	} else {
		fail 1
	}
=
Everything before the |...| is "head", and everything after is the "tail".
The return statement isn't necessarily reached, because even if the firing
condition holds, the |...| code may decide to return in some other way.
It provides only a default to cover rules which don't specify an outcome.

=
int RTRules::compile_test_head(id_body *idb, rule *R) {
	inter_name *identifier = CompileImperativeDefn::iname(idb);
	id_runtime_context_data *phrcd = &(idb->runtime_context_data);

	if (RTRules::compile_constraint(R) == TRUE) return TRUE;

	int tests = 0;

	if (PluginCalls::compile_test_head(idb, R, &tests) == FALSE) {
		if (ActionRules::get_ap(phrcd)) @<Compile an action test head@>;
	}
	if (Wordings::nonempty(phrcd->activity_context))
		@<Compile an activity or explicit condition test head@>;

	if ((tests > 0) || (idb->compilation_data.compile_with_run_time_debugging)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_number, Hierarchy::find(DEBUG_RULES_HL));
			EmitCode::code();
			EmitCode::down();
				EmitCode::call(Hierarchy::find(DB_RULE_HL));
				EmitCode::down();
					EmitCode::val_iname(K_value, identifier);
					EmitCode::val_number((inter_ti) idb->allocation_id);
					EmitCode::val_number(0);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}
	return FALSE;
}

@ This is almost the up-down reflection of the head, but note that it begins
with the default outcome return (see above).

=
void RTRules::compile_test_tail(id_body *idb, rule *R) {
	inter_name *identifier = CompileImperativeDefn::iname(idb);
	id_runtime_context_data *phrcd = &(idb->runtime_context_data);
	rulebook *rb = RuleFamily::get_rulebook(idb->head_of_defn);
	if (rb) RTRulebooks::compile_default_outcome(Rulebooks::get_outcomes(rb));
	if (Wordings::nonempty(phrcd->activity_context))
		@<Compile an activity or explicit condition test tail@>;
	if (PluginCalls::compile_test_tail(idb, R) == FALSE) {
		if (ActionRules::get_ap(phrcd)) @<Compile an action test tail@>;
	}
}

@h Plugin tests.

=
int RTRules::actions_compile_test_head(id_body *idb, rule *R, int *tests) {
	id_runtime_context_data *phrcd = &(idb->runtime_context_data);
	if (Scenes::get_rcd_spec(phrcd)) @<Compile a scene test head@>;
	if (ActionRules::get_ap(phrcd)) @<Compile possibly testing actor action test head@>
	else if (ActionRules::get_always_test_actor(phrcd)) @<Compile an actor-is-player test head@>;
	return TRUE;
}

int RTRules::actions_compile_test_tail(id_body *idb, rule *R) {
	inter_name *identifier = CompileImperativeDefn::iname(idb);
	id_runtime_context_data *phrcd = &(idb->runtime_context_data);
	if (ActionRules::get_ap(phrcd)) @<Compile an action test tail@>
	else if (ActionRules::get_always_test_actor(phrcd)) @<Compile an actor-is-player test tail@>;
	if (Scenes::get_rcd_spec(phrcd)) @<Compile a scene test tail@>;
	return TRUE;
}

@h Scene test.

@<Compile a scene test head@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		RTScenes::compile_during_clause(Scenes::get_rcd_spec(phrcd));
		EmitCode::code();
		EmitCode::down();

	(*tests)++;

@<Compile a scene test tail@> =
	inter_ti failure_code = 1;
	@<Compile a generic test fail@>;

@h Action test.

@<Compile an action test head@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		RTActionPatterns::compile_pattern_match_actorless(ActionRules::get_ap(phrcd));
		EmitCode::code();
		EmitCode::down();

	tests++;
	if (ActionPatterns::involves_actions(ActionRules::get_ap(phrcd))) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_object, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
			EmitCode::up();
	}

@<Compile possibly testing actor action test head@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		if (ActionRules::get_never_test_actor(phrcd))
			RTActionPatterns::compile_pattern_match_actorless(ActionRules::get_ap(phrcd));
		else
			RTActionPatterns::compile_pattern_match(ActionRules::get_ap(phrcd));
		EmitCode::code();
		EmitCode::down();

	(*tests)++;
	if (ActionPatterns::involves_actions(ActionRules::get_ap(phrcd))) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_object, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
			EmitCode::up();
	}

@<Compile an action test tail@> =
	inter_ti failure_code = 2;
	@<Compile a generic test fail@>;

@h Actor-is-player test.

@<Compile an actor-is-player test head@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
			EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();

	(*tests)++;

@<Compile an actor-is-player test tail@> =
	inter_ti failure_code = 3;
	@<Compile a generic test fail@>;

@h Activity-or-condition test.

@<Compile an activity or explicit condition test head@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		activity_list *avl = phrcd->avl;
		if (avl) {
			@<Compile a test that something in the activity list is going on@>;
		} else {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadWhenWhile),
				"I don't understand the 'when/while' clause",
				"which should name activities or conditions.");
			EmitCode::val_false();
		}
		EmitCode::code();
		EmitCode::down();

		RTActivities::annotate_list_for_cross_references(avl, idb);
		tests++;

@<Compile an activity or explicit condition test tail@> =
	inter_ti failure_code = 4;
	@<Compile a generic test fail@>;

@<Compile a test that something in the activity list is going on@> =
	int negate_me = FALSE, downs = 0;
	if (avl->ACL_parity == FALSE) negate_me = TRUE;
	if (negate_me) { EmitCode::inv(NOT_BIP); EmitCode::down(); downs++; }

	int cl = 0;
	for (activity_list *k = avl; k; k = k->next) cl++;

	int ncl = 0;
	while (avl != NULL) {
		if (++ncl < cl) {
			EmitCode::inv(OR_BIP);
			EmitCode::down();
			downs++;
		}
		if (avl->activity != NULL) {
			EmitCode::call(Hierarchy::find(TESTACTIVITY_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, avl->activity->compilation_data.value_iname);
				if (avl->acting_on) {
					if (Specifications::is_description(avl->acting_on)) {
						EmitCode::val_iname(K_value,
							Deferrals::function_to_test_description(avl->acting_on));
					} else {
						EmitCode::val_number(0);
						CompileValues::to_code_val(avl->acting_on);
					}
				}
			EmitCode::up();
		}
		else {
			CompileValues::to_code_val(avl->only_when);
		}
		avl = avl->next;
	}

	while (downs > 0) { EmitCode::up(); downs--; }

@h Failure in general.

@<Compile a generic test fail@> =
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(GT_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_number, Hierarchy::find(DEBUG_RULES_HL));
					EmitCode::val_number(1);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::call(Hierarchy::find(DB_RULE_HL));
					EmitCode::down();
						EmitCode::val_iname(K_value, identifier);
						EmitCode::val_number((inter_ti) idb->allocation_id);
						EmitCode::val_number(failure_code);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
