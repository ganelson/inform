[FromLexicon::] Parse Excerpts.

Given an excerpt of wording, to construct S-nodes for one or more
registered excerpt meanings which it matches.

@h Default bitmaps.
The following will be useful only for minimal use of //lexicon//. Inform
certainly doesn't use settings as minimal as these -- see
//values: Meaning Codes// for what it does do.

@d ONE_WEIRD_TRICK_DISCOVERED_BY_A_MOM_MC 0x00000004 /* meaningless, so do not use */

@default EXACT_PARSING_BITMAP
	(MISCELLANEOUS_MC)
@default SUBSET_PARSING_BITMAP
	(NOUN_MC)
@default PARAMETRISED_PARSING_BITMAP
	(ONE_WEIRD_TRICK_DISCOVERED_BY_A_MOM_MC)

@h Parsing methods.
The excerpt parser tests a given wording to see if it matches something
in the bank of excerpt meanings. It looks only for atomic meanings ("box"):
more sophisticated grammar higher up will have to parse compound meanings
(such as "something in an open box").

We will return either a single result or a list of possible results, as
alternative readings. It is not at all easy to decide what "door"
means, for instance: the class of doors, or a particular door, and if so
then which one? We cannot answer that question here, and do not even try.
However, we can specify a context, in effect saying something like "what
would this mean if it had to be an adjective name?".

Depending on that context, four basic parsing modes can then be used.
(1) Exact parsing is what it sounds like: the texts have to match exactly,
except that an initial article is skipped. Thus "the going action"
exactly matches "going action", but "going" does not.
(2) In subset parsing, a match is achieved if the text parsed consists of
words all of which are found in the meaning tested. Thus "red door" and
"red" are each subset matches for "ornate red door with brass handle".
(3) In parametrised parsing, arbitrary (non-empty) text is allowed to
match against |#| gaps in the token list. Thus "award 5 points" is a
parametrised match for "award |#| points".
(4) In maximal parsing, we find the longest possible initial match, allowing
it even if it does reach to the end of the excerpt, and we return a unique
finding, not a list of possibilities.

@d EXACT_PM 1
@d SUBSET_PM 2
@d PARAMETRISED_PM 4
@d MAXIMAL_PM 8

@ To monitor the efficiency of the excerpt parser, we keep track of:

=
int no_calls_to_parse_excerpt = 0,
	no_meanings_tried = 0,
	no_meanings_tried_in_detail = 0,
	no_successful_calls_to_parse_excerpt = 0, no_matched_ems = 0;

@ In addition, it turns out to be convenient to have a global mode, for the
sake of disambiguating awkward cases:

=
vocabulary_entry *word_to_suppress_in_phrases = NULL;

@ As input, we supply not just the excerpt but also a context; or, to put it
another way, a filter on which excerpt meanings to look at. This must be a
bitmap made up from meaning codes, such as |TABLE_MC + TABLE_COLUMN_MC|,
which would check for tables and table columns simultaneously.

However, there is one restriction on this. Recall that there are four
parsing modes, and that different modes are used for different meaning
codes. The |mc_bitmap| context is required not to mix MCs with different
parsing modes.

