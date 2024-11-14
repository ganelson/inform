[TemporaryVariables::] Temporary Variables.

When the runtime code needs to borrow a global variable for a while.

@ The "temporary global" is made available to runtime code for short periods
of time, and can hold any value (i.e., are not constrained to have any fixed
kind over the lifetime of the run). To obtain it, call one of these functions,
where |K| is the kind it will have for the next little while:

=
nonlocal_variable *TemporaryVariables::from_iname(inter_name *temp_iname, kind *K) {
	nonlocal_variable *temp = NonlocalVariables::temporary_global_variable();
	RTVariables::store_in_this_iname(temp, temp_iname);
	NonlocalVariables::set_kind(temp, K);
	return temp;
}

nonlocal_variable *TemporaryVariables::from_existing_variable(nonlocal_variable *existing, kind *K) {
	nonlocal_variable *temp = NonlocalVariables::temporary_global_variable();
	RTVariables::set_NVE_from_existing(temp, existing);
	NonlocalVariables::set_kind(temp, K);
	return temp;
}

nonlocal_variable *TemporaryVariables::from_nve(nonlocal_variable_emission nve, kind *K) {
	nonlocal_variable *temp = NonlocalVariables::temporary_global_variable();
	RTVariables::set_NVE(temp, nve);
	NonlocalVariables::set_kind(temp, K);
	return temp;
}

@ A set of up to 8 globals are also available to store "formal parameters",
again for short periods of time:

=
int formal_par_vars_made = FALSE;
nonlocal_variable *formal_par_VAR[8];
int formal_par_base = 0;
int TemporaryVariables::claim_formal_parameters(int how_many) {
	formal_par_base += how_many;
	if (formal_par_base + how_many > 8) internal_error("overflow on formal parameters");
	return formal_par_base + how_many;
}
void TemporaryVariables::release_formal_parameters(int how_many) {
	formal_par_base -= how_many;
	if (formal_par_base < 0) internal_error("underflow on formal parameters");
}
nonlocal_variable *TemporaryVariables::formal_parameter(int i) {
	i += formal_par_base;
	if (i >= 8) internal_error("too many formal parameter variables");
	if (formal_par_vars_made == FALSE) {
		for (int j=0; j<8; j++) {
			formal_par_VAR[j] = NonlocalVariables::new(EMPTY_WORDING, K_object, NULL);
			RTVariables::set_hierarchy_location(formal_par_VAR[j], 
				TemporaryVariables::hl_of_formal_parameter(j));
		}
		formal_par_vars_made = TRUE;
	}
	nonlocal_variable *nlv = formal_par_VAR[i];
	return nlv;
}

inter_name *TemporaryVariables::iname_of_formal_parameter(int n) {
	n += formal_par_base;
	return Hierarchy::find(TemporaryVariables::hl_of_formal_parameter(n));
}

int TemporaryVariables::hl_of_formal_parameter(int n) {
	switch (n) {
		case 0: return formal_par0_HL;
		case 1: return formal_par1_HL;
		case 2: return formal_par2_HL;
		case 3: return formal_par3_HL;
		case 4: return formal_par4_HL;
		case 5: return formal_par5_HL;
		case 6: return formal_par6_HL;
		case 7: return formal_par7_HL;
	}
	internal_error("bad formal par number");
	return -1;
}
