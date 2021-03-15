[CommandGrammars::] Command Grammars.


@ There are several sorts of command grammar, then, and only the first
of these is associated with a genuine typed-by-the-player command verb:

@d CG_IS_COMMAND 1  /* an imperative verbal command at run-time */
@d CG_IS_TOKEN   2  /* a square-bracketed token in other grammar */
@d CG_IS_SUBJECT  3  /* a noun phrase at run time: a name for an object */
@d CG_IS_VALUE   4  /* a noun phrase at run time: a name for a value */
@d CG_IS_CONSULT 5  /* a pattern to match in part of a command (such as "consult") */
@d CG_IS_PROPERTY_NAME 6  /* a noun phrase at run time: a name for an either/or pval */

@ The following maxima are imposed by the I6 compiler:

@d MAX_ALIASED_COMMANDS 32
@d MAX_LINES_PER_COMMAND 32

=
typedef struct command_grammar {
	int cg_is; /* one of the |CG_IS_*| values above */

	struct grammar_type cg_type;

	struct cg_line *first_line; /* linked list in creation order */
	struct cg_line *sorted_first_line; /* and in logical applicability order */

	struct wording command; /* |CG_IS_COMMAND|: word number at which command found */
	struct wording aliased_command[MAX_ALIASED_COMMANDS]; /* ...and other commands synonymous */
	int no_aliased_commands; /* ...and how many of them there are */

	struct wording name; /* |CG_IS_TOKEN|: name of this token */
	struct inter_name *cg_line_iname;

	struct inference_subject *subj_understood; /* |CG_IS_SUBJECT|: what this provides names for */

	struct kind *kind_understood; /* |CG_IS_VALUE|: for which type it names an instance of */
	struct inter_name *cg_parse_name_iname;

	struct property *prn_understood; /* |CG_IS_PROPERTY_NAME|: which prn this names */
	struct inter_name *cg_prn_iname; /* the relevant GPR is called this */

	struct parse_node *where_gv_created; /* for problem message reports */

	struct inter_name *cg_consult_iname; /* for the consult parsing routine if needed */
	struct text_stream *cg_I6_identifier; /* when a token is delegated to an I6 routine */

	int slashed; /* slashing has been done */
	int determined; /* determination has been done */

	CLASS_DEFINITION
} command_grammar;

@ A few imperative verbs are reserved for Inform testing, such as SHOWME.
We record those as instances of the following:

=
typedef struct reserved_command_verb {
	text_stream *reserved_text;
	CLASS_DEFINITION
} reserved_command_verb;

@ We begin as usual with a constructor and some debug log tracing.

=
command_grammar *CommandGrammars::cg_new(int cg_is) {
	command_grammar *cg;
	cg = CREATE(command_grammar);
	cg->command = EMPTY_WORDING;
	cg->first_line = NULL;
	cg->cg_type = UnderstandTokens::Types::new(FALSE);
	cg->cg_is = cg_is;
	cg->name = EMPTY_WORDING;
	cg->no_aliased_commands = 0;
	cg->sorted_first_line = NULL;
	cg->subj_understood = NULL;
	cg->kind_understood = NULL;
	cg->cg_parse_name_iname = NULL;
	cg->prn_understood = NULL;
	cg->where_gv_created = current_sentence;
	cg->cg_consult_iname = NULL;
	cg->cg_prn_iname = NULL;
	cg->cg_line_iname = NULL;
	cg->cg_I6_identifier = Str::new();
	cg->slashed = FALSE;
	cg->determined = FALSE;
	return cg;
}

void CommandGrammars::log(command_grammar *cg) {
	LOG("<CG%d:", cg->allocation_id);
	switch(cg->cg_is) {
		case CG_IS_COMMAND:
			if (Wordings::empty(cg->command)) LOG("command=no-verb verb");
			else LOG("command=%W", cg->command);
			break;
		case CG_IS_TOKEN: LOG("token=%W", cg->name); break;
		case CG_IS_SUBJECT: LOG("object"); break;
		case CG_IS_VALUE: LOG("value=%u", cg->kind_understood); break;
		case CG_IS_CONSULT: LOG("consult"); break;
		case CG_IS_PROPERTY_NAME: LOG("property-name"); break;
		default: LOG("<unknown>"); break;
	}
	LOG(">");
}

@h Command words.
Some GVs are used to represent the command grammar for imperative verbs
used by the player at run-time. Such a CG handles multiple commands, which
are considered equivalent at run-time: the first of these is the official
command word, and the rest are "aliases". For instance, the Standard Rules
create a CG for the command PULL with one alias, DRAG. (This somewhat
asymmetric approach is used because it matches the way I6 |Verb| declarations
are laid out.)

