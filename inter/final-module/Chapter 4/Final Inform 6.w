[CodeGen::I6::] Generating Inform 6.

To generate I6 code from intermediate code.

@h Target.

@e pragmatic_matter_I7CGS
@e compiler_versioning_matter_I7CGS
@e predeclarations_I7CGS
@e very_early_matter_I7CGS
@e constants_1_I7CGS
@e constants_2_I7CGS
@e constants_3_I7CGS
@e constants_4_I7CGS
@e constants_5_I7CGS
@e constants_6_I7CGS
@e constants_7_I7CGS
@e constants_8_I7CGS
@e constants_9_I7CGS
@e constants_10_I7CGS
@e predeclarations_2_I7CGS
@e early_matter_I7CGS
@e text_literals_code_I7CGS
@e summations_at_eof_I7CGS
@e arrays_at_eof_I7CGS
@e globals_array_I7CGS
@e main_matter_I7CGS
@e routines_at_eof_I7CGS
@e code_at_eof_I7CGS
@e verbs_at_eof_I7CGS
@e stubs_at_eof_I7CGS
@e property_offset_creator_I7CGS

=
int I6_target_segments[] = {
	pragmatic_matter_I7CGS,
	compiler_versioning_matter_I7CGS,
	predeclarations_I7CGS,
	predeclarations_2_I7CGS,
	very_early_matter_I7CGS,
	constants_1_I7CGS,
	constants_2_I7CGS,
	constants_3_I7CGS,
	constants_4_I7CGS,
	constants_5_I7CGS,
	constants_6_I7CGS,
	constants_7_I7CGS,
	constants_8_I7CGS,
	constants_9_I7CGS,
	constants_10_I7CGS,
	early_matter_I7CGS,
	text_literals_code_I7CGS,
	summations_at_eof_I7CGS,
	arrays_at_eof_I7CGS,
	globals_array_I7CGS,
	main_matter_I7CGS,
	routines_at_eof_I7CGS,
	code_at_eof_I7CGS,
	verbs_at_eof_I7CGS,
	stubs_at_eof_I7CGS,
	property_offset_creator_I7CGS,
	-1
};

@

