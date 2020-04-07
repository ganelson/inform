[Parser::SP::MeaningLists::] Meaning Lists.

To build meaning lists, which despite the name are really tree
structures, showing possible interpretations of a sequence of words.

@h Definitions.

@ Meaning lists are an intermediate construction within the S-parser,
used to hold the possible meanings of complex excerpts of text. The S-parser
completes its work by turning any meaning list for a successfully parsed
piece of text into a much more compact |specification| structure,
perhaps with a proposition in predicate calculus attached. This is both
smaller and much less ambiguous in meaning. It would remove a layer of
code in Inform, and also one delicate interface between layers, if the
S-parser could parse directly to specifications; and this is what
the earliest builds did, in 2003 and 2004, but the result was that
|specification| became a very complex structure, trying to perform
two different tasks at once -- being a sort of checklist of possibilities
and then being a definite answer. Separating these two roles and inventing
meaning lists was a very disruptive decision, but eventually resulted in cleaner
and simpler code.

@ We have already seen meaning lists used to store lists of possible
excerpt meanings attached to given words, but that's not their main
function, and despite the name they are not necessarily simple lists. They
are a sort of two-dimensional tree structure where every node P represents
one possible meaning of a given excerpt of the original text. Because in
general the meaning will be complicated, and not as simple as a single
noun, P will also have children which are nodes representing meanings of
subexcerpts.

A two-dimensional tree is hard to visualise, but in practice they are easy
enough to read: they are basically standard parse-trees except that at
certain points they fork off into different possibilities. For instance, if
we try to parse the example phrase at the beginning of this chapter:

>> if Mr Fitzwilliam Darcy was carrying at least three things which are in the box, increase the score by 7;

