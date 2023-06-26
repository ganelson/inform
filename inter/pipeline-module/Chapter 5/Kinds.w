[SynopticKinds::] Kinds.

To compile the main/synoptic/kinds submodule.

@ Our inventory |inv| already contains a list |inv->kind_nodes| of all packages
in the tree with type |_kind|; here is one for each base kind. Similarly for
the list |inv->derived_kind_nodes|.

=
void SynopticKinds::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (InterNodeList::array_len(inv->kind_nodes) > 0) @<Assign unique strong ID numbers@>;
	if (InterNodeList::array_len(inv->derived_kind_nodes) > 0)
		InterNodeList::array_sort(inv->derived_kind_nodes, MakeSynopticModuleStage::module_order);
	@<Define BASE_KIND_HWM@>;	
	@<Define DEFAULTVALUEFINDER function@>;
	@<Define VALUESFINDER function@>;
	@<Define DEFAULTVALUEOFKOV function@>;
	@<Define PRINTKINDVALUEPAIR function@>;
	@<Define KOVCOMPARISONFUNCTION function@>;
	@<Define KOVDOMAINSIZE function@>;
	@<Define KOVISBLOCKVALUE function@>;
	@<Define I7_KIND_NAME function@>;
	@<Define KOVSUPPORTFUNCTION function@>;
	@<Define SHOWMEKINDDETAILS function@>;
	@<Define RUCKSACK_CLASS constant@>;
	@<Define KINDHIERARCHY array@>;
}

@ Each base kind package contains a numeric constant with the symbol name |strong_id|.
We want to ensure that these ID numbers are contiguous from 2 and never duplicated,
so we change the values of these constants accordingly. (From 2 because we want to
avoid 0, and we want 1 always to mean "kind unknown".)

Note that derived kinds are not enumerated in this way; their strong ID constants
are addresses of small arrays.

@<Assign unique strong ID numbers@> =
	InterNodeList::array_sort(inv->kind_nodes, MakeSynopticModuleStage::module_order);
	for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
		inter_symbol *id_s = Metadata::optional_symbol(pack, I"^strong_id");
		if (id_s) InterSymbol::set_int(id_s, i+2);
	}

@ The "high water mark" of strong IDs for base kinds. Any strong ID this high
or higher is therefore that of a derived kind.

@<Define BASE_KIND_HWM@> =
	inter_name *iname = HierarchyLocations::iname(I, BASE_KIND_HWM_HL);
	Produce::numeric_constant(I, iname, K_value,
		(inter_ti) (InterNodeList::array_len(inv->kind_nodes) + 2));

@<Define DEFAULTVALUEFINDER function@> =
	inter_name *iname = HierarchyLocations::iname(I, DEFAULTVALUEFINDER_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	for (int i=0; i<InterNodeList::array_len(inv->derived_kind_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->derived_kind_nodes->list[i].node);
		if (Metadata::read_numeric(pack, I"^default_value_needed")) {
			inter_symbol *rks_s = Synoptic::get_symbol(pack, I"strong_id");
			inter_symbol *dv_s = Synoptic::get_symbol(pack, I"default_value");
			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, EQ_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, k_s);
					Produce::val_symbol(I, K_value, rks_s);
				Produce::up(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, RETURN_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, dv_s);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		}
	}
	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@<Define VALUESFINDER function@> =
	inter_name *iname = HierarchyLocations::iname(I, VALUESFINDER_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
		inter_symbol *ea_s = Metadata::optional_symbol(pack, I"^enumeration_array");
		if (ea_s) {
			inter_symbol *id_s = Metadata::required_symbol(pack, I"^strong_id");
			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, EQ_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, k_s);
					Produce::val_symbol(I, K_value, id_s);
				Produce::up(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, RETURN_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, ea_s);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		}
	}
	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@ |DefaultValueOfKOV(K)| returns the default value for kind |K|: it's needed,
for instance, when increasing the size of a list of $K$ to include new entries,
which have to be given some type-safe value to start out at.

