[PL::Bibliographic::Release::] Release Instructions.

To write the iFiction record for the work of IF compiled, its
release instructions and its picture manifest, if any.

@ Much of this section is best understood by reference to the Treaty of
Babel, a cross-IF-system standard for bibliographic data and packaging
agreed between the major IF design systems in 2006. Inform aims to comply
fully with the Treaty and the code below should be maintained as such.

@ The following somewhat miscellaneous variables hold the instructions given
in the source text for how to release the story file -- the content of
any "Release along with..." sentences, in fact.

=
int release_website = FALSE; /* Release along with a website? */
wchar_t *website_template_leafname = L"Standard"; /* If so, the template name for it */
int release_interpreter = FALSE; /* Release along with an interpreter? */
text_stream *interpreter_template_leafname = NULL; /* If so, the template name for it */
int release_booklet = FALSE; /* Release along with introductory booklet? */
int release_postcard = FALSE; /* Release along with Zarf's IF card? */
int release_cover = FALSE; /* Release along with cover art? */
parse_node *cover_filename_sentence = NULL; /* Where this was requested */
int cover_alt_text = -1; /* ALT text in case cover is displayed in HTML */
int release_solution = FALSE; /* Release along with a solution? */
int release_source = FALSE; /* Release along with the source text? */
int release_card = FALSE; /* Release along with the iFiction card? */
int solution_public = FALSE; /* If released, will this be linked on a website? */
int source_public = TRUE; /* If released, will this be linked on a website? */
int card_public = FALSE; /* If released, will this be linked on a website? */
int create_Materials = FALSE; /* Create a Materials folder if one doesn't exist already */

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

@ A sentence like this allows for a shopping list of release ingredients:

>> Release along with a public source text and a website.

The object noun phrase is an articled list, and each entry must match this.

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

@ And here is the handling code which uses the grammar above:

=
int PL::Bibliographic::Release::release_along_with_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Use American dialect." */
		case ACCEPT_SMFT:
			<np-articled-list>(OW);
			V->next = <<rp>>;
			return TRUE;
		case ALLOW_IN_OPTIONS_FILE_SMFT:
			return TRUE;
		case PASS_1_SMFT:
			PL::Bibliographic::Release::handle_release_declaration_inner(V->next);
			break;
	}
	return FALSE;
}

@ =
void PL::Bibliographic::Release::visit_to_quote(OUTPUT_STREAM, parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down)) {
		special_meaning_holder *sm = Node::get_special_meaning(p->down);
		if (SpecialMeanings::is(sm, PL::Bibliographic::Release::release_along_with_SMF)) {
			TEMPORARY_TEXT(TEMP)
			Index::link_to(TEMP, Wordings::first_wn(Node::get_text(p)), TRUE);
			WRITE("status instruction ||");
			STREAM_COPY(OUT, TEMP);
			WRITE("||\n");
			DISCARD_TEXT(TEMP)
		}
	}
}

void PL::Bibliographic::Release::handle_release_declaration(parse_node *p) {
	PL::Bibliographic::Release::handle_release_declaration_inner(p->down->next);
}

void PL::Bibliographic::Release::handle_release_declaration_inner(parse_node *p) {
	if (Node::get_type(p) == AND_NT) {
		PL::Bibliographic::Release::handle_release_declaration_inner(p->down);
		PL::Bibliographic::Release::handle_release_declaration_inner(p->down->next);
		return;
	}
	current_sentence = p;
	if (<release-sentence-object>(Node::get_text(p)))
		@<Respond to an individual release instruction@>
	else
		@<Issue a bad release instruction problem message@>;
}

@ The items to release are called "payloads".

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

