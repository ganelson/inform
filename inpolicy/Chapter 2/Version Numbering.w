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
	struct filename *versions_file;
	struct linked_list *versions; /* of |version| */
	struct version *current_version;
	struct text_stream *conts;
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

@ And here we turn a named web into its |project| structure. We print its
current version number when we first load a project in:

=
project *Inversion::read(text_stream *web) {
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
	P->versions_file = Filenames::in_folder(Pathnames::from_text(web), I"versions.txt");
	@<Read in the versions file@>;
	@<Print the current version number@>;
	return P;
}

@<Print the current version number@> =
	if (P->current_version == NULL) {
		Errors::with_text("warning: no version marked as current", web);
	} else {
		PRINT("%S: %S %S (build %S)\n", web,
			P->current_version->name, P->current_version->number, P->current_version->build_code);
	}

@<Read in the versions file@> =
	TextFiles::read(P->versions_file, FALSE, "unable to read roster of version numbers", TRUE,
		&Inversion::version_harvester, NULL, P);

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
		P->sync_to = Inversion::read(mr.exp[0]);
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
	filename *F = Filenames::in_folder(Pathnames::from_text(P->web), I"Contents.w");
	TextFiles::read(F, FALSE, "unable to read web contents", TRUE,
		&Inversion::impose_helper, NULL, P);
	text_stream vr_stream;
	text_stream *OUT = &vr_stream;
	if (Streams::open_to_file(OUT, F, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("unable to write web contents", F);
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
	project *P = Inversion::read(web);
	if (Inversion::needs_update(P))  {
		Inversion::write(P);
		Inversion::impose(P);
		if ((Str::eq(web, I"inform7")) && (P->current_version)) {
			filename *F = Filenames::from_text(I"build-code.mk");
			text_stream as_stream;
			text_stream *OUT = &as_stream;
			if (Streams::open_to_file(OUT, F, UTF8_ENC) == FALSE)
				Errors::fatal_with_file("unable to write archive settings", F);
			WRITE("BUILDCODE = %S\n", P->current_version->build_code);
			Streams::close(OUT);
		}
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
