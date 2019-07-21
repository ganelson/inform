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
inter_symbol *veneer_symbols[MAX_VSYMBS];
text_stream *veneer_symbol_names[MAX_VSYMBS];
text_stream *veneer_symbol_translations[MAX_VSYMBS];
dictionary *veneer_symbols_indexed_by_name = NULL;

int veneer_indexes_created = FALSE;
void Veneer::create_indexes(void) {
	veneer_indexes_created = TRUE;
	for (int i=0; i<MAX_VSYMBS; i++) veneer_symbols[i] = NULL;
	veneer_symbols_indexed_by_name = Dictionaries::new(512, FALSE);

	Veneer::index(NOTHING_VSYMB, I"nothing", NULL);

	Veneer::index(DICTIONARY_TABLE_VSYMB, I"#dictionary_table", NULL);
	Veneer::index(DICT_PAR1_VSYMB, I"#dict_par1", NULL);
	Veneer::index(DICT_PAR2_VSYMB, I"#dict_par2", NULL);
	Veneer::index(LARGEST_OBJECT_VSYMB, I"#largest_object", NULL);
	Veneer::index(ACTIONS_TABLE_VSYMB, I"#actions_table", NULL);
	Veneer::index(IDENTIFIERS_TABLE_VSYMB, I"#identifiers_table", NULL);
	Veneer::index(GRAMMAR_TABLE_VSYMB, I"#grammar_table", NULL);
	Veneer::index(VERSION_NUMBER_VSYMB, I"#version_number", NULL);
	Veneer::index(CLASSES_TABLE_VSYMB, I"#classes_table", NULL);
	Veneer::index(GLOBALS_ARRAY_VSYMB, I"#globals_array", NULL);
	Veneer::index(GSELF_VSYMB, I"#g$self", NULL);
	Veneer::index(CPV__START_VSYMB, I"#cpv__start", NULL);
	Veneer::index(NUM_ATTR_BYTES_VSYMB, I"NUM_ATTR_BYTES", NULL);
	
	Veneer::index(PARENT_VSYMB, I"parent", NULL);
	Veneer::index(CHILD_VSYMB, I"child", NULL);
	Veneer::index(SIBLING_VSYMB, I"sibling", NULL);
	Veneer::index(INDIRECT_VSYMB, I"indirect", NULL);
	Veneer::index(RANDOM_VSYMB, I"random", NULL);
	Veneer::index(METACLASS_VSYMB, I"metaclass", NULL);
	Veneer::index(CHILDREN_VSYMB, I"children", NULL);

	Veneer::index(ROUTINE_VSYMB, I"Routine", NULL);
	Veneer::index(STRING_VSYMB, I"String", NULL);
	Veneer::index(CLASS_VSYMB, I"Class", NULL);
	Veneer::index(OBJECT_VSYMB, I"Object", NULL);

	Veneer::index(ASM_ARROW_VSYMB, I"__assembly_arrow", I"->");
	Veneer::index(ASM_SP_VSYMB, I"__assembly_sp", I"sp");
	Veneer::index(ASM_LABEL_VSYMB, I"__assembly_label", I"?");
	Veneer::index(ASM_RTRUE_VSYMB, I"__assembly_rtrue_label", I"?rtrue");
	Veneer::index(ASM_RFALSE_VSYMB, I"__assembly_rfalse_label", I"?rfalse");
	Veneer::index(ASM_NEG_VSYMB, I"__assembly_negated_label", I"~");
	Veneer::index(ASM_NEG_RTRUE_VSYMB, I"__assembly_negated_rtrue_label", I"?~rtrue");
	Veneer::index(ASM_NEG_RFALSE_VSYMB, I"__assembly_negated_rfalse_label", I"?~rfalse");

	Veneer::index(Z__REGION_VSYMB, I"Z__Region", NULL);
	Veneer::index(CP__TAB_VSYMB, I"CP__Tab", NULL);
	Veneer::index(RA__PR_VSYMB, I"RA__Pr", NULL);
	Veneer::index(RL__PR_VSYMB, I"RL__Pr", NULL);
	Veneer::index(OC__CL_VSYMB, I"OC__Cl", NULL);
	Veneer::index(RV__PR_VSYMB, I"RV__Pr", NULL);
	Veneer::index(OP__PR_VSYMB, I"OP__Pr", NULL);
	Veneer::index(CA__PR_VSYMB, I"CA__Pr", NULL);
	Veneer::index(RT__ERR_VSYMB, I"RT__Err", NULL);

	Veneer::index(FLOAT_NAN_VSYMB, I"FLOAT_NAN", NULL);

	Veneer::index(PROPERTY_METADATA_VSYMB, I"property_metadata", NULL);
	Veneer::index(FBNA_PROP_NUMBER_VSYMB, I"FBNA_PROP_NUMBER", NULL);
	Veneer::index(VALUE_PROPERTY_HOLDERS_VSYMB, I"value_property_holders", NULL);
	Veneer::index(VALUE_RANGE_VSYMB, I"value_range", NULL);
	Veneer::index(RESPONSETEXTS_VSYMB, I"ResponseTexts", NULL);
	Veneer::index(CREATEPROPERTYOFFSETS_VSYMB, I"CreatePropertyOffsets", NULL);
	Veneer::index(KINDHIERARCHY_VSYMB, I"KindHierarchy", NULL);
	Veneer::index(SAVED_SHORT_NAME_VSYMB, I"saved_short_name", NULL);
	Veneer::index(NO_RESPONSES_VSYMB, I"NO_RESPONSES", NULL);
}

