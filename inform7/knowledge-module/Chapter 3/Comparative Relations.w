[ComparativeRelations::] Comparative Relations.

When a measurement adjective like "tall" is defined, so is a comparative
relation like "taller than".

@h Family.
There can be many of these. Each is associated with a property, but some
properties may never be measured ("carrying capacity", say) while others may
have more than one comparative (a property such as "height" might have
relations for both "shorter" and "taller"). So comparative relations do not
correspond exactly with properties.

= (early code)
bp_family *property_comparison_bp_family = NULL;

@ =
void ComparativeRelations::start(void) {
	property_comparison_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(property_comparison_bp_family, STOCK_BPF_MTID, ComparativeRelations::stock);
	METHOD_ADD(property_comparison_bp_family, TYPECHECK_BPF_MTID, ComparativeRelations::typecheck);
	METHOD_ADD(property_comparison_bp_family, SCHEMA_BPF_MTID, ComparativeRelations::schema);
}

@h Creation.
When an adjective is defined so that it performs an inequality comparison
of a property value, like so:

>> Definition: A woman is tall if her height is 68 or more.

...Inform automatically generates a comparative form (here "taller than").
This is where our comparative relations come from, but the work is done in
//Measurement Adjectives//, not here.

=
void ComparativeRelations::stock(bp_family *self, int n) {
	if (n == 2) Measurements::create_comparatives();
}

@ However, whenever a comparative is made, an instance of the following is
created and attached to it:

=
typedef struct comparative_bp_data {
	struct property *comparative_property; /* (if right way) if a comparative adjective */
	int comparison_sign; /* ...and |+1| or |-1| according to sign of definition */
	CLASS_DEFINITION
} comparative_bp_data;

void ComparativeRelations::initialise(binary_predicate *bp,
	int sign, property *prn) {
	comparative_bp_data *D = CREATE(comparative_bp_data);
	D->comparison_sign = sign; D->comparative_property = prn;
	bp->family_specific = STORE_POINTER_comparative_bp_data(D);
}

@h Typechecking.
Comparatives can be used in two different senses, which we'll call absolute
and relative:

(*) "if Geoff is taller than 4 foot 5 inches" is absolute, while
(*) "if Geoff is taller than Miranda" is relative.

To allow for these two different usages, we'll typecheck this asymmetrically;
the left term is typechecked as usual, but the right is more leniently handled.

=
int ComparativeRelations::typecheck(bp_family *self, binary_predicate *bp,
	kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {

	if ((kinds_required[0]) &&
		(Kinds::compatible(kinds_of_terms[0], kinds_required[0]) == NEVER_MATCH)) {
		LOG("Term 0 is %u not %u\n", kinds_of_terms[0], kinds_required[0]);
		TypecheckPropositions::issue_bp_typecheck_error(bp,
			kinds_of_terms[0], kinds_of_terms[1], tck);
		return NEVER_MATCH;
	}

	property *prn = Properties::property_with_same_name_as(kinds_of_terms[1]);
	comparative_bp_data *D = RETRIEVE_POINTER_comparative_bp_data(bp->family_specific);
	if ((prn) && (prn != D->comparative_property)) {
		if (tck->log_to_I6_text)
			LOG("Comparative misapplied to $Y not $Y\n", prn, D->comparative_property);
		Problems::quote_property(4, D->comparative_property);
		Problems::quote_property(5, prn);
		StandardProblems::tcp_problem(_p_(PM_ComparativeMisapplied), tck,
			"that ought to make a comparison of %4 not %5.");
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@h Compilation.

=
int ComparativeRelations::schema(bp_family *self, int task, binary_predicate *bp,
	annotated_i6_schema *asch) {
	if (task == TEST_ATOM_TASK)
		@<Rewrite the annotated schema if it turns out to be an absolute comparison@>;
	return FALSE;
}

@ And here the relative and absolute cases have to be compiled differently.

@<Rewrite the annotated schema if it turns out to be an absolute comparison@> =
	kind *st[2];
	st[0] = Deferrals::Cinders::kind_of_value_of_term(asch->pt0);
	st[1] = Deferrals::Cinders::kind_of_value_of_term(asch->pt1);
	if ((Kinds::eq(st[0], st[1]) == FALSE) &&
		(Properties::can_name_coincide_with_kind(st[1]))) {
		property *prn = Properties::property_with_same_name_as(st[1]);
		if (prn) {
			comparative_bp_data *D =
				RETRIEVE_POINTER_comparative_bp_data(bp->family_specific);
			Calculus::Schemas::modify(asch->schema,
				"*1.%n %s *2", RTProperties::iname(prn),
				Measurements::strict_comparison(D->comparison_sign));
			return TRUE;
		}
	}
