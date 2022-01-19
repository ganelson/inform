[I6Operators::] Inform 6 Operators.

Order of precedence for Inform 6 operators, regarded as their Inter primitive
equivalents.

@ The following table of data is essentially the same one in shown in section 
6.2 of the Inform 6 Technical Manual: which operators take precedence over
which others, which are right or left associative, which are prefix or postfix,
and so on.

=
typedef struct i6_operator_metadata {
	inter_ti BIP;          /* which may be a |*_XBIP| value */
	int precedence;        /* operators with higher precedence bind more tightly */
	int prefix;            /* |TRUE| for prefix, |FALSE| for suffix, |NOT_APPLICABLE| for infix */
	int right_associative; /* if same operator used twice at same precedence */
	int arity;             /* how many operands the operator has: always 1 or 2 */
	char *notation_c;      /* Inform 6 syntax for this operator */
	struct text_stream *notation;
} i6_operator_metadata;

@ Do not reorder this table without reading //I6Operators::notation_to_BIP// below.

=
i6_operator_metadata i6_operator_chart[] = {
	{ STORE_BIP,           1, NOT_APPLICABLE, FALSE, 2, "=",        NULL },

	{ AND_BIP,             2, NOT_APPLICABLE, TRUE,  2, "&&",       NULL },
	{ OR_BIP,              2, NOT_APPLICABLE, TRUE,  2, "||",       NULL },
	{ NOT_BIP,             2, TRUE,           TRUE,  1, "~~",       NULL },

	{ EQ_BIP,              3, NOT_APPLICABLE, TRUE,  2, "==",       NULL },
	{ GT_BIP,              3, NOT_APPLICABLE, TRUE,  2, ">",        NULL },
	{ GE_BIP,              3, NOT_APPLICABLE, TRUE,  2, ">=",       NULL },
	{ LT_BIP,              3, NOT_APPLICABLE, TRUE,  2, "<",        NULL },
	{ LE_BIP,              3, NOT_APPLICABLE, TRUE,  2, "<=",       NULL },
	{ NE_BIP,              3, NOT_APPLICABLE, TRUE,  2, "~=",       NULL },
	{ HAS_XBIP,            3, NOT_APPLICABLE, TRUE,  2, "has",      NULL },
	{ HASNT_XBIP,          3, NOT_APPLICABLE, TRUE,  2, "hasnt",    NULL },
	{ OFCLASS_BIP,         3, NOT_APPLICABLE, TRUE,  2, "ofclass",  NULL },
	{ PROPERTYEXISTS_BIP,  3, NOT_APPLICABLE, TRUE,  2, "provides", NULL },
	{ IN_BIP,              3, NOT_APPLICABLE, TRUE,  2, "in",       NULL },
	{ NOTIN_BIP,           3, NOT_APPLICABLE, TRUE,  2, "notin",    NULL },

	{ ALTERNATIVE_BIP,     4, NOT_APPLICABLE, TRUE,  2, "or",       NULL },
	{ ALTERNATIVECASE_BIP, 4, NOT_APPLICABLE, TRUE,  2, "",         NULL },

	{ PLUS_BIP,            5, NOT_APPLICABLE, TRUE,  2, "+",        NULL },
	{ MINUS_BIP,           5, NOT_APPLICABLE, TRUE,  2, "-",        NULL },

	{ TIMES_BIP,           6, NOT_APPLICABLE, TRUE,  2, "*",        NULL },
	{ DIVIDE_BIP,          6, NOT_APPLICABLE, TRUE,  2, "/",        NULL },
	{ MODULO_BIP,          6, NOT_APPLICABLE, TRUE,  2, "%",        NULL },
	{ BITWISEAND_BIP,      6, NOT_APPLICABLE, TRUE,  2, "&",        NULL },
	{ BITWISEOR_BIP,       6, NOT_APPLICABLE, TRUE,  2, "|",        NULL },
	{ BITWISENOT_BIP,      6, TRUE,           TRUE,  1, "~",        NULL },

	{ LOOKUP_BIP,          7, NOT_APPLICABLE, TRUE,  2, "-->",      NULL },
	{ LOOKUPBYTE_BIP,      7, NOT_APPLICABLE, TRUE,  2, "->",       NULL },

	{ UNARYMINUS_BIP,      8, NOT_APPLICABLE, TRUE,  1, "-",        NULL },

	{ POSTINCREMENT_BIP,   9, FALSE,          TRUE,  1, "++",       NULL },
	{ POSTDECREMENT_BIP,   9, FALSE,          TRUE,  1, "--",       NULL },
	{ PREINCREMENT_BIP,    9, TRUE,           TRUE,  1, "++",       NULL },
	{ PREDECREMENT_BIP,    9, TRUE,           TRUE,  1, "--",       NULL },

	{ PROPERTYARRAY_BIP,  10, NOT_APPLICABLE, TRUE,  2, ".&",       NULL },
	{ PROPERTYLENGTH_BIP, 10, NOT_APPLICABLE, TRUE,  2, ".#",       NULL },

	{ PROPERTYVALUE_BIP,  12, NOT_APPLICABLE, TRUE,  2, ".",        NULL },

	{ OWNERKIND_XBIP,     13, NOT_APPLICABLE, TRUE,  2, ">>",       NULL },
	
	{ 0,                  -1, NOT_APPLICABLE, TRUE,  0, "",         NULL }
};

