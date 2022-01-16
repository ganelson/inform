[BIPMetadata::] Metadata on Primitives.

Order of precedence for Inform 6 operators, regarded as their Inter primitive
equivalents.

@h Inform 6 operators.
The following functions return data which is essentially the content of the
table shown in section 6.2 of the Inform 6 Technical Manual: which operators
take precedence over which others, which are right or left associative,
which are prefix or postfix, and so on.

The superclass operator |::| is not allowed in schemas, but nor is it needed.

@d UNPRECEDENTED_OPERATOR 10000

=
int BIPMetadata::precedence(inter_ti O) {
	if (O == STORE_BIP) return 1;

	if (O == AND_BIP) return 2;
	if (O == OR_BIP) return 2;
	if (O == NOT_BIP) return 2;

	if (O == EQ_BIP) return 3;
	if (O == GT_BIP) return 3;
	if (O == GE_BIP) return 3;
	if (O == LT_BIP) return 3;
	if (O == LE_BIP) return 3;
	if (O == NE_BIP) return 3;
	if (O == HAS_XBIP) return 3;
	if (O == HASNT_XBIP) return 3;
	if (O == OFCLASS_BIP) return 3;
	if (O == PROPERTYEXISTS_BIP) return 3;
	if (O == IN_BIP) return 3;
	if (O == NOTIN_BIP) return 3;

	if (O == ALTERNATIVE_BIP) return 4;
	if (O == ALTERNATIVECASE_BIP) return 4;

	if (O == PLUS_BIP) return 5;
	if (O == MINUS_BIP) return 5;

	if (O == TIMES_BIP) return 6;
	if (O == DIVIDE_BIP) return 6;
	if (O == MODULO_BIP) return 6;
	if (O == BITWISEAND_BIP) return 6;
	if (O == BITWISEOR_BIP) return 6;
	if (O == BITWISENOT_BIP) return 6;

	if (O == LOOKUP_BIP) return 7;
	if (O == LOOKUPBYTE_BIP) return 7;

	if (O == UNARYMINUS_BIP) return 8;

	if (O == PREINCREMENT_BIP) return 9;
	if (O == PREDECREMENT_BIP) return 9;
	if (O == POSTINCREMENT_BIP) return 9;
	if (O == POSTDECREMENT_BIP) return 9;

	if (O == PROPERTYARRAY_BIP) return 10;
	if (O == PROPERTYLENGTH_BIP) return 10;

	if (O == PROPERTYVALUE_BIP) return 12;

	if (O == OWNERKIND_XBIP) return 13;

	return UNPRECEDENTED_OPERATOR;
}

int BIPMetadata::first_operand_ref(inter_ti O) {
	if (O == STORE_BIP) return TRUE;
	if (O == PREINCREMENT_BIP) return TRUE;
	if (O == PREDECREMENT_BIP) return TRUE;
	if (O == POSTINCREMENT_BIP) return TRUE;
	if (O == POSTDECREMENT_BIP) return TRUE;
	return FALSE;
}

text_stream *BIPMetadata::I6_notation_for(inter_ti O) {
	if (O == STORE_BIP) return I"=";

	if (O == AND_BIP) return I"&&";
	if (O == OR_BIP) return I"||";
	if (O == NOT_BIP) return I"~~";

	if (O == EQ_BIP) return I"==";
	if (O == GT_BIP) return I">";
	if (O == GE_BIP) return I">=";
	if (O == LT_BIP) return I"<";
	if (O == LE_BIP) return I"<=";
	if (O == NE_BIP) return I"~=";
	if (O == HAS_XBIP) return I"has";
	if (O == HASNT_XBIP) return I"hasnt";
	if (O == OFCLASS_BIP) return I"ofclass";
	if (O == PROPERTYEXISTS_BIP) return I"provides";
	if (O == IN_BIP) return I"in";
	if (O == NOTIN_BIP) return I"notin";

	if (O == ALTERNATIVE_BIP) return I"or";

	if (O == PLUS_BIP) return I"+";
	if (O == MINUS_BIP) return I"-";

	if (O == TIMES_BIP) return I"*";
	if (O == DIVIDE_BIP) return I"/";
	if (O == MODULO_BIP) return I"%";
	if (O == BITWISEAND_BIP) return I"&";
	if (O == BITWISEOR_BIP) return I"|";
	if (O == BITWISENOT_BIP) return I"~";

	if (O == LOOKUP_BIP) return I"-->";
	if (O == LOOKUPBYTE_BIP) return I"->";

	if (O == UNARYMINUS_BIP) return I"-";

	if (O == PREINCREMENT_BIP) return I"++";
	if (O == PREDECREMENT_BIP) return I"--";
	if (O == POSTINCREMENT_BIP) return I"++";
	if (O == POSTDECREMENT_BIP) return I"--";

	if (O == PROPERTYARRAY_BIP) return I".&";
	if (O == PROPERTYLENGTH_BIP) return I".#";
	if (O == OWNERKIND_XBIP) return I"::";

	if (O == PROPERTYVALUE_BIP) return I".";

	return I"???";
}

