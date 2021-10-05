[VanillaObjects::] Vanilla Objects.

How the vanilla code generation strategy handles instances, kinds, and properties.

@h Properties.
Early in code-generation, we declare the properties. This entails some housekeeping,
putting together lists of kinds and instances as well.

=
void VanillaObjects::declare_properties(code_generation *gen) {
	gen->kinds_in_source_order =
		VanillaObjects::sorted_array(gen->kinds, VanillaObjects::in_source_order);
	gen->kinds_in_declaration_order =
		VanillaObjects::sorted_array(gen->kinds, VanillaObjects::in_declaration_order);
	gen->instances_in_declaration_order =
		VanillaObjects::sorted_array(gen->instances, VanillaObjects::in_declaration_order);
	if (LinkedLists::len(gen->unassimilated_properties) > 0)
		@<Declare and allocate properties@>;
	@<Mark the kinds which can have properties@>;
}

@ =
inter_symbol **VanillaObjects::sorted_array(linked_list *L,
	int (*sorter)(const void *elem1, const void *elem2)) {
	int N = LinkedLists::len(L);
	inter_symbol **array = NULL;
	if (N > 0) {
		array = (inter_symbol **)
			(Memory::calloc(N, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
		int i=0;
		inter_symbol *sym;
		LOOP_OVER_LINKED_LIST(sym, inter_symbol, L) array[i++] = sym;
		qsort(array, (size_t) N, sizeof(inter_symbol *), sorter);
	}
	return array;
}

int VanillaObjects::in_source_order(const void *elem1, const void *elem2) {
	return VanillaObjects::in_annotation_order(elem1, elem2, SOURCE_ORDER_IANN);
}
int VanillaObjects::in_declaration_order(const void *elem1, const void *elem2) {
	return VanillaObjects::in_annotation_order(elem1, elem2, DECLARATION_ORDER_IANN);
}
int VanillaObjects::in_annotation_order(const void *elem1, const void *elem2, inter_ti annot) {
	const inter_symbol **e1 = (const inter_symbol **) elem1;
	const inter_symbol **e2 = (const inter_symbol **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting kinds");
	int s1 = VanillaObjects::sequence_number(*e1, annot);
	int s2 = VanillaObjects::sequence_number(*e2, annot);
	if (s1 != s2) return s1-s2;
	return Inter::Symbols::sort_number(*e1) - Inter::Symbols::sort_number(*e2);
}
int VanillaObjects::sequence_number(const inter_symbol *kind_name, inter_ti annot) {
	int N = Inter::Symbols::read_annotation(kind_name, annot);
	if (N >= 0) return N;
	return 100000000;
}

@<Declare and allocate properties@> =
	dictionary *i6dps_dict = Dictionaries::new(1024, FALSE); /* of |inter_symbol| */
	dictionary *pre_i6dps_dict = Dictionaries::new(1024, FALSE); /* of |inter_symbol| */
	dictionary *lists = Dictionaries::new(1024, FALSE); /* of |linked_list| of |inter_symbol| */

	inter_symbol *prop_name;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->assimilated_properties)
		@<Group the properties by their unmangled identifier names@>;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->unassimilated_properties)
		@<Group the properties by their unmangled identifier names@>;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->assimilated_properties)
		@<Declare one property for each name group@>;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->unassimilated_properties)
		@<Declare one property for each name group@>;

@<Group the properties by their unmangled identifier names@> =
	dictionary *D = pre_i6dps_dict;
	dictionary *D2 = lists;
	text_stream *name = Inter::Symbols::name(prop_name);
	if (Dictionaries::find(D, name) == NULL) {
		text_stream *inner_name = Str::duplicate(name);
		Dictionaries::create(D, inner_name);
		Dictionaries::write_value(D, inner_name, (void *) prop_name);
		linked_list *L = NEW_LINKED_LIST(inter_symbol);
		ADD_TO_LINKED_LIST(prop_name, inter_symbol, L);
		Dictionaries::create(D2, inner_name);
		Dictionaries::write_value(D2, inner_name, (void *) L);
	} else {
		Dictionaries::write_value(D, name, (void *) prop_name);
		linked_list *L = Dictionaries::read_value(D2, name);
		ADD_TO_LINKED_LIST(prop_name, inter_symbol, L);
	}

