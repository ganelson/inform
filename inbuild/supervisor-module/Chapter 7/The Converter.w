[ExtensionConverter::] The Converter.

To convert an extension from the traditional one-file format to the more
modern directory-based format.

@ In all paths through this function, we must write either good news or bad
to |OUT|: bad news usually following from the file system refusing to create
a text file or directory.

=
void ExtensionConverter::go(inform_extension *E, text_stream *OUT) {
	Extensions::read_source_text_for(E);

	TEMPORARY_TEXT(dirname)
	Editions::write_canonical_leaf(dirname, E->as_copy->edition);
	WRITE_TO(dirname, ".i7xd");
	pathname *P_home = Pathnames::down(Filenames::up(E->as_copy->location_if_file), dirname);
	pathname *P_source =        Pathnames::down(P_home, I"Source");
	pathname *P_documentation = Pathnames::down(P_home, I"Documentation");
	pathname *P_examples =      Pathnames::down(P_documentation, I"Examples");

	@<Create the home directory for the extension@>;
	@<Construct JSON metadata and write it as a file@>;
	@<Write out the source code@>;
	@<Write out the documentation@>;

	WRITE("migrated to directory '%S'\n", dirname);
	DISCARD_TEXT(dirname)
}

@<Create the home directory for the extension@> =
	if (Directories::exists(P_home)) {
		WRITE("can't make this into %S because directory '%p' already exists", dirname, P_home);
		return;
	}
	if (ExtensionConverter::mkdir(E, OUT, P_home) == FALSE) return;

@<Construct JSON metadata and write it as a file@> =	
	JSON_value *JM = JSON::new_object();
	JSON_value *is = JSON::new_object();
	JSON::add_to_object(JM, I"is", is);
	JSON::add_to_object(is, I"type", JSON::new_string(I"extension"));
	JSON::add_to_object(is, I"title", JSON::new_string(E->as_copy->edition->work->title));
	JSON::add_to_object(is, I"author", JSON::new_string(E->as_copy->edition->work->author_name));
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V) == FALSE) {
		TEMPORARY_TEXT(vt)
		WRITE_TO(vt, "%v", &V);
		JSON::add_to_object(is, I"version", JSON::new_string(vt));
		DISCARD_TEXT(vt)
	}

	filename *JF = Filenames::in(P_home, I"extension_metadata.json");
	text_stream JSONF_struct;
	text_stream *JS = &JSONF_struct;
	if (ExtensionConverter::fopen(E, OUT, JS, JF) == FALSE) return;
	JSON::encode(JS, JM);
	STREAM_CLOSE(JS);

@<Write out the source code@> =
	if (ExtensionConverter::mkdir(E, OUT, P_source) == FALSE) return;
	TEMPORARY_TEXT(sleaf)
	Editions::write_canonical_leaf(sleaf, E->as_copy->edition);
	WRITE_TO(sleaf, ".i7x");
	filename *SF = Filenames::in(P_source, sleaf);
	DISCARD_TEXT(sleaf)
	text_stream SRCF_struct;
	text_stream *SS = &SRCF_struct;
	if (ExtensionConverter::fopen(E, OUT, SS, SF) == FALSE) return;
	WRITE_TO(SS, "%S", E->read_into_file->body_text);
	STREAM_CLOSE(SS);

@<Write out the documentation@> =
	text_stream *source = E->read_into_file->torn_off_documentation;
	if (Str::is_whitespace(source) == FALSE) {
		if (ExtensionConverter::mkdir(E, OUT, P_documentation) == FALSE) return;
		filename *F_documentation = Filenames::in(P_documentation, I"Documentation.txt");
		text_stream DOCF_struct;
		text_stream *S_documentation = &DOCF_struct;
		if (ExtensionConverter::fopen(E, OUT, S_documentation, F_documentation) == FALSE) return;
		@<Filter the documentation through@>;
		STREAM_CLOSE(S_documentation);
	}

@ We work through the documentation attached to the original extension (if
there was any) in two passes. On pass 1, we do nothing except to count the
number of section and chapter headings. On pass 2, we split up the content
into the main file and individual example files.

@<Filter the documentation through@> =
	int chapter_count = 0, section_count = 0, example_count = 0;
	text_stream EG_struct;
	for (int pass = 1; pass <= 2; pass++) {
		text_stream *dest = S_documentation, *S_example = NULL;
		TEMPORARY_TEXT(line)
		int indentation = 0, space_count = 0;
		for (int i=0; i<Str::len(source); i++) {
			wchar_t c = Str::get_at(source, i);
			if (c == '\n') {
				@<Line read@>;
				Str::clear(line);
				indentation = 0; space_count = 0;
			} else if ((Str::len(line) == 0) && (Characters::is_whitespace(c))) {
				if (c == '\t') indentation++;
				if (c == ' ') space_count++;
				if (space_count == 4) { indentation++; space_count = 0; }
			} else {
				PUT_TO(line, c);
			}
		}
		if (Str::len(line) > 0) @<Line read@>;
		DISCARD_TEXT(line)
		if (pass == 2) @<End any example@>;
	}

