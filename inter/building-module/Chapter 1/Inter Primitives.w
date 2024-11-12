[Primitives::] Inter Primitives.

The standard set of primitive invocations available in Inter code as generated
by the Inform tool-chain.

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
	int term_count;
	int term_categories[8];
	int takes_code_blocks;
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

@e ENABLEPRINTING_BIP
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
@e INDIRECT6V_BIP
@e INDIRECT0_BIP
@e INDIRECT1_BIP
@e INDIRECT2_BIP
@e INDIRECT3_BIP
@e INDIRECT4_BIP
@e INDIRECT5_BIP
@e INDIRECT6_BIP
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

@d SIP_RECORD_END
	NULL, NULL, 0,
	{ VAL_PRIM_CAT, VAL_PRIM_CAT, VAL_PRIM_CAT, VAL_PRIM_CAT, VAL_PRIM_CAT, VAL_PRIM_CAT, VAL_PRIM_CAT, VAL_PRIM_CAT },
	FALSE

=
inform7_primitive standard_inform7_primitives[] = {
	{ PLUS_BIP,              "!plus",              "val val -> val",                  SIP_RECORD_END },
	{ MINUS_BIP,             "!minus",             "val val -> val",                  SIP_RECORD_END },
	{ UNARYMINUS_BIP,        "!unaryminus",        "val -> val",                      SIP_RECORD_END },
	{ TIMES_BIP,             "!times",             "val val -> val",                  SIP_RECORD_END },
	{ DIVIDE_BIP,            "!divide",            "val val -> val",                  SIP_RECORD_END },
	{ MODULO_BIP,            "!modulo",            "val val -> val",                  SIP_RECORD_END },
	{ BITWISEAND_BIP,        "!bitwiseand",        "val val -> val",                  SIP_RECORD_END },
	{ BITWISEOR_BIP,         "!bitwiseor",         "val val -> val",                  SIP_RECORD_END },
	{ BITWISENOT_BIP,        "!bitwisenot",        "val -> val",                      SIP_RECORD_END },
	{ SEQUENTIAL_BIP,        "!sequential",        "val val -> val",                  SIP_RECORD_END },
	{ TERNARYSEQUENTIAL_BIP, "!ternarysequential", "val val val -> val",              SIP_RECORD_END },
	{ RANDOM_BIP,            "!random",            "val -> val",                      SIP_RECORD_END },

	{ STORE_BIP,             "!store",             "ref val -> val",                  SIP_RECORD_END },
	{ PREINCREMENT_BIP,      "!preincrement",      "ref -> val",                      SIP_RECORD_END },
	{ POSTINCREMENT_BIP,     "!postincrement",     "ref -> val",                      SIP_RECORD_END },
	{ PREDECREMENT_BIP,      "!predecrement",      "ref -> val",                      SIP_RECORD_END },
	{ POSTDECREMENT_BIP,     "!postdecrement",     "ref -> val",                      SIP_RECORD_END },
	{ SETBIT_BIP,            "!setbit",            "ref val -> void",                 SIP_RECORD_END },
	{ CLEARBIT_BIP,          "!clearbit",          "ref val -> void",                 SIP_RECORD_END },

	{ PUSH_BIP,              "!push",              "val -> void",                     SIP_RECORD_END },
	{ PULL_BIP,              "!pull",              "ref -> void",                     SIP_RECORD_END },
	{ LOOKUP_BIP,            "!lookup",            "val val -> val",                  SIP_RECORD_END },
	{ LOOKUPBYTE_BIP,        "!lookupbyte",        "val val -> val",                  SIP_RECORD_END },
	{ PROPERTYARRAY_BIP,     "!propertyarray",     "val val val -> val",              SIP_RECORD_END },
	{ PROPERTYLENGTH_BIP,    "!propertylength",    "val val val -> val",              SIP_RECORD_END },
	{ PROPERTYEXISTS_BIP,    "!propertyexists",    "val val val -> val",              SIP_RECORD_END },
	{ PROPERTYVALUE_BIP,     "!propertyvalue",     "val val val -> val",              SIP_RECORD_END },

	{ MOVE_BIP,              "!move",              "val val -> void",                 SIP_RECORD_END },
	{ REMOVE_BIP,            "!remove",            "val -> void",                     SIP_RECORD_END },
	{ CHILD_BIP,             "!child",             "val -> val",                      SIP_RECORD_END },
	{ CHILDREN_BIP,          "!children",          "val -> val",                      SIP_RECORD_END },
	{ SIBLING_BIP,           "!sibling",           "val -> val",                      SIP_RECORD_END },
	{ PARENT_BIP,            "!parent",            "val -> val",                      SIP_RECORD_END },
	{ METACLASS_BIP,         "!metaclass",         "val -> val",                      SIP_RECORD_END },

	{ NOT_BIP,               "!not",               "val -> val",                      SIP_RECORD_END },
	{ AND_BIP,               "!and",               "val val -> val",                  SIP_RECORD_END },
	{ OR_BIP,                "!or",                "val val -> val",                  SIP_RECORD_END },
	{ EQ_BIP,                "!eq",                "val val -> val",                  SIP_RECORD_END },
	{ NE_BIP,                "!ne",                "val val -> val",                  SIP_RECORD_END },
	{ GT_BIP,                "!gt",                "val val -> val",                  SIP_RECORD_END },
	{ GE_BIP,                "!ge",                "val val -> val",                  SIP_RECORD_END },
	{ LT_BIP,                "!lt",                "val val -> val",                  SIP_RECORD_END },
	{ LE_BIP,                "!le",                "val val -> val",                  SIP_RECORD_END },
	{ OFCLASS_BIP,           "!ofclass",           "val val -> val",                  SIP_RECORD_END },
	{ IN_BIP,                "!in",                "val val -> val",                  SIP_RECORD_END },
	{ NOTIN_BIP,             "!notin",             "val val -> val",                  SIP_RECORD_END },
	{ ALTERNATIVE_BIP,       "!alternative",       "val val -> val",                  SIP_RECORD_END },

	{ ENABLEPRINTING_BIP,    "!enableprinting",    "void -> void",                    SIP_RECORD_END },
	{ FONT_BIP,              "!font",              "val -> void",                     SIP_RECORD_END },
	{ STYLE_BIP,             "!style",             "val -> void",                     SIP_RECORD_END },
	{ PRINT_BIP,             "!print",             "val -> void",                     SIP_RECORD_END },
	{ PRINTNL_BIP,           "!printnl",           "void -> void",                    SIP_RECORD_END },
	{ PRINTCHAR_BIP,         "!printchar",         "val -> void",                     SIP_RECORD_END },
	{ PRINTOBJ_BIP,          "!printobj",          "val -> void",                     SIP_RECORD_END },
	{ PRINTNUMBER_BIP,       "!printnumber",       "val -> void",                     SIP_RECORD_END },
	{ PRINTDWORD_BIP,        "!printdword",        "val -> void",                     SIP_RECORD_END },
	{ PRINTSTRING_BIP,       "!printstring",       "val -> void",                     SIP_RECORD_END },
	{ BOX_BIP,               "!box",               "val -> void",                     SIP_RECORD_END },
	{ SPACES_BIP,            "!spaces",            "val -> void",                     SIP_RECORD_END },

	{ IF_BIP,                "!if",                "val code -> void",                SIP_RECORD_END },
	{ IFDEBUG_BIP,           "!ifdebug",           "code -> void",                    SIP_RECORD_END },
	{ IFSTRICT_BIP,          "!ifstrict",          "code -> void",                    SIP_RECORD_END },
	{ IFELSE_BIP,            "!ifelse",            "val code code -> void",           SIP_RECORD_END },
	{ WHILE_BIP,             "!while",             "val code -> void",                SIP_RECORD_END },
	{ DO_BIP,                "!do",                "val code -> void",                SIP_RECORD_END },
	{ FOR_BIP,               "!for",               "val val val code -> void",        SIP_RECORD_END },
	{ OBJECTLOOP_BIP,        "!objectloop",        "ref val val code -> void",        SIP_RECORD_END },
	{ OBJECTLOOPX_BIP,       "!objectloopx",       "ref val code -> void",            SIP_RECORD_END },
	{ BREAK_BIP,             "!break",             "void -> void",                    SIP_RECORD_END },
	{ CONTINUE_BIP,          "!continue",          "void -> void",                    SIP_RECORD_END },
	{ SWITCH_BIP,            "!switch",            "val code -> void",                SIP_RECORD_END },
	{ CASE_BIP,              "!case",              "val code -> void",                SIP_RECORD_END },
	{ ALTERNATIVECASE_BIP,   "!alternativecase",   "val val -> val",                  SIP_RECORD_END },
	{ DEFAULT_BIP,           "!default",           "code -> void",                    SIP_RECORD_END },
	{ RETURN_BIP,            "!return",            "val -> void",                     SIP_RECORD_END },
	{ JUMP_BIP,              "!jump",              "lab -> void",                     SIP_RECORD_END },
	{ QUIT_BIP,              "!quit",              "void -> void",                    SIP_RECORD_END },
	{ RESTORE_BIP,           "!restore",           "lab -> void",                     SIP_RECORD_END },

	{ INDIRECT0V_BIP,        "!indirect0v",        "val -> void",                     SIP_RECORD_END },
	{ INDIRECT1V_BIP,        "!indirect1v",        "val val -> void",                 SIP_RECORD_END },
	{ INDIRECT2V_BIP,        "!indirect2v",        "val val val -> void",             SIP_RECORD_END },
	{ INDIRECT3V_BIP,        "!indirect3v",        "val val val val -> void",         SIP_RECORD_END },
	{ INDIRECT4V_BIP,        "!indirect4v",        "val val val val val -> void",     SIP_RECORD_END },
	{ INDIRECT5V_BIP,        "!indirect5v",        "val val val val val val -> void", SIP_RECORD_END },
	{ INDIRECT6V_BIP,        "!indirect6v",        "val val val val val val val -> void", SIP_RECORD_END },
	{ INDIRECT0_BIP,         "!indirect0",         "val -> val",                      SIP_RECORD_END },
	{ INDIRECT1_BIP,         "!indirect1",         "val val -> val",                  SIP_RECORD_END },
	{ INDIRECT2_BIP,         "!indirect2",         "val val val -> val",              SIP_RECORD_END },
	{ INDIRECT3_BIP,         "!indirect3",         "val val val val -> val",          SIP_RECORD_END },
	{ INDIRECT4_BIP,         "!indirect4",         "val val val val val -> val",      SIP_RECORD_END },
	{ INDIRECT5_BIP,         "!indirect5",         "val val val val val val -> val",  SIP_RECORD_END },
	{ INDIRECT6_BIP,         "!indirect6",         "val val val val val val val -> val",  SIP_RECORD_END },
	{ MESSAGE0_BIP,          "!message0",          "val val -> val",                  SIP_RECORD_END },
	{ MESSAGE1_BIP,          "!message1",          "val val val -> val",              SIP_RECORD_END },
	{ MESSAGE2_BIP,          "!message2",          "val val val val -> val",          SIP_RECORD_END },
	{ MESSAGE3_BIP,          "!message3",          "val val val val val -> val",      SIP_RECORD_END },
	{ EXTERNALCALL_BIP,      "!externalcall",      "val val -> val",                  SIP_RECORD_END },

	{ 0,                     "",                   "",                                SIP_RECORD_END }
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
			@<Parse and sanity-check the signature text@>;
			standard_inform7_primitives_extent++;
		}
	}
}