@<Declare one property for each name group@> =
	dictionary *D = i6dps_dict;
	text_stream *name = Inter::Symbols::name(prop_name);
	if (Dictionaries::find(D, name) == NULL) {
		LOGIF(PROPERTY_ALLOCATION, "! NEW name=%S   sname=%S   eor=%d   assim=%d\n",
			name, prop_name->symbol_name,
			Inter::Symbols::read_annotation(prop_name, EITHER_OR_IANN),
			Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN));
		text_stream *inner_name = Str::duplicate(name);
		Dictionaries::create(D, inner_name);
		Dictionaries::write_value(D, inner_name, (void *) prop_name);
		
		text_stream *array_name = Str::new();
		WRITE_TO(array_name, "A_%S", inner_name);

		Inter::Symbols::set_translate(prop_name, array_name);
		Inter::Symbols::annotate_t(gen->from, prop_name->owning_table->owning_package,
			prop_name, INNER_PROPERTY_NAME_IANN, inner_name);

		linked_list *all_forms = (linked_list *) Dictionaries::read_value(lists, name);

		segmentation_pos saved;
		Generators::begin_array(gen, array_name, prop_name, NULL, WORD_ARRAY_FORMAT, &saved);
		Generators::declare_property(gen, prop_name, all_forms);
		if (Inter::Symbols::read_annotation(prop_name, EITHER_OR_IANN))
			Generators::array_entry(gen, I"1", WORD_ARRAY_FORMAT);
		else
			Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
		@<Do permissions@>;
		Generators::end_array(gen, WORD_ARRAY_FORMAT, &saved);
	} else {
		LOGIF(PROPERTY_ALLOCATION, "! OLD name=%S   sname=%S   eor=%d   assim=%d\n",
			name, prop_name->symbol_name,
			Inter::Symbols::read_annotation(prop_name, EITHER_OR_IANN),
			Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN));
		inter_symbol *existing_prop_name = 
			(inter_symbol *) Dictionaries::read_value(D, name);
		Inter::Symbols::set_translate(prop_name, Inter::Symbols::name(existing_prop_name));
		text_stream *inner_name = I"<nameless>";
		int N = Inter::Symbols::read_annotation(existing_prop_name, INNER_PROPERTY_NAME_IANN);
		if (N > 0) inner_name = Inter::Warehouse::get_text(InterTree::warehouse(gen->from), (inter_ti) N);
		Inter::Symbols::annotate_t(gen->from, prop_name->owning_table->owning_package,
			prop_name, INNER_PROPERTY_NAME_IANN, inner_name);
	}
	LOGIF(PROPERTY_ALLOCATION, "! SO  %S --> %S\n",
		Inter::Symbols::name(prop_name), VanillaObjects::inner_property_name(gen, prop_name));

@<Do permissions@> =
	inter_symbol *prop_name = 
		(inter_symbol *) Dictionaries::read_value(pre_i6dps_dict, name);
	int pos = 0; inter_tree *I = gen->from;
	@<Write the property name in double quotes@>;
	@<Write a list of kinds or objects which are permitted to have this property@>;
	Generators::mangled_array_entry(gen, I"NULL", WORD_ARRAY_FORMAT);

@ The following lets the run-time environment know what properties are
called, and which kinds of object are allowed to have them. This might look
a little odd: why does the run-time code need to know any of that?

The answer is that the Inform compiler will prevent grossly type-unsafe
property accesses at compile time -- for example, asking if a number is
"recurring" (an either/or property of scenes), which can be ruled out
because numbers and scenes are wholly disjoint as values. But it will allow
any object property of any object to be accessed, because it's not usually
possible for the typechecker to know if an object value |O| is a vehicle, a
direction, and so on. So the finer access controls for properties of
objects are left until run-time (whereas no such regime is needed for
properties of values). To make this possible, we need to tell the run-time
code what is and is not allowed.

