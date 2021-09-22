[BinaryTarget::] Final Binary Inter.

To create the range of possible targets into which Inter can be converted.

@ This target is very simple: when we get the message to begin generation,
we simply ask the Inter module to output some text, and return true to
tell the generator that nothing more need be done.

=
void BinaryTarget::create_generator(void) {
	code_generator *binary_inter_cgt = Generators::new(I"binary");
	METHOD_ADD(binary_inter_cgt, BEGIN_GENERATION_MTID, BinaryTarget::text);
}

int BinaryTarget::text(code_generator *cgt, code_generation *gen) {
	if (gen->to_file) Inter::Binary::write(gen->to_file, gen->from);
	return TRUE;
}
