[JSONMetadata::] JSON Metadata.

Managing JSON-encoded metadata files for resources such as kits.

@ Every //inbuild_copy// can optionally contain a pointer to a JSON value called
|metadata_record|. The code in this section reads a file of JSON metadata into
that record, validating it (a) as syntactically correct JSON, (b) as JSON which
matches the Inbuild schema for what copy metadata should look like, and (c) as
identifying the copy which it purports to identify.

In practice, (a) and (b) are delegated to the //foundation: JSON// library.

=
void JSONMetadata::read_metadata_file(inbuild_copy *C, filename *F,
	text_stream *repairing_title, text_stream *repairing_author) {
	JSON_requirement *req = JSONMetadata::requirements();
	TEMPORARY_TEXT(contents)
	TextFiles::read(F, FALSE, "unable to read file of JSON metadata", TRUE,
		&JSONMetadata::read_metadata_file_helper, NULL, contents);
	SVEXPLAIN(2, "(read JSON metadata file found at %f)\n", F);
	text_file_position tfp = TextFiles::at(F, 1);
	JSON_value *obj = JSON::decode(contents, &tfp);
	if ((obj) && (obj->JSON_type == ERROR_JSONTYPE)) {
		@<Report a syntax error in JSON@>;
		return;
	} else {
		@<Validate the JSON read in@>;
	}
	DISCARD_TEXT(contents)
	C->metadata_record = obj;
	@<Examine the "is" member of the metadata object@>;
	@<Police the "needs"@>;
	JSON_value *compatibility = JSON::look_up_object(obj, I"compatibility");
	if (compatibility) @<Extract compatibility@>;
}

void JSONMetadata::read_metadata_file_helper(text_stream *text, text_file_position *tfp,
	void *v_state) {
	text_stream *contents = (text_stream *) v_state;
	WRITE_TO(contents, "%S\n", text);
}

@<Report a syntax error in JSON@> =
	TEMPORARY_TEXT(err)
	WRITE_TO(err, "the metadata contains a syntax error: '%S'", obj->if_error);
	Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
	DISCARD_TEXT(err)	

@<Validate the JSON read in@> =
	linked_list *validation_errors = NEW_LINKED_LIST(text_stream);
	if (JSON::validate(obj, req, validation_errors) == FALSE) {
		text_stream *err;
		LOOP_OVER_LINKED_LIST(err, text_stream, validation_errors) {
			TEMPORARY_TEXT(msg)
			WRITE_TO(msg, "the metadata did not validate: '%S'", err);
			Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, msg));
			DISCARD_TEXT(msg)
		}
		return;
	}

@<Examine the "is" member of the metadata object@> =
	JSON_value *is = JSON::look_up_object(obj, I"is");
	JSON_value *type = JSON::look_up_object(is, I"type");
	if (type) @<Make sure the type is correct@>;
	JSON_value *title = JSON::look_up_object(is, I"title");
	if (title) @<Make sure the title is correct@>;
	JSON_value *author = JSON::look_up_object(is, I"author");
	if (author) @<Make sure the author is correct@>;
	JSON_value *version = JSON::look_up_object(is, I"version");
	if (version) @<Read the version number and apply it@>;
	JSON_value *version_range = JSON::look_up_object(is, I"version-range");
	if (version_range) @<Forbid the use of a version range@>;

@ So, for example, if this file is from what we think is a kit, then it needs
to say that |is.type| is |"kit"|.

@<Make sure the type is correct@> =
	text_stream *type_text = type->if_string;
	text_stream *required_text = I"<unknown";
	if (C->edition->work->genre == kit_genre) required_text = I"kit";
	if (C->edition->work->genre == extension_genre) required_text = I"extension";
	if (C->edition->work->genre == extension_bundle_genre) required_text = I"extension";
	if (C->edition->work->genre == language_genre) required_text = I"language";
	if (C->edition->work->genre == project_file_genre) required_text = I"project";
	if (C->edition->work->genre == project_bundle_genre) required_text = I"project";
	if (Str::ne(type_text, required_text)) {
		TEMPORARY_TEXT(msg)
		WRITE_TO(msg, "the metadata misidentifies the type as '%S', but it should be '%S'",
			type_text, required_text);
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, msg));
		DISCARD_TEXT(msg)
	}
	JSON_value *kit_details = JSON::look_up_object(obj, I"kit-details");
	if ((kit_details) && (Str::ne(type_text, I"kit"))) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "the metadata contains kit-details but is not for a kit");
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)
	}
	JSON_value *extension_details = JSON::look_up_object(obj, I"extension-details");
	if ((extension_details) && (Str::ne(type_text, I"extension"))) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "the metadata contains extension-details but is not for an extension");
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)
	}
	JSON_value *language_details = JSON::look_up_object(obj, I"language-details");
	if ((language_details) && (Str::ne(type_text, I"language"))) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "the metadata contains language-details but is not for a language");
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)
	}
	JSON_value *project_details = JSON::look_up_object(obj, I"project-details");
	if ((project_details) && (Str::ne(type_text, I"project"))) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "the metadata contains project-details but is not for a project");
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)
	}

