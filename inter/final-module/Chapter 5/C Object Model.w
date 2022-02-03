[CObjectModel::] C Object Model.

How objects, classes and properties are compiled to C.

@h Introduction.

=
void CObjectModel::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, PSEUDO_OBJECT_MTID, CObjectModel::pseudo_object);
	METHOD_ADD(gtr, DECLARE_INSTANCE_MTID, CObjectModel::declare_instance);
	METHOD_ADD(gtr, DECLARE_KIND_MTID, CObjectModel::declare_kind);

	METHOD_ADD(gtr, DECLARE_PROPERTY_MTID, CObjectModel::declare_property);
	METHOD_ADD(gtr, ASSIGN_PROPERTY_MTID, CObjectModel::assign_property);
	METHOD_ADD(gtr, ASSIGN_PROPERTIES_MTID, CObjectModel::assign_properties);
}

@

@d MAX_C_OBJECT_TREE_DEPTH 256

=
typedef struct C_generation_object_model_data {
	int owner_id_count;
	struct C_property_owner *arrow_chain[MAX_C_OBJECT_TREE_DEPTH];
	int property_id_counter;
	struct C_property_owner *current_owner;
	struct dictionary *declared_properties;
	struct linked_list *declared_owners; /* of |C_property_owner| */
	struct C_property_owner *compass_instance;
	struct C_property_owner *direction_kind;
	int value_ranges_needed;
	int value_property_holders_needed;
	int Class_either_or_properties_not_set;
} C_generation_object_model_data;

void CObjectModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(objdata.owner_id_count) = 1;
	C_GEN_DATA(objdata.property_id_counter) = 0;
	C_GEN_DATA(objdata.declared_properties) = Dictionaries::new(1024, FALSE);
	C_GEN_DATA(objdata.declared_owners) = NEW_LINKED_LIST(C_property_owner);
	for (int i=0; i<128; i++) C_GEN_DATA(objdata.arrow_chain)[i] = NULL;
	C_GEN_DATA(objdata.compass_instance) = NULL;
	C_GEN_DATA(objdata.value_ranges_needed) = FALSE;
	C_GEN_DATA(objdata.value_property_holders_needed) = FALSE;
	C_GEN_DATA(objdata.Class_either_or_properties_not_set) = TRUE;
}

void CObjectModel::begin(code_generation *gen) {
	CObjectModel::initialise_data(gen);
	CObjectModel::declare_metaclasses(gen);
}

void CObjectModel::end(code_generation *gen) {
	CObjectModel::write_i7_initialiser(gen);
	CObjectModel::write_i7_initialise_object_tree(gen);
	CObjectModel::define_object_value_regions(gen);
	CObjectModel::compile_ofclass_array(gen);
	CObjectModel::compile_gprop_functions(gen);
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define i7_max_objects I7VAL_STRINGS_BASE\n");
	WRITE("#define i7_no_property_ids %d\n", C_GEN_DATA(objdata.property_id_counter));
	CodeGen::deselect(gen, saved);
	CObjectModel::make_enumerated_property_arrays(gen);
}

@h The object value-space.
Inter requires that the following values must be distinguishable at runtime:

(a) Instances of object;
(b) Classes, which include kinds of object such as "container", but not other
kinds such as "number";
(c) Constant text values -- note: this does not mean values of the I7 "text"
kind, this means only text literals in Inter;
(d) Functions;
(e) 0, which is also the value of the non-object |nothing|.

Note that there is no requirement for these ranges of value to be contiguous,
or to exhaust the whole range of 32-bit values (and they do not). We provide
a function |i7_metaclass| which returns |Class|, |Object|, |String|, |Routine|
or 0 in cases (a) to (e), or 0 for any values not fitting any of these: this
function implements the |!metaclass| primitive.

@ In this C runtime, |nothing| will be 0, as is mandatory; |Class|, |Object|,
|String| and |Routine| will be 1 to 4 respectively; values from 5 upwards will
be assigned to objects and classes as they arise -- note that these mix freely;
string values will occupy a contiguous range |I7VAL_STRINGS_BASE| to
|I7VAL_FUNCTIONS_BASE-1|; and function values will be in tha range
|I7VAL_FUNCTIONS_BASE| to |0x7FFFFFFF|, though they will certainly not fill it.

=
void CObjectModel::define_object_value_regions(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7word_t i7_metaclass_of[] = {\n"); INDENT;
	WRITE("0\n");
	C_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_owners)) {
		WRITE(", ");
		if (co->is_class) Generators::mangle(gen, OUT, I"Class");
		else Generators::mangle(gen, OUT, I"Object");
		WRITE("\n");
	}
	OUTDENT; WRITE(" };\n");
	int b = C_GEN_DATA(objdata.owner_id_count);
	WRITE("#define I7VAL_STRINGS_BASE %d\n", b);
	WRITE("#define I7VAL_FUNCTIONS_BASE %d\n", b + CLiteralsModel::size_of_String_area(gen));
	CodeGen::deselect(gen, saved);
}

@ Those decisions give us the following |i7_metaclass| function:

= (text to inform7_clib.h)
i7word_t i7_metaclass(i7process_t *proc, i7word_t id);
=

