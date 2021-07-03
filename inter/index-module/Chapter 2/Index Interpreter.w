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
	InterpretIndex::complete(D); 
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
		text_stream *k;
		LOOP_OVER_LINKED_LIST(k, text_stream, igs->pages) {
			TEMPORARY_TEXT(leafname)
			WRITE_TO(leafname, "%S.html", k);
			InterpretIndex::open_file(leafname, Localisation::read(D, k, I"Title"), -1, D);
			DISCARD_TEXT(leafname)
		}
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

@ The index is written at the end of each successful compilation. During
indexing, only one index file is ever open for output at a time: this
always has the file handle |ifl|. The following routine is called to open a
new index file for output.

=
index_page *current_index_page = NULL;

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
text_stream *ifl = NULL; /* Current destination of index text */
text_stream index_file_struct; /* The current index file being written */
text_stream *InterpretIndex::open_file(text_stream *index_leaf, text_stream *title, int sub,
	localisation_dictionary *D) {
	filename *F = IndexLocations::filename(index_leaf, sub);
	if (ifl) InterpretIndex::close_index_file();
	if (STREAM_OPEN_TO_FILE(&index_file_struct, F, UTF8_ENC) == FALSE) {
		#ifdef CORE_MODULE
		Problems::fatal_on_file("Can't open index file", F);
		#endif
		#ifndef CORE_MODULE
		Errors::fatal_with_file("can't open index file", F);
		#endif
	}
	ifl = &index_file_struct;
	text_stream *OUT = ifl;
	@<Set the current index page@>;

	HTML::header(OUT, title,
		InstalledFiles::filename(CSS_FOR_STANDARD_PAGES_IRES),
		InstalledFiles::filename(JAVASCRIPT_FOR_STANDARD_PAGES_IRES));
	index_file_counter++;
	if (Str::get_first_char(title) == '<') {
		InterpretIndex::index_banner_line(OUT, 1, I"^", I"Details",
			I"A single action in detail.|About the action rulebooks<ARSUMMARY>",
			"../Actions.html");
		HTML_TAG("hr");
	} else InterpretIndex::periodic_table(OUT, index_leaf);
	if ((Str::get_first_char(title) != '<') && (Str::eq_wide_string(index_leaf, L"Welcome.html") == FALSE))
		@<Write the index elements@>;
	return OUT;
}

@<Set the current index page@> =
	index_page *ip;
	LOOP_OVER(ip, index_page)
		if (ip->allocation_id == index_file_counter) {
			current_index_page = ip; break;
		}

@h Writing the periodic table.
Each index page is arranged as follows: at the top is a navigational bar
in a DIV called "periodictable", and underneath that are chunks of actual
indexing material in DIVs called "element1", "element2", ... Different
pages have different numbers of elements.

The periodic table is shown complete on the Welcome page, but otherwise
is reduced to just the relevant row (orbital?).

We will call the table opened if the surround is fully visible, in which
case the actual content is hidden but the 8 rows of the table are all
visible; and closed if the surround is hidden, so that only 1 row of the
table is visible, and some or all of the content of the page is visible below.

Each row, except the top one, begins with a rectangle called the sidebar.
If the table is closed then clicking on the sidebar opens it; if it's open,
clicking on the sidebar for a given row closes the table and goes to the
relevant page of the index. The contents of the sidebar cell are defined
by a DIV whose class is "sidebar".

The sidebar is followed by a series of cells called the "boxes", one for
each element in that row's index page. These contain DIVs with the class
"box" and the ID "boxN_M", where N is the row number, 1 to 7, and M is
the column number, 1 to E, where E is the number of elements in that row.
Each box then contains three pieces of text: an abbreviation like Kd,
in a DIV with class "symbol"; a spelled-out name like Kinds, in a DIV
with class "rubric"; and an element number like 3, in a DIV with class
"indexno".

Following that is a broad cell, spanning the rest of the table's width,
which contains text like "Kinds Index". This contains a DIV of class
"headingbox", inside which is a main heading in a DIV of class "headingtext"
and text underneath in another of class "headingrubric".

@ So let's generate all of that:

=
void InterpretIndex::periodic_table(OUTPUT_STREAM, text_stream *index_leaf) {
	int max_elements = 0;
	index_page *ip;
	LOOP_OVER(ip, index_page)
		if (max_elements < ip->no_elements)
			max_elements = ip->no_elements;

	HTML_OPEN_WITH("div", "id=\"periodictable\"");
	HTML_OPEN_WITH("table", "cellspacing=\"3\" border=\"0\" width=\"100%%\"");
	if (Str::eq_wide_string(index_leaf, L"Welcome.html"))
		@<Write the heading row of the surround@>;
	LOOP_OVER(ip, index_page)
		if (((Str::eq_wide_string(index_leaf, L"Welcome.html")) || (ip == current_index_page)) &&
			(Str::eq_wide_string(ip->page_leafname, L"Welcome") == FALSE)) {
			@<Start a row of the periodic table@>;
			index_element *ie;
			LOOP_OVER(ie, index_element)
				if (ie->owning_page == ip)
					@<Write an element-box of the periodic table@>;
			@<End a row of the periodic table@>;
		}
	HTML_CLOSE("table");
	HTML_CLOSE("div");
}

