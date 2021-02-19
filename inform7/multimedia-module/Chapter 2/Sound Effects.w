[PL::Sounds::] Sound Effects.

To register the names associated with sound resource numbers, which
are defined to allow the final story file to play sound effects, and to produce
the index of sound effects.

@ To be viable, sound files have to be of a format which Blorb recognises,
and in any case we only allow two formats: AIFF (uncompressed) and OGG
(compressed).

@d sounds_data blorb_sound

=
typedef struct blorb_sound {
	struct wording name; /* text of name */
	struct filename *filename_of_sound_file; /* relative to the Resources folder */
	int sound_number; /* resource number of this picture inside Blorb */
	int alt_description; /* word number of double-quoted description */
	CLASS_DEFINITION
} blorb_sound;

@ And we define one type ID.
A resource ID number for a figure (i.e.,
a picture) or a sound effect in the eventual blorb, or for use in Glulx
within the application.

= (early code)
kind *K_sound_name = NULL;

@ =
void PL::Sounds::start(void) {
	REGISTER(NEW_INSTANCE_NOTIFY_PCALL, PL::Sounds::sounds_new_named_instance_notify);
	REGISTER(NEW_BASE_KIND_NOTIFY_PCALL, PL::Sounds::sounds_new_base_kind_notify);
}

@ =
int PL::Sounds::sounds_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"SOUND_NAME_TY")) {
		K_sound_name = new_base; return TRUE;
	}
	return FALSE;
}

int allow_sound_creations = FALSE;

int PL::Sounds::sounds_new_named_instance_notify(instance *nc) {
	if (K_sound_name == NULL) return FALSE;
	kind *K = Instances::to_kind(nc);
	if (Kinds::eq(K, K_sound_name)) {
		if (allow_sound_creations == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BackdoorSoundCreation),
				"this is not the way to create a new sound name",
				"which should be done with a special 'Sound ... is the file ...' "
				"sentence.");
		ATTACH_PLUGIN_DATA_TO_SUBJECT(sounds, nc->as_subject, PL::Sounds::new_blorb_sound(nc));
		return TRUE;
	}
	return FALSE;
}

blorb_sound *PL::Sounds::new_blorb_sound(instance *nc) {
	blorb_sound *bs = CREATE(blorb_sound);
	return bs;
}

@ Sound allocation now follows. This handles the special meaning "X is an sound...".

=
<new-sound-sentence-object> ::=
	<definite-article> <new-sound-sentence-object-unarticled> |    ==> { pass 2 }
	<new-sound-sentence-object-unarticled>							==> { pass 1 }

<new-sound-sentence-object-unarticled> ::=
	file <np-unparsed>												==> { TRUE, RP[1] }

<nounphrase-sound> ::=
	sound ...							==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

@ =
int PL::Sounds::new_sound_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Sound... is the file..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-sound>(SW)) && (<new-sound-sentence-object>(OW))) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			if (PluginManager::active(sounds_plugin) == FALSE)
				internal_error("Sounds plugin inactive");
			PL::Sounds::register_sound(Node::get_text(V->next),
				Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

@ The syntax for sound effects allows for alt-texts, exactly as for figures.

=
<sound-sentence-object> ::=
	<sound-source> ( <quoted-text> ) |  ==> { R[1], -, <<alttext>> = R[2] }
	<sound-source>                      ==> { pass 1 }

<sound-source> ::=
	<quoted-text> |  ==> { pass 1 }
	...              ==> @<Issue PM_SoundNotTextual problem@>;

@<Issue PM_SoundNotTextual problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SoundNotTextual),
		"a sound effect can only be declared as a quoted file name",
		"which should be the name of an AIFF or OGG file inside the Sounds "
		"subfolder of the project's .materials folder. For instance, 'Sound "
		"of Swordplay is the file \"Crossed Swords.aiff\".'");
	==> { 0, - };

