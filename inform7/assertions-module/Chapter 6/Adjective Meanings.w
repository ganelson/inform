[AdjectiveMeanings::] Adjective Meanings.

One individual meaning which an adjective can have.

@ An adjective can have a long list of meanings in different contexts:

=
typedef struct adjective_meaning_data {
	struct adjective_meaning *possible_meanings; /* list of definitions in order given */
	struct adjective_meaning *sorted_meanings; /* the same list sorted into logical order */
} adjective_meaning_data;


@ Adjectives are simpler than verbs, since they define unary rather than
binary predicates. The word "open" applies to only one term -- logically, we
regard it as |open(x)|, whereas a verb like "suspects" would appear
in formulae as |suspects(x, y)|.

But they are nevertheless complicated enough to have multiple meanings. For
instance, two of the senses of "empty" in the Standard Rules are:

>> Definition: a text is empty rather than non-empty if it is "".

>> Definition: a table name is empty rather than non-empty if the number of filled rows in it is 0.

(Which also defines two of the senses of "non-empty", another adjective.)
The clause |empty(x)| can be fully understood only when we know what
kind of value x has; for a text, the first sense applies, and for a table
name, the second.


@ Each individual sense of an adjective has its own |adjective_meaning|
structure, which we define next. It consists of some logistical data to keep
its place in the linked lists (see above), some data to specify its domain
(see below), some indexing data which is not very important, and then the
crucial part: its "detailed meaning".

The general model is that adjective meanings come in different "kinds",
for which specific code is scattered across Inform. In each case, the
|detailed_meaning| points to an appropriate data structure, and specialised
routines are called to create and use the adjective.

We can also specify that the meaning implied by this pointer is to be
understood reversely: that the adjective is the negation of the one specified.
This enables "non-empty" for texts (say) to be defined identically with
"empty" for texts, but with the |meaning_parity| flag set to |FALSE|
rather than |TRUE|.

=
typedef struct adjective_meaning_family {
	struct method_set *methods;
	int parsing_priority;
	CLASS_DEFINITION
} adjective_meaning_family;

adjective_meaning_family *AdjectiveMeanings::new_family(int N) {
	adjective_meaning_family *f = CREATE(adjective_meaning_family);
	f->parsing_priority = N;
	f->methods = Methods::new_set();
	return f;
}

@

=
typedef struct adjective_meaning {
	struct adjective_meaning_family *family;

	struct wording adjective_index_text; /* text to use in the Phrasebook index */
	struct parse_node *defined_at; /* from what sentence this came (if it did) */

	struct adjective *owning_adjective; /* of which this is a definition */
	struct adjective_meaning *next_meaning; /* next in order of definition */
	struct adjective_meaning *next_sorted; /* next in logically sorted order */

	struct wording domain_text; /* domain to which defn applies */
	struct inference_subject *domain_infs; /* what domain the defn applies to */
	int setting_domain; /* are we currently working this out? */
	struct kind *domain_kind; /* what kind of values */
	int problems_thrown; /* complaining about the domain of this adjective */

	int meaning_parity; /* meaning understood positively? */
	struct adjective_meaning *am_negated_from; /* if explicitly constructed as such */

	general_pointer detailed_meaning; /* to the relevant structure */
	int task_via_support_routine[NO_ADJECTIVE_TASKS + 1];
	struct i6_schema i6s_to_transfer_to_SR[NO_ADJECTIVE_TASKS + 1]; /* where |TRUE| */
	struct i6_schema i6s_for_runtime_task[NO_ADJECTIVE_TASKS + 1]; /* where |TRUE| */
	int am_ready_flag; /* optional flag to mark whether schemas prepared yet */

	int defined_already; /* temporary workspace used when compiling support routines */

	CLASS_DEFINITION
} adjective_meaning;

@ What are adjectives for? Since an adjective is a unary predicate, it can be
thought of as an assignment from its domain set to the set of two possibilities:
true, false. Thus one sense of "open" maps doors to true if they are currently
open, false if they are closed.

There are altogether five things we might want to do with an adjective:

(1) Test whether it is true at any given point during play.
(2) Assert that it is true at the start of play.
(3) Assert that it is false at the start of play.
(4) Assert that it is now to be true from this point on during play.
(5) Assert that it is now to be false from this point on during play.

We do not need to test whether it is false, since we need only test whether
it is true and negate the result.

Adjectives for which all five of these operations can be carried out are
the exception rather than the rule. "Open" is an example:

>> [1] if the marble door is open, ...
>> [2] The marble door is open.
>> [3] The marble door is not open.
>> [4] now the marble door is open;
>> [5] now the marble door is not open;

Every adjective in practice supports (1), testing for truth, but this is
not required by the code below. Many adjectives -- properly speaking, many
senses of an adjective -- only support testing: "empty" in the sense of
texts, for instance.

Of the five possibilities, (1), (4) and (5) happen at run-time. These are
called "tasks" and are identified by the following constants. While in
theory an adjective's handling code can compile anything it likes to carry
out these tasks, in practice most are defined by providing an I6 schema,
which is why the |adjective_meaning| structure contains these -- see below.

@d NO_ADJECTIVE_TASKS 3

@d TEST_ADJECTIVE_TASK 1 /* test if currently true */
@d NOW_ADJECTIVE_TRUE_TASK 2 /* assert now true */
@d NOW_ADJECTIVE_FALSE_TASK 3 /* assert now false */

@ For indexing (only) we need to run through the definitions of a given
adjectival phrase in sorted order, so:

@d LOOP_OVER_SORTED_MEANINGS(aph, am)
	for (am = AdjectiveMeanings::get_sorted_definition_list(aph); am; am=am->next_sorted)

@h Symbols.

=
typedef struct adjective_compilation_data {
	struct inter_name *aph_iname;
	struct package_request *aph_package;
} adjective_compilation_data;

@

@d ADJECTIVE_COMPILATION_LINGUISTICS_CALLBACK AdjectiveMeanings::initialise

=
void AdjectiveMeanings::initialise(adjective *adj) {
	adj->adjective_compilation.aph_package = Hierarchy::package(CompilationUnits::current(), ADJECTIVES_HAP);
	adj->adjective_compilation.aph_iname = Hierarchy::make_iname_in(ADJECTIVE_HL, adj->adjective_compilation.aph_package);
}

typedef struct adjective_iname_holder {
	struct adjective *aph_held;
	int task_code;
	int weak_ID_of_domain;
	struct inter_name *iname_held;
	CLASS_DEFINITION
} adjective_iname_holder;

inter_name *AdjectiveMeanings::iname(adjective *aph, int task, int weak_id) {
	adjective_iname_holder *aih;
	LOOP_OVER(aih, adjective_iname_holder)
		if ((aih->aph_held == aph) && (aih->task_code == task) && (aih->weak_ID_of_domain == weak_id))
			return aih->iname_held;
	aih = CREATE(adjective_iname_holder);
	aih->aph_held = aph;
	aih->task_code = task;
	aih->weak_ID_of_domain = weak_id;
	package_request *PR = Hierarchy::package_within(ADJECTIVE_TASKS_HAP, aph->adjective_compilation.aph_package);
	aih->iname_held = Hierarchy::make_iname_in(TASK_FN_HL, PR);
	return aih->iname_held;
}

