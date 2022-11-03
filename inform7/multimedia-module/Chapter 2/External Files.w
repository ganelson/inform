[ExternalFiles::] External Files.

To register the names associated with external files, and build
the small I6 arrays associated with each.

@ The test group |:files| exercises the features in this feature.

The following is called to activate the feature:

=
void ExternalFiles::start(void) {
	PluginCalls::plug(PRODUCTION_LINE_PLUG, ExternalFiles::production_line);
	PluginCalls::plug(MAKE_SPECIAL_MEANINGS_PLUG, ExternalFiles::make_special_meanings);
	PluginCalls::plug(NEW_BASE_KIND_NOTIFY_PLUG, ExternalFiles::files_new_base_kind_notify);
	PluginCalls::plug(NEW_INSTANCE_NOTIFY_PLUG, ExternalFiles::files_new_named_instance_notify);
}

int ExternalFiles::production_line(int stage, int debugging,
	stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(RTMultimedia::compile_files);
	}
	return FALSE;
}

@h One special meaning.
We add one special meaning for assertions, to catch sentences with the shape:

>> The File of Wisdom (owned by another project) is called "wisdom".

=
int ExternalFiles::make_special_meanings(void) {
	SpecialMeanings::declare(ExternalFiles::new_file_SMF, I"new-file", 2);
	return FALSE;
}
int ExternalFiles::new_file_SMF(int task, parse_node *V, wording *NPs) {
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
			ExternalFiles::register_file(Node::get_text(V->next),
				Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

@ And this is the Preform grammar needed for the subject phrase:

@d EXTERNAL_TEXT_FILE_NFSMF 0
@d EXTERNAL_BINARY_FILE_NFSMF 1
@d INTERNAL_TEXT_FILE_NFSMF 2
@d INTERNAL_BINARY_FILE_NFSMF 3
@d INTERNAL_FORM_FILE_NFSMF 4

=
<external-file-sentence-subject> ::=
	<definite-article> <external-file-sentence-subject> |  ==> { pass 2 }
	internal data/binary <external-file-name> |            ==> { INTERNAL_BINARY_FILE_NFSMF, -, <<ownership>> = R[1] }
	internal text <external-file-name> |                   ==> { INTERNAL_TEXT_FILE_NFSMF, -, <<ownership>> = R[1] }
	internal form <external-file-name> |                   ==> { INTERNAL_FORM_FILE_NFSMF, -, <<ownership>> = R[1] }
	text <external-file-name> |                            ==> { EXTERNAL_TEXT_FILE_NFSMF, -, <<ownership>> = R[1] }
	binary <external-file-name> |                          ==> { EXTERNAL_BINARY_FILE_NFSMF, -, <<ownership>> = R[1] }
	<external-file-name>                                   ==> { EXTERNAL_TEXT_FILE_NFSMF, -, <<ownership>> = R[1] }

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

@ The object phrase is simply quoted text. Although the Preform grammar doesn't
go into this level of detail, it's actually required to have 3 to 23 English
letters or digits, with the first being a letter.

=
<external-file-sentence-object> ::=
	<quoted-text> |  ==> { pass 1 }
	...              ==> @<Issue PM_FilenameNotTextual problem@>

<new-file-sentence-object> ::=
	<indefinite-article> <new-file-sentence-object-unarticled> |  ==> { pass 2 }
	<new-file-sentence-object-unarticled>                         ==> { pass 1 }

<new-file-sentence-object-unarticled> ::=
	called <np-unparsed>                                          ==> { TRUE, RP[1] }

<nounphrase-external-file> ::=
	<external-file-sentence-subject>    ==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

@<Issue PM_FilenameNotTextual problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FilenameNotTextual),
		"a file can only be called with a single quoted piece of text",
		"as in: 'The File of Wisdom is called \"wisdom\".'");
	==> { -1, - };

@ In assertion pass 1, then, the following is called on any sentence which
has been found to create a file:

=
void ExternalFiles::register_file(wording W, wording FN) {
	<external-file-sentence-object>(FN);
	FN = Wordings::from(FN, <<r>>);
	if (Wordings::empty(FN)) return;
	wchar_t *p = Lexer::word_text(Wordings::first_wn(FN));
	if (<external-file-sentence-subject>(W) == FALSE) internal_error("bad ef grammar");
	wording NW = GET_RW(<external-file-name>, 1);
	int format = <<r>>;
	@<Vet the filename@>;
	int binary = FALSE;
	int ownership = OWNED_BY_THIS_PROJECT;
	switch (format) {
		case EXTERNAL_TEXT_FILE_NFSMF:
		case EXTERNAL_BINARY_FILE_NFSMF: {
			if (format == EXTERNAL_BINARY_FILE_NFSMF) binary = TRUE;
			TEMPORARY_TEXT(ifid_of_file)
			@<Determine the ownership@>;
			ExternalFiles::files_create(W, binary, ownership, ifid_of_file, FN);
			LOGIF(MULTIMEDIA_CREATIONS, "Created external file <%W> = filename '%N'\n", W, FN);
			DISCARD_TEXT(ifid_of_file)
			break;
		}
		case INTERNAL_TEXT_FILE_NFSMF:
		case INTERNAL_BINARY_FILE_NFSMF:
		case INTERNAL_FORM_FILE_NFSMF:
			InternalFiles::files_create(<<r>>, NW, FN);
			LOGIF(MULTIMEDIA_CREATIONS, "Created internal file <%W> = filename '%N'\n", NW, FN);
			break;
	}
}

