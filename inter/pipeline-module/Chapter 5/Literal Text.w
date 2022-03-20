[SynopticText::] Literal Text.

To alphabetise literal texts, deduplicate them, and store a canonical set in
the synoptic/texts submodule.

@ Before this runs, literal text constants are scattered all over the Inter tree.
At the end, they are all moved into a submodule of the synoptic module called
|texts|, and are presented in alphabetical order (case sensitively) without
duplicates.

This is not done to save memory, though it does that too, but because we want
runtime code to be able to compare literal texts by performing an unsigned
comparison on their addresses. The following works:
= (text as Inform 7)
	let Q be "Rhayader";
	if Q is "Rhayader":
		say "Q is still Q, so you can relax."
=
because the two instances of |"Rhayader"| compile to the same data in memory.
Dynamic texts must of course be compared more expensively.

This cannot be arranged in the main body of the Inform compiler because these
two instances might be much further apart than in this example -- one might be
in a kit, and the other in an unrelated extension, say.

Our inventory |inv| already contains a list |inv->text_nodes| of constant
definitions whose value is a literal text.

=
void SynopticText::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (InterNodeList::array_len(inv->text_nodes) > 0) {
		InterNodeList::array_sort(inv->text_nodes, SynopticText::cmp);
		inter_package *texts_pack =
			Packaging::incarnate(
				LargeScale::synoptic_submodule(I,
					LargeScale::register_submodule_identity(I"text")));
		inter_bookmark IBM = InterBookmark::at_end_of_this_package(texts_pack);
		text_stream *latest_text = NULL;
		inter_symbol *latest_s = NULL;
		for (int i=0, j=0; i<InterNodeList::array_len(inv->text_nodes); i++) {
			inter_tree_node *P = inv->text_nodes->list[i].node;
			inter_package *pack = InterPackage::container(P);
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
	Synoptic::textual_constant(I, step, alpha_s, S, &IBM);
	latest_s = alpha_s;
	latest_text = S;

@ This is run on every P in the list. It begins as, for example,
= (text as Inter)
	constant (text_literal) whatever = "banana"
=
and becomes:
= (text as Inter)
	constant whatever = ref_to_text
=
where |ref_text_2| in the current package is equated to |alphabetised_text_1|
in |texts|.

@<Change the value in P from a literal text to an alias for the latest text@> =
	inter_symbol *ref_s = Synoptic::new_symbol(pack, I"ref_to_text");

	Wiring::wire_to(ref_s, latest_s);
	inter_pair val = InterValuePairs::symbolic_in(InterPackage::container(P), ref_s);
	ConstantInstruction::set_constant(P, val);
	ConstantInstruction::set_type(P, InterTypes::unchecked());

@ Here we extract the actual text from a node defining a constant literal text,
and use that to define a sorting function on nodes:

=
text_stream *SynopticText::text_quoted_here(inter_tree_node *P) {
	if (ConstantInstruction::list_format(P) == CONST_LIST_FORMAT_NONE) {
		inter_pair val = ConstantInstruction::constant(P);
		return InterValuePairs::to_text(Inode::tree(P), val);
	}
	return NULL;
}

int SynopticText::cmp(const void *ent1, const void *ent2) {
	ina_entry *E1 = (ina_entry *) ent1;
	ina_entry *E2 = (ina_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	text_stream *S1 = SynopticText::text_quoted_here(P1);
	text_stream *S2 = SynopticText::text_quoted_here(P2);
	return Str::cmp(S1, S2);
}
