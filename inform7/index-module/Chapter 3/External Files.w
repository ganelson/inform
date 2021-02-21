[IXExternalFiles::] External Files.

To produce the index of external files.

@ This is more or less perfunctory, but still of some use, if only as a list.

=
void IXExternalFiles::index_all(OUTPUT_STREAM) {
	if (PluginManager::active(files_plugin) == FALSE) return;
	files_data *exf;
	if (NUMBER_CREATED(files_data) == 0) {
		HTML_OPEN("p");
		WRITE("This project doesn't read or write external files.");
		HTML_CLOSE("p");
		return;
	}
	HTML_OPEN("p");
	WRITE("<b>List of External Files</b>");
	HTML_CLOSE("p");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	LOOP_OVER(exf, files_data) {
		HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
		if (exf->file_is_binary) {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/exf_binary.png\"");
		} else {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/exf_text.png\"");
		}
		WRITE("&nbsp;");
		HTML::next_html_column(OUT, 0);
		WRITE("%+W", exf->name);
		Index::link(OUT, Wordings::first_wn(exf->name));
		HTML_TAG("br");
		WRITE("Filename: %s %N- owned by ",
			(exf->file_is_binary)?"- binary ":"",
			exf->unextended_filename);
		switch (exf->file_ownership) {
			case OWNED_BY_THIS_PROJECT: WRITE("this project"); break;
			case OWNED_BY_ANOTHER_PROJECT: WRITE("another project"); break;
			case OWNED_BY_SPECIFIC_PROJECT:
				WRITE("project with IFID number <b>%S</b>",
					exf->IFID_of_owner);
				break;
		}
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
	HTML_OPEN("p");
}
