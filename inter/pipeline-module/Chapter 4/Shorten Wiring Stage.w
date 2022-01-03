[ShortenWiringStage::] Shorten Wiring Stage.

To catch missing resources with suitable errors, to remove plugs and sockets
as no longer necessary, and to shorten wiring as much as possible.

@ =
void ShortenWiringStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"shorten-wiring",
		ShortenWiringStage::run, NO_STAGE_ARG, FALSE);
}

@ In practice, linking errors can occur when the source text refers to a function
which doesn't exist in any kit: if the user has mistyped |ExmapleKitFunction|, say,
then the plug would never find a socket with a matching name. We want to catch
and report these errors efficiently, so we keep the bad names in both a dictionary
(for quick lookup) and a list (for reporting).

=
typedef struct plug_inspection_state {
	struct dictionary *bad_plugs;
	struct linked_list *bad_plug_names; /* of |text_stream| */
} plug_inspection_state;

int ShortenWiringStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.repository;
	plug_inspection_state state;
	state.bad_plugs = Dictionaries::new(16, FALSE);
	state.bad_plug_names = NEW_LINKED_LIST(text_stream);
	InterTree::traverse(I, ShortenWiringStage::visitor, &state, NULL, PACKAGE_IST);
	if (LinkedLists::len(state.bad_plug_names) > 0) {
		TEMPORARY_TEXT(NS)
		text_stream *N;
		LOOP_OVER_LINKED_LIST(N, text_stream, state.bad_plug_names) {
			if (Str::len(NS) > 0) WRITE_TO(NS, ", ");
			WRITE_TO(NS, "%S", N);
		}
		PipelineErrors::error_with(step,
			"unable to find definitions for the following name(s): %S", NS);
		DISCARD_TEXT(NS)
		return FALSE;
	}
 	inter_package *connectors = Site::connectors_package(I);
 	if (connectors) {
 		inter_symbols_table *ST = Inter::Packages::scope(connectors);
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if ((Wiring::is_plug(S)) && (Wiring::has_no_incoming_connections(S)))
				Inter::Symbols::remove_from_table(S);
		}
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if ((Wiring::is_socket(S)) && (Wiring::has_no_incoming_connections(S)))
				Inter::Symbols::remove_from_table(S);
		}
		int errors = 0;
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if (S) {
				LOG("Connector not deleted: %3\n", S);
				errors++;
			}
		}
		if (errors > 0) internal_error("plugs and sockets mismanaged");
	}
	return TRUE;
}

@ Note that it is not necessarily an error to have a loose plug, that is, a plug
which does not connect to any socket. It is only an error if a symbol is trying
to connect to this plug. So we make a traverse of the tree to look for such symbols.

Note that we also take the opportunity to simplify chains of equations down to just
the minimum. For example, if we have |S1 -> S2 -> plug -> socket -> T1 -> T2 -> T3|,
we simplify just to |S1 -> T3|.

=
void ShortenWiringStage::visitor(inter_tree *I, inter_tree_node *P, void *v_state) {
	plug_inspection_state *state = (plug_inspection_state *) v_state;
	inter_package *Q = Inter::Package::defined_by_frame(P);
	inter_symbols_table *ST = Inter::Packages::scope(Q);
	for (int i=0; i<ST->size; i++) {
		inter_symbol *S = ST->symbol_array[i];
		inter_symbol *E = Wiring::cable_end(S);
		if (S != E) {
			Wiring::shorten_wiring(S);
			if (Wiring::is_loose_plug(E))
				@<This is an error, because a loose plug has been used@>;
		}
	}
}

@<This is an error, because a loose plug has been used@> =
	text_stream *N = Wiring::plug_name(E);
	if (Dictionaries::find(state->bad_plugs, N) == NULL) {
		Dictionaries::create(state->bad_plugs, N);
		ADD_TO_LINKED_LIST(N, text_stream, state->bad_plug_names);
	}
