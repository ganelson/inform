[ActionNameLists::] Action Name Lists.

Action name lists are used in parsing action patterns, and identify which
action names seem to be possible within them.

@h Data structure.
An ANL is a head object, an //action_name_list//, which points to a linked
list of //anl_entry// objects.

=
typedef struct action_name_list {
	struct anl_entry *entries;
	int negation_state;
	int test_this_in_ap_match;
} action_name_list;

action_name_list *ActionNameLists::new_list(anl_entry *first, int state) {
	action_name_list *list = CREATE(action_name_list);
	list->entries = first;
	list->negation_state = state;
	list->test_this_in_ap_match = TRUE;
	return list;
}

@ The "negation state" of a list is one of three possibilities, not two. The
difference is that "doing something other than examining the box", for example,
is |ANL_NEGATED_LISTWISE|, whereas "doing something other than examining to the
box" is |ANL_NEGATED_ITEMWISE|. Note that the state is set irrevocably when the
list is created.

@d ANL_POSITIVE 1
@d ANL_NEGATED_LISTWISE 2
@d ANL_NEGATED_ITEMWISE 3

=
int ActionNameLists::listwise_negated(action_name_list *list) {
	if ((list) && (list->negation_state == ANL_NEGATED_LISTWISE)) return TRUE;
	return FALSE;
}

int ActionNameLists::itemwise_negated(action_name_list *list) {
	if ((list) && (list->negation_state == ANL_NEGATED_ITEMWISE)) return TRUE;
	return FALSE;
}

int ActionNameLists::positive(action_name_list *list) {
	if ((list == NULL) || (list->negation_state == ANL_POSITIVE)) return TRUE;
	return FALSE;
}

@ It is sometimes possible when matching action patterns to prove that it
is unnecessary to test that the action appears in this list; and then the
list can be marked accordingly:

=
void ActionNameLists::suppress_action_testing(action_name_list *list) {
	list->test_this_in_ap_match = FALSE;
}

int ActionNameLists::testing(action_name_list *list) {
	if (list == NULL) return FALSE;
	return list->test_this_in_ap_match;
}

@ An entry has some book-keeping fields, and is otherwise divided into the
item itself -- either an action name or a named action pattern -- and some
parsing data needed by the complicated algorithms for turning text into an
action list.

=
typedef struct anl_entry {
	struct anl_item item;
	struct anl_parsing_data parsing_data;
	int marked_for_deletion;
	struct anl_entry *next_entry; /* next in this ANL list */
} anl_entry;

anl_entry *ActionNameLists::new_entry_at(wording W) {
	anl_entry *entry = CREATE(anl_entry);
	entry->item = ActionNameLists::new_item();
	int at = -1;
	if (Wordings::nonempty(W)) at = Wordings::first_wn(W);
	entry->parsing_data = ActionNameLists::new_parsing_data(at);
	entry->marked_for_deletion = FALSE;
	return entry;
}

@ The model here is that the list can be reduced in size by marking entries
for deletion and then, subsequently, having all such entries removed. Note
that the head //action_name_list// object remains valid even if every entry
is removed.

=
void ActionNameLists::mark_for_deletion(anl_entry *X) {
	if (X) X->marked_for_deletion = TRUE;
	else internal_error("tried to mark null entry for deletion");
}

int ActionNameLists::marked_for_deletion(anl_entry *X) {
	if (X) return X->marked_for_deletion;
	return FALSE;
}

@ This function actually does two things: deletes unwanted entries, and deletes
entries which fail to change the word position.

=
void ActionNameLists::remove_entries_marked_for_deletion(action_name_list *list) {
	if (list) {
		int pos = -1;
		for (anl_entry *entry = list->entries, *prev = NULL; entry; entry = entry->next_entry) {
			if ((entry->marked_for_deletion) || (pos == entry->parsing_data.word_position)) {
				if (prev == NULL) list->entries = entry->next_entry;
				else prev->next_entry = entry->next_entry;
			} else {
				prev = entry;
				pos = entry->parsing_data.word_position;
			}
		}
	}
}

