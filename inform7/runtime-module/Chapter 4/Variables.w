[RTVariables::] Variables.

To compile run-time support for nonlocal variables.

@

=
typedef struct variable_compilation_data {
	struct inter_name *nlv_iname;
	int nlv_name_translated; /* has this been given storage as an I6 variable? */
	struct nonlocal_variable_emission rvalue_nve;
	struct nonlocal_variable_emission lvalue_nve;
	struct text_stream *nlv_write_schema; /* or |NULL| to assign to the L-value form */
	int housed_in_variables_array; /* i.e. |FALSE| if stored elsewhere */
	int var_is_initialisable_anyway; /* meaningful only if |housed_in_variables_array| is |FALSE| */
} variable_compilation_data;

variable_compilation_data RTVariables::new_compilation_data(void) {
	variable_compilation_data data;
	data.nlv_iname = NULL;
	data.nlv_name_translated = FALSE;
	data.rvalue_nve = RTVariables::new_nve();
	data.lvalue_nve = RTVariables::new_nve();
	data.nlv_write_schema = NULL;
	data.housed_in_variables_array = FALSE;
	data.var_is_initialisable_anyway = FALSE;
	return data;
}

void RTVariables::make_initialisable(nonlocal_variable *nlv) {
	nlv->compilation_data.var_is_initialisable_anyway = TRUE;
}

int RTVariables::is_initialisable(nonlocal_variable *nlv) {
	if (nlv->compilation_data.housed_in_variables_array) return TRUE;
	if (nlv->compilation_data.var_is_initialisable_anyway) return TRUE;
	return FALSE;
}
		
typedef struct nonlocal_variable_emission {
	struct inter_name *iname_form;
	struct text_stream *textual_form;
	int nothing_form;
	int stv_ID;
	int stv_index;
	int allow_outside;
	int use_own_iname;
} nonlocal_variable_emission;

nonlocal_variable_emission RTVariables::new_nve(void) {
	nonlocal_variable_emission nve;
	nve.iname_form = NULL;
	nve.textual_form = Str::new();
	nve.stv_ID = -1;
	nve.stv_index = -1;
	nve.allow_outside = FALSE;
	nve.use_own_iname = FALSE;
	nve.nothing_form = FALSE;
	return nve;
}

nonlocal_variable_emission RTVariables::nve_from_nothing(void) {
	nonlocal_variable_emission nve = RTVariables::new_nve();
	WRITE_TO(nve.textual_form, "nothing");
	nve.nothing_form = TRUE;
	return nve;
}

nonlocal_variable_emission RTVariables::nve_from_iname(inter_name *iname) {
	nonlocal_variable_emission nve = RTVariables::new_nve();
	nve.iname_form = iname;
	WRITE_TO(nve.textual_form, "%n", iname);
	return nve;
}

nonlocal_variable_emission RTVariables::nve_from_mstack(int N, int index, int allow_outside) {
	nonlocal_variable_emission nve = RTVariables::new_nve();
	if (allow_outside)
		WRITE_TO(nve.textual_form, "(MStack-->MstVON(%d,%d))", N, index);
	else
		WRITE_TO(nve.textual_form, "(MStack-->MstVO(%d,%d))", N, index);
	nve.stv_ID = N;
	nve.stv_index = index;
	nve.allow_outside = allow_outside;
	return nve;
}

nonlocal_variable_emission RTVariables::nve_from_pos(void) {
	nonlocal_variable_emission nve = RTVariables::new_nve();
	nve.use_own_iname = TRUE;
	return nve;
}

void RTVariables::identifier_translates(nonlocal_variable *nlv, text_stream *name) {
	if (nlv->compilation_data.nlv_name_translated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_QuantityTranslatedAlready),
			"this variable has already been translated",
			"so there must be some duplication somewhere.");
	}
	nlv->compilation_data.nlv_name_translated = TRUE;
	if (Str::eq(name, I"nothing")) {
		RTVariables::set_I6_identifier(nlv, FALSE, RTVariables::nve_from_nothing());
		RTVariables::set_I6_identifier(nlv, TRUE, RTVariables::nve_from_nothing());
	} else {
		inter_name *as_iname = Produce::find_by_name(Emit::tree(), name);
		RTVariables::set_I6_identifier(nlv, FALSE, RTVariables::nve_from_iname(as_iname));
		RTVariables::set_I6_identifier(nlv, TRUE, RTVariables::nve_from_iname(as_iname));
	}
}

@ In general, the following allows us to set the R-value and L-value forms
of the variable's storage. An R-value is the form of the variable on the
right-hand side of an assignment, that is, when we're reading it; an L-value
is the form used when we're setting it. Often these will be the same, but
not always.

=
void RTVariables::set_I6_identifier(nonlocal_variable *nlv, int left, nonlocal_variable_emission nve) {
	if (Str::len(nve.textual_form) > 30) internal_error("name too long");
	if (nlv == NULL) internal_error("null nlv");
	if (left) nlv->compilation_data.lvalue_nve = nve; else nlv->compilation_data.rvalue_nve = nve;
	nlv->compilation_data.housed_in_variables_array = FALSE;
}

