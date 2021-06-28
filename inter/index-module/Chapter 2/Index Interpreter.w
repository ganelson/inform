[InterpretIndex::] Index Interpreter.

The index layout is read in from a file.

@h Implementation.
So, then, here is the shared interpreter for these functions. Broadly
speaking, it's a filter from input to output, where the input is either to
be a file or a wide C-string, and the output (if any) is a text stream.
In kind or indexing mode, there is in fact no output, and the interpreter
is run only to call other functions.

=
void InterpretIndex::generate_from_structure_file(filename *index_structure) {
	FILE *Input_File = Filenames::fopen(index_structure, "r");
	if (Input_File == NULL) {
		LOG("Filename was %f\n", index_structure);
		internal_error("unable to open template file for the index");
	}

	int col = 1, cr;
	TEMPORARY_TEXT(heading_name)

	int comment = FALSE;

	TEMPORARY_TEXT(command)
	TEMPORARY_TEXT(argument)
	do {
		Str::clear(command);
		Str::clear(argument);
		@<Read next character from I6T stream@>;
		NewCharacter: if (cr == EOF) break;
		if (comment == FALSE) {
			if (cr == '{') {
				@<Read next character from I6T stream@>;
				if (cr == '-') {
					@<Read up to the next close brace as an I6T command and argument@>;
					if (Str::get_first_char(command) == '!') continue;
					@<Act on an I6T indexing command@>;
					continue;
				} else { /* otherwise the open brace was a literal */
					goto NewCharacter;
				}
			}
		}
	} while (cr != EOF);
	DISCARD_TEXT(command)
	DISCARD_TEXT(argument)
	if (Input_File) { if (DL) STREAM_FLUSH(DL); fclose(Input_File); }

	DISCARD_TEXT(heading_name)
	Index::complete(); 
}

@ I6 template files are encoded as ISO Latin-1, not as Unicode UTF-8, so
ordinary |fgetc| is used, and no BOM marker is parsed. Lines are assumed
to be terminated with either |0x0a| or |0x0d|. (Since blank lines are
harmless, we take no trouble over |0a0d| or |0d0a| combinations.) The
built-in template files, almost always the only ones used, are line
terminated |0x0a| in Unix fashion.

@<Read next character from I6T stream@> =
	if (Input_File) cr = fgetc(Input_File);
	else cr = EOF;
	col++; if ((cr == 10) || (cr == 13)) col = 0;

@ We get here when reading a kinds template file. Note that initial and
trailing white space on the line is deleted: this makes it easier to lay
out I6T template files tidily.

@<Read rest of line as argument@> =
	Str::clear(argument);
	if (Characters::is_space_or_tab(cr) == FALSE) PUT_TO(argument, cr);
	int at_start = TRUE;
	while (TRUE) {
		@<Read next character from I6T stream@>;
		if ((cr == 10) || (cr == 13)) break;
		if ((at_start) && (Characters::is_space_or_tab(cr))) continue;
		PUT_TO(argument, cr); at_start = FALSE;
	}
	while (Characters::is_space_or_tab(Str::get_last_char(argument)))
		Str::delete_last_character(argument);

@ And here we read a normal command. The command name must not include |}|
or |:|. If there is no |:| then the argument is left unset (so that it will
be the empty string: see above). The argument must not include |}|.

@<Read up to the next close brace as an I6T command and argument@> =
	Str::clear(command);
	Str::clear(argument);
	int com_mode = TRUE;
	while (TRUE) {
		@<Read next character from I6T stream@>;
		if ((cr == '}') || (cr == EOF)) break;
		if ((cr == ':') && (com_mode)) { com_mode = FALSE; continue; }
		if (com_mode) PUT_TO(command, cr);
		else PUT_TO(argument, cr);
	}

@h Indexing commands.
Commands in a |.indext| file are skipped when Inform has been called with a 
ommand-line switch to disable the index. (As is done by |intest|, to save
time.) |{-index:name}| opens the index file called |name|.

