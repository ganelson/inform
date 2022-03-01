[CReferences::] C References.

How changes to storage objects are translated into C.

@ References identify storage objects which are being written to or otherwise
modified, rather than having their current contents read.

There are seven possible ways to modify something identified by a reference,
and we need constants to identify these ways in the code we generate:

= (text to inform7_clib.h)
#define i7_lvalue_SET 1
#define i7_lvalue_PREDEC 2
#define i7_lvalue_POSTDEC 3
#define i7_lvalue_PREINC 4
#define i7_lvalue_POSTINC 5
#define i7_lvalue_SETBIT 6
#define i7_lvalue_CLEARBIT 7
=

@ Those seven ways correspond to seven Inter primitives, with the following
signatures:
= (text)
primitive !store         ref val -> val
primitive !preincrement  ref -> val
primitive !postincrement ref -> val
primitive !predecrement  ref -> val
primitive !postdecrement ref -> val
primitive !setbit        ref val -> void
primitive !clearbit      ref val -> void
=
Since C functions can have their return values freely ignored, we will in fact
implement |!setbit| and |!clearbit| as if they too had the signature
|ref val -> val|.

=
int CReferences::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *store_form = NULL;
	switch (bip) {
		case STORE_BIP:			store_form = I"i7_lvalue_SET"; break;
		case PREINCREMENT_BIP:	store_form = I"i7_lvalue_PREINC"; break;
		case POSTINCREMENT_BIP:	store_form = I"i7_lvalue_POSTINC"; break;
		case PREDECREMENT_BIP:	store_form = I"i7_lvalue_PREDEC"; break;
		case POSTDECREMENT_BIP:	store_form = I"i7_lvalue_POSTDEC"; break;
		case SETBIT_BIP:		store_form = I"i7_lvalue_SETBIT"; break;
		case CLEARBIT_BIP:		store_form = I"i7_lvalue_CLEARBIT"; break;
		default: return NOT_APPLICABLE;
	}
	if (store_form) @<This does indeed modify a value by reference@>;
	return FALSE;
}

@ Some storage objects, like variables, can be generated to C code which works
in either an lvalue or rvalue context. For example, the Inter variable |frog|
generates just as the C variable |i7_mgl_frog|.[1] It's then fine to generate
code like either |10 + i7_mgl_frog|, where it is used in a |val| context, or
like |i7_mgl_frog++|, where it is used in a |ref| context.

But other storage objects are not so lucky, and can only be written to by
calling functions.

[1] In real life, do not mangle frogs. See C. S. Lewis, "Perelandra", 1943.

@<This does indeed modify a value by reference@> =
	inter_tree_node *ref = InterTree::first_child(P);
	inter_tree_node *storage_ref = InterTree::first_child(P);
	if (storage_ref->W.instruction[0] == REFERENCE_IST)
		storage_ref = InterTree::first_child(storage_ref);
	int val_supplied = FALSE;
	if ((bip == STORE_BIP) || (bip == SETBIT_BIP) || (bip == CLEARBIT_BIP)) val_supplied = TRUE;
	if (ReferenceInstruction::node_is_ref_to(gen->from, ref, LOOKUP_BIP))
		@<This is a reference to a word lookup@>
	else if (ReferenceInstruction::node_is_ref_to(gen->from, ref, LOOKUPBYTE_BIP))
		@<This is a reference to a byte lookup@>
	else if (ReferenceInstruction::node_is_ref_to(gen->from, ref, PROPERTYVALUE_BIP))
		@<This is a reference to a property value@>
	else
		@<This is a reference to something else@>;

@<This is a reference to a word lookup@> =
	WRITE("(");
	WRITE("i7_change_word(proc, ");
		Vanilla::node(gen, InterTree::first_child(storage_ref)); WRITE(", ");
		Vanilla::node(gen, InterTree::second_child(storage_ref)); WRITE(", ");
	if (val_supplied) { VNODE_2C; } else { WRITE("0"); }
	WRITE(", %S", store_form);
	WRITE("))");

@<This is a reference to a byte lookup@> =
	WRITE("(");
	WRITE("i7_change_byte(proc, ");
		Vanilla::node(gen, InterTree::first_child(storage_ref)); WRITE(" + ");
		Vanilla::node(gen, InterTree::second_child(storage_ref)); WRITE(", ");
	if (val_supplied) { VNODE_2C; } else { WRITE("0"); }
	WRITE(", %S", store_form);
	WRITE("))");

@<This is a reference to a property value@> =
	WRITE("(");
	WRITE("i7_change_gprop_value(proc, ");
		Vanilla::node(gen, InterTree::first_child(storage_ref)); WRITE(", ");
		Vanilla::node(gen, InterTree::second_child(storage_ref)); WRITE(", ");
		Vanilla::node(gen, InterTree::third_child(storage_ref)); WRITE(", ");
	if (val_supplied) { VNODE_2C; } else { WRITE("0"); }
	WRITE(", %S", store_form);
	WRITE("))");

@<This is a reference to something else@> =
	switch (bip) {
		case PREINCREMENT_BIP:	WRITE("++("); VNODE_1C; WRITE(")"); break;
		case POSTINCREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")++"); break;
		case PREDECREMENT_BIP:	WRITE("--("); VNODE_1C; WRITE(")"); break;
		case POSTDECREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")--"); break;
		case STORE_BIP:			WRITE("("); VNODE_1C; WRITE(" = "); VNODE_2C; WRITE(")"); break;
		case SETBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" | "); VNODE_2C; break;
		case CLEARBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" &~ ("); VNODE_2C; WRITE(")"); break;
	}