@ The list must be kept in a strict order, as can be seen:

=
void ActionNameLists::join_to(anl_entry *earlier, anl_entry *later) {
	if (ActionNameLists::precedes(later, earlier)) internal_error("misordering");
	earlier->next_entry = later;
}

@ Which uses the following function:

(*) Results in later word positions come first, and if that doesn't decide it
(*) NAPs come before actions, and if that doesn't decide it
(*) Older NAPs come before younger ones, and if that doesn't decide it
(*) Less abbreviated results come first, and if that doesn't decide it
(*) Older action names come before younger, and if that doesn't decide it
(*) Later-discovered results come before earlier ones.

Here, "older" and "younger" mean how long ago the relevant //named_action_pattern//
or //action_name// objects were created, and since this happens in source text
order, we are really saying "closer to the top of the source text" when we
say "older".

Note that this function is transitive ($p(x, y)$ and $p(y, z)$ implies $p(x, z)$)
and antisymmetric ($p(x, y)$ implies that $p(y, x)$ is false). Strictly speaking
it is not trichotomous, but if neither $p(x, y)$ nor $p(y, x)$ then $x$ and $y$
have identical item data; and in that case it doesn't matter which way round they
are in the list.

=
int ActionNameLists::precedes(anl_entry *e1, anl_entry *e2) {
	if (e1 == NULL) return FALSE;
	if (e2 == NULL) return TRUE;

	int c = e1->parsing_data.word_position -
			e2->parsing_data.word_position;
	if (c > 0) return TRUE; if (c < 0) return FALSE;

	c = ((e1->item.nap_listed)?(e1->item.nap_listed->allocation_id):10000000) -
		((e2->item.nap_listed)?(e2->item.nap_listed->allocation_id):10000000);
	if (c > 0) return TRUE; if (c < 0) return FALSE;

	c = e1->parsing_data.abbreviation_level -
		e2->parsing_data.abbreviation_level;
	if (c < 0) return TRUE; if (c > 0) return FALSE;

	c = ((e1->item.action_listed)?(e1->item.action_listed->allocation_id):10000000) -
		((e2->item.action_listed)?(e2->item.action_listed->allocation_id):10000000);
	if (c > 0) return TRUE; if (c < 0) return FALSE;

	return FALSE;
}

anl_entry *ActionNameLists::join_entry(anl_entry *further, anl_entry *tail) {
	if (further == NULL) return tail;
	if (tail == NULL) return further;
	anl_entry *entry = tail;
	while (entry->next_entry != NULL) entry = entry->next_entry;
	ActionNameLists::join_to(entry, further);
	return tail;
}

@ When not pruning the list, these macros are useful for working through it:

@d LOOP_THROUGH_ANL(var, list)
	for (anl_entry *var = (list)?(list->entries):NULL; var; var = var->next_entry)

@d LOOP_THROUGH_ANL_WITH_PREV(var, prev_var, next_var, list)
	for (anl_entry *var = (list)?(list->entries):NULL,
		*prev_var = NULL, *next_var = (var)?(var->next_entry):NULL;
		var;
		prev_var = var, var = next_var, next_var = (next_var)?(next_var->next_entry):NULL)

=
int ActionNameLists::length(action_name_list *list) {
	int C = 0;
	LOOP_THROUGH_ANL(entry, list) C++;
	return C;
}

int ActionNameLists::nonempty(action_name_list *list) {
	if ((list) && (list->entries)) return TRUE;
	return FALSE;
}

@ If an action list is a wrapper for a single named action pattern, the
following function returns that NAP. Anything more complicated, |NULL|.

=
named_action_pattern *ActionNameLists::is_single_NAP(action_name_list *list) {
	if ((ActionNameLists::length(list) == 1) && (list->negation_state == ANL_POSITIVE)) {
		anl_item *item = ActionNameLists::first_item(list);
		return item->nap_listed;
	}
	return NULL;
}

@ The //anl_item// material is the actual content we are trying to get at.
Like life, items are a mixture of naps and actions. At most one of these
fields is non-|NULL|. If they are both |NULL|, this represents "doing
anything" -- a completely unrestricted action.