@ The following must be called before the above array can be used. It checks
that the numbering is right, and converts the names and signatures from |char *|
to |text_stream *|.

=
int inform6_operators_chart_prepared = FALSE;
int inform6_operators_xref[MAX_BIPS];
int inform6_operators_XBIP_xref[MAX_BIPS];

void I6Operators::prepare_chart(void) {
	if (inform6_operators_chart_prepared == FALSE) {
		inform6_operators_chart_prepared = TRUE;
		for (int i=0; i<MAX_BIPS; i++) inform6_operators_xref[i] = -1;
		for (int i=0; i<MAX_BIPS; i++) inform6_operators_XBIP_xref[i] = -1;
		for (inter_ti i=0; ; i++) {
			if (i6_operator_chart[i].BIP == 0) break;
			if (i >= MAX_BIPS) internal_error("MAX_BIPS set too low");
			inter_ti BIP = i6_operator_chart[i].BIP;
			if (BIP >= LOWEST_XBIP_VALUE) {
				if (BIP > HIGHEST_XBIP_VALUE) internal_error("XBIP value out of range");
				inform6_operators_XBIP_xref[BIP - LOWEST_XBIP_VALUE] = (int) i;
			} else {
				if (BIP >= MAX_BIPS) internal_error("BIP value out of range");
				inform6_operators_xref[BIP] = (int) i;
			}
			i6_operator_chart[i].notation = Str::new();
			WRITE_TO(i6_operator_chart[i].notation, "%s",
				i6_operator_chart[i].notation_c);
		}
	}
}

@ This, again, is trickier than it looks because a valid input can be either a
|*_BIP| code or a |*_XBIP| code:

=
i6_operator_metadata *I6Operators::operator_for_BIP(inter_ti BIP) {
	I6Operators::prepare_chart();
	if ((BIP < MAX_BIPS) && (inform6_operators_xref[BIP] >= 0))
		return &(i6_operator_chart[inform6_operators_xref[BIP]]);
	if ((BIP >= LOWEST_XBIP_VALUE) && (BIP <= OWNERKIND_XBIP) &&
		(inform6_operators_XBIP_xref[BIP - LOWEST_XBIP_VALUE] >= 0))
		return &(i6_operator_chart[inform6_operators_XBIP_xref[BIP - LOWEST_XBIP_VALUE]]);
	return NULL;
}

@ So now we have the outward-facing API. Here's the Inform 6 notation:

=
text_stream *I6Operators::I6_notation_for(inter_ti BIP) {
	i6_operator_metadata *md = I6Operators::operator_for_BIP(BIP);
	return (md) ? (md->notation) : I"???";
}

@ And the inverse of that function, from text to an operator, or 0 if none
matches. Note that we return the earliest row in the above table, if more than
one matches, and this matters for |++| and |--|, where the same notation is
used both for the prefix and postfix operators.

=
inter_ti I6Operators::notation_to_BIP(text_stream *T) {
	I6Operators::prepare_chart();
	for (inter_ti i=0; ; i++) {
		if (i6_operator_chart[i].BIP == 0) break;
		if (Str::eq(T, i6_operator_chart[i].notation)) return i6_operator_chart[i].BIP;
	}
	return 0;
}

@ The arity of the operator, always 1 or 2, unless the given |BIP| is not
an operator at all:

=
int I6Operators::arity(inter_ti BIP) {
	i6_operator_metadata *md = I6Operators::operator_for_BIP(BIP);
	return (md) ? (md->arity) : 0;
}

@ Returns:

(*) |TRUE| for a prefix operator, e.g., |++alpha|;
(*) |FALSE| for a postfix operator, e.g., |alpha--|;
(*) |NOT_APPLICABLE| for an infix operator, e.g., |alpha + beta|, or for
something which is not an operator at all.

=
int I6Operators::prefix(inter_ti BIP) {
	i6_operator_metadata *md = I6Operators::operator_for_BIP(BIP);
	return (md) ? (md->prefix) : NOT_APPLICABLE;
}

@ The precedence level of the operator, or infinity (near enough) if this is
not an operator at all.

@d UNPRECEDENTED_OPERATOR 10000

=
int I6Operators::precedence(inter_ti BIP) {
	i6_operator_metadata *md = I6Operators::operator_for_BIP(BIP);
	return (md) ? (md->precedence) : UNPRECEDENTED_OPERATOR;
}

@ |TRUE| if the operator is right associative, |FALSE| if it is left associative;
irrelevant, of course, for unary operators.

=
int I6Operators::right_associative(inter_ti BIP) {
	i6_operator_metadata *md = I6Operators::operator_for_BIP(BIP);
	return (md) ? (md->right_associative) : TRUE;
}
