[CodeGen::IP::] Instances and Properties.

To generate the initial state of storage for instances and their
properties, and all associated metadata.

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
int FBNA_found = FALSE, properties_found = FALSE, attribute_slots_used = 0;
void CodeGen::IP::property(OUTPUT_STREAM, inter_repository *I, inter_symbol *prop_name, text_stream *attributes) {
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
	inter_frame_list *PL =
		Inter::find_frame_list(
			I,
			Inter::Property::permissions_list(prop_name));
	if (PL == NULL) internal_error("no permissions list");
	inter_frame X;
	LOOP_THROUGH_INTER_FRAME_LIST(X, PL) {
		inter_symbol *owner_name =
			Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope_of(X), X.data[OWNER_PERM_IFLD]);
		if (owner_name == NULL) internal_error("bad owner");
		inter_symbol *owner_kind = NULL;
		if (Inter::Symbols::defining_frame(owner_name).data[ID_IFLD] == INSTANCE_IST) {
			owner_kind = Inter::Instance::kind_of(owner_name);
		} else {
			owner_kind = owner_name;
		}
		if (CodeGen::is_kind_of_object(owner_kind) == FALSE) make_attribute = FALSE;
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
		if (attribute_slots_used++ < ATTRIBUTE_SLOTS_TO_GIVE_AWAY)
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
		if (A == NULL) A = CodeGen::name(prop_name);
		WRITE_TO(attributes, "Attribute %S;\n", A);
	} else {
		if (translated == FALSE)
			WRITE_TO(attributes, "Attribute %S;\n", CodeGen::name(prop_name));
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
	if (FBNA_found == FALSE) {
		FBNA_found = TRUE;
		WRITE_TO(attributes, "Constant FBNA_PROP_NUMBER = %S;\n", CodeGen::name(prop_name));
	}

@ It's unlikely, but just possible, that no FBNAs ever exist, so after the
above has been tried on all properties:

=
void CodeGen::IP::knowledge(OUTPUT_STREAM, inter_repository *I, text_stream *code_at_eof, text_stream *attributes) {
	if ((FBNA_found == FALSE) && (properties_found))
		WRITE_TO(attributes, "Constant FBNA_PROP_NUMBER = MAX_POSITIVE_NUMBER; ! No actual FBNA\n");

	inter_symbol **all_props_in_source_order = NULL;
	inter_symbol **props_in_source_order = NULL;
	int no_properties = 0, total_no_properties = 0;
	@<Make a list of properties in source order@>;
	@<Compile the property numberspace forcer@>;

	inter_symbol **kinds_in_source_order = NULL;
	inter_symbol **kinds_in_declaration_order = NULL;
	int no_kinds = 0;
	@<Make a list of kinds in source order@>;

	inter_symbol **instances_in_declaration_order = NULL;
	int no_instances = 0;
	@<Make a list of instances in declaration order@>;

	if (properties_found) @<Write Value Property Holder objects for each kind of value instance@>;
	@<Make a list of kinds in declaration order@>;
	@<Annotate kinds of object with a sequence counter@>;
	@<Write the KindHierarchy array@>;
	@<Write an I6 Class definition for each kind of object@>;
	@<Write an I6 Object definition for each object instance@>;
	@<Write the property metadata array@>;

	@<Stub the properties@>;
}

@<Make a list of properties in source order@> =
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == PROPERTY_IST) {
			inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
			if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
				total_no_properties++;
			if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
				no_properties++;
		}
	if (no_properties > 0) properties_found = TRUE;

	if (total_no_properties > 0) {
		all_props_in_source_order = (inter_symbol **)
			(Memory::I7_calloc(total_no_properties, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
		int c = 0;
		LOOP_THROUGH_FRAMES(P, I)
			if (P.data[ID_IFLD] == PROPERTY_IST) {
				inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
				if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
					all_props_in_source_order[c++] = prop_name;
				else
					CodeGen::IP::property(OUT, I, prop_name, attributes);
			}
		qsort(all_props_in_source_order, (size_t) total_no_properties, sizeof(inter_symbol *),
			CodeGen::compare_kind_symbols);
		for (int p=0; p<total_no_properties; p++) {
			inter_symbol *prop_name = all_props_in_source_order[p];
			CodeGen::IP::property(OUT, I, prop_name, attributes);
		}
	}

	if (properties_found) {
		props_in_source_order = (inter_symbol **)
			(Memory::I7_calloc(no_properties, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
		int c = 0;
		LOOP_THROUGH_FRAMES(P, I)
			if (P.data[ID_IFLD] == PROPERTY_IST) {
				inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
				if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
					props_in_source_order[c++] = prop_name;
			}

		LOOP_THROUGH_FRAMES(P, I)
			if (P.data[ID_IFLD] == PROPERTY_IST) {
				inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PROP_IFLD);
				if ((Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) == 1) &&
					(Inter::Symbols::read_annotation(prop_name, ATTRIBUTE_IANN) != 1)) {
					// props_in_source_order[c++] = prop_name;
					WRITE_TO(attributes, "Property %S;\n", prop_name->symbol_name);
				}
			}
	}

@<Make a list of kinds in source order@> =
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == KIND_IST)
			no_kinds++;
	if (no_kinds == 0) return;

	kinds_in_source_order = (inter_symbol **)
		(Memory::I7_calloc(no_kinds, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
	int c = 0;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == KIND_IST) {
			inter_symbol *kind_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
			kinds_in_source_order[c++] = kind_name;
		}
	qsort(kinds_in_source_order, (size_t) no_kinds, sizeof(inter_symbol *),
		CodeGen::compare_kind_symbols);

@<Make a list of kinds in declaration order@> =
	inter_frame P;
	kinds_in_declaration_order = (inter_symbol **)
		(Memory::I7_calloc(no_kinds, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
	int c = 0;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == KIND_IST) {
			inter_symbol *kind_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
			kinds_in_declaration_order[c++] = kind_name;
		}
	qsort(kinds_in_declaration_order, (size_t) no_kinds, sizeof(inter_symbol *),
		CodeGen::compare_kind_symbols_decl);

@<Make a list of instances in declaration order@> =
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == INSTANCE_IST)
			no_instances++;
	if (no_instances > 0) {
		instances_in_declaration_order = (inter_symbol **)
			(Memory::I7_calloc(no_instances, sizeof(inter_symbol *), CODE_GENERATION_MREASON));
		int c = 0;
		LOOP_THROUGH_FRAMES(P, I)
			if (P.data[ID_IFLD] == INSTANCE_IST) {
				inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
				instances_in_declaration_order[c++] = inst_name;
			}
		qsort(instances_in_declaration_order, (size_t) no_instances, sizeof(inter_symbol *),
			CodeGen::compare_kind_symbols_decl);
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
	if (properties_found) {
		WRITE("Object property_numberspace_forcer\n"); INDENT;
		for (int p=0; p<no_properties; p++) {
			inter_symbol *prop_name = props_in_source_order[p];
			if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT) == FALSE) {
				inter_symbol *kind_name = Inter::Property::kind_of(prop_name);
				if (kind_name == truth_state_kind_symbol) {
					WRITE("  with %S false\n", CodeGen::name(prop_name));
				}
			}
		}
		OUTDENT; WRITE(";\n");
	}

@<Annotate kinds of object with a sequence counter@> =
	inter_t c = 1;
	for (int i=0; i<no_kinds; i++) {
		inter_symbol *kind_name = kinds_in_source_order[i];
		if (CodeGen::is_kind_of_object(kind_name))
			Inter::Symbols::annotate_i(I, kind_name, OBJECT_KIND_COUNTER_IANN,  c++);
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
	for (int i=0; i<no_kinds; i++) {
		inter_symbol *kind_name = kinds_in_source_order[i];
		if (CodeGen::is_kind_of_object(kind_name)) no_kos++;
	}

	if (no_kos > 0) {
		WRITE("Array KindHierarchy --> K0_kind (0)");
		for (int i=0; i<no_kinds; i++) {
			inter_symbol *kind_name = kinds_in_source_order[i];
			if (CodeGen::is_kind_of_object(kind_name)) {
				inter_symbol *super_name = Inter::Kind::super(kind_name);
				if ((super_name) && (super_name != object_kind_symbol)) {
					WRITE(" %S (%d)", CodeGen::name(kind_name),
						CodeGen::kind_of_object_count(super_name));
				} else {
					WRITE(" %S (0)", CodeGen::name(kind_name));
				}
			}
		}
		WRITE(";\n");
	}

@h Lookup mechanism for properties of value instances.
As noted above, if |K| is a kind which can have properties but is not a subkind
of object, then a property for instances of |K| is stored in an array called
a "stick". At run-time, given the property number and |K|, we will need to find
where in memory the correct stick is, and this needs to be quick.

This is essentially a dictionary lookup problem and we solve it by compiling
a faux object |V| for each |K|, called a "value property holder" or VPH.
Given |K| we find |V| by looking it up in the array

	|value_property_holders|

Once we know |V|, we then look up |V.P| to get the address of the stick for
property |P|, something which the virtual machine can do quickly.

This comes at the cost of several hundred bytes of overhead, which we don't
take lightly in the Z-machine. But speed and flexibility are worth more.

@<Write Value Property Holder objects for each kind of value instance@> =
	@<Define the I6 VPH class@>;
	inter_symbol *max_weak_id = Inter::SymbolsTables::symbol_from_name_in_main(I, I"MAX_WEAK_ID");
	if (max_weak_id) {
		inter_frame P = Inter::Symbols::defining_frame(max_weak_id);
		int M = (int) P.data[DATA_CONST_IFLD + 1];

		@<Decide who gets a VPH@>;
		@<Write the VPH lookup array@>;
		for (int w=1; w<M; w++) {
			for (int i=0; i<no_kinds; i++) {
				inter_symbol *kind_name = kinds_in_source_order[i];
				if (CodeGen::weak_id(kind_name) == w) {
					if (Inter::Symbols::get_flag(kind_name, VPH_MARK_BIT)) {
						TEMPORARY_TEXT(sticks);
						WRITE("VPH_Class VPH_%d\n    with value_range %d\n",
							w, Inter::Kind::instance_count(kind_name));
						for (int p=0; p<no_properties; p++) {
							inter_symbol *prop_name = props_in_source_order[p];
							CodeGen::unmark(prop_name);
						}
						inter_frame_list *FL =
							Inter::find_frame_list(I, Inter::Kind::permissions_list(kind_name));
						@<Work through this frame list of permissions@>;
						for (int in=0; in<no_instances; in++) {
							inter_symbol *inst_name = instances_in_declaration_order[in];
							if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
								inter_frame_list *FL =
									Inter::find_frame_list(I, Inter::Instance::permissions_list(inst_name));
								@<Work through this frame list of permissions@>;
							}
						}
						WRITE(";\n%S\n", sticks);
						DISCARD_TEXT(sticks);
					}
				}
			}
		}
	}

@ It's convenient to be able to distinguish, at run-time, which objects are
the VPH objects used only for kind-property indexing; we can test if |O| is
such an object with the I6 condition |(O ofclass VPH_Class)|.

The property |value_range| for a VPH object is the number |N| such that the
legal values at run-time for this kind are |1, 2, 3, ..., N|: or in other
words, the number of instances of this kind.

@<Define the I6 VPH class@> =
	WRITE("Class VPH_Class;\n");

@<Decide who gets a VPH@> =
	for (int i=0; i<no_kinds; i++) {
		inter_symbol *kind_name = kinds_in_source_order[i];
		if (CodeGen::is_kind_of_object(kind_name)) continue;
		if (kind_name == object_kind_symbol) continue;
		if (kind_name == unchecked_kind_symbol) continue;
		int vph_me = FALSE;
		inter_frame_list *FL =
			Inter::find_frame_list(I, Inter::Kind::permissions_list(kind_name));
		if (FL->first_in_ifl) vph_me = TRUE;
		else for (int in=0; in<no_instances; in++) {
			inter_symbol *inst_name = instances_in_declaration_order[in];
			if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
				inter_frame_list *FL =
					Inter::find_frame_list(I, Inter::Instance::permissions_list(inst_name));
				if (FL->first_in_ifl) vph_me = TRUE;
			}
		}
		if (vph_me) Inter::Symbols::set_flag(kind_name, VPH_MARK_BIT);
	}

