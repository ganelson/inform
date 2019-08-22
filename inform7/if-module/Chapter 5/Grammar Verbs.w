[PL::Parsing::Verbs::] Grammar Verbs.

A grammar verb is not literally a verb, as the name is a hangover
from the way I6 defines grammar. It might be said to be a necklace onto which
we thread the sea-shells of grammar lines. Each grammar verb has its own
purpose: to match various possibilities (one for each grammar line) against
text aimed at a particular result. For instance, all run time commands
beginning with TAKE are parsed with a single grammar verb. If we
create a new grammar token, "[polite remark]", for use in other grammar,
then that too will have its own "grammar verb". If we define the word
"eleventy-one" as meaning the number 111, it will be added to a grammar
verb attached to the kind "number" which parses eccentric names for
number values. And so on. Probably a better name for this structure would
be simply "grammar", but that might be confusing in other ways, and
anyway the ship has sailed.

@h Definitions.

@ There are five different sorts of grammar verb, then, and only the first
of these is associated with a genuine typed-by-the-player command verb:

@d GV_IS_COMMAND 1  /* an imperative verbal command at run-time */
@d GV_IS_TOKEN   2  /* a square-bracketed token in other grammar */
@d GV_IS_OBJECT  3  /* a noun phrase at run time: a name for an object */
@d GV_IS_VALUE   4  /* a noun phrase at run time: a name for a value */
@d GV_IS_CONSULT 5  /* a pattern to match in part of a command (such as "consult") */
@d GV_IS_PROPERTY_NAME 6  /* a noun phrase at run time: a name for an either/or pval */

@ The following maxima are imposed by the I6 compiler:

@d MAX_ALIASED_COMMANDS 32
@d MAX_LINES_PER_COMMAND 32

=
typedef struct grammar_verb {
	int gv_is; /* one of the five values above */

	struct grammar_type gv_type;

	struct grammar_line *first_line; /* linked list in creation order */
	struct grammar_line *sorted_first_line; /* and in logical applicability order */

	struct wording command; /* |GV_IS_COMMAND|: word number at which command found */
	struct wording aliased_command[MAX_ALIASED_COMMANDS]; /* ...and other commands synonymous */
	int no_aliased_commands; /* ...and how many of them there are */

	struct wording name; /* |GV_IS_TOKEN|: name of this token */
	struct inter_name *gv_line_iname;

	struct inference_subject *subj_understood; /* |GV_IS_OBJECT|: what this provides names for */

	struct kind *kind_understood; /* |GV_IS_VALUE|: for which type it names an instance of */
	struct inter_name *gv_parse_name_iname;

	struct property *prn_understood; /* |GV_IS_PROPERTY_NAME|: which prn this names */
	struct inter_name *gv_prn_iname; /* the relevant GPR is called this */

	struct parse_node *where_gv_created; /* for problem message reports */

	struct inter_name *gv_consult_iname; /* for the consult parsing routine if needed */
	struct text_stream *gv_I6_identifier; /* when a token is delegated to an I6 routine */

	int slashed; /* slashing has been done */
	int determined; /* determination has been done */

	MEMORY_MANAGEMENT
} grammar_verb;

@ A few imperative verbs are reserved for Inform testing, such as SHOWME.
We record those as instances of the following:

=
typedef struct reserved_command_verb {
	text_stream *reserved_text;
	MEMORY_MANAGEMENT
} reserved_command_verb;

@ We begin as usual with a constructor and some debug log tracing.

=
grammar_verb *PL::Parsing::Verbs::gv_new(int gv_is) {
	grammar_verb *gv;
	gv = CREATE(grammar_verb);
	gv->command = EMPTY_WORDING;
	gv->first_line = NULL;
	gv->gv_type = PL::Parsing::Tokens::Types::new(FALSE);
	gv->gv_is = gv_is;
	gv->name = EMPTY_WORDING;
	gv->no_aliased_commands = 0;
	gv->sorted_first_line = NULL;
	gv->subj_understood = NULL;
	gv->kind_understood = NULL;
	gv->gv_parse_name_iname = NULL;
	gv->prn_understood = NULL;
	gv->where_gv_created = current_sentence;
	gv->gv_consult_iname = NULL;
	gv->gv_prn_iname = NULL;
	gv->gv_line_iname = NULL;
	gv->gv_I6_identifier = Str::new();
	gv->slashed = FALSE;
	gv->determined = FALSE;
	return gv;
}

void PL::Parsing::Verbs::log(grammar_verb *gv) {
	LOG("<GV%d:", gv->allocation_id);
	switch(gv->gv_is) {
		case GV_IS_COMMAND:
			if (Wordings::empty(gv->command)) LOG("command=no-verb verb");
			else LOG("command=%W", gv->command);
			break;
		case GV_IS_TOKEN: LOG("token=%W", gv->name); break;
		case GV_IS_OBJECT: LOG("object"); break;
		case GV_IS_VALUE: LOG("value=$u", gv->kind_understood); break;
		case GV_IS_CONSULT: LOG("consult"); break;
		case GV_IS_PROPERTY_NAME: LOG("property-name"); break;
		default: LOG("<unknown>"); break;
	}
	LOG(">");
}

