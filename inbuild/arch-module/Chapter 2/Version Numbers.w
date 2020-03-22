[VersionNumbers::] Version Numbers.

Semantic version numbers such as 3.7.1.

@h Standard adoption.
The Semantic Version Number standard, semver 2.0.0, provides a strict set
of rules for the format and meaning of version numbers: see |https://semver.org|.

Prior to the standard most version numbers in computing usage looked like
dot-divided runs of non-negative integers: for example, 4, 7.1, and 0.2.3.
The standard now requires exactly three: major, minor and patch. It's
therefore formally incorrect to have a version 2, or a version 2.3. We will
not be so strict on the textual form, which we will allow to be abbreviated.
Thus:

(a) The text |6.4.7| is understood to mean 6.4.7 and printed back as |6.4.7|
(b) The text |6| is understood to mean 6.0.0 and printed back as |6|
(c) The text |6.1| is understood to mean 6.1.0 and printed back as |6.1|
(d) The text |6.1.0| is understood to mean 6.1.0 and printed back as |6.1.0|

Similarly, the absence of a version number (called "null" below) will be
understood to mean 0.0.0, but will be distinguished from the explicit choice
to number something as 0.0.0.

@ A complication is that Inform 7 extensions have for many years allowed two
forms of version number: either just |N|, which fits the scheme above, or
|N/DDDDDD|, which does not. This is a format which was chosen for sentimental
reasons: IF enthusiasts know it well from the banner text of the Infocom
titles of the 1980s. This story file, for instance, was compiled at the
time of the Reykjavik summit between Presidents Gorbachev and Reagan:

	|Moonmist|
	|Infocom interactive fiction - a mystery story|
	|Copyright (c) 1986 by Infocom, Inc. All rights reserved.|
	|Moonmist is a trademark of Infocom, Inc.|
	|Release number 9 / Serial number 861022|

Story file collectors customarily abbreviate this in catalogues to |9/861022|.

We will therefore allow this notation, and convert it silently each way.
|N/DDDDDD| is equivalent to |N.DDDDDD|. Thus, |9/861022| means 9.861022.0 in
semver precedence order.

In all non-textual respects, and in particular on precedence rules, we follow
the standard exactly. The only reason we allow these abbreviations is because
we don't want to force Inform extension writers to type "Version 3.4.1 of
Such-and-Such by Me begins here", and so on: it would break all existing
extensions, for one thing, and it looks unfriendly.

@ In the array below, unspecified numbers are stored as |-1|. The three
components are otherwise required to be non-negative integers.

Semver allows for more elaborate forms: for example |3.1.41-alpha.72.zeta+6Q45|
would mean 3.1.41 but with prerelease versioning |alpha.72.zeta| and build
metadata |6Q45|. The |prerelease_segments| list for this would be a list of
three texts: |alpha|, |72|, |zeta|.

@d SEMVER_NUMBER_DEPTH 3 /* major, minor, patch */

=
typedef struct semantic_version_number {
	int version_numbers[SEMVER_NUMBER_DEPTH];
	struct linked_list *prerelease_segments; /* of |text_stream| */
	struct text_stream *build_metadata;
} semantic_version_number;

typedef struct semantic_version_number_holder {
	struct semantic_version_number version;
	MEMORY_MANAGEMENT
} semantic_version_number_holder;

@ All invalid strings of numbers -- i.e., breaking the above rules -- are
called "null" versions, and can never be valid as the version of anything.
Instead they are used to represent the absence of a version number.
(In particular, a string of |-1|s is null.)

=
semantic_version_number VersionNumbers::null(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconditional-uninitialized"
	semantic_version_number V;
	for (int i=0; i<SEMVER_NUMBER_DEPTH; i++) V.version_numbers[i] = -1;
	V.prerelease_segments = NULL;
	V.build_metadata = NULL;
	return V;
#pragma clang diagnostic pop
}

