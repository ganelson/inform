[CGLines::] Command Grammar Lines.

A CG line is a list of CG tokens to specify a textual pattern. For example,
"take [something] out" is a CG line of three tokens.

@ CG lines can be as simple as single words, to describe an object in the
world model perhaps, or can be longer prototypes of commands to describe
actions. There are many, many examples in //standard_rules: Command Grammar//,
but for example in:
>> Understand "remove [things inside] from [something]" as removing it from.
...the CG line "[things inside] from [something]" is added to the CG for the
command verb REMOVE. This is a CG line with a //determination_type//
expressing that it describes two |K_object| terms, the first perhaps being
multiple and the second not; and with |resulting_action| set to the
removing it from action. That's a feature only seen in lines for
|CG_IS_COMMAND| grammars, in fact.

=
typedef struct cg_line {
	struct cg_line *next_line; /* linked list in creation order */
	struct cg_line *sorted_next_line; /* and in applicability order */
	int general_sort_bonus; /* temporary values used in grammar line sorting */
	int understanding_sort_bonus;

	struct parse_node *where_grammar_specified; /* where found in source */
	int original_text; /* the word number of the double-quoted grammar text... */
	struct cg_token *tokens; /* ...which is parsed into this list of tokens */
	int lexeme_count; /* number of lexemes, or |-1| if not yet counted */

	struct determination_type cgl_type; /* only correct after determination occurs */
	struct wording understand_when_text; /* match me only when this condition holds */
	struct pcalc_prop *understand_when_prop; /* match me only when this proposition applies */

	int pluralised; /* |CG_IS_SUBJECT|: refers in the plural */

	struct action_name *resulting_action; /* |CG_IS_COMMAND|: the action */
	int reversed; /* |CG_IS_COMMAND|: the two values are in reverse order */
	int mistaken; /* |CG_IS_COMMAND|: is this understood as a mistake? */
	struct wording mistake_response_text; /* if so, reply thus */

	struct cg_line_indexing_data indexing_data;
	struct cg_line_compilation_data compilation_data;
	CLASS_DEFINITION
} cg_line;

@ =
cg_line *CGLines::new(wording W, action_name *ac,
	cg_token *token_list, int reversed, int pluralised) {
	if (token_list == NULL) internal_error("no token list for CGL");
	cg_line *cgl;
	cgl = CREATE(cg_line);
	@<Initialise listing data@>;
	cgl->where_grammar_specified = current_sentence;
	cgl->original_text = Wordings::first_wn(W);
	cgl->tokens = token_list;
	cgl->lexeme_count = -1; /* no count made as yet */

	cgl->cgl_type = DeterminationTypes::new();
	cgl->understand_when_text = EMPTY_WORDING;
	cgl->understand_when_prop = NULL;

	cgl->pluralised = pluralised;

	cgl->resulting_action = ac;
	cgl->reversed = reversed;
	cgl->mistaken = FALSE;
	cgl->mistake_response_text = EMPTY_WORDING;

	cgl->compilation_data = RTCommandGrammarLines::new_compilation_data(cgl);
	cgl->indexing_data = CommandsIndex::new_id(cgl);

	if (ac) Actions::add_gl(ac, cgl);
	return cgl;
}

@ A command grammar has a list of CGLs. But in fact it has two lists, with the
same contents, but in different orders. The unsorted list holds them in order
of creation; the sorted one in order of matching priority at run-time. This
sorting is a big issue: see //CGLines::list_sort// below.

@d LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg)
	for (cg_line *cgl = cg->first_line; cgl; cgl = cgl->next_line)
@d LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
	for (cg_line *cgl = cg->sorted_first_line; cgl; cgl = cgl->sorted_next_line)

@d UNCALCULATED_BONUS -1000000

@<Initialise listing data@> =
	cgl->next_line = NULL;
	cgl->sorted_next_line = NULL;
	cgl->general_sort_bonus = UNCALCULATED_BONUS;
	cgl->understanding_sort_bonus = UNCALCULATED_BONUS;

@ While we're talking loops... CG lines are lists of CG tokens:

@d LOOP_THROUGH_CG_TOKENS(cgt, cgl)
	for (cg_token *cgt = cgl?(cgl->tokens):NULL; cgt; cgt = cgt->next_token)

@ To count how many lines a CG has so far, we use the unsorted list, since we
don't know if the sorted one has been made yet:

=
int CGLines::list_length(command_grammar *cg) {
	int c = 0;
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg) c++;
	return c;
}

@ CG lines are added to a CG by being put at the end of the unsorted list.
(Once sorting has occurred, it is too late.)

=
void CGLines::list_add(command_grammar *cg, cg_line *new_gl) {
	if (cg->sorted_first_line) internal_error("too late to add lines to CG");
	new_gl->next_line = NULL;
	if (cg->first_line == NULL) {
		cg->first_line = new_gl;
	} else {
		cg_line *posn = cg->first_line;
		while (posn->next_line) posn = posn->next_line;
		posn->next_line = new_gl;
	}
}

@ In rare cases CG lines are also removed, but again, before sorting occurs.

=
void CGLines::list_remove(command_grammar *cg, action_name *find) {
	if (cg->sorted_first_line) internal_error("too late to remove lines from CG");
	cg_line *prev = NULL, *posn = cg->first_line;
	while (posn) {
		if (posn->resulting_action == find) {
			LOGIF(GRAMMAR_CONSTRUCTION, "Removing grammar line: $g\n", posn);
			if (prev) prev->next_line = posn->next_line;
			else cg->first_line = posn->next_line;
		} else {
			prev = posn;
		}
		posn = posn->next_line;
	}
}

@ We make no attempt to pretty-print a complete breakdown of CG, and instead
log just enough to identify which one it is:

=
void CGLines::log(cg_line *cgl) {
	LOG("<CGL%d:%W>", cgl->allocation_id, Wordings::one_word(cgl->original_text));
}

@h Relevant only for CG_IS_VALUE lines.
In |CG_IS_VALUE| grammars, the lines are ways to refer to a specific value
which is not an object, and we record which value the line refers to here.

=
void CGLines::set_single_term(cg_line *cgl, parse_node *cgl_value) {
	DeterminationTypes::set_single_term(&(cgl->cgl_type), cgl_value);
}

@h Conditional lines.
A few grammar lines take effect only when some circumstance holds: most I7
conditions are valid to specify this, with the notation "Understand ... as
... when ...". However, we want to protect new authors from mistakes
like this:

>> Understand "mate" as Fred when asking Fred to do something: ...

where the condition couldn't test anything useful because it's not yet
known what the action will be.

=
<understand-condition> ::=
	<s-non-action-condition> |  ==> { pass 1 }
	<s-condition> |             ==> @<Issue PM_WhenAction problem@>; ==> { -, NULL };
	...                         ==> @<Issue PM_BadWhen problem@>; ==> { -, NULL };

@<Issue PM_WhenAction problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_WhenAction),
		"the condition after 'when' involves the current action",
		"but this can never work, because when Inform is still trying to "
		"understand a command, the current action isn't yet decided on.");

@<Issue PM_BadWhen problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadWhen),
		"the condition after 'when' makes no sense to me",
		"although otherwise this worked - it is only the part after 'when' "
		"which I can't follow.");

@ Such CGLs have an "understand when" text. We have to keep this as text and
typecheck it with Dash only when it will actually be used; this is where
that happens.

=
void CGLines::set_understand_when(cg_line *cgl, wording W) {
	cgl->understand_when_text = W;
}
parse_node *CGLines::get_understand_cond(cg_line *cgl) {
	if (Wordings::nonempty(cgl->understand_when_text)) {
		current_sentence = cgl->where_grammar_specified;
		if (<understand-condition>(cgl->understand_when_text)) {
			parse_node *spec = <<rp>>;
			if ((spec) && (Dash::validate_conditional_clause(spec) == FALSE)) {
				@<Issue PM_BadWhen problem@>;
				spec = NULL;
			}
			return spec;
		}
	}
	return NULL;
}

@ More subtly, a CGL might be given as a way to describe, say, "an open door".
This will go into the CG associated with the kind |K_door|, but the line will
have the proposition ${\it open}(x)$ attached to it: the description then
matches an object $x$ only when this proposition holds. (It must always be
a proposition with a single free variable.)