@h Command words.
Some GVs are used to represent the command grammar for imperative verbs
used by the player at run-time. Such a GV handles multiple commands, which
are considered equivalent at run-time: the first of these is the official
command word, and the rest are "aliases". For instance, the Standard Rules
create a GV for the command PULL with one alias, DRAG. (This somewhat
asymmetric approach is used because it matches the way I6 |Verb| declarations
are laid out.)

A complication is that one GV is permitted to be a special case: the
so-called "no verb verb", whose main command word is empty and which
can have no aliases. This is used to parse verbless commands at run-time:
for instance, the I7 designer can specify that a command consisting only
of a number followed by the word GO should cause some action, and this
is implemented not with a command verb but using I6's hooks for verbless
commands. The grammar "[number] go" is attached as a grammar line to
the "no verb verb", which is distinguished by having its command word
number set to |-1|. Note that the "no verb verb" exists only in runs of
NI where it has been needed: the Standard Rules do not use it.

Command GVs other than the "no verb verb" are said to be "genuinely
verbal".

=
wording PL::Parsing::Verbs::get_verb_text(grammar_verb *gv) {
	return gv->command;
}

int PL::Parsing::Verbs::gv_is_genuinely_verbal(grammar_verb *gv) {
	if ((gv->gv_is == GV_IS_COMMAND) && (Wordings::nonempty(gv->command)))
		return TRUE;
	return FALSE;
}

@ The next routine finds, or if necessary creates, a GV for a given command
word encountered without any indication that it should alias another. Note
that calling this with word number |-1| finds, or creates, the "no verb
verb".

=
grammar_verb *PL::Parsing::Verbs::find_or_create_command(wording W) {
	grammar_verb *gv = PL::Parsing::Verbs::find_command(W);

	if (gv) return gv;

	gv = PL::Parsing::Verbs::gv_new(GV_IS_COMMAND);
	gv->command = W;

	if (Wordings::empty(W)) {
		inter_name *iname = Hierarchy::find(NO_VERB_VERB_DEFINED_HL);
		Emit::named_numeric_constant(iname, (inter_t) 1);
	}
	else LOGIF(GRAMMAR_CONSTRUCTION, "GV%d has verb %W\n", gv->allocation_id, W);

	return gv;
}

@ By contrast, this routine merely finds a GV, or returns null if none
exists with the given command word.

=
grammar_verb *PL::Parsing::Verbs::find_command(wording W) {
	grammar_verb *gv;
	LOOP_OVER(gv, grammar_verb)
		if (gv->gv_is == GV_IS_COMMAND) {
			if (Wordings::empty(W)) {
				if (Wordings::empty(gv->command)) return gv;
			} else {
				if (Wordings::match(gv->command, W)) return gv;
				for (int i=0; i<gv->no_aliased_commands; i++)
					if (Wordings::match(gv->aliased_command[i], W))
						return gv;
			}
		}
	return NULL;
}

@ We now have routines to add or remove commands from a given GV. Removing
is the tricky case, since detaching the main command word means that one
of the aliases must become the new main command; or, in the worst case,
that there are no commands left, in which case we need to empty the GV
of grammar lines so that it can either be ignored or re-used (in the
event that the designer, having cancelled the old meaning of the command,
now supplies new ones).

It is not possible to add to, or remove from, the "no verb verb".

=
void PL::Parsing::Verbs::add_command(grammar_verb *gv, wording W) {
	if (gv == NULL)
		internal_error("tried to add alias command to null GV");
	if (gv->gv_is != GV_IS_COMMAND)
		internal_error("tried to add alias command to non-command GV");
	if (gv->no_aliased_commands == MAX_ALIASED_COMMANDS) {
		Problems::Issue::sentence_problem(_p_(PM_TooManyAliases),
			"this 'understand the command ... as ...' makes too many aliases "
			"for the same command",
			"exceeding the limit of 32.");
		return;
	}
	gv->aliased_command[gv->no_aliased_commands++] = W;
	LOGIF(GRAMMAR, "Adding alias '%W' to G%d '%W'\n", W, gv->allocation_id, gv->command);
}

