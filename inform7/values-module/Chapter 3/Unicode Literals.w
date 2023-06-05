[UnicodeLiterals::] Unicode Literals.

To manage the names assigned to Unicode character values.

@h Parsing.
The following is called only on excerpts from the source where it is a
fairly safe bet that a Unicode character is referred to. For example, when
the player types either of these:

>> "[unicode 321]odz Churchyard"
>> "[unicode Latin capital letter L with stroke]odz Churchyard"

...then the text after the word "unicode" is parsed by <s-unicode-character>.

=
<s-unicode-character> ::=
	<cardinal-number-unlimited> | ==> { -, Rvalues::from_Unicode(UnicodeLiterals::max(R[1]), W) }
	<unicode-character-name>      ==> { -, Rvalues::from_Unicode(R[1], W) }

<unicode-character-name> internal {
	TEMPORARY_TEXT(N)
	WRITE_TO(N, "%W", W);
	for (int i=0; i<Str::len(N); i++)
		Str::put_at(N, i, Characters::toupper(Str::get_at(N, i)));
	int U = UnicodeLiterals::parse(N);
	DISCARD_TEXT(N)
	if (U >= 0) {
		if ((TargetVMs::is_16_bit(Task::vm())) && (U >= 0x10000)) {
			@<Issue PM_UnicodeOutOfRange@>;
			U = 65;
		}
		==> { UnicodeLiterals::max(U), - };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ And here is the range check. Values above |MAX_UNICODE_CODE_POINT| are
permitted, but need to be specified numerically.

=
int UnicodeLiterals::max(int cc) {
	if (cc < 0) {
		@<Issue PM_UnicodeOutOfRange@>;
		return 65;
	}
	return cc;
}

@<Issue PM_UnicodeOutOfRange@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnicodeOutOfRange),
		"this character value is beyond the range which the current story "
		"could handle",
		"which is from 0 to (hexadecimal) FFFF for stories compiled to the "
		"Z-machine, and otherwise 0 to 1FFFF.");

@h Code points.
Each distinct code point in the Unicode specification will correspond to one
of these:

@d MAX_UNICODE_CODE_POINT 0x20000

@e Cc_UNICODE_CAT from 1 /* Other, Control */
@e Cf_UNICODE_CAT /* Other, Format */
@e Cn_UNICODE_CAT /* Other, Not Assigned: no character actually has this */
@e Co_UNICODE_CAT /* Other, Private Use */
@e Cs_UNICODE_CAT /* Other, Surrogate */
@e Ll_UNICODE_CAT /* Letter, Lowercase */
@e Lm_UNICODE_CAT /* Letter, Modifier */
@e Lo_UNICODE_CAT /* Letter, Other */
@e Lt_UNICODE_CAT /* Letter, Titlecase */
@e Lu_UNICODE_CAT /* Letter, Uppercase */
@e Mc_UNICODE_CAT /* Mark, Spacing Combining */
@e Me_UNICODE_CAT /* Mark, Enclosing */
@e Mn_UNICODE_CAT /* Mark, Non-Spacing */
@e Nd_UNICODE_CAT /* Number, Decimal Digit */
@e Nl_UNICODE_CAT /* Number, Letter */
@e No_UNICODE_CAT /* Number, Other */
@e Pc_UNICODE_CAT /* Punctuation, Connector */
@e Pd_UNICODE_CAT /* Punctuation, Dash */
@e Pe_UNICODE_CAT /* Punctuation, Close */
@e Pf_UNICODE_CAT /* Punctuation, Final quote */
@e Pi_UNICODE_CAT /* Punctuation, Initial quote */
@e Po_UNICODE_CAT /* Punctuation, Other */
@e Ps_UNICODE_CAT /* Punctuation, Open */
@e Sc_UNICODE_CAT /* Symbol, Currency */
@e Sk_UNICODE_CAT /* Symbol, Modifier */
@e Sm_UNICODE_CAT /* Symbol, Math */
@e So_UNICODE_CAT /* Symbol, Other */
@e Zl_UNICODE_CAT /* Separator, Line */
@e Zp_UNICODE_CAT /* Separator, Paragraph */
@e Zs_UNICODE_CAT /* Separator, Space */

