[Extensions::] Extensions.

An Inform 7 extension.

@h Kits.

= (early code)
inbuild_genre *extension_genre = NULL;

@ An extension has a title and an author name, each of which is limited in
length to one character less than the following constants:

@d MAX_EXTENSION_TITLE_LENGTH 51
@d MAX_EXTENSION_AUTHOR_LENGTH 51
@d MAX_VERSION_NUMBER_LENGTH 32 /* allows for |999/991231| and more besides */

@ =
void Extensions::start(void) {
	extension_genre = Model::genre(I"extension");
	METHOD_ADD(extension_genre, GENRE_WRITE_WORK_MTID, Extensions::write_work);
	METHOD_ADD(extension_genre, GENRE_LOCATION_IN_NEST_MTID, Extensions::location_in_nest);
	METHOD_ADD(extension_genre, GENRE_COPY_TO_NEST_MTID, Extensions::copy_to_nest);
}

inbuild_copy *Extensions::claim(text_stream *arg, text_stream *ext, int directory_status) {
	if (directory_status == TRUE) return NULL;
	if (Str::eq_insensitive(ext, I"i7x")) {
		filename *F = Filenames::from_text(arg);
		return Extensions::claim_file(F);
	}
	return NULL;
}

inbuild_copy *Extensions::claim_file(filename *F) {
	TEMPORARY_TEXT(author);
	TEMPORARY_TEXT(title);
	TEMPORARY_TEXT(error_text);
	TEMPORARY_TEXT(rubric_text);
	TEMPORARY_TEXT(requirement_text);
	inbuild_version_number V = Extensions::scan_file(F, title, author, rubric_text, requirement_text, error_text);
	inform_extension *E = Extensions::load_at(title, author, F);
	if (Str::len(error_text) > 0) return NULL;
	Works::add_to_database(E->as_copy->edition->work, CLAIMED_WDBC);
	E->version_loaded = V; E->as_copy->edition->version = V;
	DISCARD_TEXT(author);
	DISCARD_TEXT(title);
	DISCARD_TEXT(error_text);
	DISCARD_TEXT(rubric_text);
	DISCARD_TEXT(requirement_text);
	return E->as_copy;
}

void Extensions::write_work(inbuild_genre *gen, OUTPUT_STREAM, inbuild_work *work) {
	WRITE("%X", work);
}

pathname *Extensions::path_within_nest(inbuild_nest *N) {
	if (N == NULL) internal_error("no nest");
	return Pathnames::subfolder(N->location, I"Extensions");
}

filename *Extensions::filename_in_nest(inbuild_nest *N, text_stream *title, text_stream *author) {
	pathname *E = Extensions::path_within_nest(N);
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.i7x", title);
	filename *F = Filenames::in_folder(Pathnames::subfolder(E, author), leaf);
	DISCARD_TEXT(leaf);
	return F;
}

inbuild_version_number Extensions::scan_file(filename *F,
	text_stream *claimed_title, text_stream *claimed_author_name,
	text_stream *rubric_text, text_stream *requirement_text, text_stream *error_text) {
	inbuild_version_number V = VersionNumbers::null();
	TEMPORARY_TEXT(titling_line);
	TEMPORARY_TEXT(version_text);
	FILE *EXTF = Filenames::fopen_caseless(F, "r");
	if (EXTF == NULL) {
		if (error_text) WRITE_TO(error_text, "file cannot be read");
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
		if (error_text) WRITE_TO(error_text, 
			"appears not to be an extension (its first line does "
			"not end 'begin(s) here', as extension titling lines must)");
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
			"appears not to be an extension (the titling line does "
			"not give both author and title)");
		return V;
	}

@ Similarly, extension titles are not allowed to contain parentheses, so
this is unambiguous.

@<Extract the VM requirements text, if any, from the claimed title@> =
	if (Regexp::match(&mr, claimed_title, L"(%c*?) *(%(%c*%))")) {
		Str::copy(claimed_title, mr.exp[0]);
		Str::copy(requirement_text, mr.exp[1]);
	}

@

