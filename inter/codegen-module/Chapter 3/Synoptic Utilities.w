[Synoptic::] Synoptic Utilities.

Managing the generation of code and arrays in the synoptic module, which is put
together from resources all over the Inter tree.

@h Pipeline stage.
This stage...

=
void Synoptic::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"consolidate-text",
		Synoptic::go, NO_STAGE_ARG, FALSE);
}

typedef struct tree_inventory {
	struct inter_tree *of_tree;
	struct linked_list *items; /* of |tree_inventory_item| */
	inter_tree_location_list *text_nodes;
	inter_tree_location_list *module_nodes;
	inter_tree_location_list *response_nodes;
	inter_tree_location_list *rulebook_nodes;
	inter_tree_location_list *rule_nodes;
	inter_tree_location_list *activity_nodes;
	inter_tree_location_list *action_nodes;
	inter_tree_location_list *property_nodes;
	inter_tree_location_list *extension_nodes;
	inter_tree_location_list *relation_nodes;
	inter_tree_location_list *table_nodes;
	inter_tree_location_list *table_column_nodes;
	inter_tree_location_list *table_column_usage_nodes;
	inter_tree_location_list *action_history_condition_nodes;
	inter_tree_location_list *past_tense_condition_nodes;
	inter_tree_location_list *instance_nodes;
	inter_tree_location_list *scene_nodes;
	inter_tree_location_list *file_nodes;
	inter_tree_location_list *figure_nodes;
	inter_tree_location_list *sound_nodes;
	inter_tree_location_list *use_option_nodes;
	inter_tree_location_list *verb_form_nodes;
	inter_tree_location_list *derived_kind_nodes;
	inter_tree_location_list *kind_nodes;
	inter_tree_location_list *test_nodes;
	inter_tree_location_list *named_action_pattern_nodes;
	CLASS_DEFINITION
} tree_inventory;

tree_inventory *Synoptic::new_inventory(inter_tree *I) {
	tree_inventory *inv = CREATE(tree_inventory);
	inv->of_tree = I;
	inv->items = NEW_LINKED_LIST(tree_inventory_item);
	inv->text_nodes = TreeLists::new();

	inv->response_nodes = Synoptic::add_inventory_need(inv, I"_response");
	inv->rulebook_nodes = Synoptic::add_inventory_need(inv, I"_rulebook");
	inv->rule_nodes = Synoptic::add_inventory_need(inv, I"_rule");
	inv->activity_nodes = Synoptic::add_inventory_need(inv, I"_activity");
	inv->action_nodes = Synoptic::add_inventory_need(inv, I"_action");
	inv->property_nodes = Synoptic::add_inventory_need(inv, I"_property");
	inv->relation_nodes = Synoptic::add_inventory_need(inv, I"_relation");
	inv->table_nodes = Synoptic::add_inventory_need(inv, I"_table");
	inv->table_column_nodes = Synoptic::add_inventory_need(inv, I"_table_column");
	inv->table_column_usage_nodes = Synoptic::add_inventory_need(inv, I"_table_column_usage");
	inv->action_history_condition_nodes = Synoptic::add_inventory_need(inv, I"_action_history_condition");
	inv->past_tense_condition_nodes = Synoptic::add_inventory_need(inv, I"_past_condition");
	inv->use_option_nodes = Synoptic::add_inventory_need(inv, I"_use_option");
	inv->verb_form_nodes = Synoptic::add_inventory_need(inv, I"_verb_form");
	inv->derived_kind_nodes = Synoptic::add_inventory_need(inv, I"_derived_kind");
	inv->kind_nodes = Synoptic::add_inventory_need(inv, I"_kind");
	inv->module_nodes = Synoptic::add_inventory_need(inv, I"_module");
	inv->instance_nodes = Synoptic::add_inventory_need(inv, I"_instance");
	inv->test_nodes = Synoptic::add_inventory_need(inv, I"_test");
	inv->named_action_pattern_nodes = Synoptic::add_inventory_need(inv, I"_named_action_pattern");

	inv->extension_nodes = TreeLists::new();
	inv->scene_nodes = TreeLists::new();
	inv->file_nodes = TreeLists::new();
	inv->figure_nodes = TreeLists::new();
	inv->sound_nodes = TreeLists::new();
	return inv;
}

typedef struct tree_inventory_item {
	struct inter_tree_location_list *node_list;
	struct inter_symbol *required_ptype;
	CLASS_DEFINITION
} tree_inventory_item;

inter_tree_location_list *Synoptic::add_inventory_need(tree_inventory *inv, text_stream *pt) {
	tree_inventory_item *item = CREATE(tree_inventory_item);
	item->node_list = TreeLists::new();
	item->required_ptype = PackageTypes::get(inv->of_tree, pt);
	ADD_TO_LINKED_LIST(item, tree_inventory_item, inv->items);
	return item->node_list;
}

