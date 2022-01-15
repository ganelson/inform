[SynopticExtensions::] Extensions.

To renumber the extensions and construct suitable functions and arrays.

@ Our inventory |inv| already contains a list |inv->extension_nodes| of packages
with the type |_module| which derive from extensions.

=
void SynopticExtensions::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (TreeLists::len(inv->extension_nodes) > 0) @<Assign unique extension ID numbers@>;
	@<Define SHOWEXTENSIONVERSIONS function@>;
	@<Define SHOWFULLEXTENSIONVERSIONS function@>;
	@<Define SHOWONEEXTENSION function@>;
}

@ Each extension module contains a numeric constant with the symbol name |extension_id|.
We want to ensure that these ID numbers are contiguous from 1 and never duplicated,
so we change the values of these constants accordingly.

@<Assign unique extension ID numbers@> =
	TreeLists::sort(inv->extension_nodes, MakeSynopticModuleStage::category_order);
	for (int i=0; i<TreeLists::len(inv->extension_nodes); i++) {
		inter_package *pack =
			Inter::Package::defined_by_frame(inv->extension_nodes->list[i].node);
		inter_tree_node *D = Synoptic::get_definition(pack, I"extension_id");
		D->W.data[DATA_CONST_IFLD+1] = (inter_ti) (i + 1);
	}

@ Now we compile three functions, each of which simply prints credits out.

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

@<Define SHOWEXTENSIONVERSIONS function@> =
	inter_name *iname = HierarchyLocations::iname(I, SHOWEXTENSIONVERSIONS_HL);
	Synoptic::begin_function(I, iname);
	for (int i=0; i<TreeLists::len(inv->extension_nodes); i++) {
		inter_package *pack =
			Inter::Package::defined_by_frame(inv->extension_nodes->list[i].node);
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
	Synoptic::end_function(I, step, iname);

@ This fuller version does not allow the exemptions.

@<Define SHOWFULLEXTENSIONVERSIONS function@> =
	inter_name *iname = HierarchyLocations::iname(I, SHOWFULLEXTENSIONVERSIONS_HL);
	Synoptic::begin_function(I, iname);
	for (int i=0; i<TreeLists::len(inv->extension_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->extension_nodes->list[i].node);
		text_stream *credit = Str::duplicate(Metadata::read_textual(pack, I"^credit"));
		WRITE_TO(credit, "\n");
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, credit);
		Produce::up(I);
	}
	Synoptic::end_function(I, step, iname);

@ This prints the name of a single extension, identified by a value which
is its extension ID. Speed of execution here is quite unimportant, so it's
just a run of |if (id == 1) ...|, then |if (id == 2) ...|, and so on.

@<Define SHOWONEEXTENSION function@> =
	inter_name *iname = HierarchyLocations::iname(I, SHOWONEEXTENSION_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *id_s = Synoptic::local(I, I"id", NULL);
	for (int i=0; i<TreeLists::len(inv->extension_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->extension_nodes->list[i].node);
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
	Synoptic::end_function(I, step, iname);
