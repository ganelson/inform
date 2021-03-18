[CommandGrammars::] Command Grammars.

The possible command text following a command verb, or referring to a single
concept or object, is gathered into a "command grammar".

@ Command grammars, or CGs, are used in six excitingly different ways:

@d CG_IS_COMMAND        1  /* for player-typed commands starting with a given verb */
@d CG_IS_TOKEN          2  /* for defining a square-bracketed token used in commands */
@d CG_IS_SUBJECT        3  /* for ways the player can refer to an object or kind */
@d CG_IS_VALUE          4  /* for ways the player can refer to a non-object value */
@d CG_IS_CONSULT        5  /* for topics of conversation, as used in commands like ASK or CONSULT */
@d CG_IS_PROPERTY_NAME  6  /* for ways to refer to property values used adjectivally */

@ Fixed maxima are generally a bad idea in a compiler (what seems excessive in
one decade becomes limiting in the next), but in this plugin we have to
make data tables in formats which can be handled by the Inform 6 compiler.
And that does have two maxima which cannot easily be avoided, so we need to
respect those here as well.

|MAX_ALIASED_COMMANDS| is harmless enough: it's the maximum number of command
verbs which can be synonymous with a single other one, as for example if CONSUME
were synonymous with EAT. Few command verbs need more than four or five, and
many need none at all.

|MAX_LINES_PER_GRAMMAR| is potentially more biting, since it puts a limit on
the number of different command syntaxes which any one command verb can have.
(It applies only to |CG_IS_COMMAND| grammars: the rest are unlimited.) Skilled
Inform 7 writers can get around this with named tokens, but still, in an ideal
world we would not impose a limit here.

@d MAX_ALIASED_COMMANDS 32
@d MAX_LINES_PER_GRAMMAR 32

@ Many of the fields here are relevant only when the CG takes a given |cg_is|
form, so this is not as bloated a structure as it looks.

=
typedef struct command_grammar {
	int cg_is; /* one of the |CG_IS_*| values above */
	struct parse_node *where_cg_created; /* for problem message reports */

	struct determination_type cg_type;

	struct cg_line *first_line; /* linked list in creation order */
	struct cg_line *sorted_first_line; /* and in logical applicability order */
	int slashed; /* slashing has been done */
	int determined; /* determination has been done */

	struct wording command; /* |CG_IS_COMMAND|: what command verb this belongs to */
	struct wording aliased_command[MAX_ALIASED_COMMANDS]; /* ...and other commands synonymous */
	int no_aliased_commands; /* ...and how many of them there are */

	struct wording token_name; /* |CG_IS_TOKEN|: name of this token */

	struct inference_subject *subj_understood; /* |CG_IS_SUBJECT|: what this provides names for */

	struct kind *kind_understood; /* |CG_IS_VALUE|: for which type it names an instance of */

	struct property *prn_understood; /* |CG_IS_PROPERTY_NAME|: which prn this names */

	struct cg_compilation_data compilation_data;
	CLASS_DEFINITION
} command_grammar;

@ We begin as usual with a constructor and some debug log tracing.

=
command_grammar *CommandGrammars::cg_new(int cg_is) {
	command_grammar *cg;
	cg = CREATE(command_grammar);
	cg->command = EMPTY_WORDING;
	cg->first_line = NULL;
	cg->cg_type = DeterminationTypes::new();
	cg->cg_is = cg_is;
	cg->token_name = EMPTY_WORDING;
	cg->no_aliased_commands = 0;
	cg->sorted_first_line = NULL;
	cg->subj_understood = NULL;
	cg->kind_understood = NULL;
	cg->prn_understood = NULL;
	cg->where_cg_created = current_sentence;
	cg->slashed = FALSE;
	cg->determined = FALSE;
	cg->compilation_data = RTCommandGrammars::new_compilation_data();
	return cg;
}

void CommandGrammars::log(command_grammar *cg) {
	LOG("<CG%d:", cg->allocation_id);
	switch(cg->cg_is) {
		case CG_IS_COMMAND:
			if (Wordings::empty(cg->command)) LOG("command=no-verb verb");
			else LOG("command=%W", cg->command);
			break;
		case CG_IS_TOKEN: LOG("token=%W", cg->token_name); break;
		case CG_IS_SUBJECT: LOG("subject=$j", cg->subj_understood); break;
		case CG_IS_VALUE: LOG("value=%u", cg->kind_understood); break;
		case CG_IS_CONSULT: LOG("consult"); break;
		case CG_IS_PROPERTY_NAME: LOG("property=$Y", cg->prn_understood); break;
		default: LOG("<unknown>"); break;
	}
	LOG(">");
}

