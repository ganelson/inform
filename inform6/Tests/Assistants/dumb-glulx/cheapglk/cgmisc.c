#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "glk.h"
#include "cheapglk.h"

static unsigned char char_tolower_table[256];
static unsigned char char_toupper_table[256];

gidispatch_rock_t (*gli_register_obj)(void *obj, glui32 objclass) = NULL;
void (*gli_unregister_obj)(void *obj, glui32 objclass, 
    gidispatch_rock_t objrock) = NULL;
gidispatch_rock_t (*gli_register_arr)(void *array, glui32 len, 
    char *typecode) = NULL;
void (*gli_unregister_arr)(void *array, glui32 len, char *typecode, 
    gidispatch_rock_t objrock) = NULL;

void gli_initialize_misc()
{
    int ix;
    int res;
    
    /* Initialize the to-uppercase and to-lowercase tables. These should
        *not* be localized to a platform-native character set! They are
        intended to work on Latin-1 data, and the code below correctly
        sets up the tables for that character set. */
    
    for (ix=0; ix<256; ix++) {
        char_toupper_table[ix] = ix;
        char_tolower_table[ix] = ix;
    }
    for (ix=0; ix<256; ix++) {
        if (ix >= 'A' && ix <= 'Z') {
            res = ix + ('a' - 'A');
        }
        else if (ix >= 0xC0 && ix <= 0xDE && ix != 0xD7) {
            res = ix + 0x20;
        }
        else {
            res = 0;
        }
        if (res) {
            char_tolower_table[ix] = res;
            char_toupper_table[res] = ix;
        }
    }

}

void glk_exit()
{
    exit(0);
}

void glk_set_interrupt_handler(void (*func)(void))
{
    /* This cheap library doesn't understand interrupts. */
}

unsigned char glk_char_to_lower(unsigned char ch)
{
    return char_tolower_table[ch];
}

unsigned char glk_char_to_upper(unsigned char ch)
{
    return char_toupper_table[ch];
}

void glk_select(event_t *event)
{
    window_t *win = gli_window_get();
    
    gli_event_clearevent(event);
    
    fflush(stdout);

    if (!win || !(win->char_request || win->line_request)) {
        /* No input requests. This is legal, but a pity, because the
            correct behavior is to wait forever. Bye bye. */
        while (1) {
            getchar();
        }
    }
    
    if (win->char_request) {
        char buf[256];
        glui32 kval;
        int len;
        
        /* How cheap are we? We don't want to fiddle with line 
            buffering, so we just accept an entire line (terminated by 
            return) and use the first key. Remember that return has to 
            be turned into a special keycode (and so would other keys,
            if we could recognize them.) */
 
        fgets(buf, 255, stdin);
        if (!gli_utf8input) {
            kval = buf[0];
        }
        else {
            int val;
            val = strlen(buf);
            if (val && (buf[val-1] == '\n' || buf[val-1] == '\r'))
                val--;
            len = gli_parse_utf8((unsigned char *)buf, val, &kval, 1);
            if (!len)
                kval = '\n';
        }

        if (kval == '\r' || kval == '\n') {
            kval = keycode_Return;
        }
        else {
            if (!win->char_request_uni && kval >= 0x100)
                kval = '?';
        }
        
        win->char_request = FALSE;
        event->type = evtype_CharInput;
        event->win = win;
        event->val1 = kval;
        
    }
    else {
        /* line_request */
        char buf[256];
        int val;
        glui32 ix;

        fgets(buf, 255, stdin);
        val = strlen(buf);
        if (val && (buf[val-1] == '\n' || buf[val-1] == '\r'))
            val--;

        if (!gli_utf8input) {
            if (val > win->linebuflen)
                val = win->linebuflen;
            if (!win->line_request_uni) {
                memcpy(win->linebuf, buf, val);
            }
            else {
                glui32 *destbuf = (glui32 *)win->linebuf;
                for (ix=0; ix<val; ix++)
                    destbuf[ix] = (glui32)(((unsigned char *)buf)[ix]);
            }
        }
        else {
            glui32 ubuf[256];
            val = gli_parse_utf8((unsigned char *)buf, val, ubuf, 256);
            if (val > win->linebuflen)
                val = win->linebuflen;
            if (!win->line_request_uni) {
                unsigned char *destbuf = (unsigned char *)win->linebuf;
                for (ix=0; ix<val; ix++) {
                    glui32 kval = ubuf[ix];
                    if (kval >= 0x100)
                        kval = '?';
                    destbuf[ix] = kval;
                }
            }
            else {
                /* We ought to perform Unicode Normalization Form C here. */
                glui32 *destbuf = (glui32 *)win->linebuf;
                for (ix=0; ix<val; ix++)
                    destbuf[ix] = ubuf[ix];
            }
        }

        if (!win->line_request_uni) {
            if (win->echostr) {
                gli_stream_echo_line(win->echostr, win->linebuf, val);
            }
        }
        else {
            if (win->echostr) {
                gli_stream_echo_line_uni(win->echostr, win->linebuf, val);
            }
        }

        if (gli_unregister_arr) {
            if (!win->line_request_uni)
                (*gli_unregister_arr)(win->linebuf, win->linebuflen, 
                    "&+#!Cn", win->inarrayrock);
            else
                (*gli_unregister_arr)(win->linebuf, win->linebuflen, 
                    "&+#!Iu", win->inarrayrock);
        }

        win->line_request = FALSE;
        win->line_request_uni = FALSE;
        win->linebuf = NULL;
        event->type = evtype_LineInput;
        event->win = win;
        event->val1 = val;
    }
}

