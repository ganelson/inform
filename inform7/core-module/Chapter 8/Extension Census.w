[Extensions::Census::] Extension Census.

To conduct a census of all the extensions installed (whether used
on this run or not), and keep the documentation index for them up to date.

@h Definitions.

@ In addition to the extensions read in, there are the roads not taken: the
ones which I7 has at its disposal, but which the source text never asks to
include. Inform performs a "census" of installed extensions on every run,
essentially by scanning the directories which hold them to see what the
user has installed there.

Each extension discovered will produce a single "extension census datum",
or ECD.

=
typedef struct extension_census_datum {
	struct extension_identifier ecd_id; /* title, author, hash code */
	struct text_stream *version_text; /* such as |23| or |14/060527| */
	struct text_stream *VM_requirement; /* such as "(for Z-machine only)" */
	int built_in; /* found in the Inform 7 application's private stock */
	int project_specific; /* found in the Materials folder for the current project */
	int overriding_a_built_in_extension; /* not built in, but overriding one which is */
	pathname *domain; /* pathname of the stock in which this was found */
	struct text_stream *rubric; /* brief description found in opening lines */
	struct extension_census_datum *next; /* next one in lexicographic order */
	MEMORY_MANAGEMENT
} extension_census_datum;

@ This is a narrative section and describes the story of the census. Just as
Caesar Augustus decreed that all the world should be taxed, and that each
should return to his place of birth, so we will open and inspect every
extension we can find, checking that each is in the right place.

Note that if the same extension is found in more than one domain, the first
to be found is considered the definitive version: this is why the external
area is searched first, so that the user can override built-in extensions
by placing his own versions in the external area. (Should this convention
ever be reversed, a matching change would need to be made in the code which
opens extension files in Read Source Text.)

=
void Extensions::Census::perform(void) {
	Extensions::Census::begin_recording_census_errors();
	for (int area=0; area<NO_FS_AREAS; area++)
		Extensions::Census::take_census_of_domain(pathname_of_extensions[area], area+1);
	Extensions::Census::end_recording_census_errors();
}

@h Conducting the census.
An "extension domain", for these purposes, is a directory in the filing
system which can contain extensions (providing these are themselves placed
in subdirectories identifying their authorship). The built-in domain is
special (it is read-only, for one thing), but in principle we could have
any number of other domains. The following code scans one.

=
pathname *current_extension_domain = NULL;
void Extensions::Census::take_census_of_domain(pathname *P, int origin) {
	current_extension_domain = P;
	Extensions::Census::census_from(P, TRUE, origin, NULL);
}

@ The following routine is not as recursive as it looks, since it runs at
only two levels: a top level, when it is scanning the domain, and an inner
level, when it is scanning the subfolder of the domain for a given author.

The reader may wince at the way we scan a directory -- we essentially dump
a catalogue listing to a temporary text file and then read it back in,
one line at a time -- but it works properly on all platforms, which is
important given how poorly directory handling is standardised in C.

Because of the two-level recursion, there are two such temporary files,
|Temporary1.txt| at the upper level and |Temporary0.txt| below. These are
stored in the external Extensions area. In principle that could be
problematic since two processes running Inform on the same machine may be
simultaneously taking an extension census, so could lock each other out:
probably we ought to include a process ID in the filenames. But then we
would have further platform hassles, and we would need to delete the files
when done, and worry about what happens if Inform is aborted half-way.
(When |intest| does large multiprocessing test runs of Inform, indexing
is turned off, so extension censuses are not being taken.)

=
typedef struct census_state {
	struct pathname *P;
	int top_level;
	int origin;
	text_stream *parent;
} census_state;

void Extensions::Census::census_from(pathname *P, int top_level, int origin, text_stream *parent) {
	scan_directory *dir = Directories::open(P);
	if (dir) {
		census_state cs;
		cs.P = P; cs.top_level = top_level; cs.origin = origin; cs.parent = parent;
		TEMPORARY_TEXT(item_name);
		int count = 0;
		while (Directories::next(dir, item_name))
			Extensions::Census::census_from_helper(item_name, &cs, ++count);
		DISCARD_TEXT(item_name);
		Directories::close(dir);
	}
}

void Extensions::Census::census_from_helper(text_stream *item_name, census_state *cs,
	int count) {
	if (Str::len(item_name) == 0) return;
	LOGIF(EXTENSIONS_CENSUS, "%d: %S\n", count, item_name);
	if (cs->top_level) @<Take census from a possible author folder@>
	else @<Take census from a possible extension@>;
}

@ At the upper level, we expect every item to be a subfolder whose name is that
of a given author. We can identify folder names because of the terminating
slash |/|: note that this character is used regardless of whether or not it
is the platform's file separator, and that it is illegal in extension titles
or author names.

It is a "census error" -- meaning, we have detected a misinstallation of
extensions -- if any file is present, or any folder too long for its name to
be an author name, except that items with names beginning with a |.| are
ignored. (In particular, the folders |./| and |../| are ignored, but so too
are OS X Finder files like |.DS_Store|, and other such junk. No author name
or title is allowed to contain a |.| character, so this cannot throw away
valid census entries.)

Once we have a valid, non-reserved author subfolder, we recurse down to lower
level to scan it.