int VersionNumbers::is_null(semantic_version_number V) {
	for (int i=0, allow=TRUE; i<SEMVER_NUMBER_DEPTH; i++) {
		if (V.version_numbers[i] < -1) return TRUE; /* should never happen */
		if (V.version_numbers[i] == -1) allow = FALSE;
		else if (allow == FALSE) return TRUE; /* should never happen */
	}
	if (V.version_numbers[0] < 0) return TRUE;
	return FALSE;
}

@h Printing and parsing.
Printing is simple enough:

=
void VersionNumbers::to_text(OUTPUT_STREAM, semantic_version_number V) {
	if (VersionNumbers::is_null(V)) { WRITE("null"); return; }
	for (int i=0; (i<SEMVER_NUMBER_DEPTH) && (V.version_numbers[i] >= 0); i++) {
		if (i>0) WRITE(".");
		WRITE("%d", V.version_numbers[i]);
	}
	if (V.prerelease_segments) {
		int c = 0;
		text_stream *T;
		LOOP_OVER_LINKED_LIST(T, text_stream, V.prerelease_segments) {
			if (c++ == 0) WRITE("-"); else WRITE(".");
			WRITE("%S", T);
		}			
	}
	if (V.build_metadata) WRITE("+%S", V.build_metadata);
}

@ And this provides for the |%v| escape, though we must be careful when
using this to pass a pointer to the version, not the version itself;
variadic macros are not carefully enough type-checked by |clang| or |gcc|
to catch this sort of slip.

=
void VersionNumbers::writer(OUTPUT_STREAM, char *format_string, void *vE) {
	semantic_version_number *V = (semantic_version_number *) vE;
	VersionNumbers::to_text(OUT, *V);
}

@ Parsing is much more of a slog. The following returns a null version if
the text |T| is in any respect malformed, i.e., if it deviates from the
above specification in even the most trivial way. We parse the three parts
of a semver version in order: e.g. |3.1.41-alpha.72.zeta+6Q45| the first
part is up to the hyphen, the second part between the hyphen and the plus
sign, and the third part runs to the end. The second and third parts are
optional, but if both are given, they must be in that order.

@e MMP_SEMVERPART from 1
@e PRE_SEMVERPART
@e BM_SEMVERPART

=
semantic_version_number VersionNumbers::from_text(text_stream *T) {
	semantic_version_number V = VersionNumbers::null();
	int component = 0, val = -1, dots_used = 0, slashes_used = 0, count = 0;
	int part = MMP_SEMVERPART;
	TEMPORARY_TEXT(prerelease);
	LOOP_THROUGH_TEXT(pos, T) {
		wchar_t c = Str::get(pos);
		switch (part) {
			case MMP_SEMVERPART: 
				if (c == '.') dots_used++;
				if (c == '/') slashes_used++;
				if ((c == '.') || (c == '/') || (c == '-') || (c == '+')) {
					if (val == -1) return VersionNumbers::null();
					if (component >= SEMVER_NUMBER_DEPTH) return VersionNumbers::null();
					V.version_numbers[component] = val;
					component++; val = -1; count = 0;
					if (c == '-') part = PRE_SEMVERPART;
					if (c == '+') part = BM_SEMVERPART;
				} else if (Characters::isdigit(c)) {
					int digit = c - '0';
					if ((val == 0) && (slashes_used == 0))
						return VersionNumbers::null();
					if (val < 0) val = digit; else val = 10*val + digit;
					count++;
				} else return VersionNumbers::null();
				break;
			case PRE_SEMVERPART:
				if (c == '.') {
					@<Add prerelease content@>;
				} else if (c == '+') {
					@<Add prerelease content@>; part = BM_SEMVERPART;
				} else {
					PUT_TO(prerelease, c);
				}
				break;
			case BM_SEMVERPART:
				if (V.build_metadata == NULL) V.build_metadata = Str::new();
				PUT_TO(V.build_metadata, c);
				break;
		}
	}
	if ((part == PRE_SEMVERPART) && (Str::len(prerelease) > 0)) @<Add prerelease content@>;
	DISCARD_TEXT(prerelease);
	if ((dots_used > 0) && (slashes_used > 0)) return VersionNumbers::null();
	if (slashes_used > 0) {
		if (component > 1) return VersionNumbers::null();
		if (count != 6) return VersionNumbers::null();
	}
	if (part == MMP_SEMVERPART) {
		if (val == -1) return VersionNumbers::null();
		if (component >= SEMVER_NUMBER_DEPTH) return VersionNumbers::null();
		V.version_numbers[component] = val;
	}
	return V;
}

