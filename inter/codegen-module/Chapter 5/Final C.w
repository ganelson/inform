[CodeGen::C::] Generating C.

To generate I6 code from intermediate code.

@h Target.

=
code_generation_target *c_target = NULL;
void CodeGen::C::create_target(void) {
	code_generation_target *cgt = CodeGen::Targets::new(I"c");
	METHOD_ADD(cgt, BEGIN_GENERATION_MTID, CodeGen::C::begin_generation);
	METHOD_ADD(cgt, GENERAL_SEGMENT_MTID, CodeGen::C::general_segment);
	METHOD_ADD(cgt, TL_SEGMENT_MTID, CodeGen::C::tl_segment);
	METHOD_ADD(cgt, DEFAULT_SEGMENT_MTID, CodeGen::C::default_segment);
	METHOD_ADD(cgt, BASIC_CONSTANT_SEGMENT_MTID, CodeGen::C::basic_constant_segment);
	METHOD_ADD(cgt, CONSTANT_SEGMENT_MTID, CodeGen::C::constant_segment);
	METHOD_ADD(cgt, PROPERTY_SEGMENT_MTID, CodeGen::C::property_segment);
	METHOD_ADD(cgt, COMPILE_PRIMITIVE_MTID, CodeGen::C::compile_primitive);
	METHOD_ADD(cgt, COMPILE_DICTIONARY_WORD_MTID, CodeGen::C::compile_dictionary_word);
	METHOD_ADD(cgt, COMPILE_LITERAL_NUMBER_MTID, CodeGen::C::compile_literal_number);
	METHOD_ADD(cgt, COMPILE_LITERAL_TEXT_MTID, CodeGen::C::compile_literal_text);
	METHOD_ADD(cgt, DECLARE_PROPERTY_MTID, CodeGen::C::declare_property);
	METHOD_ADD(cgt, PREPARE_VARIABLE_MTID, CodeGen::C::prepare_variable);
	METHOD_ADD(cgt, DECLARE_VARIABLE_MTID, CodeGen::C::declare_variable);
	METHOD_ADD(cgt, DECLARE_LOCAL_VARIABLE_MTID, CodeGen::C::declare_local_variable);
	METHOD_ADD(cgt, BEGIN_CONSTANT_MTID, CodeGen::C::begin_constant);
	METHOD_ADD(cgt, END_CONSTANT_MTID, CodeGen::C::end_constant);
	METHOD_ADD(cgt, BEGIN_FUNCTION_MTID, CodeGen::C::begin_function);
	METHOD_ADD(cgt, BEGIN_FUNCTION_CODE_MTID, CodeGen::C::begin_function_code);
	METHOD_ADD(cgt, END_FUNCTION_MTID, CodeGen::C::end_function);
	METHOD_ADD(cgt, BEGIN_ARRAY_MTID, CodeGen::C::begin_array);
	METHOD_ADD(cgt, ARRAY_ENTRY_MTID, CodeGen::C::array_entry);
	METHOD_ADD(cgt, END_ARRAY_MTID, CodeGen::C::end_array);
	METHOD_ADD(cgt, OFFER_PRAGMA_MTID, CodeGen::C::offer_pragma)
	c_target = cgt;
}

code_generation_target *CodeGen::C::target(void) {
	return inform6_target;
}

@h Segmentation.

