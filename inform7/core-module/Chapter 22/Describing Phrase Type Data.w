[Phrases::TypeData::Textual::] Describing Phrase Type Data.

To convert phrase type data to and from text.

@h Logging.
We begin with the problem of printing out a textual description of a PHTD.
The debugging log is simple:

=
void Phrases::TypeData::Textual::log(ph_type_data *phtd) {
	LOG("  PHTD: register as <%W>\n  %s\n", phtd->registration_text,
		Phrases::TypeData::describe_manner_of_return(phtd->manner_of_return, phtd, NULL));
	if (phtd->manner_of_return == DECIDES_VALUE_MOR)
		LOG("  decides value of kind $u\n", phtd->return_kind);
	@<Log the word sequence@>;
	@<Log the token sequence@>;
	Phrases::TypeData::log_inline_details(phtd->as_inline);
	Phrases::TypeData::log_say_details(phtd->as_say);
}

@<Log the word sequence@> =
	LOG("  ");
	int i;
	for (i=0; i<phtd->no_words; i++)
		if (phtd->word_sequence[i] < MAX_TOKENS_PER_PHRASE)
			LOG("#%d ", phtd->word_sequence[i]);
		else
			LOG("%N ", phtd->word_sequence[i]);
	LOG("(%d words)\n", phtd->no_words);

@<Log the token sequence@> =
	int i;
	for (i=0; i<phtd->no_tokens; i++)
		LOG("  #%d: \"%W\" = $P\n", i,
			phtd->token_sequence[i].token_name, phtd->token_sequence[i].to_match);

@ Abbreviatedly:

=
void Phrases::TypeData::Textual::log_briefly(ph_type_data *phtd) {
	if (phtd == NULL) { LOG("NULL-PHTD"); return; }
	LOG("\"%W\"", phtd->registration_text);
	switch(phtd->manner_of_return) {
		case DECIDES_CONDITION_MOR: LOG("(=condition)"); break;
		case DECIDES_VALUE_MOR: LOG("(=$u)", phtd->return_kind); break;
	}
}

@h HTML forms.
But the debugging log isn't the only place we want to write out the phrase
type to: it also gets written to HTML, not just openly but also in the
Javascript pasted form. One reason for this is to write entries in the
Phrasebook Index, but another is to show what Inform was trying to do when
issuing a Problem message: usually it has managed partially to match up the
tokens in a phrase, and has a mostly-formed but incorrect invocation as
a result. If such an invocation |inv| is supplied here, than the attempted
match is shown.

@d PASTE_PHRASE_FORMAT 1 /* in the insert-to-source text pasted by a button in the Index */
@d INDEX_PHRASE_FORMAT 2 /* a simpler version good enough for most purposes */

=
void Phrases::TypeData::Textual::write_HTML_representation(OUTPUT_STREAM,
	ph_type_data *phtd, int paste_format, parse_node *inv) {

	int seq_from = 0, seq_to = phtd->no_words;

	int writing_a_say = Phrases::TypeData::preface_for_say_HTML(OUT, phtd->as_say, paste_format);
	if (writing_a_say == NOT_APPLICABLE) return;
	if (writing_a_say) seq_from = 1; /* skip the first word, which is necessarily "say" in this case */

	if (phtd->as_inline.block_follows) seq_to--; /* skip the last word, which is a block marker */

	if ((paste_format == PASTE_PHRASE_FORMAT) && (writing_a_say == FALSE)) {
		if (phtd->word_sequence[0] < MAX_TOKENS_PER_PHRASE) seq_from++;
		if ((phtd->word_sequence[seq_to-1] < MAX_TOKENS_PER_PHRASE) &&
			(phtd->as_inline.block_follows == NO_BLOCK_FOLLOWS)) seq_to--;
	}
	@<Describe the word sequence@>;
	if (phtd->as_inline.block_follows) {
		if (paste_format) WRITE(":\n");
		else {
			WRITE(":");
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;");
			HTML_OPEN("i");
			HTML::begin_colour(OUT, I"ff4040");
			WRITE("phrases");
			HTML::end_colour(OUT);
			HTML_CLOSE("i");
		}
	}

	Phrases::TypeData::epilogue_for_say_HTML(OUT, phtd->as_say, paste_format);
}

@<Describe the word sequence@> =
	int j;
	for (j=seq_from; j<seq_to; j++) {
		if (j > seq_from) WRITE(" ");
		int ix = phtd->word_sequence[j];
		if (ix < MAX_TOKENS_PER_PHRASE)
			@<Describe a token in the word sequence@>
		else
			@<Describe a fixed word in the word sequence@>;
	}

@<Describe a fixed word in the word sequence@> =
	wchar_t *p = Lexer::word_raw_text(phtd->word_sequence[j]);
	int i, tinted = FALSE;
	for (i=0; p[i]; i++) {
		if ((p[i] == '/') && (tinted == FALSE)) {
			tinted = TRUE;
			if (paste_format == PASTE_PHRASE_FORMAT) break;
			HTML::begin_colour(OUT, I"808080");
		}
		WRITE("%c", p[i]);
	}
	if ((paste_format != PASTE_PHRASE_FORMAT) && (tinted)) HTML::end_colour(OUT);

