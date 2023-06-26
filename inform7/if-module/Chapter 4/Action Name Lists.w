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
		int pos = -2;
		for (anl_entry *entry = list->entries, *prev = NULL; entry; entry = entry->next_entry) {
			if (Log::aspect_switched_on(ACTION_PATTERN_PARSING_DA)) {
				ActionNameLists::log_entry(entry); LOG(" (wp %d)",
					entry->parsing_data.word_position);
			}
			int delete = FALSE;
			if (entry->marked_for_deletion) {
				delete = TRUE;
				LOGIF(ACTION_PATTERN_PARSING, ": marked, so delete\n");
			} else if (pos == entry->parsing_data.word_position) {
				delete = TRUE;
				LOGIF(ACTION_PATTERN_PARSING, ": fails to advance, so delete\n");
			} else {
				LOGIF(ACTION_PATTERN_PARSING, ": retain\n");
			}
			if (delete) {
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
	if (later == earlier) internal_error("loop");
	if (ActionNameLists::precedes(later, earlier)) {
		WRITE_TO(STDERR, "Earlier: "); ActionNameLists::write_entry_briefly(STDERR, earlier); WRITE_TO(STDERR, "\n");
		WRITE_TO(STDERR, "Later:   "); ActionNameLists::write_entry_briefly(STDERR, later); WRITE_TO(STDERR, "\n");
		internal_error("misordering");
	}
	earlier->next_entry = later;
}

@ Which uses the following function:

(*) Results in later word positions come first, and if that doesn't decide it
(*) NAPs come before actions, and if that doesn't decide it
(*) Older NAPs come before younger ones, and if that doesn't decide it
(*) Less abbreviated results come first, and if that doesn't decide it
(*) Action names with longer non-it-length come before shorter, and if that doesn't decide it
(*) Older action names come before younger, and if that doesn't decide it
(*) Later-discovered results come before earlier ones -- which because of the
way we parse them means that results with more fixed words in clauses come
before those with fewer.

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

	c = ((e1->item.action_listed)?(ActionNameNames::non_it_length(e1->item.action_listed)):10000000) -
		((e2->item.action_listed)?(ActionNameNames::non_it_length(e2->item.action_listed)):10000000);
	if (c > 0) return TRUE; if (c < 0) return FALSE;

	c = ((e1->item.action_listed)?(e1->item.action_listed->allocation_id):10000000) -
		((e2->item.action_listed)?(e2->item.action_listed->allocation_id):10000000);
	if (c > 0) return TRUE; if (c < 0) return FALSE;

	return FALSE;
}

@ These lists are never long, so we don't need to worry about running time here.

On entry |main_list| begins a linked list in which each entry //ActionNameLists::precedes//
the next; while |new_list| can be in any sequence, but must be disjoint from the
|main_list|, i.e., have no entries in common.

On exit the return value heads a linked list in which each entry precedes the
next, and which includes exactly the members of the two lists passed to it.

=
anl_entry *ActionNameLists::join_entries(anl_entry *new_list, anl_entry *main_list) {
	if (new_list == NULL) return main_list;
	if (main_list == NULL) return new_list;
	for (anl_entry *X = new_list; X; X = X->next_entry)
		for (anl_entry *Y = main_list; Y; Y = Y->next_entry)
			if (X == Y) internal_error("ANLs not disjoint");
	anl_entry *new_entry = new_list;
	while (new_entry) {
		anl_entry *next_entry = new_entry->next_entry;
		new_entry->next_entry = NULL;
		@<Insertion-sort the new entry into the main list@>;
		new_entry = next_entry;
	}
	return main_list;
}

@<Insertion-sort the new entry into the main list@> =
	if (ActionNameLists::precedes(new_entry, main_list)) {
		ActionNameLists::join_to(new_entry, main_list);
		main_list = new_entry;
	} else {
		for (anl_entry *prev = NULL, *pos = main_list; pos; prev = pos, pos = pos->next_entry) {	
			if (ActionNameLists::precedes(new_entry, pos)) {
				if (prev) ActionNameLists::join_to(prev, new_entry);
				ActionNameLists::join_to(new_entry, pos);
				break;
			}
			if (pos->next_entry == NULL) {
				ActionNameLists::join_to(pos, new_entry);
				break;
			}
		}
	}

