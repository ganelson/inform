[Licences::] Licences.

A copy of any genre can in principle have a licence declaration attached to it.

@h Creation.
It could be argued that licences belong to editions, not copies, but we want to
be pragmatic. We're not storing the true state of the legal status of the material
in the copy, only what this copy claims about itself.

=
typedef struct inbuild_licence {
	struct open_source_licence *standard_licence;
	struct inbuild_copy *on_copy;
	struct text_stream *rights_owner;
	int copyright_year;
	int revision_year;
	struct text_stream *origin_URL;
	struct text_stream *rights_history;
	int read_from_JSON;
	int discussed_in_source;
	int modified;
	CLASS_DEFINITION
} inbuild_licence;

@ Copies begin with this blank sort of non-licence:

=
inbuild_licence *Licences::new(inbuild_copy *copy) {
	inbuild_licence *licence = CREATE(inbuild_licence);
	licence->standard_licence = NULL;
	licence->on_copy = copy;
	licence->rights_owner = I"Unknown";
	licence->copyright_year = 1970;
	licence->revision_year = 0;
	licence->origin_URL = NULL;
	licence->rights_history = NULL;
	licence->read_from_JSON = FALSE;
	licence->discussed_in_source = FALSE;
	licence->modified = FALSE;
	return licence;
}

@h Date from a JSON object.
This is the optional |legal-metadata| object in any inbuild-standard JSON
metadata file.

=
void Licences::from_JSON(inbuild_licence *licence, JSON_value *legal_metadata) {
	JSON_value *id = JSON::look_up_object(legal_metadata, I"licence");
	JSON_value *owner = JSON::look_up_object(legal_metadata, I"rights-owner");
	JSON_value *date = JSON::look_up_object(legal_metadata, I"date");
	JSON_value *rev_date = JSON::look_up_object(legal_metadata, I"revision-date");
	JSON_value *url = JSON::look_up_object(legal_metadata, I"origin-url");
	JSON_value *rights = JSON::look_up_object(legal_metadata, I"rights-history");

	if ((id == NULL) || (owner == NULL) || (date == NULL)) return;

	licence->read_from_JSON = TRUE;

	inbuild_copy *C = licence->on_copy;

	licence->standard_licence = NULL;
	if (Str::ne(id->if_string, I"Unspecified")) {
		licence->standard_licence = LicenceData::from_SPDX_id(id->if_string);
		if (licence->standard_licence == NULL) {
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the licence '%S', given in JSON metadata, is not an SPDX standard licence code",
				id->if_string);
			Copies::attach_error(C, CopyErrors::new_T(MALFORMED_LICENCE_CE, -1, error_text));
			DISCARD_TEXT(error_text)
		} else if (licence->standard_licence->deprecated) {
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the licence '%S', is a valid SPDX code but for a licence now deprecated",
				id->if_string);
			Copies::attach_error(C, CopyErrors::new_T(MALFORMED_LICENCE_CE, -1, error_text));
			DISCARD_TEXT(error_text)
		}
	}
	
	licence->rights_owner = Str::duplicate(owner->if_string);
	if (Str::len(licence->rights_owner) == 0)
		Copies::attach_error(C, CopyErrors::new_T(
			MALFORMED_LICENCE_CE, -1, I"the rights owner must be non-empty"));

	licence->copyright_year = date->if_integer;
	if ((licence->copyright_year < 1970) || (licence->copyright_year >= 10000)) {
		TEMPORARY_TEXT(error_text)
		WRITE_TO(error_text,
			"the date '%d' needs to be a four-digit year after 1970", date->if_integer);
		Copies::attach_error(C, CopyErrors::new_T(MALFORMED_LICENCE_CE, -1, error_text));
		DISCARD_TEXT(error_text)
		licence->copyright_year = 1970;
	}

	licence->revision_year = 0;
	if (rev_date) {
		licence->revision_year = rev_date->if_integer;
		if ((licence->revision_year <= licence->copyright_year) ||
			(licence->revision_year >= 10000)) {
			TEMPORARY_TEXT(error_text)
			WRITE_TO(error_text,
				"the revision date '%d' needs to be a four-digit year after the date",
				rev_date->if_integer);
			Copies::attach_error(C, CopyErrors::new_T(MALFORMED_LICENCE_CE, -1, error_text));
			DISCARD_TEXT(error_text)
			licence->revision_year = 0;
		}
	}

	if (url) licence->origin_URL = Str::duplicate(url->if_string);
	else licence->origin_URL = NULL;

	if (rights) licence->rights_history = Str::duplicate(rights->if_string);
	else licence->rights_history = NULL;

	licence->modified = FALSE;
}

@h Data to a JSON object.
And conversely...

=
JSON_value *Licences::to_JSON(inbuild_licence *licence) {
	if (licence == NULL) internal_error("not a licence");

	JSON_value *licence_object = JSON::new_object();
	if (licence->standard_licence == NULL)
		JSON::add_to_object(licence_object, I"licence",
			JSON::new_string(I"Unspecified"));
	else
		JSON::add_to_object(licence_object, I"licence",
			JSON::new_string(licence->standard_licence->SPDX_id));

	JSON::add_to_object(licence_object, I"rights-owner",
		JSON::new_string(licence->rights_owner));

	JSON::add_to_object(licence_object, I"date",
		JSON::new_number(licence->copyright_year));
	if (licence->revision_year > 0)
		JSON::add_to_object(licence_object, I"revision-date",
			JSON::new_number(licence->revision_year));

	if (Str::len(licence->origin_URL) > 0)
		JSON::add_to_object(licence_object, I"origin-url",
			JSON::new_string(licence->origin_URL));

	if (Str::len(licence->rights_history) > 0)
		JSON::add_to_object(licence_object, I"rights-history",
			JSON::new_string(licence->rights_history));

	return licence_object;
}

@h Alteration.

=
void Licences::set_licence(inbuild_licence *licence, open_source_licence *osl) {
	if (licence->standard_licence != osl) {
		licence->standard_licence = osl;
		licence->modified = TRUE;
	}
}

void Licences::set_owner(inbuild_licence *licence, text_stream *owner) {
	if (Str::ne(licence->rights_owner, owner)) {
		licence->rights_owner = Str::duplicate(owner);
		licence->modified = TRUE;
	}
}

void Licences::set_date(inbuild_licence *licence, int date) {
	if (licence->copyright_year != date) {
		licence->copyright_year = date;
		licence->modified = TRUE;
	}
}

void Licences::set_revision_date(inbuild_licence *licence, int date) {
	if (licence->revision_year != date) {
		licence->revision_year = date;
		licence->modified = TRUE;
	}
}

void Licences::set_origin_URL(inbuild_licence *licence, text_stream *URL) {
	if (Str::ne(licence->origin_URL, URL)) {
		licence->origin_URL = Str::duplicate(URL);
		licence->modified = TRUE;
	}
}

void Licences::set_rights_history(inbuild_licence *licence, text_stream *rights_history) {
	if (Str::ne(licence->rights_history, rights_history)) {
		licence->rights_history = Str::duplicate(rights_history);
		licence->modified = TRUE;
	}
}


