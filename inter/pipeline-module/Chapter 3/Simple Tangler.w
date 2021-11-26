[SimpleTangler::] Simple Tangler.

Unravelling (a simple version of) Inweb's literate programming notation to
access the tangled content.

@h The I6T Reader.
The rest of this section, then, is a general-purpose reader of I6T-syntax code.
Although it is only used for one purpose in the Inform code base, it once had
multiple uses, and so it's written quite flexibly. There seems no reason to
get rid of that flexibility: perhaps we'll use it again some day.

So, then, this is the parcel of settings for controlling the I6T reader. The
|state| here is not used by the reader itself, but instead allows the callback
functions to have a shared state of their own.

=
typedef struct simple_tangle_docket {
	void (*raw_callback)(struct text_stream *, struct simple_tangle_docket *);
	void (*command_callback)(struct text_stream *, struct text_stream *,
		struct text_stream *, struct simple_tangle_docket *);
	void (*error_callback)(char *, struct text_stream *);
	void *state;
	struct linked_list *search_paths; /* of |pathname| */
} simple_tangle_docket;

@ =
simple_tangle_docket SimpleTangler::new_docket(
	void (*A)(struct text_stream *, struct simple_tangle_docket *),
	void (*B)(struct text_stream *, struct text_stream *,
		struct text_stream *, struct simple_tangle_docket *),
	void (*C)(char *, struct text_stream *),
	linked_list *search_list, void *initial_state) {
	simple_tangle_docket docket;
	docket.raw_callback = A;
	docket.command_callback = B;
	docket.error_callback = C;
	docket.state = initial_state;
	docket.search_paths = search_list;
	return docket;
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
void SimpleTangler::tangle(simple_tangle_docket *docket, text_stream *insertion, text_stream *segment) {
	TEMPORARY_TEXT(T)
	SimpleTangler::tangle_L2(T, insertion, segment, -1, docket, NULL);
	(*(docket->raw_callback))(T, docket);
	DISCARD_TEXT(T)
}

void SimpleTangler::tangle_L2(OUTPUT_STREAM, text_stream *sf,
	text_stream *segment_name, int N_escape, simple_tangle_docket *docket, filename *Input_Filename) {
	if (Str::eq(segment_name, I"all")) {
		pathname *K;
		LOOP_OVER_LINKED_LIST(K, pathname, docket->search_paths) {
			pathname *P = Pathnames::up(K);
			web_md *Wm = WebMetadata::get(P, NULL, V2_SYNTAX, NULL, FALSE, TRUE, NULL);
			chapter_md *Cm;
			LOOP_OVER_LINKED_LIST(Cm, chapter_md, Wm->chapters_md) {
				section_md *Sm;
				LOOP_OVER_LINKED_LIST(Sm, section_md, Cm->sections_md) {
					filename *SF = Sm->source_file_for_section;
					SimpleTangler::tangle_L3(OUT, sf, Sm->sect_title, N_escape, docket, SF);
				}
			}
		}
		return;
	}
	SimpleTangler::tangle_L3(OUT, sf, segment_name, N_escape, docket, Input_Filename);
}

void SimpleTangler::tangle_L3(OUTPUT_STREAM, text_stream *sf,
	text_stream *segment_name, int N_escape, simple_tangle_docket *docket, filename *Input_Filename) {
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
part of the I6T docket.

@<Open the I6 template file@> =
	if (Input_Filename)
		Input_File = Filenames::fopen(Input_Filename, "r");
	pathname *P;
	LOOP_OVER_LINKED_LIST(P, pathname, docket->search_paths)
		if (Input_File == NULL)
			Input_File = Filenames::fopen(
				Filenames::in(P, segment_name), "r");
	if (Input_File == NULL)
		(*(docket->error_callback))("unable to open the template segment '%S'", segment_name);

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
					(*(docket->error_callback))(
						"unknown '@...' marker at column 0 in template matter: '%S'", I6T_buffer);
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
		(*(docket->error_callback))(
			"unsupported '= (...)' marker at column 0 in template matter", NULL);
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
				(*(docket->error_callback))("Empty heading name in I6 template file", NULL);
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
			(*(docket->command_callback))(OUT, command, argument, docket);
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
	DISCARD_TEXT(i7_exp)
		(*(docket->error_callback))(
			"use of (+ ... +) in the template has been withdrawn: '%S'", i7_exp);
