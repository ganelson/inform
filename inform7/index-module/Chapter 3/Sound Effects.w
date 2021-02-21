[IXSounds::] Sound Effects.

To produce the index of sound effects.

@h Sounds Index.

=
void IXSounds::index_all(OUTPUT_STREAM) {
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
