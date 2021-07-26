[IndexUtilities::] Index Utilities.

Miscellaneous utility functions for producing index content.

@h Element banner.
This is used as the banner at the top of each index element, and also at the
top of the Actions detail pages. It's about time this table-based HTML was
replaced with styled CSS layout code, really. But it works fine.

(Anyone tempted to do this should note that the result must render correctly
on typical browser views embedded in apps on Windows, MacOS and Linux.)

=
void IndexUtilities::banner_line(OUTPUT_STREAM, index_page *page, int N, text_stream *sym,
	text_stream *name, text_stream *exp, char *link, localisation_dictionary *D) {
	HTML_OPEN_WITH("table", "cellspacing=\"3\" border=\"0\" style=\"background:#eeeeee;\"");
	HTML_OPEN("tr");
	@<Write the banner mini-element-box@>;
	@<Write the row titling element@>;
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	WRITE("\n");
}

@<Write the banner mini-element-box@> =
	int ref = (page)?(page->allocation_id+1):1;
	HTML_OPEN_WITH("td", "valign=\"top\" align=\"left\"");
	HTML_OPEN_WITH("div", "id=\"minibox%d_%d\" class=\"smallbox\"", ref, N);
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
	Localisation::roman(OUT, D, exp);
	HTML_CLOSE("p");
	HTML_CLOSE("td");

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
void IndexUtilities::link(OUTPUT_STREAM, int wn) {
	IndexUtilities::link_to_location(OUT, Lexer::word_location(wn), TRUE);
}

void IndexUtilities::link_package(OUTPUT_STREAM, inter_package *pack) {
	int at = (int) Metadata::read_optional_numeric(pack, I"^at");
	if (at > 0) IndexUtilities::link(OUT, at);
}

void IndexUtilities::link_location(OUTPUT_STREAM, source_location sl) {
	IndexUtilities::link_to_location(OUT, sl, TRUE);
}

void IndexUtilities::link_to(OUTPUT_STREAM, int wn, int nonbreaking_space) {
	IndexUtilities::link_to_location(OUT, Lexer::word_location(wn), nonbreaking_space);
}

