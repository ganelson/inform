[Preform::] Preform.

To parse the word stream against a general grammar defined by Preform.

@h Parsing.
Speed is important in the following
code, but not critical: I optimised it until profiling showed that Inform spent
only about 6\% of its time here.

=
int ptraci = FALSE; /* in this mode, we trace parsing to the debugging log */
int preform_lookahead_mode = FALSE; /* in this mode, we are looking ahead */
int fail_nonterminal_quantum = 0; /* jump forward by this many words in lookahead */
void *preform_backtrack = NULL; /* position to backtrack from in voracious internal */

int Preform::parse_nt_against_word_range(nonterminal *nt, wording W, int *result,
	void **result_p) {
	time_t start_of_nt = time(0);
	if (nt == NULL) internal_error("can't parse a null nonterminal");
	#ifdef INSTRUMENTED_PREFORM
	nt->nonterminal_tries++;
	#endif
	int success_rval = TRUE; /* what to return in the event of a successful match */
	fail_nonterminal_quantum = 0;

	int teppic = ptraci; /* Teppic saves Ptraci */
	ptraci = nt->watched;

	if (ptraci) {
		if (preform_lookahead_mode) ptraci = FALSE;
		else LOG("%V: <%W>\n", nt->nonterminal_id, W);
	}

	int input_length = Wordings::length(W);
	if ((nt->max_nt_words == 0) ||
		((input_length >= nt->min_nt_words) && (input_length <= nt->max_nt_words))) {
		@<Try to match the input text to the nonterminal@>;
	}

	@<The nonterminal has failed to parse@>;
}

@ The routine ends here...

@<The nonterminal has failed to parse@> =
	if (ptraci) LOG("Failed %V (time %d)\n", nt->nonterminal_id, time(0)-start_of_nt);
	ptraci = teppic;
	return FALSE;

@ ...unless a match was made, in which case it ends here. At this point |Q|
and |QP| will hold the results of the match.

@<The nonterminal has successfully parsed@> =
	if (result) *result = Q; if (result_p) *result_p = QP;
	most_recent_result = Q; most_recent_result_p = QP;
	#ifdef INSTRUMENTED_PREFORM
	nt->nonterminal_matches++;
	#endif
	ptraci = teppic;
	return success_rval;

@ Here we see that a successful voracious NT returns the word number it got
to, rather than |TRUE|. Otherwise this is straightforward: we delegate to
an internal NT, or try all possible productions for an external one.

@d RANGE_OPTIMISATION_LENGTH 10

@<Try to match the input text to the nonterminal@> =
	int unoptimised = FALSE;
	if ((Wordings::empty(W)) || (input_length >= RANGE_OPTIMISATION_LENGTH))
		unoptimised = TRUE;
	if (nt->internal_definition) {
		if (nt->voracious) unoptimised = TRUE;
		if ((unoptimised) || (Optimiser::nt_bitmap_violates(W, &(nt->nonterminal_req)) == FALSE)) {
			int r, Q; void *QP = NULL;
			if (Wordings::first_wn(W) >= 0) r = (*(nt->internal_definition))(W, &Q, &QP);
			else { r = FALSE; Q = 0; }
			if (r) {
				if (nt->voracious) success_rval = r;
				if (ptraci) LOG("Succeeded %d\n", time(0)-start_of_nt);
				@<The nonterminal has successfully parsed@>;
			}
		} else {
			if (ptraci) {
				LOG("%V: <%W> violates ", nt->nonterminal_id, W);
				Optimiser::log_range_requirement(&(nt->nonterminal_req));
				LOG("\n");
			}
		}
	} else {
		if ((unoptimised) || (Optimiser::nt_bitmap_violates(W, &(nt->nonterminal_req)) == FALSE)) {
			void *acc_result = NULL;
			production_list *pl;
			for (pl = nt->first_production_list; pl; pl = pl->next_production_list) {
				NATURAL_LANGUAGE_WORDS_TYPE *nl = pl->definition_language;
				if ((primary_Preform_language == NULL) || (primary_Preform_language == nl)) {
					production *pr;
					int last_v = FALSE;
					for (pr = pl->first_production; pr; pr = pr->next_production) {
						int violates = FALSE;
						if (unoptimised == FALSE) {
							if (pr->production_req.ditto_flag) violates = last_v;
							else violates = Optimiser::nt_bitmap_violates(W, &(pr->production_req));
							last_v = violates;
						}
						if (violates == FALSE) {
							@<Parse the given production@>;
						} else {
							if (ptraci) {
								LOG("production in %V: ", nt->nonterminal_id);
								LoadPreform::log_production(pr, FALSE);
								LOG(": <%W> violates ", W);
								Optimiser::log_range_requirement(&(pr->production_req));
								LOG("\n");
							}
						}
					}
				}
			}
			if ((nt->multiplicitous) && (acc_result)) {
				int Q = TRUE; void *QP = acc_result;
				@<The nonterminal has successfully parsed@>;
			}
		} else {
			if (ptraci) {
				LOG("%V: <%W> violates ", nt->nonterminal_id, W);
				Optimiser::log_range_requirement(&(nt->nonterminal_req));
				LOG("\n");
			}
		}
	}

