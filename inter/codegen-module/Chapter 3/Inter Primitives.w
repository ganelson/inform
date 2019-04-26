[Primitives::] Inter Primitives.

@

= (early code)
inter_symbol *return_interp = NULL;
inter_symbol *jump_interp = NULL;
inter_symbol *move_interp = NULL;
inter_symbol *give_interp = NULL;
inter_symbol *take_interp = NULL;
inter_symbol *break_interp = NULL;
inter_symbol *continue_interp = NULL;
inter_symbol *quit_interp = NULL;
inter_symbol *modulo_interp = NULL;
inter_symbol *random_interp = NULL;
inter_symbol *not_interp = NULL;
inter_symbol *and_interp = NULL;
inter_symbol *or_interp = NULL;
inter_symbol *bitwiseand_interp = NULL;
inter_symbol *bitwiseor_interp = NULL;
inter_symbol *bitwisenot_interp = NULL;
inter_symbol *eq_interp = NULL;
inter_symbol *ne_interp = NULL;
inter_symbol *gt_interp = NULL;
inter_symbol *ge_interp = NULL;
inter_symbol *lt_interp = NULL;
inter_symbol *le_interp = NULL;
inter_symbol *in_interp = NULL;
inter_symbol *has_interp = NULL;
inter_symbol *hasnt_interp = NULL;
inter_symbol *ofclass_interp = NULL;
inter_symbol *sequential_interp = NULL;
inter_symbol *ternarysequential_interp = NULL;
inter_symbol *plus_interp = NULL;
inter_symbol *minus_interp = NULL;
inter_symbol *unaryminus_interp = NULL;
inter_symbol *times_interp = NULL;
inter_symbol *divide_interp = NULL;
inter_symbol *stylebold_interp = NULL;
inter_symbol *font_interp = NULL;
inter_symbol *styleroman_interp = NULL;
inter_symbol *styleunderline_interp = NULL;
inter_symbol *print_interp = NULL;
inter_symbol *printchar_interp = NULL;
inter_symbol *printname_interp = NULL;
inter_symbol *printnumber_interp = NULL;
inter_symbol *printnlnumber_interp = NULL;
inter_symbol *printcindef_interp = NULL;
inter_symbol *printindef_interp = NULL;
inter_symbol *printcdef_interp = NULL;
inter_symbol *printdef_interp = NULL;
inter_symbol *printaddress_interp = NULL;
inter_symbol *printstring_interp = NULL;
inter_symbol *box_interp = NULL;
inter_symbol *push_interp = NULL;
inter_symbol *pull_interp = NULL;
inter_symbol *preincrement_interp = NULL;
inter_symbol *postincrement_interp = NULL;
inter_symbol *predecrement_interp = NULL;
inter_symbol *postdecrement_interp = NULL;
inter_symbol *lookup_interp = NULL;
inter_symbol *lookupbyte_interp = NULL;
inter_symbol *lookupref_interp = NULL;
inter_symbol *store_interp = NULL;
inter_symbol *if_interp = NULL;
inter_symbol *ifdebug_interp = NULL;
inter_symbol *ifelse_interp = NULL;
inter_symbol *while_interp = NULL;
inter_symbol *for_interp = NULL;
inter_symbol *objectloop_interp = NULL;
inter_symbol *objectloopx_interp = NULL;
inter_symbol *switch_interp = NULL;
inter_symbol *case_interp = NULL;
inter_symbol *default_interp = NULL;
inter_symbol *setbit_interp = NULL;
inter_symbol *clearbit_interp = NULL;
inter_symbol *indirect0v_interp = NULL;
inter_symbol *indirect1v_interp = NULL;
inter_symbol *indirect2v_interp = NULL;
inter_symbol *indirect3v_interp = NULL;
inter_symbol *indirect4v_interp = NULL;
inter_symbol *indirect5v_interp = NULL;
inter_symbol *indirect0_interp = NULL;
inter_symbol *indirect1_interp = NULL;
inter_symbol *indirect2_interp = NULL;
inter_symbol *indirect3_interp = NULL;
inter_symbol *indirect4_interp = NULL;
inter_symbol *indirect5_interp = NULL;
inter_symbol *propertyaddress_interp = NULL;
inter_symbol *propertylength_interp = NULL;
inter_symbol *provides_interp = NULL;
inter_symbol *propertyvalue_interp = NULL;
inter_symbol *notin_interp = NULL;

