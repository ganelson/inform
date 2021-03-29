[AdjectiveMeaningDomains::] Adjective Meaning Domains.

What a single sense of an adjective can apply to: perhaps a kind or an instance.

@h Introduction.
Each //adjective_meaning// structure contains one of these. The "domain" of
an adjective meaning is the set of values to which it can validly apply. For
example, the meaning of "odd" for numbers has the set of all numbers as its
domain, whereas the sense here:

>> Mrs Elspeth Spong can be odd, eccentric or mildly dotty.

has only a single instance as domain -- Mrs Spong herself.

We represent this as an inference subject, since that can represent either an
instance or a base kind; but note also the |domain_kind| field. At first sight
this is redundant, but in fact it isn't, since it enables us to define
adjectives on non-base kinds such as "lists of scenes".

This part of Inform is plagued with timing difficulties, however, where the
domain of an adjective is given to us as text which we cannot yet understand.
For example, if the author defines "A boojum is odd if it is in a dark room",
and "boojum" is a kind yet to be created, we're stuck.

We therefore store such text until later, when the domain can be "determined".

=
typedef struct adjective_domain_data {
	struct wording domain_text; /* text given by author about the domain */
	struct inference_subject *domain_infs; /* what domain the defn applies to */
	struct kind *domain_kind; /* what kind of values */
	int currently_determining; /* are we currently working this out? */
	int problems_thrown; /* number of problems thrown about this domain */
} adjective_domain_data;

void AdjectiveMeaningDomains::log(adjective_domain_data *domain) {
	if (domain->domain_infs == NULL) LOG("domain:'%W'?", domain->domain_text);
	else LOG("domain:($j, %u)", domain->domain_infs, domain->domain_kind);
}

@ If all we have is text:

=
void AdjectiveMeaningDomains::set_from_text(adjective_meaning *am, wording W) {
	am->domain = AdjectiveMeaningDomains::new_from_text(W);
	AdjectiveMeaningDomains::determine_if_possible(am);
}
adjective_domain_data AdjectiveMeaningDomains::new_from_text(wording W) {
	adjective_domain_data domain;	
	domain.domain_text = W;
	domain.domain_infs = NULL;
	domain.domain_kind = NULL;
	domain.currently_determining = FALSE;
	domain.problems_thrown = 0;
	return domain;
}

@ If in fact we know exactly what domain we want, these functions can be used.
Determination on these domains then does nothing, because they are already
pre-determined.

Note that we round up the kind to "object" if it's more specialised than that
-- say, if it's "door" -- because run-time rather than compile-time disambiguation
is used when applying adjectives to objects.

=
void AdjectiveMeaningDomains::set_from_kind(adjective_meaning *am, kind *K) {
	am->domain = AdjectiveMeaningDomains::new_from_kind(K);
}
adjective_domain_data AdjectiveMeaningDomains::new_from_kind(kind *K) {
	adjective_domain_data domain = AdjectiveMeaningDomains::new_from_text(EMPTY_WORDING);
	if ((K == NULL) || (Kinds::Behaviour::is_object(K))) K = K_object;
	domain.domain_infs = KindSubjects::from_kind(K);
	domain.domain_kind = K;
	return domain;
}

void AdjectiveMeaningDomains::set_from_instance(adjective_meaning *am, instance *I) {
	am->domain = AdjectiveMeaningDomains::new_from_instance(I);
}
adjective_domain_data AdjectiveMeaningDomains::new_from_instance(instance *I) {
	adjective_domain_data domain = AdjectiveMeaningDomains::new_from_text(EMPTY_WORDING);
	if (I == NULL) return AdjectiveMeaningDomains::new_from_kind(K_object);
	domain.domain_infs = Instances::as_subject(I);
	domain.domain_kind = Kinds::weaken(Instances::to_kind(I), K_object);
	return domain;
}

@h Determination.
So this is where we determine the domain. Sometimes we allow this to fail
for timing reasons, sometimes we require that it must not fail:

=
void AdjectiveMeaningDomains::determine(adjective_meaning *am) {
	AdjectiveMeaningDomains::determine_inner(am, FALSE);
}
void AdjectiveMeaningDomains::determine_if_possible(adjective_meaning *am) {
	AdjectiveMeaningDomains::determine_inner(am, TRUE);
}

@ This variant is useful to catch circularities like "A big container is big
if...", where the adjective's domain directly or indirectly involves itself:

