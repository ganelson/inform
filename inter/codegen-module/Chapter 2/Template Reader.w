[TemplateReader::] I6 Template Reader.

Inform 6 meta-language is the language used by template files (with
extension |.i6t|). It is not itself I6 code, but a list of instructions for
making I6 code: most of the content is to be copied over verbatim, but certain
escape sequences cause Inform to insert more elaborate material, or to do something
active.

@h Definitions.

@ =
typedef struct I6T_kit {
	struct inter_reading_state *IRS;
	int no_i6t_file_areas;
	struct pathname *i6t_files[16];
	void (*raw_callback)(struct text_stream *, struct I6T_kit *);
	void (*command_callback)(struct text_stream *, struct text_stream *, struct text_stream *, struct I6T_kit *);
	void *I6T_state;
} I6T_kit;

@ The user (or an extension used by the user) is allowed to register gobbets
of I6T code to be used before, instead of, or after any whole segment or
named part of a segment of the template layer: the following structure holds
such a request.

=
typedef struct I6T_intervention {
	int intervention_stage; /* $-1$ for before, 0 for instead, 1 for after */
	struct text_stream *segment_name;
	struct text_stream *part_name; /* or NULL to mean the entire segment */
	struct text_stream *I6T_matter; /* to be used at the given position, or NULL */
	struct text_stream *alternative_segment; /* to be used at the given position, or NULL */
	int segment_found; /* did the segment name match one actually read? */
	int part_found; /* did the part name? */
	#ifdef CORE_MODULE
	struct parse_node *where_intervention_requested; /* at what sentence? */
	#endif
	MEMORY_MANAGEMENT
} I6T_intervention;

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

tells Inform to act {\it immediately} on the I6T command given, with the
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

I6T_kit TemplateReader::kit_out(inter_reading_state *IRS, void (*A)(struct text_stream *, struct I6T_kit *),
	void (*B)(struct text_stream *, struct text_stream *, struct text_stream *, struct I6T_kit *),
	void *C) {
	I6T_kit kit;
	kit.IRS = IRS;
	kit.raw_callback = A;
	kit.command_callback = B;
	kit.I6T_state = C;
	kit.no_i6t_file_areas = 0;
	return kit;
}

void TemplateReader::extract(text_stream *template_file, I6T_kit *kit) {
	text_stream *SP = Str::new();
	TemplateReader::interpret(SP, NULL, template_file, -1, kit);
	(*(kit->raw_callback))(SP, kit);
}

void TemplateReader::interpret(OUTPUT_STREAM, text_stream *sf, text_stream *segment_name, int N_escape,
	I6T_kit *kit) {
	FILE *Input_File = NULL;
	TEMPORARY_TEXT(default_command);
	TEMPORARY_TEXT(heading_name);
	int skip_part = FALSE, comment = TRUE;
	int col = 1, cr, sfp = 0;

	if (Str::len(segment_name) > 0) TemplateReader::I6T_file_intervene(OUT, BEFORE_LINK_STAGE, segment_name, NULL, kit);
	if ((Str::len(segment_name) > 0) && (TemplateReader::I6T_file_intervene(OUT, INSTEAD_LINK_STAGE, segment_name, NULL, kit))) goto OmitFile;

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
					WRITE("{N");
					goto NewCharacter;
				} else { /* otherwise the open brace was a literal */
					PUT_TO(OUT, '{');
					goto NewCharacter;
				}
			}
			if (cr == '(') {
				@<Read next character from I6T stream@>;
				if (cr == '+') {
					@<Read up to the next plus close-bracket as an I7 expression@>;
					continue;
				} else { /* otherwise the open bracket was a literal */
					PUT_TO(OUT, '(');
					goto NewCharacter;
				}
			}
			PUT_TO(OUT, cr);
		}
	} while (cr != EOF);
	DISCARD_TEXT(command);
	DISCARD_TEXT(argument);
	if (Input_File) { if (DL) STREAM_FLUSH(DL); fclose(Input_File); }

	if ((Str::len(heading_name) > 0) && (Str::len(segment_name) > 0))
		TemplateReader::I6T_file_intervene(OUT, AFTER_LINK_STAGE, segment_name, heading_name, kit);

	OmitFile:
	if (Str::len(segment_name) > 0) TemplateReader::I6T_file_intervene(OUT, AFTER_LINK_STAGE, segment_name, NULL, kit);
	DISCARD_TEXT(default_command);
	DISCARD_TEXT(heading_name);
}

@ We look for the |.i6t| files first in the materials folder, then in the
installed area and lastly (but almost always) in the built-in resources.

@<Open the I6 template file@> =
	Input_File = NULL;
	for (int area=0; area<kit->no_i6t_file_areas; area++)
		if (Input_File == NULL)
			Input_File = Filenames::fopen(
				Filenames::in_folder(kit->i6t_files[area], segment_name), "r");
	if (Input_File == NULL)
		TemplateReader::error("unable to open the template segment '%S'", segment_name);

