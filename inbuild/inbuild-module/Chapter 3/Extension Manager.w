[ExtensionManager::] Extension Manager.

An Inform 7 extension.

@h Genre definition.

= (early code)
inbuild_genre *extension_genre = NULL;

@ An extension has a title and an author name, each of which is limited in
length to one character less than the following constants:

@d MAX_EXTENSION_TITLE_LENGTH 51
@d MAX_EXTENSION_AUTHOR_LENGTH 51

@ =
void ExtensionManager::start(void) {
	extension_genre = Model::genre(I"extension");
	METHOD_ADD(extension_genre, GENRE_WRITE_WORK_MTID, ExtensionManager::write_work);
	METHOD_ADD(extension_genre, GENRE_CLAIM_AS_COPY_MTID, ExtensionManager::claim_as_copy);
	METHOD_ADD(extension_genre, GENRE_SEARCH_NEST_FOR_MTID, ExtensionManager::search_nest_for);
	METHOD_ADD(extension_genre, GENRE_COPY_TO_NEST_MTID, ExtensionManager::copy_to_nest);
}

void ExtensionManager::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%X", work);
}

@ Extensions live in their namesake subdirectory of a nest:

=
pathname *ExtensionManager::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::subfolder(N->location, I"Extensions");
}

@ Extension copies are annotated with a structure called an |inform_extension|,
which stores data about extensions used by the Inform compiler.

=
inform_extension *ExtensionManager::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == extension_genre)) {
		return RETRIEVE_POINTER_inform_extension(C->content);
	}
	return NULL;
}

inbuild_copy *ExtensionManager::new_copy(inbuild_edition *edition, filename *F) {
	inform_extension *E = Extensions::new_ie();
	inbuild_copy *C = Model::copy_in_file(edition, F, STORE_POINTER_inform_extension(E));
	E->as_copy = C;
	return C;
}

@h Claiming.
Here |arg| is a textual form of a filename or pathname, such as may have been
supplied at the command line; |ext| is a substring of it, and is its extension
(e.g., |jpg| if |arg| is |Geraniums.jpg|), or is empty if there isn't one;
|directory_status| is true if we know for some reason that this is a directory
not a file, false if we know the reverse, and otherwise not applicable.

An extension, for us, needs to be a file with extension |i7x|, but it needs
also to scan properly -- which means the top line of the file has to be right.
So we'll open it and look.

=
void ExtensionManager::claim_as_copy(inbuild_genre *gen, inbuild_copy **C,
	text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == TRUE) return;
	if (Str::eq_insensitive(ext, I"i7x")) {
		filename *F = Filenames::from_text(arg);
		*C = ExtensionManager::claim_file_as_copy(F, NULL, FALSE);
	}
}

inbuild_copy *ExtensionManager::claim_file_as_copy(filename *F, text_stream *error_text,
	int allow_malformed) {
	if ((allow_malformed) && (TextFiles::exists(F) == FALSE)) return NULL;
	TEMPORARY_TEXT(author);
	TEMPORARY_TEXT(title);
	TEMPORARY_TEXT(rubric_text);
	TEMPORARY_TEXT(requirement_text);
	inbuild_version_number V =
		ExtensionManager::scan_file(F, title, author, rubric_text, requirement_text, error_text);
	inbuild_copy *C = ExtensionManager::new_copy(
		Model::edition(Works::new(extension_genre, title, author), V), F);
	if ((allow_malformed) || (Str::len(error_text) == 0)) {
		Works::add_to_database(C->edition->work, CLAIMED_WDBC);
		ExtensionManager::build_graph(C);
	} else {
		C = NULL;
	}
	DISCARD_TEXT(author);
	DISCARD_TEXT(title);
	DISCARD_TEXT(rubric_text);
	DISCARD_TEXT(requirement_text);
	return C;
}

@ The following scans a potential extension file. If it seems malformed, a
suitable error is written to the stream |error_text|. If not, this is left
alone, and the version number is returned.

