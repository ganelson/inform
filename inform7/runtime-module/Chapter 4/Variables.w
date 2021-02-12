[RTVariables::] Variables.

To compile run-time support for nonlocal variables.

@

=
int RTVariables::emit_all(inference_subject_family *f, int ignored) {
	nonlocal_variable *nlv;
	LOOP_OVER(nlv, nonlocal_variable)
		if ((nlv->constant_at_run_time == FALSE) ||
			(nlv->housed_in_variables_array)) {

			BEGIN_COMPILATION_MODE;
			COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);

			inter_name *iname = NonlocalVariables::iname(nlv);
			inter_ti v1 = 0, v2 = 0;

			NonlocalVariables::seek_initial_value(iname, &v1, &v2, nlv);

			END_COMPILATION_MODE;

			text_stream *rvalue = NULL;
			if (nlv->housed_in_variables_array == FALSE)
				rvalue = NonlocalVariables::identifier(nlv);
			Emit::variable(iname, nlv->nlv_kind, v1, v2, rvalue);
			@<Add any anomalous extras@>;
		}
	return TRUE;
}

@ Here, an inter routine is compiled which returns the current value of the
command prompt variable; see //CommandParserKit: Parser//.

@<Add any anomalous extras@> =
	if (nlv == command_prompt_VAR) {
		inter_name *iname = NonlocalVariables::iname(nlv);
		inter_name *cpt_iname = Hierarchy::find(COMMANDPROMPTTEXT_HL);
		packaging_state save = Routines::begin(cpt_iname);
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_text, iname);
		Produce::up(Emit::tree());
		Routines::end(save);
		Hierarchy::make_available(Emit::tree(), cpt_iname);
	}
