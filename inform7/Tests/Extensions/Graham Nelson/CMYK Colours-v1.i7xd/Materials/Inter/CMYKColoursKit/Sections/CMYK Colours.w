CMYK Colours

The functions needed for CMYK colour support.

@ See "Writing with Inform" for details.

=
Constant CMYK_NAME_F = 0;
Constant CMYK_CYAN_F = 1;
Constant CMYK_MAGENTA_F = 2;
Constant CMYK_YELLOW_F = 3;
Constant CMYK_BLACK_F = 4;

[ CMYK_COLOUR_TY_Say cmyk;
	TEXT_TY_Say(PVField(cmyk, CMYK_NAME_F));
	print " ink = ";
	print "C:", PVField(cmyk, CMYK_CYAN_F), "% ";
	print "M:", PVField(cmyk, CMYK_MAGENTA_F), "% ";
	print "Y:", PVField(cmyk, CMYK_YELLOW_F), "% ";
	print "K:", PVField(cmyk, CMYK_BLACK_F), "%";
];

[ CMYK_COLOUR_TY_Compare cmyk1 cmyk2 i d;
	d = TEXT_TY_Compare(PVField(cmyk1, CMYK_NAME_F), PVField(cmyk2, CMYK_NAME_F));
	if (d ~= 0) return d;
	for (i=CMYK_CYAN_F: i<=CMYK_BLACK_F: i++) {
		d = PVField(cmyk1, i) - PVField(cmyk2, i);
		if (d ~= 0) return d;
	}
	return 0;
];

[ CMYK_COLOUR_TY_Hash cmyk rv;
	rv = TEXT_TY_Hash(PVField(cmyk, CMYK_NAME_F));
	rv = rv * 33 + PVField(cmyk, CMYK_CYAN_F);
	rv = rv * 33 + PVField(cmyk, CMYK_MAGENTA_F);
	rv = rv * 33 + PVField(cmyk, CMYK_YELLOW_F);
	rv = rv * 33 + PVField(cmyk, CMYK_BLACK_F);
	return rv;
];

Array CMYK_DEFAULT_NAME_TEXT --> PACKED_TEXT_STORAGE "black";

[ CMYK_COLOUR_TY_Create kind_id sb_address
	short_block long_block txt;

	long_block = CreatePVLongBlock(kind_id);
	txt = CreatePV(TEXT_TY);
	CopyPV(txt, CMYK_DEFAULT_NAME_TEXT);
	TEXT_TY_Mutable(txt);
	InitialisePVLongBlockField(long_block, CMYK_NAME_F, txt);
	InitialisePVLongBlockField(long_block, CMYK_CYAN_F, 0);
	InitialisePVLongBlockField(long_block, CMYK_MAGENTA_F, 0);
	InitialisePVLongBlockField(long_block, CMYK_YELLOW_F, 0);
	InitialisePVLongBlockField(long_block, CMYK_BLACK_F, 100);
	
	short_block = CreatePVShortBlock(sb_address, kind_id);
	short_block-->0 = long_block;

	return short_block;
];

[ CMYK_COLOUR_TY_Destroy cmyk;
	DestroyPV(PVField(cmyk, CMYK_NAME_F));
];

[ CMYK_COLOUR_TY_New ink c m y k cmyk;
	cmyk = CreatePV(CMYK_COLOUR_TY);
	CopyPV(PVField(cmyk, CMYK_NAME_F), ink);
	WritePVField(cmyk, CMYK_CYAN_F, c);
	WritePVField(cmyk, CMYK_MAGENTA_F, m);
	WritePVField(cmyk, CMYK_YELLOW_F, y);
	WritePVField(cmyk, CMYK_BLACK_F, k);
	return cmyk;
];

[ CMYK_COLOUR_TY_Copy cmykto cmykfrom kind recycling
	inkfrom inkto;
	CopyPVRawData(cmykto, cmykfrom, kind, recycling);
	inkfrom = PVField(cmykfrom, CMYK_NAME_F);
	inkto = CreatePV(TEXT_TY);
	CopyPV(inkto, inkfrom);
	WritePVField(cmykto, CMYK_NAME_F, inkto);
];