@ Later, when we actually need to know where these are being stored, we assign
run-time locations to any variable without them:

=
text_stream *RTVariables::get_identifier(nonlocal_variable *nlv) {
	if (Str::len(nlv->compilation_data.rvalue_nve.textual_form) == 0) RTVariables::allocate_storage();
	if (Str::len(nlv->compilation_data.rvalue_nve.textual_form) == 0) @<Issue a missing meaning problem@>;
	return nlv->compilation_data.rvalue_nve.textual_form;
}

@<Issue a missing meaning problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, nlv->name);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"The sentence %1 seems to need the value '%2', but that currently "
		"has no definition.");
	Problems::issue_problem_end();
	return I"self";

@ And the allocation is done here. Variables not stored anywhere else are
marked to be housed in an array, though it's really up to the code-generator
tp make that decision:

=
void RTVariables::allocate_storage(void) {
	nonlocal_variable *var;
	LOOP_OVER(var, nonlocal_variable)
		if (((Str::len(var->compilation_data.lvalue_nve.textual_form) == 0) || (Str::len(var->compilation_data.rvalue_nve.textual_form) == 0)) &&
			((var->constant_at_run_time == FALSE) || (var->var_is_bibliographic))) {
			RTVariables::set_I6_identifier(var, FALSE, RTVariables::nve_from_pos());
			RTVariables::set_I6_identifier(var, TRUE, RTVariables::nve_from_pos());
			var->compilation_data.housed_in_variables_array = TRUE;
		}
}

nonlocal_variable_emission RTVariables::stv_lvalue(stacked_variable *stv) {
	if ((stv->owner_id == ACTION_PROCESSING_RB) && (stv->offset_in_owning_frame == 0))
		return RTVariables::nve_from_iname(Hierarchy::find(ACTOR_HL));
	else
		return RTVariables::nve_from_mstack(stv->owner_id, stv->offset_in_owning_frame, FALSE);
}

nonlocal_variable_emission RTVariables::stv_rvalue(stacked_variable *stv) {
	if ((stv->owner_id == ACTION_PROCESSING_RB) && (stv->offset_in_owning_frame == 0))
		return RTVariables::nve_from_iname(Hierarchy::find(ACTOR_HL));
	else
		return RTVariables::nve_from_mstack(stv->owner_id, stv->offset_in_owning_frame, TRUE);
}

inter_name *RTVariables::iname(nonlocal_variable *nlv) {
	if (nlv->compilation_data.nlv_iname == NULL) {
		package_request *R =
			Hierarchy::package(CompilationUnits::find(nlv->nlv_created_at), VARIABLES_HAP);
		Hierarchy::markup_wording(R, VARIABLE_NAME_HMD, nlv->name);
		nlv->compilation_data.nlv_iname = Hierarchy::make_iname_with_memo(VARIABLE_HL, R, nlv->name);
	}
	return nlv->compilation_data.nlv_iname;
}

@ In extreme cases, it's even possible to set an explicit I6 schema for how
to change a variable:

=
void RTVariables::set_write_schema(nonlocal_variable *nlv, text_stream *sch) {
	nlv->compilation_data.nlv_write_schema = Str::duplicate(sch);
}

text_stream *RTVariables::get_write_schema(nonlocal_variable *nlv) {
	RTVariables::warn_about_change(nlv);
	if (nlv == NULL) return NULL;
	return nlv->compilation_data.nlv_write_schema;
}

void RTVariables::warn_about_change(nonlocal_variable *nlv) {
	#ifdef IF_MODULE
	if ((score_VAR) && (nlv == score_VAR)) {
		if ((global_compilation_settings.scoring_option_set == FALSE) ||
			(global_compilation_settings.scoring_option_set == NOT_APPLICABLE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_CantChangeScore),
				"this is a story with no scoring",
				"so it makes no sense to change the 'score' value. You can add "
				"scoring to the story by including the sentence 'Use scoring.', "
				"in which case this problem message will go away; or you can "
				"remove it with 'Use no scoring.' (Until 2011, the default was "
				"to have scoring, but now it's not to have scoring.)");
		}
	}
	#endif
}



void RTVariables::emit_lvalue(nonlocal_variable *nlv) {
	nonlocal_variable_emission *nve = &(nlv->compilation_data.lvalue_nve);
	if (nve->iname_form) {
		Produce::val_iname(Emit::tree(), K_value, nve->iname_form);
	} else if (nve->stv_ID >= 0) {
		Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MSTACK_HL));
			int ex = MSTVO_HL;
			if (nve->allow_outside) ex = MSTVON_HL;
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(ex));
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) nve->stv_ID);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) nve->stv_index);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}  else if (nve->use_own_iname) {
		Produce::val_iname(Emit::tree(), K_value, RTVariables::iname(nlv));
	} else if (nve->nothing_form) {
		Produce::val_symbol(Emit::tree(), K_value, Site::veneer_symbol(Emit::tree(), NOTHING_VSYMB));
	} else {
		internal_error("improperly formed nve");
	}
}

