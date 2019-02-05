/*
 * fastmem.c
 *
 * Memory related functions (fast version without virtual memory)
 *
 */

#include <stdio.h>
#include <string.h>
#include "frotz.h"

#ifdef __MSDOS__

#include <alloc.h>

#define malloc(size)	farmalloc (size)
#define realloc(size,p)	farrealloc (size,p)
#define free(size)	farfree (size)
#define memcpy(d,s,n)	_fmemcpy (d,s,n)

#else

#include <stdlib.h>

#ifndef SEEK_SET
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#endif

#define far

#endif

extern void seed_random (int);
extern void restart_screen (void);
extern void refresh_text_style (void);
extern void call (zword, int, zword *, int);
extern void split_window (zword);
extern void script_open (void);
extern void script_close (void);

extern void (*op0_opcodes[]) (void);
extern void (*op1_opcodes[]) (void);
extern void (*op2_opcodes[]) (void);
extern void (*var_opcodes[]) (void);

char save_name[MAX_FILE_NAME + 1] = DEFAULT_SAVE_NAME;
char auxilary_name[MAX_FILE_NAME + 1] = DEFAULT_AUXILARY_NAME;

zbyte far *zmp = NULL;
zbyte far *pcp = NULL;

static FILE *story_fp = NULL;

static zbyte far *undo[MAX_UNDO_SLOTS];

static undo_slots = 0;
static undo_count = 0;
static undo_valid = 0;

/*
 * get_header_extension
 *
 * Read a value from the header extension (former mouse table).
 *
 */

zword get_header_extension (int entry)
{
    zword addr;
    zword val;

    if (h_extension_table == 0 || entry > hx_table_size)
	return 0;

    addr = h_extension_table + 2 * entry;
    LOW_WORD (addr, val)

    return val;

}/* get_header_extension */

/*
 * set_header_extension
 *
 * Set an entry in the header extension (former mouse table).
 *
 */

void set_header_extension (int entry, zword val)
{
    zword addr;

    if (h_extension_table == 0 || entry > hx_table_size)
	return;

    addr = h_extension_table + 2 * entry;
    SET_WORD (addr, val)

}/* set_header_extension */

/*
 * restart_header
 *
 * Set all header fields which hold information about the interpreter.
 *
 */

void restart_header (void)
{
    zword screen_x_size;
    zword screen_y_size;
    zbyte font_x_size;
    zbyte font_y_size;

    int i;

    SET_BYTE (H_CONFIG, h_config)
    SET_WORD (H_FLAGS, h_flags)

    if (h_version >= V4) {
	SET_BYTE (H_INTERPRETER_NUMBER, h_interpreter_number)
	SET_BYTE (H_INTERPRETER_VERSION, h_interpreter_version)
	SET_BYTE (H_SCREEN_ROWS, h_screen_rows)
	SET_BYTE (H_SCREEN_COLS, h_screen_cols)
    }

    /* It's less trouble to use font size 1x1 for V5 games, especially
       because of a bug in the unreleased German version of "Zork 1" */

    if (h_version != V6) {
	screen_x_size = (zword) h_screen_cols;
	screen_y_size = (zword) h_screen_rows;
	font_x_size = 1;
	font_y_size = 1;
    } else {
	screen_x_size = h_screen_width;
	screen_y_size = h_screen_height;
	font_x_size = h_font_width;
	font_y_size = h_font_height;
    }

    if (h_version >= V5) {
	SET_WORD (H_SCREEN_WIDTH, screen_x_size)
	SET_WORD (H_SCREEN_HEIGHT, screen_y_size)
	SET_BYTE (H_FONT_HEIGHT, font_y_size)
	SET_BYTE (H_FONT_WIDTH, font_x_size)
	SET_BYTE (H_DEFAULT_BACKGROUND, h_default_background)
	SET_BYTE (H_DEFAULT_FOREGROUND, h_default_foreground)
    }

    if (h_version == V6)
	for (i = 0; i < 8; i++)
	    storeb ((zword) (H_USER_NAME + i), h_user_name[i]);

    SET_BYTE (H_STANDARD_HIGH, h_standard_high)
    SET_BYTE (H_STANDARD_LOW, h_standard_low)

}/* restart_header */

/*
 * init_memory
 *
 * Allocate memory and load the story file.
 *
 */

