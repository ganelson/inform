[Equations::] Equations.

To manage and compile equations, which relate numerical quantities.

@ As with tables, equations are detected early on in Inform's run but not
parsed for their contents until later, so we store several word ranges.
Also as with tables, each can have a number, a name or both.

=
typedef struct equation {
	struct wording equation_text; /* the text of the actual equation */
	struct wording equation_no_text; /* the equation number (if any) */
	struct wording equation_name_text; /* the equation name (if any) */
	struct wording where_text; /* declaration of symbols */
	struct wording usage_text; /* usage notes */
	struct parse_node *equation_created_at; /* where created in source */

	int examined_already;
	struct equation_node *parsed_equation; /* and the equation itself (when eventually parsed) */
	struct equation_symbol *symbol_list; /* the symbols used */
	
	struct equation_compilation_data compilation_data;
	CLASS_DEFINITION
} equation;

@ Each equation is allowed to use one or more symbols. Some may correspond
to local variables in surrounding code from time to time, but others will
be constants, and it's better to think of these as placeholders in the
syntax of the equation, not as storage objects like variables. For instance,
in
$$ E = mc^2 $$
we have three symbols: $E$, $m$ and $c$. (The 2 does not count.) There
might be symbols called $m$ in any number of other equations; if so each
instance has its own |equation_symbol| structure.

=
typedef struct equation_symbol {
	struct wording name; /* always just one word, in fact */
	struct kind *var_kind; /* if a variable -- must be quasinumerical */
	struct id_body *function_notated; /* if a phrase QN to QN */
	struct parse_node *var_const; /* if a symbol for a constant value */
	int temp_constant; /* is this constant a substitution for one usage only? */
	struct equation_symbol *next; /* in the list belonging to the equation */
	struct local_variable *local_map; /* when being solved in a given stack frame */
	int promote_local_to_real; /* from integer, if necessary */
	CLASS_DEFINITION
} equation_symbol;

@ In addition, there are some standing symbols used by all equations: the
constant "pi", for example. They're stored in this linked list:

=
equation_symbol *standard_equation_symbols = NULL;

@ When parsed, the equation is stored as a tree of |equation_node| structures.
As usual, the leaves represent symbols or else constants not given symbol
status (such as the 2 in $E = mc^2$); the non-leaf nodes represent operations,
identified with the same codes as used in "Dimensions". Note
that the equals sign |=| is itself considered an operation here.Thus:
= (text)
	OPERATION_EQN =
	    SYMBOL_EQN E
	    OPERATION_EQN *
	        SYMBOL_EQN m
	        OPERATION_EQN ^
	            SYMBOL_EQN c
	            CONSTANT_EQN 2
=

@d CONSTANT_EQN 1 /* a leaf, representing a quasinumerical constant not given a symbol */
@d SYMBOL_EQN 2 /* a leaf, representing a symbol */
@d OPERATION_EQN 3 /* a non-leaf, representing an operation */

@ However, because of the algorithm used to parse the text of the equation into
this tree, we also need certain other kinds of node to exist during parsing
only. They are syntactic gimmicks, and are forbidden in the final tree.

@d OPEN_BRACKET_EQN 4
@d CLOSE_BRACKET_EQN 5
@d END_EQN 6 /* the end (left or right edge, really) of the equation */

@ Another temporary trick in parsing is to distinguish between explicit
multiplication, where the source text uses an asterisk |*|, and implicit,
as between $m$ and $c^2$ in $E = mc^2$. We distinguish these so that they
can bind with different tightnesses, but both are represented just as
|TIMES_OPERATION| nodes in the eventual tree.

Implicit function application is similarly used to represent the unwritten
operation in |log pi| -- where the function |log| is being applied to the
value |pi|.

@d IMPLICIT_TIMES_OPERATION 100
@d IMPLICIT_APPLICATION_OPERATION 101

@ And now the equation node structure:

@d MAX_EQN_ARITY 2 /* at present all operations are at most binary */

=
typedef struct equation_node {
	int eqn_type; /* one of the |*_EQN| values */
	int eqn_operation; /* one of the |*_OPERATION| values (see "Dimensions.w") */
	int enode_arity; /* 0 for a leaf */
	struct equation_node *enode_operands[MAX_EQN_ARITY]; /* the operands */
	struct parse_node *leaf_constant; /* if e.g. "21" */
	struct equation_symbol *leaf_symbol; /* if e.g. "G" */
	struct generalised_kind gK_before; /* result of the node as it is */
	struct generalised_kind gK_after; /* result of the node as we need it to be */
	int enode_promotion; /* promote this from an integer to a real number? */
	int rational_n; /* represents the rational number |n/m|... */
	int rational_m; /* ...unless |m| is zero */
	CLASS_DEFINITION
} equation_node;

@ Equation names follow the same conventions as table names.

=
<equation-name> ::=
	equation {<cardinal-number>} - ... |    ==> { 3, - }
	equation {<cardinal-number>} |          ==> { 1, - }
	equation - ... |                        ==> { 2, - }
	equation ***							==> @<Issue PM_EquationMisnumbered problem@>

@ The above catches all of the named expressions written out in the
source text, but not the ones written "inline", in phrases like

>> let F be given by F = ma;

Those equations are created by calling |Equations::new| direct from the
S-parser: such equations are called "anonymous", as they have no name. But in
either case, an equation begins here:

=
equation *Equations::new_at(parse_node *p, int anonymous) {
	wording W = Node::get_text(p);
	return Equations::new(W, anonymous);
}

equation *Equations::new(wording W, int anonymous) {
	equation *eqn;
	LOOP_OVER(eqn, equation)
		if (eqn->equation_created_at == current_sentence)
			return eqn;

	eqn = CREATE(equation);
	eqn->equation_created_at = current_sentence;
	eqn->where_text = EMPTY_WORDING;
	eqn->usage_text = EMPTY_WORDING;
	eqn->parsed_equation = NULL;
	eqn->symbol_list = NULL;
	eqn->examined_already = FALSE;

	wording NO = EMPTY_WORDING, NA = EMPTY_WORDING;
	if (anonymous == FALSE) {
		@<Parse the equation's number and/or name@>;
		@<Register any names for this equation@>;
		if (<equation-where>(W)) {
			W = GET_RW(<equation-where>, 1);
			Equations::set_wherewithal(eqn, GET_RW(<equation-where>, 2));
		}
	}
	eqn->equation_no_text = NO;
	eqn->equation_name_text = NA;

	if (<text-ending-in-comma>(W)) W = GET_RW(<text-ending-in-comma>, 1);
	eqn->equation_text = W;
	
	eqn->compilation_data = RTEquations::new_compilation_data(eqn);
	return eqn;
}

@ =
<text-ending-in-comma> ::=
	... ,

@ We take the word range $(w_1, w_2)$ and shave off the first line, that is,
all the words up to the first line break occurring between words. (Compare
the syntax for a table declaration.) This becomes the word range $(tw_1, tw_2)$.
We know that this begins with the word "equation", or we wouldn't be here
(because the sentence would not have been classed an |EQUATION_NT|).

@<Issue PM_EquationMisnumbered problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EquationMisnumbered),
		"the top line of this equation declaration seems not to be a "
		"legal equation number or name",
		"and should read something like 'Equation 6', or 'Equation - "
		"Newton's Second Law', or 'Equation 41 - Coulomb's Law'.");
	==> { 0, - };

@<Parse the equation's number and/or name@> =
	int i = Wordings::last_word_of_formatted_text(W, FALSE);
	wording TW = Wordings::up_to(W, i);
	W = Wordings::from(W, i+1);
	if (<equation-name>(TW)) {
		switch (<<r>>) {
			case 0: return NULL;
			case 1: NO = GET_RW(<equation-name>, 1); break;
			case 2: NA = GET_RW(<equation-name>, 1); break;
			case 3: NO = GET_RW(<equation-name>, 1);
					NA = GET_RW(<equation-name>, 2); break;
		}
	} else internal_error("malformed equation sentence");

@ An equation can be referred to by its number, or by its name. Thus

>> Equation 64 - Distribution of Cheese

could be referred to elsewhere in the text by any of three names:

>> equation 64, Distribution of Cheese, Distribution of Cheese equation

=
<equation-names-construction> ::=
	equation ... |
	... equation

@<Register any names for this equation@> =
	if (Wordings::nonempty(NO)) {
		word_assemblage wa = PreformUtilities::merge(<equation-names-construction>, 0,
			WordAssemblages::from_wording(NO));
		wording AW = WordAssemblages::to_wording(&wa);
		Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			EQUATION_MC, Rvalues::from_equation(eqn), Task::language_of_syntax());
	}

	if (Wordings::nonempty(NA)) {
		if (<s-type-expression-or-value>(NA)) {
			Problems::quote_wording_as_source(1, NA);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EquationMisnamed));
			Problems::issue_problem_segment(
				"The equation name %1 will have to be disallowed as it is text "
				"which already has a meaning to Inform. For instance, creating "
				"an equation called 'Equation - 2 + 2' would be disallowed "
				"because Inform would read '2 + 2' as arithmetic, not a name.");
			Problems::issue_problem_end();
		} else {
			Nouns::new_proper_noun(NA, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
				EQUATION_MC, Rvalues::from_equation(eqn), Task::language_of_syntax());
			word_assemblage wa =
				PreformUtilities::merge(<equation-names-construction>, 0,
					WordAssemblages::from_wording(NA));
			wording AW = WordAssemblages::to_wording(&wa);
			Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
				EQUATION_MC, Rvalues::from_equation(eqn), Task::language_of_syntax());
		}
	}

@ A "where" clause following an equation defines its symbols, as we shall
see. That can be detected in the above parsing process where the equation
is displayed, but for anonymous equations occurring inline, the S-parser
has to discover it; and the S-parser then calls this routine:

=
void Equations::set_wherewithal(equation *eqn, wording W) {
	eqn->where_text = W;
}

@h Parsing equations.
So now it's later on. We can run through all the equations displayed in the
source text:

=
void Equations::traverse_to_stock(void) {
	equation *eqn;
	LOOP_OVER(eqn, equation) {
		current_sentence = eqn->equation_created_at;
		Equations::examine(eqn);
	}
}

@ And, as with creation, |Equations::examine| is called explicitly in the meaning
list converter when an equation is found inline. So in all cases, we call the
following before we need to use the equation, which runs a three-stage process:
parsing the "where..." clause to declare the symbols, then parsing the equation,
then type-checking it.

=
void Equations::examine(equation *eqn) {
	if (eqn->examined_already) return;
	eqn->examined_already = TRUE;
	if (Equations::eqn_declare_symbols(eqn) == FALSE) return;
	Equations::eqn_declare_standard_symbols();
	eqn->parsed_equation = Equations::eqn_parse(eqn);
	if (eqn->parsed_equation == NULL) return;
	if (Equations::eqn_typecheck(eqn) == FALSE)
		Equations::log_equation_node(eqn->parsed_equation);
}

@h Declaring symbols.
Equations are allowed to end with a "where..." clause, explaining what
the symbols in it mean. For example:

>> where F is a force, a = 9.801 m/ss, m1 and m2 are masses;

At the earlier stages of parsing, we simply split the "where" text away
using this:

=
<equation-where> ::=
	... where ...

@ For a displayed equation, the following parses the "where..." text, which
is expected to declare every symbol occurring in it.

=
int Equations::eqn_declare_symbols(equation *eqn) {
	if (Wordings::empty(eqn->where_text)) return TRUE;
	int result = Equations::eqn_declare_variables_inner(eqn, eqn->where_text, FALSE);
	int changed = TRUE;
	while (changed) {
		changed = FALSE;
		for (equation_symbol *ev = eqn->symbol_list; ev; ev = ev->next)
			if (ev->var_kind == NULL) {
				if (ev->next == NULL) {
					StandardProblems::equation_symbol_problem(_p_(BelievedImpossible),
						eqn, eqn->where_text,
						"each symbol in a equation has to be declared with a kind of "
						"value or else an actual value. So '...where N = 1701.' or "
						"'...where N, M are numbers.' would be fine.");
					result = FALSE;
				} else {
					ev->var_kind = ev->next->var_kind;
					ev->var_const = ev->next->var_const;
					changed = TRUE;
				}
			}
	}
	return result;
}

@ But the following routine is also used with the "where" text supplied in
a phrase like so:

>> let F be given by Newton's Second Law, where m = 101kg;

In this context the "where" text sets explicit values for symbols occurring
in the equation; these are temporary settings only and will not change the
equation's behaviour elsewhere.

So the following is called in either permanent mode, when it declares symbols
for an equation, or temporary mode, when it gives them temporary assignments.
It returns |TRUE| if all went well, or |FALSE| if problem messages had to be
issued.

=
equation *equation_being_declared = NULL;
int equation_declared_temporarily = FALSE;
int eq_symbol_wn = -1;

@ The following grammar is later used to parse the text after "where". For
example:

>> F is a force, a = 9.801 m/ss, m1 and m2 are masses

This is split into four clauses, of which the trickiest is the third, reading
just "m1". This abbreviated form is allowed only in permanent declarations
(i.e., not in equations defined inside "let" phrases) and gives the symbol
the same definition as the one following it -- so m1 becomes defined as a
mass, too.

=
<equation-where-list> ::=
	... |                                                   ==> @<Match only when looking ahead@>
	<equation-where-setting-entry> <equation-where-tail> |  ==> { 0, - }
	<equation-where-setting-entry>                          ==> { 0, - }

<equation-where-tail> ::=
	, _and <equation-where-list> |        ==> { 0, - }
	_,/and <equation-where-list>          ==> { 0, - }

<equation-where-setting-entry> ::=
	...  |                                ==> { lookahead }
	<equation-where-setting>              ==> @<Declare an equation variable@>

<equation-where-setting> ::=
	<equation-symbol> is/are <k-kind> |   ==> { EQW_IDENTIFIES_KIND, RP[2] }; eq_symbol_wn = R[1];
	<equation-symbol> is/are <s-value> |  ==> { EQW_IDENTIFIES_VALUE, RP[2] }; eq_symbol_wn = R[1];
	<equation-symbol> is/are ... |        ==> @<Issue PM_EquationSymbolNonValue problem@>
	<equation-symbol> = <k-kind> |        ==> @<Issue PM_EquationSymbolEqualsKOV problem@>
	<equation-symbol> = <s-value> |       ==> { EQW_IDENTIFIES_VALUE, RP[2] }; eq_symbol_wn = R[1];
	<equation-symbol> = ... |             ==> @<Issue PM_EquationSymbolNonValue problem@>
	<equation-symbol>                     ==> { EQW_IDENTIFIES_NOTHING, NULL }; eq_symbol_wn = R[1];

<equation-symbol> ::=
	<valid-equation-symbol>	|             ==> { pass 1 }
	### |                                 ==> @<Issue PM_EquationSymbolMalformed problem@>
	...									  ==> @<Issue PM_EquationSymbolMisdeclared problem@>

@<Match only when looking ahead@> =
	eq_symbol_wn = Wordings::first_wn(W);
	==> { 0, - };
	return preform_lookahead_mode;

@<Declare an equation variable@> =
	Equations::eqn_dec_var(equation_being_declared, Wordings::one_word(eq_symbol_wn), R[1], RP[1]);
	==> { -, - };

@<Issue PM_EquationSymbolNonValue problem@> =
	if (!preform_lookahead_mode)
		StandardProblems::equation_symbol_problem(_p_(PM_EquationSymbolNonValue),
			equation_being_declared, Wordings::one_word(R[1]),
			"this has neither a kind of value nor an actual value.");
	==> { EQW_IDENTIFIES_PROBLEM, - };

@<Issue PM_EquationSymbolEqualsKOV problem@> =
	if (!preform_lookahead_mode)
		StandardProblems::equation_symbol_problem(_p_(PM_EquationSymbolEqualsKOV),
			equation_being_declared, Wordings::one_word(R[1]),
			"'is' should be used, not '=', for a kind of value rather "
			"than an actual value.");
	==> { EQW_IDENTIFIES_PROBLEM, - };

@<Issue PM_EquationSymbolMalformed problem@> =
	if (!preform_lookahead_mode)
		StandardProblems::equation_symbol_problem(_p_(PM_EquationSymbolMalformed),
			equation_being_declared, W,
			"a symbol in a equation has to be a sequence of one to ten "
			"letters optionally followed by a number from 0 to 99, so "
			"'G', 'm', 'pi' and 'KE1' are all legal symbol names. But "
			"this one is not.");
	==> { -1, - };

@<Issue PM_EquationSymbolMisdeclared problem@> =
	if (!preform_lookahead_mode)
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_EquationSymbolMisdeclared),
			"the symbols here are not declared properly",
			"and should each be declared with a kind of value or else an "
			"actual value.");
	==> { -1, - };

@

@d EQW_IDENTIFIES_KIND 1
@d EQW_IDENTIFIES_VALUE 2
@d EQW_IDENTIFIES_NOTHING 3
@d EQW_IDENTIFIES_PROBLEM 4

=
int Equations::eqn_declare_variables_inner(equation *eqn, wording W, int temp) {
	equation_being_declared = eqn;
	equation_declared_temporarily = temp;
	int pc = problem_count;
	<equation-where-list>(W);
	if (problem_count > pc) return FALSE;
	return TRUE;
}

int Equations::eqn_dec_var(equation *eqn, wording W, int X, void *XP) {
	parse_node *spec = NULL;
	kind *K = NULL;
	int temp = equation_declared_temporarily;
	if ((X == EQW_IDENTIFIES_PROBLEM) || (Wordings::empty(W))) return FALSE;
	if (X != EQW_IDENTIFIES_NOTHING)
		@<Find the actual value, or kind of value, which the symbol is to match@>;

	if (temp) @<Assign the given value to this symbol on a temporary basis@>
	else Equations::eqn_add_symbol(eqn, W, K, spec);

	return TRUE;
}

@ Symbols are allowed to be set equal to kinds of value, but only quasinumerical
ones; or to quasinumerical constants; or to global variables which contain
quasinumerical values. The latter are included to make it easier for extensions
to set up sets of equations for, say, gravity, defining

>> The acceleration due to gravity is an acceleration that varies.

and thus letting the extension's user decide how strong gravity is, but
still using it in equations:

>> let F be given by Newton's Second Law, where a = the acceleration due to gravity;

@<Find the actual value, or kind of value, which the symbol is to match@> =
	spec = NULL;
	if (X == EQW_IDENTIFIES_KIND) {
		K = XP;
		if (temp) {
			StandardProblems::equation_symbol_problem(_p_(PM_EquationSymbolVague), eqn, W,
				"when an equation is named for use in a 'let' "
				"phrase, any variables listed under 'where...' have "
				"to be given definite values, not just vaguely said "
				"to have particular kinds. Otherwise, I can't do any "
				"calculation with them.");
			return FALSE;
		}
	}
	if (X == EQW_IDENTIFIES_VALUE) {
		spec = XP;
		K = Specifications::to_kind(spec);
	}
	if ((K) && (Kinds::Behaviour::is_quasinumerical(K) == FALSE)) {
		StandardProblems::equation_symbol_problem(_p_(PM_EquationSymbolNonNumeric), eqn, W,
			"this has a kind of value on which arithmetic cannot be done, "
			"so it can have no place in an equation.");
		return FALSE;
	}

@ At this point we know the user means the variable named at word |wn|
to have the temporary value |spec|, and we have to identify that as one
of the symbols:

@<Assign the given value to this symbol on a temporary basis@> =
	for (equation_symbol *ev = eqn->symbol_list; ev; ev = ev->next)
		if (Wordings::match_cs(W, ev->name)) {
			if (Kinds::eq(K, ev->var_kind) == FALSE) {
				StandardProblems::equation_symbol_problem(_p_(PM_EquationSymbolBadSub), eqn, W,
					"you're using 'where' to substitute something into this "
					"symbol which has the wrong kind of value.");
			}
			ev->temp_constant = TRUE;
			ev->var_const = spec;
			return TRUE;
		}
	StandardProblems::equation_symbol_problem(_p_(PM_EquationSymbolSpurious), eqn, W,
		"when 'where' is used to supply values to plug into a "
		"named equation as part of a 'let' phrase, you can only "
		"supply values for symbols actually used in that equation. "
		"This one doesn't seem to occur there.");
	return FALSE;

@ We won't want those temporary assignments hanging around, so once the
hurly-burly is done, the following is called:

=
void Equations::eqn_remove_temp_variables(equation *eqn) {
	for (equation_symbol *ev = eqn->symbol_list; ev; ev = ev->next)
		if (ev->temp_constant) {
			ev->var_const = NULL;
			ev->temp_constant = FALSE;
		}
}

@ As we saw, permanent symbol declarations cause |Equations::eqn_add_symbol| to be called.
But what about the symbols for an inline equation, like this one?

>> let F be given by F = ma;

These are not explicitly declared. What happens is that any local variable
on the current stack frame, whose name could plausibly be that of a symbol,
is made into one. Sometimes the locals won't be symbols in the equation at all,
but will just have short names and coincidentally hold quasinumeric values;
that doesn't matter, because if they're not in the equation, they'll never
be used.

=
void Equations::declare_local_variables(equation *eqn) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame) {
		local_variable *lvar;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
			if (lvar->allocated)
				Equations::declare_local(eqn,
					lvar->current_usage.varname, lvar->current_usage.kind_as_declared);
	}
}

/* which calls the following for each current local variable in turn: */
void Equations::declare_local(equation *eqn, wording W, kind *K) {
	if ((Equations::equation_symbol_legal(W)) && (Kinds::Behaviour::is_quasinumerical(K)))
		Equations::eqn_add_symbol(eqn, W, K, NULL);
}

@ Next we add "e" and "pi". These are added last, so that any local
declarations will trump them.

=
void Equations::eqn_declare_standard_symbols(void) {
	if (standard_equation_symbols) return;

	wording TCW = Feeds::feed_text(I"e pi");
	LOOP_THROUGH_WORDING(i, TCW) {
		wording V = Wordings::one_word(i);
		if (<s-type-expression>(V)) {
			parse_node *spec = <<rp>>;
			Equations::eqn_add_symbol(NULL, V, K_real_number, spec);
		}
	}
	id_body *idb;
	LOOP_OVER(idb, id_body) {
		wording W = ToPhraseFamily::get_equation_form(idb->head_of_defn);
		if (Wordings::nonempty(W)) {
			equation_symbol *ev = Equations::eqn_add_symbol(NULL, W, K_real_number, NULL);
			ev->function_notated = idb;
		}
	}
}

@ And that about wraps up symbol declaration, except for the routine which
actually declares symbols:

=
equation_symbol *Equations::eqn_add_symbol(equation *eqn, wording W, kind *K, parse_node *spec) {
	W = Wordings::first_word(W);
	equation_symbol **list_head = &standard_equation_symbols;
	if (eqn) list_head = &(eqn->symbol_list);
	equation_symbol *ev;
	for (ev = *list_head; ev; ev = ev->next)
		if (Wordings::match_cs(W, ev->name))
			return ev;
	ev = CREATE(equation_symbol);
	ev->var_kind = K;
	ev->function_notated = NULL;
	ev->var_const = spec;
	ev->next = NULL;
	if (*list_head == NULL) *list_head = ev;
	else {
		equation_symbol *f = *list_head;
		while ((f) && (f->next)) f = f->next;
		f->next = ev;
	}
	ev->name = W;
	ev->temp_constant = FALSE;
	return ev;
}

@ This is where the criterion for being a valid symbol name is expressed:
it matches only a single word, and only if the lettering matches the regular
expression |[A-Za-z]?{1,8}\d?{0,2}|.

