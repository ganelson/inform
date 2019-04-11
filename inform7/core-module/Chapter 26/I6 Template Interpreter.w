[TemplateFiles::] I6 Template Interpreter.

Inform 6 meta-language is the language used by template files (with
extension |.i6t|). It is not itself I6 code, but a list of instructions for
making I6 code: most of the content is to be copied over verbatim, but certain
escape sequences cause Inform to insert more elaborate material, or to do something
active. The entire top-level logic of Inform is carried out by interpreting the
|Main.i6t| file in this way.

@h Definitions.

@ The following flag is set by the |-noindex| command line option.

= (early code)
int do_not_generate_index = FALSE;

@h Syntax of I6T files.
The syntax of these files has been designed so that a valid I6T file is
also a valid Inweb section file. This means that no tangling is required to
make the I6T files: they can be, and indeed are, simply copied verbatim
from Appendix B of the source web.

Formally, an I6T file consists of a preamble followed by one or more parts.
The preamble takes the form:

	|B/name: Longer Form of Name.|
	| |
	|@Purpose: ...|
	| |
	|@-------------------------------------------------------------------------------|

(for some number of dashes). Each part begins with a heading line in the form

	|@p Title.|

At some point during the part, a heading line

	|@c|

introduces the code of the part. When Inform interprets an I6T file, it ignores
the preamble and the material in every part before the |@c| heading: these
are commentary.

It actually doesn't matter if a template file contains lines longer than
this, so long as they do not occur inside |{-lines:...}| and |{-endlines}|,
and so long as no individual braced command |{-...}| exceeds this length.

@d MAX_I6T_LINE_LENGTH 1024

@ We can regard the whole Inform program as basically a filter: it copies its
input, the |Main.i6t| template file, directly into its output, but making
certain replacements along the way.

The code portions of |.i6t| files are basically written in I6, but with a
special escape syntax:

	|{-command:argument}|

tells Inform to act immediately on the I6T command given, with the
argument supplied. One of these commands is special:

	|{-lines:commandname}|

tells Inform that all subsequent lines in the I6T file, up to the next
|{-endlines}|, are to be read as a series of arguments for the
|commandname| command. Thus,

	|{-lines:admire}|
	|Jackson Pollock|
	|Paul Klee|
	|Wassily Kandinsky|
	|{-endlines}|

is a shorthand form for:

	|{-admire:Jackson Pollock}{-admire:Paul Klee}{-admire:Wassily Kandinsky}|

The following comment syntax is useful mainly for commenting out commands:

	|{-! Something very clever happens next.}|

The commands all either instruct Inform to do something (say, traverse the
parse tree and convert its assertions to inferences) but output nothing,
or else to compile some I6 code to the output. There are no control structures,
no variables: I6T commands do not amount to a programming language.

@ I7 expressions can be included in I6T code exactly as in inline invocation
definitions: thus

	|Constant FROG_CLASS = (+ pond-dwelling amphibian +);|

will expand "pond-dwelling amphibian" into the I6 translation of the kind
of object with this name. Because of this syntax, one has to watch out for
I6 code like so:

	|if (++counter_of_some_kind > 0) ...|

