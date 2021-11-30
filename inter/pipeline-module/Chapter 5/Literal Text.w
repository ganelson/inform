[SynopticText::] Literal Text.

To alphabetise literal texts, deduplicate them, and stote a canonical set in
the main/texts linkage.

@ Before this runs, literal text constants are scattered all over the Inter tree.
At the end, they are all moved into a package called |texts|, of type |_linkage|,
and are presented in alphabetical order (case sensitively) without duplicates.

This is not done to save memory, though it does that too, but because we want
runtime code to be able to compare literal texts by performing an unsigned
comparison on their addresses. The following works:
= (text as Inform 7)
	let Q be "Rhayader";
	if Q is "Rhayader":
		say "Q is still Q, so you can relax."
=
because the two instances of |"Rhayader"| compile to the same data in memory.
This cannot be arranged in the main body of the Inform compiler because these
two instances might be much further apart than in this example -- one might be
in a kit, and the other in an unrelated extension, for example.

As this is called, //Synoptic Utilities// has already formed a list |text_nodes|
of constants marked with the |TEXT_LITERAL_IANN| annotation. We take it from there:

=
void SynopticText::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (TreeLists::len(inv->text_nodes) > 0) {
		TreeLists::sort(inv->text_nodes, SynopticText::cmp);
		inter_package *texts_pack = Site::ensure_texts_package(I);
		inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(texts_pack);

		text_stream *latest_text = NULL;
		inter_symbol *latest_s = NULL;
		for (int i=0, j=0; i<TreeLists::len(inv->text_nodes); i++) {
			inter_tree_node *P = inv->text_nodes->list[i].node;
			inter_package *pack = Inter::Packages::container(P);
			text_stream *S = SynopticText::text_quoted_here(P);
			if ((latest_text == NULL) || (Str::ne(S, latest_text)))
				@<A new entry, not a duplicated one@>;
			@<Change the value in P from a literal text to an alias for the latest text@>;
		}
	}
}

@ If the list reads |"apple", "apple", "banana", "cauliflower", "cauliflower"|,
this will be executed on the first |"apple"|, on |"banana"| and the first
|"cauliflower"|. They will lead to definitions in the texts module like so:
= (text as Inter)
	constant alphabetised_text_0 K_unchecked = "apple" __text_literal=1
	constant alphabetised_text_1 K_unchecked = "banana" __text_literal=1
	constant alphabetised_text_2 K_unchecked = "cauliflower" __text_literal=1
=

@<A new entry, not a duplicated one@> =
	TEMPORARY_TEXT(A)
	WRITE_TO(A, "alphabetised_text_%d", j++);
	inter_symbol *alpha_s = Synoptic::new_symbol(texts_pack, A);
	DISCARD_TEXT(A)
	Synoptic::def_textual_constant(I, step, alpha_s, S, &IBM);
	latest_s = alpha_s;
	latest_text = S;

@ This is run on every P in the list. It begins as, for example,
= (text as Inter)
	constant whatever K_unchecked = "banana" __text_literal=1
=
and becomes:
= (text as Inter)
	constant whatever K_unchecked = ref_to_text
=
where |ref_text_2| in the current package is equated to |alphabetised_text_1|
in |texts|.

@<Change the value in P from a literal text to an alias for the latest text@> =
	inter_symbol *ref_s = Synoptic::new_symbol(pack, I"ref_to_text");

	InterSymbolsTables::equate(ref_s, latest_s);
	inter_ti val1 = 0, val2 = 0;
	Inter::Symbols::to_data(I, Inter::Packages::container(P), ref_s, &val1, &val2);
	P->W.data[FORMAT_CONST_IFLD] = CONSTANT_DIRECT;
	P->W.data[DATA_CONST_IFLD] = val1;
	P->W.data[DATA_CONST_IFLD+1] = val2;

	inter_symbol *con_name =
		InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	Inter::Symbols::unannotate(con_name, TEXT_LITERAL_IANN);

@ Here we extract the actual text from a node defining a constant literal text,
and use that to define a sorting function on nodes:

=
text_stream *SynopticText::text_quoted_here(inter_tree_node *P) {
	if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_TEXT) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		return Inode::ID_to_text(P, val1);
	}
	internal_error("not indirect");
	return NULL;
}

int SynopticText::cmp(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	text_stream *S1 = SynopticText::text_quoted_here(P1);
	text_stream *S2 = SynopticText::text_quoted_here(P2);
	return Str::cmp(S1, S2);
}
