[Figures::] Figures.

To register the names associated with picture resource numbers, which are defined
to allow the final story file to show illustrations.

@ The following is called to activate the plugin:

=
void Figures::start(void) {
	PluginManager::plug(MAKE_SPECIAL_MEANINGS_PLUG, Figures::make_special_meanings);
	PluginManager::plug(NEW_BASE_KIND_NOTIFY_PLUG, Figures::figures_new_base_kind_notify);
	PluginManager::plug(NEW_INSTANCE_NOTIFY_PLUG, Figures::figures_new_named_instance_notify);
	PluginManager::plug(PRODUCTION_LINE_PLUG, Figures::production_line);
}

int Figures::production_line(int stage, int debugging, stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(RTMultimedia::compile_figures);
	}
	return FALSE;
}

@h One special meaning.
We add one special meaning for assertions, to catch sentences with the shape
"Figure... is the file...".

=
int Figures::make_special_meanings(void) {
	SpecialMeanings::declare(Figures::new_figure_SMF, I"new-figure", 2);
	return FALSE;
}
int Figures::new_figure_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Figure... is the file..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-figure>(SW)) && (<new-figure-sentence-object>(OW))) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			Figures::register_figure(Node::get_text(V->next),
				Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

@ And this is the Preform grammar needed:

=
<new-figure-sentence-object> ::=
	<definite-article> <new-figure-sentence-object-unarticled> |  ==> { pass 2 }
	<new-figure-sentence-object-unarticled>                       ==> { pass 1 }

<new-figure-sentence-object-unarticled> ::=
	file <np-unparsed>                                            ==> { TRUE, RP[1] }

<nounphrase-figure> ::=
	figure ...                           ==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

<figure-sentence-object> ::=
	<figure-source> ( <quoted-text> ) |  ==> { R[1], -, <<alttext>> = R[2] }
	<figure-source>                      ==> { pass 1 }

<figure-source> ::=
	of cover art |                       ==> { -1, - }
	<quoted-text> |                      ==> { pass 1 }
	...                                  ==> @<Issue PM_PictureNotTextual problem@>;

@<Issue PM_PictureNotTextual problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PictureNotTextual),
		"a figure can only be declared as a quoted file name",
		"which should be the name of a JPEG or PNG image inside the "
		"project's .materials folder. For instance, 'Figure 2 is the "
		"file \"Crossed Swords.png\".'");
	==> { 0, - };

@ This is a figure name which Inform provides special support for; it recognises
the English name when it is defined by the Standard Rules. (So there is no need
to translate this to other languages.)

=
<notable-figures> ::=
	of cover art

@ In assertion pass 1, then, the following is called on any sentence which
has been found to create a figure:

=
void Figures::register_figure(wording W, wording FN) {
	<<alttext>> = -1;
	if (<figure-sentence-object>(FN)) {
		int wn = <<r>>;
		if (wn > 0) Word::dequote(wn);
		if (<<alttext>> > 0) Word::dequote(<<alttext>>);
		@<Make sure W is acceptable as a new figure name@>;
		int id = 1; /* the ID of the cover art */
		if (wn >= 0) id = Task::get_next_free_blorb_resource_ID();
		TEMPORARY_TEXT(leaf)
		WRITE_TO(leaf, "%N", wn);
		if ((wn >= 0) && (Str::is_whitespace(leaf))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FigureWhiteSpace),
				"this is not a filename I can use",
				"because it is either empty or contains only spaces.");
			return;
		}
		filename *figure_file = NULL;
		if (wn >= 0) figure_file = Filenames::in(Task::figures_path(), leaf);
		DISCARD_TEXT(leaf)
		Figures::figures_create(W, id, figure_file, <<alttext>>);
		LOGIF(MULTIMEDIA_CREATIONS, "Created figure <%W> = filename '%f' = resource ID %d\n",
			W, figure_file, id);
	}
}

@<Make sure W is acceptable as a new figure name@> =
	Assertions::Creator::vet_name_for_noun(W);
	if ((<s-value>(W)) &&
		(Rvalues::is_CONSTANT_of_kind(<<rp>>, K_figure_name))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PictureDuplicate),
			"this is already the name of a Figure",
			"so there must be some duplication somewhere.");
		return;
	}

@h One significant kind.

= (early code)
kind *K_figure_name = NULL;

@ This is created by an Inter kit early in Inform's run; the function below
detects that this has happened, and sets |K_figure_name| to point to it.

=
int Figures::figures_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"FIGURE_NAME_TY")) {
		K_figure_name = new_base; return TRUE;
	}
	return FALSE;
}

@h Significant new instances.
This structure of additional data is attached to each figure instance:

=
typedef struct figures_data {
	struct wording name; /* text of name */
	struct filename *filename_of_image_file;
	int figure_number; /* resource number of this picture inside Blorb */
	int alt_description; /* word number of double-quoted description */
	struct instance *as_instance;
	CLASS_DEFINITION
} figures_data;

figures_data *F_cover_art = NULL;

@ We allow instances of "figure name" to be created only through the above
code calling //Figures::figures_create//. If any other proposition somehow
manages to make a figure, a problem message is thrown.

=
int allow_figure_creations = FALSE;

instance *Figures::figures_create(wording W, int id, filename *figure_file, int alt) {
	allow_figure_creations = TRUE;
	Assert::true(Propositions::Abstract::to_create_something(K_figure_name, W), CERTAIN_CE);
	allow_figure_creations = FALSE;
	instance *I = Instances::latest();
	figures_data *figd = PLUGIN_DATA_ON_INSTANCE(figures, I);
	figd->filename_of_image_file = figure_file;
	figd->name = W;
	figd->figure_number = id;
	figd->alt_description = alt;
	figd->as_instance = I;
	if (id == 1) F_cover_art = figd;
	return I;
}

@ =
int Figures::figures_new_named_instance_notify(instance *I) {
	if ((K_figure_name) && (Kinds::eq(Instances::to_kind(I), K_figure_name))) {
		if (allow_figure_creations == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_BackdoorFigureCreation),
				"this is not the way to create a new figure name",
				"which should be done with a special 'Figure ... is the file ...' "
				"sentence.");
		ATTACH_PLUGIN_DATA_TO_SUBJECT(figures, I->as_subject, CREATE(figures_data));
		return TRUE;
	}
	return FALSE;
}

@ The cover art is special, in that it always has ID number 1, and its
description appears in the iFiction metadata for a project.

=
wchar_t *Figures::description_of_cover_art(void) {
	if ((F_cover_art == NULL) || (F_cover_art->alt_description == -1)) return L"";
	return Lexer::word_text(F_cover_art->alt_description);
}

@h Blurb and manifest.
The picture manifest is used by the implementation of Glulx within the
Inform application to connect picture ID numbers with filenames relative
to the Materials folder for its project.

=
void Figures::write_picture_manifest(OUTPUT_STREAM, int include_cover,
	char *cover_art_format) {
	if (PluginManager::active(figures_plugin) == FALSE) return;
	figures_data *figd;
	WRITE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
	WRITE("<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" "
		"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
	WRITE("<plist version=\"1.0\">\n"); INDENT;
	WRITE("<dict>\n"); INDENT;
	WRITE("<key>Graphics</key>\n");
	WRITE("<dict>\n"); INDENT;
	if (include_cover) {
		WRITE("<key>1</key>\n");
		filename *large = NULL;
		if (strcmp(cover_art_format, "jpg") == 0)
			large = Task::large_cover_art_file(TRUE);
		else
			large = Task::large_cover_art_file(FALSE);
		WRITE("<string>%f</string>\n", large);
	}
	LOOP_OVER(figd, figures_data)
		if (figd->figure_number > 1) {
			WRITE("<key>%d</key>\n", figd->figure_number);
			TEMPORARY_TEXT(rel)
			Filenames::to_text_relative(rel, figd->filename_of_image_file,
				Projects::materials_path(Task::project()));
			WRITE("<string>%S</string>\n", rel);
			DISCARD_TEXT(rel)
		}
	OUTDENT; WRITE("</dict>\n");
	Sounds::write_sounds_manifest(OUT);
	OUTDENT; WRITE("</dict>\n");
	OUTDENT; WRITE("</plist>\n");
}

@ The following writes Blurb commands for all of the figures, but not for
the cover art, which is handled by Bibliographic Data.

=
void Figures::write_blurb_commands(OUTPUT_STREAM) {
	if (PluginManager::active(figures_plugin) == FALSE) return;
	figures_data *figd;
	LOOP_OVER(figd, figures_data)
		if (figd->figure_number > 1) {
			wchar_t *desc = L"";
			if (figd->alt_description >= 0)
				desc = Lexer::word_text(figd->alt_description);
			if (Wide::len(desc) > 0)
				WRITE("picture %d \"%f\" \"%N\"\n", figd->figure_number,
					figd->filename_of_image_file, figd->alt_description);
			else
				WRITE("picture %d \"%f\"\n",
					figd->figure_number, figd->filename_of_image_file);
		}
}

@ The following is used only with the "separate figures" release option.

=
void Figures::write_copy_commands(release_instructions *rel) {
	if (PluginManager::active(figures_plugin) == FALSE) return;
	figures_data *figd;
	LOOP_OVER(figd, figures_data)
		if (figd->figure_number > 1)
			ReleaseInstructions::add_aux_file(rel, figd->filename_of_image_file,
				Task::released_figures_path(), L"--", SEPARATE_FIGURES_PAYLOAD);
}

