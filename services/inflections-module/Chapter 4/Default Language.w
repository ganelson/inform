[DefaultLanguage::] Default Language.

To keep track of what the default natural language is.

@ The following mechanism may become more sophisticated later.

=
NATURAL_LANGUAGE_WORDS_TYPE *default_language_for_linguistics = NULL;

void DefaultLanguage::set(NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	default_language_for_linguistics = nl;
}

NATURAL_LANGUAGE_WORDS_TYPE *DefaultLanguage::get(NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	if (nl) return nl;
	return default_language_for_linguistics;
}
