[NewUseOptions::] New Use Option Requests.

Special sentences for creating new use options.

@ Use options in Inform are akin to |#pragma| directives for the C family of
compilers: they are written in the source code of the program being compiled,
but they're not really part of that program, and are instead instructions to
the compiler (or more often, the Inter kits which the program is linked to)
to do something in a different way.

Use options have natural-language names, and are created with sentences like:

>> Use American dialect translates as the configuration flag AMERICAN_DIALECT in BasicInformKit.

or with the more old-fashioned (and soon to be deprecated)

>> Use American dialect translates as (- Constant US_DIALECT = 1; -).

@ A "... translates as ..." sentence has this special meaning if its SP and
OP match the following:

@e NO_UTAS from 0
@e INLINE_UTAS
@e CONFIG_NAMELESS_FLAG_UTAS
@e CONFIG_FLAG_UTAS
@e CONFIG_FLAG_IN_UTAS
@e CONFIG_NAMELESS_VALUE_UTAS
@e CONFIG_VALUE_UTAS
@e CONFIG_VALUE_EQ_UTAS
@e CONFIG_VALUE_IN_UTAS
@e CONFIG_VALUE_IN_EQ_UTAS
@e COMPILER_UTAS

=
<use-translates-as-sentence-subject> ::=
	use <np-unparsed>  ==> { TRUE, RP[1] }

<use-translates-as-sentence-object> ::=
	(- ### |          		 									==> { INLINE_UTAS, - }
	configuration <use-translates-as-configuration> | 			==> { R[1], - }
	<article> configuration <use-translates-as-configuration> | ==> { R[2], - }
	a compiler feature |	 									==> { COMPILER_UTAS, - }
	...                					==> @<Issue PM_UseTranslatesNotI6 problem@>

<use-translates-as-configuration> ::=
	flag |                          ==> { CONFIG_NAMELESS_FLAG_UTAS, - }
	flag <quoted-text> | 			==> @<Issue PM_UseTranslatesNotI6 problem@>
	flag ### | 						==> { CONFIG_FLAG_UTAS, - }
	flag ### = ### | 				==> @<Issue PM_UseTranslatesNotI6 problem@>
	flag <quoted-text> in ### |		==> @<Issue PM_UseTranslatesNotI6 problem@>
	flag ### in ### | 				==> { CONFIG_FLAG_IN_UTAS, - }
	flag ### = ### in ### | 		==> @<Issue PM_UseTranslatesNotI6 problem@>
	value |                         ==> { CONFIG_NAMELESS_VALUE_UTAS, - }
	value <quoted-text> | 			==> @<Issue PM_UseTranslatesNotI6 problem@>
	value ### | 					==> { CONFIG_VALUE_UTAS, - }
	value ### = ### | 				==> { CONFIG_VALUE_EQ_UTAS, - }
	value <quoted-text> in ### |	==> @<Issue PM_UseTranslatesNotI6 problem@>
	value ### in ### |	 			==> { CONFIG_VALUE_IN_UTAS, - }
	value ### = ### in ###		 	==> { CONFIG_VALUE_IN_EQ_UTAS, - }

@<Issue PM_UseTranslatesNotI6 problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_UseTranslatesNotI6),
		"that translates into something I don't recognise",
		"which should be 'configuration flag/value NAME', "
		"'configuration flag/value NAME in KIT', or an inline I6-syntax code "
		"inclusion in '(-' and '-)' markers, although the latter is best avoided.");
	==> { NO_UTAS, - };

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
	struct wording expansion; /* inline definition as given in source */
	int definition_form; /* one of the |*_UTAS| constants above */
	struct text_stream *symbol_name; /* if not defined as inline code */
	struct text_stream *kit_name; /* null if no kit specified */
	struct parse_node *where_created;
	int source_file_scoped; /* scope is the current source file only? */
	struct parsed_use_option_setting *default_value;
	struct linked_list *settings_made; /* of |parsed_use_option_setting| */
	int is_explicitly_numerical; /* must a Use sentence give a number? */
	int notable_option_code; /* or negative if not notable */
	struct use_option_compilation_data compilation_data;
	int no_Inter_presence;
	CLASS_DEFINITION
} use_option;