@ When not pruning the list, this macro is useful for working through it:

@d LOOP_THROUGH_ANL(var, list)
	for (anl_entry *var = (list)?(list->entries):NULL; var; var = var->next_entry)

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
	int abbreviation_level; /* number of words missing */
	struct anl_clause *anl_clauses; /* clauses in this reading */
} anl_parsing_data;

anl_parsing_data ActionNameLists::new_parsing_data(int at) {
	anl_parsing_data parsing_data;
	parsing_data.anl_clauses = NULL;
	parsing_data.abbreviation_level = 0;
	parsing_data.word_position = -1;
	return parsing_data;
}

void ActionNameLists::clear_parsing_data(anl_entry *entry, wording W) {
	entry->parsing_data.anl_clauses = NULL;
	int at = -1;
	if (Wordings::nonempty(W)) at = Wordings::first_wn(W);
	entry->parsing_data.word_position = at;
	entry->parsing_data.abbreviation_level = 0;
}

@ Parsing data contains a linked list, sorted in ascending clause ID order, of the
following structures, which are similar (but not identical) to //ap_clause//
objects: and indeed, in the happy case where an entry in an action name list
produces a successful parse in //Parse Clauses//, the //anl_clause//
objects of that entry will be turned into a string of //ap_clause// objects
in the final AP.

=
typedef struct anl_clause {
	int clause_ID;
	struct wording clause_text;
	struct anl_clause *next_clause;
	struct shared_variable *stv_to_match;
	struct parse_node *evaluation;
} anl_clause;

@ And this is convenient for looking through them:

@d LOOP_THROUGH_ANL_CLAUSES(c, entry)
	for (anl_clause *c = (entry)?(entry->parsing_data.anl_clauses):NULL; c; c = c->next_clause)

=
int ActionNameLists::noun_count(anl_entry *entry) {
	int p = 0;
	LOOP_THROUGH_ANL_CLAUSES(c, entry)
		if ((c->clause_ID == NOUN_AP_CLAUSE) || (c->clause_ID == SECOND_AP_CLAUSE))
			p++;
	return p;
}

int ActionNameLists::has_clause(anl_entry *entry, int C) {
	LOOP_THROUGH_ANL_CLAUSES(c, entry)
		if (c->clause_ID == C) return TRUE;
	return FALSE;
}

anl_clause *ActionNameLists::get_clause(anl_entry *entry, int C) {
	LOOP_THROUGH_ANL_CLAUSES(c, entry)
		if (c->clause_ID == C) return c;
	return NULL;
}

wording ActionNameLists::get_clause_wording(anl_entry *entry, int C) {
	LOOP_THROUGH_ANL_CLAUSES(c, entry)
		if (c->clause_ID == C) return c->clause_text;
	return EMPTY_WORDING;
}

@ Note that it is legal to create an ANL clause with empty wording.

=
anl_entry *ActionNameLists::set_clause_wording(anl_entry *entry, int C, wording W) {
	if (entry == NULL) internal_error("no entry");
	anl_clause *prev = NULL;
	LOOP_THROUGH_ANL_CLAUSES(c, entry) {
		if (c->clause_ID == C) {
			c->clause_text = W; return entry;
		}
		if (c->clause_ID > C) @<Insert clause here@>;
		prev = c;
	}
	anl_clause *c = NULL;
	@<Insert clause here@>;
}

@<Insert clause here@> =
	anl_clause *nc = CREATE(anl_clause);
	nc->clause_ID = C;
	nc->clause_text = W;
	nc->evaluation = NULL;
	nc->stv_to_match = NULL;
	if (prev) { nc->next_clause = c; prev->next_clause = nc; }
	else { nc->next_clause = c; entry->parsing_data.anl_clauses = nc; }
	return entry;

