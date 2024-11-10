[RuleBookings::] Rule Bookings.

Bookings are assignments of rules to rulebooks.

@h Introduction.
Rules are only really of use in rulebooks, but in fact they can belong to
any number of rulebooks. Each placement of a rule in a rulebook is called
a "booking", and results in a //booking// object. These are gathered into
linked lists as //booking_list// objects: see //Booking Lists//.

We can think of rule bookings as being looseleaf pages, of which we have an
unlimited supply: any rule can be written on them. They can be bound into
any rulebook at any specified position, but each rulebook divides into three
non-overlapping sections: the first rules, the middle rules, the last rules.
And each //booking// records which of these sections it belongs to.

@e MIDDLE_PLACEMENT from 0 /* most bookings are in this middle section */
@e VERY_FIRST_PLACEMENT
@e FIRST_PLACEMENT
@e LAST_PLACEMENT
@e VERY_LAST_PLACEMENT

=
typedef struct booking {
	struct rule *rule_being_booked; /* what appears on this page */
	int placement; /* one of the |*_PLACEMENT| values above */
	int place_automatically; /* should this be inserted automatically? */

	struct booking_commentary commentary; /* used only for indexing and code comments */

	struct booking *next_booking; /* in its booking list */
	CLASS_DEFINITION
} booking;

@ Here's a rather arcane notation used in the debugging log:

=
void RuleBookings::log(booking *br) {
	if (br == NULL) { LOG("BR:<null-booked-rule>"); return; }
	LOG("BR%d", br->allocation_id);
	switch (br->placement) {
		case MIDDLE_PLACEMENT: LOG("m"); break;
		case VERY_FIRST_PLACEMENT: LOG("vf"); break;
		case FIRST_PLACEMENT: LOG("f"); break;
		case LAST_PLACEMENT: LOG("l"); break;
		case VERY_LAST_PLACEMENT: LOG("vl"); break;
		default: LOG("?"); break;
	}
	Rules::log(br->rule_being_booked);
}

@h Creation.

=
booking *RuleBookings::new(rule *R) {
	booking *br = CREATE(booking);
	br->next_booking = NULL;
	br->rule_being_booked = R;
	br->placement = MIDDLE_PLACEMENT;
	br->place_automatically = FALSE;
	br->commentary = RuleBookings::new_commentary();
	return br;
}

@h Access.

=
rule *RuleBookings::get_rule(booking *br) {
	if (br == NULL) return NULL;
	return br->rule_being_booked;
}

