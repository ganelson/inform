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
		filename *rmt_vn = Filenames::in_folder(Pathnames::from_text(web), I"README.txt");
		if (TextFiles::exists(rmt_vn)) @<Read in README file@>;
		rmt_vn = Filenames::in_folder(Pathnames::from_text(web), I"README.md");
		if (TextFiles::exists(rmt_vn)) @<Read in README file@>;
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

@<Read in README file@> =
	TextFiles::read(rmt_vn, FALSE, "unable to read README file from website template", TRUE,
		&Inversion::readme_harvester, NULL, P);

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

@ And this is needed for cheapglk and glulxe.

=
void Inversion::readme_harvester(text_stream *text, text_file_position *tfp, void *state) {
	project *P = (project *) state;
	match_results mr = Regexp::create_mr();
	if (Str::len(text) == 0) return;
	if ((Regexp::match(&mr, text, L"CheapGlk Library: version (%c*?) *")) ||
		(Regexp::match(&mr, text, L"- Version (%c*?) *"))) {
		@<Ensure a current version exists@>;
		P->current_version->number = Str::duplicate(mr.exp[0]);
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
