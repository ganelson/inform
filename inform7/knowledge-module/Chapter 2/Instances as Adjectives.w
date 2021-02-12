[InstanceAdjectives::] Instances as Adjectives.

When instances are adjectives as well as nouns.

@ Some constant names can be used adjectivally, but not others. This happens
when their kind's name coincides with a name for a property, as might for
instance happen with "colour". In other words, because it is reasonable
that a ball might have a colour, we can declare that "the ball is green",
or speak of "something blue", whereas "number" is not a coinciding property,
and we would not ordinarily write "the ball is 4".[1]

[1] A quirk in English does allow this, implicitly construing number as an
age property, but we don't go there in Inform.

@ Let's reconstruct the chain of events, shall we? It has been found that an
instance, though a noun, must be used as an adjective: for example, "red".
Inform has run through the permissions for the property ("colour") in
question, and found that, say, it's a property of doors, scenes and also
a single piece of litmus paper. Each of these three is an inference subject,
so //InferenceSubjects::make_adj_const_domain// was called for each in turn.

By different means, those calls all ended up by passing the buck onto the
following function: twice with the domain |set| being a kind ("door" and then
"scene"), once with |set| being null and |singleton| an instance ("litmus paper").

So, then, we make the instance |I| have an adjectival use setting the property
|P| when applied to either |set| or |singleton|, whichever is not null.

=
void InstanceAdjectives::make_adjectival(instance *I, property *P,
	kind *set, instance *singleton) {
	kind *D = NULL;
	@<Find the kind domain within which the adjective applies@>;
	adjective_meaning *am = NULL;
	@<Create the adjective meaning for this use of the instance@>;
	@<Write I6 schemas for asserting and testing this use of the instance@>;
}

@<Find the kind domain within which the adjective applies@> =
	if (singleton) D = Instances::to_kind(singleton);
	else if (set) D = set;
	if (D == NULL) internal_error("No adjectival constant domain");

@<Create the adjective meaning for this use of the instance@> =
	wording NW = Instances::get_name(I, FALSE);
	am = Adjectives::Meanings::new(ENUMERATIVE_KADJ, STORE_POINTER_instance(I), NW);
	I->as_adjective = Adjectives::Meanings::declare(am, NW, 4);
	if (singleton) Adjectives::Meanings::set_domain_from_instance(am, singleton);
	else if (set) Adjectives::Meanings::set_domain_from_kind(am, set);

@<Write I6 schemas for asserting and testing this use of the instance@> =
	i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
	Calculus::Schemas::modify(sch,
		"GProperty(%k, *1, %n) == %d",
			D, Properties::iname(P), I->enumeration_index);
	sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, FALSE);
	Calculus::Schemas::modify(sch,
		"WriteGProperty(%k, *1, %n, %d)",
			D, Properties::iname(P), I->enumeration_index);

@ And access to the adjectival form is provided by:

=
adjective *InstanceAdjectives::as_adjective(instance *I) {
	return I->as_adjective;
}

adjective_meaning *InstanceAdjectives::parse(parse_node *pn,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	return NULL;
}

void InstanceAdjectives::compiling_soon(adjective_meaning *am, instance *I, int T) {
}

int InstanceAdjectives::compile(instance *I, int T, int emit_flag, ph_stack_frame *phsf) {
	return FALSE;
}

@ Asserting such an adjective simply asserts its property. We refuse to assert
the falseness of such an adjective since it's unclear what to infer from, e.g.,
"the ball is not green": we would need to give it a colour, and there's no
good basis for choosing which.

=
int InstanceAdjectives::assert(instance *I,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	if (parity == FALSE) return FALSE;
	property *P = Properties::Conditions::get_coinciding_property(Instances::to_kind(I));
	if (P == NULL) internal_error("enumerative adjective on non-property");
	World::Inferences::draw_property(infs_to_assert_on, P, Rvalues::from_instance(I));
	return TRUE;
}
