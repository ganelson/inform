[IndexLexicon::] Lexicon.

A lexicon for nouns, adjectives and verbs found in an Inter tree.

@ The lexicon is the part of the Index which gives an alphabetised list of
adjectives, nouns, verbs and other words which can be used in descriptions
of things: it's the nearest thing to an index of the meanings inside Inform.
It brings together meanings relating to various different Inform structures
under a single umbrella:

@d COMMON_NOUN_TLEXE 1 /* a kind */
@d PROPER_NOUN_TLEXE 2 /* an instance of "object" */
@d ADJECTIVAL_PHRASE_TLEXE 3 /* the subject of a "Definition:" */
@d ENUMERATED_CONSTANT_TLEXE 4 /* e.g., "green" if colour is a kind of value and green a colour */
@d VERB_TLEXE 5 /* an ordinary verb */
@d PREP_TLEXE 7 /* a "to be upon..." sort of verb */
@d MVERB_TLEXE 9 /* a meaningless verb */

=
typedef struct index_lexicon_entry {
	struct text_stream *lemma;
	int part_of_speech; /* one of those above */
	char *category; /* textual description of said, e.g., |"adjective"| */
	struct general_pointer entry_refers_to; /* depending on which part of speech */
	char *gloss_note; /* gloss on the definition, or |NULL| if none is provided */
	struct inter_package *lex_package;
	int link_to; /* word number in source text */
	struct text_stream *reduced_to_lower_case; /* text converted to lower case for sorting */
	struct index_lexicon_entry *sorted_next; /* next in lexicographic order */
	CLASS_DEFINITION
} index_lexicon_entry;

@ A lexicon is then a set of entries. These are accumulated in no particular
order, then sorted.

=
typedef struct inter_lexicon {
	struct linked_list *unsorted;
	index_lexicon_entry *first; /* head of list in lexicographic order */
	CLASS_DEFINITION
} inter_lexicon;

@h Creating a lexicon.
And this is where that happens:

=
inter_lexicon *IndexLexicon::stock(inter_tree *I, tree_inventory *inv) {
	inter_lexicon *lexicon = CREATE(inter_lexicon);
	lexicon->first = NULL;
	lexicon->unsorted = NEW_LINKED_LIST(index_lexicon_entry);
	@<Add verb entries@>;
	@<Add preposition entries@>;
	@<Add adjective entries@>;
	@<Add common noun entries@>;
	@<Add proper noun entries@>;
	@<Create lower-case forms of all lexicon entries@>;
	@<Sort the lexicon into alphabetical order@>;
	return lexicon;
}

@<Add verb entries@> =
	InterNodeList::array_sort(inv->verb_nodes, MakeSynopticModuleStage::module_order);
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->verb_nodes) {
		index_lexicon_entry *lex;
		if (Metadata::read_numeric(pack, I"^meaningless"))
			lex = IndexLexicon::new_entry_with_package(
				Metadata::required_textual(pack, I"^infinitive"), MVERB_TLEXE, pack);
		else
			lex = IndexLexicon::new_entry_with_package(
				Metadata::required_textual(pack, I"^infinitive"), VERB_TLEXE, pack);
		lex->link_to = (int) Metadata::read_numeric(pack, I"^at");
		ADD_TO_LINKED_LIST(lex, index_lexicon_entry, lexicon->unsorted);
	}

@<Add preposition entries@> =
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->preposition_nodes) {
		index_lexicon_entry *lex = IndexLexicon::new_entry_with_package(
			Metadata::required_textual(pack, I"^text"), PREP_TLEXE, pack);
		lex->link_to = (int) Metadata::read_numeric(pack, I"^at");
	}

@<Add adjective entries@> =
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->adjective_nodes) {
		text_stream *lemma = Metadata::required_textual(pack, I"^text");
		if (Str::len(lemma) > 0) {
			index_lexicon_entry *lex = IndexLexicon::new_entry(lemma, ADJECTIVAL_PHRASE_TLEXE);
			lex->category = "adjective";
			lex->lex_package = pack;		
			ADD_TO_LINKED_LIST(lex, index_lexicon_entry, lexicon->unsorted);
		}
	}

@<Add common noun entries@> =
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->kind_nodes)
		if (Metadata::read_optional_numeric(pack, I"^is_subkind_of_object")) {
			index_lexicon_entry *lex = IndexLexicon::new_entry(
				Metadata::required_textual(pack, I"^name"), COMMON_NOUN_TLEXE);
			lex->link_to = (int) Metadata::read_numeric(pack, I"^at");
			lex->category = "noun";
			lex->lex_package = pack;			
			ADD_TO_LINKED_LIST(lex, index_lexicon_entry, lexicon->unsorted);
		}