which can trigger an unwanted |(+|.

@ It is not quite true that the following routine acts as a filter from
input to output, because:

(i) It skips the preamble and the commentary portion of each part in the input.

(ii) It has an |active| mode, outside of which it ignores most commands and
copies no output -- it begins in active mode and leaves it only when Inform
issues problem messages, so that subsequent commands almost certainly
cannot safely be used. In a successful compilation run, the interpreter
remains in active mode throughout. Otherwise, generally speaking, it goes
into passive mode as soon as an I6T command has resulted in Problem messages,
and then in stays in passive mode until the output file is closed again;
then it goes back into active mode to carry out some shutting-down-gracefully
steps.

(iii) The output stream is not always open. In fact, it starts unopened (and
with |OUT| set to null); two of the I6T commands open and close it. When
the file isn't open, no output can be written, but I6T commands telling Inform
to do something can still take effect: in fact, the |Main.i6t| file begins
with dozens of I6T commands before the output file is opened, and concludes
with a couple of dozen more after it has been closed.

(iv) It can abort, cleanly exiting Inform when it does so, if a global flag
is set as a result of work done by one of its commands. In fact, this is
used only to exit Inform early after performing an extension census when called
with the command line option |-census|, and can never happen on a compilation
run, whatever problems or disasters may occur.

@ The I6T interpreter is a single routine which implements the description
above:

=
void TemplateFiles::interpret(OUTPUT_STREAM, wchar_t *sf, text_stream *segment_name, int N_escape) {
	FILE *Input_File = NULL;
	TEMPORARY_TEXT(default_command);
	TEMPORARY_TEXT(heading_name);
	int active = TRUE, indexing = FALSE, skip_part = FALSE, comment = TRUE;
	int col = 1, cr, sfp = 0;

	if (Str::len(segment_name) > 0) {
		@<Open the I6 template file@>;
		comment = TRUE;
	} else comment = FALSE;

	TEMPORARY_TEXT(command);
	TEMPORARY_TEXT(argument);
	do {
		Str::clear(command);
		Str::clear(argument);
		@<Read next character from I6T stream@>;
		NewCharacter: if (cr == EOF) break;
		if ((cr == '@') && (col == 1)) {
			int inweb_syntax = -1;
			@<Read the rest of line as an at-heading@>;
			@<Act on the at-heading, going in or out of comment mode as appropriate@>;
			continue;
		}
		if (comment == FALSE) {
			if (Str::len(default_command) > 0) {
				if ((cr == 10) || (cr == 13)) continue; /* skip blank lines here */
				@<Set the command to the default, and read rest of line as argument@>;
				if ((Str::get_first_char(argument) == '!') ||
					(Str::get_first_char(argument) == 0)) continue; /* skip blanks and comments */
				if (Str::eq_wide_string(argument, L"{-endlines}")) Str::clear(default_command);
				else @<Act on I6T command and argument@>;
				continue;
			}
			if (cr == '{') {
				@<Read next character from I6T stream@>;
				if (cr == '-') {
					@<Read up to the next close brace as an I6T command and argument@>;
					if (Str::get_first_char(command) == '!') continue;
					@<Act on I6T command and argument@>;
					continue;
				} else if ((cr == 'N') && (N_escape >= 0)) {
					@<Read next character from I6T stream@>;
					if (cr == '}') {
						WRITE("%d", N_escape);
						continue;
					}
					if ((OUT) && (active)) WRITE("{N");
					goto NewCharacter;
				} else { /* otherwise the open brace was a literal */
					if ((OUT) && (active)) PUT_TO(OUT, '{');
					goto NewCharacter;
				}
			}
			if (cr == '(') {
				@<Read next character from I6T stream@>;
				if (cr == '+') {
					@<Read up to the next plus close-bracket as an I7 expression@>;
					continue;
				} else { /* otherwise the open bracket was a literal */
					if ((OUT) && (active)) PUT_TO(OUT, '(');
					goto NewCharacter;
				}
			}
			if ((OUT) && (active)) PUT_TO(OUT, cr);
		}
	} while (cr != EOF);
	DISCARD_TEXT(command);
	DISCARD_TEXT(argument);
	if (Input_File) { if (DL) STREAM_FLUSH(DL); fclose(Input_File); }

	DISCARD_TEXT(default_command);
	DISCARD_TEXT(heading_name);
}

@ We look for the |.i6t| files first in the materials folder, then in the
installed area and lastly (but almost always) in the built-in resources.

@<Open the I6 template file@> =
	Input_File = NULL;
	for (int area=0; area<NO_FS_AREAS; area++)
		if (Input_File == NULL)
			Input_File = Filenames::fopen(
				Filenames::in_folder(pathname_of_i6t_files[area], segment_name), "r");
	if (Input_File == NULL) {
		WRITE_TO(STDERR, "inform: Unable to open segment <%S>\n", segment_name);
		Problems::Issue::unlocated_problem(_p_(BelievedImpossible), /* or anyway not usefully testable */
			"I couldn't open a requested I6T segment: see the console "
			"output for details.");
	}

@ I6 template files are encoded as ISO Latin-1, not as Unicode UTF-8, so
ordinary |fgetc| is used, and no BOM marker is parsed. Lines are assumed
to be terminated with either |0x0a| or |0x0d|. (Since blank lines are
harmless, we take no trouble over |0a0d| or |0d0a| combinations.) The
built-in template files, almost always the only ones used, are line
terminated |0x0a| in Unix fashion.

@<Read next character from I6T stream@> =
	if (Input_File) cr = fgetc(Input_File);
	else if (sf) {
		cr = sf[sfp]; if (cr == 0) cr = EOF; else sfp++;
	} else cr = EOF;
	col++; if ((cr == 10) || (cr == 13)) col = 0;

@ Anything following an at-character in the first column is looked at to see if
it's a heading, that is, an Inweb syntax:

@d INWEB_PARAGRAPH_SYNTAX 1
@d INWEB_CODE_SYNTAX 2
@d INWEB_DASH_SYNTAX 3
@d INWEB_PURPOSE_SYNTAX 4

@<Read the rest of line as an at-heading@> =
	TEMPORARY_TEXT(I6T_buffer);
	int i = 0, committed = FALSE, unacceptable_character = FALSE;
	while (i<MAX_I6T_LINE_LENGTH) {
		@<Read next character from I6T stream@>;
		if ((committed == FALSE) && ((cr == 10) || (cr == 13) || (cr == ' '))) {
			if (Str::eq_wide_string(I6T_buffer, L"p")) inweb_syntax = INWEB_PARAGRAPH_SYNTAX;
			else if (Str::eq_wide_string(I6T_buffer, L"c")) inweb_syntax = INWEB_CODE_SYNTAX;
			else if (Str::get_first_char(I6T_buffer) == '-') inweb_syntax = INWEB_DASH_SYNTAX;
			else if (Str::begins_with_wide_string(I6T_buffer, L"Purpose:")) inweb_syntax = INWEB_PURPOSE_SYNTAX;
			committed = TRUE;
			if (inweb_syntax == -1) {
				if (unacceptable_character == FALSE) {
					if ((OUT) && (active)) {
						PUT_TO(OUT, '@');
						WRITE_TO(OUT, "%S", I6T_buffer);
						PUT_TO(OUT, cr);
					}
					break;
				} else {
					LOG("heading begins: <%S>\n", I6T_buffer);
					Problems::quote_stream(1, I6T_buffer);
					Problems::Issue::unlocated_problem(_p_(PM_BadTemplateAtSign),
						"An unknown '@...' marker has been found at column 0 in "
						"raw Inform 6 template material: specifically, '@%1'. ('@' "
						"has a special meaning in this first column, and this "
						"might clash with its use to introduce an assembly-language "
						"opcode in Inform 6: if that's a problem, you can avoid it "
						"simply by putting one or more spaces or tabs in front of "
						"the opcode(s) to keep them clear of the left margin.)");
				}
			}
		}
		if (!(((cr >= 'A') && (cr <= 'Z')) || ((cr >= 'a') && (cr <= 'z'))
			|| ((cr >= '0') && (cr <= '9'))
			|| (cr == '-') || (cr == '>') || (cr == ':') || (cr == '_')))
			unacceptable_character = TRUE;
		if ((cr == 10) || (cr == 13)) break;
		PUT_TO(I6T_buffer, cr);
	}
	Str::copy(command, I6T_buffer);
	DISCARD_TEXT(I6T_buffer);

@ As can be seen, only a small minority of Inweb syntaxes are allowed:
in particular, no |@d| or angle-bracketed macros. This interpreter is not
a full-fledged tangler.

@<Act on the at-heading, going in or out of comment mode as appropriate@> =
	switch (inweb_syntax) {
		case INWEB_PARAGRAPH_SYNTAX: {
			Str::copy_tail(heading_name, command, 2);
			int c;
			while (((c = Str::get_last_char(heading_name)) != 0) &&
				((c == ' ') || (c == '\t') || (c == '.')))
				Str::delete_last_character(heading_name);
			if (Str::len(heading_name) == 0)
				TemplateFiles::error("Empty heading name in I6 template file");
			comment = TRUE; skip_part = FALSE;
			break;
		}
		case INWEB_CODE_SYNTAX:
			if (skip_part == FALSE) comment = FALSE;
			break;
		case INWEB_DASH_SYNTAX: break;
		case INWEB_PURPOSE_SYNTAX: break;
	}

@ Here we are in |{-lines:...}| mode, so that the entire line of the file
is to be read as an argument. Note that initial and trailing white space on
the line is deleted: this makes it easier to lay out I6T template files
tidily.

@<Set the command to the default, and read rest of line as argument@> =
	Str::copy(command, default_command);
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

@ And similarly, for the |(+| ... |+)| notation used to mark I7 material
within I6:

@<Read up to the next plus close-bracket as an I7 expression@> =
	TEMPORARY_TEXT(i7_exp);
	while (TRUE) {
		@<Read next character from I6T stream@>;
		if (cr == EOF) break;
		if ((cr == ')') && (Str::get_last_char(i7_exp) == '+')) {
			Str::delete_last_character(i7_exp); break; }
		PUT_TO(i7_exp, cr);
	}
	TemplateFiles::compile_I7_from_I6(NULL, OUT, i7_exp);
	DISCARD_TEXT(i7_exp);

@h Acting on I6T commands.
Only a few commands work even in passive mode, but they include file-handling
because the close-file command needs to be able to get out of passive mode
and back into active (and besides, because the file still needs to be closed).

The |{-type:...}| command hands over the argument to a more specific
interpreter, one which constructs kinds.

The |{-segment:...}| command recursively calls the I6T interpreter on the
supplied I6T filename, which means it acts rather like |#include| in C.
Note that because we pass the current output file handle |of| through to
this new invocation, it will have the file open if we do, and closed if
we do. It will run in active mode, but that's fine, because we're in active
mode too. It won't run in indexing mode, so |{-segment:...}| can't be used
safely between |{-open-index}| and |{-close-index}|.

=
@<Act on I6T command and argument@> =
	@<Act on the I6T lines command@>;
	if (active == FALSE) continue;
	if (Str::eq_wide_string(command, L"plugin")) { Plugins::Manage::command(argument); continue; }
	if (Str::eq_wide_string(command, L"type")) { Kinds::Interpreter::despatch_kind_command(argument); continue; }
	@<Act on the I6T counter command@>;
	@<Act on an I6T indexing command@>;

	LOG("command: <%S> argument: <%S>\n", command, argument);
	Problems::quote_stream(1, command);
	Problems::Issue::unlocated_problem(_p_(PM_TemplateError),
		"In an explicit Inform 6 code insertion, I recognise a few special "
		"notations in the form '{-command}'. This time, though, the unknown notation "
		"{-%1} has been used, and this is an error. (It seems very unlikely indeed "
		"that this could be legal Inform 6 which I'm misreading, but if so, try "
		"adjusting the spacing to make this problem message go away.)");

@ There is no corresponding code here to act on |{-endlines}| because it is
not valid as a free-standing command: it can only occur at the end of a
|{-lines:...}| block, and is acted upon above.

@<Act on the I6T lines command@> =
	if (Str::eq_wide_string(command, L"lines")) {
		Str::copy(default_command, argument);
		continue;
	}

@h Indexing commands.
Commands in between |{-open-index}| and |{-close-index}| are skipped when
Inform has been called with a command-line switch to disable the index. (As is
done by |intest|, to save time.) |{-index:name}| opens the index file
called |name|.

@<Act on an I6T indexing command@> =
	if (Str::eq_wide_string(command, L"open-index")) { indexing = TRUE; continue; }
	if (Str::eq_wide_string(command, L"close-index")) { indexing = FALSE; continue; }

	if ((indexing) && (do_not_generate_index)) continue;
	if (Str::eq_wide_string(command, L"index-complete")) { if (indexing) Index::complete(); continue; }

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
			TEMPORARY_TEXT(leafname);
			Str::copy(leafname, titling);
			if (Regexp::match(&mr2, leafname, L"(%C+?) (%c+)")) Str::copy(leafname, mr2.exp[0]);
			WRITE_TO(leafname, ".html");
			Index::open_file(leafname, titling, -1, explanation);
			Regexp::dispose_of(&mr2);
			DISCARD_TEXT(leafname);
		} else {
			internal_error("bad index format");
		}
		Regexp::dispose_of(&mr);
		continue;
	}

