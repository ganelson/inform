[TemplateReader::] I6 Template Reader.

Inform 6 meta-language is the language used by template files (with
extension |.i6t|); we need tp be able to read it here in order to
assimilate template code.

@h Interventions.
The user (or an extension used by the user) is allowed to register gobbets
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
	CLASS_DEFINITION
} I6T_intervention;

@ =
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
		if ((stage == CATCH_ALL_LINK_STAGE) ||
			((i6ti->intervention_stage == stage) &&
				(Str::eq(i6ti->segment_name, segment)))) {
			i6ti->segment_found = TRUE;
			if (Str::eq(i6ti->part_name, part) == FALSE) continue;
			i6ti->part_found = TRUE;
			#ifdef CORE_MODULE
			current_sentence = i6ti->where_intervention_requested;
			#endif
			LOGIF(TEMPLATE_READING, "Intervention at stage %d Segment %S Part %S\n", stage, segment, part);
			if (i6ti->I6T_matter) {
				TemplateReader::interpret(OUT, i6ti->I6T_matter, NULL, -1, kit, NULL);
			}
			if (Str::len(i6ti->alternative_segment) > 0)
				TemplateReader::interpret(OUT, NULL, i6ti->alternative_segment, -1, kit, NULL);
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
			LOG("Intervention at stage %d Segment %S Part %S\n",
				i6ti->intervention_stage, i6ti->segment_name, i6ti->part_name);
			#ifdef PROBLEMS_MODULE
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(Untestable),
				"no template file of that name was ever read in",
				"so this attempt to intervene had no effect. "
				"The template files have names like 'Output.i6t', 'Parser.i6t' "
				"and so on. (Looking at the typeset form of the template, "
				"available at the Inform website, may help.)");
			#endif
			#ifndef PROBLEMS_MODULE
			PipelineErrors::kit_error("was asked to intervene on this segment, but never saw it: '%S'", i6ti->segment_name);
			#endif
		} else if ((i6ti->part_found == FALSE) && (i6ti->part_name) &&
			(Str::eq_wide_string(i6ti->segment_name, L"Main.i6t") == FALSE)) {
			#ifdef CORE_MODULE
			current_sentence = i6ti->where_intervention_requested;
			#endif
			LOG("Intervention at stage %d Segment %S Part %S\n",
				i6ti->intervention_stage, i6ti->segment_name, i6ti->part_name);
			#ifdef PROBLEMS_MODULE
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(Untestable),
				"that template file didn't have a part with that name",
				"so this attempt to intervene had no effect. "
				"Each template file is divided internally into a number of "
				"named parts, and you have to quote their names precisely. "
				"(Looking at the typeset form of the template, available at "
				"the Inform website, may help.)");
			#endif
			#ifndef PROBLEMS_MODULE
			PipelineErrors::kit_error("was asked to intervene on this part, but never saw it: '%S'", i6ti->part_name);
			#endif
		}
	}
}

@h I6T kits.
These are used to abstract calls to the I6T reader, so that customers of
varying dispositions can do different things with the code parsed.

@ =
typedef struct I6T_kit {
	struct inter_bookmark *IBM;
	int no_i6t_file_areas;
	struct pathname *i6t_files[16];
	void (*raw_callback)(struct text_stream *, struct I6T_kit *);
	void (*command_callback)(struct text_stream *, struct text_stream *, struct text_stream *, struct I6T_kit *);
	void *I6T_state;
} I6T_kit;

@ =
I6T_kit TemplateReader::kit_out(inter_bookmark *IBM, void (*A)(struct text_stream *, struct I6T_kit *),
	void (*B)(struct text_stream *, struct text_stream *, struct text_stream *, struct I6T_kit *),
	void *C) {
	I6T_kit kit;
	kit.IBM = IBM;
	kit.raw_callback = A;
	kit.command_callback = B;
	kit.I6T_state = C;
	kit.no_i6t_file_areas = 0;
	return kit;
}

