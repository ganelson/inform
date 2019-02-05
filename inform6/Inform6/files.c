/* ------------------------------------------------------------------------- */
/*   "files" : File handling for source code, the transcript file and the    */
/*             debugging information file; file handling and splicing of     */
/*             the output file.                                              */
/*                                                                           */
/*             Note that filenaming conventions are left to the top-level    */
/*             routines in "inform.c", since they are tied up with ICL       */
/*             settings and are very host OS-dependent.                      */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

int input_file;                         /* Number of source files so far     */

int32 total_chars_read;                 /* Characters read in (from all
                                           source files put together)        */

static int checksum_low_byte,           /* For calculating the Z-machine's   */
           checksum_high_byte;          /* "verify" checksum                 */

static int32 checksum_long;             /* For the Glulx checksum,           */
static int checksum_count;              /* similarly                         */

/* ------------------------------------------------------------------------- */
/*   Most of the information about source files is kept by "lexer.c"; this   */
/*   level is only concerned with file names and handles.                    */
/* ------------------------------------------------------------------------- */

FileId *InputFiles=NULL;                /*  Ids for all the source files     */
static char *filename_storage,          /*  Translated filenames             */
            *filename_storage_p;
static int filename_storage_left;

/* ------------------------------------------------------------------------- */
/*   When emitting debug information, we won't have addresses of routines,   */
/*   sequence points, Glulx objects (addresses of Z-machine objects aren't   */
/*   needed), globals, arrays, or grammar lines.  We only have their         */
/*   offsets from base addresses, which won't be known until the end of      */
/*   compilation.  Since everything else in the relevant debug records is    */
/*   known much earlier and is less convenient to store up, we emit the      */
/*   debug records with a placeholder value and then backpatch these         */
/*   placeholders.  The following structs each store either an offset or a   */
/*   symbol index and the point in the debug information file where the      */
/*   corresponding address should be written once the base address is known. */
/* ------------------------------------------------------------------------- */

#define INITIAL_DEBUG_INFORMATION_BACKPATCH_ALLOCATION 65536

typedef struct value_and_backpatch_position_struct
{   int32 value;
    fpos_t backpatch_position;
} value_and_backpatch_position;

typedef struct debug_backpatch_accumulator_struct
{   int32 number_of_values_to_backpatch;
    int32 number_of_available_backpatches;
    value_and_backpatch_position *values_and_backpatch_positions;
    int32 (* backpatching_function)(int32);
} debug_backpatch_accumulator;

static debug_backpatch_accumulator object_backpatch_accumulator;
static debug_backpatch_accumulator packed_code_backpatch_accumulator;
static debug_backpatch_accumulator code_backpatch_accumulator;
static debug_backpatch_accumulator global_backpatch_accumulator;
static debug_backpatch_accumulator array_backpatch_accumulator;
static debug_backpatch_accumulator grammar_backpatch_accumulator;

/* ------------------------------------------------------------------------- */
/*   File handles and names for temporary files.                             */
/* ------------------------------------------------------------------------- */

FILE *Temp1_fp=NULL, *Temp2_fp=NULL,  *Temp3_fp=NULL;
char Temp1_Name[PATHLEN], Temp2_Name[PATHLEN], Temp3_Name[PATHLEN];

/* ------------------------------------------------------------------------- */
/*   Opening and closing source code files                                   */
/* ------------------------------------------------------------------------- */

#if defined(PC_WIN32) && defined(HAS_REALPATH)
#include <windows.h>
char *realpath(const char *path, char *resolved_path)
{
  return GetFullPathNameA(path,PATHLEN,resolved_path,NULL) != 0 ? resolved_path : 0;
}
#endif

extern void load_sourcefile(char *filename_given, int same_directory_flag)
{
    /*  Meaning: open a new file of Inform source.  (The lexer picks up on
        this by noticing that input_file has increased.)                     */

    char name[PATHLEN];
#ifdef HAS_REALPATH
    char absolute_name[PATHLEN];
#endif
    int x = 0;
    FILE *handle;

    if (input_file == MAX_SOURCE_FILES)
        memoryerror("MAX_SOURCE_FILES", MAX_SOURCE_FILES);

    do
    {   x = translate_in_filename(x, name, filename_given, same_directory_flag,
                (input_file==0)?1:0);
        handle = fopen(name,"r");
    } while ((handle == NULL) && (x != 0));

    if (filename_storage_left <= (int)strlen(name))
        memoryerror("MAX_SOURCE_FILES", MAX_SOURCE_FILES);

    filename_storage_left -= strlen(name)+1;
    strcpy(filename_storage_p, name);
    InputFiles[input_file].filename = filename_storage_p;

    filename_storage_p += strlen(name)+1;

    if (debugfile_switch)
    {   debug_file_printf("<source index=\"%d\">", input_file);
        debug_file_printf("<given-path>");
        debug_file_print_with_entities(filename_given);
        debug_file_printf("</given-path>");
#ifdef HAS_REALPATH
        if (realpath(name, absolute_name))
        {   debug_file_printf("<resolved-path>");
            debug_file_print_with_entities(absolute_name);
            debug_file_printf("</resolved-path>");
        }
#endif
        debug_file_printf("<language>Inform 6</language>");
        debug_file_printf("</source>");
    }

    InputFiles[input_file].handle = handle;
    if (InputFiles[input_file].handle==NULL)
        fatalerror_named("Couldn't open source file", name);

    if (line_trace_level > 0) printf("\nOpening file \"%s\"\n",name);

    input_file++;
}

static void close_sourcefile(int file_number)
{
    if (InputFiles[file_number-1].handle == NULL) return;

    /*  Close this file.  */

    if (ferror(InputFiles[file_number-1].handle))
        fatalerror_named("I/O failure: couldn't read from source file",
            InputFiles[file_number-1].filename);

    fclose(InputFiles[file_number-1].handle);

    InputFiles[file_number-1].handle = NULL;

    if (line_trace_level > 0) printf("\nClosing file\n");
}

extern void close_all_source(void)
{   int i;
    for (i=0; i<input_file; i++) close_sourcefile(i+1);
}

/* ------------------------------------------------------------------------- */
/*   Feeding source code up into the lexical analyser's buffer               */
/*   (see "lexer.c" for its specification)                                   */
/* ------------------------------------------------------------------------- */

extern int file_load_chars(int file_number, char *buffer, int length)
{
    int read_in; FILE *handle;

    if (file_number-1 > input_file)
    {   buffer[0] = 0; return 1; }

    handle = InputFiles[file_number-1].handle;
    if (handle == NULL)
    {   buffer[0] = 0; return 1; }

    read_in = fread(buffer, 1, length, handle);
    total_chars_read += read_in;

    if (read_in == length) return length;

    close_sourcefile(file_number);

    if (file_number == 1)
    {   buffer[read_in]   = 0;
        buffer[read_in+1] = 0;
        buffer[read_in+2] = 0;
        buffer[read_in+3] = 0;
    }
    else
    {   buffer[read_in]   = '\n';
        buffer[read_in+1] = ' ';
        buffer[read_in+2] = ' ';
        buffer[read_in+3] = ' ';
    }

    return(-(read_in+4));
}

/* ------------------------------------------------------------------------- */
/*   Final assembly and output of the story file/module.                     */
/* ------------------------------------------------------------------------- */

FILE *sf_handle;