then the S-parser initially generates the following meaning list:
= (text)
	CMD_ML / "if mr fitzwilliam darcy was carrying at least ..."
	    PHRASE_ML
	        [1/2] (score 1) {# at # = VOID_PHRASE_MC} / "if mr fitzwilliam ..."
	            UNPARSED_ML / "if mr fitzwilliam darcy was carrying"
	            UNPARSED_ML / "least three things which are in the box..."
	        [2/2] (score 1) {if # , # = VOID_PHRASE_MC} / "if mr fitzwilliam darcy..."
	            UNPARSED_ML / "mr fitzwilliam darcy was carrying at..."
	            UNPARSED_ML / "increase the score by 7"
=
The notation |[1/2]| means "possibility 1 of 2". This structure shows that
the S-parser is certain that we have a command phrase, but that on textual
grounds alone it could be one of two possibilities. In fact, |[2/2]| is the
valid one, as will become clear when it returns to parse the arguments currently
left as |UNPARSED_ML| nodes.

@ When the S-parser gets to the condition (argument 1 of possibility |[2/2]| above),
a more elaborate meaning list results, but which is unambiguous:
= (text)
	COND_ML / "mr fitzwilliam darcy was carrying at least ... in the box"
	    SV_ML / "mr fitzwilliam darcy was carrying at least ... in the box"
	        NP_ML / "mr fitzwilliam darcy"
	            VAL_ML / "mr fitzwilliam darcy"
	                DC_ML / "mr fitzwilliam darcy"
	                    DC_NOUN_ML / "mr fitzwilliam darcy"
	                        {mr fitzwilliam darcy = NAMETAG_MC}
	        VP_ML
	            VERB_ML => VU: was WAS_TENSE -> is
	                PREP_ML => PU: carrying -> carries
	            NP_ML / "at least three things which are in the box"
	                VAL_ML / "at least three things which are in the box"
	                    DC_ML / "at least three things which are in the box"
	                        SN_ML / "at least three things which are in the box"
	                            DC_ML / "at least three things"
	                                DC_NOUN_ML / "things"
	                                    {things = NAMETAG_MC}
	                                DETERMINER_ML => Card>=3 / "at least three"
	                            VP_ML
	                                VERB_ML => VU: are IS_TENSE -> is
	                                    PREP_ML => PU: in -> is-in
	                                DC_ML / "box"
	                                    DC_NOUN_ML / "box"
	                                        {mr bingham's box = NAMETAG_MC}
	                        DETERMINER_ML => Card>=3 / "at least three"
=
Note the three concrete noun phrases -- Mr Darcy, the box, and "things". It's
perhaps surprising that the determiner for "at least three" turns up twice
in the tree, but this is because the sub-excerpt

>> at least three things

is also validly subject to the determiner, so its subtree contains the
appropriate node.

As this shows, the result of parsing can be an extravagantly big meaning list.
When the S-parser finishes, it is translated into much more compact data:
a single specification representing a condition,
= (text)
	(A)'mr fitzwilliam ... box'/CONDITION_FMY/TEST_PROPOSITION_SPC<0 times: WAS_TENSE>
=
and with the proposition
= (text)
	[ Card>=3 x: K2'thing'(x) ^ is(O104'mr bingham's box',ContainerOf(x)) =>
	    is(O105'mr fitzwilliam darcy',CarrierOf(x)) ]
=
which can be paraphrased "at least three $x$ which are things and such that
their container is the box are also such that Mr Darcy is their carrier".

@ So, then, each meaning list node has children and siblings to place it into
a parse tree, but also forking links to alternative meanings. The actual
data at a node can be a value (the |type_spec|), an excerpt meaning, or
in some cases a pointer to some other structure. For instance, a
|VERB_ML| node has a pointer to the relevant |verb_usage| attached.

=
typedef struct meaning_list {
	int expiry_time; /* an integer measured in creation "cycles": see below */
	unsigned int production; /* a production code */
	int word_ref1, word_ref2; /* word pair as usual */
	struct excerpt_meaning *em; /* what this seems to mean... */
	struct specification *type_spec; /* evaluation used in compaction */
	struct general_pointer data_attached; /* certain productions have data attached */
	struct meaning_list *next_alternative; /* fork to alternative meaning */
	int score; /* a scoring system is used to choose most likely alternative */
	struct meaning_list *sibling; /* tree of meanings of subordinate clauses */
	struct meaning_list *child;
	MEMORY_MANAGEMENT
} meaning_list;

int no_permanent_MLs = 0, no_ephemeral_MLs = 0, GAP_movements = 0;

@ It will be noted that the meaning codes for excerpt meanings use the bottom
31 bits of a (presumably) 32-bit word to hold sets of contexts, but never have
bit 32 set. Meaning codes with bit 32 set are not considered as sets but
simply as magic values in themselves. When we parse a complicated piece of
text, the result is a tree in which the leaves are excerpts with simple
meanings, where the |production| field is a meaning code; but the higher
nodes have |production| values from the following set.

(There is no significance to these numbers except that they must all be
different, and must all have bit 32 set.)

@d ABSENT_SUBJECT_ML	0x80000010
@d ADVERB_ML			0x80000030
@d AL_ML				0x80000040
@d AP_ML				0x80000050
@d CALLED_ML            0x80000058
@d CARRIED_ML			0x80000060
@d CASE_ML				0x80000070
@d OTHERWISE_ML			0x80000080
@d CMD_ML				0x80000090
@d COND_AND_ML			0x800000a0
@d COND_NOT_ML			0x800000b0
@d COND_OR_ML			0x800000c0
@d COND_PAST_ML			0x800000d0
@d COND_PHRASE_ML		0x800000e0
@d COND_ML				0x800000f0
@d DC_ADJS_ML			0x80000100
@d DC_ADJSNOUN_ML		0x80000110
@d DC_NOUN_ML			0x80000130
@d DC_ML				0x80000140
@d DETERMINER_ML		0x80000180
@d INSTEAD_ML			0x80000190
@d LITERAL_ML			0x800001a0
@d LOCAL_ML				0x800001b0
@d MEMBER_OF_ML			0x800001c0
@d ADJ_NOT_ML			0x800001e0
@d NP_ML				0x800001f0
@d OPTION_ML			0x80000200
@d PHR_OPT_ML			0x80000210
@d PHRASE_ML			0x80000220
@d PREP_ML				0x80000240
@d SAY_ML				0x80000250
@d SN_ML				0x80000270
@d STV_ML				0x80000280
@d SV_ML				0x80000290
@d TE_CALLED_ML			0x800002a0
@d TE_EX_VAR_ML			0x800002b0
@d TE_GL_VAR_ML			0x800002c0
@d TE_NEW_VAR_ML		0x800002e0
@d TE_ML				0x800002f0
@d TE_VAR_ML			0x80000300
@d THERE_ML             0x80000310
@d TIME_ML				0x80000320
@d TR_CORR_ML			0x80000330
@d TR_ENTRY_ML			0x80000340
@d TR_IN_ROW_ML			0x80000350
@d TR_LISTED_IN_ML		0x80000360
@d TR_OF_IN_ML			0x80000370
@d TR_ML				0x80000380
@d TYPE_ML				0x80000390
@d UNPARSED_ML			0x800003a0
@d VAL_LIST_ENTRY_ML	0x800003b0
@d VAL_NOTHING_ML		0x800003c0
@d VAL_ML				0x800003d0
@d VAL_PAIR_ML			0x800003e0
@d VAL_PROP_OF_ML		0x800003f0
@d VAL_RESPONSE_ML		0x80000400
@d VALUE_PHRASE_ML		0x80000410
@d VERB_ML				0x80000420
@d VP_ML				0x80000430
@d COMPOSITED_ML		0x80000440

@d EQUATION_INLINE_ML	0x80000450
@d EQUATION_WHERE_ML	0x80000460
@d SAY_VERB_ML			0x80000470
@d SAY_MODAL_VERB_ML	0x80000480
@d SAY_ADJECTIVE_ML		0x80000490

@h Logging production values.

=
void Parser::SP::MeaningLists::log_production(unsigned int production) {
	if (production == 0) { LOG("<null-production>"); return; }
	if (production & 0x80000000) {
		switch (production) {
			case ABSENT_SUBJECT_ML: LOG("ABSENT_SUBJECT_ML"); break;
			case ADVERB_ML: LOG("ADVERB_ML"); break;
			case AL_ML: LOG("AL_ML"); break;
			case AP_ML: LOG("AP_ML"); break;
			case CALLED_ML: LOG("CALLED_ML"); break;
			case CARRIED_ML: LOG("CARRIED_ML"); break;
			case CASE_ML: LOG("CASE_ML"); break;
			case OTHERWISE_ML: LOG("OTHERWISE_ML"); break;
			case CMD_ML: LOG("CMD_ML"); break;
			case COMPOSITED_ML: LOG("COMPOSITED_ML"); break;
			case COND_AND_ML: LOG("COND_AND_ML"); break;
			case COND_NOT_ML: LOG("COND_NOT_ML"); break;
			case COND_OR_ML: LOG("COND_OR_ML"); break;
			case COND_PAST_ML: LOG("COND_PAST_ML"); break;
			case COND_PHRASE_ML: LOG("COND_PHRASE_ML"); break;
			case COND_ML: LOG("COND_ML"); break;
			case DC_ADJS_ML: LOG("DC_ADJS_ML"); break;
			case DC_ADJSNOUN_ML: LOG("DC_ADJSNOUN_ML"); break;
			case DC_NOUN_ML: LOG("DC_NOUN_ML"); break;
			case DC_ML: LOG("DC_ML"); break;
			case DETERMINER_ML: LOG("DETERMINER_ML"); break;
			case EQUATION_INLINE_ML: LOG("EQUATION_INLINE_ML"); break;
			case EQUATION_WHERE_ML: LOG("EQUATION_WHERE_ML"); break;
			case INSTEAD_ML: LOG("INSTEAD_ML"); break;
			case LITERAL_ML: LOG("LITERAL_ML"); break;
			case LOCAL_ML: LOG("LOCAL_ML"); break;
			case MEMBER_OF_ML: LOG("MEMBER_OF_ML"); break;
			case ADJ_NOT_ML: LOG("ADJ_NOT_ML"); break;
			case NP_ML: LOG("NP_ML"); break;
			case OPTION_ML: LOG("OPTION_ML"); break;
			case PHR_OPT_ML: LOG("PHR_OPT_ML"); break;
			case PHRASE_ML: LOG("PHRASE_ML"); break;
			case PREP_ML: LOG("PREP_ML"); break;
			case SAY_ML: LOG("SAY_ML"); break;
			case SAY_ADJECTIVE_ML: LOG("SAY_ADJECTIVE_ML"); break;
			case SAY_VERB_ML: LOG("SAY_VERB_ML"); break;
			case SAY_MODAL_VERB_ML: LOG("SAY_MODAL_VERB_ML"); break;
			case SN_ML: LOG("SN_ML"); break;
			case STV_ML: LOG("STV_ML"); break;
			case SV_ML: LOG("SV_ML"); break;
			case TE_CALLED_ML: LOG("TE_CALLED_ML"); break;
			case TE_EX_VAR_ML: LOG("TE_EX_VAR_ML"); break;
			case TE_GL_VAR_ML: LOG("TE_GL_VAR_ML"); break;
			case TE_NEW_VAR_ML: LOG("TE_NEW_VAR_ML"); break;
			case TE_ML: LOG("TE_ML"); break;
			case TE_VAR_ML: LOG("TE_VAR_ML"); break;
			case THERE_ML: LOG("THERE_ML"); break;
			case TIME_ML: LOG("TIME_ML"); break;
			case TR_CORR_ML: LOG("TR_CORR_ML"); break;
			case TR_ENTRY_ML: LOG("TR_ENTRY_ML"); break;
			case TR_IN_ROW_ML: LOG("TR_IN_ROW_ML"); break;
			case TR_LISTED_IN_ML: LOG("TR_LISTED_IN_ML"); break;
			case TR_OF_IN_ML: LOG("TR_OF_IN_ML"); break;
			case TR_ML: LOG("TR_ML"); break;
			case TYPE_ML: LOG("TYPE_ML"); break;
			case UNPARSED_ML: LOG("UNPARSED_ML"); break;
			case VAL_LIST_ENTRY_ML: LOG("VAL_LIST_ENTRY_ML"); break;
			case VAL_NOTHING_ML: LOG("VAL_NOTHING_ML"); break;
			case VAL_PAIR_ML: LOG("VAL_PAIR_ML"); break;
			case VAL_ML: LOG("VAL_ML"); break;
			case VAL_PROP_OF_ML: LOG("VAL_PROP_OF_ML"); break;
			case VAL_RESPONSE_ML: LOG("VAL_RESPONSE_ML"); break;
			case VALUE_PHRASE_ML: LOG("VALUE_PHRASE_ML"); break;
			case VERB_ML: LOG("VERB_ML"); break;
			case VP_ML: LOG("VP_ML"); break;
			default: LOG("<unknown-production-%08x>", production); break;
		}
	} else Semantics::Nouns::ExcerptMeanings::log_meaning_code(production);
}

@ Logging a meaning list is more than a matter of displaying an indented tree,
because of the ambiguities present. The log uses the notation |[1/3]| for
"possibility 1 of 3".

@d LOG_ML_SAFETY_LIMIT 100

=
void Parser::SP::MeaningLists::log(meaning_list *ml) {
	if (ml == NULL) { LOG("<null-meaning-list>\n"); return; }
	Parser::SP::MeaningLists::log_ml_recursively(ml, 0, 0, 1);
}

void Parser::SP::MeaningLists::log_ml_recursively(meaning_list *ml, int num, int of, int gen) {
	if (gen > LOG_ML_SAFETY_LIMIT) { LOG("*** Pruned: tree large or damaged ***\n"); return; }
	int w1, w2;
	@<Calculate num and of such that this is [num/of] if they aren't already supplied@>;

	if (ml == NULL) { LOG("NULL\n"); return; }
	if (of > 1) {
		LOG("[%d/%d] ", num, of);
		if (ml->score != 0) LOG("(score %d) ", ml->score);
	}
	if (ml->em) LOG("$M", ml->em);
	else Parser::SP::MeaningLists::log_production(ml->production);
	if (ml->type_spec) {
		LOG(" => ");
		if (ml->production == TIME_ML) LOG("$t", Specifications::get_condition_tense(ml->type_spec));
		else LOG("$S", ml->type_spec);
	}
	@<Describe attached data for a few special cases with pointers attached@>;
	Parser::SP::MeaningLists::get_text(ml, &w1, &w2);
	if (w1 >= 0) LOG(" / \"$W\"", w1, w2);
	LOG("\n");

	if (ml->child) {
		LOG_INDENT; Parser::SP::MeaningLists::log_ml_recursively(ml->child, 0, 0, gen+1); LOG_OUTDENT;
	}
	if (ml->next_alternative) Parser::SP::MeaningLists::log_ml_recursively(ml->next_alternative, num+1, of, gen+1);
	if (ml->sibling) Parser::SP::MeaningLists::log_ml_recursively(ml->sibling, 0, 0, gen+1);
}

@ When the first alternative is called, |Parser::SP::MeaningLists::log_ml_recursively| has arguments 0
and 0 for the possibility. The following code finds out the correct value for
|of|, setting this possibility to be |[1/of]|. When we later iterate through
other alternatives, we pass on correct values of |num| and |of|, so that this
code won't be used again on the same horizontal list of possibilities.

@<Calculate num and of such that this is [num/of] if they aren't already supplied@> =
	if (num == 0) {
		meaning_list *ml2;
		for (ml2 = ml, of = 0; ml2; ml2 = ml2->next_alternative, of++) ;
		num = 1;
	}

@ Most higher-up nodes in the list are described fully by production
number alone -- every |VAL_ML| is like every other. But a few have
data attached, a pointer to some other structure, to clarify them. Not
every |PREP_ML| is like every other; it depends what the preposition
usage is.

@<Describe attached data for a few special cases with pointers attached@> =
	switch (ml->production) {
		case DETERMINER_ML:
			LOG(" => ");
			Quantifiers::log(RETRIEVE_POINTER_quantifier(ml->data_attached), ml->score); break;
		case VERB_ML:
			LOG(" => ");
			Verbs::log(RETRIEVE_POINTER_verb_usage(ml->data_attached)); break;
		case PREP_ML:
			LOG(" => ");
			Prepositions::log(RETRIEVE_POINTER_preposition_usage(ml->data_attached)); break;
	}

@h Creation.
When we ask the memory manager to create a new structure, we increase
the amount of memory claimed from the operating system, little by little.
This memory will not be given back until Inform exits: structures, once
created, are permanent. Normally this is what we want -- to hold a phrase
definition, for instance, which needs to be available for the rest of the
run.

Meaning lists are the exception. In tests made in February 2009, compiling
"Bronze" generated around 189,000 |meaning_list| structures, but only
1 in 50 were needed in permanent storage -- to hold the lists of excerpt
meanings attached to vocabulary words, which together make up Inform's
equivalent of a symbols table. The other 49 in 50 |meaning_list| structures
were ephemeral -- an intermediate result of parsing text which could be thrown
away once acted on. So that is what the following new system will do.

Each |meaning_list| is marked with an expiry date when created --
most often the "current time", just as supermarket bread is tagged with a
sell-by date which is the same as the day of baking. The rarer permanent
MLs are marked instead with impossibly distant expiry dates, like Army
field rations. The "current time", for this purpose, has no connection
with the time of day. It begins at 0 and advances by 1 whenever Inform
completes some parsing-heavy task: working through an assertion sentence,
compiling a phrase, and so on. A meaning list structure whose expiry date
is before the current time is said to have "expired".

@d THE_INFINITE_FUTURE 2147483647

@ When we need a new meaning list, we first look for an expired one to
reuse -- only if that fails do we ask the memory manager to create
a new structure. A complete search of existing structures would produce
the best-possible memory economy, but would also be slow. For speed
reasons we therefore use the following pragmatic strategy:

(a) A new ephemeral ML reuses the first expired structure after the
last-created permanent one, but
(b) A new permanent ML reuses the expired structure in memory.

We do this by keeping three markers: the earliest ephemeral ML occurring
one or more places before some permanent ML, the "GAP";
the latest permanent one, the "LP"; and the start of the expired tail,
"TAIL", characterised by the fact that it and all subsequent MLs have
expired.

For instance, suppose the time is now 1021 and the list of MLs in memory
shows expiry dates thus:
= (text)
	PERMANENT -> 1020 -> PERMANENT -> PERMANENT -> 1021 -> 1020 -> 976
	             ^GAP                 ^LP                  ^TAIL
=
A new ephemeral ML reuses the TAIL position, the second 1020, and TAIL
moves forwards:
= (text)
	PERMANENT -> 1020 -> PERMANENT -> PERMANENT -> 1021 -> 1021 -> 976
	             ^GAP                 ^LP                          ^TAIL
=
Whereas a new permanent ML reuses the GAP position, filling in the gap,
and GAP becomes |NULL|:
= (text)
	PERMANENT -> PERMANENT -> PERMANENT -> PERMANENT -> 1021 -> 1021 -> 976
	                                       ^LP                          ^TAIL
=
Note that LP moves only forwards. GAP is |NULL| from time to time, but its
non-|NULL| values always move forwards, too. The sequence is always GAP
strictly behind LP strictly behind TAIL, when these are not |NULL|, and
no two ever coincide.

Perfect efficiency is achieved when GAP is |NULL|, as here. In
practice this doesn't always happen. But MLs do tend to concentrate early in
memory; on a long run they end up about 90\% contiguous, that is, if there
are $N$ permanent MLs then they tend to live in the first $1.1N$ positions.
That will be good enough for us, and the important point about the above
algorithm is that it allocates $M$ objects in $O(M)$ time, not $O(M^2)$,
which with $M\simeq 190,000$ would hurt.

=
meaning_list *LP_marker = NULL, *GAP_marker = NULL, *TAIL_marker = NULL;
meaning_list *earliest_ephemeral_ML_today = NULL;

int current_creation_time = 0, max_ML_creations_per_day = 0, no_ML_creations_today;

@ First, the allocation.

=
meaning_list *Parser::SP::MeaningLists::get_available_ml(int seeking_permanent_slot) {
	meaning_list *new;
	if ((seeking_permanent_slot) && (GAP_marker)) {
		new = GAP_marker;
		LOGIF(MEANING_LIST_ALLOCATION, "Time %d: Using GAP position ML%d with expiry time %d\n",
			current_creation_time, new->allocation_id, new->expiry_time);
		/* here TAIL does not change */
		@<Move the GAP marker forward to the next gap, if any@>;
	} else if (TAIL_marker) {
		new = TAIL_marker;
		LOGIF(MEANING_LIST_ALLOCATION, "Time %d: Using TAIL position ML%d with expiry time %d\n",
			current_creation_time, new->allocation_id, new->expiry_time);
		/* here any GAP is unaltered */
		TAIL_marker = NEXT_OBJECT(TAIL_marker, meaning_list);
		if (seeking_permanent_slot) LP_marker = new;
	} else {
		new = CREATE(meaning_list);
		LOGIF(MEANING_LIST_ALLOCATION, "Time %d: Using new position ML%d\n",
			current_creation_time, new->allocation_id);
		/* here any TAIL vanishes, but a GAP is unaltered */
		TAIL_marker = NULL;
		if (seeking_permanent_slot) LP_marker = new;
	}
	if (seeking_permanent_slot) new->expiry_time = THE_INFINITE_FUTURE;
	else {
		new->expiry_time = current_creation_time;
		if (earliest_ephemeral_ML_today == NULL) earliest_ephemeral_ML_today = new;
	}
	no_ML_creations_today++;
	LOGIF(MEANING_LIST_ALLOCATION, "Time %d: GAP = ML%d, LP = ML%d, TAIL = ML%d\n",
		current_creation_time,
		(GAP_marker)?(GAP_marker->allocation_id):0,
		(LP_marker)?(LP_marker->allocation_id):0,
		(TAIL_marker)?(TAIL_marker->allocation_id):0);
	return new;
}

@ Everything before the GAP is permanent, and the new item put there will also
be permanent. We must move forward over unexpired items. There are then three
possibilities: we run out (there are now no expired items in the list, so the
new GAP is |NULL|); or we are at the TAIL position (so everything is expired
from here on, and GAP must again be |NULL|); or we are at an expired item
before the TAIL, which is therefore a new valid GAP item.

@<Move the GAP marker forward to the next gap, if any@> =
	do {
		GAP_marker = NEXT_OBJECT(GAP_marker, meaning_list);
		GAP_movements++;
	} while ((GAP_marker) && (GAP_marker->expiry_time >= current_creation_time));
	if (GAP_marker == TAIL_marker) GAP_marker = NULL;

@ Second, moving time on to the next day. There is little prospect of
reaching |THE_INFINITE_FUTURE|, but just in case we do, we stop time
there; infinity is the day that never sees midnight.

=
void Parser::SP::MeaningLists::finish_this_session(void) {
	if (current_creation_time < THE_INFINITE_FUTURE) {
		if (Log::get_aspect(MEANING_LIST_ALLOCATION_DA)) {
			LOG("Time %d: %d items were created today ",
				current_creation_time, no_ML_creations_today);
			if (no_ML_creations_today > max_ML_creations_per_day) {
				LOG("- a new record!");
				max_ML_creations_per_day = no_ML_creations_today;
			}
			LOG("\n");
		}
		@<Adjust the markers at midnight@>;
		current_creation_time++;
		earliest_ephemeral_ML_today = NULL;
		no_ML_creations_today = 0;
	}
}

@ To continue our example, at one minute to midnight on day 1021 we had:
= (text)
	PERMANENT -> PERMANENT -> PERMANENT -> PERMANENT -> 1021 -> 1021 -> 976
	                                       ^LP                          ^TAIL
=
And at one minute past midnight on day 1022 we have:
= (text)
	PERMANENT -> PERMANENT -> PERMANENT -> PERMANENT -> 1021 -> 1021 -> 976
	                                       ^LP          ^TAIL
=
LP doesn't move, since there is no change to the permanent items. Since every
non-permanent item expired at midnight, the new TAIL always starts just after LP.

The tricky one is GAP. If it is non-|NULL| at midnight, it doesn't change,
since it is still an expired item with everything before it permanent. But if
it is |NULL|, we only know that any gaps in the permanent items are filled
with day-1021 creations, like this:
= (text)
	PERMANENT -> PERMANENT -> PERMANENT -> 1021 -> 1021 -> PERMANENT -> 1021 -> 976
=
Consider the first day-1021 creation in the list. If it doesn't exist
(i.e., there are no day-1021 items) there is still no GAP. Otherwise it
exists, and is either before, at or after the new TAIL position. If before
TAIL (or if there is no TAIL), it is the new GAP. If at or after TAIL then
there are no permanent items after it, and once again there is still no GAP.

@<Adjust the markers at midnight@> =
	TAIL_marker = NEXT_OBJECT(LP_marker, meaning_list);
	if (GAP_marker == NULL) {
		GAP_marker = earliest_ephemeral_ML_today;
		if ((TAIL_marker) && (GAP_marker) &&
			(GAP_marker->allocation_id >= TAIL_marker->allocation_id))
			GAP_marker = NULL;
	}

@ We can finally prove the running time of this algorithm over the entire
run. Suppose $M$ meaning lists are allocated during the run. The midnight
operation runs in $O(1)$ but occurs on each of the $D$ days; however, each
day's activity requires the creation of at least one meaning list, so
$D\leq M$ and midnight operations are worst $O(M)$. The allocation
operation contains just one loop, when GAP moves forwards. Now GAP always
advances until it becomes |NULL|, and since the list has length at most
$M$, this is $\leq M$ iterations in total across Inform's run -- {\it
except} that the midnight operation sometimes puts it back after it has
become |NULL|, forcing it to traverse the last few items again.

For each $t$, let $C(t)$ be the number of allocations made on day $t$.
We prove by induction that the number of extra GAP movements due to being
put back at the end of day $t$, which we call $X(t)$, satisfies $X(t)\leq
C(t)+C(t+1)$.

Suppose, at midnight on day $t$, GAP is put back into the new list. How
many extra steps forward will that cost us before it falls off again? The
answer is that it is put back at the earliest ephemeral day $t$ creation.
This is at most $C(t)$ steps from the TAIL, which it will never advance
past. However, the TAIL itself moves forwards during day $t+1$, by at most
$C(t+1)$ steps. So the worst case is that the extra steps incurred due to
day $t+1$ is actually $C(t)+C(t+1)$.

Therefore the total number of extra steps forward is
$$ X = \sum_{t=0}^{D-1} X(t) \leq \sum_{t=0}^{D-1} C(t)+C(t+1)
\leq 2\sum_{t=0}^{D-1} C(t) = 2M. $$
It takes at most $M$ regular steps forward, so, finally, the number of
iterations of the loop is bounded across the whole run by $3M$, and hence
our allocation algorithm runs in $O(M)$ time.

@ Testing with "Bronze" in February 2009 in fact produced just 2438 steps
where $M = 189165$, so in real-world usage it is very likely well under
$3M$. At the end of the run there were 5411 MLs in memory, of which 4166
were permanent. Only 1245 ephemeral MLs existed, instead of 184,999, saving
about 10.5MB of memory -- a saving of 30\% off the total memory bill.

Though it had been intended as a trade-off of speed for memory savings, it
in fact shaved about 15\% off Inform's total running time, because
|Parser::SP::MeaningLists::get_available_ml| acts as a fast cache for spare memory in rapid-fire
parsing.

@h Construction.
We can now forget how memory for MLs is found, and worry about how to
make them and what to use them for. We request them either temporarily or
permanently:

=
meaning_list *Parser::SP::MeaningLists::new(unsigned int code_number) {
	meaning_list *ml = Parser::SP::MeaningLists::get_available_ml(FALSE);
	@<Initialise the rest of the ML structure@>;
	no_ephemeral_MLs++;
	return ml;
}

meaning_list *Parser::SP::MeaningLists::new_permanent(unsigned int code_number) {
	meaning_list *ml = Parser::SP::MeaningLists::get_available_ml(TRUE);
	@<Initialise the rest of the ML structure@>;
	no_permanent_MLs++;
	return ml;
}

@ But in each case the result looks the same.

@<Initialise the rest of the ML structure@> =
	ml->em = NULL;
	ml->next_alternative = NULL;
	ml->sibling = NULL;
	ml->child = NULL;
	ml->type_spec = NULL;
	ml->score = 0;
	ml->production = code_number;
	Parser::SP::MeaningLists::set_text(ml, -1, -1);
	ml->data_attached = NULL_GENERAL_POINTER;

@ The following constructor routines fill out the fields in useful ways.
Here's one if a word range is to be attached:

=
meaning_list *Parser::SP::MeaningLists::new_with_words(unsigned int code_number, int w1, int w2) {
	meaning_list *ml = Parser::SP::MeaningLists::new(code_number);
	Parser::SP::MeaningLists::set_text(ml, w1, w2);
	return ml;
}

@ And here is one deriving from a nametag:

=
meaning_list *Parser::SP::MeaningLists::from_nametag(nametag *nt) {
	meaning_list *ml = Parser::SP::MeaningLists::new(NAMETAG_MC);
	ml->em = Nametags::get_principal_meaning(nt);
	ml->score = 1;
	return ml;
}

@ |TYPE_ML| nodes hold specifications. As we will see,
these can represent both actual and generic values (for instance, "7" and
"a number"), but the ones attached to |TYPE_ML| nodes are always
generic. First, a version to create such a node from the type ID number:

=
meaning_list *Parser::SP::MeaningLists::type_from_ID(int ID_number) {
	meaning_list *ml = Parser::SP::MeaningLists::new(TYPE_ML);
	ml->type_spec = Specifications::new_generic_from_type_ID(ID_number);
	return ml;
}

@ Second, from a given kind:

=
meaning_list *Parser::SP::MeaningLists::type_from_kind(kind *K) {
	meaning_list *ml = Parser::SP::MeaningLists::new(TYPE_ML);
	ml->type_spec = Specifications::Values::new_generic_CONSTANT(K);
	return ml;
}

@ |DETERMINER_ML| nodes record a quantifier (the underlying meaning
of a determiner, that is) together with its numeric parameter, in case
relevant.

=
meaning_list *Parser::SP::MeaningLists::determiner(quantifier *quant, int parameter, int w1, int w2) {
	meaning_list *ml = Parser::SP::MeaningLists::new_with_words(DETERMINER_ML, w1, w2);
	ml->data_attached = STORE_POINTER_quantifier(quant);
	ml->score = parameter;
	return ml;
}

@ |TIME_ML| nodes record a time period, a structure which despite
its name can also simply be a tense indication. Slightly bogusly, the time
period is attached by being part of a condition SP, though no specific
condition is meant -- it's just that conditions always have time periods
attached to them, so this is the natural way to store them.

=
meaning_list *Parser::SP::MeaningLists::time(time_period tp) {
	meaning_list *ml = Parser::SP::MeaningLists::new(TIME_ML);
	ml->type_spec = Specifications::Conditions::new(TimePeriods::store(tp));
	return ml;
}

@ |VERB_ML| nodes record the usage of a verb.

=
meaning_list *Parser::SP::MeaningLists::verb(verb_usage *vu) {
	meaning_list *ml = Parser::SP::MeaningLists::new(VERB_ML);
	Parser::SP::MeaningLists::attach_data(ml, STORE_POINTER_verb_usage(vu));
	return ml;
}

@ |PREP_ML| nodes record the usage of SParSSa preposition.

=
meaning_list *Parser::SP::MeaningLists::preposition(preposition_usage *pu) {
	meaning_list *ml = Parser::SP::MeaningLists::new(PREP_ML);
	Parser::SP::MeaningLists::attach_data(ml, STORE_POINTER_preposition_usage(pu));
	return ml;
}

@ An |OPTION_ML| node holds a phrase option name.

=
meaning_list *Parser::SP::MeaningLists::option(int opt_num) {
	meaning_list *ml = Parser::SP::MeaningLists::new(OPTION_ML);
	ml->type_spec = Specifications::Conditions::new_TEST_PHRASE_OPTION(opt_num);
	return ml;
}

@ |SAY_VERB_ML| nodes hold references to verbs by their first person plural.

=
meaning_list *Parser::SP::MeaningLists::say_verb(verb_conjugation *vc, int neg) {
	meaning_list *ml = Parser::SP::MeaningLists::new(SAY_VERB_ML);
	Parser::SP::MeaningLists::attach_data(ml, STORE_POINTER_verb_conjugation(vc));
	Parser::SP::MeaningLists::set_score(ml, neg);
	return ml;
}

@ |SAY_MODAL_VERB_ML| annotate those with modals like "might".

=
meaning_list *Parser::SP::MeaningLists::say_modal_verb(verb_conjugation *vc) {
	meaning_list *ml = Parser::SP::MeaningLists::new(SAY_MODAL_VERB_ML);
	Parser::SP::MeaningLists::attach_data(ml, STORE_POINTER_verb_conjugation(vc));
	return ml;
}

@ |SAY_ADJECTIVE_ML| nodes hold references to adjectives by their masculine
singulars.

=
meaning_list *Parser::SP::MeaningLists::say_adjective(adjectival_phrase *aph) {
	meaning_list *ml = Parser::SP::MeaningLists::new(SAY_ADJECTIVE_ML);
	Parser::SP::MeaningLists::attach_data(ml, STORE_POINTER_adjectival_phrase(aph));
	return ml;
}

@h Copying MLs.
Note that this copies the contents of the ML, but not the expiry date, or
indeed the memory manager's private fields.

=
void Parser::SP::MeaningLists::copy(meaning_list *ml_to, meaning_list *ml_from) {
	ml_to->em = ml_from->em;
	ml_to->next_alternative = ml_from->next_alternative;
	ml_to->sibling = ml_from->sibling;
	ml_to->child = ml_from->child;
	ml_to->type_spec = ml_from->type_spec;
	ml_to->score = ml_from->score;
	ml_to->production = ml_from->production;
	ml_to->word_ref1 = ml_from->word_ref1;
	ml_to->word_ref2 = ml_from->word_ref2;
	ml_to->data_attached = ml_from->data_attached;
}

@h Access routines.

=
unsigned int Parser::SP::MeaningLists::production(meaning_list *ml) {
	return ml->production;
}
void Parser::SP::MeaningLists::set_production(meaning_list *ml, unsigned int pr) {
	ml->production = pr;
}

@ Navigating the tree structure through subclauses:

=
meaning_list *Parser::SP::MeaningLists::right(meaning_list *ml) {
	return ml->sibling;
}
void Parser::SP::MeaningLists::set_right(meaning_list *ml, meaning_list *ml2) {
	ml->sibling = ml2;
}
meaning_list *Parser::SP::MeaningLists::down(meaning_list *ml) {
	return ml->child;
}
void Parser::SP::MeaningLists::set_down(meaning_list *ml, meaning_list *ml2) {
	ml->child = ml2;
}

@ Alternatives, where the meaning list forks:

=
meaning_list *Parser::SP::MeaningLists::sideways(meaning_list *ml) {
	return ml->next_alternative;
}
int Parser::SP::MeaningLists::match_score(meaning_list *ml) {
	return ml->score;
}
void Parser::SP::MeaningLists::set_score(meaning_list *ml, int s) {
	ml->score = s;
}

@ The attached text. Most Inform structures don't use access routines like this
for word ranges, but this one is an exception because at one time it was packed
into a single |int| to save memory; that proved impossible given the conflicting
needs of very high $w_1$ values on long source texts, and very high $w_2-w_1$
differences for extensive constant lists.

=
void Parser::SP::MeaningLists::set_text(meaning_list *ml, int w1, int w2) {
	if (w1<0) { ml->word_ref1 = -1; ml->word_ref2 = -1; }
	else { ml->word_ref1 = w1; ml->word_ref2 = w2; }
}

void Parser::SP::MeaningLists::get_text(meaning_list *ml, int *w1, int *w2) {
	*w1 = ml->word_ref1; *w2 = ml->word_ref2;
}

@ An excerpt meaning:

=
excerpt_meaning *Parser::SP::MeaningLists::meaning(meaning_list *ml) {
	return ml->em;
}
void Parser::SP::MeaningLists::set_meaning(meaning_list *ml, excerpt_meaning *em) {
	ml->em = em;
}

@ Or maybe a specification:

=
specification *Parser::SP::MeaningLists::get_attached_spec(meaning_list *ml) {
	return ml->type_spec;
}
void Parser::SP::MeaningLists::attach_spec(meaning_list *ml, specification *spec) {
	ml->type_spec = spec;
}

@ And perhaps also an attached pointer to some other structure of
unspecified type.

=
general_pointer Parser::SP::MeaningLists::get_attached_data(meaning_list *ml) {
	return ml->data_attached;
}
void Parser::SP::MeaningLists::attach_data(meaning_list *ml, general_pointer data) {
	ml->data_attached = data;
}
