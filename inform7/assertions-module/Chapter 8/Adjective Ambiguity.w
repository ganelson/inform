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
	struct linked_list *in_defn_order; /* of |adjective_meaning| */
	struct linked_list *in_precedence_order; /* of |adjective_meaning| */
} adjective_meaning_data;

void AdjectiveAmbiguity::new_set(adjective *adj) {
	adj->adjective_meanings.in_defn_order = NEW_LINKED_LIST(adjective_meaning);
	adj->adjective_meanings.in_precedence_order = NEW_LINKED_LIST(adjective_meaning);
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
	ADD_TO_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order);
	am->owning_adjective = adj;
	return adj;
}

@ And here we log the unsorted list.

=
void AdjectiveAmbiguity::log(adjective *adj) {
	if (adj == NULL) { LOG("<null-APH>\n"); return; }
	int n = 1;
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order) {
		LOG("%d: %W ", n, am->indexing_text);
		AdjectiveMeaningDomains::log(&(am->domain));
		n++;
	}
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
		LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order) {
			if (AdjectiveMeaningDomains::determine_avoiding_circularity(am) == FALSE)
				return FALSE;
			kind *am_kind = AdjectiveMeaningDomains::get_kind(am);
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

@ Does a given adjective have any interpretation as an enumerated property
value, or an either/or property? If so we return the earliest known.

=
instance *AdjectiveAmbiguity::has_enumerative_meaning(adjective *adj) {
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order)
		if (InstanceAdjectives::is_enumerative(am))
			return RETRIEVE_POINTER_instance(am->family_specific_data);
	return NULL;
}

property *AdjectiveAmbiguity::has_either_or_property_meaning(adjective *adj, int *sense) {
	adjective_meaning *am;
	if (adj)
		LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order)
			if (EitherOrPropertyAdjectives::is(am)) {
				if (sense) {
					if (am->negated_from) *sense = FALSE;
					else *sense = TRUE;
				}
				return RETRIEVE_POINTER_property(am->family_specific_data);
			}
	return NULL;
}

@ Occasionally we just want one meaning:

=
adjective_meaning *AdjectiveAmbiguity::first_meaning(adjective *adj) {
	if (adj == NULL) return NULL;
	return FIRST_IN_LINKED_LIST(adjective_meaning,
		adj->adjective_meanings.in_defn_order);
}

@h Sorting lists of meanings.
After meanings have been declared, a typical APH will have a disordered
"possible meaning" list and an empty "sorted meaning" list. The following
insertion-sorts[1] the possibles list into the sorted list.

[1] Well, yes, but these are very short lists, typically 5 items or fewer.

=
void AdjectiveAmbiguity::sort(adjective *adj) {
	if (adj == NULL) internal_error("tried to sort meanings for null adjective");
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order)
		AdjectiveMeaningDomains::determine_if_possible(am);
	LinkedLists::empty(adj->adjective_meanings.in_precedence_order);
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order) {
		adjective_meaning *am2; int pos = 0;
		LOOP_OVER_LINKED_LIST(am2, adjective_meaning, 
			adj->adjective_meanings.in_precedence_order) {
			if (AdjectiveAmbiguity::cmp(am, am2) == 1) break;
			pos++;
		}
		LinkedLists::insert(adj->adjective_meanings.in_precedence_order, pos, am);
	}
}

int AdjectiveAmbiguity::cmp(adjective_meaning *am1, adjective_meaning *am2) {
	if (am1 == am2) return 0;
	int d = AdjectiveMeaningDomains::cmp(&(am1->domain), &(am2->domain));
	if (d != 0) return d;
	if (am1->domain.domain_infs == am2->domain.domain_infs)
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
			Problems::quote_wording_as_source(1, am1->indexing_text);
			Problems::quote_wording_as_source(2, am2->indexing_text);
			StandardProblems::handmade_problem(Task::syntax_tree(), 
				_p_(PM_AdjDomainDuplicated));
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

@ With that sorting done, we can begin to use an adjective. Suppose there has
been an assertion sentence like this:

>> The ormolu clock is fixed in place.

"Fixed in place" is identified as an adjective, |adj|; the "ormulo clock" is
what it applies to, stored in either |infs_to_assert_on|. |kind_domain| is what
kind we think this has. |parity| is equal to |TRUE|.

What happens is that the list of definitions for "fixed in place" is checked
in logical precedence order, and //AdjectiveMeanings::assert// called
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
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_precedence_order)
		if (AdjectiveMeaningDomains::strong_match(kind_domain, infs_to_assert_on, am))
			if (AdjectiveMeanings::assert(am, infs_to_assert_on, parity))
				return TRUE;
	return FALSE;
}

@ Similarly, the following produces an I6 schema to carry out a task for the
adjective. (See //AdjectiveMeanings::make_schema// for tasks.)

=
i6_schema *AdjectiveAmbiguity::schema_for_task(adjective *adj, kind *kind_domain, int T) {
	if (kind_domain == NULL) kind_domain = K_object;
	AdjectiveAmbiguity::sort(adj);
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_precedence_order) {
		AdjectiveMeaningDomains::determine(am);
		if (AdjectiveMeaningDomains::weak_match(kind_domain, am) == FALSE) continue;
		i6_schema *i6s = AdjectiveMeanings::get_schema(am, T);
		if (i6s) return i6s;
	}
	return NULL;
}
