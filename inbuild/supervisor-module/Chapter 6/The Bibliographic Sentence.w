[BiblioSentence::] The Bibliographic Sentence.

That line at the top of an Inform source text, saying what it is and who wrote it.

@ It might seem sensible to parse the opening sentence of the source text,
the bibliographic sentence giving title and author, by looking at the result
of sentence-breaking: in other words, to wait until the syntax tree for a
project has been read in.

But this isn't fast enough, because the sentence also specifies the language
of syntax, and we need to know of any non-English choice immediately. So a
special hook in the //syntax// module calls the following function as soon as
such a sentence is found; thus, it happens during sentence-breaking, not
after it, and may therefore affect how subsequent sentences are broken.

@e BadTitleSentence_SYNERROR

=
void BiblioSentence::notify(inform_project *proj, parse_node *PN) {
	wording W = Node::get_text(PN);
	if (<titling-line>(W)) {
		text_stream *T = proj->as_copy->edition->work->title;
		if (proj->as_copy->edition->work->author_name == NULL)
			proj->as_copy->edition->work->author_name = Str::new();
		text_stream *A = proj->as_copy->edition->work->author_name;
		inform_language *L = <<rp>>;
		if (L) {
			Projects::set_language_of_play(proj, L);
			LOG("Language of play: %S\n", L->as_copy->edition->work->title);
		}
		@<Extract title and author name wording@>;
		@<Dequote the title and, perhaps, author name@>;
	} else {
		copy_error *CE = CopyErrors::new(SYNTAX_CE, BadTitleSentence_SYNERROR);
		CopyErrors::supply_node(CE, PN);
		Copies::attach_error(proj->as_copy, CE);
	}
}

@ This is what the top line of the main source text should look like, if it's
to declare the title and author.

=
<titling-line> ::=
	<plain-titling-line> ( in <natural-language> ) |  ==> R[1]; *XP = RP[2];
	<plain-titling-line>                              ==> R[1]; *XP = NULL;

<plain-titling-line> ::=
	{<quoted-text-without-subs>} by ... |  ==> TRUE
	{<quoted-text-without-subs>}           ==> FALSE

@<Extract title and author name wording@> =
	wording TW = GET_RW(<plain-titling-line>, 1);
	wording AW = EMPTY_WORDING;
	if (<<r>>) AW = GET_RW(<plain-titling-line>, 2);
	Str::clear(T);
	WRITE_TO(T, "%+W", TW);
	if (Wordings::nonempty(AW)) {
		Str::clear(A);
		WRITE_TO(A, "%+W", AW);
	}

@ The author is sometimes given outside of quotation marks:

>> "The Large Scale Structure of Space-Time" by Lindsay Lohan

But not always:

>> "Greek Rural Postmen and Their Cancellation Numbers" by "will.i.am"

@<Dequote the title and, perhaps, author name@> =
	Str::trim_white_space(T);
	if ((Str::get_first_char(T) == '\"') && (Str::get_last_char(T) == '\"')) {
		Str::delete_first_character(T);
		Str::delete_last_character(T);
		Str::trim_white_space(T);
	}
	LOG("Title: %S\n", T);
	Str::trim_white_space(A);
	if ((Str::get_first_char(A) == '\"') && (Str::get_last_char(A) == '\"')) {
		Str::delete_first_character(A);
		Str::delete_last_character(A);
		Str::trim_white_space(A);
	}
	if (Str::len(A) > 0) LOG("Author: %S\n", A);
