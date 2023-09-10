[LexiconModule::] Lexicon Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
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
	Log::declare_aspect(EXCERPT_MEANINGS_DA, U"excerpt meanings", FALSE, FALSE);
	Log::declare_aspect(EXCERPT_PARSING_DA, U"excerpt parsing", FALSE, FALSE);
	Writers::register_logger('M', ExcerptMeanings::log);
	@<Declare the tree annotations@>;
}
void LexiconModule::end(void) {
}

@ This module uses //syntax//, and adds the following annotations to the
syntax tree.

@e meaning_ANNOT /* |excerpt_meaning|: for leaves */

=
DECLARE_ANNOTATION_FUNCTIONS(meaning, excerpt_meaning)

MAKE_ANNOTATION_FUNCTIONS(meaning, excerpt_meaning)

@<Declare the tree annotations@> =
	Annotations::declare_type(meaning_ANNOT, LexiconModule::write_meaning_ANNOT);

@ =
void LexiconModule::write_meaning_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_meaning(p)) {
		WRITE(" {meaning: ");
		ExcerptMeanings::log(OUT, Node::get_meaning(p));
		WRITE("}");
	}
}
