[InterventionRequests::] Intervention Requests.

Special sentences for inserting low-level material written in Inform 6 notation.

@ Very early on in the life of Inform 7, features were added to allow users to
glue in pieces of raw Inform 6 code, as a way of easing the transition for them.
In an ideal world, those features would now be removed entirely. The main use
case now is that an extension wants to provide a feature with an Inform 7
API, but implemented under the hood with Inform 6. This would be better done
with an accompanying kit of Inter code, but at present (2021) that makes such
an extension more difficult to distribute.

What is true, however, is that the many nuanced ways to express how such an
inclusion could be made were heavily curtailed in 2017. The syntax for these
was not made illegal, but simply ignored. All instructions about where I6
code should now go are disregarded; the new code-generator locates such code
wherever it wants to.

However, we continue to parse the old syntax, so:

@d SEGMENT_LEVEL_INC 1		/* before, instead of, or after a segment of I6 template */
@d SECTION_LEVEL_INC 2		/* before, instead of, or after a section of I6 template */
@d WHEN_DEFINING_INC 3		/* as part of an Object or Class definition */
@d AS_PREFORM_INC 4 		/* include it not as I6, but as Preform grammar */
@d REPLACING_INC 5          /* replacing a symbol also defined in some kit */

@d BEFORE_LINK_STAGE 1
@d INSTEAD_LINK_STAGE 2
@d AFTER_LINK_STAGE 3
@d EARLY_LINK_STAGE 4

=
int inclusion_side, section_inclusion_wn, segment_inclusion_wn;

@ Note that although Preform inclusions are syntactically like I6 inclusions,
and share the grammar above, they're nevertheless a different thing and aren't
handled here: if we see one, we ignore it.

=
<inform6-inclusion-location> ::=
	<inclusion-side> {<quoted-text-without-subs>} |     ==> @<Segment@>
	<inclusion-side> {<quoted-text-without-subs>} in {<quoted-text-without-subs>} | ==> @<Section@>
	when defining <s-type-expression> |                 ==> { WHEN_DEFINING_INC, RP[1] }
	replacing {<quoted-text-without-subs>} |            ==> { REPLACING_INC, - }
	when defining ... |                                 ==> @<Issue PM_WhenDefiningUnknown problem@>
	before the library |                                ==> @<Issue PM_BeforeTheLibrary problem@>
	in the preform grammar                              ==> { AS_PREFORM_INC, NULL }

<inclusion-side> ::=
	before |                                            ==> { BEFORE_LINK_STAGE, - }
	instead of |                                        ==> @<Issue PM_IncludeInsteadOf problem@>
	after                                               ==> { AFTER_LINK_STAGE, - }

@<Segment@> =
	inclusion_side = R[1]; segment_inclusion_wn = R[2];
	==> { SEGMENT_LEVEL_INC, NULL };

@<Section@> =
	inclusion_side = R[1]; section_inclusion_wn = R[2]; segment_inclusion_wn = R[3];
	==> { SEGMENT_LEVEL_INC, NULL };

@<Issue PM_WhenDefiningUnknown problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_WhenDefiningUnknown),
		"I do not understand what definition you're referring to",
		"so I can't make an Inter inclusion there.");
	==> { SEGMENT_LEVEL_INC, NULL };

@<Issue PM_IncludeInsteadOf problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_IncludeInsteadOf),
		"this syntax was withdrawn in April 2022",
		"in favour of a more finely controlled inclusion command. See the manual, "
		"but you can probably get what you want using 'replacing \"SomeFunctionName\".' "
		"rather than 'instead of ...'.");
	==> { SEGMENT_LEVEL_INC, NULL };

@<Issue PM_BeforeTheLibrary problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BeforeTheLibrary),
		"this syntax was withdrawn in January 2008",
		"but the effect you want can probably be achieved by just deleting the "
		"words 'before the library.'");
	==> { SEGMENT_LEVEL_INC, NULL };

@ So, then, this function is called on inclusion sentences such as:

>> Include (- ... -) before "I6 Inclusions" in "Output.i6t".

Those references are now meaningless (I6T files in the sense meant by this
syntax no longer exist), but we faithfully parse them before ignoring them.
A later version of Inform will probably produce problem messages on these.

