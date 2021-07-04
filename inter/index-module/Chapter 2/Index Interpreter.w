[InterpretIndex::] Index Interpreter.

The index layout is read in from a file.

@

=
inter_tree *indexing_tree = NULL;

void InterpretIndex::set_tree(inter_tree *I) {
	indexing_tree = I;
}

inter_tree *InterpretIndex::get_tree(void) {
	if (indexing_tree == NULL) internal_error("no indexing tree");
	return indexing_tree;
}

@

=
typedef struct index_generation_state {
	struct localisation_dictionary *dict;
	struct linked_list *pages; /* of |text_stream| */
} index_generation_state;

void InterpretIndex::generate(inter_tree *I, text_stream *structure, localisation_dictionary *D) {
	filename *index_structure = InstalledFiles::index_structure_file(structure);
	InterpretIndex::set_tree(I);
	index_generation_state igs;
	igs.pages = NEW_LINKED_LIST(text_stream);
	igs.dict = D;
	TextFiles::read(index_structure, FALSE, "unable to read index structure file", TRUE,
		&InterpretIndex::read_structure, NULL, (void *) &igs);
	text_stream *k;
	LOOP_OVER_LINKED_LIST(k, text_stream, igs.pages) {
		TEMPORARY_TEXT(leafname)
		WRITE_TO(leafname, "%S.html", k);
		text_stream *OUT = InterpretIndex::open_file(leafname, Localisation::read(D, k, I"Title"), -1, D);
		Elements::periodic_table(OUT, InterpretIndex::current(), leafname, D);
		InterpretIndex::close_index_file(OUT);
		DISCARD_TEXT(leafname)
	}
	GroupedElement::detail_pages(D);
	InterpretIndex::set_tree(NULL);
}

void InterpretIndex::generate_one_element(OUTPUT_STREAM, inter_tree *I, wording elt,
	localisation_dictionary *D) {
	InterpretIndex::set_tree(I);
	Elements::test_card(OUT, elt, D);
	InterpretIndex::set_tree(NULL);
}

void InterpretIndex::read_structure(text_stream *text, text_file_position *tfp, void *state) {
	index_generation_state *igs = (index_generation_state *) state;
	localisation_dictionary *D = igs->dict;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L"page (%C+) (%C+)")) {
		text_stream *col = mr.exp[1];
		text_stream *key = mr.exp[0];
		text_stream *heading = Localisation::read(D, key, I"Title");
		text_stream *explanation = Localisation::read(D, key, I"Caption");
		InterpretIndex::new_page(col, heading, explanation, key);
		ADD_TO_LINKED_LIST(Str::duplicate(key), text_stream, igs->pages);
	} else if (Regexp::match(&mr, text, L"element (%C+)")) {
		text_stream *elt = mr.exp[0];
		InterpretIndex::new_segment(elt,
			Localisation::read(D, elt, I"Title"),
			Localisation::read(D, elt, I"Heading"));
	} else if (Regexp::match(&mr, text, L"contents (%C+) (%C+)")) {
		text_stream *col = mr.exp[1];
		text_stream *key = mr.exp[0];
		text_stream *heading = Localisation::read(D, key, I"Title");
		text_stream *explanation = Localisation::read(D, key, I"Caption");
		InterpretIndex::new_page(col, heading, explanation, key);
		ADD_TO_LINKED_LIST(Str::duplicate(key), text_stream, igs->pages);
	}
	Regexp::dispose_of(&mr);
}

@ If only we had an index file, we could look it up under "index file"...

The Index of a project is a set of HTML files describing its milieu: the
definitions it makes, the world model resulting, and the rules in force,
which arise as a combination of the source text and the extensions.

Each index page is divided into "elements".

=
typedef struct index_page {
	int no_elements;
	struct text_stream *key_colour;
	struct text_stream *page_title;
	struct text_stream *page_explanation;
	struct text_stream *page_leafname;
	CLASS_DEFINITION
} index_page;

@ =
typedef struct index_element {
	int atomic_number; /* 1, 2, 3, ..., within its page */
	struct text_stream *chemical_symbol;
	struct text_stream *element_name;
	struct text_stream *explanatory_note;
	struct index_page *owning_page;
	CLASS_DEFINITION
} index_element;

@ 

=
index_page *current_index_page = NULL;

index_page *InterpretIndex::current(void) {
	return current_index_page;
}

