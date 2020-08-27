[Nouns::] Nouns.

To create noun objects, each of which represents a single common or proper noun
which may have multiple inflected forms.

@h A noun is more than a lexical cluster.
Consider the line:

>> A mammal is a kind of animal.

Inform generates a new noun from this line: "mammal". This may well occur
in a variety of inflected forms (though in English, there will be just two:
"mammal" and "mammals"). That set of forms is gathered into a |lexical_cluster|
object: see //inflections: Lexical Clusters//. Lexical clusters are not necessarily
of nouns -- they are also used for adjectives, for example. So it would be
wrong to represent a noun by a lexical cluster alone.

Inform instead attaches a //noun// object to the new "mammal" kind. This object
contains the lexical cluster to define its syntax, but it also has semantics attached.

@ From a linguistic point of view, the class of nouns can be divided into two
subclasses: common nouns and proper nouns. "Mammal" is a common noun, whereas
a sentence such as:

>> A carved oak table is here.

...creates a proper noun, "carved oak table". Nouns are not used only to
refer to the model world of some interactive fiction, though: Inform uses
common nouns for kinds of value, such as "number", and proper nouns for
all sorts of specific but abstract things created in a program: activities,
rulebooks and tables, for example.

What we will call the "subclass" of the noun is always one of these values:

@d COMMON_NOUN 1
@d PROPER_NOUN 2

@ The other semantic ingredient in a //noun// object is a pointer to some
object which gives it a meaning. For example, for the "carved oak table" in
the Inform example above that would be an |instance| object representing this
piece of furniture in the model world.

It might seem the wrong way around for the //noun// object to contain its
meaning -- like saying that a luggage tag has a suitcase hanging from it,
rather than vice versa. But this enables the lexicon to return a //noun//
as the result of parsing some text, or more accurately a //noun_usage//
which points to a //noun//. That in turn means that the lexicon's results
can convey some linguistic data as well as the actual meaning -- e.g., it
can say not only "this text refers to X" but also "this text is in the
feminine accusative plural".

=
typedef struct noun {
	struct lexical_cluster *names;
	int noun_subclass; /* either |COMMON_NOUN| or |PROPER_NOUN| */
	struct general_pointer meaning;
	unsigned int registration_category;
	struct linguistic_stock_item *in_stock;

	#ifdef NOUN_COMPILATION_LINGUISTICS_CALLBACK
	struct name_compilation_data name_compilation;
	#endif
	#ifdef NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK
	struct name_resolution_data name_resolution;
	#endif

	CLASS_DEFINITION
} noun;

@ A //noun_usage// object is what a lexicon search returns when text is matched
against some form of a noun.

=
typedef struct noun_usage {
	struct noun *noun_used;
	struct grammatical_usage *usage;
	CLASS_DEFINITION
} noun_usage;

@ =
void Nouns::write_usage(OUTPUT_STREAM, noun_usage *nu) {
	if (nu->noun_used->noun_subclass == COMMON_NOUN) WRITE(" {common");
	if (nu->noun_used->noun_subclass == PROPER_NOUN) WRITE(" {proper");
	Stock::write_usage(OUT, nu->usage, GENDER_LCW+NUMBER_LCW+CASE_LCW);
	WRITE("}");
}

@ Nouns are a grammatical category:

=
grammatical_category *nouns_category = NULL;
void Nouns::create_category(void) {
	nouns_category = Stock::new_category(I"noun");
	METHOD_ADD(nouns_category, LOG_GRAMMATICAL_CATEGORY_MTID, Nouns::log_item);
}

void Nouns::log_item(grammatical_category *cat, general_pointer data) {
	noun *N = RETRIEVE_POINTER_noun(data);
	if (N->noun_subclass == COMMON_NOUN) LOG("common: "); else LOG("proper: ");
	Nouns::log(N);
}

@h Creation.
The following functions are called to create new proper or common nouns, and
note that:
(i) It is legal for the supplied text to be empty, and this does happen
for example when Inform creates the nouns of anonymous objects, as in a
sentence such as "Four people are in the Dining Room." Empty text in |W| means
that no forms are added to the lexical cluster and nothing is registered with
the lexicon.
(ii) The |options| are a bitmap which used to be larger, and is now reduced
to a combination of just two possibilities:

@d ADD_TO_LEXICON_NTOPT 1         /* register these forms with the lexicon */
@d WITH_PLURAL_FORMS_NTOPT 2      /* add plurals to the forms known */

