[RTRules::] Rules.

To compile run-time support for rules.

@

= (early code)
rule *rule_being_compiled = NULL; /* rule whose phrase's definition is being compiled */
rule *adopted_rule_for_compilation = NULL; /* when a new response is being compiled */
int adopted_marker_for_compilation = -1; /* when a new response is being compiled */

@ In Inter code, a rule is compiled to the name of the routine implementing it.

=
typedef struct rule_compilation_data {
	struct package_request *rule_package;
	struct inter_name *shell_routine_iname;
	struct inter_name *rule_extern_iname; /* if externally defined, this is the I6 routine */
	struct inter_name *xiname;
	struct inter_name *rule_extern_response_handler_iname; /* and this produces any response texts it has */
	int defn_compiled; /* has the definition of this rule, if needed, been compiled yet? */
} rule_compilation_data;

rule_compilation_data RTRules::new_compilation_data(rule *R) {
	rule_compilation_data rcd;
	rcd.rule_extern_iname = NULL;
	rcd.xiname = NULL;
	rcd.rule_extern_response_handler_iname = NULL;
	rcd.shell_routine_iname = NULL;
	rcd.rule_package = Hierarchy::local_package(RULES_HAP);
	rcd.defn_compiled = FALSE;
	if (Wordings::nonempty(R->name))
		Hierarchy::markup_wording(rcd.rule_package, RULE_NAME_HMD, R->name);
	return rcd;
}

stack_frame *RTRules::stack_frame(rule *R) {
	if ((R == NULL) || (R->defn_as_I7_source == NULL)) return NULL;
	return &(R->defn_as_I7_source->body_of_defn->compilation_data.id_stack_frame);
}

void RTRules::prepare_rule(imperative_defn *id, rule *R) {
	rule_family_data *rfd = RETRIEVE_POINTER_rule_family_data(id->family_specific_data);
	package_request *P = RTRules::package(R);
	if (Wordings::empty(rfd->constant_name))
		Hierarchy::markup_wording(P, RULE_NAME_HMD, Node::get_text(id->at));
	CompileImperativeDefn::set_iname(id->body_of_defn, 
		Hierarchy::make_localised_iname_in(RULE_FN_HL, P));
}

package_request *RTRules::package(rule *R) {
	return R->compilation_data.rule_package;
}

inter_name *RTRules::shell_iname(rule *R) {
	if (R->compilation_data.shell_routine_iname == NULL)
		R->compilation_data.shell_routine_iname = Hierarchy::make_iname_in(SHELL_FN_HL, R->compilation_data.rule_package);
	return R->compilation_data.shell_routine_iname;
}

inter_name *RTRules::iname(rule *R) {
	if (R->defn_as_I7_source) return CompileImperativeDefn::iname(R->defn_as_I7_source->body_of_defn);
	else if (R->compilation_data.rule_extern_iname) {
		if (LinkedLists::len(R->applicability_constraints) > 0) {
			return RTRules::shell_iname(R);
		} else {
			return R->compilation_data.rule_extern_iname;
		}
	} else internal_error("tried to symbolise nameless rule");
	return NULL;
}

void RTRules::define_by_Inter_function(rule *R) {
	R->compilation_data.rule_extern_iname = Hierarchy::make_iname_in(EXTERIOR_RULE_HL, R->compilation_data.rule_package);

	inter_name *xiname = Produce::find_by_name(Emit::tree(), R->defn_as_Inter_function);
	Emit::iname_constant(R->compilation_data.rule_extern_iname, K_value, xiname); 

	R->compilation_data.xiname = xiname;
}

inter_name *RTRules::get_handler_definition(rule *R) {
	if (R->compilation_data.rule_extern_response_handler_iname == NULL) {
		R->compilation_data.rule_extern_response_handler_iname =
			Hierarchy::derive_iname_in(RESPONDER_FN_HL, R->compilation_data.xiname, R->compilation_data.rule_package);
		Hierarchy::make_available(R->compilation_data.rule_extern_response_handler_iname);
	}
	return R->compilation_data.rule_extern_response_handler_iname;
}

@h Compilation.
Only those rules defined as I7 phrases need us to compile anything -- and then
what we compile, of course, is the phrase in question.

