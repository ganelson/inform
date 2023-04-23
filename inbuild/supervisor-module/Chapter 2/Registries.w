[Registries::] Registries.

Registries are nests provided with metadata and intended to be presented as
an online source from which Inform resources can be downloaded.

@h Creation.
To "create" a registry here does not mean actually altering the file system, for
example by making a directory: registries here are merely notes in memory of
positions in the file system hierarchy which may or may not exist.

=
typedef struct inbuild_registry {
	struct pathname *location;
	struct inbuild_nest *nest;
	struct JSON_value *roster;
	CLASS_DEFINITION
} inbuild_registry;

@ =
inbuild_registry *Registries::new(pathname *P) {
	inbuild_registry *N = CREATE(inbuild_registry);
	N->location = P;
	N->nest = Nests::new(Pathnames::down(P, I"payloads"));
	N->roster = NULL;
	return N;
}

@h The roster.
This is a JSON file called |roster.json|, whose schema must match the one specified
by the file |registry-metadata.jsonr| in the standard Inform distribution.

The following silently returns |TRUE| if it does, or prints errors and returns
|FALSE| if not (or if it doesn't exist).

=
int Registries::read_roster(inbuild_registry *R) {
	if (R == NULL) internal_error("no registry");
	R->roster = NULL;
	filename *F = Filenames::in(R->location, I"roster.json");
	if (TextFiles::exists(F) == FALSE) {
		WRITE_TO(STDERR, "%f: roster file does not exist\n", F);
		return FALSE;
	}
	TEMPORARY_TEXT(contents)
	TextFiles::read(F, FALSE, "unable to read file of JSON metadata", TRUE,
		&JSONMetadata::read_metadata_file_helper, NULL, contents);
	text_file_position tfp = TextFiles::at(F, 1);
	JSON_value *obj = JSON::decode(contents, &tfp);
	DISCARD_TEXT(contents)
	if ((obj) && (obj->JSON_type == ERROR_JSONTYPE)) {
		WRITE_TO(STDERR, "%f: JSON syntax error: %S\n", F, obj->if_error);
		return FALSE;
	} else {
		JSON_requirement *req = Registries::requirements();
		linked_list *validation_errors = NEW_LINKED_LIST(text_stream);
		if (JSON::validate(obj, req, validation_errors) == FALSE) {
			text_stream *err;
			LOOP_OVER_LINKED_LIST(err, text_stream, validation_errors) {
				WRITE_TO(STDERR, "%f: metadata did not validate: '%S'\n", F, err);
			}
			return FALSE;
		}
	}
	R->roster = obj;
	return TRUE;
}

@ The following schema validates the metadata for a registry, and is cached
so that it only needs to load once.

=
dictionary *JSON_registry_metadata_requirements = NULL;

JSON_requirement *Registries::requirements(void) {
	if (JSON_registry_metadata_requirements == NULL) {
		filename *F = InstalledFiles::filename(REGISTRY_JSON_REQS_IRES);
		JSON_registry_metadata_requirements = JSON::read_requirements_file(NULL, F);
	}
	JSON_requirement *req =
		JSON::look_up_requirements(JSON_registry_metadata_requirements, I"registry-metadata");
	if (req == NULL) internal_error("JSON metadata file did not define <registry-metadata>");
	return req;
}

@h Building.
To "build" a registry doesn't involve very much: just putting some indexing
files together, using the preprocessor built into //foundation//.

If the registry is |R|, we preprocess each file |R/source/X.Y| into |R/X.Y|:

=
void Registries::build(inbuild_registry *R) {
	if (R == NULL) internal_error("no registry");
	linked_list *ML = NEW_LINKED_LIST(preprocessor_macro);
	@<Construct the list of custom macros for this sort of preprocessing@>;
	pathname *S = Pathnames::down(R->location, I"source");
	linked_list *L = Directories::listing(S);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry)) == FALSE) {
			filename *F = Filenames::in(S, entry);
			TEMPORARY_TEXT(EXT)
			Filenames::write_extension(EXT, F);
			if (Str::len(EXT) > 0) {
				filename *T = Filenames::in(R->location, Filenames::get_leafname(F));
				WRITE_TO(STDOUT, "%f -> %f\n", F, T);
				Preprocessor::preprocess(F, T, NULL, ML,
					STORE_POINTER_inbuild_registry(R), '#', UTF8_ENC);
			}
			DISCARD_TEXT(EXT)
		}
	}
}

