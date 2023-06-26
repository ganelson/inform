[BinaryInter::] Inter in Binary Files.

To read or write inter between memory and binary files.

@h Compression and the shibboleth.
(Not the name of a band.) A binary Inter file opens with an 20-byte uncompressed
header:

(a) The first four bytes store a big-endian 32-bit word. Its numerical value
is given by the |INTER_SHIBBOLETH| constant, but in fact this is the same as
the ASCII encoding of the letters |intr|.

(b) The second four bytes are all 0. This enables us to distinguish a binary
Inter file from a random text file which just happens to begin with those letters.

(c) Words 2, 3 and 4 are then the three numerical parts of the current Inter
specification's semantic version number. For example, if that were 5.2.4, then
these words would be 5, 2 and 4 respectively.

@d INTER_SHIBBOLETH ((inter_ti) 0x696E7472)

=
int BinaryInter::test_file(filename *F) {
	int verdict = TRUE;
	FILE *fh = BinaryFiles::try_to_open_for_reading(F);
	if (fh == NULL) return FALSE;
	unsigned int X = 0;
	if ((BinaryFiles::read_int32(fh, &X) == FALSE) ||
		((inter_ti) X != INTER_SHIBBOLETH)) verdict = FALSE;
	if ((BinaryFiles::read_int32(fh, &X) == FALSE) ||
		((inter_ti) X != 0)) verdict = FALSE;
	BinaryFiles::close(fh);
	return verdict;
}

@ And this is a version which returns either the semver of Inter used in the
file, or else a null semver if the file isn't binary Inter:

=
semantic_version_number BinaryInter::test_file_version(filename *F) {
	FILE *fh = BinaryFiles::try_to_open_for_reading(F);
	if (fh == NULL) return VersionNumbers::null();
	unsigned int X = 0;
	if ((BinaryFiles::read_int32(fh, &X) == FALSE) ||
		((inter_ti) X != INTER_SHIBBOLETH) ||
		(BinaryFiles::read_int32(fh, &X) == FALSE) ||
		((inter_ti) X != 0)) {
		BinaryFiles::close(fh);
		return VersionNumbers::null();
	}
	unsigned int v1 = 0, v2 = 0, v3 = 0;
	if ((BinaryFiles::read_int32(fh, &v1) == FALSE) ||
		(BinaryFiles::read_int32(fh, &v2) == FALSE) ||
		(BinaryFiles::read_int32(fh, &v3) == FALSE)) {
		BinaryFiles::close(fh);
		return VersionNumbers::null();
	}
	semantic_version_number V = InterVersion::from_three_words(v1, v2, v3);
	BinaryFiles::close(fh);
	return V;
}

@ Once past the header, the data is a flat series of 32-bit values, but many
of those are in practice low values: small integers, ASCII character codes and
the like. Given the Inform GUI apps need to store quite a lot of precompiled
binary Inter files, we can reduce the app's footprint -- by what turns out to be
about 14 MB -- if we compress those files. We do this by writing each word as
a series of 1 to 5 bytes.

@ The following scheme is used on every word after the header:
= (text)
	VALUE               ONE TO FIVE BYTES
	00000000-0000007f	0xxxxxxx
	00000080-00003fff	10xxxxxx	xxxxxxxx
	00004000-001fffff	110xxxxx	xxxxxxxx	xxxxxxxx
	00200000-3fffffff	11111111	xxxxxxxx	xxxxxxxx	xxxxxxxx	xxxxxxxx
	40000000-4000001e	111xxxxx
	4000001f-ffffffff	11111111	xxxxxxxx	xxxxxxxx	xxxxxxxx	xxxxxxxx
=
This is a little like UTF-8, but because there is no need to synchronise from an
arbitrary mid-file position, we can be more economical with bits; and we then
also optimise for the range just above |40000000| because this is |SYMBOL_BASE_VAL|,
and means that references in Inter bytecode to symbols cluster there. See
//Symbols Tables//.

Measurement on the binary Inter form of BasicInformKit, compiled for the 32d
architecture, came out as follows in February 2022:
= (text)
Words in 1 byte(s): 923439
Words in 2 byte(s): 81056
Words in 3 byte(s): 21939
Words in 5 byte(s): 17269
1043703 words, 1237713 bytes: compression 0.296472
=
That is, the compressed file is about 0.295 times the size of what it would be
if no compression were used. Other kits similarly produced 0.294220, 0.286038,
and so on: the ratio was fairly consistent. More could certainly be done (even
these compressed files reduce further if run through gzip), but it would be a
trade-off for complexity. At some point enough is good enough.

