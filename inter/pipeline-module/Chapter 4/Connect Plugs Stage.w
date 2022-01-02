[ConnectPlugsStage::] Connect Plugs Stage.

To reconcile symbol references made across compilation unit boundaries.

@ See //bytecode: Connectors// for more, but consider this example:
= (text as Inform 7)
To call the kit: (- ExampleKitFunction(); -).

To begin:
	call the kit.
=
The //inform7// compiler makes a main source tree out of this. It doesn't have
a definition of |ExampleKitFunction|; that's defined in, say, |HypotheticalKit|,
which is being linked in after compilation. Indeed, the compiler has no way
even to know where in the package hierarchy of the Inter tree for |HypotheticalKit|
this function will be. What to do?

What it does is to create a symbol |S| representing the function which equates like so:
= (text)
	main
		source_text
			S (regular symbol) ->   main
										connectors
										    ExampleKitFunction (plug symbol)
=
Once the Inter code for the kit has been loaded, we also find symbols:
= (text)
	main
		connectors
			ExampleKitFunction (socket symbol) ->	main
														HypotheticalKit
															...
															ExampleKitFunction (regular symbol)
=
So now we must connect the plug to the socket. |S| will then connect through to
the actual definition, and all will be well.

=
void ConnectPlugsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"connect-plugs",
		ConnectPlugsStage::run, NO_STAGE_ARG, FALSE);
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

int ConnectPlugsStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.repository;
 	inter_package *connectors = Site::connectors_package(I);
 	if (connectors) @<Try to connect plugs and sockets@>;
 	@<Check that there are now no symbols which connect to loose plugs@>;
	return TRUE;
}

@<Try to connect plugs and sockets@> =
	inter_symbols_table *ST = Inter::Packages::scope(connectors);
	for (int i=0; i<ST->size; i++) {
		inter_symbol *S = ST->symbol_array[i];
		if (Inter::Connectors::is_loose_plug(S)) {
			inter_symbol *socket =
				Inter::Connectors::find_socket(I, Inter::Connectors::plug_name(S));
			if (socket)
				Inter::Connectors::wire_plug(S, socket);
		}
	}

@<Check that there are now no symbols which connect to loose plugs@> =
	plug_inspection_state state;
	state.bad_plugs = Dictionaries::new(16, FALSE);
	state.bad_plug_names = NEW_LINKED_LIST(text_stream);
	InterTree::traverse(I, ConnectPlugsStage::visitor, &state, NULL, PACKAGE_IST);
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

@ Note that it is not necessarily an error to have a loose plug, that is, a plug
which does not connect to any socket. It is only an error if a symbol is trying
to connect to this plug. So we make a traverse of the tree to look for such symbols.

Note that we also take the opportunity to simplify chains of equations down to just
the minimum. For example, if we have |S1 -> S2 -> plug -> socket -> T1 -> T2 -> T3|,
we simplify just to |S1 -> T3|.

=
void ConnectPlugsStage::visitor(inter_tree *I, inter_tree_node *P, void *v_state) {
	plug_inspection_state *state = (plug_inspection_state *) v_state;
	inter_package *Q = Inter::Package::defined_by_frame(P);
	inter_symbols_table *ST = Inter::Packages::scope(Q);
	for (int i=0; i<ST->size; i++) {
		inter_symbol *S = ST->symbol_array[i];
		inter_symbol *E = S;
		while ((E) && (E->equated_to)) E = E->equated_to;
		if ((S) && (S != E)) {
			S->equated_to = E;
			if (Inter::Connectors::is_loose_plug(E))
				@<This is an error, because a loose plug has been used@>;
		}
	}
}

@<This is an error, because a loose plug has been used@> =
	text_stream *N = S->equated_to->equated_name;
	if (Dictionaries::find(state->bad_plugs, N) == NULL) {
		Dictionaries::create(state->bad_plugs, N);
		ADD_TO_LINKED_LIST(N, text_stream, state->bad_plug_names);
	}
