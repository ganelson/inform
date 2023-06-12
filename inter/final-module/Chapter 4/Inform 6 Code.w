[I6TargetCode::] Inform 6 Code.

To generate I6 routines of imperative code.

@ =
void I6TargetCode::create_generator(code_generator *gtr) {
	METHOD_ADD(gtr, DECLARE_FUNCTION_MTID, I6TargetCode::declare_function);
	METHOD_ADD(gtr, PLACE_LABEL_MTID, I6TargetCode::place_label);
	METHOD_ADD(gtr, EVALUATE_LABEL_MTID, I6TargetCode::evaluate_label);
	METHOD_ADD(gtr, PLACE_PROVENANCE_MTID, I6TargetCode::place_provenance);
	METHOD_ADD(gtr, INVOKE_PRIMITIVE_MTID, I6TargetCode::invoke_primitive);
	METHOD_ADD(gtr, INVOKE_FUNCTION_MTID, I6TargetCode::invoke_function);
	METHOD_ADD(gtr, INVOKE_OPCODE_MTID, I6TargetCode::invoke_opcode);
	METHOD_ADD(gtr, ASSEMBLY_MARKER_MTID, I6TargetCode::assembly_marker);
}

@h Functions.
Inform 6 originated as an assembler briefly called "zass", and its assembly-language
character can still be seen in the way functions are declared:
= (text as Inform 6)
[ FunctionName local1 local2 local3 ... localn;
	...
];
=
Here |local1|, |local2|, ..., |localn| are all of the local variables accessible
from the function; the earliest will be used as call parameters, all subsequent
ones being initially zero.

=
void I6TargetCode::declare_function(code_generator *gtr, code_generation *gen,
	vanilla_function *vf) {
	segmentation_pos saved = CodeGen::select(gen, functions_I7CGS);
	if (vf == NULL) internal_error("no vg");
	text_stream *fn_name = vf->identifier;
	text_stream *OUT = CodeGen::current(gen);
	@<Open the function@>;

	if (Str::eq(fn_name, I"Main"))                 @<Inject code at the top of Main@>;
	if (Str::eq(fn_name, I"DebugAction"))          @<Inject code at the top of DebugAction@>;
	if (Str::eq(fn_name, I"DebugAttribute"))       @<Inject code at the top of DebugAttribute@>;
	if (Str::eq(fn_name, I"DebugProperty"))        @<Inject code at the top of DebugProperty@>;
	if (Str::eq(fn_name, I"FINAL_CODE_STARTUP_R")) @<Inject code at the top of FINAL_CODE_STARTUP_R@>;

	Vanilla::node(gen, vf->function_body); /* This compiles the body of the function */

	@<Close the function@>;
	CodeGen::deselect(gen, saved);
}

@<Open the function@> =
	WRITE("[ %S", fn_name);
	text_stream *var_name;
	LOOP_OVER_LINKED_LIST(var_name, text_stream, vf->locals)
		WRITE(" %S", var_name);
	WRITE(";\n"); INDENT;

@<Close the function@> =
	OUTDENT; WRITE("];\n");

@ A few functions will be sneakily rewritten in passing. This is done to handle
specific features of the Z or Glulx virtual machines which do not meaningfully
exist in any wider cross-platform way. Although this could all be done by having
a slightly more elaborate linker and then including the code below in kits
(as was indeed done during 2020), it's really better that the Inter tree not
have to refer to eldritch Z-only symbols like |#largest_object| or Glulx-only
symbols like |#g$self|.

@<Inject code at the top of Main@> =
	WRITE("#ifdef TARGET_ZCODE; max_z_object = #largest_object - 255; #endif;\n");

@<Inject code at the top of DebugAction@> =
	WRITE("#ifdef TARGET_GLULX;\n");
	WRITE("if (a < 4096) {\n");
	WRITE("    if (a < 0 || a >= #identifiers_table-->7) print \"<invalid action \", a, \">\";\n");
	WRITE("    else {\n");
	WRITE("        str = #identifiers_table-->6;\n");
	WRITE("        str = str-->a;\n");
	WRITE("        if (str) print (string) str; else print \"<unnamed action \", a, \">\";\n");
	WRITE("        return;\n");
	WRITE("    }\n");
	WRITE("}\n");
	WRITE("#endif;\n");
	WRITE("#ifdef TARGET_ZCODE;\n");
	WRITE("if (a < 4096) {\n");
	WRITE("    anames = #identifiers_table;\n");
	WRITE("    anames = anames + 2*(anames-->0) + 2*48;\n");
	WRITE("    print (string) anames-->a;\n");
	WRITE("    return;\n");
	WRITE("}\n");
	WRITE("#endif;\n");

@<Inject code at the top of DebugAttribute@> =
	I6_GEN_DATA(DebugAttribute_seen) = TRUE; 
	WRITE("#ifdef TARGET_GLULX;\n");
	WRITE("if (a < 0 || a >= NUM_ATTR_BYTES*8) print \"<invalid attribute \", a, \">\";\n");
	WRITE("else {\n");
	WRITE("    str = #identifiers_table-->4;\n");
	WRITE("    str = str-->a;\n");
	WRITE("    if (str) print (string) str; else print \"<unnamed attribute \", a, \">\";\n");
	WRITE("}\n");
	WRITE("return;\n");
	WRITE("#endif;\n");
	WRITE("#ifdef TARGET_ZCODE;\n");
	WRITE("if (a < 0 || a >= 48) print \"<invalid attribute \", a, \">\";\n");
	WRITE("else {\n");
	WRITE("    anames = #identifiers_table; anames = anames + 2*(anames-->0);\n");
	WRITE("    print (string) anames-->a;\n");
	WRITE("}\n");
	WRITE("return;\n");
	WRITE("#endif;\n");

@<Inject code at the top of DebugProperty@> =
	WRITE("print (property) p;\n");
	WRITE("return;\n");

@ This enables a speed optimisation in the Glulx virtual machine which
reimplements some of the veneer functions in "hardware". If it weren't here,
or if the Gestalt said that the VM didn't support this after all, no harm would
be done except for a slight slowdown.

At the suggestion of Adrian Welcker, the code below uses the new accelerated
function numbers 8 to 13 in place of the previously valid 2 to 7, which are new
in Glulx 3.1.3. This is a trade-off: it means they behave correctly if the
Inform 6 constant |NUM_ATTR_BYTES| is altered -- in effect, it's getting around
a bug in the previous Glulx spec -- but on the other hand, these accelerated
functions do not exist in earlier Glulx implementations. However, takeup of
3.1.3 has been swift. (See Jira bug I7-2328 and I7-1162.)