@ So from here on we look only at the external case, where we're parsing the
text against a production.

@<Parse the given production@> =
	if (ptraci) {
		LOG_INDENT;
		@<Log the production match number@>;
		LoadPreform::log_production(pr, FALSE); LOG("\n");
	}
	#ifdef INSTRUMENTED_PREFORM
	pr->production_tries++;
	#endif

	int slow_scan_needed = FALSE;
	#ifdef CORE_MODULE
	parse_node *added_to_result = NULL;
	#endif
	if ((input_length >= pr->min_pr_words) && (input_length <= pr->max_pr_words)) {
		int Q; void *QP = NULL;
		@<Actually parse the given production, going to Fail if we can't@>;

		#ifdef INSTRUMENTED_PREFORM /* record the sentence containing the longest example */
		pr->production_matches++;
		if (Wordings::length(pr->sample_text) < Wordings::length(W)) pr->sample_text = W;
		#endif

		if (ptraci) {
			@<Log the production match number@>;
			LOG("succeeded (%s): ", (slow_scan_needed)?"slowly":"quickly");
			LOG("result: %d\n", Q); LOG_OUTDENT;
		}
		@<The nonterminal has successfully parsed@>;
	}

	Fail:
	if (ptraci) {
		@<Log the production match number@>;
		#ifdef CORE_MODULE
		if (added_to_result) LOG("added to result (%s): $P\n",
			(slow_scan_needed)?"slowly":"quickly", added_to_result);
		else
		#endif
			LOG("failed (%s)\n", (slow_scan_needed)?"slowly":"quickly");
		LOG_OUTDENT;
	}

@<Log the production match number@> =
	if (pr->match_number >= 26) {
		LOG("production /%c%c/: ", 'a'+pr->match_number-26, 'a'+pr->match_number-26);
	} else {
		LOG("production /%c/: ", 'a'+pr->match_number);
	}

@ Okay. So, the strategy is: a fast scan checking the easy things; if that's
not sufficient, a slow scan checking the rest; then making sure brackets
match, if there were any, and last composing the intermediate results into
the final ones. For example, if the production is
= (text as InC)
	adjust the <achingly-slow> to the <exhaustive> at once
=
then the fast scan verifies the presence of "adjust the" and "at once";
the slow scan next looks for all occurrences of "to the", the single strut
for this production; and only then does it test the two slow nonterminals
on the intervening words, if there are any.

@d MAX_RESULTS_PER_PRODUCTION 10
@d MAX_PTOKENS_PER_PRODUCTION 32

