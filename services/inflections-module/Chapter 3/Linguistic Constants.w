[Lcon::] Linguistic Constants.

Some basic linguistic constants are defined.

@h Constants.
First, we support three genders:

@d NO_KNOWN_GENDERS 3
@d NEUTER_GENDER 1 /* or can be used as Scandinavian "common gender" */
@d MASCULINE_GENDER 2
@d FEMININE_GENDER 3

@ There are six "persons". The sequence corresponds to the defined constants
in the English Language extension, which we assume will be followed by other
languages.

@d NO_KNOWN_PERSONS 3
@d FIRST_PERSON 0
@d SECOND_PERSON 1
@d THIRD_PERSON 2

@ And two numbers:

@d NO_KNOWN_NUMBERS 2
@d SINGULAR_NUMBER 0
@d PLURAL_NUMBER 1

@ And two moods:

@d NO_KNOWN_MOODS 2
@d ACTIVE_MOOD 0
@d PASSIVE_MOOD 1

@ And two senses:

@d NO_KNOWN_SENSES 2
@d POSITIVE_SENSE 0
@d NEGATIVE_SENSE 1

@ 25 cases sounds like plenty, but some languages are pretty scary this
way: Hungarian has 18. We only require two cases to exist, the nominative
and accusative, which are required to be cases 0 and 1.

@d MAX_GRAMMATICAL_CASES 25
@d NOMINATIVE_CASE 0
@d ACCUSATIVE_CASE 1

@ There are at least five tenses, the first four of which are used by Inform
in English. Some languages can use optional extras; French, for example, uses
tense 5 for the past historic.

@d NO_KNOWN_TENSES 7
@d IS_TENSE 0       /* Present */
@d WAS_TENSE 1      /* Past */
@d HASBEEN_TENSE 2  /* Present perfect */
@d HADBEEN_TENSE 3  /* Past perfect */
@d WILLBE_TENSE 4   /* Future (not used in assertions or conditions) */
@d CUSTOM1_TENSE 5
@d CUSTOM2_TENSE 6

@h Packed references.
The following enables even a 32-bit integer to hold an ID reference in the
range 0 to 128K, together with any combination of gender, person, number,
mood, case, tense, and sense. This could be optimised further, exploiting
for example that no grammatical concept ever simultaneously has mood and
gender, but it seems unlikely that there's any need.

If the 128K limit on references ever becomes problematic, which seems very
unlikely, we might compromise on the number of cases; or we might simply
change |lcon_ti| to a wider integer type. (It needs to have value copy
semantics.) If so, though, Preform results will also need to be widened,
because numerous Preform nonterminals in //linguistics// return |lcon_ti|
values, and at present Preform return values are |int|.

@d lcon_ti int

@ And here's how we pack everything in:
= (text)
            <-- lsb     32 bits      msb -->
    gender  xx..............................
    person  ..xx............................
    number  ....x...........................
    mood    .....x..........................
    case    ......xxxxx.....................
	tense   ...........xxx..................
	sense   ..............x.................
	id      ...............xxxxxxxxxxxxxxxxx
=

@d GENDER_LCBASE 0x00000001
@d GENDER_LCMASK 0x00000003
@d PERSON_LCBASE 0x00000004
@d PERSON_LCMASK 0x0000000C
@d NUMBER_LCBASE 0x00000010
@d NUMBER_LCMASK 0x00000010
@d MOOD_LCBASE   0x00000020
@d MOOD_LCMASK   0x00000020
@d CASE_LCBASE   0x00000040
@d CASE_LCMASK   0x000007C0
@d TENSE_LCBASE  0x00000800
@d TENSE_LCMASK  0x00003800
@d SENSE_LCBASE  0x00004000
@d SENSE_LCMASK  0x00004000
@d ID_LCBASE     0x00008000
@d ID_LCUNMASK   0x00007FFF

=
lcon_ti Lcon::base(void) { return (lcon_ti) 0; }
lcon_ti Lcon::of_id(int id) { return (lcon_ti) id*ID_LCBASE; }

int Lcon::get_id(lcon_ti l)     { return (int) l/ID_LCBASE; }
int Lcon::get_gender(lcon_ti l) { return (int) (l & GENDER_LCMASK) / GENDER_LCBASE; }
int Lcon::get_person(lcon_ti l) { return (int) (l & PERSON_LCMASK) / PERSON_LCBASE; }
int Lcon::get_number(lcon_ti l) { return (int) (l & NUMBER_LCMASK) / NUMBER_LCBASE; }
int Lcon::get_mood(lcon_ti l)   { return (int) (l & MOOD_LCMASK) / MOOD_LCBASE; }
int Lcon::get_case(lcon_ti l)   { return (int) (l & CASE_LCMASK) / CASE_LCBASE; }
int Lcon::get_tense(lcon_ti l)  { return (int) (l & TENSE_LCMASK) / TENSE_LCBASE; }
int Lcon::get_sense(lcon_ti l)  { return (int) (l & SENSE_LCMASK) / SENSE_LCBASE; }