@<Describe a token in the word sequence@> =
	switch (paste_format) {
		case INDEX_PHRASE_FORMAT:
			if (writing_a_say == FALSE) WRITE("(");
			if (inv) {
				parse_node *found = Invocations::get_token_as_parsed(inv, ix);
				text_stream *col = I"008000";
				if (Node::is(found, UNKNOWN_NT)) col = I"800000";
				HTML::begin_colour(OUT, col);
				WRITE("%W", Node::get_text(found));
				HTML::end_colour(OUT);
				WRITE(" - ");
				Dash::note_inv_token_text(found,
					(phtd->token_sequence[ix].construct == NEW_LOCAL_PT_CONSTRUCT)?TRUE:FALSE);
			}
			@<Describe what the token matches@>;
			if (writing_a_say == FALSE) WRITE(")");
			break;
		case PASTE_PHRASE_FORMAT:
			WRITE("...");
			break;
	}

@<Describe what the token matches@> =
	switch (phtd->token_sequence[ix].construct) {
		case STANDARD_PT_CONSTRUCT: {
			parse_node *spec = phtd->token_sequence[ix].to_match;
			if (Specifications::is_kind_like(spec)) {
				HTML::begin_colour(OUT, I"4040ff");
				Kinds::Textual::write(OUT, Specifications::to_kind(spec));
				HTML::end_colour(OUT);
			} else if ((Node::is(spec, CONSTANT_NT)) ||
					(Specifications::is_description(spec))) {
				HTML::begin_colour(OUT, I"4040ff");
				WRITE("%W", Node::get_text(spec));
				HTML::end_colour(OUT);
			} else {
				HTML_OPEN("i");
				HTML::begin_colour(OUT, I"ff4040");
				Specifications::write_out_in_English(OUT, spec);
				HTML::end_colour(OUT);
				HTML_CLOSE("i");
			}
			break;
		}
		case NEW_LOCAL_PT_CONSTRUCT:
			HTML::begin_colour(OUT, I"E00060");
			WRITE("a new name");
			HTML::end_colour(OUT); break;
		case EXISTING_LOCAL_PT_CONSTRUCT:
			HTML::begin_colour(OUT, I"E00060");
			WRITE("a temporary named value");
			if ((phtd->token_sequence[ix].token_kind) &&
				(Kinds::Compare::eq(phtd->token_sequence[ix].token_kind, K_value) == FALSE)) {
				WRITE(" holding ");
				Kinds::Textual::write_articled(OUT, phtd->token_sequence[ix].token_kind);
			}
			HTML::end_colour(OUT); break;
		case CONDITION_PT_CONSTRUCT:
			HTML::begin_colour(OUT, I"E00060");
			WRITE("a condition");
			HTML::end_colour(OUT); break;
		case STORAGE_PT_CONSTRUCT:
			HTML::begin_colour(OUT, I"E00060");
			WRITE("a stored value");
			HTML::end_colour(OUT); break;
		case TABLE_REFERENCE_PT_CONSTRUCT:
			HTML::begin_colour(OUT, I"E00060");
			WRITE("a table entry");
			HTML::end_colour(OUT); break;
		case KIND_NAME_PT_CONSTRUCT:
			HTML::begin_colour(OUT, I"E00060");
			WRITE("name of kind");
			HTML::end_colour(OUT); break;
		case VOID_PT_CONSTRUCT:
			HTML::begin_colour(OUT, I"E00060");
			WRITE("a phrase");
			HTML::end_colour(OUT); break;
	}

@h Problem messages.
Which enables this rather cool depiction used in Problem messages:

=
void Phrases::TypeData::Textual::inv_write_HTML_representation(OUTPUT_STREAM, parse_node *inv) {
	phrase *ph = Node::get_phrase_invoked(inv);
	if (ph) {
		ph_type_data *phtd = &(ph->type_data);
		if (Wordings::nonempty(ph->ph_documentation_symbol)) {
			TEMPORARY_TEXT(pds)
			WRITE_TO(pds, "%+W", Wordings::one_word(Wordings::first_wn(ph->ph_documentation_symbol)));
			Index::DocReferences::link_to(OUT, pds, -1);
			DISCARD_TEXT(pds)
		} else
			Index::link_to(OUT, Wordings::first_wn(Node::get_text(ph->declaration_node)), FALSE);
		WRITE(" ");
		Phrases::TypeData::Textual::write_HTML_representation(OUT, phtd, INDEX_PHRASE_FORMAT, inv);
		WRITE(" ");
		switch (Dash::reading_passed(inv)) {
			case TRUE: HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/tick.png"); break;
			case FALSE: HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/cross.png"); break;
			default: HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/greytick.png"); break;
		}
	}
}

@h Indexing.
And also this rather fine presentation in the Phrasebook index:

=
void Phrases::TypeData::Textual::write_index_representation(OUTPUT_STREAM, ph_type_data *phtd, phrase *ph) {
	if (phtd->manner_of_return == DECIDES_CONDITION_MOR)
		WRITE("<i>if</i> ");
	Phrases::write_HTML_representation(OUT, ph, INDEX_PHRASE_FORMAT);
	if (phtd->return_kind == NULL) {
		if (phtd->manner_of_return == DECIDES_CONDITION_MOR) WRITE("<i>:</i>");
	} else {
		WRITE(" ... <i>");
		if (Kinds::Behaviour::definite(phtd->return_kind) == FALSE) WRITE("value");
		else Kinds::Textual::write(OUT, phtd->return_kind);
		WRITE("</i>");
		wording W = Phrases::Usage::get_equation_form(&(ph->usage_data));
		if (Wordings::nonempty(W)) {
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>y</i>&nbsp;=&nbsp;<b>%+W</b>(<i>x</i>)", W);
		}
	}
}

@ In the Phrasebook index, listings are marked with plus sign buttons which,
when clicked, expand an otherwise hidden box of details about the phrase.
This is the routine which prints those details.

