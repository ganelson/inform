[Architectures::] Architectures.

To deal with multiple inter architectures.

@h Architectures.

=
typedef struct inter_architecture {
	struct text_stream *shorthand; /* such as |32d| */
	int sixteen_bit;
	int debug_enabled;
	MEMORY_MANAGEMENT
} inter_architecture;

inter_architecture *Architectures::new(text_stream *code, int s, int d) {
	inter_architecture *A = CREATE(inter_architecture);
	A->shorthand = Str::duplicate(code);
	A->sixteen_bit = s;
	A->debug_enabled = d;
	return A;
}

void Architectures::create(void) {
	Architectures::new(I"16", TRUE, FALSE);
	Architectures::new(I"16d", TRUE, TRUE);
	Architectures::new(I"32", FALSE, FALSE);
	Architectures::new(I"32d", FALSE, TRUE);
}

filename *Architectures::canonical_binary(pathname *P, inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	TEMPORARY_TEXT(leafname);
	WRITE_TO(leafname, "arch-%S.interb", A->shorthand);
	filename *F = Filenames::in_folder(P, leafname);
	DISCARD_TEXT(leafname);
	return F;
}

filename *Architectures::canonical_textual(pathname *P, inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	TEMPORARY_TEXT(leafname);
	WRITE_TO(leafname, "arch-%S.intert", A->shorthand);
	filename *F = Filenames::in_folder(P, leafname);
	DISCARD_TEXT(leafname);
	return F;
}

text_stream *Architectures::to_codename(inter_architecture *A) {
	if (A == NULL) return NULL;
	return A->shorthand;
}

inter_architecture *Architectures::from_codename(text_stream *name) {
	inter_architecture *A;
	LOOP_OVER(A, inter_architecture)
		if (Str::eq_insensitive(A->shorthand, name))
			return A;
	return NULL;
}

int Architectures::is_16_bit(inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	return A->sixteen_bit;
}
int Architectures::debug_enabled(inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	return A->debug_enabled;
}
