[Adjectives::] Adjectives.

To create adjective objects, each of which represents a single adjective
which may have multiple inflected forms and meanings.

@h An adjective is only a lexical cluster.
We represent adjectives like "empty" with //adjective// objects. The only
linguistic data in these objects is the lexical cluster for its wordings,
possibly in multiple languages. These allow adjectives to have inflected
forms, though this never really arises in English. (Let's not argue about
the word "blond"/"blonde", the only counterexample anybody ever brings up.)

Beyond that, an //adjective// object simply contains two convenient hooks
for the user of this module to attach semantics to an adjective. For how
Inform does this, see //core: Adjective Meanings//.

= 
typedef struct adjective {
	struct lexical_cluster *adjective_names;
	struct linguistic_stock_item *in_stock;

	#ifdef ADJECTIVE_COMPILATION_LINGUISTICS_CALLBACK
	struct adjective_compilation_data adjective_compilation;
	#endif
	#ifdef ADJECTIVE_MEANING_LINGUISTICS_CALLBACK
	struct adjective_meaning_data adjective_meanings;
	#endif

	CLASS_DEFINITION
} adjective;

@ Adjectives are a grammatical category:

=
grammatical_category *adjectives_category = NULL;
void Adjectives::create_category(void) {
	adjectives_category = Stock::new_category(I"adjective");
	METHOD_ADD(adjectives_category, LOG_GRAMMATICAL_CATEGORY_MTID, Adjectives::log_item);
}

void Adjectives::log_item(grammatical_category *cat, general_pointer data) {
	adjective *adj = RETRIEVE_POINTER_adjective(data);
	Adjectives::log(adj);
}

adjective *Adjectives::from_lcon(lcon_ti lcon) {
	linguistic_stock_item *item = Stock::from_lcon(lcon);
	if (item == NULL) return NULL;
	return RETRIEVE_POINTER_adjective(item->data);
}

@h Creation.
The following declares a new adjective, creating it only if it does not
already exist.

=
adjective *Adjectives::declare(wording W, NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	adjective *adj;
	LOOP_OVER(adj, adjective) {
		wording C = Clusters::get_form_in_language(adj->adjective_names, FALSE, nl);
		if (Wordings::match(C, W)) return adj;
	}
	adj = NULL;
	if (Wordings::nonempty(W)) adj = Adjectives::parse(W);
	if (adj) return adj;
	adj = CREATE(adjective);
	adj->adjective_names = Clusters::new();
	Clusters::add_with_agreements(adj->adjective_names, W, nl);
	#ifdef ADJECTIVE_MEANING_LINGUISTICS_CALLBACK
	ADJECTIVE_MEANING_LINGUISTICS_CALLBACK(adj);
	#endif
	#ifdef ADJECTIVE_COMPILATION_LINGUISTICS_CALLBACK
	ADJECTIVE_COMPILATION_LINGUISTICS_CALLBACK(adj);
	#endif
	@<Register the new adjective with the lexicon module@>;
	adj->in_stock = Stock::new(adjectives_category, STORE_POINTER_adjective(adj));
	return adj;
}

@ It's very important for performance that parsing adjective names can be
done quickly, so we use the lexicon's optimisation code to mark all words
occurring in any known adjective. Whereas nouns are registered with the
lexicon under any number of different meaning codes, adjectives are always
registered under |ADJECTIVE_MC|.

@<Register the new adjective with the lexicon module@> =
	if ((nl == NULL) && (Wordings::nonempty(W))) {
		#ifdef ADJECTIVE_NAME_VETTING_LINGUISTICS_CALLBACK
		if (ADJECTIVE_NAME_VETTING_LINGUISTICS_CALLBACK(W)) {
		#endif
			Lexicon::register(ADJECTIVE_MC, W, STORE_POINTER_adjective(adj));
			LOOP_THROUGH_WORDING(n, W) NTI::mark_word(n, <adjective-name>);
		#ifdef ADJECTIVE_NAME_VETTING_LINGUISTICS_CALLBACK
		}
		#endif
	}

@ =
wording Adjectives::get_nominative_singular(adjective *adj) {
	return Clusters::get_form(adj->adjective_names, FALSE);
}

@h Parsing adjectives.
This does what its name suggests: matches the name of any adjective known to
Inform. By construction there is only one |adjective| for any given excerpt of
text, so the following is unambiguous:

=
<adjective-name> internal {
	parse_node *p = Lexicon::retrieve(ADJECTIVE_MC, W);
	if (p) {
		adjective *adj = RETRIEVE_POINTER_adjective(Lexicon::get_data(Node::get_meaning(p)));
		==> {-, adj};
		return TRUE;
	}
	==> { fail nonterminal };
}

@ Wrapping which:

=
adjective *Adjectives::parse(wording W) {
	if (<adjective-name>(W)) return <<rp>>;
	return NULL;
}

@h Testing agreement.
This is used in unit testing.

=
void Adjectives::test_adjective(OUTPUT_STREAM, wording W) {
	adjective *adj = Adjectives::declare(W, NULL);
	if (adj == NULL) { WRITE("Failed test\n"); return; }
	for (int g = NEUTER_GENDER; g <= FEMININE_GENDER; g++) {
		switch (g) {
			case NEUTER_GENDER: WRITE("neuter "); break;
			case MASCULINE_GENDER: WRITE("masculine "); break;
			case FEMININE_GENDER: WRITE("feminine "); break;
		}
		for (int n = 1; n <= 2; n++) {
			if (n == 1) WRITE("singular: "); else WRITE(" / plural: ");
			wording C = Clusters::get_form_general(adj->adjective_names,
				NULL, n, g);
			WRITE("%W", C);
		}
		WRITE("^");
	}
}

@h Logging.
To identify an adjective in the debugging log:

=
void Adjectives::log(adjective *adj) {
	Adjectives::write(DL, adj);
}
void Adjectives::write(OUTPUT_STREAM, adjective *adj) {
	if (adj == NULL) { WRITE("<null adjectival phrase>"); return; }
	wording W = Adjectives::get_nominative_singular(adj);
	WRITE("'%W'", W);
}
