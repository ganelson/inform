[KindCommands::] Kind Commands.

To read in details of the built-in kinds from template files,
setting them up ready for use.

@ Everyone loves a mini-language, so here is one. At the top level:

(a) Lines consisting of white space or whose first non-white space character is
|!| are ignored as comments.

(b) A line ending with a colon |:| opens a new block. The text before the colon
is the title of the block, except that the first character indicates its type:
(-1) An asterisk means that the block is a template definition: for instance,
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

@ The body of a kind definition is a sequence of one-line commands setting
what properties the kind has. These commands take the form of a name, a colon,
and an operand; for instance,
= (text)
	i6-printing-routine-actions:DA_Number
=
The operands have different types, and the possibilities are given here:

@d NO_KCA -1 /* there's no operand */

@d BOOLEAN_KCA 1 /* must be |yes| or |no| */
@d CCM_KCA 2 /* a constant compilation method */
@d TEXT_KCA 3 /* any text (no quotation marks or other delimiters are used) */
@d VOCABULARY_KCA 4 /* any single word */
@d NUMERIC_KCA 5 /* any decimal number */
@d CONSTRUCTOR_KCA 6 /* any valid kind number, such as "number" */
@d TEMPLATE_KCA 7 /* the name of a template whose definition is given in the file */
@d MACRO_KCA 8 /* the name of a macro whose definition is given in the file */

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
} single_kind_command;

@ A few of the commands connect pairs of kinds together: for instance,
when we write
= (text)
	cast:RULEBOOK_TY
=
in the definition block for |RULE_TY|, we're saying that every rulebook
can always be cast implicitly to a rule. There can be any number of these
in the definition block, so we need somewhere to store details, and the
following structure provides an entry in a linked list.

=
typedef struct kind_constructor_casting_rule {
	struct text_stream *cast_from_kind_unparsed; /* to the one which has the rule */
	struct kind_constructor *cast_from_kind; /* to the one which has the rule */
	struct kind_constructor_casting_rule *next_casting_rule;
} kind_constructor_casting_rule;

@ And this is the analogous structure for giving I6 schemas to compare
data of two different kinds:

=
typedef struct kind_constructor_comparison_schema {
	struct text_stream *comparator_unparsed;
	struct kind_constructor *comparator;
	struct text_stream *comparison_schema;
	struct kind_constructor_comparison_schema *next_comparison_schema;
} kind_constructor_comparison_schema;

@ And this is the analogous structure for giving I6 schemas to compare
data of two different kinds:

=
typedef struct kind_constructor_instance {
	struct text_stream *instance_of_this_unparsed;
	struct kind_constructor *instance_of_this;
	struct kind_constructor_instance *next_instance_rule;
} kind_constructor_instance;

@ And, to cut to the chase, here is the complete table of commands:

=
kind_command_definition table_of_kind_commands[] = {
	{ "can-coincide-with-property", can_coincide_with_property_KCC, BOOLEAN_KCA },
	{ "can-exchange", can_exchange_KCC, BOOLEAN_KCA },
	{ "defined-in-source-text", defined_in_source_text_KCC, BOOLEAN_KCA },
	{ "has-i6-GPR", has_i6_GPR_KCC, BOOLEAN_KCA },
	{ "indexed-grey-if-empty", indexed_grey_if_empty_KCC, BOOLEAN_KCA },
	{ "is-incompletely-defined", is_incompletely_defined_KCC, BOOLEAN_KCA },
	{ "is-template-variable", is_template_variable_KCC, BOOLEAN_KCA },
	{ "multiple-block", multiple_block_KCC, BOOLEAN_KCA },
	{ "named-values-created-with-assertions",
		named_values_created_with_assertions_KCC, BOOLEAN_KCA },

	{ "constant-compilation-method", constant_compilation_method_KCC, CCM_KCA },

	{ "comparison-routine", comparison_routine_KCC, TEXT_KCA },
	{ "default-value", default_value_KCC, TEXT_KCA },
	{ "description", description_KCC, TEXT_KCA },
	{ "distinguisher", distinguisher_KCC, TEXT_KCA },
	{ "documentation-reference", documentation_reference_KCC, TEXT_KCA },
	{ "explicit-i6-GPR", explicit_i6_GPR_KCC, TEXT_KCA },
	{ "i6-printing-routine", i6_printing_routine_KCC, TEXT_KCA },
	{ "i6-printing-routine-actions", i6_printing_routine_actions_KCC, TEXT_KCA },
	{ "index-default-value", index_default_value_KCC, TEXT_KCA },
	{ "index-maximum-value", index_maximum_value_KCC, TEXT_KCA },
	{ "index-minimum-value", index_minimum_value_KCC, TEXT_KCA },
	{ "loop-domain-schema", loop_domain_schema_KCC, TEXT_KCA },
	{ "recognition-only-GPR", recognition_only_GPR_KCC, TEXT_KCA },
	{ "specification-text", specification_text_KCC, TEXT_KCA },

	{ "cast", cast_KCC, CONSTRUCTOR_KCA },
	{ "comparison-schema", comparison_schema_KCC, CONSTRUCTOR_KCA },
	{ "instance-of", instance_of_KCC, CONSTRUCTOR_KCA },

	{ "modifying-adjective", modifying_adjective_KCC, VOCABULARY_KCA },
	{ "plural", plural_KCC, VOCABULARY_KCA },
	{ "singular", singular_KCC, VOCABULARY_KCA },

	{ "constructor-arity", constructor_arity_KCC, TEXT_KCA },
	{ "group", group_KCC, NUMERIC_KCA },
	{ "heap-size-estimate", heap_size_estimate_KCC, NUMERIC_KCA },
	{ "index-priority", index_priority_KCC, NUMERIC_KCA },
	{ "small-block-size", small_block_size_KCC, NUMERIC_KCA },
	{ "template-variable-number", template_variable_number_KCC, NUMERIC_KCA },

	{ "apply-template", apply_template_KCC, TEMPLATE_KCA },

	{ "apply-macro", apply_macro_KCC, MACRO_KCA },

	{ NULL, -1, NO_KCA }
};

@ Where each legal command is defined with a block like so:

=
typedef struct kind_command_definition {
	char *text_of_command;
	int opcode_number;
	int operand_type;
} kind_command_definition;

@ Macros and templates have their definitions stored in structures thus:

=
typedef struct kind_template_definition {
	struct text_stream *template_name; /* including the asterisk, e.g., |"*PRINTING-ROUTINE"| */
	struct text_stream *template_text;
	CLASS_DEFINITION
} kind_template_definition;

typedef struct kind_macro_definition {
	struct text_stream *kind_macro_name; /* including the sharp, e.g., |"#UNIT"| */
	int kind_macro_line_count;
	struct single_kind_command kind_macro_line[MAX_KIND_MACRO_LENGTH];
	CLASS_DEFINITION
} kind_macro_definition;