@<Actually parse the given production, going to Fail if we can't@> =
	int checked[MAX_PTOKENS_PER_PRODUCTION];
	int intermediates[MAX_RESULTS_PER_PRODUCTION];
	void *intermediate_ps[MAX_RESULTS_PER_PRODUCTION];
	int parsed_open_pos = -1, parsed_close_pos = -1;

	@<Try a fast scan through the production@>;
	if (slow_scan_needed) @<Try a slow scan through the production@>;

	if ((parsed_open_pos >= 0) && (parsed_close_pos >= 0))
		if (Wordings::paired_brackets(Wordings::new(parsed_open_pos, parsed_close_pos)) == FALSE)
			goto Fail;
	@<Compose and store the result@>;

@ Once we have successfully matched the line, we need to compose the
intermediate results into a final result. If |inweb| has compiled a compositor
routine for the nonterminal, we call it: note that it can then return |FALSE|
to fail the production after all, and can even return |FAIL_NONTERMINAL| to
abandon not just this production, but all of the productions. (This is quite
useful as a way to put exceptional syntaxes into the grammar, since it can
make subsequent productions only available in some cases.)

If there's no compositor then the integer result is the production's number,
and the pointer result is null.

@d FAIL_NONTERMINAL -100000
@d FAIL_NONTERMINAL_TO FAIL_NONTERMINAL+1000

@<Compose and store the result@> =
	if (nt->compositor_fn) {
		intermediates[0] = pr->match_number;
		int f = (*(nt->compositor_fn))(&Q, &QP, intermediates, intermediate_ps, nt->range_result, W);
		if (f == FALSE) goto Fail;
		if (nt->multiplicitous) {
			#ifdef CORE_MODULE
			added_to_result = QP;
			acc_result = (void *) SyntaxTree::add_reading((parse_node *) acc_result, QP, W);
			#endif
			goto Fail;
		}
		if ((f >= FAIL_NONTERMINAL) && (f < FAIL_NONTERMINAL_TO)) {
			fail_nonterminal_quantum = f - FAIL_NONTERMINAL;
			@<The nonterminal has failed to parse@>;
		}
	} else {
		Q = pr->match_number; QP = NULL;
	}

@ In the fast scan, we check that all fixed words with known positions
are in those positions.

@<Try a fast scan through the production@> =
	ptoken *pt;
	int wn = -1, tc;
	for (pt = pr->first_ptoken, tc = 0; pt; pt = pt->next_ptoken, tc++) {
		if (pt->ptoken_is_fast) {
			int p = pt->ptoken_position;
			if (p > 0) wn = Wordings::first_wn(W)+p-1;
			else if (p < 0) wn = Wordings::last_wn(W)+p+1;
			if (Preform::parse_fixed_word_ptoken(wn, pt) == FALSE) {
				slow_scan_needed = FALSE;
				goto Fail; /* the word should have been here, and it wasn't */
			}
			if (pt->ve_pt == OPENBRACKET_V) parsed_open_pos = wn;
			if (pt->ve_pt == CLOSEBRACKET_V) parsed_close_pos = wn;
			checked[tc] = wn;
		} else {
			slow_scan_needed = TRUE;
			checked[tc] = -1;
		}
	}
	if ((slow_scan_needed == FALSE) && (wn != Wordings::last_wn(W))) goto Fail; /* input text goes on further */

@ The slow scan is more challenging. We want to loop through all possible
strut positions, where by "possible" we mean that
$$ s_i+\ell_i <= s_{i+1}, \quad i = 0, 1, ..., s $$
and that for each $i$ the $i$-th strut matches the text beginning at $s_i$.

@<Try a slow scan through the production@> =
	int spos[MAX_STRUTS_PER_PRODUCTION]; /* word numbers for where we are trying the struts */
	int NS = pr->no_struts;
	@<Start from the lexicographically earliest strut position@>;
	ptoken *backtrack_token = NULL;
	int backtrack_index = -1, backtrack_to = -1, backtrack_tc = -1;
	while (TRUE) {
		@<Try a slow scan with the current strut positions@>;
		break;
		FailThisStrutPosition: ;
		if (backtrack_token) continue;
		@<Move on to the next strut position@>;
	}