=
void Extensions::location_in_nest(inbuild_genre *gen, inbuild_nest *N, inbuild_requirement *req, linked_list *search_results) {
	pathname *P = Extensions::path_within_nest(N);
	if ((Str::len(req->work->title) > 0) && (Str::len(req->work->author_name) > 0)) {
		for (int i7x_flag = 1; i7x_flag >= 0; i7x_flag--) {
			TEMPORARY_TEXT(leaf);
			if (i7x_flag) WRITE_TO(leaf, "%S.i7x", req->work->title);
			else WRITE_TO(leaf, "%S", req->work->title);
			filename *F = Filenames::in_folder(Pathnames::subfolder(P, req->work->author_name), leaf);
			if (TextFiles::exists(F)) {
				inform_extension *E = Extensions::load_at(req->work->title, req->work->author_name, F);
				if (Requirements::meets(E->as_copy->edition, req)) {
					Nests::add_search_result(search_results, N, E->as_copy);
				}
			}
			DISCARD_TEXT(leaf);
		}
	} else {
		Extensions::location_recursively(P, N, req, search_results);
	}
}

void Extensions::location_recursively(pathname *P, inbuild_nest *N, inbuild_requirement *req, linked_list *search_results) {
	scan_directory *D = Directories::open(P);
	if (D) {
		TEMPORARY_TEXT(LEAFNAME);
		while (Directories::next(D, LEAFNAME)) {
			if (Str::get_last_char(LEAFNAME) == FOLDER_SEPARATOR) {
				pathname *Q = Pathnames::subfolder(P, LEAFNAME);
				Extensions::location_recursively(Q, N, req, search_results);
			} else {
				if (Str::suffix_eq(LEAFNAME, I".i7x", 4)) {
					filename *F = Filenames::in_folder(P, LEAFNAME);
					inbuild_copy *C = Extensions::claim_file(F);
					if (Requirements::meets(C->edition, req)) {
						Nests::add_search_result(search_results, N, C);
					}
				}
			}
		}
		DISCARD_TEXT(LEAFNAME);
		Directories::close(D);
	}
}

void Extensions::copy_to_nest(inbuild_genre *gen, inbuild_copy *C, inbuild_nest *N, int syncing) {
	internal_error("unimplemented");
}

typedef struct inform_extension {
	struct inbuild_copy *as_copy;
	struct inbuild_version_number version_loaded; /* As actually loaded */
	#ifdef CORE_MODULE
	struct wording body_text; /* Body of source text supplied in extension, if any */
	int body_text_unbroken; /* Does this contain text waiting to be sentence-broken? */
	struct wording documentation_text; /* Documentation supplied in extension, if any */
	int loaded_from_built_in_area; /* Located within Inform application */
	int authorial_modesty; /* Do not credit in the compiled game */
	struct source_file *read_into_file; /* Which source file loaded this */
	struct text_stream *rubric_as_lexed;
	struct text_stream *extra_credit_as_lexed;
	#endif
	MEMORY_MANAGEMENT
} inform_extension;

inform_extension *Extensions::load_at(text_stream *title, text_stream *author, filename *F) {
	inform_extension *E = CREATE(inform_extension);

	inbuild_work *work = Works::new(extension_genre, title, author);
	inbuild_edition *edition = Model::edition(work, VersionNumbers::null());
	E->as_copy = Model::copy_in_file(edition, F, STORE_POINTER_inform_extension(E));
	
	E->version_loaded = VersionNumbers::null();

	#ifdef CORE_MODULE
	E->body_text = EMPTY_WORDING;
	E->body_text_unbroken = FALSE;
	E->documentation_text = EMPTY_WORDING;
	E->loaded_from_built_in_area = FALSE;
	E->authorial_modesty = FALSE;
	E->rubric_as_lexed = NULL;
	E->extra_credit_as_lexed = NULL;	
	#endif
//	build_graph *EV = 
	Graphs::copy_vertex(E->as_copy);
	return E;
}

inform_extension *Extensions::from_copy(inbuild_copy *C) {
	if ((C) && (C->edition->work->genre == extension_genre)) {
		return RETRIEVE_POINTER_inform_extension(C->content);
	}
	return NULL;
}