=
code_generation_target *inform6_target = NULL;
void CodeGen::I6::create_target(void) {
	code_generation_target *cgt = CodeGen::Targets::new(I"inform6");
	METHOD_ADD(cgt, BEGIN_GENERATION_MTID, CodeGen::I6::begin_generation);
	METHOD_ADD(cgt, GENERAL_SEGMENT_MTID, CodeGen::I6::general_segment);
	METHOD_ADD(cgt, TL_SEGMENT_MTID, CodeGen::I6::tl_segment);
	METHOD_ADD(cgt, DEFAULT_SEGMENT_MTID, CodeGen::I6::default_segment);
	METHOD_ADD(cgt, BASIC_CONSTANT_SEGMENT_MTID, CodeGen::I6::basic_constant_segment);
	METHOD_ADD(cgt, CONSTANT_SEGMENT_MTID, CodeGen::I6::constant_segment);
	METHOD_ADD(cgt, COMPILE_PRIMITIVE_MTID, CodeGen::I6::compile_primitive);
	METHOD_ADD(cgt, MANGLE_IDENTIFIER_MTID, CodeGen::I6::mangle);
	METHOD_ADD(cgt, COMPILE_DICTIONARY_WORD_MTID, CodeGen::I6::compile_dictionary_word);
	METHOD_ADD(cgt, COMPILE_LITERAL_NUMBER_MTID, CodeGen::I6::compile_literal_number);
	METHOD_ADD(cgt, COMPILE_LITERAL_REAL_MTID, CodeGen::I6::compile_literal_real);
	METHOD_ADD(cgt, COMPILE_LITERAL_TEXT_MTID, CodeGen::I6::compile_literal_text);
	METHOD_ADD(cgt, DECLARE_PROPERTY_MTID, CodeGen::I6::declare_property);
	METHOD_ADD(cgt, DECLARE_ATTRIBUTE_MTID, CodeGen::I6::declare_attribute);
	METHOD_ADD(cgt, PROPERTY_OFFSET_MTID, CodeGen::I6::property_offset);
	METHOD_ADD(cgt, PREPARE_VARIABLE_MTID, CodeGen::I6::prepare_variable);
	METHOD_ADD(cgt, DECLARE_VARIABLE_MTID, CodeGen::I6::declare_variable);
	METHOD_ADD(cgt, EVALUATE_VARIABLE_MTID, CodeGen::I6::evaluate_variable);
	METHOD_ADD(cgt, DECLARE_CLASS_MTID, CodeGen::I6::declare_class);
	METHOD_ADD(cgt, END_CLASS_MTID, CodeGen::I6::end_class);
	METHOD_ADD(cgt, DECLARE_INSTANCE_MTID, CodeGen::I6::declare_instance);
	METHOD_ADD(cgt, END_INSTANCE_MTID, CodeGen::I6::end_instance);
	METHOD_ADD(cgt, OPTIMISE_PROPERTY_MTID, CodeGen::I6::optimise_property_value);
	METHOD_ADD(cgt, ASSIGN_PROPERTY_MTID, CodeGen::I6::assign_property);
	METHOD_ADD(cgt, DECLARE_LOCAL_VARIABLE_MTID, CodeGen::I6::declare_local_variable);
	METHOD_ADD(cgt, BEGIN_CONSTANT_MTID, CodeGen::I6::begin_constant);
	METHOD_ADD(cgt, END_CONSTANT_MTID, CodeGen::I6::end_constant);
	METHOD_ADD(cgt, BEGIN_FUNCTION_MTID, CodeGen::I6::begin_function);
	METHOD_ADD(cgt, BEGIN_FUNCTION_CODE_MTID, CodeGen::I6::begin_function_code);
	METHOD_ADD(cgt, PLACE_LABEL_MTID, CodeGen::I6::place_label);
	METHOD_ADD(cgt, END_FUNCTION_MTID, CodeGen::I6::end_function);
	METHOD_ADD(cgt, FUNCTION_CALL_MTID, CodeGen::I6::function_call);
	METHOD_ADD(cgt, ASSEMBLY_MTID, CodeGen::I6::assembly);
	METHOD_ADD(cgt, BEGIN_ARRAY_MTID, CodeGen::I6::begin_array);
	METHOD_ADD(cgt, ARRAY_ENTRY_MTID, CodeGen::I6::array_entry);
	METHOD_ADD(cgt, COMPILE_LITERAL_SYMBOL_MTID, CodeGen::I6::compile_literal_symbol);
	METHOD_ADD(cgt, ARRAY_ENTRIES_MTID, CodeGen::I6::array_entries);
	METHOD_ADD(cgt, END_ARRAY_MTID, CodeGen::I6::end_array);
	METHOD_ADD(cgt, OFFER_PRAGMA_MTID, CodeGen::I6::offer_pragma)
	METHOD_ADD(cgt, END_GENERATION_MTID, CodeGen::I6::end_generation);
	METHOD_ADD(cgt, WORLD_MODEL_ESSENTIALS_MTID, CodeGen::I6::world_model_essentials);
	METHOD_ADD(cgt, NEW_ACTION_MTID, CodeGen::I6::new_action);
	inform6_target = cgt;
}

code_generation_target *CodeGen::I6::target(void) {
	return inform6_target;
}

@h Segmentation.
The loss of |life| is so appalling that I6 will not even compile a story
file which doesn't define the property number |life| (well, strictly
speaking, it checks the presence of constants suggesting the I6 library
first, but the template layer does define constants like that). We define
it as a null constant to be sure of avoiding any valid property number; I6
being typeless, that enables the veneer to compile again. (The relevant
code is in |CA__Pr|, defined in the |veneer.c| section of I6.)

|debug_flag| is traditionally called so, but is actually
now a bitmap of flags for tracing actions, calls to object routines, and so on.
It's used in the I6 veneer, and need not exist on any other final compilation target.

@d I6_GEN_DATA(x) ((I6_generation_data *) (gen->target_specific_data))->x

=
typedef struct I6_generation_data {
	int I6_property_offsets_made;
	CLASS_DEFINITION
} I6_generation_data;

