[SourceText::] Source Text.

Code for reading Inform 7 source text, which Inbuild uses for both extensions
and projects.

@ This short function is a bridge to the lexer, and is used for reading
text files of source into either projects or extensions. Note that it
doesn't attach the fed text to the copy: the copy may need to contain text
from multiple files and indeed from elsewhere.

=
inbuild_copy *currently_lexing_into = NULL;

source_file *SourceText::read_file(inbuild_copy *C, filename *F, text_stream *synopsis,
	int documentation_only, int primary) {
	currently_lexing_into = C;
	general_pointer ref = STORE_POINTER_inbuild_copy(NULL);
	FILE *handle = Filenames::fopen(F, "r");
	source_file *sf = NULL;
	if (handle) {
		text_stream *leaf = Filenames::get_leafname(F);
		if (primary) leaf = I"main source text";
		sf = TextFromFiles::feed_open_file_into_lexer(F, handle,
			leaf, documentation_only, ref);
		if (sf == NULL) {
			Copies::attach_error(C, CopyErrors::new_F(OPEN_FAILED_CE, -1, F));
		} else {
			fclose(handle);
			#ifdef CORE_MODULE
			if (documentation_only == FALSE) @<Tell console output about the file@>;
			#endif
		}
	}
	currently_lexing_into = NULL;
	return sf;
}

@ This is where messages like

	|I've also read Standard Rules by Graham Nelson, which is 27204 words long.|

are printed to |stdout| (not |stderr|), in something of an affectionate nod
to TeX's traditional console output, though occasionally I think silence is
golden and that these messages could go. It's a moot point for almost all users,
though, because the console output is concealed from them by the Inform
application.

@<Tell console output about the file@> =
	int wc;
	char *message;
	if (primary) message = "I've now read %S, which is %d words long.\n";
	else message = "I've also read %S, which is %d words long.\n";
	wc = TextFromFiles::total_word_count(sf);
	WRITE_TO(STDOUT, message, synopsis, wc);
	STREAM_FLUSH(STDOUT);
	LOG(message, synopsis, wc);

@

@d LEXER_PROBLEM_HANDLER SourceText::lexer_problem_handler

=
void SourceText::lexer_problem_handler(int err, text_stream *desc, wchar_t *word) {
	if (err == MEMORY_OUT_LEXERERROR)
		Errors::fatal("Out of memory: unable to create lexer workspace");
    if (currently_lexing_into) {
		copy_error *CE = CopyErrors::new_WT(LEXER_CE, err, word, desc);
		Copies::attach_error(currently_lexing_into, CE);
    }
}

@

@d COPY_FILE_TYPE inbuild_copy

@

@d SYNTAX_PROBLEM_HANDLER SourceText::syntax_problem_handler

=
void SourceText::syntax_problem_handler(int err_no, wording W, void *ref, int k) {
	inbuild_copy *C = (inbuild_copy *) ref;
	copy_error *CE = CopyErrors::new_N(SYNTAX_CE, err_no, k);
	CopyErrors::supply_wording(CE, W);
	Copies::attach_error(C, CE);
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

@e ExtMultipleBeginsHere_SYNERROR
@e ExtBeginsAfterEndsHere_SYNERROR
@e ExtEndsWithoutBegins_SYNERROR
@e ExtMultipleEndsHere_SYNERROR

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
		case 2: SYNTAX_PROBLEM_HANDLER(ExtMultipleBeginsHere_SYNERROR, W, sfsm_copy, 0); break;
		case 3: SYNTAX_PROBLEM_HANDLER(ExtBeginsAfterEndsHere_SYNERROR, W, sfsm_copy, 0); break;
	}