@<Respond to an individual release instruction@> =
	int payload = <<r>>;
	switch (payload) {
		case SOLUTION_PAYLOAD:
			release_solution = TRUE;
			if (<<privacy>> != NOT_APPLICABLE) solution_public = <<privacy>>;
			break;
		case SOURCE_TEXT_PAYLOAD:
			release_source = TRUE;
			if (<<privacy>> != NOT_APPLICABLE) source_public = <<privacy>>;
			break;
		case LIBRARY_CARD_PAYLOAD:
			release_card = TRUE;
			if (<<privacy>> != NOT_APPLICABLE) card_public = <<privacy>>;
			break;
		case COVER_ART_PAYLOAD:
			release_cover = TRUE;
			cover_alt_text = <<alttext>>;
			cover_filename_sentence = current_sentence;
			break;
		case EXISTING_STORY_FILE_PAYLOAD:
		case NAMED_EXISTING_STORY_FILE_PAYLOAD:
			if (TargetVMs::is_16_bit(Task::vm()) == FALSE) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* not usefully testable */
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
			PL::Bibliographic::Release::create_aux_file(A,
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
			PL::Bibliographic::Release::create_aux_file(A,
				Task::release_path(),
				L"--",
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
			PL::Bibliographic::Release::create_aux_file(A, P, L"--", payload);
			break;
		}
		case BOOKLET_PAYLOAD: release_booklet = TRUE; break;
		case POSTCARD_PAYLOAD: release_postcard = TRUE; break;
		case WEBSITE_PAYLOAD: release_website = TRUE; break;
		case THEMED_WEBSITE_PAYLOAD: {
			wording TW = GET_RW(<release-sentence-object>, 1);
			Word::dequote(Wordings::first_wn(TW));
			website_template_leafname = Lexer::word_text(Wordings::first_wn(TW));
			release_website = TRUE;
			break;
		}
		case INTERPRETER_PAYLOAD:
			release_interpreter = TRUE; release_website = TRUE;
			break;
		case THEMED_INTERPRETER_PAYLOAD: {
			wording TW = GET_RW(<release-sentence-object>, 1);
			Word::dequote(Wordings::first_wn(TW));
			interpreter_template_leafname = Str::new();
			WRITE_TO(interpreter_template_leafname, "%W", Wordings::first_wn(TW));
			release_interpreter = TRUE; release_website = TRUE;
			break;
		}
		case SEPARATE_FIGURES_PAYLOAD:
			PL::Figures::write_copy_commands();
			break;
		case SEPARATE_SOUNDS_PAYLOAD:
			PL::Sounds::write_copy_commands();
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

@ =
auxiliary_file *PL::Bibliographic::Release::create_aux_file(filename *name,
	pathname *fold, wchar_t *desc, int payload) {
	auxiliary_file *af = CREATE(auxiliary_file);
	af->name_of_original_file = name;
	af->folder_to_release_to = fold;
	af->brief_description = Str::new();
	WRITE_TO(af->brief_description, "%w", desc);
	af->from_payload = payload;
	return af;
}

@ So much for taking down instructions; now we must act on them. In this
routine we combine writing the iFiction record and the release instructions --
done together since they have so much in common, being essentially two ways
of writing the same thing.

@d LENGTH_OF_STORY_FILE_HEADER 0x40

@d zbyte unsigned char

=
void PL::Bibliographic::Release::write_ifiction_and_blurb(void) {
	@<Decide whether we need to create a Materials folder@>;

	int cover_picture_number = (release_cover)?1:0;
	char *cover_art_format = NULL;
	unsigned int width = 0, height = 0;
	@<Check cover art image if any@>;

	zbyte header[LENGTH_OF_STORY_FILE_HEADER]; /* a sequence of bytes, not a C string */
	if (Task::wraps_existing_storyfile()) @<Read header of existing story file if present@>

	if (problem_count == 0) @<Finally, write out our three metadata files@>;
}

@ Until March 2010, Materials folders weren't needed for very simple releases;
but they were needed for absolutely everything else. In the end we simplified
matters by always releasing to a Materials folder, though the advent of
application sandboxing in Mac OS X in 2012 may force us to revisit this.

@<Decide whether we need to create a Materials folder@> =
	create_Materials = TRUE; /* thus making the next condition irrelevant */
	if ((release_website) || (release_interpreter) || (release_booklet) || (release_postcard) ||
		(release_cover) || (release_source) || (release_card) || (release_solution) ||
		(Task::wraps_existing_storyfile()) || (NUMBER_CREATED(blorb_figure) > 1)) {
		create_Materials = TRUE;
	}
	if (create_Materials) {
		@<Create the Materials folder if not already present@>;
		@<Create the Release subfolder if not already present@>;
		if (release_interpreter) @<Create the Interpreter subfolder if not already present@>;
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
		return;
	}

@<Create the Release subfolder if not already present@> =
	if (Pathnames::create_in_file_system(Task::release_path()) == FALSE) {
		StandardProblems::release_problem_path(_p_(Untestable),
			"In order to release the story file along with other "
			"resources, I tried to create a folder alongside this "
			"Inform project, but was unable to do so. The folder "
			"was to have been called",
			Task::release_path());
		return;
	}
	auxiliary_file *af;
	LOOP_OVER(af, auxiliary_file)
		if (Pathnames::create_in_file_system(af->folder_to_release_to) == FALSE) {
			StandardProblems::release_problem_path(_p_(Untestable),
				"In order to release the story file along with other "
				"resources, I tried to create a folder alongside this "
				"Inform project, but was unable to do so. The folder "
				"was to have been called",
				af->folder_to_release_to);
			return;
		}

@<Create the Interpreter subfolder if not already present@> =
	if (Pathnames::create_in_file_system(Task::released_interpreter_path()) == FALSE) {
		StandardProblems::release_problem_path(_p_(Untestable),
			"In order to release the story file along with an "
			"interpreter, I tried to create a folder alongside this "
			"Inform project, but was unable to do so. The folder "
			"was to have been called",
			Task::released_interpreter_path());
		return;
	}

@ Using the utility routines above, we find out the format of the cover
art and see that its dimensions conform to Treaty of Babel requirements.

@<Check cover art image if any@> =
	if (release_cover) {
		current_sentence = cover_filename_sentence;
		cover_art_format = "";
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

@<The cover seems to be a JPEG@> =
	cover_art_format = "jpg";
	int rv = ImageFiles::get_JPEG_dimensions(COVER_FILE, &width, &height);
	fclose(COVER_FILE);
	if (rv == FALSE) {
		StandardProblems::release_problem(_p_(Untestable),
			"The cover image seems not to be a JPEG despite the name",
			cover_filename);
		return;
	}

@<The cover seems to be a PNG@> =
	cover_art_format = "png";
	int rv = ImageFiles::get_PNG_dimensions(COVER_FILE, &width, &height);
	fclose(COVER_FILE);
	if (rv == FALSE) {
		StandardProblems::release_problem(_p_(Untestable),
			"The cover image seems not to be a PNG despite the name",
			cover_filename);
		return;
	}

@<There seems to be no cover at all@> =
	StandardProblems::release_problem_at_sentence(_p_(Untestable),
		"The release instructions said that there is a cover image "
		"to attach to the story file, but I was unable to find it, "
		"having looked for both 'Cover.png' and 'Cover.jpg' in the "
		"'.materials' folder for this project", cover_filename);
	return;

@<Check that the pixel height and width are sensible@> =
	if ((width < 120) || (width > 1200) || (height < 120) || (height > 1200)) {
		StandardProblems::release_problem(_p_(Untestable),
			"The height and width of the cover image, in pixels, must be "
			"between 120 and 1024 inclusive",
			cover_filename);
		return;
	}
	if ((width > 2*height) || (height > 2*width)) {
		StandardProblems::release_problem(_p_(Untestable),
			"We recommend a square cover image, but at any rate it is "
			"required to be no more rectangular than twice as wide as it "
			"is high (or vice versa)",
			cover_filename);
		return;
	}

@<Read header of existing story file if present@> =
	if (Projects::currently_releasing(Task::project()) == FALSE)
		@<Issue a problem if this isn't a Release run@>;
	FILE *STORYF = Filenames::fopen(Task::existing_storyfile_file(), "rb");
	if (STORYF == NULL) {
		StandardProblems::unlocated_problem_on_file(Task::syntax_tree(), 
			_p_(BelievedImpossible), /* i.e., not testable by intest */
			"The instruction 'Release along with an existing story file' "
			"means that I need to bind up a story file called '%1', in "
			"the .materials folder for this project. But it doesn't seem "
			"to be there.", Task::existing_storyfile_file());
		return;
	}
	int i;
	for (i=0; i<LENGTH_OF_STORY_FILE_HEADER; i++) {
		int c = fgetc(STORYF);
		if (c == EOF) header[i] = 0;
		else header[i] = (zbyte) c;
	}
	fclose(STORYF);

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
	return;

@ That's it for the preliminaries: time to do some actual work.

@<Finally, write out our three metadata files@> =
	@<Write iFiction record@>;
	@<Write release blurb@>;
	@<Write manifest file@>;

@<Write iFiction record@> =
	text_stream xf_struct; text_stream *xf = &xf_struct;
	filename *F = Task::ifiction_record_file();
	if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open metadata file", F);
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(COMPILE_TEXT_TO_XML_CMODE);
	PL::Bibliographic::Release::write_ifiction_record(xf, header, cover_picture_number, cover_art_format, height, width);
	END_COMPILATION_MODE;
	STREAM_CLOSE(xf);

@<Write release blurb@> =
	filename *F = Task::blurb_file();
	text_stream xf_struct; text_stream *xf = &xf_struct;
	if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open blurb file", F);
	PL::Bibliographic::Release::write_release_blurb(xf, cover_picture_number, cover_art_format);
	STREAM_CLOSE(xf);

@<Write manifest file@> =
	filename *F = Task::manifest_file();
	text_stream xf_struct; text_stream *xf = &xf_struct;
	if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open manifest file", F);
	PL::Figures::write_picture_manifest(xf, release_cover, cover_art_format);
	STREAM_CLOSE(xf);

@ For the format of this file, see the Treaty of Babel.

=
void PL::Bibliographic::Release::write_ifiction_record(OUTPUT_STREAM, zbyte *header,
	int cover_picture_number, char *cover_art_format,
	unsigned int height, unsigned int width) {
	WRITE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
	WRITE("<ifindex version=\"1.0\" "
		"xmlns=\"http://babel.ifarchive.org/protocol/iFiction/\">\n"); INDENT;
	WRITE("<story>\n"); INDENT;
	@<Write the body of the iFiction record@>;
	OUTDENT; WRITE("</story>\n");
	OUTDENT; WRITE("</ifindex>\n");
}

@<Write the body of the iFiction record@> =
	text_stream *story_format = TargetVMs::get_iFiction_format(Task::vm());

	@<Write the identification tag of the iFiction record@>;
	@<Write the bibliographic tag of the iFiction record@>;
	if (NUMBER_CREATED(auxiliary_file) > 0)
		@<Write the resources tag of the iFiction record@>;
	if (release_cover)
		@<Write the cover tag of the iFiction record@>;
	@<Write the releases tag of the iFiction record@>;
	@<Write the colophon tag of the iFiction record@>;
	WRITE("<%S>\n", story_format); INDENT;
	@<Write the format-specific tag of the iFiction record@>;
	OUTDENT; WRITE("</%S>\n", story_format);

@<Write the identification tag of the iFiction record@> =
	WRITE("<identification>\n"); INDENT;
	WRITE("<ifid>%S</ifid>\n", PL::Bibliographic::IFID::read_uuid());
	if (Task::wraps_existing_storyfile()) {
		WRITE("<ifid>ZCODE-%d-%c%c%c%c%c%c",
			header[2]*256+header[3],
			header[0x12], header[0x13], header[0x14],
			header[0x15], header[0x16], header[0x17]);
		if ((header[0x12] != '8') || (Characters::isdigit(header[0x12])))
			WRITE("-%04x", header[0x1c]*256 + header[0x1d]);
		WRITE("</ifid>\n");
	}
	WRITE("<format>%S</format>\n", story_format);
	OUTDENT; WRITE("</identification>\n");

@<Write the bibliographic tag of the iFiction record@> =
	WRITE("<bibliographic>\n"); INDENT;
	WRITE("<title>");
	if (PL::Bibliographic::Release::write_var_to_XML(OUT, story_title_VAR, FALSE) == FALSE) WRITE("Untitled");
	WRITE("</title>\n");
	WRITE("<author>");
	if (PL::Bibliographic::Release::write_var_to_XML(OUT, story_author_VAR, FALSE) == FALSE) WRITE("Anonymous");
	WRITE("</author>\n");
	WRITE("<headline>");
	if (PL::Bibliographic::Release::write_var_to_XML(OUT, story_headline_VAR, FALSE) == FALSE)
		WRITE("An Interactive Fiction");
	WRITE("</headline>\n");
	WRITE("<genre>");
	if (PL::Bibliographic::Release::write_var_to_XML(OUT, story_genre_VAR, FALSE) == FALSE) WRITE("Fiction");
	WRITE("</genre>\n");
	WRITE("<firstpublished>");
	if (PL::Bibliographic::Release::write_var_to_XML(OUT, story_creation_year_VAR, FALSE) == FALSE)
		WRITE("%d", (the_present->tm_year)+1900);
	WRITE("</firstpublished>\n");
	if (NonlocalVariables::has_initial_value_set(story_description_VAR)) {
		WRITE("<description>");
		PL::Bibliographic::Release::write_var_to_XML(OUT, story_description_VAR, TRUE);
		WRITE("</description>\n");
	}
	WRITE("<language>");
	Languages::write_ISO_code(OUT, Projects::get_language_of_play(Task::project()));
	WRITE("</language>\n");
	WRITE("<group>Inform</group>\n");
	if (episode_number >= 0) {
		WRITE("<seriesnumber>%d</seriesnumber>\n", episode_number);
		WRITE("<series>%w</series>\n", series_name);
	}
	OUTDENT; WRITE("</bibliographic>\n");

@<Write the resources tag of the iFiction record@> =
	auxiliary_file *af;
	WRITE("<resources>\n"); INDENT;
	LOOP_OVER(af, auxiliary_file) {
		WRITE("<auxiliary>\n"); INDENT;
		WRITE("<leafname>");
		TEMPORARY_TEXT(rel)
		Filenames::to_text_relative(rel, af->name_of_original_file,
			Projects::materials_path(Task::project()));
		HTML::write_xml_safe_text(OUT, rel);
		DISCARD_TEXT(rel)
		WRITE("</leafname>\n");
		if (Str::len(af->brief_description) > 0) {
			WRITE("<description>");
			HTML::write_xml_safe_text(OUT, af->brief_description);
			WRITE("</description>\n");
		}
		OUTDENT; WRITE("</auxiliary>\n");
	}
	OUTDENT; WRITE("</resources>\n");

@ The |<description>| key here was added in version 8 of the Treaty of Babel,
in February 2014.

@<Write the cover tag of the iFiction record@> =
	WRITE("<cover>\n"); INDENT;
	WRITE("<format>%s</format>\n", cover_art_format);
	WRITE("<height>%d</height>\n", height);
	WRITE("<width>%d</width>\n", width);
	if (cover_alt_text >= 0) {
		Word::dequote(cover_alt_text);
		WRITE("<description>%N</description>\n", cover_alt_text);
	} else {
		WRITE("<description>%w</description>\n", PL::Figures::description_of_cover_art());
	}
	OUTDENT; WRITE("</cover>\n");

@<Write the releases tag of the iFiction record@> =
	WRITE("<releases>\n"); INDENT;
	WRITE("<attached>\n"); INDENT;
	WRITE("<release>\n"); INDENT;
	if (Task::wraps_existing_storyfile()) @<Write release data for an existing story file@>
	else @<Write release data for an Inform 7 project@>;
	OUTDENT; WRITE("</release>\n");
	OUTDENT; WRITE("</attached>\n");
	OUTDENT; WRITE("</releases>\n");

@ ZILCH was Infocom's in-house compiler of Z-machine story files, and prior
to Inform the only one to exist. Inform differs from it in using the last four
bytes of the header to store its own version number.

(The following code will be incorrect on 1 January 2080.)

@<Write release data for an existing story file@> =
	WRITE("<releasedate>%s%c%c-%c%c-%c%c</releasedate>\n",
		((Characters::isdigit(header[0x12])) &&
			(header[0x12] != '8') && (header[0x12] != '9'))?"20":"19",
		header[0x12], header[0x13], header[0x14],
		header[0x15], header[0x16], header[0x17]);
	WRITE("<version>%d</version>\n", header[2]*256+header[3]);
	if ((Characters::isdigit(header[0x3c])) &&
		((Characters::isdigit(header[0x3d])) || (header[0x3d] == '.')) &&
		(Characters::isdigit(header[0x3e])) && (Characters::isdigit(header[0x3f]))) {
		if (header[0x3d] == '.') {
			WRITE("<compiler>Inform 6</compiler>\n");
			WRITE("<compilerversion>%c%c%c%c</compilerversion>\n",
				header[0x3c], header[0x3d], header[0x3e], header[0x3f]);
		}
		else {
			WRITE("<compiler>Inform 1-5</compiler>\n");
			WRITE("<compilerversion>%c%c%c%c</compilerversion>\n",
				header[0x3c], header[0x3d], header[0x3e], header[0x3f]);
		}
	} else {
		WRITE("<compiler>ZILCH</compiler>\n");
		WRITE("<compilerversion>%d</compilerversion>\n", header[0x00]);
	}

@<Write release data for an Inform 7 project@> =
	WRITE("<releasedate>%04d-%02d-%02d</releasedate>\n",
		(the_present->tm_year)+1900, (the_present->tm_mon)+1, the_present->tm_mday);
	if ((story_release_number_VAR != NULL) &&
		(NonlocalVariables::has_initial_value_set(story_release_number_VAR))) {
		WRITE("<version>");
		PL::Bibliographic::Release::write_var_to_XML(OUT, story_release_number_VAR, FALSE);
		WRITE("</version>\n");
	} else WRITE("<version>1</version>\n");
	WRITE("<compiler>Inform 7</compiler>\n");
	WRITE("<compilerversion>%B (build %B)</compilerversion>\n", FALSE, TRUE);

@<Write the colophon tag of the iFiction record@> =
	WRITE("<colophon>\n"); INDENT;
	WRITE("<generator>Inform 7</generator>\n");
	WRITE("<generatorversion>%B (build %B)</generatorversion>\n", FALSE, TRUE);
	WRITE("<originated>20%02d-%02d-%02d</originated>\n",
		(the_present->tm_year)-100, (the_present->tm_mon)+1, the_present->tm_mday);
	OUTDENT; WRITE("</colophon>\n");

@ ZIL was Infocom's in-house language, a variant of MDL which in turn resembled
LISP.

@<Write the format-specific tag of the iFiction record@> =
	if (Task::wraps_existing_storyfile()) {
		WRITE("<serial>%c%c%c%c%c%c</serial>\n",
			header[0x12], header[0x13], header[0x14],
			header[0x15], header[0x16], header[0x17]);
		WRITE("<release>%d</release>\n", header[2]*256+header[3]);
		WRITE("<checksum>%04x</checksum>\n", header[0x1c]*256 + header[0x1d]);
		if ((Characters::isdigit(header[0x3c])) &&
			((Characters::isdigit(header[0x3d])) || (header[0x3d] == '.')) &&
			(Characters::isdigit(header[0x3e])) && (Characters::isdigit(header[0x3f]))) {
			WRITE("<compiler>Inform v%c%c%c%c</compiler>\n",
				header[0x3c], header[0x3d], header[0x3e], header[0x3f]);
		} else {
			WRITE("<compiler>Infocom ZIL</compiler>\n");
		}
	} else {
		WRITE("<serial>%02d%02d%02d</serial>\n",
			(the_present->tm_year)-100, (the_present->tm_mon)+1, the_present->tm_mday);
		if ((story_release_number_VAR != NULL) &&
			(NonlocalVariables::has_initial_value_set(story_release_number_VAR))) {
			WRITE("<release>");
			PL::Bibliographic::Release::write_var_to_XML(OUT, story_release_number_VAR, FALSE);
			WRITE("</release>\n");
		} else WRITE("<release>1</release>\n");
		WRITE("<compiler>Inform %B (build %B)</compiler>\n", FALSE, TRUE);
	}
	if (release_cover)
		WRITE("<coverpicture>%d</coverpicture>\n", cover_picture_number);

@ =
int PL::Bibliographic::Release::write_var_to_XML(OUTPUT_STREAM, nonlocal_variable *nlv, int desc_mode) {
	NonlocalVariables::treat_as_plain_text_word(nlv);
	if ((nlv) && (NonlocalVariables::has_initial_value_set(nlv))) {
		parse_node *val =
			NonlocalVariables::substitute_constants(
				NonlocalVariables::get_initial_value(
					nlv));
		kind *K = NonlocalVariables::kind(nlv);
		if (Node::is(val, UNKNOWN_NT)) {
			if (Kinds::eq(K, K_number)) WRITE("0");
		} else {
			if (Kinds::eq(K, K_number)) {
				value_holster VH = Holsters::new(INTER_DATA_VHMODE);
				Specifications::Compiler::compile_constant_to_kind_vh(&VH, val, K);
				inter_ti v1 = 0, v2 = 0;
				Holsters::unholster_pair(&VH, &v1, &v2);
				WRITE("%d", (inter_ti) v2);
			} else {
				wording W = Node::get_text(val);
				int w1 = Wordings::first_wn(W);
				PL::Bibliographic::compile_bibliographic_text(OUT, Lexer::word_text(w1));
			}
		}
		return TRUE;
	}
	return FALSE;
}

@ =
int PL::Bibliographic::Release::write_var_to_text(OUTPUT_STREAM, nonlocal_variable *nlv) {
	if ((nlv) && (NonlocalVariables::has_initial_value_set(nlv))) {
		parse_node *val =
			NonlocalVariables::substitute_constants(
				NonlocalVariables::get_initial_value(
					nlv));
		kind *K = NonlocalVariables::kind(nlv);
		if (Node::is(val, UNKNOWN_NT)) {
			if (Kinds::eq(K, K_number)) WRITE("0");
		} else {
			if (Kinds::eq(K, K_number)) {
				value_holster VH = Holsters::new(INTER_DATA_VHMODE);
				Specifications::Compiler::compile_constant_to_kind_vh(&VH, val, K);
				inter_ti v1 = 0, v2 = 0;
				Holsters::unholster_pair(&VH, &v1, &v2);
				WRITE("%d", (inter_ti) v2);
			} else {
				wording W = Node::get_text(val);
				int w1 = Wordings::first_wn(W);
				PL::Bibliographic::compile_bibliographic_text(OUT, Lexer::word_text(w1));
			}
		}
		return TRUE;
	}
	return FALSE;
}

@ Releasing requires four programs to work together: this one, Inform 6
to turn our output into a story file, a releasing agent called "Inblorb"
which binds up the result into a blorbed file, and lastly the user interface,
which calls the other three in the right sequence.

Although the user interface looks as if it's in charge, in fact we are
pulling the strings, because we write a "blurb file" of instructions
telling Inblorb exactly what to do. The format for this is an extension of
the "blurb" format documented in the "Inform Designer's Manual",
fourth edition (the "DM4"); see the published source code for Inblorb.

Note that the code below does not generate an |author| blurb instruction,
which would lead to an AUTH chunk in the final blorb. This is partly
because the AUTH chunk is now obsolete in the wake of the Treaty of
Babel, but also because it avoids problems with Unicode: an AUTH can
only contain plainest ASCII, whereas the author's name known to Inform
may very well use characters not representable in ASCII. There is no
good way round this: so, farewell AUTH.

Similarly, we do not supply a release number. The release number of a blorb
has a different meaning from that of the story file embedded in it: the
number refers to the release of the picture and sound resources found
in the blorb, and we know nothing about that. (It's a feature provided
for archival re-releases of 1980s IF.)

@d BIBLIOGRAPHIC_TEXT_TRUNCATION 31

=
void PL::Bibliographic::Release::write_release_blurb(OUTPUT_STREAM,
	int cover_picture_number, char *cover_art_format) {
	TEMPORARY_TEXT(TEMP)
	@<Compose the blorbed story filename into the TEMP stream@>;
	WRITE("! Blurb file created by Inform %B (build %B)\n\n", FALSE, TRUE);
	@<Write the body of the Blurb file@>;
	DISCARD_TEXT(TEMP)
}

@ Note that we truncate the title if it becomes vastly long, to make sure
the Blorb-file's filename won't be too long for the file system.

@<Compose the blorbed story filename into the TEMP stream@> =
	if ((story_title_VAR != NULL) &&
		(NonlocalVariables::has_initial_value_set(story_title_VAR))) {
		BEGIN_COMPILATION_MODE;
		COMPILATION_MODE_ENTER(TRUNCATE_TEXT_CMODE);
		PL::Bibliographic::Release::write_var_to_text(TEMP, story_title_VAR);
		END_COMPILATION_MODE;
	} else WRITE_TO(TEMP, "story");
	WRITE_TO(TEMP, ".%S", TargetVMs::get_blorbed_extension(Task::vm()));

@<Write the body of the Blurb file@> =
	@<Tell Inblorb where to write its report to@>;
	WRITE("\n! Identification\n\n");
	@<Tell Inblorb where the project and release folders are@>;
	WRITE("\n! Blorb instructions\n\n");
	@<Tell Inblorb where the story file and iFiction files are@>;
	@<Give instructions about the cover image@>;
	PL::Figures::write_blurb_commands(OUT);
	PL::Sounds::write_blurb_commands(OUT);
	WRITE("\n! Placeholder variables\n\n");
	@<Write numerous placeholder variables@>;
	WRITE("\n! Other material to release\n\n");
	@<Give instructions about source text, solution and library card@>;
	@<Give instructions about auxiliary files@>;
	if (release_interpreter) @<Give instructions to release with an interpreter for Web play@>;
	if (release_website) @<Give instructions to construct a website around the release@>;
	@<Give hints to Inblorb for its HTML status page@>;

@<Tell Inblorb where to write its report to@> =
	WRITE("status \"%f\" \"%f\"\n\n",
		Supervisor::file_from_installation(CBLORB_REPORT_MODEL_IRES),
		Task::cblorb_report_file());

@<Tell Inblorb where the project and release folders are@> =
	WRITE("project folder \"%p\"\n", Projects::path(Task::project()));
	if (create_Materials)
		WRITE("release to \"%p\"\n", Task::release_path());

@<Tell Inblorb where the story file and iFiction files are@> =
	WRITE("storyfile leafname \""); STREAM_COPY(OUT, TEMP); WRITE("\"\n");
	if (Task::wraps_existing_storyfile())
		WRITE("storyfile \"%f\" include\n", Task::existing_storyfile_file());
	else
		WRITE("storyfile \"%f\" include\n", Task::storyfile_file());
	WRITE("ifiction \"%f\" include\n", Task::ifiction_record_file());

@ A controversial point here is that if the author supplies no cover art, we
supply it for him, and if necessary copy a suitable image into any website
released along with the work.

@<Give instructions about the cover image@> =
	if (release_cover) {
		filename *large = NULL;
		if (strcmp(cover_art_format, "jpg") == 0)
			large = Task::large_cover_art_file(TRUE);
		else
			large = Task::large_cover_art_file(FALSE);
		WRITE("cover \"%f\"\n", large);
		WRITE("picture %d \"%f\"\n", cover_picture_number, large);
	} else {
		WRITE("cover \"%f\"\n", Supervisor::file_from_installation(LARGE_DEFAULT_COVER_ART_IRES));
		WRITE("picture %d \"%f\"\n", 1, Supervisor::file_from_installation(LARGE_DEFAULT_COVER_ART_IRES));
		if (release_website) {
			WRITE("release file \"%f\"\n", Supervisor::file_from_installation(LARGE_DEFAULT_COVER_ART_IRES));
			WRITE("release file \"%f\"\n", Supervisor::file_from_installation(SMALL_DEFAULT_COVER_ART_IRES));
		}
	}

@ This will be recognisable as yet another form of the Library Card information.
"Placeholders" are the only data structure in the primitive blurb language, and
are in effect strings, whose names appear in block capitals within square
brackets [THUS].

@<Write numerous placeholder variables@> =
	WRITE("placeholder [IFID] = \"%S\"\n", PL::Bibliographic::IFID::read_uuid());

	if (NonlocalVariables::has_initial_value_set(story_release_number_VAR)) {
		WRITE("placeholder [RELEASE] = \"");
		PL::Bibliographic::Release::write_var_to_text(OUT, story_release_number_VAR);
		WRITE("\"\n");
	} else WRITE("placeholder [RELEASE] = \"1\"\n");

	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(COMPILE_TEXT_TO_XML_CMODE);

	if (NonlocalVariables::has_initial_value_set(story_creation_year_VAR)) {
		WRITE("placeholder [YEAR] = \"");
		PL::Bibliographic::Release::write_var_to_text(OUT, story_creation_year_VAR);
		WRITE("\"\n");
	} else WRITE("placeholder [YEAR] = \"%d\"\n", (the_present->tm_year)+1900);

	if (NonlocalVariables::has_initial_value_set(story_title_VAR)) {
		NonlocalVariables::treat_as_plain_text_word(story_title_VAR);
		WRITE("placeholder [TITLE] = \"");
		PL::Bibliographic::Release::write_var_to_text(OUT, story_title_VAR);
		WRITE("\"\n");
	} else WRITE("placeholder [TITLE] = \"Untitled\"\n");

	if (NonlocalVariables::has_initial_value_set(story_author_VAR)) {
		NonlocalVariables::treat_as_plain_text_word(story_author_VAR);
		WRITE("placeholder [AUTHOR] = \"");
		PL::Bibliographic::Release::write_var_to_text(OUT, story_author_VAR);
		WRITE("\"\n");
	} else WRITE("placeholder [AUTHOR] = \"Anonymous\"\n");

	if (NonlocalVariables::has_initial_value_set(story_description_VAR)) {
		NonlocalVariables::treat_as_plain_text_word(story_description_VAR);
		WRITE("placeholder [BLURB] = \"");
		PL::Bibliographic::Release::write_var_to_text(OUT, story_description_VAR);
		WRITE("\"\n");
	} else WRITE("placeholder [BLURB] = \"A work of interactive fiction.\"\n");

	END_COMPILATION_MODE;

@<Give instructions about source text, solution and library card@> =
	if (release_source) {
		if (source_public) WRITE("source public\n"); else WRITE("source\n");
	}
	if (release_solution) {
		if (solution_public) WRITE("solution public\n"); else WRITE("solution\n");
	}
	if (release_card) {
		if (card_public) WRITE("ifiction public\n"); else WRITE("ifiction\n");
	}

@ The Introduction booklet and the Postcard are both squirreled away inside
a standard Inform installation. Under the Creative Commons licence terms for
the Postcard, we have to credit its authors here; but the booklet contains its
own credits.

@<Give instructions about auxiliary files@> =
	auxiliary_file *af;
	LOOP_OVER(af, auxiliary_file) {
		TEMPORARY_TEXT(rel)
		Pathnames::to_text_relative(rel, af->folder_to_release_to, Task::release_path());
		WRITE("auxiliary \"%f\" \"%S\" \"%S\"\n",
			af->name_of_original_file,
			(Str::len(af->brief_description) > 0)?(af->brief_description):I"--",
			(Str::len(rel) > 0)?rel:I"--");
		DISCARD_TEXT(rel)
	}
	if (release_booklet) {
		WRITE("auxiliary \"%f\" \"Introduction to IF\" \"--\"\n", Supervisor::file_from_installation(INTRO_BOOKLET_IRES));
	}
	if (release_postcard) {
		WRITE("auxiliary \"%f\" \"IF Postcard\" \"--\"\n", Supervisor::file_from_installation(INTRO_POSTCARD_IRES));
		WRITE("placeholder [OTHERCREDITS] = \"The postcard was written by Andrew Plotkin "
			"and designed by Lea Albaugh.\"\n");
	}

@ Facilities for a Javascript interpreter to play a base64-encoded story
file online.

@<Give instructions to release with an interpreter for Web play@> =
	WRITE("\n! Website instructions\n\n");
	WRITE("placeholder [ENCODEDSTORYFILE] = \"");
	STREAM_COPY(OUT, TEMP);
	WRITE(".js\"\n");
	@<Tell Inblorb where to find the website templates@>;

	if (Str::len(interpreter_template_leafname) == 0)
		interpreter_template_leafname = TargetVMs::get_default_interpreter(Task::vm());
	text_stream *ext = TargetVMs::get_blorbed_extension(Task::vm());
	WRITE("placeholder [INTERPRETERSCRIPTS] = \" ");
	auxiliary_file *af;
	LOOP_OVER(af, auxiliary_file)
		if (af->from_payload == JAVASCRIPT_PAYLOAD) {
			TEMPORARY_TEXT(rel)
			Filenames::to_text_relative(rel, af->name_of_original_file,
				Projects::materials_path(Task::project()));
			WRITE("<script src='%S'></script>", rel);
			DISCARD_TEXT(rel)
		}
	LOOP_OVER(af, auxiliary_file)
		if (af->from_payload == CSS_PAYLOAD) {
			TEMPORARY_TEXT(rel)
			Filenames::to_text_relative(rel, af->name_of_original_file,
				Projects::materials_path(Task::project()));
			WRITE("<link rel='stylesheet' href='%S' type='text/css' media='all'></link>", rel);
			DISCARD_TEXT(rel)
		}
	WRITE("\"\n");
	WRITE("interpreter \"%S\" \"%c\"\n", interpreter_template_leafname, Str::get_first_char(ext));
	WRITE("base64 \"%f\" to \"%p%c",
		Task::storyfile_file(), Task::released_interpreter_path(), FOLDER_SEPARATOR);
	STREAM_COPY(OUT, TEMP);
	WRITE(".js\"\n");

@<Give instructions to construct a website around the release@> =
	WRITE("\n! Website instructions\n\n");
	@<Tell Inblorb where to find the website templates@>;
	if (Wide::cmp(website_template_leafname, L"Classic") != 0) WRITE("css\n");
	WRITE("website \"%w\"\n", website_template_leafname);

@ The order here is significant, since Inblorb searches the folders in order,
with the earliest quoted searched first.

@<Tell Inblorb where to find the website templates@> =
	inbuild_nest *N;
	linked_list *L = Projects::nest_list(Task::project());
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, L)
		WRITE("template path \"%p\"\n", TemplateManager::path_within_nest(N));

@ Inblorb reports its progress, or lack of it, with an HTML page, just as we do.
This page however includes some hints on what the user might have chosen
instead of what he actually did choose, and we'll write those hints now, for
Inblorb to copy out later.

@<Give hints to Inblorb for its HTML status page@> =
	SyntaxTree::traverse_text(Task::syntax_tree(), OUT, PL::Bibliographic::Release::visit_to_quote);
	if (release_cover == FALSE) {
		WRITE("status alternative ||Using 'Release along with cover art', to "
			"provide something more distinctive than the default artwork above");
		Index::DocReferences::link_to(OUT, I"release_cover", FALSE);
		WRITE("||\n");
	}
	if (release_website == FALSE) {
		WRITE("status alternative ||Using 'Release along with a website'");
		Index::DocReferences::link_to(OUT, I"release_website", FALSE);
		WRITE("||\n");
	}
	if (release_interpreter == FALSE) {
		WRITE("status alternative ||Using 'Release along with an interpreter', "
			"for in-browser play on your website");
		Index::DocReferences::link_to(OUT, I"release_interpreter", FALSE);
		WRITE("||\n");
	}
	if (NUMBER_CREATED(auxiliary_file) == 0) {
		WRITE("status alternative ||Using 'Release along with a file of "
			"\"Such-and-Such\" called \"whatever.pdf\"', perhaps to add a "
			"manual, or a welcoming note");
		Index::DocReferences::link_to(OUT, I"release_files", FALSE);
		WRITE("||\n");
	}

	if (release_source == FALSE) {
		WRITE("status alternative ||Using 'Release along with the source text'");
		Index::DocReferences::link_to(OUT, I"release_source", FALSE);
		WRITE("||\n");
	}

	if (release_solution == FALSE) {
		WRITE("status alternative ||Using 'Release along with a solution'");
		Index::DocReferences::link_to(OUT, I"release_solution", FALSE);
		WRITE("||\n");
	}

	if (release_card == FALSE) {
		WRITE("status alternative ||Using 'Release along with the library card'");
		Index::DocReferences::link_to(OUT, I"release_card", FALSE);
		WRITE("||\n");
	}

	if (release_booklet == FALSE) {
		WRITE("status alternative ||Using 'Release along with the introductory booklet'");
		Index::DocReferences::link_to(OUT, I"release_booklet", FALSE);
		WRITE("||\n");
	}

	if (release_postcard == FALSE) {
		WRITE("status alternative ||Using 'Release along with the introductory postcard'");
		Index::DocReferences::link_to(OUT, I"release_postcard", FALSE);
		WRITE("||\n");
	}
