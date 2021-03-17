[UnderstandLines::] Command Grammar Lines.

A CG line is a list of CG tokens to specify a textual pattern. For example,
"take [something] out" is a CG line of three tokens.

@ CG lines can be as simple as single words, to describe an object in the
world model perhaps, or can be longer prototypes of commands to describe
actions. There are many, many examples in //standard_rules: Command Grammar//,
but for example in:
>> Understand "remove [things inside] from [something]" as removing it from.
the CG line "[things inside] from [something]" is added to the CG for the
command verb REMOVE. This is a CG line with a //determination_type//
expressing that it describes two |K_object| terms, the first perhaps being
multiple and the second not; and with |resulting_action| set to the
removing it from action. That's a feature only seen in lines for
|CG_IS_COMMAND| grammars, in fact.

CG lines are lists of CG tokens: "[things inside]", FROM, and "[something]"
are all tokens. But Inform does not have a |cg_token| type because these are
instead stored as |TOKEN_NT| nodes in the parse tree, and are the children
of the |tokens| node belonging to the CG line.

A small amount of disjunction is allowed in a grammar line: for instance,
"look in/inside/into [something]" consists of five tokens, but only three
so-called lexemes, basic units to be matched. (The first is LOOK, the second
can be any one of IN, INSIDE or INTO, and the third is an object in scope.)
The |lexeme_count| field caches the count of these since it is fiddly to
calculate, and useful when sorting grammar lines into applicability order.

The individual tokens are stored simply as parse tree nodes of type
|TOKEN_NT|, and are the children of the node |cgl->tokens|, which is why
(for now, anyway) there is no grammar token structure.

=
typedef struct cg_line {
	struct cg_line *next_line; /* linked list in creation order */
	struct cg_line *sorted_next_line; /* and in applicability order */
	int general_sort_bonus; /* temporary values used in grammar line sorting */
	int understanding_sort_bonus;

	struct parse_node *where_grammar_specified; /* where found in source */
	int original_text; /* the word number of the double-quoted grammar text... */
	struct parse_node *tokens; /* ...which is parsed into this list of tokens */
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
cg_line *UnderstandLines::new(wording W, action_name *ac,
	parse_node *token_list, int reversed, int pluralised) {
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

	cgl->compilation_data = RTCommandGrammarLines::new_cd(cgl);
	cgl->indexing_data = CommandsIndex::new_id(cgl);

	if (ac) Actions::add_gl(ac, cgl);
	return cgl;
}

@ A command grammar has a list of CGLs. But in fact it has two lists, with the
same contents, but in different orders. The unsorted list holds them in order
of creation; the sorted one in order of matching priority at run-time. This
sorting is a big issue: see //UnderstandLines::list_sort// below.

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

@ To count how many lines a CG has so far, we use the unsorted list, since we
don't know if the sorted one has been made yet:

=
int UnderstandLines::list_length(command_grammar *cg) {
	int c = 0;
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg) c++;
	return c;
}

@ CG lines are added to a CG by being put at the end of the unsorted list.
(Once sorting has occurred, it is too late.)