=
int AdjectiveMeaningDomains::determine_avoiding_circularity(adjective_meaning *am) {
	if (am->domain.currently_determining) @<Issue a problem for a circularity@>;
	am->domain.currently_determining = TRUE;
	AdjectiveMeaningDomains::determine_if_possible(am);
	am->domain.currently_determining = FALSE;
	return TRUE;
}

@<Issue a problem for a circularity@> =
	if (problem_count == 0) {
		current_sentence = am->defined_at;
		StandardProblems::adjective_problem(Task::syntax_tree(), _p_(PM_AdjectiveCircular),
			am->indexing_text, am->domain.domain_text,
			"this doesn't really define an adjective",
			"because it seems to be circular - it is involved in its own definition.");
	}
	return FALSE;

@ =
void AdjectiveMeaningDomains::determine_inner(adjective_meaning *am, 
	int suppress_problems) {
	if (am->domain.domain_infs) return; /* already determined */

	current_sentence = am->defined_at;
	if (Wordings::empty(am->domain.domain_text))
		internal_error("undeclared domain kind for AM");
	parse_node *supplied = NULL;
	if (<s-type-expression>(am->domain.domain_text)) supplied = <<rp>>;
	if (supplied == NULL) @<Reject domain of adjective@>;
	@<Reject domain of adjective unless a kind of value or description of objects@>;
	kind *K = NULL;
	if (Specifications::is_condition(supplied)) {
		if (Specifications::to_kind(supplied)) K = Specifications::to_kind(supplied);
		else K = K_object;
		@<Reject domain of adjective if it is a set of objects which may vary in play@>;
	} else if (Rvalues::is_rvalue(supplied))
		K = Rvalues::to_kind(supplied);
	if (K == NULL) @<Reject domain of adjective@>;
	if (Kinds::Behaviour::is_kind_of_kind(K)) @<Reject domain as vague@>;
	if ((K_understanding) && (Kinds::eq(K, K_understanding))) @<Reject domain as topic@>;
	instance *I = Rvalues::to_object_instance(supplied);
	if (I) supplied = Rvalues::from_instance(I);
	else if (Kinds::Behaviour::is_subkind_of_object(K))
		supplied = Specifications::from_kind(K);
	am->domain.domain_infs = InferenceSubjects::from_specification(supplied);
	am->domain.domain_kind = K;
}

@ Note that we throw only one problem message per AM, as otherwise duplication
can't be avoided.

@<Reject domain of adjective@> =
	if ((suppress_problems) || (am->domain.problems_thrown++ > 0)) return;
	current_sentence = am->defined_at;
	StandardProblems::adjective_problem(Task::syntax_tree(),
		_p_(PM_AdjDomainUnknown),
		am->indexing_text, am->domain.domain_text,
		"this isn't a thing, a kind of thing or a kind of value",
		"and indeed doesn't have any meaning I can make sense of.");
	return;

@<Reject domain as vague@> =
	if ((suppress_problems) || (am->domain.problems_thrown++ > 0)) return;
	current_sentence = am->defined_at;
	StandardProblems::adjective_problem(Task::syntax_tree(),
		_p_(PM_AdjDomainVague),
		am->indexing_text, am->domain.domain_text,
		"this isn't allowed as the domain of a definition",
		"since it potentially describes many different kinds, not just one.");
	return;

@<Reject domain as topic@> =
	if ((suppress_problems) || (am->domain.problems_thrown++ > 0)) return;
	current_sentence = am->defined_at;
	StandardProblems::adjective_problem(Task::syntax_tree(),
		_p_(PM_AdjDomainTopic),
		am->indexing_text, am->domain.domain_text,
		"this isn't allowed as the domain of a definition",
		"because 'topic' doesn't behave the way other kinds of value do when "
		"it comes to making comparisons.");
	return;

@<Reject domain of adjective unless a kind of value or description of objects@> =
	if ((Node::is(supplied, CONSTANT_NT)) &&
		(Specifications::is_description_like(supplied) == FALSE) &&
		(Rvalues::to_instance(supplied) == NULL)) {
		if ((suppress_problems) || (am->domain.problems_thrown++ > 0)) return;
		current_sentence = am->defined_at;
		StandardProblems::adjective_problem(Task::syntax_tree(),
			_p_(PM_AdjDomainSurreal),
			am->indexing_text, am->domain.domain_text,
			"this isn't allowed as the domain of a definition",
			"since adjectives like this can be applied only to specific things, "
			"kinds of things or kinds of values: so 'Definition: a door is ajar "
			"if...' is fine, because a door is a kind of thing, and 'Definition: "
			"a number is prime if ...' is fine too, but 'Definition: 5 is prime "
			"if ...' is not allowed.");
		return;
	}