@<Write the heading row of the surround@> =
	HTML_OPEN_WITH("tr", "id=\"surround0\"");
	HTML_OPEN("td");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "colspan=\"2\"");
	HTML_TAG_WITH("img", "src='inform:/doc_images/index@2x.png' border=1 width=115 height=115");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "colspan=\"%d\" style=\"width:100%%;\"", max_elements - 1);
	HTML_OPEN_WITH("div", "class=\"headingboxhigh\"");
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	WRITE("Welcome to the Index");
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	WRITE("A guide which grows with your project");
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");

@<Start a row of the periodic table@> =
	if (Str::eq_wide_string(index_leaf, L"Welcome.html")) {
		HTML_OPEN("tr");
		HTML_OPEN_WITH("td", "onclick=\"window.location='%S.html'; return false;\"",
			ip->page_leafname);
		HTML_OPEN_WITH("div", "class=\"sidebar\"");
		HTML_CLOSE("div");
		HTML_CLOSE("td");
	} else {
		HTML_OPEN_WITH("tr", "id=\"surround%d\"", ip->allocation_id+1);
		HTML_OPEN_WITH("td", "onclick=\"window.location='Welcome.html'; return false;\"");
		HTML_OPEN_WITH("div", "class=\"sidebar\"");
		HTML_CLOSE("div");
		HTML_CLOSE("td");
	}

@<Write an element-box of the periodic table@> =
	if (ip == current_index_page) {
		HTML_OPEN_WITH("td", "onclick=\"click_element_box('segment%d'); return false;\"",
			ie->atomic_number);
	} else {
		HTML_OPEN_WITH("td", "onclick=\"window.location='%S.html?segment%d'; return false;\"",
			ip->page_leafname, ie->atomic_number);
	}
	HTML_OPEN_WITH("div", "id=\"box%d_%d\" class=\"box\"", ip->allocation_id+1, ie->atomic_number);
	HTML_OPEN_WITH("a", "class=\"symbol\" title=\"%S\" href=\"#\"", ie->element_name);
	WRITE("%S", ie->chemical_symbol);
	HTML_CLOSE("a"); WRITE("\n");
	HTML_OPEN_WITH("div", "class=\"indexno\"");
	WRITE("%d", ie->atomic_number);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"rubric\"");
	WRITE("%S", ie->element_name);
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	HTML_CLOSE("td");

@<End a row of the periodic table@> =
	TEMPORARY_TEXT(tds)
	if (ip == current_index_page) {
		WRITE_TO(tds, "onclick=\"show_all_elements(); return false;\" ");
	} else {
		WRITE_TO(tds, "onclick=\"window.location='%S.html'; return false;\" ",
			ip->page_leafname);
	}
	if (ip->no_elements < max_elements)
		WRITE_TO(tds, "colspan=\"%d\" ", max_elements - ip->no_elements + 1);
	WRITE_TO(tds, "style=\"width:100%%\"");
	HTML_OPEN_WITH("td", "%S", tds);
	DISCARD_TEXT(tds)
	WRITE("\n");

	HTML_OPEN_WITH("div", "class=\"headingbox\"");
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	WRITE("%S", ip->page_title);
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	WRITE("%S", ip->page_explanation);
	HTML_CLOSE("div");
	HTML_CLOSE("div");

	HTML_CLOSE("td");
	HTML_CLOSE("tr");

@h Writing the elements.
Each element is contained inside a DIV with id "segment1", "segment2", and
so on. There's then a banner line -- a sort of subheading; then the index
content at last; and then a rule.

@<Write the index elements@> =
	index_element *ie;
	LOOP_OVER(ie, index_element)
		if (ie->owning_page == current_index_page) {
			HTML_OPEN_WITH("div", "id=\"segment%d\"", ie->atomic_number);
			HTML_TAG("hr");
			InterpretIndex::index_banner_line(OUT, ie->atomic_number, ie->chemical_symbol,
				ie->element_name, ie->explanatory_note, NULL);
			index_page *save_ip = current_index_page;
			Elements::render(OUT, ie->chemical_symbol, D);
			current_index_page = save_ip;
			HTML_CLOSE("div");
		}
	HTML_TAG("hr");

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

@ Written index files are closed either when the next one is opened (see
above), or when the |.i6t| interpreter signals the end of indexing by
calling |InterpretIndex::complete| below.

=
void InterpretIndex::complete(localisation_dictionary *D) {
	if (ifl) InterpretIndex::close_index_file();
	GroupedElement::detail_pages(D);
}

void InterpretIndex::close_index_file(void) {
	if (ifl == NULL) return;
	HTML::footer(ifl);
	STREAM_CLOSE(ifl); ifl = NULL;
}