@h Commands accessing Inform internals.
The following expands to the number of labels produced for a given label namespace.

@<Act on the I6T counter command@> =
	if (Str::eq_wide_string(command, L"counter")) {
		if (OUT == NULL) continue;
		WRITE("%d", JumpLabels::read_counter(argument, NOT_APPLICABLE)); continue;
	}

@h Template errors.
Errors here used to be basically failed assertions, but inevitably people
reported this as a bug (0001596). It was never intended that I6T coding
be part of the outside-facing language, but for a handful of people
using template-hacking there are a handful of cases that can't be avoided, so...

=
void TemplateFiles::error(char *message) {
	Problems::quote_text(1, message);
	Problems::Issue::handmade_problem(_p_(...));
	Problems::issue_problem_segment(
		"I ran into a mistake in a template file command: %1. The I6 "
		"template files (or .i6t files) are a very low-level part of Inform, "
		"and errors like this will only occur if the standard installation "
		"has been amended or damaged. One possibility is that you're using "
		"an extension which does some 'template hacking', as it's called, "
		"but made a mistake doing so.");
	Problems::issue_problem_end();
}

@h I7 expression evaluation.
This is not quite like regular expression evaluation, because we want
"room" and "lighted" to be evaluated as the I6 translation of the
relevant class or property, rather than as code to test the predicate
"$X$ is a room" or "$X$ is lighted", and similarly for bare names
of defined adjectives. So:

=
void TemplateFiles::compile_I7_from_I6(value_holster *VH, text_stream *OUT, text_stream *p) {
	if ((VH) && (VH->vhmode_wanted == INTER_VOID_VHMODE)) {
		Emit::evaluation();
		Emit::down();
	}

	TemplateFiles::compile_I7_from_I6_inner(VH, OUT, p);

	if ((VH) && (VH->vhmode_wanted == INTER_VOID_VHMODE)) {
		Emit::up();
	}
}

void TemplateFiles::compile_I7_from_I6_inner(value_holster *VH, text_stream *OUT, text_stream *p) {
	wording LW = Feeds::feed_stream(p);

	if (<property-name>(LW)) {
		if (VH)
			Emit::val_iname(K_value, Properties::iname(<<rp>>));
		else
			WRITE_TO(OUT, "%n", Properties::iname(<<rp>>));
		return;
	}

	if (<k-kind>(LW)) {
		kind *K = <<rp>>;
		if (Kinds::Compare::lt(K, K_object)) {
			if (VH)
				Emit::val_iname(K_value, Kinds::RunTime::I6_classname(K));
			else
				WRITE_TO(OUT, "%n", Kinds::RunTime::I6_classname(K));
			return;
		}
	}

	instance *I = Instances::parse_object(LW);
	if (I) {
		if (VH)
			Emit::val_iname(K_value, Instances::iname(<<rp>>));
		else
			WRITE_TO(OUT, "%~I", I);
		return;
	}

	adjectival_phrase *aph = Adjectives::parse(LW);
	if (aph) {
		if (Adjectives::Meanings::write_adjective_test_routine(VH, aph)) return;
		Problems::Issue::unlocated_problem(_p_(BelievedImpossible),
			"You tried to use '(+' and '+)' to expand to the Inform 6 routine "
			"address of an adjective, but it was an adjective with no meaning.");
		return;
	}

	#ifdef IF_MODULE
	int initial_problem_count = problem_count;
	#endif
	parse_node *spec = NULL;
	if (<s-value>(LW)) spec = <<rp>>;
	else spec = Specifications::new_UNKNOWN(LW);
	#ifndef IF_MODULE
	Emit::val(K_number, LITERAL_IVAL, 0);
	#endif
	#ifdef IF_MODULE
	if (initial_problem_count < problem_count) return;
	Dash::check_value(spec, NULL);
	if (initial_problem_count < problem_count) return;
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	if (VH)
		Specifications::Compiler::emit_as_val(K_value, spec);
	else {
		nonlocal_variable *nlv = NonlocalVariables::parse(LW);
		if (nlv) {
			PUT(URL_SYMBOL_CHAR);
			Inter::SymbolsTables::symbol_to_url_name(OUT, InterNames::to_symbol(NonlocalVariables::iname(nlv)));
			PUT(URL_SYMBOL_CHAR);
		} else {
			value_holster VH2 = Holsters::new(INTER_DATA_VHMODE);
			Specifications::Compiler::compile_inner(&VH2, spec);
			inter_t v1 = 0, v2 = 0;
			Holsters::unholster_pair(&VH2, &v1, &v2);
			if (v1 == ALIAS_IVAL) {
				PUT(URL_SYMBOL_CHAR);
				inter_symbols_table *T = Inter::Packages::scope(Packaging::current_enclosure()->actual_package);
				inter_symbol *S = Inter::SymbolsTables::symbol_from_id(T, v2);
				Inter::SymbolsTables::symbol_to_url_name(OUT, S);
				PUT(URL_SYMBOL_CHAR);
			} else {
				CodeGen::val_from(OUT, Emit::IRS(), v1, v2);
			}
		}
	}
	END_COMPILATION_MODE;
	#endif
}

