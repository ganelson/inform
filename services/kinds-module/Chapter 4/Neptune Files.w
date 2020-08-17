[NeptuneFiles::] Neptune Files.

To read in details of built-in kind constructors from so-called Neptune files,
setting them up ready for use.

@ Neptune files are lists of kind constructor commands, so the following
code simply reads the lines, removes blanks and comments, and then passes
on those commands. The name derives from the Place Neptune, Carcassonne,
where these files were first conceived and implemented.

=
void NeptuneFiles::load(parse_node_tree *T, filename *F) {
	TextFiles::read(F, FALSE, "unable to read kinds file", TRUE,
		&NeptuneFiles::load_kinds_helper, NULL, T);
}

void NeptuneFiles::load_kinds_helper(text_stream *text, text_file_position *tfp, void *state) {
	parse_node_tree *T = (parse_node_tree *) state;
	if ((Str::get_first_char(text) == '!') ||
		(Str::get_first_char(text) == 0)) return; /* skip blanks and comments */
	KindCommands::despatch(T, text);
}

@ Neptune files are in the strange position in being not quite for end users --
the average Inform user will never even see one -- but they are not quite for
internal use only, either. The main motivation for moving properties of kinds
out of Inform's program logic and into an external text file was to make it
easier to verify that they were correctly set up, but they were certainly also
meant to give future Inform hackers -- users who like to burrow into
internals -- scope for play.

The Neptune files supplied with Inform's standard distribution are correct,
so errors can only result from mistakes by such hackers. We strike a sort of
middle position: when we fine errors, we won't feel obliged to produce
elegant problem messages, and will instead throw internal errors or (in some
cases) generate incorrect Inter code leading to internal errors later on.
But we won't actually crash if we can help it.

=
void NeptuneFiles::error(text_stream *command, char *error) {
	LOG("Kind command error found at: %S\n", command);
	internal_error(error);
}