= (text to inform7_clib.c)
i7word_t i7_metaclass(i7process_t *proc, i7word_t id) {
	if (id <= 0) return 0;
	if (id >= I7VAL_FUNCTIONS_BASE) return i7_mgl_Routine;
	if (id >= I7VAL_STRINGS_BASE) return i7_mgl_String;
	return i7_metaclass_of[id];
}
=

@h Property owners.
We use the term "property owner" to mean either a kind of object, or an instance
of object. This is a little loose since instances of enumerated non-object kinds
can also have properties, but those, as we'll later see, are stored quite differently.

Each property owner has a unique ID number. The special ID 0 is reserved for |nothing|,
meaning the absence of such an owner, so we can only use 1 upwards; and as we've seen,
1 to 4 are used for the four metaclasses |Class|, |Object|, |String| and |Routine|.
After that, it's first come, first served.

Each owner has a "class", which is always the name of another owner: except that
the owner |Class| has the class name |Class|, i.e., itself.

Instances, though not of course classes, will also end up as part of an object
containment tree; so we record the initial state of that three here. For classes,
of course, |initial_parent|, |initial_sibling| and |initial_child| will remain |NULL|.

=
typedef struct C_property_owner {
	int id;
	int is_class;
	struct text_stream *name;
	struct text_stream *class;
	struct linked_list *property_values; /* of |C_pv_pair| */
	struct C_property_owner *initial_parent;
	struct C_property_owner *initial_sibling;
	struct C_property_owner *initial_child;
	CLASS_DEFINITION
} C_property_owner;

C_property_owner *CObjectModel::new_owner(code_generation *gen, int id, text_stream *name,
	text_stream *class_name, int is_class) {
	if (Str::len(name) == 0) internal_error("nameless property owner");
	C_property_owner *co = CREATE(C_property_owner);
	co->id = id;
	co->name = Str::duplicate(name);
	co->class = Str::duplicate(class_name);
	co->is_class = is_class;
	co->property_values = NEW_LINKED_LIST(C_pv_pair);
	co->initial_parent = NULL;
	co->initial_sibling = NULL;
	co->initial_child = NULL;
	C_GEN_DATA(objdata.current_owner) = co;
	ADD_TO_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_owners));
	return co;
}

@ The (constant) array |i7_class_of[id]| accepts any ID for a class or instance,
and evaluates to the ID of its classname. So, for example, |i7_class_of[1] == 1|
expresses that the classname of |Class| is |Class| itself. Here we compile
a declaration for that array.

=
void CObjectModel::compile_ofclass_array(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7word_t i7_class_of[] = { 0");
	C_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_owners)) {
		WRITE(", "); Generators::mangle(gen, OUT, co->class);
	}
	WRITE(" };\n");
	CodeGen::deselect(gen, saved);
}

@ The existence of the |i7_class_of| array at runtime makes it possible to
implement the primitive |!ofclass| reasonably efficiently. Note that it may need
to recurse up the class hierarchy. If A is of class B whose superclass is C, then
|i7_ofclass(A, B)| and |i7_ofclass(A, C)| are both true, as it |i7_ofclass(B, C)|.

= (text to inform7_clib.h)
int i7_ofclass(i7process_t *proc, i7word_t id, i7word_t cl_id);
=

= (text to inform7_clib.c)
int i7_ofclass(i7process_t *proc, i7word_t id, i7word_t cl_id) {
	if ((id <= 0) || (cl_id <= 0)) return 0;
	if (id >= I7VAL_FUNCTIONS_BASE) {
		if (cl_id == i7_mgl_Routine) return 1;
		return 0;
	}
	if (id >= I7VAL_STRINGS_BASE) {
		if (cl_id == i7_mgl_String) return 1;
		return 0;
	}
	if (id == i7_mgl_Class) {
		if (cl_id == i7_mgl_Class) return 1;
		return 0;
	}
	if (cl_id == i7_mgl_Object) {
		if (i7_metaclass_of[id] == i7_mgl_Object) return 1;
		return 0;
	}
	int cl_found = i7_class_of[id];
	while (cl_found != i7_mgl_Class) {
		if (cl_id == cl_found) return 1;
		cl_found = i7_class_of[cl_found];
	}
	return 0;
}
=

@ Here we compile code to initialise the tree. This happens in two stages: first
the tree is blanked out so that nothing contains anything else, and that's done
with an unchanging function in the C library:

= (text to inform7_clib.h)
void i7_empty_object_tree(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_empty_object_tree(i7process_t *proc) {
	proc->state.object_tree_parent  = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	proc->state.object_tree_child   = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	proc->state.object_tree_sibling = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	for (int i=0; i<i7_max_objects; i++) {
		proc->state.object_tree_parent[i] = 0;
		proc->state.object_tree_child[i] = 0;
		proc->state.object_tree_sibling[i] = 0;
	}
}
=

@ And secondly, there is dynamic code (i.e. different for different compilations)
to store the initial values as recorded in the |initial_*| fields:

=
void CObjectModel::write_i7_initialise_object_tree(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("void i7_initialise_object_tree(i7process_t *proc) {\n"); INDENT;
	C_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_owners)) {
		if (co->initial_parent) {
			WRITE("proc->state.object_tree_parent[");
			Generators::mangle(gen, OUT, co->name);
			WRITE("] = ");
			Generators::mangle(gen, OUT, co->initial_parent->name);
			WRITE(";\n");
		}
		if (co->initial_sibling) {
			WRITE("proc->state.object_tree_sibling[");
			Generators::mangle(gen, OUT, co->name);
			WRITE("] = ");
			Generators::mangle(gen, OUT, co->initial_sibling->name);
			WRITE(";\n");
		}
		if (co->initial_child) {
			WRITE("proc->state.object_tree_child[");
			Generators::mangle(gen, OUT, co->name);
			WRITE("] = ");
			Generators::mangle(gen, OUT, co->initial_child->name);
			WRITE(";\n");
		}
	}
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);
}

