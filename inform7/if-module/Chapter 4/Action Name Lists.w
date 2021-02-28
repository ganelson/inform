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
} action_name_list;

action_name_list *ActionNameLists::new_list(anl_entry *first, int state) {
	action_name_list *list = CREATE(action_name_list);
	list->entries = first;
	list->negation_state = state;
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

@ An entry has some book-keeping fields, and is otherwise divided into the
item itself -- either an action name or a named action pattern -- and some
parsing data needed by the complicated algorithms for turning text into an
action list.

=
typedef struct anl_entry {
	struct anl_item item;
	struct anl_parsing_data parsing_data;
	int marked_for_deletion;
	struct anl_entry *next_link; /* next in this ANL list */
} anl_entry;

anl_entry *ActionNameLists::new_entry_at(int at) {
	anl_entry *new_anl = CREATE(anl_entry);
	new_anl->item = ActionNameLists::new_item();
	new_anl->parsing_data = ActionNameLists::new_parsing_data(at);
	new_anl->marked_for_deletion = FALSE;
	return new_anl;
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
		for (anl_entry *entry = list->entries, *prev = NULL; entry; entry = entry->next_link) {
			if ((entry->marked_for_deletion) || (pos == entry->parsing_data.word_position)) {
				if (prev == NULL) list->entries = entry->next_link;
				else prev->next_link = entry->next_link;
			} else {
				prev = entry;
				pos = entry->parsing_data.word_position;
			}
		}
	}
}

@ When not pruning the list, these macros are useful for working through it:

@d LOOP_THROUGH_ANL(var, list)
	for (anl_entry *var = (list)?(list->entries):NULL; var; var = var->next_link)

@d LOOP_THROUGH_ANL_WITH_PREV(var, prev_var, next_var, list)
	for (anl_entry *var = (list)?(list->entries):NULL,
		*prev_var = NULL, *next_var = (var)?(var->next_link):NULL;
		var;
		prev_var = var, var = next_var, next_var = (next_var)?(next_var->next_link):NULL)

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

@ The //anl_item// material is the actual content we are trying to get at:

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

