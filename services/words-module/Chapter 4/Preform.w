[Preform::] Preform.

To parse the word stream against a general grammar defined by Preform.

@h Top level.
The purpose of this section is to write //Preform::parse_nt_against_word_range//,
the function which is called whenever Preform grammar is matched against a
wording: the //inweb// preprocessor converts code like:
= (text as InC)
	if (<aquarium-name>(W)) ...
=
into
= (text as C)
	if (Preform::parse_nt_against_word_range(aquarium_name_NTM, W, NULL, NULL)) ...
=
Those last two parameters, |result| and |result_p|, are set only when we are
recursively calling the function from inside itself. Recall that a match against
a NT either succeeds or fails, and that produces the return value of this
function, |TRUE| or |FALSE|; but if it succeeds it also produces both an integer
and a pointer result, though in any given situation either or both may be
irrelevant. When |result| and |result_p| are set, those results are copied
into the variables these pointers point to. In all cases, they are also
written to the global variables |most_recent_result| and |most_recent_result_p|.

=
int ptraci = FALSE; /* in this mode, we trace parsing to the debugging log */
int preform_lookahead_mode = FALSE; /* in this mode, we are looking ahead */
int fail_nonterminal_quantum = 0; /* jump forward by this many words in lookahead */
void *preform_backtrack = NULL; /* position to backtrack from in voracious internal */

int Preform::parse_nt_against_word_range(nonterminal *nt, wording W, int *result,
	void **result_p) {
	time_t start_of_nt = time(0);
	if (nt == NULL) internal_error("can't parse a null nonterminal");
	nt->ins.nonterminal_tries++;
	int success_rval = TRUE; /* what to return in the event of a successful match */
	fail_nonterminal_quantum = 0;
	int teppic = ptraci; /* Teppic saves Ptraci */

	@<Trace watched nonterminals, but not in lookahead mode@>;
	int input_length = Wordings::length(W);
	if ((nt->opt.nt_extremes.max_words == 0) ||
		(LengthExtremes::in_bounds(input_length, nt->opt.nt_extremes)))
		@<Try to match the input text to the nonterminal@>;

	@<The nonterminal has failed to parse@>;
}

@<Trace watched nonterminals, but not in lookahead mode@> =
	ptraci = nt->ins.watched;
	if (ptraci) {
		if (preform_lookahead_mode) ptraci = FALSE;
		else LOG("%V: <%W>\n", nt->nonterminal_id, W);
	}

@ The function ends here...

@<The nonterminal has failed to parse@> =
	Instrumentation::note_nonterminal_fail(nt);
	if (ptraci) LOG("Failed %V (time %d)\n", nt->nonterminal_id, time(0)-start_of_nt);
	ptraci = teppic;
	return FALSE;

@ ...unless a match was made, in which case it ends here. At this point |Q|
and |QP| will hold the results of the match.

@<The nonterminal has successfully parsed@> =
	Instrumentation::note_nonterminal_match(nt, W);
	if (result) *result = Q; if (result_p) *result_p = QP;
	most_recent_result = Q; most_recent_result_p = QP;
	ptraci = teppic;
	return success_rval;

@ Here we see that a successful voracious NT returns the word number it got
to, rather than |TRUE|. Otherwise this is straightforward: we delegate to
an internal NT, or try all possible productions for a regular one.

@d RANGE_OPTIMISATION_LENGTH 10

@<Try to match the input text to the nonterminal@> =
	int unoptimised = FALSE;
	if ((Wordings::empty(W)) || (input_length >= RANGE_OPTIMISATION_LENGTH))
		unoptimised = TRUE;
	if (nt->voracious) unoptimised = TRUE;
	if (nt->internal_definition) @<Try to match to an internal NT@>
	else @<Try to match to a regular NT@>;

@<Try to match to an internal NT@> =
	if ((unoptimised) || (NTI::nt_bitmap_violates(W, &(nt->opt.nt_ntic)) == FALSE)) {
		int r, Q; void *QP = NULL;
		if (Wordings::first_wn(W) >= 0) r = (*(nt->internal_definition))(W, &Q, &QP);
		else { r = FALSE; Q = 0; }
		if (r) {
			if (nt->voracious) success_rval = r;
			if (ptraci) LOG("Succeeded %d\n", time(0)-start_of_nt);
			@<The nonterminal has successfully parsed@>;
		}
	} else @<Log an NTIC violation@>;

