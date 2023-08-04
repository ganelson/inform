[Examples::] Examples.

Keeping track of the metadata on and sequencing of the examples.

@ Examples are created in no particular order, and their allocation numbers
do not necessarily correspond to the numbering displayed in the final
documentation produced. We'll occasionally refer to ENO, or "example
numbering order", for this internal ordering.

Since a single example can appear in multiple volumes, in different places in
each, we must record where it occurs in each one. In some forms of output,
examples aren't given in full until several sections after the one they belong
to (for example, to hold them back to the end of the current chapter, or even
the current volume), so we also need to remember where it will actually go.

=
typedef struct example {
	struct filename *ex_filename;
	struct text_stream *ex_outline;
	struct text_stream *ex_public_name;
	struct text_stream *ex_index;
	struct text_stream *ex_subtitle;
	struct text_stream *ex_stars;
	struct text_stream *ex_sort_key;
	int ex_star_count;
	int ex_header_length;
	struct section *example_belongs_to_section[MAX_VOLUMES]; /* e.g., an example might belong to section 7 */
	struct section *example_displayed_at_section[MAX_VOLUMES]; /* but be held back and appear at end of section 23 */
	int example_position[MAX_VOLUMES]; /* sequence, counting from 0 */
	CLASS_DEFINITION
} example;

@ Examples are referenced both by a flat array (in ENO order) and in a hash
of their names:

@d MAX_EXAMPLES 10000

=
example *examples[MAX_EXAMPLES];
dictionary *examples_by_name = NULL;

@ These are used temporarily during recipe book construction.

=
dictionary *recipe_location = NULL;
dictionary *recipe_sort_prefix = NULL;
dictionary *recipe_subheading_of = NULL;

@h Example scanning.
Each Example has its own file, which consists of a three-line header, and
then some rawtext. The following scanner goes through a whole directory
to look for example files, and then scans their headers, ignoring the text
below for the time being. A sample:
= (text as Indoc)
	*** Plural assertions
	(Clothing kinds; Get Me to the Church on Time)
	Using kinds of clothing to prevent the player from wearing several...
=
Note that the title of the work appears after the semicolon on line 2.

An exception to this is the |(Recipes).txt| file, which is not an example,
but is instead a layout plan for how examples appear in volume 1 of the
Inform documentation.

=
void Examples::scan_examples(void) {
	linked_list *L = Directories::listing(indoc_settings->examples_directory);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) continue;
		if (Str::includes(entry, I"-I.")) continue;
		filename *exloc = Filenames::in(indoc_settings->examples_directory, entry);
		example *E = CREATE(example);
		@<Initialise the example@>;
		if (no_examples >= MAX_EXAMPLES) Errors::fatal("too many examples");
		examples[no_examples++] = E;
		@<Scan the example@>;
	}
	volume *V;
	LOOP_OVER(V, volume) {
		@<Work out the sequence of examples within this volume@>;
		@<Work out where each example is displayed within this volume@>;
	}
}

@<Initialise the example@> =
	E->ex_filename = exloc;
	E->ex_outline = NULL;
	E->ex_public_name = NULL;
	E->ex_index = NULL;
	E->ex_subtitle = NULL;
	E->ex_stars = NULL;
	E->ex_sort_key = NULL;
	E->ex_star_count = 1;
	E->ex_header_length = 0;
	E->example_belongs_to_section[0] = NULL;
	E->example_belongs_to_section[1] = NULL;
	E->example_displayed_at_section[0] = NULL;
	E->example_displayed_at_section[1] = NULL;
	E->example_position[0] = 0;
	E->example_position[1] = 0;

@<Scan the example@> =
	examples_helper_state ehs;
	ehs.E = E;
	ehs.ef = exloc;
	ehs.body_reached = FALSE;
	TextFiles::read(exloc, FALSE, "can't read example file",
		TRUE, Examples::examples_helper, NULL, &ehs);

@ =
typedef struct examples_helper_state {
	struct example *E;
	struct filename *ef;
	int body_reached;
} examples_helper_state;