A complication is that one CG is permitted to be a special case: the
so-called "no verb verb", whose main command word is empty and which
can have no aliases. This is used to parse verbless commands at run-time:
for instance, the I7 designer can specify that a command consisting only
of a number followed by the word GO should cause some action, and this
is implemented not with a command verb but using I6's hooks for verbless
commands. The grammar "[number] go" is attached as a grammar line to
the "no verb verb", which is distinguished by having its command word
number set to |-1|. Note that the "no verb verb" exists only in runs of
Inform where it has been needed: the Standard Rules do not use it.

Command GVs other than the "no verb verb" are said to be "genuinely
verbal".

=
wording CommandGrammars::get_verb_text(command_grammar *cg) {
	return cg->command;
}

int CommandGrammars::cg_is_genuinely_verbal(command_grammar *cg) {
	if ((cg->cg_is == CG_IS_COMMAND) && (Wordings::nonempty(cg->command)))
		return TRUE;
	return FALSE;
}

@ The next routine finds, or if necessary creates, a CG for a given command
word encountered without any indication that it should alias another. Note
that calling this with word number |-1| finds, or creates, the "no verb
verb".

=
command_grammar *CommandGrammars::find_or_create_command(wording W) {
	command_grammar *cg = CommandGrammars::find_command(W);

	if (cg) return cg;

	cg = CommandGrammars::cg_new(CG_IS_COMMAND);
	cg->command = W;

	if (Wordings::empty(W)) {
		inter_name *iname = Hierarchy::find(NO_VERB_VERB_DEFINED_HL);
		Emit::named_numeric_constant(iname, (inter_ti) 1);
		global_compilation_settings.no_verb_verb_exists = TRUE;
	}
	else LOGIF(GRAMMAR_CONSTRUCTION, "CG%d has verb %W\n", cg->allocation_id, W);

	return cg;
}

@ By contrast, this routine merely finds a CG, or returns null if none
exists with the given command word.

=
command_grammar *CommandGrammars::find_command(wording W) {
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_COMMAND) {
			if (Wordings::empty(W)) {
				if (Wordings::empty(cg->command)) return cg;
			} else {
				if (Wordings::match(cg->command, W)) return cg;
				for (int i=0; i<cg->no_aliased_commands; i++)
					if (Wordings::match(cg->aliased_command[i], W))
						return cg;
			}
		}
	return NULL;
}

@ We now have routines to add or remove commands from a given CG. Removing
is the tricky case, since detaching the main command word means that one
of the aliases must become the new main command; or, in the worst case,
that there are no commands left, in which case we need to empty the CG
of grammar lines so that it can either be ignored or re-used (in the
event that the designer, having cancelled the old meaning of the command,
now supplies new ones).

It is not possible to add to, or remove from, the "no verb verb".

=
void CommandGrammars::add_command(command_grammar *cg, wording W) {
	if (cg == NULL)
		internal_error("tried to add alias command to null CG");
	if (cg->cg_is != CG_IS_COMMAND)
		internal_error("tried to add alias command to non-command CG");
	if (cg->no_aliased_commands == MAX_ALIASED_COMMANDS) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooManyAliases),
			"this 'understand the command ... as ...' makes too many aliases "
			"for the same command",
			"exceeding the limit of 32.");
		return;
	}
	cg->aliased_command[cg->no_aliased_commands++] = W;
	LOGIF(GRAMMAR, "Adding alias '%W' to G%d '%W'\n", W, cg->allocation_id, cg->command);
}

void CommandGrammars::remove_command(command_grammar *cg, wording W) {
	if (cg == NULL)
		internal_error("tried to detach alias command from null CG");
	if (cg->cg_is != CG_IS_COMMAND)
		internal_error("tried to detach alias command from non-command CG");
	LOGIF(GRAMMAR, "Detaching verb '%W' from grammar\n", W);
	if (cg == NULL)	return;
	if (Wordings::match(cg->command, W)) {
		LOGIF(GRAMMAR, "Detached verb is the head-verb\n");
		if (cg->no_aliased_commands == 0) {
			cg->first_line = NULL;
			LOGIF(GRAMMAR, "Which had no aliases: clearing grammar to NULL\n");
		} else {
			cg->command = cg->aliased_command[--(cg->no_aliased_commands)];
			LOGIF(GRAMMAR, "Which had aliases: making new head-verb '%W'\n",
				cg->command);
		}
	} else {
		LOGIF(GRAMMAR, "Detached verb is one of the aliases\n");
		for (int i=0; i<cg->no_aliased_commands; i++) {
			if (Wordings::match(cg->aliased_command[i], W)) {
				for (int j=i; j<cg->no_aliased_commands-1; j++)
					cg->aliased_command[j] = cg->aliased_command[j+1];
				cg->no_aliased_commands--;
				break;
			}
		}
	}
}

