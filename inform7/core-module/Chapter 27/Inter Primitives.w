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
void Primitives::emit(void) {
	Emit::primitive(I"!font", I"val -> void", &font_interp);
	Emit::primitive(I"!stylebold", I"void -> void", &stylebold_interp);
	Emit::primitive(I"!styleunderline", I"void -> void", &styleunderline_interp);
	Emit::primitive(I"!styleroman", I"void -> void", &styleroman_interp);
	Emit::primitive(I"!print", I"val -> void", &print_interp);
	Emit::primitive(I"!printchar", I"val -> void", &printchar_interp);
	Emit::primitive(I"!printname", I"val -> void", &printname_interp);
	Emit::primitive(I"!printnumber", I"val -> void", &printnumber_interp);
	Emit::primitive(I"!printaddress", I"val -> void", &printaddress_interp);
	Emit::primitive(I"!printstring", I"val -> void", &printstring_interp);
	Emit::primitive(I"!printnlnumber", I"val -> void", &printnlnumber_interp);
	Emit::primitive(I"!printdef", I"val -> void", &printdef_interp);
	Emit::primitive(I"!printcdef", I"val -> void", &printcdef_interp);
	Emit::primitive(I"!printindef", I"val -> void", &printindef_interp);
	Emit::primitive(I"!printcindef", I"val -> void", &printcindef_interp);
	Emit::primitive(I"!box", I"val -> void", &box_interp);
	Emit::primitive(I"!push", I"val -> void", &push_interp);
	Emit::primitive(I"!pull", I"ref -> void", &pull_interp);
	Emit::primitive(I"!postincrement", I"ref -> val", &postincrement_interp);
	Emit::primitive(I"!preincrement", I"ref -> val", &preincrement_interp);
	Emit::primitive(I"!postdecrement", I"ref -> val", &postdecrement_interp);
	Emit::primitive(I"!predecrement", I"ref -> val", &predecrement_interp);
	Emit::primitive(I"!return", I"val -> void", &return_interp);
	Emit::primitive(I"!quit", I"void -> void", &quit_interp);
	Emit::primitive(I"!break", I"void -> void", &break_interp);
	Emit::primitive(I"!continue", I"void -> void", &continue_interp);
	Emit::primitive(I"!jump", I"lab -> void", &jump_interp);
	Emit::primitive(I"!move", I"val val -> void", &move_interp);
	Emit::primitive(I"!give", I"val val -> void", &give_interp);
	Emit::primitive(I"!take", I"val val -> void", &take_interp);
	Emit::primitive(I"!store", I"ref val -> val", &store_interp);
	Emit::primitive(I"!setbit", I"ref val -> void", &setbit_interp);
	Emit::primitive(I"!clearbit", I"ref val -> void", &clearbit_interp);
	Emit::primitive(I"!modulo", I"val val -> val", &modulo_interp);
	Emit::primitive(I"!random", I"val -> val", &random_interp);
	Emit::primitive(I"!lookup", I"val val -> val", &lookup_interp);
	Emit::primitive(I"!lookupbyte", I"val val -> val", &lookupbyte_interp);
	Emit::primitive(I"!lookupref", I"val val -> ref", &lookupref_interp);
	Emit::primitive(I"!not", I"val -> val", &not_interp);
	Emit::primitive(I"!and", I"val val -> val", &and_interp);
	Emit::primitive(I"!or", I"val val -> val", &or_interp);
	Emit::primitive(I"!bitwiseand", I"val val -> val", &bitwiseand_interp);
	Emit::primitive(I"!bitwiseor", I"val val -> val", &bitwiseor_interp);
	Emit::primitive(I"!bitwisenot", I"val -> val", &bitwisenot_interp);
	Emit::primitive(I"!eq", I"val val -> val", &eq_interp);
	Emit::primitive(I"!ne", I"val val -> val", &ne_interp);
	Emit::primitive(I"!gt", I"val val -> val", &gt_interp);
	Emit::primitive(I"!ge", I"val val -> val", &ge_interp);
	Emit::primitive(I"!lt", I"val val -> val", &lt_interp);
	Emit::primitive(I"!le", I"val val -> val", &le_interp);
	Emit::primitive(I"!has", I"val val -> val", &has_interp);
	Emit::primitive(I"!hasnt", I"val val -> val", &hasnt_interp);
	Emit::primitive(I"!in", I"val val -> val", &in_interp);
	Emit::primitive(I"!ofclass", I"val val -> val", &ofclass_interp);
	Emit::primitive(I"!sequential", I"val val -> val", &sequential_interp);
	Emit::primitive(I"!ternarysequential", I"val val val -> val", &ternarysequential_interp);
	Emit::primitive(I"!plus", I"val val -> val", &plus_interp);
	Emit::primitive(I"!minus", I"val val -> val", &minus_interp);
	Emit::primitive(I"!unaryminus", I"val -> val", &unaryminus_interp);
	Emit::primitive(I"!times", I"val val -> val", &times_interp);
	Emit::primitive(I"!divide", I"val val -> val", &divide_interp);
	Emit::primitive(I"!if", I"val code -> void", &if_interp);
	Emit::primitive(I"!ifdebug", I"code -> void", &ifdebug_interp);
	Emit::primitive(I"!ifelse", I"val code code -> void", &ifelse_interp);
	Emit::primitive(I"!while", I"val code -> void", &while_interp);
	Emit::primitive(I"!for", I"val val val code -> void", &for_interp);
	Emit::primitive(I"!objectloop", I"ref val val code -> void", &objectloop_interp);
	Emit::primitive(I"!objectloopx", I"ref val code -> void", &objectloopx_interp);
	Emit::primitive(I"!switch", I"val code -> void", &switch_interp);
	Emit::primitive(I"!case", I"val code -> void", &case_interp);
	Emit::primitive(I"!default", I"code -> void", &default_interp);
	Emit::primitive(I"!indirect0v", I"val -> void", &indirect0v_interp);
	Emit::primitive(I"!indirect1v", I"val val -> void", &indirect1v_interp);
	Emit::primitive(I"!indirect2v", I"val val val -> void", &indirect2v_interp);
	Emit::primitive(I"!indirect3v", I"val val val val -> void", &indirect3v_interp);
	Emit::primitive(I"!indirect4v", I"val val val val val -> void", &indirect4v_interp);
	Emit::primitive(I"!indirect5v", I"val val val val val val -> void", &indirect5v_interp);
	Emit::primitive(I"!indirect0", I"val -> val", &indirect0_interp);
	Emit::primitive(I"!indirect1", I"val val -> val", &indirect1_interp);
	Emit::primitive(I"!indirect2", I"val val val -> val", &indirect2_interp);
	Emit::primitive(I"!indirect3", I"val val val val -> val", &indirect3_interp);
	Emit::primitive(I"!indirect4", I"val val val val val -> val", &indirect4_interp);
	Emit::primitive(I"!indirect5", I"val val val val val val -> val", &indirect5_interp);
	Emit::primitive(I"!propertyaddress", I"val val -> val", &propertyaddress_interp);
	Emit::primitive(I"!propertylength", I"val val -> val", &propertylength_interp);
	Emit::primitive(I"!provides", I"val val -> val", &provides_interp);
	Emit::primitive(I"!propertyvalue", I"val val -> val", &propertyvalue_interp);
	Emit::primitive(I"!notin", I"val val -> val", &notin_interp);
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