@<Try to match to a regular NT@> =
	if ((unoptimised) || (NTI::nt_bitmap_violates(W, &(nt->opt.nt_ntic)) == FALSE)) {
		void *acc_result = NULL;
		for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
			NATURAL_LANGUAGE_WORDS_TYPE *nl = pl->definition_language;
			if ((primary_Preform_language == NULL) || (primary_Preform_language == nl)) {
				int ditto_result = FALSE;
				for (production *pr = pl->first_pr; pr; pr = pr->next_pr)
					@<Try to match to a production@>;
			}
		}
		if ((nt->multiplicitous) && (acc_result)) {
			int Q = TRUE; void *QP = acc_result;
			@<The nonterminal has successfully parsed@>;
		}
	} else @<Log an NTIC violation@>;

@<Log an NTIC violation@> =
	if (ptraci) {
		LOG("%V: <%W> violates ", nt->nonterminal_id, W);
		Instrumentation::log_ntic(&(nt->opt.nt_ntic));
		LOG("\n");
	}

@h Middle level.
So from here on down we look only at the regular case, where we're parsing the
text against a production. Recall that a production's NTIC has the "ditto flag"
if it is the same constraint as the previous productions's NTIC; in which
case we have no need to recompute |violates|.

@<Try to match to a production@> =
	int violates = FALSE;
	if (unoptimised == FALSE) {
		if (pr->opt.pr_ntic.ditto_flag) violates = ditto_result;
		else violates = NTI::nt_bitmap_violates(W, &(pr->opt.pr_ntic));
		ditto_result = violates;
	}
	if (violates == FALSE) {
		if (LengthExtremes::in_bounds(input_length, pr->opt.pr_extremes)) {
			@<Log that the production is entering full parsing@>;
			@<Enter full parsing of production@>;
		} else @<Log a production length violation@>;
	} else @<Log a production NTIC violation@>;

@<Log that the production is entering full parsing@> =
	if (ptraci) {
		LOG_INDENT;
		@<Log the production match number@>;
		Instrumentation::log_production(pr, FALSE); LOG("\n");
	}

@<Log a production length violation@> =
	if (ptraci) {
		LOG("production in %V: ", nt->nonterminal_id);
		Instrumentation::log_production(pr, FALSE);
		LOG(": <%W> violates length ", W);
		Instrumentation::log_extremes(&(pr->opt.pr_extremes));
		LOG("\n");
	}

@<Log a production NTIC violation@> =
	if (ptraci) {
		LOG("production in %V: ", nt->nonterminal_id);
		Instrumentation::log_production(pr, FALSE);
		LOG(": <%W> violates ", W);
		Instrumentation::log_ntic(&(pr->opt.pr_ntic));
		LOG("\n");
	}

@

@d MAX_RESULTS_PER_PRODUCTION 10
@d MAX_PTOKENS_PER_PRODUCTION 32

@<Enter full parsing of production@> =
	int checked[MAX_PTOKENS_PER_PRODUCTION];
	int intermediates[MAX_RESULTS_PER_PRODUCTION];
	void *intermediate_ps[MAX_RESULTS_PER_PRODUCTION];
	int parsed_open_pos = -1, parsed_close_pos = -1;
	int slow_scan_needed = FALSE;
	#ifdef CORE_MODULE
	parse_node *added_to_result = NULL;
	#endif

	@<Actually parse the given production, going to Fail if we can't@>;

	/* Succeed: */
	int Q; void *QP = NULL;
	@<Compose and store the result@>;
	Instrumentation::note_production_match(pr, W);
	@<Log the success of the production@>;
	@<The nonterminal has successfully parsed@>;

	Fail:
	Instrumentation::note_production_fail(pr);
	@<Log the failure of the production@>;

@ Once we have successfully matched the line, we need to compose the
intermediate results into a final result. If //inweb// has compiled a compositor
function for the nonterminal, we call it.

If there's no compositor then the integer result is the production's number,
and the pointer result is null.

This is the range of fail nonterminal values -- |FAIL_NONTERMINAL| to one
less than |FAIL_NONTERMINAL_TO|:

@d FAIL_NONTERMINAL -100000
@d FAIL_NONTERMINAL_TO FAIL_NONTERMINAL+1000

@<Compose and store the result@> =
	if (nt->compositor_fn) {
		intermediates[0] = pr->match_number;
		int f = (*(nt->compositor_fn))(&Q, &QP,
			intermediates, intermediate_ps, nt->range_result, W);
		if (f == FALSE) goto Fail;
		if ((f >= FAIL_NONTERMINAL) && (f < FAIL_NONTERMINAL_TO)) {
			fail_nonterminal_quantum = f - FAIL_NONTERMINAL;
			@<The nonterminal has failed to parse@>;
		}
		if (nt->multiplicitous) @<Handle multiplicitous nonterminals directly@>;
	} else {
		Q = pr->match_number; QP = NULL;
	}

