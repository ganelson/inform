[Instrumentation::] Instrumentation.

To provide debugging and tuning data on the Preform parser's performance.

@h What data we collect.
This ought to be a privacy policy under GDPR, somehow. If so, our justification
for logging usage data would be this:
(a) the Preform parser does something very complicated and has to be tuned just
right to be efficient, so debugging logs are helpful;
(b) but it runs millions of times in each Inform compilation, in a wide variety
of ways, and any kind of complete log would be both too large and too complex
to take in. We want to be selective, and to be able to summarise.

So, in instrumentation mode, we gather the following data. For nonterminals,
we record the number of hits and misses. If a nonterminal is "watched", we
log its every parse.

=
typedef struct nonterminal_instrumentation_data {
	int watched; /* watch goings-on to the debugging log */
	int nonterminal_tries;
	int nonterminal_matches;
} nonterminal_instrumentation_data;

@ =
void Instrumentation::initialise_nonterminal_data(nonterminal_instrumentation_data *ins) {
	ins->watched = FALSE;
	ins->nonterminal_tries = 0; ins->nonterminal_matches = 0;
}

void Instrumentation::watch(nonterminal *nt, int state) {
	nt->ins.watched = state;
}

@ These are called after each hit or miss.

=
void Instrumentation::note_nonterminal_match(nonterminal *nt, wording W) {
	nt->ins.nonterminal_tries++;
	nt->ins.nonterminal_matches++;
}

void Instrumentation::note_nonterminal_fail(nonterminal *nt) {
	nt->ins.nonterminal_tries++;
}

@ We count the number of hits and misses on each production, and also store
some sample text matching it. (In fact, we store the longest text which ever
matches it.)

=
typedef struct production_instrumentation_data {
	int production_tries;
	int production_matches;
	struct wording sample_text;
} production_instrumentation_data;

@ =
void Instrumentation::initialise_production_data(production_instrumentation_data *ins) {
	ins->production_tries = 0; ins->production_matches = 0;
	ins->sample_text = EMPTY_WORDING;
}

@ These are called after each hit or miss.

=
void Instrumentation::note_production_match(production *pr, wording W) {
	pr->ins.production_tries++;
	pr->ins.production_matches++;
	if (Wordings::length(pr->ins.sample_text) < Wordings::length(W))
		pr->ins.sample_text = W;
}

void Instrumentation::note_production_fail(production *pr) {
	pr->ins.production_tries++;
}

@ At present, we collect no data on individual ptokens.

=
typedef struct ptoken_instrumentation_data {
	int to_keep_this_from_being_empty_which_is_nonstandard_C;
} ptoken_instrumentation_data;

void Instrumentation::initialise_ptoken_data(ptoken_instrumentation_data *ins) {
	ins->to_keep_this_from_being_empty_which_is_nonstandard_C = 0;
}

@h Logging.
Descending the wheels within wheels of the Preform data structures, then:

=
void Instrumentation::log(void) {
	int detailed = FALSE;
	nonterminal *nt;
	LOOP_OVER(nt, nonterminal) {
		Instrumentation::log_nt(nt, detailed);
		LOG("\n");
	}
}

void Instrumentation::log_nt(nonterminal *nt, int detailed) {
	LOG("%V ", nt->nonterminal_id);
	if (nt->marked_internal) LOG("internal ");
	if (nt->ins.nonterminal_tries > 0)
		LOG("hits %d/%d ", nt->ins.nonterminal_matches, nt->ins.nonterminal_tries);
	LOG("nti "); Instrumentation::log_bit(NTI::nt_incidence_bit(nt));
	LOG(" constraint "); Instrumentation::log_ntic(&(nt->opt.nt_ntic));
	LOG(" extremes ");
	Instrumentation::log_extremes(&(nt->opt.nt_extremes));
	LOG("\n");
	LOG_INDENT;
	for (production_list *pl = nt->first_pl; pl;
		pl = pl->next_pl)
		Instrumentation::log_production_list(pl, detailed);
	LOG_OUTDENT;
}