@<Reject domain of adjective if it is a set of objects which may vary in play@> =
	if (Descriptions::is_qualified(supplied)) {
		if (am->domain.problems_thrown++ > 0) return;
		current_sentence = am->defined_at;
		StandardProblems::adjective_problem(Task::syntax_tree(),
			_p_(PM_AdjDomainSlippery),
			am->indexing_text, am->domain.domain_text,
			"this is slippery",
			"because it can change during play. Definitions can only be "
			"made in cases where it's clear for any given value or object "
			"what definition will apply. For instance, 'Definition: a "
			"door is shiny if ...' is fine, but 'Definition: an open "
			"door is shiny if ...' is not allowed - Inform wouldn't know "
			"whether or not to apply it to the Big Blue Door (say), since "
			"it would only apply some of the time.");
		return;
	}

@ Finally, then, we can read what we currently believe the kind of the domain
is with the following. Note that:
(*) if the domain is undetermined, we return |NULL|;
(*) if the domain is a single instance, we return the kind of that instance.

=
kind *AdjectiveMeaningDomains::get_kind(adjective_meaning *am) {
	if (am == NULL) return NULL;
	if (am->domain.domain_infs == NULL) return NULL;
	return am->domain.domain_kind;
}

@ And similarly the subject:

=
inference_subject *AdjectiveMeaningDomains::get_subject(adjective_meaning *am) {
	if (am == NULL) return NULL;
	return am->domain.domain_infs;
}

@h Matching and sorting.
"Matching" is used to tell when a meaning can be applied to a term of a
given kind, or inference subject. It comes in two flavours: weak and strong.

(*) Weak checking only says that the kind is close enough for run-time
checking to be able to do the rest. Any two base kinds are different even in
weak checking -- "scene" and "number", for instance. On the other hand,
"list of scenes" weakly matches "list of numbers", and because domain kinds
inside "object" are treated as just "object", "container" weakly matches "animal".
(*) Strong checking imposes the further requirement that if the term is a
specific instance, then it must definitely lie within the domain.

=
int AdjectiveMeaningDomains::weak_match(kind *K1, adjective_meaning *am) {
	kind *K2 = AdjectiveMeaningDomains::get_kind(am);
	if (RTKinds::weak_id(K1) == RTKinds::weak_id(K2)) return TRUE;
	return FALSE;
}

int AdjectiveMeaningDomains::strong_match(kind *K1, inference_subject *infs,
	adjective_meaning *am) {
	if (AdjectiveMeaningDomains::weak_match(K1, am)) {
		instance *I = InstanceSubjects::to_object_instance(infs);
		if (I == NULL) return TRUE;
		while (infs) {
			if (am->domain.domain_infs == infs) return TRUE;
			infs = InferenceSubjects::narrowest_broader_subject(infs);
		}
	}
	return FALSE;
}

@ The following sorting function is used in the process of sorting the meanings
of an adjective into precedence order -- see //AdjectiveAmbiguity::sort//.
It takes two domains $D_1$ and $D_2$, and returns
(*) 1 if $D_1$ is inside $D_2$,
(*) -1 if $D_2$ is inside $D_1$,
(*) 0 otherwise, i.e., if they are the same or have no overlap.[1]

[1] More interesting Venn diagrams are not possible because of the way
domains are set up.

=
int AdjectiveMeaningDomains::cmp(adjective_domain_data *domain1, 
	adjective_domain_data *domain2) {
	if ((domain1->domain_infs) && (domain2->domain_infs == NULL)) return 1;
	if ((domain1->domain_infs == NULL) && (domain2->domain_infs)) return -1;

	if (InferenceSubjects::is_strictly_within(
		domain1->domain_infs, domain2->domain_infs)) return 1;
	if (InferenceSubjects::is_strictly_within(
		domain2->domain_infs, domain1->domain_infs)) return -1;

	kind *K1 = KindSubjects::to_nonobject_kind(domain1->domain_infs);
	kind *K2 = KindSubjects::to_nonobject_kind(domain2->domain_infs);
	if ((K1) && (K2)) {
		int c1 = Kinds::compatible(K1, K2);
		int c2 = Kinds::compatible(K2, K1);
		if ((c1 == ALWAYS_MATCH) && (c2 != ALWAYS_MATCH)) return 1;
		if ((c1 != ALWAYS_MATCH) && (c2 == ALWAYS_MATCH)) return -1;
	}
	return 0;
}
