[InnardsElement::] Innards Element.

To write the Innards element (In) in the index.

@ Describing the current VM.

=
void InnardsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->use_option_nodes, Synoptic::module_order);

	@<Show the virtual machine compiled for@>;
	@<Show the use options@>;

	HTML_OPEN("p");
	IndexUtilities::extra_link(OUT, 3);
	WRITE("See some technicalities for Inform maintainers only");
	HTML_CLOSE("p");
	IndexUtilities::extra_div_open(OUT, 3, 2, "e0e0e0");
	HTML_OPEN("p");
	IndexUtilities::anchor(OUT, I"CONFIG");
	@<Show the language elements used@>;
	@<Add some paste buttons for the debugging log@>;
	IndexUtilities::extra_div_close(OUT, "e0e0e0");
}

@<Show the virtual machine compiled for@> =
	IndexUtilities::anchor(OUT, I"STORYFILE");
	HTML_OPEN("p"); WRITE("Story file format: ");
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/basics");
	text_stream *VM = Metadata::read_optional_textual(pack, I"^virtual_machine");
	text_stream *VM_icon = Metadata::read_optional_textual(pack, I"^virtual_machine_icon");
	if (Str::len(VM_icon) > 0) {
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/%S", VM_icon);
		WRITE("&nbsp;");
	}
	if (Str::len(VM) > 0) WRITE("%S", VM);
	HTML_CLOSE("p");

@<Show the use options@> =
	HTML_OPEN("p"); WRITE("The following use options are in force:"); HTML_CLOSE("p");
	InnardsElement::index_options_in_force_from(OUT, inv, MAIN_TEXT_UO_ORIGIN, NULL);
	InnardsElement::index_options_in_force_from(OUT, inv, OPTIONS_FILE_UO_ORIGIN, NULL);
	for (int i=0; i<TreeLists::len(inv->module_nodes); i++) {
		inter_package *E = Inter::Package::defined_by_frame(inv->module_nodes->list[i].node);
		InnardsElement::index_options_in_force_from(OUT, inv, EXTENSION_UO_ORIGIN, E);
	}
	int c = 0;
	HTML_OPEN("p"); WRITE("Whereas these are not in force:"); HTML_CLOSE("p");
	HTML::open_indented_p(OUT, 2, "tight");
	for (int i=0; i<TreeLists::len(inv->use_option_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->use_option_nodes->list[i].node);
		inter_ti set = Metadata::read_numeric(pack, I"^active");
		inter_ti sfs = Metadata::read_numeric(pack, I"^source_file_scoped");
		if ((set == FALSE) && (sfs == FALSE)) {
			@<Write in the index line for a use option not taken@>;
			if (c++ > 0) WRITE(", ");
		}
	}
	if (c == 0) WRITE("None."); /* in practice, this will never happen */
	HTML_CLOSE("p");

@<Write in the index line for a use option not taken@> =
	HTML_OPEN_WITH("span", "style=\"white-space:nowrap\";");
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, "Use %S.", Metadata::read_textual(pack, I"^name"));
	PasteButtons::paste_text(OUT, TEMP);
	DISCARD_TEXT(TEMP)
	WRITE("&nbsp;%S", Metadata::read_textual(pack, I"^name"));
	HTML_CLOSE("span");

@<Show the language elements used@> =
	WRITE("Inform language definition:\n");
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/basics");
	text_stream *used = Metadata::read_optional_textual(pack, I"^language_elements_used");
	text_stream *not_used = Metadata::read_optional_textual(pack, I"^language_elements_not_used");
	if (Str::len(used) > 0) WRITE("Included: %S", used);
	if (Str::len(not_used) > 0) WRITE("<br>Excluded: %S", not_used);
	HTML_CLOSE("p");