=
typedef struct anl_item {
	struct action_name *action_listed; /* the action in this ANL list entry */
	struct named_action_pattern *nap_listed; /* or a named pattern instead */
} anl_item;

anl_item ActionNameLists::new_item(void) {
	anl_item item;
	item.action_listed = NULL;
	item.nap_listed = NULL;
	return item;
}

void ActionNameLists::clear_item_data(anl_entry *entry, action_name *an) {
	entry->item.action_listed = an;
	entry->item.nap_listed = NULL;
}

anl_item *ActionNameLists::first_item(action_name_list *list) {
	if ((list) && (list->entries)) return &(list->entries->item);
	return NULL;
}

@ The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int ActionNameLists::compare_specificity(action_name_list *anl1, action_name_list *anl2) {
	int count1, count2;
	count1 = ActionNameLists::count_actions_covered(anl1);
	count2 = ActionNameLists::count_actions_covered(anl2);
	if (count1 < count2) return 1;
	if (count1 > count2) return -1;
	return 0;
}

int ActionNameLists::count_actions_covered(action_name_list *list) {
	int k = 0, infinity = NUMBER_CREATED(action_name);
	if (list == NULL) return infinity;
	if (list->entries == NULL) return infinity;
	LOOP_THROUGH_ANL(entry, list) {
		if (entry->item.nap_listed) continue;
		if ((entry->item.action_listed) && (k < infinity)) k++;
		else k = infinity;
	}
	if (ActionNameLists::positive(list) == FALSE) k = infinity - k;
	return k;
}

named_action_pattern *ActionNameLists::nap(anl_entry *entry) {
	if (entry) return entry->item.nap_listed;
	return NULL;
}

action_name *ActionNameLists::action(anl_entry *entry) {
	if (entry) return entry->item.action_listed;
	return NULL;
}

@ A given action |an| falls within the context of this list if it appears
positively in the list, or negatively by not falling into a category excluded
by it; for example, "examining" falls within "examining something", and also
within "doing something other than looking at something" (a case of itemwise
negation) but not "doing something other than looking".

=
int ActionNameLists::covers_action(action_name_list *list, action_name *an) {
	LOOP_THROUGH_ANL(entry, list) {
		anl_item *item = &(entry->item);
		int within = FALSE;
		if (item->action_listed == an) within = TRUE;
		else if (item->nap_listed) within =
			NamedActionPatterns::covers_action(item->nap_listed, an);
		if (((within) && (ActionNameLists::positive(list))) ||
			((within == FALSE) && (ActionNameLists::positive(list) == FALSE)))
			return TRUE;
	}
	return FALSE;
}

@ The //anl_parsing_data// material is needed on a temporary basis when parsing
the text leading to a list:

=
typedef struct anl_parsing_data {
	int word_position; /* and some values used temporarily during parsing */
	int parc;
	struct wording parameter[2];
	struct wording in_clause;
	int abbreviation_level; /* number of words missing */
} anl_parsing_data;

anl_parsing_data ActionNameLists::new_parsing_data(int at) {
	anl_parsing_data parsing_data;
	parsing_data.parc = 0;
	parsing_data.word_position = at;
	parsing_data.in_clause = EMPTY_WORDING;
	parsing_data.abbreviation_level = 0;
	return parsing_data;
}

void ActionNameLists::clear_parsing_data(anl_entry *entry, wording W) {
	entry->parsing_data.parc = 0;
	int at = -1;
	if (Wordings::nonempty(W)) at = Wordings::first_wn(W);
	entry->parsing_data.word_position = at;
	entry->parsing_data.in_clause = EMPTY_WORDING;
	entry->parsing_data.abbreviation_level = 0;
}

int ActionNameLists::parc(anl_entry *entry) {
	if (entry) return entry->parsing_data.parc;
	return 0;
}

wording ActionNameLists::par(anl_entry *entry, int i) {
	if ((entry) && (entry->parsing_data.parc > i)) return entry->parsing_data.parameter[i];
	return EMPTY_WORDING;
}

