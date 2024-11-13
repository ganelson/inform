[BlurbFile::] The Blurb File.

To write the blurb file of instructions for inblorb to release the project.

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
void BlurbFile::write(OUTPUT_STREAM, release_instructions *rel) {
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
		(VariableSubjects::has_initial_value_set(story_title_VAR))) {
		BlurbFile::write_var_to_text(TEMP, story_title_VAR, TRUNCATE_BIBTEXT_MODE);
		LOOP_THROUGH_TEXT(pos, TEMP) {
			inchar32_t c = Str::get(pos);
			if ((c == ':') || (c == '/') || (c == '\\') || (c == '.') ||
				(c == '*') || (c == '#'))
				Str::put(pos, '-');
		}
	} else {
		WRITE_TO(TEMP, "story");
	}
	WRITE_TO(TEMP, ".%S", TargetVMs::get_blorbed_extension(Task::vm()));

@<Write the body of the Blurb file@> =
	@<Tell Inblorb where to write its report to@>;
	WRITE("\n! Identification\n\n");
	@<Tell Inblorb where the project and release folders are@>;
	WRITE("\n! Blorb instructions\n\n");
	@<Tell Inblorb where the story file and iFiction files are@>;
	@<Give instructions about the cover image@>;
	Figures::write_blurb_commands(OUT);
	Sounds::write_blurb_commands(OUT);
	InternalFiles::write_blurb_commands(OUT);
	WRITE("\n! Placeholder variables\n\n");
	@<Write numerous placeholder variables@>;
	WRITE("\n! Other material to release\n\n");
	@<Give instructions about source text, solution and library card@>;
	@<Give instructions about auxiliary files@>;
	int templates_declared = FALSE;
	if (rel->release_interpreter) @<Give instructions to release with an interpreter for Web play@>;
	if (rel->release_website) @<Give instructions to construct a website around the release@>;
	@<Give hints to Inblorb for its HTML status page@>;

@<Tell Inblorb where to write its report to@> =
	WRITE("status \"%f\" \"%f\"\n",
		InstalledFiles::filename(CBLORB_REPORT_MODEL_IRES),
		Task::cblorb_report_file());

@<Tell Inblorb where the project and release folders are@> =
	WRITE("project folder \"%p\"\n", Projects::path(Task::project()));
	WRITE("release to \"%p\"\n", Task::release_path());

@<Tell Inblorb where the story file and iFiction files are@> =
	WRITE("storyfile leafname \""); STREAM_COPY(OUT, TEMP); WRITE("\"\n");
	filename *F = BlurbFile::storyfile_original();
	if (F) WRITE("storyfile \"%f\" include\n", F);
	WRITE("ifiction \"%f\" include\n", Task::ifiction_record_file());

@ A controversial point here is that if the author supplies no cover art, we
supply it for him, and if necessary copy a suitable image into any website
released along with the work.

@<Give instructions about the cover image@> =
	if (rel->release_cover) {
		filename *large = NULL;
		if (strcmp(rel->cover_art_format, "jpg") == 0)
			large = Task::large_cover_art_file(TRUE);
		else
			large = Task::large_cover_art_file(FALSE);
		WRITE("cover \"%f\"\n", large);
		WRITE("picture %d \"%f\"\n", rel->cover_picture_number, large);
	} else {
		WRITE("cover \"%f\"\n",
			InstalledFiles::filename(LARGE_DEFAULT_COVER_ART_IRES));
		WRITE("picture %d \"%f\"\n", 1,
			InstalledFiles::filename(LARGE_DEFAULT_COVER_ART_IRES));
		if (rel->release_website) {
			WRITE("release file \"%f\"\n",
				InstalledFiles::filename(LARGE_DEFAULT_COVER_ART_IRES));
			WRITE("release file \"%f\"\n",
				InstalledFiles::filename(SMALL_DEFAULT_COVER_ART_IRES));
		}
	}

@ This will be recognisable as yet another form of the Library Card information.
"Placeholders" are the only data structure in the primitive blurb language, and
are in effect strings, whose names appear in block capitals within square
brackets [THUS].