@h The block of definitions.

@d ADJECTIVE_MEANING_LINGUISTICS_CALLBACK AdjectiveMeanings::new_block

=
void AdjectiveMeanings::new_block(adjective *adj) {
	adj->adjective_meanings.possible_meanings = NULL;
	adj->adjective_meanings.sorted_meanings = NULL;
}

@ The following assigns a new meaning to a given word range: we find the
appropriate APH (creating if necessary) and then add the new meaning to the
end of its unsorted meaning list.

We eventually need to sort this list of definitions into logical priority
order -- so that a definition applying to just Count Dracula precedes one
applying to men, which in turn precedes one applying to things. (Priority
order is irrelevant when two senses apply to domains with no overlap, as
in the case of texts and table names.) It's convenient and costs little
memory to keep the sorted list as a second linked list.

=
adjective *AdjectiveMeanings::declare(adjective_meaning *am,
	wording W, int route) {
	adjective *aph = Adjectives::declare(W, NULL);
	adjective_meaning *aml = aph->adjective_meanings.possible_meanings;
	if (aml == NULL) aph->adjective_meanings.possible_meanings = am;
	else {
		while (aml->next_meaning) aml = aml->next_meaning;
		aml->next_meaning = am;
	}
	am->next_meaning = NULL;
	am->owning_adjective = aph;
	return aph;
}

@ Once declared, an AM stays with the same APH for the whole of Inform's run,
and it can only be declared once. So every AM belongs to one and only one
APH, which we can read off as follows:

=
adjective *AdjectiveMeanings::get_aph_from_am(adjective_meaning *am) {
	return am->owning_adjective;
}

@ And here we log the unsorted meaning list.

=
void AdjectiveMeanings::log_meanings(adjective *aph) {
	adjective_meaning *am;
	int n;
	if (aph == NULL) { LOG("<null-APH>\n"); return; }
	for (n=1, am = aph->adjective_meanings.possible_meanings; am; n++, am = am->next_meaning)
		LOG("%d: %W (domain:$j) (dk:%u)\n", n, am->adjective_index_text,
			am->domain_infs, am->domain_kind);
}

@h Checking an adjective's applicability.
If the source tries to apply the word "open", say, to a given value or
object $X$, when does that make sense?

We can only find out by checking every possible meaning of "open" to see
if it can accommodate the kind of value of $X$. But this time we use weak
checking, and make it weaker still since a null kind is taken to mean "any
object", either in the AM's definition -- which can happen if we are very
early in Inform's run -- or because the caller doesn't actually know the
kind of value of $X$. (In other words, adjectives tend to assume they apply
to objects rather than other values.) This means we will accept some
logically impossible outcomes -- we would say that it's acceptable to apply
"open" to an animal, say -- but that is actually a good thing. It means
that "list of open things" or "something open" are allowed. Source text
such as:

>> The labrador puppy is an open animal.

will successfully parse, but then result in higher-level problem messages.
The following does compile:

>> now the labrador puppy is open;

but results in a run-time problem message when it executes.

It makes no difference what order we check the AMs in, so we can use the
unsorted list, which is helpful since we may need to call this routine
early in the run when sorting cannot yet be done.

=
int AdjectiveMeanings::applicable_to(adjective *aph, kind *K) {
	if (aph) {
		adjective_meaning *am;
		for (am = aph->adjective_meanings.possible_meanings; am; am = am->next_meaning) {
			if (am->domain_infs == NULL) {
				if (am->setting_domain) @<Issue a problem for a circularity@>;
				am->setting_domain = TRUE;
				AdjectiveMeanings::set_definition_domain(am, TRUE);
				am->setting_domain = FALSE;
			}
			kind *am_kind = AdjectiveMeanings::get_domain(am);
			if (Kinds::Behaviour::is_object(am_kind)) {
				if (K == NULL) return TRUE;
				if (Kinds::Behaviour::is_object(K)) return TRUE;
			} else {
				if ((K) && (Kinds::Behaviour::is_object(K) == FALSE) &&
					(Kinds::compatible(K, am_kind) == ALWAYS_MATCH))
					return TRUE;
			}
		}
	}
	return FALSE;
}

@<Issue a problem for a circularity@> =
	if (problem_count == 0) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Clusters::get_form(aph->adjective_names, FALSE));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AdjectiveCircular));
		Problems::issue_problem_segment(
			"In the sentence %1, it looks as if the definition of the adjective "
			"'%2' may be circular.");
		Problems::issue_problem_end();
	}
	return FALSE;

@h Broad applicability tests.
Does a given APH have any interpretation as an enumerated property value,
or an either/or property? If so we return the earliest known.

=
instance *AdjectiveMeanings::has_ENUMERATIVE_meaning(adjective *aph) {
	adjective_meaning *am;
	for (am = aph->adjective_meanings.possible_meanings; am; am = am->next_meaning)
		if (InstanceAdjectives::is_enumerative(am))
			return RETRIEVE_POINTER_instance(am->detailed_meaning);
	return NULL;
}

property *AdjectiveMeanings::has_EORP_meaning(adjective *aph, int *sense) {
	if (aph)
		for (adjective_meaning *am = aph->adjective_meanings.possible_meanings; am; am = am->next_meaning)
			if (Properties::EitherOr::is_either_or_adjective(am)) {
				if (sense) *sense = am->meaning_parity;
				return RETRIEVE_POINTER_property(am->detailed_meaning);
			}
	return NULL;
}

@h Asserting the initial state.
All that domain-checking machinery means we can begin to use an adjective.

Suppose an assertion sentence in the source text claims that, in the initial
state of things, what the adjective tests is true. For example:

>> The ormolu clock is fixed in place.

The S-parser, finding that this sentence is syntactically reasonable,
identifies "fixed in place" as an adjective, and stores a pointer to its
APH structure, but goes no further. Later on, the A-parser, working through
sentences like this, works out that the adjective is to be applied to
the instance "ormolu clock", whose kind is "thing"; and that the
sentence asserts a truth, not a falsity. It then calls the following
routine, with |parity| equal to |TRUE|.

What happens is that the list of definitions for "fixed in place" is
strictly checked in logical precedence order, and that |AdjectiveMeanings::assert| is
eventually called on the logically narrowest definition which the "ormolu
clock" matches. (That will probably be the definition for the "fixed
in place" either/or property for things, unless someone has given the
adjective some special meaning unique to the clock.)

The following routine therefore acts as a junction-box, deciding which
sense of the adjective is to be applied. We return |TRUE| if we were
able to find a definition which could be asserted and which the clock
matched, and |FALSE| if there was no definition which applied, or if
none of those which did could be asserted for it.

