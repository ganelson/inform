[I6Errors::] Inform 6 Syntax Errors.

To issue problem messages when parsing malformed I6-syntax code.

@ Errors like these used to be basically failed assertions, but inevitably people
reported that as a bug (Mantis 0001596). It was never intended that Inform 6-syntax
hacking should be part of the outside-facing Inform language; but if you leave
power tools just lying around, people will eventually pick them up and wonder
what the red button marked "danger" does.

Note that |i6_syntax_error_location| is initially uninitialised and thus has
undefined contents, so we take care to blank it out if it is read before being
written to for the first time.

=
text_provenance i6_syntax_error_location;
int i6_syntax_error_location_set = FALSE;

text_provenance I6Errors::get_current_location(void) {
	if (i6_syntax_error_location_set == FALSE)
		I6Errors::clear_current_location();
	return i6_syntax_error_location;
}
void I6Errors::clear_current_location(void) {
	I6Errors::set_current_location(Provenance::nowhere());
}
void I6Errors::set_current_location(text_provenance where) {
	i6_syntax_error_location_set = TRUE;
	i6_syntax_error_location = where;
}

void I6Errors::set_current_location_near_splat(inter_tree_node *P) {
	I6Errors::clear_current_location();
	if ((P) && (Inode::is(P, SPLAT_IST)))
		I6Errors::set_current_location(SplatInstruction::provenance(P));
}

@ The issuing mechanism, or rather, the mechanism used if the main Inform
compiler doesn't gazump us (in order to provide something better-looking in
the GUI apps).

=
int i6_syntax_error_count = 0;

void I6Errors::issue(char *message, text_stream *quote) {
	text_provenance at = I6Errors::get_current_location();
	#ifdef CORE_MODULE
	SourceProblems::I6_level_error(message, quote, at);
	#endif
	#ifndef CORE_MODULE
	if (Provenance::is_somewhere(at)) {
		filename *F = Provenance::get_filename(at);
		TEMPORARY_TEXT(M)
		WRITE_TO(M, message, quote);
		Errors::at_position_S(M, F, Provenance::get_line(at));
		DISCARD_TEXT(M)
	} else {
		Errors::with_text(message, quote);
	}
	#endif
	i6_syntax_error_count++;
}

void I6Errors::reset_count(void) {
	I6Errors::clear_current_location();
	i6_syntax_error_count = 0;
}

int I6Errors::errors_occurred(void) {
	if (i6_syntax_error_count != 0) return TRUE;
	return FALSE;
}

@ The functions below are for errors detected when parsing text into schemas, or
when emitting code from them.

Note that the |parsing_errors| field  of a schema is null until the first error
is detected -- which, of course, it usually isn't. It holds a linked list of these:

=
typedef struct schema_parsing_error {
	struct text_stream *message;
	struct text_provenance provenance;
	CLASS_DEFINITION
} schema_parsing_error;

@ =
void I6Errors::issue_at_node(inter_schema_node *at, text_stream *message) {
	if (at->parent_schema->parsing_errors == NULL)
		at->parent_schema->parsing_errors = NEW_LINKED_LIST(schema_parsing_error);
	schema_parsing_error *err = CREATE(schema_parsing_error);
	err->message = Str::duplicate(message);
	if (at) {
		if (Provenance::is_somewhere(at->provenance)) err->provenance = at->provenance;
		else if (at->parent_schema) err->provenance = at->parent_schema->provenance;
		else err->provenance = Provenance::nowhere();
	} else {
		err->provenance = Provenance::nowhere();
	}
	ADD_TO_LINKED_LIST(err, schema_parsing_error, at->parent_schema->parsing_errors);
	LOG("Schema error: %S\n", message);
	if ((at->parent_schema) && (Provenance::is_somewhere(at->parent_schema->provenance)))
		LOG("Schema provenance %f, line %d\n",
			Provenance::get_filename(at->parent_schema->provenance),
			Provenance::get_line(at->parent_schema->provenance));
	LOG("$1\n", at->parent_schema);
}

@ That function of course caches schema errors for playback later: well, here's
the later. Unless the main Inform compiler takes over from us, the result will
be drastic, halting what is presumably the |inter| tool:

=
void I6Errors::internal_error_on_schema_errors(inter_schema *sch) {
	if (LinkedLists::len(sch->parsing_errors) > 0) {
		#ifdef CORE_MODULE
		SourceProblems::inter_schema_errors(sch);
		#endif
		#ifndef CORE_MODULE
		WRITE_TO(STDERR, "Parsing error(s) in the internal schema '%S':\n",
			sch->converted_from);
		schema_parsing_error *err;
		LOOP_OVER_LINKED_LIST(err, schema_parsing_error, sch->parsing_errors)
			WRITE_TO(STDERR, "- %S\n", err->message);
		exit(1);
		#endif
	}
}
