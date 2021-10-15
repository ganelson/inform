[I6TargetCode::] Inform 6 Code.

To generate I6 routines of imperative code.

@ =
void I6TargetCode::create_generator(code_generator *cgt) {
	METHOD_ADD(cgt, DECLARE_FUNCTION_MTID, I6TargetCode::declare_function);
	METHOD_ADD(cgt, PLACE_LABEL_MTID, I6TargetCode::place_label);
	METHOD_ADD(cgt, EVALUATE_LABEL_MTID, I6TargetCode::evaluate_label);
	METHOD_ADD(cgt, INVOKE_PRIMITIVE_MTID, I6TargetCode::invoke_primitive);
	METHOD_ADD(cgt, INVOKE_FUNCTION_MTID, I6TargetCode::invoke_function);
	METHOD_ADD(cgt, INVOKE_OPCODE_MTID, I6TargetCode::invoke_opcode);
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
void I6TargetCode::declare_function(code_generator *cgt, code_generation *gen,
	inter_symbol *fn, inter_tree_node *D) {
	segmentation_pos saved = CodeGen::select(gen, functions_I7CGS);
	text_stream *fn_name = Inter::Symbols::name(fn);
	text_stream *OUT = CodeGen::current(gen);
	@<Open the function@>;

	if (Str::eq(fn_name, I"Main"))                 @<Inject code at the top of Main@>;
	if (Str::eq(fn_name, I"DebugAction"))          @<Inject code at the top of DebugAction@>;
	if (Str::eq(fn_name, I"DebugAttribute"))       @<Inject code at the top of DebugAttribute@>;
	if (Str::eq(fn_name, I"DebugProperty"))        @<Inject code at the top of DebugProperty@>;
	if (Str::eq(fn_name, I"FINAL_CODE_STARTUP_R")) @<Inject code at the top of FINAL_CODE_STARTUP_R@>;

	Vanilla::node(gen, D); /* This compiles the body of the function */

	@<Close the function@>;
	CodeGen::deselect(gen, saved);
}

@<Open the function@> =
	WRITE("[ %S", fn_name);
	I6TargetCode::seek_locals(gen, D);
	WRITE(";");

@ =
void I6TargetCode::seek_locals(code_generation *gen, inter_tree_node *P) {
	if (P->W.data[ID_IFLD] == LOCAL_IST) {
		inter_package *pack = Inter::Packages::container(P);
		inter_symbol *var_name =
			InterSymbolsTables::local_symbol_from_id(pack, P->W.data[DEFN_LOCAL_IFLD]);
		text_stream *OUT = CodeGen::current(gen);
		WRITE(" %S", var_name->symbol_name);
	}
	LOOP_THROUGH_INTER_CHILDREN(F, P) I6TargetCode::seek_locals(gen, F);
}

@<Close the function@> =
	WRITE("];\n");

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
	WRITE("@accelfunc 2 CP__Tab;\n");
	WRITE("@accelfunc 3 RA__Pr;\n");
	WRITE("@accelfunc 4 RL__Pr;\n");
	WRITE("@accelfunc 5 OC__Cl;\n");
	WRITE("@accelfunc 6 RV__Pr;\n");
	WRITE("@accelfunc 7 OP__Pr;\n");
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
void I6TargetCode::place_label(code_generator *cgt, code_generation *gen,
	text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S;\n", label_name);
}
void I6TargetCode::evaluate_label(code_generator *cgt, code_generation *gen,
	text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

@h Function invocations.
Or in other words, function calls. These are easy: the syntax is exactly what
it would be for C.

=
void I6TargetCode::invoke_function(code_generator *cgt, code_generation *gen,
	inter_symbol *fn, inter_tree_node *P, int void_context) {
	text_stream *fn_name = Inter::Symbols::name(fn);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S(", fn_name);
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
given to us here. Glulx has one set, Z another.

The |@aread| opcode is a valid Z-machine opcode, but owing to the way I6 handles
the irreconcilable change in syntax for the same opcode in V3 and V4-5 of the
Z-machine specification, there is no good way to assemble it using |@| notation
unless we want to save the result. (See the Z-Machine Standards Document.)
As a dodge, we use the Inform 6 statement |read X Y| instead.

The three pseudo-opcodes |@provides_gprop|, |@read_gprop| and |@write_gprop| are
however not valid for either Z or G.

=
void I6TargetCode::invoke_opcode(code_generator *cgt, code_generation *gen,
	text_stream *opcode, int operand_count, inter_tree_node **operands,
	inter_tree_node *label, int label_sense, int void_context) {
	text_stream *OUT = CodeGen::current(gen);
	if (Str::eq(opcode, I"@provides_gprop")) @<Invoke special provides_gprop@>;
	if (Str::eq(opcode, I"@read_gprop")) @<Invoke special read_gprop@>;
	if (Str::eq(opcode, I"@write_gprop")) @<Invoke special write_gprop@>;
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
	if (void_context) WRITE(";\n");
}

@<Invoke special provides_gprop@> =
	TEMPORARY_TEXT(K)
	TEMPORARY_TEXT(obj)
	TEMPORARY_TEXT(p)
	TEMPORARY_TEXT(val)
	CodeGen::select_temporary(gen, K);
	Vanilla::node(gen, operands[0]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, obj);
	Vanilla::node(gen, operands[1]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, p);
	Vanilla::node(gen, operands[2]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, val);
	Vanilla::node(gen, operands[3]);
	CodeGen::deselect_temporary(gen);

	I6_GEN_DATA(value_ranges_needed) = TRUE;
	I6_GEN_DATA(value_property_holders_needed) = TRUE;

	WRITE("if (%S == OBJECT_TY) {\n", K);
	WRITE("    if ((%S) && (metaclass(%S) == Object)) {\n", obj, obj);
	WRITE("        if ((%S-->0 == 2) || (%S provides %S-->1)) {\n", p, obj, p);
	WRITE("            %S = 1;\n", val);
	WRITE("        } else {\n");
	WRITE("            %S = 0;\n", val);
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("        %S = 0;\n", val);
	WRITE("    }\n");
	WRITE("} else {\n");
	WRITE("    if ((%S >= 1) && (%S <= value_ranges-->%S)) {\n", obj, obj, K);
	WRITE("        holder = value_property_holders-->%S;\n", K);
	WRITE("        if ((holder) && (holder provides %S-->1)) {\n", p);
	WRITE("            %S = 1;\n", val);
	WRITE("        } else {\n");
	WRITE("            %S = 0;\n", val);
	WRITE("        }\n");
	WRITE("    } else {\n");
	WRITE("        %S = 0;\n", val);
	WRITE("    }\n");
	WRITE("}\n");

	DISCARD_TEXT(K)
	DISCARD_TEXT(obj)
	DISCARD_TEXT(p)
	DISCARD_TEXT(val)
	return;

@<Invoke special read_gprop@> =
	TEMPORARY_TEXT(K)
	TEMPORARY_TEXT(obj)
	TEMPORARY_TEXT(p)
	TEMPORARY_TEXT(val)
	CodeGen::select_temporary(gen, K);
	Vanilla::node(gen, operands[0]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, obj);
	Vanilla::node(gen, operands[1]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, p);
	Vanilla::node(gen, operands[2]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, val);
	Vanilla::node(gen, operands[3]);
	CodeGen::deselect_temporary(gen);

	I6_GEN_DATA(value_property_holders_needed) = TRUE;

	WRITE("if (%S == OBJECT_TY) {\n", K);
	WRITE("    if (%S-->0 == 2) {\n", p);
	WRITE("        if (%S has %S-->1) %S = 1; else %S = 0;\n", obj, p, val, val);
	WRITE("    } else {\n");
	WRITE("        if (%S-->1 == door_to) %S = %S.(%S-->1)();\n", p, val, obj, p);
	WRITE("        else %S = %S.(%S-->1);\n", val, obj, p);
	WRITE("    }\n");
	WRITE("} else {\n");
	WRITE("    holder = value_property_holders-->%S;\n", K);
	WRITE("    %S = (holder.(%S-->1))-->(%S+COL_HSIZE);\n", val, p, obj);
	WRITE("}\n");

	DISCARD_TEXT(K)
	DISCARD_TEXT(obj)
	DISCARD_TEXT(p)
	DISCARD_TEXT(val)
	return;

@<Invoke special write_gprop@> =
	TEMPORARY_TEXT(K)
	TEMPORARY_TEXT(obj)
	TEMPORARY_TEXT(p)
	TEMPORARY_TEXT(val)
	CodeGen::select_temporary(gen, K);
	Vanilla::node(gen, operands[0]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, obj);
	Vanilla::node(gen, operands[1]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, p);
	Vanilla::node(gen, operands[2]);
	CodeGen::deselect_temporary(gen);
	CodeGen::select_temporary(gen, val);
	Vanilla::node(gen, operands[3]);
	CodeGen::deselect_temporary(gen);

	I6_GEN_DATA(value_property_holders_needed) = TRUE;

	WRITE("if (%S == OBJECT_TY) {\n", K);
	WRITE("    if (%S-->0 == 2) {\n", p);
	WRITE("        if (%S) give %S %S-->1; else give %S ~(%S-->1);\n", val, obj, p, obj, p);
	WRITE("    } else {\n");
	WRITE("        %S.(%S-->1) = %S;\n", obj, p, val);
	WRITE("    }\n");
	WRITE("} else {\n");
	WRITE("    ((value_property_holders-->%S).(%S-->1))-->(%S+COL_HSIZE) = %S;\n", K, p, obj, val);
	WRITE("}\n");

	DISCARD_TEXT(K)
	DISCARD_TEXT(obj)
	DISCARD_TEXT(p)
	DISCARD_TEXT(val)
	return;

@ =
int i6_next_is_a_ref = FALSE, i6_next_is_a_give = FALSE, i6_next_is_a_take = FALSE;
void I6TargetCode::invoke_primitive(code_generator *cgt, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P, int void_context) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_bip(I, prim_name);
	text_stream *store_form = NULL;
	
	switch (bip) {
		@<Basic arithmetic and logical operations@>;
		@<Storing or otherwise changing values@>;
		@<VM stack access@>;
		@<Control structures@>;
		@<Indirect function or method calls@>;
		@<Property value access@>;
		@<Textual output@>;
		@<The VM object tree@>;
		@<Random number generator@>;
		default:
			WRITE_TO(STDERR, "Unimplemented primitive is '%S'\n", prim_name->symbol_name);
			internal_error("unimplemented prim");
	}
	if ((void_context) && (suppress_terminal_semicolon == FALSE)) WRITE(";\n");
}

@<Basic arithmetic and logical operations@> =
	case PLUS_BIP:			WRITE("("); VNODE_1C; WRITE(" + "); VNODE_2C; WRITE(")"); break;
	case MINUS_BIP:			WRITE("("); VNODE_1C; WRITE(" - "); VNODE_2C; WRITE(")"); break;
	case UNARYMINUS_BIP:	WRITE("(-("); VNODE_1C; WRITE("))"); break;
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
	case SEQUENTIAL_BIP: WRITE("("); VNODE_1C; WRITE(","); VNODE_2C; WRITE(")"); break;
	case TERNARYSEQUENTIAL_BIP: @<Generate primitive for ternarysequential@>; break;
	case ALTERNATIVE_BIP:	VNODE_1C; WRITE(" or "); VNODE_2C; break;

@<Storing or otherwise changing values@> =
	case STORE_BIP:			store_form = I"i7_lvalue_SET"; @<Perform a store@>; break;
	case PREINCREMENT_BIP:	store_form = I"i7_lvalue_PREINC"; @<Perform a store@>; break;
	case POSTINCREMENT_BIP:	store_form = I"i7_lvalue_POSTINC"; @<Perform a store@>; break;
	case PREDECREMENT_BIP:	store_form = I"i7_lvalue_PREDEC"; @<Perform a store@>; break;
	case POSTDECREMENT_BIP:	store_form = I"i7_lvalue_POSTDEC"; @<Perform a store@>; break;
	case SETBIT_BIP:		store_form = I"i7_lvalue_SETBIT"; @<Perform a store@>; break;
	case CLEARBIT_BIP:		store_form = I"i7_lvalue_CLEARBIT"; @<Perform a store@>; break;

@<Property value access@> =
	case PROPERTYEXISTS_BIP:
		I6_GEN_DATA(value_ranges_needed) = TRUE;
		I6_GEN_DATA(value_property_holders_needed) = TRUE;
		WRITE("(_final_provides(OBJECT_TY, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE("))"); break;
//		WRITE("("); VNODE_1C; WRITE(" provides ("); VNODE_2C; WRITE("-->1))"); break;
	case XPROPERTYEXISTS_BIP: 
		I6_GEN_DATA(value_ranges_needed) = TRUE;
		I6_GEN_DATA(value_property_holders_needed) = TRUE;
		WRITE("(_final_provides("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", "); VNODE_3C; WRITE("))"); break;
	case PROPERTYADDRESS_BIP: WRITE("(_final_read_paddr("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE("))"); break;
	case PROPERTYLENGTH_BIP: WRITE("(_final_read_plen("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE("))"); break;
	case PROPERTYVALUE_BIP:	if (i6_next_is_a_give)
								@<Write attribute give@>
							else if (i6_next_is_a_take)
								@<Write attribute take@>
							else if (i6_next_is_a_ref)
								@<Write property value@>
							else
								@<Evaluate property value@>;
							break;

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
	case IF_BIP: @<Generate primitive for if@>; break;
	case IFDEBUG_BIP: @<Generate primitive for ifdebug@>; break;
	case IFSTRICT_BIP: @<Generate primitive for ifstrict@>; break;
	case IFELSE_BIP: @<Generate primitive for ifelse@>; break;
	case WHILE_BIP: @<Generate primitive for while@>; break;
	case DO_BIP: @<Generate primitive for do@>; break;
	case FOR_BIP: @<Generate primitive for for@>; break;
	case OBJECTLOOP_BIP: @<Generate primitive for objectloop@>; break;
	case OBJECTLOOPX_BIP: @<Generate primitive for objectloopx@>; break;
	case LOOP_BIP: @<Generate primitive for loop@>; break;
	case SWITCH_BIP: @<Generate primitive for switch@>; break;
	case CASE_BIP: @<Generate primitive for case@>; break;
	case ALTERNATIVECASE_BIP: VNODE_1C; WRITE(", "); VNODE_2C; break;
	case DEFAULT_BIP: @<Generate primitive for default@>; break;

@<Indirect function or method calls@> =
	case INDIRECT0_BIP: case INDIRECT0V_BIP: case CALLMESSAGE0_BIP:
							WRITE("("); VNODE_1C; WRITE(")()"); break;
	case INDIRECT1_BIP: case INDIRECT1V_BIP: case CALLMESSAGE1_BIP:
							WRITE("("); VNODE_1C; WRITE(")(");
							VNODE_2C; WRITE(")"); break;
	case INDIRECT2_BIP: case INDIRECT2V_BIP: case CALLMESSAGE2_BIP:
							WRITE("("); VNODE_1C; WRITE(")(");
							VNODE_2C; WRITE(","); VNODE_3C; WRITE(")"); break;
	case INDIRECT3_BIP: case INDIRECT3V_BIP: case CALLMESSAGE3_BIP:
							WRITE("("); VNODE_1C; WRITE(")(");
							VNODE_2C; WRITE(","); VNODE_3C; WRITE(","); VNODE_4C; WRITE(")"); break;
	case INDIRECT4_BIP: case INDIRECT4V_BIP:
							WRITE("("); VNODE_1C; WRITE(")(");
							VNODE_2C; WRITE(","); VNODE_3C; WRITE(","); VNODE_4C; WRITE(",");
							VNODE_5C; WRITE(")"); break;
	case INDIRECT5_BIP: case INDIRECT5V_BIP:
							WRITE("("); VNODE_1C; WRITE(")(");
							VNODE_2C; WRITE(","); VNODE_3C; WRITE(","); VNODE_4C; WRITE(",");
							VNODE_5C; WRITE(","); VNODE_6C; WRITE(")"); break;
	case MESSAGE0_BIP: 		WRITE("_final_message0("); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
	case MESSAGE1_BIP: 		WRITE("("); VNODE_1C; WRITE(".("); VNODE_2C; WRITE("-->1)(");
							VNODE_3C; WRITE("))"); break;
	case MESSAGE2_BIP: 		WRITE("("); VNODE_1C; WRITE(".("); VNODE_2C; WRITE("-->1)(");
							VNODE_3C; WRITE(","); VNODE_4C; WRITE("))"); break;
	case MESSAGE3_BIP: 		WRITE("("); VNODE_1C; WRITE(".("); VNODE_2C; WRITE("-->1)(");
							VNODE_3C; WRITE(","); VNODE_4C; WRITE(","); VNODE_5C; WRITE("))"); break;

	case EXTERNALCALL_BIP:	internal_error("external calls impossible in Inform 6"); break;

@<Textual output@> =
	case PRINT_BIP: WRITE("print "); CodeGen::lt_mode(gen, PRINTING_LTM); VNODE_1C; CodeGen::lt_mode(gen, REGULAR_LTM); break;
	case PRINTCHAR_BIP: WRITE("print (char) "); VNODE_1C; break;
	case PRINTNL_BIP: WRITE("new_line"); break;
	case PRINTOBJ_BIP: WRITE("print (object) "); VNODE_1C; break;
	case PRINTNUMBER_BIP: WRITE("print "); VNODE_1C; break;
	case PRINTDWORD_BIP: WRITE("print (address) "); VNODE_1C; break;
	case PRINTSTRING_BIP: WRITE("print (string) "); VNODE_1C; break;
	case BOX_BIP: WRITE("box "); CodeGen::lt_mode(gen, BOX_LTM); VNODE_1C; CodeGen::lt_mode(gen, REGULAR_LTM); break;
	case SPACES_BIP:		WRITE("spaces "); VNODE_1C; break;
	case FONT_BIP:
		WRITE("if ("); VNODE_1C; WRITE(") { font on; } else { font off; }");
		suppress_terminal_semicolon = TRUE;
		break;
	case STYLE_BIP: {
		inter_tree_node *N = InterTree::first_child(P);
		if ((N->W.data[ID_IFLD] == CONSTANT_IST) &&
			(N->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT)) {
			inter_ti val2 = N->W.data[DATA_CONST_IFLD + 1];
			switch (val2) {
				case 1: WRITE("style bold"); break;
				case 2: WRITE("style underline"); break;
				case 3: WRITE("style reverse"); break;
				default: WRITE("style roman");
			}
		} else {
			WRITE("style roman");
		}
		break;
	}

@<The VM object tree@> =
	case MOVE_BIP: WRITE("move "); VNODE_1C; WRITE(" to "); VNODE_2C; break;
	case REMOVE_BIP: WRITE("remove "); VNODE_1C; break;

@<Random number generator@> =
	case RANDOM_BIP: WRITE("random("); VNODE_1C; WRITE(")"); break;

@<Perform a store@> =
	inter_tree_node *ref = InterTree::first_child(P);
	if ((Inter::Reference::node_is_ref_to(gen->from, ref, PROPERTYVALUE_BIP)) &&
		(I6TargetCode::pval_case(ref) != 2)) {
		@<Handle the ref using the incomplete-function mode@>;
	} else {
		@<Handle the ref with code working either as lvalue or rvalue@>;
	}

@<Handle the ref using the incomplete-function mode@> =
	inter_tree_node *VP = InterTree::second_child(P);
	int set = NOT_APPLICABLE;
	if (VP->W.data[ID_IFLD] == VAL_IST) {
		inter_ti val1 = VP->W.data[VAL1_VAL_IFLD];
		inter_ti val2 = VP->W.data[VAL2_VAL_IFLD];
		if ((val1 == LITERAL_IVAL) && (val2)) set = TRUE;
		if ((val1 == LITERAL_IVAL) && (val2 == 0)) set = FALSE;
	}
	if ((I6TargetCode::pval_case(ref) == 1) && (set == TRUE)) {
		i6_next_is_a_give = TRUE; VNODE_1C; i6_next_is_a_give = FALSE;
	} else if ((I6TargetCode::pval_case(ref) == 1) && (set == FALSE)) {
		i6_next_is_a_take = TRUE; VNODE_1C; i6_next_is_a_take = FALSE;
	} else {
		WRITE("("); i6_next_is_a_ref = TRUE; VNODE_1C; i6_next_is_a_ref = FALSE; 
		if (bip == STORE_BIP) { VNODE_2C; } else { WRITE("0"); }
		WRITE(", %S))", store_form);
	}

@<Handle the ref with code working either as lvalue or rvalue@> =
	switch (bip) {
		case PREINCREMENT_BIP:	WRITE("++("); VNODE_1C; WRITE(")"); break;
		case POSTINCREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")++"); break;
		case PREDECREMENT_BIP:	WRITE("--("); VNODE_1C; WRITE(")"); break;
		case POSTDECREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")--"); break;
		case STORE_BIP:			WRITE("("); VNODE_1C; WRITE(" = "); VNODE_2C; WRITE(")"); break;
		case SETBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" | "); VNODE_2C; break;
		case CLEARBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" &~ ("); VNODE_2C; WRITE(")"); break;
	}

