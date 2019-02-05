[CodeGen::CacheCM::] Cache CM.

To cache inter definitions of rules from a given compilation module.

@h Parsing.

=
int filter_indented = FALSE;

void CodeGen::CacheCM::go(OUTPUT_STREAM, inter_repository *I) {
	filter_indented = FALSE;
	Inter::Textual::write(OUT, I, &CodeGen::CacheCM::sr_filter, 1);
	Inter::Textual::write(OUT, I, &CodeGen::CacheCM::sr_filter, 2);
	Inter::Textual::write(OUT, I, &CodeGen::CacheCM::sr_filter, 3);
}

int CodeGen::CacheCM::sr_filter(inter_frame P, int pass) {
	if (pass == 1) {
		if (P.data[ID_IFLD] == PACKAGETYPE_IST) {
			return TRUE;
		}
		if (P.data[ID_IFLD] == PRIMITIVE_IST) {
			return TRUE;
		}
	}
	if (pass == 2) {
		inter_package *pack = Inter::Packages::container(P);
		if ((pack) && (pack->package_name) && (Str::eq(pack->package_name->symbol_name, I"conjugations")))
			return TRUE;
		if (P.data[ID_IFLD] == KIND_IST) {
			return TRUE;
		}
		if (P.data[ID_IFLD] == EXPORT_IST) {
			inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_EXPORT_IFLD);
			if ((con_name) && (Inter::Symbols::get_flag(con_name, SR_CACHE_MARK_BIT)))
				return TRUE;
		}
		if (P.data[ID_IFLD] == CONSTANT_IST) {
			inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			if ((con_name) && (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1)) return FALSE;
			if ((con_name) && (Inter::Symbols::get_flag(con_name, SR_CACHE_MARK_BIT)))
				return TRUE;
		}
		if (P.data[ID_IFLD] == PACKAGE_IST) {
			inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
			if ((con_name) && (Str::eq(con_name->symbol_name, I"main"))) return TRUE;
			if ((con_name) && (Str::eq(con_name->symbol_name, I"rules"))) return TRUE;
			if ((con_name) && (Str::eq(con_name->symbol_name, I"phrases"))) return TRUE;
			if ((con_name) && (Str::eq(con_name->symbol_name, I"definitions"))) return TRUE;
			if ((con_name) && (Str::eq(con_name->symbol_name, I"conjugations"))) return TRUE;
			if ((con_name) && (Inter::Symbols::get_flag(con_name, SR_CACHE_MARK_BIT))) {
				filter_indented = TRUE;
				return TRUE;
			}
		}
		int level = Inter::Defn::get_level(P);
		if (level > 0) {
			if (filter_indented) return TRUE;
			return FALSE;
		}
		filter_indented = FALSE;
	}
	if (pass == 3) {
		if (P.data[ID_IFLD] == RESPONSE_IST) {
			inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(P, RULE_RESPONSE_IFLD);
			if ((owner_name) && (Inter::Symbols::get_flag(owner_name, SR_CACHE_MARK_BIT))) return TRUE;
		}
	}
	return FALSE;
}
