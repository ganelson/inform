Vector

The functions needed for "vector" support.

@ See "Writing with Inform" for details.

=
Constant VECTOR_X_SF = SBONLYPV_FIELDS + 0;
Constant VECTOR_Y_SF = SBONLYPV_FIELDS + 1;
Constant VECTOR_Z_SF = SBONLYPV_FIELDS + 2;

[ VECTOR_TY_Say vec;
	print "(", vec-->VECTOR_X_SF, ",", vec-->VECTOR_Y_SF, ",", vec-->VECTOR_Z_SF, ")";
];

[ VECTOR_TY_Compare vec1 vec2 n1 n2 i j d;
	for (i=VECTOR_X_SF: i<=VECTOR_Z_SF: i++) {
		d = vec1-->i - vec2-->i;
		if (d ~= 0) return d;
	}
	return 0;
];

[ VECTOR_TY_Create kind_id sb_address
	short_block;

	short_block = CreatePVShortBlock(sb_address, kind_id);
	short_block-->VECTOR_X_SF = 0;
	short_block-->VECTOR_Y_SF = 0;
	short_block-->VECTOR_Z_SF = 0;

	return short_block;
];

[ VECTOR_TY_Copy vecto vecfrom;
	vecto-->VECTOR_X_SF = vecfrom-->VECTOR_X_SF;
	vecto-->VECTOR_Y_SF = vecfrom-->VECTOR_Y_SF;
	vecto-->VECTOR_Z_SF = vecfrom-->VECTOR_Z_SF;
	return false;
];

[ VECTOR_TY_Fill vec x y z;

	vec-->VECTOR_X_SF = x;
	vec-->VECTOR_Y_SF = y;
	vec-->VECTOR_Z_SF = z;

	return vec;
];

[ VECTOR_TY_Plus vec1 vec2;
	vec1-->VECTOR_X_SF = vec1-->VECTOR_X_SF + vec2-->VECTOR_X_SF;
	vec1-->VECTOR_Y_SF = vec1-->VECTOR_Y_SF + vec2-->VECTOR_Y_SF;
	vec1-->VECTOR_Z_SF = vec1-->VECTOR_Z_SF + vec2-->VECTOR_Z_SF;
	return vec1;
];

[ VECTOR_TY_Minus vec1 vec2;
	vec1-->VECTOR_X_SF = vec1-->VECTOR_X_SF - vec2-->VECTOR_X_SF;
	vec1-->VECTOR_Y_SF = vec1-->VECTOR_Y_SF - vec2-->VECTOR_Y_SF;
	vec1-->VECTOR_Z_SF = vec1-->VECTOR_Z_SF - vec2-->VECTOR_Z_SF;
	return vec1;
];

[ VECTOR_TY_Negate vec1;
	vec1-->VECTOR_X_SF = -(vec1-->VECTOR_X_SF);
	vec1-->VECTOR_Y_SF = -(vec1-->VECTOR_Y_SF);
	vec1-->VECTOR_Z_SF = -(vec1-->VECTOR_Z_SF);
	return vec1;
];

[ VECTOR_TY_Scale vec scalar;
	vec-->VECTOR_X_SF = scalar*vec-->VECTOR_X_SF;
	vec-->VECTOR_Y_SF = scalar*vec-->VECTOR_Y_SF;
	vec-->VECTOR_Z_SF = scalar*vec-->VECTOR_Z_SF;
	return vec;
];

[ VECTOR_TY_DotProduct vec1 vec2;
	return
		(vec1-->VECTOR_X_SF) * (vec2-->VECTOR_X_SF) +
		(vec1-->VECTOR_Y_SF) * (vec2-->VECTOR_Y_SF) +
		(vec1-->VECTOR_Z_SF) * (vec2-->VECTOR_Z_SF);
];
