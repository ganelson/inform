[Nouns::] Nouns.

Nouns are an abstraction for meanings registered with the excerpt
parser which serve as names for individual things or kinds of things.

@h Why we abstract nouns.
In the previous chapter, we laid out a general-purpose way to register
"excerpt meanings": to say that a given excerpt of text, such as "air
pressure", might have a particular meaning. However, we don't want to
use that system directly to represent a noun, because this would assume
that nouns come in just one wording. In reality, they are inflected to
indicate number (singular vs plural) and, in many languages, case, and
they can therefore have many wordings; they can also be translated into
other languages.

@h Structure.
We will give each noun a "priority", used when resolving ambiguities, but
this will be a very simple system: common nouns (i.e., names of kinds) will
be high priority, and proper names (i.e., names of instances) will be low.

@d HIGH_NOUN_PRIORITY 1
@d LOW_NOUN_PRIORITY 2

@d MAX_NOUN_PRIORITY 2

=
typedef struct noun {
	struct name_cluster *names;
	struct general_pointer tagged_to;
	int search_priority; /* in the range 1 up to |MAX_NOUN_PRIORITY| */
	int match_exactly; /* do not allow subset parsing matches, e.g., "bottle" for "glass bottle" */
	int range_number; /* used to enumerate */
	unsigned int registration_category;
	struct general_pointer registration_to;
	#ifdef CORE_MODULE
	struct text_stream *nt_I6_identifier; /* Name to be used in Inform 6 output */
	struct inter_name *nt_iname;
	struct name_resolution_data name_resolution; /* see the Headings section on this */
	#endif
	CLASS_DEFINITION
} noun;

@h Creation.
Note that it's legal for the supplied text to be empty, and this does happen
for example when Inform creates the nouns of anonymous objects, as in a
sentence such as "Four people are in the Dining Room."

It may seem odd that noun structures store a pointer back to their owners;
as if the luggage tag has a suitcase hanging from it, rather than vice versa.
But this is needed because nouns can themselves be registered as excerpt
meanings. Thus, "silver medallion" might be an EM pointing to a noun,
and if it comes up in parsing then we need a way to get from the noun to
the actual medallion object.

When a noun is created, we supply a bitmap of options:

@d PARSE_EXACTLY_NTOPT 1
@d REGISTER_SINGULAR_NTOPT 2
@d REGISTER_PLURAL_NTOPT 4
@d ATTACH_TO_SEARCH_LIST_NTOPT 8

=
noun *Nouns::new_proper_noun(wording W, int gender, int options,
	unsigned int mc, parse_node *val) {
	general_pointer owner = NULL_GENERAL_POINTER;
	if (val) owner = STORE_POINTER_parse_node(val);
	return Nouns::new_inner(W, owner, LOW_NOUN_PRIORITY, options, mc, NULL, gender);
}

noun *Nouns::new_common_noun(wording W, int gender, int options,
	unsigned int mc, general_pointer owner) {
	return Nouns::new_inner(W, owner, HIGH_NOUN_PRIORITY, options, mc, NULL, gender);
}

noun *Nouns::new_inner(wording W, general_pointer owner, int p, int options,
	unsigned int mc, NATURAL_LANGUAGE_WORDS_TYPE *foreign_language, int gender) {
	noun *t = CREATE(noun);
	t->tagged_to = owner;
	t->registration_to = owner;
	if (mc == NOUN_MC) t->registration_to = STORE_POINTER_noun(t);
	t->registration_category = mc;
	t->range_number = t->allocation_id + 1;
	t->search_priority = p;
	t->match_exactly = FALSE;
	t->names = Clusters::new();
	if (options & PARSE_EXACTLY_NTOPT) t->match_exactly = TRUE;
	if (Wordings::nonempty(W))
		Nouns::add_to_noun_and_reg(t, W, foreign_language, gender, 1, options);
	#ifdef CORE_MODULE
	t->nt_I6_identifier = Str::new();
	t->nt_iname = NULL;
	if (options & ATTACH_TO_SEARCH_LIST_NTOPT)
		@<Insert this noun into the relevant heading search list@>;
	#endif
	return t;
}

@ Every heading in the source text has a search list of nouns created
under it, and this is used for disambiguation: see below.

@<Insert this noun into the relevant heading search list@> =
	Sentences::Headings::disturb();
	Sentences::Headings::attach_noun(t);
	Sentences::Headings::verify_divisions();

@h Attaching some wording to a noun.
As noted above, each noun comes with a cluster of names, and here's where
we add a new one.

@d NOUN_HAS_NO_MC 0xffffffff

