[LicenceDeclaration::] Licence Declaration Requests.

Special sentences for declaring details of the licence on an extension or
a project.

@ 

The subject phrase must match:

@e LICENCE_LICENCEDETAIL from 1
@e COPYRIGHT_LICENCEDETAIL
@e URL_LICENCEDETAIL
@e RIGHTS_LICENCEDETAIL

=
<licence-sentence-subject> ::=
	<article> <licence-detail> of/for this extension |     ==> { R[2], - }
	<licence-detail> of/for this extension |               ==> { R[1], - }
	<article> <licence-detail> of/for this story/project | ==> { -(R[2]), - }
	<licence-detail> of/for this story/project |           ==> { -(R[1]), - }
    ... of/for this story/project/extension                ==> @<Issue PM_LicenceDetailUnknown@>;
 
<licence-detail> ::=
	licence/license |                                      ==> { LICENCE_LICENCEDETAIL, - }
	copyright |                                            ==> { COPYRIGHT_LICENCEDETAIL, - }
	origin URL |                                           ==> { URL_LICENCEDETAIL, - }
	rights history                                         ==> { RIGHTS_LICENCEDETAIL, - }

<licence-sentence-object> ::=
	<quoted-text> |										   ==> { pass 1 }
	...                                                    ==> @<Issue PM_LicenceUnquoted@>;

@<Issue PM_LicenceDetailUnknown@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_LicenceDetailUnknown),
		"sets an unknown licencing detail",
		"and should declare 'licence', 'copyright', 'origin URL' or 'rights history'.");
	==> { 0, - };

@<Issue PM_LicenceUnquoted@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_LicenceUnquoted),
		"should give its value in double-quotes",
		"as in the sentence "
		"'The licence for this extension is \"CC-BY-4.0\".'");
	==> { 0, - };

@ 

=
int LicenceDeclaration::licence_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* 'The licence for this extension is "CC-BY-4.0".' */
		case ACCEPT_SMFT:
			if (<licence-sentence-subject>(SW)) {
				int detail = <<r>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				<np-unparsed>(OW);
				V->next->next = <<rp>>;
				if ((detail != 0) && (<licence-sentence-object>(OW))) {
					Word::dequote(Wordings::first_wn(OW));
					inchar32_t *text = Lexer::word_text(Wordings::first_wn(OW));
					TEMPORARY_TEXT(val)
					WRITE_TO(val, "%w", text);
					if (detail > 0)
						LicenceDeclaration::set(TRUE, detail, val, Wordings::first_wn(OW));
					else
						LicenceDeclaration::set(FALSE, -detail, val, Wordings::first_wn(OW));
					DISCARD_TEXT(val)
				}
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ 

=
void LicenceDeclaration::set(int extension, int detail, text_stream *val, int wn) {
	LOG("Ext = %d, detail = %d, val = <%S>\n", extension, detail, val);
	switch (detail) {
		case LICENCE_LICENCEDETAIL: {
			open_source_licence *osl = NULL;
			if (Str::eq(val, I"Unspecified")) { @<Accept licence@>; return; }
			osl = LicenceData::from_SPDX_id(val);
			if (osl == NULL) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_NoSuchLicence),
					"gives a licence unknown to Inform",
					"and must be one of those in the SPDX standard catalogue "
					"of licence IDs, like '\"CC-BY-4.0\"'. (See spdx.org.)");
				return;
			}
			if (osl->deprecated) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_DeprecatedLicence),
					"tries to use a licence which is now deprecated",
					"according to the SPDX standard catalogue "
					"of licence IDs. (See spdx.org.)");
				return;
			}
			@<Accept licence@>;
			break;
		}
		case COPYRIGHT_LICENCEDETAIL: {
			if ((Str::includes(val, I"(c)")) || (Str::includes(val, I"(C)")) ||
				(Str::includes(val, I"copyright")) || (Str::includes(val, I"Copyright")) ||
				(Str::includes(val, I"COPYRIGHT")) ||
				(Str::includes_character(val, (inchar32_t) 0x00A9))) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_CopyrightSaysCopyright),
					"contains the word 'copyright' or a symbol or abbreviation "
					"to that effect",
					"which it shouldn't, because Inform adds that automatically. "
					"So '\"Emily Short 2024\"' is allowed, but not '\"(c) Emily Short 2024\"'.");
				return;
			}
			match_results mr = Regexp::create_mr();
			if (Regexp::match(&mr, val, U"(%C%c*?) (%d%d%d%d)-(%d%d%d%d)")) {
				text_stream *owner = mr.exp[0];
				int date = Str::atoi(mr.exp[1], 0);
				int rev = Str::atoi(mr.exp[2], 0);
				if (date < 1971) @<Issue PM_AntiquatedCopyright@>;
				if (rev <= date) @<Issue PM_BadRevisionDate@>;
				@<Accept owner@>;
				@<Accept date@>;
				@<Accept revision date@>;
			} else if (Regexp::match(&mr, val, U"(%C%c*?) (%d%d%d%d)")) {
				text_stream *owner = mr.exp[0];
				int date = Str::atoi(mr.exp[1], 0);
				if (date < 1971) @<Issue PM_AntiquatedCopyright@>;
				@<Accept owner@>;
				@<Accept date@>;
			}
			break;
		}
		case URL_LICENCEDETAIL:
			if ((Str::begins_with(val, I"http://")) ||
				(Str::begins_with(val, I"https://"))) { @<Accept URL@>; return; }
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_BadOriginURL),
				"tries to give an invalid origin URL",
				"which must begin 'http://' or 'https://'.");
			return;
		case RIGHTS_LICENCEDETAIL:
			@<Accept rights@>; return;
	}
}

