[VersionNumbers::] Version Numbers.

Semantic version numbers such as 3.7.1.

@ Traditional semantic version numbers look like dot-divided runs of
non-negative integers: for example, 4, 7.1, and 0.2.3. Up to |VERSION_NUMBER_DEPTH|
components can be given. The tail of the array should be padded with |-1| values;
otherwise, components should all be non-negative integers.

@d VERSION_NUMBER_DEPTH 4

=
typedef struct semantic_version_number {
	int version_numbers[VERSION_NUMBER_DEPTH];
} semantic_version_number;

typedef struct semantic_version_number_holder {
	struct semantic_version_number version;
	MEMORY_MANAGEMENT
} semantic_version_number_holder;

@ However, Inform 7 extensions have for many years allowed two forms of
version number: either just |N|, which clearly fits the scheme above, or
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
|N/DDDDDD| is equivalent to |N.DDDDDD|.

@ All invalid strings of numbers -- i.e., breaking the above rules -- are
called "null" versions, and can never be valid as the version of anything.
Instead they are used to represent the absence of a version number.
(In particular, a string of |-1|s is null.)

=
semantic_version_number VersionNumbers::null(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconditional-uninitialized"
	semantic_version_number V;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++) V.version_numbers[i] = -1;
	return V;
#pragma clang diagnostic pop
}

semantic_version_number VersionNumbers::from_major(int major) {
	semantic_version_number V = VersionNumbers::null();
	V.version_numbers[0] = major;
	return V;
}

semantic_version_number VersionNumbers::from_pair(int major, int minor) {
	semantic_version_number V = VersionNumbers::null();
	V.version_numbers[0] = major;
	V.version_numbers[1] = minor;
	return V;
}

int VersionNumbers::is_null(semantic_version_number V) {
	for (int i=0, allow=TRUE; i<VERSION_NUMBER_DEPTH; i++) {
		if (V.version_numbers[i] < -1)
			return TRUE;
		if (V.version_numbers[i] == -1)
			allow = FALSE;
		else if (allow == FALSE) return TRUE;
	}
	if (V.version_numbers[0] < 0) return TRUE;
	return FALSE;
}

@ Here we print and parse:

=
void VersionNumbers::to_text(OUTPUT_STREAM, semantic_version_number V) {
	if (VersionNumbers::is_null(V)) WRITE("null");
	else
		for (int i=0; (i<VERSION_NUMBER_DEPTH) && (V.version_numbers[i] >= 0); i++) {
			if (i>0) WRITE(".");
			WRITE("%d", V.version_numbers[i]);
		}
}

void VersionNumbers::writer(OUTPUT_STREAM, char *format_string, void *vE) {
	semantic_version_number *V = (semantic_version_number *) vE;
	VersionNumbers::to_text(OUT, *V);
}

semantic_version_number VersionNumbers::from_text(text_stream *T) {
	semantic_version_number V;
	int component = 0, val = -1, dots_used = 0, slashes_used = 0, count = 0;
	LOOP_THROUGH_TEXT(pos, T) {
		wchar_t c = Str::get(pos);
		if (c == '.') dots_used++;
		if (c == '/') slashes_used++;
		if ((c == '.') || (c == '/')) {
			if (val == -1) return VersionNumbers::null();
			if (component >= VERSION_NUMBER_DEPTH) return VersionNumbers::null();
			V.version_numbers[component] = val;
			component++; val = -1; count = 0;
		} else if (Characters::isdigit(c)) {
			int digit = c - '0';
			if ((val == 0) && (slashes_used == 0))
				return VersionNumbers::null();
			if (val < 0) val = digit; else val = 10*val + digit;
			count++;
		} else return VersionNumbers::null();
	}
	if (val == -1) return VersionNumbers::null();
	if ((dots_used > 0) && (slashes_used > 0)) return VersionNumbers::null();
	if (slashes_used > 0) {
		if (component > 1) return VersionNumbers::null();
		if (count != 6) return VersionNumbers::null();
	}
	if (component >= VERSION_NUMBER_DEPTH) return VersionNumbers::null();
	V.version_numbers[component] = val;
	for (int i=component+1; i<VERSION_NUMBER_DEPTH; i++) V.version_numbers[i] = -1;
	return V;
}

@ And now comparison operators. Note that all null versions are equal, and
are always both |<=| and |>=| all versions. This means our ordering is not
trichotomous (though it is on the set of non-null versions), but this
ensures that null versions can be used to mean "unlimited" in either direction.

=
int VersionNumbers::eq(semantic_version_number V1, semantic_version_number V2) {
	if (VersionNumbers::is_null(V1)) return VersionNumbers::is_null(V2);
	if (VersionNumbers::is_null(V2)) return FALSE;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++)
		if (V1.version_numbers[i] != V2.version_numbers[i])
			return FALSE;
	return TRUE;
}

int VersionNumbers::ne(semantic_version_number V1, semantic_version_number V2) {
	return (VersionNumbers::eq(V1, V2))?FALSE:TRUE;
}

int VersionNumbers::le(semantic_version_number V1, semantic_version_number V2) {
	if (VersionNumbers::is_null(V1)) return TRUE;
	if (VersionNumbers::is_null(V2)) return TRUE;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++)
		if (V1.version_numbers[i] > V2.version_numbers[i])
			return FALSE;
	return TRUE;
}

int VersionNumbers::gt(semantic_version_number V1, semantic_version_number V2) {
	return (VersionNumbers::le(V1, V2))?FALSE:TRUE;
}

int VersionNumbers::ge(semantic_version_number V1, semantic_version_number V2) {
	if (VersionNumbers::is_null(V1)) return TRUE;
	if (VersionNumbers::is_null(V2)) return TRUE;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++)
		if (V1.version_numbers[i] < V2.version_numbers[i])
			return FALSE;
	return TRUE;
}

int VersionNumbers::lt(semantic_version_number V1, semantic_version_number V2) {
	return (VersionNumbers::ge(V1, V2))?FALSE:TRUE;
}

