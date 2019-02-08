[Coverage::] Problem Coverage.

To see which problem messages have test cases and which are linked
to the documentation.

@h Observation.

@d CASE_EXISTS_PCON		0x00000001
@d DOC_MENTIONS_PCON 	0x00000002
@d CODE_MENTIONS_PCON 	0x00000004
@d IMPOSSIBLE_PCON 		0x00000008
@d UNTESTABLE_PCON 		0x00000010
@d NAMELESS_PCON		0x00000020

=
dictionary *problems_dictionary = NULL;

typedef struct known_problem {
	struct text_stream *name;
	int contexts_observed;
	int contexts_observed_multiple_times;
	MEMORY_MANAGEMENT
} known_problem;

@ When a problem is observed, we create a dictionary entry for it, if necessary,
and augment its bitmap of known contexts:

=
void Coverage::observe_problem(text_stream *name, int context) {
	if (problems_dictionary == NULL)
		problems_dictionary = Dictionaries::new(1000, FALSE);
	known_problem *KP = NULL;
	if (Dictionaries::find(problems_dictionary, name)) {
		KP = (known_problem *) Dictionaries::read_value(problems_dictionary, name);
	} else {
		KP = CREATE(known_problem);
		Dictionaries::create(problems_dictionary, name);
		Dictionaries::write_value(problems_dictionary, name, (void *) KP);
		KP->name = Str::duplicate(name);
		KP->contexts_observed = 0;
		KP->contexts_observed_multiple_times = 0;
	}
	if (KP->contexts_observed & context)
		KP->contexts_observed_multiple_times |= context;
	KP->contexts_observed |= context;
}

@h Problems which have test cases.
Here we ask Intest to produce a roster of all known test cases, then parse
this back to look for cases whose names have the |PM_...| format. Those are
the problem message test cases, so we observe them.

=
void Coverage::which_problems_have_test_cases(pathname *Workspace) {
	filename *CAT = Filenames::in_folder(Workspace, I"cases.txt");
	TEMPORARY_TEXT(COMMAND);
	WRITE_TO(COMMAND, "intest/Tangled/intest inform7 -catalogue ");
	Shell::redirect(COMMAND, CAT);
	if (Shell::run(COMMAND)) Errors::fatal("can't run intest to harvest cases");
	DISCARD_TEXT(COMMAND);
	TextFiles::read(CAT, FALSE, "unable to read roster of test cases", TRUE,
		&Coverage::test_case_harvester, NULL, NULL);
}

void Coverage::test_case_harvester(text_stream *text, text_file_position *tfp, void *state) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L"(PM_%C+)%c*"))
		Coverage::observe_problem(mr.exp[0], CASE_EXISTS_PCON);
	Regexp::dispose_of(&mr);
}

@h Problems mentioned in documentation.
Here we look through the "Writing with Inform" source text for cross-references
to problem messages:

=
void Coverage::which_problems_are_referenced(pathname *Workspace) {
	pathname *D = Pathnames::from_text(I"Documentation");
	filename *WWI = Filenames::in_folder(D, I"Writing with Inform.txt");
	TextFiles::read(WWI, FALSE, "unable to read 'Writing with Inform' source text", TRUE,
		&Coverage::xref_harvester, NULL, NULL);
}

void Coverage::xref_harvester(text_stream *text, text_file_position *tfp, void *state) {
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, text, L"(%c*)%{(PM_%C+?)%}(%c*)")) {
		Coverage::observe_problem(mr.exp[1], DOC_MENTIONS_PCON);
		Str::clear(text);
		WRITE_TO(text, "%S%S", mr.exp[0], mr.exp[2]);
	}
	Regexp::dispose_of(&mr);
}

@h Problems generated in the I7 source.
Which is to say, actually existing problem messages.

