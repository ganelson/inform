[BookingLists::] Booking Lists.

Booking lists are linked lists of rule bookings. The content of a rulebook
is a booking list.

@h Introduction.
Bookings are intended to be bound together in linked lists, each of which
represents the interior pages of a single rulebook.

=
typedef struct booking_list {
	struct booking *list_head; /* the dummy entry at the front */
	CLASS_DEFINITION
} booking_list;

@ There are only three operations on lists: creation, addition of a booking,
and removal of a booking. The following invariants are preserved:

(a) The list head is a dummy, i.e., meaningless, booking which has never been
the subject of any addition operation and has never moved.

(b) The only |FIRST_PLACEMENT| entries in the list immediately follow the list
head. Those which were added explicitly as first-placed are in reverse order
of addition to the list.

(c) The only |LAST_PLACEMENT| entries in the list are at the end. Those which
were added explicitly as last-placed are in order of addition to the list.

(d) If R and S are middle-placed rules which were placed in the list within
the same range (say, both anywhere, or both "after T" or "before U") and R
precedes S, then either R is more specific than S, or they are equally specific
and R was added to the list before S.

(e) The list never contains duplicates, that is, never contains two bookings
whose rules are equal, in the sense of //Rules::eq//.

@ These macros are useful for iterating through the contents in sequence;
note that |br| is never equal to the dummy head, and that |pr| is never |NULL| --
though it is initially equal to the dummy, which of course is the point of
having the dummy.

@d LOOP_OVER_BOOKINGS(br, L)
	for (booking *br=(L)?(L->list_head->next_booking):NULL; br; br=br->next_booking)
@d LOOP_OVER_BOOKINGS_WITH_PREV(br, pr, L)
	for (booking *br = L->list_head->next_booking, *pr = L->list_head; br;
		pr = br, br = br->next_booking)

=
void BookingLists::log(booking_list *L) {
	if (L == NULL) { LOG("<null-booked-rule-list>\n"); return; }
	int t = BookingLists::length(L);
	if (t == 0) { LOG("<empty-booked-rule-list>\n"); return; }
	int s = 1;
	LOOP_OVER_BOOKINGS(br, L)
		LOG("  %d/%d. $b\n", s++, t, br);
}

@h Creation.
A new list is a dummy header (see (a) above):

=
booking_list *BookingLists::new(void) {
	booking_list *L = CREATE(booking_list);
	L->list_head = RuleBookings::new(NULL);
	return L;
}

@h Addition.
The following is called when a booking |br| for the rule R needs to be placed 
into list |L|, which is the contents of a rulebook we will call B. This happens,
for example, in response to an an assertion like "R is listed after S in B";
in that cast the |side| would be |AFTER_SIDE|, and the |ref_rule| would be S.

It is also possible to specify a |placing|. For example, for a rule described
as "First every turn rule: ...", this would be added to the every turn rulebook
with placing |FIRST_PLACEMENT|. There are three possible placings: see //booking//
for what they are.

And since there are four possible sides, the following function effectively has
12 different modes to get right.

Each "addition" leaves the list either the same size or longer by 1.

@d BEFORE_SIDE -1 /* before the reference rule */
@d IN_SIDE 0      /* if no mention is made of where to put the new booking */
@d AFTER_SIDE 1   /* after the reference rule */
@d INSTEAD_SIDE 2 /* in place of the reference rule */

=
void BookingLists::add(booking_list *L, booking *new_br,
	int placing, int side, rule *ref_rule) {
	@<Make some sanity checks on the addition instructions@>;
	@<Handle the case where the new rule is already in the list@>;
	@<Handle all placements made with the INSTEAD side@>;
	@<Handle any VERY FIRST placement@>;
	@<Handle all placements made with the FIRST placement@>;
	@<Handle all placements made with the LAST placement@>;
	@<Handle any VERY LAST placement@>;
	@<Handle what's left: MIDDLE placements on the IN, BEFORE or AFTER sides@>;
}

