[Properties::SameRelations::] Same Property Relation.

Each value property has an associated relation to compare its value
between two holders.

@h Initial stock.
There is no initial stock of these, since there are no value properties yet
when Inform starts up.

=
void Properties::SameRelations::REL_create_initial_stock(void) {
}

@h Second stock.
If, for example, there is a value property called "height" then a BP is
constructed in order to serve as the meaning of "the same height as" in text
like this:

>> if Ms Cregg is the same height as Big Bird, ...

We again have two schemas, because it makes sense not only to perform
the comparison but also to force it true thus:

>> now Ms Cregg is the same height as Big Bird;

(That couldn't be arranged for strict inequality comparisons like "taller
than" because it is unclear just how much taller than Big Bird we would have
to make C. J.)

=
void Properties::SameRelations::REL_create_second_stock(void) {
	property *prn;
	LOOP_OVER(prn, property) {
		if (Properties::is_value_property(prn)) {
			vocabulary_entry *rel_name;
			inter_name *i6_pname = Properties::iname(prn);
			@<Work out the name for the same-property-value-as relation@>;

			TEMPORARY_TEXT(relname);
			WRITE_TO(relname, "%V", rel_name);
			binary_predicate *bp = BinaryPredicates::make_pair(PROPERTY_SAME_KBP,
				BinaryPredicates::new_term(NULL), BinaryPredicates::new_term(NULL),
				relname, NULL, NULL,
				Calculus::Schemas::new("*1.%n = *2.%n", i6_pname, i6_pname),
				Calculus::Schemas::new("*1.%n == *2.%n", i6_pname, i6_pname),
				WordAssemblages::lit_1(rel_name));
			DISCARD_TEXT(relname);
			bp->same_property = prn;
			Properties::SameRelations::register_same_property_as(bp, Properties::get_name(prn));
		}
	}
}

void Properties::SameRelations::register_same_property_as(binary_predicate *root, wording W) {
	if (Wordings::empty(W)) return;
	set_where_created = current_sentence;
	verb_meaning vm = VerbMeanings::new(root, NULL);
	preposition_identity *prep =
		Prepositions::make(
			Preform::Nonparsing::merge(<same-property-as-construction>, 0,
				WordAssemblages::from_wording(W)), FALSE);
	Verbs::add_form(copular_verb, prep, NULL, vm, SVO_FS_BIT);
}

@ In I7 source text, this relation is called "same-height-as", but we don't
mention this in the documentation because (for timing reasons) it doesn't
exist when the new-verb sentences are being parsed: so writing

>> The verb to be level with implies the same-height-as relation.

cannot work. Nothing is really lost by this, since it's easy enough to
define an identically-behaving relation by hand:

>> Levelling relates a person (called Mr X) to a person (called Mr Y) when the height of Mr X is the height of Mr Y.
>> The verb to be level with implies the levelling relation.

Relations need to have single-word names, but properties don't, so we shrink
spaces to hyphens: thus, for instance, "same-carrying-capacity-as". We also
truncate to a reasonable length, ensuring that the result doesn't exceed
|MAX_WORD_LENGTH| or overflow our storage for a debugging-log name.

@<Work out the name for the same-property-value-as relation@> =
	TEMPORARY_TEXT(i7_name);
	WRITE_TO(i7_name, "same-%<W-as", prn->name);
	LOOP_THROUGH_TEXT(pos, i7_name)
		if (Str::get(pos) == ' ') Str::put(pos, '-');
	wording I7W = Feeds::feed_text_expanding_strings(i7_name);
	rel_name = Lexer::word(Wordings::first_wn(I7W));
	DISCARD_TEXT(i7_name);

@h Typechecking.
We just let the standard machinery do its work.

=
int Properties::SameRelations::REL_typecheck(binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return DECLINE_TO_MATCH;
}

@h Assertion.

=
int Properties::SameRelations::REL_assert(binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	return FALSE;
}

@h Compilation.
Again we need do nothing special.

=
int Properties::SameRelations::REL_compile(int task,
	binary_predicate *bp, annotated_i6_schema *asch) {
	return FALSE;
}

@ =
property *Properties::SameRelations::bp_get_same_as_property(binary_predicate *bp) {
	return bp->same_property;
}

@h Problem message text.

=
int Properties::SameRelations::REL_describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
