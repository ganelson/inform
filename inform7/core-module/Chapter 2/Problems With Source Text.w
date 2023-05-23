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
				Problems::quote_stream(1, Filenames::get_leafname(CE->details_file));
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::issue_problem_segment(
					"I can't open the file '%1' of source text. %P"
					"If you are using the 'Source' subfolder of Materials to "
					"hold your source text, maybe your 'Contents.txt' has a "
					"typo in it?");
				Problems::issue_problem_end();		
				break;
			case EXT_MISWORDED_CE:
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_stream(2, CE->details);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ExtMiswordedBeginsHere));
				Problems::issue_problem_segment(
					"The extension %1, which your source text makes use of, seems to be "
					"damaged or incorrect: its identifying opening line is wrong. "
					"Specifically, %2.");
				Problems::issue_problem_end();
				break;
			case EXT_BAD_DIRNAME_CE:
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_stream(2, CE->details);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::issue_problem_segment(
					"The extension %1, which your source text makes use of, is stored "
					"in a directory (which is fine), but does not follow the rules for "
					"what that directory is called (which is not fine). Specifically, %2.");
				Problems::issue_problem_end();
				break;
			case EXT_BAD_FILENAME_CE:
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_stream(2, CE->details);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::issue_problem_segment(
					"The extension %1, which your source text makes use of, has the wrong "
					"filename for its source text. Specifically, %2.");
				Problems::issue_problem_end();
				break;
			case EXT_RANEOUS_CE:
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_stream(2, CE->details);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::issue_problem_segment(
					"The extension %1, which your source text makes use of, is stored "
					"in a directory (which is fine), but contains files or subdirectories "
					"which I don't recognise (which is not fine). Specifically, %2.");
				Problems::issue_problem_end();
				break;
			case PROJECT_MALFORMED_CE:
				Problems::quote_stream(1, CE->details);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::issue_problem_segment(
					"This project seems to be malformed. Specifically, %1.");
				Problems::issue_problem_end();
				break;
			case METADATA_MALFORMED_CE:
				if (CE->copy->found_by) {
					Problems::quote_work(1, CE->copy->found_by->work);
					Problems::quote_stream(2, CE->details);
					SourceProblems::quote_genre(3, CE);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
					Problems::issue_problem_segment(
						"The %3 %1, which your source text makes use of, seems to have "
						"metadata problems. Specifically: %2.");
					Problems::issue_problem_end();
				} else {
					Problems::quote_work(1, CE->copy->edition->work);
					Problems::quote_stream(2, CE->details);
					SourceProblems::quote_genre(3, CE);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
					Problems::issue_problem_segment(
						"The %3 %1 seems to have metadata problems. Specifically: %2.");
					Problems::issue_problem_end();
				}
				break;
			case LANGUAGE_UNAVAILABLE_CE:
				Problems::quote_work(1, CE->copy->edition->work);
				Problems::quote_stream(2, CE->details);
				SourceProblems::quote_genre(3, CE);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::issue_problem_segment(
					"The %3 %1 seems to need me to know about a non-English language, '%2'. "
					"I can't find any definition for this language.");
				Problems::issue_problem_end();
				break;
			case LANGUAGE_DEFICIENT_CE:
				Problems::quote_work(1, CE->copy->edition->work);
				Problems::quote_stream(2, CE->details);
				SourceProblems::quote_genre(3, CE);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::issue_problem_segment(
					"The %3 %1 seems to need me to work with a non-English language, but '%2'.");
				Problems::issue_problem_end();
				break;
			case EXT_TITLE_TOO_LONG_CE: {
				int max = MAX_EXTENSION_TITLE_LENGTH;
				int overage = CE->details_N - MAX_EXTENSION_TITLE_LENGTH;
				Problems::quote_work(1, CE->copy->found_by->work);
				Problems::quote_number(2, &max);
				Problems::quote_number(3, &overage);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ExtTitleTooLong));
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
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ExtAuthorTooLong));
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
						StandardProblems::lexical_problem(Task::syntax_tree(), _p_(PM_TooMuchQuotedText),
							"Too much text in quotation marks", CE->details_word,
							"...\" The maximum length is very high, so this is more "
							"likely to be because a close quotation mark was "
							"forgotten.");
						break;
					case WORD_TOO_LONG_LEXERERROR:
						  StandardProblems::lexical_problem(Task::syntax_tree(), _p_(PM_WordTooLong),
							"Word too long", CE->details_word,
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
						StandardProblems::lexical_problem(Task::syntax_tree(), _p_(Untestable), /* well, not at all conveniently */
							"Verbatim Inform 6 extract too long", CE->details_word,
							"... -). The maximum length is quite high, so this "
							"may be because a '-)' was forgotten. Still, if "
							"you do need to paste a huge I6 program in, try "
							"using several verbatim inclusions in a row.");
						break;
					case STRING_NEVER_ENDS_LEXERERROR:
						StandardProblems::lexical_problem_S(Task::syntax_tree(), _p_(PM_UnendingQuote),
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
						StandardProblems::lexical_problem_S(Task::syntax_tree(), _p_(PM_UnendingComment),
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
						StandardProblems::lexical_problem_S(Task::syntax_tree(), _p_(PM_UnendingI6),
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
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnexpectedSemicolon));
						Problems::issue_problem_segment(
							"The text %1 is followed by a semicolon ';', which only makes "
							"sense to me inside a rule or phrase (where there's a heading, "
							"then a colon, then a list of instructions divided by semicolons). "
							"Perhaps you want a full stop '.' instead?");
						Problems::issue_problem_end();
						break;
					case ParaEndsInColon_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ParaEndsInColon));
						Problems::issue_problem_segment(
							"The text %1 seems to end a paragraph with a colon. (Rule declarations "
							"can end a sentence with a colon, so maybe there's accidentally a "
							"skipped line here?)");
						Problems::issue_problem_end();
						break;
					case SentenceEndsInColon_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SentenceEndsInColon));
						Problems::issue_problem_segment(
							"The text %1 seems to have a colon followed by a full stop, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case SentenceEndsInSemicolon_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SentenceEndsInSemicolon));
						Problems::issue_problem_segment(
							"The text %1 seems to have a semicolon followed by a full stop, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case SemicolonAfterColon_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SemicolonAfterColon));
						Problems::issue_problem_segment(
							"The text %1 seems to have a semicolon following a colon, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case SemicolonAfterStop_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SemicolonAfterStop));
						Problems::issue_problem_segment(
							"The text %1 seems to have a semicolon following a full stop, which is "
							"punctuation I don't understand.");
						Problems::issue_problem_end();
						break;
					case HeadingOverLine_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						Problems::quote_source(2, Diagrams::new_UNPARSED_NOUN(Wordings::up_to(CE->details_W, CE->details_N-1)));
						Problems::quote_source(3, Diagrams::new_UNPARSED_NOUN(Wordings::from(CE->details_W, CE->details_N)));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_HeadingOverLine));
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
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						Problems::quote_source(2,
							Diagrams::new_UNPARSED_NOUN(Wordings::new(Wordings::last_wn(CE->details_W)+1, CE->details_N-1)));
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_HeadingStopsBeforeEndOfLine));
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
						StandardProblems::extension_problem(_p_(PM_ExtNoBeginsHere),
							Extensions::from_copy(C),
							"has no 'begins here' sentence");
						break;
					case ExtNoEndsHere_SYNERROR:
						StandardProblems::extension_problem(_p_(PM_ExtNoEndsHere),
							Extensions::from_copy(C),
							"has no 'ends here' sentence");
						break;
					case ExtSpuriouslyContinues_SYNERROR:
						StandardProblems::extension_problem(_p_(PM_ExtSpuriouslyContinues),
							Extensions::from_copy(C),
							"continues after the 'ends here' sentence");
						break;
					case ExtMultipleEndsHere_SYNERROR:
						StandardProblems::extension_problem(_p_(PM_ExtMultipleEndsHere),
							Extensions::from_copy(C),
							"has more than one 'ends here' sentence");
						break;
					case ExtMultipleBeginsHere_SYNERROR:
						StandardProblems::extension_problem(_p_(PM_ExtMultipleBeginsHere),
							Extensions::from_copy(C),
							"has more than one 'begins here' sentence");
						break;
					case ExtBeginsAfterEndsHere_SYNERROR:
						StandardProblems::extension_problem(_p_(PM_ExtBeginsAfterEndsHere),
							Extensions::from_copy(C),
							"has a further 'begins here' after an 'ends here'");
						break;
					case ExtEndsWithoutBegins_SYNERROR:
						StandardProblems::extension_problem(_p_(BelievedImpossible),
							Extensions::from_copy(C),
							"has an 'ends here' with nothing having begun");
						break;
					case BadTitleSentence_SYNERROR:
						current_sentence = NULL;
						StandardProblems::unlocated_problem(Task::syntax_tree(),
							_p_(PM_BadTitleSentence),
							"The opening bibliographic sentence can only be a title in "
							"double-quotes, possibly followed with 'by' and the name of "
							"the author.");
						break;
					case UnknownLanguageElement_SYNERROR:
						current_sentence = CE->details_node;
						StandardProblems::sentence_problem(
							Task::syntax_tree(), _p_(PM_UnknownLanguageElement),
							"this heading contains a stipulation about the current "
							"Inform language definition which I can't understand",
							"and should be something like '(for Glulx external files "
							"language element only)'.");
						break;
					case UnknownVirtualMachine_SYNERROR:
						current_sentence = CE->details_node;
						StandardProblems::sentence_problem(
							Task::syntax_tree(), _p_(PM_UnknownVirtualMachine),
							"this heading contains a stipulation about the Setting "
							"for story file format which I can't understand",
							"and should be something like '(for Z-machine version 5 "
							"or 8 only)' or '(for Glulx only)'.");
						break;
					case UseElementWithdrawn_SYNERROR:
						current_sentence = CE->details_node;
						StandardProblems::sentence_problem(
							Task::syntax_tree(), _p_(PM_UseElementWithdrawn),
							"the ability to activate or deactivate compiler elements "
							"in source text has been withdrawn",
							"in favour of a new system with Inform kits.");
						break;
					case IncludeExtQuoted_SYNERROR:
						current_sentence = CE->details_node;
						StandardProblems::sentence_problem(
							Task::syntax_tree(), _p_(PM_IncludeExtQuoted),
							"the name of an included extension should be given without double "
							"quotes in an Include sentence",
							"so for instance 'Include Oh My God by Janice Bing.' rather than "
							"'Include \"Oh My God\" by Janice Bing.')");
						break;
					case BogusExtension_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BogusExtension));
						Problems::issue_problem_segment(
							"I can't find the extension requested by: %1.");
						Problems::issue_problem_end();
						break;
					case ExtVersionTooLow_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_stream(2, CE->details);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ExtVersionTooLow));
						Problems::issue_problem_segment(
							"I can't find the right version of the extension requested by %1 - "
							"I can only find %2.");
						Problems::issue_problem_end();
						break;
					case ExtVersionMalformed_SYNERROR:
						current_sentence = CE->details_node;
						StandardProblems::sentence_problem(
							Task::syntax_tree(), _p_(PM_ExtVersionMalformed),
							"a version number must have the form N/DDDDDD",
							"as in the example '2/040426' for release 2 made on 26 April 2004. "
							"(The DDDDDD part is optional, so '3' is a legal version number too. "
							"N must be between 1 and 999: in particular, there is no version 0.)");
						break;
					case ExtInadequateVM_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_stream(2, CE->details);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ExtInadequateVM));
						Problems::issue_problem_segment(
							"You wrote %1: but my copy of that extension stipulates that it "
							"is '%2'. That means it can only be used with certain of "
							"the possible compiled story file formats, and at the "
							"moment, we don't fit the requirements. (You can change "
							"the format used for this project on the Settings panel.)");
						Problems::issue_problem_end();
						break;
					case ExtMisidentifiedEnds_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_extension(1, Extensions::from_copy(C));
						Problems::quote_wording(2, CE->details_W);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ExtMisidentifiedEnds));
						Problems::issue_problem_segment(
							"The extension %1, which your source text makes use of, seems to be "
							"malformed: its 'begins here' sentence correctly identifies it, but "
							"then the 'ends here' sentence calls it '%2' instead. (They need "
							"to be a matching pair except that the end does not name the "
							"author: for instance, 'Hocus Pocus by Jan Ackerman begins here.' "
							"would match with 'Hocus Pocus ends here.')");
						Problems::issue_problem_end();
						break;
					case HeadingInPlaceOfUnincluded_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_extension_id(2, CE->details_work);
						StandardProblems::handmade_problem(
							Task::syntax_tree(), _p_(PM_HeadingInPlaceOfUnincluded));
						Problems::issue_problem_segment(
							"In the sentence %1, it looks as if you intend to replace a section "
							"of source text from the extension '%2', but no extension of that "
							"name has been included - so it is not possible to replace any of its "
							"headings.");
						Problems::issue_problem_end();
						break;
					case UnequalHeadingInPlaceOf_SYNERROR:
						current_sentence = CE->details_node;
						StandardProblems::sentence_problem(
							Task::syntax_tree(), _p_(PM_UnequalHeadingInPlaceOf),
							"these headings are not of the same level",
							"so it is not possible to make the replacement. (Level here means "
							"being a Volume, Book, Part, Chapter or Section: for instance, "
							"only a Chapter heading can be used 'in place of' a Chapter.)");
						break;
					case HeadingInPlaceOfSubordinate_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_extension_id(2, CE->details_work);
						Problems::quote_source(3, CE->details_node2);
						Problems::quote_extension_id(4, CE->details_work2);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_HeadingInPlaceOfSubordinate));
						Problems::issue_problem_segment(
							"In the sentence %1, it looks as if you intend to replace a section "
							"of source text from the extension '%2', but that doesn't really make "
							"sense because this new piece of source text is part of a superior "
							"heading ('%3') which is already being replaced spliced into '%4'.");
						Problems::issue_problem_end();
						break;
					case HeadingInPlaceOfUnknown_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_extension_id(2, CE->details_work);
						Problems::quote_wording(3, CE->details_W);
						Problems::quote_stream(4, CE->details);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_HeadingInPlaceOfUnknown));
						Problems::issue_problem_segment(
							"In the sentence %1, it looks as if you intend to replace a section "
							"of source text from the extension '%2', but that extension does "
							"not seem to have any heading called '%3'. (The version I loaded "
							"was %4.)");
						Problems::issue_problem_end();
						break;
					case UnavailableLOS_SYNERROR:
						current_sentence = NULL;
						Problems::quote_stream(1, CE->details);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
						Problems::issue_problem_segment(
							"The project says that its syntax is written in a language "
							"other than English (specifically, %1), but the language bundle "
							"for that language does not provide a file of Preform definitions.");
						Problems::issue_problem_end();
						break;
					case DialogueOnSectionsOnly_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						StandardProblems::handmade_problem(Task::syntax_tree(),
							_p_(PM_DialogueOnSectionsOnly));
						Problems::issue_problem_segment(
							"In the heading %1, you've marked for '(dialogue)', but only "
							"Sections can be so marked - not Chapters, Books, and so on.");
						Problems::issue_problem_end();
						break;
					case UnexpectedDialogue_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(),
							_p_(PM_UnexpectedDialogue));
						Problems::issue_problem_segment(
							"The text %1 appears under a section heading marked as dialogue, "
							"so it needs to be either a cue in brackets '(like this.)', or "
							"else a line of dialogue 'Speaker: \"Something to say!\"'. It "
							"doesn't seem to be either of those.");
						Problems::issue_problem_end();
						break;
					case UnquotedDialogue_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(),
							 _p_(PM_UnquotedDialogue));
						Problems::issue_problem_segment(
							"The text %1 appears to be a line of dialogue, but after the "
							"colon ':' there should only be a single double-quoted text.");
						Problems::issue_problem_end();
						break;
					case EmptyDialogueClause_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(),
							_p_(PM_EmptyDialogueClause));
						Problems::issue_problem_segment(
							"The text %1 appears to be a bracketed clause to do with "
							"dialogue, but the punctuation looks wrong because it includes "
							"an empty part.");
						Problems::issue_problem_end();
						break;
					case MisbracketedDialogueClause_SYNERROR:
						Problems::quote_source(1, Diagrams::new_UNPARSED_NOUN(CE->details_W));
						StandardProblems::handmade_problem(Task::syntax_tree(),
							_p_(PM_MisbracketedDialogueClause));
						Problems::issue_problem_segment(
							"The text %1 appears to be a bracketed clause to do with "
							"dialogue, but the punctuation looks wrong because it uses "
							"brackets '(' and ')' in a way which doesn't match. There "
							"should be just one outer pair of brackets, and inside they "
							"can only be used to clarify clauses, if necessary.");
						Problems::issue_problem_end();
						break;
					case MissingSourceFile_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_stream(2, CE->details);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
						Problems::issue_problem_segment(
							"I can't find the source file holding the content of the heading %1 - "
							"it should be '%2' in the 'Source' subdirectory of the materials "
							"for this project.");
						Problems::issue_problem_end();
						break;
					case HeadingWithFileNonempty_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_stream(2, CE->details);
						Problems::quote_source(3, current_sentence->down);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
						Problems::issue_problem_segment(
							"The heading %1 should refer only to the contents of the file "
							"'%2' (in the 'Source' subdirectory of the materials for this "
							"project) but in fact goes on to contain other material too. "
							"That other material (see %3) needs to be put under a new "
							"heading of equal or greater priority (or else moved to the file).");
						Problems::issue_problem_end();
						break;
					case MisheadedSourceFile_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						Problems::quote_stream(2, CE->details);
						heading *h = Node::get_embodying_heading(current_sentence);
						if (h) Problems::quote_wording(3, h->heading_text);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
						Problems::issue_problem_segment(
							"The heading %1 says that its contents are in the file "
							"'%2' (in the 'Source' subdirectory of the materials for this "
							"project). If so, then that file needs to start with a matching "
							"opening line, giving the same heading name '%3'; and it doesn't.");
						Problems::issue_problem_end();
						break;
					case HeadingTooGreat_SYNERROR:
						current_sentence = CE->details_node;
						Problems::quote_source(1, current_sentence);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
						Problems::issue_problem_segment(
							"The heading %1 is too high a level to appear in this source "
							"file. For example, if a source file contains the contents of "
							"a Chapter, then it cannot contain a Book heading - "
							"a Chapter can be part of a Book, but not vice versa.");
						Problems::issue_problem_end();
						break;
					default:
						internal_error("unknown syntax error");
				}
				break;
			default: internal_error("an unknown error occurred");
		}
	}
}