@ =
void PL::Sounds::register_sound(wording F, wording FN) {
	<<alttext>> = -1;
	<sound-sentence-object>(FN);
	int wn = <<r>>;
	if (wn == 0) return;
	if (wn > 0) Word::dequote(wn);
	if (<<alttext>> > 0) Word::dequote(<<alttext>>);

	Assertions::Creator::vet_name_for_noun(F);

	if ((<s-value>(F)) &&
		(Rvalues::is_CONSTANT_of_kind(<<rp>>, K_sound_name))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SoundDuplicate),
			"this is already the name of a sound effect",
			"so there must be some duplication somewhere.");
		return;
	}

	allow_sound_creations = TRUE;
	pcalc_prop *prop = Propositions::Abstract::to_create_something(
		K_sound_name, F);
	Assert::true(prop, CERTAIN_CE);
	allow_sound_creations = FALSE;
	blorb_sound *bs = PLUGIN_DATA_ON_INSTANCE(sounds, Instances::latest());

	TEMPORARY_TEXT(leaf)
	WRITE_TO(leaf, "%N", wn);
	bs->filename_of_sound_file = Filenames::in(Task::sounds_path(), leaf);
	DISCARD_TEXT(leaf)

	bs->name = F;
	bs->sound_number = Task::get_next_free_blorb_resource_ID();
	bs->alt_description = <<alttext>>;

	LOGIF(FIGURE_CREATIONS,
		"Created sound effect <%W> = filename '%N' = resource ID %d\n",
		F, wn, bs->sound_number);
}

@h Blurb and manifest.
The sounds manifest is used by the implementation of Glulx within the
Inform application to connect picture ID numbers with filenames relative
to the |.materials| folder for its project. (It's part of the XML
manifest file created from |Figures.w|.)

=
void PL::Sounds::write_sounds_manifest(OUTPUT_STREAM) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	blorb_sound *bs;
	if (NUMBER_CREATED(blorb_sound) == 0) return;
	WRITE("<key>Sounds</key>\n");
	WRITE("<dict>\n"); INDENT;
	LOOP_OVER(bs, blorb_sound) {
		WRITE("<key>%d</key>\n", bs->sound_number);
		TEMPORARY_TEXT(rel)
		Filenames::to_text_relative(rel, bs->filename_of_sound_file,
			Projects::materials_path(Task::project()));
		WRITE("<string>%S</string>\n", rel);
		DISCARD_TEXT(rel)
	}
	OUTDENT; WRITE("</dict>\n");
}

@ The following writes Blurb commands for all of the sounds.

=
void PL::Sounds::write_blurb_commands(OUTPUT_STREAM) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	blorb_sound *bs;
	LOOP_OVER(bs, blorb_sound) {
		wchar_t *desc = L"";
		if (bs->alt_description >= 0)
			desc = Lexer::word_text(bs->alt_description);
		if (Wide::len(desc) > 0)
			WRITE("sound %d \"%f\" \"%N\"\n",
				bs->sound_number, bs->filename_of_sound_file, bs->alt_description);
		else
			WRITE("sound %d \"%f\"\n", bs->sound_number, bs->filename_of_sound_file);
	}
}

@ The following is used only with the "separate figures" release option.

=
void PL::Sounds::write_copy_commands(void) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	blorb_sound *bs;
	LOOP_OVER(bs, blorb_sound)
		PL::Bibliographic::Release::create_aux_file(
			bs->filename_of_sound_file,
			Task::released_sounds_path(),
			L"--",
			SEPARATE_SOUNDS_PAYLOAD);
}

@ =
void PL::Sounds::compile_ResourceIDsOfSounds_array(void) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFSOUNDS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	Emit::array_numeric_entry(0);
	blorb_sound *bs;
	LOOP_OVER(bs, blorb_sound) Emit::array_numeric_entry((inter_ti) bs->sound_number);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}

@h Sounds Index.
The index is only a little helpful for sounds.

=
void PL::Sounds::index_all(OUTPUT_STREAM) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	blorb_sound *bs; FILE *SOUND_FILE;
	TEMPORARY_TEXT(line2)
	int rv;
	if (NUMBER_CREATED(blorb_sound) == 0) {
		HTML_OPEN("p");
		WRITE("There are no sound effects in this project.");
		HTML_CLOSE("p");
		return;
	}
	HTML_OPEN("p"); WRITE("<b>List of Sounds</b>"); HTML_CLOSE("p");
	WRITE("\n");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	LOOP_OVER(bs, blorb_sound) {
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
					rv = SoundFiles::get_OggVorbis_duration(SOUND_FILE, &duration, &pBitsPerSecond,
						&pChannels, &pSampleRate);
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
