[VersionNumbers::] Version Numbers.

Semantic version numbers such as 3.7.1.

@ For example, 4, 7.1, and 0.2.3 are all version numbers. Up to |VERSION_NUMBER_DEPTH|
components can be given. The tail of the array should be padded with |-1| values;
otherwise, components should all be non-negative integers.

@d VERSION_NUMBER_DEPTH 4

=
typedef struct inbuild_version_number {
	int version_numbers[VERSION_NUMBER_DEPTH];
} inbuild_version_number;

@ All invalid strings of numbers -- i.e., breaking the above rules -- are
called "null" versions, and can never be valid as the version of anything.
Instead they are used to represent the absence of a version number.
(In particular, a string of |-1|s is null.)

=
inbuild_version_number VersionNumbers::null(void) {
	inbuild_version_number V;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++) V.version_numbers[i] = -1;
	return V;
}

int VersionNumbers::is_null(inbuild_version_number V) {
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
void VersionNumbers::to_text(OUTPUT_STREAM, inbuild_version_number V) {
	if (VersionNumbers::is_null(V)) WRITE("null");
	else
		for (int i=0; (i<VERSION_NUMBER_DEPTH) && (V.version_numbers[i] >= 0); i++) {
			if (i>0) WRITE(".");
			WRITE("%d", V.version_numbers[i]);
		}
}

inbuild_version_number VersionNumbers::from_text(text_stream *T) {
	inbuild_version_number V;
	int component = 0, val = -1;
	LOOP_THROUGH_TEXT(pos, T) {
		wchar_t c = Str::get(pos);
		if (c == '.') {
			if (val == -1) return VersionNumbers::null();
			if (component >= VERSION_NUMBER_DEPTH) return VersionNumbers::null();
			V.version_numbers[component] = val;
			component++; val = -1;
		} else if (Characters::isdigit(c)) {
			int digit = c - '0';
			if (val < 0) val = digit; else val = 10*val + digit;
		} else return VersionNumbers::null();
	}
	if (val == -1) return VersionNumbers::null();
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
int VersionNumbers::eq(inbuild_version_number V1, inbuild_version_number V2) {
	if (VersionNumbers::is_null(V1)) return VersionNumbers::is_null(V2);
	if (VersionNumbers::is_null(V2)) return FALSE;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++)
		if (V1.version_numbers[i] != V2.version_numbers[i])
			return FALSE;
	return TRUE;
}

int VersionNumbers::ne(inbuild_version_number V1, inbuild_version_number V2) {
	return (VersionNumbers::eq(V1, V2))?FALSE:TRUE;
}

int VersionNumbers::le(inbuild_version_number V1, inbuild_version_number V2) {
	if (VersionNumbers::is_null(V1)) return TRUE;
	if (VersionNumbers::is_null(V2)) return TRUE;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++)
		if (V1.version_numbers[i] > V2.version_numbers[i])
			return FALSE;
	return TRUE;
}

int VersionNumbers::gt(inbuild_version_number V1, inbuild_version_number V2) {
	return (VersionNumbers::le(V1, V2))?FALSE:TRUE;
}

int VersionNumbers::ge(inbuild_version_number V1, inbuild_version_number V2) {
	if (VersionNumbers::is_null(V1)) return TRUE;
	if (VersionNumbers::is_null(V2)) return TRUE;
	for (int i=0; i<VERSION_NUMBER_DEPTH; i++)
		if (V1.version_numbers[i] < V2.version_numbers[i])
			return FALSE;
	return TRUE;
}

int VersionNumbers::lt(inbuild_version_number V1, inbuild_version_number V2) {
	return (VersionNumbers::ge(V1, V2))?FALSE:TRUE;
}

