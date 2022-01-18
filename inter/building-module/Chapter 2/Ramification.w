[Ramification::] Ramification.

Turning textual code written in Inform 6 syntax into an inter schema.

@h Introduction.
Once //Tokenisation// has been done, we have an inter schema which is not
really a tree, but a linked list in all but name --
= (text)
	EXPRESSION_ISNT
		T1
		T2
		T3
		T4
		...
=
So, there is no internal structure yet. "Ramification" performs a series of
transformations on this tree, gradually shaking out the (sometimes ambiguous)
syntactic markers such as |COMMA_ISTT| and replacing them with semantically
clear subtrees.

=
void Ramification::go(inter_schema *sch) {
	REPEATEDLY_APPLY(Ramification::implied_braces);
	REPEATEDLY_APPLY(Ramification::unbrace_schema);
	REPEATEDLY_APPLY(Ramification::divide_schema);
	REPEATEDLY_APPLY(Ramification::undivide_schema);
	REPEATEDLY_APPLY(Ramification::resolve_halfopen_blocks);
	REPEATEDLY_APPLY(Ramification::break_early_bracings);
	REPEATEDLY_APPLY(Ramification::strip_leading_white_space);
	REPEATEDLY_APPLY(Ramification::split_switches_into_cases);
	REPEATEDLY_APPLY(Ramification::strip_leading_white_space);
	REPEATEDLY_APPLY(Ramification::split_print_statements);
	REPEATEDLY_APPLY(Ramification::identify_constructs);
	REPEATEDLY_APPLY(Ramification::treat_constructs);
	REPEATEDLY_APPLY(Ramification::add_missing_bodies);
	REPEATEDLY_APPLY(Ramification::remove_empties);
	REPEATEDLY_APPLY(Ramification::outer_subexpressions);
	REPEATEDLY_APPLY(Ramification::top_level_commas);
	REPEATEDLY_APPLY(Ramification::alternatecases);
	REPEATEDLY_APPLY(Ramification::outer_subexpressions);
	REPEATEDLY_APPLY(Ramification::strip_all_white_space);
	REPEATEDLY_APPLY(Ramification::debracket);
	REPEATEDLY_APPLY(Ramification::implied_return_values);
	REPEATEDLY_APPLY(Ramification::message_calls);
}

@ Each transformation will be applied until it returns |FALSE| to say that
it could see nothing to do, or |NOT_APPLICABLE| to say that it did but
that it doesn't want to be called again. Some transformations make use
of temporary markers attached to nodes or tokens in the tree, so we clear
these out at the start of each iteration.

@d REPEATEDLY_APPLY(X)
	{
		Ramification::unmark(sch->node_tree);
		while (TRUE) {
			int rv = X(NULL, sch->node_tree);
			if (rv == FALSE) break;
			LOGIF(SCHEMA_COMPILATION_DETAILS, "After round of " #X ":\n$1\n", sch);
			if (rv == NOT_APPLICABLE) break;
		}
	}

=
void Ramification::unmark(inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		isn->node_marked = FALSE;
		for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
			t->preinsert = 0;
			t->postinsert = 0;
		}
		Ramification::unmark(isn->child_node);
	}
}

@h The implied braces ramification.
In common with most C-like languages, though unlike Perl, Inform 6 makes braces
optional around code blocks which contain only a single statement. Thus:
= (text as Inform 6)
	if (x == 1) print "x is 1.^";
=
is understood as if it were
= (text as Inform 6)
	if (x == 1) { print "x is 1.^"; }
=
But we will find future ramifications much easier to code up if braces are
always used. So this one looks for cases where braces have been omitted,
and inserts them around the single statements in question.

=
int Ramification::implied_braces(inter_schema_node *par, inter_schema_node *at) {
	for (inter_schema_node *isn = at; isn; isn=isn->next_node) {
		for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
			if ((t->ist_type == RESERVED_ISTT) &&
				((t->reserved_word == IF_I6RW) ||
					(t->reserved_word == WHILE_I6RW) ||
					(t->reserved_word == FOR_I6RW) ||
					(t->reserved_word == SWITCH_I6RW) ||
					(t->reserved_word == OBJECTLOOP_I6RW))) {
				inter_schema_token *n = t->next;
				int bl = 0;
				while (n) {
					if (n->ist_type == OPEN_ROUND_ISTT) bl++;
					if (n->ist_type == CLOSE_ROUND_ISTT) {
						bl--;
						if (bl == 0) { n = n->next; break; }
					}
					n = n->next;
				}
				if ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				if ((n) && (n->ist_type != OPEN_BRACE_ISTT))
					@<Make pre and post markers from here@>;
			}
			if ((t->ist_type == RESERVED_ISTT) &&
				(t->reserved_word == ELSE_I6RW)) {
				inter_schema_token *n = t->next;
				if ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				if ((n) && (n->ist_type != OPEN_BRACE_ISTT))
					@<Make pre and post markers from here@>;
			}
		}
	}

	int changed = TRUE, rounds = 0;
	while (changed) {
		changed = FALSE; rounds++;
		for (inter_schema_node *isn = at; isn; isn=isn->next_node) {
			for (inter_schema_token *t = isn->expression_tokens, *prev = NULL;
				t; prev = t, t=t->next) {
				if ((prev) && (t->preinsert > 0)) {
					t->preinsert--;
					inter_schema_token *open_b =
						InterSchemas::new_token(OPEN_BRACE_ISTT, I"{", 0, 0, -1);
					InterSchemas::add_token_after(open_b, prev);
					changed = TRUE;
				}
				if (t->postinsert > 0) {
					t->postinsert--;
					inter_schema_token *close_b =
						InterSchemas::new_token(CLOSE_BRACE_ISTT, I"}", 0, 0, -1);
					InterSchemas::add_token_after(close_b, t);
					changed = TRUE;
				}
			}
		}
	}
	if (rounds > 1) return NOT_APPLICABLE;
	return FALSE;
}

@<Make pre and post markers from here@> =
	n->preinsert++;
	int found_if = FALSE, brl = 0, posted = FALSE, upped = FALSE;
	inter_schema_token *last_n = n;
	while (n) {
		if (n->ist_type == OPEN_BRACE_ISTT) { brl++; upped = TRUE; }
		if (n->ist_type == CLOSE_BRACE_ISTT) brl--;
		if (n->ist_type == OPEN_ROUND_ISTT) brl++;
		if (n->ist_type == CLOSE_ROUND_ISTT) brl--;
		if ((brl == 0) && (n->ist_type == RESERVED_ISTT) && (n->reserved_word == IF_I6RW))
			found_if = TRUE;
		if ((brl == 0) &&
			((n->ist_type == DIVIDER_ISTT) ||
				((upped) && (n->ist_type == CLOSE_BRACE_ISTT)))) {
			inter_schema_token *m = n->next;
			while ((m) && (m->ist_type == WHITE_SPACE_ISTT)) m = m->next;
			if ((found_if == FALSE) || (m == NULL) || (m->ist_type != RESERVED_ISTT) ||
				(m->reserved_word != ELSE_I6RW)) {
				n->postinsert++; posted = TRUE;
				break;
			}
		}
		last_n = n;
		n = n->next;
	}
	if (posted == FALSE) {
		last_n->postinsert++;
	}

