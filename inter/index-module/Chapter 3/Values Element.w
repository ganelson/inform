[ValuesElement::] Values Element.

To write the Values element (Vl) in the index.

@ Variables and equations both appear here, though really they're conceptually
quite different.

=
void ValuesElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->variable_nodes, Synoptic::module_order);
	@<Index the variables@>;
	TreeLists::sort(inv->equation_nodes, Synoptic::module_order);
	@<Index the equations@>;
}

@<Index the variables@> =
	inter_symbol *definition_area = NULL, *current_area = NULL;
	HTML_OPEN("p");
	IndexUtilities::anchor(OUT, I"NAMES");
	int understood_note_given = FALSE;
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->variable_nodes)
		if (Metadata::read_optional_numeric(pack, I"^indexable")) {
			if (Metadata::read_optional_numeric(pack, I"^understood"))
				@<Index a K understood variable@>
			else
				@<Index a regular variable@>;
		}
	HTML_CLOSE("p");

@<Index a K understood variable@> =
	if (understood_note_given == FALSE) {
		understood_note_given = TRUE;
		Localisation::write_0(OUT, LD, I"Index.Elements.Vl.UnderstoodVariables");
		HTML_TAG("br");
	}

@<Index a regular variable@> =
	definition_area = Metadata::read_optional_symbol(pack, I"^heading");
	if (definition_area == NULL) continue;
	if (definition_area != current_area) {
		inter_package *heading_pack =
			Inter::Packages::container(definition_area->definition);
		HTML_CLOSE("p");
		HTML_OPEN("p");
		IndexUtilities::show_definition_area(OUT, heading_pack, FALSE);
	}
	current_area = definition_area;

	text_stream *name = Metadata::read_optional_textual(pack, I"^name");
	WRITE("%S", name);
	IndexUtilities::link_package(OUT, pack);
	IndexUtilities::link_to_documentation(OUT, pack);
	text_stream *contents = Metadata::read_optional_textual(pack, I"^contents");
	WRITE(" - <i>%S</i>", contents);
	HTML_TAG("br");

@<Index the equations@> =
	HTML_OPEN("p");
	Localisation::bold_0(OUT, LD, I"Index.Elements.Vl.EquationsHeading");
	WRITE(" (");
	Localisation::italic_0(OUT, LD, I"Index.Elements.Vl.AboutEquations");
	WRITE(")");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	int N = 0;
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->equation_nodes) {
		int at = (int) Metadata::read_optional_numeric(pack, I"^at");
		if (at > 0) {
			WRITE("%S", Metadata::read_optional_textual(pack, I"^name"));
			IndexUtilities::link(OUT, at);
			WRITE(" (%S)", Metadata::read_optional_textual(pack, I"^text"));
			HTML_TAG("br");
			N++;
		}
	}
	if (N == 0) Localisation::italic_0(OUT, LD, I"Index.Elements.Vl.NoEquations");
	HTML_CLOSE("p");
