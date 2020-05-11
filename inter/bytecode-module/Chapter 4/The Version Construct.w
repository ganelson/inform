[Inter::Version::] The Version Construct.

Defining the version construct.

@

@e VERSION_IST

=
void Inter::Version::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		VERSION_IST,
		L"version (%d+)",
		I"version", I"versions");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Version::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Version::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Version::write);
}

@

@d NUMBER_VERSION_IFLD 2

@d EXTENT_VERSION_IFR 3

=
void Inter::Version::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, VERSION_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (Inter::Annotations::exist(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Version::new(IBM, Str::atoi(ilp->mr.exp[0], 0), (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Version::new(inter_bookmark *IBM, int V, inter_t level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_1(IBM, VERSION_IST, (inter_t) V, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

void Inter::Version::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_VERSION_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	if (P->W.data[NUMBER_VERSION_IFLD] < 1) { *E = Inode::error(P, I"version out of range", NULL); return; }
}

void Inter::Version::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("version %d", P->W.data[NUMBER_VERSION_IFLD]);
}
