[IXContents::] Contents Element.

To produce the index contents listing and the XML headings file.

@h The index.

=
typedef struct contents_entry {
	struct heading *heading_entered;
	struct contents_entry *next;
	CLASS_DEFINITION
} contents_entry;

void IXContents::render(OUTPUT_STREAM) {
	IXContents::index(OUT);
	IXContents::index_extensions(OUT);
}

int headings_indexed = 0;
void IXContents::index(OUTPUT_STREAM) {
	#ifdef IF_MODULE
	HTML_OPEN("p");
	WRITE("<b>");
	if ((story_title_VAR == NULL) || (story_author_VAR == NULL))
		WRITE("Contents");
	else {
//		IXBibliographicData::index_variable(OUT, story_title_VAR,
//			I"Untitled");
		WRITE(" by ");
//		IXBibliographicData::index_variable(OUT, story_author_VAR,
//			I"Anonymous");
	}	
	WRITE("</b>");
	HTML_CLOSE("p");
	#endif
	HTML_OPEN("p");
	WRITE("CONTENTS");
	HTML_CLOSE("p");
	IXContents::index_heading_recursively(OUT,
		NameResolution::pseudo_heading()->child_heading);
	contents_entry *ce;
	int min_positive_level = 10;
	LOOP_OVER(ce, contents_entry)
		if ((ce->heading_entered->level > 0) &&
			(ce->heading_entered->level < min_positive_level))
			min_positive_level = ce->heading_entered->level;
	LOOP_OVER(ce, contents_entry)
		@<Index this entry in the contents@>;

	if (NUMBER_CREATED(contents_entry) == 1) {
		HTML_OPEN("p"); WRITE("(This would look more like a contents page if the source text "
			"were divided up into headings.");
		Index::DocReferences::link(OUT, I"HEADINGS");
		WRITE(")");
		HTML_CLOSE("p");
		WRITE("\n");
	}
}

@<Index this entry in the contents@> =
	heading *h = ce->heading_entered;
	/* indent to correct tab position */
	HTML_OPEN_WITH("ul", "class=\"leaders\""); WRITE("\n");
	int ind_used = h->indentation;
	if (h->level == 0) ind_used = 1;
	HTML_OPEN_WITH("li", "class=\"leaded indent%d\"", ind_used);
	HTML_OPEN("span");
	if (h->level == 0) {
		if (NUMBER_CREATED(contents_entry) == 1)
			WRITE("Source text");
		else
			WRITE("Preamble");
	} else {
		/* write the text of the heading title */
		WRITE("%+W", Node::get_text(h->sentence_declaring));
	}
	HTML_CLOSE("span");
	HTML_OPEN("span");
	contents_entry *next_ce = NEXT_OBJECT(ce, contents_entry);
	if (h->level != 0)
		while ((next_ce) && (next_ce->heading_entered->level > ce->heading_entered->level))
			next_ce = NEXT_OBJECT(next_ce, contents_entry);
	int start_word = Wordings::first_wn(Node::get_text(ce->heading_entered->sentence_declaring));
	int end_word = (next_ce)?(Wordings::first_wn(Node::get_text(next_ce->heading_entered->sentence_declaring)))
		: (TextFromFiles::last_lexed_word(FIRST_OBJECT(source_file)));

	int N = 0;
	for (int i = start_word; i < end_word; i++)
		N += TextFromFiles::word_count(i);
	if (h->level > min_positive_level) HTML::begin_colour(OUT, I"808080");
	WRITE("%d words", N);
	if (h->level > min_positive_level) HTML::end_colour(OUT);
	/* place a link to the relevant line of the primary source text */
	Index::link_location(OUT, h->start_location);
	HTML_CLOSE("span");
	HTML_CLOSE("li");
	HTML_CLOSE("ul");
	WRITE("\n");
	@<List all the objects and kinds created under the given heading, one tap stop deeper@>;

@ We index only headings of level 1 and up -- so, not the pseudo-heading or the
File (0) ones -- and which are not within any extensions -- so, are in the
primary source text written by the user.