@ We only care here abput the part of the signature before the |->|, but we go
ahead and perform a full sanity check on it anyway, just in case somebody some day
amends the above table but gets it wrong. The time consumed by these checks
is trivial, since this happens only once per run.

@<Parse and sanity-check the signature text@> =
	int p = 0, before_arrow = TRUE, pre_void = FALSE, inputs = 0, outputs = 0;
	text_stream *S = standard_inform7_primitives[i].signature;
	TEMPORARY_TEXT(term)
	while (p <= Str::len(S)) {
		inchar32_t c = Str::get_at(S, p);
		if ((Characters::is_whitespace(c)) || (c == 0)) {
			if ((Str::eq(term, I"->")) && (before_arrow)) before_arrow = FALSE;
			else {
				int this = -1;
				if (Str::eq(term, I"void")) {
					this = -2;
					if (before_arrow) pre_void = TRUE;
				}
				if (Str::eq(term, I"val"))  this = VAL_PRIM_CAT;
				if (Str::eq(term, I"ref"))  this = REF_PRIM_CAT;
				if (Str::eq(term, I"lab"))  this = LAB_PRIM_CAT;
				if (Str::eq(term, I"code")) this = CODE_PRIM_CAT;
				if (this == -1) internal_error("unknown term category in primitive");
				if (before_arrow) {
					if (this != -2) {
						if (inputs >= 8) internal_error("too many terms in primitive");
						standard_inform7_primitives[i].term_categories[inputs] = this;
						inputs++;
					}
				} else {
					if ((this != -2) && (this != VAL_PRIM_CAT))
						internal_error("bad term after -> in primitive");
					outputs++;
				}	
			}
			Str::clear(term);
		} else {
			PUT_TO(term, c);
		}
		p++;
	}
	DISCARD_TEXT(term)
	if ((outputs > 1) || ((pre_void) && (inputs > 0)))
		internal_error("malformed signature in primitive");
	standard_inform7_primitives[i].term_count = inputs;
	standard_inform7_primitives[i].takes_code_blocks = FALSE;
	for (int t=0; t<inputs; t++)
		if (standard_inform7_primitives[i].term_categories[t] == CODE_PRIM_CAT)
			standard_inform7_primitives[i].takes_code_blocks = TRUE;

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