@<Make some sanity checks on the addition instructions@> =
	if ((side != IN_SIDE) && (ref_rule == NULL))
		internal_error("tried to add before or after or instead of non-rule");
	if ((side == IN_SIDE) && (ref_rule != NULL))
		internal_error("tried to add in middle but with ref rule");
	if ((side != IN_SIDE) && (placing != MIDDLE_PLACEMENT))
		internal_error("tried to add before or after but with non-middle placement");
	if (L == NULL)
		internal_error("tried to add rule to null list");
	switch(placing) {
		case MIDDLE_PLACEMENT: break;
		case VERY_FIRST_PLACEMENT: LOGIF(RULE_ATTACHMENTS, "Placed very first\n"); break;
		case FIRST_PLACEMENT: LOGIF(RULE_ATTACHMENTS, "Placed first\n"); break;
		case LAST_PLACEMENT: LOGIF(RULE_ATTACHMENTS, "Placed last\n"); break;
		case VERY_LAST_PLACEMENT: LOGIF(RULE_ATTACHMENTS, "Placed very last\n"); break;
		default: internal_error("invalid placing of rule");
	}

@ If R is already in B, the assertion may still have an effect.

If our instructions specify no particular position for R to take, we return
because nothing need be done: the rule's there already, so be happy. Otherwise,
we remove R's existing booking in order that it can be rebooked in a new position.

This is a change in semantics from the original Inform 7 design for rulebooks,
under which a rule could be booked multiple times in the same rulebook -- which
was then called "duplication". Following debate on the Usenet newsgroup
|rec.arts.int-fiction| in February and March 2009, it was decided to abolish
duplication in favour of the clean principle that a rule can only be in a
single rulebook once. This makes it easier to place rules with tricky preambles,
though there were arguments on both sides.

@<Handle the case where the new rule is already in the list@> =
	LOOP_OVER_BOOKINGS_WITH_PREV(pos, prev, L)
		if (Rules::eq(RuleBookings::get_rule(pos), RuleBookings::get_rule(new_br))) {
			if ((side == IN_SIDE) && (placing == MIDDLE_PLACEMENT)) return;
			prev->next_booking = pos->next_booking;
			pos->next_booking = NULL;
			LOGIF(RULE_ATTACHMENTS, "Removing previous entry from rulebook\n");
			break; /* rule can only appear once, so no need to keep checking */
		}

@<Handle all placements made with the INSTEAD side@> =
	if (side == INSTEAD_SIDE) {
		LOOP_OVER_BOOKINGS_WITH_PREV(pos, prev, L)
			if (Rules::eq(RuleBookings::get_rule(pos), ref_rule)) {
				if ((pos->placement == VERY_FIRST_PLACEMENT) ||
					(pos->placement == VERY_LAST_PLACEMENT)) {
					StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InsteadOfVeryFirst),
						"'very first' or 'very last' rules cannot be replaced with 'instead'",
						"since this allows the creator of the rulebook to be certain "
						"that they will always be in place.");
				} else {
					new_br->placement = pos->placement; /* replace with same placement */
					new_br->next_booking = pos->next_booking;
					prev->next_booking = new_br;
				}
			}
		return;
	}

@<Handle any VERY FIRST placement@> =
	if (placing == VERY_FIRST_PLACEMENT) {
		booking *previously_first = L->list_head->next_booking;
		if ((previously_first) && (previously_first->placement == VERY_FIRST_PLACEMENT))
			@<Throw PM_OnlyOneVeryFirst problem@>;
		L->list_head->next_booking = new_br;
		new_br->next_booking = previously_first; /* pushes any existing rules forward */
		new_br->placement = placing;
		return;
	}

@<Throw PM_OnlyOneVeryFirst problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OnlyOneVeryFirst),
		"only one 'very first' or 'very last' rule can exist in a rulebook",
		"unlike the situation with mere 'first' or 'last' rules.");

