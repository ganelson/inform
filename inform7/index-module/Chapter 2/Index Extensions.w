[IndexExtensions::] Index Extensions.

To keep details of the extensions currently loaded, their authors,
titles, versions and rubrics, and to index and credit them suitably.

@h Indexing extensions in the Contents index.
The routine below places a list of extensions used in the Contents index,
giving only minimal entries about them.

=
void IndexExtensions::index(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("EXTENSIONS"); HTML_CLOSE("p");
	IndexExtensions::index_extensions_from(OUT, NULL);
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Extensions::is_standard(E) == FALSE)
			IndexExtensions::index_extensions_from(OUT, E);
	LOOP_OVER(E, inform_extension)
		if (Extensions::is_standard(E))
			IndexExtensions::index_extensions_from(OUT, E);
	HTML_OPEN("p"); HTML_CLOSE("p");
}

void IndexExtensions::index_extensions_from(OUTPUT_STREAM, inform_extension *from) {
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

@ Nothing can prevent a certain repetitiousness intruding here, but there is
just enough local knowledge required to make it foolhardy to try to automate
this from a dump of the excerpt meanings table (say). The ordering of
paragraphs, as in Roget's Thesaurus, tries to proceed from solid things
through to diffuse linguistic ones. But the reader of the resulting
documentation page could be forgiven for thinking it a miscellany.

=
void IndexExtensions::document_in_detail(OUTPUT_STREAM, inform_extension *E) {
	ExtensionDictionary::erase_entries_concerning(E);
	ExtensionDictionary::time_stamp(E);

	@<Document and dictionary the kinds made in extension@>;
	@<Document and dictionary the objects made in extension@>;

	@<Document and dictionary the global variables made in extension@>;
	@<Document and dictionary the enumerated constant values made in extension@>;

	@<Document and dictionary the kinds of action made in extension@>;
	@<Document and dictionary the actions made in extension@>;

	@<Document and dictionary the verbs made in extension@>;
	@<Document and dictionary the adjectival phrases made in extension@>;
	@<Document and dictionary the property names made in extension@>;

	@<Document and dictionary the use options made in extension@>;
}

@ Off we go, then. Kinds of object:

@<Document and dictionary the kinds made in extension@> =
	kind *K;
	int kc = 0;
	LOOP_OVER_BASE_KINDS(K) {
		parse_node *S = Kinds::Behaviour::get_creating_sentence(K);
		if (S) {
			if (Lexer::file_of_origin(Wordings::first_wn(Node::get_text(S))) == E->read_into_file) {
				wording W = Kinds::Behaviour::get_name(K, FALSE);
				kc = IndexExtensions::document_headword(OUT, kc, E, "Kinds", I"kind", W);
				kind *S = Latticework::super(K);
				if (S) {
					W = Kinds::Behaviour::get_name(S, FALSE);
					if (Wordings::nonempty(W)) WRITE(" (a kind of %+W)", W);
				}
			}
		}
	}
	if (kc != 0) HTML_CLOSE("p");

@ Actual objects:

@<Document and dictionary the objects made in extension@> =
	instance *I;
	int kc = 0;
	LOOP_OVER_INSTANCES(I, K_object) {
		wording OW = Instances::get_name(I, FALSE);
		if ((Instances::get_creating_sentence(I)) && (Wordings::nonempty(OW))) {
			if (Lexer::file_of_origin(
				Wordings::first_wn(Node::get_text(Instances::get_creating_sentence(I))))
					== E->read_into_file) {
				TEMPORARY_TEXT(name_of_its_kind)
				kind *k = Instances::to_kind(I);
				wording W = Kinds::Behaviour::get_name(k, FALSE);
				WRITE_TO(name_of_its_kind, "%+W", W);
				kc = IndexExtensions::document_headword(OUT, kc, E,
					"Physical creations", name_of_its_kind, OW);
				WRITE(" (a %S)", name_of_its_kind);
				DISCARD_TEXT(name_of_its_kind)
			}
		}
	}
	if (kc != 0) HTML_CLOSE("p");

@ Global variables:

@<Document and dictionary the global variables made in extension@> =
	nonlocal_variable *q;
	int kc = 0;
	LOOP_OVER(q, nonlocal_variable)
		if ((Wordings::first_wn(q->name) >= 0) &&
			(NonlocalVariables::is_global(q)) &&
			(Lexer::file_of_origin(Wordings::first_wn(q->name)) == E->read_into_file) &&
			(Headings::indexed(Headings::of_wording(q->name)))) {
			if (<value-understood-variable-name>(q->name) == FALSE)
				kc = IndexExtensions::document_headword(OUT,
					kc, E, "Values that vary", I"value", q->name);
		}
	if (kc != 0) HTML_CLOSE("p");

@ Constants:

@<Document and dictionary the enumerated constant values made in extension@> =
	instance *q;
	int kc = 0;
	LOOP_OVER(q, instance) {
		if (Kinds::Behaviour::is_an_enumeration(Instances::to_kind(q))) {
			wording NW = Instances::get_name(q, FALSE);
			if ((Wordings::nonempty(NW)) && (Lexer::file_of_origin(Wordings::first_wn(NW)) == E->read_into_file))
				kc = IndexExtensions::document_headword(OUT, kc, E, "Values", I"value", NW);
		}
	}
	if (kc != 0) HTML_CLOSE("p");

@ Kinds of action:

@<Document and dictionary the kinds of action made in extension@> =
	#ifdef IF_MODULE
	PL::Actions::Patterns::Named::index_for_extension(OUT, E->read_into_file, E);
	#endif

@ Actions:

@<Document and dictionary the actions made in extension@> =
	#ifdef IF_MODULE
	PL::Actions::Index::index_for_extension(OUT, E->read_into_file, E);
	#endif

@ Verbs (this one we delegate):

@<Document and dictionary the verbs made in extension@> =
	IndexLexicon::list_verbs_in_file(OUT, E->read_into_file, E);

@ Adjectival phrases:

@<Document and dictionary the adjectival phrases made in extension@> =
	adjective *adj;
	int kc = 0;
	LOOP_OVER(adj, adjective) {
		wording W = Adjectives::get_nominative_singular(adj);
		if ((Wordings::nonempty(W)) &&
			(Lexer::file_of_origin(Wordings::first_wn(W)) == E->read_into_file))
			kc = IndexExtensions::document_headword(OUT, kc, E, "Adjectives", I"adjective", W);
	}
	if (kc != 0) HTML_CLOSE("p");

@ Other adjectives:

@<Document and dictionary the property names made in extension@> =
	property *prn;
	int kc = 0;
	LOOP_OVER(prn, property)
		if ((Wordings::nonempty(prn->name)) &&
			(Properties::is_shown_in_index(prn)) &&
			(Lexer::file_of_origin(Wordings::first_wn(prn->name)) == E->read_into_file))
			kc = IndexExtensions::document_headword(OUT, kc, E, "Properties", I"property",
				prn->name);
	if (kc != 0) HTML_CLOSE("p");

@ Use options:

@<Document and dictionary the use options made in extension@> =
	use_option *uo;
	int kc = 0;
	LOOP_OVER(uo, use_option)
		if ((Wordings::first_wn(uo->name) >= 0) &&
			(Lexer::file_of_origin(Wordings::first_wn(uo->name)) == E->read_into_file))
			kc = IndexExtensions::document_headword(OUT, kc, E, "Use options", I"use option",
				uo->name);
	if (kc != 0) HTML_CLOSE("p");

@ Finally, the utility routine which keeps count (hence |kc|) and displays
suitable lists, while entering each entry in turn into the extension
dictionary.

=
int IndexExtensions::document_headword(OUTPUT_STREAM, int kc, inform_extension *E, char *par_heading,
	text_stream *category, wording W) {
	if (kc++ == 0) { HTML_OPEN("p"); WRITE("%s: ", par_heading); }
	else WRITE(", ");
	WRITE("<b>%+W</b>", W);
	ExtensionDictionary::new_entry_from_wording(category, E, W);
	return kc;
}
