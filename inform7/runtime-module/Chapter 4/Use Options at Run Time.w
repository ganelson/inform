[RTUseOptions::] Use Options at Run Time.

To give certain use options a presence at run-time.

@ A relatively late addition to the design of use options was to make them
values at run-time, of the kind "use option". We need to provide two routines:
one to test them, one to print them.

=
void RTUseOptions::TestUseOption_routine(void) {
	inter_name *iname = Hierarchy::find(NO_USE_OPTIONS_HL);
	Emit::named_numeric_constant(iname, (inter_ti) NUMBER_CREATED(use_option));
	@<Compile the TestUseOption routine@>;
	@<Compile the PrintUseOption routine@>;
}

@<Compile the TestUseOption routine@> =
	packaging_state save = Routines::begin(Hierarchy::find(TESTUSEOPTION_HL));
	inter_symbol *UO_s = LocalVariables::new_other_as_symbol(I"UO");
	use_option *uo;
	LOOP_OVER(uo, use_option)
		if ((uo->option_used) || (uo->minimum_setting_value >= 0)) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, UO_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
						(inter_ti) uo->allocation_id);
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	Produce::rfalse(Emit::tree());
	Routines::end(save);

@<Compile the PrintUseOption routine@> =
	inter_name *iname = Kinds::Behaviour::get_iname(K_use_option);
	packaging_state save = Routines::begin(iname);
	inter_symbol *UO_s = LocalVariables::new_other_as_symbol(I"UO");
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, UO_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			use_option *uo;
			LOOP_OVER(uo, use_option) {
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
						(inter_ti) uo->allocation_id);
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), PRINT_BIP);
						Produce::down(Emit::tree());
							TEMPORARY_TEXT(N)
							WRITE_TO(N, "%W option", uo->name);
							if (uo->minimum_setting_value > 0)
								WRITE_TO(N, " [%d]", uo->minimum_setting_value);
							Produce::val_text(Emit::tree(), N);
							DISCARD_TEXT(N)
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			}
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Routines::end(save);

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
	Emit::named_numeric_constant(iname, (inter_ti) bitmap);
	Hierarchy::make_available(Emit::tree(), iname);

	iname = Hierarchy::find(TEMPLATE_CONFIGURATION_LOOKMODE_HL);
	Emit::named_numeric_constant(iname, (inter_ti) global_compilation_settings.room_description_level);
	Hierarchy::make_available(Emit::tree(), iname);
}

@ Most use options take effect by causing a constant to be defined:

=
void RTUseOptions::compile(void) {
	use_option *uo;
	LOOP_OVER(uo, use_option)
		if ((uo->option_used) || (uo->minimum_setting_value >= 0)) {
			text_stream *UO = Str::new();
			I6T::interpret_i6t(UO,
				Lexer::word_raw_text(Wordings::first_wn(uo->expansion) + 1),
				uo->minimum_setting_value);
			WRITE_TO(UO, "\n");
			Emit::intervention(EARLY_LINK_STAGE, NULL, NULL, UO, NULL);
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
