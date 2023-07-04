[ExtensionWebsite::] The Mini-Website.

To refresh the mini-website of available extensions presented in the
Inform GUI applications.

@h The mini-website.
The Inform GUI apps present HTML in-app documentation on extensions: in
effect, a mini-website showing all the extensions available to the current
user, and giving detailed documentation on each one. The code in this
chapter of //supervisor// runs only if and when we want to generate or
update that website, and plays no part in Inform compilation or building
as such: it lives in //supervisor// because it's essentially concerned
with managing resources (i.e., extensions in nests).

A principle used throughout is that we fail safe and silent: if we can't
write the documentation website for any reason (permissions failures, for
example) then we make no complaint. It's a convenience for the user, but not
an essential. This point of view was encouraged by many Inform users working
clandestinely on thumb drives at their places of work, and whose employers
had locked their computers down fairly heavily.

@ The process always involves a "census" of all installed extensions, but
can happen for two different reasons:

(a) when we run in "census mode", because of |-census| at the command line;
(b) when //inform7// is indexing after a successful compilation.

Reason (a) typically happens because the user installs a new extension from
the app, and it calls the //inform7// tool in |-census| mode to force an
update of the documentation. But (a) can also happen from the command line
using either //inbuild// or //inform7//.

The second sort of census is lighter in effect because only incremental
changes to documentation are made, but the process of census-taking is the
same either way. Here are the functions for (a) and (b) respectively:

=
void ExtensionWebsite::handle_census_mode(void) {
	HTML::set_link_abbreviation_path(NULL);
	ExtensionWebsite::go(NULL, TRUE);
}

void ExtensionWebsite::index_after_compilation(inform_project *proj) {
	HTML::set_link_abbreviation_path(Projects::path(proj));
	ExtensionWebsite::go(proj, FALSE);
}

void ExtensionWebsite::go(inform_project *proj, int force_update) {
	ExtensionDictionary::read_from_file();

	ExtensionCensus::perform(proj);
	@<Time-stamp extensions used in the project as being last used today@>;
	@<Write index pages@>;
	@<Write individual pages on individual extensions@>;

	ExtensionDictionary::write_back();
}

@ This simply ensures that dates used are updated to today's date for
extensions used in the current run; otherwise they wouldn't show in the
documentation as used today until the next run, for obscure timing reasons.

@<Time-stamp extensions used in the project as being last used today@> =
	if (proj) {
		inform_extension *E;
		LOOP_OVER_LINKED_LIST(E, inform_extension, proj->extensions_included) {
			ExtensionDictionary::time_stamp(E);
			E->has_historically_been_used = TRUE;
		}
	}

@<Write index pages@> =
	ExtensionIndex::write(proj);

@ Each extension gets its own page in the external documentation area, but
this page can have two forms:
(i) a deluxe version, produced if a project |proj| has successfully used
the extension on this run and we therefore know a lot about the extension;
(ii) an ordinaire version, where we may never have used the extension and
currently have no specific knowledge of it.

@<Write individual pages on individual extensions@> =
	if (proj) {
		inform_extension *E;
		LOOP_OVER_LINKED_LIST(E, inform_extension, proj->extensions_included)
			ExtensionPages::write_page(NULL, E, FALSE, proj); /* deluxe */
	}
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum)
		ExtensionPages::write_page(ecd, NULL, force_update, NULL); /* ordinaire */

@h Organisation of the website.
There is a top level consisting of two home pages: a directory of all
installed extensions, and an index to the terms defined in those extensions. A
cross-link switches between them. Each of these links down to the bottom
level, where there is a page for every installed extension (wherever it is
installed). The picture is therefore something like this:
= (text)
         Extensions -- ExtIndex
             |      \/    |
             |      /\    |
    Nigel Toad/Eggs    Barnabas Dundritch/Neopolitan Iced Cream   ...
=
These pages would be stored in the transient area at the relative URLs:
= (text)
	Documentation/Extensions.html
	Documentation/ExtIndex.html
	Documentation/Extensions/Nigel Toad/Eggs.html
	Documentation/Extensions/Barnabas Dundritch/Neopolitan Iced Cream.html
=
And see also the function //ExtensionDictionary::filename//, which uses a file
in the same area but not as part of the site.

=
pathname *ExtensionWebsite::home_URL(inform_project *proj) {
	if (proj == NULL) {
		pathname *P = Supervisor::transient();
		if (P == NULL) return NULL;
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		P = Pathnames::down(P, I"Documentation");
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		return P;
	} else {
		pathname *P = Projects::materials_path(proj);
		if (P == NULL) return NULL;
		P = Pathnames::down(P, I"Extensions");
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		P = Pathnames::down(P, I"Reserved");
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		P = Pathnames::down(P, I"Documentation");
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		return P;
	}
}

@ The top-level files |Extensions.html| and |ExtIndex.html| go here:

=
filename *ExtensionWebsite::index_URL(inform_project *proj, text_stream *leaf) {
	pathname *P = ExtensionWebsite::home_URL(proj);
	if (P == NULL) return NULL;
	return Filenames::in(P, leaf);
}

@ And individual extension pages here. A complication is that a single
extension may also have sidekick pages for any examples in its supplied
documentation: so for instance we might actually see --
= (text)
	Documentation/Extensions/Emily Short/Locksmith.html
	Documentation/Extensions/Emily Short/Locksmith-eg1.html
	Documentation/Extensions/Emily Short/Locksmith-eg2.html
	Documentation/Extensions/Emily Short/Locksmith-eg3.html
	Documentation/Extensions/Emily Short/Locksmith-eg4.html
=
The following supplies the necessary filenames.

=
filename *ExtensionWebsite::page_URL(inform_project *proj, inbuild_edition *edition, int eg_number) {
	TEMPORARY_TEXT(leaf)
	Editions::write_canonical_leaf(leaf, edition);
	
	pathname *P;
	if (proj) {
		P = Projects::materials_path(proj);
		if (P == NULL) return NULL;
		P = Pathnames::down(P, I"Extensions");
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		P = Pathnames::down(P, I"Reserved");
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		P = Pathnames::down(P, I"Documentation");
	} else {
		P = ExtensionWebsite::home_URL(NULL);
		if (P == NULL) return NULL;
		P = Pathnames::down(P, I"Extensions");
	}
	if (Pathnames::create_in_file_system(P) == 0) return NULL;
	P = Pathnames::down(P, edition->work->author_name);
	if (Pathnames::create_in_file_system(P) == 0) return NULL;

	if (proj) {
		P = Pathnames::down(P, leaf);
		if (Pathnames::create_in_file_system(P) == 0) return NULL;
		Str::clear(leaf);
		if (eg_number > 0) WRITE_TO(leaf, "eg%d.html", eg_number);
		else WRITE_TO(leaf, "index.html");
	} else {
		if (eg_number > 0) WRITE_TO(leaf, "-eg%d", eg_number);
		WRITE_TO(leaf, ".html");
	}

	filename *F = Filenames::in(P, leaf);
	DISCARD_TEXT(leaf)
	return F;
}
