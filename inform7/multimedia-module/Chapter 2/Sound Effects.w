[Sounds::] Sound Effects.

To register the names associated with sound resource numbers, which are defined
to allow the final story file to play sound effects.

@ The following is called to activate the plugin:

=
void Sounds::start(void) {
	PluginManager::plug(MAKE_SPECIAL_MEANINGS_PLUG, Sounds::make_special_meanings);
	PluginManager::plug(NEW_BASE_KIND_NOTIFY_PLUG, Sounds::new_base_kind_notify);
	PluginManager::plug(NEW_INSTANCE_NOTIFY_PLUG, Sounds::new_named_instance_notify);
}

@h One special meaning.
We add one special meaning for assertions, to catch sentences with the shape
"Sound... is the file...".

=
int Sounds::make_special_meanings(void) {
	SpecialMeanings::declare(Sounds::new_sound_SMF, I"new-sound", 2);
	return FALSE;
}
int Sounds::new_sound_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) {
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
			Sounds::register_sound(Node::get_text(V->next),
				Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

@ And this is the Preform grammar needed:

=
<new-sound-sentence-object> ::=
	<definite-article> <new-sound-sentence-object-unarticled> |  ==> { pass 2 }
	<new-sound-sentence-object-unarticled>						 ==> { pass 1 }

<new-sound-sentence-object-unarticled> ::=
	file <np-unparsed>                                           ==> { TRUE, RP[1] }

<nounphrase-sound> ::=
	sound ...                              ==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

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

@ In assertion pass 1, then, the following is called on any sentence which
has been found to create a sound:

=
void Sounds::register_sound(wording W, wording FN) {
	<<alttext>> = -1;
	if (<sound-sentence-object>(FN)) {
		int wn = <<r>>;
		if (wn > 0) Word::dequote(wn);
		if (<<alttext>> > 0) Word::dequote(<<alttext>>);
		@<Make sure W is acceptable as a new sound name@>;
		int id = Task::get_next_free_blorb_resource_ID();
		TEMPORARY_TEXT(leaf)
		WRITE_TO(leaf, "%N", wn);
		DISCARD_TEXT(leaf)
		filename *sound_file = Filenames::in(Task::sounds_path(), leaf);
		Sounds::sounds_create(W, id, sound_file, <<alttext>>);
		LOGIF(MULTIMEDIA_CREATIONS,
			"Created sound effect <%W> = filename '%N' = resource ID %d\n", W, wn, id);
	}
}

@<Make sure W is acceptable as a new sound name@> =
	Assertions::Creator::vet_name_for_noun(W);
	if ((<s-value>(W)) && (Rvalues::is_CONSTANT_of_kind(<<rp>>, K_sound_name))) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_SoundDuplicate),
			"this is already the name of a sound effect",
			"so there must be some duplication somewhere.");
		return;
	}

@h One significant kind.

= (early code)
kind *K_sound_name = NULL;

@ This is created by an Inter kit early in Inform's run; the function below
detects that this has happened, and sets |K_sound_name| to point to it.

=
int Sounds::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"SOUND_NAME_TY")) {
		K_sound_name = new_base; return TRUE;
	}
	return FALSE;
}

@h Significant new instances.
This structure of additional data is attached to each sound instance:

=
typedef struct sounds_data {
	struct wording name; /* text of name */
	struct filename *filename_of_sound_file; /* relative to the Resources folder */
	int sound_number; /* resource number of this picture inside Blorb */
	int alt_description; /* word number of double-quoted description */
	CLASS_DEFINITION
} sounds_data;

@ We allow instances of "sound name" to be created only through the above
code calling //Sounds::sounds_create//. If any other proposition somehow
manages to make a sound, a problem message is thrown.

=
int allow_sound_creations = FALSE;

instance *Sounds::sounds_create(wording W, int id, filename *sound_file, int alt) {
	allow_sound_creations = TRUE;
	Assert::true(Propositions::Abstract::to_create_something(K_sound_name, W), CERTAIN_CE);
	allow_sound_creations = FALSE;
	instance *I = Instances::latest();
	sounds_data *sd = PLUGIN_DATA_ON_INSTANCE(sounds, I);
	sd->filename_of_sound_file = sound_file;
	sd->name = W;
	sd->sound_number = id;
	sd->alt_description = alt;
	return I;
}

int Sounds::new_named_instance_notify(instance *I) {
	if ((K_sound_name) && (Kinds::eq(Instances::to_kind(I), K_sound_name))) {
		if (allow_sound_creations == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_BackdoorSoundCreation),
				"this is not the way to create a new sound name",
				"which should be done with a special 'Sound ... is the file ...' "
				"sentence.");
		ATTACH_PLUGIN_DATA_TO_SUBJECT(sounds, I->as_subject, CREATE(sounds_data));
		return TRUE;
	}
	return FALSE;
}

@h Blurb and manifest.
The sounds manifest is used by the implementation of Glulx within the Inform
application to connect picture ID numbers with filenames relative to the
|.materials| folder for its project. (It's part of the XML manifest file
created from |Figures.w|.)

=
void Sounds::write_sounds_manifest(OUTPUT_STREAM) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	sounds_data *sd;
	if (NUMBER_CREATED(sounds_data) == 0) return;
	WRITE("<key>Sounds</key>\n");
	WRITE("<dict>\n"); INDENT;
	LOOP_OVER(sd, sounds_data) {
		WRITE("<key>%d</key>\n", sd->sound_number);
		TEMPORARY_TEXT(rel)
		Filenames::to_text_relative(rel, sd->filename_of_sound_file,
			Projects::materials_path(Task::project()));
		WRITE("<string>%S</string>\n", rel);
		DISCARD_TEXT(rel)
	}
	OUTDENT; WRITE("</dict>\n");
}

@ The following writes Blurb commands for all of the sounds.

=
void Sounds::write_blurb_commands(OUTPUT_STREAM) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	sounds_data *sd;
	LOOP_OVER(sd, sounds_data) {
		wchar_t *desc = L"";
		if (sd->alt_description >= 0)
			desc = Lexer::word_text(sd->alt_description);
		if (Wide::len(desc) > 0)
			WRITE("sound %d \"%f\" \"%N\"\n",
				sd->sound_number, sd->filename_of_sound_file, sd->alt_description);
		else
			WRITE("sound %d \"%f\"\n", sd->sound_number, sd->filename_of_sound_file);
	}
}

@ The following is used only with the "separate figures" release option.

=
void Sounds::write_copy_commands(void) {
	if (PluginManager::active(sounds_plugin) == FALSE) return;
	sounds_data *sd;
	LOOP_OVER(sd, sounds_data)
		PL::Bibliographic::Release::create_aux_file(
			sd->filename_of_sound_file,
			Task::released_sounds_path(),
			L"--",
			SEPARATE_SOUNDS_PAYLOAD);
}