=
inbuild_version_number ExtensionManager::scan_file(filename *F,
	text_stream *claimed_title, text_stream *claimed_author_name,
	text_stream *rubric_text, text_stream *requirement_text, text_stream *error_text) {
	inbuild_version_number V = VersionNumbers::null();
	TEMPORARY_TEXT(titling_line);
	TEMPORARY_TEXT(version_text);
	FILE *EXTF = Filenames::fopen_caseless(F, "r");
	if (EXTF == NULL) {
		if (error_text) WRITE_TO(error_text, "this file cannot be read");
		return V;
	}
	@<Read the titling line of the extension and normalise its casing@>;
	@<Read the rubric text, if any is present@>;
	@<Parse the version, title, author and VM requirements from the titling line@>;
	fclose(EXTF);
	if (Str::len(version_text) > 0) V = VersionNumbers::from_text(version_text);
	DISCARD_TEXT(titling_line);
	DISCARD_TEXT(version_text);
	return V;
}

@ The actual maximum number of characters in the titling line is one less
than |MAX_TITLING_LINE_LENGTH|, to allow for the null terminator. The titling
line is terminated by any of |0A|, |0D|, |0A 0D| or |0D 0A|, or by the local
|\n| for good measure.

@<Read the titling line of the extension and normalise its casing@> =
	int titling_chars_read = 0, c;
	while ((c = TextFiles::utf8_fgetc(EXTF, NULL, FALSE, NULL)) != EOF) {
		if (c == 0xFEFF) return V; /* skip the optional Unicode BOM pseudo-character */
		if ((c == '\x0a') || (c == '\x0d') || (c == '\n')) break;
		if (titling_chars_read < MAX_TITLING_LINE_LENGTH - 1) PUT_TO(titling_line, c);
	}
	Works::normalise_casing(titling_line);

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

@ In general, once case-normalised, a titling line looks like this:

>> Version 2/070423 Of Going To The Zoo (For Glulx Only) By Cary Grant Begins Here.

and the version information, the VM restriction and the full stop are all
optional, but the division word "of" and the concluding "begin[s] here"
are not. We break it up into pieces, so that

	|version_text = "2/070423"|
	|claimed_title = "Going To The Zoo"|
	|claimed_author_name = "Cary Grant"|
	|requirement_text = "(For Glulx Only)"|

It's tempting to do this by feeding it into the Inform lexer and then reusing
some of the code which parses these lines during sentence-breaking, but in fact
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
		if (error_text) WRITE_TO(error_text, 
			"the first line of this file does not end 'begin(s) here'");
		return V;
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
		if (error_text) WRITE_TO(error_text,
			"the titling line does not give both author and title");
		return V;
	}

@ Similarly, extension titles are not allowed to contain parentheses, so
this is unambiguous.

@<Extract the VM requirements text, if any, from the claimed title@> =
	if (Regexp::match(&mr, claimed_title, L"(%c*?) *(%(%c*%))")) {
		Str::copy(claimed_title, mr.exp[0]);
		Str::copy(requirement_text, mr.exp[1]);
	}

@h Searching.
Here we look through a nest to find all extensions matching the supplied
requirements.

For efficiency's sake, since the nest could contain many hundreds of
extensions, we narrow down to the author's subfolder if a specific
author is required, and to the specific extension file if title is
also known. (In particular, this happens when the Inform compiler is
using us to search for, say, Locksmith by Emily Short.)

Nobody should any longer be storing extension files without the file
extension |.i7x|, but this was allowed in the early days of Inform 7,
so we'll quietly allow for it.

