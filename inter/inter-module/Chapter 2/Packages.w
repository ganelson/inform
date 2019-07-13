[Inter::Packages::] Packages.

To manage packages of inter code.

@h Symbols tables.

=
typedef struct inter_package {
	struct inter_repository *stored_in;
	inter_t index_n;
	struct inter_symbol *package_name;
	struct inter_package *parent_package;
	struct inter_symbols_table *package_scope;
	int codelike_package;
	inter_t I7_baseline;
	int package_flags;
	MEMORY_MANAGEMENT
} inter_package;

@

@d USED_PACKAGE_FLAG 1

@ =
inter_package *Inter::Packages::new(inter_package *par, inter_repository *I, inter_t n) {
	inter_package *pack = CREATE(inter_package);
	pack->stored_in = I;
	pack->package_scope = NULL;
	pack->package_name = NULL;
	pack->package_flags = 0;
	pack->parent_package = par;
	pack->index_n = n;
	pack->codelike_package = FALSE;
	pack->I7_baseline = 0;
	return pack;
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

void Inter::Packages::traverse_global(code_generation *gen, void (*visitor)(code_generation *, inter_frame, void *), void *state) {
	inter_frame P;
	LOOP_THROUGH_INTER_FRAME_LIST(P, (&(gen->from->global_material))) {
		if (P.data[ID_IFLD] != PACKAGE_IST) {
			(*visitor)(gen, P, state);
		}
	}
}

void Inter::Packages::traverse_global_inc(code_generation *gen, void (*visitor)(code_generation *, inter_frame, void *), void *state) {
	inter_frame P;
	LOOP_THROUGH_INTER_FRAME_LIST(P, (&(gen->from->global_material))) {
		(*visitor)(gen, P, state);
	}
}

void Inter::Packages::traverse_repository_global(inter_repository *from, void (*visitor)(inter_repository *, inter_frame, void *), void *state) {
	inter_frame P;
	LOOP_THROUGH_INTER_FRAME_LIST(P, (&(from->global_material))) {
		if (P.data[ID_IFLD] != PACKAGE_IST) {
			(*visitor)(from, P, state);
		}
	}
}

void Inter::Packages::traverse_repository_global_inc(inter_repository *from, void (*visitor)(inter_repository *, inter_frame, void *), void *state) {
	inter_frame P;
	LOOP_THROUGH_INTER_FRAME_LIST(P, (&(from->global_material))) {
		(*visitor)(from, P, state);
	}
}

void Inter::Packages::traverse(code_generation *gen, void (*visitor)(code_generation *, inter_frame, void *), void *state) {
	inter_frame D = Inter::Symbols::defining_frame(gen->just_this_package->package_name);
	Inter::Packages::traverse_inner(gen, D, visitor, state);
}
void Inter::Packages::traverse_inner(code_generation *gen, inter_frame P, void (*visitor)(code_generation *, inter_frame, void *), void *state) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if (C.data[ID_IFLD] != PACKAGE_IST)
			(*visitor)(gen, C, state);
		Inter::Packages::traverse_inner(gen, C, visitor, state);
	}
}

void Inter::Packages::traverse_repository(inter_repository *from, void (*visitor)(inter_repository *, inter_frame, void *), void *state) {
	inter_package *mp = Inter::Packages::main(from);
	if (mp) {
		inter_frame D = Inter::Symbols::defining_frame(mp->package_name);
		Inter::Packages::traverse_repository_inner(from, D, visitor, state);
	}
}
void Inter::Packages::traverse_repository_inner(inter_repository *from, inter_frame P, void (*visitor)(inter_repository *, inter_frame, void *), void *state) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if (C.data[ID_IFLD] != PACKAGE_IST)
			(*visitor)(from, C, state);
		Inter::Packages::traverse_repository_inner(from, C, visitor, state);
	}
}

void Inter::Packages::traverse_repository_inc(inter_repository *from, void (*visitor)(inter_repository *, inter_frame, void *), void *state) {
	inter_package *mp = Inter::Packages::main(from);
	if (mp) {
		inter_frame D = Inter::Symbols::defining_frame(mp->package_name);
		Inter::Packages::traverse_repository_inc_inner(from, D, visitor, state);
	}
}
void Inter::Packages::traverse_repository_inc_from(inter_repository *from, void (*visitor)(inter_repository *, inter_frame, void *), void *state, inter_package *mp) {
	if (mp) {
		inter_frame D = Inter::Symbols::defining_frame(mp->package_name);
		(*visitor)(from, D, state);
		Inter::Packages::traverse_repository_inc_inner(from, D, visitor, state);
	}
}
void Inter::Packages::traverse_repository_inc_inner(inter_repository *from, inter_frame P, void (*visitor)(inter_repository *, inter_frame, void *), void *state) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		(*visitor)(from, C, state);
		Inter::Packages::traverse_repository_inc_inner(from, C, visitor, state);
	}
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
