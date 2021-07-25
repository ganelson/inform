[RTPhrasebook::] Phrasebook Index.

Compiling what amounts to the Phrasebook index into the Inter hierarchy.

@ The Phrasebook index cannot be generated from the Inter hierarchy simply
by observing the function definitions in it, because of the existence of
implicit phrases, polymorphic phrases and so on. It needs just too much
understanding of the situation which only the top- and mid-levels of the
compiler have.

So we compile what amounts to a structured version of this index element
directly into the Inter code, for retrieval later when the actual index
HTML page is written.

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
void RTPhrasebook::compile_entries(void) {
	package_request *last_super_heading_package = NULL;
	inform_extension *last_extension_named = NULL;
	for (int division = 0, N = NUMBER_CREATED(inform_extension); division <= N; division++) {
		heading *last_heading_named = NULL;
		package_request *last_heading_package = NULL;
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
				if ((last_heading_package == NULL) || (this_heading != last_heading_named))
					@<Mark a subdivision in the Phrasebook@>;
				last_heading_named = this_heading;
				last_extension_named = this_extension;

				@<Actually index the phrase@>;
			}
		}
	}
}

@ We call the null extension the source text, and otherwise we produce
the extension's name as a major subheading in our index.

@<Mark a division in the Phrasebook@> =
	if (this_extension == NULL) {
		last_super_heading_package =
			Hierarchy::completion_package(PHRASEBOOK_SUPER_HEADING_HAP);
		Hierarchy::apply_metadata(last_super_heading_package,
			PHRASEBOOK_SUPER_HEADING_TEXT_MD_HL, I"Defined in the source");
	} else if (Extensions::is_standard(this_extension)) {
		TEMPORARY_TEXT(credit)
		WRITE_TO(credit, "From the extension ");
		Extensions::write_name_to_file(this_extension, credit);
		last_super_heading_package =
			Hierarchy::completion_package(PHRASEBOOK_SUPER_HEADING_HAP);
		Hierarchy::apply_metadata(last_super_heading_package,
			PHRASEBOOK_SUPER_HEADING_TEXT_MD_HL, credit);
		DISCARD_TEXT(credit)
	} else {
		TEMPORARY_TEXT(credit)
		WRITE_TO(credit, "From the extension ");
		Extensions::write_name_to_file(this_extension, credit);
		WRITE_TO(credit, " by ");
		Extensions::write_author_to_file(this_extension, credit);
		last_super_heading_package =
			Hierarchy::completion_package(PHRASEBOOK_SUPER_HEADING_HAP);
		Hierarchy::apply_metadata(last_super_heading_package,
			PHRASEBOOK_SUPER_HEADING_TEXT_MD_HL, credit);
		DISCARD_TEXT(credit)
	}
	no_subdivision_yet = TRUE;
	last_heading_package = NULL;
	last_heading_named = NULL;

@ In pass 1, subdivisions are shown in a comma-separated list; in pass 2,
each has a paragraph of its own.

@<Mark a subdivision in the Phrasebook@> =
	wording HW = Headings::get_text(this_heading);
	if (Wordings::nonempty(HW)) {
		@<Strip away bracketed matter in the heading name@>;
		if (Extensions::is_standard(this_extension))
			@<Mark a faked division due to inter-hyphen clue in SR heading@>;
	}
	TEMPORARY_TEXT(SUBH)
	if (Wordings::nonempty(HW)) WRITE_TO(SUBH, "%+W", HW);
	else WRITE_TO(SUBH, "Miscellaneous");
	last_heading_package =
		Hierarchy::package_within(PHRASEBOOK_HEADING_HAP, last_super_heading_package);
	Hierarchy::apply_metadata(last_heading_package,
		PHRASEBOOK_HEADING_TEXT_MD_HL, SUBH);
	DISCARD_TEXT(SUBH)
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
	... - ... |          ==> { 2, - }
	...                  ==> { 1, - }

@ We then extract "Control phrases" as the "clue".