@h The CG_IS_COMMAND form.
These are the CGs for which CGs were invented, really. Each different
imperative verb a player can type has a CG of the possible syntaxes the
player's command can take after that start.

However, such a CG can also handle a number of "aliases", which are verbs
synonymous to the main one. For instance, the Standard Rules create a CG for
the command PULL but also give it one alias, DRAG.

Command verbs are of course recognised by their wording, or rather, spelling.
(We cannot have two different CGs for the verb MARK as understood in two
different senses, say for marking work and for daubing on a wall.) A special
case is the empty command verb, the one with no letters at all, which is
traditionally called the "no verb verb".[1] All other verbs are "genuinely
verbal".

[1] The Standard Rules do not use the no verb verb, but Inform designers
sometimes do, to allow players to type commands which are meaningful even
when they do not start with a verb. We treat those as being commands which
do in fact start with the invisible "no verb verb".

=
wording CommandGrammars::get_verb_text(command_grammar *cg) {
	return cg->command;
}

int CommandGrammars::cg_is_genuinely_verbal(command_grammar *cg) {
	if ((cg->cg_is == CG_IS_COMMAND) && (Wordings::nonempty(cg->command)))
		return TRUE;
	return FALSE;
}

@ Here we find the CG associated with command |W|, or return null if none
exists (i.e. because no grammar has been created for it). Note that if |W| is
the |EMPTY_WORDING|, then this function returns the "no verb verb".

=
command_grammar *CommandGrammars::for_command_verb(wording W) {
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

@ This does the same, but creating the CG if it does not already exist, so
that it is guaranteed to return a non-|NULL| pointer:

=
command_grammar *CommandGrammars::for_command_verb_creating(wording W) {
	command_grammar *cg = CommandGrammars::for_command_verb(W);
	if (cg) return cg;
	cg = CommandGrammars::cg_new(CG_IS_COMMAND);
	cg->command = W;
	if (Wordings::empty(W)) {
		RTCommandGrammars::create_no_verb_verb(cg);
		LOGIF(GRAMMAR, "CG%d is the no verb verb\n", cg->allocation_id);
	} else {
		LOGIF(GRAMMAR, "CG%d is the command verb %W\n", cg->allocation_id, W);
	}
	return cg;
}

@ We now have functions to add or remove command verbs from a given CG as aliases.
Note that these cannot be called on the no verb verb.

=
void CommandGrammars::add_alias(command_grammar *cg, wording W) {
	if (cg == NULL) internal_error("add alias to null CG");
	if (cg->cg_is != CG_IS_COMMAND) internal_error("add alias to non-command CG");
	if (cg->no_aliased_commands == MAX_ALIASED_COMMANDS) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooManyAliases),
			"this 'understand the command ... as ...' makes too many aliases "
			"for the same command",
			"exceeding the limit of 32.");
	} else {
		cg->aliased_command[cg->no_aliased_commands++] = W;
		LOGIF(GRAMMAR, "Adding alias '%W' to CG%d '%W'\n", W,
			cg->allocation_id, cg->command);
	}
}

@ Removing is trickier, since we might be detaching the main command verb, and
that means that one of the aliases must become the new main verb; or, in the
worst case, there might be no commands left, and in that case we need to empty
the CG of grammar lines so that it can either be ignored or re-used.

=
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

@ This is needed when the designer asks to make actions inaccessible to
commands from the player, with a line like "Understand nothing as the
dropping action":

=
void CommandGrammars::remove_action(command_grammar *cg, action_name *an) {
	if (cg->cg_is == CG_IS_COMMAND)
		CGLines::list_remove(cg, an);
}

@h The CG_IS_TOKEN form.
These are like text substitutions in reverse. For instance, we could define
a token "[suitable colour]", which matches any colour name typed by the player.

Tokens are identified solely by their textual names. There is one and only one
token called "[suitable colour]".

=
command_grammar *CommandGrammars::new_named_token(wording W) {
	command_grammar *cg = CommandGrammars::named_token_by_name(W);
	if (cg == NULL) {
		cg = CommandGrammars::cg_new(CG_IS_TOKEN);
		cg->token_name = W;
		RTCommandGrammars::new_CG_IS_TOKEN(cg, W);
	}
	return cg;
}