=
parse_node *FromLexicon::parse(unsigned int mc_bitmap, wording W) {
	parse_node *results = NULL;

	no_calls_to_parse_excerpt++;

	if (Wordings::empty(W)) return NULL;
	while (Wordings::paired_brackets(W)) W = Wordings::trim_both_ends(W);
	if (Wordings::empty(W)) return NULL;

	int parsing_mode = 0, hash = 0;

	@<Choose which parsing mode we should use, given the MC bitmap@>;
	@<Take note of casing on first word, in the few circumstances when we care@>;
	@<Skip an initial article most of the time@>;

	hash = hash | ExcerptMeanings::hash_code(W);

	LOGIF(EXCERPT_PARSING,
		"Parsing excerpt <%W> hash %08x mc $N mode %d\n", W, hash, mc_bitmap, parsing_mode);

	switch(parsing_mode) {
		case EXACT_PM: @<Enter exact parsing mode@>; break;
		case MAXIMAL_PM: @<Enter maximal parsing mode@>; break;
		case PARAMETRISED_PM: @<Enter parametrised parsing mode@>; break;
		case SUBSET_PM: @<Enter subset parsing mode@>; break;
		case 0: LOG("mc_bitmap: $N\n", mc_bitmap);
			internal_error("Unknown parsing mode");
		default: LOG("pm: %08x mc_bitmap: $N\n", parsing_mode, mc_bitmap);
			internal_error("Mixed parsing modes");
	}

	LOGIF(EXCERPT_PARSING, "Completed:\n$m", results);
	if (results) {
		for (parse_node *loopy = results; loopy; loopy = loopy->next_alternative)
			no_matched_ems++;
		no_successful_calls_to_parse_excerpt++;
	}
	return results;
}

@ Maximal parsing is something of a special case: it is used only for adjective
lists, and we can only enter that mode by calling with exactly the correct
bitmap for this. Otherwise, the parsing mode depends on which MC(s) are
included in the bitmap.

@<Choose which parsing mode we should use, given the MC bitmap@> =
	parsing_mode = 0;
	if (mc_bitmap & EXACT_PARSING_BITMAP) parsing_mode |= EXACT_PM;
	if (mc_bitmap & SUBSET_PARSING_BITMAP) parsing_mode |= SUBSET_PM;
	if (mc_bitmap & PARAMETRISED_PARSING_BITMAP) parsing_mode |= PARAMETRISED_PM;
	if (lexicon_in_maximal_mode) parsing_mode = MAXIMAL_PM;

@ Recall that excerpt parsing is case insensitive except for the first word
of a text substitution, and then only when two definitions have been given,
one capitalising the word and the other not, or when the word is a single
letter long.

