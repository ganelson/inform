[CObjectModel::] C Object Model.

How objects, classes and properties are compiled to C.

@h Setting up the model.

=
void CObjectModel::initialise(code_generator *cgt) {
	METHOD_ADD(cgt, PSEUDO_OBJECT_MTID, CObjectModel::pseudo_object);
	METHOD_ADD(cgt, DECLARE_INSTANCE_MTID, CObjectModel::declare_instance);
	METHOD_ADD(cgt, END_INSTANCE_MTID, CObjectModel::end_instance);
	METHOD_ADD(cgt, DECLARE_VALUE_INSTANCE_MTID, CObjectModel::declare_value_instance);
	METHOD_ADD(cgt, DECLARE_CLASS_MTID, CObjectModel::declare_class);
	METHOD_ADD(cgt, END_CLASS_MTID, CObjectModel::end_class);

	METHOD_ADD(cgt, DECLARE_PROPERTY_MTID, CObjectModel::declare_property);
	METHOD_ADD(cgt, PROPERTY_OFFSET_MTID, CObjectModel::property_offset);
	METHOD_ADD(cgt, OPTIMISE_PROPERTY_MTID, CObjectModel::optimise_property_value);
	METHOD_ADD(cgt, ASSIGN_PROPERTY_MTID, CObjectModel::assign_property);
}

typedef struct C_generation_object_model_data {
	int owner_id_count;
	struct C_property_owner *arrow_chain[128];
	int property_id_counter;
	int C_property_offsets_made;
	struct C_property_owner *current_owner;
	struct dictionary *declared_properties;
	struct linked_list *declared_objects; /* of |C_property_owner| */
	struct C_property_owner *compass_instance;
	struct C_property_owner *direction_kind;
	int inline_this;
	struct dictionary *header_constants;
} C_generation_object_model_data;

typedef struct C_property_owner {
	struct text_stream *name;
	struct text_stream *class;
	struct text_stream *identifier;
	struct linked_list *property_values;
	struct C_property_owner *initial_parent;
	struct C_property_owner *initial_sibling;
	struct C_property_owner *initial_child;
	int is_class;
	int id;
	CLASS_DEFINITION
} C_property_owner;

void CObjectModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(objdata.owner_id_count) = 0;
	C_GEN_DATA(objdata.property_id_counter) = 0;
	C_GEN_DATA(objdata.C_property_offsets_made) = 0;
	C_GEN_DATA(objdata.declared_properties) = Dictionaries::new(1024, FALSE);
	C_GEN_DATA(objdata.inline_this) = FALSE;
	C_GEN_DATA(objdata.declared_objects) = NEW_LINKED_LIST(C_property_owner);
	for (int i=0; i<128; i++) C_GEN_DATA(objdata.arrow_chain)[i] = NULL;
	C_GEN_DATA(objdata.compass_instance) = NULL;
	C_GEN_DATA(objdata.header_constants) = Dictionaries::new(1024, TRUE);
}

void CObjectModel::begin(code_generation *gen) {
	CObjectModel::initialise_data(gen);
	@<Begin the initialiser function@>;
	CObjectModel::property_by_name(gen, I"value_range", FALSE);
}

void CObjectModel::end(code_generation *gen) {
	CObjectModel::write_property_values_table(gen);
	@<Complete the initialiser function@>;
	@<Complete the property-offset creator function@>;
	@<Predeclare the object count and class array@>;
}

@h Owners.
In this model, every class and every instance are represented by one "owner
object" each. These owner objects own properties, as we shall see. Each has
a name, an ID number, and a "class name", which is always the name of another
owner: except that the owner |Class| has the class name |Class|, i.e., itself.

Here we create an owner. They are listed in a dynamically resized array in
the model data:

=
C_property_owner *CObjectModel::assign_owner(code_generation *gen, int id, text_stream *name,
	text_stream *class_name, int is_class) {
	C_property_owner *co = CREATE(C_property_owner);
	if (Str::len(name) == 0) internal_error("nameless instance");
	co->name = Str::duplicate(name);
	co->class = Str::duplicate(class_name);
	co->is_class = is_class;
	co->property_values = NEW_LINKED_LIST(C_pv_pair);
	co->initial_parent = NULL;
	co->initial_sibling = NULL;
	co->initial_child = NULL;
	co->identifier = Str::new(); CNamespace::mangle(NULL, co->identifier, co->name);
	co->id = id;
	C_GEN_DATA(objdata.current_owner) = co;
	ADD_TO_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_objects));
	return co;
}