@ =
void Instrumentation::log_ntic(nti_constraint *ntic) {
	int c = 0;
	if (ntic->DW_req) { if (c++ > 0) LOG(" & "); LOG("DW = "); Instrumentation::log_bitmap(ntic->DW_req); }
	if (ntic->DS_req) { if (c++ > 0) LOG(" & "); LOG("DS = "); Instrumentation::log_bitmap(ntic->DS_req); }
	if (ntic->CW_req) { if (c++ > 0) LOG(" & "); LOG("CW = "); Instrumentation::log_bitmap(ntic->CW_req); }
	if (ntic->CS_req) { if (c++ > 0) LOG(" & "); LOG("CS = "); Instrumentation::log_bitmap(ntic->CS_req); }
	if (ntic->FW_req) { if (c++ > 0) LOG(" & "); LOG("FW = "); Instrumentation::log_bitmap(ntic->FW_req); }
	if (ntic->FS_req) { if (c++ > 0) LOG(" & "); LOG("FS = "); Instrumentation::log_bitmap(ntic->FS_req); }
	if (c == 0) LOG("(none)");
}

void Instrumentation::log_bitmap(int bm) {
	LOG("{");
	int c = 0;
	for (int i=0; i<32; i++) {
		int b = 1 << i;
		if (bm & b) {
			if (c++ > 0) LOG(", ");
			Instrumentation::log_bit(b);
		}
	}
	LOG("}");
}

void Instrumentation::log_bit(int b) {
	for (int i=0; i<32; i++) if (b == (1 << i)) {
		if (i < RESERVED_NT_BITS) LOG("r");
		LOG("%d", i);
	}
}

void Instrumentation::log_extremes(length_extremes *E) {
	LOG("[%d, ", E->min_words);
	if (E->max_words == INFINITE_WORD_COUNT) LOG("infinity)");
	else LOG("%d]", E->max_words);
}

@ =
void Instrumentation::log_production_list(production_list *pl, int detailed) {
	LOG("%J:\n", pl->definition_language);
	LOG_INDENT;
	for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
		Instrumentation::log_production(pr, detailed);
		LOG("\n  ");
		if (pr->ins.production_tries > 0)
			LOG("(hits %d/%d) ", pr->ins.production_matches, pr->ins.production_tries);
		if (Wordings::nonempty(pr->ins.sample_text)) {
			if (Wordings::length(pr->ins.sample_text) > 8) LOG("(matched long text) ");
			else LOG("(matched: '%W') ", pr->ins.sample_text);
		}
		LOG("constraint ");
		Instrumentation::log_ntic(&(pr->opt.pr_ntic));
		LOG(" extremes ");
		Instrumentation::log_extremes(&(pr->opt.pr_extremes));
		LOG("\n");
	}
	LOG_OUTDENT;
}

@ =
void Instrumentation::log_production(production *pr, int detailed) {
	if (pr->first_pt == NULL) LOG("<empty-production>");
	for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt) {
		Instrumentation::log_ptoken(pt, detailed);
		LOG(" ");
	}
}

@ =
void Instrumentation::log_ptoken(ptoken *pt, int detailed) {
	if ((detailed) && (pt->opt.ptoken_position != 0))
		LOG("(@%d)", pt->opt.ptoken_position);
	if ((detailed) && (pt->opt.strut_number >= 0))
		LOG("(S%d)", pt->opt.strut_number);
	if (pt->disallow_unexpected_upper) LOG("_");
	if (pt->negated_ptoken) LOG("^");
	if (pt->range_starts >= 0) {
		LOG("{"); if (detailed) LOG("%d:", pt->range_starts);
	}
	for (ptoken *alt = pt; alt; alt = alt->alternative_ptoken) {
		if (alt->nt_pt) {
			LOG("%V", alt->nt_pt->nonterminal_id);
			if (detailed) LOG("=%d", alt->result_index);
		} else {
			LOG("%V", alt->ve_pt);
		}
		if (alt->alternative_ptoken) LOG("/");
	}
	if (pt->range_ends >= 0) {
		if (detailed) LOG(":%d", pt->range_ends); LOG("}");
	}
}

@ A less detailed form used in linguistic problem messages:

=
void Instrumentation::write_ptoken(OUTPUT_STREAM, ptoken *pt) {
	if (pt->disallow_unexpected_upper) WRITE("_");
	if (pt->negated_ptoken) WRITE("^");
	if (pt->range_starts >= 0) WRITE("{");
	for (ptoken *alt = pt; alt; alt = alt->alternative_ptoken) {
		if (alt->nt_pt) {
			WRITE("%V", alt->nt_pt->nonterminal_id);
		} else {
			WRITE("%V", alt->ve_pt);
		}
		if (alt->alternative_ptoken) WRITE("/");
	}
	if (pt->range_ends >= 0) WRITE("}");
}
