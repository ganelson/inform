[FiguresElement::] Figures Element.

To write the Figures element (Fi) in the index.

@ This also includes sounds and external files, a little questionably.

=
void FiguresElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	if (TreeLists::len(inv->figure_nodes) > 0) {
		TreeLists::sort(inv->figure_nodes, Synoptic::module_order);
	}
	if (TreeLists::len(inv->sound_nodes) > 0) {
		TreeLists::sort(inv->sound_nodes, Synoptic::module_order);
	}
	if (TreeLists::len(inv->file_nodes) > 0) {
		TreeLists::sort(inv->file_nodes, Synoptic::module_order);
	}
	if (TreeLists::len(inv->figure_nodes) < 2) { /* cover art always creates 1 */
		HTML_OPEN("p");
		WRITE("There are no figures, or illustrations, in this project.");
		HTML_CLOSE("p");
	} else {
		@<Index the figures@>;
	}
	if (TreeLists::len(inv->sound_nodes) == 0) {
		HTML_OPEN("p");
		WRITE("There are no sound effects in this project.");
		HTML_CLOSE("p");
	} else {
		@<Index the sounds@>;
	}
	if (TreeLists::len(inv->file_nodes) == 0) {
		HTML_OPEN("p");
		WRITE("This project doesn't read or write external files.");
		HTML_CLOSE("p");
	} else {
		@<Index the files@>;
	}
}

@ The index is presented with thumbnails of a given pixel width, which
the HTML renderer automatically scales to fit. Height is adjusted so as
to match this width, preserving the aspect ratio.

@d THUMBNAIL_WIDTH 80