void IndexUtilities::link_to_location(OUTPUT_STREAM, source_location sl, int nonbreaking_space) {
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

@h Links to documentation.
These produce little blue help icons which, when clicked, show the relevant
page of documentation in the Inform app. Cross-referencing is via the
system set up in //html: Documentation References//.

=
void IndexUtilities::link_to_documentation(OUTPUT_STREAM, inter_package *pack) {
	text_stream *doc = Metadata::read_optional_textual(pack, I"^documentation");
	if (Str::len(doc) > 0) DocReferences::link(OUT, doc);
}

@h Links to detail pages.
The "Beneath" icon is used for links to details pages seen as beneath the
current index page: for instance, for the link from the Actions page to the
page about the taking action.

=
void IndexUtilities::detail_link(OUTPUT_STREAM, char *stub, int sub, int down) {
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
void IndexUtilities::below_link(OUTPUT_STREAM, text_stream *p) {
	WRITE("&nbsp;");
	HTML_OPEN_WITH("a", "href=#%S", p);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/Below.png");
	HTML_CLOSE("a");
}

void IndexUtilities::anchor(OUTPUT_STREAM, text_stream *p) {
	HTML_OPEN_WITH("a", "name=%S", p); HTML_CLOSE("a");
}

void IndexUtilities::below_link_numbered(OUTPUT_STREAM, int n) {
	WRITE("&nbsp;");
	HTML_OPEN_WITH("a", "href=#A%d", n);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/Below.png");
	HTML_CLOSE("a");
}

void IndexUtilities::anchor_numbered(OUTPUT_STREAM, int n) {
	HTML_OPEN_WITH("a", "name=A%d", n); HTML_CLOSE("a");
}

@h "Show extra" links, and also a spacer of equivalent width.

=
void IndexUtilities::extra_link(OUTPUT_STREAM, int id) {
	HTML_OPEN_WITH("a",
		"href=\"#\" onclick=\"showExtra('extra%d', 'plus%d'); return false;\"", id, id);
	HTML_TAG_WITH("img", "border=0 id=\"plus%d\" src=inform:/doc_images/extra.png", id);
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

void IndexUtilities::extra_all_link_with(OUTPUT_STREAM, int nr, char *icon) {
	HTML_OPEN_WITH("a", "href=\"#\" onclick=\"showAllResp(%d); return false;\"", nr);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/%s.png", icon);
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

void IndexUtilities::extra_link_with(OUTPUT_STREAM, int id, char *icon) {
	HTML_OPEN_WITH("a",
		"href=\"#\" onclick=\"showResp('extra%d', 'plus%d'); return false;\"", id, id);
	HTML_TAG_WITH("img", "border=0 id=\"plus%d\" src=inform:/doc_images/%s.png", id, icon);
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

void IndexUtilities::noextra_link(OUTPUT_STREAM) {
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/noextra.png");
	WRITE("&nbsp;");
}

@ These open up divisions:

=
void IndexUtilities::extra_div_open(OUTPUT_STREAM, int id, int indent, char *colour) {
	HTML_OPEN_WITH("div", "id=\"extra%d\" style=\"display: none;\"", id);
	HTML::open_indented_p(OUT, indent, "");
	HTML::open_coloured_box(OUT, colour, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
}

void IndexUtilities::extra_div_close(OUTPUT_STREAM, char *colour) {
	HTML::close_coloured_box(OUT, colour, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
	HTML_CLOSE("p");
	HTML_CLOSE("div");
}

void IndexUtilities::extra_div_open_nested(OUTPUT_STREAM, int id, int indent) {
	HTML_OPEN_WITH("div", "id=\"extra%d\" style=\"display: none;\"", id);
	HTML::open_indented_p(OUT, indent, "");
}

void IndexUtilities::extra_div_close_nested(OUTPUT_STREAM) {
	HTML_CLOSE("p");
	HTML_CLOSE("div");
}

@h "Deprecation" icons.

=
void IndexUtilities::deprecation_icon(OUTPUT_STREAM, int id) {
	HTML_OPEN_WITH("a",
		"href=\"#\" onclick=\"showExtra('extra%d', 'plus%d'); return false;\"", id, id);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/deprecated.png");
	HTML_CLOSE("a");
	WRITE("&nbsp;");
}

@h Miscellaneous utilities.
First: to print a double-quoted word into the index, without its surrounding
quotes.

=
void IndexUtilities::dequote(OUTPUT_STREAM, wchar_t *p) {
	if ((p[0] == 0) || (p[1] == 0)) return;
	for (int i=1; p[i+1]; i++) {
		int c = p[i];
		switch(c) {
			case '"': WRITE("&quot;"); break;
			default: PUT_TO(OUT, c); break;
		}
	}
}

@ The "definition area" for content is usually a heading inside an extension;
see the Phrasebook element for examples of how this comes out.

=
void IndexUtilities::show_definition_area(OUTPUT_STREAM, inter_package *heading_pack,
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

@ Here |pack| is the Inter package for a kind constructor.

=
void IndexUtilities::kind_name(OUTPUT_STREAM, inter_package *pack, int plural,
	int with_links) {
	if (pack == NULL) return;
	text_stream *key = (plural)?I"^index_plural":I"^index_singular";
	WRITE("%S", Metadata::read_optional_textual(pack, key));
	if (with_links) IndexUtilities::link_package(OUT, pack);
}

@h Page state.

=
typedef struct index_page_data {
	int RS_unique_xtra_no;
	int IX_show_index_links;
	int row_stripe;
	struct faux_instance *indexing_room;
} index_page_data;

@ This is called whenever a new page is written:

=
void IndexUtilities::clear_page_data(index_session *session) {
	session->page.RS_unique_xtra_no = 1;
	session->page.IX_show_index_links = TRUE;
	session->page.row_stripe = FALSE;
	session->page.indexing_room = NULL;
}

@h Unique extra-box IDs.

=
int IndexUtilities::extra_ID(index_session *session) {
	return session->page.RS_unique_xtra_no++;
}

@h Links between rules in rulebook listings.
A notation is used to show how rulebook sorting affected the placement of
adjacent rules in an index listing; but this notation can be temporarily
switched off:

=
void IndexUtilities::list_suppress_indexed_links(index_session *session) {
	session->page.IX_show_index_links = FALSE;
}

void IndexUtilities::list_resume_indexed_links(index_session *session) {
	session->page.IX_show_index_links = TRUE;
}

int IndexUtilities::showing_links(index_session *session) {
	return session->page.IX_show_index_links;
}

@h Row stripes.

=
int IndexUtilities::stripe(index_session *session) {
	session->page.row_stripe = (session->page.row_stripe)?FALSE:TRUE;
	return session->page.row_stripe;
}

@h Room being indexed, if any.

=
faux_instance *IndexUtilities::room_being_indexed(index_session *session) {
	return session->page.indexing_room;
}

void IndexUtilities::set_room_being_indexed(faux_instance *I, index_session *session) {
	session->page.indexing_room = I;
}
