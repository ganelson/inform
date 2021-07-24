[EventsElement::] Events Element.

To write the Events element (Ev) in the index.

@ There are two tables, one for timed events, the other for those of no fixed time.

=
void EventsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->rule_nodes, Synoptic::module_order);

	int when_count = 0, tt_count = 0;
	@<Index events with no specific time@>;
	@<Index timetabled events@>;
	if ((when_count == 0) && (tt_count == 0)) {
		HTML_OPEN("p"); WRITE("<i>None.</i>"); HTML_CLOSE("p");
	}
}

@<Index events with no specific time@> =
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->rule_nodes)
		if ((Metadata::exists(pack, I"^timed")) &&
			(Metadata::exists(pack, I"^timed_for") == FALSE)) {
			if (when_count == 0) {
				HTML_OPEN("p");
				WRITE("<i>Events with no specific time</i>");
				HTML_CLOSE("p");
			}
			when_count++;
			HTML_OPEN_WITH("p", "class=\"tightin2\"");
			WRITE("%S", Metadata::read_textual(pack, I"^preamble"));
			IndexUtilities::link_package(OUT, pack);
			WRITE(" (where triggered: ");
			inter_package *entry;
			LOOP_THROUGH_SUBPACKAGES(entry, pack, I"_timed_rule_trigger") {
				int at = (int) Metadata::read_optional_numeric(entry, I"^used_at");
				if (at > 0) IndexUtilities::link(OUT, at);
			}
			WRITE(")");
			HTML_CLOSE("p");
		}

@<Index timetabled events@> =
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->rule_nodes)
		if ((Metadata::exists(pack, I"^timed")) &&
			(Metadata::exists(pack, I"^timed_for"))) {
			if (tt_count == 0) {
				HTML_OPEN("p");
				WRITE("<i>Timetable</i>");
				HTML_CLOSE("p");
			}
			tt_count++;
			HTML_OPEN_WITH("p", "class=\"in2\"");
			WRITE("%S", Metadata::read_textual(pack, I"^preamble"));
			IndexUtilities::link_package(OUT, pack);
			HTML_CLOSE("p");
		}
