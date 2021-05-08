[SynopticKinds::] Kinds.

To compile the main/synoptic/kinds submodule.

@ Before this runs, kind packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |kind_nodes|
of packages of type |_kind|, and similarly for |derived_kind_nodes|.

=
void SynopticKinds::compile(inter_tree *I, tree_inventory *inv) {
	if (TreeLists::len(inv->kind_nodes) > 0) {
		TreeLists::sort(inv->kind_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
			inter_symbol *weak_s = Metadata::read_optional_symbol(pack, I"^weak_id");
			if (weak_s) Inter::Symbols::set_int(weak_s, i+2);
		}
	}
	if (TreeLists::len(inv->derived_kind_nodes) > 0) {
		TreeLists::sort(inv->derived_kind_nodes, Synoptic::module_order);
	}
	@<Define BASE_KIND_HWM@>;	
	@<Define DEFAULTVALUEFINDER function@>;
	@<Define DEFAULTVALUEOFKOV function@>;
	@<Define PRINTKINDVALUEPAIR function@>;
	@<Define KOVCOMPARISONFUNCTION function@>;
	@<Define KOVDOMAINSIZE function@>;
	@<Define KOVISBLOCKVALUE function@>;
	@<Define I7_KIND_NAME function@>;
	@<Define KOVSUPPORTFUNCTION function@>;
	@<Define SHOWMEKINDDETAILS function@>;
}

@<Define BASE_KIND_HWM@> =
	inter_name *iname = HierarchyLocations::find(I, BASE_KIND_HWM_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) (TreeLists::len(inv->kind_nodes) + 2));

