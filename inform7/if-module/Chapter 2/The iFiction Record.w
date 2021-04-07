[iFiction::] The iFiction Record.

To write the iFiction record for the work of IF compiled.

@ The format of this file is exactly specified by the Treaty of Babel.

=
void iFiction::write_ifiction_record(OUTPUT_STREAM, release_instructions *rel) {
	WRITE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
	WRITE("<ifindex version=\"1.0\" "
		"xmlns=\"http://babel.ifarchive.org/protocol/iFiction/\">\n"); INDENT;
	WRITE("<story>\n"); INDENT;
	zbyte *header = rel->existing_story_header;
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
	if (rel->release_cover)
		@<Write the cover tag of the iFiction record@>;
	@<Write the releases tag of the iFiction record@>;
	@<Write the colophon tag of the iFiction record@>;
	WRITE("<%S>\n", story_format); INDENT;
	@<Write the format-specific tag of the iFiction record@>;
	OUTDENT; WRITE("</%S>\n", story_format);

@<Write the identification tag of the iFiction record@> =
	WRITE("<identification>\n"); INDENT;
	WRITE("<ifid>%S</ifid>\n", BibliographicData::read_uuid());
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
	if (iFiction::write_var_to_XML(OUT, story_title_VAR) == FALSE) WRITE("Untitled");
	WRITE("</title>\n");
	WRITE("<author>");
	if (iFiction::write_var_to_XML(OUT, story_author_VAR) == FALSE) WRITE("Anonymous");
	WRITE("</author>\n");
	WRITE("<headline>");
	if (iFiction::write_var_to_XML(OUT, story_headline_VAR) == FALSE)
		WRITE("An Interactive Fiction");
	WRITE("</headline>\n");
	WRITE("<genre>");
	if (iFiction::write_var_to_XML(OUT, story_genre_VAR) == FALSE) WRITE("Fiction");
	WRITE("</genre>\n");
	WRITE("<firstpublished>");
	if (iFiction::write_var_to_XML(OUT, story_creation_year_VAR) == FALSE)
		WRITE("%d", (the_present->tm_year)+1900);
	WRITE("</firstpublished>\n");
	if (VariableSubjects::has_initial_value_set(story_description_VAR)) {
		WRITE("<description>");
		iFiction::write_var_to_XML(OUT, story_description_VAR);
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
	WRITE("<format>%s</format>\n", rel->cover_art_format);
	WRITE("<height>%d</height>\n", rel->height);
	WRITE("<width>%d</width>\n", rel->width);
	if (rel->cover_alt_text >= 0) {
		Word::dequote(rel->cover_alt_text);
		WRITE("<description>%N</description>\n", rel->cover_alt_text);
	} else {
		WRITE("<description>%w</description>\n", Figures::description_of_cover_art());
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
		(VariableSubjects::has_initial_value_set(story_release_number_VAR))) {
		WRITE("<version>");
		iFiction::write_var_to_XML(OUT, story_release_number_VAR);
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
			(VariableSubjects::has_initial_value_set(story_release_number_VAR))) {
			WRITE("<release>");
			iFiction::write_var_to_XML(OUT, story_release_number_VAR);
			WRITE("</release>\n");
		} else WRITE("<release>1</release>\n");
		WRITE("<compiler>Inform %B (build %B)</compiler>\n", FALSE, TRUE);
	}
	if (rel->release_cover)
		WRITE("<coverpicture>%d</coverpicture>\n", rel->cover_picture_number);

@ =
int iFiction::write_var_to_XML(OUTPUT_STREAM, nonlocal_variable *nlv) {
	NonlocalVariables::initial_value_as_plain_text(nlv);
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
				inter_ti v1 = 0, v2 = 0;
				CompileSpecifications::constant_to_pair(&v1, &v2, val, K);
				WRITE("%d", (inter_ti) v2);
			} else {
				wording W = Node::get_text(val);
				int w1 = Wordings::first_wn(W);
				BibliographicData::compile_bibliographic_text(OUT, Lexer::word_text(w1), XML_BIBTEXT_MODE);
			}
		}
		return TRUE;
	}
	return FALSE;
}
