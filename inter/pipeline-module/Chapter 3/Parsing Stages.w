[ParsingStages::] Parsing Stages.

Two stages which accept raw I6-syntax material in the parse tree, either from
imsertions made using Inform 7's low-level features, or after reading the
source code for a kit.

@h The two stages.

=
void ParsingStages::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"load-kit-source", ParsingStages::run_load_kit_source,
		TEMPLATE_FILE_STAGE_ARG, TRUE);	
	ParsingPipelines::new_stage(I"parse-insertions", ParsingStages::run_parse_insertions,
		NO_STAGE_ARG, FALSE);
}

@ The stage |load-kit-source K| takes the kit |K|, looks for its source code
(which will be Inform 6-syntax source code written in a literate programming
notation) and reads this in to the current Inter tree, as a new top-level
module.

=
int ParsingStages::run_load_kit_source(pipeline_step *step) {
	inter_tree *I = step->ephemera.repository;
	inter_package *main_package = Site::main_package_if_it_exists(I);
	if (main_package) @<Create a module to hold the Inter read in from this kit@>;
	I6T_kit kit;
	@<Make a suitable I6T kit@>;
	ParsingStages::capture(&kit, NULL, I"all");
	return TRUE;
}

@ So for example if we are reading the source for WorldModelKit, then the
following creates the package |/main/WorldModelKit|, with package type |_module|.
It's into this module that all the code will be read.

@<Create a module to hold the Inter read in from this kit@> =
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(main_package);
	inter_symbol *module_name = PackageTypes::get(I, I"_module");
	inter_package *template_p = NULL;
	Inter::Package::new_package_named(&IBM, step->step_argument, FALSE,
		module_name, 1, NULL, &template_p);
	Site::set_assimilation_package(I, template_p);

@ =
int ParsingStages::run_parse_insertions(pipeline_step *step) {
	inter_tree *I = step->ephemera.repository;
	I6T_kit kit;
	@<Make a suitable I6T kit@>;
	InterTree::traverse(I, ParsingStages::catch_all_visitor, &kit, NULL, 0);
	return TRUE;
}

void ParsingStages::catch_all_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == LINK_IST) {
		text_stream *insertion = Inode::ID_to_text(P, P->W.data[TO_RAW_LINK_IFLD]);
		#ifdef CORE_MODULE
		current_sentence = (parse_node *) Inode::ID_to_ref(P, P->W.data[REF_LINK_IFLD]);
		#endif
		I6T_kit *kit = (I6T_kit *) state;
		ParsingStages::capture(kit, insertion, NULL);
	}
}

@<Make a suitable I6T kit@> =
	linked_list *PP = step->ephemera.the_PP;
	inter_package *template_package = Site::ensure_assimilation_package(I, RunningPipelines::get_symbol(step, plain_ptype_RPSYM));	
	
	inter_bookmark link_bookmark =
		Inter::Bookmarks::at_end_of_this_package(template_package);

	kit = ParsingStages::kit_out(&link_bookmark, &(ParsingStages::receive_raw),  &(ParsingStages::receive_command), NULL);
	kit.no_i6t_file_areas = LinkedLists::len(PP);
	pathname *P;
	int i=0;
	LOOP_OVER_LINKED_LIST(P, pathname, PP)
		kit.i6t_files[i++] = Pathnames::down(P, I"Sections");

@

@d IGNORE_WS_FILTER_BIT 1
@d DQUOTED_FILTER_BIT 2
@d SQUOTED_FILTER_BIT 4
@d COMMENTED_FILTER_BIT 8
@d ROUTINED_FILTER_BIT 16
@d CONTENT_ON_LINE_FILTER_BIT 32

@d SUBORDINATE_FILTER_BITS (COMMENTED_FILTER_BIT + SQUOTED_FILTER_BIT + DQUOTED_FILTER_BIT + ROUTINED_FILTER_BIT)

=
void ParsingStages::receive_raw(text_stream *S, I6T_kit *kit) {
	text_stream *R = Str::new();
	int mode = IGNORE_WS_FILTER_BIT;
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == 10) || (c == 13)) c = '\n';
		if (mode & IGNORE_WS_FILTER_BIT) {
			if ((c == '\n') || (Characters::is_whitespace(c))) continue;
			mode -= IGNORE_WS_FILTER_BIT;
		}
		if ((c == '!') && (!(mode & (DQUOTED_FILTER_BIT + SQUOTED_FILTER_BIT)))) {
			mode = mode | COMMENTED_FILTER_BIT;
		}
		if (mode & COMMENTED_FILTER_BIT) {
			if (c == '\n') {
				mode -= COMMENTED_FILTER_BIT;
				if (!(mode & CONTENT_ON_LINE_FILTER_BIT)) continue;
			}
			else continue;
		}
		if ((c == '[') && (!(mode & SUBORDINATE_FILTER_BITS))) {
			mode = mode | ROUTINED_FILTER_BIT;
		}
		if (mode & ROUTINED_FILTER_BIT) {
			if ((c == ']') && (!(mode & (DQUOTED_FILTER_BIT + SQUOTED_FILTER_BIT + COMMENTED_FILTER_BIT)))) mode -= ROUTINED_FILTER_BIT;
		}
		if ((c == '\'') && (!(mode & (DQUOTED_FILTER_BIT + COMMENTED_FILTER_BIT)))) {
			if (mode & SQUOTED_FILTER_BIT) mode -= SQUOTED_FILTER_BIT;
			else mode = mode | SQUOTED_FILTER_BIT;
		}
		if ((c == '\"') && (!(mode & (SQUOTED_FILTER_BIT + COMMENTED_FILTER_BIT)))) {
			if (mode & DQUOTED_FILTER_BIT) mode -= DQUOTED_FILTER_BIT;
			else mode = mode | DQUOTED_FILTER_BIT;
		}
		if (c != '\n') {
			if (Characters::is_whitespace(c) == FALSE) mode = mode | CONTENT_ON_LINE_FILTER_BIT;
		} else {
			if (mode & CONTENT_ON_LINE_FILTER_BIT) mode = mode - CONTENT_ON_LINE_FILTER_BIT;
			else if (!(mode & SUBORDINATE_FILTER_BITS)) continue;
		}
		PUT_TO(R, c);
		if ((c == ';') && (!(mode & SUBORDINATE_FILTER_BITS))) {
			ParsingStages::chunked_raw(R, kit);
			mode = IGNORE_WS_FILTER_BIT;
		}
	}
	ParsingStages::chunked_raw(R, kit);
	Str::clear(S);
}