@h Owner IDs.
At runtime, an ID number uniquely identifies possible owners of properties.
The special ID 0 is reserved for |nothing|, meaning the absence of such an
owner, so we can only use 1 upwards.

The four metaclasses |Class|, |Object|, |String|, |Routine| will get IDs 1
to 4. Those are not classes in the Inter tree, and must therefore be created
here as special cases. After that, it's first come, first served.

=
int CObjectModel::next_owner_id(code_generation *gen) {
	C_GEN_DATA(objdata.owner_id_count)++;
	if (C_GEN_DATA(objdata.owner_id_count) == 1) {
		CObjectModel::declare_class_inner(gen, I"Class", NULL, 1, I"Class");
		C_GEN_DATA(objdata.owner_id_count)++;
		CObjectModel::declare_class_inner(gen, I"Object", NULL, 2, I"Class");
		C_GEN_DATA(objdata.owner_id_count)++;
		CObjectModel::declare_class_inner(gen, I"String", NULL, 3, I"Class");
		C_GEN_DATA(objdata.owner_id_count)++;
		CObjectModel::declare_class_inner(gen, I"Routine", NULL, 4, I"Class");
		C_GEN_DATA(objdata.owner_id_count)++;
	}
	return C_GEN_DATA(objdata.owner_id_count);
}

@ The (constant) array |i7_class_of[id]| accepts any ID for a class or instance,
and evaluates to the ID of its classname. So, for example, |i7_class_of[1] == 1|
expresses that the classname of |Class| is |Class| itself. Here we compile
a declaration for that array.

ID numbers above our range used for classes and instances are reserved for
double-quoted literal strings, and then for functions. Thus, each distinct
literal string, and each distinct function, has an ID; and none of these IDs
overlap.

@<Predeclare the object count and class array@> =
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);

	WRITE("#define i7_max_objects %d\n", C_GEN_DATA(objdata.owner_id_count) + 1);

	WRITE("i7word_t i7_metaclass_of[] = { 0");
	C_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_objects)) {
		if (co->is_class) WRITE(", i7_mgl_Class");
		else WRITE(", i7_mgl_Object");
	}
	WRITE(" };\n");

	WRITE("i7word_t i7_class_of[] = { 0");
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_objects)) {
		WRITE(", "); CNamespace::mangle(NULL, OUT, co->class);
	}
	WRITE(" };\n");

	WRITE("#define I7VAL_STRINGS_BASE %d\n", C_GEN_DATA(objdata.owner_id_count) + 1);
	WRITE("#define I7VAL_FUNCTIONS_BASE %d\n",
		C_GEN_DATA(objdata.owner_id_count) + 1 + CLiteralsModel::no_strings(gen));

	WRITE("#define i7_no_property_ids %d\n", C_GEN_DATA(objdata.property_id_counter));
	CodeGen::deselect(gen, saved);

@h Class and instance declarations.
Each proper base kind in the Inter tree produces an owner as follows:

=
void CObjectModel::declare_class(code_generator *cgt, code_generation *gen,
	text_stream *class_name, text_stream *printed_name, text_stream *super_class, segmentation_pos *saved) {
	*saved = CodeGen::select(gen, c_main_matter_I7CGS);
	if (Str::len(super_class) == 0) super_class = I"Class";
	CObjectModel::declare_class_inner(gen, class_name, printed_name,
		CObjectModel::next_owner_id(gen), super_class);
}

void CObjectModel::end_class(code_generator *cgt, code_generation *gen, text_stream *class_name, segmentation_pos saved) {
	CodeGen::deselect(gen, saved);
}

void CObjectModel::declare_class_inner(code_generation *gen,
	text_stream *class_name, text_stream *printed_name, int id, text_stream *super_class) {
	CObjectModel::define_constant_for_owner_id(gen, class_name, id);
	if (printed_name) CObjectModel::define_header_constant_for_kind(gen, class_name, printed_name, id);
	CObjectModel::assign_owner(gen, id, class_name, super_class, TRUE);
}

@ And each instance here:

=
void CObjectModel::pseudo_object(code_generator *cgt, code_generation *gen, text_stream *obj_name) {
	segmentation_pos saved;
	C_property_owner *obj = CObjectModel::declare_instance(cgt, gen, I"Object", obj_name, obj_name, -1, FALSE, &saved);
	CodeGen::deselect(gen, saved);
	if (Str::eq(obj_name, I"Compass")) C_GEN_DATA(objdata.compass_instance) = obj;
}