@h Runtime classes.
Classes arise either (i) as one of the four fundamental metaclasses, which
we automatically declare at the start of each run, or (ii) when a kind of
object is declared. Here is (i):

=
void CObjectModel::declare_metaclasses(code_generation *gen) {
	CObjectModel::new_runtime_class(gen, I"Class", NULL, I"Class");
	CObjectModel::new_runtime_class(gen, I"Object", NULL, I"Class");
	CObjectModel::new_runtime_class(gen, I"String", NULL, I"Class");
	CObjectModel::new_runtime_class(gen, I"Routine", NULL, I"Class");
}

@ And here is (ii):

=
void CObjectModel::declare_kind(code_generator *gtr, code_generation *gen, 
	inter_symbol *kind_s, segmentation_pos *saved) {
	if ((kind_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) ||
		(VanillaObjects::is_kind_of_object(gen, kind_s)))
		@<Declare a kind of object@>
	else if (VanillaObjects::value_kind_with_properties(gen, kind_s))
		CObjectModel::vph_object(gen, kind_s);
}

@<Declare a kind of object@> =
	text_stream *class_name = Inter::Symbols::name(kind_s);
	text_stream *printed_name = Metadata::read_optional_textual(
		InterPackage::container(kind_s->definition), I"^printed_name");
	text_stream *super_class = NULL;
	inter_symbol *super_name = Inter::Kind::super(kind_s);
	if (super_name) super_class = Inter::Symbols::name(super_name);
	if (Str::len(super_class) == 0) super_class = I"Class";
	CObjectModel::new_runtime_class(gen, class_name, printed_name, super_class);

@ In either case (i) or (ii) the following is called:

=
void CObjectModel::new_runtime_class(code_generation *gen, text_stream *class_name,
	text_stream *printed_name, text_stream *super_class) {
	int id = C_GEN_DATA(objdata.owner_id_count)++;
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define "); Generators::mangle(gen, OUT, class_name); WRITE(" %d\n", id);
	CodeGen::deselect(gen, saved);
	if (printed_name) {
		segmentation_pos saved = CodeGen::select(gen, c_kinds_symbols_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("#define %S %d\n", CTarget::symbols_header_identifier(gen, I"K", printed_name), id);
		CodeGen::deselect(gen, saved);
	}
	CObjectModel::new_owner(gen, id, class_name, super_class, TRUE);
}

@h Runtime instances.
These arise either (i) as pseudo-objects provided by kits -- the Inform 7
compiler never itself generates pseudo-objects; or (ii) as property-holder
objects to hold the properties of an enumerated non-object kind, where one
such object exists for each such kind; or (iii), the most obvious way, as
the runtime form of instances of Inform 7 objects. For example, the rooms,
things and people of a work of interactive fiction would each be cases of (iii).

Here is (i). After a typical IF run through Inform 7, this produces only
two pseudo-objects, |Compass| and |thedark|.

=
void CObjectModel::pseudo_object(code_generator *gtr, code_generation *gen, text_stream *obj_name) {
	C_property_owner *obj = CObjectModel::new_runtime_object(gtr, gen, I"Object", obj_name, -1, FALSE);
	if (Str::eq(obj_name, I"Compass")) C_GEN_DATA(objdata.compass_instance) = obj;
}

@ Here is (ii). Each enumerated kind produces one of these. In a typical
IF run, for example, there is one for the kind "scene".

=
void CObjectModel::vph_object(code_generation *gen, inter_symbol *kind_s) {
	TEMPORARY_TEXT(instance_name)
	CObjectModel::write_vph_identifier(gen, instance_name, kind_s);
	CObjectModel::new_runtime_object(NULL, gen, I"Object", instance_name, -1, FALSE);
	DISCARD_TEXT(instance_name)
}

@ And here is (iii).

=
void CObjectModel::declare_instance(code_generator *gtr, code_generation *gen,
	inter_symbol *inst_s, inter_symbol *kind_s, int enumeration, segmentation_pos *ignored_saved) {
	text_stream *printed_name = Metadata::read_optional_textual(
		InterPackage::container(inst_s->definition), I"^printed_name");
	int is_enumerative = FALSE;
	if ((kind_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) ||
		(VanillaObjects::is_kind_of_object(gen, kind_s))) {
		@<Declare an object instance@>
	} else {
		is_enumerative = TRUE;
		CObjectModel::define_constant_for_enumeration(gen, kind_s, inst_s, enumeration);
	}
	int seg = (is_enumerative)?c_enum_symbols_I7CGS:c_instances_symbols_I7CGS;
	segmentation_pos saved = CodeGen::select(gen, seg);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n",
		CTarget::symbols_header_identifier(gen, I"I", printed_name), enumeration);
	CodeGen::deselect(gen, saved);
}