void init_memory (void)
{
    long size;
    zword addr;
    unsigned n;
    int i, j;

    static struct {
	enum story story_id;
	zword release;
	zbyte serial[6];
    } records[] = {
	{       SHERLOCK,  21, "871214" },
	{       SHERLOCK,  26, "880127" },
	{    BEYOND_ZORK,  47, "870915" },
	{    BEYOND_ZORK,  49, "870917" },
	{    BEYOND_ZORK,  51, "870923" },
	{    BEYOND_ZORK,  57, "871221" },
	{      ZORK_ZERO, 296, "881019" },
	{      ZORK_ZERO, 366, "890323" },
	{      ZORK_ZERO, 383, "890602" },
	{      ZORK_ZERO, 393, "890714" },
	{         SHOGUN, 292, "890314" },
	{         SHOGUN, 295, "890321" },
	{         SHOGUN, 311, "890510" },
	{         SHOGUN, 322, "890706" },
	{         ARTHUR,  54, "890606" },
	{         ARTHUR,  63, "890622" },
	{         ARTHUR,  74, "890714" },
	{        JOURNEY,  26, "890316" },
	{        JOURNEY,  30, "890322" },
	{        JOURNEY,  77, "890616" },
	{        JOURNEY,  83, "890706" },
	{ LURKING_HORROR, 203, "870506" },
	{ LURKING_HORROR, 219, "870912" },
	{ LURKING_HORROR, 221, "870918" },
	{        UNKNOWN,   0, "------" }
    };

    /* Open story file */

    if ((story_fp = fopen (story_name, "rb")) == NULL)
	os_fatal ("Cannot open story file");

    /* Allocate memory for story header */

    if ((zmp = (zbyte far *) malloc (64)) == NULL)
	os_fatal ("Out of memory");

    /* Load header into memory */

    if (fread (zmp, 1, 64, story_fp) != 64)
	os_fatal ("Story file read error");

    /* Copy header fields to global variables */

    LOW_BYTE (H_VERSION, h_version)

    if (h_version < V1 || h_version > V8)
	os_fatal ("Unknown Z-code version");

    LOW_BYTE (H_CONFIG, h_config)

    if (h_version == V3 && (h_config & CONFIG_BYTE_SWAPPED))
	os_fatal ("Byte swapped story file");

    LOW_WORD (H_RELEASE, h_release)
    LOW_WORD (H_RESIDENT_SIZE, h_resident_size)
    LOW_WORD (H_START_PC, h_start_pc)
    LOW_WORD (H_DICTIONARY, h_dictionary)
    LOW_WORD (H_OBJECTS, h_objects)
    LOW_WORD (H_GLOBALS, h_globals)
    LOW_WORD (H_DYNAMIC_SIZE, h_dynamic_size)
    LOW_WORD (H_FLAGS, h_flags)

    for (i = 0, addr = H_SERIAL; i < 6; i++, addr++)
	LOW_BYTE (addr, h_serial[i])

    /* Auto-detect buggy story files that need special fixes */

    for (i = 0; records[i].story_id != UNKNOWN; i++) {

	if (h_release == records[i].release) {

	    for (j = 0; j < 6; j++)
		if (h_serial[j] != records[i].serial[j])
		    goto no_match;

	    story_id = records[i].story_id;

	}

    no_match: ;

    }

    LOW_WORD (H_ABBREVIATIONS, h_abbreviations)
    LOW_WORD (H_FILE_SIZE, h_file_size)

    /* Calculate story file size in bytes */

    if (h_file_size != 0) {

	story_size = (long) 2 * h_file_size;

	if (h_version >= V4)
	    story_size *= 2;
	if (h_version >= V6)
	    story_size *= 2;

    } else {		/* some old games lack the file size entry */

	fseek (story_fp, 0, SEEK_END);
	story_size = ftell (story_fp);
	fseek (story_fp, 64, SEEK_SET);

    }

    LOW_WORD (H_CHECKSUM, h_checksum)
    LOW_WORD (H_ALPHABET, h_alphabet)
    LOW_WORD (H_FUNCTIONS_OFFSET, h_functions_offset)
    LOW_WORD (H_STRINGS_OFFSET, h_strings_offset)
    LOW_WORD (H_TERMINATING_KEYS, h_terminating_keys)
    LOW_WORD (H_EXTENSION_TABLE, h_extension_table)

    /* Zork Zero Macintosh doesn't have the graphics flag set */

    if (story_id == ZORK_ZERO && h_release == 296)
	h_flags |= GRAPHICS_FLAG;

    /* Adjust opcode tables */

    if (h_version <= V4) {
	op0_opcodes[0x09] = z_pop;
	op1_opcodes[0x0f] = z_not;
    } else {
	op0_opcodes[0x09] = z_catch;
	op1_opcodes[0x0f] = z_call_n;
    }

    /* Allocate memory for story data */

    if ((zmp = (zbyte far *) realloc (zmp, story_size)) == NULL)
	os_fatal ("Out of memory");

    /* Load story file in chunks of 32KB */

    n = 0x8000;

    for (size = 64; size < story_size; size += n) {

	if (story_size - size < 0x8000)
	    n = (unsigned) (story_size - size);

	SET_PC (size)

	if (fread (pcp, 1, n, story_fp) != n)
	    os_fatal ("Story file read error");

    }

    /* Read header extension table */

    hx_table_size = get_header_extension (HX_TABLE_SIZE);
    hx_unicode_table = get_header_extension (HX_UNICODE_TABLE);

}/* init_memory */

