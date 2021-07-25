[FiguresElement::] Figures Element.

To write the Figures element (Fi) in the index.

@ Not only figures but also sounds and external files, a little questionably.

=
void FiguresElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->figure_nodes, Synoptic::module_order);
	TreeLists::sort(inv->sound_nodes, Synoptic::module_order);
	TreeLists::sort(inv->file_nodes, Synoptic::module_order);
	@<Index the figures@>;
	@<Index the sounds@>;
	@<Index the files@>;
}

@h Figures.

@<Index the figures@> =
	if (TreeLists::len(inv->figure_nodes) <= 1) { /* cover art always creates 1 */
		HTML_OPEN("p");
		Localisation::roman(OUT, LD, I"Index.Elements.Fi.NoFigures");
		HTML_CLOSE("p");
	} else {
		HTML_OPEN("p");
		Localisation::bold(OUT, LD, I"Index.Elements.Fi.ListOfFigures");
		HTML_CLOSE("p");
		@<Tabulate the figures@>;
	}

@ The table is presented with thumbnails of a given pixel width, which
the HTML renderer automatically scales to fit. Height is adjusted so as
to match this width, preserving the aspect ratio.

@d THUMBNAIL_WIDTH 80

=
@<Tabulate the figures@> =
	inter_package *settings = Inter::Packages::by_url(I, I"/main/completion/basics");
	int MAX_INDEXED_FIGURES =
		(int) Metadata::read_optional_numeric(settings, I"^max_indexed_figures");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	int count_of_displayed_figures = 0;
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->figure_nodes) {
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		if (id > 1) {
			text_stream *filename_as_text = Metadata::read_textual(pack, I"^filename");
			filename *F = Filenames::from_text(filename_as_text);
			TEMPORARY_TEXT(description)
			unsigned int width = 0, height = 0;
			int format_found = 0;
			@<Find image format and dimensions@>;
			@<Render a table row for the image@>;
			DISCARD_TEXT(description)
		}
	}
	HTML::end_html_table(OUT);
	if (count_of_displayed_figures > MAX_INDEXED_FIGURES) {
		HTML_OPEN("p");
		WRITE("(");
		Localisation::roman_ii(OUT, LD, I"Index.Elements.Fi.ThumbnailLimit", 
			MAX_INDEXED_FIGURES, 10*MAX_INDEXED_FIGURES);
		WRITE(")");
		HTML_CLOSE("p");
	}

@<Find image format and dimensions@> =
	FILE *FIGURE_FILE = Filenames::fopen(F, "rb");
	if (FIGURE_FILE) {
		text_stream *real_format = I"JPEG";
		format_found = ImageFiles::get_JPEG_dimensions(FIGURE_FILE, &width, &height);
		fclose(FIGURE_FILE);
		if (format_found == 0) {
			FIGURE_FILE = Filenames::fopen(F, "rb");
			if (FIGURE_FILE) {
				real_format = I"PNG";
				format_found = ImageFiles::get_PNG_dimensions(FIGURE_FILE, &width, &height);
				fclose(FIGURE_FILE);
			}
		}
		if (format_found == 0) {
			Localisation::italic(description, LD, I"Index.Elements.Fi.UnknownFormat");
		} else {
			Localisation::roman_t(description, LD, I"Index.Elements.Fi.Format", real_format);
			WRITE_TO(description, ": ");
			Localisation::roman_ii(description, LD, I"Index.Elements.Fi.Dimensions",
				(int) width, (int) height);
		}
	} else {
		Localisation::italic(description, LD, I"Index.Elements.Fi.Missing");
	}