int CodeGen::I6::begin_generation(code_generation_target *cgt, code_generation *gen) {
	I6_generation_data *data = CREATE(I6_generation_data);
	data->I6_property_offsets_made = 0;

	CodeGen::create_segments(gen, data, I6_target_segments);

	generated_segment *saved = CodeGen::select(gen, compiler_versioning_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Constant Grammar__Version 2;\n");
	WRITE("Global debug_flag;\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, routines_at_eof_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("#Ifdef TARGET_ZCODE;\n");
	WRITE("Global max_z_object;\n");
	WRITE("[ OC__Cl obj cla j a n objflag;\n"); INDENT;
	WRITE("@jl obj 1 ?NotObj;\n");
	WRITE("@jg obj max_z_object ?NotObj;\n");
	WRITE("@inc objflag;\n");
	WRITE("#Ifdef K1_room;\n");
	WRITE("@je cla K1_room ?~NotRoom;\n");
	WRITE("@test_attr obj mark_as_room ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE(".NotRoom;\n");
	WRITE("#Endif;\n");
	WRITE("#Ifdef K2_thing;\n");
	WRITE("@je cla K2_thing ?~NotObj;\n");
	WRITE("@test_attr obj mark_as_thing ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE("#Endif;\n");
	WRITE(".NotObj;\n");
	WRITE("\n");
	WRITE("@je cla Object Class ?ObjOrClass;\n");
	WRITE("@je cla Routine String ?RoutOrStr;\n");
	WRITE("\n");
	WRITE("@jin cla 1 ?~Mistake;\n");
	WRITE("\n");
	WRITE("@jz objflag ?rfalse;\n");
	WRITE("@get_prop_addr obj 2 -> a;\n");
	WRITE("@jz a ?rfalse;\n");
	WRITE("@get_prop_len a -> n;\n");
	WRITE("\n");
	WRITE("@div n 2 -> n;\n");
	WRITE(".Loop;\n");
	WRITE("@loadw a j -> sp;\n");
	WRITE("@je sp cla ?rtrue;\n");
	WRITE("@inc j;\n");
	WRITE("@jl j n ?Loop;\n");
	WRITE("@rfalse;\n");
	WRITE("\n");
	WRITE(".ObjOrClass;\n");
	WRITE("@jz objflag ?rfalse;\n");
	WRITE("@je cla Object ?JustObj;\n");
	WRITE("\n");
	WRITE("! So now cla is Class\n");
	WRITE("@jg obj String ?~rtrue;\n");
	WRITE("@jin obj Class ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE("\n");
	WRITE(".JustObj;\n");
	WRITE("! So now cla is Object\n");
	WRITE("@jg obj String ?~rfalse;\n");
	WRITE("@jin obj Class ?rfalse;\n");
	WRITE("@rtrue;\n");
	WRITE("\n");
	WRITE(".RoutOrStr;\n");
	WRITE("@jz objflag ?~rfalse;\n");
	WRITE("@call_2s Z__Region obj -> sp;\n");
	WRITE("@inc sp;\n");
	WRITE("@je sp cla ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE("\n");
	WRITE(".Mistake;\n");
	WRITE("RT__Err(\"apply 'ofclass' for\", cla, -1);\n");
	WRITE("rfalse;\n");
	OUTDENT; WRITE("];\n");
	WRITE("#Endif;\n");
	CodeGen::deselect(gen, saved);

	return FALSE;
}

int I6_DebugAttribute_seen = FALSE;
int CodeGen::I6::end_generation(code_generation_target *cgt, code_generation *gen) {
	if (I6_GEN_DATA(I6_property_offsets_made) > 0) {
		generated_segment *saved = CodeGen::select(gen, property_offset_creator_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		OUTDENT;
		WRITE("];\n");
		CodeGen::deselect(gen, saved);
	}
	
	if (I6_DebugAttribute_seen == FALSE) {
		generated_segment *saved = CodeGen::select(gen, routines_at_eof_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("[ DebugAttribute a anames str;\n");
		WRITE("    print \"<attribute \", a, \">\";\n");
		WRITE("];\n");
		CodeGen::deselect(gen, saved);
	}
	
	return FALSE;
}

int CodeGen::I6::general_segment(code_generation_target *cgt, code_generation *gen, inter_tree_node *P) {
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
	return CodeGen::I6::default_segment(cgt);
}

int CodeGen::I6::default_segment(code_generation_target *cgt) {
	return main_matter_I7CGS;
}
int CodeGen::I6::constant_segment(code_generation_target *cgt, code_generation *gen) {
	return early_matter_I7CGS;
}
int CodeGen::I6::basic_constant_segment(code_generation_target *cgt, code_generation *gen, inter_symbol *con_name, int depth) {
	if (depth >= 10) depth = 10;
	return constants_1_I7CGS + depth - 1;
}
int CodeGen::I6::tl_segment(code_generation_target *cgt) {
	return text_literals_code_I7CGS;
}

void CodeGen::I6::offer_pragma(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, text_stream *tag, text_stream *content) {
	if (Str::eq(tag, I"target_I6")) {
		generated_segment *saved = CodeGen::select(gen, pragmatic_matter_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("!%% %S\n", content);
		CodeGen::deselect(gen, saved);
	}
}

void CodeGen::I6::mangle(code_generation_target *cgt, OUTPUT_STREAM, text_stream *identifier) {
	WRITE("%S", identifier);
}

int CodeGen::I6::compile_primitive(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	int suppress_terminal_semicolon = FALSE;
	inter_tree *I = gen->from;
	inter_ti bip = Primitives::to_bip(I, prim_name);
	switch (bip) {
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
		case LOOKUP_BIP:		WRITE("("); INV_A1; WRITE("-->("); INV_A2; WRITE("))"); break;
		case LOOKUPBYTE_BIP:	WRITE("("); INV_A1; WRITE("->("); INV_A2; WRITE("))"); break;
		case PROPERTYADDRESS_BIP: WRITE("("); INV_A1; WRITE(".& "); INV_A2; WRITE(")"); break;
		case PROPERTYLENGTH_BIP: WRITE("("); INV_A1; WRITE(".# "); INV_A2; WRITE(")"); break;
		case PROPERTYVALUE_BIP:	WRITE("("); INV_A1; WRITE("."); INV_A2; WRITE(")"); break;

		case BREAK_BIP:			WRITE("break"); break;
		case CONTINUE_BIP:		WRITE("continue"); break;
		case RETURN_BIP: 		@<Generate primitive for return@>; break;
		case JUMP_BIP: 			WRITE("jump "); INV_A1; break;
		case QUIT_BIP: 			WRITE("quit"); break;
		case RESTORE_BIP: 		WRITE("restore "); INV_A1; break;

		case INDIRECT0_BIP: case INDIRECT0V_BIP: case CALLMESSAGE0_BIP:
								WRITE("("); INV_A1; WRITE(")()"); break;
		case INDIRECT1_BIP: case INDIRECT1V_BIP: case CALLMESSAGE1_BIP:
								WRITE("("); INV_A1; WRITE(")(");
								INV_A2; WRITE(")"); break;
		case INDIRECT2_BIP: case INDIRECT2V_BIP: case CALLMESSAGE2_BIP:
								WRITE("("); INV_A1; WRITE(")(");
								INV_A2; WRITE(","); INV_A3; WRITE(")"); break;
		case INDIRECT3_BIP: case INDIRECT3V_BIP: case CALLMESSAGE3_BIP:
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
		case SPACES_BIP:		WRITE("spaces "); INV_A1; break;
		case FONT_BIP:
			WRITE("if ("); INV_A1; WRITE(") { font on; } else { font off; }");
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

		case MOVE_BIP: WRITE("move "); INV_A1; WRITE(" to "); INV_A2; break;
		case REMOVE_BIP: WRITE("remove "); INV_A1; break;
		case GIVE_BIP: WRITE("give "); INV_A1; WRITE(" "); INV_A2; break;
		case TAKE_BIP: WRITE("give "); INV_A1; WRITE(" ~"); INV_A2; break;

		case ALTERNATIVECASE_BIP: INV_A1; WRITE(", "); INV_A2; break;
		case SEQUENTIAL_BIP: WRITE("("); INV_A1; WRITE(","); INV_A2; WRITE(")"); break;
		case TERNARYSEQUENTIAL_BIP: @<Generate primitive for ternarysequential@>; break;

		case PRINT_BIP: WRITE("print "); INV_A1_PRINTMODE; break;
		case PRINTCHAR_BIP: WRITE("print (char) "); INV_A1; break;
		case PRINTNL_BIP: WRITE("new_line"); break;
		case PRINTOBJ_BIP: WRITE("print (object) "); INV_A1; break;
		case PRINTNUMBER_BIP: WRITE("print "); INV_A1; break;
		case PRINTDWORD_BIP: WRITE("print (address) "); INV_A1; break;
		case PRINTSTRING_BIP: WRITE("print (string) "); INV_A1; break;
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
	WRITE("#ifdef DEBUG;\n"); INDENT; INV_A1; OUTDENT; WRITE("#endif;\n");
	suppress_terminal_semicolon = TRUE;

@<Generate primitive for ifstrict@> =
	WRITE("#ifdef STRICT_MODE;\n"); INDENT; INV_A1; OUTDENT; WRITE("#endif;\n");
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
void CodeGen::I6::compile_dictionary_word(code_generation_target *cgt, code_generation *gen,
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
void CodeGen::I6::compile_literal_number(code_generation_target *cgt,
	code_generation *gen, inter_ti val, int hex_mode) {
	text_stream *OUT = CodeGen::current(gen);
	if (hex_mode) WRITE("$%x", val);
	else WRITE("%d", val);
}

void CodeGen::I6::compile_literal_real(code_generation_target *cgt,
	code_generation *gen, text_stream *textual) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("$%S", textual);
}

@

=
void CodeGen::I6::compile_literal_text(code_generation_target *cgt, code_generation *gen,
	text_stream *S, int printing_mode, int box_mode, int escape_mode) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\"");
	if (escape_mode == FALSE) {
		WRITE("%S", S);
	} else {
		int esc_char = FALSE;
		LOOP_THROUGH_TEXT(pos, S) {
			wchar_t c = Str::get(pos);
			if (box_mode) {
				switch(c) {
					case '@': WRITE("@{40}"); break;
					case '"': WRITE("~"); break;
					case '^': WRITE("@{5E}"); break;
					case '~': WRITE("@{7E}"); break;
					case '\\': WRITE("@{5C}"); break;
					case '\t': WRITE(" "); break;
					case '\n': WRITE("\"\n\""); break;
					case NEWLINE_IN_STRING: WRITE("\"\n\""); break;
					default: PUT(c);
				}
			} else {
				switch(c) {
					case '@':
						if (printing_mode) {
							WRITE("@@64"); esc_char = TRUE; continue;
						}
						WRITE("@{40}"); break;
					case '"': WRITE("~"); break;
					case '^':
						if (printing_mode) {
							WRITE("@@94"); esc_char = TRUE; continue;
						}
						WRITE("@{5E}"); break;
					case '~':
						if (printing_mode) {
							WRITE("@@126"); esc_char = TRUE; continue;
						}
						WRITE("@{7E}"); break;
					case '\\': WRITE("@{5C}"); break;
					case '\t': WRITE(" "); break;
					case '\n': WRITE("^"); break;
					case NEWLINE_IN_STRING: WRITE("^"); break;
					default: {
						if (esc_char) WRITE("@{%02x}", c);
						else PUT(c);
					}
				}
				esc_char = FALSE;
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
void CodeGen::I6::declare_property(code_generation_target *cgt, code_generation *gen,
	inter_symbol *prop_name, int used) {
	text_stream *name = CodeGen::CL::name(prop_name);
	if (used) {
		generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
		WRITE_TO(CodeGen::current(gen), "Property %S;\n", prop_name->symbol_name);
		CodeGen::deselect(gen, saved);
	} else {
		generated_segment *saved = CodeGen::select(gen, code_at_eof_I7CGS);
		WRITE_TO(CodeGen::current(gen), "#ifndef %S; Constant %S = 0; #endif;\n", name, name);
		CodeGen::deselect(gen, saved);
	}
}

void CodeGen::I6::declare_attribute(code_generation_target *cgt, code_generation *gen,
	text_stream *prop_name) {
	WRITE_TO(CodeGen::current(gen), "Attribute %S;\n", prop_name);
}

void CodeGen::I6::property_offset(code_generation_target *cgt, code_generation *gen, text_stream *prop, int pos, int as_attr) {
	generated_segment *saved = CodeGen::select(gen, property_offset_creator_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if (I6_GEN_DATA(I6_property_offsets_made)++ == 0) {
		WRITE("[ CreatePropertyOffsets i;\n"); INDENT;
		WRITE("for (i=0: i<attributed_property_offsets_SIZE: i++)\n"); INDENT;
		WRITE("attributed_property_offsets-->i = -1;\n"); OUTDENT;
		WRITE("for (i=0: i<valued_property_offsets_SIZE: i++)\n"); INDENT;
		WRITE("valued_property_offsets-->i = -1;\n"); OUTDENT;
	}	
	if (as_attr) WRITE("attributed_property_offsets");
	else WRITE("valued_property_offsets");
	WRITE("-->%S = %d;\n", prop, pos);
	CodeGen::deselect(gen, saved);
}

@

=
int CodeGen::I6::prepare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k) {
//	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) != 1) {
			text_stream *S = Str::new();
			WRITE_TO(S, "(Global_Vars-->%d)", k);
			Inter::Symbols::set_translate(var_name, S);
			k++;
		}
//	}
	return k;
}

int CodeGen::I6::declare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k, int of) {
	if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) == 1) {
		generated_segment *saved = CodeGen::select(gen, main_matter_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("Global %S = ", CodeGen::CL::name(var_name));
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		WRITE(";\n");
		CodeGen::deselect(gen, saved);
	} else {
//	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		generated_segment *saved = CodeGen::select(gen, predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		if (k == 0) WRITE("Array Global_Vars -->\n");
		WRITE("  (");
		inter_symbols_table *globals = Inter::Packages::scope_of(P);
		CodeGen::CL::literal(gen, NULL, globals, P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		WRITE(") ! -->%d = %S (%S)\n", k, CodeGen::CL::name(var_name), var_name->symbol_name);
		k++;
		if (k == of) {
			if (k < 2) WRITE("  NULL NULL");
			WRITE(";\n");
		}
		CodeGen::deselect(gen, saved);
	}
	return k;
}

void CodeGen::I6::evaluate_variable(code_generation_target *cgt, code_generation *gen, inter_symbol *var_name, int as_reference) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S", CodeGen::CL::name(var_name));
}

void CodeGen::I6::declare_class(code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *printed_name, text_stream *super_class) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Class %S\n", class_name);
	if (Str::len(super_class) > 0) WRITE("  class %S\n", super_class);
}

void CodeGen::I6::end_class(code_generation_target *cgt, code_generation *gen, text_stream *class_name) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";\n");
}

void CodeGen::I6::declare_instance(code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name, text_stream *printed_name, int acount, int is_dir) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S", class_name);
	for (int i=0; i<acount; i++) WRITE(" ->");
	WRITE(" %S", instance_name);
	if (is_dir) WRITE(" Compass");
}

void CodeGen::I6::end_instance(code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";\n");
}

int CodeGen::I6::optimise_property_value(code_generation_target *cgt, code_generation *gen, inter_symbol *prop_name, inter_tree_node *X) {
	if (Inter::Symbols::is_stored_in_data(X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD])) {
		inter_symbol *S = InterSymbolsTables::symbol_from_data_pair_and_frame(X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD], X);
		if ((S) && (Inter::Symbols::read_annotation(S, INLINE_ARRAY_IANN) == 1)) {
			inter_tree_node *P = Inter::Symbols::definition(S);
			text_stream *OUT = CodeGen::current(gen);
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				if (i>DATA_CONST_IFLD) WRITE(" ");
				CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[i], P->W.data[i+1], FALSE);
			}
			return TRUE;
		}
	}
	return FALSE;
}

void CodeGen::I6::assign_property(code_generation_target *cgt, code_generation *gen, text_stream *property_name, text_stream *val, int as_att) {
	text_stream *OUT = CodeGen::current(gen);
	if (as_att) {
		if (Str::eq(val, I"0")) WRITE("    has ~%S\n", property_name);
		else WRITE("    has %S\n", property_name);
	} else {
		WRITE("    with %S %S\n", property_name, val);
	}
}

void CodeGen::I6::declare_local_variable(code_generation_target *cgt, int pass,
	code_generation *gen, inter_tree_node *P, inter_symbol *var_name) {
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE(" %S", var_name->symbol_name);
	}
}

