[InflectionsModule::] Inflections Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INFLECTIONS_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e name_cluster_CLASS
@e individual_name_CLASS
@e plural_dictionary_entry_CLASS
@e verb_conjugation_CLASS

=
DECLARE_CLASS(individual_name)
DECLARE_CLASS(name_cluster)
DECLARE_CLASS(plural_dictionary_entry)
DECLARE_CLASS(verb_conjugation)

@ Like all modules, this one must define a |start| and |end| function:

=
void InflectionsModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}
void InflectionsModule::end(void) {
}

@<Register this module's stream writers@> =
	;

@

@e CONSTRUCTED_PAST_PARTICIPLES_DA
@e CONSTRUCTED_PLURALS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(CONSTRUCTED_PAST_PARTICIPLES_DA, L"constructed past participles", FALSE, FALSE);
	Log::declare_aspect(CONSTRUCTED_PLURALS_DA, L"constructed plurals", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;

@<Register this module's command line switches@> =
	;
