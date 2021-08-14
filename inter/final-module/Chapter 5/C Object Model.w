[CObjectModel::] C Object Model.

How objects, classes and properties are compiled to C.

@h Setting up the model.

=
void CObjectModel::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, DECLARE_INSTANCE_MTID, CObjectModel::declare_instance);
	METHOD_ADD(cgt, DECLARE_CLASS_MTID, CObjectModel::declare_class);

	METHOD_ADD(cgt, DECLARE_PROPERTY_MTID, CObjectModel::declare_property);
	METHOD_ADD(cgt, DECLARE_ATTRIBUTE_MTID, CObjectModel::declare_attribute);
	METHOD_ADD(cgt, PROPERTY_OFFSET_MTID, CObjectModel::property_offset);
	METHOD_ADD(cgt, ASSIGN_PROPERTY_MTID, CObjectModel::assign_property);
}

typedef struct C_generation_object_model_data {
	int owner_id_count;
	struct C_property_owner *owners;
	int owners_capacity;
	int property_id_counter;
	int C_property_offsets_made;
	int current_owner_id;
} C_generation_object_model_data;

typedef struct C_property_owner {
	struct text_stream *name;
	struct text_stream *class;
	int is_class;
} C_property_owner;

void CObjectModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(objdata.owner_id_count) = 0;
	C_GEN_DATA(objdata.property_id_counter) = 0;
	C_GEN_DATA(objdata.C_property_offsets_made) = 0;
	C_GEN_DATA(objdata.owners) = NULL;
	C_GEN_DATA(objdata.owners_capacity) = 0;
}

void CObjectModel::begin(code_generation *gen) {
	CObjectModel::initialise_data(gen);
	@<Begin the initialiser function@>;
	CObjectModel::declare_property_by_name(gen, I"value_range", TRUE);
}