@<Construct the list of custom macros for this sort of preprocessing@> =
	Preprocessor::new_macro(ML, I"include", I"file: LEAFNAME",
		Registries::include_expander, NULL);
	Preprocessor::new_macro(ML, I"include-css", I"?platform: PLATFORM",
		Registries::css_expander, NULL);
	Preprocessor::new_macro(ML, I"process", I"file: LEAFNAME",
		Registries::process_expander, NULL);
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"section", I"of: ID",
		Registries::section_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"subsection", I"of: ID",
		Registries::subsection_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"author", I"of: ID ?escape: WHICH",
		Registries::author_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"title", I"of: ID ?escape: WHICH",
		Registries::title_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"version", I"of: ID ?escape: WHICH",
		Registries::version_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"summary", I"of: ID ?escape: WHICH",
		Registries::summary_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"forum-thread", I"of: ID",
		Registries::thread_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"section-mark", I"of: ID",
		Registries::section_mark_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"section-title", I"of: ID",
		Registries::section_title_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"subsection-mark", I"of: ID",
		Registries::subsection_mark_expander, NULL));
	Preprocessor::do_not_suppress_whitespace(
		Preprocessor::new_macro(ML, I"subsection-title", I"of: ID",
		Registries::subsection_title_expander, NULL));
	Preprocessor::new_loop_macro(ML, I"sections", NULL,
		Registries::sections_expander, NULL);
	Preprocessor::new_loop_macro(ML, I"subsections", I"in: SECTION",
		Registries::subsections_expander, NULL);
	Preprocessor::new_loop_macro(ML, I"resources", I"in: SECTION",
		Registries::resources_expander, NULL);
	Preprocessor::new_loop_macro(ML, I"if-forum-thread", I"for: ID",
		Registries::if_forum_thread_expander, NULL);

@ |{include file:I}| splices in the file |R/source/include/I|, unmodified.
It can contain any textual material, and even braces and backslashes pass
through exactly as written.

=
void Registries::include_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *leafname = parameter_values[0];
	filename *prototype = Filenames::in(Pathnames::down(Pathnames::down(R->location, I"source"), I"include"), leafname);
	TextFiles::read(prototype, FALSE, "can't open include file",
		TRUE, Registries::scan_line, NULL, PPS);
}

void Registries::scan_line(text_stream *line, text_file_position *tfp, void *X) {
	preprocessor_state *PPS = (preprocessor_state *) X;
	WRITE_TO(PPS->dest, "%S\n", line);
}

@ |{process file:I}| also splices in the file |R/source/include/I|, but runs
it through the preprocessor first. This means any macros it contains will be
expanded, and it has to comply with the syntax rules on use of braces and
backslash.

=
void Registries::process_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *leafname = parameter_values[0];
	filename *prototype = Filenames::in(Pathnames::down(Pathnames::down(R->location, I"source"), I"include"), leafname);
	TextFiles::read(prototype, FALSE, "can't open include file",
		TRUE, Preprocessor::scan_line, NULL, PPS);
}

@ |{include-css platform:P}| splices in the Inform distribution's standard CSS
files for the named platform. It's an |include|, not a |process|.

=
void Registries::css_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	text_stream *platform = parameter_values[0];
	filename *prototype = InstalledFiles::filename_for_platform(CSS_SET_BY_PLATFORM_IRES, platform);
	WRITE_TO(PPS->dest, "<style type=\"text/css\">\n");
	WRITE_TO(PPS->dest, "<!--\n");
	TextFiles::read(prototype, FALSE, "can't open include file",
		TRUE, Registries::scan_line, NULL, PPS);
	prototype = InstalledFiles::filename_for_platform(CSS_FOR_STANDARD_PAGES_IRES, platform);
	TextFiles::read(prototype, FALSE, "can't open include file",
		TRUE, Registries::scan_line, NULL, PPS);
	WRITE_TO(PPS->dest, "--></style>\n");
}

@ |{sections}| ... |{end-sections}| is a loop construct, which loops over each
section of the registry's roster file. The loop variable |{SECTIONID}| holds
the ID text for the section; right now, that's just |0|, |1|, |2|, ...

=
void Registries::sections_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	Preprocessor::set_loop_var_name(loop, I"SECTIONID");
	JSON_value *sections = JSON::look_up_object(R->roster, I"sections");
	if (sections == NULL) internal_error("could not find roster sections");
	JSON_value *E;
	int i = 0;
	LOOP_OVER_LINKED_LIST(E, JSON_value, sections->if_list) {
		text_stream *sid = Str::new();
		WRITE_TO(sid, "%d", i++);
		Preprocessor::add_loop_iteration(loop, sid);
	}
}