C_property_owner *CObjectModel::declare_instance(code_generator *cgt, code_generation *gen,
	text_stream *class_name, text_stream *instance_name, text_stream *printed_name, int acount, int is_dir, segmentation_pos *saved) {
	*saved = CodeGen::select(gen, c_main_matter_I7CGS);
	if (Str::len(instance_name) == 0) internal_error("nameless instance");
	int id = CObjectModel::next_owner_id(gen);
	CObjectModel::define_constant_for_owner_id(gen, instance_name, id);
	if (printed_name) {
		TEMPORARY_TEXT(val)
		WRITE_TO(val, "%d", id);
		CObjectModel::define_header_constant_for_instance(gen, instance_name, printed_name, val, FALSE);
		DISCARD_TEXT(val)
	}
	C_property_owner *this = CObjectModel::assign_owner(gen, id, instance_name, class_name, FALSE);
	if (acount >= 0) {
		this->initial_parent = NULL;
		if (acount > 0) {
			C_property_owner *par = C_GEN_DATA(objdata.arrow_chain)[acount-1];
			if (par == NULL) internal_error("arrows misaligned");
			if (par->initial_child == NULL) {
				par->initial_child = this;
			} else {
				C_property_owner *older = par->initial_child;
				while ((older) && (older->initial_sibling)) older = older->initial_sibling;
				older->initial_sibling = this;
			}
			this->initial_parent = par;
		} else if (is_dir) {
			C_property_owner *par = C_GEN_DATA(objdata.compass_instance);
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
		}
		C_GEN_DATA(objdata.arrow_chain)[acount] = this;
		for (int i=acount+1; i<128; i++) C_GEN_DATA(objdata.arrow_chain)[i] = NULL;
	}
	return this;
}

void CObjectModel::end_instance(code_generator *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name, segmentation_pos saved) {
	CodeGen::deselect(gen, saved);
}

void CObjectModel::declare_value_instance(code_generator *cgt,
	code_generation *gen, text_stream *instance_name, text_stream *printed_name, text_stream *val) {
	Generators::declare_constant(gen, instance_name, NULL, RAW_GDCFORM, NULL, val, FALSE);
	CObjectModel::define_header_constant_for_instance(gen, instance_name, printed_name, val, TRUE);
}

@ So it is finally time to compile a |#define| for the owner's identifier,
defining this as a constant equal to its ID.

=
void CObjectModel::define_constant_for_owner_id(code_generation *gen, text_stream *owner_name,
	int id) {
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define "); CNamespace::mangle(NULL, OUT, owner_name); WRITE(" %d\n", id);
	CodeGen::deselect(gen, saved);
}

text_stream *CObjectModel::new_header_name(code_generation *gen, text_stream *prefix, text_stream *raw) {
	dictionary *D = C_GEN_DATA(objdata.header_constants);
	text_stream *key = Str::new();
	WRITE_TO(key, "i7_%S_", prefix);
	LOOP_THROUGH_TEXT(pos, raw)
		if (Characters::isalnum(Str::get(pos)))
			PUT_TO(key, Str::get(pos));
		else
			PUT_TO(key, '_');
	text_stream *dv = Dictionaries::get_text(D, key);
	if (dv) {
		TEMPORARY_TEXT(keyx)
		int n = 2;
		while (TRUE) {
			Str::clear(keyx);
			WRITE_TO(keyx, "%S_%d", key, n);
			if (Dictionaries::get_text(D, keyx) == NULL) break;
			n++;
		}
		DISCARD_TEXT(keyx)
		WRITE_TO(key, "_%d", n);
	}
	Dictionaries::create_text(D, key);
	return key;
}

void CObjectModel::define_header_constant_for_instance(code_generation *gen, text_stream *owner_name,
	text_stream *printed_name, text_stream *val, int enumerated) {
	int seg = (enumerated)?c_enum_symbols_I7CGS:c_instances_symbols_I7CGS;
	segmentation_pos saved = CodeGen::select(gen, seg);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %S\n", CObjectModel::new_header_name(gen, I"I", printed_name), val);
	CodeGen::deselect(gen, saved);
}

