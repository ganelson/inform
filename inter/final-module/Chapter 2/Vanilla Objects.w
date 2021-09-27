[VanillaObjects::] Vanilla Objects.

How the vanilla code generation strategy handles instances, kinds, and properties.

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
		text_stream *call_it = Inter::Symbols::name(prop_name);
		if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT)) {
			if ((X->W.data[DVAL1_PVAL_IFLD] == LITERAL_IVAL) &&
				(X->W.data[DVAL2_PVAL_IFLD] == 0)) {
				Generators::assign_property(gen, call_it, I"0", TRUE);
			} else {
				Generators::assign_property(gen, call_it, I"1", TRUE);
			}
		} else {
			TEMPORARY_TEXT(OUT)
			CodeGen::select_temporary(gen, OUT);
			if (Generators::optimise_property_value(gen, prop_name, X) == FALSE) {
				CodeGen::pair(gen, X,
					X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD]);
			}
			CodeGen::deselect_temporary(gen);
			Generators::assign_property(gen, call_it, OUT, FALSE);
			DISCARD_TEXT(OUT)
		}
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
void VanillaObjects::property(inter_tree *I, inter_symbol *prop_name, code_generation *gen, int *FBNA_found, int *attribute_slots_used) {
	if (prop_name == NULL) internal_error("bad property");
	if (Inter::Symbols::read_annotation(prop_name, EITHER_OR_IANN) >= 0) {
		int translated = FALSE;
		if (Inter::Symbols::read_annotation(prop_name, EXPLICIT_ATTRIBUTE_IANN) >= 0) translated = TRUE;
		if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) >= 0) translated = TRUE;

		int make_attribute = NOT_APPLICABLE;
		@<Any either/or property which can belong to a value instance is ineligible@>;
		@<An either/or property translated to an attribute declared in the I6 template must be chosen@>;
		@<Otherwise give away attribute slots on a first-come-first-served basis@>;
		if (make_attribute == TRUE) Inter::Symbols::set_flag(prop_name, ATTRIBUTE_MARK_BIT);
		@<Check against the I7 compiler's beliefs@>;

		if (make_attribute) {
			@<Declare as an I6 attribute@>;
		} else {
			@<Worry about the FBNA@>;
		}
	}
}

@ The dodge of using an attribute to store an either-or property won't work
for properties of value instances, because then the value-property-holder
object couldn't store the necessary table address (see next section). So we
must rule out any property which might belong to any value.

@<Any either/or property which can belong to a value instance is ineligible@> =
	inter_node_list *PL =
		Inter::Warehouse::get_frame_list(
			InterTree::warehouse(I),
			Inter::Property::permissions_list(prop_name));
	if (PL == NULL) internal_error("no permissions list");
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, PL) {
		inter_symbol *owner_name =
			InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(X), X->W.data[OWNER_PERM_IFLD]);
		if (owner_name == NULL) internal_error("bad owner");
		inter_symbol *owner_kind = NULL;
		inter_tree_node *D = Inter::Symbols::definition(owner_name);
		if ((D) && (D->W.data[ID_IFLD] == INSTANCE_IST)) {
			owner_kind = Inter::Instance::kind_of(owner_name);
		} else {
			owner_kind = owner_name;
		}
		if (VanillaObjects::is_kind_of_object(owner_kind) == FALSE) make_attribute = FALSE;
	}

@ An either/or property which has been deliberately equated to an I6
template attribute with a sentence like...

>> The fixed in place property translates into I6 as "static".

...is (we must assume) already declared as an |Attribute|, so we need to
remember that it's implemented as an attribute when compiling references
to it.

@<An either/or property translated to an attribute declared in the I6 template must be chosen@> =
	if (translated) make_attribute = TRUE;

@ We have in theory 48 Attribute slots to use up, that being the number
available in versions 5 and higher of the Z-machine, but the I6 template
layer consumes so many that only a few slots remain for the user's own
creations. Giving these away to the first-created properties is the
simplest way to allocate them, and in fact it works pretty well, because
the first such either/or properties tend to be created in extensions and
to be frequently used.

@d ATTRIBUTE_SLOTS_TO_GIVE_AWAY 11