=
noun *Nouns::new_proper_noun(wording W, int gender, int options,
	unsigned int mc, parse_node *val, NATURAL_LANGUAGE_WORDS_TYPE *lang) {
	general_pointer owner = NULL_GENERAL_POINTER;
	if (val) owner = STORE_POINTER_parse_node(val);
	return Nouns::new_inner(W, owner, PROPER_NOUN, options, mc, lang, gender);
}

noun *Nouns::new_common_noun(wording W, int gender, int options,
	unsigned int mc, general_pointer owner, NATURAL_LANGUAGE_WORDS_TYPE *lang) {
	return Nouns::new_inner(W, owner, COMMON_NOUN, options, mc, lang, gender);
}

@ Each using:

=
noun *Nouns::new_inner(wording W, general_pointer owner, int p, int options,
	unsigned int mc, NATURAL_LANGUAGE_WORDS_TYPE *lang, int gender) {
	noun *N = CREATE(noun);
	N->meaning = owner;
	N->registration_category = mc;
	N->noun_subclass = p;
	N->names = Clusters::new();
	N->in_stock = Stock::new(nouns_category, STORE_POINTER_noun(N));

	if (Wordings::nonempty(W)) Nouns::supply_text(N, W, lang, gender, SINGULAR_NUMBER, options);

	#ifdef NOUN_COMPILATION_LINGUISTICS_CALLBACK
	NOUN_COMPILATION_LINGUISTICS_CALLBACK(N);
	#endif
	return N;
}

@h Subclass.

=
int Nouns::subclass(noun *N) {
	if (N == NULL) return 0;
	return N->noun_subclass;
}

int Nouns::is_proper(noun *N) {
	if ((N) && (N->noun_subclass == PROPER_NOUN)) return TRUE;
	return FALSE;
}

int Nouns::is_common(noun *N) {
	if ((N) && (N->noun_subclass == COMMON_NOUN)) return TRUE;
	return FALSE;
}

@h Logging.

=
void Nouns::log(noun *N) {
	Nouns::write(DL, N);
}

void Nouns::write(OUTPUT_STREAM, noun *N) {
	if (N == NULL) { WRITE("<untagged>"); return; }
	wording W = Nouns::nominative_singular(N);
	if (Wordings::nonempty(W)) WRITE("'%W'", W);
}

@h Attaching some wording to a noun.
As noted above, each noun comes with a cluster of names, and here's where
we add a new one.

=
void Nouns::supply_text(noun *N, wording W, NATURAL_LANGUAGE_WORDS_TYPE *lang,
	int gender, int number, int options) {
	linked_list *L = Clusters::add(N->names, W, lang, gender, number,
		(options & WITH_PLURAL_FORMS_NTOPT)?TRUE:FALSE);
	if (options & ADD_TO_LEXICON_NTOPT) {
		individual_form *in;
		LOOP_OVER_LINKED_LIST(in, individual_form, L)
			@<Register each distinct declined form of the noun@>;
	}
}

@ See the discussion of noun usages above. The idea is that if our form is,
say, the German plural form of "Tisch", then the declension of that would be
"Tische", "Tische", "Tischen", "Tische": we group these into two registrations,
"Tische" (with possible forms nominative, accusative, genitive) and "Tischen"
(just dative).

@<Register each distinct declined form of the noun@> =
	int c = Declensions::no_cases(lang);
	int done[MAX_GRAMMATICAL_CASES];
	for (int i=0; i<c; i++) done[i] = FALSE;
	for (int i=0; i<c; i++) if (done[i] == FALSE) {
		noun_usage *nu = CREATE(noun_usage);
		nu->noun_used = N;
		nu->usage = Stock::new_usage(N->in_stock, lang);
		wording W = Declensions::in_case(&(in->declined), i);
		for (int j=0; j<c; j++)
			if (Wordings::match_cs(W, Declensions::in_case(&(in->declined), j))) {
				done[j] = TRUE;
				Stock::add_form_to_usage(nu->usage, in->declined.lcon_cased[j]);
			}
		Lexicon::register(N->registration_category, W, STORE_POINTER_noun_usage(nu));				
	}

@h Name access.
We normally access names in their nominative cases, so:

=
wording Nouns::nominative_singular(noun *N) {
	if (N == NULL) return EMPTY_WORDING;
	return Clusters::get_form(N->names, FALSE);
}

int Nouns::nominative_singular_includes(noun *N, vocabulary_entry *wd) {
	if (N == NULL) return FALSE;
	wording W = Nouns::nominative_singular(N);
	LOOP_THROUGH_WORDING(i, W)
		if (wd == Lexer::word(i))
			return TRUE;
	return FALSE;
}

