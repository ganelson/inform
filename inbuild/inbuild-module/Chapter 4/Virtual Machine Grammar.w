[VMGrammar::] Virtual Machine Grammar.

Grammar for parsing natural language descriptions of a virtual machine.

@ This nonterminal corresponds to the Inbuild version number syntax in the
arch module: for example, it matches |2.7.6| or |3/990505|.

=
<version-number> internal 1 {
	TEMPORARY_TEXT(vtext);
	WRITE_TO(vtext, "%W", W);
	semantic_version_number V = VersionNumbers::from_text(vtext);
	int result = FALSE;
	if (VersionNumbers::is_null(V) == FALSE) {
		result = TRUE;
		semantic_version_number_holder *H = CREATE(semantic_version_number_holder);
		H->version = V;
		*XP = (void *) H;
	}
	DISCARD_TEXT(vtext);
	return result;
}

@ The following nonterminal matches any valid description of a virtual machine,
with result |TRUE| if the current target VM matches that description and
|FALSE| if not.
=
<virtual-machine> internal {
	TEMPORARY_TEXT(vtext);
	WRITE_TO(vtext, "%W", W);
	compatibility_specification *C = Compatibility::from_text(vtext);
	if (C) { *XP = C; return TRUE; }
	*XP = NULL; return FALSE;
}
