[Inter::] Inter in Memory.

To store bytecode-like intermediate code in memory.

@

=
typedef struct inter_tree {
	struct inter_tree_node *root_node;
	struct inter_package *root_package;
	struct inter_package *main_package;
	MEMORY_MANAGEMENT
} inter_tree;

typedef struct inter_tree_node {
	struct inter_tree *tree;
	struct inter_package *package;
	struct inter_tree_node *parent_itn;
	struct inter_tree_node *first_child_itn;
	struct inter_tree_node *last_child_itn;
	struct inter_tree_node *previous_itn;
	struct inter_tree_node *next_itn;
	struct warehouse_floor_space W;
} inter_tree_node;

@ =
inter_tree_node *Inter::new_itn(inter_tree *I, warehouse_floor_space W) {
	inter_tree_node *itn = CREATE(inter_tree_node);
	itn->tree = I;
	itn->package = NULL;
	itn->parent_itn = NULL;
	itn->first_child_itn = NULL;
	itn->last_child_itn = NULL;
	itn->previous_itn = NULL;
	itn->next_itn = NULL;
	itn->W = W;
	return itn;
}

inter_tree *Inter::create(void) {
	inter_tree *I = CREATE(inter_tree);
	I->main_package = NULL;

	inter_warehouse *warehouse = Inter::Warehouse::new();
	inter_t N = Inter::Warehouse::create_symbols_table(warehouse);
	inter_symbols_table *globals = Inter::Warehouse::get_symbols_table(warehouse, N);
	I->root_package = Inter::Warehouse::get_package(warehouse, Inter::Warehouse::create_package(warehouse, I));
	I->root_node = Inter::Frame::root_frame(warehouse, I);
	Inter::Packages::make_rootlike(I->root_package);
	Inter::Packages::set_scope(I->root_package, globals);
	Inter::Warehouse::attribute_resource(warehouse, N, I->root_package);
	return I;
}

inter_warehouse *Inter::warehouse(inter_tree *I) {
	return Inter::Frame::warehouse(I->root_node);
}

inter_symbols_table *Inter::get_global_symbols(inter_tree *I) {
	return Inter::Packages::scope(I->root_package);
}

inter_tree_node *Inter::get_previous(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->previous_itn;
}

void Inter::set_previous(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->previous_itn = V;
}

inter_tree_node *Inter::get_next(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->next_itn;
}

void Inter::set_next(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->next_itn = V;
}

inter_tree_node *Inter::get_first_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->first_child_itn;
}

void Inter::set_first_child(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->first_child_itn = V;
}

inter_tree_node *Inter::get_last_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->last_child_itn;
}

void Inter::set_last_child(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->last_child_itn = V;
}

inter_tree_node *Inter::get_parent(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->parent_itn;
}

void Inter::set_parent(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->parent_itn = V;
}

inter_tree_node *Inter::first_child_P(inter_tree_node *P) {
	if (P == NULL) return NULL;
	return P->first_child_itn;
}

