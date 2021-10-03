[Veneer::] The Veneer.

@

@d MAX_VSYMBS 100

@e DICTIONARY_TABLE_VSYMB from 0
@e ACTIONS_TABLE_VSYMB
@e GRAMMAR_TABLE_VSYMB
@e SELF_VSYMB

@e CHILDREN_VSYMB
@e PARENT_VSYMB
@e CHILD_VSYMB
@e SIBLING_VSYMB
@e RANDOM_VSYMB
@e SPACES_VSYMB
@e METACLASS_VSYMB

@e ROUTINE_VSYMB
@e STRING_VSYMB
@e CLASS_VSYMB
@e OBJECT_VSYMB

@e ASM_ARROW_VSYMB
@e ASM_SP_VSYMB
@e ASM_LABEL_VSYMB
@e ASM_RTRUE_VSYMB
@e ASM_RFALSE_VSYMB
@e ASM_NEG_VSYMB
@e ASM_NEG_RTRUE_VSYMB
@e ASM_NEG_RFALSE_VSYMB

@e VALUE_PROPERTY_HOLDERS_VSYMB
@e VALUE_RANGES_VSYMB
@e RESPONSETEXTS_VSYMB
@e CREATEPROPERTYOFFSETS_VSYMB
@e KINDHIERARCHY_VSYMB
@e NO_RESPONSES_VSYMB

=
void Veneer::create_indexes(inter_tree *I) {
	Veneer::index(I, DICTIONARY_TABLE_VSYMB, I"#dictionary_table", NULL);
	Veneer::index(I, ACTIONS_TABLE_VSYMB, I"#actions_table", NULL);
	Veneer::index(I, GRAMMAR_TABLE_VSYMB, I"#grammar_table", NULL);
	Veneer::index(I, SELF_VSYMB, I"self", NULL);
	
	Veneer::index(I, PARENT_VSYMB, I"parent", NULL);
	Veneer::index(I, CHILD_VSYMB, I"child", NULL);
	Veneer::index(I, SIBLING_VSYMB, I"sibling", NULL);
	Veneer::index(I, RANDOM_VSYMB, I"random", NULL);
	Veneer::index(I, METACLASS_VSYMB, I"metaclass", NULL);
	Veneer::index(I, CHILDREN_VSYMB, I"children", NULL);

	Veneer::index(I, ROUTINE_VSYMB, I"Routine", NULL);
	Veneer::index(I, STRING_VSYMB, I"String", NULL);
	Veneer::index(I, CLASS_VSYMB, I"Class", NULL);
	Veneer::index(I, OBJECT_VSYMB, I"Object", NULL);

	Veneer::index(I, ASM_ARROW_VSYMB, I"__assembly_arrow", I"->");
	Veneer::index(I, ASM_SP_VSYMB, I"__assembly_sp", I"sp");
	Veneer::index(I, ASM_LABEL_VSYMB, I"__assembly_label", I"?");
	Veneer::index(I, ASM_RTRUE_VSYMB, I"__assembly_rtrue_label", I"?rtrue");
	Veneer::index(I, ASM_RFALSE_VSYMB, I"__assembly_rfalse_label", I"?rfalse");
	Veneer::index(I, ASM_NEG_VSYMB, I"__assembly_negated_label", I"~");
	Veneer::index(I, ASM_NEG_RTRUE_VSYMB, I"__assembly_negated_rtrue_label", I"?~rtrue");
	Veneer::index(I, ASM_NEG_RFALSE_VSYMB, I"__assembly_negated_rfalse_label", I"?~rfalse");

	Veneer::index(I, VALUE_PROPERTY_HOLDERS_VSYMB, I"value_property_holders", NULL);
	Veneer::index(I, VALUE_RANGES_VSYMB, I"value_ranges", NULL);
	Veneer::index(I, RESPONSETEXTS_VSYMB, I"ResponseTexts", NULL);
	Veneer::index(I, CREATEPROPERTYOFFSETS_VSYMB, I"CreatePropertyOffsets", NULL);
	Veneer::index(I, KINDHIERARCHY_VSYMB, I"KindHierarchy", NULL);
	Veneer::index(I, NO_RESPONSES_VSYMB, I"NO_RESPONSES", NULL);
}

void Veneer::index(inter_tree *I, int ix, text_stream *S, text_stream *T) {
	Dictionaries::create(I->site.veneer_symbols_indexed_by_name, S);
	Dictionaries::write_value(I->site.veneer_symbols_indexed_by_name, S,
		(void *) &(I->site.veneer_symbols[ix]));
	I->site.veneer_symbol_names[ix] = Str::duplicate(S);
	I->site.veneer_symbol_translations[ix] = Str::duplicate(T);
}

inter_symbol *Veneer::find_by_index(inter_tree *I, int ix, inter_symbol *unchecked_kind_symbol) {
	inter_symbol **slot = &(I->site.veneer_symbols[ix]);
	return Veneer::make(I, slot, I->site.veneer_symbol_names[ix], I->site.veneer_symbol_translations[ix], unchecked_kind_symbol);
}

inter_symbol *Veneer::find(inter_tree *I, text_stream *S, inter_symbol *unchecked_kind_symbol) {
	if (Dictionaries::find(I->site.veneer_symbols_indexed_by_name, S)) {
		inter_symbol **slot = (inter_symbol **) Dictionaries::read_value(I->site.veneer_symbols_indexed_by_name, S);
		if (slot == NULL) internal_error("accident with veneer dictionary");
		if (*slot) return *slot;
		for (int ix=0; ix<MAX_VSYMBS; ix++)
			if (Str::eq(I->site.veneer_symbol_names[ix], S))
				return Veneer::find_by_index(I, ix, unchecked_kind_symbol);
		internal_error("indexing accident with veneer dictionary");
	}
	return NULL;
}

inter_symbol *Veneer::make(inter_tree *I, inter_symbol **slot, text_stream *S, text_stream *T, inter_symbol *unchecked_kind_symbol) {
	if (*slot == NULL) {
		inter_package *veneer_package = Packaging::incarnate(Site::veneer_request(I));
		inter_bookmark *IBM = Site::veneer_booknark(I);
		inter_symbols_table *tab = Inter::Packages::scope(veneer_package);
		*slot = InterSymbolsTables::symbol_from_name_creating(tab, S);
		if (Str::len(T) > 0) Inter::Symbols::set_translate(*slot, T);
		Inter::Symbols::annotate_i(*slot, VENEER_IANN, 1);
		Produce::guard(Inter::Constant::new_numerical(IBM,
			InterSymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), veneer_package, *slot),
			InterSymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), veneer_package, unchecked_kind_symbol),
			LITERAL_IVAL, 0,
			(inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
	}
	return *slot;
}
