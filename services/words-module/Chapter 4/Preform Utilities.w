[PreformUtilities::] Preform Utilities.

Other uses for Preform grammar, including the generation of adaptive
text, and word inflection.

@h Specifying generated text.
Our main operation here is a "merge". This extracts the text from a production,
substituting the ingredient text in place of any |...| it finds. (Other
wildcards and nonterminals are ignored.) For example, merging the production
= (text as Preform)
	fried ... tomatoes
=
with "orange" results in "fried orange tomatoes".

=
word_assemblage PreformUtilities::merge(nonterminal *nt, int pnum,
	word_assemblage ingredient) {
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		int N = 0;
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
			if (N == pnum) {
				word_assemblage wa = WordAssemblages::lit_0();
				ptoken *pt;
				for (pt = pr->first_pt; pt; pt = pt->next_pt) {
					if (pt->ptoken_category == FIXED_WORD_PTC) {
						wa = WordAssemblages::join(wa, WordAssemblages::lit_1(pt->ve_pt));
					} else if (pt->ptoken_category == MULTIPLE_WILDCARD_PTC) {
						wa = WordAssemblages::join(wa, ingredient);
					}
				}
				return wa;
			}
			N++;
		}
	}
	return WordAssemblages::lit_0(); /* give up, in other words */
}

@ Thus we can simply extract the wording by performing a merge with the empty
ingredient text:

=
word_assemblage PreformUtilities::wording(nonterminal *nt, int pnum) {
	return PreformUtilities::merge(nt, pnum, WordAssemblages::lit_0());
}

@ And here we take just one word:

=
vocabulary_entry *PreformUtilities::word(nonterminal *nt, int pnum) {
	word_assemblage wa = PreformUtilities::merge(nt, pnum, WordAssemblages::lit_0());
	vocabulary_entry **words;
	int num_words;
	WordAssemblages::as_array(&wa, &words, &num_words);
	if (num_words == 1) return words[0];
	return NULL;
}

@h Specifying replacements.
The following looks for a word in one nonterminal and returns the
corresponding word in another. If the word isn't found, it's left unchanged.

=
vocabulary_entry *PreformUtilities::find_corresponding_word(vocabulary_entry *ve,
	nonterminal *nt_from, nonterminal *nt_to) {
	for (production_list *pl_from = nt_from->first_pl, *pl_to = nt_to->first_pl;
		((pl_from) && (pl_to));
		pl_from = pl_from->next_pl, pl_to = pl_to->next_pl)
		for (production *pr_from = pl_from->first_pr, *pr_to = pl_to->first_pr;
			((pr_from) && (pr_to));
			pr_from = pr_from->next_pr, pr_to = pr_to->next_pr)
			for (ptoken *pt_from = pr_from->first_pt, *pt_to = pr_to->first_pt;
				((pt_from) && (pt_to));
				pt_from = pt_from->next_pt, pt_to = pt_to->next_pt)
				if ((pt_from->ptoken_category == FIXED_WORD_PTC) &&
					(pt_to->ptoken_category == FIXED_WORD_PTC))
					if (ve == pt_from->ve_pt)
						return pt_to->ve_pt;
	return ve; /* no change, in other words */
}

@h Lexicon entry.
This is only a convenience for putting particles into the Lexicon:

=
#ifdef CORE_MODULE
void PreformUtilities::enter_lexicon(nonterminal *nt, int pos, char *category, char *gloss) {
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl)
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr)
			for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt)
				for (ptoken *alt = pt; alt; alt = alt->alternative_ptoken)
					if (alt->ve_pt)
						IndexLexicon::new_entry_with_details(EMPTY_WORDING, pos,
							WordAssemblages::lit_1(alt->ve_pt), category, gloss);
}
#endif

@h Making tries.
Properly speaking, we make "avinues". Note that we expect to make a different
avinue for each natural language; this matters so that we can pluralise words
correctly in both English and French in the same run of Inform, for example.
But we are going to need to use these avinues frequently, so we cache them once
created.

=
match_avinue *PreformUtilities::define_trie(nonterminal *nt, int end,
	NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	match_avinue *ave = NULL;
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl)
		if (pl->definition_language == nl) {
			if (pl->as_avinue) return pl->as_avinue;
			@<Construct a new avinue from this nonterminal@>;
			pl->as_avinue = ave;
		}
	return ave;
}

@ The grammar for this nonterminal is either a "list grammar", meaning that it
lists other nonterminals which each define avinues, and we have to string those
together into one long avinue; or else it contains the actual content of a
single avinue.

@<Construct a new avinue from this nonterminal@> =
	int list_grammar = NOT_APPLICABLE; /* i.e., we don't know yet */
	for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
		ptoken *first = pr->first_pt;
		if (first == NULL) continue;
		ptoken *second = first->next_pt;
		if ((second) && (second->next_pt)) {
			Instrumentation::log_production(pr, FALSE);
			PreformUtilities::production_error(nt, pr,
				"trie line with more than 2 words");
		}
		@<Consider the one- or two-token production in this nonterminal@>;
	}

