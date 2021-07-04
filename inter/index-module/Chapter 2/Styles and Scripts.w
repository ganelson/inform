[IndexStyles::] Styles and Scripts.

CSS and Javascripts embedded into the body of index pages.

@h So here goes with the CSS and Javascript.

@d ADDITIONAL_SCRIPTING_HTML_CALLBACK IndexStyles::incorporate

=
void IndexStyles::incorporate(OUTPUT_STREAM) {
	index_page *current_page = InterpretIndex::current();
	if (current_page == NULL) return;

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

@ At the middle level of our Javascript, we have routines which move the
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
