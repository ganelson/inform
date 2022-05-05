[IndexStyles::] Styles and Scripts.

CSS and Javascripts embedded into the body of index pages.

@ This is a questionable decision: The HTML pages of the index, which have
to live inside a project bundle and may be accessed through non-standard URL
schemes, do not use external script files. That avoids possible problems with
failing to link to said files correctly.

But it means every HTML page in the index has to embed its own CSS and
Javascript, and this is done with a callback function which allows us to insert
material into the head of an HTML page when it is opened for output. Note that
the function acts only when the page was created with |state|, which will only
happen when it was created by //index//.

@d ADDITIONAL_SCRIPTING_HTML_CALLBACK IndexStyles::incorporate

=
void IndexStyles::incorporate(OUTPUT_STREAM, void *state) {
	if (state) {
		index_page *current_page = (index_page *) state;
		if (current_page == NULL) return;
		index_session *session = current_page->for_session;
		@<Incorporate some CSS@>;
		@<Incorporate some Javascript@>;
	}
}

@ The CSS is mostly the same every time and is therefore mostly loaded from an
external file in the Inform installation; but the colour scheme depends on the
structure file loaded by the //Index Interpreter//, so that's not fixed on every
run of Inform.

@<Incorporate some CSS@> =
	HTML_OPEN_WITH("style", "type=\"text/css\" media=\"screen, print\"");
	index_page *ip;
	linked_list *L = Indexing::get_list_of_pages(session);
	LOOP_OVER_LINKED_LIST(ip, index_page, L) {
		index_element *ie;
		LOOP_OVER_LINKED_LIST(ie, index_element, ip->elements) {
			WRITE("#box%d_%d {\n", ip->allocation_id+1, ie->atomic_number);
			WRITE("    background: #%S;\n", ip->key_colour);
			WRITE("}\n");
			WRITE("#minibox%d_%d {\n", ip->allocation_id+1, ie->atomic_number);
			WRITE("    background: #%S;\n", ip->key_colour);
			WRITE("}\n");
		}
	}
	HTML_CLOSE("style");

@ Now we come to the Javascript. This varies much more from page to page, and
is generated procedurally below.

@<Incorporate some Javascript@> =
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

@ When loaded in a browser, a page can be in one of three states:

(1) With the periodic table closed, and all the boxes in the one visible
row lit up, and all of the elements on the page visible;
(2) With the periodic table closed, and all the boxes grey except one
which is lit up, and just the one element it corresponds to visible;
(3) With the periodic table open, and all boxes lit up, and no elements
visible on the page below.

The page loads in state (1). Note that on a page with just one element,
states (1) and (2) are indistinguishable.

We'll structure the Javascript functions on three levels. At the top level,
we have functions called when buttons on the page are clicked:

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
	for (i=1; i<=current_page->no_elements; i++)
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

@ At the middle level of our Javascript, we have functions which move the
page to a new state. This routine goes to state (1):

@<Write Javascript code for showing every element on the page@> =
	WRITE("function show_all_elements() {\n");
	for (int i=1; i<=current_page->no_elements; i++) {
		WRITE("    show_element('segment%d');\n", i);
		WRITE("    light_up('segment%d');\n", i);
	}
	WRITE("	}\n");

@ This routine goes to state (2), where the |id| is the ID of the content
element -- |segment1|, |segment2|, ...

@<Write Javascript code for showing only one element on the page@> =
	WRITE("function show_only_one_element(id) {\n");
	for (int i=1; i<=current_page->no_elements; i++) {
		WRITE("    hide_element('segment%d');\n", i);
		WRITE("    light_down('segment%d');\n", i);
	}
	WRITE("    show_element(id);\n");
	WRITE("    light_up(id);\n");
	WRITE("}\n");

@ This routine goes to state (3):

@<Write Javascript code for entering the periodic table display@> =
	WRITE("function enter_periodic_table() {\n");
	for (int i=1; i<=current_page->no_elements; i++) {
		WRITE("    hide_element('segment%d');\n", i);
		WRITE("    light_up('segment%d');\n", i);
	}
	WRITE("}\n");

@ And at the bottom level of the Javascript code we have service functions
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
		current_page->key_colour);
	WRITE("}\n");
	WRITE("function light_down(id) {\n");
	@<Write Javascript to produce the corresponding icon name@>;
	WRITE("    document.getElementById(ic).style.background = '#cccccc';\n");
	WRITE("}\n");

@<Write Javascript to produce the corresponding icon name@> =
	WRITE("    var ic = 'box%d_1';\n", current_page->allocation_id+1);
	for (int i=2; i<=current_page->no_elements; i++)
		WRITE("    if (id == 'segment%d') { ic = 'box%d_%d';}\n",
			i, current_page->allocation_id+1, i);
