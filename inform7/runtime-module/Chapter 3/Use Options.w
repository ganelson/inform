[RTUseOptions::] Use Options.

To give use options a presence at run-time.

@ The following function compiles everything necessary for use options to
work at runtime:

=
typedef struct use_option_compilation_data {
	struct package_request *uo_package;
	struct inter_name *uo_value;
	int value_to_use;
	struct parse_node *value_determined_at;
} use_option_compilation_data;

use_option_compilation_data RTUseOptions::new_compilation_data(use_option *uo) {
	use_option_compilation_data uocd;
	uocd.uo_package = Hierarchy::local_package_to(USE_OPTIONS_HAP, uo->where_created);
	uocd.uo_value = Hierarchy::make_iname_in(USE_OPTION_ID_HL, uocd.uo_package);
	uocd.value_to_use = 0;
	uocd.value_determined_at = NULL;
	return uocd;
}

inter_name *RTUseOptions::uo_iname(use_option *uo) {
	return uo->compilation_data.uo_value;
}

void RTUseOptions::compile(void) {
	@<Reject inline definitions if we forbid deprecated features@>;
	@<Calculate the values of configuration constants@>;
	@<Apply Inter metadata@>;
	@<Compile pragmas from use options which set these@>;
	@<Compile configuration values supplied by the compiler itself@>;
	@<Compile configuration values supplied by use options@>;
}

@ This is only done here in the runtime module as a convenience of timing.
The potential issue is that by the time "Use no deprecated features" is read,
we have already read all the offending inline definitions.

@<Reject inline definitions if we forbid deprecated features@> =
	if (global_compilation_settings.no_deprecated_features) {
		use_option *uo;
		LOOP_OVER(uo, use_option)
			if (uo->definition_form == INLINE_UTAS) {
				current_sentence = uo->where_created;
				StandardProblems::handmade_problem(Task::syntax_tree(),
					_p_(PM_UONotationDeprecated));
				Problems::quote_source(1, current_sentence);
				Problems::issue_problem_segment(
					"In %1, you set up a use option, but you use the deprecated notation "
					"'(- ... -)' to say what to do if this option is set. Since you "
					"also have 'Use no deprecated features' set, I'm issuing a problem "
					"message. (For now, though, this would have worked if it hadn't been "
					"for 'Use no deprecated features'.)");
				Problems::issue_problem_end();
			}
	}

@<Calculate the values of configuration constants@> =
	use_option *uo;
	LOOP_OVER(uo, use_option)
		@<Calculate the value to use@>;

@<Calculate the value to use@> =
	if ((uo->definition_form == CONFIG_FLAG_UTAS) ||
		(uo->definition_form == CONFIG_FLAG_IN_UTAS) ||
		(uo->definition_form == COMPILER_UTAS)) {
		if (RTUseOptions::used(uo)) {
			uo->compilation_data.value_to_use = 1;
			parsed_use_option_setting *puos =
				FIRST_IN_LINKED_LIST(parsed_use_option_setting, uo->settings_made);
			if (puos) uo->compilation_data.value_determined_at = puos->made_at;
			else uo->compilation_data.value_determined_at = uo->default_value->made_at;
		} else {
			uo->compilation_data.value_to_use = 0;
			uo->compilation_data.value_determined_at = uo->default_value->made_at;
		}
	} else {
		int explicits = 0;
		uo->compilation_data.value_determined_at = uo->default_value->made_at;
		parsed_use_option_setting *puos, *explicit = NULL, *minimum_puos = NULL;
		int minimum = -1;
		if (uo->default_value->at_least == TRUE) {
			minimum = uo->default_value->value;
			minimum_puos = uo->default_value;
		}
		LOGIF(USE_OPTIONS, "Default for %W: ", uo->name);
		RTUseOptions::log_puos(uo->default_value);
		LOGIF(USE_OPTIONS, "\n");

		LOOP_OVER_LINKED_LIST(puos, parsed_use_option_setting, uo->settings_made) {
			LOGIF(USE_OPTIONS, "Setting: ");
			RTUseOptions::log_puos(puos);
			LOGIF(USE_OPTIONS, "\n");
			if (puos->at_least == FALSE) {
				explicits++;
				if (explicits == 1) explicit = puos;
				else if (puos->value != explicit->value) @<Issue problem for value conflict@>;
			} else if (puos->at_least == TRUE) {
				if (minimum < puos->value) { minimum = puos->value; minimum_puos = puos; }
			}
		}
		if ((explicit) && (minimum_puos)) {
			if (minimum < explicit->value) minimum = explicit->value;
			if (minimum > explicit->value) {
				current_sentence = minimum_puos->made_at;
				Problems::quote_source(1, minimum_puos->made_at);
				Problems::quote_source(2, explicit->made_at);
				Problems::quote_wording(3, minimum_puos->textual_option);
				StandardProblems::handmade_problem(Task::syntax_tree(),
					_p_(PM_UOExplicitValueTooSmall));
				Problems::issue_problem_segment(
					"In %1, you set a use option '%3', but that conflicts with the "
					"earlier setting %2.");
				Problems::issue_problem_end();
			}
		}
		if (minimum >= 0) {
			uo->compilation_data.value_to_use = minimum;
			uo->compilation_data.value_determined_at = minimum_puos->made_at;
		} else if (explicit) {
			uo->compilation_data.value_to_use = explicit->value;
			uo->compilation_data.value_determined_at = explicit->made_at;
		} else {
			uo->compilation_data.value_to_use = uo->default_value->value;
			uo->compilation_data.value_determined_at = uo->default_value->made_at;
		}
	}
	LOGIF(USE_OPTIONS, "Determined value of %W = %d\n", uo->name, uo->compilation_data.value_to_use);