@ This is really the same function but setting variable as well as ID.

=
anl_entry *ActionNameLists::set_clause_wording_and_stv(anl_entry *entry, int C,
	wording W, shared_variable *stv) {
	if (entry == NULL) internal_error("no entry");
	anl_clause *prev = NULL;
	LOOP_THROUGH_ANL_CLAUSES(c, entry) {
		if (c->clause_ID == C) {
			c->clause_text = W; c->stv_to_match = stv; return entry;
		}
		if (c->clause_ID > C) @<Insert clause here with stv@>;
		prev = c;
	}
	anl_clause *c = NULL;
	@<Insert clause here with stv@>;
}

@<Insert clause here with stv@> =
	anl_clause *nc = CREATE(anl_clause);
	nc->clause_ID = C;
	nc->clause_text = W;
	nc->evaluation = NULL;
	nc->stv_to_match = stv;
	if (prev) { nc->next_clause = c; prev->next_clause = nc; }
	else { nc->next_clause = c; entry->parsing_data.anl_clauses = nc; }
	return entry;

@ This truncates a clause so that it stops just before the given word number.
For example, "croquet in the gardens" might be truncated to just "croquet".
Here, if the text should become empty as a result then the clause is deleted
from the list. This is important since it removes temporary |TAIL_AP_CLAUSE|
clauses if they successfully convert into more permanent ones.

=
void ActionNameLists::truncate_clause(anl_entry *entry, int C, int wn) {
	anl_clause *prev = NULL;
	LOOP_THROUGH_ANL_CLAUSES(c, entry) {
		if (c->clause_ID == C) {
			c->clause_text = Wordings::up_to(c->clause_text, wn - 1);
			if (Wordings::empty(c->clause_text)) {
				if (prev) prev->next_clause = c->next_clause;
				else entry->parsing_data.anl_clauses = c->next_clause;
			}
			return;
		}
		prev = c;
	}
}

@ Up to two "nouns" can be added to an entry; the first to be added is put
into the |NOUN_AP_CLAUSE| clause, and the second to |SECOND_AP_CLAUSE|.

=
anl_entry *ActionNameLists::add_noun(anl_entry *entry, wording W) {
	switch (ActionNameLists::noun_count(entry)) {
		case 0: ActionNameLists::set_clause_wording(entry, NOUN_AP_CLAUSE, W); break;
		case 1: ActionNameLists::set_clause_wording(entry, SECOND_AP_CLAUSE, W); break;
		default: internal_error("too many nouns for ANL entry");
	}
	return entry;
}

@ So much for clauses. Entries also record the word position at which the
action (or named action pattern) text kicks in:

=
int ActionNameLists::word_position(anl_entry *entry) {
	if (entry) return entry->parsing_data.word_position;
	return -1;
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

This is easy to detect here, because the enforced ordering of the list ensures
that earlier entries are (in this sense) better than later ones.

If the list includes actions at two different word positions, so that they
are not alternate readings from the same point, then by definition there
is no best action. (For example, in "throwing or removing something".)

=
action_name *ActionNameLists::get_best_action(action_name_list *list) {
	if (ActionNameLists::positive(list) == FALSE) return NULL;
	int posn = -1;
	action_name *choice = NULL;
	LOOP_THROUGH_ANL(entry, list) {
		if (entry->item.action_listed) {
			if (entry->parsing_data.word_position != posn) {
				if (posn >= 0) return NULL;
				posn = entry->parsing_data.word_position;
			}
			if (choice == NULL) choice = entry->item.action_listed;
		} else return NULL;
	}
	return choice;
}

@h Duplication.

=
anl_entry *ActionNameLists::duplicate_entry(anl_entry *entry) {
	anl_entry *new_entry = ActionNameLists::new_entry_at(EMPTY_WORDING);
	new_entry->parsing_data = entry->parsing_data;
	new_entry->parsing_data.anl_clauses = NULL;
	LOOP_THROUGH_ANL_CLAUSES(c, entry)
		ActionNameLists::set_clause_wording_and_stv(new_entry,
			c->clause_ID, c->clause_text, c->stv_to_match);
	new_entry->item = entry->item;
	new_entry->next_entry = NULL;
	return new_entry;
}

@h Logging.

=
void ActionNameLists::log(action_name_list *list) {
	if (list == NULL) {
		LOG("<null-anl>");
	} else {
		if (ActionNameLists::listwise_negated(list)) { LOG("L-NOT[\n"); LOG_INDENT; }
		if (ActionNameLists::itemwise_negated(list)) { LOG("I-NOT[\n"); LOG_INDENT; }
		int benchmark = 0;
		LOOP_THROUGH_ANL(entry, list) {
			if ((entry->parsing_data.word_position < benchmark) || (benchmark == 0))
				benchmark = entry->parsing_data.word_position;
		}
		int c = 1;
		LOOP_THROUGH_ANL(entry, list) {
			LOG("(%d). +%d ", c, entry->parsing_data.word_position - benchmark);
			ActionNameLists::log_entry(entry);
			LOG("\n");
			c++;
		}
		if (ActionNameLists::itemwise_negated(list)) { LOG_OUTDENT; LOG("\n]\n"); }
		if (ActionNameLists::listwise_negated(list)) { LOG_OUTDENT; LOG("\n]\n"); }
	}
}

void ActionNameLists::log_entry(anl_entry *entry) {
	if (entry == NULL) {
		LOG("<null-entry>");
	} else {
		if (entry->marked_for_deletion) LOG(" (to be deleted)");
		ActionNameLists::log_entry_briefly(entry);
		LOOP_THROUGH_ANL_CLAUSES(c, entry)
			if (Wordings::nonempty(c->clause_text)) {
			    LOG(" "); ActionNameLists::log_clause(c);
			}
	}
}

void ActionNameLists::log_clause(anl_clause *c) {
	LOG("[");
	APClauses::write_clause_ID(DL, c->clause_ID, c->stv_to_match);
	LOG(": %W]", c->clause_text);
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

void ActionNameLists::log_entry_briefly(anl_entry *entry) {
	if (entry->item.nap_listed) {
		LOG("%W", Nouns::nominative_singular(entry->item.nap_listed->as_noun));
	} else if (entry->item.action_listed == NULL)
		LOG("ANY");
	else {
		LOG("%W", ActionNameNames::tensed(entry->item.action_listed, IS_TENSE));
	}			
}

void ActionNameLists::write_entry_briefly(OUTPUT_STREAM, anl_entry *entry) {
	if (entry->item.nap_listed) {
		WRITE("%W", Nouns::nominative_singular(entry->item.nap_listed->as_noun));
	} else if (entry->item.action_listed == NULL)
		WRITE("ANY");
	else {
		WRITE("%W", ActionNameNames::tensed(entry->item.action_listed, IS_TENSE));
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

The test group |:actions| is helpful in catching errors here.

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
	doing something/anything other than <excluded-list> | ==> { pass 1 }
	doing something/anything except <excluded-list> |     ==> { pass 1 }
	doing something/anything to/with {...} |    ==> { -, - }; wording TW = WR[1]; @<Something to@>
	doing something/anything |                  ==> @<Something@>
	doing something/anything {...} |            ==> { -, - }; TW = WR[1]; @<Something in@>
	<anl>                                       ==> @<X@>

<excluded-list> ::=
	<anl> to/with {<minimal-common-to-text>} |  ==> @<Something except X with@>
	<anl>                                       ==> @<Something except X@>

<minimal-common-to-text> ::=
	_,/or ... |                                 ==> { fail }
	... to/with ... |                           ==> { fail }
	...

@<Something to@> =
	TW = GET_RW(<action-list>, 1);
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	ActionNameLists::add_noun(entry, TW);
	==> { TRUE, ActionNameLists::new_list(ActionNameLists::ramify(entry), ANL_POSITIVE) }

@<Something@> =
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	==> { TRUE, ActionNameLists::new_list(entry, ANL_POSITIVE) };

@<Something in@> =
	TW = GET_RW(<action-list>, 1);
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	ActionNameLists::set_clause_wording(entry, TAIL_AP_CLAUSE, TW);
	==> { TRUE, ActionNameLists::new_list(ActionNameLists::ramify(entry), ANL_POSITIVE) };

@<X@> =
	==> { TRUE, ActionNameLists::new_list(RP[1], ANL_POSITIVE) };

@<Something except X@> =
	==> { FALSE, ActionNameLists::new_list(RP[1], ANL_NEGATED_LISTWISE) };

@<Something except X with@> =
	anl_entry *entry = RP[1];
	if ((entry == NULL) ||
		(entry->item.action_listed == NULL) ||
		(ActionSemantics::can_have_noun(entry->item.action_listed) == FALSE)) {
		==> { fail production };
	}
	ActionNameLists::add_noun(entry, GET_RW(<excluded-list>, 1));
	==> { FALSE, ActionNameLists::new_list(ActionNameLists::ramify(entry), ANL_NEGATED_ITEMWISE) };

@ This matches a comma/or-separated list of items:

=
<anl> ::=
	<anl-entry> <anl-tail> |  ==> { -, ActionNameLists::join_entries(RP[1], RP[2]) }
	<anl-entry>               ==> { pass 1 }

<anl-tail> ::=
	, _or <anl> |             ==> { pass 1 }
	_,/or <anl>               ==> { pass 1 }

@ Items can be named action patterns, so let's get those out of the way first:

=
<anl-entry> ::=
	<named-action-pattern> |        ==> { -, ActionNameLists::nap_entry(RP[1], W, EMPTY_WORDING) }
	<named-action-pattern-tailed> | ==> { pass 1 }
	<anl-entry-with-action>         ==> { pass 1 }

<named-action-pattern-tailed> internal {
	for (int i=Wordings::first_wn(W); i<= Wordings::last_wn(W) - 1; i++) {
		if (<named-action-pattern>(Wordings::up_to(W, i))) {
			==> { -, ActionNameLists::nap_entry(<<rp>>, W, Wordings::from(W, i+1)) };
			return TRUE;
		}
	}
	return FALSE;
}

@ Here |TW| is the "tail wording", that is, any text left over after the name
itself. So, for "irreverent behaviour in the presence of the Bishop", the
|nap| may be the "irreverent behaviour", and |TW| the text "in the presence
of the Bishop". We put that temporarily into the |TAIL_AP_CLAUSE|, and then
ramify what had been a single-entry list so that it may now have multiple
entries -- for example, "irreverent behaviour [in: the presence of the Bishop]"
or "irreverent behaviour [in-presence: the Bishop]".

=
anl_entry *ActionNameLists::nap_entry(named_action_pattern *nap, wording W, wording TW) {
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	entry->item.nap_listed = nap;
	if (Wordings::nonempty(TW))
		ActionNameLists::set_clause_wording(entry, TAIL_AP_CLAUSE, TW);
	return ActionNameLists::ramify(entry);
}

@ If we aren't going to name an action pattern, we're going to have to spell
out an actual choice of action.

=
<anl-entry-with-action> internal {
	anl_entry *results = NULL;
	@<Parse the wording into a list of results@>;
	results = ActionNameLists::ramify(results);
	if (results) {
		==> { -, results }; return TRUE;
	}
	==> { fail nonterminal };
}

@ The following makes a list of results before ramification.

For example, for the text "looking or taking inventory in the presence of Hans
in the Laboratory", we get the following set of |results|:
= (text)
(1). +2 taking inventory [tail: in the presence of hans in the laboratory]
(2). +2 taking [noun: inventory in the presence of hans in the laboratory]
(3). +0 looking
=

@<Parse the wording into a list of results@> =
	anl_entry *trial_entry = ActionNameLists::new_entry_at(EMPTY_WORDING);
	action_name *an;
	LOOP_OVER(an, action_name) {
		@<Ready the trial entry for another test@>;
		wording RW = EMPTY_WORDING;
		int abbreviated_to_tail = FALSE;
		@<Make the trial entry fit this action, if possible, leaving remaining text in RW@>;
		@<Transfer remaining words to a trailing clause@>;
		@<Include the trial entry@>;
		NoMatch: ;
	}

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
	int w_m = Wordings::first_wn(W), x_m = Wordings::first_wn(XW), n = 0;
	while ((w_m <= Wordings::last_wn(W)) && (x_m <= Wordings::last_wn(XW))) {
		if (Lexer::word(x_m++) != Lexer::word(w_m++)) {
			if ((abbreviable) && (it_optional) && (n >= 1)) {
				x_ended = TRUE; abbreviated_to_tail = TRUE; x_m--; w_m--;
			} else goto NoMatch;
			break;
		}
		n++;
		if (x_m > Wordings::last_wn(XW)) { x_ended = TRUE; break; }
		if (<object-pronoun>(Wordings::one_word(x_m))) {
			if (w_m > Wordings::last_wn(W)) x_ended = TRUE; else {
				int j = -1, k;
				for (k=(it_optional)?(w_m):(w_m+1); k<=Wordings::last_wn(W); k++)
					if (Lexer::word(k) == Lexer::word(x_m+1)) { j = k; break; }
				if (j<0) goto NoMatch;
				if (j-1 >= w_m)
					ActionNameLists::add_noun(trial_entry, Wordings::new(w_m, j-1));
				else
					ActionNameLists::add_noun(trial_entry, EMPTY_WORDING);
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

@ For example, in "looking or taking inventory in the presence of Hans
in the Laboratory", after finding "taking inventory" as a possible action,
we are left with "in the presence of Hans in the Laboratory". These have to
be stored into |TAIL_AP_CLAUSE|, since they cannot be part of any noun --
because taking inventory doesn't have a noun. But when finding "taking",
the remaining words "inventory in the presence of Hans in the Laboratory"
have to go into |NOUN_AP_CLAUSE| -- the taking action does have a noun.

@<Transfer remaining words to a trailing clause@> =
	if (Wordings::nonempty(RW)) {
		if ((ActionSemantics::can_have_noun(an)) && (abbreviated_to_tail == FALSE)) {
			ActionNameLists::add_noun(trial_entry, RW);
		} else {
			ActionNameLists::set_clause_wording(trial_entry, TAIL_AP_CLAUSE, RW);
		}		
	}

@ So this is the happy ending. We don't copy the trial entry; we insertion-sort
the structure itself into the results list, and make a fresh structure to be
the trial entry for future trials.

@<Include the trial entry@> =
	results = ActionNameLists::join_entries(trial_entry, results);
	trial_entry = ActionNameLists::new_entry_at(EMPTY_WORDING);

@ And now we get to ramification. This is what happens last, when a set of
raw results has been produced. We "ramify" this by expanding it into multiple
readings according to how the trailing clause might in fact be made up of
sub-clauses. For example, our unramified set of results
= (text)
(1). +2 taking inventory [tail: in the presence of hans in the laboratory]
(2). +2 taking [noun: inventory in the presence of hans in the laboratory]
(3). +0 looking
=
becomes the ramified set
= (text)
(1). +2 taking inventory [in: the laboratory] [in-presence: hans]
(2). +2 taking inventory [in-presence: hans in the laboratory]
(3). +2 taking [noun: inventory] [in: the laboratory] [in-presence: hans]
(4). +2 taking [noun: inventory] [in-presence: hans in the laboratory]
(5). +2 taking [noun: inventory in the presence of hans] [in: the laboratory]
(6). +2 taking [noun: inventory in the presence of hans in the laboratory]
(7). +0 looking
=
Note that the |TAIL_AP_CLAUSE| clauses, which were just temporary holders
for leftover text, have gone entirely. Had it been impossible to break them
into legal subclauses, they would have caused the result to be struck out
altogether. For example, this:
= (text)
(1). +0 taking inventory [tail: book]
(2). +0 taking [noun: inventory book]
=
ramifies to just
= (text)
(1). +0 taking [noun: inventory book]
=
because the tail wording "book" after "taking inventory" cannot be read as
a sequence of subclauses.

Ramification thus consists of a sudden increase in the number of possible
readings, which we call an explosion, followed by a cull of anything which
still has a |TAIL_AP_CLAUSE|.

=
anl_entry *ActionNameLists::ramify(anl_entry *results) {
	for (anl_entry *entry = results; entry; ) {
		anl_entry *next = entry->next_entry;
		ActionNameLists::explode(entry);
		entry = next;
	}
	for (anl_entry *prev = NULL, *entry = results; entry; entry = entry->next_entry)
		if (Wordings::nonempty(ActionNameLists::get_clause_wording(entry, TAIL_AP_CLAUSE))) {
			if (prev) prev->next_entry = entry->next_entry;
			else results = entry->next_entry;
		} else {
			prev = entry;
		}
	return results;
}

@ And here is the explosion part. |tc| here identifies what the trailing clause
actually is:

=
void ActionNameLists::explode(anl_entry *entry) {
	int tc = -1;
	if (ActionNameLists::has_clause(entry, TAIL_AP_CLAUSE)) tc = TAIL_AP_CLAUSE;
	else if (ActionNameLists::has_clause(entry, SECOND_AP_CLAUSE)) tc = SECOND_AP_CLAUSE;
	else if (ActionNameLists::has_clause(entry, NOUN_AP_CLAUSE)) tc = NOUN_AP_CLAUSE;
	else return;
	wording TW = ActionNameLists::get_clause_wording(entry, tc);
	ActionNameLists::explode_clause(entry, tc, Wordings::first_wn(TW));
}

@ The following is recursive and exhausts all possible readings of the trailing
clause, exactly once each. We have to store what ought to be variables on the
stack as globals because of the little dance via Preform nonterminals below,
but the idea is simple enough. This function finds the first point at which
the reading diverges: for example, if the text is "banjo in the Conservatoire",
then "in" is the point of divergence. Maybe the text is all one clause, or
maybe it's just "banjo" and there is then a second clause "in the Conservatoire".

=
anl_entry *currently_exploding_entry = NULL;
int currently_exploding_clause = -1;
int explosions_count = 0;
void ActionNameLists::explode_clause(anl_entry *entry, int tc, int from_wn) {
	anl_entry *saved = currently_exploding_entry;
	int saved_C = currently_exploding_clause;
	currently_exploding_entry = entry;
	currently_exploding_clause = tc;
	wording TW = ActionNameLists::get_clause_wording(entry, tc);
	explosions_count++;
	int start = explosions_count;
	LOG_INDENT;
	for (int w = from_wn; ((w < Wordings::last_wn(TW)) && (start == explosions_count)); w++) {
		if (<text-precluding-divergence>(Wordings::one_word(w))) { w++; continue; }
		<detonate-at-divergence-points>(Wordings::from(TW, w));
	}
	LOG_OUTDENT;
	currently_exploding_entry = saved;
	currently_exploding_clause = saved_C;
}
	
@ Note that if we spot the <text-precluding-divergence> wording immediately before
the point of divergence, we forbid divergence to occur. It must contain only
single words.

This actually matters surprisingly rarely, but enables us to handle quite
difficult cases like "Instead of buying the cheapest spice which is in the market"
without typechecking errors occurring on the unwanted case of reading this as
"Instead of buying the cheapest spice which is" plus the clause "in the market" --
the latter being, in fact, valid.

=
<text-precluding-divergence> ::=
	is |
	not

@ Divergence points, then, must not unexpectedly use upper case -- so "taking
Puss In Boots" is never read as possibly having an "in: Boots" clause; and
they either use the two standard wordings "in the presence of" or "in". or
else wording provided by a matching variable in an action declaration.

Note that this nonterminal never matches! It is parsed for its side-effect
of calling //ActionNameLists::detonate// on every possibility.

=
<detonate-at-divergence-points> ::=
	_in _the _presence _of ... |  ==> @<Explode in-presence@>
	_in ... |                     ==> @<Explode in@>
	<clause-opening> ...

@<Explode in@> =
	wording T = GET_RW(<detonate-at-divergence-points>, 1);
	ActionNameLists::detonate(IN_AP_CLAUSE, NULL, T, W);
	return FALSE;

@<Explode in-presence@> =
	wording T = GET_RW(<detonate-at-divergence-points>, 1);
	ActionNameLists::detonate(IN_THE_PRESENCE_OF_AP_CLAUSE, NULL, T, W);
	return FALSE;

@ For example, in the text "going from the Park to the Town", "from" and "to"
are divergence points:

=
<clause-opening> internal ? {
	if (Word::unexpectedly_upper_case(Wordings::first_wn(W)) == FALSE) {
		action_name *chief_an = currently_exploding_entry->item.action_listed;
		if (chief_an) {
			shared_variable_set *stvo = chief_an->action_variables;
			if (stvo) {
				shared_variable *stv;
				LOOP_OVER_LINKED_LIST(stv, shared_variable, stvo->variables) {
					wording VW = stv->match_wording_text;
					if (Wordings::starts_with(W, VW)) {
						wording T = Wordings::from(W, Wordings::first_wn(W) + Wordings::length(VW));
						int potential_C = APClauses::clause_ID_for_action_variable(stv);
						ActionNameLists::detonate(potential_C, stv, T, W);
					}
				}
			}
		}
	}
	==> { fail nonterminal };
}

@ Finally the actual business of splitting our original entry into two, one
(called |X| here) in which a new clause appears at the point of divergence,
and one (called |Y|) where it does not.

The order is important here because this is why when there are multiple
readings of clauses in the ramified list, the readings with more clauses
come before the readings with fewer.

Note that we only diverge if the new clause is one which does not already
exist for this entry. This is because it makes no sense to have the same
clause twice, and also means that pathological text like "in in in in in
in in in in in in in in in in in in in in in in in in in in in in in in in"
cannot cause a combinatorial nightmare; because each clause appears at
most once in any entry, the number of entries produced by ramification is
capped at $2^n$, where $n$ is the number of different clauses whose matching
words appear somewhere in the text. As Inform ships with only seven different
clauses anyway, this will never be too bad.

=
void ActionNameLists::detonate(int potential_C, shared_variable *stv, wording T, wording W) {
	if (ActionNameLists::has_clause(currently_exploding_entry, potential_C) == FALSE) {
		anl_entry *extra = ActionNameLists::duplicate_entry(currently_exploding_entry);

		anl_entry *Y = extra, *X = currently_exploding_entry;
		ActionNameLists::set_clause_wording(X, potential_C, T);
		anl_clause *extra_clause = ActionNameLists::get_clause(X, potential_C);
		extra_clause->stv_to_match = stv;
		ActionNameLists::truncate_clause(X, currently_exploding_clause, Wordings::first_wn(W));

		anl_entry *n = currently_exploding_entry->next_entry;
		currently_exploding_entry->next_entry = extra;
		extra->next_entry = n;
		ActionNameLists::explode_clause(Y, currently_exploding_clause, Wordings::first_wn(W)+1);
		ActionNameLists::explode_clause(X, potential_C, Wordings::first_wn(T)+1);
	}
}

@ Lastly, this little function is provided for unit testing the above, and
is otherwise never called.

=
void ActionNameLists::test_list(wording W) {
	LOG("Action name list for: %W\n", W);
	action_name_list *anl = ActionNameLists::parse(W, IS_TENSE, NULL);
	LOG("$L\n", anl);
}