void PL::Parsing::Verbs::remove_command(grammar_verb *gv, wording W) {
	if (gv == NULL)
		internal_error("tried to detach alias command from null GV");
	if (gv->gv_is != GV_IS_COMMAND)
		internal_error("tried to detach alias command from non-command GV");
	LOGIF(GRAMMAR, "Detaching verb '%W' from grammar\n", W);
	if (gv == NULL)	return;
	if (Wordings::match(gv->command, W)) {
		LOGIF(GRAMMAR, "Detached verb is the head-verb\n");
		if (gv->no_aliased_commands == 0) {
			gv->first_line = NULL;
			LOGIF(GRAMMAR, "Which had no aliases: clearing grammar to NULL\n");
		} else {
			gv->command = gv->aliased_command[--(gv->no_aliased_commands)];
			LOGIF(GRAMMAR, "Which had aliases: making new head-verb '%W'\n",
				gv->command);
		}
	} else {
		LOGIF(GRAMMAR, "Detached verb is one of the aliases\n");
		for (int i=0; i<gv->no_aliased_commands; i++) {
			if (Wordings::match(gv->aliased_command[i], W)) {
				for (int j=i; j<gv->no_aliased_commands-1; j++)
					gv->aliased_command[j] = gv->aliased_command[j+1];
				gv->no_aliased_commands--;
				break;
			}
		}
	}
}

void PL::Parsing::Verbs::index_command_aliases(OUTPUT_STREAM, grammar_verb *gv) {
	if (gv == NULL) return;
	int i, n = gv->no_aliased_commands;
	for (i=0; i<n; i++)
		WRITE("/%N", Wordings::first_wn(gv->aliased_command[i]));
}

void PL::Parsing::Verbs::remove_action(grammar_verb *gv, action_name *an) {
	if (gv->gv_is != GV_IS_COMMAND) return;
	gv->first_line = PL::Parsing::Lines::list_remove(gv->first_line, an);
}

@ Command GVs are destined to be compiled into |Verb| directives, as follows.

=
packaging_state PL::Parsing::Verbs::gv_compile_Verb_directive_header(grammar_verb *gv, inter_name *array_iname) {
	if (gv->gv_is != GV_IS_COMMAND)
		internal_error("tried to compile Verb from non-command GV");
	if (gv->first_line == NULL)
		internal_error("compiling Verb for empty grammar");

	packaging_state save = Emit::named_verb_array_begin(array_iname, K_value);

	if (Wordings::empty(gv->command))
		Emit::array_dword_entry(I"no.verb");
	else {
		TEMPORARY_TEXT(vt);
		WRITE_TO(vt, "%W", Wordings::one_word(Wordings::first_wn(gv->command)));
		if (PL::Parsing::Verbs::command_verb_reserved(vt)) {
			current_sentence = gv->where_gv_created;
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, gv->command);
			Problems::Issue::handmade_problem(_p_(BelievedImpossible));
			Problems::issue_problem_segment(
				"You wrote %1, but %2 is a built-in Inform testing verb, which "
				"means it is reserved for Inform's own use and can't be used "
				"for ordinary play purposes. %PThe verbs which are reserved in "
				"this way are all listed in the alphabetical catalogue on the "
				"Actions Index page.");
			Problems::issue_problem_end();
		}
		DISCARD_TEXT(vt);
		TEMPORARY_TEXT(WD);
		WRITE_TO(WD, "%N", Wordings::first_wn(gv->command));
		Emit::array_dword_entry(WD);
		DISCARD_TEXT(WD);
		for (int i=0; i<gv->no_aliased_commands; i++) {
			TEMPORARY_TEXT(WD);
			WRITE_TO(WD, "%N", Wordings::first_wn(gv->aliased_command[i]));
			Emit::array_dword_entry(WD);
			DISCARD_TEXT(WD);
		}
	}
	return save;
}

@ Reserved verb names are collated as the I6 template files are read:

=
void PL::Parsing::Verbs::reserve(text_stream *verb_name) {
	reserved_command_verb *rcv = CREATE(reserved_command_verb);
	rcv->reserved_text = Str::new();
	PL::Parsing::Verbs::normalise_cv_to(rcv->reserved_text, verb_name);
	PL::Actions::Index::test_verb(rcv->reserved_text);
}

int PL::Parsing::Verbs::command_verb_reserved(text_stream *verb_tried) {
	reserved_command_verb *rcv;
	TEMPORARY_TEXT(normalised_vt);
	PL::Parsing::Verbs::normalise_cv_to(normalised_vt, verb_tried);
	LOOP_OVER(rcv, reserved_command_verb)
		if (Str::eq(normalised_vt, rcv->reserved_text))
			return TRUE;
	DISCARD_TEXT(normalised_vt);
	return FALSE;
}

void PL::Parsing::Verbs::normalise_cv_to(OUTPUT_STREAM, text_stream *from) {
	Str::clear(OUT);
	for (int i=0; (i<31) && (i<Str::len(from)); i++)
		PUT(Characters::tolower(Str::get_at(from, i)));
}

@ The "Commands available to the player" portion of the Actions index page
is, in effect, an alphabetised merge of the GLs found within the command GVs.
GLs for the "no verb verb" appear under the special headword "0" (which
is not displayed); otherwise GLs appear under the main command word, and
aliases are shown with references like: "drag", same as "pull".

One routine takes a GV and creates suitable entries for the Actions index
to process; the other two routines act upon any such entries once they are
needed.

