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
	METHOD_ADD(cgt, MANGLE_IDENTIFIER_MTID, CodeGen::C::mangle);
	METHOD_ADD(cgt, COMPILE_PRIMITIVE_MTID, CodeGen::C::compile_primitive);
	METHOD_ADD(cgt, COMPILE_DICTIONARY_WORD_MTID, CodeGen::C::compile_dictionary_word);
	METHOD_ADD(cgt, COMPILE_LITERAL_NUMBER_MTID, CodeGen::C::compile_literal_number);
	METHOD_ADD(cgt, COMPILE_LITERAL_TEXT_MTID, CodeGen::C::compile_literal_text);
	METHOD_ADD(cgt, DECLARE_PROPERTY_MTID, CodeGen::C::declare_property);
	METHOD_ADD(cgt, DECLARE_ATTRIBUTE_MTID, CodeGen::C::declare_attribute);
	METHOD_ADD(cgt, PREPARE_VARIABLE_MTID, CodeGen::C::prepare_variable);
	METHOD_ADD(cgt, DECLARE_VARIABLE_MTID, CodeGen::C::declare_variable);
	METHOD_ADD(cgt, DECLARE_CLASS_MTID, CodeGen::C::declare_class);
	METHOD_ADD(cgt, END_CLASS_MTID, CodeGen::C::end_class);
	METHOD_ADD(cgt, DECLARE_INSTANCE_MTID, CodeGen::C::declare_instance);
	METHOD_ADD(cgt, END_INSTANCE_MTID, CodeGen::C::end_instance);
	METHOD_ADD(cgt, ASSIGN_PROPERTY_MTID, CodeGen::C::assign_property);
	METHOD_ADD(cgt, DECLARE_LOCAL_VARIABLE_MTID, CodeGen::C::declare_local_variable);
	METHOD_ADD(cgt, BEGIN_CONSTANT_MTID, CodeGen::C::begin_constant);
	METHOD_ADD(cgt, END_CONSTANT_MTID, CodeGen::C::end_constant);
	METHOD_ADD(cgt, BEGIN_FUNCTION_MTID, CodeGen::C::begin_function);
	METHOD_ADD(cgt, BEGIN_FUNCTION_CODE_MTID, CodeGen::C::begin_function_code);
	METHOD_ADD(cgt, PLACE_LABEL_MTID, CodeGen::C::place_label);
	METHOD_ADD(cgt, END_FUNCTION_MTID, CodeGen::C::end_function);
	METHOD_ADD(cgt, BEGIN_FUNCTION_CALL_MTID, CodeGen::C::begin_function_call);
	METHOD_ADD(cgt, ARGUMENT_MTID, CodeGen::C::argument);
	METHOD_ADD(cgt, END_FUNCTION_CALL_MTID, CodeGen::C::end_function_call);
	METHOD_ADD(cgt, BEGIN_OPCODE_MTID, CodeGen::C::begin_opcode);
	METHOD_ADD(cgt, SUPPLY_OPERAND_MTID, CodeGen::C::supply_operand);
	METHOD_ADD(cgt, END_OPCODE_MTID, CodeGen::C::end_opcode);
	METHOD_ADD(cgt, BEGIN_ARRAY_MTID, CodeGen::C::begin_array);
	METHOD_ADD(cgt, ARRAY_ENTRY_MTID, CodeGen::C::array_entry);
	METHOD_ADD(cgt, END_ARRAY_MTID, CodeGen::C::end_array);
	METHOD_ADD(cgt, OFFER_PRAGMA_MTID, CodeGen::C::offer_pragma)
	METHOD_ADD(cgt, END_GENERATION_MTID, CodeGen::C::end_generation);
	c_target = cgt;
}

code_generation_target *CodeGen::C::target(void) {
	return inform6_target;
}

@h Segmentation.

@e c_mem_I7CGS
@e c_initialiser_I7CGS

=
text_stream *double_quoted_C = NULL;
int no_double_quoted_C_strings = 0;
int C_property_enumeration_counter = 0;
int extent_of_i7mem = 0;
int C_class_counter = 0;
int C_instance_counter = 0;