@<Issue PM_AntiquatedCopyright@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_EarlyCopyrightDate),
		"has too early a copyright date",
		"which should be at least 1971.");
	return;

@<Issue PM_BadRevisionDate@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_BadRevisionDate),
		"has a revision date which is too early",
		"since it should be later than the first copyright date.");
	return;

@<Accept licence@> =
	inbuild_licence *L;
	@<Find appropriate licence to adjust@>;
	Licences::set_licence(L, osl);

@<Accept owner@> =
	inbuild_licence *L;
	@<Find appropriate licence to adjust@>;
	Licences::set_owner(L, owner);

@<Accept date@> =
	inbuild_licence *L;
	@<Find appropriate licence to adjust@>;
	Licences::set_date(L, date);

@<Accept revision date@> =
	inbuild_licence *L;
	@<Find appropriate licence to adjust@>;
	Licences::set_revision_date(L, rev);

@<Accept URL@> =
	inbuild_licence *L;
	@<Find appropriate licence to adjust@>;
	Licences::set_origin_URL(L, val);

@<Accept rights@> =
	inbuild_licence *L;
	@<Find appropriate licence to adjust@>;
	Licences::set_rights_history(L, val);

@<Find appropriate licence to adjust@> =
	source_file *from = Lexer::file_of_origin(wn);
	inform_extension *E = Extensions::corresponding_to(from);
	if (extension) {
		if (E) L = E->as_copy->licence;
		else {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_ExtensionLicenceOutsideExtensions),
				"tries to set the licence for an extension but the main source text",
				"which is not allowed - an extension's licence must be set in the "
				"extension itself.");
			return;
		}
	} else {
		L = Task::project()->as_copy->licence;
		if (E) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_ProjectLicenceOutsideProject),
				"tries to set the licence for a project in an extension",
				"which is not allowed - a project's licence must be set in the "
				"main source text.");
			return;
		}
	}
	if (L == NULL) internal_error("no licence");
	L->discussed_in_source = TRUE;

@

=
void LicenceDeclaration::check_licences(void) {
	inform_project *proj = Task::project();
	inbuild_licence *L;
	L = proj->as_copy->licence;
	@<Auto-fill copyright year and author@>;
	if (L->modified) Projects::update_metadata(proj, TRUE, I"licence details changed");
	inform_extension *E;
	LOOP_OVER_LINKED_LIST(E, inform_extension, proj->extensions_included) {
		L = E->as_copy->licence;
		if (L->modified) @<Auto-fill copyright year and author@>;
		if (L->modified) Extensions::update_metadata(E, TRUE, I"licence details changed");
	}
}

@<Auto-fill copyright year and author@> =
	if (L->copyright_year == 1970)
		Licences::set_date(L, the_present->tm_year+1900);
	if (Str::eq(L->rights_owner, I"Unknown"))
		Licences::set_owner(L, L->on_copy->edition->work->author_name);

@