int BIPMetadata::arity(inter_ti O) {
	if (O == STORE_BIP) return 2;

	if (O == AND_BIP) return 2;
	if (O == OR_BIP) return 2;
	if (O == NOT_BIP) return 1;

	if (O == ALTERNATIVE_BIP) return 2;
	if (O == ALTERNATIVECASE_BIP) return 2;

	if (O == EQ_BIP) return 2;
	if (O == GT_BIP) return 2;
	if (O == GE_BIP) return 2;
	if (O == LT_BIP) return 2;
	if (O == LE_BIP) return 2;
	if (O == NE_BIP) return 2;
	if (O == HAS_XBIP) return 2;
	if (O == HASNT_XBIP) return 2;
	if (O == OFCLASS_BIP) return 2;
	if (O == PROPERTYEXISTS_BIP) return 2;
	if (O == IN_BIP) return 2;
	if (O == NOTIN_BIP) return 2;

	if (O == PLUS_BIP) return 2;
	if (O == MINUS_BIP) return 2;

	if (O == TIMES_BIP) return 2;
	if (O == DIVIDE_BIP) return 2;
	if (O == MODULO_BIP) return 2;
	if (O == BITWISEAND_BIP) return 2;
	if (O == BITWISEOR_BIP) return 2;
	if (O == BITWISENOT_BIP) return 1;

	if (O == LOOKUP_BIP) return 2;
	if (O == LOOKUPBYTE_BIP) return 2;

	if (O == UNARYMINUS_BIP) return 1;

	if (O == PREINCREMENT_BIP) return 1;
	if (O == PREDECREMENT_BIP) return 1;
	if (O == POSTINCREMENT_BIP) return 1;
	if (O == POSTDECREMENT_BIP) return 1;

	if (O == PROPERTYARRAY_BIP) return 2;
	if (O == PROPERTYLENGTH_BIP) return 2;
	if (O == PROPERTYVALUE_BIP) return 2;
	if (O == OWNERKIND_XBIP) return 2;

	return 0;
}

int BIPMetadata::prefix(inter_ti O) {
	if (O == NOT_BIP) return TRUE;
	if (O == BITWISENOT_BIP) return TRUE;
	if (O == UNARYMINUS_BIP) return TRUE;

	if (O == PREINCREMENT_BIP) return TRUE;
	if (O == PREDECREMENT_BIP) return TRUE;
	if (O == POSTINCREMENT_BIP) return FALSE;
	if (O == POSTDECREMENT_BIP) return FALSE;

	return NOT_APPLICABLE;
}

int BIPMetadata::right_associative(inter_ti O) {
	if (O == STORE_BIP) return FALSE;
	return TRUE;
}

@h Metadata on inter primitives.

=
int BIPMetadata::ip_arity(inter_ti O) {
	int arity = 1;
	if (O == BREAK_BIP) arity = 0;
	if (O == CONTINUE_BIP) arity = 0;
	if (O == QUIT_BIP) arity = 0;
	if (O == MOVE_BIP) arity = 2;
	if (O == DEFAULT_BIP) arity = 1;
	if (O == CASE_BIP) arity = 2;
	if (O == SWITCH_BIP) arity = 2;
	if (O == OBJECTLOOP_BIP) arity = 2;
	if (O == IF_BIP) arity = 2;
	if (O == IFELSE_BIP) arity = 3;
	if (O == FOR_BIP) arity = 4;
	if (O == WHILE_BIP) arity = 2;
	if (O == DO_BIP) arity = 2;
	if (O == READ_XBIP) arity = 2;
	return arity;
}

int BIPMetadata::ip_loopy(inter_ti O) {
	int loopy = FALSE;
	if (O == OBJECTLOOP_BIP) loopy = TRUE;
	if (O == FOR_BIP) loopy = TRUE;
	if (O == WHILE_BIP) loopy = TRUE;
	if (O == DO_BIP) loopy = TRUE;
	return loopy;
}

int BIPMetadata::ip_prim_cat(inter_ti O, int i) {
	int ok = VAL_PRIM_CAT;
	if (O == JUMP_BIP) ok = LAB_PRIM_CAT;
	if (O == RESTORE_BIP) ok = LAB_PRIM_CAT;
	if (O == PULL_BIP) ok = REF_PRIM_CAT;

	if ((O == IF_BIP) && (i == 1)) ok = CODE_PRIM_CAT;
	if ((O == SWITCH_BIP) && (i == 1)) ok = CODE_PRIM_CAT;
	if ((O == CASE_BIP) && (i == 1)) ok = CODE_PRIM_CAT;
	if ((O == DEFAULT_BIP) && (i == 0)) ok = CODE_PRIM_CAT;
	if ((O == IFELSE_BIP) && (i >= 1)) ok = CODE_PRIM_CAT;
	if ((BIPMetadata::ip_loopy(O)) && (i == BIPMetadata::ip_arity(O) - 1)) ok = CODE_PRIM_CAT;
	return ok;
}
