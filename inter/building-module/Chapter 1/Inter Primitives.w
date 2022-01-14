[Primitives::] Inter Primitives.

@h The standard Inform 7 instruction set.
Metadata on the primitives used by Inter in the Inform tool-set is stored as
an array |standard_inform7_primitives| of the following records:

=
typedef struct inform7_primitive {
	inter_ti BIP;
	char *name_c;
	char *signature_c;
	struct text_stream *name;
	struct text_stream *signature;
} inform7_primitive;

@ Each different primitive has a unique BIP number. (The origins of the term
BIP are now lost, though the I and the P presumably once stood for "Inform"
and "primitive".) BIPs count upwards contiguously from 1.

The point of BIPs is simply that it would be too slow to index primitives only
by their instruction names, because even with all the hashing in the world,
there would have to be string comparisons.

@d MAX_BIPS 100

@e PLUS_BIP from 1
@e MINUS_BIP
@e UNARYMINUS_BIP
@e TIMES_BIP
@e DIVIDE_BIP
@e MODULO_BIP
@e BITWISEAND_BIP
@e BITWISEOR_BIP
@e BITWISENOT_BIP
@e SEQUENTIAL_BIP
@e TERNARYSEQUENTIAL_BIP
@e RANDOM_BIP

@e STORE_BIP
@e PREINCREMENT_BIP
@e POSTINCREMENT_BIP
@e PREDECREMENT_BIP
@e POSTDECREMENT_BIP
@e SETBIT_BIP
@e CLEARBIT_BIP

@e PUSH_BIP
@e PULL_BIP
@e LOOKUP_BIP
@e LOOKUPBYTE_BIP
@e PROPERTYARRAY_BIP
@e PROPERTYLENGTH_BIP
@e PROPERTYEXISTS_BIP
@e PROPERTYVALUE_BIP

@e MOVE_BIP
@e REMOVE_BIP
@e CHILD_BIP
@e CHILDREN_BIP
@e SIBLING_BIP
@e PARENT_BIP
@e METACLASS_BIP

@e NOT_BIP
@e AND_BIP
@e OR_BIP
@e EQ_BIP
@e NE_BIP
@e GT_BIP
@e GE_BIP
@e LT_BIP
@e LE_BIP
@e OFCLASS_BIP
@e IN_BIP
@e NOTIN_BIP
@e ALTERNATIVE_BIP

@e FONT_BIP
@e STYLE_BIP
@e PRINT_BIP
@e PRINTNL_BIP
@e PRINTCHAR_BIP
@e PRINTOBJ_BIP
@e PRINTNUMBER_BIP
@e PRINTDWORD_BIP
@e PRINTSTRING_BIP
@e BOX_BIP
@e SPACES_BIP

@e IF_BIP
@e IFDEBUG_BIP
@e IFSTRICT_BIP
@e IFELSE_BIP
@e WHILE_BIP
@e DO_BIP
@e FOR_BIP
@e OBJECTLOOP_BIP
@e OBJECTLOOPX_BIP
@e BREAK_BIP
@e CONTINUE_BIP
@e SWITCH_BIP
@e CASE_BIP
@e ALTERNATIVECASE_BIP
@e DEFAULT_BIP
@e RETURN_BIP
@e JUMP_BIP
@e QUIT_BIP
@e RESTORE_BIP

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
@e EXTERNALCALL_BIP

@ And here is the array of metadata. It's tiresome to have to include the null
fields here, which is done only because text_stream literals |I"like this"|
cannot be compiled in a constant context by the |clang| C compiler. So the
names and signatures of the primitives are compiled as |char *| literals instead,
and converted on first use at runtime.

It is essential that the sequence of rows below is the same as the sequence of
enumerations above; but //Primitives::prepare_standard_set_array// checks this
at runtime and throws an error if not.