@ Compressed data exists only in files: decompression happens as data is read
into memory, and compression happens as it is written to the file.

This is the decoder. It stores the 32-bit unsigned value read in |result|,
and returns |TRUE| if all went well; if a file system error, or end of file,
occurs, then it returns |FALSE| and the contents of |result| are undefined.

=
int BinaryInter::read_word(FILE *binary_file, unsigned int *result) {
	int c1 = getc(binary_file), c2, c3, c4, c5; if (c1 == EOF) return FALSE;
	switch (c1 & 0xE0) {
		case 0:     /* opening byte 000xxxxx */
		case 0x20:  /* opening byte 001xxxxx */
		case 0x40:  /* opening byte 010xxxxx */
		case 0x60:  /* opening byte 011xxxxx */
			*result = (unsigned int) c1; break;
		case 0x80:  /* opening byte 100xxxxx */
		case 0xa0:  /* opening byte 101xxxxx */
			c1 = c1 & 0x3f;
	    	c2 = getc(binary_file); if (c2 == EOF) return FALSE;
			*result = (((unsigned int) c1) << 8) + (unsigned int) c2; break;
		case 0xc0:  /* opening byte 110xxxxx */
	    	c1 = c1 & 0x1f;
	    	c2 = getc(binary_file); if (c2 == EOF) return FALSE;
	    	c3 = getc(binary_file); if (c3 == EOF) return FALSE;
			*result = (((unsigned int) c1) << 16) +
				(((unsigned int) c2) << 8) + (unsigned int) c3; break;
		case 0xe0:  /* opening byte 111xxxxx */
			if (c1 != 0xff) {
				*result = 0x40000000 + (unsigned int) (c1 & 0x1f); break;
			} else {
				c2 = getc(binary_file); if (c2 == EOF) return FALSE;
				c3 = getc(binary_file); if (c3 == EOF) return FALSE;
				c4 = getc(binary_file); if (c4 == EOF) return FALSE;
				c5 = getc(binary_file); if (c5 == EOF) return FALSE;
				*result = (((unsigned int) c2) << 24) +
							(((unsigned int) c3) << 16) +
							(((unsigned int) c4) << 8) + ((unsigned int) c5);
			}
			break;
	}
	return TRUE;
}

@ And this version always returns a word:

=
unsigned int BinaryInter::read_next(FILE *binary_file, inter_error_location *eloc) {
	unsigned int X = 0;
	if (BinaryInter::read_word(binary_file, &X) == FALSE) {
		BinaryInter::read_error(eloc, ftell(binary_file),
			I"binary Inter file incomplete");
		return 0;
	}
	return X;
}

@ And this is the encoder. (Define the symbol |MEASURE_INTER_COMPRESSION| to
see measurements like those above.) We return |FALSE| if some file system error
occurred, making it impossible to write the data.

=
#ifdef MEASURE_INTER_COMPRESSION
int Inter_words_with_byte_count[10] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
#endif

int BinaryInter::write_word(FILE *binary_file, unsigned int val) {
	if (val < 0x80) {
		#ifdef MEASURE_INTER_COMPRESSION
		Inter_words_with_byte_count[1]++;
		#endif
		int c1 = (int) val;
		if (putc(c1, binary_file) == EOF) return FALSE;
	} else if (val < 0x4000) {
		#ifdef MEASURE_INTER_COMPRESSION
		Inter_words_with_byte_count[2]++;
		#endif
		int c1 = 0x80 + (int) (val >> 8);
		int c2 = (int) (val & 0xFF);
		if (putc(c1, binary_file) == EOF) return FALSE;
		if (putc(c2, binary_file) == EOF) return FALSE;
	} else if (val < 0x200000) {
		#ifdef MEASURE_INTER_COMPRESSION
		Inter_words_with_byte_count[3]++;
		#endif
		int c1 = 0xc0 + (int) (val >> 16);
		int c2 = (int) ((val >> 8) & 0xFF);
		int c3 = (int) (val & 0xFF);
		if (putc(c1, binary_file) == EOF) return FALSE;
		if (putc(c2, binary_file) == EOF) return FALSE;
		if (putc(c3, binary_file) == EOF) return FALSE;
	} else if ((val >= 0x40000000) && (val < 0x4000001f)) {
		#ifdef MEASURE_INTER_COMPRESSION
		Inter_words_with_byte_count[1]++;
		#endif
		if (putc((int) (0xe0 + val - 0x40000000), binary_file) == EOF) return FALSE;
	} else {
		#ifdef MEASURE_INTER_COMPRESSION
		Inter_words_with_byte_count[5]++;
		#endif
		int c1 = 0xff;
		int c2 = (int) ((val >> 24) & 0xFF);
		int c3 = (int) ((val >> 16) & 0xFF);
		int c4 = (int) ((val >> 8) & 0xFF);
		int c5 = (int) (val & 0xFF);
		if (putc(c1, binary_file) == EOF) return FALSE;
		if (putc(c2, binary_file) == EOF) return FALSE;
		if (putc(c3, binary_file) == EOF) return FALSE;
		if (putc(c4, binary_file) == EOF) return FALSE;
		if (putc(c5, binary_file) == EOF) return FALSE;
	}
    return TRUE;
}