int CodeGen::C::begin_generation(code_generation_target *cgt, code_generation *gen) {
	gen->segments[pragmatic_matter_I7CGS] = CodeGen::new_segment();
	gen->segments[compiler_versioning_matter_I7CGS] = CodeGen::new_segment();
	gen->segments[predeclarations_I7CGS] = CodeGen::new_segment();
	gen->segments[predeclarations_2_I7CGS] = CodeGen::new_segment();
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
	gen->segments[c_mem_I7CGS] = CodeGen::new_segment();
	gen->segments[c_initialiser_I7CGS] = CodeGen::new_segment();

	double_quoted_C = Str::new();
	no_double_quoted_C_strings = 0;
	
	C_class_counter = 0;
	C_instance_counter = 0;
	
	C_property_enumeration_counter = 0;

	generated_segment *saved = CodeGen::select(gen, compiler_versioning_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#include \"inform7_clib.h\"\n");
	WRITE("i7byte i7mem[];\n");
	WRITE("i7val ");
	CodeGen::C::mangle(cgt, OUT, I"self");
	WRITE(" = 0;\n");
	WRITE("i7val ");
	CodeGen::C::mangle(cgt, OUT, I"sp");
	WRITE(" = 0;\n");
	WRITE("#define ");
	CodeGen::C::mangle(cgt, OUT, I"Grammar__Version");
	WRITE(" 2\n");
	WRITE("i7val ");
	CodeGen::C::mangle(cgt, OUT, I"debug_flag");
	WRITE(" = 0;\n");
	CodeGen::deselect(gen, saved);

	CodeGen::C::make_veneer_fcf(gen, I"Z__Region");
	CodeGen::C::make_veneer_fcf(gen, I"CP__Tab");
	CodeGen::C::make_veneer_fcf(gen, I"RA__Pr");
	CodeGen::C::make_veneer_fcf(gen, I"RL__Pr");
	CodeGen::C::make_veneer_fcf(gen, I"OC__Cl");
	CodeGen::C::make_veneer_fcf(gen, I"RV__Pr");
	CodeGen::C::make_veneer_fcf(gen, I"OP__Pr");
	CodeGen::C::make_veneer_fcf(gen, I"CA__Pr");

	CodeGen::C::declare_property_by_name(gen, I"value_range", TRUE);

	saved = CodeGen::select(gen, c_mem_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("i7byte i7mem[] = {\n");
	CodeGen::deselect(gen, saved);
	extent_of_i7mem = 0;
	
	saved = CodeGen::select(gen, stubs_at_eof_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("int i7_initializer(void);\n");
	WRITE("int main(int argc, char **argv) { i7_initializer(); ");
	WRITE("fn_"); CodeGen::C::mangle(cgt, OUT, I"Main");
	WRITE("(0); return 0; }\n");
	CodeGen::deselect(gen, saved);
	
	saved = CodeGen::select(gen, c_initialiser_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("int i7_initializer(void) {\n");
	WRITE("i7val ref = 0;\n");
	CodeGen::deselect(gen, saved);
	
	return FALSE;
}

int CodeGen::C::end_generation(code_generation_target *cgt, code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define I7VAL_STRINGS_BASE %d\n", extent_of_i7mem);
	WRITE("#define I7VAL_FUNCTIONS_BASE %d\n", extent_of_i7mem + no_double_quoted_C_strings);
	WRITE("char *dqs[] = {\n%S\"\" };\n", double_quoted_C);
	CodeGen::deselect(gen, saved);
	
	saved = CodeGen::select(gen, c_mem_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("0, 0 };\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_initialiser_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("return ref;\n");
	WRITE("}\n");
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
	return predeclarations_I7CGS;
}
int CodeGen::C::tl_segment(code_generation_target *cgt) {
	return text_literals_code_I7CGS;
}

void CodeGen::C::offer_pragma(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, text_stream *tag, text_stream *content) {
}

void CodeGen::C::mangle(code_generation_target *cgt, OUTPUT_STREAM, text_stream *identifier) {
	if (Str::get_first_char(identifier) == '(') WRITE("%S", identifier);
	else if (Str::get_first_char(identifier) == '#') {
		WRITE("i7_mgl_sharp_");
		LOOP_THROUGH_TEXT(pos, identifier)
			if ((Str::get(pos) != '#') && (Str::get(pos) != '$'))
				PUT(Str::get(pos));
	} else WRITE("i7_mgl_%S", identifier);
}

int C_write_lookup_mode = FALSE;

int CodeGen::C::compile_primitive(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_bip(I, prim_name);
	switch (bip) {
		case INVERSION_BIP:		break; /* we won't support this in C */

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
		case EQ_BIP: 			@<Generate comparison@>; break;
		case NE_BIP: 			@<Generate comparison@>; break;
		case GT_BIP: 			@<Generate comparison@>; break;
		case GE_BIP: 			@<Generate comparison@>; break;
		case LT_BIP: 			@<Generate comparison@>; break;
		case LE_BIP: 			@<Generate comparison@>; break;
		case OFCLASS_BIP:		@<Generate comparison@>; break;
		case HAS_BIP:			@<Generate comparison@>; break;
		case HASNT_BIP:			@<Generate comparison@>; break;
		case IN_BIP:			@<Generate comparison@>; break;
		case NOTIN_BIP:			@<Generate comparison@>; break;
		case PROVIDES_BIP:		@<Generate comparison@>; break;
		case ALTERNATIVE_BIP:	INV_A1; WRITE(" or "); INV_A2; break;

		case PUSH_BIP:			WRITE("i7_push("); INV_A1; WRITE(")"); break;
		case PULL_BIP:			INV_A1; WRITE(" = i7_pull()"); break;
		case PREINCREMENT_BIP:	WRITE("++("); INV_A1; WRITE(")"); break;
		case POSTINCREMENT_BIP:	WRITE("("); INV_A1; WRITE(")++"); break;
		case PREDECREMENT_BIP:	WRITE("--("); INV_A1; WRITE(")"); break;
		case POSTDECREMENT_BIP:	WRITE("("); INV_A1; WRITE(")--"); break;
		case STORE_BIP:			@<Generate primitive for store@>; break;
		case SETBIT_BIP:		INV_A1; WRITE(" = "); INV_A1; WRITE(" | "); INV_A2; break;
		case CLEARBIT_BIP:		INV_A1; WRITE(" = "); INV_A1; WRITE(" &~ ("); INV_A2; WRITE(")"); break;
		case LOOKUP_BIP:		if (C_write_lookup_mode) {
									C_write_lookup_mode = FALSE;
									@<Generate primitive for lookupref@>;
								} else {
									@<Generate primitive for lookup@>;
								}
								break;
		case LOOKUPBYTE_BIP:	@<Generate primitive for lookupbyte@>; break;
		case LOOKUPREF_BIP:		@<Generate primitive for lookupref@>; break;
		case PROPERTYADDRESS_BIP: WRITE("i7_prop_addr("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: WRITE("i7_prop_len("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case PROPERTYVALUE_BIP:	WRITE("i7_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;

		case BREAK_BIP:			WRITE("break"); break;
		case CONTINUE_BIP:		WRITE("continue"); break;
		case RETURN_BIP: 		@<Generate primitive for return@>; break;
		case JUMP_BIP: 			WRITE("goto "); INV_A1; break;
		case QUIT_BIP: 			WRITE("exit(0)"); break;
		case RESTORE_BIP: 		break; /* we won't support this in C */

		case INDIRECT0_BIP: case INDIRECT0V_BIP:
								WRITE("i7_call_0("); INV_A1; WRITE(")"); break;
		case INDIRECT1_BIP: case INDIRECT1V_BIP:
								WRITE("i7_call_1("); INV_A1; WRITE(", ");
								INV_A2; WRITE(")"); break;
		case INDIRECT2_BIP: case INDIRECT2V_BIP:
								WRITE("i7_call_2("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(")"); break;
		case INDIRECT3_BIP: case INDIRECT3V_BIP:
								WRITE("i7_call_3("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;
		case INDIRECT4_BIP: case INDIRECT4V_BIP:
								WRITE("i7_call_4("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(", ");
								INV_A5; WRITE(")"); break;
		case INDIRECT5_BIP: case INDIRECT5V_BIP:
								WRITE("i7_call_5("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(", ");
								INV_A5; WRITE(", "); INV_A6; WRITE(")"); break;
		case MESSAGE0_BIP: 		WRITE("i7_call_0(i7_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("))"); break;
		case MESSAGE1_BIP: 		WRITE("i7_call_1(i7_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(")"); break;
		case MESSAGE2_BIP: 		WRITE("i7_call_2(i7_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;
		case MESSAGE3_BIP: 		WRITE("i7_call_3(i7_prop_value("); INV_A1; WRITE(", "); INV_A2; WRITE("), ");
								INV_A3; WRITE(", "); INV_A4; WRITE(", "); INV_A5; WRITE(")"); break;
		case CALLMESSAGE0_BIP: 	WRITE("i7_ccall_0("); INV_A1; WRITE(")"); break;
		case CALLMESSAGE1_BIP: 	WRITE("i7_ccall_1("); INV_A1; WRITE(", ");
								INV_A2; WRITE(")"); break;
		case CALLMESSAGE2_BIP: 	WRITE("i7_ccall_2("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(")"); break;
		case CALLMESSAGE3_BIP: 	WRITE("i7_ccall_3("); INV_A1; WRITE(", ");
								INV_A2; WRITE(", "); INV_A3; WRITE(", "); INV_A4; WRITE(")"); break;

		case SPACES_BIP:		WRITE("for (int j = "); INV_A1; WRITE("; j >= 0; j--) printf(\" \")"); break;
		case FONT_BIP:
			WRITE("if ("); INV_A1; WRITE(") { i7_font(1); } else { i7_font(0); }");
			suppress_terminal_semicolon = TRUE;
			break;
		case STYLEROMAN_BIP: WRITE("i7_style(i7_roman)"); break;
		case STYLEBOLD_BIP: WRITE("i7_style(i7_bold)"); break;
		case STYLEUNDERLINE_BIP: WRITE("i7_style(i7_underline)"); break;
		case STYLEREVERSE_BIP: WRITE("i7_style(i7_reverse)"); break;

		case MOVE_BIP: WRITE("i7_move("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;
		case REMOVE_BIP: WRITE("i7_move("); INV_A1; WRITE(", 0)"); break;
		case GIVE_BIP: WRITE("i7_give("); INV_A1; WRITE(", "); INV_A2; WRITE(", 1)"); break;
		case TAKE_BIP: WRITE("i7_give("); INV_A1; WRITE(", "); INV_A2; WRITE(", 0)"); break;

		case ALTERNATIVECASE_BIP: INV_A1; WRITE(", "); INV_A2; break;
		case SEQUENTIAL_BIP: WRITE("("); INV_A1; WRITE(","); INV_A2; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP: @<Generate primitive for ternarysequential@>; break;

		case PRINT_BIP: WRITE("printf(\"%%s\", "); INV_A1_PRINTMODE; WRITE(")"); break;
		case PRINTRET_BIP: WRITE("printf(\"%%s\", "); INV_A1_PRINTMODE; WRITE("); return 1"); break;
		case PRINTCHAR_BIP: WRITE("i7_print_char("); INV_A1; WRITE(")"); break;
		case PRINTNAME_BIP: WRITE("i7_print_name("); INV_A1; WRITE(")"); break;
		case PRINTOBJ_BIP: WRITE("i7_print_object("); INV_A1; WRITE(")"); break;
		case PRINTPROPERTY_BIP: WRITE("i7_print_property("); INV_A1; WRITE(")"); break;
		case PRINTNUMBER_BIP: WRITE("printf(\"%%d\", (int) "); INV_A1; WRITE(")"); break;
		case PRINTADDRESS_BIP: WRITE("i7_print_address("); INV_A1; WRITE(")"); break;
		case PRINTSTRING_BIP: WRITE("printf(\"%%s\", dqs["); INV_A1; WRITE(" - I7VAL_STRINGS_BASE])"); break;
		case PRINTNLNUMBER_BIP: WRITE("i7_print_number("); INV_A1; WRITE(")"); break;
		case PRINTDEF_BIP: WRITE("i7_print_def_art("); INV_A1; WRITE(")"); break;
		case PRINTCDEF_BIP: WRITE("i7_print_cdef_art("); INV_A1; WRITE(")"); break;
		case PRINTINDEF_BIP: WRITE("i7_print_indef_art("); INV_A1; WRITE(")"); break;
		case PRINTCINDEF_BIP: WRITE("i7_print_cindef_art("); INV_A1; WRITE(")"); break;
		case BOX_BIP: WRITE("i7_print_box("); INV_A1_BOXMODE; WRITE(")"); break;

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

		case RANDOM_BIP: WRITE("i7_random("); INV_A1; WRITE(")"); break;

		case READ_BIP: WRITE("i7_read("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;

		default: LOG("Prim: %S\n", prim_name->symbol_name); internal_error("unimplemented prim");
	}
	return suppress_terminal_semicolon;
}

@<Generate comparison@> =
	CodeGen::C::comparison(cgt, gen, bip, InterTree::first_child(P), InterTree::second_child(P));

@<Generate primitive for store@> =
	inter_tree_node *ref = InterTree::first_child(P);
	if (CodeGen::C::basically_an_array_write(gen->from, ref)) {
		WRITE("("); C_write_lookup_mode = TRUE; INV_A1; C_write_lookup_mode = FALSE; INV_A2; WRITE("))");
	} else {
		WRITE("("); INV_A1; WRITE(" = "); INV_A2; WRITE(")");
	}

@<Generate primitive for lookup@> =
	WRITE("i7_lookup(i7mem, "); INV_A1; WRITE(", "); INV_A2; WRITE(")");

@<Generate primitive for lookupref@> =
	WRITE("write_i7_lookup(i7mem, "); INV_A1; WRITE(", "); INV_A2; WRITE(", ");
	
@<Generate primitive for lookupbyte@> =
	WRITE("i7mem["); INV_A1; WRITE(" + "); INV_A2; WRITE("]");

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
		case FALSE: WRITE("return 0"); break;
		case TRUE: WRITE("return 1"); break;
		case NOT_APPLICABLE: WRITE("return (i7val) "); CodeGen::FC::frame(gen, V); break;
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
	WRITE(";"); INV_A2;
	WRITE(";");
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
	CodeGen::C::caser(cgt, gen,  InterTree::first_child(P));
	INDENT; INV_A2; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for default@> =
	WRITE("default:\n"); INDENT; INV_A1; WRITE(";\n"); WRITE("break;\n"); OUTDENT;
	suppress_terminal_semicolon = TRUE;

@ =
void CodeGen::C::caser(code_generation_target *cgt, code_generation *gen, inter_tree_node *X) {
	if (X->W.data[ID_IFLD] == INV_IST) {
		if (X->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(X);
			inter_ti xbip = Primitives::to_bip(gen->from, prim);
			if (xbip == ALTERNATIVECASE_BIP) {
				CodeGen::C::caser(cgt, gen, InterTree::first_child(X));
				CodeGen::C::caser(cgt, gen, InterTree::second_child(X));
				return;
			}
		}
	}
	text_stream *OUT = CodeGen::current(gen);
	WRITE("case ");
	CodeGen::FC::frame(gen, X);
	WRITE(": ");
}

void CodeGen::C::comparison(code_generation_target *cgt, code_generation *gen,
	inter_ti bip, inter_tree_node *X, inter_tree_node *Y) {
	CodeGen::C::comparison_r(cgt, gen, bip, X, Y, 0);
}

void CodeGen::C::comparison_r(code_generation_target *cgt, code_generation *gen,
	inter_ti bip, inter_tree_node *X, inter_tree_node *Y, int depth) {
	if (Y->W.data[ID_IFLD] == INV_IST) {
		if (Y->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(Y);
			inter_ti ybip = Primitives::to_bip(gen->from, prim);
			if (ybip == ALTERNATIVE_BIP) {
				text_stream *OUT = CodeGen::current(gen);
				if (depth == 0) { WRITE("(i7_tmp = "); CodeGen::FC::frame(gen, X); WRITE(", ("); }
				CodeGen::C::comparison_r(cgt, gen, bip, NULL, InterTree::first_child(Y), depth+1);
				WRITE(" || ");
				CodeGen::C::comparison_r(cgt, gen, bip, NULL, InterTree::second_child(Y), depth+1);
				if (depth == 0) { WRITE("))"); }
				return;
			}
		}
	}
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case EQ_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" == "); @<Compile second compared@>; WRITE(")"); break;
		case NE_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" != "); @<Compile second compared@>; WRITE(")"); break;
		case GT_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" > "); @<Compile second compared@>; WRITE(")"); break;
		case GE_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" >= "); @<Compile second compared@>; WRITE(")"); break;
		case LT_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" < "); @<Compile second compared@>; WRITE(")"); break;
		case LE_BIP: 			WRITE("("); @<Compile first compared@>; WRITE(" <= "); @<Compile second compared@>; WRITE(")"); break;
		case OFCLASS_BIP:		WRITE("(i7_ofclass("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
		case HAS_BIP:			WRITE("(i7_has("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
		case HASNT_BIP:			WRITE("(i7_has("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE(") == FALSE)"); break;
		case IN_BIP:			WRITE("(i7_in("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
		case NOTIN_BIP:			WRITE("(i7_in("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE(") == FALSE)"); break;
		case PROVIDES_BIP:		WRITE("(i7_provides("); @<Compile first compared@>; WRITE(", "); @<Compile second compared@>; WRITE("))"); break;
	}
}

@<Compile first compared@> =
	if (X) CodeGen::FC::frame(gen, X); else WRITE("i7_tmp");

@<Compile second compared@> =
	CodeGen::FC::frame(gen, Y);

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
	
	if (printing_mode == FALSE) {
		WRITE("(I7VAL_STRINGS_BASE + %d)", no_double_quoted_C_strings++);
		OUT = double_quoted_C;
	}
	
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
	if (printing_mode == FALSE) WRITE(",\n");
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
	CodeGen::C::declare_property_by_name(gen, name, used);
}

void CodeGen::C::declare_property_by_name(code_generation *gen, text_stream *name, int used) {
	if (used) {
		generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("#define ");
		CodeGen::C::mangle(NULL, OUT, name);
		WRITE(" %d\n", C_property_enumeration_counter++);
		CodeGen::deselect(gen, saved);
	} else {
		generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("#ifndef ");
		CodeGen::C::mangle(NULL, OUT, name);
		WRITE("\n#define ");
		CodeGen::C::mangle(NULL, OUT, name);
		WRITE(" 0\n#endif\n");
		CodeGen::deselect(gen, saved);
	}
}

void CodeGen::C::declare_attribute(code_generation_target *cgt, code_generation *gen,
	text_stream *prop_name) {
	generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CodeGen::C::mangle(cgt, OUT, prop_name);
	WRITE(" %d\n", C_property_enumeration_counter++);
	CodeGen::deselect(gen, saved);
}

@

=
int CodeGen::C::prepare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k) {
	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) != 1) {
			text_stream *S = Str::new();
			WRITE_TO(S, "(");
			CodeGen::C::mangle(cgt, S, I"Global_Vars");
			WRITE_TO(S, "[%d])", k);
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
		WRITE("i7val ");
		CodeGen::C::mangle(cgt, OUT, CodeGen::CL::name(var_name));
		WRITE(" = "); 
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		WRITE(";\n");
		CodeGen::deselect(gen, saved);
	}
	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (k == 0) CodeGen::C::begin_array(cgt, gen, I"Global_Vars", WORD_ARRAY_FORMAT);
		TEMPORARY_TEXT(val)
		CodeGen::select_temporary(gen, val);
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		CodeGen::deselect_temporary(gen);
		CodeGen::C::array_entry(cgt, gen, val, WORD_ARRAY_FORMAT);
		DISCARD_TEXT(val)
		k++;
		if (k == of) {
			if (k < 2) {
				CodeGen::C::array_entry(cgt, gen, I"0", WORD_ARRAY_FORMAT);
				CodeGen::C::array_entry(cgt, gen, I"0", WORD_ARRAY_FORMAT);
			}
			CodeGen::C::end_array(cgt, gen, WORD_ARRAY_FORMAT);
		}
	}
	return k;
}

void CodeGen::C::begin_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name, int continues, int ifndef_me) {
	text_stream *OUT = CodeGen::current(gen);
	if (ifndef_me) {
		WRITE("#ifndef ");
		CodeGen::C::mangle(cgt, OUT, const_name);
		WRITE("\n");
	}
	WRITE("#define ");
	CodeGen::C::mangle(cgt, OUT, const_name);
	if (continues) WRITE(" ");
}
void CodeGen::C::end_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name, int ifndef_me) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\n");
	if (ifndef_me) WRITE("#endif\n");
}

text_stream *C_fn_prototype = NULL;
int C_fn_parameter_count = 0;

typedef struct final_c_function {
	struct text_stream *identifier_as_constant;
	int uses_vararg_model;
	int max_arity;
	CLASS_DEFINITION
} final_c_function;

final_c_function *CodeGen::C::create_fcf(text_stream *unmangled_name) {
	final_c_function *fcf = CREATE(final_c_function);
	fcf->max_arity = 0;
	fcf->uses_vararg_model = FALSE;
	fcf->identifier_as_constant = Str::duplicate(unmangled_name);
	return fcf;
}

void CodeGen::C::declare_fcf(code_generation *gen, final_c_function *fcf) {
	generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CodeGen::C::mangle(NULL, OUT, fcf->identifier_as_constant);
	WRITE(" (I7VAL_FUNCTIONS_BASE + %d)\n", fcf->allocation_id);
	CodeGen::deselect(gen, saved);
}

void CodeGen::C::make_veneer_fcf(code_generation *gen, text_stream *unmangled_name) {
	final_c_function *fcf = CodeGen::C::create_fcf(unmangled_name);
	CodeGen::C::declare_fcf(gen, fcf);
}

final_c_function *C_fn_being_found = NULL;

void CodeGen::C::begin_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	text_stream *fn_name = CodeGen::CL::name(fn);
	C_fn_parameter_count = 0;
	if (pass == 1) {
		C_fn_being_found = CodeGen::C::create_fcf(fn_name);
		fn->translation_data = STORE_POINTER_final_c_function(C_fn_being_found);
		if (C_fn_prototype == NULL) C_fn_prototype = Str::new();
		Str::clear(C_fn_prototype);
		WRITE_TO(C_fn_prototype, "i7val fn_");
		CodeGen::C::mangle(cgt, C_fn_prototype, fn_name);
		WRITE_TO(C_fn_prototype, "(int __argc");
	}
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE("i7val fn_");
		CodeGen::C::mangle(cgt, OUT, fn_name);
		WRITE("(int __argc");
	}
}

void CodeGen::C::begin_function_code(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(") {");
}

void CodeGen::C::place_label(code_generation_target *cgt, code_generation *gen, text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
	WRITE(": ;\n", label_name);
}

void CodeGen::C::end_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	if (pass == 1) {
		WRITE_TO(C_fn_prototype, ")");

		generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("%S;\n", C_fn_prototype);
		CodeGen::deselect(gen, saved);

		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		CodeGen::C::declare_fcf(gen, fcf);
	}
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE("\n}\n");
	}
}

void CodeGen::C::begin_function_call(code_generation_target *cgt, code_generation *gen, inter_symbol *fn, int argc) {
	text_stream *fn_name = CodeGen::CL::name(fn);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("fn_");
	CodeGen::C::mangle(cgt, OUT, fn_name);
	WRITE("(%d", argc);
	if (GENERAL_POINTER_IS_NULL(fn->translation_data) == FALSE) {
		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		if (fcf->uses_vararg_model) {
			WRITE(", %d, (i7varargs) { ", argc);
		}
	}	
}
void CodeGen::C::argument(code_generation_target *cgt, code_generation *gen, inter_tree_node *F, inter_symbol *fn, int argc, int of_argc) {
	text_stream *OUT = CodeGen::current(gen);
	if (GENERAL_POINTER_IS_NULL(fn->translation_data) == FALSE) {
		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		if ((argc > 0) || (fcf->uses_vararg_model == FALSE)) WRITE(", ");
		CodeGen::FC::frame(gen, F);
	} else {
		WRITE(", ");
		CodeGen::FC::frame(gen, F);
	}
}
void CodeGen::C::end_function_call(code_generation_target *cgt, code_generation *gen, inter_symbol *fn, int argc) {
	if (GENERAL_POINTER_IS_NULL(fn->translation_data)) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE(")");
		WRITE(" /* %S has null */", CodeGen::CL::name(fn));
	} else {
		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		text_stream *OUT = CodeGen::current(gen);
		if (fcf->uses_vararg_model) {
			for (int i = argc; i < 10; i++) {
				if (i > 0) WRITE(", ");
				WRITE("0");
			}
			WRITE(" }");
			for (int i = 1; i < fcf->max_arity; i++) WRITE(", 0");
		} else {
			while (argc < fcf->max_arity) {
				WRITE(", 0");
				argc++;
			}
		}
		WRITE(")");
	}
}

int C_operand_count = 0, C_operand_branches = FALSE; inter_tree_node *C_operand_label = NULL;
void CodeGen::C::begin_opcode(code_generation_target *cgt, code_generation *gen, text_stream *opcode) {
	text_stream *OUT = CodeGen::current(gen);
	C_operand_branches = FALSE;
	C_operand_label = NULL;
	if (Str::get_at(opcode, 1) == 'j') { C_operand_branches = TRUE; }
	if (C_operand_branches) WRITE("if (");
	WRITE("glulx_");
	LOOP_THROUGH_TEXT(pos, opcode)
		if (Str::get(pos) != '@')
			PUT(Str::get(pos));
	WRITE("("); C_operand_count = 0;
}
void CodeGen::C::supply_operand(code_generation_target *cgt, code_generation *gen, inter_tree_node *F, int is_label) {
	text_stream *OUT = CodeGen::current(gen);
	if (is_label) {
		C_operand_label = F;
	} else {
		if (C_operand_count++ > 0) WRITE(", ");
		CodeGen::FC::frame(gen, F);
	}
}
void CodeGen::C::end_opcode(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(")");
	if (C_operand_branches) {
		if (negate_label_mode) WRITE(" == FALSE");
		WRITE(") goto ");
		if (C_operand_label == NULL) internal_error("no branch label");
		CodeGen::FC::frame(gen, C_operand_label);
	}
}

void CodeGen::C::declare_local_variable(code_generation_target *cgt, int pass,
	code_generation *gen, inter_tree_node *P, inter_symbol *var_name) {
	C_fn_parameter_count++;
	if (pass == 1) {
		if (Str::eq(var_name->symbol_name, I"_vararg_count")) {
			C_fn_being_found->uses_vararg_model = TRUE;
			WRITE_TO(C_fn_prototype, ", i7val ");
			CodeGen::C::mangle(cgt, C_fn_prototype, var_name->symbol_name);
			WRITE_TO(C_fn_prototype, ", i7varargs ");
			CodeGen::C::mangle(cgt, C_fn_prototype, I"_varargs");
		} else {
			WRITE_TO(C_fn_prototype, ", i7val ");
			CodeGen::C::mangle(cgt, C_fn_prototype, var_name->symbol_name);
		}
		C_fn_being_found->max_arity++;
	}
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		if (Str::eq(var_name->symbol_name, I"_vararg_count")) {
			WRITE(", i7val ");
			CodeGen::C::mangle(cgt, OUT, var_name->symbol_name);
			WRITE(", i7varargs ");
			CodeGen::C::mangle(cgt, OUT, I"_varargs");
		} else {
			WRITE(", i7val ");
			CodeGen::C::mangle(cgt, OUT, var_name->symbol_name);
		}
	}
}

void CodeGen::C::declare_class(code_generation_target *cgt, code_generation *gen, text_stream *class_name) {
	C_class_counter++;
	if (C_class_counter == 1) {
		CodeGen::C::declare_class_inner(cgt, gen, I"Class");
		C_class_counter++;
		CodeGen::C::declare_class_inner(cgt, gen, I"Object");
		C_class_counter++;
		CodeGen::C::declare_class_inner(cgt, gen, I"String");
		C_class_counter++;
		CodeGen::C::declare_class_inner(cgt, gen, I"Routine");
		C_class_counter++;
	}
	CodeGen::C::declare_class_inner(cgt, gen, class_name);
}

void CodeGen::C::declare_class_inner(code_generation_target *cgt, code_generation *gen, text_stream *class_name) {
	generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CodeGen::C::mangle(cgt, OUT, class_name);
	WRITE(" %d\n", C_class_counter);
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_initialiser_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("ref = ");
	CodeGen::C::mangle(cgt, OUT, class_name);
	WRITE(";\n");
	CodeGen::deselect(gen, saved);
}

void CodeGen::C::end_class(code_generation_target *cgt, code_generation *gen, text_stream *class_name) {
}

void CodeGen::C::declare_instance(code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name) {
	generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CodeGen::C::mangle(cgt, OUT, instance_name);
	WRITE(" %d\n", C_instance_counter);
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_initialiser_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("ref = ");
	CodeGen::C::mangle(cgt, OUT, instance_name);
	WRITE(";\n");
	CodeGen::deselect(gen, saved);
}

void CodeGen::C::end_instance(code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name) {
}

void CodeGen::C::assign_property(code_generation_target *cgt, code_generation *gen, text_stream *property_name, text_stream *val, int as_att) {
	generated_segment *saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7_assign(ref, ");
	CodeGen::C::mangle(cgt, OUT, property_name);
	WRITE(", %S, %d);\n", val, as_att);
	CodeGen::deselect(gen, saved);
}

int C_array_entry_count = 0;
text_stream *C_array_name = NULL;

void CodeGen::C::begin_array(code_generation_target *cgt, code_generation *gen, text_stream *array_name, int format) {
	generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CodeGen::C::mangle(cgt, OUT, array_name);
	WRITE(" %d // An array in format %d\n", extent_of_i7mem, format);
	CodeGen::deselect(gen, saved);

	if (C_array_name == NULL) C_array_name = Str::new();
	Str::clear(C_array_name); WRITE_TO(C_array_name, "%S", array_name);
	C_array_entry_count = 0;

	if ((format == TABLE_ARRAY_FORMAT) || (format == BUFFER_ARRAY_FORMAT)) {
		TEMPORARY_TEXT(extname)
		WRITE_TO(extname, "xt_%S", array_name);
		CodeGen::C::array_entry(cgt, gen, extname, format);
		DISCARD_TEXT(extname)
	}
}

void CodeGen::C::array_entry(code_generation_target *cgt, code_generation *gen, text_stream *entry, int format) {
	generated_segment *saved = CodeGen::select(gen, c_mem_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if ((format == TABLE_ARRAY_FORMAT) || (format == WORD_ARRAY_FORMAT)) {
		WRITE("    I7BYTE_0(%S), I7BYTE_1(%S), I7BYTE_2(%S), I7BYTE_3(%S),\n",
			entry, entry, entry, entry);
		extent_of_i7mem += 4;
	} else {
		WRITE("    (i7byte) %S,\n", entry);
		extent_of_i7mem += 1;
	}
	CodeGen::deselect(gen, saved);
	C_array_entry_count++;
}

void CodeGen::C::end_array(code_generation_target *cgt, code_generation *gen, int format) {
	generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if ((format == TABLE_ARRAY_FORMAT) || (format == BUFFER_ARRAY_FORMAT)) {
		WRITE("#define xt_%S %d\n", C_array_name, C_array_entry_count-1);
	}
	CodeGen::deselect(gen, saved);
}

int CodeGen::C::basically_an_array_write(inter_tree *I, inter_tree_node *P) {
	int reffed = FALSE;
	while (P->W.data[ID_IFLD] == REFERENCE_IST) {
		P = InterTree::first_child(P);
		reffed = TRUE;
	}
	if (P->W.data[ID_IFLD] == INV_IST) {
		if (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(P);
			inter_ti bip = Primitives::to_bip(I, prim);
			if (bip == LOOKUPREF_BIP) return TRUE;
			if ((bip == LOOKUP_BIP) && (reffed)) return TRUE;
		}
	}
	return FALSE;
}