=
int CodeGen::C::begin_generation(code_generation_target *cgt, code_generation *gen) {
	gen->segments[pragmatic_matter_I7CGS] = CodeGen::new_segment();
	gen->segments[compiler_versioning_matter_I7CGS] = CodeGen::new_segment();
	gen->segments[attributes_at_eof_I7CGS] = CodeGen::new_segment();
	gen->segments[very_early_matter_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_1_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_2_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_3_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_4_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_5_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_6_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_7_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_8_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_9_I7CGS] = CodeGen::new_segment();
	gen->segments[constants_10_I7CGS] = CodeGen::new_segment();
	gen->segments[early_matter_I7CGS] = CodeGen::new_segment();
	gen->segments[text_literals_code_I7CGS] = CodeGen::new_segment();
	gen->segments[summations_at_eof_I7CGS] = CodeGen::new_segment();
	gen->segments[arrays_at_eof_I7CGS] = CodeGen::new_segment();
	gen->segments[globals_array_I7CGS] = CodeGen::new_segment();
	gen->segments[main_matter_I7CGS] = CodeGen::new_segment();
	gen->segments[routines_at_eof_I7CGS] = CodeGen::new_segment();
	gen->segments[code_at_eof_I7CGS] = CodeGen::new_segment();
	gen->segments[verbs_at_eof_I7CGS] = CodeGen::new_segment();
	gen->segments[stubs_at_eof_I7CGS] = CodeGen::new_segment();

	generated_segment *saved = CodeGen::select(gen, compiler_versioning_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("typedef int i7val;\n");
	WRITE("typedef char i7byte;\n");
	WRITE("#include <stdio.h>\n");
	WRITE("#define Grammar__Version 2\n");
	WRITE("i7val debug_flag = 0;\n");
	CodeGen::deselect(gen, saved);
	
	saved = CodeGen::select(gen, stubs_at_eof_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("int main(int argc, char **argv) { Main(); return 0; }\n");
	CodeGen::deselect(gen, saved);
	
	return FALSE;
}

int CodeGen::C::general_segment(code_generation_target *cgt, code_generation *gen, inter_tree_node *P) {
	switch (P->W.data[ID_IFLD]) {
		case CONSTANT_IST: {
			inter_symbol *con_name =
				InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			int choice = early_matter_I7CGS;
			if (Str::eq(con_name->symbol_name, I"DynamicMemoryAllocation")) choice = very_early_matter_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, LATE_IANN) == 1) choice = code_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1) choice = arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) choice = arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) choice = arrays_at_eof_I7CGS;
			if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_LIST) choice = arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) choice = verbs_at_eof_I7CGS;
			if (Inter::Constant::is_routine(con_name)) choice = routines_at_eof_I7CGS;
			return choice;
		}
	}
	return CodeGen::C::default_segment(cgt);
}

int CodeGen::C::default_segment(code_generation_target *cgt) {
	return main_matter_I7CGS;
}
int CodeGen::C::constant_segment(code_generation_target *cgt, code_generation *gen) {
	return early_matter_I7CGS;
}
int CodeGen::C::basic_constant_segment(code_generation_target *cgt, code_generation *gen, int depth) {
	if (depth >= 10) depth = 10;
	return constants_1_I7CGS + depth - 1;
}
int CodeGen::C::property_segment(code_generation_target *cgt) {
	return attributes_at_eof_I7CGS;
}
int CodeGen::C::tl_segment(code_generation_target *cgt) {
	return text_literals_code_I7CGS;
}

void CodeGen::C::offer_pragma(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, text_stream *tag, text_stream *content) {
}