@ Each production contains one or two tokens. There are four possibilities for
the production:
= (text)
	(1)   ... <some-nonterminal>
	(2)   <some-nonterminal> ...
	(3)   <some-nonterminal>
	(4)   pattern-word instructions-word
=
Cases (1), (2) and (3) are allowed only in list grammars; case (4) is allowed
only in content grammars. The |...| indicates whether the trie in the named
nonterminal will act on the start or end of a word -- this is needed only to
override the normal convention.

@<Consider the one- or two-token production in this nonterminal@> =
	int this_end = end;
	ptoken *entry = NULL;
	if ((first->ptoken_category == MULTIPLE_WILDCARD_PTC) &&
		(second) && (second->ptoken_category == NONTERMINAL_PTC)) {
		entry = second; this_end = TRIE_END;
	}
	if ((first->ptoken_category == NONTERMINAL_PTC) &&
		(second) && (second->ptoken_category == MULTIPLE_WILDCARD_PTC)) {
		entry = first; this_end = TRIE_START;
	}
	if ((first->ptoken_category == NONTERMINAL_PTC) && (second == NULL)) {
		entry = first;
	}

	if (entry) {
		if (list_grammar == FALSE) @<Throw problem for a mixed trie nonterminal@>;
		@<Recurse to make an avinue from the nonterminal named here, and add it to our result@>;
		list_grammar = TRUE;
	} else {
		if (list_grammar == TRUE) @<Throw problem for a mixed trie nonterminal@>;
		if (second == NULL)
			PreformUtilities::production_error(nt, pr,
				"there should be two words here, a pattern and an instruction");
		@<Add this pattern and instruction to the trie, creating it if necessary@>;
		list_grammar = FALSE;
	}

@<Throw problem for a mixed trie nonterminal@> =
	PreformUtilities::production_error(nt, pr,
		"this should either be a list of other nonterminals, or a list of patterns "
		"and instructions, but not a mixture");

@<Recurse to make an avinue from the nonterminal named here, and add it to our result@> =
	match_avinue *next_mt =
		Tries::duplicate_avinue(PreformUtilities::define_trie(entry->nt_pt, this_end, nl));
	if (ave == NULL) ave = next_mt;
	else {
		match_avinue *m = ave;
		while (m->next) m = m->next;
		m->next = next_mt;
	}

@<Add this pattern and instruction to the trie, creating it if necessary@> =
	if (ave == NULL) ave = Tries::new_avinue(end);
	TEMPORARY_TEXT(from);
	WRITE_TO(from, "%V", first->ve_pt);
	Tries::add_to_avinue(ave, from, Vocabulary::get_exemplar(second->ve_pt, FALSE));
	DISCARD_TEXT(from);

@ The following may be useful for debugging:

=
void PreformUtilities::log_avinues(void) {
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal)
		for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl)
			if (pl->as_avinue)
				LOG("\n\n%V ($J)\n%a",
					nt->nonterminal_id, pl->definition_language, pl->as_avinue);
}

@h Errors.
People are going to get their tries wrong; it's a very hard notation
to learn. No end users of Inform will ever write them at all -- this is a
low-level feature for translators only -- but translators need all the help
they can get, so we'll try to provide good problem messages.

=
void PreformUtilities::production_error(nonterminal *nt, production *pr, char *message) {
	PreformUtilities::error(WordAssemblages::lit_0(), nt, pr, message);
}

@ Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |PREFORM_ERROR_WORDS_CALLBACK|
to some routine of her own, gazumping this one.

=
void PreformUtilities::error(word_assemblage base_text, nonterminal *nt,
	production *pr, char *message) {
	#ifdef PREFORM_ERROR_WORDS_CALLBACK
	PREFORM_ERROR_WORDS_CALLBACK(base_text, nt, pr, message);
	#endif
	#ifndef PREFORM_ERROR_WORDS_CALLBACK
	if (pr) {
		LOG("The production at fault is:\n");
		Instrumentation::log_production(pr, FALSE); LOG("\n");
	}
	TEMPORARY_TEXT(ERM);
	if (nt == NULL)
		WRITE_TO(ERM, "(no nonterminal)");
	else
		WRITE_TO(ERM, "nonterminal %w",
			Vocabulary::get_exemplar(nt->nonterminal_id, FALSE));
	WRITE_TO(ERM, ": ");

	if (WordAssemblages::nonempty(base_text))
		WRITE_TO(ERM, "can't conjugate verb '%A': ", &base_text);

	if (pr) {
		TEMPORARY_TEXT(TEMP);
		for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt) {
			Instrumentation::write_ptoken(TEMP, pt);
			if (pt->next_pt) WRITE_TO(TEMP, " ");
		}
		WRITE_TO(ERM, "line %d ('%S'): ", pr->match_number, TEMP);
		DISCARD_TEXT(TEMP);
	}
	WRITE_TO(ERM, "%s", message);
	Errors::with_text("Preform error: %S", ERM);
	DISCARD_TEXT(ERM);
	#endif
}
