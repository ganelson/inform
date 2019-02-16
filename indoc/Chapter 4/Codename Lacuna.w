[Lacuna::] Codename Lacuna.

The "lacuna" style of navigational gadgets, a plain text style with
no navigational features at all.

@h Creation.

=
navigation_design *Lacuna::create(void) {
	navigation_design *ND = Gadgets::new(I"lacuna", FALSE, TRUE);
	METHOD_ADD(ND, RENDER_CHAPTER_TITLE_MTID, Lacuna::lacuna_chapter_title);
	METHOD_ADD(ND, RENDER_SECTION_TITLE_MTID, Lacuna::lacuna_section_title);
	return ND;
}

@h Top.
At the front end of a section, before any of its text.

=
void Lacuna::lacuna_chapter_title(navigation_design *self, text_stream *OUT, volume *V, chapter *C) {
	WRITE("%S\n\n", C->chapter_full_title);
}

void Lacuna::lacuna_section_title(navigation_design *self, text_stream *OUT, volume *V, chapter *C, section *S) {
	WRITE("\n%c%S\n\n", SECTION_SYMBOL, S->title);
}
