[RTUseOptions::] Use Options at Run Time.

To give certain use options a presence at run-time.

@ A relatively late addition to the design of use options was to make them
values at run-time, of the kind "use option". We need to provide two routines:
one to test them, one to print them.

=
void RTUseOptions::TestUseOption_routine(void) {
	inter_name *iname = Hierarchy::find(NO_USE_OPTIONS_HL);
	Emit::numeric_constant(iname, (inter_ti) NUMBER_CREATED(use_option));
	@<Compile the TestUseOption routine@>;
	@<Compile the PrintUseOption routine@>;
}

@<Compile the TestUseOption routine@> =
	packaging_state save = Functions::begin(Hierarchy::find(TESTUSEOPTION_HL));
	inter_symbol *UO_s = LocalVariables::new_other_as_symbol(I"UO");
	use_option *uo;
	LOOP_OVER(uo, use_option)
		if ((uo->option_used) || (uo->minimum_setting_value >= 0)) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, UO_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
						(inter_ti) uo->allocation_id);
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::rtrue(Emit::tree());
				Emit::up();
			Emit::up();
		}
	Produce::rfalse(Emit::tree());
	Functions::end(save);

@<Compile the PrintUseOption routine@> =
	inter_name *iname = Kinds::Behaviour::get_iname(K_use_option);
	packaging_state save = Functions::begin(iname);
	inter_symbol *UO_s = LocalVariables::new_other_as_symbol(I"UO");
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Emit::down();
		Produce::val_symbol(Emit::tree(), K_value, UO_s);
		Produce::code(Emit::tree());
		Emit::down();
			use_option *uo;
			LOOP_OVER(uo, use_option) {
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Emit::down();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
						(inter_ti) uo->allocation_id);
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), PRINT_BIP);
						Emit::down();
							TEMPORARY_TEXT(N)
							WRITE_TO(N, "%W option", uo->name);
							if (uo->minimum_setting_value > 0)
								WRITE_TO(N, " [%d]", uo->minimum_setting_value);
							Produce::val_text(Emit::tree(), N);
							DISCARD_TEXT(N)
						Emit::up();
					Emit::up();
				Emit::up();
			}
		Emit::up();
	Emit::up();
	Functions::end(save);

@ And we also compile constants. The aim of all of this is to enable Inter
kits for the model world to operate without conditional compilation, which
would make them harder to precompile.

=
void RTUseOptions::configure_template(void) {
	int bitmap = 0;
	if (global_compilation_settings.scoring_option_set == TRUE) bitmap += 1;
	if (global_compilation_settings.undo_prevention) bitmap += 2;
	if (global_compilation_settings.serial_comma) bitmap += 4;
	if (global_compilation_settings.predictable_randomisation) bitmap += 16;
	if (global_compilation_settings.command_line_echoing) bitmap += 32;
	if (global_compilation_settings.no_verb_verb_exists) bitmap += 64;
	if (global_compilation_settings.American_dialect) bitmap += 128;
	if (global_compilation_settings.story_author_given) bitmap += 256;
	if (global_compilation_settings.ranking_table_given) bitmap += 512;

	inter_name *iname = Hierarchy::find(TEMPLATE_CONFIGURATION_BITMAP_HL);
	Emit::numeric_constant(iname, (inter_ti) bitmap);
	Hierarchy::make_available(Emit::tree(), iname);

	iname = Hierarchy::find(TEMPLATE_CONFIGURATION_LOOKMODE_HL);
	Emit::numeric_constant(iname, (inter_ti) global_compilation_settings.room_description_level);
	Hierarchy::make_available(Emit::tree(), iname);
}

@ Most use options take effect by causing a constant to be defined:

=
void RTUseOptions::compile(void) {
	use_option *uo;
	LOOP_OVER(uo, use_option)
		if ((uo->option_used) || (uo->minimum_setting_value >= 0)) {
			text_stream *UO = Str::new();
			WRITE_TO(UO, "%W", Wordings::from(uo->expansion,
				Wordings::first_wn(uo->expansion) + 1));
			text_stream *S = Str::new();
			for (int i=0; i<Str::len(UO); i++) {
				if ((Str::get_at(UO, i) == '{') && (Str::get_at(UO, i+1) == 'N') &&
					(Str::get_at(UO, i+2) == '}')) {
					WRITE_TO(S, "%d", uo->minimum_setting_value);
					i += 2;
				} else {
					PUT_TO(S, Str::get_at(UO, i));
				}
			}
			Emit::intervention(EARLY_LINK_STAGE, NULL, NULL, S, NULL);
		}
}

@ I6 memory settings need to be issued as ICL commands at the top of the I6
source code: see the DM4 for details.

=
void RTUseOptions::compile_pragmas(void) {
	Emit::pragma(I"-s");
	i6_memory_setting *ms;
	LOOP_OVER(ms, i6_memory_setting) {
		if ((Str::eq_wide_string(ms->ICL_identifier, L"MAX_LOCAL_VARIABLES")) &&
			(TargetVMs::allow_MAX_LOCAL_VARIABLES(Task::vm()) == FALSE))
			continue;
		TEMPORARY_TEXT(prag)
		WRITE_TO(prag, "$%S=%d", ms->ICL_identifier, ms->number);
		Emit::pragma(prag);
		DISCARD_TEXT(prag)
	}
}