int RTVariables::emit_all(inference_subject_family *f, int ignored) {
	nonlocal_variable *nlv;
	LOOP_OVER(nlv, nonlocal_variable)
		if ((nlv->constant_at_run_time == FALSE) ||
			(nlv->compilation_data.housed_in_variables_array)) {

			BEGIN_COMPILATION_MODE;
			COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);

			inter_name *iname = RTVariables::iname(nlv);
			inter_ti v1 = 0, v2 = 0;

			RTVariables::seek_initial_value(iname, &v1, &v2, nlv);

			END_COMPILATION_MODE;

			text_stream *rvalue = NULL;
			if (nlv->compilation_data.housed_in_variables_array == FALSE)
				rvalue = RTVariables::get_identifier(nlv);
			Emit::variable(iname, nlv->nlv_kind, v1, v2, rvalue);
			@<Add any anomalous extras@>;
		}
	return TRUE;
}

@ Here, an inter routine is compiled which returns the current value of the
command prompt variable; see //CommandParserKit: Parser//.

@<Add any anomalous extras@> =
	if (nlv == command_prompt_VAR) {
		inter_name *iname = RTVariables::iname(nlv);
		inter_name *cpt_iname = Hierarchy::find(COMMANDPROMPTTEXT_HL);
		packaging_state save = Routines::begin(cpt_iname);
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_text, iname);
		Produce::up(Emit::tree());
		Routines::end(save);
		Hierarchy::make_available(Emit::tree(), cpt_iname);
	}

@ The following routine compiles the correct initial value for the given
variable. If it has no known initial value, it is given the initial
value for its kind where possible: note that this may not be possible
if the source text says something like

>> Thickness is a kind of value. The carpet nap is a thickness that varies.

without specifying any thicknesses: the set of legal thickness values
is empty, so the carpet nap variable cannot be created in a way
which makes its kind safe. Hence the error messages.

=
void RTVariables::emit_initial_value(nonlocal_variable *nlv) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	RTVariables::compile_initial_value_vh(&VH, nlv);
	inter_ti v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	Emit::array_generic_entry(v1, v2);
}

void RTVariables::emit_initial_value_as_val(nonlocal_variable *nlv) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	RTVariables::compile_initial_value_vh(&VH, nlv);
	Holsters::to_val_mode(Emit::tree(), &VH);
}

void RTVariables::seek_initial_value(inter_name *iname, inter_ti *v1,
	inter_ti *v2, nonlocal_variable *nlv) {
	ival_emission IE = Emit::begin_ival_emission(iname);
	RTVariables::compile_initial_value_vh(Emit::ival_holster(&IE), nlv);
	Emit::end_ival_emission(&IE, v1, v2);
}

void RTVariables::compile_initial_value_vh(value_holster *VH, nonlocal_variable *nlv) {
	parse_node *val =
		NonlocalVariables::substitute_constants(
			VariableSubjects::get_initial_value(
				nlv));
	if (Node::is(val, UNKNOWN_NT)) {
		current_sentence = nlv->nlv_created_at;
		@<Initialise with the default value of its kind@>
	} else {
		current_sentence = VariableSubjects::origin_of_initial_value(nlv);
		if (Lvalues::get_storage_form(val) == NONLOCAL_VARIABLE_NT)
			@<Issue a problem for one variable set equal to another@>
		else Specifications::Compiler::compile_constant_to_kind_vh(VH, val, nlv->nlv_kind);
	}
}

@<Initialise with the default value of its kind@> =
	if (RTKinds::compile_default_value_vh(VH, nlv->nlv_kind, nlv->name, "variable") == FALSE) {
		if (nlv->var_is_allowed_to_be_zero) {
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		} else {
			wording W = Kinds::Behaviour::get_name(nlv->nlv_kind, FALSE);
			Problems::quote_wording(1, nlv->name);
			Problems::quote_wording(2, W);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyDataType));
			Problems::issue_problem_segment(
				"I am unable to put any value into the variable '%1', because "
				"%2 is a kind of value with no actual values.");
			Problems::issue_problem_end();
		}
	}

@<Issue a problem for one variable set equal to another@> =
	nonlocal_variable *the_other = Node::get_constant_nonlocal_variable(val);
	if (the_other == NULL) internal_error(
		"Tried to compile initial value of variable as null variable");
	if (the_other == nlv) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, nlv->name);
		Problems::quote_kind(3, nlv->nlv_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_InitialiseQ2));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2', which should be %3 "
			"that varies, is to have an initial value equal to itself - "
			"this is such an odd thing to say that I think I must have "
			"misunderstood.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, nlv->name);
		Problems::quote_kind(3, nlv->nlv_kind);
		Problems::quote_wording(4, the_other->name);
		Problems::quote_kind(5, the_other->nlv_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_InitialiseQ1));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2', which should be %3 "
			"that varies, is to have an initial value equal to '%4', "
			"which in turn is %5 that varies. At the start of play, "
			"variable values have to be set equal to definite constants, "
			"so this is not allowed.");
		Problems::issue_problem_end();
	}