wording ActionNameLists::in_clause(anl_entry *entry) {
	if (entry) return entry->parsing_data.in_clause;
	return EMPTY_WORDING;
}

anl_entry *ActionNameLists::add_parameter(anl_entry *entry, wording W) {
	if (entry == NULL) internal_error("no entry");
	if (entry->parsing_data.parc >= 2) internal_error("too many ANL parameters");
	entry->parsing_data.parameter[entry->parsing_data.parc] = W;
	entry->parsing_data.parc++;
	return entry;
}

anl_entry *ActionNameLists::add_in_clause(anl_entry *entry, wording W) {
	if (entry == NULL) internal_error("no entry");
	entry->parsing_data.in_clause = W;
	return entry;
}

int ActionNameLists::first_position(action_name_list *list) {
	if (list) return ActionNameLists::word_position(list->entries);
	return -1;
}

int ActionNameLists::word_position(anl_entry *entry) {
	if (entry) return entry->parsing_data.word_position;
	return -1;
}

int ActionNameLists::same_word_position(anl_entry *entry, anl_entry *Y) {
	if ((entry) && (Y) && (entry->parsing_data.word_position == Y->parsing_data.word_position))
		return TRUE;
	return FALSE;
}

@h Single and best actions.
This tests whether the list gives a single positive action:

=
action_name *ActionNameLists::single_positive_action(action_name_list *list) {
	if ((ActionNameLists::length(list) == 1) &&
		(ActionNameLists::positive(list)))
		return ActionNameLists::first_item(list)->action_listed;
	return NULL;
}

@ This is used only when the list is part of an exactly known action, so
that it should contain just one item, and this should be an actual action,
not a NAP.

=
action_name *ActionNameLists::get_the_one_true_action(action_name_list *list) {
	action_name *an = ActionNameLists::single_positive_action(list);
	if (an == NULL) internal_error("Singleton ANL points to null AN");
	return an;
}

@ The "best" action is the one maximising the number of words in the fixed
part of an action name: thus if there are actions "throwing away" and
"throwing", then in the ANL arising from the text "throwing away the fish",
the action "throwing away" is better than the action "throwing".

If the list includes actions at two different word positions, so that they
are not alternate readings from the same point, then by definition there
is no best action. (For example, in "throwing or removing something".)

=
action_name *ActionNameLists::get_best_action(action_name_list *list) {
	int posn = -1, best_score = -1;
	action_name *best = NULL;
	if (ActionNameLists::positive(list) == FALSE) return NULL;
	LOOP_THROUGH_ANL(entry, list)
		if (entry->item.action_listed) {
			int score = ActionNameLists::entry_score(entry);
			if (entry->parsing_data.word_position != posn) {
				if (posn >= 0) return NULL;
				posn = entry->parsing_data.word_position;
				best = entry->item.action_listed;
				best_score = score;
			} else {
				if (score > best_score) {
					best_score = score;
					best = entry->item.action_listed;
				}
			}
		}
	return best;
}

int ActionNameLists::entry_score(anl_entry *entry) {
	if ((entry) && (entry->item.action_listed))
		return ActionNameNames::non_it_length(entry->item.action_listed) -
			entry->parsing_data.abbreviation_level;
	return -1;
}

@h Logging.

=
void ActionNameLists::log(action_name_list *list) {
	if (list == NULL) {
		LOG("<null-anl>");
	} else {
		if (ActionNameLists::listwise_negated(list)) LOG("L-NOT[ ");
		if (ActionNameLists::itemwise_negated(list)) LOG("I-NOT[ ");
		int c = 0;
		LOOP_THROUGH_ANL(entry, list) {
			LOG("(%d). ", c);
			ActionNameLists::log_entry(entry);
			c++;
		}
		if (ActionNameLists::listwise_negated(list)) LOG(" ]");
	}
}

