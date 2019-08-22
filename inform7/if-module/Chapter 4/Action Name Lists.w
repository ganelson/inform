[PL::Actions::Lists::] Action Name Lists.

Action name lists provide a disjunction in the choice of action
made by an action pattern. For instance, "taking or dropping the disc"
results in a two-entry ANL. An empty ANL is also legal, and means "doing
something" -- the generic I7 text for "any action at all".

@h Definitions.

=
typedef struct action_name_list {
	struct action_name *action_listed; /* the action in this ANL list entry */
	struct named_action_pattern *nap_listed; /* or a named pattern instead */
	struct action_name_list *next; /* next in this ANL list */
	int word_position; /* and some values used temporarily during parsing */
	int negate_pattern; /* parity of the entire list which this heads */
	int parity; /* parity of just this individual item */
	int parc;
	struct wording parameter[2];
	struct wording in_clause;
	int abbreviation_level; /* number of words missing */
	int anyone_specified;
	int delete_this_link; /* used temporarily during parsing */
} action_name_list;

@ The action name list is the part of an action pattern identifying
which actions are allowed: "taking, dropping or examining" for
example. The following routine extracts this from a potentially longer
text (e.g. "taking, dropping or examining a door").

=
action_name_list *PL::Actions::Lists::anl_new(void) {
	action_name_list *new_anl = CREATE(action_name_list);
	new_anl->action_listed = NULL;
	new_anl->nap_listed = NULL;
	new_anl->parc = 0;
	new_anl->word_position = -1;
	new_anl->parity = 1;
	new_anl->negate_pattern = FALSE;
	new_anl->in_clause = EMPTY_WORDING;
	new_anl->abbreviation_level = 0;
	new_anl->anyone_specified = FALSE;
	new_anl->delete_this_link = FALSE;
	return new_anl;
}

void PL::Actions::Lists::log(action_name_list *anl) {
	int i, c;
	for (c=0; anl; anl = anl->next, c++) {
		LOG("ANL entry %s(%d@%d): %s ",
			(anl->delete_this_link)?"(to be deleted) ":"",
			c, anl->word_position,
			(anl->parity==1)?"+":"-");
		if (anl->action_listed)
			LOG("%W", anl->action_listed->present_name);
		if (anl->nap_listed)
			LOG("%W", Nouns::nominative(anl->nap_listed->name));
		else LOG("NULL");
		for (i=0; i<anl->parc; i++)
			LOG(" [%d: %W]", i, anl->parameter[i]);
		LOG(" [in: %W]\n", anl->in_clause);
	}
}

void PL::Actions::Lists::log_briefly(action_name_list *anl) {
	if (anl == NULL) LOG("<null-anl>");
	else {
		if (anl->negate_pattern) LOG("NOT[ ");
		action_name_list *a;
		for (a = anl; a; a = a->next) {
			if (a->nap_listed) {
				if (a->parity == -1) LOG("not-");
				LOG("%W / ", Nouns::nominative(a->nap_listed->name));
			} else if (a->action_listed == NULL)
				LOG("ANY / ");
			else {
				if (a->parity == -1) LOG("not-");
				LOG("%W / ", a->action_listed->present_name);
			}
		}
		if (anl->negate_pattern) LOG(" ]");
	}
}

action_name *PL::Actions::Lists::get_singleton_action(action_name_list *anl) {
	action_name *an;
	if (anl == NULL) internal_error("Supposed singleton ANL is empty");
	an = anl->action_listed;
	if (an == NULL) internal_error("Singleton ANL points to null AN");
	return an;
}

action_name_list *anl_being_parsed = NULL;

@ The following handles action name lists, such as:

>> doing something other than waiting
>> taking or dropping the box

At this stage in parsing, we are identifying possible actions, and
what their possible operands are, but we aren't trying to parse those
operands.

=
<action-list> ::=
	doing something/anything other than <anl-excluded> |	==> FALSE; *XP = RP[1];
	doing something/anything except <anl-excluded> |		==> FALSE; *XP = RP[1];
	doing something/anything to/with <anl-to-tail> |		==> TRUE; *XP = RP[1];
	doing something/anything |								==> @<Construct ANL for anything@>
	doing something/anything ... |							==> TRUE; *XP = NULL; return FAIL_NONTERMINAL;
	<anl>													==> TRUE; *XP = RP[1];

<anl-excluded> ::=
	<anl> to/with {<anl-minimal-common-operand>} |			==> @<Add to-clause to excluded ANL@>;
	<anl>													==> TRUE; *XP = PL::Actions::Lists::flip_anl_parity(RP[1], FALSE);

<anl-minimal-common-operand> ::=
	_,/or ... |												==> FALSE; return FAIL_NONTERMINAL;
	... to/with ... |										==> FALSE; return FAIL_NONTERMINAL;
	...														==> TRUE;