@ =
void BinaryInter::write_compression_statistics(OUTPUT_STREAM) {
	#ifdef MEASURE_INTER_COMPRESSION
	int tot_words = 0, tot_bytes = 0;
	for (int i=1; i<10; i++)
		if (Inter_words_with_byte_count[i] > 0) {
			WRITE("Words in %d byte(s): %d\n", i, Inter_words_with_byte_count[i]);
			tot_words += Inter_words_with_byte_count[i];
			tot_bytes += i*Inter_words_with_byte_count[i];
		}
	WRITE("%d words, %d bytes: compression %g\n", tot_words, tot_bytes,
		((double) tot_bytes)/((double) (4*tot_words)));
	#endif
}

@ Conventionally, texts are stored as a sequence of words:
= (text)
	0	length word L (= 0 for the empty text)
	1	first character
	...
	L	last character
=
So, note, this is not a C-style null terminated string.

=
void BinaryInter::read_text(FILE *binary_file, text_stream *T, inter_error_location *eloc) {
	unsigned int L = BinaryInter::read_next(binary_file, eloc);
	for (unsigned int i=0; i<L; i++) {
		unsigned int c = BinaryInter::read_next(binary_file, eloc);
		PUT_TO(T, (wchar_t) c);
	}
}

void BinaryInter::write_text(FILE *binary_file, text_stream *T) {
	BinaryInter::write_word(binary_file, (unsigned int) Str::len(T));
	LOOP_THROUGH_TEXT(pos, T)
		BinaryInter::write_word(binary_file, (unsigned int) Str::get(pos));
}

@h Reading and writing inter to binary.
So much for the encoding: now for the content, that is, what those words of
data actually are. The following functions to read and write binary Inter
files are presented in an interleaved way, showing each reader alongside its
corresponding writer.

Still, let's do the file-handling first:

=
void BinaryInter::read(inter_tree *I, filename *F) {
	LOGIF(INTER_FILE_READ, "(Reading binary inter file %f)\n", F);
	long int max_offset = BinaryFiles::size(F);
	FILE *fh = BinaryFiles::open_for_reading(F);
	inter_error_location eloc = InterErrors::interb_location(F, 0);
	inter_bookmark at = InterBookmark::at_start_of_this_repository(I);
	inter_warehouse *warehouse = InterTree::warehouse(I);
	inter_ti *grid = NULL;
	inter_ti grid_extent = 0;
	InterInstruction::suspend_cross_referencing(I);
	@<Read the content@>;
	if (grid) Memory::I7_array_free(grid, INTER_BYTECODE_MREASON,
		(int) grid_extent, sizeof(inter_ti));
	Primitives::index_primitives_in_tree(I);
	InterInstruction::resume_cross_referencing(I);
	InterInstruction::tree_lint(I);
	BinaryFiles::close(fh);
}

void BinaryInter::write(filename *F, inter_tree *I) {
	LOGIF(INTER_FILE_READ, "(Writing binary inter file %f)\n", F);
	FILE *fh = BinaryFiles::open_for_writing(F);
	inter_warehouse *warehouse = InterTree::warehouse(I);
	@<Write the content@>;
	BinaryFiles::close(fh);
	BinaryInter::write_compression_statistics(STDOUT);
}

@ The file is organised in five blocks:

@<Read the content@> =
	@<Read the header@>;
	@<Read the annotations@>;
	@<Read the resources@>;
	@<Read the symbol wirings@>;
	@<Read the bytecode@>;

@<Write the content@> =
	@<Write the header@>;
	@<Write the annotations@>;
	@<Write the resources@>;
	@<Write the symbol wirings@>;
	@<Write the bytecode@>;

@ The header is uncompressed, so we call |BinaryFiles::read_int32| and
|BinaryFiles::write_int32| from //foundation//.

