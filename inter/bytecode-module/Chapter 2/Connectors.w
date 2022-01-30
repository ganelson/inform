[Wiring::] Connectors.

To manage link symbols.

@ =
typedef struct wiring_data {
	struct inter_symbol *connects_to;
	struct text_stream *wants_to_connect_to;
	int no_connections;
} wiring_data;

wiring_data Wiring::new_wiring_data(inter_symbol *S) {
	wiring_data wd;
	wd.connects_to = NULL;
	wd.wants_to_connect_to = NULL;
	wd.no_connections = 0;
	return wd;
}

inter_symbol *Wiring::cable_end(inter_symbol *S) {
	while ((S) && (S->wiring.connects_to)) S = S->wiring.connects_to;
	return S;
}

inter_symbol *Wiring::wired_to(inter_symbol *S) {
	if (S) return S->wiring.connects_to;
	return NULL;
}

int Wiring::has_no_incoming_connections(inter_symbol *S) {
	if ((S) && (S->wiring.no_connections == 0)) return TRUE;
	return FALSE;
}

int Wiring::is_wired(inter_symbol *S) {
	if (Wiring::wired_to(S)) return TRUE;
	return FALSE;
}

void Wiring::wire_to(inter_symbol *S, inter_symbol *T) {
	if (S == NULL) internal_error("null symbol cannot be wired");
	if ((S->metadata_key) || ((T) && (T->metadata_key)))
		internal_error("metadata keys cannot be wired");
	if (S->wiring.connects_to == T) return;
	if (S->wiring.connects_to) S->wiring.connects_to->wiring.no_connections--;
	S->wiring.connects_to = T;
	S->wiring.wants_to_connect_to = NULL;
	if (T) T->wiring.no_connections++;
	if ((Inter::Symbols::get_scope(S) != SOCKET_ISYMS) &&
		(Inter::Symbols::get_scope(S) != PLUG_ISYMS))
		Inter::Symbols::set_scope(S, EXTERNAL_ISYMS);
	LOGIF(INTER_SYMBOLS, "Wired $3 to $3\n", S, T);
	int c = 0;
	for (inter_symbol *W = S; W; W = W->wiring.connects_to, c++)
		if (c == 100) {
			c = 0;
			for (inter_symbol *W = S; ((W) && (c < 20)); W = W->wiring.connects_to, c++)
				LOG("%d. %S\n", c, W->symbol_name);
			LOG("...");
			internal_error("probably made a circuit in wiring");
		}
}

void Wiring::wire_to_name(inter_symbol *S, text_stream *T) {
	if (S == NULL) internal_error("null symbol cannot be wired");
	if (S->metadata_key) internal_error("metadata keys cannot be wired");
	if (Str::len(T) == 0) internal_error("symbols cannot be wired to the empty name");
	if (Str::get_at(T, 0) == '/') internal_error("symbols cannot be wired to URLs");
	Wiring::wire_to(S, NULL);
	S->wiring.wants_to_connect_to = Str::duplicate(T);
}

int Wiring::is_wired_to_name(inter_symbol *S) {
	if ((S) && (Str::len(S->wiring.wants_to_connect_to) > 0)) return TRUE;
	return FALSE;
}

text_stream *Wiring::wired_to_name(inter_symbol *S) {
	if (S) return S->wiring.wants_to_connect_to;
	return NULL;
}

void Wiring::shorten_wiring(inter_symbol *S) {
	inter_symbol *E = Wiring::cable_end(S);
	if ((S != E) && (Wiring::wired_to(S) != E)) Wiring::wire_to(S, E);
}

void Wiring::convert_to_plug(inter_symbol *S, text_stream *wanted) {
	Wiring::wire_to_name(S, wanted);
	Inter::Symbols::set_scope(S, PLUG_ISYMS);
	Inter::Symbols::set_type(S, MISC_ISYMT);
}

