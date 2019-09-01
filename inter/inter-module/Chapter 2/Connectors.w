[Inter::Connectors::] Connectors.

To manage link symbols.

@ =
int unique_plug_number = 1;
inter_symbol *Inter::Connectors::plug(inter_tree *I, text_stream *wanted) {
if (Str::eq(wanted, I"self")) internal_error("selfie!");
	inter_package *connectors = Inter::Connectors::connectors_package(I);
	TEMPORARY_TEXT(PN)
	WRITE_TO(PN, "plug_%05d", unique_plug_number++);
	inter_symbol *plug = Inter::SymbolsTables::create_with_unique_name(
		Inter::Packages::scope(connectors), PN);
	DISCARD_TEXT(PN);
	Inter::SymbolsTables::make_plug(plug, wanted);
	LOGIF(INTER_CONNECTORS, "Plug I%d: $3 seeking %S\n", I->allocation_id, plug, plug->equated_name);
	return plug;
}

inter_symbol *Inter::Connectors::socket(inter_tree *I, text_stream *socket_name, inter_symbol *wired_from) {
	inter_package *connectors = Inter::Connectors::connectors_package(I);
	inter_symbol *socket = Inter::SymbolsTables::create_with_unique_name(
		Inter::Packages::scope(connectors), socket_name);
	Inter::SymbolsTables::make_socket(socket, wired_from);
	LOGIF(INTER_CONNECTORS, "Socket I%d: $3 wired to $3\n", I->allocation_id, socket, wired_from);
	return socket;
}

inter_package *Inter::Connectors::connectors_package(inter_tree *I) {
	if (I == NULL) internal_error("no tree for connectors");
	inter_package *connectors = Site::connectors_package(I);
	if (connectors == NULL) {
		inter_package *main_package = Site::main_package(I);
		if (main_package == NULL) internal_error("tree without main");
		connectors = Inter::Packages::by_name(main_package, I"connectors");
		if (connectors == NULL) {
			inter_symbol *linkage = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/_linkage");
			if (linkage == NULL) internal_error("no linkage ptype");
			inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(main_package);
			Inter::Package::new_package(&IBM, I"connectors", linkage,
				(inter_t) Inter::Bookmarks::baseline(&IBM)+1, NULL, &(connectors));
		}
		if (connectors == NULL) internal_error("unable to create connector package");
		Site::set_connectors_package(I, connectors);
		Inter::Packages::make_linklike(connectors);
	}
	return connectors;
}

inter_symbol *Inter::Connectors::find_socket(inter_tree *I, text_stream *identifier) {
	inter_package *connectors = Site::connectors_package(I);
	if (connectors) {
		inter_symbol *S = Inter::SymbolsTables::symbol_from_name_not_equating(
			Inter::Packages::scope(Site::connectors_package(I)), identifier);
		if ((S) && (Inter::Symbols::get_scope(S) == SOCKET_ISYMS)) return S;
	}
	return NULL;
}

inter_symbol *Inter::Connectors::find_plug(inter_tree *I, text_stream *identifier) {
	inter_package *connectors = Site::connectors_package(I);
	if (connectors) {
		inter_symbol *S = Inter::SymbolsTables::symbol_from_name_not_equating(
			Inter::Packages::scope(Site::connectors_package(I)), identifier);
		if ((S) && (Inter::Symbols::get_scope(S) == PLUG_ISYMS)) return S;
	}
	return NULL;
}

void Inter::Connectors::wire_plug(inter_symbol *plug, inter_symbol *to) {
	if (plug == NULL) internal_error("no plug");
	LOGIF(INTER_CONNECTORS, "Plug $3 wired to $3\n", plug, to);
	Inter::SymbolsTables::equate(plug, to);
}

void Inter::Connectors::stecker(inter_tree *I) {
 	inter_package *Q = Site::connectors_package(I);
 	if (Q == NULL) return;
	inter_symbols_table *ST = Inter::Packages::scope(Q);
	for (int i=0; i<ST->size; i++) {
		inter_symbol *plug = ST->symbol_array[i];
		if ((plug) && (Inter::Symbols::get_scope(plug) == PLUG_ISYMS) && (plug->equated_to == NULL)) {
			inter_symbol *socket = Inter::Connectors::find_socket(I, plug->equated_name);
			if (socket) {
				Inter::Connectors::wire_plug(plug, socket);
				plug->equated_name = NULL;
			}
		}
	}
}