@<Inject code at the top of FINAL_CODE_STARTUP_R@> =
	WRITE("#ifdef TARGET_GLULX;\n");
	WRITE("@gestalt 9 0 res;\n");
	WRITE("if (res == 0) rfalse;\n");
	WRITE("addr = #classes_table;\n");
	WRITE("@accelparam 0 addr;\n");
	WRITE("@accelparam 1 INDIV_PROP_START;\n");
	WRITE("@accelparam 2 Class;\n");
	WRITE("@accelparam 3 Object;\n");
	WRITE("@accelparam 4 Routine;\n");
	WRITE("@accelparam 5 String;\n");
	WRITE("addr = #globals_array + WORDSIZE * #g$self;\n");
	WRITE("@accelparam 6 addr;\n");
	WRITE("@accelparam 7 NUM_ATTR_BYTES;\n");
	WRITE("addr = #cpv__start;\n");
	WRITE("@accelparam 8 addr;\n");
	WRITE("@accelfunc 1 Z__Region;\n");
	WRITE("@accelfunc 8 CP__Tab;\n");
	WRITE("@accelfunc 9 RA__Pr;\n");
	WRITE("@accelfunc 10 RL__Pr;\n");
	WRITE("@accelfunc 11 OC__Cl;\n");
	WRITE("@accelfunc 12 RV__Pr;\n");
	WRITE("@accelfunc 13 OP__Pr;\n");
	WRITE("#endif;\n");
	WRITE("rfalse;\n");

@h Labels.
Labels in Inform 6 are |jump| destinations, much as in C they are |goto| destinations.
A full stop indicates where they are positioned:
= (text as Inform 6)
	if (whatever) jump Catastrophe;
		...
	.Catastrophe;
		...
=
Inter identifiers for labels also start with full stops. So:

=
void I6TargetCode::place_label(code_generator *gtr, code_generation *gen,
	text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S;\n", label_name);
}
void I6TargetCode::evaluate_label(code_generator *gtr, code_generation *gen,
	text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

@h Origsource references.

The conversion of filenames to I6 string literals doesn't really account
for special characters. We're leaving it up to the end user to decode all
of I6's confusing escape sequences. But at least we guarantee that the
I6 compiler won't choke on the directive.
=
void I6TargetCode::place_provenance(code_generator *gtr, code_generation *gen,
	text_provenance *source_loc) {
	text_stream *OUT = CodeGen::current(gen);
	if (Provenance::is_somewhere(*source_loc)) {
		WRITE("#OrigSource ");
		Generators::compile_literal_text(gen, source_loc->textual_filename, TRUE);
		if (source_loc->line_number > 0)
			WRITE(" %d;\n", source_loc->line_number);
		else
			WRITE(";\n");
	}
	else {
		WRITE("#OrigSource;\n");
	}
}

@h Function invocations.
Or in other words, function calls. These are easy: the syntax is exactly what
it would be for C.

=
void I6TargetCode::invoke_function(code_generator *gtr, code_generation *gen,
	inter_tree_node *P, vanilla_function *vf, int void_context) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S(", vf->identifier);
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P) {
		if (c++ > 0) WRITE(", ");
		Vanilla::node(gen, F);
	}
	WRITE(")");
	if (void_context) WRITE(";\n");
}

@h Assembly language.
In general, we make no attempt to police the supposedly valid assembly language
given to us here. Glulx has one set, Z another. Any assembly language in the Inter
tree results from kit material; and if the author of such a kit tries to use an
invalid opcode, then the result won't compile under I6, but none of that is our
business here.

The |@aread| opcode is a valid Z-machine opcode, but owing to the way I6 handles
the irreconcilable change in syntax for the same opcode in V3 and V4-5 of the
Z-machine specification, there is no good way to assemble it using |@| notation
unless we want to save the result. (See the Z-Machine Standards Document.)
As a dodge, we use the Inform 6 statement |read X Y| instead.

=
void I6TargetCode::invoke_opcode(code_generator *gtr, code_generation *gen,
	text_stream *opcode, int operand_count, inter_tree_node **operands,
	inter_tree_node *label, int label_sense) {
	text_stream *OUT = CodeGen::current(gen);
	if (Str::eq(opcode, I"@aread")) WRITE("read");
	else WRITE("%S", opcode);
	for (int opc = 0; opc < operand_count; opc++) {
		WRITE(" ");
		Vanilla::node(gen, operands[opc]);
	}
	if (label) {
		WRITE(" ?");
		if (label_sense == FALSE) WRITE("~");
		Vanilla::node(gen, label);
	}
	WRITE(";\n");
}

void I6TargetCode::assembly_marker(code_generator *gtr, code_generation *gen, inter_ti marker) {
	text_stream *OUT = CodeGen::current(gen);
	switch (marker) {
		case ASM_ARROW_ASMMARKER: WRITE("->"); break;
		case ASM_SP_ASMMARKER: WRITE("sp"); break;
		case ASM_RTRUE_ASMMARKER: WRITE("?rtrue"); break;
		case ASM_RFALSE_ASMMARKER: WRITE("?rfalse"); break;
		case ASM_NEG_ASMMARKER: WRITE("~"); break;
		case ASM_NEG_RTRUE_ASMMARKER: WRITE("?~rtrue"); break;
		case ASM_NEG_RFALSE_ASMMARKER: WRITE("?~rfalse"); break;
		default:
			WRITE_TO(STDERR, "Unimplemented assembly marker is '%d'\n", marker);
			internal_error("unimplemented assembly marker");
	}
}

@h Primitives.

=
void I6TargetCode::invoke_primitive(code_generator *gtr, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P, int void_context) {
	inter_tree *I = gen->from;
	text_stream *OUT = CodeGen::current(gen);
	inter_ti bip = Primitives::to_BIP(I, prim_name);
	
	int suppress_terminal_semicolon = (void_context)?FALSE:TRUE;
	switch (bip) {
		@<Basic arithmetic and logical operations@>;
		@<Storing or otherwise changing values@>;
		@<VM stack access@>;
		@<Control structures@>;
		@<Indirect function calls@>;
		@<Method calls@>;
		@<Property value access@>;
		@<Textual output@>;
		@<The VM object tree@>;
		default:
			WRITE_TO(STDERR, "Unimplemented primitive is '%S'\n",
				InterSymbol::identifier(prim_name));
			internal_error("unimplemented prim");
	}
	if (suppress_terminal_semicolon == FALSE) WRITE(";\n");
}

@ Mostly easy, because the Inter primitives here were so closely modelled on
their Inform 6 analogues in the first place.