void InterpretIndex::new_page(text_stream *col, text_stream *title, text_stream *exp, text_stream *leaf) {
	current_index_page = CREATE(index_page);
	current_index_page->no_elements = 0;
	current_index_page->key_colour = Str::duplicate(col);
	current_index_page->page_title = Str::duplicate(title);
	current_index_page->page_explanation = Str::duplicate(exp);
	current_index_page->page_leafname = Str::duplicate(leaf);
}

void InterpretIndex::new_segment(text_stream *abb, text_stream *title, text_stream *explanation) {
	if (current_index_page == NULL)
		internal_error("template creates index elements improperly");
	if (Str::len(abb) > 2)
		internal_error("abbreviation for index element too long");
	index_element *ie = CREATE(index_element);
	ie->owning_page = current_index_page;
	ie->atomic_number = ++(current_index_page->no_elements);
	ie->chemical_symbol = Str::duplicate(abb);
	ie->element_name = Str::duplicate(title);
	ie->explanatory_note = Str::duplicate(explanation);
}

int index_file_counter = 0;
text_stream index_file_struct; /* The current index file being written */
text_stream *InterpretIndex::open_file(text_stream *index_leaf, text_stream *title, int sub,
	localisation_dictionary *D) {
	filename *F = IndexLocations::filename(index_leaf, sub);
	if (STREAM_OPEN_TO_FILE(&index_file_struct, F, UTF8_ENC) == FALSE) {
		#ifdef CORE_MODULE
		Problems::fatal_on_file("Can't open index file", F);
		#endif
		#ifndef CORE_MODULE
		Errors::fatal_with_file("can't open index file", F);
		#endif
	}
	text_stream *OUT = &index_file_struct;
	@<Set the current index page@>;

	HTML::header(OUT, title,
		InstalledFiles::filename(CSS_FOR_STANDARD_PAGES_IRES),
		InstalledFiles::filename(JAVASCRIPT_FOR_STANDARD_PAGES_IRES));
	index_file_counter++;
	return OUT;
}

@<Set the current index page@> =
	index_page *ip;
	LOOP_OVER(ip, index_page)
		if (ip->allocation_id == index_file_counter) {
			current_index_page = ip; break;
		}

@

=
void InterpretIndex::close_index_file(text_stream *ifl) {
	if (ifl) {
		HTML::footer(ifl);
		STREAM_CLOSE(ifl);
	}
}

@ This is abstracted as a routine because it's also used for the much smaller
and simpler navigation on the Actions detail pages.

=
void InterpretIndex::index_banner_line(OUTPUT_STREAM, int N, text_stream *sym, text_stream *name, text_stream *exp, char *link) {
	HTML_OPEN_WITH("table", "cellspacing=\"3\" border=\"0\" style=\"background:#eeeeee;\"");
	HTML_OPEN("tr");
	@<Write the banner mini-element-box@>;
	@<Write the row titling element@>;
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	WRITE("\n");
}

@<Write the banner mini-element-box@> =
	HTML_OPEN_WITH("td", "valign=\"top\" align=\"left\"");
	HTML_OPEN_WITH("div", "id=\"minibox%d_%d\" class=\"smallbox\"",
		current_index_page->allocation_id+1, N);
	TEMPORARY_TEXT(dets)
	WRITE_TO(dets, "class=\"symbol\" title=\"%S\" ", name);
	if (link) WRITE_TO(dets, "href=\"%s\"", link);
	else WRITE_TO(dets, "href=\"#\" onclick=\"click_element_box('segment%d'); return false;\"", N);
	HTML_OPEN_WITH("a", "%S", dets);
	DISCARD_TEXT(dets)
	WRITE("%S", sym);
	HTML_CLOSE("a");
	HTML_OPEN_WITH("div", "class=\"indexno\"");
	WRITE("%d\n", N);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	HTML_CLOSE("td");

@<Write the row titling element@> =
	HTML_OPEN_WITH("td", "style=\"width:100%%;\" align=\"left\" valign=\"top\"");
	HTML_OPEN_WITH("p", "style=\"margin-top:0px;padding-top:0px;"
		"margin-bottom:0px;padding-bottom:0px;line-height:150%%;\"");
	WRITE("<b>%S</b> &mdash; \n", name);
	Index::explain(OUT, exp);
	HTML_CLOSE("p");
	HTML_CLOSE("td");
