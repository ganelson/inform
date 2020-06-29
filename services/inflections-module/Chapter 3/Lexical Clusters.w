[Clusters::] Lexical Clusters.

Lexical clusters are sets of noun or adjective forms, perhaps multiple
or in multiple languages, which have in common that they share a meaning.

@h Cluster.
A cluster is a linked list of "forms", annotated with lingistic roles. For
example, the cluster of forms for the common noun "man" might be:

>> man (En, singular), men (En, plural), homme (Fr, singular), hommes (Fr, plural)

We would call each of these four an "individual form" of the cluster. Each can
in fact consist of multiple wordings, inflected into different cases, but
in English this doesn't really show.

While this perhaps looks a little unstructured, that means that it doesn't
impose many assumptions about the language. A similarly pragmatic view is taken
by the XML frameworks used in the Lexical Markup Framework standard ISO 24613,
which it would be fairly easy to convert our //lexical_cluster// objects to.

=
typedef struct lexical_cluster {
	struct linked_list *listed; /* of |individual_form| */
	CLASS_DEFINITION
} lexical_cluster;

typedef struct individual_form {
	struct declension declined; /* text of form */
	int form_number; /* 1 for singular, 2 for plural */
	int form_gender; /* 1 is neuter, 2 is masculine, 3 is feminine */
	NATURAL_LANGUAGE_WORDS_TYPE *form_language;
	CLASS_DEFINITION
} individual_form;

@ A cluster begins empty.

=
lexical_cluster *Clusters::new(void) {
	lexical_cluster *forms = CREATE(lexical_cluster);
	forms->listed = NEW_LINKED_LIST(individual_form);
	return forms;
}

@ The following can add either a single form, or a form and its plural(s):

=
individual_form *Clusters::add_one(lexical_cluster *forms, wording W,
	NATURAL_LANGUAGE_WORDS_TYPE *nl, int gender, int number) {
	nl = DefaultLanguage::get(nl);
	individual_form *in = CREATE(individual_form);
	in->declined = Declensions::of_noun(W, nl, gender, number);
	in->form_language = nl;
	in->form_number = number;
	in->form_gender = gender;
	ADD_TO_LINKED_LIST(in, individual_form, forms->listed);
	return in;
}

linked_list *Clusters::add(lexical_cluster *forms, wording W,
	NATURAL_LANGUAGE_WORDS_TYPE *nl, int gender, int number, int pluralise) {
	linked_list *L = NEW_LINKED_LIST(individual_form);
	individual_form *in = Clusters::add_one(forms, W, nl, gender, number);
	ADD_TO_LINKED_LIST(in, individual_form, L);
	if ((pluralise) && (number == 1))
		@<Add plural forms as well@>;
	return L;
}

@ The following makes all possible plurals and registers those too. (Note
that every instance gets a plural form: even something palpably unique, like
"the Koh-i-Noor diamond".) The plural dictionary supports multiple plurals,
so there may be any number of forms registered: for instance, the kind
"person" is registered with plurals "persons" and "people".

@<Add plural forms as well@> =
	plural_dictionary_entry *pde = NULL;
	int k = 0;
	do {
		k++;
		wording PW = EMPTY_WORDING;
		pde = Pluralisation::make(W, &PW, pde, nl);
		if (Wordings::nonempty(PW)) {
			LOGIF(CONSTRUCTED_PLURALS, "(%d) Plural of <%W>: <%W>\n", k, W, PW);
			individual_form *in = Clusters::add_one(forms, PW, nl, gender, 2);
			ADD_TO_LINKED_LIST(in, individual_form, L);
		}
	} while (pde);

@ The following is more suited to adjectives, or to words which are used
adjectivally, such as past participles in French. This time we generate all
possible gender and number agreements -- except in English, where no variation
occurs: please don't argue about blond/blonde.

GNA is a traditional Inform term, standing for "gender-number-animation".
At run time, it's an integer from 0 to 11 which encodes all possible
combinations. Here we only work through six, ignoring animation:

=
void Clusters::add_with_agreements(lexical_cluster *cl, wording W,
	NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	nl = DefaultLanguage::get(nl);
	if (nl == DefaultLanguage::get(NULL))
		Clusters::add(cl, W, nl, NEUTER_GENDER, 1, FALSE);
	else
		for (int gna = 0; gna < 6; gna++)
			@<Generate agreement form in this GNA and add to the declension@>;
}