@<Add proper noun entries@> =
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->instance_nodes) {
		if (Metadata::read_optional_numeric(pack, I"^is_object")) {
			index_lexicon_entry *lex = IndexLexicon::new_entry(
				Metadata::required_textual(pack, I"^name"), PROPER_NOUN_TLEXE);
			lex->link_to = (int) Metadata::read_numeric(pack, I"^at");
			lex->category = "noun";
			lex->lex_package = pack;
			ADD_TO_LINKED_LIST(lex, index_lexicon_entry, lexicon->unsorted);
		} else {
			index_lexicon_entry *lex = IndexLexicon::new_entry(
				Metadata::required_textual(pack, I"^name"), ENUMERATED_CONSTANT_TLEXE);
			lex->link_to = (int) Metadata::read_numeric(pack, I"^at");
			lex->category = "noun";
			lex->lex_package = pack;
			ADD_TO_LINKED_LIST(lex, index_lexicon_entry, lexicon->unsorted);
		}
	}

@ Before we can sort the lexicon, we need to turn its disparate forms of name
into a single, canonical, lower-case representation.

@<Create lower-case forms of all lexicon entries@> =
	index_lexicon_entry *lex;
	LOOP_OVER_LINKED_LIST(lex, index_lexicon_entry, lexicon->unsorted) {
		Str::copy(lex->reduced_to_lower_case, lex->lemma);
		LOOP_THROUGH_TEXT(pos, lex->reduced_to_lower_case)
			Str::put(pos, Characters::tolower(Str::get(pos)));
	}

@ The lexicon is sorted by insertion sort, which is not ideally fast, but
which is convenient when dealing with linked lists: there are unlikely to be
more than 1000 or so entries, so the speed penalty for insertion rather
than (say) quicksort is not great.

@<Sort the lexicon into alphabetical order@> =
	index_lexicon_entry *lex;
	LOOP_OVER_LINKED_LIST(lex, index_lexicon_entry, lexicon->unsorted) {
		index_lexicon_entry *lex2, *last_lex;
		if (lexicon->first == NULL) {
			lexicon->first = lex; lex->sorted_next = NULL; continue;
		}
		for (last_lex = NULL, lex2 = lexicon->first; lex2;
			last_lex = lex2, lex2 = lex2->sorted_next)
			if (Str::cmp(lex->reduced_to_lower_case, lex2->reduced_to_lower_case) < 0) {
				if (last_lex == NULL) lexicon->first = lex;
				else last_lex->sorted_next = lex;
				lex->sorted_next = lex2; goto Inserted;
			}
		last_lex->sorted_next = lex; lex->sorted_next = NULL;
		Inserted: ;
	}

@ Lexicon entries are created by the following function:

=
index_lexicon_entry *IndexLexicon::new_entry(text_stream *lemma, int part) {
	index_lexicon_entry *lex = CREATE(index_lexicon_entry);
	lex->lemma = Str::duplicate(lemma);
	lex->part_of_speech = part;
	lex->entry_refers_to = NULL_GENERAL_POINTER;
	lex->category = NULL; lex->gloss_note = NULL;
	lex->reduced_to_lower_case = Str::new();
	lex->lex_package = NULL;
	lex->link_to = 0;
	return lex;
}

@ Or by these specialisations:

=
index_lexicon_entry *IndexLexicon::new_entry_with_details(text_stream *lemma, int pos,
	char *category, char *gloss) {
	index_lexicon_entry *lex = IndexLexicon::new_entry(lemma, pos);
	lex->lemma = lemma;
	lex->category = category; lex->gloss_note = gloss;
	return lex;
}

index_lexicon_entry *IndexLexicon::new_entry_with_package(text_stream *infinitive, int part,
	inter_package *pack) {
	index_lexicon_entry *lex = IndexLexicon::new_entry(NULL, part);
	lex->lemma = infinitive;
	lex->category = "verb";
	lex->lex_package = pack;
	return lex;
}

@h Listing a lexicon.
Now for the bulk of the work. Entries appear in HTML paragraphs with hanging
indentation and no interparagraph spacing, so we need to insert regular
paragraphs between the As and the Bs, then between the Bs and the Cs, and so on.
Each entry consists of the wording, then maybe some icons, then an explanation
of what it is: for instance,
= (text)
player's holdall [icon]    noun, a kind of container
=
In a few cases, there is a further textual gloss to add.

