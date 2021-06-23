[Index::] Index File Services.

To provide routines to help build the various HTML index files,
none of which are actually created in this section.

@

=
inter_tree *indexing_tree = NULL;

void Index::set_tree(inter_tree *I) {
	indexing_tree = I;
}

inter_tree *Index::get_tree(void) {
	return indexing_tree;
}

@ If only we had an index file, we could look it up under "index file"...

The Index of a project is a set of HTML files describing its milieu: the
definitions it makes, the world model resulting, and the rules in force,
which arise as a combination of the source text and the extensions (in
particular, the Standard Rules).

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

void Index::new_page(text_stream *col, text_stream *title, text_stream *exp, text_stream *leaf) {
	current_index_page = CREATE(index_page);
	current_index_page->no_elements = 0;
	current_index_page->key_colour = Str::duplicate(col);
	current_index_page->page_title = Str::duplicate(title);
	current_index_page->page_explanation = Str::duplicate(exp);
	current_index_page->page_leafname = Str::duplicate(leaf);
}

void Index::new_segment(text_stream *abb, text_stream *title, text_stream *explanation) {
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

@ ...

=
pathname *Index::path(void) {
	#ifdef PATH_INDEX_CALLBACK
	return PATH_INDEX_CALLBACK();
	#endif
	#ifndef PATH_INDEX_CALLBACK
	return NULL;
	#endif
}

@ An oddity in the Index folder is an XML file recording where the headings
are in the source text: this is for the benefit of the user interface
application, if it wants it, but is not linked to or used by the HTML of
the index as seen by the user.

=
filename *Index::xml_headings_file(void) {
	return Filenames::in(Index::path(), I"Headings.xml");
}

@ Within the Index is a deeper level, into the weeds as it were, called
|Details|.

=
pathname *Index::index_details_path(void) {
	pathname *P = Pathnames::down(Index::path(), I"Details");
	if (Pathnames::create_in_file_system(P)) return P;
	return NULL;
}

@ And the following routine determines the filename for a page in this
mini-website. Filenames down in the |Details| area have the form
|N_S| where |N| is an integer supplied and |S| the leafname; for instance,
|21_A.html| provides details page number 21 about actions, derived from the
leafname |A.html|.

=
filename *Index::index_filename(text_stream *leafname, int sub) {
	if (sub >= 0) {
		TEMPORARY_TEXT(full_leafname)
		WRITE_TO(full_leafname, "%d_%S", sub, leafname);
		filename *F = Filenames::in(Index::index_details_path(), full_leafname);
		DISCARD_TEXT(full_leafname)
		return F;
	} else {
		return Filenames::in(Index::path(), leafname);
	}
}

int index_file_counter = 0;
text_stream *ifl = NULL; /* Current destination of index text */
text_stream index_file_struct; /* The current index file being written */
text_stream *Index::open_file(text_stream *index_leaf, text_stream *title, int sub, text_stream *explanation) {
	filename *F = Index::index_filename(index_leaf, sub);
	if (ifl) Index::close_index_file();
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
		Index::index_banner_line(OUT, 1, I"^", I"Details",
			I"A single action in detail.|About the action rulebooks<ARSUMMARY>",
			"../Actions.html");
		HTML_TAG("hr");
	} else @<Write the periodic table@>;
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

@<Write the periodic table@> =
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
			Index::index_banner_line(OUT, ie->atomic_number, ie->chemical_symbol,
				ie->element_name, ie->explanatory_note, NULL);
			index_page *save_ip = current_index_page;
			Index::index_actual_element(OUT, ie->chemical_symbol);
			current_index_page = save_ip;
			HTML_CLOSE("div");
		}
	HTML_TAG("hr");

@ This is abstracted as a routine because it's also used for the much smaller
and simpler navigation on the Actions detail pages.

