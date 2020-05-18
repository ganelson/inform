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
typedef struct preposition_identity {
	struct word_assemblage prep_text;
	#ifdef CORE_MODULE
	struct lexicon_entry *prep_lex_entry; /* for use when indexing */
	#endif
	struct parse_node *where_prep_created; /* for use if problem messages needed */
	int allow_unexpected_upper_case; /* for preps like "in Cahoots With" */
	CLASS_DEFINITION
} preposition_identity;

@ As with verbs, "prepositions" can be long, but are not unlimited.

@d MAX_WORDS_IN_PREPOSITION (MAX_WORDS_IN_ASSEMBLAGE - 2)

@ Preposition words are marked for efficiency of parsing:

@d PREPOSITION_MC 0x00800000 /* a word which might introduce a relative clause */

@h Logging.

=
void Prepositions::log(OUTPUT_STREAM, void *vprep) {
	preposition_identity *prep = (preposition_identity *) vprep;
	if (prep == NULL) { WRITE("___"); }
	else { WRITE("p=%A", &(prep->prep_text)); }
}

@h Creation.
Prepositions are completely determined by their wording: the "for" attached
to one verb is the same preposition as the "for" attached to another one.

=
preposition_identity *Prepositions::make(word_assemblage wa, int unexpected_upper_casing_used) {
	preposition_identity *prep = NULL;
	LOOP_OVER(prep, preposition_identity)
		if (WordAssemblages::compare(&(prep->prep_text), &wa))
			return prep;

	prep = CREATE(preposition_identity);
	prep->prep_text = wa;
	prep->where_prep_created = set_where_created;
	prep->allow_unexpected_upper_case = unexpected_upper_casing_used;
	Prepositions::mark_as_preposition(WordAssemblages::first_word(&wa));

	#ifdef CORE_MODULE
	prep->prep_lex_entry = Index::Lexicon::new_main_verb(wa, PREP_LEXE);
	#endif
	LOGIF(VERB_FORMS, "New preposition: $p\n", prep);

	return prep;
}

@ Two utility routines:

=
parse_node *Prepositions::get_where_pu_created(preposition_identity *prep) {
	return prep->where_prep_created;
}

int Prepositions::length(preposition_identity *prep) {
	if (prep == NULL) return 0;
	return WordAssemblages::length(&(prep->prep_text));
}

@h Parsing source text against preposition usages.
The following parses to see if the preposition occurs at the beginning of,
perhaps entirely filling, the given wording. We return the word number after
the preposition ends, which might therefore be just outside the range.

=
int Prepositions::parse_prep_against(wording W, preposition_identity *prep) {
	return WordAssemblages::parse_as_weakly_initial_text(W, &(prep->prep_text), EMPTY_WORDING,
		prep->allow_unexpected_upper_case, TRUE);
}

@ The following nonterminal is currently not used. In principle it spots any
preposition, but note that it does so by testing in creation order.

=
<preposition> internal ? {
	if (Vocabulary::test_flags(Wordings::first_wn(W), PREPOSITION_MC) == FALSE) return FALSE;
	preposition_identity *prep;
	LOOP_OVER(prep, preposition_identity) {
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
	for (verb_form *vf = copular_verb->list_of_forms; vf; vf=vf->next_form) {
		preposition_identity *prep = vf->preposition;
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
	if (permitted_verb_identity)
		for (verb_form *vf = permitted_verb_identity->list_of_forms; vf; vf=vf->next_form) {
			preposition_identity *prep = vf->preposition;
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
	<relative-clause-marker>->opt.flag_words_in_production = PREPOSITION_MC;
}

void Prepositions::preform_optimiser(void) {
	Optimiser::mark_nt_as_requiring_itself(<preposition>);
	Optimiser::mark_nt_as_requiring_itself(<copular-preposition>);
	Optimiser::mark_nt_as_requiring_itself(<permitted-preposition>);
}

void Prepositions::mark_as_preposition(vocabulary_entry *ve) {
	Vocabulary::set_flags(ve, PREPOSITION_MC);
	Optimiser::mark_vocabulary(ve, <preposition>);
	Optimiser::mark_vocabulary(ve, <copular-preposition>);
	Optimiser::mark_vocabulary(ve, <permitted-preposition>);
}