=
void Phrases::TypeData::Textual::write_reveal_box(OUTPUT_STREAM, ph_type_data *phtd, phrase *ph) {
	HTML_OPEN("p");
	@<Present a paste button containing the text of the phrase@>;
	Phrases::TypeData::Textual::write_index_representation(OUT, phtd, ph);
	Phrases::Options::index(OUT, &(ph->options_data));
	@<Quote from and reference to the documentation, where possible@>;
	@<Present the equation form of the phrase, if it has one@>;
	@<Present the name of the phrase regarded as a value, if it has one@>;
	@<Present the kind of the phrase@>;
	HTML_CLOSE("p");
	@<Warn about deprecation, where necessary@>;
}

@<Present a paste button containing the text of the phrase@> =
	TEMPORARY_TEXT(TEMP)
	Phrases::write_HTML_representation(TEMP, ph, PASTE_PHRASE_FORMAT);
	PasteButtons::paste_text(OUT, TEMP);
	DISCARD_TEXT(TEMP)
	WRITE("&nbsp;");

@ This is only possible for phrases mentioned in the built-in manuals,
of course.

@<Quote from and reference to the documentation, where possible@> =
	if (Wordings::nonempty(ph->ph_documentation_symbol)) {
		HTML_CLOSE("p");
		TEMPORARY_TEXT(pds)
		WRITE_TO(pds, "%+W", Wordings::one_word(Wordings::first_wn(ph->ph_documentation_symbol)));
		Index::DocReferences::doc_fragment(OUT, pds);
		HTML_OPEN("p"); WRITE("<b>See</b> ");
		Index::DocReferences::fully_link(OUT, pds);
		DISCARD_TEXT(pds)
	}

@<Present the equation form of the phrase, if it has one@> =
	wording W = Phrases::Usage::get_equation_form(&(ph->usage_data));
	if (Wordings::nonempty(W)) {
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("<b>In equations:</b> write as ");
		PasteButtons::paste_W(OUT, W);
		WRITE("&nbsp;%+W()", W);
	}

@<Present the name of the phrase regarded as a value, if it has one@> =
	if (ph->usage_data.constant_phrase_holder) {
		wording W = Nouns::nominative_singular(ph->usage_data.constant_phrase_holder->name);
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("<b>Name:</b> ");
		PasteButtons::paste_W(OUT, W);
		WRITE("&nbsp;%+W", W);
	}

@ "Say" phrases are never used functionally and don't have interesting kinds,
so we won't list them here.

@<Present the kind of the phrase@> =
	if (Phrases::TypeData::is_a_say_phrase(ph) == FALSE) {
		HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("<b>Kind:</b> ");
		Kinds::Textual::write(OUT, Phrases::TypeData::kind(phtd));
	}

@<Warn about deprecation, where necessary@> =
	if (Phrases::TypeData::deprecated(&(ph->type_data))) {
		HTML_OPEN("p");
		WRITE("<b>Warning:</b> ");
		WRITE("This phrase is now deprecated! It will probably be withdrawn in "
			"future builds of Inform, and even the present build will reject it "
			"if the 'Use no deprecated features' option is set. If you're using "
			"it now, try following the documentation link above for advice on "
			"what to write instead.");
		HTML_CLOSE("p");
	}

@h Comments in compiled code.
That's it for indexing. There's one last piece of describing to do: a
convenient comment to go into the compiled I6 code, just above the routine
a phrase has been compiled into:

=
void Phrases::TypeData::Textual::phtd_write_I6_comment_describing(ph_type_data *phtd, OUTPUT_STREAM) {
	int j;
	WRITE("! ");
	for (j=0; j<phtd->no_words; j++) {
		if (phtd->word_sequence[j] < MAX_TOKENS_PER_PHRASE)
			WRITE("#%d ", phtd->word_sequence[j]);
		else
			WRITE("%N ", phtd->word_sequence[j]);
	}
	WRITE(":\n");
}

@h Parsing a PHTD.
And now the reverse process: given a preamble in the source text such as

>> To decide which room is room (D - direction) from/of (R1 - room): ...

we want to turn it into a PHTD for its phrase. We only do this for "To..."
phrases; as we've seen, rules have PHRCDs instead.

When this routine is called, the word range supplied is the whole preamble --
in this example, it's from "To" to the ")" just before the colon. If we
detect phrase options, after a comma, we pass the word range for them back.
The PHTD we write to is factory-fresh except that it has the "inline" flag
correctly set.

=
void Phrases::TypeData::Textual::parse(ph_type_data *phtd, wording XW, wording *OW) {
	int say_flag = FALSE; /* is this going to be a "say" phrase? */

	if (Wordings::nonempty(XW)) XW = Phrases::TypeData::Textual::phtd_parse_return_data(phtd, XW); 			/* trim return data from the front */
	if (Wordings::nonempty(XW)) Index::DocReferences::position_of_symbol(&XW); /* trim documentation ref from the back */
	if (Wordings::nonempty(XW)) XW = Phrases::TypeData::Textual::phtd_parse_doodads(phtd, XW, &say_flag); 	/* and other doodads from the back */

	int cw = -1; /* word number of first comma */
	@<Find the first comma outside of parentheses, if any exists@>;
	if (cw >= 0) {
		int comma_presages_options = TRUE;
		@<Does this comma presage phrase options?@>;
		if (comma_presages_options) {
			if (say_flag) @<Issue a problem: say phrases aren't allowed options@>;
			*OW = Wordings::from(XW, cw + 1);
			XW = Wordings::up_to(XW, cw - 1); /* trim the preamble range to to the text before the comma */
		}
	}
	phtd->registration_text = XW;
	Phrases::TypeData::Textual::phtd_parse_word_sequence(phtd, XW);
}

