[ReleaseInstructions::] Release Instructions.

To write the iFiction record for the work of IF compiled, its
release instructions and its picture manifest, if any.

@h Sets of release instructions.
It is hard to imagine that we will ever need to think about two sets of
release instructions at the same time, but for tidiness we still bundle up
everything to do with a release into a singleton instance of the following.

A "zbyte" is a byte from a Z-machine story file.

@d LENGTH_OF_STORY_FILE_HEADER 0x40
@d zbyte unsigned char

=
typedef struct release_instructions {
	int release_website; /* Release along with a website? */
	inchar32_t *website_template_leafname; /* If so, the template name for it */
	int release_interpreter; /* Release along with an interpreter? */
	struct text_stream *interpreter_template_leafname; /* If so, the template name for it */
	int release_booklet; /* Release along with introductory booklet? */
	int release_postcard; /* Release along with Zarf's IF card? */
	int release_cover; /* Release along with cover art? */
	struct parse_node *cover_filename_sentence; /* Where this was requested */
	int cover_alt_text; /* ALT text in case cover is displayed in HTML */
	int release_solution; /* Release along with a solution? */
	int release_source; /* Release along with the source text? */
	int release_card; /* Release along with the iFiction card? */
	int solution_public; /* If released, will this be linked on a website? */
	int source_public; /* If released, will this be linked on a website? */
	int card_public; /* If released, will this be linked on a website? */
	struct linked_list *aux_files; /* of |auxiliary_file| */
	int cover_picture_number; /* ID for the cover art (usually 1) */
	char *cover_art_format; /* such as "jpg" */
	unsigned int width; /* in pixels */
	unsigned int height; /* in pixels */
	zbyte existing_story_header[LENGTH_OF_STORY_FILE_HEADER]; /* a byte array, not a C string */
	CLASS_DEFINITION
} release_instructions;

@ =
release_instructions *ReleaseInstructions::new_set(void) {
	release_instructions *set = CREATE(release_instructions);
	set->release_website = FALSE;
	set->website_template_leafname = U"Standard";
	set->release_interpreter = FALSE;
	set->interpreter_template_leafname = NULL;
	set->release_booklet = FALSE;
	set->release_postcard = FALSE;
	set->release_cover = FALSE;
	set->cover_filename_sentence = NULL;
	set->cover_alt_text = -1;
	set->release_solution = FALSE;
	set->release_source = FALSE;
	set->release_card = FALSE;
	set->solution_public = FALSE;
	set->source_public = TRUE;
	set->card_public = FALSE;
	set->aux_files = NEW_LINKED_LIST(auxiliary_file);
	set->cover_picture_number = 0;
	set->cover_art_format = NULL;
	set->width = 0; set->height = 0;
	for (int i=0; i<LENGTH_OF_STORY_FILE_HEADER; i++) set->existing_story_header[i] = 0;
	return set;
}

@ And this is the singleton set of instructions for our current project:

=
release_instructions *my_instructions = NULL;

void ReleaseInstructions::start(void) {
	my_instructions = ReleaseInstructions::new_set();
}

@ Auxiliary files are not really files to us at all: simply names passed along.
They are the auxiliary files included in the iFiction record generated
for a released project, if the source asks to do so: they might for instance
be maps or booklets which the author intends to accompany the final story
file. (Because they are treated only as names and are never opened, the
following structure contains no file handles.)

=
typedef struct auxiliary_file {
	struct filename *name_of_original_file; /* e.g., "Collegio.pdf" */
	struct pathname *folder_to_release_to; /* e.g., "Sounds" */
	struct text_stream *brief_description; /* e.g., "Collegio Magazine" */
	int from_payload;
	CLASS_DEFINITION
} auxiliary_file;

@ =
void ReleaseInstructions::add_aux_file(release_instructions *rel,
	filename *name, pathname *fold, inchar32_t *desc, int payload) {
	auxiliary_file *af = CREATE(auxiliary_file);
	af->name_of_original_file = name;
	af->folder_to_release_to = fold;
	af->brief_description = Str::new();
	WRITE_TO(af->brief_description, "%w", desc);
	af->from_payload = payload;
	ADD_TO_LINKED_LIST(af, auxiliary_file, rel->aux_files);
}