@<Take census from a possible author folder@> =
	if (Str::get_first_char(item_name) == '.') return;
	if (Str::get_last_char(item_name) == FOLDER_SEPARATOR) {
		Str::delete_last_character(item_name); /* remove the terminal slash: it has served its purpose */

		if (Str::eq(item_name, I"Reserved")) return;

		if (Str::len(item_name) > MAX_EXTENSION_TITLE_LENGTH-1) {
			Extensions::Census::census_error("author name exceeds the maximum permitted length",
				item_name, NULL, NULL, NULL); return;
		}
		if (Str::includes_character(item_name, '.')) {
			Extensions::Census::census_error("author name contains a full stop",
				item_name, NULL, NULL, NULL); return;
		}
		Extensions::Census::census_from(
			Pathnames::subfolder(cs->P, item_name),
			FALSE, cs->origin, item_name);
		return;
	}
	Extensions::Census::census_error("non-folder found where author folders should be",
		item_name, NULL, NULL, NULL); return;

@ At the lower level, |.| files or folders are again skipped; any other
folders are a census error, since there should only be extension files
present; and once again, we enforce the title length restriction.

As will be seen from the logic below, an extension is only given a census
entry (and therefore included in the HTML documentation of installed
extensions) if no census errors arise from it. An Inform user can therefore
know that if an extension shows up on his documentation page, it is properly
installed and identifies itself correctly, and moreover that it can be
installed correctly on other Informs elsewhere (perhaps on other platforms).

@d MAX_TITLING_LINE_LENGTH 501 /* lots, allowing for an improbably large number of virtual machine restrictions */

@<Take census from a possible extension@> =
	int overridden_by_an_extension_already_found = FALSE;
	TEMPORARY_TEXT(candidate_title);
	TEMPORARY_TEXT(raw_title);
	TEMPORARY_TEXT(candidate_author_name);
	TEMPORARY_TEXT(raw_author_name);
	TEMPORARY_TEXT(titling_line);
	TEMPORARY_TEXT(rubric_text);
	TEMPORARY_TEXT(version_text);
	TEMPORARY_TEXT(requirement_text);
	TEMPORARY_TEXT(claimed_author_name);
	TEMPORARY_TEXT(claimed_title);
	if (Str::get_last_char(item_name) == '.') return;
	if (Str::get_last_char(item_name) == FOLDER_SEPARATOR) {
		Extensions::Census::census_error("folder or application in author folder",
			cs->parent, item_name, NULL, NULL); return;
	}
	if (Str::len(item_name) > MAX_EXTENSION_TITLE_LENGTH-1) {
		Extensions::Census::census_error("title exceeds the maximum permitted length",
			cs->parent, item_name, NULL, NULL); return;
	}

	@<Make candidate title and author name from normalised casing versions of filename and parent folder name@>;
	@<Extract the titling line and rubric, if any, from the extension file@>;
	@<Parse the version, title, author and VM requirements from the titling line@>;
	@<Check that the candidate name and title match those claimed in the titling line@>;
	@<See if we duplicate the title and author name of an extension already found in another domain@>;
	if (overridden_by_an_extension_already_found == FALSE) {
		extension_census_datum *ecd;
		@<Create a new census datum for this extension, which has passed all tests@>;
	}
	DISCARD_TEXT(candidate_title);
	DISCARD_TEXT(raw_title);
	DISCARD_TEXT(candidate_author_name);
	DISCARD_TEXT(raw_author_name);
	DISCARD_TEXT(titling_line);
	DISCARD_TEXT(rubric_text);
	DISCARD_TEXT(version_text);
	DISCARD_TEXT(requirement_text);
	DISCARD_TEXT(claimed_author_name);
	DISCARD_TEXT(claimed_title);

@ If we find an extension at the relative pathname |Emily Short/Locksmith| then
we expect it to be Locksmith by Emily Short: these are the candidate author name
and title respectively. (What the file actually contains is another matter, as
we shall see.)

All titles and author names have to be stored carefully in case-normalised
form at all times, and this extends to the filename and folder name. Enforcing
this rule may seem needlessly bureaucratic, since for the majority of users
(using typical Mac OS X and Windows installations) the filing system preserves
the case of filenames but is not sensitive to case when searching for files:
thus the folders |jimmy stewart| and |Jimmy Stewart| behave identically in
practice. But we want to use |strcmp| for case-sensitive comparisons, for
instance.

There are active Inform users who do have a case-sensitive filing system
(on some of the Linux and Solaris ports), and we want extension files to
continue to work perfectly if taken from one Inform installation and added
to another. So the previously strict rules on casing of the filenames as
stored have been waived.

@<Make candidate title and author name from normalised casing versions of filename and parent folder name@> =
	Str::copy(candidate_author_name, cs->parent);
	Str::copy(candidate_title, item_name);
	@<Remove filename extension for extensions, if any@>;
	Str::copy(raw_title, candidate_title);
	Str::copy(raw_author_name, candidate_author_name);
	Extensions::IDs::normalise_casing(candidate_author_name);
	Extensions::IDs::normalise_casing(candidate_title);

	if (Str::includes_character(candidate_title, '.')) {
		LOG("Title is <%S>\n", candidate_title);
		Extensions::Census::census_error("title contains a full stop",
			cs->parent, candidate_title, NULL, NULL); return;
	}

@ We permit (encourage, actually) the filename extension ".i7x" for extensions,
in any of its possible casings, and that of course isn't part of the title:

@<Remove filename extension for extensions, if any@> =
	if (Str::ends_with_wide_string(candidate_title, L".i7x"))
		Str::truncate(candidate_title, Str::len(candidate_title) - 4);

