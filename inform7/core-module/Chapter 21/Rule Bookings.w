[Rules::Bookings::] Rule Bookings.

Bookings are assignments of rules to rulebooks. We can think of
them as being looseleaf pages, of which we have an unlimited supply: any
rule can be written on them, and they can be bound into any rulebook at
any specified position.

@h Definitions.

@ Bookings are simple structures. They record which rule is to appear, and
whether it's to appear at the front, middle, or back of the rulebook:

=
typedef struct booking {
	struct booking *next_rule; /* in the linked list of pages for the rulebook */

	struct rule *rule_being_booked; /* what appears on this page */
	int placement; /* one of three placement values: see below */
	int automatic_placement; /* should this be inserted automatically? */

	/* used only to show how the page was added to its rulebook, for the index: */
	int next_rule_specificity; /* $1$ more specific than following, $0$ equal, $-1$ less */
	char *next_rule_specificity_law; /* description of reason */
	char *next_rule_specificity_lawname; /* name of Law used to sort */

	MEMORY_MANAGEMENT
} booking;

@ When bookings are gathered into linked lists, they are positioned using
"placements". Ordinarily they go somewhere in the middle, but
declarations are allowed to specify that they must occur at the front or
back, e.g.:

>> The first reaching inside rule: ...

The |placement| field is therefore always one of the following three values:

@d MIDDLE_PLACEMENT 0 /* most rules are somewhere in the middle */
@d FIRST_PLACEMENT 1
@d LAST_PLACEMENT 2

@h Creation.

=
booking *Rules::Bookings::new(rule *R) {
	booking *br = CREATE(booking);
	br->next_rule = NULL;

	br->rule_being_booked = R;
	br->placement = MIDDLE_PLACEMENT;
	br->automatic_placement = FALSE;

	br->next_rule_specificity = 0;
	br->next_rule_specificity_law = NULL;
	br->next_rule_specificity_lawname = NULL;
	return br;
}

@ Here's a rather arcane notation used in the debugging log:

=
void Rules::Bookings::log(booking *br) {
	if (br == NULL) { LOG("BR:<null-booked-rule>"); return; }
	LOG("BR%d", br->allocation_id);
	switch (br->placement) {
		case MIDDLE_PLACEMENT: LOG("m"); break;
		case FIRST_PLACEMENT: LOG("f"); break;
		case LAST_PLACEMENT: LOG("l"); break;
		default: LOG("?"); break;
	}
	Rules::log(br->rule_being_booked);
}

@ And this is the only externally useful information in a booking:

=
rule *Rules::Bookings::get_rule(booking *br) {
	if (br == NULL) return NULL;
	return br->rule_being_booked;
}

@h Automatic placement into rulebooks.
Some bookings result from explicit sentences like:

>> The can't reach inside closed containers rule is listed in the reaching inside rules.

But others have their placements made implicitly in their definitions:

>> Before eating something: ...

(which creates a nameless rule and implicitly places it in the "before"
rulebook). When Inform reads such a rule, it creates a booking, but does
not immediately insert it into a rulebook: instead it marks the booking
for "automatic placement" later on.

=
void Rules::Bookings::request_automatic_placement(booking *br) {
	br->automatic_placement = TRUE;
}

@ Automatic placement occurs in declaration order. This is important, because
it ensures that it is declaration order which the rule-sorting code falls back
on when it can see no other justification for placing one rule either side
of another.

=
void Rules::Bookings::make_automatic_placements(void) {
	booking *br;
	LOOP_OVER(br, booking)
		if (br->automatic_placement) {
			phrase *ph = Rules::get_I7_definition(br->rule_being_booked);
			if (ph) {
				current_sentence = ph->declaration_node;
				Rules::Bookings::place(&(ph->usage_data), br);
				Rules::set_kind_from(br->rule_being_booked,
					Phrases::Usage::get_rulebook(&(ph->usage_data)));
			}
		}
}


@ Having long ago decided where and how to place the phrase into a rulebook,
we finally get the opportunity to do this. The BR supplied must be the one
generated from the PHUD elsewhere.