@<Read the header@> =
	unsigned int X = 0;
	if ((BinaryFiles::read_int32(fh, &X) == FALSE) ||
		((inter_ti) X != INTER_SHIBBOLETH) ||
		(BinaryFiles::read_int32(fh, &X) == FALSE) ||
		((inter_ti) X != 0)) {
		BinaryInter::read_error(&eloc, 0, I"not a binary inter file");
		BinaryFiles::close(fh);
		return;
	}
	unsigned int v1 = 0, v2 = 0, v3 = 0;
	if ((BinaryFiles::read_int32(fh, &v1) == FALSE) ||
		(BinaryFiles::read_int32(fh, &v2) == FALSE) ||
		(BinaryFiles::read_int32(fh, &v3) == FALSE)) {
		BinaryInter::read_error(&eloc, 0, I"header breaks off");
		BinaryFiles::close(fh);
		return;
	}
	semantic_version_number file_version = InterVersion::from_three_words(v1, v2, v3);
	if (InterVersion::check_readable(file_version) == FALSE) {
		semantic_version_number current_version = InterVersion::current();
		TEMPORARY_TEXT(erm)
		WRITE_TO(erm,
			"file '%f' holds Inter written for specification v%v, but I expect v%v",
			F, &file_version, &current_version);
		BinaryInter::read_error(&eloc, 0, erm);
		DISCARD_TEXT(erm)
	}

@<Write the header@> =
	BinaryFiles::write_int32(fh, (unsigned int) INTER_SHIBBOLETH);
	BinaryFiles::write_int32(fh, (unsigned int) 0);
	unsigned int v1 = 0, v2 = 0, v3 = 0;
	InterVersion::to_three_words(&v1, &v2, &v3);
	BinaryFiles::write_int32(fh, v1);
	BinaryFiles::write_int32(fh, v2);
	BinaryFiles::write_int32(fh, v3);

@ Next we have to describe the possible range of //Annotations//. We need these
now, because they will be referred to in the symbol definitions in the
resource block later on.

This block is a sequence of records like so:
= (text)
	Word	Annotation ID
	Text	Name
	Word	Annotation type (a |*_IATYPE| value)
=
terminated by the sentinel word |INVALID_IANN|. There cannot be two blocks with
the same annotation ID; the order of blocks is not meaningful. In particular,
they are not necessarily in increasing order of ID.

@<Read the annotations@> =
	inter_ti ID = INVALID_IANN;
	while (BinaryInter::read_word(fh, &ID)) {
		if (ID == INVALID_IANN) break;
		TEMPORARY_TEXT(keyword)
		BinaryInter::read_text(fh, keyword, &eloc);
		unsigned int iatype = BinaryInter::read_next(fh, &eloc);
		if (SymbolAnnotation::declare(ID, keyword, (int) iatype) == FALSE) {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "conflicting annotation name '%S'", keyword);
			BinaryInter::read_error(&eloc, ftell(fh), err);
			DISCARD_TEXT(err)
		}
		DISCARD_TEXT(keyword)
	}

@<Write the annotations@> =
	inter_annotation_form *IAF;
	LOOP_OVER(IAF, inter_annotation_form)
		if (IAF->annotation_ID != INVALID_IANN) {
			BinaryInter::write_word(fh, IAF->annotation_ID);
			BinaryInter::write_text(fh, IAF->annotation_keyword);
			BinaryInter::write_word(fh, (unsigned int) IAF->iatype);
		}
	BinaryInter::write_word(fh, INVALID_IANN);

@ There follows a block of resources. This consists of a single word giving
the count of the number of resources (which may be 0); then a table of warehouse
IDs; then a table of metadata for the resources.

@<Read the resources@> =
	unsigned int count = BinaryInter::read_next(fh, &eloc);
	@<Read the table of warehouse ID numbers@>;
	@<Read the table of resources proper@>;

@<Write the resources@> =
	inter_ti count = 0;
	LOOP_OVER_RESOURCE_IDS(n, I) count++;
	BinaryInter::write_word(fh, (unsigned int) count);
	@<Write the table of warehouse ID numbers@>;
	@<Write the table of resources proper@>;

@ A problem we must deal with is that the bytecode for the original tree will
have been full of references to texts, and such, by means of their warehouse ID
numbers. As we read in this data, we can and will mimic the texts that those
numbers were referring to: but we cannot expect them to have the same IDs in
our warehouse that they had in the original.

For example, suppose a tree contained the text |"passacaglia"| at warehouse ID 34;
that this tree was then saved out as a binary Inter file; and that we are now
reading that binary file in. We can certainly make a text reading |"passacaglia"|,
but there is no reason to expect (and no way to oblige) it to have warehouse ID 34
in our tree |I|.

Because of that we will need to keep careful track of how IDs in the binary file
compare to those in our tree in memory. This is the purpose of the |grid| array.
So, for example, |grid[34]| is the ID for the string where our copy of
|"passacaglia"| goes.