@h Release with sentences.
A sentence like the following allows for a shopping list of release ingredients:

>> Release along with a public source text and a website.

The object noun phrase is an articled list, and each entry must match this.
Most of the things in this list are "payloads", that is, individual items to
release as part of the complete collection, and these are numbered thus:

@d SOLUTION_PAYLOAD 0
@d SOURCE_TEXT_PAYLOAD 1
@d LIBRARY_CARD_PAYLOAD 2
@d COVER_ART_PAYLOAD 3
@d EXISTING_STORY_FILE_PAYLOAD 4
@d AUXILIARY_FILE_PAYLOAD 5
@d BOOKLET_PAYLOAD 6
@d POSTCARD_PAYLOAD 7
@d WEBSITE_PAYLOAD 8
@d THEMED_WEBSITE_PAYLOAD 9
@d INTERPRETER_PAYLOAD 10
@d THEMED_INTERPRETER_PAYLOAD 11
@d HIDDEN_FILE_PAYLOAD 12
@d HIDDEN_FILE_IN_PAYLOAD 13
@d SEPARATE_FIGURES_PAYLOAD 14
@d SEPARATE_SOUNDS_PAYLOAD 15
@d CSS_PAYLOAD 16
@d JAVASCRIPT_PAYLOAD 17
@d NAMED_EXISTING_STORY_FILE_PAYLOAD 18

=
<release-sentence-object> ::=
	<privacy-indicator> <exposed-innards> |    ==> { R[2], -, <<privacy>> = R[1] }
	<privacy-indicator> ...	|                  ==> @<Issue PM_NoSuchPublicRelease problem@>
	<exposed-innards> |                        ==> { R[1], -, <<privacy>> = NOT_APPLICABLE }
	cover art ( <quoted-text> ) |              ==> { COVER_ART_PAYLOAD, -, <<alttext>> = R[1] }
	cover art |                                ==> { COVER_ART_PAYLOAD, -, <<alttext>> = -1 }
	existing story file |                      ==> { EXISTING_STORY_FILE_PAYLOAD, - }
	existing story file called {<quoted-text-without-subs>} |  ==> { NAMED_EXISTING_STORY_FILE_PAYLOAD, - }
	file of {<quoted-text-without-subs>} called {<quoted-text-without-subs>} |  ==> { AUXILIARY_FILE_PAYLOAD, - }
	file {<quoted-text-without-subs>} in {<quoted-text-without-subs>} |  ==> { HIDDEN_FILE_IN_PAYLOAD, - }
	file {<quoted-text-without-subs>} |        ==> { HIDDEN_FILE_PAYLOAD, - }
	style sheet {<quoted-text-without-subs>} | ==> { CSS_PAYLOAD, - }
	javascript {<quoted-text-without-subs>} |  ==> { JAVASCRIPT_PAYLOAD, - }
	introductory booklet |                     ==> { BOOKLET_PAYLOAD, - }
	introductory postcard |                    ==> { POSTCARD_PAYLOAD, - }
	website |                                  ==> { WEBSITE_PAYLOAD, - }
	separate figures |                         ==> { SEPARATE_FIGURES_PAYLOAD, - }
	separate sounds |                          ==> { SEPARATE_SOUNDS_PAYLOAD, - }
	{<quoted-text-without-subs>} website |     ==> { THEMED_WEBSITE_PAYLOAD, - }
	interpreter |                              ==> { INTERPRETER_PAYLOAD, - }
	{<quoted-text-without-subs>} interpreter   ==> { THEMED_INTERPRETER_PAYLOAD, - }

@<Issue PM_NoSuchPublicRelease problem@> =
	Problems::quote_wording_as_source(1, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoSuchPublicRelease));
	Problems::issue_problem_segment(
		"I don't know how to release along with %1: the only features of "
		"a release which can be marked as public or private are the 'source "
		"text', 'solution' and 'library card'.");
	Problems::issue_problem_end();
	==> { BOOKLET_PAYLOAD, - }; /* to recover harmlessly */