@<Add prerelease content@> =
	if (Str::len(prerelease) == 0) return VersionNumbers::null();
	if (V.prerelease_segments == NULL) V.prerelease_segments = NEW_LINKED_LIST(text_stream);
	ADD_TO_LINKED_LIST(Str::duplicate(prerelease), text_stream, V.prerelease_segments);
	Str::clear(prerelease);

@h Precendence.
The most important part of the semver standard is the rule on which versions
take precedence over which others, and we follow it exactly. The following
criteria are used in turn: major version; minor version; patch version;
any prerelease elements, which must be compared numerically if consisting
of digits only, and alphabetically otherwise; and finally the number of
prerelease elements. Build metadata is disregarded entirely.

=
int VersionNumbers::le(semantic_version_number V1, semantic_version_number V2) {
	for (int i=0; i<SEMVER_NUMBER_DEPTH; i++) {
		int N1 = VersionNumbers::floor(V1.version_numbers[i]);
		int N2 = VersionNumbers::floor(V2.version_numbers[i]);
		if (N1 > N2) return FALSE;
		if (N1 < N2) return TRUE;
	}
	linked_list_item *I1 = (V1.prerelease_segments)?(LinkedLists::first(V1.prerelease_segments)):NULL;
	linked_list_item *I2 = (V2.prerelease_segments)?(LinkedLists::first(V2.prerelease_segments)):NULL;
	while ((I1) && (I2)) {
		text_stream *T1 = (text_stream *) LinkedLists::content(I1);
		text_stream *T2 = (text_stream *) LinkedLists::content(I2);
		int N1 = VersionNumbers::strict_atoi(T1);
		int N2 = VersionNumbers::strict_atoi(T2);
		if ((N1 >= 0) && (N2 >= 0)) {
			if (N1 < N2) return TRUE;
			if (N1 > N2) return FALSE;
		} else {
			if (Str::ne(T1, T2)) {
				int c = Str::cmp(T1, T2);
				if (c < 0) return TRUE;
				if (c > 0) return FALSE;
			}
		}
		I1 = LinkedLists::next(I1);
		I2 = LinkedLists::next(I2);
	}
	if ((I1 == NULL) && (I2)) return TRUE;
	if ((I1) && (I2 == NULL)) return FALSE;
	return TRUE;
}

@ The effect of this is to read unspecified versions of major, minor or patch
as if they were 0:

=
int VersionNumbers::floor(int N) {
	if (N < 0) return 0;
	return N;
}

@ This returns a non-negative integer if |T| contains only digits, and |-1|
otherwise. If the value has more than about 10 digits, then the result will
not be meaningful, which I think is a technical violation of the standard.

=
int VersionNumbers::strict_atoi(text_stream *T) {
	LOOP_THROUGH_TEXT(pos, T)
		if (Characters::isdigit(Str::get(pos)) == FALSE)
			return -1;
	wchar_t c = Str::get_first_char(T);
	if ((c == '0') && (Str::len(T) > 1)) return -1;
	return Str::atoi(T, 0);
}

@h Trichotomy.
We now use the above function to construct ordering relations on semvers.
These are trichotomous, that is, for each pair |V1, V2|, exactly one of the
|VersionNumbers::eq(V1, V2)|, |VersionNumbers::gt(V1, V2)|, |VersionNumbers::lt(V1, V2)|
is true.

=
int VersionNumbers::eq(semantic_version_number V1, semantic_version_number V2) {
	if ((VersionNumbers::le(V1, V2)) && (VersionNumbers::le(V2, V1)))
		return TRUE;
	return FALSE;
}

int VersionNumbers::ne(semantic_version_number V1, semantic_version_number V2) {
	return (VersionNumbers::eq(V1, V2))?FALSE:TRUE;
}

