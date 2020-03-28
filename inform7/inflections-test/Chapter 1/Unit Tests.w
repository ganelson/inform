[Unit::] Unit Tests.

How we shall test it.

@h Adjectives.

=
void Unit::test_adjectives(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		LOOP_THROUGH_WORDING(i, sf->text_read) {
			if (Lexer::word(i) == PARBREAK_V) continue;
			wording W = Wordings::one_word(i);
			PRINT("%W --> ", W);
			PRINT("comparative: %W, ", Grading::make_comparative(W, English_language));
			PRINT("superlative: %W, ", Grading::make_superlative(W, English_language));
			PRINT("quiddity: %W\n", Grading::make_quiddity(W, English_language));
		}
	}
}

@h Articles.

=
void Unit::test_articles(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		LOOP_THROUGH_WORDING(i, sf->text_read) {
			if (Lexer::word(i) == PARBREAK_V) continue;
			wording W = Wordings::one_word(i);
			TEMPORARY_TEXT(T);
			WRITE_TO(T, "%W", W);
			TEMPORARY_TEXT(AT);
			ArticleInflection::preface_by_article(AT, T, English_language);
			PRINT("%S --> %S\n", T, AT);
			DISCARD_TEXT(AT);
			DISCARD_TEXT(T);
		}
	}
}

@h Declensions.

=
void Unit::test_declensions(text_stream *arg) {
	vocabulary_entry *m_V = Vocabulary::entry_for_text(L"m");
	vocabulary_entry *f_V = Vocabulary::entry_for_text(L"f");
	vocabulary_entry *n_V = Vocabulary::entry_for_text(L"n");
	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		wording PW = Feeds::feed_stream(I"der");
		int gen = NEUTER_GENDER;
		LOOP_THROUGH_WORDING(i, sf->text_read) {
			if (Lexer::word(i) == PARBREAK_V) continue;
			if (Lexer::word(i) == m_V) { gen = MASCULINE_GENDER; continue; }
			if (Lexer::word(i) == f_V) { gen = FEMININE_GENDER; continue; }
			if (Lexer::word(i) == n_V) { gen = NEUTER_GENDER; continue; }
			wording W = Wordings::one_word(i);
			declension D = Declensions::decline(W, English_language, gen, 1);
			declension AD = Declensions::decline_article(PW, English_language, gen, 1);
			PRINT("%W --> ", W);
			Declensions::writer(STDOUT, &D, &AD);
			D = Declensions::decline(W, English_language, gen, 2);
			AD = Declensions::decline_article(PW, English_language, gen, 2);
			PRINT("pl --> ");
			Declensions::writer(STDOUT, &D, &AD);
			PRINT("\n");
		}
	}
}

@h Participles.

=
void Unit::test_participles(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		LOOP_THROUGH_WORDING(i, sf->text_read) {
			if (Lexer::word(i) == PARBREAK_V) continue;
			wording W = Wordings::one_word(i);
			PRINT("%W --> %W\n", W, PastParticiples::pasturise_wording(W));
		}
	}
}

@h Plurals.
(ASAGIG stands for "as sure as geese is geese".)

=
void Unit::test_plurals(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		LOOP_THROUGH_WORDING(i, sf->text_read) {
			if (Lexer::word(i) == PARBREAK_V) continue;
			wording W = Wordings::one_word(i);
			TEMPORARY_TEXT(G);
			WRITE_TO(G, "%W", W);
			TEMPORARY_TEXT(ASAGIG);
			Pluralisation::regular(ASAGIG, G, English_language);
			PRINT("%S --> %S\n", G, ASAGIG);
			DISCARD_TEXT(ASAGIG);
			DISCARD_TEXT(G);
		}
	}
}

@h Verbs.

=
void Unit::test_verbs(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		int c = 0;
		LOOP_THROUGH_WORDING(i, sf->text_read) {
			if (Lexer::word(i) == PARBREAK_V) continue;
			wording W = Wordings::one_word(i);
			if (c++ < 10) {
				PRINT("Verb %W -->\n", W);
				TEMPORARY_TEXT(T);
				Conjugation::test(T, W, English_language);
				Regexp::replace(T, L"%^", L"\n", REP_REPEATING);
				PRINT("%S\n", T);
				DISCARD_TEXT(T);
			} else {
				Conjugation::test_participle(STDOUT, W);
			}
		}
	}
}
