[IndexLocations::] Index Locations.

To provide routines to help build the various HTML index files,
none of which are actually created in this section.

@ This module exists to serve either //inform7// or //inter//, and it's not
up to us to decide where an index is put, so we ask nicely:

=
pathname *IndexLocations::path(void) {
	#ifdef PATH_INDEX_CALLBACK
	return PATH_INDEX_CALLBACK();
	#endif
	#ifndef PATH_INDEX_CALLBACK
	return NULL;
	#endif
}

@ An oddity in the Index folder is an XML file recording where the headings
are in the source text: this is for the benefit of the user interface
application, if it wants it, but is not linked to or used by the HTML of
the index as seen by the user.

=
filename *IndexLocations::xml_headings_filename(void) {
	return Filenames::in(IndexLocations::path(), I"Headings.xml");
}

@ And the following function determines the filename for a page in this
mini-website. Filenames down in the |Details| area have the form |N_S| where
|N| is an integer supplied and |S| the leafname; for instance, |21_A.html|
provides details page number 21 about actions, derived from the leafname |A.html|.

=
filename *IndexLocations::filename(text_stream *S, int N) {
	if (N >= 0) {
		TEMPORARY_TEXT(full_leafname)
		WRITE_TO(full_leafname, "%d_%S", N, S);
		filename *F = Filenames::in(IndexLocations::details_path(), full_leafname);
		DISCARD_TEXT(full_leafname)
		return F;
	} else {
		return Filenames::in(IndexLocations::path(), S);
	}
}

@ Within the Index is a deeper level, into the weeds as it were, called
|Details|.

=
pathname *IndexLocations::details_path(void) {
	pathname *P = Pathnames::down(IndexLocations::path(), I"Details");
	if (Pathnames::create_in_file_system(P)) return P;
	return NULL;
}