static void sf_put(int c)
{
    if (!glulx_mode) {

      /*  The checksum is the unsigned sum mod 65536 of the bytes in the
          story file from 0x0040 (first byte after header) to the end.

          The link data does not contribute to the checksum of a module.     */

      checksum_low_byte += c;
      if (checksum_low_byte>=256)
      {   checksum_low_byte-=256;
          if (++checksum_high_byte==256) checksum_high_byte=0;
      }

    }
    else {

      /*  The checksum is the unsigned 32-bit sum of the entire story file,
          considered as a list of 32-bit words, with the checksum field
          being zero. */

      switch (checksum_count) {
      case 0:
        checksum_long += (((int32)(c & 0xFF)) << 24);
        break;
      case 1:
        checksum_long += (((int32)(c & 0xFF)) << 16);
        break;
      case 2:
        checksum_long += (((int32)(c & 0xFF)) << 8);
        break;
      case 3:
        checksum_long += ((int32)(c & 0xFF));
        break;
      }
      
      checksum_count = (checksum_count+1) & 3;
      
    }

    fputc(c, sf_handle);
}

/* Recursive procedure to generate the Glulx compression table. */

static void output_compression(int entnum, int32 *size, int *count)
{
  huffentity_t *ent = &(huff_entities[entnum]);
  int32 val;
  char *cx;

  sf_put(ent->type);
  (*size)++;
  (*count)++;

  switch (ent->type) {
  case 0:
    val = Write_Strings_At + huff_entities[ent->u.branch[0]].addr;
    sf_put((val >> 24) & 0xFF);
    sf_put((val >> 16) & 0xFF);
    sf_put((val >> 8) & 0xFF);
    sf_put((val) & 0xFF);
    (*size) += 4;
    val = Write_Strings_At + huff_entities[ent->u.branch[1]].addr;
    sf_put((val >> 24) & 0xFF);
    sf_put((val >> 16) & 0xFF);
    sf_put((val >> 8) & 0xFF);
    sf_put((val) & 0xFF);
    (*size) += 4;
    output_compression(ent->u.branch[0], size, count);
    output_compression(ent->u.branch[1], size, count);
    break;
  case 1:
    /* no data */
    break;
  case 2:
    sf_put(ent->u.ch);
    (*size) += 1;
    break;
  case 3:
    cx = (char *)abbreviations_at + ent->u.val*MAX_ABBREV_LENGTH;
    while (*cx) {
      sf_put(*cx);
      cx++;
      (*size) += 1;  
    }
    sf_put('\0');
    (*size) += 1;  
    break;
  case 4:
    val = unicode_usage_entries[ent->u.val].ch;
    sf_put((val >> 24) & 0xFF);
    sf_put((val >> 16) & 0xFF);
    sf_put((val >> 8) & 0xFF);
    sf_put((val) & 0xFF);
    (*size) += 4;
    break;
  case 9:
    val = abbreviations_offset + 4 + ent->u.val*4;
    sf_put((val >> 24) & 0xFF);
    sf_put((val >> 16) & 0xFF);
    sf_put((val >> 8) & 0xFF);
    sf_put((val) & 0xFF);
    (*size) += 4;
    break;
  }
}