void CObjectModel::define_header_constant_for_kind(code_generation *gen, text_stream *owner_name,
	text_stream *printed_name, int id) {
	segmentation_pos saved = CodeGen::select(gen, c_kinds_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n", CObjectModel::new_header_name(gen, I"K", printed_name), id);
	CodeGen::deselect(gen, saved);
}

void CObjectModel::define_header_constant_for_action(code_generation *gen, text_stream *action_name,
	text_stream *printed_name, int id) {
	segmentation_pos saved = CodeGen::select(gen, c_actions_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n", CObjectModel::new_header_name(gen, I"A", printed_name), id);
	CodeGen::deselect(gen, saved);
}

void CObjectModel::define_header_constant_for_property(code_generation *gen, text_stream *prop_name,
	int id) {
	segmentation_pos saved = CodeGen::select(gen, c_property_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n", CObjectModel::new_header_name(gen, I"P", prop_name), id);
	CodeGen::deselect(gen, saved);
}

void CObjectModel::define_header_constant_for_variable(code_generation *gen, text_stream *var_name,
	int id) {
	segmentation_pos saved = CodeGen::select(gen, c_variable_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n", CObjectModel::new_header_name(gen, I"V", var_name), id);
	CodeGen::deselect(gen, saved);
}

void CObjectModel::define_header_constant_for_function(code_generation *gen, text_stream *fn_name,
	text_stream *val) {
	segmentation_pos saved = CodeGen::select(gen, c_function_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %S\n", CObjectModel::new_header_name(gen, I"F", fn_name), val);
	CodeGen::deselect(gen, saved);
}

@h Code to compute ofclass and metaclass.
The easier case is metaclass. This is a built-in function, so we make it follow
the calling conventions of other functions. It says which of five possible values
an ID belongs to: 0, |Class|, |Object|, |String| or |Routine|.

= (text to inform7_clib.h)
i7word_t fn_i7_mgl_metaclass(i7process_t *proc, i7word_t id);
int i7_ofclass(i7process_t *proc, i7word_t id, i7word_t cl_id);
=

= (text to inform7_clib.c)
i7word_t fn_i7_mgl_metaclass(i7process_t *proc, i7word_t id) {
	if (id <= 0) return 0;
	if (id >= I7VAL_FUNCTIONS_BASE) return i7_mgl_Routine;
	if (id >= I7VAL_STRINGS_BASE) return i7_mgl_String;
	return i7_metaclass_of[id];
}
=
This function implements |OFCLASS_BIP| for us at runtime, and is a little harder,
because we may need to recurse up the class hierarchy. If A is of class B whose
superclass is C, then |i7_ofclass(A, B)| and |i7_ofclass(A, C)| are both true,
as it |i7_ofclass(B, C)|.
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

@h Property IDs.
Each distinct property has a distinct ID. These count upwards from 0, and can
freely overlap with owner IDs or anything else.

In Inform 6, owing to the complicated VMs it compiles to, there is a complicated
distinction between "VM attributes" (some but not all either-or properties) and
"VM properties" (everything else). But not here.

If a property is never given to anything this is nevertheless called, with |used|
set false, so that a suitable constant is |#sefine|d in the code, and therefore
that references to it will not fail to compile.

=
void CObjectModel::declare_property(code_generator *cgt, code_generation *gen,
	inter_symbol *prop_name) {
	int attr = FALSE;
	if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT)) {
		if ((Inter::Symbols::read_annotation(prop_name, ASSIMILATED_IANN) >= 0) ||
			(Inter::Symbols::read_annotation(prop_name, EXPLICIT_ATTRIBUTE_IANN) < 0)) attr = TRUE;
	}
	text_stream *name = Inter::Symbols::name(prop_name);
	C_property *cp = CObjectModel::property_by_name(gen, name, attr);
	text_stream *pname = Metadata::read_optional_textual(Inter::Packages::container(prop_name->definition), I"^name");
	if (pname)
		CObjectModel::define_header_constant_for_property(gen, pname, cp->id);
}

@ Property IDs count upwards from 0 in declaration order, though they really
only need to be unique, so the order is not significant.

=
typedef struct C_property {
	struct text_stream *name;
	int id;
	int attr;
	CLASS_DEFINITION
} C_property;

C_property *CObjectModel::property_by_name(code_generation *gen, text_stream *name, int attr) {
	dictionary *D = C_GEN_DATA(objdata.declared_properties);
	C_property *cp;
	if (Dictionaries::find(D, name) == NULL) {
		cp = CREATE(C_property);
		cp->name = Str::duplicate(name);
		cp->attr = attr;
		cp->id = C_GEN_DATA(objdata.property_id_counter)++;
		Dictionaries::create(D, name);
		Dictionaries::write_value(D, name, (void *) cp);
		
		segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("#define ");
		CNamespace::mangle(NULL, OUT, cp->name);
		WRITE(" %d\n", cp->id);
		CodeGen::deselect(gen, saved);
	} else {
		cp = Dictionaries::read_value(D, name);
	}
	return cp;
}

@h Property offsets arrays.
Here we compile a function which creates arrays of where to find metadata on
properties at runtime.

=
void CObjectModel::property_offset(code_generator *cgt, code_generation *gen,
	text_stream *prop, int pos, int as_attr) {
	segmentation_pos saved = CodeGen::select(gen, c_property_offset_creator_I7CGS);
	text_stream *OUT = CodeGen::current(gen);

	if (C_GEN_DATA(objdata.C_property_offsets_made)++ == 0)
		@<Begin the property-offset creator function@>;

	WRITE("i7_write_word(proc, ");
	if (as_attr) CNamespace::mangle(cgt, OUT, I"attributed_property_offsets");
	else CNamespace::mangle(cgt, OUT, I"valued_property_offsets");
	WRITE(", ");
	CNamespace::mangle(cgt, OUT, prop);
	WRITE(", %d, i7_lvalue_SET);\n", pos);
	CodeGen::deselect(gen, saved);
}

@ This function is created only if properties actually exist to have offsets;
that avoids a meaningless function being created in small test runs of |inter|
not deriving from an Inform program.

@<Begin the property-offset creator function@> =
	WRITE("i7word_t fn_i7_mgl_CreatePropertyOffsets(i7process_t *proc) {\n"); INDENT;
	WRITE("for (int i=0; i<i7_mgl_attributed_property_offsets_SIZE; i++)\n"); INDENT;
	WRITE("i7_write_word(proc, i7_mgl_attributed_property_offsets, i, -1, i7_lvalue_SET);\n"); OUTDENT;
	WRITE("for (int i=0; i<i7_mgl_valued_property_offsets_SIZE; i++)\n"); INDENT;
	WRITE("i7_write_word(proc, i7_mgl_valued_property_offsets, i, -1, i7_lvalue_SET);\n"); OUTDENT;

@ This function has no meaningful return value, but has to conform to our
calling convention for Inform programs, which means it has to return something.
By fiat, that will be 0.

@<Complete the property-offset creator function@> =
	if (C_GEN_DATA(objdata.C_property_offsets_made) > 0) {
		segmentation_pos saved = CodeGen::select(gen, c_property_offset_creator_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("return 0;\n");
		OUTDENT;
		WRITE("}\n");
		CodeGen::deselect(gen, saved);
	}

@h Property-value initialiser function.
When generating code for I6, property values are initialised with direct
declarations in the I6 language, which tell that compiler to set up a large
and complicated data structure.

We will not use any of that here, and will not attempt to create static data
arrays which already have the right contents. Instead we will compile an
initialiser function which runs early and sets the property values up by hand:

@<Begin the initialiser function@> =
	segmentation_pos saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("void i7_initializer(i7process_t *proc) {\n"); INDENT;
	WRITE("for (int id=0; id<i7_max_objects; id++) {\n"); INDENT;
	WRITE("for (int p=0; p<i7_no_property_ids; p++) {\n"); INDENT;
	WRITE("i7_properties[id].address[p] = 0;\n");
	WRITE("i7_properties[id].len[p] = 0;\n");
	OUTDENT; WRITE("}\n");
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);

@<Complete the initialiser function@> =
	segmentation_pos saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);

	C_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_objects)) {
		if (co->initial_parent) WRITE("proc->state.i7_object_tree_parent[%S] = %S;\n", co->identifier, co->initial_parent->identifier);
		if (co->initial_sibling) WRITE("proc->state.i7_object_tree_sibling[%S] = %S;\n", co->identifier, co->initial_sibling->identifier);
		if (co->initial_child) WRITE("proc->state.i7_object_tree_child[%S] = %S;\n", co->identifier, co->initial_child->identifier);
	}

	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);