=
void RTRules::compile_definition(rule *R, int *i, int max_i) {
	if (R->compilation_data.defn_compiled == FALSE) {
		R->compilation_data.defn_compiled = TRUE;
		rule_being_compiled = R;
		if (R->defn_as_I7_source)
			CompileImperativeDefn::not_from_phrase(R->defn_as_I7_source->body_of_defn, i, max_i,
				R->variables_visible_in_definition, R);
		if ((R->compilation_data.rule_extern_iname) &&
			(LinkedLists::len(R->applicability_constraints) > 0))
			@<Compile a shell routine to apply conditions to an I6 rule@>;
		rule_being_compiled = NULL;
	}
}

@ This is the trickiest case: where the user has asked for something like

>> The carrying requirements rule does nothing when eating the lollipop.

and the carrying requirements rule is defined by an I6 routine, which we
are unable to modify. What we do is to create a shell routine to call it,
and put the conditions into this outer shell; we then use the outer shell
as the definition of the rule in future.

@<Compile a shell routine to apply conditions to an I6 rule@> =
	inter_name *shell_iname = RTRules::shell_iname(R);
	packaging_state save = Functions::begin(shell_iname);
	if (RTRules::compile_constraint(R) == FALSE) {
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
		EmitCode::call(R->compilation_data.rule_extern_iname);
		EmitCode::up();
	}
	Functions::end(save);

@ The following generates code to terminate a rule early if its applicability
conditions have not been met.

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
		if (Inter::Constant::is_routine(InterNames::to_symbol(subbed)) == FALSE) {
			EmitCode::val_number(0);
		} else {
			EmitCode::call(subbed);
		}
	} else {
		EmitCode::val_number(0);
	}
	EmitCode::up();

@h Printing rule names at run time.

=
void RTRules::RulePrintingRule_routine(void) {
	inter_name *iname = Hierarchy::find(RULEPRINTINGRULE_HL);
	packaging_state save = Functions::begin(iname);
	inter_symbol *R_s = LocalVariables::new_other_as_symbol(I"R");
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			EmitCode::inv(GE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, R_s);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::inv(LT_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, R_s);
				EmitCode::val_iname(K_value, Hierarchy::find(NUMBER_RULEBOOKS_CREATED_HL));
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Print a rulebook name@>;
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Print a rule name@>;
		EmitCode::up();
	EmitCode::up();
	Functions::end(save);
	Hierarchy::make_available(iname);
}

@<Print a rulebook name@> =
	if (global_compilation_settings.memory_economy_in_force) {
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I"(rulebook ");
		EmitCode::up();
		EmitCode::inv(PRINTNUMBER_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, R_s);
		EmitCode::up();
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I")");
		EmitCode::up();
	} else {
		EmitCode::inv(PRINTSTRING_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(RULEBOOKNAMES_HL));
				EmitCode::val_symbol(K_value, R_s);
			EmitCode::up();
		EmitCode::up();
	}

@<Print a rule name@> =
	if (global_compilation_settings.memory_economy_in_force) {
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I"(rule at address ");
		EmitCode::up();
		EmitCode::inv(PRINTNUMBER_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, R_s);
		EmitCode::up();
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I")");
		EmitCode::up();
	} else {
		rule *R;
		LOOP_OVER(R, rule) {
			if ((Wordings::nonempty(R->name) == FALSE) &&
				((R->defn_as_I7_source == NULL) ||
					(R->defn_as_I7_source->at == NULL) ||
					(R->defn_as_I7_source->at->down == NULL)))
					continue;
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, R_s);
					EmitCode::val_iname(K_value, RTRules::iname(R));
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					TEMPORARY_TEXT(OUT)
					@<Print a textual name for this rule@>;
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(OUT);
					EmitCode::up();
					EmitCode::rtrue();
					DISCARD_TEXT(OUT)
				EmitCode::up();
			EmitCode::up();
		}
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I"(nameless rule at address ");
		EmitCode::up();
		EmitCode::inv(PRINTNUMBER_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, R_s);
		EmitCode::up();
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I")");
		EmitCode::up();
	}

