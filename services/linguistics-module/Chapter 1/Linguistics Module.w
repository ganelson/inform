[LinguisticsModule::] Linguistics Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d LINGUISTICS_MODULE TRUE

@ This module defines the following classes:

@e adjectival_phrase_CLASS
@e adjective_usage_CLASS
@e quantifier_CLASS
@e determiner_CLASS
@e verb_identity_CLASS
@e verb_form_CLASS
@e verb_meaning_CLASS
@e verb_sense_CLASS
@e verb_usage_CLASS
@e verb_usage_tier_CLASS
@e preposition_identity_CLASS
@e time_period_CLASS
@e excerpt_meaning_CLASS
@e noun_CLASS

=
DECLARE_CLASS(adjectival_phrase)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(adjective_usage, 1000)
DECLARE_CLASS(quantifier)
DECLARE_CLASS(determiner)
DECLARE_CLASS(verb_identity)
DECLARE_CLASS(verb_form)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(verb_meaning, 100)
DECLARE_CLASS(verb_sense)
DECLARE_CLASS(verb_usage)
DECLARE_CLASS(verb_usage_tier)
DECLARE_CLASS(preposition_identity)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(time_period, 100)
DECLARE_CLASS(excerpt_meaning)
DECLARE_CLASS(noun)

@ Like all modules, this one must define a |start| and |end| function:

@e EXCERPT_MEANINGS_DA
@e EXCERPT_PARSING_DA
@e TIME_PERIODS_DA
@e VERB_USAGES_DA
@e VERB_FORMS_DA

=
void LinguisticsModule::start(void) {
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	Cardinals::enable_in_word_form();
	Articles::mark_for_preform();
	Prepositions::mark_for_preform();
}
void LinguisticsModule::end(void) {
}

@

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(TIME_PERIODS_DA, L"time periods", FALSE, FALSE);
	Log::declare_aspect(VERB_USAGES_DA, L"verb usages", FALSE, TRUE);
	Log::declare_aspect(VERB_FORMS_DA, L"verb forms", FALSE, TRUE);
	Log::declare_aspect(EXCERPT_MEANINGS_DA, L"excerpt meanings", FALSE, FALSE);
	Log::declare_aspect(EXCERPT_PARSING_DA, L"excerpt parsing", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('M', ExcerptMeanings::log);
	Writers::register_logger('t', Occurrence::log);
	Writers::register_logger('p', Prepositions::log);
	Writers::register_logger('w', Verbs::log_verb);
	Writers::register_logger('y', VerbMeanings::log);

@ This module uses //syntax//, and adds the following annotations to the
syntax tree.

@e meaning_ANNOT /* |excerpt_meaning|: for leaves */

@e verbal_certainty_ANNOT		 /* |int|: certainty level if known */
@e sentence_is_existential_ANNOT /* |int|: such as "there is a man" */
@e linguistic_error_here_ANNOT   /* |int|: one of the errors occurred here */
@e inverted_verb_ANNOT   		 /* |int|: an inversion of subject and object has occurred */
@e possessive_verb_ANNOT   		 /* |int|: this is a non-relative use of "to have" */
@e verb_ANNOT   				 /* |verb_usage|: what's being done here */
@e preposition_ANNOT   			 /* |preposition_identity|: which preposition, if any, qualifies it */
@e second_preposition_ANNOT   	 /* |preposition_identity|: which further preposition, if any, qualifies it */
@e verb_meaning_ANNOT   		 /* |verb_meaning|: what it means */

@e nounphrase_article_ANNOT 	 /* |int|: definite or indefinite article: see below */
@e plural_reference_ANNOT 		 /* |int|: used by PROPER NOUN nodes for evident plurals */
@e gender_reference_ANNOT 		 /* |int|: used by PROPER NOUN nodes for evident genders */
@e relationship_node_type_ANNOT  /* |int|: what kind of inference this assertion makes */
@e implicitly_refers_to_ANNOT 	 /* |int|: this will implicitly refer to something */

=
DECLARE_ANNOTATION_FUNCTIONS(meaning, excerpt_meaning)
DECLARE_ANNOTATION_FUNCTIONS(verb, verb_usage)
DECLARE_ANNOTATION_FUNCTIONS(preposition, preposition_identity)
DECLARE_ANNOTATION_FUNCTIONS(second_preposition, preposition_identity)
DECLARE_ANNOTATION_FUNCTIONS(verb_meaning, verb_meaning)

MAKE_ANNOTATION_FUNCTIONS(meaning, excerpt_meaning)
MAKE_ANNOTATION_FUNCTIONS(verb, verb_usage)
MAKE_ANNOTATION_FUNCTIONS(preposition, preposition_identity)
MAKE_ANNOTATION_FUNCTIONS(second_preposition, preposition_identity)
MAKE_ANNOTATION_FUNCTIONS(verb_meaning, verb_meaning)

@ This module requires |words|, which contains the Preform parser. When that
initialises, it calls the following routine to improve its performance.

@d PREFORM_OPTIMISER_WORDS_CALLBACK LinguisticsModule::preform_optimiser

=
int first_round_of_nt_optimisation_made = FALSE;
void LinguisticsModule::preform_optimiser(void) {
	Cardinals::preform_optimiser();
	VerbUsages::preform_optimiser();
	Prepositions::preform_optimiser();
	if (first_round_of_nt_optimisation_made == FALSE) {
		first_round_of_nt_optimisation_made = TRUE;
		Quantifiers::make_built_in();
	}
}
