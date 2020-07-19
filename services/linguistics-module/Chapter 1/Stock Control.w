[Stock::] Stock Control.

To manage the stock of possible linguistic items.

@ Stock items are classified by their categories. There are only a few of
these, each represented by a single instance of:

=
typedef struct grammatical_category {
	struct text_stream *name;
	struct method_set *methods;
	int number_of_items;
	CLASS_DEFINITION
} grammatical_category;

@ The categories form a fixed set. They are each created by their own sections
of code, as called from this function when the module starts up:

=
void Stock::create_categories(void) {
	Adjectives::create_category();
	Articles::create_category();
	Nouns::create_category();
	Pronouns::create_category();
	Prepositions::create_category();
	Quantifiers::create_category();
	Verbs::create_category();
	Verbs::create_forms_category();
}

@ Those functions in turn each call this creator:

=
grammatical_category *Stock::new_category(text_stream *name) {
	grammatical_category *cat = CREATE(grammatical_category);
	cat->name = Str::duplicate(name);
	cat->methods = Methods::new_set();
	cat->number_of_items = 0;
	return cat;
}

@ Grammatical categories support only a single method call:

@e LOG_GRAMMATICAL_CATEGORY_MTID

=
VOID_METHOD_TYPE(LOG_GRAMMATICAL_CATEGORY_MTID, grammatical_category *cat,
	general_pointer data)

@ The stock is essentially a big inventory of items, each represented by an
instance of the following:

=
typedef struct linguistic_stock_item {
	struct grammatical_category *category;
	struct general_pointer data;
	CLASS_DEFINITION
} linguistic_stock_item;

@ A flat array is maintained of the entire stock, so that they can be efficiently
looked up by their allocation numbers:

=
linguistic_stock_item **flat_array_of_stock = NULL;
int flat_array_of_stock_extent = 0;

linguistic_stock_item *Stock::new(grammatical_category *cat, general_pointer data) {
	linguistic_stock_item *item = CREATE(linguistic_stock_item);
	item->category = cat;
	item->data = data;
	cat->number_of_items++;
	@<Expand the stock array if it has run out of space@>;
	flat_array_of_stock[item->allocation_id] = item;
	LOGIF(LINGUISTIC_STOCK, "Added to stock: ");
	if (Log::aspect_switched_on(LINGUISTIC_STOCK_DA)) Stock::log(item);
	return item;
}

@ Note that the array starts empty, so this will happen the first time a stock
item is created.

@<Expand the stock array if it has run out of space@> =
	if (NUMBER_CREATED(linguistic_stock_item) > flat_array_of_stock_extent) {
		int new_fa_extent = 4*flat_array_of_stock_extent;
		if (new_fa_extent == 0) new_fa_extent = 2048;
		linguistic_stock_item **new_fa =
			Memory::calloc(new_fa_extent, sizeof(linguistic_stock_item *), STOCK_MREASON);
		for (int i=0; i<new_fa_extent; i++)
			if (i < flat_array_of_stock_extent)
				new_fa[i] = flat_array_of_stock[i];
			else
				new_fa[i] = NULL;
		if (flat_array_of_stock)
			Memory::I7_array_free(flat_array_of_stock, STOCK_MREASON,
				flat_array_of_stock_extent, sizeof(linguistic_stock_item *));
		flat_array_of_stock = new_fa;
		flat_array_of_stock_extent = new_fa_extent;
	}

@ What can we do with the stock? Well, we can log it, which is useful for
diagnostics and the woven form of this module, if nothing else.

=
void Stock::log(linguistic_stock_item *item) {
	LOG("%S: ", item->category->name);
	VOID_METHOD_CALL(item->category, LOG_GRAMMATICAL_CATEGORY_MTID, item->data);
	LOG("\n");
}

void Stock::log_all(void) {
	grammatical_category *cat;
	LOOP_OVER(cat, grammatical_category)
		LOG("%S: %d item%s\n", cat->name, cat->number_of_items,
			(cat->number_of_items==1)?"":"s");
	LOG("total in all categories: %d\n\n", NUMBER_CREATED(linguistic_stock_item));
	linguistic_stock_item *item;
	LOOP_OVER(cat, grammatical_category) {
		LOOP_OVER(item, linguistic_stock_item)
			if (item->category == cat)
				Stock::log(item);
		LOG("\n");
	}
}

@ The stock inventory can also be used to make references. Using the stock
ID number (plus 1) as the reference ID of a linguistic constant reference,
we can effectively have a single |int| value refer to a stock item together
with any combination of gender, person, number, mood, case, tense, and sense.
The "plus 1" is so that a reference ID of zeri can mean "no item".

=
lcon_ti Stock::to_lcon(linguistic_stock_item *item) {
	return Lcon::of_id(1 + item->allocation_id);
}

