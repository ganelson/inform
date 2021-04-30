[SynopticExtensions::] Extensions.

To renumber the extensions and construct suitable functions and arrays.

@ Before this runs, there are one or more modules in the Inter tree which
contain the material compiled from extensions. We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |extension_nodes|
of packages of type |_module| which derive from extensions.

=
void SynopticExtensions::renumber(inter_tree *I, inter_tree_location_list *extension_nodes) {
	if (TreeLists::len(extension_nodes) > 0) {
		TreeLists::sort(extension_nodes, Synoptic::category_order);
		for (int i=0; i<TreeLists::len(extension_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(extension_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"extension_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) (i + 1);
		}
	}
}

@ Extensions have an obvious effect at runtime -- they include extra material.
But there are also just three functions which deal with extensions as if
they were values; all of them simply print credits out.

This is more important than it may sound because many extensions are published
under a Creative Commons attribution license which requires users to give credit
to the authors: Inform thus ensures that this happens automatically.

There are two forms of exemption from this --
(*) specific authorial modesty suppresses the author's name for one extension,
at that extension author's discretion;
(*) general authorial modesty suppresses the author's name for any extensions
by the same person who wrote the main source text.

By design, however, the author of the main source text cannot remove the name
of a different author writing an extension which did not ask for modesty. That
would violate the CC license.

@e SHOWEXTENSIONVERSIONS_SYNID
@e SHOWFULLEXTENSIONVERSIONS_SYNID
@e SHOWONEEXTENSION_SYNID

=
int SynopticExtensions::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case SHOWEXTENSIONVERSIONS_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the SHOWEXTENSIONVERSIONS function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case SHOWFULLEXTENSIONVERSIONS_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the SHOWFULLEXTENSIONVERSIONS function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case SHOWONEEXTENSION_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the SHOWONEEXTENSION function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@<Add a body of code to the SHOWEXTENSIONVERSIONS function@> =
	for (int i=0; i<TreeLists::len(extension_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(extension_nodes->list[i].node);
		inter_ti modesty = Metadata::read_numeric(pack, I"^modesty");
		if (modesty == 0) {
			text_stream *credit = Str::duplicate(Metadata::read_textual(pack, I"^credit"));
			WRITE_TO(credit, "\n");
			Produce::inv_primitive(I, PRINT_BIP);
			Produce::down(I);
				Produce::val_text(I, credit);
			Produce::up(I);
		}
	}

@ This fuller version does not allow the exemptions.

@<Add a body of code to the SHOWFULLEXTENSIONVERSIONS function@> =
	for (int i=0; i<TreeLists::len(extension_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(extension_nodes->list[i].node);
		text_stream *credit = Str::duplicate(Metadata::read_textual(pack, I"^credit"));
		WRITE_TO(credit, "\n");
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, credit);
		Produce::up(I);
	}

@ This prints the name of a single extension, identified by a value which
is its allocation ID plus 1. (In effect, this means extensions are numbered from
1 upwards in order of inclusion.)

@<Add a body of code to the SHOWONEEXTENSION function@> =
	inter_symbol *id_s = Synoptic::get_local(I, I"id");
	for (int i=0; i<TreeLists::len(extension_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(extension_nodes->list[i].node);
		text_stream *credit = Metadata::read_textual(pack, I"^credit");
		Produce::inv_primitive(I, IF_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, EQ_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, id_s);
				Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) (i + 1));
			Produce::up(I);
			Produce::code(I);
			Produce::down(I);
				Produce::inv_primitive(I, PRINT_BIP);
				Produce::down(I);
					Produce::val_text(I, credit);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	}
