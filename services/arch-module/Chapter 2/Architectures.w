[Architectures::] Architectures.

To deal with multiple inter architectures.

@h Architectures.
An "architecture" is a choice of how to use Inter code: for example, with the
expectation that it will have 32-bit rather than 16-bit integers. These are
not different Inter formats: two Inter files could, in fact, be identical
and yet one could be intended to be code-generated to a 32-bit program
and another to 16-bit. In effect, an "architecture" holds the settings which
//inform7// uses when turning source text into Inter code.

Each different architecture is represented by one of these:

=
typedef struct inter_architecture {
	struct text_stream *shorthand; /* such as |32d| */
	int sixteen_bit;
	int debug_enabled;
	CLASS_DEFINITION
} inter_architecture;

@ =
inter_architecture *Architectures::new(text_stream *code, int s, int d) {
	inter_architecture *A = CREATE(inter_architecture);
	A->shorthand = Str::duplicate(code);
	A->sixteen_bit = s;
	A->debug_enabled = d;
	return A;
}

@h Standard set.
This is called when the //arch// module starts up; no other architectures
are ever made.

=
void Architectures::create(void) {
	Architectures::new(I"16", TRUE, FALSE);
	Architectures::new(I"16d", TRUE, TRUE);
	Architectures::new(I"32", FALSE, FALSE);
	Architectures::new(I"32d", FALSE, TRUE);
}

@h Canonical filenames.
When a kit is built, its Inter code is stored in files with these leafnames:

=
filename *Architectures::canonical_binary(pathname *P, inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	TEMPORARY_TEXT(leafname)
	WRITE_TO(leafname, "arch-%S.interb", A->shorthand);
	filename *F = Filenames::in(P, leafname);
	DISCARD_TEXT(leafname)
	return F;
}

filename *Architectures::canonical_textual(pathname *P, inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	TEMPORARY_TEXT(leafname)
	WRITE_TO(leafname, "arch-%S.intert", A->shorthand);
	filename *F = Filenames::in(P, leafname);
	DISCARD_TEXT(leafname)
	return F;
}

@h Shorthand.
These functions turn an architecture into a text like |16d| and back again:

=
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

inter_architecture *Architectures::from_codename_with_hint(text_stream *name, int debug) {
	inter_architecture *A = Architectures::from_codename(name);
	if ((A) && (debug)) {
		inter_architecture *B;
		LOOP_OVER(B, inter_architecture)
			if ((B->sixteen_bit == A->sixteen_bit) && (B->debug_enabled) && (debug == TRUE)) 
				return B;
	}
	return A;
}

@h What an architecture offers.
At present, this all there is, so in a sense all possible architectures exist:

=
int Architectures::is_16_bit(inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	return A->sixteen_bit;
}
int Architectures::debug_enabled(inter_architecture *A) {
	if (A == NULL) internal_error("no arch");
	return A->debug_enabled;
}
