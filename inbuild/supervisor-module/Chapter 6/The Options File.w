[OptionsFile::] The Options File.

The optional file of Options applied to all of the user's projects.

@ An Inform user with unyielding views on punctuation may want to have:

>> Use the serial comma.

applied to every project she works on. For such needs, it's possible to
create an |Options.txt| file of sentence which are present, by implication,
in every project.

When Inform reads this file, very early in its run, it tries to obey any use
options in the file right away -- earlier even than <structural-sentence>. It
spots these, very crudely, as sentences which match the following (that is,
which start with "use"). Note the final full stop -- this is all occurring
before sentence-breaking has even taken place. Fortunately, no matter how
unyielding the user's views, it's not allowed to write:

>> Use the serial comma!

so the sentence-terminator will certainly be a full stop.

=
<use-option-sentence-shape> ::=
	use <immediate-use> .

<immediate-use> ::=
	... |                                         ==> { lookahead }
	<immediate-use-entry> <immediate-use-tail> |
	<immediate-use-entry>

<immediate-use-tail> ::=
	, _and <immediate-use> |
	_,/and <immediate-use>

<immediate-use-entry> ::=
	<notable-use-option-name> |                   ==> @<Act on this use option immediately@>
	......

@<Act on this use option immediately@> =
	#ifdef CORE_MODULE
	CompilationSettings::set(R[1], -1, NULL);
	#endif
	
@ There is just one options file, so no need to load it more than once.

=
wording options_file_wording = EMPTY_WORDING_INIT;

void OptionsFile::read(filename *F) {
	if (Wordings::empty(options_file_wording)) {
		feed_t id = Feeds::begin();
		TextFiles::read(F, TRUE,
			NULL, FALSE, OptionsFile::read_helper, NULL, NULL);
		options_file_wording = Feeds::end(id);
	}
}

void OptionsFile::read_helper(text_stream *line,
	text_file_position *tfp, void *unused_state) {
	WRITE_TO(line, "\n");
	wording W = Feeds::feed_text(line);
	<use-option-sentence-shape>(W);
}
