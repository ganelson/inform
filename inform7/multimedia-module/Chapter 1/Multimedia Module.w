[MultimediaModule::] Multimedia Module.

Setting up the use of this module.

@h Introduction.

@d MULTIMEDIA_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e blorb_figure_MT
@e blorb_sound_MT
@e external_file_MT

=
ALLOCATE_INDIVIDUALLY(blorb_figure)
ALLOCATE_INDIVIDUALLY(blorb_sound)
ALLOCATE_INDIVIDUALLY(external_file)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void MultimediaModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;

@<Register this module's command line switches@> =
	;

@h The end.

=
void MultimediaModule::end(void) {
}