command_grammar *CommandGrammars::named_token_by_name(wording W) {
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)
		if ((cg->cg_is == CG_IS_TOKEN) && (Wordings::match(W, cg->token_name)))
			return cg;
	return NULL;
}

@ A slight variation is provided by those which are defined by Inter functions.

=
void CommandGrammars::new_translated_token(wording W, parse_node *id) {
	command_grammar *cg = CommandGrammars::named_token_by_name(W);
	if (cg) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_GrammarTranslatedAlready),
			"this grammar token has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	cg = CommandGrammars::new_named_token(W);
	RTCommandGrammars::set_CG_IS_TOKEN_identifier(cg, Node::get_text(id));
}

@h The CG_IS_SUBJECT form.
Any inference subject can in theory be given a CG, used to parse unusual forms
of its name. If the source reads:

>> Understand "frog" as the Brazilian leaping toad.

then "frog" is added to the CG for the toad's inference subject.

The toad is of course an object, and in fact although there are many other
inference subjects in Inform, this system is used only for objects and their
kinds.[1]

[1] Because in our run-time representation, objects and kinds of objects have
data which makes it convenient for them to provide their own "general parsing
routines", whereas enumeration values do not. So to give exotic names to instances
of non-object kinds we use |CG_IS_VALUE| instead. And in any case numbers or
times of day are not inference subjects anyway, so we would need |CG_IS_VALUE|
in any case for those.

=
command_grammar *CommandGrammars::for_subject(inference_subject *subj) {
	if (PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object != NULL)
		return PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object;
	command_grammar *cg = CommandGrammars::cg_new(CG_IS_SUBJECT);
	PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object = cg;
	cg->subj_understood = subj;
	return cg;
}

@ This is an optimisation to store grammar more efficiently if it turns out
that the names given to the subject are all single words. It saves a few bytes
at run-time, and is just a little faster for the command parser then.

=
void CommandGrammars::take_out_one_word_grammar(command_grammar *cg) {
	if (cg->cg_is != CG_IS_SUBJECT)
		internal_error("One-word optimisation applies only to objects");
	RTCommandGrammarLines::list_take_out_one_word_grammar(cg);
}

@h The CG_IS_VALUE form.
This is used to store names for, say, particular numbers, or enumeration
values. The following examples both involve |CG_IS_VALUE| grammars:
= (text as Inform 7)
Understand "deuce" as 2.
Colour is a kind of value. Red, blue and green are colours.
Understand "scarlet" as red.
=
Note however that a |CG_IS_VALUE| grammar is associated with a kind: unlike
the case of |CG_IS_SUBJECT|, there isn't a different one for each individual
value. There is just one grammar holding all possible fancy names for
different numbers, for example; the |CG_IS_VALUE| grammar for |K_number|.

=
command_grammar *CommandGrammars::for_kind(kind *K) {
	if (K == NULL) internal_error("cannot get CG for null kind");
	if (CommandGrammars::get_parsing_grammar(K) != NULL)
		return CommandGrammars::get_parsing_grammar(K);
	command_grammar *cg = CommandGrammars::cg_new(CG_IS_VALUE);
	if (Kinds::Behaviour::is_object(K)) internal_error("cannot set CG for K_object");
	if (Kinds::Behaviour::is_subkind_of_object(K))
		internal_error("object kinds should not have a CG_IS_VALUE grammar");
	K->construct->understand_as_values = cg;
	cg->kind_understood = K;
	return cg;
}

command_grammar *CommandGrammars::get_parsing_grammar(kind *K) {
	if (K == NULL) return NULL;
	if (Kinds::Behaviour::is_object(K)) internal_error("cannot get CG for K_object");
	return K->construct->understand_as_values;
}

@h The CG_IS_CONSULT form.
Consultation grammars[1] are used to handle topics of conversation and other
free-form textual parts of commands typed by the player: the player can legally
type ASK JETHRO ABOUT ... and put almost anything after ABOUT, and we need ways
to parse that material.

The model here is rather different. Because the topic being discussed could be
almost anything -- maybe Jethro knows about WHEAT PRICES, the HARVEST and
QUANTUM CHROMODYNAMICS (he has hidden depths) -- there is no obvious data
structure in Inform to attach such a grammar to. Instead, code wishing to
create a new consultation should first call //CommandGrammars::prepare_consultation_cg//,
then access the current one being made using //CommandGrammars::get_consultation_cg//.
Note that exactly one consultation can be made at a time.

