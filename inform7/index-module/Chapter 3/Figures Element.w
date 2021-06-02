[IXFigures::] Figures Element.

To produce the index of figures.

@

=
void IXFigures::render(OUTPUT_STREAM) {
	IXFigures::index_all(OUT);
	IXFigures::index_sounds(OUT);
	IXFigures::index_files(OUT);
}

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

@h Sounds Index.

=
void IXFigures::index_sounds(OUTPUT_STREAM) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	sounds_data *bs; FILE *SOUND_FILE;
	TEMPORARY_TEXT(line2)
	int rv;
	if (NUMBER_CREATED(sounds_data) == 0) {
		HTML_OPEN("p");
		WRITE("There are no sound effects in this project.");
		HTML_CLOSE("p");
		return;
	}
	HTML_OPEN("p"); WRITE("<b>List of Sounds</b>"); HTML_CLOSE("p");
	WRITE("\n");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	LOOP_OVER(bs, sounds_data) {
		unsigned int duration, pBitsPerSecond, pChannels, pSampleRate, fsize,
			midi_version = 0, no_tracks = 0;
		int preview = TRUE, waveform_style = TRUE;
		rv = 0;
		SOUND_FILE = Filenames::fopen(bs->filename_of_sound_file, "rb");
		if (SOUND_FILE) {
			char *real_format = "AIFF";
			rv = SoundFiles::get_AIFF_duration(SOUND_FILE, &duration, &pBitsPerSecond,
				&pChannels, &pSampleRate);
			fseek(SOUND_FILE, 0, SEEK_END);
			fsize = (unsigned int) (ftell(SOUND_FILE));
			fclose(SOUND_FILE);
			if (rv == 0) {
				SOUND_FILE = Filenames::fopen(bs->filename_of_sound_file, "rb");
				if (SOUND_FILE) {
					real_format = "Ogg Vorbis";
					preview = FALSE;
					rv = SoundFiles::get_OggVorbis_duration(SOUND_FILE, &duration,
						&pBitsPerSecond, &pChannels, &pSampleRate);
					fclose(SOUND_FILE);
				}
			}
			if (rv == 0) {
				SOUND_FILE = Filenames::fopen(bs->filename_of_sound_file, "rb");
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
				HTML_TAG("br");
			} else {
				if (waveform_style == FALSE) {
					WRITE_TO(line2, "Type %d %s file with %d track%s",
						midi_version, real_format, no_tracks,
						(no_tracks == 1)?"":"s");
					HTML_TAG("br");
					WRITE("<i>Warning: not officially supported in glulx yet</i>");
					HTML_TAG("br");
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
					HTML_TAG("br");
					WRITE_TO(line2, "Sampled as %d.%01dkHz %s (%d.%01d kilobits/sec)",
						pSampleRate/1000, (pSampleRate%1000)/100,
						(pChannels==1)?"Mono":"Stereo",
						pBitsPerSecond/1000, (pSampleRate%1000)/100);
					HTML_TAG("br");
				}
			}
		} else {
			WRITE_TO(line2, "<i>Missing from the Sounds folder</i>");
			HTML_TAG("br");
		}
		HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
		if (rv == 0) {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/image_problem.png\"");
		} else if (preview) {
			HTML_OPEN_WITH("embed",
				"src=\"file://%f\" width=\"%d\" height=\"64\" "
				"autostart=\"false\" volume=\"50%%\" mastersound",
				bs->filename_of_sound_file, THUMBNAIL_WIDTH);
			HTML_CLOSE("embed");
		} else {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/sound_okay.png\"");
		}
		WRITE("&nbsp;");
		HTML::next_html_column(OUT, 0);
		WRITE("%+W", bs->name);
		Index::link(OUT, Wordings::first_wn(bs->name));
		TEMPORARY_TEXT(rel)
		Filenames::to_text_relative(rel, bs->filename_of_sound_file,
			Projects::materials_path(Task::project()));
		HTML_TAG("br");
		WRITE("%SFilename: \"%S\" - resource number %d", line2, rel, bs->sound_number);
		DISCARD_TEXT(rel)
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
	HTML_OPEN("p");
	DISCARD_TEXT(line2)
}

@ This is more or less perfunctory, but still of some use, if only as a list.

=
void IXFigures::index_files(OUTPUT_STREAM) {
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