=
void CGLines::set_understand_prop(cg_line *cgl, pcalc_prop *prop) {
	cgl->understand_when_prop = prop;
}

@ Use of either feature makes a CGL "conditional":

=
int CGLines::conditional(cg_line *cgl) {
	if ((Wordings::nonempty(cgl->understand_when_text)) || (cgl->understand_when_prop))
		return TRUE;
	return FALSE;
}

@h Mistakes.
These are grammar lines used in command CGs for commands which are accepted
but only in order to print nicely worded rejections.

=
void CGLines::set_mistake(cg_line *cgl, wording MW) {
	cgl->mistaken = TRUE;
	cgl->mistake_response_text = MW;
}

@h Single word optimisation.
The grammars used to parse names of objects are normally compiled into
|parse_name| routines. But the I6 parser also uses the |name| property,
and it is advantageous to squeeze as much as possible into |name| and
as little as possible into |parse_name|. The only possible candidates
for that are grammar lines consisting of single unconditional words, as
detected by the following function:

=
int CGLines::cgl_contains_single_unconditional_word(cg_line *cgl) {
	if ((cgl->tokens)
		&& (cgl->tokens->next_token == NULL)
		&& (cgl->tokens->slash_class == 0)
		&& (CGTokens::is_literal(cgl->tokens))
		&& (cgl->pluralised == FALSE)
		&& (CGLines::conditional(cgl) == FALSE))
		return Wordings::first_wn(CGTokens::text(cgl->tokens));
	return -1;
}

@h Slashing the line.
Slashing is the process of dealing with forward slash tokens in a CG line.
It's done one line at a time, each line being independent of all others for
this purpose, so:

=
void CGLines::slash(command_grammar *cg) {
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg) {
		current_sentence = cgl->where_grammar_specified;
		@<Annotate the CG tokens with slash-class and slash-dash-dash@>;
		@<Throw a problem if slash has been used with non-literal tokens@>;
		@<Calculate the lexeme count@>;
	}
}

@ The tokenised text of a CG line can contain "slashes":
= (text)
given in Inform source text   "take up/in all washing/laundry/linen"
tokenised                     take up / in all washing / laundry / linen
=
This is a run of 10 CG tokens, three of them forward slashes which are actually
markers to indicate disjunction: thus the three tokens "up / all" intend to
match just one word of the player's command, which can be either UP or ALL.

Slashing consolidates this line to 7 CG tokens, giving each one a |slash_class|
value to show which group it belongs to. 0 means that a token is not part of a
slashed group; otherwise, the group number should be shared by all the tokens
in the group, and should be different from that of other groups. Thus:
= (text)
                     take up in all washing laundry linen
slash_class          0    1  1  0   2       2       2
=
In addition, Inform allows the syntax |--| to mean the empty word, or rather,
to mean that it is permissible for the player's command to miss this word out.
If one option in a group is |--| then this does not get a token of its own,
but instead results in the |slash_dash_dash| field to be set. For example,
consider "near --/the/that tree/shrub":
= (text)
                       near  the  that  tree  shrub
slash_class            0     1    1     2     2
slash_dash_dash        FALSE TRUE FALSE FALSE FALSE
=
Note that |--| occurring on its own, outside of a run of slashes, has by
definition no effect, and disappears without trace in this process.

@<Annotate the CG tokens with slash-class and slash-dash-dash@> =
	LOOP_THROUGH_CG_TOKENS(cgt, cgl) cgt->slash_class = 0;

	int alternatives_group = 0;
	cg_token *class_start = NULL;
	LOOP_THROUGH_CG_TOKENS(cgt, cgl) {
		if ((cgt->next_token) && (Wordings::length(CGTokens::text(cgt->next_token)) == 1) &&
			(Lexer::word(Wordings::first_wn(CGTokens::text(cgt->next_token))) ==
				FORWARDSLASH_V)) {
			if (cgt->slash_class == 0) {
				class_start = cgt; alternatives_group++; /* start new equiv class */
				class_start->slash_dash_dash = FALSE;
			}
			cgt->slash_class = alternatives_group;
			if (cgt->next_token->next_token)
				cgt->next_token->next_token->slash_class = alternatives_group;
			if ((cgt->next_token->next_token) &&
				(Wordings::length(CGTokens::text(cgt->next_token->next_token)) == 1) &&
				(Lexer::word(Wordings::first_wn(CGTokens::text(cgt->next_token->next_token))) ==
					DOUBLEDASH_V)) {
				class_start->slash_dash_dash = TRUE;
				cgt->next_token = cgt->next_token->next_token->next_token; /* excise both */
			} else {
				cgt->next_token = cgt->next_token->next_token; /* excise slash */
			}
		}
	}

