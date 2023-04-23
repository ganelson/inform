[NewUseOptions::] New Use Option Requests.

Special sentences for creating new use options.

@ Use options in Inform are akin to |#pragma| directives for the C family of
compilers: they are written in the source code of the program being compiled,
but they're not really part of that program, and are instead instructions to
the compiler to do something in a different way.[1]

Use options have natural-language names, and are created with sentences like:

>> Use American dialect translates as (- Constant DIALECT_US; -).

This syntax is now rather odd-looking, but most users never need it: it's used
mainly in the Basic Inform extension to create the standard set of use options.
Note the Inform 6 notation used for the Inter code between the |(-| and |-)|
brackets.

[1] The design of use options is arguably more muddled, because they do not all
correspond to compiler features: some affect the behaviour of Inter kits, and
some can be user-defined entirely.

@ A "... translates as ..." sentence has this special meaning if its SP and
OP match the following:

=
<use-translates-as-sentence-subject> ::=
	use <np-unparsed>  ==> { TRUE, RP[1] }

<use-translates-as-sentence-object> ::=
	(- ### |           ==> { -, - }
	...                ==> @<Issue PM_UseTranslatesNotI6 problem@>

@<Issue PM_UseTranslatesNotI6 problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_UseTranslatesNotI6),
		"that translates into something which isn't a simple Inter inclusion",
		"placed in '(-' and '-)' markers.");
	==> { FALSE, - };

@ =
int NewUseOptions::use_translates_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Use American dialect means ..." */
		case ACCEPT_SMFT:
			if ((<use-translates-as-sentence-object>(OW)) &&
				(<use-translates-as-sentence-subject>(SW))) {
				V->next = <<rp>>;
				<np-unparsed>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			@<Create a new use option@>;
			break;
	}
	return FALSE;
}

@ Use options correspond to instances of the following:

=
typedef struct use_option {
	struct wording name; /* word range where name is stored */
	struct wording expansion; /* definition as given in source */
	struct parse_node *where_used; /* where the option is taken in the source */
	struct parse_node *where_created;
	int option_used; /* set if this option has been taken */
	int source_file_scoped; /* scope is the current source file only? */
	int minimum_setting_value; /* for those which are numeric */
	int notable_option_code; /* or negative if not notable */
	struct use_option_compilation_data compilation_data;
	CLASS_DEFINITION
} use_option;

@<Create a new use option@> =
	wording SP = Node::get_text(V->next);
	wording OP = Node::get_text(V->next->next);
	<use-setting>(SP); /* always passes */
	int N = <<r>>; if (N < 0) N = -1;

	wording UOW = GET_RW(<use-setting>, 1);
	use_option *existing_uo = NewUseOptions::parse_uo(UOW);
	if (existing_uo) {
		if ((Wordings::match(OP, existing_uo->expansion) == FALSE) ||
			(N != existing_uo->minimum_setting_value)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, UOW);
			Problems::quote_source(3, existing_uo->where_created);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UODuplicate));
			Problems::issue_problem_segment(
				"In %1, you define a use option '%2', but that has already been "
				"defined, and with a different meaning: %3.");
			Problems::issue_problem_end();
		}
	} else {
		use_option *uo = CREATE(use_option);
		uo->name = UOW;
		uo->expansion = OP;
		uo->option_used = FALSE;
		uo->minimum_setting_value = N;
		uo->source_file_scoped = FALSE;
		uo->notable_option_code = -1;
		if (<notable-use-option-name>(uo->name)) uo->notable_option_code = <<r>>;
		if (uo->notable_option_code == AUTHORIAL_MODESTY_UO) uo->source_file_scoped = TRUE;
		uo->where_used = NULL;
		uo->where_created = current_sentence;
		uo->compilation_data = RTUseOptions::new_compilation_data(uo);
		Nouns::new_proper_noun(uo->name, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			MISCELLANEOUS_MC, Rvalues::from_use_option(uo), Task::language_of_syntax());
	}

@ Having registered the use option names as miscellaneous, we need to parse
them back that way too:

=
use_option *NewUseOptions::parse_uo(wording OW) {
	parse_node *p = Lexicon::retrieve(MISCELLANEOUS_MC, OW);
	if (Rvalues::is_CONSTANT_of_kind(p, K_use_option)) return Rvalues::to_use_option(p);
	return NULL;
}

@ The following sets an option.

=
void NewUseOptions::set(use_option *uo, int min_setting, source_file *from) {
	if (uo->minimum_setting_value == -1) {
		if (min_setting != -1)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UONotNumerical),
				"that 'Use' option does not have a numerical setting",
				"but is either used or not used.");
	} else {
		if (min_setting >= uo->minimum_setting_value)
			uo->minimum_setting_value = min_setting;
	}
	if (uo->source_file_scoped) {
		inform_extension *E = Extensions::corresponding_to(from);
		if (E == NULL) { /* that is, if used in the main source text */
			uo->option_used = TRUE;
			uo->where_used = current_sentence;
		}
	} else {
		uo->option_used = TRUE;
		uo->where_used = current_sentence;
	}
	CompilationSettings::set(uo->notable_option_code,
		uo->minimum_setting_value, from);
}

@ We can also meddle with the I6 memory settings which will be used to finish
compiling the story file. We need this because we have no practical way to
predict when our code will break I6's limits: the only reasonable way it can
work is for the user to hit the limit occasionally, and then raise that limit
by hand with a sentence in the source text.

=
typedef struct i6_memory_setting {
	struct text_stream *ICL_identifier; /* see the DM4 for the I6 memory setting names */
	int number; /* e.g., |50000| means "at least 50,000" */
	CLASS_DEFINITION
} i6_memory_setting;

@ =
void NewUseOptions::memory_setting(text_stream *identifier, int n) {
	i6_memory_setting *ms;
	LOOP_OVER(ms, i6_memory_setting)
		if (Str::eq(identifier, ms->ICL_identifier)) {
			if (ms->number < n) ms->number = n;
			if (Str::eq(identifier, I"DICT_WORD_SIZE"))
				global_compilation_settings.dict_word_size = n;
			return;
		}
	ms = CREATE(i6_memory_setting);
	ms->ICL_identifier = Str::duplicate(identifier);
	ms->number = n;
}
