[InflectionDefns::] Linguistic Definitions.

Some basic linguistic constants are defined.

@h Constants.
First, we support three genders:

@d NO_KNOWN_GENDERS 3
@d NEUTER_GENDER 1 /* or can be used as Scandinavian "common gender" */
@d MASCULINE_GENDER 2
@d FEMININE_GENDER 3

@ There are six "persons". The sequence corresponds to the defined constants
in the English Language extension, which we assume will be followed by other
languages.

@d NO_KNOWN_PERSONS 6
@d FIRST_PERSON_SINGULAR 0
@d SECOND_PERSON_SINGULAR 1
@d THIRD_PERSON_SINGULAR 2
@d FIRST_PERSON_PLURAL 3
@d SECOND_PERSON_PLURAL 4
@d THIRD_PERSON_PLURAL 5

@ And two numbers:

@d NO_KNOWN_NUMBERS 2
@d SINGULAR_NUMBER 0
@d PLURAL_NUMBER 1

@ And two moods:

@d NO_KNOWN_MOODS 2
@d ACTIVE_MOOD 0
@d PASSIVE_MOOD 1

@ 25 cases sounds like plenty, but some languages are pretty scary this
way: Hungarian has 18. We only require one case to exist, the nominative,
which is required to be case 0.

@d MAX_GRAMMATICAL_CASES 25
@d NOMINATIVE_CASE 0

@ There are at least five tenses, the first four of which are used by Inform
in English. Some languages can use optional extras; French, for example, uses
tense 5 for the past historic.

@d NO_KNOWN_TENSES 7 /* allowing for two optional extras in non-English languages */
@d IS_TENSE 0		/* Present */
@d WAS_TENSE 1 		/* Past */
@d HASBEEN_TENSE 2 	/* Present perfect */
@d HADBEEN_TENSE 3 	/* Past perfect */
@d WILLBE_TENSE 4 	/* Future (not used in assertions or conditions) */
@d CUSTOM1_TENSE 5
@d CUSTOM2_TENSE 6

=
void InflectionDefns::log_tense_number(OUTPUT_STREAM, int t) {
	switch (t) {
		case IS_TENSE:      WRITE("IS_TENSE"); break;
		case WAS_TENSE:     WRITE("WAS_TENSE"); break;
		case HASBEEN_TENSE: WRITE("HASBEEN_TENSE"); break;
		case HADBEEN_TENSE: WRITE("HADBEEN_TENSE"); break;
		case WILLBE_TENSE:  WRITE("WILLBE_TENSE"); break;
		case CUSTOM1_TENSE: WRITE("CUSTOM1_TENSE"); break;
		case CUSTOM2_TENSE: WRITE("CUSTOM2_TENSE"); break;
		default:            WRITE("<invalid-tense>"); break;
	}
}

@h A default language.
The following is in effect also a constant; Inform sets it to English early
in its run.

=
NATURAL_LANGUAGE_WORDS_TYPE *default_language_for_linguistics = NULL;

void InflectionDefns::set_default_nl(NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	default_language_for_linguistics = nl;
}

NATURAL_LANGUAGE_WORDS_TYPE *InflectionDefns::default_nl(NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	if (nl) return nl;
	return default_language_for_linguistics;
}
