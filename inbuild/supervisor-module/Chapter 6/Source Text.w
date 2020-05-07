[SourceText::] Source Text.

Using the lexer and syntax analysis modules to read in Inform 7 source text.

@h Bridge to the Lexer.
Lexing is the business of the //words// module, and we need to tell it what
data type to use when referencing natural languages.

@d PREFORM_LANGUAGE_TYPE struct inform_language

@ Lexical errors -- overly long words, half-open quotations, and such -- are
converted into copy errors and attached to the copy currently being worked on.
The following callback function performs that service.

//words// has no convenient way to keep track of what copy we're working on,
so we will simply store it in a global variable.

@d PROBLEM_WORDS_CALLBACK SourceText::lexer_problem_handler

=
inbuild_copy *currently_lexing_into = NULL;
void SourceText::lexer_problem_handler(int err, text_stream *desc, wchar_t *word) {
	if (err == MEMORY_OUT_LEXERERROR)
		Errors::fatal("Out of memory: unable to create lexer workspace");
    if (currently_lexing_into) {
		copy_error *CE = CopyErrors::new_WT(LEXER_CE, err, word, desc);
		Copies::attach_error(currently_lexing_into, CE);
    }
}

@ This next function is our bridge to the lexer (see //words: Text From Files//),
and is used for reading text files of source into either projects or extensions.
Note that it doesn't attach the fed text to the copy: the caller must do that,
perhaps combining our feed with that of others.

=
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
= (text as ConsoleText)
	I've also read Standard Rules by Graham Nelson, which is 27204 words long.
=
are printed to |stdout| (not |stderr|), though occasionally I think silence is
golden and that these messages could go. It's a moot point for almost all users,
though, because the console output is concealed from them by the Inform UI
applications.

@<Tell console output about the file@> =
	char *message = "I've also read %S, which is %d words long.\n";
	if (primary) message = "I've now read %S, which is %d words long.\n";
	int wc = TextFromFiles::total_word_count(sf);
	WRITE_TO(STDOUT, message, synopsis, wc);
	STREAM_FLUSH(STDOUT);
	LOG(message, synopsis, wc);

@h Bridge to the syntax analyser.
Similarly, //supervisor// sits on top of the //syntax// module, which forms
up the stream of words from the lexer into syntax trees. This too produces
potential errors, and these will also convert into copy errors, but now we
have a more elegant way to keep track of the copy; //syntax// can be passed
a sort of "your ref" pointer to it.

@d PROBLEM_REF_SYNTAX_TYPE struct inbuild_copy /* the "your ref" is a pointer to this type */
@d PROJECT_REF_SYNTAX_TYPE struct inform_project /* similarly but for the "project ref" */
@d PROBLEM_SYNTAX_CALLBACK SourceText::syntax_problem_handler

=
void SourceText::syntax_problem_handler(int err_no, wording W,
	PROBLEM_REF_SYNTAX_TYPE *C, int k) {
	copy_error *CE = CopyErrors::new_N(SYNTAX_CE, err_no, k);
	CopyErrors::supply_wording(CE, W);
	Copies::attach_error(C, CE);
}

@ And in fact we will be producing a number of syntax errors of our own, to
add to those generated in //syntax//.

@e ExtMultipleBeginsHere_SYNERROR
@e ExtBeginsAfterEndsHere_SYNERROR
@e ExtEndsWithoutBegins_SYNERROR
@e ExtMultipleEndsHere_SYNERROR
@e UseElementWithdrawn_SYNERROR
@e UnknownLanguageElement_SYNERROR
@e UnknownVirtualMachine_SYNERROR
@e HeadingInPlaceOfUnincluded_SYNERROR
@e UnequalHeadingInPlaceOf_SYNERROR
@e HeadingInPlaceOfSubordinate_SYNERROR
@e HeadingInPlaceOfUnknown_SYNERROR
@e IncludeExtQuoted_SYNERROR
@e BogusExtension_SYNERROR
@e ExtVersionTooLow_SYNERROR
@e ExtVersionMalformed_SYNERROR
@e ExtInadequateVM_SYNERROR
@e ExtMisidentifiedEnds_SYNERROR

@ The //inform7// compiler will eventually make a much more detailed syntax
tree, extending the one we make here: but we will basically just break the
text into sentences, arrange those under headings, and take action on just a
few so-called "structural sentences" which have to be dealt with early on.

//syntax// allows us to create a callback function which will be called
whenever a new sentence is made. What we use it for reflects that fact that
the vast bulk of the source text is read by //supervisor// early in a run of
//inform7//, with just a few sentences ("inventions") added later. The bulk
part is parsed collectively, but the later inventions have to be marked as
needing to be parsed one by one. So, when //supervisor// has definitely
finished loading the bulk in, it calls:

=
int bulk_of_source_loaded = FALSE;
void SourceText::bulk_of_source_loaded(void) {
	bulk_of_source_loaded = TRUE;
}

@ And here is the callback function. It's only ever needed for //inform7//,
not for //inbuild//, which isn't in the inventions business.

@d SENTENCE_ANNOTATION_SYNTAX_CALLBACK SourceText::annotate_new_sentence

=
void SourceText::annotate_new_sentence(parse_node *new) {
	if (bulk_of_source_loaded) {
		ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
		#ifdef CORE_MODULE
		Sentences::VPs::seek(new);
		#endif
	}
}

@ The next tweak to //syntax// is to give it some node metadata. //syntax//
itself places nodes of a small number of basic types into the syntax tree;
we want to expand on those. (And the //core// module will expand on them still
further, so this still isn't everything. Note that we give our own version of
|INVOCATION_LIST_NT| only if //inform7// is not the parent: that's because
there's a slightly different version in //core: Parse Tree Usage//.)

The node types we're adding are for the "structural sentences" which we will
look for below. (The asterisk notation for |TRACE_NT| isn't known to most
Inform users: it increases output to the debugging log.)

@d SYNTAX_TREE_METADATA_SETUP SourceText::node_metadata

@e BIBLIOGRAPHIC_NT    /* For the initial title sentence */
@e ROUTINE_NT          /* "Instead of taking something, ..." */
@e INFORM6CODE_NT      /* "Include (- ... -) */
@e TABLE_NT            /* "Table 1 - Counties of England" */
@e EQUATION_NT         /* "Equation 2 - Newton's Second Law" */
@e TRACE_NT            /* A sentence consisting of an asterisk and optional quoted text */
@e INVOCATION_LIST_NT  /* Single invocation of a (possibly compound) phrase */

@d list_node_type ROUTINE_NT
@d list_entry_node_type INVOCATION_LIST_NT

=
void SourceText::node_metadata(void) {
	ParseTree::md(BIBLIOGRAPHIC_NT, "BIBLIOGRAPHIC_NT",     0, 0,     L2_NCAT, 0);
	ParseTree::md(ROUTINE_NT, "ROUTINE_NT",                 0, INFTY, L2_NCAT, 0);
	ParseTree::md(INFORM6CODE_NT, "INFORM6CODE_NT",         0, 0,     L2_NCAT, 0);
	ParseTree::md(TABLE_NT, "TABLE_NT",                     0, 0,     L2_NCAT, TABBED_NFLAG);
	ParseTree::md(EQUATION_NT, "EQUATION_NT",               0, 0,     L2_NCAT, 0);
	ParseTree::md(TRACE_NT, "TRACE_NT",                     0, 0,     L2_NCAT, 0);
	#ifndef CORE_MODULE
	ParseTree::md(INVOCATION_LIST_NT, "INVOCATION_LIST_NT", 0, INFTY, L2_NCAT, 0);
	#endif
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
sections of source not being included for one reason or another.

//syntax// requires us to define the nonterminal |<dividing-sentence>|,
and here goes:

=
<dividing-sentence> ::=
	<if-start-of-paragraph> <heading> | ==> R[2]
	<extension-end-marker-sentence>     ==> R[1]

<heading> ::=
	volume ... |                        ==> 1
	book ... |                          ==> 2
	part ... |                          ==> 3
	chapter ... |                       ==> 4
	section ...                         ==> 5

<extension-end-marker-sentence> ::=
	... begin/begins here |             ==> -1; @<Check we can begin an extension here@>;
	... end/ends here                   ==> -2; @<Check we can end an extension here@>;

@ Note that the extension end markers are only read in extensions, so they can
never accidentally match in the main source text.

@<Check we can begin an extension here@> =
	switch (sfsm->ext_pos) {
		case 1: sfsm->ext_pos++; break;
		case 2: PROBLEM_SYNTAX_CALLBACK(ExtMultipleBeginsHere_SYNERROR, W, sfsm->ref, 0); break;
		case 3: PROBLEM_SYNTAX_CALLBACK(ExtBeginsAfterEndsHere_SYNERROR, W, sfsm->ref, 0); break;
	}

@<Check we can end an extension here@> =
	switch (sfsm->ext_pos) {
		case 1: PROBLEM_SYNTAX_CALLBACK(ExtEndsWithoutBegins_SYNERROR, W, sfsm->ref, 0); break;
		case 2: sfsm->ext_pos++; break;
		case 3: PROBLEM_SYNTAX_CALLBACK(ExtMultipleEndsHere_SYNERROR, W, sfsm->ref, 0); break;
	}

@ //syntax// also requires this definition:

=
<structural-sentence> ::=
	<if-start-of-source-text> <quoted-text> |      ==> 0; sfsm->nt = BIBLIOGRAPHIC_NT;
	<if-start-of-source-text> <quoted-text> ... |  ==> 0; sfsm->nt = BIBLIOGRAPHIC_NT;
	<language-modifying-sentence> |                ==> R[1]
	* |                                            ==> 0; sfsm->nt = TRACE_NT;
	* <quoted-text-without-subs> |                 ==> 0; sfsm->nt = TRACE_NT;
	<if-start-of-paragraph> table ... |            ==> 0; sfsm->nt = TABLE_NT;
	<if-start-of-paragraph> equation ... |         ==> 0; sfsm->nt = EQUATION_NT;
	include the ... by ... |                       ==> 0; sfsm->nt = INCLUDE_NT;
	include ... by ... |                           ==> 0; sfsm->nt = INCLUDE_NT;
	include (- ...                                 ==> 0; sfsm->nt = INFORM6CODE_NT;

@ Properly speaking, despite the definition above, language modifying sentences
are nonstructural. So what are they doing here? The answer is that we need to
read them early on, because they affect the way that they parse all other
sentences. Whereas other nonstructural sentences can wait, these can't.

=
<language-modifying-sentence> ::=
	include (- ### in the preform grammar |        ==> -2; sfsm->nt = INFORM6CODE_NT;
	use ... language element/elements              ==> -1

@ The following callback function is called by //syntax// when it breaks a
sentence of type |BEGINHERE_NT| or |ENDHERE_NT| -- i.e., the beginning or end
of an extension.

@d BEGIN_OR_END_HERE_SYNTAX_CALLBACK SourceText::new_beginend

=
void SourceText::new_beginend(parse_node *pn, inbuild_copy *C) {
	inform_extension *E = ExtensionManager::from_copy(C);
	if (ParseTree::get_type(pn) == BEGINHERE_NT) Inclusions::check_begins_here(pn, E);
	if (ParseTree::get_type(pn) == ENDHERE_NT) Inclusions::check_ends_here(pn, E);
}

@ Lastly, this callback is called by //syntax// when it hits a sentence like:

>> Use interactive fiction language element.

This feature of Inform has been withdrawn (it has moved lower down the software
stack into the new world of kits), so we issue a syntax error.

@d LANGUAGE_ELEMENT_SYNTAX_CALLBACK SourceText::new_language

=
void SourceText::new_language(wording W) {
	copy_error *CE = CopyErrors::new(SYNTAX_CE, UseElementWithdrawn_SYNERROR);
	CopyErrors::supply_node(CE, current_sentence);
	Copies::attach_error(sfsm->ref, CE);
}