int CodeGen::I6::begin_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name, inter_symbol *const_s, inter_tree_node *P, int continues, int ifndef_me) {
	text_stream *OUT = CodeGen::current(gen);

	if ((const_s) && (Inter::Symbols::read_annotation(const_s, INLINE_ARRAY_IANN) == 1)) return FALSE;

	if (Str::eq(const_name, I"FLOAT_INFINITY")) return FALSE;
	if (Str::eq(const_name, I"FLOAT_NINFINITY")) return FALSE;
	if (Str::eq(const_name, I"FLOAT_NAN")) return FALSE;
	if (Str::eq(const_name, I"nothing")) return FALSE;
	if (Str::eq(const_name, I"#dict_par1")) return FALSE;
	if (Str::eq(const_name, I"#dict_par2")) return FALSE;

	if (Str::eq(const_name, I"Release")) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
		WRITE("Release ");
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return FALSE;
	}

	if (Str::eq(const_name, I"Story")) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
		WRITE("Global Story = ");
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return FALSE;
	}

	if (Str::eq(const_name, I"Serial")) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
		WRITE("Serial ");
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return FALSE;
	}

	if (ifndef_me) WRITE("#ifndef %S;\n", const_name);
	WRITE("Constant %S", const_name);
	if (continues) WRITE(" = ");
	return TRUE;
}
void CodeGen::I6::end_constant(code_generation_target *cgt, code_generation *gen, text_stream *const_name, int ifndef_me) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";\n");
	if (ifndef_me) WRITE("#endif;\n");
}

