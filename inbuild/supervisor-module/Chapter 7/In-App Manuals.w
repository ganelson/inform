[Manuals::] In-App Manuals.

Adaptations to extension documentation for rendering inside the app.

@h Duplex contents page.

=
void Manuals::duplex_contents_page(OUTPUT_STREAM, compiled_documentation *cd) {
	Manuals::write_javascript_for_contents_buttons(OUT, cd);
	HTML_OPEN_WITH("div", "class=\"midnight\"");
	HTML_OPEN_WITH("table", "cellspacing=\"3\" border=\"0\" width=\"100%%\"");
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "style=\"width:80px; height:120px;\"");
	HTML_TAG_WITH("img", "src=\"inform:/doc_images/wwi_cover@2x.png\" class=\"thinbordered\" style=\"width:80px; height:120px;\"");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "style=\"width:80px; height:120px;\"");
	HTML_TAG_WITH("img", "src=\"inform:/doc_images/irb_cover@2x.png\" class=\"thinbordered\" style=\"width:80px; height:120px;\"");
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "style=\"width:100%%;\"");
	HTML_OPEN_WITH("div", "class=\"headingboxhigh\"");
	HTML_OPEN_WITH("div", "class=\"headingtext\"");
	WRITE("Documentation");
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubric\"");
	WRITE("Two complete books about Inform:");
	HTML_TAG("br");
	WRITE("<i>Writing with Inform</i>, a comprehensive introduction");
	HTML_TAG("br");
	WRITE("<i>The Inform Recipe Book</i>, practical solutions for authors to use");
	HTML_CLOSE("div");
	HTML_CLOSE("div");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	TEMPORARY_TEXT(title)
	WRITE_TO(title, "Contents");
	int column = 0;
	cd_volume *volumes[2] = { NULL, NULL };
	cd_volume *V;
	LOOP_OVER_LINKED_LIST(V, cd_volume, cd->volumes) {
		volumes[column++] = V;
		if (column == 2) break;
	}
	HTML_OPEN_WITH("table", "class=\"fullwidth\"");
	for (column=0; column<2; column++)
		if (volumes[column])
			@<Render this column of the contents@>;
	HTML_CLOSE("table");

	DISCARD_TEXT(title)
	HTML_CLOSE("div");
}

@<Render this column of the contents@> =
	if (column == 0) HTML_OPEN_WITH("td", "class=\"midnightlefthalfpage\"")
	else HTML_OPEN_WITH("td", "class=\"midnightrighthalfpage\"");
	@<Render a heavyweight column of links@>;
	HTML_CLOSE("td");

@ The lines linking to sections within a chapter are grouped into a |<div>| for
that chapter, which can be hidden or revealed -- it contains "extra" material,
as we put it.

We assume here that there are fewer than 1000 chapters in each volume;
there are in practice about 25.

@<Render a heavyweight column of links@> =
	cd_volume *V = volumes[column];

	TEMPORARY_TEXT(extra)
	Manuals::all_extras_link(extra, V->label);
	Manuals::midnight_contents_column_banner(OUT, V->title, V, extra);
	DISCARD_TEXT(extra)

	int extra_count = 0;
	Manuals::duplex_r(OUT, V->volume_item, column, &extra_count);
	if (extra_count > 0) HTML::end_div(OUT);

	for (int ix=0; ix<NO_CD_INDEXES; ix++)
		if (((column == 0) && ((ix == 1) || (ix == 3))) ||
			((column == 1) && ((ix == 0) || (ix == 2))))
			if (cd->include_index[ix]) {
				Manuals::mc_link_A(OUT, cd->index_URL_pattern[ix], cd->index_title[ix]);
			}

	WRITE("\n");

@

=
void Manuals::midnight_contents_column_banner(OUTPUT_STREAM, text_stream *title, cd_volume *V, text_stream *extra) {
	HTML_OPEN_WITH("table", "class=\"fullwidth midnightblack\"");
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"midnightbannerleftcell\"");
	WRITE("%S", extra);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"midnightbannercentrecell\"");
	HTML_OPEN_WITH("span", "class=\"midnightbannertext\"");
	WRITE("%S", title);
	HTML_CLOSE("span");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
}

