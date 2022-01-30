[Metadata::] Metadata.

Looking up metadata in special constants.

@ =
int Metadata::valid_key(text_stream *key) {
	if (Str::get_at(key, 0) == '^') return TRUE;
	return FALSE;
}

int Metadata::exists(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return FALSE;
	inter_tree_node *D = md->definition;
	if (D == NULL) return FALSE;
	return TRUE;
}

inter_symbol *Metadata::read_symbol(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) {
		LOG("unable to find metadata key %S in package $6\n", key, pack);
		Metadata::err("not found", pack, key);
	}
	inter_tree_node *D = md->definition;
	if (D == NULL) Metadata::err("not defined", pack, key);
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) {
		LOG("%d\n", D->W.instruction[FORMAT_CONST_IFLD]);
		Metadata::err("not direct", pack, key);
	}
	if (D->W.instruction[DATA_CONST_IFLD] != ALIAS_IVAL) Metadata::err("not symbol", pack, key);

	inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack),
		D->W.instruction[DATA_CONST_IFLD + 1]);
	if (s == NULL) Metadata::err("no symbol", pack, key);
	return s;
}

inter_symbol *Metadata::read_optional_symbol(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return NULL;
	inter_tree_node *D = md->definition;
	if (D == NULL) Metadata::err("not defined", pack, key);
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) {
		LOG("%d\n", D->W.instruction[FORMAT_CONST_IFLD]);
		Metadata::err("not direct", pack, key);
	}
	if (D->W.instruction[DATA_CONST_IFLD] != ALIAS_IVAL) Metadata::err("not symbol", pack, key);

	inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack),
		D->W.instruction[DATA_CONST_IFLD + 1]);
	if (s == NULL) Metadata::err("no symbol", pack, key);
	return s;
}

inter_tree_node *Metadata::read_optional_list(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return NULL;
	inter_tree_node *D = md->definition;
	if (D == NULL) Metadata::err("not defined", pack, key);
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONSTANT_INDIRECT_LIST) {
		LOG("%d\n", D->W.instruction[FORMAT_CONST_IFLD]);
		Metadata::err("not a list", pack, key);
	}
	return D;
}

inter_ti Metadata::read_numeric(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) Metadata::err("not found", pack, key);
	inter_tree_node *D = md->definition;
	if (D == NULL) Metadata::err("not defined", pack, key);
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) Metadata::err("not direct", pack, key);
	if (D->W.instruction[DATA_CONST_IFLD] != LITERAL_IVAL) Metadata::err("not literal", pack, key);
	return D->W.instruction[DATA_CONST_IFLD + 1];
}

inter_ti Metadata::read_optional_numeric(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return 0;
	inter_tree_node *D = md->definition;
	if (D == NULL) Metadata::err("not defined", pack, key);
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) Metadata::err("not direct", pack, key);
	if (D->W.instruction[DATA_CONST_IFLD] != LITERAL_IVAL) Metadata::err("not literal", pack, key);
	return D->W.instruction[DATA_CONST_IFLD + 1];
}

text_stream *Metadata::read_textual(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) Metadata::err("not found", pack, key);
	inter_tree_node *D = md->definition;
	if (D == NULL) Metadata::err("not defined", pack, key);
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONSTANT_INDIRECT_TEXT)  {
		LOG("%d\n", D->W.instruction[FORMAT_CONST_IFLD]);
		Metadata::err("not text", pack, key);
	}
	return Inode::ID_to_text(D, D->W.instruction[DATA_CONST_IFLD]);
}

text_stream *Metadata::read_optional_textual(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) return NULL;
	inter_tree_node *D = md->definition;
	if (D == NULL) Metadata::err("not defined", pack, key);
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONSTANT_INDIRECT_TEXT)  {
		LOG("%d\n", D->W.instruction[FORMAT_CONST_IFLD]);
		Metadata::err("not text", pack, key);
	}
	return Inode::ID_to_text(D, D->W.instruction[DATA_CONST_IFLD]);
}

void Metadata::err(char *err, inter_package *pack, text_stream *key) {
	LOG("Error on metadata %S in $6\n", key, pack);
	WRITE_TO(STDERR, "Error on metadata %S in ", key);
	Inter::Packages::write_url_name(STDERR, pack);
	WRITE_TO(STDERR, "\n");
	internal_error(err);
}
