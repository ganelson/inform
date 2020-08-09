[KindFiles::] Kind Files.

To read in details of built-in kind constructors from template files,
setting them up ready for use.

@ There's nothing to this:

=
void KindFiles::load(parse_node_tree *T, filename *F) {
	TextFiles::read(F, FALSE, "unable to read kinds file", TRUE,
		&KindFiles::load_kinds_helper, NULL, T);
}

void KindFiles::load_kinds_helper(text_stream *text, text_file_position *tfp, void *state) {
	parse_node_tree *T = (parse_node_tree *) state;
	if ((Str::get_first_char(text) == '!') ||
		(Str::get_first_char(text) == 0)) return; /* skip blanks and comments */
	KindCommands::despatch(T, text);
}