@<Declare an object instance@> =
	int c = Inter::Symbols::read_annotation(inst_s, ARROW_COUNT_IANN);
	if (c < 0) c = 0;
	int is_dir = Inter::Kind::is_a(kind_s,
		RunningPipelines::get_symbol(gen->from_step, direction_kind_RPSYM));
	C_property_owner *owner = CObjectModel::new_runtime_object(gtr, gen,
		Inter::Symbols::name(kind_s), Inter::Symbols::name(inst_s), c, is_dir);
	enumeration = owner->id;

@ Whether it's from case (i), (ii) or (iii), we always end up here. Note that
|acount| is negative only in cases (i) and (ii): if it is at least 0, then it
is the "arrow count", that is, its depth in the containment tree. (Calls are
made here in a hierarchical depth-first traverse of the containment tree.)

All direction objects have to be placed in the |Compass| pseudo-object.

=
C_property_owner *CObjectModel::new_runtime_object(code_generator *gtr, code_generation *gen,
	text_stream *class_name, text_stream *instance_name, int acount, int is_dir) {
	int id = C_GEN_DATA(objdata.owner_id_count)++;
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if (Str::len(instance_name) == 0) internal_error("nameless instance");
	WRITE("#define "); Generators::mangle(gen, OUT, instance_name); WRITE(" %d\n", id);
	CodeGen::deselect(gen, saved);
	C_property_owner *this = CObjectModel::new_owner(gen, id, instance_name, class_name, FALSE);
	if (acount >= 0) @<Place this in the object containment tree@>;
	return this;
}

@<Place this in the object containment tree@> =
	if (acount >= MAX_C_OBJECT_TREE_DEPTH) internal_error("arrows too deep");
	C_property_owner *par = NULL;
	this->initial_parent = NULL;
	if (acount > 0) {
		par = C_GEN_DATA(objdata.arrow_chain)[acount-1];
		if (par == NULL) internal_error("arrows misaligned");
	} else if (is_dir) {
		par = C_GEN_DATA(objdata.compass_instance);
	}
	if (par) {
		if (par->initial_child == NULL) {
			par->initial_child = this;
		} else {
			C_property_owner *older = par->initial_child;
			while ((older) && (older->initial_sibling)) older = older->initial_sibling;
			older->initial_sibling = this;
		}
		this->initial_parent = par;			
	}
	C_GEN_DATA(objdata.arrow_chain)[acount] = this;
	for (int i=acount+1; i<MAX_C_OBJECT_TREE_DEPTH; i++)
		C_GEN_DATA(objdata.arrow_chain)[i] = NULL;

@h The property dictionary.
Each distinct property has a distinct ID. These count upwards from 0, and can
freely overlap with owner IDs or anything else. Their order is not significant.

Properties are recognised here by name, using a dictionary.

=
typedef struct C_property {
	struct text_stream *name;
	int id;
	int either_or;
	CLASS_DEFINITION
} C_property;

C_property *CObjectModel::property_by_name(code_generation *gen, text_stream *name,
	int either_or) {
	dictionary *D = C_GEN_DATA(objdata.declared_properties);
	C_property *cp;
	if (Dictionaries::find(D, name) == NULL) {
		cp = CREATE(C_property);
		cp->name = Str::duplicate(name);
		cp->either_or = either_or;
		cp->id = C_GEN_DATA(objdata.property_id_counter)++;
		Dictionaries::create(D, name);
		Dictionaries::write_value(D, name, (void *) cp);
	} else {
		cp = Dictionaries::read_value(D, name);
	}
	return cp;
}

@ =
C_property *CObjectModel::existing_property_by_name(code_generation *gen,
	text_stream *name) {
	dictionary *D = C_GEN_DATA(objdata.declared_properties);
	if (Dictionaries::find(D, name) == NULL) internal_error("no such property");
	return Dictionaries::read_value(D, name);
}

@h Declaring properties.

=
void CObjectModel::declare_property(code_generator *gtr, code_generation *gen,
	inter_symbol *prop_name, linked_list *all_forms) {
	text_stream *name = Inter::Symbols::name(prop_name);
	int either_or = FALSE;
	if (Inter::Symbols::read_annotation(prop_name, EITHER_OR_IANN) == 1) either_or = TRUE;
	C_property *cp = CObjectModel::property_by_name(gen, name, either_or);
	text_stream *inner_name = VanillaObjects::inner_property_name(gen, prop_name);

	@<Define the inner name as a constant@>;
	@<Make the opening two metadata array entries required by Vanilla@>;
	@<Define the property name in the symbols header file too@>;
}

@<Define the inner name as a constant@> =
	segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	Generators::mangle(gen, OUT, inner_name);
	WRITE(" %d\n", cp->id);
	CodeGen::deselect(gen, saved);

@ The Vanilla algorithm says we must make two array entries here, at the start
of the property's runtime metadata array. The Inform 6 generator uses the first
of those entries to say how values of this property are stored at runtime; for
C, though, all properties have the same runtime format, and we don't use the
first entry at all. We'll simply zero it.

But the second entry is the inner property, as with Inform 6.