@<Create a new use option@> =
	wording SP = Node::get_text(V->next);
	wording OP = Node::get_text(V->next->next);
	parsed_use_option_setting *puos = UseOptions::parse_setting(SP);
	int N = puos->value; if ((puos->at_least == TRUE) && (N < 0)) N = -1;
	wording UOW = puos->textual_option;
	if (puos->resolved_option) {
		@<Do not allow the same use option to be declared twice@>;
	} else {
		<use-translates-as-sentence-object>(OP);
		int form = <<r>>;
		@<Do not allow a one-word symbol for a numerical value@>;
		@<Do not allow a flag to have a default value@>;
		@<Declare this new option@>;
	}

@<Do not allow the same use option to be declared twice@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, UOW);
	Problems::quote_source(3, puos->resolved_option->where_created);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UODuplicate));
	Problems::issue_problem_segment(
		"In %1, you define a use option '%2', but that has already been "
		"defined: %3.");
	Problems::issue_problem_end();

@<Declare this new option@> =
	use_option *uo = CREATE(use_option);
	puos->resolved_option = uo;
	uo->name = UOW;
	uo->expansion = EMPTY_WORDING;
	uo->definition_form = form;
	if (uo->definition_form == INLINE_UTAS) @<Handle the deprecated inline case@>;
	uo->symbol_name = NULL;
	uo->kit_name = NULL;
	uo->is_explicitly_numerical = FALSE;
	if (puos->at_least != NOT_APPLICABLE) uo->is_explicitly_numerical = TRUE;
	if ((uo->definition_form == CONFIG_VALUE_UTAS) ||
		(uo->definition_form == CONFIG_NAMELESS_VALUE_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_IN_UTAS)) {
		uo->is_explicitly_numerical = TRUE;
	}
	uo->default_value = puos;
	int M = 0, M_set = FALSE;
	@<See if this option sets a value to some specified number M@>;
	@<Make sure the flag or value name is valid@>;
	uo->no_Inter_presence = FALSE;
	if (uo->definition_form == CONFIG_NAMELESS_FLAG_UTAS) {
		uo->definition_form = CONFIG_FLAG_UTAS;
		uo->no_Inter_presence = TRUE;
	}
	if (uo->definition_form == CONFIG_NAMELESS_VALUE_UTAS) {
		uo->definition_form = CONFIG_VALUE_UTAS;
		uo->no_Inter_presence = TRUE;
	}
	if (uo->definition_form == COMPILER_UTAS) {
		uo->no_Inter_presence = TRUE;
	}
	@<Make sure the kit name is valid@>;
	uo->settings_made = NEW_LINKED_LIST(parsed_use_option_setting);
	uo->source_file_scoped = FALSE;
	uo->notable_option_code = -1;
	if (<notable-use-option-name>(uo->name)) uo->notable_option_code = <<r>>;
	if (uo->notable_option_code == AUTHORIAL_MODESTY_UO) uo->source_file_scoped = TRUE;
	uo->where_created = current_sentence;
	uo->compilation_data = RTUseOptions::new_compilation_data(uo);
	Nouns::new_proper_noun(uo->name, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_use_option(uo), Task::language_of_syntax());

@ At some point this will cease to be allowed, but simple inline definitions
are still supported, and the call to |RTUseOptions::check_deprecated_definition|
checks that the one here is simple enough to deal with. If it isn't, a problem
message is thrown.

@<Handle the deprecated inline case@> =
	uo->expansion = OP;
	text_stream *UO = Str::new();
	WRITE_TO(UO, "%W", Wordings::from(OP, Wordings::first_wn(OP) + 1));
	if (RTUseOptions::check_deprecated_definition(UO) == FALSE) {
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_UONotationWithdrawn));
		Problems::quote_source(1, current_sentence);
		Problems::quote_stream(2, UO);
		Problems::issue_problem_segment(
			"In %1, you set up a use option, but you use the deprecated notation "
			"'(- %2 -)' to say what to do if this option is set. For now, that "
			"still works if a simple form is used, such as '(- Constant X; -)' or "
			"'(- Constant Y = {N}; -)' or even '(- Constant Z = 2*{N}; -)', but the "
			"ability to write arbitrary Inform 6-syntax code here has been withdrawn.");
		Problems::issue_problem_end();
	}

