/* This is a header file for using a library of C code to support Inter code
   compiled to ANSI C. It was generated mechanically from the Inter source code,
   so to change this material, edit that and not this file. */

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
typedef int32_t i7word_t;
typedef uint32_t unsigned_i7word_t;
typedef unsigned char i7byte_t;
typedef float i7float_t;
#define I7_ASM_STACK_CAPACITY 128
#define I7_TMP_STORAGE_CAPACITY 128

typedef struct i7rngseed_t {
	uint32_t A;
	uint32_t interval;
	uint32_t counter;
} i7rngseed_t;

typedef struct i7state_t {
	i7byte_t *memory;
	i7word_t himem;
	i7word_t stack[I7_ASM_STACK_CAPACITY];
	int stack_pointer;
	i7word_t *object_tree_parent;
	i7word_t *object_tree_child;
	i7word_t *object_tree_sibling;
	i7word_t *variables;
	i7word_t tmp[I7_TMP_STORAGE_CAPACITY];
	i7word_t current_output_stream_ID;
	struct i7rngseed_t seed;
} i7state_t;
typedef struct i7snapshot_t {
	int valid;
	struct i7state_t then;
} i7snapshot_t;
#define I7_MAX_SNAPSHOTS 10
typedef struct i7process_t {
	i7state_t state;
	i7snapshot_t snapshots[I7_MAX_SNAPSHOTS];
	int snapshot_pos;
	jmp_buf execution_env;
	int termination_code;
	void (*receiver)(int id, wchar_t c, char *style);
	int send_count;
	char *(*sender)(int count);
	void (*stylist)(struct i7process_t *proc, i7word_t which, i7word_t what);
	void (*glk_implementation)(struct i7process_t *proc, i7word_t glk_api_selector,
		i7word_t varargc, i7word_t *z);
	struct miniglk_data *miniglk;
	int use_UTF8;
} i7process_t;
i7state_t i7_new_state(void);
i7snapshot_t i7_new_snapshot(void);
i7process_t i7_new_process(void);
char *i7_default_sender(int count);
void i7_default_receiver(int id, wchar_t c, char *style);
int i7_default_main(int argc, char **argv);
void i7_set_process_receiver(i7process_t *proc,
	void (*receiver)(int id, wchar_t c, char *style), int UTF8);
void i7_set_process_sender(i7process_t *proc, char *(*sender)(int count));
void i7_set_process_stylist(i7process_t *proc,
	void (*stylist)(struct i7process_t *proc, i7word_t which, i7word_t what));
void i7_set_process_glk_implementation(i7process_t *proc,
	void (*glk_implementation)(struct i7process_t *proc, i7word_t glk_api_selector,
		i7word_t varargc, i7word_t *z));
int i7_run_process(i7process_t *proc);
void i7_benign_exit(i7process_t *proc);
void i7_fatal_exit(i7process_t *proc);
void i7_initialiser(i7process_t *proc); /* part of the compiled story, not inform_clib.c */
void i7_initialise_object_tree(i7process_t *proc); /* ditto */
#define i7_lvalue_SET 1
#define i7_lvalue_PREDEC 2
#define i7_lvalue_POSTDEC 3
#define i7_lvalue_PREINC 4
#define i7_lvalue_POSTINC 5
#define i7_lvalue_SETBIT 6
#define i7_lvalue_CLEARBIT 7
void i7_initialise_variables(i7process_t *proc);
void *i7_calloc(i7process_t *proc, size_t how_many, size_t of_size);
void i7_initialise_memory_and_stack(i7process_t *proc);
i7byte_t i7_read_byte(i7process_t *proc, i7word_t address);
i7word_t i7_read_sword(i7process_t *proc, i7word_t array_address, i7word_t array_index);
i7word_t i7_read_word(i7process_t *proc, i7word_t array_address, i7word_t array_index);
#define I7BYTE_0(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_1(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_2(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_3(V)  (V & 0x000000FF)

void i7_write_byte(i7process_t *proc, i7word_t address, i7byte_t new_val);
void i7_write_word(i7process_t *proc, i7word_t address, i7word_t array_index,
	i7word_t new_val);
