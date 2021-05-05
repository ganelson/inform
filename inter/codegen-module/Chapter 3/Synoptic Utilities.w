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

inter_tree_location_list *text_nodes = NULL;
inter_tree_location_list *response_nodes = NULL;
inter_tree_location_list *rulebook_nodes = NULL;
inter_tree_location_list *rule_nodes = NULL;
inter_tree_location_list *activity_nodes = NULL;
inter_tree_location_list *action_nodes = NULL;
inter_tree_location_list *property_nodes = NULL;
inter_tree_location_list *extension_nodes = NULL;
inter_tree_location_list *relation_nodes = NULL;
inter_tree_location_list *table_nodes = NULL;
inter_tree_location_list *table_column_nodes = NULL;
inter_tree_location_list *table_column_usage_nodes = NULL;
inter_tree_location_list *past_tense_action_nodes = NULL;
inter_tree_location_list *past_tense_condition_nodes = NULL;
inter_tree_location_list *instance_nodes = NULL;
inter_tree_location_list *scene_nodes = NULL;
inter_tree_location_list *file_nodes = NULL;
inter_tree_location_list *figure_nodes = NULL;
inter_tree_location_list *sound_nodes = NULL;
inter_tree_location_list *use_option_nodes = NULL;
inter_tree_location_list *verb_form_nodes = NULL;
inter_tree_location_list *derived_kind_nodes = NULL;
inter_tree_location_list *kind_nodes = NULL;

int Synoptic::go(pipeline_step *step) {
	text_nodes = TreeLists::new();
	response_nodes = TreeLists::new();
	rulebook_nodes = TreeLists::new();
	rule_nodes = TreeLists::new();
	activity_nodes = TreeLists::new();
	action_nodes = TreeLists::new();
	property_nodes = TreeLists::new();
	extension_nodes = TreeLists::new();
	relation_nodes = TreeLists::new();
	table_nodes = TreeLists::new();
	table_column_nodes = TreeLists::new();
	table_column_usage_nodes = TreeLists::new();
	past_tense_action_nodes = TreeLists::new();
	past_tense_condition_nodes = TreeLists::new();
	instance_nodes = TreeLists::new();
	scene_nodes = TreeLists::new();
	file_nodes = TreeLists::new();
	figure_nodes = TreeLists::new();
	sound_nodes = TreeLists::new();
	use_option_nodes = TreeLists::new();
	verb_form_nodes = TreeLists::new();
	derived_kind_nodes = TreeLists::new();
	kind_nodes = TreeLists::new();
	InterTree::traverse(step->repository, Synoptic::visitor, NULL, NULL, 0);

	SynopticText::alphabetise(step->repository, text_nodes);
	
	SynopticActions::compile(step->repository, action_nodes);
	SynopticActivities::compile(step->repository, activity_nodes);
	SynopticChronology::compile(step->repository);
	SynopticExtensions::compile(step->repository, extension_nodes);
	SynopticInstances::compile(step->repository, instance_nodes);
	SynopticKinds::compile(step->repository);
	SynopticMultimedia::compile(step->repository);
	SynopticProperties::compile(step->repository, property_nodes);
	SynopticRelations::compile(step->repository, relation_nodes);
	SynopticResponses::compile(step->repository, response_nodes);
	SynopticRules::compile(step->repository);
	SynopticScenes::compile(step->repository, scene_nodes);
	SynopticTables::compile(step->repository, table_nodes);
	SynopticUseOptions::compile(step->repository);
	SynopticVerbs::compile(step->repository);
	return TRUE;
}

void Synoptic::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_s =
			InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		if (Inter::Symbols::read_annotation(con_s, TEXT_LITERAL_IANN) == 1)
			TreeLists::add(text_nodes, P);
	}
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = Inter::Package::defined_by_frame(P);
		inter_symbol *ptype = Inter::Packages::type(pack);
		if (ptype == PackageTypes::get(I, I"_response"))
			TreeLists::add(response_nodes, P);
		if (ptype == PackageTypes::get(I, I"_rulebook"))
			TreeLists::add(rulebook_nodes, P);
		if (ptype == PackageTypes::get(I, I"_rule"))
			TreeLists::add(rule_nodes, P);
		if (ptype == PackageTypes::get(I, I"_activity"))
			TreeLists::add(activity_nodes, P);
		if (ptype == PackageTypes::get(I, I"_action"))
			TreeLists::add(action_nodes, P);
		if (ptype == PackageTypes::get(I, I"_property"))
			TreeLists::add(property_nodes, P);
		if (ptype == PackageTypes::get(I, I"_module")) {
			if (InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), I"extension_id"))
				TreeLists::add(extension_nodes, P);
		}
		if (ptype == PackageTypes::get(I, I"_relation"))
			TreeLists::add(relation_nodes, P);
		if (ptype == PackageTypes::get(I, I"_table"))
			TreeLists::add(table_nodes, P);
		if (ptype == PackageTypes::get(I, I"_table_column_usage"))
			TreeLists::add(table_column_usage_nodes, P);
		if (ptype == PackageTypes::get(I, I"_table_column"))
			TreeLists::add(table_column_nodes, P);
		if (ptype == PackageTypes::get(I, I"_past_action_pattern"))
			TreeLists::add(past_tense_action_nodes, P);
		if (ptype == PackageTypes::get(I, I"_past_condition"))
			TreeLists::add(past_tense_condition_nodes, P);
		if (ptype == PackageTypes::get(I, I"_use_option"))
			TreeLists::add(use_option_nodes, P);
		if (ptype == PackageTypes::get(I, I"_verb_form"))
			TreeLists::add(verb_form_nodes, P);
		if (ptype == PackageTypes::get(I, I"_kind"))
			TreeLists::add(kind_nodes, P);
		if (ptype == PackageTypes::get(I, I"_derived_kind"))
			TreeLists::add(derived_kind_nodes, P);
		if (ptype == PackageTypes::get(I, I"_instance")) {
			TreeLists::add(instance_nodes, P);
			inter_package *pack = Inter::Package::defined_by_frame(P);
			if (Metadata::exists(pack, I"^is_scene"))
				TreeLists::add(scene_nodes, P);
			if (Metadata::exists(pack, I"^is_file"))
				TreeLists::add(file_nodes, P);
			if (Metadata::exists(pack, I"^is_figure"))
				TreeLists::add(figure_nodes, P);
			if (Metadata::exists(pack, I"^is_sound"))
				TreeLists::add(sound_nodes, P);
		}
	}
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
