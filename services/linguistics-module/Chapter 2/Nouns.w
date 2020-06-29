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
rather than vice versa. But this arrangement makes it convenient to add
translations into non-English languages later on (i.e., at a time after the
initial creation of the //noun// object).

@h Structure.

=
typedef struct noun {
	struct lexical_cluster *names;
	int noun_subclass; /* either |COMMON_NOUN| or |PROPER_NOUN| */

	struct general_pointer meaning;
	unsigned int registration_category;

	#ifdef NOUN_COMPILATION_LINGUISTICS_CALLBACK
	struct name_compilation_data name_compilation; /* see //core: Using Nametags// on this */
	#endif
	#ifdef NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK
	struct name_resolution_data name_resolution; /* see //core: Headings// on this */
	#endif

	CLASS_DEFINITION
} noun;

@h Creation.
The following functions are called to create new proper or common nouns, and
note that:
(i) It is legal for the supplied text to be empty, and this does happen
for example when Inform creates the nouns of anonymous objects, as in a
sentence such as "Four people are in the Dining Room." Empty text in |W| means
that no forms are added to the lexical cluster and nothing is registered with
the lexicon.
(ii) If a noun is added to the lexicon with the special meaning code |NOUN_MC|,
passed to these functions in |mc|, then the meaning given to the lexicon is
the |noun| object itself, from which the ultimate |meaning| can then be
derived. The reason for such an indirection is that it makes it possible to
see whether the noun used was common or proper. Inform uses this when sorting
out ambiguous names of instances or kinds.
(iii) The |options| are a bitmap which used to be larger, and is now reduced
to a combination of just two possibilities:

@d ADD_TO_LEXICON_NTOPT 1         /* register these forms with the lexicon */
@d WITH_PLURAL_FORMS_NTOPT 2      /* add plurals to the forms known */

=
noun *Nouns::new_proper_noun(wording W, int gender, int options,
	unsigned int mc, parse_node *val) {
	general_pointer owner = NULL_GENERAL_POINTER;
	if (val) owner = STORE_POINTER_parse_node(val);
	return Nouns::new_inner(W, owner, PROPER_NOUN, options, mc, NULL, gender);
}

noun *Nouns::new_common_noun(wording W, int gender, int options,
	unsigned int mc, general_pointer owner) {
	return Nouns::new_inner(W, owner, COMMON_NOUN, options, mc, NULL, gender);
}

@ Note that 

=
noun *Nouns::new_inner(wording W, general_pointer owner, int p, int options,
	unsigned int mc, NATURAL_LANGUAGE_WORDS_TYPE *lang, int gender) {
	noun *t = CREATE(noun);
	t->meaning = owner;
	t->registration_category = mc;
	t->noun_subclass = p;
	t->names = Clusters::new();
	if (Wordings::nonempty(W)) Nouns::supply_text(t, W, lang, gender, 1, options);
	#ifdef NOUN_COMPILATION_LINGUISTICS_CALLBACK
	NOUN_COMPILATION_LINGUISTICS_CALLBACK(t);
	#endif
	return t;
}

@h Subclass.

=
int Nouns::subclass(noun *t) {
	if (t == NULL) return 0;
	return t->noun_subclass;
}

int Nouns::is_proper(noun *t) {
	if ((t) && (t->noun_subclass == PROPER_NOUN)) return TRUE;
	return FALSE;
}

int Nouns::is_common(noun *t) {
	if ((t) && (t->noun_subclass == COMMON_NOUN)) return TRUE;
	return FALSE;
}

@h Logging.

=
void Nouns::log(noun *t) {
	if (t == NULL) { LOG("<untagged>"); return; }
	wording W = Nouns::nominative_singular(t);
	if (Wordings::nonempty(W)) LOG("'%W'", W);
}

@h Attaching some wording to a noun.
As noted above, each noun comes with a cluster of names, and here's where
we add a new one.

For the time being, nouns are registered with the lexicon only in their
nominative cases; if we ever get to the point of Inform source text written
fully in a language like German, that will need to change.

=
void Nouns::supply_text(noun *t, wording W, NATURAL_LANGUAGE_WORDS_TYPE *lang,
	int gender, int number, int options) {
	linked_list *L = Clusters::add(t->names, W, lang, gender, number,
		(options & WITH_PLURAL_FORMS_NTOPT)?TRUE:FALSE);
	if (options & ADD_TO_LEXICON_NTOPT) {
		individual_form *in;
		LOOP_OVER_LINKED_LIST(in, individual_form, L) {
			general_pointer m = t->meaning;
			if (t->registration_category == NOUN_MC) m = STORE_POINTER_noun(t);
			Lexicon::register(t->registration_category,
				Clusters::get_nominative_of_form(in), m);
		}
	}
}

@h Name access.
We normally access names in their nominative cases, so:

=
wording Nouns::nominative_singular(noun *t) {
	if (t == NULL) return EMPTY_WORDING;
	return Clusters::get_form(t->names, FALSE);
}

int Nouns::nominative_singular_includes(noun *t, vocabulary_entry *wd) {
	if (t == NULL) return FALSE;
	wording W = Nouns::nominative_singular(t);
	LOOP_THROUGH_WORDING(i, W)
		if (wd == Lexer::word(i))
			return TRUE;
	return FALSE;
}

wording Nouns::nominative(noun *t, int plural_flag) {
	return Clusters::get_form(t->names, plural_flag);
}

wording Nouns::nominative_in_language(noun *t, int plural_flag,
	NATURAL_LANGUAGE_WORDS_TYPE *lang) {
	return Clusters::get_form_in_language(t->names, plural_flag, lang);
}

void Nouns::set_nominative_plural_in_language(noun *t, wording W,
	NATURAL_LANGUAGE_WORDS_TYPE *lang) {
	Clusters::set_plural_in_language(t->names, W, lang);
}

@h Meaning.

=
general_pointer Nouns::meaning(noun *t) {
	if (t == NULL) return NULL_GENERAL_POINTER;
	return t->meaning;
}

@h Exact parsing in the lexicon.

@d PARSE_EXACTLY_LEXICON_CALLBACK Nouns::parse_exactly

=
int Nouns::parse_exactly(excerpt_meaning *em) {
	if (em->meaning_code == NOUN_MC) {
		#ifdef CORE_MODULE
		if (use_exact_parsing_option) return TRUE;
		#endif
		return FALSE;
	}
	return TRUE;
}

@h Disambiguation.
Here the parse node |p| stands at the head of a list of alternative meanings
for some text: for example, they might be different possible meanings of the
words "red chair" -- perhaps the "red stuffed chair", perhaps the "red upright
chair", and so on. We want to choose the most likely possibility.

Within Inform, this "likely" consideration is a matter of context -- of which
heading the noun appears under.

=
noun *Nouns::disambiguate(parse_node *p, int common_only) {
	noun *first_nt = NULL;
	@<If only one of the possible matches is eligible, return that@>;
	@<If the matches can be scored, return the highest-scoring one@>;
	/* and otherwise... */
	return first_nt;
}

@<If only one of the possible matches is eligible, return that@> =
	int candidates = 0; 
	for (parse_node *p2 = p; p2; p2 = p2->next_alternative) {
		noun *nt = RETRIEVE_POINTER_noun(Lexicon::get_data(Node::get_meaning(p2)));
		if (Nouns::is_eligible_match(nt, common_only)) {
			first_nt = nt; candidates++;
		}
	}
	if (candidates <= 1) return first_nt;

@<If the matches can be scored, return the highest-scoring one@> =
	#ifdef NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK
	noun *best_nt = NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK(p, common_only);
	if (best_nt) return best_nt;
	#endif

@ =
int Nouns::is_eligible_match(noun *nt, int common_only) {
	if ((common_only) && (Nouns::is_common(nt) == FALSE)) return FALSE;
	return TRUE;
}