@<Print a textual name for this rule@> =
	if (Wordings::nonempty(R->name)) {
		CompiledText::from_text(OUT, R->name);
	} else if (R->defn_as_I7_source->at) {
		CompiledText::from_text(OUT,
			Articles::remove_the(
				Node::get_text(R->defn_as_I7_source->at)));
	} else WRITE("%n", RTRules::iname(R));

@ =
void RTRules::compile_comment(rule *R, int index, int from) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "Rule %d/%d", index, from);
	if (R->defn_as_I7_source == NULL) {
		WRITE_TO(C, ": %n", R->compilation_data.rule_extern_iname);
	}
	EmitCode::comment(C);
	DISCARD_TEXT(C)
	if (R->defn_as_I7_source) {
		TEMPORARY_TEXT(C)
		WRITE_TO(C, "%~W:", R->defn_as_I7_source->log_text);
		EmitCode::comment(C);
		DISCARD_TEXT(C)
	}
}

@h Compilation of I6-format rulebook.
The following can generate both old-style array rulebooks and routine rulebooks,
which were introduced in December 2010.

=
void RTRules::start_list_compilation(void) {
	inter_name *iname = Hierarchy::find(EMPTY_RULEBOOK_INAME_HL);
	packaging_state save = Functions::begin(iname);
	LocalVariables::new_other_parameter(I"forbid_breaks");
	EmitCode::rfalse();
	Functions::end(save);
	Hierarchy::make_available(iname);
}

@

@d ARRAY_RBF 1 /* format as an array simply listing the rules */
@d GROUPED_ARRAY_RBF 2 /* format as a grouped array, for quicker action testing */
@d ROUTINE_RBF 3 /* format as a routine which runs the rulebook */
@d RULE_OPTIMISATION_THRESHOLD 20 /* group arrays when larger than this number of rules */

=
inter_name *RTRules::list_compile(booking_list *L,
	inter_name *identifier, int action_based, int parameter_based) {
	if (L == NULL) return NULL;
	inter_name *rb_symb = NULL;

	int countup = BookingLists::length(L);
	if (countup == 0) {
		rb_symb = Emit::iname_constant(identifier, K_value,
			Hierarchy::find(EMPTY_RULEBOOK_INAME_HL));
	} else {
		int format = ROUTINE_RBF;

		@<Compile the rulebook in the given format@>;
	}
	return rb_symb;
}

@ Grouping is the practice of gathering together rules which all rely on
the same action going on; it's then efficient to test the action once rather
than once for each rule.

@<Compile the rulebook in the given format@> =
	int grouping = FALSE, group_cap = 0;
	switch (format) {
		case GROUPED_ARRAY_RBF: grouping = TRUE; group_cap = 31; break;
		case ROUTINE_RBF: grouping = TRUE; group_cap = 2000000000; break;
	}
	if (action_based == FALSE) grouping = FALSE;

	inter_symbol *forbid_breaks_s = NULL, *rv_s = NULL, *original_deadflag_s = NULL, *p_s = NULL;
	packaging_state save_array = Emit::new_packaging_state();

	@<Open the rulebook compilation@>;
	int group_size = 0, group_started = FALSE, entry_count = 0, action_group_open = FALSE;
	LOOP_OVER_BOOKINGS(br, L) {
		parse_node *spec = Rvalues::from_rule(RuleBookings::get_rule(br));
		if (grouping) {
			if (group_size == 0) {
				if (group_started) @<End an action group in the rulebook@>;
				#ifdef IF_MODULE
				action_name *an = RTRules::br_required_action(br);
				booking *brg = br;
				while ((brg) && (an == RTRules::br_required_action(brg))) {
					group_size++;
					brg = brg->next_booking;
				}
				#endif
				#ifndef IF_MODULE
				booking *brg = br;
				while (brg) {
					group_size++;
					brg = brg->next_booking;
				}
				#endif
				if (group_size > group_cap) group_size = group_cap;
				group_started = TRUE;
				@<Begin an action group in the rulebook@>;
			}
			group_size--;
		}
		@<Compile an entry in the rulebook@>;
		entry_count++;
	}
	if (group_started) @<End an action group in the rulebook@>;
	@<Close the rulebook compilation@>;

