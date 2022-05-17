[InflectionsModule::] Inflections Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INFLECTIONS_MODULE TRUE

@ This module defines the following classes:

@e lexical_cluster_CLASS
@e individual_form_CLASS
@e plural_dictionary_entry_CLASS
@e verb_conjugation_CLASS

=
DECLARE_CLASS(individual_form)
DECLARE_CLASS(lexical_cluster)
DECLARE_CLASS(plural_dictionary_entry)
DECLARE_CLASS(verb_conjugation)

@ Like all modules, this one must define a |start| and |end| function:

@e CONSTRUCTED_PAST_PARTICIPLES_DA
@e CONSTRUCTED_PLURALS_DA

=
void InflectionsModule::start(void) {
	Log::declare_aspect(CONSTRUCTED_PAST_PARTICIPLES_DA,
		L"constructed past participles", FALSE, FALSE);
	Log::declare_aspect(CONSTRUCTED_PLURALS_DA,
		L"constructed plurals", FALSE, FALSE);
}
void InflectionsModule::end(void) {
}
