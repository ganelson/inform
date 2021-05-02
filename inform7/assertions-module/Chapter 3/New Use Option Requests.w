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
	int N = <<r>>;

	use_option *uo = CREATE(use_option);
	uo->name = GET_RW(<use-setting>, 1);
	uo->expansion = OP;
	uo->option_used = FALSE;
	uo->minimum_setting_value = (N > 0) ? N : -1;
	uo->source_file_scoped = FALSE;
	uo->notable_option_code = -1;
	if (<notable-use-option-name>(uo->name)) uo->notable_option_code = <<r>>;
	if (uo->notable_option_code == AUTHORIAL_MODESTY_UO) uo->source_file_scoped = TRUE;
	uo->where_used = NULL;
	uo->where_created = current_sentence;
	uo->compilation_data = RTUseOptions::new_compilation_data(uo);
	Nouns::new_proper_noun(uo->name, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_use_option(uo), Task::language_of_syntax());

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

@ And this is what the rest of Inform calls to find out whether a particular
pragma is set:

=
int NewUseOptions::uo_set_from(use_option *uo, int category, inform_extension *E) {
	source_file *sf = (uo->where_used)?
		(Lexer::file_of_origin(Wordings::first_wn(Node::get_text(uo->where_used)))):NULL;
	inform_extension *efo = (sf)?(Extensions::corresponding_to(sf)):NULL;
	switch (category) {
		case 1: if ((sf) && (efo == NULL)) return TRUE; break;
		case 2: if (sf == NULL) return TRUE; break;
		case 3: if ((sf) && (efo == E)) return TRUE; break;
	}
	return FALSE;
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
			return;
		}
	ms = CREATE(i6_memory_setting);
	ms->ICL_identifier = Str::duplicate(identifier);
	ms->number = n;
}

@ Now for indexing, where there's nothing much to see.

@d MAIN_TEXT_UO_ORIGIN 1
@d OPTIONS_FILE_UO_ORIGIN 2
@d EXTENSION_UO_ORIGIN 3

=
void NewUseOptions::index(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("The following use options are in force:"); HTML_CLOSE("p");
	NewUseOptions::index_options_in_force_from(OUT, MAIN_TEXT_UO_ORIGIN, NULL);
	NewUseOptions::index_options_in_force_from(OUT, OPTIONS_FILE_UO_ORIGIN, NULL);
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		NewUseOptions::index_options_in_force_from(OUT, EXTENSION_UO_ORIGIN, E);
	int nt = 0;
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if ((uo->option_used == FALSE) && (uo->minimum_setting_value < 0)) nt++;
	}
	if (nt > 0) {
		HTML_OPEN("p"); WRITE("Whereas these are not in force:"); HTML_CLOSE("p");
		HTML::open_indented_p(OUT, 2, "tight");
		LOOP_OVER(uo, use_option) {
			if (uo->source_file_scoped) continue;
			if ((uo->option_used == FALSE) && (uo->minimum_setting_value < 0)) {
				@<Write in the index line for a use option not taken@>;
				if (--nt > 0) WRITE(", ");
			}
		}
		HTML_CLOSE("p");
	}
}

@<Write in the index line for a use option not taken@> =
	HTML_OPEN_WITH("span", "style=\"white-space:nowrap\";");
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, "Use %+W.", uo->name);
	PasteButtons::paste_text(OUT, TEMP);
	DISCARD_TEXT(TEMP)
	WRITE("&nbsp;%+W", uo->name);
	HTML_CLOSE("span");

@ =
void NewUseOptions::index_options_in_force_from(OUTPUT_STREAM, int category, inform_extension *E) {
	int N = 0;
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if ((uo->option_used) && (uo->minimum_setting_value < 0) &&
			(NewUseOptions::uo_set_from(uo, category, E))) {
			if (N++ == 0) @<Write in the use option subheading@>;
			@<Write in the index line for a use option taken@>;
		}
	}
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if (((uo->option_used) && (uo->minimum_setting_value >= 0)) &&
			(NewUseOptions::uo_set_from(uo, category, E))) {
			if (N++ == 0) @<Write in the use option subheading@>;
			@<Write in the index line for a use option taken@>;
		}
	}
}

@<Write in the use option subheading@> =
	HTML::open_indented_p(OUT, 2, "tight");
	HTML::begin_colour(OUT, I"808080");
	WRITE("Set from ");
	switch (category) {
		case MAIN_TEXT_UO_ORIGIN:
			WRITE("the source text"); break;
		case OPTIONS_FILE_UO_ORIGIN:
			WRITE("the Options.txt configuration file");
			Index::DocReferences::link(OUT, I"OPTIONSFILE"); break;
		case EXTENSION_UO_ORIGIN:
			if (Extensions::is_standard(E)) WRITE("the ");
			else WRITE("the extension ");
			WRITE("%S", E->as_copy->edition->work->title);
			break;
	}
	WRITE(":");
	HTML::end_colour(OUT);
	HTML_CLOSE("p");

@<Write in the index line for a use option taken@> =
	HTML::open_indented_p(OUT, 3, "tight");
	WRITE("Use %+W", uo->name);
	if (uo->minimum_setting_value >= 0) WRITE(" of at least %d", uo->minimum_setting_value);
	if (uo->where_used) Index::link(OUT, Wordings::first_wn(Node::get_text(uo->where_used)));
	if (uo->minimum_setting_value >= 0) {
		WRITE("&nbsp;");
		TEMPORARY_TEXT(TEMP)
		WRITE_TO(TEMP, "Use %+W of at least %d.", uo->name, 2*(uo->minimum_setting_value));
		PasteButtons::paste_text(OUT, TEMP);
		DISCARD_TEXT(TEMP)
		WRITE("&nbsp;<i>Double this</i>");
	}
	HTML_CLOSE("p");