=
<valid-equation-symbol> internal {
	if (Equations::equation_symbol_legal(W)) {
		==> { Wordings::first_wn(W), - };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ Using:

=
int Equations::equation_symbol_legal(wording W) {
	if (Wordings::length(W) == 1) {
		inchar32_t *p = Lexer::word_raw_text(Wordings::first_wn(W));
		int j, letters = 0, digits = 0, name_legal = TRUE;
		for (j=0; p[j]; j++) {
			inchar32_t c = p[j];
			if (Characters::isdigit(c)) digits++;
			else if (Characters::isalpha(c)) { letters++; if (digits > 0) name_legal = FALSE; }
			else name_legal = FALSE;
			if (j >= 13) break;
		}
		if ((letters > 10) || (digits > 2)) name_legal = FALSE;
		return name_legal;
	}
	return FALSE;
}

@h Equation nodes.
The parsed equation is a tree full of nodes, so we need routines to make
and examine them.

=
equation_node *Equations::enode_new(int t) {
	equation_node *enode = CREATE(equation_node);
	enode->eqn_type = t;
	enode->eqn_operation = -1;
	enode->enode_arity = 0;
	enode->leaf_constant = NULL;
	enode->leaf_symbol = NULL;
	enode->enode_operands[0] = NULL;
	enode->gK_before = Kinds::FloatingPoint::new_gk(K_value); /* unknown for now */
	enode->gK_after = Kinds::FloatingPoint::new_gk(K_value); /* unknown for now */
	enode->enode_promotion = FALSE;
	enode->rational_n = 0;
	enode->rational_m = 0;
	return enode;
}

@ This is how we make the three kinds of enode permitted in the final compiled
equation. (The other kinds can be created using |Equations::enode_new| directly.)

=
equation_node *Equations::enode_new_op(int op) {
	equation_node *enode = Equations::enode_new(OPERATION_EQN);
	enode->eqn_operation = op;
	return enode;
}

equation_node *Equations::enode_new_symbol(equation_symbol *ev) {
	equation_node *enode = Equations::enode_new(SYMBOL_EQN);
	enode->leaf_symbol = ev;
	return enode;
}

equation_node *Equations::enode_new_constant(parse_node *spec) {
	equation_node *enode = Equations::enode_new(CONSTANT_EQN);
	enode->leaf_constant = spec;
	return enode;
}

@ Being able to log nodes is useful, if only because it's always pretty to
watch shift-reduce parsers in action.

=
void Equations::log_equation_node(equation_node *tok) {
	Equations::log_equation_node_inner(tok, 0);
}

void Equations::log_equation_node_inner(equation_node *tok, int d) {
	for (int i=0; i<d; i++) if (i+1<d) LOG("    "); else LOG("+---");
	if (tok == NULL) { LOG("<NULL>\n"); return; }
	if (tok->eqn_type == OPERATION_EQN) {
		switch (tok->eqn_operation) {
			case PLUS_OPERATION: LOG("<add>"); break;
			case MINUS_OPERATION: LOG("<subtract>"); break;
			case DIVIDE_OPERATION: LOG("<divide>"); break;
			case TIMES_OPERATION: LOG("<multiply>"); break;
			case IMPLICIT_TIMES_OPERATION: LOG("<implicitly multiply>"); break;
			case IMPLICIT_APPLICATION_OPERATION: LOG("<apply function>"); break;
			case EQUALS_OPERATION: LOG("<set equal>"); break;
			case ROOT_OPERATION: LOG("<square root>"); break;
			case REALROOT_OPERATION: LOG("<real square root>"); break;
			case CUBEROOT_OPERATION: LOG("<cube root>"); break;
			case POWER_OPERATION: LOG("<to the power>"); break;
			case NEGATE_OPERATION: LOG("<unary subtraction>"); break;
			default: LOG("<op-%d>", tok->eqn_operation); break;
		}
	} else if (tok->eqn_type == SYMBOL_EQN) LOG("<symbol-%W>", tok->leaf_symbol->name);
	else if (tok->eqn_type == CONSTANT_EQN) LOG("<constant-$P>", tok->leaf_constant);
	else if (tok->eqn_type == OPEN_BRACKET_EQN) LOG("<open-bracket>");
	else if (tok->eqn_type == CLOSE_BRACKET_EQN) LOG("<close-bracket>");
	else if (tok->eqn_type == END_EQN) LOG("<end>");
	else { LOG("<bad-eqn>\n"); return; }
	LOG(" : ");
	Kinds::FloatingPoint::log_gk(tok->gK_before);
	LOG(", ");
	Kinds::FloatingPoint::log_gk(tok->gK_after);
	LOG("\n");
	if (tok->eqn_type == OPERATION_EQN)
		for (int i=0; i<tok->enode_arity; i++)
			Equations::log_equation_node_inner(tok->enode_operands[i], d+1);
}

@h Tokenising equations.
We break up the word range $(w_1, w_2)$ into tokens of equation matter. Word
boundaries divide tokens, but so do operators like |+|, and boundaries can
also occur in runs of alphanumerics if we spot symbol names: thus |mv^21|
will be divided into tokens |m|, |v|, |^|, |21|.

The following routine sends each token in turn to the shift/reduce parser
below, encoding each token as an enode. We return |NULL| if a problem message
has to be issued, or else a pointer to the parsed tree if we succeed.

@d MAX_ENODES_IN_EXPRESSION 100

=
equation_node *Equations::eqn_parse(equation *eqn) {
	wording W = eqn->equation_text;
	Equations::enode_sr_start(); /* start the shift-reduce parser */

	equation_node *previous_token = NULL;
	int enode_count = 0; /* number of tokens shipped so far */
	int bl = 0; /* bracket nesting level */

	int wn = Wordings::first_wn(W), i = 0; inchar32_t *p = NULL;
	while ((wn <= Wordings::last_wn(W)) || (p)) {
		if (p == NULL) { i = 0; p = Lexer::word_raw_text(wn++); }
		/* we are now at character |i| in string |p|, while |wn| is the next word */

		equation_node *token = NULL;
		@<Break off a token from the current position@>;
		@<Issue the token to the shift-reduce parser@>;

		previous_token = token;
		if (p[i] == 0) p = NULL;
	}
	if (Equations::enode_sr_token(eqn, Equations::enode_new(END_EQN)) == FALSE)
		@<Equation fails in the shift-reduce parser@>;
	equation_node *result = Equations::enode_sr_result();
	if (bl != 0) {
		StandardProblems::equation_problem(_p_(BelievedImpossible), eqn, "",
			"this seems to use brackets in a mismatched way, since there "
			"are different numbers of left and right brackets '(' and ')'.");
		return NULL;
	}
	return result;
}

@ Note that symbol names can't begin with a digit.

@<Break off a token from the current position@> =
	inchar32_t c = p[i];
	if (Characters::isalpha(c)) @<Break off a symbol name as a token@>
	else if (Characters::isdigit(c)) @<Break off a numeric constant as a token@>
	else @<Break off an operator or a piece of punctuation as a token@>;

@ Note that symbols are identified by recognition: without knowing the identities
of the symbols, the syntax alone wouldn't tell us how to break them. We can only
break |mc^2| as |m| followed by |c^2| if we know that |m| and |c| are symbols,
rather than |mc|. (This is one reason why most programming languages don't
allow implicit multiplication.)

@<Break off a symbol name as a token@> =
	TEMPORARY_TEXT(text_of_symbol)
	int j; /* the length of the symbol name we try to break off */
	for (j=0; (j<14) && (Characters::isalnum(p[i+j])) && (token == NULL); j++)
		PUT_TO(text_of_symbol, p[i+j]);
	for (equation_symbol *ev = standard_equation_symbols; ev; ev = ev->next)
		@<Look for this symbol name@>;
	if (token == NULL)
		for (j=1; (j<15) && (Characters::isalnum(p[i+j-1])) && (token == NULL); j++) {
			/* copy the first |j| characters into a C string: */
			Str::clear(text_of_symbol);
			for (int k=0; k<j; k++) PUT_TO(text_of_symbol, p[i+k]);
			/* try to identify this as one of the declared symbols: */
			equation_symbol *ev;
			for (ev = eqn->symbol_list; ev; ev = ev->next)
				@<Look for this symbol name@>;
		}
	if (token == NULL) {
		StandardProblems::equation_problem_S(_p_(PM_EquationTokenUnrecognised), eqn, text_of_symbol,
			"the symbol '%3' is one that I don't recognise. It doesn't "
			"seem to be declared after the equation - for instance, "
			"by adding 'where %3 is a number'.");
		return NULL;
	}
	DISCARD_TEXT(text_of_symbol)

@<Look for this symbol name@> =
	if (Str::eq_wide_string(text_of_symbol, Lexer::word_raw_text(Wordings::first_wn(ev->name)))) {
		token = Equations::enode_new_symbol(ev);
		i += j;
		break;
	}

@ The following is reliable because a string of digits not starting with a
0 is always a valid number to Inform unless it overflows the virtual machine's
capacity; and so is the number 0 itself.

@<Break off a numeric constant as a token@> =
	if ((p[i] == '0') && (Characters::isdigit(p[i+1]))) {
		StandardProblems::equation_problem(_p_(PM_EquationLeadingZero), eqn, "",
			"a number in an equation isn't allowed to begin with a "
			"'0' digit, so an equation like 'M = 007+Q' is against the rules.");
		return NULL;
	}

	TEMPORARY_TEXT(text_of_number)
	@<Copy the literal number into a C string, flanked by spaces@>;
	/* now sneakily add this to the word stream, and let the S-parser read it: */
	wording NW = Feeds::feed_text(text_of_number);
	DISCARD_TEXT(text_of_number)

	parse_node *spec = NULL;
	if (<s-type-expression>(NW)) spec = <<rp>>;
	else {
		StandardProblems::equation_problem(_p_(BelievedImpossible), eqn, "",
			"there's a literal number in that equation which doesn't make "
			"sense to me.");
		return NULL;
	}
	/* this can only go wrong if there was an overflow, and a problem will have been issued for that: */
	if (Node::is(spec, CONSTANT_NT) == FALSE) return NULL;
	token = Equations::enode_new_constant(spec);

@<Copy the literal number into a C string, flanked by spaces@> =
	while (Characters::isdigit(p[i])) PUT_TO(text_of_number, p[i++]);
	if (p[i] == '.') {
		PUT_TO(text_of_number, p[i++]);
		while (Characters::isdigit(p[i])) PUT_TO(text_of_number, p[i++]);
	}
	if ((LiteralReals::ismultiplicationsign(p[i])) && (p[i+1] == '1') && (p[i+2] == '0') && (p[i+3] == '^')) {
		PUT_TO(text_of_number, p[i++]);
		PUT_TO(text_of_number, p[i++]);
		PUT_TO(text_of_number, p[i++]);
		PUT_TO(text_of_number, p[i++]);
		while (Characters::isdigit(p[i])) PUT_TO(text_of_number, p[i++]);
	}
	PUT_TO(text_of_number, ' ');

@ Which leaves just the easiest case:

@<Break off an operator or a piece of punctuation as a token@> =
	switch (c) {
		case '=': token = Equations::enode_new_op(EQUALS_OPERATION); break;
		case '+': token = Equations::enode_new_op(PLUS_OPERATION); break;
		case '-':
			if ((previous_token == NULL) ||
				(previous_token->eqn_type == OPERATION_EQN) ||
				(previous_token->eqn_type == OPEN_BRACKET_EQN))
				token = Equations::enode_new_op(NEGATE_OPERATION);
			else
				token = Equations::enode_new_op(MINUS_OPERATION);
			break;
		case '/': token = Equations::enode_new_op(DIVIDE_OPERATION); break;
		case '*': token = Equations::enode_new_op(TIMES_OPERATION); break;
		case '^': token = Equations::enode_new_op(POWER_OPERATION); break;
		case '(': token = Equations::enode_new(OPEN_BRACKET_EQN); bl++; break;
		case ')': token = Equations::enode_new(CLOSE_BRACKET_EQN); bl--; break;
		default: {
			TEMPORARY_TEXT(symbol)
			PUT_TO(symbol, c);
			StandardProblems::equation_problem_S(_p_(PM_EquationOperatorUnrecognised), eqn, symbol,
				"the symbol '%3' is one that I don't recognise. I was "
				"expecting an arithmetic sign, '+', '-', '*','/', or '^', "
				"or else '=' or a bracket '(' or ')'.");
			LOG("Bad operator '%S'\n", symbol); return NULL;
			DISCARD_TEXT(symbol)
		}
	}
	i++;

@ So now we have our next token, and are ready to ship it. But if we
detect an implicit multiplication, for instance between |m| and |c^2|
in |E=mc^2|, we issue that as an |IMPLICIT_TIMES_OPERATION| enode in
between; and in |log pi| we issue an |IMPLICIT_APPLICATION_OPERATION|.

@<Issue the token to the shift-reduce parser@> =
	if (Equations::application_is_implied(previous_token, token)) {
		if (Equations::enode_sr_token(eqn, Equations::enode_new_op(IMPLICIT_APPLICATION_OPERATION)) == FALSE)
			@<Equation fails in the shift-reduce parser@>;
		enode_count++;
	} else if (Equations::multiplication_is_implied(previous_token, token)) {
		if (Equations::enode_sr_token(eqn, Equations::enode_new_op(IMPLICIT_TIMES_OPERATION)) == FALSE)
			@<Equation fails in the shift-reduce parser@>;
		enode_count++;
	}

	if (Equations::enode_sr_token(eqn, token) == FALSE)
		@<Equation fails in the shift-reduce parser@>;
	enode_count++;
	if (enode_count >= MAX_ENODES_IN_EXPRESSION - 2) {
		StandardProblems::equation_problem(_p_(PM_EquationTooComplex), eqn, "",
			"this is too long and complex an equation.");
		return NULL;
	}

@ In case any of the enode insertions fail. It's tricky to generate good error
messages and recover well when an operator-precedence grammar fails to match in
a parser like this, so we'll fall back on this:

@<Equation fails in the shift-reduce parser@> =
	StandardProblems::equation_problem(_p_(PM_EquationMispunctuated), eqn, "",
		"this seems to be wrongly punctuated, and doesn't make sense as a "
		"mathematical formula.");
	return NULL;

@ Lastly, here is when multiplication is implied:

=
int Equations::multiplication_is_implied(equation_node *previous_token, equation_node *token) {
	int lt, rt;
	if ((token == NULL) || (previous_token == NULL)) return FALSE;
	lt = previous_token->eqn_type; rt = token->eqn_type;
	if (((lt == SYMBOL_EQN) || (lt == CONSTANT_EQN) || (lt == CLOSE_BRACKET_EQN)) &&
		((rt == SYMBOL_EQN) || (rt == CONSTANT_EQN) || (rt == OPEN_BRACKET_EQN)))
		return TRUE;
	return FALSE;
}

@ And when function application is implied:

=
int Equations::application_is_implied(equation_node *previous_token, equation_node *token) {
	int lt, rt;
	if ((token == NULL) || (previous_token == NULL)) return FALSE;
	lt = previous_token->eqn_type; rt = token->eqn_type;
	if ((lt == SYMBOL_EQN) && (previous_token->leaf_symbol->function_notated)) return TRUE;
	return FALSE;
}

@h The shift-reduce parser.
This is a classic algorithm for expression-evaluator grammars; see for
instance Aho, Sethi and Ullman, "Compilers", section 4.6 in the second edition.
We use a pair of stacks. The SR stack holds possible attempts to understand
what we have so far, given the tokens that have arrived; the emitter stack
holds nodes which form pieces of the output tree as it is assembled. Nodes
flow from our input, are usually "shifted" onto the SR stack for a while,
are eventually "reduced" in clumps taken off this stack and "emitted",
then go onto the emitter stack, and are finally removed as they are made
into trees.

The flow is therefore always forwards; tokens can't slosh back and forth
between the stacks. On each iteration, at least one token makes progress,
so if there are $N$ tokens of input (including both end marker tokens) then we
take at worst $2N$ steps to finish. Each stack can't need more than $N$
entries, and $N$ is bounded above by |MAX_ENODES_IN_EXPRESSION| plus 2
(allowing for the end markers). So:

=
int SR_sp = 0;
equation_node *SR_stack[MAX_ENODES_IN_EXPRESSION+2];

int emitter_sp = 0;
equation_node *emitter_stack[MAX_ENODES_IN_EXPRESSION+2];

void Equations::log_sr_stacks(void) {
	int i;
	LOG("SR: ");
	for (i=0; i<SR_sp; i++) { LOG(" %d: ", i); Equations::log_equation_node(SR_stack[i]); }
	LOG("EMITTER: ");
	for (i=0; i<emitter_sp; i++) { LOG(" %d: ", i); Equations::log_equation_node(emitter_stack[i]); }
}

@ The start and finish are as follows. At the start, the emitter stack is
empty and the SR stack contains an |END_EQN| token, which represents the
left-hand end of the expression. (Another such token, this time representing the
right-hand end, will be sent by the routines above at the end of the stream. So
there will be two |END_EQN| tokens in play.)

=
void Equations::enode_sr_start(void) {
	SR_stack[0] = Equations::enode_new(END_EQN);
	SR_sp = 1;
	emitter_sp = 0;
}

@ If we have succeeded, the end state of the emitter stack contains a single
node: the head of the tree we have grown to represent the expression.

=
equation_node *Equations::enode_sr_result(void) {
	return emitter_stack[0];
}

@ So the following is the routine which iteratively deals with tokens as
they arrive. As noted above, the loop however ominous always terminates.

For proofs and explanations see ASU, but the idea is simple enough: as we
see the expression a little at a time, we collect possibilities of how to
read it on the SR-stack, until we reach a point where it's possible to tell
what was meant; we then reduce the SR-stack by taking the winning possibility
off the top and moving it to the emitter stack. For instance, if we have
read |4 + 5| then we don't know yet whether the |+| will add the 4 to the 5;
if the next token is |+| or |END_EQN| then it will, but if the next token
is |*| then it won't, because we're looking at something like |4 + 5 * 6|.

If the next token is of lower precedence than |+| then we "reduce" --
telling the emitter about the addition, which we now understand -- but if
it's higher, as with |*|, then we "shift", meaning, we postpone worrying
about the addition and start worrying about the multiplication instead;
our new problem, working out what |*| applies to, sits on top of the
addition problem on the SR-stack.

=
int Equations::enode_sr_token(equation *eqn, equation_node *tok) {
	int safety_cutout = 3*MAX_ENODES_IN_EXPRESSION;

	while (TRUE) {
		if (SR_sp <= 0) internal_error("SR stack empty");

		if ((SR_stack[SR_sp-1]->eqn_type == END_EQN) && (tok->eqn_type == END_EQN)) break;

		if ((Equations::enode_lt(SR_stack[SR_sp-1], tok)) || (Equations::enode_eq(SR_stack[SR_sp-1], tok)))
			@<Shift an enode onto the SR-stack@>
		else if (Equations::enode_gt(SR_stack[SR_sp-1], tok))
			@<Reduce some enodes from the SR-stack to the emitter stack@>
		else return FALSE;

		if (safety_cutout-- < 0) internal_error("SR parser deadlocked");
	}

	if ((emitter_sp != 1) || (SR_sp != 1)) return FALSE;
	return TRUE;
}

@ After shifting, we return a signal of success, which asks for the next
token to be sent.

@<Shift an enode onto the SR-stack@> =
	SR_stack[SR_sp++] = tok;
	return TRUE;

@ The ASU book is a little vague about what happens if there is an underflow
here, I think because it's possible to set up the grammar such that an
underflow cannot occur. But I can see no obvious proof that it will never
occur for us given syntactically incorrect input, so we will return |FALSE|
on an underflow to be safe.

Note that we can never emit the bottom-most token on the SR stack: that's the
left-hand end marker, so can never be validly part of any arithmetic. So
an underflow occurs if that's all that's left, i.e., when the SR stack pointer
is 1, not 0.

@<Reduce some enodes from the SR-stack to the emitter stack@> =
	do { if (SR_sp <= 1) return FALSE;
		if (Equations::enode_emit(SR_stack[--SR_sp]) == FALSE) return FALSE;
	} while ((SR_sp >= 1) && (Equations::enode_lt(SR_stack[SR_sp-1], SR_stack[SR_sp]) == FALSE));

@ The key point is that if nodes arrive at the SR parser in their
ordinary order of mathematical writing, then they "reduce" off the
SR stack and onto the emitter stack in reverse Polish notation order.
Thus the sequence |4 + 2 * 7| is emitted as |4 2 7 * +|. RPN has no
need of brackets to clarify the sequence of operation, and it's very
easy to build a tree from.

=
int Equations::enode_emit(equation_node *tok) {
	switch (tok->eqn_type) {
		case SYMBOL_EQN: case CONSTANT_EQN:
			emitter_stack[emitter_sp++] = tok;
			break;
		case OPERATION_EQN:
			if (tok->eqn_operation == IMPLICIT_TIMES_OPERATION)
				tok->eqn_operation = TIMES_OPERATION;
			if (tok->eqn_operation == IMPLICIT_APPLICATION_OPERATION)
				tok->enode_arity = 2;
			else if (Kinds::Dimensions::arithmetic_op_is_unary(tok->eqn_operation))
				tok->enode_arity = 1;
			else
				tok->enode_arity = 2;
			int i;
			for (i = tok->enode_arity - 1; i >= 0; i--) {
				emitter_sp--;
				if (emitter_sp < 0) return FALSE;
				tok->enode_operands[i] = emitter_stack[emitter_sp];
			}
			emitter_stack[emitter_sp++] = tok;
			break;
	}
	return TRUE;
}

@ All we need now is to decide the order of precedence of our tokens,
though this isn't as simple as it looks, because they are not all
symmetrical left-right. That's obviously true of things like an open
bracket |(|, which affects the stuff to the left very differently from
the stuff to the right. But it is also true of operators. |+| may be
associative mathematically, but in computing there's a difference
between evaluating |a + (b+c)| and |(a+b) + c|.

All of this means there's no simple order relationship on the tokens,
where $T<S$ if and only if $S>T$. We order them using a numerical score,
but they get one score $f(T)$ if they appear on the left and another
score $g(T)$ if they appear on the right:

=
int Equations::enode_lt(equation_node *tok1, equation_node *tok2) {
	int f_left = Equations::f_function(tok1), g_right = Equations::g_function(tok2);
	if (f_left < g_right) return TRUE; return FALSE;
}

int Equations::enode_eq(equation_node *tok1, equation_node *tok2) {
	int f_left = Equations::f_function(tok1), g_right = Equations::g_function(tok2);
	if (f_left == g_right) return TRUE; return FALSE;
}

int Equations::enode_gt(equation_node *tok1, equation_node *tok2) {
	int f_left = Equations::f_function(tok1), g_right = Equations::g_function(tok2);
	if (f_left > g_right) return TRUE; return FALSE;
}

@ And here are those scorings. Note that for the binary operators, $f$
scores are usually slightly higher than $g$ scores: that's what makes
them left associative, that is, $a+b+c$ is read as $(a+b)+c$. The
exception to this is raising to powers: |a^2^3| evaluates $a^8$, not
$a^6$, because it is read as |a^(2^3)|.

Implicit multiplication has higher precedence than explicit. This is
actually to give it higher precedence than division (which has to have
the same precedence as explicit multiplication), and is so that
|ab/cd| evaluates $(ab)/(cd)$ rather than $a\cdot (b/c)\cdot d$.

=
int Equations::f_function(equation_node *tok) {
	switch (tok->eqn_type) {
		case SYMBOL_EQN: case CONSTANT_EQN: return 16;
		case OPERATION_EQN:
			switch (tok->eqn_operation) {
				case EQUALS_OPERATION: return 2;
				case PLUS_OPERATION: case MINUS_OPERATION: return 4;
				case TIMES_OPERATION: case DIVIDE_OPERATION: return 6;
				case IMPLICIT_TIMES_OPERATION: return 8;
				case POWER_OPERATION: return 9;
				case IMPLICIT_APPLICATION_OPERATION: return 5;
				case NEGATE_OPERATION: return 1;
			}
			internal_error("unknown operator precedence");
		case OPEN_BRACKET_EQN: return 0;
		case CLOSE_BRACKET_EQN: return 16;
		case END_EQN: return 0;
	}
	internal_error("unknown f-value"); return 0;
}

@ And symmetrically:

=
int Equations::g_function(equation_node *tok) {
	switch (tok->eqn_type) {
		case SYMBOL_EQN: case CONSTANT_EQN: return 15;
		case OPERATION_EQN:
			if (tok) switch (tok->eqn_operation) {
				case EQUALS_OPERATION: return 1;
				case PLUS_OPERATION: case MINUS_OPERATION: return 3;
				case TIMES_OPERATION: case DIVIDE_OPERATION: return 5;
				case IMPLICIT_TIMES_OPERATION: return 7;
				case POWER_OPERATION: return 10;
				case IMPLICIT_APPLICATION_OPERATION: return 14;
				case NEGATE_OPERATION: return 12;
			}
			internal_error("unknown operator precedence");
		case OPEN_BRACKET_EQN: return 15;
		case CLOSE_BRACKET_EQN: return 0;
		case END_EQN: return 0;
	}
	internal_error("unknown g-value"); return 0;
}

@h Typechecking equations.
The SR parser can generate trees for any syntactically valid equation, but
it may be something using |=| inappropriately or not at all. We rule that
out first: we want the top node in the tree to be the unique |=| operator.

=
int Equations::eqn_typecheck(equation *eqn) {
	switch (Equations::enode_count_equals(eqn->parsed_equation)) {
		case 0:
			StandardProblems::equation_problem(_p_(PM_EquationDoesntEquate), eqn, "",
				"this equation doesn't seem to contain an equals sign, and "
				"without '=' there is no equating anything with anything.");
			return FALSE;
		case 1:
			if (Equations::enode_is_equals(eqn->parsed_equation) == FALSE) {
				StandardProblems::equation_problem(_p_(PM_EquationEquatesBadly), eqn, "",
					"the equals sign '=' here seems to be buried inside the "
					"formula, not at the surface. For instance, 'F = ma' is "
					"fine, but 'F(m=a)' would not make sense - the '=' would "
					"be inside brackets.");
				return FALSE;
			}
			break;
		default:
			StandardProblems::equation_problem(_p_(PM_EquationEquatesMultiply), eqn, "",
				"this equation seems to contain more than one equals "
				"sign '='.");
			return FALSE;
	}

	return Equations::enode_typecheck(eqn, eqn->parsed_equation);
}

@ A recursive count of instances down the tree from |tok|:

=
int Equations::enode_count_equals(equation_node *tok) {
	int c = 0, i;
	if (tok) {
		if (Equations::enode_is_equals(tok)) c++;
		for (i=0; i<tok->enode_arity; i++)
			c += Equations::enode_count_equals(tok->enode_operands[i]);
	}
	return c;
}

int Equations::enode_is_equals(equation_node *tok) {
	if (tok == NULL) return FALSE;
	if ((tok->eqn_type == OPERATION_EQN) && (tok->eqn_operation == EQUALS_OPERATION))
		return TRUE;
	return FALSE;
}

@ Now we come to the real typechecking. The following is called, depth-first,
at each node in the equation; it has to assign a kind at every node, in such
a way that all operations are dimensionally valid. We return |FALSE| if we
are obliged to issue a problem message.

=
int float_terminal_nodes = FALSE;

int Equations::enode_typecheck(equation *eqn, equation_node *tok) {
	int result = TRUE;
	if (tok == NULL) return result;
	LOG_INDENT;
	int i;
	for (i=0; i<tok->enode_arity; i++)
		if (Equations::enode_typecheck(eqn, tok->enode_operands[i]) == FALSE)
			result = FALSE;
	if (result) {
		switch (tok->eqn_type) {
			case SYMBOL_EQN:
				tok->gK_before =
					Kinds::FloatingPoint::new_gk(tok->leaf_symbol->var_kind);
				break;
			case CONSTANT_EQN:
				tok->gK_before =
					Kinds::FloatingPoint::new_gk(
						Node::get_kind_of_value(tok->leaf_constant));
				if ((tok->enode_promotion) && (CompileValues::target_VM_supports_kind(K_real_number)))
					tok->gK_before =
						Kinds::FloatingPoint::to_real(tok->gK_before);
				break;
			case OPERATION_EQN:
				if (tok->eqn_operation == EQUALS_OPERATION)
					@<Typecheck the set-equals node at the top level@>
				else if (tok->eqn_operation == POWER_OPERATION)
					@<Typecheck a raise-to-integer-power node@>
				else if (tok->eqn_operation == IMPLICIT_APPLICATION_OPERATION)
					@<Typecheck a function application node@>
				else
					@<Typecheck a general operation node@>;
				break;
			default: internal_error("forbidden enode found in parsed equation");
		}
	}
	tok->gK_after = tok->gK_before;
	if ((float_terminal_nodes) && (tok->enode_arity == FALSE))
		Equations::promote_subequation(eqn, tok, FALSE);
	LOG_OUTDENT;
	return result;
}

@ If we know that we need a real rather than integer answer, that has to
propagate downwards from the equality into the trees on either side, casting
integers to reals.

@<Typecheck the set-equals node at the top level@> =
	kind *L = Kinds::FloatingPoint::underlying(tok->enode_operands[0]->gK_after);
	kind *R = Kinds::FloatingPoint::underlying(tok->enode_operands[1]->gK_after);
	L = Kinds::FloatingPoint::integer_equivalent(L);
	R = Kinds::FloatingPoint::integer_equivalent(R);
	if (Kinds::eq(L, R) == FALSE) {
		result = FALSE;
		LOG("Tried to equate %u and %u\n", L, R);
		StandardProblems::equation_problem(_p_(PM_EquationIncomparable), eqn, "",
			"this equation tries to set two values equal which have "
			"different kinds from each other.");
	}
	int lf = Kinds::FloatingPoint::is_real(tok->enode_operands[0]->gK_after);
	int rf = Kinds::FloatingPoint::is_real(tok->enode_operands[1]->gK_after);
	if ((lf == TRUE) && (rf == FALSE))
		Equations::promote_subequation(eqn, tok->enode_operands[1], TRUE);
	if ((lf == FALSE) && (rf == TRUE))
		Equations::demote_subequation(eqn, tok->enode_operands[1]);
	tok->gK_before = tok->enode_operands[0]->gK_after;

@ The restriction on powers is needed to make it possible to know the
dimensions of the result. If $h$ is a length, $h^2$ is an area but $h^3$ is
a volume; so if all we have is $h^n$, and we don't know the value of $n$,
we're unable to see what equations $h^n$ can appear in.

@<Typecheck a raise-to-integer-power node@> =
	equation_node *base = tok->enode_operands[0];
	equation_node *power = tok->enode_operands[1];

	if (Kinds::Dimensions::dimensionless(Kinds::FloatingPoint::underlying(base->gK_after))) {
		tok->gK_before = base->gK_after;
		tok->gK_after = base->gK_after;
	} else @<Take the dimensional power of the kind of the base@>;
	int lf = Kinds::FloatingPoint::is_real(tok->enode_operands[0]->gK_after);
	int rf = Kinds::FloatingPoint::is_real(tok->enode_operands[1]->gK_after);
	if ((lf == TRUE) && (rf == FALSE))
		Equations::promote_subequation(eqn, tok->enode_operands[1], FALSE);
	if ((lf == FALSE) && (rf == TRUE))
		Equations::promote_subequation(eqn, tok->enode_operands[0], FALSE);
	if ((Kinds::FloatingPoint::is_real(tok->gK_after) == FALSE) && ((lf) || (rf))) {
		tok->gK_before = Kinds::FloatingPoint::to_real(tok->gK_before);
	}

@<Typecheck a function application node@> =
	equation_node *fn = tok->enode_operands[0];
	if ((fn->eqn_type == SYMBOL_EQN) && (fn->leaf_symbol->function_notated)) {
		id_body *idb = fn->leaf_symbol->function_notated;
		kind *RK;
		if (IDTypeData::arithmetic_operation(idb) == REALROOT_OPERATION) {
			kind *OPK = Kinds::FloatingPoint::underlying(tok->enode_operands[1]->gK_after);
			RK = Kinds::Dimensions::arithmetic_on_kinds(OPK, NULL, REALROOT_OPERATION);
			if (RK == NULL) {
				StandardProblems::equation_problem(_p_(PM_EquationCantRoot-G), eqn, "",
					"the square root function 'root' can only be used on quantities "
					"whose dimensions are themselves a square - for example, the "
					"root of the area 100 sq m makes sense (it's 10m), but the root "
					"of 4m doesn't make sense, because what's a square root of a meter?");
				return FALSE;
			}
		} else {
			RK = IDTypeData::get_return_kind(&(idb->type_data));
		}
		tok->gK_before = Kinds::FloatingPoint::to_real(Kinds::FloatingPoint::new_gk(RK));
	}
	int rf = Kinds::FloatingPoint::is_real(tok->enode_operands[1]->gK_after);
	if (rf == FALSE) Equations::promote_subequation(eqn, tok->enode_operands[1], FALSE);

@ To work out the kind of $b^n$, we use repeated multiplication or division
of dimensions; if $n=0$ then we have a dimensionless value, and choose
"number" as the simplest possibility.

@<Take the dimensional power of the kind of the base@> =
	kind *F =
		Kinds::FloatingPoint::integer_equivalent(
			Kinds::FloatingPoint::underlying(
				base->gK_after));
	int real = FALSE;
	if (Kinds::FloatingPoint::is_real(base->gK_after)) real = TRUE;

	int n = -1, m = 1;
	if (power->rational_m != 0) {
		n = power->rational_n; m = power->rational_m;
		if ((m > 1) && (real == FALSE)) {
			result = FALSE;
			StandardProblems::equation_problem(_p_(PM_EquationCantPower2-G), eqn, "",
				"except for the special cases of squaring and cubing, the '^' "
				"raise-to-power symbol can only be used to power a value using "
				"real rather than integer arithmetic.");
		}
	} else if ((Kinds::eq(Kinds::FloatingPoint::underlying(power->gK_after), K_number) == FALSE) ||
		(power->eqn_type != CONSTANT_EQN)) {
		result = FALSE;
		StandardProblems::equation_problem(_p_(PM_EquationDimensionPower), eqn, "",
			"the '^' raise-to-power symbol can only be used to raise a value "
			"with dimensions to a specific number. So 'mv^2' is fine, but not "
			"'mv^n' or 'mv^(1+n)'. (This is because I would need to work out what "
			"kind of value 'v^n' would be, and the answer would depend on 'n', "
			"but I wouldn't know what 'n' is.)");
	} else {
		n = Rvalues::to_int(power->leaf_constant);
	}
	if (n >= 1) {
		kind *K = Kinds::Dimensions::to_rational_power(F, n, m);
		if (K == NULL)  {
			StandardProblems::equation_problem(_p_(BelievedImpossible), eqn, "",
				"this would involve taking a fractional power of an amount whose "
				"dimensions are not of that power form - for example, the square "
				"root of the area 100 sq m makes sense (it's 10m), but the square "
				"root of 4m doesn't make sense, because what's a square root of "
				"a meter?");
			return FALSE;
		}
		if (real)
			tok->gK_before =
				Kinds::FloatingPoint::to_real(
					Kinds::FloatingPoint::new_gk(K));
		else
			tok->gK_before =
				Kinds::FloatingPoint::new_gk(K);
	}

@ The following is easy because it was the content of the whole "Dimensions.w"
section:

@<Typecheck a general operation node@> =
	kind *K = NULL;
	kind *O1 =
		Kinds::FloatingPoint::integer_equivalent(
			Kinds::FloatingPoint::underlying(
				tok->enode_operands[0]->gK_after));
	int real = FALSE;
	if (Kinds::FloatingPoint::is_real(tok->enode_operands[0]->gK_after))
		real = TRUE;
	if (Kinds::Dimensions::arithmetic_op_is_unary(tok->eqn_operation))
		K = Kinds::Dimensions::arithmetic_on_kinds(O1, NULL, tok->eqn_operation);
	else {
		kind *O2 =
			Kinds::FloatingPoint::integer_equivalent(
				Kinds::FloatingPoint::underlying(
					tok->enode_operands[1]->gK_after));
		if (Kinds::FloatingPoint::is_real(tok->enode_operands[1]->gK_after))
			real = TRUE;
		K = Kinds::Dimensions::arithmetic_on_kinds(O1, O2, tok->eqn_operation);
		int lf = Kinds::FloatingPoint::is_real(tok->enode_operands[0]->gK_after);
		int rf = Kinds::FloatingPoint::is_real(tok->enode_operands[1]->gK_after);
		if ((lf == TRUE) && (rf == FALSE))
			Equations::promote_subequation(eqn, tok->enode_operands[1], FALSE);
		if ((lf == FALSE) && (rf == TRUE))
			Equations::promote_subequation(eqn, tok->enode_operands[0], FALSE);
	}
	if (K == NULL) {
		result = FALSE;
		tok->gK_before = Kinds::FloatingPoint::new_gk(K_value);
		LOG("Failed at operation:\n"); Equations::log_equation_node(tok);
		if (Kinds::Dimensions::arithmetic_op_is_unary(tok->eqn_operation))
			@<Issue unary equation typechecking problem message@>
		else
			@<Issue binary equation typechecking problem message@>;
	} else if (real)
		tok->gK_before =
			Kinds::FloatingPoint::to_real(
				Kinds::FloatingPoint::new_gk(K));
	else
		tok->gK_before =
			Kinds::FloatingPoint::new_gk(K);

@<Issue unary equation typechecking problem message@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(4,
		Kinds::FloatingPoint::underlying(tok->enode_operands[0]->gK_after));
	switch(tok->eqn_operation) {
		case NEGATE_OPERATION:
			Problems::quote_text(6, "negating");
			break;
		case ROOT_OPERATION:
			Problems::quote_text(6, "taking the square root of");
			break;
		case REALROOT_OPERATION:
			Problems::quote_text(6, "taking the (real-valued) square root of");
			break;
		case CUBEROOT_OPERATION:
			Problems::quote_text(6, "taking the cube root of");
			break;
	}
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"You wrote %1, but that equation seems to involve %6 %4, which is not "
		"good arithmetic.");
	Problems::issue_problem_end();

@<Issue binary equation typechecking problem message@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(4, Kinds::FloatingPoint::underlying(tok->enode_operands[0]->gK_after));
	Problems::quote_kind(5, Kinds::FloatingPoint::underlying(tok->enode_operands[1]->gK_after));
	switch(tok->eqn_operation) {
		case PLUS_OPERATION:
			Problems::quote_text(6, "adding"); Problems::quote_text(7, "to");
			break;
		case MINUS_OPERATION:
			Problems::quote_text(6, "subtracting"); Problems::quote_text(7, "from");
			break;
		case TIMES_OPERATION:
			Problems::quote_text(6, "multiplying"); Problems::quote_text(7, "by");
			break;
		case DIVIDE_OPERATION:
		case REMAINDER_OPERATION:
			Problems::quote_text(6, "dividing"); Problems::quote_text(7, "by");
			break;
		case POWER_OPERATION:
			Problems::quote_text(6, "raising"); Problems::quote_text(7, "to the power of");
			break;
		default:
			Problems::quote_text(6, "combining"); Problems::quote_text(7, "with");
			break;
	}
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EquationBadArithmetic));
	Problems::issue_problem_segment(
		"You wrote %1, but that equation seems to involve "
		"%6 %4 %7 %5, which is not good arithmetic.");
	Problems::issue_problem_end();