@ |{subsections in: SID}| ... |{end-subsections}| loops similarly over all
subsections in the section with id |SID|. The loop variable is |{SUBSECTIONID}|.
This also now counts up from 0 (but textually: all preprocessor variables are
text), but note that this SSID is unique in the registry: i.e., it doesn't go back
to |0| at the start of each section.

=
void Registries::subsections_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	text_stream *in = parameter_values[0];
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	Preprocessor::set_loop_var_name(loop, I"SUBSECTIONID");
	JSON_value *sections = JSON::look_up_object(R->roster, I"sections");
	if (sections == NULL) internal_error("could not find roster sections");
	JSON_value *E;
	int i = 0, j = 0;
	LOOP_OVER_LINKED_LIST(E, JSON_value, sections->if_list) {
		TEMPORARY_TEXT(sid)
		WRITE_TO(sid, "%d", i++);
		JSON_value *subsections = JSON::look_up_object(E, I"subsections");
		if (subsections == NULL) internal_error("could not find roster subsections");
		JSON_value *F;
		LOOP_OVER_LINKED_LIST(F, JSON_value, subsections->if_list) {
			if (Str::eq(sid, in)) {
				text_stream *ssid = Str::new();
				WRITE_TO(ssid, "%d", j);
				Preprocessor::add_loop_iteration(loop, ssid);
			}
			j++;
		}
		DISCARD_TEXT(sid)
	}
}

@ |{resources in: SSID}| ... |{end-resources}| loops similarly over all
resources in the subsection with id |SSID|, or over absolutely all resources
if the id is given as |ALL|. The loop variable is |{ID}|.

=
void Registries::resources_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	text_stream *in = parameter_values[0];
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	Preprocessor::set_loop_var_name(loop, I"ID");
	JSON_value *sections = JSON::look_up_object(R->roster, I"sections");
	if (sections == NULL) internal_error("could not find roster sections");
	JSON_value *E;
	int j = 0, k = 0;
	LOOP_OVER_LINKED_LIST(E, JSON_value, sections->if_list) {
		JSON_value *subsections = JSON::look_up_object(E, I"subsections");
		if (subsections == NULL) internal_error("could not find roster subsections");
		JSON_value *F;
		LOOP_OVER_LINKED_LIST(F, JSON_value, subsections->if_list) {
			TEMPORARY_TEXT(ssid)
			WRITE_TO(ssid, "%d", j++);
			JSON_value *holdings = JSON::look_up_object(F, I"holdings");
			if (holdings == NULL) internal_error("could not find roster holdings");
			JSON_value *G;
			LOOP_OVER_LINKED_LIST(G, JSON_value, holdings->if_list) {
				if ((Str::eq(in, I"ALL")) || (Str::eq(ssid, in))) {
					text_stream *id = Str::new();
					WRITE_TO(id, "%d", k);
					Preprocessor::add_loop_iteration(loop, id);
				}
				k++;
			}
			DISCARD_TEXT(ssid)
		}
	}
}

@ We now have a run of macros which give details of the resource |ID|.

First, |{section of: ID}| produces the SID of its section.

=
void Registries::section_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	TEMPORARY_TEXT(section)
	JSON_value *res = Registries::resource_from_textual_id(R, of, section, NULL);
	if (res) WRITE_TO(PPS->dest, "%S", section);
	DISCARD_TEXT(section)
}

@ |{subsection of: ID}| produces the SSID of its subsection.

=
void Registries::subsection_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	TEMPORARY_TEXT(subsection)
	JSON_value *res = Registries::resource_from_textual_id(R, of, NULL, subsection);
	if (res) WRITE_TO(PPS->dest, "%S", subsection);
	DISCARD_TEXT(subsection)
}

@ |{author of: ID escape: ESC}| produces the author's name, optionally escaped
with the system below.

=
void Registries::author_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	text_stream *escape = parameter_values[1];
	JSON_value *res = Registries::resource_from_textual_id(R, of, NULL, NULL);
	if (res) {
		JSON_value *author = JSON::look_up_object(res, I"author");
		if (author == NULL) internal_error("could not find author");
		Registries::write_escaped(PPS->dest, author->if_string, escape);
	}
}

@ |{title of: ID escape: ESC}| produces the title, optionally escaped with the
system below.