@<Make sure the title is correct@> =
	WRITE_TO(repairing_title, "%S", title->if_string);
	if (Str::ne(title->if_string, C->edition->work->title)) {
		if (repairing_title) {
			;
		} else {
			TEMPORARY_TEXT(err)
			if (Str::len(C->edition->work->title) > 0)
				WRITE_TO(err, "the metadata says the title is '%S' when it should be '%S'",
					title->if_string, C->edition->work->title);
			else
				WRITE_TO(err, "the metadata says the title is '%S' but it is untitled",
					title->if_string);
			Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)
		}
	}

@<Make sure the author is correct@> =
	WRITE_TO(repairing_author, "%S", author->if_string);
	if (Str::ne(author->if_string, C->edition->work->author_name)) {
		if (repairing_author) {
			;
		} else {
			TEMPORARY_TEXT(err)
			if (Str::len(C->edition->work->author_name) > 0)
				WRITE_TO(err, "the metadata says the author is '%S' when it should be '%S'",
					author->if_string, C->edition->work->author_name);
			else
				WRITE_TO(err, "the metadata says the author is '%S', but it has no author",
					author->if_string);
			Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)
		}
	}

@ Unlike those tests, here we simply trust the metadata to be correctly supplying
a version number.

@<Read the version number and apply it@> =
	semantic_version_number V = VersionNumbers::from_text(version->if_string);
	if (VersionNumbers::is_null(V)) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "cannot read version number '%S'", version->if_string);
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)
	} else {
		C->edition->version = VersionNumbers::from_text(version->if_string);
	}

@<Forbid the use of a version range@> =
	TEMPORARY_TEXT(err)
	WRITE_TO(err, "the metadata should specify an exact version, not a range");
	Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
	DISCARD_TEXT(err)	

@ It would have been possible to write the schema in a way which would exclude
the possibilities blocked here, but only by making it cumbersome. Besides,
checking here results in more explicit error messages.

@<Police the "needs"@> =
	JSON_value *needs = JSON::look_up_object(obj, I"needs");
	if (needs) {
		JSON_value *E;
		LOOP_OVER_LINKED_LIST(E, JSON_value, needs->if_list) {
			JSON_value *if_clause = JSON::look_up_object(E, I"if");
			JSON_value *unless_clause = JSON::look_up_object(E, I"unless");
			JSON_value *needs_clause = JSON::look_up_object(E, I"needs");
			if ((if_clause) && (unless_clause)) {
				TEMPORARY_TEXT(err)
				WRITE_TO(err, "cannot give both 'if' and 'unless' in same requirement");
				Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
				DISCARD_TEXT(err)	
			}
			JSONMetadata::not_both(C, if_clause, I"'if' clause of a requirement");
			JSONMetadata::not_both(C, unless_clause, I"'unless' clause of a requirement");
			JSONMetadata::not_both(C, needs_clause, I"'needs' clause of a requirement");
		}
	}

@ All very pedantic, but:

=
void JSONMetadata::not_both(inbuild_copy *C, JSON_value *clause, text_stream *where) {
	if (clause) {
		JSON_value *version = JSON::look_up_object(clause, I"version");
		JSON_value *version_range = JSON::look_up_object(clause, I"version-range");
		if ((version) && (version_range)) {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "%S specifies both a version and a version-range", where);
			Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)	
		}
		if (version) {
			semantic_version_number V = VersionNumbers::from_text(version->if_string);
			if (VersionNumbers::is_null(V)) {
				TEMPORARY_TEXT(err)
				WRITE_TO(err, "cannot read version '%S' in %S", version->if_string, where);
				Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
				DISCARD_TEXT(err)
			}
		}
		if (version_range) {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "'version-range' is not yet supported in %S", where);
			Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
			DISCARD_TEXT(err)
		}
	}
}

@<Extract compatibility@> =
	compatibility_specification *CS = Compatibility::from_text(compatibility->if_string);
	if (CS) C->edition->compatibility = CS;
	else {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "cannot read compatibility '%S'", compatibility->if_string);
		Copies::attach_error(C, CopyErrors::new_T(METADATA_MALFORMED_CE, -1, err));
		DISCARD_TEXT(err)
	}

@ The following returns the schema needed for (b); we will load it in from a file
in the Inform/Inbuild installation, but will then cache the result so that it
loads only once.

=
dictionary *JSON_resource_metadata_requirements = NULL;

JSON_requirement *JSONMetadata::requirements(void) {
	if (JSON_resource_metadata_requirements == NULL) {
		filename *F = InstalledFiles::filename(RESOURCE_JSON_REQS_IRES);
		JSON_resource_metadata_requirements = JSON::read_requirements_file(NULL, F);
	}
	JSON_requirement *req =
		JSON::look_up_requirements(JSON_resource_metadata_requirements, I"resource-metadata");
	if (req == NULL) internal_error("JSON metadata file did not define <resource-metadata>");
	return req;
}
