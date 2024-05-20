[BibliographicData::] Bibliographic Data.

To manage the special variables providing bibliographic data on the
work of IF being generated (title, author's name and so forth), and to write
the Library Card in the index.

@h Enter the feature.
This chapter defines the "bibliographic data" feature, whose activation
function follows.

Much of this chapter is best understood by reference to the Treaty of
Babel, a cross-IF-system standard for bibliographic data and packaging
agreed between the major IF design systems in 2006. Inform aims to comply
fully with the Treaty and the code below should be maintained as such.

=
void BibliographicData::start(void) {
	PluginCalls::plug(PRODUCTION_LINE_PLUG,
		BibliographicData::production_line);
	PluginCalls::plug(MAKE_SPECIAL_MEANINGS_PLUG,
		BibliographicData::make_special_meanings);
	PluginCalls::plug(NEW_VARIABLE_NOTIFY_PLUG,
		BibliographicData::bibliographic_new_variable_notify);
}

int BibliographicData::production_line(int stage, int debugging,
	stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(RTBibliographicData::compile_constants);
	}
	if (stage == BIBLIOGRAPHIC_CSEQ) {
		BENCH(ReleaseInstructions::write_ifiction_and_blurb);
	}
	return FALSE;
}

@ This enables two special sentence shapes: one which really should never
have been included in Inform, to do with episode numbers, and another which
is essential, allowing authors to specify how releases are made.

=
int BibliographicData::make_special_meanings(void) {
	SpecialMeanings::declare(BibliographicData::episode_SMF,
		I"episode", 2);
	SpecialMeanings::declare(ReleaseInstructions::release_along_with_SMF,
		I"release-along-with", 4);
	return FALSE;
}

@h Episode sentences.
Episode sentences do nothing other than to fill in two pieces of rarely-used
bibliographic data (which could just as easily be variables). But two of the
larger worked examples we were trying Inform out on, in the early days,
belonged to a sequence called "When in Rome". So it didn't seem such an
obscure request at the time.

>> This is episode 2 of "When in Rome".

This handles the special meaning "The story is episode...".

=
int episode_number = -1; /* for a work which is part of a numbered series */
inchar32_t *series_name = NULL;

int BibliographicData::episode_number(void) {
	return episode_number;
}

inchar32_t *BibliographicData::series_name(void) {
	return series_name;
}

int BibliographicData::episode_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The story is episode 2 of ..." */
		case ACCEPT_SMFT:
			if ((<episode-sentence-subject>(SW)) && (<episode-sentence-object>(OW))) {
				if (<<r>> >= 0) {
					episode_number = <<r>>;
					Word::dequote(<<series>>);
					series_name = Lexer::word_text(<<series>>);
				}
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ The subject noun phrase is fixed, so the information is in the object NP,
which must match:

=
<episode-sentence-subject> ::=
	<definite-article> story |
	this story |
	story

<episode-sentence-object> ::=
	episode <cardinal-number> of <quoted-text-without-subs> |  ==> { R[1], -, <<series>> = R[2] }
	episode ...                                                ==> @<Issue PM_BadEpisode problem@>;

@<Issue PM_BadEpisode problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadEpisode),
		"this is not the right way to specify how the story "
		"fits into a larger narrative",
		"and should take the form 'The story is episode 2 of "
		"\"Belt of Orion\", where the episode number has to be a "
		"whole number 0, 1, 2, ... and the series name has to be "
		"plain text without [substitutions].");
	==> { -1, - };

@h Bibliographic variables.
Most of the bibliographic data on a story is kept in global variables, however,
which are used to build the iFiction record and the releasing blurb at the end
of a successful compilation. They are:

= (early code)
nonlocal_variable *story_title_VAR = NULL;
nonlocal_variable *story_author_VAR = NULL;
nonlocal_variable *story_headline_VAR = NULL;
nonlocal_variable *story_genre_VAR = NULL;
nonlocal_variable *story_description_VAR = NULL;
nonlocal_variable *story_creation_year_VAR = NULL;
nonlocal_variable *story_release_number_VAR = NULL;
nonlocal_variable *story_licence_VAR = NULL;
nonlocal_variable *story_copyright_VAR = NULL;
nonlocal_variable *story_origin_URL_VAR = NULL;
nonlocal_variable *story_rights_history_VAR = NULL;

@ As usual, Inform uses these English wordings to detect the creation of the
variables in the Standard Rules, which are in English: so there's no point
in translating this nonterminal to other languages.

@d STORY_TITLE_BIBV 0
@d STORY_AUTHOR_BIBV 1
@d STORY_HEADLINE_BIBV 2
@d STORY_GENRE_BIBV 3
@d STORY_DESCRIPTION_BIBV 4
@d STORY_CREATION_YEAR_BIBV 5
@d RELEASE_NUMBER_BIBV 6
@d STORY_LICENCE_BIBV 7
@d STORY_COPYRIGHT_BIBV 8
@d STORY_ORIGIN_URL_BIBV 9
@d STORY_RIGHTS_HISTORY_BIBV 10

=
<notable-bibliographic-variables> ::=
	story title |
	story author |
	story headline |
	story genre |
	story description |
	story creation year |
	release number |
	story licence |
	story copyright |
	story origin url |
	story rights history

@ And we read them here:

=
int BibliographicData::bibliographic_new_variable_notify(nonlocal_variable *q) {
	if (<notable-bibliographic-variables>(q->name)) {
		switch (<<r>>) {
			case STORY_TITLE_BIBV: story_title_VAR = q; break;
			case STORY_AUTHOR_BIBV: story_author_VAR = q; break;
			case STORY_HEADLINE_BIBV: story_headline_VAR = q; break;
			case STORY_GENRE_BIBV: story_genre_VAR = q; break;
			case STORY_DESCRIPTION_BIBV: story_description_VAR = q; break;
			case STORY_CREATION_YEAR_BIBV: story_creation_year_VAR = q; break;
			case RELEASE_NUMBER_BIBV:
				story_release_number_VAR = q;
				semantic_version_number V = Projects::get_version(Task::project());
				if (VersionNumbers::is_null(V) == FALSE) {
					if (P_variable_initial_value == NULL) internal_error("too soon");
					int M = V.version_numbers[0];
					parse_node *save = current_sentence;
					current_sentence = NULL;
					PropertyInferences::draw_from_metadata(
						NonlocalVariables::to_subject(q), P_variable_initial_value,
							Rvalues::from_int(M, EMPTY_WORDING));
					current_sentence = save;
				}
				break;
			case STORY_LICENCE_BIBV: story_licence_VAR = q; break;
			case STORY_COPYRIGHT_BIBV: story_copyright_VAR = q; break;
			case STORY_ORIGIN_URL_BIBV: story_origin_URL_VAR = q; break;
			case STORY_RIGHTS_HISTORY_BIBV: story_rights_history_VAR = q; break;
		}
		NonlocalVariables::make_constant(q, TRUE);
	}
	return FALSE;
}

@h The opening sentence.
The following is called in response to the bibliographic sentence -- the
optional one at the start of a source text which gives its title and author.
This isn't handled by the special meaning machinery above because it really
isn't a conventional sentence at all -- there's no verb. Instead, //assertions//
calls this function directly on pass 2.

Should either title or author be unspecified, we use whatever the //supervisor//
module thought was the title or author.