@<Mark a faked division due to inter-hyphen clue in SR heading@> =
	<heading-name-hyphenated>(HW);
	if (<<r>> == 3) {
		wording C = GET_RW(<heading-name-hyphenated>, 2);
		if ((Wordings::empty(CLW)) || (Wordings::match(C, CLW) == FALSE)) {
			CLW = C;
			last_heading_package =
				Hierarchy::package_within(PHRASEBOOK_HEADING_HAP, last_super_heading_package);
			Hierarchy::apply_metadata_from_raw_wording(last_heading_package,
				PHRASEBOOK_HEADING_TEXT_MD_HL, C);
			no_subdivision_yet = TRUE;
		}
		HW = GET_RW(<heading-name-hyphenated>, 3);
	} else if (<<r>> == 2) {
		HW = GET_RW(<heading-name-hyphenated>, 2);
	}

@ We see where |idb| is in a run of phrases which share a common documentation
symbol; only the first in the run has a plus-sign link to reveal the box of
documentation in question, and only the last in the run is followed by the
code for the box.

@<Actually index the phrase@> =
	TEMPORARY_TEXT(OUT)
	id_body *idb2 = idb, *run_end = idb;
	if (RTPhrasebook::ph_same_doc(idb, run_begin) == FALSE) run_begin = idb;
	while ((idb2) && (RTPhrasebook::ph_same_doc(idb, idb2))) {
		run_end = idb2; idb2 = NEXT_OBJECT(idb2, id_body);
	}

	HTML_OPEN_WITH("p", "class=\"tightin2\"");
	if (run_begin == idb) IndexUtilities::extra_link(OUT, run_end->allocation_id);
	else IndexUtilities::noextra_link(OUT);
	RTPhrasebook::index_type_data(OUT, &(idb->type_data), idb);
	if (IDTypeData::deprecated(&(idb->type_data)))
		IndexUtilities::deprecation_icon(OUT, run_begin->allocation_id);
	IndexUtilities::link(OUT, Wordings::first_wn(Node::get_text(ImperativeDefinitions::body_at(idb))));
	HTML_CLOSE("p");

	if (run_end == idb) {
		IndexUtilities::extra_div_open(OUT, idb->allocation_id, 3, "e0e0e0");
		RTPhrasebook::write_reveal_box(OUT, &(run_begin->type_data), run_begin);
		IndexUtilities::extra_div_close(OUT, "e0e0e0");
	}
	package_request *entry =
				Hierarchy::package_within(PHRASEBOOK_ENTRY_HAP, last_heading_package);
	Hierarchy::apply_metadata(entry, PHRASEBOOK_ENTRY_TEXT_MD_HL, OUT);
	DISCARD_TEXT(OUT)

@ Where the following detects if two phrases have the same documentation
symbol, i.e., are essentially rewordings of the same phrase, and will have
a single shared reveal-box:

=
int RTPhrasebook::ph_same_doc(id_body *p1, id_body *p2) {
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
void RTPhrasebook::index_definition_area(OUTPUT_STREAM, wording W, int show_if_unhyphenated) {
	<heading-name-hyphenated>(W);
	if ((<<r>> == 1) && (show_if_unhyphenated == FALSE)) return;
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
}

@ Writing type data in the Phrasebook index:

=
void RTPhrasebook::index_type_data(OUTPUT_STREAM, id_type_data *idtd, id_body *idb) {
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
void RTPhrasebook::write_reveal_box(OUTPUT_STREAM, id_type_data *idtd, id_body *idb) {
	HTML_OPEN("p");
	@<Present a paste button containing the text of the phrase@>;
	RTPhrasebook::index_type_data(OUT, idtd, idb);
	RTPhrasebook::index_phrase_options(OUT, &(idb->type_data.options_data));
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
		DocReferences::doc_fragment(OUT, pds);
		HTML_OPEN("p"); WRITE("<b>See</b> ");
		DocReferences::fully_link(OUT, pds);
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

@ =
void RTPhrasebook::index_phrase_options(OUTPUT_STREAM, id_options_data *phod) {
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

