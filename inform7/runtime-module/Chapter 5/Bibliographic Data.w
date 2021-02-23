[RTBibliographicData::] Bibliographic Data.

@ Bibliographic data is significant at run-time because the kits contain
code to print out the "banner" at the start of play, which is a sort of
title page. So they need to know the title, and so on.

Note that some of the bibliographic variables are actually compiled to
constants.

=
void RTBibliographicData::compile_constants(void) {
	encode_constant_text_bibliographically = TRUE;
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(COMPILE_TEXT_TO_I6_CMODE);

	if (story_title_VAR) @<Compile the I6 Story constant@>;
	if (story_headline_VAR) @<Compile the I6 Headline constant@>;
	if (story_author_VAR) @<Compile the I6 Story Author constant@>;
	if (story_release_number_VAR) @<Compile the I6 Release directive@>;
	@<Compile the I6 serial number, based on the date@>;

	END_COMPILATION_MODE;
	encode_constant_text_bibliographically = FALSE;
}

@ If the author doesn't name a work, then its title is properly "", not
"Welcome": that's just something we use to provide a readable banner.

@<Compile the I6 Story constant@> =
	inter_name *iname = Hierarchy::find(STORY_HL);
	NonlocalVariables::initial_value_as_plain_text(story_title_VAR);
	inter_ti v1 = 0, v2 = 0;
	if (VariableSubjects::has_initial_value_set(story_title_VAR))
		RTVariables::seek_initial_value(iname, &v1, &v2, story_title_VAR);
	else
		TextLiterals::compile_literal_from_text(iname, &v1, &v2, L"\"Welcome\"");
	Emit::named_generic_constant(iname, v1, v2);
	Hierarchy::make_available(Emit::tree(), iname);

@ And similarly here:

@<Compile the I6 Headline constant@> =
	inter_name *iname = Hierarchy::find(HEADLINE_HL);
	inter_ti v1 = 0, v2 = 0;
	if (VariableSubjects::has_initial_value_set(story_headline_VAR)) {
		NonlocalVariables::initial_value_as_plain_text(story_headline_VAR);
		RTVariables::seek_initial_value(iname, &v1, &v2, story_headline_VAR);
	} else {
		TextLiterals::compile_literal_from_text(iname, &v1, &v2, L"\"An Interactive Fiction\"");
	}
	Emit::named_generic_constant(iname, v1, v2);
	Hierarchy::make_available(Emit::tree(), iname);

@ This time we compile nothing if no author is provided:

@<Compile the I6 Story Author constant@> =
	if (VariableSubjects::has_initial_value_set(story_author_VAR)) {
		inter_name *iname = Hierarchy::find(STORY_AUTHOR_HL);
		inter_ti v1 = 0, v2 = 0;
		NonlocalVariables::initial_value_as_plain_text(story_author_VAR);
		RTVariables::seek_initial_value(iname, &v1, &v2, story_author_VAR);
		Emit::named_generic_constant(iname, v1, v2);
		Hierarchy::make_available(Emit::tree(), iname);
		global_compilation_settings.story_author_given = TRUE;
	} else {
		inter_name *iname = Hierarchy::find(STORY_AUTHOR_HL);
		inter_ti v1 = LITERAL_IVAL, v2 = 0;
		Emit::named_generic_constant(iname, v1, v2);
		Hierarchy::make_available(Emit::tree(), iname);
	}

@ Similarly (but numerically):

@<Compile the I6 Release directive@> =
	if (VariableSubjects::has_initial_value_set(story_release_number_VAR)) {
		inter_name *iname = Hierarchy::find(RELEASE_HL);
		inter_ti v1 = 0, v2 = 0;
		RTVariables::seek_initial_value(iname, &v1, &v2, story_release_number_VAR);
		Emit::named_generic_constant(iname, v1, v2);
		Hierarchy::make_available(Emit::tree(), iname);
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
	Emit::named_text_constant(iname, SN);
	DISCARD_TEXT(SN)
	Hierarchy::make_available(Emit::tree(), iname);

@ The IFID is written into the compiled story file, too, both in order
that it can be printed by the VERSION command and to brand the file so
that it can still be identified even if it loses touch with its iFiction
record. We store the IFID in plain text, with a "magic string" identifier
around it, in byte-accessible memory.

=
void RTBibliographicData::IFID_text(void) {
	text_stream *uuid = BibliographicData::read_uuid();
	inter_name *UUID_array_iname = Hierarchy::find(UUID_ARRAY_HL);
	Emit::named_string_constant(UUID_array_iname, uuid);
	Hierarchy::make_available(Emit::tree(), UUID_array_iname);
}

inter_name *RTBibliographicData::IFID_iname(void) {
	return Hierarchy::find(UUID_ARRAY_HL);
}

