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

void Lcon::write_person(OUTPUT_STREAM, int p) {
	switch (p) {
		case FIRST_PERSON: WRITE("1p"); break;
		case SECOND_PERSON: WRITE("2p"); break;
		case THIRD_PERSON: WRITE("3p"); break;
	}
}

void Lcon::write_number(OUTPUT_STREAM, int n) {
	switch (n) {
		case SINGULAR_NUMBER: WRITE("s"); break;
		case PLURAL_NUMBER: WRITE("p"); break;
	}
}

void Lcon::write_gender(OUTPUT_STREAM, int g) {
	switch (g) {
		case NEUTER_GENDER: WRITE("n"); break;
		case MASCULINE_GENDER: WRITE("m"); break;
		case FEMININE_GENDER: WRITE("f"); break;
	}
}

void Lcon::write_sense(OUTPUT_STREAM, int s) {
	if (s == NEGATIVE_SENSE) WRITE("-ve");
	if (s == POSITIVE_SENSE) WRITE("+ve");
}

void Lcon::write_mood(OUTPUT_STREAM, int m) {
	if (m == ACTIVE_MOOD) WRITE("act");
	if (m == PASSIVE_MOOD) WRITE("pass");
}

void Lcon::write_tense(OUTPUT_STREAM, int t) {
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
		case NOMINATIVE_CASE: WRITE("nom"); break;
		case ACCUSATIVE_CASE: WRITE("acc"); break;
		default:              WRITE("case%d", c); break;
	}
}

@ =
int Lcon::same_but_for_gender(lcon_ti A, lcon_ti B) {
	if ((A - (A & GENDER_LCMASK)) == (B - (B & GENDER_LCMASK))) return TRUE;
	return FALSE;
}

int Lcon::same_but_for_person(lcon_ti A, lcon_ti B) {
	if ((A - (A & PERSON_LCMASK)) == (B - (B & PERSON_LCMASK))) return TRUE;
	return FALSE;
}

int Lcon::same_but_for_number(lcon_ti A, lcon_ti B) {
	if ((A - (A & NUMBER_LCMASK)) == (B - (B & NUMBER_LCMASK))) return TRUE;
	return FALSE;
}

int Lcon::same_but_for_mood(lcon_ti A, lcon_ti B) {
	if ((A - (A & MOOD_LCMASK)) == (B - (B & MOOD_LCMASK))) return TRUE;
	return FALSE;
}

int Lcon::same_but_for_case(lcon_ti A, lcon_ti B) {
	if ((A - (A & CASE_LCMASK)) == (B - (B & CASE_LCMASK))) return TRUE;
	return FALSE;
}

int Lcon::same_but_for_tense(lcon_ti A, lcon_ti B) {
	if ((A - (A & TENSE_LCMASK)) == (B - (B & TENSE_LCMASK))) return TRUE;
	return FALSE;
}

int Lcon::same_but_for_sense(lcon_ti A, lcon_ti B) {
	if ((A - (A & SENSE_LCMASK)) == (B - (B & SENSE_LCMASK))) return TRUE;
	return FALSE;
}

@h Axes.
We can think of a combination of the seven grammatical attributes above as
being like a position in seven-dimensional space, with each being a coordinate
on one of these sevem axes.

In practice, we're oftem interested in only a few of the seven. Nouns, for
instance, do not have tenses; verbs do not have cases. It's convenient to
represent the seven axes by the following constants, so that an arbitrary
sum of these can represent a set of things we're interested in:

@d GENDER_LCW 1
@d PERSON_LCW 2
@d NUMBER_LCW 4
@d MOOD_LCW   8
@d CASE_LCW   16
@d TENSE_LCW  32
@d SENSE_LCW  64

@ And |desiderata| in the following function is exactly that sort of set.

=
void Lcon::write(OUTPUT_STREAM, lcon_ti l, int desiderata) {
	for (int axis=1; axis<128; axis=axis*2)
		if (desiderata & axis) {
			WRITE(" ");
			Lcon::write_value_on_axis(OUT, axis, Lcon::get_value_on_axis(axis, l));
		}
}

@ The parameter |axis| in the following must, on the other hand, be a pure power
of 2, that is, it must be a single |*_LCW| value.

=
void Lcon::write_value_on_axis(OUTPUT_STREAM, int axis, int v) {
	switch (axis) {
		case GENDER_LCW: Lcon::write_gender(OUT, v); break;
		case PERSON_LCW: Lcon::write_person(OUT, v); break;
		case NUMBER_LCW: Lcon::write_number(OUT, v); break;
		case MOOD_LCW: Lcon::write_mood(OUT, v); break;
		case CASE_LCW: Lcon::write_case(OUT, v); break;
		case TENSE_LCW: Lcon::write_tense(OUT, v); break;
		case SENSE_LCW: Lcon::write_sense(OUT, v); break;
		default: internal_error("bad axis");
	}
}