i7byte_t i7_change_byte(i7process_t *proc, i7word_t address, i7byte_t new_val, int way);
i7word_t i7_change_word(i7process_t *proc, i7word_t array_address, i7word_t array_index,
	i7word_t new_val, int way);
void i7_debug_stack(char *N);
i7word_t i7_pull(i7process_t *proc);
void i7_push(i7process_t *proc, i7word_t x);
void i7_copy_state(i7process_t *proc, i7state_t *to, i7state_t *from);
void i7_destroy_state(i7process_t *proc, i7state_t *s);
void i7_destroy_snapshot(i7process_t *proc, i7snapshot_t *unwanted);
void i7_destroy_latest_snapshot(i7process_t *proc);
void i7_save_snapshot(i7process_t *proc);
int i7_has_snapshot(i7process_t *proc);
void i7_restore_snapshot(i7process_t *proc);
void i7_restore_snapshot_from(i7process_t *proc, i7snapshot_t *ss);
void i7_opcode_call(i7process_t *proc, i7word_t fn_ref, i7word_t varargc, i7word_t *z);
void i7_opcode_copy(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_aload(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_aloads(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_aloadb(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_shiftl(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_ushiftr(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
int i7_opcode_jeq(i7process_t *proc, i7word_t x, i7word_t y);
int i7_opcode_jleu(i7process_t *proc, i7word_t x, i7word_t y);
int i7_opcode_jnz(i7process_t *proc, i7word_t x);
int i7_opcode_jz(i7process_t *proc, i7word_t x);
void i7_opcode_nop(i7process_t *proc);
void i7_opcode_quit(i7process_t *proc);
void i7_opcode_verify(i7process_t *proc, i7word_t *z);
void i7_opcode_restoreundo(i7process_t *proc, i7word_t *x);
void i7_opcode_saveundo(i7process_t *proc, i7word_t *x);
void i7_opcode_hasundo(i7process_t *proc, i7word_t *x);
void i7_opcode_discardundo(i7process_t *proc);
void i7_opcode_restart(i7process_t *proc);
void i7_opcode_restore(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_save(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_streamnum(i7process_t *proc, i7word_t x);
void i7_opcode_streamchar(i7process_t *proc, i7word_t x);
void i7_opcode_streamunichar(i7process_t *proc, i7word_t x);
#define serop_KeyIndirect        1
#define serop_ZeroKeyTerminates  2
#define serop_ReturnIndex        4
void i7_opcode_binarysearch(i7process_t *proc, i7word_t key, i7word_t keysize,
	i7word_t start, i7word_t structsize, i7word_t numstructs, i7word_t keyoffset,
	i7word_t options, i7word_t *s1);
void i7_opcode_mcopy(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z);
void i7_opcode_mzero(i7process_t *proc, i7word_t x, i7word_t y);
void i7_opcode_malloc(i7process_t *proc, i7word_t x, i7word_t y);
void i7_opcode_mfree(i7process_t *proc, i7word_t x);
i7rngseed_t i7_initial_rng_seed(void);
void i7_opcode_random(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_setrandom(i7process_t *proc, i7word_t s);
i7word_t i7_random(i7process_t *proc, i7word_t x);
void i7_opcode_setiosys(i7process_t *proc, i7word_t x, i7word_t y);
void i7_opcode_gestalt(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_add(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_sub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_neg(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_mul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_div(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_mod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);

i7word_t i7_div(i7process_t *proc, i7word_t x, i7word_t y);
i7word_t i7_mod(i7process_t *proc, i7word_t x, i7word_t y);
void i7_opcode_fadd(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fsub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fmul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fdiv(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_fmod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z, i7word_t *w);
void i7_opcode_floor(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_ceil(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_ftonumn(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_ftonumz(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_numtof(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_exp(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_log(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_pow(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void i7_opcode_sqrt(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_sin(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_cos(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_tan(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_asin(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_acos(i7process_t *proc, i7word_t x, i7word_t *y);
void i7_opcode_atan(i7process_t *proc, i7word_t x, i7word_t *y);
int i7_opcode_jfeq(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z);
int i7_opcode_jfne(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z);
int i7_opcode_jfge(i7process_t *proc, i7word_t x, i7word_t y);
int i7_opcode_jflt(i7process_t *proc, i7word_t x, i7word_t y);
int i7_opcode_jisinf(i7process_t *proc, i7word_t x);
int i7_opcode_jisnan(i7process_t *proc, i7word_t x);
char *i7_text_to_C_string(i7word_t str);
void i7_print_dword(i7process_t *proc, i7word_t at);
i7word_t i7_metaclass(i7process_t *proc, i7word_t id);
int i7_ofclass(i7process_t *proc, i7word_t id, i7word_t cl_id);
void i7_empty_object_tree(i7process_t *proc);
#define I7_MAX_PROPERTY_IDS 1000
typedef struct i7_property_set {
	i7word_t address[I7_MAX_PROPERTY_IDS];
	i7word_t len[I7_MAX_PROPERTY_IDS];
} i7_property_set;
extern i7_property_set i7_properties[];

i7word_t i7_prop_addr(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr);
i7word_t i7_prop_len(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr);
int i7_provides(i7process_t *proc, i7word_t owner_id, i7word_t prop_id);
void i7_move(i7process_t *proc, i7word_t obj, i7word_t to);
i7word_t i7_parent(i7process_t *proc, i7word_t id);
i7word_t i7_child(i7process_t *proc, i7word_t id);
i7word_t i7_children(i7process_t *proc, i7word_t id);
i7word_t i7_sibling(i7process_t *proc, i7word_t id);
int i7_in(i7process_t *proc, i7word_t obj1, i7word_t obj2);
i7word_t i7_read_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t pr_array);
void i7_write_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id, i7word_t val);
i7word_t i7_change_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t prop_id,
	i7word_t val, int way);
int i7_provides_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p);
i7word_t i7_read_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr);
void i7_write_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val);
void i7_change_gprop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val, i7word_t form);
int i7_provides_gprop_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
i7word_t i7_read_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
void i7_write_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val, i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
void i7_change_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t val, i7word_t form, i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE);
i7word_t i7_gen_call(i7process_t *proc, i7word_t id, i7word_t *args, int argc);
i7word_t i7_call_0(i7process_t *proc, i7word_t id);
i7word_t i7_call_1(i7process_t *proc, i7word_t id, i7word_t v);
i7word_t i7_call_2(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2);
i7word_t i7_call_3(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2, i7word_t v3);
i7word_t i7_call_4(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2, i7word_t v3,
	i7word_t v4);
i7word_t i7_call_5(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2, i7word_t v3,
	i7word_t v4, i7word_t v5);
i7word_t i7_mcall_0(i7process_t *proc, i7word_t to, i7word_t prop);
i7word_t i7_mcall_1(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v);
i7word_t i7_mcall_2(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2);
i7word_t i7_mcall_3(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2, i7word_t v3);
void i7_print_C_string(i7process_t *proc, char *c_string);
void i7_print_decimal(i7process_t *proc, i7word_t x);
void i7_print_object(i7process_t *proc, i7word_t x);
void i7_print_box(i7process_t *proc, i7word_t x);
void i7_print_char(i7process_t *proc, i7word_t x);
void i7_styling(i7process_t *proc, i7word_t which, i7word_t what);
void i7_default_stylist(i7process_t *proc, i7word_t which, i7word_t what);
void i7_opcode_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc,
	i7word_t *z);
void i7_default_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc,
	i7word_t *z);
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
#define I7_BODY_TEXT_ID          201
#define I7_STATUS_TEXT_ID        202
#define I7_BOX_TEXT_ID           203
#define i7_fileusage_Data        0x00
#define i7_fileusage_SavedGame   0x01
#define i7_fileusage_Transcript  0x02
#define i7_fileusage_InputRecord 0x03
#define i7_fileusage_TypeMask    0x0f
#define i7_fileusage_TextMode    0x100
#define i7_fileusage_BinaryMode  0x000

#define i7_filemode_Write        0x01
#define i7_filemode_Read         0x02
#define i7_filemode_ReadWrite    0x03
#define i7_filemode_WriteAppend  0x05
#define i7_seekmode_Start (0)
#define i7_seekmode_Current (1)
#define i7_seekmode_End (2)
#define i7_evtype_None           0
#define i7_evtype_Timer          1
#define i7_evtype_CharInput      2
#define i7_evtype_LineInput      3
#define i7_evtype_MouseInput     4
#define i7_evtype_Arrange        5
#define i7_evtype_Redraw         6
#define i7_evtype_SoundNotify    7
#define i7_evtype_Hyperlink      8
#define i7_evtype_VolumeNotify   9
#define i7_gestalt_Version						0
#define i7_gestalt_CharInput					1
#define i7_gestalt_LineInput					2
#define i7_gestalt_CharOutput					3
  #define i7_gestalt_CharOutput_ApproxPrint		1
  #define i7_gestalt_CharOutput_CannotPrint		0
  #define i7_gestalt_CharOutput_ExactPrint		2
#define i7_gestalt_MouseInput					4
#define i7_gestalt_Timer						5
#define i7_gestalt_Graphics						6
#define i7_gestalt_DrawImage					7
#define i7_gestalt_Sound						8
#define i7_gestalt_SoundVolume					9
#define i7_gestalt_SoundNotify					10
#define i7_gestalt_Hyperlinks					11
#define i7_gestalt_HyperlinkInput				12
#define i7_gestalt_SoundMusic					13
#define i7_gestalt_GraphicsTransparency			14
#define i7_gestalt_Unicode						15
#define i7_gestalt_UnicodeNorm					16
#define i7_gestalt_LineInputEcho				17
#define i7_gestalt_LineTerminators				18
#define i7_gestalt_LineTerminatorKey			19
#define i7_gestalt_DateTime						20
#define i7_gestalt_Sound2						21
#define i7_gestalt_ResourceStream				22
#define i7_gestalt_GraphicsCharInput			23

i7word_t i7_miniglk_gestalt(i7process_t *proc, i7word_t g);
i7word_t i7_miniglk_char_to_lower(i7process_t *proc, i7word_t c);
i7word_t i7_miniglk_char_to_upper(i7process_t *proc, i7word_t c);
#define I7_MINIGLK_LEAFNAME_LENGTH 128

typedef struct i7_mg_file_t {
	i7word_t usage;
	i7word_t name;
	i7word_t rock;
	char leafname[I7_MINIGLK_LEAFNAME_LENGTH + 32];
	FILE *handle;
} i7_mg_file_t;

typedef struct i7_mg_stream_t {
	FILE *to_file;
	i7word_t to_file_id;
	wchar_t *to_memory;
	size_t memory_used;
	size_t memory_capacity;
	i7word_t previous_id;
	i7word_t write_here_on_closure;
	size_t write_limit;
	int active;
	int encode_UTF8;
	int char_size;
	int chars_read;
	int read_position;
	int end_position;
	int owned_by_window_id;
	int fixed_pitch;
	char style[128];
	char composite_style[300];
} i7_mg_stream_t;

typedef struct i7_mg_window_t {
	i7word_t type;
	i7word_t stream_id;
	i7word_t rock;
} i7_mg_window_t;

typedef struct i7_mg_event_t {
	i7word_t type;
	i7word_t win_id;
	i7word_t val1;
	i7word_t val2;
} i7_mg_event_t;

#define I7_MINIGLK_MAX_FILES 128
#define I7_MINIGLK_MAX_STREAMS 128
#define I7_MINIGLK_MAX_WINDOWS 128
#define I7_MINIGLK_RING_BUFFER_SIZE 32

typedef struct miniglk_data {
	/* streams */
	i7_mg_stream_t memory_streams[I7_MINIGLK_MAX_STREAMS];
	i7word_t stdout_stream_id, stderr_stream_id;
	/* files */
	i7_mg_file_t files[I7_MINIGLK_MAX_FILES + 32];
	int no_files;
	/* windows */
	i7_mg_window_t windows[I7_MINIGLK_MAX_WINDOWS];
	int no_windows;
	/* events */
	i7_mg_event_t events_ring_buffer[I7_MINIGLK_RING_BUFFER_SIZE];
	int rb_back, rb_front;
	int no_line_events;
} miniglk_data;

void i7_initialise_miniglk_data(i7process_t *proc);
void i7_initialise_miniglk(i7process_t *proc);
int i7_mg_new_file(i7process_t *proc);
int i7_mg_fseek(i7process_t *proc, int id, int pos, int origin);
int i7_mg_ftell(i7process_t *proc, int id);
int i7_mg_fopen(i7process_t *proc, int id, int mode);
void i7_mg_fclose(i7process_t *proc, int id);
void i7_mg_fputc(i7process_t *proc, int c, int id);
int i7_mg_fgetc(i7process_t *proc, int id);
i7word_t i7_miniglk_fileref_create_by_name(i7process_t *proc, i7word_t usage,
	i7word_t name, i7word_t rock);
i7word_t i7_miniglk_fileref_does_file_exist(i7process_t *proc, i7word_t id);
i7_mg_stream_t i7_mg_new_stream(i7process_t *proc, FILE *F, int win_id);
i7word_t i7_mg_open_stream(i7process_t *proc, FILE *F, int win_id);
i7word_t i7_miniglk_stream_open_memory(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock);
i7word_t i7_miniglk_stream_open_memory_uni(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock);
i7word_t i7_miniglk_stream_open_file(i7process_t *proc, i7word_t fileref,
	i7word_t usage, i7word_t rock);
void i7_miniglk_stream_set_position(i7process_t *proc, i7word_t id, i7word_t pos,
	i7word_t seekmode);
i7word_t i7_miniglk_stream_get_position(i7process_t *proc, i7word_t id);
i7word_t i7_miniglk_stream_get_current(i7process_t *proc);
void i7_miniglk_stream_set_current(i7process_t *proc, i7word_t id);
void i7_mg_put_to_stream(i7process_t *proc, i7word_t rock, wchar_t c);
void i7_miniglk_put_char_stream(i7process_t *proc, i7word_t stream_id, i7word_t x);
i7word_t i7_miniglk_get_char_stream(i7process_t *proc, i7word_t stream_id);
void i7_miniglk_stream_close(i7process_t *proc, i7word_t id, i7word_t result);
i7word_t i7_miniglk_window_open(i7process_t *proc, i7word_t split, i7word_t method,
	i7word_t size, i7word_t wintype, i7word_t rock);
i7word_t i7_miniglk_set_window(i7process_t *proc, i7word_t id);
i7word_t i7_mg_get_window_rock(i7process_t *proc, i7word_t id);
i7word_t i7_miniglk_window_get_size(i7process_t *proc, i7word_t id, i7word_t a1,
	i7word_t a2);
void i7_mg_add_event_to_buffer(i7process_t *proc, i7_mg_event_t e);
i7_mg_event_t *i7_mg_get_event_from_buffer(i7process_t *proc);
i7word_t i7_miniglk_select(i7process_t *proc, i7word_t structure);
i7word_t i7_miniglk_request_line_event(i7process_t *proc, i7word_t window_id,
	i7word_t buffer, i7word_t max_len, i7word_t init_len);
i7word_t i7_miniglk_request_line_event_uni(i7process_t *proc, i7word_t window_id,
	i7word_t buffer, i7word_t max_len, i7word_t init_len);
i7word_t i7_encode_float(i7float_t val);
i7float_t i7_decode_float(i7word_t val);
i7word_t i7_read_variable(i7process_t *proc, i7word_t var_id);
void i7_write_variable(i7process_t *proc, i7word_t var_id, i7word_t val);
char *i7_read_string(i7process_t *proc, i7word_t S);
void i7_write_string(i7process_t *proc, i7word_t S, char *A);
i7word_t *i7_read_list(i7process_t *proc, i7word_t S, int *N);
void i7_write_list(i7process_t *proc, i7word_t S, i7word_t *A, int L);
i7word_t i7_try(i7process_t *proc, i7word_t action_id, i7word_t n, i7word_t s);
#endif
