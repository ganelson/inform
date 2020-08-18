[NeptuneSyntax::] Neptune Syntax.

To parse individual commands from Neptune files.

@h Specification of the Neptune language.
Everyone loves a mini-language, so here is one. At the top level:

(a) Lines consisting of white space or whose first non-white space character is
|!| are ignored as comments.

(b) A line ending with a colon |:| opens a new block. The text before the colon
is the title of the block, except that the first character indicates its type:
(-1) An asterisk means that the block is a "star template": for instance,
|*PRINTING-ROUTINE:| says the block defines a template called |PRINTING-ROUTINE|.
A template consists of Inform 7 source text which extends as far as the next
|*END| line.
(-2) A sharp sign |#| means that the block is a macro definition. For
instance, |#UNIT:| says the block defines a template called |UNIT|. A macro
is just a sequence of lines holding kind commands which continues to
the beginning of the next block, or the end of the file.
(-3) And otherwise the block is a kind definition, but the optional opening
character |+| marks the kind as one which Inform requires the existence of.
Thus |+NUMBER_TY:|, since Inform will crash if the template doesn't set this
kind up, but |BOOJUMS_TY:| would validly declare a new kind called
|BOOJUMS_TY| which isn't special to any of Inform's internals. The |+| signs
are there as a help for hackers looking at the I6 template and wondering what
they can safely monkey with.

(c) That just leaves the lines within blocks. Each of these is a usage of one
of the commands, given in the form |operation: operand|, i.e., divided by a
colon and some optional spacing.

@h The command set.
Each different operation is defined with a block like so:

=
typedef struct kind_command_definition {
	char *text_of_command;
	int opcode_number; /* one of the |*_KCC| values below */
	int operand_type; /* one of the |*_KCA| values below */
} kind_command_definition;

@ The operands have different types, and the possibilities are given here:

@e NO_KCA from 0   /* there's no operand */
@e BOOLEAN_KCA     /* must be |yes| or |no| */
@e CCM_KCA         /* a constant compilation method */
@e TEXT_KCA        /* any text (no quotation marks or other delimiters are used) */
@e VOCABULARY_KCA  /* any single word */
@e NUMERIC_KCA     /* any decimal number */
@e CONSTRUCTOR_KCA /* any valid kind number, such as "number" */
@e TEMPLATE_KCA    /* the name of a template whose definition is given in the file */
@e MACRO_KCA       /* the name of a macro whose definition is given in the file */

@ And, to cut to the chase, here is the complete table of commands:

@e apply_macro_KCC from 1
@e apply_template_KCC
@e can_coincide_with_property_KCC
@e can_exchange_KCC
@e cast_KCC
@e comparison_routine_KCC
@e comparison_schema_KCC
@e constant_compilation_method_KCC
@e constructor_arity_KCC
@e default_value_KCC
@e defined_in_source_text_KCC
@e description_KCC
@e distinguisher_KCC
@e documentation_reference_KCC
@e explicit_GPR_identifier_KCC
@e group_KCC
@e has_GPR_KCC
@e heap_size_estimate_KCC
@e i6_printing_routine_actions_KCC
@e i6_printing_routine_KCC
@e index_default_value_KCC
@e index_maximum_value_KCC
@e index_minimum_value_KCC
@e indexed_grey_if_empty_KCC
@e index_priority_KCC
@e conforms_to_KCC
@e is_incompletely_defined_KCC
@e is_template_variable_KCC
@e loop_domain_schema_KCC
@e modifying_adjective_KCC
@e multiple_block_KCC
@e created_with_assertions_KCC
@e plural_KCC
@e recognition_only_GPR_KCC
@e singular_KCC
@e specification_text_KCC
@e small_block_size_KCC
@e template_variable_number_KCC

