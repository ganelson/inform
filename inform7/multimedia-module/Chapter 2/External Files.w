[PL::Files::] External Files.

To register the names associated with external files, and build
the small I6 arrays associated with each.

@ Each file can be text or binary, has a name, and can be owned by a this
project, by an unspecified other project, or by a project named by IFID.

@d OWNED_BY_THIS_PROJECT 1
@d OWNED_BY_ANOTHER_PROJECT 2
@d OWNED_BY_SPECIFIC_PROJECT 3

=
typedef struct external_file {
	struct wording name; /* text of name */
	int unextended_filename; /* word number of text like |"bones"| */
	struct text_stream *exf_I6_identifier; /* an I6 identifier */
	int file_is_binary; /* true or false */
	int file_ownership; /* one of the above */
	struct text_stream *IFID_of_owner; /* an I6 identifier */
	struct inter_name *exf_iname;
	struct inter_name *IFID_array_iname;
	CLASS_DEFINITION
} external_file;

@ A |-->| array to a run-time data structure associated
with an external file, read or written by the story file during play.

= (early code)
kind *K_external_file = NULL;

@ =
void PL::Files::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_BASE_KIND_NOTIFY, PL::Files::files_new_base_kind_notify);
	PLUGIN_REGISTER(PLUGIN_NEW_INSTANCE_NOTIFY, PL::Files::files_new_named_instance_notify);
}

@ =
int PL::Files::files_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"EXTERNAL_FILE_TY")) {
		K_external_file = new_base; return TRUE;
	}
	return FALSE;
}

int allow_exf_creations = FALSE;
int PL::Files::files_new_named_instance_notify(instance *nc) {
	if (K_external_file == NULL) return FALSE;
	kind *K = Instances::to_kind(nc);
	if (Kinds::eq(K, K_external_file)) {
		if (allow_exf_creations == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BackdoorFileCreation),
				"this is not the way to create a new external file",
				"which should be done with a special 'The File ... is called ...' "
				"sentence.");
		Instances::set_connection(nc,
			STORE_POINTER_external_file(PL::Files::new_external_file(nc)));
		return TRUE;
	}
	return FALSE;
}

@ =
external_file *PL::Files::new_external_file(instance *nc) {
	external_file *exf = CREATE(external_file);
	return exf;
}

@ External files are created with a special sentence:

>> The File of Wisdom (owned by another project) is called "wisdom".

Here is the subject:

=
<external-file-sentence-subject> ::=
	<definite-article> <external-file-sentence-subject> |  ==> { pass 2 }
	text <external-file-name> |                            ==> { FALSE, -, <<ownership>> = R[1] }
	binary <external-file-name> |                          ==> { TRUE, -, <<ownership>> = R[1] }
	<external-file-name>                                   ==> { FALSE, -, <<ownership>> = R[1] }

<external-file-name> ::=
	{file ...} ( owned by <external-file-owner> ) |        ==> { pass 1 }
	{file ...}                                             ==> { NOT_APPLICABLE, - }

<external-file-owner> ::=
	another project |                                      ==> { FALSE, - }
	project {<quoted-text-without-subs>} |                 ==> { TRUE, - }
	...                                                    ==> @<Issue PM_BadFileOwner problem@>

@<Issue PM_BadFileOwner problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadFileOwner),
		"the owner of this file is wrongly specified",
		"since it is not one of the three possibilities - "
		"(1) Specify nothing: making the file belong to this "
		"project. (2) Specify only that it belongs to someone, "
		"without saying whom: 'The File of Wisdom (owned by "
		"another project) is called \"wisdom\".' (3) Specify "
		"that it belongs to a project with a given double-quoted "
		"IFID: 'The File of Wisdom (owned by project "
		"\"4122DDA8-A153-46BC-8F57-42220F9D8795\") "
		"is called \"wisdom\".'");
	==> { NOT_APPLICABLE, - };

@ The object NP is simply quoted text. Although the Preform grammar doesn't
go into this level of detail, it's actually required to have 3 to 23 English
letters or digits, with the first being a letter.

=
<external-file-sentence-object> ::=
	<quoted-text> |  ==> { pass 1 }
	...              ==> @<Issue PM_FilenameNotTextual problem@>

@<Issue PM_FilenameNotTextual problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FilenameNotTextual),
		"a file can only be called with a single quoted piece of text",
		"as in: 'The File of Wisdom is called \"wisdom\".'");
	==> { -1, - };