@<Issue problem for value conflict@> =
	current_sentence = puos->made_at;
	Problems::quote_source(1, current_sentence);
	Problems::quote_source(2, explicit->made_at);
	Problems::quote_wording(3, puos->textual_option);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UOValueConflicts));
	Problems::issue_problem_segment(
		"In %1, you set a use option '%3', but that conflicts with the "
		"earlier setting %2.");
	Problems::issue_problem_end();

@<Apply Inter metadata@> =
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		package_request *R = uo->compilation_data.uo_package;
		inter_name *set_iname = Hierarchy::make_iname_in(USE_OPTION_ON_MD_HL, R);
		inter_ti set = 0;
		if (RTUseOptions::used(uo)) set = 1;
		Emit::numeric_constant(set_iname, set);
		Emit::numeric_constant(uo->compilation_data.uo_value, (inter_ti) 0);
		Hierarchy::apply_metadata_from_raw_wording(R, USE_OPTION_MD_HL, uo->name);
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "%W option", uo->name);
		Hierarchy::apply_metadata(R, USE_OPTION_PNAME_MD_HL, N);
		DISCARD_TEXT(N)
		Hierarchy::apply_metadata_from_number(R, SOURCE_FILE_SCOPED_MD_HL,
			(inter_ti) uo->source_file_scoped);
		if (uo->compilation_data.value_determined_at)
			Hierarchy::apply_metadata_from_number(R, USE_OPTION_USED_AT_MD_HL,
				(inter_ti) Wordings::first_wn(Node::get_text(uo->compilation_data.value_determined_at)));
		source_file *sf = (uo->compilation_data.value_determined_at)?
			(Lexer::file_of_origin(Wordings::first_wn(Node::get_text(uo->compilation_data.value_determined_at)))):NULL;
		inform_extension *efo = (sf)?(Extensions::corresponding_to(sf)):NULL;
		if ((sf) && (efo == NULL))
			Hierarchy::apply_metadata_from_number(R, USED_IN_SOURCE_TEXT_MD_HL, 1);
		else if (sf == NULL)
			Hierarchy::apply_metadata_from_number(R, USED_IN_OPTIONS_MD_HL, 1);
		else if (efo)
			Hierarchy::apply_metadata_from_iname(R, USED_IN_EXTENSION_MD_HL,
				CompilationUnits::extension_id(efo));
		Hierarchy::apply_metadata_from_number(R, USE_OPTION_CV_MD_HL,
			(inter_ti) uo->compilation_data.value_to_use);
	}

@ Some use options convert directly into pragma instructions telling the Inform 6
compiler (assuming we will be using that) to raise some limit. This is done with
ICL ("Inform Control Language") instructions: see the Inform 6 Designer's Manual
for details of these. Any other code-generator can ignore these pragmas.

@<Compile pragmas from use options which set these@> =
	target_pragma_setting *tps;
	LOOP_OVER(tps, target_pragma_setting)
		Emit::pragma(tps->target, tps->content);
	i6_memory_setting *ms;
	LOOP_OVER(ms, i6_memory_setting)
		if (TargetVMs::allow_memory_setting(Task::vm(), ms->ICL_identifier)) {
			TEMPORARY_TEXT(prag)
			WRITE_TO(prag, "$%S=%d", ms->ICL_identifier, ms->number);
			Emit::pragma(I"Inform6", prag);
			DISCARD_TEXT(prag)
		}
	if (TargetVMs::is_16_bit(Task::vm()) == FALSE) {
		TEMPORARY_TEXT(prag)
		WRITE_TO(prag, "$DICT_WORD_SIZE=%d",
			global_compilation_settings.dictionary_resolution);
		Emit::pragma(I"Inform6", prag);
		DISCARD_TEXT(prag)
	}