@h Flotation.


=
void Equations::promote_subequation(equation *eqn, equation_node *tok, int deeply) {
	if (tok == NULL) return;
	if (deeply) {
		float_terminal_nodes = TRUE;
		Equations::enode_typecheck(eqn, tok);
		float_terminal_nodes = FALSE;
	}
	tok->gK_after = Kinds::FloatingPoint::to_real(tok->gK_after);
}

void Equations::demote_subequation(equation *eqn, equation_node *tok) {
	if (tok == NULL) return;
	tok->gK_after = Kinds::FloatingPoint::to_integer(tok->gK_after);
}

@h Rearrangement.
We carry out only the simplest of operations, but it's surprising how often that's
good enough: if it isn't, we simply return |FALSE|.

Everything we do will be reversible, which is important since we are
changing the |parsed_equation| tree, and we don't want to be changing our
view of what the equation means in the process. One thing that never changes
is that the top node of the equation is always the unique "equal to" node
in the tree.

Suppose we are solving for |v|, which occurs in just one place in the equation.
Either it's at the top level under the |=|, in which case we now have an
explicit formula for |v|, or it's stuck underneath some operation node. We
rearrange the tree to move this operation over to the other side, which
allows |v| to make progress -- see below for a proof that this terminates.

=
int Equations::eqn_rearrange(equation *eqn, equation_symbol *to_solve) {
	while (TRUE) {
		@<Swap the two sides if necessary so that v occurs only once and on the left@>;

		equation_node *old_LHS = eqn->parsed_equation->enode_operands[0];
		equation_node *old_RHS = eqn->parsed_equation->enode_operands[1];

		if (old_LHS->eqn_type != OPERATION_EQN) break;

		if (old_LHS->enode_arity == 2)
			@<Rearrange to move v upwards through this binary operator@>
		else
			@<Rearrange to move v upwards through this unary operator@>;
	}

	return TRUE;
}