@ Three of the secret ingredients of a project which can be released, and can
optionally be marked "public" (they appear on any website about it) or
"private" (they don't).

=
<privacy-indicator> ::=
	private |
	public

<exposed-innards> ::=
	solution |
	source text |
	library card

@ And here is the special meaning function which uses the grammar above. Note
that we accept almost any sentence here -- but that this is because the meaning
is only given for sentences beginning "Release with...".

=
int ReleaseInstructions::release_along_with_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Use American dialect." */
		case ACCEPT_SMFT:
			<np-articled-list>(OW);
			V->next = <<rp>>;
			return TRUE;
		case ALLOW_IN_OPTIONS_FILE_SMFT:
			return TRUE;
		case PASS_1_SMFT:
			ReleaseInstructions::handle_release_declaration_inner(V->next);
			break;
	}
	return FALSE;
}

void ReleaseInstructions::handle_release_declaration_inner(parse_node *p) {
	if (Node::get_type(p) == AND_NT) {
		ReleaseInstructions::handle_release_declaration_inner(p->down);
		ReleaseInstructions::handle_release_declaration_inner(p->down->next);
		return;
	}
	current_sentence = p;
	if (<release-sentence-object>(Node::get_text(p)))
		@<Respond to an individual release instruction@>
	else
		@<Issue a bad release instruction problem message@>;
}

@ 

@<Respond to an individual release instruction@> =
	int payload = <<r>>;
	switch (payload) {
		case SOLUTION_PAYLOAD:
			my_instructions->release_solution = TRUE;
			if (<<privacy>> != NOT_APPLICABLE) my_instructions->solution_public = <<privacy>>;
			break;
		case SOURCE_TEXT_PAYLOAD:
			my_instructions->release_source = TRUE;
			if (<<privacy>> != NOT_APPLICABLE) my_instructions->source_public = <<privacy>>;
			break;
		case LIBRARY_CARD_PAYLOAD:
			my_instructions->release_card = TRUE;
			if (<<privacy>> != NOT_APPLICABLE) my_instructions->card_public = <<privacy>>;
			break;
		case COVER_ART_PAYLOAD:
			my_instructions->release_cover = TRUE;
			my_instructions->cover_alt_text = <<alttext>>;
			my_instructions->cover_filename_sentence = current_sentence;
			break;
		case EXISTING_STORY_FILE_PAYLOAD:
		case NAMED_EXISTING_STORY_FILE_PAYLOAD:
			if (TargetVMs::is_16_bit(Task::vm()) == FALSE) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(Untestable),
					"existing story files can only be used with the Z-machine",
					"not with the Glulx setting.");
				return;
			}
			if (payload == NAMED_EXISTING_STORY_FILE_PAYLOAD) {
				wording SW = GET_RW(<release-sentence-object>, 1);
				Word::dequote(Wordings::first_wn(SW));
				TEMPORARY_TEXT(leaf)
				WRITE_TO(leaf, "%N", Wordings::first_wn(SW));
				Task::set_existing_storyfile(leaf);
				DISCARD_TEXT(leaf)
			} else {
				Task::set_existing_storyfile(NULL);
			}
			break;
		case AUXILIARY_FILE_PAYLOAD: {
			wording DW = GET_RW(<release-sentence-object>, 1);
			wording LW = GET_RW(<release-sentence-object>, 2);
			Word::dequote(Wordings::first_wn(LW));
			Word::dequote(Wordings::first_wn(DW));
			TEMPORARY_TEXT(leaf)
			WRITE_TO(leaf, "%N", Wordings::first_wn(LW));
			filename *A = Filenames::in(Projects::materials_path(Task::project()), leaf);
			DISCARD_TEXT(leaf)
			ReleaseInstructions::add_aux_file(my_instructions, A,
				Task::release_path(),
				Lexer::word_text(Wordings::first_wn(DW)),
				payload);
			break;
		}
		case CSS_PAYLOAD: case JAVASCRIPT_PAYLOAD: case HIDDEN_FILE_PAYLOAD: {
			wording LW = GET_RW(<release-sentence-object>, 1);
			Word::dequote(Wordings::first_wn(LW));
			TEMPORARY_TEXT(leaf)
			WRITE_TO(leaf, "%N", Wordings::first_wn(LW));
			filename *A = Filenames::in(Projects::materials_path(Task::project()), leaf);
			DISCARD_TEXT(leaf)
			ReleaseInstructions::add_aux_file(my_instructions, A,
				Task::release_path(),
				U"--",
				payload);
			break;
		}
		case HIDDEN_FILE_IN_PAYLOAD: {
			wording LW = GET_RW(<release-sentence-object>, 1);
			wording FW = GET_RW(<release-sentence-object>, 2);
			Word::dequote(Wordings::first_wn(LW));
			Word::dequote(Wordings::first_wn(FW));
			TEMPORARY_TEXT(leaf)
			WRITE_TO(leaf, "%N", Wordings::first_wn(LW));
			filename *A = Filenames::in(Projects::materials_path(Task::project()), leaf);
			DISCARD_TEXT(leaf)
			TEMPORARY_TEXT(folder)
			WRITE_TO(folder, "%N", Wordings::first_wn(FW));
			pathname *P = Pathnames::down(Task::release_path(), folder);
			DISCARD_TEXT(folder)
			ReleaseInstructions::add_aux_file(my_instructions, A, P, U"--", payload);
			break;
		}
		case BOOKLET_PAYLOAD: my_instructions->release_booklet = TRUE; break;
		case POSTCARD_PAYLOAD: my_instructions->release_postcard = TRUE; break;
		case WEBSITE_PAYLOAD: my_instructions->release_website = TRUE; break;
		case THEMED_WEBSITE_PAYLOAD: {
			wording TW = GET_RW(<release-sentence-object>, 1);
			Word::dequote(Wordings::first_wn(TW));
			my_instructions->website_template_leafname = Lexer::word_text(Wordings::first_wn(TW));
			my_instructions->release_website = TRUE;
			break;
		}
		case INTERPRETER_PAYLOAD:
			my_instructions->release_interpreter = TRUE; my_instructions->release_website = TRUE;
			break;
		case THEMED_INTERPRETER_PAYLOAD: {
			wording TW = GET_RW(<release-sentence-object>, 1);
			Word::dequote(Wordings::first_wn(TW));
			my_instructions->interpreter_template_leafname = Str::new();
			WRITE_TO(my_instructions->interpreter_template_leafname, "%W", TW);
			my_instructions->release_interpreter = TRUE; my_instructions->release_website = TRUE;
			break;
		}
		case SEPARATE_FIGURES_PAYLOAD:
			Figures::write_copy_commands(my_instructions);
			break;
		case SEPARATE_SOUNDS_PAYLOAD:
			Sounds::write_copy_commands(my_instructions);
			break;
	}

