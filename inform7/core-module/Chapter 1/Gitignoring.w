[Gitignoring::] Gitignoring.

Automatically creating or updating gitignore files within Inform projects, so
that can be put under version control with git more easily.

@ Git is, so help us, the world's standard in version control, but is not
the easiest system to configure, especially for beginners. One thing we can
help with is the automatic setting up of |.gitignore| files, which tell git
which files are ephemeral and need not be under source control.

This very simple feature was added to Inform as IE-0002 in October 2022.

=
void Gitignoring::automatic(inform_project *proj) {
	Gitignoring::for_project(Projects::path(proj));
	Gitignoring::for_materials(Projects::materials_path(proj));
}

@ In |.gitignore| file syntax, pathnames are relative to that of the file.
|P/**| means "ignore |P| and all its contents, to any depth". Lines beginning
with a |#| are comments.

=
void Gitignoring::for_project(pathname *P) {
	filename *F = Filenames::in(P, I".gitignore");
	text_stream *stanza_wanted =
		I"Build/**\nIndex/**\nmanifest.plist\nMetadata.iFiction\nnotes.rtf\nRelease.blurb\n";
	Gitignoring::fix(F, stanza_wanted);
}

void Gitignoring::for_materials(pathname *P) {
	filename *F = Filenames::in(P, I".gitignore");
	text_stream *stanza_wanted = I"Release/**\n";
	Gitignoring::fix(F, stanza_wanted);
}

@ What we do, for each of the directories relevant to a project (i.e. the project
itself and its materials), is to see if a |.gitignore| file already exists. If it
does, we look for a "stanza" between appropriate comments which will represent
our contribution. If that stanza already contains the right contents, then we
do not write the file. (There is no need, and we don't want to touch the timestamp
on the file.) Otherwise, we write the file back but with out preferred contents
of the stanza replacing whatever was there before.

As a special case, if there is no |.gitignore| file, we create one consisting
only of our stanza.

=
void Gitignoring::fix(filename *F, text_stream *stanza_wanted) {
	gitignore_harvest H;
	@<Harvest the existing gitignore file content, if any@>;

	if (H.ignore) return;
	if (Str::eq(stanza_wanted, H.G)) return;

	text_stream F_struct; text_stream *OUT = &F_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, ISO_ENC) == FALSE)
		Errors::fatal_with_file("unable to open .gitignore file for output: %f", F);
	WRITE("%S", H.B);
	WRITE("# This stanza written automatically by inform7\n");
	WRITE("%S", stanza_wanted);
	WRITE("# End of stanza written automatically by inform7\n");
	WRITE("%S", H.A);
	STREAM_CLOSE(OUT);
}

@ The process of extracting the content of any existing |.gitignore| file
is called "harvesting", and results in one of these:

=
typedef struct gitignore_harvest {
	int position;          /* 1: before stanza, 2: inside it, 3: after it */
	int ignore;            /* have we seen a request not to do this? */
	struct text_stream *B; /* content of file before stanza */
	struct text_stream *G; /* content of stanza (not including comments) */
	struct text_stream *A; /* content of file after stanza */
} gitignore_harvest;

@<Harvest the existing gitignore file content, if any@> =
	H.position = 1;
	H.ignore = FALSE;
	H.B = Str::new();
	H.G = Str::new();
	H.A = Str::new();
	if (TextFiles::exists(F))
		TextFiles::read(F, TRUE,
			NULL, FALSE, Gitignoring::read_helper, NULL, &H);

@ =
void Gitignoring::read_helper(text_stream *line,
	text_file_position *tfp, void *state) {
	gitignore_harvest *H = (gitignore_harvest *) state;
	Str::trim_white_space(line);
	if (Str::eq(line, I"# This stanza written automatically by inform7")) {
		if (H->position == 1) H->position = 2;
	} else if (Str::eq(line, I"# End of stanza written automatically by inform7")) {
		if (H->position == 2) H->position = 3;
	} else if (Str::eq(line, I"# No stanza written automatically by inform7")) {
		H->ignore = TRUE;
	} else {
		switch (H->position) {
			case 1: WRITE_TO(H->B, "%S\n", line); break;
			case 2: WRITE_TO(H->G, "%S\n", line); break;
			case 3: WRITE_TO(H->A, "%S\n", line); break;
		}
	}
}
