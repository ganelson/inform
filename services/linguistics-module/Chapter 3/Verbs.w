[Verbs::] Verbs.

To record the identity and different structural forms of verbs.

@h Verb Identities.
What is a verb? Are the verbs in "Peter is hungry" and "Jane will be in the
Dining Room" the same? How about in "Donald Trump lies on the television" and
"My cat Donald lies on the television"? This isn't so easy to answer.

For our purposes two usages of a verbs are "the same verb" if they ultimately
come from the same instance of the following structure; this essentially
defines a verb as a combination of its inflected forms with its possible
usages in a sentence.

=
typedef struct verb {
	struct verb_conjugation *conjugation;
	struct verb_form *first_form;
	struct verb_form *base_form;
	struct linguistic_stock_item *in_stock;

	#ifdef VERB_COMPILATION_LINGUISTICS_CALLBACK
	struct verb_compilation_data compilation_data;
	#endif

	CLASS_DEFINITION
} verb;

@ Verbs are a grammatical category:

=
grammatical_category *verbs_category = NULL;
void Verbs::create_category(void) {
	verbs_category = Stock::new_category(I"verb");
	METHOD_ADD(verbs_category, LOG_GRAMMATICAL_CATEGORY_MTID, Verbs::log_item);
}

void Verbs::log_item(grammatical_category *cat, general_pointer data) {
	verb *V = RETRIEVE_POINTER_verb(data);
	Verbs::log_verb(DL, V);
}

verb *Verbs::from_lcon(lcon_ti lcon) {
	linguistic_stock_item *item = Stock::from_lcon(lcon);
	if (item == NULL) return NULL;
	return RETRIEVE_POINTER_verb(item->data);
}

lcon_ti Verbs::to_lcon(verb *v) {
	return Stock::to_lcon(v->in_stock);
}

@ Note also that every verb always has a bare form, where no prepositions are
combined with it. This is (initially) meaningless, but it always exists.

Finally, note that the conjugation can be null. This is used only for
what we'll call "operator verbs", where a mathematical operator is used
instead of a word: for example, the |<=| sign is such a verb in Inform.

=
verb *copular_verb = NULL;

verb *Verbs::new_verb(verb_conjugation *vc, int cop) {
	verb *V = CREATE(verb);
	V->conjugation = vc;
	V->first_form = NULL;
	V->base_form = NULL;
	#ifdef VERB_COMPILATION_LINGUISTICS_CALLBACK
	VERB_COMPILATION_LINGUISTICS_CALLBACK(V);
	#endif

	@<Give the new verb a single meaningless form@>;
	@<If this is the first copular verb, remember that@>;

	V->in_stock = Stock::new(verbs_category, STORE_POINTER_verb(V));
	LOGIF(VERB_FORMS, "New verb: $w\n", V);
	return V;
}

@<Give the new verb a single meaningless form@> =
	Verbs::add_form(V, NULL, NULL, VerbMeanings::meaninglessness(), SVO_FS_BIT);

@ Note that the first verb submitted with the copular flag set is considered
to be the definitive copular verb.

@<If this is the first copular verb, remember that@> =
	if ((cop) && (copular_verb == NULL) && (vc) &&
		(WordAssemblages::nonempty(vc->infinitive))) copular_verb = V;

@

=
void Verbs::log_verb(OUTPUT_STREAM, void *vvi) {
	verb *V = (verb *) vvi;
	if (V == NULL) { WRITE("<no-V>"); }
	else {
		if (V->conjugation) WRITE("%A", &(V->conjugation->infinitive));
		else WRITE("(unconjugated)");
		WRITE("(%d)", V->allocation_id);
	}
}

@h Operator Verbs.
As noted above, these are tenseless verbs with no conjugation, represented
only by symbols such as |<=|. As infix operators, they mimic SVO sentence
structures.