void CommandGrammars::index_command_aliases(OUTPUT_STREAM, command_grammar *cg) {
	if (cg == NULL) return;
	int i, n = cg->no_aliased_commands;
	for (i=0; i<n; i++)
		WRITE("/%N", Wordings::first_wn(cg->aliased_command[i]));
}

void CommandGrammars::remove_action(command_grammar *cg, action_name *an) {
	if (cg->cg_is != CG_IS_COMMAND) return;
	cg->first_line = UnderstandLines::list_remove(cg->first_line, an);
}

@ Command GVs are destined to be compiled into |Verb| directives, as follows.

=
packaging_state CommandGrammars::cg_compile_Verb_directive_header(command_grammar *cg, inter_name *array_iname) {
	if (cg->cg_is != CG_IS_COMMAND)
		internal_error("tried to compile Verb from non-command CG");
	if (cg->first_line == NULL)
		internal_error("compiling Verb for empty grammar");

	packaging_state save = Emit::named_verb_array_begin(array_iname, K_value);

	if (Wordings::empty(cg->command))
		Emit::array_dword_entry(I"no.verb");
	else {
		TEMPORARY_TEXT(vt)
		WRITE_TO(vt, "%W", Wordings::one_word(Wordings::first_wn(cg->command)));
		if (CommandGrammars::command_verb_reserved(vt)) {
			current_sentence = cg->where_gv_created;
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, cg->command);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
			Problems::issue_problem_segment(
				"You wrote %1, but %2 is a built-in Inform testing verb, which "
				"means it is reserved for Inform's own use and can't be used "
				"for ordinary play purposes. %PThe verbs which are reserved in "
				"this way are all listed in the alphabetical catalogue on the "
				"Actions Index page.");
			Problems::issue_problem_end();
		}
		DISCARD_TEXT(vt)
		TEMPORARY_TEXT(WD)
		WRITE_TO(WD, "%N", Wordings::first_wn(cg->command));
		Emit::array_dword_entry(WD);
		DISCARD_TEXT(WD)
		for (int i=0; i<cg->no_aliased_commands; i++) {
			TEMPORARY_TEXT(WD)
			WRITE_TO(WD, "%N", Wordings::first_wn(cg->aliased_command[i]));
			Emit::array_dword_entry(WD);
			DISCARD_TEXT(WD)
		}
	}
	return save;
}

@ Reserved verb names are collated as the I6 template files are read:

=
void CommandGrammars::reserve(text_stream *verb_name) {
	reserved_command_verb *rcv = CREATE(reserved_command_verb);
	rcv->reserved_text = Str::new();
	CommandGrammars::normalise_cv_to(rcv->reserved_text, verb_name);
	CommandsIndex::test_verb(rcv->reserved_text);
}

int CommandGrammars::command_verb_reserved(text_stream *verb_tried) {
	reserved_command_verb *rcv;
	TEMPORARY_TEXT(normalised_vt)
	CommandGrammars::normalise_cv_to(normalised_vt, verb_tried);
	LOOP_OVER(rcv, reserved_command_verb)
		if (Str::eq(normalised_vt, rcv->reserved_text))
			return TRUE;
	DISCARD_TEXT(normalised_vt)
	return FALSE;
}

void CommandGrammars::normalise_cv_to(OUTPUT_STREAM, text_stream *from) {
	Str::clear(OUT);
	for (int i=0; (i<31) && (i<Str::len(from)); i++)
		PUT(Characters::tolower(Str::get_at(from, i)));
}

@ The "Commands available to the player" portion of the Actions index page
is, in effect, an alphabetised merge of the GLs found within the command GVs.
GLs for the "no verb verb" appear under the special headword "0" (which
is not displayed); otherwise GLs appear under the main command word, and
aliases are shown with references like: "drag", same as "pull".

One routine takes a CG and creates suitable entries for the Actions index
to process; the other two routines act upon any such entries once they are
needed.

=
void CommandGrammars::make_command_index_entries(OUTPUT_STREAM, command_grammar *cg) {
	if ((cg->cg_is == CG_IS_COMMAND) && (cg->first_line)) {
		if (Wordings::empty(cg->command))
			CommandsIndex::vie_new_from(OUT, L"0", cg, NORMAL_COMMAND);
		else
			CommandsIndex::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(cg->command)), cg, NORMAL_COMMAND);
		for (int i=0; i<cg->no_aliased_commands; i++)
			CommandsIndex::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(cg->aliased_command[i])), cg, ALIAS_COMMAND);
	}
}

