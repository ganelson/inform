[CSObjectModel::] C# Object Model.

How objects, classes and properties are compiled to C#.

@h Introduction.

=
void CSObjectModel::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, PSEUDO_OBJECT_MTID, CSObjectModel::pseudo_object);
	METHOD_ADD(gtr, DECLARE_INSTANCE_MTID, CSObjectModel::declare_instance);
	METHOD_ADD(gtr, DECLARE_KIND_MTID, CSObjectModel::declare_kind);

	METHOD_ADD(gtr, DECLARE_PROPERTY_MTID, CSObjectModel::declare_property);
	METHOD_ADD(gtr, ASSIGN_PROPERTY_MTID, CSObjectModel::assign_property);
	METHOD_ADD(gtr, ASSIGN_PROPERTIES_MTID, CSObjectModel::assign_properties);
}

@

@d MAX_CS_OBJECT_TREE_DEPTH 256

=
typedef struct CS_generation_object_model_data {
	int owner_id_count;
	struct CS_property_owner *arrow_chain[MAX_CS_OBJECT_TREE_DEPTH];
	int property_id_counter;
	struct CS_property_owner *current_owner;
	struct dictionary *declared_properties;
	struct linked_list *declared_owners; /* of |CS_property_owner| */
	struct CS_property_owner *compass_instance;
	struct CS_property_owner *direction_kind;
	int value_ranges_needed;
	int value_property_holders_needed;
	int Class_either_or_properties_not_set;
} CS_generation_object_model_data;

void CSObjectModel::initialise_data(code_generation *gen) {
	CS_GEN_DATA(objdata.owner_id_count) = 1;
	CS_GEN_DATA(objdata.property_id_counter) = 0;
	CS_GEN_DATA(objdata.declared_properties) = Dictionaries::new(1024, FALSE);
	CS_GEN_DATA(objdata.declared_owners) = NEW_LINKED_LIST(CS_property_owner);
	for (int i=0; i<128; i++) CS_GEN_DATA(objdata.arrow_chain)[i] = NULL;
	CS_GEN_DATA(objdata.compass_instance) = NULL;
	CS_GEN_DATA(objdata.value_ranges_needed) = FALSE;
	CS_GEN_DATA(objdata.value_property_holders_needed) = FALSE;
	CS_GEN_DATA(objdata.Class_either_or_properties_not_set) = TRUE;
}

void CSObjectModel::begin(code_generation *gen) {
	CSObjectModel::initialise_data(gen);
	CSObjectModel::declare_metaclasses(gen);
}

=