=
@<Index the figures@> =
	inter_package *settings = Inter::Packages::by_url(I, I"/main/completion/basics");
	int MAX_INDEXED_FIGURES =
		(int) Metadata::read_optional_numeric(settings, I"^max_indexed_figures");
	HTML_OPEN("p"); WRITE("<b>List of Figures</b>"); HTML_CLOSE("p");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	int count_of_displayed_figures = 0;
	for (int i=0; i<TreeLists::len(inv->figure_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->figure_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		if (id > 1) {
			text_stream *filename_as_text = Metadata::read_textual(pack, I"^filename");
			filename *F = Filenames::from_text(filename_as_text);
			TEMPORARY_TEXT(line2)
			unsigned int width = 0, height = 0;
			int rv = 0;
			FILE *FIGURE_FILE = Filenames::fopen(F, "rb");
			if (FIGURE_FILE) {
				char *real_format = "JPEG";
				rv = ImageFiles::get_JPEG_dimensions(FIGURE_FILE, &width, &height);
				fclose(FIGURE_FILE);
				if (rv == 0) {
					FIGURE_FILE = Filenames::fopen(F, "rb");
					if (FIGURE_FILE) {
						real_format = "PNG";
						rv = ImageFiles::get_PNG_dimensions(FIGURE_FILE, &width, &height);
						fclose(FIGURE_FILE);
					}
				}
				if (rv == 0) {
					WRITE_TO(line2, "<i>Unknown image format</i>");
				} else {
					WRITE_TO(line2, "%s format: %d (width) by %d (height) pixels",
						real_format, width, height);
				}
			} else {
				WRITE_TO(line2, "<i>Missing from the Figures folder</i>");
			}
			HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
			if (rv == 0) {
				HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/image_problem.png\"");
				WRITE("&nbsp;");
			} else if (count_of_displayed_figures++ < MAX_INDEXED_FIGURES) {
				HTML_TAG_WITH("img", "border=\"1\" src=\"file://%f\" width=\"%d\" height=\"%d\"",
					F, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
				WRITE("&nbsp;");
			} else {
				HTML_OPEN_WITH("div", "style=\"width:%dpx; height:%dpx; border:1px solid; background-color:#6495ed;\"",
					THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
				WRITE("&nbsp;");
				HTML_CLOSE("div");
			}

			HTML::next_html_column(OUT, 0);
			WRITE("%S", Metadata::read_textual(pack, I"^name"));
			int at = (int) Metadata::read_optional_numeric(pack, I"^at");
			if (at > 0) Index::link(OUT, at);

			HTML_TAG("br");
			if (Str::len(line2) > 0) {
				WRITE("%S", line2);
				HTML_TAG("br");
			}
			WRITE("Filename: \"%S\" - resource number %d", Filenames::get_leafname(F), id);
			HTML::end_html_row(OUT);
			DISCARD_TEXT(line2)
		}
	}
	HTML::end_html_table(OUT);
	if (count_of_displayed_figures > MAX_INDEXED_FIGURES) {
		HTML_OPEN("p");
		WRITE("(Only the first %d thumbnails have been shown here, "
			"to avoid Inform taking up too much memory. If you'd like to "
			"see more, set 'Use index figure thumbnails of at least %d.', or "
			"whatever number you want to wait for.)",
			MAX_INDEXED_FIGURES, 10*MAX_INDEXED_FIGURES);
		HTML_CLOSE("p");
	}

@h Sounds Index.

@<Index the sounds@> =
	HTML_OPEN("p"); WRITE("<b>List of Sounds</b>"); HTML_CLOSE("p");
	WRITE("\n");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	for (int i=0; i<TreeLists::len(inv->sound_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->sound_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		text_stream *filename_as_text = Metadata::read_textual(pack, I"^filename");
		filename *F = Filenames::from_text(filename_as_text);
		unsigned int duration, pBitsPerSecond, pChannels, pSampleRate, fsize,
			midi_version = 0, no_tracks = 0;
		int preview = TRUE, waveform_style = TRUE;
		TEMPORARY_TEXT(line2)
		int rv = 0;
		FILE *SOUND_FILE = Filenames::fopen(F, "rb");
		if (SOUND_FILE) {
			char *real_format = "AIFF";
			rv = SoundFiles::get_AIFF_duration(SOUND_FILE, &duration, &pBitsPerSecond,
				&pChannels, &pSampleRate);
			fseek(SOUND_FILE, 0, SEEK_END);
			fsize = (unsigned int) (ftell(SOUND_FILE));
			fclose(SOUND_FILE);
			if (rv == 0) {
				SOUND_FILE = Filenames::fopen(F, "rb");
				if (SOUND_FILE) {
					real_format = "Ogg Vorbis";
					preview = FALSE;
					rv = SoundFiles::get_OggVorbis_duration(SOUND_FILE, &duration,
						&pBitsPerSecond, &pChannels, &pSampleRate);
					fclose(SOUND_FILE);
				}
			}
			if (rv == 0) {
				SOUND_FILE = Filenames::fopen(F, "rb");
				if (SOUND_FILE) {
					waveform_style = FALSE;
					real_format = "MIDI";
					preview = TRUE;
					rv = SoundFiles::get_MIDI_information(SOUND_FILE,
						&midi_version, &no_tracks);
					fclose(SOUND_FILE);
				}
			}
			if (rv == 0) {
				WRITE_TO(line2, "<i>Unknown sound format</i>");
			} else {
				if (waveform_style == FALSE) {
					WRITE_TO(line2, "Type %d %s file with %d track%s",
						midi_version, real_format, no_tracks,
						(no_tracks == 1)?"":"s");
					HTML_TAG("br");
					WRITE("<i>Warning: not officially supported in glulx yet</i>");
				} else {
					int min = (duration/6000), sec = (duration%6000)/100,
						centisec = (duration%100);
					WRITE_TO(line2, "%d.%01dKB %s file: duration ",
						fsize/1024, (fsize%1024)/102, real_format);
					if (min > 0)
						WRITE_TO(line2, "%d minutes ", min);
					if ((sec > 0) || (centisec > 0)) {
						if (centisec == 0)
							WRITE_TO(line2, "%d seconds", sec);
						else
							WRITE_TO(line2, "%d.%02d seconds", sec, centisec);
					} else WRITE_TO(line2, "exactly");
					WRITE_TO(line2, "Sampled as %d.%01dkHz %s (%d.%01d kilobits/sec)",
						pSampleRate/1000, (pSampleRate%1000)/100,
						(pChannels==1)?"Mono":"Stereo",
						pBitsPerSecond/1000, (pSampleRate%1000)/100);
				}
			}
		} else {
			WRITE_TO(line2, "<i>Missing from the Sounds folder</i>");
		}
		HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
		if (rv == 0) {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/image_problem.png\"");
		} else if (preview) {
			HTML_OPEN_WITH("embed",
				"src=\"file://%f\" width=\"%d\" height=\"64\" "
				"autostart=\"false\" volume=\"50%%\" mastersound",
				F, THUMBNAIL_WIDTH);
			HTML_CLOSE("embed");
		} else {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/sound_okay.png\"");
		}
		WRITE("&nbsp;");
		HTML::next_html_column(OUT, 0);
		WRITE("%S", Metadata::read_textual(pack, I"^name"));
		int at = (int) Metadata::read_optional_numeric(pack, I"^at");
		if (at > 0) Index::link(OUT, at);
		HTML_TAG("br");
		if (Str::len(line2) > 0) {
			WRITE("%S", line2);
			HTML_TAG("br");
		}
		WRITE("Filename: \"%S\" - resource number %d", Filenames::get_leafname(F), id);
		DISCARD_TEXT(line2)
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);

@ This is more or less perfunctory, but still of some use, if only as a list.

=
@<Index the files@> =
	HTML_OPEN("p");
	WRITE("<b>List of External Files</b>");
	HTML_CLOSE("p");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	for (int i=0; i<TreeLists::len(inv->file_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->file_nodes->list[i].node);
		HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
		int is_binary = (int) Metadata::read_optional_numeric(pack, I"^is_binary");
		if (is_binary) {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/exf_binary.png\"");
		} else {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/exf_text.png\"");
		}
		WRITE("&nbsp;");
		HTML::next_html_column(OUT, 0);
		WRITE("%S", Metadata::read_textual(pack, I"^name"));
		int at = (int) Metadata::read_optional_numeric(pack, I"^at");
		if (at > 0) Index::link(OUT, at);
		HTML_TAG("br");
		WRITE("Filename: %s %S- owned by ",
			(is_binary)?"- binary ":"",
			Metadata::read_textual(pack, I"^leafname"));
		if (Metadata::read_optional_numeric(pack, I"^file_owned")) {
			WRITE("this project");
		} else if (Metadata::read_optional_numeric(pack, I"^file_owned_by_other")) {
			WRITE("another project");
		} else {
			WRITE("project with IFID number <b>%S</b>",
				Metadata::read_textual(pack, I"^file_owner"));
		}
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
	HTML_OPEN("p");