=
typedef struct unicode_point {
	int code_point; /* in the range 0 to MAX_UNICODE_CODE_POINT - 1 */
	struct text_stream *name; /* e.g. "RIGHT-FACING ARMENIAN ETERNITY SIGN" */
	int category; /* one of the |*_UNICODE_CAT| values above */
	int tolower; /* -1 if no mapping to lower case is available, or a code point */
	int toupper; /* -1 if no mapping to upper case is available, or a code point */
	int totitle; /* -1 if no mapping to title case is available, or a code point */
} unicode_point;

unicode_point UnicodeLiterals::new_code_point(int C) {
	unicode_point up;
	up.code_point = C;
	up.name = NULL;
	up.category = Cn_UNICODE_CAT; 
	up.tolower = -1;
	up.toupper = -1;
	up.totitle = -1;
	return up;
}

@ Storage for these is managed on demand, in a flexibly-sized array:

=
unicode_point *unicode_points = NULL; /* array indexed by code point */
int unicode_points_extent = 0; /* current number of entries in that array */
int max_known_unicode_point = 0;

unicode_point *UnicodeLiterals::code_point(int U) {
	if ((U < 0) || (U >= MAX_UNICODE_CODE_POINT)) internal_error("Unicode point out of range");
	UnicodeLiterals::ensure_data();
	if (U >= unicode_points_extent) {
		int new_extent = unicode_points_extent;
		if (new_extent == 0) new_extent = 1;
		while (new_extent <= U) new_extent = 2*new_extent;
		unicode_point *new_unicode_points = (unicode_point *)
			(Memory::calloc(new_extent, sizeof(unicode_point), UNICODE_DATA_MREASON));
		for (int i=0; i<unicode_points_extent; i++)
			new_unicode_points[i] = unicode_points[i];
		for (int i=unicode_points_extent; i<new_extent; i++)
			new_unicode_points[i] = UnicodeLiterals::new_code_point(i);
		if (unicode_points_extent > 0)
			Memory::I7_array_free(unicode_points,
				UNICODE_DATA_MREASON, unicode_points_extent, sizeof(unicode_point));
		unicode_points = new_unicode_points;
		unicode_points_extent = new_extent;
	}
	if (U > max_known_unicode_point) max_known_unicode_point = U;
	return &(unicode_points[U]);
}

@ The standard Inform distribution includes the current Unicode specification's
main data file. Although parsing that file is relatively fast, we do it only
on demand, because it's not small (about 2 MB of text) and is often not needed.

The |UnicodeData_lookup| dictionary really associates texts (names of characters)
with non-negative integers (their code points), but our |dictionary| type only
allows texts-to-pointers, so we wrap these integers up into |unicode_lookup_value|
to which we can then have pointers.

(As noted by David Kinder in May 2023, it's unsafe to use this dictionary to
associate texts with |unicode_point *| values, because the flexible-sized array
holding those means that they will move around in memory. If we are lucky, the
memory freed when the old version of the array is surpassed will be left intact
and then the dictionary pointers to it will all work fine: if we are not lucky,
for example if the memory environment is stressed because |intest| is running
many simultaneous copies of Inform, then that space will be reused and the
dictionary pointers will be invalid.)

=
dictionary *UnicodeData_lookup = NULL;
typedef struct unicode_lookup_value {
	int code_point;
} unicode_lookup_value;

void UnicodeLiterals::ensure_data(void) {
	if (UnicodeData_lookup == NULL) {
		UnicodeData_lookup = Dictionaries::new(65536, FALSE);
		filename *F = InstalledFiles::filename(UNICODE_DATA_IRES);
		TextFiles::read(F, FALSE, "can't open UnicodeData file", TRUE,
			&UnicodeLiterals::read_line, NULL, NULL);
		LOG("Read Unicode data to code point 0x%06x in %f\n", max_known_unicode_point, F);
	}
}

@ The format of this file is admirably stable. Lines look like so:
= (text)
	0067;LATIN SMALL LETTER G;Ll;0;L;;;;;N;;;0047;;0047
	1C85;CYRILLIC SMALL LETTER THREE-LEGGED TE;Ll;0;L;;;;;N;;;0422;;0422
	1FAA1;SEWING NEEDLE;So;0;ON;;;;;N;;;;;
=
Each line corresponds to a code point. They're presented in the file in ascending
order of these values, but we make no use of that fact. Each line contains fields
divided by semicolons, and semicolon characters are illegal in any field.

