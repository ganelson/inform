[Produce::] Producing Inter.

@h Definitions.

@

=
void Produce::guard(inter_error_message *ERR) {
	if ((ERR) && (problem_count == 0)) { Inter::Errors::issue(ERR); /* internal_error("inter error"); */ }
}

inter_symbol *Produce::new_symbol(inter_symbols_table *T, text_stream *name) {
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if ((symb) && (Inter::Symbols::read_annotation(symb, HOLDING_IANN) == 1)) {
		Produce::annotate_symbol_i(symb, DELENDA_EST_IANN, 1);
		inter_tree_node *D = Inter::Symbols::definition(symb);
		Inter::Tree::remove_node(D);
		Inter::Symbols::undefine(symb);
		return symb;
	}
	return Inter::SymbolsTables::create_with_unique_name(T, name);
}

inter_symbol *Produce::define_symbol(inter_name *iname) {
	InterNames::to_symbol(iname);
	if (iname->symbol) {
		if (Inter::Symbols::is_predeclared(iname->symbol)) {
			Inter::Symbols::undefine(iname->symbol);
		}
	}
	if ((iname->symbol) && (Inter::Symbols::read_annotation(iname->symbol, HOLDING_IANN) == 1)) {
		if (Inter::Symbols::read_annotation(iname->symbol, DELENDA_EST_IANN) != 1) {
			Produce::annotate_symbol_i(iname->symbol, DELENDA_EST_IANN, 1);
			Inter::Symbols::strike_definition(iname->symbol);
		}
		return iname->symbol;
	}
	return iname->symbol;
}

inter_tree *Produce::tree(void) {
	return Inter::Bookmarks::tree(Packaging::at());
}

inter_symbol *Produce::opcode(inter_t bip) {
	return Primitives::get(Produce::tree(), bip);
}

inter_t Produce::baseline(inter_bookmark *IBM) {
	if (IBM == NULL) return 0;
	if (Inter::Bookmarks::package(IBM) == NULL) return 0;
	if (Inter::Packages::is_rootlike(Inter::Bookmarks::package(IBM))) return 0;
	if (Inter::Packages::is_codelike(Inter::Bookmarks::package(IBM)))
		return (inter_t) Inter::Packages::baseline(Inter::Packages::parent(Inter::Bookmarks::package(IBM))) + 1;
	return (inter_t) Inter::Packages::baseline(Inter::Bookmarks::package(IBM)) + 1;
}

inter_bookmark Produce::bookmark(void) {
	inter_bookmark b = Inter::Bookmarks::snapshot(Packaging::at());
	return b;
}

inter_bookmark Produce::bookmark_at(inter_bookmark *IBM) {
	inter_bookmark b = Inter::Bookmarks::snapshot(IBM);
	return b;
}

void Produce::nop(void) {
	Produce::guard(Inter::Nop::new(Packaging::at(), Produce::baseline(Packaging::at()), NULL));
}

void Produce::nop_at(inter_bookmark *IBM) {
	Produce::guard(Inter::Nop::new(IBM, Produce::baseline(IBM) + 2, NULL));
}

void Produce::version(int N) {
	Produce::guard(Inter::Version::new(Packaging::at(), N, Produce::baseline(Packaging::at()), NULL));
}

void Produce::metadata(package_request *P, text_stream *key, text_stream *value) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID), value);
	inter_name *iname = InterNames::explicitly_named(key, P);
	inter_symbol *key_name = Produce::define_symbol(iname);
	packaging_state save = Packaging::enter_home_of(iname);
	Produce::guard(Inter::Metadata::new(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), key_name), ID, Produce::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

inter_symbol *Produce::packagetype(text_stream *name, int enclosing) {
	inter_symbol *pt = Produce::new_symbol(Inter::Tree::global_scope(Produce::tree()), name);
	Produce::guard(Inter::PackageType::new_packagetype(Packaging::package_types(), pt, Produce::baseline(Packaging::package_types()), NULL));
	if (enclosing) Produce::annotate_symbol_i(pt, ENCLOSING_IANN, 1);
	return pt;
}

void Produce::comment(text_stream *text) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID), text);
	Produce::guard(Inter::Comment::new(Packaging::at(), Produce::baseline(Packaging::at()), NULL, ID));
}

inter_package *Produce::package(inter_name *iname, inter_symbol *ptype) {
	if (ptype == NULL) internal_error("no package type");
	inter_t B = Produce::baseline(Packaging::at());
	inter_package *IP = NULL;
	TEMPORARY_TEXT(hmm);
	WRITE_TO(hmm, "%n", iname);
	Produce::guard(Inter::Package::new_package_named(Packaging::at(), hmm, TRUE, ptype, B, NULL, &IP));
	DISCARD_TEXT(hmm);
	if (IP) Inter::Bookmarks::set_current_package(Packaging::at(), IP);
	return IP;
}

void Produce::annotate_symbol_t(inter_symbol *symb, inter_t annot_ID, text_stream *S) {
	Inter::Symbols::annotate_t(Inter::Packages::tree(symb->owning_table->owning_package), symb->owning_table->owning_package, symb, annot_ID, S);
}

void Produce::annotate_symbol_w(inter_symbol *symb, inter_t annot_ID, wording W) {
	TEMPORARY_TEXT(temp);
	WRITE_TO(temp, "%W", W);
	Inter::Symbols::annotate_t(Inter::Packages::tree(symb->owning_table->owning_package), symb->owning_table->owning_package, symb, annot_ID, temp);
	DISCARD_TEXT(temp);
}

void Produce::annotate_symbol_i(inter_symbol *symb, inter_t annot_ID, inter_t V) {
	Inter::Symbols::annotate_i(symb, annot_ID, V);
}

void Produce::annotate_iname_i(inter_name *N, inter_t annot_ID, inter_t V) {
	Inter::Symbols::annotate_i(InterNames::to_symbol(N), annot_ID, V);
}

void Produce::set_flag(inter_name *iname, int f) {
	Inter::Symbols::set_flag(InterNames::to_symbol(iname), f);
}

void Produce::clear_flag(inter_name *iname, int f) {
	Inter::Symbols::clear_flag(InterNames::to_symbol(iname), f);
}

void Produce::annotate_i(inter_name *iname, inter_t annot_ID, inter_t V) {
	if (iname) Produce::annotate_symbol_i(InterNames::to_symbol(iname), annot_ID, V);
}

void Produce::annotate_w(inter_name *iname, inter_t annot_ID, wording W) {
	if (iname) Produce::annotate_symbol_w(InterNames::to_symbol(iname), annot_ID, W);
}

int Produce::read_annotation(inter_name *iname, inter_t annot) {
	return Inter::Symbols::read_annotation(InterNames::to_symbol(iname), annot);
}


void Produce::change_translation(inter_name *iname, text_stream *new_text) {
	Inter::Symbols::set_translate(InterNames::to_symbol(iname), new_text);
}

text_stream *Produce::get_translation(inter_name *iname) {
	return Inter::Symbols::get_translate(InterNames::to_symbol(iname));
}

