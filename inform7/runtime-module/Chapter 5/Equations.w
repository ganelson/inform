[RTEquations::] Equations.

To compile the equations submodule for a compilation unit, which contains
_equation packages.

@ Each equation has a distinct runtime identifier, which in fact is a stub
function returning |false|; but because these functions are all different,
they provide values different from each other and from all other functions.

There is otherwise nothing to see except metadata used in indexing. Equations
are solved using inline code, not here; see //imperative: Compile Solutions to Equations//.

=
typedef struct equation_compilation_data {
	struct parse_node *eqn_created_at;
	struct package_request *eqn_package;
	struct inter_name *eqn_iname;
} equation_compilation_data;

equation_compilation_data RTEquations::new_compilation_data(equation *eqn) {
	equation_compilation_data ecd;
	ecd.eqn_created_at = current_sentence;
	ecd.eqn_package = NULL;
	ecd.eqn_iname = NULL;
	return ecd;
}

package_request *RTEquations::package(equation *eqn) {
	if (eqn->compilation_data.eqn_package == NULL)
		eqn->compilation_data.eqn_package =
			Hierarchy::local_package_to(EQUATIONS_HAP,
				eqn->compilation_data.eqn_created_at);
	return eqn->compilation_data.eqn_package;
}

inter_name *RTEquations::identifier(equation *eqn) {
	if (eqn->compilation_data.eqn_iname == NULL)
		eqn->compilation_data.eqn_iname =
			Hierarchy::make_iname_in(IDENTIFIER_FN_HL, RTEquations::package(eqn));
	return eqn->compilation_data.eqn_iname;
}

void RTEquations::compile(void) {
	equation *eqn;
	LOOP_OVER(eqn, equation) {
		packaging_state save = Functions::begin(RTEquations::identifier(eqn));
		EmitCode::rfalse();
		Functions::end(save);
		package_request *pack = RTEquations::package(eqn);
		int mw = Wordings::last_wn(eqn->equation_no_text);
		if (Wordings::last_wn(eqn->equation_name_text) > mw)
			mw = Wordings::last_wn(eqn->equation_name_text);
		if (mw >= 0) {
			wording NW = Wordings::up_to(Node::get_text(eqn->equation_created_at), mw);
			Hierarchy::apply_metadata_from_raw_wording(pack, EQUATION_NAME_MD_HL, NW);
			Hierarchy::apply_metadata_from_number(pack, EQUATION_AT_MD_HL,
				(inter_ti) Wordings::first_wn(NW));
		}
		Hierarchy::apply_metadata_from_raw_wording(pack, EQUATION_TEXT_MD_HL,
			eqn->equation_text);
	}
}