void glk_select_poll(event_t *event)
{
    gli_event_clearevent(event);
    
    /* This only checks for timer events at the moment, and we don't
        support any, so I guess this is a pretty simple function. */
}

void glk_tick()
{
    /* Do nothing. */
}

void glk_request_timer_events(glui32 millisecs)
{
    /* Don't make me laugh. */
}

void gidispatch_set_object_registry(
    gidispatch_rock_t (*regi)(void *obj, glui32 objclass), 
    void (*unregi)(void *obj, glui32 objclass, gidispatch_rock_t objrock))
{
    window_t *win;
    stream_t *str;
    fileref_t *fref;
    
    gli_register_obj = regi;
    gli_unregister_obj = unregi;
    
    if (gli_register_obj) {
        /* It's now necessary to go through all existing objects, and register
            them. */
        for (win = glk_window_iterate(NULL, NULL); 
            win;
            win = glk_window_iterate(win, NULL)) {
            win->disprock = (*gli_register_obj)(win, gidisp_Class_Window);
        }
        for (str = glk_stream_iterate(NULL, NULL); 
            str;
            str = glk_stream_iterate(str, NULL)) {
            str->disprock = (*gli_register_obj)(str, gidisp_Class_Stream);
        }
        for (fref = glk_fileref_iterate(NULL, NULL); 
            fref;
            fref = glk_fileref_iterate(fref, NULL)) {
            fref->disprock = (*gli_register_obj)(fref, gidisp_Class_Fileref);
        }
    }
}

void gidispatch_set_retained_registry(
    gidispatch_rock_t (*regi)(void *array, glui32 len, char *typecode), 
    void (*unregi)(void *array, glui32 len, char *typecode, 
        gidispatch_rock_t objrock))
{
    gli_register_arr = regi;
    gli_unregister_arr = unregi;
}

gidispatch_rock_t gidispatch_get_objrock(void *obj, glui32 objclass)
{
    switch (objclass) {
        case gidisp_Class_Window:
            return ((window_t *)obj)->disprock;
        case gidisp_Class_Stream:
            return ((stream_t *)obj)->disprock;
        case gidisp_Class_Fileref:
            return ((fileref_t *)obj)->disprock;
        default: {
            gidispatch_rock_t dummy;
            dummy.num = 0;
            return dummy;
        }
    }
}

