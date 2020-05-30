[Occurrence::] Adverb Phrases of Occurrence.

To parse representations of periods of time or of historical
repetition.

@h Definitions.

@ In two different contexts (action patterns and specifications) we
will need a represention for periods of time. We measure time in two
units: "times", as in something having been true four times in the
past; and "turns", as in something having been true for five turns
now. We will also need to keep track of four tenses when discussing
time periods, and also whether we mean "three or more" (say) or
"less than seven" turns or times. We represent this using the
relevant I6 comparison operator: for instance a length of 5 and
an operator |>=| denotes "five or more". Lastly, we can denote a
closed interval of time as well, by setting |until| to the upper
end.

@d TIMES_UNIT 1 /* used for "for the third time" */
@d TURNS_UNIT 2 /* used for "for three turns" */

=
typedef struct time_period {
	int valid_tp; /* flag distinguishing validly and invalidly parsed periods */
	int units; /* one of the two above */
	int length; /* the duration or else the lower limit of an interval */
	int until; /* |-1| or else the upper limit of an interval */
	char *inform6_operator; /* |<=|, |==|, |>|, and so forth */
	int tense; /* one of the four above */
} time_period;

@ This simple procedure looks at the text between |w1| and |w2| to look for an
indication of a period of time, such as "twice" or "for more than the third
time".

=
time_period Occurrence::new(void) {
	time_period tp;
	tp.valid_tp = 0;
	tp.length = -1;
	tp.until = -1;
	tp.units = TIMES_UNIT;
	tp.inform6_operator = NULL;
	tp.tense = IS_TENSE;
	return tp;
}

time_period Occurrence::new_tense_marker(int t) {
	time_period tp = Occurrence::new();
	tp.tense = t;
	return tp;
}

time_period *Occurrence::store(time_period tp) {
	time_period *ntp = CREATE(time_period);
	*ntp = tp;
	return ntp;
}

void Occurrence::log(OUTPUT_STREAM, void *vtp) {
	time_period *tp = (time_period *) vtp;
	if (tp->valid_tp == FALSE) { WRITE("---"); return; }
	WRITE("<");
	if (tp->inform6_operator) WRITE("%s", tp->inform6_operator);
	if (tp->until >= 0) WRITE("%d", tp->until); else WRITE("%d", tp->length);
	switch(tp->units) {
		case TURNS_UNIT: WRITE(" turns"); break;
		case TIMES_UNIT: WRITE(" times"); break;
		default: WRITE(": <invalid-units>"); break;
	}
	if (tp->tense != IS_TENSE) {
		WRITE(": "); InflectionDefns::log_tense_number(OUT, tp->tense);
	}
	WRITE(">");
}

int Occurrence::is_valid(time_period *tp) {
	return tp->valid_tp;
}
void Occurrence::make_invalid(time_period *tp) {
	tp->valid_tp = FALSE;
}

int Occurrence::get_tense(time_period *tp) {
	return tp->tense;
}

void Occurrence::set_tense(time_period *tp, int t) {
	tp->tense = t;
}

int Occurrence::duration_count(time_period *tp) {
	int L = tp->length;
	if (L < 0) L = 0;
	if (tp->until >= 0) {
		return tp->until - L + 1;
	} else {
		if (tp->inform6_operator == NULL) return 1;
		if (strcmp(tp->inform6_operator, "==") == 0) return 1;
		if (strcmp(tp->inform6_operator, "<=") == 0) return L;
		if (strcmp(tp->inform6_operator, "<") == 0) return L - 1;
		if (strcmp(tp->inform6_operator, ">=") == 0) return 1000000 - L;
		if (strcmp(tp->inform6_operator, ">") == 0) return 1000000 - (L - 1);
	}
	return 0;
}

int Occurrence::compare_specificity(time_period *tp1, time_period *tp2) {
	if ((tp1) && (tp1->valid_tp == FALSE)) tp1 = NULL;
	if ((tp2) && (tp2->valid_tp == FALSE)) tp2 = NULL;

	if ((tp1 == NULL) && (tp2 == NULL)) return 0;

	if ((tp1) && (tp2 == NULL)) return 1;
	if ((tp2) && (tp1 == NULL)) return -1;

	int dc1 = Occurrence::duration_count(tp1);
	int dc2 = Occurrence::duration_count(tp2);

	if (dc1 > dc2) return -1;
	if (dc1 < dc2) return 1;

	return 0;
}

@

@d EQ_REPM 1
@d LT_REPM 2
@d LE_REPM 3
@d GT_REPM 4
@d GE_REPM 5
@d NO_REPM 6

@ Historical references are textual indications that a condition compares
the present state with past states: for example,

>> twice
>> for more than the third time

Note that every HR contains one of the words below, so that if
<historical-reference-possible> fails on an excerpt then it
cannot contain any HR; this cuts down our parsing time considerably.

=
<historical-reference-possible> ::=
	*** once/twice/thrice/turn/turns/time/times

@ Otherwise the grammar is straightforward:

=
<historical-reference> ::=
	for <repetition-specification> |    ==> R[1]
	<repetition-specification>					==> R[1]

<repetition-specification> ::=
	only/exactly <repetitions> |    ==> EQ_REPM
	at most <repetitions> |    ==> LE_REPM
	less/fewer than <repetitions> |    ==> LT_REPM
	at least <repetitions> |    ==> GE_REPM
	more than <repetitions> |    ==> GT_REPM
	under <repetitions> |    ==> LT_REPM
	over <repetitions> |    ==> GT_REPM
	<repetitions>								==> NO_REPM

<repetitions> ::=
	<iteration-repetitions> |    ==> 0; <<from>> = R[1]; <<unit>> = TIMES_UNIT
	<turn-repetitions>							==> 0; <<from>> = R[1]; <<unit>> = TURNS_UNIT

<iteration-repetitions> ::=
	once |    ==> 1
	twice |    ==> 2
	thrice |    ==> 3
	<rep-number> to <rep-number> time/times |    ==> R[1]; <<to>> = R[2]
	<rep-number> time/times						==> R[1]

<turn-repetitions> ::=
	<rep-number> to <rep-number> turn/turns |    ==> R[1]; <<to>> = R[2]
	<rep-number> turn/turns						==> R[1]

<rep-number> ::=
	<definite-article> <ordinal-number> |    ==> R[2]
	<ordinal-number> |    ==> R[1]
	<cardinal-number>							==> R[1]

@ =
time_period Occurrence::parse(wording W) {
	time_period tp = Occurrence::new();
	if (<historical-reference-possible>(W)) {
		LOOP_THROUGH_WORDING(k, W) {
			<<to>> = -1;
			if (<historical-reference>(Wordings::from(W, k))) {
				switch (<<r>>) {
					case EQ_REPM: tp.inform6_operator = "=="; break;
					case LT_REPM: tp.inform6_operator = "<"; break;
					case LE_REPM: tp.inform6_operator = "<="; break;
					case GT_REPM: tp.inform6_operator = ">"; break;
					case GE_REPM: tp.inform6_operator = ">="; break;
					case NO_REPM: tp.inform6_operator = NULL; break;
				}
				tp.length = <<from>>;
				tp.until = <<to>>;
				tp.units = <<unit>>;
				tp.valid_tp = k-1;
				LOGIF(TIME_PERIODS, "Parsed time period: <%W> = $t\n", Wordings::from(W, k), &tp);
				break;
			}
		}
	}
	return tp;
}