@<Write numerous placeholder variables@> =
	WRITE("placeholder [IFID] = \"%S\"\n", BibliographicData::read_uuid());

	if (VariableSubjects::has_initial_value_set(story_release_number_VAR)) {
		WRITE("placeholder [RELEASE] = \"");
		BlurbFile::write_var_to_text(OUT, story_release_number_VAR, XML_BIBTEXT_MODE);
		WRITE("\"\n");
	} else WRITE("placeholder [RELEASE] = \"1\"\n");

	if (VariableSubjects::has_initial_value_set(story_creation_year_VAR)) {
		WRITE("placeholder [YEAR] = \"");
		BlurbFile::write_var_to_text(OUT, story_creation_year_VAR, XML_BIBTEXT_MODE);
		WRITE("\"\n");
	} else WRITE("placeholder [YEAR] = \"%d\"\n", (the_present->tm_year)+1900);

	if (VariableSubjects::has_initial_value_set(story_title_VAR)) {
		NonlocalVariables::initial_value_as_plain_text(story_title_VAR);
		WRITE("placeholder [TITLE] = \"");
		BlurbFile::write_var_to_text(OUT, story_title_VAR, XML_BIBTEXT_MODE);
		WRITE("\"\n");
	} else WRITE("placeholder [TITLE] = \"Untitled\"\n");

	if (VariableSubjects::has_initial_value_set(story_author_VAR)) {
		NonlocalVariables::initial_value_as_plain_text(story_author_VAR);
		WRITE("placeholder [AUTHOR] = \"");
		BlurbFile::write_var_to_text(OUT, story_author_VAR, XML_BIBTEXT_MODE);
		WRITE("\"\n");
	} else WRITE("placeholder [AUTHOR] = \"Anonymous\"\n");

	if (VariableSubjects::has_initial_value_set(story_description_VAR)) {
		NonlocalVariables::initial_value_as_plain_text(story_description_VAR);
		WRITE("placeholder [BLURB] = \"");
		BlurbFile::write_var_to_text(OUT, story_description_VAR, XML_BIBTEXT_MODE);
		WRITE("\"\n");
	} else WRITE("placeholder [BLURB] = \"A work of interactive fiction.\"\n");

@<Give instructions about source text, solution and library card@> =
	if (rel->release_source) {
		if (rel->source_public) WRITE("source public\n"); else WRITE("source\n");
	}
	if (rel->release_solution) {
		if (rel->solution_public) WRITE("solution public\n"); else WRITE("solution\n");
	}
	if (rel->release_card) {
		if (rel->card_public) WRITE("ifiction public\n"); else WRITE("ifiction\n");
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
	if (rel->release_booklet) {
		WRITE("auxiliary \"%f\" \"Introduction to IF\" \"--\"\n",
			InstalledFiles::filename(INTRO_BOOKLET_IRES));
	}
	if (rel->release_postcard) {
		WRITE("auxiliary \"%f\" \"IF Postcard\" \"--\"\n",
			InstalledFiles::filename(INTRO_POSTCARD_IRES));
		WRITE("placeholder [OTHERCREDITS] = \"The postcard was written by Andrew Plotkin "
			"and designed by Lea Albaugh.\"\n");
	}
	if (LicenceDeclaration::anything_to_declare()) {		
		WRITE("auxiliary \"%f\" \"%S\" \"--\"\n",
			Task::licenses_file(rel->release_website),
			I"Copyright");
	}

@ Facilities for a Javascript interpreter to play a base64-encoded story
file online.

@<Give instructions to release with an interpreter for Web play@> =
	WRITE("\n! Interpreter instructions\n\n");
	WRITE("placeholder [ENCODEDSTORYFILE] = \"");
	STREAM_COPY(OUT, TEMP);
	WRITE(".js\"\n");
	@<Tell Inblorb where to find the website templates@>;

	if (Str::len(rel->interpreter_template_leafname) == 0)
		rel->interpreter_template_leafname = TargetVMs::get_default_interpreter(Task::vm());
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
	WRITE("interpreter \"%S\" \"%c\"\n", rel->interpreter_template_leafname,
		Str::get_first_char(ext));

	filename *SF = BlurbFile::storyfile_original();
	if (SF) {
		WRITE("base64 \"%f\" to \"%p%c", SF, Task::released_interpreter_path(),
			FOLDER_SEPARATOR);
	}
	STREAM_COPY(OUT, TEMP);
	WRITE(".js\"\n");

@<Give instructions to construct a website around the release@> =
	WRITE("\n! Website instructions\n\n");
	@<Tell Inblorb where to find the website templates@>;
	if (Wide::cmp(rel->website_template_leafname, U"Classic") != 0) WRITE("css\n");
	WRITE("website \"%w\"\n", rel->website_template_leafname);

@ The order here is significant, since Inblorb searches the folders in order,
with the earliest quoted searched first. We want first the materials folder for
a project, then the |Templates| directory in the materials for extensions
included by the project, and then the external area, and finally the internal.

@<Tell Inblorb where to find the website templates@> =
	if (templates_declared == FALSE) {
		inbuild_nest *N;
		linked_list *L = Projects::nest_list(Task::project());
		linked_list *declared = NEW_LINKED_LIST(text_stream);
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, L) {
			inbuild_nest *M = N;
			@<Declare one template path@>;
			if (Nests::get_tag(N) == MATERIALS_NEST_TAG) {
				inform_extension *E;
				LOOP_OVER_LINKED_LIST(E, inform_extension, Task::project()->extensions_included) {
					pathname *P = Extensions::materials_path(E);
					if (P) {
						M = Nests::new(P);
						@<Declare one template path@>;
					}
				}
			}
		}
		templates_declared = TRUE;
	}

