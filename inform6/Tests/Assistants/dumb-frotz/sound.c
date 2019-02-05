/*
 * sound.c
 *
 * Sound effect function
 *
 */

#include "frotz.h"

#define EFFECT_PREPARE 1
#define EFFECT_PLAY 2
#define EFFECT_STOP 3
#define EFFECT_FINISH_WITH 4

extern int direct_call (zword);

static zword routine = 0;

static next_sample = 0;
static next_volume = 0;

static bool locked = FALSE;
static bool playing = FALSE;

/*
 * start_sample
 *
 * Call the IO interface to play a sample.
 *
 */

static void start_sample (int number, int volume, int repeats, zword eos)
{

    static zbyte lh_repeats[] = {
	0x00, 0x00, 0x00, 0x01, 0xff,
	0x00, 0x01, 0x01, 0x01, 0x01,
	0xff, 0x01, 0x01, 0xff, 0x00,
	0xff, 0xff, 0xff, 0xff, 0xff
    };

    if (story_id == LURKING_HORROR)
	repeats = lh_repeats[number];

    os_start_sample (number, volume, repeats);

    routine = eos;
    playing = TRUE;

}/* start_sample */

/*
 * start_next_sample
 *
 * Play a sample that has been delayed until the previous sound effect has
 * finished.  This is necessary for two samples in The Lurking Horror that
 * immediately follow other samples.
 *
 */

static void start_next_sample (void)
{

    if (next_sample != 0)
	start_sample (next_sample, next_volume, 0, 0);

    next_sample = 0;
    next_volume = 0;

}/* start_next_sample */

/*
 * end_of_sound
 *
 * Call the Z-code routine which was given as the last parameter of
 * a sound_effect call. This function may be called from a hardware
 * interrupt (which requires extremely careful programming).
 *
 */

void end_of_sound (void)
{

    playing = FALSE;

    if (!locked) {

	if (story_id == LURKING_HORROR)
	    start_next_sample ();

	direct_call (routine);

    }

}/* end_of_sound */

/*
 * z_sound_effect, load / play / stop / discard a sound effect.
 *
 *   	zargs[0] = number of bleep (1 or 2) or sample
 *	zargs[1] = operation to perform (samples only)
 *	zargs[2] = repeats and volume (play sample only)
 *	zargs[3] = end-of-sound routine (play sample only, optional)
 *
 * Note: Volumes range from 1 to 8, volume 255 is the default volume.
 *	 Repeats are stored in the high byte, 255 is infinite loop.
 *
 */

void z_sound_effect (void)
{
    zword number = zargs[0];
    zword effect = zargs[1];
    zword volume = zargs[2];

    if (number >= 3) {

	locked = TRUE;

	if (story_id == LURKING_HORROR && (number == 9 || number == 16)) {

	    if (effect == EFFECT_PLAY) {

		next_sample = number;
		next_volume = volume;

		locked = FALSE;

		if (!playing)
		    start_next_sample ();

	    } else locked = FALSE;

	    return;

	}

	playing = FALSE;

	switch (effect) {

	case EFFECT_PREPARE:
	    os_prepare_sample (number);
	    break;
	case EFFECT_PLAY:
	    start_sample (number, lo (volume), hi (volume), (zargc == 4) ? zargs[3] : 0);
	    break;
	case EFFECT_STOP:
	    os_stop_sample ();
	    break;
	case EFFECT_FINISH_WITH:
	    os_finish_with_sample ();
	    break;

	}

	locked = FALSE;

    } else os_beep (number);

}/* z_sound_effect */