=
void UnderstandLines::list_add(command_grammar *cg, cg_line *new_gl) {
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
void UnderstandLines::list_remove(command_grammar *cg, action_name *find) {
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
void UnderstandLines::log(cg_line *cgl) {
	LOG("<CGL%d:%W>", cgl->allocation_id, Node::get_text(cgl->tokens));
}

@h Relevant only for CG_IS_VALUE lines.
In |CG_IS_VALUE| grammars, the lines are ways to refer to a specific value
which is not an object, and we record which value the line refers to here.

=
void UnderstandLines::set_single_term(cg_line *cgl, parse_node *cgl_value) {
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
void UnderstandLines::set_understand_when(cg_line *cgl, wording W) {
	cgl->understand_when_text = W;
}
parse_node *UnderstandLines::get_understand_cond(cg_line *cgl) {
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
void UnderstandLines::set_understand_prop(cg_line *cgl, pcalc_prop *prop) {
	cgl->understand_when_prop = prop;
}

@ Use of either feature makes a CGL "conditional":

=
int UnderstandLines::conditional(cg_line *cgl) {
	if ((Wordings::nonempty(cgl->understand_when_text)) || (cgl->understand_when_prop))
		return TRUE;
	return FALSE;
}

@h Mistakes.
These are grammar lines used in command CGs for commands which are accepted
but only in order to print nicely worded rejections.

=
void UnderstandLines::set_mistake(cg_line *cgl, wording MW) {
	cgl->mistaken = TRUE;
	cgl->mistake_response_text = MW;
	RTCommandGrammarLines::set_mistake(cgl, MW);
}

@h Single word optimisation.
The grammars used to parse names of objects are normally compiled into
|parse_name| routines. But the I6 parser also uses the |name| property,
and it is advantageous to squeeze as much as possible into |name| and
as little as possible into |parse_name|. The only possible candidates
for that are grammar lines consisting of single unconditional words, as
detected by the following function:

=
int UnderstandLines::cgl_contains_single_unconditional_word(cg_line *cgl) {
	parse_node *pn = cgl->tokens->down;
	if ((pn)
		&& (pn->next == NULL)
		&& (Annotations::read_int(pn, slash_class_ANNOT) == 0)
		&& (Annotations::read_int(pn, grammar_token_literal_ANNOT))
		&& (cgl->pluralised == FALSE)
		&& (UnderstandLines::conditional(cgl) == FALSE))
		return Wordings::first_wn(Node::get_text(pn));
	return -1;
}

@h Phase I: Slash Grammar.
Slashing is an activity carried out on a per-grammar-line basis, so to slash
a list of CGLs we simply slash each CGL in turn.

=
void UnderstandLines::line_list_slash(command_grammar *cg) {
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg)
		UnderstandLines::slash_cg_line(cgl);
}

@ Now the actual slashing process, which does not descend to tokens. We
remove any slashes, and fill in positive numbers in the |qualifier| field
corresponding to non-singleton equivalence classes. Thus "take up/in all
washing/laundry/linen" begins as 10 tokens, three of them forward slashes,
and ends as 7 tokens, with |qualifier| values 0, 1, 1, 0, 2, 2, 2, for
four equivalence classes in turn. Each equivalence class is one lexical
unit, or "lexeme", so the lexeme count is then 4.

In addition, if one of the slashed options is "--", then this means the
empty word, and is removed from the token list; but the first token of the
lexeme is annotated accordingly.

=
void UnderstandLines::slash_cg_line(cg_line *cgl) {
	parse_node *pn;
	int alternatives_group = 0;

	current_sentence = cgl->where_grammar_specified; /* to report problems */

	if (cgl->tokens == NULL)
		internal_error("Null tokens on grammar");

	LOGIF(GRAMMAR_CONSTRUCTION, "Preparing grammar line:\n$T", cgl->tokens);

	for (pn = cgl->tokens->down; pn; pn = pn->next)
		Annotations::write_int(pn, slash_class_ANNOT, 0);

	parse_node *class_start = NULL;
	for (pn = cgl->tokens->down; pn; pn = pn->next) {
		if ((pn->next) &&
			(Wordings::length(Node::get_text(pn->next)) == 1) &&
			(Lexer::word(Wordings::first_wn(Node::get_text(pn->next))) == FORWARDSLASH_V)) { /* slash follows: */
			if (Annotations::read_int(pn, slash_class_ANNOT) == 0) {
				class_start = pn; alternatives_group++; /* start new equiv class */
				Annotations::write_int(class_start, slash_dash_dash_ANNOT, FALSE);
			}

			Annotations::write_int(pn, slash_class_ANNOT,
				alternatives_group); /* make two sides of slash equiv */
			if (pn->next->next)
				Annotations::write_int(pn->next->next, slash_class_ANNOT, alternatives_group);
			if ((pn->next->next) &&
				(Wordings::length(Node::get_text(pn->next->next)) == 1) &&
				(Lexer::word(Wordings::first_wn(Node::get_text(pn->next->next))) == DOUBLEDASH_V)) { /* -- follows: */
				Annotations::write_int(class_start, slash_dash_dash_ANNOT, TRUE);
				pn->next = pn->next->next->next; /* excise slash and dash-dash */
			} else {
				pn->next = pn->next->next; /* excise the slash from the token list */
			}
		}
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Regrouped as:\n$T", cgl->tokens);

	for (pn = cgl->tokens->down; pn; pn = pn->next)
		if ((Annotations::read_int(pn, slash_class_ANNOT) > 0) &&
			(Annotations::read_int(pn, grammar_token_literal_ANNOT) == FALSE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OverAmbitiousSlash),
				"the slash '/' can only be used between single literal words",
				"so 'underneath/under/beneath' is allowed but "
				"'beneath/[florid ways to say under]/under' isn't.");
			break;
		}

	cgl->lexeme_count = 0;

	for (pn = cgl->tokens->down; pn; pn = pn->next) {
		int i = Annotations::read_int(pn, slash_class_ANNOT);
		if (i > 0)
			while ((pn->next) && (Annotations::read_int(pn->next, slash_class_ANNOT) == i))
				pn = pn->next;
		cgl->lexeme_count++;
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Slashed as:\n$T", cgl->tokens);
}

@h Phase II: Determining Grammar.
Here there is substantial work to do both at the line list level and on
individual lines, and the latter does recurse down to token level too.

The following routine calculates the type of the CGL list as the union
of the types of the CGLs within it, where union means the narrowest type
such that every CGL in the list casts to it. We return null if there
are no CGLs in the list, or if the CGLs all return null types, or if
an error occurs. (Note that actions in command verb grammars are counted
as null for this purpose, since a grammar used for parsing the player's
commands is not also used to determine a value.)

=
parse_node *UnderstandLines::line_list_determine(int depth, int cg_is,
	command_grammar *cg, int genuinely_verbal) {
	int first_flag = TRUE;
	parse_node *spec_union = NULL;
	LOGIF(GRAMMAR_CONSTRUCTION, "Determining CGL list for $G\n", cg);

	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg) {
		parse_node *spec_of_line =
			UnderstandLines::cgl_determine(cgl, depth, cg_is, cg, genuinely_verbal);

		if (first_flag) { /* initially no expectations: |spec_union| is meaningless */
			spec_union = spec_of_line; /* so we set it to the first result */
			first_flag = FALSE;
			continue;
		}

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

		if ((cg->cg_is == CG_IS_SUBJECT) || (cg->cg_is == CG_IS_VALUE)) continue;

		current_sentence = cgl->where_grammar_specified;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MixedOutcome),
			"grammar tokens must have the same outcome whatever the way they are "
			"reached",
			"so writing a line like 'Understand \"within\" or \"next to "
			"[something]\" as \"[my token]\" must be wrong: one way it produces "
			"a thing, the other way it doesn't.");
		spec_union = NULL;
		break; /* to prevent the problem being repeated for the same grammar */
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Union: $P\n");
	return spec_union;
}

@ There are three tasks here: to determine the type of the CGL, to issue a
problem if this type is impossibly large, and to calculate two numerical
quantities used in sorting CGLs: the "general sorting bonus" and the
"understanding sorting bonus" (see below).

=
parse_node *UnderstandLines::cgl_determine(cg_line *cgl, int depth,
	int cg_is, command_grammar *cg, int genuinely_verbal) {
	parse_node *spec = NULL;
	parse_node *pn, *pn2;
	int nulls_count, i, nrv, line_length;
	current_sentence = cgl->where_grammar_specified;

	cgl->understanding_sort_bonus = 0;
	cgl->general_sort_bonus = 0;

	nulls_count = 0; /* number of tokens with null results */

	pn = cgl->tokens->down; /* start from first token */
	if ((genuinely_verbal) && (pn)) pn = pn->next; /* unless it's a command verb */

	for (pn2=pn, line_length=0; pn2; pn2 = pn2->next) line_length++;

	int multiples = 0;
	for (i=0; pn; pn = pn->next, i++) {
		if (Node::get_type(pn) != TOKEN_NT)
			internal_error("Bogus node types on grammar");

		int score = 0;
		spec = UnderstandTokens::determine(pn, depth, &score);
		LOGIF(GRAMMAR_CONSTRUCTION, "Result of token <%W> is $P\n", Node::get_text(pn), spec);

		if (spec) {
			if ((Specifications::is_kind_like(spec)) &&
				(K_understanding) &&
				(Kinds::eq(Specifications::to_kind(spec), K_understanding))) { /* "[text]" token */
				int usb_contribution = i - 100;
				if (usb_contribution >= 0) usb_contribution = -1;
				usb_contribution = 100*usb_contribution + (line_length-1-i);
				cgl->understanding_sort_bonus += usb_contribution; /* reduces! */
			}
			int score_multiplier = 1;
			if (DeterminationTypes::get_no_values_described(&(cgl->cgl_type)) == 0) score_multiplier = 10;
			DeterminationTypes::add_term(&(cgl->cgl_type), spec,
				UnderstandTokens::is_multiple(pn));
			cgl->general_sort_bonus += score*score_multiplier;
		} else nulls_count++;

		if (UnderstandTokens::is_multiple(pn)) multiples++;
	}

	if (multiples > 1)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MultipleMultiples),
			"there can be at most one token in any line which can match "
			"multiple things",
			"so you'll have to remove one of the 'things' tokens and "
			"make it a 'something' instead.");

	nrv = DeterminationTypes::get_no_values_described(&(cgl->cgl_type));
	if (nrv == 0) cgl->general_sort_bonus = 100*nulls_count;
	if (cg_is == CG_IS_COMMAND) spec = NULL;
	else {
		if (nrv < 2) spec = DeterminationTypes::get_single_term(&(cgl->cgl_type));
		else StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TwoValuedToken),
			"there can be at most one varying part in the definition of a "
			"named token",
			"so 'Understand \"button [a number]\" as \"[button indication]\"' "
			"is allowed but 'Understand \"button [a number] on [something]\" "
			"as \"[button indication]\"' is not.");
	}

	LOGIF(GRAMMAR_CONSTRUCTION,
		"Determined $g: lexeme count %d, sorting bonus %d, arguments %d, "
		"fixed initials %d, type $P\n",
		cgl, cgl->lexeme_count, cgl->general_sort_bonus, nrv,
		cgl->understanding_sort_bonus, spec);

	return spec;
}

