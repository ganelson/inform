[Occurrence::] Adverb Phrases of Occurrence.

To parse representations of periods of time or of historical repetition.

@ Natural language can talk about the extension of a situation into the past
in a number of ways, but we will model just two of these:
(a) Something having been the case on a number of previous occasions, or
"times", as in: "for the third time";
(b) Something having been the case on a number of previous turns, a unit
really only meaningful for turn-based simulations, as in: "for three turns".

@d TIMES_UNIT 1 /* used for "for the third time" */
@d TURNS_UNIT 2 /* used for "for three turns" */

@ And the following the constants are used to record how to measure the
threshold value -- "for more than three turns" would be |GT_REPM|, and so
on. The default, |NO_REPM|, means that nothing is specified by way of
comparison -- "four times" -- and the meaning of that may depend on
context; Inform treats a |NO_REPM| occurrence quite carefully -- see
//runtime: Chronology//.

@e EQ_REPM from 1
@e LT_REPM
@e LE_REPM
@e GT_REPM
@e GE_REPM
@e NO_REPM

@ The following structure is used for the result of parsing some text for
a time period. For example, "X is 7 for the second time" would have as
its used wording "for the second time", and unused wording "X is 7".

=
typedef struct time_period {
	int units; /* one of the two above */
	int length; /* the duration or else the lower limit of an interval */
	int until; /* |-1| or else the upper limit of an interval */
	int test_operator; /* one of the |*_REPM| constants */
	struct wording used_wording;
	struct wording unused_wording;
	CLASS_DEFINITION
} time_period;

@ Logging:

=
void Occurrence::log(OUTPUT_STREAM, void *vtp) {
	time_period *tp = (time_period *) vtp;
	WRITE("<");
	switch (tp->test_operator) {
		case EQ_REPM: WRITE("=="); break;
		case LT_REPM: WRITE("<"); break;
		case LE_REPM: WRITE("<="); break;
		case GT_REPM: WRITE(">"); break;
		case GE_REPM: WRITE(">="); break;
	}
	if (tp->until >= 0) WRITE("%d", tp->until); else WRITE("%d", tp->length);
	switch(tp->units) {
		case TURNS_UNIT: WRITE(" turns"); break;
		case TIMES_UNIT: WRITE(" times"); break;
		default: WRITE(": <invalid-units>"); break;
	}
	WRITE(">");
}

@ Access:

=
int Occurrence::operator(time_period *tp) {
	if (tp == NULL) return NO_REPM;
	return tp->test_operator;
}

int Occurrence::units(time_period *tp) {
	if (tp == NULL) return TIMES_UNIT;
	return tp->units;
}

int Occurrence::length(time_period *tp) {
	if (tp == NULL) return -1;
	return tp->length;
}

int Occurrence::until(time_period *tp) {
	if (tp == NULL) return -1;
	return tp->until;
}

wording Occurrence::used_wording(time_period *tp) {
	if (tp == NULL) internal_error("no time period");
	return tp->used_wording;
}

wording Occurrence::unused_wording(time_period *tp) {
	if (tp == NULL) internal_error("no time period");
	return tp->unused_wording;
}

@ Sorting.
Sorting of time periods has to be by "specificity". A briefer time period
is in this sense more specific than a longer one, because it is more specific
about the time at which the behaviour occurs.

=
int Occurrence::compare_specificity(time_period *tp1, time_period *tp2) {
	if ((tp1 == NULL) && (tp2 == NULL)) return 0;

	if ((tp1) && (tp2 == NULL)) return 1;
	if ((tp2) && (tp1 == NULL)) return -1;

	int dc1 = Occurrence::sorting_count(tp1);
	int dc2 = Occurrence::sorting_count(tp2);

	if (dc1 > dc2) return -1;
	if (dc1 < dc2) return 1;

	return 0;
}

int Occurrence::sorting_count(time_period *tp) {
	int L = tp->length;
	if (L < 0) L = 0;
	if (tp->until >= 0) {
		return tp->until - L + 1;
	} else {
		switch (tp->test_operator) {
			case NO_REPM: return 1;
			case EQ_REPM: return 1;
			case LT_REPM: return L - 1;
			case LE_REPM: return L;
			case GT_REPM: return 1000000 - (L - 1);
			case GE_REPM: return 1000000 - L;
		}
	}
	return 0;
}

@ Historical references are textual indications that a condition compares
the present state with past states: for example, "for more than the third time".
Note that every HR contains one of the words below, so that if
<historical-reference-possible> fails on an excerpt then it
cannot contain any HR; this cuts down our parsing time considerably.

=
<historical-reference-possible> ::=
	*** once/twice/thrice/turn/turns/time/times

@ Otherwise the grammar is straightforward:

=
<historical-reference> ::=
	for <repetition-specification> |       ==> { R[1], - }
	<repetition-specification>             ==> { R[1], - }

<repetition-specification> ::=
	only/exactly <repetitions> |           ==> { EQ_REPM, - }
	at most <repetitions> |                ==> { LE_REPM, - }
	less/fewer than <repetitions> |        ==> { LT_REPM, - }
	at least <repetitions> |               ==> { GE_REPM, - }
	more than <repetitions> |              ==> { GT_REPM, - }
	under <repetitions> |                  ==> { LT_REPM, - }
	over <repetitions> |                   ==> { GT_REPM, - }
	<repetitions>                          ==> { NO_REPM, - }

<repetitions> ::=
	<iteration-repetitions> |              ==> { 0, -, <<from>> = R[1], <<unit>> = TIMES_UNIT }
	<turn-repetitions>                     ==> { 0, -, <<from>> = R[1], <<unit>> = TURNS_UNIT }

<iteration-repetitions> ::=
	once |                                 ==> { 1, - }
	twice |                                ==> { 2, - }
	thrice |                               ==> { 3, - }
	<reps> to <reps> time/times |          ==> { R[1], - , <<to>> = R[2] }
	<reps> time/times                      ==> { R[1], - }

<turn-repetitions> ::=
	<reps> to <reps> turn/turns |          ==> { R[1], - , <<to>> = R[2] }
	<reps> turn/turns                      ==> { R[1], - }

<reps> ::=
	<definite-article> <ordinal-number> |  ==> { R[2], - }
	<ordinal-number> |                     ==> { R[1], - }
	<cardinal-number>                      ==> { R[1], - }

@ And so, finally, here is code to parse using the above grammar:

=
time_period *Occurrence::parse(wording W) {
	if (<historical-reference-possible>(W)) {
		LOOP_THROUGH_WORDING(k, W) {
			<<to>> = -1;
			wording HW = Wordings::from(W, k);
			if (<historical-reference>(HW)) {
				time_period *tp = CREATE(time_period);
				tp->test_operator = <<r>>;
				tp->length = <<from>>;
				tp->until = <<to>>;
				tp->units = <<unit>>;
				tp->used_wording = HW;
				tp->unused_wording = Wordings::up_to(W, k-1);
				LOGIF(TIME_PERIODS, "Parsed time period: <%W> = $t\n", HW, tp);
				return tp;
			}
		}
	}
	return NULL;
}