inter_tree_node *Inter::second_child_P(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *Inter::third_child_P(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *Inter::fourth_child_P(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *Inter::fifth_child_P(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *Inter::sixth_child_P(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

@

@e BEFORE_ICPLACEMENT from 0
@e AFTER_ICPLACEMENT
@e IMMEDIATELY_AFTER_ICPLACEMENT
@e AS_FIRST_CHILD_OF_ICPLACEMENT
@e AS_LAST_CHILD_OF_ICPLACEMENT
@e NOWHERE_ICPLACEMENT

=
int trace_inter_insertion = FALSE;

void Inter::insert(inter_tree_node *F, inter_bookmark *at) {
	if (F == NULL) internal_error("no frame to insert");
	if (at == NULL) internal_error("nowhere to insert");
	inter_package *pack = Inter::Bookmarks::package(at);
	inter_tree *I = pack->stored_in;
	LOGIF(INTER_FRAMES, "Insert frame %F\n", *F);
	if (trace_inter_insertion) Inter::Defn::write_construct_text(DL, F);
	inter_t F_level = F->W.data[LEVEL_IFLD];
	if (F_level == 0) {
		Inter::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, I->root_node);
		if ((Inter::Bookmarks::get_placement(at) == AFTER_ICPLACEMENT) ||
			(Inter::Bookmarks::get_placement(at) == IMMEDIATELY_AFTER_ICPLACEMENT)) {
			Inter::Bookmarks::set_ref(at, F);
		}
	} else {
		if (Inter::Bookmarks::get_placement(at) == NOWHERE_ICPLACEMENT) internal_error("bad wrt");
		if ((Inter::Bookmarks::get_placement(at) == AFTER_ICPLACEMENT) ||
			(Inter::Bookmarks::get_placement(at) == IMMEDIATELY_AFTER_ICPLACEMENT)) {
			while (F_level < Inter::Bookmarks::get_ref(at)->W.data[LEVEL_IFLD]) {
				inter_tree_node *R = Inter::Bookmarks::get_ref(at);
				inter_tree_node *PR = Inter::get_parent(R);
				if (PR == NULL) internal_error("bubbled up out of tree");
				Inter::Bookmarks::set_ref(at, PR);
			}
			if (F_level > Inter::Bookmarks::get_ref(at)->W.data[LEVEL_IFLD] + 1) internal_error("bubbled down off of tree");
			if (F_level == Inter::Bookmarks::get_ref(at)->W.data[LEVEL_IFLD] + 1) {
				if (Inter::Bookmarks::get_placement(at) == IMMEDIATELY_AFTER_ICPLACEMENT) {
					Inter::place(F, AS_FIRST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
					Inter::Bookmarks::set_placement(at, AFTER_ICPLACEMENT);
				} else {
					Inter::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
				}
			} else {
				Inter::place(F, AFTER_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
			}
			Inter::Bookmarks::set_ref(at, F);
			return;
		}
		Inter::place(F, Inter::Bookmarks::get_placement(at), Inter::Bookmarks::get_ref(at));
	}
}

void Inter::remove_from_tree(inter_tree_node *P) {
	Inter::place(P, NOWHERE_ICPLACEMENT, NULL);
}

void Inter::place(inter_tree_node *C, int how, inter_tree_node *R) {
	@<Extricate C from its current tree position@>;
	switch (how) {
		case NOWHERE_ICPLACEMENT:
			return;
		case AS_FIRST_CHILD_OF_ICPLACEMENT:
			@<Make C the first child of R@>;
			break;
		case AS_LAST_CHILD_OF_ICPLACEMENT:
			@<Make C the last child of R@>;
			break;
		case AFTER_ICPLACEMENT:
		case IMMEDIATELY_AFTER_ICPLACEMENT:
			@<Insert C after R@>;
			break;
		case BEFORE_ICPLACEMENT:
			@<Insert C before R@>;
			break;
		default:
			internal_error("unimplemented");
	}
}

@<Extricate C from its current tree position@> =
	inter_tree_node *OP = Inter::get_parent(C);
	if (OP) {
		if (Inter::get_first_child(OP) == C)
			Inter::set_first_child(OP, Inter::get_next(C));
		if (Inter::get_last_child(OP) == C)
			Inter::set_last_child(OP, Inter::get_previous(C));
	}
	inter_tree_node *OB = Inter::get_previous(C);
	inter_tree_node *OD = Inter::get_next(C);
	if (OB) {
		Inter::set_next(OB, OD);
	}
	if (OD) {
		Inter::set_previous(OD, OB);
	}
	Inter::set_parent(C, NULL);
	Inter::set_previous(C, NULL);
	Inter::set_next(C, NULL);

@<Make C the first child of R@> =
	Inter::set_parent(C, R);
	inter_tree_node *D = Inter::get_first_child(R);
	if (D == NULL) {
		Inter::set_last_child(R, C);
		Inter::set_next(C, NULL);
	} else {
		Inter::set_previous(D, C);
		Inter::set_next(C, D);
	}
	Inter::set_first_child(R, C);

@<Make C the last child of R@> =
	Inter::set_parent(C, R);
	inter_tree_node *B = Inter::get_last_child(R);
	if (B == NULL) {
		Inter::set_first_child(R, C);
		Inter::set_previous(C, NULL);
	} else {
		Inter::set_next(B, C);
		Inter::set_previous(C, B);
	}
	Inter::set_last_child(R, C);

@<Insert C after R@> =
	inter_tree_node *P = Inter::get_parent(R);
	if (P == NULL) internal_error("can't move C after R when R is nowhere");
	Inter::set_parent(C, P);
	if (Inter::get_last_child(P) == R)
		Inter::set_last_child(P, C);
	else {
		inter_tree_node *D = Inter::get_next(R);
		if (D == NULL) internal_error("inter tree broken");
		Inter::set_next(C, D);
		Inter::set_previous(D, C);
	}
	Inter::set_next(R, C);
	Inter::set_previous(C, R);

@<Insert C before R@> =
	inter_tree_node *P = Inter::get_parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	Inter::set_parent(C, P);
	if (Inter::get_first_child(P) == R)
		Inter::set_first_child(P, C);
	else {
		inter_tree_node *B = Inter::get_previous(R);
		if (B == NULL) internal_error("inter tree broken");
		Inter::set_previous(C, B);
		Inter::set_next(B, C);
	}
	Inter::set_next(C, R);
	Inter::set_previous(R, C);

@

=
void Inter::backtrace(OUTPUT_STREAM, inter_tree_node *F) {
	inter_tree_node *X = F;
	int n = 0;
	while (TRUE) {
		X = Inter::get_parent(X);
		if (X == NULL) break;
		n++;
	}
	for (int i = n; i >= 0; i--) {
		inter_tree_node *X = F;
		int m = 0;
		while (TRUE) {
			inter_tree_node *Y = Inter::get_parent(X);
			if (Y == NULL) break;
			if (m == i) {
				WRITE("%2d. ", (n-i));
				if (i == 0) WRITE("** "); else WRITE("   ");
				Inter::Defn::write_construct_text_allowing_nop(OUT, X);
				break;
			}
			X = Y;
			m++;
		}
	}
	LOOP_THROUGH_INTER_CHILDREN(C, F) {
		WRITE("%2d.    ", (n+1));
		Inter::Defn::write_construct_text_allowing_nop(OUT, C);
	}
}		

@

@d LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = Inter::get_first_child(P); F; F = Inter::get_next(F))

@d PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = Inter::get_first_child(P), *FN = F?(Inter::get_next(F)):NULL;
		F; F = FN, FN = FN?(Inter::get_next(FN)):NULL)

=
void Inter::traverse_global_list(inter_tree *from, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(P, from->root_node) {
		if ((filter == 0) ||
			((filter > 0) && (P->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (P->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, P, state);
	}
}

void Inter::traverse_tree(inter_tree *from, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, inter_package *mp, int filter) {
	if (mp == NULL) mp = Inter::Packages::main(from);
	if (mp) {
		inter_tree_node *D = Inter::Symbols::definition(mp->package_name);
		if ((filter == 0) ||
			((filter > 0) && (D->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (D->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, D, state);
		Inter::traverse_tree_r(from, D, visitor, state, filter);
	}
}
void Inter::traverse_tree_r(inter_tree *from, inter_tree_node *P, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (C->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (C->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, C, state);
		Inter::traverse_tree_r(from, C, visitor, state, filter);
	}
}