@<Otherwise give away attribute slots on a first-come-first-served basis@> =
	if (make_attribute == NOT_APPLICABLE) {
		if (*attribute_slots_used++ < ATTRIBUTE_SLOTS_TO_GIVE_AWAY)
			make_attribute = TRUE;
		else
			make_attribute = FALSE;
	}

@ At present the I7 compiler makes a decision matching this one for its
own internal needs. We want to make sure its decision matches ours, so we
check that here. (It tells us by marking the property name with the
|ATTRIBUTE_IANN| annotation.) But this code will eventually go.

@<Check against the I7 compiler's beliefs@> =
	int made_attribute = FALSE;
	if (Inter::Symbols::read_annotation(prop_name, ATTRIBUTE_IANN) >= 0)
		made_attribute = TRUE;
	if (made_attribute != make_attribute) {
		LOG("Disagree on %S: %d vs %d\n", prop_name->symbol_name, made_attribute, make_attribute);
		internal_error("attribute allocation dispute");
	}

@ A curiosity of I6 is that attributes must be declared before use, whereas
properties need not be. We generate suitable |Attribute| statements here.
Note that if the property has been translated onto an existing I6 name, then
we assume that's the name of an attribute already declared (for example
in the I6 template, or some extension), and we therefore do nothing.

@<Declare as an I6 attribute@> =
	if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) >= 0) {
		text_stream *A = Inter::Symbols::get_translate(prop_name);
		if (A == NULL) A = Inter::Symbols::name(prop_name);
		Generators::declare_attribute(gen, A);
	} else {
		if (translated == FALSE)
			Generators::declare_attribute(gen, Inter::Symbols::name(prop_name));
	}

@ The weak point in our scheme for making some either/or properties into
Attributes is that run-time code is going to need a fast way to determine
which, since they have to be accessed differently. We rely on the facts that

(a) at run-time, attribute numbers are all numerically lower than property
numbers, and

(b) property numbers increase in order of their first appearances in the
I6 source code.

Thus an either/or property |P| must be an I6 attribute if |P < F| and must be
an I6 property if |P >= F|, where |F| is the earliest-defined either/or
property which isn't stored as an attribute.

This cutoff value |F| is customarily called FBNA, the "first boolean not
an attribute". (Perhaps she ought to be called FEONA.) The following
compiles an I6 constant for this value.

@<Worry about the FBNA@> =
	if (*FBNA_found == FALSE) {
		*FBNA_found = TRUE;
		TEMPORARY_TEXT(val)
		Generators::mangle(gen, val, Inter::Symbols::name(prop_name));
		Generators::declare_constant(gen, I"FBNA_PROP_NUMBER", NULL, RAW_GDCFORM, NULL, val, FALSE);
		DISCARD_TEXT(val)
	}

@ It's unlikely, but just possible, that no FBNAs ever exist, so after the
above has been tried on all properties:

=
void VanillaObjects::consolidate(code_generation *gen) {
	inter_tree *I = gen->from;
	inter_symbol **all_props_in_source_order = NULL;
	inter_symbol **props_in_source_order = NULL;
	int no_unassimilated_properties = 0;
	@<Make a list of properties in source order@>;
	@<Compile the property numberspace forcer@>;

	inter_symbol **kinds_in_source_order = NULL;
	inter_symbol **kinds_in_declaration_order = NULL;
	@<Make a list of kinds in source order@>;

	inter_symbol **instances_in_declaration_order = NULL;
	@<Make a list of instances in declaration order@>;

	if (no_unassimilated_properties > 0) @<Write Value Property Holder objects for each kind of value instance@>;
	@<Make a list of kinds in declaration order@>;
	@<Annotate kinds of object with a sequence counter@>;
	@<Write the KindHierarchy array@>;
	@<Write an I6 Class definition for each kind of object@>;
	@<Write an I6 Object definition for each object instance@>;
	@<Write the property metadata array@>;

	@<Stub the properties@>;
}