void CommandGrammars::index_normal(OUTPUT_STREAM, command_grammar *cg, text_stream *headword) {
	UnderstandLines::sorted_list_index_normal(OUT, cg->sorted_first_line, headword);
}

void CommandGrammars::index_alias(OUTPUT_STREAM, command_grammar *cg, text_stream *headword) {
	WRITE("&quot;%S&quot;, <i>same as</i> &quot;%N&quot;",
		headword, Wordings::first_wn(cg->command));
	TEMPORARY_TEXT(link)
	WRITE_TO(link, "%N", Wordings::first_wn(cg->command));
	Index::below_link(OUT, link);
	DISCARD_TEXT(link)
	HTML_TAG("br");
}

@h Named grammar tokens.
These are like text substitutions in reverse. For instance, we could define
a token "[suitable colour]". These are identified solely by their textual
names (e.g., "suitable colour").

=
command_grammar *CommandGrammars::named_token_new(wording W) {
	command_grammar *cg = CommandGrammars::named_token_by_name(W);
	if (cg == NULL) {
		cg = CommandGrammars::cg_new(CG_IS_TOKEN);
		cg->name = W;
		package_request *PR = Hierarchy::local_package(NAMED_TOKENS_HAP);
		cg->cg_line_iname = Hierarchy::make_iname_in(PARSE_LINE_FN_HL, PR);
	}
	return cg;
}

command_grammar *CommandGrammars::named_token_by_name(wording W) {
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)
		if ((cg->cg_is == CG_IS_TOKEN) && (Wordings::match(W, cg->name)))
			return cg;
	return NULL;
}

@ =
void CommandGrammars::index_tokens(OUTPUT_STREAM) {
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "anybody", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "anyone", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "anything", NULL, NULL, I"things_token", "same as \"[thing]\"");
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "other things", NULL, NULL, I"things_token", NULL);
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "somebody", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "someone", NULL, NULL, I"someone_token", NULL);
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "something", NULL, NULL, I"things_token", "same as \"[thing]\"");
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "something preferably held", NULL, NULL, I"things_token", NULL);
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "text", NULL, NULL, I"text_token", NULL);
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "things", NULL, NULL, I"things_token", NULL);
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "things inside", NULL, NULL, I"things_token", NULL);
	CommandGrammars::index_tokens_for(OUT, EMPTY_WORDING, "things preferably held", NULL, NULL, I"things_token", NULL);
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_TOKEN)
			CommandGrammars::index_tokens_for(OUT, cg->name, NULL,
				cg->where_gv_created, cg->sorted_first_line, NULL, NULL);
}

void CommandGrammars::index_tokens_for(OUTPUT_STREAM, wording W, char *special, parse_node *where,
	cg_line *defns, text_stream *help, char *explanation) {
	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("\"[");
	if (special) WRITE("%s", special); else WRITE("%+W", W);
	WRITE("]\"");
	if (where) Index::link(OUT, Wordings::first_wn(Node::get_text(where)));
	if (Str::len(help) > 0) Index::DocReferences::link(OUT, help);
	if (explanation) WRITE(" - %s", explanation);
	HTML_CLOSE("p");
	if (defns) UnderstandLines::index_list_for_token(OUT, defns);
}


@ A slight variation is provided by those which are defined by I6 routines.

=
void CommandGrammars::translates(wording W, parse_node *p2) {
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)
		if ((cg->cg_is == CG_IS_TOKEN) && (Wordings::match(W, cg->name))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_GrammarTranslatedAlready),
				"this grammar token has already been translated",
				"so there must be some duplication somewhere.");
			return;
		}
	cg = CommandGrammars::named_token_new(W);
	WRITE_TO(cg->cg_I6_identifier, "%N", Wordings::first_wn(Node::get_text(p2)));
}

inter_name *CommandGrammars::i6_token_as_iname(command_grammar *cg) {
	if (Str::len(cg->cg_I6_identifier) > 0)
		return Produce::find_by_name(Emit::tree(), cg->cg_I6_identifier);
	if (cg->cg_line_iname == NULL) internal_error("no token GPR");
	return cg->cg_line_iname;
}

@h Consultation grammars.
These are used for grammar included as a column of a table or in a
conditional match. The terminology goes back to the early days of I6, when
CONSULT was a command capable of parsing arbitrary text, something which
a game called Curses made heavy use of.