@h Handling the extension file.
This and the next three paragraphs do the file-handling necessary to open the extension,
extract its titling line and rubric, then close it again.

@<Extract the titling line and rubric, if any, from the extension file@> =
	FILE *EXTF;
	@<Open the extension file for reading@>;
	@<Read the titling line of the extension and normalise its casing@>;
	@<Read the rubric text, if any is present@>;
	fclose(EXTF);

@ The following should only fail in the event of some peculiar filing system
failure (or of some other process having moved or deleted the file since
we scanned the folder only moments ago).

@<Open the extension file for reading@> =
	filename *F =
		Locations::of_extension(current_extension_domain,
			item_name, cs->parent, FALSE);
	EXTF = Filenames::fopen_caseless(F, "r");
	if (EXTF == NULL) {
		Extensions::Census::census_error("file cannot be read",
			cs->parent, item_name, NULL, NULL); return;
	}

@ The actual maximum number of characters in the titling line is one less
than |MAX_TITLING_LINE_LENGTH|, to allow for the null terminator. The titling
line is terminated by any of |0A|, |0D|, |0A 0D| or |0D 0A|, or by the local
|\n| for good measure.

@<Read the titling line of the extension and normalise its casing@> =
	int titling_chars_read = 0, c;
	while ((c = TextFiles::utf8_fgetc(EXTF, NULL, FALSE, NULL)) != EOF) {
		if (c == 0xFEFF) return; /* skip the optional Unicode BOM pseudo-character */
		if ((c == '\x0a') || (c == '\x0d') || (c == '\n')) break;
		if (titling_chars_read < MAX_TITLING_LINE_LENGTH - 1) PUT_TO(titling_line, c);
	}
	Extensions::IDs::normalise_casing(titling_line);

@ In the following, all possible newlines are converted to white space, and
all white space before a quoted rubric text is ignored. We need to do this
partly because users have probably keyed a double line break before the
rubric, but also because we might have stopped reading the titling line
halfway through a line division combination like |0A 0D|, so that the first
thing we read here is a meaningless |0D|.

@<Read the rubric text, if any is present@> =
	int c, found_start = FALSE;
	while ((c = TextFiles::utf8_fgetc(EXTF, NULL, FALSE, NULL)) != EOF) {
		if ((c == '\x0a') || (c == '\x0d') || (c == '\n') || (c == '\t')) c = ' ';
		if ((c != ' ') && (found_start == FALSE)) {
			if (c == '"') found_start = TRUE;
			else break;
		} else {
			if (c == '"') break;
			if (found_start) PUT_TO(rubric_text, c);
		}
	}

@h Parsing the titling line.
In general, once case-normalised, a titling line looks like this:

>> Version 2/070423 Of Going To The Zoo (For Glulx Only) By Cary Grant Begins Here.

and the version information, the VM restriction and the full stop are all
optional, but the division word "of" and the concluding "begin[s] here"
are not. We break it up into pieces, so that

	|version_text = "2/070423"|
	|claimed_title = "Going To The Zoo"|
	|claimed_author_name = "Cary Grant"|
	|requirement_text = "(For Glulx Only)"|

It's tempting to do this by feeding it into the lexer and then reusing some
of the code which parses these lines during sentence-breaking, but in fact
we want to use the information rather differently, and besides: it seems
useful to record some C code here which correctly parses a titling line,
since this can easily be extracted and used in other utilities handling
Inform extensions.

@<Parse the version, title, author and VM requirements from the titling line@> =
	match_results mr = Regexp::create_mr();
	if (Str::get_last_char(titling_line) == '.') Str::delete_last_character(titling_line);
	if ((Regexp::match(&mr, titling_line, L"(%c*) Begin Here")) ||
		(Regexp::match(&mr, titling_line, L"(%c*) Begins Here"))) {
		Str::copy(titling_line, mr.exp[0]);
	} else {
		LOG("Titling: %S\n", titling_line);
		Extensions::Census::census_error("appears not to be an extension (its first line does "
			"not end 'begin(s) here', as extension titling lines must)",
			cs->parent, item_name, NULL, NULL); return;
	}

	@<Scan the version text, if any, and advance to the position past Version... Of@>;
	if (Regexp::match(&mr, titling_line, L"The (%c*)")) Str::copy(titling_line, mr.exp[0]);
	@<Divide the remaining text into a claimed author name and title, divided by By@>;
	@<Extract the VM requirements text, if any, from the claimed title@>;
	Regexp::dispose_of(&mr);

@ We make no attempt to check the version number for validity: the purpose
of the census is to identify extensions and reject accidentally included
other files, not to syntax-check all extensions to see if they would work
if used.

@<Scan the version text, if any, and advance to the position past Version... Of@> =
	if (Regexp::match(&mr, titling_line, L"Version (%c*?) Of (%c*)")) {
		Str::copy(version_text, mr.exp[0]);
		Str::copy(titling_line, mr.exp[1]);
	}

@ The earliest "by" is the divider: note that extension titles are not
allowed to contain this word, so "North By Northwest By Cary Grant" is
not a situation we need to contend with.

@<Divide the remaining text into a claimed author name and title, divided by By@> =
	if (Regexp::match(&mr, titling_line, L"(%c*?) By (%c*)")) {
		Str::copy(claimed_title, mr.exp[0]);
		Str::copy(claimed_author_name, mr.exp[1]);
	} else {
		Extensions::Census::census_error("appears not to be an extension (the titling line does "
			"not give both author and title)",
			cs->parent, item_name, NULL, NULL); return;
	}