@ =
void Primitives::emit(inter_repository *I, inter_reading_state *IRS) {
	Primitives::emit_one(I, IRS, I"!font", I"val -> void", &font_interp);
	Primitives::emit_one(I, IRS, I"!stylebold", I"void -> void", &stylebold_interp);
	Primitives::emit_one(I, IRS, I"!styleunderline", I"void -> void", &styleunderline_interp);
	Primitives::emit_one(I, IRS, I"!styleroman", I"void -> void", &styleroman_interp);
	Primitives::emit_one(I, IRS, I"!print", I"val -> void", &print_interp);
	Primitives::emit_one(I, IRS, I"!printchar", I"val -> void", &printchar_interp);
	Primitives::emit_one(I, IRS, I"!printname", I"val -> void", &printname_interp);
	Primitives::emit_one(I, IRS, I"!printnumber", I"val -> void", &printnumber_interp);
	Primitives::emit_one(I, IRS, I"!printaddress", I"val -> void", &printaddress_interp);
	Primitives::emit_one(I, IRS, I"!printstring", I"val -> void", &printstring_interp);
	Primitives::emit_one(I, IRS, I"!printnlnumber", I"val -> void", &printnlnumber_interp);
	Primitives::emit_one(I, IRS, I"!printdef", I"val -> void", &printdef_interp);
	Primitives::emit_one(I, IRS, I"!printcdef", I"val -> void", &printcdef_interp);
	Primitives::emit_one(I, IRS, I"!printindef", I"val -> void", &printindef_interp);
	Primitives::emit_one(I, IRS, I"!printcindef", I"val -> void", &printcindef_interp);
	Primitives::emit_one(I, IRS, I"!box", I"val -> void", &box_interp);
	Primitives::emit_one(I, IRS, I"!push", I"val -> void", &push_interp);
	Primitives::emit_one(I, IRS, I"!pull", I"ref -> void", &pull_interp);
	Primitives::emit_one(I, IRS, I"!postincrement", I"ref -> val", &postincrement_interp);
	Primitives::emit_one(I, IRS, I"!preincrement", I"ref -> val", &preincrement_interp);
	Primitives::emit_one(I, IRS, I"!postdecrement", I"ref -> val", &postdecrement_interp);
	Primitives::emit_one(I, IRS, I"!predecrement", I"ref -> val", &predecrement_interp);
	Primitives::emit_one(I, IRS, I"!return", I"val -> void", &return_interp);
	Primitives::emit_one(I, IRS, I"!quit", I"void -> void", &quit_interp);
	Primitives::emit_one(I, IRS, I"!break", I"void -> void", &break_interp);
	Primitives::emit_one(I, IRS, I"!continue", I"void -> void", &continue_interp);
	Primitives::emit_one(I, IRS, I"!jump", I"lab -> void", &jump_interp);
	Primitives::emit_one(I, IRS, I"!move", I"val val -> void", &move_interp);
	Primitives::emit_one(I, IRS, I"!give", I"val val -> void", &give_interp);
	Primitives::emit_one(I, IRS, I"!take", I"val val -> void", &take_interp);
	Primitives::emit_one(I, IRS, I"!store", I"ref val -> val", &store_interp);
	Primitives::emit_one(I, IRS, I"!setbit", I"ref val -> void", &setbit_interp);
	Primitives::emit_one(I, IRS, I"!clearbit", I"ref val -> void", &clearbit_interp);
	Primitives::emit_one(I, IRS, I"!modulo", I"val val -> val", &modulo_interp);
	Primitives::emit_one(I, IRS, I"!random", I"val -> val", &random_interp);
	Primitives::emit_one(I, IRS, I"!lookup", I"val val -> val", &lookup_interp);
	Primitives::emit_one(I, IRS, I"!lookupbyte", I"val val -> val", &lookupbyte_interp);
	Primitives::emit_one(I, IRS, I"!lookupref", I"val val -> ref", &lookupref_interp);
	Primitives::emit_one(I, IRS, I"!not", I"val -> val", &not_interp);
	Primitives::emit_one(I, IRS, I"!and", I"val val -> val", &and_interp);
	Primitives::emit_one(I, IRS, I"!or", I"val val -> val", &or_interp);
	Primitives::emit_one(I, IRS, I"!bitwiseand", I"val val -> val", &bitwiseand_interp);
	Primitives::emit_one(I, IRS, I"!bitwiseor", I"val val -> val", &bitwiseor_interp);
	Primitives::emit_one(I, IRS, I"!bitwisenot", I"val -> val", &bitwisenot_interp);
	Primitives::emit_one(I, IRS, I"!eq", I"val val -> val", &eq_interp);
	Primitives::emit_one(I, IRS, I"!ne", I"val val -> val", &ne_interp);
	Primitives::emit_one(I, IRS, I"!gt", I"val val -> val", &gt_interp);
	Primitives::emit_one(I, IRS, I"!ge", I"val val -> val", &ge_interp);
	Primitives::emit_one(I, IRS, I"!lt", I"val val -> val", &lt_interp);
	Primitives::emit_one(I, IRS, I"!le", I"val val -> val", &le_interp);
	Primitives::emit_one(I, IRS, I"!has", I"val val -> val", &has_interp);
	Primitives::emit_one(I, IRS, I"!hasnt", I"val val -> val", &hasnt_interp);
	Primitives::emit_one(I, IRS, I"!in", I"val val -> val", &in_interp);
	Primitives::emit_one(I, IRS, I"!ofclass", I"val val -> val", &ofclass_interp);
	Primitives::emit_one(I, IRS, I"!sequential", I"val val -> val", &sequential_interp);
	Primitives::emit_one(I, IRS, I"!ternarysequential", I"val val val -> val", &ternarysequential_interp);
	Primitives::emit_one(I, IRS, I"!plus", I"val val -> val", &plus_interp);
	Primitives::emit_one(I, IRS, I"!minus", I"val val -> val", &minus_interp);
	Primitives::emit_one(I, IRS, I"!unaryminus", I"val -> val", &unaryminus_interp);
	Primitives::emit_one(I, IRS, I"!times", I"val val -> val", &times_interp);
	Primitives::emit_one(I, IRS, I"!divide", I"val val -> val", &divide_interp);
	Primitives::emit_one(I, IRS, I"!if", I"val code -> void", &if_interp);
	Primitives::emit_one(I, IRS, I"!ifdebug", I"code -> void", &ifdebug_interp);
	Primitives::emit_one(I, IRS, I"!ifelse", I"val code code -> void", &ifelse_interp);
	Primitives::emit_one(I, IRS, I"!while", I"val code -> void", &while_interp);
	Primitives::emit_one(I, IRS, I"!for", I"val val val code -> void", &for_interp);
	Primitives::emit_one(I, IRS, I"!objectloop", I"ref val val code -> void", &objectloop_interp);
	Primitives::emit_one(I, IRS, I"!objectloopx", I"ref val code -> void", &objectloopx_interp);
	Primitives::emit_one(I, IRS, I"!switch", I"val code -> void", &switch_interp);
	Primitives::emit_one(I, IRS, I"!case", I"val code -> void", &case_interp);
	Primitives::emit_one(I, IRS, I"!default", I"code -> void", &default_interp);
	Primitives::emit_one(I, IRS, I"!indirect0v", I"val -> void", &indirect0v_interp);
	Primitives::emit_one(I, IRS, I"!indirect1v", I"val val -> void", &indirect1v_interp);
	Primitives::emit_one(I, IRS, I"!indirect2v", I"val val val -> void", &indirect2v_interp);
	Primitives::emit_one(I, IRS, I"!indirect3v", I"val val val val -> void", &indirect3v_interp);
	Primitives::emit_one(I, IRS, I"!indirect4v", I"val val val val val -> void", &indirect4v_interp);
	Primitives::emit_one(I, IRS, I"!indirect5v", I"val val val val val val -> void", &indirect5v_interp);
	Primitives::emit_one(I, IRS, I"!indirect0", I"val -> val", &indirect0_interp);
	Primitives::emit_one(I, IRS, I"!indirect1", I"val val -> val", &indirect1_interp);
	Primitives::emit_one(I, IRS, I"!indirect2", I"val val val -> val", &indirect2_interp);
	Primitives::emit_one(I, IRS, I"!indirect3", I"val val val val -> val", &indirect3_interp);
	Primitives::emit_one(I, IRS, I"!indirect4", I"val val val val val -> val", &indirect4_interp);
	Primitives::emit_one(I, IRS, I"!indirect5", I"val val val val val val -> val", &indirect5_interp);
	Primitives::emit_one(I, IRS, I"!propertyaddress", I"val val -> val", &propertyaddress_interp);
	Primitives::emit_one(I, IRS, I"!propertylength", I"val val -> val", &propertylength_interp);
	Primitives::emit_one(I, IRS, I"!provides", I"val val -> val", &provides_interp);
	Primitives::emit_one(I, IRS, I"!propertyvalue", I"val val -> val", &propertyvalue_interp);
	Primitives::emit_one(I, IRS, I"!notin", I"val val -> val", &notin_interp);
}