static void output_file_z(void)
{   FILE *fin=NULL; char new_name[PATHLEN];
    int32 length, blanks=0, size, i, j, offset;
    uint32 code_length, size_before_code, next_cons_check;
    int use_function;

    ASSERT_ZCODE();

    /* At this point, construct_storyfile() has just been called. */

    /*  Enter the length information into the header.                        */

    length=((int32) Write_Strings_At) + static_strings_extent;
    if (module_switch) length += link_data_size +
                                 zcode_backpatch_size +
                                 zmachine_backpatch_size;

    while ((length%length_scale_factor)!=0) { length++; blanks++; }
    length=length/length_scale_factor;
    zmachine_paged_memory[26]=(length & 0xff00)/0x100;
    zmachine_paged_memory[27]=(length & 0xff);

    /*  To assist interpreters running a paged virtual memory system, Inform
        writes files which are padded with zeros to the next multiple of
        0.5K.  This calculates the number of bytes of padding needed:        */

    while (((length_scale_factor*length)+blanks-1)%512 != 511) blanks++;

    translate_out_filename(new_name, Code_Name);

    sf_handle = fopen(new_name,"wb");
    if (sf_handle == NULL)
        fatalerror_named("Couldn't open output file", new_name);

#ifdef MAC_MPW
    /*  Set the type and creator to Andrew Plotkin's MaxZip, a popular
        Z-code interpreter on the Macintosh  */

    if (!module_switch) fsetfileinfo(new_name, 'mxZR', 'ZCOD');
#endif

    /*  (1)  Output the paged memory.                                        */

    for (i=0;i<64;i++)
        fputc(zmachine_paged_memory[i], sf_handle);
    size = 64;
    checksum_low_byte = 0;
    checksum_high_byte = 0;

    for (i=64; i<Write_Code_At; i++)
    {   sf_put(zmachine_paged_memory[i]); size++;
    }

    /*  (2)  Output the compiled code area.                                  */

    if (temporary_files_switch)
    {   fclose(Temp2_fp);
        fin=fopen(Temp2_Name,"rb");
        if (fin==NULL)
            fatalerror("I/O failure: couldn't reopen temporary file 2");
    }

    if (!OMIT_UNUSED_ROUTINES) {
        /* This is the old-fashioned case, which is easy. All of zcode_area
           (zmachine_pc bytes) will be output. next_cons_check will be
           ignored, because j will never reach it. */
        code_length = zmachine_pc;
        use_function = TRUE;
        next_cons_check = code_length+1;
    }
    else {
        /* With dead function stripping, life is more complicated. 
           j will run from 0 to zmachine_pc, but only code_length of
           those should be output. next_cons_check is the location of
           the next function break; that's where we check whether
           we're in a live function or a dead one.
           (This logic is simplified by the assumption that a backpatch
           marker will never straddle a function break.) */
        if (zmachine_pc != df_total_size_before_stripping)
            compiler_error("Code size does not match (zmachine_pc and df_total_size).");
        code_length = df_total_size_after_stripping;
        use_function = TRUE;
        next_cons_check = 0;
        df_prepare_function_iterate();
    }
    size_before_code = size;

    j=0;
    if (!module_switch)
    for (i=0; i<zcode_backpatch_size; i=i+3)
    {   int long_flag = TRUE;
        offset
            = 256*read_byte_from_memory_block(&zcode_backpatch_table, i+1)
              + read_byte_from_memory_block(&zcode_backpatch_table, i+2);
        backpatch_error_flag = FALSE;
        backpatch_marker
            = read_byte_from_memory_block(&zcode_backpatch_table, i);
        if (backpatch_marker >= 0x80) long_flag = FALSE;
        backpatch_marker &= 0x7f;
        offset = offset + (backpatch_marker/32)*0x10000;
        while (offset+0x30000 < j) {
            offset += 0x40000;
            long_flag = !long_flag;
        }
        backpatch_marker &= 0x1f;

        /* All code up until the next backpatch marker gets flushed out
           as-is. (Unless we're in a stripped-out function.) */
        while (j<offset) {
            if (!use_function) {
                while (j<offset && j<next_cons_check) {
                    /* get dummy value */
                    ((temporary_files_switch)?fgetc(fin):
                        read_byte_from_memory_block(&zcode_area, j));
                    j++;
                }
            }
            else {
                while (j<offset && j<next_cons_check) {
                    size++;
                    sf_put((temporary_files_switch)?fgetc(fin):
                        read_byte_from_memory_block(&zcode_area, j));
                    j++;
                }
            }
            if (j == next_cons_check)
                next_cons_check = df_next_function_iterate(&use_function);
        }

        if (long_flag)
        {   int32 v = (temporary_files_switch)?fgetc(fin):
                read_byte_from_memory_block(&zcode_area, j);
            v = 256*v + ((temporary_files_switch)?fgetc(fin):
                read_byte_from_memory_block(&zcode_area, j+1));
            j += 2;
            if (use_function) {
                v = backpatch_value(v);
                sf_put(v/256); sf_put(v%256);
                size += 2;
            }
        }
        else
        {   int32 v = (temporary_files_switch)?fgetc(fin):
                read_byte_from_memory_block(&zcode_area, j);
            j++;
            if (use_function) {
                v = backpatch_value(v);
                sf_put(v);
                size++;
            }
        }

        if (j > next_cons_check)
            compiler_error("Backpatch appears to straddle function break");

        if (backpatch_error_flag)
        {   printf("*** %s  zcode offset=%08lx  backpatch offset=%08lx ***\n",
                (long_flag)?"long":"short", (long int) j, (long int) i);
        }
    }

    /* Flush out the last bit of zcode_area, after the last backpatch
       marker. */
    offset = zmachine_pc;
    while (j<offset) {
        if (!use_function) {
            while (j<offset && j<next_cons_check) {
                /* get dummy value */
                ((temporary_files_switch)?fgetc(fin):
                    read_byte_from_memory_block(&zcode_area, j));
                j++;
            }
        }
        else {
            while (j<offset && j<next_cons_check) {
                size++;
                sf_put((temporary_files_switch)?fgetc(fin):
                    read_byte_from_memory_block(&zcode_area, j));
                j++;
            }
        }
        if (j == next_cons_check)
            next_cons_check = df_next_function_iterate(&use_function);
    }

    if (temporary_files_switch)
    {   if (ferror(fin))
            fatalerror("I/O failure: couldn't read from temporary file 2");
        fclose(fin);
    }

    if (size_before_code + code_length != size)
        compiler_error("Code output length did not match");

    /*  (3)  Output any null bytes (required to reach a packed address)
             before the strings area.                                        */

    while (size<Write_Strings_At) { sf_put(0); size++; }

    /*  (4)  Output the static strings area.                                 */

    if (temporary_files_switch)
    {   fclose(Temp1_fp);
        fin=fopen(Temp1_Name,"rb");
        if (fin==NULL)
            fatalerror("I/O failure: couldn't reopen temporary file 1");
        for (i=0; i<static_strings_extent; i++) sf_put(fgetc(fin));
        if (ferror(fin))
            fatalerror("I/O failure: couldn't read from temporary file 1");
        fclose(fin);
        remove(Temp1_Name); remove(Temp2_Name);
    }
    else
      for (i=0; i<static_strings_extent; i++) {
        sf_put(read_byte_from_memory_block(&static_strings_area,i));
        size++;
      }

    /*  (5)  Output the linking data table (in the case of a module).        */

    if (temporary_files_switch)
    {   if (module_switch)
        {   fclose(Temp3_fp);
            fin=fopen(Temp3_Name,"rb");
            if (fin==NULL)
                fatalerror("I/O failure: couldn't reopen temporary file 3");
            for (j=0; j<link_data_size; j++) sf_put(fgetc(fin));
            if (ferror(fin))
                fatalerror("I/O failure: couldn't read from temporary file 3");
            fclose(fin);
            remove(Temp3_Name);
        }
    }
    else
        if (module_switch)
            for (i=0; i<link_data_size; i++)
                sf_put(read_byte_from_memory_block(&link_data_area,i));

    if (module_switch)
    {   for (i=0; i<zcode_backpatch_size; i++)
            sf_put(read_byte_from_memory_block(&zcode_backpatch_table, i));
        for (i=0; i<zmachine_backpatch_size; i++)
            sf_put(read_byte_from_memory_block(&zmachine_backpatch_table, i));
    }

    /*  (6)  Output null bytes to reach a multiple of 0.5K.                  */

    while (blanks>0) { sf_put(0); blanks--; }

    if (ferror(sf_handle))
        fatalerror("I/O failure: couldn't write to story file");

    fseek(sf_handle, 28, SEEK_SET);
    fputc(checksum_high_byte, sf_handle);
    fputc(checksum_low_byte, sf_handle);

    if (ferror(sf_handle))
      fatalerror("I/O failure: couldn't backtrack on story file for checksum");

    fclose(sf_handle);

    /*  Write a copy of the header into the debugging information file
        (mainly so that it can be used to identify which story file matches
        with which debugging info file).                                     */

    if (debugfile_switch)
    {   debug_file_printf("<story-file-prefix>");
        for (i = 0; i < 63; i += 3)
        {   if (i == 27)
            {   debug_file_print_base_64_triple
                    (zmachine_paged_memory[27],
                     checksum_high_byte,
                     checksum_low_byte);
            } else
            {   debug_file_print_base_64_triple
                    (zmachine_paged_memory[i],
                     zmachine_paged_memory[i + 1],
                     zmachine_paged_memory[i + 2]);
            }
        }
        debug_file_print_base_64_single(zmachine_paged_memory[63]);
        debug_file_printf("</story-file-prefix>");
    }

#ifdef ARCHIMEDES
    {   char settype_command[PATHLEN];
        sprintf(settype_command, "settype %s %s",
            new_name, riscos_file_type());
        system(settype_command);
    }
#endif
#ifdef MAC_FACE
     if (module_switch)
         InformFiletypes (new_name, INF_MODULE_TYPE);
     else
         InformFiletypes (new_name, INF_ZCODE_TYPE);
#endif
}