=
int AdjectiveMeanings::assert(adjective *aph, kind *kind_domain,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	adjective_meaning *am;
	AdjectiveMeanings::sort(aph);
	for (am = aph->adjective_meanings.sorted_meanings; am; am = am->next_sorted) {
		if (AdjectiveMeanings::domain_weak_match(kind_domain,
			AdjectiveMeanings::get_domain(am)) == FALSE) continue;
		if (AdjectiveMeanings::domain_subj_compare(infs_to_assert_on, am) == FALSE) continue;
		if (AdjectiveMeanings::assert_single(am, infs_to_assert_on, val_to_assert_on, parity)) return TRUE;
	}
	return FALSE;
}

@h Sorting lists of meanings.
After meanings have been declared, a typical APH will have a disordered
"possible meaning" list and an empty "sorted meaning" list. The following
sorts the possibles list into the sorted list.

=
void AdjectiveMeanings::sort(adjective *aph) {
	if (aph == NULL) internal_error("tried to sort meanings for null APH");
	aph->adjective_meanings.sorted_meanings =
		AdjectiveMeanings::list_sort(aph->adjective_meanings.possible_meanings);
}

@ And voil\`a, the result can be read here:

=
adjective_meaning *AdjectiveMeanings::get_sorted_definition_list(adjective *aph) {
	return aph->adjective_meanings.sorted_meanings;
}

@ Occasionally we just want one meaning:

=
adjective_meaning *AdjectiveMeanings::first_meaning(adjective *aph) {
	return aph->adjective_meanings.possible_meanings;
}

adjective_meaning *AdjectiveMeanings::list_sort(adjective_meaning *unsorted_head) {
	adjective_meaning *sorted_head = NULL;
	adjective_meaning *am, *am2;
	for (am = unsorted_head; am; am = am->next_meaning)
		if (am->domain_infs == NULL)
			AdjectiveMeanings::set_definition_domain(am, TRUE);
	for (am = unsorted_head; am; am = am->next_meaning) {
		if (sorted_head == NULL) {
			sorted_head = am;
			am->next_sorted = NULL;
		} else {
			adjective_meaning *lastdef = NULL;
			for (am2 = sorted_head; am2; am2 = am2->next_sorted) {
				if (AdjectiveMeanings::compare(am, am2) == 1) {
					if (lastdef == NULL) {
						sorted_head = am;
						am->next_sorted = am2;
					} else {
						lastdef->next_sorted = am;
						am->next_sorted = am2;
					}
					break;
				}
				if (am2->next_sorted == NULL) {
					am2->next_sorted = am;
					am->next_sorted = NULL;
					break;
				}
				lastdef = am2;
			}
		}
	}
	return sorted_head;
}

@h Individual meanings.
So you want to define a new meaning for an adjective? Here's the procedure:

(1) Call |AdjectiveMeanings::new| to create it. The |form| should
be one of the |*_KADJ| constants, and the |details| should contain a pointer to
the data structure it uses. The word range is used for indexing only.
(2) Call |AdjectiveMeanings::declare| to associate it with a given
adjective name, and thus have it added to the possible meanings list of the
appropriate APH.
(3) Give it a domain of definition (see below).
(4) Optionally, give it explicit I6 schemas for testing and asserting (see
below) -- this makes coding what the adjective compiles to much easier.

=
adjective_meaning *AdjectiveMeanings::new(adjective_meaning_family *family,
	general_pointer details, wording W) {
	adjective_meaning *am = CREATE(adjective_meaning);
	am->defined_at = current_sentence;
	am->adjective_index_text = W;
	am->owning_adjective = NULL;
	am->next_meaning = NULL;
	am->next_sorted = NULL;
	am->domain_text = EMPTY_WORDING;
	am->domain_infs = NULL; am->domain_kind = NULL; am->setting_domain = FALSE;
	am->family = family;
	am->detailed_meaning = details;
	am->defined_already = FALSE;
	am->problems_thrown = 0;
	am->meaning_parity = TRUE;
	am->am_ready_flag = FALSE;
	for (int i=1; i<=NO_ADJECTIVE_TASKS; i++) {
		am->task_via_support_routine[i] = NOT_APPLICABLE;
		Calculus::Schemas::modify(&(am->i6s_for_runtime_task[i]), "");
		Calculus::Schemas::modify(&(am->i6s_to_transfer_to_SR[i]), "");
	}
	am->am_negated_from = NULL;
	return am;
}

@ Negating an AM.
If you want to define an adjective as the logical negation of an existing one,
take any AM which has been through stages (1) to (4) and then apply
|AdjectiveMeanings::negate| to create a new AM. Then use
|AdjectiveMeanings::declare| to associate this with a (presumably
different) name, but there's no need to specify its I6 schemas or its domain --
those are inherited.

=
adjective_meaning *AdjectiveMeanings::negate(adjective_meaning *am) {
	adjective_meaning *neg = CREATE(adjective_meaning);
	neg->defined_at = current_sentence;
	neg->adjective_index_text = am->adjective_index_text;
	neg->owning_adjective = NULL;
	neg->next_meaning = NULL;
	neg->next_sorted = NULL;
	neg->domain_text = am->domain_text;
	neg->domain_infs = am->domain_infs; neg->domain_kind = am->domain_kind;
	neg->family = am->family;
	neg->detailed_meaning = am->detailed_meaning;
	neg->defined_already = FALSE;
	neg->problems_thrown = 0;
	neg->am_ready_flag = FALSE;
	neg->meaning_parity = (am->meaning_parity)?FALSE:TRUE;
	for (int i=1; i<=NO_ADJECTIVE_TASKS; i++) {
		int j = i;
		if (i == NOW_ADJECTIVE_TRUE_TASK) j = NOW_ADJECTIVE_FALSE_TASK;
		if (i == NOW_ADJECTIVE_FALSE_TASK) j = NOW_ADJECTIVE_TRUE_TASK;
		neg->task_via_support_routine[j] = am->task_via_support_routine[i];
		neg->i6s_for_runtime_task[j] = am->i6s_for_runtime_task[i];
		Calculus::Schemas::modify(&(neg->i6s_to_transfer_to_SR[j]), "");
	}
	neg->am_negated_from = am;
	return neg;
}

adjective_meaning_family *AdjectiveMeanings::get_form(adjective_meaning *am) {
	if (am == NULL) return NULL;
	return am->family;
}

@h The domain of validity.
Every AM has a clearly defined range of values or objects to which it applies.
For example, "odd" for numbers has |domain_infs| equal to "number",
while the sense of "odd" created by

>> Mrs Elspeth Spong can be odd, eccentric or mildly dotty.

would have |domain_infs| equal to Mrs Spong herself.

@ In comparing and testing domains, we use two different levels of matching:
weak and strong.

Strong checking makes an exact match, but weak checking blurs the definitions
so that two domains are counted as equal if they are close enough that run-time
type checking can be used to tell them apart.

In general, any two base kinds are different even in weak checking -- "scene"
and "number", for instance. On the other hand, "list of scenes" weakly
matches "list of numbers", and "container" weakly matches "animal".
As this last example shows, two domains can be completely disjoint and still
make a weak match.

=
int AdjectiveMeanings::domain_weak_match(kind *K1, kind *K2) {
	if (RTKinds::weak_id(K1) == RTKinds::weak_id(K2))
		return TRUE;
	return FALSE;
}

@ Whereas the following makes a strict check of whether a given subject is
within the domain of an adjective meaning.

=
int AdjectiveMeanings::domain_subj_compare(inference_subject *infs, adjective_meaning *am) {
	instance *I = InstanceSubjects::to_object_instance(infs);
	if (I == NULL) return TRUE;
	if (am->domain_infs == KindSubjects::from_kind(K_object)) return TRUE;
	while (infs) {
		if (am->domain_infs == infs) return TRUE;
		infs = InferenceSubjects::narrowest_broader_subject(infs);
	}
	return FALSE;
}

@h Specifying the domain of a new AM.
In principle the domain should be set as soon as the AM is created, but in
practice some AMs -- those coming from properties -- might need to be
created very early in Inform's run, at a time when objects and kinds of
object do not exist. For those cases, an alternative is to give a word range --
"a number", say, or "a container" -- and if necessary this is left
until later on in the run to parse. (For "a number", it wouldn't be
necessary; for "a container", it would.)

The inclusion of |domain_kind| may seem redundant here; surely the INFS is
sufficient? But it isn't, because "list of numbers" -- say -- has the
same INFS as "list of texts" or a list of anything else, so that if we
recorded the domain only as an INFS then we couldn't define adjectives
over specific constructed kinds.

To set the domain, call exactly one of the following three routines:

=
void AdjectiveMeanings::set_domain_text(adjective_meaning *am, wording W) {
	am->domain_infs = NULL; am->domain_kind = NULL;
	am->domain_text = W;
	AdjectiveMeanings::set_definition_domain(am, TRUE);
}

void AdjectiveMeanings::set_domain_from_instance(adjective_meaning *am,
	instance *I) {
	if (I == NULL) {
		am->domain_infs = KindSubjects::from_kind(K_object);
		am->domain_kind = K_object;
	} else {
		am->domain_infs = Instances::as_subject(I);
		am->domain_kind = Kinds::weaken(Instances::to_kind(I), K_object);
	}
	am->domain_text = EMPTY_WORDING;
}

@ Note that we round up the kind to "object" if it's more specialised than that
-- say, if it's "door" -- because run-time rather than compile-time
disambiguation is used when applying adjectives to objects.

=
void AdjectiveMeanings::set_domain_from_kind(adjective_meaning *am, kind *K) {
	if ((K == NULL) || (Kinds::Behaviour::is_object(K))) K = K_object;
	am->domain_infs = KindSubjects::from_kind(K);
	am->domain_kind = K;
	am->domain_text = EMPTY_WORDING;
}

@ And we can read the main domain thus:

=
kind *AdjectiveMeanings::get_domain(adjective_meaning *am) {
	if (am->domain_infs == NULL) return NULL;
	return am->domain_kind;
}

kind *AdjectiveMeanings::get_domain_forcing(adjective_meaning *am) {
	AdjectiveMeanings::set_definition_domain(am, TRUE);
	if (am->domain_infs == NULL) return NULL;
	return am->domain_kind;
}

@ In the case where the domain is declared as a word range, the following
routine eventually converts it to the correct form. In effect, this is a
lazy evaluation trick -- the routine is called just before the domain is
actually needed.

=
void AdjectiveMeanings::set_definition_domain(adjective_meaning *am, int early) {
	if (am->domain_infs) return;
	current_sentence = am->defined_at;
	if (Wordings::empty(am->domain_text)) internal_error("undeclared domain kind for AM");
	parse_node *supplied = NULL;
	if (<s-type-expression>(am->domain_text))
		supplied = <<rp>>;
	if (supplied == NULL) @<Reject domain of adjective@>;
	@<Reject domain of adjective unless a kind of value or description of objects@>;
	kind *K = NULL;
	if (Specifications::is_condition(supplied)) {
		if (Specifications::to_kind(supplied))
			K = Specifications::to_kind(supplied);
		else K = K_object;
		@<Reject domain of adjective if it is a set of objects which may vary in play@>;
	} else if (Rvalues::is_rvalue(supplied))
		K = Rvalues::to_kind(supplied);
	if (K == NULL) @<Reject domain of adjective@>;
	if (Kinds::Behaviour::is_kind_of_kind(K)) @<Reject domain as vague@>;
	if ((K_understanding) && (Kinds::eq(K, K_understanding))) @<Reject domain as topic@>;
	@<Set the domain INFS as needed@>;
}

@ Note that we throw only one problem message per AM, as otherwise duplication
can't be avoided.

@<Reject domain of adjective@> =
	if ((early) || (am->problems_thrown++ > 0)) return;
	current_sentence = am->defined_at;
	StandardProblems::adjective_problem(Task::syntax_tree(), _p_(PM_AdjDomainUnknown),
		am->adjective_index_text, am->domain_text,
		"this isn't a thing, a kind of thing or a kind of value",
		"and indeed doesn't have any meaning I can make sense of.");
	return;

@<Reject domain as vague@> =
	if ((early) || (am->problems_thrown++ > 0)) return;
	current_sentence = am->defined_at;
	StandardProblems::adjective_problem(Task::syntax_tree(), _p_(PM_AdjDomainVague),
		am->adjective_index_text, am->domain_text,
		"this isn't allowed as the domain of a definition",
		"since it potentially describes many different kinds, not just one.");
	return;

@<Reject domain as topic@> =
	if ((early) || (am->problems_thrown++ > 0)) return;
	current_sentence = am->defined_at;
	StandardProblems::adjective_problem(Task::syntax_tree(), _p_(PM_AdjDomainTopic),
		am->adjective_index_text, am->domain_text,
		"this isn't allowed as the domain of a definition",
		"because 'topic' doesn't behave the way other kinds of value do when "
		"it comes to making comparisons.");
	return;

@ Similarly:

@<Reject domain of adjective unless a kind of value or description of objects@> =
	if ((Node::is(supplied, CONSTANT_NT)) &&
		(Specifications::is_description_like(supplied) == FALSE) &&
		(Rvalues::to_instance(supplied) == NULL)) {
		if ((early) || (am->problems_thrown++ > 0)) return;
		current_sentence = am->defined_at;
		StandardProblems::adjective_problem(Task::syntax_tree(), _p_(PM_AdjDomainSurreal),
			am->adjective_index_text, am->domain_text,
			"this isn't allowed as the domain of a definition",
			"since adjectives like this can be applied only to specific things, "
			"kinds of things or kinds of values: so 'Definition: a door is ajar "
			"if...' is fine, because a door is a kind of thing, and 'Definition: "
			"a number is prime if ...' is fine too, but 'Definition: 5 is prime "
			"if ...' is not allowed.");
		return;
	}

@ And a final possible objection:

@<Reject domain of adjective if it is a set of objects which may vary in play@> =
	if (Descriptions::is_qualified(supplied)) {
		if (am->problems_thrown++ > 0) return;
		current_sentence = am->defined_at;
		StandardProblems::adjective_problem(Task::syntax_tree(), _p_(PM_AdjDomainSlippery),
			am->adjective_index_text, am->domain_text,
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

@<Set the domain INFS as needed@> =
	instance *I = Rvalues::to_object_instance(supplied);
	if (I) supplied = Rvalues::from_instance(I);
	else if (Kinds::Behaviour::is_subkind_of_object(K))
		supplied = Specifications::from_kind(K);
	am->domain_infs = InferenceSubjects::from_specification(supplied);
	am->domain_kind = K;

@h Comparing domains of validity.
In order to sort AMs into logical precedence order, we rely on the
following routine, which like |strcmp| returns a positive number to favour
the first term, a negative to favour the second, and zero if they are
equally good. Note that zero is only in fact returned when the two AMs
compared are one and the same -- we want to ensure that there is one
and only one possible sorted state for any given list of AMs.

Suppose the adjectives $A_1$ and $A_2$ have domain sets $D_1$ and $D_2$. Then:

(i) If $D_1\subseteq D_2$ and $D_1\neq D_2$, then $A_1$ precedes $A_2$.
(ii) If $D_2\subseteq D_1$ and $D_2\neq D_1$, then $A_2$ precedes $A_1$.
(iii) If $D_1 = D_2$ or if $D_1\cap D_2 = \emptyset$ then we have to be
pragmatic: see below.

Those are the only possibilities; the range of possible domains is set up
so that there can never be an interesting Venn diagram of overlaps
between them.

Unlike our weak domain tests above, this is a strict test.

=
int AdjectiveMeanings::compare(adjective_meaning *am1, adjective_meaning *am2) {
	if (am1 == am2) return 0;
	if ((am1->domain_infs) && (am2->domain_infs == NULL)) return 1;
	if ((am1->domain_infs == NULL) && (am2->domain_infs)) return -1;

	if (InferenceSubjects::is_strictly_within(am1->domain_infs, am2->domain_infs)) return 1;
	if (InferenceSubjects::is_strictly_within(am2->domain_infs, am1->domain_infs)) return -1;

	kind *K1 = KindSubjects::to_nonobject_kind(am1->domain_infs);
	kind *K2 = KindSubjects::to_nonobject_kind(am2->domain_infs);
	if ((K1) && (K2)) {
		int c1 = Kinds::compatible(K1, K2);
		int c2 = Kinds::compatible(K2, K1);
		if ((c1 == ALWAYS_MATCH) && (c2 != ALWAYS_MATCH)) return 1;
		if ((c1 != ALWAYS_MATCH) && (c2 == ALWAYS_MATCH)) return -1;
	}
	if (am1->domain_infs == am2->domain_infs)
		@<Worry about definitions of the same adjective on the same domain@>;

	return am2->allocation_id - am1->allocation_id;
}

@ In general, it's an error to define the same adjective on the same domain
twice, except for a redefinition in the source text of a definition in an
extension. (We exclude enumerative adjectives because they are defined
internally by a method which involves occasional duplication but where
the duplicates are all mutually consistent; these do not arise from the
author's source text.)

@<Worry about definitions of the same adjective on the same domain@> =
	if ((Wordings::nonempty(Node::get_text(am1->defined_at))) &&
		(Wordings::nonempty(Node::get_text(am2->defined_at))) &&
		(InstanceAdjectives::is_enumerative(am1) == FALSE) &&
		(InstanceAdjectives::is_enumerative(am2) == FALSE)) {
		inform_extension *ef1 =
			Extensions::corresponding_to(
				Lexer::file_of_origin(Wordings::first_wn(Node::get_text(am1->defined_at))));
		inform_extension *ef2 =
			Extensions::corresponding_to(
				Lexer::file_of_origin(Wordings::first_wn(Node::get_text(am2->defined_at))));
		if ((ef1 == ef2) || ((ef1) && (ef2))) {
			current_sentence = am1->defined_at;
			Problems::quote_wording_as_source(1, am1->adjective_index_text);
			Problems::quote_wording_as_source(2, am2->adjective_index_text);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AdjDomainDuplicated));
			Problems::issue_problem_segment(
				"The definitions %1 and %2 both try to cover the same situation: "
				"the same adjective applied to the exact same range. %P"
				"It's okay to override a definition in an extension with another "
				"one in the main source text, but it's not okay to define the same "
				"adjective twice over the same domain in the same file.");
			Problems::issue_problem_end();
		}
		if (ef1 == NULL) return 1;
		if (ef2 == NULL) return -1;
	}

@h Testing and asserting in play.
Now for testing, making true and making false in play. We won't be there when
the story file is played, of course, so what we have to do is to compile code
to perform the test or force the state.

In fact what we do is to supply an I6 schema, which for this purpose is
simply the text of I6 code in which the escape |*1| represents the value
to which the adjective is applied. In the example of "open" for containers,
we might choose:
= (text)
	if the sack is open, ...  -->   (Adj_53_t1_v61(*1))
	now the sack is open; ...  -->   Adj_53_t2_v61(*1)
	now the sack is not open; ...  -->   Adj_53_t3_v61(*1)
=
These schemas call an I6 routine called a "support routine". The names
here are schematic: "open" on this run was APH number 53, the run-time
tasks to perform were task 1, task 2 and task 3, and the sense of the
adjective was the one applying to domain 61 -- which in this example run
was the weak ID of "object". In other words, these are routines to "test
open in the sense of objects", "now open in the sense of objects", and
"now not open in the sense of objects".

If we make a choice like that, then we say that the task is provided
"via a support routine". We need not do so: for instance,
= (text)
	if the Entire Game is happening, ...  -->  (scene_status->(*1 - 1)==1)
=
is an example where the sense of "happening" for scenes can be tested
directly using a schema, without calling a support routine. And clearly
support routines only put off the problem, because we will also have to
compile the routine itself. So why use them? The answer is that in
complicated situations where run-time type checking is needed, they
avoid duplication of code, and can make repeated use of the |*1| value
without repeating any side-effects produced by the calculation of this
value. They also make the code simpler for human eyes to read.

@ When an AM has been declared, the provider can choose to set an I6
schema for it, for any of the tasks, immediately; or can wait and do it
later; or can choose not to do it, and instead provide code which
generates a suitable schema on the fly. If at whatever stage the
provider does set an I6 schema for a task, it should call the following.

Note that any AM working on objects always has to go via a support
routine -- this is because, thanks to weak domain-checking, there may
be run-time type-checking code to apply. In other cases, the provider
can choose to go via a support routine or not.

=
i6_schema *AdjectiveMeanings::set_i6_schema(adjective_meaning *am,
	int T, int via_support) {
	kind *K = AdjectiveMeanings::get_domain(am);
	if (K == NULL) K = K_object;
	if (Kinds::Behaviour::is_object(K)) via_support = TRUE;
	am->task_via_support_routine[T] = via_support;
	return &(am->i6s_for_runtime_task[T]);
}

@ When Inform's code-generator needs to compile one of the tasks, then, it
calls the following to obtain the correct I6 schema.

Note that the |task_via_support_routine| values are not flags: they can be
|TRUE| (allowed, done via support routine), |FALSE| (allowed, done directly)
or |NOT_APPLICABLE| (the task certainly can't be done). If none of the
applicable meanings for the adjective are able to perform the task at
run-time, we return |NULL| as our schema, and the code-generator will use
that to issue a suitable problem message.

=
i6_schema *AdjectiveMeanings::get_i6_schema(adjective *aph,
	kind *kind_domain, int T) {
	adjective_meaning *am;
	if (kind_domain == NULL) kind_domain = K_object;
	AdjectiveMeanings::sort(aph);
	for (am = aph->adjective_meanings.sorted_meanings; am; am = am->next_sorted) {
		kind *am_kind = AdjectiveMeanings::get_domain(am);
		if (am_kind == NULL) AdjectiveMeanings::set_definition_domain(am, FALSE);
		if (AdjectiveMeanings::domain_weak_match(kind_domain, am_kind) == FALSE) continue;
		AdjectiveMeanings::compiling_soon(am, T);
		switch (am->task_via_support_routine[T]) {
			case FALSE: return &(am->i6s_for_runtime_task[T]);
			case TRUE:
				if (Calculus::Schemas::empty(&(am->i6s_to_transfer_to_SR[T])))
					@<Construct a schema for this adjective, using the standard routine naming@>;
				return &(am->i6s_to_transfer_to_SR[T]);
		}
	}
	return NULL;
}

@ Where the following is complicated by the need to respect negations; it may
be that the original adjective has a support routine defined, but that the
negation does not, and so must use those of the original.

@<Construct a schema for this adjective, using the standard routine naming@> =
	int task = T; char *negation_operator = "";
	adjective *use_aph = aph;
	if (am->am_negated_from) {
		use_aph = am->am_negated_from->owning_adjective;
		switch (T) {
			case TEST_ADJECTIVE_TASK: negation_operator = "~~"; break;
			case NOW_ADJECTIVE_TRUE_TASK: task = NOW_ADJECTIVE_FALSE_TASK; break;
			case NOW_ADJECTIVE_FALSE_TASK: task = NOW_ADJECTIVE_TRUE_TASK; break;
		}
	}
	inter_name *iname = AdjectiveMeanings::iname(use_aph, task, RTKinds::weak_id(am_kind));
	Calculus::Schemas::modify(&(am->i6s_to_transfer_to_SR[T]), "*=-(%s%n(*1))",
		negation_operator, iname);

@ The following is needed when making sense of the I6-to-I7 escape sequence
|(+ adj +)|, where |adj| is the name of an adjective. Since I6 is typeless,
there's no good way to choose which sense of the adjective is meant, so we
don't know which routine to expand out. The convention is: a meaning for
objects, if there is one; otherwise the first-declared meaning.

=
int AdjectiveMeanings::write_adjective_test_routine(value_holster *VH,
	adjective *aph) {
	i6_schema *sch;
	int weak_id = RTKinds::weak_id(K_object);
	sch = AdjectiveMeanings::get_i6_schema(aph, NULL,
		TEST_ADJECTIVE_TASK);
	if (sch == NULL) {
		if (aph->adjective_meanings.possible_meanings == NULL) return FALSE;
		kind *am_kind =
			AdjectiveMeanings::get_domain(aph->adjective_meanings.possible_meanings);
		if (am_kind == NULL) return FALSE;
		weak_id = RTKinds::weak_id(am_kind);
	}
	Produce::val_iname(Emit::tree(), K_value, AdjectiveMeanings::iname(aph, TEST_ADJECTIVE_TASK, weak_id));
	return TRUE;
}

@ The following instructs an AM to use a support routine to handle a given
task.

=
void AdjectiveMeanings::pass_task_to_support_routine(adjective_meaning *am,
	int T) {
	AdjectiveMeanings::set_i6_schema(am, T, TRUE);
}

@ Some kinds of adjective find it useful to do some preparation work just
before first compilation, but only once. For those, the ready flag is available:

=
int AdjectiveMeanings::get_ready_flag(adjective_meaning *am) {
	return am->am_ready_flag;
}
void AdjectiveMeanings::set_ready_flag(adjective_meaning *am) {
	am->am_ready_flag = TRUE;
}

@h Support routines.
Using these is only passing the buck: and the buck stops here.

The following utility is used to loop through the sorted meaning list,
skipping over any which have been dealt with already.

=
adjective_meaning *AdjectiveMeanings::list_next_domain_kind(adjective_meaning *am, kind **K, int T) {
	while ((am) && ((am->defined_already) || (AdjectiveMeanings::compilation_possible(am, T) == FALSE)))
		am = am->next_sorted;
	if (am == NULL) return NULL;
	*K = AdjectiveMeanings::get_domain(am);
	return am->next_sorted;
}

@ And this is where we do the iteration. The idea is that one adjective
definition routine is defined (for each task number) which covers all of
the weakly-domain-equal definitions for the same adjective. Thus one
routine might handle "detailed" for rulebooks, and another might handle
"detailed" for all of its meanings associated with objects -- possibly
many AMs.

=
void AdjectiveMeanings::compile_support_code(void) {
	@<Ensure, just in case, that domains exist and are sorted on@>;
	int T;
	for (T=1; T<=NO_ADJECTIVE_TASKS; T++) {
		adjective *aph;
		LOOP_OVER(aph, adjective) {
			adjective_meaning *am;
			for (am = aph->adjective_meanings.possible_meanings; am; am = am->next_meaning)
				am->defined_already = FALSE;
			for (am = aph->adjective_meanings.sorted_meanings; am; ) {
				kind *K = NULL;
				am = AdjectiveMeanings::list_next_domain_kind(am, &K, T);
				if (K)
					@<Compile adjective definition for this atomic kind of value@>;
			}
		}
	}
}

@ It's unlikely that we have got this far without the domains for the AMs
having been established, but certainly possible. We need the domains to be
known in order to sort.

@<Ensure, just in case, that domains exist and are sorted on@> =
	adjective *aph;
	LOOP_OVER(aph, adjective) {
		adjective_meaning *am;
		for (am = aph->adjective_meanings.possible_meanings; am; am = am->next_meaning) {
			AdjectiveMeanings::set_definition_domain(am, FALSE);
			am->defined_already = FALSE;
		}
		AdjectiveMeanings::sort(aph);
	}

@ The following is a standard way to compile a one-off routine.

@<Compile adjective definition for this atomic kind of value@> =
	wording W = Adjectives::get_nominative_singular(aph);
	LOGIF(VARIABLE_CREATIONS, "Compiling support code for %W applying to %u, task %d\n",
		W, K, T);

	inter_name *iname = AdjectiveMeanings::iname(aph, T, RTKinds::weak_id(K));
	packaging_state save = Routines::begin(iname);
	@<Add an it-variable to represent the value or object in the domain@>;

	TEMPORARY_TEXT(C)
	WRITE_TO(C, "meaning of \"");
	if (Wordings::nonempty(W)) WRITE_TO(C, "%~W", W);
	else WRITE_TO(C, "<nameless>");
	WRITE_TO(C, "\"");
	Emit::code_comment(C);
	DISCARD_TEXT(C)

	if (problem_count == 0) {
		local_variable *it_lv = LocalVariables::it_variable();
		inter_symbol *it_s = LocalVariables::declare_this(it_lv, FALSE, 8);
		AdjectiveMeanings::list_compile(aph->adjective_meanings.sorted_meanings, Frames::current_stack_frame(), K, T, it_s);
	}
	Produce::rfalse(Emit::tree());

	Routines::end(save);

@ The stack frame has just one call parameter: the value $x$ which might, or
might not, be such that adjective($x$) is true. We allow this to be called
"it", though it can also have a calling name in some cases (see below).

Clearly it ought to have the kind which defines the domain -- so it's a rulebook
if the domain is all rulebooks, and so on -- but it doesn't always do so. The
exception is that it is bogusly given the kind "number" if the adjective is
being defined only by I6 routines. This is done to avoid compiling very
inefficient code from the Standard Rules. For instance, the SR reads, in
slightly simplified form:

>> Definition: a text is empty if I6 routine |"TEXT\_TY\_Empty"| says so.

rather than the more obvious:

>> Definition: a text is empty if it is not |""|.

Both of these definitions work. But if the routine defining "empty" for text
is allowed to act on a text variable, Inform needs to compile code which acts
on block values held on the memory heap at run-time. That means it needs to
compile a memory heap; and that costs 8K or so of storage, making large
Z-machine games which don't need text alteration or lists impossible to fit into
the 64K array space limit. (There's also a benefit even if we do need a heap;
the adjective can act on a direct pointer to the structure, and no time is
wasted allocating memory and copying the block value first.)

@<Add an it-variable to represent the value or object in the domain@> =
	kind *add_K = K_number;
	adjective_meaning *am;
	for (am = aph->adjective_meanings.sorted_meanings; am; am = am->next_sorted)
		if ((Phrases::RawPhrasal::is_by_Inter_function(am) == FALSE) &&
			(AdjectiveMeanings::domain_weak_match(K, AdjectiveMeanings::get_domain(am))))
			add_K = K;

	LocalVariables::add_pronoun(Frames::current_stack_frame(), EMPTY_WORDING, add_K);
	LocalVariables::enable_possessive_form_of_it();

@ We run through possible meanings of the APH which share the current weak
domain, and compile code which performs the stronger part of the domain
test at run-time. In practice, at present the only weak domain which might
have multiple definitions is "object", but that may change.

=
void AdjectiveMeanings::list_compile(adjective_meaning *list_head,
	ph_stack_frame *phsf, kind *K, int T, inter_symbol *t0_s) {
	adjective_meaning *am;
	for (am = list_head; am; am = am->next_sorted)
		if ((AdjectiveMeanings::compilation_possible(am, T)) &&
			(AdjectiveMeanings::domain_weak_match(K, AdjectiveMeanings::get_domain(am)))) {
			current_sentence = am->defined_at;
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				InferenceSubjects::emit_element_of_condition(am->domain_infs, t0_s);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						if ((am->meaning_parity == FALSE) && (T == TEST_ADJECTIVE_TASK)) {
							Produce::inv_primitive(Emit::tree(), NOT_BIP);
							Produce::down(Emit::tree());
						}
						AdjectiveMeanings::emit_meaning(am, T, phsf);
						am->defined_already = TRUE;
						if ((am->meaning_parity == FALSE) && (T == TEST_ADJECTIVE_TASK)) {
							Produce::up(Emit::tree());
						}
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
}

@h Kinds of adjectives.
This is where |inweb|'s use of C rather than |C++| or Python as a base
language becomes a little embarrassing: we really want to have seven or
eight subclasses of an "adjective" class, and provide a group of methods.
Instead we simulate this with the following clumsy code. (More elegant
code using pointers to functions would trip up |inweb|'s structure-element
usage checking.)

To define a new kind of adjective, first allocate it a new |*_KADJ|
constant (see above). Then declare functions to handle the following
methods.

@ 1. |*_KADJ_parse|. This enables the kind of adjective to claim a definition
which the user has explicitly written, like so:

>> Definition: A ... (called ...) is ... if ...

In place of the ellipses are the adjective name, domain name, condition
text and (optionally) also the calling name. The routine should return a
pointer to the AM it creates, if it does want to claim the definition;
and |NULL| if it doesn't want it. |sense| is either $1$, meaning that
"if" was used (the condition has positive sense); or $-1$, meaning
that it was "unless" (a negative sense); or $0$, meaning that instead
of a condition, a rule was supplied. (Most kinds of adjective will only
claim if the sense is $1$; some never claim at all.)

@e PARSE_ADJM_MTID

=
INT_METHOD_TYPE(PARSE_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW)

adjective_meaning *AdjectiveMeanings::parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	for (int priority = 0; priority < 10; priority++) {
		adjective_meaning_family *f;
		LOOP_OVER(f, adjective_meaning_family)
			if (f->parsing_priority == priority)
				@<Try the f family@>;
	}
	return NULL;
}

@<Try the f family@> =
	adjective_meaning *am = NULL;
	int rv = FALSE;
	INT_METHOD_CALL(rv, f, PARSE_ADJM_MTID, &am, q, sense, AW, DNW, CONW, CALLW);
	if (rv) return am;

@ 2. |*_KADJ_compiling_soon|. This warns the adjective that it will shortly be
needed in compilation, that is, that code will soon be compiled which uses it.
This advance warning is an opportunity to compile a schema for the adjective
at the last minute, but there is no obligation. There is also no return value.

@e COMPILING_SOON_ADJM_MTID

=
VOID_METHOD_TYPE(COMPILING_SOON_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, int T)

void AdjectiveMeanings::compiling_soon(adjective_meaning *am, int T) {
	VOID_METHOD_CALL(am->family, COMPILING_SOON_ADJM_MTID, am, T);
}

@ 3. |*_KADJ_compile|. We should now either compile code which, in the
given stack frame and writing code to the given file handle, carries out the
given task for the adjective, and return |TRUE|; or return |FALSE| to
tell Inform that the task is impossible.

Note that if an adjective has defined a schema to handle the task, then its
|*_KADJ_compile| is not needed and not consulted.

@e COMPILE_ADJM_MTID

=
int AdjectiveMeanings::emit_meaning(adjective_meaning *am, int T, ph_stack_frame *phsf) {
	return AdjectiveMeanings::compile_inner(am, T, TRUE, phsf);
}

int AdjectiveMeanings::compilation_possible(adjective_meaning *am, int T) {
	return AdjectiveMeanings::compile_inner(am, T, FALSE, NULL);
}

INT_METHOD_TYPE(COMPILE_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, int T, int emit_flag, ph_stack_frame *phsf)

int AdjectiveMeanings::compile_inner(adjective_meaning *am, int T, int emit_flag, ph_stack_frame *phsf) {
	AdjectiveMeanings::compiling_soon(am, T);
	@<Use the I6 schema instead to compile the task, if one exists@>;
	int rv = FALSE;
	INT_METHOD_CALL(rv, am->family, COMPILE_ADJM_MTID, am, T, emit_flag, phsf);
	return rv;
}

@ We expand the I6 schema, placing the "it" variable -- a nameless call
parameter which is always local variable number 0 for this stack frame --
into |*1|.

@<Use the I6 schema instead to compile the task, if one exists@> =
	if (Calculus::Schemas::empty(&(am->i6s_for_runtime_task[T])) == FALSE) {
		if (emit_flag) {
			parse_node *it_var = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING,
				LocalVariables::it_variable());
			pcalc_term it_term = Terms::new_constant(it_var);
			EmitSchemas::emit_expand_from_terms(&(am->i6s_for_runtime_task[T]), &it_term, NULL, FALSE);
		}
		return TRUE;
	}

@ 4. |*_KADJ_assert|. We should now either take action to ensure that
the adjective will hold (or not hold, according to |parity|) for the given
object or value; or return |FALSE| to tell Inform that this cannot be
asserted, which will trigger a problem message.

@e ASSERT_ADJM_MTID

=
INT_METHOD_TYPE(ASSERT_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, inference_subject *infs_to_assert_on,
	parse_node *val_to_assert_on, int parity)

int AdjectiveMeanings::assert_single(adjective_meaning *am,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	if (am->meaning_parity == FALSE) {
		am = am->am_negated_from; parity = (parity)?FALSE:TRUE;
	}
	int rv = FALSE;
	INT_METHOD_CALL(rv, am->family, ASSERT_ADJM_MTID, am, infs_to_assert_on,
		val_to_assert_on, parity);
	return rv;
}

@ 5. |*_KADJ_index|. This should print a description of the adjective to the
index, for use in the Phrasebook lexicon. Note that it is only needed where
the AM has been constructed positively, that is, it is not needed if the
AM was made as a negation of something else.

Note also that if the AM was defined with any indexing text then that will
be printed if the routine does nothing better.

@e INDEX_ADJM_MTID

=
INT_METHOD_TYPE(INDEX_ADJM_MTID, adjective_meaning_family *f, text_stream *OUT,
	adjective_meaning *am)

void AdjectiveMeanings::print_to_index(OUTPUT_STREAM, adjective_meaning *am) {
	@<Index the domain of validity of the AM@>;
	if (am->am_negated_from) {
		wording W = Adjectives::get_nominative_singular(am->am_negated_from->owning_adjective);
		WRITE(" opposite of </i>%+W<i>", W);
	} else {
		int rv = FALSE;
		INT_METHOD_CALL(rv, am->family, INDEX_ADJM_MTID, OUT, am);
		if ((rv == FALSE) && (Wordings::nonempty(am->adjective_index_text)))
			WRITE("%+W", am->adjective_index_text);
	}
	if (Wordings::nonempty(am->adjective_index_text))
		Index::link(OUT, Wordings::first_wn(am->adjective_index_text));
}

@ This is supposed to imitate dictionaries, distinguishing meanings by
concisely showing their usage. Thus "empty" would have indexed entries
prefaced "(of a rulebook)", "(of an activity)", and so on.

@<Index the domain of validity of the AM@> =
	if (am->domain_infs)
		WRITE("(of </i>%+W<i>) ", InferenceSubjects::get_name_text(am->domain_infs));

@h Parsing for adaptive text.

=
<adaptive-adjective> internal {
	if (Projects::get_language_of_play(Task::project()) == DefaultLanguage::get(NULL)) return FALSE;
	adjective *aph;
	LOOP_OVER(aph, adjective) {
		wording AW = Clusters::get_form_general(aph->adjective_names, Projects::get_language_of_play(Task::project()), 1, -1);
		if (Wordings::match(AW, W)) {
			==> { FALSE, aph};
			return TRUE;
		}
	}
	==> { fail nonterminal };
}

@ Compiling to:

=
void AdjectiveMeanings::agreements(void) {
	if (Projects::get_language_of_play(Task::project()) == DefaultLanguage::get(NULL)) return;
	adjective *aph;
	LOOP_OVER(aph, adjective) {
		wording PW = Clusters::get_form_general(aph->adjective_names, Projects::get_language_of_play(Task::project()), 1, -1);
		if (Wordings::empty(PW)) continue;

		packaging_state save = Routines::begin(aph->adjective_compilation.aph_iname);
		inter_symbol *o_s = LocalVariables::add_named_call_as_symbol(I"o");
		inter_symbol *force_plural_s = LocalVariables::add_named_call_as_symbol(I"force_plural");
		inter_symbol *gna_s = LocalVariables::add_internal_local_as_symbol(I"gna");

		Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, o_s);
				Produce::val_nothing(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gna_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 6);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gna_s);
					inter_name *iname = Hierarchy::find(GETGNAOFOBJECT_HL);
					Produce::inv_call_iname(Emit::tree(), iname);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, o_s);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, force_plural_s);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), NE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) -1);
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, gna_s);
							Produce::inv_primitive(Emit::tree(), PLUS_BIP);
							Produce::down(Emit::tree());
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
								Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, gna_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, gna_s);
			Produce::inv_primitive(Emit::tree(), MODULO_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, gna_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 6);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, gna_s);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				for (int gna=0; gna<6; gna++) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) gna);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), PRINT_BIP);
							Produce::down(Emit::tree());
								TEMPORARY_TEXT(T)
								int number_sought = 1, gender_sought = NEUTER_GENDER;
								if (gna%3 == 0) gender_sought = MASCULINE_GENDER;
								if (gna%3 == 1) gender_sought = FEMININE_GENDER;
								if (gna >= 3) number_sought = 2;
								wording AW = Clusters::get_form_general(aph->adjective_names,
									Projects::get_language_of_play(Task::project()), number_sought, gender_sought);
								if (Wordings::nonempty(AW)) WRITE_TO(T, "%W", AW);
								else WRITE_TO(T, "%W", PW);
								Produce::val_text(Emit::tree(), T);
								DISCARD_TEXT(T)
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Routines::end(save);
	}
}

void AdjectiveMeanings::emit(adjective *aph) {
	Produce::inv_call_iname(Emit::tree(), aph->adjective_compilation.aph_iname);
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_NOUN_HL));
		Produce::inv_primitive(Emit::tree(), GE_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_LIST_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(SAY__P_HL));
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
	Produce::up(Emit::tree());
}