@ Multiplicitous NTs exist only in //core//, and differ from other regular NTs
because they accumulate their results from successful productions but do not
stop parsing on a successful match.

@<Handle multiplicitous nonterminals directly@> =
	#ifdef CORE_MODULE
	added_to_result = QP;
	acc_result = (void *) SyntaxTree::add_reading((parse_node *) acc_result, QP, W);
	#endif
	goto Fail;

@<Log the success of the production@> =
	if (ptraci) {
		@<Log the production match number@>;
		LOG("succeeded (%s): ", (slow_scan_needed)?"slowly":"quickly");
		LOG("result: %d\n", Q); LOG_OUTDENT;
	}

@<Log the failure of the production@> =
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

@h Bottom level.
Okay: so now we have exhausted all the optimisations avoiding the need to
parse our text against the production, so we are forced to do some work.
The strategy is:
(*) first, a fast scan checking the easy things;
(*) then a slow scan checking the rest;
(*) then making sure brackets match, if there were any.

For example, if the production is
= (text as Preform)
	adjust the <achingly-slow> to the <exhaustive> at once
=
then the fast scan verifies the presence of "adjust the" and "at once";
the slow scan next looks for all occurrences of "to the", the single strut
for this production; and only then does it test the two slow nonterminals
on the intervening words, if there are any.

@<Actually parse the given production, going to Fail if we can't@> =
	@<Try a fast scan through the production@>;
	if (slow_scan_needed) @<Try a slow scan through the production@>;

	if ((parsed_open_pos >= 0) && (parsed_close_pos >= 0))
		if (Wordings::paired_brackets(
			Wordings::new(parsed_open_pos, parsed_close_pos)) == FALSE)
				goto Fail;

@ In the fast scan, we check that all fixed words with known positions
are in those positions.

