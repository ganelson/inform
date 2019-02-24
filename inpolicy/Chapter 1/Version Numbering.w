[Inversion::] Version Numbering.

To update the build number(s) and versions for the intools.

@h The build-numbers file.

=
typedef struct project {
	struct text_stream *sync_line;
	struct project *sync_to;
	int manual_updating;
	struct text_stream *web;
	struct filename *versions_file;
	struct version *first_version;
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
	int unstable;
	struct version *next_version;
	MEMORY_MANAGEMENT
} version;

project *Inversion::read(text_stream *web) {
	project *P;
	LOOP_OVER(P, project)
		if (Str::eq(web, P->web))
			return P;
	P = CREATE(project);
	P->sync_line = Str::new();
	P->sync_to = NULL;
	P->manual_updating = TRUE;
	P->web = Str::duplicate(web);
	P->first_version = NULL;
	P->current_version = NULL;
	P->versions_file = Filenames::in_folder(Pathnames::from_text(web), I"versions.txt");
	TextFiles::read(P->versions_file, FALSE, "unable to read roster of version numbers", TRUE,
		&Inversion::version_harvester, NULL, P);
	P->conts = Str::new();
	if (P->current_version == NULL) {
		Errors::with_text("warning: no version marked as current", web);
	} else {
		PRINT("%S: %S %S (build %S)\n", web,
			P->current_version->name, P->current_version->number, P->current_version->build_code);
	}
	return P;
}

void Inversion::version_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if (Regexp::match(&mr, text, L"Automatic")) {
		P->manual_updating = FALSE;
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
			V->unstable = TRUE;
			Str::delete_first_character(V->build_code);
			P->current_version = V;
		} else V->unstable = FALSE;
		if (P->first_version == NULL) P->first_version = V;
		else {
			version *W = P->first_version;
			while ((W) && (W->next_version)) W = W->next_version;
			W->next_version = V;
		}
	} else {
		Errors::in_text_file("can't parse version line", tfp);
	}
	Regexp::dispose_of(&mr);
}

void Inversion::write(project *P) {
	text_stream vr_stream;
	text_stream *OUT = &vr_stream;
	if (Streams::open_to_file(OUT, P->versions_file, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write versions file", P->versions_file);
	if (P->sync_to) WRITE("Sync to %S\n", P->sync_to->web);
	for (version *V = P->first_version; V; V = V->next_version) {
		WRITE("%S\t%S\t",
			V->name, V->number);
		if (V->unstable) WRITE("*");
		WRITE("%S\t%S\t%S\n",
			V->build_code, V->date, V->notes);
	}
	Streams::close(OUT);
}

@h Updating.

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