=
void PL::Parsing::Verbs::make_command_index_entries(OUTPUT_STREAM, grammar_verb *gv) {
	if ((gv->gv_is == GV_IS_COMMAND) && (gv->first_line)) {
		if (Wordings::empty(gv->command))
			PL::Actions::Index::vie_new_from(OUT, L"0", gv, NORMAL_COMMAND);
		else
			PL::Actions::Index::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(gv->command)), gv, NORMAL_COMMAND);
		for (int i=0; i<gv->no_aliased_commands; i++)
			PL::Actions::Index::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(gv->aliased_command[i])), gv, ALIAS_COMMAND);
	}
}

void PL::Parsing::Verbs::index_normal(OUTPUT_STREAM, grammar_verb *gv, text_stream *headword) {
	PL::Parsing::Lines::sorted_list_index_normal(OUT, gv->sorted_first_line, headword);
}

void PL::Parsing::Verbs::index_alias(OUTPUT_STREAM, grammar_verb *gv, text_stream *headword) {
	WRITE("&quot;%S&quot;, <i>same as</i> &quot;%N&quot;",
		headword, Wordings::first_wn(gv->command));
	TEMPORARY_TEXT(link);
	WRITE_TO(link, "%N", Wordings::first_wn(gv->command));
	Index::below_link(OUT, link);
	DISCARD_TEXT(link);
	HTML_TAG("br");
}

@h Named grammar tokens.
These are like text substitutions in reverse. For instance, we could define
a token "[suitable colour]". These are identified solely by their textual
names (e.g., "suitable colour").

=
grammar_verb *PL::Parsing::Verbs::named_token_new(wording W) {
	grammar_verb *gv = PL::Parsing::Verbs::named_token_by_name(W);
	if (gv == NULL) {
		gv = PL::Parsing::Verbs::gv_new(GV_IS_TOKEN);
		gv->name = W;
		package_request *PR = Hierarchy::local_package(NAMED_TOKENS_HAP);
		gv->gv_line_iname = Hierarchy::make_iname_in(PARSE_LINE_FN_HL, PR);
	}
	return gv;
}

grammar_verb *PL::Parsing::Verbs::named_token_by_name(wording W) {
	grammar_verb *gv;
	LOOP_OVER(gv, grammar_verb)
		if ((gv->gv_is == GV_IS_TOKEN) && (Wordings::match(W, gv->name)))
			return gv;
	return NULL;
}

@ =
void PL::Parsing::Verbs::index_tokens(OUTPUT_STREAM) {
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "anybody", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "anyone", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "anything", NULL, NULL, I"things_token", "same as \"[thing]\"");
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "other things", NULL, NULL, I"things_token", NULL);
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "somebody", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "someone", NULL, NULL, I"someone_token", NULL);
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "something", NULL, NULL, I"things_token", "same as \"[thing]\"");
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "something preferably held", NULL, NULL, I"things_token", NULL);
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "text", NULL, NULL, I"text_token", NULL);
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "things", NULL, NULL, I"things_token", NULL);
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "things inside", NULL, NULL, I"things_token", NULL);
	PL::Parsing::Verbs::index_tokens_for(OUT, EMPTY_WORDING, "things preferably held", NULL, NULL, I"things_token", NULL);
	grammar_verb *gv;
	LOOP_OVER(gv, grammar_verb)
		if (gv->gv_is == GV_IS_TOKEN)
			PL::Parsing::Verbs::index_tokens_for(OUT, gv->name, NULL,
				gv->where_gv_created, gv->sorted_first_line, NULL, NULL);
}

void PL::Parsing::Verbs::index_tokens_for(OUTPUT_STREAM, wording W, char *special, parse_node *where,
	grammar_line *defns, text_stream *help, char *explanation) {
	HTMLFiles::open_para(OUT, 1, "tight");
	WRITE("\"[");
	if (special) WRITE("%s", special); else WRITE("%+W", W);
	WRITE("]\"");
	if (where) Index::link(OUT, Wordings::first_wn(ParseTree::get_text(where)));
	if (Str::len(help) > 0) Index::DocReferences::link(OUT, help);
	if (explanation) WRITE(" - %s", explanation);
	HTML_CLOSE("p");
	if (defns) PL::Parsing::Lines::index_list_for_token(OUT, defns);
}


@ A slight variation is provided by those which are defined by I6 routines.

=
void PL::Parsing::Verbs::translates(wording W, parse_node *p2) {
	grammar_verb *gv;
	LOOP_OVER(gv, grammar_verb)
		if ((gv->gv_is == GV_IS_TOKEN) && (Wordings::match(W, gv->name))) {
			Problems::Issue::sentence_problem(_p_(PM_GrammarTranslatedAlready),
				"this grammar token has already been translated",
				"so there must be some duplication somewhere.");
			return;
		}
	gv = PL::Parsing::Verbs::named_token_new(W);
	WRITE_TO(gv->gv_I6_identifier, "%N", Wordings::first_wn(ParseTree::get_text(p2)));
}

