[Inter::Connectors::] Connectors.

To manage link symbols.

@ =
inter_symbol *Inter::Connectors::plug(inter_bookmark *IBM, text_stream *plug_name, text_stream *wanted, inter_package **package_cache) {
	inter_package *connectors = Inter::Connectors::connectors_package(IBM, package_cache);
	inter_symbol *plug = Inter::SymbolsTables::create_with_unique_name(Inter::Packages::scope(connectors), plug_name);
	Inter::SymbolsTables::make_plug(plug, wanted);
	return plug;
}

inter_symbol *Inter::Connectors::socket(inter_bookmark *IBM, text_stream *socket_name, inter_symbol *wired_from, inter_package **package_cache) {
	inter_package *connectors = Inter::Connectors::connectors_package(IBM, package_cache);
	inter_symbol *socket = Inter::SymbolsTables::create_with_unique_name(Inter::Packages::scope(connectors), socket_name);
	Inter::SymbolsTables::make_socket(socket, wired_from);
	return socket;
}

inter_package *Inter::Connectors::connectors_package(inter_bookmark *IBM, inter_package **package_cache) {
	inter_package *connectors = NULL;
	if (package_cache) connectors = *package_cache;
	if (connectors == NULL) {
		connectors = Inter::Packages::by_name(Inter::Bookmarks::package(IBM), I"connectors");
	}
	if (connectors == NULL) {
		inter_symbol *linkage = Inter::SymbolsTables::url_name_to_symbol(Inter::Bookmarks::tree(IBM), NULL, I"/_linkage");
		if (linkage == NULL) internal_error("no linkage ptype");
		Inter::Package::new_package(IBM, I"connectors", linkage, (inter_t) Inter::Bookmarks::baseline(IBM)+1, NULL, &(connectors));
	}
	if (connectors == NULL) internal_error("unable to create connector package");
	if (package_cache) *package_cache = connectors;
	Inter::Packages::make_linklike(connectors);
	return connectors;
}
