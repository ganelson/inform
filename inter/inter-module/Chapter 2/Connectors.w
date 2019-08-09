[Inter::Connectors::] Connectors.

To manage link symbols.

@ =
inter_symbol *Inter::Connectors::plug(inter_tree *I, text_stream *plug_name, text_stream *wanted) {
	inter_package *connectors = Inter::Connectors::connectors_package(I);
	inter_symbol *plug = Inter::SymbolsTables::create_with_unique_name(
		Inter::Packages::scope(connectors), plug_name);
	Inter::SymbolsTables::make_plug(plug, wanted);
	LOG("Plug I%d: %S\n", I->allocation_id, plug_name);
	return plug;
}

inter_symbol *Inter::Connectors::socket(inter_tree *I, text_stream *socket_name, inter_symbol *wired_from) {
	inter_package *connectors = Inter::Connectors::connectors_package(I);
	inter_symbol *socket = Inter::SymbolsTables::create_with_unique_name(
		Inter::Packages::scope(connectors), socket_name);
	Inter::SymbolsTables::make_socket(socket, wired_from);
	LOG("Socket I%d: %S (== $3)\n", I->allocation_id, socket_name, socket);
	return socket;
}

inter_package *Inter::Connectors::connectors_package(inter_tree *I) {
	if (I == NULL) internal_error("no tree for connectors");
	inter_package *connectors = Inter::Tree::connectors_package(I);
	if (connectors == NULL) {
		inter_package *main_package = Inter::Tree::main_package(I);
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
		Inter::Tree::set_connectors_package(I, connectors);
		Inter::Packages::make_linklike(connectors);
	}
	return connectors;
}
