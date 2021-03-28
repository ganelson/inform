[Phrases::Index::] Phrasebook Index.

To compile most of the HTML page for the Phrasebook index.

@ The Phrasebook is produced in two passes. On pass 1, we show just the
divisions and subdivisions, making a contents page for the Phrasebook; on pass
2, we include the actual phrases, making the body text for the Phrasebook.

The divisions (which look like headings on the Index, but we don't call them
that to avoid confusion with source text headings) correspond to the
extensions in which phrases are defined. If $N$ extensions were included
then there are divisions $0, 1, ..., N$, where $0, ..., N-1$ correspond
to the extensions in inclusion order, with the Standard Rules being division 0.
Division $N$ represents the source text itself.

The subdivisions (in effect subheadings on the Index) correspond to headings,
within the divisions, under which phrases are defined. Note that some headings
suppress indexing of their definitions.

=
void Phrases::Index::index_page_Phrasebook(OUTPUT_STREAM) {
	for (int pass=1; pass<=2; pass++) {
		inform_extension *last_extension_named = NULL;
		for (int division = 0, N = NUMBER_CREATED(inform_extension); division <= N; division++) {
			heading *last_heading_named = NULL;
			int no_subdivision_yet = TRUE;
			wording CLW = EMPTY_WORDING;
			imperative_defn *id;
			id_body *run_begin = NULL;
			LOOP_OVER(id, imperative_defn) {
				if (ImperativeDefinitionFamilies::include_in_Phrasebook_index(id)) {
					id_body *idb = id->body_of_defn;
					/* include only if it is under an indexed heading */
					heading *this_heading =
						Headings::of_wording(Node::get_text(ImperativeDefinitions::body_at(idb)));
					if (Headings::indexed(this_heading) == FALSE) continue;
					/* and only if that heading lies in the piece of source for this division */
					inform_extension *this_extension =
						Headings::get_extension_containing(this_heading);
					if (division == N) { /* skip phrase unless it's in the source text */
						if (this_extension != NULL) continue;
					} else { /* skip phrase unless it's defined in the extension for this division */
						if ((this_extension == NULL) || (this_extension->allocation_id != division)) continue;
					}

					if (last_extension_named != this_extension) @<Mark a division in the Phrasebook@>;
					if (this_heading != last_heading_named) @<Mark a subdivision in the Phrasebook@>;
					last_heading_named = this_heading;
					last_extension_named = this_extension;

					if (pass == 2) @<Actually index the phrase@>;
				}
			}
		}
	}
}

@ We call the null extension the source text; we don't call the Standard
Rules anything, as that goes without saying; and otherwise we produce
the extension's name as a major subheading in our index.

@<Mark a division in the Phrasebook@> =
	if (this_extension == NULL) {
		if (pass == 2) HTML_TAG("hr");
		HTML_OPEN_WITH("p", "class=\"in1\"");
		WRITE("<b>Defined in the source</b>");
		HTML_CLOSE("p");
	} else if (Extensions::is_standard(this_extension) == FALSE) {
		if (pass == 2) HTML_TAG("hr");
		HTML_OPEN_WITH("p", "class=\"in1\"");
		WRITE("<b>From the extension ");
		Extensions::write_name_to_file(this_extension, OUT);
		WRITE(" by ");
		Extensions::write_author_to_file(this_extension, OUT);
		WRITE("</b>");
		HTML_CLOSE("p");
	}
	no_subdivision_yet = TRUE;

@ In pass 1, subdivisions are shown in a comma-separated list; in pass 2,
each has a paragraph of its own.

@<Mark a subdivision in the Phrasebook@> =
	wording HW = Headings::get_text(this_heading);
	if (Wordings::nonempty(HW)) {
		if (pass == 1) @<Strip away bracketed matter in the heading name@>;
		if (Extensions::is_standard(this_extension))
			@<Mark a faked division due to inter-hyphen clue in SR heading@>;
	}

	if ((pass == 1) && (no_subdivision_yet == FALSE)) WRITE(", ");
	if (pass == 2) {
		Index::anchor_numbered(OUT, idb->allocation_id);
		HTML_OPEN_WITH("p", "class=\"in2\"");
		WRITE("<b>");
	}
	if (Wordings::nonempty(HW)) WRITE("%+W", HW);
	else WRITE("Miscellaneous");
	if (pass == 1) Index::below_link_numbered(OUT, idb->allocation_id);
	if (pass == 2) {
		WRITE("</b>");
		HTML_CLOSE("p");
	}
	no_subdivision_yet = FALSE;

@<Strip away bracketed matter in the heading name@> =
	if (<heading-with-parenthesis>(HW)) HW = GET_RW(<heading-with-parenthesis>, 1);

@ The Standard Rules contain such a profusion of phrase definitions that,
without making use of subheadings, the Phrasebook Index would be a shapeless
list in which it was impossible to find things.

