[Adjectives::] Adjectives.

To record the names of all adjectives.

@h Adjectives are not their meanings.
Adjectives are simpler than verbs, since they define unary rather than
binary predicates. The word "open" applies to only one term -- logically, we
regard it as |open(x)|, whereas a verb like "suspects" would appear
in formulae as |suspects(x, y)|.

But they are nevertheless complicated enough to have multiple meanings. For
instance, two of the senses of "empty" in the Standard Rules are:

>> Definition: a text is empty rather than non-empty if it is "".

>> Definition: a table name is empty rather than non-empty if the number of filled rows in it is 0.

(Which also defines two of the senses of "non-empty", another adjective.)
The clause |empty(x)| can be fully understood only when we know what
kind of value x has; for a text, the first sense applies, and for a table
name, the second.

Adjectives may also need to inflect, though not in English. (Let's not argue
about the word "blond"/"blonde", which is the only counterexample anybody
ever brings up.)

@h Adjectival phrases.
Because of this we need a structure to represent an adjective as
distinct from its meaning, and this is it.

@default ADJECTIVE_MEANING_TYPE void

=
typedef struct adjectival_phrase {
	struct name_cluster *adjective_names;
	#ifdef CORE_MODULE
	struct inter_name *aph_iname;
	struct package_request *aph_package;
	#endif
	ADJECTIVE_MEANING_TYPE *meanings;
	CLASS_DEFINITION
} adjectival_phrase;

@ The following declares a new adjective, creating it only if necessary:

=
adjectival_phrase *Adjectives::declare(wording W, PREFORM_LANGUAGE_TYPE *nl) {
	adjectival_phrase *aph;
	LOOP_OVER(aph, adjectival_phrase) {
		wording C = Clusters::get_name_in_play(aph->adjective_names, FALSE, nl);
		if (Wordings::match(C, W)) return aph;
	}
	return Adjectives::from_word_range(W, nl);
}

@ Whereas this simply creates it:

=
adjectival_phrase *Adjectives::from_word_range(wording W, PREFORM_LANGUAGE_TYPE *nl) {
	adjectival_phrase *aph = NULL;
	if (Wordings::nonempty(W)) aph = Adjectives::parse(W);
	if (aph) return aph;
	aph = CREATE(adjectival_phrase);
	aph->adjective_names = Clusters::new();
	Clusters::add_with_agreements(aph->adjective_names, W, nl);
	aph->meanings = NULL;
	#ifdef EMPTY_ADJECTIVE_MEANING
	aph->meanings = EMPTY_ADJECTIVE_MEANING();
	#endif
	#ifdef CORE_MODULE
	aph->aph_package = Hierarchy::package(Modules::current(), ADJECTIVES_HAP);
	aph->aph_iname = Hierarchy::make_iname_in(ADJECTIVE_HL, aph->aph_package);
	#endif
	if ((nl == NULL) && (Wordings::nonempty(W))) {
		#ifdef ADJECTIVE_NAME_VETTING
		if (ADJECTIVE_NAME_VETTING(W)) {
		#endif
			ExcerptMeanings::register(ADJECTIVE_MC,
				W, STORE_POINTER_adjectival_phrase(aph));
			LOOP_THROUGH_WORDING(n, W)
				Preform::mark_word(n, <adjective-name>);
		#ifdef ADJECTIVE_NAME_VETTING
		}
		#endif
	}
	return aph;
}

@ =
wording Adjectives::get_text(adjectival_phrase *aph, int plural) {
	return Clusters::get_name(aph->adjective_names, plural);
}

@h Parsing adjectives.
This does what its name suggests: matches the name of any adjective known to
Inform.

=
<adjective-name> internal {
	parse_node *p = ExParser::parse_excerpt(ADJECTIVE_MC, W);
	if (p) {
		*XP = RETRIEVE_POINTER_adjectival_phrase(
			ExcerptMeanings::data(ParseTree::get_meaning(p)));
		return TRUE;
	}
	return FALSE;
}

@ These are registered as excerpt meanings with the |ADJECTIVE_MC| meaning
code, so parsing a word range to match an adjective is easy. By construction
there is only one |adjectival_phrase| for any given excerpt of text, so
the following is unambiguous:

=
adjectival_phrase *Adjectives::parse(wording W) {
	if (<adjective-name>(W)) return <<rp>>;
	return NULL;
}

@h Testing agreement.

=
void Adjectives::test_adjective(OUTPUT_STREAM, wording W) {
	adjectival_phrase *aph = Adjectives::declare(W, NULL);
	if (aph == NULL) { WRITE("Failed test\n"); return; }
	int g, n;
	for (g = NEUTER_GENDER; g <= FEMININE_GENDER; g++) {
		switch (g) {
			case NEUTER_GENDER: WRITE("neuter "); break;
			case MASCULINE_GENDER: WRITE("masculine "); break;
			case FEMININE_GENDER: WRITE("feminine "); break;
		}
		for (n = 1; n <= 2; n++) {
			if (n == 1) WRITE("singular: "); else WRITE(" / plural: ");
			wording C = Clusters::get_name_general(aph->adjective_names,
				NULL, n, g);
			WRITE("%W", C);
		}
		WRITE("^");
	}
}

@h Logging.
To identify an adjective in the debugging log:

=
void Adjectives::log(adjectival_phrase *aph) {
	if (aph == NULL) { LOG("<null adjectival phrase>"); return; }
	wording W = Adjectives::get_text(aph, FALSE);
	if (Streams::I6_escapes_enabled(DL)) LOG("'%W'", W);
	else LOG("A%d'%W'", aph->allocation_id, W);
}

