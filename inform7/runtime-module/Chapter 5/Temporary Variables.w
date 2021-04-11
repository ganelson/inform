[RTTemporaryVariables::] Temporary Variables.

When the run-time code needs to borrow a global variable for a while.

@

=
nonlocal_variable *i6_glob_VAR = NULL;
nonlocal_variable *i6_nothing_VAR = NULL; /* the I6 |nothing| constant */
nonlocal_variable *command_prompt_VAR = NULL; /* the command prompt text */
nonlocal_variable *parameter_object_VAR = NULL;

nonlocal_variable *RTTemporaryVariables::nothing_pseudo_variable(void) {
	return i6_nothing_VAR;
}
nonlocal_variable *RTTemporaryVariables::command_prompt_variable(void) {
	return command_prompt_VAR;
}

@ These are variable names which Inform provides special support for; it
recognises the English names when they are defined by the Standard Rules. (So
there is no need to translate this to other languages.) The first two are
hacky constructs which only the SR should ever refer to.

=
<notable-variables> ::=
	i6-varying-global |
	i6-nothing-constant |
	command prompt |
	parameter-object

@ =
void RTTemporaryVariables::new_variable_notify(nonlocal_variable *nlv, wording W) {
	if (<notable-variables>(W)) {
		switch (<<r>>) {
			case 0: i6_glob_VAR = nlv; break;
			case 1: i6_nothing_VAR = nlv; break;
			case 2: command_prompt_VAR = nlv; break;
			case 3: parameter_object_VAR = nlv; break;
		}
	}
}

nonlocal_variable *RTTemporaryVariables::from_iname(inter_name *temp_iname, kind *K) {
	RTVariables::set_I6_identifier(i6_glob_VAR, FALSE, RTVariables::nve_from_iname(temp_iname));
	RTVariables::set_I6_identifier(i6_glob_VAR, TRUE, RTVariables::nve_from_iname(temp_iname));
	NonlocalVariables::set_kind(i6_glob_VAR, K);
	return i6_glob_VAR;
}

nonlocal_variable *RTTemporaryVariables::from_nve(nonlocal_variable_emission nve, kind *K) {
	RTVariables::set_I6_identifier(i6_glob_VAR, FALSE, nve);
	RTVariables::set_I6_identifier(i6_glob_VAR, TRUE, nve);
	NonlocalVariables::set_kind(i6_glob_VAR, K);
	return i6_glob_VAR;
}

nonlocal_variable *RTTemporaryVariables::from_existing_variable(nonlocal_variable *existing, kind *K) {
	return RTTemporaryVariables::from_nve(existing->compilation_data.rvalue_nve, K);
}

int formal_par_vars_made = FALSE;
nonlocal_variable *formal_par_VAR[8];
nonlocal_variable *RTTemporaryVariables::formal_parameter(int i) {
	if (formal_par_vars_made == FALSE) {
		for (int i=0; i<8; i++) {
			formal_par_VAR[i] = NonlocalVariables::new(EMPTY_WORDING, K_object, NULL);
			inter_name *iname = RTTemporaryVariables::iname_of_formal_parameter(i);
			formal_par_VAR[i]->compilation_data.nlv_iname = iname;
			RTVariables::set_I6_identifier(formal_par_VAR[i], FALSE,
				RTVariables::nve_from_iname(iname));
			RTVariables::set_I6_identifier(formal_par_VAR[i], TRUE,
				RTVariables::nve_from_iname(iname));
		}
		formal_par_vars_made = TRUE;
	}
	nonlocal_variable *nlv = formal_par_VAR[i];
	return nlv;
}

inter_name *RTTemporaryVariables::iname_of_formal_parameter(int n) {
	switch (n) {
		case 0: return Hierarchy::find(formal_par0_HL);
		case 1: return Hierarchy::find(formal_par1_HL);
		case 2: return Hierarchy::find(formal_par2_HL);
		case 3: return Hierarchy::find(formal_par3_HL);
		case 4: return Hierarchy::find(formal_par4_HL);
		case 5: return Hierarchy::find(formal_par5_HL);
		case 6: return Hierarchy::find(formal_par6_HL);
		case 7: return Hierarchy::find(formal_par7_HL);
	}
	internal_error("bad formal par number");
	return NULL;
}