@h Placement.
When created, a booking is like a piece of looseleaf paper which has not yet
been put into a binder (i.e., into the //booking_list// of a rulebook); the
process of putting it into such a list is called "placement".

Most rules declare a single rulebook to belong to in their definitions:

>> Before eating something: ...

This nameless rule is to go into the "before eating" rulebook. When Inform
reads this, it creates a booking, but does not immediately place this into
the rulebook; instead, the booking is marked for automatic placement later on.

=
void RuleBookings::request_automatic_placement(booking *br) {
	br->place_automatically = TRUE;
}

@ And now it's later on:

=
void RuleBookings::make_automatic_placements(void) {
	booking *br;
	LOOP_OVER(br, booking)
		if (br->place_automatically) {
			imperative_defn *id = Rules::get_imperative_definition(br->rule_being_booked);
			if (id) {
				current_sentence = id->at;
				id_body *idb = id->body_of_defn;
				rulebook *original_owner = RuleFamily::get_rulebook(idb->head_of_defn);
				int placement = RuleFamily::get_rulebook_placement(idb->head_of_defn);
				rulebook *owner = original_owner;
				PluginCalls::place_rule(br->rule_being_booked, original_owner, &owner);
				if (owner != original_owner) {
					RuleFamily::set_rulebook(idb->head_of_defn, owner);
					LOGIF(RULE_ATTACHMENTS, "Rerouting $b: $K --> $K\n",
						br, original_owner, owner);
				}
				Rulebooks::attach_rule(owner, br, placement, 0, NULL);
				Rules::set_kind_from(br->rule_being_booked, owner);
			} else {
				internal_error("Inter-defined rules cannot be automatically placed");
			}
		}
}

@h Specificity of bookings.
This |strcmp|-like function is intended to be used in sorting algorithms,
and returns 1 if |br1| is more specific than |br2|, -1 if |br2| is more specific
than |br1|, or 0 if they are equally good.

=
int RuleBookings::cmp(booking *br1, booking *br2, int log_this) {
	if ((br1 == NULL) || (br2 == NULL)) internal_error("compared null specificity");
	if (log_this) LOG("Comparing specificity of rules:\n(1) $b\n(2) $b\n", br1, br2);
	return Rules::cmp(br1->rule_being_booked, br2->rule_being_booked, log_this);
}

@h Commentary.
The sorting algorithm for rulebooks is very important, and Inform authors sometimes
need to know why rulebooks come out in a particular order. So each booking includes
a //booking_commentary// which explains how it came to end up where it did. This
is used only for code comments and the index.

=
typedef struct booking_commentary {
	int next_rule_specificity; /* 1 for more specific than following, 0 equal, -1 less */
	struct text_stream *tooltip_text; /* description of reason */
	struct text_stream *law_applied; /* name of Law used to sort */
} booking_commentary;

booking_commentary RuleBookings::new_commentary(void) {
	booking_commentary bc;
	bc.next_rule_specificity = 0;
	bc.tooltip_text = NULL;
	bc.law_applied = NULL;
	return bc;
}

void RuleBookings::comment(OUTPUT_STREAM, booking *br) {
	text_stream *law = br->commentary.law_applied;
	switch(br->commentary.next_rule_specificity) {
		case -1: WRITE("  <<< %S <<<", law); break;
		case 0: WRITE("  === equally specific with ==="); break;
		case 1: WRITE("  >>> %S >>>", law); break;
	}
}

void RuleBookings::list_judge_ordering(booking_list *L) {
	LOOP_OVER_BOOKINGS(br, L)
		if (br->next_booking) {
			if (br->placement != br->next_booking->placement)
				@<Calculate specificities when placements differ@>
			else
				@<Calculate specificities when placements are the same@>;
		} else {
			br->commentary.next_rule_specificity = 0;
			br->commentary.tooltip_text = NULL;
		}
}

@<Calculate specificities when placements differ@> =
	br->commentary.next_rule_specificity = 1;
	switch(br->placement) {
		case VERY_FIRST_PLACEMENT:
			br->commentary.tooltip_text =
				I"the rule above was listed as 'very first' so it precedes everything";
			break;
		case FIRST_PLACEMENT:
			switch(br->next_booking->placement) {
				case MIDDLE_PLACEMENT:
					br->commentary.tooltip_text =
						I"the rule above was listed as 'first' so precedes this one, which wasn't";
					break;
				case LAST_PLACEMENT:
					br->commentary.tooltip_text =
						I"the rule above was listed as 'first' so precedes this one, listed as 'last'";
					break;
				case VERY_LAST_PLACEMENT:
					br->commentary.tooltip_text =
						I"the rule below was listed as 'very last' so it comes after everything";
					break;
				default:
					BookingLists::log(L);
					internal_error("booking list invariant broken");
					break;
			}
			break;
		case MIDDLE_PLACEMENT:
			switch(br->next_booking->placement) {
				case LAST_PLACEMENT:
					br->commentary.tooltip_text =
					I"the rule below was listed as 'last' so comes after this one, which wasn't";
					break;
				case VERY_LAST_PLACEMENT:
					br->commentary.tooltip_text =
						I"the rule below was listed as 'very last' so it comes after everything";
					break;
				default:
					BookingLists::log(L);
					internal_error("booking list invariant broken");
					break;
			}
			break;
		case LAST_PLACEMENT:
			switch(br->next_booking->placement) {
				case VERY_LAST_PLACEMENT:
					br->commentary.tooltip_text =
						I"the rule below was listed as 'very last' so it comes after everything";
					break;
				default:
					BookingLists::log(L);
					internal_error("booking list invariant broken");
					break;
			}
			break;
		default:
			BookingLists::log(L);
			internal_error("booking list invariant broken");
			break;
	}

@<Calculate specificities when placements are the same@> =
	br->commentary.next_rule_specificity = 0;
	switch(br->placement) {
		case VERY_FIRST_PLACEMENT:
			BookingLists::log(L);
			internal_error("multiple very first rules for the same rulebook");
			break;
		case FIRST_PLACEMENT:
			br->commentary.tooltip_text =
			I"these rules were both listed as 'first', so they appear in reverse order of listing";
			break;
		case MIDDLE_PLACEMENT:
			br->commentary.next_rule_specificity =
				RuleBookings::cmp(br, br->next_booking, FALSE);
			if (br->commentary.next_rule_specificity == 0) br->commentary.tooltip_text =
			I"these rules are equally ranked";
			else {
				br->commentary.tooltip_text =
				I"the arrow points from a more specific rule to a more general, as decided by Law";
				br->commentary.law_applied = Specifications::law_applied();
			}
			break;
		case LAST_PLACEMENT:
			br->commentary.tooltip_text =
			I"these rules were both listed as 'last', so they appear in order of listing";
			break;
		case VERY_LAST_PLACEMENT:
			BookingLists::log(L);
			internal_error("multiple very last rules for the same rulebook");
			break;
	}