The grid is read in from a table whose first word is the maximum warehouse ID
ever used in the original file, plus 1; and then is a list of words giving
the warehouse IDs for the resources in turn.

@<Read the table of warehouse ID numbers@> =
	grid_extent = BinaryInter::read_next(fh, &eloc);
	if (grid_extent > 0) {
		grid = (inter_ti *) Memory::calloc((int) grid_extent, sizeof(inter_ti),
			INTER_BYTECODE_MREASON);
		for (inter_ti i=0; i<grid_extent; i++) grid[i] = 0;
		for (inter_ti i=0; i<count; i++) {
			unsigned int original_ID = BinaryInter::read_next(fh, &eloc);
			inter_ti n;
			switch (i) {
				case 0: n = InterTree::global_scope(I)->resource_ID; break;
				case 1: n = InterTree::root_package(I)->resource_ID; break;
				default: n = InterWarehouse::create_resource(warehouse); break;
			}
			if (original_ID >= grid_extent) {
				original_ID = grid_extent-1;
				BinaryInter::read_error(&eloc, ftell(fh), I"max incorrect");
			}
			grid[original_ID] = n;
		}
	}
	
@<Write the table of warehouse ID numbers@> =
	inter_ti max = 0;
	LOOP_OVER_RESOURCE_IDS(n, I)
		if (n+1 > max)
			max = n+1;
	BinaryInter::write_word(fh, (unsigned int) max);
	LOOP_OVER_RESOURCE_IDS(n, I)
		BinaryInter::write_word(fh, (unsigned int) n);

@ The table of resources is then a series of records, one for each resource.
Each record begins with a type word, which must be one of the |*_IRSRC| values.
After that, the content (and record length) depends on the type.

The first two resources in this table are always:

(i) the symbols table for the root package, which holds global symbols such
as primitive names; and

(ii) the root package itself.

The sequence is otherwise not meaningful. It should not be assumed that
resources will be in increasing warehouse ID order.

@<Read the table of resources proper@> =		
	for (inter_ti i=0; i<count; i++) {
		unsigned int original_ID = BinaryInter::read_next(fh, &eloc);
		if ((original_ID == 0) || (original_ID >= grid_extent)) {
			BinaryInter::read_error(&eloc, ftell(fh), I"warehouse ID out of range");
			original_ID = grid_extent - 1;
		}
		inter_ti ID = grid[original_ID];
		unsigned int X = BinaryInter::read_next(fh, &eloc);
		switch (X) {
			case TEXT_IRSRC:          @<Read a string resource@>; break;
			case SYMBOLS_TABLE_IRSRC: @<Read a symbols table resource@>; break;
			case NODE_LIST_IRSRC:     @<Read a node list resource@>; break;
			case PACKAGE_REF_IRSRC:   @<Read a package resource@>; break;
			default: BinaryInter::read_error(&eloc, ftell(fh), I"unknown resource type");
		}
	}

@<Write the table of resources proper@> =
	LOOP_OVER_RESOURCE_IDS(ID, I) {
		inter_ti RT = InterWarehouse::resource_type_code(warehouse, ID);
		BinaryInter::write_word(fh, (unsigned int) ID);
		BinaryInter::write_word(fh, RT);
		switch (RT) {
			case TEXT_IRSRC:          @<Write a string resource@>; break;
			case SYMBOLS_TABLE_IRSRC: @<Write a symbols table resource@>; break;
			case PACKAGE_REF_IRSRC:   @<Write a package resource@>; break;
			case NODE_LIST_IRSRC:     @<Write a node list resource@>; break;
			default: internal_error("unimplemented resource type");
		}
	}

@ A text resource is |TEXT_IRSRC| followed by a single text, giving its content.

@<Read a string resource@> =
	text_stream *txt = Str::new();
	InterWarehouse::create_ref_at(warehouse, ID, STORE_POINTER_text_stream(txt), NULL);
	BinaryInter::read_text(fh, txt, &eloc);

@<Write a string resource@> =
	text_stream *txt = InterWarehouse::get_text(warehouse, ID);
	BinaryInter::write_text(fh, txt);

@ A symbols table resource is |SYMBOLS_TABLE_IRSRC| followed by a list of records,
one for each symbol:
= (text)
	word	ID within the symbols table (always SYMBOL_BASE_VAL or greater, so nonzero)
	word	symbol type (one of the |*_ISYMT| values)
	word	persistent flags
	text	identifier of the symbol
	table	annotations table (see below)
	text	text this symbol is wired to (if it is a plug: otherwise, omitted)
=