@

=
int CObjectModel::optimise_property_value(code_generator *cgt, code_generation *gen, inter_symbol *prop_name, inter_tree_node *X) {
	C_GEN_DATA(objdata.inline_this) = FALSE;
	if (Inter::Symbols::is_stored_in_data(X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD])) {
		inter_symbol *S = InterSymbolsTables::symbol_from_data_pair_and_frame(X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD], X);
		if ((S) && (Inter::Symbols::read_annotation(S, INLINE_ARRAY_IANN) == 1)) {
			C_GEN_DATA(objdata.inline_this) = TRUE;
		}
	}	
	return FALSE;
}

@ And this function call is compiled to initialise a property value for a given
owner. Note that it must be called after the owner's declaration call, and before
the next owner is declared.

=
typedef struct C_pv_pair {
	struct C_property *prop;
	struct text_stream *val;
	int inlined;
	CLASS_DEFINITION
} C_pv_pair;

void CObjectModel::assign_property(code_generator *cgt, code_generation *gen,
	text_stream *property_name, text_stream *val, int as_att) {
	C_property_owner *owner = C_GEN_DATA(objdata.current_owner);
	C_property *prop = CObjectModel::property_by_name(gen, property_name, FALSE);
	C_pv_pair *pair = CREATE(C_pv_pair);
	pair->prop = prop;
	pair->val = Str::duplicate(val);
	pair->inlined = C_GEN_DATA(objdata.inline_this);
	C_GEN_DATA(objdata.inline_this) = FALSE;
	ADD_TO_LINKED_LIST(pair, C_pv_pair, owner->property_values);
}