@ We use tries to modify the base text, which is taken to be the neuter
singular form, into the other five forms.

@<Generate agreement form in this GNA and add to the declension@> =
	nonterminal *step1 = NULL, *step2 = NULL;
	int form_number = 1, form_gender = NEUTER_GENDER;
	if (gna >= 3) form_number = 2;
	switch (gna) {
		case 0:	step1 = <adjective-to-masculine-singular>;
				form_gender = MASCULINE_GENDER; break;
		case 1:	step1 = <adjective-to-feminine-singular>;
				form_gender = FEMININE_GENDER; break;
		case 2:	break;
		case 3: step1 = <adjective-to-masculine-singular>;
				step2 = <adjective-to-masculine-plural>;
				form_gender = MASCULINE_GENDER; break;
		case 4: step1 = <adjective-to-feminine-singular>;
				step2 = <adjective-to-feminine-plural>;
				form_gender = FEMININE_GENDER; break;
		case 5: step1 = <adjective-to-plural>; break;
	}
	wording FW = EMPTY_WORDING;
	@<Process via the agreement trie in this pipeline@>;
	Clusters::add(cl, FW, nl, form_gender, form_number, FALSE);

@ Not much of a pipeline, really: we start with the base case and work
through one or two tries.

@<Process via the agreement trie in this pipeline@> =
	word_assemblage wa = WordAssemblages::from_wording(W);
	if (step1)
		wa = Inflect::first_word(wa,
			PreformUtilities::define_trie(step1, TRIE_END,
				DefaultLanguage::get(nl)));
	if (step2)
		wa = Inflect::first_word(wa,
			PreformUtilities::define_trie(step2, TRIE_END,
				DefaultLanguage::get(nl)));
	FW = WordAssemblages::to_wording(&wa);

@h Plural fixing.
Less elegantly, we can force the plural of a form in a cluster to a given
fixed text, overwriting it if it's already there. In practice this is done
only when the built-in kinds are being given plural forms; some of these
(those for kind constructors with optional wordings) have a peculiar format,
and wouldn't pass through the pluralising tries intact.

=
void Clusters::set_plural_in_language(lexical_cluster *cl, wording W,
	NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	individual_form *in;
	LOOP_OVER_LINKED_LIST(in, individual_form, cl->listed)
		if (in->form_number == 2) {
			in->declined = Declensions::of_noun(W, nl, NEUTER_GENDER, 2);
			return;
		}
	Clusters::add(cl, W, NULL, NEUTER_GENDER, 2, FALSE);
}

@h Searching declensions.
These are always quite small, so there's no need for any efficient device
to search them.

The first routine finds the earliest form with the correct number (singular
or plural):

=
wording Clusters::get_form(lexical_cluster *cl, int plural_flag) {
	int number_sought = 1;
	if (plural_flag) number_sought = 2;
	individual_form *in;
	LOOP_OVER_LINKED_LIST(in, individual_form, cl->listed)
		if (in->form_number == number_sought)
			return Clusters::get_nominative_of_form(in);
	return EMPTY_WORDING;
}

@ The following variant finds the earliest form in the language of play,
falling back on English if there's none registered:

=
wording Clusters::get_form_in_language(lexical_cluster *cl, int plural_flag,
	NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	int number_sought = 1;
	if (plural_flag) number_sought = 2;
	individual_form *in;
	LOOP_OVER_LINKED_LIST(in, individual_form, cl->listed)
		if ((in->form_number == number_sought) &&
			(in->form_language == nl))
			return Clusters::get_nominative_of_form(in);
	return Clusters::get_form(cl, plural_flag);
}

@ A more specific search, which can optionally test for number and gender.

=
wording Clusters::get_form_general(lexical_cluster *cl,
	NATURAL_LANGUAGE_WORDS_TYPE *nl, int number_sought, int gender_sought) {
	individual_form *in;
	LOOP_OVER_LINKED_LIST(in, individual_form, cl->listed)
		if (((number_sought == -1) || (number_sought == in->form_number)) &&
			((gender_sought == -1) || (gender_sought == in->form_gender)) &&
			(in->form_language == nl))
			return Clusters::get_nominative_of_form(in);
	return EMPTY_WORDING;
}

@ All of which use:

=
wording Clusters::get_nominative_of_form(individual_form *in) {
	return Declensions::in_case(&(in->declined), NOMINATIVE_CASE);
}