@<Read a symbols table resource@> =
	inter_symbols_table *tab = InterWarehouse::get_symbols_table(warehouse, ID);
	if (tab == NULL) {
		tab = InterSymbolsTable::new(ID);
		InterWarehouse::create_ref_at(warehouse, ID,
			STORE_POINTER_inter_symbols_table(tab), NULL);
	}
	unsigned int symbol_ID = 0;
	while (BinaryInter::read_word(fh, &symbol_ID)) {
		if (symbol_ID == 0) break;
		TEMPORARY_TEXT(identifier)
		unsigned int st = BinaryInter::read_next(fh, &eloc);
		unsigned int flags = BinaryInter::read_next(fh, &eloc);
		BinaryInter::read_text(fh, identifier, &eloc);
		inter_symbol *S = InterSymbolsTable::symbol_from_name_creating_at_ID(tab,
			identifier, symbol_ID);
		InterSymbol::set_type(S, (int) st);
		InterSymbol::set_persistent_flags(S, (int) flags);
		@<Read the annotations for a symbol@>;
		if (InterSymbol::is_plug(S)) {
			TEMPORARY_TEXT(N)
			BinaryInter::read_text(fh, N, &eloc);
			Wiring::wire_to_name(S, N);
			DISCARD_TEXT(N)
		}
		LOGIF(INTER_BINARY, "Read symbol $3\n", S);
		DISCARD_TEXT(identifier)
	}

@<Write a symbols table resource@> =
	inter_symbols_table *T = InterWarehouse::get_symbols_table(warehouse, ID);
	if (T) {
		LOOP_OVER_SYMBOLS_TABLE(S, T) {
			BinaryInter::write_word(fh, S->symbol_ID);
			BinaryInter::write_word(fh, (unsigned int) InterSymbol::get_type(S));
			BinaryInter::write_word(fh, (unsigned int) InterSymbol::get_persistent_flags(S));
			BinaryInter::write_text(fh, InterSymbol::identifier(S));
			@<Write the annotations for a symbol@>;
			if (InterSymbol::is_plug(S)) {
				text_stream *N = Wiring::wired_to_name(S);
				BinaryInter::write_text(fh, N);
			}
		}
	}
	BinaryInter::write_word(fh, 0);

@ The annotations table for a single symbol begins with a word in the form
|(bm << 6) + n|, where |bm| is the bitmap of its boolean annotations, and |n|
is the number of non-boolean ones it has -- which might be 0.

This word is then followed by |n| pairs:
= (text)
	word	non-boolean annotation ID
	word	non-boolean annotation value
=
The meaning of the value depends on the annotation type.

@<Read the annotations for a symbol@> =
	unsigned int bm = BinaryInter::read_next(fh, &eloc);
	S->annotations.boolean_annotations |= (bm / 0x20);
	unsigned int L = bm & 0x1f;
	for (unsigned int i=0; i<L; i++) {
		unsigned int c1 = BinaryInter::read_next(fh, &eloc);
		unsigned int c2 = BinaryInter::read_next(fh, &eloc);
		inter_annotation IA = SymbolAnnotation::from_pair(c1, c2);
		if (SymbolAnnotation::is_invalid(IA))
			BinaryInter::read_error(&eloc, ftell(fh), I"invalid annotation");
		if ((grid) && (IA.annot->iatype == TEXTUAL_IATYPE))
			IA.annot_value = grid[IA.annot_value];
		SymbolAnnotation::set(-1, S, IA);
	}

@<Write the annotations for a symbol@> =
	inter_annotation_set *set = &(S->annotations);
	BinaryInter::write_word(fh,
		0x20*((unsigned int) set->boolean_annotations) +
		(unsigned int) LinkedLists::len(set->other_annotations));
	if (set->other_annotations) {
		inter_annotation *A;
		LOOP_OVER_LINKED_LIST(A, inter_annotation, set->other_annotations) {
			inter_ti c1 = 0, c2 = 0;
			SymbolAnnotation::to_pair(*A, &c1, &c2);
			BinaryInter::write_word(fh, (unsigned int) c1);
			BinaryInter::write_word(fh, (unsigned int) c2);
		}
	}

@ A package resource is |PACKAGE_REF_IRSRC| followed by:
= (text)
	word	warehouse ID of parent package, or 0 for the root package
	word	persistent package flags
	word	warehouse ID of symbols table
	text	package name
=
The name isn't used much here, and it's arguably wasteful to store it: the
alternative would be to use some further flags marking the identity of certain
special packages (such as |connectors|). But having the names of packages be
easy to determine from the binary Inter file seems no bad thing, and it doesn't
consume so very many extra bytes. Package names are short and compress well.