If we find the upper case form of such a text substitution, we set a special
bit in the hash code. (The upper and lower case forms are both registered as
excerpt meanings, with the same hash code except that one has this extra bit
set and the other hasn't.)

@<Take note of casing on first word, in the few circumstances when we care@> =
	#ifdef EM_CASE_SENSITIVITY_TEST_LEXICON_CALLBACK
	if (EM_CASE_SENSITIVITY_TEST_LEXICON_CALLBACK(mc_bitmap)) {
		wchar_t *tx = Lexer::word_raw_text(Wordings::first_wn(W));
		if ((tx[0]) && (Characters::isupper(tx[0])) &&
			((tx[1] == 0) ||
				(Vocabulary::used_case_sensitively(Lexer::word(Wordings::first_wn(W)))))) {
			hash = hash | CAPITALISED_VARIANT_FORM;
		}
	}
	#endif

@ An initial article is always skipped unless we are looking at a phrase;
but then we are only allowed to skip an initial "the", and even then only
if we aren't looking for text substitutions.

@<Skip an initial article most of the time@> =
	if (parsing_mode & PARAMETRISED_PM) {
		#ifdef EM_IGNORE_DEFINITE_ARTICLE_TEST_LEXICON_CALLBACK
		if (EM_IGNORE_DEFINITE_ARTICLE_TEST_LEXICON_CALLBACK(mc_bitmap))
		#endif
			W = Articles::remove_the(W);
	} else {
		W = Articles::remove_article(W);
	}

@ When checking cases below, we are always going to consider only those
which have a meaning code among those we are looking for:

@d EXCERPT_MEANING_RELEVANT(p)
	(no_meanings_tried++, ((mc_bitmap & (Node::get_meaning(p)->meaning_code))!=0))

@d EXAMINE_EXCERPT_MEANING_IN_DETAIL
	LOGIF(EXCERPT_PARSING,
		"Trying $M (parsing mode %d)\n", Node::get_meaning(p), parsing_mode);
	no_meanings_tried_in_detail++;

@h Exact parsing mode.
Exact matching is just what it sounds like: the match must be word
for word. Because of that, the excerpt meaning is guaranteed to be listed
under the start list of the first word, if it matches (because there cannot
be |#| tokens in the token list -- if there were, we would be in parametrised
parsing mode).

@<Enter exact parsing mode@> =
	parse_node *p;
	vocabulary_entry *v = Lexer::word(Wordings::first_wn(W));
	if (v == NULL) internal_error("Unidentified word when parsing");
	if ((v->flags) & mc_bitmap)
		for (p = v->means.start_list; p; p = p->next_alternative)
			@<Try to match excerpt in exact parsing mode@>;

@ In exact parsing, the hash codes must agree perfectly:

@<Try to match excerpt in exact parsing mode@> =
	if (EXCERPT_MEANING_RELEVANT(p) && (hash == Node::get_meaning(p)->excerpt_hash)) {
		EXAMINE_EXCERPT_MEANING_IN_DETAIL;
		if (Node::get_meaning(p)->no_em_tokens == Wordings::length(W)) {
			int j, k, err;
			for (j=0, k=Wordings::first_wn(W), err = FALSE;
				j<Node::get_meaning(p)->no_em_tokens; j++, k++)
				if (Node::get_meaning(p)->em_tokens[j] != Lexer::word(k)) { err=TRUE; break; }
			if (err == FALSE)
				results = FromLexicon::result(Node::get_meaning(p), 1, results);
		}
	}

@h Maximal parsing mode.

@<Enter maximal parsing mode@> =
	vocabulary_entry *v = Lexer::word(Wordings::first_wn(W));
	if (v == NULL) internal_error("Unidentified word when parsing");
	if ((v->flags) & mc_bitmap) {
		parse_node *p, *best_p = NULL; int best_score = 0;
		for (p = v->means.start_list; p; p = p->next_alternative)
			@<Try to match excerpt in maximal parsing mode@>;
		if (best_p)
			results =
				FromLexicon::result(
					Node::get_meaning(best_p), best_score, results);
	}

@ In maximal matching, we keep only the longest exact match found, and
if two have equal length then keep the first one found. (It should ideally
never be the case that clashes occur.)

@<Try to match excerpt in maximal parsing mode@> =
	if (EXCERPT_MEANING_RELEVANT(p) &&
		((hash & Node::get_meaning(p)->excerpt_hash) == Node::get_meaning(p)->excerpt_hash)) {
		EXAMINE_EXCERPT_MEANING_IN_DETAIL;
		if (Node::get_meaning(p)->no_em_tokens <= Wordings::length(W)) {
			int j, k, err;
			for (err=FALSE, j=0, k=Wordings::first_wn(W);
				j<Node::get_meaning(p)->no_em_tokens;
				j++, k++)
				if (Node::get_meaning(p)->em_tokens[j] != Lexer::word(k)) { err = TRUE; break; }
			if ((err == FALSE) && (j>best_score)) {
				best_p = p; best_score = j;
			}
		}
	}

@h Parametrised parsing mode.
This is the only parsing mode which allows for arbitrary text to appear:
i.e., where any text X can appear in "award X points", for example.

@<Enter parametrised parsing mode@> =
	vocabulary_entry *v = Lexer::word(Wordings::first_wn(W));
	if (v == NULL) internal_error("Unidentified word when parsing");
	parse_node *p;
	#ifdef EM_ALLOW_BLANK_TEST_LEXICON_CALLBACK
	if (EM_ALLOW_BLANK_TEST_LEXICON_CALLBACK(mc_bitmap)) {
		for (p = blank_says_p; p; p = p->next_alternative) {
			parse_node *this_result =
				Node::new_with_words(mc_bitmap, W);
			wording SW = Node::get_text(this_result);
			Node::copy(this_result, p);
			Node::set_text(this_result, SW);
			this_result->down = Node::new_with_words(UNKNOWN_NT, W);
			this_result->next_alternative = results;
			results = this_result;
			no_meanings_tried++, no_meanings_tried_in_detail++;
		}
	}
	#endif
	for (p = v->means.start_list; p; p = p->next_alternative)
		@<Try to match excerpt in parametrised parsing mode@>;
	if (Wordings::length(W) > 1) {
		v = Lexer::word(Wordings::last_wn(W));
		if (v == NULL) internal_error("Unidentified word when parsing");
		for (p = v->means.end_list; p; p = p->next_alternative)
			@<Try to match excerpt in parametrised parsing mode@>;
	}
	LOOP_THROUGH_WORDING(i, W)
		if (i > Wordings::first_wn(W)) {
			v = Lexer::word(i);
			if (v == NULL) internal_error("Unidentified word when parsing");
			for (p = v->means.middle_list; p; p = p->next_alternative)
				@<Try to match excerpt in parametrised parsing mode@>;
		}

@ It is required here that the data supplied must be a pointer to a phrase,
though it can be any type of phrase.

@<Try to match excerpt in parametrised parsing mode@> =
	int eh = Node::get_meaning(p)->excerpt_hash;
	if (EXCERPT_MEANING_RELEVANT(p) &&
		((hash & eh) == eh) &&
		((Node::get_meaning(p)->em_tokens[0] == 0) ||
			((hash & CAPITALISED_VARIANT_FORM) == (eh & CAPITALISED_VARIANT_FORM)))) {
		int no_tokens_to_match = Node::get_meaning(p)->no_em_tokens;
		wording saved_W = W;
		wording params_W[MAX_TOKENS_PER_EXCERPT_MEANING];
		#ifdef CORE_MODULE
		wording ph_opt_W = EMPTY_WORDING;
		#endif
		int bl; /* the "bracket level" (0 for unbracketed, 1 for inside one pair, etc.) */
		int j, scan_pos, t, err;
		EXAMINE_EXCERPT_MEANING_IN_DETAIL;

		@<Look through to see if there are phrase options at the end@>;
		for (err=FALSE, j=0, scan_pos=Wordings::first_wn(W), t=0, bl=0;
			(j<no_tokens_to_match) && (scan_pos<=Wordings::last_wn(W)); j++) {
			LOGIF(EXCERPT_PARSING, "j=%d, scan_pos=%d, t=%d\n", j, scan_pos, t);
			vocabulary_entry *this_word = Node::get_meaning(p)->em_tokens[j];
			if (this_word) @<We're required to match a fixed word@>
			else if (j == no_tokens_to_match-1)
				@<We're required to match a parameter at the excerpt's end@>
			else
				@<We're required to match a parameter before the excerpt's end@>;
		}
		LOGIF(EXCERPT_PARSING, "outcome has err=%d (hash here %08x)\n",
			err, Node::get_meaning(p)->excerpt_hash);
		@<Check the matched parameters for sanity@>;
		if (err == FALSE) @<Record a successful parametrised match@>;
		W = saved_W;
	}

@<Look through to see if there are phrase options at the end@> =
	#ifdef CORE_MODULE
	phrase *ph = ToPhraseFamily::meaning_as_phrase(Node::get_meaning(p));
	if (ToPhraseFamily::allows_options(ph)) {
		LOGIF(EXCERPT_PARSING, "Looking for phrase options\n");
		for (bl=0, scan_pos=Wordings::first_wn(W)+1;
			scan_pos<Wordings::last_wn(W); scan_pos++) {
			if ((Lexer::word(scan_pos) == COMMA_V) && (bl==0)) {
				ph_opt_W = Wordings::from(W, scan_pos+1);
				W = Wordings::up_to(W, scan_pos-1);
				LOGIF(EXCERPT_PARSING, "Found phrase options <%W>\n", ph_opt_W);
				break;
			}
			@<Maintain bracket level@>;
		}
	}
	#endif

@<We're required to match a fixed word@> =
	if (this_word != Lexer::word(scan_pos)) { err=TRUE; break; }
	if (this_word == word_to_suppress_in_phrases) { err=TRUE; break; }
	scan_pos++;

@<We're required to match a parameter at the excerpt's end@> =
	params_W[t++] = Wordings::from(W, scan_pos);
	scan_pos = Wordings::last_wn(W) + 1;

@<We're required to match a parameter before the excerpt's end@> =
	int fixed_words_at_end = 0;
	for (; j+1+fixed_words_at_end < no_tokens_to_match; fixed_words_at_end++)
		if (Node::get_meaning(p)->em_tokens[j+1+fixed_words_at_end] == NULL) {
			fixed_words_at_end = 0; break;
		}

	if (fixed_words_at_end > 0) {
		params_W[t++] =
			Wordings::new(scan_pos, Wordings::last_wn(W) - fixed_words_at_end);
		scan_pos = Wordings::last_wn(W) - fixed_words_at_end + 1;
	} else {
		vocabulary_entry *sentinel = Node::get_meaning(p)->em_tokens[j+1];
		int bl_initial = bl;
		int start_word = scan_pos;
		err = TRUE;
		while (scan_pos <= Wordings::last_wn(W)) {
			@<Maintain bracket level@>;
			if ((bl == bl_initial) && (scan_pos > start_word) &&
				(sentinel == Lexer::word(scan_pos))) { err = FALSE; break; }
			if (bl < bl_initial) break;
			scan_pos++;
		}
		params_W[t++] = Wordings::new(start_word, scan_pos-1);
	}

@<Check the matched parameters for sanity@> =
	int x;
	if (j<no_tokens_to_match) err = TRUE;
	if (scan_pos <= Wordings::last_wn(W)) err = TRUE;
	if (err == FALSE)
		for (x=0; x<t; x++) {
			if (Wordings::empty(params_W[x])) err = TRUE;
			else {
				int bl = 0;
				LOOP_THROUGH_WORDING(scan_pos, params_W[x]) {
					@<Maintain bracket level@>;
					if (bl < 0) err = TRUE;
				}
				if (bl != 0) err = TRUE;
			}
		}

@ Monitor bracket level:

@<Maintain bracket level@> =
	if ((Lexer::word(scan_pos) == OPENBRACKET_V) ||
		(Lexer::word(scan_pos) == OPENBRACE_V)) bl++;
	if ((Lexer::word(scan_pos) == CLOSEBRACKET_V) ||
		(Lexer::word(scan_pos) == CLOSEBRACE_V)) bl--;

@ A happy ending. We add the result to our linked list, annotating it with
nodes for the parameters and any phrase options.

@<Record a successful parametrised match@> =
	parse_node *last_param = NULL;
	parse_node *this_result =
		Node::new_with_words(Node::get_meaning(p)->meaning_code, W);
	Node::set_meaning(this_result, Node::get_meaning(p));
	this_result->next_alternative = results;
	Node::set_score(this_result, 1);
	#ifdef CORE_MODULE
	if (Wordings::nonempty(ph_opt_W)) {
		this_result->down = Node::new_with_words(UNKNOWN_NT, ph_opt_W);
		Annotations::write_int(this_result->down, is_phrase_option_ANNOT, TRUE);
		last_param = this_result->down;
	}
	#endif
	for (int x=0; x<t; x++) {
		parse_node *p2;
		p2 = Node::new_with_words(UNKNOWN_NT, params_W[x]);
		if (last_param) last_param->next = p2;
		else this_result->down = p2;
		last_param = p2;
	}
	results = this_result;

@h Subset parsing mode.
In subset mode, each possible match is kept, and is assigned a numerical
score based purely on the number of words in the full description which were
missed out. This makes "door" a better match against "door" (0 words
missed out) than against "green door" (1 word missed out).

Note that a single word which also has a meaning as a number is never
matched. This is so that "11" (say) cannot be misinterpreted as an
abbreviated form of an object name like "Chamber 11".

@<Enter subset parsing mode@> =
	if ((Wordings::length(W) == 1) &&
		((Vocabulary::test_flags(Wordings::first_wn(W), NUMBER_MC)) != 0))
		goto SubsetFailed;
	int j = -1, k = -1;
	LOOP_THROUGH_WORDING(i, W) {
		vocabulary_entry *v = Lexer::word(i);
		if (v == NULL) internal_error("Unidentified word when parsing");
		if (NTI::test_vocabulary(v, <article>)) continue;
		if (v->means.subset_list_length == 0) goto SubsetFailed;
		if (v->means.subset_list_length > j) { j = v->means.subset_list_length; k = i; }
	}
	if (k >= 0) {
		vocabulary_entry *v = Lexer::word(k);
		parse_node *p;
		for (p = v->means.subset_list; p; p = p->next_alternative)
			@<Try to match excerpt in subset parsing mode@>;
	}
	SubsetFailed: ;

@<Try to match excerpt in subset parsing mode@> =
	if (EXCERPT_MEANING_RELEVANT(p) &&
		((hash & Node::get_meaning(p)->excerpt_hash) == hash)) {
		EXAMINE_EXCERPT_MEANING_IN_DETAIL;
		if (Wordings::length(W) <= Node::get_meaning(p)->no_em_tokens) {
			int err = FALSE;
			if (FromLexicon::parse_exactly(Node::get_meaning(p))) {
				LOGIF(EXCERPT_PARSING,
					"Require exact matching of $M\n", Node::get_meaning(p));
				err = TRUE;
				if (Node::get_meaning(p)->no_em_tokens == Wordings::length(W)) {
					for (j=0, k=Wordings::first_wn(W), err = FALSE;
						j<Node::get_meaning(p)->no_em_tokens; j++, k++)
						if (Node::get_meaning(p)->em_tokens[j] != Lexer::word(k)) {
							err=TRUE; break;
						}
				}
				goto SubsetMatchDecided;
			}
			LOOP_THROUGH_WORDING(k, W) {
				err = TRUE;
				for (j=0; j<Node::get_meaning(p)->no_em_tokens; j++)
					if (Node::get_meaning(p)->em_tokens[j] == Lexer::word(k)) err=FALSE;
				if (err) break;
			}
			SubsetMatchDecided:
			if (err == FALSE) {
				excerpt_meaning *em = Node::get_meaning(p);
				results = FromLexicon::result(em,
					100-((em->no_em_tokens) - (Wordings::length(W)-1)),
					results);
			}
		}
	}

@ Inform uses the callback here simply to disallow inexact parsing of |NOUN_NT|
excerpts when the use option "unabbreviated object names" is set.

=
int FromLexicon::parse_exactly(excerpt_meaning *em) {
	#ifdef PARSE_EXACTLY_LEXICON_CALLBACK
	return PARSE_EXACTLY_LEXICON_CALLBACK(em);
	#endif
	#ifndef PARSE_EXACTLY_LEXICON_CALLBACK
	if (em->meaning_code == NOUN_MC) return FALSE;
	return TRUE;
	#endif
}

@ The following adds a result to the list already formed, and returns the list
as extended by one.

=
parse_node *FromLexicon::result(excerpt_meaning *em, int score, parse_node *list) {
	parse_node *this_result;
	#ifdef PN_FROM_EM_LEXICON_CALLBACK
	this_result = PN_FROM_EM_LEXICON_CALLBACK(em);
	#endif
	#ifndef PN_FROM_EM_LEXICON_CALLBACK
	if (VALID_POINTER_parse_node(Lexicon::get_data(em))) {
		parse_node *val = RETRIEVE_POINTER_parse_node(Lexicon::get_data(em));
		this_result = Node::new(INVALID_NT);
		Node::copy(this_result, val);
	} else {
		this_result = Node::new(em->meaning_code);
		Node::set_meaning(this_result, em);
	}
	#endif
	this_result->next_alternative = list;
	Node::set_score(this_result, score);
	return this_result;
}

parse_node *FromLexicon::retrieve_parse_node(excerpt_meaning *em) {
	if (em == NULL) return NULL;
	#ifdef PN_FROM_EM_LEXICON_CALLBACK
	return PN_FROM_EM_LEXICON_CALLBACK(em);
	#endif
	#ifndef PN_FROM_EM_LEXICON_CALLBACK
	return RETRIEVE_POINTER_parse_node(Lexicon::get_data(em));
	#endif
}

@h Monitoring the efficiency of the parser.
The present value of these statistics when the lexicon is used in making a
typical Inform story can be read off in //inform7: Performance Metrics//.

=
void FromLexicon::statistics(void) {
	LOG("Size of lexicon: %d excerpt meanings\n", NUMBER_CREATED(excerpt_meaning));
	vocabulary_entry *sve = NULL, *eve = NULL, *mve = NULL, *subve = NULL;
	int lsl = 0, lel = 0, lml = 0, lsubl = 0,
		nsl = 0, nel = 0, nml = 0, nsubl = 0,
		m = 0, n = 0;
	for (int i = 0; i<lexer_wordcount; i++) {
		vocabulary_entry *ve = Lexer::word(i);
		vocabulary_lexicon_data *ld = &(ve->means);
		if ((ld) && (ld->scanned_already == FALSE)) {
			m++;
			ld->scanned_already = TRUE;
			int sl = FromLexicon::len(ld->start_list);
			int el = FromLexicon::len(ld->end_list);
			int ml = FromLexicon::len(ld->middle_list);
			int subl = FromLexicon::len(ld->subset_list);
			if (sl > 0) nsl++;
			if (el > 0) nel++;
			if (ml > 0) nml++;
			if (subl > 0) nsubl++;
			if (sl + el + ml + subl > 0) n++;
			if (sl > lsl) { lsl = sl; sve = ve; }
			if (el > lel) { lel = el; eve = ve; }
			if (ml > lml) { lml = ml; mve = ve; }
			if (subl > lsubl) { lsubl = subl; subve = ve; }
		}
	}
	LOG("  Stored among %d words out of total vocabulary of %d\n", n, m);
	if (nsl > 0)
		LOG("  %d words have a start list: longest belongs to %V (with %d meanings)\n",
			nsl, sve, lsl);
	if (nel > 0)
		LOG("  %d words have an end list: longest belongs to %V (with %d meanings)\n",
			nel, eve, lel);
	if (nml > 0)
		LOG("  %d words have a middle list: longest belongs to %V (with %d meanings)\n",
			nml, mve, lml);
	if (nsubl > 0)
		LOG("  %d words have a subset list: longest belongs to %V (with %d meanings)\n",
			nsubl, subve, lsubl);
	LOG("\n");
	
	LOG("Number of attempts to retrieve: %d\n", no_calls_to_parse_excerpt);
	LOG("  of which unsuccessful: %d\n",
		no_calls_to_parse_excerpt - no_successful_calls_to_parse_excerpt);
	LOG("  of which successful: %d\n\n", no_successful_calls_to_parse_excerpt);

	LOG("Total attempts to match against excerpt meanings: %d\n", no_meanings_tried);
	LOG("  of which, total with incorrect hash codes: %d\n",
		no_meanings_tried - no_meanings_tried_in_detail);
	LOG("  of which, total with correct hash codes: %d\n",
		no_meanings_tried_in_detail);
	LOG("  of which, total which matched: %d\n", no_matched_ems);


	if (Log::aspect_switched_on(EXCERPT_MEANINGS_DA)) ExcerptMeanings::log_all();
}

int FromLexicon::len(parse_node *pn) {
	int N = 0;
	while (pn) {
		N++; pn = pn->next_alternative;
	}
	return N;
}
