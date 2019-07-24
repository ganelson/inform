[Inter::Ref::] The Ref Construct.

Defining the ref construct.

@

@e REF_IST

=
void Inter::Ref::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		REF_IST,
		L"ref (%i+) (%C+)",
		I"ref", I"refs");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Ref::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Ref::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Ref::write);
}

@

@d BLOCK_REF_IFLD 2
@d KIND_REF_IFLD 3
@d VAL1_REF_IFLD 4
@d VAL2_REF_IFLD 5

@d EXTENT_REF_IFR 6

=
void Inter::Ref::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IBM, REF_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'ref' used outside function", eloc); return; }
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *ref_kind = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], KIND_IST, E);
	if (*E) return;

	inter_t var_val1 = 0;
	inter_t var_val2 = 0;
	*E = Inter::Types::read(ilp->line, eloc, Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), ref_kind, ilp->mr.exp[1], &var_val1, &var_val2, locals);
	if (*E) return;

	*E = Inter::Ref::new(IBM, routine, ref_kind, ilp->indent_level, var_val1, var_val2, eloc);
}

inter_error_message *Inter::Ref::new(inter_bookmark *IBM, inter_symbol *routine, inter_symbol *ref_kind, int level, inter_t val1, inter_t val2, inter_error_location *eloc) {
	inter_tree_node *P = Inter::Node::fill_4(IBM, REF_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, ref_kind), val1, val2, eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Tree::insert_node(P, IBM);
	return NULL;
}

void Inter::Ref::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_REF_IFR) { *E = Inter::Node::error(P, I"extent wrong", NULL); return; }
	inter_symbols_table *locals = Inter::Packages::scope(owner);
	if (locals == NULL) { *E = Inter::Node::error(P, I"no symbols table in function", NULL); return; }
	*E = Inter::Verify::symbol(owner, P, P->W.data[KIND_REF_IFLD], KIND_IST); if (*E) return;
	inter_symbol *ref_kind = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P->W.data[KIND_REF_IFLD]);;
	*E = Inter::Verify::local_value(P, VAL1_REF_IFLD, ref_kind, locals); if (*E) return;
}

void Inter::Ref::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) { *E = Inter::Node::error(P, I"function has no symbols table", NULL); return; }
	inter_symbol *ref_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_REF_IFLD);
	if (ref_kind) {
		WRITE("ref %S ", ref_kind->symbol_name);
		Inter::Types::write(OUT, P, ref_kind, P->W.data[VAL1_REF_IFLD], P->W.data[VAL2_REF_IFLD], locals, FALSE);
	} else { *E = Inter::Node::error(P, I"cannot write ref", NULL); return; }
}