@ The ambiguity alluded to here is with Inform 6 ICL settings: see below.

@<Do not allow a one-word symbol for a numerical value@> =
	if ((Wordings::length(UOW) == 1) && (puos->at_least != NOT_APPLICABLE))
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UOValueOneWord),
			"use options which take numerical values have to be more than "
			"a single word long",
			"to prevent ambiguities which would otherwise be a nuisance.");

@<Do not allow a flag to have a default value@> =
	if ((N >= 0) && ((form == CONFIG_FLAG_UTAS) || (form == CONFIG_FLAG_IN_UTAS)))
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UOFlagWithValue),
			"this is a configuration flag not a value",
			"so it cannot be 'at least' some minimum number.");

@<See if this option sets a value to some specified number M@> =
	if ((uo->definition_form == CONFIG_VALUE_EQ_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_IN_EQ_UTAS)) {
		if (N >= 0)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_UOValueExact),
				"this is a value which is definitely set by the option",
				"so it cannot be 'at least' some minimum number.");
		wording MW = GET_RW(<use-translates-as-configuration>, 2);
		if (<cardinal-number-unlimited>(MW)) { M = <<r>>; M_set = TRUE; }
		else StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UOValueNotDecimal),
			"the value after '=' must be written as a decimal number",
			"0, 1, 2, ...");
		puos->at_least = FALSE;
		puos->value = M;
	}

@<Make sure the flag or value name is valid@> =
	if ((uo->definition_form == CONFIG_FLAG_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_UTAS) ||
		(uo->definition_form == CONFIG_FLAG_IN_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_IN_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_EQ_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_IN_EQ_UTAS)) {
		wording SYMW = GET_RW(<use-translates-as-configuration>, 1);
		uo->symbol_name = Str::new();
		WRITE_TO(uo->symbol_name, "%+W", SYMW);
		int invalid = FALSE;
		if (Str::len(uo->symbol_name) > 20) invalid = TRUE;
		if (Characters::isupper(Str::get_at(uo->symbol_name, 0)) == FALSE)
			invalid = TRUE;
		LOOP_THROUGH_TEXT(pos, uo->symbol_name) {
			wchar_t c = Str::get(pos);
			if ((Characters::isupper(c) == FALSE) &&
				(Characters::isdigit(c) == FALSE) &&
				(c != '_'))
				invalid = TRUE;
		}
		if (invalid)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_UOSymbolBad),
				"the name of that configuration flag or value is invalid",
				"and must be 20 characters or fewer in length, must begin "
				"with an upper-case letter A to Z, and can contain only "
				"upper-case letters, digits and underscores '_'.");
	}

@<Make sure the kit name is valid@> =
	if ((uo->definition_form == CONFIG_FLAG_IN_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_IN_UTAS) ||
		(uo->definition_form == CONFIG_VALUE_IN_EQ_UTAS)) {
		int pos = 2;
		if (uo->definition_form == CONFIG_VALUE_IN_EQ_UTAS) pos = 3;
		wording KW = GET_RW(<use-translates-as-configuration>, pos);
		uo->kit_name = Str::new();
		WRITE_TO(uo->kit_name, "%+W", KW);
		int invalid = FALSE;
		if (Characters::isupper(Str::get_at(uo->kit_name, 0)) == FALSE)
			invalid = TRUE;
		LOOP_THROUGH_TEXT(pos, uo->kit_name) {
			wchar_t c = Str::get(pos);
			if ((Characters::isupper(c) == FALSE) &&
				(Characters::islower(c) == FALSE) &&
				(Characters::isdigit(c) == FALSE))
				invalid = TRUE;
		}
		if (Str::suffix_eq(uo->kit_name, I"Kit", 3) == FALSE) invalid = TRUE;
		if (invalid)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_UOKitNameBad),
				"the name of that kit is invalid",
				"and must begin with an upper-case letter A to Z, must end "
				"with 'Kit', and must contain only letters and digits.");
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
void NewUseOptions::set(parsed_use_option_setting *puos) {
	use_option *uo = puos->resolved_option;
	if (uo == NULL) internal_error("tried to set null UO");
	if ((uo->is_explicitly_numerical == FALSE) && (puos->at_least != NOT_APPLICABLE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UONotNumerical),
			"that 'Use' option does not have a numerical setting",
			"but is either used or not used.");
	} else if ((uo->is_explicitly_numerical) && (puos->at_least == NOT_APPLICABLE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UONumerical),
			"that 'Use' option has to have a numerical setting",
			"and you do not give one.");
	} else {
		ADD_TO_LINKED_LIST(puos, parsed_use_option_setting, uo->settings_made);
	}
	source_file *from = Lexer::file_of_origin(Wordings::first_wn(puos->textual_option));
	if (uo->source_file_scoped) {
		inform_extension *E = Extensions::corresponding_to(from);
		if (E) puos->made_at = NULL;
	}
	CompilationSettings::set(uo->notable_option_code, puos->value, from);
}