@ Similarly, extension titles are not allowed to contain parentheses, so
this is unambiguous.

@<Extract the VM requirements text, if any, from the claimed title@> =
	if (Regexp::match(&mr, claimed_title, L"(%c*?) *(%(%c*%))")) {
		Str::copy(claimed_title, mr.exp[0]);
		Str::copy(requirement_text, mr.exp[1]);
	}

@h Making sure this is the extension we expected to find.
It's easier for these confusions to arise than might be thought. For instance,
if two different authors independently write extensions called "Followers",
it would be easy to put a file of this name in the wrong author folder by
mistake. Since extension installation is usually handled mechanically (and,
we hope, correctly) by the Inform application, such problems are only likely
to arise when users install extensions by hand. Still, it's prudent to check.

@<Check that the candidate name and title match those claimed in the titling line@> =
	int right_leafname = FALSE, right_folder = FALSE;
	if (Str::eq(claimed_title, candidate_title)) right_leafname = TRUE;
	if (Str::eq(claimed_author_name, candidate_author_name)) right_folder = TRUE;

	if ((right_leafname == TRUE) && (right_folder == FALSE)) {
		Extensions::Census::census_error("an extension with the right filename but in the wrong "
			"author's folder",
			cs->parent, item_name, claimed_author_name, claimed_title); return;
	}
	if ((right_leafname == FALSE) && (right_folder == TRUE)) {
		Extensions::Census::census_error("an extension stored in the correct author's folder, but "
			"with the wrong filename",
			cs->parent, item_name, claimed_author_name, claimed_title); return;
	}
	if ((right_leafname == FALSE) && (right_folder == FALSE)) {
		Extensions::Census::census_error("an extension but with the wrong filename and put in the "
			"wrong author's folder",
			cs->parent, item_name, claimed_author_name, claimed_title); return;
	}

@h Adding the extension to the census, or not.
Recall that the higher-priority external domain is scanned first; the
built-in domain is scanned second. So if we find that our new extension has
the same title and author as one already known, it must be the case that we
are now scanning the built-in area and that the previous one was an extension
which the user had installed to override this built-in extension.

@<See if we duplicate the title and author name of an extension already found in another domain@> =
	extension_census_datum *other;
	LOOP_OVER(other, extension_census_datum)
		if ((Str::eq(candidate_author_name, other->ecd_id.author_name))
			&& (Str::eq(candidate_title, other->ecd_id.title))
			&& ((other->built_in) || (cs->origin == ORIGIN_WAS_BUILT_IN_EXTENSIONS_AREA))) {
			other->overriding_a_built_in_extension = TRUE;
			overridden_by_an_extension_already_found = TRUE;
		}

@ Assuming the new extension was not overridden in this way, we come here.
Because we didn't check the version number text for validity, it might
through being invalid be longer than we expect: in case this is so, we
truncate it.

@<Create a new census datum for this extension, which has passed all tests@> =
	ecd = CREATE(extension_census_datum);
	Extensions::IDs::new(&(ecd->ecd_id), candidate_author_name, candidate_title, INSTALLED_EIDBC);
	Extensions::IDs::set_raw(&(ecd->ecd_id), raw_author_name, raw_title);
	ecd->VM_requirement = Str::duplicate(requirement_text);
	if (Str::len(version_text) > MAX_VERSION_NUMBER_LENGTH)
		Str::truncate(version_text, MAX_VERSION_NUMBER_LENGTH); /* truncate to maximum legal length */
	ecd->version_text = Str::duplicate(version_text);
	ecd->domain = current_extension_domain;
	ecd->built_in = FALSE;
	if (cs->origin == ORIGIN_WAS_BUILT_IN_EXTENSIONS_AREA) ecd->built_in = TRUE;
	ecd->project_specific = FALSE;
	if (cs->origin == ORIGIN_WAS_MATERIALS_EXTENSIONS_AREA) ecd->project_specific = TRUE;
	ecd->overriding_a_built_in_extension = FALSE;
	ecd->next = NULL;
	ecd->rubric = Str::duplicate(rubric_text);

@h Census errors.
To recap, the extension census process involves looking for all the
extensions Inform can find, but also checking them: are the files genuine, that
is, do they appear to be suitable text files with the correct identifying
first lines? Or have binary files crept in, or genuine extension but which
have been given the wrong location or filename? When any of these checks
fails, a census error is generated: there are about a dozen different
kinds.

These are dumped to a text stream during the census process. Once again, this
is not thread-safe: two simultaneous attempts by different Inform processes
to take a census might collide.

=
int no_census_errors = 0, recording_census_errors = FALSE;
text_stream *CENERR = NULL;

void Extensions::Census::begin_recording_census_errors(void) {
	no_census_errors = 0; recording_census_errors = TRUE;
	CENERR = Str::new();
}

int Extensions::Census::currently_recording_errors(void) {
	return recording_census_errors;
}

void Extensions::Census::end_recording_census_errors(void) {
	recording_census_errors = FALSE;
}

@ When a census error arises, then, we write it as a line to the errors stream.

