[EqualitySchemas::] Equality Schemas.

To define how to compile a comparison of two values.

@ For most word-value kinds, it's easy to compare two values to see if they are
equal: all we need is the |==| operator. But for pointer-value kinds, that
would simply tell us whether they point to the same block of data on the
heap, whereas we need in fact to compare the blocks they point to. So the
kind system makes it possible for each individual kind to decide how values
should be compared, returning an I6 schema prototype to compare |*1| and |*2|.

What happens at run-time when we test to see if value V equals value W,
or change storage object S so that it now contains value T, depends on the
kind of values we are discussing. If there were only word-based values in
Inform (as was the case until September 2007), there would be little to
do here, as the comparison would simply compile to |V == W|, while the
storage would be a matter of either |S = W;| or some more exotic case
along the lines of |StorageRoutineWrite(S, W);|.

But once pointers to blocks are allowed, this becomes more interesting.
Now the comparison needs to be a deep one, that is, we want to test whether
two texts (say) have the same textual content -- not whether we are
holding two pointers to the same blocks in memory, which is what a simple
comparison would achieve. Such a test is called "deep comparison", and
similarly, we must assign by transferring the contents of the blocks of
data, not merely the pointer to them, which is a "deep copy".

=
text_stream *EqualitySchemas::interpret_equality(kind *left, kind *right) {
	LOGIF(KIND_CHECKING, "Interpreting equality test of kinds %u, %u\n", left, right);

	if ((Kinds::eq(left, K_truth_state)) || (Kinds::eq(right, K_truth_state)))
		return I"(*1 && true) == (*2 && true)";

	kind_constructor *L = NULL, *R = NULL;
	if ((left) && (right)) { L = left->construct; R = right->construct; }

	kind_constructor_comparison_schema *dtcs;
	for (dtcs = L->first_comparison_schema; dtcs; dtcs = dtcs->next_comparison_schema) {
		if (Str::len(dtcs->comparator_unparsed) > 0) {
			dtcs->comparator = KindConstructors::parse(dtcs->comparator_unparsed);
			Str::clear(dtcs->comparator_unparsed);
		}
		if (R == dtcs->comparator) return dtcs->comparison_schema;
	}

	if (KindConstructors::uses_block_values(L)) {
		if (KindConstructors::allow_word_as_pointer(L, R)) {
			local_block_value *pall =
				Frames::allocate_local_block_value(Kinds::base_construction(L));
			text_stream *promotion = Str::new();
			WRITE_TO(promotion, "*=-ComparePV(*1, CastPV(%S, *#2, *2))==0",
				pall->to_refer->prototype);
			return promotion;
		}
	}

	text_stream *cr = Kinds::Behaviour::get_comparison_routine(left);
	if ((Str::len(cr) == 0) ||
		(Str::eq_wide_string(cr, U"signed")) ||
		(Str::eq_wide_string(cr, U"UnsignedCompare"))) return I"*=-*1 == *2";
	return I"*=- *_1(*1, *2) == 0";
}
