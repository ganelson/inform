[Veneer::] The Veneer.

@

@d MAX_VSYMBS 100

@e NOTHING_VSYMB from 0

@e DICTIONARY_TABLE_VSYMB
@e DICT_PAR1_VSYMB
@e DICT_PAR2_VSYMB
@e LARGEST_OBJECT_VSYMB
@e ACTIONS_TABLE_VSYMB
@e IDENTIFIERS_TABLE_VSYMB
@e GRAMMAR_TABLE_VSYMB
@e VERSION_NUMBER_VSYMB
@e CLASSES_TABLE_VSYMB
@e GLOBALS_ARRAY_VSYMB
@e SELF_VSYMB
@e GSELF_VSYMB
@e CPV__START_VSYMB
@e NUM_ATTR_BYTES_VSYMB

@e CHILDREN_VSYMB
@e PARENT_VSYMB
@e CHILD_VSYMB
@e SIBLING_VSYMB
@e RANDOM_VSYMB
@e INDIRECT_VSYMB
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

@e Z__REGION_VSYMB
@e CP__TAB_VSYMB
@e RA__PR_VSYMB
@e RL__PR_VSYMB
@e OC__CL_VSYMB
@e RV__PR_VSYMB
@e OP__PR_VSYMB
@e CA__PR_VSYMB
@e RT__ERR_VSYMB

@e FLOAT_NAN_VSYMB

@e PROPERTY_METADATA_VSYMB
@e FBNA_PROP_NUMBER_VSYMB
@e VALUE_PROPERTY_HOLDERS_VSYMB
@e VALUE_RANGE_VSYMB
@e RESPONSETEXTS_VSYMB
@e CREATEPROPERTYOFFSETS_VSYMB
@e KINDHIERARCHY_VSYMB
@e SAVED_SHORT_NAME_VSYMB
@e NO_RESPONSES_VSYMB

=
void Veneer::create_indexes(inter_tree *I) {
	Veneer::index(I, NOTHING_VSYMB, I"nothing", NULL);

	Veneer::index(I, DICTIONARY_TABLE_VSYMB, I"#dictionary_table", NULL);
	Veneer::index(I, DICT_PAR1_VSYMB, I"#dict_par1", NULL);
	Veneer::index(I, DICT_PAR2_VSYMB, I"#dict_par2", NULL);
	Veneer::index(I, LARGEST_OBJECT_VSYMB, I"#largest_object", NULL);
	Veneer::index(I, ACTIONS_TABLE_VSYMB, I"#actions_table", NULL);
	Veneer::index(I, IDENTIFIERS_TABLE_VSYMB, I"#identifiers_table", NULL);
	Veneer::index(I, GRAMMAR_TABLE_VSYMB, I"#grammar_table", NULL);
	Veneer::index(I, VERSION_NUMBER_VSYMB, I"#version_number", NULL);
	Veneer::index(I, CLASSES_TABLE_VSYMB, I"#classes_table", NULL);
	Veneer::index(I, GLOBALS_ARRAY_VSYMB, I"#globals_array", NULL);
	Veneer::index(I, SELF_VSYMB, I"self", NULL);
	Veneer::index(I, GSELF_VSYMB, I"#g$self", NULL);
	Veneer::index(I, CPV__START_VSYMB, I"#cpv__start", NULL);
	Veneer::index(I, NUM_ATTR_BYTES_VSYMB, I"NUM_ATTR_BYTES", NULL);
	
	Veneer::index(I, PARENT_VSYMB, I"parent", NULL);
	Veneer::index(I, CHILD_VSYMB, I"child", NULL);
	Veneer::index(I, SIBLING_VSYMB, I"sibling", NULL);
	Veneer::index(I, INDIRECT_VSYMB, I"indirect", NULL);
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

	Veneer::index(I, Z__REGION_VSYMB, I"Z__Region", NULL);
	Veneer::index(I, CP__TAB_VSYMB, I"CP__Tab", NULL);
	Veneer::index(I, RA__PR_VSYMB, I"RA__Pr", NULL);
	Veneer::index(I, RL__PR_VSYMB, I"RL__Pr", NULL);
	Veneer::index(I, OC__CL_VSYMB, I"OC__Cl", NULL);
	Veneer::index(I, RV__PR_VSYMB, I"RV__Pr", NULL);
	Veneer::index(I, OP__PR_VSYMB, I"OP__Pr", NULL);
	Veneer::index(I, CA__PR_VSYMB, I"CA__Pr", NULL);
	Veneer::index(I, RT__ERR_VSYMB, I"RT__Err", NULL);

	Veneer::index(I, FLOAT_NAN_VSYMB, I"FLOAT_NAN", NULL);

	Veneer::index(I, PROPERTY_METADATA_VSYMB, I"property_metadata", NULL);
	Veneer::index(I, FBNA_PROP_NUMBER_VSYMB, I"FBNA_PROP_NUMBER", NULL);
	Veneer::index(I, VALUE_PROPERTY_HOLDERS_VSYMB, I"value_property_holders", NULL);
	Veneer::index(I, VALUE_RANGE_VSYMB, I"value_range", NULL);
	Veneer::index(I, RESPONSETEXTS_VSYMB, I"ResponseTexts", NULL);
	Veneer::index(I, CREATEPROPERTYOFFSETS_VSYMB, I"CreatePropertyOffsets", NULL);
	Veneer::index(I, KINDHIERARCHY_VSYMB, I"KindHierarchy", NULL);
	Veneer::index(I, SAVED_SHORT_NAME_VSYMB, I"saved_short_name", NULL);
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
		return Veneer::make(I, slot, S, NULL, unchecked_kind_symbol);
	}
	return NULL;
}

inter_symbol *Veneer::make(inter_tree *I, inter_symbol **slot, text_stream *S, text_stream *T, inter_symbol *unchecked_kind_symbol) {
	if (*slot == NULL) {
		inter_package *veneer_package = Packaging::incarnate(Site::veneer_request(I));
		inter_bookmark *IBM = Site::veneer_booknark(I);
		inter_symbols_table *tab = Inter::Packages::scope(veneer_package);
		*slot = Inter::SymbolsTables::symbol_from_name_creating(tab, S);
		if (Str::len(T) > 0) Inter::Symbols::set_translate(*slot, T);
		Inter::Symbols::annotate_i(*slot, VENEER_IANN, 1);
		Produce::guard(Inter::Constant::new_numerical(IBM,
			Inter::SymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), veneer_package, *slot),
			Inter::SymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), veneer_package, unchecked_kind_symbol),
			LITERAL_IVAL, 0,
			(inter_t) Inter::Bookmarks::baseline(IBM) + 1, NULL));
	}
	return *slot;
}
