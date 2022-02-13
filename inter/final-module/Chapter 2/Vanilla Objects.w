[VanillaObjects::] Vanilla Objects.

How the vanilla code generation strategy handles instances, kinds, and properties.

@h Properties.
Early in code-generation, we declare the properties. Generators might want to
represent these in all kinds of ways for the sake of efficiency; on Inform 6,
for example, some either-or properties of objects may be represented as
"attributes". But that's not our concern. We will try to keep the model as
simple as possible here.

What we assume is that:
(a) A property |P| is represented at runtime by a small word array.
(b) The meaning of the first two words, |P-->0| and |P-->1|, is up to the
generator. It can put anything it likes in them.
(c) |P-->2| is 1 for either-or properties, 0 for all others.
(d) |P-->3| is the printed name of the property, for use in debugging or
runtime problem messages.
(e) |P-->4| onwards is a set of permissions, a concise representation of
which instances can have the property in question. This is 0-terminated.

@ The biggest complication we face is that the linking process has left us, in
some cases, with multiple property declarations for what is actually the same
property.

For example, this arises when a property is defined in Inform 7 source like so:
= (text as Inform 7)
A room can be privately-named or publicly-named.
The privately-named property translates into Inter as "privately_named".
=
...where the property |privately_named| actually originates in a kit, written
in Inform 6 notation like so:
= (text as Inform 6)
Attribute privately_named;
=
We now have two property declarations, one in the Standard Rules module, the
other in the BasicInformKit module. It's tempting to have the linker delete
the Standard Rules one and convert references to it to point them to the kit
definition, but this is not a good idea because the kit definition doesn't
have the metadata or permissions which the Standard Rules definition has. So
we keep both in play, and reconcile them in the code below.

It gets worse: the Standard Rules properties "lighted" and "lit", though different --
one applies to rooms, one to things -- both translate to the same BasicInformKit
property |light|. At present that's the worst case scenario (i.e., three different
properties all coinciding) but we won't assume that.

So what we do is to work through the properties and group them into equivalence
classes by their final identifier names. Here, for example, we recognise these
two properties as the same because they both want to be called |privately_named|.
By scanning the assimilated properties (i.e. those from kits) first, we ensure
that the first one found in each set will be the definitive source of the property.
But it will likely be the later members of the set which have the necessary
metadata attached.

Of course, in the benign case where there is just one Inform 7-level definition
of a property, |first_with_name| and |last_with_name| will be the same, and the
list will be a singleton.

=
void VanillaObjects::declare_properties(code_generation *gen) {
	dictionary *first_with_name = Dictionaries::new(1024, FALSE); /* of |inter_symbol| */
	dictionary *last_with_name = Dictionaries::new(1024, FALSE); /* of |inter_symbol| */
	dictionary *all_with_name = Dictionaries::new(1024, FALSE); /* of |linked_list| of |inter_symbol| */

	inter_symbol *prop_name;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->assimilated_properties)
		@<Group the properties by name@>;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->unassimilated_properties)
		@<Group the properties by name@>;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->assimilated_properties)
		@<Declare one property for each name group@>;
	LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->unassimilated_properties)
		@<Declare one property for each name group@>;
}

@<Group the properties by name@> =
	text_stream *name = InterSymbol::trans(prop_name);
	if (Dictionaries::find(last_with_name, name) == NULL) {
		text_stream *inner_name = Str::duplicate(name);
		Dictionaries::create(last_with_name, inner_name);
		Dictionaries::write_value(last_with_name, inner_name, (void *) prop_name);
		linked_list *L = NEW_LINKED_LIST(inter_symbol);
		ADD_TO_LINKED_LIST(prop_name, inter_symbol, L);
		Dictionaries::create(all_with_name, inner_name);
		Dictionaries::write_value(all_with_name, inner_name, (void *) L);
	} else {
		Dictionaries::write_value(last_with_name, name, (void *) prop_name);
		linked_list *L = Dictionaries::read_value(all_with_name, name);
		ADD_TO_LINKED_LIST(prop_name, inter_symbol, L);
	}

@ So here's an annoyance. We will need two identifier names for each property.
One is the metadata array, while the other will probably be used by the generator
to hold the actual storage -- that other is called the "inner name".