=
int LicenceDeclaration::anything_to_declare(void) {
	inform_project *proj = Task::project();
	inbuild_licence *L = proj->as_copy->licence;
	if (LicenceDeclaration::to_be_declared(L)) return TRUE;
	inform_extension *E;
	LOOP_OVER_LINKED_LIST(E, inform_extension, proj->extensions_included) {
		L = E->as_copy->licence;
		if (LicenceDeclaration::to_be_declared(L)) return TRUE;
	}
	return FALSE;
}

int LicenceDeclaration::to_be_declared(inbuild_licence *L) {
	if ((L->read_from_JSON) || (L->discussed_in_source)) {
		if (Str::eq(L->rights_history,
			I"This extension is basic to Inform and requires no acknowledgement."))
			return FALSE;
		return TRUE;
	}
	return FALSE;
}

@

@e I6_TEXT_LICENSESFORMAT from 1
@e PLAIN_LICENSESFORMAT
@e HTML_LICENSESFORMAT

=
void LicenceDeclaration::describe(OUTPUT_STREAM, int format) {
	inform_project *proj = Task::project();
	inbuild_licence *L = proj->as_copy->licence;
	text_stream *mention = NULL;
	int licences_cited = FALSE, include_MIT = FALSE, include_MIT_0 = FALSE;
	
	if (format == HTML_LICENSESFORMAT) {
		WRITE("<html><body>\n");
		WRITE("<h1>Copyright notice</h1>\n");
	}

	if ((L->read_from_JSON) || (L->discussed_in_source)) {
		@<Open paragraph@>;
		WRITE("Story ");
		@<Describe L@>;
		@<Close paragraph@>;
	}
	inform_extension *E;
	LOOP_OVER_LINKED_LIST(E, inform_extension, proj->extensions_included) {
		L = E->as_copy->licence;
		if ((L->read_from_JSON) || (L->discussed_in_source)) {
			@<Open paragraph@>;
			WRITE("%X v%v is ",
				L->on_copy->edition->work, &(L->on_copy->edition->version));
			mention = I", included";
			@<Describe L@>;
			@<Close paragraph@>;
		}
	}
	if (licences_cited) {
		@<Open paragraph@>;
		WRITE("For information about and links to full text of licences, see: ");
		LicenceDeclaration::link(OUT, I"https://spdx.org/licenses/", format);
		@<Close paragraph@>;
	}
	if (format == HTML_LICENSESFORMAT) {
		if (include_MIT)
			TextFiles::write_file_contents(OUT, InstalledFiles::filename(MIT_LICENSE_IRES));
		if (include_MIT_0)
			TextFiles::write_file_contents(OUT, InstalledFiles::filename(MIT_0_LICENSE_IRES));
	}
	if (format == HTML_LICENSESFORMAT) WRITE("</body></html>\n");
}

@<Describe L@> =
	text_stream *id = NULL;
	if (L->standard_licence) id = L->standard_licence->SPDX_id;
	if (Str::eq(id, I"MIT")) include_MIT = TRUE;
	if (Str::eq(id, I"MIT-0")) include_MIT_0 = TRUE;
	if ((Str::eq(id, I"Unlicense")) || (Str::eq(id, I"CC0-1.0"))) {
		WRITE("placed in the public domain by ");
	} else {
		WRITE("(c) ");
	}
	WRITE("%S %d", L->rights_owner, L->copyright_year);
	if (L->revision_year >= L->copyright_year) WRITE("-%d", L->revision_year);
	if (L->standard_licence) {
		WRITE("%S under licence %S", mention, L->standard_licence->SPDX_id);
		licences_cited = TRUE;
	}
	WRITE(".");
	if (Str::len(L->rights_history) > 0) WRITE(" %S", L->rights_history);
	if (Str::len(L->origin_URL) > 0) {
		WRITE(" See: ");
		LicenceDeclaration::link(OUT, L->origin_URL, format);
	}

@<Open paragraph@> =
	if (format == HTML_LICENSESFORMAT) WRITE("<p>");

@<Close paragraph@> =
	if (format == HTML_LICENSESFORMAT) WRITE("</p>");
	if (format == I6_TEXT_LICENSESFORMAT) WRITE("^");
	WRITE("\n");

@

=
void LicenceDeclaration::link(OUTPUT_STREAM, text_stream *URL, int format) {
	if (format == HTML_LICENSESFORMAT) WRITE("<a href=\"%S\">%S</a>", URL, URL);
	else WRITE("%S", URL);
}
