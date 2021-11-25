[ParsingStages::] Parsing Stages.

Two stages which accept raw I6-syntax material in the parse tree, either from
imsertions made using Inform 7's low-level features, or after reading the
source code for a kit.

@h The two stages.
These stages have more in common than they first appear. Both convert I6T-syntax
source code into a series of |SPLAT_IST| nodes in the Inter tree, with one
such node for each different directive in the I6T source.

The T in "I6T" stands for "template", which in the 2010s was a mechanism for
providing I6 code to I7. That's not the arrangement any more, but the syntax
(mostly) lives on, and so does the name I6T. Still, it's really just the same
thing as Inform 6 code in an Inweb-style literate programming notation.

=
void ParsingStages::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"load-kit-source", ParsingStages::run_load_kit_source,
		TEMPLATE_FILE_STAGE_ARG, TRUE);	
	ParsingPipelines::new_stage(I"parse-insertions", ParsingStages::run_parse_insertions,
		NO_STAGE_ARG, FALSE);
}

@ The stage |load-kit-source K| takes the kit |K|, looks for its source code
(text files written in I6T syntax) and reads this in to the current Inter tree,
placing the resulting nodes in a new top-level module.

=
int ParsingStages::run_load_kit_source(pipeline_step *step) {
	inter_tree *I = step->ephemera.repository;
	inter_package *main_package = Site::main_package_if_it_exists(I);
	if (main_package) @<Create a module to hold the Inter read in from this kit@>;
	I6T_kit kit;
	@<Make a suitable I6T kit@>;
	ParsingStages::I6T_reader(&kit, NULL, I"all");
	return TRUE;
}

@ So for example if we are reading the source for WorldModelKit, then the
following creates the package |/main/WorldModelKit|, with package type |_module|.
It's into this module that the resulting |SPLAT_IST| nodes will be put.

@<Create a module to hold the Inter read in from this kit@> =
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(main_package);
	inter_symbol *module_name = PackageTypes::get(I, I"_module");
	inter_package *template_p = NULL;
	Inter::Package::new_package_named(&IBM, step->step_argument, FALSE,
		module_name, 1, NULL, &template_p);
	Site::set_assimilation_package(I, template_p);

@ The stage |parse-insertions| does the same thing, but on a much smaller scale,
and reading raw I6T source code from |LINK_IST| nodes in the Inter tree rather
than from an external file. There will only be a few of these, and with not much
code in them, when the tree has been compiled by Inform: they arise from
features such as
= (text as Inform 7)
Include (-
	[ CuriousFunction;
		print "Curious!";
	];
-).
=
The //inform7// code does not contain a compiler from I6T down to Inter, so
it can only leave us these unparsed fragments as |LINK_IST| nodes. We take
it from there.

=
int ParsingStages::run_parse_insertions(pipeline_step *step) {
	inter_tree *I = step->ephemera.repository;
	I6T_kit kit;
	@<Make a suitable I6T kit@>;
	InterTree::traverse(I, ParsingStages::visit_insertions, &kit, NULL, LINK_IST);
	return TRUE;
}

void ParsingStages::visit_insertions(inter_tree *I, inter_tree_node *P, void *state) {
	text_stream *insertion = Inode::ID_to_text(P, P->W.data[TO_RAW_LINK_IFLD]);
	#ifdef CORE_MODULE
	current_sentence = (parse_node *) Inode::ID_to_ref(P, P->W.data[REF_LINK_IFLD]);
	#endif
	I6T_kit *kit = (I6T_kit *) state;
	ParsingStages::I6T_reader(kit, insertion, NULL);
}

@ So, then, both of those stages rely on (i) making something called an I6T kit,
then (ii) calling //ParsingStages::I6T_reader//.

Here's where we make the kit, which is really just a collection of settings for
the I6T-reader. That comes down to:

(a) the place to put any nodes generated,
(b) what to do with I6 source code, or with commands embedded in it, and
(c) which file-system paths to look inside when reading from files rather
than raw text in memory.

For (c), note that if a kit is in directory |K| then its source files are
in |K/Sections|.

@<Make a suitable I6T kit@> =
	inter_package *assimilation_package = Site::ensure_assimilation_package(I,
		RunningPipelines::get_symbol(step, plain_ptype_RPSYM));
	inter_bookmark assimilation_point =
		Inter::Bookmarks::at_end_of_this_package(assimilation_package);
	linked_list *L = NEW_LINKED_LIST(pathname);
	pathname *P;
	LOOP_OVER_LINKED_LIST(P, pathname, step->ephemera.the_PP)
		ADD_TO_LINKED_LIST(Pathnames::down(P, I"Sections"), pathname, L);
	kit = ParsingStages::kit_out(&assimilation_point,
		&(ParsingStages::receive_raw), &(ParsingStages::receive_command), L, NULL);

