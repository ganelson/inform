/* This is a library of C code to support Inform or other Inter programs compiled
   tp ANSI C. It was generated mechanically from the Inter source code, so to
   change it, edit that and not this. */

#ifndef I7_CLIB_H_INCLUDED
#define I7_CLIB_H_INCLUDED 1

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <ctype.h>
#include <stdint.h>
#include <setjmp.h>

typedef int32_t i7val;
typedef uint32_t i7uval;
typedef unsigned char i7byte;

#define I7_ASM_STACK_CAPACITY 128

typedef struct i7state {
	i7byte *memory;
	i7val stack[I7_ASM_STACK_CAPACITY];
	int stack_pointer;
	i7val *i7_object_tree_parent;
	i7val *i7_object_tree_child;
	i7val *i7_object_tree_sibling;
	i7val tmp;
} i7state;
typedef struct i7process {
	i7state state;
	jmp_buf execution_env;
	int termination_code;
} i7process;

i7state i7_new_state(void);
i7process i7_new_process(void);
void i7_run_process(i7process *proc, void (*receiver)(int id, wchar_t c));
void i7_initializer(i7process *proc);
void i7_fatal_exit(i7process *proc);
#define i7_lvalue_SET 1
#define i7_lvalue_PREDEC 2
#define i7_lvalue_POSTDEC 3
#define i7_lvalue_PREINC 4
#define i7_lvalue_POSTINC 5
#define i7_lvalue_SETBIT 6
#define i7_lvalue_CLEARBIT 7
i7byte i7_initial_memory[];
void i7_initialise_state(i7process *proc);
i7byte i7_read_byte(i7process *proc, i7val address);
i7val i7_read_word(i7process *proc, i7val array_address, i7val array_index);
#define I7BYTE_0(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_1(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_2(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_3(V)  (V & 0x000000FF)