int ActionNameLists::parc(anl_entry *entry) {
	if (entry) return entry->parsing_data.parc;
	return 0;
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

wording ActionNameLists::par(anl_entry *entry, int i) {
	if ((entry) && (entry->parsing_data.parc > i)) return entry->parsing_data.parameter[i];
	return EMPTY_WORDING;
}

wording ActionNameLists::in_clause(anl_entry *entry) {
	if (entry) return entry->parsing_data.in_clause;
	return EMPTY_WORDING;
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
	LOGIF(RULE_ATTACHMENTS, "Getting single action from:\n$L\n", list);
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
	LOGIF(RULE_ATTACHMENTS, "Posn %d AN $l\n", posn, best);
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

=
anl_entry *anl_being_parsed = NULL;

@ The following handles action name lists, such as:

>> doing something other than waiting
>> taking or dropping the box

At this stage in parsing, we are identifying possible actions, and
what their possible operands are, but we aren't trying to parse those
operands.

=
<action-list> ::=
	doing something/anything other than <anl-excluded> |  ==> { FALSE, RP[1] }
	doing something/anything except <anl-excluded> |      ==> { FALSE, RP[1] }
	doing something/anything to/with <anl-to-tail> |      ==> { TRUE, ActionNameLists::new_list(RP[1], ANL_POSITIVE) }
	doing something/anything |                            ==> @<Construct ANL for anything@>
	doing something/anything ... |                        ==> { fail }
	<anl>                                                 ==> { TRUE, ActionNameLists::new_list(RP[1], ANL_POSITIVE) }

<anl-excluded> ::=
	<anl> to/with {<anl-minimal-common-operand>} |        ==> @<Add to-clause to excluded ANL@>;
	<anl>                                                 ==> { TRUE, ActionNameLists::new_list(RP[1], ANL_NEGATED_LISTWISE) }

<anl-minimal-common-operand> ::=
	_,/or ... |                                           ==> { fail }
	... to/with ... |                                     ==> { fail }
	...

@<Construct ANL for anything@> =
	anl_entry *anl = ActionNameLists::new_entry_at(Wordings::first_wn(W));
	==> { TRUE, ActionNameLists::new_list(anl, ANL_POSITIVE) };

@ The trickiest form is:

>> doing something to the box in the dining room

where no explicit action occurs at all, but we have to parse the rest of
the text as if it does, including an "in" clause.

So the following finds the first "in" within its range of words, except that
it throws out an "in" that we consider bogus for our own syntactic purposes:
for instance, we don't want to count the "in" from "fixed in place".

=
<anl-to-tail> ::=
	<anl-operand> <anl-in-tail> |  ==> @<Augment ANL with in clause@>
	<anl-operand>                  ==> { pass 1 }

<anl-operand> ::=
	...                            ==> @<Construct ANL for anything applied@>

<anl-in-tail> ::=
	fixed in place *** |                  ==> { advance Wordings::delta(WR[1], W) }
	is/are/was/were/been/listed in *** |  ==> { advance Wordings::delta(WR[1], W) }
	in ...                                ==> { TRUE, - }

@<Augment ANL with in clause@> =
	anl_entry *anl = RP[1];
	anl->parsing_data.in_clause = GET_RW(<anl-in-tail>, 1);

@<Construct ANL for anything applied@> =
	anl_entry *new_anl;
	if ((!preform_lookahead_mode) && (anl_being_parsed)) new_anl = anl_being_parsed;
	else new_anl = ActionNameLists::new_entry_at(Wordings::first_wn(W));
	new_anl->parsing_data.parameter[new_anl->parsing_data.parc] = W;
	new_anl->parsing_data.parc++;
	==> { TRUE, new_anl };

@ Now for the basic list of actions being included:

=
<anl> ::=
	<anl-entry> <anl-tail> |  ==> @<Join parsed ANLs@>
	<anl-entry>               ==> { pass 1 }

<anl-tail> ::=
	, _or <anl> |             ==> { pass 1 }
	_,/or <anl>               ==> { pass 1 }

@ Which reduces us to an internal nonterminal for an entry in this list.
It actually produces multiple matches: for example,

>> taking inventory

will result in a list of two possibilities -- "taking inventory", the
action, with no operand; and "taking", the action, applied to the
operand "inventory". (It's unlikely that the last will succeed in the
end, but it's syntactically valid.)

=
<anl-entry> ::=
	<named-action-pattern>	|               ==> @<Make an action pattern from named behaviour@>
	<named-action-pattern> <anl-in-tail> |  ==> @<Make an action pattern from named behaviour plus in@>
	<anl-entry-with-action>					==> { pass 1 }

<named-action-pattern> internal {
	named_action_pattern *nap = NamedActionPatterns::by_name(W);
	if (nap) {
		==> { -, nap }; return TRUE;
	}
	==> { fail nonterminal };
}

<anl-entry-with-action> internal {
	anl_entry *anl = ActionNameLists::anl_parse_internal(W);
	if (anl) {
		==> { -, anl }; return TRUE;
	}
	==> { fail nonterminal };
}

@<Make an action pattern from named behaviour@> =
	anl_entry *new_anl = ActionNameLists::new_entry_at(Wordings::first_wn(W));
	new_anl->item.nap_listed = RP[1];
	==> { 0, new_anl };

@<Make an action pattern from named behaviour plus in@> =
	anl_entry *new_anl = ActionNameLists::new_entry_at(Wordings::first_wn(W));
	new_anl->item.nap_listed = RP[1];
	new_anl->parsing_data.in_clause = GET_RW(<anl-in-tail>, 1);
	==> { 0, new_anl };

@<Add to-clause to excluded ANL@> =
	anl_entry *anl = RP[1];
	if ((anl == NULL) ||
		(ActionSemantics::can_have_noun(anl->item.action_listed) == FALSE)) {
		==> { fail production };
	}
	anl->parsing_data.parameter[anl->parsing_data.parc] = GET_RW(<anl-excluded>, 1);
	anl->parsing_data.parc++;
	action_name_list *list = ActionNameLists::new_list(anl, ANL_NEGATED_ITEMWISE);
	==> { FALSE, list };

@<Join parsed ANLs@> =
	anl_entry *join;
	anl_entry *left_atom = RP[1];
	anl_entry *right_tail = RP[2];
	if (left_atom == NULL) { join = right_tail; }
	else if (right_tail == NULL) { join = left_atom; }
	else {
		anl_entry *new_anl = right_tail;
		while (new_anl->next_link != NULL) new_anl = new_anl->next_link;
		new_anl->next_link = left_atom;
		join = right_tail;
	}
	==> { 0, join };

@ =
int anl_parsing_tense = IS_TENSE;
action_name_list *ActionNameLists::parse(wording W, int tense) {
	if (Wordings::mismatched_brackets(W)) return NULL;
	int t = anl_parsing_tense;
	anl_parsing_tense = tense;
	int r = <action-list>(W);
	anl_parsing_tense = t;
	if (r) return <<rp>>;
	return NULL;
}

@ =
anl_entry *ActionNameLists::anl_parse_internal(wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Parsing ANL from %W (tense %d)\n", W, anl_parsing_tense);

	int tense = anl_parsing_tense;
	anl_entry *anl_list = NULL, *new_anl = NULL;

	action_name *an;
	new_anl = ActionNameLists::new_entry_at(-1);

	LOOP_OVER(an, action_name) {
		int x_ended = FALSE;
		int fc = 0;
		int it_optional = ActionNameNames::it_optional(an);
		int abbreviable = ActionNameNames::abbreviable(an);
		wording XW = ActionNameNames::tensed(an, tense);
		new_anl->item.action_listed = an;
		new_anl->parsing_data.parc = 0;
		new_anl->parsing_data.word_position = Wordings::first_wn(W);
		new_anl->parsing_data.in_clause = EMPTY_WORDING;
		int w_m = Wordings::first_wn(W), x_m = Wordings::first_wn(XW);
		while ((w_m <= Wordings::last_wn(W)) && (x_m <= Wordings::last_wn(XW))) {
			if (Lexer::word(x_m++) != Lexer::word(w_m++)) {
				fc=1; goto DontInclude;
			}
			if (x_m > Wordings::last_wn(XW)) { x_ended = TRUE; break; }
			if (<object-pronoun>(Wordings::one_word(x_m))) {
				if (w_m > Wordings::last_wn(W)) x_ended = TRUE; else {
					int j = -1, k;
					for (k=(it_optional)?(w_m):(w_m+1); k<=Wordings::last_wn(W); k++)
						if (Lexer::word(k) == Lexer::word(x_m+1)) { j = k; break; }
					if (j<0) { fc=2; goto DontInclude; }
					if (j-1 >= w_m) {
						new_anl->parsing_data.parameter[new_anl->parsing_data.parc] = Wordings::new(w_m, j-1);
						new_anl->parsing_data.parc++;
					} else {
						new_anl->parsing_data.parameter[new_anl->parsing_data.parc] = EMPTY_WORDING;
						new_anl->parsing_data.parc++;
					}
					w_m = j; x_m++;
				}
			}
			if (x_ended) break;
		}
		if ((w_m > Wordings::last_wn(W)) && (x_ended == FALSE)) {
			if (abbreviable) x_ended = TRUE;
			else { fc=3; goto DontInclude; }
		}
		if (x_m <= Wordings::last_wn(XW)) new_anl->parsing_data.abbreviation_level = Wordings::last_wn(XW)-x_m+1;

		int inc = FALSE;
		if (w_m > Wordings::last_wn(W)) inc = TRUE;
		else if (<anl-in-tail>(Wordings::from(W, w_m))) {
			new_anl->parsing_data.in_clause = GET_RW(<anl-in-tail>, 1);
			inc = TRUE;
		} else if (ActionSemantics::can_have_noun(an)) {
			anl_being_parsed = new_anl;
			if (<anl-to-tail>(Wordings::from(W, w_m))) {
				inc = TRUE;
			}
			anl_being_parsed = NULL;
		}
		new_anl->next_link = NULL;
		if (inc) {
			if (anl_list == NULL) anl_list = new_anl;
			else {
				anl_entry *pos = anl_list, *prev = NULL;
				while ((pos) && (pos->parsing_data.abbreviation_level < new_anl->parsing_data.abbreviation_level))
					prev = pos, pos = pos->next_link;
				if (prev) prev->next_link = new_anl; else anl_list = new_anl;
				new_anl->next_link = pos;
			}
		}
		new_anl = ActionNameLists::new_entry_at(-1);
		DontInclude: ;
	}
	LOGIF(ACTION_PATTERN_PARSING, "Parsing ANL from %W resulted in:\n$8\n", W, anl_list);
	return anl_list;
}
