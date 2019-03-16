[Inversion::] Version Numbering.

To update the build number(s) and versions for the intools.

@h The build-numbers file.
The scheme here is that each project can optionally contain a UTF-8 encoded
text file called |versions.txt|, which lists all of its version history;
a line of that file corresponds to a "version". Out of these versions, one
must be marked as the current version.

=
typedef struct project {
	struct text_stream *sync_line;
	struct project *sync_to;
	int manual_updating;
	struct text_stream *web;
	struct filename *contents_file;
	struct filename *versions_file;
	struct linked_list *versions; /* of |version| */
	struct version *current_version;
	struct text_stream *purpose;
	struct text_stream *conts;
	int next_is_version;
	MEMORY_MANAGEMENT
} project;

typedef struct version {
	struct text_stream *name;
	struct text_stream *number;
	struct text_stream *build_code;
	struct text_stream *date;
	struct text_stream *notes;
	MEMORY_MANAGEMENT
} version;

@ And here we take a filename or pathname, which might be to a web, with
or without a versions file; or to an extension; or to a website template;
or to the original Inform 6 source code. These all store their version
numbering differently, so we need code which is something of a Swiss army
knife.

=
project *Inversion::read(text_stream *web, int silently) {
	project *P;
	LOOP_OVER(P, project) if (Str::eq(web, P->web)) return P;
	P = CREATE(project);
	P->sync_line = Str::new();
	P->sync_to = NULL;
	P->manual_updating = TRUE;
	P->web = Str::duplicate(web);
	P->versions = NEW_LINKED_LIST(version);
	P->current_version = NULL;
	P->conts = Str::new();
	P->purpose = Str::new();
	P->next_is_version = FALSE;
	if (Str::ends_with_wide_string(web, L".i7x")) {
		P->versions_file = NULL;
		P->contents_file = NULL;
		@<Read in the extension file@>;
	} else {
		P->versions_file = Filenames::in_folder(Pathnames::from_text(web), I"versions.txt");
		P->contents_file = Filenames::in_folder(Pathnames::from_text(web), I"Contents.w");
		if (TextFiles::exists(P->contents_file)) {
			@<Read in the contents file@>;
			if (TextFiles::exists(P->versions_file) == FALSE)
				@<Read version from the contents file@>;
		}
		if (TextFiles::exists(P->versions_file)) @<Read in the versions file@>;
		filename *I6_vn = Filenames::in_folder(
			Pathnames::subfolder(Pathnames::from_text(web), I"inform6"), I"header.h");
		if (TextFiles::exists(I6_vn)) @<Read in I6 source header file@>;
		filename *template_vn = Filenames::in_folder(Pathnames::from_text(web), I"(manifest).txt");
		if (TextFiles::exists(template_vn)) @<Read in template manifest file@>;
	}
	@<Print the current version number@>;
	return P;
}

@<Print the current version number@> =
	if ((P->current_version) && (!silently))
		PRINT("%S: %S %S (build %S)\n", web,
			P->current_version->name, P->current_version->number, P->current_version->build_code);

@<Read in the extension file@> =
	TextFiles::read(Filenames::from_text(web), FALSE, "unable to read extension", TRUE,
		&Inversion::extension_harvester, NULL, P);

@<Read in the contents file@> =
	TextFiles::read(P->contents_file, FALSE, "unable to read contents section", TRUE,
		&Inversion::contents_harvester, NULL, P);

@<Read version from the contents file@> =
	TextFiles::read(P->contents_file, FALSE, "unable to read contents section", TRUE,
		&Inversion::contents_version_harvester, NULL, P);

@<Read in the versions file@> =
	TextFiles::read(P->versions_file, FALSE, "unable to read roster of version numbers", TRUE,
		&Inversion::version_harvester, NULL, P);

@<Read in I6 source header file@> =
	TextFiles::read(I6_vn, FALSE, "unable to read header file from I6 source", TRUE,
		&Inversion::header_harvester, NULL, P);

@<Read in template manifest file@> =
	TextFiles::read(template_vn, FALSE, "unable to read manifest file from website template", TRUE,
		&Inversion::template_harvester, NULL, P);

@ The format for the contents section of a web is documented in Inweb.

=
void Inversion::extension_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if (Regexp::match(&mr, text, L" *Version (%c*?) of %c*begins here. *")) {
		@<Ensure a current version exists@>;
		P->current_version->number = Str::duplicate(mr.exp[0]);
	}
	Regexp::dispose_of(&mr);
}

@ The format for the contents section of a web is documented in Inweb.

