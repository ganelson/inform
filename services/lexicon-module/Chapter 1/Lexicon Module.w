[LexiconModule::] Lexicon Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d LEXICON_MODULE TRUE

@ This module defines the following classes:

@e excerpt_meaning_CLASS

=
DECLARE_CLASS(excerpt_meaning)

@ Like all modules, this one must define a |start| and |end| function:

@e EXCERPT_MEANINGS_DA
@e EXCERPT_PARSING_DA

=
void LexiconModule::start(void) {
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}
void LexiconModule::end(void) {
}

@

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(EXCERPT_MEANINGS_DA, L"excerpt meanings", FALSE, FALSE);
	Log::declare_aspect(EXCERPT_PARSING_DA, L"excerpt parsing", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('M', ExcerptMeanings::log);

@ This module uses //syntax//, and adds the following annotations to the
syntax tree.

@e meaning_ANNOT /* |excerpt_meaning|: for leaves */

=
DECLARE_ANNOTATION_FUNCTIONS(meaning, excerpt_meaning)

MAKE_ANNOTATION_FUNCTIONS(meaning, excerpt_meaning)
