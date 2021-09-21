[CodeGen::Binary::] Final Binary Inter.

To create the range of possible targets into which Inter can be converted.

@ This target is very simple: when we get the message to begin generation,
we simply ask the Inter module to output some text, and return true to
tell the generator that nothing more need be done.

=
void CodeGen::Binary::create_target(void) {
	code_generation_target *binary_inter_cgt = CodeGen::Targets::new(I"binary");
	METHOD_ADD(binary_inter_cgt, BEGIN_GENERATION_MTID, CodeGen::Binary::text);
}

int CodeGen::Binary::text(code_generation_target *cgt, code_generation *gen) {
	if (gen->to_file) Inter::Binary::write(gen->to_file, gen->from);
	return TRUE;
}
