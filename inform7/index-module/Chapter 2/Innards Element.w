[IXInnards::] Innards Element.

To index tables.

@h Describing the current VM.

=
void IXInnards::render(OUTPUT_STREAM, target_vm *VM) {
	IXInnards::index_VM(OUT, VM);
	IXInnards::index_use_options(OUT);
	HTML_OPEN("p");
	Index::extra_link(OUT, 3);
	WRITE("See some technicalities for Inform maintainers only");
	HTML_CLOSE("p");
	Index::extra_div_open(OUT, 3, 2, "e0e0e0");
	IXInnards::show_configuration(OUT);
	@<Add some paste buttons for the debugging log@>;
	Index::extra_div_close(OUT, "e0e0e0");
}

@ The index provides some hidden paste icons for these:

@<Add some paste buttons for the debugging log@> =
	HTML_OPEN("p");
	WRITE("Debugging log:");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	for (int i=0; i<NO_DEFINED_DA_VALUES; i++) {
		debugging_aspect *da = &(the_debugging_aspects[i]);
		if (Str::len(da->unhyphenated_name) > 0) {
			TEMPORARY_TEXT(is)
			WRITE_TO(is, "Include %S in the debugging log.", da->unhyphenated_name);
			PasteButtons::paste_text(OUT, is);
			WRITE("&nbsp;%S", is);
			DISCARD_TEXT(is)
			HTML_TAG("br");
		}
	}
	HTML_CLOSE("p");

@ =
void IXInnards::index_VM(OUTPUT_STREAM, target_vm *VM) {
	if (VM == NULL) internal_error("target VM not set yet");
	Index::anchor(OUT, I"STORYFILE");
	HTML_OPEN("p"); WRITE("Story file format: ");
	ExtensionIndex::plot_icon(OUT, VM);
	TargetVMs::write(OUT, VM);
	HTML_CLOSE("p");
}

@ =
void IXInnards::show_configuration(OUTPUT_STREAM) {
	HTML_OPEN("p");
	Index::anchor(OUT, I"CONFIG");
	WRITE("Inform language definition:\n");
	PluginManager::list_plugins(OUT, "Included", TRUE);
	PluginManager::list_plugins(OUT, "Excluded", FALSE);
	HTML_CLOSE("p");
}

@ Now for indexing, where there's nothing much to see.

@d MAIN_TEXT_UO_ORIGIN 1
@d OPTIONS_FILE_UO_ORIGIN 2
@d EXTENSION_UO_ORIGIN 3

=
void IXInnards::index_use_options(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("The following use options are in force:"); HTML_CLOSE("p");
	IXInnards::index_options_in_force_from(OUT, MAIN_TEXT_UO_ORIGIN, NULL);
	IXInnards::index_options_in_force_from(OUT, OPTIONS_FILE_UO_ORIGIN, NULL);
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		IXInnards::index_options_in_force_from(OUT, EXTENSION_UO_ORIGIN, E);
	int nt = 0;
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if ((uo->option_used == FALSE) && (uo->minimum_setting_value < 0)) nt++;
	}
	if (nt > 0) {
		HTML_OPEN("p"); WRITE("Whereas these are not in force:"); HTML_CLOSE("p");
		HTML::open_indented_p(OUT, 2, "tight");
		LOOP_OVER(uo, use_option) {
			if (uo->source_file_scoped) continue;
			if ((uo->option_used == FALSE) && (uo->minimum_setting_value < 0)) {
				@<Write in the index line for a use option not taken@>;
				if (--nt > 0) WRITE(", ");
			}
		}
		HTML_CLOSE("p");
	}
}

@<Write in the index line for a use option not taken@> =
	HTML_OPEN_WITH("span", "style=\"white-space:nowrap\";");
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, "Use %+W.", uo->name);
	PasteButtons::paste_text(OUT, TEMP);
	DISCARD_TEXT(TEMP)
	WRITE("&nbsp;%+W", uo->name);
	HTML_CLOSE("span");

@ =
void IXInnards::index_options_in_force_from(OUTPUT_STREAM, int category, inform_extension *E) {
	int N = 0;
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if ((uo->option_used) && (uo->minimum_setting_value < 0) &&
			(NewUseOptions::uo_set_from(uo, category, E))) {
			if (N++ == 0) @<Write in the use option subheading@>;
			@<Write in the index line for a use option taken@>;
		}
	}
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if (((uo->option_used) && (uo->minimum_setting_value >= 0)) &&
			(NewUseOptions::uo_set_from(uo, category, E))) {
			if (N++ == 0) @<Write in the use option subheading@>;
			@<Write in the index line for a use option taken@>;
		}
	}
}

@<Write in the use option subheading@> =
	HTML::open_indented_p(OUT, 2, "tight");
	HTML::begin_colour(OUT, I"808080");
	WRITE("Set from ");
	switch (category) {
		case MAIN_TEXT_UO_ORIGIN:
			WRITE("the source text"); break;
		case OPTIONS_FILE_UO_ORIGIN:
			WRITE("the Options.txt configuration file");
			Index::DocReferences::link(OUT, I"OPTIONSFILE"); break;
		case EXTENSION_UO_ORIGIN:
			if (Extensions::is_standard(E)) WRITE("the ");
			else WRITE("the extension ");
			WRITE("%S", E->as_copy->edition->work->title);
			break;
	}
	WRITE(":");
	HTML::end_colour(OUT);
	HTML_CLOSE("p");

@<Write in the index line for a use option taken@> =
	HTML::open_indented_p(OUT, 3, "tight");
	WRITE("Use %+W", uo->name);
	if (uo->minimum_setting_value >= 0) WRITE(" of at least %d", uo->minimum_setting_value);
	if (uo->where_used) Index::link(OUT, Wordings::first_wn(Node::get_text(uo->where_used)));
	if (uo->minimum_setting_value >= 0) {
		WRITE("&nbsp;");
		TEMPORARY_TEXT(TEMP)
		WRITE_TO(TEMP, "Use %+W of at least %d.", uo->name, 2*(uo->minimum_setting_value));
		PasteButtons::paste_text(OUT, TEMP);
		DISCARD_TEXT(TEMP)
		WRITE("&nbsp;<i>Double this</i>");
	}
	HTML_CLOSE("p");