static void output_file_g(void)
{   FILE *fin=NULL; char new_name[PATHLEN];
    int32 size, i, j, offset;
    int32 VersionNum;
    uint32 code_length, size_before_code, next_cons_check;
    int use_function;
    int first_byte_of_triple, second_byte_of_triple, third_byte_of_triple;

    ASSERT_GLULX();

    /* At this point, construct_storyfile() has just been called. */

    translate_out_filename(new_name, Code_Name);

    sf_handle = fopen(new_name,"wb+");
    if (sf_handle == NULL)
        fatalerror_named("Couldn't open output file", new_name);

#ifdef MAC_MPW
    /*  Set the type and creator to Andrew Plotkin's MaxZip, a popular
        Z-code interpreter on the Macintosh  */

    if (!module_switch) fsetfileinfo(new_name, 'mxZR', 'ZCOD');
#endif

    checksum_long = 0;
    checksum_count = 0;

    /* Determine the version number. */

    VersionNum = 0x00020000;

    /* Increase for various features the game may have used. */
    if (no_unicode_chars != 0 || (uses_unicode_features)) {
      VersionNum = 0x00030000;
    }
    if (uses_memheap_features) {
      VersionNum = 0x00030100;
    }
    if (uses_acceleration_features) {
      VersionNum = 0x00030101;
    }
    if (uses_float_features) {
      VersionNum = 0x00030102;
    }

    /* And check if the user has requested a specific version. */
    if (requested_glulx_version) {
      if (requested_glulx_version < VersionNum) {
        static char error_message_buff[256];
        sprintf(error_message_buff, "Version 0x%08lx requested, but \
game features require version 0x%08lx", (long)requested_glulx_version, (long)VersionNum);
        warning(error_message_buff);
      }
      else {
        VersionNum = requested_glulx_version;
      }
    }

    /*  (1)  Output the header. We use sf_put here, instead of fputc,
        because the header is included in the checksum. */

    /* Magic number */
    sf_put('G');
    sf_put('l');
    sf_put('u');
    sf_put('l');
    /* Version number. */
    sf_put((VersionNum >> 24));
    sf_put((VersionNum >> 16));
    sf_put((VersionNum >> 8));
    sf_put((VersionNum));
    /* RAMSTART */
    sf_put((Write_RAM_At >> 24));
    sf_put((Write_RAM_At >> 16));
    sf_put((Write_RAM_At >> 8));
    sf_put((Write_RAM_At));
    /* EXTSTART, or game file size */
    sf_put((Out_Size >> 24));
    sf_put((Out_Size >> 16));
    sf_put((Out_Size >> 8));
    sf_put((Out_Size));
    /* ENDMEM, which the game file size plus MEMORY_MAP_EXTENSION */
    i = Out_Size + MEMORY_MAP_EXTENSION;
    sf_put((i >> 24));
    sf_put((i >> 16));
    sf_put((i >> 8));
    sf_put((i));
    /* STACKSIZE */
    sf_put((MAX_STACK_SIZE >> 24));
    sf_put((MAX_STACK_SIZE >> 16));
    sf_put((MAX_STACK_SIZE >> 8));
    sf_put((MAX_STACK_SIZE));
    /* Initial function to call. Inform sets things up so that this
       is the start of the executable-code area. */
    sf_put((Write_Code_At >> 24));
    sf_put((Write_Code_At >> 16));
    sf_put((Write_Code_At >> 8));
    sf_put((Write_Code_At));
    /* String-encoding table. */
    sf_put((Write_Strings_At >> 24));
    sf_put((Write_Strings_At >> 16));
    sf_put((Write_Strings_At >> 8));
    sf_put((Write_Strings_At));
    /* Checksum -- zero for the moment. */
    sf_put(0x00);
    sf_put(0x00);
    sf_put(0x00);
    sf_put(0x00);
    
    size = GLULX_HEADER_SIZE;

    /*  (1a) Output the eight-byte memory layout identifier. */

    sf_put('I'); sf_put('n'); sf_put('f'); sf_put('o');
    sf_put(0); sf_put(1); sf_put(0); sf_put(0);

    /*  (1b) Output the rest of the Inform-specific data. */

    /* Inform version number */
    sf_put('0' + ((RELEASE_NUMBER/100)%10));
    sf_put('.');
    sf_put('0' + ((RELEASE_NUMBER/10)%10));
    sf_put('0' + RELEASE_NUMBER%10);
    /* Glulx back-end version number */
    sf_put('0' + ((GLULX_RELEASE_NUMBER/100)%10));
    sf_put('.');
    sf_put('0' + ((GLULX_RELEASE_NUMBER/10)%10));
    sf_put('0' + GLULX_RELEASE_NUMBER%10);
    /* Game release number */
    sf_put((release_number>>8) & 0xFF);
    sf_put(release_number & 0xFF);
    /* Game serial number */
    {
      char serialnum[8];
      write_serial_number(serialnum);
      for (i=0; i<6; i++)
        sf_put(serialnum[i]);
    }
    size += GLULX_STATIC_ROM_SIZE;

    /*  (2)  Output the compiled code area. */

    if (temporary_files_switch)
    {   fclose(Temp2_fp);
        fin=fopen(Temp2_Name,"rb");
        if (fin==NULL)
            fatalerror("I/O failure: couldn't reopen temporary file 2");
    }

    if (!OMIT_UNUSED_ROUTINES) {
        /* This is the old-fashioned case, which is easy. All of zcode_area
           (zmachine_pc bytes) will be output. next_cons_check will be
           ignored, because j will never reach it. */
        code_length = zmachine_pc;
        use_function = TRUE;
        next_cons_check = code_length+1;
    }
    else {
        /* With dead function stripping, life is more complicated. 
           j will run from 0 to zmachine_pc, but only code_length of
           those should be output. next_cons_check is the location of
           the next function break; that's where we check whether
           we're in a live function or a dead one.
           (This logic is simplified by the assumption that a backpatch
           marker will never straddle a function break.) */
        if (zmachine_pc != df_total_size_before_stripping)
            compiler_error("Code size does not match (zmachine_pc and df_total_size).");
        code_length = df_total_size_after_stripping;
        use_function = TRUE;
        next_cons_check = 0;
        df_prepare_function_iterate();
    }
    size_before_code = size;

    j=0;
    if (!module_switch)
      for (i=0; i<zcode_backpatch_size; i=i+6) {
        int data_len;
        int32 v;
        offset = 
          (read_byte_from_memory_block(&zcode_backpatch_table, i+2) << 24)
          | (read_byte_from_memory_block(&zcode_backpatch_table, i+3) << 16)
          | (read_byte_from_memory_block(&zcode_backpatch_table, i+4) << 8)
          | (read_byte_from_memory_block(&zcode_backpatch_table, i+5));
        backpatch_error_flag = FALSE;
        backpatch_marker =
          read_byte_from_memory_block(&zcode_backpatch_table, i);
        data_len =
          read_byte_from_memory_block(&zcode_backpatch_table, i+1);

        /* All code up until the next backpatch marker gets flushed out
           as-is. (Unless we're in a stripped-out function.) */
        while (j<offset) {
            if (!use_function) {
                while (j<offset && j<next_cons_check) {
                    /* get dummy value */
                    ((temporary_files_switch)?fgetc(fin):
                        read_byte_from_memory_block(&zcode_area, j));
                    j++;
                }
            }
            else {
                while (j<offset && j<next_cons_check) {
                    size++;
                    sf_put((temporary_files_switch)?fgetc(fin):
                        read_byte_from_memory_block(&zcode_area, j));
                    j++;
                }
            }
            if (j == next_cons_check)
                next_cons_check = df_next_function_iterate(&use_function);
        }

        /* Write out the converted value of the backpatch marker.
           (Unless we're in a stripped-out function.) */
        switch (data_len) {

        case 4:
          v = ((temporary_files_switch)?fgetc(fin):
            read_byte_from_memory_block(&zcode_area, j));
          v = (v << 8) | ((temporary_files_switch)?fgetc(fin):
            read_byte_from_memory_block(&zcode_area, j+1));
          v = (v << 8) | ((temporary_files_switch)?fgetc(fin):
            read_byte_from_memory_block(&zcode_area, j+2));
          v = (v << 8) | ((temporary_files_switch)?fgetc(fin):
            read_byte_from_memory_block(&zcode_area, j+3));
          j += 4;
          if (!use_function)
              break;
          v = backpatch_value(v);
          sf_put((v >> 24) & 0xFF);
          sf_put((v >> 16) & 0xFF);
          sf_put((v >> 8) & 0xFF);
          sf_put((v) & 0xFF);
          size += 4;
          break;

        case 2:
          v = ((temporary_files_switch)?fgetc(fin):
            read_byte_from_memory_block(&zcode_area, j));
          v = (v << 8) | ((temporary_files_switch)?fgetc(fin):
            read_byte_from_memory_block(&zcode_area, j+1));
          j += 2;
          if (!use_function)
              break;
          v = backpatch_value(v);
          if (v >= 0x10000) {
            printf("*** backpatch value does not fit ***\n");
            backpatch_error_flag = TRUE;
          }
          sf_put((v >> 8) & 0xFF);
          sf_put((v) & 0xFF);
          size += 2;
          break;

        case 1:
          v = ((temporary_files_switch)?fgetc(fin):
            read_byte_from_memory_block(&zcode_area, j));
          j += 1;
          if (!use_function)
              break;
          v = backpatch_value(v);
          if (v >= 0x100) {
            printf("*** backpatch value does not fit ***\n");
            backpatch_error_flag = TRUE;
          }
          sf_put((v) & 0xFF);
          size += 1;
          break;

        default:
          printf("*** unknown backpatch data len = %d ***\n",
            data_len);
          backpatch_error_flag = TRUE;
        }

        if (j > next_cons_check)
          compiler_error("Backpatch appears to straddle function break");

        if (backpatch_error_flag) {
          printf("*** %d bytes  zcode offset=%08lx  backpatch offset=%08lx ***\n",
            data_len, (long int) j, (long int) i);
        }
    }

    /* Flush out the last bit of zcode_area, after the last backpatch
       marker. */
    offset = zmachine_pc;
    while (j<offset) {
        if (!use_function) {
            while (j<offset && j<next_cons_check) {
                /* get dummy value */
                ((temporary_files_switch)?fgetc(fin):
                    read_byte_from_memory_block(&zcode_area, j));
                j++;
            }
        }
        else {
            while (j<offset && j<next_cons_check) {
                size++;
                sf_put((temporary_files_switch)?fgetc(fin):
                    read_byte_from_memory_block(&zcode_area, j));
                j++;
            }
        }
        if (j == next_cons_check)
            next_cons_check = df_next_function_iterate(&use_function);
    }

    if (temporary_files_switch)
    {   if (ferror(fin))
            fatalerror("I/O failure: couldn't read from temporary file 2");
        fclose(fin);
    }

    if (size_before_code + code_length != size)
        compiler_error("Code output length did not match");

    /*  (4)  Output the static strings area.                                 */

    if (temporary_files_switch) {
      fseek(Temp1_fp, 0, SEEK_SET);
    }
    {
      int32 ix, lx;
      int ch, jx, curbyte, bx;
      int depth, checkcount;
      huffbitlist_t *bits;
      int32 origsize;

      origsize = size;

      if (compression_switch) {

        /* The 12-byte table header. */
        lx = compression_table_size;
        sf_put((lx >> 24) & 0xFF);
        sf_put((lx >> 16) & 0xFF);
        sf_put((lx >> 8) & 0xFF);
        sf_put((lx) & 0xFF);
        size += 4;
        sf_put((no_huff_entities >> 24) & 0xFF);
        sf_put((no_huff_entities >> 16) & 0xFF);
        sf_put((no_huff_entities >> 8) & 0xFF);
        sf_put((no_huff_entities) & 0xFF);
        size += 4;
        lx = Write_Strings_At + 12;
        sf_put((lx >> 24) & 0xFF);
        sf_put((lx >> 16) & 0xFF);
        sf_put((lx >> 8) & 0xFF);
        sf_put((lx) & 0xFF);
        size += 4;

        checkcount = 0;
        output_compression(huff_entity_root, &size, &checkcount);
        if (checkcount != no_huff_entities)
          compiler_error("Compression table count mismatch.");
      }

      if (size - origsize != compression_table_size)
        compiler_error("Compression table size mismatch.");

      origsize = size;

      for (lx=0, ix=0; lx<no_strings; lx++) {
        int escapelen=0, escapetype=0;
        int done=FALSE;
        int32 escapeval=0;
        if (compression_switch)
          sf_put(0xE1); /* type byte -- compressed string */
        else
          sf_put(0xE0); /* type byte -- non-compressed string */
        size++;
        jx = 0; 
        curbyte = 0;
        while (!done) {
          if (temporary_files_switch)
            ch = fgetc(Temp1_fp);
          else
            ch = read_byte_from_memory_block(&static_strings_area, ix);
          ix++;
          if (ix > static_strings_extent || ch < 0)
            compiler_error("Read too much not-yet-compressed text.");

          if (escapelen == -1) {
            escapelen = 0;
            if (ch == '@') {
              ch = '@';
            }
            else if (ch == '0') {
              ch = '\0';
            }
            else if (ch == 'A' || ch == 'D' || ch == 'U') {
              escapelen = 4;
              escapetype = ch;
              escapeval = 0;
              continue;
            }
            else {
              compiler_error("Strange @ escape in processed text.");
            }
          }
          else if (escapelen) {
            escapeval = (escapeval << 4) | ((ch-'A') & 0x0F);
            escapelen--;
            if (escapelen == 0) {
              if (escapetype == 'A') {
                ch = huff_abbrev_start+escapeval;
              }
              else if (escapetype == 'D') {
                ch = huff_dynam_start+escapeval;
              }
              else if (escapetype == 'U') {
                ch = huff_unicode_start+escapeval;
              }
              else {
                compiler_error("Strange @ escape in processed text.");
              }
            }
            else 
              continue;
          }
          else {
            if (ch == '@') {
              escapelen = -1;
              continue;
            }
            if (ch == 0) {
              ch = 256;
              done = TRUE;
            }
          }

          if (compression_switch) {
            bits = &(huff_entities[ch].bits);
            depth = huff_entities[ch].depth;
            for (bx=0; bx<depth; bx++) {
              if (bits->b[bx / 8] & (1 << (bx % 8)))
                curbyte |= (1 << jx);
              jx++;
              if (jx == 8) {
                sf_put(curbyte);
                size++;
                curbyte = 0;
                jx = 0;
              }
            }
          }
          else {
            if (ch >= huff_dynam_start) {
              sf_put(' '); sf_put(' '); sf_put(' ');
              size += 3;
            }
            else if (ch >= huff_abbrev_start) {
              /* nothing */
            }
            else {
              /* 256, the string terminator, comes out as zero */
              sf_put(ch & 0xFF);
              size++;
            }
          }
        }
        if (compression_switch && jx) {
          sf_put(curbyte);
          size++;
        }
      }
      
      if (size - origsize != compression_string_size)
        compiler_error("Compression string size mismatch.");

    }
    
    /*  (4.5)  Output any null bytes (required to reach a GPAGESIZE address)
             before RAMSTART. */

    while (size % GPAGESIZE) { sf_put(0); size++; }

    /*  (5)  Output RAM. */

    for (i=0; i<RAM_Size; i++)
    {   sf_put(zmachine_paged_memory[i]); size++;
    }

    if (ferror(sf_handle))
        fatalerror("I/O failure: couldn't write to story file");

    fseek(sf_handle, 32, SEEK_SET);
    fputc((checksum_long >> 24) & 0xFF, sf_handle);
    fputc((checksum_long >> 16) & 0xFF, sf_handle);
    fputc((checksum_long >> 8) & 0xFF, sf_handle);
    fputc((checksum_long) & 0xFF, sf_handle);

    if (ferror(sf_handle))
      fatalerror("I/O failure: couldn't backtrack on story file for checksum");

    /*  Write a copy of the first 64 bytes into the debugging information file
        (mainly so that it can be used to identify which story file matches with
        which debugging info file).  */

    if (debugfile_switch)
    {   fseek(sf_handle, 0L, SEEK_SET);
        debug_file_printf("<story-file-prefix>");
        for (i = 0; i < 63; i += 3)
        {   first_byte_of_triple = fgetc(sf_handle);
            second_byte_of_triple = fgetc(sf_handle);
            third_byte_of_triple = fgetc(sf_handle);
            debug_file_print_base_64_triple
                (first_byte_of_triple,
                 second_byte_of_triple,
                 third_byte_of_triple);
        }
        debug_file_print_base_64_single(fgetc(sf_handle));
        debug_file_printf("</story-file-prefix>");
    }

    fclose(sf_handle);

#ifdef ARCHIMEDES
    {   char settype_command[PATHLEN];
        sprintf(settype_command, "settype %s %s",
            new_name, riscos_file_type());
        system(settype_command);
    }
#endif
#ifdef MAC_FACE
     if (module_switch)
         InformFiletypes (new_name, INF_MODULE_TYPE);
     else
         InformFiletypes (new_name, INF_ZCODE_TYPE);
#endif
}

