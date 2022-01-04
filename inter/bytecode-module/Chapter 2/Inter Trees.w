[InterTree::] Inter Trees.

To manage tree structures of inter code, and manage the movement of nodes
within these trees.

@

@d SYNOPTIC_HIERARCHY_MADE_ITHBIT 1
@d KIT_HIERARCHY_MADE_ITHBIT 2

=
typedef struct inter_tree {
	struct inter_warehouse *housed;
	struct inter_tree_node *root_node;
	struct inter_package *root_package;
	struct building_site site;
	int history_bits;
	CLASS_DEFINITION
} inter_tree;

@ =
inter_tree *InterTree::new(void) {
	inter_tree *I = CREATE(inter_tree);
	I->housed = Inter::Warehouse::new();
	inter_ti N = Inter::Warehouse::create_symbols_table(I->housed);
	inter_symbols_table *globals = Inter::Warehouse::get_symbols_table(I->housed, N);
	inter_ti root_package_ID = Inter::Warehouse::create_package(I->housed, I);
	I->root_package = Inter::Warehouse::get_package(I->housed, root_package_ID);
	I->root_node = Inode::root_frame(I->housed, I);
	I->root_package->package_head = I->root_node;
	Inter::Packages::make_rootlike(I->root_package);
	Inter::Packages::set_scope(I->root_package, globals);
	I->root_node->package = I->root_package;
	Inter::Warehouse::attribute_resource(I->housed, N, I->root_package);
	Site::clear(I);
	I->history_bits = 0;
	return I;
}

inter_package *InterTree::root_package(inter_tree *I) {
	if (I) return I->root_package;
	return NULL;
}

inter_warehouse *InterTree::warehouse(inter_tree *I) {
	return I->housed;
}

inter_symbols_table *InterTree::global_scope(inter_tree *I) {
	return Inter::Packages::scope(I->root_package);
}

inter_tree_node *InterTree::previous(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->previous_itn;
}

inter_tree_node *InterTree::next(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->next_itn;
}

inter_tree_node *InterTree::first_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->first_child_itn;
}

inter_tree_node *InterTree::second_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::third_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::fourth_child(inter_tree_node *P) {
	if (P == NULL) return NULL;
	P = P->first_child_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	P = P->next_itn;
	if (P == NULL) return NULL;
	return P->next_itn;
}

inter_tree_node *InterTree::fifth_child(inter_tree_node *P) {
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

inter_tree_node *InterTree::sixth_child(inter_tree_node *P) {
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

inter_tree_node *InterTree::last_child(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->last_child_itn;
}

inter_tree_node *InterTree::parent(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->parent_itn;
}

@

=
void InterTree::remove_node(inter_tree_node *P) {
	InterTree::place(P, NOWHERE_ICPLACEMENT, NULL);
}

void InterTree::place(inter_tree_node *C, int how, inter_tree_node *R) {
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
	inter_tree_node *OP = InterTree::parent(C);
	if (OP) {
		if (InterTree::first_child(OP) == C)
			InterTree::set_first_child_UNSAFE(OP, InterTree::next(C));
		if (InterTree::last_child(OP) == C)
			InterTree::set_last_child_UNSAFE(OP, InterTree::previous(C));
	}
	inter_tree_node *OB = InterTree::previous(C);
	inter_tree_node *OD = InterTree::next(C);
	if (OB) {
		InterTree::set_next_UNSAFE(OB, OD);
	}
	if (OD) {
		InterTree::set_previous_UNSAFE(OD, OB);
	}
	InterTree::set_parent_UNSAFE(C, NULL);
	InterTree::set_previous_UNSAFE(C, NULL);
	InterTree::set_next_UNSAFE(C, NULL);

@<Make C the first child of R@> =
	InterTree::set_parent_UNSAFE(C, R);
	inter_tree_node *D = InterTree::first_child(R);
	if (D == NULL) {
		InterTree::set_last_child_UNSAFE(R, C);
		InterTree::set_next_UNSAFE(C, NULL);
	} else {
		InterTree::set_previous_UNSAFE(D, C);
		InterTree::set_next_UNSAFE(C, D);
	}
	InterTree::set_first_child_UNSAFE(R, C);

@<Make C the last child of R@> =
	InterTree::set_parent_UNSAFE(C, R);
	inter_tree_node *B = InterTree::last_child(R);
	if (B == NULL) {
		InterTree::set_first_child_UNSAFE(R, C);
		InterTree::set_previous_UNSAFE(C, NULL);
	} else {
		InterTree::set_next_UNSAFE(B, C);
		InterTree::set_previous_UNSAFE(C, B);
	}
	InterTree::set_last_child_UNSAFE(R, C);

@<Insert C after R@> =
	inter_tree_node *P = InterTree::parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	InterTree::set_parent_UNSAFE(C, P);
	if (InterTree::last_child(P) == R)
		InterTree::set_last_child_UNSAFE(P, C);
	else {
		inter_tree_node *D = InterTree::next(R);
		if (D == NULL) internal_error("inter tree broken");
		InterTree::set_next_UNSAFE(C, D);
		InterTree::set_previous_UNSAFE(D, C);
	}
	InterTree::set_next_UNSAFE(R, C);
	InterTree::set_previous_UNSAFE(C, R);

@<Insert C before R@> =
	inter_tree_node *P = InterTree::parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	InterTree::set_parent_UNSAFE(C, P);
	if (InterTree::first_child(P) == R)
		InterTree::set_first_child_UNSAFE(P, C);
	else {
		inter_tree_node *B = InterTree::previous(R);
		if (B == NULL) internal_error("inter tree broken");
		InterTree::set_previous_UNSAFE(C, B);
		InterTree::set_next_UNSAFE(B, C);
	}
	InterTree::set_next_UNSAFE(C, R);
	InterTree::set_previous_UNSAFE(R, C);

@

=
void InterTree::set_previous_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->previous_itn = V;
}

void InterTree::set_next_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->next_itn = V;
}

void InterTree::set_first_child_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->first_child_itn = V;
}

