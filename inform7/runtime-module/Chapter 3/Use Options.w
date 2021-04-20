[RTUseOptions::] Use Options.

To give use options a presence at run-time.

@ The following function compiles everything necessary for use options to
work at runtime:

=
void RTUseOptions::compile(void) {
	@<Compile NO_USE_OPTIONS@>;
	@<Compile pragmas from use options which set these@>;
	@<Compile the kit configuration@>;
	@<Make interventions to give non-pragma use options effect@>;
	@<Compile the TESTUSEOPTION function@>;
	@<Compile the printing function for the use option kind@>;
}

@<Compile NO_USE_OPTIONS@> =
	inter_name *iname = Hierarchy::find(NO_USE_OPTIONS_HL);
	Emit::numeric_constant(iname, (inter_ti) NUMBER_CREATED(use_option));

@ Some use options convert directly into pragma instructions telling the Inform 6
compiler (assuming we will be using that) to raise some limit. This is done with
ICL ("Inform Control Language") instructions: see the Inform 6 Designer's Manual
for details of these. Any other code-generator can ignore these pragmas.

Note that not every VM allows |MAX_LOCAL_VARIABLES| to be raised; if the current
one doesn't, that's not an error; it's just a pragma we suppress.

@<Compile pragmas from use options which set these@> =
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

@ Some use options in the Standard Rules, or in Basic Inform, set Inter constants
which are intended to affect the behaviour of the kits at runtime, rather than
to influence what the compiler does. However, we want to minimise the use of
conditional compilation in those kits, so we will instead turn some common
use options into a bitmap. Kits can then look at this bitmap with regular
conditional code, rather than conditionally compiling code depending on whether
or not some associated constant exists.

The bitmap here must remain small enough to fit in 16 bits, and the meaning
of these bits must not be changed here without making matching changes in the
kits.

@<Compile the kit configuration@> =
	int bitmap = 0;
	if (global_compilation_settings.scoring_option_set == TRUE) bitmap += 1;
	if (global_compilation_settings.undo_prevention)            bitmap += 2;
	if (global_compilation_settings.serial_comma)               bitmap += 4;
	if (global_compilation_settings.predictable_randomisation)  bitmap += 16;
	if (global_compilation_settings.command_line_echoing)       bitmap += 32;
	if (global_compilation_settings.no_verb_verb_exists)        bitmap += 64;
	if (global_compilation_settings.American_dialect)           bitmap += 128;
	if (RTBibliographicData::story_author_given())              bitmap += 256;
	if (global_compilation_settings.ranking_table_given)        bitmap += 512;

	inter_name *iname = Hierarchy::find(KIT_CONFIGURATION_BITMAP_HL);
	Emit::numeric_constant(iname, (inter_ti) bitmap);
	Hierarchy::make_available(iname);

	iname = Hierarchy::find(KIT_CONFIGURATION_LOOKMODE_HL);
	Emit::numeric_constant(iname,
		(inter_ti) global_compilation_settings.room_description_level);
	Hierarchy::make_available(iname);

@ Most use options take effect by causing a constant to be defined. They are
defined using Inform 6 notation inside |(-| and |-)| markers: for example,
= (text as Inform 7)
Use predictable randomisation translates as (- Constant FIX_RNG; -).
Use maximum text length of at least 1024 translates as
	(- Constant TEXT_TY_BufferSize = {N}+3; -).
=
As the second case there shows, they are not necessarily as simple as just
being "define a constant as having the value N", though perhaps they should be:
this may be a simplification to Inform worth making, because then we could
avoid the need for "intervention", that is, for injecting a piece of Inform 6
notation into the Inter tree to be assimilated at the linking stage later on.

We do at least take care of the |{N}| marker, if present, so that the intervention
made in that second case would be something like
= (text as Inform 7)
	Constant TEXT_TY_BufferSize = 4096+3;
=

@<Make interventions to give non-pragma use options effect@> =
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
			Interventions::from_use_option(S);
		}

@ A relatively late addition to the design of use options was to make them
values at runtime, of the kind "use option". We need to provide two functions:
one to test whether a given use option is currently set, one to print the
name of a given use option.

@<Compile the TESTUSEOPTION function@> =
	packaging_state save = Functions::begin(Hierarchy::find(TESTUSEOPTION_HL));
	inter_symbol *UO_s = LocalVariables::new_other_as_symbol(I"UO");
	use_option *uo;
	LOOP_OVER(uo, use_option)
		if ((uo->option_used) || (uo->minimum_setting_value >= 0)) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, UO_s);
					EmitCode::val_number((inter_ti) uo->allocation_id);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::rtrue();
				EmitCode::up();
			EmitCode::up();
		}
	EmitCode::rfalse();
	Functions::end(save);

@<Compile the printing function for the use option kind@> =
	inter_name *iname = Kinds::Behaviour::get_iname(K_use_option);
	packaging_state save = Functions::begin(iname);
	inter_symbol *UO_s = LocalVariables::new_other_as_symbol(I"UO");
	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, UO_s);
		EmitCode::code();
		EmitCode::down();
			use_option *uo;
			LOOP_OVER(uo, use_option) {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) uo->allocation_id);
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(PRINT_BIP);
						EmitCode::down();
							TEMPORARY_TEXT(N)
							WRITE_TO(N, "%W option", uo->name);
							if (uo->minimum_setting_value > 0)
								WRITE_TO(N, " [%d]", uo->minimum_setting_value);
							EmitCode::val_text(N);
							DISCARD_TEXT(N)
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			}
		EmitCode::up();
	EmitCode::up();
	Functions::end(save);
