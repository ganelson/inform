[TokensElement::] Tokens Element.

To write the Tokens element (To) in the index.

@ =
void TokensElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.To.Explanation1");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	Localisation::roman(OUT, LD, I"Index.Elements.To.Explanation2");
	HTML_CLOSE("p");
	inter_tree *I = Indexing::get_tree(session);

	TokensElement::token(OUT, I, "anybody", NULL, I"someone_token", I"[any person]", NULL, LD);
	TokensElement::token(OUT, I, "anyone", NULL, I"someone_token", I"[any person]", NULL, LD);
	TokensElement::token(OUT, I, "anything", NULL, I"things_token", I"[any thing]", NULL, LD);
	TokensElement::token(OUT, I, "other things", NULL, I"things_token", NULL, NULL, LD);
	TokensElement::token(OUT, I, "somebody", NULL, I"someone_token", I"[someone]", NULL, LD);
	TokensElement::token(OUT, I, "someone", NULL, I"someone_token", NULL, NULL, LD);
	TokensElement::token(OUT, I, "something", NULL, I"things_token", NULL,
		I"Index.Elements.To.Something", LD);
	TokensElement::token(OUT, I, "something preferably held", NULL, I"things_token", NULL, NULL, LD);
	TokensElement::token(OUT, I, "text", NULL, I"text_token", NULL, NULL, LD);
	TokensElement::token(OUT, I, "things", NULL, I"things_token", NULL, NULL, LD);
	TokensElement::token(OUT, I, "things inside", NULL, I"things_token", NULL, NULL, LD);
	TokensElement::token(OUT, I, "things preferably held", NULL, I"things_token", NULL, NULL, LD);

	inter_package *pack = InterPackage::from_URL(I, I"/main/completion/grammar");
	inter_package *cg_pack;
	LOOP_THROUGH_SUBPACKAGES(cg_pack, pack, I"_command_grammar")
		if (Metadata::read_optional_numeric(cg_pack, I"^is_token"))
			TokensElement::token(OUT, I, NULL, cg_pack, NULL, NULL, NULL, LD);
}

@ So, then, this function is sometimes called for the standard built-in tokens,
in which case |special| is set, and sometimes for those created by source text,
when |special| is null.

=
void TokensElement::token(OUTPUT_STREAM, inter_tree *I, char *special,
	inter_package *cg_pack, text_stream *doc_ref, text_stream *same_as,
	text_stream *additional, localisation_dictionary *LD) {
	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("\"[");
	if (special) WRITE("%s", special);
	else if (cg_pack) WRITE("%S", Metadata::optional_textual(cg_pack, I"^name"));
	WRITE("]\"");
	if (cg_pack) IndexUtilities::link_package(OUT, cg_pack);
	if (Str::len(doc_ref) > 0) DocReferences::link(OUT, doc_ref);
	if (Str::len(same_as) > 0) {
		WRITE(" - ");
		Localisation::roman_t(OUT, LD, I"Index.Elements.To.SameAs", same_as);
	}
	if (Str::len(additional) > 0) {
		WRITE(" - ");
		Localisation::roman(OUT, LD, additional);
	}
	HTML_CLOSE("p");
	if (cg_pack) {
		int k = 0;
		inter_package *line_pack;
		LOOP_THROUGH_SUBPACKAGES(line_pack, cg_pack, I"_cg_line") {
			text_stream *trueverb = Metadata::optional_textual(line_pack, I"^true_verb");
			HTML::open_indented_p(OUT, 2, "hanging");
			if (k++ == 0) WRITE("="); else WRITE("or");
			WRITE(" &quot;");
			TokensElement::verb_definition(OUT,
				Metadata::optional_textual(line_pack, I"^text"),
				trueverb, EMPTY_WORDING);
			WRITE("&quot;");
			IndexUtilities::link_package(OUT, line_pack);
			if (Metadata::read_optional_numeric(line_pack, I"^reversed")) {
				WRITE(" ");
				Localisation::roman(OUT, LD, I"Index.Elements.To.Reversed");
			}
			HTML_CLOSE("p");
		}
	}
}

@ This function is also used by //Commands Element//.

=
void TokensElement::verb_definition(OUTPUT_STREAM, text_stream *T, text_stream *trueverb,
	wording W) {
	int i = 1;
	if (Str::len(T) < 2) return;
	if (Str::len(trueverb) > 0) {
		if (Str::eq_wide_string(trueverb, U"0") == FALSE) {
			WRITE("%S", trueverb);
			for (i=1; Str::get_at(T, i+1); i++) if (Str::get_at(T, i) == ' ') break;
			for (; Str::get_at(T, i+1); i++) if (Str::get_at(T, i) != ' ') break;
			if (Str::get_at(T, i+1)) WRITE(" ");
		}
	}
	for (; Str::get_at(T, i+1); i++) {
		inchar32_t c = Str::get_at(T, i);
		switch(c) {
			case '"': WRITE("&quot;"); break;
			default: PUT_TO(OUT, c); break;
		}
	}
}