@ We start by finding the lexicographically earliest, i.e., we find the earliest
possible position for $s_0$, then the earliest position from $s_0+\ell_0$ for
$s_1$, and so on. (Our wildcards are not greedy: we match with shortest possible
text rather than longest.)

In all of the code below, the general case with |NS| greater than 1 is actually
valid code for all cases, but experiment shows about a 5\% speed gain from
handling the popular case of one strut separately.

@<Start from the lexicographically earliest strut position@> =
	if (NS == 1) {
		spos[0] = Preform::next_strut_posn_after(W, pr->struts[0], pr->strut_lengths[0], Wordings::first_wn(W));
		if (spos[0] == -1) goto Fail;
	} else if (NS > 1) {
		int s, from = Wordings::first_wn(W);
		for (s=0; s<NS; s++) {
			spos[s] = Preform::next_strut_posn_after(W, pr->struts[s], pr->strut_lengths[s], from);
			if (spos[s] == -1) goto Fail;
			from = spos[s] + pr->strut_lengths[s] + 1;
		}
	}

@ In the general case, we move the final strut forward if we can; if we can't,
we move the penultimate one, then move the final one to the first subsequent
position valid for it; and so on. Ultimately this results in the first strut
being unable to move forwards, at which point, we've lost.

@<Move on to the next strut position@> =
	if (NS == 0) goto Fail;
	else if (NS == 1) {
		spos[0] = Preform::next_strut_posn_after(W, pr->struts[0], pr->strut_lengths[0], spos[0]+1);
		if (spos[0] == -1) goto Fail;
	} else if (NS > 1) {
		int s;
		for (s=NS-1; s>=0; s--) {
			int n = Preform::next_strut_posn_after(W, pr->struts[s], pr->strut_lengths[s], spos[s]+1);
			if (n != -1) { spos[s] = n; break; }
		}
		if (s == -1) goto Fail;
		int from = spos[s] + 1; s++;
		for (; s<NS; s++) {
			spos[s] = Preform::next_strut_posn_after(W, pr->struts[s], pr->strut_lengths[s], from);
			if (spos[s] == -1) goto Fail;
			from = spos[s] + pr->strut_lengths[s] + 1;
		}
	}

@ We can now forget about struts, thankfully, and check the remaining unchecked
ptokens.

@<Try a slow scan with the current strut positions@> =
	int wn = Wordings::first_wn(W), tc;
	ptoken *pt, *nextpt;
	if (backtrack_token) {
		pt = backtrack_token; nextpt = backtrack_token->next_ptoken;
		tc = backtrack_tc; wn = backtrack_to;
		goto Reenter;
	}
	for (pt = pr->first_ptoken, nextpt = (pt)?(pt->next_ptoken):NULL, tc = 0;
		pt;
		pt = nextpt, nextpt = (pt)?(pt->next_ptoken):NULL, tc++) {
		Reenter: ;
		int known_pos = checked[tc];
		if (known_pos >= 0) {
			if (wn > known_pos) goto Fail; /* a theoretical possibility if strut lookahead overreaches */
			wn = known_pos+1;
		} else {
			if (pt->range_starts >= 0) nt->range_result[pt->range_starts] = Wordings::one_word(wn);
			switch (pt->ptoken_category) {
				case FIXED_WORD_PTC: @<Match a fixed word ptoken@>; break;
				case SINGLE_WILDCARD_PTC: @<Match a single wildcard ptoken@>; break;
				case MULTIPLE_WILDCARD_PTC: @<Match a multiple wildcard ptoken@>; break;
				case POSSIBLY_EMPTY_WILDCARD_PTC: @<Match a possibly empty wildcard ptoken@>; break;
				case NONTERMINAL_PTC: @<Match a nonterminal ptoken@>; break;
			}
			if (pt->range_ends >= 0)
				nt->range_result[pt->range_ends] = Wordings::up_to(nt->range_result[pt->range_ends], wn-1);
		}
	}
	if (wn != Wordings::last_wn(W)+1) goto FailThisStrutPosition;