@<Declare one template path@> =
	pathname *TP = TemplateManager::path_within_nest(M);
	if (Directories::exists(TP)) {
		text_stream *declaration = Str::new();
		WRITE_TO(declaration, "template path \"%p\"\n", TP);
		int already = FALSE;
		text_stream *done;
		LOOP_OVER_LINKED_LIST(done, text_stream, declared)
			if (Str::eq(done, declaration))
				already = TRUE;
		if (already == FALSE) {
			WRITE("%S", declaration);
			ADD_TO_LINKED_LIST(declaration, text_stream, declared);
		}
	}

@ Inblorb reports its progress, or lack of it, with an HTML page, just as we do.
This page however includes some hints on what the user might have chosen
instead of what he actually did choose, and we'll write those hints now, for
Inblorb to copy out later.

@<Give hints to Inblorb for its HTML status page@> =
	SyntaxTree::traverse_text(Task::syntax_tree(), OUT, BlurbFile::visit_to_quote);
	if (rel->release_cover == FALSE) {
		WRITE("status alternative ||Using 'Release along with cover art', to "
			"provide something more distinctive than the default artwork above");
		DocReferences::link_to(OUT, I"release_cover", FALSE);
		WRITE("||\n");
	}
	if (rel->release_website == FALSE) {
		WRITE("status alternative ||Using 'Release along with a website'");
		DocReferences::link_to(OUT, I"release_website", FALSE);
		WRITE("||\n");
	}
	if (rel->release_interpreter == FALSE) {
		WRITE("status alternative ||Using 'Release along with an interpreter', "
			"for in-browser play on your website");
		DocReferences::link_to(OUT, I"release_interpreter", FALSE);
		WRITE("||\n");
	}
	if (NUMBER_CREATED(auxiliary_file) == 0) {
		WRITE("status alternative ||Using 'Release along with a file of "
			"\"Such-and-Such\" called \"whatever.pdf\"', perhaps to add a "
			"manual, or a welcoming note");
		DocReferences::link_to(OUT, I"release_files", FALSE);
		WRITE("||\n");
	}

	if (rel->release_source == FALSE) {
		WRITE("status alternative ||Using 'Release along with the source text'");
		DocReferences::link_to(OUT, I"release_source", FALSE);
		WRITE("||\n");
	}

	if (rel->release_solution == FALSE) {
		WRITE("status alternative ||Using 'Release along with a solution'");
		DocReferences::link_to(OUT, I"release_solution", FALSE);
		WRITE("||\n");
	}

	if (rel->release_card == FALSE) {
		WRITE("status alternative ||Using 'Release along with the library card'");
		DocReferences::link_to(OUT, I"release_card", FALSE);
		WRITE("||\n");
	}

	if (rel->release_booklet == FALSE) {
		WRITE("status alternative ||Using 'Release along with the introductory booklet'");
		DocReferences::link_to(OUT, I"release_booklet", FALSE);
		WRITE("||\n");
	}

	if (rel->release_postcard == FALSE) {
		WRITE("status alternative ||Using 'Release along with the introductory postcard'");
		DocReferences::link_to(OUT, I"release_postcard", FALSE);
		WRITE("||\n");
	}

@ =
filename *BlurbFile::storyfile_original(void) {
	filename *F = Task::existing_storyfile_file();
	if (F == NULL) F = Task::storyfile_file();
	return F;
}

@ =
void BlurbFile::visit_to_quote(OUTPUT_STREAM, parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down)) {
		special_meaning_holder *sm = Node::get_special_meaning(p->down);
		if (SpecialMeanings::is(sm, ReleaseInstructions::release_along_with_SMF)) {
			TEMPORARY_TEXT(TEMP)
			IndexUtilities::link_to(TEMP, Wordings::first_wn(Node::get_text(p)), TRUE);
			WRITE("status instruction ||");
			STREAM_COPY(OUT, TEMP);
			WRITE("||\n");
			DISCARD_TEXT(TEMP)
		}
	}
}

@ =
int BlurbFile::write_var_to_text(OUTPUT_STREAM, nonlocal_variable *nlv, int mode) {
	if ((nlv) && (VariableSubjects::has_initial_value_set(nlv))) {
		parse_node *val =
			NonlocalVariables::substitute_constants(
				VariableSubjects::get_initial_value(
					nlv));
		kind *K = NonlocalVariables::kind(nlv);
		if (Node::is(val, UNKNOWN_NT)) {
			if (Kinds::eq(K, K_number)) WRITE("0");
		} else {
			if (Kinds::eq(K, K_number)) {
				inter_pair N = CompileValues::constant_to_pair(val, K);
				WRITE("%d", InterValuePairs::to_number(N));
			} else {
				wording W = Node::get_text(val);
				int w1 = Wordings::first_wn(W);
				BibliographicData::compile_bibliographic_text(OUT, Lexer::word_text(w1), mode);
			}
		}
		return TRUE;
	}
	return FALSE;
}