=
void Registries::title_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	text_stream *escape = parameter_values[1];
	JSON_value *res = Registries::resource_from_textual_id(R, of, NULL, NULL);
	if (res) {
		JSON_value *title = JSON::look_up_object(res, I"title");
		if (title == NULL) internal_error("could not find title");
		Registries::write_escaped(PPS->dest, title->if_string, escape);
	}
}

@ |{version of: ID escape: ESC}| produces the version, optionally escaped with the
system below.

=
void Registries::version_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	text_stream *escape = parameter_values[1];
	JSON_value *res = Registries::resource_from_textual_id(R, of, NULL, NULL);
	if (res) {
		JSON_value *version = JSON::look_up_object(res, I"version");
		if (version == NULL) internal_error("could not find version");
		Registries::write_escaped(PPS->dest, version->if_string, escape);
	}
}

@ |{summary of: ID escape: ESC}| produces the summary, optionally escaped with the
system below.

=
void Registries::summary_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	text_stream *escape = parameter_values[1];
	JSON_value *res = Registries::resource_from_textual_id(R, of, NULL, NULL);
	if (res) {
		JSON_value *summary = JSON::look_up_object(res, I"summary");
		if (summary == NULL) internal_error("could not find summary");
		Registries::write_escaped(PPS->dest, summary->if_string, escape);
	}
}

@ |{thread of: ID}| produces the forum thread number, if it exists, and prints
nothing if it does not.

=
void Registries::thread_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	JSON_value *res = Registries::resource_from_textual_id(R, of, NULL, NULL);
	if (res) {
		JSON_value *thread = JSON::look_up_object(res, I"forum-thread");
		if (thread) WRITE_TO(PPS->dest, "%d", thread->if_integer);
	}
}

@ |{if-forum-thread for: ID}| ... |{end-if-forum-thread}| checks whether the
resource has a thread number, and if so, expands the material |...|. This is
crudely done as either a 0- or 1-term loop.

=
void Registries::if_forum_thread_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	text_stream *of_id = parameter_values[0];
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	Preprocessor::set_loop_var_name(loop, I"ID");
	JSON_value *sections = JSON::look_up_object(R->roster, I"sections");
	if (sections == NULL) internal_error("could not find roster sections");
	JSON_value *E;
	int k = 0;
	LOOP_OVER_LINKED_LIST(E, JSON_value, sections->if_list) {
		JSON_value *subsections = JSON::look_up_object(E, I"subsections");
		if (subsections == NULL) internal_error("could not find roster subsections");
		JSON_value *F;
		LOOP_OVER_LINKED_LIST(F, JSON_value, subsections->if_list) {
			JSON_value *holdings = JSON::look_up_object(F, I"holdings");
			if (holdings == NULL) internal_error("could not find roster holdings");
			JSON_value *G;
			LOOP_OVER_LINKED_LIST(G, JSON_value, holdings->if_list) {
				TEMPORARY_TEXT(id)
				WRITE_TO(id, "%d", k++);
				if (Str::eq(id, of_id)) {
					JSON_value *thread = JSON::look_up_object(G, I"forum-thread");
					if (thread) Preprocessor::add_loop_iteration(loop, id);
				}
				DISCARD_TEXT(id)
			}
		}
	}
}

@ |{section-mark of: SID}| produces the "section mark" of the section.

=
void Registries::section_mark_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	TEMPORARY_TEXT(mark)
	JSON_value *section = Registries::section_from_textual_id(R, of, mark);
	if (section) WRITE_TO(PPS->dest, "%S", mark);
	DISCARD_TEXT(mark)
}

@ |{section-title of: SID}| produces the title of the section.

=
void Registries::section_title_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	JSON_value *section = Registries::section_from_textual_id(R, of, NULL);
	if (section) {
		JSON_value *title = JSON::look_up_object(section, I"title");
		if (title == NULL) internal_error("could not find title");
		WRITE_TO(PPS->dest, "%S", title->if_string);
	}
}

@ |{subsection-mark of: SID}| produces the "subsection mark" of the subsection.

=
void Registries::subsection_mark_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	TEMPORARY_TEXT(mark)
	JSON_value *subsection = Registries::subsection_from_textual_id(R, of, NULL, mark);
	if (subsection) WRITE_TO(PPS->dest, "%S", mark);
	DISCARD_TEXT(mark)
}

@ |{subsection-title of: SID}| produces the title of the subsection.