int VersionNumbers::gt(semantic_version_number V1, semantic_version_number V2) {
	return (VersionNumbers::le(V1, V2))?FALSE:TRUE;
}

int VersionNumbers::ge(semantic_version_number V1, semantic_version_number V2) {
	return VersionNumbers::le(V2, V1);
}

int VersionNumbers::lt(semantic_version_number V1, semantic_version_number V2) {
	return (VersionNumbers::ge(V1, V2))?FALSE:TRUE;
}

@ And the following can be used for sorting, following the |strcmp| convention.

=
int VersionNumbers::cmp(semantic_version_number V1, semantic_version_number V2) {
	if (VersionNumbers::eq(V1, V2)) return 0;
	if (VersionNumbers::gt(V1, V2)) return 1;
	return -1;
}

@h Ranges.
We often want to check if a semver lies in a given precedence range, which we
store as an "interval" in the mathematical sense. For example, the range |[2,6)|
means all versions from 2.0.0 (inclusve) up to, but not equal to, 6.0.0. The
lower end is called "closed" because it includes the end-value 2.0.0, and the
upper end "open" because it does not. An infinite end means that there
os no restriction in that direction; an empty end means that, in fact, the
interval is the empty set, that is, that no version number can ever satisfy it.

The |end_value| element is meaningful only for |CLOSED_RANGE_END| and |OPEN_RANGE_END|
ends. If one end is marked |EMPTY_RANGE_END|, so must the other be: it makes
no sense for an interval to be empty seen from one end but not the other.

@e CLOSED_RANGE_END from 1
@e OPEN_RANGE_END
@e INFINITE_RANGE_END
@e EMPTY_RANGE_END

=
typedef struct range_end {
	int end_type;
	struct semantic_version_number end_value;
} range_end;

typedef struct semver_range {
	struct range_end lower;
	struct range_end upper;
	MEMORY_MANAGEMENT
} semver_range;

@ As hinted above, the notation |[| and |]| is used for closed ends, and |(|
and |)| for open ones.

=
void VersionNumbers::write_range(OUTPUT_STREAM, semver_range *R) {
	if (R == NULL) internal_error("no range");
	switch(R->lower.end_type) {
		case CLOSED_RANGE_END: WRITE("[%v,", &(R->lower.end_value)); break;
		case OPEN_RANGE_END: WRITE("(%v,", &(R->lower.end_value)); break;
		case INFINITE_RANGE_END: WRITE("(-infty,"); break;
		case EMPTY_RANGE_END: WRITE("empty"); break;
	}
	switch(R->upper.end_type) {
		case CLOSED_RANGE_END: WRITE("%v]", &(R->upper.end_value)); break;
		case OPEN_RANGE_END: WRITE("%v)", &(R->upper.end_value)); break;
		case INFINITE_RANGE_END: WRITE("infty)"); break;
	}
}

@ The "allow anything" range runs from minus to plus infinity. Every version
number lies in this range.

=
semver_range *VersionNumbers::any_range(void) {
	semver_range *R = CREATE(semver_range);
	R->lower.end_type = INFINITE_RANGE_END;
	R->lower.end_value = VersionNumbers::null();
	R->upper.end_type = INFINITE_RANGE_END;
	R->upper.end_value = VersionNumbers::null();
	return R;
}

int VersionNumbers::is_any_range(semver_range *R) {
	if (R == NULL) return TRUE;
	if ((R->lower.end_type == INFINITE_RANGE_END) && (R->upper.end_type == INFINITE_RANGE_END))
		return TRUE;
	return FALSE;
}

@ The "compatibility" range for a given version lies at the heart of semver:
to be compatible with version |V|, version |W| must be of equal or greater
precedence, and must have the same major version number. For example,
for |2.1.7| the range will be |[2.1.7, 3-A)|, all versions at least 2.1.7 but
not as high as 3.0.0-A.

Note that |3.0.0-A| is the least precendent version allowed by semver with
major version 3. The |-| gives it lower precedence than all release versions of
3.0.0; the fact that upper case |A| is alphabetically the earliest non-empty
alphanumeric string gives it lower precendence than all other prerelease
versions.