@<Try a fast scan through the production@> =
	int wn = -1, tc = 0;
	for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt, tc++) {
		if (pt->opt.ptoken_is_fast) {
			int p = pt->opt.ptoken_position;
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
	if ((slow_scan_needed == FALSE) && (wn != Wordings::last_wn(W)))
		goto Fail; /* text goes on further */

@ The slow scan is more challenging. We want to loop through all possible
strut positions, where by "possible" we mean that
$$ s_i+\ell_i \leq s_{i+1}, \quad i = 0, 1, ..., s $$
and that for each $i$ the $i$-th strut matches the text beginning at $s_i$.

@<Try a slow scan through the production@> =
	int spos[MAX_STRUTS_PER_PRODUCTION]; /* word numbers for where we try the struts */
	int NS = pr->opt.no_struts;
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
		spos[0] = Preform::next_strut_posn_after(W,
			pr->opt.struts[0], pr->opt.strut_lengths[0], Wordings::first_wn(W));
		if (spos[0] == -1) goto Fail;
	} else if (NS > 1) {
		int s, from = Wordings::first_wn(W);
		for (s=0; s<NS; s++) {
			spos[s] = Preform::next_strut_posn_after(W,
				pr->opt.struts[s], pr->opt.strut_lengths[s], from);
			if (spos[s] == -1) goto Fail;
			from = spos[s] + pr->opt.strut_lengths[s] + 1;
		}
	}

@ In the general case, we move the final strut forward if we can; if we can't,
we move the penultimate one, then move the final one to the first subsequent
position valid for it; and so on. Ultimately this results in the first strut
being unable to move forwards, at which point, we've lost.

@<Move on to the next strut position@> =
	if (NS == 0) goto Fail;
	else if (NS == 1) {
		spos[0] = Preform::next_strut_posn_after(W,
			pr->opt.struts[0], pr->opt.strut_lengths[0], spos[0]+1);
		if (spos[0] == -1) goto Fail;
	} else if (NS > 1) {
		int s;
		for (s=NS-1; s>=0; s--) {
			int n = Preform::next_strut_posn_after(W,
				pr->opt.struts[s], pr->opt.strut_lengths[s], spos[s]+1);
			if (n != -1) { spos[s] = n; break; }
		}
		if (s == -1) goto Fail;
		int from = spos[s] + 1; s++;
		for (; s<NS; s++) {
			spos[s] = Preform::next_strut_posn_after(W,
				pr->opt.struts[s], pr->opt.strut_lengths[s], from);
			if (spos[s] == -1) goto Fail;
			from = spos[s] + pr->opt.strut_lengths[s] + 1;
		}
	}

@ We can now forget about struts, thankfully, and check the remaining unchecked
ptokens.

@<Try a slow scan with the current strut positions@> =
	int wn = Wordings::first_wn(W), tc;
	ptoken *pt, *nextpt;
	if (backtrack_token) {
		pt = backtrack_token; nextpt = backtrack_token->next_pt;
		tc = backtrack_tc; wn = backtrack_to;
		goto Reenter;
	}
	for (pt = pr->first_pt, nextpt = (pt)?(pt->next_pt):NULL, tc = 0;
		pt;
		pt = nextpt, nextpt = (pt)?(pt->next_pt):NULL, tc++) {
		Reenter: ;
		int known_pos = checked[tc];
		if (known_pos >= 0) {
			if (wn > known_pos)
				goto Fail; /* a theoretical possibility if strut lookahead overreaches */
			wn = known_pos+1;
		} else {
			if (pt->range_starts >= 0)
				nt->range_result[pt->range_starts] = Wordings::one_word(wn);
			@<Match a ptoken@>;
			if (pt->range_ends >= 0)
				nt->range_result[pt->range_ends] =
					Wordings::up_to(nt->range_result[pt->range_ends], wn-1);
		}
	}
	if (wn != Wordings::last_wn(W)+1) goto FailThisStrutPosition;

@<Match a ptoken@> =
	switch (pt->ptoken_category) {
		case FIXED_WORD_PTC: @<Match a fixed word ptoken@>; break;
		case SINGLE_WILDCARD_PTC: @<Match a single wildcard ptoken@>; break;
		case MULTIPLE_WILDCARD_PTC: @<Match a multiple wildcard ptoken@>; break;
		case POSSIBLY_EMPTY_WILDCARD_PTC: @<Match a possibly empty wildcard ptoken@>; break;
		case NONTERMINAL_PTC: @<Match a nonterminal ptoken@>; break;
	}

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
we rely on the recursive call to //Preform::parse_nt_against_word_range// returning a
quick no.

@<Match a nonterminal ptoken@> =
	if ((wn > Wordings::last_wn(W)) && (pt->nt_pt->opt.nt_extremes.min_words > 0))
		goto FailThisStrutPosition;
	int wt;
	if (pt->nt_pt->voracious) wt = Wordings::last_wn(W);
	else if ((pt->nt_pt->opt.nt_extremes.min_words > 0) &&
		(pt->nt_pt->opt.nt_extremes.min_words == pt->nt_pt->opt.nt_extremes.max_words))
		wt = wn + pt->nt_pt->opt.nt_extremes.min_words - 1;
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
	if (pt->nt_pt->opt.nt_extremes.max_words > 0) wn = wt+1;

@ How much text from the input should this ptoken match? We feed it as much
as possible, and to calculate that, we must either be at the end of the run,
or else know exactly where the next ptoken starts: because its position is
known, or because it's a strut.

This is why two elastic nonterminals in a row won't parse correctly:
= (text as Preform)
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
		int p = lookahead->opt.ptoken_position;
		if (p > 0) wt = Wordings::first_wn(W)+p-2;
		else if (p < 0) wt = Wordings::last_wn(W)+p;
		else if (lookahead->opt.strut_number >= 0) wt = spos[lookahead->opt.strut_number]-1;
		else if ((lookahead->nt_pt)
			&& (pt->negated_ptoken == FALSE)
			&& (Optimiser::ptoken_width(pt) == PTOKEN_ELASTIC)) {
			wt = -1;
		 	nonterminal *target = lookahead->nt_pt;
		 	int save_preform_lookahead_mode = preform_lookahead_mode;
		 	preform_lookahead_mode = TRUE;
			for (int j = wn+1; j <= Wordings::last_wn(W); j++) {
				if (Preform::parse_nt_against_word_range(target,
					Wordings::new(j, Wordings::last_wn(W)), NULL, NULL)) {
					if ((pt->nt_pt == NULL) ||
						(Preform::parse_nt_against_word_range(pt->nt_pt,
							Wordings::new(wn, j-1), NULL, NULL))) {
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
= (text as Preform)
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
		for (pt = start; pt; pt = pt->next_pt) {
			if (pt->ptoken_category == FIXED_WORD_PTC) {
				if (Preform::parse_fixed_word_ptoken(pos, pt)) pos++;
				else break;
			} else {
				int q = Preform::parse_nt_against_word_range(pt->nt_pt,
					Wordings::new(pos, pos+pt->nt_pt->opt.nt_extremes.max_words-1),
					NULL, NULL);
				if (pt->negated_ptoken) q = q?FALSE:TRUE;
				if (q) pos += pt->nt_pt->opt.nt_extremes.max_words;
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
