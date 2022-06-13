[CommandsElement::] Commands Element.

To write the Commands element (Cm) in the index.

@ =
void CommandsElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	inter_tree *I = Indexing::get_tree(session);

	linked_list *entries = NEW_LINKED_LIST(command_index_entry);
	@<Create the entries for the command list@>;
	linked_list *sorted = CommandsElement::sort(entries);

	wchar_t head_letter = 0;
	command_index_entry *cie;
	LOOP_OVER_LINKED_LIST(cie, command_index_entry, sorted) {
		if (Str::get_first_char(cie->command_headword) != head_letter) {
			if (head_letter) HTML_TAG("br");
			head_letter = Str::get_first_char(cie->command_headword);
		}
		@<Render an index entry from the sorted list@>;
	}
}

@<Create the entries for the command list@> =
	inter_package *pack = InterPackage::from_URL(I, I"/main/completion/grammar");
	inter_package *entry;
	LOOP_THROUGH_SUBPACKAGES(entry, pack, I"_command_grammar")
		if ((Metadata::read_optional_numeric(entry, I"^is_command")) &&
			(InterTree::no_subpackages(entry, I"_cg_line") > 0))
			@<Create entry for this command@>;
	CommandsElement::make_direction_entry(entries);

@<Create entry for this command@> =
	text_stream *main_command = Metadata::optional_textual(entry, I"^command");
	if (Str::len(main_command) == 0) main_command = I"0";
	CommandsElement::make_entry(main_command, entry, NORMAL_COMMAND, entries);
	inter_package *alias;
	LOOP_THROUGH_SUBPACKAGES(alias, entry, I"_cg_alias") {
		text_stream *alias_command = Metadata::required_textual(alias, I"^alias");
		CommandsElement::make_entry(alias_command, entry, ALIAS_COMMAND, entries);
	}

@ Entries in the list correspond to the headwords of commands which can be typed
at runtime, like QUIT or INVENTORY. For indexing purposes, we divide these headwords
as follows:

@d NORMAL_COMMAND 1
@d ALIAS_COMMAND 2
@d OUT_OF_WORLD_COMMAND 3
@d TESTING_COMMAND 4
@d BARE_DIRECTION_COMMAND 5

=
typedef struct command_index_entry {
	int nature; /* one of the above values */
	struct text_stream *command_headword; /* text of command headword, such as "REMOVE" */
	struct inter_package *cg_indexed; /* ...leading to... */
	struct command_index_entry *next_alphabetically; /* next in linked list */
	CLASS_DEFINITION
} command_index_entry;

command_index_entry *sorted_command_index = NULL; /* in alphabetical order of |text| */

@ =
void CommandsElement::make_test_entry(text_stream *t, linked_list *entries) {
	command_index_entry *cie;
	cie = CREATE(command_index_entry);
	cie->command_headword = Str::duplicate(t);
	cie->nature = TESTING_COMMAND;
	cie->cg_indexed = NULL;
	cie->next_alphabetically = NULL;
	ADD_TO_LINKED_LIST(cie, command_index_entry, entries);
}

void CommandsElement::make_entry(text_stream *headword, inter_package *cg_pack,
	int nature, linked_list *entries) {
	command_index_entry *cie = CREATE(command_index_entry);
	cie->command_headword = Str::duplicate(headword);
	cie->nature = nature;
	cie->cg_indexed = cg_pack;
	cie->next_alphabetically = NULL;
	ADD_TO_LINKED_LIST(cie, command_index_entry, entries);
}

void CommandsElement::make_direction_entry(linked_list *entries) {
	command_index_entry *cie = CREATE(command_index_entry);
	cie->command_headword = I"0";
	cie->nature = BARE_DIRECTION_COMMAND;
	cie->cg_indexed = NULL;
	cie->next_alphabetically = NULL;
	ADD_TO_LINKED_LIST(cie, command_index_entry, entries);
}

