[IXFigures::] Figures.

To produce the index of figures.

@ The index is presented with thumbnails of a given pixel width, which
the HTML renderer automatically scales to fit. Height is adjusted so as
to match this width, preserving the aspect ratio.

@d THUMBNAIL_WIDTH 80

=
void IXFigures::index_all(OUTPUT_STREAM) {
	if (PluginManager::active(figures_plugin) == FALSE) return;
	figures_data *bf; FILE *FIGURE_FILE;
	int MAX_INDEXED_FIGURES = global_compilation_settings.index_figure_thumbnails;
	int rv;
	if (NUMBER_CREATED(figures_data) < 2) { /* cover art always creates 1 */
		HTML_OPEN("p"); WRITE("There are no figures, or illustrations, in this project.");
		HTML_CLOSE("p"); return;
	}
	HTML_OPEN("p"); WRITE("<b>List of Figures</b>"); HTML_CLOSE("p");

	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	int count_of_displayed_figures = 0;
	LOOP_OVER(bf, figures_data) {
		if (bf->figure_number > 1) {
			TEMPORARY_TEXT(line2)
			unsigned int width = 0, height = 0;
			rv = 0;
			FIGURE_FILE = Filenames::fopen(bf->filename_of_image_file, "rb");
			if (FIGURE_FILE) {
				char *real_format = "JPEG";
				rv = ImageFiles::get_JPEG_dimensions(FIGURE_FILE, &width, &height);
				fclose(FIGURE_FILE);
				if (rv == 0) {
					FIGURE_FILE = Filenames::fopen(bf->filename_of_image_file, "rb");
					if (FIGURE_FILE) {
						real_format = "PNG";
						rv = ImageFiles::get_PNG_dimensions(FIGURE_FILE, &width, &height);
						fclose(FIGURE_FILE);
					}
				}
				if (rv == 0) {
					WRITE_TO(line2, "<i>Unknown image format</i>");
					HTML_TAG("br");
				} else {
					WRITE_TO(line2, "%s format: %d (width) by %d (height) pixels",
						real_format, width, height);
					HTML_TAG("br");
				}
			} else {
				WRITE_TO(line2, "<i>Missing from the Figures folder</i>");
				HTML_TAG("br");
			}
			HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
			if (rv == 0) {
				HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/image_problem.png\"");
				WRITE("&nbsp;");
			} else if (count_of_displayed_figures++ < MAX_INDEXED_FIGURES) {
				HTML_TAG_WITH("img", "border=\"1\" src=\"file://%f\" width=\"%d\" height=\"%d\"",
					bf->filename_of_image_file, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
				WRITE("&nbsp;");
			} else {
				HTML_OPEN_WITH("div", "style=\"width:%dpx; height:%dpx; border:1px solid; background-color:#6495ed;\"",
					THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
				WRITE("&nbsp;");
				HTML_CLOSE("div");
			}

			HTML::next_html_column(OUT, 0);
			WRITE("%+W", bf->name);
			Index::link(OUT, Wordings::first_wn(bf->name));

			TEMPORARY_TEXT(rel)
			Filenames::to_text_relative(rel, bf->filename_of_image_file,
				Projects::materials_path(Task::project()));
			HTML_TAG("br");
			WRITE("%SFilename: \"%S\" - resource number %d", line2, rel, bf->figure_number);
			DISCARD_TEXT(rel)
			HTML::end_html_row(OUT);
			DISCARD_TEXT(line2)
		}
	}
	HTML::end_html_table(OUT);
	HTML_OPEN("p");
	if (count_of_displayed_figures > MAX_INDEXED_FIGURES) {
		WRITE("(Only the first %d thumbnails have been shown here, "
			"to avoid Inform taking up too much memory. If you'd like to "
			"see more, set 'Use index figure thumbnails of at least %d.', or "
			"whatever number you want to wait for.)",
			MAX_INDEXED_FIGURES, 10*MAX_INDEXED_FIGURES);
		HTML_CLOSE("p");
	}
}