@<Write attribute give@> =
	i6_next_is_a_give = FALSE;
	WRITE("give "); VNODE_1C; WRITE(" %S", I6TargetCode::inner_name(gen, P)); break;

@<Write attribute take@> =
	i6_next_is_a_take = FALSE;
	WRITE("give "); VNODE_1C; WRITE(" ~%S", I6TargetCode::inner_name(gen, P)); break;

@<Write property value@> =								
	i6_next_is_a_ref = FALSE;
	WRITE("_final_write_pval("); VNODE_1C; WRITE(","); VNODE_2C; WRITE(", ");

@<Evaluate property value@> =								
	switch (I6TargetCode::pval_case(P)) {
		case 1: WRITE("("); VNODE_1C; WRITE(" has %S", I6TargetCode::inner_name(gen, P)); WRITE(")"); break;
		case 2: WRITE("("); VNODE_1C; WRITE(".%S", I6TargetCode::inner_name(gen, P)); WRITE(")"); break;
		case 3: I6TargetCode::comparison_r(gen, InterTree::first_child(P), InterTree::second_child(P), 0); break;
	}

@ =
void I6TargetCode::comparison_r(code_generation *gen,
	inter_tree_node *X, inter_tree_node *Y, int depth) {
	text_stream *OUT = CodeGen::current(gen);
	if (Y->W.data[ID_IFLD] == INV_IST) {
		if (Y->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(Y);
			inter_ti ybip = Primitives::to_bip(gen->from, prim);
			if (ybip == ALTERNATIVE_BIP) {
				if (depth == 0) { WRITE("((or_tmp_var = "); Vanilla::node(gen, X); WRITE(") && (("); }
				I6TargetCode::comparison_r(gen, NULL, InterTree::first_child(Y), depth+1);
				WRITE(") || (");
				I6TargetCode::comparison_r(gen, NULL, InterTree::second_child(Y), depth+1);
				if (depth == 0) { WRITE(")))"); }
				return;
			}
		}
	}
	switch (I6TargetCode::pval_case_inner(Y)) {
		case 1: WRITE("("); if (X) Vanilla::node(gen, X); else WRITE("or_tmp_var"); WRITE(" has %S", I6TargetCode::inner_name_inner(gen, Y)); WRITE(")"); break;
		case 2: WRITE("("); if (X) Vanilla::node(gen, X); else WRITE("or_tmp_var"); WRITE(".%S", I6TargetCode::inner_name_inner(gen, Y)); WRITE(")"); break;
		case 3:
			WRITE("_final_read_pval(");
			if (X) Vanilla::node(gen, X); else WRITE("or_tmp_var");
			WRITE(", "); 
			Vanilla::node(gen, Y);
			WRITE(")"); break;
	}
}