=
void Rules::Bookings::place(ph_usage_data *phud, booking *br) {
	if (Phrases::Usage::get_effect(phud) == RULE_IN_RULEBOOK_EFF) {
		#ifdef IF_MODULE
		rulebook *original_owner = Phrases::Usage::get_rulebook(phud);
		if (Rulebooks::requires_specific_action(original_owner)) {
			int waiver = FALSE;
			action_name_list *anl;
			action_name *an;
			wording PW = Phrases::Usage::get_prewhile_text(phud);
			if (Wordings::nonempty(PW)) {
				LOOP_THROUGH_WORDING(i, PW)
					if (PL::Actions::Patterns::Named::by_name(Wordings::from(PW, i)))
						goto NotSingleAction;
				anl = PL::Actions::Lists::extract_actions_only(PW);
				an = PL::Actions::Lists::get_single_action(anl);
				Rules::set_marked_for_anyone(Rules::Bookings::get_rule(br),
					PL::Actions::Lists::get_explicit_anyone_flag(anl));
			} else {
				anl = NULL;
				an = NULL;
				waiver = TRUE;
				if (original_owner == built_in_rulebooks[CHECK_RB]) waiver = FALSE;
				if (original_owner == built_in_rulebooks[CARRY_OUT_RB]) waiver = FALSE;
				if (original_owner == built_in_rulebooks[REPORT_RB]) waiver = FALSE;
			}
			LOGIF(RULE_ATTACHMENTS, "BR is: $b\n AN is: $l\n", br, an);
			if ((an == NULL) && (waiver == FALSE)) {
				int x;
				an = PL::Actions::longest_null(PW, IS_TENSE, &x);
			}
			if ((an == NULL) && (waiver == FALSE)) {
				NotSingleAction:
				Phrases::Usage::log(phud);
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, PW);
				Problems::Issue::handmade_problem(_p_(PM_MultipleCCR));
				Problems::issue_problem_segment(
					"You wrote %1, but the situation this refers to ('%2') is "
					"not a single action. Rules in the form of 'check', 'carry "
					"out' and 'report' are tied to specific actions, and must "
					"give a single explicit action name - even if they then go "
					"on to very complicated conditions about any nouns also "
					"involved. So 'Check taking something: ...' is fine, "
					"but not 'Check taking or dropping something: ...' or "
					"'Check doing something: ...' - the former names two "
					"actions, the latter none.");
				Problems::issue_problem_end();
			} else {
				#ifdef IF_MODULE
				if (original_owner == built_in_rulebooks[CHECK_RB]) {
					Phrases::Usage::set_rulebook(phud,
						PL::Actions::get_fragmented_rulebook(an, built_in_rulebooks[CHECK_RB]));
				} else if (original_owner == built_in_rulebooks[CARRY_OUT_RB]) {
					Phrases::Usage::set_rulebook(phud,
						PL::Actions::get_fragmented_rulebook(an, built_in_rulebooks[CARRY_OUT_RB]));
				} else if (original_owner == built_in_rulebooks[REPORT_RB]) {
					Phrases::Usage::set_rulebook(phud,
						PL::Actions::get_fragmented_rulebook(an, built_in_rulebooks[REPORT_RB]));
				} else {
					Phrases::Usage::set_rulebook(phud,
						PL::Actions::switch_fragmented_rulebook(an, original_owner));
				}
				#endif
				if (original_owner != Phrases::Usage::get_rulebook(phud))
					LOGIF(RULE_ATTACHMENTS, "Rerouting $b to $K\n", br,
						Phrases::Usage::get_rulebook(phud));
			}
		}
		#endif
		Rulebooks::attach_rule(Phrases::Usage::get_rulebook(phud), br,
			Phrases::Usage::get_rulebook_placement(phud), 0, NULL);
	}
}

@h Specificity of bookings.
The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int Rules::Bookings::compare_specificity_of_br(booking *br1, booking *br2, int log) {
	if ((br1 == NULL) || (br2 == NULL)) internal_error("compared null specificity");
	if (log) LOG("Comparing specificity of rules:\n(1) $b\n(2) $b\n", br1, br2);
	return Rules::compare_specificity(
		br1->rule_being_booked, br2->rule_being_booked, log);
}

@h Lists of bookings.
Bookings are intended to be bound together in linked lists, each of which
represents the interior pages of a single rulebook.

There are only three operations on lists: creation, addition of a booking,
and removal of a booking. The following invariants are preserved:

(a) The list head is a dummy booking which has never been the subject of any
addition operation and has never moved.

(b) The only |FIRST_PLACEMENT| entries in the list immediately follow the list
head. Those which were added explicitly as first-placed are in reverse order
of addition to the list.

(c) The only |LAST_PLACEMENT| entries in the list are at the end. Those which
were added explicitly as last-placed are in order of addition to the list.

(d) If R and S are middle-placed rules which were placed in the list within
the same range (say, both anywhere, or both "after T" or "before U")
and R precedes S, then either R is more specific than S, or they are
equally specific and R was added to the list before S.