@<Find the first comma outside of parentheses, if any exists@> =
	int bl = 0;
	LOOP_THROUGH_WORDING(i, XW) {
		if ((Lexer::word(i) == OPENBRACE_V) || (Lexer::word(i) == OPENBRACKET_V)) bl++;
		if ((Lexer::word(i) == CLOSEBRACE_V) || (Lexer::word(i) == CLOSEBRACKET_V)) bl--;
		if ((Lexer::word(i) == COMMA_V) && (bl == 0) &&
			(i>Wordings::first_wn(XW)) && (i<Wordings::last_wn(XW))) { cw = i; break; }
	}

@ In some control structures, comma is implicitly a sort of "then".

@<Does this comma presage phrase options?@> =
	if ((<control-structure-phrase>(XW)) &&
		(ControlStructures::comma_possible(<<rp>>)))
		comma_presages_options = FALSE;

@ If you find the explanation in this message unconvincing, you're not alone.
To be honest my preferred fix would be to delete phrase options from the
language altogether, but there we are; spilt milk.

@<Issue a problem: say phrases aren't allowed options@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SayWithPhraseOptions),
		"phrase options are not allowed for 'say' phrases",
		"because the commas would lead to ambiguous sentences, and because the "
		"content of a substitution is intended to be something conceptually simple "
		"and not needing clarification.");

@ We will need some constants for the annotations which the Preform grammar
below will make. First, for the main phrase structure:

@d NO_ANN 0
@d SAY_ANN 1
@d LET_ANN 2
@d BLOCK_ANN 3
@d IN_LOOP_ANN 4
@d IN_ANN 5
@d CONDITIONAL_ANN 6
@d LOOP_ANN 7

@ And these are for the specialised "say" phrase grammar:

@d NO_SANN 1
@d CONTROL_SANN 2
@d BEGIN_SANN 3
@d CONTINUE_SANN 4
@d ENDM_SANN 5
@d END_SANN 6

@ And these for "return" annotations:

@d DEC_RANN 1
@d DEV_RANN 2
@d TOC_RANN 3
@d TOV_RANN 4
@d TO_RANN 5

@ Now we come to the grammar for phrase definitions (not rules). This is
surprisingly complicated, but many of the options are reserved for the
Standard Rules.

We know from coarse mode parsing of the preamble that it starts with the
word "to".

=
<phrase-preamble> ::=
	<phrase-preamble> ( deprecated ) |                          ==> { R[1], -, <<deprecated>> = TRUE }
	<say-preamble>	|                                           ==> { SAY_ANN, -, <<say-ann>> = R[1] }
	<to-preamble>                                               ==> { pass 1 }

<to-preamble> ::=
	<to-preamble> ( arithmetic operation <cardinal-number> ) |  ==> { R[1], -, <<operation>> = R[2] }
	<to-preamble> ( assignment operation ) |                    ==> { R[1], -, <<assignment>> = TRUE }
	{let ... be given by ...} |                                 ==> { LET_ANN, -, <<eqn>> = TRUE }
	{let ...} |                                                 ==> { LET_ANN, -, <<eqn>> = FALSE }
	... -- end |                                                ==> { BLOCK_ANN, - }
	... -- end conditional |                                    ==> { CONDITIONAL_ANN, - }
	... -- end loop |                                           ==> { LOOP_ANN, - }
	... -- in loop |                                            ==> { IN_LOOP_ANN, - }
	... -- in ### |                                             ==> { IN_ANN, - }
	...                                                         ==> { NO_ANN, - }

@ The definition remaining after the preamble is removed is then vetted.
This is a possibly controversial point, in fact, because the check in question
is to make sure the phrase definition doesn't mask off a relationship, which
would almost certainly throw a cascade of other but less helpful problem
messages.

=
<phrase-vetting> ::=
	( ...... ) <copular-verb> {<copular-preposition>} ( ...... )  ==> { -, K_number, <<rel1>> = Wordings::first_wn(WR[2]), <<rel2>> = Wordings::last_wn(WR[2]), <<preposition:prep>> = RP[2] }; @<Issue PM_MasksRelation problem@>

@<Issue PM_MasksRelation problem@> =
	preposition *prep = <<preposition:prep>>;
	Problems::quote_source(1, current_sentence);
	if (Prepositions::get_where_pu_created(prep) == NULL)
		Problems::quote_text(4, "This is a relation defined inside Inform.");
	else
		Problems::quote_source(4, Prepositions::get_where_pu_created(prep));
	Problems::quote_wording(2, W);
	Problems::quote_wording(3, Wordings::new(<<rel1>>, <<rel2>>));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_MasksRelation));
	Problems::issue_problem_segment(
		"I don't want you to define a phrase with the wording you've used in "
		"in %1 because it could be misunderstood. There is already a definition "
		"of what it means for something to be '%3' something else, so this "
		"phrase definition would look too much like testing whether "
		"'X is %3 Y'. (%4.)");
	Problems::issue_problem_end();

@ Phrases whose definitions begin "To say" are usually text substitutions,
the exception being the primordial phrase for saying text.

