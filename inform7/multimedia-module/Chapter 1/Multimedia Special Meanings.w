[MultimediaMeanings::] Multimedia Special Meanings.

Setting up the use of this module.

@ =
void MultimediaMeanings::bootstrap(void) {
	SpecialMeanings::declare(PL::Figures::new_figure_SMF,						I"new-figure", 2);
	SpecialMeanings::declare(PL::Sounds::new_sound_SMF,							I"new-sound", 2);
	SpecialMeanings::declare(PL::Files::new_file_SMF,							I"new-file", 2);
}
