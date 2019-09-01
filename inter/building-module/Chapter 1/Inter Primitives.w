[Primitives::] Inter Primitives.

@

=
void Primitives::emit(inter_tree *I, inter_bookmark *IBM) {
	Primitives::emit_one(I, IBM, I"!font", I"val -> void");
	Primitives::emit_one(I, IBM, I"!stylebold", I"void -> void");
	Primitives::emit_one(I, IBM, I"!styleunderline", I"void -> void");
	Primitives::emit_one(I, IBM, I"!stylereverse", I"void -> void");
	Primitives::emit_one(I, IBM, I"!styleroman", I"void -> void");
	Primitives::emit_one(I, IBM, I"!print", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printret", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printchar", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printname", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printobj", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printproperty", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printnumber", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printaddress", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printstring", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printnlnumber", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printdef", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printcdef", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printindef", I"val -> void");
	Primitives::emit_one(I, IBM, I"!printcindef", I"val -> void");
	Primitives::emit_one(I, IBM, I"!box", I"val -> void");
	Primitives::emit_one(I, IBM, I"!push", I"val -> void");
	Primitives::emit_one(I, IBM, I"!pull", I"ref -> void");
	Primitives::emit_one(I, IBM, I"!postincrement", I"ref -> val");
	Primitives::emit_one(I, IBM, I"!preincrement", I"ref -> val");
	Primitives::emit_one(I, IBM, I"!postdecrement", I"ref -> val");
	Primitives::emit_one(I, IBM, I"!predecrement", I"ref -> val");
	Primitives::emit_one(I, IBM, I"!return", I"val -> void");
	Primitives::emit_one(I, IBM, I"!quit", I"void -> void");
	Primitives::emit_one(I, IBM, I"!restore", I"lab -> void");
	Primitives::emit_one(I, IBM, I"!spaces", I"val -> void");
	Primitives::emit_one(I, IBM, I"!break", I"void -> void");
	Primitives::emit_one(I, IBM, I"!continue", I"void -> void");
	Primitives::emit_one(I, IBM, I"!jump", I"lab -> void");
	Primitives::emit_one(I, IBM, I"!move", I"val val -> void");
	Primitives::emit_one(I, IBM, I"!remove", I"val -> void");
	Primitives::emit_one(I, IBM, I"!give", I"val val -> void");
	Primitives::emit_one(I, IBM, I"!take", I"val val -> void");
	Primitives::emit_one(I, IBM, I"!store", I"ref val -> val");
	Primitives::emit_one(I, IBM, I"!setbit", I"ref val -> void");
	Primitives::emit_one(I, IBM, I"!clearbit", I"ref val -> void");
	Primitives::emit_one(I, IBM, I"!modulo", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!random", I"val -> val");
	Primitives::emit_one(I, IBM, I"!lookup", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!lookupbyte", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!lookupref", I"val val -> ref");
	Primitives::emit_one(I, IBM, I"!not", I"val -> val");
	Primitives::emit_one(I, IBM, I"!and", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!or", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!alternative", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!alternativecase", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!bitwiseand", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!bitwiseor", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!bitwisenot", I"val -> val");
	Primitives::emit_one(I, IBM, I"!eq", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!ne", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!gt", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!ge", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!lt", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!le", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!has", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!hasnt", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!in", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!ofclass", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!sequential", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!ternarysequential", I"val val val -> val");
	Primitives::emit_one(I, IBM, I"!plus", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!minus", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!unaryminus", I"val -> val");
	Primitives::emit_one(I, IBM, I"!times", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!divide", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!if", I"val code -> void");
	Primitives::emit_one(I, IBM, I"!ifdebug", I"code -> void");
	Primitives::emit_one(I, IBM, I"!ifstrict", I"code -> void");
	Primitives::emit_one(I, IBM, I"!ifelse", I"val code code -> void");
	Primitives::emit_one(I, IBM, I"!while", I"val code -> void");
	Primitives::emit_one(I, IBM, I"!do", I"val code -> void");
	Primitives::emit_one(I, IBM, I"!for", I"val val val code -> void");
	Primitives::emit_one(I, IBM, I"!objectloop", I"ref val val code -> void");
	Primitives::emit_one(I, IBM, I"!objectloopx", I"ref val code -> void");
	Primitives::emit_one(I, IBM, I"!switch", I"val code -> void");
	Primitives::emit_one(I, IBM, I"!case", I"val code -> void");
	Primitives::emit_one(I, IBM, I"!default", I"code -> void");
	Primitives::emit_one(I, IBM, I"!indirect0v", I"val -> void");
	Primitives::emit_one(I, IBM, I"!indirect1v", I"val val -> void");
	Primitives::emit_one(I, IBM, I"!indirect2v", I"val val val -> void");
	Primitives::emit_one(I, IBM, I"!indirect3v", I"val val val val -> void");
	Primitives::emit_one(I, IBM, I"!indirect4v", I"val val val val val -> void");
	Primitives::emit_one(I, IBM, I"!indirect5v", I"val val val val val val -> void");
	Primitives::emit_one(I, IBM, I"!indirect0", I"val -> val");
	Primitives::emit_one(I, IBM, I"!indirect1", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!indirect2", I"val val val -> val");
	Primitives::emit_one(I, IBM, I"!indirect3", I"val val val val -> val");
	Primitives::emit_one(I, IBM, I"!indirect4", I"val val val val val -> val");
	Primitives::emit_one(I, IBM, I"!indirect5", I"val val val val val val -> val");
	Primitives::emit_one(I, IBM, I"!message0", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!message1", I"val val val -> val");
	Primitives::emit_one(I, IBM, I"!message2", I"val val val val -> val");
	Primitives::emit_one(I, IBM, I"!message3", I"val val val val val -> val");
	Primitives::emit_one(I, IBM, I"!callmessage0", I"val -> val");
	Primitives::emit_one(I, IBM, I"!callmessage1", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!callmessage2", I"val val val -> val");
	Primitives::emit_one(I, IBM, I"!callmessage3", I"val val val val -> val");
	Primitives::emit_one(I, IBM, I"!propertyaddress", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!propertylength", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!provides", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!propertyvalue", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!notin", I"val val -> val");
	Primitives::emit_one(I, IBM, I"!read", I"val val -> void");
	Primitives::emit_one(I, IBM, I"!inversion", I"void -> void");
}

inter_symbol *Primitives::get(inter_tree *I, inter_t bip) {
	if (I == NULL) internal_error("no tree");
	if ((bip < 1) || (bip >= MAX_BIPS)) internal_error("bip out of range");
	return Site::get_opcode(I, bip);
}

void Primitives::emit_one(inter_tree *I, inter_bookmark *IBM, text_stream *prim, text_stream *category) {
	TEMPORARY_TEXT(prim_command);
	WRITE_TO(prim_command, "primitive %S %S", prim, category);
	Produce::guard(Inter::Defn::read_construct_text(prim_command, NULL, IBM));
	inter_error_message *E = NULL;
	inter_symbol *S = Inter::Textual::find_symbol(I, NULL, Inter::Tree::global_scope(I), prim, PRIMITIVE_IST, &E);
	inter_t bip = Primitives::to_bip(I, S);
	if (bip == 0) internal_error("missing bip");
	if (bip >= MAX_BIPS) internal_error("unsafely high bip");
	Site::set_opcode(I, bip, S);
	Produce::guard(E);
	DISCARD_TEXT(prim_command);
}

int Primitives::is_indirect_interp(inter_t s) {
	if (s == INDIRECT0_BIP) return TRUE;
	if (s == INDIRECT1_BIP) return TRUE;
	if (s == INDIRECT2_BIP) return TRUE;
	if (s == INDIRECT3_BIP) return TRUE;
	if (s == INDIRECT4_BIP) return TRUE;
	if (s == INDIRECT5_BIP) return TRUE;
	return FALSE;
}

inter_t Primitives::indirect_interp(int arity) {
	switch (arity) {
		case 0: return INDIRECT0_BIP;
		case 1: return INDIRECT1_BIP;
		case 2: return INDIRECT2_BIP;
		case 3: return INDIRECT3_BIP;
		case 4: return INDIRECT4_BIP;
		case 5: return INDIRECT5_BIP;
		default: internal_error("indirect function call with too many arguments");
	}
	return 0;
}

int Primitives::is_indirectv_interp(inter_t s) {
	if (s == INDIRECT0V_BIP) return TRUE;
	if (s == INDIRECT1V_BIP) return TRUE;
	if (s == INDIRECT2V_BIP) return TRUE;
	if (s == INDIRECT3V_BIP) return TRUE;
	if (s == INDIRECT4V_BIP) return TRUE;
	if (s == INDIRECT5V_BIP) return TRUE;
	return FALSE;
}

inter_t Primitives::indirectv_interp(int arity) {
	switch (arity) {
		case 0: return INDIRECT0V_BIP;
		case 1: return INDIRECT1V_BIP;
		case 2: return INDIRECT2V_BIP;
		case 3: return INDIRECT3V_BIP;
		case 4: return INDIRECT4V_BIP;
		case 5: return INDIRECT5V_BIP;
		default: internal_error("indirectv function call with too many arguments");
	}
	return 0;
}

@

@d MAX_BIPS 200

@e NOT_BIP from 1
@e AND_BIP
@e OR_BIP
@e ALTERNATIVE_BIP
@e ALTERNATIVECASE_BIP
@e BITWISEAND_BIP
@e BITWISEOR_BIP
@e BITWISENOT_BIP
@e EQ_BIP
@e NE_BIP
@e GT_BIP
@e GE_BIP
@e LT_BIP
@e LE_BIP
@e OFCLASS_BIP
@e HAS_BIP
@e HASNT_BIP
@e IN_BIP
@e NOTIN_BIP
@e SEQUENTIAL_BIP
@e TERNARYSEQUENTIAL_BIP
@e PLUS_BIP
@e MINUS_BIP
@e UNARYMINUS_BIP
@e TIMES_BIP
@e DIVIDE_BIP
@e MODULO_BIP
@e RANDOM_BIP
@e RETURN_BIP
@e MOVE_BIP
@e REMOVE_BIP
@e GIVE_BIP
@e TAKE_BIP
@e JUMP_BIP
@e QUIT_BIP
@e RESTORE_BIP
@e SPACES_BIP
@e BREAK_BIP
@e CONTINUE_BIP
@e STYLEROMAN_BIP
@e FONT_BIP
@e STYLEBOLD_BIP
@e STYLEUNDERLINE_BIP
@e STYLEREVERSE_BIP
@e PRINT_BIP
@e PRINTRET_BIP
@e PRINTCHAR_BIP
@e PRINTNAME_BIP
@e PRINTOBJ_BIP
@e PRINTPROPERTY_BIP
@e PRINTNUMBER_BIP
@e PRINTADDRESS_BIP
@e PRINTSTRING_BIP
@e PRINTNLNUMBER_BIP
@e PRINTDEF_BIP
@e PRINTCDEF_BIP
@e PRINTINDEF_BIP
@e PRINTCINDEF_BIP
@e BOX_BIP
@e PUSH_BIP
@e PULL_BIP
@e PREINCREMENT_BIP
@e POSTINCREMENT_BIP
@e PREDECREMENT_BIP
@e POSTDECREMENT_BIP
@e STORE_BIP
@e SETBIT_BIP
@e CLEARBIT_BIP
@e IF_BIP
@e IFDEBUG_BIP
@e IFSTRICT_BIP
@e IFELSE_BIP
@e WHILE_BIP
@e DO_BIP
@e FOR_BIP
@e OBJECTLOOP_BIP
@e OBJECTLOOPX_BIP
@e LOOKUP_BIP
@e LOOKUPBYTE_BIP
@e LOOKUPREF_BIP
@e LOOP_BIP
@e SWITCH_BIP
@e CASE_BIP
@e DEFAULT_BIP
@e INDIRECT0V_BIP
@e INDIRECT1V_BIP
@e INDIRECT2V_BIP
@e INDIRECT3V_BIP
@e INDIRECT4V_BIP
@e INDIRECT5V_BIP
@e INDIRECT0_BIP
@e INDIRECT1_BIP
@e INDIRECT2_BIP
@e INDIRECT3_BIP
@e INDIRECT4_BIP
@e INDIRECT5_BIP
@e MESSAGE0_BIP
@e MESSAGE1_BIP
@e MESSAGE2_BIP
@e MESSAGE3_BIP
@e CALLMESSAGE0_BIP
@e CALLMESSAGE1_BIP
@e CALLMESSAGE2_BIP
@e CALLMESSAGE3_BIP
@e PROPERTYADDRESS_BIP
@e PROPERTYLENGTH_BIP
@e PROVIDES_BIP
@e PROPERTYVALUE_BIP
@e READ_BIP
@e INVERSION_BIP

=
text_stream *Primitives::name(inter_t bip) {
	switch (bip) {
		case NOT_BIP: return I"!not";
		case AND_BIP: return I"!and";
		case OR_BIP: return I"!or";
		case ALTERNATIVE_BIP: return I"!alternative";
		case ALTERNATIVECASE_BIP: return I"!alternativecase";
		case BITWISEAND_BIP: return I"!bitwiseand";
		case BITWISEOR_BIP: return I"!bitwiseor";
		case BITWISENOT_BIP: return I"!bitwisenot";
		case EQ_BIP: return I"!eq";
		case NE_BIP: return I"!ne";
		case GT_BIP: return I"!gt";
		case GE_BIP: return I"!ge";
		case LT_BIP: return I"!lt";
		case LE_BIP: return I"!le";
		case OFCLASS_BIP: return I"!ofclass";
		case HAS_BIP: return I"!has";
		case HASNT_BIP: return I"!hasnt";
		case IN_BIP: return I"!in";
		case NOTIN_BIP: return I"!notin";
		case SEQUENTIAL_BIP: return I"!sequential";
		case TERNARYSEQUENTIAL_BIP: return I"!ternarysequential";
		case PLUS_BIP: return I"!plus";
		case MINUS_BIP: return I"!minus";
		case UNARYMINUS_BIP: return I"!unaryminus";
		case TIMES_BIP: return I"!times";
		case DIVIDE_BIP: return I"!divide";
		case MODULO_BIP: return I"!modulo";
		case RANDOM_BIP: return I"!random";
		case RETURN_BIP: return I"!return";
		case JUMP_BIP: return I"!jump";
		case GIVE_BIP: return I"!give";
		case TAKE_BIP: return I"!take";
		case MOVE_BIP: return I"!move";
		case REMOVE_BIP: return I"!remove";
		case QUIT_BIP: return I"!quit";
		case RESTORE_BIP: return I"!restore";
		case SPACES_BIP: return I"!spaces";
		case BREAK_BIP: return I"!break";
		case CONTINUE_BIP: return I"!continue";
		case FONT_BIP: return I"!font";
		case STYLEROMAN_BIP: return I"!styleroman";
		case STYLEBOLD_BIP: return I"!stylebold";
		case STYLEUNDERLINE_BIP: return I"!styleunderline";
		case STYLEREVERSE_BIP: return I"!stylereverse";
		case PRINT_BIP: return I"!print";
		case PRINTRET_BIP: return I"!printret";
		case PRINTCHAR_BIP: return I"!printchar";
		case PRINTNAME_BIP: return I"!printname";
		case PRINTOBJ_BIP: return I"!printobj";
		case PRINTPROPERTY_BIP: return I"!printproperty";
		case PRINTNUMBER_BIP: return I"!printnumber";
		case PRINTADDRESS_BIP: return I"!printaddress";
		case PRINTSTRING_BIP: return I"!printstring";
		case PRINTNLNUMBER_BIP: return I"!printnlnumber";
		case PRINTDEF_BIP: return I"!printdef";
		case PRINTCDEF_BIP: return I"!printcdef";
		case PRINTINDEF_BIP: return I"!printindef";
		case PRINTCINDEF_BIP: return I"!printcindef";
		case BOX_BIP: return I"!box";
		case PUSH_BIP: return I"!push";
		case PULL_BIP: return I"!pull";
		case PREINCREMENT_BIP: return I"!preincrement";
		case POSTINCREMENT_BIP: return I"!postincrement";
		case PREDECREMENT_BIP: return I"!predecrement";
		case POSTDECREMENT_BIP: return I"!postdecrement";
		case STORE_BIP: return I"!store";
		case SETBIT_BIP: return I"!setbit";
		case CLEARBIT_BIP: return I"!clearbit";
		case IF_BIP: return I"!if";
		case IFDEBUG_BIP: return I"!ifdebug";
		case IFSTRICT_BIP: return I"!ifstrict";
		case IFELSE_BIP: return I"!ifelse";
		case WHILE_BIP: return I"!while";
		case DO_BIP: return I"!do";
		case FOR_BIP: return I"!for";
		case OBJECTLOOP_BIP: return I"!objectloop";
		case OBJECTLOOPX_BIP: return I"!objectloopx";
		case LOOKUP_BIP: return I"!lookup";
		case LOOKUPBYTE_BIP: return I"!lookupbyte";
		case LOOKUPREF_BIP: return I"!lookupref";
		case LOOP_BIP: return I"!loop";
		case SWITCH_BIP: return I"!switch";
		case CASE_BIP: return I"!case";
		case DEFAULT_BIP: return I"!default";
		case INDIRECT0V_BIP: return I"!indirect0v";
		case INDIRECT1V_BIP: return I"!indirect1v";
		case INDIRECT2V_BIP: return I"!indirect2v";
		case INDIRECT3V_BIP: return I"!indirect3v";
		case INDIRECT4V_BIP: return I"!indirect4v";
		case INDIRECT5V_BIP: return I"!indirect5v";
		case INDIRECT0_BIP: return I"!indirect0";
		case INDIRECT1_BIP: return I"!indirect1";
		case INDIRECT2_BIP: return I"!indirect2";
		case INDIRECT3_BIP: return I"!indirect3";
		case INDIRECT4_BIP: return I"!indirect4";
		case INDIRECT5_BIP: return I"!indirect5";
		case MESSAGE0_BIP: return I"!message0";
		case MESSAGE1_BIP: return I"!message1";
		case MESSAGE2_BIP: return I"!message2";
		case MESSAGE3_BIP: return I"!message3";
		case CALLMESSAGE0_BIP: return I"!callmessage0";
		case CALLMESSAGE1_BIP: return I"!callmessage1";
		case CALLMESSAGE2_BIP: return I"!callmessage2";
		case CALLMESSAGE3_BIP: return I"!callmessage3";
		case PROPERTYADDRESS_BIP: return I"!propertyaddress";
		case PROPERTYLENGTH_BIP: return I"!propertylength";
		case PROVIDES_BIP: return I"!provides";
		case PROPERTYVALUE_BIP: return I"!propertyvalue";
		case READ_BIP: return I"!read";
		case INVERSION_BIP: return I"!inversion";
	}
	return I"<none>";
}

void Primitives::scan_tree(inter_tree *I) {
	Inter::Tree::traverse_root_only(I, Primitives::scan_visitor, NULL, PRIMITIVE_IST);
}

void Primitives::scan_visitor(inter_tree *I, inter_tree_node *P, void *v_state) {
	inter_symbol *prim_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PRIM_IFLD);
	inter_t bip = Primitives::to_bip(I, prim_name);
	if (bip) Site::set_opcode(I, bip, prim_name);
}

inter_t Primitives::to_bip(inter_tree *I, inter_symbol *symb) {
	if (symb == NULL) return 0;
	int B = Inter::Symbols::read_annotation(symb, BIP_CODE_IANN);
	inter_t bip = (B > 0)?((inter_t) B):0;
	if (bip != 0) return bip;
	if (Str::eq(symb->symbol_name, I"!not")) bip = NOT_BIP;
	if (Str::eq(symb->symbol_name, I"!and")) bip = AND_BIP;
	if (Str::eq(symb->symbol_name, I"!or")) bip = OR_BIP;
	if (Str::eq(symb->symbol_name, I"!alternative")) bip = ALTERNATIVE_BIP;
	if (Str::eq(symb->symbol_name, I"!alternativecase")) bip = ALTERNATIVECASE_BIP;
	if (Str::eq(symb->symbol_name, I"!bitwiseand")) bip = BITWISEAND_BIP;
	if (Str::eq(symb->symbol_name, I"!bitwiseor")) bip = BITWISEOR_BIP;
	if (Str::eq(symb->symbol_name, I"!bitwisenot")) bip = BITWISENOT_BIP;
	if (Str::eq(symb->symbol_name, I"!eq")) bip = EQ_BIP;
	if (Str::eq(symb->symbol_name, I"!ne")) bip = NE_BIP;
	if (Str::eq(symb->symbol_name, I"!gt")) bip = GT_BIP;
	if (Str::eq(symb->symbol_name, I"!ge")) bip = GE_BIP;
	if (Str::eq(symb->symbol_name, I"!lt")) bip = LT_BIP;
	if (Str::eq(symb->symbol_name, I"!le")) bip = LE_BIP;
	if (Str::eq(symb->symbol_name, I"!ofclass")) bip = OFCLASS_BIP;
	if (Str::eq(symb->symbol_name, I"!has")) bip = HAS_BIP;
	if (Str::eq(symb->symbol_name, I"!hasnt")) bip = HASNT_BIP;
	if (Str::eq(symb->symbol_name, I"!in")) bip = IN_BIP;
	if (Str::eq(symb->symbol_name, I"!notin")) bip = NOTIN_BIP;
	if (Str::eq(symb->symbol_name, I"!sequential")) bip = SEQUENTIAL_BIP;
	if (Str::eq(symb->symbol_name, I"!ternarysequential")) bip = TERNARYSEQUENTIAL_BIP;
	if (Str::eq(symb->symbol_name, I"!plus")) bip = PLUS_BIP;
	if (Str::eq(symb->symbol_name, I"!minus")) bip = MINUS_BIP;
	if (Str::eq(symb->symbol_name, I"!unaryminus")) bip = UNARYMINUS_BIP;
	if (Str::eq(symb->symbol_name, I"!times")) bip = TIMES_BIP;
	if (Str::eq(symb->symbol_name, I"!divide")) bip = DIVIDE_BIP;
	if (Str::eq(symb->symbol_name, I"!modulo")) bip = MODULO_BIP;
	if (Str::eq(symb->symbol_name, I"!random")) bip = RANDOM_BIP;
	if (Str::eq(symb->symbol_name, I"!return")) bip = RETURN_BIP;
	if (Str::eq(symb->symbol_name, I"!jump")) bip = JUMP_BIP;
	if (Str::eq(symb->symbol_name, I"!give")) bip = GIVE_BIP;
	if (Str::eq(symb->symbol_name, I"!take")) bip = TAKE_BIP;
	if (Str::eq(symb->symbol_name, I"!move")) bip = MOVE_BIP;
	if (Str::eq(symb->symbol_name, I"!remove")) bip = REMOVE_BIP;
	if (Str::eq(symb->symbol_name, I"!quit")) bip = QUIT_BIP;
	if (Str::eq(symb->symbol_name, I"!restore")) bip = RESTORE_BIP;
	if (Str::eq(symb->symbol_name, I"!spaces")) bip = SPACES_BIP;
	if (Str::eq(symb->symbol_name, I"!break")) bip = BREAK_BIP;
	if (Str::eq(symb->symbol_name, I"!continue")) bip = CONTINUE_BIP;
	if (Str::eq(symb->symbol_name, I"!font")) bip = FONT_BIP;
	if (Str::eq(symb->symbol_name, I"!styleroman")) bip = STYLEROMAN_BIP;
	if (Str::eq(symb->symbol_name, I"!stylebold")) bip = STYLEBOLD_BIP;
	if (Str::eq(symb->symbol_name, I"!styleunderline")) bip = STYLEUNDERLINE_BIP;
	if (Str::eq(symb->symbol_name, I"!stylereverse")) bip = STYLEREVERSE_BIP;
	if (Str::eq(symb->symbol_name, I"!print")) bip = PRINT_BIP;
	if (Str::eq(symb->symbol_name, I"!printret")) bip = PRINTRET_BIP;
	if (Str::eq(symb->symbol_name, I"!printchar")) bip = PRINTCHAR_BIP;
	if (Str::eq(symb->symbol_name, I"!printname")) bip = PRINTNAME_BIP;
	if (Str::eq(symb->symbol_name, I"!printobj")) bip = PRINTOBJ_BIP;
	if (Str::eq(symb->symbol_name, I"!printproperty")) bip = PRINTPROPERTY_BIP;
	if (Str::eq(symb->symbol_name, I"!printnumber")) bip = PRINTNUMBER_BIP;
	if (Str::eq(symb->symbol_name, I"!printaddress")) bip = PRINTADDRESS_BIP;
	if (Str::eq(symb->symbol_name, I"!printstring")) bip = PRINTSTRING_BIP;
	if (Str::eq(symb->symbol_name, I"!printnlnumber")) bip = PRINTNLNUMBER_BIP;
	if (Str::eq(symb->symbol_name, I"!printdef")) bip = PRINTDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!printcdef")) bip = PRINTCDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!printindef")) bip = PRINTINDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!printcindef")) bip = PRINTCINDEF_BIP;
	if (Str::eq(symb->symbol_name, I"!box")) bip = BOX_BIP;
	if (Str::eq(symb->symbol_name, I"!push")) bip = PUSH_BIP;
	if (Str::eq(symb->symbol_name, I"!pull")) bip = PULL_BIP;
	if (Str::eq(symb->symbol_name, I"!preincrement")) bip = PREINCREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!postincrement")) bip = POSTINCREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!predecrement")) bip = PREDECREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!postdecrement")) bip = POSTDECREMENT_BIP;
	if (Str::eq(symb->symbol_name, I"!store")) bip = STORE_BIP;
	if (Str::eq(symb->symbol_name, I"!setbit")) bip = SETBIT_BIP;
	if (Str::eq(symb->symbol_name, I"!clearbit")) bip = CLEARBIT_BIP;
	if (Str::eq(symb->symbol_name, I"!if")) bip = IF_BIP;
	if (Str::eq(symb->symbol_name, I"!ifdebug")) bip = IFDEBUG_BIP;
	if (Str::eq(symb->symbol_name, I"!ifstrict")) bip = IFSTRICT_BIP;
	if (Str::eq(symb->symbol_name, I"!ifelse")) bip = IFELSE_BIP;
	if (Str::eq(symb->symbol_name, I"!while")) bip = WHILE_BIP;
	if (Str::eq(symb->symbol_name, I"!do")) bip = DO_BIP;
	if (Str::eq(symb->symbol_name, I"!for")) bip = FOR_BIP;
	if (Str::eq(symb->symbol_name, I"!objectloop")) bip = OBJECTLOOP_BIP;
	if (Str::eq(symb->symbol_name, I"!objectloopx")) bip = OBJECTLOOPX_BIP;
	if (Str::eq(symb->symbol_name, I"!lookup")) bip = LOOKUP_BIP;
	if (Str::eq(symb->symbol_name, I"!lookupbyte")) bip = LOOKUPBYTE_BIP;
	if (Str::eq(symb->symbol_name, I"!lookupref")) bip = LOOKUPREF_BIP;
	if (Str::eq(symb->symbol_name, I"!loop")) bip = LOOP_BIP;
	if (Str::eq(symb->symbol_name, I"!switch")) bip = SWITCH_BIP;
	if (Str::eq(symb->symbol_name, I"!case")) bip = CASE_BIP;
	if (Str::eq(symb->symbol_name, I"!default")) bip = DEFAULT_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect0v")) bip = INDIRECT0V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect1v")) bip = INDIRECT1V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect2v")) bip = INDIRECT2V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect3v")) bip = INDIRECT3V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect4v")) bip = INDIRECT4V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect5v")) bip = INDIRECT5V_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect0")) bip = INDIRECT0_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect1")) bip = INDIRECT1_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect2")) bip = INDIRECT2_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect3")) bip = INDIRECT3_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect4")) bip = INDIRECT4_BIP;
	if (Str::eq(symb->symbol_name, I"!indirect5")) bip = INDIRECT5_BIP;
	if (Str::eq(symb->symbol_name, I"!message0")) bip = MESSAGE0_BIP;
	if (Str::eq(symb->symbol_name, I"!message1")) bip = MESSAGE1_BIP;
	if (Str::eq(symb->symbol_name, I"!message2")) bip = MESSAGE2_BIP;
	if (Str::eq(symb->symbol_name, I"!message3")) bip = MESSAGE3_BIP;
	if (Str::eq(symb->symbol_name, I"!callmessage0")) bip = CALLMESSAGE0_BIP;
	if (Str::eq(symb->symbol_name, I"!callmessage1")) bip = CALLMESSAGE1_BIP;
	if (Str::eq(symb->symbol_name, I"!callmessage2")) bip = CALLMESSAGE2_BIP;
	if (Str::eq(symb->symbol_name, I"!callmessage3")) bip = CALLMESSAGE3_BIP;
	if (Str::eq(symb->symbol_name, I"!propertyaddress")) bip = PROPERTYADDRESS_BIP;
	if (Str::eq(symb->symbol_name, I"!propertylength")) bip = PROPERTYLENGTH_BIP;
	if (Str::eq(symb->symbol_name, I"!provides")) bip = PROVIDES_BIP;
	if (Str::eq(symb->symbol_name, I"!propertyvalue")) bip = PROPERTYVALUE_BIP;
	if (Str::eq(symb->symbol_name, I"!read")) bip = READ_BIP;
	if (Str::eq(symb->symbol_name, I"!inversion")) bip = INVERSION_BIP;
	if (bip != 0) {
		Inter::Symbols::annotate_i(symb, BIP_CODE_IANN, bip);
		return bip;
	}
	return 0;
}