@h Phase III: Sort Grammar.
Insertion sort is used to take the linked list of CGLs and construct a
separate, sorted version. This is not the controversial part.

=
cg_line *UnderstandLines::list_sort(cg_line *list_head) {
	cg_line *cgl, *gl2, *gl3, *sorted_head;

	if (list_head == NULL) return NULL;

	sorted_head = list_head;
	list_head->sorted_next_line = NULL;

	cgl = list_head;
	while (cgl->next_line) {
		cgl = cgl->next_line;
		gl2 = sorted_head;
		if (UnderstandLines::cg_line_must_precede(cgl, gl2)) {
			sorted_head = cgl;
			cgl->sorted_next_line = gl2;
			continue;
		}
		while (gl2) {
			gl3 = gl2;
			gl2 = gl2->sorted_next_line;
			if (gl2 == NULL) {
				gl3->sorted_next_line = cgl;
				break;
			}
			if (UnderstandLines::cg_line_must_precede(cgl, gl2)) {
				gl3->sorted_next_line = cgl;
				cgl->sorted_next_line = gl2;
				break;
			}
		}
	}
	return sorted_head;
}

@ This is the controversial part: the routine which decides whether one CGL
takes precedence (i.e., is parsed earlier than and thus in preference to)
another CGL. This algorithm has been hacked many times to try to reach a
position which pleases all designers: something of a lost cause. The
basic motivation is that we need to sort because the various parsers of
I7 grammar (|parse_name| routines, general parsing routines, the I6 command
parser itself) all work by returning the first match achieved. This means
that if grammar line L2 matches a superset of the texts which grammar line
L1 matches, then L1 should be tried first: trying them in the order L2, L1
would mean that L1 could never be matched, which is surely contrary to the
designer's intention. (Compare the rule-sorting algorithm, which has similar
motivation but is entirely distinct, though both use the same primitive
methods for comparing types of single values, i.e., at stages 5b1 and 5c1
below.)

