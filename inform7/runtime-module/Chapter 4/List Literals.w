[ListLiterals::] List Literals.

Each enclosure contains the literal lists needed by its functions.

@h Runtime representation.
Literal lists arise from source text such as:
= (text as Inform 7)
	let Q be { 60, 168 };
=
The data to hold |{ 60, 168 }| has to be stored somehow. As with all
kinds for which values cannot be stored in a single word, we use a double
pointer:
= (text)
	                    small block:              large block:
	Q ----------------> pointer ----------------> block value header
	                    0                         strong kind ID for entries
	                                              number of entries
	                                              the entries
=
So in this particular example, the result would be:
= (text)
	                    small block:              large block:
	Q ----------------> pointer ----------------> block value header
	                    0                         NUMBER_TY
	                                              2
	                                              60
	                                              168
=
So the small block always occupies 2 words, the second being initially 0 and
used at runtime; the large block can be any size we need. The runtime code has
elaborate ways to extend or contract dynamic lists, but these of course are
constants, so we simply make the large blocks exactly the right size.

We make the large block first:

=
packaging_state ListLiterals::begin_large_block(inter_name *iname, kind *list_kind,
	int no_entries) {
	packaging_state save = EmitArrays::begin_word(iname, K_value);
	TheHeap::emit_block_value_header(list_kind, TRUE, no_entries + 2);
	RTKindIDs::strong_ID_array_entry(Kinds::unary_construction_material(list_kind));
	EmitArrays::numeric_entry((inter_ti) no_entries);
	return save;
}

void ListLiterals::end_large_block(packaging_state save) {
	EmitArrays::end(save);
}

@ And then make the small block pointing to it:

=
inter_name *ListLiterals::small_block(inter_name *large_block) {
	inter_name *N = Enclosures::new_small_block_for_constant();
	packaging_state save = EmitArrays::begin_unchecked(N);
	EmitArrays::iname_entry(large_block);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	return N;
}

@h Default values for list kinds.
The default list is the empty list, but note from the above representation
that the empty list of numbers (say) is different from the empty list of texts:
= (text)
	      small block:              large block:
	----> pointer ----------------> block value header
	                                NUMBER_TY
	                                0

	      small block:              large block:
	----> pointer ----------------> block value header
	                                TEXT_TY
	                                0
=
So each different kind K needs its own large block for making the default value
of "list of K": see //RTKindIDs::compile_structures//. This block is easily made:

=
void ListLiterals::default_large_block(inter_name *iname, kind *list_kind) {
	packaging_state save = ListLiterals::begin_large_block(iname, list_kind, 0);
	ListLiterals::end_large_block(save);
}

@h Literals.
To return to the example:
= (text as Inform 7)
	let Q be { 60, 168 };
=
Each list literal like |{ 60, 168 }| in imperative code results in a |literal_list|
object, and here we return its value:

=
inter_name *ListLiterals::compile_literal_list(literal_list *ll) {
	Lists::kind_of_ll(ll, FALSE);
	return ListLiterals::small_block(ListLiterals::large_block_iname(ll));
}

inter_name *ListLiterals::large_block_iname(literal_list *ll) {
	if (ll->ll_iname == NULL) {
		ll->ll_iname = Enclosures::new_iname(LITERALS_HAP, LIST_LITERAL_HL);
		text_stream *desc = Str::new();
		WRITE_TO(desc, "list literal '%W'", ll->unbraced_text);
		Sequence::queue_at(&ListLiterals::compilation_agent,
			STORE_POINTER_literal_list(ll), desc, ll->list_text);
	}
	return ll->ll_iname;
}

@ The large blocks are then compiled in due course by the following agent
(see //core: How To Compile//):

=
void ListLiterals::compilation_agent(compilation_subtask *t) {
	literal_list *ll = RETRIEVE_POINTER_literal_list(t->data);
	if (ll->ll_iname) {
		Lists::kind_of_ll(ll, TRUE);
		if (problem_count == 0) @<Compile the large block for this literal@>;
	}
}

@<Compile the large block for this literal@> =
	llist_entry *lle;
	int n = 0;
	for (lle = ll->first_llist_entry; lle; lle = lle->next_llist_entry) n++;
	packaging_state save =
		ListLiterals::begin_large_block(ll->ll_iname, Lists::kind_of_ll(ll, FALSE), n);
	for (lle = ll->first_llist_entry; lle; lle = lle->next_llist_entry)
		CompileValues::to_array_entry_of_kind(
			lle->llist_entry_value, ll->entry_kind);
	ListLiterals::end_large_block(save);

@h The instance list for a kind.
For kinds of object and enumerations, Inform sometimes chooses to compile its
own literal list, even though this is not specified anywhere in the source text.
Not all kinds have these: obviously, there can be no instance list for |K_real_number|.
The following returns -1 if |K| is similarly unsuitable, or a non-negative value
for the number of instances it has:

=
int ListLiterals::extent_of_instance_list(kind *K) {
	if (Kinds::Behaviour::is_an_enumeration(K)) return RTKindConstructors::enumeration_size(K);
	if (Kinds::Behaviour::is_subkind_of_object(K)) return Instances::count(K);
	return -1;
}

@ And the following then constructs the literal list, on demand:

=
inter_name *ListLiterals::get_instance_list(kind *K) {
	int N = ListLiterals::extent_of_instance_list(K);
	if (N < 0) return NULL;
	inter_name *large_block_iname = RTKindConstructors::list_iname(Kinds::get_construct(K));
	if (large_block_iname == NULL) {
		large_block_iname =
			Hierarchy::make_iname_in(INSTANCE_LIST_HL, RTKindConstructors::kind_package(K));
		packaging_state save = ListLiterals::begin_large_block(
			large_block_iname, Kinds::unary_con(CON_list_of, K), N);
		if (Kinds::Behaviour::is_an_enumeration(K)) RTKindConstructors::make_enumeration_entries(K);
		if (Kinds::Behaviour::is_subkind_of_object(K)) @<Compile entries for a kind of object@>;
		ListLiterals::end_large_block(save);
		RTKindConstructors::set_list_iname(Kinds::get_construct(K), large_block_iname);
	}
	return ListLiterals::small_block(large_block_iname);
}

@ Note that the instances are given in the order preferred by //Instance Counting//,
not in creation order, as a simple |LOOP_OVER_INSTANCES| would have done.

@<Compile entries for a kind of object@> =
	instance *I = InstanceCounting::next_in_IK_sequence(NULL, K);
	while (I) {
		EmitArrays::iname_entry(RTInstances::value_iname(I));
		I = InstanceCounting::next_in_IK_sequence(I, K);
	}
