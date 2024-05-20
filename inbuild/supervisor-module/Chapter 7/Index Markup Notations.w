[IndexMarkupNotations::] Index Markup Notations.

Lemmas are marked up semantically using all sorts of notations.

@ For example, this code is used to remember that |^^{taking+action+}| is an
index reference to "taking" which should have the style "action". The left
pattern here is empty, while the right pattern is |+action+|.

@d MAX_PATTERN_LENGTH 1024

=
typedef struct index_markup_notation {
	inchar32_t left_pattern[MAX_PATTERN_LENGTH];  /* null-terminated wide C string */
	int left_width;
	inchar32_t right_pattern[MAX_PATTERN_LENGTH]; /* null-terminated wide C string */
	int right_width;
	struct indexing_category *category;
	CLASS_DEFINITION
} index_markup_notation;

index_markup_notation *IndexMarkupNotations::add(compiled_documentation *cd,
	text_stream *L, text_stream *R, indexing_category *category) {
	index_markup_notation *imn = CREATE(index_markup_notation);
	imn->category = category;
	Str::copy_to_wide_string(imn->left_pattern, L, MAX_PATTERN_LENGTH);
	Str::copy_to_wide_string(imn->right_pattern, R, MAX_PATTERN_LENGTH);
	imn->left_width = Str::len(L);
	imn->right_width = Str::len(R);
	ADD_TO_LINKED_LIST(imn, index_markup_notation, cd->id.notations);
	return imn;
}

int IndexMarkupNotations::left_width(index_markup_notation *imn) {
	if (imn == NULL) return 0;
	return imn->left_width;
}

int IndexMarkupNotations::right_width(index_markup_notation *imn) {
	if (imn == NULL) return 0;
	return imn->right_width;
}

indexing_category *IndexMarkupNotations::category(index_markup_notation *imn) {
	return imn->category;
}

index_markup_notation *IndexMarkupNotations::match(compiled_documentation *cd,
	text_stream *text) {
	index_markup_notation *imn;
	LOOP_OVER_LINKED_LIST(imn, index_markup_notation, cd->id.notations)
		if (Str::begins_with_wide_string(text, imn->left_pattern))
			if (Str::ends_with_wide_string(text, imn->right_pattern))
				return imn;
	return NULL;
}