=
<say-preamble> ::=
	<say-preamble> -- running on |             ==> { R[1], -, <<run-on>> = TRUE }
	{say otherwise/else} |                     ==> { CONTROL_SANN, -, <<control>> = OTHERWISE_SAY_CS }
	{say otherwise/else if/unless ...} |       ==> { CONTROL_SANN, -, <<control>> = OTHERWISE_IF_SAY_CS }
	{say if/unless ...} |                      ==> { CONTROL_SANN, -, <<control>> = IF_SAY_CS }
	{say end if/unless} |                      ==> { CONTROL_SANN, -, <<control>> = END_IF_SAY_CS }
	{say ...} -- beginning ### |               ==> { BEGIN_SANN, - }
	{say ...} -- continuing ### |              ==> { CONTINUE_SANN, - }
	{say ...} -- ending ### with marker ### |  ==> { ENDM_SANN, - }
	{say ...} -- ending ### |                  ==> { END_SANN, - }
	{say ...}                                  ==> { NO_SANN, - }

@ The following is used on the same text as <to-preamble>, but later on,
for timing reasons.

Note that <k-kind-for-template> parses <k-kind>, but in a mode which causes
the kind variables to be read as formal prototypes and not as their values.
This allows for tricky definitions like:

>> To decide which K is (name of kind of value K) which relates to (Y - L) by (R - relation of Ks to values of kind L)

where <k-kind-for-template> needs to recognise "K" even though the tokens
haven't yet been parsed, so that we don't yet know it will be meaningful.

=
<to-return-data> ::=
	to {decide yes/no} |                             ==> { DEC_RANN, NULL }
	to {decide on ...} |                             ==> { DEV_RANN, NULL }
	to decide whether/if the ... |                   ==> { TOC_RANN, NULL }
	to decide whether/if ... |                       ==> { TOC_RANN, NULL }
	to decide what/which <return-kind> is the ... |  ==> { TOV_RANN, RP[1] }
	to decide what/which <return-kind> is ... |      ==> { TOV_RANN, RP[1] }
	to ...                                           ==> { TO_RANN,  NULL }

<return-kind> ::=
	<k-kind-for-template> |                          ==> { pass 1 }
	...                                              ==> { -, K_number}; @<Issue PM_UnknownValueToDecide problem@>

@<Issue PM_UnknownValueToDecide problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnknownValueToDecide));
	Problems::issue_problem_segment(
		"The phrase you describe in %1 seems to be trying to decide a value, "
		"but '%2' is not a kind that I recognise. (I had expected something "
		"like 'number' or 'object' - see the Kinds index for what's available.)");
	Problems::issue_problem_end();

@ The support code needed for the |<to-return-data>| grammar.

=
int no_truth_state_returns = 0;
wording Phrases::TypeData::Textual::phtd_parse_return_data(ph_type_data *phtd, wording XW) {
	phtd->return_kind = NULL;
	if (<to-return-data>(XW)) {
		XW = GET_RW(<to-return-data>, 1);
		int mor = -1; kind *K = NULL;
		switch (<<r>>) {
			case DEC_RANN: break;
			case DEV_RANN: break;
			case TOC_RANN: mor = DECIDES_CONDITION_MOR; break;
			case TOV_RANN: mor = DECIDES_VALUE_MOR; K = <<rp>>; break;
			case TO_RANN:  mor = DECIDES_NOTHING_MOR; break;
		}
		if (mor >= 0) Phrases::TypeData::set_mor(phtd, mor, K);
	} else internal_error("to phrase without to");
	if (Kinds::Compare::eq(phtd->return_kind, K_truth_state)) {
		if (no_truth_state_returns++ > 0)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TruthStateToDecide),
			"phrases are not allowed to decide a truth state",
			"and should be defined with the form 'To decide if ...' rather than "
			"'To decide what truth state is ...'.");
	}
	return XW;
}

@ The "doodads" are the special features of a phrase notated at the back of
the preamble, which is why the following routine may move the end of the
preamble word range backwards -- it returns the current last word number.

=
wording Phrases::TypeData::Textual::phtd_parse_doodads(ph_type_data *phtd, wording W, int *say_flag) {
	<<operation>> = -1; <<assignment>> = FALSE; <<deprecated>> = FALSE; <<run-on>> = FALSE;
	<phrase-preamble>(W); /* guaranteed to match any non-empty text */
	if (<<r>> == SAY_ANN) W = GET_RW(<say-preamble>, 1);
	else W = GET_RW(<to-preamble>, 1);

	if (<<deprecated>>) Phrases::TypeData::deprecate_phrase(phtd);

	int let = FALSE, blk = NO_BLOCK_FOLLOWS, only_in = 0; /* "nothing unusual" defaults */
	switch (<<r>>) {
		case BLOCK_ANN:			blk = MISCELLANEOUS_BLOCK_FOLLOWS; break;
		case CONDITIONAL_ANN:	blk = CONDITIONAL_BLOCK_FOLLOWS; break;
		case IN_ANN:			@<Set only-in to the first keyword@>; break;
		case IN_LOOP_ANN:		only_in = -1; break;
		case LET_ANN:			if (<<eqn>>) let = EQUATION_LET_PHRASE;
								else let = ASSIGNMENT_LET_PHRASE;
								break;
		case LOOP_ANN:			blk = LOOP_BODY_BLOCK_FOLLOWS; break;
		case SAY_ANN: 			@<We seem to be parsing a "say" phrase@>; break;
	}

	Phrases::TypeData::make_id(&(phtd->as_inline),
		<<operation>>, <<assignment>>, let, blk, only_in);

	<phrase-vetting>(W);

	return W;
}

@ For example, if the preamble is "To while...", then this sets |only_in|
to the word number of "while".

@<Set only-in to the first keyword@> =
	wording OW = GET_RW(<to-preamble>, 2);
	only_in = Wordings::first_wn(OW);

@ And similarly for the say annotations.