@<Look through this frame list of permissions@> =

@ This array is indexed by the weak kind ID of |K|. The entry is 0 if |K|
doesn't have a VPH, or the object number of its VPH if it has.

@<Write the VPH lookup array@> =
	WRITE("Array value_property_holders --> 0");
	int vph = 0;
	for (int w=1; w<M; w++) {
		int written = FALSE;
		for (int i=0; i<no_kinds; i++) {
			inter_symbol *kind_name = kinds_in_source_order[i];
			if (CodeGen::weak_id(kind_name) == w) {
				if (Inter::Symbols::get_flag(kind_name, VPH_MARK_BIT)) {
					written = TRUE;
					WRITE(" VPH_%d", w);
				}
			}
		}
		if (written) vph++; else WRITE(" 0");
	}
	WRITE(";\n");
	@<Stub a faux VPH if none have otherwise been created@>;

@ In the event that no value instances have properties, there'll be no
instances of the |VPH_Class|, and no I6 object will be compiled with a
|value_range| property; that means I6 code referring to this will fail with an
I6 error. We don't want that, so if necessary we compile a useless VPH object
just to force the property into being.

@<Stub a faux VPH if none have otherwise been created@> =
	if (vph == 0) WRITE("VPH_Class UnusedVPH with value_range 0;\n");