@<Open the rulebook compilation@> =
	rb_symb = identifier;
	switch (format) {
		case ARRAY_RBF: save_array = EmitArrays::begin(identifier, K_value); break;
		case GROUPED_ARRAY_RBF: save_array = EmitArrays::begin(identifier, K_value); EmitArrays::numeric_entry((inter_ti) -2); break;
		case ROUTINE_RBF: {
			save_array = Functions::begin(identifier);
			forbid_breaks_s = LocalVariables::new_other_as_symbol(I"forbid_breaks");
			rv_s = LocalVariables::new_internal_commented_as_symbol(I"rv", I"return value");
			if (countup > 1)
				original_deadflag_s =
					LocalVariables::new_internal_commented_as_symbol(I"original_deadflag", I"saved state");
			if (parameter_based)
				p_s = LocalVariables::new_internal_commented_as_symbol(I"p", I"rulebook parameter");

		RTRules::commentary(L);


			if (countup > 1) {
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, original_deadflag_s);
					EmitCode::val_iname(K_value, Hierarchy::find(DEADFLAG_HL));
				EmitCode::up();
			}
			if (parameter_based) {
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, p_s);
					EmitCode::val_iname(K_value, Hierarchy::find(PARAMETER_VALUE_HL));
				EmitCode::up();
			}
			break;
		}
	}

@<Begin an action group in the rulebook@> =
	switch (format) {
		case GROUPED_ARRAY_RBF:
			#ifdef IF_MODULE
			if (an) RTActions::action_array_entry(an); else
			#endif
				EmitArrays::numeric_entry((inter_ti) -2);
			if (group_size > 1) EmitArrays::numeric_entry((inter_ti) group_size);
			action_group_open = TRUE;
			break;
		case ROUTINE_RBF:
			#ifdef IF_MODULE
			if (an) {
				EmitCode::inv(IFELSE_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(ACTION_HL));
						EmitCode::val_iname(K_value, RTActions::double_sharp(an));
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();

				action_group_open = TRUE;
			}
			#endif
			break;
	}

@<Compile an entry in the rulebook@> =
	switch (format) {
		case ARRAY_RBF:
		case GROUPED_ARRAY_RBF:
			CompileValues::to_array_entry(spec);
			break;
		case ROUTINE_RBF:
			if (entry_count > 0) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(NE_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, original_deadflag_s);
						EmitCode::val_iname(K_value, Hierarchy::find(DEADFLAG_HL));
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(RETURN_BIP);
						EmitCode::down();
							EmitCode::val_number(0);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			}
			@<Compile an optional mid-rulebook paragraph break@>;
			if (parameter_based) {
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(PARAMETER_VALUE_HL));
					EmitCode::val_symbol(K_value, p_s);
				EmitCode::up();
			}
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, rv_s);
				EmitCode::inv(INDIRECT0_BIP);
				EmitCode::down();
					CompileValues::to_code_val(spec);
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, rv_s);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, rv_s);
							EmitCode::val_number(2);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(RETURN_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, Hierarchy::find(REASON_THE_ACTION_FAILED_HL));
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();

					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						CompileValues::to_code_val(spec);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUPREF_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(LATEST_RULE_RESULT_HL));
					EmitCode::val_number(0);
				EmitCode::up();
				EmitCode::val_number(0);
			EmitCode::up();
			break;
	}

@<End an action group in the rulebook@> =
	if (action_group_open) {
		switch (format) {
			case ROUTINE_RBF:
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						@<Compile an optional mid-rulebook paragraph break@>;
					EmitCode::up();
				EmitCode::up();
				break;
		}
		action_group_open = FALSE;
	}

@<Close the rulebook compilation@> =
	switch (format) {
		case ARRAY_RBF:
		case GROUPED_ARRAY_RBF:
			EmitArrays::null_entry();
			EmitArrays::end(save_array);
			break;
		case ROUTINE_RBF:
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_number(0);
			EmitCode::up();
			Functions::end(save_array);
			break;
	}

@<Compile an optional mid-rulebook paragraph break@> =
	if (entry_count > 0) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_number, Hierarchy::find(SAY__P_HL));
			EmitCode::code();
			EmitCode::down();
				EmitCode::call(Hierarchy::find(RULEBOOKPARBREAK_HL));
				EmitCode::down();
					EmitCode::val_symbol(K_value, forbid_breaks_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}

@