int Lcon::get_value_on_axis(int axis, lcon_ti A) {
	switch (axis) {
		case GENDER_LCW: return Lcon::get_gender(A);
		case PERSON_LCW: return Lcon::get_person(A);
		case NUMBER_LCW: return Lcon::get_number(A);
		case MOOD_LCW: return Lcon::get_mood(A);
		case CASE_LCW: return Lcon::get_case(A);
		case TENSE_LCW: return Lcon::get_tense(A);
		case SENSE_LCW: return Lcon::get_sense(A);
		default: internal_error("bad axis");
	}
	return 0;
}

int Lcon::same_but_for_value_on_axis(int axis, lcon_ti A, lcon_ti B) {
	switch (axis) {
		case GENDER_LCW: return Lcon::same_but_for_gender(A, B);
		case PERSON_LCW: return Lcon::same_but_for_person(A, B);
		case NUMBER_LCW: return Lcon::same_but_for_number(A, B);
		case MOOD_LCW: return Lcon::same_but_for_mood(A, B);
		case CASE_LCW: return Lcon::same_but_for_case(A, B);
		case TENSE_LCW: return Lcon::same_but_for_tense(A, B);
		case SENSE_LCW: return Lcon::same_but_for_sense(A, B);
		default: internal_error("bad axis");
	}
	return 0;
}

@h Writing sets.
Suppose we have a list of |lcon_ti| constants and want to print out their
grammatical attributes. If we do that in the obvious way, by calling
//Lcon::write// on each of the constants in turn, we tend to get a list
of tiresome length. We want to abbreviate so that, e.g.,
= (text)
	1p s + 1p p + 2p s + 2p p + 3p s + 3p p
=
becomes just |1p/2p/3p s/p|.

Doing this is surprisingly non-trivial: an optimal solution means finding
the minimal number of disjoint 7-dimensional cuboids whose union is the
set of coordinates in the list. "Cuboid" here really means "Cartesian
product of seven sets"; the above case is a benign one because the set
in question is a single cuboid --
$$ \lbrace (1p, s), (2p, s), (3p, s), (1p, p), (2p, p), (3p, p) \rbrace = \lbrace 1p, 2p, 3p \rbrace\times\lbrace s, p\rbrace. $$

We will aim for an adequately good answer, not an optimal one. The following
code is really only needed for printing tidy debugging and test logs, so
it's probably not worth any further effort.

@ To avoid the C extension for variable-length arrays, and to avoid memory
allocation, we're simply going to make our working arrays quite large. But
this is fine -- the function is for printing, so it's not used much.

@d MAX_LCON_SET_SIZE
	NO_KNOWN_GENDERS*NO_KNOWN_PERSONS*NO_KNOWN_NUMBERS*NO_KNOWN_MOODS*
		NO_KNOWN_SENSES*MAX_GRAMMATICAL_CASES*NO_KNOWN_TENSES

@ We are going to aggregate items in the list into numbered cuboids. The
strategy is simple: start with the first item; make the largest-volume cuboid
inside our set which contains that item; then take the next item not already
included, and continue.

=
void Lcon::write_set(OUTPUT_STREAM, lcon_ti *set, int set_size, int desiderata) {
	if (set_size > MAX_LCON_SET_SIZE) internal_error("lcon set too large");
	int cuboid_number[MAX_LCON_SET_SIZE];
	for (int i=0; i<set_size; i++) cuboid_number[i] = -1;
	for (int i=0, cuboid=0; i<set_size; i++) if (cuboid_number[i] == -1) {
		if (cuboid++ > 0) WRITE(" +");
		@<Find the most volumetric cuboid containing this form@>;
	}
}

@ Note that there is always at least one cuboid containing the item $i$ --
the $1\times 1\times 1\times 1\times 1\times 1\times 1$ cuboid containing
just that one point. So the following certainly finds something. The
|elongated_sides| value accumulates the set of axis directions in which
the cuboid is longer than 1.

@<Find the most volumetric cuboid containing this form@> =
	cuboid_number[i] = cuboid;
	int elongated_sides = 0;

	@<Repeatedly elongate in the axis which maximises the volume growth@>;
	@<Write the resulting cuboid out@>;

@ So now we are at item $i$. We repeatedly do the following: try to expand
the cuboid into each of the seven axis directions, then choose the one
which expands it the most. We stop when no further expansion is possible.