(e) The list never contains duplicates, that is, never contains two bookings
whose rules are equal, in the sense of |Rules::eq|.

@ A new list is a dummy header (see (a) above):

=
booking *Rules::Bookings::list_new(void) {
	return Rules::Bookings::new(NULL);
}

@ When rule R is explicitly placed into (the rule list of) rulebook B
(by an assertion like "R is listed after S in B", say), there are
evidently two possibilities:

Case (i). R's phrase already occurs somewhere in rulebook B, so that this
affects only the ordering of rulebook B. We therefore remove it (so that it
does not occur twice in B) and reinsert it within the position range
indicated. Note that this process still makes use of logical precedence; it
simply confines itself to a narrower range. If R has to occur before S,
then R is placed according to logical precedence within the sublist from
the head of the list up to just-before-S.

To determine whether or not R's phrase is already in B, we compare their
phrases if set, and their I6 equivalents if not.

Note that we search the entire rulebook for R, not just the valid interval
in the rulebook where R might go (e.g., "after S").

Case (ii). R's phrase does not occur in B. We insert R into rulebook B
within the position range indicated.

Each addition leaves the list either the same size or longer by 1.

If we insert a rule as first-placed rule when there already is a
first-placed rule, the new one displaces it to go first, but both continue
to be labelled as "first-placed", so that subsequent rule insertions of
middle-placed rules will still go after both of them. Symmetrically, a
second last-placed rule is inserted after any existing one, but both are
labelled "last-placed". Because of the range possibility ("after S") we
might find ourselves inserting a rule as middle-placed and yet still after
a last-placed rule, or before a first-placed one: if so we change its
placement to last or first respectively, in order to preserve invariants
(b) and (c) above.

There was a small debate on |rec.arts.int-fiction| in February 2009 as
to whether a rule placed instead of another rule within the same rulebook
should be duplicated, or moved. In builds from 2008 and earlier, there was
duplication, but this broke the clean principle that a rule appears only
once per rulebook, and made it difficult to place certain rules with tricky
preambles; on the other hand merely moving makes it more difficult to
replace a whole run of rules with a single place-holder. Both sides were
argued for. In March 2009, it was finally decided to go with moving, not
duplication, and to preserve the "only once per rulebook" principle.

@ We specify the way we want to add a rule to a list of bookings using the
following enumerated values, which handle requirements like "before the
awkward noises rule".

@d BEFORE_SIDE -1 /* before a reference rule */
@d IN_SIDE 0 /* without reference to any other rule */
@d AFTER_SIDE 1 /* after a reference rule */
@d INSTEAD_SIDE 2 /* in place of reference rule */

=
void Rules::Bookings::list_add(booking *list_head, booking *new_rule,
	int placing, int side, rule *ref_rule) {
	@<Make some sanity checks on the addition instructions@>;
	@<Handle the case where the new rule is already in the list@>;
	@<Handle all placements made with the INSTEAD side@>;
	@<Handle all placements made with the FIRST placement@>;
	@<Handle all placements made with the LAST placement@>;
	@<Handle what's left: MIDDLE placements on the IN, BEFORE or AFTER sides@>;
}

@<Make some sanity checks on the addition instructions@> =
	if ((side != IN_SIDE) && (ref_rule == NULL))
		internal_error("tried to add before or after or instead of non-rule");
	if ((side == IN_SIDE) && (ref_rule != NULL))
		internal_error("tried to add in middle but with ref rule");
	if ((side != IN_SIDE) && (placing != MIDDLE_PLACEMENT))
		internal_error("tried to add before or after but with non-middle placement");
	if (list_head == NULL)
		internal_error("tried to add rule to null list");
	switch(placing) {
		case MIDDLE_PLACEMENT: break;
		case FIRST_PLACEMENT: LOGIF(RULE_ATTACHMENTS, "Placed first\n"); break;
		case LAST_PLACEMENT: LOGIF(RULE_ATTACHMENTS, "Placed last\n"); break;
		default:
			LOG("Invalid placing %d\n", placing);
			internal_error("invalid placing of rule");
	}

@<Handle the case where the new rule is already in the list@> =
	booking *pos, *prev;
	for (prev=list_head, pos=list_head->next_rule; pos; prev=pos, pos=pos->next_rule)
		if (Rules::eq(Rules::Bookings::get_rule(pos),
			Rules::Bookings::get_rule(new_rule))) {
			if ((side == IN_SIDE) && (placing == MIDDLE_PLACEMENT))
				return; /* rule is already in rulebook: do nothing */
			prev->next_rule = pos->next_rule;
			pos->next_rule = NULL;
			LOGIF(RULE_ATTACHMENTS, "Removing previous entry from rulebook\n");
			break; /* rule can only appear once, so no need to keep checking */
		}