@ This is printed when //inter// is run with the |-primitives| switch.

=
void Primitives::show_primitives(OUTPUT_STREAM) {
	WRITE("  Code     Primitive           Signature\n");
	Primitives::prepare_standard_set_array();
	for (inter_ti i=0; i<standard_inform7_primitives_extent; i++) {
		inform7_primitive *prim = &(standard_inform7_primitives[i]);
		WRITE("  %4x     %S", prim->BIP, prim->name);
		for (int j = Str::len(prim->name); j<20; j++) PUT(' ');
		WRITE("%S\n", prim->signature);
	}	
}

@ In general the standard set is a miscellany, but with one systematic family
of primitives for making indirect function calls (that is, calling a function
whose identity is not known at compile time). These 12 primitives all do
the same thing, but vary in their signatures, according to how many arguments
the function call has, and whether its return value is to be used or discarded.

The following functions allow us to ask for the right primitive for the job:

=
int Primitives::arity_too_great_for_indirection(int arity) {
	if (arity > 6) return TRUE;
	return FALSE;
}

inter_ti Primitives::BIP_for_indirect_call_returning_value(int arity) {
	switch (arity) {
		case 0: return INDIRECT0_BIP;
		case 1: return INDIRECT1_BIP;
		case 2: return INDIRECT2_BIP;
		case 3: return INDIRECT3_BIP;
		case 4: return INDIRECT4_BIP;
		case 5: return INDIRECT5_BIP;
		case 6: return INDIRECT6_BIP;
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
		case 6: return INDIRECT6V_BIP;
		default: internal_error("indirectv function call with too many arguments");
	}
	return 0;
}