@ I6 template files are encoded as ISO Latin-1, not as Unicode UTF-8, so
ordinary |fgetc| is used, and no BOM marker is parsed. Lines are assumed
to be terminated with either |0x0a| or |0x0d|. (Since blank lines are
harmless, we take no trouble over |0a0d| or |0d0a| combinations.) The
built-in template files, almost always the only ones used, are line
terminated |0x0a| in Unix fashion.

@<Read next character from I6T stream@> =
	if (Input_File) cr = fgetc(Input_File);
	else if (sf) {
		cr = Str::get_at(sf, sfp); if (cr == 0) cr = EOF; else sfp++;
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
					PUT_TO(OUT, '@');
					WRITE_TO(OUT, "%S", I6T_buffer);
					PUT_TO(OUT, cr);
					break;
				} else {
					LOG("heading begins: <%S>\n", I6T_buffer);
					#ifdef PROBLEMS_MODULE
					Problems::quote_stream(1, I6T_buffer);
					Problems::Issue::unlocated_problem(_p_(...),
						"An unknown '@...' marker has been found at column 0 in "
						"raw Inform 6 template material: specifically, '@%1'. ('@' "
						"has a special meaning in this first column, and this "
						"might clash with its use to introduce an assembly-language "
						"opcode in Inform 6: if that's a problem, you can avoid it "
						"simply by putting one or more spaces or tabs in front of "
						"the opcode(s) to keep them clear of the left margin.)");
					#endif
					#ifndef PROBLEMS_MODULE
					TemplateReader::error("unknown '@...' marker at column 0 in template matter: '%S'", I6T_buffer);
					#endif
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
in particular, no definitions| or angle-bracketed macros. This reader is not
a full-fledged tangler.

@<Act on the at-heading, going in or out of comment mode as appropriate@> =
	switch (inweb_syntax) {
		case INWEB_PARAGRAPH_SYNTAX: {
			if ((Str::len(heading_name) > 0) && (Str::len(segment_name) > 0))
				TemplateReader::I6T_file_intervene(OUT, AFTER_LINK_STAGE, segment_name, heading_name, kit);
			Str::copy_tail(heading_name, command, 2);
			int c;
			while (((c = Str::get_last_char(heading_name)) != 0) &&
				((c == ' ') || (c == '\t') || (c == '.')))
				Str::delete_last_character(heading_name);
			if (Str::len(heading_name) == 0)
				TemplateReader::error("Empty heading name in I6 template file", NULL);
			comment = TRUE; skip_part = FALSE;
			if (Str::len(segment_name) > 0) {
				TemplateReader::I6T_file_intervene(OUT, BEFORE_LINK_STAGE, segment_name, heading_name, kit);
				if (TemplateReader::I6T_file_intervene(OUT, INSTEAD_LINK_STAGE, segment_name, heading_name, kit)) skip_part = TRUE;
			}
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
	LOG("SPONG: %S\n", i7_exp);
	DISCARD_TEXT(i7_exp);
		TemplateReader::error("use of (+ ... +) in the template has been withdrawn: '%S'", i7_exp);

@h Acting on I6T commands.

=
@<Act on I6T command and argument@> =
	@<Act on the I6T segment command@>;
	(*(kit->command_callback))(OUT, command, argument, kit);

@ The |{-segment:...}| command recursively calls the I6T interpreter on the
supplied I6T filename, which means it acts rather like |#include| in C.
Note that because we pass the current output file handle |of| through to
this new invocation, it will have the file open if we do, and closed if
we do. It won't run in indexing mode, so |{-segment:...}| can't be used
safely between |{-open-index}| and |{-close-index}|.

@<Act on the I6T segment command@> =
	if (Str::eq_wide_string(command, L"segment")) {
		(*(kit->raw_callback))(OUT, kit);
		Str::clear(OUT);
		TemplateReader::interpret(OUT, NULL, argument, -1, kit);
		(*(kit->raw_callback))(OUT, kit);
		Str::clear(OUT);
		continue;
	}

@h Template errors.
Errors here used to be basically failed assertions, but inevitably people
reported this as a bug (0001596). It was never intended that I6T coding
be part of the outside-facing language, but for a handful of people
using template-hacking there are a handful of cases that can't be avoided, so...

=
void TemplateReader::error(char *message, text_stream *quote) {
	#ifdef PROBLEMS_MODULE
	TEMPORARY_TEXT(M);
	WRITE_TO(M, message, quote);
	Problems::quote_stream(1, M);
	Problems::Issue::handmade_problem(_p_(...));
	Problems::issue_problem_segment(
		"I ran into a mistake in a template file: %1. The I6 "
		"template files (or .i6t files) are a very low-level part of Inform, "
		"and errors like this will only occur if the standard installation "
		"has been amended or damaged. One possibility is that you're using "
		"an extension which does some 'template hacking', as it's called, "
		"but made a mistake doing so.");
	Problems::issue_problem_end();
	DISCARD_TEXT(M);
	#endif
	#ifndef PROBLEMS_MODULE
	Errors::with_text(message, quote);
	#endif
}

@h Intervention.
This is a system allowing the user to hang explicit code before, instead of
or after any part of any segment of the I6T files in use.

=
void TemplateReader::new_intervention(int stage, text_stream *segment,
	text_stream *part, text_stream *i6, text_stream *seg, void *ref) {
	I6T_intervention *i6ti = NULL;
	if (stage == INSTEAD_LINK_STAGE) {
		LOOP_OVER(i6ti, I6T_intervention)
			if ((i6ti->intervention_stage == 0) &&
				(Str::eq(i6ti->segment_name, segment)) &&
				(Str::eq(i6ti->part_name, part)))
				break;
	}
	if (i6ti == NULL) i6ti = CREATE(I6T_intervention);
	i6ti->intervention_stage = stage;
	i6ti->segment_name = Str::duplicate(segment);
	i6ti->part_name = Str::duplicate(part);
	i6ti->I6T_matter = i6;
	i6ti->alternative_segment = Str::duplicate(seg);
	i6ti->segment_found = FALSE;
	i6ti->part_found = FALSE;
	#ifdef CORE_MODULE
	i6ti->where_intervention_requested = (parse_node *) ref;
	#endif
	LOGIF(TEMPLATE_READING, "New stage %d Segment %S Part %S\n", stage, segment, part);
}

@ An intervention "instead" (stage 0) replaces any existing one, but at other
stages -- before and after -- they are accumulated.

=
int TemplateReader::I6T_file_intervene(OUTPUT_STREAM, int stage, text_stream *segment, text_stream *part, I6T_kit *kit) {
	I6T_intervention *i6ti;
	int rv = FALSE;
	if (Str::eq_wide_string(segment, L"Main.i6t")) return rv;
	LOGIF(TEMPLATE_READING, "Stage %d Segment %S Part %S\n", stage, segment, part);
	LOOP_OVER(i6ti, I6T_intervention)
		if ((i6ti->intervention_stage == stage) &&
			(Str::eq(i6ti->segment_name, segment))) {
			i6ti->segment_found = TRUE;
			if (Str::eq(i6ti->part_name, part) == FALSE) continue;
			i6ti->part_found = TRUE;
			#ifdef CORE_MODULE
			current_sentence = i6ti->where_intervention_requested;
			#endif
			LOGIF(TEMPLATE_READING, "Intervention at stage %d Segment %S Part %S\n", stage, segment, part);
			if (i6ti->I6T_matter) {
				TemplateReader::interpret(OUT, i6ti->I6T_matter, NULL, -1, kit);
			}
			if (Str::len(i6ti->alternative_segment) > 0)
				TemplateReader::interpret(OUT, NULL, i6ti->alternative_segment, -1, kit);
			if (stage == 0) rv = TRUE;
		}
	return rv;
}

@ At the end of the run, we check to see if any of the interventions were
never acted on. This generally means the user mistyped the name of a section
or part -- which would otherwise be an error very difficult to detect.

=
void TemplateReader::report_unacted_upon_interventions(void) {
	I6T_intervention *i6ti;
	LOOP_OVER(i6ti, I6T_intervention) {
		if ((i6ti->segment_found == FALSE) && (Str::eq_wide_string(i6ti->segment_name, L"Main.i6t") == FALSE)) {
			#ifdef CORE_MODULE
			current_sentence = i6ti->where_intervention_requested;
			#endif
			LOG("Intervention at stage %d Segment %S Part %S\n", i6ti->intervention_stage, i6ti->segment_name, i6ti->part_name);
			#ifdef PROBLEMS_MODULE
			Problems::Issue::sentence_problem(_p_(PM_NoSuchTemplate),
				"no template file of that name was ever read in",
				"so this attempt to intervene had no effect. "
				"The template files have names like 'Output.i6t', 'Parser.i6t' "
				"and so on. (Looking at the typeset form of the template, "
				"available at the Inform website, may help.)");
			#endif
			#ifndef PROBLEMS_MODULE
			TemplateReader::error("was asked to intervene on this segment, but never saw it: '%S'", i6ti->segment_name);
			#endif
		} else if ((i6ti->part_found == FALSE) && (i6ti->part_name) &&
			(Str::eq_wide_string(i6ti->segment_name, L"Main.i6t") == FALSE)) {
			#ifdef CORE_MODULE
			current_sentence = i6ti->where_intervention_requested;
			#endif
			LOG("Intervention at stage %d Segment %S Part %S\n", i6ti->intervention_stage, i6ti->segment_name, i6ti->part_name);
			#ifdef PROBLEMS_MODULE
			Problems::Issue::sentence_problem(_p_(PM_NoSuchPart),
				"that template file didn't have a part with that name",
				"so this attempt to intervene had no effect. "
				"Each template file is divided internally into a number of "
				"named parts, and you have to quote their names precisely. "
				"(Looking at the typeset form of the template, available at "
				"the Inform website, may help.)");
			#endif
			#ifndef PROBLEMS_MODULE
			TemplateReader::error("was asked to intervene on this part, but never saw it: '%S'", i6ti->part_name);
			#endif
		}
	}
}