@<Make a list of properties in source order@> =
	inter_tree_node *P;
	LOOP_OVER_LINKED_LIST(P, inter_tree_node, gen->properties) {
		inter_symbol *prop_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
		if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
			no_unassimilated_properties++;
	}

	if (no_unassimilated_properties > 0) {
		int FBNA_found = FALSE;
		int attribute_slots_used = 0;
		all_props_in_source_order = (inter_symbol **)
			(Memory::calloc(no_unassimilated_properties, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
		int c = 0;
		inter_tree_node *P;
		LOOP_OVER_LINKED_LIST(P, inter_tree_node, gen->properties) {
			inter_symbol *prop_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
			if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
				all_props_in_source_order[c++] = prop_name;
			else
				VanillaObjects::property(I, prop_name, gen, &FBNA_found, &attribute_slots_used);
		}
		qsort(all_props_in_source_order, (size_t) no_unassimilated_properties, sizeof(inter_symbol *),
			VanillaObjects::compare_kind_symbols);
		for (int p=0; p<no_unassimilated_properties; p++) {
			inter_symbol *prop_name = all_props_in_source_order[p];
			VanillaObjects::property(I, prop_name, gen, &FBNA_found, &attribute_slots_used);
		}
		if (FBNA_found == FALSE)
			Generators::declare_constant(gen, I"FBNA_PROP_NUMBER", NULL, RAW_GDCFORM, NULL, I"MAX_POSITIVE_NUMBER", FALSE);
	}

	if (no_unassimilated_properties > 0) {
		props_in_source_order = (inter_symbol **)
			(Memory::calloc(no_unassimilated_properties, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
		int c = 0;
		inter_tree_node *P;
		LOOP_OVER_LINKED_LIST(P, inter_tree_node, gen->properties) {
			inter_symbol *prop_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
			if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
				props_in_source_order[c++] = prop_name;
		}

		LOOP_OVER_LINKED_LIST(P, inter_tree_node, gen->properties) {
			inter_symbol *prop_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
			if ((Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) == 1) &&
				(Inter::Symbols::read_annotation(prop_name, ATTRIBUTE_IANN) != 1)) {
				Generators::declare_property(gen, prop_name, TRUE);
			}
		}
	}

@<Make a list of kinds in source order@> =
	if (LinkedLists::len(gen->kinds) == 0) return;

	kinds_in_source_order = (inter_symbol **)
		(Memory::calloc(LinkedLists::len(gen->kinds), sizeof(inter_symbol *), CODE_GENERATION_MREASON));
	int i = 0;
	inter_tree_node *P;
	LOOP_OVER_LINKED_LIST(P, inter_tree_node, gen->kinds) {
		inter_symbol *kind_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
		kinds_in_source_order[i++] = kind_name;
	}
	qsort(kinds_in_source_order, (size_t) i, sizeof(inter_symbol *),
		VanillaObjects::compare_kind_symbols);

@<Make a list of kinds in declaration order@> =
	kinds_in_declaration_order = (inter_symbol **)
		(Memory::calloc(LinkedLists::len(gen->kinds), sizeof(inter_symbol *), CODE_GENERATION_MREASON));
	int i = 0;
	inter_tree_node *P;
	LOOP_OVER_LINKED_LIST(P, inter_tree_node, gen->kinds) {
		inter_symbol *kind_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
		kinds_in_declaration_order[i++] = kind_name;
	}
	qsort(kinds_in_declaration_order, (size_t) i, sizeof(inter_symbol *),
		VanillaObjects::compare_kind_symbols_decl);

@<Make a list of instances in declaration order@> =
	if (LinkedLists::len(gen->instances) > 0) {
		instances_in_declaration_order = (inter_symbol **)
			(Memory::calloc(LinkedLists::len(gen->instances), sizeof(inter_symbol *), CODE_GENERATION_MREASON));
		int i=0;
		inter_tree_node *P;
		LOOP_OVER_LINKED_LIST(P, inter_tree_node, gen->instances) {
			inter_symbol *inst_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
			instances_in_declaration_order[i++] = inst_name;
		}
		qsort(instances_in_declaration_order, (size_t) i, sizeof(inter_symbol *),
			VanillaObjects::compare_kind_symbols_decl);
	}

@ But there's a snag. The above assumes that property values will have the
same ordering at run-time as their definition order here, but that isn't
necessarily true. The run-time ordering depends on how early in the I6
source code they appear, and that in turn depends on which objects have
which properties, and so on -- nothing we can rely on.

We finesse this by creating the following spurious object before the
class hierarchy and object tree are created: its properties are therefore
all new creations, and since we declare them in I7 creation order, they
are now allocated I6 property numbers in a sequence matching this. (We
don't care about the numbering of non-either/or properties, so we don't
bother to force them.)

@<Compile the property numberspace forcer@> =
	if (no_unassimilated_properties > 0) {
		segmentation_pos saved;
		Generators::declare_instance(gen, I"Object", I"property_numberspace_forcer", NULL, -1, FALSE, &saved);
		for (int p=0; p<no_unassimilated_properties; p++) {
			inter_symbol *prop_name = props_in_source_order[p];
			if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT) == FALSE) {
				inter_symbol *kind_name = Inter::Property::kind_of(prop_name);
				if (kind_name == truth_state_kind_symbol) {
					Generators::assign_property(gen, Inter::Symbols::name(prop_name), I"0", FALSE);
				}
			}
		}
		Generators::end_instance(gen, I"Object", I"property_numberspace_forcer", saved);
	}

@<Annotate kinds of object with a sequence counter@> =
	inter_ti c = 1;
	for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
		inter_symbol *kind_name = kinds_in_source_order[i];
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
		inter_symbol *kind_name = kinds_in_source_order[i];
		if (VanillaObjects::is_kind_of_object(kind_name)) no_kos++;
	}

	segmentation_pos saved;
	Generators::begin_array(gen, I"KindHierarchy", NULL, NULL, WORD_ARRAY_FORMAT, &saved);
	if (no_kos > 0) {
		Generators::mangled_array_entry(gen, I"K0_kind", WORD_ARRAY_FORMAT);
		Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
		for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
			inter_symbol *kind_name = kinds_in_source_order[i];
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
	@<Define the I6 VPH class@>;
	inter_symbol *max_weak_id = InterSymbolsTables::url_name_to_symbol(I, NULL, 
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = Inter::Symbols::evaluate_to_int(max_weak_id);
		if (M != 0) {
			@<Decide who gets a VPH@>;
			@<Write the VPH lookup array@>;
			for (int w=1; w<M; w++) {
				for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
					inter_symbol *kind_name = kinds_in_source_order[i];
					if (VanillaObjects::weak_id(kind_name) == w) {
						if (Inter::Symbols::get_flag(kind_name, VPH_MARK_BIT)) {
							TEMPORARY_TEXT(instance_name)
							WRITE_TO(instance_name, "VPH_%d", w);
							segmentation_pos saved;
							Generators::declare_instance(gen, I"VPH_Class", instance_name, NULL, -1, FALSE, &saved);
							TEMPORARY_TEXT(N)
							WRITE_TO(N, "%d", Inter::Kind::instance_count(kind_name));
							Generators::assign_property(gen, I"value_range", N, FALSE);
							DISCARD_TEXT(N)
							for (int p=0; p<no_unassimilated_properties; p++) {
								inter_symbol *prop_name = props_in_source_order[p];
								CodeGen::unmark(prop_name);
							}
							inter_node_list *FL =
								Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Kind::permissions_list(kind_name));
							@<Work through this frame list of permissions@>;
							for (int in=0; in<LinkedLists::len(gen->instances); in++) {
								inter_symbol *inst_name = instances_in_declaration_order[in];
								if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
									inter_node_list *FL =
										Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Instance::permissions_list(inst_name));
									@<Work through this frame list of permissions@>;
								}
							}
							Generators::end_instance(gen, I"VPH_Class", instance_name, saved);
							DISCARD_TEXT(instance_name)
						}
					}
				}
			}
		}
	}
	@<Compile the property stick arrays@>;