@<Work through this frame list of permissions@> =
	inter_frame X;
	LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
		inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
		if (prop_name == NULL) internal_error("no property");
		if (CodeGen::marked(prop_name) == FALSE) {
			CodeGen::mark(prop_name);
			text_stream *call_it = CodeGen::name(prop_name);
			WRITE("    with %S ", call_it);
			if (X.data[STORAGE_PERM_IFLD]) {
				inter_symbol *store = Inter::SymbolsTables::symbol_from_frame_data(X, STORAGE_PERM_IFLD);
				if (store == NULL) internal_error("bad PP in inter");
				WRITE("%S", CodeGen::name(store));
			} else {
				@<Compile a stick of property values and put its address here@>;
			}
			WRITE("\n");
		}
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
	TEMPORARY_TEXT(ident);
	WRITE_TO(ident, "KOVP_%d_P%d", w, CodeGen::pnum(prop_name));
	WRITE("%S", ident);
	WRITE_TO(sticks, "Array %S table 0 0", ident);
	for (int j=0; j<no_instances; j++) {
		inter_symbol *inst_name = instances_in_declaration_order[j];
		if (Inter::Kind::is_a(Inter::Instance::kind_of(inst_name), kind_name)) {
			int found = 0;
			inter_frame_list *PVL =
				Inter::find_frame_list(
					X.repo_segment->owning_repo,
					Inter::Instance::properties_list(inst_name));
			@<Work through this frame list of values@>;
			PVL = Inter::find_frame_list(
					X.repo_segment->owning_repo,
					Inter::Kind::properties_list(kind_name));
			@<Work through this frame list of values@>;
			if (found == 0) WRITE_TO(sticks, " (0)");
		}
	}
	WRITE_TO(sticks, ";\n");

