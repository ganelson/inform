[InnardsElement::] Innards Element.

To write the Innards element (In) in the index.

@ This element is something of a miscellany, except that it's all about the
technical implementation rather than the content of a work.

=
void InnardsElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	inter_tree *I = Indexing::get_tree(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	InterNodeList::array_sort(inv->use_option_nodes, MakeSynopticModuleStage::module_order);

	@<Show the virtual machine compiled for@>;
	@<Show the use options@>;

	HTML_OPEN("p");
	IndexUtilities::extra_link(OUT, 3);
	Localisation::roman(OUT, LD, I"Index.Elements.In.Technicalities");
	HTML_CLOSE("p");
	IndexUtilities::extra_div_open(OUT, 3, 2, I"indexmorebox");
	HTML_OPEN("p");
	IndexUtilities::anchor(OUT, I"CONFIG");
	HTML_CLOSE("p");
	@<Show the language elements used@>;
	@<Add some paste buttons for the debugging log@>;
	IndexUtilities::extra_div_close(OUT, I"indexmorebox");
}

@<Show the virtual machine compiled for@> =
	IndexUtilities::anchor(OUT, I"STORYFILE");
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.In.Format");
	WRITE(": ");
	inter_package *pack = InterPackage::from_URL(I, I"/main/completion/basics");
	text_stream *VM = Metadata::optional_textual(pack, I"^virtual_machine");
	text_stream *VM_icon = Metadata::optional_textual(pack, I"^virtual_machine_icon");
	if (Str::len(VM_icon) > 0) {
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/%S", VM_icon);
		WRITE("&nbsp;");
	}
	if (Str::len(VM) > 0) WRITE("%S", VM);
	HTML_CLOSE("p");

@<Show the use options@> =
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.In.ActiveUseOptions");
	WRITE(":");
	HTML_CLOSE("p");
	InnardsElement::index_options_in_force_from(OUT, inv, MAIN_TEXT_UO_ORIGIN, NULL, LD);
	InnardsElement::index_options_in_force_from(OUT, inv, OPTIONS_FILE_UO_ORIGIN, NULL, LD);
	inter_package *E;
	LOOP_OVER_INVENTORY_PACKAGES(E, i, inv->module_nodes)
		InnardsElement::index_options_in_force_from(OUT, inv, EXTENSION_UO_ORIGIN, E, LD);
	int c = 0;
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.In.InactiveUseOptions");
	WRITE(":");
	HTML_CLOSE("p");
	HTML::open_indented_p(OUT, 2, "tight");
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->use_option_nodes) {
		inter_ti set = Metadata::read_numeric(pack, I"^active");
		inter_ti sfs = Metadata::read_numeric(pack, I"^source_file_scoped");
		if ((set == FALSE) && (sfs == FALSE)) {
			@<Write in the index line for a use option not taken@>;
			if (c++ > 0) WRITE(", ");
		}
	}
	if (c == 0) Localisation::roman(OUT, LD, I"Index.Elements.In.NoUseOptions");
	HTML_CLOSE("p");

@<Write in the index line for a use option not taken@> =
	HTML_OPEN_WITH("span", "style=\"white-space:nowrap\";");
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, "Use %S.", Metadata::required_textual(pack, I"^name"));
	PasteButtons::paste_text(OUT, TEMP);
	DISCARD_TEXT(TEMP)
	WRITE("&nbsp;%S", Metadata::required_textual(pack, I"^name"));
	HTML_CLOSE("span");

@<Show the language elements used@> =
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.In.LanguageDefinition");
	WRITE(":");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	inter_package *pack = InterPackage::from_URL(I, I"/main/completion/basics");
	text_stream *used = Metadata::optional_textual(pack, I"^language_elements_used");
	text_stream *not_used = Metadata::optional_textual(pack, I"^language_elements_not_used");
	if (Str::len(used) > 0) 
		Localisation::roman_t(OUT, LD, I"Index.Elements.In.Included", used);
	if ((Str::len(used) > 0) && (Str::len(not_used) > 0)) WRITE("<br>");
	if (Str::len(not_used) > 0)
		Localisation::roman_t(OUT, LD, I"Index.Elements.In.Excluded", not_used);
	HTML_CLOSE("p");