For example, although |!alternative| is a very unusual linguistic feature --
it allows alternatives in several conditions, e.g., |if (x == 1 or 2 or 3) ...| --
it corresponds directly to the |or| keyword of Inform 6, so generating it is trivial.

@<Basic arithmetic and logical operations@> =
	case PLUS_BIP:			WRITE("("); VNODE_1C; WRITE(" + "); VNODE_2C; WRITE(")"); break;
	case MINUS_BIP:			WRITE("("); VNODE_1C; WRITE(" - "); VNODE_2C; WRITE(")"); break;
	case UNARYMINUS_BIP:	@<Handle unary minus@>; break;
	case TIMES_BIP:			WRITE("("); VNODE_1C; WRITE("*"); VNODE_2C; WRITE(")"); break;
	case DIVIDE_BIP:		WRITE("("); VNODE_1C; WRITE("/"); VNODE_2C; WRITE(")"); break;
	case MODULO_BIP:		WRITE("("); VNODE_1C; WRITE("%%"); VNODE_2C; WRITE(")"); break;
	case BITWISEAND_BIP:	WRITE("(("); VNODE_1C; WRITE(")&("); VNODE_2C; WRITE("))"); break;
	case BITWISEOR_BIP:		WRITE("(("); VNODE_1C; WRITE(")|("); VNODE_2C; WRITE("))"); break;
	case BITWISENOT_BIP:	WRITE("(~("); VNODE_1C; WRITE("))"); break;
	case NOT_BIP:			WRITE("(~~("); VNODE_1C; WRITE("))"); break;
	case AND_BIP:			WRITE("(("); VNODE_1C; WRITE(") && ("); VNODE_2C; WRITE("))"); break;
	case OR_BIP: 			WRITE("(("); VNODE_1C; WRITE(") || ("); VNODE_2C; WRITE("))"); break;
	case EQ_BIP: 			WRITE("("); VNODE_1C; WRITE(" == "); VNODE_2C; WRITE(")"); break;
	case NE_BIP: 			WRITE("("); VNODE_1C; WRITE(" ~= "); VNODE_2C; WRITE(")"); break;
	case GT_BIP: 			WRITE("("); VNODE_1C; WRITE(" > "); VNODE_2C; WRITE(")"); break;
	case GE_BIP: 			WRITE("("); VNODE_1C; WRITE(" >= "); VNODE_2C; WRITE(")"); break;
	case LT_BIP: 			WRITE("("); VNODE_1C; WRITE(" < "); VNODE_2C; WRITE(")"); break;
	case LE_BIP: 			WRITE("("); VNODE_1C; WRITE(" <= "); VNODE_2C; WRITE(")"); break;
	case OFCLASS_BIP:		WRITE("("); VNODE_1C; WRITE(" ofclass "); VNODE_2C; WRITE(")"); break;
	case IN_BIP:			WRITE("("); VNODE_1C; WRITE(" in "); VNODE_2C; WRITE(")"); break;
	case NOTIN_BIP:			WRITE("("); VNODE_1C; WRITE(" notin "); VNODE_2C; WRITE(")"); break;
	case LOOKUP_BIP:		WRITE("("); VNODE_1C; WRITE("-->("); VNODE_2C; WRITE("))"); break;
	case LOOKUPBYTE_BIP:	WRITE("("); VNODE_1C; WRITE("->("); VNODE_2C; WRITE("))"); break;
	case ALTERNATIVE_BIP:	VNODE_1C; WRITE(" or "); VNODE_2C; break;
	case SEQUENTIAL_BIP:    WRITE("("); VNODE_1C; WRITE(","); VNODE_2C; WRITE(")"); break;
	case TERNARYSEQUENTIAL_BIP: @<Generate primitive for ternarysequential@>; break;
	case RANDOM_BIP:        WRITE("random("); VNODE_1C; WRITE(")"); break;

@ In general, Inform 6 is able to constant-fold, that is, to evaluate expressions
between constants at compile time: for example, |5+6| will be compiled as |11|,
not as code to add |5| to |6|. But in just a few contexts, notably as case values
in |switch| statements, constants won't fold. This in particular affects unary
minus, so that |(-(23))| is not syntactically valid as a switch case. So we
omit the brackets for applications of unary minus which are simple enough to
do so. (See Jira bug I7-2304.)

@<Handle unary minus@> =
	if (Inode::get_construct_ID(InterTree::first_child(P)) == VAL_IST) {
		WRITE("-"); VNODE_1C;
	} else {
		WRITE("(-("); VNODE_1C; WRITE("))");
	}

@ But the unfortunate |!ternarysequential a b c| needs some gymnastics. It
would be trivial to generate to C with the serial comma operator: |(a, b, c)|
evaluates |a|, then throws that away and evaluates |b|, then throws that away
too and returns the value of |c|.

The same effect is annoyingly difficult to get out of the sometimes shaky I6
compiler's expression parser. I6 does support the comma operator, so at first
sight |(a, b, c)| ought to work in I6, too. And it does, right up to the point
where some of the token values themselves include invocations of functions. It
is a known infelicity of the I6 syntax analyser that it won't always allow the
serial comma to be mixed in the same expression with the function argument
comma: for example in the case |(a(b, c), d)|, where the first comma constructs
a list of arguments and the second is the operator. (Many such expressions work
fine in I6 -- but not all.)

That being so, we use the following circumlocution:
= (text as Inform 6)
	(c) + 0*((b) + (a))
=
Because I6 evaluates the leaves in an expression tree right-to-left, not
left-to-right, the parameter assignments happen first, then the conditions,
then the result.

@<Generate primitive for ternarysequential@> =
	WRITE("(\n"); INDENT;
	WRITE("! This evaluates last\n"); VNODE_3C;
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("0*(\n"); INDENT;
	WRITE("! This evaluates second\n");
	WRITE("((\n"); INDENT; VNODE_2C;
	OUTDENT; WRITE("\n))\n");
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("! This evaluate first\n");
	WRITE("("); VNODE_1C; WRITE(")");
	OUTDENT; WRITE(")\n");
	OUTDENT; WRITE(")\n");

@ These are the seven primitives which change a storage item given by a
reference, which is always the first child of the primitive node. It might,
for example, be a global variable, or a memory location.

@<Storing or otherwise changing values@> =
	case STORE_BIP:			@<Perform a store@>; break;
	case PREINCREMENT_BIP:	@<Perform a store@>; break;
	case POSTINCREMENT_BIP: @<Perform a store@>; break;
	case PREDECREMENT_BIP:	@<Perform a store@>; break;
	case POSTDECREMENT_BIP:	@<Perform a store@>; break;
	case SETBIT_BIP:		@<Perform a store@>; break;
	case CLEARBIT_BIP:		@<Perform a store@>; break;

