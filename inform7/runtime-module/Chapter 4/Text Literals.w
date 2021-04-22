[TextLiterals::] Text Literals.

In this section we compile text constants.

@h Runtime representation.
Literal texts arise from source text such as:
= (text as Inform 7)
	let Q be "the quick brown fox";
	say "Where has that indolent hound got to?";
=
Note that only |"the quick brown fox"| is actually a constant value here; the
text concerning the hound is turned directly into operands for Inter instructions
for printing text, and never needs to be a value. The fox text, on the other hand,
is being stored in |Q|, and you can only store values.

Text at runtime is stored in small blocks, always of size 2:
= (text)
	                    small block:
	Q ----------------> format
	                    content
=
The format can be one of four possible alternatives at runtime, and the runtime
system may dynamically switch between them; essentially it uses this to
decompress text from its "packed" form to a character-accessible form only
on demand.

The compiler generates only one of these formats: |CONSTANT_PACKED_TEXT_STORAGE|.
In this format, the |content| can be either a packed string, or a function,
so although there is no long block to make, we do always have something else
to make besides the small block.

In this section, |content| will always be a packed string; in //Text Substitutions//
it will always be a function.

=
inter_name *TextLiterals::small_block(inter_name *content) {
	inter_name *small_block = Enclosures::new_small_block_for_constant();
	packaging_state save = EmitArrays::begin(small_block, K_value);
	EmitArrays::iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
	EmitArrays::iname_entry(content);
	EmitArrays::end(save);
	return small_block;
}

@h Default value.
The default text is empty. It's defined in //BasicInformKit//, but is equivalent
to calling |TextLiterals::small_block(EMPTY_TEXT_PACKED_HL)|.

=
inter_name *TextLiterals::default_text(void) {
	return Hierarchy::find(EMPTY_TEXT_VALUE_HL);
}

@h Suppressing apostrophe substitution.
We are allowed to flag one text where ordinary apostrophe-to-double-quote
substitution doesn't occur: this is used for the title at the top of the
source text, and nothing else.

=
int wn_quote_suppressed = -1;
void TextLiterals::suppress_quote_expansion(wording W) {
	wn_quote_suppressed = Wordings::first_wn(W);
}
int TextLiterals::suppressing_on(wording W) {
	if ((wn_quote_suppressed >= 0) &&
		(Wordings::first_wn(W) == wn_quote_suppressed)) return TRUE;
	return FALSE;
}

@h Making literals.
This was once a rather elegantly complicated algorithm involving searches on
a red-black tree in order to compile the texts in alphabetical order, but in
April 2021 that was replaced by an Inter pipeline stage which collates the text
much later in the process. See //codegen: Consolidate Packed Text//.

=
inter_name *TextLiterals::to_value(wording W) {
	return TextLiterals::to_value_inner(W, FALSE);
}

inter_name *TextLiterals::to_value_unescaped(wording W) {
	return TextLiterals::to_value_inner(W, TRUE);
}

inter_name *TextLiterals::to_value_inner(wording W, int unesc) {
	int w1 = Wordings::first_wn(W);
	if (Wide::cmp(Lexer::word_text(w1), L"\"\"") == 0)
		return Hierarchy::find(EMPTY_TEXT_VALUE_HL);

	inter_name *content_iname = Enclosures::new_iname(LITERALS_HAP, TEXT_LITERAL_HL);
	Produce::annotate_i(content_iname, TEXT_LITERAL_IANN, 1);
	if (Task::wraps_existing_storyfile()) {
		Emit::text_constant(content_iname, I"--");
	} else {
		TEMPORARY_TEXT(TLT)
		int options = CT_DEQUOTE;
		if (TextLiterals::suppressing_on(W) == FALSE) {
			if (unesc == FALSE) options += CT_EXPAND_APOSTROPHES;
			if (RTBibliographicData::in_bibliographic_mode()) {
				options += CT_RECOGNISE_APOSTROPHE_SUBSTITUTION;
				options += CT_RECOGNISE_UNICODE_SUBSTITUTION;
			}
		}
		TranscodeText::from_wide_string(TLT, Lexer::word_text(w1), options);
		Emit::text_constant(content_iname, TLT);
		DISCARD_TEXT(TLT)
	}

	return TextLiterals::small_block(content_iname);
}