C_property_owner *CObjectModel::super(code_generation *gen, C_property_owner *owner) {
	C_property_owner *co;
	LOOP_OVER_LINKED_LIST(co, C_property_owner, C_GEN_DATA(objdata.declared_objects)) {
		if (Str::eq(co->name,  owner->class)) return co;
	}
	return NULL;
}

int not_added_ops_yet = TRUE;
void CObjectModel::gather_properties(code_generation *gen, C_property_owner *owner, C_pv_pair **vals) {
	C_property_owner *super = CObjectModel::super(gen, owner);
	if ((Str::eq(owner->name, I"Class")) && (not_added_ops_yet)) {
		C_property *prop;
		LOOP_OVER(prop, C_property) {
			if (prop->attr) {
				C_pv_pair *np = CREATE(C_pv_pair);
				np->prop = prop;
				np->val = I"0";
				np->inlined = FALSE;
				ADD_TO_LINKED_LIST(np, C_pv_pair, owner->property_values);
			}
		}
		not_added_ops_yet = FALSE;
	}
	if (super != owner) CObjectModel::gather_properties(gen, super, vals);
	C_pv_pair *pair;
	LOOP_OVER_LINKED_LIST(pair, C_pv_pair, owner->property_values) {
		vals[pair->prop->id] = pair;
	}
}

void CObjectModel::write_property_values_table(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	C_property_owner *owner;
	LOOP_OVER_LINKED_LIST(owner, C_property_owner, C_GEN_DATA(objdata.declared_objects)) {
		C_pv_pair *vals[1024];
		for (int i=0; i<1024; i++) vals[i] = NULL;
		CObjectModel::gather_properties(gen, owner, vals);
		for (int i=0; i<1024; i++) if (vals[i]) {
			C_pv_pair *pair = vals[i];
			if (pair->inlined) {
				WRITE("i7_properties[");
				CNamespace::mangle(NULL, OUT, owner->name);
				WRITE("].address[");
				CNamespace::mangle(NULL, OUT, pair->prop->name);
				WRITE("] = %S;\n", pair->val);
				WRITE("i7_properties[");
				CNamespace::mangle(NULL, OUT, owner->name);
				WRITE("].len[");
				CNamespace::mangle(NULL, OUT, pair->prop->name);
				WRITE("] = xt_%S + 1;\n", pair->val);
			} else {
				WRITE("i7_properties[");
				CNamespace::mangle(NULL, OUT, owner->name);
				WRITE("].address[");
				CNamespace::mangle(NULL, OUT, pair->prop->name);
				WRITE("] = %d; // %S\n", C_GEN_DATA(memdata.himem), pair->val);
				CMemoryModel::array_entry(NULL, gen, pair->val, WORD_ARRAY_FORMAT);
				WRITE("i7_properties[");
				CNamespace::mangle(NULL, OUT, owner->name);
				WRITE("].len[");
				CNamespace::mangle(NULL, OUT, pair->prop->name);
				WRITE("] = 1;\n");
			}
		}
	}
	CodeGen::deselect(gen, saved);
}

@h Primitives for property usage.
The following primitives are all implemented by calling suitable C functions,
which we will then need to write in |inform7_clib.h|.