@ If we insert a rule as first-placed rule when there already is a first-placed
rule, the new one displaces it to go first, but both continue to be labelled as
having |FIRST_PLACEMENT|, so that subsequent rule insertions of middle-placed rules
will still go after both of them. If there's a very first rule, there's just one,
and it sits right at the front; mere first rules won't displace it.

@<Handle all placements made with the FIRST placement@> =
	if (placing == FIRST_PLACEMENT) { /* first in valid interval (must be whole list) */
		booking *previously_first = L->list_head->next_booking;
		if ((previously_first) && (previously_first->placement == VERY_FIRST_PLACEMENT)) {
			new_br->next_booking = previously_first->next_booking; /* slot in after VF rule */
			previously_first->next_booking = new_br;
			new_br->placement = placing;
		} else {
			L->list_head->next_booking = new_br;
			new_br->next_booking = previously_first; /* pushes any existing first rule forward */
			new_br->placement = placing;
		}
		return;
	}

@ Symmetrically, a second last-placed rule is inserted after any existing one, but
both are labelled as having |LAST_PLACEMENT|. But we cannot go past the very
last rule, if there is one.

@<Handle all placements made with the LAST placement@> =
	if (placing == LAST_PLACEMENT) { /* last in valid interval (must be whole list) */
		booking *prev = L->list_head;
		while ((prev->next_booking) && (prev->next_booking->placement != VERY_LAST_PLACEMENT))
			prev = prev->next_booking;
		new_br->next_booking = prev->next_booking;
		prev->next_booking = new_br; /* pushes any existing last rule backward */
		new_br->placement = placing;
		return;
	}

@<Handle any VERY LAST placement@> =
	if (placing == VERY_LAST_PLACEMENT) {
		booking *prev = L->list_head;
		while (prev->next_booking != NULL) prev = prev->next_booking;
		if (prev->placement == VERY_LAST_PLACEMENT)
			@<Throw PM_OnlyOneVeryFirst problem@>;
		prev->next_booking = new_br; /* pushes any existing last rule backward */
		new_br->next_booking = NULL;
		new_br->placement = placing;
		return;
	}

@<Handle what's left: MIDDLE placements on the IN, BEFORE or AFTER sides@> =
	booking *start_rule = L->list_head; /* valid interval begins after this rule */
	booking *end_rule = NULL; /* valid interval ends before this rule, or runs to end if |NULL| */
	@<Adjust the valid interval to take care of BEFORE and AFTER side requirements@>;
	@<Check that the valid interval is indeed as advertised@>;
	booking *insert_after = start_rule; /* insertion point is after this */
	@<Find insertion point, keeping the valid interval in specificity order@>;
	booking *subseq = insert_after->next_booking;
	insert_after->next_booking = new_br;
	new_br->next_booking = subseq;
	@<Set the placement for the new rule booking@>;

@<Adjust the valid interval to take care of BEFORE and AFTER side requirements@> =
	switch(side) {
		case BEFORE_SIDE:
			LOOP_OVER_BOOKINGS(pos, L)
				if (Rules::eq(RuleBookings::get_rule(pos), ref_rule))
					end_rule = pos; /* insert before: so valid interval ends here */
			if (end_rule == NULL) internal_error("can't find end rule");
			break;
		case AFTER_SIDE:
			LOOP_OVER_BOOKINGS(pos, L)
				if (Rules::eq(RuleBookings::get_rule(pos), ref_rule))
					start_rule = pos; /* insert after: so valid interval begins here */
			if (start_rule == L->list_head) internal_error("can't find start rule");
			break;
	}

@<Check that the valid interval is indeed as advertised@> =
	int i = 0, t = 2;
	if (end_rule == NULL) t = 1;
	booking *pos;
	for (pos = L->list_head; pos; pos = pos->next_booking) {
		if ((pos == start_rule) && (i == 0)) i = 1;
		if ((pos == end_rule) && (i == 1)) i = 2;
	}
	if (i != t) internal_error("valid rule interval isn't");

