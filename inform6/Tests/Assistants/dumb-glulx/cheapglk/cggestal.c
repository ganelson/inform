#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "glk.h"
#include "cheapglk.h"

glui32 glk_gestalt(glui32 id, glui32 val)
{
    return glk_gestalt_ext(id, val, NULL, 0);
}

glui32 glk_gestalt_ext(glui32 id, glui32 val, glui32 *arr, 
    glui32 arrlen)
{
    switch (id) {
        
        case gestalt_Version:
            /* This implements Glk spec version 0.7.5. */
            return 0x00000705;
        
        case gestalt_LineInput:
            if (val >= 32 && val < 127)
                return TRUE;
            else
                return FALSE;
                
        case gestalt_CharInput: 
            if (val >= 32 && val < 127)
                return TRUE;
            else if (val == keycode_Return)
                return TRUE;
            else {
                /* If we're doing UTF-8 input, we can input any Unicode
                   character. Except control characters. */
                if (gli_utf8input) {
                    if (val >= 160 && val < 0x200000)
                        return TRUE;
                }
                /* If not, we can't accept anything non-ASCII */
                return FALSE;
            }
        
        case gestalt_CharOutput: 
            if (val >= 32 && val < 127) {
                if (arr && arrlen >= 1)
                    arr[0] = 1;
                return gestalt_CharOutput_ExactPrint;
            }
            else {
                /* cheaply, we don't do any translation of printed
                    characters, so the output is always one character 
                    even if it's wrong. */
                if (arr && arrlen >= 1)
                    arr[0] = 1;
                /* If we're doing UTF-8 output, we can print any Unicode
                   character. Except control characters. */
                if (gli_utf8output) {
                    if (val >= 160 && val < 0x200000)
                        return gestalt_CharOutput_ExactPrint;
                }
                return gestalt_CharOutput_CannotPrint;
            }
            
        case gestalt_MouseInput: 
            return FALSE;
            
        case gestalt_Timer: 
            return FALSE;

        case gestalt_Graphics:
        case gestalt_GraphicsTransparency:
        case gestalt_GraphicsCharInput:
            return FALSE;
            
        case gestalt_DrawImage:
            return FALSE;
            
        case gestalt_Unicode:
#ifdef GLK_MODULE_UNICODE
            return TRUE;
#else
            return FALSE;
#endif /* GLK_MODULE_UNICODE */
            
        case gestalt_UnicodeNorm:
#ifdef GLK_MODULE_UNICODE_NORM
            return TRUE;
#else
            return FALSE;
#endif /* GLK_MODULE_UNICODE_NORM */
            
        case gestalt_Sound:
        case gestalt_SoundVolume:
        case gestalt_SoundNotify: 
        case gestalt_SoundMusic:
            return FALSE;
        case gestalt_Sound2: 
            /* Sound2 implies all the above sound options. But for
               cheapglk, they're all false. */
            return FALSE;

        case gestalt_LineInputEcho:
            return FALSE;

        case gestalt_LineTerminators:
        case gestalt_LineTerminatorKey:
            return FALSE;

        case gestalt_DateTime:
            return TRUE;

        case gestalt_ResourceStream:
            return TRUE;

        default:
            return 0;

    }
}