@d CODE_VALUE_UNICODE_DATA_FIELD 0
@d NAME_UNICODE_DATA_FIELD 1
@d GENERAL_CATEGORY_UNICODE_DATA_FIELD 2
@d COMBINING_CLASSES_UNICODE_DATA_FIELD 3
@d BIDIRECTIONAL_CATEGORY_UNICODE_DATA_FIELD 4
@d DECOMPOSITION_MAPPING_UNICODE_DATA_FIELD 5
@d DECIMAL_DIGIT_VALUE_UNICODE_DATA_FIELD 6
@d DIGIT_VALUE_UNICODE_DATA_FIELD 7
@d NUMERIC_VALUE_UNICODE_DATA_FIELD 8
@d MIRRORED_UNICODE_DATA_FIELD 9
@d OLD_NAME_UNICODE_DATA_FIELD 10
@d ISO_10646_COMMENT_UNICODE_DATA_FIELD 11
@d UC_MAPPING_UNICODE_DATA_FIELD 12
@d LC_MAPPING_UNICODE_DATA_FIELD 13
@d TC_MAPPING_UNICODE_DATA_FIELD 14

=
void UnicodeLiterals::read_line(text_stream *text, text_file_position *tfp, void *vm) {
	Str::trim_white_space(text);
	wchar_t c = Str::get_first_char(text);
	if (c == 0) return;
	text_stream *name = Str::new();
	TEMPORARY_TEXT(category)
	int U[16], field_number = 0;
	for (int f=0; f<16; f++) U[f] = 0;
	@<Parse the fields@>;
	if ((field_number > 1) && (U[CODE_VALUE_UNICODE_DATA_FIELD] < MAX_UNICODE_CODE_POINT)) {
		int c = Cn_UNICODE_CAT;
		@<Determine the category code@>;
		unicode_point *up = UnicodeLiterals::code_point(U[CODE_VALUE_UNICODE_DATA_FIELD]);
		@<Initialise the unicode point structure@>;
		@<Add to the dictionary of character names@>;
	}
	DISCARD_TEXT(category)
}

@<Parse the fields@> =
	for (int i=0; i<Str::len(text); i++) {
		wchar_t c = Str::get_at(text, i);
		if (c == ';') field_number++;
		else switch (field_number) {
			case CODE_VALUE_UNICODE_DATA_FIELD:
			case UC_MAPPING_UNICODE_DATA_FIELD:
			case LC_MAPPING_UNICODE_DATA_FIELD:
			case TC_MAPPING_UNICODE_DATA_FIELD: {
				int H = -1;
				if ((c >= '0') && (c <= '9')) H = (int) (c - '0');
				if ((c >= 'A') && (c <= 'F')) H = (int) (c - 'A' + 10);
				if (H >= 0) U[field_number] = U[field_number]*16 + H;
				break;
			}
			case NAME_UNICODE_DATA_FIELD:
				PUT_TO(name, c);
				break;
			case GENERAL_CATEGORY_UNICODE_DATA_FIELD:
				PUT_TO(category, c);
				break;
		}
	}

@<Determine the category code@> =
		 if (Str::eq(category, I"Cc")) c = Cc_UNICODE_CAT;
	else if (Str::eq(category, I"Cf")) c = Cf_UNICODE_CAT;
	else if (Str::eq(category, I"Cn")) c = Cn_UNICODE_CAT;
	else if (Str::eq(category, I"Co")) c = Co_UNICODE_CAT;
	else if (Str::eq(category, I"Cs")) c = Cs_UNICODE_CAT;
	else if (Str::eq(category, I"Ll")) c = Ll_UNICODE_CAT;
	else if (Str::eq(category, I"Lm")) c = Lm_UNICODE_CAT;
	else if (Str::eq(category, I"Lo")) c = Lo_UNICODE_CAT;
	else if (Str::eq(category, I"Lt")) c = Lt_UNICODE_CAT;
	else if (Str::eq(category, I"Lu")) c = Lu_UNICODE_CAT;
	else if (Str::eq(category, I"Mc")) c = Mc_UNICODE_CAT;
	else if (Str::eq(category, I"Me")) c = Me_UNICODE_CAT;
	else if (Str::eq(category, I"Mn")) c = Mn_UNICODE_CAT;
	else if (Str::eq(category, I"Nd")) c = Nd_UNICODE_CAT;
	else if (Str::eq(category, I"Nl")) c = Nl_UNICODE_CAT;
	else if (Str::eq(category, I"No")) c = No_UNICODE_CAT;
	else if (Str::eq(category, I"Pc")) c = Pc_UNICODE_CAT;
	else if (Str::eq(category, I"Pd")) c = Pd_UNICODE_CAT;
	else if (Str::eq(category, I"Pe")) c = Pe_UNICODE_CAT;
	else if (Str::eq(category, I"Pf")) c = Pf_UNICODE_CAT;
	else if (Str::eq(category, I"Pi")) c = Pi_UNICODE_CAT;
	else if (Str::eq(category, I"Po")) c = Po_UNICODE_CAT;
	else if (Str::eq(category, I"Ps")) c = Ps_UNICODE_CAT;
	else if (Str::eq(category, I"Sc")) c = Sc_UNICODE_CAT;
	else if (Str::eq(category, I"Sk")) c = Sk_UNICODE_CAT;
	else if (Str::eq(category, I"Sm")) c = Sm_UNICODE_CAT;
	else if (Str::eq(category, I"So")) c = So_UNICODE_CAT;
	else if (Str::eq(category, I"Zl")) c = Zl_UNICODE_CAT;
	else if (Str::eq(category, I"Zp")) c = Zp_UNICODE_CAT;
	else if (Str::eq(category, I"Zs")) c = Zs_UNICODE_CAT;
	else LOG("Unknown category '%S'\n", category);