=
void IXContents::index_heading_recursively(OUTPUT_STREAM, heading *h) {
	if (h == NULL) return;
	int show_heading = TRUE;
	heading *next = h->child_heading;
	if (next == NULL) next = h->next_heading;
	if ((next) &&
		(Extensions::corresponding_to(next->start_location.file_of_origin)))
		next = NULL;
	if (h->level == 0) {
		show_heading = FALSE;
		if ((headings_indexed == 0) &&
			((next == NULL) ||
				(Wordings::first_wn(Node::get_text(next->sentence_declaring)) !=
					Wordings::first_wn(Node::get_text(h->sentence_declaring)))))
			show_heading = TRUE;
	}
	if (Extensions::corresponding_to(h->start_location.file_of_origin))
		show_heading = FALSE;
	if (show_heading) {
		contents_entry *ce = CREATE(contents_entry);
		ce->heading_entered = h;
		headings_indexed++;
	}

	IXContents::index_heading_recursively(OUT, h->child_heading);
	IXContents::index_heading_recursively(OUT, h->next_heading);
}

@ We skip any objects or kinds without names (i.e., whose |creator| is null).
The rest appear in italic type, and without links to source text since this
in practice strews distractingly many orange berries across the page.

@<List all the objects and kinds created under the given heading, one tap stop deeper@> =
	noun *nt;
	int c = 0;
	LOOP_OVER_NOUNS_UNDER(nt, h) {
		wording W = Nouns::nominative(nt, FALSE);
		if (Wordings::nonempty(W)) {
			if (c++ == 0) {
				HTML::open_indented_p(OUT, ind_used+1, "hanging");
				HTML::begin_colour(OUT, I"808080");
			} else WRITE(", ");
			WRITE("<i>%+W</i>", W);
		}
	}
	if (c > 0) { HTML::end_colour(OUT); HTML_CLOSE("p"); }

@h Indexing extensions in the Contents index.
The routine below places a list of extensions used in the Contents index,
giving only minimal entries about them.

=
void IXContents::index_extensions(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("EXTENSIONS"); HTML_CLOSE("p");
	IXContents::index_extensions_from(OUT, NULL);
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Extensions::is_standard(E) == FALSE)
			IXContents::index_extensions_from(OUT, E);
	LOOP_OVER(E, inform_extension)
		if (Extensions::is_standard(E))
			IXContents::index_extensions_from(OUT, E);
	HTML_OPEN("p"); HTML_CLOSE("p");
}

void IXContents::index_extensions_from(OUTPUT_STREAM, inform_extension *from) {
	int show_head = TRUE;
	inform_extension *E;
	LOOP_OVER(E, inform_extension) {
		inform_extension *owner = NULL;
		parse_node *N = Extensions::get_inclusion_sentence(from);
		if (Wordings::nonempty(Node::get_text(N))) {
			source_location sl = Wordings::location(Node::get_text(N));
			if (sl.file_of_origin == NULL) owner = NULL;
			else owner = Extensions::corresponding_to(
				Lexer::file_of_origin(Wordings::first_wn(Node::get_text(N))));
		}
		if (owner != from) continue;
		if (show_head) {
			HTML::open_indented_p(OUT, 2, "hanging");
			HTML::begin_colour(OUT, I"808080");
			WRITE("Included ");
			if (Extensions::is_standard(from)) WRITE("automatically by Inform");
			else if (from == NULL) WRITE("from the source text");
			else {
				WRITE("by the extension %S", from->as_copy->edition->work->title);
			}
			show_head = FALSE;
			HTML::end_colour(OUT);
			HTML_CLOSE("p");
		}
		HTML_OPEN_WITH("ul", "class=\"leaders\"");
		HTML_OPEN_WITH("li", "class=\"leaded indent2\"");
		HTML_OPEN("span");
		WRITE("%S ", E->as_copy->edition->work->title);
		Works::begin_extension_link(OUT, E->as_copy->edition->work, NULL);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/help.png");
		Works::end_extension_link(OUT, E->as_copy->edition->work);
		if (Extensions::is_standard(E) == FALSE) { /* give author and inclusion links, but not for SR */
			WRITE(" by %X", E->as_copy->edition->work->author_name);
		}
		if (VersionNumbers::is_null(E->as_copy->edition->version) == FALSE) {
			WRITE(" ");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			semantic_version_number V = E->as_copy->edition->version;
			WRITE("version %v", &V);
			HTML_CLOSE("span");
		}
		if (Str::len(E->extra_credit_as_lexed) > 0) {
			WRITE(" ");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			WRITE("(%S)", E->extra_credit_as_lexed);
			HTML_CLOSE("span");
		}
		HTML_CLOSE("span");
		HTML_OPEN("span");
		WRITE("%d words", TextFromFiles::total_word_count(E->read_into_file));
		if (from == NULL) Index::link(OUT, Wordings::first_wn(Node::get_text(Extensions::get_inclusion_sentence(E))));
		HTML_CLOSE("span");
		HTML_CLOSE("li");
		HTML_CLOSE("ul");
		WRITE("\n");
	}
}