@h Syntax of I6T files.
The syntax of these files has been designed so that a valid I6T file is
also a valid Inweb section file. (Inweb now has two formats, an old and a
new one: here we can read either, though the I6T sources in the main Inform
distribution have been modernised to the new syntax.) Many Inweb syntaxes
are, however, not allowed in I6T: really, you should use only |@h| headings
and the |=| sign to divide commentary from text. Macros and definitions, in
particular, are not permitted. This means that no real tangling is required
to make the I6T files.

The entire range of possibilities is shown here:
= (text as Inweb)
	Circuses.
	 
	This hypothetical I6T file provides support for holding circuses.
	 
	@h Start.
	This routine is called when a big top must be raised. Note that the
	elephants must first be watered (see Livestock.i6t).
	
	=
	[ RaiseBT c;
	...
	];
=
...and so on. As with Inweb, the commentary is removed when we read this
code. While this doesn't allow for full-on literate programming, it does
permit a generous amount of annotation.

@ One restriction. It actually doesn't matter if a template file contains
lines longer than this, so long as they do not occur inside |{-lines:...}| and
|{-endlines}|, and so long as no individual braced command |{-...}| exceeds
this length.

@d MAX_I6T_LINE_LENGTH 1024

@ The I6T interpreter is then a single routine to implement the description
above, though note that it can act on interventions as well. (But in modern
Inform usage, often there won't be any, because templates for the Standard
Rules and so forth are assimilated in stand-alone runs of the code generator,
and therefore no interventions will have happened.)

=
void TemplateReader::extract(text_stream *template_file, I6T_kit *kit) {
	text_stream *SP = Str::new();
	TemplateReader::interpret(SP, NULL, template_file, -1, kit, NULL);
	(*(kit->raw_callback))(SP, kit);
}

typedef struct contents_section_state {
	struct linked_list *sects; /* of |text_stream| */
	int active;
} contents_section_state;

void TemplateReader::interpret(OUTPUT_STREAM, text_stream *sf,
	text_stream *segment_name, int N_escape, I6T_kit *kit, filename *Input_Filename) {
	if (Str::eq(segment_name, I"all")) {
		for (int area=0; area<kit->no_i6t_file_areas; area++) {
			pathname *P = Pathnames::up(kit->i6t_files[area]);
			web_md *Wm = WebMetadata::get(P, NULL, V2_SYNTAX, NULL, FALSE, TRUE, NULL);
			chapter_md *Cm;
			LOOP_OVER_LINKED_LIST(Cm, chapter_md, Wm->chapters_md) {
				section_md *Sm;
				LOOP_OVER_LINKED_LIST(Sm, section_md, Cm->sections_md) {
					filename *SF = Sm->source_file_for_section;
					TemplateReader::interpret(OUT, sf, Sm->sect_title, N_escape, kit, SF);
				}
			}
		}
		return;
	}
	TEMPORARY_TEXT(heading_name)
	int skip_part = FALSE, comment = TRUE, extract = FALSE;
	int col = 1, cr, sfp = 0;

	if (Str::len(segment_name) > 0)
		TemplateReader::I6T_file_intervene(OUT, BEFORE_LINK_STAGE, segment_name, NULL, kit);
	if ((Str::len(segment_name) > 0) &&
		(TemplateReader::I6T_file_intervene(OUT, INSTEAD_LINK_STAGE, segment_name, NULL, kit)))
		goto OmitFile;

	FILE *Input_File = NULL;
	if ((Str::len(segment_name) > 0) || (Input_Filename)) {
		@<Open the I6 template file@>;
		comment = TRUE;
	} else comment = FALSE;

	@<Interpret the I6T file@>;

	if (Input_File) { if (DL) STREAM_FLUSH(DL); fclose(Input_File); }

	if ((Str::len(heading_name) > 0) && (Str::len(segment_name) > 0))
		TemplateReader::I6T_file_intervene(OUT, AFTER_LINK_STAGE, segment_name, heading_name, kit);

	OmitFile:
	if (Str::len(segment_name) > 0)
		TemplateReader::I6T_file_intervene(OUT, AFTER_LINK_STAGE, segment_name, NULL, kit);
	DISCARD_TEXT(heading_name)
}

@ We look for the |.i6t| files in a list of possible locations supplied as
part of the I6T kit.