@<Initialise the unicode point structure@> =
	up->name = name;
	up->category = c;
	up->tolower = U[LC_MAPPING_UNICODE_DATA_FIELD];
	up->toupper = U[UC_MAPPING_UNICODE_DATA_FIELD];
	up->totitle = U[TC_MAPPING_UNICODE_DATA_FIELD];

@ Control codes in Unicode, a residue of ASCII, are given no names by the
standard. For example:
= (text)
	0004;<control>;Cc;0;BN;;;;;N;END OF TRANSMISSION;;;;
=
Indeed, at present every code with category |Cc| has the pseudo-name |<control>|.
So we will mostly not allow these to be referred to by name in Inform. (In theory we
could read the ISO-10646 comment as if it were a name: here, that would be
"END OF TRANSMISSION", which isn't too bad. But "FORM FEED (FF)" and
"CHARACTER TABULATION" are less persuasive, and anyway, we don't actually want
users to insert control characters into Inform text literals.)

@<Add to the dictionary of character names@> =
	text_stream *index = NULL;
	if (c == Cc_UNICODE_CAT) {
		if (U[CODE_VALUE_UNICODE_DATA_FIELD] == 9) index = I"TAB";
		if (U[CODE_VALUE_UNICODE_DATA_FIELD] == 10) index = I"NEWLINE";
	} else {
		index = name;
	}
	if (index) {
		Dictionaries::create(UnicodeData_lookup, name);
		unicode_lookup_value *ulv = CREATE(unicode_lookup_value);
		ulv->code_point = U[CODE_VALUE_UNICODE_DATA_FIELD];
		Dictionaries::write_value(UnicodeData_lookup, name, (void *) ulv);	
	}

@h Using the Unicode data.
The first lookup here is slow, since it requires us to parse the Unicode
specification data file. But after that everything runs quite swiftly.

=
int UnicodeLiterals::parse(text_stream *N) {
	UnicodeLiterals::ensure_data();
	if (Dictionaries::find(UnicodeData_lookup, N)) {
		unicode_lookup_value *ulv = Dictionaries::read_value(UnicodeData_lookup, N);
		return ulv->code_point;
	}
	return -1;
}

@ We won't go too far down the Unicode rabbit-hole, but here are functions which
may some day be useful:

=
int UnicodeLiterals::tolower(int C) {
	unicode_point *up = UnicodeLiterals::code_point(C);
	int D = up->tolower;
	if (D >= 0) return D;
	return C;
}
int UnicodeLiterals::toupper(int C) {
	unicode_point *up = UnicodeLiterals::code_point(C);
	int D = up->toupper;
	if (D >= 0) return D;
	return C;
}
int UnicodeLiterals::totitle(int C) {
	unicode_point *up = UnicodeLiterals::code_point(C);
	int D = up->totitle;
	if (D >= 0) return D;
	return C;
}
int UnicodeLiterals::category(int C) {
	unicode_point *up = UnicodeLiterals::code_point(C);
	return up->category;
}