@<Add some paste buttons for the debugging log@> =
	HTML_OPEN("p");
	WRITE("Debugging log:");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/basics");
	inter_package *aspect_pack;
	LOOP_THROUGH_SUBPACKAGES(aspect_pack, pack, I"_debugging_aspect") {	
		TEMPORARY_TEXT(is)
		WRITE_TO(is, "Include %S in the debugging log.",
			Metadata::read_textual(aspect_pack, I"^name"));
		PasteButtons::paste_text(OUT, is);
		WRITE("&nbsp;%S&nbsp;", is);
		DISCARD_TEXT(is)
		if (Metadata::read_optional_numeric(aspect_pack, I"^used")) {
			HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/tick.png");
		} else {
			HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/cross.png");
		}
		HTML_TAG("br");
	}
	HTML_CLOSE("p");

@ Now for indexing, where there's nothing much to see.

@d MAIN_TEXT_UO_ORIGIN 1
@d OPTIONS_FILE_UO_ORIGIN 2
@d EXTENSION_UO_ORIGIN 3

=
void InnardsElement::index_options_in_force_from(OUTPUT_STREAM, tree_inventory *inv, int category, inter_package *E) {
	int N = 0;
	for (int i=0; i<TreeLists::len(inv->use_option_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->use_option_nodes->list[i].node);
		inter_ti set = Metadata::read_numeric(pack, I"^active");
		inter_ti sfs = Metadata::read_numeric(pack, I"^source_file_scoped");
		if ((set) && (sfs == FALSE)) {
			if (InnardsElement::uo_set_from(pack, category, E)) {
				if (N++ == 0) @<Write in the use option subheading@>;
				@<Write in the index line for a use option taken@>;
			}
		}
	}
}

@ And this is what the rest of Inform calls to find out whether a particular
pragma is set:

=
int InnardsElement::uo_set_from(inter_package *pack, int category, inter_package *E) {
	switch (category) {
		case MAIN_TEXT_UO_ORIGIN: if (Metadata::read_optional_numeric(pack, I"^used_in_source_text")) return TRUE; break;
		case OPTIONS_FILE_UO_ORIGIN: if (Metadata::read_optional_numeric(pack, I"^used_in_options")) return TRUE; break;
		case EXTENSION_UO_ORIGIN: {
			inter_symbol *id = Metadata::read_optional_symbol(pack, I"^used_in_extension");
			if (id) {
				inter_package *used_in_E = Inter::Packages::container(id->definition);
				if ((used_in_E) && (used_in_E == E)) return TRUE;
			}
			break;
		}
	}
	return FALSE;
}

@<Write in the use option subheading@> =
	HTML::open_indented_p(OUT, 2, "tight");
	HTML::begin_colour(OUT, I"808080");
	WRITE("Set from ");
	switch (category) {
		case MAIN_TEXT_UO_ORIGIN:
			WRITE("the source text"); break;
		case OPTIONS_FILE_UO_ORIGIN:
			WRITE("the Options.txt configuration file, or automatically");
			IndexUtilities::DocReferences::link(OUT, I"OPTIONSFILE"); break;
		case EXTENSION_UO_ORIGIN:
			WRITE("%S", Metadata::read_optional_textual(E, I"^credit"));
			break;
	}
	WRITE(":");
	HTML::end_colour(OUT);
	HTML_CLOSE("p");

@<Write in the index line for a use option taken@> =
	HTML::open_indented_p(OUT, 3, "tight");
	WRITE("Use %S", Metadata::read_optional_textual(pack, I"^name"));
	int msv = (int) Metadata::read_optional_numeric(pack, I"^minimum");
	if (msv > 0) WRITE(" of at least %d", msv);
	int at = (int) Metadata::read_optional_numeric(pack, I"^used_at");
	if (at > 0) IndexUtilities::link(OUT, at);
	if (msv > 0) {
		WRITE("&nbsp;");
		TEMPORARY_TEXT(TEMP)
		WRITE_TO(TEMP, "Use %S of at least %d.",
			Metadata::read_optional_textual(pack, I"^name"), 2*msv);
		PasteButtons::paste_text(OUT, TEMP);
		DISCARD_TEXT(TEMP)
		WRITE("&nbsp;<i>Double this</i>");
	}
	HTML_CLOSE("p");
