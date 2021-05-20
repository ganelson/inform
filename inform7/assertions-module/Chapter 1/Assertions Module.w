[AssertionsModule::] Assertions Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d ASSERTIONS_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e ASSEMBLIES_DA
@e ASSERTIONS_DA
@e IMPLICATIONS_DA
@e NOUN_RESOLUTION_DA
@e PRONOUNS_DA
@e RELATION_DEFINITIONS_DA

=
COMPILE_WRITER(table *, Tables::log)
COMPILE_WRITER(table_column *, Tables::Columns::log)

void AssertionsModule::start(void) {
	AdjectivalPredicates::start();
	CreationPredicates::start();
	Calculus::QuasinumericRelations::start();
	Relations::Universal::start();
	ExplicitRelations::start();
	EqualityDetails::start();
	KindPredicatesRevisited::start();
	ImperativeDefinitionFamilies::create();
	AdjectivesByPhrase::start();
	AdjectivesByCondition::start();
	AdjectivesByInterFunction::start();
	AdjectivesByInterCondition::start();

	Log::declare_aspect(ASSEMBLIES_DA, L"assemblies", FALSE, FALSE);
	Log::declare_aspect(ASSERTIONS_DA, L"assertions", FALSE, TRUE);
	Log::declare_aspect(IMPLICATIONS_DA, L"implications", FALSE, TRUE);
	Log::declare_aspect(NOUN_RESOLUTION_DA, L"noun resolution", FALSE, FALSE);
	Log::declare_aspect(PRONOUNS_DA, L"pronouns", FALSE, FALSE);
	Log::declare_aspect(RELATION_DEFINITIONS_DA, L"relation definitions", FALSE, FALSE);

	InternalTests::make_test_available(I"refinery",
		&Classifying::perform_refinery_internal_test, TRUE);
	InternalTests::make_test_available(I"equation",
		&Equations::perform_equation_internal_test, TRUE);
}
void AssertionsModule::end(void) {
}
