[InterVersion::] The Inter Version.

The semantic version number for the current definition of Inter bytecode.

@ We can expect the details of the Inter language to change. Such changes
could easily render text or binary files of Inter code useless; so we will
want to use semantic versioning to compare the language as we understand it
(the "current version") with the language as it was understood by whoever
wrote the Inter file we are loading (the "file version").

If we consider the version as having the traditional form |major.minor.patch|,
the |major| version should change on any of the following:

(a) Removal of an Inter construct, or any renumbering of |*_IST| constants.
(b) Change of bytecode representation of an instruction.
(c) Change of the binary file format in //Inter in Binary Files//. Note that
changing some of the defined constants in this module could have the same effect,
since these constants are used as distinguishing values in binary Inter files.
(d) Change of the textual file format in //Inter in Text Files// and elsewhere
in the |CONSTRUCT_READ_MTID| methods for the constructs.
(e) Removal of one of the standard annotations, or any renumbering of existing
ones. See //Annotations//.
(f) Removal of one of the standard primitives, or any renumbering of existing
ones. See //building: Inter Primitives//.

This may result in ungainly, high |major| version numbers: so be it. However,
the following need only mean a bump of the |minor| version --

(a) Addition of a new Inter construct, provided the existing ones are not
renumbered.
(b) Addition of a new Inter annotation, provided the existing ones are not
renumbered.
(c) Addition of a new Inter primitive, provided the existing ones are not
renumbered.

The |patch| version number should always remain 0 -- this is not a version for
the implementation of anything, just for the specification itself, so in some
sense it cannot be bug-fixed, only changed.

Modifiers of the |+| and |-| sort are also best avoided here, so we will deal only
with SVNs in the traditional |x.y.z| format.

@ 1.0.0 (28 April 2022) was the baseline Inter implementation used in the beta of
Inform 10.1.0.

2.0.0 (24 May 2022) introduced a new base type constructor for "activity on T".
This renumbers the binary representation of types, so it is a major not minor bump.

3.0.0 (9 October 2022) added a new optional field to |SPLAT_IST| instructions,
which holds I6 annotations in the sense of Inform evolution proposal IE-0006.
Note that these are not Inter annotations, which apply to symbols: these apply
to directives.

4.0.0 (7 January 2023) added new type constructor codes to make it possible to
represent new data structures with custom kind constructors from Neptune files
in Inform kits.

5.0.0 (24 April 2023) added (further) new fields to |SPLAT_IST| instructions, to
record their provenance and so make better error reporting possible.

6.0.0 (25 May 2023) added the |ORIGSOURCE_IST| instruction.

7.0.0 (11 June 2023) renamed |ORIGSOURCE_IST| to |PROVENANCE_IST|, and added the
|ORIGIN_IST| instruction.

@ Anyway, the implementation, such as it is:

=
semantic_version_number InterVersion::current(void) {
	semantic_version_number V = VersionNumbers::from_text(I"7.0.0");
	if (VersionNumbers::is_null(V)) internal_error("malformed version number");
	return V;
}

int InterVersion::check_readable(semantic_version_number file_version) {
	return VersionNumberRanges::in_range(
		InterVersion::current(),
		VersionNumberRanges::compatibility_range(file_version));
}

@ When Inter is stored in binary format, the version number is stored in three
consecutive unsigned integers in the file header: see //Inter in Binary Files//.

=
void InterVersion::to_three_words(unsigned int *w1, unsigned int *w2, unsigned int *w3) {
	semantic_version_number V = InterVersion::current();
	*w1 = (unsigned int) V.version_numbers[0];
	*w2 = (unsigned int) V.version_numbers[1];
	*w3 = (unsigned int) V.version_numbers[2];
}

semantic_version_number InterVersion::from_three_words(unsigned int w1, unsigned int w2,
	unsigned int w3) {
	TEMPORARY_TEXT(textual)
	WRITE_TO(textual, "%d.%d.%d", w1, w2, w3);
	semantic_version_number V = VersionNumbers::from_text(textual);
	DISCARD_TEXT(textual)
	return V;
}
