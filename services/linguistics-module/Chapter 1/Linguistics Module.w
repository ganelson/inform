[LinguisticsModule::] Linguistics Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d LINGUISTICS_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

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
	Log::declare_aspect(LINGUISTIC_STOCK_DA, U"linguistic stock", FALSE, FALSE);
	Log::declare_aspect(TIME_PERIODS_DA, U"time periods", FALSE, FALSE);
	Log::declare_aspect(VERB_USAGES_DA, U"verb usages", FALSE, TRUE);
	Log::declare_aspect(VERB_FORMS_DA, U"verb forms", FALSE, TRUE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('t', Occurrence::log);
	Writers::register_logger('p', Prepositions::log);
	Writers::register_logger('w', Verbs::log_verb);
	Writers::register_logger('y', VerbMeanings::log);
	REGISTER_WRITER('z', Nouns::log);

@ Not all of our memory will be claimed in the form of structures: now and then
we need to use the equivalent of traditional `malloc` and `calloc` routines.

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