@<Make the opening two metadata array entries required by Vanilla@> =
	TEMPORARY_TEXT(val)
	WRITE_TO(val, "0");
	Generators::array_entry(gen, val, WORD_ARRAY_FORMAT);
	Str::clear(val);
	Generators::mangle(gen, val, inner_name);
	Generators::array_entry(gen, val, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(val)

@<Define the property name in the symbols header file too@> =
	text_stream *pname = Metadata::read_optional_textual(
		InterPackage::container(prop_name->definition), I"^name");
	if (Str::len(pname) > 0) {
		int A = Inter::Symbols::read_annotation(prop_name, C_ARRAY_ADDRESS_IANN);
		if (A > 0) {
			segmentation_pos saved = CodeGen::select(gen, c_property_symbols_I7CGS);
			text_stream *OUT = CodeGen::current(gen);
			WRITE("#define %S %d\n",
				CTarget::symbols_header_identifier(gen, I"P", pname), A);
			CodeGen::deselect(gen, saved);
		}
	}

@h Assigning properties.
Vabilla calls this to assign a property to a single owner:

=
void CObjectModel::assign_property(code_generator *gtr, code_generation *gen,
	inter_symbol *prop_name, inter_ti val1, inter_ti val2, inter_tree_node *X) {

	int inline_this = FALSE;
	if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *S = InterSymbolsTable::symbol_from_data_pair_at_node(val1, val2, X);
		if ((S) && (Inter::Symbols::read_annotation(S, INLINE_ARRAY_IANN) == 1))
			inline_this = TRUE;
	}	

	TEMPORARY_TEXT(val)
	CodeGen::select_temporary(gen, val);
	CodeGen::pair(gen, X, val1, val2);
	CodeGen::deselect_temporary(gen);
	C_property_owner *owner = C_GEN_DATA(objdata.current_owner);
	C_property *prop = CObjectModel::existing_property_by_name(gen,
		Inter::Symbols::name(prop_name));
	CObjectModel::assign_one_prop(gen, owner, prop, val, inline_this);
	DISCARD_TEXT(val)
}

@ And it calls this to give an array of the property's values for all of the
instances of a single enumerated kind:

=
void CObjectModel::assign_properties(code_generator *gtr, code_generation *gen,
	inter_symbol *kind_s, inter_symbol *prop_name, text_stream *array) {
	TEMPORARY_TEXT(mgl)
	Generators::mangle(gen, mgl, array);
	C_property_owner *owner = C_GEN_DATA(objdata.current_owner);
	C_property *prop = CObjectModel::existing_property_by_name(gen,
		Inter::Symbols::name(prop_name));
	CObjectModel::assign_one_prop(gen, owner, prop, mgl, FALSE);
	DISCARD_TEXT(mgl)
}

@ In either case, the following assigns a property value to an owner, though
all it really does is to stash it away for now:

=
typedef struct C_pv_pair {
	struct C_property *prop;
	struct text_stream *val;
	int inlined;
	CLASS_DEFINITION
} C_pv_pair;

void CObjectModel::assign_one_prop(code_generation *gen, C_property_owner *owner,
	C_property *prop, text_stream *val, int inline_this) {
	C_pv_pair *pair = CREATE(C_pv_pair);
	pair->prop = prop;
	pair->val = Str::duplicate(val);
	pair->inlined = inline_this;
	ADD_TO_LINKED_LIST(pair, C_pv_pair, owner->property_values);
}

@ Creating all those //C_pv_pair//s was just playing for time, though: eventually
we have to do this --

=
void CObjectModel::write_i7_initialiser(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("void i7_initialiser(i7process_t *proc) {\n"); INDENT;
	WRITE("for (int id=0; id<i7_max_objects; id++) {\n"); INDENT;
	WRITE("for (int p=0; p<i7_no_property_ids; p++) {\n"); INDENT;
	WRITE("i7_properties[id].address[p] = 0;\n");
	WRITE("i7_properties[id].len[p] = 0;\n");
	OUTDENT; WRITE("}\n");
	OUTDENT; WRITE("}\n");
	C_property_owner *owner;
	LOOP_OVER_LINKED_LIST(owner, C_property_owner, C_GEN_DATA(objdata.declared_owners)) {
		C_pv_pair *vals[1024];
		for (int i=0; i<1024; i++) vals[i] = NULL;
		CObjectModel::gather_properties_into_array(gen, owner, vals);
		for (int i=0; i<1024; i++) if (vals[i]) {
			C_pv_pair *pair = vals[i];
			WRITE("i7_properties[");
			Generators::mangle(gen, OUT, owner->name);
			WRITE("].address[i7_read_word(proc, ");
			Generators::mangle(gen, OUT, pair->prop->name);
			WRITE(", 1)] = ");
			if (pair->inlined) {
				WRITE("%S;\n", pair->val);
			} else {
				WRITE("%d; // %S\n", C_GEN_DATA(memdata.himem), pair->val);
				CMemoryModel::array_entry(NULL, gen, pair->val, WORD_ARRAY_FORMAT);
			}
			WRITE("i7_properties[");
			Generators::mangle(gen, OUT, owner->name);
			WRITE("].len[i7_read_word(proc, ");
			Generators::mangle(gen, OUT, pair->prop->name);
			WRITE(", 1)] = ");
			if (pair->inlined) {
				WRITE("%S__xt + 1;\n", pair->val);
			} else {
				WRITE("1;\n");
			}
		}
	}
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);
}