@<We seem to be parsing a "say" phrase@> =
	*say_flag = TRUE;
	int cs = -1, pos = -1, at = -1, cat = -1;
	wording XW = EMPTY_WORDING;
	switch (<<say-ann>>) {
		case CONTROL_SANN:	cs = <<control>>; break;
		case BEGIN_SANN:	pos = SSP_START; XW = GET_RW(<say-preamble>, 2); at = Wordings::first_wn(XW); break;
		case CONTINUE_SANN:	pos = SSP_MIDDLE; XW = GET_RW(<say-preamble>, 2); at = Wordings::first_wn(XW); break;
		case ENDM_SANN:		pos = SSP_END; XW = GET_RW(<say-preamble>, 2); at = Wordings::first_wn(XW);
							XW = GET_RW(<say-preamble>, 3); cat = Wordings::first_wn(XW);
							break;
		case END_SANN:		pos = SSP_END; XW = GET_RW(<say-preamble>, 2); at = Wordings::first_wn(XW); break;
	}
	Phrases::TypeData::make_sd(&(phtd->as_say), <<run-on>>, cs, pos, at, cat);

@ The syntax for the body of a phrase definition is that it's a sequence of
fixed single words, which are not brackets, and bracketed token definitions,
occurring in any quantity and any order. For example:

>> begin the (A - activity on value of kind K) activity with (val - K)

is a sequence of word, word, token, word, word, token.

For implementation convenience, we write a grammar which splits off the next
piece of the definition from the front of the text. In production (e), it's
a single word; in production (b), a token definition; and the others all
give problems for misuse of brackets.

=
<phrase-definition-word-or-token> ::=
	( ) *** |                             ==> @<Issue PM_TokenWithEmptyBrackets problem@>
	( <phrase-token-declaration> ) *** |  ==> { TRUE, RP[1], <<token-form>> = R[1] }
	( *** |                               ==> @<Issue PM_TokenWithoutCloseBracket problem@>
	) *** |                               ==> @<Issue PM_TokenWithoutOpenBracket problem@>
	### ***                               ==> { FALSE, - }

@ Phrase token declarations allow a variety of non-standard constructs.

Note that nested brackets are allowed in the kind indication after
the hyphen, and this is sorely needed with complicated functional kinds.

=
<phrase-token-declaration> ::=
	*** ( *** - ...... |                                              ==> @<Issue PM_TokenWithNestedBrackets problem@>
	...... - a nonexisting variable |                                 ==> { TRUE, Specifications::from_kind(K_value), <<token-construct>> = NEW_LOCAL_PT_CONSTRUCT }
	...... - a nonexisting <k-kind-for-template> variable |           ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = NEW_LOCAL_PT_CONSTRUCT }
	...... - a nonexisting <k-kind-for-template> that/which varies |  ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = NEW_LOCAL_PT_CONSTRUCT }
	...... - nonexisting variable |                                   ==> { TRUE, Specifications::from_kind(K_value), <<token-construct>> = NEW_LOCAL_PT_CONSTRUCT }
	...... - nonexisting <k-kind-for-template> variable |             ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = NEW_LOCAL_PT_CONSTRUCT }
	...... - nonexisting <k-kind-for-template> that/which varies |    ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = NEW_LOCAL_PT_CONSTRUCT }
	...... - {an existing variable} |                                 ==> { TRUE, Specifications::from_kind(K_value), <<token-construct>> = EXISTING_LOCAL_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - {an existing <k-kind-for-template> variable} |           ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = EXISTING_LOCAL_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - {an existing <k-kind-for-template> that/which varies} |  ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = EXISTING_LOCAL_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - {existing variable} |                                    ==> { TRUE, Specifications::from_kind(K_value), <<token-construct>> = EXISTING_LOCAL_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - {existing <k-kind-for-template> variable} |              ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = EXISTING_LOCAL_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - {existing <k-kind-for-template> that/which varies} |     ==> { TRUE, Specifications::from_kind(RP[1]), <<token-construct>> = EXISTING_LOCAL_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - a condition |                                            ==> { TRUE, NULL, <<token-construct>> = CONDITION_PT_CONSTRUCT }
	...... - condition |                                              ==> { TRUE, NULL, <<token-construct>> = CONDITION_PT_CONSTRUCT }
	...... - a phrase |                                               ==> { TRUE, NULL, <<token-construct>> = VOID_PT_CONSTRUCT }
	...... - phrase |                                                 ==> { TRUE, NULL, <<token-construct>> = VOID_PT_CONSTRUCT }
	...... - storage |                                                ==> { TRUE, Specifications::from_kind(K_value), <<token-construct>> = STORAGE_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - a table-reference |                                      ==> { TRUE, Specifications::from_kind(K_value), <<token-construct>> = TABLE_REFERENCE_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - table-reference |                                        ==> { TRUE, Specifications::from_kind(K_value), <<token-construct>> = TABLE_REFERENCE_PT_CONSTRUCT }; Node::set_text(*XP, WR[2]);
	...... - <s-phrase-token-type> |                                  ==> { TRUE, RP[1], <<token-construct>> = STANDARD_PT_CONSTRUCT }
	...... - <s-kind-as-name-token> |                                 ==> { TRUE, RP[1], <<token-construct>> = KIND_NAME_PT_CONSTRUCT }
	...... - ...... |                                                 ==> @<Issue PM_BadTypeIndication problem@>
	<s-kind-as-name-token> |                                          ==> { FALSE, RP[1], <<token-construct>> = KIND_NAME_PT_CONSTRUCT }
	......                                                            ==> @<Issue PM_TokenMisunderstood problem@>

@<Issue PM_TokenWithEmptyBrackets problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithEmptyBrackets),
		"nothing is between the opening bracket '(' and its matching close bracket ')'",
		"so I can't see what is meant to be the fixed text and what is meant to be "
		"changeable. The idea is to put brackets around whatever varies from one "
		"usage to another: for instance, 'To contribute (N - a number) dollars: ...'.");
	==> { NOT_APPLICABLE, - };

@<Issue PM_TokenWithoutCloseBracket problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithoutCloseBracket),
		"the opening bracket '(' has no matching close bracket ')'",
		"so I can't see what is meant to be the fixed text and what is meant to be "
		"changeable. The idea is to put brackets around whatever varies from one "
		"usage to another: for instance, 'To contribute (N - a number) dollars: ...'.");
	==> { NOT_APPLICABLE, - };

@<Issue PM_TokenWithoutOpenBracket problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithoutOpenBracket),
		"a close bracket ')' appears here with no matching open '('",
		"so I can't see what is meant to be the fixed text and what is meant to "
		"be changeable. The idea is to put brackets around whatever varies from "
		"one usage to another: for instance, 'To contribute (N - a number) "
		"dollars: ...'.");
	==> { NOT_APPLICABLE, - };