@ Once the I6T reader has unpacked the literate-programming notation, it will
reduce the I6T code to pure Inform 6 source together with (perhaps) a handful of
commands in braces. Our kit must say what to do with each of these outputs.

The easy part: what to do when we find a command in I6T source. In pre-Inter
versions of Inform, when I6T was just a way of expressing Inform 6 code but
with some braced commands mixed in, there were lots of legal if enigmatic
syntaxes in use. Now those have all gone, so in all cases we issue an error:

=
void ParsingStages::receive_command(OUTPUT_STREAM, text_stream *command,
	text_stream *argument, I6T_kit *kit) {
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
		PipelineErrors::kit_error(
			"the template command '{-%S}' has been withdrawn in this version of Inform",
			command);
	} else {
		LOG("command: <%S> argument: <%S>\n", command, argument);
		PipelineErrors::kit_error("no such {-command} as '%S'", command);
	}
}

@ We very much do not ignore the raw I6 code read in, though. When the reader
gives us a chunk of this, we parse through it with a simple finite-state machine.
This can be summarised as "divide the code up at |;| boundaries, sending each
piece in turn to //ParsingStages::splat//". But of course we do not want to
react to semicolons in quoted text or comments, and in fact we also do not
want to react to semicolons used as statement dividers inside I6 routines (i.e.,
functions). So for example
= (text as Inform 6)
Global aspic = "this; and that";
! Don't react to this; I'm only a comment
[ Hello; print "Hello; goodbye.^"; ];
=
would be divided into just two splats,
= (text as Inform 6)
Global aspic = "this; and that";
=
and
= (text as Inform 6)
[ Hello; print "Hello; goodbye.^"; ];
=
(And the comment would be stripped out entirely.)

@d IGNORE_WS_I6TBIT 1
@d DQUOTED_I6TBIT 2
@d SQUOTED_I6TBIT 4
@d COMMENTED_I6TBIT 8
@d ROUTINED_I6TBIT 16
@d CONTENT_ON_LINE_I6TBIT 32

@d SUBORDINATE_I6TBITS
	(COMMENTED_I6TBIT + SQUOTED_I6TBIT + DQUOTED_I6TBIT + ROUTINED_I6TBIT)

=
void ParsingStages::receive_raw(text_stream *S, I6T_kit *kit) {
	text_stream *R = Str::new();
	int mode = IGNORE_WS_I6TBIT;
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == 10) || (c == 13)) c = '\n';
		if (mode & IGNORE_WS_I6TBIT) {
			if ((c == '\n') || (Characters::is_whitespace(c))) continue;
			mode -= IGNORE_WS_I6TBIT;
		}
		if ((c == '!') && (!(mode & (DQUOTED_I6TBIT + SQUOTED_I6TBIT)))) {
			mode = mode | COMMENTED_I6TBIT;
		}
		if (mode & COMMENTED_I6TBIT) {
			if (c == '\n') {
				mode -= COMMENTED_I6TBIT;
				if (!(mode & CONTENT_ON_LINE_I6TBIT)) continue;
			}
			else continue;
		}
		if ((c == '[') && (!(mode & SUBORDINATE_I6TBITS))) {
			mode = mode | ROUTINED_I6TBIT;
		}
		if (mode & ROUTINED_I6TBIT) {
			if ((c == ']') && (!(mode & (DQUOTED_I6TBIT + SQUOTED_I6TBIT + COMMENTED_I6TBIT))))
				mode -= ROUTINED_I6TBIT;
		}
		if ((c == '\'') && (!(mode & (DQUOTED_I6TBIT + COMMENTED_I6TBIT)))) {
			if (mode & SQUOTED_I6TBIT) mode -= SQUOTED_I6TBIT;
			else mode = mode | SQUOTED_I6TBIT;
		}
		if ((c == '\"') && (!(mode & (SQUOTED_I6TBIT + COMMENTED_I6TBIT)))) {
			if (mode & DQUOTED_I6TBIT) mode -= DQUOTED_I6TBIT;
			else mode = mode | DQUOTED_I6TBIT;
		}
		if (c != '\n') {
			if (Characters::is_whitespace(c) == FALSE)
				mode = mode | CONTENT_ON_LINE_I6TBIT;
		} else {
			if (mode & CONTENT_ON_LINE_I6TBIT) mode = mode - CONTENT_ON_LINE_I6TBIT;
			else if (!(mode & SUBORDINATE_I6TBITS)) continue;
		}
		PUT_TO(R, c);
		if ((c == ';') && (!(mode & SUBORDINATE_I6TBITS))) {
			ParsingStages::splat(R, kit);
			mode = IGNORE_WS_I6TBIT;
		}
	}
	ParsingStages::splat(R, kit);
	Str::clear(S);
}

