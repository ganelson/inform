[SourceProblems::] Problems With Source Text.

Errors with the source text, either lexical issues or major syntactic ones, 
are found when Inbuild reads the text in: what this section does is to collect
and issue those errors as tidy Inform problem messages.

@ To trigger all of the problems listed below, test with the |:inbuild|
group.

=
void SourceProblems::issue_problems_arising(inbuild_copy *C) {
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
			case KIT_MISWORDED_CE:
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_stream(2, CE->notes);
				Problems::Issue::handmade_problem(_p_(Untestable));
				Problems::issue_problem_segment(
					"The kit %1, which your source text makes use of, seems to be "
					"damaged or incorrect: its identifying opening line is wrong. "
					"Specifically, %2.");
				Problems::issue_problem_end();
				break;
			case EXT_TITLE_TOO_LONG_CE: {
				int max = MAX_EXTENSION_TITLE_LENGTH;
				int overage = CE->details_N - MAX_EXTENSION_TITLE_LENGTH;
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_number(2, &max);
				Problems::quote_number(3, &overage);
				Problems::Issue::handmade_problem(_p_(PM_ExtTitleTooLong));
				Problems::issue_problem_segment(
					"The extension %1, which your source text makes use of, has a "
					"title which is too long, exceeding the maximum allowed "
					"(%2 characters) by %3.");
				Problems::issue_problem_end();
				break;
			}
			case EXT_AUTHOR_TOO_LONG_CE: {
				int max = MAX_EXTENSION_AUTHOR_LENGTH;
				int overage = CE->details_N - MAX_EXTENSION_AUTHOR_LENGTH;
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_number(2, &max);
				Problems::quote_number(3, &overage);
				Problems::Issue::handmade_problem(_p_(PM_ExtAuthorTooLong));
				Problems::issue_problem_segment(
					"The extension %1, which your source text makes use of, has an "
					"author name which is too long, exceeding the maximum allowed "
					"(%2 characters) by %3.");
				Problems::issue_problem_end();
				break;
			}
			case LEXER_CE:
				switch (CE->error_subcategory) {
					case STRING_TOO_LONG_LEXERERROR:
						Problems::Issue::lexical_problem(_p_(PM_TooMuchQuotedText),
							"Too much text in quotation marks", CE->word,
							"...\" The maximum length is very high, so this is more "
							"likely to be because a close quotation mark was "
							"forgotten.");
						break;
					case WORD_TOO_LONG_LEXERERROR:
						  Problems::Issue::lexical_problem(_p_(PM_WordTooLong),
							"Word too long", CE->word,
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
							"Verbatim Inform 6 extract too long", CE->word,
							"... -). The maximum length is quite high, so this "
							"may be because a '-)' was forgotten. Still, if "
							"you do need to paste a huge I6 program in, try "
							"using several verbatim inclusions in a row.");
						break;
					case STRING_NEVER_ENDS_LEXERERROR:
						Problems::Issue::lexical_problem_S(_p_(PM_UnendingQuote),
							"Some source text ended in the middle of quoted text",
							CE->details,
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
							CE->details,
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
							CE->details,
							"This probably means that a '-)' is missing.");
						break;
					default:
						internal_error("unknown lexer error");
				}
				break;
			case SYNTAX_CE:
				switch (CE->error_subcategory) {
					case UnexpectedSemicolon_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::Issue::handmade_problem(_p_(PM_UnexpectedSemicolon));
						Problems::issue_problem_segment(
							"The text %1 is followed by a semicolon ';', which only makes "
							"sense to me inside a rule or phrase (where there's a heading, "
							"then a colon, then a list of instructions divided by semicolons). "
							"Perhaps you want a full stop '.' instead?");
						Problems::issue_problem_end();
						break;
					case ParaEndsInColon_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::Issue::handmade_problem(_p_(PM_ParaEndsInColon));
						Problems::issue_problem_segment(
							"The text %1 seems to end a paragraph with a colon. (Rule declarations "
							"can end a sentence with a colon, so maybe there's accidentally a "
							"skipped line here?)");
						Problems::issue_problem_end();
						break;
					case SentenceEndsInColon_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::Issue::handmade_problem(_p_(PM_SentenceEndsInColon));
						Problems::issue_problem_segment(
							"The text %1 seems to have a colon followed by a full stop, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case SentenceEndsInSemicolon_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::Issue::handmade_problem(_p_(PM_SentenceEndsInSemicolon));
						Problems::issue_problem_segment(
							"The text %1 seems to have a semicolon followed by a full stop, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case SemicolonAfterColon_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::Issue::handmade_problem(_p_(PM_SemicolonAfterColon));
						Problems::issue_problem_segment(
							"The text %1 seems to have a semicolon following a colon, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case SemicolonAfterStop_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::Issue::handmade_problem(_p_(PM_SemicolonAfterStop));
						Problems::issue_problem_segment(
							"The text %1 seems to have a semicolon following a full stop, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case HeadingOverLine_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::quote_source(2, NounPhrases::new_raw(Wordings::up_to(CE->details_W, CE->details_N-1)));
						Problems::quote_source(3, NounPhrases::new_raw(Wordings::from(CE->details_W, CE->details_N)));
						Problems::Issue::handmade_problem(_p_(PM_HeadingOverLine));
						Problems::issue_problem_segment(
							"The text %1 seems to be a heading, but contains a "
							"line break, which is not allowed: so I am reading it "
							"as just %2 and ignoring the continuation %3. The rule "
							"is that a heading must be a single line which is the "
							"only sentence in its paragraph, so there must be a "
							"skipped line above and below.");
						Problems::issue_problem_end();
						break;
					case HeadingStopsBeforeEndOfLine_SYNERROR:
						Problems::quote_source(1, NounPhrases::new_raw(CE->details_W));
						Problems::quote_source(2,
							NounPhrases::new_raw(Wordings::new(Wordings::last_wn(CE->details_W)+1, CE->details_N-1)));
						Problems::Issue::handmade_problem(_p_(PM_HeadingStopsBeforeEndOfLine));
						Problems::issue_problem_segment(
							"The text %1 seems to be a heading, but does not occupy "
							"the whole of its line of source text, which continues %2. "
							"The rule is that a heading must occupy a whole single line "
							"which is the only sentence in its paragraph, so there "
							"must be a skipped line above and below. %P"
							"A heading must not contain a colon ':' or any full stop "
							"characters '.', even if they occur in an ellipsis '...' or a "
							"number '2.3.13'. (I mention that because sometimes this problem "
							"arises when a decimal point is misread as a full stop.)");
						Problems::issue_problem_end();
						break;

					case ExtNoBeginsHere_SYNERROR:
						Problems::Issue::extension_problem(_p_(PM_ExtNoBeginsHere),
							ExtensionManager::from_copy(C),
							"has no 'begins here' sentence");
						break;
					case ExtNoEndsHere_SYNERROR:
						Problems::Issue::extension_problem(_p_(PM_ExtNoEndsHere),
							ExtensionManager::from_copy(C),
							"has no 'ends here' sentence");
						break;
					case ExtSpuriouslyContinues_SYNERROR:
						Problems::Issue::extension_problem(_p_(PM_ExtSpuriouslyContinues),
							ExtensionManager::from_copy(C),
							"continues after the 'ends here' sentence");
						break;
					case ExtMultipleEndsHere_SYNERROR:
						Problems::Issue::extension_problem(_p_(PM_ExtMultipleEndsHere),
							ExtensionManager::from_copy(C),
							"has more than one 'ends here' sentence");
						break;
					case ExtMultipleBeginsHere_SYNERROR:
						Problems::Issue::extension_problem(_p_(PM_ExtMultipleBeginsHere),
							ExtensionManager::from_copy(C),
							"has more than one 'begins here' sentence");
						break;
					case ExtBeginsAfterEndsHere_SYNERROR:
						Problems::Issue::extension_problem(_p_(PM_ExtBeginsAfterEndsHere),
							ExtensionManager::from_copy(C),
							"has a further 'begins here' after an 'ends here'");
						break;
					case ExtEndsWithoutBegins_SYNERROR:
						Problems::Issue::extension_problem(_p_(BelievedImpossible),
							ExtensionManager::from_copy(C),
							"has an 'ends here' with nothing having begun");
						break;
					case BadTitleSentence_SYNERROR:
						current_sentence = CE->details_node;
						Problems::Issue::sentence_problem(_p_(PM_BadTitleSentence),
							"the initial bibliographic sentence can only be a title in double-quotes",
							"possibly followed with 'by' and the name of the author.");
						break;
					default:
						internal_error("unknown syntax error");
				}
				break;
			default: internal_error("an unknown error occurred");
		}
	}
}
