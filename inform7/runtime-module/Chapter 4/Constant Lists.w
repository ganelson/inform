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
		packaging_state save = EmitArrays::begin_late(N, K_value);
		EmitArrays::iname_entry(ConstantLists::iname(ll));
		EmitArrays::numeric_entry(0);
		EmitArrays::end(save);
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
	packaging_state save = EmitArrays::begin(ll->ll_iname, K_value);
	llist_entry *lle;
	int n = 0;
	for (lle = ll->first_llist_entry; lle; lle = lle->next_llist_entry) n++;

	RTKinds::emit_block_value_header(Lists::kind_of_ll(ll, FALSE), TRUE, n+2);

	RTKinds::emit_strong_id(ll->entry_kind);

	EmitArrays::numeric_entry((inter_ti) n);
	for (lle = ll->first_llist_entry; lle; lle = lle->next_llist_entry)
		CompileValues::to_array_entry_of_kind(
			lle->llist_entry_value, ll->entry_kind);
	EmitArrays::end(save);

@ The default list of any given kind is empty.

=
void ConstantLists::compile_default_list(inter_name *identifier, kind *K) {
	packaging_state save = EmitArrays::begin(identifier, K_value);
	RTKinds::emit_block_value_header(K, TRUE, 2);
	RTKinds::emit_strong_id(Kinds::unary_construction_material(K));
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
}

int ConstantLists::extent_of_instance_list(kind *K) {
	if (Kinds::Behaviour::is_an_enumeration(K))
		return Kinds::Behaviour::get_highest_valid_value_as_integer(K);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		int N = 0;
		instance *I;
		LOOP_OVER_INSTANCES(I, K) N++;
		return N;
	}
	return -1;
}

inter_name *ConstantLists::get_instance_list(kind *K) {
	int N = ConstantLists::extent_of_instance_list(K);
	if (N < 0) return NULL;
	inter_name *iname = Kinds::Constructors::list_iname(Kinds::get_construct(K));
	if (iname == NULL) {
		TEMPORARY_TEXT(ILN)
		WRITE_TO(ILN, "ILIST_");
		Kinds::Textual::write(ILN, K);
		Str::truncate(ILN, 31);
		LOOP_THROUGH_TEXT(pos, ILN) {
			Str::put(pos, Characters::toupper(Str::get(pos)));
			if (Characters::isalnum(Str::get(pos)) == FALSE) Str::put(pos, '_');
		}
		iname = Hierarchy::make_iname_with_specific_name(ILIST_HL,
			InterSymbolsTables::render_identifier_unique(Produce::main_scope(Emit::tree()), ILN),
				Kinds::Behaviour::package(K));
		DISCARD_TEXT(ILN)
		Hierarchy::make_available(iname);

		packaging_state save = EmitArrays::begin(iname, K_value);
		RTKinds::emit_block_value_header(Kinds::unary_con(CON_list_of, K), TRUE, N + 2);
		RTKinds::emit_strong_id(K);
		EmitArrays::numeric_entry((inter_ti) N);
		if (Kinds::Behaviour::is_an_enumeration(K)) {
			for (int i = 1; i <= N; i++) {
				EmitArrays::numeric_entry((inter_ti) i);
			}
		}		
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			instance *I = PL::Counting::next_instance_of(NULL, K);
			while (I) {
				EmitArrays::iname_entry(RTInstances::iname(I));
				I = PL::Counting::next_instance_of(I, K);
			}
		}
		EmitArrays::end(save);
		Kinds::Constructors::set_list_iname(Kinds::get_construct(K), iname);
	}
	inter_name *bc = RTKinds::new_block_constant_iname();
	packaging_state save = EmitArrays::begin_late(bc, K_value);
	EmitArrays::iname_entry(iname);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	return bc;
}