@ We have no ability to gather terms, so the variable |v| we are solving for can only
occur once in the formula. In Inform's idea of equations, |A = B| and |B = A|
have the same meaning, so we'll place |v| on the left.

@<Swap the two sides if necessary so that v occurs only once and on the left@> =
	int lc = Equations::enode_count_var(eqn->parsed_equation->enode_operands[0], to_solve);
	int rc = Equations::enode_count_var(eqn->parsed_equation->enode_operands[1], to_solve);

	if (lc + rc != 1) return FALSE;
	if (lc == 0) {
		equation_node *swap = eqn->parsed_equation->enode_operands[0];
		eqn->parsed_equation->enode_operands[0] = eqn->parsed_equation->enode_operands[1];
		eqn->parsed_equation->enode_operands[1] = swap;
	}

@ The main loop above terminates because on each iteration, either

(i) the tree depth of |v| below |=| decreases by 1, or
(ii) the tree depth of |v| remains the same but the number of |MINUS_OPERATION| or
|DIVIDE_OPERATION| nodes in the tree decreases by 1.

Since at any given time there are a finite number of |MINUS_OPERATION| or
|DIVIDE_OPERATION| nodes, case (ii) cannot repeat indefinitely, and we must
therefore eventually fall into case (i); and then subsequently do so again,
and so on; and so the tree depth of |v| will ultimately fall to 1, at which
point it is at the top level as required and we break out of the loop.