lcon_ti Lcon::set_id(lcon_ti l, int id) { return (l & ID_LCUNMASK) + id*ID_LCBASE; }
lcon_ti Lcon::set_gender(lcon_ti l, int x) { return (l & (~GENDER_LCMASK)) + x*GENDER_LCBASE; }
lcon_ti Lcon::set_person(lcon_ti l, int x) { return (l & (~PERSON_LCMASK)) + x*PERSON_LCBASE; }
lcon_ti Lcon::set_number(lcon_ti l, int x) { return (l & (~NUMBER_LCMASK)) + x*NUMBER_LCBASE; }
lcon_ti Lcon::set_mood(lcon_ti l, int x)   { return (l & (~MOOD_LCMASK)) + x*MOOD_LCBASE; }
lcon_ti Lcon::set_case(lcon_ti l, int x)   { return (l & (~CASE_LCMASK)) + x*CASE_LCBASE; }
lcon_ti Lcon::set_tense(lcon_ti l, int x)  { return (l & (~TENSE_LCMASK)) + x*TENSE_LCBASE; }
lcon_ti Lcon::set_sense(lcon_ti l, int x)  { return (l & (~SENSE_LCMASK)) + x*SENSE_LCBASE; }

@

@d GENDER_LCW 1
@d PERSON_LCW 2
@d NUMBER_LCW 4
@d MOOD_LCW   8
@d CASE_LCW   16
@d TENSE_LCW  32
@d SENSE_LCW  64

=
void Lcon::write(OUTPUT_STREAM, lcon_ti l, int desiderata) {
	if (desiderata & GENDER_LCW) Lcon::write_gender(OUT, Lcon::get_gender(l));
	if (desiderata & PERSON_LCW) Lcon::write_person(OUT, Lcon::get_person(l));
	if (desiderata & NUMBER_LCW) Lcon::write_number(OUT, Lcon::get_number(l));
	if (desiderata & MOOD_LCW) Lcon::write_mood(OUT, Lcon::get_mood(l));
	if (desiderata & CASE_LCW) Lcon::write_case(OUT, Lcon::get_case(l));
	if (desiderata & TENSE_LCW) Lcon::write_tense(OUT, Lcon::get_tense(l));
	if (desiderata & SENSE_LCW) Lcon::write_sense(OUT, Lcon::get_sense(l));
}

void Lcon::write_person(OUTPUT_STREAM, int p) {
	switch (p) {
		case FIRST_PERSON: WRITE(" 1p"); break;
		case SECOND_PERSON: WRITE(" 2p"); break;
		case THIRD_PERSON: WRITE(" 3p"); break;
	}
}

void Lcon::write_number(OUTPUT_STREAM, int n) {
	switch (n) {
		case SINGULAR_NUMBER: WRITE(" s"); break;
		case PLURAL_NUMBER: WRITE(" p"); break;
	}
}

void Lcon::write_gender(OUTPUT_STREAM, int g) {
	switch (g) {
		case NEUTER_GENDER: WRITE(" (n)"); break;
		case MASCULINE_GENDER: WRITE(" (m)"); break;
		case FEMININE_GENDER: WRITE(" (f)"); break;
	}
}

void Lcon::write_sense(OUTPUT_STREAM, int s) {
	if (s == NEGATIVE_SENSE) WRITE(" -ve");
	if (s == POSITIVE_SENSE) WRITE(" +ve");
}

void Lcon::write_mood(OUTPUT_STREAM, int m) {
	if (m == ACTIVE_MOOD) WRITE(" act");
	if (m == PASSIVE_MOOD) WRITE(" pass");
}

void Lcon::write_tense(OUTPUT_STREAM, int t) {
	WRITE(" "); 
	switch (t) {
		case IS_TENSE:      WRITE("IS_TENSE"); break;
		case WAS_TENSE:     WRITE("WAS_TENSE"); break;
		case HASBEEN_TENSE: WRITE("HASBEEN_TENSE"); break;
		case HADBEEN_TENSE: WRITE("HADBEEN_TENSE"); break;
		case WILLBE_TENSE:  WRITE("WILLBE_TENSE"); break;
		case CUSTOM1_TENSE: WRITE("CUSTOM1_TENSE"); break;
		case CUSTOM2_TENSE: WRITE("CUSTOM2_TENSE"); break;
		default:            WRITE("<invalid-tense>"); break;
	}
}

void Lcon::write_case(OUTPUT_STREAM, int c) {
	switch (c) {
		case NOMINATIVE_CASE: WRITE(" nom"); break;
		case ACCUSATIVE_CASE: WRITE(" acc"); break;
		default:              WRITE(" case%d", c); break;
	}
}
