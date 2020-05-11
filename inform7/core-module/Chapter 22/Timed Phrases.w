[Phrases::Timed::] Timed Phrases.

Another way phrases can be invoked is as timed events, which need
no special Inform data structure and are simply compiled into a pair of
timetable I6 arrays to be processed at run-time.

@h Definitions.

@ The timing of an event records the time at which a phrase should
spontaneously happen. This is ordinarily a time value, in minutes from 12
midnight, for a phrase happening at a specific time -- for instance, one
defined as "At 9:00 AM: ..." But two values are special:

@d NOT_A_TIMED_EVENT -1 /* as for the vast majority of phrases */
@d NO_FIXED_TIME -2 /* for phrases like "When the clock strikes: ..." */
@d NOT_AN_EVENT -3 /* not even syntactically */

@ And here we record where events are used:

=
typedef struct use_as_event {
	struct parse_node *where_triggered; /* sentence which specifies when this occurs */
	struct use_as_event *next;
	CLASS_DEFINITION
} use_as_event;

@ Timed events are stored in two simple arrays, processed by run-time code.

=
void Phrases::Timed::TimedEventsTable(void) {
	inter_name *iname = Hierarchy::find(TIMEDEVENTSTABLE_HL);
	packaging_state save = Emit::named_table_array_begin(iname, K_value);
	int when_count = 0;
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		int t = Phrases::Usage::get_timing_of_event(&(ph->usage_data));
		if (t == NOT_A_TIMED_EVENT) continue;
		if (t == NO_FIXED_TIME) when_count++;
		else Emit::array_iname_entry(Phrases::iname(ph));
	}

	for (int i=0; i<when_count+1; i++) {
		Emit::array_numeric_entry(0);
		Emit::array_numeric_entry(0);
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void Phrases::Timed::TimedEventTimesTable(void) {
	inter_name *iname = Hierarchy::find(TIMEDEVENTTIMESTABLE_HL);
	packaging_state save = Emit::named_table_array_begin(iname, K_number);
	int when_count = 0;
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		int t = Phrases::Usage::get_timing_of_event(&(ph->usage_data));
		if (t == NOT_A_TIMED_EVENT) continue;
		if (t == NO_FIXED_TIME) when_count++;
		else Emit::array_numeric_entry((inter_t) t);
	}

	for (int i=0; i<when_count+1; i++) {
		Emit::array_numeric_entry(0);
		Emit::array_numeric_entry(0);
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@ That's it, really: everything else is just indexing.

=
void Phrases::Timed::note_usage(phrase *ph, parse_node *at) {
	int t = Phrases::Usage::get_timing_of_event(&(ph->usage_data));
	if (t == NO_FIXED_TIME) {
		use_as_event *uae = CREATE(use_as_event);
		uae->where_triggered = at;
		uae->next = NULL;
		use_as_event *prev = ph->usage_data.uses_as_event;
		if (prev == NULL) ph->usage_data.uses_as_event = uae;
		else {
			while ((prev) && (prev->next)) prev = prev->next;
			prev->next = uae;
		}
	}
}

@ An interesting case where the Problem is arguably only a warning and
arguably shouldn't block compilation. Then again...

=
void Phrases::Timed::check_for_unused(void) {
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if (Phrases::Usage::get_timing_of_event(&(ph->usage_data)) == NO_FIXED_TIME) {
			if (ph->usage_data.uses_as_event == NULL) {
				current_sentence = ph->declaration_node;
				Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnusedTimedEvent),
					"this sets up a timed event which is never used",
					"since you never use any of the phrases which could cause it. "
					"(A timed event is just a name, and it needs other instructions "
					"elsewhere before it can have any effect.)");
			}
		}
}

@ And here's the actual index segment.

=
void Phrases::Timed::index(OUTPUT_STREAM) {
	int when_count = 0, tt_count = 0;
	@<Index events with no specific time@>;
	@<Index timetabled events@>;
	if ((when_count == 0) && (tt_count == 0)) {
		HTML_OPEN("p"); WRITE("<i>None.</i>"); HTML_CLOSE("p");
	}
}

@<Index events with no specific time@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		int t = Phrases::Usage::get_timing_of_event(&(ph->usage_data));
		if (t == NO_FIXED_TIME) {
			if (when_count == 0) {
				HTML_OPEN("p");
				WRITE("<i>Events with no specific time</i>");
				HTML_CLOSE("p");
			}
			when_count++;
			HTML_OPEN_WITH("p", "class=\"tightin2\"");
			Phrases::Usage::index_preamble(OUT, &(ph->usage_data));
			if ((ph->declaration_node) &&
				(Wordings::nonempty(Node::get_text(ph->declaration_node))))
				Index::link(OUT, Wordings::first_wn(Node::get_text(ph->declaration_node)));
			WRITE(" (where triggered: ");
			use_as_event *uae;
			for (uae = ph->usage_data.uses_as_event; uae; uae=uae->next)
				Index::link(OUT, Wordings::first_wn(Node::get_text(uae->where_triggered)));
			WRITE(")");
			HTML_CLOSE("p");
		}
	}

@<Index timetabled events@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		int t = Phrases::Usage::get_timing_of_event(&(ph->usage_data));
		if (t >= 0) { /* i.e., an actual time of day in minutes since midnight */
			if (tt_count == 0) {
				HTML_OPEN("p");
				WRITE("<i>Timetable</i>");
				HTML_CLOSE("p");
			}
			tt_count++;
			HTML_OPEN_WITH("p", "class=\"in2\"");
			Phrases::Usage::index_preamble(OUT, &(ph->usage_data));
			if ((ph->declaration_node) &&
				(Wordings::nonempty(Node::get_text(ph->declaration_node))))
				Index::link(OUT, Wordings::first_wn(Node::get_text(ph->declaration_node)));
			HTML_CLOSE("p");
		}
	}
