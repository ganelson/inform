[RTBibliographicData::] Bibliographic Data.

Recording bibliographic data, such as title and authorship, in Inter.

@ Bibliographic data is significant at run-time because the kits contain
code to print out the "banner" at the start of play, which is a sort of
title page. So they need to know the title, and so on.

Note that some of the bibliographic variables are actually compiled to
constants.

=
int encode_constant_text_bibliographically = FALSE; /* Compile literal text semi-literally */

int RTBibliographicData::in_bibliographic_mode(void) {
	return encode_constant_text_bibliographically;
}

void RTBibliographicData::compile_constants(void) {
	encode_constant_text_bibliographically = TRUE;
	if (story_title_VAR) @<Compile the I6 Story constant@>;
	if (story_headline_VAR) @<Compile the I6 Headline constant@>;
	if (story_author_VAR) @<Compile the I6 Story Author constant@>;
	if (story_release_number_VAR) @<Compile the I6 Release directive@>;
	@<Compile the I6 serial number, based on the date@>;
	@<Compile metadata@>;
	encode_constant_text_bibliographically = FALSE;
}

@ If the author doesn't name a work, then its title is properly "", not
"Welcome": that's just something we use to provide a readable banner.

@<Compile the I6 Story constant@> =
	inter_name *iname = Hierarchy::find(STORY_HL);
	if (VariableSubjects::has_initial_value_set(story_title_VAR)) {
		NonlocalVariables::initial_value_as_plain_text(story_title_VAR);
		Emit::initial_value_as_constant(iname, story_title_VAR);
		Emit::initial_value_as_raw_text(Hierarchy::find(STORY_MD_HL),
			story_title_VAR);
	} else {
		Emit::text_constant_from_wide_string(iname, U"\"Welcome\"");
		Emit::text_constant(Hierarchy::find(STORY_MD_HL), I"Untitled");
	}
	Hierarchy::make_available(iname);

@ And similarly here:

@<Compile the I6 Headline constant@> =
	inter_name *iname = Hierarchy::find(HEADLINE_HL);
	if (VariableSubjects::has_initial_value_set(story_headline_VAR)) {
		NonlocalVariables::initial_value_as_plain_text(story_headline_VAR);
		Emit::initial_value_as_constant(iname, story_headline_VAR);
		Emit::initial_value_as_raw_text(Hierarchy::find(HEADLINE_MD_HL),
			story_headline_VAR);
	} else {
		Emit::text_constant_from_wide_string(iname, U"\"An Interactive Fiction\"");
		Emit::text_constant(Hierarchy::find(HEADLINE_MD_HL), I"An Interactive Fiction");
	}
	Hierarchy::make_available(iname);

@ This time we compile a zero constant if no author is provided:

@<Compile the I6 Story Author constant@> =
	if (VariableSubjects::has_initial_value_set(story_author_VAR)) {
		inter_name *iname = Hierarchy::find(STORY_AUTHOR_HL);
		NonlocalVariables::initial_value_as_plain_text(story_author_VAR);
		Emit::initial_value_as_constant(iname, story_author_VAR);
		Hierarchy::make_available(iname);
		Emit::initial_value_as_raw_text(Hierarchy::find(AUTHOR_MD_HL),
			story_author_VAR);
	} else {
		inter_name *iname = Hierarchy::find(STORY_AUTHOR_HL);
		Emit::unchecked_numeric_constant(iname, 0);
		Hierarchy::make_available(iname);
		Emit::text_constant(Hierarchy::find(AUTHOR_MD_HL), I"Anonymous");
	}

@ Similarly (but numerically):

@<Compile the I6 Release directive@> =
	if (VariableSubjects::has_initial_value_set(story_release_number_VAR)) {
		inter_name *iname = Hierarchy::find(RELEASE_HL);
		Emit::initial_value_as_constant(iname, story_release_number_VAR);
		Hierarchy::make_available(iname);
	}
	Emit::initial_value_as_constant(Hierarchy::find(RELEASE_MD_HL),
		story_release_number_VAR);
	semantic_version_number V = Projects::get_version(Task::project());
	if (VersionNumbers::is_null(V) == FALSE) {
		inter_name *iname = Hierarchy::find(STORY_VERSION_MD_HL);
		TEMPORARY_TEXT(v)
		WRITE_TO(v, "%v", &V);
		Emit::text_constant(iname, v);
		DISCARD_TEXT(v)
	}

