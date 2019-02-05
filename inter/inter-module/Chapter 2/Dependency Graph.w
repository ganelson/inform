[Inter::Graph::] Dependency Graph.

Finding dependencies in definitions.

@ =
inter_error_message *Inter::Graph::show_dependencies(OUTPUT_STREAM, inter_repository *I) {
	WRITE("Dependencies:\n");
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I) {
		inter_error_message *E = Inter::Defn::callback_dependencies(P, &(Inter::Graph::note), OUT);
		if (E) return E;
	}
	return NULL;
}

void Inter::Graph::note(inter_symbol *S, inter_symbol *T, void *state) {
	text_stream *OUT = (text_stream *) state;
	WRITE("  %S depends on %S\n", S?S->symbol_name:I"<none>", T?T->symbol_name:I"<none>");
}

void Inter::Graph::find(void) {
}