Recall that each CGL has a numerical USB (understanding sort bonus) and
GSB (general sort bonus). The following rules are applied in sequence:

(1) Higher USBs beat lower USBs.

(2a) For sorting CGLs in player-command grammar, shorter lines beat longer
lines, where length is calculated as the lexeme count.

(2b) For sorting all other CGLs, longer lines beat shorter lines.

(3) Mistaken commands beat unmistaken commands.

(4) Higher GSBs beat lower GSBs.

(5a) Fewer resulting values beat more resulting values.

(5b1) A narrower first result type beats a wider first result type, if
there is a first result.

(5b2) A multiples-disallowed first result type beats a multiples-allowed
first result type, if there is a first result.

(5c1) A narrower second result type beats a wider second result type, if
there is a second result.

(5c2) A multiples-disallowed second result type beats a multiples-allowed
second result type, if there is a second result.

(6) Conditional lines (with a "when" proviso, that is) beat
unconditional lines.

(7) The grammar line defined earlier beats the one defined later.

Rule 1 is intended to resolve awkward ambiguities involved with command
grammar which includes "[text]" tokens. Each such token subtracts 10000 from
the USB of a line but adds back 100 times the token position (which is at least
0 and which we can safely suppose is less than 99: we truncate just in case
so that every |"[text]"| certainly makes a negative contribution of at least
$-100$) and then subtracts off the number of tokens left on the line.