/*
 * init_undo
 *
 * Allocate memory for multiple undo. It is important not to occupy
 * all the memory available, since the IO interface may need memory
 * during the game, e.g. for loading sounds or pictures.
 *
 */

void init_undo (void)
{
    void far *reserved;

    if (reserve_mem != 0)
	if ((reserved = malloc (reserve_mem)) == NULL)
	    return;

    while (undo_slots < option_undo_slots && undo_slots < MAX_UNDO_SLOTS) {

	void far *mem = malloc ((long) sizeof (stack) + h_dynamic_size);

	if (mem == NULL)
	    break;

	undo[undo_slots++] = mem;

    }

    if (reserve_mem != 0)
	free (reserved);

}/* init_undo */

/*
 * reset_memory
 *
 * Close the story file and deallocate memory.
 *
 */

void reset_memory (void)
{

    fclose (story_fp);

    while (undo_slots--)
	free (undo[undo_slots]);

    free (zmp);

}/* reset_memory */

/*
 * storeb
 *
 * Write a byte value to the dynamic Z-machine memory.
 *
 */

void storeb (zword addr, zbyte value)
{

    if (addr >= h_dynamic_size)
	runtime_error ("Store out of dynamic memory");

    if (addr == H_FLAGS + 1) {	/* flags register is modified */

	h_flags &= ~(SCRIPTING_FLAG | FIXED_FONT_FLAG);
	h_flags |= value & (SCRIPTING_FLAG | FIXED_FONT_FLAG);

	if (value & SCRIPTING_FLAG) {
	    if (!ostream_script)
		script_open ();
	} else {
	    if (ostream_script)
		script_close ();
	}

	refresh_text_style ();

    }

    SET_BYTE (addr, value)

}/* storeb */

/*
 * storew
 *
 * Write a word value to the dynamic Z-machine memory.
 *
 */

void storew (zword addr, zword value)
{

    storeb ((zword) (addr + 0), hi (value));
    storeb ((zword) (addr + 1), lo (value));

}/* storew */

/*
 * z_restart, re-load dynamic area, clear the stack and set the PC.
 *
 * 	no zargs used
 *
 */

void z_restart (void)
{
    static bool first_restart = TRUE;

    flush_buffer ();

    os_restart_game (RESTART_BEGIN);

    seed_random (0);

    if (!first_restart) {

	fseek (story_fp, 0, SEEK_SET);

	if (fread (zmp, 1, h_dynamic_size, story_fp) != h_dynamic_size)
	    os_fatal ("Story file read error");

    }

    restart_header ();
    restart_screen ();

    sp = fp = stack + STACK_SIZE;

    if (h_version != V6) {

	long pc = (long) h_start_pc;
	SET_PC (pc)

    } else call (h_start_pc, 0, NULL, 0);

    if (first_restart && option_profiling) {
      long pc;
      GET_PC (pc)
      prof_enter(pc);
    }
    first_restart = FALSE;
    os_restart_game (RESTART_END);

}/* z_restart */

/*
 * get_default_name
 *
 * Read a default file name from the memory of the Z-machine and
 * copy it to a string.
 *
 */

static void get_default_name (char *default_name, zword addr)
{

    if (addr != 0) {

	zbyte len;
	int i;

	LOW_BYTE (addr, len)
	addr++;

	for (i = 0; i < len; i++) {

	    zbyte c;

	    LOW_BYTE (addr, c)
	    addr++;

	    if (c >= 'A' && c <= 'Z')
		c += 'a' - 'A';

	    default_name[i] = c;

	}

	default_name[i] = 0;

	if (strchr (default_name, '.') == NULL)
	    strcpy (default_name + i, ".AUX");

    } else strcpy (default_name, auxilary_name);

}/* get_default_name */