@<Define DEFAULTVALUEFINDER function@> =
	inter_name *iname = HierarchyLocations::find(I, DEFAULTVALUEFINDER_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	for (int i=0; i<TreeLists::len(inv->derived_kind_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->derived_kind_nodes->list[i].node);
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
	Synoptic::end_function(I, iname);

@ |DefaultValueOfKOV(K)| returns the default value for kind |K|: it's needed,
for instance, when increasing the size of a list of $K$ to include new entries,
which have to be given some type-safe value to start out at.

@<Define DEFAULTVALUEOFKOV function@> =
	inter_name *iname = HierarchyLocations::find(I, DEFAULTVALUEOFKOV_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *sk_s = Synoptic::local(I, I"sk", NULL);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::find(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, sk_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_symbol(pack, I"^mkdef_fn")) {
				inter_symbol *weak_s = Metadata::read_symbol(pack, I"^weak_id");
				inter_symbol *mkdef_fn_s = Metadata::read_symbol(pack, I"^mkdef_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, weak_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, RETURN_BIP);
						Produce::down(I);
							Produce::inv_call(I, mkdef_fn_s);
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
	Synoptic::end_function(I, iname);

@ |PrintKindValuePair(K, V)| prints out the value |V|, declaring its kind to be |K|.

@<Define PRINTKINDVALUEPAIR function@> =
	inter_name *iname = HierarchyLocations::find(I, PRINTKINDVALUEPAIR_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	inter_symbol *v_s = Synoptic::local(I, I"v", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::find(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
			if ((Metadata::read_optional_numeric(pack, I"^is_base")) &&
				(Metadata::read_optional_symbol(pack, I"^print_fn")) &&
				(Metadata::read_optional_numeric(pack, I"^is_subkind_of_object") == FALSE)) {
				inter_symbol *weak_s = Metadata::read_symbol(pack, I"^weak_id");
				inter_symbol *print_fn_s = Metadata::read_symbol(pack, I"^print_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, weak_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_call(I, print_fn_s);
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
					Produce::inv_primitive(I, PRINT_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, v_s);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);
	Synoptic::end_function(I, iname);

@ |KOVComparisonFunction(K)| returns either the address of a function to
perform a comparison between two values, or else 0 to signal that no
special sort of comparison is needed. (In which case signed numerical
comparison will be used.) The function |F| may be used in a sorting algorithm,
so it must have no side-effects. |F(x,y)| should return 1 if $x>y$,
0 if $x=y$ and $-1$ if $x<y$. Note that it is not permitted to return 0
unless the two values are genuinely equal.

@<Define KOVCOMPARISONFUNCTION function@> =
	inter_name *iname = HierarchyLocations::find(I, KOVCOMPARISONFUNCTION_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::find(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_symbol(pack, I"^cmp_fn")) {
				inter_symbol *weak_s = Metadata::read_symbol(pack, I"^weak_id");
				inter_symbol *cmp_fn_s = Metadata::read_symbol(pack, I"^cmp_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, weak_s);
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
	Synoptic::end_function(I, iname);

@<Define KOVDOMAINSIZE function@> =
	inter_name *iname = HierarchyLocations::find(I, KOVDOMAINSIZE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::find(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_numeric(pack, I"^domain_size")) {
				inter_symbol *weak_s = Metadata::read_symbol(pack, I"^weak_id");
				inter_ti domain_size = Metadata::read_numeric(pack, I"^domain_size");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, weak_s);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, RETURN_BIP);
						Produce::down(I);
							Produce::val(I, K_value, LITERAL_IVAL, domain_size);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
		Produce::up(I);
	Produce::up(I);
	Produce::rfalse(I);
	Synoptic::end_function(I, iname);

@ |KOVIsBlockValue(k)| is true if and only if |k| is the (strong or weak) ID of
a kind storing pointers to blocks of data.

@<Define KOVISBLOCKVALUE function@> =
	inter_name *iname = HierarchyLocations::find(I, KOVISBLOCKVALUE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);

	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::find(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_numeric(pack, I"^has_block_values")) {
				inter_symbol *weak_s = Metadata::read_symbol(pack, I"^weak_id");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, weak_s);
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
	Synoptic::end_function(I, iname);

@<Define I7_KIND_NAME function@> =
	inter_name *iname = HierarchyLocations::find(I, I7_KIND_NAME_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
		inter_symbol *class_s = Metadata::read_optional_symbol(pack, I"^object_class");
		if (class_s) {
			text_stream *pn = Metadata::read_textual(pack, I"^printed_name");
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
	Synoptic::end_function(I, iname);

@ |KOVSupportFunction(K)| returns the address of the specific support function
for a pointer-value kind |K|, or returns 0 if |K| is not such a kind. For what
such a function does, see "BlockValues.i6t".

@<Define KOVSUPPORTFUNCTION function@> =
	inter_name *iname = HierarchyLocations::find(I, KOVSUPPORTFUNCTION_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *k_s = Synoptic::local(I, I"k", NULL);
	inter_symbol *fail_s = Synoptic::local(I, I"fail", NULL);

	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call_iname(I, HierarchyLocations::find(I, KINDATOMIC_HL));
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
			if (Metadata::read_optional_numeric(pack, I"^has_block_values")) {
				inter_symbol *weak_s = Metadata::read_symbol(pack, I"^weak_id");
				inter_symbol *support_s = Metadata::read_symbol(pack, I"^support_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, weak_s);
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
			Produce::inv_call_iname(I, HierarchyLocations::find(I, BLKVALUEERROR_HL));
			Produce::down(I);
				Produce::val_symbol(I, K_value, fail_s);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);

	Produce::rfalse(I);
	Synoptic::end_function(I, iname);

@<Define SHOWMEKINDDETAILS function@> =
	inter_name *iname = HierarchyLocations::find(I, SHOWMEKINDDETAILS_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *which_s = Synoptic::local(I, I"which", NULL);
	inter_symbol *na_s = Synoptic::local(I, I"na", NULL);
	inter_symbol *t_0_s = Synoptic::local(I, I"t_0", NULL);
	for (int i=0; i<TreeLists::len(inv->kind_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->kind_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_object")) {
			inter_symbol *showme_s = Metadata::read_optional_symbol(pack, I"^showme_fn");
			if (showme_s) {
				Produce::inv_primitive(I, STORE_BIP);
				Produce::down(I);
					Produce::ref_symbol(I, K_value, na_s);
					Produce::inv_call(I, showme_s);
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
	Synoptic::end_function(I, iname);
