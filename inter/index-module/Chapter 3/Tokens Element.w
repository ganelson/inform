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
	inter_symbol *wanted = PackageTypes::get(I, I"_command_grammar");
	inter_tree_node *D = Inter::Packages::definition(pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				if (Metadata::read_optional_numeric(entry, I"^is_token"))
					TokensElement::index_tokens_for(OUT, I, NULL, entry, NULL, NULL);
			}
		}
	}
}

void TokensElement::index_tokens_for(OUTPUT_STREAM, inter_tree *I, char *special, inter_package *defns,
	text_stream *help, char *explanation) {
	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("\"[");
	if (special) WRITE("%s", special);
	else if (defns) WRITE("%S", Metadata::read_optional_textual(defns, I"^name"));
	WRITE("]\"");
	if (defns) {
		int at = (int) Metadata::read_optional_numeric(defns, I"^at");
		if (at > 0) Index::link(OUT, at);
	}
	if (Str::len(help) > 0) Index::DocReferences::link(OUT, help);
	if (explanation) WRITE(" - %s", explanation);
	HTML_CLOSE("p");
	if (defns) TokensElement::index_list_for_token(OUT, I, defns);
}

void TokensElement::index_list_for_token(OUTPUT_STREAM, inter_tree *I, inter_package *cg) {
	inter_symbol *wanted = PackageTypes::get(I, I"_cg_line");
	inter_tree_node *D = Inter::Packages::definition(cg);
	int k = 0;
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				text_stream *trueverb = Metadata::read_optional_textual(entry, I"^true_verb");
				HTML::open_indented_p(OUT, 2, "hanging");
				if (k++ == 0) WRITE("="); else WRITE("or");
				WRITE(" &quot;");
				TokensElement::verb_definition(OUT,
					Metadata::read_optional_textual(entry, I"^text"),
					trueverb, EMPTY_WORDING);
				WRITE("&quot;");
				int at = (int) Metadata::read_optional_numeric(entry, I"^at");
				if (at > 0) Index::link(OUT, at);
				if (Metadata::read_optional_numeric(entry, I"^reversed"))
					WRITE(" <i>reversed</i>");
				HTML_CLOSE("p");
			}
		}
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
