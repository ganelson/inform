[TokensElement::] Tokens Element.

To write the Tokens element (To) in the index.

@ =
void TokensElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	TokensElement::index_tokens_for(OUT, "anybody", NULL, I"someone_token", "same as \"[someone]\"");
	TokensElement::index_tokens_for(OUT, "anyone", NULL, I"someone_token", "same as \"[someone]\"");
	TokensElement::index_tokens_for(OUT, "anything", NULL, I"things_token", "same as \"[thing]\"");
	TokensElement::index_tokens_for(OUT, "other things", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, "somebody", NULL, I"someone_token", "same as \"[someone]\"");
	TokensElement::index_tokens_for(OUT, "someone", NULL, I"someone_token", NULL);
	TokensElement::index_tokens_for(OUT, "something", NULL, I"things_token", "same as \"[thing]\"");
	TokensElement::index_tokens_for(OUT, "something preferably held", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, "text", NULL, I"text_token", NULL);
	TokensElement::index_tokens_for(OUT, "things", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, "things inside", NULL, I"things_token", NULL);
	TokensElement::index_tokens_for(OUT, "things preferably held", NULL, I"things_token", NULL);
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/grammar");
	inter_symbol *wanted = PackageTypes::get(I, I"_command_grammar");
	inter_tree_node *D = Inter::Packages::definition(pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				if (Metadata::read_optional_numeric(entry, I"^is_token"))
					TokensElement::index_tokens_for(OUT, NULL, entry, NULL, NULL);
			}
		}
	}
}

void TokensElement::index_tokens_for(OUTPUT_STREAM, char *special, inter_package *defns,
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
	if (defns) TokensElement::index_list_for_token(OUT, defns);
}

void TokensElement::index_list_for_token(OUTPUT_STREAM, inter_package *cg) {
	WRITE("DEFINITION HERE");
/*	int k = 0;
	LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
		if (cgl->indexing_data.belongs_to_cg) {
			wording VW = CommandGrammars::get_verb_text(cgl->indexing_data.belongs_to_cg);
			TEMPORARY_TEXT(trueverb)
			if (Wordings::nonempty(VW))
				WRITE_TO(trueverb, "%W", Wordings::one_word(Wordings::first_wn(VW)));
			HTML::open_indented_p(OUT, 2, "hanging");
			if (k++ == 0) WRITE("="); else WRITE("or");
			WRITE(" &quot;");
			CommandsIndex::verb_definition(OUT,
				Lexer::word_text(cgl->original_text), trueverb, EMPTY_WORDING);
			WRITE("&quot;");
			Index::link(OUT, cgl->original_text);
			if (cgl->reversed) WRITE(" <i>reversed</i>");
			HTML_CLOSE("p");
			DISCARD_TEXT(trueverb)
		}
*/
}