@<Repeatedly elongate in the axis which maximises the volume growth@> =
	int max_elongation = 0;
	do {
		int best_d = 0;
		max_elongation = 0;
		int enlarged[MAX_LCON_SET_SIZE];
		for (int d = 1; d < 128; d = d*2) if (d & desiderata) {
			int elongation = 0;
			@<Enlarge the cuboid in axis direction d@>;
			if (max_elongation < elongation) { max_elongation = elongation; best_d = d; }
		}
		if (best_d) {
			elongated_sides = elongated_sides | best_d;
			int d = best_d, elongation = 0;
			@<Enlarge the cuboid in axis direction d@>;
			for (int j=0; j<set_size; j++) cuboid_number[j] = enlarged[j];
		}
	} while (max_elongation > 0);

@ We start with the current cuboid. The |enlarged| array will be the same as
the |cuboid_number| array except that some additional points |x| for which
|cuboid_number[x]| is $-1$ -- i.e., points not yet placed in any cuboid --
will have |enlarged[x]| set to |cuboid| -- i.e., will be placed in the current
cuboid. In effect, |enlarged| is a speculative next version of |cuboid_number|.

We first find the "variations" in the $d$ direction: that is, $d$ coordinates
of points which are either $i$ itself or are unplaced points whose other
coordinates are the same as those for $i$.

@<Enlarge the cuboid in axis direction d@> =
	for (int j=0; j<set_size; j++) enlarged[j] = cuboid_number[j];
	int variations[MAX_LCON_SET_SIZE], no_vars;
	@<Find all the variations on axis d from position i@>;
	int allow = TRUE;
	@<Check every position has the same variations, and elongate by them@>;
	if (allow == FALSE) elongation = 0;

@ For example, if $i = (2, 1, 0, 0, 0, 0, 0)$ and $d$ is the second axis, then
one variation would be 1 (the $d$ coordinate of $i$ itself) and if, say,
$(2, 7, 0, 0, 0, 0, 0)$ were an unplaced point then 7 would also be a variation.

@<Find all the variations on axis d from position i@> =
	no_vars = 0;
	for (int j=0; j<set_size; j++) if ((cuboid_number[j] < 0) || (j == i)) {
		lcon_ti A = set[i], B = set[j];
		if (Lcon::same_but_for_value_on_axis(d, A, B))
			variations[no_vars++] = Lcon::get_value_on_axis(d, B);
	}

@ Now suppose our variation set is indeed $\lbrace 1, 7\rbrace$, as in the
above example. The idea is that we will use this set as the new side for the
cuboid. We know that we can vary $i$ by these values; that's how they were
found. But we must also check that we can vary every other point currently
in the cuboid in the same way. If we can't, the attempt fails.

@<Check every position has the same variations, and elongate by them@> =
	for (int k=0; k<set_size; k++) if (cuboid_number[k] == cuboid) {
		for (int vc=0; vc<no_vars; vc++) {
			int v = variations[vc], found = FALSE;
			for (int j=0; j<set_size; j++) if ((cuboid_number[j] < 0) || (j == k)) {
				lcon_ti A = set[k], B = set[j];
				if ((Lcon::same_but_for_value_on_axis(d, A, B)) &&
					(v == Lcon::get_value_on_axis(d, B))) {
					if (enlarged[j] == -1) {
						enlarged[j] = cuboid; elongation++;
					}
					found = TRUE;
				}
			}
			if (found == FALSE) allow = FALSE;
		} 
	}

@ And finally, but also not quite trivially, printing out the cuboid. We
handle the elongated sides differently from the unelongated ones, which
are relegated to the //Lcon::write// call at the end. Note that this prints
nothing if |remainder| is zero.

@<Write the resulting cuboid out@> =
	int unelongated_sides = desiderata;
	for (int d=1; d<128; d=d*2) {
		if (elongated_sides & d) {
			unelongated_sides = unelongated_sides - d;
			WRITE(" ");
			int values[MAX_LCON_SET_SIZE];
			for (int j=0, vc=0, terms=0; j<set_size; j++) if (cuboid_number[j] == cuboid) {
				int v = Lcon::get_value_on_axis(d, set[j]);
				int already_listed = FALSE;
				for (int x=0; x<vc; x++) if (v == values[x]) already_listed = TRUE;
				if (already_listed == FALSE) {
					if (terms++ > 0) WRITE("/");
					Lcon::write_value_on_axis(OUT, d, v);
					values[vc++] = v;
				}
			}		
		}
	}
	Lcon::write(OUT, set[i], unelongated_sides);