void ActionNameLists::log_briefly(action_name_list *list) {
	if (list == NULL) {
		LOG("<null-anl>");
	} else {
		if (ActionNameLists::listwise_negated(list)) LOG("L-NOT[ ");
		if (ActionNameLists::itemwise_negated(list)) LOG("I-NOT[ ");
		int c = 0;
		LOOP_THROUGH_ANL(entry, list) {
			if (c > 0) LOG(" / ");
			ActionNameLists::log_entry_briefly(entry);
			c++;
		}
		if (ActionNameLists::listwise_negated(list)) LOG(" ]");
	}
}

void ActionNameLists::log_entry(anl_entry *entry) {
	if (entry == NULL) {
		LOG("<null-entry>");
	} else {
		LOG("ANL entry %s(@%d): ",
			(entry->marked_for_deletion)?"(to be deleted) ":"",
			entry->parsing_data.word_position);
		if (entry->item.action_listed)
			LOG("%W", ActionNameNames::tensed(entry->item.action_listed, IS_TENSE));
		else if (entry->item.nap_listed)
			LOG("%W", Nouns::nominative_singular(entry->item.nap_listed->as_noun));
		else LOG("NULL");
		for (int i=0; i<entry->parsing_data.parc; i++)
			LOG(" [%d: %W]", i, entry->parsing_data.parameter[i]);
		if (Wordings::nonempty(entry->parsing_data.in_clause))
			LOG(" [in: %W]\n", entry->parsing_data.in_clause);
	}
}

void ActionNameLists::log_entry_briefly(anl_entry *entry) {
	if (entry->item.nap_listed) {
		LOG("%W", Nouns::nominative_singular(entry->item.nap_listed->as_noun));
	} else if (entry->item.action_listed == NULL)
		LOG("ANY");
	else {
		LOG("%W", ActionNameNames::tensed(entry->item.action_listed, IS_TENSE));
	}			
}

@h Parsing text to an ANL.
Action name lists arise only for parsing text, and only from the function below; 
this might match, for example, "doing something other than waiting", or
"dropping the box". We make no effort to understand the words which are not
part of the action: "dropping the box" is just "dropping (two words)" here.

Note that it works in either |IS_TENSE| or |HASBEEN_TENSE|, and that |sense|
is set to |FALSE| (if it is supplied) when the text had a negative sense --
something other than something -- or |TRUE| for a positive one.

The test group |:anl| is helpful in catching errors here.

@ =
int anl_parsing_tense = IS_TENSE;
action_name_list *ActionNameLists::parse(wording W, int tense, int *sense) {
	if (Wordings::mismatched_brackets(W)) return NULL;
	int t = anl_parsing_tense;
	anl_parsing_tense = tense;
	int r = <action-list>(W);
	anl_parsing_tense = t;
	if (r) {
		if (sense) *sense = <<r>>;
		return <<rp>>;
	}
	return NULL;
}

@ The outer parts of the syntax are handled by a Preform grammar.

=
<action-list> ::=
	doing something/anything other than <excluded-list> | ==> { FALSE, RP[1] }
	doing something/anything except <excluded-list> |     ==> { FALSE, RP[1] }
	doing something/anything to/with <anl-to-tail> |      ==> { TRUE, ActionNameLists::new_list(RP[1], ANL_POSITIVE) }
	doing something/anything |                            ==> @<Construct ANL for anything@>
	doing something/anything ... |                        ==> { fail }
	<anl>                                                 ==> { TRUE, ActionNameLists::new_list(RP[1], ANL_POSITIVE) }

<excluded-list> ::=
	<anl> to/with {<minimal-common-to-text>} |            ==> @<Add to-clause to excluded ANL@>;
	<anl>                                                 ==> { TRUE, ActionNameLists::new_list(RP[1], ANL_NEGATED_LISTWISE) }

<minimal-common-to-text> ::=
	_,/or ... |                                           ==> { fail }
	... to/with ... |                                     ==> { fail }
	...

@<Construct ANL for anything@> =
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	==> { TRUE, ActionNameLists::new_list(entry, ANL_POSITIVE) };