@<Match a fixed word ptoken@> =
	int q = Preform::parse_fixed_word_ptoken(wn, pt);
	if (q == FALSE) goto FailThisStrutPosition;
	if (pt->ve_pt == OPENBRACKET_V) parsed_open_pos = wn;
	if (pt->ve_pt == CLOSEBRACKET_V) parsed_close_pos = wn;
	wn++;

@<Match a single wildcard ptoken@> =
	wn++;

@<Match a multiple wildcard ptoken@> =
	if (wn > Wordings::last_wn(W)) goto FailThisStrutPosition;
	int wt;
	@<Calculate how much to stretch this elastic ptoken@>;
	if (wn > wt) goto FailThisStrutPosition; /* zero length */
	if (pt->balanced_wildcard) {
		int i, bl = 0;
		for (i=wn; i<=wt; i++) {
			if ((Lexer::word(i) == OPENBRACKET_V) || (Lexer::word(i) == OPENBRACE_V)) bl++;
			if ((Lexer::word(i) == CLOSEBRACKET_V) || (Lexer::word(i) == CLOSEBRACE_V)) {
				bl--;
				if (bl < 0) goto FailThisStrutPosition;
			}
		}
		if (bl != 0) goto FailThisStrutPosition;
	}
	wn = wt+1;

@<Match a possibly empty wildcard ptoken@> =
	int wt;
	@<Calculate how much to stretch this elastic ptoken@>;
	wn = wt+1;

@ A voracious nonterminal is offered the entire rest of the word range, and
returns how much it ate. Otherwise, we offer the maximum amount of space
available: if, for word-count reasons, that's never going to match, then
we rely on the recursive call to |Preform::parse_nt_against_word_range| returning a
quick no.

@<Match a nonterminal ptoken@> =
	if ((wn > Wordings::last_wn(W)) && (pt->nt_pt->min_nt_words > 0)) goto FailThisStrutPosition;
	int wt;
	if (pt->nt_pt->voracious) wt = Wordings::last_wn(W);
	else if ((pt->nt_pt->min_nt_words > 0) && (pt->nt_pt->min_nt_words == pt->nt_pt->max_nt_words))
		wt = wn + pt->nt_pt->min_nt_words - 1;
	else @<Calculate how much to stretch this elastic ptoken@>;

	if (pt == backtrack_token) {
		if (ptraci)
			LOG("Reached backtrack position %V: <%W>\n",
				pt->nt_pt->nonterminal_id, Wordings::new(wn, wt));
		preform_backtrack = intermediate_ps[pt->result_index];
	}
	if (ptraci) LOG_INDENT;
	int q = Preform::parse_nt_against_word_range(pt->nt_pt, Wordings::new(wn, wt),
		&(intermediates[pt->result_index]), &(intermediate_ps[pt->result_index]));
	if (ptraci) LOG_OUTDENT;
	if (pt == backtrack_token) { preform_backtrack = NULL; backtrack_token = NULL; }
	if (pt->nt_pt->voracious) {
		if (q > 0) { wt = q; q = TRUE; }
		else if (q < 0) { wt = -q; q = TRUE;
			backtrack_index = pt->result_index; backtrack_to = wn;
			backtrack_token = pt; backtrack_tc = tc;
			if (ptraci)
				LOG("Set backtrack position %V: <%W>\n",
					pt->nt_pt->nonterminal_id, Wordings::new(wn, wt));
		} else { wt = wn; }
	}
	if (pt->negated_ptoken) q = q?FALSE:TRUE;
	if (q == FALSE) goto FailThisStrutPosition;
	if (pt->nt_pt->max_nt_words > 0) wn = wt+1;

@ How much text from the input should this ptoken match? We feed it as much
as possible, and to calculate that, we must either be at the end of the run,
or else know exactly where the next ptoken starts: because its position is
known, or because it's a strut.