@<Issue a bad release instruction problem message@> =
	Problems::quote_source(1, p);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReleaseAlong));
	Problems::issue_problem_segment(
		"I don't know how to release along with %1: the only forms I can "
		"accept are - 'Release along with cover art', '...a website', "
		"'the solution', 'the library card', 'the introductory booklet', "
		"'the source text', 'an existing story file' or '...a file of "
		"\"Something Useful\" called \"Something.pdf\"'.");
	Problems::issue_problem_end();

@h Writing out files.
So much for taking down instructions; now we must act on them. In this
routine we combine writing the iFiction record and the release instructions --
done together since they have so much in common, being essentially two ways
of writing the same thing.

=
void ReleaseInstructions::write_ifiction_and_blurb(void) {
	if (Projects::stand_alone(Task::project())) return;
	release_instructions *rel = my_instructions;
	if (ReleaseInstructions::ensure_Materials(rel) == FALSE) return;
	if (ReleaseInstructions::check_cover_art(rel) == FALSE) return;
	if (Task::wraps_existing_storyfile()) {
		if (ReleaseInstructions::read_existing_header(rel) == FALSE) return;
	}
	if (problem_count == 0) {
		@<Write iFiction record@>;
		@<Write licenses file@>;
		@<Write release blurb@>;
		@<Write manifest file@>;
	}
	return;
}

