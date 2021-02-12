[Properties::ProvisionRelation::] The Provision Relation.

To define the provision relation, which determines which properties
can be held by which objects.

@ As we've seen, assertions assigning properties ("A scene has a time called
the expected duration") result in properties being created -- here "expected
duration" -- and then in suitable propositions being asserted as true.

These propositions are written in terms of the provision predicate: for
example, provision(scene, expected duration). This is the only way to
grant permission to hold a property within the world model.

= (early code)
binary_predicate *R_provision = NULL;

@h Family.

=
bp_family *provision_bp_family = NULL;

void Properties::ProvisionRelation::start(void) {
	provision_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(provision_bp_family, STOCK_BPF_MTID, Properties::ProvisionRelation::stock);
	METHOD_ADD(provision_bp_family, TYPECHECK_BPF_MTID, Properties::ProvisionRelation::REL_typecheck);
	METHOD_ADD(provision_bp_family, ASSERT_BPF_MTID, Properties::ProvisionRelation::REL_assert);
	METHOD_ADD(provision_bp_family, SCHEMA_BPF_MTID, Properties::ProvisionRelation::REL_compile);
	METHOD_ADD(provision_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, Properties::ProvisionRelation::REL_describe_for_problems);
	METHOD_ADD(provision_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID, Properties::ProvisionRelation::REL_describe_briefly);
}

@h Initial stock.
There's just one relation of this kind, and it's hard-wired in.

=
void Properties::ProvisionRelation::stock(bp_family *self, int n) {
	if (n == 1) {
		R_provision =
			BinaryPredicates::make_pair(provision_bp_family,
				BPTerms::new(NULL), BPTerms::new(NULL),
				I"provides", NULL, NULL, NULL,
				PreformUtilities::wording(<relation-names>, PROVISION_RELATION_NAME));
		BinaryPredicates::set_index_details(R_provision, "value", "property");
	}
}

@h Typechecking.
Any property can in principle be assigned to any inference subject (as we'll
see in the next chapter), so there's really no restriction on the left term.
The right term, of course, has to be a property.

=
int Properties::ProvisionRelation::REL_typecheck(bp_family *self, binary_predicate *bp,
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
int Properties::ProvisionRelation::REL_assert(bp_family *self, binary_predicate *bp,
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
int Properties::ProvisionRelation::REL_compile(bp_family *self, int task, binary_predicate *bp,
	annotated_i6_schema *asch) {
	if (task == TEST_ATOM_TASK) {
		kind *K = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt0);
		property *prn = Rvalues::to_property(asch->pt1.constant);
		if (K) {
			if (prn) {
				if (Kinds::Behaviour::is_object(K))
					@<Compile an I6 run-time test of property provision@>
				else
					@<Determine the result now, since we know already, and compile only the outcome@>;
				return TRUE;
			} else if (Kinds::Behaviour::is_object(K)) {
				kind *PK = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt1);
				if (Kinds::get_construct(PK) == CON_property) {
					if (Kinds::eq(K_truth_state, Kinds::unary_construction_material(PK)))
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
	if (World::Permissions::find(KindSubjects::from_kind(K), prn, TRUE))
		Calculus::Schemas::modify(asch->schema, "true");
	else
		Calculus::Schemas::modify(asch->schema, "false");

@h Problem message text.
Nothing special is needed here.

=
int Properties::ProvisionRelation::REL_describe_for_problems(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
void Properties::ProvisionRelation::REL_describe_briefly(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	WRITE("provision");
}