inter_name *PL::Parsing::Verbs::i6_token_as_iname(grammar_verb *gv) {
	if (Str::len(gv->gv_I6_identifier) > 0)
		return Hierarchy::find_by_name(gv->gv_I6_identifier);
	if (gv->gv_line_iname == NULL) internal_error("no token GPR");
	return gv->gv_line_iname;
}

@h Consultation grammars.
These are used for grammar included as a column of a table or in a
conditional match. The terminology goes back to the early days of I6, when
CONSULT was a command capable of parsing arbitrary text, something which
a game called Curses made heavy use of.

=
grammar_verb *PL::Parsing::Verbs::consultation_new(void) {
	grammar_verb *gv;
	gv = PL::Parsing::Verbs::gv_new(GV_IS_CONSULT);
	return gv;
}

@h Subject parsing grammars.
Each inference subject can optionally have a GV, used to parse unusual forms of
its name (though of course many subjects are never parsed at all, so this is
only used in practice for objects and their kinds). The following routine finds
or creates such.

=
grammar_verb *PL::Parsing::Verbs::for_subject(inference_subject *subj) {
	grammar_verb *gv;
	if (PF_S(parsing, subj)->understand_as_this_object != NULL)
		return PF_S(parsing, subj)->understand_as_this_object;
	gv = PL::Parsing::Verbs::gv_new(GV_IS_OBJECT);
	PF_S(parsing, subj)->understand_as_this_object = gv;
	gv->subj_understood = subj;
	return gv;
}

void PL::Parsing::Verbs::take_out_one_word_grammar(grammar_verb *gv) {
	if (gv->gv_is != GV_IS_OBJECT)
		internal_error("One-word optimisation applies only to objects");
	gv->first_line = PL::Parsing::Lines::list_take_out_one_word_grammar(gv->first_line);
}

int PL::Parsing::Verbs::allow_mixed_lines(grammar_verb *gv) {
	if ((gv->gv_is == GV_IS_OBJECT) || (gv->gv_is == GV_IS_VALUE))
		return TRUE;
	return FALSE;
}

@h Data type parsing grammars.
Each kind can optionally have a GV, used to parse unusual forms of
its literals. The following routine finds or creates this.

=
grammar_verb *PL::Parsing::Verbs::for_kind(kind *K) {
	grammar_verb *gv;
	if (PL::Parsing::Verbs::get_parsing_grammar(K) != NULL)
		return PL::Parsing::Verbs::get_parsing_grammar(K);
	gv = PL::Parsing::Verbs::gv_new(GV_IS_VALUE);
	PL::Parsing::Verbs::set_parsing_grammar(K, gv);
	gv->kind_understood = K;
	return gv;
}

@h Property name parsing grammars.
Only either/or properties can have a GV, used to parse unusual forms of
the alternatives as used when properties are describing objects. The
following routine finds or creates this for a given property.

=
grammar_verb *PL::Parsing::Verbs::for_prn(property *prn) {
	grammar_verb *gv;
	if (Properties::EitherOr::get_parsing_grammar(prn) != NULL)
		return Properties::EitherOr::get_parsing_grammar(prn);
	gv = PL::Parsing::Verbs::gv_new(GV_IS_PROPERTY_NAME);
	Properties::EitherOr::set_parsing_grammar(prn, gv);
	gv->prn_understood = prn;
	gv->gv_prn_iname = Hierarchy::make_iname_in(EITHER_OR_GPR_FN_HL, Properties::package(prn));
	return gv;
}

@h The list of grammar lines.
Every GV has a list of GLs: indeed, this list is really the grammar. Here
we test this for emptiness, and provide for adding to it. Removals are not
possible.

=
int PL::Parsing::Verbs::is_empty(grammar_verb *gv) {
	if ((gv == NULL) || (gv->first_line == NULL)) return TRUE;
	return FALSE;
}

void PL::Parsing::Verbs::add_line(grammar_verb *gv, grammar_line *gl) {
	LOGIF(GRAMMAR, "Adding grammar line $g to verb $G\n", gl, gv);
	if ((gv->gv_is == GV_IS_COMMAND) &&
		(PL::Parsing::Lines::list_length(gv->first_line) >= MAX_LINES_PER_COMMAND)) {
		Problems::Issue::sentence_problem(_p_(PM_TooManyGrammarLines),
			"this command verb now has too many Understand possibilities",
			"that is, there are too many 'Understand \"whatever ...\" as ...' "
			"which share the same initial word 'whatever'. The best way to "
			"get around this is to try to consolidate some of those lines "
			"together, perhaps by using slashes to combine alternative "
			"wordings, or by defining new grammar tokens [in square brackets].");
		return;
	}
	gv->first_line = PL::Parsing::Lines::list_add(gv->first_line, gl);
}

@ Each GV has the potential to carry a kind made up of the number of
values produced, and what their types are. This is only really meaningful
for the GVs trying to express a single value: the following routine returns
|UNKNOWN_NT| unless that's the case.