In the case of our |privately_named| example, the metadata array will be called
something like |A_privately_named|, and any references to the property in kit
code or in Inform 7 source text will compile to this array. The inner name will
preserve the original identifier |privately_named|, and will likely be used by
the final generator for where a property value is actually stored. For Inform 6,
for example, we will have:
= (text)
	A_privately_named --> 0		2
	                  --> 1		privately_named (an I6 attribute)
	                  --> 2     1
	                  --> 3     "privately named"
	                  --> 4     ... permissions follow
=
In some ways it would be more convenient to use these names the other way around:
to call the array itself |privately_named| and have the inner identifier be
something like |I_privately_named|. But this fails on Inform 6 in exasperating
ways because of the built-in |name| property, whose name cannot be declared or
altered.

@<Declare one property for each name group@> =
	text_stream *name = InterSymbol::trans(prop_name);
	text_stream *inner_name = NULL;
	if (Dictionaries::find(first_with_name, name) == NULL) {
		LOGIF(PROPERTY_ALLOCATION, "! NEW name=%S   sname=%S   eor=%d   assim=%d\n",
			name, InterSymbol::identifier(prop_name),
			SymbolAnnotation::get_b(prop_name, EITHER_OR_IANN),
			SymbolAnnotation::get_b(prop_name, ASSIMILATED_IANN));
		inner_name = Str::duplicate(name);
		Dictionaries::create(first_with_name, inner_name);
		Dictionaries::write_value(first_with_name, inner_name, (void *) prop_name);
		SymbolAnnotation::set_t(gen->from, InterSymbol::package(prop_name),
			prop_name, INNER_PROPERTY_NAME_IANN, inner_name);
		@<Set the translation to a new metadata array@>;
	} else {
		LOGIF(PROPERTY_ALLOCATION, "! OLD name=%S   sname=%S   eor=%d   assim=%d\n",
			name, InterSymbol::identifier(prop_name),
			SymbolAnnotation::get_b(prop_name, EITHER_OR_IANN),
			SymbolAnnotation::get_b(prop_name, ASSIMILATED_IANN));
		inter_symbol *existing_prop_name = 
			(inter_symbol *) Dictionaries::read_value(first_with_name, name);
		inner_name = VanillaObjects::inner_property_name(gen, existing_prop_name);
		InterSymbol::set_translate(prop_name, InterSymbol::trans(existing_prop_name));
		SymbolAnnotation::set_t(gen->from, InterSymbol::package(prop_name),
			prop_name, INNER_PROPERTY_NAME_IANN, inner_name);
	}
	LOGIF(PROPERTY_ALLOCATION, "! Translation %S, inner name %S\n",
		InterSymbol::trans(prop_name), VanillaObjects::inner_property_name(gen, prop_name));

@ Note that //Generators::declare_property// calls the generator to ask it to
create the first two entries in the metadata array. Those can be anything the
generator wants.

@<Set the translation to a new metadata array@> =
	text_stream *array_name = Str::new();
	WRITE_TO(array_name, "A_%S", inner_name);
	InterSymbol::set_translate(prop_name, array_name);

	linked_list *all_forms = (linked_list *) Dictionaries::read_value(all_with_name, name);

	segmentation_pos saved;
	Generators::begin_array(gen, array_name, prop_name, NULL, WORD_ARRAY_FORMAT, &saved);
	Generators::declare_property(gen, prop_name, all_forms);
	@<Write the either-or flag@>;
	@<Write the property name in double quotes@>;
	@<Write a list of kinds or objects which are permitted to have this property@>;
	Generators::mangled_array_entry(gen, I"NULL", WORD_ARRAY_FORMAT);
	Generators::end_array(gen, WORD_ARRAY_FORMAT, &saved);

@<Write the either-or flag@> =
	if (SymbolAnnotation::get_b(prop_name, EITHER_OR_IANN))
		Generators::array_entry(gen, I"1", WORD_ARRAY_FORMAT);
	else
		Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);

@ Note that we extract the printed name from the last property in the set,
because that will come from an I7 source text definition.

