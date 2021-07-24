[ValuesElement::] Values Element.

To write the Values element (Vl) in the index.

@ And here is the indexing code:

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
	for (int i=0; i<TreeLists::len(inv->variable_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->variable_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^indexable")) {
			if (Metadata::read_optional_numeric(pack, I"^understood"))
				@<Index a K understood variable@>
			else
				@<Index a regular variable@>;
		}
	}
	HTML_CLOSE("p");

@<Index a K understood variable@> =
	if (understood_note_given == FALSE) {
		understood_note_given = TRUE;
		WRITE("<i>kind</i> understood - <i>value</i>");
		HTML_TAG("br");
	}

@<Index a regular variable@> =
	definition_area = Metadata::read_optional_symbol(pack, I"^heading");
	if (definition_area == NULL) continue;
	if (definition_area != current_area) {
		inter_package *heading_pack = Inter::Packages::container(definition_area->definition);
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
	if (TreeLists::len(inv->equation_nodes) > 0) {
		HTML_OPEN("p"); WRITE("<b>List of Named or Numbered Equations</b> (<i>About equations</i>");
		IndexUtilities::DocReferences::link(OUT, I"EQUATIONS"); WRITE(")");
		HTML_CLOSE("p");
		HTML_OPEN("p");
		int N = 0;
		for (int i=0; i<TreeLists::len(inv->equation_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->equation_nodes->list[i].node);
			int at = (int) Metadata::read_optional_numeric(pack, I"^at");
			if (at > 0) {
				WRITE("%S", Metadata::read_optional_textual(pack, I"^name"));
				IndexUtilities::link(OUT, at);
				WRITE(" (%S)", Metadata::read_optional_textual(pack, I"^text"));
				HTML_TAG("br");
				N++;
			}
		}
		if (N == 0) WRITE("<i>None</i>.\n");
		HTML_CLOSE("p");
	}