@ Target pragma settings arise from sentences like

>> Use Ada compiler option "!check-boundaries".

which tell Inform that the Inter it produces should be marked so that any
hypothetical translation of that code to Ada could (if the translation code
chose to) take notice of the option set. We know nothing of the possible
languages or their options: ours just to pass on the news.

=
typedef struct target_pragma_setting {
	struct text_stream *target;
	struct text_stream *content;
	CLASS_DEFINITION
} target_pragma_setting;

@ We handle the case of Inform 6 ICL memory limit settings specially:
|$MAX_WHATEVER=200| must be able to raise the numerical value to the largest
set, if multiple sentences set |$MAX_WHATEVER|.

=
void NewUseOptions::pragma_setting(parsed_use_option_setting *puos) {
	TEMPORARY_TEXT(target)
	LOOP_THROUGH_TEXT(pos, puos->language_for_pragma)
		if (Characters::is_whitespace(Str::get(pos)) == FALSE)
			PUT_TO(target, Str::get(pos));
	if (Str::eq_insensitive(target, I"Inform6")) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, puos->content_of_pragma, L" *$(%C+)=(%d+);* *")) {
			int val = Str::atoi(mr.exp[1], 0);
			NewUseOptions::memory_setting(mr.exp[0], val);
		} else {
			@<Stash the PUOS for later@>;
		}
		Regexp::dispose_of(&mr);
	} else {
		@<Stash the PUOS for later@>;
	}
	DISCARD_TEXT(target)
}

@ There are far too few of these to worry about a quadratic running time here.

@<Stash the PUOS for later@> =
	int already_done = FALSE;
	target_pragma_setting *tps;
	LOOP_OVER(tps, target_pragma_setting)
		if ((Str::eq_insensitive(tps->target, target)) &&
			(Str::eq(tps->content, puos->content_of_pragma)))
			already_done = TRUE;
	if (already_done == FALSE) {
		tps = CREATE(target_pragma_setting);
		tps->target = Str::duplicate(target);
		tps->content = Str::duplicate(puos->content_of_pragma);
	}

@ So this is the special case for Inform 6 memory settings. (Well, that's what
they mostly are.)

=
typedef struct i6_memory_setting {
	struct text_stream *ICL_identifier; /* see the DM4 for the I6 memory setting names */
	int number; /* e.g., |50000| means "at least 50,000" */
	CLASS_DEFINITION
} i6_memory_setting;

@ =
void NewUseOptions::memory_setting(text_stream *identifier, int n) {
	LOOP_THROUGH_TEXT(pos, identifier)
		Str::put(pos, Characters::toupper(Str::get(pos)));
	if (Str::len(identifier) > 63) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_BadICLIdentifier),
			"that is too long to be an ICL identifier",
			"so can't be the name of any I6 memory setting.");
	}
	if (Str::eq(identifier, I"DICT_WORD_SIZE"))
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_DoNotUseDICTWORDSIZE),
			"the Inform 6 memory setting 'DICT_WORD_SIZE' should no longer be used",
			"and instead you should write 'Use dictionary resolution of N' to set "
			"the number of letters recognised in a word typed in a command during play.");
	i6_memory_setting *ms;
	LOOP_OVER(ms, i6_memory_setting)
		if (Str::eq(identifier, ms->ICL_identifier)) {
			if (ms->number < n) ms->number = n;
			return;
		}
	ms = CREATE(i6_memory_setting);
	ms->ICL_identifier = Str::duplicate(identifier);
	ms->number = n;
}