@<Construct ANL for anything@> =
	*X = TRUE;
	action_name_list *new_anl = PL::Actions::Lists::anl_new();
	new_anl->word_position = Wordings::first_wn(W);
	*XP = new_anl;

@ The trickiest form is:

>> doing something to the box in the dining room

where no explicit action occurs at all, but we have to parse the rest of
the text as if it does, including an "in" clause.

So the following finds the first "in" within its range of words, except that
it throws out an "in" that we consider bogus for our own syntactic purposes:
for instance, we don't want to count the "in" from "fixed in place".

=
<anl-to-tail> ::=
	<anl-operand> <anl-in-tail> |		==> @<Augment ANL with in clause@>
	<anl-operand>						==> 0; *XP = RP[1]

<anl-operand> ::=
	...									==> @<Construct ANL for anything applied@>

<anl-in-tail> ::=
	fixed in place *** |					==> FALSE; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	is/are/was/were/been/listed in *** |	==> FALSE; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	in ...									==> TRUE

@<Augment ANL with in clause@> =
	action_name_list *anl = RP[1];
	anl->in_clause = GET_RW(<anl-in-tail>, 1);

@<Construct ANL for anything applied@> =
	*X = TRUE;
	action_name_list *new_anl;
	if ((!preform_lookahead_mode) && (anl_being_parsed)) new_anl = anl_being_parsed;
	else {
		new_anl = PL::Actions::Lists::anl_new();
		new_anl->word_position = Wordings::first_wn(W);
	}
	new_anl->parameter[new_anl->parc] = W;
	new_anl->parc++;
	*XP = new_anl;

@ Now for the basic list of actions being included:

=
<anl> ::=
	<anl-entry> <anl-tail> |		==> @<Join parsed ANLs@>
	<anl-entry>						==> 0; *XP = RP[1];

<anl-tail> ::=
	, _or <anl> |					==> 0; *XP = RP[1];
	_,/or <anl>						==> 0; *XP = RP[1];

@ Which reduces us to an internal nonterminal for an entry in this list.
It actually produces multiple matches: for example,

>> taking inventory