extern void output_file(void)
{
  if (!glulx_mode)
    output_file_z();
  else
    output_file_g();
}

/* ------------------------------------------------------------------------- */
/*   Output the text transcript file (only called if there is to be one).    */
/* ------------------------------------------------------------------------- */

FILE *transcript_file_handle; int transcript_open;

extern void write_to_transcript_file(char *text)
{   fputs(text, transcript_file_handle);
    fputc('\n', transcript_file_handle);
}

extern void open_transcript_file(char *what_of)
{   char topline_buffer[256];

    transcript_file_handle = fopen(Transcript_Name,"w");
    if (transcript_file_handle==NULL)
        fatalerror_named("Couldn't open transcript file",
        Transcript_Name);

    transcript_open = TRUE;

    sprintf(topline_buffer, "Transcript of the text of \"%s\"\n\
[From %s]\n", what_of, banner_line);
    write_to_transcript_file(topline_buffer);
}

extern void abort_transcript_file(void)
{   if (transcript_switch && transcript_open)
        fclose(transcript_file_handle);
    transcript_open = FALSE;
}

extern void close_transcript_file(void)
{   char botline_buffer[256];
    char sn_buffer[7];

    write_serial_number(sn_buffer);
    sprintf(botline_buffer, "\n[End of transcript: release %d.%s]\n",
        release_number, sn_buffer);
    write_to_transcript_file(botline_buffer);

    if (ferror(transcript_file_handle))
        fatalerror("I/O failure: couldn't write to transcript file");
    fclose(transcript_file_handle);
    transcript_open = FALSE;

#ifdef ARCHIMEDES
    {   char settype_command[PATHLEN];
        sprintf(settype_command, "settype %s text",
            Transcript_Name);
        system(settype_command);
    }
#endif
#ifdef MAC_FACE
    InformFiletypes (Transcript_Name, INF_TEXT_TYPE);
#endif
}