@ This handles the special meaning "File... is the file...".

=
<new-file-sentence-object> ::=
	<indefinite-article> <new-file-sentence-object-unarticled> |  ==> { pass 2 }
	<new-file-sentence-object-unarticled>                         ==> { pass 1 }

<new-file-sentence-object-unarticled> ::=
	called <np-unparsed>                                          ==> { TRUE, RP[1] }

<nounphrase-external-file> ::=
	<external-file-sentence-subject>    ==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

@ =
int PL::Files::new_file_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "File... is the file..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-external-file>(SW)) && (<new-file-sentence-object>(OW))) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			if (Plugins::Manage::plugged_in(files_plugin) == FALSE)
				internal_error("Files plugin inactive");
			PL::Files::register_file(Node::get_text(V->next),
				Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

void PL::Files::register_file(wording F, wording FN) {
	int bad_filename = FALSE;
	<external-file-sentence-object>(FN);
	FN = Wordings::from(FN, <<r>>);
	if (Wordings::empty(FN)) return;
	wchar_t *p = Lexer::word_text(Wordings::first_wn(FN));
	if (Wide::len(p) < 5) bad_filename = TRUE;
	if (Characters::isalpha(p[1]) == FALSE) bad_filename = TRUE;
	for (int i=0; p[i]; i++) {
		if (p[i] == '"') {
			if ((i==0) || (p[i+1] == 0)) continue;
		}
		if (i>24) bad_filename = TRUE;
		if ((isalpha(p[i])) || (Characters::isdigit(p[i]))) continue;
		LOG("Objected to character %c\n", p[i]);
		bad_filename = TRUE;
	}
	if (bad_filename) {
		LOG("Filename: %s\n", p);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FilenameUnsafe),
			"filenames must be very conservatively chosen",
			"in order to be viable on a wide range of computers. They must "
			"consist of 3 to 23 English letters or digits, with the first being "
			"a letter. Spaces are not allowed, and nor are periods. (A file "
			"extension, such as '.glkdata', may be added on some platforms "
			"automatically: this is invisible to Inform.)");
		return;
	}

	int ownership = OWNED_BY_THIS_PROJECT;
	TEMPORARY_TEXT(ifid_of_file)

	if (<external-file-sentence-subject>(F) == FALSE) internal_error("bad ef grammar");
	F = GET_RW(<external-file-name>, 1);
	int binary = <<r>>;
	if (<<ownership>> == TRUE) {
		wording OW = GET_RW(<external-file-owner>, 1);
		int j, invalid = FALSE;
		p = Lexer::word_text(Wordings::last_wn(OW));
		for (j=1; (j<47) && (p[j]); j++) {
			if ((p[j] == '"') && (p[j+1] == 0)) break;
			PUT_TO(ifid_of_file, p[j]);
			if ((isalpha(p[j])) || (Characters::isdigit(p[j]))) continue;
			if (p[j] == '-') continue;
			invalid = TRUE;
			LOG("Objected to character %c\n", p[j]);
		}
		if ((invalid) || (j==47)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadFileIFID),
				"the owner of the file should be specified "
				"using a valid double-quoted IFID",
				"as in: 'The File of Wisdom (owned by project "
				"\"4122DDA8-A153-46BC-8F57-42220F9D8795\") "
				"is called \"wisdom\".'");
		} else
			ownership = OWNED_BY_SPECIFIC_PROJECT;
	}
	if (<<ownership>> == FALSE) {
		ownership = OWNED_BY_ANOTHER_PROJECT;
	}

	Assertions::Creator::vet_name_for_noun(F);

	if ((<s-value>(F)) &&
		(Rvalues::is_CONSTANT_of_kind(<<rp>>, K_external_file))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FilenameDuplicate),
			"this is already the name of a file",
			"so there must be some duplication somewhere.");
		return;
	}

	allow_exf_creations = TRUE;
	pcalc_prop *prop = Propositions::Abstract::to_create_something(
		K_external_file, F);
	Propositions::Assert::assert_true(prop, CERTAIN_CE);
	allow_exf_creations = FALSE;
	external_file *exf = RETRIEVE_POINTER_external_file(
		Instances::get_connection(latest_instance));
	exf->name = F;
	exf->unextended_filename = Wordings::first_wn(FN);
	exf->file_is_binary = binary;
	exf->file_ownership = ownership;
	exf->IFID_of_owner = Str::duplicate(ifid_of_file);

	package_request *P = Hierarchy::local_package(EXTERNAL_FILES_HAP);
	exf->exf_iname = Hierarchy::make_iname_with_memo(FILE_HL, P, exf->name);
	exf->IFID_array_iname = Hierarchy::make_iname_with_memo(IFID_HL, P, exf->name);

	LOGIF(FIGURE_CREATIONS, "Created external file <%W> = filename '%N'\n",
		F, exf->unextended_filename);
	DISCARD_TEXT(ifid_of_file)
}

