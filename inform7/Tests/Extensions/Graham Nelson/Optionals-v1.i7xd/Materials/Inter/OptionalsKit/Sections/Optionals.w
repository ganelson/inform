Optionals

The functions needed for "optional K" support.

@ See "Writing with Inform" for details.

=
Constant OPTIONAL_CONTENT_SF = SBONLYPV_FIELDS + 0;

Constant OPTIONAL_TY_NO_VALUE_SBF = 1;

[ OPTIONAL_TY_Say opt scalar_kind_id;
	if (ShortBlockOnlyPVFlags(opt, 0) & OPTIONAL_TY_NO_VALUE_SBF) {
		print "no value";
	} else {
		scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(opt), 0);
		SayKindValuePair(scalar_kind_id, opt-->OPTIONAL_CONTENT_SF);
	}
];

[ OPTIONAL_TY_Compare opt1 opt2 scalar_kind_id;
	if (ShortBlockOnlyPVFlags(opt1, 0) & OPTIONAL_TY_NO_VALUE_SBF) {
		if (ShortBlockOnlyPVFlags(opt2, 0) & OPTIONAL_TY_NO_VALUE_SBF) return 0;
		return -1;
	}
	if (ShortBlockOnlyPVFlags(opt2, 0) & OPTIONAL_TY_NO_VALUE_SBF) return 1;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(opt1), 0);
	return CompareKindValuePairs(
		scalar_kind_id, opt1-->OPTIONAL_CONTENT_SF,
		scalar_kind_id, opt2-->OPTIONAL_CONTENT_SF);
];

[ OPTIONAL_TY_Create kind_id sb_address
	short_block scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(kind_id, 0);
	short_block = CreatePVShortBlock(sb_address, kind_id);
	WriteShortBlockOnlyPVFlags(short_block, OPTIONAL_TY_NO_VALUE_SBF);
	short_block-->OPTIONAL_CONTENT_SF = 0;
	
	return short_block;
];

[ OPTIONAL_TY_Destroy opt scalar_kind_id;
	if (ShortBlockOnlyPVFlags(opt, 0) & OPTIONAL_TY_NO_VALUE_SBF) return;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(opt), 0);
	if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id))
		DestroyPV(opt-->OPTIONAL_CONTENT_SF);
];

[ OPTIONAL_TY_QuickCopy optto optfrom kind;
	rfalse;
];

[ OPTIONAL_TY_Copy optto optfrom scalar_kind_id;
	if (ShortBlockOnlyPVFlags(optfrom, 0) & OPTIONAL_TY_NO_VALUE_SBF) {
		if (ShortBlockOnlyPVFlags(optto, 0) & OPTIONAL_TY_NO_VALUE_SBF == 0) {
			scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(optto), 0);
			if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id))
				DestroyPV(optto-->OPTIONAL_CONTENT_SF);
			optto-->OPTIONAL_CONTENT_SF = 0;
			WriteShortBlockOnlyPVFlags(optto, OPTIONAL_TY_NO_VALUE_SBF);
		}
	} else {
		scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(optto), 0);
		if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id)) {
			if (ShortBlockOnlyPVFlags(optto, 0) & OPTIONAL_TY_NO_VALUE_SBF)
				optto-->OPTIONAL_CONTENT_SF = CreatePV(scalar_kind_id);
			CopyPV(optto-->OPTIONAL_CONTENT_SF, optfrom-->OPTIONAL_CONTENT_SF);
		} else {
			optto-->OPTIONAL_CONTENT_SF = optfrom-->OPTIONAL_CONTENT_SF;
		}
		WriteShortBlockOnlyPVFlags(optto, 0);
	}
	return false;
];

[ OPTIONAL_TY_Wrap opt x scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(opt), 0);
	WriteShortBlockOnlyPVFlags(opt, 0);
	if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id)) {
		if (opt-->OPTIONAL_CONTENT_SF == 0)
			opt-->OPTIONAL_CONTENT_SF = CreatePV(scalar_kind_id);
		CopyPV(opt-->OPTIONAL_CONTENT_SF, x);
	} else {
		opt-->OPTIONAL_CONTENT_SF = x;
	}
	return opt;
];

[ OPTIONAL_TY_Exists opt;
	if (ShortBlockOnlyPVFlags(opt, 0) & OPTIONAL_TY_NO_VALUE_SBF)
		rfalse;
	rtrue;
];

[ OPTIONAL_TY_Unwrap val opt scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(opt), 0);
	if (ShortBlockOnlyPVFlags(opt, 0) & OPTIONAL_TY_NO_VALUE_SBF) {
		BlkValueError("unwrapped an optional value with no value");
		val = KindDefaultValue(scalar_kind_id);
	}
	if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id)) {
		CopyPV(val, opt-->OPTIONAL_CONTENT_SF);
	} else {
		val = opt-->OPTIONAL_CONTENT_SF;
	}
	return val;
];