=
void Index::index_banner_line(OUTPUT_STREAM, int N, text_stream *sym, text_stream *name, text_stream *exp, char *link) {
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

@h So here goes with the CSS and Javascript.

@d ADDITIONAL_SCRIPTING_HTML_CALLBACK Index::scripting

=
void Index::scripting(OUTPUT_STREAM) {
	if (current_index_page == NULL) return;

	HTML_OPEN_WITH("style", "type=\"text/css\" media=\"screen, print\"");
	@<Write some CSS styles for all these classes@>;
	HTML_CLOSE("style");

	HTML_OPEN_WITH("script", "type=\"text/javascript\"");
	WRITE("var qq; window.onload = function() {\n");
	WRITE("    if (location.search.length > 0) {\n");
	WRITE("        qq = location.search.substring(1, location.search.length);\n");
	WRITE("        show_only_one_element(qq);\n");
	WRITE("    }\n");
	WRITE("}\n");
	@<Write Javascript code for clicking on an element box@>;
	@<Write Javascript code for clicking on the sidebar@>;

	@<Write Javascript code for showing every element on the page@>;
	@<Write Javascript code for showing only one element on the page@>;
	@<Write Javascript code for entering the periodic table display@>;

	@<Write Javascript code for showing and hiding a single element@>;
	@<Write Javascript code for lighting up or greying down an element box@>;
	HTML_CLOSE("script");
}

@<Write some CSS styles for all these classes@> =
	WRITE("p {\n");
	WRITE("font-family: \"Lucida Grande\", \"Lucida Sans Unicode\", Helvetica, Arial, Verdana, sans-serif;\n");
	WRITE("}\n");
	WRITE("\n");
	WRITE(".box a:link { text-decoration: none; }\n");
	WRITE(".box a:visited { text-decoration: none; }\n");
	WRITE(".box a:active { text-decoration: none; }\n");
	WRITE(".box a:hover { text-decoration: none; color: #444444; }\n");
	WRITE("\n");
	WRITE(".smallbox a:link { text-decoration: none; }\n");
	WRITE(".smallbox a:visited { text-decoration: none; }\n");
	WRITE(".smallbox a:active { text-decoration: none; }\n");
	WRITE(".smallbox a:hover { text-decoration: none; color: #444444; }\n");
	WRITE("\n");
	WRITE(".symbol {\n");
	WRITE("	position: absolute;\n");
	WRITE("	top: -4px;\n");
	WRITE("	left: -1px;\n");
	WRITE("	width: 100%%;\n");
	WRITE("	color: #ffffff;\n");
	WRITE("	padding: 14px 0px 14px 1px;\n");
	WRITE("	font-size: 20px;\n");
	WRITE("	font-weight: bold;\n");
	WRITE("	text-align: center;\n");
	WRITE("}\n");
	WRITE(".indexno {\n");
	WRITE("	position: absolute;\n");
	WRITE("	top: 1px;\n");
	WRITE("	left: 3px;\n");
	WRITE("	color: #ffffff;\n");
	WRITE("	font-size: 7pt;\n");
	WRITE("	text-align: left;\n");
	WRITE("}\n");
	WRITE(".rubric {\n");
	WRITE("	position: absolute;\n");
	WRITE("	top: 35px;\n");
	WRITE("	width: 100%%;\n");
	WRITE("	color: #ffffff;\n");
	WRITE("	font-size: 9px;\n");
	WRITE("	font-weight: bold;\n");
	WRITE("	text-align: center;\n");
	WRITE("}\n");
	WRITE("\n");
	WRITE(".box {\n");
	WRITE(" position: relative;\n");
	WRITE(" height: 56px;\n");
	WRITE(" width: 56px;\n");
	WRITE(" padding: 0px;\n");
	WRITE("font-family: \"Lucida Grande\", \"Lucida Sans Unicode\", Helvetica, Arial, Verdana, sans-serif;\n");
	WRITE("-webkit-font-smoothing: antialiased;\n");
	WRITE("}\n");
	WRITE(".sidebar {\n");
	WRITE(" height: 56px;\n");
	WRITE(" width: 16px;\n");
	WRITE(" background: #888;\n");
	WRITE("font-family: \"Lucida Grande\", \"Lucida Sans Unicode\", Helvetica, Arial, Verdana, sans-serif;\n");
	WRITE("-webkit-font-smoothing: antialiased;\n");
	WRITE("}\n");
	WRITE(".sidebar:hover { background: #222; }\n");
	WRITE("\n");
	WRITE(".smallbox {\n");
	WRITE(" position: relative;\n");
	WRITE(" height: 40px;\n");
	WRITE(" width: 40px;\n");
	WRITE(" padding: 0px;\n");
	WRITE("font-family: \"Lucida Grande\", \"Lucida Sans Unicode\", Helvetica, Arial, Verdana, sans-serif;\n");
	WRITE("-webkit-font-smoothing: antialiased;\n");
	WRITE("}\n");
	WRITE("\n");
	index_page *ip;
	LOOP_OVER(ip, index_page) {
		index_element *ie;
		LOOP_OVER(ie, index_element)
			if (ie->owning_page == ip) {
				WRITE("#box%d_%d {\n", ip->allocation_id+1, ie->atomic_number);
				WRITE(" background: #%S;\n", ip->key_colour);
				WRITE(" }\n");
				WRITE("#minibox%d_%d {\n", ip->allocation_id+1, ie->atomic_number);
				WRITE(" background: #%S;\n", ip->key_colour);
				WRITE(" }\n");
			}
	}
	WRITE("\n");

	WRITE("ul.leaders {\n");
	WRITE("    padding: 0;\n");
	WRITE("    margin-top: 1px;\n");
	WRITE("    margin-bottom: 0;\n");
	WRITE("    overflow-x: hidden;\n");
	WRITE("    list-style: none}\n");
	WRITE("ul.leaders li.leaded:before {\n");
	WRITE("    float: left;\n");
	WRITE("    width: 0;\n");
	WRITE("    white-space: nowrap;\n");
	WRITE("    content:\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"\n");
	WRITE("	\".  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \"}\n");
	WRITE("ul.leaders li.leaded span:first-child {\n");
	WRITE("    padding-right: 0.33em;\n");
	WRITE("    background: white}\n");
	WRITE("ul.leaders li.leaded span + span {\n");
	WRITE("    float: right;\n");
	WRITE("    padding-left: 0.33em;\n");
	WRITE("    background: white}\n");
	int i;
	for (i=1; i<10; i++) {
		WRITE("li.indent%d span:first-child {\n", i);
		WRITE("    padding-left: %dpx;\n", 25*i);
		WRITE("}\n");
	}
	WRITE("\n");
	WRITE("li.unleaded:before {\n");
	WRITE("	content: \"\";\n");
	WRITE("}\n");

@ Now we come to the Javascript. The page can be in one of three states:

(1) With the periodic table closed, and all the boxes in the one visible
row lit up, and all of the elements on the page visible;
(2) With the periodic table closed, and all the boxes grey except one
which is lit up, and just the one element it corresponds to visible;
(3) With the periodic table open, and all boxes lit up, and no elements
visible on the page below.

The page loads in state (1). Note that on a page with just one element,
states (1) and (2) are indistinguishable.

We'll structure the Javascript routines on three levels. At the top level,
we have routines called when buttons on the page are clicked:

@ This is called when the user clicks on an element box corresponding to
something on the current page. If that's hidden, we go to state (2) for the
element clicked on. If it's showing, we see which state we're in: if we're
in state (2) we go to state (1), and otherwise go to state (2). (The trick
is deciding what state we're in: we do that by counting the number of visible
elements.)

@<Write Javascript code for clicking on an element box@> =
	WRITE("function click_element_box(id) {\n");
	WRITE("    if (document.getElementById(id).style.display == 'none') {\n");
	WRITE("        show_only_one_element(id);\n");
	WRITE("    } else {\n");
	WRITE("        var x = 0;\n");
	int i;
	for (i=1; i<=current_index_page->no_elements; i++)
		WRITE("        if (document.getElementById('segment%d').style.display == '') { x++; }\n", i);
	WRITE("        if (x == 1) { show_all_elements(); }\n");
	WRITE("        else { show_only_one_element(id); }\n");
	WRITE("    }\n");
	WRITE("}\n");

@ If we're in state (1) or (2), go to state (3); if we're in state (3), go to
state (1).

@<Write Javascript code for clicking on the sidebar@> =
	WRITE("function click_sidebar() {\n");
	WRITE("    if (document.getElementById('surround0').style.display == 'none') {\n");
	WRITE("        enter_periodic_table();\n");
	WRITE("    } else {\n");
	WRITE("        show_all_elements();\n");
	WRITE("    }\n");
	WRITE("}\n");

@ At the middle level of our Javascript, we have routines which move the
page to a new state. This routine goes to state (1):

@<Write Javascript code for showing every element on the page@> =
	WRITE("function show_all_elements() {\n");
	for (int i=1; i<=current_index_page->no_elements; i++) {
		WRITE("    show_element('segment%d');\n", i);
		WRITE("    light_up('segment%d');\n", i);
	}
	WRITE("	}\n");

@ This routine goes to state (2), where the |id| is the ID of the content
element -- |segment1|, |segment2|, ...

@<Write Javascript code for showing only one element on the page@> =
	WRITE("function show_only_one_element(id) {\n");
	for (int i=1; i<=current_index_page->no_elements; i++) {
		WRITE("    hide_element('segment%d');\n", i);
		WRITE("    light_down('segment%d');\n", i);
	}
	WRITE("    show_element(id);\n");
	WRITE("    light_up(id);\n");
	WRITE("}\n");

@ This routine goes to state (3):

@<Write Javascript code for entering the periodic table display@> =
	WRITE("function enter_periodic_table() {\n");
	for (int i=1; i<=current_index_page->no_elements; i++) {
		WRITE("    hide_element('segment%d');\n", i);
		WRITE("    light_up('segment%d');\n", i);
	}
	WRITE("}\n");

@ And at the bottom level of the Javascript code we have service routines
to show, hide and colour things:

@<Write Javascript code for showing and hiding a single element@> =
	WRITE("function show_element(id) {\n");
	WRITE("    document.getElementById(id).style.display = '';\n");
	WRITE("}\n");
	WRITE("function hide_element(id) {\n");
	WRITE("    document.getElementById(id).style.display = 'none';\n");
	WRITE("}\n");

@<Write Javascript code for lighting up or greying down an element box@> =
	WRITE("function light_up(id) {\n");
	@<Write Javascript to produce the corresponding icon name@>;
	WRITE("    document.getElementById(ic).style.background = '#%S';\n",
		current_index_page->key_colour);
	WRITE("}\n");
	WRITE("function light_down(id) {\n");
	@<Write Javascript to produce the corresponding icon name@>;
	WRITE("    document.getElementById(ic).style.background = '#cccccc';\n");
	WRITE("}\n");

@<Write Javascript to produce the corresponding icon name@> =
	WRITE("    var ic = 'box%d_1';\n", current_index_page->allocation_id+1);
	for (int i=2; i<=current_index_page->no_elements; i++)
		WRITE("    if (id == 'segment%d') { ic = 'box%d_%d';}\n",
			i, current_index_page->allocation_id+1, i);

@ =
void Index::test_card(OUTPUT_STREAM, wording W) {
	TEMPORARY_TEXT(elt)
	WRITE_TO(elt, "%+W", W);
	Index::index_actual_element(OUT, elt);
	DISCARD_TEXT(elt)
}

void Index::index_actual_element(OUTPUT_STREAM, text_stream *elt) {
	if (Str::eq_wide_string(elt, L"A1")) { GroupedElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"A2")) { AlphabeticElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Ar")) { ArithmeticElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Bh")) { BehaviourElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"C"))  { ContentsElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Cd")) { CardElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Ch")) { ChartElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Cm")) { CommandsElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Ev")) { EventsElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Fi")) { FiguresElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Gz")) { GazetteerElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"In")) { InnardsElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Lx")) { LexiconElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Mp")) { IXPhysicalWorld::render(OUT, FALSE); return; }
	if (Str::eq_wide_string(elt, L"MT")) { IXPhysicalWorld::render(OUT, TRUE); return; }
	if (Str::eq_wide_string(elt, L"Ph")) { PhrasebookElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Pl")) { PlotElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Rl")) { RelationsElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"RS")) { RulesForScenesElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"St")) { StandardsElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Tb")) { TablesElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"To")) { TokensElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Vb")) { VerbsElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Vl")) { ValuesElement::render(OUT); return; }
	if (Str::eq_wide_string(elt, L"Xt")) { ExtrasElement::render(OUT); return; }

	HTML_OPEN("p"); WRITE("NO CONTENT"); HTML_CLOSE("p");
}