=
#ifdef IF_MODULE
action_name *RTRules::br_required_action(booking *br) {
	imperative_defn *id = Rules::get_imperative_definition(br->rule_being_booked);
	if (id) return ActionRules::required_action(&(id->body_of_defn->runtime_context_data));
	return NULL;
}
#endif

@

=
void RTRules::compile_NUMBER_RULEBOOKS_CREATED(void) {
	inter_name *iname = Hierarchy::find(NUMBER_RULEBOOKS_CREATED_HL);
	Emit::numeric_constant(iname, (inter_ti) NUMBER_CREATED(rulebook));
	Hierarchy::make_available(iname);
}

@

=
typedef struct rulebook_compilation_data {
	struct inter_name *stv_creator_iname;
	struct package_request *rb_package;
	struct inter_name *rb_iname; /* run-time storage/routine holding contents */
} rulebook_compilation_data;

rulebook_compilation_data RTRules::new_rulebook_compilation_data(rulebook *rb,
	package_request *R) {
	rulebook_compilation_data rcd;
	rcd.stv_creator_iname = NULL;
	rcd.rb_package = R;
	rcd.rb_iname = Hierarchy::make_iname_in(RUN_FN_HL, R);
	return rcd;
}

@ We do not actually compile the I6 routines for a rulebook here, but simply
act as a proxy. The I6 arrays making the rulebooks available to run-time
code are the real outcome of the code in this section.

=
void RTRules::commentary(booking_list *L) {
	RuleBookings::list_judge_ordering(L);
	if (BookingLists::is_empty_of_i7_rules(L)) return;
	BookingLists::commentary(L);
}

void RTRules::rulebooks_array_array(void) {
	inter_name *iname = Hierarchy::find(RULEBOOKS_ARRAY_HL);
	packaging_state save = EmitArrays::begin(iname, K_value);
	rulebook *rb;
	LOOP_OVER(rb, rulebook)
		EmitArrays::iname_entry(rb->compilation_data.rb_iname);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}

void RTRules::compile_rulebooks(void) {
	RTRules::start_list_compilation();
	rulebook *B;
	LOOP_OVER(B, rulebook) {
		int act = FALSE;
		if (Rulebooks::action_focus(B)) act = TRUE;
		if (B->automatically_generated) act = FALSE;
		int par = FALSE;
		if (Rulebooks::action_focus(B) == FALSE) par = TRUE;
		LOGIF(RULEBOOK_COMPILATION, "Compiling rulebook: %W = %n\n",
			B->primary_name, B->compilation_data.rb_iname);
		RTRules::list_compile(B->contents, B->compilation_data.rb_iname, act, par);
	}
	rule *R;
	LOOP_OVER(R, rule)
		Rules::check_constraints_are_typesafe(R);
}

void RTRules::RulebookNames_array(void) {
	inter_name *iname = Hierarchy::find(RULEBOOKNAMES_HL);
	packaging_state save = EmitArrays::begin(iname, K_value);
	if (global_compilation_settings.memory_economy_in_force) {
		EmitArrays::numeric_entry(0);
		EmitArrays::numeric_entry(0);
	} else {
		rulebook *B;
		LOOP_OVER(B, rulebook) {
			TEMPORARY_TEXT(rbt)
			WRITE_TO(rbt, "%~W rulebook", B->primary_name);
			EmitArrays::text_entry(rbt);
			DISCARD_TEXT(rbt)
		}
	}
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}


inter_name *RTRules::get_stv_creator_iname(rulebook *B) {
	if (B->compilation_data.stv_creator_iname == NULL)
		B->compilation_data.stv_creator_iname =
			Hierarchy::make_iname_in(RULEBOOK_STV_CREATOR_FN_HL, B->compilation_data.rb_package);
	return B->compilation_data.stv_creator_iname;
}

