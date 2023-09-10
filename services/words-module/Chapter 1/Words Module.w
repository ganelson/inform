[WordsModule::] Words Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//,
and contains no code of interest. The following constant exists only in tools
which use this module:

@d WORDS_MODULE TRUE

@ This module defines the following classes:

@e source_file_CLASS
@e vocabulary_entry_CLASS
@e nonterminal_CLASS
@e production_CLASS
@e production_list_CLASS
@e ptoken_CLASS

=
DECLARE_CLASS(source_file)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(vocabulary_entry, 100)
DECLARE_CLASS(nonterminal)
DECLARE_CLASS(production_list)
DECLARE_CLASS(production)
DECLARE_CLASS(ptoken)

@ Like all modules, this one must define a |start| and |end| function:

@e LEXER_TEXT_MREASON
@e LEXER_WORDS_MREASON

@e LEXICAL_OUTPUT_DA
@e VOCABULARY_DA

=
void WordsModule::start(void) {
	Memory::reason_name(LEXER_TEXT_MREASON, "source text");
	Memory::reason_name(LEXER_WORDS_MREASON, "source text details");

	Writers::register_writer('A', &WordAssemblages::writer); /* |%A| = write word assemblage */
	Writers::register_writer_I('N', &Lexer::writer);         /* |%N| = write word with this number */
	Writers::register_writer('V', &Vocabulary::writer);      /* |%V| = write vocabulary entry */
	Writers::register_writer_W('W', &Wordings::writer);      /* |%W| = write wording */

	Log::declare_aspect(LEXICAL_OUTPUT_DA, U"lexical output", FALSE, FALSE);
	Log::declare_aspect(VOCABULARY_DA, U"vocabulary", FALSE, FALSE);

	Writers::register_logger('f', WordAssemblages::log); /* |$f| = log word assemblage */
	Writers::register_logger('v', Vocabulary::log);      /* |$v| = log vocabulary entry */

	Lexer::start();
	Vocabulary::create_punctuation();
	LoadPreform::create_punctuation();
	Nonterminals::register();
}

void WordsModule::end(void) {
}