=
void Registries::subsection_title_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	inbuild_registry *R = RETRIEVE_POINTER_inbuild_registry(PPS->specifics);
	text_stream *of = parameter_values[0];
	JSON_value *subsection = Registries::subsection_from_textual_id(R, of, NULL, NULL);
	if (subsection) {
		JSON_value *title = JSON::look_up_object(subsection, I"title");
		if (title == NULL) internal_error("could not find title");
		WRITE_TO(PPS->dest, "%S", title->if_string);
	}
}

@h Escapology.
|quotes| escapes single quotation marks by placing a backslash before them,
as is necessary in JavaScript string literals.

|spaces| escapes spaces as |%20|, as is necessary in URLs.

|both| does both; |neither| does neither.

=
void Registries::write_escaped(OUTPUT_STREAM, text_stream *text, text_stream *escape) {
	if (Str::eq(escape, I"quotes")) {
		LOOP_THROUGH_TEXT(pos, text) {
			wchar_t c = Str::get(pos);
			if (c == '\'') {
				PUT('\\');
				PUT('\'');
			} else {
				PUT(c);
			}
		}
	} else if (Str::eq(escape, I"spaces")) {
		LOOP_THROUGH_TEXT(pos, text) {
			wchar_t c = Str::get(pos);
			if (c == ' ') {
				WRITE("%%20");
			} else {
				PUT(c);
			}
		}
	} else if (Str::eq(escape, I"both")) {
		LOOP_THROUGH_TEXT(pos, text) {
			wchar_t c = Str::get(pos);
			if (c == '\'') {
				PUT('\\');
				PUT('\'');
			} else if (c == ' ') {
				WRITE("%%20");
			} else {
				PUT(c);
			}
		}
	} else if ((Str::eq(escape, I"neither")) || (Str::len(escape) == 0)) {
		WRITE("%S", text);
	} else WRITE_TO(STDERR, "error: no such escape as '%S'\n", escape);
}

@h Looking up by textual ID.
Given a textual resource id |id|, return the JSON object for it, or else
print an error and return |NULL|.

On success, the SID of its section is written to |sectionid|, and the SSID
of its subsection to |subsectionid|.

=
JSON_value *Registries::resource_from_textual_id(inbuild_registry *R, text_stream *id,
	text_stream *sectionid, text_stream *subsectionid) {
	if ((R == NULL) || (R->roster == NULL)) internal_error("bad registry");
	JSON_value *sections = JSON::look_up_object(R->roster, I"sections");
	if (sections == NULL) internal_error("could not find roster sections");
	JSON_value *E;
	int i = 0, j = 0, k = 0;
	LOOP_OVER_LINKED_LIST(E, JSON_value, sections->if_list) {
		JSON_value *subsections = JSON::look_up_object(E, I"subsections");
		if (subsections == NULL) internal_error("could not find roster subsections");
		JSON_value *F;
		LOOP_OVER_LINKED_LIST(F, JSON_value, subsections->if_list) {
			JSON_value *holdings = JSON::look_up_object(F, I"holdings");
			if (holdings == NULL) internal_error("could not find roster holdings");
			JSON_value *G;
			LOOP_OVER_LINKED_LIST(G, JSON_value, holdings->if_list) {
				int match = FALSE;
				TEMPORARY_TEXT(this_id)
				WRITE_TO(this_id, "%d", k);
				if (Str::eq(id, this_id)) match = TRUE;
				DISCARD_TEXT(this_id)
				if (match) {
					WRITE_TO(sectionid, "%d", i);
					WRITE_TO(subsectionid, "%d", j);
					return G;
				}
				k++;
			}
			j++;
		}
		i++;
	}
	WRITE_TO(STDERR, "error: no such resource ID as '%S'\n", id);
	return NULL;
}

@ Similarly for sections, with a |SID|.

The "mark" for a section is 1, 2, 3, ...

=
JSON_value *Registries::section_from_textual_id(inbuild_registry *R, text_stream *sid,
	text_stream *mark) {
	if ((R == NULL) || (R->roster == NULL)) internal_error("bad registry");
	JSON_value *sections = JSON::look_up_object(R->roster, I"sections");
	if (sections == NULL) internal_error("could not find roster sections");
	JSON_value *E;
	int i = 0;
	LOOP_OVER_LINKED_LIST(E, JSON_value, sections->if_list) {
		int match = FALSE;
		TEMPORARY_TEXT(this_sid)
		WRITE_TO(this_sid, "%d", i);
		if (Str::eq(sid, this_sid)) match = TRUE;
		DISCARD_TEXT(this_sid)
		if (match) {
			WRITE_TO(mark, "%d", i+1);
			return E;
		}
		i++;
	}
	WRITE_TO(STDERR, "error: no such section ID as '%S'\n", sid);
	return NULL;
}