int CodeGen::C::compile_primitive(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_bip(I, prim_name);
	switch (bip) {
		case INVERSION_BIP:		WRITE("inversion"); break;

		case PLUS_BIP:			WRITE("("); INV_A1; WRITE(" + "); INV_A2; WRITE(")"); break;
		case MINUS_BIP:			WRITE("("); INV_A1; WRITE(" - "); INV_A2; WRITE(")"); break;
		case UNARYMINUS_BIP:	WRITE("(-("); INV_A1; WRITE("))"); break;
		case TIMES_BIP:			WRITE("("); INV_A1; WRITE("*"); INV_A2; WRITE(")"); break;
		case DIVIDE_BIP:		WRITE("("); INV_A1; WRITE("/"); INV_A2; WRITE(")"); break;
		case MODULO_BIP:		WRITE("("); INV_A1; WRITE("%%"); INV_A2; WRITE(")"); break;
		case BITWISEAND_BIP:	WRITE("(("); INV_A1; WRITE(")&("); INV_A2; WRITE("))"); break;
		case BITWISEOR_BIP:		WRITE("(("); INV_A1; WRITE(")|("); INV_A2; WRITE("))"); break;
		case BITWISENOT_BIP:	WRITE("(~("); INV_A1; WRITE("))"); break;

		case NOT_BIP:			WRITE("(~~("); INV_A1; WRITE("))"); break;
		case AND_BIP:			WRITE("(("); INV_A1; WRITE(") && ("); INV_A2; WRITE("))"); break;
		case OR_BIP: 			WRITE("(("); INV_A1; WRITE(") || ("); INV_A2; WRITE("))"); break;
		case EQ_BIP: 			WRITE("("); INV_A1; WRITE(" == "); INV_A2; WRITE(")"); break;
		case NE_BIP: 			WRITE("("); INV_A1; WRITE(" ~= "); INV_A2; WRITE(")"); break;
		case GT_BIP: 			WRITE("("); INV_A1; WRITE(" > "); INV_A2; WRITE(")"); break;
		case GE_BIP: 			WRITE("("); INV_A1; WRITE(" >= "); INV_A2; WRITE(")"); break;
		case LT_BIP: 			WRITE("("); INV_A1; WRITE(" < "); INV_A2; WRITE(")"); break;
		case LE_BIP: 			WRITE("("); INV_A1; WRITE(" <= "); INV_A2; WRITE(")"); break;
		case OFCLASS_BIP:		WRITE("("); INV_A1; WRITE(" ofclass "); INV_A2; WRITE(")"); break;
		case HAS_BIP:			WRITE("("); INV_A1; WRITE(" has "); INV_A2; WRITE(")"); break;
		case HASNT_BIP:			WRITE("("); INV_A1; WRITE(" hasnt "); INV_A2; WRITE(")"); break;
		case IN_BIP:			WRITE("("); INV_A1; WRITE(" in "); INV_A2; WRITE(")"); break;
		case NOTIN_BIP:			WRITE("("); INV_A1; WRITE(" notin "); INV_A2; WRITE(")"); break;
		case PROVIDES_BIP:		WRITE("("); INV_A1; WRITE(" provides "); INV_A2; WRITE(")"); break;
		case ALTERNATIVE_BIP:	INV_A1; WRITE(" or "); INV_A2; break;

		case PUSH_BIP:			WRITE("@push "); INV_A1; break;
		case PULL_BIP:			WRITE("@pull "); INV_A1; break;
		case PREINCREMENT_BIP:	WRITE("++("); INV_A1; WRITE(")"); break;
		case POSTINCREMENT_BIP:	WRITE("("); INV_A1; WRITE(")++"); break;
		case PREDECREMENT_BIP:	WRITE("--("); INV_A1; WRITE(")"); break;
		case POSTDECREMENT_BIP:	WRITE("("); INV_A1; WRITE(")--"); break;
		case STORE_BIP:			WRITE("("); INV_A1; WRITE(" = "); INV_A2; WRITE(")"); break;
		case SETBIT_BIP:		INV_A1; WRITE(" = "); INV_A1; WRITE(" | "); INV_A2; break;
		case CLEARBIT_BIP:		INV_A1; WRITE(" = "); INV_A1; WRITE(" &~ ("); INV_A2; WRITE(")"); break;
		case LOOKUP_BIP:		WRITE("("); INV_A1; WRITE("["); INV_A2; WRITE("])"); break;
		case LOOKUPBYTE_BIP:	WRITE("("); INV_A1; WRITE("->("); INV_A2; WRITE("))"); break;
		case LOOKUPREF_BIP:		WRITE("("); INV_A1; WRITE("-->("); INV_A2; WRITE("))"); break;
		case PROPERTYADDRESS_BIP: WRITE("("); INV_A1; WRITE(".& "); INV_A2; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: WRITE("("); INV_A1; WRITE(".# "); INV_A2; WRITE(")"); break;
		case PROPERTYVALUE_BIP:	WRITE("("); INV_A1; WRITE("."); INV_A2; WRITE(")"); break;

		case BREAK_BIP:			WRITE("break"); break;
		case CONTINUE_BIP:		WRITE("continue"); break;
		case RETURN_BIP: 		@<Generate primitive for return@>; break;
		case JUMP_BIP: 			WRITE("jump "); INV_A1; break;
		case QUIT_BIP: 			WRITE("exit(0)"); break;
		case RESTORE_BIP: 		WRITE("restore "); INV_A1; break;

		case INDIRECT0_BIP: case INDIRECT0V_BIP:
								WRITE("("); INV_A1; WRITE(")()"); break;
		case INDIRECT1_BIP: case INDIRECT1V_BIP:
								WRITE("("); INV_A1; WRITE(")(");
								INV_A2; WRITE(")"); break;
		case INDIRECT2_BIP: case INDIRECT2V_BIP:
								WRITE("("); INV_A1; WRITE(")(");
								INV_A2; WRITE(","); INV_A3; WRITE(")"); break;
		case INDIRECT3_BIP: case INDIRECT3V_BIP:
								WRITE("("); INV_A1; WRITE(")(");
								INV_A2; WRITE(","); INV_A3; WRITE(","); INV_A4; WRITE(")"); break;
		case INDIRECT4_BIP: case INDIRECT4V_BIP:
								WRITE("("); INV_A1; WRITE(")(");
								INV_A2; WRITE(","); INV_A3; WRITE(","); INV_A4; WRITE(",");
								INV_A5; WRITE(")"); break;
		case INDIRECT5_BIP: case INDIRECT5V_BIP:
								WRITE("("); INV_A1; WRITE(")(");
								INV_A2; WRITE(","); INV_A3; WRITE(","); INV_A4; WRITE(",");
								INV_A5; WRITE(","); INV_A6; WRITE(")"); break;
		case MESSAGE0_BIP: 		WRITE("("); INV_A1; WRITE("."); INV_A2; WRITE("())"); break;
		case MESSAGE1_BIP: 		WRITE("("); INV_A1; WRITE("."); INV_A2; WRITE("(");
								INV_A3; WRITE("))"); break;
		case MESSAGE2_BIP: 		WRITE("("); INV_A1; WRITE("."); INV_A2; WRITE("(");
								INV_A3; WRITE(","); INV_A4; WRITE("))"); break;
		case MESSAGE3_BIP: 		WRITE("("); INV_A1; WRITE("."); INV_A2; WRITE("(");
								INV_A3; WRITE(","); INV_A4; WRITE(","); INV_A5; WRITE("))"); break;
		case CALLMESSAGE0_BIP: 	WRITE("("); INV_A1; WRITE(".call())"); break;
		case CALLMESSAGE1_BIP: 	WRITE("("); INV_A1; WRITE(".call(");
								INV_A2; WRITE("))"); break;
		case CALLMESSAGE2_BIP: 	WRITE("("); INV_A1; WRITE(".call(");
								INV_A2; WRITE(","); INV_A3; WRITE("))"); break;
		case CALLMESSAGE3_BIP: 	WRITE("("); INV_A1; WRITE(".call(");
								INV_A2; WRITE(","); INV_A3; WRITE(","); INV_A4; WRITE("))"); break;

		case SPACES_BIP:		WRITE("spaces "); INV_A1; break;
		case FONT_BIP:
			WRITE("if ("); INV_A1; WRITE(") { font on; } else { font off; }");
			suppress_terminal_semicolon = TRUE;
			break;
		case STYLEROMAN_BIP: WRITE("style roman"); break;
		case STYLEBOLD_BIP: WRITE("style bold"); break;
		case STYLEUNDERLINE_BIP: WRITE("style underline"); break;
		case STYLEREVERSE_BIP: WRITE("style reverse"); break;

		case MOVE_BIP: WRITE("move "); INV_A1; WRITE(" to "); INV_A2; break;
		case REMOVE_BIP: WRITE("remove "); INV_A1; break;
		case GIVE_BIP: WRITE("give "); INV_A1; WRITE(" "); INV_A2; break;
		case TAKE_BIP: WRITE("give "); INV_A1; WRITE(" ~"); INV_A2; break;

		case ALTERNATIVECASE_BIP: INV_A1; WRITE(", "); INV_A2; break;
		case SEQUENTIAL_BIP: WRITE("("); INV_A1; WRITE(","); INV_A2; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP: @<Generate primitive for ternarysequential@>; break;

		case PRINT_BIP: WRITE("printf(\"%%s\", "); INV_A1_PRINTMODE; WRITE(")"); break;
		case PRINTRET_BIP: INV_A1_PRINTMODE; break;
		case PRINTCHAR_BIP: WRITE("print (char) "); INV_A1; break;
		case PRINTNAME_BIP: WRITE("print (name) "); INV_A1; break;
		case PRINTOBJ_BIP: WRITE("print (object) "); INV_A1; break;
		case PRINTPROPERTY_BIP: WRITE("print (property) "); INV_A1; break;
		case PRINTNUMBER_BIP: WRITE("printf(\"%%d\", "); INV_A1; WRITE(")"); break;
		case PRINTADDRESS_BIP: WRITE("print (address) "); INV_A1; break;
		case PRINTSTRING_BIP: WRITE("print (string) "); INV_A1; break;
		case PRINTNLNUMBER_BIP: WRITE("print (number) "); INV_A1; break;
		case PRINTDEF_BIP: WRITE("print (the) "); INV_A1; break;
		case PRINTCDEF_BIP: WRITE("print (The) "); INV_A1; break;
		case PRINTINDEF_BIP: WRITE("print (a) "); INV_A1; break;
		case PRINTCINDEF_BIP: WRITE("print (A) "); INV_A1; break;
		case BOX_BIP: WRITE("box "); INV_A1_BOXMODE; break;

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
		case DEFAULT_BIP: @<Generate primitive for default@>; break;

		case RANDOM_BIP: WRITE("random("); INV_A1; WRITE(")"); break;

		case READ_BIP: WRITE("read "); INV_A1; WRITE(" "); INV_A2; break;

		default: LOG("Prim: %S\n", prim_name->symbol_name); internal_error("unimplemented prim");
	}
	return suppress_terminal_semicolon;
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
		case NOT_APPLICABLE: WRITE("return "); CodeGen::FC::frame(gen, V); break;
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
	WRITE("! This value evaluates third (i.e., last)\n"); INV_A3;
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("0*(\n"); INDENT;
	WRITE("! The following condition evaluates second\n");
	WRITE("((\n"); INDENT; INV_A2;
	OUTDENT; WRITE("\n))\n");
	OUTDENT; WRITE("+\n"); INDENT;
	WRITE("! The following assignments evaluate first\n");
	WRITE("("); INV_A1; WRITE(")");
	OUTDENT; WRITE(")\n");
	OUTDENT; WRITE(")\n");

@<Generate primitive for if@> =
	WRITE("if ("); INV_A1; WRITE(") {\n"); INDENT; INV_A2;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifdebug@> =
	WRITE("#ifdef DEBUG\n"); INDENT; INV_A1; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifstrict@> =
	WRITE("#ifdef STRICT_MODE\n"); INDENT; INV_A1; OUTDENT; WRITE("#endif\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifelse@> =
	WRITE("if ("); INV_A1; WRITE(") {\n"); INDENT; INV_A2; OUTDENT;
	WRITE("} else {\n"); INDENT; INV_A3; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for while@> =
	WRITE("while ("); INV_A1; WRITE(") {\n"); INDENT; INV_A2; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for do@> =
	WRITE("do {"); INV_A2; WRITE("} until (\n"); INDENT; INV_A1; OUTDENT; WRITE(")\n");

@<Generate primitive for for@> =
	WRITE("for (");
	inter_tree_node *INIT = InterTree::first_child(P);
	if (!((INIT->W.data[ID_IFLD] == VAL_IST) && (INIT->W.data[VAL1_VAL_IFLD] == LITERAL_IVAL) && (INIT->W.data[VAL2_VAL_IFLD] == 1))) INV_A1;
	WRITE(":"); INV_A2;
	WRITE(":");
	inter_tree_node *U = InterTree::third_child(P);
	if (U->W.data[ID_IFLD] != VAL_IST)
	CodeGen::FC::frame(gen, U);
	WRITE(") {\n"); INDENT; INV_A4;
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
		WRITE("("); INV_A1; WRITE(" ofclass "); INV_A2;
		WRITE(" && ");
	} INV_A3;
	if (in_flag == FALSE) {
		WRITE(")");
	}
	WRITE(" {\n"); INDENT; INV_A4;
	OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for objectloopx@> =
	WRITE("objectloop ("); INV_A1; WRITE(" ofclass "); INV_A2;
	WRITE(") {\n"); INDENT; INV_A3; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for loop@> =
	WRITE("{\n"); INDENT; INV_A1; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for switch@> =
	WRITE("switch ("); INV_A1;
	WRITE(") {\n"); INDENT; INV_A2; OUTDENT; WRITE("}\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for case@> =
	INV_A1; WRITE(":\n"); INDENT; INV_A2; WRITE(";\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for default@> =
	WRITE("default:\n"); INDENT; INV_A1; WRITE(";\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@

=
void CodeGen::C::compile_dictionary_word(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int pluralise) {
	text_stream *OUT = CodeGen::current(gen);
	int n = 0;
	WRITE("'");
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		switch(c) {
			case '/': if (Str::len(S) == 1) WRITE("@{2F}"); else WRITE("/"); break;
			case '\'': WRITE("^"); break;
			case '^': WRITE("@{5E}"); break;
			case '~': WRITE("@{7E}"); break;
			case '@': WRITE("@{40}"); break;
			default: PUT(c);
		}
		if (n++ > 32) break;
	}
	if (pluralise) WRITE("//p");
	else if (Str::len(S) == 1) WRITE("//");
	WRITE("'");
}

@

=
void CodeGen::C::compile_literal_number(code_generation_target *cgt,
	code_generation *gen, inter_ti val, int hex_mode) {
	text_stream *OUT = CodeGen::current(gen);
	if (hex_mode) WRITE("0x%x", val);
	else WRITE("%d", val);
}

@

=
void CodeGen::C::compile_literal_text(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int printing_mode, int box_mode) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\"");
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if (box_mode) {
			switch(c) {
				case '"': WRITE("\\\""); break;
				case '\\': WRITE("\\\\"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("\\n\"\n\""); break;
				case NEWLINE_IN_STRING: WRITE("\"\n\""); break;
				default: PUT(c);
			}
		} else {
			switch(c) {
				case '"': WRITE("\\\""); break;
				case '\\': WRITE("\\\\"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("\\n"); break;
				case NEWLINE_IN_STRING: WRITE("\\n"); break;
				default: PUT(c); break;
			}
		}
	}
	WRITE("\"");
}

@ Because in I6 source code some properties aren't declared before use, it follows
that if not used by any object then they won't ever be created. This is a
problem since it means that I6 code can't refer to them, because it would need
to mention an I6 symbol which doesn't exist. To get around this, we create the
property names which don't exist as constant symbols with the harmless value
0; we do this right at the end of the compiled I6 code. (This is a standard I6
trick called "stubbing", these being "stub definitions".)

=
void CodeGen::C::declare_property(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prop_name, int used) {
	text_stream *name = CodeGen::CL::name(prop_name);
	if (used) {
		generated_segment *saved = CodeGen::select(gen, attributes_at_eof_I7CGS);
		WRITE_TO(CodeGen::current(gen), "Property %S;\n", prop_name->symbol_name);
		CodeGen::deselect(gen, saved);
	} else {
		generated_segment *saved = CodeGen::select(gen, code_at_eof_I7CGS);
		WRITE_TO(CodeGen::current(gen), "#ifndef %S\n#define %S 0\n#endif\n", name, name);
		CodeGen::deselect(gen, saved);
	}
}

@

=
int CodeGen::C::prepare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k) {
	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) != 1) {
			text_stream *S = Str::new();
			WRITE_TO(S, "(Global_Vars-->%d)", k);
			Inter::Symbols::set_translate(var_name, S);
		}
		k++;
	}
	return k;
}

