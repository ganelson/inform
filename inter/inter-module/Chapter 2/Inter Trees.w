[Inter::Tree::] Inter Trees.

To manage tree structures of inter code, and manage the movement of nodes
within these trees.

@

=
typedef struct inter_tree {
	struct inter_warehouse *housed;
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
inter_tree_node *Inter::Tree::new_node(inter_tree *I, warehouse_floor_space W) {
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

inter_tree *Inter::Tree::new(void) {
	inter_tree *I = CREATE(inter_tree);
	I->main_package = NULL;
	I->housed = Inter::Warehouse::new();
	inter_t N = Inter::Warehouse::create_symbols_table(I->housed);
	inter_symbols_table *globals = Inter::Warehouse::get_symbols_table(I->housed, N);
	inter_t root_package_ID = Inter::Warehouse::create_package(I->housed, I);
	I->root_package = Inter::Warehouse::get_package(I->housed, root_package_ID);
	I->root_node = Inter::Node::root_frame(I->housed, I);
	Inter::Packages::make_rootlike(I->root_package);
	Inter::Packages::set_scope(I->root_package, globals);
	I->root_node->package = I->root_package;
	Inter::Warehouse::attribute_resource(I->housed, N, I->root_package);
	return I;
}

inter_package *Inter::Tree::root_package(inter_tree *I) {
	if (I) return I->root_package;
	return NULL;
}

inter_package *Inter::Tree::main_package(inter_tree *I) {
	if (I) return I->main_package;
	return NULL;
}

void Inter::Tree::set_main_package(inter_tree *I, inter_package *M) {
	if (I == NULL) internal_error("no tree"); 
	I->main_package = M;
}

inter_warehouse *Inter::Tree::warehouse(inter_tree *I) {
	return I->housed;
}

inter_symbols_table *Inter::Tree::global_scope(inter_tree *I) {
	return Inter::Packages::scope(I->root_package);
}

inter_tree_node *Inter::Tree::previous(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->previous_itn;
}

void Inter::Tree::set_previous(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->previous_itn = V;
}

inter_tree_node *Inter::Tree::next(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->next_itn;
}

void Inter::Tree::set_next(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->next_itn = V;
}

inter_tree_node *Inter::Tree::first_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->first_child_itn;
}

void Inter::Tree::set_first_child(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->first_child_itn = V;
}

inter_tree_node *Inter::Tree::second_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *Inter::Tree::third_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *Inter::Tree::fourth_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *Inter::Tree::fifth_child(inter_tree_node *P) {
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

inter_tree_node *Inter::Tree::sixth_child(inter_tree_node *P) {
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

inter_tree_node *Inter::Tree::last_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->last_child_itn;
}

void Inter::Tree::set_last_child(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->last_child_itn = V;
}

inter_tree_node *Inter::Tree::parent(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->parent_itn;
}

void Inter::Tree::set_parent(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->parent_itn = V;
}

@

=
int trace_inter_insertion = FALSE;

void Inter::Tree::insert_node(inter_tree_node *F, inter_bookmark *at) {
	if (F == NULL) internal_error("no frame to insert");
	if (at == NULL) internal_error("nowhere to insert");
	inter_package *pack = Inter::Bookmarks::package(at);
	inter_tree *I = pack->stored_in;
	LOGIF(INTER_FRAMES, "Insert frame %F\n", *F);
	if (trace_inter_insertion) Inter::Defn::write_construct_text(DL, F);
	inter_t F_level = F->W.data[LEVEL_IFLD];
	if (F_level == 0) {
		Inter::Tree::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, I->root_node);
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
				inter_tree_node *PR = Inter::Tree::parent(R);
				if (PR == NULL) internal_error("bubbled up out of tree");
				Inter::Bookmarks::set_ref(at, PR);
			}
			if (F_level > Inter::Bookmarks::get_ref(at)->W.data[LEVEL_IFLD] + 1) internal_error("bubbled down off of tree");
			if (F_level == Inter::Bookmarks::get_ref(at)->W.data[LEVEL_IFLD] + 1) {
				if (Inter::Bookmarks::get_placement(at) == IMMEDIATELY_AFTER_ICPLACEMENT) {
					Inter::Tree::place(F, AS_FIRST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
					Inter::Bookmarks::set_placement(at, AFTER_ICPLACEMENT);
				} else {
					Inter::Tree::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
				}
			} else {
				Inter::Tree::place(F, AFTER_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
			}
			Inter::Bookmarks::set_ref(at, F);
			return;
		}
		Inter::Tree::place(F, Inter::Bookmarks::get_placement(at), Inter::Bookmarks::get_ref(at));
		if (Inter::Bookmarks::get_placement(at) == AS_FIRST_CHILD_OF_ICPLACEMENT) {
			Inter::Bookmarks::set_ref(at, F);
			Inter::Bookmarks::set_placement(at, AFTER_ICPLACEMENT);
		}
	}
}

void Inter::Tree::remove_node(inter_tree_node *P) {
	Inter::Tree::place(P, NOWHERE_ICPLACEMENT, NULL);
}

void Inter::Tree::place(inter_tree_node *C, int how, inter_tree_node *R) {
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
	inter_tree_node *OP = Inter::Tree::parent(C);
	if (OP) {
		if (Inter::Tree::first_child(OP) == C)
			Inter::Tree::set_first_child(OP, Inter::Tree::next(C));
		if (Inter::Tree::last_child(OP) == C)
			Inter::Tree::set_last_child(OP, Inter::Tree::previous(C));
	}
	inter_tree_node *OB = Inter::Tree::previous(C);
	inter_tree_node *OD = Inter::Tree::next(C);
	if (OB) {
		Inter::Tree::set_next(OB, OD);
	}
	if (OD) {
		Inter::Tree::set_previous(OD, OB);
	}
	Inter::Tree::set_parent(C, NULL);
	Inter::Tree::set_previous(C, NULL);
	Inter::Tree::set_next(C, NULL);

@<Make C the first child of R@> =
	Inter::Tree::set_parent(C, R);
	inter_tree_node *D = Inter::Tree::first_child(R);
	if (D == NULL) {
		Inter::Tree::set_last_child(R, C);
		Inter::Tree::set_next(C, NULL);
	} else {
		Inter::Tree::set_previous(D, C);
		Inter::Tree::set_next(C, D);
	}
	Inter::Tree::set_first_child(R, C);

@<Make C the last child of R@> =
	Inter::Tree::set_parent(C, R);
	inter_tree_node *B = Inter::Tree::last_child(R);
	if (B == NULL) {
		Inter::Tree::set_first_child(R, C);
		Inter::Tree::set_previous(C, NULL);
	} else {
		Inter::Tree::set_next(B, C);
		Inter::Tree::set_previous(C, B);
	}
	Inter::Tree::set_last_child(R, C);

@<Insert C after R@> =
	inter_tree_node *P = Inter::Tree::parent(R);
	if (P == NULL) internal_error("can't move C after R when R is nowhere");
	Inter::Tree::set_parent(C, P);
	if (Inter::Tree::last_child(P) == R)
		Inter::Tree::set_last_child(P, C);
	else {
		inter_tree_node *D = Inter::Tree::next(R);
		if (D == NULL) internal_error("inter tree broken");
		Inter::Tree::set_next(C, D);
		Inter::Tree::set_previous(D, C);
	}
	Inter::Tree::set_next(R, C);
	Inter::Tree::set_previous(C, R);

@<Insert C before R@> =
	inter_tree_node *P = Inter::Tree::parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	Inter::Tree::set_parent(C, P);
	if (Inter::Tree::first_child(P) == R)
		Inter::Tree::set_first_child(P, C);
	else {
		inter_tree_node *B = Inter::Tree::previous(R);
		if (B == NULL) internal_error("inter tree broken");
		Inter::Tree::set_previous(C, B);
		Inter::Tree::set_next(B, C);
	}
	Inter::Tree::set_next(C, R);
	Inter::Tree::set_previous(R, C);

@

@d LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = Inter::Tree::first_child(P); F; F = Inter::Tree::next(F))

@d PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = Inter::Tree::first_child(P), *FN = F?(Inter::Tree::next(F)):NULL;
		F; F = FN, FN = FN?(Inter::Tree::next(FN)):NULL)

=
void Inter::Tree::traverse_root_only(inter_tree *from, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(P, from->root_node) {
		if ((filter == 0) ||
			((filter > 0) && (P->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (P->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, P, state);
	}
}

void Inter::Tree::traverse(inter_tree *from, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, inter_package *mp, int filter) {
	if (mp == NULL) mp = Inter::Tree::main_package(from);
	if (mp) {
		inter_tree_node *D = Inter::Symbols::definition(mp->package_name);
		if ((filter == 0) ||
			((filter > 0) && (D->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (D->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, D, state);
		Inter::Tree::traverse_r(from, D, visitor, state, filter);
	}
}
void Inter::Tree::traverse_r(inter_tree *from, inter_tree_node *P, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (C->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (C->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, C, state);
		Inter::Tree::traverse_r(from, C, visitor, state, filter);
	}
}