@

=
int I6TargetCode::pval_case(inter_tree_node *P) {
	while (P->W.data[ID_IFLD] == REFERENCE_IST) P = InterTree::first_child(P);
	inter_tree_node *prop_node = InterTree::second_child(P);
	return I6TargetCode::pval_case_inner(prop_node);
}

text_stream *I6TargetCode::inner_name(code_generation *gen, inter_tree_node *P) {
	while (P->W.data[ID_IFLD] == REFERENCE_IST) P = InterTree::first_child(P);
	inter_tree_node *prop_node = InterTree::second_child(P);
	return I6TargetCode::inner_name_inner(gen, prop_node);
}

text_stream *I6TargetCode::inner_name_inner(code_generation *gen, inter_tree_node *prop_node) {
	inter_symbol *prop_symbol = NULL;
	if (prop_node->W.data[ID_IFLD] == VAL_IST) {
		inter_ti val1 = prop_node->W.data[VAL1_VAL_IFLD];
		inter_ti val2 = prop_node->W.data[VAL2_VAL_IFLD];
		if (Inter::Symbols::is_stored_in_data(val1, val2))
			prop_symbol =
				InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(prop_node), val2);
	}
	if ((prop_symbol) && (Inter::Symbols::get_flag(prop_symbol, ATTRIBUTE_MARK_BIT))) {
		return VanillaObjects::inner_property_name(gen, prop_symbol);
	} else if ((prop_symbol) && (prop_symbol->definition->W.data[ID_IFLD] == PROPERTY_IST)) {
		return VanillaObjects::inner_property_name(gen, prop_symbol);
	} else {
		return NULL;
	}
}