@ =
void Index::explain(OUTPUT_STREAM, text_stream *explanation) {
	int italics_open = FALSE;
	for (int i=0, L=Str::len(explanation); i<L; i++) {
		switch (Str::get_at(explanation, i)) {
			case '|':
				HTML_TAG("br");
				WRITE("<i>"); italics_open = TRUE; break;
			case '<': {
				TEMPORARY_TEXT(link)
				WRITE("&nbsp;");
				i++;
				while ((i<L) && (Str::get_at(explanation, i) != '>'))
					PUT_TO(link, Str::get_at(explanation, i++));
				Index::DocReferences::link(OUT, link);
				DISCARD_TEXT(link)
				break;
			}
			case '[': {
				TEMPORARY_TEXT(link)
				WRITE("&nbsp;");
				i++;
				while ((i<L) && (Str::get_at(explanation, i) != '>'))
					PUT_TO(link, Str::get_at(explanation, i++));
				Index::below_link(OUT, link);
				DISCARD_TEXT(link)
				break;
			}
			default: WRITE("%c", Str::get_at(explanation, i)); break;
		}
	}
	if (italics_open) WRITE("</i>");
}

@ Written index files are closed either when the next one is opened (see
above), or when the |.i6t| interpreter signals the end of indexing by
calling |Index::complete| below.

