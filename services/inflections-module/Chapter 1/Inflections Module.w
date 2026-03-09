[InflectionsModule::] Inflections Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INFLECTIONS_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

@e CONSTRUCTED_PAST_PARTICIPLES_DA
@e CONSTRUCTED_PLURALS_DA

=
void InflectionsModule::start(void) {
	Log::declare_aspect(CONSTRUCTED_PAST_PARTICIPLES_DA,
		U"constructed past participles", FALSE, FALSE);
	Log::declare_aspect(CONSTRUCTED_PLURALS_DA,
		U"constructed plurals", FALSE, FALSE);
}
void InflectionsModule::end(void) {
}