/* ------------------------------------------------------------------------- */
/*   Access to the debugging information file.                               */
/* ------------------------------------------------------------------------- */

static FILE *Debug_fp;                 /* Handle of debugging info file      */

static void open_debug_file(void)
{   Debug_fp=fopen(Debugging_Name,"wb");
    if (Debug_fp==NULL)
       fatalerror_named("Couldn't open debugging information file",
           Debugging_Name);
}

extern void nullify_debug_file_position(maybe_file_position *position) {
    position->valid = 0;
}

static void close_debug_file(void)
{   fclose(Debug_fp);
#ifdef MAC_FACE
    InformFiletypes (Debugging_Name, INF_DEBUG_TYPE);
#endif
}

extern void begin_debug_file(void)
{   open_debug_file();

    debug_file_printf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    debug_file_printf("<inform-story-file version=\"1.0\" ");
    debug_file_printf("content-creator=\"Inform\" ");
    debug_file_printf
        ("content-creator-version=\"%d.%d%d\">",
         (VNUMBER / 100) % 10,
         (VNUMBER / 10) % 10,
         VNUMBER % 10);
}

extern void debug_file_printf(const char*format, ...)
{   va_list argument_pointer;
    va_start(argument_pointer, format);
    vfprintf(Debug_fp, format, argument_pointer);
    va_end(argument_pointer);
    if (ferror(Debug_fp))
    {   fatalerror("I/O failure: can't write to debugging information file");
    }
}

extern void debug_file_print_with_entities(const char*string)
{   int index = 0;
    char character;
    for (character = string[index]; character; character = string[++index])
    {   switch(character)
        {   case '"':
                debug_file_printf("&quot;");
                break;
            case '&':
                debug_file_printf("&amp;");
                break;
            case '\'':
                debug_file_printf("&apos;");
                break;
            case '<':
                debug_file_printf("&lt;");
                break;
            case '>':
                debug_file_printf("&gt;");
                break;
            default:
                debug_file_printf("%c", character);
                break;
        }
    }
}

static char base_64_digits[] =
  { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 
    'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
    't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', '+', '/' };

extern void debug_file_print_base_64_triple
    (uchar first, uchar second, uchar third)
{   debug_file_printf
        ("%c%c%c%c",
         base_64_digits[first >> 2],
         base_64_digits[((first & 3) << 4) | (second >> 4)],
         base_64_digits[((second & 15) << 2) | (third >> 6)],
         base_64_digits[third & 63]);
}

extern void debug_file_print_base_64_pair(uchar first, uchar second)
{   debug_file_printf
        ("%c%c%c=",
         base_64_digits[first >> 2],
         base_64_digits[((first & 3) << 4) | (second >> 4)],
         base_64_digits[(second & 15) << 2]);
}

extern void debug_file_print_base_64_single(uchar first)
{   debug_file_printf
        ("%c%c==",
         base_64_digits[first >> 2],
         base_64_digits[(first & 3) << 4]);
}

static void write_debug_location_internals(debug_location location)
{   debug_file_printf("<file-index>%d</file-index>", location.file_index - 1);
    debug_file_printf
        ("<file-position>%d</file-position>", location.beginning_byte_index);
    debug_file_printf
        ("<line>%d</line>", location.beginning_line_number);
    debug_file_printf
        ("<character>%d</character>", location.beginning_character_number);
    if (location.beginning_byte_index != location.end_byte_index ||
        location.beginning_line_number != location.end_line_number ||
        location.beginning_character_number != location.end_character_number)
    {   debug_file_printf
            ("<end-file-position>%d</end-file-position>",
             location.end_byte_index);
        debug_file_printf
            ("<end-line>%d</end-line>", location.end_line_number);
        debug_file_printf
            ("<end-character>%d</end-character>",
             location.end_character_number);
    }
}

extern void write_debug_location(debug_location location)
{   if (location.file_index && location.file_index != 255)
    {   debug_file_printf("<source-code-location>");
        write_debug_location_internals(location);
        debug_file_printf("</source-code-location>");
    }
}

extern void write_debug_locations(debug_locations locations)
{   if (locations.next)
    {   const debug_locations*current = &locations;
        unsigned int index = 0;
        for (; current; current = current->next, ++index)
        {   debug_file_printf("<source-code-location index=\"%d\">", index);
            write_debug_location_internals(current->location);
            debug_file_printf("</source-code-location>");
        }
    }
    else
    {   write_debug_location(locations.location);
    }
}