void RTRules::rulebook_var_creators(void) {
	rulebook *B;
	LOOP_OVER(B, rulebook)
		if (SharedVariables::set_empty(B->my_variables) == FALSE) {
			RTVariables::set_shared_variables_creator(B->my_variables,
				RTRules::get_stv_creator_iname(B));
			RTVariables::compile_frame_creator(B->my_variables);
		}

	if (global_compilation_settings.memory_economy_in_force == FALSE) {
		inter_name *iname = Hierarchy::find(RULEBOOK_VAR_CREATORS_HL);
		packaging_state save = EmitArrays::begin(iname, K_value);
		LOOP_OVER(B, rulebook) {
			if (SharedVariables::set_empty(B->my_variables)) EmitArrays::numeric_entry(0);
			else EmitArrays::iname_entry(RTVariables::get_shared_variables_creator(B->my_variables));
		}
		EmitArrays::numeric_entry(0);
		EmitArrays::end(save);
		Hierarchy::make_available(iname);
	} else @<Make slow lookup routine@>;
}

@<Make slow lookup routine@> =
	inter_name *iname = Hierarchy::find(SLOW_LOOKUP_HL);
	packaging_state save = Functions::begin(iname);
	inter_symbol *rb_s = LocalVariables::new_other_as_symbol(I"rb");

	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, rb_s);
		EmitCode::code();
		EmitCode::down();

		rulebook *B;
		LOOP_OVER(B, rulebook)
			if (SharedVariables::set_empty(B->my_variables) == FALSE) {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) (B->allocation_id));
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(RETURN_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, RTRules::get_stv_creator_iname(B));
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			}

		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_number(0);
	EmitCode::up();

	Functions::end(save);

@

=
<notable-rulebook-outcomes> ::=
	it is very likely |
	it is likely |
	it is possible |
	it is unlikely |
	it is very unlikely

@ =
void RTRules::new_outcome(named_rulebook_outcome *rbno, wording W) {
	package_request *R = Hierarchy::local_package(OUTCOMES_HAP);
	Hierarchy::markup_wording(R, OUTCOME_NAME_HMD, W);
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
			Hierarchy::make_available(iname);
			Emit::iname_constant(iname, K_value, rbno->nro_iname);
		}
	}
}

inter_name *RTRules::outcome_identifier(named_rulebook_outcome *rbno) {
	return rbno->nro_iname;
}

inter_name *RTRules::default_outcome_identifier(void) {
	named_rulebook_outcome *rbno;
	LOOP_OVER(rbno, named_rulebook_outcome)
		return rbno->nro_iname;
	return NULL;
}

void RTRules::compile_default_outcome(outcomes *outs) {
	int rtrue = FALSE;
	rulebook_outcome *rbo = outs->default_named_outcome;
	if (rbo) {
		switch(rbo->kind_of_outcome) {
			case SUCCESS_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKSUCCEEDS_HL);
				EmitCode::call(iname);
				EmitCode::down();
				RTKinds::emit_weak_id_as_val(K_rulebook_outcome);
				EmitCode::val_iname(K_value, rbo->outcome_name->nro_iname);
				EmitCode::up();
				rtrue = TRUE;
				break;
			}
			case FAILURE_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKFAILS_HL);
				EmitCode::call(iname);
				EmitCode::down();
				RTKinds::emit_weak_id_as_val(K_rulebook_outcome);
				EmitCode::val_iname(K_value, rbo->outcome_name->nro_iname);
				EmitCode::up();
				rtrue = TRUE;
				break;
			}
		}
	} else {
		switch(outs->default_rule_outcome) {
			case SUCCESS_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKSUCCEEDS_HL);
				EmitCode::call(iname);
				EmitCode::down();
				EmitCode::val_number(0);
				EmitCode::val_number(0);
				EmitCode::up();
				rtrue = TRUE;
				break;
			}
			case FAILURE_OUTCOME: {
				inter_name *iname = Hierarchy::find(RULEBOOKFAILS_HL);
				EmitCode::call(iname);
				EmitCode::down();
				EmitCode::val_number(0);
				EmitCode::val_number(0);
				EmitCode::up();
				rtrue = TRUE;
				break;
			}
		}
	}

	if (rtrue) EmitCode::rtrue();
}