void Veneer::index(int ix, text_stream *S, text_stream *T) {
	Dictionaries::create(veneer_symbols_indexed_by_name, S);
	Dictionaries::write_value(veneer_symbols_indexed_by_name, S,
		(void *) &(veneer_symbols[ix]));
	veneer_symbol_names[ix] = Str::duplicate(S);
	veneer_symbol_translations[ix] = Str::duplicate(T);
}

inter_symbol *Veneer::find_by_index(inter_package *veneer_package, inter_bookmark *IBM, int ix, inter_symbol *unchecked_kind_symbol) {
	if (veneer_indexes_created == FALSE) Veneer::create_indexes();
	inter_symbol **slot = &(veneer_symbols[ix]);
	return Veneer::make(veneer_package, IBM, slot, veneer_symbol_names[ix], veneer_symbol_translations[ix], unchecked_kind_symbol);
}

inter_symbol *Veneer::find(inter_package *veneer_package, inter_bookmark *IBM, text_stream *S, inter_symbol *unchecked_kind_symbol) {
	if (veneer_indexes_created == FALSE) Veneer::create_indexes();
	if (Dictionaries::find(veneer_symbols_indexed_by_name, S)) {
		inter_symbol **slot = (inter_symbol **) Dictionaries::read_value(veneer_symbols_indexed_by_name, S);
		if (slot == NULL) internal_error("accident with veneer dictionary");
		return Veneer::make(veneer_package, IBM, slot, S, NULL, unchecked_kind_symbol);
	}
	return NULL;
}

inter_symbol *Veneer::make(inter_package *veneer_package, inter_bookmark *IBM, inter_symbol **slot, text_stream *S, text_stream *T, inter_symbol *unchecked_kind_symbol) {
	if (*slot == NULL) {
		inter_symbols_table *tab = Inter::Packages::scope(veneer_package);
		*slot = Inter::SymbolsTables::symbol_from_name_creating(tab, S);
		if (Str::len(T) > 0) Inter::Symbols::set_translate(*slot, T);
		Inter::Symbols::annotate_i(*slot, VENEER_IANN, 1);
		CodeGen::MergeTemplate::guard(Inter::Constant::new_numerical(IBM,
			Inter::SymbolsTables::id_from_symbol(IBM->read_into, veneer_package, *slot),
			Inter::SymbolsTables::id_from_symbol(IBM->read_into, veneer_package, unchecked_kind_symbol),
			LITERAL_IVAL, 0,
			(inter_t) Inter::Bookmarks::baseline(IBM) + 1, NULL));
	}
	return *slot;
}