= (text to inform7_cslib.cs)
partial class Story {
	protected internal int i7_max_objects;
	protected internal int i7_no_property_ids;
=

=
void CSObjectModel::end(code_generation *gen) {
	CSObjectModel::write_i7_initialiser(gen);
	CSObjectModel::write_i7_initialise_object_tree(gen);
	CSObjectModel::define_object_value_regions(gen);
	CSObjectModel::compile_ofclass_array(gen);
	CSObjectModel::compile_gprop_functions(gen);
	segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7_max_objects = I7VAL_STRINGS_BASE;\n");
	WRITE("i7_no_property_ids = %d;\n", CS_GEN_DATA(objdata.property_id_counter));
	CodeGen::deselect(gen, saved);
	CSObjectModel::make_enumerated_property_arrays(gen);
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

@ In this C# runtime, |nothing| will be 0, as is mandatory; |Class|, |Object|,
|String| and |Routine| will be 1 to 4 respectively; values from 5 upwards will
be assigned to objects and classes as they arise -- note that these mix freely;
string values will occupy a contiguous range |I7VAL_STRINGS_BASE| to
|I7VAL_FUNCTIONS_BASE-1|; and function values will be in tha range
|I7VAL_FUNCTIONS_BASE| to |0x7FFFFFFF|, though they will certainly not fill it.

= (text to inform7_cslib.cs) 
	protected internal int i7_functions_base;
	protected internal int[] i7_metaclass_of;
	protected internal int[] i7_class_of;
=

=
void CSObjectModel::define_object_value_regions(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, cs_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	int b = CS_GEN_DATA(objdata.owner_id_count);
	WRITE("const int I7VAL_STRINGS_BASE = %d;\n", b);
	WRITE("const int I7VAL_FUNCTIONS_BASE = %d;\n", b + CSLiteralsModel::size_of_String_area(gen));
	CodeGen::deselect(gen, saved);
	saved = CodeGen::select(gen, cs_constructor_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("i7_metaclass_of = new[] {\n"); INDENT;
	WRITE("0\n");
	CS_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, CS_property_owner, CS_GEN_DATA(objdata.declared_owners)) {
		WRITE(", ");
		if (co->is_class) Generators::mangle(gen, OUT, I"Class");
		else Generators::mangle(gen, OUT, I"Object");
		WRITE("\n");
	}
	OUTDENT; WRITE(" };\n");
	WRITE("i7_strings_base = I7VAL_STRINGS_BASE;\n");
	WRITE("i7_functions_base = I7VAL_FUNCTIONS_BASE;\n", b + CSLiteralsModel::size_of_String_area(gen));
	CodeGen::deselect(gen, saved);
}

@ Those decisions give us the following |i7_metaclass| function:

= (text to inform7_cslib.cs)
	protected internal readonly int i7_special_class_Routine;
	protected internal readonly int i7_special_class_String;
	protected internal readonly int i7_special_class_Class;
	protected internal readonly int i7_special_class_Object;
	protected internal int i7_metaclass(int id) {
		if (id <= 0) return 0;
		if (id >= i7_functions_base) return i7_special_class_Routine;
		if (id >= i7_strings_base) return i7_special_class_String;
		return i7_metaclass_of[id];
	}
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
typedef struct CS_property_owner {
	int id;
	int is_class;
	struct text_stream *name;
	struct text_stream *class;
	struct linked_list *property_values; /* of |CS_pv_pair| */
	struct CS_property_owner *initial_parent;
	struct CS_property_owner *initial_sibling;
	struct CS_property_owner *initial_child;
	CLASS_DEFINITION
} CS_property_owner;

CS_property_owner *CSObjectModel::new_owner(code_generation *gen, int id, text_stream *name,
	text_stream *class_name, int is_class) {
	if (Str::len(name) == 0) internal_error("nameless property owner");
	CS_property_owner *co = CREATE(CS_property_owner);
	co->id = id;
	co->name = Str::duplicate(name);
	co->class = Str::duplicate(class_name);
	co->is_class = is_class;
	co->property_values = NEW_LINKED_LIST(CS_pv_pair);
	co->initial_parent = NULL;
	co->initial_sibling = NULL;
	co->initial_child = NULL;
	CS_GEN_DATA(objdata.current_owner) = co;
	ADD_TO_LINKED_LIST(co, CS_property_owner, CS_GEN_DATA(objdata.declared_owners));
	return co;
}

@ The (constant) array |i7_class_of[id]| accepts any ID for a class or instance,
and evaluates to the ID of its classname. So, for example, |i7_class_of[1] == 1|
expresses that the classname of |Class| is |Class| itself. Here we compile
a declaration for that array.

=
void CSObjectModel::compile_ofclass_array(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7_class_of = new[] { 0");
	CS_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, CS_property_owner, CS_GEN_DATA(objdata.declared_owners)) {
		WRITE(", "); Generators::mangle(gen, OUT, co->class);
	}
	WRITE(" };\n");
	CodeGen::deselect(gen, saved);
}

@ The existence of the |i7_class_of| array at runtime makes it possible to
implement the primitive |!ofclass| reasonably efficiently. Note that it may need
to recurse up the class hierarchy. If A is of class B whose superclass is C, then
|i7_ofclass(A, B)| and |i7_ofclass(A, C)| are both true, as it |i7_ofclass(B, C)|.

= (text to inform7_cslib.cs)
partial class Process {
	internal int i7_ofclass(int id, int cl_id) {
		if ((id <= 0) || (cl_id <= 0)) return 0;
		if (id >= story.i7_functions_base) {
			if (cl_id == story.i7_special_class_Routine) return 1;
			return 0;
		}
		if (id >= story.i7_strings_base) {
			if (cl_id == story.i7_special_class_String) return 1;
			return 0;
		}
		if (id == story.i7_special_class_Class) {
			if (cl_id == story.i7_special_class_Class) return 1;
			return 0;
		}
		if (cl_id == story.i7_special_class_Object) {
			if (story.i7_metaclass_of[id] == story.i7_special_class_Object) return 1;
			return 0;
		}
		int cl_found = story.i7_class_of[id];
		while (cl_found != story.i7_special_class_Class) {
			if (cl_id == cl_found) return 1;
			cl_found = story.i7_class_of[cl_found];
		}
		return 0;
	}
=

@ Here we compile code to initialise the tree. This happens in two stages: first
the tree is blanked out so that nothing contains anything else, and that's done
with an unchanging function in the C library:

= (text to inform7_cslib.cs)
	int i7_max_objects;
	int i7_no_property_ids;
	void i7_empty_object_tree() {
		//TODO: move to State?
		i7_max_objects = story.i7_max_objects;
		i7_no_property_ids = story.i7_no_property_ids;
		state.object_tree_parent  = new int[i7_max_objects];
		state.object_tree_child   = new int[i7_max_objects];
		state.object_tree_sibling = new int[i7_max_objects];
		for (int i=0; i<i7_max_objects; i++) {
			state.object_tree_parent[i] = 0;
			state.object_tree_child[i] = 0;
			state.object_tree_sibling[i] = 0;
		}
	}
}
=

@ And secondly, there is dynamic code (i.e. different for different compilations)
to store the initial values as recorded in the |initial_*| fields:

= (text to inform7_cslib.cs)
partial class Story {
	public abstract void i7_initialise_object_tree(Process proc);
}
=

=
void CSObjectModel::write_i7_initialise_object_tree(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, cs_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("override public void i7_initialise_object_tree(Inform.Process proc) {\n"); INDENT;
	CS_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, CS_property_owner, CS_GEN_DATA(objdata.declared_owners)) {
		if (co->initial_parent) {
			WRITE("proc.state.object_tree_parent[");
			Generators::mangle(gen, OUT, co->name);
			WRITE("] = ");
			Generators::mangle(gen, OUT, co->initial_parent->name);
			WRITE(";\n");
		}
		if (co->initial_sibling) {
			WRITE("proc.state.object_tree_sibling[");
			Generators::mangle(gen, OUT, co->name);
			WRITE("] = ");
			Generators::mangle(gen, OUT, co->initial_sibling->name);
			WRITE(";\n");
		}
		if (co->initial_child) {
			WRITE("proc.state.object_tree_child[");
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
void CSObjectModel::declare_metaclasses(code_generation *gen) {
	CSObjectModel::new_runtime_class(gen, I"Class", NULL, I"Class");
	CSObjectModel::new_runtime_class(gen, I"Object", NULL, I"Class");
	CSObjectModel::new_runtime_class(gen, I"String", NULL, I"Class");
	CSObjectModel::new_runtime_class(gen, I"Routine", NULL, I"Class");
}

@ And here is (ii):

=
void CSObjectModel::declare_kind(code_generator *gtr, code_generation *gen, 
	inter_symbol *kind_s, segmentation_pos *saved) {
	if ((kind_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) ||
		(VanillaObjects::is_kind_of_object(gen, kind_s)))
		@<Declare a kind of object@>
	else if (VanillaObjects::value_kind_with_properties(gen, kind_s))
		CSObjectModel::vph_object(gen, kind_s);
}

@<Declare a kind of object@> =
	text_stream *class_name = InterSymbol::trans(kind_s);
	text_stream *printed_name = Metadata::optional_textual(
		InterPackage::container(kind_s->definition), I"^printed_name");
	text_stream *super_class = NULL;
	inter_symbol *super_name = TypenameInstruction::super(kind_s);
	if (super_name) super_class = InterSymbol::trans(super_name);
	if (Str::len(super_class) == 0) super_class = I"Class";
	CSObjectModel::new_runtime_class(gen, class_name, printed_name, super_class);

@ In either case (i) or (ii) the following is called:

=
void CSObjectModel::new_runtime_class(code_generation *gen, text_stream *class_name,
	text_stream *printed_name, text_stream *super_class) {
	int id = CS_GEN_DATA(objdata.owner_id_count)++;
	/* int special_class = Str::eq(class_name, I"Class")  ||
	                    Str::eq(class_name, I"Object") || 
		                Str::eq(class_name, I"String") ||
		                Str::eq(class_name, I"Routine"); */
	segmentation_pos saved = CodeGen::select(gen, /* special_class ? cs_constructor_I7CGS : */ cs_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	/* if (!special_class) */ WRITE("/*nrc1*/const int "); 
	Generators::mangle(gen, OUT, class_name); WRITE(" = %d;\n", id);
	CodeGen::deselect(gen, saved);
	if (printed_name) {
		segmentation_pos saved = CodeGen::select(gen, cs_kinds_symbols_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("/*nrc2*/const int %S = %d;\n", CSTarget::symbols_header_identifier(gen, I"K", printed_name), id);
		CodeGen::deselect(gen, saved);
	}
	CSObjectModel::new_owner(gen, id, class_name, super_class, TRUE);
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
void CSObjectModel::pseudo_object(code_generator *gtr, code_generation *gen, text_stream *obj_name) {
	CS_property_owner *obj = CSObjectModel::new_runtime_object(gtr, gen, I"Object", obj_name, -1, FALSE);
	if (Str::eq(obj_name, I"Compass")) CS_GEN_DATA(objdata).compass_instance = obj;
}

@ Here is (ii). Each enumerated kind produces one of these. In a typical
IF run, for example, there is one for the kind "scene".

=
void CSObjectModel::vph_object(code_generation *gen, inter_symbol *kind_s) {
	TEMPORARY_TEXT(instance_name)
	CSObjectModel::write_vph_identifier(gen, instance_name, kind_s);
	CSObjectModel::new_runtime_object(NULL, gen, I"Object", instance_name, -1, FALSE);
	DISCARD_TEXT(instance_name)
}

@ And here is (iii).

=
void CSObjectModel::declare_instance(code_generator *gtr, code_generation *gen,
	inter_symbol *inst_s, inter_symbol *kind_s, int enumeration, segmentation_pos *ignored_saved) {
	text_stream *printed_name = Metadata::optional_textual(
		InterPackage::container(inst_s->definition), I"^printed_name");
	int is_enumerative = FALSE;
	if ((kind_s == RunningPipelines::get_symbol(gen->from_step, object_kind_RPSYM)) ||
		(VanillaObjects::is_kind_of_object(gen, kind_s))) {
		@<Declare an object instance@>
	} else {
		is_enumerative = TRUE;
		CSObjectModel::define_constant_for_enumeration(gen, kind_s, inst_s, enumeration);
	}
	int seg = (is_enumerative)?cs_enum_symbols_I7CGS:cs_instances_symbols_I7CGS;
	segmentation_pos saved = CodeGen::select(gen, seg);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("/*di*/const int %S = %d;\n",
		CSTarget::symbols_header_identifier(gen, I"I", printed_name), enumeration);
	CodeGen::deselect(gen, saved);
}

@<Declare an object instance@> =
	int c = VanillaObjects::spatial_depth(inst_s);
	int is_dir = TypenameInstruction::is_a(kind_s,
		RunningPipelines::get_symbol(gen->from_step, direction_kind_RPSYM));
	CS_property_owner *owner = CSObjectModel::new_runtime_object(gtr, gen,
		InterSymbol::trans(kind_s), InterSymbol::trans(inst_s), c, is_dir);
	enumeration = owner->id;

@ Whether it's from case (i), (ii) or (iii), we always end up here. Note that
|acount| is negative only in cases (i) and (ii): if it is at least 0, then it
is the "arrow count", that is, its depth in the containment tree. (Calls are
made here in a hierarchical depth-first traverse of the containment tree.)

All direction objects have to be placed in the |Compass| pseudo-object.

=
CS_property_owner *CSObjectModel::new_runtime_object(code_generator *gtr, code_generation *gen,
	text_stream *class_name, text_stream *instance_name, int acount, int is_dir) {
	int id = CS_GEN_DATA(objdata.owner_id_count)++;
	segmentation_pos saved = CodeGen::select(gen, cs_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if (Str::len(instance_name) == 0) internal_error("nameless instance");
	WRITE("/*nro*/const int "); Generators::mangle(gen, OUT, instance_name); WRITE(" = %d;\n", id);
	CodeGen::deselect(gen, saved);
	CS_property_owner *this = CSObjectModel::new_owner(gen, id, instance_name, class_name, FALSE);
	if (acount >= 0) @<Place this in the object containment tree@>;
	return this;
}

@<Place this in the object containment tree@> =
	if (acount >= MAX_CS_OBJECT_TREE_DEPTH) internal_error("arrows too deep");
	CS_property_owner *par = NULL;
	this->initial_parent = NULL;
	if (acount > 0) {
		par = CS_GEN_DATA(objdata.arrow_chain)[acount-1];
		if (par == NULL) internal_error("arrows misaligned");
	} else if (is_dir) {
		par = CS_GEN_DATA(objdata.compass_instance);
	}
	if (par) {
		if (par->initial_child == NULL) {
			par->initial_child = this;
		} else {
			CS_property_owner *older = par->initial_child;
			while ((older) && (older->initial_sibling)) older = older->initial_sibling;
			older->initial_sibling = this;
		}
		this->initial_parent = par;			
	}
	CS_GEN_DATA(objdata.arrow_chain)[acount] = this;
	for (int i=acount+1; i<MAX_CS_OBJECT_TREE_DEPTH; i++)
		CS_GEN_DATA(objdata.arrow_chain)[i] = NULL;

@h The property dictionary.
Each distinct property has a distinct ID. These count upwards from 0, and can
freely overlap with owner IDs or anything else. Their order is not significant.

Properties are recognised here by name, using a dictionary.

=
typedef struct CS_property {
	struct text_stream *name;
	int id;
	int either_or;
	CLASS_DEFINITION
} CS_property;

CS_property *CSObjectModel::property_by_name(code_generation *gen, text_stream *name,
	int either_or) {
	dictionary *D = CS_GEN_DATA(objdata.declared_properties);
	CS_property *cp;
	if (Dictionaries::find(D, name) == NULL) {
		cp = CREATE(CS_property);
		cp->name = Str::duplicate(name);
		cp->either_or = either_or;
		cp->id = CS_GEN_DATA(objdata.property_id_counter)++;
		Dictionaries::create(D, name);
		Dictionaries::write_value(D, name, (void *) cp);
	} else {
		cp = Dictionaries::read_value(D, name);
	}
	return cp;
}

@ =
CS_property *CSObjectModel::existing_property_by_name(code_generation *gen,
	text_stream *name) {
	dictionary *D = CS_GEN_DATA(objdata.declared_properties);
	if (Dictionaries::find(D, name) == NULL) internal_error("no such property");
	return Dictionaries::read_value(D, name);
}

@h Declaring properties.

=
void CSObjectModel::declare_property(code_generator *gtr, code_generation *gen,
	inter_symbol *prop_s, linked_list *all_forms) {
	text_stream *name = InterSymbol::trans(prop_s);
	int either_or = VanillaObjects::is_either_or_property(prop_s);
	CS_property *cp = CSObjectModel::property_by_name(gen, name, either_or);
	text_stream *inner_name = VanillaObjects::inner_property_name(gen, prop_s);

	@<Define the inner name as a constant@>;
	@<Make the opening two metadata array entries required by Vanilla@>;
	@<Define the property name in the symbols header file too@>;
}

@<Define the inner name as a constant@> =
	segmentation_pos saved = CodeGen::select(gen, cs_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("/*dinc*/const int ");
	Generators::mangle(gen, OUT, inner_name);
	WRITE(" = %d;\n", cp->id);
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
	text_stream *pname = Metadata::optional_textual(
		InterPackage::container(prop_s->definition), I"^name");
	if (Str::len(pname) > 0) {
		int A = SymbolAnnotation::get_i(prop_s, C_ARRAY_ADDRESS_IANN);
		if (A > 0) {
			segmentation_pos saved = CodeGen::select(gen, cs_property_symbols_I7CGS);
			text_stream *OUT = CodeGen::current(gen);
			WRITE("/*dpnshf*/const int %S = %d;\n",
				CSTarget::symbols_header_identifier(gen, I"P", pname), A);
			CodeGen::deselect(gen, saved);
		}
	}

@h Assigning properties.
Vabilla calls this to assign a property to a single owner:

=
void CSObjectModel::assign_property(code_generator *gtr, code_generation *gen,
	inter_symbol *prop_s, inter_pair pair, inter_tree_node *X) {

	int inline_this = FALSE;
	if (InterValuePairs::is_symbolic(pair)) {
		inter_symbol *S = InterValuePairs::to_symbol_at(pair, X);
		if (ConstantInstruction::is_inline(S)) inline_this = TRUE;
	}
	TEMPORARY_TEXT(val)
	CodeGen::select_temporary(gen, val);
	CodeGen::pair(gen, X, pair);
	CodeGen::deselect_temporary(gen);
	CS_property_owner *owner = CS_GEN_DATA(objdata.current_owner);
	CS_property *prop = CSObjectModel::existing_property_by_name(gen,
		InterSymbol::trans(prop_s));
	CSObjectModel::assign_one_prop(gen, owner, prop, val, inline_this);
	DISCARD_TEXT(val)
}

@ And it calls this to give an array of the property's values for all of the
instances of a single enumerated kind:

=
void CSObjectModel::assign_properties(code_generator *gtr, code_generation *gen,
	inter_symbol *kind_s, inter_symbol *prop_s, text_stream *array) {
	TEMPORARY_TEXT(mgl)
	Generators::mangle(gen, mgl, array);
	CS_property_owner *owner = CS_GEN_DATA(objdata.current_owner);
	CS_property *prop = CSObjectModel::existing_property_by_name(gen,
		InterSymbol::trans(prop_s));
	CSObjectModel::assign_one_prop(gen, owner, prop, mgl, FALSE);
	DISCARD_TEXT(mgl)
}

@ In either case, the following assigns a property value to an owner, though
all it really does is to stash it away for now:

=
typedef struct CS_pv_pair {
	struct CS_property *prop;
	struct text_stream *val;
	int inlined;
	CLASS_DEFINITION
} CS_pv_pair;

void CSObjectModel::assign_one_prop(code_generation *gen, CS_property_owner *owner,
	CS_property *prop, text_stream *val, int inline_this) {
	CS_pv_pair *pair = CREATE(CS_pv_pair);
	pair->prop = prop;
	pair->val = Str::duplicate(val);
	pair->inlined = inline_this;
	ADD_TO_LINKED_LIST(pair, CS_pv_pair, owner->property_values);
}

@ Creating all those //CS_pv_pair//s was just playing for time, though: eventually
we have to do this --


= (text to inform7_cslib.cs)
partial class Story {
	public abstract void i7_initialiser(Process proc);
}
=

=
void CSObjectModel::write_i7_initialiser(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, cs_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("override public void i7_initialiser(Inform.Process proc) {\n");
	INDENT;
	WRITE("for (int id=0; id<i7_max_objects; id++) {\n"); INDENT;
	WRITE("for (int p=0; p<i7_no_property_ids; p++) {\n"); INDENT;
	WRITE("proc.i7_properties[id] = new Inform.PropertySet();");
	WRITE("proc.i7_properties[id].address[p] = 0;\n");
	WRITE("proc.i7_properties[id].len[p] = 0;\n");
	OUTDENT; WRITE("}\n");
	OUTDENT; WRITE("}\n");
	WRITE("proc.i7_static_himem = i7_static_himem;");
	CS_property_owner *owner;
	LOOP_OVER_LINKED_LIST(owner, CS_property_owner, CS_GEN_DATA(objdata.declared_owners)) {
		CS_pv_pair *vals[1024];
		for (int i=0; i<1024; i++) vals[i] = NULL;
		CSObjectModel::gather_properties_into_array(gen, owner, vals);
		for (int i=0; i<1024; i++) if (vals[i]) {
			CS_pv_pair *pair = vals[i];
			WRITE("proc.i7_properties[");
			Generators::mangle(gen, OUT, owner->name);
			WRITE("].address[proc.i7_read_word(");
			Generators::mangle(gen, OUT, pair->prop->name);
			WRITE(", 1)] = ");
			if (pair->inlined) {
				WRITE("%S;\n", pair->val);
			} else {
				WRITE("%d; // %S\n", CS_GEN_DATA(memdata.himem), pair->val);
				CSMemoryModel::array_entry(NULL, gen, pair->val, WORD_ARRAY_FORMAT);
			}
			WRITE("proc.i7_properties[");
			Generators::mangle(gen, OUT, owner->name);
			WRITE("].len[proc.i7_read_word(");
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

void CSObjectModel::gather_properties_into_array(code_generation *gen,
	CS_property_owner *owner, CS_pv_pair **vals) {
	CS_property_owner *super = NULL;
	CS_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, CS_property_owner, CS_GEN_DATA(objdata.declared_owners)) {
		if (Str::eq(co->name,  owner->class)) { super = co; break; }
	}
	if (Str::eq(owner->name, I"Class"))
		@<Ensure that Class itself has every either-or property, with the value false@>;
	if (super != owner) CSObjectModel::gather_properties_into_array(gen, super, vals);
	CS_pv_pair *pair;
	LOOP_OVER_LINKED_LIST(pair, CS_pv_pair, owner->property_values) {
		vals[pair->prop->id] = pair;
	}
}

@ The import of this is that because every owner's super-owner's super-owner...
and so on ends in |Class|, and because |Class| provides every either-or property,
it follows that every owner provides every either-or property. And in the absence
of any more specific data, it will be initially |false|.

This is not true of other properties, which have different runtime semantics.

@<Ensure that Class itself has every either-or property, with the value false@> =
	if (CS_GEN_DATA(objdata.Class_either_or_properties_not_set)) {
		CS_GEN_DATA(objdata.Class_either_or_properties_not_set) = FALSE;
		CS_property *prop;
		LOOP_OVER(prop, CS_property)
			if (prop->either_or)
				CSObjectModel::assign_one_prop(gen, owner, prop, I"0", FALSE);
	}

@h Instances which are not objects.

=
void CSObjectModel::define_constant_for_enumeration(code_generation *gen,
	inter_symbol *kind_s, inter_symbol *inst_s, int enumeration) {
	TEMPORARY_TEXT(val)
	WRITE_TO(val, "%d", enumeration);
	Generators::declare_constant(gen, inst_s, RAW_GDCFORM, val);
	DISCARD_TEXT(val)
}

void CSObjectModel::write_vph_identifier(code_generation *gen, OUTPUT_STREAM,
	inter_symbol *kind_s) {
	WRITE("VPH_%d", VanillaObjects::weak_id(kind_s));
}

void CSObjectModel::make_enumerated_property_arrays(code_generation *gen) {
	if (CS_GEN_DATA(objdata.value_ranges_needed))
		@<Make the value ranges@>;
	if (CS_GEN_DATA(objdata.value_property_holders_needed))
		@<Make the value property holders@>;
}

@ This is an array indexed by weak kind ID which holds the largest valid value
for an enumerated kind; or just 0 if the kind is not an enumeration.

@<Make the value ranges@> =
	CSMemoryModel::begin_array(NULL, gen, I"value_ranges", NULL, NULL, WORD_ARRAY_FORMAT, -1, NULL);
	CSMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
	inter_symbol *max_weak_id = InterSymbolsTable::URL_to_symbol(gen->from,
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = InterSymbol::evaluate_to_int(max_weak_id);
		for (int w=1; w<M; w++) {
			int written = FALSE;
			inter_symbol *kind_s;
			LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order) {
				if (VanillaObjects::weak_id(kind_s) == w) {
					if (VanillaObjects::value_kind_with_properties(gen, kind_s)) {
						written = TRUE;
						TEMPORARY_TEXT(N)
						WRITE_TO(N, "%d", TypenameInstruction::instance_count(kind_s));
						CSMemoryModel::array_entry(NULL, gen, N, WORD_ARRAY_FORMAT);
						DISCARD_TEXT(N)
					}
				}
			}
			if (written == FALSE)
				CSMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
		}
	}
	CSMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT, -1, NULL);

@ This is an array indexed by weak kind ID which holds the object ID of the
value property holder for an enumerated kind; or just 0 if the kind is not an
enumeration.

@<Make the value property holders@> =
	CSMemoryModel::begin_array(NULL, gen, I"value_property_holders",
		NULL, NULL, WORD_ARRAY_FORMAT, -1, NULL);
	CSMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
	inter_symbol *max_weak_id = InterSymbolsTable::URL_to_symbol(gen->from,
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = InterSymbol::evaluate_to_int(max_weak_id);
		for (int w=1; w<M; w++) {
			int written = FALSE;
			inter_symbol *kind_s;
			LOOP_OVER_LINKED_LIST(kind_s, inter_symbol, gen->kinds_in_declaration_order) {
				if (VanillaObjects::weak_id(kind_s) == w) {
					if (VanillaObjects::value_kind_with_properties(gen, kind_s)) {
						written = TRUE;
						TEMPORARY_TEXT(N)
						CSObjectModel::write_vph_identifier(gen, N, kind_s);
						TEMPORARY_TEXT(M)
						Generators::mangle(gen, M, N);
						CSMemoryModel::array_entry(NULL, gen, M, WORD_ARRAY_FORMAT);
						DISCARD_TEXT(M)
						DISCARD_TEXT(N)
					}
				}
			}
			if (written == FALSE)
				CSMemoryModel::array_entry(NULL, gen, I"0", WORD_ARRAY_FORMAT);
		}
	}
	CSMemoryModel::end_array(NULL, gen, WORD_ARRAY_FORMAT, -1, NULL);

@h Primitives.
The following primitives are all implemented by calling suitable C functions,
which we will then need to write in |inform7_cslib.h|.

For |i7_metaclass|, see //CSObjectModel::define_object_value_regions// above.

=
int CSObjectModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case PROPERTYARRAY_BIP:
			WRITE("proc.i7_prop_addr("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: 
			WRITE("proc.i7_prop_len("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(")"); break;
		case MOVE_BIP:
			WRITE("proc.i7_move("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		case REMOVE_BIP:
			WRITE("proc.i7_move("); VNODE_1C; WRITE(", 0)"); break;
		case CHILD_BIP:
			WRITE("proc.i7_child("); VNODE_1C; WRITE(")"); break;
		case CHILDREN_BIP:
			WRITE("proc.i7_children("); VNODE_1C; WRITE(")"); break;
		case PARENT_BIP:
			WRITE("proc.i7_parent("); VNODE_1C; WRITE(")"); break;
		case SIBLING_BIP:
			WRITE("proc.i7_sibling("); VNODE_1C; WRITE(")"); break;
		case METACLASS_BIP:
			WRITE("i7_metaclass("); VNODE_1C; WRITE(")"); break;
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

Lengths are returned in bytes, not words, hence the multiplication by 4.

= (text to inform7_cslib.cs)

class PropertySet {
	const int I7_MAX_PROPERTY_IDS = 1000;

	internal readonly int[] address = new int[I7_MAX_PROPERTY_IDS];
	internal readonly int[] len = new int[I7_MAX_PROPERTY_IDS];
}

partial class Process {
	internal readonly PropertySet[] i7_properties;

	internal int i7_prop_len(int K, int obj, int pr_array) {
		int pr = i7_read_word(pr_array, 1);
		if ((obj <= 0) || (obj >= i7_max_objects) ||
			(pr < 0) || (pr >= i7_no_property_ids)) return 0;
		return 4*i7_properties[(int) obj].len[(int) pr];
	}

	internal int i7_prop_addr(int K, int obj, int pr_array) {
		int pr = i7_read_word(pr_array, 1);
		if ((obj <= 0) || (obj >= i7_max_objects) ||
			(pr < 0) || (pr >= i7_no_property_ids)) return 0;
		return i7_properties[(int) obj].address[(int) pr];
	}

@ The address array can be used to determine whether a runtime object or class
provides a given property: if the address is nonzero then it does.

= (text to inform7_cslib.cs)
	internal bool i7_provides(int owner_id, int pr_array) {
		int prop_id = i7_read_word(pr_array, 1);
		if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
			(prop_id < 0) || (prop_id >= i7_no_property_ids)) return false;
		while (owner_id != 1) {
			if (i7_properties[(int) owner_id].address[(int) prop_id] != 0) return true;
			owner_id = story.i7_class_of[owner_id];
		}
		return false;
	}
=

@ Now |i7_move|, which moves |obj| in the object tree so that it becomes the
eldest child of |to|, unless |to| is zero, in which case it is removed from
the tree.

= (text to inform7_cslib.cs)
	internal void i7_move(int obj, int to) {
		if ((obj <= 0) || (obj >= i7_max_objects)) return;
		int p = state.object_tree_parent[obj];
		if (p != 0) {
			if (state.object_tree_child[p] == obj) {
				state.object_tree_child[p] = state.object_tree_sibling[obj];
			} else {
				int c = state.object_tree_child[p];
				while (c != 0) {
					if (state.object_tree_sibling[c] == obj) {
						state.object_tree_sibling[c] = state.object_tree_sibling[obj];
						break;
					}
					c = state.object_tree_sibling[c];
				}
			}
		}
		state.object_tree_parent[obj] = to;
		state.object_tree_sibling[obj] = 0;
		if (to != 0) {
			state.object_tree_sibling[obj] = state.object_tree_child[to];
			state.object_tree_child[to] = obj;
		}
	}
=

@ Now the four ways to interrogate the object containment tree:

= (text to inform7_cslib.cs)
	int i7_parent(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		return state.object_tree_parent[id];
	}
	int i7_child(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		return state.object_tree_child[id];
	}
	int i7_children(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		int c=0;
		for (int i=0; i<i7_max_objects; i++)
			if (state.object_tree_parent[i] == id)
				c++;
		return c;
	}
	int i7_sibling(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		return state.object_tree_sibling[id];
	}
=

@ And the implementation of "is |obj1| directly a child of |obj2|?"

= (text to inform7_cslib.cs)
	int i7_in(int obj1, int obj2) {
		if (story.i7_metaclass(obj1) != story.i7_special_class_Object) return 0;
		if (obj2 == 0) return 0;
		if (state.object_tree_parent[obj1] == obj2) return 1;
		return 0;
	}
=

@h Reading, writing and changing object properties.

= (text to inform7_cslib.cs)
	int i7_read_prop_value(int owner_id, int pr_array) {
		int prop_id = i7_read_word(pr_array, 1);
		if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
			(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
		while (i7_properties[(int) owner_id].address[(int) prop_id] == 0) {
			owner_id = story.i7_class_of[owner_id];
			if (owner_id == story.i7_special_class_Class) return 0;
		}
		int address = i7_properties[(int)owner_id].address[(int)prop_id];
		return i7_read_word(address, 0);
	}

	void i7_write_prop_value(int owner_id, int pr_array, int val) {
		int prop_id = i7_read_word(pr_array, 1);
		if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
			(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
			Console.WriteLine("impossible property write ({0:D}, {1:D})", owner_id, prop_id);
			i7_fatal_exit();
		}
		int address = i7_properties[(int) owner_id].address[(int) prop_id];
		if (address != 0) i7_write_word(address, 0, val);
		else {
			Console.WriteLine("impossible property write ({0:D}, {1:D})", owner_id, prop_id);
			i7_fatal_exit();
		}
	}

	int i7_change_prop_value(int obj, int pr,
		int to, int way) {
		int val = i7_read_prop_value(obj, pr), new_val = val;
		switch (way) {
			case i7_lvalue_SET:
				i7_write_prop_value(obj, pr, to); new_val = to; break;
			case i7_lvalue_PREDEC:
				new_val = val-1; i7_write_prop_value(obj, pr, val-1); break;
			case i7_lvalue_POSTDEC:
				new_val = val; i7_write_prop_value(obj, pr, val-1); break;
			case i7_lvalue_PREINC:
				new_val = val+1; i7_write_prop_value(obj, pr, val+1); break;
			case i7_lvalue_POSTINC:
				new_val = val; i7_write_prop_value(obj, pr, val+1); break;
			case i7_lvalue_SETBIT:
				new_val = val | new_val; i7_write_prop_value(obj, pr, new_val); break;
			case i7_lvalue_CLEARBIT:
				new_val = val &(~new_val); i7_write_prop_value(obj, pr, new_val); break;
		}
		return new_val;
	}
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

@ So here are the dynamic wrappers.

=
void CSObjectModel::compile_gprop_functions(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, cs_function_declarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("//#if i7_mgl_OBJECT_TY\n");
	WRITE("int i7_provides_gprop(Inform.Process proc, int K, int obj, int p) {\n");
	WRITE("    return System.Convert.ToInt32(proc.i7_provides_gprop_inner(K, obj, p, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE));\n");
	WRITE("}\n");
	WRITE("int i7_read_gprop_value(Inform.Process proc, int K, int obj, int p) {\n");
	WRITE("    return proc.i7_read_gprop_value_inner(K, obj, p, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE);\n");
	WRITE("}\n");
	WRITE("void i7_write_gprop_value(Inform.Process proc, int K, int obj,\n");
	WRITE("    int p, int val) {\n");
	WRITE("    proc.i7_write_gprop_value_inner(K, obj, p, val, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE);\n");
	WRITE("}\n");
	WRITE("void i7_change_gprop_value(Inform.Process proc, int K, int obj,\n");
	WRITE("    int p, int val, int form) {\n");
	WRITE("    proc.i7_change_gprop_value_inner(K, obj, p, val, form, i7_mgl_OBJECT_TY,\n");
	WRITE("         i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_COL_HSIZE);\n");
	WRITE("}\n");
	WRITE("//#endif\n");
	CodeGen::deselect(gen, saved);
}

@ And these are the static functions in the C library which they call: 

= (text to inform7_cslib.cs)
partial class Process {
	internal bool i7_provides_gprop_inner(int K, int obj, int pr,
		int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		if (K == i7_mgl_OBJECT_TY) {
			if ((((obj != 0) && ((story.i7_metaclass( obj) == story.i7_special_class_Object)))) &&
				(((i7_read_word(pr, 0) == 2) || (i7_provides(obj, pr)))))
				return true;
		} else {
			if ((((obj >= 1)) && ((obj <= i7_read_word(i7_mgl_value_ranges, K))))) {
				int holder = i7_read_word(i7_mgl_value_property_holders, K);
				if (((holder !=0) && ((i7_provides(holder, pr))))) return true;
			}
		}
		return false;
	}

	internal int i7_read_gprop_value_inner(int K, int obj, int pr,
		int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		int val = 0;
		if ((K == i7_mgl_OBJECT_TY)) {
			return (int) i7_read_prop_value(obj, pr);
		} else {
			int holder = i7_read_word(i7_mgl_value_property_holders, K);
			return (int) i7_read_word(
				i7_read_prop_value(holder, pr), (obj + i7_mgl_COL_HSIZE));
		}
		return val;
	}

	internal void i7_write_gprop_value_inner(int K, int obj, int pr,
		int val, int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		if ((K == i7_mgl_OBJECT_TY)) {
			i7_write_prop_value(obj, pr, val);
		} else {
			int holder = i7_read_word(i7_mgl_value_property_holders, K);
			i7_write_word(
				i7_read_prop_value(holder, pr), (obj + i7_mgl_COL_HSIZE), val);
		}
	}

	internal void i7_change_gprop_value_inner(int K, int obj, int pr,
		int val, int form,
		int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		if ((K == i7_mgl_OBJECT_TY)) {
			i7_change_prop_value(obj, pr, val, form);
		} else {
			int holder = i7_read_word(i7_mgl_value_property_holders, K);
			i7_change_word(
				i7_read_prop_value(holder, pr), (obj + i7_mgl_COL_HSIZE), val, form);
		}
	}
}
=