=
command_grammar *CommandGrammars::consultation_new(void) {
	command_grammar *cg;
	cg = CommandGrammars::cg_new(CG_IS_CONSULT);
	return cg;
}

@h Subject parsing grammars.
Each inference subject can optionally have a CG, used to parse unusual forms of
its name (though of course many subjects are never parsed at all, so this is
only used in practice for objects and their kinds). The following routine finds
or creates such.

=
command_grammar *CommandGrammars::for_subject(inference_subject *subj) {
	command_grammar *cg;
	if (PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object != NULL)
		return PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object;
	cg = CommandGrammars::cg_new(CG_IS_SUBJECT);
	PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object = cg;
	cg->subj_understood = subj;
	return cg;
}

void CommandGrammars::take_out_one_word_grammar(command_grammar *cg) {
	if (cg->cg_is != CG_IS_SUBJECT)
		internal_error("One-word optimisation applies only to objects");
	cg->first_line = UnderstandLines::list_take_out_one_word_grammar(cg->first_line);
}

int CommandGrammars::allow_mixed_lines(command_grammar *cg) {
	if ((cg->cg_is == CG_IS_SUBJECT) || (cg->cg_is == CG_IS_VALUE))
		return TRUE;
	return FALSE;
}

@h Data type parsing grammars.
Each kind can optionally have a CG, used to parse unusual forms of
its literals. The following routine finds or creates this.

=
command_grammar *CommandGrammars::for_kind(kind *K) {
	command_grammar *cg;
	if (CommandGrammars::get_parsing_grammar(K) != NULL)
		return CommandGrammars::get_parsing_grammar(K);
	cg = CommandGrammars::cg_new(CG_IS_VALUE);
	CommandGrammars::set_parsing_grammar(K, cg);
	cg->kind_understood = K;
	return cg;
}

@h Property name parsing grammars.
Only either/or properties can have a CG, used to parse unusual forms of
the alternatives as used when properties are describing objects. The
following routine finds or creates this for a given property.

=
command_grammar *CommandGrammars::for_prn(property *prn) {
	command_grammar *cg;
	if (EitherOrProperties::get_parsing_grammar(prn) != NULL)
		return EitherOrProperties::get_parsing_grammar(prn);
	cg = CommandGrammars::cg_new(CG_IS_PROPERTY_NAME);
	EitherOrProperties::set_parsing_grammar(prn, cg);
	cg->prn_understood = prn;
	cg->cg_prn_iname = Hierarchy::make_iname_in(EITHER_OR_GPR_FN_HL, RTProperties::package(prn));
	return cg;
}

@h The list of grammar lines.
Every CG has a list of GLs: indeed, this list is really the grammar. Here
we test this for emptiness, and provide for adding to it. Removals are not
possible.

=
int CommandGrammars::is_empty(command_grammar *cg) {
	if ((cg == NULL) || (cg->first_line == NULL)) return TRUE;
	return FALSE;
}

void CommandGrammars::add_line(command_grammar *cg, cg_line *cgl) {
	LOGIF(GRAMMAR, "Adding grammar line $g to verb $G\n", cgl, cg);
	if ((cg->cg_is == CG_IS_COMMAND) &&
		(UnderstandLines::list_length(cg->first_line) >= MAX_LINES_PER_COMMAND)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooManyGrammarLines),
			"this command verb now has too many Understand possibilities",
			"that is, there are too many 'Understand \"whatever ...\" as ...' "
			"which share the same initial word 'whatever'. The best way to "
			"get around this is to try to consolidate some of those lines "
			"together, perhaps by using slashes to combine alternative "
			"wordings, or by defining new grammar tokens [in square brackets].");
		return;
	}
	cg->first_line = UnderstandLines::list_add(cg->first_line, cgl);
}

@ Each CG has the potential to carry a kind made up of the number of
values produced, and what their types are. This is only really meaningful
for the GVs trying to express a single value: the following routine returns
|UNKNOWN_NT| unless that's the case.

=
kind *CommandGrammars::get_data_type_as_token(command_grammar *cg) {
	return UnderstandTokens::Types::get_data_type_as_token(&(cg->cg_type));
}

@ Some tokens require suitable I6 routines to have already been compiled,
if they are to work nicely: the following routine goes through the tokens
by exploring each CG in turn.

=
void CommandGrammars::compile_conditions(void) {
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)	{
		current_sentence = cg->where_gv_created;
		UnderstandLines::line_list_compile_condition_tokens(cg->first_line);
	}
}

@h Grammar Preparation.
This simply causes Phases I and II of grammar processing to take place, one
after the other.