@<Write the property name in double quotes@> =
	text_stream *pname = I"<nameless>";
	int N = Inter::Symbols::read_annotation(prop_name, PROPERTY_NAME_IANN);
	if (N > 0) pname = Inter::Warehouse::get_text(InterTree::warehouse(I), (inter_ti) N);
	TEMPORARY_TEXT(entry)
	CodeGen::select_temporary(gen, entry);
	Generators::compile_literal_text(gen, pname, TRUE);
	CodeGen::deselect_temporary(gen);
	Generators::array_entry(gen, entry, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(entry)
	pos++;

@ A complete list here would be wasteful both of space and run-time
checking time, but we only need a list $O_1, O_2, ..., O_k$ such that for
each $W$ allowed to have the property, either $W = O_i$ for some $i$, or
$W$ is of kind $O_i$ for some $i$ (perhaps indirectly).

In a tricksy complication, we need to allow for the possibility that two
or more different I7 properties are actually equal at run-time. This wouldn't
happen by itself, but does happen if two different properties are translated
to the same I6 property, and in fact the template does this: "lighted" and
"lit" both translate to I6 |light|. The only way to reconcile this is to
make the list a union of the lists of both. This does mean the routine
runs in $O(P^2N)$ time, where $P$ is the number of properties and $N$ the
number of objects, but we can live with that. $P$ does not in practice rise
linearly with the size of the source text, even though $N$ does.

@<Write a list of kinds or objects which are permitted to have this property@> =
	inter_symbol *eprop_name;
	LOOP_OVER_LINKED_LIST(eprop_name, inter_symbol, gen->unassimilated_properties) {
		if (Str::eq(Inter::Symbols::name(eprop_name), Inter::Symbols::name(prop_name))) {
			inter_node_list *EVL =
				Inter::Warehouse::get_frame_list(InterTree::warehouse(I),
					Inter::Property::permissions_list(eprop_name));

			@<List any O with an explicit permission@>;
			@<List all top-level kinds if "object" itself has an explicit permission@>;
		}
	}

@<List any O with an explicit permission@> =
	for (int k=0; k<LinkedLists::len(gen->kinds); k++) {
		inter_symbol *kind_name = gen->kinds_in_source_order[k];
		if (VanillaObjects::is_kind_of_object(kind_name)) {
			inter_tree_node *X;
			LOOP_THROUGH_INTER_NODE_LIST(X, EVL) {
				inter_symbol *owner_name =
					InterSymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				if (owner_name == kind_name) {
					Generators::mangled_array_entry(gen, Inter::Symbols::name(kind_name), WORD_ARRAY_FORMAT);
					pos++;
				}
			}
		}
	}
	for (int in=0; in<LinkedLists::len(gen->instances); in++) {
		inter_symbol *inst_name = gen->instances_in_declaration_order[in];
		if (VanillaObjects::is_kind_of_object(Inter::Instance::kind_of(inst_name))) {
			inter_tree_node *X;
			LOOP_THROUGH_INTER_NODE_LIST(X, EVL) {
				inter_symbol *owner_name =
					InterSymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				if (owner_name == inst_name) {
					Generators::mangled_array_entry(gen, Inter::Symbols::name(inst_name), WORD_ARRAY_FORMAT);
					pos++;
				}
			}
		}
	}

@<List all top-level kinds if "object" itself has an explicit permission@> =
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, EVL) {
		inter_symbol *owner_name =
			InterSymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
		if (owner_name == object_kind_symbol) {
			Generators::mangled_array_entry(gen, I"K0_kind", WORD_ARRAY_FORMAT);
			pos++;
			for (int k=0; k<LinkedLists::len(gen->kinds); k++) {
				inter_symbol *kind_name = gen->kinds_in_source_order[k];
				if (Inter::Kind::super(kind_name) == object_kind_symbol) {
					Generators::mangled_array_entry(gen, Inter::Symbols::name(kind_name), WORD_ARRAY_FORMAT);
					pos++;
				}
			}
		}
	}

