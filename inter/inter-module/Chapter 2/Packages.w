[Inter::Packages::] Packages.

To manage packages of inter code.

@h Symbols tables.

=
typedef struct inter_package {
	struct inter_repository *stored_in;
	inter_t index_n;
	struct inter_symbol *package_name;
	struct inter_package *parent_package;
	struct inter_package *child_package;
	struct inter_package *next_package;
	struct inter_symbols_table *package_scope;
	int codelike_package;
	inter_t I7_baseline;
	MEMORY_MANAGEMENT
} inter_package;

@ =
inter_package *Inter::Packages::new(inter_package *par, inter_repository *I, inter_t n) {
	inter_package *pack = CREATE(inter_package);
	pack->stored_in = I;
	pack->package_scope = NULL;
	pack->package_name = NULL;
	pack->parent_package = par;
	if (par) {
		if (par->child_package == NULL) par->child_package = pack;
		else {
			inter_package *sib = par->child_package;
			while ((sib) && (sib->next_package)) sib = sib->next_package;
			sib->next_package = pack;
		}
	}
	pack->index_n = n;
	pack->codelike_package = FALSE;
	pack->I7_baseline = 0;
	return pack;
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
	if ((N) && (Str::eq(N->symbol_name, I"main"))) {
		P->stored_in->main_package = P;
	}
}

void Inter::Packages::log(OUTPUT_STREAM, void *vp) {
	inter_package *pack = (inter_package *) vp;
	if (pack == NULL) WRITE("<null-package>");
	else {
		WRITE("%S", pack->package_name->symbol_name);
	}
}

inter_package *Inter::Packages::main(inter_repository *I) {
	if (I) return I->main_package;
	return NULL;
}

inter_package *Inter::Packages::basics(inter_repository *I) {
	inter_symbol *S = Inter::Packages::search_main_exhaustively(I, I"basics");
	if (S) return Inter::Package::which(S);
	return NULL;
}

inter_symbol *Inter::Packages::search_exhaustively(inter_package *P, text_stream *S) {
	inter_symbol *found = Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope(P), S);
	if (found) return found;
	for (P = P->child_package; P; P = P->next_package) {
		found = Inter::Packages::search_exhaustively(P, S);
		if (found) return found;
	}
	return NULL;
}

inter_symbol *Inter::Packages::search_main_exhaustively(inter_repository *I, text_stream *S) {
	return Inter::Packages::search_exhaustively(Inter::Packages::main(I), S);
}

inter_t Inter::Packages::to_PID(inter_package *P) {
	if (P == NULL) return 0;
	return P->index_n;
}

inter_package *Inter::Packages::from_PID(inter_repository *I, inter_t PID) {
	if (PID == 0) return NULL;
	return Inter::get_package(I, PID);
}

inter_package *Inter::Packages::container(inter_frame P) {
	if (P.repo_segment == NULL) return NULL;
	return Inter::Packages::from_PID(P.repo_segment->owning_repo, Inter::Frame::get_package(P));
}

inter_symbols_table *Inter::Packages::scope(inter_package *pack) {
	if (pack == NULL) return NULL;
	return pack->package_scope;
}

inter_symbols_table *Inter::Packages::scope_of(inter_frame P) {
	inter_package *pack = Inter::Packages::container(P);
	if (pack) return pack->package_scope;
	return Inter::Frame::global_symbols(P);
}

inter_symbol *Inter::Packages::type(inter_package *P) {
	if (P == NULL) return NULL;
	if (P->package_name == NULL) return NULL;
	return Inter::Package::type(P->package_name);
}

int Inter::Packages::baseline(inter_package *P) {
	if (P == NULL) return 0;
	if (P->package_name == NULL) return 0;
	return Inter::Defn::get_level(Inter::Symbols::defining_frame(P->package_name));
}