=
kind *PL::Parsing::Verbs::get_data_type_as_token(grammar_verb *gv) {
	return PL::Parsing::Tokens::Types::get_data_type_as_token(&(gv->gv_type));
}

@ Some tokens require suitable I6 routines to have already been compiled,
if they are to work nicely: the following routine goes through the tokens
by exploring each GV in turn.

=
void PL::Parsing::Verbs::compile_conditions(void) {
	grammar_verb *gv;
	LOOP_OVER(gv, grammar_verb)	{
		current_sentence = gv->where_gv_created;
		PL::Parsing::Lines::line_list_compile_condition_tokens(gv->first_line);
	}
}

@h Grammar Preparation.
This simply causes Phases I and II of grammar processing to take place, one
after the other.

=
void PL::Parsing::Verbs::prepare(void) {
	PL::Parsing::Verbs::gv_slash_all();
	PL::Parsing::Verbs::gv_determine_all();
}

@h Phase I: Slash Grammar.
Slashing is really a grammar-line based activity, so we do no more than
pass the buck down to the list of grammar lines.

=
void PL::Parsing::Verbs::gv_slash_all(void) {
	grammar_verb *gv;
	Log::new_stage(I"Slashing grammar (G1)");
	LOOP_OVER(gv, grammar_verb) {
		if (gv->slashed == FALSE) {
			LOGIF(GRAMMAR_CONSTRUCTION, "Slashing $G\n", gv);
			PL::Parsing::Lines::line_list_slash(gv->first_line);
			gv->slashed = TRUE;
		}
	}
}

@h Phase II: Determining Grammar.
Again, at this top level we are really only calling downwards.

=
void PL::Parsing::Verbs::gv_determine_all(void) {
	grammar_verb *gv;
	Log::new_stage(I"Determining grammar (G2)");
	LOOP_OVER(gv, grammar_verb)
		if ((gv->determined == FALSE) && (gv->first_line)) {
			current_sentence = gv->where_gv_created;
			PL::Parsing::Verbs::determine(gv, 0);
			gv->determined = TRUE;
		}
}

parse_node *PL::Parsing::Verbs::determine(grammar_verb *gv, int depth) {
	parse_node *spec_union = NULL;
	current_sentence = gv->where_gv_created;

	if (PL::Parsing::Tokens::Types::has_return_type(&(gv->gv_type)))
		return PL::Parsing::Tokens::Types::get_single_type(&(gv->gv_type));

	if (depth > NUMBER_CREATED(grammar_verb)) {
		Problems::Issue::sentence_problem(_p_(PM_GrammarIllFounded),
			"grammar tokens are not allowed to be defined in terms of "
			"themselves",
			"either directly or indirectly.");
		return NULL;
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Determining $G\n", gv);

	spec_union = PL::Parsing::Lines::line_list_determine(gv->first_line, depth,
		gv->gv_is, gv, PL::Parsing::Verbs::gv_is_genuinely_verbal(gv));

	LOGIF(GRAMMAR_CONSTRUCTION, "Result of verb $G is $P\n", gv, spec_union);

	PL::Parsing::Tokens::Types::set_single_type(&(gv->gv_type), spec_union);

	return spec_union;
}

@h Phases III and IV: Sort and Compile Grammar.
At this highest level phases III and IV are intermingled, in that Phase III
always precedes Phase IV for any given list of grammar lines, but each GV
goes through both Phase III and IV before the next begins Phase III. So it
would not be appropriate to print banners like "Phase III begins here"
in the debugging log.

Finally, though, some substantive work to do: because it is the GV which
records the purpose of the grammar in question, we must compile a suitable
I6 context for the grammar to appear within.

Four of the five kinds of GV are compiled by the routine below: the fifth
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

inter_name *PL::Parsing::Verbs::grammar_constant(int N, int V) {
	inter_name *iname = Hierarchy::find(N);
	Emit::named_numeric_constant(iname, 1);
	return iname;
}

void PL::Parsing::Verbs::compile_all(void) {
	grammar_verb *gv;
	PL::Parsing::Verbs::gv_slash_all();
	PL::Parsing::Verbs::gv_determine_all();

	Log::new_stage(I"Sorting and compiling non-value grammar (G3, G4)");

	VERB_DIRECTIVE_REVERSE_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_REVERSE_HL, 1);
	VERB_DIRECTIVE_SLASH_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_SLASH_HL, 1);
	VERB_DIRECTIVE_DIVIDER_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_DIVIDER_HL, 1);
	VERB_DIRECTIVE_RESULT_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_RESULT_HL, 2);
	VERB_DIRECTIVE_SPECIAL_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_SPECIAL_HL, 3);
	VERB_DIRECTIVE_NUMBER_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_NUMBER_HL, 4);
	VERB_DIRECTIVE_NOUN_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_NOUN_HL, 5);
	VERB_DIRECTIVE_MULTI_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_MULTI_HL, 6);
	VERB_DIRECTIVE_MULTIINSIDE_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_MULTIINSIDE_HL, 7);
	VERB_DIRECTIVE_MULTIHELD_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_MULTIHELD_HL, 8);
	VERB_DIRECTIVE_HELD_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_HELD_HL, 9);
	VERB_DIRECTIVE_CREATURE_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_CREATURE_HL, 10);
	VERB_DIRECTIVE_TOPIC_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_TOPIC_HL, 11);
	VERB_DIRECTIVE_MULTIEXCEPT_iname = PL::Parsing::Verbs::grammar_constant(VERB_DIRECTIVE_MULTIEXCEPT_HL, 12);

	LOOP_OVER(gv, grammar_verb)
		if (gv->gv_is == GV_IS_TOKEN)
			PL::Parsing::Verbs::compile(gv); /* makes GPRs for designed tokens */

	LOOP_OVER(gv, grammar_verb)
		if (gv->gv_is == GV_IS_COMMAND)
			PL::Parsing::Verbs::compile(gv); /* makes |Verb| directives */

	LOOP_OVER(gv, grammar_verb)
		if (gv->gv_is == GV_IS_OBJECT)
			PL::Parsing::Verbs::compile(gv); /* makes routines for use in |parse_name| */

	LOOP_OVER(gv, grammar_verb)
		if (gv->gv_is == GV_IS_CONSULT)
			PL::Parsing::Verbs::compile(gv); /* routines to parse snippets, used as values */

	LOOP_OVER(gv, grammar_verb)
		if (gv->gv_is == GV_IS_PROPERTY_NAME)
			PL::Parsing::Verbs::compile(gv); /* makes routines for use in |parse_name| */

	PL::Parsing::Lines::compile_slash_gprs();
}

