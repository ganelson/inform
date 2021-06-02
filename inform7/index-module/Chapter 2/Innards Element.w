[IXInnards::] Innards Element.

To index tables.

@h Describing the current VM.

=
void IXInnards::render(OUTPUT_STREAM, target_vm *VM) {
	IXInnards::index_VM(OUT, VM);
	NewUseOptions::index(OUT);
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