@<Work through this frame list of values@> =
	inter_frame Y;
	LOOP_THROUGH_INTER_FRAME_LIST(Y, PVL) {
		inter_symbol *p_name = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope_of(Y), Y.data[PROP_PVAL_IFLD]);
		if ((p_name == prop_name) && (found == 0)) {
			found = 1;
			inter_t v1 = Y.data[DVAL1_PVAL_IFLD];
			inter_t v2 = Y.data[DVAL2_PVAL_IFLD];
			WRITE_TO(sticks, " (");
			CodeGen::literal(sticks, I, NULL, Inter::Packages::scope_of(Y), v1, v2, FALSE);
			WRITE_TO(sticks, ")");
		}
	}

@<Write an I6 Class definition for each kind of object@> =
	for (int i=0; i<no_kinds; i++) {
		inter_symbol *kind_name = kinds_in_declaration_order[i];
		if ((kind_name == object_kind_symbol) ||
			(CodeGen::is_kind_of_object(kind_name))) {
			WRITE("Class %S\n", CodeGen::name(kind_name));
			inter_symbol *super_name = Inter::Kind::super(kind_name);
			if (super_name) WRITE("    class %S\n", CodeGen::name(super_name));
			CodeGen::append(OUT, kind_name);
			inter_frame_list *FL =
				Inter::find_frame_list(I, Inter::Kind::properties_list(kind_name));
			CodeGen::IP::plist(OUT, I, FL);
			WRITE(";\n\n");
		}
	}

