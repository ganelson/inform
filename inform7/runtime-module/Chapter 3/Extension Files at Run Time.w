[RTExtensions::] Extension Files at Run Time.

To provide the credits routines.

@ Here we compile a routine to print out credits for all the extensions
present in the compiled work. This is important because the extensions
published at the Inform website are available under a Creative Commons
license which requires users to give credit to the authors: Inform
ensures that this happens automatically.

Use of authorial modesty (see above) will suppress a credit in the
|ShowExtensionVersions| routine, but the system is set up so that one can
only be modest about one's own extensions: this would otherwise violate a
CC license of somebody else. General authorial modesty thus suppresses
credits for all extensions used which are by the user himself. On the
other hand, if an extension contains an authorial modesty disclaimer
in its own text, then that must have been the wish of its author, so
we can suppress the credit whoever that author was.

In |I7FullExtensionVersions| all extensions are credited whatever anyone's
feelings of modesty.

=
void RTExtensions::ShowExtensionVersions_routine(void) {
	inter_name *iname = Hierarchy::find(SHOWEXTENSIONVERSIONS_HL);
	packaging_state save = Functions::begin(iname);
	inform_extension *E;
	LOOP_OVER(E, inform_extension) {
		TEMPORARY_TEXT(the_author_name)
		WRITE_TO(the_author_name, "%S", E->as_copy->edition->work->author_name);
		int self_penned = FALSE;
		#ifdef IF_MODULE
		if (BibliographicData::story_author_is(the_author_name)) self_penned = TRUE;
		#endif
		if (((E == NULL) || (E->authorial_modesty == FALSE)) && /* if (1) extension doesn't ask to be modest */
			((general_authorial_modesty == FALSE) || /* and (2) author doesn't ask to be modest, or... */
			(self_penned == FALSE))) { /* ...didn't write this extension */
				TEMPORARY_TEXT(C)
				RTExtensions::credit_ef(C, E, TRUE); /* then we award a credit */
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(C);
				EmitCode::up();
				DISCARD_TEXT(C)
			}
		DISCARD_TEXT(the_author_name)
	}
	Functions::end(save);
	Hierarchy::make_available(iname);

	iname = Hierarchy::find(SHOWFULLEXTENSIONVERSIONS_HL);
	save = Functions::begin(iname);
	LOOP_OVER(E, inform_extension) {
		TEMPORARY_TEXT(C)
		RTExtensions::credit_ef(C, E, TRUE);
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(C);
		EmitCode::up();
		DISCARD_TEXT(C)
	}
	Functions::end(save);
	Hierarchy::make_available(iname);
	
	iname = Hierarchy::find(SHOWONEEXTENSION_HL);
	save = Functions::begin(iname);
	inter_symbol *id_s = LocalVariables::new_other_as_symbol(I"id");
	LOOP_OVER(E, inform_extension) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, id_s);
				EmitCode::val_number((inter_ti) (E->allocation_id + 1));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				TEMPORARY_TEXT(C)
				RTExtensions::credit_ef(C, E, FALSE);
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(C);
				EmitCode::up();
				DISCARD_TEXT(C)
			EmitCode::up();
		EmitCode::up();
	}
	Functions::end(save);
	Hierarchy::make_available(iname);
}

@ The actual credit consists of a single line, with name, version number
and author.

=
void RTExtensions::credit_ef(OUTPUT_STREAM, inform_extension *E, int with_newline) {
	if (E == NULL) internal_error("unfound ef");
	WRITE("%S", E->as_copy->edition->work->raw_title);
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V) == FALSE) WRITE(" version %v", &V);
	WRITE(" by %S", E->as_copy->edition->work->raw_author_name);
	if (Str::len(E->extra_credit_as_lexed) > 0) WRITE(" (%S)", E->extra_credit_as_lexed);
	if (with_newline) WRITE("\n");
}