@<Handle all placements made with the INSTEAD side@> =
	if (side == INSTEAD_SIDE) {
		booking *pos, *prev;
		for (prev=list_head, pos=list_head->next_rule; pos; prev=pos, pos=pos->next_rule)
			if (Rules::eq(Rules::Bookings::get_rule(pos), ref_rule)) {
				new_rule->placement = pos->placement; /* replace with same placement */
				new_rule->next_rule = pos->next_rule;
				prev->next_rule = new_rule;
			}
		return;
	}

@<Handle all placements made with the FIRST placement@> =
	if (placing == FIRST_PLACEMENT) { /* first in valid interval (must be whole list) */
		booking *subseq = list_head->next_rule;
		list_head->next_rule = new_rule;
		new_rule->next_rule = subseq; /* pushes any existing first rule forward */
		new_rule->placement = placing;
		return;
	}

@<Handle all placements made with the LAST placement@> =
	if (placing == LAST_PLACEMENT) { /* last in valid interval (must be whole list) */
		booking *prev = list_head;
		while (prev->next_rule != NULL) prev = prev->next_rule;
		prev->next_rule = new_rule; /* pushes any existing last rule backward */
		new_rule->next_rule = NULL;
		new_rule->placement = placing;
		return;
	}

@<Handle what's left: MIDDLE placements on the IN, BEFORE or AFTER sides@> =
	booking *start_rule = list_head; /* valid interval begins after this rule */
	booking *end_rule = NULL; /* valid interval ends before this rule, or runs to end if |NULL| */
	@<Adjust the valid interval to take care of BEFORE and AFTER side requirements@>;
	@<Check that the valid interval is indeed as advertised@>;
	booking *insert_after = start_rule; /* insertion point is after this */
	@<Find insertion point, keeping the valid interval in specificity order@>;
	booking *subseq = insert_after->next_rule;
	insert_after->next_rule = new_rule;
	new_rule->next_rule = subseq;
	@<Set the placement for the new rule booking@>;

@<Adjust the valid interval to take care of BEFORE and AFTER side requirements@> =
	booking *pos;
	switch(side) {
		case BEFORE_SIDE:
			for (pos=list_head->next_rule; pos; pos=pos->next_rule)
				if (Rules::eq(Rules::Bookings::get_rule(pos), ref_rule))
					end_rule = pos; /* insert before: so valid interval ends here */
			if (end_rule == NULL) internal_error("can't find end rule");
			break;
		case AFTER_SIDE:
			for (pos=list_head->next_rule; pos; pos=pos->next_rule)
				if (Rules::eq(Rules::Bookings::get_rule(pos), ref_rule))
					start_rule = pos; /* insert after: so valid interval begins here */
			if (start_rule == list_head) internal_error("can't find start rule");
			break;
	}

@<Check that the valid interval is indeed as advertised@> =
	int i = 0, t = 2;
	if (end_rule == NULL) t = 1;
	booking *pos;
	for (pos = list_head; pos; pos = pos->next_rule) {
		if ((pos == start_rule) && (i == 0)) i = 1;
		if ((pos == end_rule) && (i == 1)) i = 2;
	}
	if (i != t) internal_error("valid rule interval isn't");

@<Find insertion point, keeping the valid interval in specificity order@> =
	int log = FALSE; if (Log::aspect_switched_on(SPECIFICITIES_DA)) log = TRUE;

	/* move forward to final valid first rule (if any exist) */
	while ((insert_after->next_rule != end_rule)
		&& (insert_after->next_rule->placement == FIRST_PLACEMENT))
		insert_after = insert_after->next_rule;

	/* move forward past other middle rules if they are not less specific */
	while ((insert_after->next_rule != end_rule) /* stop before $p$ leaves valid range */
		&& (insert_after->next_rule->placement != LAST_PLACEMENT) /* or reaches a last rule */
		&& (Rules::Bookings::compare_specificity_of_br(insert_after->next_rule, new_rule,
			log) >= 0)) /* or a rule less specific than the new one */
		insert_after = insert_after->next_rule;

@ Since this part of the algorithm is used only when we've requested MIDDLE
placement, it might seem that |new_rule->placement| should always be set to
that. This does indeed mostly happen, but not always. To preserve rulebook
invariants (b) and (c), we need to force anything added after a LAST rule
to be LAST as well, and similarly for FIRSTs. (This will only happen in
cases where the source text called for placements AFTER a LAST rule, or
BEFORE a FIRST one.)

