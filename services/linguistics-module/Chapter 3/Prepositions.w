[Prepositions::] Prepositions.

To define prepositional forms.

@h Prepositions.
These are words which introduce relative clauses, or mark the text following
them as having some role; in more inflected languages, noun cases might be
used for some of the same purposes. For example, in the sentence "Peter is
in the Library", the word "in" is a preposition (as it is twice in this
sentence, too). Prepositions often occur in combination with the copular
verb "to be" like this, but not always. Inform's standard usage "X substitutes
for Y" couples the preposition "for" to the verb "to substitute".

That all sounds linguistically sound, but we're on dodgier ground in how
we analyse text like "X is contained by Y". We're going to regard this as
the verb "to be" combined with the preposition "contained by", for
implementation reasons.

Note that the following says nothing about the preposition's meaning, which
will vary depending on the verb it's coupled with.

=
typedef struct preposition {
	struct word_assemblage prep_text;
	#ifdef CORE_MODULE
	struct index_lexicon_entry *prep_lex_entry; /* for use when indexing */
	#endif
	struct parse_node *where_prep_created; /* for use if problem messages needed */
	int allow_unexpected_upper_case; /* for preps like "in Cahoots With" */
	struct linguistic_stock_item *in_stock;
	CLASS_DEFINITION
} preposition;

@ Prepositions are a grammatical category:

=
grammatical_category *prepositions_category = NULL;
void Prepositions::create_category(void) {
	prepositions_category = Stock::new_category(I"preposition");
	METHOD_ADD(prepositions_category, LOG_GRAMMATICAL_CATEGORY_MTID, Prepositions::log_item);
}

void Prepositions::log_item(grammatical_category *cat, general_pointer data) {
	preposition *P = RETRIEVE_POINTER_preposition(data);
	LOG("%A", &(P->prep_text));
}

@ As with verbs, "prepositions" can be long, but are not unlimited.

@d MAX_WORDS_IN_PREPOSITION (MAX_WORDS_IN_ASSEMBLAGE - 2)

@ Preposition words are marked for efficiency of parsing:

@d PREPOSITION_MC 0x00800000 /* a word which might introduce a relative clause */

@h Logging.

=
void Prepositions::log(OUTPUT_STREAM, void *vprep) {
	preposition *prep = (preposition *) vprep;
	if (prep == NULL) { WRITE("___"); }
	else { WRITE("%A", &(prep->prep_text)); }
}

@h Creation.
Prepositions are completely determined by their wording: the "for" attached
to one verb is the same preposition as the "for" attached to another one.

=
preposition *Prepositions::make(word_assemblage wa, int unexpected_upper_casing_used,
	parse_node *where) {
	preposition *prep = NULL;
	LOOP_OVER(prep, preposition)
		if (WordAssemblages::eq(&(prep->prep_text), &wa))
			return prep;

	prep = CREATE(preposition);
	prep->prep_text = wa;
	prep->where_prep_created = where;
	prep->allow_unexpected_upper_case = unexpected_upper_casing_used;
	Prepositions::mark_as_preposition(WordAssemblages::first_word(&wa));

	#ifdef CORE_MODULE
	prep->prep_lex_entry = IndexLexicon::new_main_verb(wa, PREP_LEXE);
	#endif
	prep->in_stock = Stock::new(prepositions_category, STORE_POINTER_preposition(prep));
	LOGIF(VERB_FORMS, "New preposition: $p\n", prep);

	return prep;
}

@ Two utility routines:

=
parse_node *Prepositions::get_where_pu_created(preposition *prep) {
	return prep->where_prep_created;
}

int Prepositions::length(preposition *prep) {
	if (prep == NULL) return 0;
	return WordAssemblages::length(&(prep->prep_text));
}

@h Parsing source text against preposition usages.
The following parses to see if the preposition occurs at the beginning of,
perhaps entirely filling, the given wording. We return the word number after
the preposition ends, which might therefore be just outside the range.

=
int Prepositions::parse_prep_against(wording W, preposition *prep) {
	return WordAssemblages::parse_as_weakly_initial_text(W, &(prep->prep_text), EMPTY_WORDING,
		prep->allow_unexpected_upper_case, TRUE);
}

@ The following nonterminal is currently not used. In principle it spots any
preposition, but note that it does so by testing in creation order.

=
<preposition> internal ? {
	if (Vocabulary::test_flags(Wordings::first_wn(W), PREPOSITION_MC) == FALSE) return FALSE;
	preposition *prep;
	LOOP_OVER(prep, preposition) {
		int i = Prepositions::parse_prep_against(W, prep);
		if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W)+1)) {
			*XP = prep;
			return i-1;
		}
	}
	return FALSE;
}

@ It's often useful to look for prepositions which can be combined with the
copular verb "to be". These are tested in order of the list of possible
verb forms for "to be', which is constructed with longer prepositions first.
So it will find the longest match.

=
<copular-preposition> internal ? {
	if (copular_verb == NULL) return FALSE;
	if (Vocabulary::test_flags(Wordings::first_wn(W), PREPOSITION_MC) == FALSE) return FALSE;
	for (verb_form *vf = copular_verb->first_form; vf; vf=vf->next_form) {
		preposition *prep = vf->preposition;
		if ((prep) && (VerbMeanings::is_meaningless(&(vf->list_of_senses->vm)) == FALSE)) {
			int i = Prepositions::parse_prep_against(W, prep);
			if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W)+1)) {
				*XP = prep;
				return i-1;
			}
		}
	}
	return FALSE;
}

@ This is exactly similar, except that it looks for prepositions combined
with a given "permitted verb".

=
<permitted-preposition> internal ? {
	if (Vocabulary::test_flags(Wordings::first_wn(W), PREPOSITION_MC) == FALSE) return FALSE;
	if (permitted_verb)
		for (verb_form *vf = permitted_verb->first_form; vf; vf=vf->next_form) {
			preposition *prep = vf->preposition;
			if ((prep) && (VerbMeanings::is_meaningless(&(vf->list_of_senses->vm)) == FALSE)) {
				int i = Prepositions::parse_prep_against(W, prep);
				if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W)+1)) {
					*XP = prep;
					return i-1;
				}
			}
		}
	return FALSE;
}

@ =
void Prepositions::mark_for_preform(void) {
	Nonterminals::flag_words_with(<relative-clause-marker>, PREPOSITION_MC);
}

void Prepositions::preform_optimiser(void) {
	NTI::one_word_in_match_must_have_my_NTI_bit(<preposition>);
	NTI::one_word_in_match_must_have_my_NTI_bit(<copular-preposition>);
	NTI::one_word_in_match_must_have_my_NTI_bit(<permitted-preposition>);
}

void Prepositions::mark_as_preposition(vocabulary_entry *ve) {
	Vocabulary::set_flags(ve, PREPOSITION_MC);
	NTI::mark_vocabulary(ve, <preposition>);
	NTI::mark_vocabulary(ve, <copular-preposition>);
	NTI::mark_vocabulary(ve, <permitted-preposition>);
}
