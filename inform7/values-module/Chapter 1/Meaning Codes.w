[MeaningCodes::] Meaning Codes.

The set of meaning codes used when Inform runs the excerpt parser.

@ See //lexicon: Excerpt Meanings// for more, but briefly: the //lexicon//
module provides a parser for "excerpts" of natural language text. The user
of that module is supposed to provide bitmap-friendly codes which categorise
the various meanings likely to be given. Several modules do this, but this
is where the Inform compiler-specific codes appear.

@d VOID_PHRASE_MC			0x00000010 /* e.g., |award # points| */
@d VALUE_PHRASE_MC			0x00000020 /* e.g., |number of rows in #| */
@d COND_PHRASE_MC			0x00000040 /* e.g., |# has not ended| */
@d PROPERTY_MC				0x00000080 /* e.g., |carrying capacity| */
@d NAMED_CONSTANT_MC		0x00000100 /* e.g., |green| */
@d TABLE_MC					0x00000200 /* e.g., |table of rankings| */
@d TABLE_COLUMN_MC			0x00000400 /* e.g., |rank| */
@d RULE_MC					0x00000800 /* e.g., |update chronological records rule| */
@d RULEBOOK_MC				0x00001000 /* e.g., |instead| */
@d ACTIVITY_MC				0x00002000 /* e.g., |reading a command| */
@d EQUATION_MC				0x00004000 /* e.g., |Newton's Second Law| */
@d VARIABLE_MC				0x00008000 /* e.g., |left hand status line| */
@d NAMED_AP_MC				0x00010000 /* e.g., |bad behaviour| */
@d SAY_PHRASE_MC			0x00020000 /* e.g., |say # in words| */
@d PHRASE_CONSTANT_MC		0x00040000 /* e.g., |doubling function| */

@ This one is used only by the //if// module, but let's define it here anyway:

@d ACTION_PARTICIPLE_MC		0x02000000 /* a word like "taking" */

@ We use callback functions to tell //lexicon// any special rules for
parsing excerpts with these codes:

@d EM_CASE_SENSITIVITY_TEST_LEXICON_CALLBACK MeaningCodes::case_sensitivity
@d EM_ALLOW_BLANK_TEST_LEXICON_CALLBACK MeaningCodes::allow_blank
@d EM_IGNORE_DEFINITE_ARTICLE_TEST_LEXICON_CALLBACK MeaningCodes::ignore_definite_article

=
int MeaningCodes::case_sensitivity(unsigned int mc) {
	if (mc == SAY_PHRASE_MC) return TRUE;
	return FALSE;
}

int MeaningCodes::allow_blank(unsigned int mc) {
	if (mc == SAY_PHRASE_MC) return TRUE;
	return FALSE;
}

int MeaningCodes::ignore_definite_article(unsigned int mc) {
	if ((mc & SAY_PHRASE_MC) == 0) return TRUE;
	return FALSE;
}

@ We decide which form of parsing to use with the following bitmaps:

@d EXACT_PARSING_BITMAP
	(MISCELLANEOUS_MC + PROPERTY_MC + ADJECTIVE_MC +
	NAMED_CONSTANT_MC + VARIABLE_MC + KIND_SLOW_MC + RULE_MC + RULEBOOK_MC +
	TABLE_MC + TABLE_COLUMN_MC + NAMED_AP_MC + ACTIVITY_MC + EQUATION_MC +
	PHRASE_CONSTANT_MC)
@d SUBSET_PARSING_BITMAP
	(NOUN_MC)
@d PARAMETRISED_PARSING_BITMAP
	(VOID_PHRASE_MC + VALUE_PHRASE_MC + COND_PHRASE_MC + SAY_PHRASE_MC)

@ The //lexicon// module is generally quite uncomplaining, but:

@d PROBLEM_LEXICON_CALLBACK MeaningCodes::linguistics_problem_handler

=
void MeaningCodes::linguistics_problem_handler(int err_no, wording W, void *ref, int k) {
	switch (err_no) {
		case TooLongName_LEXICONERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooLongName),
				"that seems to involve far too long a name",
				"since in general names are limited to a maximum of 32 words.");
			break;
		default: internal_error("unimplemented problem message");
	}
}

@ Here we log a general bitmap made up from meaning codes:

@d LOG_UNENUMERATED_NODE_TYPES_SYNTAX_CALLBACK MeaningCodes::log_meaning_code

=
void MeaningCodes::log_meaning_code(OUTPUT_STREAM, unsigned int mc) {
	int i, f = FALSE;
	unsigned int j;
	for (i=0, j=1; i<31; i++, j*=2)
		if (mc & j) {
			if (f) LOG(" + "); f = TRUE;
			switch (j) {
				case ACTION_PARTICIPLE_MC: WRITE("ACTION_PARTICIPLE_MC"); break;
				case ACTIVITY_MC: WRITE("ACTIVITY_MC"); break;
				case ADJECTIVE_MC: WRITE("ADJECTIVE_MC"); break;
				case COND_PHRASE_MC: WRITE("COND_PHRASE_MC"); break;
				case EQUATION_MC: WRITE("EQUATION_MC"); break;
				case I6_MC: WRITE("I6_MC"); break;
				case ING_MC: WRITE("ING_MC"); break;
				case KIND_FAST_MC: WRITE("KIND_FAST_MC"); break;
				case KIND_SLOW_MC: WRITE("KIND_SLOW_MC"); break;
				case MISCELLANEOUS_MC: WRITE("MISCELLANEOUS_MC"); break;
				case NAMED_AP_MC: WRITE("NAMED_AP_MC"); break;
				case NAMED_CONSTANT_MC: WRITE("NAMED_CONSTANT_MC"); break;
				case NOUN_MC: WRITE("NOUN_MC"); break;
				case NUMBER_MC: WRITE("NUMBER_MC"); break;
				case ORDINAL_MC: WRITE("ORDINAL_MC"); break;
				case PHRASE_CONSTANT_MC: WRITE("PHRASE_CONSTANT_MC"); break;
				case PREPOSITION_MC: WRITE("PREPOSITION_MC"); break;
				case PROPERTY_MC: WRITE("PROPERTY_MC"); break;
				case RULE_MC: WRITE("RULE_MC"); break;
				case RULEBOOK_MC: WRITE("RULEBOOK_MC"); break;
				case SAY_PHRASE_MC: WRITE("SAY_PHRASE_MC"); break;
				case TABLE_COLUMN_MC: WRITE("TABLE_COLUMN_MC"); break;
				case TABLE_MC: WRITE("TABLE_MC"); break;
				case TEXT_MC: WRITE("TEXT_MC"); break;
				case TEXTWITHSUBS_MC: WRITE("TEXTWITHSUBS_MC"); break;
				case VALUE_PHRASE_MC: WRITE("VALUE_PHRASE_MC"); break;
				case VARIABLE_MC: WRITE("VARIABLE_MC"); break;
				case VOID_PHRASE_MC: WRITE("VOID_PHRASE_MC"); break;
				default: WRITE("<unknown-mc>"); break;
			}
		}
}