@<Read a package resource@> =
	unsigned int parent_package_resource_ID = BinaryInter::read_next(fh, &eloc);
	unsigned int flags = BinaryInter::read_next(fh, &eloc);
	unsigned int symbols_table_resource_ID = BinaryInter::read_next(fh, &eloc);
	inter_package *parent = NULL;
	if (parent_package_resource_ID != 0) {
		if (grid) parent_package_resource_ID = grid[parent_package_resource_ID];
		parent = InterWarehouse::get_package(warehouse, parent_package_resource_ID);
	}
	inter_package *stored_package = InterWarehouse::get_package(warehouse, ID);
	if (stored_package == NULL) {
		stored_package = InterPackage::new(I, ID);
		InterWarehouse::create_ref_at(warehouse, ID,
			STORE_POINTER_inter_package(stored_package), stored_package);
	}
	InterPackage::set_persistent_flags(stored_package, (int) flags);
	if (symbols_table_resource_ID != 0) {
		if (grid) symbols_table_resource_ID = grid[symbols_table_resource_ID];
		InterPackage::set_scope(stored_package,
			InterWarehouse::get_symbols_table(warehouse, symbols_table_resource_ID));
	}
	TEMPORARY_TEXT(N)
	BinaryInter::read_text(fh, N, &eloc);
	LargeScale::note_package_name(I, stored_package, N);
	DISCARD_TEXT(N)

@<Write a package resource@> =
	inter_package *P = InterWarehouse::get_package(warehouse, ID);
	if (P == NULL) internal_error("no package for warehouse ID");
	inter_package *par = InterPackage::parent(P);
	if (par == NULL) BinaryInter::write_word(fh, 0);
	else BinaryInter::write_word(fh, (unsigned int) par->resource_ID);
	BinaryInter::write_word(fh, (unsigned int) InterPackage::get_persistent_flags(P));
	BinaryInter::write_word(fh, P->package_scope->resource_ID);
	BinaryInter::write_text(fh, InterPackage::name(P));

@ A node list resource consists only of the word |NODE_LIST_IRSRC|, with no
further data. That's because node lists are built fresh as instructions are
read in. So on writing we need do nothing, and on reading, we only need to
create the empty node list.

@<Read a node list resource@> =
	if (InterWarehouse::get_node_list(warehouse, ID) == 0)
		InterWarehouse::create_ref_at(warehouse, ID,
			STORE_POINTER_inter_node_list(InterNodeList::new()), NULL);

@<Write a node list resource@> =
	;

@ Now for the symbol wiring block. This has to be here, after all the symbols
tables and packages have been made, so that cross-references can be sorted out.
The block records all pairs |S1| and |S2| such that |S1 ~~> S2|; note that it
does not record wirings to names, only wirings to symbols.

Rather than storing these pairs in no order, we group them by the origin table,
that is, by the symbols table holding |S1|. So the block consists of one record
for each table which needs to make some wirings:
= (text)
	word	warehouse ID of symbols table holding S1
	table	wirings in this table
=
This is terminated by a 0 word, which is safe since 0 is never a valid warehouse
ID: see //The Warehouse//. The sub-table of wirings is then a sequence of these:
= (text)
		word	symbol ID in this table of S1
		word 	warehouse ID of symbols table holding S2
		word	symbol ID in that table of S2
=
Again, this is null-terminated, which is safe since all symbol IDs are at least
|SYMBOL_BASE_VAL|, a huge number.

@<Read the symbol wirings@> =
	unsigned int S1_table_ID = 0;
	while (BinaryInter::read_word(fh, &S1_table_ID)) {
		if (S1_table_ID == 0) break;
		if (grid) S1_table_ID = grid[S1_table_ID];
		inter_symbols_table *S1_table = InterWarehouse::get_symbols_table(warehouse, S1_table_ID);
		if (S1_table == NULL)
			BinaryInter::read_error(&eloc, ftell(fh), I"invalid symbols table in wiring");
		unsigned int S1_symbol_ID = 0;
		while (BinaryInter::read_word(fh, &S1_symbol_ID)) {
			if (S1_symbol_ID == 0) break;
			unsigned int S2_table_ID = BinaryInter::read_next(fh, &eloc);
			if (grid) S2_table_ID = grid[S2_table_ID];
			unsigned int S2_symbol_ID = BinaryInter::read_next(fh, &eloc);
			inter_symbols_table *S2_table = InterWarehouse::get_symbols_table(warehouse, S2_table_ID);
			if (S1_table == NULL)
				BinaryInter::read_error(&eloc, ftell(fh), I"invalid symbols table in wiring");
			inter_symbol *S1 = InterSymbolsTable::symbol_from_ID(S1_table, S1_symbol_ID);
			inter_symbol *S2 = InterSymbolsTable::symbol_from_ID(S2_table, S2_symbol_ID);
			if ((S1 == NULL) || (S2 == NULL))
				BinaryInter::read_error(&eloc, ftell(fh), I"invalid symbols in wiring");
			Wiring::wire_to(S1, S2);
		}
	}