@<Render a table row for the image@> =
	HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
	if (format_found == 0) {
		HTML_TAG_WITH("img",
			"border=\"0\" src=\"inform:/doc_images/image_problem.png\"");
		WRITE("&nbsp;");
	} else if (count_of_displayed_figures++ < MAX_INDEXED_FIGURES) {
		HTML_TAG_WITH("img",
			"border=\"1\" src=\"file://%f\" width=\"%d\" height=\"%d\"",
			F, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
		WRITE("&nbsp;");
	} else {
		HTML_OPEN_WITH("div",
			"style=\"width:%dpx; height:%dpx; border:1px solid; background-color:#6495ed;\"",
			THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
		WRITE("&nbsp;");
		HTML_CLOSE("div");
	}

	HTML::next_html_column(OUT, 0);
	WRITE("%S", Metadata::read_textual(pack, I"^name"));
	IndexUtilities::link_package(OUT, pack);
	HTML_TAG("br");
	if (Str::len(description) > 0) {
		WRITE("%S", description);
		HTML_TAG("br");
	}
	Localisation::roman_ti(description, LD, I"Index.Elements.Fi.Resource",
		Filenames::get_leafname(F), (int) id);
	HTML::end_html_row(OUT);

@h Sounds.

@<Index the sounds@> =
	if (TreeLists::len(inv->sound_nodes) == 0) {
		HTML_OPEN("p");
		Localisation::bold(OUT, LD, I"Index.Elements.Fi.ListOfSounds");
		HTML_CLOSE("p");
		HTML_OPEN("p");
		Localisation::roman(OUT, LD, I"Index.Elements.Fi.NoSounds");
		HTML_CLOSE("p");
	} else {
		@<Tabulate the sounds@>;
	}

@<Tabulate the sounds@> =
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->sound_nodes) {
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		text_stream *filename_as_text = Metadata::read_textual(pack, I"^filename");
		filename *F = Filenames::from_text(filename_as_text);
		unsigned int duration, pBitsPerSecond, pChannels, pSampleRate, fsize,
			midi_version = 0, no_tracks = 0;
		int preview = TRUE, waveform_style = TRUE;
		TEMPORARY_TEXT(description)
		int format_found = 0;
		@<Find sound format and duration@>
		@<Render a table row for the sound@>;
		DISCARD_TEXT(description)
	}
	HTML::end_html_table(OUT);

@<Find sound format and duration@> =
	FILE *SOUND_FILE = Filenames::fopen(F, "rb");
	if (SOUND_FILE) {
		text_stream *real_format = I"AIFF";
		format_found = SoundFiles::get_AIFF_duration(SOUND_FILE, &duration, &pBitsPerSecond,
			&pChannels, &pSampleRate);
		fseek(SOUND_FILE, 0, SEEK_END);
		fsize = (unsigned int) (ftell(SOUND_FILE));
		fclose(SOUND_FILE);
		if (format_found == 0) {
			SOUND_FILE = Filenames::fopen(F, "rb");
			if (SOUND_FILE) {
				real_format = I"Ogg Vorbis";
				preview = FALSE;
				format_found = SoundFiles::get_OggVorbis_duration(SOUND_FILE, &duration,
					&pBitsPerSecond, &pChannels, &pSampleRate);
				fclose(SOUND_FILE);
			}
		}
		if (format_found == 0) {
			SOUND_FILE = Filenames::fopen(F, "rb");
			if (SOUND_FILE) {
				waveform_style = FALSE;
				real_format = I"MIDI";
				preview = TRUE;
				format_found = SoundFiles::get_MIDI_information(SOUND_FILE,
					&midi_version, &no_tracks);
				fclose(SOUND_FILE);
			}
		}
		if (format_found == 0) {
			Localisation::italic(description, LD, I"Index.Elements.Fi.UnknownSoundFormat");
		} else {
			if (waveform_style == FALSE) @<Describe sound in MIDI format@>
			else @<Describe sound in waveform format@>;
		}
	} else {
		Localisation::italic(description, LD, I"Index.Elements.Fi.MissingSound");
	}

@<Describe sound in MIDI format@> =
	if (no_tracks == 1) {
		Localisation::roman_it(description, LD, I"Index.Elements.Fi.SoundFormatOneTrack",
			(int) midi_version, real_format);
	} else {
		Localisation::write_iti(description, LD, I"Index.Elements.Fi.SoundFormatMultiTrack",
			(int) midi_version, real_format, (int) no_tracks);
	}
	WRITE_TO(description, " - ");
	Localisation::italic(description, LD, I"Index.Elements.Fi.SoundUnsupported");

@<Describe sound in waveform format@> =
	TEMPORARY_TEXT(size)
	WRITE_TO(size, "%d.%01dKB", fsize/1024, (fsize%1024)/102);
	Localisation::roman_tt(description, LD, I"Index.Elements.Fi.SoundFile", size, real_format);
	DISCARD_TEXT(size)
	int min = (duration/6000), sec = (duration%6000)/100, centisec = (duration%100);
	WRITE_TO(description, ": ");
	TEMPORARY_TEXT(seconds)
	if (centisec == 0) WRITE_TO(seconds, "%d", sec);
	else WRITE_TO(seconds, "%d.%02d", sec, centisec);
	if (min > 0) {
		if ((sec > 0) || (centisec > 0)) {
			Localisation::roman_it(description, LD, I"Index.Elements.Fi.DurationMS",
				min, seconds);
		} else {
			Localisation::roman_i(description, LD, I"Index.Elements.Fi.DurationM", min);
		}
	} else {
		Localisation::roman_t(description, LD, I"Index.Elements.Fi.DurationS", seconds);
	}
	DISCARD_TEXT(seconds)
	WRITE_TO(description, "<br>");
	TEMPORARY_TEXT(sample)
	WRITE_TO(sample, "%d.%01dkHz", pSampleRate/1000, (pSampleRate%1000)/100);
	Localisation::roman_t(OUT, LD, I"Index.Elements.Fi.Sampled", sample);
	DISCARD_TEXT(sample)
	WRITE_TO(description, " ");
	if (pChannels == 1) Localisation::roman(OUT, LD, I"Index.Elements.Fi.Mono");
	else Localisation::roman(OUT, LD, I"Index.Elements.Fi.Stereo");
	WRITE_TO(description, " (");
	TEMPORARY_TEXT(bitrate)
	WRITE_TO(bitrate, "%d.%01d", pBitsPerSecond/1000, (pSampleRate%1000)/100);
	Localisation::roman_t(OUT, LD, I"Index.Elements.Fi.BitRate", bitrate);
	DISCARD_TEXT(bitrate)
	WRITE_TO(description, ")");

@<Render a table row for the sound@> =
	HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
	if (format_found == 0) {
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
	IndexUtilities::link_package(OUT, pack);
	HTML_TAG("br");
	if (Str::len(description) > 0) {
		WRITE("%S", description);
		HTML_TAG("br");
	}
	Localisation::roman_ti(description, LD, I"Index.Elements.Fi.Resource",
		Filenames::get_leafname(F), (int) id);
	HTML::end_html_row(OUT);

@h Files.
This is more or less perfunctory, but still of some use, if only as a list.

@<Index the files@> =
	if (TreeLists::len(inv->file_nodes) == 0) {
		HTML_OPEN("p");
		Localisation::roman(OUT, LD, I"Index.Elements.Fi.NoFiles");
		HTML_CLOSE("p");
	} else {
		HTML_OPEN("p");
		Localisation::bold(OUT, LD, I"Index.Elements.Fi.ListOfFiles");
		HTML_CLOSE("p");
		@<Tabulate the files@>;
	}

@<Tabulate the files@> =
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->file_nodes) {
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
		IndexUtilities::link_package(OUT, pack);
		HTML_TAG("br");
		if (is_binary)
			Localisation::roman_t(OUT, LD, I"Index.Elements.Fi.BinaryFile",
				Metadata::read_textual(pack, I"^leafname"));
		else
			Localisation::roman_t(OUT, LD, I"Index.Elements.Fi.TextFile",
				Metadata::read_textual(pack, I"^leafname"));
		WRITE(" - ");
		if (Metadata::read_optional_numeric(pack, I"^file_owned")) {
			Localisation::roman(OUT, LD, I"Index.Elements.Fi.FileOwnedByThis");
		} else if (Metadata::read_optional_numeric(pack, I"^file_owned_by_other")) {
			Localisation::roman(OUT, LD, I"Index.Elements.Fi.FileOwnedByOther");
		} else {
			Localisation::roman_t(OUT, LD, I"Index.Elements.Fi.FileOwnedBy",
				Metadata::read_textual(pack, I"^file_owner"));
		}
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
