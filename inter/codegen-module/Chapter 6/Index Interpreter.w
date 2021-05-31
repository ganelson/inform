[InterpretIndex::] Index Interpreter.

Inform 6 template language, or I6T for short, is a notation for expressing
low-level code in Inter.

@

=
int do_not_generate_index = FALSE; /* Set by the |-no-index| command line option */
void InterpretIndex::disable_or_enable_index(int which) {
	do_not_generate_index = which;
}

void InterpretIndex::interpret_indext(filename *indext_file) {
	if (do_not_generate_index == FALSE)
		InterpretIndex::interpreter_shared(indext_file);
}

@h Implementation.
So, then, here is the shared interpreter for these functions. Broadly
speaking, it's a filter from input to output, where the input is either to
be a file or a wide C-string, and the output (if any) is a text stream.
In kind or indexing mode, there is in fact no output, and the interpreter
is run only to call other functions.

=
void InterpretIndex::interpreter_shared(filename *index_structure) {
	text_stream *OUT = NULL;
	FILE *Input_File = NULL;
	int col = 1, cr;
	TEMPORARY_TEXT(heading_name)

	int comment = FALSE;

	@<Open a file for input, if necessary@>;

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
					if (OUT) PUT_TO(OUT, '{');
					goto NewCharacter;
				}
			}
			if (OUT) PUT_TO(OUT, cr);
		}
	} while (cr != EOF);
	DISCARD_TEXT(command)
	DISCARD_TEXT(argument)
	if (Input_File) { if (DL) STREAM_FLUSH(DL); fclose(Input_File); }

	DISCARD_TEXT(heading_name)
}

@ "If necessary" because our input may be supplied as a wide string, not a
file.

@<Open a file for input, if necessary@> =
	if (index_structure) {
		Input_File = Filenames::fopen(index_structure, "r");
		if (Input_File == NULL) {
			LOG("Filename was %f\n", index_structure);
			internal_error("unable to open template file for the index");
		}
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
	if (Str::eq_wide_string(command, L"index-complete")) { Index::complete(); continue; }

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