void Primitives::emit_one(inter_repository *I, inter_reading_state *IRS, text_stream *prim, text_stream *category, inter_symbol **to) {
	if (to == NULL) internal_error("no symbol");
	TEMPORARY_TEXT(prim_command);
	WRITE_TO(prim_command, "primitive %S %S", prim, category);
	CodeGen::Link::guard(Inter::Defn::read_construct_text(prim_command, NULL, IRS));
	inter_error_message *E = NULL;
	*to = Inter::Textual::find_symbol(I, NULL, Inter::get_global_symbols(I), prim, PRIMITIVE_IST, &E);
	CodeGen::Link::guard(E);
	DISCARD_TEXT(prim_command);
}

int Primitives::is_indirect_interp(inter_symbol *s) {
	if (s == indirect0_interp) return TRUE;
	if (s == indirect1_interp) return TRUE;
	if (s == indirect2_interp) return TRUE;
	if (s == indirect3_interp) return TRUE;
	if (s == indirect4_interp) return TRUE;
	if (s == indirect5_interp) return TRUE;
	return FALSE;
}

inter_symbol *Primitives::indirect_interp(int arity) {
	switch (arity) {
		case 0: return indirect0_interp;
		case 1: return indirect1_interp;
		case 2: return indirect2_interp;
		case 3: return indirect3_interp;
		case 4: return indirect4_interp;
		case 5: return indirect5_interp;
		default: internal_error("indirect function call with too many arguments");
	}
	return NULL;
}