void InterTree::set_last_child_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->last_child_itn = V;
}

void InterTree::set_parent_UNSAFE(inter_tree_node *F, inter_tree_node *V) {
	if (F) F->parent_itn = V;
}

@

@d LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = InterTree::first_child(P); F; F = InterTree::next(F))

@d PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_tree_node *F = InterTree::first_child(P), *FN = F?(InterTree::next(F)):NULL;
		F; F = FN, FN = FN?(InterTree::next(FN)):NULL)

=
void InterTree::traverse_root_only(inter_tree *from, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(P, from->root_node) {
		if ((filter == 0) ||
			((filter > 0) && (P->W.data[ID_IFLD] == (inter_ti) filter)) ||
			((filter < 0) && (P->W.data[ID_IFLD] != (inter_ti) -filter)))
			(*visitor)(from, P, state);
	}
}

void InterTree::traverse(inter_tree *from, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, inter_package *mp, int filter) {
	if (mp == NULL) mp = Site::main_package_if_it_exists(from);
	if (mp) {
		inter_tree_node *D = Inter::Packages::definition(mp);
		if ((filter == 0) ||
			((filter > 0) && (D->W.data[ID_IFLD] == (inter_ti) filter)) ||
			((filter < 0) && (D->W.data[ID_IFLD] != (inter_ti) -filter)))
			(*visitor)(from, D, state);
		InterTree::traverse_r(from, D, visitor, state, filter);
	}
}
void InterTree::traverse_r(inter_tree *from, inter_tree_node *P, void (*visitor)(inter_tree *, inter_tree_node *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (C->W.data[ID_IFLD] == (inter_ti) filter)) ||
			((filter < 0) && (C->W.data[ID_IFLD] != (inter_ti) -filter)))
			(*visitor)(from, C, state);
		InterTree::traverse_r(from, C, visitor, state, filter);
	}
}

@

@d LOOP_THROUGH_SUBPACKAGES(entry, pack, ptype)
	inter_symbol *pack##wanted = (pack)?(PackageTypes::get(pack->package_head->tree, ptype)):NULL;
	if (pack)
		LOOP_THROUGH_INTER_CHILDREN(C, Inter::Packages::definition(pack))
			if ((C->W.data[ID_IFLD] == PACKAGE_IST) &&
				(entry = Inter::Package::defined_by_frame(C)) &&
				(Inter::Packages::type(entry) == pack##wanted))

=
int InterTree::no_subpackages(inter_package *pack, text_stream *ptype) {
	int N = 0;
	if (pack) {
		inter_package *entry;
		LOOP_THROUGH_SUBPACKAGES(entry, pack, ptype) N++;
	}
	return N;
}