@<Write the property name in double quotes@> =
	inter_symbol *last_prop_name = 
		(inter_symbol *) Dictionaries::read_value(last_with_name, name);
	inter_tree *I = gen->from;
	text_stream *pname = SymbolAnnotation::get_t(last_prop_name, I, PROPERTY_NAME_IANN);
	if (pname == NULL) pname = I"<nameless>";
	TEMPORARY_TEXT(entry)
	CodeGen::select_temporary(gen, entry);
	Generators::compile_literal_text(gen, pname, TRUE);
	CodeGen::deselect_temporary(gen);
	Generators::array_entry(gen, entry, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(entry)

@ Type-safety at runtime is managed with a hybrid of compile-time and runtime
checking. Compile-time checking polices all uses of properties of values other
than objects, but it will usually allow any object property of any object to
be accessed, because it's not usually possible for the typechecker to know if
an object value |O| is a vehicle, a direction, and so on. For this reason
some runtime checking is needed, and to perform that checking, properties need
a list of permissions to be stored in memory. This is where.

Note that permissions are accumulated for all of the properties in a given
name set. In the case of "lighted" and "lit" and |light|, therefore, the
permissions written will be those for "lighted" (rooms, basically) and then
those for "lit" (things); |light|, the WorldModelKit original, has no permissions --
assimilated properties never do have.

@<Write a list of kinds or objects which are permitted to have this property@> =
	inter_tree *I = gen->from;
	inter_symbol *eprop_name;
	LOOP_OVER_LINKED_LIST(eprop_name, inter_symbol, all_forms) {
		inter_node_list *EVL =
			InterWarehouse::get_node_list(InterTree::warehouse(I),
				Inter::Property::permissions_list(eprop_name));
		@<List any kind of object with an explicit permission@>;
		@<List any individual instance with an explicit permission@>;
		@<List all top-level kinds if "object" itself has an explicit permission@>;
	}

@<List any kind of object with an explicit permission@> =
	inter_symbol *kind_s;
	LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order)
		if (VanillaObjects::is_kind_of_object(gen, kind_s)) {
			inter_tree_node *X;
			LOOP_THROUGH_INTER_NODE_LIST(X, EVL) {
				inter_symbol *owner_s =
					InterSymbolsTable::symbol_from_ID_at_node(X, OWNER_PERM_IFLD);
				if (owner_s == kind_s)
					Generators::symbol_array_entry(gen, kind_s, WORD_ARRAY_FORMAT);
			}
		}

@ An unusual feature of Inform as a programming language is that individual objects
can be given properties, even when other objects of the same kind may lack them. So:

@<List any individual instance with an explicit permission@> =
	inter_symbol *inst_s;
	LOOP_OVER_LINKED_LIST(inst_s, inter_symbol, gen->instances_in_declaration_order)
		if (VanillaObjects::is_kind_of_object(gen, Inter::Instance::kind_of(inst_s))) {
			inter_tree_node *X;
			LOOP_THROUGH_INTER_NODE_LIST(X, EVL) {
				inter_symbol *owner_s =
					InterSymbolsTable::symbol_from_ID_at_node(X, OWNER_PERM_IFLD);
				if (owner_s == inst_s)
					Generators::symbol_array_entry(gen, inst_s, WORD_ARRAY_FORMAT);
			}
		}

@ It's happily a rare occurrence, but "object" itself can have properties -- so
that every object of any kind has permission to have that. We convey that by giving
permission for every top-level kind of object. (There are typically only four of
these top-level kinds, and not many properties have these permissions, so it's
not as wasteful as it looks.)

@<List all top-level kinds if "object" itself has an explicit permission@> =
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, EVL) {
		inter_symbol *owner_s =
			InterSymbolsTable::symbol_from_ID_at_node(X, OWNER_PERM_IFLD);
		if (owner_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) {
			Generators::mangled_array_entry(gen, I"K0_kind", WORD_ARRAY_FORMAT);
			inter_symbol *kind_s;
			LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order) {
				if (Inter::Kind::super(kind_s) == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) {
					Generators::symbol_array_entry(gen, kind_s, WORD_ARRAY_FORMAT);
				}
			}
		}
	}
	
@ Generators can then access the inner name (if they want it) thus:

=
text_stream *VanillaObjects::inner_property_name(code_generation *gen, inter_symbol *prop_name) {
	text_stream *inner_name = SymbolAnnotation::get_t(prop_name,
		gen->from, INNER_PROPERTY_NAME_IANN);
	if (inner_name == NULL) inner_name = I"<nameless>";
	return inner_name;
}