@ A few kit configuration values cannot be set with use options, and are
hard-wired into the compiler:

@<Compile configuration values supplied by the compiler itself@> =
	if (global_compilation_settings.no_verb_verb_exists) {
	    RTUseOptions::define_config_constant(I"WorldModelKit`NO_VERB_VERB_EXISTS", 1);
	} else {
	    RTUseOptions::define_config_constant(I"WorldModelKit`NO_VERB_VERB_EXISTS", 0);
	}	
	if (RTBibliographicData::story_author_given()) {
	    RTUseOptions::define_config_constant(I"WorldModelKit`STORY_AUTHOR_GIVEN", 1);
	} else {
	    RTUseOptions::define_config_constant(I"WorldModelKit`STORY_AUTHOR_GIVEN", 0);
	}	
	if (global_compilation_settings.ranking_table_given) {
	    RTUseOptions::define_config_constant(I"WorldModelKit`RANKING_TABLE_GIVEN", 1);
	} else {
	    RTUseOptions::define_config_constant(I"WorldModelKit`RANKING_TABLE_GIVEN", 0);
	}

@ There's a little dance here to make sure that every flag or value referred to
in a use option declaration is actually compiled (to a default value if necessary),
but once only. This can be difficult to ensure since multiple use options may
set the same value (probably, but not necessarily, differently). We use a
dictionary of the symbol names being declared to keep track.

@<Compile configuration values supplied by use options@> =
	dictionary *D = Dictionaries::new(32, FALSE);
	LOGIF(USE_OPTIONS, "Active use options (those set by explicit sentences)\n");
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		if ((RTUseOptions::used(uo)) && (uo->no_Inter_presence == FALSE)) {
			LOGIF(USE_OPTIONS, "use option '%W': ", uo->name);
			current_sentence = uo->compilation_data.value_determined_at;
			int active = TRUE;
			if (uo->definition_form == INLINE_UTAS) @<Include raw Inform 6 code@>
			else @<Define a symbol@>;
		}
	}
	LOGIF(USE_OPTIONS, "\nInactive use options (those not set by explicit sentences)\n");
	LOOP_OVER(uo, use_option) {
		if ((RTUseOptions::used(uo) == FALSE) && (uo->no_Inter_presence == FALSE)) {
			LOGIF(USE_OPTIONS, "use option '%W': ", uo->name);
			current_sentence = uo->compilation_data.value_determined_at;
			int active = FALSE;
			if (uo->definition_form == INLINE_UTAS) @<Include raw Inform 6 code@>
			else @<Define a symbol@>;
		}
	}
	LOGIF(USE_OPTIONS, "\n");
	current_sentence = NULL;
	@<Default any configuration constants needed by a kit but not addressed by use options@>;

@ The old-school way for use options to take effect is by causing a constant to
be defined using inclusion notation. That is, they are defined using Inform 6
notation inside |(-| and |-)| markers: for example,
= (text as Inform 7)
Use feverish dreams translates as (- Constant FEVERISH_DREAMS; -).
Use hallucination time of at least 1024 translates as
	(- Constant DREAMY_TIME = {N}+3; -).
=
The |{N}| marker, if present, is converted to the value, producing, say:
= (text as Inform 6)
	Constant DREAMY_TIME = 4096+3;
=
All this form of notation is deprecated now, but in the mean time we can still
read almost all such definitions, because almost all users write them in a simple
enough way that we can tell what they want and achieve it by better means.

@<Include raw Inform 6 code@> =
	text_stream *UO = Str::new();
	WRITE_TO(UO, "%W", Wordings::from(uo->expansion, Wordings::first_wn(uo->expansion) + 1));
	current_sentence = uo->where_created;
	RTUseOptions::handle_deprecated_definition(UO, active, uo->compilation_data.value_to_use);

@ The newer and better way does not involve inclusions (with their concomitant
need to inject splat nodes into the Inter we generate), but instead makes
constants which will be linked into the kit of code we are trying to configure.