=
void InterventionRequests::make(parse_node *PN) {
	current_sentence = PN;
	wording IW = Node::get_text(PN);
	/* skip to the instructions */
	IW = Wordings::trim_first_word(Wordings::trim_first_word(Wordings::trim_first_word(IW)));

	if (Wordings::empty(IW)) {
		@<There are no specific instructions about where it goes@>;
	} else {
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
				case REPLACING_INC:
					@<Replace a kit definition with this@>; break;
				case AS_PREFORM_INC: return;
			}
		}
		if (problem) @<Issue problem message for bad inclusion instructions@>;
	}
}

@<There are no specific instructions about where it goes@> =
	InterventionRequests::remember(AFTER_LINK_STAGE, NULL, NULL, PN, NULL, NULL);

@<It's positioned with respect to a template segment@> =
	Word::dequote(segment_inclusion_wn);
	TEMPORARY_TEXT(seg)
	WRITE_TO(seg, "%W", Wordings::one_word(segment_inclusion_wn));
	InterventionRequests::remember(inclusion_side, seg, NULL, PN, NULL, NULL);
	DISCARD_TEXT(seg)

@<It's positioned with respect to a template section@> =
	Word::dequote(section_inclusion_wn);
	Word::dequote(segment_inclusion_wn);
	TEMPORARY_TEXT(sec)
	TEMPORARY_TEXT(seg)
	WRITE_TO(sec, "%W", Wordings::one_word(section_inclusion_wn));
	WRITE_TO(seg, "%W", Wordings::one_word(segment_inclusion_wn));
	InterventionRequests::remember(inclusion_side, seg, sec, PN, NULL, NULL);
	DISCARD_TEXT(sec)
	DISCARD_TEXT(seg)

@<Replace a kit definition with this@> =
	wording W = GET_RW(<inform6-inclusion-location>, 1);
	int wn = Wordings::first_wn(W);
	Word::dequote(wn);
	TEMPORARY_TEXT(X)
	WRITE_TO(X, "%W", W);
	InterventionRequests::remember(AFTER_LINK_STAGE, NULL, NULL, PN, NULL, X);
	DISCARD_TEXT(X)

@ When it comes to class and object definitions, we don't give the Template
code instructions; we remember what's needed ourselves:

@<It's positioned in the middle of a class or object definition@> =
	parse_node *spec = <<rp>>;
	inference_subject *infs = InferenceSubjects::from_specification(spec);
	if (infs) InterventionRequests::remember_for_subject(PN, infs);
	else problem = TRUE;

@<Issue problem message for bad inclusion instructions@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadI6Inclusion),
		"this is not a form of Inter code inclusion I recognise",
		"because the clause at the end telling me where to put the code excerpt is not "
		"one of the possibilities I know.");

@ These requests are not acted on here, they are simply remembered for later
action: see //runtime: Interventions//.

=
typedef struct source_text_intervention {
	int stage; /* one of the |*_LINK_STAGE| enumerated constants */
	struct text_stream *segment;
	struct text_stream *part;
	struct text_stream *seg;
	struct inference_subject *infs_to_include_with;
	struct text_stream *matter;
	struct parse_node *where_made;
	struct text_stream *replacing;
	CLASS_DEFINITION
} source_text_intervention;

source_text_intervention *InterventionRequests::new_sti(parse_node *p) {
	source_text_intervention *sti = CREATE(source_text_intervention);
	sti->where_made = current_sentence;
	sti->stage = AFTER_LINK_STAGE;
	sti->segment = NULL;
	sti->part = NULL;
	wchar_t *sf = Lexer::word_raw_text(Wordings::first_wn(Node::get_text(p)) + 2);
	sti->matter = Str::new();
	WRITE_TO(sti->matter, "%w", sf);
	sti->seg = NULL;
	sti->replacing = NULL;
	return sti;
}

void InterventionRequests::remember_for_subject(parse_node *p, inference_subject *infs) {
	source_text_intervention *sti = InterventionRequests::new_sti(p);
	sti->infs_to_include_with = infs;
}

void InterventionRequests::remember(int stage, text_stream *segment, text_stream *part,
	parse_node *p, text_stream *seg, text_stream *rep) {
	source_text_intervention *sti = InterventionRequests::new_sti(p);
	sti->stage = stage;
	sti->segment = Str::duplicate(segment);
	sti->part = Str::duplicate(part);
	sti->seg = Str::duplicate(seg);
	sti->replacing = Str::duplicate(rep);
}