void CObjectModel::gather_properties_into_array(code_generation *gen,
	C_property_owner *owner, C_pv_pair **vals) {
	C_property_owner *super = NULL;
	C_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_owners)) {
		if (Str::eq(co->name,  owner->class)) { super = co; break; }
	}
	if (Str::eq(owner->name, I"Class"))
		@<Ensure that Class itself has every either-or property, with the value false@>;
	if (super != owner) CObjectModel::gather_properties_into_array(gen, super, vals);
	C_pv_pair *pair;
	LOOP_OVER_LINKED_LIST(pair, C_pv_pair, owner->property_values) {
		vals[pair->prop->id] = pair;
	}
}

@ The import of this is that because every owner's super-owner's super-owner...
and so on ends in |Class|, and because |Class| provides every either-or property,
it follows that every owner provides every either-or property. And in the absence
of any more specific data, it will be initially |false|.

This is not true of other properties, which have different runtime semantics.

@<Ensure that Class itself has every either-or property, with the value false@> =
	if (C_GEN_DATA(objdata.Class_either_or_properties_not_set)) {
		C_GEN_DATA(objdata.Class_either_or_properties_not_set) = FALSE;
		C_property *prop;
		LOOP_OVER(prop, C_property)
			if (prop->either_or)
				CObjectModel::assign_one_prop(gen, owner, prop, I"0", FALSE);
	}

@h Instances which are not objects.

=
void CObjectModel::define_constant_for_enumeration(code_generation *gen,
	inter_symbol *kind_s, inter_symbol *inst_s, int enumeration) {
	TEMPORARY_TEXT(val)
	WRITE_TO(val, "%d", enumeration);
	Generators::declare_constant(gen, inst_s, RAW_GDCFORM, val);
	DISCARD_TEXT(val)
}

void CObjectModel::write_vph_identifier(code_generation *gen, OUTPUT_STREAM,
	inter_symbol *kind_s) {
	WRITE("VPH_%d", VanillaObjects::weak_id(kind_s));
}

void CObjectModel::make_enumerated_property_arrays(code_generation *gen) {
	if (C_GEN_DATA(objdata.value_ranges_needed))
		@<Make the value ranges@>;
	if (C_GEN_DATA(objdata.value_property_holders_needed))
		@<Make the value property holders@>;
}

@ This is an array indexed by weak kind ID which holds the largest valid value
for an enumerated kind; or just 0 if the kind is not an enumeration.

@<Make the value ranges@> =
	CMemoryModel::begin_array(NULL, gen, I"value_ranges", NULL, NULL, WORD_ARRAY_FORMAT, NULL);
	CMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
	inter_symbol *max_weak_id = InterSymbolsTable::URL_to_symbol(gen->from,
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = Inter::Symbols::evaluate_to_int(max_weak_id);
		for (int w=1; w<M; w++) {
			int written = FALSE;
			inter_symbol *kind_s;
			LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order) {
				if (VanillaObjects::weak_id(kind_s) == w) {
					if (VanillaObjects::value_kind_with_properties(gen, kind_s)) {
						written = TRUE;
						TEMPORARY_TEXT(N)
						WRITE_TO(N, "%d", Inter::Kind::instance_count(kind_s));
						CMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
						DISCARD_TEXT(N)
					}
				}
			}
			if (written == FALSE)
				CMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
		}
	}
	CMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT, NULL);

@ This is an array indexed by weak kind ID which holds the object ID of the
value property holder for an enumerated kind; or just 0 if the kind is not an
enumeration.

@<Make the value property holders@> =
	CMemoryModel::begin_array(NULL, gen, I"value_property_holders",
		NULL, NULL, WORD_ARRAY_FORMAT, NULL);
	CMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
	inter_symbol *max_weak_id = InterSymbolsTable::URL_to_symbol(gen->from,
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = Inter::Symbols::evaluate_to_int(max_weak_id);
		for (int w=1; w<M; w++) {
			int written = FALSE;
			inter_symbol *kind_s;
			LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order) {
				if (VanillaObjects::weak_id(kind_s) == w) {
					if (VanillaObjects::value_kind_with_properties(gen, kind_s)) {
						written = TRUE;
						TEMPORARY_TEXT(N)
						CObjectModel::write_vph_identifier(gen, N, kind_s);
						TEMPORARY_TEXT(M)
						Generators::mangle(gen, M, N);
						CMemoryModel::array_entry(NULL, gen, M, WORD_ARRAY_FORMAT);
						DISCARD_TEXT(M)
						DISCARD_TEXT(N)
					}
				}
			}
			if (written == FALSE)
				CMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
		}
	}
	CMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT, NULL);

@h Primitives.
The following primitives are all implemented by calling suitable C functions,
which we will then need to write in |inform7_clib.h|.

For |i7_metaclass|, see //CObjectModel::define_object_value_regions// above.