So the indexer in fact looks at headings in the source text and attempts
to group definitions by them. In particular, in the Standard Rules, it looks
for headings with this form:

>> Blah blah blah - Major title - Minor title

For example, we might have

>> Section SR5/3/2 - Control phrases - While

which would match the first production below. The first piece is discarded,
and the second and third pieces used as headings and subheadings respectively.

=
<heading-with-parenthesis> ::=
	{<heading-name-hyphenated>} ( <definite-article> ... ) |
	{<heading-name-hyphenated>} ( ... ) |
	{<heading-name-hyphenated>}

<heading-name-hyphenated> ::=
	... - ... - ... |    ==> { 3, - }
	... - ... |    ==> { 2, - }
	... 					==> { 1, - }

@ We then extract "Control phrases" as the "clue".

@<Mark a faked division due to inter-hyphen clue in SR heading@> =
	<heading-name-hyphenated>(HW);
	if (<<r>> == 3) {
		wording C = GET_RW(<heading-name-hyphenated>, 2);
		if ((Wordings::empty(CLW)) || (Wordings::match(C, CLW) == FALSE)) {
			CLW = C;
			if (pass == 2) HTML_TAG("hr");
			HTML_OPEN_WITH("p", "class=\"in1\"");
			WRITE("<b>%+W</b>", CLW);
			HTML_CLOSE("p");
			no_subdivision_yet = TRUE;
		}
		HW = GET_RW(<heading-name-hyphenated>, 3);
	} else {
		HW = GET_RW(<heading-name-hyphenated>, 1);
	}

@ We see where |idb| is in a run of phrases which share a common documentation
symbol; only the first in the run has a plus-sign link to reveal the box of
documentation in question, and only the last in the run is followed by the
code for the box.

@<Actually index the phrase@> =
	id_body *idb2 = idb, *run_end = idb;
	if (Phrases::Index::ph_same_doc(idb, run_begin) == FALSE) run_begin = idb;
	while ((idb2) && (Phrases::Index::ph_same_doc(idb, idb2))) {
		run_end = idb2; idb2 = NEXT_OBJECT(idb2, id_body);
	}

	HTML_OPEN_WITH("p", "class=\"tightin2\"");
	if (run_begin == idb) Index::extra_link(OUT, run_end->allocation_id);
	else Index::noextra_link(OUT);
	Phrases::Index::index_type_data(OUT, &(idb->type_data), idb);
	if (IDTypeData::deprecated(&(idb->type_data)))
		Index::deprecation_icon(OUT, run_begin->allocation_id);
	Index::link(OUT, Wordings::first_wn(Node::get_text(ImperativeDefinitions::body_at(idb))));
	HTML_CLOSE("p");

	if (run_end == idb) {
		Index::extra_div_open(OUT, idb->allocation_id, 3, "e0e0e0");
		Phrases::Index::write_reveal_box(OUT, &(run_begin->type_data), run_begin);
		Index::extra_div_close(OUT, "e0e0e0");
	}

@ Where the following detects if two phrases have the same documentation
symbol, i.e., are essentially rewordings of the same phrase, and will have
a single shared reveal-box:

=
int Phrases::Index::ph_same_doc(id_body *p1, id_body *p2) {
	if ((p1 == NULL) || (p2 == NULL) ||
		(Wordings::empty(ToPhraseFamily::doc_ref(p1->head_of_defn))) ||
			(Wordings::empty(ToPhraseFamily::doc_ref(p2->head_of_defn))))
		return FALSE;
	if (Wordings::match(ToPhraseFamily::doc_ref(p1->head_of_defn), ToPhraseFamily::doc_ref(p2->head_of_defn)))
		return TRUE;
	return FALSE;
}

@ This is nothing to do with phrases, but as we've defined <heading-name-hyphenated>
above, it may as well go here.

=
void Phrases::Index::index_definition_area(OUTPUT_STREAM, wording W, int show_if_unhyphenated) {
	<heading-name-hyphenated>(W);
	if ((<<r>> == 1) && (show_if_unhyphenated == FALSE)) return;
	HTML_OPEN("b");
	switch (<<r>>) {
		case 1: WRITE("%+W", W); break;
		case 2: {
			wording C = GET_RW(<heading-name-hyphenated>, 2);
			WRITE("%+W", C); break;
		}
		case 3: {
			wording C = GET_RW(<heading-name-hyphenated>, 2);
			wording D = GET_RW(<heading-name-hyphenated>, 3);
			WRITE("%+W - %+W", C, D);
			break;
		}
	}
	HTML_CLOSE("b");
	HTML_TAG("br");
}

@ Writing type data in the Phrasebook index:

=
void Phrases::Index::index_type_data(OUTPUT_STREAM, id_type_data *idtd, id_body *idb) {
	if (idtd->manner_of_return == DECIDES_CONDITION_MOR)
		WRITE("<i>if</i> ");
	ImperativeDefinitions::write_HTML_representation(OUT, idb, INDEX_PHRASE_FORMAT);
	if (idtd->return_kind == NULL) {
		if (idtd->manner_of_return == DECIDES_CONDITION_MOR) WRITE("<i>:</i>");
	} else {
		WRITE(" ... <i>");
		if (Kinds::Behaviour::definite(idtd->return_kind) == FALSE) WRITE("value");
		else Kinds::Textual::write(OUT, idtd->return_kind);
		WRITE("</i>");
		wording W = ToPhraseFamily::get_equation_form(idb->head_of_defn);
		if (Wordings::nonempty(W)) {
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>y</i>&nbsp;=&nbsp;<b>%+W</b>(<i>x</i>)", W);
		}
	}
}

@ In the Phrasebook index, listings are marked with plus sign buttons which,
when clicked, expand an otherwise hidden box of details about the phrase.
This is the routine which prints those details.

=
void Phrases::Index::write_reveal_box(OUTPUT_STREAM, id_type_data *idtd, id_body *idb) {
	HTML_OPEN("p");
	@<Present a paste button containing the text of the phrase@>;
	Phrases::Index::index_type_data(OUT, idtd, idb);
	Phrases::Index::index_phrase_options(OUT, &(idb->options_data));
	@<Quote from and reference to the documentation, where possible@>;
	@<Present the equation form of the phrase, if it has one@>;
	@<Present the name of the phrase regarded as a value, if it has one@>;
	@<Present the kind of the phrase@>;
	HTML_CLOSE("p");
	@<Warn about deprecation, where necessary@>;
}

@<Present a paste button containing the text of the phrase@> =
	TEMPORARY_TEXT(TEMP)
	ImperativeDefinitions::write_HTML_representation(TEMP, idb, PASTE_PHRASE_FORMAT);
	PasteButtons::paste_text(OUT, TEMP);
	DISCARD_TEXT(TEMP)
	WRITE("&nbsp;");

@ This is only possible for phrases mentioned in the built-in manuals,
of course.

@<Quote from and reference to the documentation, where possible@> =
	if (Wordings::nonempty(ToPhraseFamily::doc_ref(idb->head_of_defn))) {
		HTML_CLOSE("p");
		TEMPORARY_TEXT(pds)
		WRITE_TO(pds, "%+W", Wordings::one_word(Wordings::first_wn(ToPhraseFamily::doc_ref(idb->head_of_defn))));
		Index::DocReferences::doc_fragment(OUT, pds);
		HTML_OPEN("p"); WRITE("<b>See</b> ");
		Index::DocReferences::fully_link(OUT, pds);
		DISCARD_TEXT(pds)
	}

@<Present the equation form of the phrase, if it has one@> =
	wording W = ToPhraseFamily::get_equation_form(idb->head_of_defn);
	if (Wordings::nonempty(W)) {
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("<b>In equations:</b> write as ");
		PasteButtons::paste_W(OUT, W);
		WRITE("&nbsp;%+W()", W);
	}

@<Present the name of the phrase regarded as a value, if it has one@> =
	wording CW = ToPhraseFamily::constant_name(idb->head_of_defn);
	if (Wordings::nonempty(CW)) {
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("<b>Name:</b> ");
		PasteButtons::paste_W(OUT, CW);
		WRITE("&nbsp;%+W", CW);
	}

@ "Say" phrases are never used functionally and don't have interesting kinds,
so we won't list them here.

@<Present the kind of the phrase@> =
	if (IDTypeData::is_a_say_phrase(idb) == FALSE) {
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("<b>Kind:</b> ");
		Kinds::Textual::write(OUT, IDTypeData::kind(idtd));
	}

@<Warn about deprecation, where necessary@> =
	if (IDTypeData::deprecated(&(idb->type_data))) {
		HTML_OPEN("p");
		WRITE("<b>Warning:</b> ");
		WRITE("This phrase is now deprecated! It will probably be withdrawn in "
			"future builds of Inform, and even the present build will reject it "
			"if the 'Use no deprecated features' option is set. If you're using "
			"it now, try following the documentation link above for advice on "
			"what to write instead.");
		HTML_CLOSE("p");
	}

@h Indexing.

=
void Phrases::Index::index_phrase_options(OUTPUT_STREAM, id_options_data *phod) {
	for (int i=0; i<phod->no_options_permitted; i++) {
		phrase_option *po = phod->options_permitted[i];
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
		if (i==0) {
			HTML_TAG("br");
			WRITE("<i>optionally</i> ");
		} else if (i == phod->no_options_permitted-1) {
			if (phod->multiple_options_permitted) WRITE("<i>and/or</i> ");
			else WRITE("<i>or</i> ");
		}
		PasteButtons::paste_W(OUT, po->name);
		WRITE("&nbsp;%+W", po->name);
		if (i < phod->no_options_permitted-1) {
			WRITE(",");
			HTML_TAG("br");
		}
		WRITE("\n");
	}
}