void Manuals::duplex_r(OUTPUT_STREAM, markdown_item *md, int column, int *extra_count) {
	if (md == NULL) return;
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 1)) {
		if (*extra_count > 0) HTML::end_div(OUT);
		int id = column*1000 + (*extra_count)++;
		HTML_OPEN_WITH("p", "class=\"midnightcontentsA\"");
		Manuals::extra_link(OUT, id);
		DocumentationRenderer::link_to(OUT, md);
		for (markdown_item *ch = md->down; ch; ch = ch->next)
			Markdown::render_extended(OUT, ch, InformFlavouredMarkdown::variation());
		HTML_CLOSE("a");
		HTML_CLOSE("p");
		Manuals::extra_div_open(OUT, id);
	}
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 2)) {
		HTML_OPEN_WITH("p", "class=\"midnightcontentsB\"");
		DocumentationRenderer::link_to(OUT, md);
		for (markdown_item *ch = md->down; ch; ch = ch->next)
			Markdown::render_extended(OUT, ch, InformFlavouredMarkdown::variation());
		HTML_CLOSE("a");
		HTML_CLOSE("p");
	}
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		Manuals::duplex_r(OUT, ch, column, extra_count);
}

@ The "extra" functions here are for revealing or concealing page content
when the user clicks a button. Each such piece of content is in its own
uniquely-ID'd |<div>|, as follows:

=
void Manuals::extra_div_open(OUTPUT_STREAM, int id) {
	HTML_OPEN_WITH("div", "id=\"extra%d\" style=\"display: none;\"", id);
}

@ And the following links provide the wiring for the buttons:

=
void Manuals::extra_icon(OUTPUT_STREAM, text_stream *name) {
	WRITE("inform:/doc_images/%S.png", name);
}

void Manuals::extra_link(OUTPUT_STREAM, int id) {
	TEMPORARY_TEXT(onclick)
	WRITE_TO(onclick, "showExtra('extra%d', 'plus%d'); return false;", id, id);
	HTML::begin_link_with_class_onclick(OUT, NULL, I"#", onclick);
	DISCARD_TEXT(onclick)
	TEMPORARY_TEXT(details)
	WRITE_TO(details, "alt=\"show\" id=\"plus%d\" src=\"", id);
	Manuals::extra_icon(details, I"extra");
	WRITE_TO(details, "\"");
	HTML::tag(OUT, "img", details);
	DISCARD_TEXT(details)
	HTML_CLOSE("a");
	WRITE("&#160;");
}

void Manuals::all_extras_link(OUTPUT_STREAM, text_stream *from) {
	WRITE("&#160;");
	TEMPORARY_TEXT(onclick)
	WRITE_TO(onclick, "showExtra%S(); return false;", from);
	HTML::begin_link_with_class_onclick(OUT, NULL, I"#", onclick);
	DISCARD_TEXT(onclick)
	TEMPORARY_TEXT(details)
	WRITE_TO(details, "alt=\"show\" id=\"plus%S\" src=\"", from);
	Manuals::extra_icon(details, I"extrab");
	WRITE_TO(details, "\"");
	HTML::tag(OUT, "img", details);
	DISCARD_TEXT(details)
	HTML_CLOSE("a");
}


@ And here are the level A and B contents entry link paragraphs:

=
void Manuals::mc_link_A(OUTPUT_STREAM, text_stream *to, text_stream *text) {
	HTML_OPEN_WITH("p", "class=\"midnightcontentsA\"");
	Indexes::general_link(OUT, I"standardlink", to, text);
	HTML_CLOSE("p");
}

void Manuals::mc_link_B(OUTPUT_STREAM, text_stream *to, text_stream *text) {
	HTML_OPEN_WITH("p", "class=\"midnightcontentsB\"");
	Indexes::general_link(OUT, I"standardlink", to, text);
	HTML_CLOSE("p");
}

void Manuals::midnight_section_title(text_stream *OUT, compiled_documentation *cd,
	filename *linkleft, text_stream *title, filename *linkright) {
	HTML::begin_div_with_class_S(OUT, I"bookheader", __FILE__, __LINE__);
	TEMPORARY_TEXT(lf)
	TEMPORARY_TEXT(rf)
	WRITE_TO(lf, "%/f", linkleft);
	WRITE_TO(rf, "%/f", linkright);
	Manuals::midnight_banner(OUT, cd,
		title, cd->contents_URL_pattern, lf, rf);
	HTML::end_div(OUT);
	DISCARD_TEXT(lf)
	DISCARD_TEXT(rf)
}

@ =
void Manuals::image_with_id(OUTPUT_STREAM, text_stream *name, text_stream *id) {
	TEMPORARY_TEXT(details)
	WRITE_TO(details, "alt=\"%S\" src=\"inform:/doc_images/%S\" id=\"%S\"", name, name, id);
	HTML::tag(OUT, "img", details);
	DISCARD_TEXT(details)
}

void Manuals::midnight_banner_for_indexes(text_stream *OUT, compiled_documentation *cd,
	text_stream *title) {
	Manuals::midnight_banner(OUT, cd, title, NULL, NULL, NULL);
}

