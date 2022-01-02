[Inter::Connectors::] Connectors.

To manage link symbols.

@ =
int unique_plug_number = 1;
inter_symbol *Inter::Connectors::plug(inter_tree *I, text_stream *wanted) {
	inter_package *connectors = Inter::Connectors::connectors_package(I);
	TEMPORARY_TEXT(PN)
	WRITE_TO(PN, "plug_%05d", unique_plug_number++);
	inter_symbol *plug = InterSymbolsTables::create_with_unique_name(
		Inter::Packages::scope(connectors), PN);
	DISCARD_TEXT(PN)
	InterSymbolsTables::make_plug(plug, wanted);
	LOGIF(INTER_CONNECTORS, "Plug I%d: $3 seeking %S\n", I->allocation_id, plug, plug->equated_name);
	return plug;
}

inter_symbol *Inter::Connectors::socket(inter_tree *I, text_stream *socket_name, inter_symbol *wired_from) {
	inter_package *connectors = Inter::Connectors::connectors_package(I);
	inter_symbol *socket = InterSymbolsTables::create_with_unique_name(
		Inter::Packages::scope(connectors), socket_name);
	InterSymbolsTables::make_socket(socket, wired_from);
	LOGIF(INTER_CONNECTORS, "Socket I%d: $3 wired to $3\n", I->allocation_id, socket, wired_from);
	return socket;
}

inter_package *Inter::Connectors::connectors_package(inter_tree *I) {
	if (I == NULL) internal_error("no tree for connectors");
	inter_package *connectors = Site::connectors_package(I);
	if (connectors == NULL) {
		connectors = Site::make_linkage_package(I, I"connectors");
		Site::set_connectors_package(I, connectors);
		Inter::Packages::make_linklike(connectors);
	}
	return connectors;
}

inter_symbol *Inter::Connectors::find_socket(inter_tree *I, text_stream *identifier) {
	inter_package *connectors = Site::connectors_package(I);
	if (connectors) {
		inter_symbol *S = InterSymbolsTables::symbol_from_name_not_equating(
			Inter::Packages::scope(Site::connectors_package(I)), identifier);
		if ((S) && (Inter::Symbols::get_scope(S) == SOCKET_ISYMS)) return S;
	}
	return NULL;
}

inter_symbol *Inter::Connectors::find_plug(inter_tree *I, text_stream *identifier) {
	inter_package *connectors = Site::connectors_package(I);
	if (connectors) {
		inter_symbol *S = InterSymbolsTables::symbol_from_name_not_equating(
			Inter::Packages::scope(Site::connectors_package(I)), identifier);
		if ((S) && (Inter::Symbols::get_scope(S) == PLUG_ISYMS)) return S;
	}
	return NULL;
}

void Inter::Connectors::wire_plug(inter_symbol *plug, inter_symbol *to) {
	if (plug == NULL) internal_error("no plug");
	LOGIF(INTER_CONNECTORS, "Plug $3 wired to $3\n", plug, to);
	InterSymbolsTables::equate(plug, to);
	plug->equated_name = NULL;
}

int Inter::Connectors::is_plug(inter_symbol *S) {
	if ((S) && (Inter::Symbols::get_scope(S) == PLUG_ISYMS)) return TRUE;
	return FALSE;
}

int Inter::Connectors::is_socket(inter_symbol *S) {
	if ((S) && (Inter::Symbols::get_scope(S) == SOCKET_ISYMS)) return TRUE;
	return FALSE;
}

int Inter::Connectors::is_loose_plug(inter_symbol *S) {
	if ((S) && (Inter::Symbols::get_scope(S) == PLUG_ISYMS) && (S->equated_to == NULL))
		return TRUE;
	return FALSE;
}

text_stream *Inter::Connectors::plug_name(inter_symbol *S) {
	if (Inter::Connectors::is_loose_plug(S)) return S->equated_name;
	return NULL;
}