@ So the rearrangement moves have to make sure the "(i) or (ii)" property
always holds. The simplest case to understand is |+|. Suppose we have:
= (text)
	=
	    +
	        V
	        E
	    R
=
representing $(V+E) = R$, where $V$ is the sub-equation containing
$v$. ($E$ is an arbitrary sub-equation, and $R$ is the right hand
side.) One of the two operands of |+| will be "promoted", moving
upwards in the tree, and since we can choose to promote either $V$ or
$E$, we'll choose $V$, thus obtaining:
= (text)
	=
	    V
	    -
	        R
	        E
=
that is, $V = (R - E)$. Since $V$ has moved upwards, so has the unique instance
of $v$, and therefore the tree depth of $v$ has decreased by 1 -- property (i).
Multiplication is similar, but turns into division on the right hand side.

But now consider |-|. When we rearrange:
= (text)
	=
	    -
	        E
	        V
	    R
=
representing $(E-V) = R$ we no longer have a choice of which operand of |-|
to promote: we have to promote the right operand, and that produces $E = (R+V)$.
The tree depth of $v$ is not improved, and it's now over on the right hand
side. The next iteration of the main loop will swap sides again so that we
have $(R+V) = E$. But a tricky node (subtraction or division) has been
exchanged out of the tree for an easy one (addition or multiplication), so
we fail property (i) but achieve property (ii).

