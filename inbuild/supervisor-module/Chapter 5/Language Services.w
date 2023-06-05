[Languages::] Language Services.

Behaviour specific to copies of the language genre.

@h Scanning metadata.
Metadata for natural languages is stored in the following structure.
Inform can read and write text in multiple natural languages, though it
needs help to do so: each natural language known to Inform comes from a
small resource folder called its "bundle". (This includes English.)

@e PLAYED_LSUPPORT from 1
@e WRITTEN_LSUPPORT
@e INDEXED_LSUPPORT
@e REPORTED_LSUPPORT

@d MAX_LSUPPORTS 5

=
typedef struct inform_language {
	struct inbuild_copy *as_copy;
	struct wording instance_name; /* instance name, e.g., "German language" */
	struct instance *nl_instance; /* instance, e.g., "German language" */
	struct text_stream *iso_code; /* e.g., "fr" or "de" */
	struct text_stream *translated_name; /* e.g., "Français" or "Deutsch" */
	struct text_stream *native_cue; /* e.g., "en français" or "in deutscher Sprache" */
	struct inform_extension *belongs_to; /* if it does belong to an extension */
	int adaptive_person; /* which person text substitutions are written from */
	int Preform_loaded; /* has a Preform syntax definition been read for this? */
	int supports[MAX_LSUPPORTS];
	CLASS_DEFINITION
} inform_language;

@ This is called as soon as a new copy |C| of the language genre is created.

=
void Languages::scan(inbuild_copy *C) {
	inform_language *L = CREATE(inform_language);
	L->as_copy = C;
	if (C == NULL) internal_error("no copy to scan");
	Copies::set_metadata(C, STORE_POINTER_inform_language(L));
	TEMPORARY_TEXT(sentence_format)
	WRITE_TO(sentence_format, "%S language", C->edition->work->title);
	L->instance_name = Feeds::feed_text(sentence_format);
	DISCARD_TEXT(sentence_format)
	L->nl_instance = NULL;
	L->Preform_loaded = FALSE;
	L->adaptive_person = -1; /* i.e., none yet specified */
	/* these defaults should always be overwritten */
	L->iso_code = I"en";
	L->translated_name = I"English";
	/* but not this one */
	L->native_cue = NULL;
	L->belongs_to = NULL;
	for (int i=0; i<MAX_LSUPPORTS; i++) L->supports[i] = FALSE;

	filename *about_file = Filenames::in(Languages::path_to_bundle(L), I"about.txt");
	if (TextFiles::exists(about_file)) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "a language bundle should no longer use an 'about.txt' file");
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)	
	}
	
	filename *F = Filenames::in(C->location_if_path, I"language_metadata.json");
	if (TextFiles::exists(F)) {
		JSONMetadata::read_metadata_file(C, F, NULL, NULL);
		if (C->metadata_record) {
			JSON_value *language_details =
				JSON::look_up_object(C->metadata_record, I"language-details");
			if (language_details) @<Extract the language details@>
			else {
				TEMPORARY_TEXT(err)
				WRITE_TO(err, "'language_metadata.json' must contain a \"language-details\" field");
				Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
				DISCARD_TEXT(err)	
			}
			JSON_value *needs = JSON::look_up_object(C->metadata_record, I"needs");
			if (needs) {
				TEMPORARY_TEXT(err)
				WRITE_TO(err, "language bundle is not allowed to have 'needs'");
				Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
				DISCARD_TEXT(err)	
			}
		}
	} else {
		SVEXPLAIN(2, "(no JSON metadata file found at %f)\n", F);
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "a language bundle must now provide a 'language_metadata.json' file");
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)	
	}
}

@<Extract the language details@> =
	JSON_value *translated_name = JSON::look_up_object(language_details, I"translated-name");
	if (translated_name) L->translated_name = Str::duplicate(translated_name->if_string);
	
	JSON_value *iso_code = JSON::look_up_object(language_details, I"iso-639-1-code");
	if (iso_code) L->iso_code = Str::duplicate(iso_code->if_string);
	
	JSON_value *translated_syntax_cue = JSON::look_up_object(language_details, I"translated-syntax-cue");
	if (translated_syntax_cue) L->native_cue = Str::duplicate(translated_syntax_cue->if_string);
	
	JSON_value *supports = JSON::look_up_object(language_details, I"supports");
	if (supports) {
		JSON_value *E;
		LOOP_OVER_LINKED_LIST(E, JSON_value, supports->if_list) {
			text_stream *key = E->if_string;
			if (Str::eq(key, I"played")) L->supports[PLAYED_LSUPPORT] = TRUE;
			if (Str::eq(key, I"written")) L->supports[WRITTEN_LSUPPORT] = TRUE;
			if (Str::eq(key, I"indexed")) L->supports[INDEXED_LSUPPORT] = TRUE;
			if (Str::eq(key, I"reported")) L->supports[REPORTED_LSUPPORT] = TRUE;
		}
	}

@ =
pathname *Languages::path_to_bundle(inform_language *L) {
	return L->as_copy->location_if_path;
}
	
@h Logging.

=
void Languages::log(OUTPUT_STREAM, char *opts, void *vL) {
	inform_language *L = (inform_language *) vL;
	if (L == NULL) { LOG("<null-language>"); }
	else { LOG("%S", L->as_copy->edition->work->title); }
}