@<Define a symbol@> =
	inter_ti val = (inter_ti) uo->compilation_data.value_to_use;
	if (Str::len(uo->kit_name) > 0) @<Vet the kit@>;
	text_stream *UO = Str::new();
	@<Compose the full symbol name UO@>;
	dict_entry *de = Dictionaries::find(D, UO);
	use_option *at = NULL;
	if (de) {
		at = (use_option *) Dictionaries::value_for_entry(de);
		if ((RTUseOptions::used(uo)) && (RTUseOptions::used(at)) &&
			(at->compilation_data.value_to_use != uo->compilation_data.value_to_use)) {
			@<Issue a problem for mutually exclusive options being set@>;
		} else {
			LOGIF(USE_OPTIONS, "doing nothing as %S already set to %d\n",
				UO, at->compilation_data.value_to_use);
		}
	} else {
		LOGIF(USE_OPTIONS, "defining %S = %d\n", UO, val);
		Dictionaries::create(D, UO);
		Dictionaries::write_value(D, UO, uo);
		RTUseOptions::define_config_constant(UO, val);
	}

@<Compose the full symbol name UO@> =
	if ((uo->definition_form == CONFIG_FLAG_UTAS) ||
		(uo->definition_form == CONFIG_FLAG_IN_UTAS)) {
		RTUseOptions::uo_identifier(UO, uo->kit_name, uo->symbol_name, TRUE);
	} else {
		RTUseOptions::uo_identifier(UO, uo->kit_name, uo->symbol_name, FALSE);
	}	

@<Issue a problem for mutually exclusive options being set@> =
	LOGIF(USE_OPTIONS, "would set %S = %d but it's already %d\n",
		UO, val, at->compilation_data.value_to_use);
	current_sentence = uo->compilation_data.value_determined_at;
	Problems::quote_source(1, current_sentence);
	Problems::quote_source(2, at->compilation_data.value_determined_at);
	Problems::quote_wording(3, uo->name);
	Problems::quote_wording(4, at->name);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UOsMutuallyExclusive));
	Problems::issue_problem_segment(
		"In %1, you set a use option '%3', but that conflicts with the "
		"earlier setting %2 of '%4', because these are names for two "
		"different possible values of the same parameter.");
	Problems::issue_problem_end();

@<Vet the kit@> =
	inform_project *proj = Task::project();
	inform_kit *kit = Projects::get_linked_kit(proj, uo->kit_name);
	if (kit == NULL) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UOForMissingKit));
		Problems::quote_source(1, uo->where_created);
		Problems::quote_stream(2, uo->kit_name);
		Problems::issue_problem_segment(
			"In %1, you set up a use option used to configure the kit '%2', "
			"but that kit is not part of the current project.");
		Problems::issue_problem_end();
	} else {
		int f = Kits::configuration_is_a_flag(kit, uo->symbol_name);
		if (f == NOT_APPLICABLE) {
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UONotInKit));
			Problems::quote_source(1, uo->where_created);
			Problems::quote_stream(2, uo->kit_name);
			Problems::quote_stream(3, uo->symbol_name);
			Problems::issue_problem_segment(
				"In %1, you set up a use option used to configure the kit '%2' "
				"by setting the value of '%3', but that kit (though part of the "
				"current project) has no such configuration value. These are set "
				"for a kit in its JSON metadata file.");
			Problems::issue_problem_end();
		} else if ((f == TRUE) && (val != 0) && (val != 1)) {
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UOFlagSaysKit));
			Problems::quote_source(1, uo->where_created);
			Problems::quote_stream(2, uo->kit_name);
			Problems::quote_stream(3, uo->symbol_name);
			int val_signed = (int) val;
			Problems::quote_number(4, &val_signed);
			Problems::issue_problem_segment(
				"In %1, you set up a use option used to configure the kit '%2' "
				"by setting the value of '%3', but the JSON metadata for that kit "
				"says that %3 is a flag, and here we seem to want to set it to "
				"the value %4, which is clearly not 0 or 1.");
			Problems::issue_problem_end();
		}
	}

@ Suppose `BasicInformKit` says in its metadata that it expects `SECRET_SAUCE`
to be defined, but no use option has been declared which mentions that. We don't
want linking to fail, so we declare this to be 0.

The fraudulent entries in the dictionary, which are not valid pointers, are
unimportant because the dictionary is thrown away immediately after this is done.

@<Default any configuration constants needed by a kit but not addressed by use options@> =
	linked_list *L = Projects::list_of_kit_configurations(Task::project());
	kit_configuration *kc;
	LOOP_OVER_LINKED_LIST(kc, kit_configuration, L) {
		TEMPORARY_TEXT(UO)
		RTUseOptions::uo_identifier(UO, kc->owner->as_copy->edition->work->title,
			kc->symbol_name, kc->is_flag);
		if (Dictionaries::find(D, UO) == NULL) {
			LOGIF(USE_OPTIONS, "Kit default needed: defining %S = 0\n", UO);
			use_option *hideous_fraud = (use_option *) kc;
			Dictionaries::create(D, UO);
			Dictionaries::write_value(D, UO, hideous_fraud);
			RTUseOptions::define_config_constant(UO, 0);
		}
		DISCARD_TEXT(UO)
	}