@<Perform a store@> =
	inter_tree_node *storage_ref = InterTree::first_child(P);	
	if (storage_ref->W.instruction[0] == REFERENCE_IST)
		storage_ref = InterTree::first_child(storage_ref);
	if ((ReferenceInstruction::node_is_ref_to(gen->from, InterTree::first_child(P),
		PROPERTYVALUE_BIP)) &&
		(I6TargetCode::pval_case(storage_ref) != I6G_CAN_PROVE_IS_OBJ_PROPERTY)) {
		@<Alter a property value@>;
	} else {
		@<Alter some other storage@>;
	}

@ The easy case first: here, whatever the storage is (for example, a variable),
it's one that we can simply treat as an lvalue in Inform 6 (for example, by giving
its variable name). For example, the memory location |A-->3| can be assigned to,
or can have |++| or |--| applied to it in I6.

Note that this case even includes some property values: if we can see that |P|
is the explicit name of a property we are storing in a VM-property, then we can
use |O.P| as an Inform 6 lvalue, and all is well, and we then end up with code
such as |++(O.P)|.

@<Alter some other storage@> =
	switch (bip) {
		case PREINCREMENT_BIP:	WRITE("++("); VNODE_1C; WRITE(")"); break;
		case POSTINCREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")++"); break;
		case PREDECREMENT_BIP:	WRITE("--("); VNODE_1C; WRITE(")"); break;
		case POSTDECREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")--"); break;
		case STORE_BIP:			WRITE("("); VNODE_1C; WRITE(" = "); VNODE_2C; WRITE(")"); break;
		case SETBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" | "); VNODE_2C; break;
		case CLEARBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" &~ ("); VNODE_2C; WRITE(")"); break;
	}

@ But not all property values can be written as Inform 6 lvalues. If the I7
property P is being stored as a VM-attribute A, then there is no lvalue which
expresses the value of A for an object O: instead one must use |give O A| to
set it, |give O ~A| to unset it, and |(O has A)| to test it. And there will
also be cases where P cannot be identified at compile-time, so that we have no
way to know whether it will be stored as a VM-attribute or not.

To handle these two cases, then, we will compile an attempt to store or modify
a property value either as a |give| statement -- if we can prove P is being
stored in a VM-attribute -- or else as a function call to a general-purpose
function called |_final_change_property|.

@<Alter a property value@> =
	inter_tree_node *VP = InterTree::second_child(P);
	int set = NOT_APPLICABLE;
	if (Inode::is(VP, VAL_IST)) {
		inter_pair val = ValInstruction::value(VP);
		if (InterValuePairs::is_number(val)) {
			if (InterValuePairs::is_zero(val)) set = FALSE;
			else if (InterValuePairs::is_one(val)) set = TRUE;
		}
	}
	
	int c = I6TargetCode::pval_case(storage_ref);
	if ((c == I6G_CAN_PROVE_IS_OBJ_ATTRIBUTE) && (bip == STORE_BIP) && (set == TRUE)) {
		WRITE("give "); Vanilla::node(gen, InterTree::second_child(storage_ref));
		WRITE(" %S", I6TargetCode::inner_name(gen, InterTree::third_child(storage_ref)));
	} else if ((c == I6G_CAN_PROVE_IS_OBJ_ATTRIBUTE) && (bip == STORE_BIP) && (set == FALSE)) {
		WRITE("give "); Vanilla::node(gen, InterTree::second_child(storage_ref));
		WRITE(" ~%S", I6TargetCode::inner_name(gen, InterTree::third_child(storage_ref)));
	} else {
		WRITE("(");
		switch (bip) {
			case STORE_BIP:			WRITE("_final_store_property"); break;
			case PREINCREMENT_BIP:	WRITE("_final_preinc_property"); break;
			case POSTINCREMENT_BIP:	WRITE("_final_postinc_property"); break;
			case PREDECREMENT_BIP:	WRITE("_final_predec_property"); break;
			case POSTDECREMENT_BIP:	WRITE("_final_postdec_property"); break;
			case SETBIT_BIP:		WRITE("_final_setbit_property"); break;
			case CLEARBIT_BIP:		WRITE("_final_clearbit_property"); break;
		}
		WRITE("(");
		Vanilla::node(gen, InterTree::first_child(storage_ref));
		WRITE(",");
		Vanilla::node(gen, InterTree::second_child(storage_ref));
		WRITE(",");
		Vanilla::node(gen, InterTree::third_child(storage_ref));
		switch (bip) {
			case STORE_BIP:			WRITE(", "); VNODE_2C; break;
			case SETBIT_BIP:		WRITE(", "); VNODE_2C; break;
			case CLEARBIT_BIP:		WRITE(", "); VNODE_2C; break;
		}
		WRITE("))");
	}

@ Reading property values is easier. The general case, similarly, is to call a
function for this, but an important optimisation collapses this to the use of
the |has| or |.| operators in I6 where we can prove at compile-time that the
property in question is stored as a VM-attribute (resp., a VM-property) of
what is definitely a VM-object. This optimisation results in faster code.

