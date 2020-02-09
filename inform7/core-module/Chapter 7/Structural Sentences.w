[StructuralSentences::] Structural Sentences.

To parse structurally important sentences.

@

@d list_node_type ROUTINE_NT
@d list_entry_node_type INVOCATION_LIST_NT

@

@d SENTENCE_ANNOTATION_FUNCTION StructuralSentences::annotate_new_sentence

=
void StructuralSentences::annotate_new_sentence(parse_node *new) {
	if (text_loaded_from_source) {
		ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
		Sentences::VPs::seek(new);
	}
}

@

@d NEW_HEADING_HANDLER StructuralSentences::new_heading

=
int StructuralSentences::new_heading(parse_node *new) {
	heading *h = Sentences::Headings::declare(new);
	ParseTree::set_embodying_heading(new, h);
	return Sentences::Headings::include_material(h);
}

@

@d NEW_BEGINEND_HANDLER StructuralSentences::new_beginend

=
void StructuralSentences::new_beginend(parse_node *new, extension_file *ef) {
	if (ParseTree::get_type(new) == BEGINHERE_NT)
		Extensions::Inclusion::check_begins_here(new, sfsm_extension);
	if (ParseTree::get_type(new) == ENDHERE_NT)
		Extensions::Inclusion::check_ends_here(new, sfsm_extension);
}

@

@d NEW_LANGUAGE_HANDLER StructuralSentences::new_language

=
void StructuralSentences::new_language(wording W) {
	Problems::Issue::sentence_problem(_p_(PM_UseElementWithdrawn),
		"the ability to activate or deactivate compiler elements in source text has been withdrawn",
		"in favour of a new system with Inform kits.");
}

@

@d EXTENSION_FILE_TYPE extension_file

@h Sentence division.
Sentence division can happen either early in Inform's run, when the vast bulk
of the source text is read, or at intermittent periods later when fresh text
is generated internally. New sentences need to be treated slightly differently
in these cases, so this seems as good a point as any to define the routine
which the |.i6t| interpreter calls when it wants to signal that the source
text has now officially been read.

=
void StructuralSentences::declare_source_loaded(void) {
	text_loaded_from_source = TRUE;
}

@h Sentence breaking.
The |Sentences::break| routine is used for long stretches of text,
normally entire files. The following provides a way for the |.i6t|
interpreter to apply it to the whole text as lexed, which provides the
original basis for parsing. (This won't be the entire source text,
though: extensions, including the Standard Rules, have yet to be read.)