@<Line read@> =
	Str::trim_white_space(line);
	match_results mr = Regexp::create_mr();
	if ((Regexp::match(&mr, line, L"Section *: *(%c+?)")) ||
		(Regexp::match(&mr, line, L"Section *- *(%c+?)"))) {
		if (pass == 1) section_count++;
		if (pass == 2) @<End any example@>;
	} else if ((Regexp::match(&mr, line, L"Chapter *: *(%c+?)")) ||
		(Regexp::match(&mr, line, L"Chapter *- *(%c+?)"))) {
		if (pass == 1) chapter_count++;
		if (pass == 2) {
			@<End any example@>;
			@<Amend this to a section heading@>;
		}
	}
	if (pass == 2) {
		if ((Regexp::match(&mr, line, L"Example *: *(%**) *(%c+?)")) ||
			(Regexp::match(&mr, line, L"Example *- *(%**) *(%c+?)")))
			@<Deal with an example heading@>
		else
			@<Copy the line out to the appropriate file@>;
	}
	
	Regexp::dispose_of(&mr);

@ Old single-file extensions tended to use Chapters, intended as major headings,
with not much content, and not to use Sections at all. Because we now split
off Chapters into their own HTML pages, we don't want that, so when converting
an old extension which has chapters but no sections, we downgrade all the chapters
to sections.

@<Amend this to a section heading@> =
	if (section_count == 0) {
		Str::clear(line);
		WRITE_TO(line, "Section: %S", mr.exp[0]);
	}

@<Deal with an example heading@> =
	text_stream *stars = mr.exp[0];
	text_stream *title = mr.exp[1];
	text_stream *desc = NULL;
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, title, L" *(%c+?) - *(%c+) *")) {
		title = mr2.exp[0];
		desc = mr2.exp[1];
	}
	@<Begin an example@>;
	Regexp::dispose_of(&mr2);

@<Begin an example@> =
	if ((example_count++ == 0) &&
		(ExtensionConverter::mkdir(E, OUT, P_examples) == FALSE)) return;

	TEMPORARY_TEXT(eleaf)
	for (int i=0, last_was_ws=TRUE; i<Str::len(title); i++) {
		wchar_t c = Str::get_at(title, i);
		if (Characters::is_whitespace(c)) { last_was_ws = TRUE; continue; }
		if (last_was_ws) c = Characters::toupper(c);
		last_was_ws = FALSE;
		if ((c == '.') || (c == ',') || (c == ';') || (c == '"') || (c == '\''))
			continue;
		PUT_TO(eleaf, c);
	}
	WRITE_TO(eleaf, ".txt");
	filename *F_example = Filenames::in(P_examples, eleaf);
	DISCARD_TEXT(eleaf)
	S_example = &EG_struct;
	if (ExtensionConverter::fopen(E, OUT, S_example, F_example) == FALSE) return;
	dest = S_example;
	WRITE_TO(dest, "Example: %S %S\n", stars, title);
	if (Str::len(desc) > 0) WRITE_TO(dest, "Description: %S\n", desc);

@<End any example@> =
	if (S_example) {
		STREAM_CLOSE(S_example);
		S_example = NULL;
		dest = S_documentation;
	}

@ Note that we amend the old-style paste marker to the new style, though both
are legal.

@<Copy the line out to the appropriate file@> =
	for (int i=0; i<indentation; i++) PUT_TO(dest, '\t');
	match_results mr2 = Regexp::create_mr();
	if ((indentation == 1) && (Regexp::match(&mr2, line, L"%* *: *(%c+?)"))) {
		WRITE_TO(dest, "{*}%S\n", mr2.exp[0]);
	} else {
		WRITE_TO(dest, "%S\n", line);
	}
	Regexp::dispose_of(&mr2);

@ And this provides bad news texts when the two main file-system operations fail.

=
int ExtensionConverter::mkdir(inform_extension *E, text_stream *OUT, pathname *P) {
	if (Pathnames::create_in_file_system(P) == FALSE) {
		WRITE("unable to create directory '%p'", P);
		return FALSE;
	}
	return TRUE;
}

int ExtensionConverter::fopen(inform_extension *E, text_stream *OUT, text_stream *S, filename *F) {
	if (STREAM_OPEN_TO_FILE(S, F, UTF8_ENC) == FALSE) {
		WRITE("unable to create file '%f'", F);
		return FALSE;
	}
	return TRUE;
}