=
void CommandGrammars::prepare(void) {
	CommandGrammars::cg_slash_all();
	CommandGrammars::cg_determine_all();
}

@h Phase I: Slash Grammar.
Slashing is really a grammar-line based activity, so we do no more than
pass the buck down to the list of grammar lines.

=
void CommandGrammars::cg_slash_all(void) {
	command_grammar *cg;
	Log::new_stage(I"Slashing grammar (G1)");
	LOOP_OVER(cg, command_grammar) {
		if (cg->slashed == FALSE) {
			LOGIF(GRAMMAR_CONSTRUCTION, "Slashing $G\n", cg);
			UnderstandLines::line_list_slash(cg->first_line);
			cg->slashed = TRUE;
		}
	}
}

@h Phase II: Determining Grammar.
Again, at this top level we are really only calling downwards.

=
void CommandGrammars::cg_determine_all(void) {
	command_grammar *cg;
	Log::new_stage(I"Determining grammar (G2)");
	LOOP_OVER(cg, command_grammar)
		if ((cg->determined == FALSE) && (cg->first_line)) {
			current_sentence = cg->where_gv_created;
			CommandGrammars::determine(cg, 0);
			cg->determined = TRUE;
		}
}

parse_node *CommandGrammars::determine(command_grammar *cg, int depth) {
	parse_node *spec_union = NULL;
	current_sentence = cg->where_gv_created;

	if (UnderstandTokens::Types::has_return_type(&(cg->cg_type)))
		return UnderstandTokens::Types::get_single_type(&(cg->cg_type));

	if (depth > NUMBER_CREATED(command_grammar)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_GrammarIllFounded),
			"grammar tokens are not allowed to be defined in terms of "
			"themselves",
			"either directly or indirectly.");
		return NULL;
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Determining $G\n", cg);

	spec_union = UnderstandLines::line_list_determine(cg->first_line, depth,
		cg->cg_is, cg, CommandGrammars::cg_is_genuinely_verbal(cg));

	LOGIF(GRAMMAR_CONSTRUCTION, "Result of verb $G is $P\n", cg, spec_union);

	UnderstandTokens::Types::set_single_type(&(cg->cg_type), spec_union);

	return spec_union;
}

@h Phases III and IV: Sort and Compile Grammar.
At this highest level phases III and IV are intermingled, in that Phase III
always precedes Phase IV for any given list of grammar lines, but each CG
goes through both Phase III and IV before the next begins Phase III. So it
would not be appropriate to print banners like "Phase III begins here"
in the debugging log.

Finally, though, some substantive work to do: because it is the CG which
records the purpose of the grammar in question, we must compile a suitable
I6 context for the grammar to appear within.

Four of the five kinds of CG are compiled by the routine below: the fifth
kind is compiled in "Tokens Parsing Values", in response to different
|.i6t| commands, because the token routines are needed at a different position
in the final I6 output.

Sequence is important here: in particular the GPRs must exist before the
|Verb| directives, because otherwise I6 will throw not-declared-yet errors.

=
inter_name *VERB_DIRECTIVE_REVERSE_iname = NULL;
inter_name *VERB_DIRECTIVE_SLASH_iname = NULL;
inter_name *VERB_DIRECTIVE_DIVIDER_iname = NULL;
inter_name *VERB_DIRECTIVE_RESULT_iname = NULL;
inter_name *VERB_DIRECTIVE_SPECIAL_iname = NULL;
inter_name *VERB_DIRECTIVE_NUMBER_iname = NULL;
inter_name *VERB_DIRECTIVE_NOUN_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTI_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTIINSIDE_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTIHELD_iname = NULL;
inter_name *VERB_DIRECTIVE_HELD_iname = NULL;
inter_name *VERB_DIRECTIVE_CREATURE_iname = NULL;
inter_name *VERB_DIRECTIVE_TOPIC_iname = NULL;
inter_name *VERB_DIRECTIVE_MULTIEXCEPT_iname = NULL;

inter_name *CommandGrammars::grammar_constant(int N, int V) {
	inter_name *iname = Hierarchy::find(N);
	Emit::named_numeric_constant(iname, 1);
	Hierarchy::make_available(Emit::tree(), iname);
	return iname;
}