inter_ti Primitives::BIP_for_message_send(int arity) {
	switch (arity) {
		case 2: return MESSAGE0_BIP;
		case 3: return MESSAGE1_BIP;
		case 4: return MESSAGE2_BIP;
		case 5: return MESSAGE3_BIP;
		default: internal_error("message call must have arity 2 to 5");
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
	if (s == INDIRECT6_BIP) return TRUE;
	return FALSE;
}

int Primitives::is_BIP_for_void_indirect_call(inter_ti s) {
	if (s == INDIRECT0V_BIP) return TRUE;
	if (s == INDIRECT1V_BIP) return TRUE;
	if (s == INDIRECT2V_BIP) return TRUE;
	if (s == INDIRECT3V_BIP) return TRUE;
	if (s == INDIRECT4V_BIP) return TRUE;
	if (s == INDIRECT5V_BIP) return TRUE;
	if (s == INDIRECT6V_BIP) return TRUE;
	return FALSE;
}

@h About the terms.
For example, 0 for the signature |void -> val|, or 2 for |ref val -> val|.

The |*_XBIP| operations are treated as if they had the signature |val val -> void|.

=
int Primitives::term_count(inter_ti BIP) {
	Primitives::prepare_standard_set_array();
	if (BIP >= LOWEST_XBIP_VALUE) return 2;
	return standard_inform7_primitives[BIP - 1].term_count;
}

@ And this returns the primitive category for each term, counting from 0:
this will be |VAL_PRIM_CAT|, |CODE_PRIM_CAT|, |REF_PRIM_CAT| or |LAB_PRIM_CAT|.

Again, the |*_XBIP| operations are treated as if |val val -> void|.

=
int Primitives::term_category(inter_ti BIP, int i) {
	Primitives::prepare_standard_set_array();
	if ((i < 0) || (i >= 8)) internal_error("term out of range");
	if (BIP >= LOWEST_XBIP_VALUE) return VAL_PRIM_CAT;
	return standard_inform7_primitives[BIP - 1].term_categories[i];
}

@ Returns |TRUE| if any of those categories is a |CODE_PRIM_CAT|; note that
this is cached for speed.

=
int Primitives::takes_code_blocks(inter_ti BIP) {
	Primitives::prepare_standard_set_array();
	if (BIP >= LOWEST_XBIP_VALUE) return FALSE;
	return standard_inform7_primitives[BIP - 1].takes_code_blocks;
}

@h Primitives within a specific tree.
So much for discussing the instruction set in the abstract: now we need code
to handle its declaration in each Inter tree we make. Note that, for speed,
each |inter_tree| structure contains the following index array inside it:

=
typedef struct site_primitives_data {
	struct inter_symbol *primitives_by_BIP[MAX_BIPS];
} site_primitives_data;

void Primitives::clear_site_data(inter_tree *I) {
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
	inter_symbol *prim = PrimitiveInstruction::primitive(P);
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
	for (inter_ti i=0; i<standard_inform7_primitives_extent; i++)
		Primitives::declare_one(I, IBM, &(standard_inform7_primitives[i]));
}

inter_symbol *Primitives::declare_one(inter_tree *I, inter_bookmark *IBM, inform7_primitive *prim) {
	text_stream *name = prim->name;
	text_stream *signature = prim->signature;
	TEMPORARY_TEXT(prim_command)
	WRITE_TO(prim_command, "primitive %S %S", name, signature);
	Produce::guard(TextualInter::parse_single_line(prim_command, NULL, IBM));
	inter_error_message *E = NULL;
	inter_symbol *S = TextualInter::find_global_symbol(IBM, NULL, name, PRIMITIVE_IST, &E);
	inter_ti bip = Primitives::to_BIP(I, S);
	if (bip == 0) internal_error("missing bip");
	if (bip != prim->BIP) internal_error("wrong BIP");
	if (bip >= MAX_BIPS) internal_error("unsafely high bip");
	I->site.spridata.primitives_by_BIP[bip] = S;
	Produce::guard(E);
	DISCARD_TEXT(prim_command)
	return S;
}

@ Used when parsing textual Inter:

=
inter_symbol *Primitives::declare_one_named(inter_tree *I, inter_bookmark *IBM,
	text_stream *name) {
	Primitives::prepare_standard_set_array();
	for (inter_ti i=0; i<standard_inform7_primitives_extent; i++) {
		inform7_primitive *prim = &(standard_inform7_primitives[i]);
		if (Str::eq(prim->name, name)) return Primitives::declare_one(I, IBM, prim);
	}
	return NULL;
}

@ Finally, then, we provide functions to convert between BIPs and local primitive
symbols.

=
inter_symbol *Primitives::from_BIP(inter_tree *I, inter_ti bip) {
	if (I == NULL) internal_error("no tree");
	if ((bip < 1) || (bip >= MAX_BIPS)) internal_error("bip out of range");
	inter_symbol *prim = I->site.spridata.primitives_by_BIP[bip];
	if (prim == NULL) {
		WRITE_TO(STDERR, "BIP = %d\n", bip);
		internal_error("undefined primitive");
	}
	return prim;
}

inter_ti Primitives::to_BIP(inter_tree *I, inter_symbol *symb) {
	if (symb == NULL) return 0;
	inter_ti B = PrimitiveInstruction::get_BIP(symb);
	if (B == 0) {
		B = Primitives::name_to_BIP(InterSymbol::identifier(symb));
		if (B != 0) PrimitiveInstruction::set_BIP(symb, B);
	}
	return B;
}
