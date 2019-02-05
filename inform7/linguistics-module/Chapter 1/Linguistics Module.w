[LinguisticsModule::] Linguistics Module.

Setting up the use of this module.

@h Introduction.

@d LINGUISTICS_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e adjectival_phrase_MT
@e adjective_usage_array_MT
@e quantifier_MT
@e determiner_MT
@e verb_identity_MT
@e verb_form_MT
@e verb_meaning_array_MT
@e verb_sense_MT
@e verb_usage_MT
@e verb_usage_tier_MT
@e preposition_identity_MT
@e time_period_array_MT
@e excerpt_meaning_MT
@e noun_MT

=
ALLOCATE_INDIVIDUALLY(adjectival_phrase)
ALLOCATE_IN_ARRAYS(adjective_usage, 1000)
ALLOCATE_INDIVIDUALLY(quantifier)
ALLOCATE_INDIVIDUALLY(determiner)
ALLOCATE_INDIVIDUALLY(verb_identity)
ALLOCATE_INDIVIDUALLY(verb_form)
ALLOCATE_IN_ARRAYS(verb_meaning, 100)
ALLOCATE_INDIVIDUALLY(verb_sense)
ALLOCATE_INDIVIDUALLY(verb_usage)
ALLOCATE_INDIVIDUALLY(verb_usage_tier)
ALLOCATE_INDIVIDUALLY(preposition_identity)
ALLOCATE_IN_ARRAYS(time_period, 100)
ALLOCATE_INDIVIDUALLY(excerpt_meaning)
ALLOCATE_INDIVIDUALLY(noun)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void LinguisticsModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
	Cardinals::enable_in_word_form();
	Articles::mark_for_preform();
	Prepositions::mark_for_preform();
	Diagrams::setup();
}

@<Register this module's stream writers@> =
	;

@

@e EXCERPT_MEANINGS_DA
@e EXCERPT_PARSING_DA
@e TIME_PERIODS_DA
@e VERB_USAGES_DA
@e VERB_FORMS_DA

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


@<Register this module's command line switches@> =
	;

@ =
void LinguisticsModule::preform_optimiser(void) {
	Cardinals::preform_optimiser();
	VerbUsages::preform_optimiser();
	Prepositions::preform_optimiser();
	Quantifiers::make_built_in();
}

@h The end.

=
void LinguisticsModule::end(void) {
}