@<Mark the kinds which can have properties@> =
	inter_tree *I = gen->from;
	inter_symbol *kind_name;
	LOOP_OVER_LINKED_LIST(kind_name, inter_symbol, gen->kinds) {
		if (VanillaObjects::is_kind_of_object(kind_name)) continue;
		if (kind_name == object_kind_symbol) continue;
		if (kind_name == unchecked_kind_symbol) continue;
		int mark_me = FALSE;
		inter_node_list *FL =
			Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Kind::permissions_list(kind_name));
		if (FL->first_in_inl) mark_me = TRUE;
		else for (int in=0; in<LinkedLists::len(gen->instances); in++) {
			inter_symbol *inst_name = gen->instances_in_declaration_order[in];
			if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
				inter_node_list *FL =
					Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Instance::permissions_list(inst_name));
				if (FL->first_in_inl) mark_me = TRUE;
			}
		}
		if (mark_me) Inter::Symbols::set_flag(kind_name, KIND_WITH_PROPS_MARK_BIT);
	}

@h Instances and kinds.

=
void VanillaObjects::generate(code_generation *gen) {
	inter_tree *I = gen->from;

	if (LinkedLists::len(gen->unassimilated_properties) > 0) {
		@<Write Value Property Holder objects for each kind of value instance@>;
	}

	@<Annotate kinds of object with a sequence counter@>;
	@<Write the KindHierarchy array@>;
	@<Write an I6 Class definition for each kind of object@>;
	@<Write an I6 Object definition for each object instance@>;
}

@<Annotate kinds of object with a sequence counter@> =
	inter_ti c = 1;
	for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
		inter_symbol *kind_name = gen->kinds_in_source_order[i];
		if (VanillaObjects::is_kind_of_object(kind_name))
			Inter::Symbols::annotate_i(kind_name, OBJECT_KIND_COUNTER_IANN,  c++);
	}

@h The kind inheritance tree.
We begin with an array providing metadata on the kinds of object: there
are just two words per kind -- the Inform 6 class corresponding to the kind,
then the instance count for its own kind. For instance, "door" is usually
kind number 4, so it occupies record 4 in this array -- words 8 and 9. Word
8 will be |K4_door|, the Inform 6 class for doors, and word 9 will be the
number 2, meaning kind number 2, "thing". This tells us that a door is
a kind of thing. In this way, we store the hierarchy of |N| kinds in |2N|
words of memory; it's needed at run-time for checking dynamically that
property usage is legal.

@<Write the KindHierarchy array@> =
	int no_kos = 0;
	for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
		inter_symbol *kind_name = gen->kinds_in_source_order[i];
		if (VanillaObjects::is_kind_of_object(kind_name)) no_kos++;
	}

	segmentation_pos saved;
	Generators::begin_array(gen, I"KindHierarchy", NULL, NULL, WORD_ARRAY_FORMAT, &saved);
	if (no_kos > 0) {
		Generators::mangled_array_entry(gen, I"K0_kind", WORD_ARRAY_FORMAT);
		Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
		for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
			inter_symbol *kind_name = gen->kinds_in_source_order[i];
			if (VanillaObjects::is_kind_of_object(kind_name)) {
				inter_symbol *super_name = Inter::Kind::super(kind_name);
				Generators::mangled_array_entry(gen, Inter::Symbols::name(kind_name), WORD_ARRAY_FORMAT);
				if ((super_name) && (super_name != object_kind_symbol)) {
					TEMPORARY_TEXT(N);
					WRITE_TO(N, "%d", VanillaObjects::kind_of_object_count(super_name));
					Generators::array_entry(gen, N, WORD_ARRAY_FORMAT);
					DISCARD_TEXT(N);
				} else {
					Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
				}
			}
		}
	} else {
		Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
		Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
	}
	Generators::end_array(gen, WORD_ARRAY_FORMAT, &saved);

@h Lookup mechanism for properties of value instances.
As noted above, if |K| is a kind which can have properties but is not a subkind
of object, then a property for instances of |K| is stored in an array called
a "stick". At run-time, given the property number and |K|, we will need to find
where in memory the correct stick is, and this needs to be quick.

