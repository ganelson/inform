[RTExtensions::] Extension Files at Run Time.

To compile the credits functions.

@ Extensions have an obvious effect at runtime -- they include extra material.
But there are also just three functions which deal with extensions as if
they were values; all of them simply print credits out.

This is more important than it may sound because many extensions are published
under a Creative Commons attribution license which requires users to give credit
to the authors: Inform thus ensures that this happens automatically.

There are two forms of exemption from this --
(*) specific authorial modesty suppresses the author's name for one extension,
at that extension author's discretion;
(*) general authorial modesty suppresses the author's name for any extensions
by the same person who wrote the main source text.

By design, however, the author of the main source text cannot remove the name
of a different author writing an extension which did not ask for modesty. That
would violate the CC license.

=
void RTExtensions::compile_support(void) {
	@<Compile SHOWEXTENSIONVERSIONS function@>;
	@<Compile SHOWFULLEXTENSIONVERSIONS function@>;
	@<Compile SHOWONEEXTENSION function@>;
}

@<Compile SHOWEXTENSIONVERSIONS function@> =
	inter_name *iname = Hierarchy::find(SHOWEXTENSIONVERSIONS_HL);
	packaging_state save = Functions::begin(iname);
	inform_extension *E;
	LOOP_OVER(E, inform_extension) {
		TEMPORARY_TEXT(the_author_name)
		WRITE_TO(the_author_name, "%S", E->as_copy->edition->work->author_name);
		int self_penned = FALSE;
		if (BibliographicData::story_author_is(the_author_name)) self_penned = TRUE;
		if ((E->authorial_modesty == FALSE) &&      /* if (1) extension doesn't ask to be modest */
			((general_authorial_modesty == FALSE) || /* and (2a) author doesn't ask to be modest, or */
			    (self_penned == FALSE))) {           /*     (2b) didn't write this extension */
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

@ This fuller version does not allow the exemptions.

@<Compile SHOWFULLEXTENSIONVERSIONS function@> =
	inter_name *iname = Hierarchy::find(SHOWFULLEXTENSIONVERSIONS_HL);
	packaging_state save = Functions::begin(iname);
	inform_extension *E;
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

@ This prints the name of a single extension, identified by a value which
is its allocation ID plus 1. (In effect, this means extensions are numbered from
1 upwards in order of inclusion.)

@<Compile SHOWONEEXTENSION function@> =	
	inter_name *iname = Hierarchy::find(SHOWONEEXTENSION_HL);
	packaging_state save = Functions::begin(iname);
	inter_symbol *id_s = LocalVariables::new_other_as_symbol(I"id");
	inform_extension *E;
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

@ The actual credit consists of a single line, with name, version number
and author; together with any "extra credit" asked for by the extension.

=
void RTExtensions::credit_ef(OUTPUT_STREAM, inform_extension *E, int with_newline) {
	if (E == NULL) internal_error("no ef");
	WRITE("%S", E->as_copy->edition->work->raw_title);
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V) == FALSE) WRITE(" version %v", &V);
	WRITE(" by %S", E->as_copy->edition->work->raw_author_name);
	if (Str::len(E->extra_credit_as_lexed) > 0) WRITE(" (%S)", E->extra_credit_as_lexed);
	if (with_newline) WRITE("\n");
}