@ It's convenient to be able to distinguish, at run-time, which objects are
the VPH objects used only for kind-property indexing; we can test if |O| is
such an object with the I6 condition |(O ofclass VPH_Class)|.

The property |value_range| for a VPH object is the number |N| such that the
legal values at run-time for this kind are |1, 2, 3, ..., N|: or in other
words, the number of instances of this kind.

@<Define the I6 VPH class@> =
	segmentation_pos saved;
	Generators::declare_class(gen, I"VPH_Class", NULL, I"Class", &saved);
	Generators::end_class(gen, I"VPH_Class", saved);

@<Decide who gets a VPH@> =
	for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
		inter_symbol *kind_name = kinds_in_source_order[i];
		if (VanillaObjects::is_kind_of_object(kind_name)) continue;
		if (kind_name == object_kind_symbol) continue;
		if (kind_name == unchecked_kind_symbol) continue;
		int vph_me = FALSE;
		inter_node_list *FL =
			Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Kind::permissions_list(kind_name));
		if (FL->first_in_inl) vph_me = TRUE;
		else for (int in=0; in<LinkedLists::len(gen->instances); in++) {
			inter_symbol *inst_name = instances_in_declaration_order[in];
			if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
				inter_node_list *FL =
					Inter::Warehouse::get_frame_list(InterTree::warehouse(I), Inter::Instance::permissions_list(inst_name));
				if (FL->first_in_inl) vph_me = TRUE;
			}
		}
		if (vph_me) Inter::Symbols::set_flag(kind_name, VPH_MARK_BIT);
	}