@<Property value access@> =
	case PROPERTYEXISTS_BIP: 
		I6_GEN_DATA(value_ranges_needed) = TRUE;
		I6_GEN_DATA(value_property_holders_needed) = TRUE;
		WRITE("(_final_propertyexists("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE("))"); break;
	case PROPERTYARRAY_BIP: WRITE("(_final_propertyarray("); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE("))"); break;
	case PROPERTYLENGTH_BIP: WRITE("(_final_propertylength("); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE("))"); break;
	case PROPERTYVALUE_BIP: {
		inter_tree_node *KP = InterTree::first_child(P);
		inter_tree_node *OP = InterTree::second_child(P);
		inter_tree_node *PP = InterTree::third_child(P);
		switch (I6TargetCode::pval_case(P)) {
			case I6G_CAN_PROVE_IS_OBJ_ATTRIBUTE:
				WRITE("("); VNODE_2C;
				WRITE(" has %S", I6TargetCode::inner_name(gen, PP)); WRITE(")"); break;
			case I6G_CAN_PROVE_IS_OBJ_PROPERTY:
				WRITE("("); VNODE_2C;
				WRITE(".%S", I6TargetCode::inner_name(gen, PP)); WRITE(")"); break;
			case I6G_CANNOT_PROVE:
				I6_GEN_DATA(value_property_holders_needed) = TRUE;
				I6TargetCode::eval_property_list(gen, KP, OP, PP, 0); break;
		}
		break;
	}

@ In the most general case of |!propertyvalue|, we will end up calling the function
|_final_propertyvalue|. But we don't do so right away because, annoyingly, |!propertyvalue|
can have |!alternative| children supplied. We might find this, for example:
= (text as Inter)
inv !if
	inv !propertyvalue
		val K_object harmonium
		inv !alternative
		    val K_value P_sonorous
		    val K_value P_muted
=
...arising from kit code such as |if (harmonium has sonorous or muted) ...|.
This only seldom arises, so perhaps we can be given for handling it less than
optimally in all cases. We turn it into:
= (text as Inform 6)
	if (((or_tmp_var = harmonium) && (or_tmp_var has sonorous)) ||
		(or_tmp_var has muted))
=
Note that |or_tmp_var| is used here so that the left operand, i.e., the object,
is evaluated only once -- in case there are side-effects of the evaluation.

=
void I6TargetCode::eval_property_list(code_generation *gen, inter_tree_node *K, 
	inter_tree_node *X, inter_tree_node *Y, int depth) {
	text_stream *OUT = CodeGen::current(gen);
	if (Inode::is(Y, INV_IST)) {
		if (InvInstruction::method(Y) == PRIMITIVE_INVMETH) {
			inter_symbol *prim = InvInstruction::primitive(Y);
			inter_ti ybip = Primitives::to_BIP(gen->from, prim);
			if (ybip == ALTERNATIVE_BIP) {
				if (depth == 0) { WRITE("((or_tmp_var = "); Vanilla::node(gen, X); WRITE(") && (("); }
				I6TargetCode::eval_property_list(gen, K, NULL, InterTree::first_child(Y), depth+1);
				WRITE(") || (");
				I6TargetCode::eval_property_list(gen, K, NULL, InterTree::second_child(Y), depth+1);
				if (depth == 0) { WRITE(")))"); }
				return;
			}
		}
	}
	switch (I6TargetCode::pval_case_inner(K, Y)) {
		case I6G_CAN_PROVE_IS_OBJ_ATTRIBUTE:
			WRITE("("); if (X) Vanilla::node(gen, X); else WRITE("or_tmp_var");
			WRITE(" has %S", I6TargetCode::inner_name(gen, Y)); WRITE(")"); break;
		case I6G_CAN_PROVE_IS_OBJ_PROPERTY:
			WRITE("("); if (X) Vanilla::node(gen, X); else WRITE("or_tmp_var");
			WRITE(".%S", I6TargetCode::inner_name(gen, Y)); WRITE(")"); break;
		case I6G_CANNOT_PROVE:
			WRITE("_final_propertyvalue(");
			Vanilla::node(gen, K);
			WRITE(", ");
			if (X) Vanilla::node(gen, X); else WRITE("or_tmp_var");
			WRITE(", "); 
			Vanilla::node(gen, Y);
			WRITE(")"); break;
	}
}

@<VM stack access@> =
	case PUSH_BIP:			WRITE("@push "); VNODE_1C; break;
	case PULL_BIP:			WRITE("@pull "); VNODE_1C; break;

@<Control structures@> =
	case BREAK_BIP:			WRITE("break"); break;
	case CONTINUE_BIP:		WRITE("continue"); break;
	case RETURN_BIP: 		@<Generate primitive for return@>; break;
	case JUMP_BIP: 			WRITE("jump "); VNODE_1C; break;
	case QUIT_BIP: 			WRITE("quit"); break;
	case RESTORE_BIP: 		WRITE("restore "); VNODE_1C; break;
	case IF_BIP:            @<Generate primitive for if@>; break;
	case IFDEBUG_BIP:       @<Generate primitive for ifdebug@>; break;
	case IFSTRICT_BIP:      @<Generate primitive for ifstrict@>; break;
	case IFELSE_BIP:        @<Generate primitive for ifelse@>; break;
	case WHILE_BIP:         @<Generate primitive for while@>; break;
	case DO_BIP:            @<Generate primitive for do@>; break;
	case FOR_BIP:           @<Generate primitive for for@>; break;
	case OBJECTLOOP_BIP:    @<Generate primitive for objectloop@>; break;
	case OBJECTLOOPX_BIP:   @<Generate primitive for objectloopx@>; break;
	case SWITCH_BIP:        @<Generate primitive for switch@>; break;
	case CASE_BIP:          @<Generate primitive for case@>; break;
	case ALTERNATIVECASE_BIP: VNODE_1C; WRITE(", "); VNODE_2C; break;
	case DEFAULT_BIP:       @<Generate primitive for default@>; break;

@<Generate primitive for return@> =
	int rboolean = NOT_APPLICABLE;
	inter_tree_node *V = InterTree::first_child(P);
	if (Inode::is(V, VAL_IST)) {
		inter_pair val = ValInstruction::value(V);
		if (InterValuePairs::is_zero(val)) rboolean = FALSE;
		else if (InterValuePairs::is_one(val)) rboolean = TRUE;
	}
	switch (rboolean) {
		case FALSE: WRITE("rfalse"); break;
		case TRUE: WRITE("rtrue"); break;
		case NOT_APPLICABLE: WRITE("return "); Vanilla::node(gen, V); break;
	}

@<Generate primitive for if@> =
	WRITE("if ("); VNODE_1C; WRITE(") {\n"); INDENT; VNODE_2C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifdebug@> =
	WRITE("#ifdef DEBUG;\n"); INDENT; VNODE_1C; OUTDENT; WRITE("#endif;\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifstrict@> =
	WRITE("#ifdef STRICT_MODE;\n"); INDENT; VNODE_1C; OUTDENT; WRITE("#endif;\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifelse@> =
	WRITE("if ("); VNODE_1C; WRITE(") {\n"); INDENT; VNODE_2C; OUTDENT;
	WRITE("} else {\n"); INDENT; VNODE_3C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for while@> =
	WRITE("while ("); VNODE_1C; WRITE(") {\n"); INDENT; VNODE_2C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for do@> =
	WRITE("do {"); VNODE_2C; WRITE("} until (\n"); INDENT; VNODE_1C; OUTDENT; WRITE(")\n");

@<Generate primitive for for@> =
	WRITE("for (");
	inter_tree_node *INIT = InterTree::first_child(P);
	if (!((Inode::is(INIT, VAL_IST)) &&
		(InterValuePairs::is_number(ValInstruction::value(INIT))) &&
		(InterValuePairs::to_number(ValInstruction::value(INIT)) == 1)))
			VNODE_1C;
	WRITE(":"); VNODE_2C;
	WRITE(":");
	inter_tree_node *U = InterTree::third_child(P);
	if (Inode::isnt(U, VAL_IST))
	Vanilla::node(gen, U);
	WRITE(") {\n"); INDENT; VNODE_4C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloop@> =
	int in_flag = FALSE;
	inter_tree_node *U = InterTree::third_child(P);
	if ((Inode::is(U, INV_IST)) &&
		(InvInstruction::method(U) == PRIMITIVE_INVMETH)) {
		inter_symbol *prim = InvInstruction::primitive(U);
		if ((prim) && (Primitives::to_BIP(I, prim) == IN_BIP)) in_flag = TRUE;
	}

	WRITE("objectloop ");
	if (in_flag == FALSE) {
		WRITE("("); VNODE_1C; WRITE(" ofclass "); VNODE_2C;
		WRITE(" && ");
	} VNODE_3C;
	if (in_flag == FALSE) {
		WRITE(")");
	}
	WRITE(" {\n"); INDENT; VNODE_4C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloopx@> =
	WRITE("objectloop ("); VNODE_1C; WRITE(" ofclass "); VNODE_2C;
	WRITE(") {\n"); INDENT; VNODE_3C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for switch@> =
	WRITE("switch ("); VNODE_1C;
	WRITE(") {\n"); INDENT; VNODE_2C; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for case@> =
	VNODE_1C; WRITE(":\n"); INDENT; VNODE_2C; WRITE(";\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for default@> =
	WRITE("default:\n"); INDENT; VNODE_1C; WRITE(";\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@ In Inform 6, as in C, a function which returns a value can be called in a void
context (in which case its return value is thrown away); the syntax for calling
a void function is identical to that for calling a value-returning function, so
we can treat |INDIRECT0V_BIP| as the same as |INDIRECT0_BIP|, and so on.

@<Indirect function calls@> =
	case INDIRECT0_BIP: case INDIRECT0V_BIP:
	    WRITE("("); VNODE_1C; WRITE(")()"); break;
	case INDIRECT1_BIP: case INDIRECT1V_BIP:
		WRITE("("); VNODE_1C; WRITE(")("); VNODE_2C; WRITE(")"); break;
	case INDIRECT2_BIP: case INDIRECT2V_BIP:
		WRITE("("); VNODE_1C; WRITE(")("); VNODE_2C; WRITE(","); VNODE_3C; WRITE(")");
		break;
	case INDIRECT3_BIP: case INDIRECT3V_BIP:
		WRITE("("); VNODE_1C; WRITE(")("); VNODE_2C; WRITE(","); VNODE_3C; WRITE(",");
		VNODE_4C; WRITE(")"); break;
	case INDIRECT4_BIP: case INDIRECT4V_BIP:
		WRITE("("); VNODE_1C; WRITE(")("); VNODE_2C; WRITE(","); VNODE_3C; WRITE(",");
		VNODE_4C; WRITE(","); VNODE_5C; WRITE(")"); break;
	case INDIRECT5_BIP: case INDIRECT5V_BIP:
		WRITE("("); VNODE_1C; WRITE(")("); VNODE_2C; WRITE(","); VNODE_3C; WRITE(",");
		VNODE_4C; WRITE(","); VNODE_5C; WRITE(","); VNODE_6C; WRITE(")"); break;
	case EXTERNALCALL_BIP:	internal_error("external calls impossible in Inform 6"); break;

@ Message calls are handled with functions (see below) in case the user is trying
to send a message to a property stored in an attribute, or something like that.

@<Method calls@> =
	case MESSAGE0_BIP: 		WRITE("_final_message0("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
	case MESSAGE1_BIP: 		WRITE("_final_message1("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
							VNODE_3C; WRITE(")"); break;
	case MESSAGE2_BIP: 		WRITE("_final_message2("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
							VNODE_3C; WRITE(","); VNODE_4C; WRITE(")"); break;
	case MESSAGE3_BIP: 		WRITE("_final_message3("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
							VNODE_3C; WRITE(","); VNODE_4C; WRITE(","); VNODE_5C; WRITE(")"); break;

@ Note that the only styles permitted are those from the original Z-machine, which
is about the level of technology of a 1970s teletype. The |!style| number must be
a constant 1, 2 or 3, or else plain roman is all you get.

@<Textual output@> =
	case PRINT_BIP:         WRITE("print "); CodeGen::lt_mode(gen, PRINTING_LTM);
							VNODE_1C; CodeGen::lt_mode(gen, REGULAR_LTM); break;
	case PRINTCHAR_BIP:     WRITE("print (char) "); VNODE_1C; break;
	case PRINTNL_BIP:       WRITE("new_line"); break;
	case PRINTOBJ_BIP:      WRITE("print (object) "); VNODE_1C; break;
	case PRINTNUMBER_BIP:   WRITE("print "); VNODE_1C; break;
	case PRINTDWORD_BIP:    WRITE("print (address) "); VNODE_1C; break;
	case PRINTSTRING_BIP:   WRITE("print (string) "); VNODE_1C; break;
	case BOX_BIP:           WRITE("box "); CodeGen::lt_mode(gen, BOX_LTM);
							VNODE_1C; CodeGen::lt_mode(gen, REGULAR_LTM); break;
	case SPACES_BIP:		WRITE("spaces "); VNODE_1C; break;
	case FONT_BIP:
		WRITE("if ("); VNODE_1C; WRITE(") { font on; } else { font off; }");
		suppress_terminal_semicolon = TRUE;
		break;
	case STYLE_BIP: {
		inter_tree_node *N = InterTree::first_child(P);
		inter_pair pair = ValInstruction::value(N);
		inter_ti style = InterValuePairs::to_number(pair);
		switch (style) {
			case 1: WRITE("style bold"); break;
			case 2: WRITE("style underline"); break;
			case 3: WRITE("style reverse"); break;
			default: WRITE("style roman");
		}
		break;
	}
	case ENABLEPRINTING_BIP:
		WRITE("#ifdef TARGET_GLULX;\n");
		WRITE("@setiosys 2 0; ! Set to use Glk\n");
		WRITE("@push 201;     ! = GG_MAINWIN_ROCK;\n");
		WRITE("@push 3;       ! = wintype_TextBuffer\n");
		WRITE("@push 0;\n");
		WRITE("@push 0;\n");
		WRITE("@push 0;\n");
		WRITE("@glk 35 5 sp;  ! glk_window_open, pushing a window ID\n");
		WRITE("@glk 47 1 0;   ! glk_set_window to that window ID\n");
		WRITE("#endif;\n");
		break;

@<The VM object tree@> =
	case MOVE_BIP:          WRITE("move "); VNODE_1C; WRITE(" to "); VNODE_2C; break;
	case REMOVE_BIP:        WRITE("remove "); VNODE_1C; break;
	case CHILD_BIP:         WRITE("child("); VNODE_1C; WRITE(")"); break;
	case CHILDREN_BIP:      WRITE("children("); VNODE_1C; WRITE(")"); break;
	case PARENT_BIP:        WRITE("parent("); VNODE_1C; WRITE(")"); break;
	case SIBLING_BIP:       WRITE("sibling("); VNODE_1C; WRITE(")"); break;
	case METACLASS_BIP:     WRITE("metaclass("); VNODE_1C; WRITE(")"); break;

@h Support code for property accesses.
In the following, |prop_node| is a |VAL_IST| identifying the property being
accessed: we return the "inner name" as text, if we can find one. This will only
happen if the node evaluates to a named symbol which is the name of a property.
See //Vanilla Objects// for more on inner names. 

=
text_stream *I6TargetCode::inner_name(code_generation *gen, inter_tree_node *prop_node) {
	inter_symbol *prop_symbol = NULL;
	if (Inode::is(prop_node, VAL_IST)) {
		inter_pair val = ValInstruction::value(prop_node);
		if (InterValuePairs::is_symbolic(val))
			prop_symbol = InterValuePairs::to_symbol_at(val, prop_node);
	}
	if ((prop_symbol) && (InterSymbol::get_flag(prop_symbol, ATTRIBUTE_MARK_ISYMF))) {
		return VanillaObjects::inner_property_name(gen, prop_symbol);
	} else if ((prop_symbol) && (Inode::is(prop_symbol->definition, PROPERTY_IST))) {
		return VanillaObjects::inner_property_name(gen, prop_symbol);
	} else {
		return NULL;
	}
}

@ |I6TargetCode::pval_case| applies to a |!propertyvalue| invocation node. That
has three children: the kind, the object/owner, and the property itself. We
look at the node and try to see if it's one of the two easy cases which enable
more efficient code to be compiled (see above): in fact, it almost always is.

(*) We return |I6G_CAN_PROVE_IS_OBJ_ATTRIBUTE| if the kind is definitely |OBJECT_TY|
and the property is stored in a VM-attribute;
(*) Or |I6G_CAN_PROVE_IS_OBJ_PROPERTY| if the kind is definitely |OBJECT_TY|
and the property is stored in a VM-property;
(*) Or |I6G_CANNOT_PROVE| if we don't know.

@d I6G_CAN_PROVE_IS_OBJ_ATTRIBUTE 1
@d I6G_CAN_PROVE_IS_OBJ_PROPERTY 2
@d I6G_CANNOT_PROVE 3

=
int I6TargetCode::pval_case(inter_tree_node *P) {
	while (Inode::is(P, REFERENCE_IST)) P = InterTree::first_child(P);
	inter_tree_node *prop_node = InterTree::third_child(P);
	return I6TargetCode::pval_case_inner(InterTree::first_child(P), prop_node);
}

int I6TargetCode::pval_case_inner(inter_tree_node *kind_node, inter_tree_node *prop_node) {
	inter_symbol *kind_symbol = NULL;
	if (Inode::is(kind_node, VAL_IST)) {
		inter_pair val = ValInstruction::value(kind_node);
		if (InterValuePairs::is_symbolic(val))
			kind_symbol = InterValuePairs::to_symbol_at(val, kind_node);
	}
	if (Str::eq(InterSymbol::trans(kind_symbol), I"OBJECT_TY") == FALSE)
		return I6G_CANNOT_PROVE;

	inter_symbol *prop_symbol = NULL;
	if (Inode::is(prop_node, VAL_IST)) {
		inter_pair val = ValInstruction::value(prop_node);
		if (InterValuePairs::is_symbolic(val))
			prop_symbol = InterValuePairs::to_symbol_at(val, prop_node);
	}
	if ((prop_symbol) && (InterSymbol::get_flag(prop_symbol, ATTRIBUTE_MARK_ISYMF))) {
		return I6G_CAN_PROVE_IS_OBJ_ATTRIBUTE;
	} else if ((prop_symbol) && (Inode::is(prop_symbol->definition, PROPERTY_IST))) {
		return I6G_CAN_PROVE_IS_OBJ_PROPERTY;
	} else {
		return I6G_CANNOT_PROVE;
	}
}

@h The final functions.
The generator above compiled calls to a handful of functions with names in the
form |_final_*|; so these functions must clearly be supplied. It might seem that
they ought to be included in, say, BasicInformKit and not here. But:

(1) They are needed only for Inform 6 usage, whereas BasicInformKit contains
material used whatever the final code-generator;
(2) They are written in genuine Inform 6 code, not kit code, which looks like
I6 and is very similar to it but is not quite the same. In kit code, |O.P| means
"the value of the property P for the object O", but where |P| is the metadata
array for the property. In genuine Inform 6, |O.P| expects |P| to be the actual
VM-property. The following functions need the latter interpretation in order to work.

=
void I6TargetCode::end_generation(code_generator *gtr, code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, functions_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	@<Most general implementation of !propertyvalue@>;
	@<Most general implementation of !propertyexists@>;
	@<Most general implementation of !propertyarray@>;
	@<Most general implementation of !propertylength@>;
	@<Most general implementation of writing to a property@>;
	@<Implementation of !messageX@>;
	CodeGen::deselect(gen, saved);
}

@ See //Inform 6 Objects// for the runtime contents of the array of property
metadata |p|. The following is more or less a safe general-purpose wrapper for
the Inform 6 operator |.|, used as an rvalue, in cases where we cannot prove
it would be safe to use |.| directly:

@<Most general implementation of !propertyvalue@> =
	WRITE("#ifdef BASICINFORMKIT;\n");
	WRITE("[ _final_propertyvalue K o p t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) { if (o has p) rtrue; rfalse; }\n");
	WRITE("            if (o provides p) return o.p;\n");
	WRITE("        }\n");
	WRITE("        rfalse;\n");
	WRITE("    } else {\n");
	WRITE("        t = value_property_holders-->K;\n");
	WRITE("        return (t.(p-->1))-->(o+COL_HSIZE);\n");
	WRITE("    }\n");
	WRITE("];\n");
	WRITE("#endif;\n");

@ Similarly, this is a safe wrapper for |provides|:

@<Most general implementation of !propertyexists@> =
	WRITE("#ifdef BASICINFORMKIT;\n");
	WRITE("[ _final_propertyexists K o p holder;\n");
	WRITE("if (K == OBJECT_TY) {\n");
	WRITE("    if ((o) && (metaclass(o) == Object)) {\n");
	WRITE("        if ((p-->0 == 2) || (o provides p-->1)) {\n");
	WRITE("            rtrue;\n");
	WRITE("        } else {\n");
	WRITE("            rfalse;\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("        rfalse;\n");
	WRITE("    }\n");
	WRITE("} else {\n");
	WRITE("    if ((o >= 1) && (o <= value_ranges-->K)) {\n");
	WRITE("        holder = value_property_holders-->K;\n");
	WRITE("        if ((holder) && (holder provides p-->1)) {\n");
	WRITE("            rtrue;\n");
	WRITE("        } else {\n");
	WRITE("            rfalse;\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("        rfalse;\n");
	WRITE("    }\n");
	WRITE("}\n");
	WRITE("rfalse; ];\n");
	WRITE("#endif;\n");

@ And this for |.&|. Note that we always return 0 if the owner is not an object.

@<Most general implementation of !propertyarray@> =
	WRITE("#ifdef BASICINFORMKIT;\n");
	WRITE("[ _final_propertyarray K o p v t;\n");
	WRITE("    if (K ~= OBJECT_TY) return 0;\n");
	WRITE("    t = p-->0; p = p-->1;\n");
	WRITE("    if (t == 2) return 0;\n");
	WRITE("    return o.&p;\n");
	WRITE("];\n");
	WRITE("#endif;\n");

@ And this for |.#|. Again, we always return 0 if the owner is not an object.

@<Most general implementation of !propertylength@> =
	WRITE("#ifdef BASICINFORMKIT;\n");
	WRITE("[ _final_propertylength K o p v t;\n");
	WRITE("    if (K ~= OBJECT_TY) return 0;\n");
	WRITE("    t = p-->0; p = p-->1;\n");
	WRITE("    if (t == 2) return 0;\n");
	WRITE("    return o.#p;\n");
	WRITE("];\n");
	WRITE("#endif;\n");

@ And this is a safe way to write to or otherwise alter |O.P|, laboriously
written out as seven functions. (Speed is more important than conciseness here.)

@<Most general implementation of writing to a property@> =
	WRITE("#ifdef BASICINFORMKIT;\n");
	WRITE("[ _final_store_property K o p v t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) {\n");
	WRITE("                if (v) give o p; else give o ~p;\n");
	WRITE("            } else if (o provides p) {\n");
	WRITE("                o.p = v;\n");
	WRITE("            }\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("        ((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE) = v;\n");
	WRITE("    }\n");
	WRITE("];\n");
	WRITE("[ _final_preinc_property K o p t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) {\n");
	WRITE("                if (o has p) { give o ~p; rfalse; } give o p; rtrue;\n");
	WRITE("            } else if (o provides p) {\n");
	WRITE("                return ++(o.p);\n");
	WRITE("            }\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("       return ++(((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE));\n");
	WRITE("    }\n");
	WRITE("    return 0;\n");
	WRITE("];\n");
	WRITE("[ _final_predec_property K o p t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) {\n");
	WRITE("                if (o has p) { give o ~p; rfalse; } give o p; rtrue;\n");
	WRITE("            } else if (o provides p) {\n");
	WRITE("                return --(o.p);\n");
	WRITE("            }\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("       return --(((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE));\n");
	WRITE("    }\n");
	WRITE("    return 0;\n");
	WRITE("];\n");
	WRITE("[ _final_postinc_property K o p t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) {\n");
	WRITE("                if (o has p) { give o ~p; rtrue; } give o p; rfalse;\n");
	WRITE("            } else if (o provides p) {\n");
	WRITE("                return (o.p)++;\n");
	WRITE("            }\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("       return (((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE))++;\n");
	WRITE("    }\n");
	WRITE("    return 0;\n");
	WRITE("];\n");
	WRITE("[ _final_postdec_property K o p t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) {\n");
	WRITE("                if (o has p) { give o ~p; rtrue; } give o p; rfalse;\n");
	WRITE("            } else if (o provides p) {\n");
	WRITE("                return (o.p)--;\n");
	WRITE("            }\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("       return (((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE))--;\n");
	WRITE("    }\n");
	WRITE("    return 0;\n");
	WRITE("];\n");
	WRITE("[ _final_setbit_property K o p v t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) {\n");
	WRITE("                if (v & 1) give o p;\n");
	WRITE("            } else if (o provides p) {\n");
	WRITE("                o.p = o.p | v;\n");
	WRITE("            }\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("        ((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE) =\n");
	WRITE("            ((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE) | v;\n");
	WRITE("    }\n");
	WRITE("];\n");
	WRITE("[ _final_clearbit_property K o p v t;\n");
	WRITE("    if (K == OBJECT_TY) {\n");
	WRITE("        if (metaclass(o) == Object) {\n");
	WRITE("            t = p-->0; p = p-->1;\n");
	WRITE("            if (t == 2) {\n");
	WRITE("                if (v & 1) give o ~p;\n");
	WRITE("            } else if (o provides p) {\n");
	WRITE("                o.p = o.p & ~v;\n");
	WRITE("            }\n");
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("        ((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE) =\n");
	WRITE("            ((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE) & ~v;\n");
	WRITE("    }\n");
	WRITE("];\n");
	WRITE("#endif;\n");

@ It's not entirely clear what the result of trying to send a message to an
either/or property ought to be: nobody should ever do that. We're going to say
that it's 0 here.

@<Implementation of !messageX@> =
	WRITE("#ifdef BASICINFORMKIT;\n");
	WRITE("[ _final_message0 o p q x a rv;\n");
	WRITE("    if (p-->0 == 2) return 0;\n");
	WRITE("    q = p-->1; return o.q();\n");
	WRITE("];\n");
	WRITE("[ _final_message1 o p v1 q x a rv;\n");
	WRITE("    if (p-->0 == 2) return 0;\n");
	WRITE("    q = p-->1; return o.q(v1);\n");
	WRITE("];\n");
	WRITE("[ _final_message2 o p v1 v2 q x a rv;\n");
	WRITE("    if (p-->0 == 2) return 0;\n");
	WRITE("    q = p-->1; return o.q(v1, v2);\n");
	WRITE("];\n");
	WRITE("[ _final_message3 o p v1 v2 v3 q x a rv;\n");
	WRITE("    if (p-->0 == 2) return 0;\n");
	WRITE("    q = p-->1; return o.q(v1, v2, v3);\n");
	WRITE("];\n");
	WRITE("#endif;\n");