void Synoptic::perform_inventory(tree_inventory *inv) {
	inter_tree *I = inv->of_tree;
	InterTree::traverse(I, Synoptic::visitor, inv, NULL, 0);
	for (int i=0; i<TreeLists::len(inv->module_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->module_nodes->list[i].node);
		if (InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), I"extension_id"))
			TreeLists::add(inv->extension_nodes, inv->module_nodes->list[i].node);
	}
	for (int i=0; i<TreeLists::len(inv->instance_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_scene"))
			TreeLists::add(inv->scene_nodes, inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_file"))
			TreeLists::add(inv->file_nodes, inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_figure"))
			TreeLists::add(inv->figure_nodes, inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_sound"))
			TreeLists::add(inv->sound_nodes, inv->instance_nodes->list[i].node);
	}
}

void Synoptic::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	tree_inventory *inv = (tree_inventory *) state;
	if (P->W.data[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_s =
			InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		if (Inter::Symbols::read_annotation(con_s, TEXT_LITERAL_IANN) == 1)
			TreeLists::add(inv->text_nodes, P);
	}
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = Inter::Package::defined_by_frame(P);
		inter_symbol *ptype = Inter::Packages::type(pack);
		tree_inventory_item *item;
		LOOP_OVER_LINKED_LIST(item, tree_inventory_item, inv->items)
			if (ptype == item->required_ptype) {
				TreeLists::add(item->node_list, P);
				break;
			}
	}
}

tree_inventory *cached_inventory = NULL;
inter_tree *cache_is_for = NULL;
tree_inventory *Synoptic::inv(inter_tree *I) {
	if (cache_is_for == I) return cached_inventory;
	cache_is_for = I;
	cached_inventory = Synoptic::new_inventory(I);
	Synoptic::perform_inventory(cached_inventory);
	return cached_inventory;
}

int Synoptic::go(pipeline_step *step) {
	tree_inventory *inv = Synoptic::inv(step->repository);

	SynopticText::compile(step->repository, inv);
	SynopticActions::compile(step->repository, inv);
	SynopticActivities::compile(step->repository, inv);
	SynopticChronology::compile(step->repository, inv);
	SynopticExtensions::compile(step->repository, inv);
	SynopticInstances::compile(step->repository, inv);
	SynopticKinds::compile(step->repository, inv);
	SynopticMultimedia::compile(step->repository, inv);
	SynopticProperties::compile(step->repository, inv);
	SynopticRelations::compile(step->repository, inv);
	SynopticResponses::compile(step->repository, inv);
	SynopticRules::compile(step->repository, inv);
	SynopticScenes::compile(step->repository, inv);
	SynopticTables::compile(step->repository, inv);
	SynopticUseOptions::compile(step->repository, inv);
	SynopticVerbs::compile(step->repository, inv);
	SynopticTests::compile(step->repository, inv);
	return TRUE;
}

@

=
int Synoptic::module_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *mod1 = Synoptic::module_containing(P1);
	inter_package *mod2 = Synoptic::module_containing(P2);
	inter_ti C1 = Metadata::read_optional_numeric(mod1, I"^category");
	inter_ti C2 = Metadata::read_optional_numeric(mod2, I"^category");
	int d = ((int) C2) - ((int) C1); /* larger values sort earlier */
	if (d != 0) return d;
	return E1->sort_key - E2->sort_key; /* smaller values sort earlier */
}

int Synoptic::category_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *mod1 = Inter::Packages::container(P1);
	inter_package *mod2 = Inter::Packages::container(P2);
	inter_ti C1 = Metadata::read_optional_numeric(mod1, I"^category");
	inter_ti C2 = Metadata::read_optional_numeric(mod2, I"^category");
	int d = ((int) C2) - ((int) C1); /* larger values sort earlier */
	if (d != 0) return d;
	return E1->sort_key - E2->sort_key; /* smaller values sort earlier */
}

@h Redefinition.

=
inter_symbol *Synoptic::new_symbol(inter_package *pack, text_stream *name) {
	return InterSymbolsTables::create_with_unique_name(Inter::Packages::scope(pack), name);
}

inter_symbol *Synoptic::get_symbol(inter_package *pack, text_stream *name) {
	inter_symbol *loc_s = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), name);
	if (loc_s == NULL) Metadata::err("package symbol not found", pack, name);
	return loc_s;
}

@

=
void Synoptic::def_textual_constant(inter_tree *I, inter_symbol *con_s, text_stream *S, inter_bookmark *IBM) {
	Inter::Symbols::annotate_i(con_s, TEXT_LITERAL_IANN, 1);
	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I),
		Inter::Bookmarks::package(IBM));
	Str::copy(Inter::Warehouse::get_text(InterTree::warehouse(I), ID), S);
	Produce::guard(Inter::Constant::new_textual(IBM,
		InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), con_s),
		InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), unchecked_kind_symbol),
		ID, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
}

@