@<Write an I6 Object definition for each object instance@> =
	for (int i=0; i<no_instances; i++) {
		inter_symbol *inst_name = instances_in_declaration_order[i];
		CodeGen::IP::object_instance(OUT, I, Inter::Symbols::defining_frame(inst_name));
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
	if (properties_found) {
		TEMPORARY_TEXT(pm_writer);
		WRITE_TO(pm_writer, "[ CreatePropertyOffsets i;\n"); STREAM_INDENT(pm_writer);
		WRITE_TO(pm_writer, "for (i=0: i<attributed_property_offsets_SIZE: i++)"); STREAM_INDENT(pm_writer);
		WRITE_TO(pm_writer, "attributed_property_offsets-->i = -1;\n"); STREAM_OUTDENT(pm_writer);
		WRITE_TO(pm_writer, "for (i=0: i<valued_property_offsets_SIZE: i++)"); STREAM_INDENT(pm_writer);
		WRITE_TO(pm_writer, "valued_property_offsets-->i = -1;\n"); STREAM_OUTDENT(pm_writer);

		WRITE("Array property_metadata -->\n"); INDENT;
		int pos = 0;
		for (int p=0; p<no_properties; p++) {
			inter_symbol *prop_name = props_in_source_order[p];
			WRITE("! offset %d: property %S\n", pos, CodeGen::name(prop_name));
			if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT))
				WRITE_TO(pm_writer, "attributed_property_offsets");
			else
				WRITE_TO(pm_writer, "valued_property_offsets");
			WRITE_TO(pm_writer, "-->%S = %d;\n", CodeGen::name(prop_name), pos);

			@<Write the property name in double quotes@>;
			@<Write a list of kinds or objects which are permitted to have this property@>;
			WRITE("NULL\n"); pos++;
		}
		OUTDENT; WRITE(";\n");
		STREAM_OUTDENT(pm_writer);
		WRITE_TO(pm_writer, "];\n");
		WRITE("%S", pm_writer);
		DISCARD_TEXT(pm_writer);
	}

@<Write the property name in double quotes@> =
	WRITE("\"");
	int N = Inter::Symbols::read_annotation(prop_name, PROPERTY_NAME_IANN);
	if (N <= 0) WRITE("<nameless>");
	else WRITE("%S", Inter::get_text(I, (inter_t) N));
	WRITE("\" ");
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
	for (int e=0; e<no_properties; e++) {
		inter_symbol *eprop_name = props_in_source_order[e];
		if (Str::eq(CodeGen::name(eprop_name), CodeGen::name(prop_name))) {
			inter_frame_list *EVL =
				Inter::find_frame_list(I, Inter::Property::permissions_list(eprop_name));

			@<List any O with an explicit permission@>;
			@<List all top-level kinds if "object" itself has an explicit permission@>;
		}
	}

@<List any O with an explicit permission@> =
	for (int k=0; k<no_kinds; k++) {
		inter_symbol *kind_name = kinds_in_source_order[k];
		if (CodeGen::is_kind_of_object(kind_name)) {
			inter_frame X;
			LOOP_THROUGH_INTER_FRAME_LIST(X, EVL) {
				inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				if (owner_name == kind_name) {
					WRITE("%S ", CodeGen::name(kind_name));
					pos++;
				}
			}
		}
	}
	for (int in=0; in<no_instances; in++) {
		inter_symbol *inst_name = instances_in_declaration_order[in];
		if (CodeGen::is_kind_of_object(Inter::Instance::kind_of(inst_name))) {
			inter_frame X;
			LOOP_THROUGH_INTER_FRAME_LIST(X, EVL) {
				inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				if (owner_name == inst_name) {
					WRITE("%S ", CodeGen::name(inst_name));
					pos++;
				}
			}
		}
	}

@<List all top-level kinds if "object" itself has an explicit permission@> =
	if (Inter::Symbols::read_annotation(eprop_name, RTO_IANN) < 0) {
		inter_frame X;
		LOOP_THROUGH_INTER_FRAME_LIST(X, EVL) {
			inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
			if (owner_name == object_kind_symbol) {
				for (int k=0; k<no_kinds; k++) {
					inter_symbol *kind_name = kinds_in_source_order[k];
					if (Inter::Kind::super(kind_name) == object_kind_symbol) {
						WRITE("%S ", CodeGen::name(kind_name));
						pos++;
					}
				}
			}
		}
	}

@ Because in I6 source code properties aren't declared before use, it follows
that if not used by any object then they won't ever be created. This is a
problem since it means that I6 code can't refer to them, because it would need
to mention an I6 symbol which doesn't exist. To get around this, we create the
property names which don't exist as constant symbols with the harmless value
0; we do this right at the end of the compiled I6 code. (This is a standard I6
trick called "stubbing", these being "stub definitions".)