@<Write iFiction record@> =
	text_stream xf_struct; text_stream *xf = &xf_struct;
	filename *F = Task::ifiction_record_file();
	if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open metadata file", F);
	iFiction::write_ifiction_record(xf, rel);
	STREAM_CLOSE(xf);

@<Write licenses file@> =
	if (LicenceDeclaration::anything_to_declare()) {
		text_stream xf_struct; text_stream *xf = &xf_struct;
		filename *F = Task::licenses_file(my_instructions->release_website);
		if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
			Problems::fatal_on_file("Can't open metadata file", F);
		int format = PLAIN_LICENSESFORMAT;
		if (my_instructions->release_website) format = HTML_LICENSESFORMAT;
		LicenceDeclaration::describe(xf, format);
		STREAM_CLOSE(xf);
	}

@<Write release blurb@> =
	filename *F = Task::blurb_file();
	text_stream xf_struct; text_stream *xf = &xf_struct;
	if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open blurb file", F);
	BlurbFile::write(xf, rel);
	STREAM_CLOSE(xf);

@<Write manifest file@> =
	filename *F = Task::manifest_file();
	text_stream xf_struct; text_stream *xf = &xf_struct;
	if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open manifest file", F);
	Figures::write_picture_manifest(xf, rel->release_cover, rel->cover_art_format);
	STREAM_CLOSE(xf);

@h Cover art, if any.
We find out the format of the cover art and see that its dimensions conform
to Treaty of Babel requirements.

=
int ReleaseInstructions::check_cover_art(release_instructions *rel) {
	rel->cover_picture_number = (rel->release_cover)?1:0;
	if (rel->release_cover) {
		current_sentence = rel->cover_filename_sentence;
		rel->cover_art_format = "";
		filename *cover_filename = Task::large_cover_art_file(TRUE);
		FILE *COVER_FILE = Filenames::fopen(cover_filename, "rb" );
		if (COVER_FILE) @<The cover seems to be a JPEG@>
		else {
			cover_filename = Task::large_cover_art_file(FALSE);
			COVER_FILE = Filenames::fopen(cover_filename, "rb" );
			if (COVER_FILE) @<The cover seems to be a PNG@>
			else @<There seems to be no cover at all@>;
		}
		@<Check that the pixel height and width are sensible@>;
	}
	return TRUE;
}

@<The cover seems to be a JPEG@> =
	rel->cover_art_format = "jpg";
	int rv = ImageFiles::get_JPEG_dimensions(COVER_FILE, &rel->width, &rel->height);
	fclose(COVER_FILE);
	if (rv == FALSE) {
		StandardProblems::release_problem(_p_(Untestable),
			"The cover image seems not to be a JPEG despite the name",
			cover_filename);
		return FALSE;
	}

@<The cover seems to be a PNG@> =
	rel->cover_art_format = "png";
	int rv = ImageFiles::get_PNG_dimensions(COVER_FILE, &rel->width, &rel->height);
	fclose(COVER_FILE);
	if (rv == FALSE) {
		StandardProblems::release_problem(_p_(Untestable),
			"The cover image seems not to be a PNG despite the name",
			cover_filename);
		return FALSE;
	}

@<There seems to be no cover at all@> =
	StandardProblems::release_problem_at_sentence(_p_(Untestable),
		"The release instructions said that there is a cover image "
		"to attach to the story file, but I was unable to find it, "
		"having looked for both 'Cover.png' and 'Cover.jpg' in the "
		"'.materials' folder for this project", cover_filename);
	return FALSE;

@<Check that the pixel height and width are sensible@> =
	if ((rel->width < 120) || (rel->width > 1200) ||
		(rel->height < 120) || (rel->height > 1200)) {
		StandardProblems::release_problem(_p_(Untestable),
			"The height and width of the cover image, in pixels, must be "
			"between 120 and 1024 inclusive",
			cover_filename);
		return FALSE;
	}
	if ((rel->width > 2*rel->height) || (rel->height > 2*rel->width)) {
		StandardProblems::release_problem(_p_(Untestable),
			"We recommend a square cover image, but at any rate it is "
			"required to be no more rectangular than twice as wide as it "
			"is high (or vice versa)",
			cover_filename);
		return FALSE;
	}

