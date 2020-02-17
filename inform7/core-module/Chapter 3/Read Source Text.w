[SourceFiles::] Read Source Text.

This is where source text is read in, whether from extension files
or from the main source text file, and fed into the lexer.

@h Definitions.

@ The source text is drawn almost entirely from the primary source file and
the extensions, but Inform does also inject small amounts of source text of
its own (for instance, when a new kind is created, the kind interpreter
does this), and some extensions, such as Basic Inform, need to be given
inclusion sentences -- see Kits.

=
void SourceFiles::read_primary_source_text(void) {
	inbuild_copy *C = Inbuild::project()->as_copy;
	Copies::read_source_text_for(C);
	SourceFiles::issue_problems_arising(C);
}

void SourceFiles::issue_problems_arising(inbuild_copy *C) {
	if (C == NULL) return;
	copy_error *CE;
	LOOP_OVER_LINKED_LIST(CE, copy_error, C->errors_reading_source_text) {
		switch (CE->error_category) {
			case OPEN_FAILED_CE:
				Problems::quote_stream(1, Filenames::get_leafname(CE->file));
				Problems::Issue::handmade_problem(_p_(Untestable));
				Problems::issue_problem_segment(
					"I can't open the file '%1' of source text. %P"
					"If you are using the 'Source' subfolder of Materials to "
					"hold your source text, maybe your 'Contents.txt' has a "
					"typo in it?");
				Problems::issue_problem_end();		
				break;
			case EXT_MISWORDED_CE:
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_stream(2, CE->notes);
				Problems::Issue::handmade_problem(_p_(PM_ExtMiswordedBeginsHere));
				Problems::issue_problem_segment(
					"The extension %1, which your source text makes use of, seems to be "
					"damaged or incorrect: its identifying opening line is wrong. "
					"Specifically, %2.");
				Problems::issue_problem_end();
				break;
			default: internal_error("an unknown error occurred");
		}
	}
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

inform_extension *SourceFiles::get_extension_corresponding(source_file *sf) {
	if (sf == NULL) return NULL;
	inbuild_copy *C = RETRIEVE_POINTER_inbuild_copy(sf->your_ref);
	if (C == NULL) return NULL;
	if (C->edition->work->genre != extension_genre) return NULL;
	return ExtensionManager::from_copy(C);
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
