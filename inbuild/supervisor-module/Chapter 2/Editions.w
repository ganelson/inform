[Editions::] Editions.

An edition is a numbered version of a work.

@h Editions.
An "edition" of a work is a particular version numbered form of it. For
example, release 7 of Bronze by Emily Short would be an edition of the
work Bronze by Emily Short.

It is at this level that we record what works are compatible with which
target virtual machines, because we can imagine that, for example, version 7
might work with all VMs, while version 8 required a 32-bit architecture.

=
typedef struct inbuild_edition {
	struct inbuild_work *work;
	struct semantic_version_number version;
	struct compatibility_specification *compatibility;
	CLASS_DEFINITION
} inbuild_edition;

inbuild_edition *Editions::new(inbuild_work *work, semantic_version_number version) {
	inbuild_edition *edition = CREATE(inbuild_edition);
	edition->work = work;
	edition->version = version;
	edition->compatibility = Compatibility::all();
	return edition;
}

void Editions::write(OUTPUT_STREAM, inbuild_edition *E) {
	Works::write(OUT, E->work);
	semantic_version_number V = E->version;
	if (VersionNumbers::is_null(V) == FALSE) {
		WRITE(" v%v", &V);
	}
}

@ When a copy is to be duplicated into a nest |N|, we need to work out where
to put it. For example, version 2.1 of the extension Marbles by Steve Hogarth
would go into |N/Extensions/Steve Hogarth/Marbles-v2_1.i7x|. The following
contributes only the un-filename-extended leafname |Marbles-v2_1|.

=
int canonical_leaves_have_versions = TRUE;

void Editions::set_canonical_leaves_have_versions(int which) {
	canonical_leaves_have_versions = which;
}

void Editions::write_canonical_leaf(OUTPUT_STREAM, inbuild_edition *E) {
	WRITE("%S", E->work->title);
	if ((canonical_leaves_have_versions) &&
		(VersionNumbers::is_null(E->version) == FALSE)) {
		TEMPORARY_TEXT(vn)
		WRITE_TO(vn, "-v%v", &(E->version));
		LOOP_THROUGH_TEXT(pos, vn)
			if (Str::get(pos) == '.')
				PUT('_');
			else
				PUT(Str::get(pos));
		DISCARD_TEXT(vn)
	}
}

@ The |-inspect| command of Inbuild uses the following.

=
void Editions::inspect(OUTPUT_STREAM, inbuild_edition *E) {
	Editions::write(OUT, E);
	if (Compatibility::test_universal(E->compatibility) == FALSE) {
		WRITE(" (");
		Compatibility::write(OUT, E->compatibility);
		WRITE(")");
	}
}

@ For sorting search results:

=
int Editions::cmp(inbuild_edition *E1,  inbuild_edition *E2) {
	int r = Works::cmp(E1->work, E2->work);
	if (r == 0) r = VersionNumbers::cmp(E1->version, E2->version);
	return r;
}
