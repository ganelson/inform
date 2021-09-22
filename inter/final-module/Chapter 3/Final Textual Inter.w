[TextualTarget::] Final Textual Inter.

To create the range of possible targets into which Inter can be converted.

@ This target is very simple: when we get the message to begin generation,
we simply ask the Inter module to output some text, and return true to
tell the generator that nothing more need be done.

=
void TextualTarget::create_generator(void) {
	code_generator *textual_inter_cgt = Generators::new(I"text");
	METHOD_ADD(textual_inter_cgt, BEGIN_GENERATION_MTID, TextualTarget::text);
}

int TextualTarget::text(code_generator *cgt, code_generation *gen) {
	if (gen->to_stream) Inter::Textual::write(gen->to_stream, gen->from, NULL, 1);
	return TRUE;
}