@<Stub the properties@> =
	for (int p=0; p<no_properties; p++) {
		inter_symbol *prop_name = props_in_source_order[p];
		text_stream *name = CodeGen::name(prop_name);
		if (Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) != 1)
			WRITE_TO(code_at_eof, "#ifndef %S; Constant %S = 0; #endif;\n", name, name);
	}

@h Instances.

=
void CodeGen::IP::instance(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
	inter_symbol *inst_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_INST_IFLD);

	if (Inter::Kind::is_a(inst_kind, object_kind_symbol) == FALSE) {
		inter_t val1 = P.data[VAL1_INST_IFLD];
		inter_t val2 = P.data[VAL2_INST_IFLD];
		WRITE("Constant %S", CodeGen::name(inst_name));
		if (val1 != UNDEF_IVAL) {
			WRITE(" = ");
			int hex = FALSE;
			for (int i=0; i<inst_name->no_symbol_annotations; i++)
				if (inst_name->symbol_annotations[i].annot->annotation_ID == HEX_IANN)
					hex = TRUE;
			if (hex) WRITE("$%x", val2);
			else WRITE("%d", val2);
		}
		WRITE(";\n");
	}
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
void CodeGen::IP::object_instance(OUTPUT_STREAM, inter_repository *I, inter_frame P) {
	inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
	inter_symbol *inst_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_INST_IFLD);

	if (Inter::Kind::is_a(inst_kind, object_kind_symbol)) {
		WRITE("Object ");
		int c = 0;
		for (int i=0; i<inst_name->no_symbol_annotations; i++)
			if (inst_name->symbol_annotations[i].annot->annotation_ID == ARROW_COUNT_IANN)
				c = (int) inst_name->symbol_annotations[i].annot_value;
		for (int i=0; i<c; i++) WRITE("-> ");
		WRITE("%S \"\"", CodeGen::name(inst_name));
		if (Inter::Kind::is_a(inst_kind, direction_kind_symbol)) { WRITE(" Compass"); }
		WRITE("\n    class %S\n", CodeGen::name(inst_kind));
		CodeGen::append(OUT, inst_name);
		inter_frame_list *FL =
			Inter::find_frame_list(
				P.repo_segment->owning_repo,
				Inter::Instance::properties_list(inst_name));
		CodeGen::IP::plist(OUT, I, FL);
		WRITE(";\n\n");
	}
}

void CodeGen::IP::plist(OUTPUT_STREAM, inter_repository *I, inter_frame_list *FL) {
	if (FL == NULL) internal_error("no properties list");
	inter_frame X;
	LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
		inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PVAL_IFLD);
		if (prop_name == NULL) internal_error("no property");
		text_stream *call_it = CodeGen::name(prop_name);
		if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT)) {
			char *maybe = "";
			if ((X.data[DVAL1_PVAL_IFLD] == LITERAL_IVAL) &&
				(X.data[DVAL2_PVAL_IFLD] == 0)) maybe = "~";
			WRITE("    has %s%S\n", maybe, call_it);
		} else {
			WRITE("    with %S ", call_it);
			int done = FALSE;
			if (Inter::Symbols::is_stored_in_data(X.data[DVAL1_PVAL_IFLD], X.data[DVAL2_PVAL_IFLD])) {
				inter_symbol *S = Inter::SymbolsTables::symbol_from_data_pair_and_frame(X.data[DVAL1_PVAL_IFLD], X.data[DVAL2_PVAL_IFLD], X);
				if ((S) && (Inter::Symbols::read_annotation(S, INLINE_ARRAY_IANN) == 1)) {
					inter_frame P = Inter::Symbols::defining_frame(S);
					for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
						if (i>DATA_CONST_IFLD) WRITE(" ");
						CodeGen::literal(OUT, I, NULL, Inter::Packages::scope_of(P), P.data[i], P.data[i+1], FALSE);
					}
					done = TRUE;
				}
			}
			if (done == FALSE)
				CodeGen::literal(OUT, I, NULL, Inter::Packages::scope_of(X),
					X.data[DVAL1_PVAL_IFLD], X.data[DVAL2_PVAL_IFLD], FALSE);
			WRITE("\n");
		}
	}
}
