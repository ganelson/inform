[RTExtensions::] Extensions.

To compile the credits functions.

@

=
void RTExtensions::compile_synoptic_resources(void) {
	@<Provide placeholder for the SHOWEXTENSIONVERSIONS function@>;
	@<Provide placeholder for the SHOWFULLEXTENSIONVERSIONS function@>;
	@<Provide placeholder for the SHOWONEEXTENSION function@>;
}

@<Provide placeholder for the SHOWEXTENSIONVERSIONS function@> =
	inter_name *iname = Hierarchy::find(SHOWEXTENSIONVERSIONS_HL);
	Produce::annotate_i(iname, SYNOPTIC_IANN, SHOWEXTENSIONVERSIONS_SYNID);
	packaging_state save = Functions::begin(iname);
	EmitCode::comment(I"This function is consolidated");
	Functions::end(save);
	Hierarchy::make_available(iname);

@<Provide placeholder for the SHOWFULLEXTENSIONVERSIONS function@> =
	inter_name *iname = Hierarchy::find(SHOWFULLEXTENSIONVERSIONS_HL);
	Produce::annotate_i(iname, SYNOPTIC_IANN, SHOWFULLEXTENSIONVERSIONS_SYNID);
	packaging_state save = Functions::begin(iname);
	EmitCode::comment(I"This function is consolidated");
	Functions::end(save);
	Hierarchy::make_available(iname);

@<Provide placeholder for the SHOWONEEXTENSION function@> =	
	inter_name *iname = Hierarchy::find(SHOWONEEXTENSION_HL);
	Produce::annotate_i(iname, SYNOPTIC_IANN, SHOWONEEXTENSION_SYNID);
	packaging_state save = Functions::begin(iname);
	LocalVariables::new_other_as_symbol(I"id");
	EmitCode::comment(I"This function is consolidated");
	Functions::end(save);
	Hierarchy::make_available(iname);