Because a high USB gets priority, and "[text]" tokens make a negative
contribution, the effect is to relegate lines containing "[text]" tokens
to the bottom of the list -- which is good because "[text]" voraciously
eats up words, matching more or less anything, so that any remotely
specific case ought to be tried first. The effect of the curious addition
back in of the token position is that later-placed "[text]" tokens are
tried before earlier-placed ones. Thus |"read chapter [text]"| has a USB
of $-98$, and takes precedence over |"read [text]"| with a USB of $-99$,
but both are beaten by just |"read [something]"| with a USB of 0.
The effect of the subtraction back of the number of tokens remaining
is to ensure that |"read [token] backwards"| takes priority over
|"read [token]"|.

The voracity of |"[text]"|, and its tendency to block out all other
possibilities unless restrained, has to be addressed by this lexically
based numerical calculation because it works in a lexical sort of way:
playing with the types system to prefer |DESCRIPTION/UNDERSTANDING|
over, say, |VALUE/OBJECT| would not be sufficient.

The most surprising point here is the asymmetry in rule 2, which basically
says that when parsing commands typed at the keyboard, shorter beats longer,
whereas in all other settings longer beats shorter. This arises because the
I6 parser, at run time, traditionally works that way: I6 command grammars
are normally stored with short forms first and long forms afterward. The
I6 parser can afford to do this because it is matching text of known length:
if parsing TAKE FROG FROM AQUARIUM, it will try TAKE FROG first but is able
to reject this as not matching the whole text. In other parsing settings,
we are trying to make a maximum-length match against a potentially infinite
stream of words, and it is therefore important to try to match WATERY
CASCADE EFFECT before WATERY CASCADE when looking at text like WATERY
CASCADE EFFECT IMPRESSES PEOPLE, given that the simplistic parsers we
compile generally return the first match found.

Rule 3, that mistakes beat non-mistakes, was in fact rule 1 during 2006: it
seemed logical that since mistakes were exceptional cases, they would be
better checked earlier before moving on to general cases. However, an
example provided by Eric Eve showed that although this was logically correct,
the I6 parser would try to auto-complete lengthy mistakes and thus fail to
check subsequent commands. For this reason, |"look behind [something]"|
as a mistake needs to be checked after |"look"|, or else the I6 parser
will respond to the command LOOK by replying "What do you want to look
behind?" -- and then saying that you are mistaken.

Rule 4 is intended as a lexeme-based tiebreaker. We only get here if there
are the same number of lexemes in the two CGLs being compared. Each is
given a GSB score as follows: a literal lexeme, which produces no result,
such as |"draw"| or |"in/inside/within"|, scores 100; all other lexemes
score as follows:

-- |"[things inside]"| scores a GSB of 10 as the first parameter, 1 as the second;

-- |"[things preferably held]"| similarly scores a GSB of 20 or 2;

-- |"[other things]"| similarly scores a GSB of 20 or 2;

-- |"[something preferably held]"| similarly scores a GSB of 30 or 3;

-- any token giving a logical description of some class of objects, such as
|"[open container]"|, similarly scores a GSB of 50 or 5;

-- and any remaining token (for instance, one matching a number or some other
kind of value) scores a GSB of 0.

