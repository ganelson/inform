[Pronouns::] Pronouns.

Preform grammar for the pronouns.

@h Pronouns.
Pronouns are an awkward grammatical category. They are words standing in place
of, or somehow referring to, nouns not explicitly given. But they do not always
function as nouns (possessive pronouns are more like determiners), and we give
them their own category rather than making them into a special //noun// object.

Pronoun objects contain no interesting data: in effect, the //pronoun// class
is an enumeration.

=
typedef struct pronoun {
	struct text_stream *name;
	struct linguistic_stock_item *in_stock;

	CLASS_DEFINITION
} pronoun;

@ A //pronoun_usage// object is what a lexicon search returns when text is
matched against some form of a pronoun.

=
typedef struct pronoun_usage {
	struct pronoun *pronoun_used;
	struct grammatical_usage *usage;
	CLASS_DEFINITION
} pronoun_usage;

@ =
void Pronouns::write_usage(OUTPUT_STREAM, pronoun_usage *pu) {
	WRITE(" {%S", pu->pronoun_used->name);
	Stock::write_usage(OUT, pu->usage, PERSON_LCW + GENDER_LCW + NUMBER_LCW + CASE_LCW);
	WRITE("}");
}

@ The stock of pronouns is fixed, as follows. We are going to regard the three
persons as being different pronouns, since they make different references,
though not every grammarian would agree. So we have three "agent pronouns" --
those standing for subject or object -- and then three possessives, and "here",
which stands in the place of a noun referring to a location, and is thus also
a pronoun.

=
grammatical_category *pronouns_category = NULL;
pronoun *first_person_pronoun = NULL;
pronoun *second_person_pronoun = NULL;
pronoun *third_person_pronoun = NULL;
pronoun *first_person_possessive_pronoun = NULL;
pronoun *second_person_possessive_pronoun = NULL;
pronoun *third_person_possessive_pronoun = NULL;
pronoun *here_pronoun = NULL;
pronoun *implied_pronoun = NULL;

void Pronouns::create_category(void) {
	pronouns_category = Stock::new_category(I"pronoun");
	METHOD_ADD(pronouns_category, LOG_GRAMMATICAL_CATEGORY_MTID, Pronouns::log_item);
	first_person_pronoun = Pronouns::new(I"first person pronoun");
	second_person_pronoun = Pronouns::new(I"second person pronoun");
	third_person_pronoun = Pronouns::new(I"third person pronoun");
	first_person_possessive_pronoun = Pronouns::new(I"first person possessive pronoun");
	second_person_possessive_pronoun = Pronouns::new(I"second person possessive pronoun");
	third_person_possessive_pronoun = Pronouns::new(I"third person possessive pronoun");
	here_pronoun = Pronouns::new(I"location pronoun");
	implied_pronoun = Pronouns::new(I"implied pronoun");
}

pronoun *Pronouns::new(text_stream *name) {
	pronoun *P = CREATE(pronoun);
	P->name = Str::duplicate(name);
	P->in_stock = Stock::new(pronouns_category, STORE_POINTER_pronoun(P));
	return P;
}

void Pronouns::log_item(grammatical_category *cat, general_pointer data) {
	pronoun *P = RETRIEVE_POINTER_pronoun(data);
	LOG("%S", P->name);
}

@h Parsing.
Pronouns are ideal for small word sets, because even when their tables of
inflected forms are in theory large, there are in practice few distinguishable
words in them. For example, there are in theory twelve second-person pronouns
in English, but all twelve of them are "you".

The following sets turn out to be convenient for parsing purposes, but it
would be easy to form other subsets of the pronouns.

=
small_word_set *pronouns_sws = NULL, /* all agent pronouns of any case */
	*subject_pronouns_sws = NULL, /* just those in the nominative */
	*object_pronouns_sws = NULL; /* just those in the accusative */

small_word_set *possessive_pronouns_sws = NULL, /* all possessive pronouns of any person */
	*first_person_possessive_pronouns_sws = NULL,
	*second_person_possessive_pronouns_sws = NULL,
	*third_person_possessive_pronouns_sws = NULL;

small_word_set *here_pronouns_sws = NULL;