void ParsingStages::chunked_raw(text_stream *S, I6T_kit *kit) {
	if (Str::len(S) == 0) return;
	PUT_TO(S, '\n');
	ParsingStages::entire_splat(kit->IBM, I"template", S, (inter_ti) (Inter::Bookmarks::baseline(kit->IBM) + 1));
	Str::clear(S);
}

void ParsingStages::entire_splat(inter_bookmark *IBM, text_stream *origin, text_stream *content, inter_ti level) {
	inter_ti SID = Inter::Warehouse::create_text(Inter::Bookmarks::warehouse(IBM), Inter::Bookmarks::package(IBM));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Bookmarks::warehouse(IBM), SID);
	Str::copy(glob_storage, content);
	Produce::guard(Inter::Splat::new(IBM, SID, 0, level, 0, NULL));
}

void ParsingStages::receive_command(OUTPUT_STREAM, text_stream *command, text_stream *argument, I6T_kit *kit) {
	if ((Str::eq_wide_string(command, L"plugin")) ||
		(Str::eq_wide_string(command, L"type")) ||
		(Str::eq_wide_string(command, L"open-file")) ||
		(Str::eq_wide_string(command, L"close-file")) ||
		(Str::eq_wide_string(command, L"lines")) ||
		(Str::eq_wide_string(command, L"endlines")) ||
		(Str::eq_wide_string(command, L"open-index")) ||
		(Str::eq_wide_string(command, L"close-index")) ||
		(Str::eq_wide_string(command, L"index-page")) ||
		(Str::eq_wide_string(command, L"index-element")) ||
		(Str::eq_wide_string(command, L"index")) ||
		(Str::eq_wide_string(command, L"log")) ||
		(Str::eq_wide_string(command, L"log-phase")) ||
		(Str::eq_wide_string(command, L"progress-stage")) ||
		(Str::eq_wide_string(command, L"counter")) ||
		(Str::eq_wide_string(command, L"value")) ||
		(Str::eq_wide_string(command, L"read-assertions")) ||
		(Str::eq_wide_string(command, L"callv")) ||
		(Str::eq_wide_string(command, L"call")) ||
		(Str::eq_wide_string(command, L"array")) ||
		(Str::eq_wide_string(command, L"marker")) ||
		(Str::eq_wide_string(command, L"testing-routine")) ||
		(Str::eq_wide_string(command, L"testing-command"))) {
		LOG("command: <%S> argument: <%S>\n", command, argument);
		PipelineErrors::kit_error("the template command '{-%S}' has been withdrawn in this version of Inform", command);
	} else {
		LOG("command: <%S> argument: <%S>\n", command, argument);
		PipelineErrors::kit_error("no such {-command} as '%S'", command);
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
I6T_kit ParsingStages::kit_out(inter_bookmark *IBM, void (*A)(struct text_stream *, struct I6T_kit *),
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
typedef struct contents_section_state {
	struct linked_list *sects; /* of |text_stream| */
	int active;
} contents_section_state;

void ParsingStages::capture(I6T_kit *kit, text_stream *insertion, text_stream *segment) {
	TEMPORARY_TEXT(T)
	ParsingStages::interpret(T, insertion, segment, -1, kit, NULL);
	(*(kit->raw_callback))(T, kit);
	DISCARD_TEXT(T)
}

void ParsingStages::interpret(OUTPUT_STREAM, text_stream *sf,
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
					ParsingStages::interpret(OUT, sf, Sm->sect_title, N_escape, kit, SF);
				}
			}
		}
		return;
	}
	TEMPORARY_TEXT(heading_name)
	int skip_part = FALSE, comment = TRUE, extract = FALSE;
	int col = 1, cr, sfp = 0;

	FILE *Input_File = NULL;
	if ((Str::len(segment_name) > 0) || (Input_Filename)) {
		@<Open the I6 template file@>;
		comment = TRUE;
	} else comment = FALSE;

	@<Interpret the I6T file@>;

	if (Input_File) { if (DL) STREAM_FLUSH(DL); fclose(Input_File); }

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
			Str::copy_tail(heading_name, command, 2);
			int c;
			while (((c = Str::get_last_char(heading_name)) != 0) &&
				((c == ' ') || (c == '\t') || (c == '.')))
				Str::delete_last_character(heading_name);
			if (Str::len(heading_name) == 0)
				PipelineErrors::kit_error("Empty heading name in I6 template file", NULL);
			extract = FALSE; 
			comment = TRUE; skip_part = FALSE;
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
internal_error("neurotica!");
		(*(kit->raw_callback))(OUT, kit);
		Str::clear(OUT);
		ParsingStages::interpret(OUT, NULL, argument, -1, kit, NULL);
		(*(kit->raw_callback))(OUT, kit);
		Str::clear(OUT);
		continue;
	}

@h Contents section.

=
void ParsingStages::read_contents(text_stream *text, text_file_position *tfp, void *state) {
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
