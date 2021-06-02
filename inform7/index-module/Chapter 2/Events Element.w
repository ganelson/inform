[IXEvents::] Events Element.

To index relations.

@

=
void IXEvents::render(OUTPUT_STREAM) {
	int when_count = 0, tt_count = 0;
	@<Index events with no specific time@>;
	@<Index timetabled events@>;
	if ((when_count == 0) && (tt_count == 0)) {
		HTML_OPEN("p"); WRITE("<i>None.</i>"); HTML_CLOSE("p");
	}
}

@<Index events with no specific time@> =
	id_body *idb;
	LOOP_OVER(idb, id_body) {
		int t = TimedRules::get_timing_of_event(idb->head_of_defn);
		if (t == NO_FIXED_TIME) {
			if (when_count == 0) {
				HTML_OPEN("p");
				WRITE("<i>Events with no specific time</i>");
				HTML_CLOSE("p");
			}
			when_count++;
			HTML_OPEN_WITH("p", "class=\"tightin2\"");
			ImperativeDefinitions::index_preamble(OUT, idb->head_of_defn);
			if ((ImperativeDefinitions::body_at(idb)) &&
				(Wordings::nonempty(Node::get_text(ImperativeDefinitions::body_at(idb)))))
				Index::link(OUT, Wordings::first_wn(Node::get_text(ImperativeDefinitions::body_at(idb))));
			WRITE(" (where triggered: ");
			linked_list *L = TimedRules::get_uses_as_event(idb->head_of_defn);
			parse_node *p;
			LOOP_OVER_LINKED_LIST(p, parse_node, L)
				Index::link(OUT, Wordings::first_wn(Node::get_text(p)));
			WRITE(")");
			HTML_CLOSE("p");
		}
	}

@<Index timetabled events@> =
	id_body *idb;
	LOOP_OVER(idb, id_body) {
		int t = TimedRules::get_timing_of_event(idb->head_of_defn);
		if (t >= 0) { /* i.e., an actual time of day in minutes since midnight */
			if (tt_count == 0) {
				HTML_OPEN("p");
				WRITE("<i>Timetable</i>");
				HTML_CLOSE("p");
			}
			tt_count++;
			HTML_OPEN_WITH("p", "class=\"in2\"");
			ImperativeDefinitions::index_preamble(OUT, idb->head_of_defn);
			if ((ImperativeDefinitions::body_at(idb)) &&
				(Wordings::nonempty(Node::get_text(ImperativeDefinitions::body_at(idb)))))
				Index::link(OUT, Wordings::first_wn(Node::get_text(ImperativeDefinitions::body_at(idb))));
			HTML_CLOSE("p");
		}
	}