=
void BibliographicData::bibliographic_data(parse_node *PN) {
	inbuild_edition *edn = Task::edition();
	TEMPORARY_TEXT(T)
	TEMPORARY_TEXT(A)
	WRITE_TO(T, "\"%S\" ", edn->work->title);
	WRITE_TO(A, "\"%S\" ", edn->work->author_name);
	wording TW = Feeds::feed_text(T);
	wording AW = Feeds::feed_text(A);
	DISCARD_TEXT(T)
	DISCARD_TEXT(A)

	if ((story_title_VAR) && (story_author_VAR)) {
		parse_node *the_title;
		if (<s-value>(TW)) the_title = <<rp>>;
		else the_title = Specifications::new_UNKNOWN(TW);
		Assertions::PropertyKnowledge::initialise_global_variable(
			story_title_VAR, the_title);
		TextLiterals::suppress_quote_expansion(Node::get_text(the_title));

		if (Str::len(edn->work->author_name) > 0) {
			parse_node *the_author;
			if (<s-value>(AW)) the_author = <<rp>>;
			else the_author = Specifications::new_UNKNOWN(AW);
			Assertions::PropertyKnowledge::initialise_global_variable(
				story_author_VAR, the_author);
		}
	}
}

@ This unattractive function performs a string comparison of the author's name
against one that's supplied, case sensitively, and is used when deciding
whether to print credits at run-time for extensions written by the same
person as the author of the main work.

=
int BibliographicData::story_author_is(text_stream *p) {
	if ((story_author_VAR) &&
		(VariableSubjects::has_initial_value_set(story_author_VAR))) {
		parse_node *spec = VariableSubjects::get_initial_value(story_author_VAR);
		Node::set_kind_of_value(spec, K_text);
		int result = FALSE;
		TEMPORARY_TEXT(TEMP)
		wording W = Node::get_text(spec);
		int w1 = Wordings::first_wn(W);
		BibliographicData::compile_bibliographic_text(TEMP, Lexer::word_text(w1), HTML_BIBTEXT_MODE);
		if (Str::eq(TEMP, p)) result = TRUE;
		DISCARD_TEXT(TEMP)
		return result;
	}
	return FALSE;
}

@h Licence information.

=
void BibliographicData::fill_licence_variables(void) {
	inform_project *proj = Task::project();
	inbuild_licence *L = proj->as_copy->licence;

	text_stream *val;
	nonlocal_variable *var;

	var = story_licence_VAR;
	if (L->standard_licence) val = L->standard_licence->SPDX_id;
	else val = I"Unspecified";
	@<Set var to val@>;
	
	var = story_copyright_VAR;
	val = Str::new();
	WRITE_TO(val, "%S %d", L->rights_owner, L->copyright_year);
	if (L->revision_year > L->copyright_year) WRITE_TO(val, "-%d", L->revision_year);
	@<Set var to val@>;
	
	var = story_origin_URL_VAR;
	val = L->origin_URL;
	@<Set var to val@>;
	
	var = story_rights_history_VAR;
	val = L->rights_history;
	@<Set var to val@>;
}

@<Set var to val@> =
	if (var) {
		TEMPORARY_TEXT(val_t)
		PUT_TO(val_t, '"');
		LOOP_THROUGH_TEXT(pos, val)
			if (Str::get(pos) == '"')
				PUT_TO(val_t, '\'');
			else
				PUT_TO(val_t, Str::get(pos));
		PUT_TO(val_t, '"');
		wording TW = Feeds::feed_text(val_t);
		parse_node *constant_text = Rvalues::from_unescaped_wording(TW);
		Assertions::PropertyKnowledge::initialise_global_variable(
			var, constant_text);
		DISCARD_TEXT(val_t)
	}

@h The IFID.
The Interactive Fiction ID number for an Inform 7-compiled work is the same
as the UUID unique ID generated by the Inform 7 application.

UUIDs are not generated here, but by the user interface application. We expect
to read them in the form of the |uuid.txt| file placed in the project bundle
by that application. After some agonising, I decided that the Treaty did not
actually oblige me to crash out if this file did not exist: but in such
cases the UUID is empty.

@d MAX_UUID_LENGTH 128 /* the UUID is truncated to this if necessary */

=
text_stream *uuid_text = NULL;
int uuid_read = -1;