=
verb *Verbs::new_operator_verb(verb_meaning vm) {
	verb *V = Verbs::new_verb(NULL, FALSE);
	Verbs::add_form(V, NULL, NULL, vm, SVO_FS_BIT);
	return V;
}

@h Verb Forms.
A "verb form" is a way to use a given verb in a sentence. This may require
up to two different prepositions to be used. For example, "Peter is hungry"
and "Jane will be in the Dining Room" exhibit two different verb forms:
"to be" with no preposition (meaning that the object phrase, "hungry", is
not introduced by a preposition), and "to be" with the preposition "in".

It's not always the case that the preposition follows the verb, even when
it directly introduces the object, because of a quirk of English called
inversion: for example "In the Dining Room is Jane" locates "in" far from
"is". But the first preposition, if given, always introduces the object
phrase. If it's not given, the object phrase has no introduction, as in
the sentence "Peter is hungry".

The second clause preposition is again optional. This marks that the verb
takes two object phrases, and provides a preposition to introduce the
second of these. For example, in "X translates into Y as Z", the verb
is "translate", the first preposition is "into", and the second is "as".
In "X ends Y when Z", the first preposition is null, and the second is "when".

@ A "form structure" is a possible way in which a verb form can be expressed.
SVO means "subject, verb, object", as in "Peter likes Jane"; VOO means
"verb, object, object", as in "Test me with ...", and so on. Since multiple
form usages can be legal for the same form, this is a bitmap:

@d SVO_FS_BIT 			1
@d VO_FS_BIT			2
@d SVOO_FS_BIT			4
@d VOO_FS_BIT			8

@ So here's the verb form:

=
typedef struct verb_form {
	struct verb *underlying_verb;
	struct preposition *preposition;
	struct preposition *second_clause_preposition;
	int form_structures; /* bitmap of |*_FS_BIT| values */

	struct word_assemblage infinitive_reference_text; /* e.g. "translate into" */
	struct word_assemblage pos_reference_text; /* e.g. "translate into" */
	struct word_assemblage neg_reference_text; /* e.g. "do not translate into" */

	struct verb_sense *list_of_senses;
	struct verb_meaning *first_unspecial_meaning;

	struct verb_form *next_form; /* within the linked list for the verb */
	struct linguistic_stock_item *in_stock;

	#ifdef VERB_FORM_COMPILATION_LINGUISTICS_CALLBACK
	struct verb_form_compilation_data verb_form_compilation;
	#endif

	CLASS_DEFINITION
} verb_form;

@ Verb forms are also a grammatical category:

=
grammatical_category *verb_forms_category = NULL;
void Verbs::create_forms_category(void) {
	verb_forms_category = Stock::new_category(I"verb_form");
	METHOD_ADD(verb_forms_category, LOG_GRAMMATICAL_CATEGORY_MTID, Verbs::log_form_item);
}

void Verbs::log_form_item(grammatical_category *cat, general_pointer data) {
	verb_form *vf = RETRIEVE_POINTER_verb_form(data);
	Verbs::log_form(vf);
}
void Verbs::log_form(verb_form *vf) {
	LOG("$w + $p + $p",
		vf->underlying_verb, vf->preposition, vf->second_clause_preposition);
	if (vf->form_structures & SVO_FS_BIT) LOG(" SVO");
	if (vf->form_structures & VO_FS_BIT) LOG(" VO");
	if (vf->form_structures & SVOO_FS_BIT) LOG(" SVOO");
	if (vf->form_structures & VOO_FS_BIT) LOG(" VOO");
}

@h Verb senses.
In this model, a verb can have multiple senses. Inform makes little use of
that in verbs created by the user, but for example "X is Y" has more than
a dozen different senses. (Inform distinguishes them on a case by case basis,
by looking at X and Y.)

The following structure is just a holder for a "verb meaning", so that it
can be joined into a linked list. Verb meanings are described elsewhere.