pronoun_usage *implied_pronoun_usage = NULL;

pronoun_usage *Pronouns::get_implied(void) {
	return implied_pronoun_usage;
}

@ And now we have to make them. The following capacity would be enough even if
we were simultaneously dealing with four languages in which every inflection
produced a different word. So it really is not going to run out.

@d PRONOUN_SWS_CAPACITY 4*NO_KNOWN_GENDERS*NO_KNOWN_NUMBERS*MAX_GRAMMATICAL_CASES

=
void Pronouns::create_small_word_sets(void) {
	pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(pronouns_sws, <first-person-pronoun-table>,
		-1, FIRST_PERSON, first_person_pronoun);
	Pronouns::add(pronouns_sws, <second-person-pronoun-table>,
		-1, SECOND_PERSON, second_person_pronoun);
	Pronouns::add(pronouns_sws, <third-person-pronoun-table>,
		-1, THIRD_PERSON, third_person_pronoun);

	subject_pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(subject_pronouns_sws, <first-person-pronoun-table>,
		NOMINATIVE_CASE, FIRST_PERSON, first_person_pronoun);
	Pronouns::add(subject_pronouns_sws, <second-person-pronoun-table>,
		NOMINATIVE_CASE, SECOND_PERSON, second_person_pronoun);
	Pronouns::add(subject_pronouns_sws, <third-person-pronoun-table>,
		NOMINATIVE_CASE, THIRD_PERSON, third_person_pronoun);

	object_pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(object_pronouns_sws, <first-person-pronoun-table>,
		ACCUSATIVE_CASE, FIRST_PERSON, first_person_pronoun);
	Pronouns::add(object_pronouns_sws, <second-person-pronoun-table>,
		ACCUSATIVE_CASE,  SECOND_PERSON, second_person_pronoun);
	Pronouns::add(object_pronouns_sws, <third-person-pronoun-table>,
		ACCUSATIVE_CASE, THIRD_PERSON, third_person_pronoun);

	possessive_pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(possessive_pronouns_sws, <first-person-possessive-pronoun-table>,
		-1, FIRST_PERSON, first_person_possessive_pronoun);
	Pronouns::add(possessive_pronouns_sws, <second-person-possessive-pronoun-table>,
		-1, SECOND_PERSON, second_person_possessive_pronoun);
	Pronouns::add(possessive_pronouns_sws, <third-person-possessive-pronoun-table>,
		-1, THIRD_PERSON, third_person_possessive_pronoun);

	first_person_possessive_pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(first_person_possessive_pronouns_sws, <first-person-possessive-pronoun-table>,
		-1, FIRST_PERSON, first_person_possessive_pronoun);

	second_person_possessive_pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(second_person_possessive_pronouns_sws, <second-person-possessive-pronoun-table>,
		-1, SECOND_PERSON, second_person_possessive_pronoun);

	third_person_possessive_pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(third_person_possessive_pronouns_sws, <third-person-possessive-pronoun-table>,
		-1, THIRD_PERSON, third_person_possessive_pronoun);
		
	here_pronouns_sws = Stock::new_sws(PRONOUN_SWS_CAPACITY);
	Pronouns::add(here_pronouns_sws, <here-pronoun-table>,
		-1, THIRD_PERSON, here_pronoun);

	implied_pronoun_usage = CREATE(pronoun_usage);
	implied_pronoun_usage->pronoun_used = implied_pronoun;
	implied_pronoun_usage->usage = Stock::new_usage(implied_pronoun->in_stock, NULL);	
}

@ All of which use the following, which extracts inflected forms from the
nonterminal tables (see below for their English versions and layout).