This is essentially a dictionary lookup problem and we solve it by compiling
a faux object |V| for each |K|, called a "value property holder" or VPH.
Given |K| we find |V| by looking it up in the array |value_property_holders|.

Once we know |V|, we then look up |V.P| to get the address of the stick for
property |P|, something which the virtual machine can do quickly.

This comes at the cost of several hundred bytes of overhead, which we don't
take lightly in the Z-machine. But speed and flexibility are worth more.

@<Write Value Property Holder objects for each kind of value instance@> =
	linked_list *stick_list = NEW_LINKED_LIST(kov_value_stick);
	inter_symbol *max_weak_id = InterSymbolsTables::url_name_to_symbol(I, NULL, 
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = Inter::Symbols::evaluate_to_int(max_weak_id);
		if (M != 0) {
			for (int w=1; w<M; w++) {
				for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
					inter_symbol *kind_name = gen->kinds_in_source_order[i];
					if (VanillaObjects::weak_id(kind_name) == w) {
						if (Inter::Symbols::get_flag(kind_name, KIND_WITH_PROPS_MARK_BIT)) {
							TEMPORARY_TEXT(instance_name)
							WRITE_TO(instance_name, "VPH_%d", w);
							segmentation_pos saved;
							Generators::declare_instance(gen, I"Object", instance_name, NULL, -1, FALSE, &saved);
							inter_symbol *prop_name;
							LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->unassimilated_properties)
								CodeGen::unmark(prop_name);
							inter_node_list *FL =
								Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Kind::permissions_list(kind_name));
							@<Work through this frame list of permissions@>;
							for (int in=0; in<LinkedLists::len(gen->instances); in++) {
								inter_symbol *inst_name = gen->instances_in_declaration_order[in];
								if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
									inter_node_list *FL =
										Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Instance::permissions_list(inst_name));
									@<Work through this frame list of permissions@>;
								}
							}
							Generators::end_instance(gen, I"Object", instance_name, saved);
							DISCARD_TEXT(instance_name)
						}
					}
				}
			}
		}
	}
	@<Compile the property stick arrays@>;

@<Work through this frame list of permissions@> =
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
		inter_symbol *prop_name = InterSymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
		if (prop_name == NULL) internal_error("no property");
		if (CodeGen::marked(prop_name) == FALSE) {
			CodeGen::mark(prop_name);
			if (X->W.data[STORAGE_PERM_IFLD]) {
				inter_symbol *store = InterSymbolsTables::symbol_from_frame_data(X, STORAGE_PERM_IFLD);
				if (store == NULL) internal_error("bad PP in inter");
				Generators::assign_mangled_property(gen, prop_name, Inter::Symbols::name(store));
			} else {
				TEMPORARY_TEXT(ident)
				kov_value_stick *kvs = CREATE(kov_value_stick);
				kvs->identifier = Str::new();
				WRITE_TO(kvs->identifier, "KOVP_%d_P%d", w, VanillaObjects::pnum(prop_name));
				kvs->prop = prop_name;
				kvs->kind_name = kind_name;
				kvs->node = X;
				ADD_TO_LINKED_LIST(kvs, kov_value_stick, stick_list);
				Generators::assign_mangled_property(gen, prop_name, kvs->identifier);
				DISCARD_TEXT(ident)
			}
		}
	}

@<Compile the property stick arrays@> =
	kov_value_stick *kvs;
	LOOP_OVER_LINKED_LIST(kvs, kov_value_stick, stick_list) {
		inter_symbol *prop_name = kvs->prop;
		inter_symbol *kind_name = kvs->kind_name;
		text_stream *ident = kvs->identifier;
		inter_tree_node *X = kvs->node;
		@<Compile a stick of property values and put its address here@>;
	}

@ These little arrays are sticks of property values, and they are laid out
as if they were column arrays in a Table data structure. This means they must
be |table| arrays (which wastes one word of memory) and must have blanked-out
table column header words at the front (which wastes a further |COL_HSIZE|
words). But the cost is a simple overhead, not rising with the number of
instances, and it's a small price for the gain in simplicity and speed.

