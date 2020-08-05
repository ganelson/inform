[IFModuleMeanings::] IF Special Meanings.

Setting up the use of this module.

@ =
void IFModuleMeanings::bootstrap(void) {
	SpecialMeanings::declare(PL::Scenes::begins_when_SMF,						I"scene-begins-when", 1);
	SpecialMeanings::declare(PL::Scenes::ends_when_SMF,							I"scene-ends-when", 1);
	SpecialMeanings::declare(PL::Parsing::understand_as_SMF,					I"understand-as", 1);

	SpecialMeanings::declare(PL::Actions::new_action_SMF, 						I"new-action", 2);
	SpecialMeanings::declare(PL::Bibliographic::episode_SMF,					I"episode", 2);

	SpecialMeanings::declare(PL::Bibliographic::Release::release_along_with_SMF,I"release-along-with", 4);
	SpecialMeanings::declare(PL::EPSMap::index_map_with_SMF,					I"index-map-with", 4);
}
