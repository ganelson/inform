[StructuralSentences::] Structural Sentences.

To parse structurally important sentences.

@

@d list_node_type ROUTINE_NT
@d list_entry_node_type INVOCATION_LIST_NT

@h Sentence division.
Sentence division can happen either early in Inform's run, when the vast bulk
of the source text is read, or at intermittent periods later when fresh text
is generated internally. New sentences need to be treated slightly differently
in these cases, so this seems as good a point as any to define the routine
which the |.i6t| interpreter calls when it wants to signal that the source
text has now officially been read.

@d SENTENCE_ANNOTATION_FUNCTION StructuralSentences::annotate_new_sentence

=
int text_loaded_from_source = FALSE;
void StructuralSentences::declare_source_loaded(void) {
	text_loaded_from_source = TRUE;
}

void StructuralSentences::annotate_new_sentence(parse_node *new) {
	if (text_loaded_from_source) {
		ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
		Sentences::VPs::seek(new);
	}
}

@

@d NEW_HEADING_HANDLER StructuralSentences::new_heading

=
int StructuralSentences::new_heading(parse_node *new) {
	heading *h = Sentences::Headings::declare(new);
	ParseTree::set_embodying_heading(new, h);
	return Sentences::Headings::include_material(h);
}

@

@d NEW_BEGINEND_HANDLER StructuralSentences::new_beginend

=
void StructuralSentences::new_beginend(parse_node *new, inform_extension *E) {
	if (ParseTree::get_type(new) == BEGINHERE_NT)
		Extensions::Inclusion::check_begins_here(new, sfsm_extension);
	if (ParseTree::get_type(new) == ENDHERE_NT)
		Extensions::Inclusion::check_ends_here(new, sfsm_extension);
}

@

@d NEW_LANGUAGE_HANDLER StructuralSentences::new_language

=
void StructuralSentences::new_language(wording W) {
	Problems::Issue::sentence_problem(_p_(PM_UseElementWithdrawn),
		"the ability to activate or deactivate compiler elements in source text has been withdrawn",
		"in favour of a new system with Inform kits.");
}

@ This is for invented sentences, such as those creating the understood
variables.

=
void StructuralSentences::add_inventions_heading(void) {
	parse_node *implicit_heading = ParseTree::new(HEADING_NT);
	ParseTree::set_text(implicit_heading, Feeds::feed_text_expanding_strings(L"Invented sentences"));
	ParseTree::annotate_int(implicit_heading, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(implicit_heading, heading_level_ANNOT, 0);
	ParseTree::insert_sentence(implicit_heading);
	Sentences::Headings::declare(implicit_heading);
}

@

@d SYNTAX_PROBLEM_HANDLER StructuralSentences::syntax_problem_handler

=
void StructuralSentences::syntax_problem_handler(int err_no, wording W, void *ref, int k) {
	switch (err_no) {
		case UnexpectedSemicolon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_UnexpectedSemicolon));
			Problems::issue_problem_segment(
				"The text %1 is followed by a semicolon ';', which only makes "
				"sense to me inside a rule or phrase (where there's a heading, "
				"then a colon, then a list of instructions divided by semicolons). "
				"Perhaps you want a full stop '.' instead?");
			Problems::issue_problem_end();
			break;
		case ParaEndsInColon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_ParaEndsInColon));
			Problems::issue_problem_segment(
				"The text %1 seems to end a paragraph with a colon. (Rule declarations "
				"can end a sentence with a colon, so maybe there's accidentally a "
				"skipped line here?)");
			Problems::issue_problem_end();
			break;
		case SentenceEndsInColon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SentenceEndsInColon));
			Problems::issue_problem_segment(
				"The text %1 seems to have a colon followed by a full stop, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case SentenceEndsInSemicolon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SentenceEndsInSemicolon));
			Problems::issue_problem_segment(
				"The text %1 seems to have a semicolon followed by a full stop, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case SemicolonAfterColon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SemicolonAfterColon));
			Problems::issue_problem_segment(
				"The text %1 seems to have a semicolon following a colon, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case SemicolonAfterStop_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SemicolonAfterStop));
			Problems::issue_problem_segment(
				"The text %1 seems to have a semicolon following a full stop, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case ExtNoBeginsHere_SYNERROR: {
			inform_extension *E = (inform_extension *) ref;
			Problems::Issue::extension_problem(_p_(PM_ExtNoBeginsHere),
				E, "has no 'begins here' sentence");
			break;
		}
		case ExtNoEndsHere_SYNERROR: {
			inform_extension *E = (inform_extension *) ref;
			Problems::Issue::extension_problem(_p_(PM_ExtNoEndsHere),
				E, "has no 'ends here' sentence");
			break;
		}
		case ExtSpuriouslyContinues_SYNERROR: {
			inform_extension *E = (inform_extension *) ref;
			LOG("Spurious text: %W\n", W);
			Problems::Issue::extension_problem(_p_(PM_ExtSpuriouslyContinues),
				E, "continues after the 'ends here' sentence");
			break;
		}
		case HeadingOverLine_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::quote_source(2, NounPhrases::new_raw(Wordings::up_to(W, k-1)));
			Problems::quote_source(3, NounPhrases::new_raw(Wordings::from(W, k)));
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
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::quote_source(2,
				NounPhrases::new_raw(Wordings::new(Wordings::last_wn(W)+1, k-1)));
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
		case ExtMultipleBeginsHere_SYNERROR: {
			inform_extension *E = (inform_extension *) ref;
			Problems::Issue::extension_problem(_p_(PM_ExtMultipleBeginsHere),
				E, "has more than one 'begins here' sentence");
			break;
		}
		case ExtBeginsAfterEndsHere_SYNERROR: {
			inform_extension *E = (inform_extension *) ref;
			Problems::Issue::extension_problem(_p_(PM_ExtBeginsAfterEndsHere),
				E, "has a further 'begins here' after an 'ends here'");
			break;
		}
		case ExtEndsWithoutBegins_SYNERROR: {
			inform_extension *E = (inform_extension *) ref;
			Problems::Issue::extension_problem(_p_(BelievedImpossible),
				E, "has an 'ends here' with nothing having begun"); break;
			break;
		}
		case ExtMultipleEndsHere_SYNERROR: {
			inform_extension *E = (inform_extension *) ref;
			Problems::Issue::extension_problem(_p_(PM_ExtMultipleEndsHere),
				E, "has more than one 'ends here' sentence"); break;
			break;
		}

		default: internal_error("unimplemented problem message");
	}
}