=
int CObjectModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case PROPERTYARRAY_BIP:
			WRITE("i7_prop_addr(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: 
			WRITE("i7_prop_len(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(")"); break;
		case MOVE_BIP:
			WRITE("i7_move(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		case REMOVE_BIP:
			WRITE("i7_move(proc, "); VNODE_1C; WRITE(", 0)"); break;
		case CHILD_BIP:
			WRITE("i7_child(proc, "); VNODE_1C; WRITE(")"); break;
		case CHILDREN_BIP:
			WRITE("i7_children(proc, "); VNODE_1C; WRITE(")"); break;
		case PARENT_BIP:
			WRITE("i7_parent(proc, "); VNODE_1C; WRITE(")"); break;
		case SIBLING_BIP:
			WRITE("i7_sibling(proc, "); VNODE_1C; WRITE(")"); break;
		case METACLASS_BIP:
			WRITE("i7_metaclass(proc, "); VNODE_1C; WRITE(")"); break;
		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@ Let's start with property address and property length; while actual property
values live inside process memory, the addresses showing where they are in that
memory, and how many bytes they take up, are held in (static) arrays. Note that
although multiple processes running the same I7 story would have multiple values
for these properties, which likely differ at any given time, they would be at
the same address and of the same length in each. 

= (text to inform7_clib.h)
#define I7_MAX_PROPERTY_IDS 1000
typedef struct i7_property_set {
	i7word_t address[I7_MAX_PROPERTY_IDS];
	i7word_t len[I7_MAX_PROPERTY_IDS];
} i7_property_set;
i7_property_set i7_properties[];

i7word_t i7_prop_addr(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr);
i7word_t i7_prop_len(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr);
=

Lengths are returned in bytes, not words, hence the multiplication by 4.

= (text to inform7_clib.c)
i7_property_set i7_properties[i7_max_objects];

i7word_t i7_prop_len(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr_array) {
	i7word_t pr = i7_read_word(proc, pr_array, 1);
	if ((obj <= 0) || (obj >= i7_max_objects) ||
		(pr < 0) || (pr >= i7_no_property_ids)) return 0;
	return 4*i7_properties[(int) obj].len[(int) pr];
}

i7word_t i7_prop_addr(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr_array) {
	i7word_t pr = i7_read_word(proc, pr_array, 1);
	if ((obj <= 0) || (obj >= i7_max_objects) ||
		(pr < 0) || (pr >= i7_no_property_ids)) return 0;
	return i7_properties[(int) obj].address[(int) pr];
}

@ The address array can be used to determine whether a runtime object or class
provides a given property: if the address is nonzero then it does.

= (text to inform7_clib.h)
int i7_provides(i7process_t *proc, i7word_t owner_id, i7word_t prop_id);
=

= (text to inform7_clib.c)
int i7_provides(i7process_t *proc, i7word_t owner_id, i7word_t pr_array) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (owner_id != 1) {
		if (i7_properties[(int) owner_id].address[(int) prop_id] != 0) return 1;
		owner_id = i7_class_of[owner_id];
	}
	return 0;
}
=

@ Now |i7_move|, which moves |obj| in the object tree so that it becomes the
eldest child of |to|, unless |to| is zero, in which case it is removed from
the tree.

= (text to inform7_clib.h)
void i7_move(i7process_t *proc, i7word_t obj, i7word_t to);
=

= (text to inform7_clib.c)
void i7_move(i7process_t *proc, i7word_t obj, i7word_t to) {
	if ((obj <= 0) || (obj >= i7_max_objects)) return;
	int p = proc->state.object_tree_parent[obj];
	if (p) {
		if (proc->state.object_tree_child[p] == obj) {
			proc->state.object_tree_child[p] = proc->state.object_tree_sibling[obj];
		} else {
			int c = proc->state.object_tree_child[p];
			while (c != 0) {
				if (proc->state.object_tree_sibling[c] == obj) {
					proc->state.object_tree_sibling[c] = proc->state.object_tree_sibling[obj];
					break;
				}
				c = proc->state.object_tree_sibling[c];
			}
		}
	}
	proc->state.object_tree_parent[obj] = to;
	proc->state.object_tree_sibling[obj] = 0;
	if (to) {
		proc->state.object_tree_sibling[obj] = proc->state.object_tree_child[to];
		proc->state.object_tree_child[to] = obj;
	}
}
=

@ Now the four ways to interrogate the object containment tree:

= (text to inform7_clib.h)
i7word_t i7_parent(i7process_t *proc, i7word_t id);
i7word_t i7_child(i7process_t *proc, i7word_t id);
i7word_t i7_children(i7process_t *proc, i7word_t id);
i7word_t i7_sibling(i7process_t *proc, i7word_t id);
=

= (text to inform7_clib.c)
i7word_t i7_parent(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.object_tree_parent[id];
}
i7word_t i7_child(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.object_tree_child[id];
}
i7word_t i7_children(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	i7word_t c=0;
	for (int i=0; i<i7_max_objects; i++)
		if (proc->state.object_tree_parent[i] == id)
			c++;
	return c;
}
i7word_t i7_sibling(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.object_tree_sibling[id];
}
=

@ And the implementation of "is |obj1| directly a child of |obj2|?"

= (text to inform7_clib.h)
int i7_in(i7process_t *proc, i7word_t obj1, i7word_t obj2);
=

= (text to inform7_clib.c)
int i7_in(i7process_t *proc, i7word_t obj1, i7word_t obj2) {
	if (i7_metaclass(proc, obj1) != i7_mgl_Object) return 0;
	if (obj2 == 0) return 0;
	if (proc->state.object_tree_parent[obj1] == obj2) return 1;
	return 0;
}
=

@h Reading, writing and changing object properties.

= (text to inform7_clib.h)
i7word_t i7_read_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t pr_array);
void i7_write_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id, i7word_t val);
i7word_t i7_change_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id,
	i7word_t val, int way);