@<Set the placement for the new rule booking@> =
	new_rule->placement = MIDDLE_PLACEMENT;
	if ((insert_after != list_head) &&
		(insert_after->placement == LAST_PLACEMENT))
		new_rule->placement =
			LAST_PLACEMENT; /* happens if valid interval is after a last rule */

	if ((subseq) &&
		(subseq->placement == FIRST_PLACEMENT))
		new_rule->placement =
			FIRST_PLACEMENT; /* happens if valid interval is before a first rule */

@ That leaves only the removal operation, which is much simpler:

=
void Rules::Bookings::list_remove(booking *list_head, rule *ref_rule) {
	booking *br, *pr;
	for (br = list_head->next_rule, pr = list_head; br; pr = br, br = br->next_rule) {
		if (Rules::eq(Rules::Bookings::get_rule(br), ref_rule)) {
			pr->next_rule = br->next_rule;
			return;
		}
	}
}

@h Logging lists.

=
void Rules::Bookings::list_log(booking *list_head) {
	if (list_head == NULL) { LOG("<null-booked-rule-list>\n"); return; }
	int t = Rules::Bookings::no_rules_in_list(list_head);
	if (t == 0) { LOG("<empty-booked-rule-list>\n"); return; }
	booking *br; int s;
	for (br = list_head->next_rule, s = 1; br; br = br->next_rule, s++)
		LOG("  %d/%d. $b\n", ++s, t, br);
}

@h Scanning lists for their contents.
Strictly speaking a |NULL| pointer is not valid as a booking list, since it
has no head, but we treat it as if it were the empty list:

=
int Rules::Bookings::no_rules_in_list(booking *list_head) {
	if (list_head == NULL) return 0;
	int n = 0;
	for (booking *br = list_head->next_rule; br; br = br->next_rule) n++;
	return n;
}


int Rules::Bookings::list_is_empty(booking *list_head, rule_context rc) {
	if (list_head == NULL) return TRUE;
	for (booking *br = list_head->next_rule; br; br = br->next_rule) {
		phrase *ph = Rules::get_I7_definition(br->rule_being_booked);
		if (Rulebooks::phrase_fits_rule_context(ph, rc)) return FALSE;
	}
	return TRUE;
}

int Rules::Bookings::list_is_empty_of_i7_rules(booking *list_head) {
	if (list_head == NULL) return TRUE;
	for (booking *br = list_head->next_rule; br; br = br->next_rule)
		if (Rules::get_I7_definition(br->rule_being_booked))
			return FALSE;
	return TRUE;
}

int Rules::Bookings::list_contains(booking *list_head, rule *to_find) {
	if (list_head == NULL) return FALSE;
	for (booking *br = list_head->next_rule; br; br = br->next_rule)
		if (Rules::eq(Rules::Bookings::get_rule(br), to_find))
			return TRUE;
	return FALSE;
}

int Rules::Bookings::list_contains_ph(booking *list_head, phrase *ph_to_find) {
	if (list_head == NULL) return FALSE;
	for (booking *br = list_head->next_rule; br; br = br->next_rule)
		if (Rules::get_I7_definition(br->rule_being_booked) == ph_to_find)
			return TRUE;
	return FALSE;
}

@h Indexing of lists.
There's a division of labour: here we arrange the index of the rules and
show the linkage between them, while the actual content for each rule is
handled in the "Rules" section.

=
int Rules::Bookings::list_index(OUTPUT_STREAM, booking *list_head, rule_context rc,
	char *billing, rulebook *owner, int *resp_count) {
	booking *br, *prev;
	int count = 0;
	for (br = list_head->next_rule, prev = NULL; br; prev = br, br = br->next_rule) {
		rule *R = br->rule_being_booked;
		#ifdef IF_MODULE
		phrase *ph = Rules::get_I7_definition(R);
		if (ph) {
			ph_runtime_context_data *phrcd = &(ph->runtime_context_data);
			scene *during_scene = Phrases::Context::get_scene(phrcd);
			if ((rc.scene_context) && (during_scene != rc.scene_context)) continue;
			if ((rc.action_context) &&
				(Phrases::Context::within_action_context(phrcd, rc.action_context) == FALSE))
				continue;
		}
		#endif
		count++;
		Rules::Bookings::br_start_index_line(OUT, prev, billing);
		*resp_count += Rules::index(OUT, R, owner, rc);
	}
	return count;
}

@ The "index links" are not hypertextual: they're the little icons showing
the order of precedence of rules in the list. On some index pages we don't
want this, so:

=
int show_index_links = TRUE;

void Rules::Bookings::list_suppress_indexed_links(void) {
	show_index_links = FALSE;
}

void Rules::Bookings::list_resume_indexed_links(void) {
	show_index_links = TRUE;
}

void Rules::Bookings::br_start_index_line(OUTPUT_STREAM, booking *prev, char *billing) {
	HTMLFiles::open_para(OUT, 2, "hanging");
	if ((billing[0]) && (show_index_links)) Rules::Bookings::br_show_linkage_icon(OUT, prev);
	WRITE("%s", billing);
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	if ((billing[0] == 0) && (show_index_links)) Rules::Bookings::br_show_linkage_icon(OUT, prev);
}

@ And here's how the index links (if wanted) are chosen and plotted:

=
void Rules::Bookings::br_show_linkage_icon(OUTPUT_STREAM, booking *prev) {
	char *icon_name = NULL; /* redundant assignment to appease |gcc -O2| */
	if ((prev == NULL) || (prev->next_rule_specificity_law == NULL)) {
		HTMLFiles::html_icon_with_tooltip(OUT, "rulenone.png", "start of rulebook", NULL);
		return;
	}
	switch (prev->next_rule_specificity) {
		case -1: icon_name = "ruleless.png"; break;
		case 0: icon_name = "ruleequal.png"; break;
		case 1: icon_name = "rulemore.png"; break;
		default: internal_error("unknown rule specificity");
	}
	HTMLFiles::html_icon_with_tooltip(OUT, icon_name, prev->next_rule_specificity_law,
		prev->next_rule_specificity_lawname);
}

@h Calculating the specificities.
And this is where the fields describing how the list was ordered are put
together. They're not a historical record of what was done: they're a
measurement of the final outcome.

=
void Rules::Bookings::list_judge_ordering(booking *list_head) {
	booking *br;
	if (list_head == NULL) return;
	for (br = list_head->next_rule; br; br = br->next_rule) {
		if (br->next_rule) {
			if (br->placement != br->next_rule->placement)
				@<Calculate specificities when placements differ@>
			else
				@<Calculate specificities when placements are the same@>;
		} else {
			br->next_rule_specificity = 0;
			br->next_rule_specificity_law = NULL;
		}
	}
}

@<Calculate specificities when placements differ@> =
	br->next_rule_specificity = 1;
	switch(br->placement) {
		case FIRST_PLACEMENT:
			switch(br->next_rule->placement) {
				case MIDDLE_PLACEMENT:
					br->next_rule_specificity_law =
						"the rule above was listed as 'first' so precedes this "
						"one, which wasn't";
					break;
				case LAST_PLACEMENT:
					br->next_rule_specificity_law =
						"the rule above was listed as 'first' so precedes this "
						"one, which was listed as 'last'";
					break;
				default:
					Rules::Bookings::list_log(list_head);
					internal_error("booking list invariant broken");
					break;
			}
			break;
		case MIDDLE_PLACEMENT:
			switch(br->next_rule->placement) {
				case LAST_PLACEMENT:
					br->next_rule_specificity_law =
						"the rule below was listed as 'last' so comes after the "
						"rule above, which wasn't";
					break;
				default:
					Rules::Bookings::list_log(list_head);
					internal_error("booking list invariant broken");
					break;
			}
			break;
		default:
			Rules::Bookings::list_log(list_head);
			internal_error("booking list invariant broken");
			break;
	}

@<Calculate specificities when placements are the same@> =
	int r;
	switch(br->placement) {
		case FIRST_PLACEMENT:
			br->next_rule_specificity = 0;
			br->next_rule_specificity_law =
				"these rules were both listed as 'first', so they appear in "
				"reverse order of listing";
			break;
		case MIDDLE_PLACEMENT:
			r = Rules::Bookings::compare_specificity_of_br(br, br->next_rule, FALSE);
			br->next_rule_specificity = r;
			if (r == 0) br->next_rule_specificity_law =
				"these rules are equally ranked, so their order is determined by "
				"which was defined first (or by explicit 'listed in' sentences)";
			else {
				br->next_rule_specificity_law =
				"the arrow points from a more specific rule to a more general one, "
				"as decided by Law";
				br->next_rule_specificity_lawname = c_s_stage_law;
			}
			break;
		case LAST_PLACEMENT:
			br->next_rule_specificity = 0;
			br->next_rule_specificity_law =
				"these rules were both listed as 'last', so they appear in order "
				"of listing";
			break;
	}

