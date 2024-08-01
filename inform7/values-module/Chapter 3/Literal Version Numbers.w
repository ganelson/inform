[LiteralVersions::] Literal Version Numbers.

To parse version numbers written semver-style.

@ 

=
<s-literal-version-number> internal {
	if (Wordings::length(W) != 1) return FALSE;
	inchar32_t *p = Lexer::word_raw_text(Wordings::first_wn(W));
	if ((p) && (p[0] == 'v')) {
		int segments[3] = { 0, 0, 0 };
		int segment_count = 0, digits = 0;

		int i = 1;
		while (p[i]) {
			if (Characters::isdigit(p[i])) {
				segments[segment_count] = 10*segments[segment_count] + ((int) p[i] - (int) '0');
				digits++;
				if (digits > 9) {
					==> { fail nonterminal };
				}
			} else if ((p[i] == '.') && (segment_count < 2) && (digits > 0)) {
				digits = 0; segment_count++;
			} else {
				==> { fail nonterminal };
			}
			i++;
		}
		if (digits > 0) {
			TEMPORARY_TEXT(vtext)
			WRITE_TO(vtext, "%d", segments[0]);
			if (segment_count >= 1) WRITE_TO(vtext, ".%d", segments[1]);
			if (segment_count >= 2) WRITE_TO(vtext, ".%d", segments[2]);
			semantic_version_number V = VersionNumbers::from_text(vtext);
			DISCARD_TEXT(vtext)
			==> { -, Rvalues::from_version(V, W) }
			return TRUE;
		}
	}
	==> { fail nonterminal };
}