void RTRules::compile_outcome(named_rulebook_outcome *rbno) {
	id_body *idb = Functions::defn_being_compiled();
	rulebook_outcome *rbo = FocusAndOutcome::rbo_from_context(rbno, idb);
	if (rbo == NULL) {
		rulebook *rb;
		LOOP_OVER(rb, rulebook) {
			outcomes *outs = Rulebooks::get_outcomes(rb);
			rulebook_outcome *ro;
			LOOP_OVER_LINKED_LIST(ro, rulebook_outcome, outs->named_outcomes)
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
			EmitCode::call(iname);
			EmitCode::down();
			RTKinds::emit_weak_id_as_val(K_rulebook_outcome);
			EmitCode::val_iname(K_value, rbno->nro_iname);
			EmitCode::up();
			EmitCode::rtrue();
			break;
		}
		case FAILURE_OUTCOME: {
			inter_name *iname = Hierarchy::find(RULEBOOKFAILS_HL);
			EmitCode::call(iname);
			EmitCode::down();
			RTKinds::emit_weak_id_as_val(K_rulebook_outcome);
			EmitCode::val_iname(K_value, rbno->nro_iname);
			EmitCode::up();
			EmitCode::rtrue();
			break;
		}
		case NO_OUTCOME:
			EmitCode::rfalse();
			break;
		default:
			internal_error("bad RBO outcome kind");
	}
}

void RTRules::RulebookOutcomePrintingRule(void) {
	named_rulebook_outcome *rbno;
	LOOP_OVER(rbno, named_rulebook_outcome) {
		TEMPORARY_TEXT(RV)
		WRITE_TO(RV, "%+W", Nouns::nominative_singular(rbno->name));
		Emit::text_constant(rbno->nro_iname, RV);
		DISCARD_TEXT(RV)
	}

	inter_name *printing_rule_name = Kinds::Behaviour::get_iname(K_rulebook_outcome);
	packaging_state save = Functions::begin(printing_rule_name);
	inter_symbol *rbnov_s = LocalVariables::new_other_as_symbol(I"rbno");
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, rbnov_s);
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(PRINT_BIP);
			EmitCode::down();
				EmitCode::val_text(I"(no outcome)");
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(PRINTSTRING_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, rbnov_s);
			EmitCode::up();
			EmitCode::rfalse();
		EmitCode::up();
	EmitCode::up();
	Functions::end(save);
}

@h Compiling the firing test.
Each rule compiles to a routine, and this routine is called whenever the
opportunity might exist for the rule to fire. The structure of this is
similar to:
= (text as Inform 6)
	[ Rule;
	    if (some-firing-condition) {
	        ...
	        return some-default-outcome;
	    }
	];
=
The "test head" is the "if" line here, and the "test tail" is the "}". The
return statement isn't necessarily reached, because even if the firing
condition holds, the "..." code may decide to return in some other way.
It provides only a default to cover rules which don't specify an outcome.

In general the test is more elaborate than a single "if", though not very
much.

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

@ This is almost the up-down reflection of the head, but note that it begins
with the default outcome return (see above).

=
void RTRules::compile_test_tail(id_body *idb, rule *R) {
	inter_name *identifier = CompileImperativeDefn::iname(idb);
	id_runtime_context_data *phrcd = &(idb->runtime_context_data);
	rulebook *rb = RuleFamily::get_rulebook(idb->head_of_defn);
	if (rb) RTRules::compile_default_outcome(Rulebooks::get_outcomes(rb));
	if (Wordings::nonempty(phrcd->activity_context))
		@<Compile an activity or explicit condition test tail@>;
	if (PluginCalls::compile_test_tail(idb, R) == FALSE) {
		if (ActionRules::get_ap(phrcd)) @<Compile an action test tail@>;
	}
}

@h Scene test.

@<Compile a scene test head@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		RTScenes::emit_during_clause(Scenes::get_rcd_spec(phrcd));
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
		RTActionPatterns::emit_pattern_match(ActionRules::get_ap(phrcd), TRUE);
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
			RTActionPatterns::emit_pattern_match(ActionRules::get_ap(phrcd), TRUE);
		else
			RTActionPatterns::emit_pattern_match(ActionRules::get_ap(phrcd), FALSE);
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
			RTActivities::emit_activity_list(avl);
		} else {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadWhenWhile),
				"I don't understand the 'when/while' clause",
				"which should name activities or conditions.");
			EmitCode::val_false();
		}
		EmitCode::code();
		EmitCode::down();

		IXActivities::annotate_list_for_cross_references(avl, idb);
		tests++;

@<Compile an activity or explicit condition test tail@> =
	inter_ti failure_code = 4;
	@<Compile a generic test fail@>;

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