@ The following routine unites, so far as possible, the different forms of
GV by compiling each of them as a sandwich: top slice, filling, bottom slice.
The interesting case is of a GV representing names for an object: the
name-behaviour needs to be inherited from the object's kind, and so on up
the kinds hierarchy, but this is a case where I7's kind hierarchy does not
agree with I6's class hierarchy. I6 has no (nice) way to inherit |parse_name|
behaviour from a class to an instance. So we will simply pile up extra
fillings into the sandwich. The order of these is important: by getting
in first, grammar for the instance takes priority; its immediate kind has
next priority, and so on up the hierarchy.

=
void PL::Parsing::Verbs::compile(grammar_verb *gv) {
	if (gv->first_line == NULL) return;

	LOGIF(GRAMMAR, "Compiling grammar verb $G\n", gv);

	current_sentence = gv->where_gv_created;

	PL::Parsing::Lines::reset_labels();
	switch(gv->gv_is) {
		case GV_IS_COMMAND: {
			package_request *PR = Hierarchy::synoptic_package(COMMANDS_HAP);
			inter_name *array_iname = Hierarchy::make_iname_in(VERB_DECLARATION_ARRAY_HL, PR);
			packaging_state save = 
				PL::Parsing::Verbs::gv_compile_Verb_directive_header(gv, array_iname);
			PL::Parsing::Verbs::gv_compile_lines(NULL, gv);
			Emit::array_end(save);
			break;
		}
		case GV_IS_TOKEN: {
			gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
			if (gv->gv_line_iname == NULL) internal_error("gv token not ready");
			packaging_state save = Routines::begin(gv->gv_line_iname);
			PL::Parsing::Tokens::Values::add_original(&gprk);
			PL::Parsing::Tokens::Values::add_standard_set(&gprk);
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk.original_wn_s);
				Emit::val_iname(K_value, Hierarchy::find(WN_HL));
			Emit::up();
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk.rv_s);
				Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Emit::up();
			PL::Parsing::Verbs::gv_compile_lines(&gprk, gv);
			Emit::inv_primitive(Produce::opcode(RETURN_BIP));
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
			Emit::up();
			Routines::end(save);
			break;
		}
		case GV_IS_CONSULT: {
			gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
			inter_name *iname = PL::Parsing::Tokens::General::consult_iname(gv);
			packaging_state save = Routines::begin(iname);
			PL::Parsing::Tokens::Values::add_range_calls(&gprk);
			PL::Parsing::Tokens::Values::add_original(&gprk);
			PL::Parsing::Tokens::Values::add_standard_set(&gprk);
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
				Emit::val_symbol(K_value, gprk.range_from_s);
			Emit::up();
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk.original_wn_s);
				Emit::val_iname(K_value, Hierarchy::find(WN_HL));
			Emit::up();
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk.rv_s);
				Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Emit::up();
			PL::Parsing::Verbs::gv_compile_lines(&gprk, gv);
			Emit::inv_primitive(Produce::opcode(RETURN_BIP));
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
			Emit::up();
			Routines::end(save);
			break;
		}
		case GV_IS_OBJECT: {
			gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
			packaging_state save = Emit::unused_packaging_state();
			if (PL::Parsing::Tokens::General::compile_parse_name_head(&save, &gprk, gv->subj_understood, gv, NULL)) {
				PL::Parsing::Verbs::gv_compile_parse_name_lines(&gprk, gv);
				PL::Parsing::Tokens::General::compile_parse_name_tail(&gprk);
				Routines::end(save);
			}
			break;
		}
		case GV_IS_VALUE:
			internal_error("iv");
			break;
		case GV_IS_PROPERTY_NAME: {
			gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
			if (gv->gv_prn_iname == NULL) internal_error("PRN PN not ready");
			packaging_state save = Routines::begin(gv->gv_prn_iname);
			PL::Parsing::Tokens::Values::add_original(&gprk);
			PL::Parsing::Tokens::Values::add_standard_set(&gprk);
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk.original_wn_s);
				Emit::val_iname(K_value, Hierarchy::find(WN_HL));
			Emit::up();
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk.rv_s);
				Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Emit::up();
			PL::Parsing::Verbs::gv_compile_lines(&gprk, gv);
			Emit::inv_primitive(Produce::opcode(RETURN_BIP));
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
			Emit::up();
			Routines::end(save);
			break;
		}
	}
}