void Wiring::convert_to_socket(inter_symbol *S, inter_symbol *to) {
	Wiring::wire_to(S, to);
	Inter::Symbols::set_scope(S, SOCKET_ISYMS);
}

int unique_plug_number = 1;
inter_symbol *Wiring::plug(inter_tree *I, text_stream *wanted) {
	inter_package *connectors = LargeScale::ensure_connectors_package(I);
	TEMPORARY_TEXT(PN)
	WRITE_TO(PN, "plug_%05d", unique_plug_number++);
	inter_symbol *plug = InterSymbolsTables::create_with_unique_name(
		InterPackage::scope(connectors), PN);
	DISCARD_TEXT(PN)
	Wiring::convert_to_plug(plug, wanted);
	LOGIF(INTER_CONNECTORS, "Plug I%d: $3 seeking %S\n", I->allocation_id, plug, Wiring::plug_name(plug));
	return plug;
}

inter_symbol *Wiring::socket(inter_tree *I, text_stream *socket_name, inter_symbol *to) {
	inter_package *connectors = LargeScale::ensure_connectors_package(I);
	inter_symbol *socket = InterSymbolsTables::create_with_unique_name(
		InterPackage::scope(connectors), socket_name);
	Wiring::convert_to_socket(socket, to);
	LOGIF(INTER_CONNECTORS, "Socket I%d: $3 wired to $3\n", I->allocation_id, socket, to);
	return socket;
}

inter_symbol *Wiring::find_socket(inter_tree *I, text_stream *identifier) {
	inter_package *connectors = LargeScale::connectors_package_if_it_exists(I);
	if (connectors) {
		inter_symbol *S = InterSymbolsTables::symbol_from_name_not_equating(
			InterPackage::scope(LargeScale::connectors_package_if_it_exists(I)), identifier);
		if ((S) && (Inter::Symbols::get_scope(S) == SOCKET_ISYMS)) return S;
	}
	return NULL;
}

inter_symbol *Wiring::find_plug(inter_tree *I, text_stream *identifier) {
	inter_package *connectors = LargeScale::connectors_package_if_it_exists(I);
	if (connectors) {
		inter_symbol *S = InterSymbolsTables::symbol_from_name_not_equating(
			InterPackage::scope(LargeScale::connectors_package_if_it_exists(I)), identifier);
		if ((S) && (Inter::Symbols::get_scope(S) == PLUG_ISYMS)) return S;
	}
	return NULL;
}

void Wiring::wire_plug(inter_symbol *plug, inter_symbol *to) {
	if (plug == NULL) internal_error("no plug");
	LOGIF(INTER_CONNECTORS, "Plug $3 wired to $3\n", plug, to);
	Wiring::wire_to(plug, to);
}

int Wiring::is_plug(inter_symbol *S) {
	if ((S) && (Inter::Symbols::get_scope(S) == PLUG_ISYMS)) return TRUE;
	return FALSE;
}

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
void Wiring::connect_plugs_to_sockets(inter_tree *I) {
 	inter_package *connectors = LargeScale::connectors_package_if_it_exists(I);
 	if (connectors) {
 		inter_symbols_table *ST = InterPackage::scope(connectors);
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if (Wiring::is_loose_plug(S)) {
				inter_symbol *socket = Wiring::find_socket(I, Wiring::plug_name(S));
				if (socket) Wiring::wire_plug(S, socket);
			}
		}
	}
}

int Wiring::is_socket(inter_symbol *S) {
	if ((S) && (Inter::Symbols::get_scope(S) == SOCKET_ISYMS)) return TRUE;
	return FALSE;
}

int Wiring::is_loose_plug(inter_symbol *S) {
	if ((Wiring::is_plug(S)) && (Wiring::is_wired(S) == FALSE)) return TRUE;
	return FALSE;
}

text_stream *Wiring::plug_name(inter_symbol *S) {
	if (Wiring::is_loose_plug(S)) return Wiring::wired_to_name(S);
	return NULL;
}