=
void Coverage::which_problems_exist(pathname *Workspace) {
	Coverage::which_problems_exist_inner(
		Pathnames::from_text(I"inform7"), Workspace);
	Coverage::which_problems_exist_inner(
		Pathnames::from_text(I"inform7/core-module"), Workspace);
	Coverage::which_problems_exist_inner(
		Pathnames::from_text(I"inform7/if-module"), Workspace);
	Coverage::which_problems_exist_inner(
		Pathnames::from_text(I"inform7/multimedia-module"), Workspace);
	Coverage::which_problems_exist_inner(
		Pathnames::from_text(I"inter/codegen-module"), Workspace);
}

void Coverage::which_problems_exist_inner(pathname *D, pathname *Workspace) {
	filename *C = Filenames::in_folder(D, I"Contents.w");
	existence_state es;
	es.web_path = D;
	es.chapter_path = NULL;
	TextFiles::read(C, FALSE, "unable to read contents page of 'inform7' web", TRUE,
		&Coverage::section_harvester, NULL, &es);
}

typedef struct existence_state {
	struct pathname *web_path;
	struct pathname *chapter_path;
	struct filename *section;
} existence_state;

void Coverage::section_harvester(text_stream *text, text_file_position *tfp, void *state) {
	existence_state *es = (existence_state *) state;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L"(Chapter %d+)%c+"))
		es->chapter_path = Pathnames::subfolder(es->web_path, mr.exp[0]);
	if (Regexp::match(&mr, text, L"Appendix%c+")) es->chapter_path = NULL;
	if (Regexp::match(&mr, text, L"Preliminaries%c+")) es->chapter_path = NULL;
	if ((es->chapter_path) && (Regexp::match(&mr, text, L" (%c+?) *"))) {
		TEMPORARY_TEXT(leaf);
		Str::copy(leaf, mr.exp[0]);
		if (Regexp::match(&mr, leaf, L"(%c+?) %[%[%c+")) Str::copy(leaf, mr.exp[0]);
		WRITE_TO(leaf, ".w");
		es->section = Filenames::in_folder(es->chapter_path, leaf);
		DISCARD_TEXT(leaf);
		TextFiles::read(es->section, FALSE, "unable to read section page from 'inform7' web", TRUE,
			&Coverage::existence_harvester, NULL, es);
	}
	Regexp::dispose_of(&mr);
}

void Coverage::existence_harvester(text_stream *text, text_file_position *tfp, void *state) {
	existence_state *es = (existence_state *) state;
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, text, L"(%c*?)_p_%((%c+?)%)(%c*)")) {
		Str::clear(text);
		WRITE_TO(text, "%S%S", mr.exp[0], mr.exp[2]);
		TEMPORARY_TEXT(name);
		Str::copy(name, mr.exp[1]);
		if (Str::eq_wide_string(name, L"sigil")) break;
		int context = CODE_MENTIONS_PCON;
		if (Str::eq_wide_string(name, L"BelievedImpossible")) { context = IMPOSSIBLE_PCON; @<Suffix location@> }
		else if (Str::eq_wide_string(name, L"Untestable")) { context = UNTESTABLE_PCON; @<Suffix location@> }
		else if (Str::eq_wide_string(name, L"...")) { context = NAMELESS_PCON; @<Suffix location@> }
		if (Str::eq_wide_string(name, L"BelievedImpossible")) @<Suffix location@>
		Coverage::observe_problem(name, context);
		DISCARD_TEXT(name);
	}
	Regexp::dispose_of(&mr);
}

@<Suffix location@> =
	WRITE_TO(name, "_%f_line%d", es->section, tfp->line_count);

@h Checking.