@<Check we can end an extension here@> =
	switch (sfsm_extension_position) {
		case 1: SYNTAX_PROBLEM_HANDLER(ExtEndsWithoutBegins_SYNERROR, W, sfsm_copy, 0); break;
		case 2: sfsm_extension_position++; break;
		case 3: SYNTAX_PROBLEM_HANDLER(ExtMultipleEndsHere_SYNERROR, W, sfsm_copy, 0); break;
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

@e BIBLIOGRAPHIC_NT     			/* For the initial title sentence */
@e ROUTINE_NT           			/* "Instead of taking something, ..." */
@e INFORM6CODE_NT       			/* "Include (- ... -) */
@e TABLE_NT             			/* "Table 1 - Counties of England" */
@e EQUATION_NT          			/* "Equation 2 - Newton's Second Law" */
@e TRACE_NT             			/* A sentence consisting of an asterisk and optional quoted text */
@e INVOCATION_LIST_NT   		    /* Single invocation of a (possibly compound) phrase */

@d list_node_type ROUTINE_NT
@d list_entry_node_type INVOCATION_LIST_NT

@ =
void SourceText::node_metadata(void) {
	ParseTree::md((parse_tree_node_type) { BIBLIOGRAPHIC_NT, "BIBLIOGRAPHIC_NT",    					0, 0,		L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { ROUTINE_NT, "ROUTINE_NT", 			   					0, INFTY,	L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { INFORM6CODE_NT, "INFORM6CODE_NT",		   					0, 0,		L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { TABLE_NT, "TABLE_NT",					   					0, 0,		L2_NCAT, TABBED_CONTENT_NFLAG });
	ParseTree::md((parse_tree_node_type) { EQUATION_NT, "EQUATION_NT",			   					0, 0,		L2_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { TRACE_NT, "TRACE_NT",					   					0, 0,		L2_NCAT, 0 });
	#ifndef CORE_MODULE
	ParseTree::md((parse_tree_node_type) { INVOCATION_LIST_NT, "INVOCATION_LIST_NT",		   			0, INFTY,	L2_NCAT, 0 });
	#endif
}

@

=
<structural-sentence> ::=
	<if-start-of-source-text> <quoted-text> |				==> 0; ssnt = BIBLIOGRAPHIC_NT;
	<if-start-of-source-text> <quoted-text> ... |			==> 0; ssnt = BIBLIOGRAPHIC_NT;
	<language-modifying-sentence> |							==> R[1]
	* |														==> 0; ssnt = TRACE_NT;
	* <quoted-text-without-subs> |							==> 0; ssnt = TRACE_NT;
	<if-start-of-paragraph> table ... |						==> 0; ssnt = TABLE_NT;
	<if-start-of-paragraph> equation ... |					==> 0; ssnt = EQUATION_NT;
	include the ... by ... |								==> 0; ssnt = INCLUDE_NT;
	include ... by ... |									==> 0; ssnt = INCLUDE_NT;
	include (- ...											==> 0; ssnt = INFORM6CODE_NT;

@ Properly speaking, despite the definition above, language modifying sentences
are nonstructural. So what are they doing here? The answer is that we need to
read them early on, because they affect the way that they parse all other
sentences. Whereas other nonstructural sentences can wait, these can't.

=
<language-modifying-sentence> ::=
	include (- ### in the preform grammar |			==> -2; ssnt = INFORM6CODE_NT;
	use ... language element/elements				==> -1

@h Sentence division.
Sentence division can happen either early in Inform's run, when the vast bulk
of the source text is read, or at intermittent periods later when fresh text
is generated internally. New sentences need to be parsed as they arise, not
saved up to be parsed later, so we will use the following:

@d SENTENCE_ANNOTATION_FUNCTION SourceText::annotate_new_sentence

=
int text_loaded_from_source = FALSE;
void SourceText::declare_source_loaded(void) {
	text_loaded_from_source = TRUE;
}

void SourceText::annotate_new_sentence(parse_node *new) {
	if (text_loaded_from_source) {
		ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
		#ifdef CORE_MODULE
		Sentences::VPs::seek(new);
		#endif
	}
}

@

@d NEW_BEGINEND_HANDLER SourceText::new_beginend

=
void SourceText::new_beginend(parse_node *new, inbuild_copy *C) {
	inform_extension *E = ExtensionManager::from_copy(C);
	if (ParseTree::get_type(new) == BEGINHERE_NT)
		Inclusions::check_begins_here(new, E);
	if (ParseTree::get_type(new) == ENDHERE_NT)
		Inclusions::check_ends_here(new, E);
}

@

@d NEW_LANGUAGE_HANDLER SourceText::new_language

@e UseElementWithdrawn_SYNERROR

=
void SourceText::new_language(wording W) {
	copy_error *CE = CopyErrors::new(SYNTAX_CE, UseElementWithdrawn_SYNERROR);
	CopyErrors::supply_node(CE, current_sentence);
	Copies::attach_error(sfsm_copy, CE);
}