@ Each of those "splats" becomes a |SPLAT_IST| node in the tree at the
current insertion point recorded in the kit.

Note that this function empties the splat buffer |R| before exiting.

=
void ParsingStages::splat(text_stream *R, I6T_kit *kit) {
	if (Str::len(R) > 0) {
		PUT_TO(R, '\n');
		inter_ti SID = Inter::Warehouse::create_text(
			Inter::Bookmarks::warehouse(kit->IBM), Inter::Bookmarks::package(kit->IBM));
		text_stream *textual_storage =
			Inter::Warehouse::get_text(Inter::Bookmarks::warehouse(kit->IBM), SID);
		Str::copy(textual_storage, R);
		Produce::guard(Inter::Splat::new(kit->IBM, SID, 0,
			(inter_ti) (Inter::Bookmarks::baseline(kit->IBM) + 1), 0, NULL));
		Str::clear(R);
	}
}

@ And that's it: the result of these stages is just to break the I6T source they
found up into individual directives, and put them into the tree as |SPLAT_IST| nodes.
No effort has been made yet to see what directives they are. Subsequent stages
will handle that.

@h The I6T Reader.
The rest of this section, then, is a general-purpose reader of I6T-syntax code.
Although it is only used for one purpose in the Inform code base, it once had
multiple uses, and so it's written quite flexibly. There seems no reason to
get rid of that flexibility: perhaps we'll use it again some day.

So, then, this is the parcel of settings for controlling the I6T reader:

=
typedef struct I6T_kit {
	struct inter_bookmark *IBM;
	void (*raw_callback)(struct text_stream *, struct I6T_kit *);
	void (*command_callback)(struct text_stream *, struct text_stream *,
		struct text_stream *, struct I6T_kit *);
	void *I6T_state;
	struct linked_list *search_paths; /* of |pathname| */
} I6T_kit;

@ We actually don't use this facility, but a kit contains a |state| which is
shared across the calls to the callback functions. When a kit is created, the
initial state must be supplied; after that, it's updated only by the callback
functions supplied.

=
I6T_kit ParsingStages::kit_out(inter_bookmark *IBM,
	void (*A)(struct text_stream *, struct I6T_kit *),
	void (*B)(struct text_stream *, struct text_stream *,
		struct text_stream *, struct I6T_kit *),
	linked_list *search_list, void *initial_state) {
	I6T_kit kit;
	kit.IBM = IBM;
	kit.raw_callback = A;
	kit.command_callback = B;
	kit.I6T_state = initial_state;
	kit.search_paths = search_list;
	return kit;
}

@ I6T files use a literate programming notation which is, in effect, a much
simplified version of Inweb's. (Note that Inweb can therefore read kits as
if they were webs, and we use that to weave them for the source website.)

Many Inweb syntaxes are, however, not allowed in I6T: really, you should use
only |@h| headings and the |=| sign to divide commentary from text. Macros and
definitions, in particular, are not permitted; I6T is not really tangled as such.

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

void ParsingStages::I6T_reader(I6T_kit *kit, text_stream *insertion, text_stream *segment) {
	TEMPORARY_TEXT(T)
	ParsingStages::interpret(T, insertion, segment, -1, kit, NULL);
	(*(kit->raw_callback))(T, kit);
	DISCARD_TEXT(T)
}

void ParsingStages::interpret(OUTPUT_STREAM, text_stream *sf,
	text_stream *segment_name, int N_escape, I6T_kit *kit, filename *Input_Filename) {
	if (Str::eq(segment_name, I"all")) {
		pathname *K;
		LOOP_OVER_LINKED_LIST(K, pathname, kit->search_paths) {
			pathname *P = Pathnames::up(K);
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
	pathname *P;
	LOOP_OVER_LINKED_LIST(P, pathname, kit->search_paths)
		if (Input_File == NULL)
			Input_File = Filenames::fopen(
				Filenames::in(P, segment_name), "r");
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
