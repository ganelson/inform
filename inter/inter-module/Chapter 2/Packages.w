[Inter::Packages::] Packages.

To manage packages of inter code.

@h Symbols tables.

=
typedef struct inter_package {
	struct inter_tree_node *package_head;
	inter_t index_n;
	struct inter_symbol *package_name;
	struct inter_symbols_table *package_scope;
	int package_flags;
	MEMORY_MANAGEMENT
} inter_package;

@

@d CODELIKE_PACKAGE_FLAG 1
@d LINKAGE_PACKAGE_FLAG 2
@d USED_PACKAGE_FLAG 4
@d ROOT_PACKAGE_FLAG 8
@d MARK_PACKAGE_FLAG 16

@ =
inter_tree *default_ptree = NULL;

inter_package *Inter::Packages::new(inter_tree *I, inter_t n) {
	inter_package *pack = CREATE(inter_package);
	pack->package_head = NULL;
	pack->package_scope = NULL;
	pack->package_name = NULL;
	pack->package_flags = 0;
	pack->index_n = n;
	return pack;
}

inter_tree_node *Inter::Packages::definition(inter_package *pack) {
	if (pack == NULL) return NULL;
	if (Inter::Packages::is_rootlike(pack)) return NULL;
	return pack->package_head;
}

inter_tree *Inter::Packages::tree(inter_package *pack) {
	if (default_ptree) return default_ptree;
	return pack->package_head->tree;
}

text_stream *Inter::Packages::name(inter_package *pack) {
	if (pack == NULL) return NULL;
	return pack->package_name->symbol_name;
}

int Inter::Packages::is_codelike(inter_package *pack) {
	if ((pack) && (pack->package_flags & CODELIKE_PACKAGE_FLAG)) return TRUE;
	return FALSE;
}

void Inter::Packages::make_codelike(inter_package *pack) {
	if (pack) {
		pack->package_flags |= CODELIKE_PACKAGE_FLAG;
	}
}

int Inter::Packages::is_linklike(inter_package *pack) {
	if ((pack) && (pack->package_flags & LINKAGE_PACKAGE_FLAG)) return TRUE;
	return FALSE;
}

void Inter::Packages::make_linklike(inter_package *pack) {
	if (pack) {
		pack->package_flags |= LINKAGE_PACKAGE_FLAG;
	}
}

int Inter::Packages::is_rootlike(inter_package *pack) {
	if ((pack) && (pack->package_flags & ROOT_PACKAGE_FLAG)) return TRUE;
	return FALSE;
}

void Inter::Packages::make_rootlike(inter_package *pack) {
	if (pack) {
		pack->package_flags |= ROOT_PACKAGE_FLAG;
	}
}

inter_package *Inter::Packages::parent(inter_package *pack) {
	if (pack) {
		if (Inter::Packages::is_rootlike(pack)) return NULL;
		inter_tree_node *D = Inter::Packages::definition(pack);
		inter_tree_node *P = Inter::Tree::parent(D);
		if (P == NULL) return NULL;
		return Inter::Package::defined_by_frame(P);
	}
	return NULL;
}

void Inter::Packages::unmark_all(void) {
	inter_package *pack;
	LOOP_OVER(pack, inter_package)
		Inter::Packages::clear_flag(pack, MARK_PACKAGE_FLAG);
}

void Inter::Packages::set_scope(inter_package *P, inter_symbols_table *T) {
	if (P == NULL) internal_error("null package");
	P->package_scope = T;
	if (T) T->owning_package = P;
}

void Inter::Packages::set_name(inter_package *P, inter_symbol *N) {
	if (P == NULL) internal_error("null package");
	if (N == NULL) internal_error("null package name");
	P->package_name = N;
	if ((N) && (Str::eq(N->symbol_name, I"main")))
		Inter::Tree::set_main_package(Inter::Packages::tree(P), P);
}

void Inter::Packages::log(OUTPUT_STREAM, void *vp) {
	inter_package *pack = (inter_package *) vp;
	Inter::Packages::write_url_name(OUT, pack);
}

inter_package *Inter::Packages::basics(inter_tree *I) {
	inter_symbol *S = Inter::Packages::search_main_exhaustively(I, I"basics");
	if (S) return Inter::Package::which(S);
	return NULL;
}

inter_package *Inter::Packages::veneer(inter_tree *I) {
	inter_symbol *S = Inter::Packages::search_main_exhaustively(I, I"veneer");
	if (S) return Inter::Package::which(S);
	return NULL;
}