text_stream *BibliographicData::read_uuid(void) {
	if (uuid_read >= 0) return uuid_text;
	uuid_text = Str::new();
	uuid_read = 0;
	FILE *xf = Filenames::fopen(Task::uuid_file(), "r");
	if (xf == NULL) return uuid_text; /* the UUID is the empty string if the file is missing */
	int c;
	while (((c = fgetc(xf)) != EOF) /* the UUID file is plain text, not Unicode */
		&& (uuid_read++ < MAX_UUID_LENGTH-1))
		if (Characters::is_Unicode_whitespace((inchar32_t) c) == FALSE)
			PUT_TO(uuid_text, Characters::toupper((inchar32_t) c));
	fclose(xf);
	return uuid_text;
}

@h Bibliographic text.
"Bibliographic text" is text used in bibliographic data about the work
of IF compiled: for instance, in the iFiction record, or in the Library
Card section of the HTML index. Note that the exact output format depends
on global variables, which allow the bibliographic text writing code to
configure Inform for its current purposes. On non-empty strings this routine
therefore splits into one of three independent methods.

@d XML_BIBTEXT_MODE 1
@d TRUNCATE_BIBTEXT_MODE 2
@d I6_BIBTEXT_MODE 3
@d HTML_BIBTEXT_MODE 4

=
void BibliographicData::compile_bibliographic_text(OUTPUT_STREAM, inchar32_t *p, int mode) {
	if (p == NULL) return;
	if (mode == XML_BIBTEXT_MODE)
		@<Compile bibliographic text as XML respecting Treaty of Babel rules@>;
	if (mode == TRUNCATE_BIBTEXT_MODE)
		@<Compile bibliographic text as a truncated filename@>;
	if ((RTBibliographicData::in_bibliographic_mode()) || (mode == I6_BIBTEXT_MODE))
		@<Compile bibliographic text as an I6 string@>
	@<Compile bibliographic text as HTML@>;
}

@ This looks like a standard routine for converting ISO Latin-1 to UTF-8
with XML escapes, but there are a few conventions on whitespace, too, in order
to comply with a strict reading of the Treaty of Babel. (This is intended
for fields in iFiction records.)

@<Compile bibliographic text as XML respecting Treaty of Babel rules@> =
	int i = 0, i2 = Wide::len(p)-1, snl, wsc;
	if ((p[0] == '"') && (p[i2] == '"')) { i++; i2--; } /* omit surrounding double-quotes */
	while (Characters::is_babel_whitespace(p[i])) i++; /* omit leading space */
	while ((i2>=0) && (Characters::is_babel_whitespace(p[i2]))) i2--; /* omit trailing space */
	for (snl = FALSE, wsc = 0; i<=i2; i++) {
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t':
				snl = FALSE;
				wsc++;
				int k = i;
				while ((p[k] == ' ') || (p[k] == '\x0a') ||
					(p[k] == '\x0d') || (p[k] == '\t')) k++;
				if ((wsc == 1) && (p[k] != NEWLINE_IN_STRING)) WRITE(" ");
				break;
			case NEWLINE_IN_STRING:
				if (snl) break;
				WRITE("<br/>");
				snl = TRUE; wsc = 1; break;
			case '[':
				if ((p[i+1] == '\'') && (p[i+2] == ']')) {
					i += 2;
					WRITE("'"); break;
				}
				int n = TranscodeText::expand_unisub(OUT, p, i);
				if (n >= 0) { i = n; break; }
				/* and otherwise fall through to the default case */
			default:
				snl = FALSE;
				wsc = 0;
				switch(p[i]) {
					case '&': WRITE("&amp;"); break;
					case '<': WRITE("&lt;"); break;
					case '>': WRITE("&gt;"); break;
					default: PUT(p[i]); break;
				}
				break;
		}
	}
	return;