@ This innocuous code -- if Inform runs on 25 June 2013, we compile the serial
number "130625" -- is actually controversial: quite a few users feel they
should be able to fake the date-stamp with dates of their own choosing.

@<Compile the I6 serial number, based on the date@> =
	inter_name *iname = Hierarchy::find(SERIAL_HL);
	TEMPORARY_TEXT(SN)
	int year_digits = (the_present->tm_year) % 100;
	WRITE_TO(SN, "%02d%02d%02d",
		year_digits, (the_present->tm_mon)+1, the_present->tm_mday);
	Emit::text_constant(Hierarchy::find(SERIAL_MD_HL), SN);
	Emit::serial_number(iname, SN);
	DISCARD_TEXT(SN)
	Hierarchy::make_available(iname);

@ Then there are metadata details which will be used in indexing, but which do
not compile to any data in the object code:

@<Compile metadata@> =
	Emit::text_constant(Hierarchy::find(IFID_MD_HL), BibliographicData::read_uuid());
	TEMPORARY_TEXT(lang)
	inform_language *L = Projects::get_language_of_play(Task::project());
	if (L == NULL) WRITE_TO(lang, "English");
	else WRITE_TO(lang, "%S", L->as_copy->edition->work->title);
	Emit::text_constant(Hierarchy::find(LANGUAGE_MD_HL), lang);
	DISCARD_TEXT(lang)
	int E = BibliographicData::episode_number();
	if (E >= 0) {
		Emit::numeric_constant(Hierarchy::find(EPISODE_NUMBER_MD_HL), (inter_ti) E);
		TEMPORARY_TEXT(series)
		WRITE_TO(series, "%w", BibliographicData::series_name());
		Emit::text_constant(Hierarchy::find(SERIES_NAME_MD_HL), series);
		DISCARD_TEXT(series)
	}
	if (VariableSubjects::has_initial_value_set(story_description_VAR)) {
		Emit::initial_value_as_raw_text(Hierarchy::find(DESCRIPTION_MD_HL),
			story_description_VAR);
	} else {
		Emit::text_constant(Hierarchy::find(DESCRIPTION_MD_HL), I"None");
	}
	if (VariableSubjects::has_initial_value_set(story_genre_VAR)) {
		Emit::initial_value_as_raw_text(Hierarchy::find(GENRE_MD_HL),
			story_genre_VAR);
	} else {
		Emit::text_constant(Hierarchy::find(GENRE_MD_HL), I"Fiction");
	}
	if (VariableSubjects::has_initial_value_set(story_creation_year_VAR)) {
		Emit::initial_value_as_raw_text(Hierarchy::find(YEAR_MD_HL),
			story_creation_year_VAR);
	} else {
		Emit::text_constant(Hierarchy::find(YEAR_MD_HL), I"(This year)");
	}
	Emit::initial_value_as_raw_text(Hierarchy::find(LICENCE_MD_HL), story_licence_VAR);
	Emit::initial_value_as_raw_text(Hierarchy::find(COPYRIGHT_MD_HL), story_copyright_VAR);
	Emit::initial_value_as_raw_text(Hierarchy::find(ORIGIN_URL_MD_HL), story_origin_URL_VAR);
	Emit::initial_value_as_raw_text(Hierarchy::find(RIGHTS_HISTORY_MD_HL), story_rights_history_VAR);

@ The IFID is written into the compiled story file, too, both in order
that it can be printed by the VERSION command and to brand the file so
that it can still be identified even if it loses touch with its iFiction
record. We store the IFID in plain text, with a "magic string" identifier
around it, in byte-accessible memory.

=
void RTBibliographicData::IFID_text(void) {
	text_stream *uuid = BibliographicData::read_uuid();
	inter_name *UUID_array_iname = Hierarchy::find(UUID_ARRAY_HL);
	Emit::text_constant(UUID_array_iname, uuid);
	Hierarchy::make_available(UUID_array_iname);
}

inter_name *RTBibliographicData::IFID_iname(void) {
	return Hierarchy::find(UUID_ARRAY_HL);
}

@

=
int RTBibliographicData::story_author_given(void) {
	if ((story_author_VAR) &&
		(VariableSubjects::has_initial_value_set(story_author_VAR)))
		return TRUE;
	return FALSE;
}