void SourceProblems::quote_genre(int N, copy_error *CE) {
	text_stream *name = CE->copy->edition->work->genre->genre_name;
	if (Str::eq(name, I"projectbundle")) name = I"project";
	if (Str::eq(name, I"projectfile")) name = I"project";
	if (Str::eq(name, I"extensionbundle")) name = I"extension";
	Problems::quote_stream(N, name);
}

@ These are errors generated by the //building// module, but which we want to
tidy up and present in the usual Inform 7 way.

=
void SourceProblems::inter_schema_errors(inter_schema *sch) {
	Problems::quote_source(1, current_sentence);
	Problems::quote_stream(2, sch->converted_from);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_InterSchemaErrors));
	Problems::issue_problem_segment(
		"In the sentence %1, you use a fragment of code written in Inform 6 "
		"syntax which seems to be malformed in some way. I delegate all that "
		"work to a lesser compiler: I gave it '%2' to compile, and it came "
		"back with this: ");
	schema_parsing_error *err;
	int c = 1;
	LOOP_OVER_LINKED_LIST(err, schema_parsing_error, sch->parsing_errors) {
		Problems::quote_stream(1, err->message);
		Problems::quote_number(2, &c);
		Problems::issue_problem_segment("%P%2. %1 ");
		c++;
	}
	Problems::issue_problem_end();
}