=
void Extensions::Census::census_error(char *message, text_stream *auth, text_stream *title,
	text_stream *claimed_author, text_stream *claimed_title) {
	text_stream *OUT = CENERR;
	no_census_errors++;
	HTMLFiles::open_para(OUT, 2, "hanging");
	if (Str::len(claimed_author) > 0)
		WRITE("<b>%S by %S</b> - %s (the extension says it is '%S by %S')",
			title, auth, message, claimed_title, claimed_author);
	else if ((Str::len(auth) > 0) && (Str::len(title) > 0))
		WRITE("<b>%S by %S</b> - %s", title, auth, message);
	else
		WRITE("<b>%S</b> - %s", auth, message);
	HTML_CLOSE("p");
}

@ And this is where the inclusion of that material into the catalogue is
taken care of. First, we sometimes position a warning prominently at the
top of the listing, because otherwise its position at the bottom will be
invisible unless the user scrolls a long way:

=
void Extensions::Census::warn_about_census_errors(OUTPUT_STREAM) {
	if (no_census_errors == 0) return; /* no need for a warning */
	if (NUMBER_CREATED(extension_census_datum) < 20) return; /* it's a short page anyway */
	HTML_OPEN("p");
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/misinstalled.png");
	WRITE("&nbsp;"
		"<b>Warning</b>. One or more extensions are installed incorrectly: "
		"see details below.");
 	HTML_CLOSE("p");
 }

@ =
void Extensions::Census::transcribe_census_errors(OUTPUT_STREAM) {
	if (no_census_errors == 0) return; /* nothing to include, then */
	@<Include the headnote explaining what census errors are@>;
	WRITE("%S\n", CENERR);
}

@ We only want to warn people here: not to stop them from using Inform
until they put matters right. (Suppose, for instance, they are using an
account not giving them sufficient privileges to modify files in the external
extensions area: they'd then be locked out if anything was amiss there.)

@<Include the headnote explaining what census errors are@> =
	HTML_TAG("hr");
	HTML_OPEN("p");
	HTML_TAG_WITH("img", "border=0 align=\"left\" src=inform:/doc_images/census_problem.png");
	WRITE("<b>Warning</b>. Inform checks the folder of user-installed extensions "
		"each time it translates the source text, in order to keep this directory "
		"page up to date. Each file must be a properly labelled extension (with "
		"its titling line correctly identifying itself), and must be in the right "
		"place - e.g. 'Marbles by Daphne Quilt' must have the filename 'Marbles.i7x' "
		"(or just 'Marbles' with no file extension) and be stored in the folder "
		"'Daphne Quilt'. The title should be at most %d characters long; the "
		"author name, %d. At the last check, these rules were not being followed:",
			MAX_EXTENSION_TITLE_LENGTH, MAX_EXTENSION_AUTHOR_LENGTH);
	HTML_CLOSE("p");

@ Here we write the copy for the directory page of the extensions
documentation: the one which the user currently sees by clicking on the
"Installed Extensions" link from the contents page of the documentation.
It contains an alphabetised catalogue of extensions by author and then
title, along with some useful information about them, and then a list of
any oddities found in the external extensions area.

@d CE_BY_TITLE 1
@d CE_BY_AUTHOR 2
@d CE_BY_INSTALL 3
@d CE_BY_DATE 4
@d CE_BY_LENGTH 5

=
void Extensions::Census::write_results(OUTPUT_STREAM) {
	@<Display the location of installed extensions@>;
	Extensions::Census::warn_about_census_errors(OUT);
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_TAG("hr");
	@<Time stamp the extensions used on this run@>;

	int key_vms = FALSE, key_override = FALSE, key_builtin = FALSE,
		key_pspec = FALSE, key_bullet = FALSE;

	@<Display the census radio buttons@>;

	int no_entries = NUMBER_CREATED(extension_census_datum);
	extension_census_datum **sorted_census_results = Memory::I7_calloc(no_entries,
		sizeof(extension_census_datum *), EXTENSION_DICTIONARY_MREASON);

	int d;
	for (d=1; d<=5; d++) {
		@<Start an HTML division for this sorted version of the census@>;
		@<Sort the census into the appropriate order@>;
		@<Display the sorted version of the census@>;
		HTML_CLOSE("div");
	}
	@<Print the key to any symbols used in the census lines@>;
	Extensions::Census::transcribe_census_errors(OUT);
	Memory::I7_array_free(sorted_census_results, EXTENSION_DICTIONARY_MREASON,
		no_entries, sizeof(extension_census_datum *));
}

@<Display the location of installed extensions@> =
	int nps = 0, nbi = 0, ni = 0;
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum) {
		if (ecd->project_specific) nps++;
		else if (ecd->built_in) nbi++;
		else ni++;
	}

	HTML_OPEN("p");
	HTML_TAG_WITH("img", "src='inform:/doc_images/builtin_ext.png' border=0");
	WRITE("&nbsp;You have "
		"%d extensions built-in to this copy of Inform, marked with a grey folder "
		"icon in the catalogue below.",
		nbi);
	HTML_CLOSE("p");
	HTML_OPEN("p");
	if (ni == 0) {
		HTML_TAG_WITH("img", "src='inform:/doc_images/folder4.png' border=0");
		WRITE("&nbsp;You have no other extensions installed at present.");
	} else {
		HTML::Javascript::open_file(OUT, pathname_of_extensions[EXTERNAL_FS_AREA], NULL,
			"src='inform:/doc_images/folder4.png' border=0");
		WRITE("&nbsp;You have %d further extension%s installed. These are marked "
			"with a blue folder icon in the catalogue below. (Click it to see "
			"where the file is stored on your computer.) "
			"For more extensions, visit <b>www.inform7.com</b>.",
			ni, (ni==1)?"":"s");
	}
	HTML_CLOSE("p");
	if (nps > 0) {
		HTML_OPEN("p");
		HTML::Javascript::open_file(OUT, pathname_of_extensions[INTERNAL_FS_AREA], NULL, PROJECT_SPECIFIC_SYMBOL);
		WRITE("&nbsp;You have %d extension%s in the .materials folder for the "
			"current project. (Click the purple folder icon to show the "
			"location.) %s not available to other projects.",
			nps, (nps==1)?"":"s", (nps==1)?"This is":"These are");
		HTML_CLOSE("p");
	}