=
kind_command_definition table_of_kind_commands[] = {
	{ "can-coincide-with-property",  can_coincide_with_property_KCC,   BOOLEAN_KCA },
	{ "can-exchange",                can_exchange_KCC,                 BOOLEAN_KCA },
	{ "defined-in-source-text",      defined_in_source_text_KCC,       BOOLEAN_KCA },
	{ "has-i6-GPR",                  has_GPR_KCC,                      BOOLEAN_KCA },
	{ "indexed-grey-if-empty",       indexed_grey_if_empty_KCC,        BOOLEAN_KCA },
	{ "is-incompletely-defined",     is_incompletely_defined_KCC,      BOOLEAN_KCA },
	{ "is-template-variable",        is_template_variable_KCC,         BOOLEAN_KCA },
	{ "multiple-block",              multiple_block_KCC,               BOOLEAN_KCA },
	{ "created-with-assertions",     created_with_assertions_KCC,      BOOLEAN_KCA },

	{ "constant-compilation-method", constant_compilation_method_KCC,  CCM_KCA },

	{ "comparison-routine",          comparison_routine_KCC,           TEXT_KCA },
	{ "default-value",               default_value_KCC,                TEXT_KCA },
	{ "description",                 description_KCC,                  TEXT_KCA },
	{ "distinguisher",               distinguisher_KCC,                TEXT_KCA },
	{ "documentation-reference",     documentation_reference_KCC,      TEXT_KCA },
	{ "explicit-i6-GPR",             explicit_GPR_identifier_KCC,      TEXT_KCA },
	{ "i6-printing-routine",         i6_printing_routine_KCC,          TEXT_KCA },
	{ "i6-printing-routine-actions", i6_printing_routine_actions_KCC,  TEXT_KCA },
	{ "index-default-value",         index_default_value_KCC,          TEXT_KCA },
	{ "index-maximum-value",         index_maximum_value_KCC,          TEXT_KCA },
	{ "index-minimum-value",         index_minimum_value_KCC,          TEXT_KCA },
	{ "loop-domain-schema",          loop_domain_schema_KCC,           TEXT_KCA },
	{ "recognition-only-GPR",        recognition_only_GPR_KCC,         TEXT_KCA },
	{ "specification-text",          specification_text_KCC,           TEXT_KCA },

	{ "cast",                        cast_KCC,                         CONSTRUCTOR_KCA },
	{ "comparison-schema",           comparison_schema_KCC,            CONSTRUCTOR_KCA },
	{ "conforms-to",                 conforms_to_KCC,                  CONSTRUCTOR_KCA },

	{ "modifying-adjective",         modifying_adjective_KCC,          VOCABULARY_KCA },
	{ "plural",                      plural_KCC,                       VOCABULARY_KCA },
	{ "singular",                    singular_KCC,                     VOCABULARY_KCA },

	{ "constructor-arity",           constructor_arity_KCC,            TEXT_KCA },
	{ "group",                       group_KCC,                        NUMERIC_KCA },
	{ "heap-size-estimate",          heap_size_estimate_KCC,           NUMERIC_KCA },
	{ "index-priority",              index_priority_KCC,               NUMERIC_KCA },
	{ "small-block-size",            small_block_size_KCC,             NUMERIC_KCA },
	{ "template-variable-number",    template_variable_number_KCC,     NUMERIC_KCA },

	{ "apply-template",              apply_template_KCC,               TEMPLATE_KCA },

	{ "apply-macro",                 apply_macro_KCC,                  MACRO_KCA },

	{ NULL, -1, NO_KCA }
};

@ When processing a command, we parse it into one of the following structures:

=
typedef struct single_kind_command {
	struct kind_command_definition *which_kind_command;
	int boolean_argument; /* where appropriate */
	int numeric_argument; /* where appropriate */
	struct text_stream *textual_argument; /* where appropriate */
	int ccm_argument; /* where appropriate */
	struct word_assemblage vocabulary_argument; /* where appropriate */
	struct text_stream *constructor_argument; /* where appropriate */
	struct kind_template_definition *template_argument; /* where appropriate */
	struct kind_macro_definition *macro_argument; /* where appropriate */
	struct text_file_position *origin;
	struct kind_constructor *defined_for;
	int completed;
} single_kind_command;