void Examples::examples_helper(text_stream *line, text_file_position *tfp, void *v_ehs) {
	examples_helper_state *ehs = (examples_helper_state *) v_ehs;
	example *E = ehs->E;
	Str::trim_white_space(line);
	if (ehs->body_reached) return;
	if (Str::is_whitespace(line)) { ehs->body_reached = TRUE; return; }
	E->ex_header_length++;
	match_results mr = Regexp::create_mr();
	if (tfp->line_count == 1) {
		if (Regexp::match(&mr, line, L"Example *: *(%*+) (%c*)")) {
			text_stream *asterisk_text = mr.exp[0];
			text_stream *name = mr.exp[1];
			E->ex_stars = Str::duplicate(asterisk_text);
			int starc = 0;
			if (Str::eq_wide_string(E->ex_stars, L"*")) starc=1;
			if (Str::eq_wide_string(E->ex_stars, L"**")) starc=2;
			if (Str::eq_wide_string(E->ex_stars, L"***")) starc=3;
			if (Str::eq_wide_string(E->ex_stars, L"****")) starc=4;
			if (starc == 0) {
				Errors::in_text_file("star count for example must be * to ****", tfp);
				starc = 1;
			}
			E->ex_star_count = starc;
			E->ex_public_name = Str::duplicate(name);
			if (examples_by_name == NULL) examples_by_name = Dictionaries::new(100, FALSE);
			Dictionaries::create(examples_by_name, name);
			Dictionaries::write_value(examples_by_name, name, E);
		} else {
			Errors::in_text_file("first line should read 'Example: ** Title'", tfp);
		}
	} else {
		if (Regexp::match(&mr, line, L"(%C+?) *: *(%c*)")) {
			text_stream *field = mr.exp[0];
			text_stream *content = mr.exp[1];
			if (Str::eq(field, I"Example")) {
				Errors::in_text_file("'Example:' should be on line 1", tfp);
			} else if (Str::eq(field, I"Location")) {
				text_stream *sname = content;
				if (Dictionaries::find(volumes[0]->sections_by_name, sname) == NULL) {
					E->example_belongs_to_section[0] = NULL;
					Errors::in_text_file("example belongs to an unknown section", tfp);
				} else {
					section *S = Dictionaries::read_value(volumes[0]->sections_by_name, sname);
					if (S) E->example_belongs_to_section[0] = S;
				}
				E->ex_filename = ehs->ef;
			} else if (Str::eq(field, I"Description")) {
				E->ex_outline = Str::duplicate(content);
			} else if (Str::eq(field, I"For")) {
				; /* not relevant to indoc */
			} else if (Str::eq(field, I"Index")) {
				E->ex_index = Str::duplicate(content);
			} else if (Str::eq(field, I"Subtitle")) {
				E->ex_subtitle = Str::duplicate(content);
			} else if (Str::eq(field, I"RecipeLocation")) {
				text_stream *sname = content;
				if (Dictionaries::find(volumes[1]->sections_by_name, sname) == NULL) {
					E->example_belongs_to_section[1] = NULL;
					Errors::in_text_file("example belongs to an unknown section", tfp);
				} else {
					section *S = Dictionaries::read_value(volumes[1]->sections_by_name, sname);
					if (S) E->example_belongs_to_section[1] = S;
				}
			}
		}
	}
	Regexp::dispose_of(&mr);
}

@ At this point, then, we know which section every example belongs to. But
we still have to put them in order within those sections: we want 1-star
examples first, then 2-star, and so on. The following does that. In the
first volume, examples of equal star rating are in essentially random order,
but in subsequent volumes, they appear in that same order, since this means
their example numbers as shown in the documentation are increasing; which
looks tidy.

As noted above, |example_sequence| and |example_position| are essentially
inverse permutations.

@<Work out the sequence of examples within this volume@> =
	example *E;
	LOOP_OVER(E, example) {
		V->examples_sequence[E->allocation_id] = E;
		int key1 = 0;
		if (E->example_belongs_to_section[V->allocation_id])
			key1 = E->example_belongs_to_section[V->allocation_id]->allocation_id;
		int key2 = E->ex_star_count;
		int key3 = E->allocation_id;
		if (V->allocation_id > 0) key3 = E->example_position[0];
		E->ex_sort_key = Str::new();
		WRITE_TO(E->ex_sort_key, "%08d-%08d-%08d", key1, key2, key3);
	}

	qsort(V->examples_sequence, (size_t) no_examples, sizeof(example *),
		Examples::sort_comparison);

	for (int n=0; n<no_examples; n++) {
		example *E = V->examples_sequence[n];
		E->example_position[V->allocation_id] = n + 1; /* to count from 1 when displayed */
	}