@ This array is indexed by the weak kind ID of |K|. The entry is 0 if |K|
doesn't have a VPH, or the object number of its VPH if it has.

@<Write the VPH lookup array@> =
	segmentation_pos saved;
	Generators::begin_array(gen, I"value_property_holders", NULL, NULL, WORD_ARRAY_FORMAT, &saved);
	Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
	int vph = 0;
	for (int w=1; w<M; w++) {
		int written = FALSE;
		for (int i=0; i<LinkedLists::len(gen->kinds); i++) {
			inter_symbol *kind_name = kinds_in_source_order[i];
			if (VanillaObjects::weak_id(kind_name) == w) {
				if (Inter::Symbols::get_flag(kind_name, VPH_MARK_BIT)) {
					written = TRUE;
					TEMPORARY_TEXT(vph)
					WRITE_TO(vph, "VPH_%d", w);
					Generators::mangled_array_entry(gen, vph, WORD_ARRAY_FORMAT);
					DISCARD_TEXT(vph)
				}
			}
		}
		if (written) vph++; else Generators::array_entry(gen, I"0", WORD_ARRAY_FORMAT);
	}
	Generators::end_array(gen, WORD_ARRAY_FORMAT, &saved);
	@<Stub a faux VPH if none have otherwise been created@>;

@ In the event that no value instances have properties, there'll be no
instances of the |VPH_Class|, and no I6 object will be compiled with a
|value_range| property; that means I6 code referring to this will fail with an
I6 error. We don't want that, so if necessary we compile a useless VPH object
just to force the property into being.

@<Stub a faux VPH if none have otherwise been created@> =
	/* if (vph == 0) WRITE("VPH_Class UnusedVPH with value_range 0;\n"); */