void PL::Parsing::Verbs::compile_iv(gpr_kit *gprk, grammar_verb *gv) {
	if (gv->first_line == NULL) return;
	LOGIF(GRAMMAR, "Compiling grammar verb $G\n", gv);
	current_sentence = gv->where_gv_created;
	PL::Parsing::Lines::reset_labels();
	if (gv->gv_is != GV_IS_VALUE) internal_error("not iv");
	PL::Parsing::Verbs::gv_compile_lines(gprk, gv);
}

@ The special thing about |GV_IS_OBJECT| grammars is that each is attached
to an inference subject, and when we compile them we recurse up the subject
hierarchy: thus if the red ball is of kind ball which is of kind thing,
then the |parse_name| for the red ball consists of grammar lines specified
for the red ball, then those specified for all balls, and lastly those
specified for all things. (This mimics I6 class-to-instance inheritance.)

=
void PL::Parsing::Verbs::gv_compile_parse_name_lines(gpr_kit *gprk, grammar_verb *gv) {
	inference_subject *subj = gv->subj_understood;

	if (PF_S(parsing, subj)->understand_as_this_object != gv)
		internal_error("link between subject and GV broken");

	LOGIF(GRAMMAR, "Parse_name content for $j:\n", subj);
	PL::Parsing::Verbs::gv_compile_lines(gprk, PF_S(parsing, subj)->understand_as_this_object);

	inference_subject *infs;
	for (infs = InferenceSubjects::narrowest_broader_subject(subj);
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		if (PF_S(parsing, infs))
			if (PF_S(parsing, infs)->understand_as_this_object) {
				LOGIF(GRAMMAR, "And parse_name content inherited from $j:\n", infs);
				PL::Parsing::Verbs::gv_compile_lines(gprk, PF_S(parsing, infs)->understand_as_this_object);
			}
	}
}

@ All other grammars are compiled just as they are:

=
void PL::Parsing::Verbs::gv_compile_lines(gpr_kit *gprk, grammar_verb *gv) {
	PL::Parsing::Lines::list_assert_ownership(gv->first_line, gv); /* Mark for later indexing */
	PL::Parsing::Verbs::sort_grammar_verb(gv); /* Phase III for the GLs in the GV happens here */
	PL::Parsing::Lines::sorted_line_list_compile(gprk, gv->sorted_first_line,
		gv->gv_is, gv, PL::Parsing::Verbs::gv_is_genuinely_verbal(gv)); /* And Phase IV here */
}

@ All of that was really Phase IV work (compiling), but a very little Phase
III business also happens at this top level. Note that some grammars are
compiled more than once (if a red ball and a blue ball are both of kind
ball, then compiling grammars for them will also involve compiling grammars
for the ball in each case: see above), so the following routine may well be
called more than once for the same GV. We only want to sort once, though, so:

=
void PL::Parsing::Verbs::sort_grammar_verb(grammar_verb *gv) {
	if (gv->sorted_first_line == NULL)
		gv->sorted_first_line = PL::Parsing::Lines::list_sort(gv->first_line);
}

@h Kinds as GVs.
If the user writes lines in the source text such as

>> Understand "eleventy-one" as 111.

then grammar lines will have to be attached to a kind; in fact, a kind can
have its own |grammar_verb| structure attached, which holds a sequence of
such grammar lines. (These are possibilities in addition to those provided
by any GPR existing because of the above routines.)

=
void PL::Parsing::Verbs::set_parsing_grammar(kind *K, grammar_verb *gv) {
	if (K == NULL) return;
	if (Kinds::Compare::le(K, K_object)) internal_error("wrong way to handle object grammar");
	K->construct->understand_as_values = gv;
}

grammar_verb *PL::Parsing::Verbs::get_parsing_grammar(kind *K) {
	if (K == NULL) return NULL;
	if (Kinds::Compare::le(K, K_object)) internal_error("wrong way to handle object grammar");
	return K->construct->understand_as_values;
}