=
semver_range *VersionNumbers::compatibility_range(semantic_version_number V) {
	semver_range *R = VersionNumbers::any_range();
	if (VersionNumbers::is_null(V) == FALSE) {
		R->lower.end_type = CLOSED_RANGE_END;
		R->lower.end_value = V;
		R->upper.end_type = OPEN_RANGE_END;
		semantic_version_number W = VersionNumbers::null();
		W.version_numbers[0] = V.version_numbers[0] + 1;
		W.prerelease_segments = NEW_LINKED_LIST(text_stream);
		ADD_TO_LINKED_LIST(I"A", text_stream, W.prerelease_segments);
		R->upper.end_value = W;
	}
	return R;
}

@ More straightforwardly, these ranges are for anything from V, or up to V,
inclusive:

=
semver_range *VersionNumbers::at_least_range(semantic_version_number V) {
	semver_range *R = VersionNumbers::any_range();
	R->lower.end_type = CLOSED_RANGE_END;
	R->lower.end_value = V;
	return R;
}

semver_range *VersionNumbers::at_most_range(semantic_version_number V) {
	semver_range *R = VersionNumbers::any_range();
	R->upper.end_type = CLOSED_RANGE_END;
	R->upper.end_value = V;
	return R;
}

@ Here we test whether V is at least a given end, and then at most:

=
int VersionNumbers::version_ge_end(semantic_version_number V, range_end E) {
	switch (E.end_type) {
		case CLOSED_RANGE_END:
			if (VersionNumbers::is_null(V)) return FALSE;
			if (VersionNumbers::ge(V, E.end_value)) return TRUE;
			break;
		case OPEN_RANGE_END:
			if (VersionNumbers::is_null(V)) return FALSE;
			if (VersionNumbers::gt(V, E.end_value)) return TRUE;
			break;
		case INFINITE_RANGE_END: return TRUE;
		case EMPTY_RANGE_END: return FALSE;
	}
	return FALSE;
}

int VersionNumbers::version_le_end(semantic_version_number V, range_end E) {
	switch (E.end_type) {
		case CLOSED_RANGE_END:
			if (VersionNumbers::is_null(V)) return FALSE;
			if (VersionNumbers::le(V, E.end_value)) return TRUE;
			break;
		case OPEN_RANGE_END:
			if (VersionNumbers::is_null(V)) return FALSE;
			if (VersionNumbers::lt(V, E.end_value)) return TRUE;
			break;
		case INFINITE_RANGE_END: return TRUE;
		case EMPTY_RANGE_END: return FALSE;
	}
	return FALSE;
}

@ This allows a simple way to write:

=
int VersionNumbers::in_range(semantic_version_number V, semver_range *R) {
	if (R == NULL) return TRUE;
	if ((VersionNumbers::version_ge_end(V, R->lower)) &&
		(VersionNumbers::version_le_end(V, R->upper))) return TRUE;
	return FALSE;
}

@ The following decides which end restriction is stricter: it returns 1
of |E1| is, -1 if |E2| is, and 0 if they are equally onerous.

The empty set is as strict as it gets: nothing qualifies.

Similarly, infinite ends are as relaxed as can be: everything qualifies.

And otherwise, we need to know which end we're looking at in order to decide:
a lower end of |[4, ...]| is stricter than a lower end of |[3, ...]|, but an
upper end of |[..., 4]| is not as strict as an upper end of |[..., 3]|. Where
the boundary value is the same, open ends are stricter than closed ends.

=
int VersionNumbers::stricter(range_end E1, range_end E2, int lower) {
	if ((E1.end_type == EMPTY_RANGE_END) && (E2.end_type == EMPTY_RANGE_END)) return 0;
	if (E1.end_type == EMPTY_RANGE_END) return 1;
	if (E2.end_type == EMPTY_RANGE_END) return -1;
	if ((E1.end_type == INFINITE_RANGE_END) && (E2.end_type == INFINITE_RANGE_END)) return 0;
	if (E1.end_type == INFINITE_RANGE_END) return -1;
	if (E2.end_type == INFINITE_RANGE_END) return 1;
	int c = VersionNumbers::cmp(E1.end_value, E2.end_value);
	if (c != 0) {
		if (lower) return c; else return -c;
	}
	if (E1.end_type == E2.end_type) return 0;
	if (E1.end_type == CLOSED_RANGE_END) return -1;
	return 1;
}