This is why two elastic nonterminals in a row won't parse correctly:
= (text as InC)
	frog <amphibian> <pond-preference> toad
=
Preform is unable to work out where the central boundary will occur. In theory
it should try every possibility. But that's inefficient: in practice the
solution is to write the grammar to minimise these cases, and then to set up
<amphibian> as a voracious token, so that it decides the boundary position
for itself. (If <amphibian> is not voracious, the following calculation
probably gives the wrong answer.)

@<Calculate how much to stretch this elastic ptoken@> =
	ptoken *lookahead = nextpt;
	if (lookahead == NULL) wt = Wordings::last_wn(W);
	else {
		int p = lookahead->ptoken_position;
		if (p > 0) wt = Wordings::first_wn(W)+p-2;
		else if (p < 0) wt = Wordings::last_wn(W)+p;
		else if (lookahead->strut_number >= 0) wt = spos[lookahead->strut_number]-1;
		else if ((lookahead->nt_pt)
			&& (pt->negated_ptoken == FALSE)
			&& (Optimiser::ptoken_width(pt) == PTOKEN_ELASTIC)) {
			wt = -1;
		 	nonterminal *target = lookahead->nt_pt;
		 	int save_preform_lookahead_mode = preform_lookahead_mode;
		 	preform_lookahead_mode = TRUE;
			for (int j = wn+1; j <= Wordings::last_wn(W); j++) {
				if (Preform::parse_nt_against_word_range(target, Wordings::new(j, Wordings::last_wn(W)), NULL, NULL)) {
					if ((pt->nt_pt == NULL) ||
						(Preform::parse_nt_against_word_range(pt->nt_pt, Wordings::new(wn, j-1), NULL, NULL))) {
						wt = j-1; break;
					}
				} else {
					if (fail_nonterminal_quantum > 0) j += fail_nonterminal_quantum - 1;
				}
			}
			preform_lookahead_mode = save_preform_lookahead_mode;
			if (wt < 0) goto FailThisStrutPosition;
		} else wt = wn;
	}

@ Here we find the next possible match position for the strut beginning |start|
and of width |len| in words, which begins at word |from| or after. Note that
the strut might run up right to the end of the input text: for example, in
= (text as InC)
	neckties ... tied ***
=
the word "tied" is a strut, because the |***| makes its position uncertain,
but since |***| might match the empty text, "tied" might legally be the
last word in the input text.

=
int Preform::next_strut_posn_after(wording W, ptoken *start, int len, int from) {
	int last_legal_position = Wordings::last_wn(W) - len + 1;
	while (from <= last_legal_position) {
		ptoken *pt;
		int pos = from;
		for (pt = start; pt; pt = pt->next_ptoken) {
			if (pt->ptoken_category == FIXED_WORD_PTC) {
				if (Preform::parse_fixed_word_ptoken(pos, pt)) pos++;
				else break;
			} else {
				int q = Preform::parse_nt_against_word_range(pt->nt_pt,
					Wordings::new(pos, pos+pt->nt_pt->max_nt_words-1),
					NULL, NULL);
				if (pt->negated_ptoken) q = q?FALSE:TRUE;
				if (q) pos += pt->nt_pt->max_nt_words;
				else break;
			}
			if (pos-from >= len) return from;
		}
		from++;
	}
	return -1;
}

@ Finally, a single fixed word, with its annotations and alternatives.

=
int Preform::parse_fixed_word_ptoken(int wn, ptoken *pt) {
	vocabulary_entry *ve = Lexer::word(wn);
	int m = pt->disallow_unexpected_upper;
	ptoken *alt;
	for (alt = pt; alt; alt = alt->alternative_ptoken)
		if ((ve == alt->ve_pt) &&
			((m == FALSE) || (Word::unexpectedly_upper_case(wn) == FALSE)))
			return (pt->negated_ptoken)?FALSE:TRUE;
	return (pt->negated_ptoken)?TRUE:FALSE;
}
