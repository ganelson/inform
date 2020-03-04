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
			Copies::attach(C, Copies::new_error_on_file(OPEN_FAILED_CE, F));
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
	TEMPORARY_TEXT(erm);
	switch (err) {
		case STRING_TOO_LONG_LEXERERROR:
			WRITE_TO(erm, "Too much text in quotation marks: %w", word);
            break;
		case WORD_TOO_LONG_LEXERERROR:
			WRITE_TO(erm, "Word too long: %w", word);
			break;
		case I6_TOO_LONG_LEXERERROR:
			WRITE_TO(erm, "I6 inclusion too long: %w", word);
			break;
		case STRING_NEVER_ENDS_LEXERERROR:
			WRITE_TO(erm, "Quoted text never ends: %S", desc);
			break;
		case COMMENT_NEVER_ENDS_LEXERERROR:
			WRITE_TO(erm, "Square-bracketed text never ends: %S", desc);
			break;
		case I6_NEVER_ENDS_LEXERERROR:
			WRITE_TO(erm, "I6 inclusion text never ends: %S", desc);
			break;
		default:
			internal_error("unknown lexer error");
    }
    if (currently_lexing_into) {
    	copy_error *CE = Copies::new_error(LEXER_CE, erm);
    	CE->error_subcategory = err;
    	CE->details = Str::duplicate(desc);
    	CE->word = word;
    	Copies::attach(currently_lexing_into, CE);
    }
	DISCARD_TEXT(erm);
}

@

@d EXTENSION_FILE_TYPE inbuild_copy

@

@d SYNTAX_PROBLEM_HANDLER SourceText::syntax_problem_handler

=
void SourceText::syntax_problem_handler(int err_no, wording W, void *ref, int k) {
	inbuild_copy *C = (inbuild_copy *) ref;
	copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
	CE->error_subcategory = err_no;
	CE->details_W = W;
	CE->details_N = k;
	Copies::attach(C, CE);
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
		case 2: SYNTAX_PROBLEM_HANDLER(ExtMultipleBeginsHere_SYNERROR, W, sfsm_extension, 0); break;
		case 3: SYNTAX_PROBLEM_HANDLER(ExtBeginsAfterEndsHere_SYNERROR, W, sfsm_extension, 0); break;
	}

@<Check we can end an extension here@> =
	switch (sfsm_extension_position) {
		case 1: SYNTAX_PROBLEM_HANDLER(ExtEndsWithoutBegins_SYNERROR, W, sfsm_extension, 0); break;
		case 2: sfsm_extension_position++; break;
		case 3: SYNTAX_PROBLEM_HANDLER(ExtMultipleEndsHere_SYNERROR, W, sfsm_extension, 0); break;
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