linguistic_stock_item *Stock::from_lcon(lcon_ti l) {
	int id = Lcon::get_id(l) - 1;
	if ((id < 0) || (id >= flat_array_of_stock_extent)) return NULL;
	return flat_array_of_stock[id];
}

@ Grammatical usages.
Consider nouns, for example. In many languages, declensions do not distinguish
cases fully. In English, the accusative and nominative form of almost every
noun are the same. So it would not be possible for this object to say for
sure what case was used -- for example, the lexicon can't know that the
use of "Jane" in the sentences "Peter knows Jane" and "Jane knows Peter" has
a different case in those sentences: it's only looking at the word itself,
and can't know the wider context. If we parse the word "Jane" the best we can
do is say "it's Jane, in either the nominative or accusative case".

More inflected languages make for more interesting examples here. In German,
for example, "Tische" could be any of the nominative, accusative or genitive
plurals of "Tisch", table, but "Tischen" can only be the dative plural.

The following object represents awkward disjunctions like "either the nominative
or accusative case".

@d MAX_GU_FORMS 2*MAX_GRAMMATICAL_CASES

=
typedef struct grammatical_usage {
	struct linguistic_stock_item *used;
	NATURAL_LANGUAGE_WORDS_TYPE *language;
	int no_possible_forms;
	lcon_ti possible_forms[MAX_GU_FORMS];
	CLASS_DEFINITION
} grammatical_usage;

grammatical_usage *Stock::new_usage(linguistic_stock_item *item, NATURAL_LANGUAGE_WORDS_TYPE *L) {
	grammatical_usage *gu = CREATE(grammatical_usage);
	gu->used = item;
	gu->language = L;
	gu->no_possible_forms = 0;
	return gu;
}

void Stock::add_form_to_usage(grammatical_usage *gu, lcon_ti f) {
	if (gu->used) f = Lcon::set_id(f, 1 + gu->used->allocation_id);
	if (gu->no_possible_forms >= MAX_GU_FORMS) internal_error("too many forms");
	gu->possible_forms[gu->no_possible_forms++] = f;
}

lcon_ti Stock::first_form_in_usage(grammatical_usage *gu) {
	if (gu->no_possible_forms == 0) internal_error("unformed usage");
	return gu->possible_forms[0];
}

void Stock::write_usage(OUTPUT_STREAM, grammatical_usage *gu, int desiderata) {
	if (gu->no_possible_forms == 0) WRITE("<unformed usage>");
	Lcon::write_set(OUT, gu->possible_forms, gu->no_possible_forms, desiderata);
}

int Stock::usage_might_be_singular(grammatical_usage *gu) {
	if (gu)
		for (int i=0; i<gu->no_possible_forms; i++)
			if (Lcon::get_number(gu->possible_forms[i]) == SINGULAR_NUMBER)
				return TRUE;
	return FALSE;			
}

int Stock::usage_might_be_third_person(grammatical_usage *gu) {
	if (gu)
		for (int i=0; i<gu->no_possible_forms; i++)
			if (Lcon::get_person(gu->possible_forms[i]) == THIRD_PERSON)
				return TRUE;
	return FALSE;			
}

@h Small word sets.
Sometimes we want a very fast way to parse a single word to see if it belongs
to a small set of possibilities -- for example, to see if it is a pronoun.
If there are very few such, even using Preform is unnecessary overhead. The
following is a lightweight alternative:

=
typedef struct small_word_set {
	int extent;
	int used;
	struct vocabulary_entry **word_ve;
	void **results;

	CLASS_DEFINITION
} small_word_set;

@ Small word sets do not expand: they must be created large enough. But really,
if we expect them to contain more than about 20 words at the outside, then
we ought to be using standard Preform nonterminals instead.

Small word sets are, however, initially empty -- i.e., no capacity is used.

=
small_word_set *Stock::new_sws(int capacity) {
	small_word_set *sws = CREATE(small_word_set);
	sws->used = 0;
	sws->extent = capacity;
	sws->word_ve = (vocabulary_entry **)
		(Memory::calloc(sws->extent, sizeof(vocabulary_entry *), SWS_MREASON));
	sws->results = (void **)
		(Memory::calloc(sws->extent, sizeof(void *), SWS_MREASON));
	return sws;
}

@ The following adds a word.

=
void *Stock::find_in_sws(small_word_set *sws, vocabulary_entry *ve) {
	for (int i=0; i<sws->used; i++)
		if (ve == sws->word_ve[i])
			return sws->results[i];
	return NULL;
}

void Stock::add_to_sws(small_word_set *sws, vocabulary_entry *ve, void *res) {
	if (sws->used >= sws->extent) internal_error("small word set exhausted");
	sws->word_ve[sws->used] = ve;
	sws->results[sws->used] = res;
	sws->used++;
}