@ And subsections, with a |SSID|:

The "mark" for a subsection is 1.1, 1.2, 1.3, ..., 2.1, 2.2, ...

=
JSON_value *Registries::subsection_from_textual_id(inbuild_registry *R, text_stream *ssid,
	text_stream *mark, text_stream *submark) {
	if ((R == NULL) || (R->roster == NULL)) internal_error("bad registry");
	JSON_value *sections = JSON::look_up_object(R->roster, I"sections");
	if (sections == NULL) internal_error("could not find roster sections");
	JSON_value *E;
	int i = 0, j = 0;
	LOOP_OVER_LINKED_LIST(E, JSON_value, sections->if_list) {
		JSON_value *subsections = JSON::look_up_object(E, I"subsections");
		if (subsections == NULL) internal_error("could not find roster subsections");
		int x = 1;
		JSON_value *F;
		LOOP_OVER_LINKED_LIST(F, JSON_value, subsections->if_list) {
			int match = FALSE;
			TEMPORARY_TEXT(this_ssid)
			WRITE_TO(this_ssid, "%d", j);
			if (Str::eq(ssid, this_ssid)) match = TRUE;
			DISCARD_TEXT(this_ssid)
			if (match) {
				WRITE_TO(mark, "%d", i+1);
				WRITE_TO(submark, "%d.%d", i+1, x);
				return F;
			}
			j++, x++;
		}
		i++;
	}
	WRITE_TO(STDERR, "error: no such subsection ID as '%S'\n", ssid);
	return NULL;
}

@h Simpler preprocessing.
A simpler version of the above preprocessor is convenient as a way of manufacting
small HTML files needed in the Inform apps: for example, to display advice text
on the launcher panels. There's nothing interesting about those files except that
they may need platform-specific CSS in order to display properly in Dark Mode,
use congenial fonts, and so on.

We preprocess from |F| to |T|, except that we look to see if there's a platform
variant of the file |F| first: for example, if |F| is |Fruits/bananas.html|, and
the platform is |wii|, then we look for |Fruits/bananas-wii.html| and use that
instead. (If not, we just use |F|.) In practice, for example, this allows the
file in the apps which lists keyboard shortcuts to vary with platform.

=
void Registries::preprocess_HTML(filename *T, filename *F, text_stream *platform) {
	linked_list *ML = NEW_LINKED_LIST(preprocessor_macro);
	Preprocessor::new_macro(ML, I"include-css", I"?platform: PLATFORM",
		Registries::preprocess_css_expander, NULL);
	TEMPORARY_TEXT(variant)
	Filenames::write_unextended_leafname(variant, F);
	WRITE_TO(variant, "-%S", platform);
	Filenames::write_extension(variant, F);
	filename *variant_F = Filenames::in(Filenames::up(F), variant);
	if (TextFiles::exists(variant_F)) F = variant_F;
	DISCARD_TEXT(variant)
	WRITE_TO(STDOUT, "%f -> %f\n", F, T);
	Preprocessor::preprocess(F, T, NULL, ML,
		STORE_POINTER_text_stream(platform), '#', UTF8_ENC);
}

void Registries::preprocess_css_expander(preprocessor_macro *mm, preprocessor_state *PPS,
	text_stream **parameter_values, preprocessor_loop *loop, text_file_position *tfp) {
	text_stream *platform = parameter_values[0];
	if (Str::len(platform) == 0) platform = RETRIEVE_POINTER_text_stream(PPS->specifics);
	filename *prototype = InstalledFiles::filename_for_platform(CSS_SET_BY_PLATFORM_IRES, platform);
	WRITE_TO(PPS->dest, "<style type=\"text/css\">\n");
	WRITE_TO(PPS->dest, "<!--\n");
	TextFiles::read(prototype, FALSE, "can't open include file",
		TRUE, Registries::scan_line, NULL, PPS);
	prototype = InstalledFiles::filename_for_platform(CSS_FOR_STANDARD_PAGES_IRES, platform);
	TextFiles::read(prototype, FALSE, "can't open include file",
		TRUE, Registries::scan_line, NULL, PPS);
	WRITE_TO(PPS->dest, "--></style>\n");
}
