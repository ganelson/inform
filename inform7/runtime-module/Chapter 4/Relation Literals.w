[RelationLiterals::] Relation Literals.

In fact there is only one literal relation: the empty one, used as a default
value.

@ It seems odd to call it a literal, but this:
= (text as Inform 7)
	let Q be a relation of numbers;
=
sets up |Q| to be a new empty relation -- one in which, as yet, no number is
related to any other.

The following function compiles an array ready to be |Q|, with some initial
capacity in it to absorb relationships forged at runtime. This is the default
value of kinds using the "relation of K to L" constructor.

The runtime representation of temporary relations like this one is complex.
See //Relations// and //BasicInformKit: Relations//.

=
inter_name *RelationLiterals::default(kind *K) {
	inter_name *small_block = Enclosures::new_small_block_for_constant();
	packaging_state save = EmitArrays::begin_late(small_block, K_value);
	RTKinds::emit_block_value_header(K, FALSE, 34);
	EmitArrays::null_entry();
	EmitArrays::null_entry();
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "anonymous "); Kinds::Textual::write(DVT, K);
	EmitArrays::text_entry(DVT);
	DISCARD_TEXT(DVT)

	EmitArrays::iname_entry(Hierarchy::find(TTF_SUM_HL));
	EmitArrays::numeric_entry(7);
	RTKinds::emit_strong_id(K);
	kind *EK = Kinds::unary_construction_material(K);
	if (Kinds::Behaviour::uses_pointer_values(EK))
		EmitArrays::iname_entry(Hierarchy::find(HASHLISTRELATIONHANDLER_HL));
	else
		EmitArrays::iname_entry(Hierarchy::find(DOUBLEHASHSETRELATIONHANDLER_HL));

	EmitArrays::text_entry(I"an anonymous relation");

	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	for (int i=0; i<24; i++) EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	return small_block;
}