int Primitives::is_indirectv_interp(inter_symbol *s) {
	if (s == indirect0v_interp) return TRUE;
	if (s == indirect1v_interp) return TRUE;
	if (s == indirect2v_interp) return TRUE;
	if (s == indirect3v_interp) return TRUE;
	if (s == indirect4v_interp) return TRUE;
	if (s == indirect5v_interp) return TRUE;
	return FALSE;
}

inter_symbol *Primitives::indirectv_interp(int arity) {
	switch (arity) {
		case 0: return indirect0v_interp;
		case 1: return indirect1v_interp;
		case 2: return indirect2v_interp;
		case 3: return indirect3v_interp;
		case 4: return indirect4v_interp;
		case 5: return indirect5v_interp;
		default: internal_error("indirectv function call with too many arguments");
	}
	return NULL;
}

@

@e NOT_BIP from 1
@e AND_BIP
@e OR_BIP
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
@e GIVE_BIP
@e TAKE_BIP
@e JUMP_BIP
@e QUIT_BIP
@e BREAK_BIP
@e CONTINUE_BIP
@e STYLEROMAN_BIP
@e FONT_BIP
@e STYLEBOLD_BIP
@e STYLEUNDERLINE_BIP
@e PRINT_BIP
@e PRINTCHAR_BIP
@e PRINTNAME_BIP
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
@e IFELSE_BIP
@e WHILE_BIP
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
@e PROPERTYADDRESS_BIP
@e PROPERTYLENGTH_BIP
@e PROVIDES_BIP
@e PROPERTYVALUE_BIP

=
inter_t Primitives::to_bip(inter_repository *I, inter_symbol *symb) {
	if (symb == NULL) return 0;
	int B = Inter::Symbols::read_annotation(symb, BIP_CODE_IANN);
	inter_t bip = (B > 0)?((inter_t) B):0;
	if (bip != 0) return bip;
	if (Str::eq(symb->symbol_name, I"!not")) bip = NOT_BIP;
	if (Str::eq(symb->symbol_name, I"!and")) bip = AND_BIP;
	if (Str::eq(symb->symbol_name, I"!or")) bip = OR_BIP;
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
	if (Str::eq(symb->symbol_name, I"!quit")) bip = QUIT_BIP;
	if (Str::eq(symb->symbol_name, I"!break")) bip = BREAK_BIP;
	if (Str::eq(symb->symbol_name, I"!continue")) bip = CONTINUE_BIP;
	if (Str::eq(symb->symbol_name, I"!font")) bip = FONT_BIP;
	if (Str::eq(symb->symbol_name, I"!styleroman")) bip = STYLEROMAN_BIP;
	if (Str::eq(symb->symbol_name, I"!stylebold")) bip = STYLEBOLD_BIP;
	if (Str::eq(symb->symbol_name, I"!styleunderline")) bip = STYLEUNDERLINE_BIP;
	if (Str::eq(symb->symbol_name, I"!print")) bip = PRINT_BIP;
	if (Str::eq(symb->symbol_name, I"!printchar")) bip = PRINTCHAR_BIP;
	if (Str::eq(symb->symbol_name, I"!printname")) bip = PRINTNAME_BIP;
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
	if (Str::eq(symb->symbol_name, I"!ifelse")) bip = IFELSE_BIP;
	if (Str::eq(symb->symbol_name, I"!while")) bip = WHILE_BIP;
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
	if (Str::eq(symb->symbol_name, I"!propertyaddress")) bip = PROPERTYADDRESS_BIP;
	if (Str::eq(symb->symbol_name, I"!propertylength")) bip = PROPERTYLENGTH_BIP;
	if (Str::eq(symb->symbol_name, I"!provides")) bip = PROVIDES_BIP;
	if (Str::eq(symb->symbol_name, I"!propertyvalue")) bip = PROPERTYVALUE_BIP;
	if (bip != 0) {
		Inter::Symbols::annotate_i(I, symb, BIP_CODE_IANN, bip);
		return bip;
	}
	return 0;
}
