[ConstantLists::] Constant Lists.

In this section we compile I6 arrays for constant lists arising
from braced literals.

@ That leaves just the compilation of lists at run-time. This used to be a
complex dance with initialisation code interleaved with heap construction,
so there was once a two-page explanation here, but it is now blessedly simple.

=
inter_name *ConstantLists::compile_literal_list(wording W) {
	int incipit = Wordings::first_wn(W);
	literal_list *ll = Lists::find_literal(incipit+1);
	if (ll) {
		Lists::kind_of_ll(ll, FALSE);
		inter_name *N = RTKinds::new_block_constant_iname();
		packaging_state save = Emit::named_late_array_begin(N, K_value);
		Emit::array_iname_entry(ConstantLists::iname(ll));
		Emit::array_numeric_entry(0);
		Emit::array_end(save);
		return N;
	}
	return NULL;
}

inter_name *ConstantLists::iname(literal_list *ll) {
	if (ll->ll_iname == NULL) {
		package_request *PR = Hierarchy::package_in_enclosure(LITERALS_HAP);
		ll->ll_iname = Hierarchy::make_iname_in(LIST_LITERAL_HL, PR);
	}
	return ll->ll_iname;
}

@ Using:

=
void ConstantLists::compile(void) {
	literal_list *ll;

	if (problem_count == 0)
		LOOP_OVER(ll, literal_list)
			if ((ll->list_compiled == FALSE) && (ll->ll_iname)) {
				ll->list_compiled = TRUE;
				current_sentence = ll->list_text;
				Lists::kind_of_ll(ll, TRUE);
				if (problem_count == 0) @<Actually compile the list array@>;
			}
}

@ These are I6 word arrays, with the contents:

(a) a zero word, used as a flag at run-time;
(b) the strong kind ID of the kind of entry the list holds (not the kind of
the list!);
(c) the number of entries in the list; and
(d) that number of values, each representing one entry.

@<Actually compile the list array@> =
	packaging_state save = Emit::named_array_begin(ll->ll_iname, K_value);
	llist_entry *lle;
	int n = 0;
	for (lle = ll->first_llist_entry; lle; lle = lle->next_llist_entry) n++;

	RTKinds::emit_block_value_header(Lists::kind_of_ll(ll, FALSE), TRUE, n+2);

	RTKinds::emit_strong_id(ll->entry_kind);

	Emit::array_numeric_entry((inter_ti) n);
	for (lle = ll->first_llist_entry; lle; lle = lle->next_llist_entry)
		CompileValues::to_array_entry_of_kind(
			lle->llist_entry_value, ll->entry_kind);
	Emit::array_end(save);

@ The default list of any given kind is empty.

=
void ConstantLists::compile_default_list(inter_name *identifier, kind *K) {
	packaging_state save = Emit::named_array_begin(identifier, K_value);
	RTKinds::emit_block_value_header(K, TRUE, 2);
	RTKinds::emit_strong_id(Kinds::unary_construction_material(K));
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}