=
inter_package *synoptic_fn_package = NULL;
packaging_state synoptic_fn_ps;
void Synoptic::begin_function(inter_tree *I, inter_name *iname) {
	synoptic_fn_package = Produce::block(I, &synoptic_fn_ps, iname);
}
void Synoptic::end_function(inter_tree *I, inter_name *iname) {
	Produce::end_block(I);
	Synoptic::function(I, iname, synoptic_fn_package);
	Produce::end_main_block(I, synoptic_fn_ps);
}

void Synoptic::function(inter_tree *I, inter_name *fn_iname, inter_package *block) {
	inter_symbol *fn_s = Produce::define_symbol(fn_iname);
	Produce::guard(Inter::Constant::new_function(Packaging::at(I),
		InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(Packaging::at(I)), fn_s),
		InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(Packaging::at(I)), unchecked_kind_symbol),
		block,
		Produce::baseline(Packaging::at(I)), NULL));
}
inter_symbol *Synoptic::local(inter_tree *I, text_stream *name,
	text_stream *comment) {
	return Produce::local(I, K_value, name, 0, comment);
}

inter_tree_node *synoptic_array_node = NULL;
packaging_state synoptic_array_ps;
void Synoptic::begin_array(inter_tree *I, inter_name *iname) {
	synoptic_array_ps = Packaging::enter_home_of(iname);
	inter_symbol *con_s = Produce::define_symbol(iname);
	synoptic_array_node = Inode::fill_3(Packaging::at(I), CONSTANT_IST,
		 InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), con_s),
		 InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), list_of_unchecked_kind_symbol),
		 CONSTANT_INDIRECT_LIST, NULL, (inter_ti) Inter::Bookmarks::baseline(Packaging::at(I)) + 1);
}
void Synoptic::end_array(inter_tree *I) {
	inter_error_message *E =
		Inter::Defn::verify_construct(Inter::Bookmarks::package(Packaging::at(I)), synoptic_array_node);
	if (E) {
		Inter::Errors::issue(E);
		internal_error("synoptic array failed verification");
	}
	Inter::Bookmarks::insert(Packaging::at(I), synoptic_array_node);
	Packaging::exit(I, synoptic_array_ps);
}

void Synoptic::numeric_entry(inter_ti val2) {
	if (Inode::extend(synoptic_array_node, 2) == FALSE) internal_error("cannot extend");
	synoptic_array_node->W.data[synoptic_array_node->W.extent-2] = LITERAL_IVAL;
	synoptic_array_node->W.data[synoptic_array_node->W.extent-1] = val2;
}
void Synoptic::symbol_entry(inter_symbol *S) {
	if (Inode::extend(synoptic_array_node, 2) == FALSE) internal_error("cannot extend");
	inter_package *pack = Inter::Packages::container(synoptic_array_node);
	inter_symbol *local_S = InterSymbolsTables::create_with_unique_name(Inter::Packages::scope(pack), S->symbol_name);
	InterSymbolsTables::equate(local_S, S);
	inter_ti val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Packages::tree(pack), pack, local_S, &val1, &val2);
	synoptic_array_node->W.data[synoptic_array_node->W.extent-2] = ALIAS_IVAL;
	synoptic_array_node->W.data[synoptic_array_node->W.extent-1] = val2;
}
void Synoptic::textual_entry(text_stream *text) {
	if (Inode::extend(synoptic_array_node, 2) == FALSE) internal_error("cannot extend");
	inter_package *pack = Inter::Packages::container(synoptic_array_node);
	inter_tree *I = Inter::Packages::tree(pack);
	inter_ti val2 = Inter::Warehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
	Str::copy(glob_storage, text);
	synoptic_array_node->W.data[synoptic_array_node->W.extent-2] = LITERAL_TEXT_IVAL;
	synoptic_array_node->W.data[synoptic_array_node->W.extent-1] = val2;
}

inter_tree_node *Synoptic::get_definition(inter_package *pack, text_stream *name) {
	inter_symbol *def_s = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), name);
	if (def_s == NULL) {
		LOG("Unable to find symbol %S in $6\n", name, pack);
		internal_error("no symbol");
	}
	inter_tree_node *D = def_s->definition;
	if (D == NULL) {
		LOG("Undefined symbol %S in $6\n", name, pack);
		internal_error("undefined symbol");
	}
	return D;
}

inter_tree_node *Synoptic::get_optional_definition(inter_package *pack, text_stream *name) {
	inter_symbol *def_s = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), name);
	if (def_s == NULL) return NULL;
	inter_tree_node *D = def_s->definition;
	if (D == NULL) internal_error("undefined symbol");
	return D;
}

inter_package *Synoptic::module_containing(inter_tree_node *P) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree *I = Inter::Packages::tree(pack);
	while (pack) {
		inter_symbol *ptype = Inter::Packages::type(pack);
		if (ptype == PackageTypes::get(I, I"_module")) return pack;
		pack = Inter::Packages::parent(pack);
	}
	return NULL;
}
