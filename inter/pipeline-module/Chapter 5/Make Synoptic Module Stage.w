[MakeSynopticModuleStage::] Make Synoptic Module Stage.

Creating a top-level module of synoptic resources.

@ At this point the tree contains one module for each compilation unit included
in the link: which is a fancy way of saying, it contains one module for the
main source text, ohe for each extension, and one each for each kit included.

We now add one final module, |/main/synoptic|, which contains resources compiled
together from all of the others.

=
void MakeSynopticModuleStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"make-synoptic-module",
		MakeSynopticModuleStage::run, NO_STAGE_ARG, FALSE);
}

int MakeSynopticModuleStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	tree_inventory *inv = MakeSynopticModuleStage::take_inventory_cached(I);

	SynopticHierarchy::establish(I); /* in case this has not already been done */
	KitHierarchy::establish(I); /* likewise */

	SynopticText::compile(I, step, inv);
	SynopticActions::compile(I, step, inv);
	SynopticActivities::compile(I, step, inv);
	SynopticChronology::compile(I, step, inv);
	SynopticExtensions::compile(I, step, inv);
	SynopticInstances::compile(I, step, inv);
	SynopticKinds::compile(I, step, inv);
	SynopticMultimedia::compile(I, step, inv);
	SynopticProperties::compile(I, step, inv);
	SynopticRelations::compile(I, step, inv);
	SynopticResponses::compile(I, step, inv);
	SynopticRules::compile(I, step, inv);
	SynopticScenes::compile(I, step, inv);
	SynopticTables::compile(I, step, inv);
	SynopticUseOptions::compile(I, step, inv);
	SynopticVerbs::compile(I, step, inv);
	SynopticTests::compile(I, step, inv);
	
	Wiring::connect_plugs_to_sockets(I);
	return TRUE;
}

@ The inventory for an Inter tree is an itemisation of packages with particular
types: for example, we can ask it to hold a list of |_activity| packages.

=
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
	inter_tree_location_list *verb_nodes;
	inter_tree_location_list *modal_verb_nodes;
	inter_tree_location_list *verb_form_nodes;
	inter_tree_location_list *preposition_nodes;
	inter_tree_location_list *adjective_nodes;
	inter_tree_location_list *derived_kind_nodes;
	inter_tree_location_list *kind_nodes;
	inter_tree_location_list *test_nodes;
	inter_tree_location_list *named_action_pattern_nodes;
	inter_tree_location_list *variable_nodes;
	inter_tree_location_list *equation_nodes;
	inter_tree_location_list *heading_nodes;
	inter_tree_location_list *multiplication_rule_nodes;
	CLASS_DEFINITION
} tree_inventory;

typedef struct tree_inventory_item {
	struct inter_tree_location_list *node_list;
	struct inter_symbol *required_ptype;
	CLASS_DEFINITION
} tree_inventory_item;

@ Creating one of these is quick enough: when created, it's just a list of
requirements.

=
tree_inventory *MakeSynopticModuleStage::new_inventory(inter_tree *I) {
	tree_inventory *inv = CREATE(tree_inventory);
	inv->of_tree = I;
	inv->items = NEW_LINKED_LIST(tree_inventory_item);
	inv->text_nodes = TreeLists::new();

	inv->response_nodes = MakeSynopticModuleStage::needs(inv, I"_response");
	inv->rulebook_nodes = MakeSynopticModuleStage::needs(inv, I"_rulebook");
	inv->rule_nodes = MakeSynopticModuleStage::needs(inv, I"_rule");
	inv->activity_nodes = MakeSynopticModuleStage::needs(inv, I"_activity");
	inv->action_nodes = MakeSynopticModuleStage::needs(inv, I"_action");
	inv->property_nodes = MakeSynopticModuleStage::needs(inv, I"_property");
	inv->relation_nodes = MakeSynopticModuleStage::needs(inv, I"_relation");
	inv->table_nodes = MakeSynopticModuleStage::needs(inv, I"_table");
	inv->table_column_nodes = MakeSynopticModuleStage::needs(inv, I"_table_column");
	inv->table_column_usage_nodes = MakeSynopticModuleStage::needs(inv, I"_table_column_usage");
	inv->action_history_condition_nodes = MakeSynopticModuleStage::needs(inv, I"_action_history_condition");
	inv->past_tense_condition_nodes = MakeSynopticModuleStage::needs(inv, I"_past_condition");
	inv->use_option_nodes = MakeSynopticModuleStage::needs(inv, I"_use_option");
	inv->verb_nodes = MakeSynopticModuleStage::needs(inv, I"_verb");
	inv->modal_verb_nodes = MakeSynopticModuleStage::needs(inv, I"_modal_verb");
	inv->verb_form_nodes = MakeSynopticModuleStage::needs(inv, I"_verb_form");
	inv->preposition_nodes = MakeSynopticModuleStage::needs(inv, I"_preposition");
	inv->adjective_nodes = MakeSynopticModuleStage::needs(inv, I"_adjective");
	inv->derived_kind_nodes = MakeSynopticModuleStage::needs(inv, I"_derived_kind");
	inv->kind_nodes = MakeSynopticModuleStage::needs(inv, I"_kind");
	inv->module_nodes = MakeSynopticModuleStage::needs(inv, I"_module");
	inv->instance_nodes = MakeSynopticModuleStage::needs(inv, I"_instance");
	inv->test_nodes = MakeSynopticModuleStage::needs(inv, I"_test");
	inv->named_action_pattern_nodes = MakeSynopticModuleStage::needs(inv, I"_named_action_pattern");
	inv->variable_nodes = MakeSynopticModuleStage::needs(inv, I"_variable");
	inv->equation_nodes = MakeSynopticModuleStage::needs(inv, I"_equation");
	inv->heading_nodes = MakeSynopticModuleStage::needs(inv, I"_heading");
	inv->multiplication_rule_nodes = MakeSynopticModuleStage::needs(inv, I"_multiplication_rule");

	inv->extension_nodes = TreeLists::new();
	inv->scene_nodes = TreeLists::new();
	inv->file_nodes = TreeLists::new();
	inv->figure_nodes = TreeLists::new();
	inv->sound_nodes = TreeLists::new();
	return inv;
}

