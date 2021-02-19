[SameAsRelations::] Same Property Relation.

Each value property has an associated relation to compare its value between
two owners.

@h Family.

=
bp_family *same_property_bp_family = NULL;

void SameAsRelations::start(void) {
	same_property_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(same_property_bp_family, STOCK_BPF_MTID, SameAsRelations::stock);
	METHOD_ADD(same_property_bp_family, TYPECHECK_BPF_MTID, SameAsRelations::typecheck);
}

@h Stock.
If, for example, there is a value property called "height" then we make a
relation to serve as the meaning of "the same height as" in text like this:

>> if Ms Cregg is the same height as Big Bird, ...

We have two schemas, because it now[1] makes sense not only to perform
the comparison but also to force it true thus:

>> now Ms Cregg is the same height as Big Bird;

[1] That couldn't be arranged for strict inequality comparisons like "taller
than" -- see //Comparative Relations// -- because it is unclear just how much
taller than Big Bird we would have to make C. J.

=
void SameAsRelations::stock(bp_family *self, int n) {
	if (n == 2) {
		property *prn;
		LOOP_OVER(prn, property) {
			if ((Properties::is_value_property(prn)) &&
				(Wordings::nonempty(prn->name))) {
				vocabulary_entry *rel_name;
				inter_name *i6_pname = RTProperties::iname(prn);
				@<Work out the name for the same-property-value-as relation@>;

				TEMPORARY_TEXT(relname)
				WRITE_TO(relname, "%V", rel_name);
				binary_predicate *bp =
					BinaryPredicates::make_pair(same_property_bp_family,
						BPTerms::new(NULL), BPTerms::new(NULL),
						relname, NULL,
						Calculus::Schemas::new("*1.%n = *2.%n", i6_pname, i6_pname),
						Calculus::Schemas::new("*1.%n == *2.%n", i6_pname, i6_pname),
						WordAssemblages::lit_1(rel_name));
				DISCARD_TEXT(relname)
				bp->family_specific = STORE_POINTER_property(prn);
				SameAsRelations::register_same_property_as(bp,
					Properties::get_name(prn));
			}
		}
	}
}

@ The family-specific data in this family is just a pointer to the property:

=
property *SameAsRelations::bp_get_same_as_property(binary_predicate *bp) {
	if (bp->relation_family != same_property_bp_family) return NULL;
	if (bp->right_way_round == FALSE) return NULL;
	return RETRIEVE_POINTER_property(bp->family_specific);
}

@ When we make one of these, we also make a prepositional form, as in the
example "the same height as":

=
<same-property-as-construction> ::=
	the same ... as

@ =
void SameAsRelations::register_same_property_as(binary_predicate *root,
	wording W) {
	if (Wordings::empty(W)) return;
	verb_meaning vm = VerbMeanings::regular(root);
	preposition *prep =
		Prepositions::make(
			PreformUtilities::merge(<same-property-as-construction>, 0,
				WordAssemblages::from_wording(W)), FALSE, current_sentence);
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
spaces to hyphens: thus, for instance, "same-carrying-capacity-as".

@<Work out the name for the same-property-value-as relation@> =
	TEMPORARY_TEXT(i7_name)
	WRITE_TO(i7_name, "same-%<W-as", prn->name);
	LOOP_THROUGH_TEXT(pos, i7_name)
		if (Str::get(pos) == ' ') Str::put(pos, '-');
	wording I7W = Feeds::feed_text_expanding_strings(i7_name);
	rel_name = Lexer::word(Wordings::first_wn(I7W));
	DISCARD_TEXT(i7_name)

@h Typechecking.
We just let the standard machinery do its work.

=
int SameAsRelations::typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return DECLINE_TO_MATCH;
}