@h Instances, kinds and values of properties.
Round two is to make declarations of our kinds and instances. Again, we want to
make as few assumptions as possible about the eventual runtime representation
of these ideas, but that will not be no assumptions.

In particular, whereas generators can stash object properties more or less in
any way they like, they are required to stash properties of non-object values
in small arrays called "sticks", which mimic table columns. This is imposed by
the language itself, which allows properties of values to be defined by tables
of values.

So while it would be attractive here to make no distinction between objects
and other property-owners, we cannot do so.

=
void VanillaObjects::declare_kinds_and_instances(code_generation *gen) {
	inter_tree *I = gen->from;
	@<Declare kinds of value@>;
	@<Declare kinds of object@>;
	@<Declare instances@>;
}

@ We start then with kinds which have properties but are not kinds of objects.
We want to ensure that no property is assigned more than once (for the same kind),
so we use "marks" on those already done.

@<Declare kinds of value@> =
	int unique_kovp_id = 0;
	inter_symbol *kind_s;
	LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order) {
		if (VanillaObjects::value_kind_with_properties(gen, kind_s)) {
			segmentation_pos saved;
			Generators::declare_kind(gen, kind_s, &saved);
			inter_symbol *prop_name;
			LOOP_OVER_LINKED_LIST(prop_name, inter_symbol, gen->unassimilated_properties)
				CodeGen::unmark(prop_name);
			@<Declare properties which every instance of this kind of value can have@>;
			@<Declare properties which only some instances of this kind of value can have@>;
			Generators::end_kind(gen, kind_s, saved);
		}
	}

@<Declare properties which every instance of this kind of value can have@> =
	inter_node_list *FL = InterWarehouse::get_node_list(InterTree::warehouse(I),
		Inter::Kind::permissions_list(kind_s));
	@<Work through this node list of permissions@>;

@<Declare properties which only some instances of this kind of value can have@> =
	inter_symbol *inst_s;
	LOOP_OVER_LINKED_LIST(inst_s, inter_symbol, gen->instances_in_declaration_order) {
		if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_s), kind_s)) {
			inter_node_list *FL = InterWarehouse::get_node_list(InterTree::warehouse(I),
				Inter::Instance::permissions_list(inst_s));
			@<Work through this node list of permissions@>;
		}
	}

@<Work through this node list of permissions@> =
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
		inter_symbol *prop_name = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PERM_IFLD);
		if (prop_name == NULL) internal_error("no property");
		if (CodeGen::marked(prop_name) == FALSE) {
			CodeGen::mark(prop_name);
			@<Assign the property values for this property@>;
		}
	}

@ In the case where a kind of value has been created by table, as in this example:
= (text as Inform 7)	
	Planet is a kind of value. The planets are defined by the Table of Outer Planets.

	Table of Outer Planets
	planet		semimajor axis
	Jupiter		5 AU
	Saturn		10 AU
	Uranus		19 AU
	Neptune		30 AU
	Pluto		39 AU
=
the property "semimajor axis" is already stored in a table column. That becomes
our stick array. But in other cases, where the instances have not been created
by table, no sticks exist and we must compile them.

@<Assign the property values for this property@> =
	text_stream *ident = NULL;
	if (X->W.instruction[STORAGE_PERM_IFLD]) {
		inter_symbol *store = InterSymbolsTable::symbol_from_ID_at_node(X, STORAGE_PERM_IFLD);
		if (store == NULL) internal_error("bad PP in inter");
		ident = InterSymbol::trans(store);
	} else {
		ident = Str::new();
		WRITE_TO(ident, "KOVP_%d", unique_kovp_id++);
		@<Compile a stick of property values and put its address here@>;
	}
	Generators::assign_properties(gen, kind_s, prop_name, ident);

@ These little arrays are sticks of property values, and they are laid out
as if they were column arrays in a Table data structure. This means they must
be |TABLE_ARRAY_FORMAT| arrays (which wastes one word of memory) and must have
blanked-out table column header words at the front (which wastes a further
|COL_HSIZE| words). But the cost is a simple overhead, not rising with the
number of instances, and is worth it for simplicity and speed.

