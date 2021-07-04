[Elements::] The Periodic Table.

The index is divided up into 'elements'.

@ Each index page is arranged as follows: at the top is a navigational bar
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
void Elements::periodic_table(OUTPUT_STREAM, index_page *current_page,
	text_stream *index_leaf, localisation_dictionary *D) {
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
		if (((Str::eq_wide_string(index_leaf, L"Welcome.html")) || (ip == current_page)) &&
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
	if (Str::eq_wide_string(index_leaf, L"Welcome.html") == FALSE)
		@<Write the index elements@>;
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
	if (ip == current_page) {
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
	if (ip == current_page) {
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
		if (ie->owning_page == current_page) {
			HTML_OPEN_WITH("div", "id=\"segment%d\"", ie->atomic_number);
			HTML_TAG("hr");
			InterpretIndex::index_banner_line(OUT, ie->atomic_number, ie->chemical_symbol,
				ie->element_name, ie->explanatory_note, NULL);
			Elements::render(OUT, ie->chemical_symbol, D);
			HTML_CLOSE("div");
		}
	HTML_TAG("hr");

@

=
void Elements::test_card(OUTPUT_STREAM, wording W, localisation_dictionary *LD) {
	TEMPORARY_TEXT(elt)
	WRITE_TO(elt, "%+W", W);
	Elements::render(OUT, elt, LD);
	DISCARD_TEXT(elt)
}

void Elements::render(OUTPUT_STREAM, text_stream *elt, localisation_dictionary *LD) {
	if (Str::eq_wide_string(elt, L"A1")) { GroupedElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"A2")) { AlphabeticElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Ar")) { ArithmeticElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Bh")) { BehaviourElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"C"))  { ContentsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Cd")) { CardElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Ch")) { ChartElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Cm")) { CommandsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Ev")) { EventsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Fi")) { FiguresElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Gz")) { GazetteerElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"In")) { InnardsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Lx")) { LexiconElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Mp")) { MapElement::render(OUT, LD, FALSE); return; }
	if (Str::eq_wide_string(elt, L"MT")) { MapElement::render(OUT, LD, TRUE); return; }
	if (Str::eq_wide_string(elt, L"Ph")) { PhrasebookElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Pl")) { PlotElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Rl")) { RelationsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"RS")) { RulesForScenesElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"St")) { StandardsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Tb")) { TablesElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"To")) { TokensElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Vb")) { VerbsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Vl")) { ValuesElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Xt")) { ExtrasElement::render(OUT, LD); return; }

	HTML_OPEN("p"); WRITE("NO CONTENT"); HTML_CLOSE("p");
}