@h Parsing single kind commands.
Each command is read in as text, parsed and stored into a modest structure.

=
kind_constructor *constructor_described = NULL;

single_kind_command NeptuneSyntax::parse_command(parse_node_tree *T,
	text_stream *whole_command, text_file_position *tfp) {
	single_kind_command stc;
	@<Initialise the STC to a blank command@>;

	Str::trim_white_space(whole_command);
	if (StarTemplates::recording()) {
		if (Str::eq(whole_command, I"*END")) StarTemplates::end(whole_command, tfp);
		else StarTemplates::record_line(whole_command, tfp);
		stc.completed = TRUE;
	} else if (Str::get_last_char(whole_command) == ':') {
		if (NeptuneMacros::recording()) NeptuneMacros::end(tfp);
		Str::delete_last_character(whole_command); /* remove the terminal colon */
		if (Str::get_first_char(whole_command) == '#') NeptuneMacros::begin(whole_command, tfp);
		else if (Str::get_first_char(whole_command) == '*') StarTemplates::begin(whole_command, tfp);
		else @<Create a new constructor@>;
		stc.completed = TRUE;
	} else {
		TEMPORARY_TEXT(command)
		TEMPORARY_TEXT(argument)

		@<Parse line into command and argument, divided by a colon@>;

		@<Identify the command being used@>;

		switch(stc.which_kind_command->operand_type) {
			case BOOLEAN_KCA: @<Parse a boolean argument for a kind command@>; break;
			case CCM_KCA: @<Parse a CCM argument for a kind command@>; break;
			case CONSTRUCTOR_KCA: @<Parse a constructor-name argument for a kind command@>; break;
			case MACRO_KCA: @<Parse a macro name argument for a kind command@>; break;
			case NUMERIC_KCA: @<Parse a numeric argument for a kind command@>; break;
			case TEMPLATE_KCA: @<Parse a template name argument for a kind command@>; break;
			case TEXT_KCA: @<Parse a textual argument for a kind command@>; break;
			case VOCABULARY_KCA: @<Parse a vocabulary argument for a kind command@>; break;
		}
		DISCARD_TEXT(command)
		DISCARD_TEXT(argument)
	}
	return stc;
}

@<Initialise the STC to a blank command@> =
	stc.which_kind_command = NULL;
	stc.boolean_argument = NOT_APPLICABLE;
	stc.numeric_argument = 0;
	stc.textual_argument = Str::new();
	stc.ccm_argument = -1;
	stc.vocabulary_argument = WordAssemblages::lit_0();
	stc.constructor_argument = Str::new();
	stc.macro_argument = NULL;
	stc.template_argument = NULL;
	stc.completed = FALSE;
	stc.origin = tfp;
	stc.defined_for = constructor_described;

@<Create a new constructor@> =
	TEMPORARY_TEXT(name)
	Str::copy(name, whole_command);
	int should_know = FALSE;
	if (Str::get_first_char(name) == '+') { Str::delete_first_character(name); should_know = TRUE; }
	int do_know = FamiliarKinds::is_known(name);
	if ((do_know == FALSE) && (should_know == TRUE))
		NeptuneFiles::error(whole_command, I"kind command describes kind with no known name", tfp);
	if ((do_know == TRUE) && (should_know == FALSE))
		NeptuneFiles::error(whole_command, I"kind command describes already-known kind", tfp);
	constructor_described =
		Kinds::Constructors::new(T, Kinds::get_construct(K_value), name, NULL);
	#ifdef NEW_BASE_KINDS_CALLBACK
	if ((constructor_described != CON_KIND_VARIABLE) &&
		(constructor_described != CON_INTERMEDIATE)) {
		NEW_BASE_KINDS_CALLBACK(
			Kinds::base_construction(constructor_described), NULL, name, EMPTY_WORDING);
	}
	#endif
	DISCARD_TEXT(name)