@h Compilation of rule definitions for rulebook.
There's no real need to do it this way -- but we compile rule definitions
in rulebook order to make the I6 source more legible, and for the same
reason we add plenty of commentary.

=
void Rules::Bookings::list_compile_rule_phrases(booking *list_head,
	int *i, int max_i) {
	if (list_head == NULL) return;

	int t = Rules::Bookings::no_rules_in_list(list_head);
	booking *br; int s;
	for (br = list_head->next_rule, s = 1; br; br = br->next_rule, s++) {
		Rules::compile_comment(br->rule_being_booked, s, t);
		if (br->next_rule) {
			TEMPORARY_TEXT(C);
			if (br->placement != br->next_rule->placement) {
				WRITE_TO(C, "--- now the ");
				switch(br->next_rule->placement) {
					case FIRST_PLACEMENT: WRITE_TO(C, "first-placed rules"); break;
					case MIDDLE_PLACEMENT: WRITE_TO(C, "mid-placed rules"); break;
					case LAST_PLACEMENT: WRITE_TO(C, "last-placed rules"); break;
				}
				WRITE_TO(C, " ---");
				Produce::comment(Emit::tree(), C);
			} else {
				char *law = br->next_rule_specificity_lawname;
				switch(br->next_rule_specificity) {
					case -1: WRITE_TO(C, "  <<< %s <<<", law); Produce::comment(Emit::tree(), C); break;
					case 0: WRITE_TO(C, "  === equally specific with ==="); Produce::comment(Emit::tree(), C); break;
					case 1: WRITE_TO(C, "  >>> %s >>>", law); Produce::comment(Emit::tree(), C); break;
				}
			}
			DISCARD_TEXT(C);
		}
	}
	CompiledText::divider_comment();
}

@h Compilation of I6-format rulebook.
The following can generate both old-style array rulebooks and routine rulebooks,
which were introduced in December 2010.

=
void Rules::Bookings::start_list_compilation(void) {
	packaging_state save = Routines::begin(Hierarchy::find(EMPTY_RULEBOOK_INAME_HL));
	LocalVariables::add_named_call(I"forbid_breaks");
	Produce::rfalse(Emit::tree());
	Routines::end(save);
}

@

@d ARRAY_RBF 1 /* format as an array simply listing the rules */
@d GROUPED_ARRAY_RBF 2 /* format as a grouped array, for quicker action testing */
@d ROUTINE_RBF 3 /* format as a routine which runs the rulebook */
@d RULE_OPTIMISATION_THRESHOLD 20 /* group arrays when larger than this number of rules */

=
inter_name *Rules::Bookings::list_compile(booking *list_head,
	inter_name *identifier, int action_based, int parameter_based) {
	if (list_head == NULL) return NULL;
	inter_name *rb_symb = NULL;

	int countup = Rules::Bookings::no_rules_in_list(list_head);
	if (countup == 0) {
		rb_symb = Emit::named_iname_constant(identifier, K_value,
			Hierarchy::find(EMPTY_RULEBOOK_INAME_HL));
	} else {
		int format = ROUTINE_RBF;

		@<Compile the rulebook in the given format@>;
	}
	return rb_symb;
}

@ Grouping is the practice of gathering together rules which all rely on
the same action going on; it's then efficient to test the action once rather
than once for each rule.

@<Compile the rulebook in the given format@> =
	int grouping = FALSE, group_cap = 0;
	switch (format) {
		case GROUPED_ARRAY_RBF: grouping = TRUE; group_cap = 31; break;
		case ROUTINE_RBF: grouping = TRUE; group_cap = 2000000000; break;
	}
	if (action_based == FALSE) grouping = FALSE;

	inter_symbol *forbid_breaks_s = NULL, *rv_s = NULL, *original_deadflag_s = NULL, *p_s = NULL;
	packaging_state save_array = Emit::unused_packaging_state();

	@<Open the rulebook compilation@>;
	int group_size = 0, group_started = FALSE, entry_count = 0, action_group_open = FALSE;
	booking *br;
	for (br = list_head->next_rule; br; br = br->next_rule) {
		parse_node *spec = Rvalues::from_rule(br->rule_being_booked);
		if (grouping) {
			if (group_size == 0) {
				if (group_started) @<End an action group in the rulebook@>;
				#ifdef IF_MODULE
				action_name *an = Rules::Bookings::br_required_action(br);
				booking *brg = br;
				while ((brg) && (an == Rules::Bookings::br_required_action(brg))) {
					group_size++;
					brg = brg->next_rule;
				}
				#endif
				#ifndef IF_MODULE
				booking *brg = br;
				while (brg) {
					group_size++;
					brg = brg->next_rule;
				}
				#endif
				if (group_size > group_cap) group_size = group_cap;
				group_started = TRUE;
				@<Begin an action group in the rulebook@>;
			}
			group_size--;
		}
		@<Compile an entry in the rulebook@>;
		entry_count++;
	}
	if (group_started) @<End an action group in the rulebook@>;
	@<Close the rulebook compilation@>;