@ =
linked_list *CommandsElement::sort(linked_list *entries) {
	command_index_entry *cie, *list_start = NULL;
	LOOP_OVER_LINKED_LIST(cie, command_index_entry, entries) {
		if (list_start == NULL) { list_start = cie; continue; }
		command_index_entry *cie2 = list_start, *last_cie2 = NULL;
		while (cie2 && (Str::cmp(cie->command_headword, cie2->command_headword) > 0)) {
			last_cie2 = cie2;
			cie2 = cie2->next_alphabetically;
		}
		if (last_cie2 == NULL) {
			cie->next_alphabetically = list_start; list_start = cie;
		} else {
			last_cie2->next_alphabetically = cie; cie->next_alphabetically = cie2;
		}
	}
	linked_list *sorted = NEW_LINKED_LIST(command_index_entry);
	for (command_index_entry *cie = list_start; cie; cie = cie->next_alphabetically)
		ADD_TO_LINKED_LIST(cie, command_index_entry, sorted);
	return sorted;
}

@ With those lengthy digressions done, back to the actual indexing:

@<Render an index entry from the sorted list@> =
	inter_package *cg_pack = cie->cg_indexed;
	switch (cie->nature) {
		case NORMAL_COMMAND:
			CommandsElement::index_normal(OUT, I, cg_pack, cie->command_headword, LD);
			break;
		case ALIAS_COMMAND:
			CommandsElement::index_alias(OUT, I, cg_pack, cie->command_headword, LD);
			break;
		case OUT_OF_WORLD_COMMAND:
			HTML::begin_span(OUT, I"indexdullred");
			WRITE("&quot;%S&quot;, ", cie->command_headword);
			Localisation::italic(OUT, LD, I"Index.Elements.Cm.Command");
			HTML::end_span(OUT);
			HTML_TAG("br");
			break;
		case TESTING_COMMAND:
			HTML::begin_span(OUT, I"indexdullred");
			WRITE("&quot;%S&quot;, ", cie->command_headword);
			Localisation::italic(OUT, LD, I"Index.Elements.Cm.TestingCommand");
			HTML::end_span(OUT);
			HTML_TAG("br");
			break;
		case BARE_DIRECTION_COMMAND:
			WRITE("&quot;[direction]&quot; - ");
			Localisation::italic(OUT, LD, I"Index.Elements.Cm.DirectionCommand");
			HTML_TAG("br");
			break;
	}

@h Indexing grammar lines.

=
void CommandsElement::index_normal(OUTPUT_STREAM, inter_tree *I, inter_package *cg_pack,
	text_stream *headword, localisation_dictionary *LD) {
	inter_package *entry;
	LOOP_THROUGH_SUBPACKAGES(entry, cg_pack, I"_cg_line")
		CommandsElement::index_grammar_line(OUT, entry, headword, LD);
}

void CommandsElement::index_alias(OUTPUT_STREAM, inter_tree *I, inter_package *cg_pack,
	text_stream *headword, localisation_dictionary *LD) {
	WRITE("&quot;%S&quot;, ", headword);
	Localisation::italic(OUT, LD, I"Index.Elements.Cm.Alias");
	WRITE(" &quot;%S&quot;", Metadata::required_textual(cg_pack, I"^command"));
	IndexUtilities::link_package(OUT, cg_pack);
	HTML_TAG("br");
}

void CommandsElement::index_grammar_line(OUTPUT_STREAM, inter_package *cgl,
	text_stream *headword, localisation_dictionary *LD) {
	inter_symbol *an_s = Metadata::optional_symbol(cgl, I"^action");
	if (an_s == NULL) return;
	inter_package *an = InterPackage::container(an_s->definition);
	int oow = (int) Metadata::read_optional_numeric(an, I"^out_of_world");
	if (Str::len(headword) > 0) IndexUtilities::anchor(OUT, headword);
	if (oow) HTML::begin_span(OUT, I"indexdullred");
	WRITE("&quot;");
	TokensElement::verb_definition(OUT, Metadata::optional_textual(cgl, I"^text"),
		headword, EMPTY_WORDING);
	WRITE("&quot;");
	IndexUtilities::link_package(OUT, cgl);
	
	WRITE(" - <i>%S</i>", Metadata::required_textual(an, I"^name"));
	IndexUtilities::detail_link(OUT, "A",
		(int) Metadata::read_numeric(an, I"action_id"), TRUE);
	if (Metadata::read_optional_numeric(cgl, I"^reversed")) {
		WRITE(" ");
		Localisation::italic(OUT, LD, I"Index.Elements.Cm.Reversed");
	}
	if (oow) HTML::end_span(OUT);
	HTML_TAG("br");
}