@h The unbrace schema ramification.
We now remove braces used to delimit code blocks and replace them with |CODE_ISNT|
subtrees. So for example
= (text)
	EXPRESSION_ISNT
		T1
		OPEN_BRACE_ISTT
		T2
		T3
		CLOSE_BRACE_ISTT
		T4
=
becomes
= (text)
	EXPRESSION_ISNT
		T1
	CODE_ISNT
		EXPRESSION_ISNT
			T2
			T3
	EXPRESSION_ISNT
		T4
=
In this way, all matching pairs of |OPEN_BRACE_ISTT| and |CLOSE_BRACE_ISTT| tokens
are removed.

=
int Ramification::unbrace_schema(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		for (inter_schema_token *t = isn->expression_tokens, *prev = NULL; t; prev = t, t=t->next) {
			if ((prev) && (t->ist_type == OPEN_BRACE_ISTT)) {
				prev->next = NULL;
				inter_schema_node *code_isn =
					InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
				isn->child_node = code_isn;
				code_isn->parent_node = isn;

				inter_schema_node *new_isn =
					InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				code_isn->child_node = new_isn;
				new_isn->parent_node = code_isn;

				prev = t; t = t->next;
				while ((t) && (t->ist_type == WHITE_SPACE_ISTT)) { prev = t; t = t->next; }

				new_isn->expression_tokens = t;
				inter_schema_token *n = new_isn->expression_tokens, *pn = NULL;
				int brl = 1;
				while (n) {
					if (n->ist_type == OPEN_BRACE_ISTT) brl++;
					if (n->ist_type == CLOSE_BRACE_ISTT) brl--;
					if (n->ist_type == OPEN_ROUND_ISTT) brl++;
					if (n->ist_type == CLOSE_ROUND_ISTT) brl--;
					n->owner = new_isn;
					if (brl == 0) {
						if (pn == NULL) new_isn->expression_tokens = NULL;
						else pn->next = NULL;
						break;
					}
					pn = n; n = n->next;
				}
				if (n) {
					inter_schema_token *resumed = n->next;
					n->next = NULL;
					while ((resumed) && (resumed->ist_type == WHITE_SPACE_ISTT))
						resumed = resumed->next;
					if (resumed) {
						inter_schema_node *new_isn =
							InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						new_isn->expression_tokens = resumed;
						new_isn->parent_node = isn->parent_node;
						InterSchemas::changed_tokens_on(new_isn);
						inter_schema_node *saved = isn->next_node;
						isn->next_node = new_isn;
						new_isn->next_node = saved;
					}
				}
				return TRUE;
			}
		}
		if (Ramification::unbrace_schema(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@h The divide schema ramification.
A |DIVIDER_ISTT| token represents a semicolon used to divide I6 statements.
We want to represent them, however, by independent subtrees. So:
= (text)
	EXPRESSION_ISNT
		T1
		T2
		DIVIDER_ISTT
		T3
		T4
		DIVIDER_ISTT
=
becomes
= (text)
	EXPRESSION_ISNT
		T1
		T2
		DIVIDER_ISTT
	EXPRESSION_ISNT
		T3
		T4
		DIVIDER_ISTT
=
After this stage, therefore, each statement occupies its own |EXPRESSION_ISNT|.

=
int Ramification::divide_schema(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		int bl = 0;
		for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
			if (t->ist_type == OPEN_ROUND_ISTT) bl++;
			if (t->ist_type == CLOSE_ROUND_ISTT) bl--;
			if ((bl == 0) && (t->ist_type == DIVIDER_ISTT) && (t->next)) {
				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				new_isn->expression_tokens = t->next;
				new_isn->parent_node = isn->parent_node;
				if (isn->child_node) {
					new_isn->child_node = isn->child_node;
					new_isn->child_node->parent_node = new_isn;
					isn->child_node = NULL;
				}
				InterSchemas::changed_tokens_on(new_isn);
				inter_schema_node *saved = isn->next_node;
				isn->next_node = new_isn;
				new_isn->next_node = saved;
				t->next = NULL;
				return TRUE;
			}
		}
		if (Ramification::divide_schema(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@h The undivide schema ramification.
The expression nodes for statements now tend to end with |DIVIDER_ISTT| tokens
which no longer have any useful meaning. We remove them. For example:
= (text)
	EXPRESSION_ISNT
		T1
		T2
		DIVIDER_ISTT
	EXPRESSION_ISNT
		T3
		T4
		DIVIDER_ISTT
=
becomes
= (text)
	EXPRESSION_ISNT
		T1
		T2
	EXPRESSION_ISNT
		T3
		T4
=
After this, then, there are no further |DIVIDER_ISTT| tokens in the tree.

=
int Ramification::undivide_schema(inter_schema_node *par, inter_schema_node *isn) {
	int rv = FALSE;
	for (; isn; isn=isn->next_node) {
		inter_schema_token *t = isn->expression_tokens;
		if ((t) && (t->ist_type == DIVIDER_ISTT)) {
			isn->expression_tokens = NULL;
			isn->semicolon_terminated = TRUE;
			rv = TRUE;
		} else {
			while ((t) && (t->next)) {
				if (t->next->ist_type == DIVIDER_ISTT) {
					t->next = NULL; isn->semicolon_terminated = TRUE; rv = TRUE; break;
				}
				t = t->next;
			}
		}
		if (Ramification::undivide_schema(isn, isn->child_node)) rv = TRUE;
	}
	return rv;
}

@h The resolve halfopen blocks ramification.
At this point, all matching pairs of open and close braces have been removed.
But that doesn't quite solve the problem of code blocks, because an inline
phrase in Inform 7 can use the notations |{-open-brace}| or |{-close-brace}|
to indicate that a code block must be opened or closed, in a way which does
not pair up.

There is clearly no way for a tree structure to encode a half-open subtree,
so the schema itself has to have a special annotation made in this case, which
is done by calling //InterSchemas::mark_unclosed// or //InterSchemas::mark_unopened//.
It is inconvenient to delete the brace command node (we might end up with an
empty |EXPRESSION_ISNT| list), so instead we convert it to a harmless piece
of white space.

At the end of this process, then, all code blocks are correctly handled, and
all statements are held as single |EXPRESSION_ISNT| nodes. So the coarse
structure of the code is correctly handled -- we have a clear tree structure
of statements (or expressions), hierarchically arranged in code blocks.

=
int Ramification::resolve_halfopen_blocks(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		inter_schema_token *t = isn->expression_tokens;
		while ((t) && (t->ist_type == WHITE_SPACE_ISTT)) t = t->next;
		if ((t) && (t->ist_type == INLINE_ISTT) && (t->inline_command == open_brace_ISINC)) {
			InterSchemas::mark_unclosed(isn);
			t->ist_type = WHITE_SPACE_ISTT;
			t->material = I" ";
			return TRUE;
		}
		if ((t) && (t->ist_type == INLINE_ISTT) && (t->inline_command == close_brace_ISINC)) {
			InterSchemas::mark_unopened(isn);
			t->ist_type = WHITE_SPACE_ISTT;
			t->material = I" ";
			if (t->next) {
				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				new_isn->expression_tokens = t->next;
				new_isn->parent_node = isn->parent_node;
				if (isn->child_node) {
					new_isn->child_node = isn->child_node;
					new_isn->child_node->parent_node = new_isn;
					isn->child_node = NULL;
				}
				InterSchemas::changed_tokens_on(new_isn);
				inter_schema_node *saved = isn->next_node;
				isn->next_node = new_isn;
				new_isn->next_node = saved;
				t->next = NULL;
			}
			return TRUE;
		}
		if (Ramification::resolve_halfopen_blocks(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@h The break early bracings ramification.
If an expression list begins with one or more braced commands, perhaps with some
white space, and then continues with some honest I6 material, we divide the
early commands off from the subsequent matter. Thus:
= (text)
	EXPRESSION_ISNT
		INLINE_ISTT
		WHITE_SPACE_ISTT
		INLINE_ISTT
		WHITE_SPACE_ISTT
		T1
		T2
		T3
=
becomes
= (text)
	EXPRESSION_ISNT
		INLINE_ISTT
		WHITE_SPACE_ISTT
		INLINE_ISTT
		WHITE_SPACE_ISTT
	EXPRESSION_ISNT
		T1
		T2
		T3
=

=
int Ramification::break_early_bracings(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		inter_schema_token *n = isn->expression_tokens;
		if (n) {
			inter_schema_token *m = NULL;
			while (Ramification::permitted_early(n)) {
				m = n;
				n = n->next;
			}
			if ((m) && (n) && (n->ist_type == RESERVED_ISTT)) {
				inter_schema_node *new_isn =
					InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				new_isn->expression_tokens = n;
				new_isn->parent_node = isn->parent_node;
				if (isn->child_node) {
					new_isn->child_node = isn->child_node;
					new_isn->child_node->parent_node = new_isn;
					isn->child_node = NULL;
				}
				InterSchemas::changed_tokens_on(new_isn);
				inter_schema_node *saved = isn->next_node;
				isn->next_node = new_isn;
				new_isn->next_node = saved;
				m->next = NULL;
				return TRUE;
			}
		}
		if (Ramification::break_early_bracings(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}
int Ramification::permitted_early(inter_schema_token *n) {
	if ((n) && (n->ist_type == INLINE_ISTT)) return TRUE;
	if ((n) && (n->ist_type == WHITE_SPACE_ISTT)) return TRUE;
	return FALSE;
}

@h The strip leading white space ramification.
If an expression begins with white space, remove it. (This makes coding subsequent
ramifications easier -- because we can assume the first token is substantive.)

=
int Ramification::strip_leading_white_space(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		inter_schema_token *t = isn->expression_tokens;
		if ((t) && (t->ist_type == WHITE_SPACE_ISTT)) {
			isn->expression_tokens = t->next;
			return TRUE;
		}
		if (Ramification::strip_leading_white_space(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@h The split switches into cases ramification.
Unlike most C-like languages, Inform 6 does not have a |case| reserved word to
introduce cases in a |switch| statement. For example:
= (text as Inform 6)
	switch (x) {
		1, 2, 3: print "Do one thing.";
		4: print "Do a different thing.";
		default: print "Otherwise, do this other thing.";
	}
=
Here, the colons and the reserved word |default| are the important syntactic markers.
We break this up as three code blocks:
= (text)
	STATEMENT_ISNT "case"
		EXPRESSION_ISNT
			1
			COMMA_ISTT
			WHITE_SPACE_ISTT
			2
			COMMA_ISTT
			WHITE_SPACE_ISTT
			3
		CODE_ISNT
			...
	STATEMENT_ISNT "case"
		EXPRESSION_ISNT
			4
		CODE_ISNT
			...
	STATEMENT_ISNT "default"
		CODE_ISNT
			...
=

=		
int Ramification::split_switches_into_cases(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if (isn->expression_tokens) {
			inter_schema_token *n = isn->expression_tokens, *prev = isn->expression_tokens;
			int bl = 0;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) bl++;
				if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
				if ((n->ist_type == COLON_ISTT) && (bl == 0)) {
					inter_schema_node *original_child = isn->child_node;

					int defaulter = FALSE;
					if ((isn->expression_tokens) &&
						(isn->expression_tokens->ist_type == RESERVED_ISTT) &&
						(isn->expression_tokens->reserved_word == DEFAULT_I6RW)) defaulter = TRUE;
					
					inter_schema_node *sw_val = NULL;
					inter_schema_node *sw_code = NULL;
					if (defaulter) {
						sw_code = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
						isn->child_node = sw_code;
						sw_code->parent_node = isn;
					} else {
						sw_val = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						sw_code = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
						sw_val->next_node = sw_code;
						sw_val->parent_node = isn; isn->child_node = sw_val;
						sw_code->parent_node = isn;
					}

					int switch_begins = FALSE;
					int switch_ends = FALSE;
					inter_schema_node *pn = isn->parent_node;
					while (pn) {
						if ((pn->expression_tokens) &&
							(pn->expression_tokens->ist_type == RESERVED_ISTT) &&
							(pn->expression_tokens->reserved_word == SWITCH_I6RW)) {
							switch_begins = TRUE;
							inter_schema_node *pn2 = isn;
							while (pn2) {
								if (pn2->next_node) { switch_ends = TRUE; break; }
								pn2 = pn2->parent_node;
							}
							break;
						}
						pn = pn->parent_node;
					}
					if (switch_ends == FALSE) InterSchemas::mark_unclosed(sw_code);
					if (switch_begins == FALSE) InterSchemas::mark_case_closed(isn);
					if (sw_val) sw_val->expression_tokens = isn->expression_tokens;
					prev->next = NULL;
					isn->expression_tokens = NULL;
					isn->isn_type = STATEMENT_ISNT;
					if (defaulter)
						isn->isn_clarifier = DEFAULT_BIP;
					else
						isn->isn_clarifier = CASE_BIP;

					inter_schema_node *sw_code_exp =
						InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					sw_code_exp->expression_tokens = n->next;

					sw_code->child_node = sw_code_exp;
					sw_code_exp->parent_node = sw_code;

					InterSchemas::changed_tokens_on(sw_val);
					InterSchemas::changed_tokens_on(sw_code_exp);
					
					sw_code_exp->child_node = original_child;

					inter_schema_node *at = isn->next_node;
					inter_schema_node *attach = sw_code_exp;
					while ((at) && (Ramification::casey(at) == FALSE)) {
						inter_schema_node *next_at = at->next_node;
						at->next_node = NULL;
						at->parent_node = sw_code;
						attach->next_node = at;
						attach = at;
						isn->next_node = next_at;
						at = next_at;
					}

					return TRUE;
				}
				prev = n; n = n->next;
			}
		}
		if (Ramification::split_switches_into_cases(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int Ramification::casey(inter_schema_node *isn) {
	if (isn == NULL) return FALSE;
	if (isn->expression_tokens) {
		inter_schema_token *n = isn->expression_tokens;
		int bl = 0;
		while (n) {
			if (n->ist_type == OPEN_ROUND_ISTT) bl++;
			if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
			if ((n->ist_type == COLON_ISTT) && (bl == 0)) return TRUE;
			n = n->next;
		}
	}
	return FALSE;
}

@h The split print statements ramification.
Inform 6 supports composite print statements, like so:
= (text as Inform 6)
	print_ret "X is ", x, ".";
=
This example currently looks like:
= (text)
	EXPRESSION_ISNT
		RESERVED_ISTT "print_ret"
		WHITE_SPACE_ISTT
		DQUOTED_ISTT "X is "
		COMMA_ISTT
		WHITE_SPACE_ISTT
		IDENTIFIER_ISTT "x"
		COMMA_ISTT
		WHITE_SPACE_ISTT
		DQUOTED_ISTT "."
=
We break this up as three individual prints:
= (text)
	EXPRESSION_ISNT
		RESERVED_ISTT "print"
		WHITE_SPACE_ISTT
		DQUOTED_ISTT "X is "
	EXPRESSION_ISNT
		RESERVED_ISTT "print"
		WHITE_SPACE_ISTT
		IDENTIFIER_ISTT "x"
	EXPRESSION_ISNT
		RESERVED_ISTT "print_ret"
		WHITE_SPACE_ISTT
		DQUOTED_ISTT "."
=
Note that, for obvious reasons, in the |print_ret| case only the third of the
prints should perform a return.

The point of this stage is to get rid of one source of |COMMA_ISTT| tokens;
commas can mean a number of different things in Inform 6 syntax and it makes
our work simpler to take one of those meanings out of the picture.

=
int Ramification::split_print_statements(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if (isn->expression_tokens) {
			if ((isn->expression_tokens->ist_type == RESERVED_ISTT)
				&& ((isn->expression_tokens->reserved_word == PRINT_I6RW) ||
					(isn->expression_tokens->reserved_word == PRINTRET_I6RW))) {
				inter_schema_token *n = isn->expression_tokens->next, *prev = isn->expression_tokens;
				int bl = 0;
				while (n) {
					if (n->ist_type == OPEN_ROUND_ISTT) bl++;
					if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
					if ((n->ist_type == COMMA_ISTT) && (bl == 0)) {
						prev->next = NULL;
						n->ist_type = RESERVED_ISTT;
						n->reserved_word = isn->expression_tokens->reserved_word;
						isn->expression_tokens->reserved_word = PRINT_I6RW;
						isn->expression_tokens->material = I"print";
						if (n->reserved_word == PRINT_I6RW) n->material = I"print";
						else n->material = I"print_ret";
						inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						new_isn->expression_tokens = n;
						new_isn->parent_node = isn->parent_node;
						InterSchemas::changed_tokens_on(new_isn);
						inter_schema_node *saved = isn->next_node;
						isn->next_node = new_isn;
						new_isn->next_node = saved;
						new_isn->semicolon_terminated = isn->semicolon_terminated;
						return TRUE;
					}
					prev = n; n = n->next;
				}
			}
		}
		if (Ramification::split_print_statements(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@h The identify constructs ramification.
At this point each individual expression or statement is represented by the
tokens under an |EXPRESSION_ISNT| node. It's legal to give an expression as
a statement in Inform 6, i.e., in void context, just as it is in C. But we
can tell the difference because statements are introduced by reserved words
such as |while|; and this is where we do that.

=
int Ramification::identify_constructs(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if (isn->expression_tokens) {
			inter_ti which_statement = 0;
			int dangle_number = -1;
			text_stream *dangle_text = NULL;
			inter_schema_token *operand1 = NULL, *operand2 = NULL;
			inter_schema_node *operand2_node = NULL;
			switch (isn->expression_tokens->ist_type) {
				case RESERVED_ISTT:
					@<If this expression opens with a reserved word, it may be a statement@>;
					break;
				case DIRECTIVE_ISTT:
					@<If this expression opens with a directive keyword, it is a directive@>;
					break;
				case OPCODE_ISTT:
					@<If this expression opens with an opcode keyword, it is an assembly line@>;
					break;
			}

			if (which_statement) {
				@<Make this a STATEMENT_ISNT node@>;
				return TRUE;
			}
		}
		if ((isn->isn_type != ASSEMBLY_ISNT) && (isn->isn_type != DIRECTIVE_ISNT))
			if (Ramification::identify_constructs(isn, isn->child_node)) return TRUE;
	}

	return FALSE;
}

@ To have the node converted from |EXPRESSION_ISNT| to |STATEMENT_ISNT|, we must
set |which_statement| to the BIP of the Inter primitive which will implement it.
If we set |dangle_number| to some non-negative value, then that will be added
as an argument. Thus:
= (text)
	EXPRESSION_ISNT
		rfalse
=
becomes:
=
	STATEMENT_ISNT - RETURN_BIP
		EXPRESSION_ISNT
			0
=
The |0| is an invention -- in that it never occurs in the original text -- and
its expression dangles beneath the |STATEMENT_ISNT| node; and similarly for
a |dangle_text|, of course.

@<If this expression opens with a reserved word, it may be a statement@> =
	switch (isn->expression_tokens->reserved_word) {
		case BREAK_I6RW:      which_statement = BREAK_BIP; break;
		case CONTINUE_I6RW:   which_statement = CONTINUE_BIP; break;
		case DO_I6RW:         @<This is a do statement@>; break;
		case FONT_I6RW:       @<This is a font statement@>; break;
		case FOR_I6RW:        which_statement = FOR_BIP; break;
		case GIVE_I6RW:       @<This is a give statement@>; break;
		case IF_I6RW:         @<This is an if statement@>; break;
		case INVERSION_I6RW:  which_statement = PRINT_BIP; dangle_text = I"v6"; break;
		case JUMP_I6RW:       which_statement = JUMP_BIP; break;
		case MOVE_I6RW:       @<This is a move statement@>; break;
		case NEWLINE_I6RW:    which_statement = PRINT_BIP; dangle_text = I"\n"; break;
		case OBJECTLOOP_I6RW: which_statement = OBJECTLOOP_BIP; break;
		case PRINT_I6RW:
		case PRINTRET_I6RW:   @<This is a print statement@>; break;
		case QUIT_I6RW:       which_statement = QUIT_BIP; break;
		case READ_I6RW:       @<This is a read statement@>; break;
		case REMOVE_I6RW:     which_statement = REMOVE_BIP; break;
		case RESTORE_I6RW:    which_statement = RESTORE_BIP; break;
		case RETURN_I6RW:     which_statement = RETURN_BIP; break;
		case RFALSE_I6RW:     which_statement = RETURN_BIP; dangle_number = 0; break;
		case RTRUE_I6RW:      which_statement = RETURN_BIP; dangle_number = 1; break;
		case SPACES_I6RW:     which_statement = SPACES_BIP; break;
		case STYLE_I6RW:      @<This is a style statement@>; break;
		case SWITCH_I6RW:     which_statement = SWITCH_BIP; break;
		case WHILE_I6RW:      which_statement = WHILE_BIP; break;
	}

@<This is a do statement@> =
	which_statement = DO_BIP;
	inter_schema_node *next_isn = isn->next_node;
	if ((next_isn) && (next_isn->expression_tokens) &&
		(next_isn->expression_tokens->ist_type == RESERVED_ISTT) &&
		(next_isn->expression_tokens->reserved_word == UNTIL_I6RW)) {
		isn->next_node = next_isn->next_node;
		inter_schema_token *n = next_isn->expression_tokens->next;
		while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
		operand1 = n;
	} else {
		internal_error("do without until");
	}

@<This is a font statement@> =
	which_statement = FONT_BIP;
	inter_schema_token *n = isn->expression_tokens->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	if ((n) && (Str::eq(n->material, I"on"))) dangle_number = 1;
	if ((n) && (Str::eq(n->material, I"off"))) dangle_number = 0;

@<This is a give statement@> =
	inter_schema_token *n = isn->expression_tokens->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	operand1 = n;
	n = n->next;
	operand1->next = NULL;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	if ((n) && (n->ist_type == OPERATOR_ISTT) &&
		(n->operation_primitive == BITWISENOT_BIP)) {
		which_statement = STORE_BIP; dangle_number = 0;
		n = n->next;
	} else {
		which_statement = STORE_BIP; dangle_number = 1;
	}
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	operand2 = n;

@<This is an if statement@> =
	which_statement = IF_BIP;
	inter_schema_token *n = isn->expression_tokens->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	operand1 = n;
	inter_schema_node *next_isn = isn->next_node;
	if ((next_isn) && (next_isn->expression_tokens) &&
		(next_isn->expression_tokens->ist_type == RESERVED_ISTT) &&
		(next_isn->expression_tokens->reserved_word == ELSE_I6RW) &&
		(next_isn->child_node)) {
		inter_schema_token *n = next_isn->child_node->child_node->expression_tokens;
		while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
		operand2 = n;
		if (n) {
			which_statement = IFELSE_BIP;
			operand2_node = next_isn->child_node;
		}
		isn->next_node = next_isn->next_node;
	}

@<This is a move statement@> =
	inter_schema_token *n = isn->expression_tokens->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	operand1 = n;
	while (n) {
		if (Str::eq(n->material, I"to")) {
			n->ist_type = WHITE_SPACE_ISTT;
			n->material = I" ";
			operand2 = n->next;
			n->next = NULL;
			while ((operand2) && (operand2->ist_type == WHITE_SPACE_ISTT)) operand2 = operand2->next;
			break;
		}
		n = n->next;
	}
	if ((operand1) && (operand2)) which_statement = MOVE_BIP;

@<This is a style statement@> =
	inter_schema_token *n = isn->expression_tokens->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	if ((n) && (Str::eq(n->material, I"roman"))) {
		which_statement = STYLE_BIP;
		dangle_number = 0;
	} else if ((n) && (Str::eq(n->material, I"bold"))) {
		which_statement = STYLE_BIP;
		dangle_number = 1;
	} else if ((n) && (Str::eq(n->material, I"underline"))) {
		which_statement = STYLE_BIP;
		dangle_number = 2;
	} else if ((n) && (Str::eq(n->material, I"reverse"))) {
		which_statement = STYLE_BIP;
		dangle_number = 3;
	} else {
		which_statement = STYLE_BIP;
	}

@<This is a print statement@> =
	which_statement = PRINTNUMBER_BIP;
	inter_schema_token *n = isn->expression_tokens->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	if ((n) && (n->ist_type == OPEN_ROUND_ISTT)) {
		n = n->next;
		while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
		inter_schema_token *pr = n;
		if (pr) {
			n = n->next;
			while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
			if ((n) && (n->ist_type == CLOSE_ROUND_ISTT)) {
				n = n->next;
				while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				if (Str::eq(pr->material, I"address")) {
					which_statement = PRINTDWORD_BIP;
					operand1 = n;
				} else if (Str::eq(pr->material, I"char")) {
					which_statement = PRINTCHAR_BIP;
					operand1 = n;
				} else if (Str::eq(pr->material, I"string")) {
					which_statement = PRINTSTRING_BIP;
					operand1 = n;
				} else if (Str::eq(pr->material, I"object")) {
					which_statement = PRINTOBJ_BIP;
					operand1 = n;
				} else {
					if (Str::eq(pr->material, I"the")) pr->material = I"DefArt";
					if (Str::eq(pr->material, I"The")) pr->material = I"CDefArt";
					if ((Str::eq(pr->material, I"a")) || (Str::eq(pr->material, I"an"))) pr->material = I"IndefArt";
					if ((Str::eq(pr->material, I"A")) || (Str::eq(pr->material, I"An"))) pr->material = I"CIndefArt";
					if (Str::eq(pr->material, I"number")) pr->material = I"LanguageNumber";
					if (Str::eq(pr->material, I"name")) pr->material = I"PrintShortName";
					if (Str::eq(pr->material, I"property")) pr->material = I"DebugProperty";
					isn->expression_tokens = pr;
					inter_schema_token *open_b =
						InterSchemas::new_token(OPEN_ROUND_ISTT, I"(", 0, 0, -1);
					InterSchemas::add_token_after(open_b, isn->expression_tokens);
					open_b->next = n;
					n = open_b;
					while ((n) && (n->next)) n = n->next;
					inter_schema_token *close_b =
						InterSchemas::new_token(CLOSE_ROUND_ISTT, I")", 0, 0, -1);
					InterSchemas::add_token_after(close_b, n);
					which_statement = 0;
					operand1 = NULL;
				}
			}
		}
	}
	if (which_statement == PRINTNUMBER_BIP) {
		inter_schema_token *n = isn->expression_tokens->next;
		while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
		if ((n) && (n->ist_type == DQUOTED_ISTT)) {
			which_statement = PRINT_BIP;
			Tokenisation::de_escape_text(n->material);
		}
	}
	if (isn->expression_tokens->reserved_word == PRINTRET_I6RW) {
		inter_schema_node *save_next = isn->next_node;
		isn->next_node = InterSchemas::new_node(isn->parent_schema, STATEMENT_ISNT);
		isn->next_node->parent_node = isn->parent_node;
		isn->next_node->isn_clarifier = PRINT_BIP;
		isn->next_node->child_node = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
		isn->next_node->child_node->parent_node = isn->next_node;
		InterSchemas::add_token_to_node(isn->next_node->child_node, InterSchemas::new_token(DQUOTED_ISTT, I"\n", 0, 0, -1));
		isn->next_node->next_node = InterSchemas::new_node(isn->parent_schema, STATEMENT_ISNT);
		isn->next_node->next_node->parent_node = isn->parent_node;
		isn->next_node->next_node->isn_clarifier = RETURN_BIP;
		isn->next_node->next_node->next_node = save_next;
	}

@<This is a read statement@> =
	inter_schema_token *n = isn->expression_tokens->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	operand1 = n;
	n = n->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	operand2 = n;
	operand1->next = NULL;
	operand2->next = NULL;
	if ((operand1) && (operand2)) which_statement = READ_XBIP;

@<If this expression opens with a directive keyword, it is a directive@> =
	isn->isn_type = DIRECTIVE_ISNT;
	isn->dir_clarifier = isn->expression_tokens->reserved_word;
	if (isn->expression_tokens->next) {
		inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
		isn->child_node = new_isn;
		new_isn->parent_node = isn;
		new_isn->expression_tokens = isn->expression_tokens->next;
		InterSchemas::changed_tokens_on(new_isn);
	}
	isn->expression_tokens = NULL;
	which_statement = 0;

@<If this expression opens with an opcode keyword, it is an assembly line@> =
	if (Str::eq(isn->expression_tokens->material, I"@push")) which_statement = PUSH_BIP;
	else if (Str::eq(isn->expression_tokens->material, I"@pull")) which_statement = PULL_BIP;
	else {
		isn->isn_type = ASSEMBLY_ISNT;
		inter_schema_node *prev_node = NULL;
		for (inter_schema_token *l = isn->expression_tokens, *n = l?(l->next):NULL; l; l=n, n=n?(n->next):NULL) {
			if (l->ist_type != WHITE_SPACE_ISTT) {
				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				new_isn->expression_tokens = l; l->next = NULL; l->owner = new_isn;
				if (l->operation_primitive) {
					l->ist_type = IDENTIFIER_ISTT;
					l->operation_primitive = 0;
				}
				if ((n) && (Str::eq(l->material, I"-"))) {
					l->material = Str::new();
					WRITE_TO(l->material, "-%S", n->material);
					l->ist_type = NUMBER_ISTT;
					n = n->next;
				}
				if (Str::eq(l->material, I"->")) l->ist_type = ASM_ARROW_ISTT;
				if (Str::eq(l->material, I"sp")) l->ist_type = ASM_SP_ISTT;
				if ((Str::eq(l->material, I"?")) && (n)) {
					l->ist_type = ASM_LABEL_ISTT;
					l->material = n->material;
					n = n->next;
					if (Str::eq(l->material, I"~")) {
						l->ist_type = ASM_NEGATED_LABEL_ISTT;
						l->material = n->material;
						n = n->next;
					}
				}
				if (isn->child_node == NULL) isn->child_node = new_isn;
				else if (prev_node) prev_node->next_node = new_isn;
				new_isn->parent_node = isn;
				prev_node = new_isn;
			}
		}
		isn->expression_tokens = NULL;
	}

@<Make this a STATEMENT_ISNT node@> =
	inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
	if (operand1 == NULL) operand1 = isn->expression_tokens->next;
	new_isn->expression_tokens = operand1;
	if ((new_isn->expression_tokens) &&
		(new_isn->expression_tokens->ist_type == WHITE_SPACE_ISTT))
			new_isn->expression_tokens = new_isn->expression_tokens->next;
	InterSchemas::changed_tokens_on(new_isn);
	isn->isn_clarifier = which_statement;
	isn->isn_type = STATEMENT_ISNT;
	isn->expression_tokens = NULL;
	new_isn->next_node = isn->child_node;
	isn->child_node = new_isn;
	new_isn->parent_node = isn;

	if ((which_statement != STORE_BIP) && (dangle_number >= 0)) {
		text_stream *T = Str::new();
		WRITE_TO(T, "%d", dangle_number);
		new_isn->expression_tokens = InterSchemas::new_token(NUMBER_ISTT, T, 0, 0, -1);
		new_isn->expression_tokens->owner = new_isn;
	}
	if (Str::len(dangle_text) > 0) {
		new_isn->expression_tokens = InterSchemas::new_token(DQUOTED_ISTT, dangle_text, 0, 0, -1);
		new_isn->expression_tokens->owner = new_isn;
		Tokenisation::de_escape_text(new_isn->expression_tokens->material);
	}

	if (operand2) {
		inter_schema_node *new_new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
		if (which_statement == IFELSE_BIP) {
			new_new_isn->semicolon_terminated = TRUE;
			new_new_isn->next_node = new_isn->next_node->next_node;
			new_isn->next_node->next_node = new_new_isn;
		} else {
			new_new_isn->next_node = new_isn->next_node;
			new_isn->next_node = new_new_isn;
		}
		new_new_isn->parent_node = isn;
		new_new_isn->expression_tokens = operand2;
		if ((new_new_isn->expression_tokens) && (new_new_isn->expression_tokens->ist_type == WHITE_SPACE_ISTT))
			new_new_isn->expression_tokens = new_new_isn->expression_tokens->next;
		InterSchemas::changed_tokens_on(new_new_isn);
	}
	if (operand2_node) {
		operand2_node->next_node = NULL;
		new_isn->next_node->next_node = operand2_node;
		operand2_node->parent_node = isn;
		InterSchemas::changed_tokens_on( operand2_node->child_node);
	}
	if (which_statement == STORE_BIP) {
		isn->isn_clarifier = 0;
		isn->isn_type = EXPRESSION_ISNT;
		inter_schema_node *A = isn->child_node;
		inter_schema_node *B = isn->child_node->next_node;
		isn->child_node = NULL;
		isn->expression_tokens = A->expression_tokens;
		isn->expression_tokens->next =
			InterSchemas::new_token(OPERATOR_ISTT, I".", PROPERTYVALUE_BIP, 0, -1);
		isn->expression_tokens->next->next = B->expression_tokens;
		isn->expression_tokens->next->next->next = InterSchemas::new_token(OPERATOR_ISTT, I"=", STORE_BIP, 0, -1);
		text_stream *T = Str::new();
		WRITE_TO(T, "%d", dangle_number);
		isn->expression_tokens->next->next->next->next = InterSchemas::new_token(NUMBER_ISTT, T, 0, 0, -1);
		InterSchemas::changed_tokens_on(isn);
	}

@ =
int Ramification::alternatecases(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if ((isn->isn_clarifier == CASE_BIP) && (isn->child_node)) {
			inter_schema_node *A = isn->child_node;
			inter_schema_node *B = isn->child_node->next_node;
			if ((A) && (B) && (B->next_node)) {
				inter_schema_node *C = InterSchemas::new_node(isn->parent_schema, OPERATION_ISNT);
				C->isn_clarifier = ALTERNATIVECASE_BIP;
				C->child_node = A;
				A->parent_node = C; B->parent_node = C;
				isn->child_node = C; C->next_node = B->next_node; B->next_node = NULL;
				C->parent_node = isn;
				return TRUE;
			}				
		}
		if (Ramification::alternatecases(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int Ramification::treat_constructs(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if ((isn->isn_type == STATEMENT_ISNT) &&
			(isn->isn_clarifier == FOR_BIP) &&
			(isn->node_marked == FALSE)) {
			inter_schema_node *predicates = isn->child_node;
			if ((predicates == NULL) || (predicates->isn_type != EXPRESSION_ISNT))
				internal_error("malformed proto-for");
			inter_schema_token *n = predicates->expression_tokens;
			inter_schema_node *code_node = predicates->next_node;
			int bl = 0, cw = 0;
			inter_schema_token *from[3], *to[3];
			for (int i=0; i<3; i++) { from[i] = 0; to[i] = 0; }
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) {
					if ((bl > 0) && (from[cw] == NULL)) from[cw] = n;
					bl++;
				} else if (n->ist_type == CLOSE_ROUND_ISTT) {
					bl--;
					if (bl == 0) @<End a wodge@>;
				} else if (bl == 1) {
					if (n->ist_type == COLON_ISTT) @<End a wodge@>
					else {
						if (from[cw] == NULL) from[cw] = n;
					}
				}
				n = n->next;
			}
			if (cw != 3) internal_error("malformed for prototype");
			for (int i=0; i<3; i++) {
				inter_schema_node *eval_isn = InterSchemas::new_node(isn->parent_schema, EVAL_ISNT);
				if (i == 0) isn->child_node = eval_isn;
				if (i == 1) isn->child_node->next_node = eval_isn;
				if (i == 2) {
					isn->child_node->next_node->next_node = eval_isn;
					eval_isn->next_node = code_node;
				}
				eval_isn->parent_node = isn;

				inter_schema_node *expr_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				eval_isn->child_node = expr_isn;
				expr_isn->parent_node = eval_isn;

				inter_schema_token *m = from[i];
				while ((m) && (m->ist_type == WHITE_SPACE_ISTT)) m = m->next;
				expr_isn->expression_tokens = m;
				if (m == to[i]) expr_isn->expression_tokens = NULL;
				else {
					while (m) {
						m->owner = expr_isn;
						if (m->next == to[i]) m->next = NULL;
						m = m->next;
					}
				}
			}
			isn->node_marked = TRUE;
			return TRUE;
		}
		if (Ramification::treat_constructs(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@<End a wodge@> =
	if (from[cw] == NULL) to[cw] = NULL;
	else to[cw] = n;
	if (from[cw] == to[cw]) { from[cw] = NULL; to[cw] = NULL; }
	cw++;

@ =
int Ramification::add_missing_bodies(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		int req = 0;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == IF_BIP)) req = 2;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == IFELSE_BIP)) req = 3;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == FOR_BIP)) req = 4;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == WHILE_BIP)) req = 2;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == OBJECTLOOP_BIP)) req = 2;
		if ((req > 0) && (isn->node_marked == FALSE)) {
			int actual = 0;
			for (inter_schema_node *ch = isn->child_node; ch; ch=ch->next_node) actual++;
			if (actual < req-1) internal_error("far too few child nodes");
			if (actual > req) internal_error("too many child nodes");
			if (actual == req-1) {
				inter_schema_node *code_isn = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
				code_isn->parent_node = isn;

				inter_schema_node *ch = isn->child_node;
				while ((ch) && (ch->next_node)) ch=ch->next_node;
				ch->next_node = code_isn;

				InterSchemas::mark_unclosed(code_isn);
				isn->node_marked = TRUE;
				return TRUE;
			}
		}
		if (Ramification::add_missing_bodies(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int Ramification::remove_empties(inter_schema_node *par, inter_schema_node *isn) {
	for (inter_schema_node *prev = NULL; isn; prev = isn, isn = isn->next_node) {
		if ((isn->isn_type == EXPRESSION_ISNT) && (isn->expression_tokens == NULL)) {
			if (prev) prev->next_node = isn->next_node;
			else if (par) par->child_node = isn->next_node;
			else isn->parent_schema->node_tree = isn->next_node;
			return TRUE;
		}
		if (Ramification::remove_empties(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int Ramification::top_level_commas(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if (isn->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *n = isn->expression_tokens, *prev = NULL;
			int bl = 0;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) bl++;
				if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
				if ((n->ist_type == COMMA_ISTT) && (bl == 0) && (prev)) {
					prev->next = NULL;
					prev = n; n = n->next;
					while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) { prev = n; n = n->next; }
					inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					new_isn->expression_tokens = n;
					new_isn->parent_node = isn->parent_node;
					InterSchemas::changed_tokens_on(new_isn);
					inter_schema_node *saved = isn->next_node;
					isn->next_node = new_isn;
					new_isn->next_node = saved;
					new_isn->semicolon_terminated = isn->semicolon_terminated;
					return TRUE;
				}
				prev = n; n = n->next;
			}
		}
		if (Ramification::top_level_commas(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@h The strip all white space ramification.
White space has an important role to play earlier on in the process, but once
our tree structure contains the information it carries, we can discard it.
This simply deletes every token of type |WHITE_SPACE_ISTT|.

=
int Ramification::strip_all_white_space(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if ((isn->expression_tokens) && (isn->expression_tokens->ist_type == WHITE_SPACE_ISTT)) {
			isn->expression_tokens = isn->expression_tokens->next;
			return TRUE;
		}
		int d = 0;
		inter_schema_token *prev = isn->expression_tokens;
		if (prev) {
			inter_schema_token *n = prev->next;
			while (n) {
			 	if (n->ist_type == WHITE_SPACE_ISTT) { prev->next = n->next; d++; }
				prev = n; n = n->next;
			}
		}
		if (d > 0) return TRUE;
		if (Ramification::strip_all_white_space(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}


int Ramification::debracket(inter_schema_node *par, inter_schema_node *isn) {
	if (Ramification::outer_subexpressions(par, isn)) return TRUE;
	if (Ramification::op_subexpressions(par, isn)) return TRUE;
	if (Ramification::place_calls(par, isn)) return TRUE;
	return FALSE;
}

int Ramification::outer_subexpressions(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if (isn->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *n = isn->expression_tokens;
			while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
			if ((n) && (n->ist_type == OPEN_ROUND_ISTT)) {
				int bl = 1, fails = FALSE;
				n = n->next;
				while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				inter_schema_token *from = n, *to = NULL;
				while (n) {
					if ((bl == 0) && (n->ist_type != WHITE_SPACE_ISTT)) fails = TRUE;
					if (n->ist_type == OPEN_ROUND_ISTT) bl++;
					else if (n->ist_type == CLOSE_ROUND_ISTT) {
						bl--;
						if (bl == 0) to = n;
					}
					n = n->next;
				}
				if ((fails == FALSE) && (from) && (to) && (from != to)) {
					inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					new_isn->expression_tokens = from;
					for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next)
						if (l->next == to)
							l->next = NULL;
					InterSchemas::changed_tokens_on(new_isn);
					isn->isn_type = SUBEXPRESSION_ISNT;
					isn->expression_tokens = NULL;

					isn->child_node = new_isn;
					new_isn->parent_node = isn;

					return TRUE;
				}
			}
		}
		if (Ramification::outer_subexpressions(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int Ramification::prefer_over(inter_ti p, inter_ti existing) {
	if (existing == 0) return TRUE;
	if (BIPMetadata::precedence(p) < BIPMetadata::precedence(existing)) return TRUE;
	if ((BIPMetadata::precedence(p) == BIPMetadata::precedence(existing)) &&
		(BIPMetadata::right_associative(p)) &&
		(BIPMetadata::arity(p) == 2) &&
		(BIPMetadata::arity(existing) == 2)) return TRUE;
	return FALSE;
}

int Ramification::op_subexpressions(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if ((isn->node_marked == FALSE) && (isn->isn_type == EXPRESSION_ISNT)) {
			isn->node_marked = TRUE;
			inter_schema_token *n = isn->expression_tokens;
			int bl = 0;
			inter_ti best_operator = 0;
			inter_schema_token *break_at = NULL;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) bl++;
				if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
				if ((bl == 0) && (n->ist_type == OPERATOR_ISTT)) {
					inter_ti this_operator = n->operation_primitive;
					if (Ramification::prefer_over(this_operator, best_operator)) {
						break_at = n; best_operator = this_operator;
					}
				}
				n = n->next;
			}
			if (break_at) {
				inter_schema_token *n = isn->expression_tokens;
				while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				inter_schema_token *from = n, *to = break_at;
				int has_operand_before = FALSE, has_operand_after = FALSE;
				if ((from) && (from != to)) {
					inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					new_isn->expression_tokens = from;
					for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next)
						if (l->next == to)
							l->next = NULL;
					InterSchemas::changed_tokens_on(new_isn);
					if (isn->child_node == NULL) {
						isn->child_node = new_isn;
					} else {
						isn->child_node->next_node = new_isn;
					}
					new_isn->parent_node = isn;
					has_operand_before = TRUE;
				} else {
					if (best_operator == IN_BIP) {
						break_at->ist_type = IDENTIFIER_ISTT;
						break_at->operation_primitive = 0;
						break_at = NULL;
					}
				}
				if (break_at) {
					n = break_at->next;
					while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
					from = n; to = NULL;
					if ((from) && (from != to)) {
						inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						new_isn->expression_tokens = from;
						for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next)
							if (l->next == to)
								l->next = NULL;
						InterSchemas::changed_tokens_on(new_isn);
						if (isn->child_node == NULL) {
							isn->child_node = new_isn;
						} else {
							isn->child_node->next_node = new_isn;
						}
						new_isn->parent_node = isn;
						has_operand_after = TRUE;
					}

					isn->isn_type = OPERATION_ISNT;
					isn->expression_tokens = NULL;
					isn->isn_clarifier = break_at->operation_primitive;
					if ((break_at->operation_primitive == MINUS_BIP) && (has_operand_before == FALSE))
						isn->isn_clarifier = UNARYMINUS_BIP;
					if ((break_at->operation_primitive == POSTINCREMENT_BIP) && (has_operand_before == FALSE))
						isn->isn_clarifier = PREINCREMENT_BIP;
					if ((break_at->operation_primitive == POSTDECREMENT_BIP) && (has_operand_before == FALSE))
						isn->isn_clarifier = PREDECREMENT_BIP;
					if ((break_at->operation_primitive == PROPERTYVALUE_BIP) && (has_operand_before == FALSE)) {
						isn->isn_type = LABEL_ISNT;
						isn->isn_clarifier = 0;
					} else {
						int a = 0;
						if (has_operand_before) a++;
						if (has_operand_after) a++;
						if (a != BIPMetadata::arity(isn->isn_clarifier)) {
							LOG("Seem to have arity %d with isn %S which needs %d\n",
								a, Primitives::BIP_to_name(isn->isn_clarifier),
								BIPMetadata::arity(isn->isn_clarifier));
							LOG("$1\n", isn->parent_schema);
							internal_error("bad arity");
						}
					}
					return TRUE;
				}
			}
		}
		if (Ramification::op_subexpressions(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int Ramification::place_calls(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if (isn->isn_type == EXPRESSION_ISNT) {
			if ((isn->expression_tokens) && (isn->expression_tokens->ist_type == OPEN_ROUND_ISTT)) {
				int bl = 0, term_count = 0, tops = 0;
				inter_schema_token *opener = NULL, *closer = NULL;
				for (inter_schema_token *n = isn->expression_tokens; n; n = n->next) {
					if (n->ist_type == OPEN_ROUND_ISTT) {
						bl++;
						if (bl == 1) { opener = n; closer = NULL; term_count++; }
					} else if (n->ist_type == CLOSE_ROUND_ISTT) {
						bl--;
						if (bl == 0) { closer = n; }
					} else if (bl == 0) tops++;
				}
				if ((term_count == 2) && (tops == 0) && (opener) && (closer)) {
					@<Call brackets found@>;
				}
			}
			inter_schema_token *n = isn->expression_tokens;
			inter_schema_token *opener = NULL, *closer = NULL;
			int pre_count = 0, pre_bracings = 0, post_count = 0, veto = FALSE, bl = 0;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) {
					bl++;
					if (bl == 1) {
						if (opener == NULL) opener = n;
						else veto = TRUE;
					}
				} else if (n->ist_type == CLOSE_ROUND_ISTT) {
					bl--;
					if ((bl == 0) && (closer == NULL)) closer = n;
				} else if ((bl == 0) && (n->ist_type != INLINE_ISTT)) {
					if (opener == NULL) pre_count++;
					if ((opener) && (closer)) post_count++;
				} else if (bl == 0) {
					if (opener == NULL) pre_bracings++;
				}
				n = n->next;
			}
			if (((pre_count == 1) || ((pre_count == 0) && (pre_bracings > 0))) &&
				(post_count == 0) && (opener) && (closer) && (veto == FALSE))
				@<Call brackets found@>;
		}
		if (Ramification::place_calls(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@<Call brackets found@> =
	inter_schema_token *from = isn->expression_tokens, *to = opener, *resume = opener->next;
	@<Relegate node@>;
	inter_schema_token *n = resume; from = n; int bl = 0;
	while ((n != closer) && (n)) {
		if (n->ist_type == OPEN_ROUND_ISTT) bl++;
		if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
		if ((bl == 0) && (n->ist_type == COMMA_ISTT)) {
			to = n; resume = n->next;
			@<Relegate node@>;
			from = resume; n = from;
		} else {
			n = n->next;
		}
	}
	to = closer;
	@<Relegate node@>;

	isn->expression_tokens = NULL; isn->isn_type = CALL_ISNT;
	return TRUE;

@<Relegate node@> =
	if ((from) && (to) && (from != to)) {
		inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
		new_isn->expression_tokens = from;
		for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next)
			if (l->next == to)
				l->next = NULL;
		InterSchemas::changed_tokens_on(new_isn);
		if (isn->child_node == NULL) {
			isn->child_node = new_isn;
		} else {
			inter_schema_node *xisn = isn->child_node;
			while ((xisn) && (xisn->next_node)) xisn = xisn->next_node;
			xisn->next_node = new_isn;
		}
		new_isn->parent_node = isn;
	}

@ =
int Ramification::implied_return_values(inter_schema_node *par, inter_schema_node *isn) {
	for (inter_schema_node *prev = NULL; isn; prev = isn, isn = isn->next_node) {
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == RETURN_BIP) && (isn->child_node == FALSE)) {
			isn->child_node = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
			isn->child_node->parent_node = isn;
			isn->child_node->expression_tokens = InterSchemas::new_token(NUMBER_ISTT, I"1", 0, 0, -1);
			isn->child_node->expression_tokens->owner = isn->child_node;
			return TRUE;
		}
		if (Ramification::implied_return_values(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int Ramification::message_calls(inter_schema_node *par, inter_schema_node *isn) {
	for (inter_schema_node *prev = NULL; isn; prev = isn, isn = isn->next_node) {
		if ((isn->isn_type == OPERATION_ISNT) && (isn->isn_clarifier == PROPERTYVALUE_BIP) &&
			(isn->child_node) && (isn->child_node->next_node) && (isn->child_node->next_node->isn_type == CALL_ISNT)) {
			inter_schema_node *obj = isn->child_node;
			inter_schema_node *message = isn->child_node->next_node->child_node;
			inter_schema_node *args = isn->child_node->next_node->child_node->next_node;
			isn->isn_type = MESSAGE_ISNT; isn->isn_clarifier = 0;
			obj->next_node = message; message->parent_node = isn; message->next_node = args;
			if (message->isn_type == EXPRESSION_ISNT) {
				inter_schema_token *n = message->expression_tokens;
				if ((n) && (Str::eq(n->material, I"call"))) {
					obj->next_node = args; isn->isn_type = CALLMESSAGE_ISNT;
				}
			}
			while (args) { args->parent_node = isn; args = args->next_node; }
			return TRUE;
		}
		if (Ramification::message_calls(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}