=
typedef struct verb_sense {
	struct verb_meaning vm;
	struct verb_sense *next_sense; /* within the linked list for the verb form */
	CLASS_DEFINITION
} verb_sense;

@h Creating forms and senses.
Forms are stored in a linked list, and are uniquely identified by the triplet
of verb and two prepositions.

The base form is by definition the one where no prepositions are used. We could
therefore find that base form by calling |Verbs::find_form(V, NULL, NULL)|,
but instead we cache this result in |V->base_form| for speed: profiling shows
that Inform otherwise spends nearly 1% of its entire running time making that
innocent-looking call.

=
verb_form *Verbs::base_form(verb *V) {
	if (V) return V->base_form;
	return NULL;
}

verb_form *Verbs::find_form(verb *V, preposition *prep, preposition *second_prep) {
	if (V)
		for (verb_form *vf = V->first_form; vf; vf = vf->next_form)
			if ((vf->preposition == prep) && (vf->second_clause_preposition == second_prep))
				return vf;
	return NULL;
}

@ And here's how we add them.

=
void Verbs::add_form(verb *V, preposition *prep,
	preposition *second_prep, verb_meaning vm, int form_structs) {
	if (VerbMeanings::is_meaningless(&vm) == FALSE)
		LOGIF(VERB_FORMS, "  Adding form: $w + $p + $p = $y\n",
			V, prep, second_prep, &vm);

	VerbMeanings::set_where_assigned(&vm, current_sentence);

	if (V == NULL) internal_error("added form to null verb");

	verb_form *vf = NULL;
	@<Find or create the verb form structure for this combination@>;

	vf->form_structures = ((vf->form_structures) | form_structs);

	if ((VerbMeanings::is_meaningless(&vm) == FALSE) || (vf->list_of_senses == NULL))
		@<Add this meaning as a new sense of the verb form@>;
}

@<Find or create the verb form structure for this combination@> =
	vf = Verbs::find_form(V, prep, second_prep);
	if (vf == NULL) {
		vf = CREATE(verb_form);
		vf->underlying_verb = V;
		vf->preposition = prep;
		vf->second_clause_preposition = second_prep;
		vf->form_structures = form_structs;
		vf->list_of_senses = NULL;
		vf->next_form = NULL;
		vf->first_unspecial_meaning = NULL;
		#ifdef VERB_FORM_COMPILATION_LINGUISTICS_CALLBACK
		VERB_FORM_COMPILATION_LINGUISTICS_CALLBACK(vf);
		#endif
		@<Compose the reference texts for the new form@>;
		@<Insert the new form into the list of forms for this verb@>;
		vf->in_stock = Stock::new(verb_forms_category, STORE_POINTER_verb_form(vf));
	}

@ The reference texts are just for convenience, really: they express the form
in a canonical verbal form. For example, "translate into |+| as".

@<Compose the reference texts for the new form@> =
	verb_conjugation *vc = V->conjugation;
	if (vc) {
		int p = VerbUsages::adaptive_person(vc->defined_in);
		int n = VerbUsages::adaptive_number(vc->defined_in);
		word_assemblage we_form = (vc->tabulations[ACTIVE_VOICE].vc_text[IS_TENSE][POSITIVE_SENSE][p][n]);
		word_assemblage we_dont_form = (vc->tabulations[ACTIVE_VOICE].vc_text[IS_TENSE][NEGATIVE_SENSE][p][n]);
		vf->infinitive_reference_text = vc->infinitive;
		vf->pos_reference_text = we_form;
		vf->neg_reference_text = we_dont_form;
		if (prep) {
			vf->infinitive_reference_text =
				WordAssemblages::join(vf->infinitive_reference_text, prep->prep_text);
			vf->pos_reference_text =
				WordAssemblages::join(vf->pos_reference_text, prep->prep_text);
			vf->neg_reference_text =
				WordAssemblages::join(vf->neg_reference_text, prep->prep_text);
		}
		if (second_prep) {
			word_assemblage plus =
				WordAssemblages::lit_1(PLUS_V);
			vf->infinitive_reference_text =
				WordAssemblages::join(vf->infinitive_reference_text, plus);
			vf->pos_reference_text =
				WordAssemblages::join(vf->pos_reference_text, plus);
			vf->neg_reference_text =
				WordAssemblages::join(vf->neg_reference_text, plus);
			vf->infinitive_reference_text =
				WordAssemblages::join(vf->infinitive_reference_text, second_prep->prep_text);
			vf->pos_reference_text =
				WordAssemblages::join(vf->pos_reference_text, second_prep->prep_text);
			vf->neg_reference_text =
				WordAssemblages::join(vf->neg_reference_text, second_prep->prep_text);
		}
	} else {
		vf->infinitive_reference_text = WordAssemblages::new_assemblage();
		vf->pos_reference_text = WordAssemblages::new_assemblage();
		vf->neg_reference_text = WordAssemblages::new_assemblage();
	}

