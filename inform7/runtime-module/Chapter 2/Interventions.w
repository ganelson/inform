[Interventions::] Interventions.

Material written in low-level Inform 6 notation can be emitted for later
linking, a distasteful process called "intervening".

@ Interventions are a very low-level language feature. Just as some C compilers,
such as |gcc|, allow assembly-language code to be inserted at crucial points
in the middle of C, so Inform 7 source text allows fragments of I6 notation to
be "included". This is done by embedding it, more or less in plain text, into
the Inter hierarchy; it will only be compiled to Inter code by assimilation at
the linking stage.

Note that this is different from the ability to define phrases inline, which
also uses I6 notation, but is fully decoded in the main compiler. Here we are
looking at the consequences of, for example,
= (text)
Use predictable randomisation translates as (- Constant FIX_RNG; -).
Include (-
	[ MyOddballFunction x;
		print 2*x;
	];
-).
=
See //assertions: Intervention Requests// for how such Include sentences are
handled. Each one leads to the creation of a |source_text_intervention| object;
so now we work through those objects and take the necessary action to put the
raw I6 matter into the Inter tree.

Firstly, here are the free-standing interventions:

=
void Interventions::make_all(void) {
	source_text_intervention *sti;
	LOOP_OVER(sti, source_text_intervention)
		if (sti->infs_to_include_with == NULL) {
			current_sentence = sti->where_made;
			Emit::intervention(Interventions::expand_bracket_plus(sti->matter),
				sti->replacing);
		}
}

@ Secondly, here are those which append properties to instance or class declarations:

=
void Interventions::make_for_subject(inter_name *iname, inference_subject *infs) {
	source_text_intervention *sti;
	LOOP_OVER(sti, source_text_intervention)
		if (sti->infs_to_include_with == infs) {
			current_sentence = sti->where_made;
			Emit::append(iname, Interventions::expand_bracket_plus(sti->matter));
		}
}

@ Not to digress,[1] but the following function has a surprising history. In the
pre-2015 design of Inform, it was a formidably complex function. It was used
to read |*.i6t| template files, as they were then: the precursors of today's
kits. Those were allowed to use a wide range of complex markup commands which
are now no longer supported. The special |Main.i6t| used this ability in order
to serve as, essentially, the entire top-level logic of the compiler, calling
hundreds of different functions.[2] There were also numerous features for
having template files open each other, or switch output on and off: none of
this makes sense in the age of Inter. Finally, until 2021 this function was
also used to parse kind declarations (what we now call Neptune files) and
index content, and it could read from a stream, or a directory, or a wide C
string, and so on. This complicated matters further still.

The function now has a single purpose: it takes a text such as |x = (+ time of day +);|
and writes out an I6 stream in which any material in |(+| ... |+)| markers is
replaced by an I6 paraphrase. For example, it might output |x = thetime;|.

[1] I.e., to digress.

[2] You can find this design pattern recommended by seminal books such as
Eric Raymond's "The Art of Unix Programming" or Andy Hunt and Dave Thomas's
"The Pragmatic Programmer", but I have come to distrust it. It left the
compiler's specification ambiguous: if |Main.i6t| chose to skip steps, or
perform them in the "wrong" order, what should the compiler do?

=
text_stream *Interventions::expand_bracket_plus(text_stream *S) {
	text_stream *OUT = Str::new();
	int col = 1, cr, sfp = 0;
	TEMPORARY_TEXT(heading_name)
	TEMPORARY_TEXT(command)
	TEMPORARY_TEXT(argument)
	do {
		Str::clear(command);
		Str::clear(argument);
		@<Read next character@>;
		NewCharacter: if (cr == EOF) break;
		if (cr == '{') {
			@<Read next character@>;
			if (cr == '-') {
				@<Read up to the next close brace as an I6T command and argument@>;
				if (Str::get_first_char(command) == '!') continue;
				@<Act on I6T command and argument@>;
				continue;
			} else { /* otherwise the open brace was a literal */
				if (OUT) PUT_TO(OUT, '{');
				goto NewCharacter;
			}
		}
		if (cr == '(') {
			@<Read next character@>;
			if (cr == '+') {
				@<Read up to the next plus close-bracket as an I7 expression@>;
				continue;
			} else { /* otherwise the open bracket was a literal */
				if (OUT) PUT_TO(OUT, '(');
				goto NewCharacter;
			}
		}
		if (OUT) PUT_TO(OUT, cr);
	} while (cr != EOF);
	DISCARD_TEXT(command)
	DISCARD_TEXT(argument)
	DISCARD_TEXT(heading_name)
	return OUT;
}

@<Read next character@> =
	cr = Str::get_at(S, sfp); if (cr == 0) cr = EOF; else sfp++;
	col++; if ((cr == 10) || (cr == 13)) col = 0;

@ Our biggest complication is that I7 expressions can be included in the I6
matter with the |(+| and |+)| notation. For example,
= (text)
	Constant FROG_CL = (+ pond-dwelling amphibian +);
=
will expand "pond-dwelling amphibian" into the I6 translation of the kind
of object with this name. Because of this syntax, one has to watch out for
I6 code like so:
= (text as Inform 6)
	if (++counter_of_some_kind > 0) ...
=
which can trigger an unwanted |(+|.

@<Read up to the next plus close-bracket as an I7 expression@> =
	TEMPORARY_TEXT(i7_exp)
	while (TRUE) {
		@<Read next character@>;
		if (cr == EOF) break;
		if ((cr == ')') && (Str::get_last_char(i7_exp) == '+')) {
			Str::delete_last_character(i7_exp); break; }
		PUT_TO(i7_exp, cr);
	}
	wording W = Feeds::feed_text(i7_exp);
	CSIInline::eval_bracket_plus_to_text(OUT, W);
	DISCARD_TEXT(i7_exp)

@<Read up to the next close brace as an I6T command and argument@> =
	Str::clear(command);
	Str::clear(argument);
	int com_mode = TRUE;
	while (TRUE) {
		@<Read next character@>;
		if ((cr == '}') || (cr == EOF)) break;
		if ((cr == ':') && (com_mode)) { com_mode = FALSE; continue; }
		if (com_mode) PUT_TO(command, cr);
		else PUT_TO(argument, cr);
	}

@<Act on I6T command and argument@> =
	LOG("command: <%S> argument: <%S>\n", command, argument);
	Problems::quote_stream(1, command);
	StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(PM_TemplateError),
		"In an explicit Inform 6 code insertion, I recognise a few special "
		"notations in the form '{-command}'. This time, though, the unknown notation "
		"{-%1} has been used, and this is an error. (It seems very unlikely indeed "
		"that this could be legal Inform 6 which I'm misreading, but if so, try "
		"adjusting the spacing to make this problem message go away.)");