@<Define DEFAULTVALUEOFKOV function@> =
	inter_name *iname = HierarchyLocations::iname(I, DEFAULTVALUEOFKOV_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *sk_s = Synoptic::local(I, I"sk", NULL);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::iname(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, sk_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
			inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
			if (Metadata::optional_symbol(pack, I"^mkdef_fn")) {
				inter_symbol *id_s = Metadata::required_symbol(pack, I"^strong_id");
				inter_symbol *mkdef_fn_s = Metadata::required_symbol(pack, I"^mkdef_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, id_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, RETURN_BIP);
						Produce::down(I);
							Produce::inv_call_symbol(I, mkdef_fn_s);
							Produce::down(I);
								Produce::val_symbol(I, K_value, sk_s);
							Produce::up(I);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
		Produce::up(I);
	Produce::up(I);
	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@ |PrintKindValuePair(K, V)| prints out the value |V|, declaring its kind to be |K|.

@<Define PRINTKINDVALUEPAIR function@> =
	inter_name *iname = HierarchyLocations::iname(I, PRINTKINDVALUEPAIR_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	inter_symbol *v_s = Synoptic::local(I, I"v", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::iname(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
			inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
			if ((Metadata::optional_symbol(pack, I"^print_fn")) &&
				(Metadata::read_optional_numeric(pack, I"^is_subkind_of_object") == FALSE)) {
				inter_symbol *id_s = Metadata::required_symbol(pack, I"^strong_id");
				inter_symbol *print_fn_s = Metadata::required_symbol(pack, I"^print_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, id_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_call_symbol(I, print_fn_s);
						Produce::down(I);
							Produce::val_symbol(I, K_value, v_s);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
			Produce::inv_primitive(I, DEFAULT_BIP);
			Produce::down(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, PRINTNUMBER_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, v_s);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);
	Synoptic::end_function(I, step, iname);

@ |KOVComparisonFunction(K)| returns either the address of a function to
perform a comparison between two values, or else 0 to signal that no
special sort of comparison is needed. (In which case signed numerical
comparison will be used.) The function |F| may be used in a sorting algorithm,
so it must have no side-effects. |F(x,y)| should return 1 if $x>y$,
0 if $x=y$ and $-1$ if $x<y$. Note that it is not permitted to return 0
unless the two values are genuinely equal.

@<Define KOVCOMPARISONFUNCTION function@> =
	inter_name *iname = HierarchyLocations::iname(I, KOVCOMPARISONFUNCTION_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::iname(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
			inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
			if (Metadata::optional_symbol(pack, I"^cmp_fn")) {
				inter_symbol *id_s = Metadata::required_symbol(pack, I"^strong_id");
				inter_symbol *cmp_fn_s = Metadata::required_symbol(pack, I"^cmp_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, id_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, RETURN_BIP);
						Produce::down(I);
							Produce::val_symbol(I, K_value, cmp_fn_s);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
		Produce::up(I);
	Produce::up(I);
	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@<Define KOVDOMAINSIZE function@> =
	inter_name *iname = HierarchyLocations::iname(I, KOVDOMAINSIZE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::iname(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
			inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_numeric(pack, I"^domain_size")) {
				inter_symbol *id_s = Metadata::required_symbol(pack, I"^strong_id");
				inter_ti domain_size = Metadata::read_numeric(pack, I"^domain_size");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, id_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, RETURN_BIP);
						Produce::down(I);
							Produce::val(I, K_value, InterValuePairs::number(domain_size));
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
		Produce::up(I);
	Produce::up(I);
	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@ |KOVIsBlockValue(k)| is true if and only if |k| is the (strong or weak) ID of
a kind storing pointers to blocks of data.

@<Define KOVISBLOCKVALUE function@> =
	inter_name *iname = HierarchyLocations::iname(I, KOVISBLOCKVALUE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);

	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::iname(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
			inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_numeric(pack, I"^has_block_values")) {
				inter_symbol *id_s = Metadata::required_symbol(pack, I"^strong_id");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, id_s);
					Produce::code(I);
					Produce::down(I);
						Produce::rtrue(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
		Produce::up(I);
	Produce::up(I);
	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@<Define I7_KIND_NAME function@> =
	inter_name *iname = HierarchyLocations::iname(I, I7_KIND_NAME_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
		inter_symbol *class_s = Metadata::optional_symbol(pack, I"^object_class");
		if (class_s) {
			text_stream *pn = Metadata::required_textual(pack, I"^printed_name");
			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, EQ_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, k_s);
					Produce::val_symbol(I, K_value, class_s);
				Produce::up(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, PRINT_BIP);
					Produce::down(I);
						Produce::val_text(I, pn);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		}
	}
	Synoptic::end_function(I, step, iname);

@ |KOVSupportFunction(K)| returns the address of the specific support function
for a pointer-value kind |K|, or returns 0 if |K| is not such a kind. For what
such a function does, see "BlockValues.i6t".

@<Define KOVSUPPORTFUNCTION function@> =
	inter_name *iname = HierarchyLocations::iname(I, KOVSUPPORTFUNCTION_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	inter_symbol *fail_s = Synoptic::local(I, I"fail", NULL);

	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::iname(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
			inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_numeric(pack, I"^has_block_values")) {
				inter_symbol *id_s = Metadata::required_symbol(pack, I"^strong_id");
				inter_symbol *support_s = Metadata::required_symbol(pack, I"^support_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, id_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, RETURN_BIP);
						Produce::down(I);
							Produce::val_symbol(I, K_value, support_s);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, IF_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, fail_s);
		Produce::code(I);
		Produce::down(I);
			Produce::inv_call_iname(I, HierarchyLocations::iname(I, BLKVALUEERROR_HL));
			Produce::down(I);
				Produce::val_symbol(I, K_value, fail_s);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);

	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@<Define SHOWMEKINDDETAILS function@> =
	inter_name *iname = HierarchyLocations::iname(I, SHOWMEKINDDETAILS_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *which_s = Synoptic::local(I, I"which", NULL);
	inter_symbol *na_s = Synoptic::local(I, I"na", NULL);
	inter_symbol *t_0_s = Synoptic::local(I, I"t_0", NULL);
	for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_object")) {
			inter_symbol *showme_s = Metadata::optional_symbol(pack, I"^showme_fn");
			if (showme_s) {
				Produce::inv_primitive(I, STORE_BIP);
				Produce::down(I);
					Produce::ref_symbol(I, K_value, na_s);
					Produce::inv_call_symbol(I, showme_s);
					Produce::down(I);
						Produce::val_symbol(I, K_value, which_s);
						Produce::val_symbol(I, K_value, na_s);
						Produce::val_symbol(I, K_value, t_0_s);
					Produce::up(I);
				Produce::up(I);
			}
		}
	}
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);		
		Produce::val_symbol(I, K_value, na_s);
	Produce::up(I);		
	Synoptic::end_function(I, step, iname);

@ This goes right back to a curious feature of Inform 1, in 1993. To enable
the use of player's holdalls, we must declare a constant |RUCKSACK_CLASS| to
tell some code in |WorldModelKit| to use possessions with this Inter class as
the rucksack pro tem. This is all a bit of a hack, and isn't really fully
general: only the player has the benefit of a "player's holdall" (hence the
name), with other actors oblivious.

@<Define RUCKSACK_CLASS constant@> =
	inter_name *iname = HierarchyLocations::iname(I, RUCKSACK_CLASS_HL);
	int found = FALSE;
	for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^rucksack_class")) {
			inter_symbol *value_s = Metadata::required_symbol(pack, I"^object_class");
			Produce::symbol_constant(I, iname, K_value, value_s);
			found = TRUE;
			break;
		}
	}
	if (found == FALSE) Produce::numeric_constant(I, iname, K_value, 0);

@ The kind inheritance tree is represented by an array providing metadata on
the kinds of object: there are just two words per kind -- the class, then
the instance count for its own kind. For instance, "door" is usually
kind number 4, so it occupies record 4 in this array -- words 8 and 9. Word
8 will be |K4_door|, and word 9 will be the number 2, meaning kind number 2,
"thing". This tells us that a door is a kind of thing.

@<Define KINDHIERARCHY array@> =
	linked_list *L = NEW_LINKED_LIST(inter_symbol);
	for (int i=0; i<InterNodeList::array_len(inv->kind_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->kind_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_subkind_of_object")) {
			inter_symbol *kind_name = Metadata::required_symbol(pack, I"^object_class");
			ADD_TO_LINKED_LIST(kind_name, inter_symbol, L);
		}
	}
	
	linked_list *ordered_L = NEW_LINKED_LIST(inter_symbol);
	CodeGen::sort_symbol_list(ordered_L, L, CodeGen::in_source_md_order);
	int i = 1;
	inter_symbol *kind_name;
	LOOP_OVER_LINKED_LIST(kind_name, inter_symbol, ordered_L)
		SymbolAnnotation::set_i(kind_name, OBJECT_KIND_COUNTER_IANN, (inter_ti) i++);

	inter_name *iname = HierarchyLocations::iname(I, KINDHIERARCHY_HL);
	Synoptic::begin_array(I, step, iname);
	if (LinkedLists::len(L) > 0) {
		Synoptic::symbol_entry(RunningPipelines::get_symbol(step, object_kind_RPSYM));
		Synoptic::numeric_entry(0);
		inter_symbol *kind_name;
		LOOP_OVER_LINKED_LIST(kind_name, inter_symbol, ordered_L) {
			Synoptic::symbol_entry(kind_name);
			inter_symbol *super_name = TypenameInstruction::super(kind_name);
			if ((super_name) &&
				(super_name != RunningPipelines::get_symbol(step, object_kind_RPSYM))) {
				Synoptic::numeric_entry(SynopticKinds::kind_of_object_count(step, super_name));
			} else {
				Synoptic::numeric_entry(0);
			}
		}
	} else {
		Synoptic::numeric_entry(0);
		Synoptic::numeric_entry(0);
	}
	Synoptic::end_array(I);

@

=
inter_ti SynopticKinds::kind_of_object_count(pipeline_step *step, inter_symbol *kind_name) {
	if ((kind_name == NULL) ||
		(kind_name == RunningPipelines::get_symbol(step, object_kind_RPSYM))) return 0;
	int N = SymbolAnnotation::get_i(kind_name, OBJECT_KIND_COUNTER_IANN);
	if (N >= 0) return (inter_ti) N;
	return 0;
}