=
void Index::complete(void) {
	if (ifl) Index::close_index_file();
	#ifdef IF_MODULE
	GroupedElement::detail_pages();
	#endif
}

void Index::close_index_file(void) {
	if (ifl == NULL) return;
	HTML::footer(ifl);
	STREAM_CLOSE(ifl); ifl = NULL;
}

@h Links to source.
When index files need to reference source text material, they normally do
so by means of orange back-arrow icons which are linked to positions in
the source as typed by the user. But source text also comes from extensions.
We don't want to provide source links to those, because they can't easily
be opened in the Inform application (on some platforms, anyway), and
in any case, can't easily be modified (or should not be, anyway). Instead,
we produce links.

So, then, source links are omitted if the reference is to a location in the
Standard Rules; if it is to an extension other than that, the link is made
to the documentation for the extension; and otherwise we make a link to
the source text in the application.

=
void Index::link(OUTPUT_STREAM, int wn) {
	Index::link_to_location(OUT, Lexer::word_location(wn), TRUE);
}

void Index::link_location(OUTPUT_STREAM, source_location sl) {
	Index::link_to_location(OUT, sl, TRUE);
}

void Index::link_to(OUTPUT_STREAM, int wn, int nonbreaking_space) {
	Index::link_to_location(OUT, Lexer::word_location(wn), nonbreaking_space);
}

