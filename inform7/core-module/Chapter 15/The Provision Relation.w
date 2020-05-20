[Properties::ProvisionRelation::] The Provision Relation.

To define the provision relation, which determines which properties
can be held by which objects.

@h Definitions.

@ As we've seen, assertions assigning properties ("A scene has a time called
the expected duration") result in properties being created -- here "expected
duration" -- and then in suitable propositions being asserted as true.

These propositions are written in terms of the provision predicate: for
example, provision(scene, expected duration). This is the only way to
grant permission to hold a property within the world model.

= (early code)
binary_predicate *R_provision = NULL;

@h Initial stock.
There's just one relation of this kind, and it's hard-wired in.

=
void Properties::ProvisionRelation::REL_create_initial_stock(void) {
	R_provision =
		BinaryPredicates::make_pair(PROVISION_KBP,
			BinaryPredicates::new_term(NULL), BinaryPredicates::new_term(NULL),
			I"provides", NULL, NULL, NULL, NULL,
			Preform::Nonparsing::wording(<relation-names>, PROVISION_RELATION_NAME));
	BinaryPredicates::set_index_details(R_provision, "value", "property");
}

@h Second stock.
There is none, of course.

=
void Properties::ProvisionRelation::REL_create_second_stock(void) {
}

@h Typechecking.
Any property can in principle be assigned to any inference subject (as we'll
see in the next chapter), so there's really no restriction on the left term.
The right term, of course, has to be a property.

=
int Properties::ProvisionRelation::REL_typecheck(binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	if (Kinds::get_construct(kinds_of_terms[1]) == CON_property) return ALWAYS_MATCH;
	Problems::quote_kind(4, kinds_of_terms[1]);
	StandardProblems::tcp_problem(_p_(PM_BadProvides), tck,
		"that asks whether something provides something, and in Inform 'to provide' "
		"means that an object (or value) has a property attached - for instance, "
		"containers provide the property 'carrying capacity'. Here, though, we have "
		"%4 rather than the name of a property.");
	return NEVER_MATCH;
}

@h Assertion.
If we assert that, say, vehicles provide "colour", then we are implicitly
enabling adjectives like "green" or "blue" to apply to vehicles, so we
must make sure any such meanings are defined.

=
int Properties::ProvisionRelation::REL_assert(binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	property *prn = Rvalues::to_property(spec1);
	if ((infs0) && (prn)) {
		World::Permissions::grant(infs0, prn, TRUE);
		Instances::update_adjectival_forms(prn);
		return TRUE;
	}
	return FALSE;
}

@h Compilation.
Run-time is too late to change which objects provide what, so this relation
can't be changed at compile time.

=
int Properties::ProvisionRelation::REL_compile(int task, binary_predicate *bp,
	annotated_i6_schema *asch) {
	if (task == TEST_ATOM_TASK) {
		kind *K = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt0);
		property *prn = Rvalues::to_property(asch->pt1.constant);
		if (K) {
			if (prn) {
				if (Kinds::Compare::le(K, K_object))
					@<Compile an I6 run-time test of property provision@>
				else
					@<Determine the result now, since we know already, and compile only the outcome@>;
				return TRUE;
			} else if (Kinds::Compare::le(K, K_object)) {
				kind *PK = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt1);
				if (Kinds::get_construct(PK) == CON_property) {
					if (Kinds::Compare::eq(K_truth_state, Kinds::unary_construction_material(PK)))
						Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, true, *2)");
					else
						Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, false, *2)");
					return TRUE;
				}
			}
		}
	}
	return FALSE;
}

@ Since type-checking for "object" is too weak to make it certain what kind
of object the left operand is, we can only test property provision at run-time:

@<Compile an I6 run-time test of property provision@> =
	if (Properties::is_value_property(prn))
		Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, false, *2)");
	else
		Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, true, *2)");

@ For all other kinds, type-checking is strong enough that we can prove the
answer now.

@<Determine the result now, since we know already, and compile only the outcome@> =
	if (World::Permissions::find(Kinds::Knowledge::as_subject(K), prn, TRUE))
		Calculus::Schemas::modify(asch->schema, "true");
	else
		Calculus::Schemas::modify(asch->schema, "false");

@h Problem message text.
Nothing special is needed here.

=
int Properties::ProvisionRelation::REL_describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