@<Write the symbol wirings@> =
	LOOP_OVER_RESOURCE_IDS(ID, I) {
		inter_symbols_table *from_T = InterWarehouse::get_symbols_table(warehouse, ID);
		if (from_T) {
			int table_needed = FALSE;
			LOOP_OVER_SYMBOLS_TABLE(S, from_T) {
				if (Wiring::is_wired(S)) {
					if (table_needed == FALSE) {
						BinaryInter::write_word(fh, (unsigned int) ID);
						table_needed = TRUE;
					}
					inter_symbol *W = Wiring::wired_to(S);
					BinaryInter::write_word(fh, S->symbol_ID);
					BinaryInter::write_word(fh, W->owning_table->resource_ID);
					BinaryInter::write_word(fh, W->symbol_ID);
				}
			}
			if (table_needed) BinaryInter::write_word(fh, 0);
		}
	}
	BinaryInter::write_word(fh, 0);

@ Finally the bytecode block. Surprisingly, this is easy to handle here, but
only because a non-trivial part of the process is handled elsewhere.

Note that this loop continues until the file runs out.

@<Read the bytecode@> =
	unsigned int X = 0;
	while (BinaryInter::read_word(fh, &X)) {
		inter_package *owner = NULL;
		int extent = (int) X;
		@<Read the preframe@>;
		inter_tree_node *P = Inode::new_node(warehouse, I, extent-1, &eloc, owner);
		@<Read the frame@>;
		@<Correct and verify the frame@>;
		NodePlacement::move_to_moving_bookmark(P, &at);
	}

@<Write the bytecode@> =
	InterTree::traverse_root_only(I, BinaryInter::frame_writer, fh, -PACKAGE_IST);
	InterTree::traverse(I, BinaryInter::frame_writer, fh, NULL, 0);

@ =
void BinaryInter::frame_writer(inter_tree *I, inter_tree_node *P, void *state) {
	FILE *fh = (FILE *) state;
	@<Write the preframe@>;
	@<Write the frame@>;
}

@<Read the preframe@> =
	eloc.error_offset = (size_t) ftell(fh) - PREFRAME_SIZE;
	if ((extent < 2) || ((long int) extent >= max_offset))
		BinaryInter::read_error(&eloc, ftell(fh), I"wildly overlarge instruction frame");
	unsigned int PID = 0;
	if (BinaryInter::read_word(fh, &PID)) {
		if (grid) PID = grid[PID];
		if (PID) owner = InterWarehouse::get_package(warehouse, PID);
	}

@<Write the preframe@> =
	BinaryInter::write_word(fh, (unsigned int) (P->W.extent + 1));
	BinaryInter::write_word(fh, (unsigned int) (Inode::get_package(P)->resource_ID));

@<Read the frame@> =
	for (int i=0; i<extent-1; i++) {
		unsigned int word = BinaryInter::read_next(fh, &eloc);
		P->W.instruction[i] = word;
	}

@<Write the frame@> =
	for (int i=0; i<P->W.extent; i++)
		BinaryInter::write_word(fh, (unsigned int) (P->W.instruction[i]));

@ That just leaves the process of correction. We do two things:

(a) Transposition: this means correcting all references to warehouse IDs in the
old tree into references to those in the new, by performing |id = grid[id]|.
We cannot do this without knowing which words in the bytecode are warehouse IDs,
though, so we must call a method of the construct for the instruction.

(b) Verification: also construct-specific, also done via a method call, this not
only performs sanity checks on the bytecode for the instruction but also
completes the process of embedding the instruction by, for example, setting
the definition of any symbol created in the instruction to |P|.

@<Correct and verify the frame@> =
	inter_error_message *E = NULL;
	if (grid) E = InterInstruction::transpose_construct(owner, P, grid, grid_extent);
	if (E) { InterErrors::issue(E); exit(1); }
	E = VerifyingInter::instruction(owner, P);
	if (E) { InterErrors::issue(E); exit(1); }

@ Errors in reading binary inter are not recoverable:

=
void BinaryInter::read_error(inter_error_location *eloc, long at, text_stream *err) {
	eloc->error_offset = (size_t) at;
	InterErrors::issue(InterErrors::plain(err, eloc));
	exit(1);
}
