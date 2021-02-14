[InstanceAdjectives::] Instances as Adjectives.

When instances are adjectives as well as nouns.

@ Some constant names can be used adjectivally, but not others. This happens
when their kind's name coincides with a name for a property, as might for
instance happen with "colour". In other words, because it is reasonable
that a ball might have a colour, we can declare that "the ball is green",
or speak of "something blue", whereas "number" is not a coinciding property,
and we would not ordinarily write "the ball is 4".[1]

These instances make "enumerative adjectives" because they arise from
enumerations such as:

>> The ball can be red, green or blue.

[1] A quirk in English does allow this, implicitly construing number as an
age property, but we don't go there in Inform.

=
adjective_meaning_family *enumerative_amf = NULL;

void InstanceAdjectives::start(void) {
	enumerative_amf = AdjectiveMeanings::new_family(2);
	METHOD_ADD(enumerative_amf, ASSERT_ADJM_MTID, InstanceAdjectives::assert);
}

int InstanceAdjectives::is_enumerative(adjective_meaning *am) {
	if ((am) && (am->family == enumerative_amf)) return TRUE;
	return FALSE;
}

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
	adjective *adj = Adjectives::declare(NW, NULL);
	am = AdjectiveMeanings::new(enumerative_amf, STORE_POINTER_instance(I), NW);
	I->as_adjective = AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	if (singleton) AdjectiveMeaningDomains::set_from_instance(am, singleton);
	else if (set) AdjectiveMeaningDomains::set_from_kind(am, set);

@<Write I6 schemas for asserting and testing this use of the instance@> =
	i6_schema *sch = AdjectiveMeanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
	Calculus::Schemas::modify(sch,
		"GProperty(%k, *1, %n) == %d",
			D, Properties::iname(P), I->enumeration_index);
	sch = AdjectiveMeanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, FALSE);
	Calculus::Schemas::modify(sch,
		"WriteGProperty(%k, *1, %n, %d)",
			D, Properties::iname(P), I->enumeration_index);

@ So that creates the adjectival form, and access to it is provided by:

=
adjective *InstanceAdjectives::as_adjective(instance *I) {
	return I->as_adjective;
}

@ Asserting such an adjective simply asserts that the property has this value:
for example, asserting "green" on X is saying that the value of the "colour"
property of X is "green".

We refuse to assert the falseness of such an adjective since it's unclear what
to infer from, e.g., "the ball is not green": is it red, or blue?

=
int InstanceAdjectives::assert(adjective_meaning_family *f, adjective_meaning *am, 
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	if (parity == FALSE) return FALSE;
	instance *I = RETRIEVE_POINTER_instance(am->family_specific_data);
	property *P = Properties::Conditions::get_coinciding_property(Instances::to_kind(I));
	if (P == NULL) internal_error("enumerative adjective on non-property");
	World::Inferences::draw_property(infs_to_assert_on, P, Rvalues::from_instance(I));
	return TRUE;
}
