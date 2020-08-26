[IndexHeadings::] Index Headings.

To produce the index contents listing and the XML headings file.

@h The debugging log.
Finally, three ways to describe the run of headings: to the debugging log,
to the index of the project, and to a freestanding XML file.

=
void IndexHeadings::log(heading *h) {
	if (h==NULL) { LOG("<null heading>\n"); return; }
	heading *pseud = NameResolution::pseudo_heading();
	if (h == pseud) { LOG("<pseudo_heading>\n"); return; }
	LOG("H%d ", h->allocation_id);
	if (h->start_location.file_of_origin)
		LOG("<%f, line %d>",
			TextFromFiles::get_filename(h->start_location.file_of_origin),
			h->start_location.line_number);
	else LOG("<nowhere>");
	LOG(" level:%d indentation:%d", h->level, h->indentation);
}

@ And here we log the whole heading tree by recursing through it, and
surreptitiously check that it is correctly formed at the same time.

=
void IndexHeadings::log_all_headings(void) {
	heading *h;
	parse_node_tree *T = Task::syntax_tree();
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates) LOG("$H\n", h);
	LOG("\n");
	IndexHeadings::log_headings_recursively(NameResolution::pseudo_heading(), 0);
}

void IndexHeadings::log_headings_recursively(heading *h, int depth) {
	int i;
	if (h==NULL) return;
	for (i=0; i<depth; i++) LOG("  ");
	LOG("$H\n", h);
	if (depth-1 != h->indentation) LOG("*** indentation should be %d ***\n", depth-1);
	IndexHeadings::log_headings_recursively(h->child_heading, depth+1);
	IndexHeadings::log_headings_recursively(h->next_heading, depth);
}

@h The index.

=
typedef struct contents_entry {
	struct heading *heading_entered;
	struct contents_entry *next;
	CLASS_DEFINITION
} contents_entry;

int headings_indexed = 0;
void IndexHeadings::index(OUTPUT_STREAM) {
	#ifdef IF_MODULE
	HTML_OPEN("p");
	WRITE("<b>"); PL::Bibliographic::contents_heading(OUT); WRITE("</b>");
	HTML_CLOSE("p");
	#endif
	HTML_OPEN("p");
	WRITE("CONTENTS");
	HTML_CLOSE("p");
	IndexHeadings::index_heading_recursively(OUT,
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
void IndexHeadings::index_heading_recursively(OUTPUT_STREAM, heading *h) {
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

	IndexHeadings::index_heading_recursively(OUT, h->child_heading);
	IndexHeadings::index_heading_recursively(OUT, h->next_heading);
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

@h The XML file.
This is provided as a convenience to the application using Inform, which may want
to have a pull-down menu or similar gadget allowing the user to jump to a given
heading. This tells the interface where every heading is, thus saving it from
having to parse the source.

The property list contains a single dictionary, whose keys are the numbers
0, 1, 2, ..., $n-1$, where there are $n$ headings in all. (The pseudo-heading
is not included.) A special key, the only non-numerical one, called "Application
Version", contains the Inform build number in its usual form: "4Q34", for instance.

=
void IndexHeadings::write_as_xml(void) {
	text_stream xf_struct; text_stream *xf = &xf_struct;
	filename *F = Task::xml_headings_file();
	if (STREAM_OPEN_TO_FILE(xf, F, UTF8_ENC) == FALSE)
		Problems::fatal_on_file("Can't open headings file", F);
	IndexHeadings::write_headings_as_xml_inner(xf);
	STREAM_CLOSE(xf);
}

void IndexHeadings::write_headings_as_xml_inner(OUTPUT_STREAM) {
	heading *h;
	@<Write DTD indication for XML headings file@>;
	WRITE("<plist version=\"1.0\"><dict>\n");
	INDENT;
	WRITE("<key>Application Version</key><string>%B (build %B)</string>\n", FALSE, TRUE);
	parse_node_tree *T = Task::syntax_tree();
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates) {
		WRITE("<key>%d</key><dict>\n", h->allocation_id);
		INDENT;
		@<Write the dictionary of properties for a single heading@>;
		OUTDENT;
		WRITE("</dict>\n");
	}
	OUTDENT;
	WRITE("</dict></plist>\n");
}

@ We use a convenient Apple DTD:

@<Write DTD indication for XML headings file@> =
	WRITE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		"<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" "
		"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");

@ Note that a level of 0, and a title of |--|, signifies a File (0) level
heading: external tools can probably ignore such records. Similarly, it is
unlikely that they will ever see a record without a "Filename" key --
this would mean a heading arising from text created internally within Inform,
which will only happen if someone has done something funny with |.i6t| files --
but should this arise then the best recourse is to ignore the heading.

@<Write the dictionary of properties for a single heading@> =
	if (h->start_location.file_of_origin)
		WRITE("<key>Filename</key><string>%f</string>\n",
			TextFromFiles::get_filename(h->start_location.file_of_origin));
	WRITE("<key>Line</key><integer>%d</integer>\n", h->start_location.line_number);
	if (Wordings::nonempty(h->heading_text))
		WRITE("<key>Title</key><string>%+W</string>\n", h->heading_text);
	else
		WRITE("<key>Title</key><string>--</string>\n");
	WRITE("<key>Level</key><integer>%d</integer>\n", h->level);
	WRITE("<key>Indentation</key><integer>%d</integer>\n", h->indentation);