@<Compile a stick of property values and put its address here@> =
	segmentation_pos saved;
	Generators::begin_array(gen, ident, NULL, NULL, TABLE_ARRAY_FORMAT, &saved);
	Generators::array_entry(gen, I"0", TABLE_ARRAY_FORMAT);
	Generators::array_entry(gen, I"0", TABLE_ARRAY_FORMAT);
	inter_symbol *inst_s;
	LOOP_OVER_LINKED_LIST(inst_s, inter_symbol, gen->instances_in_declaration_order) {
		if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_s), kind_s)) {
			int found = 0;
			inter_node_list *PVL =
				Inode::ID_to_frame_list(X,
					Inter::Instance::properties_list(inst_s));
			@<Work through this node list of values@>;
			PVL = Inode::ID_to_frame_list(X,
					Inter::Kind::properties_list(kind_s));
			@<Work through this node list of values@>;
			if (found == 0) Generators::array_entry(gen, I"0", TABLE_ARRAY_FORMAT);
		}
	}
	Generators::end_array(gen, TABLE_ARRAY_FORMAT, &saved);

@<Work through this node list of values@> =
	inter_tree_node *Y;
	LOOP_THROUGH_INTER_NODE_LIST(Y, PVL) {
		inter_symbol *p_name = InterSymbolsTable::symbol_from_ID(
			InterPackage::scope_of(Y), Y->W.instruction[PROP_PVAL_IFLD]);
		if ((p_name == prop_name) && (found == 0)) {
			found = 1;
			inter_ti v1 = Y->W.instruction[DVAL1_PVAL_IFLD];
			inter_ti v2 = Y->W.instruction[DVAL2_PVAL_IFLD];
			TEMPORARY_TEXT(val)
			CodeGen::select_temporary(gen, val);
			CodeGen::pair(gen, Y, v1, v2);
			CodeGen::deselect_temporary(gen);
			Generators::array_entry(gen, val, TABLE_ARRAY_FORMAT);
			DISCARD_TEXT(val)
		}
	}

@ So now for the objects. First we declare each kind of object, first calling
//Generators::declare_kind//, then //Generators::assign_property// for each
property value, and then //Generators::end_kind//.

@<Declare kinds of object@> =
	inter_symbol *kind_s;
	LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order) {
		if ((kind_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) ||
			(VanillaObjects::is_kind_of_object(gen, kind_s))) {
			segmentation_pos saved;
			Generators::declare_kind(gen, kind_s, &saved);
			VanillaObjects::append(gen, kind_s);
			inter_node_list *FL = InterWarehouse::get_node_list(InterTree::warehouse(I),
				Inter::Kind::properties_list(kind_s));
			@<Declare the properties of this kind or instance@>;
			Generators::end_kind(gen, kind_s, saved);
		}
	}

@ And then the instances. As with kinds, we call //Generators::declare_instance//,
then give some property values, then call //Generators::end_instance//.

With instances of values, note that we have no property assignment to do: that
was all taken care of with the sticks of property values already declared.

@<Declare instances@> =
	inter_symbol *inst_s;
	LOOP_OVER_LINKED_LIST(inst_s, inter_symbol, gen->instances_in_declaration_order) {
		inter_tree_node *P = InterSymbol::definition(inst_s);
		inter_symbol *inst_kind = InterSymbolsTable::symbol_from_ID_at_node(P, KIND_INST_IFLD);
		int N = -1;
		if (Inter::Kind::is_a(inst_kind, RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) == FALSE)
			N = (int) (P->W.instruction[VAL2_INST_IFLD]);
		segmentation_pos saved;
		Generators::declare_instance(gen, inst_s, inst_kind, N, &saved);
		if (Inter::Kind::is_a(inst_kind, RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM))) {
			VanillaObjects::append(gen, inst_s);
			inter_node_list *FL =
				Inode::ID_to_frame_list(P,
					Inter::Instance::properties_list(inst_s));
			@<Declare the properties of this kind or instance@>;
		}
		Generators::end_instance(gen, inst_s, inst_kind, saved);
	}

@ The following, then, is used either for properties of a kind of object, or
properties of an instance of object, and issues a stream of //Generators::assign_property//
function calls.

@<Declare the properties of this kind or instance@> =
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL)
		Generators::assign_property(gen,
			InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PVAL_IFLD),
			X->W.instruction[DVAL1_PVAL_IFLD], X->W.instruction[DVAL2_PVAL_IFLD], X);