@<Throw a problem if slash has been used with non-literal tokens@> =
	LOOP_THROUGH_CG_TOKENS(cgt, cgl)
		if ((cgt->slash_class > 0) &&
			(CGTokens::is_literal(cgt) == FALSE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_OverAmbitiousSlash),
				"the slash '/' can only be used between single literal words",
				"so 'underneath/under/beneath' is allowed but 'beneath/[florid "
				"ways to say under]/under' isn't.");
			break;
		}

@ It is now easy to count the number of "lexemes", that's to say, the number
of groups arising from the calculations just done. In this example there are 4:
= (text)
                     take   up in   all   washing laundry linen
slash_class          0      1  1    0     2       2       2
lexemes              +--+   +---+   +-+   +-------------------+
=
And in this one 3:
= (text)
                     near   the  that   tree  shrub
slash_class          0      1    1      2     2
lexemes              +--+   +-------+   +---------+
=

@<Calculate the lexeme count@> =
	cgl->lexeme_count = 0;
	LOOP_THROUGH_CG_TOKENS(cgt, cgl) {
		int i = cgt->slash_class;
		if (i > 0)
			while ((cgt->next_token) &&
				(cgt->next_token->slash_class == i))
				cgt = cgt->next_token;
		cgl->lexeme_count++;
	}

@h Determining the line.
Here the aim is to find the //determination_type// of a CGL. Sneakily, though,
we also take the opportunity to calculate its two "sorting bonuses", which
affect how the list will be arranged when it is compiled.

@d CGL_SCORE_TOKEN_RANGE 10
@d CGL_SCORE_BUMP (CGL_SCORE_TOKEN_RANGE*CGL_SCORE_TOKEN_RANGE)

=
void CGLines::cgl_determine(cg_line *cgl, command_grammar *cg, int depth) {
	LOGIF(GRAMMAR_CONSTRUCTION, "Determining $g\n", cgl);
	LOG_INDENT;
	current_sentence = cgl->where_grammar_specified;
	cgl->understanding_sort_bonus = 0;
	cgl->general_sort_bonus = 0;

	cg_token *first = cgl->tokens; /* start from first token... */
	if ((CommandGrammars::cg_is_genuinely_verbal(cg)) && (first))
		first = first->next_token; /* ...unless it's in a nonempty command verb grammar */

	int line_length = 0;
	for (cg_token *cgt = first; cgt; cgt = cgt->next_token) line_length++;

	int multiples = 0;
	@<Make the actual calculations@>;

	if (multiples > 1)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MultipleMultiples),
			"there can be at most one token in any line which can match multiple things",
			"so you'll have to remove one of the 'things' tokens and make it a 'something' "
			"instead.");

	if ((cg->cg_is != CG_IS_COMMAND) &&
		(DeterminationTypes::get_no_values_described(&(cgl->cgl_type)) >= 2))
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TwoValuedToken),
			"there can be at most one varying part in the definition of a named token",
			"so 'Understand \"button [a number]\" as \"[button indication]\"' is allowed "
			"but 'Understand \"button [a number] on [something]\" as \"[button "
			"indication]\"' is not.");

	LOG_OUTDENT;
	if (Log::aspect_switched_on(GRAMMAR_CONSTRUCTION_DA)) {
		LOG("dt = "); DeterminationTypes::log(&(cgl->cgl_type));
		LOG(", lexeme count %d, sort bonus %d, understanding sort bonus %d\n",
			cgl->lexeme_count, cgl->general_sort_bonus, cgl->understanding_sort_bonus);
	}
}