@h The build constant.
That was the end of the template interpreter. Now, since this version-numbering
constant belongs nowhere else, we provide a single I6T command in this section
of Inform: the following routine performs |{-callv:TemplateFiles::compile_build_number}|.

=
void TemplateFiles::compile_build_number(void) {
	TEMPORARY_TEXT(build);
	WRITE_TO(build, "%B", TRUE);
	inter_name *iname = InterNames::iname(NI_BUILD_COUNT_INAME);
	Packaging::house(iname, Packaging::generic_resource(BASICS_SUBPACKAGE));
	packaging_state save = Packaging::enter_home_of(iname);
	Emit::named_string_constant(iname, build);
	Packaging::exit(save);
	DISCARD_TEXT(build);
}

@h Registration of sentence handlers.
The following routine is placed here, right at the end of the Inform code,
because at this point all of the sentence handlers -- with names like
|TABLE_SH_handler| -- have now been created.

=
void TemplateFiles::register_sentence_handlers(void) {
	@<Add sentence handlers for the top-level node types@>;
	@<Add sentence handlers for the SENTENCE/VERB node types@>;
}

@ This is all of the node types still present at the top level of the tree
at the end of sentence-breaking.

@<Add sentence handlers for the top-level node types@> =
	REGISTER_SENTENCE_HANDLER(TRACE_SH);
	REGISTER_SENTENCE_HANDLER(BEGINHERE_SH);
	REGISTER_SENTENCE_HANDLER(ENDHERE_SH);
	#ifdef IF_MODULE
	REGISTER_SENTENCE_HANDLER(BIBLIOGRAPHIC_SH);
	#endif
	REGISTER_SENTENCE_HANDLER(INFORM6CODE_SH);
	REGISTER_SENTENCE_HANDLER(COMMAND_SH);
	REGISTER_SENTENCE_HANDLER(ROUTINE_SH);
	REGISTER_SENTENCE_HANDLER(TABLE_SH);
	REGISTER_SENTENCE_HANDLER(EQUATION_SH);
	REGISTER_SENTENCE_HANDLER(HEADING_SH);
	REGISTER_SENTENCE_HANDLER(SENTENCE_SH);

@ And here are all of the verb types found in |AVERB_NT| nodes which are
first children of |SENTENCE_NT| nodes.

@<Add sentence handlers for the SENTENCE/VERB node types@> =
	REGISTER_SENTENCE_HANDLER(ASSERT_SH);
	REGISTER_SENTENCE_HANDLER(SPECIAL_MEANING_SH);