[1] The term "consultation" goes back to the origins of this feature in the
CONSULT command, which in turn goes right back to a game called "Curses" (1993),
in which players consulted a biographical dictionary of the Meldrew family.

=
command_grammar *consultation_gv = NULL;

void CommandGrammars::prepare_consultation_cg(void) {
	consultation_gv = NULL;
}

command_grammar *CommandGrammars::get_consultation_cg(void) {
	if (consultation_gv == NULL) consultation_gv = CommandGrammars::cg_new(CG_IS_CONSULT);
	return consultation_gv;
}

@h The CG_IS_PROPERTY_NAME form.
A few properties can be recognised by adjectives in the player's commands.
For example, we might allow OPEN or CLOSED in connection with doors. If so,
we may want to allow synonyms or other ways to express this, and so a
property value used adjectivally like this can be given a CG.

=
command_grammar *CommandGrammars::for_prn(property *prn) {
	if (EitherOrProperties::get_parsing_grammar(prn) != NULL)
		return EitherOrProperties::get_parsing_grammar(prn);
	command_grammar *cg = CommandGrammars::cg_new(CG_IS_PROPERTY_NAME);
	EitherOrProperties::set_parsing_grammar(prn, cg);
	cg->prn_understood = prn;
	RTCommandGrammars::new_CG_IS_PROPERTY_NAME(cg, prn);
	return cg;
}

@h The list of grammar lines.
Every CG has a list of CGLs: indeed, this list is the point of the grammar. Here
we test this for emptiness, and provide for adding to it. In general removals
are not possible, but see //CommandGrammars::remove_action// above.

=
int CommandGrammars::is_empty(command_grammar *cg) {
	if ((cg == NULL) || (cg->first_line == NULL)) return TRUE;
	return FALSE;
}

void CommandGrammars::add_line(command_grammar *cg, cg_line *cgl) {
	LOGIF(GRAMMAR, "$G + line: $g\n", cg, cgl);
	if ((cg->cg_is == CG_IS_COMMAND) &&
		(CGLines::list_length(cg) >= MAX_LINES_PER_GRAMMAR)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooManyGrammarLines),
			"this command verb now has too many Understand possibilities",
			"that is, there are too many 'Understand \"whatever ...\" as ...' "
			"which share the same initial word 'whatever'. The best way to "
			"get around this is to try to consolidate some of those lines "
			"together, perhaps by using slashes to combine alternative "
			"wordings, or by defining new grammar tokens [in square brackets].");
	} else {
		CGLines::list_add(cg, cgl);
	}
}

@ As noted above, some CGs are used to refer to objects or values: others not.
This returns the kind if so, or |NULL| if not.

=
kind *CommandGrammars::get_kind_matched(command_grammar *cg) {
	return DeterminationTypes::get_single_kind(&(cg->cg_type));
}

@h Slashing and determining.
CGs are created and then gradually accumulate grammar lines in response to the
stream of "Understand... as..." sentences. Once all of that is done, we have to
make sense of it all, which we do in two phases: "slashing" and "determining".

Slashing is really a grammar-line based activity, so we do no more than pass
the buck down to //Command Grammar Lines//.

=
void CommandGrammars::prepare(void) {
	command_grammar *cg;
	Log::new_stage(I"Slashing command grammar");
	LOOP_OVER(cg, command_grammar)
		if ((cg->slashed == FALSE) && (cg->first_line)) {
			LOGIF(GRAMMAR_CONSTRUCTION, "Slashing $G\n", cg);
			CGLines::slash(cg);
			cg->slashed = TRUE;
		}
	Log::new_stage(I"Determining command grammar");
	LOOP_OVER(cg, command_grammar)
		CommandGrammars::determine(cg, 0);
}

@ Determining is more involved, and is also recursive. What we are doing is
trying to work values a CG can produce, in terms of what value it refers to --
if any. For |CG_IS_COMMAND| grammars, for example, it will be |NULL|, but
for |CG_IS_VALUE|, it might for example be a description meaning "any value
with kind |K_number|.

Determination is hierarchical. To determine a CG we determine each of its
lines, and they in turn determine each of their tokens. But some of those tokens
will themselves be defined by |CG_IS_TOKEN| grammars, and determining those
recurses back here.