int this_is_I6_Main = 0;
void CodeGen::I6::begin_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	text_stream *fn_name = CodeGen::CL::name(fn);
	this_is_I6_Main = 0;
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE("[ %S", fn_name);
		if (Str::eq(fn_name, I"Main")) this_is_I6_Main = 1;
		if (Str::eq(fn_name, I"DebugAction")) this_is_I6_Main = 2;
		if (Str::eq(fn_name, I"DebugAttribute")) { this_is_I6_Main = 3; I6_DebugAttribute_seen = TRUE; }
		if (Str::eq(fn_name, I"DebugProperty")) this_is_I6_Main = 4;
	}
}
void CodeGen::I6::begin_function_code(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";");
	switch (this_is_I6_Main) {
		case 1:
			WRITE("#ifdef TARGET_ZCODE; max_z_object = #largest_object - 255; #endif;\n");
			break;
		case 2:
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
			break;
		case 3:
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
			break;
		case 4:
			WRITE("print (property) p;\n");
			WRITE("return;\n");
			break;			
	}
}
void CodeGen::I6::place_label(code_generation_target *cgt, code_generation *gen, text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S;\n", label_name);
}

@ This enables use of March 2009 extension to Glulx which optimises the speed
of Inform-compiled story files by moving the work of I6 veneer routines into
the interpreter itself. The empty function declaration here is misleading: its
actual contents are written out longhand during final code compilation to
Glulx, but not during e.g. final code compilation to C. This means that the
Inter tree doesn't need to refer to eldritch Glulx-only symbols like |#g$self|
or implement assembly-language operations like |@accelparam|. (See //final//.)

=
void CodeGen::I6::end_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		text_stream *fn_name = CodeGen::CL::name(fn);
		if (Str::eq(fn_name, I"FINAL_CODE_STARTUP_R")) {
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
		}
		WRITE("];\n");
	}
}