extern void write_debug_optional_identifier(int32 symbol_index)
{   if (stypes[symbol_index] != ROUTINE_T)
    {   compiler_error
            ("Attempt to write a replaceable identifier for a non-routine");
    }
    if (replacement_debug_backpatch_positions[symbol_index].valid)
    {   if (fsetpos
                (Debug_fp,
                 &replacement_debug_backpatch_positions[symbol_index].position))
        {   fatalerror("I/O failure: can't seek in debugging information file");
        }
        debug_file_printf
            ("<identifier artificial=\"true\">%s "
                 "(superseded replacement)</identifier>",
             symbs[symbol_index]);
        if (fseek(Debug_fp, 0L, SEEK_END))
        {   fatalerror("I/O failure: can't seek in debugging information file");
        }
    }
    fgetpos
      (Debug_fp, &replacement_debug_backpatch_positions[symbol_index].position);
    replacement_debug_backpatch_positions[symbol_index].valid = TRUE;
    debug_file_printf("<identifier>%s</identifier>", symbs[symbol_index]);
    /* Space for:       artificial="true" (superseded replacement) */
    debug_file_printf("                                           ");
}

extern void write_debug_symbol_backpatch(int32 symbol_index)
{   if (symbol_debug_backpatch_positions[symbol_index].valid) {
        compiler_error("Symbol entry incorrectly reused in debug information "
                       "file backpatching");
    }
    fgetpos(Debug_fp, &symbol_debug_backpatch_positions[symbol_index].position);
    symbol_debug_backpatch_positions[symbol_index].valid = TRUE;
    /* Reserve space for up to 10 digits plus a negative sign. */
    debug_file_printf("*BACKPATCH*");
}

extern void write_debug_symbol_optional_backpatch(int32 symbol_index)
{   if (symbol_debug_backpatch_positions[symbol_index].valid) {
        compiler_error("Symbol entry incorrectly reused in debug information "
                       "file backpatching");
    }
    /* Reserve space for open and close value tags and up to 10 digits plus a
       negative sign, but take the backpatch position just inside the element,
       so that we'll be in the same case as above if the symbol is eventually
       defined. */
    debug_file_printf("<value>");
    fgetpos(Debug_fp, &symbol_debug_backpatch_positions[symbol_index].position);
    symbol_debug_backpatch_positions[symbol_index].valid = TRUE;
    debug_file_printf("*BACKPATCH*</value>");
}

static void write_debug_backpatch
    (debug_backpatch_accumulator *accumulator, int32 value)
{   if (accumulator->number_of_values_to_backpatch ==
        accumulator->number_of_available_backpatches)
    {   my_realloc(&accumulator->values_and_backpatch_positions,
                   sizeof(value_and_backpatch_position) *
                       accumulator->number_of_available_backpatches,
                   2 * sizeof(value_and_backpatch_position) *
                       accumulator->number_of_available_backpatches,
                   "values and debug information backpatch positions");
        accumulator->number_of_available_backpatches *= 2;
    }
    accumulator->values_and_backpatch_positions
        [accumulator->number_of_values_to_backpatch].value = value;
    fgetpos
        (Debug_fp,
         &accumulator->values_and_backpatch_positions
             [accumulator->number_of_values_to_backpatch].backpatch_position);
    ++(accumulator->number_of_values_to_backpatch);
    /* Reserve space for up to 10 digits plus a negative sign. */
    debug_file_printf("*BACKPATCH*");
}

extern void write_debug_object_backpatch(int32 object_number)
{   if (glulx_mode)
    {   write_debug_backpatch(&object_backpatch_accumulator, object_number - 1);
    }
    else
    {   debug_file_printf("%d", object_number);
    }
}

static int32 backpatch_object_address(int32 index)
{   return object_tree_offset + OBJECT_BYTE_LENGTH * index;
}

extern void write_debug_packed_code_backpatch(int32 offset)
{   write_debug_backpatch(&packed_code_backpatch_accumulator, offset);
}

static int32 backpatch_packed_code_address(int32 offset)
{
    if (OMIT_UNUSED_ROUTINES) {
        int stripped;
        offset = df_stripped_offset_for_code_offset(offset, &stripped);
        if (stripped)
            return 0;
    }
    return (code_offset + offset) / scale_factor;
}

extern void write_debug_code_backpatch(int32 offset)
{   write_debug_backpatch(&code_backpatch_accumulator, offset);
}

static int32 backpatch_code_address(int32 offset)
{
    if (OMIT_UNUSED_ROUTINES) {
        int stripped;
        offset = df_stripped_offset_for_code_offset(offset, &stripped);
        if (stripped)
            return 0;
    }
    return code_offset + offset;
}

extern void write_debug_global_backpatch(int32 offset)
{   write_debug_backpatch(&global_backpatch_accumulator, offset);
}

static int32 backpatch_global_address(int32 offset)
{   return variables_offset + WORDSIZE * (offset - MAX_LOCAL_VARIABLES);
}

extern void write_debug_array_backpatch(int32 offset)
{   write_debug_backpatch(&array_backpatch_accumulator, offset);
}

static int32 backpatch_array_address(int32 offset)
{   return (glulx_mode ? arrays_offset : variables_offset) + offset;
}

extern void write_debug_grammar_backpatch(int32 offset)
{   write_debug_backpatch(&grammar_backpatch_accumulator, offset);
}

static int32 backpatch_grammar_address(int32 offset)
{   return grammar_table_offset + offset;
}

extern void begin_writing_debug_sections()
{   debug_file_printf("<story-file-section>");
    debug_file_printf("<type>header</type>");
    debug_file_printf("<address>0</address>");
}

extern void write_debug_section(const char*name, int32 beginning_address)
{   debug_file_printf("<end-address>%d</end-address>", beginning_address);
    debug_file_printf("</story-file-section>");
    debug_file_printf("<story-file-section>");
    debug_file_printf("<type>");
    debug_file_print_with_entities(name);
    debug_file_printf("</type>");
    debug_file_printf("<address>%d</address>", beginning_address);
}

extern void end_writing_debug_sections(int32 end_address)
{   debug_file_printf("<end-address>%d</end-address>", end_address);
    debug_file_printf("</story-file-section>");
}

extern void write_debug_undef(int32 symbol_index)
{   if (!symbol_debug_backpatch_positions[symbol_index].valid)
    {   compiler_error
            ("Attempt to erase debugging information never written or since "
                "erased");
    }
    if (stypes[symbol_index] != CONSTANT_T)
    {   compiler_error
            ("Attempt to erase debugging information for a non-constant "
             "because of an #undef");
    }
    if (fsetpos
         (Debug_fp, &symbol_debug_backpatch_positions[symbol_index].position))
    {   fatalerror("I/O failure: can't seek in debugging information file");
    }
    /* There are 7 characters in ``<value>''. */
    if (fseek(Debug_fp, -7L, SEEK_CUR))
    {   fatalerror("I/O failure: can't seek in debugging information file");
    }
    /* Overwrite:      <value>*BACKPATCH*</value> */
    debug_file_printf("                          ");
    nullify_debug_file_position
        (&symbol_debug_backpatch_positions[symbol_index]);
    if (fseek(Debug_fp, 0L, SEEK_END))
    {   fatalerror("I/O failure: can't seek in debugging information file");
    }
}

