[Index::] Index File Services.

Miscellaneous utility functions for producing index content.

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