@ This simply ensures that dates used are updated to today's date for
extensions used in the current run; otherwise they wouldn't show in the
documentation as used today until the next run, for obscure timing reasons.

@<Time stamp the extensions used on this run@> =
	extension_file *ef;
	LOOP_OVER(ef, extension_file)
		Extensions::Dictionary::time_stamp(ef);

@ I am the first to admit that this implementation is not inspired. There
are five radio buttons, and number 2 is selected by default.

@<Display the census radio buttons@> =
	HTML_OPEN("p");
	WRITE("Sort catalogue: ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"openExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus1\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By title");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); openExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus2\" src=inform:/doc_images/extrarbon.png");
	WRITE("&nbsp;By author");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"openExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus3\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By installation");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); openExtra('disp4', 'plus4'); "
		"closeExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus4\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By date used");
	HTML_CLOSE("a");
	WRITE(" | ");
	HTML_OPEN_WITH("a",
		"href=\"#\" style=\"text-decoration: none\" "
		"onclick=\"closeExtra('disp1', 'plus1'); closeExtra('disp2', 'plus2'); "
		"closeExtra('disp3', 'plus3'); closeExtra('disp4', 'plus4'); "
		"openExtra('disp5', 'plus5'); return false;\"");
	HTML_TAG_WITH("img", "border=0 id=\"plus5\" src=inform:/doc_images/extrarboff.png");
	WRITE("&nbsp;By word count");
	HTML_CLOSE("a");
	HTML_CLOSE("p");

@ Consequently, of the five divisions, number 2 is shown and the others
hidden, by default.

@<Start an HTML division for this sorted version of the census@> =
	char *display = "none";
	if (d == CE_BY_AUTHOR) display = "block";
	HTML_OPEN_WITH("div", "id=\"disp%d\" style=\"display: %s;\"", d, display);

@ The key at the foot only explicates those symbols actually used, and
doesn't explicate the "unindexed" symbol at all, since that's actually
just a blank image used for horizontal spacing to keep margins straight.

@<Print the key to any symbols used in the census lines@> =
	if ((key_builtin) || (key_override) || (key_bullet) || (key_vms) || (key_pspec)) {
		HTML_OPEN("p");
		WRITE("Key: ");
		if (key_bullet) {
			HTML_TAG_WITH("img", "%s", INDEXED_SYMBOL);
			WRITE(" Used&nbsp;");
		}
		if (key_builtin) {
			HTML_TAG_WITH("img", "%s", BUILT_IN_SYMBOL);
			WRITE(" Built in&nbsp;");
		}
		if (key_pspec) {
			HTML_TAG_WITH("img", "%s", PROJECT_SPECIFIC_SYMBOL);
			WRITE(" Project specific&nbsp;");
		}
		if (key_override) {
			HTML_TAG_WITH("img", "%s", OVERRIDING_SYMBOL);
			WRITE(" Your version overrides the one built in&nbsp;");
		}
		if (key_vms) {
			HTML_TAG("br");
			VirtualMachines::write_key(OUT);
		}
		HTML_CLOSE("p");
	}

@<Sort the census into the appropriate order@> =
	int i = 0;
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum)
		sorted_census_results[i++] = ecd;
	int (*criterion)(const void *, const void *) = NULL;
	switch (d) {
		case CE_BY_TITLE: criterion = Extensions::Census::compare_ecd_by_title; break;
		case CE_BY_AUTHOR: criterion = Extensions::Census::compare_ecd_by_author; break;
		case CE_BY_INSTALL: criterion = Extensions::Census::compare_ecd_by_installation; break;
		case CE_BY_DATE: criterion = Extensions::Census::compare_ecd_by_date; break;
		case CE_BY_LENGTH: criterion = Extensions::Census::compare_ecd_by_length; break;
		default: internal_error("no such sorting criterion");
	}
	qsort(sorted_census_results, (size_t) no_entries, sizeof(extension_census_datum *),
		criterion);

@ Standard rows have black text on striped background colours, these being
the usual ones seen in Mac OS X applications such as iTunes.

@d FIRST_STRIPE_COLOUR "#ffffff"
@d SECOND_STRIPE_COLOUR "#f3f6fa"

@<Display the sorted version of the census@> =
	HTML::begin_html_table(OUT, FIRST_STRIPE_COLOUR, TRUE, 0, 0, 2, 0, 0);
	@<Show a titling row explaining the census sorting, if necessary@>;
	int stripe = 0;
	TEMPORARY_TEXT(current_author_name);
	int i, current_installation = -1;
	for (i=0; i<no_entries; i++) {
		extension_census_datum *ecd = sorted_census_results[i];
		@<Insert a subtitling row in the census sorting, if necessary@>;
		stripe = 1 - stripe;
		if (stripe == 0)
			HTML::first_html_column_coloured(OUT, 0, SECOND_STRIPE_COLOUR, 0);
		else
			HTML::first_html_column_coloured(OUT, 0, FIRST_STRIPE_COLOUR, 0);
		@<Print the census line for this extension@>;
		HTML::end_html_row(OUT);
	}
	DISCARD_TEXT(current_author_name);
	@<Show a final titling row closing the census sorting@>;
	HTML::end_html_table(OUT);

