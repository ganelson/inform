[VersionNumberLiterals::] Version Number Literals.

Explicit actions stored in memory as literals.

@h Runtime representation.
Literal version numbers arise from source text such as:
= (text as Inform 7)
	let V be v2.31.1;
=
This is called only from the actions feature; in Basic Inform no stored actions
exist, so if the function is called then an internal error will be thrown.

Version numbers are stored in small blocks, always of size 3. There are no
long blocks.
= (text)
	                    small block:
	V ----------------> major version
	                    minor version
	                    patch version
=
See //Architecture32Kit// for more.

The default is "v0.0.0":
=
inter_name *VersionNumberLiterals::default(void) {
	inter_name *small_block = Enclosures::new_small_block_for_constant();
	packaging_state save = EmitArrays::begin_unchecked(small_block);
	TheHeap::emit_block_value_header(K_version_number, FALSE, 3);
	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	return small_block;
}

inter_name *VersionNumberLiterals::small_block(semantic_version_number V) {
	if (K_version_number == NULL) internal_error("no version number kind exists");
	inter_name *small_block = Enclosures::new_small_block_for_constant();
	packaging_state save = EmitArrays::begin_unchecked(small_block);

	TheHeap::emit_block_value_header(K_version_number, FALSE, 3);
	for (int s=0; s<3; s++) {
		int v = V.version_numbers[s];
		if (v != -1) EmitArrays::numeric_entry((inter_ti) v);
		else EmitArrays::numeric_entry(0);
	}
	EmitArrays::end(save);
	return small_block;
}