@ That just leaves the following horrible function, which is called for each
kind or instance of object, and passes raw splat matter down into the declaration
which the generator is making.

This is a bad idea, because it presupposes which generator is being used, or
at any rate what the syntax will be. It arises from source text like this:
= (text as Inform 7)
Include (-
	with before [; Go: return 1; ],
-) when defining a rideable vehicle.
=
...which should probably not be allowed. The splat is the text between |(-|
and |-)| here, and as can be seen, it's in Inform 6 syntax, which would be bad
news for, say, the C generator.

=
void VanillaObjects::append(code_generation *gen, inter_symbol *symb) {
	text_stream *OUT = CodeGen::current(gen);
	inter_tree *I = gen->from;
	text_stream *S = SymbolAnnotation::get_t(symb, I, APPEND_IANN);
	if (Str::len(S) > 0) Vanilla::splat_matter(OUT, I, S);
}

@h Utility functions.
Returns the weak ID of a kind, which is a small integer known at compile time.

=
int VanillaObjects::weak_id(inter_symbol *kind_s) {
	inter_package *pack = InterPackage::container(kind_s->definition);
	inter_symbol *weak_s = Metadata::read_optional_symbol(pack, I"^weak_id");
	int alt_N = -1;
	if (weak_s) alt_N = InterSymbol::evaluate_to_int(weak_s);
	if (alt_N >= 0) return alt_N;
	return 0;
}

@ |TRUE| for something like "thing" or "room", but |FALSE| for "object" itself.

=
int VanillaObjects::is_kind_of_object(code_generation *gen, inter_symbol *kind_s) {
	if (kind_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) return FALSE;
	inter_data_type *idt = Inter::Kind::data_type(kind_s);
	if (idt == unchecked_idt) return FALSE;
	if (Inter::Kind::is_a(kind_s, RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM))) return TRUE;
	return FALSE;
}

@ |TRUE| for a kind which can have properties but is not any sort of object.

=
int VanillaObjects::value_kind_with_properties(code_generation *gen, inter_symbol *kind_s) {
	inter_tree *I = gen->from;
	if (VanillaObjects::is_kind_of_object(gen, kind_s)) return FALSE;
	if (kind_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) return FALSE;
	if (kind_s == RunningPipelines::get_symbol(gen->from_step, unchecked_kind_RPSYM)) return FALSE;
	inter_node_list *FL = InterWarehouse::get_node_list(InterTree::warehouse(I),
		Inter::Kind::permissions_list(kind_s));
	if (InterNodeList::empty(FL) == FALSE) return TRUE;
	inter_symbol *inst_s;
	LOOP_OVER_LINKED_LIST(inst_s, inter_symbol, gen->instances_in_declaration_order) {
		if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_s), kind_s)) {
			inter_node_list *FL = InterWarehouse::get_node_list(InterTree::warehouse(I),
				Inter::Instance::permissions_list(inst_s));
			if (InterNodeList::empty(FL) == FALSE) return TRUE;
		}
	}
	return FALSE;
}

@ |TRUE| for a property which might be held by one or more instances which
are not objects.

=
int VanillaObjects::is_property_of_values(code_generation *gen, inter_symbol *prop_s) {
	inter_tree *I = gen->from;
	inter_node_list *PL =
		InterWarehouse::get_node_list(
			InterTree::warehouse(I),
			Inter::Property::permissions_list(prop_s));
	if (PL == NULL) internal_error("no permissions list");
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, PL) {
		inter_symbol *owner_s = InterSymbolsTable::symbol_from_ID(
			InterPackage::scope_of(X), X->W.instruction[OWNER_PERM_IFLD]);
		if (owner_s == NULL) internal_error("bad owner");
		inter_symbol *owner_kind_s = NULL;
		inter_tree_node *D = InterSymbol::definition(owner_s);
		if ((D) && (D->W.instruction[ID_IFLD] == INSTANCE_IST)) {
			owner_kind_s = Inter::Instance::kind_of(owner_s);
		} else {
			owner_kind_s = owner_s;
		}
		if (VanillaObjects::is_kind_of_object(gen, owner_kind_s) == FALSE)
			return TRUE;
	}
	return FALSE;
}