@h Existing story file headers.

=
int ReleaseInstructions::read_existing_header(release_instructions *rel) {
	if (Projects::currently_releasing(Task::project()) == FALSE)
		@<Issue a problem if this isn't a Release run@>;
	FILE *STORYF = Filenames::fopen(Task::existing_storyfile_file(), "rb");
	if (STORYF == NULL) {
		StandardProblems::unlocated_problem_on_file(Task::syntax_tree(), 
			_p_(Untestable),
			"The instruction 'Release along with an existing story file' "
			"means that I need to bind up a story file called '%1', in "
			"the .materials folder for this project. But it doesn't seem "
			"to be there.", Task::existing_storyfile_file());
		return FALSE;
	}
	for (int i=0; i<LENGTH_OF_STORY_FILE_HEADER; i++) {
		int c = fgetc(STORYF);
		if (c == EOF) rel->existing_story_header[i] = 0;
		else rel->existing_story_header[i] = (zbyte) c;
	}
	fclose(STORYF);
	return TRUE;
}

@<Issue a problem if this isn't a Release run@> =
	StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(PM_UnreleasedRelease),
		"This is supposed to be a source text which only contains "
		"release instructions to bind up an existing story file "
		"(for instance, one produced using Inform 6). That's because "
		"the instruction 'Release along with an existing story file' "
		"is present. So the only way to build the project is to use "
		"the Release option - not, for instance, Go or Replay, because "
		"it would make no sense to translate the source text into "
		"something to play. (Of course, you can play the released "
		"story file using an interpreter such as Zoom or Windows "
		"Frotz, etc.: just not here, within Inform.)");
	return FALSE;

@h Releasing and the Materials folder.
Until March 2010, Materials folders weren't needed for very simple releases;
but they were needed for absolutely everything else. In the end we simplified
matters by always releasing to a Materials folder, though the advent of
application sandboxing in Mac OS X made this troublesome for a while in 2012,
when we had to change the filenaming convention to comply.

=
int ReleaseInstructions::ensure_Materials(release_instructions *rel) {
	@<Create the Materials folder if not already present@>;
	@<Create the Release subfolder if not already present@>;
	if (rel->release_interpreter)
		@<Create the Interpreter subfolder if not already present@>;
	return TRUE;
}

@<Create the Materials folder if not already present@> =
	if (Pathnames::create_in_file_system(
		Projects::materials_path(Task::project())) == FALSE) {
		StandardProblems::release_problem_path(_p_(Untestable),
			"In order to release the story file along with other "
			"resources, I tried to create a folder alongside this "
			"Inform project, but was unable to do so. The folder "
			"was to have been called",
			Projects::materials_path(Task::project()));
		return FALSE;
	}

@<Create the Release subfolder if not already present@> =
	if (Pathnames::create_in_file_system(Task::release_path()) == FALSE) {
		StandardProblems::release_problem_path(_p_(Untestable),
			"In order to release the story file along with other "
			"resources, I tried to create a folder alongside this "
			"Inform project, but was unable to do so. The folder "
			"was to have been called",
			Task::release_path());
		return FALSE;
	}
	auxiliary_file *af;
	LOOP_OVER_LINKED_LIST(af, auxiliary_file, rel->aux_files)
		if (Pathnames::create_in_file_system(af->folder_to_release_to) == FALSE) {
			StandardProblems::release_problem_path(_p_(Untestable),
				"In order to release the story file along with other "
				"resources, I tried to create a folder alongside this "
				"Inform project, but was unable to do so. The folder "
				"was to have been called",
				af->folder_to_release_to);
			return FALSE;
		}

@<Create the Interpreter subfolder if not already present@> =
	if (Pathnames::create_in_file_system(Task::released_interpreter_path()) == FALSE) {
		StandardProblems::release_problem_path(_p_(Untestable),
			"In order to release the story file along with an "
			"interpreter, I tried to create a folder alongside this "
			"Inform project, but was unable to do so. The folder "
			"was to have been called",
			Task::released_interpreter_path());
		return FALSE;
	}