void CommandGrammars::compile_all(void) {
	command_grammar *cg;
	CommandGrammars::cg_slash_all();
	CommandGrammars::cg_determine_all();

	Log::new_stage(I"Sorting and compiling non-value grammar (G3, G4)");

	VERB_DIRECTIVE_REVERSE_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_REVERSE_HL, 1);
	VERB_DIRECTIVE_SLASH_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_SLASH_HL, 1);
	VERB_DIRECTIVE_DIVIDER_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_DIVIDER_HL, 1);
	VERB_DIRECTIVE_RESULT_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_RESULT_HL, 2);
	VERB_DIRECTIVE_SPECIAL_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_SPECIAL_HL, 3);
	VERB_DIRECTIVE_NUMBER_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_NUMBER_HL, 4);
	VERB_DIRECTIVE_NOUN_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_NOUN_HL, 5);
	VERB_DIRECTIVE_MULTI_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTI_HL, 6);
	VERB_DIRECTIVE_MULTIINSIDE_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIINSIDE_HL, 7);
	VERB_DIRECTIVE_MULTIHELD_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIHELD_HL, 8);
	VERB_DIRECTIVE_HELD_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_HELD_HL, 9);
	VERB_DIRECTIVE_CREATURE_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_CREATURE_HL, 10);
	VERB_DIRECTIVE_TOPIC_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_TOPIC_HL, 11);
	VERB_DIRECTIVE_MULTIEXCEPT_iname = CommandGrammars::grammar_constant(VERB_DIRECTIVE_MULTIEXCEPT_HL, 12);

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_TOKEN)
			CommandGrammars::compile(cg); /* makes GPRs for designed tokens */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_COMMAND)
			CommandGrammars::compile(cg); /* makes |Verb| directives */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_SUBJECT)
			CommandGrammars::compile(cg); /* makes routines for use in |parse_name| */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_CONSULT)
			CommandGrammars::compile(cg); /* routines to parse snippets, used as values */

	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_PROPERTY_NAME)
			CommandGrammars::compile(cg); /* makes routines for use in |parse_name| */

	UnderstandLines::compile_slash_gprs();
}

@ The following routine unites, so far as possible, the different forms of
CG by compiling each of them as a sandwich: top slice, filling, bottom slice.
The interesting case is of a CG representing names for an object: the
name-behaviour needs to be inherited from the object's kind, and so on up
the kinds hierarchy, but this is a case where I7's kind hierarchy does not
agree with I6's class hierarchy. I6 has no (nice) way to inherit |parse_name|
behaviour from a class to an instance. So we will simply pile up extra
fillings into the sandwich. The order of these is important: by getting
in first, grammar for the instance takes priority; its immediate kind has
next priority, and so on up the hierarchy.

=
void CommandGrammars::compile(command_grammar *cg) {
	if (cg->first_line == NULL) return;

	LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);

	current_sentence = cg->where_gv_created;

	UnderstandLines::reset_labels();
	switch(cg->cg_is) {
		case CG_IS_COMMAND: {
			package_request *PR = Hierarchy::synoptic_package(COMMANDS_HAP);
			inter_name *array_iname = Hierarchy::make_iname_in(VERB_DECLARATION_ARRAY_HL, PR);
			packaging_state save = 
				CommandGrammars::cg_compile_Verb_directive_header(cg, array_iname);
			CommandGrammars::cg_compile_lines(NULL, cg);
			Emit::array_end(save);
			break;
		}
		case CG_IS_TOKEN: {
			gpr_kit gprk = UnderstandValueTokens::new_kit();
			if (cg->cg_line_iname == NULL) internal_error("cg token not ready");
			packaging_state save = Routines::begin(cg->cg_line_iname);
			UnderstandValueTokens::add_original(&gprk);
			UnderstandValueTokens::add_standard_set(&gprk);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk.original_wn_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk.rv_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Produce::up(Emit::tree());
			CommandGrammars::cg_compile_lines(&gprk, cg);
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_FAIL_HL));
			Produce::up(Emit::tree());
			Routines::end(save);
			break;
		}
		case CG_IS_CONSULT: {
			gpr_kit gprk = UnderstandValueTokens::new_kit();
			inter_name *iname = UnderstandGeneralTokens::consult_iname(cg);
			packaging_state save = Routines::begin(iname);
			UnderstandValueTokens::add_range_calls(&gprk);
			UnderstandValueTokens::add_original(&gprk);
			UnderstandValueTokens::add_standard_set(&gprk);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::val_symbol(Emit::tree(), K_value, gprk.range_from_s);
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk.original_wn_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk.rv_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Produce::up(Emit::tree());
			CommandGrammars::cg_compile_lines(&gprk, cg);
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_FAIL_HL));
			Produce::up(Emit::tree());
			Routines::end(save);
			break;
		}
		case CG_IS_SUBJECT: {
			gpr_kit gprk = UnderstandValueTokens::new_kit();
			packaging_state save = Emit::unused_packaging_state();
			if (UnderstandGeneralTokens::compile_parse_name_head(&save, &gprk, cg->subj_understood, cg, NULL)) {
				CommandGrammars::cg_compile_parse_name_lines(&gprk, cg);
				UnderstandGeneralTokens::compile_parse_name_tail(&gprk);
				Routines::end(save);
			}
			break;
		}
		case CG_IS_VALUE:
			internal_error("iv");
			break;
		case CG_IS_PROPERTY_NAME: {
			gpr_kit gprk = UnderstandValueTokens::new_kit();
			if (cg->cg_prn_iname == NULL) internal_error("PRN PN not ready");
			packaging_state save = Routines::begin(cg->cg_prn_iname);
			UnderstandValueTokens::add_original(&gprk);
			UnderstandValueTokens::add_standard_set(&gprk);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk.original_wn_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, gprk.rv_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Produce::up(Emit::tree());
			CommandGrammars::cg_compile_lines(&gprk, cg);
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_FAIL_HL));
			Produce::up(Emit::tree());
			Routines::end(save);
			break;
		}
	}
}

