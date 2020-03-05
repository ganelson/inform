[Config::Inclusions::] Inform 6 Inclusions.

To include Inform 6 code almost verbatim in the output, as instructed
by low-level Inform 7 sentences.

@h Definitions.

@ Inclusions are a very low-level language feature: rather like the way some
C compilers, such as |gcc|, allow assembly-language code to be inserted at
crucial points in the middle of C, so Inform 7 allows fragments of I6 code
to be "included". Note that this is different from the ability to define
phrases using I6: what we're talking about here is the ability to add I6
material in Class or Object definitions, or simply in between other
declarations in the I6 output, but always outside of a routine.

=
typedef struct i6_inclusion_matter {
	struct parse_node *material_to_include; /* normally an I6 escape |(- ... -)| */
	struct inference_subject *infs_to_include_with; /* typically an object or class definition */
	MEMORY_MANAGEMENT
} i6_inclusion_matter;

@ Inclusions are primitive things, but fine control is needed over exactly
where they go.

@d SEGMENT_LEVEL_INC 1		/* before, instead of, or after a segment of I6 template */
@d SECTION_LEVEL_INC 2		/* before, instead of, or after a section of I6 template */
@d WHEN_DEFINING_INC 3		/* as part of an Object or Class definition */
@d AS_PREFORM_INC 4 		/* include it not as I6, but as Preform grammar */

@ Some variables used only in parsing inclusion instructions:

=
int inclusion_side, section_inclusion_wn, segment_inclusion_wn;

@ Include sentences are a way to merge lower-level programming, from another
language, into Inform source text. They are intended only as a last resort,
though seasoned I6 hackers tend to reach for them a little sooner than that.

A sentence typically takes the form:

>> Include (- ... -) when defining a thing.

and the following grammar defines the "when defining a thing" end.

=
<inform6-inclusion-location> ::=
	<inclusion-side> {<quoted-text-without-subs>} |	==> @<Note segment-level inclusion@>
	<inclusion-side> {<quoted-text-without-subs>} in {<quoted-text-without-subs>} |	==> @<Note section-level inclusion@>
	when defining <s-type-expression> |			==> WHEN_DEFINING_INC; <<parse_node:s>> = RP[1]
	when defining ... |								==> @<Issue PM_WhenDefiningUnknown problem@>
	before the library |							==> @<Issue PM_BeforeTheLibrary problem@>
	in the preform grammar							==> AS_PREFORM_INC

<inclusion-side> ::=
	before |										==> BEFORE_LINK_STAGE
	instead of |									==> INSTEAD_LINK_STAGE
	after											==> AFTER_LINK_STAGE

@<Note segment-level inclusion@> =
	*X = SEGMENT_LEVEL_INC;
	inclusion_side = R[1]; segment_inclusion_wn = R[2];

@<Note section-level inclusion@> =
	*X = SECTION_LEVEL_INC;
	inclusion_side = R[1]; section_inclusion_wn = R[2]; segment_inclusion_wn = R[3];

@<Issue PM_WhenDefiningUnknown problem@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_WhenDefiningUnknown),
		"I do not understand what definition you're referring to",
		"so I can't make an Inform 6 inclusion there.");

@<Issue PM_BeforeTheLibrary problem@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_BeforeTheLibrary),
		"this syntax was withdrawn in January 2008",
		"in favour of a more finely controlled I6 inclusion command. The effect "
		"you want can probably be achieved by writing 'after \"Definitions.i6t\".' "
		"instead of 'before the library.'");

@ Note that although Preform inclusions are syntactically like I6 inclusions,
and share the grammar above, they're nevertheless a different thing and aren't
handled here: if we see one, we ignore it.

=
sentence_handler INFORM6CODE_SH_handler =
	{ INFORM6CODE_NT, -1, 2, Config::Inclusions::inform_6_inclusion };

void Config::Inclusions::inform_6_inclusion(parse_node *PN) {
	current_sentence = PN;
	wording IW = ParseTree::get_text(PN);
	/* skip to the instructions */
	IW = Wordings::trim_first_word(Wordings::trim_first_word(Wordings::trim_first_word(IW)));

	if (Wordings::empty(IW)) @<There are no specific instructions about where it goes@>;
	int problem = TRUE;
	if (<inform6-inclusion-location>(IW)) {
		problem = FALSE;
		switch (<<r>>) {
			case SEGMENT_LEVEL_INC:
				@<It's positioned with respect to a template segment@>; break;
			case SECTION_LEVEL_INC:
				@<It's positioned with respect to a template section@>; break;
			case WHEN_DEFINING_INC:
				@<It's positioned in the middle of a class or object definition@>; break;
			case AS_PREFORM_INC: return;
		}
	}
	if (problem) @<Issue problem message for bad inclusion instructions@>;
}