int I6TargetCode::pval_case_inner(inter_tree_node *prop_node) {
	inter_symbol *prop_symbol = NULL;
	if (prop_node->W.data[ID_IFLD] == VAL_IST) {
		inter_ti val1 = prop_node->W.data[VAL1_VAL_IFLD];
		inter_ti val2 = prop_node->W.data[VAL2_VAL_IFLD];
		if (Inter::Symbols::is_stored_in_data(val1, val2))
			prop_symbol =
				InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(prop_node), val2);
	}
	if ((prop_symbol) && (Inter::Symbols::get_flag(prop_symbol, ATTRIBUTE_MARK_BIT))) {
		return 1;
	} else if ((prop_symbol) && (prop_symbol->definition->W.data[ID_IFLD] == PROPERTY_IST)) {
		return 2;
	} else {
		return 3;
	}
}

@<Generate primitive for return@> =
	int rboolean = NOT_APPLICABLE;
	inter_tree_node *V = InterTree::first_child(P);
	if (V->W.data[ID_IFLD] == VAL_IST) {
		inter_ti val1 = V->W.data[VAL1_VAL_IFLD];
		inter_ti val2 = V->W.data[VAL2_VAL_IFLD];
		if (val1 == LITERAL_IVAL) {
			if (val2 == 0) rboolean = FALSE;
			if (val2 == 1) rboolean = TRUE;
		}
	}
	switch (rboolean) {
		case FALSE: WRITE("rfalse"); break;
		case TRUE: WRITE("rtrue"); break;
		case NOT_APPLICABLE: WRITE("return "); Vanilla::node(gen, V); break;
	}
	