@<Open the I6 template file@> =
	if (Input_Filename)
		Input_File = Filenames::fopen(Input_Filename, "r");
	for (int area=0; area<kit->no_i6t_file_areas; area++)
		if (Input_File == NULL)
			Input_File = Filenames::fopen(
				Filenames::in(kit->i6t_files[area], segment_name), "r");
	if (Input_File == NULL)
		PipelineErrors::kit_error("unable to open the template segment '%S'", segment_name);

@ 

@<Interpret the I6T file@> =
	TEMPORARY_TEXT(command)
	TEMPORARY_TEXT(argument)
	do {
		Str::clear(command);
		Str::clear(argument);
		@<Read next character from I6T stream@>;
		NewCharacter: if (cr == EOF) break;
		if (((cr == '@') || (cr == '=')) && (col == 1)) {
			int inweb_syntax = -1;
			if (cr == '=') @<Read the rest of line as an equals-heading@>
			else @<Read the rest of line as an at-heading@>;
			@<Act on the heading, going in or out of comment mode as appropriate@>;
			continue;
		}
		if (comment == FALSE) @<Deal with material which isn't commentary@>;
	} while (cr != EOF);
	DISCARD_TEXT(command)
	DISCARD_TEXT(argument)


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
it's a heading, that is, an Inweb syntax. We recognise both |@h| and |@p| as
heading markers, in order to accommodate both old and new Inweb syntaxes.

@d INWEB_PARAGRAPH_SYNTAX 1
@d INWEB_CODE_SYNTAX 2
@d INWEB_DASH_SYNTAX 3
@d INWEB_PURPOSE_SYNTAX 4
@d INWEB_FIGURE_SYNTAX 5
@d INWEB_EQUALS_SYNTAX 6
@d INWEB_EXTRACT_SYNTAX 7

@<Read the rest of line as an at-heading@> =
	TEMPORARY_TEXT(I6T_buffer)
	int i = 0, committed = FALSE, unacceptable_character = FALSE;
	while (i<MAX_I6T_LINE_LENGTH) {
		@<Read next character from I6T stream@>;
		if ((committed == FALSE) && ((cr == 10) || (cr == 13) || (cr == ' '))) {
			if (Str::eq_wide_string(I6T_buffer, L"p"))
				inweb_syntax = INWEB_PARAGRAPH_SYNTAX;
			else if (Str::eq_wide_string(I6T_buffer, L"h"))
				inweb_syntax = INWEB_PARAGRAPH_SYNTAX;
			else if (Str::eq_wide_string(I6T_buffer, L"c"))
				inweb_syntax = INWEB_CODE_SYNTAX;
			else if (Str::get_first_char(I6T_buffer) == '-')
				inweb_syntax = INWEB_DASH_SYNTAX;
			else if (Str::begins_with_wide_string(I6T_buffer, L"Purpose:"))
				inweb_syntax = INWEB_PURPOSE_SYNTAX;
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
					StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(...),
						"An unknown '@...' marker has been found at column 0 in "
						"raw Inform 6 template material: specifically, '@%1'. ('@' "
						"has a special meaning in this first column, and this "
						"might clash with its use to introduce an assembly-language "
						"opcode in Inform 6: if that's a problem, you can avoid it "
						"simply by putting one or more spaces or tabs in front of "
						"the opcode(s) to keep them clear of the left margin.)");
					#endif
					#ifndef PROBLEMS_MODULE
					PipelineErrors::kit_error(
						"unknown '@...' marker at column 0 in template matter: '%S'", I6T_buffer);
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
	DISCARD_TEXT(I6T_buffer)

@<Read the rest of line as an equals-heading@> =
	TEMPORARY_TEXT(I6T_buffer)
	int i = 0;
	while (i<MAX_I6T_LINE_LENGTH) {
		@<Read next character from I6T stream@>;
		if ((cr == 10) || (cr == 13)) break;
		PUT_TO(I6T_buffer, cr);
	}
	DISCARD_TEXT(I6T_buffer)
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, I6T_buffer, L" %(text%c*%) *")) {
		inweb_syntax = INWEB_EXTRACT_SYNTAX;
	} else if (Regexp::match(&mr, I6T_buffer, L" %(figure%c*%) *")) {
		inweb_syntax = INWEB_FIGURE_SYNTAX;
	} else if (Regexp::match(&mr, I6T_buffer, L" %(%c*%) *")) {
		#ifdef PROBLEMS_MODULE
		StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(...),
			"An '= (...)' marker has been found at column 0 in "
			"raw Inform 6 template material, of a kind not allowed.");
		#endif
		#ifndef PROBLEMS_MODULE
		PipelineErrors::kit_error(
			"unsupported '= (...)' marker at column 0 in template matter", NULL);
		#endif
	} else {
		inweb_syntax = INWEB_EQUALS_SYNTAX;
	}
	Regexp::dispose_of(&mr);