=
individual_name *Nouns::add_to_noun_and_reg(noun *t,
	wording W, NATURAL_LANGUAGE_WORDS_TYPE *foreign_language, int gender, int number, int options) {
	linked_list *L = Clusters::add(t->names, W, foreign_language, gender, number,
		(options & REGISTER_PLURAL_NTOPT)?TRUE:FALSE);
	individual_name *in;
	LOOP_OVER_LINKED_LIST(in, individual_name, L)
		if ((options & REGISTER_SINGULAR_NTOPT) && (t->registration_category != NOUN_HAS_NO_MC)) {
			excerpt_meaning *em = ExcerptMeanings::register(
				t->registration_category,
				Declensions::in_case(&(in->name), NOMINATIVE_CASE),
				t->registration_to);
			Clusters::set_principal_meaning(in, STORE_POINTER_excerpt_meaning(em));
		}
	return in;
}

@ The English singular nominative form:

=
wording Nouns::nominative(noun *t) {
	if (t == NULL) return EMPTY_WORDING;
	return Clusters::get_name(t->names, FALSE);
}

@h Logging.

=
void Nouns::log(noun *t) {
	if (t == NULL) { LOG("<untagged>"); return; }
	wording W = Nouns::get_name(t, FALSE);
	if (Wordings::nonempty(W)) {
		LOG("'");
		LOOP_THROUGH_WORDING(i, W) {
			LOG("%N", i);
			if (i < Wordings::last_wn(W)) LOG(" ");
		}
		LOG("'");
	}
}

@h Name access.

=
wording Nouns::get_name(noun *t, int plural_flag) {
	return Clusters::get_name(t->names, plural_flag);
}

wording Nouns::get_name_in_play(noun *t, int plural_flag, NATURAL_LANGUAGE_WORDS_TYPE *lang) {
	return Clusters::get_name_in_play(t->names, plural_flag, lang);
}

void Nouns::set_plural_name(noun *t, wording W) {
	NATURAL_LANGUAGE_WORDS_TYPE *L = NULL;
	#ifdef CORE_LANGUAGE
	L = Task::language_of_syntax();
	#endif
	Clusters::set_plural_name(t->names, W, L);
}

int Nouns::full_name_includes(noun *t, vocabulary_entry *wd) {
	if (t == NULL) return FALSE;
	wording W = Nouns::get_name(t, FALSE);
	LOOP_THROUGH_WORDING(i, W)
		if (wd == Lexer::word(i))
			return TRUE;
	return FALSE;
}

@h Other utilities.

=
general_pointer Nouns::tag_holder(noun *t) {
	if (t == NULL) return NULL_GENERAL_POINTER;
	return t->tagged_to;
}

int Nouns::priority(noun *t) {
	if (t == NULL) return 0;
	return t->search_priority;
}

int Nouns::range_number(noun *t) {
	if (t == NULL) return 0;
	return t->range_number;
}

void Nouns::set_range_number(noun *t, int r) {
	if (t == NULL) return;
	t->range_number = r;
}

int Nouns::exactitude(noun *t) {
	if (t == NULL) return FALSE;
	#ifdef CORE_MODULE
	if (use_exact_parsing_option) return TRUE;
	#endif
	return t->match_exactly;
}

excerpt_meaning *Nouns::get_principal_meaning(noun *t) {
	return RETRIEVE_POINTER_excerpt_meaning(Clusters::get_principal_meaning(t->names));
}

@h Disambiguation.
It's a tricky task to choose from a list of possible nouns which might
have been intended by text such as "chair". If the list is empty or
contains only one choice, no problem. Otherwise we will probably have to
reorder the noun search list, and then run through it. The code below
looks as if it picks out the match with highest score, so that the ordering
is unimportant, but in fact the score assigned to a match is based purely
on the number of words missed out (see later): that means that ambiguities
often arise between two lexically similar objects, e.g., a "blue chair"
or a "red chair" when the text simply specifies "chair". Since the code
below accepts the first noun with the highest score, the outcome is
thus determined by which of the blue and red chairs ranks highest in the
search list: and that is why the search list is so important.

=
noun *Nouns::disambiguate(parse_node *p, int priority) {
	int candidates = 0; noun *first_nt = NULL;
	for (parse_node *p2 = p; p2; p2 = p2->next_alternative) {
		noun *nt = RETRIEVE_POINTER_noun(
			ExcerptMeanings::data(Node::get_meaning(p2)));
		if ((nt->search_priority >= 1) && (nt->search_priority <= priority)) {
			first_nt = nt; candidates++;
		}
	}

	if (candidates <= 1) return first_nt;

	#ifdef CORE_MODULE
	Sentences::Headings::construct_noun_search_list();
	noun *nt;
	LOOP_OVER(nt, noun)
		Sentences::Headings::set_noun_search_score(nt, 0);

	for (parse_node *p2 = p; p2; p2 = p2->next_alternative) {
		noun *nt = RETRIEVE_POINTER_noun(
			ExcerptMeanings::data(Node::get_meaning(p2)));
		if ((nt->search_priority >= 1) && (nt->search_priority <= priority))
			Sentences::Headings::set_noun_search_score(nt,
				Node::get_score(p2));
	}
	noun *best_nt = Sentences::Headings::highest_scoring_noun_searched();
	if (best_nt) return best_nt;
	#endif

	return first_nt;
}