void Manuals::midnight_banner(OUTPUT_STREAM, compiled_documentation *cd, text_stream *title,
	text_stream *linkcentre, text_stream *linkleft, text_stream *linkright) {
	HTML_OPEN_WITH("div", "class=\"midnight\"");
	TEMPORARY_TEXT(url)
	WRITE_TO(url, "%S", cd->contents_URL_pattern);
	HTML_OPEN_WITH("table", "class=\"fullwidth midnightblack\"");
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"midnightbannerleftcell\"");
	if (Str::len(linkleft) > 0) {
		TEMPORARY_TEXT(img)
		Manuals::image_with_id(img, I"Hookleft.png", I"hookleft");
		Indexes::general_link(OUT, I"standardlink", linkleft, img);
		DISCARD_TEXT(img)
	}
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"midnightbannercentrecell\"");
	if (Str::len(linkcentre) > 0) HTML::begin_link_with_class(OUT, I"standardlink", url);
	HTML_OPEN_WITH("span", "class=\"midnightbannertext\"");
	WRITE("%S", title);
	HTML_CLOSE("span");
	if (Str::len(linkcentre) > 0) HTML::end_link(OUT);
	HTML_CLOSE("td");
	HTML_OPEN_WITH("td", "class=\"midnightbannerrightcell\"");
	TEMPORARY_TEXT(img)
	Manuals::image_with_id(img, I"Hookup.png", I"hookup");
	Indexes::general_link(OUT, I"standardlink", url, img);
	DISCARD_TEXT(img)
	if (Str::len(linkright) > 0) {
		TEMPORARY_TEXT(img)
		Manuals::image_with_id(img, I"Hookright.png", I"hookright");
		Indexes::general_link(OUT, I"standardlink", linkright, img);
		DISCARD_TEXT(img)
	}
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	DISCARD_TEXT(url)
	HTML_CLOSE("div");
}

void Manuals::write_javascript_for_contents_buttons(OUTPUT_STREAM, compiled_documentation *cd) {
	HTML::open_javascript(OUT, FALSE);
	WRITE("    function openExtra(id, imid) {\n");
	WRITE("        document.getElementById(id).style.display = 'block';\n");
	WRITE("        document.getElementById(imid).src = '");
		Manuals::extra_icon(OUT, I"extraclose");
		WRITE("';\n");
	WRITE("    }\n");
	WRITE("    function closeExtra(id, imid) {\n");
	WRITE("        document.getElementById(id).style.display = 'none';\n");
	WRITE("        document.getElementById(imid).src = '");
		Manuals::extra_icon(OUT, I"extra");
		WRITE("';\n");
	WRITE("    }\n");
	int column = 0;
	cd_volume *volumes[2] = { NULL, NULL };
	int counts[2] = { 0, 0 };
	cd_volume *V;
	LOOP_OVER_LINKED_LIST(V, cd_volume, cd->volumes) {
		counts[column] = Manuals::chapter_count(V);
		volumes[column++] = V;
		if (column == 2) break;
	}
	for (column=0; column<2; column++)
		if (volumes[column]) {
			cd_volume *V = volumes[column];
			WRITE("    function showExtra%S() {\n", V->label);
			WRITE("        if (document.getElementById('plus%S').src.indexOf('", V->label);
				Manuals::extra_icon(OUT, I"extrab");
				WRITE("') >= 0) {\n");
			for (int i=0; i<counts[column]; i++) {
				int bn = (column)*1000+i;
				WRITE("            openExtra('extra%d', 'plus%d');\n", bn, bn);
			}
			WRITE("            document.getElementById('plus%S').src = '", V->label);
				Manuals::extra_icon(OUT, I"extracloseb");
				WRITE("';\n");
			WRITE("        } else {\n");
			for (int i=0; i<counts[column]; i++) {
				int bn = (column)*1000+i;
				WRITE("            closeExtra('extra%d', 'plus%d');\n", bn, bn);
			}
			WRITE("            document.getElementById('plus%S').src = '", V->label);
				Manuals::extra_icon(OUT, I"extrab");
				WRITE("';\n");
			WRITE("        }\n");
			WRITE("	}\n");
		}
	HTML::close_javascript(OUT);
}

int Manuals::chapter_count(cd_volume *V) {
	return Manuals::chapter_count_r(V->volume_item, 0);
}

int Manuals::chapter_count_r(markdown_item *md, int count) {
	if (md) {
		if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 1)) count++;
		if (md->type == MATERIAL_MIT) return count;
		for (markdown_item *ch = md->down; ch; ch = ch->next)
			count = Manuals::chapter_count_r(ch, count);
	}
	return count;
}