@<Work through this frame list of permissions@> =
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
		inter_symbol *prop_name = InterSymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
		if (prop_name == NULL) internal_error("no property");
		if (CodeGen::marked(prop_name) == FALSE) {
			CodeGen::mark(prop_name);
			text_stream *call_it = Inter::Symbols::name(prop_name);
			if (X->W.data[STORAGE_PERM_IFLD]) {
				inter_symbol *store = InterSymbolsTables::symbol_from_frame_data(X, STORAGE_PERM_IFLD);
				if (store == NULL) internal_error("bad PP in inter");
				Generators::assign_mangled_property(gen, call_it, Inter::Symbols::name(store), FALSE);
			} else {
				TEMPORARY_TEXT(ident)
				kov_value_stick *kvs = CREATE(kov_value_stick);
				kvs->identifier = Str::new();
				WRITE_TO(kvs->identifier, "KOVP_%d_P%d", w, VanillaObjects::pnum(prop_name));
				kvs->prop = prop_name;
				kvs->kind_name = kind_name;
				kvs->node = X;
				ADD_TO_LINKED_LIST(kvs, kov_value_stick, stick_list);
				Generators::assign_mangled_property(gen, call_it, kvs->identifier, FALSE);
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
		inter_symbol *inst_name = instances_in_declaration_order[j];
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
		inter_symbol *kind_name = kinds_in_declaration_order[i];
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
		inter_symbol *inst_name = instances_in_declaration_order[i];
		inter_tree_node *D = Inter::Symbols::definition(inst_name);
		VanillaObjects::instance(gen, D);
	}

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

The |property_metadata| array is organised as a sequence of variable-sized
records. Because of that, we also need arrays telling us where to find
the start of the record for a given I6 property (or attribute): we have two
of these, called |attributed_property_offsets| and |valued_property_offsets|.
The dummy value |-1| means that the relevant property has no metadata record,
though this won't happen for any property created by I7 source text.

@<Write the property metadata array@> =
	if (no_unassimilated_properties > 0) {
		segmentation_pos saved;
		Generators::begin_array(gen, I"property_metadata", NULL, NULL, WORD_ARRAY_FORMAT, &saved);
		int pos = 0;
		for (int p=0; p<no_unassimilated_properties; p++) {
			inter_symbol *prop_name = props_in_source_order[p];
			if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT))
				Generators::property_offset(gen, Inter::Symbols::name(prop_name), pos, TRUE);
			else
				Generators::property_offset(gen, Inter::Symbols::name(prop_name), pos, FALSE);
			@<Write the property name in double quotes@>;
			@<Write a list of kinds or objects which are permitted to have this property@>;
			Generators::mangled_array_entry(gen, I"NULL", WORD_ARRAY_FORMAT);
			pos++;
		}
		Generators::end_array(gen, WORD_ARRAY_FORMAT, &saved);
	}

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
	for (int e=0; e<no_unassimilated_properties; e++) {
		inter_symbol *eprop_name = props_in_source_order[e];
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
		inter_symbol *kind_name = kinds_in_source_order[k];
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
		inter_symbol *inst_name = instances_in_declaration_order[in];
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
	if (Inter::Symbols::read_annotation(eprop_name, RTO_IANN) < 0) {
		inter_tree_node *X;
		LOOP_THROUGH_INTER_NODE_LIST(X, EVL) {
			inter_symbol *owner_name =
				InterSymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
			if (owner_name == object_kind_symbol) {
				Generators::mangled_array_entry(gen, I"K0_kind", WORD_ARRAY_FORMAT);
				pos++;
				for (int k=0; k<LinkedLists::len(gen->kinds); k++) {
					inter_symbol *kind_name = kinds_in_source_order[k];
					if (Inter::Kind::super(kind_name) == object_kind_symbol) {
						Generators::mangled_array_entry(gen, Inter::Symbols::name(kind_name), WORD_ARRAY_FORMAT);
						pos++;
					}
				}
			}
		}
	}

@ 

@<Stub the properties@> =
	for (int p=0; p<no_unassimilated_properties; p++) {
		inter_symbol *prop_name = props_in_source_order[p];
		if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1) {
			Generators::declare_property(gen, prop_name, FALSE);
		}
	}

@ =
int VanillaObjects::pnum(inter_symbol *prop_name) {
	int N = Inter::Symbols::read_annotation(prop_name, SOURCE_ORDER_IANN);
	if (N >= 0) return N;
	return 0;
}

int VanillaObjects::compare_kind_symbols(const void *elem1, const void *elem2) {
	const inter_symbol **e1 = (const inter_symbol **) elem1;
	const inter_symbol **e2 = (const inter_symbol **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting kinds");
	int s1 = VanillaObjects::kind_sequence_number(*e1);
	int s2 = VanillaObjects::kind_sequence_number(*e2);
	if (s1 != s2) return s1-s2;
	return Inter::Symbols::sort_number(*e1) - Inter::Symbols::sort_number(*e2);
}

int VanillaObjects::compare_kind_symbols_decl(const void *elem1, const void *elem2) {
	const inter_symbol **e1 = (const inter_symbol **) elem1;
	const inter_symbol **e2 = (const inter_symbol **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting kinds");
	int s1 = VanillaObjects::kind_sequence_number_decl(*e1);
	int s2 = VanillaObjects::kind_sequence_number_decl(*e2);
	if (s1 != s2) return s1-s2;
	return Inter::Symbols::sort_number(*e1) - Inter::Symbols::sort_number(*e2);
}

int VanillaObjects::kind_sequence_number(const inter_symbol *kind_name) {
	int N = Inter::Symbols::read_annotation(kind_name, SOURCE_ORDER_IANN);
	if (N >= 0) return N;
	return 100000000;
}

int VanillaObjects::kind_sequence_number_decl(const inter_symbol *kind_name) {
	int N = Inter::Symbols::read_annotation(kind_name, DECLARATION_ORDER_IANN);
	if (N >= 0) return N;
	return 100000000;
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