@<Issue PM_TokenWithNestedBrackets problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenWithNestedBrackets),
		"the name of the token inside the brackets '(' and ')' and before the "
		"hyphen '-' itself contains another open bracket '('",
		"which is not allowed.");
	==> { NOT_APPLICABLE, - };

@<Issue PM_BadTypeIndication problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, GET_RW(<phrase-token-declaration>, 2));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadTypeIndication));
	Problems::issue_problem_segment(
		"In %1, the text '%2' after the hyphen should tell me what kind of value "
		"goes here (like 'a number', or 'a vehicle'), but it's not something I "
		"recognise.");
	Problems::issue_problem_end();
	==> { NOT_APPLICABLE, - };

@<Issue PM_TokenMisunderstood problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TokenMisunderstood),
		"the brackets '(' and ')' here neither say that something varies but has "
		"a given type, nor specify a called name",
		"so I can't make sense of them. For a 'To...' phrase, brackets like this "
		"are used with a hyphen dividing the name for a varying value and the "
		"kind it has: for instance, 'To contribute (N - a number) dollars: ...'. "
		"Rules, on the other hand, use brackets to give names to things or rooms "
		"found when matching conditions: for instance, 'Instead of opening a "
		"container in the presence of a man (called the box-watcher): ...'");
	==> { NOT_APPLICABLE, - };

@ This internal simply wraps <k-kind-as-name-token> up as a value.

=
<s-kind-as-name-token> internal {
	int s = kind_parsing_mode;
	kind_parsing_mode = PHRASE_TOKEN_KIND_PARSING;
	int t = <k-kind-as-name-token>(W);
	kind_parsing_mode = s;
	if (t) {
		parse_node *spec = Specifications::from_kind(<<rp>>);
		Node::set_text(spec, W);
		==> { TRUE, spec };
		return TRUE;
	}
	==> { fail nonterminal };
}


@ At this final stage of parsing, all annotations to do with inline or say
behaviour have been stripped away, and what's left is the text which will
form the word and token sequences:

=
void Phrases::TypeData::Textual::phtd_parse_word_sequence(ph_type_data *phtd, wording W) {
	phtd->no_tokens = 0;
	phtd->no_words = 0;

	int i = Wordings::first_wn(W);
	while (i <= Wordings::last_wn(W)) {
		int word_to_add = 0; /* redundant assignment to keep |gcc| happy */
		<phrase-definition-word-or-token>(Wordings::from(W, i));
		switch (<<r>>) {
			case NOT_APPLICABLE:	return; /* a problem message has been issued */
			case TRUE:				@<Add a token next@>; break;
			case FALSE: 			@<Add a word next@>; break;
		}
		if (phtd->no_words >= MAX_WORDS_PER_PHRASE) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PhraseTooLong),
				"this phrase has too many words",
				"and needs to be simplified.");
			return;
		}
		phtd->word_sequence[phtd->no_words++] = word_to_add;
	}

	@<Sort out the kind variables in this declaration@>;
}

@<Add a word next@> =
	word_to_add = i++;

@<Add a token next@> =
	if (<<token-form>> == NOT_APPLICABLE) return; /* a problem message has been issued */

	parse_node *spec = <<rp>>; /* what is to be matched */

	wording TW = EMPTY_WORDING;
	if (<<token-form>>) TW = GET_RW(<phrase-token-declaration>, 1); /* the name */

	wording A = GET_RW(<phrase-definition-word-or-token>, 1);
	i = Wordings::first_wn(A);
	W = Wordings::up_to(W, Wordings::last_wn(A)); /* move past this token */

	@<Unless we are inline, phrase tokens have to be or describe values@>;
	@<Phrase tokens cannot be quantified@>;
	@<Fashion a suitable phrase token@>;

@<Fashion a suitable phrase token@> =
	phrase_token pht;
	pht.to_match = spec;
	pht.token_kind = Specifications::to_kind(spec);
	pht.construct = <<token-construct>>;
	pht.token_name = TW;
	word_to_add = phtd->no_tokens;
	if (phtd->no_tokens >= MAX_TOKENS_PER_PHRASE) {
		if (phtd->no_tokens == MAX_TOKENS_PER_PHRASE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(spec));
			int n = MAX_TOKENS_PER_PHRASE;
			Problems::quote_number(3, &n);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TooManyTokens));
			Problems::issue_problem_segment(
				"In %1, I ran out of tokens when I got up to '%2'. "
				"Phrases are only allowed %3 tokens, that is, they "
				"are only allowed %3 bracketed parts in their definitions.");
			Problems::issue_problem_end();
		}
	} else {
		phtd->token_sequence[phtd->no_tokens] = pht;
		phtd->no_tokens++;
	}