@<Add to-clause to excluded ANL@> =
	anl_entry *entry = RP[1];
	if ((entry == NULL) ||
		(ActionSemantics::can_have_noun(entry->item.action_listed) == FALSE)) {
		==> { fail production };
	}
	ActionNameLists::add_parameter(entry, GET_RW(<excluded-list>, 1));
	==> { FALSE, ActionNameLists::new_list(entry, ANL_NEGATED_ITEMWISE) };

@ The trickiest form is:

>> doing something to the box in the dining room

where no explicit action occurs at all, but we have to parse the rest of
the text as if it does, including an "in" clause.

So <text-of-in-clause> finds the first "in" within its range of words, except
that it throws out an "in" that we consider bogus for our own syntactic purposes:
for instance, we don't want to count the "in" from "fixed in place".

=
<anl-to-tail> ::=
	<anl-operand> <text-of-in-clause> |  ==> @<Augment ANL with in clause@>
	<anl-operand>                        ==> { pass 1 }

<anl-operand> ::=
	...                                  ==> { TRUE, ActionNameLists::entry_for_to_tail(W) };

<text-of-in-clause> ::=
	fixed in place *** |                 ==> { advance Wordings::delta(WR[1], W) }
	is/are/was/were/been/listed in *** | ==> { advance Wordings::delta(WR[1], W) }
	in ...                               ==> { TRUE, - }

@<Augment ANL with in clause@> =
	==> { TRUE, ActionNameLists::add_in_clause(RP[1], GET_RW(<text-of-in-clause>, 1)) }

@ This matches a comma/or-separated list of items:

=
<anl> ::=
	<anl-entry> <anl-tail> |  ==> { 0, ActionNameLists::join_entry(RP[1], RP[2]) }
	<anl-entry>               ==> { pass 1 }

<anl-tail> ::=
	, _or <anl> |             ==> { pass 1 }
	_,/or <anl>               ==> { pass 1 }

@ Items can be named action patterns, so let's get those out of the way first:

=
<anl-entry> ::=
	<named-action-pattern>	|                    ==> @<Make a NAP entry@>
	<named-action-pattern> <text-of-in-clause> | ==> @<Make a NAP entry with an in clause@>
	<anl-entry-with-action>					     ==> { pass 1 }

@<Make a NAP entry@> =
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	entry->item.nap_listed = RP[1];
	==> { 0, entry };

@<Make a NAP entry with an in clause@> =
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	entry->item.nap_listed = RP[1];
	ActionNameLists::add_in_clause(entry, GET_RW(<text-of-in-clause>, 1));
	==> { 0, entry };

@ Which reduces us to an internal nonterminal for an entry in this list.
It actually produces multiple matches: for example,

>> taking inventory