void Index::link_to_location(OUTPUT_STREAM, source_location sl, int nonbreaking_space) {
	#ifdef SUPERVISOR_MODULE
	inform_extension *E = Extensions::corresponding_to(sl.file_of_origin);
	if (E) {
		if (Extensions::is_standard(E) == FALSE) {
			if (nonbreaking_space) WRITE("&nbsp;"); else WRITE(" ");
			Works::begin_extension_link(OUT, E->as_copy->edition->work, NULL);
			HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/Revealext.png");
			Works::end_extension_link(OUT, E->as_copy->edition->work);
		}
		return;
	}
	#endif
	SourceLinks::link(OUT, sl, nonbreaking_space);
}

@h Links to detail pages.
The "Beneath" icon is used for links to details pages seen as beneath the
current index page: for instance, for the link from the Actions page to the
page about the taking action.

=
void Index::detail_link(OUTPUT_STREAM, char *stub, int sub, int down) {
	WRITE("&nbsp;");
	HTML_OPEN_WITH("a", "href=%s%d_%s.html", (down)?"Details/":"", sub, stub);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/Beneath.png");
	HTML_CLOSE("a");
}

@h "See below" links.
These are the grey magnifying glass icons. The links are done by internal
href links to anchors lower down the same HTML page. These can be identified
either by number, or by name: whichever is more convenient for the indexing
code.

=
void Index::below_link(OUTPUT_STREAM, text_stream *p) {
	WRITE("&nbsp;");
	HTML_OPEN_WITH("a", "href=#%S", p);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/Below.png");
	HTML_CLOSE("a");
}