@<Unless we are inline, phrase tokens have to be or describe values@> =
	if ((<<token-construct>> != STANDARD_PT_CONSTRUCT) &&
		(<<token-construct>> != KIND_NAME_PT_CONSTRUCT) &&
		(phtd->as_inline.invoked_inline_not_as_call == FALSE)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(spec));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoninlineUsesNonvalues));
		Problems::issue_problem_segment(
			"In %1, the text '%2' after the hyphen should tell me what kind of "
			"value goes here (like 'a number', or 'a vehicle'), but this is not "
			"a kind: it does describe something I can understand, but not "
			"something which can then be used as a value. (It would be allowed "
			"in low-level, so-called 'inline' phrase definitions, but not in a "
			"standard phrase definition like this one.)");
		Problems::issue_problem_end();
		return;
	}

@<Phrase tokens cannot be quantified@> =
	if (Node::is(spec, TEST_VALUE_NT)) {
		pcalc_prop *prop = Descriptions::to_proposition(spec);
		if (Calculus::Variables::number_free(prop) != 1) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(spec));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PhraseTokenQuantified));
			Problems::issue_problem_segment(
				"In %1, the text '%2' after the hyphen should tell me what kind of "
				"value goes here (like 'a number', or 'a vehicle'), but it has to "
				"be a single value, and not a description of what might be multiple "
				"values. So 'N - a number' is fine, but not 'N - three numbers' or "
				"'N - every number'.");
			Problems::issue_problem_end();
			return;
		}
	}

@<Sort out the kind variables in this declaration@> =
	int i, t = 0;
	kind *declarations[27];
	int usages[27];
	for (i=1; i<=26; i++) { usages[i] = 0; declarations[i] = NULL; }
	for (i=0; i<phtd->no_tokens; i++)
		t += Phrases::TypeData::Textual::find_kind_variable_domains(phtd->token_sequence[i].token_kind,
			usages, declarations);
	if (t > 0) {
		int problem_thrown = FALSE;
		for (int v=1; (v<=26) && (problem_thrown == FALSE); v++)
			if ((usages[v] > 0) && (declarations[v] == NULL))
				@<Issue a problem for an undeclared kind variable@>;
		if (problem_thrown == FALSE)
			for (i=0; i<phtd->no_tokens; i++)
				if (phtd->token_sequence[i].token_kind)
					@<Substitute for any kind variables in the match specification@>;
	}

@<Issue a problem for an undeclared kind variable@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UndeclaredKindVariable),
		"this phrase uses a kind variable which is not declared",
		"which is not allowed.");
	phtd->token_sequence[i].token_kind =
		Kinds::binary_construction(CON_phrase, K_value, K_value);
	problem_thrown = TRUE;

@ This following process is much less mysterious than it sounds. Suppose we
have the phrase:

>> To add (purchase - K) to (shopping list - list of arithmetic values of kind K): ...

This tells us that the matcher should accept any list of arithmetic values,
and then set K equal to the kind of the entries, and require that the purchase
agree. According to the |declarations| array already made, K is declared as a
kind of "arithmetic value". What the code in this paragraph does is to change
the |to_match| specifications as if the phrase had read:

>> To add (purchase - arithmetic value) to (shopping list - list of arithmetic values): ...

In other words, we substitute "arithmetic value" in place of K, and thus get
rid of variables from the match specifications entirely. We can safely do
this because the |token_kind| for these two tokens remain
"K" and "list of K" respectively.

@<Substitute for any kind variables in the match specification@> =
	int changed = FALSE;
	kind *substituted = Kinds::substitute(
		phtd->token_sequence[i].token_kind, declarations, &changed);
	if (changed)
		phtd->token_sequence[i].to_match =
			Specifications::from_kind(substituted);

@ The following recurses down through the tree structure of a kind, returning
the number of kind variables it finds. (So for lots of straightforward kinds,
such as "list of numbers", it returns 0.)

=
int Phrases::TypeData::Textual::find_kind_variable_domains(kind *K, int *usages, kind **declarations) {
	int t = 0;
	if (K) {
		int N = Kinds::get_variable_number(K);
		if (N > 0) {
			t++;
			@<A kind variable has been found@>;
		}
		if (Kinds::is_proper_constructor(K)) {
			int a = Kinds::arity_of_constructor(K);
			if (a == 1)
				t += Phrases::TypeData::Textual::find_kind_variable_domains(
					Kinds::unary_construction_material(K), usages, declarations);
			else {
				kind *X = NULL, *Y = NULL;
				Kinds::binary_construction_material(K, &X, &Y);
				t += Phrases::TypeData::Textual::find_kind_variable_domains(X, usages, declarations);
				t += Phrases::TypeData::Textual::find_kind_variable_domains(Y, usages, declarations);
			}
		}
	}
	return t;
}

@ We count how many times each variable appears. It should be given a domain
in exactly one place: for example,

>> To amaze (alpha - an arithmetic value of kind K) with (beta - an enumerated value of kind K): ...

produces the following problem, because the domain of K has been given twice.

@<A kind variable has been found@> =
	usages[N]++;
	kind *dec = Kinds::get_variable_stipulation(K);
	if (dec) {
		if (declarations[N]) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DoublyDeclaredKindVariable),
				"this phrase declares the same kind variable more than once",
				"and ought to declare each variable once each.");
		}
		declarations[N] = dec;
	}