=

= (text to inform7_clib.c)
i7word_t i7_read_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t pr_array) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (i7_properties[(int) owner_id].address[(int) prop_id] == 0) {
		owner_id = i7_class_of[owner_id];
		if (owner_id == i7_mgl_Class) return 0;
	}
	i7word_t address = i7_properties[(int) owner_id].address[(int) prop_id];
	return i7_read_word(proc, address, 0);
}

void i7_write_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t pr_array, i7word_t val) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
	i7word_t address = i7_properties[(int) owner_id].address[(int) prop_id];
	if (address) i7_write_word(proc, address, 0, val);
	else {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
}

i7word_t i7_change_prop_value(i7process_t *proc, i7word_t obj, i7word_t pr,
	i7word_t to, int way) {
	i7word_t val = i7_read_prop_value(proc, obj, pr), new_val = val;
	switch (way) {
		case i7_lvalue_SET:
			i7_write_prop_value(proc, obj, pr, to); new_val = to; break;
		case i7_lvalue_PREDEC:
			new_val = val-1; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_POSTDEC:
			new_val = val; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_PREINC:
			new_val = val+1; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_POSTINC:
			new_val = val; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_SETBIT:
			new_val = val | new_val; i7_write_prop_value(proc, obj, pr, new_val); break;
		case i7_lvalue_CLEARBIT:
			new_val = val &(~new_val); i7_write_prop_value(proc, obj, pr, new_val); break;
	}
	return new_val;
}
=

@h Reading, writing and changing general properties.
And these are the exactly analogous functions which more generally read, write
or change properties which can be held by either objects or enumerated instances --
in other words, all properties. The additional kind argument |K| is then needed
to distinguish these cases (since the |obj| values for different kinds may well
coincide).

The functions themselves are simple enough, but there is a complication, which
is that they need to use addresses which vary from one compilation to another;
so they cannot be written straightforwardly into our C library, which has to
be the same for all compilations. We get around this by compiling wrapper
functions in our story-file C which supply the necessary information and then
call clumsy but static functions in the C library; but this is all transparent
to the user, who should call only these:

= (text to inform7_clib.h)
int i7_provides_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p);
i7word_t i7_read_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr);
void i7_write_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val);
void i7_change_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val, i7word_t form);
=

@ So here are the dynamic wrappers.

=
void CObjectModel::compile_gprop_functions(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_function_declarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("int i7_provides_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p) {\n");
	WRITE("    return i7_provides_gprop_inner(proc, K, obj, p, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE);\n");
	WRITE("}\n");
	WRITE("i7word_t i7_read_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p) {\n");
	WRITE("    return i7_read_gprop_value_inner(proc, K, obj, p, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE);\n");
	WRITE("}\n");
	WRITE("void i7_write_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj,\n");
	WRITE("    i7word_t p, i7word_t val) {\n");
	WRITE("    i7_write_gprop_value_inner(proc, K, obj, p, val, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE);\n");
	WRITE("}\n");
	WRITE("void i7_change_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj,\n");
	WRITE("    i7word_t p, i7word_t val, i7word_t form) {\n");
	WRITE("    i7_change_gprop_value_inner(proc, K, obj, p, val, form, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE);\n");
	WRITE("}\n");
	CodeGen::deselect(gen, saved);
}

@ And these are the static functions in the C library which they call: 

= (text to inform7_clib.h)
int i7_provides_gprop_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
i7word_t i7_read_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
void i7_write_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val, i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
void i7_change_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val, i7word_t form, i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
=

= (text to inform7_clib.c)
int i7_provides_gprop_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
	if (K == i7_mgl_OBJECT_TY) {
		if ((((obj) && ((i7_metaclass(proc, obj) == i7_mgl_Object)))) &&
			(((i7_read_word(proc, pr, 0) == 2) || (i7_provides(proc, obj, pr)))))
			return 1;
	} else {
		if ((((obj >= 1)) && ((obj <= i7_read_word(proc, i7_mgl_value_ranges, K))))) {
			i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
			if (((holder) && ((i7_provides(proc, holder, pr))))) return 1;
		}
	}
	return 0;
}

i7word_t i7_read_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
	i7word_t val = 0;
    if ((K == i7_mgl_OBJECT_TY)) {
    	return (i7word_t) i7_read_prop_value(proc, obj, pr);
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        return (i7word_t) i7_read_word(proc,
        	i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE));
    }
	return val;
}

void i7_write_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t val, i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
    if ((K == i7_mgl_OBJECT_TY)) {
        i7_write_prop_value(proc, obj, pr, val);
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        i7_write_word(proc,
        	i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE), val);
    }
}

void i7_change_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t val, i7word_t form,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
    if ((K == i7_mgl_OBJECT_TY)) {
        i7_change_prop_value(proc, obj, pr, val, form);
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        i7_change_word(proc,
        	i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE), val, form);
    }
}
=