@<Show a titling row explaining the census sorting, if necessary@> =
	switch (d) {
		case CE_BY_TITLE:
			@<Begin a tinted census line@>;
			WRITE("Extensions in alphabetical order");
			@<End a tinted census line@>;
			break;
		case CE_BY_DATE:
			@<Begin a tinted census line@>;
			WRITE("Extensions in order of date used (most recent first)");
			@<End a tinted census line@>;
			break;
		case CE_BY_LENGTH:
			@<Begin a tinted census line@>;
			WRITE("Extensions in order of word count (longest first)");
			@<End a tinted census line@>;
			break;
	}

@<Insert a subtitling row in the census sorting, if necessary@> =
	if ((d == CE_BY_AUTHOR) &&
		(Str::ne(current_author_name, ecd->ecd_id.author_name))) {
		Str::copy(current_author_name, ecd->ecd_id.author_name);
		@<Begin a tinted census line@>;
		@<Print the author's line in the extension census table@>;
		@<End a tinted census line@>;
		stripe = 0;
	}
	if ((d == CE_BY_INSTALL) && (Extensions::Census::installation_region(ecd) != current_installation)) {
		current_installation = Extensions::Census::installation_region(ecd);
		@<Begin a tinted census line@>;
		@<Print the installation region in the extension census table@>;
		@<End a tinted census line@>;
		stripe = 0;
	}

@<Show a final titling row closing the census sorting@> =
	@<Begin a tinted census line@>;
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	WRITE("%d extensions installed", no_entries);
	HTML_CLOSE("span");
	@<End a tinted census line@>;

@ Black text on a grey background.

@d CENSUS_TITLING_BG "#808080"

@<Begin a tinted census line@> =
	int span = 4;
	if (d == CE_BY_TITLE) span = 3;
	HTML::first_html_column_coloured(OUT, 0, CENSUS_TITLING_BG, span);
	HTML::begin_colour(OUT, I"ffffff");
	WRITE("&nbsp;");

@<End a tinted census line@> =
	HTML::end_colour(OUT);
	HTML::end_html_row(OUT);

@ Used only in "by author".

@<Print the author's line in the extension census table@> =
	WRITE("%S", ecd->ecd_id.raw_author_name);

	extension_census_datum *ecd2;
	int cu = 0, cn = 0, j;
	for (j = i; j < no_entries; j++) {
		ecd2 = sorted_census_results[j];
		if (Str::ne(current_author_name, ecd2->ecd_id.author_name)) break;
		if (Extensions::Census::ecd_used(ecd2)) cu++;
		else cn++;
	}
	WRITE("&nbsp;&nbsp;");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	WRITE("%d extension%s", cu+cn, (cu+cn==1)?"":"s");
	if ((cu == 0) && (cn == 1)) WRITE(", unused");
	else if ((cu == 0) && (cn == 2)) WRITE(", both unused");
	else if ((cu == 0) && (cn > 2)) WRITE(", all unused");
	else if ((cn == 0) && (cu == 1)) WRITE(", used");
	else if ((cn == 0) && (cu == 2)) WRITE(", both used");
	else if ((cn == 0) && (cu > 2)) WRITE(", all used");
	else if (cn+cu > 0) WRITE(", %d used, %d unused", cu, cn);
	WRITE(")");
	HTML_CLOSE("span");

@ Used only in "by installation".

@<Print the installation region in the extension census table@> =
	switch (current_installation) {
		case 0:
			WRITE("Supplied in the .materials folder&nbsp;&nbsp;");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			WRITE("%p", pathname_of_extensions[INTERNAL_FS_AREA]);
			HTML_CLOSE("span"); break;
		case 1: WRITE("Built in to Inform"); break;
		case 2: WRITE("User installed but overriding a built-in extension"); break;
		case 3:
			WRITE("User installed&nbsp;&nbsp;");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			WRITE("%p", pathname_of_extensions[EXTERNAL_FS_AREA]);
			HTML_CLOSE("span"); break;
	}

@

@d UNINDEXED_SYMBOL "border=\"0\" src=\"inform:/doc_images/unindexed_bullet.png\""
@d INDEXED_SYMBOL "border=\"0\" src=\"inform:/doc_images/indexed_bullet.png\""

@<Print the census line for this extension@> =
	@<Print column 1 of the census line@>;
	HTML::next_html_column_nw(OUT, 0);
	if (d != CE_BY_TITLE) {
		@<Print column 2 of the census line@>;
		HTML::next_html_column_nw(OUT, 0);
	}
	@<Print column 3 of the census line@>;
	HTML::next_html_column_w(OUT, 0);
	@<Print column 4 of the census line@>;

@ The appearance of the line is

>> (bullet) The Title (by The Author) (VM requirement icons)

where all is optional except the title part.

