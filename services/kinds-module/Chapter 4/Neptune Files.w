[NeptuneFiles::] Neptune Files.

To read in details of built-in kind constructors from so-called Neptune files,
setting them up ready for use.

@ Neptune files are lists of kind constructor commands, so the following
code simply reads the lines, removes blanks and comments, and then passes
on those commands. The name derives from the Place Neptune, Carcassonne,
where these files were first conceived and implemented.

=
void NeptuneFiles::load(filename *F) {
	parse_node *cs = current_sentence;
	current_sentence = NULL;
	TextFiles::read(F, FALSE, "unable to read kinds file", TRUE,
		&NeptuneFiles::load_kinds_helper, NULL, NULL);
	current_sentence = cs;
}

void NeptuneFiles::load_kinds_helper(text_stream *text, text_file_position *tfp, void *state) {
	NeptuneFiles::read_command(text, tfp);
}

void NeptuneFiles::read_command(text_stream *command, text_file_position *tfp) {
	Str::trim_white_space(command);
	if ((Str::get_first_char(command) == '!') ||
		(Str::get_first_char(command) == 0)) return; /* skip blanks and comments */

	single_kind_command stc = NeptuneSyntax::parse_command(command, tfp);
	if (stc.completed) return;

	if (NeptuneMacros::recording()) NeptuneMacros::record_into_macro(stc, tfp);
	else if (stc.defined_for) KindCommands::apply(stc, stc.defined_for);
	else NeptuneFiles::error(command, I"kind command describes unspecified kind", tfp);
}

@ Neptune files are in the strange position in being not quite for end users --
the average Inform user will never even see one -- but they are not quite for
internal use only, either. The main motivation for moving properties of kinds
out of Inform's program logic and into an external text file was to make it
easier to verify that they were correctly set up, but they were certainly also
meant to give future Inform hackers -- users who like to burrow into
internals -- scope for play.

The Neptune files supplied with Inform's standard distribution are correct,
so errors can only result from mistakes by hackers. Until 2020 these simply
threw internal errors; we now issue errors up to the user in such a way that
the Inform GUI can at least display them, if not very elegantly.

=
void NeptuneFiles::error(text_stream *command, text_stream *error,
	text_file_position *tfp) {
	TEMPORARY_TEXT(E)
	if (tfp)
		WRITE_TO(E,
			"error in Neptune file '%f', line %d ('%S'): %S",
				tfp->text_file_filename, tfp->line_count, command, error);
	else
		WRITE_TO(E,
			"error in Neptune command execution: %S", error);
	KindsModule::problem_handler(NeptuneError_KINDERROR, NULL, E, NULL, NULL);
	DISCARD_TEXT(E)
}

void NeptuneFiles::warning(text_stream *command, text_stream *error,
	text_file_position *tfp) {
	TEMPORARY_TEXT(E)
	if (tfp)
		WRITE_TO(E,
			"warning on Neptune file '%f', line %d ('%S'): %S",
				tfp->text_file_filename, tfp->line_count, command, error);
	else
		WRITE_TO(E,
			"warning on Neptune command execution: %S", error);
	KindsModule::problem_handler(NeptuneError_KINDERROR, NULL, E, NULL, NULL);
	DISCARD_TEXT(E)
}