void CommandGrammars::compile_iv(gpr_kit *gprk, command_grammar *cg) {
	if (cg->first_line == NULL) return;
	LOGIF(GRAMMAR, "Compiling command grammar $G\n", cg);
	current_sentence = cg->where_gv_created;
	UnderstandLines::reset_labels();
	if (cg->cg_is != CG_IS_VALUE) internal_error("not iv");
	CommandGrammars::cg_compile_lines(gprk, cg);
}

@ The special thing about |CG_IS_SUBJECT| grammars is that each is attached
to an inference subject, and when we compile them we recurse up the subject
hierarchy: thus if the red ball is of kind ball which is of kind thing,
then the |parse_name| for the red ball consists of grammar lines specified
for the red ball, then those specified for all balls, and lastly those
specified for all things. (This mimics I6 class-to-instance inheritance.)

=
void CommandGrammars::cg_compile_parse_name_lines(gpr_kit *gprk, command_grammar *cg) {
	inference_subject *subj = cg->subj_understood;

	if (PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object != cg)
		internal_error("link between subject and CG broken");

	LOGIF(GRAMMAR, "Parse_name content for $j:\n", subj);
	CommandGrammars::cg_compile_lines(gprk, PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object);

	inference_subject *infs;
	for (infs = InferenceSubjects::narrowest_broader_subject(subj);
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		if (PARSING_DATA_FOR_SUBJ(infs))
			if (PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_object) {
				LOGIF(GRAMMAR, "And parse_name content inherited from $j:\n", infs);
				CommandGrammars::cg_compile_lines(gprk, PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_object);
			}
	}
}

@ All other grammars are compiled just as they are:

=
void CommandGrammars::cg_compile_lines(gpr_kit *gprk, command_grammar *cg) {
	UnderstandLines::list_assert_ownership(cg->first_line, cg); /* Mark for later indexing */
	CommandGrammars::sort_command_grammar(cg); /* Phase III for the GLs in the CG happens here */
	UnderstandLines::sorted_line_list_compile(gprk, cg->sorted_first_line,
		cg->cg_is, cg, CommandGrammars::cg_is_genuinely_verbal(cg)); /* And Phase IV here */
}

@ All of that was really Phase IV work (compiling), but a very little Phase
III business also happens at this top level. Note that some grammars are
compiled more than once (if a red ball and a blue ball are both of kind
ball, then compiling grammars for them will also involve compiling grammars
for the ball in each case: see above), so the following routine may well be
called more than once for the same CG. We only want to sort once, though, so:

=
void CommandGrammars::sort_command_grammar(command_grammar *cg) {
	if (cg->sorted_first_line == NULL)
		cg->sorted_first_line = UnderstandLines::list_sort(cg->first_line);
}

@h Kinds as GVs.
If the user writes lines in the source text such as

>> Understand "eleventy-one" as 111.

then grammar lines will have to be attached to a kind; in fact, a kind can
have its own |command_grammar| structure attached, which holds a sequence of
such grammar lines. (These are possibilities in addition to those provided
by any GPR existing because of the above routines.)

=
void CommandGrammars::set_parsing_grammar(kind *K, command_grammar *cg) {
	if (K == NULL) return;
	if (Kinds::Behaviour::is_object(K)) internal_error("wrong way to handle object grammar");
	K->construct->understand_as_values = cg;
}

command_grammar *CommandGrammars::get_parsing_grammar(kind *K) {
	if (K == NULL) return NULL;
	if (Kinds::Behaviour::is_object(K)) internal_error("wrong way to handle object grammar");
	return K->construct->understand_as_values;
}