@ In the absence of any instructions, we emulate this:

>> Include ... before "I6 Inclusions" in "Output.i6t".

Note that the inclusion side 1 means "before": see the grammar above.
(Though "after" would probably have worked just as well.)

The actual output of I6 material is going to be done by the Template code,
and what we do here is simply to give it instructions to do so at the
appropriate time.

@<There are no specific instructions about where it goes@> =
	Config::Inclusions::new_intervention(AFTER_LINK_STAGE, I"Output.i6t", I"I6 Inclusions",
		Lexer::word_raw_text(Wordings::first_wn(ParseTree::get_text(PN)) + 2), NULL);
	return;

@<It's positioned with respect to a template segment@> =
	Word::dequote(segment_inclusion_wn);
	TEMPORARY_TEXT(seg);
	WRITE_TO(seg, "%W", Wordings::one_word(segment_inclusion_wn));
	Config::Inclusions::new_intervention(inclusion_side, seg, NULL,
		Lexer::word_raw_text(Wordings::first_wn(ParseTree::get_text(PN)) + 2), NULL);
	DISCARD_TEXT(seg);

@<It's positioned with respect to a template section@> =
	Word::dequote(section_inclusion_wn);
	Word::dequote(segment_inclusion_wn);
	TEMPORARY_TEXT(sec);
	TEMPORARY_TEXT(seg);
	WRITE_TO(sec, "%W", Wordings::one_word(section_inclusion_wn));
	WRITE_TO(seg, "%W", Wordings::one_word(segment_inclusion_wn));
	Config::Inclusions::new_intervention(inclusion_side, seg, sec,
		Lexer::word_raw_text(Wordings::first_wn(ParseTree::get_text(PN)) + 2), NULL);
	DISCARD_TEXT(sec);
	DISCARD_TEXT(seg);

@ When it comes to class and object definitions, we don't give the Template
code instructions; we remember what's needed ourselves:

@<It's positioned in the middle of a class or object definition@> =
	parse_node *spec = <<parse_node:s>>;
	inference_subject *infs = InferenceSubjects::from_specification(spec);
	if (infs) {
		i6_inclusion_matter *inclm = CREATE(i6_inclusion_matter);
		inclm->material_to_include = PN;
		inclm->infs_to_include_with = infs;
	} else problem = TRUE;

@<Issue problem message for bad inclusion instructions@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_BadI6Inclusion),
		"this is not a form of I6 code inclusion I recognise",
		"because the clause at the end telling me where to put the code "
		"excerpt is not one of the possibilities I know. The clause can "
		"either be blank (in which case I'll find somewhere sensible to "
		"put it), or 'when defining' plus the name of an object or kind "
		"of object, or 'before', 'instead of' or 'after' a double-quoted "
		"name of a template layer segment, or of a part of one. For "
		"instance, 'before \"Parser.i6t\".' or 'after \"Pronouns\" in "
		"\"Language.i6t\".'");

@ =
void Config::Inclusions::new_intervention(int stage, text_stream *segment, text_stream *part, wchar_t *i6, text_stream *seg) {
	text_stream *X = NULL;
	if (i6) {
		X = Str::new();
		I6T::interpret_i6t(X, i6, -1);
	}
	Emit::intervention(stage, segment, part, X, seg);
}

@ The following is our opportunity to redeem those inclusion-in-definitions
requests, which, again, we do by instructing the Template code.

=
void Config::Inclusions::compile_inclusions_for_subject(OUTPUT_STREAM, inference_subject *infs) {
	i6_inclusion_matter *inclm;
	LOOP_OVER (inclm, i6_inclusion_matter)
		if (inclm->infs_to_include_with == infs) {
			I6T::interpret_i6t(OUT,
				Lexer::word_raw_text(Wordings::first_wn(ParseTree::get_text(inclm->material_to_include)) + 2),
				-1);
			WRITE("\n");
		}
}