/*
 * z_restore, restore [a part of] a Z-machine state from disk
 *
 *	zargs[0] = address of area to restore (optional)
 *	zargs[1] = number of bytes to restore
 *	zargs[2] = address of suggested file name
 *
 */

void z_restore (void)
{
    char new_name[MAX_FILE_NAME + 1];
    char default_name[MAX_FILE_NAME + 1];
    FILE *gfp;

    zword success = 0;

    if (zargc != 0) {

	/* Get the file name */

	get_default_name (default_name, (zargc >= 3) ? zargs[2] : 0);

	if (os_read_file_name (new_name, default_name, FILE_LOAD_AUX) == 0)
	    goto finished;

	strcpy (auxilary_name, default_name);

	/* Open auxilary file */

	if ((gfp = fopen (new_name, "rb")) == NULL)
	    goto finished;

	/* Load auxilary file */

	success = fread (zmp + zargs[0], 1, zargs[1], gfp);

	/* Close auxilary file */

	fclose (gfp);

    } else {

	long pc;
	zword release;
	zword addr;
	int i;

	/* Get the file name */

	if (os_read_file_name (new_name, save_name, FILE_RESTORE) == 0)
	    goto finished;

	strcpy (save_name, new_name);

	/* Open game file */

	if ((gfp = fopen (new_name, "rb")) == NULL)
	    goto finished;

	/* Load game file */

	release = (unsigned) fgetc (gfp) << 8;
	release |= fgetc (gfp);

	(void) fgetc (gfp);
	(void) fgetc (gfp);

	/* Check the release number */

	if (release == h_release) {

	    pc = (long) fgetc (gfp) << 16;
	    pc |= (unsigned) fgetc (gfp) << 8;
	    pc |= fgetc (gfp);

	    SET_PC (pc)

	    sp = stack + (fgetc (gfp) << 8);
	    sp += fgetc (gfp);
	    fp = stack + (fgetc (gfp) << 8);
	    fp += fgetc (gfp);

	    for (i = (int) (sp - stack); i < STACK_SIZE; i++) {
		stack[i] = (unsigned) fgetc (gfp) << 8;
		stack[i] |= fgetc (gfp);
	    }

	    fseek (story_fp, 0, SEEK_SET);

	    for (addr = 0; addr < h_dynamic_size; addr++) {
		int skip = fgetc (gfp);
		for (i = 0; i < skip; i++)
		    zmp[addr++] = fgetc (story_fp);
		zmp[addr] = fgetc (gfp);
		(void) fgetc (story_fp);
	    }

	    /* Check for errors */

	    if (ferror (gfp) || ferror (story_fp) || addr != h_dynamic_size)
		os_fatal ("Error reading save file");

	    /* Reset upper window (V3 only) */

	    if (h_version == V3)
		split_window (0);

	    /* Initialise story header */

	    restart_header ();

	    /* Success */

	    success = 2;

	} else print_string ("Invalid save file\n");

	/* Close game file */

	fclose (gfp);

    }

finished:

    if (h_version <= V3)
	branch (success);
    else
	store (success);

}/* z_restore */

/*
 * restore_undo
 *
 * This function does the dirty work for z_restore_undo.
 *
 */

int restore_undo (void)
{

    if (undo_slots == 0)	/* undo feature unavailable */

	return -1;

    else if (undo_valid == 0)	/* no saved game state */

	return 0;

    else {			/* undo possible */

	long pc;

	if (undo_count == 0)
	    undo_count = undo_slots;

	memcpy (stack, undo[undo_count - 1], sizeof (stack));
	memcpy (zmp, undo[undo_count - 1] + sizeof (stack), h_dynamic_size);

	pc = ((long) stack[0] << 16) | stack[1];
	sp = stack + stack[2];
	fp = stack + stack[3];

	SET_PC (pc)

	restart_header ();

	undo_count--;
	undo_valid--;

	return 2;

    }

}/* restore_undo */

/*
 * z_restore_undo, restore a Z-machine state from memory.
 *
 *	no zargs used
 *
 */

void z_restore_undo (void)
{

    store ((zword) restore_undo ());

}/* restore_undo */

