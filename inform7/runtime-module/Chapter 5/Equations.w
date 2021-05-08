[RTEquations::] Equations.

To compile the equations submodule for a compilation unit, which contains
_equation packages.

@ Each equation has a distinct runtime identifier, which in fact is a stub
function returning false; but because these functions are all different,
they provide values different from each other and from all other functions.

There is otherwise nothing to see. Equations are solved using inline code,
not here; see //imperative: Compile Solutions to Equations//.

=
typedef struct equation_compilation_data {
	struct inter_name *eqn_iname; /* used at run-time to identify this */
} equation_compilation_data;

equation_compilation_data RTEquations::new_compilation_data(equation *eqn) {
	equation_compilation_data ecd;
	package_request *P = Hierarchy::local_package(EQUATIONS_HAP);
	ecd.eqn_iname = Hierarchy::make_iname_in(IDENTIFIER_FN_HL, P);
	return ecd;
}

inter_name *RTEquations::identifier(equation *eqn) {
	return eqn->compilation_data.eqn_iname;
}

void RTEquations::compile(void) {
	equation *eqn;
	LOOP_OVER(eqn, equation) {
		packaging_state save = Functions::begin(RTEquations::identifier(eqn));
		EmitCode::rfalse();
		Functions::end(save);
	}
}