=
small_word_set *Pronouns::add(small_word_set *sws, nonterminal *nt, int filter_case,
	int person, pronoun *p) {
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		int c = 0;
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
			if ((filter_case < 0) || (filter_case == c)) {
				int t = 0;
				for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt) {
					for (ptoken *alt = pt; alt; alt = alt->alternative_ptoken) {
						if (alt->ptoken_category != FIXED_WORD_PTC)
							PreformUtilities::production_error(nt, pr,
								"pronoun sets must contain single fixed words");
						else {
							pronoun_usage *pu =
								(pronoun_usage *) Stock::find_in_sws(sws, alt->ve_pt);
							if (pu == NULL) {
								pu = CREATE(pronoun_usage);
								pu->pronoun_used = p;
								pu->usage = Stock::new_usage(p->in_stock, NULL);
								Stock::add_to_sws(sws, alt->ve_pt, pu);
							}
							lcon_ti lcon = Stock::to_lcon(p->in_stock);
							lcon = Lcon::set_number(lcon, t%2);
							lcon = Lcon::set_gender(lcon, 1 + t/2);
							lcon = Lcon::set_case(lcon, c);
							lcon = Lcon::set_person(lcon, person);
							Stock::add_form_to_usage(pu->usage, lcon);
						}
					}
					t++;
				}
			}
			c++;
		}
		if (c != Declensions::no_cases(pl->definition_language))
			PreformUtilities::production_error(nt, NULL,
				"wrong number of cases in pronoun set");
	}
	return sws;
}

@ The following, then, parse pronouns simply by testing whether the word being
parsed lies in the relevant small word set.

=
<agent-pronoun> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

<subject-pronoun> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(subject_pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

<object-pronoun> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(object_pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

<possessive-pronoun> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(possessive_pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

<possessive-first-person> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(first_person_possessive_pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

<possessive-second-person> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(second_person_possessive_pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

<possessive-third-person> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(third_person_possessive_pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

<here-pronoun> internal 1 {
	if (pronouns_sws == NULL) Pronouns::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	pronoun_usage *pu = Stock::find_in_sws(here_pronouns_sws, ve);
	if (pu) { ==> { 0, pu }; return TRUE; }
	==> { fail nonterminal };
}

@h English pronouns.
So, then, these nonterminals are not parsed by Preform but are instead used
to stock small word sets above.

Each row represents one case: so for English, there are two rows, nominative
(i.e. for subject pronouns) and then accusative (object). Within a row, the
sequence is neuter singular, neuter plural, masculine singular, masculine plural,
feminine singular, feminine plural.

=
<first-person-pronoun-table> ::=
	i we i we i we |
	me us me us me us

<second-person-pronoun-table> ::=
	you you you you you you |
	you you you you you you

<third-person-pronoun-table> ::=
	it they he they she they |
	it them him them her them

<first-person-possessive-pronoun-table> ::=
	my our my our my our |
	my our my our my our

<second-person-possessive-pronoun-table> ::=
	your your your your your your |
	your your your your your your

<third-person-possessive-pronoun-table> ::=
	its their his their her their |
	its their his their her their

<here-pronoun-table> ::=
	here here here here here here |
	here here here here here here

@h Unit testing.
The //linguistics-test// test case |pronouns| calls this.

=
void Pronouns::test(OUTPUT_STREAM) {
	WRITE("pronouns_sws:\n");
	Pronouns::write_sws(OUT, pronouns_sws);
	WRITE("subject_pronouns_sws:\n");
	Pronouns::write_sws(OUT, subject_pronouns_sws);
	WRITE("object_pronouns_sws:\n");
	Pronouns::write_sws(OUT, object_pronouns_sws);
	WRITE("possessive_pronouns_sws:\n");
	Pronouns::write_sws(OUT, possessive_pronouns_sws);
	WRITE("first_person_possessive_pronouns_sws:\n");
	Pronouns::write_sws(OUT, first_person_possessive_pronouns_sws);
	WRITE("second_person_possessive_pronouns_sws:\n");
	Pronouns::write_sws(OUT, second_person_possessive_pronouns_sws);
	WRITE("third_person_possessive_pronouns_sws:\n");
	Pronouns::write_sws(OUT, third_person_possessive_pronouns_sws);
}

void Pronouns::write_sws(OUTPUT_STREAM, small_word_set *sws) {
	for (int i=0; i<sws->used; i++) {
		WRITE("(%d) %V:", i, sws->word_ve[i]);
		pronoun_usage *pu = (pronoun_usage *) sws->results[i];
		Pronouns::write_usage(OUT, pu);
		WRITE("\n");
	}
}
