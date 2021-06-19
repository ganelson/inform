[CommandsElement::] Commands Element.

To write the Commands element (Cm) in the index.

@ =
void CommandsElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();

	command_index_entry *vie, *vie2, *last_vie2, *list_start = NULL;
	command_grammar *cg;
	int head_letter;

	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/grammar");
	inter_symbol *wanted = PackageTypes::get(I, I"_command_grammar");
	inter_tree_node *D = Inter::Packages::definition(pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
/*				if ((cg->cg_is == CG_IS_COMMAND) && (cg->first_line)) {
					if (Wordings::empty(cg->command))
						CommandsElement::vie_new_from(OUT, L"0", cg, NORMAL_COMMAND);
					else
						CommandsElement::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(cg->command)), cg, NORMAL_COMMAND);
					for (int i=0; i<cg->no_aliased_commands; i++)
						CommandsElement::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(cg->aliased_command[i])), cg, ALIAS_COMMAND);
*/
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
				CommandsIndex::index_normal(OUT, cg, vie->command_headword);
				break;
			case ALIAS_COMMAND:
				CommandsIndex::index_alias(OUT, cg, vie->command_headword);
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
				WRITE("&quot;[direction]&quot; - <i>Going</i>");
				HTML_TAG("br");
				break;
		}
	}
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
void CommandsElement::index_meta_verb(char *t) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::new();
	WRITE_TO(vie->command_headword, "%s", t);
	vie->nature = OUT_OF_WORLD_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;
}

void CommandsElement::test_verb(text_stream *t) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::duplicate(t);
	vie->nature = TESTING_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;
}

command_index_entry *CommandsElement::vie_new_from(wchar_t *headword, inter_package *cg, int nature) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::new();
	WRITE_TO(vie->command_headword, "%w", headword);
	vie->nature = nature;
	vie->cg_indexed = cg;
	vie->next_alphabetically = NULL;
	return vie;
}

void CommandsElement::direction_verb(void) {
	vie = CREATE(command_index_entry);
	vie->command_headword = I"0";
	vie->nature = BARE_DIRECTION_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;
}