=
void ExtensionManager::search_nest_for(inbuild_genre *gen, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	pathname *P = ExtensionManager::path_within_nest(N);
	if (Str::len(req->work->author_name) > 0) {
		pathname *Q = Pathnames::subfolder(P, req->work->author_name);
		if (Str::len(req->work->title) > 0) {
			for (int i7x_flag = 1; i7x_flag >= 0; i7x_flag--) {
				TEMPORARY_TEXT(leaf);
				if (i7x_flag) WRITE_TO(leaf, "%S.i7x", req->work->title);
				else WRITE_TO(leaf, "%S", req->work->title);
				filename *F = Filenames::in_folder(Q, leaf);
				ExtensionManager::search_nest_for_single_file(F, N, req, search_results);
				DISCARD_TEXT(leaf);
			}
		} else {
			ExtensionManager::search_nest_for_r(Q, N, req, search_results);
		}
	} else {
		ExtensionManager::search_nest_for_r(P, N, req, search_results);
	}
}

void ExtensionManager::search_nest_for_r(pathname *P, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	scan_directory *D = Directories::open(P);
	if (D) {
		TEMPORARY_TEXT(LEAFNAME);
		while (Directories::next(D, LEAFNAME)) {
			if (Str::get_last_char(LEAFNAME) == FOLDER_SEPARATOR) {
				Str::delete_last_character(LEAFNAME);
				pathname *Q = Pathnames::subfolder(P, LEAFNAME);
				ExtensionManager::search_nest_for_r(Q, N, req, search_results);
			} else {
				filename *F = Filenames::in_folder(P, LEAFNAME);
				ExtensionManager::search_nest_for_single_file(F, N, req, search_results);
			}
		}
		DISCARD_TEXT(LEAFNAME);
		Directories::close(D);
	}
}

void ExtensionManager::search_nest_for_single_file(filename *F, inbuild_nest *N,
	inbuild_requirement *req, linked_list *search_results) {
	inbuild_copy *C = ExtensionManager::claim_file_as_copy(F, NULL, req->allow_malformed);
	if ((C) && (Requirements::meets(C->edition, req))) {
		Nests::add_search_result(search_results, N, C);
	}
}

@h Copying.
Now the task is to copy an extension into place in a nest. This is easy,
since an extension is a single file; to sync, we just overwrite.

=
filename *ExtensionManager::filename_in_nest(inbuild_nest *N,
	text_stream *title, text_stream *author) {
	pathname *E = ExtensionManager::path_within_nest(N);
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.i7x", title);
	filename *F = Filenames::in_folder(Pathnames::subfolder(E, author), leaf);
	DISCARD_TEXT(leaf);
	return F;
}

void ExtensionManager::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N,
	int syncing, build_methodology *meth) {
	pathname *E = ExtensionManager::path_within_nest(N);
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.i7x", C->edition->work->title);
	filename *F = Filenames::in_folder(
		Pathnames::subfolder(E, C->edition->work->author_name), leaf);
	DISCARD_TEXT(leaf);

	if (TextFiles::exists(F)) {
		if (syncing == FALSE) { Nests::overwrite_error(N, C); return; }
	} else {
		if (meth->methodology == DRY_RUN_METHODOLOGY) {
			TEMPORARY_TEXT(command);
			WRITE_TO(command, "mkdir -p ");
			Shell::quote_path(command, Filenames::get_path_to(F));
			WRITE_TO(STDOUT, "%S\n", command);
			DISCARD_TEXT(command);
		} else {
			Pathnames::create_in_file_system(N->location);
			Pathnames::create_in_file_system(Pathnames::subfolder(N->location, I"Extensions"));
			Pathnames::create_in_file_system(Filenames::get_path_to(F));
		}
	}

	TEMPORARY_TEXT(command);
	WRITE_TO(command, "cp -f ");
	Shell::quote_file(command, C->location_if_file);
	Shell::quote_file(command, F);
	BuildSteps::shell(command, meth);
	DISCARD_TEXT(command);
}

@h Build graph.
The build graph for an extension is just a single node: you don't need to
build an extension at all.

=
void ExtensionManager::build_graph(inbuild_copy *C) {
	Graphs::copy_vertex(C);
}
