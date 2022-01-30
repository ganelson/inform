[ProducePairs::] Produce Pairs.

Making Inter value pairs for various constants.

@ Simply a convenient way to make |(v1, v2)| pairs, as stored in Inter arrays
or constant definitions, which represent various forms of constant.

First, unsigned integers:

=
void ProducePairs::from_number(inter_tree *I, inter_ti *v1, inter_ti *v2, inter_ti N) {
	*v1 = LITERAL_IVAL;
	*v2 = N;
}

@ Real numbers, which Inter stores in a textual way:

=
void ProducePairs::from_real(inter_tree *I, inter_ti *v1, inter_ti *v2, double g) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I),
		InterBookmark::package(Packaging::at(I)));
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	if (g > 0) WRITE_TO(text_storage, "+");
	WRITE_TO(text_storage, "%g", g);
	*v1 = REAL_IVAL;
	*v2 = ID;
}

void ProducePairs::from_real_text(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *S) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I),
		InterBookmark::package(Packaging::at(I)));
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '$')
			PUT_TO(text_storage, Str::get(pos));
	*v1 = REAL_IVAL;
	*v2 = ID;
}

@ Text:

=
void ProducePairs::from_text(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *text) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I),
		InterBookmark::package(Packaging::at(I)));
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, text);
	*v1 = LITERAL_TEXT_IVAL;
	*v2 = ID;
}

@ Dictionary words, singular and plural:

=
void ProducePairs::from_singular_dword(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *word) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I),
		InterBookmark::package(Packaging::at(I)));
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, word);
	*v1 = DWORD_IVAL;
	*v2 = ID;
}

void ProducePairs::from_plural_dword(inter_tree *I, inter_ti *v1, inter_ti *v2, text_stream *word) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I),
		InterBookmark::package(Packaging::at(I)));
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, word);
	*v1 = PDWORD_IVAL;
	*v2 = ID;
}