@ And these are errors (mostly) from parsing the Inform 6-syntax content
in |Include (- ... -)| insertions of low-level code:

=
text_stream *notified_kit_name = NULL;
text_stream *notified_architecture_name = NULL;
int general_kit_notice_issued = FALSE;
int trigger_kit_notice = FALSE;

void SourceProblems::kit_notification(text_stream *kit_name, text_stream *architecture_name) {
	if (Str::len(kit_name) > 0) trigger_kit_notice = TRUE;
	else trigger_kit_notice = FALSE;
	notified_kit_name = Str::duplicate(kit_name);
	notified_architecture_name = Str::duplicate(architecture_name);
}

void SourceProblems::I6_level_error(char *message, text_stream *quote,
	text_provenance at) {
	filename *F = Provenance::get_filename(at);
	int line = Provenance::get_line(at);
	TEMPORARY_TEXT(file)
	if (F) WRITE_TO(file, "%f", F);
	TEMPORARY_TEXT(kit)
	TEMPORARY_TEXT(M)
	WRITE_TO(M, message, quote);
	if (Provenance::is_somewhere(at)) {
		TEMPORARY_TEXT(EX)
		Filenames::write_extension(EX, F);
		if (Str::eq_insensitive(EX, I".i6t")) {
			pathname *P = Filenames::up(F);
			if (Str::eq_insensitive(Pathnames::directory_name(P), I"Sections"))
				P = Pathnames::up(P);
			WRITE_TO(kit, "%S", Pathnames::directory_name(P));
			Str::clear(file);
			WRITE_TO(file, "%S", Filenames::get_leafname(F));
		}
		DISCARD_TEXT(EX)
	}
	if (trigger_kit_notice) {
		if (general_kit_notice_issued == FALSE) {
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
			Problems::issue_problem_segment(
				"Before the project could be translated, one of the 'kits' of low-level "
				"Inter code which it uses needed to be built first. This is seldom "
				"necessary and normally happens silently when it is, but this time errors "
				"occurred and therefore translation had to be abandoned. If you are "
				"currently tinkering with a kit, you'll often see errors like this, "
				"but otherwise it probably means that a new extension you're using "
				"(and which contains a kit) isn't properly working.");
			general_kit_notice_issued = TRUE;
			Problems::issue_problem_end();
		}
		WRITE_TO(problems_file, "<h3>Building %S for architecture %S</h3>\n",
			notified_kit_name, notified_architecture_name);
		trigger_kit_notice = FALSE;
	}
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_I6SyntaxError));
	Problems::quote_stream(1, M);
	if (Str::len(kit) > 0) {
		Problems::quote_stream(2, file);
		Problems::quote_number(3, &line);
		Problems::quote_stream(4, kit);
		if (general_kit_notice_issued) Problems::issue_problem_segment("%2, near line %3: %1.");
		else Problems::issue_problem_segment("Near line %3 of file %2 in %4: %1.");
	} else if (Provenance::is_somewhere(at)) {
		LOG("%S, line %d:\n", file, line);
		Problems::problem_quote_file(2, file, line);
		Problems::issue_problem_segment(
			"Inform 6 syntax error near here %2: %1.");
	} else {
		Problems::issue_problem_segment(
			"My low-level reader of source code reported a mistake - \"%1\". "
			"%PLow-level material written in Inform 6 syntax occurs either in kits or "
			"in matter written inside 'Include (- ... -)' in source text, either in "
			"the main source or in an extension used by it.");
	}
	Problems::issue_problem_end();
	if ((Str::len(kit) > 0) && (general_kit_notice_issued)) {
		WRITE_TO(problems_file, "<p>Path: ");
		pathname *P = NULL, *Q = NULL, *MAT = NULL, *EXT = NULL, *INT = NULL;
		for (Q = Filenames::up(F); Q; Q = Pathnames::up(Q)) {
			text_stream *name = Pathnames::directory_name(Q);
			if (Str::eq_insensitive(name, I"Extensions")) EXT = Q;
			if (Str::eq_insensitive(name, I"Inter")) INT = Q;
			if (Str::suffix_eq(name, I".materials", 10)) MAT = Q;
		}
		if (MAT) P = MAT; else if (EXT) P = EXT; else if (INT) P = INT;
		if (P) Filenames::to_text_relative(problems_file, F, Pathnames::up(P));
		else WRITE_TO(problems_file, "%f", F);
		WRITE_TO(problems_file, "</p>");
	}
	DISCARD_TEXT(M)
	DISCARD_TEXT(kit)
}