=
inform7_primitive standard_inform7_primitives[] = {
	{ PLUS_BIP,              "!plus",              "val val -> val",                  NULL, NULL },
	{ MINUS_BIP,             "!minus",             "val val -> val",                  NULL, NULL },
	{ UNARYMINUS_BIP,        "!unaryminus",        "val -> val",                      NULL, NULL },
	{ TIMES_BIP,             "!times",             "val val -> val",                  NULL, NULL },
	{ DIVIDE_BIP,            "!divide",            "val val -> val",                  NULL, NULL },
	{ MODULO_BIP,            "!modulo",            "val val -> val",                  NULL, NULL },
	{ BITWISEAND_BIP,        "!bitwiseand",        "val val -> val",                  NULL, NULL },
	{ BITWISEOR_BIP,         "!bitwiseor",         "val val -> val",                  NULL, NULL },
	{ BITWISENOT_BIP,        "!bitwisenot",        "val -> val",                      NULL, NULL },
	{ SEQUENTIAL_BIP,        "!sequential",        "val val -> val",                  NULL, NULL },
	{ TERNARYSEQUENTIAL_BIP, "!ternarysequential", "val val val -> val",              NULL, NULL },
	{ RANDOM_BIP,            "!random",            "val -> val",                      NULL, NULL },

	{ STORE_BIP,             "!store",             "ref val -> val",                  NULL, NULL },
	{ PREINCREMENT_BIP,      "!preincrement",      "ref -> val",                      NULL, NULL },
	{ POSTINCREMENT_BIP,     "!postincrement",     "ref -> val",                      NULL, NULL },
	{ PREDECREMENT_BIP,      "!predecrement",      "ref -> val",                      NULL, NULL },
	{ POSTDECREMENT_BIP,     "!postdecrement",     "ref -> val",                      NULL, NULL },
	{ SETBIT_BIP,            "!setbit",            "ref val -> void",                 NULL, NULL },
	{ CLEARBIT_BIP,          "!clearbit",          "ref val -> void",                 NULL, NULL },

	{ PUSH_BIP,              "!push",              "val -> void",                     NULL, NULL },
	{ PULL_BIP,              "!pull",              "ref -> void",                     NULL, NULL },
	{ LOOKUP_BIP,            "!lookup",            "val val -> val",                  NULL, NULL },
	{ LOOKUPBYTE_BIP,        "!lookupbyte",        "val val -> val",                  NULL, NULL },
	{ PROPERTYARRAY_BIP,     "!propertyarray",     "val val val -> val",              NULL, NULL },
	{ PROPERTYLENGTH_BIP,    "!propertylength",    "val val val -> val",              NULL, NULL },
	{ PROPERTYEXISTS_BIP,    "!propertyexists",    "val val val -> val",              NULL, NULL },
	{ PROPERTYVALUE_BIP,     "!propertyvalue",     "val val val -> val",              NULL, NULL },

	{ MOVE_BIP,              "!move",              "val val -> void",                 NULL, NULL },
	{ REMOVE_BIP,            "!remove",            "val -> void",                     NULL, NULL },
	{ CHILD_BIP,             "!child",             "val -> val",                      NULL, NULL },
	{ CHILDREN_BIP,          "!children",          "val -> val",                      NULL, NULL },
	{ SIBLING_BIP,           "!sibling",           "val -> val",                      NULL, NULL },
	{ PARENT_BIP,            "!parent",            "val -> val",                      NULL, NULL },
	{ METACLASS_BIP,         "!metaclass",         "val -> val",                      NULL, NULL },

	{ NOT_BIP,               "!not",               "val -> val",                      NULL, NULL },
	{ AND_BIP,               "!and",               "val val -> val",                  NULL, NULL },
	{ OR_BIP,                "!or",                "val val -> val",                  NULL, NULL },
	{ EQ_BIP,                "!eq",                "val val -> val",                  NULL, NULL },
	{ NE_BIP,                "!ne",                "val val -> val",                  NULL, NULL },
	{ GT_BIP,                "!gt",                "val val -> val",                  NULL, NULL },
	{ GE_BIP,                "!ge",                "val val -> val",                  NULL, NULL },
	{ LT_BIP,                "!lt",                "val val -> val",                  NULL, NULL },
	{ LE_BIP,                "!le",                "val val -> val",                  NULL, NULL },
	{ OFCLASS_BIP,           "!ofclass",           "val val -> val",                  NULL, NULL },
	{ IN_BIP,                "!in",                "val val -> val",                  NULL, NULL },
	{ NOTIN_BIP,             "!notin",             "val val -> val",                  NULL, NULL },
	{ ALTERNATIVE_BIP,       "!alternative",       "val val -> val",                  NULL, NULL },

	{ FONT_BIP,              "!font",              "val -> void",                     NULL, NULL },
	{ STYLE_BIP,             "!style",             "val -> void",                     NULL, NULL },
	{ PRINT_BIP,             "!print",             "val -> void",                     NULL, NULL },
	{ PRINTNL_BIP,           "!printnl",           "void -> void",                    NULL, NULL },
	{ PRINTCHAR_BIP,         "!printchar",         "val -> void",                     NULL, NULL },
	{ PRINTOBJ_BIP,          "!printobj",          "val -> void",                     NULL, NULL },
	{ PRINTNUMBER_BIP,       "!printnumber",       "val -> void",                     NULL, NULL },
	{ PRINTDWORD_BIP,        "!printdword",        "val -> void",                     NULL, NULL },
	{ PRINTSTRING_BIP,       "!printstring",       "val -> void",                     NULL, NULL },
	{ BOX_BIP,               "!box",               "val -> void",                     NULL, NULL },
	{ SPACES_BIP,            "!spaces",            "val -> void",                     NULL, NULL },

	{ IF_BIP,                "!if",                "val code -> void",                NULL, NULL },
	{ IFDEBUG_BIP,           "!ifdebug",           "code -> void",                    NULL, NULL },
	{ IFSTRICT_BIP,          "!ifstrict",          "code -> void",                    NULL, NULL },
	{ IFELSE_BIP,            "!ifelse",            "val code code -> void",           NULL, NULL },
	{ WHILE_BIP,             "!while",             "val code -> void",                NULL, NULL },
	{ DO_BIP,                "!do",                "val code -> void",                NULL, NULL },
	{ FOR_BIP,               "!for",               "val val val code -> void",        NULL, NULL },
	{ OBJECTLOOP_BIP,        "!objectloop",        "ref val val code -> void",        NULL, NULL },
	{ OBJECTLOOPX_BIP,       "!objectloopx",       "ref val code -> void",            NULL, NULL },
	{ BREAK_BIP,             "!break",             "void -> void",                    NULL, NULL },
	{ CONTINUE_BIP,          "!continue",          "void -> void",                    NULL, NULL },
	{ SWITCH_BIP,            "!switch",            "val code -> void",                NULL, NULL },
	{ CASE_BIP,              "!case",              "val code -> void",                NULL, NULL },
	{ ALTERNATIVECASE_BIP,   "!alternativecase",   "val val -> val",                  NULL, NULL },
	{ DEFAULT_BIP,           "!default",           "code -> void",                    NULL, NULL },
	{ RETURN_BIP,            "!return",            "val -> void",                     NULL, NULL },
	{ JUMP_BIP,              "!jump",              "lab -> void",                     NULL, NULL },
	{ QUIT_BIP,              "!quit",              "void -> void",                    NULL, NULL },
	{ RESTORE_BIP,           "!restore",           "lab -> void",                     NULL, NULL },

	{ INDIRECT0V_BIP,        "!indirect0v",        "val -> void",                     NULL, NULL },
	{ INDIRECT1V_BIP,        "!indirect1v",        "val val -> void",                 NULL, NULL },
	{ INDIRECT2V_BIP,        "!indirect2v",        "val val val -> void",             NULL, NULL },
	{ INDIRECT3V_BIP,        "!indirect3v",        "val val val val -> void",         NULL, NULL },
	{ INDIRECT4V_BIP,        "!indirect4v",        "val val val val val -> void",     NULL, NULL },
	{ INDIRECT5V_BIP,        "!indirect5v",        "val val val val val val -> void", NULL, NULL },
	{ INDIRECT0_BIP,         "!indirect0",         "val -> val",                      NULL, NULL },
	{ INDIRECT1_BIP,         "!indirect1",         "val val -> val",                  NULL, NULL },
	{ INDIRECT2_BIP,         "!indirect2",         "val val val -> val",              NULL, NULL },
	{ INDIRECT3_BIP,         "!indirect3",         "val val val val -> val",          NULL, NULL },
	{ INDIRECT4_BIP,         "!indirect4",         "val val val val val -> val",      NULL, NULL },
	{ INDIRECT5_BIP,         "!indirect5",         "val val val val val val -> val",  NULL, NULL },
	{ MESSAGE0_BIP,          "!message0",          "val val -> val",                  NULL, NULL },
	{ MESSAGE1_BIP,          "!message1",          "val val val -> val",              NULL, NULL },
	{ MESSAGE2_BIP,          "!message2",          "val val val val -> val",          NULL, NULL },
	{ MESSAGE3_BIP,          "!message3",          "val val val val val -> val",      NULL, NULL },
	{ EXTERNALCALL_BIP,      "!externalcall",      "val val -> val",                  NULL, NULL },

	{ 0,                     "",                   "",                                NULL, NULL }
};

