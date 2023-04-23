#include "glk.h"

/* Declarations for autosave support in unixautosave.c.
   These will not be defined or used unless glkstart.h contains GLKUNIX_AUTOSAVE_FEATURES.
*/

extern char *pref_autosavedir;
extern char *pref_autosavename;
extern int pref_autosave_skiparrange;

extern void glkunix_set_autosave_signature(unsigned char *buf, glui32 len);
extern void glkunix_do_autosave(glui32 selector, glui32 arg0, glui32 arg1, glui32 arg2);
extern int glkunix_do_autorestore(void);