=
int observations_made = FALSE;
int Coverage::check(OUTPUT_STREAM) {
	if (observations_made == FALSE) {
		pathname *P =
			Pathnames::subfolder(Pathnames::from_text(I"inpolicy"), I"Workspace");
		Coverage::which_problems_have_test_cases(P);
		Coverage::which_problems_are_referenced(P);
		Coverage::which_problems_exist(P);
		observations_made = TRUE;
	}

	int all_is_well = TRUE;

	WRITE("%d problem name(s) have been observed:\n", NUMBER_CREATED(known_problem)); INDENT;

	WRITE("Problems actually existing (the source code refers to them):\n"); INDENT;
	Coverage::cite(OUT, CODE_MENTIONS_PCON, 0, CODE_MENTIONS_PCON,
		L"are named and in principle testable");
	if (Coverage::cite(OUT, 0, CODE_MENTIONS_PCON, CODE_MENTIONS_PCON,
		L"are named more than once:") > 0) {
		all_is_well = FALSE;
		Coverage::list(OUT, 0, CODE_MENTIONS_PCON, CODE_MENTIONS_PCON);
	}
	Coverage::cite(OUT, IMPOSSIBLE_PCON, 0, IMPOSSIBLE_PCON,
		L"are 'BelievedImpossible', that is, no known source text causes them");
	Coverage::cite(OUT, UNTESTABLE_PCON, 0, UNTESTABLE_PCON,
		L"are 'Untestable', that is, not mechanically testable");
	Coverage::cite(OUT, NAMELESS_PCON, 0, NAMELESS_PCON,
		L"are '...', that is, they need to be give a name and a test case");
	OUTDENT;

	WRITE("Problems which should have test cases:\n"); INDENT;
	Coverage::cite(OUT, CASE_EXISTS_PCON+CODE_MENTIONS_PCON, 0, CASE_EXISTS_PCON+CODE_MENTIONS_PCON,
		L"have test cases");
	if (Coverage::cite(OUT, CASE_EXISTS_PCON+CODE_MENTIONS_PCON, 0, CODE_MENTIONS_PCON,
		L"have no test case yet:") > 0) {
		Coverage::list(OUT, CASE_EXISTS_PCON+CODE_MENTIONS_PCON, 0, CODE_MENTIONS_PCON);
	}
	if (Coverage::cite(OUT, CASE_EXISTS_PCON+CODE_MENTIONS_PCON, 0, CASE_EXISTS_PCON,
		L"are spurious test cases, since no such problems exist:") > 0) {
		all_is_well = FALSE;
		Coverage::list(OUT, CASE_EXISTS_PCON+CODE_MENTIONS_PCON, 0, CASE_EXISTS_PCON);
	}
	OUTDENT;

	WRITE("Problems which are cross-referenced in 'Writing with Inform':\n"); INDENT;
	Coverage::cite(OUT, CODE_MENTIONS_PCON+DOC_MENTIONS_PCON, 0, CODE_MENTIONS_PCON+DOC_MENTIONS_PCON,
		L"are cross-referenced");
	if (Coverage::cite(OUT, 0, DOC_MENTIONS_PCON, DOC_MENTIONS_PCON,
		L"are cross-referenced more than once:") > 0) {
		all_is_well = FALSE;
		Coverage::list(OUT, 0, DOC_MENTIONS_PCON, DOC_MENTIONS_PCON);
	}
	if (Coverage::cite(OUT, CODE_MENTIONS_PCON+DOC_MENTIONS_PCON, 0, DOC_MENTIONS_PCON,
		L"are spurious references, since no such problems exist:") > 0) {
		all_is_well = FALSE;
		Coverage::list(OUT, CODE_MENTIONS_PCON+DOC_MENTIONS_PCON, 0, DOC_MENTIONS_PCON);
	}
	OUTDENT;

	OUTDENT;
	if (all_is_well) WRITE("All is well.\n");
	else WRITE("This needs attention.\n");
	WRITE("\n");
	return all_is_well;
}

int Coverage::cite(OUTPUT_STREAM, int mask, int mask2, int val, wchar_t *message) {
	int N = 0;
	known_problem *KP;
	LOOP_OVER(KP, known_problem) {
		if ((KP->contexts_observed & mask) == val) N++;
		if ((KP->contexts_observed_multiple_times & mask2) == val) N++;
	}
	if ((N>0) && (message)) WRITE("%d problem(s) %w\n", N, message);
	return N;
}

void Coverage::list(OUTPUT_STREAM, int mask, int mask2, int val) {
	INDENT;
	known_problem *KP;
	LOOP_OVER(KP, known_problem) {
		if (((KP->contexts_observed & mask) == val) ||
			((KP->contexts_observed_multiple_times & mask2) == val)) {
			WRITE("%S\n", KP->name);
		}
	}
	OUTDENT;
}