void CObjectModel::end(code_generation *gen) {
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
void CObjectModel::assign_owner(code_generation *gen, int id, text_stream *name,
	text_stream *class_name, int is_class) {
	while (id >= C_GEN_DATA(objdata.owners_capacity)) {
		int old_capacity = C_GEN_DATA(objdata.owners_capacity);
		int new_capacity = 4 * old_capacity;
		if (old_capacity == 0) new_capacity = 8;
		C_property_owner *new_array = (Memory::calloc(new_capacity,
			sizeof(C_property_owner), CODE_GENERATION_MREASON));
		for (int i=0; i<old_capacity; i++) 
			new_array[i] = C_GEN_DATA(objdata.owners)[i];
		if (old_capacity > 0) Memory::I7_array_free(C_GEN_DATA(objdata.owners),
			CODE_GENERATION_MREASON, old_capacity, sizeof(C_property_owner));
		C_GEN_DATA(objdata.owners) = new_array;		
		C_GEN_DATA(objdata.owners_capacity) = new_capacity;
	}
	if (Str::len(name) == 0) internal_error("nameless instance");
	C_GEN_DATA(objdata.owners)[id].name = Str::duplicate(name);
	C_GEN_DATA(objdata.owners)[id].class = Str::duplicate(class_name);
	C_GEN_DATA(objdata.owners)[id].is_class = is_class;
	C_GEN_DATA(objdata.current_owner_id) = id;
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
		CObjectModel::declare_class_inner(gen, I"Class", 1, I"Class");
		C_GEN_DATA(objdata.owner_id_count)++;
		CObjectModel::declare_class_inner(gen, I"Object", 2, I"Class");
		C_GEN_DATA(objdata.owner_id_count)++;
		CObjectModel::declare_class_inner(gen, I"String", 3, I"Class");
		C_GEN_DATA(objdata.owner_id_count)++;
		CObjectModel::declare_class_inner(gen, I"Routine", 4, I"Class");
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
	generated_segment *saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);

	WRITE("#define i7_max_objects %d\n", C_GEN_DATA(objdata.owner_id_count) + 1);

	WRITE("i7val i7_metaclass_of[] = { 0");
	for (int i=1; i<C_GEN_DATA(objdata.owner_id_count); i++) {
		if (C_GEN_DATA(objdata.owners)[i].is_class) WRITE(", i7_mgl_Class");
		else WRITE(", i7_mgl_Object");
	}
	WRITE(" };\n");

	WRITE("i7val i7_class_of[] = { 0");
	for (int i=1; i<C_GEN_DATA(objdata.owner_id_count); i++) {
		WRITE(", "); CNamespace::mangle(NULL, OUT, C_GEN_DATA(objdata.owners)[i].class);
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
void CObjectModel::declare_class(code_generation_target *cgt, code_generation *gen,
	text_stream *class_name, text_stream *super_class) {
	if (Str::len(super_class) == 0) super_class = I"Class";
	CObjectModel::declare_class_inner(gen, class_name,
		CObjectModel::next_owner_id(gen), super_class);
}

void CObjectModel::declare_class_inner(code_generation *gen,
	text_stream *class_name, int id, text_stream *super_class) {
	CObjectModel::define_constant_for_owner_id(gen, class_name, id);
	CObjectModel::assign_owner(gen, id, class_name, super_class, TRUE);
}

@ And each instance here:

=
void CObjectModel::declare_instance(code_generation_target *cgt, code_generation *gen,
	text_stream *class_name, text_stream *instance_name, int acount, int is_dir) {
	if (Str::len(instance_name) == 0) internal_error("nameless instance");
	int id = CObjectModel::next_owner_id(gen);
	CObjectModel::define_constant_for_owner_id(gen, instance_name, id);
	CObjectModel::assign_owner(gen, id, instance_name, class_name, FALSE);
}

@ So it is finally time to compile a |#define| for the owner's identifier,
defining this as a constant equal to its ID.

=
void CObjectModel::define_constant_for_owner_id(code_generation *gen, text_stream *owner_name,
	int id) {
	generated_segment *saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define "); CNamespace::mangle(NULL, OUT, owner_name); WRITE(" %d\n", id);
	CodeGen::deselect(gen, saved);
}

@h Code to compute ofclass and metaclass.
The easier case is metaclass. This is a built-in function, so we make it follow
the calling conventions of other functions. It says which of five possible values
an ID belongs to: 0, |Class|, |Object|, |String| or |Routine|.

= (text to inform7_clib.h)
i7val fn_i7_mgl_metaclass(int n, i7val id) {
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

= (text to inform7_clib.h)
int i7_ofclass(i7val id, i7val cl_id) {
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
void CObjectModel::declare_property(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prop_name, int used) {
	text_stream *name = CodeGen::CL::name(prop_name);
	CObjectModel::declare_property_by_name(gen, name, used);
}
void CObjectModel::declare_attribute(code_generation_target *cgt, code_generation *gen,
	text_stream *prop_name) {
	CObjectModel::declare_property_by_name(gen, prop_name, TRUE);
}

@ Property IDs count upwards from 0 in declaration order, though they really
only need to be unique, so the order is not significant.

=
void CObjectModel::declare_property_by_name(code_generation *gen, text_stream *name, int used) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if (used) {
		WRITE("#define ");
		CNamespace::mangle(NULL, OUT, name);
		WRITE(" %d\n", C_GEN_DATA(objdata.property_id_counter)++);
	} else {
		WRITE("#ifndef ");
		CNamespace::mangle(NULL, OUT, name);
		WRITE("\n#define ");
		CNamespace::mangle(NULL, OUT, name);
		WRITE(" 0\n#endif\n");
	}
	CodeGen::deselect(gen, saved);
}

@h Property offsets arrays.
Here we compile a function which creates arrays of where to find metadata on
properties at runtime.

=
void CObjectModel::property_offset(code_generation_target *cgt, code_generation *gen,
	text_stream *prop, int pos, int as_attr) {
	generated_segment *saved = CodeGen::select(gen, c_property_offset_creator_I7CGS);
	text_stream *OUT = CodeGen::current(gen);

	if (C_GEN_DATA(objdata.C_property_offsets_made)++ == 0)
		@<Begin the property-offset creator function@>;

	WRITE("i7_write_word(i7mem, ");
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
	WRITE("i7val fn_i7_mgl_CreatePropertyOffsets(int argc) {\n"); INDENT;
	WRITE("for (int i=0; i<i7_mgl_attributed_property_offsets_SIZE; i++)\n"); INDENT;
	WRITE("i7_write_word(i7mem, i7_mgl_attributed_property_offsets, i, -1, i7_lvalue_SET);\n"); OUTDENT;
	WRITE("for (int i=0; i<i7_mgl_valued_property_offsets_SIZE; i++)\n"); INDENT;
	WRITE("i7_write_word(i7mem, i7_mgl_valued_property_offsets, i, -1, i7_lvalue_SET);\n"); OUTDENT;

@ This function has no meaningful return value, but has to conform to our
calling convention for Inform programs, which means it has to return something.
By fiat, that will be 0.

@<Complete the property-offset creator function@> =
	if (C_GEN_DATA(objdata.C_property_offsets_made) > 0) {
		generated_segment *saved = CodeGen::select(gen, c_property_offset_creator_I7CGS);
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
	generated_segment *saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("void i7_initializer(void) {\n"); INDENT;
	WRITE("for (int id=0; id<i7_max_objects; id++)\n"); INDENT;
	WRITE("for (int p=0; p<i7_no_property_ids; p++) {\n"); INDENT;
	WRITE("i7_properties[id].value[p] = 0;\n");
	WRITE("if (id == 1) i7_properties[id].value_set[p] = 1;\n");
	WRITE("else i7_properties[id].value_set[p] = 0;\n");
	OUTDENT; WRITE("}\n");
	OUTDENT;
	CodeGen::deselect(gen, saved);

@<Complete the initialiser function@> =
	generated_segment *saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);

@ And this function call is compiled to initialise a property value for a given
owner. Note that it must be called after the owner's declaration call, and before
the next owner is declared.

=
void CObjectModel::assign_property(code_generation_target *cgt, code_generation *gen,
	text_stream *property_name, text_stream *val, int as_att) {
	generated_segment *saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7_write_prop_value(");
	CNamespace::mangle(cgt, OUT, C_GEN_DATA(objdata.owners)[C_GEN_DATA(objdata.current_owner_id)].name);
	WRITE(", ");
	CNamespace::mangle(cgt, OUT, property_name);
	WRITE(", %S);\n", val);
	CodeGen::deselect(gen, saved);
}

@h Primitives for property usage.
The following primitives are all implemented by calling suitable C functions,
which we will then need to write in |inform7_clib.h|.

=
int CObjectModel::handle_store_by_ref(code_generation *gen, inter_tree_node *ref) {
	if (CodeGen::CL::node_is_ref_to(gen->from, ref, PROPERTYVALUE_BIP)) return TRUE;
	return FALSE;
}

int CObjectModel::compile_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case PROPERTYADDRESS_BIP: WRITE("i7_prop_addr("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: WRITE("i7_prop_len("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case PROPERTYVALUE_BIP:	if (CReferences::am_I_a_ref(gen)) {
									WRITE("i7_change_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE(", ");
								} else {
									WRITE("i7_read_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE(")");
								}
								break;
		case MESSAGE0_BIP: 		WRITE("i7_call_0(i7_read_prop_value("); INV_A1;
								WRITE(", "); INV_A2; WRITE("))"); break;
		case MESSAGE1_BIP: 		WRITE("i7_call_1(i7_read_prop_value("); INV_A1;
								WRITE(", "); INV_A2; WRITE("), "); INV_A3; WRITE(")"); break;
		case MESSAGE2_BIP: 		WRITE("i7_call_2(i7_read_prop_value("); INV_A1;
								WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;
		case MESSAGE3_BIP: 		WRITE("i7_call_3(i7_read_prop_value("); INV_A1;
								WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(", "); INV_A4; WRITE(", "); INV_A5; WRITE(")"); break;
		case GIVE_BIP: 			WRITE("i7_give("); INV_A1; WRITE(", "); INV_A2; WRITE(", 1)"); break;
		case TAKE_BIP: 			WRITE("i7_give("); INV_A1; WRITE(", "); INV_A2; WRITE(", 0)"); break;
		case MOVE_BIP:          WRITE("i7_move("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case REMOVE_BIP:        WRITE("i7_move("); INV_A1; WRITE(", 0)"); break;

		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@h Reading and writing properties.
So here is the run-time storage for property values, and simple code to read
and write them. Note that, unlike in the Z-machine or Glulx implementations,
property values are not stored in the memory map.

= (text to inform7_clib.h)
typedef struct i7_property_set {
	i7val value[i7_no_property_ids];
	int value_set[i7_no_property_ids];
} i7_property_set;
i7_property_set i7_properties[i7_max_objects];

void i7_write_prop_value(i7val owner_id, i7val prop_id, i7val val) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		exit(1);
	}
	i7_properties[(int) owner_id].value[(int) prop_id] = val;
	i7_properties[(int) owner_id].value_set[(int) prop_id] = 1;
}
=

@ And here sre the functions called by the above primitives:

= (text to inform7_clib.h)
i7val i7_read_prop_value(i7val owner_id, i7val prop_id) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (i7_properties[(int) owner_id].value_set[(int) prop_id] == 0)
		owner_id = i7_class_of[owner_id];
	return i7_properties[(int) owner_id].value[(int) prop_id];
}

i7val i7_change_prop_value(i7val obj, i7val pr, i7val to, int way) {
	i7val val = i7_read_prop_value(obj, pr), new_val = val;
	switch (way) {
		case i7_lvalue_SET:      i7_write_prop_value(obj, pr, to); new_val = to; break;
		case i7_lvalue_PREDEC:   new_val = val; i7_write_prop_value(obj, pr, val-1); break;
		case i7_lvalue_POSTDEC:  new_val = val-1; i7_write_prop_value(obj, pr, new_val); break;
		case i7_lvalue_PREINC:   new_val = val; i7_write_prop_value(obj, pr, val+1); break;
		case i7_lvalue_POSTINC:  new_val = val+1; i7_write_prop_value(obj, pr, new_val); break;
		case i7_lvalue_SETBIT:   new_val = val | new_val; i7_write_prop_value(obj, pr, new_val); break;
		case i7_lvalue_CLEARBIT: new_val = val &(~new_val); i7_write_prop_value(obj, pr, new_val); break;
	}
	return new_val;
}

void i7_give(i7val owner, i7val prop, i7val val) {
	i7_write_prop_value(owner, prop, val);
}

i7val i7_prop_len(i7val obj, i7val pr) {
	printf("Unimplemented: i7_prop_len.\n");
	return 0;
}

i7val i7_prop_addr(i7val obj, i7val pr) {
	printf("Unimplemented: i7_prop_addr.\n");
	return 0;
}

void i7_move(i7val obj, i7val to) {
	printf("Unimplemented: i7_move.\n");
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
int i7_has(i7val obj, i7val attr) {
	if (i7_read_prop_value(obj, attr)) return 1;
	return 0;
}

int i7_provides(i7val owner_id, i7val prop_id) {
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (owner_id != 1) {
		if (i7_properties[(int) owner_id].value_set[(int) prop_id] == 1)
			return 1;
		owner_id = i7_class_of[owner_id];
	}
	return 0;
}

int i7_in(i7val obj1, i7val obj2) {
	printf("Unimplemented: i7_in.\n");
	return 0;
}
=
