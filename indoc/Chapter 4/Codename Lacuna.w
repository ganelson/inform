[Lacuna::] Codename Lacuna.

The "lacuna" style of navigational gadgets, a plain text style with
no navigational features at all.

@h Top.
At the front end of a section, before any of its text.

=
void Lacuna::lacuna_volume_title(OUTPUT_STREAM, volume *V) {
}

void Lacuna::lacuna_chapter_title(OUTPUT_STREAM, volume *V, chapter *C) {
	WRITE("%S\n\n", C->chapter_full_title);
}

void Lacuna::lacuna_section_title(OUTPUT_STREAM, volume *V, section *S) {
	WRITE("\n%c%S\n\n", SECTION_SYMBOL, S->title);
}

@h Index top.
And this is a variant for index pages, such as the index of examples.

=
void Lacuna::lacuna_navigation_index_top(OUTPUT_STREAM, text_stream *filename, text_stream *title) {
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Lacuna::lacuna_navigation_middle(OUTPUT_STREAM, volume *V, section *S) {
}

@h Example top.
This is reached before the first example is rendered, provided at least
one example will be:

=
void Lacuna::lacuna_navigation_example_top(OUTPUT_STREAM, volume *V, section *S) {
}

@h Example bottom.
Any closing ornament at the end of examples? This is reached after the
last example is rendered, provided at least one example has been.

=
void Lacuna::lacuna_navigation_example_bottom(OUTPUT_STREAM, volume *V, section *S) {
}

@h Bottom.
At the end of the section, after any example cues and perhaps also example
bodied. (In a section with no examples, this immediately follows the middle.)

=
void Lacuna::lacuna_navigation_bottom(OUTPUT_STREAM, volume *V, section *S) {
}

@h Contents page.

=
void Lacuna::lacuna_navigation_contents_files(void) {
}