@ And so we finally arrive at the following, which intersects two ranges:
that is, it changes |R1| to the range of versions which lie inside both the
original |R1| and also |R2|. (This is used by Inbuild when an extension is
included in two different places in the source text, but with possibly
different version needs.) The return value is true if an actual change took
place, and false otherwise.

=
int VersionNumbers::intersect_range(semver_range *R1, semver_range *R2) {
	int lc = VersionNumbers::stricter(R1->lower, R2->lower, TRUE);
	int uc = VersionNumbers::stricter(R1->upper, R2->upper, FALSE);
	if ((lc >= 0) && (uc >= 0)) return FALSE;
	if (lc < 0) R1->lower = R2->lower;
	if (uc < 0) R1->upper = R2->upper;
	if (R1->lower.end_type == EMPTY_RANGE_END) R1->upper.end_type = EMPTY_RANGE_END;
	else if (R1->upper.end_type == EMPTY_RANGE_END) R1->lower.end_type = EMPTY_RANGE_END;
	else if ((R1->lower.end_type != INFINITE_RANGE_END) && (R1->upper.end_type != INFINITE_RANGE_END)) {
		int c = VersionNumbers::cmp(R1->lower.end_value, R1->upper.end_value);
		if ((c > 0) ||
			((c == 0) && ((R1->lower.end_type == OPEN_RANGE_END) ||
				(R1->upper.end_type == OPEN_RANGE_END)))) {
			R1->lower.end_type = EMPTY_RANGE_END; R1->upper.end_type = EMPTY_RANGE_END;
		}
	}
	return TRUE;
}

@h Unit tests.
The Inbuild test case |semver| exercises the following.

=
void VersionNumbers::test_range(OUTPUT_STREAM, text_stream *text) {
	semantic_version_number V = VersionNumbers::from_text(text);
	semver_range *R = VersionNumbers::compatibility_range(V);
	WRITE("Compatibility range of %v  =  ", &V);
	VersionNumbers::write_range(OUT, R);
	WRITE("\n");
	R = VersionNumbers::at_least_range(V);
	WRITE("At-least range of %v  =  ", &V);
	VersionNumbers::write_range(OUT, R);
	WRITE("\n");
	R = VersionNumbers::at_most_range(V);
	WRITE("At-most range of %v  =  ", &V);
	VersionNumbers::write_range(OUT, R);
	WRITE("\n");
}

void VersionNumbers::test_intersect(OUTPUT_STREAM,
	text_stream *text1, int r1, text_stream *text2, int r2) {
	semantic_version_number V1 = VersionNumbers::from_text(text1);
	semver_range *R1 = NULL;
	if (r1 == 0) R1 = VersionNumbers::compatibility_range(V1);
	else if (r1 > 0) R1 = VersionNumbers::at_least_range(V1);
	else if (r1 < 0) R1 = VersionNumbers::at_most_range(V1);
	semantic_version_number V2 = VersionNumbers::from_text(text2);
	semver_range *R2 = NULL;
	if (r2 == 0) R2 = VersionNumbers::compatibility_range(V2);
	else if (r2 > 0) R2 = VersionNumbers::at_least_range(V2);
	else if (r2 < 0) R2 = VersionNumbers::at_most_range(V2);
	VersionNumbers::write_range(OUT, R1);
	WRITE(" intersect ");
	VersionNumbers::write_range(OUT, R2);
	WRITE(" = ");
	int changed = VersionNumbers::intersect_range(R1, R2);
	VersionNumbers::write_range(OUT, R1);
	if (changed) WRITE (" -- changed");
	WRITE("\n");
}

void VersionNumbers::test_read_write(OUTPUT_STREAM, text_stream *text) {
	semantic_version_number V = VersionNumbers::from_text(text);
	WRITE("'%S'   -->   %v\n", text, &V);
}