The entries here are bracketed to avoid the Inform 6 syntax ambiguity between
|4 -5| (two entries, four followed by minus five) and |4-5| (one entry, just
minus one). Inform 6 always uses the second interpretation, so just in case
there are negative literal integers in these array entries, we use
brackets: thus |(4) (-5)|. This cannot be confused with function calling
because I6 doesn't allow function calls in a constant context.

@<Compile a stick of property values and put its address here@> =
	segmentation_pos saved;
	Generators::begin_array(gen, ident, NULL, NULL, TABLE_ARRAY_FORMAT, &saved);
	Generators::array_entry(gen, I"0", TABLE_ARRAY_FORMAT);
	Generators::array_entry(gen, I"0", TABLE_ARRAY_FORMAT);
	for (int j=0; j<LinkedLists::len(gen->instances); j++) {
		inter_symbol *inst_name = gen->instances_in_declaration_order[j];
		if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
			int found = 0;
			inter_node_list *PVL =
				Inode::ID_to_frame_list(X,
					Inter::Instance::properties_list(inst_name));
			@<Work through this frame list of values@>;
			PVL = Inode::ID_to_frame_list(X,
					Inter::Kind::properties_list(kind_name));
			@<Work through this frame list of values@>;
			if (found == 0) Generators::array_entry(gen, I"0", TABLE_ARRAY_FORMAT);
		}
	}
	Generators::end_array(gen, TABLE_ARRAY_FORMAT, &saved);

@<Work through this frame list of values@> =
	inter_tree_node *Y;
	LOOP_THROUGH_INTER_NODE_LIST(Y, PVL) {
		inter_symbol *p_name = InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(Y), Y->W.data[PROP_PVAL_IFLD]);
		if ((p_name == prop_name) && (found == 0)) {
			found = 1;
			inter_ti v1 = Y->W.data[DVAL1_PVAL_IFLD];
			inter_ti v2 = Y->W.data[DVAL2_PVAL_IFLD];
			TEMPORARY_TEXT(val)
			CodeGen::select_temporary(gen, val);
			CodeGen::pair(gen, Y, v1, v2);
			CodeGen::deselect_temporary(gen);
			Generators::array_entry(gen, val, TABLE_ARRAY_FORMAT);
			DISCARD_TEXT(val)
		}
	}

@<Write an I6 Class definition for each kind of object@> =
	for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
		inter_symbol *kind_name = gen->kinds_in_declaration_order[i];
		if ((kind_name == object_kind_symbol) ||
			(VanillaObjects::is_kind_of_object(kind_name))) {
			text_stream *super_class = NULL;
			inter_symbol *super_name = Inter::Kind::super(kind_name);
			if (super_name) super_class = Inter::Symbols::name(super_name);
			segmentation_pos saved;
			Generators::declare_class(gen, Inter::Symbols::name(kind_name), Metadata::read_optional_textual(Inter::Packages::container(kind_name->definition), I"^printed_name"), super_class, &saved);
			VanillaObjects::append(gen, kind_name);
			inter_node_list *FL =
				Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Kind::properties_list(kind_name));
			VanillaObjects::plist(gen, FL);
			Generators::end_class(gen, Inter::Symbols::name(kind_name), saved);
		}
	}

@<Write an I6 Object definition for each object instance@> =
	for (int i=0; i<LinkedLists::len(gen->instances); i++) {
		inter_symbol *inst_name = gen->instances_in_declaration_order[i];
		inter_tree_node *D = Inter::Symbols::definition(inst_name);
		VanillaObjects::instance(gen, D);
	}

@ =
int VanillaObjects::pnum(inter_symbol *prop_name) {
	int N = Inter::Symbols::read_annotation(prop_name, SOURCE_ORDER_IANN);
	if (N >= 0) return N;
	return 0;
}

int VanillaObjects::weak_id(inter_symbol *kind_name) {
	inter_package *pack = Inter::Packages::container(kind_name->definition);
	inter_symbol *weak_s = Metadata::read_optional_symbol(pack, I"^weak_id");
	int alt_N = -1;
	if (weak_s) alt_N = Inter::Symbols::evaluate_to_int(weak_s);
	if (alt_N >= 0) return alt_N;
	return 0;
}



