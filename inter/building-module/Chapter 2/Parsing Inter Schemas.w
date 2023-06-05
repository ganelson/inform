[ParsingSchemas::] Parsing Inter Schemas.

A simple API for turning textual code written in Inform 6 syntax into an inter
schema.

@h Just plain code.
If all we need is a schema from some code in a text, we can call this.

If the text contains syntax errors, these are attached to the schema returned;
so it's the caller's responsibility to check for those and act accordingly.

Note that the results can be tested independently of //inform7// using the
//building-test// unit test tool, whose tests verify that a great many I6
samples produce the correct schemas.

=
inter_schema *ParsingSchemas::from_text(text_stream *from, text_provenance provenance) {
	return ParsingSchemas::back_end(from, FALSE, 0, NULL, provenance);
}

@h Abbreviated I6S notation.
This is a slicker notation used inside the //calculus// module for purposes
such as representing how to compile a test of a given binary predicate, or
how to store data in a given storage object. For example, |*1.frog == *2.frog|
is a valid I6S notation, using the placeholders |*1| and |*2| to represent
the two terms of a binary predicate. See //calculus: Compilation Schemas//
for more on this notation.

Here, it's quite possible that the same piece of notation will be asked for
more than once, and we want to reply quickly, so we use a hashed dictionary
to return any already-computed answer quickly.

If the text contains syntax errors, these throw an internal error. Erroneous
I6S code can only come from within the compiler itself, and means a bug.

=
dictionary *i6s_inter_schema_cache = NULL;

inter_schema *ParsingSchemas::from_i6s(text_stream *from,
	int no_quoted_inames, void **quoted_inames) {
	if (i6s_inter_schema_cache == NULL) {
		i6s_inter_schema_cache = Dictionaries::new(512, FALSE);
	}
	dict_entry *de = Dictionaries::find(i6s_inter_schema_cache, from);
	if (de) return (inter_schema *) Dictionaries::value_for_entry(de);

	inter_schema *result = ParsingSchemas::back_end(from, TRUE,
		no_quoted_inames, quoted_inames, Provenance::nowhere());

	Dictionaries::create(i6s_inter_schema_cache, from);
	Dictionaries::write_value(i6s_inter_schema_cache, from, (void *) result);

	I6Errors::internal_error_on_schema_errors(result);
	return result;
}

@h Inline phrase definitions.
This is a typical inline phrase definition which //inform7// must handle:
= (text as Inform 7)
	To say (L - a list of values) in brace notation:
		(- LIST_OF_TY_Say({-by-reference:L}, 1); -).
=
Essentially, this defines "say ... in brace notation" as meaning the schema
coming from the text |LIST_OF_TY_Say({-by-reference:L}, 1);|.

Note that the //inform7// compiler calls //ParsingSchemas::from_inline_phrase_definition//
only once on such a definition -- it would clearly be slow and wasteful to parse
it anew each time it is used. Because of that, only 100 or so calls to this function
are made in a typical run, and so speed is not critical here.

@ That was a simple example, in that only one schema was involved: it is a
head which has no tail.

However, a few inline phrases make use of the notation |{-block}|, which
represents a block of code -- usually a loop body -- and which divides the
definition into a head part, before the block, and a tail part, after. So
in general we may have to compile two schemas, not one.

The text |from| is in a wide C string because it's coming raw from the lexer,
as the content of a |(- ... -)| lexeme, but with the |(-| and |-)| removed.

If the text contains syntax errors, these are attached to the schema returned;
so it's the caller's responsibility to check for those and act accordingly.

=
void ParsingSchemas::from_inline_phrase_definition(wchar_t *from, inter_schema **head,
	inter_schema **tail, text_provenance provenance) {
	*head = NULL; *tail = NULL;

	text_stream *head_defn = Str::new();
	text_stream *tail_defn = Str::new();
	@<Fetch the head and tail definitions@>;

	*head = ParsingSchemas::from_text(head_defn, provenance);
	if (Str::len(tail_defn) > 0)
		*tail = ParsingSchemas::from_text(tail_defn, provenance);
}

@ A tail will only be present if the definition contains |{-block}|. If it
does, we then split the definition into a head and a tail, and again trim
white space from each. Note that |{-block}| is not legal anywhere else.

For example:

>> To repeat with a King's Court begin -- end loop:

could be given the definition:
= (text as Inform 6)
	@push {-my:trcount};
	for (trcount=1; trcount<=3; trcount++)
	    {-block}
	@pull trcount;
=
This then repeats what it's given three times, while guaranteeing that the
counter is always a local variable called |trcount|, and that no matter how
such operations are nested, they will work. We might then write:
= (text as Inform 7)
	To say iteration: (- print {-my:trcount}; -).
=
and then this will work as might be hoped:
= (text as Inform 7)
	repeat with a King's Court:
	    say "[iteration]...";
	        repeat with a King's Court:
	            say "[iteration]. You play a Shanty Town, getting +2 Actions.";
=

@<Fetch the head and tail definitions@> =
	while (Characters::is_whitespace(*from)) from++;
	WRITE_TO(head_defn, "%w", from);
	int effective_end = 0;
	for (int i=0, L=Str::len(head_defn); i<L; i++)
		if (!(Characters::is_whitespace(Str::get_at(head_defn, i))))
			effective_end = i+1;
	Str::truncate(head_defn, effective_end);

	for (int i=0, L=Str::len(head_defn); i<L; i++)
		if (Str::includes_wide_string_at(head_defn, L"{-block}", i)) {
			int after = i+8, before = i;
			while (Characters::is_whitespace(Str::get_at(head_defn, after))) after++;
			while (Characters::is_whitespace(Str::get_at(head_defn, before-1))) before--;
			Str::copy_tail(tail_defn, head_defn, after);
			Str::truncate(head_defn, before);
			break;
		}

@ The public API above funnels down through this more private function:

=
inter_schema *ParsingSchemas::back_end(text_stream *from, int abbreviated,
	int no_quoted_inames, void **quoted_inames, text_provenance provenance) {
	inter_schema *sch = InterSchemas::new(from, provenance);
	if ((Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) ||
		(Log::aspect_switched_on(SCHEMA_COMPILATION_DETAILS_DA)))
		LOG("\n\n------------\nCompiling inter schema from: <%S>\n", from);

	int pos = 0;
	if ((abbreviated) && (Str::begins_with_wide_string(from, L"*=-"))) {
		sch->dereference_mode = TRUE; pos = 3;
	}
	Tokenisation::go(sch, from, pos, abbreviated, no_quoted_inames, quoted_inames);
	if ((Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) ||
		(Log::aspect_switched_on(SCHEMA_COMPILATION_DETAILS_DA)))
		LOG("Tokenised inter schema:\n$1", sch);
	
	Ramification::go(sch);
	InterSchemas::lint(sch);

	if ((Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) ||
		(Log::aspect_switched_on(SCHEMA_COMPILATION_DETAILS_DA)))
		LOG("Completed inter schema:\n$1", sch);
	return sch;
}