@<Rearrange to move v upwards through this binary operator@> =
	/* rearrange to move this operator */
	int op = old_LHS->eqn_operation;
	if (op == POWER_OPERATION)
		@<Rearrange to remove a power@>
	else if (op == IMPLICIT_APPLICATION_OPERATION)
		@<Rearrange using the inverse of function@>
	else {
		int promote = 0, new_op = PLUS_OPERATION;
		if (Equations::enode_count_var(old_LHS->enode_operands[1], to_solve) > 0) promote = 1;
		switch (op) {
			case PLUS_OPERATION: new_op = MINUS_OPERATION; break;
			case MINUS_OPERATION: new_op = PLUS_OPERATION; promote = 0; break;
			case TIMES_OPERATION: new_op = DIVIDE_OPERATION; break;
			case DIVIDE_OPERATION: new_op = TIMES_OPERATION; promote = 0; break;
			default: LOG("%d\n", op); internal_error("strange operator in rearrangement");
		}
		equation_node *E = old_LHS->enode_operands[1 - promote];
		/* the new LHS is the promoted operand: */
		eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[promote];
		/* the new RHS is the operator which used to be the LHS... */
		eqn->parsed_equation->enode_operands[1] = old_LHS;
		/* ...the former RHS being the operand replacing the promoted one... */
		old_LHS->enode_operands[0] = old_RHS;
		old_LHS->enode_operands[1] = E;
		/* ...except that the operator reverses in "sense" */
		old_LHS->eqn_operation = new_op;
	}

@ Solving $x^v = y$ for $v$ requires logs, which are not in our scheme; and
solving $v^n = y$ for non-constant $n$ is no better. So in either case we
surrender by returning |FALSE|.

In fact, the only cases we can solve at present are $V^2 = y$ and $V^3 = y$.
It would be easy to add solutions for $V^4 = y$, $V^6 = y$ and in general for
$V^k = y$ where the only prime factors of $k$ are 2 and 3, but this is not
something people are likely to need very much. The taking of 4th or higher roots
hardly ever occurs in physical equations, and anyone wanting this will have
to write more explicit source text.

Anyway, rearrangement for our easy cases is indeed easy:
= (text)
	=
	    ^
	        V
	        2
	    R
=
becomes
= (text)
	=
	    V
	    square-root
	        R
=
and $V$ is always promoted, so we achieve property (i); and similarly for
cube roots.

@<Rearrange to remove a power@> =
	int p = Rvalues::to_int(old_LHS->enode_operands[1]->leaf_constant);
	if (p == 2) {
		eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[0];
		eqn->parsed_equation->enode_operands[1] = old_LHS;
		old_LHS->eqn_operation = ROOT_OPERATION;
		old_LHS->enode_arity = 1;
		old_LHS->enode_operands[0] = old_RHS;
	} else if (p == 3) {
		eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[0];
		eqn->parsed_equation->enode_operands[1] = old_LHS;
		old_LHS->eqn_operation = CUBEROOT_OPERATION;
		old_LHS->enode_arity = 1;
		old_LHS->enode_operands[0] = old_RHS;
	} else {
		eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[0];
		eqn->parsed_equation->enode_operands[1] = old_LHS;
		old_LHS->eqn_operation = POWER_OPERATION;
		old_LHS->enode_arity = 2;
		old_LHS->enode_operands[0] = old_RHS;
		equation_node *the_power = old_LHS->enode_operands[1];
		old_LHS->enode_operands[1] = Equations::enode_new_op(DIVIDE_OPERATION);
		old_LHS->enode_operands[1]->enode_arity = 2;
		old_LHS->enode_operands[1]->enode_operands[0] = Equations::enode_new_constant(
			Rvalues::from_int(1, EMPTY_WORDING));
		old_LHS->enode_operands[1]->enode_operands[0]->gK_before =
			Kinds::FloatingPoint::new_gk(K_number);
		old_LHS->enode_operands[1]->enode_operands[0]->enode_promotion = TRUE;
		old_LHS->enode_operands[1]->enode_operands[1] = the_power;
		old_LHS->enode_operands[1]->enode_operands[1]->gK_before =
			Kinds::FloatingPoint::new_gk(K_number);
		old_LHS->enode_operands[1]->enode_operands[1]->enode_promotion = TRUE;
		old_LHS->enode_operands[1]->gK_before =
			Kinds::FloatingPoint::new_gk(K_real_number);
		old_LHS->enode_operands[1]->gK_after =
			Kinds::FloatingPoint::new_gk(K_real_number);
		old_LHS->enode_operands[1]->rational_n = 1;
		old_LHS->enode_operands[1]->rational_m = p;
		CompileValues::note_that_kind_is_used(K_real_number);
	}

@ Here we have something like |log x = y| and want to rewrite as |x = exp y|,
which is only possible if we have an inverse available for our function --
in this case, |exp| being the inverse of |log|. Thus:
= (text)
	=
	    apply
	        function
	        V
	    R
=
must become
= (text)
	=
	    V
	    apply
	        inverse-of-function
	        R
=

@<Rearrange using the inverse of function@> =
	equation_node *fnode = old_LHS->enode_operands[0];
	if ((fnode->leaf_symbol == NULL) ||
		(fnode->leaf_symbol->function_notated == NULL)) {
		Equations::log_equation_node(fnode);
		internal_error("not a function being applied");
	}
	id_body *f = fnode->leaf_symbol->function_notated;
	id_body *finv = ToPhraseFamily::inverse(f->head_of_defn);
	if (finv == NULL) return FALSE; /* no known inverse for this function */

	equation_symbol *ev, *ev_inverse = NULL;
	for (ev = standard_equation_symbols; ev; ev = ev->next)
		if (ev->function_notated == finv)
			ev_inverse = ev;

	if (ev_inverse == NULL) return FALSE; /* inverse can't be used in equations */

	fnode->leaf_symbol = ev_inverse;

	eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[1];
	eqn->parsed_equation->enode_operands[1] = old_LHS;
	old_LHS->enode_operands[1] = old_RHS;

@ The unary operations are easy in a similar way -- they only have one operand,
so we always promote $V$ and achieve property (i). A square root is rearranged
as a square, and a cube root as a cube. (It's important that everything we do
is reversible -- we generate exactly those powers which we are able to undo
again if necessary.) Unary minus is easier still -- we need only move it to
the other side; thus $-V = R$ becomes $V=-R$, and |v| again rises.

@<Rearrange to move v upwards through this unary operator@> =
	int op = old_LHS->eqn_operation;
	switch (op) {
		case NEGATE_OPERATION:
			eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[0];
			eqn->parsed_equation->enode_operands[1] = old_LHS;
			old_LHS->enode_operands[0] = old_RHS;
			break;
		case ROOT_OPERATION:
		case REALROOT_OPERATION:
			eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[0];
			eqn->parsed_equation->enode_operands[1] = old_LHS;
			old_LHS->eqn_operation = TIMES_OPERATION;
			old_LHS->enode_arity = 2;
			old_LHS->enode_operands[0] = old_RHS;
			old_LHS->enode_operands[1] = old_RHS;
			break;
		case CUBEROOT_OPERATION:
			eqn->parsed_equation->enode_operands[0] = old_LHS->enode_operands[0];
			eqn->parsed_equation->enode_operands[1] = old_LHS;
			old_LHS->eqn_operation = TIMES_OPERATION;
			old_LHS->enode_arity = 2;
			old_LHS->enode_operands[0] = old_RHS;
			old_LHS->enode_operands[1] = Equations::enode_new_op(TIMES_OPERATION);
			old_LHS->enode_operands[1]->enode_operands[0] = old_RHS;
			old_LHS->enode_operands[1]->enode_operands[1] = old_RHS;
			break;
		default: internal_error("unanticipated operator in rearrangement");
	}

@ And that's the whole rearranger, except for the utility routine which
counts instances of the magic variable |v| at or below a given point in the
equation tree.

=
int Equations::enode_count_var(equation_node *tok, equation_symbol *to_solve) {
	int c = 0, i;
	if (tok == NULL) return c;
	if ((tok->eqn_type == SYMBOL_EQN) && (tok->leaf_symbol == to_solve))
		return 1;
	for (i=0; i<tok->enode_arity; i++)
		c += Equations::enode_count_var(tok->enode_operands[i], to_solve);
	return c;
}

@h Internal test case.
This is a little like those "advise all parties" law exam questions: we
parse the equation, then rearrange to solve it for each variable in turn.

=

void Equations::perform_equation_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	wording E = itc->text_supplying_the_case;
	wording WH = EMPTY_WORDING;
	if (<equation-where>(E)) {
		E = GET_RW(<equation-where>, 1);
		WH = GET_RW(<equation-where>, 2);
	}
	equation *eqn = Equations::new(E, TRUE);
	Equations::set_wherewithal(eqn, WH);
	Equations::examine(eqn);
	Equations::log_equation_parsed(eqn);
	equation_symbol *ev;
	for (ev = eqn->symbol_list; ev; ev = ev->next) {
		if (Equations::eqn_rearrange(eqn, ev) == FALSE)
			LOG("Too hard to rearrange to solve for %W\n", ev->name);
		else {
			LOG("Rearranged to solve for %W:\n", ev->name);
			Equations::log_equation_parsed(eqn);
		}
	}
}

@h Logging.
And finally:

=
void Equations::log(equation *eqn) {
	LOG("{%W}", eqn->equation_text);
}

void Equations::log_equation_parsed(equation *eqn) {
	if (eqn == NULL) LOG("<null>\n");
	else Equations::log_equation_node(eqn->parsed_equation);
}
