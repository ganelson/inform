Memory Addresses

The functions needed for "memory address" support.

@ See "Writing with Inform" for details.

=
[ MEMORY_ADDRESS_TY_SAY N;
	print "$";
	#iftrue (WORDSIZE == 2);
	PrintInBase(N, 16, 4);
	#ifnot;
	PrintInBase(N, 16, 8);
	#endif;
];

[ MEMORY_ADDRESS_TY_ShowBytes N C
	i;
	for (i=0: i<C: i++) {
		if (i > 0) print " ";
		PrintInBase(N->i, 16, 2);
	}
	print " ~";
	for (i=0: i<C: i++) {
		if ((N->i >= $20) && (N->i < $7f)) print (char) N->i; else print "?";
	}
	print "~";
];

[ MEMORY_ADDRESS_TY_TOKEN wa wl ch n digit;
	wa = WordAddress(wn);
	wl = WordLength(wn);
	#Iftrue CHARSIZE == 1;
	ch = wa->0;
	if (wl > 5) return DECIMAL_TOKEN();
	#Ifnot;
	ch = wa-->0;
	if (wl > 9) return DECIMAL_TOKEN();
	#Endif; ! CHARSIZE
	if (ch ~= '$') return DECIMAL_TOKEN();
	wa = wa + CHARSIZE;
	wl--;
	n = 0;
	while (wl > 0) {
		#Iftrue CHARSIZE == 1;
		ch = wa->0;
		#Ifnot;
		ch = wa-->0;
		#Endif; ! CHARSIZE
		if (ch >= 'a') digit = ch - 'a' + 10;
		else if (ch >= 'A') digit = ch - 'A' + 10;
		else digit = ch - '0';
		if (digit >= 0 && digit < 16) n = 16*n + digit;
		else return GPR_FAIL;
		wl--;
		wa = wa + CHARSIZE;
	}
	parsed_number = n; wn++;
	return GPR_NUMBER;
];