@<Act on an I6T indexing command@> =
	if (Str::eq_wide_string(command, L"index-page")) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, argument, L"(%c+?)=(%c+?)=(%c+)")) {
			text_stream *col = mr.exp[0];
			text_stream *titling = mr.exp[1];
			text_stream *explanation = mr.exp[2];
			match_results mr2 = Regexp::create_mr();
			text_stream *leafname = titling;
			if (Regexp::match(&mr2, titling, L"(%C+?) (%c+)")) leafname = mr2.exp[0];
			Index::new_page(col, titling, explanation, leafname);
			Regexp::dispose_of(&mr2);
		} else internal_error("bad index-page format");
		Regexp::dispose_of(&mr);
		continue;
	}

	if (Str::eq_wide_string(command, L"index-element")) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, argument, L"(%C+) (%c+?)=(%c+)"))
			Index::new_segment(mr.exp[0], mr.exp[1], mr.exp[2]);
		else internal_error("bad index-element format");
		Regexp::dispose_of(&mr);
		continue;
	}

	if (Str::eq_wide_string(command, L"index")) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, argument, L"(%c+?)=(%c+)")) {
			text_stream *titling = mr.exp[0];
			text_stream *explanation = mr.exp[1];
			match_results mr2 = Regexp::create_mr();
			TEMPORARY_TEXT(leafname)
			Str::copy(leafname, titling);
			if (Regexp::match(&mr2, leafname, L"(%C+?) (%c+)")) Str::copy(leafname, mr2.exp[0]);
			WRITE_TO(leafname, ".html");
			Index::open_file(leafname, titling, -1, explanation);
			Regexp::dispose_of(&mr2);
			DISCARD_TEXT(leafname)
		} else {
			internal_error("bad index format");
		}
		Regexp::dispose_of(&mr);
		continue;
	}

@ Here we read a localisation file for text used in the Index elements, and write
this into a given dictionary of key-value pairs.

=
void InterpretIndex::read_into_dictionary(filename *localisation_file, dictionary *D) {
	FILE *Input_File = Filenames::fopen(localisation_file, "r");
	if (Input_File == NULL) {
		LOG("Filename was %f\n", localisation_file);
		internal_error("unable to open localisation file for the index");
	}

	int col = 1, cr;

	TEMPORARY_TEXT(key)
	TEMPORARY_TEXT(value)
	do {
		@<Read next character from localisation stream@>;
		if (cr == EOF) break;
		if (cr == '%') @<Read up to the next white space as a key@>;
		if (cr == EOF) break;
		if (Str::len(key) > 0) PUT_TO(value, cr);
	} while (cr != EOF);
	if (Str::len(key) > 0) @<Write key-value pair@>;
	DISCARD_TEXT(key)
	DISCARD_TEXT(value)
	fclose(Input_File);
	Index::complete(); 
}

@ Localisation files are encoded as ISO Latin-1, not as Unicode UTF-8, so
ordinary |fgetc| is used, and no BOM marker is parsed. Lines are assumed
to be terminated with either |0x0a| or |0x0d|. (Since blank lines are
harmless, we take no trouble over |0a0d| or |0d0a| combinations.)

@<Read next character from localisation stream@> =
	if (Input_File) cr = fgetc(Input_File);
	else cr = EOF;
	col++; if ((cr == 10) || (cr == 13)) col = 0;

@<Read up to the next white space as a key@> =
	if (Str::len(key) > 0) @<Write key-value pair@>;
	Str::clear(key);
	Str::clear(value);
	while (TRUE) {
		@<Read next character from localisation stream@>;
		if ((cr == '=') || (cr == EOF)) break;
		if (Characters::is_whitespace(cr)) continue;
		PUT_TO(key, cr);
	}
	if (cr == '=') {
		while (TRUE) {
			@<Read next character from localisation stream@>;
			if (cr == EOF) break;
			if (Characters::is_whitespace(cr)) continue;
		}
	}		

@<Write key-value pair@> =
	text_stream *to = Dictionaries::create_text(D, key);
	WRITE_TO(to, "%S", value);