=
void Inversion::contents_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if (Regexp::match(&mr, text, L" *Purpose: *(%c*?) *")) {
		P->purpose = Str::duplicate(mr.exp[0]);
	}
	Regexp::dispose_of(&mr);
}

void Inversion::contents_version_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if (Regexp::match(&mr, text, L" *Version Number: *(%c*?) *")) {
		@<Ensure a current version exists@>;
		P->current_version->number = Str::duplicate(mr.exp[0]);
	}
	Regexp::dispose_of(&mr);
}

@ A version file contains lines which can either be a special command, or
give details of a version. The commands are |Automatic| or |Manual| (the
latter is the default), or |Sync to W|, where |W| is another project.
(All of this is infrastructure left over from when the Inform tools were
syncing version numbers to the main Inform 7 version number: with the
transition to Github, this scheme was dropped.)

=
void Inversion::version_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if (Regexp::match(&mr, text, L"Automatic")) {
		P->manual_updating = FALSE;
	} else if (Regexp::match(&mr, text, L"Manual")) {
		P->manual_updating = TRUE;
	} else if (Regexp::match(&mr, text, L"Sync to (%c*)")) {
		P->sync_to = Inversion::read(mr.exp[0], TRUE);
		P->manual_updating = FALSE;
	} else if (Regexp::match(&mr, text, L"(%c*?)\t+(%c*?)\t+(%c*?)\t+(%c*?)\t+(%c*)")) {
		version *V = CREATE(version);
		V->name = Str::duplicate(mr.exp[0]);
		V->number = Str::duplicate(mr.exp[1]);
		V->build_code = Str::duplicate(mr.exp[2]);
		V->date = Str::duplicate(mr.exp[3]);
		V->notes = Str::duplicate(mr.exp[4]);
		if (Str::get_first_char(V->build_code) == '*') {
			Str::delete_first_character(V->build_code);
			P->current_version = V;
		}
		ADD_TO_LINKED_LIST(V, version, P->versions);
	} else {
		Errors::in_text_file("can't parse version line", tfp);
	}
	Regexp::dispose_of(&mr);
}

@ Explicit code to read from |header.h| in the Inform 6 repository.

=
void Inversion::header_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if (Regexp::match(&mr, text, L"#define RELEASE_NUMBER (%c*?) *")) {
		@<Ensure a current version exists@>;
		P->current_version->number = Str::duplicate(mr.exp[0]);
	}
	if (Regexp::match(&mr, text, L"#define RELEASE_DATE \"(%c*?)\" *")) {
		@<Ensure a current version exists@>;
		P->current_version->name = Str::duplicate(mr.exp[0]);
		P->current_version->date = Str::duplicate(mr.exp[0]);
	}
	Regexp::dispose_of(&mr);
}

@ Explicit code to read from the manifest file of a website template.

=
void Inversion::template_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if (Regexp::match(&mr, text, L"%[INTERPRETERVERSION%]")) {
		P->next_is_version = TRUE;
	} else if (P->next_is_version) {
		@<Ensure a current version exists@>;
		P->current_version->name = Str::duplicate(text);
		P->next_is_version = FALSE;
	}
	Regexp::dispose_of(&mr);
}

@ And many of the above use this, which assumes there will be just one single
version number known for a program.

@<Ensure a current version exists@> =
	if (P->current_version == NULL) {
		version *V = CREATE(version);
		V->name = NULL;
		V->number = NULL;
		V->build_code = I"9Z99";
		V->date = NULL;
		V->notes = NULL;
		ADD_TO_LINKED_LIST(V, version, P->versions);
		P->current_version = V;
	}

@ The following then writes back the versions file, following a version
increment:

=
void Inversion::write(project *P) {
	text_stream vr_stream;
	text_stream *OUT = &vr_stream;
	if (Streams::open_to_file(OUT, P->versions_file, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write versions file", P->versions_file);
	if (P->sync_to) WRITE("Sync to %S\n", P->sync_to->web);
	else if (P->manual_updating) WRITE("Manual\n");
	else WRITE("Automatic\n");
	version *V;
	LOOP_OVER_LINKED_LIST(V, version, P->versions) {
		WRITE("%S\t%S\t", V->name, V->number);
		if (V == P->current_version) WRITE("*");
		WRITE("%S\t%S\t%S\n", V->build_code, V->date, V->notes);
	}
	Streams::close(OUT);
}

@h Updating.
The standard date format we use is "26 February 2018".

=
int Inversion::dated_today(project *P, text_stream *dateline) {
	if (P->current_version == NULL) return FALSE;
	char *monthname[12] = { "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December" };
	WRITE_TO(dateline, "%d %s %d",
		the_present->tm_mday, monthname[the_present->tm_mon], the_present->tm_year+1900);
	int rv = FALSE;
	if (Str::eq(dateline, P->current_version->date)) rv = TRUE;
	return rv;
}

@ Here we read the Inform four-character code, e.g., |3Q27|, and increase it
by one. The two-digit code at the back is incremented, but rolls around from
|99| to |01|, in which case the letter is advanced, except that |I| and |O|
are skipped, and if the letter passes |Z| then it rolls back around to |A|
and the initial digit is incremented.

=
void Inversion::increment(project *P) {
	if (P->current_version == NULL) return;
	text_stream *T = P->current_version->build_code;
	if (Str::len(T) != 4) Errors::with_text("version number malformed: %S", T);
	else {
		int N = Str::get_at(T, 0) - '0';
		int L = Str::get_at(T, 1);
		int M1 = Str::get_at(T, 2) - '0';
		int M2 = Str::get_at(T, 3) - '0';
		if ((N < 0) || (N > 9) || (L < 'A') || (L > 'Z') ||
			(M1 < 0) || (M1 > 9) || (M2 < 0) || (M2 > 9)) {
			Errors::with_text("version number malformed: %S", T);
		} else {
			M2++;
			if (M2 == 10) { M2 = 0; M1++; }
			if (M1 == 10) { M1 = 0; M2 = 1; L++; }
			if ((L == 'I') || (L == 'O')) L++;
			if (L > 'Z') { L = 'A'; N++; }
			if (N == 10) Errors::with_text("version number overflowed: %S", T);
			else {
				Str::clear(T);
				WRITE_TO(T, "%d%c%d%d", N, L, M1, M2);
				PRINT("Build advanced to %S\n", T);
			}
		}
	}
}

@h Imposition.
When we impose a new version number on a web that has a contents page, we
update the metadata in that contents page.

=
void Inversion::impose(project *P) {
	TextFiles::read(P->contents_file, FALSE, "unable to read web contents", TRUE,
		&Inversion::impose_helper, NULL, P);
	text_stream vr_stream;
	text_stream *OUT = &vr_stream;
	if (Streams::open_to_file(OUT, P->contents_file, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("unable to write web contents", P->contents_file);
	WRITE("%S", P->conts);
	Streams::close(OUT);
}

void Inversion::impose_helper(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	project *SP = P;
	if (P->sync_to) SP = P->sync_to;
	text_stream *OUT = P->conts;
	match_results mr = Regexp::create_mr();
	if ((P->current_version) && (Regexp::match(&mr, text, L"Build Date:%c*"))) {
		WRITE("Build Date: %S\n", SP->current_version->date);
	} else if ((P->current_version) && (Regexp::match(&mr, text, L"Build Number:%c*"))) {
		WRITE("Build Number: %S\n", SP->current_version->build_code);
	} else if ((P->current_version) && (Regexp::match(&mr, text, L"Version Number:%c*"))) {
		WRITE("Version Number: %S\n", P->current_version->number);
	} else if ((P->current_version) && (Regexp::match(&mr, text, L"Version Name:%c*"))) {
		WRITE("Version Name: %S\n", P->current_version->name);
	} else {
		WRITE("%S\n", text);
	}
	Regexp::dispose_of(&mr);
}

@h Daily build maintenance.

=
void Inversion::maintain(text_stream *web) {
	project *P = Inversion::read(web, FALSE);
	if (Inversion::needs_update(P))  {
		Inversion::write(P);
		Inversion::impose(P);
	}
}

@ =
int Inversion::needs_update(project *P) {
	int rv = FALSE;
	if ((P->manual_updating == FALSE) && (P->current_version)) {
		project *SP = P->sync_to;
		if (SP) {
			if (SP->current_version) {
				if (Str::ne(P->current_version->date, SP->current_version->date)) {
					rv = TRUE; Str::copy(P->current_version->date, SP->current_version->date);
				}
				if (Str::ne(P->current_version->build_code, SP->current_version->build_code)) {
					rv = TRUE; Str::copy(P->current_version->build_code, SP->current_version->build_code);
				}
			}
		} else {
			TEMPORARY_TEXT(dateline);
			if (Inversion::dated_today(P, dateline) == FALSE) {
				if (P->sync_to == NULL) Inversion::increment(P);
				Str::copy(P->current_version->date, dateline);
				rv = TRUE;
			}
			DISCARD_TEXT(dateline);
		}
	}
	return rv;
}
