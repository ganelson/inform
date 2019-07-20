[Inter::Packages::] Packages.

To manage packages of inter code.

@h Symbols tables.

=
typedef struct inter_package {
	struct inter_repository *stored_in;
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

@ =
inter_package *Inter::Packages::new(inter_repository *I, inter_t n) {
	inter_package *pack = CREATE(inter_package);
	pack->stored_in = I;
	pack->package_scope = NULL;
	pack->package_name = NULL;
	pack->package_flags = 0;
	pack->index_n = n;
	return pack;
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

inter_package *Inter::Packages::parent(inter_package *pack) {
	if (pack) {
		inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
		inter_t P_index = Inter::Frame::get_parent_index(D);
		if (P_index == 0) return NULL;
		inter_frame P = Inter::Frame::from_index(pack->stored_in, P_index);
		return Inter::Package::defined_by_frame(P);
	}
	return NULL;
}

void Inter::Packages::unmark_all(void) {
	inter_package *pack;
	LOOP_OVER(pack, inter_package)
		CodeGen::unmark(pack->package_name);
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

inter_package *Inter::Packages::veneer(inter_repository *I) {
	inter_symbol *S = Inter::Packages::search_main_exhaustively(I, I"veneer");
	if (S) return Inter::Package::which(S);
	return NULL;
}

inter_package *Inter::Packages::template(inter_repository *I) {
	inter_symbol *S = Inter::Packages::search_main_exhaustively(I, I"template");
	if (S) return Inter::Package::which(S);
	return NULL;
}

inter_symbol *Inter::Packages::search_exhaustively(inter_package *P, text_stream *S) {
	inter_symbol *found = Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope(P), S);
	if (found) return found;
	inter_frame D = Inter::Symbols::defining_frame(P->package_name);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *Q = Inter::Package::defined_by_frame(C);
			found = Inter::Packages::search_exhaustively(Q, S);
			if (found) return found;
		}
	}
	return NULL;
}

inter_symbol *Inter::Packages::search_main_exhaustively(inter_repository *I, text_stream *S) {
	return Inter::Packages::search_exhaustively(Inter::Packages::main(I), S);
}

inter_symbol *Inter::Packages::search_resources_exhaustively(inter_repository *I, text_stream *S) {
	inter_package *main_package = Inter::Packages::main(I);
	if (main_package) {
		inter_frame D = Inter::Symbols::defining_frame(main_package->package_name);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C.data[ID_IFLD] == PACKAGE_IST) {
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

text_stream *Inter::Packages::read_metadata(inter_package *P, text_stream *key) {
	if (P == NULL) return NULL;
	inter_symbol *found = Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope(P), key);
	if ((found) && (Inter::Symbols::is_defined(found))) {
		inter_frame F = Inter::Symbols::defining_frame(found);
		inter_t val2 = F.data[VAL1_MD_IFLD + 1];
		return Inter::get_text(P->stored_in, val2);
	}
	return NULL;
}

void Inter::Packages::wrap(inter_package *P) {
}