@ Spaces and tabs after the colon are skipped; so a textual argument cannot
begin with those characters, but that doesn't matter for the things we need.

@<Parse line into command and argument, divided by a colon@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, whole_command, L" *(%c+?) *: *(%c+?) *")) {
		Str::copy(command, mr.exp[0]);
		Str::copy(argument, mr.exp[1]);
		Regexp::dispose_of(&mr);
	} else {
		NeptuneFiles::error(whole_command, I"kind command without argument", tfp);
	}

@ The following is clearly inefficient, but is not worth optimising. It makes
about 20 string comparisons per command, and there are about 600 commands in a
typical run of Inform, so the total cost is about 12,000 comparisons with
quite small strings as arguments -- which is negligible for our purposes,
so we neglect it.

@<Identify the command being used@> =
	for (int i=0; table_of_kind_commands[i].text_of_command; i++)
		if (Str::eq_narrow_string(command, table_of_kind_commands[i].text_of_command))
			stc.which_kind_command = &(table_of_kind_commands[i]);

	if (stc.which_kind_command == NULL) {
		NeptuneFiles::error(command, I"no such kind command", tfp);
		stc.completed = TRUE; return stc;
	}

@<Parse a boolean argument for a kind command@> =
	if (Str::eq_wide_string(argument, L"yes")) stc.boolean_argument = TRUE;
	else if (Str::eq_wide_string(argument, L"no")) stc.boolean_argument = FALSE;
	else NeptuneFiles::error(command, I"boolean kind command takes yes/no argument", tfp);

@<Parse a CCM argument for a kind command@> =
	if (Str::eq_wide_string(argument, L"none")) stc.ccm_argument = NONE_CCM;
	else if (Str::eq_wide_string(argument, L"literal")) stc.ccm_argument = LITERAL_CCM;
	else if (Str::eq_wide_string(argument, L"quantitative")) stc.ccm_argument = NAMED_CONSTANT_CCM;
	else if (Str::eq_wide_string(argument, L"special")) stc.ccm_argument = SPECIAL_CCM;
	else {
		NeptuneFiles::error(command,
			I"kind command with unknown constant-compilation-method", tfp);
		stc.completed = TRUE; return stc;
	}

@<Parse a textual argument for a kind command@> =
	Str::copy(stc.textual_argument, argument);

@<Parse a vocabulary argument for a kind command@> =
	stc.vocabulary_argument = WordAssemblages::lit_0();
	feed_t id = Feeds::begin();
	Feeds::feed_text(argument);
	wording W = Feeds::end(id);
	if (Wordings::length(W) >= 30) {
		NeptuneFiles::error(command, I"too many words in kind command", tfp);
		stc.completed = TRUE; return stc;
	} else
		stc.vocabulary_argument = WordAssemblages::from_wording(W);

@<Parse a numeric argument for a kind command@> =
	stc.numeric_argument = Str::atoi(argument, 0);

@<Parse a constructor-name argument for a kind command@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, argument, L"(%c*?)>>>(%c+)")) {
		Str::copy(argument, mr.exp[0]);
		Str::copy(stc.textual_argument, mr.exp[1]);
		Regexp::dispose_of(&mr);
	}
	stc.constructor_argument = Str::duplicate(argument);

@<Parse a template name argument for a kind command@> =
	stc.template_argument = StarTemplates::parse_name(argument);
	if (stc.template_argument == NULL) {
		NeptuneFiles::error(command, I"unknown template name in kind command", tfp);
		stc.completed = TRUE; return stc;
	}

@<Parse a macro name argument for a kind command@> =
	stc.macro_argument = NeptuneMacros::parse_name(argument);
	if (stc.macro_argument == NULL) {
		NeptuneFiles::error(command, I"unknown template name in kind command", tfp);
		stc.completed = TRUE; return stc;
	}
