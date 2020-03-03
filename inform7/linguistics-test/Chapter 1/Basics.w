[Basics::] Basics.

Some fundamental definitions.

@h Build identity.
First we define the build, using a notation which tangles out to the current
build number as specified in the contents section of this web.

@d INTOOL_NAME "linguistics-test"

@

@d LEXER_PROBLEM_HANDLER Basics::lexer_problem_handler

=
void Basics::lexer_problem_handler(int err, text_stream *problem_source_description, wchar_t *word) {
	if (err == MEMORY_OUT_LEXERERROR)
		Errors::fatal("Out of memory: unable to create lexer workspace");
	TEMPORARY_TEXT(word_t);
	if (word) WRITE_TO(word_t, "%w", word);
	switch (err) {
		case STRING_TOO_LONG_LEXERERROR:
			Errors::with_text("Too much text in quotation marks: %S", word_t);
            break;
		case WORD_TOO_LONG_LEXERERROR:
			Errors::with_text("Word too long: %S", word_t);
			break;
		case I6_TOO_LONG_LEXERERROR:
			Errors::with_text("I6 inclusion too long: %S", word_t);
			break;
		case STRING_NEVER_ENDS_LEXERERROR:
			Errors::with_text("Quoted text never ends: %S", problem_source_description);
			break;
		case COMMENT_NEVER_ENDS_LEXERERROR:
			Errors::with_text("Square-bracketed text never ends: %S", problem_source_description);
			break;
		case I6_NEVER_ENDS_LEXERERROR:
			Errors::with_text("I6 inclusion text never ends: %S", problem_source_description);
			break;
		default:
			internal_error("unknown lexer error");
    }
	DISCARD_TEXT(word_t);
}

@

@d SYNTAX_PROBLEM_HANDLER Basics::syntax_problem_handler

=
void Basics::syntax_problem_handler(int err_no, wording W, void *ref, int k) {
	TEMPORARY_TEXT(text);
	WRITE_TO(text, "%+W", W);
	switch (err_no) {
		case UnexpectedSemicolon_SYNERROR:
			Errors::with_text("unexpected semicolon in sentence: %S", text);
			break;
		case ParaEndsInColon_SYNERROR:
			Errors::with_text("paragraph ends with a colon: %S", text);
			break;
		case SentenceEndsInColon_SYNERROR:
			Errors::with_text("paragraph ends with a colon and full stop: %S", text);
			break;
		case SentenceEndsInSemicolon_SYNERROR:
			Errors::with_text("paragraph ends with a semicolon and full stop: %S", text);
			break;
		case SemicolonAfterColon_SYNERROR:
			Errors::with_text("paragraph ends with a colon and semicolon: %S", text);
			break;
		case SemicolonAfterStop_SYNERROR:
			Errors::with_text("paragraph ends with a full stop and semicolon: %S", text);
			break;
		case ExtNoBeginsHere_SYNERROR:
			Errors::nowhere("extension has no beginning");
			break;
		case ExtNoEndsHere_SYNERROR:
			Errors::nowhere("extension has no end");
			break;
		case ExtSpuriouslyContinues_SYNERROR:
			Errors::with_text("extension continues after end: %S", text);
			break;
		case HeadingOverLine_SYNERROR:
			Errors::with_text("heading contains a line break: %S", text);
			break;
		case HeadingStopsBeforeEndOfLine_SYNERROR:
			Errors::with_text("heading stops before end of line: %S", text);
			break;
	}
	DISCARD_TEXT(text);
}

@

@d LINGUISTICS_PROBLEM_HANDLER Basics::linguistics_problem_handler

=
void Basics::linguistics_problem_handler(int err_no, wording W, void *ref, int k) {
	TEMPORARY_TEXT(text);
	WRITE_TO(text, "%+W", W);
	switch (err_no) {
		case TooLongName_LINERROR:
			Errors::nowhere("noun too long");
			break;
	}
	DISCARD_TEXT(text);
}

@

@d PREFORM_LANGUAGE_TYPE void
@d PREFORM_ADAPTIVE_PERSON Basics::person
@d EXTENSION_FILE_TYPE void

=
int Basics::person(void *X) {
	return FIRST_PERSON_PLURAL;
}

@ =

@h Preform error handling.

@d PREFORM_ERROR_HANDLER Basics::preform_problem_handler

=
void Basics::preform_problem_handler(word_assemblage base_text, nonterminal *nt,
	production *pr, char *message) {
	if (pr) {
		LOG("The production at fault is:\n");
		Preform::log_production(pr, FALSE); LOG("\n");
	}
	TEMPORARY_TEXT(ERM);
	if (nt == NULL)
		WRITE_TO(ERM, "(no nonterminal)");
	else
		WRITE_TO(ERM, "nonterminal %w", Vocabulary::get_exemplar(nt->nonterminal_id, FALSE));
	WRITE_TO(ERM, ": ");

	if (WordAssemblages::nonempty(base_text))
		WRITE_TO(ERM, "can't conjugate verb '%A': ", &base_text);

	if (pr) {
		TEMPORARY_TEXT(TEMP);
		for (ptoken *pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
			Preform::write_ptoken(TEMP, pt);
			if (pt->next_ptoken) WRITE_TO(TEMP, " ");
		}
		WRITE_TO(ERM, "line %d ('%S'): ", pr->match_number, TEMP);
		DISCARD_TEXT(TEMP);
	}
	WRITE_TO(ERM, "%s", message);
	Errors::with_text("Preform error: %S", ERM);
	DISCARD_TEXT(ERM);
}

@

@d PARSE_TREE_TRAVERSE_TYPE void
@d SENTENCE_NODE Basics::sentence_level

=
int Basics::sentence_level(node_type_t t) {
	return FALSE;
}

@

@d ADJECTIVE_MEANING_TYPE void
@d VERB_MEANING_EQUALITY vc_be
@d VERB_MEANING_POSSESSION vc_have
@d VERB_MEANING_TYPE struct verb_conjugation
@d VERB_MEANING_REVERSAL Basics::dummy

=
void *Basics::dummy(void *X) {
	return X;
}

@

@d ONE_WEIRD_TRICK_MC			0x00000004

@d EXACT_PARSING_BITMAP
	(MISCELLANEOUS_MC)
@d SUBSET_PARSING_BITMAP
	(NOUN_MC)
@d PARAMETRISED_PARSING_BITMAP
	(ONE_WEIRD_TRICK_MC)