void i7_write_byte(i7process *proc, i7val address, i7byte new_val);
i7val i7_write_word(i7process *proc, i7val array_address, i7val array_index, i7val new_val, int way);
void glulx_aloads(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_mcopy(i7process *proc, i7val x, i7val y, i7val z);
void glulx_malloc(i7process *proc, i7val x, i7val y);
void glulx_mfree(i7process *proc, i7val x);
void i7_debug_stack(char *N);
i7val i7_pull(i7process *proc);
void i7_push(i7process *proc, i7val x);
void glulx_accelfunc(i7process *proc, i7val x, i7val y);
void glulx_accelparam(i7process *proc, i7val x, i7val y);
void glulx_copy(i7process *proc, i7val x, i7val *y);
void glulx_gestalt(i7process *proc, i7val x, i7val y, i7val *z);
int glulx_jeq(i7process *proc, i7val x, i7val y);
void glulx_nop(i7process *proc);
int glulx_jleu(i7process *proc, i7val x, i7val y);
int glulx_jnz(i7process *proc, i7val x);
int glulx_jz(i7process *proc, i7val x);
void glulx_quit(i7process *proc);
void glulx_setiosys(i7process *proc, i7val x, i7val y);
void glulx_streamchar(i7process *proc, i7val x);
void glulx_streamnum(i7process *proc, i7val x);
void glulx_streamstr(i7process *proc, i7val x);
void glulx_streamunichar(i7process *proc, i7val x);
void glulx_ushiftr(i7process *proc, i7val x, i7val y, i7val z);
void glulx_aload(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_aloadb(i7process *proc, i7val x, i7val y, i7val *z);
#define serop_KeyIndirect (0x01)
#define serop_ZeroKeyTerminates (0x02)
#define serop_ReturnIndex (0x04)
void glulx_binarysearch(i7process *proc, i7val key, i7val keysize, i7val start, i7val structsize,
	i7val numstructs, i7val keyoffset, i7val options, i7val *s1);
void glulx_shiftl(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_restoreundo(i7process *proc, i7val x);
void glulx_saveundo(i7process *proc, i7val x);
void glulx_restart(i7process *proc);
void glulx_restore(i7process *proc, i7val x, i7val y);
void glulx_save(i7process *proc, i7val x, i7val y);
void glulx_verify(i7process *proc, i7val x);
void glulx_random(i7process *proc, i7val x, i7val *y);
i7val fn_i7_mgl_random(i7process *proc, i7val x);
void glulx_setrandom(i7process *proc, i7val s);
void glulx_add(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_sub(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_neg(i7process *proc, i7val x, i7val *y);
void glulx_mul(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_div(i7process *proc, i7val x, i7val y, i7val *z);
i7val glulx_div_r(i7process *proc, i7val x, i7val y);
void glulx_mod(i7process *proc, i7val x, i7val y, i7val *z);
i7val glulx_mod_r(i7process *proc, i7val x, i7val y);
typedef float gfloat32;
i7val encode_float(gfloat32 val);
gfloat32 decode_float(i7val val);
void glulx_exp(i7process *proc, i7val x, i7val *y);
void glulx_fadd(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_fdiv(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_floor(i7process *proc, i7val x, i7val *y);
void glulx_fmod(i7process *proc, i7val x, i7val y, i7val *z, i7val *w);
void glulx_fmul(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_fsub(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_ftonumn(i7process *proc, i7val x, i7val *y);
void glulx_ftonumz(i7process *proc, i7val x, i7val *y);
void glulx_numtof(i7process *proc, i7val x, i7val *y);
int glulx_jfeq(i7process *proc, i7val x, i7val y, i7val z);
int glulx_jfne(i7process *proc, i7val x, i7val y, i7val z);
int glulx_jfge(i7process *proc, i7val x, i7val y);
int glulx_jflt(i7process *proc, i7val x, i7val y);
int glulx_jisinf(i7process *proc, i7val x);
int glulx_jisnan(i7process *proc, i7val x);
void glulx_log(i7process *proc, i7val x, i7val *y);
void glulx_acos(i7process *proc, i7val x, i7val *y);
void glulx_asin(i7process *proc, i7val x, i7val *y);
void glulx_atan(i7process *proc, i7val x, i7val *y);
void glulx_ceil(i7process *proc, i7val x, i7val *y);
void glulx_cos(i7process *proc, i7val x, i7val *y);
void glulx_pow(i7process *proc, i7val x, i7val y, i7val *z);
void glulx_sin(i7process *proc, i7val x, i7val *y);
void glulx_sqrt(i7process *proc, i7val x, i7val *y);
void glulx_tan(i7process *proc, i7val x, i7val *y);
i7val fn_i7_mgl_metaclass(i7process *proc, i7val id);
int i7_ofclass(i7process *proc, i7val id, i7val cl_id);
i7val fn_i7_mgl_CreatePropertyOffsets(i7process *proc);
void i7_write_prop_value(i7process *proc, i7val owner_id, i7val prop_id, i7val val);
i7val i7_read_prop_value(i7process *proc, i7val owner_id, i7val prop_id);
i7val i7_change_prop_value(i7process *proc, i7val obj, i7val pr, i7val to, int way);
void i7_give(i7process *proc, i7val owner, i7val prop, i7val val);
i7val i7_prop_len(i7val obj, i7val pr);
i7val i7_prop_addr(i7val obj, i7val pr);
int i7_has(i7process *proc, i7val obj, i7val attr);
int i7_provides(i7process *proc, i7val owner_id, i7val prop_id);
int i7_in(i7process *proc, i7val obj1, i7val obj2);
i7val fn_i7_mgl_parent(i7process *proc, i7val id);
i7val fn_i7_mgl_child(i7process *proc, i7val id);
i7val fn_i7_mgl_children(i7process *proc, i7val id);
i7val fn_i7_mgl_sibling(i7process *proc, i7val id);
void i7_move(i7process *proc, i7val obj, i7val to);
i7val i7_call_0(i7process *proc, i7val fn_ref);
i7val i7_call_1(i7process *proc, i7val fn_ref, i7val v);
i7val i7_call_2(i7process *proc, i7val fn_ref, i7val v, i7val v2);
i7val i7_call_3(i7process *proc, i7val fn_ref, i7val v, i7val v2, i7val v3);
i7val i7_call_4(i7process *proc, i7val fn_ref, i7val v, i7val v2, i7val v3, i7val v4);
i7val i7_call_5(i7process *proc, i7val fn_ref, i7val v, i7val v2, i7val v3, i7val v4, i7val v5);
i7val i7_mcall_0(i7process *proc, i7val to, i7val prop);
i7val i7_mcall_1(i7process *proc, i7val to, i7val prop, i7val v);
i7val i7_mcall_2(i7process *proc, i7val to, i7val prop, i7val v, i7val v2);
i7val i7_mcall_3(i7process *proc, i7val to, i7val prop, i7val v, i7val v2, i7val v3);
i7val i7_gen_call(i7process *proc, i7val fn_ref, i7val *args, int argc);
void glulx_call(i7process *proc, i7val fn_ref, i7val varargc, i7val *z);
void i7_print_dword(i7process *proc, i7val at);
#define i7_bold 1
#define i7_roman 2
#define i7_underline 3
#define i7_reverse 4
void i7_style(i7process *proc, int what);
void i7_font(i7process *proc, int what);

#define fileusage_Data (0x00)
#define fileusage_SavedGame (0x01)
#define fileusage_Transcript (0x02)
#define fileusage_InputRecord (0x03)
#define fileusage_TypeMask (0x0f)

#define fileusage_TextMode   (0x100)
#define fileusage_BinaryMode (0x000)

#define filemode_Write (0x01)
#define filemode_Read (0x02)
#define filemode_ReadWrite (0x03)
#define filemode_WriteAppend (0x05)

typedef struct i7_fileref {
	i7val usage;
	i7val name;
	i7val rock;
	char leafname[128];
	FILE *handle;
} i7_fileref;

i7val i7_do_glk_fileref_create_by_name(i7process *proc, i7val usage, i7val name, i7val rock);
int i7_fseek(i7process *proc, int id, int pos, int origin);
int i7_ftell(i7process *proc, int id);
int i7_fopen(i7process *proc, int id, int mode);
void i7_fclose(i7process *proc, int id);
i7val i7_do_glk_fileref_does_file_exist(i7process *proc, i7val id);
void i7_fputc(i7process *proc, int c, int id);
int i7_fgetc(i7process *proc, int id);
typedef struct i7_stream {
	FILE *to_file;
	i7val to_file_id;
	wchar_t *to_memory;
	size_t memory_used;
	size_t memory_capacity;
	i7val previous_id;
	i7val write_here_on_closure;
	size_t write_limit;
	int active;
	int encode_UTF8;
	int char_size;
	int chars_read;
	int read_position;
	int end_position;
	int owned_by_window_id;
} i7_stream;
i7val i7_do_glk_stream_get_current(i7process *proc);
i7_stream i7_new_stream(i7process *proc, FILE *F, int win_id);
void i7_initialise_streams(i7process *proc, void (*receiver)(int id, wchar_t c));
i7val i7_open_stream(i7process *proc, FILE *F, int win_id);
i7val i7_do_glk_stream_open_memory(i7process *proc, i7val buffer, i7val len, i7val fmode, i7val rock);
i7val i7_do_glk_stream_open_memory_uni(i7process *proc, i7val buffer, i7val len, i7val fmode, i7val rock);
i7val i7_do_glk_stream_open_file(i7process *proc, i7val fileref, i7val usage, i7val rock);
#define seekmode_Start (0)
#define seekmode_Current (1)
#define seekmode_End (2)
void i7_do_glk_stream_set_position(i7process *proc, i7val id, i7val pos, i7val seekmode);
i7val i7_do_glk_stream_get_position(i7process *proc, i7val id);
void i7_do_glk_stream_close(i7process *proc, i7val id, i7val result);
typedef struct i7_winref {
	i7val type;
	i7val stream_id;
	i7val rock;
} i7_winref;
i7val i7_do_glk_window_open(i7process *proc, i7val split, i7val method, i7val size, i7val wintype, i7val rock);
i7val i7_stream_of_window(i7process *proc, i7val id);
i7val i7_rock_of_window(i7process *proc, i7val id);
void i7_to_receiver(i7process *proc, i7val rock, wchar_t c);
void i7_do_glk_put_char_stream(i7process *proc, i7val stream_id, i7val x);
i7val i7_do_glk_get_char_stream(i7process *proc, i7val stream_id);
void i7_print_char(i7process *proc, i7val x);
void i7_print_C_string(i7process *proc, char *c_string);
void i7_print_decimal(i7process *proc, i7val x);

#define evtype_None (0)
#define evtype_Timer (1)
#define evtype_CharInput (2)
#define evtype_LineInput (3)
#define evtype_MouseInput (4)
#define evtype_Arrange (5)
#define evtype_Redraw (6)
#define evtype_SoundNotify (7)
#define evtype_Hyperlink (8)
#define evtype_VolumeNotify (9)

typedef struct i7_glk_event {
	i7val type;
	i7val win_id;
	i7val val1;
	i7val val2;
} i7_glk_event;
i7_glk_event *i7_next_event(i7process *proc);
void i7_make_event(i7process *proc, i7_glk_event e);
i7val i7_do_glk_select(i7process *proc, i7val structure);
i7val i7_do_glk_request_line_event(i7process *proc, i7val window_id, i7val buffer, i7val max_len, i7val init_len);
#define i7_glk_exit 0x0001
#define i7_glk_set_interrupt_handler 0x0002
#define i7_glk_tick 0x0003
#define i7_glk_gestalt 0x0004
#define i7_glk_gestalt_ext 0x0005
#define i7_glk_window_iterate 0x0020
#define i7_glk_window_get_rock 0x0021
#define i7_glk_window_get_root 0x0022
#define i7_glk_window_open 0x0023
#define i7_glk_window_close 0x0024
#define i7_glk_window_get_size 0x0025
#define i7_glk_window_set_arrangement 0x0026
#define i7_glk_window_get_arrangement 0x0027
#define i7_glk_window_get_type 0x0028
#define i7_glk_window_get_parent 0x0029
#define i7_glk_window_clear 0x002A
#define i7_glk_window_move_cursor 0x002B
#define i7_glk_window_get_stream 0x002C
#define i7_glk_window_set_echo_stream 0x002D
#define i7_glk_window_get_echo_stream 0x002E
#define i7_glk_set_window 0x002F
#define i7_glk_window_get_sibling 0x0030
#define i7_glk_stream_iterate 0x0040
#define i7_glk_stream_get_rock 0x0041
#define i7_glk_stream_open_file 0x0042
#define i7_glk_stream_open_memory 0x0043
#define i7_glk_stream_close 0x0044
#define i7_glk_stream_set_position 0x0045
#define i7_glk_stream_get_position 0x0046
#define i7_glk_stream_set_current 0x0047
#define i7_glk_stream_get_current 0x0048
#define i7_glk_stream_open_resource 0x0049
#define i7_glk_fileref_create_temp 0x0060
#define i7_glk_fileref_create_by_name 0x0061
#define i7_glk_fileref_create_by_prompt 0x0062
#define i7_glk_fileref_destroy 0x0063
#define i7_glk_fileref_iterate 0x0064
#define i7_glk_fileref_get_rock 0x0065
#define i7_glk_fileref_delete_file 0x0066
#define i7_glk_fileref_does_file_exist 0x0067
#define i7_glk_fileref_create_from_fileref 0x0068
#define i7_glk_put_char 0x0080
#define i7_glk_put_char_stream 0x0081
#define i7_glk_put_string 0x0082
#define i7_glk_put_string_stream 0x0083
#define i7_glk_put_buffer 0x0084
#define i7_glk_put_buffer_stream 0x0085
#define i7_glk_set_style 0x0086
#define i7_glk_set_style_stream 0x0087
#define i7_glk_get_char_stream 0x0090
#define i7_glk_get_line_stream 0x0091
#define i7_glk_get_buffer_stream 0x0092
#define i7_glk_char_to_lower 0x00A0
#define i7_glk_char_to_upper 0x00A1
#define i7_glk_stylehint_set 0x00B0
#define i7_glk_stylehint_clear 0x00B1
#define i7_glk_style_distinguish 0x00B2
#define i7_glk_style_measure 0x00B3
#define i7_glk_select 0x00C0
#define i7_glk_select_poll 0x00C1
#define i7_glk_request_line_event 0x00D0
#define i7_glk_cancel_line_event 0x00D1
#define i7_glk_request_char_event 0x00D2
#define i7_glk_cancel_char_event 0x00D3
#define i7_glk_request_mouse_event 0x00D4
#define i7_glk_cancel_mouse_event 0x00D5
#define i7_glk_request_timer_events 0x00D6
#define i7_glk_image_get_info 0x00E0
#define i7_glk_image_draw 0x00E1
#define i7_glk_image_draw_scaled 0x00E2
#define i7_glk_window_flow_break 0x00E8
#define i7_glk_window_erase_rect 0x00E9
#define i7_glk_window_fill_rect 0x00EA
#define i7_glk_window_set_background_color 0x00EB
#define i7_glk_schannel_iterate 0x00F0
#define i7_glk_schannel_get_rock 0x00F1
#define i7_glk_schannel_create 0x00F2
#define i7_glk_schannel_destroy 0x00F3
#define i7_glk_schannel_create_ext 0x00F4
#define i7_glk_schannel_play_multi 0x00F7
#define i7_glk_schannel_play 0x00F8
#define i7_glk_schannel_play_ext 0x00F9
#define i7_glk_schannel_stop 0x00FA
#define i7_glk_schannel_set_volume 0x00FB
#define i7_glk_sound_load_hint 0x00FC
#define i7_glk_schannel_set_volume_ext 0x00FD
#define i7_glk_schannel_pause 0x00FE
#define i7_glk_schannel_unpause 0x00FF
#define i7_glk_set_hyperlink 0x0100
#define i7_glk_set_hyperlink_stream 0x0101
#define i7_glk_request_hyperlink_event 0x0102
#define i7_glk_cancel_hyperlink_event 0x0103
#define i7_glk_buffer_to_lower_case_uni 0x0120
#define i7_glk_buffer_to_upper_case_uni 0x0121
#define i7_glk_buffer_to_title_case_uni 0x0122
#define i7_glk_buffer_canon_decompose_uni 0x0123
#define i7_glk_buffer_canon_normalize_uni 0x0124
#define i7_glk_put_char_uni 0x0128
#define i7_glk_put_string_uni 0x0129
#define i7_glk_put_buffer_uni 0x012A
#define i7_glk_put_char_stream_uni 0x012B
#define i7_glk_put_string_stream_uni 0x012C
#define i7_glk_put_buffer_stream_uni 0x012D
#define i7_glk_get_char_stream_uni 0x0130
#define i7_glk_get_buffer_stream_uni 0x0131
#define i7_glk_get_line_stream_uni 0x0132
#define i7_glk_stream_open_file_uni 0x0138
#define i7_glk_stream_open_memory_uni 0x0139
#define i7_glk_stream_open_resource_uni 0x013A
#define i7_glk_request_char_event_uni 0x0140
#define i7_glk_request_line_event_uni 0x0141
#define i7_glk_set_echo_line_event 0x0150
#define i7_glk_set_terminators_line_event 0x0151
#define i7_glk_current_time 0x0160
#define i7_glk_current_simple_time 0x0161
#define i7_glk_time_to_date_utc 0x0168
#define i7_glk_time_to_date_local 0x0169
#define i7_glk_simple_time_to_date_utc 0x016A
#define i7_glk_simple_time_to_date_local 0x016B
#define i7_glk_date_to_time_utc 0x016C
#define i7_glk_date_to_time_local 0x016D
#define i7_glk_date_to_simple_time_utc 0x016E
#define i7_glk_date_to_simple_time_local 0x016F
void glulx_glk(i7process *proc, i7val glk_api_selector, i7val varargc, i7val *z);
i7val fn_i7_mgl_IndefArt(i7process *proc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_DefArt(i7process *proc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_CIndefArt(i7process *proc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_CDefArt(i7process *proc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_PrintShortName(i7process *proc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
void i7_print_name(i7process *proc, i7val x);
void i7_print_object(i7process *proc, i7val x);
void i7_print_box(i7process *proc, i7val x);
void i7_read(i7process *proc, i7val x);
#endif
