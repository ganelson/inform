[SourceFiles::] Read Source Text.

This is where source text is read in, whether from extension files
or from the main source text file, and fed into the lexer.

@h Definitions.

@ The source text is drawn almost entirely from the primary source file and
the extensions, but Inform does also inject small amounts of source text of
its own (for instance, when a new kind is created, the kind interpreter
does this).

In particular, every source text read into Inform is automatically prefixed by
the following eight words -- if Inform were a computer, this would be the BIOS
which boots up its operating system. (In that the rest of the creation of the
I7 world model is handled by source text in the Standard Rules.)

Because of this mandatory insertion, one extension, the Standard Rules, is
compulsorily included in every run. So there will certainly be at least two
files of source text to be read, and quite possibly more.

@d MANDATORY_INSERTED_TEXT L"Include the Standard Rules by Graham Nelson.\n\n"

=
source_file *primary_source_file = NULL; /* first to be opened */

@ There is no real difference between the loading of the primary source text
and the loading of an extension's text, except for the descriptions we
supply in case of any problem messages which might need to be issued,
and for the fact that the mandatory insertion text is loaded before the
primary source text.

=
int SourceFiles::read_extension_source_text(extension_file *EF,
	text_stream *synopsis, int documentation_only) {
	int rv = SourceFiles::read_file(NULL, synopsis, EF, documentation_only);
	if (Log::aspect_switched_on(LEXICAL_OUTPUT_DA)) Word::log_lexer_output();
	return rv;
}

void SourceFiles::read_primary_source_text(void) {
	Feeds::feed_text(MANDATORY_INSERTED_TEXT);
	SourceFiles::read_further_mandatory_text();
	SourceFiles::read_file(filename_of_i7_source, I"your source text", NULL, FALSE);
}

@ The following reads in the text of the optional file of use options, if
this has been created, producing no problem message if it hasn't.

@d SENTENCE_COUNT_MONITOR SourceFiles::increase_sentence_count

=
wording options_file_wording = EMPTY_WORDING_INIT;
void SourceFiles::read_further_mandatory_text(void) {
	feed_t id = Feeds::begin();
	TextFiles::read(filename_of_options, TRUE,
		NULL, FALSE, SourceFiles::read_further_mandatory_text_helper, NULL, NULL);
	options_file_wording = Feeds::end(id);
}

void SourceFiles::read_further_mandatory_text_helper(text_stream *line,
	text_file_position *tfp, void *unused_state) {
	WRITE_TO(line, "\n");
	wording W = Feeds::feed_stream(line);
	if (<use-option-sentence-shape>(W)) UseOptions::set_immediate_option_flags(W, NULL);
}

int SourceFiles::increase_sentence_count(wording W) {
	if (Wordings::within(W, options_file_wording) == FALSE) return TRUE;
	return FALSE;
}

@ Either way, we use the following code. The |SourceFiles::read_file| function returns
one of the following values to indicate the source of the source: the value
only really tells us something we didn't know in the case of extensions,
but in that event the Extensions.w routines do indeed want to know this.
(Area 51 is reserved for extensions of alien origin, but the relevant
source code is classified.)

@d ORIGIN_WAS_PRIMARY_SOURCE 0
@d ORIGIN_WAS_MATERIALS_EXTENSIONS_AREA 1 /* must match |*_FS_AREA| numbers plus 1 */
@d ORIGIN_WAS_USER_EXTENSIONS_AREA 2
@d ORIGIN_WAS_BUILT_IN_EXTENSIONS_AREA 3