Literals score highly because they are structural, and differentiate
cases: under the superset rule, |"look up [thing]"| must be parsed before
|"look [direction] [thing]"|, and it is only the number of literals which
differentiates these cases. If two lines have an equal number of literals,
we now look at the first resultant lexeme. Here we find that a lexeme which
specifies an object (with a GSB of at least 10/1) beats a lexeme which only
specifies a value. Thus the same text will be parsed against objects in
preference to values, which is sensible since there are generally few
objects available to the player and they are generally likely to be the
things being referred to. Among possible object descriptions, the very
general catch-all special cases above are given lower GSB scores than
more specific ones, to enable the more specific cases to go first.

Rule 5a is unlikely to have much effect: it is likely to be rare for CGL
lists to contain CGLs mixing different numbers of results. But Rule 5b1
is very significant: it causes |"draw [animal]"| to have precedence over
|"draw [thing]"|, for instance. Rule 5b2 ensures that |"draw [thing]"|
takes precedence over |"draw [things]"|, which may be useful to handle
multiple and single objects differently.

The motivation for rule 6 is similar to the case of "when" clauses for
rules in rulebooks: it ensures that a match of |"draw [thing]"| when some
condition holds beats a match of |"draw [thing]"| at any time, and this is
necessary under the strict superset principle.

To get to rule 7 looks difficult, given the number of things about the
grammar lines which must match up -- same USB, GSB, number of lexemes,
number of resulting types, equivalent resulting types, same conditional
status -- but in fact it isn't all that uncommon. Equivalent pairs produced
by the Standard Rules include:

|"get off [something]"| and |"get in/into/on/onto [something]"|

|"turn on [something]"| and |"turn [something] on"|

Only the second of these pairs leads to ambiguity, and even then only if
an object has a name like ON VISION ON -- perhaps a book about the antique
BBC children's television programme "Vision On" -- so that the command
TURN ON VISION ON would match both of the alternative CGLs.

=
int UnderstandLines::cg_line_must_precede(cg_line *L1, cg_line *L2) {
	int cs, a, b;

	if ((L1 == NULL) || (L2 == NULL))
		internal_error("tried to sort null CGLs");
	if ((L1->lexeme_count == -1) || (L2->lexeme_count == -1))
		internal_error("tried to sort unslashed CGLs");
	if ((L1->general_sort_bonus == UNCALCULATED_BONUS) ||
		(L2->general_sort_bonus == UNCALCULATED_BONUS))
		internal_error("tried to sort uncalculated CGLs");
	if (L1 == L2) return FALSE;

	a = FALSE; if ((L1->resulting_action) || (L1->mistaken)) a = TRUE;
	b = FALSE; if ((L2->resulting_action) || (L2->mistaken)) b = TRUE;
	if (a != b) {
		LOG("L1 = $g\nL2 = $g\n", L1, L2);
		internal_error("tried to sort on incomparable CGLs");
	}

	if (L1->understanding_sort_bonus > L2->understanding_sort_bonus) return TRUE;
	if (L1->understanding_sort_bonus < L2->understanding_sort_bonus) return FALSE;

	if (a) { /* command grammar: shorter beats longer */
		if (L1->lexeme_count < L2->lexeme_count) return TRUE;
		if (L1->lexeme_count > L2->lexeme_count) return FALSE;
	} else { /* all other grammars: longer beats shorter */
		if (L1->lexeme_count < L2->lexeme_count) return FALSE;
		if (L1->lexeme_count > L2->lexeme_count) return TRUE;
	}

	if ((L1->mistaken) && (L2->mistaken == FALSE)) return TRUE;
	if ((L1->mistaken == FALSE) && (L2->mistaken)) return FALSE;

	if (L1->general_sort_bonus > L2->general_sort_bonus) return TRUE;
	if (L1->general_sort_bonus < L2->general_sort_bonus) return FALSE;

	cs = DeterminationTypes::must_precede(&(L1->cgl_type), &(L2->cgl_type));
	if (cs != NOT_APPLICABLE) return cs;

	if ((UnderstandLines::conditional(L1)) && (UnderstandLines::conditional(L2) == FALSE)) return TRUE;
	if ((UnderstandLines::conditional(L1) == FALSE) && (UnderstandLines::conditional(L2))) return FALSE;

	return FALSE;
}