/*
 * z_save, save [a part of] the Z-machine state to disk.
 *
 *	zargs[0] = address of memory area to save (optional)
 *	zargs[1] = number of bytes to save
 *	zargs[2] = address of suggested file name
 *
 */

void z_save (void)
{
    char new_name[MAX_FILE_NAME + 1];
    char default_name[MAX_FILE_NAME + 1];
    FILE *gfp;

    zword success = 0;

    if (zargc != 0) {

	/* Get the file name */

	get_default_name (default_name, (zargc >= 3) ? zargs[2] : 0);

	if (os_read_file_name (new_name, default_name, FILE_SAVE_AUX) == 0)
	    goto finished;

	strcpy (auxilary_name, default_name);

	/* Open auxilary file */

	if ((gfp = fopen (new_name, "wb")) == NULL)
	    goto finished;

	/* Write auxilary file */

	success = fwrite (zmp + zargs[0], zargs[1], 1, gfp);

	/* Close auxilary file */

	fclose (gfp);

    } else {

	long pc;
	zword addr;
	zword nsp, nfp;
	int skip;
	int i;

	/* Get the file name */

	if (os_read_file_name (new_name, save_name, FILE_SAVE) == 0)
	    goto finished;

	strcpy (save_name, new_name);

	/* Open game file */

	if ((gfp = fopen (new_name, "wb")) == NULL)
	    goto finished;

	/* Write game file */

	fputc ((int) hi (h_release), gfp);
	fputc ((int) lo (h_release), gfp);
	fputc ((int) hi (h_checksum), gfp);
	fputc ((int) lo (h_checksum), gfp);

	GET_PC (pc)

	fputc ((int) (pc >> 16) & 0xff, gfp);
	fputc ((int) (pc >> 8) & 0xff, gfp);
	fputc ((int) (pc) & 0xff, gfp);

	nsp = (int) (sp - stack);
	nfp = (int) (fp - stack);

	fputc ((int) hi (nsp), gfp);
	fputc ((int) lo (nsp), gfp);
	fputc ((int) hi (nfp), gfp);
	fputc ((int) lo (nfp), gfp);

	for (i = nsp; i < STACK_SIZE; i++) {
	    fputc ((int) hi (stack[i]), gfp);
	    fputc ((int) lo (stack[i]), gfp);
	}

	fseek (story_fp, 0, SEEK_SET);

	for (addr = 0, skip = 0; addr < h_dynamic_size; addr++)
	    if (zmp[addr] != fgetc (story_fp) || skip == 255 || addr + 1 == h_dynamic_size) {
		fputc (skip, gfp);
		fputc (zmp[addr], gfp);
		skip = 0;
	    } else skip++;

	/* Close game file and check for errors */

	if (fclose (gfp) == EOF || ferror (story_fp)) {
	    print_string ("Error writing save file\n");
	    goto finished;
	}

	/* Success */

	success = 1;

    }

finished:

    if (h_version <= V3)
	branch (success);
    else
	store (success);

}/* z_save */

/*
 * save_undo
 *
 * This function does the dirty work for z_save_undo.
 *
 */

int save_undo (void)
{
    long pc;

    if (undo_slots == 0)	/* undo feature unavailable */

	return -1;

    else {			/* save undo possible */

	if (undo_count == undo_slots)
	    undo_count = 0;

	GET_PC (pc)

	stack[0] = (zword) (pc >> 16);
	stack[1] = (zword) (pc & 0xffff);
	stack[2] = (zword) (sp - stack);
	stack[3] = (zword) (fp - stack);

	memcpy (undo[undo_count], stack, sizeof (stack));
	memcpy (undo[undo_count] + sizeof (stack), zmp, h_dynamic_size);

	if (++undo_count == undo_slots)
	    undo_count = 0;
	if (++undo_valid > undo_slots)
	    undo_valid = undo_slots;

	return 1;

    }

}/* save_undo */

/*
 * z_save_undo, save the current Z-machine state for a future undo.
 *
 *	no zargs used
 *
 */

void z_save_undo (void)
{

    store ((zword) save_undo ());

}/* z_save_undo */

/*
 * z_verify, check the story file integrity.
 *
 *	no zargs used
 *
 */

void z_verify (void)
{
    zword checksum = 0;
    long i;

    /* Sum all bytes in story file except header bytes */

    fseek (story_fp, 64, SEEK_SET);

    for (i = 64; i < story_size; i++)
	checksum += fgetc (story_fp);

    /* Branch if the checksums are equal */

    branch (checksum == h_checksum);

}/* z_verify */
