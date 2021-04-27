[Metadata::] Metadata.

Looking up metadata in special constants.

@ =
int Metadata::valid_key(text_stream *key) {
	if (Str::get_at(key, 0) == '^') return TRUE;
	return FALSE;
}

inter_symbol *Metadata::read_symbol(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) {
		LOG("unable to find metadata key %S in package $6\n", key, pack);
		internal_error("not found");
	}
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) {
		LOG("%d\n", D->W.data[FORMAT_CONST_IFLD]);
		internal_error("not direct");
	}
	if (D->W.data[DATA_CONST_IFLD] != ALIAS_IVAL) internal_error("not symbol");

	inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack),
		D->W.data[DATA_CONST_IFLD + 1]);
	if (s == NULL) internal_error("no symbol");
	return s;
}

inter_symbol *Metadata::read_optional_symbol(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return NULL;
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) {
		LOG("%d\n", D->W.data[FORMAT_CONST_IFLD]);
		internal_error("not direct");
	}
	if (D->W.data[DATA_CONST_IFLD] != ALIAS_IVAL) internal_error("not symbol");

	inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack),
		D->W.data[DATA_CONST_IFLD + 1]);
	if (s == NULL) internal_error("no symbol");
	return s;
}

inter_ti Metadata::read_numeric(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) internal_error("not found");
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) internal_error("not direct");
	if (D->W.data[DATA_CONST_IFLD] != LITERAL_IVAL) internal_error("not literal");
	return D->W.data[DATA_CONST_IFLD + 1];
}

inter_ti Metadata::read_optional_numeric(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return 0;
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) internal_error("not direct");
	if (D->W.data[DATA_CONST_IFLD] != LITERAL_IVAL) internal_error("not literal");
	return D->W.data[DATA_CONST_IFLD + 1];
}

text_stream *Metadata::read_textual(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) internal_error("not found");
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_INDIRECT_TEXT)  {
		LOG("%d\n", D->W.data[FORMAT_CONST_IFLD]);
		internal_error("not text");
	}
	return Inode::ID_to_text(D, D->W.data[DATA_CONST_IFLD]);
}

text_stream *Metadata::read_optional_textual(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return NULL;
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_INDIRECT_TEXT)  {
		LOG("%d\n", D->W.data[FORMAT_CONST_IFLD]);
		internal_error("not text");
	}
	return Inode::ID_to_text(D, D->W.data[DATA_CONST_IFLD]);
}
