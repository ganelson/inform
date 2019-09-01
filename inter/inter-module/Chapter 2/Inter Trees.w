[Inter::Tree::] Inter Trees.

To manage tree structures of inter code, and manage the movement of nodes
within these trees.

@

=
typedef struct inter_tree {
	struct inter_warehouse *housed;
	struct inter_tree_node *root_node;
	struct inter_package *root_package;
	struct building_site site;
	MEMORY_MANAGEMENT
} inter_tree;

@ =
inter_tree *Inter::Tree::new(void) {
	inter_tree *I = CREATE(inter_tree);
	I->housed = Inter::Warehouse::new();
	inter_t N = Inter::Warehouse::create_symbols_table(I->housed);
	inter_symbols_table *globals = Inter::Warehouse::get_symbols_table(I->housed, N);
	inter_t root_package_ID = Inter::Warehouse::create_package(I->housed, I);
	I->root_package = Inter::Warehouse::get_package(I->housed, root_package_ID);
	I->root_node = Inter::Node::root_frame(I->housed, I);
	I->root_package->package_head = I->root_node;
	Inter::Packages::make_rootlike(I->root_package);
	Inter::Packages::set_scope(I->root_package, globals);
	I->root_node->package = I->root_package;
	Inter::Warehouse::attribute_resource(I->housed, N, I->root_package);
	Site::clear(I);
	return I;
}

inter_package *Inter::Tree::root_package(inter_tree *I) {
	if (I) return I->root_package;
	return NULL;
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

inter_tree_node *Inter::Tree::next(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->next_itn;
}

inter_tree_node *Inter::Tree::first_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->first_child_itn;
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

inter_tree_node *Inter::Tree::parent(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->parent_itn;
}

@

=
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
			Inter::Tree::set_first_child_UNSAFE(OP, Inter::Tree::next(C));
		if (Inter::Tree::last_child(OP) == C)
			Inter::Tree::set_last_child_UNSAFE(OP, Inter::Tree::previous(C));
	}
	inter_tree_node *OB = Inter::Tree::previous(C);
	inter_tree_node *OD = Inter::Tree::next(C);
	if (OB) {
		Inter::Tree::set_next_UNSAFE(OB, OD);
	}
	if (OD) {
		Inter::Tree::set_previous_UNSAFE(OD, OB);
	}
	Inter::Tree::set_parent_UNSAFE(C, NULL);
	Inter::Tree::set_previous_UNSAFE(C, NULL);
	Inter::Tree::set_next_UNSAFE(C, NULL);

@<Make C the first child of R@> =
	Inter::Tree::set_parent_UNSAFE(C, R);
	inter_tree_node *D = Inter::Tree::first_child(R);
	if (D == NULL) {
		Inter::Tree::set_last_child_UNSAFE(R, C);
		Inter::Tree::set_next_UNSAFE(C, NULL);
	} else {
		Inter::Tree::set_previous_UNSAFE(D, C);
		Inter::Tree::set_next_UNSAFE(C, D);
	}
	Inter::Tree::set_first_child_UNSAFE(R, C);

@<Make C the last child of R@> =
	Inter::Tree::set_parent_UNSAFE(C, R);
	inter_tree_node *B = Inter::Tree::last_child(R);
	if (B == NULL) {
		Inter::Tree::set_first_child_UNSAFE(R, C);
		Inter::Tree::set_previous_UNSAFE(C, NULL);
	} else {
		Inter::Tree::set_next_UNSAFE(B, C);
		Inter::Tree::set_previous_UNSAFE(C, B);
	}
	Inter::Tree::set_last_child_UNSAFE(R, C);

@<Insert C after R@> =
	inter_tree_node *P = Inter::Tree::parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	Inter::Tree::set_parent_UNSAFE(C, P);
	if (Inter::Tree::last_child(P) == R)
		Inter::Tree::set_last_child_UNSAFE(P, C);
	else {
		inter_tree_node *D = Inter::Tree::next(R);
		if (D == NULL) internal_error("inter tree broken");
		Inter::Tree::set_next_UNSAFE(C, D);
		Inter::Tree::set_previous_UNSAFE(D, C);
	}
	Inter::Tree::set_next_UNSAFE(R, C);
	Inter::Tree::set_previous_UNSAFE(C, R);

@<Insert C before R@> =
	inter_tree_node *P = Inter::Tree::parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	Inter::Tree::set_parent_UNSAFE(C, P);
	if (Inter::Tree::first_child(P) == R)
		Inter::Tree::set_first_child_UNSAFE(P, C);
	else {
		inter_tree_node *B = Inter::Tree::previous(R);
		if (B == NULL) internal_error("inter tree broken");
		Inter::Tree::set_previous_UNSAFE(C, B);
		Inter::Tree::set_next_UNSAFE(B, C);
	}
	Inter::Tree::set_next_UNSAFE(C, R);
	Inter::Tree::set_previous_UNSAFE(R, C);

@

=
void Inter::Tree::set_previous_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->previous_itn = V;
}

void Inter::Tree::set_next_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->next_itn = V;
}

void Inter::Tree::set_first_child_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->first_child_itn = V;
}

void Inter::Tree::set_last_child_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->last_child_itn = V;
}

void Inter::Tree::set_parent_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->parent_itn = V;
}

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
	if (mp == NULL) mp = Site::main_package_if_it_exists(from);
	if (mp) {
		inter_tree_node *D = Inter::Packages::definition(mp);
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