=
int SourceFiles::read_file(filename *F, text_stream *synopsis, extension_file *EF,
	int documentation_only) {
	source_file *sf = NULL;
	int area = -1;
	if (EF)
		area = SourceFiles::read_file_inner(F, synopsis,
			pathname_of_extensions, NO_FS_AREAS + 1, documentation_only, &sf,
			STORE_POINTER_extension_file(EF), FALSE, EF);
	else
		area = SourceFiles::read_file_inner(F, synopsis,
			NULL, 0, documentation_only, &sf,
			STORE_POINTER_extension_file(NULL), TRUE, NULL);
	if (area == -1) {
		if (EF) {
			LOG("Author: %W\n", EF->author_text);
			LOG("Title: %W\n", EF->title_text);
			Problems::quote_source(1, current_sentence);
			Problems::quote_stream(2, synopsis);
			Problems::Issue::handmade_problem(_p_(PM_BogusExtension));
			Problems::issue_problem_segment(
				"I can't find the extension '%2', which seems not to be installed, "
				"but was requested by: %1. %P"
				"You can get hold of extensions which people have made public at "
				"the Inform website, www.inform7.com, or by using the Public "
				"Library in the Extensions panel.");
			Problems::issue_problem_end();
		} else {
			Problems::Fatal::filename_related(
				"Error: can't open source text file", F);
		}
	} else {
		if (EF == NULL) primary_source_file = sf;
		else Extensions::Files::set_corresponding_source_file(EF, sf);
		if (documentation_only == FALSE) @<Tell console output about the file@>;
	}
	return area;
}

@ This is where messages like

	|I've also read Standard Rules by Graham Nelson, which is 27204 words long.|

are printed to |stdout| (not |stderr|), in something of an affectionate nod
to \TeX's traditional console output, though occasionally I think silence is
golden and that the messages could go. It's a moot point for almost all users,
though, because the console output is concealed from them by the Inform
application.

@<Tell console output about the file@> =
	int wc;
	char *message;
	if (EF == NULL) message = "I've now read %S, which is %d words long.\n";
	else message = "I've also read %S, which is %d words long.\n";
	wc = TextFromFiles::total_word_count(sf);
	WRITE_TO(STDOUT, message, synopsis, wc);
	STREAM_FLUSH(STDOUT);
	LOG(message, synopsis, wc);

@ =
int SourceFiles::read_file_inner(filename *F, text_stream *synopsis,
	pathname **list, int list_len, int documentation_only, source_file **S,
	general_pointer ref, int primary, extension_file *EF) {
	int origin_tried = 1;

	FILE *handle = NULL; filename *eventual = F;
	@<Set pathname and filename, and open file@>;
	if (handle == NULL) return -1;
	text_stream *leaf = Filenames::get_leafname(eventual);
	if (primary) leaf = I"main source text";
	source_file *sf = TextFromFiles::feed_open_file_into_lexer(eventual, handle,
		leaf, documentation_only, ref);
	fclose(handle);

	if (S) *S = sf;
	return origin_tried;
}

@ The primary source text must be found where we expect it, or a fatal
error is issued. An extension, however, can be in one of two places: the
user's own repository of installed extensions, or the built-in stock. We
must try each possibility -- in that order, so that the user can supplant
the built-in extensions by installing hacked versions of her own -- and in
the event of failing, we issue only a standard Inform problem message and
continue. While meaningful compilation is unlikely to succeed now, this is
not a fatal error, because fatality would cause the user interface
application to communicate the problem badly.

@<Set pathname and filename, and open file@> =
	handle = NULL;
	if (list) {
		TEMPORARY_TEXT(author_name);
		TEMPORARY_TEXT(title);
		WRITE_TO(author_name, "%W", EF->author_text);
		WRITE_TO(title, "%W", EF->title_text);
		for (int area=0; area<list_len; area++)
			if (handle == NULL) {
				pathname *P = list[area];
				origin_tried = area + 1;
				eventual = Locations::of_extension(P, title, author_name, TRUE);
				handle = Filenames::fopen_caseless(eventual, "r");
				if (handle == NULL) {
					eventual = Locations::of_extension(P, title, author_name, FALSE);
					handle = Filenames::fopen_caseless(eventual, "r");
				}
			}
		DISCARD_TEXT(author_name);
		DISCARD_TEXT(title);
	} else {
		handle = Filenames::fopen(F, "r");
	}