=
void StructuralSentences::break_source(void) {
	int l = ParseTree::push_attachment_point(tree_root);
	int n = 0;
	if (language_definition_top >= n) n = language_definition_top+1;
	if (doc_references_top >= n) n = doc_references_top+1;
	if (language_scan_top >= n) n = language_scan_top+1;
	Sentences::break(Wordings::new(n, lexer_wordcount-1), NULL);
	ParseTree::pop_attachment_point(l);
	parse_node *implicit_heading = ParseTree::new(HEADING_NT);
	ParseTree::set_text(implicit_heading, Feeds::feed_text_expanding_strings(L"Invented sentences"));
	ParseTree::annotate_int(implicit_heading, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(implicit_heading, heading_level_ANNOT, 0);
	ParseTree::insert_sentence(implicit_heading);
	Sentences::Headings::declare(implicit_heading);
}

@ Sentences in the source text are of five categories: dividing sentences,
which divide up the source into segments; structural sentences, which split
the source into different forms (standard text, tables, equations, I6 matter,
and so on); nonstructural sentences, which make grammatical definitions and
give Inform other more or less direct instructions; rule declarations; and
regular sentences, those which use the standard verbs. Examples:

>> Volume II [dividing]
>> Include Locksmith by Emily Short [structural]
>> Release along with a website [nonstructural]
>> Instead of looking [rule]
>> The cushion is on the wooden chair [regular]

Dividing sentences are always read, whereas the others may be skipped in
sections of source not being included for one reason or another. Dividing
sentences must match the following. Note that the extension end markers are
only read in extensions, so they can never accidentally match in the main
source text.

=
<dividing-sentence> ::=
	<if-start-of-paragraph> <heading> |	==> R[2]
	<extension-end-marker-sentence>		==> R[1]

<heading> ::=
	volume ... |						==> 1
	book ... |							==> 2
	part ... |							==> 3
	chapter ... |						==> 4
	section ...							==> 5

<extension-end-marker-sentence> ::=
	... begin/begins here |				==> -1; @<Check we can begin an extension here@>;
	... end/ends here					==> -2; @<Check we can end an extension here@>;

@<Check we can begin an extension here@> =
	switch (sfsm_extension_position) {
		case 1: sfsm_extension_position++; break;
		case 2: Problems::Issue::extension_problem(_p_(PM_ExtMultipleBeginsHere),
			sfsm_extension, "has more than one 'begins here' sentence"); break;
		case 3: Problems::Issue::extension_problem(_p_(PM_ExtBeginsAfterEndsHere),
			sfsm_extension, "has a further 'begins here' after an 'ends here'"); break;
	}

@<Check we can end an extension here@> =
	switch (sfsm_extension_position) {
		case 1: Problems::Issue::extension_problem(_p_(BelievedImpossible),
			sfsm_extension, "has an 'ends here' with nothing having begun"); break;
		case 2: sfsm_extension_position++; break;
		case 3: Problems::Issue::extension_problem(_p_(PM_ExtMultipleEndsHere),
			sfsm_extension, "has more than one 'ends here' sentence"); break;
	}

@<Detect a dividing sentence@> =
	if (<dividing-sentence>(W)) {
		switch (<<r>>) {
			case -1: if (sfsm_extension_position > 0) begins_or_ends = 1;
				break;
			case -2:
				if (sfsm_extension_position > 0) begins_or_ends = -1;
				break;
			default:
				heading_level = <<r>>;
				break;
		}
	}

@ Structural sentences are defined as follows. (The asterisk notation isn't
known to most Inform users: it increases output to the debugging log.)

=
<structural-sentence> ::=
	<if-start-of-source-text> <quoted-text> |				==> 0; ssnt = BIBLIOGRAPHIC_NT;
	<if-start-of-source-text> <quoted-text> ... |			==> 0; ssnt = BIBLIOGRAPHIC_NT;
	<language-modifying-sentence> |							==> R[1]
	* |														==> 0; ssnt = TRACE_NT;
	* <quoted-text-without-subs> |							==> 0; ssnt = TRACE_NT;
	<if-start-of-paragraph> table ... |						==> 0; ssnt = TABLE_NT;
	<if-start-of-paragraph> equation ... |					==> 0; ssnt = EQUATION_NT;
	include <nounphrase-articled> by <nounphrase> |			==> 0; ssnt = INCLUDE_NT; *XP = RP[1]; ((parse_node *) RP[1])->next = RP[2];
	include (- ...											==> 0; ssnt = INFORM6CODE_NT;

@ Properly speaking, despite the definition above, language modifying sentences
are nonstructural. So what are they doing here? The answer is that we need to
read them early on, because they affect the way that they parse all other
sentences. Whereas other nonstructural sentences can wait, these can't.

=
<language-modifying-sentence> ::=
	include (- ### in the preform grammar |			==> -2; ssnt = INFORM6CODE_NT;
	use ... language element/elements				==> -1

@

@d SYNTAX_PROBLEM_HANDLER StructuralSentences::syntax_problem_handler

=
void StructuralSentences::syntax_problem_handler(int err_no, wording W, void *ref, int k) {
	switch (err_no) {
		case UnexpectedSemicolon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_UnexpectedSemicolon));
			Problems::issue_problem_segment(
				"The text %1 is followed by a semicolon ';', which only makes "
				"sense to me inside a rule or phrase (where there's a heading, "
				"then a colon, then a list of instructions divided by semicolons). "
				"Perhaps you want a full stop '.' instead?");
			Problems::issue_problem_end();
			break;
		case ParaEndsInColon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_ParaEndsInColon));
			Problems::issue_problem_segment(
				"The text %1 seems to end a paragraph with a colon. (Rule declarations "
				"can end a sentence with a colon, so maybe there's accidentally a "
				"skipped line here?)");
			Problems::issue_problem_end();
			break;
		case SentenceEndsInColon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SentenceEndsInColon));
			Problems::issue_problem_segment(
				"The text %1 seems to have a colon followed by a full stop, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case SentenceEndsInSemicolon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SentenceEndsInSemicolon));
			Problems::issue_problem_segment(
				"The text %1 seems to have a semicolon followed by a full stop, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case SemicolonAfterColon_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SemicolonAfterColon));
			Problems::issue_problem_segment(
				"The text %1 seems to have a semicolon following a colon, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case SemicolonAfterStop_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::Issue::handmade_problem(_p_(PM_SemicolonAfterStop));
			Problems::issue_problem_segment(
				"The text %1 seems to have a semicolon following a full stop, which is "
				"punctuation I don't understand.");
			Problems::issue_problem_end();
			break;
		case ExtNoBeginsHere_SYNERROR: {
			extension_file *ef = (extension_file *) ref;
			Problems::Issue::extension_problem(_p_(PM_ExtNoBeginsHere),
				ef, "has no 'begins here' sentence");
			break;
		}
		case ExtNoEndsHere_SYNERROR: {
			extension_file *ef = (extension_file *) ref;
			Problems::Issue::extension_problem(_p_(PM_ExtNoEndsHere),
				ef, "has no 'ends here' sentence");
			break;
		}
		case ExtSpuriouslyContinues_SYNERROR: {
			extension_file *ef = (extension_file *) ref;
			LOG("Spurious text: %W\n", W);
			Problems::Issue::extension_problem(_p_(PM_ExtSpuriouslyContinues),
				ef, "continues after the 'ends here' sentence");
			break;
		}
		case HeadingOverLine_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::quote_source(2, NounPhrases::new_raw(Wordings::up_to(W, k-1)));
			Problems::quote_source(3, NounPhrases::new_raw(Wordings::from(W, k)));
			Problems::Issue::handmade_problem(_p_(PM_HeadingOverLine));
			Problems::issue_problem_segment(
				"The text %1 seems to be a heading, but contains a "
				"line break, which is not allowed: so I am reading it "
				"as just %2 and ignoring the continuation %3. The rule "
				"is that a heading must be a single line which is the "
				"only sentence in its paragraph, so there must be a "
				"skipped line above and below.");
			Problems::issue_problem_end();
			break;
		case HeadingStopsBeforeEndOfLine_SYNERROR:
			Problems::quote_source(1, NounPhrases::new_raw(W));
			Problems::quote_source(2,
				NounPhrases::new_raw(Wordings::new(Wordings::last_wn(W)+1, k-1)));
			Problems::Issue::handmade_problem(_p_(PM_HeadingStopsBeforeEndOfLine));
			Problems::issue_problem_segment(
				"The text %1 seems to be a heading, but does not occupy "
				"the whole of its line of source text, which continues %2. "
				"The rule is that a heading must occupy a whole single line "
				"which is the only sentence in its paragraph, so there "
				"must be a skipped line above and below. %P"
				"A heading must not contain a colon ':' or any full stop "
				"characters '.', even if they occur in an ellipsis '...' or a "
				"number '2.3.13'. (I mention that because sometimes this problem "
				"arises when a decimal point is misread as a full stop.)");
			Problems::issue_problem_end();
			break;
		default: internal_error("unimplemented problem message");
	}
}

