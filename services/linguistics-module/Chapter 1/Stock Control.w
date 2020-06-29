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
	Nouns::create_category();
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

@ The stock is essentially a big soup of items, each represented by an
instance of the following:

=
typedef struct linguistic_stock_item {
	struct grammatical_category *category;
	struct general_pointer data;
	CLASS_DEFINITION
} linguistic_stock_item;

@ =
linguistic_stock_item *Stock::new(grammatical_category *cat, general_pointer data) {
	linguistic_stock_item *item = CREATE(linguistic_stock_item);
	item->category = cat;
	item->data = data;
	cat->number_of_items++;
	LOG("Added to stock: "); Stock::log(item);
	return item;
}

@ What can we do with the stock? Well, we can log it, which is useful for
diagnostics and the woven form of this module, if nothing else.

=
void Stock::log(linguistic_stock_item *item) {
	LOG("%S: ", item->category->name);
	VOID_METHOD_CALL(item->category, LOG_GRAMMATICAL_CATEGORY_MTID, item->data);
	LOG(" (s%d)\n", item->allocation_id);
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