void Index::anchor(OUTPUT_STREAM, text_stream *p) {
	HTML_OPEN_WITH("a", "name=%S", p); HTML_CLOSE("a");
}

void Index::below_link_numbered(OUTPUT_STREAM, int n) {
	WRITE("&nbsp;");
	HTML_OPEN_WITH("a", "href=#A%d", n);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/Below.png");
	HTML_CLOSE("a");
}

void Index::anchor_numbered(OUTPUT_STREAM, int n) {
	HTML_OPEN_WITH("a", "name=A%d", n); HTML_CLOSE("a");
}

@h "Show extra" links, and also a spacer of equivalent width.

=
void Index::extra_link(OUTPUT_STREAM, int id) {
	HTML_OPEN_WITH("a", "href=\"#\" onclick=\"showExtra('extra%d', 'plus%d'); return false;\"", id, id);
	HTML_TAG_WITH("img", "border=0 id=\"plus%d\" src=inform:/doc_images/extra.png", id);
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

void Index::extra_all_link_with(OUTPUT_STREAM, int nr, char *icon) {
	HTML_OPEN_WITH("a", "href=\"#\" onclick=\"showAllResp(%d); return false;\"", nr);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/%s.png", icon);
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

void Index::extra_link_with(OUTPUT_STREAM, int id, char *icon) {
	HTML_OPEN_WITH("a", "href=\"#\" onclick=\"showResp('extra%d', 'plus%d'); return false;\"", id, id);
	HTML_TAG_WITH("img", "border=0 id=\"plus%d\" src=inform:/doc_images/%s.png", id, icon);
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

void Index::noextra_link(OUTPUT_STREAM) {
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/noextra.png");
	WRITE("&nbsp;");
}

@ These open up divisions:

=
void Index::extra_div_open(OUTPUT_STREAM, int id, int indent, char *colour) {
	HTML_OPEN_WITH("div", "id=\"extra%d\" style=\"display: none;\"", id);
	HTML::open_indented_p(OUT, indent, "");
	HTML::open_coloured_box(OUT, colour, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
}

void Index::extra_div_close(OUTPUT_STREAM, char *colour) {
	HTML::close_coloured_box(OUT, colour, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
	HTML_CLOSE("p");
	HTML_CLOSE("div");
}

void Index::extra_div_open_nested(OUTPUT_STREAM, int id, int indent) {
	HTML_OPEN_WITH("div", "id=\"extra%d\" style=\"display: none;\"", id);
	HTML::open_indented_p(OUT, indent, "");
}

void Index::extra_div_close_nested(OUTPUT_STREAM) {
	HTML_CLOSE("p");
	HTML_CLOSE("div");
}

@h "Deprecation" icons.

=
void Index::deprecation_icon(OUTPUT_STREAM, int id) {
	HTML_OPEN_WITH("a", "href=\"#\" onclick=\"showExtra('extra%d', 'plus%d'); return false;\"", id, id);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/deprecated.png");
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

@h Miscellaneous utilities.
First: to print a double-quoted word into the index, without its surrounding
quotes.

=
void Index::dequote(OUTPUT_STREAM, wchar_t *p) {
	int i = 1;
	if ((p[0] == 0) || (p[1] == 0)) return;
	for (i=1; p[i+1]; i++) {
		int c = p[i];
		switch(c) {
			case '"': WRITE("&quot;"); break;
			default: PUT_TO(OUT, c); break;
		}
	}
}

@

=
void Index::show_definition_area(OUTPUT_STREAM, inter_package *heading_pack,
	int show_if_unhyphenated) {
	inter_ti parts = Metadata::read_optional_numeric(heading_pack, I"^parts");
	if ((parts == 1) && (show_if_unhyphenated == FALSE)) return;
	HTML_OPEN("b");
	switch (parts) {
		case 1: WRITE("%S", Metadata::read_optional_textual(heading_pack, I"^part1")); break;
		case 2: WRITE("%S", Metadata::read_optional_textual(heading_pack, I"^part2")); break;
		case 3: WRITE("%S - %S",
			Metadata::read_optional_textual(heading_pack, I"^part2"),
			Metadata::read_optional_textual(heading_pack, I"^part3")); break;
	}
	HTML_CLOSE("b");
	HTML_TAG("br");
}