@ The following must be called before the above array can be used. It checks
that the numbering is right, and converts the names and signatures from |char *|
to |text_stream *|.

=
int standard_inform7_primitives_prepared = FALSE;
inter_ti standard_inform7_primitives_extent = 0;

void Primitives::prepare_standard_set_array(void) {
	if (standard_inform7_primitives_prepared == FALSE) {
		standard_inform7_primitives_prepared = TRUE;
		for (inter_ti i=0; ; i++) {
			if (standard_inform7_primitives[i].BIP == 0) break;
			if (i >= MAX_BIPS) internal_error("MAX_BIPS set too low");
			if (standard_inform7_primitives[i].BIP != i+1)
				internal_error("primitives table disordered");
			standard_inform7_primitives[i].name = Str::new();
			WRITE_TO(standard_inform7_primitives[i].name, "%s",
				standard_inform7_primitives[i].name_c);
			standard_inform7_primitives[i].signature = Str::new();
			WRITE_TO(standard_inform7_primitives[i].signature, "%s",
				standard_inform7_primitives[i].signature_c);
			standard_inform7_primitives_extent++;
		}
	}
}

@ We can now convert between BIP and name. Note that //Primitives::name_to_BIP//
is relatively slow: but this doesn't matter because we will always cache the
results (see below).