@ For the I6 header syntax, see the DM4. Note that the "hardwired" short
name is intentionally made blank: we always use I6's |short_name| property
instead. I7's spatial plugin, if loaded (as it usually is), will have
annotated the Inter symbol for the object with an arrow count, that is,
a measure of its spatial depth. This we translate into I6 arrow notation.
If the spatial plugin wasn't loaded then we have no notion of containment,
all arrow counts are 0, and we define a flat sequence of free-standing objects.

One last oddball thing is that direction objects have to be compiled in I6
as if they were spatially inside a special object called |Compass|. This doesn't
really make much conceptual sense, and I7 dropped the idea -- it has no
"compass".

=
@ =
int VanillaObjects::is_kind_of_object(inter_symbol *kind_name) {
	if (kind_name == object_kind_symbol) return FALSE;
	inter_data_type *idt = Inter::Kind::data_type(kind_name);
	if (idt == unchecked_idt) return FALSE;
	if (Inter::Kind::is_a(kind_name, object_kind_symbol)) return TRUE;
	return FALSE;
}

@ Counting kinds of object, not very quickly:

=
inter_ti VanillaObjects::kind_of_object_count(inter_symbol *kind_name) {
	if ((kind_name == NULL) || (kind_name == object_kind_symbol)) return 0;
	int N = Inter::Symbols::read_annotation(kind_name, OBJECT_KIND_COUNTER_IANN);
	if (N >= 0) return (inter_ti) N;
	return 0;
}

@

=
typedef struct kov_value_stick {
	struct inter_symbol *prop;
	struct inter_symbol *kind_name;
	struct text_stream *identifier;
	struct inter_tree_node *node;
	CLASS_DEFINITION
} kov_value_stick;

@h Instances.

=
void VanillaObjects::instance(code_generation *gen, inter_tree_node *P) {
	inter_symbol *inst_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
	inter_symbol *inst_kind = InterSymbolsTables::symbol_from_frame_data(P, KIND_INST_IFLD);

	if (Inter::Kind::is_a(inst_kind, object_kind_symbol)) {
		int c = Inter::Symbols::read_annotation(inst_name, ARROW_COUNT_IANN);
		if (c < 0) c = 0;
		int is_dir = Inter::Kind::is_a(inst_kind, direction_kind_symbol);
		segmentation_pos saved;
		Generators::declare_instance(gen, Inter::Symbols::name(inst_kind), Inter::Symbols::name(inst_name),
			Metadata::read_optional_textual(Inter::Packages::container(P), I"^printed_name"), c, is_dir, &saved);
		VanillaObjects::append(gen, inst_name);
		inter_node_list *FL =
			Inode::ID_to_frame_list(P,
				Inter::Instance::properties_list(inst_name));
		VanillaObjects::plist(gen, FL);
		Generators::end_instance(gen, Inter::Symbols::name(inst_kind), Inter::Symbols::name(inst_name), saved);
	} else {
		inter_ti val1 = P->W.data[VAL1_INST_IFLD];
		inter_ti val2 = P->W.data[VAL2_INST_IFLD];
		int defined = TRUE;
		if (val1 == UNDEF_IVAL) defined = FALSE;
		TEMPORARY_TEXT(val)
		if (defined) WRITE_TO(val, "%d", val2);
		Generators::declare_value_instance(gen, Inter::Symbols::name(inst_name),
			Metadata::read_optional_textual(Inter::Packages::container(P), I"^printed_name"), val);
		DISCARD_TEXT(val)
	}
}

void VanillaObjects::plist(code_generation *gen, inter_node_list *FL) {
	if (FL == NULL) internal_error("no properties list");
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
		inter_symbol *prop_name = InterSymbolsTables::symbol_from_frame_data(X, PROP_PVAL_IFLD);
		if (prop_name == NULL) internal_error("no property");
		TEMPORARY_TEXT(val)
		CodeGen::select_temporary(gen, val);
		if (Generators::optimise_property_value(gen, prop_name, X) == FALSE) {
			CodeGen::pair(gen, X,
				X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD]);
		}
		CodeGen::deselect_temporary(gen);
		Generators::assign_property(gen, prop_name, val);
		DISCARD_TEXT(val)
	}
}

