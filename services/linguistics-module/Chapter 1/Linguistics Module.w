[LinguisticsModule::] Linguistics Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d LINGUISTICS_MODULE TRUE

@ This module defines the following classes:

@e adjective_CLASS
@e article_CLASS
@e article_usage_CLASS
@e quantifier_CLASS
@e determiner_CLASS
@e grammatical_category_CLASS
@e linguistic_stock_item_CLASS
@e grammatical_usage_CLASS
@e verb_CLASS
@e verb_form_CLASS
@e verb_meaning_CLASS
@e verb_sense_CLASS
@e verb_usage_CLASS
@e verb_usage_tier_CLASS
@e preposition_CLASS
@e noun_CLASS
@e noun_usage_CLASS
@e pronoun_CLASS
@e pronoun_usage_CLASS
@e small_word_set_CLASS
@e special_meaning_holder_CLASS
@e time_period_CLASS

=
DECLARE_CLASS(adjective)
DECLARE_CLASS(article)
DECLARE_CLASS(article_usage)
DECLARE_CLASS(quantifier)
DECLARE_CLASS(determiner)
DECLARE_CLASS(grammatical_category)
DECLARE_CLASS(linguistic_stock_item)
DECLARE_CLASS(grammatical_usage)
DECLARE_CLASS(verb)
DECLARE_CLASS(verb_form)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(verb_meaning, 100)
DECLARE_CLASS(verb_sense)
DECLARE_CLASS(verb_usage)
DECLARE_CLASS(verb_usage_tier)
DECLARE_CLASS(preposition)
DECLARE_CLASS(time_period)
DECLARE_CLASS(noun)
DECLARE_CLASS(noun_usage)
DECLARE_CLASS(pronoun)
DECLARE_CLASS(pronoun_usage)
DECLARE_CLASS(special_meaning_holder)
DECLARE_CLASS(small_word_set)

@ Like all modules, this one must define a |start| and |end| function:

@e LINGUISTIC_STOCK_DA
@e TIME_PERIODS_DA
@e VERB_USAGES_DA
@e VERB_FORMS_DA

=
COMPILE_WRITER(noun *, Nouns::log)

void LinguisticsModule::start(void) {
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Declare new memory allocation reasons@>;
	Stock::create_categories();
	Cardinals::enable_in_word_form();
	Articles::mark_for_preform();
	Prepositions::mark_for_preform();
	Diagrams::declare_annotations();
}
void LinguisticsModule::end(void) {
}

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(LINGUISTIC_STOCK_DA, L"linguistic stock", FALSE, FALSE);
	Log::declare_aspect(TIME_PERIODS_DA, L"time periods", FALSE, FALSE);
	Log::declare_aspect(VERB_USAGES_DA, L"verb usages", FALSE, TRUE);
	Log::declare_aspect(VERB_FORMS_DA, L"verb forms", FALSE, TRUE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('t', Occurrence::log);
	Writers::register_logger('p', Prepositions::log);
	Writers::register_logger('w', Verbs::log_verb);
	Writers::register_logger('y', VerbMeanings::log);
	REGISTER_WRITER('z', Nouns::log);

@ Not all of our memory will be claimed in the form of structures: now and then
we need to use the equivalent of traditional |malloc| and |calloc| routines.

@e STOCK_MREASON
@e SWS_MREASON

@<Declare new memory allocation reasons@> =
	Memory::reason_name(STOCK_MREASON, "linguistic stock array");
	Memory::reason_name(SWS_MREASON, "small word set array");

@ This module requires //words//, which contains the Preform parser. When that
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