void CodeGen::I6::function_call(code_generation_target *cgt, code_generation *gen, inter_symbol *fn, inter_tree_node *P, int argc) {
	text_stream *fn_name = CodeGen::CL::name(fn);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S(", fn_name);
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P) {
		if (c++ > 0) WRITE(", ");
		CodeGen::FC::frame(gen, F);
	}
	WRITE(")");
}

void CodeGen::I6::assembly(code_generation_target *cgt, code_generation *gen,
	text_stream *opcode, int operand_count, inter_tree_node **operands,
	inter_tree_node *label, int label_sense) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S", opcode);
	for (int opc = 0; opc < operand_count; opc++) {
		WRITE(" ");
		CodeGen::FC::frame(gen, operands[opc]);
	}
	if (label) {
		WRITE(" ?");
		if (label_sense == FALSE) WRITE("~");
		CodeGen::FC::frame(gen, label);
	}
}

int CodeGen::I6::begin_array(code_generation_target *cgt, code_generation *gen, text_stream *array_name, inter_symbol *array_s, inter_tree_node *P, int format) {
	text_stream *OUT = CodeGen::current(gen);
	
	if ((array_s) && (Inter::Symbols::read_annotation(array_s, VERBARRAY_IANN) == 1)) {
		WRITE("Verb ");
		if (Inter::Symbols::read_annotation(array_s, METAVERB_IANN) == 1) WRITE("meta ");
		for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
			WRITE(" ");
			CodeGen::CL::literal(gen, array_s, Inter::Packages::scope_of(P), P->W.data[i], P->W.data[i+1], TRUE);
		}
		WRITE(";");
		return FALSE;
	}
	WRITE("Array %S ", array_name);
	switch (format) {
		case WORD_ARRAY_FORMAT: WRITE("-->"); break;
		case BYTE_ARRAY_FORMAT: WRITE("->"); break;
		case TABLE_ARRAY_FORMAT: WRITE("table"); break;
		case BUFFER_ARRAY_FORMAT: WRITE("buffer"); break;
	}
	return TRUE;
}