@ And this makes a note to insert the relevant chunk of I7 source text
later on. (We do this because kind definitions are read very early on
in Inform's run, whereas I7 source text can only be lexed later.)

=
typedef struct kind_template_obligation {
	struct kind_template_definition *remembered_template; /* I7 source to insert... */
	struct kind_constructor *remembered_constructor; /* ...concerning this kind */
	CLASS_DEFINITION
} kind_template_obligation;

@h Errors and limitations.
In implementing the interpreter, we have to ask: who is it for? It occupies
a strange position in being not quite for end users -- the average Inform
user will never know what the template is -- and yet not quite for internal
use only, either. The main motivation for moving properties of kinds out of
Inform's program logic and into an external text file was to make it easier
to verify that they were correctly described; but it was certainly also
meant to give future Inform hackers -- users who like to burrow into
internals -- scope for play.

The I6 template files supplied with Inform's standard distribution are,
of course, correct. So how forgiving should we be, if errors are found in it?
(These must result from mistakes by hackers.) To what extent should we allow
arbitrarily complex constructions, as we would if it were a feature intended
for end users?

We strike a sort of middle position. Inform will probably not crash if an
incorrect kind command is supplied, but it is free to throw internal
errors or generate I6 code which fails to compile through I6.

@d MAX_KIND_MACRO_LENGTH 20 /* maximum number of commands in any one macro */

@h Setting up the interpreter.

=
void KindCommands::start(void) {
}

@h The kind command despatcher.
And this is where textual commands are received. (They come in from the
template interpreter.) Comments and blank lines have already been stripped out.

A template absorbs the raw text of its definition, and ends with |*END|;
whereas a macro absorbs the parsed form of its commands, and continues to
the next new heading. (Templates can't use the same end syntax because
they often need to contain I7 phrase definitions, where lines end with
colons.)

=
kind_constructor *constructor_described = NULL;

void KindCommands::despatch(parse_node_tree *T, text_stream *command) {
	if (KindCommands::recording_a_kind_template()) {
		if (Str::eq_wide_string(command, L"*END")) KindCommands::end_kind_template();
		else KindCommands::record_into_kind_template(command);
		return;
	}

	if (Str::get_last_char(command) == ':') {
		if (KindCommands::recording_a_kind_macro()) KindCommands::end_kind_macro();
		Str::delete_last_character(command); /* remove the terminal colon */
		@<Deal with the heading at the top of a kind command block@>;
		return;
	}

	single_kind_command stc = KindCommands::parse_kind_command(command);

	if (KindCommands::recording_a_kind_macro()) KindCommands::record_into_kind_macro(stc);
	else if (constructor_described) KindCommands::apply_kind_command(T, stc, constructor_described);
	else internal_error("kind command describes unspecified kind");
}

@<Deal with the heading at the top of a kind command block@> =
	if (Str::get_first_char(command) == '#') KindCommands::begin_kind_macro(command);
	else if (Str::get_first_char(command) == '*') KindCommands::begin_kind_template(command);
	else {
		TEMPORARY_TEXT(name)
		Str::copy(name, command);
		int should_know = FALSE;
		if (Str::get_first_char(name) == '+') { Str::delete_first_character(name); should_know = TRUE; }
		int do_know = FamiliarKinds::is_known(name);
		if ((do_know == FALSE) && (should_know == TRUE))
			internal_error("kind command describes kind with no known name");
		if ((do_know == TRUE) && (should_know == FALSE))
			internal_error("kind command describes already-known kind");
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
	}

@h Parsing single kind commands.
Each command is read in as text, parsed and stored into a modest structure.

=
single_kind_command KindCommands::parse_kind_command(text_stream *whole_command) {
	TEMPORARY_TEXT(command)
	TEMPORARY_TEXT(argument)
	single_kind_command stc;

	@<Parse line into command and argument, divided by a colon@>;

	@<Initialise the STC to a blank command@>;
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

@ Spaces and tabs after the colon are skipped; so a textual argument cannot
begin with those characters, but that doesn't matter for the things we need.

@<Parse line into command and argument, divided by a colon@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, whole_command, L" *(%c+?) *: *(%c+?) *")) {
		Str::copy(command, mr.exp[0]);
		Str::copy(argument, mr.exp[1]);
		Regexp::dispose_of(&mr);
	} else {
		KindCommands::kind_command_error(whole_command, "kind command without argument");
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

	if (stc.which_kind_command == NULL)
		KindCommands::kind_command_error(command, "no such kind command");

@<Parse a boolean argument for a kind command@> =
	if (Str::eq_wide_string(argument, L"yes")) stc.boolean_argument = TRUE;
	else if (Str::eq_wide_string(argument, L"no")) stc.boolean_argument = FALSE;
	else KindCommands::kind_command_error(command, "boolean kind command takes yes/no argument");

@<Parse a CCM argument for a kind command@> =
	if (Str::eq_wide_string(argument, L"none")) stc.ccm_argument = NONE_CCM;
	else if (Str::eq_wide_string(argument, L"literal")) stc.ccm_argument = LITERAL_CCM;
	else if (Str::eq_wide_string(argument, L"quantitative")) stc.ccm_argument = NAMED_CONSTANT_CCM;
	else if (Str::eq_wide_string(argument, L"special")) stc.ccm_argument = SPECIAL_CCM;
	else KindCommands::kind_command_error(command, "kind command with unknown constant-compilation-method");

@<Parse a textual argument for a kind command@> =
	Str::copy(stc.textual_argument, argument);

@<Parse a vocabulary argument for a kind command@> =
	stc.vocabulary_argument = WordAssemblages::lit_0();
	feed_t id = Feeds::begin();
	Feeds::feed_text(argument);
	wording W = Feeds::end(id);
	if (Wordings::length(W) >= 30)
		KindCommands::kind_command_error(command, "too many words in kind command");
	else
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
	stc.template_argument = KindCommands::parse_kind_template_name(argument);
	if (stc.template_argument == NULL)
		KindCommands::kind_command_error(command, "unknown template name in kind command");

@<Parse a macro name argument for a kind command@> =
	stc.macro_argument = KindCommands::parse_kind_macro_name(argument);
	if (stc.macro_argument == NULL)
		KindCommands::kind_command_error(command, "unknown template name in kind command");

@h Source text templates.
These are passages of I7 source text which can be inserted into the main
source text at the request of any kind. An example would be:
= (text)
	*UNDERSTOOD-VARIABLE:
	<kind> understood is a <kind> which varies.
	*END
=
The template |*UNDERSTOOD-VARIABLE| contains only a single sentence of source
text, and the idea is to make a new global variable associated with a given
kind. Note that the text is not quite literal, because it can contain
wildcards like |<kind>|, which expands to the name of the kind of value in
question: for instance, we might get

>> number understood is a number which varies.

There are a few limitations on what template text can include. Firstly,
nothing with angle brackets in, except where a wildcard appears. Secondly,
each sentence must end at the end of a line, and similarly the colon for
any rule or other definition. Thus this template would fail:
= (text)
	*UNDERSTOOD-VARIABLE:
	<kind> understood is a <kind> which
	varies. To judge <kind>: say "I judge [<kind> understood]."
	*END
=
because the first sentence ends in the middle of the second line, and the
colon dividing the phrase header from its definition is also mid-line. The
template must be reformatted thus to work:
= (text)
	*UNDERSTOOD-VARIABLE:
	<kind> understood is a <kind> which varies.
	To judge <kind>:
	    say "I judge [<kind> understood]."
	*END
=
@ So, to begin:

=
kind_template_definition *KindCommands::new_kind_template(text_stream *name) {
	kind_template_definition *ttd = CREATE(kind_template_definition);
	ttd->template_name = Str::duplicate(name);
	return ttd;
}

kind_template_definition *KindCommands::parse_kind_template_name(text_stream *name) {
	kind_template_definition *ttd;
	LOOP_OVER(ttd, kind_template_definition)
		if (Str::eq(name, ttd->template_name))
			return ttd;
	return NULL;
}

@ Here is the code which records templates, reading them as one line of plain
text at a time. (In the above example, |KindCommands::record_into_kind_template| would be
called just once, with the single source text line.)

=
kind_template_definition *current_kind_template = NULL; /* the one now being recorded */

int KindCommands::recording_a_kind_template(void) {
	if (current_kind_template) return TRUE;
	return FALSE;
}

void KindCommands::begin_kind_template(text_stream *name) {
	if (current_kind_template) internal_error("first stt still recording");
	if (KindCommands::parse_kind_template_name(name))
		internal_error("duplicate definition of source text template");
	current_kind_template = KindCommands::new_kind_template(name);
	current_kind_template->template_text = KindCommands::begin_recording_kind_text();
}

void KindCommands::record_into_kind_template(text_stream *line) {
	KindCommands::record_kind_text(line);
}

void KindCommands::end_kind_template(void) {
	if (current_kind_template == NULL) internal_error("no stt currently recording");
	KindCommands::end_recording_kind_text();
	current_kind_template = NULL;
}

@ So much for recording a template. To "play back", we need to take its text
and squeeze it into the main source text.

=
void KindCommands::transcribe_kind_template(parse_node_tree *T,
	kind_template_definition *ttd, kind_constructor *con) {
	if (ttd == NULL) internal_error("tried to transcribe missing source text template");
	#ifdef CORE_MODULE
	if ((Plugins::Manage::plugged_in(parsing_plugin) == FALSE) && (Str::eq(ttd->template_name, I"*UNDERSTOOD-VARIABLE")))
		return;
	#endif
	text_stream *p = ttd->template_text;
	int i = 0;
	while (Str::get_at(p, i)) {
		if ((Str::get_at(p, i) == '\n') || (Str::get_at(p, i) == ' ')) { i++; continue; }
		TEMPORARY_TEXT(template_line_buffer)
		int terminator = 0;
		@<Transcribe one line of the template into the line buffer@>;
		if (Str::len(template_line_buffer) > 0) {
			wording XW = Feeds::feed_text(template_line_buffer);
			if (terminator != 0) Sentences::make_node(T, XW, terminator);
		}
		DISCARD_TEXT(template_line_buffer)
	}
}

@ Inside template text, anything in angle brackets <...> is a wildcard.
These cannot be nested and cannot include newlines. All other material is
copied verbatim into the line buffer.

The only sentence terminators we recognise are full stop and colon; in
particular we wouldn't recognise a stop inside quoted matter. This does
not matter, since such things never come into kind definitions.

@<Transcribe one line of the template into the line buffer@> =
	while ((Str::get_at(p, i) != 0) && (Str::get_at(p, i) != '\n')) {
		if (Str::get_at(p, i) == '<') {
			TEMPORARY_TEXT(template_wildcard_buffer)
			i++;
			while ((Str::get_at(p, i) != 0) && (Str::get_at(p, i) != '\n') && (Str::get_at(p, i) != '>'))
				PUT_TO(template_wildcard_buffer, Str::get_at(p, i++));
			i++;
			@<Transcribe the template wildcard@>;
			DISCARD_TEXT(template_wildcard_buffer)
		} else PUT_TO(template_line_buffer, Str::get_at(p, i++));
	}
	if (Str::get_last_char(template_line_buffer) == '.') {
		Str::delete_last_character(template_line_buffer); terminator = '.';
	}
	if (Str::get_last_char(template_line_buffer) == ':') {
		Str::delete_last_character(template_line_buffer); terminator = ':';
	}

@ Only five wildcards are recognised:

@<Transcribe the template wildcard@> =
	if (Str::eq_wide_string(template_wildcard_buffer, L"kind"))
		@<Transcribe the kind's name@>
	else if (Str::eq_wide_string(template_wildcard_buffer, L"lower-case-kind"))
		@<Transcribe the kind's name in lower case@>
	else if (Str::eq_wide_string(template_wildcard_buffer, L"kind-weak-ID"))
		@<Transcribe the kind's weak ID@>
	else if (Str::eq_wide_string(template_wildcard_buffer, L"printing-routine"))
		@<Transcribe the kind's I6 printing routine@>
	else if (Str::eq_wide_string(template_wildcard_buffer, L"comparison-routine"))
		@<Transcribe the kind's I6 comparison routine@>
	else internal_error("no such source text template wildcard");

@<Transcribe the kind's name@> =
	KindCommands::transcribe_constructor_name(template_line_buffer, con, FALSE);

@<Transcribe the kind's name in lower case@> =
	KindCommands::transcribe_constructor_name(template_line_buffer, con, TRUE);

@<Transcribe the kind's weak ID@> =
	WRITE_TO(template_line_buffer, "%d", con->weak_kind_ID);

@<Transcribe the kind's I6 printing routine@> =
	WRITE_TO(template_line_buffer, "%S", con->dt_I6_identifier);

@<Transcribe the kind's I6 comparison routine@> =
	WRITE_TO(template_line_buffer, "%S", con->comparison_routine);

@ Where:

=
void KindCommands::transcribe_constructor_name(OUTPUT_STREAM, kind_constructor *con, int lower_case) {
	wording W = EMPTY_WORDING;
	if (con->dt_tag) W = Kinds::Constructors::get_name(con, FALSE);
	if (Wordings::nonempty(W)) {
		if (Kinds::Constructors::arity(con) > 0) {
			int full_length = Wordings::length(W);
			int i, w1 = Wordings::first_wn(W);
			for (i=0; i<full_length; i++) {
				if (i > 0) PUT(' ');
				vocabulary_entry *ve = Lexer::word(w1+i);
				if (ve == STROKE_V) break;
				if ((ve == CAPITAL_K_V) || (ve == CAPITAL_L_V)) WRITE("value");
				else WRITE("%V", ve);
			}
		} else {
			if (lower_case) WRITE("%+W", W);
			else WRITE("%W", W);
		}
	}
}

@h Type macros.
These are much simpler, and are just lists of kind commands grouped together
under names.

=
kind_macro_definition *current_kind_macro = NULL; /* the one now being recorded */

kind_macro_definition *KindCommands::new_kind_macro(text_stream *name) {
	kind_macro_definition *tmd = CREATE(kind_macro_definition);
	tmd->kind_macro_line_count = 0;
	tmd->kind_macro_name = Str::duplicate(name);
	return tmd;
}

kind_macro_definition *KindCommands::parse_kind_macro_name(text_stream *name) {
	kind_macro_definition *tmd;
	LOOP_OVER(tmd, kind_macro_definition)
		if (Str::eq(name, tmd->kind_macro_name))
			return tmd;
	return NULL;
}

@ And here once again is the code to record macros:

=
int KindCommands::recording_a_kind_macro(void) {
	if (current_kind_macro) return TRUE;
	return FALSE;
}

void KindCommands::begin_kind_macro(text_stream *name) {
	if (KindCommands::parse_kind_macro_name(name))
		internal_error("duplicate definition of kind command macro");
	current_kind_macro = KindCommands::new_kind_macro(name);
}

void KindCommands::record_into_kind_macro(single_kind_command stc) {
	if (current_kind_macro == NULL)
		internal_error("kind macro not being recorded");
	if (current_kind_macro->kind_macro_line_count >= MAX_KIND_MACRO_LENGTH)
		internal_error("kind macro contains too many lines");
	current_kind_macro->kind_macro_line[current_kind_macro->kind_macro_line_count++] = stc;
}

void KindCommands::end_kind_macro(void) {
	if (current_kind_macro == NULL) internal_error("ended kind macro outside one");
	current_kind_macro = NULL;
}

@ Playing back is easier, since it's just a matter of despatching the stored
commands in sequence to the relevant kind.

=
void KindCommands::play_back_kind_macro(parse_node_tree *T, kind_macro_definition *macro, kind_constructor *con) {
	if (macro == NULL) internal_error("no such kind macro to play back");
	LOGIF(KIND_CREATIONS, "Macro %S on %S (%d lines)\n",
		macro->kind_macro_name, con->name_in_template_code, macro->kind_macro_line_count);
	LOG_INDENT;
	for (int i=0; i<macro->kind_macro_line_count; i++)
		KindCommands::apply_kind_command(T, macro->kind_macro_line[i], con);
	LOG_OUTDENT;
	LOGIF(KIND_CREATIONS, "Macro %S ended\n", macro->kind_macro_name);
}

@h The kind text archiver.
Large chunks of the text in the template will need to exist permanently in
memory, and we go into recording mode to accept a series of them,
concatenated with newlines dividing them, in a text stream.

=
text_stream *kind_recording = NULL;

@ And here is recording mode:

=
text_stream *KindCommands::begin_recording_kind_text(void) {
	kind_recording = Str::new();
	return kind_recording;
}

void KindCommands::record_kind_text(text_stream *line) {
	if (kind_recording == NULL) internal_error("can't record outside recording");
	WRITE_TO(kind_recording, "%S\n", line);
}

void KindCommands::end_recording_kind_text(void) {
	kind_recording = NULL;
}

@h Error messages.

=
void KindCommands::kind_command_error(text_stream *command, char *error) {
	LOG("Kind command error found at: %S\n", command);
	internal_error(error);
}

@h Applying kind commands.
We take a single kind command and apply it to a given kind.

@d apply_macro_KCC 1
@d apply_template_KCC 2
@d can_coincide_with_property_KCC 5
@d can_exchange_KCC 6
@d cast_KCC 7
@d comparison_routine_KCC 8
@d comparison_schema_KCC 9
@d constant_compilation_method_KCC 10
@d constructor_arity_KCC 11
@d default_value_KCC 12
@d defined_in_source_text_KCC 13
@d description_KCC 14
@d distinguisher_KCC 15
@d documentation_reference_KCC 16
@d explicit_i6_GPR_KCC 17
@d group_KCC 18
@d has_i6_GPR_KCC 19
@d heap_size_estimate_KCC 20
@d i6_printing_routine_actions_KCC 21
@d i6_printing_routine_KCC 22
@d index_default_value_KCC 23
@d index_maximum_value_KCC 24
@d index_minimum_value_KCC 25
@d indexed_grey_if_empty_KCC 26
@d index_priority_KCC 27
@d instance_of_KCC 28
@d is_incompletely_defined_KCC 29
@d is_template_variable_KCC 30
@d loop_domain_schema_KCC 31
@d modifying_adjective_KCC 32
@d multiple_block_KCC 33
@d named_values_created_with_assertions_KCC 34
@d plural_KCC 35
@d recognition_only_GPR_KCC 36
@d singular_KCC 37
@d specification_text_KCC 38
@d small_block_size_KCC 39
@d template_variable_number_KCC 40

=
void KindCommands::apply_kind_command(parse_node_tree *T, single_kind_command stc, kind_constructor *con) {
	if (stc.which_kind_command == NULL) internal_error("null STC command");
	LOGIF(KIND_CREATIONS, "apply: %s (%d/%d/%S/%S) to %d/%S\n",
		stc.which_kind_command->text_of_command,
		stc.boolean_argument, stc.numeric_argument,
		stc.textual_argument, stc.constructor_argument,
		con->allocation_id, con->name_in_template_code);

	int tcc = stc.which_kind_command->opcode_number;

	@<Apply kind macros or transcribe kind templates on request@>;

	@<Most kind commands simply set a field in the constructor structure@>;
	@<A few kind commands contribute to linked lists in the constructor structure@>;
	@<And the rest fill in fields in the constructor structure in miscellaneous other ways@>;

	internal_error("unimplemented kind command");
}

@<Apply kind macros or transcribe kind templates on request@> =
	switch (tcc) {
		case apply_template_KCC:
			KindCommands::transcribe_kind_template(T, stc.template_argument, con);
			return;
		case apply_macro_KCC:
			KindCommands::play_back_kind_macro(T, stc.macro_argument, con);
			return;
	}

@

@d SET_BOOLEAN_FIELD(field) case field##_KCC: con->field = stc.boolean_argument; return;
@d SET_INTEGER_FIELD(field) case field##_KCC: con->field = stc.numeric_argument; return;
@d SET_TEXTUAL_FIELD(field) case field##_KCC: con->field = Str::duplicate(stc.textual_argument); return;
@d SET_CCM_FIELD(field) case field##_KCC: con->field = stc.ccm_argument; return;

@<Most kind commands simply set a field in the constructor structure@> =
	switch (tcc) {
		SET_BOOLEAN_FIELD(can_coincide_with_property)
		SET_BOOLEAN_FIELD(can_exchange)
		SET_BOOLEAN_FIELD(defined_in_source_text)
		SET_BOOLEAN_FIELD(has_i6_GPR)
		SET_BOOLEAN_FIELD(indexed_grey_if_empty)
		SET_BOOLEAN_FIELD(is_incompletely_defined)
		SET_BOOLEAN_FIELD(multiple_block)
		SET_BOOLEAN_FIELD(named_values_created_with_assertions)

		SET_INTEGER_FIELD(group)
		SET_INTEGER_FIELD(heap_size_estimate)
		SET_INTEGER_FIELD(index_priority)
		SET_INTEGER_FIELD(small_block_size)

		SET_CCM_FIELD(constant_compilation_method)

		SET_TEXTUAL_FIELD(default_value)
		SET_TEXTUAL_FIELD(distinguisher)
		SET_TEXTUAL_FIELD(documentation_reference)
		SET_TEXTUAL_FIELD(explicit_i6_GPR)
		SET_TEXTUAL_FIELD(index_default_value)
		SET_TEXTUAL_FIELD(index_maximum_value)
		SET_TEXTUAL_FIELD(index_minimum_value)
		SET_TEXTUAL_FIELD(loop_domain_schema)
		SET_TEXTUAL_FIELD(recognition_only_GPR)
		SET_TEXTUAL_FIELD(specification_text)
	}

@<A few kind commands contribute to linked lists in the constructor structure@> =
	if (tcc == cast_KCC) {
		#ifdef CORE_MODULE
		if ((Str::eq(stc.constructor_argument, I"SNIPPET_TY")) &&
			(Plugins::Manage::plugged_in(parsing_plugin) == FALSE)) return;
		#endif
		kind_constructor_casting_rule *dtcr = CREATE(kind_constructor_casting_rule);
		dtcr->next_casting_rule = con->first_casting_rule;
		con->first_casting_rule = dtcr;
		dtcr->cast_from_kind_unparsed = Str::duplicate(stc.constructor_argument);
		dtcr->cast_from_kind = NULL;
		return;
	}
	if (tcc == instance_of_KCC) {
		kind_constructor_instance *dti = CREATE(kind_constructor_instance);
		dti->next_instance_rule = con->first_instance_rule;
		con->first_instance_rule = dti;
		dti->instance_of_this_unparsed = Str::duplicate(stc.constructor_argument);
		dti->instance_of_this = NULL;
		return;
	}
	if (tcc == comparison_schema_KCC) {
		kind_constructor_comparison_schema *dtcs = CREATE(kind_constructor_comparison_schema);
		dtcs->next_comparison_schema = con->first_comparison_schema;
		con->first_comparison_schema = dtcs;
		dtcs->comparator_unparsed = Str::duplicate(stc.constructor_argument);
		dtcs->comparator = NULL;
		dtcs->comparison_schema = Str::duplicate(stc.textual_argument);
		return;
	}

@<And the rest fill in fields in the constructor structure in miscellaneous other ways@> =
	switch (tcc) {
		case constructor_arity_KCC:
			@<Parse the constructor arity text@>;
			return;
		case description_KCC:
			con->constructor_description = Str::duplicate(stc.textual_argument);
			return;
		case comparison_routine_KCC:
			if (Str::len(stc.textual_argument) > 31) internal_error("overlong I6 identifier");
			else con->comparison_routine = Str::duplicate(stc.textual_argument);
			return;
		case i6_printing_routine_KCC:
			if (Str::len(stc.textual_argument) > 31) internal_error("overlong I6 identifier");
			else con->dt_I6_identifier = Str::duplicate(stc.textual_argument);
			return;
		case i6_printing_routine_actions_KCC:
			if (Str::len(stc.textual_argument) > 31) internal_error("overlong I6 identifier");
			else con->name_of_printing_rule_ACTIONS = Str::duplicate(stc.textual_argument);
			return;
		case singular_KCC: case plural_KCC: {
			vocabulary_entry **array; int length;
			WordAssemblages::as_array(&(stc.vocabulary_argument), &array, &length);
			if (length == 1) {
				Kinds::mark_vocabulary_as_kind(array[0], Kinds::base_construction(con));
			} else {
				int i;
				for (i=0; i<length; i++) {
					Vocabulary::set_flags(array[i], KIND_SLOW_MC);
					NTI::mark_vocabulary(array[i], <k-kind>);
				}
				if (con->group != PROPER_CONSTRUCTOR_GRP) {
					vocabulary_entry *ve = WordAssemblages::hyphenated(&(stc.vocabulary_argument));
					if (ve) Kinds::mark_vocabulary_as_kind(ve, Kinds::base_construction(con));
				}
			}
			feed_t id = Feeds::begin();
			for (int i=0; i<length; i++)
				Feeds::feed_C_string(Vocabulary::get_exemplar(array[i], FALSE));
			wording LW = Feeds::end(id);
			if (tcc == singular_KCC) {
				int ro = 0;
				if (con->group != PROPER_CONSTRUCTOR_GRP) ro = ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT;
				NATURAL_LANGUAGE_WORDS_TYPE *L = NULL;
				#ifdef CORE_MODULE
				L = Task::language_of_syntax();
				#endif
				noun *nt =
					Nouns::new_common_noun(LW, NEUTER_GENDER, ro,
					KIND_SLOW_MC, STORE_POINTER_kind_constructor(con), L);
				con->dt_tag = nt;
			} else {
				NATURAL_LANGUAGE_WORDS_TYPE *L = NULL;
				#ifdef CORE_MODULE
				L = Task::language_of_syntax();
				#endif
				Nouns::set_nominative_plural_in_language(con->dt_tag, LW, L);
			}
			return;
		}
		case modifying_adjective_KCC:
			internal_error("the modifying-adjective syntax has been withdrawn");
			return;
	}

@<Parse the constructor arity text@> =
	int c = 0;
	string_position pos = Str::start(stc.textual_argument);
	while (TRUE) {
		while (Characters::is_space_or_tab(Str::get(pos))) pos = Str::forward(pos);
		if (Str::get(pos) == 0) break;
		if (Str::get(pos) == ',') { c++; pos = Str::forward(pos); continue; }
		if (c >= 2) { c=1; break; }
		TEMPORARY_TEXT(wd)
		while ((!Characters::is_space_or_tab(Str::get(pos))) && (Str::get(pos) != ',') && (Str::get(pos) != 0)) {
			PUT_TO(wd, Str::get(pos)); pos = Str::forward(pos);
		}
		if (Str::len(wd) > 0) {
			if (Str::eq_wide_string(wd, L"covariant")) con->variance[c] = COVARIANT;
			else if (Str::eq_wide_string(wd, L"contravariant")) con->variance[c] = CONTRAVARIANT;
			else if (Str::eq_wide_string(wd, L"optional")) con->tupling[c] = ALLOW_NOTHING_TUPLING;
			else if (Str::eq_wide_string(wd, L"list")) con->tupling[c] = ARBITRARY_TUPLING;
			else {
				LOG("Word: <%S>\n", wd);
				internal_error("illegal constructor-arity keyword");
			}
		}
		DISCARD_TEXT(wd)
	}
	con->constructor_arity = c+1;

@h Completing a batch.
At one time it was useful to do some mopping-up work after a round of kind
commands, so the following hook was devised; but at present it's not needed.

=
void KindCommands::batch_done(void) {
}

@ And that completes the kind interpreter.