=
text_stream *Primitives::BIP_to_name(inter_ti bip) {
	Primitives::prepare_standard_set_array();
	if ((bip >= 1) && (bip <= standard_inform7_primitives_extent))
		return standard_inform7_primitives[bip - 1].name;
	return I"<none>";
}

inter_ti Primitives::name_to_BIP(text_stream *name) {
	Primitives::prepare_standard_set_array();
	for (inter_ti i=0; i<standard_inform7_primitives_extent; i++)
		if (Str::eq(name, standard_inform7_primitives[i].name))
			return i+1;
	return 0;
}

@ In general the standard set is a miscellany, but with one systematic family
of primitives for making indirect function calls (that is, calling a function
whose identity is not known at compile time). These 12 primitives all do
the same thing, but vary in their signatures, according to how many arguments
the function call has, and whether its return value is to be used or discarded.

The following functions allow us to ask for the right primitive for the job:

=
inter_ti Primitives::BIP_for_indirect_call_returning_value(int arity) {
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

inter_ti Primitives::BIP_for_void_indirect_call(int arity) {
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

@ And these functions say whether or not a BIP belongs to the family:

=
int Primitives::is_BIP_for_indirect_call_returning_value(inter_ti s) {
	if (s == INDIRECT0_BIP) return TRUE;
	if (s == INDIRECT1_BIP) return TRUE;
	if (s == INDIRECT2_BIP) return TRUE;
	if (s == INDIRECT3_BIP) return TRUE;
	if (s == INDIRECT4_BIP) return TRUE;
	if (s == INDIRECT5_BIP) return TRUE;
	return FALSE;
}

int Primitives::is_BIP_for_void_indirect_call(inter_ti s) {
	if (s == INDIRECT0V_BIP) return TRUE;
	if (s == INDIRECT1V_BIP) return TRUE;
	if (s == INDIRECT2V_BIP) return TRUE;
	if (s == INDIRECT3V_BIP) return TRUE;
	if (s == INDIRECT4V_BIP) return TRUE;
	if (s == INDIRECT5V_BIP) return TRUE;
	return FALSE;
}

@h Primitives within a specific tree.
So much for discussing the instruction set in the abstract: now we need code
to handle its declaration in each Inter tree we make. Note that, for speed,
each |inter_tree| structure contains the following index array inside it:

=
typedef struct site_primitives_data {
	struct inter_symbol *primitives_by_BIP[MAX_BIPS];
} site_primitives_data;

void Primitives::clear_pdata(inter_tree *I) {
	building_site *B = &(I->site);
	for (int i=0; i<MAX_BIPS; i++) B->spridata.primitives_by_BIP[i] = NULL;
}

@ That array will allow us to obtain almost instantly the Inter symbol for
the primitive in |I| having any given BIP. We need to remember that primitives
can come into being in two ways, though: either by us creating them here (see
below), or by Inter code being read in from an external file. If the latter,
the following function must be run to make sure the index is built:

=
void Primitives::index_primitives_in_tree(inter_tree *I) {
	InterTree::traverse_root_only(I, Primitives::scan_visitor, NULL, PRIMITIVE_IST);
}

void Primitives::scan_visitor(inter_tree *I, inter_tree_node *P, void *v_state) {
	inter_symbol *prim = InterSymbolsTables::symbol_from_frame_data(P, DEFN_PRIM_IFLD);
	inter_ti bip = Primitives::to_BIP(I, prim);
	if (bip) I->site.spridata.primitives_by_BIP[bip] = prim;
}

@ Here is where we declare primitives. Since there are only around 100 of these,
it's fine for the actual primitive declarations to be made a little slowly: so
we do it by writing the declarations out in textual Inter and then parsing them.
We then make various paranoid consistency checks.

=
void Primitives::declare_standard_set(inter_tree *I, inter_bookmark *IBM) {
	Primitives::prepare_standard_set_array();
	for (inter_ti i=0; i<standard_inform7_primitives_extent; i++) {
		text_stream *prim = standard_inform7_primitives[i].name;
		text_stream *signature = standard_inform7_primitives[i].signature;
		TEMPORARY_TEXT(prim_command)
		WRITE_TO(prim_command, "primitive %S %S", prim, signature);
		Produce::guard(Inter::Defn::read_construct_text(prim_command, NULL, IBM));
		inter_error_message *E = NULL;
		inter_symbol *S = Inter::Textual::find_symbol(I, NULL,
			InterTree::global_scope(I), prim, PRIMITIVE_IST, &E);
		inter_ti bip = Primitives::to_BIP(I, S);
		if (bip == 0) internal_error("missing bip");
		if (bip != standard_inform7_primitives[i].BIP) internal_error("wrong BIP");
		if (bip >= MAX_BIPS) internal_error("unsafely high bip");
		I->site.spridata.primitives_by_BIP[bip] = S;
		Produce::guard(E);
		DISCARD_TEXT(prim_command)
	}
}

@ Finally, then, we provide functions to convert between BIPs and local primitive
symbols.

=
inter_symbol *Primitives::from_BIP(inter_tree *I, inter_ti bip) {
	if (I == NULL) internal_error("no tree");
	if ((bip < 1) || (bip >= MAX_BIPS)) internal_error("bip out of range");
	return I->site.spridata.primitives_by_BIP[bip];
}

inter_ti Primitives::to_BIP(inter_tree *I, inter_symbol *symb) {
	if (symb == NULL) return 0;
	int B = Inter::Symbols::read_annotation(symb, BIP_CODE_IANN);
	inter_ti bip = (B > 0)?((inter_ti) B):0;
	if (bip != 0) return bip;
	bip = Primitives::name_to_BIP(symb->symbol_name);
	if (bip != 0) Inter::Symbols::annotate_i(symb, BIP_CODE_IANN, bip);
	return bip;
}