static void apply_debug_information_backpatches
    (debug_backpatch_accumulator *accumulator)
{   int32 backpatch_index, backpatch_value;
    for (backpatch_index = accumulator->number_of_values_to_backpatch;
         backpatch_index--;)
    {   if (fsetpos
                (Debug_fp,
                 &accumulator->values_and_backpatch_positions
                     [backpatch_index].backpatch_position))
        {   fatalerror
                ("I/O failure: can't seek in debugging information file");
        }
        backpatch_value =
            (*accumulator->backpatching_function)
                (accumulator->values_and_backpatch_positions
                    [backpatch_index].value);
        debug_file_printf
            ("%11d", /* Space for up to 10 digits plus a negative sign. */
             backpatch_value);
    }
}

static void apply_debug_information_symbol_backpatches()
{   int backpatch_symbol;
    for (backpatch_symbol = no_symbols; backpatch_symbol--;)
    {   if (symbol_debug_backpatch_positions[backpatch_symbol].valid)
        {   if (fsetpos(Debug_fp,
                        &symbol_debug_backpatch_positions
                            [backpatch_symbol].position))
            {   fatalerror
                    ("I/O failure: can't seek in debugging information file");
            }
            debug_file_printf("%11d", svals[backpatch_symbol]);
        }
    }
}

static void write_debug_system_constants()
{   int *system_constant_list =
        glulx_mode ? glulx_system_constant_list : z_system_constant_list;
    int system_constant_index = 0;

    /* Store system constants. */
    for (; system_constant_list[system_constant_index] != -1;
         ++system_constant_index)
    {   int system_constant = system_constant_list[system_constant_index];
        debug_file_printf("<constant>");
        debug_file_printf
            ("<identifier>#%s</identifier>",
             system_constants.keywords[system_constant]);
        debug_file_printf
            ("<value>%d</value>",
             value_of_system_constant(system_constant));
        debug_file_printf("</constant>");
    }
}

extern void end_debug_file()
{   write_debug_system_constants();
    debug_file_printf("</inform-story-file>\n");

    if (glulx_mode)
    {   apply_debug_information_backpatches(&object_backpatch_accumulator);
    } else
    {   apply_debug_information_backpatches(&packed_code_backpatch_accumulator);
    }
    apply_debug_information_backpatches(&code_backpatch_accumulator);
    apply_debug_information_backpatches(&global_backpatch_accumulator);
    apply_debug_information_backpatches(&array_backpatch_accumulator);
    apply_debug_information_backpatches(&grammar_backpatch_accumulator);

    apply_debug_information_symbol_backpatches();

    close_debug_file();
}

/* ------------------------------------------------------------------------- */
/*  Temporary storage files:                                                 */
/*                                                                           */
/*      Temp file 1 is used to hold the static strings area, as compiled     */
/*                2 to hold compiled routines of Z-code                      */
/*                3 to hold the link data table (but only for modules)       */
/*                                                                           */
/*  (Though annoying, this procedure typically saves about 200K of memory,   */
/*  an important point for Amiga and sub-386 PC users of Inform)             */
/* ------------------------------------------------------------------------- */

extern void open_temporary_files(void)
{   translate_temp_filename(1);
    Temp1_fp=fopen(Temp1_Name,"wb");
    if (Temp1_fp==NULL) fatalerror_named("Couldn't open temporary file 1",
        Temp1_Name);
    translate_temp_filename(2);
    Temp2_fp=fopen(Temp2_Name,"wb");
    if (Temp2_fp==NULL) fatalerror_named("Couldn't open temporary file 2",
        Temp2_Name);

    if (!module_switch) return;
    translate_temp_filename(3);
    Temp3_fp=fopen(Temp3_Name,"wb");
    if (Temp3_fp==NULL) fatalerror_named("Couldn't open temporary file 3",
        Temp3_Name);
}

extern void check_temp_files(void)
{
    if (ferror(Temp1_fp))
        fatalerror("I/O failure: couldn't write to temporary file 1");
    if (ferror(Temp2_fp))
        fatalerror("I/O failure: couldn't write to temporary file 2");
    if (module_switch && ferror(Temp3_fp))
        fatalerror("I/O failure: couldn't write to temporary file 3");
}

extern void remove_temp_files(void)
{   if (Temp1_fp != NULL) fclose(Temp1_fp);
    if (Temp2_fp != NULL) fclose(Temp2_fp);
    remove(Temp1_Name); remove(Temp2_Name);
    if (module_switch)
    {   if (Temp3_fp != NULL) fclose(Temp3_fp);
        remove(Temp3_Name);
    }
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_files_vars(void)
{   malloced_bytes = 0;
    checksum_low_byte = 0; /* Z-code */
    checksum_high_byte = 0;
    checksum_long = 0; /* Glulx */
    checksum_count = 0;
    transcript_open = FALSE;
}

extern void files_begin_prepass(void)
{   input_file = 0;
}

extern void files_begin_pass(void)
{   total_chars_read=0;
    if (temporary_files_switch)
        open_temporary_files();
}

static void initialise_accumulator
    (debug_backpatch_accumulator *accumulator,
     int32 (* backpatching_function)(int32))
{   accumulator->number_of_values_to_backpatch = 0;
    accumulator->number_of_available_backpatches =
        INITIAL_DEBUG_INFORMATION_BACKPATCH_ALLOCATION;
    accumulator->values_and_backpatch_positions =
        my_malloc
            (sizeof(value_and_backpatch_position) *
                 accumulator->number_of_available_backpatches,
             "values and debug information backpatch positions");
    accumulator->backpatching_function = backpatching_function;
}

extern void files_allocate_arrays(void)
{   filename_storage = my_malloc(MAX_SOURCE_FILES*64, "filename storage");
    filename_storage_p = filename_storage;
    filename_storage_left = MAX_SOURCE_FILES*64;
    InputFiles = my_malloc(MAX_SOURCE_FILES*sizeof(FileId), 
        "input file storage");
    if (debugfile_switch)
    {   if (glulx_mode)
        {   initialise_accumulator
                (&object_backpatch_accumulator, &backpatch_object_address);
        } else
        {   initialise_accumulator
                (&packed_code_backpatch_accumulator,
                 &backpatch_packed_code_address);
        }
        initialise_accumulator
            (&code_backpatch_accumulator, &backpatch_code_address);
        initialise_accumulator
            (&global_backpatch_accumulator, &backpatch_global_address);
        initialise_accumulator
            (&array_backpatch_accumulator, &backpatch_array_address);
        initialise_accumulator
            (&grammar_backpatch_accumulator, &backpatch_grammar_address);
    }
}

static void tear_down_accumulator(debug_backpatch_accumulator *accumulator)
{   my_free
        (&(accumulator->values_and_backpatch_positions),
         "values and debug information backpatch positions");
}

extern void files_free_arrays(void)
{   my_free(&filename_storage, "filename storage");
    my_free(&InputFiles, "input file storage");
    if (debugfile_switch)
    {   if (!glulx_mode)
        {   tear_down_accumulator(&object_backpatch_accumulator);
        } else
        {   tear_down_accumulator(&packed_code_backpatch_accumulator);
        }
        tear_down_accumulator(&code_backpatch_accumulator);
        tear_down_accumulator(&global_backpatch_accumulator);
        tear_down_accumulator(&array_backpatch_accumulator);
        tear_down_accumulator(&grammar_backpatch_accumulator);
    }
}

/* ========================================================================= */