=
int CObjectModel::handle_store_by_ref(code_generation *gen, inter_tree_node *ref) {
	if (Inter::Reference::node_is_ref_to(gen->from, ref, PROPERTYVALUE_BIP)) return TRUE;
	return FALSE;
}

int CObjectModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case PROPERTYADDRESS_BIP: WRITE("i7_prop_addr("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: WRITE("i7_prop_len("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		case PROPERTYVALUE_BIP:	if (CReferences::am_I_a_ref(gen)) {
									WRITE("i7_change_prop_value(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
								} else {
									WRITE("i7_read_prop_value(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")");
								}
								break;
		case MESSAGE0_BIP: 		WRITE("i7_mcall_0(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		case MESSAGE1_BIP: 		WRITE("i7_mcall_1(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
								VNODE_3C; WRITE(")"); break;
		case MESSAGE2_BIP: 		WRITE("i7_mcall_2(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
								VNODE_3C; WRITE(", "); VNODE_4C; WRITE(")"); break;
		case MESSAGE3_BIP: 		WRITE("i7_mcall_3(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
								VNODE_3C; WRITE(", "); VNODE_4C; WRITE(", "); VNODE_5C; WRITE(")"); break;
		case GIVE_BIP: 			WRITE("i7_give(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", 1)"); break;
		case TAKE_BIP: 			WRITE("i7_give(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", 0)"); break;
		case MOVE_BIP:          WRITE("i7_move(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		case REMOVE_BIP:        WRITE("i7_move(proc, "); VNODE_1C; WRITE(", 0)"); break;

		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@h Reading and writing properties.
So here is the run-time storage for property values, and simple code to read
and write them.

= (text to inform7_clib.h)
i7word_t fn_i7_mgl_CreatePropertyOffsets(i7process_t *proc);
void i7_write_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id, i7word_t val);
i7word_t i7_read_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id);
i7word_t i7_change_prop_value(i7process_t *proc, i7word_t obj, i7word_t pr, i7word_t to, int way);
void i7_give(i7process_t *proc, i7word_t owner, i7word_t prop, i7word_t val);
i7word_t i7_prop_len(i7word_t obj, i7word_t pr);
i7word_t i7_prop_addr(i7word_t obj, i7word_t pr);
=

= (text to inform7_clib.c)
#define I7_MAX_PROPERTY_IDS 1000
typedef struct i7_property_set {
	i7word_t address[I7_MAX_PROPERTY_IDS];
	i7word_t len[I7_MAX_PROPERTY_IDS];
} i7_property_set;
i7_property_set i7_properties[i7_max_objects];

void i7_write_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id, i7word_t val) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
	i7word_t address = i7_properties[(int) owner_id].address[(int) prop_id];
	if (address) i7_write_word(proc, address, 0, val, i7_lvalue_SET);
	else {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
}
=

@ And here sre the functions called by the above primitives:

= (text to inform7_clib.c)
i7word_t i7_read_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (i7_properties[(int) owner_id].address[(int) prop_id] == 0) {
		owner_id = i7_class_of[owner_id];
		if (owner_id == i7_mgl_Class) return 0;
	}
	i7word_t address = i7_properties[(int) owner_id].address[(int) prop_id];
	return i7_read_word(proc, address, 0);
}

i7word_t i7_change_prop_value(i7process_t *proc, i7word_t obj, i7word_t pr, i7word_t to, int way) {
	i7word_t val = i7_read_prop_value(proc, obj, pr), new_val = val;
	switch (way) {
		case i7_lvalue_SET:      i7_write_prop_value(proc, obj, pr, to); new_val = to; break;
		case i7_lvalue_PREDEC:   new_val = val-1; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_POSTDEC:  new_val = val; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_PREINC:   new_val = val+1; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_POSTINC:  new_val = val; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_SETBIT:   new_val = val | new_val; i7_write_prop_value(proc, obj, pr, new_val); break;
		case i7_lvalue_CLEARBIT: new_val = val &(~new_val); i7_write_prop_value(proc, obj, pr, new_val); break;
	}
	return new_val;
}

void i7_give(i7process_t *proc, i7word_t owner, i7word_t prop, i7word_t val) {
	i7_write_prop_value(proc, owner, prop, val);
}

i7word_t i7_prop_len(i7word_t obj, i7word_t pr) {
	if ((obj <= 0) || (obj >= i7_max_objects) ||
		(pr < 0) || (pr >= i7_no_property_ids)) return 0;
	return 4*i7_properties[(int) obj].len[(int) pr];
}

i7word_t i7_prop_addr(i7word_t obj, i7word_t pr) {
	if ((obj <= 0) || (obj >= i7_max_objects) ||
		(pr < 0) || (pr >= i7_no_property_ids)) return 0;
	return i7_properties[(int) obj].address[(int) pr];
}
=

@h Special object-related conditions.

=
text_stream *CObjectModel::test_with_function(inter_ti bip, int *positive) {
	switch (bip) {
		case OFCLASS_BIP:	*positive = TRUE;  return I"i7_ofclass"; break;
		case HAS_BIP:		*positive = TRUE;  return I"i7_has"; break;
		case HASNT_BIP:		*positive = FALSE; return I"i7_has"; break;
		case IN_BIP:		*positive = TRUE;  return I"i7_in"; break;
		case NOTIN_BIP:		*positive = FALSE; return I"i7_in"; break;
		case PROVIDES_BIP:	*positive = TRUE;  return I"i7_provides"; break;
	}
	*positive = NOT_APPLICABLE; return NULL;
}

@

= (text to inform7_clib.h)
int i7_has(i7process_t *proc, i7word_t obj, i7word_t attr);
int i7_provides(i7process_t *proc, i7word_t owner_id, i7word_t prop_id);
int i7_in(i7process_t *proc, i7word_t obj1, i7word_t obj2);
i7word_t fn_i7_mgl_parent(i7process_t *proc, i7word_t id);
#define i7_parent fn_i7_mgl_parent
i7word_t fn_i7_mgl_child(i7process_t *proc, i7word_t id);
#define i7_child fn_i7_mgl_child
i7word_t fn_i7_mgl_children(i7process_t *proc, i7word_t id);
i7word_t fn_i7_mgl_sibling(i7process_t *proc, i7word_t id);
#define i7_sibling fn_i7_mgl_sibling
void i7_move(i7process_t *proc, i7word_t obj, i7word_t to);
=

= (text to inform7_clib.c)
int i7_has(i7process_t *proc, i7word_t obj, i7word_t attr) {
	if (i7_read_prop_value(proc, obj, attr)) return 1;
	return 0;
}

int i7_provides(i7process_t *proc, i7word_t owner_id, i7word_t prop_id) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (owner_id != 1) {
		if (i7_properties[(int) owner_id].address[(int) prop_id] != 0)
			return 1;
		owner_id = i7_class_of[owner_id];
	}
	return 0;
}

int i7_in(i7process_t *proc, i7word_t obj1, i7word_t obj2) {
	if (fn_i7_mgl_metaclass(proc, obj1) != i7_mgl_Object) return 0;
	if (obj2 == 0) return 0;
	if (proc->state.i7_object_tree_parent[obj1] == obj2) return 1;
	return 0;
}

i7word_t fn_i7_mgl_parent(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.i7_object_tree_parent[id];
}
i7word_t fn_i7_mgl_child(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.i7_object_tree_child[id];
}
i7word_t fn_i7_mgl_children(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	i7word_t c=0;
	for (int i=0; i<i7_max_objects; i++) if (proc->state.i7_object_tree_parent[i] == id) c++;
	return c;
}
i7word_t fn_i7_mgl_sibling(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.i7_object_tree_sibling[id];
}

void i7_move(i7process_t *proc, i7word_t obj, i7word_t to) {
	if ((obj <= 0) || (obj >= i7_max_objects)) return;
	int p = proc->state.i7_object_tree_parent[obj];
	if (p) {
		if (proc->state.i7_object_tree_child[p] == obj) {
			proc->state.i7_object_tree_child[p] = proc->state.i7_object_tree_sibling[obj];
		} else {
			int c = proc->state.i7_object_tree_child[p];
			while (c != 0) {
				if (proc->state.i7_object_tree_sibling[c] == obj) {
					proc->state.i7_object_tree_sibling[c] = proc->state.i7_object_tree_sibling[obj];
					break;
				}
				c = proc->state.i7_object_tree_sibling[c];
			}
		}
	}
	proc->state.i7_object_tree_parent[obj] = to;
	proc->state.i7_object_tree_sibling[obj] = 0;
	if (to) {
		proc->state.i7_object_tree_sibling[obj] = proc->state.i7_object_tree_child[to];
		proc->state.i7_object_tree_child[to] = obj;
	}
}
=
