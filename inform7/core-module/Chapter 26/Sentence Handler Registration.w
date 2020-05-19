[SHR::] Sentence Handler Registration.

This routine has to be placed close to the end of the code for boring
compilation order reasons, not because it belongs here.

@h Registration of sentence handlers.
At this point in the tangled code, all of the assertion sentence handlers
-- with names like |TABLE_SH_handler| -- have now been created, so it is
safe to expand the following macros.

=
void SHR::register_sentence_handlers(void) {
	@<Add sentence handlers for the top-level node types@>;
	@<Add sentence handlers for the SENTENCE/VERB node types@>;
}

@ This is all of the node types still present at the top level of the tree
at the end of sentence-breaking.

@<Add sentence handlers for the top-level node types@> =
	REGISTER_SENTENCE_HANDLER(TRACE_SH);
	REGISTER_SENTENCE_HANDLER(BEGINHERE_SH);
	REGISTER_SENTENCE_HANDLER(ENDHERE_SH);
	#ifdef IF_MODULE
	REGISTER_SENTENCE_HANDLER(BIBLIOGRAPHIC_SH);
	#endif
	REGISTER_SENTENCE_HANDLER(INFORM6CODE_SH);
	REGISTER_SENTENCE_HANDLER(COMMAND_SH);
	REGISTER_SENTENCE_HANDLER(ROUTINE_SH);
	REGISTER_SENTENCE_HANDLER(TABLE_SH);
	REGISTER_SENTENCE_HANDLER(EQUATION_SH);
	REGISTER_SENTENCE_HANDLER(HEADING_SH);
	REGISTER_SENTENCE_HANDLER(SENTENCE_SH);

@ And here are all of the verb types found in |VERB_NT| nodes which are
first children of |SENTENCE_NT| nodes.

@<Add sentence handlers for the SENTENCE/VERB node types@> =
	REGISTER_SENTENCE_HANDLER(ASSERT_SH);
	REGISTER_SENTENCE_HANDLER(SPECIAL_MEANING_SH);