@ =
extension_file *SourceFiles::get_extension_corresponding(source_file *sf) {
	if (sf == NULL) return NULL;
	return RETRIEVE_POINTER_extension_file(sf->your_ref);
}

@ And the following converts lexer error conditions into I7 problem messages.

@d LEXER_PROBLEM_HANDLER SourceFiles::lexer_problem_handler

=
void SourceFiles::lexer_problem_handler(int err, text_stream *problem_source_description, wchar_t *word) {
	switch (err) {
		case MEMORY_OUT_LEXERERROR:
			Problems::Fatal::issue("Out of memory: unable to create lexer workspace");
			break;
		case STRING_TOO_LONG_LEXERERROR:
            Problems::Issue::lexical_problem(_p_(PM_TooMuchQuotedText),
                "Too much text in quotation marks", word,
                "...\" The maximum length is very high, so this is more "
                "likely to be because a close quotation mark was "
                "forgotten.");
			break;
		case WORD_TOO_LONG_LEXERERROR:
              Problems::Issue::lexical_problem(_p_(PM_WordTooLong),
                "Word too long", word,
                "(Individual words of unquoted text can run up to "
                "128 letters long, which ought to be plenty. The longest "
                "recognised place name in the English speaking world is "
                "a hill in New Zealand called Taumatawhakatang-"
                "ihangakoauauot-amateaturipukaka-pikimaunga-"
                "horonuku-pokaiwhenuak-itanatahu. (You say tomato, "
                "I say taumatawhakatang-...) The longest word found in a "
                "classic novel is bababadalgharaghtakamminarronnkonnbronntonn"
                "erronntuonnthunntrovarrhounawnskawntoohoohoordenenthurnuk, "
                "creation's thunderclap from Finnegan's Wake. And both of those "
                "words are fine.)");
			break;
		case I6_TOO_LONG_LEXERERROR:
			Problems::Issue::lexical_problem(_p_(Untestable), /* well, not at all conveniently */
				"Verbatim Inform 6 extract too long", word,
				"... -). The maximum length is quite high, so this "
				"may be because a '-)' was forgotten. Still, if "
				"you do need to paste a huge I6 program in, try "
				"using several verbatim inclusions in a row.");
			break;
		case STRING_NEVER_ENDS_LEXERERROR:
			Problems::Issue::lexical_problem_S(_p_(PM_UnendingQuote),
				"Some source text ended in the middle of quoted text",
				problem_source_description,
				"This probably means that a quotation mark is missing "
				"somewhere. If you are using Inform with syntax colouring, "
				"look for where the quoted-text colour starts. (Sometimes "
				"this problem turns up because a piece of quoted text contains "
				"a text substitution in square brackets which in turn contains "
				"another piece of quoted text - this is not allowed, and causes "
				"me to lose track.)");
			break;
		case COMMENT_NEVER_ENDS_LEXERERROR:
			Problems::Issue::lexical_problem_S(_p_(PM_UnendingComment),
				"Some source text ended in the middle of a comment",
				problem_source_description,
				"This probably means that a ']' is missing somewhere. "
				"(If you are using Inform with syntax colouring, look for "
				"where the comment colour starts.) Inform's convention on "
				"'nested comments' is that each '[' in a comment must be "
				"matched by a corresponding ']': so for instance '[This "
				"[even nested like so] acts as a comment]' is a single "
				"comment - the first ']' character matches the second '[' "
				"and so doesn't end the comment: only the second ']' ends "
				"the comment.");
			break;
		case I6_NEVER_ENDS_LEXERERROR:
			Problems::Issue::lexical_problem_S(_p_(PM_UnendingI6),
				"Some source text ended in the middle of a verbatim passage "
				"of Inform 6 code",
				problem_source_description,
				"This probably means that a '-)' is missing.");
			break;
		default:
			internal_error("unknown lexer error");
    }
}