inter_package *Inter::Packages::template(inter_tree *I) {
	inter_symbol *S = Inter::Packages::search_main_exhaustively(I, I"template");
	if (S) return Inter::Package::which(S);
	return NULL;
}

inter_symbol *Inter::Packages::search_exhaustively(inter_package *P, text_stream *S) {
	inter_symbol *found = Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope(P), S);
	if (found) return found;
	inter_tree_node *D = Inter::Packages::definition(P);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *Q = Inter::Package::defined_by_frame(C);
			found = Inter::Packages::search_exhaustively(Q, S);
			if (found) return found;
		}
	}
	return NULL;
}

inter_symbol *Inter::Packages::search_main_exhaustively(inter_tree *I, text_stream *S) {
	return Inter::Packages::search_exhaustively(Inter::Tree::main_package(I), S);
}

inter_symbol *Inter::Packages::search_resources_exhaustively(inter_tree *I, text_stream *S) {
	inter_package *main_package = Inter::Tree::main_package(I);
	if (main_package) {
		inter_tree_node *D = Inter::Packages::definition(main_package);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *Q = Inter::Package::defined_by_frame(C);
				inter_symbol *found = Inter::Packages::search_exhaustively(Q, S);
				if (found) return found;
			}
		}
	}
	return NULL;
}

inter_t Inter::Packages::to_PID(inter_package *P) {
	if (P == NULL) return 0;
	return P->index_n;
}

inter_package *Inter::Packages::container(inter_tree_node *P) {
	if (P == NULL) return NULL;
	inter_package *pack = Inter::Node::get_package(P);
	if (Inter::Packages::is_rootlike(pack)) return NULL;
	return pack;
}

inter_symbols_table *Inter::Packages::scope(inter_package *pack) {
	if (pack == NULL) return NULL;
	return pack->package_scope;
}

inter_symbols_table *Inter::Packages::scope_of(inter_tree_node *P) {
	inter_package *pack = Inter::Packages::container(P);
	if (pack) return pack->package_scope;
	return Inter::Node::globals(P);
}

inter_symbol *Inter::Packages::type(inter_package *P) {
	if (P == NULL) return NULL;
	return Inter::Package::type(P);
}

int Inter::Packages::baseline(inter_package *P) {
	if (P == NULL) return 0;
	if (Inter::Packages::is_rootlike(P)) return 0;
	return Inter::Defn::get_level(Inter::Packages::definition(P));
}

text_stream *Inter::Packages::read_metadata(inter_package *P, text_stream *key) {
	if (P == NULL) return NULL;
	inter_symbol *found = Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope(P), key);
	if ((found) && (Inter::Symbols::is_defined(found))) {
		inter_tree_node *D = Inter::Symbols::definition(found);
		inter_t val2 = D->W.data[VAL1_MD_IFLD + 1];
		return Inter::Warehouse::get_text(Inter::Tree::warehouse(Inter::Packages::tree(P)), val2);
	}
	return NULL;
}

void Inter::Packages::write_url_name(OUTPUT_STREAM, inter_package *P) {
	if (P == NULL) { WRITE("<none>"); return; }
	inter_package *chain[MAX_URL_SYMBOL_NAME_DEPTH];
	int chain_length = 0;
	while (P) {
		if (chain_length >= MAX_URL_SYMBOL_NAME_DEPTH) internal_error("package nesting too deep");
		chain[chain_length++] = P;
		P = Inter::Packages::parent(P);
	}
	for (int i=chain_length-1; i>=0; i--) WRITE("/%S", Inter::Packages::name(chain[i]));
}

int Inter::Packages::get_flag(inter_package *P, int f) {
	if (P == NULL) internal_error("no package");
	return (P->package_flags & f)?TRUE:FALSE;
}

void Inter::Packages::set_flag(inter_package *P, int f) {
	if (P == NULL) internal_error("no package");
	P->package_flags = P->package_flags | f;
}

void Inter::Packages::clear_flag(inter_package *P, int f) {
	if (P == NULL) internal_error("no package");
	if (P->package_flags & f) P->package_flags = P->package_flags - f;
}

inter_package *Inter::Packages::by_name(inter_package *P, text_stream *name) {
	if (P == NULL) return NULL;
	inter_symbols_table *at = Inter::Packages::scope(P);
	inter_symbol *next_sym = Inter::SymbolsTables::symbol_from_name(at, name);
	if (next_sym == NULL) return NULL;
	return Inter::Package::which(next_sym);
}
