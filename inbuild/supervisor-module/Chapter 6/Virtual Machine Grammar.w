[VMGrammar::] Virtual Machine Grammar.

Grammar for parsing natural language descriptions of a virtual machine.

@ This nonterminal corresponds to the Inbuild version number syntax in the
arch module: for example, it matches |2.7.6| or |3/990505|. A bit
awkwardly, because a semantic version number is stored as an actual |struct|
rather than being created on the heap as an object: so we can't make the
return value of this nonterminal a pointer to that |struct|, as that would be
out of scope when needed. Instead, we have to wrap it up in a holder object
to give it permanency.

=
<version-number> internal 1 {
	TEMPORARY_TEXT(vtext)
	WRITE_TO(vtext, "%W", W);
	semantic_version_number V = VersionNumbers::from_text(vtext);
	DISCARD_TEXT(vtext)
	if (VersionNumbers::is_null(V) == FALSE) {
		semantic_version_number_holder *H = CREATE(semantic_version_number_holder);
		H->version = V;
		==> { -, H };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ The following nonterminal matches any valid description of a virtual machine.

=
<virtual-machine> internal {
	TEMPORARY_TEXT(vtext)
	WRITE_TO(vtext, "%W", W);
	compatibility_specification *C = Compatibility::from_text(vtext);
	DISCARD_TEXT(vtext)
	if (C) {
		==> { -, C };
		return TRUE;
	}
	==> { fail nonterminal };
}
