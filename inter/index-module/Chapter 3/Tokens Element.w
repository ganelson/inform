[TokensElement::] Tokens Element.

To write the Tokens element (To) in the index.

@ =
void TokensElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	HTML_OPEN("p");
	WRITE("In addition to the tokens listed below, any description of an object "
		"or value can be used: for example, \"[number]\" matches text like 127 or "
		" SIX, and \"[open door]\" matches the name of any nearby door which is "
		"currently open.");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("Names of objects are normally understood only when they are within "
		"sight, but writing 'any' lifts this restriction. So \"[any person]\" allows "
		"every name of a person, wherever they happen to be.");
	HTML_CLOSE("p");
	inter_tree *I = InterpretIndex::get_tree();
	TokensElement::index_tokens_for(OUT, I, "anybody", NULL, I"someone_token", "same as \"[someone]\"");
	TokensElement::index_tokens_for(OUT, I, "anyone", NULL, I"someone_token", "same as \"[someone]\"");
	TokensElement::index_tokens_for(OUT, I, "anything", NULL, I"things_token", "same as \"[thing]\"");
	TokensElement::index_tokens_for(OUT, I, "other things", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, I, "somebody", NULL, I"someone_token", "same as \"[someone]\"");
	TokensElement::index_tokens_for(OUT, I, "someone", NULL, I"someone_token", NULL);
	TokensElement::index_tokens_for(OUT, I, "something", NULL, I"things_token", "same as \"[thing]\"");
	TokensElement::index_tokens_for(OUT, I, "something preferably held", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, I, "text", NULL, I"text_token", NULL);
	TokensElement::index_tokens_for(OUT, I, "things", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, I, "things inside", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, I, "things preferably held", NULL, I"things_token", NULL);
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/grammar");
	inter_package *cg_pack;
	LOOP_THROUGH_SUBPACKAGES(cg_pack, pack, I"_command_grammar") {
		if (Metadata::read_optional_numeric(cg_pack, I"^is_token"))
			TokensElement::index_tokens_for(OUT, I, NULL, cg_pack, NULL, NULL);
	}
}

void TokensElement::index_tokens_for(OUTPUT_STREAM, inter_tree *I, char *special, inter_package *defns,
	text_stream *help, char *explanation) {
	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("\"[");
	if (special) WRITE("%s", special);
	else if (defns) WRITE("%S", Metadata::read_optional_textual(defns, I"^name"));
	WRITE("]\"");
	if (defns) IndexUtilities::link_package(OUT, defns);
	if (Str::len(help) > 0) IndexUtilities::DocReferences::link(OUT, help);
	if (explanation) WRITE(" - %s", explanation);
	HTML_CLOSE("p");
	if (defns) TokensElement::index_list_for_token(OUT, I, defns);
}

void TokensElement::index_list_for_token(OUTPUT_STREAM, inter_tree *I, inter_package *cg) {
	int k = 0;
	inter_package *line_pack;
	LOOP_THROUGH_SUBPACKAGES(line_pack, cg, I"_cg_line") {
		text_stream *trueverb = Metadata::read_optional_textual(line_pack, I"^true_verb");
		HTML::open_indented_p(OUT, 2, "hanging");
		if (k++ == 0) WRITE("="); else WRITE("or");
		WRITE(" &quot;");
		TokensElement::verb_definition(OUT,
			Metadata::read_optional_textual(line_pack, I"^text"),
			trueverb, EMPTY_WORDING);
		WRITE("&quot;");
		IndexUtilities::link_package(OUT, line_pack);
		if (Metadata::read_optional_numeric(line_pack, I"^reversed"))
			WRITE(" <i>reversed</i>");
		HTML_CLOSE("p");
	}
}

void TokensElement::verb_definition(OUTPUT_STREAM, text_stream *T, text_stream *trueverb, wording W) {
	int i = 1;
	if (Str::len(T) < 2) return;
	if (Str::len(trueverb) > 0) {
		if (Str::eq_wide_string(trueverb, L"0") == FALSE) {
			WRITE("%S", trueverb);
			for (i=1; Str::get_at(T, i+1); i++) if (Str::get_at(T, i) == ' ') break;
			for (; Str::get_at(T, i+1); i++) if (Str::get_at(T, i) != ' ') break;
			if (Str::get_at(T, i+1)) WRITE(" ");
		}
	}
	for (; Str::get_at(T, i+1); i++) {
		wchar_t c = Str::get_at(T, i);
		switch(c) {
			case '"': WRITE("&quot;"); break;
			default: PUT_TO(OUT, c); break;
		}
	}
}