void VersionNumbers::test_precedence(OUTPUT_STREAM, text_stream *text1, text_stream *text2) {
	semantic_version_number V1 = VersionNumbers::from_text(text1);
	semantic_version_number V2 = VersionNumbers::from_text(text2);
	int gt = VersionNumbers::gt(V1, V2);
	int eq = VersionNumbers::eq(V1, V2);
	int lt = VersionNumbers::lt(V1, V2);
	if (lt) WRITE("%v  <  %v", &V1, &V2);
	if (eq) WRITE("%v  =  %v", &V1, &V2);
	if (gt) WRITE("%v  >  %v", &V1, &V2);
	WRITE("\n");
}

void VersionNumbers::test(OUTPUT_STREAM) {
	VersionNumbers::test_read_write(OUT, I"1");
	VersionNumbers::test_read_write(OUT, I"1.2");
	VersionNumbers::test_read_write(OUT, I"1.2.3");
	VersionNumbers::test_read_write(OUT, I"71.0.45672");
	VersionNumbers::test_read_write(OUT, I"1.2.3.4");
	VersionNumbers::test_read_write(OUT, I"9/861022");
	VersionNumbers::test_read_write(OUT, I"9/86102");
	VersionNumbers::test_read_write(OUT, I"9/8610223");
	VersionNumbers::test_read_write(OUT, I"9/861022.2");
	VersionNumbers::test_read_write(OUT, I"9/861022/2");
	VersionNumbers::test_read_write(OUT, I"1.2.3-alpha.0.x45.1789");
	VersionNumbers::test_read_write(OUT, I"1+lobster");
	VersionNumbers::test_read_write(OUT, I"1.2+lobster");
	VersionNumbers::test_read_write(OUT, I"1.2.3+lobster");
	VersionNumbers::test_read_write(OUT, I"1.2.3-beta.2+shellfish");
	
	WRITE("\n");
	VersionNumbers::test_precedence(OUT, I"3", I"5");
	VersionNumbers::test_precedence(OUT, I"3", I"3");
	VersionNumbers::test_precedence(OUT, I"3", I"3.0");
	VersionNumbers::test_precedence(OUT, I"3", I"3.0.0");
	VersionNumbers::test_precedence(OUT, I"3.1.41", I"3.1.5");
	VersionNumbers::test_precedence(OUT, I"3.1.41", I"3.2.5");
	VersionNumbers::test_precedence(OUT, I"3.1.41", I"3.1.41+arm64");
	VersionNumbers::test_precedence(OUT, I"3.1.41", I"3.1.41-pre.0.1");
	VersionNumbers::test_precedence(OUT, I"3.1.41-alpha.72", I"3.1.41-alpha.8");
	VersionNumbers::test_precedence(OUT, I"3.1.41-alpha.72a", I"3.1.41-alpha.8a");
	VersionNumbers::test_precedence(OUT, I"3.1.41-alpha.72", I"3.1.41-beta.72");
	VersionNumbers::test_precedence(OUT, I"3.1.41-alpha.72", I"3.1.41-alpha.72.zeta");
	VersionNumbers::test_precedence(OUT, I"1.2.3+lobster.54", I"1.2.3+lobster.100");
	
	WRITE("\n");
	VersionNumbers::test_range(OUT, I"6.4.2-kappa.17");

	WRITE("\n");
	VersionNumbers::test_intersect(OUT, I"6.4.2-kappa.17", 0, I"3.5.5", 0);
	VersionNumbers::test_intersect(OUT, I"6.4.2-kappa.17", 0, I"6.9.1", 0);
	VersionNumbers::test_intersect(OUT, I"6.9.1", 0, I"6.4.2-kappa.17", 0);
	VersionNumbers::test_intersect(OUT, I"6.4.2", 1, I"3.5.5", 1);
	VersionNumbers::test_intersect(OUT, I"6.4.2", 1, I"3.5.5", -1);
	VersionNumbers::test_intersect(OUT, I"6.4.2", -1, I"3.5.5", 1);
	VersionNumbers::test_intersect(OUT, I"6.4.2", -1, I"3.5.5", -1);
}