@ Here we need some gymnastics. We need to produce a value which the
sometimes shaky I6 expression parser will accept, which turns out to be
quite a constraint. If we were compiling to C, we might try this:
= (text as C)
	(a, b, c)
=
using the serial comma operator -- that is, where the expression |(a, b)|
evaluates |a| then |b| and returns the value of |b|, discarding |a|.
Now I6 does support the comma operator, and this makes a workable scheme,
right up to the point where some of the token values themselves include
invocations of functions, because I6's syntax analyser won't always
allow the serial comma to be mixed in the same expression with the
function argument comma, i.e., I6 is unable properly to handle expressions
like this one:
= (text as C)
	(a(b, c), d)
=
where the first comma constructs a list and the second is the operator.
(Many such expressions work fine, but not all.) That being so, the scheme
I actually use is:
= (text as C)
	(c) + 0*((b) + (a))
=
Because I6 evaluates the leaves in an expression tree right-to-left, not
left-to-right, the parameter assignments happen first, then the conditions,
then the result.


@<Generate primitive for ternarysequential@> =
	WRITE("(\n"); INDENT;
	WRITE("! This value evaluates third (i.e., last)\n"); VNODE_3C;
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("0*(\n"); INDENT;
	WRITE("! The following condition evaluates second\n");
	WRITE("((\n"); INDENT; VNODE_2C;
	OUTDENT; WRITE("\n))\n");
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("! The following assignments evaluate first\n");
	WRITE("("); VNODE_1C; WRITE(")");
	OUTDENT; WRITE(")\n");
	OUTDENT; WRITE(")\n");

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
	if (!((INIT->W.data[ID_IFLD] == VAL_IST) && (INIT->W.data[VAL1_VAL_IFLD] == LITERAL_IVAL) && (INIT->W.data[VAL2_VAL_IFLD] == 1))) VNODE_1C;
	WRITE(":"); VNODE_2C;
	WRITE(":");
	inter_tree_node *U = InterTree::third_child(P);
	if (U->W.data[ID_IFLD] != VAL_IST)
	Vanilla::node(gen, U);
	WRITE(") {\n"); INDENT; VNODE_4C;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloop@> =
	int in_flag = FALSE;
	inter_tree_node *U = InterTree::third_child(P);
	if ((U->W.data[ID_IFLD] == INV_IST) && (U->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
		inter_symbol *prim = Inter::Inv::invokee(U);
		if ((prim) && (Primitives::to_bip(I, prim) == IN_BIP)) in_flag = TRUE;
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

@<Generate primitive for loop@> =
	WRITE("{\n"); INDENT; VNODE_1C; OUTDENT; WRITE("}\n");
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



@h A few resources.

=
void I6TargetCode::end_generation(code_generator *cgt, code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, functions_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("[ _final_read_pval o p t;\n");
	WRITE("    t = p-->0; p = p-->1; ! print \"has \", o, \" \", p, \"^\";\n");
	WRITE("    if (t == 2) { if (o has p) rtrue; rfalse; }\n");
	WRITE("    if (o provides p) return o.p; rfalse;\n");
	WRITE("];\n");
	WRITE("[ _final_write_pval o p v t;\n");
	WRITE("    t = p-->0; p = p-->1; ! print \"give \", o, \" \", p, \"^\";\n");
	WRITE("    if (t == 2) { if (v) give o p; else give o ~p; }\n");
	WRITE("    else { if (o provides p) o.p = v; }\n");
	WRITE("];\n");
	WRITE("[ _final_read_paddr o p v t;\n");
	WRITE("    t = p-->0; p = p-->1; ! print \"give \", o, \" \", p, \"^\";\n");
	WRITE("    if (t == 2) return 0;\n");
	WRITE("    return o.&p;\n");
	WRITE("];\n");
	WRITE("[ _final_read_plen o p v t;\n");
	WRITE("    t = p-->0; p = p-->1; ! print \"give \", o, \" \", p, \"^\";\n");
	WRITE("    if (t == 2) return 0;\n");
	WRITE("    return o.#p;\n");
	WRITE("];\n");
	WRITE("[ _final_message0 o p q x a rv;\n");
	WRITE("    ! print \"Message send \", (the) o, \" --> \", p, \" \", p-->1, \" addr \", o.(p-->1), \"^\";\n");
	WRITE("    q = p-->1; a = o.q; if (metaclass(a) == Object) rv = a; else if (a) { x = self; self = o; rv = indirect(a); self = x; } ! print \"Message = \", rv, \"^\";\n");
	WRITE("    return rv;\n");
	WRITE("];\n");
	WRITE("[ _final_provides K o p holder;\n");
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
	WRITE("[ _final_xwrite_pval K o p v t;\n");
	WRITE("if (K == OBJECT_TY) {\n");
	WRITE("    if (p-->0 == 2) {\n");
	WRITE("        if (v) give o p-->1; else give o ~(p-->1);\n");
	WRITE("    } else {\n");
	WRITE("        o.(p-->1) = v;\n");
	WRITE("    }\n");
	WRITE("} else {\n");
	WRITE("    ((value_property_holders-->K).(p-->1))-->(o+COL_HSIZE) = v;\n");
	WRITE("}\n");
	WRITE("];\n");

	WRITE("Constant i7_lvalue_SET = 1;\n");
	WRITE("Constant i7_lvalue_PREDEC = 2;\n");
	WRITE("Constant i7_lvalue_POSTDEC = 3;\n");
	WRITE("Constant i7_lvalue_PREINC = 4;\n");
	WRITE("Constant i7_lvalue_POSTINC = 5;\n");
	WRITE("Constant i7_lvalue_SETBIT = 6;\n");
	WRITE("Constant i7_lvalue_CLEARBIT = 7;\n");
	CodeGen::deselect(gen, saved);
}