@h I6 arrays of file structures.
External files are written in I6 as their array names:

=
void PL::Files::arrays(void) {
	if (Plugins::Manage::plugged_in(files_plugin) == FALSE) return;

	inter_name *iname = Hierarchy::find(NO_EXTERNAL_FILES_HL);
	Emit::named_numeric_constant(iname, (inter_ti) (NUMBER_CREATED(external_file)));
	Hierarchy::make_available(Emit::tree(), iname);

	external_file *exf;
	LOOP_OVER(exf, external_file) {
		if (exf->file_ownership == OWNED_BY_SPECIFIC_PROJECT) {
			packaging_state save = Emit::named_string_array_begin(exf->IFID_array_iname, K_value);
			TEMPORARY_TEXT(II)
			WRITE_TO(II, "//%S//", exf->IFID_of_owner);
			Emit::array_text_entry(II);
			DISCARD_TEXT(II)
			Emit::array_end(save);
		}
	}

	LOOP_OVER(exf, external_file) {
		packaging_state save = Emit::named_array_begin(exf->exf_iname, K_value);
		Emit::array_iname_entry(Hierarchy::find(AUXF_MAGIC_VALUE_HL));
		Emit::array_iname_entry(Hierarchy::find(AUXF_STATUS_IS_CLOSED_HL));
		if (exf->file_is_binary) Emit::array_numeric_entry(1);
		else Emit::array_numeric_entry(0);
		Emit::array_numeric_entry(0);
		TEMPORARY_TEXT(WW)
		WRITE_TO(WW, "%w", Lexer::word_raw_text(exf->unextended_filename));
		Str::delete_first_character(WW);
		Str::delete_last_character(WW);
		Emit::array_text_entry(WW);
		DISCARD_TEXT(WW)
		switch (exf->file_ownership) {
			case OWNED_BY_THIS_PROJECT: Emit::array_iname_entry(PL::Bibliographic::IFID::UUID()); break;
			case OWNED_BY_ANOTHER_PROJECT: Emit::array_null_entry(); break;
			case OWNED_BY_SPECIFIC_PROJECT: Emit::array_iname_entry(exf->IFID_array_iname); break;
		}
		Emit::array_end(save);
	}

	iname = Hierarchy::find(TABLEOFEXTERNALFILES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	Emit::array_numeric_entry(0);
	LOOP_OVER(exf, external_file) Emit::array_iname_entry(exf->exf_iname);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@h External Files Index.
More or less perfunctory, but still of some use, if only as a list.

=
void PL::Files::index_all(OUTPUT_STREAM) {
	if (Plugins::Manage::plugged_in(files_plugin) == FALSE) return;
	external_file *exf;
	if (NUMBER_CREATED(external_file) == 0) {
		HTML_OPEN("p");
		WRITE("This project doesn't read or write external files.");
		HTML_CLOSE("p");
		return;
	}
	HTML_OPEN("p");
	WRITE("<b>List of External Files</b>");
	HTML_CLOSE("p");
	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	LOOP_OVER(exf, external_file) {
		HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
		if (exf->file_is_binary) {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/exf_binary.png\"");
		} else {
			HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/exf_text.png\"");
		}
		WRITE("&nbsp;");
		HTML::next_html_column(OUT, 0);
		WRITE("%+W", exf->name);
		Index::link(OUT, Wordings::first_wn(exf->name));
		HTML_TAG("br");
		WRITE("Filename: %s %N- owned by ",
			(exf->file_is_binary)?"- binary ":"",
			exf->unextended_filename);
		switch (exf->file_ownership) {
			case OWNED_BY_THIS_PROJECT: WRITE("this project"); break;
			case OWNED_BY_ANOTHER_PROJECT: WRITE("another project"); break;
			case OWNED_BY_SPECIFIC_PROJECT:
				WRITE("project with IFID number <b>%S</b>",
					exf->IFID_of_owner);
				break;
		}
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);
	HTML_OPEN("p");
}