=
void IndexLexicon::listing(OUTPUT_STREAM, inter_lexicon *lexicon, int proper_nouns_only,
	localisation_dictionary *LD) {
	index_lexicon_entry *lex;
	wchar_t current_initial_letter = '?';
	int verb_count = 0, proper_noun_count = 0, c;
	for (lex = lexicon->first; lex; lex = lex->sorted_next)
		if (lex->part_of_speech == PROPER_NOUN_TLEXE)
			proper_noun_count++;
	if (proper_nouns_only) {
		HTML::begin_html_table(OUT, NULL, TRUE, 0, 0, 0, 0, 0);
		HTML::first_html_column(OUT, 0);
	}
	for (c = 0, lex = lexicon->first; lex; lex = lex->sorted_next) {
		if (proper_nouns_only) { if (lex->part_of_speech != PROPER_NOUN_TLEXE) continue; }
		else { if (lex->part_of_speech == PROPER_NOUN_TLEXE) continue; }
		if ((proper_nouns_only) && (c == proper_noun_count/2)) HTML::next_html_column(OUT, 0);
		if (current_initial_letter != Str::get_first_char(lex->reduced_to_lower_case)) {
			if (c > 0) { HTML_OPEN("p"); HTML_CLOSE("p"); }
			current_initial_letter = Str::get_first_char(lex->reduced_to_lower_case);
		}
		c++;
		HTML_OPEN_WITH("p", "class=\"hang\"");

		@<Text of the actual lexicon entry@>;
		@<Icon with link to documentation, source or verb table, if any@>;

		switch(lex->part_of_speech) {
			case ADJECTIVAL_PHRASE_TLEXE:
				@<Definition of adjectival phrase entry@>; break;
			case ENUMERATED_CONSTANT_TLEXE:
				@<Definition of enumerated instance entry@>; break;
			case PROPER_NOUN_TLEXE:
				@<Definition of proper noun entry@>; break;
			case COMMON_NOUN_TLEXE:
				@<Definition of common noun entry@>; break;
		}
		if (lex->gloss_note) WRITE(" <i>%s</i>", lex->gloss_note);
		HTML_CLOSE("p");
	}
	if (proper_nouns_only) { HTML::end_html_row(OUT); HTML::end_html_table(OUT); }
}

@ In traditional dictionary fashion, we present the text in what may not be
the most normal ordering, in order to place the alphabetically important
part first: thus "see, to be able to" rather than "to be able to see".[1]

[1] Compare "Gallifreyan High Council, continual incidences of madness and
treachery amongst the" in "Doctor Who: The Completely Useless Encyclopaedia",
eds. Howarth and Lyons (1996).

@<Text of the actual lexicon entry@> =
	if (lex->part_of_speech == PREP_TLEXE)
		Localisation::roman_t(OUT, LD, I"Index.Elements.Lx.ToBe", lex->lemma);
	else
		WRITE("%S", lex->lemma);

@ Main lexicon entries to do with verbs link further down the index page
to the corresponding entries in the verb table. We want to use numbered
anchors for these links, but we want to avoid colliding with numbered
anchors already used for other purposes higher up on the Phrasebook index
page. So we use a set of anchors numbered 10000 and up, which is guaranteed
not to coincide with any of those.

We omit source links to an adjectival phrase because these are polymorphic,
that is, the phrase may have multiple definitions in different parts of the
source text: so any single link would be potentially misleading.

@<Icon with link to documentation, source or verb table, if any@> =
	switch(lex->part_of_speech) {
		case COMMON_NOUN_TLEXE:
			IndexUtilities::link_to_documentation(OUT, lex->lex_package);
			break;
		case VERB_TLEXE:
		case PREP_TLEXE:
			IndexUtilities::below_link_numbered(OUT, 10000+verb_count++);
			break;
	}
	if ((lex->part_of_speech != ADJECTIVAL_PHRASE_TLEXE) && (lex->link_to > 0))
		IndexUtilities::link(OUT, lex->link_to);

@<Definition of common noun entry@> =
	@<Begin definition text@>;
	WRITE(", ");
	Localisation::roman_t(OUT, LD, I"Index.Elements.Lx.KindOf",
		Metadata::optional_textual(lex->lex_package, I"^index_superkind"));
	@<End definition text@>;

@ Simply the name of an instance.

@<Definition of proper noun entry@> =
	@<Begin definition text@>;
	WRITE("%S", Metadata::required_textual(lex->lex_package, I"^index_kind"));
	@<End definition text@>;

@ As mentioned above, an adjectival phrase can be multiply defined in
different contexts. We want to quote all of those.

@<Definition of adjectival phrase entry@> =
	@<Begin definition text@>;
	WRITE(": %S", Metadata::required_textual(lex->lex_package, I"^index_entry"));
	@<End definition text@>;

@<Definition of enumerated instance entry@> =
	@<Begin definition text@>;
	WRITE(", ");
	Localisation::roman_t(OUT, LD, I"Index.Elements.Lx.ValueOf",
		Metadata::optional_textual(lex->lex_package, I"^index_kind"));
	@<End definition text@>;

@<Begin definition text@> =
	WRITE(" ... <i>");
	if ((proper_nouns_only == FALSE) && (lex->category))
		WRITE("%s", lex->category);

@<End definition text@> =
	WRITE("</i>");