@<Add some paste buttons for the debugging log@> =
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.In.Log");
	WRITE(":");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	inter_package *pack = InterPackage::from_URL(I, I"/main/completion/basics");
	inter_package *aspect_pack;
	LOOP_THROUGH_SUBPACKAGES(aspect_pack, pack, I"_debugging_aspect") {	
		TEMPORARY_TEXT(is)
		WRITE_TO(is, "Include %S in the debugging log.",
			Metadata::required_textual(aspect_pack, I"^name"));
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

@ Use options can be set in three general ways, and the following function
answers the question "was this option set in this way?". |E| is meaningless
except for |EXTENSION_UO_ORIGIN|, when we are testing whether it was set in |E|.

@d MAIN_TEXT_UO_ORIGIN 1
@d OPTIONS_FILE_UO_ORIGIN 2
@d EXTENSION_UO_ORIGIN 3

=
int InnardsElement::uo_set_from(inter_package *pack, int way, inter_package *E) {
	switch (way) {
		case MAIN_TEXT_UO_ORIGIN:
			if (Metadata::read_optional_numeric(pack, I"^used_in_source_text")) return TRUE;
			break;
		case OPTIONS_FILE_UO_ORIGIN:
			if (Metadata::read_optional_numeric(pack, I"^used_in_options")) return TRUE;
			break;
		case EXTENSION_UO_ORIGIN: {
			inter_symbol *id = Metadata::optional_symbol(pack, I"^used_in_extension");
			if (id) {
				inter_package *used_in_E = InterPackage::container(id->definition);
				if ((used_in_E) && (used_in_E == E)) return TRUE;
			}
			break;
		}
	}
	return FALSE;
}

@ Here we list the UOs set in a particular way, using the same calling conventions.

=
void InnardsElement::index_options_in_force_from(OUTPUT_STREAM, tree_inventory *inv,
	int way, inter_package *E, localisation_dictionary *LD) {
	int N = 0;
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->use_option_nodes) {
		inter_ti set = Metadata::read_numeric(pack, I"^active");
		inter_ti sfs = Metadata::read_numeric(pack, I"^source_file_scoped");
		if ((set) && (sfs == FALSE)) {
			if (InnardsElement::uo_set_from(pack, way, E)) {
				if (N++ == 0) @<Write in the use option subheading@>;
				@<Write in the index line for a use option taken@>;
			}
		}
	}
}

@<Write in the use option subheading@> =
	HTML::open_indented_p(OUT, 2, "tight");
	HTML::begin_span(OUT, I"indexgrey");
	switch (way) {
		case MAIN_TEXT_UO_ORIGIN:
			Localisation::roman(OUT, LD, I"Index.Elements.In.SetFromSource");
			break;
		case OPTIONS_FILE_UO_ORIGIN:
			Localisation::roman(OUT, LD, I"Index.Elements.In.SetAutomatically");
			break;
		case EXTENSION_UO_ORIGIN:
			Localisation::roman_t(OUT, LD, I"Index.Elements.In.SetFrom",
				Metadata::optional_textual(E, I"^credit"));
			break;
	}
	WRITE(":");
	HTML::end_span(OUT);
	HTML_CLOSE("p");

@<Write in the index line for a use option taken@> =
	HTML::open_indented_p(OUT, 3, "tight");
	WRITE("Use %S", Metadata::optional_textual(pack, I"^name"));
	int msv = (int) Metadata::read_optional_numeric(pack, I"^minimum");
	if (msv > 0) WRITE(" of at least %d", msv);
	int at = (int) Metadata::read_optional_numeric(pack, I"^used_at");
	if (at > 0) IndexUtilities::link(OUT, at);
	if (msv > 0) {
		WRITE("&nbsp;");
		TEMPORARY_TEXT(TEMP)
		WRITE_TO(TEMP, "Use %S of at least %d.",
			Metadata::optional_textual(pack, I"^name"), 2*msv);
		PasteButtons::paste_text(OUT, TEMP);
		DISCARD_TEXT(TEMP)
		WRITE("&nbsp;");
		Localisation::italic(OUT, LD, I"Index.Elements.In.Double");
	}
	HTML_CLOSE("p");