@<Open the rulebook compilation@> =
	rb_symb = identifier;
	switch (format) {
		case ARRAY_RBF: save_array = Emit::named_array_begin(identifier, K_value); break;
		case GROUPED_ARRAY_RBF: save_array = Emit::named_array_begin(identifier, K_value); Emit::array_numeric_entry((inter_t) -2); break;
		case ROUTINE_RBF: {
			save_array = Routines::begin(identifier);
			forbid_breaks_s = LocalVariables::add_named_call_as_symbol(I"forbid_breaks");
			rv_s = LocalVariables::add_internal_local_c_as_symbol(I"rv", "return value");
			if (countup > 1)
				original_deadflag_s = LocalVariables::add_internal_local_c_as_symbol(I"original_deadflag", "saved state");
			if (parameter_based)
				p_s = LocalVariables::add_internal_local_c_as_symbol(I"p", "rulebook parameter");

			if (countup > 1) {
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, original_deadflag_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(DEADFLAG_HL));
				Produce::up(Emit::tree());
			}
			if (parameter_based) {
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, p_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PARAMETER_VALUE_HL));
				Produce::up(Emit::tree());
			}
			break;
		}
	}

@<Begin an action group in the rulebook@> =
	switch (format) {
		case GROUPED_ARRAY_RBF:
			#ifdef IF_MODULE
			if (an) Emit::array_action_entry(an); else
			#endif
				Emit::array_numeric_entry((inter_t) -2);
			if (group_size > 1) Emit::array_numeric_entry((inter_t) group_size);
			action_group_open = TRUE;
			break;
		case ROUTINE_RBF:
			#ifdef IF_MODULE
			if (an) {
				Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(ACTION_HL));
						Produce::val_iname(Emit::tree(), K_value, PL::Actions::double_sharp(an));
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());

				action_group_open = TRUE;
			}
			#endif
			break;
	}

@<Compile an entry in the rulebook@> =
	switch (format) {
		case ARRAY_RBF:
		case GROUPED_ARRAY_RBF:
			Specifications::Compiler::emit(spec);
			break;
		case ROUTINE_RBF:
			if (entry_count > 0) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), NE_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, original_deadflag_s);
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(DEADFLAG_HL));
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), RETURN_BIP);
						Produce::down(Emit::tree());
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			}
			@<Compile an optional mid-rulebook paragraph break@>;
			if (parameter_based) {
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(PARAMETER_VALUE_HL));
					Produce::val_symbol(Emit::tree(), K_value, p_s);
				Produce::up(Emit::tree());
			}
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, rv_s);
				Produce::inv_primitive(Emit::tree(), INDIRECT0_BIP);
				Produce::down(Emit::tree());
					Specifications::Compiler::emit_as_val(K_value, spec);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, rv_s);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), EQ_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, rv_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), RETURN_BIP);
							Produce::down(Emit::tree());
								Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(REASON_THE_ACTION_FAILED_HL));
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());

					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Specifications::Compiler::emit_as_val(K_value, spec);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LATEST_RULE_RESULT_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			break;
	}

@<End an action group in the rulebook@> =
	if (action_group_open) {
		switch (format) {
			case ROUTINE_RBF:
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<Compile an optional mid-rulebook paragraph break@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				break;
		}
		action_group_open = FALSE;
	}

@<Close the rulebook compilation@> =
	switch (format) {
		case ARRAY_RBF:
		case GROUPED_ARRAY_RBF:
			Emit::array_null_entry();
			Emit::array_end(save_array);
			break;
		case ROUTINE_RBF:
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			Routines::end(save_array);
			break;
	}

@<Compile an optional mid-rulebook paragraph break@> =
	if (entry_count > 0) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(SAY__P_HL));
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RULEBOOKPARBREAK_HL));
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, forbid_breaks_s);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}

@ And, finally, here's where a booking is turned into the action (if any) that
its rule requires:

=
#ifdef IF_MODULE
action_name *Rules::Bookings::br_required_action(booking *br) {
	phrase *ph = Rules::get_I7_definition(br->rule_being_booked);
	if (ph) return Phrases::Context::required_action(&(ph->runtime_context_data));
	return NULL;
}
#endif