will result in a list of two possibilities -- "taking inventory", the
action, with no operand; and "taking", the action, applied to the
operand "inventory". (It's unlikely that the last will succeed in the
end, but it's syntactically valid.)

=
<anl-entry> ::=
	<named-action-pattern>	|				==> @<Make an action pattern from named behaviour@>
	<named-action-pattern> <anl-in-tail> |	==> @<Make an action pattern from named behaviour plus in@>
	<anl-entry-with-action>					==> 0; *XP = RP[1];

<named-action-pattern> internal {
	named_action_pattern *nap = PL::Actions::Patterns::Named::by_name(W);
	if (nap) {
		*XP = nap; return TRUE;
	}
	return FALSE;
}

<anl-entry-with-action> internal {
	action_name_list *anl = PL::Actions::Lists::anl_parse_internal(W);
	if (anl) {
		*XP = anl; return TRUE;
	}
	return FALSE;
}

@<Make an action pattern from named behaviour@> =
	*X = 0;
	action_name_list *new_anl = PL::Actions::Lists::anl_new();
	new_anl->word_position = Wordings::first_wn(W);
	new_anl->nap_listed = RP[1];
	*XP = new_anl;

@<Make an action pattern from named behaviour plus in@> =
	*X = 0;
	action_name_list *new_anl = PL::Actions::Lists::anl_new();
	new_anl->word_position = Wordings::first_wn(W);
	new_anl->nap_listed = RP[1];
	new_anl->in_clause = GET_RW(<anl-in-tail>, 1);
	*XP = new_anl;

@<Add to-clause to excluded ANL@> =
	action_name_list *anl = PL::Actions::Lists::flip_anl_parity(RP[1], TRUE);
	if ((anl == NULL) ||
		(PL::Actions::can_have_parameters(anl->action_listed) == FALSE))
		return FALSE;
	anl->parameter[anl->parc] = GET_RW(<anl-excluded>, 1);
	anl->parc++;
	*XP = anl;

@<Join parsed ANLs@> =
	action_name_list *left_atom = RP[1];
	action_name_list *right_tail = RP[2];
	if (left_atom == NULL) { *XP = right_tail; }
	else if (right_tail == NULL) { *XP = left_atom; }
	else {
		action_name_list *new_anl = right_tail;
		while (new_anl->next != NULL) new_anl = new_anl->next;
		new_anl->next = left_atom;
		*XP = right_tail;
	}


@ =
action_name_list *PL::Actions::Lists::flip_anl_parity(action_name_list *anl, int flip_all) {
	if (flip_all) {
		action_name_list *L;
		for (L = anl; L; L = L->next) {
			L->parity = (L->parity == 1)?(-1):1;
		}
	} else {
		anl->negate_pattern = (anl->negate_pattern)?FALSE:TRUE;
	}
	return anl;
}

@ =
int anl_parsing_tense = IS_TENSE;
action_name_list *PL::Actions::Lists::parse(wording W, int tense) {
	if (Wordings::mismatched_brackets(W)) return NULL;
	int t = anl_parsing_tense;
	anl_parsing_tense = tense;
	int r = <action-list>(W);
	anl_parsing_tense = t;
	if (r) return <<rp>>;
	return NULL;
}

@ =
action_name_list *PL::Actions::Lists::anl_parse_internal(wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Parsing ANL from %W (tense %d)\n", W, anl_parsing_tense);

	int tense = anl_parsing_tense;
	action_name_list *anl_list = NULL, *new_anl = NULL;

	action_name *an;
	new_anl = PL::Actions::Lists::anl_new();
	anl_list = NULL;

	LOOP_OVER(an, action_name) {
		int x_ended = FALSE;
		int fc = 0;
		int it_optional = PL::Actions::it_optional(an);
		int abbreviable = PL::Actions::abbreviable(an);
		wording XW = PL::Actions::set_text_to_name_tensed(an, tense);
		new_anl->action_listed = an;
		new_anl->parc = 0;
		new_anl->word_position = Wordings::first_wn(W);
		new_anl->parity = 1;
		new_anl->in_clause = EMPTY_WORDING;
		int w_m = Wordings::first_wn(W), x_m = Wordings::first_wn(XW);
		while ((w_m <= Wordings::last_wn(W)) && (x_m <= Wordings::last_wn(XW))) {
			if (Lexer::word(x_m++) != Lexer::word(w_m++)) {
				fc=1; goto DontInclude;
			}
			if (x_m > Wordings::last_wn(XW)) { x_ended = TRUE; break; }
			if (<action-pronoun>(Wordings::one_word(x_m))) {
				if (w_m > Wordings::last_wn(W)) x_ended = TRUE; else {
					int j = -1, k;
					for (k=(it_optional)?(w_m):(w_m+1); k<=Wordings::last_wn(W); k++)
						if (Lexer::word(k) == Lexer::word(x_m+1)) { j = k; break; }
					if (j<0) { fc=2; goto DontInclude; }
					if (j-1 >= w_m) {
						new_anl->parameter[new_anl->parc] = Wordings::new(w_m, j-1);
						new_anl->parc++;
					} else {
						new_anl->parameter[new_anl->parc] = EMPTY_WORDING;
						new_anl->parc++;
					}
					w_m = j; x_m++;
				}
			}
			if (x_ended) break;
		}
		if ((w_m > Wordings::last_wn(W)) && (x_ended == FALSE)) {
			if (abbreviable) x_ended = TRUE;
			else { fc=3; goto DontInclude; }
		}
		if (x_m <= Wordings::last_wn(XW)) new_anl->abbreviation_level = Wordings::last_wn(XW)-x_m+1;

		int inc = FALSE;
		if (w_m > Wordings::last_wn(W)) inc = TRUE;
		else if (<anl-in-tail>(Wordings::from(W, w_m))) {
			new_anl->in_clause = GET_RW(<anl-in-tail>, 1);
			inc = TRUE;
		} else if (PL::Actions::can_have_parameters(an)) {
			anl_being_parsed = new_anl;
			if (<anl-to-tail>(Wordings::from(W, w_m))) {
				inc = TRUE;
			}
			anl_being_parsed = NULL;
		}
		new_anl->next = NULL;
		if (inc) {
			if (anl_list == NULL) anl_list = new_anl;
			else {
				action_name_list *pos = anl_list, *prev = NULL;
				while ((pos) && (pos->abbreviation_level < new_anl->abbreviation_level))
					prev = pos, pos = pos->next;
				if (prev) prev->next = new_anl; else anl_list = new_anl;
				new_anl->next = pos;
			}
		}
		new_anl = PL::Actions::Lists::anl_new();
		DontInclude: ;
	}
	LOGIF(ACTION_PATTERN_PARSING, "Parsing ANL from %W resulted in:\n$L\n", W, anl_list);
	return anl_list;
}

int scanning_anl_only_mode = FALSE;
action_name_list *PL::Actions::Lists::extract_actions_only(wording W) {
	action_name_list *anl = NULL;
	int s = scanning_anl_only_mode;
	scanning_anl_only_mode = TRUE;
	int s2 = permit_trying_omission;
	permit_trying_omission = TRUE;
	if (<action-pattern>(W)) {
		anl = PL::Actions::Patterns::list(<<rp>>);
		if (anl) {
			anl->anyone_specified = FALSE;
			if (<<r>> == ACTOR_EXPLICITLY_UNIVERSAL) anl->anyone_specified = TRUE;
		}
	}
	scanning_anl_only_mode = s;
	permit_trying_omission = s2;
	return anl;
}

action_name *PL::Actions::Lists::get_single_action(action_name_list *anl) {
	int posn = -1, matchl = -1;
	action_name *anf = NULL;
	LOGIF(RULE_ATTACHMENTS, "Getting single action from:\n$L\n", anl);
	while (anl) {
		if (anl->parity == -1) return NULL;
		if (anl->negate_pattern) return NULL;
		if (anl->action_listed) {
			int k = PL::Actions::get_stem_length(anl->action_listed) - anl->abbreviation_level;
			if (anl->word_position != posn) {
				if (posn >= 0) return NULL;
				posn = anl->word_position;
				anf = anl->action_listed;
				matchl = k;
			} else {
				if (k > matchl) {
					matchl = k;
					anf = anl->action_listed;
				}
			}
		}
		anl = anl->next;
	}
	LOGIF(RULE_ATTACHMENTS, "Posn %d AN $l\n", posn, anf);
	return anf;
}

int PL::Actions::Lists::get_explicit_anyone_flag(action_name_list *anl) {
	if (anl == NULL) return FALSE;
	return anl->anyone_specified;
}

int PL::Actions::Lists::negated(action_name_list *anl) {
	if (anl == NULL) return FALSE;
	return anl->negate_pattern;
}

void PL::Actions::Lists::compile(OUTPUT_STREAM, action_name_list *anl) {
	if (anl == NULL) return;
	LOGIF(ACTION_PATTERN_COMPILATION, "CANL: $L", anl);

	WRITE("(");

	int optimise = TRUE;
	for (action_name_list *L = anl; L; L = L->next)
		if (L->nap_listed)
			optimise = FALSE;

	if (optimise) {
		WRITE("action %s", (anl->parity==1)?"==":"~=");
		for (action_name_list *L = anl; L; L = L->next) {
			WRITE("%n", PL::Actions::double_sharp(L->action_listed));
			if (L->next) WRITE(" or ");
		}
	} else {
		for (action_name_list *L = anl; L; L = L->next) {
			if (L->parity == -1) WRITE("(~~");
			if (L->nap_listed)
				WRITE("(%n())", PL::Actions::Patterns::Named::identifier(L->nap_listed));
			else
				WRITE("action == %n", PL::Actions::double_sharp(L->action_listed));
			if (L->parity == -1) WRITE(")");
			if (L->next) WRITE(" || ");
		}
	}

	WRITE(")");
}

void PL::Actions::Lists::emit(action_name_list *anl) {
	if (anl == NULL) return;
	LOGIF(ACTION_PATTERN_COMPILATION, "CANL: $L", anl);

	int C = 0;
	for (action_name_list *L = anl; L; L = L->next) C++;

	if (anl->parity == -1) { Emit::inv_primitive(Produce::opcode(NOT_BIP)); Emit::down(); }

	int N = 0, downs = 0;
	for (action_name_list *L = anl; L; L = L->next) {
		if (anl->parity != L->parity) internal_error("mixed parity");
		N++;
		if (N < C) { Emit::inv_primitive(Produce::opcode(OR_BIP)); Emit::down(); downs++; }
		if (L->nap_listed) {
			Emit::inv_primitive(Produce::opcode(INDIRECT0_BIP));
			Emit::down();
				Emit::val_iname(K_value, PL::Actions::Patterns::Named::identifier(L->nap_listed));
			Emit::up();
		} else {
			Emit::inv_primitive(Produce::opcode(EQ_BIP));
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(ACTION_HL));
				Emit::val_iname(K_value, PL::Actions::double_sharp(L->action_listed));
			Emit::up();
		}
	}
	while (downs > 0) { Emit::up(); downs--; }

	if (anl->parity == -1) Emit::up();

}

@h Specificity of ANLs.
The following is one of NI's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int PL::Actions::Lists::compare_specificity(action_name_list *anl1, action_name_list *anl2) {
	int count1, count2;
	count1 = PL::Actions::Lists::count_actions_covered(anl1);
	count2 = PL::Actions::Lists::count_actions_covered(anl2);
	if (count1 < count2) return 1;
	if (count1 > count2) return -1;
	return 0;
}

@ Where:

=
int PL::Actions::Lists::count_actions_covered(action_name_list *anl) {
	int k, parity = TRUE, infinity = NUMBER_CREATED(action_name);
	if (anl == NULL) return infinity;
	if (anl->negate_pattern) parity = FALSE;
	for (k=0; anl; anl = anl->next) {
		if (anl->nap_listed) continue;
		if (anl->parity == -1) parity = FALSE;
		if ((anl->action_listed) && (k < infinity)) k++;
		else k = infinity;
	}
	if (parity == FALSE) k = infinity-k;
	return k;
}
