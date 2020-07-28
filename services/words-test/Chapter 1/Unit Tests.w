[Unit::] Unit Tests.

How we shall test it.

@h Lexer.

@d SPOTTED_MC 0x00010000

=
void Unit::test_lexer(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		PRINT("File contained %d lexer words\nWord counted at %d\n",
			Wordings::length(sf->text_read), sf->words_of_source);
		int c = 0;
		LOOP_THROUGH_WORDING(wn, sf->text_read) {
			vocabulary_entry *ve = Lexer::word(wn);
			if ((ve) && (Vocabulary::test_vflags(ve, SPOTTED_MC) == 0)) {
				PRINT("%w ", ve->exemplar);
				Vocabulary::set_flags(ve, SPOTTED_MC);
				c++;
			}
		}
		PRINT("\n");
		PRINT("File contained %d distinct words\n", c);
	}
}

@h Preform.

=
<text> ::=
	invade ... |              ==> { TRUE, - }; PRINT("Invading %+W\n", GET_RW(<text>, 1));
	proclaim <any-integer> |  ==> { TRUE, - }; PRINT("It is now %d.\n", R[1]);
	announce <quoted-text> |  ==> { TRUE, - }; PRINT("Attention: %w.\n", Lexer::word_text(R[1]));
	<declaration> |           ==> { TRUE, - }; PRINT("Dominion %d now independent\n", R[1]);
	...                       ==> { FALSE, - }; PRINT("Unknown command\n");

<declaration> ::=
	declare <dominion> independent	==>	{ pass 1 }

<dominion> ::=
	canada |
	india |
	malaya

@ =
void Unit::test_preform(text_stream *arg) {
	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"words-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, I"Syntax.preform");
	LoadPreform::load(S, NULL);

	filename *F = Filenames::from_text(arg);
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	if (sf == NULL) PRINT("File has failed to open\n");
	else {
		LOOP_THROUGH_WORDING(i, sf->text_read) {
			if (Lexer::word(i) == PARBREAK_V) continue;
			int j = i;
			while ((j <= Wordings::last_wn(sf->text_read))
				&& (Lexer::word(j) != PARBREAK_V)) j++;
			wording W = Wordings::new(i, j-1);
			i = j-1;
			PRINT("command: %W: ", W);
			if (<text>(W) == FALSE) PRINT("Failed Preform\n");
		}
	}
}