wording Nouns::nominative(noun *N, int plural_flag) {
	return Clusters::get_form(N->names, plural_flag);
}

wording Nouns::nominative_in_language(noun *N, int plural_flag,
	NATURAL_LANGUAGE_WORDS_TYPE *lang) {
	return Clusters::get_form_in_language(N->names, plural_flag, lang);
}

void Nouns::set_nominative_plural_in_language(noun *N, wording W,
	NATURAL_LANGUAGE_WORDS_TYPE *lang) {
	Clusters::set_plural_in_language(N->names, W, lang);
}

@h Meaning.

=
general_pointer Nouns::meaning(noun *N) {
	if (N == NULL) return NULL_GENERAL_POINTER;
	return N->meaning;
}

@h Disambiguation.
Here the parse node |p| stands at the head of a list of alternative meanings
for some text: for example, they might be different possible meanings of the
words "red chair" -- perhaps the "red stuffed chair", perhaps the "red upright
chair", and so on. We want to choose the most likely possibility.

Within Inform, this "likely" consideration is a matter of context -- of which
heading the noun appears under.

=
noun_usage *Nouns::disambiguate(parse_node *p, int common_only) {
	noun_usage *first_nt = NULL;
	@<If only one of the possible matches is eligible, return that@>;
	@<If the matches can be scored, return the highest-scoring one@>;
	/* and otherwise... */
	return first_nt;
}

@<If only one of the possible matches is eligible, return that@> =
	int candidates = 0; 
	for (parse_node *p2 = p; p2; p2 = p2->next_alternative) {
		noun_usage *nu = Nouns::usage_from_excerpt_meaning(Node::get_meaning(p2));
		if (Nouns::is_eligible_match(nu->noun_used, common_only)) {
			first_nt = nu; candidates++;
		}
	}
	if (candidates <= 1) return first_nt;

@<If the matches can be scored, return the highest-scoring one@> =
	#ifdef NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK
	noun_usage *best_nt = NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK(p, common_only);
	if (best_nt) return best_nt;
	#endif

@ =
int Nouns::is_eligible_match(noun *nt, int common_only) {
	if ((common_only) && (Nouns::is_common(nt) == FALSE)) return FALSE;
	return TRUE;
}

@h Actual usage.

=
void Nouns::recognise(parse_node *p) {
	parse_node *q = Lexicon::retrieve(NOUN_MC, Node::get_text(p));
	if (q) Nouns::set_node_to_be_usage_of_noun(p, Nouns::disambiguate(q, FALSE));
}

void Nouns::set_node_to_be_usage_of_noun(parse_node *p, noun_usage *nu) {
	if (nu->noun_used->noun_subclass == COMMON_NOUN)
		Node::set_type(p, COMMON_NOUN_NT);
	else
		Node::set_type(p, PROPER_NOUN_NT);
	Node::set_noun(p, nu);
}

noun *Nouns::from_excerpt_meaning(excerpt_meaning *em) {
	noun_usage *nu = RETRIEVE_POINTER_noun_usage(Lexicon::get_data(em));
	return nu->noun_used;
}

noun_usage *Nouns::usage_from_excerpt_meaning(excerpt_meaning *em) {
	noun_usage *nu = RETRIEVE_POINTER_noun_usage(Lexicon::get_data(em));
	return nu;
}

@ The following function is so called because Inform registers many constant
values as nouns -- for example, each rulebook name is a noun, and the meaning
of that is a valid rvalue in the compiler sense; it's a value which can be
computed with at run-time. Inform represents rvalues as sprigs of the parse
tree, so this function returns a |parse_node|.

@d PN_FROM_EM_LEXICON_CALLBACK Nouns::extract_noun_as_rvalue

=
parse_node *Nouns::extract_noun_as_rvalue(excerpt_meaning *em) {
	general_pointer m = Lexicon::get_data(em);
	if (VALID_POINTER_noun_usage(m)) {
		noun_usage *nu = RETRIEVE_POINTER_noun_usage(m);
		m = nu->noun_used->meaning;
	}
	parse_node *this_result;
	if (VALID_POINTER_parse_node(m)) {
		parse_node *val = RETRIEVE_POINTER_parse_node(m);
		this_result = Node::new(INVALID_NT);
		Node::copy(this_result, val);
	} else {
		this_result = Node::new(em->meaning_code);
	}
	Node::set_meaning(this_result, em);
	return this_result;
}
