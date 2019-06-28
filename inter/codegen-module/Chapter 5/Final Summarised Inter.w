[CodeGen::Summarised::] Final Summarised Inter.

To create the range of possible targets into which Inter can be converted.

@ This target is very simple: when we get the message to begin generation,
we simply ask the Inter module to output some text, and return true to
tell the generator that nothing more need be done.

=
void CodeGen::Summarised::create_target(void) {
	code_generation_target *summary_cgt = CodeGen::Targets::new(I"summary");
	METHOD_ADD(summary_cgt, BEGIN_GENERATION_MTID, CodeGen::Summarised::summary);
}

int CodeGen::Summarised::summary(code_generation_target *cgt, code_generation *gen) {
	if (gen->from_step == NULL) internal_error("temporary generations cannot be output");
	Inter::Summary::write(gen->from_step->text_out_file, gen->from);
	return TRUE;
}