@ The list of forms for a verb is in order of preposition length.

@<Insert the new form into the list of forms for this verb@> =
	verb_form *prev = NULL, *evf = V->first_form;
	for (; evf; prev = evf, evf = evf->next_form) {
		if (Prepositions::length(prep) > Prepositions::length(evf->preposition)) break;
	}
	if (prev == NULL) {
		vf->next_form = V->first_form;
		V->first_form = vf;
	} else {
		vf->next_form = prev->next_form;
		prev->next_form = vf;
	}
	if ((prep == NULL) && (second_prep == NULL)) V->base_form = vf;

@ A new sense is normally just added to the end of the list of senses for
the given form, except that if there's a meaningless sense present already,
we overwrite that with the new (presumably meaningful) one.

@<Add this meaning as a new sense of the verb form@> =
	verb_sense *vs = vf->list_of_senses, *prev = NULL;
	while (vs) {
		if (VerbMeanings::is_meaningless(&(vs->vm))) { vs->vm = vm; break; }
		prev = vs; vs = vs->next_sense;
	}
	if (vs == NULL) {
		vs = CREATE(verb_sense);
		vs->vm = vm;
		vs->next_sense = NULL;
		if (prev == NULL) vf->list_of_senses = vs;
		else prev->next_sense = vs;
	}
	if (VerbMeanings::get_special_meaning(&(vs->vm)) == NULL) {
		vf->first_unspecial_meaning = &(vs->vm);
	} else {
		if (vf->first_unspecial_meaning == &(vs->vm))
			vf->first_unspecial_meaning = NULL;
	}

@ The following function may seem curious -- what's so great about the first
regular sense of a verb? The answer is that Inform generally gives a verb at
most one regular sense.

We cache the result in |vf->first_unspecial_meaning| for speed, because profiling
of //inform7// suggests this is worth it, but retain the uncached algorithm as
well in case we suspect bugs in future.

@d CACHE_FIRST_UNSPECIAL_MEANING

=
verb_meaning *Verbs::first_unspecial_meaning_of_verb_form(verb_form *vf) {
	if (vf)  {
		#ifdef CACHE_FIRST_UNSPECIAL_MEANING
		return vf->first_unspecial_meaning;
		#endif
		#ifndef CACHE_FIRST_UNSPECIAL_MEANING
		for (verb_sense *vs = vf->list_of_senses; vs; vs = vs->next_sense)
			if (VerbMeanings::get_special_meaning(&(vs->vm)) == NULL)
				return &(vs->vm);
		#endif
	}
	return NULL;
}

@ This is useful for indexing:

=
int Verbs::has_special_meanings(verb_form *vf) {
	if (vf)
		for (verb_sense *vs = vf->list_of_senses; vs; vs = vs->next_sense)
			if (VerbMeanings::get_special_meaning(&(vs->vm)))
				return TRUE;
	return FALSE;
}