will result in a list of two possibilities -- "taking inventory", the
action, with no operand; and "taking", the action, applied to the
operand "inventory". (It's unlikely that the last will succeed in the
end, but it's syntactically valid.)

=
<anl-entry-with-action> internal {
	anl_entry *results = NULL;
	@<Parse the wording into a list of results@>;
	if (results) {
		==> { -, results }; return TRUE;
	}
	==> { fail nonterminal };
}

@<Parse the wording into a list of results@> =
	LOGIF(ACTION_PATTERN_PARSING, "Parsing ANL from %W (tense %d)\n", W, anl_parsing_tense);
	anl_entry *trial_entry = ActionNameLists::new_entry_at(EMPTY_WORDING);

	action_name *an;
	LOOP_OVER(an, action_name) {
		@<Ready the trial entry for another test@>;
		wording RW = EMPTY_WORDING;
		@<Make the trial entry fit this action, if possible, leaving remaining text in RW@>;
		@<Consider the trial entry for inclusion in the results list@>;
		NoMatch: ;
	}
	LOGIF(ACTION_PATTERN_PARSING, "Parsing ANL from %W resulted in:\n$8\n", W, results);

@<Ready the trial entry for another test@> =
	trial_entry->next_entry = NULL;
	ActionNameLists::clear_item_data(trial_entry, an);
	ActionNameLists::clear_parsing_data(trial_entry, W);

@ Here |XW| will be the wording of the action name, say "removing it from";
we try to fit |W| to this, say "removing a heavy thing from something in the
Dining Room"; and if we cannot, we run away to the label |NoMatch|, which is
inelegant, but there's no elegant way to break out of nested loops in C.

@<Make the trial entry fit this action, if possible, leaving remaining text in RW@> =
	int x_ended = FALSE;
	int it_optional = ActionNameNames::it_optional(an);
	int abbreviable = ActionNameNames::abbreviable(an);
	wording XW = ActionNameNames::tensed(an, anl_parsing_tense);
	int w_m = Wordings::first_wn(W), x_m = Wordings::first_wn(XW);
	while ((w_m <= Wordings::last_wn(W)) && (x_m <= Wordings::last_wn(XW))) {
		if (Lexer::word(x_m++) != Lexer::word(w_m++)) goto NoMatch;
		if (x_m > Wordings::last_wn(XW)) { x_ended = TRUE; break; }
		if (<object-pronoun>(Wordings::one_word(x_m))) {
			if (w_m > Wordings::last_wn(W)) x_ended = TRUE; else {
				int j = -1, k;
				for (k=(it_optional)?(w_m):(w_m+1); k<=Wordings::last_wn(W); k++)
					if (Lexer::word(k) == Lexer::word(x_m+1)) { j = k; break; }
				if (j<0) goto NoMatch;
				if (j-1 >= w_m)
					ActionNameLists::add_parameter(trial_entry, Wordings::new(w_m, j-1));
				else
					ActionNameLists::add_parameter(trial_entry, EMPTY_WORDING);
				w_m = j; x_m++;
			}
		}
		if (x_ended) break;
	}
	if ((w_m > Wordings::last_wn(W)) && (x_ended == FALSE)) {
		if (abbreviable) x_ended = TRUE; else goto NoMatch;
	}
	if (x_m <= Wordings::last_wn(XW))
		trial_entry->parsing_data.abbreviation_level = Wordings::last_wn(XW)-x_m+1;
	RW = Wordings::from(W, w_m);

@<Consider the trial entry for inclusion in the results list@> =
	if (Wordings::empty(RW)) {
		@<Include the trial entry@>;
	} else if (<text-of-in-clause>(RW)) {
		ActionNameLists::add_in_clause(trial_entry, GET_RW(<text-of-in-clause>, 1));
		@<Include the trial entry@>;
	} else if ((ActionSemantics::can_have_noun(an)) &&
		(ActionNameLists::parse_to_tail(trial_entry, RW))) {
		@<Include the trial entry@>;
	}

@ As an aside, the following code runs a specially adapted form of <anl-to-tail>:
not one which parses any differently, just one which uses the trial entry and not
newly-created ones (which would be expensive on memory).

=
anl_entry *to_tail_entry_being_parsed = NULL;
anl_entry *ActionNameLists::entry_for_to_tail(wording W) {
	anl_entry *entry;
	if ((!preform_lookahead_mode) && (to_tail_entry_being_parsed))
		entry = to_tail_entry_being_parsed;
	else entry = ActionNameLists::new_entry_at(W);
	ActionNameLists::add_parameter(entry, W);
	return entry;
}

int ActionNameLists::parse_to_tail(anl_entry *entry, wording W) {
	int result = FALSE;
	to_tail_entry_being_parsed = entry;
	if (<anl-to-tail>(W)) result = TRUE;
	to_tail_entry_being_parsed = NULL;
	return result;
}

@ So this is the happy ending. We don't copy the trial entry; we insertion-sort
the structure itself into the results list, and make a fresh structure to be
the trial entry for future trials.

@<Include the trial entry@> =
	if (results == NULL) {
		results = trial_entry;
	} else {
		anl_entry *pos = results, *prev = NULL;
		while ((pos) && (ActionNameLists::precedes(pos, trial_entry)))
			prev = pos, pos = pos->next_entry;
		if (prev) ActionNameLists::join_to(prev, trial_entry); else results = trial_entry;
		ActionNameLists::join_to(trial_entry, pos);
	}
	trial_entry = ActionNameLists::new_entry_at(EMPTY_WORDING);