int CodeGen::C::declare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k, int of) {
	if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) == 1) {
		generated_segment *saved = CodeGen::select(gen, main_matter_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("i7val %S = ", CodeGen::CL::name(var_name));
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		WRITE(";\n");
		CodeGen::deselect(gen, saved);
	}
	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		generated_segment *saved = CodeGen::select(gen, attributes_at_eof_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		if (k == 0) CodeGen::C::begin_array(cgt, gen, I"Global_Vars", WORD_ARRAY_FORMAT);
		else WRITE(", ");
		inter_symbols_table *globals = Inter::Packages::scope_of(P);
		CodeGen::CL::literal(gen, NULL, globals, P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		WRITE(" // -->%d = %S (%S)\n", k, CodeGen::CL::name(var_name), var_name->symbol_name);
		k++;
		if (k == of) {
			if (k < 2) {
				CodeGen::C::array_entry(cgt, gen, I"NULL", WORD_ARRAY_FORMAT);
				CodeGen::C::array_entry(cgt, gen, I"NULL", WORD_ARRAY_FORMAT);
			}
			CodeGen::C::end_array(cgt, gen, WORD_ARRAY_FORMAT);
		}
		CodeGen::deselect(gen, saved);
	}
	return k;
}

void CodeGen::C::begin_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name, int continues) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S", const_name);
	if (continues) WRITE(" ");
}
void CodeGen::C::end_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\n");
}