@ =
int Examples::sort_comparison(const void *ent1, const void *ent2) {
	const example *E1 = *((const example **) ent1);
	const example *E2 = *((const example **) ent2);
	return Str::cmp(E1->ex_sort_key, E2->ex_sort_key);
}

@ In some granularities, examples are held back to the end of the chapter,
or even the end of the volume, to appear. This is where that's worked out.

@<Work out where each example is displayed within this volume@> =
	example *E;
	LOOP_OVER(E, example) {
		section *S = E->example_belongs_to_section[V->allocation_id];
		section *hang_here = NULL;
		for (int p = 0; p < V->vol_section_count; p++) {
			section *HS = V->sections[p];
			if (((indoc_settings->examples_granularity == SECTION_GRANULARITY) && (S == HS))
				||
				((indoc_settings->examples_granularity == CHAPTER_GRANULARITY) && (HS->in_which_chapter == S->in_which_chapter))
				||
				(indoc_settings->examples_granularity == BOOK_GRANULARITY))
				hang_here = HS;
		}
		if (hang_here)
			E->example_displayed_at_section[V->allocation_id] = hang_here;
		else
			Errors::fatal("miscalculated example ownership");
	}

@h Rendering example cues.
An example cue is a rendered chunk describing and naming an example. The text
of the example may or may not follow: if it doesn't, the description is a
link which opens it. Depending on the examples mode, the text of the
example may be either (a) included in the file and always visible, (b) included
but hidden by default until an icon is clicked, or (c) stored in an external,
that is, separate file.

=
void Examples::render_example_cue(OUTPUT_STREAM, example *E, volume *V, int writing_index) {
	if (indoc_settings->format == PLAIN_FORMAT) @<Render example cue in plain text@>
	else if (indoc_settings->format == HTML_FORMAT) @<Render example cue in HTML@>;
}

@<Render example cue in plain text@> =
	WRITE("\nExample %d (%S): %S\n%S\n\n",
		E->example_position[V->allocation_id], E->ex_stars, E->ex_public_name, E->ex_outline);

@<Render example cue in HTML@> =
	if (writing_index ==  FALSE) {
		TEMPORARY_TEXT(anchor)
		WRITE_TO(anchor, "e%d", E->allocation_id);
		HTML::anchor(OUT, anchor);
		DISCARD_TEXT(anchor)
	}

	if (indoc_settings->navigation->simplified_examples == FALSE) @<Render the example cue left surround@>;

	TEMPORARY_TEXT(url)
	TEMPORARY_TEXT(onclick)
	Examples::open_example_url(url, E, V, V, writing_index);
	Examples::open_example_onclick(onclick, E, V, V, writing_index);
	HTML::begin_link_with_class_onclick(OUT, I"eglink", url, onclick);
	DISCARD_TEXT(url)
	DISCARD_TEXT(onclick)

	@<Render the example difficulty asterisks@>;
	@<Render the example name@>;
	HTML::end_link(OUT);

	HTML_TAG("br");
	WRITE("%S", E->ex_outline);

	if (indoc_settings->navigation->simplified_examples == FALSE) @<Render the example cue right surround@>;
	WRITE("\n");

@ The "surround" is an table-implemented area which contains the descriptive
panel about the example. It has one row of three cells:
= (text)
	[ ( 22 ) ]  [ Example: Whatever ]  [ RB ]
=
holding the "oval", the icon with the example number; the description of the
example, including its name; and the cross-link to the same example in the
other book.