@ In the HTML version, we want to respect the forcing of newlines, and
also the |[']| escape to obtain a literal single quotation mark.

@<Compile bibliographic text as HTML@> =
	int i, whitespace_count=0;
	if (p[0] == '"') p++;
	for (i=0; p[i]; i++) {
		if ((p[i] == '"') && (p[i+1] == 0)) break;
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t':
				whitespace_count++;
				if (whitespace_count == 1) PUT(' ');
				break;
			case NEWLINE_IN_STRING:
				while (p[i+1] == NEWLINE_IN_STRING) i++;
				PUT('<');
				PUT('p');
				PUT('>');
				whitespace_count = 1;
				break;
			case '[':
				if ((p[i+1] == '\'') && (p[i+2] == ']')) {
					i += 2;
					PUT('\''); break;
				}
				int n = TranscodeText::expand_unisub(OUT, p, i);
				if (n >= 0) { i = n; break; }
				/* and otherwise fall through to the default case */
			default:
				whitespace_count = 0;
				PUT(p[i]);
				break;
		}
	}
	return;

@ In the Inform 6 string version, we suppress the forcing of newlines, but
otherwise it's much the same.

@<Compile bibliographic text as an I6 string@> =
	int i, whitespace_count=0;
	if (p[0] == '"') p++;
	for (i=0; p[i]; i++) {
		if ((p[i] == '"') && (p[i+1] == 0)) break;
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t': case NEWLINE_IN_STRING:
				whitespace_count++;
				if (whitespace_count == 1) PUT(' ');
				break;
			case '[':
				if ((p[i+1] == '\'') && (p[i+2] == ']')) {
					i += 2;
					PUT('\''); break;
				} /* and otherwise fall through to the default case */
			default:
				whitespace_count = 0;
				PUT(p[i]);
				break;
		}
	}
	return;

@ This code is used to work out a good filename for something given a name
inside Inform. For instance, if a project is called

>> "St. Bartholemew's Fair: Etude for a Push-Me/Pull-You Machine"

then what would be a good filename for its released story file?

In the filename version we must forcibly truncate the text to ensure
that it does not exceed a certain length, and must also make it filename-safe,
omitting characters used as folder separators on various platforms and
(for good measure) removing accents from accented letters, so that we can
arrive at a sequence of ASCII characters. Each run of whitespace is also
converted to a single space. If this would result in an empty text or only
a single space, we return the text "story" instead.

Our example (if not truncated) then emerges as:
= (text)
	St- Bartholemew's Fair- Etude for a Push-Me-Pull-You Machine
=
Note that we do not write any filename extension (e.g., |.z5|) here.

We change possible filename separators or extension indicators to hyphens,
and remove accents from each possible ISO Latin-1 accented letter. This does
still mean that the OE and AE digraphs will simply be omitted, while the
German eszet will be barbarously shortened to a single "s", but life is
just too short to care overmuch about this.

@<Compile bibliographic text as a truncated filename@> =
	int i, pos = STREAM_EXTENT(OUT), whitespace_count=0, black_chars_written = 0;
	int N = BIBLIOGRAPHIC_TEXT_TRUNCATION;
	if (p[0] == '"') p++;
	for (i=0; p[i]; i++) {
		if (STREAM_EXTENT(OUT) - pos >= N) break;
		if ((p[i] == '"') && (p[i+1] == 0)) break;
		switch(p[i]) {
			case ' ': case '\x0a': case '\x0d': case '\t': case NEWLINE_IN_STRING:
				whitespace_count++;
				if (whitespace_count == 1) PUT(' ');
				break;
			case '?': case '*':
				if ((p[i+1]) && (p[i+1] != '\"')) PUT('-');
				break;
			default: {
				inchar32_t charcode = p[i];
				charcode = Characters::make_filename_safe(charcode);
				whitespace_count = 0;
				if (charcode < 128) {
					PUT(charcode); black_chars_written++;
				}
				break;
			}
		}
	}
	if (black_chars_written == 0) WRITE("story");
	return;
