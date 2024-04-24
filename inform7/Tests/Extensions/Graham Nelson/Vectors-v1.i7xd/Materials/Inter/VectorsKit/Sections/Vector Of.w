Vector Of

The functions needed for "vector of K" support.

@ See "Writing with Inform" for details.

=
Constant VECTOR_OF_X_SF = SBONLYPV_FIELDS + 0;
Constant VECTOR_OF_Y_SF = SBONLYPV_FIELDS + 1;
Constant VECTOR_OF_Z_SF = SBONLYPV_FIELDS + 2;

[ VECTOR_OF_TY_Say vec scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(vec), 0);
	print "(";
	SayKindValuePair(scalar_kind_id, vec-->VECTOR_OF_X_SF);
	print ",";
	SayKindValuePair(scalar_kind_id, vec-->VECTOR_OF_Y_SF);
	print ",";
	SayKindValuePair(scalar_kind_id, vec-->VECTOR_OF_Z_SF);
	print ")";
];

[ VECTOR_OF_TY_Compare vec1 vec2 n1 n2 i d scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(vec1), 0);
	for (i=VECTOR_OF_X_SF: i<=VECTOR_OF_Z_SF: i++) {
		d = CompareKindValuePairs(scalar_kind_id, vec1-->i, scalar_kind_id, vec2-->i);
		if (d ~= 0) return d;
	}
	return 0;
];

[ VECTOR_OF_TY_Create kind_id sb_address
	short_block scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(kind_id, 0);

	short_block = CreatePVShortBlock(sb_address, kind_id);
	
	if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id)) {
		short_block-->VECTOR_OF_X_SF = CreatePV(scalar_kind_id);
		short_block-->VECTOR_OF_Y_SF = CreatePV(scalar_kind_id);
		short_block-->VECTOR_OF_Z_SF = CreatePV(scalar_kind_id);
	} else {
		short_block-->VECTOR_OF_X_SF = KindDefaultValue(scalar_kind_id);
		short_block-->VECTOR_OF_Y_SF = short_block-->VECTOR_OF_X_SF;
		short_block-->VECTOR_OF_Z_SF = short_block-->VECTOR_OF_X_SF;
	}
	
	return short_block;
];

[ VECTOR_OF_TY_Destroy vec scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(vec), 0);
	if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id)) {
		DestroyPV(vec-->VECTOR_OF_X_SF);
		DestroyPV(vec-->VECTOR_OF_Y_SF);
		DestroyPV(vec-->VECTOR_OF_Z_SF);
	}
];

[ VECTOR_OF_TY_Copy vecto vecfrom scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(vecto), 0);
	if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id)) {
		CopyPV(vecto-->VECTOR_OF_X_SF, vecfrom-->VECTOR_OF_X_SF);
		CopyPV(vecto-->VECTOR_OF_Y_SF, vecfrom-->VECTOR_OF_Y_SF);
		CopyPV(vecto-->VECTOR_OF_Z_SF, vecfrom-->VECTOR_OF_Z_SF);
	} else {
		vecto-->VECTOR_OF_X_SF = vecfrom-->VECTOR_OF_X_SF;
		vecto-->VECTOR_OF_Y_SF = vecfrom-->VECTOR_OF_Y_SF;
		vecto-->VECTOR_OF_Z_SF = vecfrom-->VECTOR_OF_Z_SF;
	}
	return false;
];

[ VECTOR_OF_TY_Fill vec x y z scalar_kind_id;
	scalar_kind_id = KindConstructorTerm(KindOfShortBlockOnlyPV(vec), 0);

	if (KindConformsTo_POINTER_VALUE_TY(scalar_kind_id)) {
		CopyPV(vec-->VECTOR_OF_X_SF, x);
		CopyPV(vec-->VECTOR_OF_Y_SF, y);
		CopyPV(vec-->VECTOR_OF_Z_SF, z);
	} else {
		vec-->VECTOR_OF_X_SF = x;
		vec-->VECTOR_OF_Y_SF = y;
		vec-->VECTOR_OF_Z_SF = z;
	}

	return vec;
];