@ This composes constant identifiers:

=
void RTUseOptions::uo_identifier(OUTPUT_STREAM,
	text_stream *kit_name, text_stream *symbol_name, int flag) {
	if (Str::len(kit_name) > 0) WRITE("%S`", kit_name);
	WRITE("%S", symbol_name);
	WRITE("_CFG");
	if (flag) {
		WRITE("F");
	} else {
		WRITE("V");
	}	
}

@ Kit configuration constants are created in the |configuration| submodule
of the |completion| module in the Inter tree:

=
void RTUseOptions::define_config_constant(text_stream *UO, inter_ti val) {
	package_request *R = LargeScale::completion_submodule(Emit::tree(),
		LargeScale::register_submodule_identity(I"configuration"));
	inter_name *iname = InterNames::explicitly_named(UO, R);
	Emit::numeric_constant(iname, val);
	Hierarchy::make_available(iname);
}

@ Has the use option ever been used, as opposed to simply having its meaning
declared?

=
int RTUseOptions::used(use_option *uo) {
	if (uo == NULL) return FALSE;
	if (LinkedLists::len(uo->settings_made) > 0) return TRUE;
	return FALSE;
}

@ Logging:

=
void RTUseOptions::log_puos(parsed_use_option_setting *puos) {
	if (puos == NULL) { LOGIF(USE_OPTIONS, "<none>"); return; }
	LOGIF(USE_OPTIONS, "{%W", puos->textual_option);
	if (puos->at_least == TRUE) LOGIF(USE_OPTIONS, " >= %d", puos->value);
	if (puos->at_least == FALSE) LOGIF(USE_OPTIONS, " == %d", puos->value);
	LOGIF(USE_OPTIONS, "}");
}

@h Deprecated inclusion notation.
The old-school way for use options to take effect is by causing a constant to
be defined using inclusion notation. That is, they are defined using Inform 6
notation inside |(-| and |-)| markers: for example,
= (text as Inform 7)
Use feverish dreams translates as (- Constant FEVERISH_DREAMS; -).
Use hallucination time of at least 1024 translates as
	(- Constant DREAMY_TIME = {N}+3; -).
=
The |{N}| marker, if present, is converted to the value, producing, say:
= (text as Inform 6)
	Constant DREAMY_TIME = 4096+3;
=
All this form of notation is deprecated now, but in the mean time we can still
read almost all such definitions, because almost all users write them in a simple
enough way that we can tell what they want and achieve it by better means.

=
int RTUseOptions::check_deprecated_definition(text_stream *UO) {
	return RTUseOptions::handle_deprecated_definition(UO, FALSE, 0);
}

int  RTUseOptions::handle_deprecated_definition(text_stream *UO, int active, int N) {
	int rv = FALSE;
	inter_ti val = 0; text_stream *identifier = NULL;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, UO, L" *Constant (%C+) *; *")) {
		identifier = mr.exp[0];
	} else if (Regexp::match(&mr, UO, L" *Constant (%C+) *= *(%d+) *; *")) {
		identifier = mr.exp[0]; val = (inter_ti) Str::atoi(mr.exp[1], 0);
	} else if (Regexp::match(&mr, UO, L" *Constant (%C+) *= *{N} *; *")) {
		identifier = mr.exp[0]; val = (inter_ti) N;
	} else if (Regexp::match(&mr, UO, L" *Constant (%C+) *= *{N} *%+ *(%d+) *; *")) {
		identifier = mr.exp[0];
		val = (inter_ti) (N + Str::atoi(mr.exp[1], 0));
	} else if ((Regexp::match(&mr, UO, L" *Constant (%C+) *= *{N} *%* *(%d+) *; *")) ||
			(Regexp::match(&mr, UO, L" *Constant (%C+) *= *(%d+) *%* *{N} *; *"))) {
		identifier = mr.exp[0];
		val = (inter_ti) (N * Str::atoi(mr.exp[1], 0));
	}
	if (Str::len(identifier) > 0) @<Declare a constant, in a civilised way@>
	Regexp::dispose_of(&mr);
	return rv;
}

@<Declare a constant, in a civilised way@> =
	if (active == FALSE) LOGIF(USE_OPTIONS, "not ");
	LOGIF(USE_OPTIONS, "deducing %S = %d from (- %S -).\n", identifier, val, UO);
	if (active) RTUseOptions::define_config_constant(identifier, val);
	rv = TRUE;
