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
	LOGIF(LINGUISTIC_STOCK, "Added to stock: "); Stock::log(item);
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