@<Print column 1 of the census line@> =
	char *bulletornot = UNINDEXED_SYMBOL;
	if (Extensions::Census::ecd_used(ecd)) { bulletornot = INDEXED_SYMBOL; key_bullet = TRUE; }
	WRITE("&nbsp;");
	HTML_TAG_WITH("img", "%s", bulletornot);

	Extensions::IDs::begin_extension_link(OUT, &(ecd->ecd_id), ecd->rubric);
	if (d != CE_BY_AUTHOR) {
		HTML::begin_colour(OUT, I"404040");
		WRITE("%S", ecd->ecd_id.raw_title);
		if (Str::len(ecd->ecd_id.raw_title) + Str::len(ecd->ecd_id.raw_author_name) > 45) {
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		} else
			WRITE(" ");
		WRITE("by %S", ecd->ecd_id.raw_author_name);
		HTML::end_colour(OUT);
	} else {
		HTML::begin_colour(OUT, I"404040");
		WRITE("%S", ecd->ecd_id.raw_title);
		HTML::end_colour(OUT);
	}
	Extensions::IDs::end_extension_link(OUT, &(ecd->ecd_id));

	if (Str::len(ecd->VM_requirement)) {
		@<Append icons which signify the VM requirements of the extension@>;
		key_vms = TRUE;
	}

@ VM requirements are parsed by feeding them into the lexer and calling the
same routines as would be used when parsing headings about VM requirements
in a normal run of Inform. Note that because the requirements are in round
brackets, which the lexer will split off as distinct words, we can ignore
the first and last word and just look at what is in between:

@<Append icons which signify the VM requirements of the extension@> =
	wording W = Feeds::feed_stream(ecd->VM_requirement);
	WRITE("&nbsp;");
	VirtualMachines::write_icons(OUT, Wordings::trim_last_word(Wordings::trim_last_word(W)));

@<Print column 2 of the census line@> =
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (Str::len(ecd->version_text) > 0)
		WRITE("v&nbsp;%S", ecd->version_text);
	else
		WRITE("--");
	HTML_CLOSE("span");

@

@d BUILT_IN_SYMBOL "border=\"0\" src=\"inform:/doc_images/builtin_ext.png\""
@d OVERRIDING_SYMBOL "border=\"0\" src=\"inform:/doc_images/override_ext.png\""
@d PROJECT_SPECIFIC_SYMBOL "border=\"0\" src=\"inform:/doc_images/pspec_ext.png\""

@<Print column 3 of the census line@> =
	char *opener = "src='inform:/doc_images/folder4.png' border=0";
	pathname *area = pathname_of_extensions[EXTERNAL_FS_AREA];
	if (ecd->built_in) { opener = BUILT_IN_SYMBOL; key_builtin = TRUE; }
	if (ecd->overriding_a_built_in_extension) {
		opener = OVERRIDING_SYMBOL; key_override = TRUE;
	}
	if (ecd->project_specific) {
		opener = PROJECT_SPECIFIC_SYMBOL; key_pspec = TRUE;
		area = pathname_of_extensions[MATERIALS_FS_AREA];
	}
	if (ecd->built_in) HTML_TAG_WITH("img", "%s", opener)
	else HTML::Javascript::open_file(OUT, area, ecd->ecd_id.raw_author_name, opener);

@<Print column 4 of the census line@> =
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if ((d == CE_BY_DATE) || (d == CE_BY_INSTALL)) {
		WRITE("%S", Extensions::IDs::get_usage_date(&(ecd->ecd_id)));
	} else if (d == CE_BY_LENGTH) {
		if (Extensions::IDs::forgot(&(ecd->ecd_id)))
			WRITE("I did read this, but forgot");
		else if (Extensions::IDs::never(&(ecd->ecd_id)))
			WRITE("I've never read this");
		else
			WRITE("%d words", Extensions::IDs::get_word_count(&(ecd->ecd_id)));
	} else {
		if (Str::len(ecd->rubric) > 0)
			WRITE("%S", ecd->rubric);
		else
			WRITE("--");
	}
	HTML_CLOSE("span");

@ Two useful measurements:

=
int Extensions::Census::installation_region(extension_census_datum *ecd) {
	if (ecd->project_specific) return 0;
	if (ecd->built_in) return 1;
	if (ecd->overriding_a_built_in_extension) return 2;
	return 3;
}

int Extensions::Census::ecd_used(extension_census_datum *ecd) {
	if ((Extensions::IDs::no_times_used_in_context(
		&(ecd->ecd_id), LOADED_EIDBC) > 0) ||
		(Extensions::IDs::no_times_used_in_context(
		&(ecd->ecd_id), DICTIONARY_REFERRED_EIDBC) > 0))
		return TRUE;
	return FALSE;
}

@ The following give the sorting criteria:

=
int Extensions::Census::compare_ecd_by_title(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Extensions::IDs::compare_by_title(&(e1->ecd_id), &(e2->ecd_id));
}

int Extensions::Census::compare_ecd_by_author(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Extensions::IDs::compare(&(e1->ecd_id), &(e2->ecd_id));
}

int Extensions::Census::compare_ecd_by_installation(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	int d = Extensions::Census::installation_region(e1) - Extensions::Census::installation_region(e2);
	if (d != 0) return d;
	return Extensions::IDs::compare_by_title(&(e1->ecd_id), &(e2->ecd_id));
}

int Extensions::Census::compare_ecd_by_date(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Extensions::IDs::compare_by_date(&(e1->ecd_id), &(e2->ecd_id));
}

int Extensions::Census::compare_ecd_by_length(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	return Extensions::IDs::compare_by_length(&(e1->ecd_id), &(e2->ecd_id));
}