@ The restrictions here are really very conservative.

@<Vet the filename@> =
	int bad_filename = FALSE;
	if (Wide::len(p) < 5) bad_filename = TRUE;
	if (Characters::isalpha(p[1]) == FALSE) bad_filename = TRUE;
	for (int i=0; p[i]; i++) {
		if (p[i] == '"') {
			if ((i==0) || (p[i+1] == 0)) continue;
		}
		if (i>24) bad_filename = TRUE;
		if ((isalpha(p[i])) || (Characters::isdigit(p[i]))) continue;
		if ((format == INTERNAL_TEXT_FILE_NFSMF) ||
			(format == INTERNAL_BINARY_FILE_NFSMF) ||
			(format == INTERNAL_FORM_FILE_NFSMF))
			if ((p[i] == '.') || (p[i] == '_') || (p[i] == ' ')) continue;
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

@ Each file can be text or binary, has a name, and can be owned by this project,
by an unspecified other project, or by a project identified by its IFID.

@d OWNED_BY_THIS_PROJECT 1
@d OWNED_BY_ANOTHER_PROJECT 2
@d OWNED_BY_SPECIFIC_PROJECT 3

@<Determine the ownership@> =
	W = GET_RW(<external-file-name>, 1);
	@<Make sure W can be the name of a new file anyway@>;
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
		if ((invalid) || (j==47))
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadFileIFID),
				"the owner of the file should be specified "
				"using a valid double-quoted IFID",
				"as in: 'The File of Wisdom (owned by project "
				"\"4122DDA8-A153-46BC-8F57-42220F9D8795\") "
				"is called \"wisdom\".'");
		else
			ownership = OWNED_BY_SPECIFIC_PROJECT;
	}
	if (<<ownership>> == FALSE) ownership = OWNED_BY_ANOTHER_PROJECT;

@<Make sure W can be the name of a new file anyway@> =
	Assertions::Creator::vet_name_for_noun(W);
	if ((<s-value>(W)) &&
		(Rvalues::is_CONSTANT_of_kind(<<rp>>, K_external_file))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FilenameDuplicate),
			"this is already the name of a file",
			"so there must be some duplication somewhere.");
		return;
	}

@h One significant kind.

= (early code)
kind *K_external_file = NULL;

@ =
int ExternalFiles::files_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"EXTERNAL_FILE_TY")) {
		K_external_file = new_base; return TRUE;
	}
	return FALSE;
}

@h Significant new instances.
This structure of additional data is attached to each figure instance.

=
typedef struct files_data {
	struct wording name; /* text of name */
	int unextended_filename; /* word number of text like |"bones"| */
	struct text_stream *exf_identifier; /* an Inter identifier */
	int file_is_binary; /* true or false */
	int file_ownership; /* one of the |OWNED_BY_*| values above */
	struct text_stream *IFID_of_owner; /* if we know that */
	struct instance *as_instance;
	struct parse_node *where_created;
	CLASS_DEFINITION
} files_data;

@ We allow instances of "external file" to be created only through the above
code calling //Figures::figures_create//. If any other proposition somehow
manages to make a figure, a problem message is thrown.

=
int allow_exf_creations = FALSE;

instance *ExternalFiles::files_create(wording W, int binary, int ownership,
	text_stream *ifid_of_file, wording FN) {
	allow_exf_creations = TRUE;
	Assert::true(Propositions::Abstract::to_create_something(K_external_file, W), CERTAIN_CE);
	allow_exf_creations = FALSE;
	instance *I = Instances::latest();
	files_data *fd = FEATURE_DATA_ON_INSTANCE(files, I);
	fd->name = W;
	fd->unextended_filename = Wordings::first_wn(FN);
	fd->file_is_binary = binary;
	fd->file_ownership = ownership;
	fd->IFID_of_owner = Str::duplicate(ifid_of_file);
	fd->where_created = current_sentence;
	fd->as_instance = I;
	return I;
}

int ExternalFiles::files_new_named_instance_notify(instance *I) {
	if (K_external_file == NULL) return FALSE;
	kind *K = Instances::to_kind(I);
	if (Kinds::eq(K, K_external_file)) {
		if (allow_exf_creations == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_BackdoorFileCreation),
				"this is not the way to create a new external file",
				"which should be done with a special 'The File ... is called ...' "
				"sentence.");
		ATTACH_FEATURE_DATA_TO_SUBJECT(files, I->as_subject, CREATE(files_data));
		return TRUE;
	}
	return FALSE;
}