@ As can be seen, only a small minority of Inweb syntaxes are allowed:
in particular, no definitions| or angle-bracketed macros. This reader is not
a full-fledged tangler.

@<Act on the heading, going in or out of comment mode as appropriate@> =
	switch (inweb_syntax) {
		case INWEB_PARAGRAPH_SYNTAX: {
			if ((Str::len(heading_name) > 0) && (Str::len(segment_name) > 0))
				TemplateReader::I6T_file_intervene(OUT,
					AFTER_LINK_STAGE, segment_name, heading_name, kit);
			Str::copy_tail(heading_name, command, 2);
			int c;
			while (((c = Str::get_last_char(heading_name)) != 0) &&
				((c == ' ') || (c == '\t') || (c == '.')))
				Str::delete_last_character(heading_name);
			if (Str::len(heading_name) == 0)
				PipelineErrors::kit_error("Empty heading name in I6 template file", NULL);
			extract = FALSE; 
			comment = TRUE; skip_part = FALSE;
			if (Str::len(segment_name) > 0) {
				TemplateReader::I6T_file_intervene(OUT,
					BEFORE_LINK_STAGE, segment_name, heading_name, kit);
				if (TemplateReader::I6T_file_intervene(OUT,
					INSTEAD_LINK_STAGE, segment_name, heading_name, kit)) skip_part = TRUE;
			}
			break;
		}
		case INWEB_CODE_SYNTAX:
			extract = FALSE; 
			if (skip_part == FALSE) comment = FALSE;
			break;
		case INWEB_EQUALS_SYNTAX:
			if (extract) {
				comment = TRUE; extract = FALSE;
			} else {
				if (skip_part == FALSE) comment = FALSE;
			}
			break;
		case INWEB_EXTRACT_SYNTAX:
			comment = TRUE; extract = TRUE;
			break;
		case INWEB_DASH_SYNTAX: break;
		case INWEB_PURPOSE_SYNTAX: break;
		case INWEB_FIGURE_SYNTAX: break;
	}

@<Deal with material which isn't commentary@> =
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
	TEMPORARY_TEXT(i7_exp)
	while (TRUE) {
		@<Read next character from I6T stream@>;
		if (cr == EOF) break;
		if ((cr == ')') && (Str::get_last_char(i7_exp) == '+')) {
			Str::delete_last_character(i7_exp); break; }
		PUT_TO(i7_exp, cr);
	}
	LOG("SPONG: %S\n", i7_exp);
	DISCARD_TEXT(i7_exp)
		PipelineErrors::kit_error("use of (+ ... +) in the template has been withdrawn: '%S'", i7_exp);

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
		TemplateReader::interpret(OUT, NULL, argument, -1, kit, NULL);
		(*(kit->raw_callback))(OUT, kit);
		Str::clear(OUT);
		continue;
	}

@h Contents section.

=
void TemplateReader::read_contents(text_stream *text, text_file_position *tfp, void *state) {
	contents_section_state *CSS = (contents_section_state *) state;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L"Sections"))
		CSS->active = TRUE;
	if ((Regexp::match(&mr, text, L" (%c+)")) && (CSS->active)) {
		WRITE_TO(mr.exp[0], ".i6t");
		ADD_TO_LINKED_LIST(Str::duplicate(mr.exp[0]), text_stream, CSS->sects);
	}
	Regexp::dispose_of(&mr);
}
