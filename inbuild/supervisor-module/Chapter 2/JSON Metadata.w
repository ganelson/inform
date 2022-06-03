[JSONMetadata::] JSON Metadata.

Managing JSON-encoded metadata files for resources such as kits.

@ Every //inbuild_copy// can optionally contain a pointer to a JSON value called
|metadata_record|. The code in this section reads a file of JSON metadata into
that record, validating it (a) as syntactically correct JSON, (b) as JSON which
matches the Inbuild schema for what copy metadata should look like, and (c) as
identifying the copy which it purports to identify.

In practice, (a) and (b) are delegated to the //foundation: JSON// library.

=
void JSONMetadata::read_metadata_file(inbuild_copy *C, filename *F) {
	JSON_requirement *req = JSONMetadata::requirements();
	TEMPORARY_TEXT(contents)
	TextFiles::read(F, FALSE, "unable to read file of JSON metadata", TRUE,
		&JSONMetadata::read_metadata_file_helper, NULL, contents);
	text_file_position tfp = TextFiles::at(F, 1);
	JSON_value *value = JSON::decode(contents, &tfp);
	if ((value) && (value->JSON_type == ERROR_JSONTYPE)) {
		@<Report a syntax error in JSON@>;
		return;
	} else {
		@<Validate the JSON read in@>;
	}
	DISCARD_TEXT(contents)
	C->metadata_record = value;
	@<Examine the "is" member of the metadata object@>;
}

void JSONMetadata::read_metadata_file_helper(text_stream *text, text_file_position *tfp,
	void *v_state) {
	text_stream *contents = (text_stream *) v_state;
	WRITE_TO(contents, "%S\n", text);
}

@<Report a syntax error in JSON@> =
	TEMPORARY_TEXT(err)
	WRITE_TO(err, "the metadata contains a syntax error: '%S'", value->if_error);
	Copies::attach_error(C, CopyErrors::new_T(KIT_MISWORDED_CE, -1, err));
	DISCARD_TEXT(err)	

@<Validate the JSON read in@> =
	linked_list *validation_errors = NEW_LINKED_LIST(text_stream);
	if (JSON::validate(value, req, validation_errors) == FALSE) {
		text_stream *err;
		LOOP_OVER_LINKED_LIST(err, text_stream, validation_errors) {
			TEMPORARY_TEXT(msg)
			WRITE_TO(msg, "the metadata did not validate: '%S'", err);
			Copies::attach_error(C, CopyErrors::new_T(KIT_MISWORDED_CE, -1, msg));
			DISCARD_TEXT(msg)
		}
		return;
	}

@<Examine the "is" member of the metadata object@> =
	JSON_value *is = JSON::look_up_object(C->metadata_record, I"is");
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
	if (C->edition->work->genre == language_genre) required_text = I"language";
	if (Str::ne(type_text, required_text)) {
		TEMPORARY_TEXT(msg)
		WRITE_TO(msg, "the metadata misidentifies the type as '%S', but it should be '%S'",
			type_text, required_text);
		Copies::attach_error(C, CopyErrors::new_T(KIT_MISWORDED_CE, -1, msg));
		DISCARD_TEXT(msg)
	}

@<Make sure the title is correct@> =
	if (Str::ne(title->if_string, C->edition->work->title)) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "the metadata says the title is '%S' when it should be '%S'",
			title->if_string, C->edition->work->title);
		Copies::attach_error(C, CopyErrors::new_T(KIT_MISWORDED_CE, -1, err));
		DISCARD_TEXT(err)	
	}

@<Make sure the author is correct@> =
	if (Str::ne(author->if_string, C->edition->work->author_name)) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "the metadata says the author is '%S' when it should be '%S'",
			author->if_string, C->edition->work->author_name);
		Copies::attach_error(C, CopyErrors::new_T(KIT_MISWORDED_CE, -1, err));
		DISCARD_TEXT(err)	
	}

@ Unlike those tests, here we simply trust the metadata to be correctly supplying
a version number.

@<Read the version number and apply it@> =
	semantic_version_number V = VersionNumbers::from_text(version->if_string);
	if (VersionNumbers::is_null(V)) {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "cannot read version number '%S'", version->if_string);
		Copies::attach_error(C, CopyErrors::new_T(KIT_MISWORDED_CE, -1, err));
		DISCARD_TEXT(err)
	} else {
		C->edition->version = VersionNumbers::from_text(version->if_string);
	}

@<Forbid the use of a version range@> =
	TEMPORARY_TEXT(err)
	WRITE_TO(err, "the metadata should specify an exact version, not a range");
	Copies::attach_error(C, CopyErrors::new_T(KIT_MISWORDED_CE, -1, err));
	DISCARD_TEXT(err)	

@ The following returns the schema needed for (b); we will load it in from a file
in the Inform/Inbuild installation, but will then cache the result so that it
loads only once.

=
dictionary *JSON_resource_metadata_requirements = NULL;

JSON_requirement *JSONMetadata::requirements(void) {
	if (JSON_resource_metadata_requirements == NULL) {
		filename *F = InstalledFiles::filename(JSON_REQUIREMENTS_IRES);
		JSON_resource_metadata_requirements = JSON::read_requirements_file(NULL, F);
	}
	JSON_requirement *req =
		JSON::look_up_requirements(JSON_resource_metadata_requirements, I"resource-metadata");
	if (req == NULL) internal_error("JSON metadata file did not define <resource-metadata>");
	return req;
}
