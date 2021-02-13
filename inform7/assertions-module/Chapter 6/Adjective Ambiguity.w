[AdjectiveAmbiguity::] Adjective Ambiguity.

Managing the multiple contextual meanings which a single adjective can have.

@ Adjectives can have multiple meanings. For example, it is legal to define
both of these in the same source text:
= (text as Inform 7)
Definition: a text is empty rather than non-empty if it is "".

Definition: a table name is empty rather than non-empty if the
number of filled rows in it is 0.
=
This gives two different meanings to both "empty" and "non-empty". We can
only work out which meaning is intended by looking at the context, that is,
at the kind of whatever it is applied to. For a text, the first sense applies,
and for a table name, the second.

So, then, every adjective has the following data attached to it:

@d ADJECTIVE_MEANING_LINGUISTICS_CALLBACK AdjectiveAmbiguity::new_set

=
typedef struct adjective_meaning_data {
	struct adjective_meaning *possible_meanings; /* list in the order defined */
	struct adjective_meaning *sorted_meanings; /* list in logical precedence order */
} adjective_meaning_data;

void AdjectiveAmbiguity::new_set(adjective *adj) {
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
adjective *AdjectiveAmbiguity::add_meaning_to_adjective(adjective_meaning *am,
	adjective *adj) {
	adjective_meaning *aml = adj->adjective_meanings.possible_meanings;
	if (aml == NULL) adj->adjective_meanings.possible_meanings = am;
	else {
		while (aml->next_meaning) aml = aml->next_meaning;
		aml->next_meaning = am;
	}
	am->next_meaning = NULL;
	am->owning_adjective = adj;
	return adj;
}

@ And here we log the unsorted list.

=
void AdjectiveAmbiguity::log(adjective *adj) {
	if (adj == NULL) { LOG("<null-APH>\n"); return; }
	adjective_meaning *am;
	int n;
	for (n=1, am = adj->adjective_meanings.possible_meanings; am;
		n++, am = am->next_meaning)
		LOG("%d: %W (domain:$j) (dk:%u)\n", n, am->adjective_index_text,
			am->domain_infs, am->domain_kind);
}

@ If the source tries to apply the word "open", say, to a given value or
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
int AdjectiveAmbiguity::can_be_applied_to(adjective *adj, kind *K) {
	if (adj) {
		adjective_meaning *am;
		for (am = adj->adjective_meanings.possible_meanings; am; am = am->next_meaning) {
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
		Problems::quote_wording(2, Clusters::get_form(adj->adjective_names, FALSE));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AdjectiveCircular));
		Problems::issue_problem_segment(
			"In the sentence %1, it looks as if the definition of the adjective "
			"'%2' may be circular.");
		Problems::issue_problem_end();
	}
	return FALSE;

@ Does a given adjective have any interpretation as an enumerated property
value, or an either/or property? If so we return the earliest known.

=
instance *AdjectiveAmbiguity::has_enumerative_meaning(adjective *adj) {
	adjective_meaning *am;
	for (am = adj->adjective_meanings.possible_meanings; am; am = am->next_meaning)
		if (InstanceAdjectives::is_enumerative(am))
			return RETRIEVE_POINTER_instance(am->detailed_meaning);
	return NULL;
}

property *AdjectiveAmbiguity::has_either_or_property_meaning(adjective *adj, int *sense) {
	if (adj)
		for (adjective_meaning *am = adj->adjective_meanings.possible_meanings;
			am; am = am->next_meaning)
			if (Properties::EitherOr::is_either_or_adjective(am)) {
				if (sense) *sense = am->meaning_parity;
				return RETRIEVE_POINTER_property(am->detailed_meaning);
			}
	return NULL;
}

@ Occasionally we just want one meaning:

=
adjective_meaning *AdjectiveAmbiguity::first_meaning(adjective *adj) {
	if (adj == NULL) return NULL;
	return adj->adjective_meanings.possible_meanings;
}

@h Sorting lists of meanings.
After meanings have been declared, a typical APH will have a disordered
"possible meaning" list and an empty "sorted meaning" list. The following
insertion-sorts[1] the possibles list into the sorted list.

[1] Well, yes, but these are very short lists, typically 5 items or fewer.

=
void AdjectiveAmbiguity::sort(adjective *adj) {
	if (adj == NULL) internal_error("tried to sort meanings for null adjective");
	adjective_meaning *unsorted_head = adj->adjective_meanings.possible_meanings;
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
	adj->adjective_meanings.sorted_meanings = sorted_head;
}

adjective_meaning *AdjectiveAmbiguity::get_sorted_definition_list(adjective *adj) {
	return adj->adjective_meanings.sorted_meanings;
}

@ With that sorting done, we can begin to use an adjective. Suppose there has
been an assertion sentence like this:

>> The ormolu clock is fixed in place.

"Fixed in place" is identified as an adjective, |adj|; the "ormulo clock" is
what it applies to, stored in either |infs_to_assert_on| or |val_to_assert_on|
depending on what it is. |kind_domain| is what kind we think this has. |parity|
is equal to |TRUE|.

What happens is that the list of definitions for "fixed in place" is checked
in logical precedence order, and //AdjectiveMeanings::assert_single// called
on any kind which the "ormolu clock" matches. (That will probably be the
definition for the "fixed in place" either/or property for things, unless
someone has given the adjective some special meaning unique to the clock.) The
first adjective meaning to be assertable then wins.

The following routine therefore acts as a junction-box, deciding which sense
of the adjective is to be applied. We return |TRUE| if we were able to find a
definition which could be asserted and which the clock matched, and |FALSE| if
there was no definition which applied, or if none of those which did could be
asserted for it.

=
int AdjectiveAmbiguity::assert(adjective *adj, kind *kind_domain,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	AdjectiveAmbiguity::sort(adj);
	for (adjective_meaning *am = adj->adjective_meanings.sorted_meanings;
		am; am = am->next_sorted) {
		if (AdjectiveMeanings::domain_weak_match(kind_domain,
			AdjectiveMeanings::get_domain(am)) == FALSE) continue;
		if (AdjectiveMeanings::domain_subj_compare(infs_to_assert_on, am) == FALSE)
			continue;
		if (AdjectiveMeanings::assert_single(am, infs_to_assert_on, val_to_assert_on, parity))
			return TRUE;
	}
	return FALSE;
}

@ Similarly, the following produces an I6 schema to carry out a task for the
adjective. (See //AdjectiveMeanings::set_i6_schema// for tasks.)

=
i6_schema *AdjectiveAmbiguity::schema_for_task(adjective *adj, kind *kind_domain, int T) {
	if (kind_domain == NULL) kind_domain = K_object;
	AdjectiveAmbiguity::sort(adj);
	for (adjective_meaning *am = adj->adjective_meanings.sorted_meanings; am; am = am->next_sorted) {
		kind *am_kind = AdjectiveMeanings::get_domain(am);
		if (am_kind == NULL) {
			AdjectiveMeanings::set_definition_domain(am, FALSE);
			am_kind = AdjectiveMeanings::get_domain(am);
		}
		if (AdjectiveMeanings::domain_weak_match(kind_domain, am_kind) == FALSE) continue;
		i6_schema *i6s = AdjectiveMeanings::schema_for_task(am, T);
		if (i6s) return i6s;
	}
	return NULL;
}
