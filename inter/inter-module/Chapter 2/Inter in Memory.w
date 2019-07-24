[Inter::] Inter in Memory.

To store bytecode-like intermediate code in memory.

@

=
typedef struct inter_tree {
	struct inter_frame *root_definition_frame;
	struct inter_package *root_package;
	struct inter_package *main_package;
	MEMORY_MANAGEMENT
} inter_tree;

typedef struct inter_tree_node {
	struct inter_tree_node *node;
	struct inter_tree *tree;
	struct inter_package *package;
	struct inter_tree_node *parent_itn;
	struct inter_tree_node *first_child_itn;
	struct inter_tree_node *last_child_itn;
	struct inter_tree_node *previous_itn;
	struct inter_tree_node *next_itn;
	struct warehouse_floor_space W;
//	struct inter_frame content;
} inter_tree_node;

@ =
inter_tree_node Inter::new_itn(inter_tree *I) {
	inter_tree_node itn;
	itn.tree = I;
	itn.package = NULL;
	itn.parent_itn = NULL;
	itn.first_child_itn = NULL;
	itn.last_child_itn = NULL;
	itn.previous_itn = NULL;
	itn.next_itn = NULL;
	return itn;
}

inter_tree *Inter::create(void) {
	inter_tree *I = CREATE(inter_tree);
	I->main_package = NULL;

	inter_warehouse *warehouse = Inter::Warehouse::new();
	inter_t N = Inter::Warehouse::create_symbols_table(warehouse);
	inter_symbols_table *globals = Inter::Warehouse::get_symbols_table(warehouse, N);
	I->root_package = Inter::Warehouse::get_package(warehouse, Inter::Warehouse::create_package(warehouse, I));
	I->root_definition_frame = Inter::Frame::root_frame(warehouse, I);
	Inter::Packages::make_rootlike(I->root_package);
	Inter::Packages::set_scope(I->root_package, globals);
	Inter::Warehouse::attribute_resource(warehouse, N, I->root_package);
	return I;
}

inter_warehouse *Inter::warehouse(inter_tree *I) {
	return Inter::Frame::warehouse(I->root_definition_frame);
}

inter_symbols_table *Inter::get_global_symbols(inter_tree *I) {
	return Inter::Packages::scope(I->root_package);
}

inter_symbols_table *Inter::get_symbols_table(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_symbols_table(Inter::warehouse(I), n);
}

inter_package *Inter::get_package(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_package(Inter::warehouse(I), n);
}

text_stream *Inter::get_text(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_text(Inter::warehouse(I), n);
}

void *Inter::get_ref(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_ref(Inter::warehouse(I), n);
}

inter_frame_list *Inter::get_frame_list(inter_tree *I, inter_t N) {
	if (I == NULL) return NULL;
	return Inter::Warehouse::get_frame_list(Inter::warehouse(I), N);
}

inter_frame *Inter::get_previous(inter_frame *F) {
	if (F == NULL) return NULL;
	inter_tree_node *itn = Inter::Frame::node(F);
	itn = itn->previous_itn;
	if (itn == NULL) return NULL;
	return itn;
//	return &(itn->content);
}

void Inter::set_previous(inter_frame *F, inter_frame *V) {
	if (F) {
		inter_tree_node *itn = Inter::Frame::node(F);
		itn->previous_itn = Inter::Frame::node(V);
	}
}

inter_frame *Inter::get_next(inter_frame *F) {
	if (F == NULL) return NULL;
	inter_tree_node *itn = Inter::Frame::node(F);
	itn = itn->next_itn;
	if (itn == NULL) return NULL;
	return itn;
//	return &(itn->content);
}

void Inter::set_next(inter_frame *F, inter_frame *V) {
	if (F) {
		inter_tree_node *itn = Inter::Frame::node(F);
		itn->next_itn = Inter::Frame::node(V);
	}
}

inter_frame *Inter::get_first_child(inter_frame *F) {
	if (F == NULL) return NULL;
	inter_tree_node *itn = Inter::Frame::node(F);
	itn = itn->first_child_itn;
	if (itn == NULL) return NULL;
	return itn;
//	return &(itn->content);
}

void Inter::set_first_child(inter_frame *F, inter_frame *V) {
	if (F) {
		inter_tree_node *itn = Inter::Frame::node(F);
		itn->first_child_itn = Inter::Frame::node(V);
	}
}

inter_frame *Inter::get_last_child(inter_frame *F) {
	if (F == NULL) return NULL;
	inter_tree_node *itn = Inter::Frame::node(F);
	itn = itn->last_child_itn;
	if (itn == NULL) return NULL;
	return itn;
//	return &(itn->content);
}

void Inter::set_last_child(inter_frame *F, inter_frame *V) {
	if (F) {
		inter_tree_node *itn = Inter::Frame::node(F);
		itn->last_child_itn = Inter::Frame::node(V);
	}
}

inter_frame *Inter::get_parent(inter_frame *F) {
	if (F == NULL) return NULL;
	inter_tree_node *itn = Inter::Frame::node(F);
	itn = itn->parent_itn;
	if (itn == NULL) return NULL;
	return itn;
//	return &(itn->content);
}

void Inter::set_parent(inter_frame *F, inter_frame *V) {
	if (F) {
		inter_tree_node *itn = Inter::Frame::node(F);
		itn->parent_itn = Inter::Frame::node(V);
	}
}

inter_frame *Inter::first_child_P(inter_frame *P) {
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		return F;
	return NULL;
}

inter_frame *Inter::second_child_P(inter_frame *P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 2)
			return F;
	return NULL;
}

inter_frame *Inter::third_child_P(inter_frame *P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 3)
			return F;
	return NULL;
}

inter_frame *Inter::fourth_child_P(inter_frame *P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 4)
			return F;
	return NULL;
}

inter_frame *Inter::fifth_child_P(inter_frame *P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 5)
			return F;
	return NULL;
}

inter_frame *Inter::sixth_child_P(inter_frame *P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 6)
			return F;
	return NULL;
}

void Inter::traverse_global_list(inter_tree *from, void (*visitor)(inter_tree *, inter_frame *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(P, from->root_definition_frame) {
		if ((filter == 0) ||
			((filter > 0) && (P->node->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (P->node->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, P, state);
	}
}

void Inter::traverse_tree(inter_tree *from, void (*visitor)(inter_tree *, inter_frame *, void *), void *state, inter_package *mp, int filter) {
	if (mp == NULL) mp = Inter::Packages::main(from);
	if (mp) {
		inter_frame *D = Inter::Symbols::definition(mp->package_name);
		if ((filter == 0) ||
			((filter > 0) && (D->node->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (D->node->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, D, state);
		Inter::traverse_tree_r(from, D, visitor, state, filter);
	}
}
void Inter::traverse_tree_r(inter_tree *from, inter_frame *P, void (*visitor)(inter_tree *, inter_frame *, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (C->node->W.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (C->node->W.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, C, state);
		Inter::traverse_tree_r(from, C, visitor, state, filter);
	}
}