inter_tree_location_list *MakeSynopticModuleStage::needs(tree_inventory *inv, text_stream *pt) {
	tree_inventory_item *item = CREATE(tree_inventory_item);
	item->node_list = TreeLists::new();
	item->required_ptype = LargeScale::package_type(inv->of_tree, pt);
	ADD_TO_LINKED_LIST(item, tree_inventory_item, inv->items);
	return item->node_list;
}

@ The expensive part comes later, when we traverse the Inter tree and add
interesting packages to one of the lists.

=
tree_inventory *MakeSynopticModuleStage::take_inventory(inter_tree *I) {
	tree_inventory *inv = MakeSynopticModuleStage::new_inventory(I);
	InterTree::traverse(I, MakeSynopticModuleStage::visitor, inv, NULL, 0);
	for (int i=0; i<TreeLists::len(inv->module_nodes); i++) {
		inter_package *pack = InterPackage::at_this_head(inv->module_nodes->list[i].node);
		if (InterSymbolsTables::symbol_from_name(InterPackage::scope(pack), I"extension_id"))
			TreeLists::add(inv->extension_nodes, inv->module_nodes->list[i].node);
	}
	for (int i=0; i<TreeLists::len(inv->instance_nodes); i++) {
		inter_package *pack = InterPackage::at_this_head(inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_scene"))
			TreeLists::add(inv->scene_nodes, inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_file"))
			TreeLists::add(inv->file_nodes, inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_figure"))
			TreeLists::add(inv->figure_nodes, inv->instance_nodes->list[i].node);
		if (Metadata::exists(pack, I"^is_sound"))
			TreeLists::add(inv->sound_nodes, inv->instance_nodes->list[i].node);
	}
	return inv;
}

void MakeSynopticModuleStage::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	tree_inventory *inv = (tree_inventory *) state;
	if (P->W.instruction[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_s =
			InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		if (Inter::Symbols::read_annotation(con_s, TEXT_LITERAL_IANN) == 1)
			TreeLists::add(inv->text_nodes, P);
	}
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = InterPackage::at_this_head(P);
		inter_symbol *ptype = InterPackage::type(pack);
		tree_inventory_item *item;
		LOOP_OVER_LINKED_LIST(item, tree_inventory_item, inv->items)
			if (ptype == item->required_ptype) {
				TreeLists::add(item->node_list, P);
				break;
			}
	}
}

@ Calling //MakeSynopticModuleStage::take_inventory// is potentially slow, so
we also offer a version which caches the results:

=
tree_inventory *cached_inventory = NULL;
inter_tree *cache_is_for = NULL;
tree_inventory *MakeSynopticModuleStage::take_inventory_cached(inter_tree *I) {
	if (cache_is_for == I) return cached_inventory;
	cache_is_for = I;
	cached_inventory = MakeSynopticModuleStage::take_inventory(I);
	return cached_inventory;
}

@ The following are used for sorting.

=
int MakeSynopticModuleStage::module_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *mod1 = MakeSynopticModuleStage::module_containing(P1);
	inter_package *mod2 = MakeSynopticModuleStage::module_containing(P2);
	inter_ti C1 = Metadata::read_optional_numeric(mod1, I"^category");
	inter_ti C2 = Metadata::read_optional_numeric(mod2, I"^category");
	int d = ((int) C2) - ((int) C1); /* larger values sort earlier */
	if (d != 0) return d;
	return E1->sort_key - E2->sort_key; /* smaller values sort earlier */
}

int MakeSynopticModuleStage::category_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *mod1 = InterPackage::container(P1);
	inter_package *mod2 = InterPackage::container(P2);
	inter_ti C1 = Metadata::read_optional_numeric(mod1, I"^category");
	inter_ti C2 = Metadata::read_optional_numeric(mod2, I"^category");
	int d = ((int) C2) - ((int) C1); /* larger values sort earlier */
	if (d != 0) return d;
	return E1->sort_key - E2->sort_key; /* smaller values sort earlier */
}

inter_package *MakeSynopticModuleStage::module_containing(inter_tree_node *P) {
	inter_package *pack = InterPackage::container(P);
	inter_tree *I = InterPackage::tree(pack);
	while (pack) {
		inter_symbol *ptype = InterPackage::type(pack);
		if (ptype == LargeScale::package_type(I, I"_module")) return pack;
		pack = InterPackage::parent(pack);
	}
	return NULL;
}