void VanillaObjects::append(code_generation *gen, inter_symbol *symb) {
	text_stream *OUT = CodeGen::current(gen);
	inter_tree *I = gen->from;
	text_stream *S = Inter::Symbols::read_annotation_t(symb, I, APPEND_IANN);
	if (Str::len(S) == 0) return;
	WRITE("    ");
	Vanilla::splat_matter(OUT, I, S);
}


@h Representing instances in I6.
Partly for historical reasons, partly to squeeze performance out of the
virtual machines used in traditional parser IF, the I6 run-time
implementation of instances and their properties is complicated.

The main complication is that there are two sorts of instance: objects,
such as doors and people, and everything else, such as scenes. The two
sorts are handled equally in Inter, but have completely different run-time
representations in I6:

(a) "Object instances" are instances of a kind which is a subkind, perhaps
indirectly, of "object". These are stored as I6 objects, and the I6 classes
of these objects correspond exactly to their I7 kinds (except that the kind
"object" itself is mapped to the I6 class "Class").

(b) "Value instances" are instances of kinds which are not objects but can
nevertheless have properties. The scene "entire game" is a value instance; the
number 27 is not. Value instances are stored as enumerated constants. For
example, if there are scenes called "entire game", "Overture" and "Grand
Finale", then these are stored as the constants 1, 2, 3; and I6 constants are
defined to represent them.

@h Representing properties in I6.
Both sorts of instance can have properties; for example:

>> A supporter has a number called carrying capacity.

>> A scene has a number called completion score.

allows a property to be held by object instances (supporters) and value
instances (scenes). To the writer of I7 source text, no distinction between
these cases is visible, and the same is true of Inter code.

How to store these at run-time is not so straightforward. Speed and
compactness are unusually important here, and constraints imposed by the
virtual machine targeted by I6 add further complications.

(a) Properties of object instances are stored as either I6 properties or I6
attributes of their I6 objects. As far as possible, this is a direct mapping
from I7 instances and kinds onto I6 objects and classes. It is a little
bulkier in memory than using flat arrays, but the Glulx and Z-machine virtual
machines offer a very rapid lookup operation. Thus "the carrying capacity of
the player" can be compiled to the I6 expression |player.capacity|, which
compiles to a single short call to the I6 veneer -- and one which many
interpreters today have optimised out as a basic operation, taking only a
single VM clock cycle.

(b) The properties of value instances are stored in flat arrays called
"sticks", with each property having its own stick. For example, the property
"recurring" for a scene would have a stick holding three values, one each for
the three scenes. Sticks have the same run-time format as table columns and
this is not a coincidence, because some kinds of value instances are created
by table in I7, and this lets us use the table as a ready-made set of sticks.
But now we don't have run-time lookup mechanisms already provided for us, so
we will need to set up some metadata structures to make it possible to seek
property values for value instances quickly.

In practice, property access is slightly faster for object instances, and
property storage is slightly more compact for value instances, which is
probably the right bargain.

@h Properties.
Properties in I7 are of two sorts: either-or, which behave adjectivally,
such as "open"; and value, which behave as nouns, such as "carrying capacity".
We can distinguish these because the I7 compiler annotates the property name
symbols with the |EITHER_OR_IANN| flag. It also always gives either-or
properties the kind |K_truth_state|, but note that a few value properties
also have this kind, so the annotation is the only way to be sure.

Some either-or properties of object instances can be stored as I6
"attributes". This is memory-efficient and fast at run-time: but only a
limited number can be stored this way. Here we choose which.

=

@ =
text_stream *VanillaObjects::inner_property_name(code_generation *gen, inter_symbol *prop_name) {
	text_stream *inner_name = I"<nameless>";
	int N = Inter::Symbols::read_annotation(prop_name, INNER_PROPERTY_NAME_IANN);
	if (N > 0) inner_name = Inter::Warehouse::get_text(InterTree::warehouse(gen->from), (inter_ti) N);
	return inner_name;
}

