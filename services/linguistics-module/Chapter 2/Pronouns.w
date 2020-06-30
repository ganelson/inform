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

@ The stock of pronouns is fixed at three:

=
grammatical_category *pronouns_category = NULL;
pronoun *subject_pronoun = NULL;
pronoun *object_pronoun = NULL;
pronoun *possessive_pronoun = NULL;

void Pronouns::create_category(void) {
	pronouns_category = Stock::new_category(I"pronoun");
	METHOD_ADD(pronouns_category, LOG_GRAMMATICAL_CATEGORY_MTID, Pronouns::log_item);
	subject_pronoun = Pronouns::new(I"subject pronoun");
	object_pronoun = Pronouns::new(I"object pronoun");
	possessive_pronoun = Pronouns::new(I"possessive pronoun");
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

@h Stock references.
We ignore case and gender in pronouns, but do take note of number and person.

=
lcon_ti Pronouns::use(pronoun *P, int n, int p) {
	lcon_ti lcon = Stock::to_lcon(P->in_stock);
	lcon = Lcon::set_person(lcon, p);
	lcon = Lcon::set_number(lcon, n);
	return lcon;
}

pronoun *Pronouns::from_lcon(lcon_ti lcon) {
	linguistic_stock_item *item = Stock::from_lcon(lcon);
	if (item == NULL) return NULL;
	return RETRIEVE_POINTER_pronoun(item->data);
}

void Pronouns::write_lcon(OUTPUT_STREAM, lcon_ti lcon) {
	pronoun *P = Pronouns::from_lcon(lcon);
	WRITE(" %S ", P->name);
	switch (Lcon::get_person(lcon)) {
		case FIRST_PERSON: WRITE("1p"); break;
		case SECOND_PERSON: WRITE("2p"); break;
		case THIRD_PERSON: WRITE("3p"); break;
	}
	switch (Lcon::get_number(lcon)) {
		case SINGULAR_NUMBER: WRITE("s"); break;
		case PLURAL_NUMBER: WRITE("p"); break;
	}
}

@h English pronouns.
Rather than giving pronouns declensions as if they were nouns, we store their
different forms in Preform grammar directly, as follows.

=
<subject-pronoun> ::=
	<subject-pronoun-first-person> |   ==> R[1]
	<subject-pronoun-second-person> |  ==> R[1]
	<subject-pronoun-third-person>     ==> R[1]

<subject-pronoun-first-person> ::=
	i |           ==> Pronouns::use(subject_pronoun, SINGULAR_NUMBER, FIRST_PERSON)
	we            ==> Pronouns::use(subject_pronoun, PLURAL_NUMBER, FIRST_PERSON)

<subject-pronoun-second-person> ::=
	you |         ==> Pronouns::use(subject_pronoun, SINGULAR_NUMBER, SECOND_PERSON)
	you           ==> Pronouns::use(subject_pronoun, PLURAL_NUMBER, SECOND_PERSON)

<subject-pronoun-third-person> ::=
	it/he/she |   ==> Pronouns::use(subject_pronoun, SINGULAR_NUMBER, THIRD_PERSON)
	they          ==> Pronouns::use(subject_pronoun, PLURAL_NUMBER, THIRD_PERSON)

@

=
<object-pronoun> ::=
	<object-pronoun-first-person> |   ==> R[1]
	<object-pronoun-second-person> |  ==> R[1]
	<object-pronoun-third-person>     ==> R[1]

<object-pronoun-first-person> ::=
	me |          ==> Pronouns::use(object_pronoun, SINGULAR_NUMBER, FIRST_PERSON)
	us            ==> Pronouns::use(object_pronoun, PLURAL_NUMBER, FIRST_PERSON)

<object-pronoun-second-person> ::=
	you |         ==> Pronouns::use(object_pronoun, SINGULAR_NUMBER, SECOND_PERSON)
	you           ==> Pronouns::use(object_pronoun, PLURAL_NUMBER, SECOND_PERSON)

<object-pronoun-third-person> ::=
	it/him/her |  ==> Pronouns::use(object_pronoun, SINGULAR_NUMBER, THIRD_PERSON)
	them          ==> Pronouns::use(object_pronoun, PLURAL_NUMBER, THIRD_PERSON)

@

=
<possessive-pronoun> ::=
	<possessive-first-person> |   ==> R[1]
	<possessive-second-person> |  ==> R[1]
	<possessive-third-person>     ==> R[1]

<possessive-first-person> ::=
	my |          ==> Pronouns::use(possessive_pronoun, SINGULAR_NUMBER, FIRST_PERSON)
	our           ==> Pronouns::use(possessive_pronoun, PLURAL_NUMBER, FIRST_PERSON)

<possessive-second-person> ::=
	your |        ==> Pronouns::use(possessive_pronoun, SINGULAR_NUMBER, SECOND_PERSON)
	your          ==> Pronouns::use(possessive_pronoun, PLURAL_NUMBER, SECOND_PERSON)

<possessive-third-person> ::=
	its/his/her | ==> Pronouns::use(possessive_pronoun, SINGULAR_NUMBER, THIRD_PERSON)
	their         ==> Pronouns::use(possessive_pronoun, PLURAL_NUMBER, THIRD_PERSON)
