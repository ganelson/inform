[SHR::] Sentence Handler Registration.

This function has to be placed close to the end of the code for boring
compilation order reasons, not because it belongs here.

@ At this point in the tangled code, all of the assertion sentence handlers
-- with names like |TABLE_SH_handler| -- have now been created, so it is
safe to expand the following macros.

=
void SHR::register_sentence_handlers(void) {
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
}
