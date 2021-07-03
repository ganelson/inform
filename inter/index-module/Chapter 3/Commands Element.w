[CommandsElement::] Commands Element.

To write the Commands element (Cm) in the index.

@ =
void CommandsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();

	command_index_entry *vie, *vie2, *last_vie2, *list_start = NULL;
	int head_letter;

	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/grammar");
	inter_symbol *wanted = PackageTypes::get(I, I"_command_grammar");
	inter_tree_node *D = Inter::Packages::definition(pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				if ((Metadata::read_optional_numeric(entry, I"^is_command")) &&
					(CommandsElement::no_lines(I, entry) > 0)) {
					text_stream *main_command = Metadata::read_optional_textual(entry, I"^command");
					if (Str::len(main_command) == 0) main_command = I"0";
					CommandsElement::vie_new_from(main_command, entry, NORMAL_COMMAND);
					inter_symbol *wanted_i = PackageTypes::get(I, I"_cg_alias");
					LOOP_THROUGH_INTER_CHILDREN(B, C) {
						if (B->W.data[ID_IFLD] == PACKAGE_IST) {
							inter_package *alias = Inter::Package::defined_by_frame(B);
							if (Inter::Packages::type(alias) == wanted_i) {
								text_stream *alias_command = Metadata::read_textual(alias, I"^alias");
								CommandsElement::vie_new_from(alias_command, entry, ALIAS_COMMAND);
							}
						}
					}
				}
			}
		}
	}

	CommandsElement::direction_verb();

	LOOP_OVER(vie, command_index_entry) {
		if (list_start == NULL) { list_start = vie; continue; }
		vie2 = list_start;
		last_vie2 = NULL;
		while (vie2 && (Str::cmp(vie->command_headword, vie2->command_headword) > 0)) {
			last_vie2 = vie2;
			vie2 = vie2->next_alphabetically;
		}
		if (last_vie2 == NULL) {
			vie->next_alphabetically = list_start; list_start = vie;
		} else {
			last_vie2->next_alphabetically = vie; vie->next_alphabetically = vie2;
		}
	}

	for (vie = list_start, head_letter = 0; vie; vie = vie->next_alphabetically) {
		if (Str::get_first_char(vie->command_headword) != head_letter) {
			if (head_letter) HTML_TAG("br");
			head_letter = Str::get_first_char(vie->command_headword);
		}
		inter_package *cg = vie->cg_indexed;
		switch (vie->nature) {
			case NORMAL_COMMAND:
				CommandsElement::index_normal(OUT, I, cg, vie->command_headword);
				break;
			case ALIAS_COMMAND:
				CommandsElement::index_alias(OUT, I, cg, vie->command_headword);
				break;
			case OUT_OF_WORLD_COMMAND:
				HTML::begin_colour(OUT, I"800000");
				WRITE("&quot;%S&quot;, <i>a command for controlling play</i>",
					vie->command_headword);
				HTML::end_colour(OUT);
				HTML_TAG("br");
				break;
			case TESTING_COMMAND:
				HTML::begin_colour(OUT, I"800000");
				WRITE("&quot;%S&quot;, <i>a testing command not available "
					"in the final game</i>",
					vie->command_headword);
				HTML::end_colour(OUT);
				HTML_TAG("br");
				break;
			case BARE_DIRECTION_COMMAND:
				WRITE("&quot;[direction]&quot; - <i>going</i>");
				HTML_TAG("br");
				break;
		}
	}
}

int CommandsElement::no_lines(inter_tree *I, inter_package *cg) {
	int N = 0;
	inter_symbol *wanted = PackageTypes::get(I, I"_cg_line");
	inter_tree_node *D = Inter::Packages::definition(cg);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) N++;
		}
	}
	return N;
}

@ The following modest structure is used for the indexing of command verbs,
and is too deeply boring to comment upon. These are the headwords of commands
which can be typed at run-time, like QUIT or INVENTORY. For indexing purposes,
we divide these headwords into five "natures":

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
void CommandsElement::test_verb(text_stream *t) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::duplicate(t);
	vie->nature = TESTING_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;
}

command_index_entry *CommandsElement::vie_new_from(text_stream *headword, inter_package *cg, int nature) {
	command_index_entry *vie = CREATE(command_index_entry);
	vie->command_headword = Str::duplicate(headword);
	vie->nature = nature;
	vie->cg_indexed = cg;
	vie->next_alphabetically = NULL;
	return vie;
}

void CommandsElement::direction_verb(void) {
	command_index_entry *vie = CREATE(command_index_entry);
	vie->command_headword = I"0";
	vie->nature = BARE_DIRECTION_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;
}

@h Indexing by grammar.
This is the more obvious form of indexing: we show the grammar lines which
make up an individual CGL. (For instance, this is used in the Actions index
to show the grammar for an individual command word, by calling the routine
below for that command word's CG.) Such an index list is done in sorted
order, so that the order of appearance in the index corresponds to the
order of parsing -- this is what the reader of the index is interested in.

=
void CommandsElement::index_normal(OUTPUT_STREAM, inter_tree *I, inter_package *cg, text_stream *headword) {
	inter_symbol *wanted = PackageTypes::get(I, I"_cg_line");
	inter_tree_node *D = Inter::Packages::definition(cg);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted)
				CommandsElement::cgl_index_normal(OUT, entry, headword);
		}
	}
}

void CommandsElement::cgl_index_normal(OUTPUT_STREAM, inter_package *cgl, text_stream *headword) {
	inter_symbol *an_s = Metadata::read_optional_symbol(cgl, I"^action");
	if (an_s == NULL) return;
	inter_package *an = Inter::Packages::container(an_s->definition);
	int oow = (int) Metadata::read_optional_numeric(an, I"^out_of_world");
	if (Str::len(headword) > 0) Index::anchor(OUT, headword);
	if (oow) HTML::begin_colour(OUT, I"800000");
	WRITE("&quot;");
	TokensElement::verb_definition(OUT, Metadata::read_optional_textual(cgl, I"^text"),
		headword, EMPTY_WORDING);
	WRITE("&quot;");
	int at = (int) Metadata::read_optional_numeric(cgl, I"^at");
	if (at > 0) Index::link(OUT, at);
	
	WRITE(" - <i>%S", Metadata::read_textual(an, I"^name"));
	Index::detail_link(OUT, "A", (int) Metadata::read_numeric(an, I"action_id"), TRUE);
	if (Metadata::read_optional_numeric(cgl, I"^reversed"))
		WRITE(" <i>reversed</i>");
	WRITE("</i>");
	if (oow) HTML::end_colour(OUT);
	HTML_TAG("br");
}

void CommandsElement::index_alias(OUTPUT_STREAM, inter_tree *I, inter_package *cg, text_stream *headword) {
	WRITE("&quot;%S&quot;, <i>same as</i> &quot;%S&quot;",
		headword, Metadata::read_textual(cg, I"^command"));
	int at = (int) Metadata::read_optional_numeric(cg, I"^at");
	if (at > 0) Index::link(OUT, at);
	HTML_TAG("br");
}