void CodeGen::I6::array_entry(code_generation_target *cgt, code_generation *gen, text_stream *entry, int format) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(" (%S)", entry);
}

void CodeGen::I6::compile_literal_symbol(code_generation_target *cgt, code_generation *gen, inter_symbol *aliased, int unsub) {
	text_stream *OUT = CodeGen::current(gen);
	if (aliased == verb_directive_divider_symbol) WRITE("\n\t*");
	else if (aliased == verb_directive_reverse_symbol) WRITE("reverse");
	else if (aliased == verb_directive_slash_symbol) WRITE("/");
	else if (aliased == verb_directive_result_symbol) WRITE("->");
	else if (aliased == verb_directive_special_symbol) WRITE("special");
	else if (aliased == verb_directive_number_symbol) WRITE("number");
	else if (aliased == verb_directive_noun_symbol) WRITE("noun");
	else if (aliased == verb_directive_multi_symbol) WRITE("multi");
	else if (aliased == verb_directive_multiinside_symbol) WRITE("multiinside");
	else if (aliased == verb_directive_multiheld_symbol) WRITE("multiheld");
	else if (aliased == verb_directive_held_symbol) WRITE("held");
	else if (aliased == verb_directive_creature_symbol) WRITE("creature");
	else if (aliased == verb_directive_topic_symbol) WRITE("topic");
	else if (aliased == verb_directive_multiexcept_symbol) WRITE("multiexcept");
	else {
		if ((unsub) && (Inter::Symbols::read_annotation(aliased, SCOPE_FILTER_IANN) == 1))
			WRITE("scope=");
		if ((unsub) && (Inter::Symbols::read_annotation(aliased, NOUN_FILTER_IANN) == 1))
			WRITE("noun=");
		text_stream *S = CodeGen::CL::name(aliased);
		if ((unsub) && (Str::begins_with_wide_string(S, L"##"))) {
			LOOP_THROUGH_TEXT(pos, S)
				if (pos.index >= 2)
					PUT(Str::get(pos));
		} else {
			CodeGen::Targets::mangle(gen, OUT, S);
		}
	}
}

@ Alternatively, we can just specify how many entries there will be: they will
then be initialised to 0.

=
void CodeGen::I6::array_entries(code_generation_target *cgt, code_generation *gen,
	int how_many, int plus_ips, int format) {
	text_stream *OUT = CodeGen::current(gen);
	if (plus_ips) WRITE(" (%d + INDIV_PROP_START)", how_many, plus_ips);
	else WRITE(" (%d)", how_many);
}

void CodeGen::I6::end_array(code_generation_target *cgt, code_generation *gen, int format) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";\n");
}

void CodeGen::I6::new_action(code_generation_target *cgt, code_generation *gen, text_stream *name, int true_action) {
	if (true_action == FALSE) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE("Fake_Action %S;\n", name);
	}
}

void CodeGen::I6::world_model_essentials(code_generation_target *cgt, code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::default_segment(gen));
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Object Compass \"compass\" has concealed;\n");
	WRITE("Object thedark \"(darkness object)\";\n");
	WRITE("Object InformParser \"(Inform Parser)\" has proper;\n");
	WRITE("Object InformLibrary \"(Inform Library)\" has proper;\n");
	CodeGen::deselect(gen, saved);
}
