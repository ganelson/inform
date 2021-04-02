[RTEquations::] Equations Support.

To compile unique identifiers for equations.

@ Each equation has a distinct runtime identifier, which in fact is a stub
function returning false; but because these functions are all different,
they provide values different from each other and from all other functions.

=
void RTEquations::new_identifier(equation *eqn) {
	package_request *PR = Hierarchy::local_package(EQUATIONS_HAP);
	eqn->eqn_iname = Hierarchy::make_iname_in(SOLVE_FN_HL, PR);
}

inter_name *RTEquations::identifier(equation *eqn) {
	return eqn->eqn_iname;
}

void RTEquations::compile_identifiers(void) {
	equation *eqn;
	LOOP_OVER(eqn, equation) {
		packaging_state save = Functions::begin(eqn->eqn_iname);
		Produce::rfalse(Emit::tree());
		Functions::end(save);
	}
}