@h Language code.
This is used when we write the bibliographic data for the work of IF we're
making; this enables online databases like IFDB, and smart interpreters, to
detect the language of play for a story file without actually running it.

=
void Languages::write_ISO_code(OUTPUT_STREAM, inform_language *L) {
	#ifdef CORE_MODULE
	if (L == NULL) L = DefaultLanguage::get(NULL);
	#endif
	WRITE("%S", L->iso_code);
}

@h Support.
Different languages support different levels of translation.

=
int Languages::supports(inform_language *L, int S) {
	if ((S<1) || (S>=MAX_LSUPPORTS)) internal_error("support out of range");
	if (L == NULL) return FALSE;
	return L->supports[S];
}

@h Kit.
Each language needs its own kit of Inter code, if it is going to be used as
a language of play. The following is called only when `L` is the language of
play for `project`:

=
void Languages::add_kit_dependencies_to_project(inform_language *L, inform_project *project) {
	if (L == NULL) internal_error("no language");
	TEMPORARY_TEXT(kitname)
	WRITE_TO(kitname, "%SLanguageKit", L->as_copy->edition->work->title);
	inbuild_work *work = Works::new_raw(kit_genre, kitname, I"");
	inbuild_requirement *req = Requirements::any_version_of(work);
	Projects::add_kit_dependency(project, kitname, L, NULL, req, NULL);
	DISCARD_TEXT(kitname)
}

@h Finding by name.
Given the name of a natural language (e.g., "German") we find the
corresponding definition. That will mean searching for a copy, and that
raises the question of where to look -- in particular, it's important to
include the Materials folder for any relevant project.

=
linked_list *search_list_for_Preform_callback = NULL;
int Languages::read_Preform_definition(inform_language *L, linked_list *S) {
	if (L == NULL) internal_error("no language");
	if (L->Preform_loaded == FALSE) {
		L->Preform_loaded = TRUE;
		search_list_for_Preform_callback = S;
		int n = (*shared_preform_callback)(L);
		if (n == 0) return FALSE;
	}
	return TRUE;
}

@ This function is called only from Preform...

@d PREFORM_LANGUAGE_FROM_NAME_WORDS_CALLBACK Languages::Preform_find

=
inform_language *Languages::Preform_find(text_stream *name) {
	return Languages::find_for(name, search_list_for_Preform_callback);
}

@ ...but this one is more generally available.

=
inform_language *Languages::find_for(text_stream *name, linked_list *search) {
	text_stream *author = NULL;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, name, L"(%c+) [Ll]anguage by (%c+)")) {
		name = mr.exp[0]; author = mr.exp[1];
	} else if (Regexp::match(&mr, name, L"(%c+) by (%c+)")) {
		name = mr.exp[0]; author = mr.exp[1];
	} else if (Regexp::match(&mr, name, L"(%c+) [Ll]anguage")) {
		name = mr.exp[0];
	}
	TEMPORARY_TEXT(title)
	WRITE_TO(title, "%S Language", name);
	inbuild_requirement *extension_req =
		Requirements::any_version_of(Works::new(extension_bundle_genre, title, author));
	inbuild_search_result *extension_R = Nests::search_for_best(extension_req, search);
	DISCARD_TEXT(title)
	if (extension_R) {
		inform_extension *E = Extensions::from_copy(extension_R->copy);
		inbuild_nest *N = Extensions::materials_nest(E);
		if (N) {
			linked_list *longer = NEW_LINKED_LIST(inbuild_nest);
			ADD_TO_LINKED_LIST(N, inbuild_nest, longer);
			inbuild_requirement *req =
				Requirements::any_version_of(Works::new(language_genre, name, I""));
			inbuild_search_result *R = Nests::search_for_best(req, longer);
			if (R) {
				inform_language *L = LanguageManager::from_copy(R->copy);
				L->belongs_to = E;
				Regexp::dispose_of(&mr);
				return L;
			}
		}
	}
	inbuild_requirement *req =
		Requirements::any_version_of(Works::new(language_genre, name, I""));
	inbuild_search_result *R = Nests::search_for_best(req, search);
	Regexp::dispose_of(&mr);
	if (R) return LanguageManager::from_copy(R->copy);
	return NULL;
}

@ Or we can convert the native cue, |en français|, to the name, |French|,
though this will not work for language bundles inside of extensions, and
so the function is now deprecated:

=
text_stream *Languages::find_by_native_cue(text_stream *cue, linked_list *search) {
	SVEXPLAIN(3, "(find language by native cue %S)\n", cue);
	linked_list *results = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(Requirements::anything_of_genre(language_genre), search, results);
	inbuild_search_result *search_result;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, results) {
		inform_language *L = LanguageManager::from_copy(search_result->copy);
		if (Str::eq_insensitive(cue, L->native_cue)) {
			SVEXPLAIN(3, "(found at %p)\n", L->as_copy->location_if_path);
			return L->as_copy->edition->work->title;
		}
	}
	SVEXPLAIN(3, "(not found)\n");
	return NULL;
}

@ Finally, the following Preform nonterminal matches the English-language
name of a language: for example, "French". Unlike the above functions, it
looks only at languages already loaded, and doesn't scan nests for more.

=
<natural-language> internal {
	inform_language *L;
	LOOP_OVER(L, inform_language)
		if (Wordings::match(W, Wordings::first_word(L->instance_name))) {
			==> { -, L };
			return TRUE;
		}
	==> { fail };
}