@<Render the example cue left surround@> =
	HTML_OPEN_WITH("table", "class=\"egcue\"");
	HTML_OPEN("tr");

	HTML_OPEN_WITH("td", "class=\"egcellforoval\""); /* The Oval begins */
	HTML::begin_div_with_class_S(OUT, I"egovalfornumber overstruckimage", __FILE__, __LINE__);
	TEMPORARY_TEXT(url)
	TEMPORARY_TEXT(onclick)
	Examples::open_example_url(url, E, V, V, writing_index);
	Examples::open_example_onclick(onclick, E, V, V, writing_index);
	HTML::begin_link_with_class_onclick(OUT, I"eglink", url, onclick);
	DISCARD_TEXT(url)
	DISCARD_TEXT(onclick)
	WRITE("<b>%d</b>", E->example_position[0]);
	HTML::end_link(OUT);
	HTML::end_div(OUT);
	HTML_CLOSE("td"); /* The Oval ends */

	HTML_OPEN_WITH("td", "class=\"egnamecell\"");
	HTML_OPEN_WITH("p", "class=\"egcuetext\""); /* The Descriptive Panel Area begins */

@<Render the example difficulty asterisks@> =
	for (int starcc=0; starcc < E->ex_star_count; starcc++) {
		if (indoc_settings->navigation->simplified_examples) WRITE("*");
		else HTMLUtilities::asterisk_image(OUT, I"asterisk.png");
	}

@<Render the example name@> =
	HTML_OPEN("b");
	TEMPORARY_TEXT(text_of_name)
	Str::copy(text_of_name, E->ex_public_name);
	Str::trim_white_space(text_of_name);
	Rawtext::escape_HTML_characters_in(text_of_name);
	if (indoc_settings->navigation->simplified_examples == FALSE) {
		HTML_OPEN_WITH("span", "class=\"egbanner\"");
		WRITE("Example");
		HTML_CLOSE("span");
		HTML_OPEN_WITH("span", "class=\"egname\"");
		WRITE("%S", text_of_name);
		HTML_CLOSE("span");
	} else {
		WRITE("Example %d: %S", E->example_position[0], text_of_name);
	}
	DISCARD_TEXT(text_of_name)
	HTML_CLOSE("b");

@<Render the example cue right surround@> =
	HTML_CLOSE("p");
	HTML_CLOSE("td"); /* The Descriptive Panel Area ends */
	HTML_OPEN_WITH("td", "class=\"egcrossref\"");
	if (no_volumes > 1)
		@<Render the cross-link to the same example in the other book@>;
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");

@<Render the cross-link to the same example in the other book@> =
	char *cross_to = "RB"; volume *V_to = volumes[1];
	if (V->allocation_id == 1) { cross_to = "WI"; V_to = volumes[0]; }
	HTML::comment(OUT, I"START IGNORE");
	HTML::begin_div_with_class_S(OUT, I"egovalforxref overstruckimage", __FILE__, __LINE__);
	TEMPORARY_TEXT(url)
	Examples::open_example_url(url, E, V, V_to, writing_index);
	HTML::begin_link(OUT, url);
	WRITE("<i>%s</i>", cross_to);
	HTML::end_link(OUT);
	HTML::end_div(OUT);
	HTML::comment(OUT, I"END IGNORE");

@ The following is a URL for a link which opens the example. Note that in
some cases this should work by a Javascript function call instead...

=
void Examples::open_example_url(OUTPUT_STREAM, example *E, volume *from_V, volume *V, int writing_index) {
	if ((indoc_settings->examples_mode == EXMODE_openable_internal) && (writing_index == 0) && (from_V == V))
		WRITE("#");
	else
		Examples::goto_example_url(OUT, E, V);
}

@ ...and this is it, used for the |onclick| field:

=
void Examples::open_example_onclick(OUTPUT_STREAM, example *E, volume *from_V, volume *V, int writing_index) {
	if ((indoc_settings->examples_mode == EXMODE_openable_internal) &&
		(writing_index == 0) &&
		(from_V == V)) {
		WRITE("showExample('example%d'); return false;", E->allocation_id);
	}
}

@ The actual URL holding the contents of an example are as follows:

=
void Examples::goto_example_url(OUTPUT_STREAM, example *E, volume *V) {
	WRITE("%S#e%d", E->example_belongs_to_section[V->allocation_id]->unanchored_URL, E->allocation_id);
}
