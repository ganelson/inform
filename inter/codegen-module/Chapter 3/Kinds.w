[SynopticKinds::] Kinds.

To construct suitable functions and arrays.

@ Before this runs, kind packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |kind_nodes|
of packages of type |_kind|.

=
void SynopticKinds::renumber(inter_tree *I) {
	if (TreeLists::len(kind_nodes) > 0) {
		TreeLists::sort(kind_nodes, Synoptic::module_order);
//		for (int i=0; i<TreeLists::len(kind_nodes); i++) {
//			inter_package *pack = Inter::Package::defined_by_frame(kind_nodes->list[i].node);
//			inter_tree_node *D = Synoptic::get_definition(pack, I"property_id");
//			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
//		}
	}
}

@ There are also resources to create in the |synoptic| module:

@e BASE_KIND_HWM_SYNID
@e DEFAULTVALUEOFKOV_SYNID
@e DEFAULTVALUEFINDER_SYNID
@e PRINTKINDVALUEPAIR_SYNID
@e KOVCOMPARISONFUNCTION_SYNID
@e KOVDOMAINSIZE_SYNID
@e KOVISBLOCKVALUE_SYNID
@e I7_KIND_NAME_SYNID
@e KOVSUPPORTFUNCTION_SYNID
@e SHOWMEKINDDETAILS_SYNID

=
int SynopticKinds::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case BASE_KIND_HWM_SYNID:
			break;
		case DEFAULTVALUEOFKOV_SYNID:
			break;
		case DEFAULTVALUEFINDER_SYNID:
			break;
		case PRINTKINDVALUEPAIR_SYNID:
			break;
		case KOVCOMPARISONFUNCTION_SYNID:
			break;
		case KOVDOMAINSIZE_SYNID:
			break;
		case KOVISBLOCKVALUE_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the KOVISBLOCKVALUE function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case I7_KIND_NAME_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the I7_KIND_NAME function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case KOVSUPPORTFUNCTION_SYNID:
			break;
		case SHOWMEKINDDETAILS_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the SHOWMEKINDDETAILS function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@ |KOVIsBlockValue(k)| is true if and only if |k| is the (strong or weak) ID of
a kind storing pointers to blocks of data.

@<Add a body of code to the KOVISBLOCKVALUE function@> =
	inter_symbol *k_s = Synoptic::get_local(I, I"k");
	inter_symbol *ka_s = Synoptic::get_local(I, I"ka");

	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, k_s);
		Produce::inv_call(I, ka_s);
		Produce::down(I);
			Produce::val_symbol(I, K_value, k_s);
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, k_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(kind_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(kind_nodes->list[i].node);
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

@<Add a body of code to the I7_KIND_NAME function@> =
	inter_symbol *k_s = Synoptic::get_local(I, I"k");
	for (int i=0; i<TreeLists::len(kind_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(kind_nodes->list[i].node);
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

@<Add a body of code to the SHOWMEKINDDETAILS function@> =
	inter_symbol *which_s = Synoptic::get_local(I, I"which");
	for (int i=0; i<TreeLists::len(kind_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(kind_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_object")) {
			inter_symbol *showme_s = Metadata::read_symbol(pack, I"^showme_fn");
			Produce::inv_call(I, showme_s);
			Produce::down(I);
				Produce::val_symbol(I, K_value, which_s);
			Produce::up(I);
		}
	}