=
parse_node *CommandGrammars::determine(command_grammar *cg, int depth) {
	current_sentence = cg->where_cg_created;
	@<If this CG produces a value we have determined already, return that@>;
	@<If recursion went impossibly deep, the CG grammar must be ill-founded@>;

	LOGIF(GRAMMAR_CONSTRUCTION, "Determining $G\n", cg);
	LOG_INDENT;
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg)
		CGLines::cgl_determine(cgl, cg, depth);
	LOG_OUTDENT;
	parse_node *spec_union = NULL;
	@<Take the union of the single-term results of each line@>;

	@<Cache the answer so that we need not determine it again@>;
	return spec_union;
}

@<If this CG produces a value we have determined already, return that@> =
	if (cg->determined) return DeterminationTypes::get_single_term(&(cg->cg_type));

@<If recursion went impossibly deep, the CG grammar must be ill-founded@> =
	if (depth > NUMBER_CREATED(command_grammar)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_GrammarIllFounded),
			"grammar tokens are not allowed to be defined in terms of themselves",
			"either directly or indirectly.");
		return NULL;
	}

@ The "union" referred to below is the widest possible description which
matches the single term of the determination type of each CGL in the list.

@<Take the union of the single-term results of each line@> =
	LOGIF(GRAMMAR_CONSTRUCTION, "Taking union on $G\n", cg);
	LOG_INDENT;
	int first_flag = TRUE;
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg) {
		parse_node *spec_of_line = DeterminationTypes::get_single_term(&(cgl->cgl_type));
		LOG("CGL $g --> $P\n", cgl, spec_of_line);
		if (first_flag) { /* initially no expectations: |spec_union| is meaningless */
			spec_union = spec_of_line; /* so we set it to the first result */
			first_flag = FALSE;
		} else {
			if ((spec_union == NULL) && (spec_of_line == NULL))
				continue; /* we expected to find no result, and did: so no problem */

			if ((spec_union) && (spec_of_line)) {
				if (Dash::compatible_with_description(spec_union, spec_of_line) == ALWAYS_MATCH) {
					spec_union = spec_of_line; /* here |spec_of_line| was a wider type */
					continue;
				}
				if (Dash::compatible_with_description(spec_of_line, spec_union) == ALWAYS_MATCH) {
					continue; /* here |spec_union| was already wide enough */
				}
			}
			@<It is now evident that the lines have incompatible determination types@>;
			break; /* to prevent the problem being repeated for the same grammar */
		}
	}
	LOG_OUTDENT;
	LOGIF(GRAMMAR_CONSTRUCTION, "Result is $P\n", spec_union);

@ In some CGs, it doesn't matter if the lines do different things: for example,
in the CG_IS_COMMAND for the command verb TAKE, "inventory" (void determination
type) and "[things]" (single term determination type) can happily co-exist.

CG_IS_VALUE and CG_IS_SUBJECT are also exceptions because they include grammars
associated with kinds, in which different CGLs may describe different specific
values of that kind. For example, the one for the kind |K_number| might have one
CGL describing the number 17, and another describing 22. There's no good way to
take the union of those numbers.

@<It is now evident that the lines have incompatible determination types@> =
	if ((cg->cg_is == CG_IS_CONSULT) ||
		(cg->cg_is == CG_IS_SUBJECT) ||
		(cg->cg_is == CG_IS_COMMAND) ||
		(cg->cg_is == CG_IS_VALUE)) continue;
	current_sentence = cgl->where_grammar_specified;
	LOG("Offending CGL is $g in $G\n", cgl, cg);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MixedOutcome),
		"grammar tokens must have the same outcome whatever the way they are reached",
		"so writing a line like 'Understand \"within\" or \"next to [something]\" "
		"as \"[my token]\" must be wrong: one way it produces a thing, the other "
		"way it doesn't.");
	spec_union = NULL;

@<Cache the answer so that we need not determine it again@> =
	cg->determined = TRUE;
	DeterminationTypes::set_single_term(&(cg->cg_type), spec_union);

@h Sorting.
The list of lines in a CG needs to be sorted into order before compilation,
to ensure that the player's commands are interpreted correctly whatever order
in which the designer wrote the "Understand... as..." sentences setting it up.

Note that some grammars are compiled more than once, but that we only want to
sort once, so:

=
void CommandGrammars::sort_command_grammar(command_grammar *cg) {
	if (cg->sorted_first_line == NULL)
		cg->sorted_first_line = CGLines::list_sort(cg);
}
