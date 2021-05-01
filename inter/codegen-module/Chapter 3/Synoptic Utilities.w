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
	InterTree::traverse(step->repository, Synoptic::visitor, NULL, NULL, 0);
	SynopticText::alphabetise(step->repository, text_nodes);
	
	InterTree::traverse(step->repository, Synoptic::syn_visitor, NULL, NULL, 0);
	SynopticResponses::renumber(step->repository, response_nodes);
	SynopticRules::renumber(step->repository, rulebook_nodes);
	SynopticActivities::renumber(step->repository, activity_nodes);
	SynopticActions::renumber(step->repository, action_nodes);
	SynopticProperties::renumber(step->repository, property_nodes);
	SynopticExtensions::renumber(step->repository, extension_nodes);
	SynopticRelations::renumber(step->repository, relation_nodes);
	SynopticTables::renumber(step->repository, table_nodes);
	SynopticChronology::renumber(step->repository, past_tense_action_nodes);
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
	}
}

@

@e NO_SYNID from 0

=
void Synoptic::syn_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_s =
			InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		int synid = Inter::Symbols::read_annotation(con_s, SYNOPTIC_IANN);
		if (synid > NO_SYNID) {
			Inter::Symbols::unannotate(con_s, SYNOPTIC_IANN);
			if (SynopticResponses::redefine(I, P, con_s, synid)) return;
			if (SynopticRules::redefine(I, P, con_s, synid)) return;
			if (SynopticActivities::redefine(I, P, con_s, synid)) return;
			if (SynopticActions::redefine(I, P, con_s, synid)) return;
			if (SynopticProperties::redefine(I, P, con_s, synid)) return;
			if (SynopticExtensions::redefine(I, P, con_s, synid)) return;
			if (SynopticRelations::redefine(I, P, con_s, synid)) return;
			if (SynopticTables::redefine(I, P, con_s, synid)) return;
			if (SynopticChronology::redefine(I, P, con_s, synid)) return;
			LOG("Couldn't consolidate $3\n", con_s);
			internal_error("symbol cannot be consolidated");
		}
	}
}

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

inter_symbol *Synoptic::get_local(inter_tree *I, text_stream *name) {
	inter_package *pack = Inter::Bookmarks::package(Produce::at(I));
	inter_symbol *loc_s = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), name);
	if (loc_s == NULL) Metadata::err("local not found", pack, name);
	return loc_s;
}

packaging_state Synoptic::begin_redefining_function(inter_bookmark *IBM, inter_tree *I, inter_tree_node *P) {
	if (P->W.data[FORMAT_CONST_IFLD] != CONSTANT_ROUTINE) {
		LOG("%d\n", P->W.data[FORMAT_CONST_IFLD]);
		internal_error("not a function");
	}
	inter_package *block = Inode::ID_to_package(P, P->W.data[DATA_CONST_IFLD]);
	inter_tree_node *first_F = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, block->package_head)
		if (F->W.data[ID_IFLD] == CODE_IST)
			first_F = InterTree::first_child(F);
	if (first_F == NULL) internal_error("failed to find code block");
	Site::set_cir(I, block);
	*IBM = Inter::Bookmarks::after_this_node(I, first_F);
	Produce::push_code_position(I, Produce::new_cip(I, IBM), Inter::Bookmarks::snapshot(Packaging::at(I)));
	packaging_state save = I->site.current_state;
	Packaging::set_state(I, IBM, Packaging::enclosure(I));
	return save;
}

void Synoptic::end_redefining_function(inter_tree *I, packaging_state save) {
	Packaging::set_state(I, save.saved_IRS, save.saved_enclosure);
	Produce::pop_code_position(I);
	Site::set_cir(I, NULL);
}

@

=
void Synoptic::def_numeric_constant(inter_symbol *con_s, inter_ti val, inter_bookmark *IBM) {
	Produce::guard(Inter::Constant::new_numerical(IBM,
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_s),
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, list_of_unchecked_kind_symbol),
		LITERAL_IVAL, val, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
}

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
inter_tree_node *Synoptic::begin_array(inter_symbol *con_s, inter_bookmark *IBM) {
	return Inode::fill_3(IBM, CONSTANT_IST,
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_s),
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, list_of_unchecked_kind_symbol),
		 CONSTANT_INDIRECT_LIST, NULL, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1);
}
inter_tree_node *Synoptic::begin_byte_array(inter_symbol *con_s, inter_bookmark *IBM) {
	Inter::Symbols::annotate_i(con_s, BYTEARRAY_IANN, 1);
	return Inode::fill_3(IBM, CONSTANT_IST,
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_s),
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, list_of_unchecked_kind_symbol),
		 CONSTANT_INDIRECT_LIST, NULL, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1);
}
inter_tree_node *Synoptic::begin_table_array(inter_symbol *con_s, inter_bookmark *IBM) {
	Inter::Symbols::annotate_i(con_s, TABLEARRAY_IANN, 1);
	return Inode::fill_3(IBM, CONSTANT_IST,
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_s),
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, list_of_unchecked_kind_symbol),
		 CONSTANT_INDIRECT_LIST, NULL, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1);
}
void Synoptic::end_array(inter_tree_node *Q, inter_bookmark *IBM) {
	inter_error_message *E =
		Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), Q);
	if (E) {
		Inter::Errors::issue(E);
		internal_error("synoptic array failed verification");
	}
	Inter::Bookmarks::insert(IBM, Q);
}

void Synoptic::numeric_entry(inter_tree_node *Q, inter_ti val2) {
	if (Inode::extend(Q, 2) == FALSE) internal_error("cannot extend");
	Q->W.data[Q->W.extent-2] = LITERAL_IVAL;
	Q->W.data[Q->W.extent-1] = val2;
}
void Synoptic::symbol_entry(inter_tree_node *Q, inter_symbol *S) {
	if (Inode::extend(Q, 2) == FALSE) internal_error("cannot extend");
	inter_package *pack = Inter::Packages::container(Q);
	inter_symbol *local_S = InterSymbolsTables::create_with_unique_name(Inter::Packages::scope(pack), S->symbol_name);
	InterSymbolsTables::equate(local_S, S);
	inter_ti val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Packages::tree(pack), pack, local_S, &val1, &val2);
	Q->W.data[Q->W.extent-2] = ALIAS_IVAL;
	Q->W.data[Q->W.extent-1] = val2;
}
void Synoptic::textual_entry(inter_tree_node *Q, text_stream *text) {
	if (Inode::extend(Q, 2) == FALSE) internal_error("cannot extend");
	inter_package *pack = Inter::Packages::container(Q);
	inter_tree *I = Inter::Packages::tree(pack);
	inter_ti val2 = Inter::Warehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
	Str::copy(glob_storage, text);
	Q->W.data[Q->W.extent-2] = LITERAL_TEXT_IVAL;
	Q->W.data[Q->W.extent-1] = val2;
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