int C_fn_parameter_count = 0;

void CodeGen::C::begin_function(code_generation_target *cgt, code_generation *gen, text_stream *fn_name) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7val %S(", fn_name); C_fn_parameter_count = 0;
}

void CodeGen::C::begin_function_code(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	if (C_fn_parameter_count == 0) WRITE("void");
	WRITE(") {");
}

void CodeGen::C::end_function(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\n}\n");
}

void CodeGen::C::declare_local_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name) {
	text_stream *OUT = CodeGen::current(gen);
	if (C_fn_parameter_count++ > 0) WRITE(", ");
	WRITE("i7val %S", var_name->symbol_name);
}

int C_array_entry_count = 0;
text_stream *C_array_entries = NULL;

void CodeGen::C::begin_array(code_generation_target *cgt, code_generation *gen, text_stream *array_name, int format) {
	if (C_array_entries == NULL) C_array_entries = Str::new();
	Str::clear(C_array_entries); C_array_entry_count = 0;
	text_stream *OUT = CodeGen::current(gen);
	switch (format) {
		case WORD_ARRAY_FORMAT: WRITE("i7val"); break;
		case BYTE_ARRAY_FORMAT: WRITE("i7byte"); break;
		case TABLE_ARRAY_FORMAT: WRITE("i7val"); break;
		case BUFFER_ARRAY_FORMAT: WRITE("i7byte"); break;
	}
	WRITE(" %S[] = { ", array_name);
}

void CodeGen::C::array_entry(code_generation_target *cgt, code_generation *gen, text_stream *entry, int format) {
	if (C_array_entry_count++ > 0) WRITE_TO(C_array_entries, ", ");
	WRITE_TO(C_array_entries, "%S", entry);
}

void CodeGen::C::end_array(code_generation_target *cgt, code_generation *gen, int format) {
	text_stream *OUT = CodeGen::current(gen);
	if ((format == TABLE_ARRAY_FORMAT) || (format == BUFFER_ARRAY_FORMAT)) {
		WRITE("%d", C_array_entry_count++);
		if (C_array_entry_count > 1) WRITE(", ");
	}
	WRITE("%S", C_array_entries);
	WRITE(" };\n");
}