@<Find insertion point, keeping the valid interval in specificity order@> =
	int log = FALSE; if (Log::aspect_switched_on(SPECIFICITIES_DA)) log = TRUE;

	/* move forward to final valid first rule (if any exist) */
	while ((insert_after->next_booking != end_rule)
		&& ((insert_after->next_booking->placement == VERY_FIRST_PLACEMENT) ||
			(insert_after->next_booking->placement == FIRST_PLACEMENT)))
		insert_after = insert_after->next_booking;

	/* move forward past other middle rules if they are not less specific */
	while ((insert_after->next_booking != end_rule) /* stop before $p$ leaves valid range */
		&& (insert_after->next_booking->placement != LAST_PLACEMENT) /* or reaches a last rule */
		&& (insert_after->next_booking->placement != VERY_LAST_PLACEMENT) /* or a very last rule */
		&& (RuleBookings::cmp(insert_after->next_booking, new_br,
			log) >= 0)) /* or a rule less specific than the new one */
		insert_after = insert_after->next_booking;

@ Since this part of the algorithm is used only when we've requested MIDDLE
placement, it might seem that |new_br->placement| should always be set to
that. This does indeed mostly happen, but not always. To preserve rulebook
invariants (b) and (c), we need to force anything added after a LAST rule
to be LAST as well, and similarly for FIRSTs. (This will only happen in
cases where the source text called for placements AFTER a LAST rule, or
BEFORE a FIRST one.)

@<Set the placement for the new rule booking@> =
	new_br->placement = MIDDLE_PLACEMENT;
	if ((insert_after != L->list_head) &&
		(insert_after->placement == LAST_PLACEMENT))
		new_br->placement =
			LAST_PLACEMENT; /* happens if valid interval is after a last rule */

	if ((subseq) &&
		(subseq->placement == FIRST_PLACEMENT))
		new_br->placement =
			FIRST_PLACEMENT; /* happens if valid interval is before a first rule */

@h Removal.
This is much simpler, since it doesn't disturb the ordering:

=
void BookingLists::remove(booking_list *L, rule *R) {
	LOOP_OVER_BOOKINGS_WITH_PREV(br, pr, L)
		if (Rules::eq(RuleBookings::get_rule(br), R)) {
			if ((br->placement == VERY_FIRST_PLACEMENT) ||
				(br->placement == VERY_LAST_PLACEMENT)) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RemovedVeryFirst),
					"'very first' or 'very last' rules cannot be removed by 'not listed in'",
					"since this allows the creator of the rulebook to be certain "
					"that they will always be in place.");
			}				
			pr->next_booking = br->next_booking;
			return;
		}
}

@h Scanning lists for their contents.

=
int BookingLists::length(booking_list *L) {
	int n = 0;
	LOOP_OVER_BOOKINGS(br, L) n++;
	return n;
}

booking *BookingLists::first(booking_list *L) {
	LOOP_OVER_BOOKINGS(br, L) return br;
	return NULL;
}

int BookingLists::is_empty_of_i7_rules(booking_list *L) {
	LOOP_OVER_BOOKINGS(br, L)
		if (Rules::get_imperative_definition(RuleBookings::get_rule(br)))
			return FALSE;
	return TRUE;
}

int BookingLists::contains(booking_list *L, rule *to_find) {
	LOOP_OVER_BOOKINGS(br, L)
		if (Rules::eq(RuleBookings::get_rule(br), to_find))
			return TRUE;
	return FALSE;
}

int BookingLists::contains_ph(booking_list *L, id_body *idb_to_find) {
	LOOP_OVER_BOOKINGS(br, L) {
		imperative_defn *id = Rules::get_imperative_definition(RuleBookings::get_rule(br));
		if ((id) && (id->body_of_defn == idb_to_find))
			return TRUE;
	}
	return FALSE;
}