@ The general sort bonus is $Rs_0 + s_1$, where $R$ is the |CGL_SCORE_TOKEN_RANGE|
and $s_0$, $s_1$ are the scores for the first and second tokens describing values,
which are such that $0\leq s_i<R$; or if none of the $n$ tokens describes a value,
the GSB is $R^2n$, which is guaranteed to be much larger.

However, there is also an understanding sort bonus, which is really a penalty
incurred by "[text]" tokens -- which are very free-form topics of conversation.
A "[text]" at token position $i$, where $0\leq i<n$, scores $R^2(i-R^2) + (n - 1 - i)$.
Given that $i$ is small and $R^2$ is big, this is basically a huge negative
number, but is such that a "[text]" earlier in the line is penalised just a
little bit more than a "[text]" later.

For $R=10$, the following might thus happen. (I've simplified this table by
having the individual tokens all score 1, but in fact they can score a range
of small numbers: see //CGTokens::score_bonus//.)
= (text)
                        n       s_0     s_1     gsb     usb
inventory               1       --      --      100     0
[thing]                 1       1       --      10      0
[thing] from [thing]    3       1       1       11      0
umbrage over [text]     3       1       --      10      -9800
umbrage [text]          2       1       --      10      -9900
umbrage [text] issue    3       1       --      10      -9899
=
It is roughly true that if we sort these lines in descending order of the
sum of those scores, they come out in the order we need to try them when
parsing the player's command at run-time. For the exact sorting rules, see below.

@<Make the actual calculations@> =
	int nulls_count = 0, pos = 0;
	for (cg_token *cgt = first; cgt; cgt = cgt->next_token) {
		parse_node *spec = CGTokens::determine(cgt, depth);
		int score = CGTokens::score_bonus(cgt);
		if ((score < 0) || (score >= CGL_SCORE_TOKEN_RANGE))
			internal_error("token score out of range");
		LOGIF(GRAMMAR_CONSTRUCTION, "token %d/%d: <%W> --> $P (score %d)\n",
			pos+1, line_length, CGTokens::text(cgt), spec, score);
		if (spec) {
			@<Text tokens contribute also to the understanding sort bonus@>;
			int score_multiplier = 1;
			if (DeterminationTypes::get_no_values_described(&(cgl->cgl_type)) == 0)
				score_multiplier = CGL_SCORE_TOKEN_RANGE;
			DeterminationTypes::add_term(&(cgl->cgl_type), spec,
				CGTokens::is_multiple(cgt));
			cgl->general_sort_bonus += score*score_multiplier;
		} else nulls_count++;

		if (CGTokens::is_multiple(cgt)) multiples++;
		pos++;
	}
	if (nulls_count == line_length)
		cgl->general_sort_bonus = CGL_SCORE_BUMP*nulls_count;

@ This looks for a "[text]" token, which is the Inform syntax to mean one
which parses to a |K_understanding| match.

@<Text tokens contribute also to the understanding sort bonus@> =
	if ((Specifications::is_kind_like(spec)) &&
		(K_understanding) &&
		(Kinds::eq(Specifications::to_kind(spec), K_understanding))) { /* "[text]" token */
		int usb_contribution = pos - CGL_SCORE_BUMP;
		if (usb_contribution >= 0) usb_contribution = -1; /* very unlikely to happen */
		usb_contribution = CGL_SCORE_BUMP*usb_contribution + (line_length-1-pos);
		cgl->understanding_sort_bonus += usb_contribution;
	}

@h Sorting the lines in a grammar.
The CGLs in a grammar are insertion sorted into a sorted version. This is not
the controversial part: //CGLines::cg_line_must_precede// is the part
people argued over for years.

=
cg_line *CGLines::list_sort(command_grammar *cg) {
	cg_line *unsorted_head = cg->first_line;
	if (unsorted_head == NULL) return NULL;

	cg_line *sorted_head = unsorted_head;
	sorted_head->sorted_next_line = NULL;

	cg_line *cgl = unsorted_head;
	while (cgl->next_line) {
		cgl = cgl->next_line;
		cg_line *cgl2 = sorted_head;
		if (CGLines::cg_line_must_precede(cg, cgl, cgl2)) {
			sorted_head = cgl;
			cgl->sorted_next_line = cgl2;
			continue;
		}
		while (cgl2) {
			cg_line *cgl3 = cgl2;
			cgl2 = cgl2->sorted_next_line;
			if (cgl2 == NULL) {
				cgl3->sorted_next_line = cgl;
				break;
			}
			if (CGLines::cg_line_must_precede(cg, cgl, cgl2)) {
				cgl3->sorted_next_line = cgl;
				cgl->sorted_next_line = cgl2;
				break;
			}
		}
	}
	return sorted_head;
}

@ As noted, the following function was responsible for quite some debate in
the early days of Inform 7. The issue here is that the command parser at
run-time accepts the first match it can make, when given a list of options.[1]
Because of that, it is essential to put these options in the right order, or
some can never happen. For example,
= (text)
ask [someone] about [something]
ask [someone] about [text]
=
have to be that way around, because any comnand which matches the first line
here also matches the second. Putting these lines into order used to be part
of the craft of the Inform 6 programmer, but it was always difficult to do,
and Inform 7 aimed to liberate authors from the need to do this. A long
period of aggrieved bug-reporting followed, when it turned out that Inform 7
made different decisions than authors accustomed to Inform 6 would like.
We ended up with the following algorithm, which has not changed since at
least 2010, and will not change again.

[1] Well... roughly. See //CommandParserKit: Parser// for the gory details.

@ The code in //CGLines::cgl_determine// looked as if we would decide
if line |L1| precedes |L2| by adding up their score bonuses, and letting the
higher scorer go first. That is in fact nearly equivalent to the following,
but not quite.

=
int CGLines::cg_line_must_precede(command_grammar *cg, cg_line *L1, cg_line *L2) {
	@<Perform some sanity checks@>;
	@<Nothing precedes itself@>;
	@<Lower understanding penalties precede higher ones@>;
	@<Shorter precedes longer in command verbs, longer precedes shorter otherwise@>;
	@<Mistakes precede correct readings@>;
	@<Higher sort bonuses precede lower ones@>;
	@<More specific determinations precede less specific ones@>;
	@<Conditional readings precede unconditional readings@>;
	@<Lines created earlier precede lines creater later in the source text@>;
}

@<Perform some sanity checks@> =
	if ((L1 == NULL) || (L2 == NULL))
		internal_error("tried to sort null CGLs");
	if ((L1->lexeme_count == -1) || (L2->lexeme_count == -1))
		internal_error("tried to sort unslashed CGLs");
	if ((L1->general_sort_bonus == UNCALCULATED_BONUS) ||
		(L2->general_sort_bonus == UNCALCULATED_BONUS))
		internal_error("tried to sort uncalculated CGLs");

@<Nothing precedes itself@> =
	if (L1 == L2) return FALSE;

@ "[text]" tokens have such an extreme effect that they are the first thing
to look at. The following guarantees that any line without "[text]" tokens
always precedes any line with them: see the calculation of the USB above.

Thus |"read chapter [text]"| precedes |"read [text]"| precedes |"read [something]"|.

@<Lower understanding penalties precede higher ones@> =
	if (L1->understanding_sort_bonus > L2->understanding_sort_bonus) return TRUE;
	if (L1->understanding_sort_bonus < L2->understanding_sort_bonus) return FALSE;

@ It seems reasonable that the length of the CG line (in lexemes, not tokens)
might be a sorting criterion, but what we do looks asymmetric. Why should
CG_IS_COMMAND grammars have the opposite convention from all others?

This arises because the command parser we use at run time works that way. The
difference is that when the parser is working on an entire command -- thus,
working through a |CG_IS_COMMAND| grammar -- it always knows how many words
it has to match. If the player has typed TAKE FROG FROM AQUARIUM, the parser
has to make sense of all of the words. It needs to consider the possibility
"take [something]" before "take [something] from [something]" because there
might be an object called "frog fram aquarium".

On the other hand, if it is parsing a |CG_IS_TOKEN| grammar, it is trying to
match as many words as possible from a stream of words that will probably then
continue. It is therefore important to try to match WATERY CASCADE EFFECT
before WATERY CASCADE when looking at text like WATERY CASCADE EFFECT
IMPRESSES PEOPLE, so that we match three words not two. So in these
situations, longer possibilities must be tried first.

@<Shorter precedes longer in command verbs, longer precedes shorter otherwise@> =
	if (cg->cg_is == CG_IS_COMMAND) { /* command grammar: shorter beats longer */
		if (L1->lexeme_count < L2->lexeme_count) return TRUE;
		if (L1->lexeme_count > L2->lexeme_count) return FALSE;
	} else { /* all other grammars: longer beats shorter */
		if (L1->lexeme_count < L2->lexeme_count) return FALSE;
		if (L1->lexeme_count > L2->lexeme_count) return TRUE;
	}

@ Throughout 2006, the rule that mistakes beat non-mistakes was in fact the
most important, taking priority over length or understanding sort bonus.
This seemed logical that since mistakes were exceptional cases, they would be
better checked earlier before moving on to general cases. However, an
example provided by Eric Eve showed that although this was logically correct,
the run-time command parser would try to auto-complete lengthy mistakes and
thus fail to check subsequent commands.

For this reason, |"look behind [something]"| as a mistake needs to be checked
after |"look"|, or else the command parser will respond to LOOK by replying
"What do you want to look behind?" -- and then saying that you are mistaken.

@<Mistakes precede correct readings@> =
	if ((L1->mistaken) && (L2->mistaken == FALSE)) return TRUE;
	if ((L1->mistaken == FALSE) && (L2->mistaken)) return FALSE;

@ This next rule is a lexeme-based tiebreaker. We only get here if there
are the same number of lexemes in the two CGLs being compared. Lines in which
all tokens are literal words, like "tossed egg salad", are scored so highly
that they will always come first: see //CGLines::cgl_determine//.
But if one of the tokens is not literal, then we score it in such a way that
the specificity of the tokens is what decides. The first token is more important
than the second, and a more specific token comes before a lower one.

See //CGTokens::determine// for how the score of an individual token
is worked out.

@<Higher sort bonuses precede lower ones@> =
	if (L1->general_sort_bonus > L2->general_sort_bonus) return TRUE;
	if (L1->general_sort_bonus < L2->general_sort_bonus) return FALSE;

@ By now the lines are extremely similar, but for example we might have
"put [thing] in [container]" and "put [thing] in [thing]". The first must
precede the second because |K_container| is a subkind of |K_thing|.

@<More specific determinations precede less specific ones@> =
	int cs = DeterminationTypes::must_precede(&(L1->cgl_type), &(L2->cgl_type));
	if (cs != NOT_APPLICABLE) return cs;

@ The motivation for this one is similar to the case of "when" clauses for
rules in rulebooks: it ensures that a match of |"draw [thing]"| when some
condition holds beats a match of |"draw [thing]"| at any time, and this is
necessary under the strict superset principle.

@<Conditional readings precede unconditional readings@> =
	if ((CGLines::conditional(L1)) &&
		(CGLines::conditional(L2) == FALSE)) return TRUE;
	if ((CGLines::conditional(L1) == FALSE) &&
		(CGLines::conditional(L2))) return FALSE;

@ Getting down to here looks difficult, given the number of things about |L1|
and |L2| which have to match up -- same USB, GSB, number of lexemes,
number of resulting types, equivalent resulting types, same mistake and
conditional status -- but in fact it isn't all that uncommon. Equivalent pairs
produced by the Standard Rules include:
= (text)
get off [something]
get in/into/on/onto [something]

turn on [something]
turn [something] on
=
Only the second of these pairs leads to ambiguity, and even then only if
an object has a name like ON VISION ON -- perhaps a book about the antique
BBC children's television programme "Vision On" -- so that the command
TURN ON VISION ON would match both of the alternative CGLs.

@<Lines created earlier precede lines creater later in the source text@> =
	if (L1->allocation_id < L2->allocation_id) return TRUE;
	return FALSE;
