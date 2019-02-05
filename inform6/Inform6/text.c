/* ------------------------------------------------------------------------- */
/*   "text" : Text translation, the abbreviations optimiser, the dictionary  */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

uchar *low_strings, *low_strings_top;  /* Start and next free byte in the low
                                          strings pool */

int32 static_strings_extent;           /* Number of bytes of static strings
                                          made so far */
memory_block static_strings_area;      /* Used if (!temporary_files_switch) to
                                          hold the static strings area so far */

static uchar *strings_holding_area;    /* Area holding translated strings
                                          until they are moved into either
                                          a temporary file, or the
                                          static_strings_area below */

char *all_text, *all_text_top;         /* Start and next byte free in (large)
                                          text buffer holding the entire text
                                          of the game, when it is being
                                          recorded                           */
int put_strings_in_low_memory,         /* When TRUE, put static strings in
                                          the low strings pool at 0x100 rather
                                          than in the static strings area    */
    is_abbreviation,                   /* When TRUE, the string being trans
                                          is itself an abbreviation string
                                          so can't make use of abbreviations */
    abbrevs_lookup_table_made,         /* The abbreviations lookup table is
                                          constructed when the first non-
                                          abbreviation string is translated:
                                          this flag is TRUE after that       */
    abbrevs_lookup[256];               /* Once this has been constructed,
                                          abbrevs_lookup[n] = the smallest
                                          number of any abbreviation beginning
                                          with ASCII character n, or -1
                                          if none of the abbreviations do    */
int no_abbreviations;                  /* No of abbreviations defined so far */
uchar *abbreviations_at;                 /* Memory to hold the text of any
                                          abbreviation strings declared      */
/* ------------------------------------------------------------------------- */
/*   Glulx string compression storage                                        */
/* ------------------------------------------------------------------------- */

int no_strings;                        /* No of strings in static strings
                                          area.                              */
int no_dynamic_strings;                /* No. of @.. string escapes used
                                          (actually, the highest value used
                                          plus one)                          */
int no_unicode_chars;                  /* Number of distinct Unicode chars
                                          used. (Beyond 0xFF.)               */

static int MAX_CHARACTER_SET;          /* Number of possible entities */
huffentity_t *huff_entities;           /* The list of entities (characters,
                                          abbreviations, @.. escapes, and 
                                          the terminator)                    */
static huffentity_t **hufflist;        /* Copy of the list, for sorting      */

int no_huff_entities;                  /* The number of entities in the list */
int huff_unicode_start;                /* Position in the list where Unicode
                                          chars begin.                       */
int huff_abbrev_start;                 /* Position in the list where string
                                          abbreviations begin.               */
int huff_dynam_start;                  /* Position in the list where @..
                                          entities begin.                    */
int huff_entity_root;                  /* The position in the list of the root
                                          entry (when considering the table
                                          as a tree).                        */

int done_compression;                  /* Has the game text been compressed? */
int32 compression_table_size;          /* Length of the Huffman table, in 
                                          bytes                              */
int32 compression_string_size;         /* Length of the compressed string
                                          data, in bytes                     */
int32 *compressed_offsets;             /* The beginning of every string in
                                          the game, relative to the beginning
                                          of the Huffman table. (So entry 0
                                          is equal to compression_table_size)*/

#define UNICODE_HASH_BUCKETS (64)
unicode_usage_t *unicode_usage_entries;
static unicode_usage_t *unicode_usage_hash[UNICODE_HASH_BUCKETS];

static int unicode_entity_index(int32 unicode);

/* ------------------------------------------------------------------------- */
/*   Abbreviation arrays                                                     */
/* ------------------------------------------------------------------------- */

int *abbrev_values;
int *abbrev_quality;
int *abbrev_freqs;

/* ------------------------------------------------------------------------- */

int32 total_chars_trans,               /* Number of ASCII chars of text in   */
      total_bytes_trans,               /* Number of bytes of Z-code text out */
      zchars_trans_in_last_string;     /* Number of Z-chars in last string:
                                          needed only for abbrev efficiency
                                          calculation in "directs.c"         */
static int32 total_zchars_trans,       /* Number of Z-chars of text out
                                          (only used to calculate the above) */
      no_chars_transcribed;            /* Number of ASCII chars written to
                                          the text transcription area (used
                                          for the -r and -u switches)        */

static int zchars_out_buffer[3],       /* During text translation, a buffer of
                                          3 Z-chars at a time: when it's full
                                          these are written as a 2-byte word */
           zob_index;                  /* Index (0 to 2) into it             */

static unsigned char *text_out_pc;     /* The "program counter" during text
                                          translation: the next address to
                                          write Z-coded text output to       */

static unsigned char *text_out_limit;  /* The upper limit of text_out_pc
                                          during text translation            */

static int text_out_overflow;          /* During text translation, becomes
                                          true if text_out_pc tries to pass
                                          text_out_limit                     */

/* ------------------------------------------------------------------------- */
/*   For variables/arrays used by the dictionary manager, see below          */
/* ------------------------------------------------------------------------- */

/* ------------------------------------------------------------------------- */
/*   Prepare the abbreviations lookup table (used to speed up abbreviation   */
/*   detection in text translation).  We first bubble-sort the abbrevs into  */
/*   alphabetical order (this is necessary for the detection algorithm to    */
/*   to work).  Since the table is only prepared once, and for a table       */
/*   of size at most 96, there's no point using an efficient sort algorithm. */
/* ------------------------------------------------------------------------- */

static void make_abbrevs_lookup(void)
{   int bubble_sort, j, k, l; char p[MAX_ABBREV_LENGTH]; char *p1, *p2;
    do
    {   bubble_sort = FALSE;
        for (j=0; j<no_abbreviations; j++)
            for (k=j+1; k<no_abbreviations; k++)
            {   p1=(char *)abbreviations_at+j*MAX_ABBREV_LENGTH;
                p2=(char *)abbreviations_at+k*MAX_ABBREV_LENGTH;
                if (strcmp(p1,p2)<0)
                {   strcpy(p,p1); strcpy(p1,p2); strcpy(p2,p);
                    l=abbrev_values[j]; abbrev_values[j]=abbrev_values[k];
                    abbrev_values[k]=l;
                    l=abbrev_quality[j]; abbrev_quality[j]=abbrev_quality[k];
                    abbrev_quality[k]=l;
                    bubble_sort = TRUE;
                }
            }
    } while (bubble_sort);

    for (j=no_abbreviations-1; j>=0; j--)
    {   p1=(char *)abbreviations_at+j*MAX_ABBREV_LENGTH;
        abbrevs_lookup[(uchar)p1[0]]=j;
        abbrev_freqs[j]=0;
    }
    abbrevs_lookup_table_made = TRUE;
}

/* ------------------------------------------------------------------------- */
/*   Search the abbreviations lookup table (a routine which must be fast).   */
/*   The source text to compare is text[i], text[i+1], ... and this routine  */
/*   is only called if text[i] is indeed the first character of at least one */
/*   abbreviation, "from" begin the least index into the abbreviations table */
/*   of an abbreviation for which text[i] is the first character.  Recall    */
/*   that the abbrevs table is in alphabetical order.                        */
/*                                                                           */
/*   The return value is -1 if there is no match.  If there is a match, the  */
/*   text to be abbreviated out is over-written by a string of null chars    */
/*   with "ASCII" value 1, and the abbreviation number is returned.          */
/*                                                                           */
/*   In Glulx, we *do not* do this overwriting with 1's.                     */
/* ------------------------------------------------------------------------- */

static int try_abbreviations_from(unsigned char *text, int i, int from)
{   int j, k; uchar *p, c;
    c=text[i];
    for (j=from, p=(uchar *)abbreviations_at+from*MAX_ABBREV_LENGTH;
         (j<no_abbreviations)&&(c==p[0]); j++, p+=MAX_ABBREV_LENGTH)
    {   if (text[i+1]==p[1])
        {   for (k=2; p[k]!=0; k++)
                if (text[i+k]!=p[k]) goto NotMatched;
            if (!glulx_mode) {
                for (k=0; p[k]!=0; k++) text[i+k]=1;
            }
            abbrev_freqs[j]++;
            return(j);
            NotMatched: ;
        }
    }
    return(-1);
}

extern void make_abbreviation(char *text)
{
    strcpy((char *)abbreviations_at
            + no_abbreviations*MAX_ABBREV_LENGTH, text);

    is_abbreviation = TRUE;
    abbrev_values[no_abbreviations] = compile_string(text, TRUE, TRUE);
    is_abbreviation = FALSE;

    /*   The quality is the number of Z-chars saved by using this            */
    /*   abbreviation: note that it takes 2 Z-chars to print it.             */

    abbrev_quality[no_abbreviations++] = zchars_trans_in_last_string - 2;
}

/* ------------------------------------------------------------------------- */
/*   The front end routine for text translation                              */
/* ------------------------------------------------------------------------- */

extern int32 compile_string(char *b, int in_low_memory, int is_abbrev)
{   int i, j; uchar *c;

    is_abbreviation = is_abbrev;

    /* Put into the low memory pool (at 0x100 in the Z-machine) of strings   */
    /* which may be wanted as possible entries in the abbreviations table    */

    if (!glulx_mode && in_low_memory)
    {   j=subtract_pointers(low_strings_top,low_strings);
        low_strings_top=translate_text(low_strings_top, low_strings+MAX_LOW_STRINGS, b);
        if (!low_strings_top)
            memoryerror("MAX_LOW_STRINGS", MAX_LOW_STRINGS);
        is_abbreviation = FALSE;
        return(0x21+(j/2));
    }

    if (glulx_mode && done_compression)
        compiler_error("Tried to add a string after compression was done.");

    c = translate_text(strings_holding_area, strings_holding_area+MAX_STATIC_STRINGS, b);
    if (!c)
        memoryerror("MAX_STATIC_STRINGS",MAX_STATIC_STRINGS);

    i = subtract_pointers(c, strings_holding_area);

    /* Insert null bytes as needed to ensure that the next static string */
    /* also occurs at an address expressible as a packed address         */

    if (!glulx_mode) {
        int textalign;
        if (oddeven_packing_switch) 
            textalign = scale_factor*2;
        else
            textalign = scale_factor;
        while ((i%textalign)!=0)
        {
            if (i+2 > MAX_STATIC_STRINGS)
                memoryerror("MAX_STATIC_STRINGS",MAX_STATIC_STRINGS);
            i+=2; *c++ = 0; *c++ = 0;
        }
    }

    j = static_strings_extent;

    if (temporary_files_switch)
        for (c=strings_holding_area; c<strings_holding_area+i;
             c++, static_strings_extent++)
            fputc(*c,Temp1_fp);
    else
        for (c=strings_holding_area; c<strings_holding_area+i;
             c++, static_strings_extent++)
            write_byte_to_memory_block(&static_strings_area,
                static_strings_extent, *c);

    is_abbreviation = FALSE;

    if (!glulx_mode) {
        return(j/scale_factor);
    }
    else {
        /* The marker value is a one-based string number. (We reserve zero
           to mean "not a string at all". */
        return (++no_strings);
    }
}

/* ------------------------------------------------------------------------- */
/*   Output a single Z-character into the buffer, and flush it if full       */
/* ------------------------------------------------------------------------- */

static void write_z_char_z(int i)
{   uint32 j;
    ASSERT_ZCODE();
    total_zchars_trans++;
    zchars_out_buffer[zob_index++]=(i%32);
    if (zob_index!=3) return;
    zob_index=0;
    j= zchars_out_buffer[0]*0x0400 + zchars_out_buffer[1]*0x0020
       + zchars_out_buffer[2];
    if (text_out_pc+2 > text_out_limit) {
        text_out_overflow = TRUE;
        return;
    }
    text_out_pc[0] = j/256; text_out_pc[1] = j%256; text_out_pc+=2;
    total_bytes_trans+=2;
}

static void write_zscii(int zsc)
{
    int lookup_value, in_alphabet;

    if (zsc==' ')
    {   write_z_char_z(0);
        return;
    }

    if (zsc < 0x100) lookup_value = zscii_to_alphabet_grid[zsc];

    else lookup_value = -1;

    if (lookup_value >= 0)
    {   alphabet_used[lookup_value] = 'Y';
        in_alphabet = lookup_value/26;
        if (in_alphabet==1) write_z_char_z(4);  /* SHIFT to A1 */
        if (in_alphabet==2) write_z_char_z(5);  /* SHIFT to A2 */
        write_z_char_z(lookup_value%26 + 6);
    }
    else
    {   write_z_char_z(5); write_z_char_z(6);
        write_z_char_z(zsc/32); write_z_char_z(zsc%32);
    }
}

/* ------------------------------------------------------------------------- */
/*   Finish a Z-coded string, padding out with Z-char 5s if necessary and    */
/*   setting the "end" bit on the final 2-byte word                          */
/* ------------------------------------------------------------------------- */

static void end_z_chars(void)
{   unsigned char *p;
    zchars_trans_in_last_string=total_zchars_trans-zchars_trans_in_last_string;
    while (zob_index!=0) write_z_char_z(5);
    p=(unsigned char *) text_out_pc;
    *(p-2)= *(p-2)+128;
}

/* Glulx handles this much more simply -- compression is done elsewhere. */
static void write_z_char_g(int i)
{
  ASSERT_GLULX();
  if (text_out_pc+1 > text_out_limit) {
      text_out_overflow = TRUE;
      return;
  }
  total_zchars_trans++;
  text_out_pc[0] = i;
  text_out_pc++;
  total_bytes_trans++;  
}

/* ------------------------------------------------------------------------- */
/*   The main routine "text.c" provides to the rest of Inform: the text      */
/*   translator. p is the address to write output to, s_text the source text */
/*   and the return value is the next free address to write output to.       */
/*   The return value will not exceed p_limit. If the translation tries to   */
/*   overflow this boundary, the return value will be NULL (and you should   */
/*   display an error).                                                      */
/*   Note that the source text may be corrupted by this routine.             */
/* ------------------------------------------------------------------------- */

extern uchar *translate_text(uchar *p, uchar *p_limit, char *s_text)
{   int i, j, k, in_alphabet, lookup_value;
    int32 unicode; int zscii;
    unsigned char *text_in;

    /*  Cast the input and output streams to unsigned char: text_out_pc will
        advance as bytes of Z-coded text are written, but text_in doesn't    */

    text_in     = (unsigned char *) s_text;
    text_out_pc = (unsigned char *) p;
    text_out_limit = (unsigned char *) p_limit;
    text_out_overflow = FALSE;

    /*  Remember the Z-chars total so that later we can subtract to find the
        number of Z-chars translated on this string                          */

    zchars_trans_in_last_string = total_zchars_trans;

    /*  Start with the Z-characters output buffer empty                      */

    zob_index=0;

    /*  If this is the first text translated since the abbreviations were
        declared, and if some were declared, then it's time to make the
        lookup table for abbreviations

        (Except: we don't if the text being translated is itself
        the text of an abbreviation currently being defined)                 */

    if ((!abbrevs_lookup_table_made) && (no_abbreviations > 0)
        && (!is_abbreviation))
        make_abbrevs_lookup();

    /*  If we're storing the whole game text to memory, then add this text   */

    if ((!is_abbreviation) && (store_the_text))
    {   no_chars_transcribed += strlen(s_text)+2;
        if (no_chars_transcribed >= MAX_TRANSCRIPT_SIZE)
            memoryerror("MAX_TRANSCRIPT_SIZE", MAX_TRANSCRIPT_SIZE);
        sprintf(all_text_top, "%s\n\n", s_text);
        all_text_top += strlen(all_text_top);
    }

    if (transcript_switch && (!veneer_mode))
        write_to_transcript_file(s_text);

  if (!glulx_mode) {

    /*  The empty string of Z-text is illegal, since it can't carry an end
        bit: so we translate an empty string of ASCII text to just the
        pad character 5.  Printing this causes nothing to appear on screen.  */

    if (text_in[0]==0) write_z_char_z(5);

    /*  Loop through the characters of the null-terminated input text: note
        that if 1 is written over a character in the input text, it is
        afterwards ignored                                                   */

    for (i=0; text_in[i]!=0; i++)
    {   total_chars_trans++;

        /*  Contract ".  " into ". " if double-space-removing switch set:
            likewise "?  " and "!  " if the setting is high enough           */

        if ((double_space_setting >= 1)
            && (text_in[i+1]==' ') && (text_in[i+2]==' '))
        {   if (text_in[i]=='.') text_in[i+2]=1;
            if (double_space_setting >= 2)
            {   if (text_in[i]=='?') text_in[i+2]=1;
                if (text_in[i]=='!') text_in[i+2]=1;
            }
        }

        /*  Try abbreviations if the economy switch set                      */

        if ((economy_switch) && (!is_abbreviation)
            && ((k=abbrevs_lookup[text_in[i]])!=-1))
        {   if ((j=try_abbreviations_from(text_in, i, k))!=-1)
            {   if (j<32) { write_z_char_z(2); write_z_char_z(j); }
                else { write_z_char_z(3); write_z_char_z(j-32); }
            }
        }

        /* If Unicode switch set, use text_to_unicode to perform UTF-8
           decoding */
        if (character_set_unicode && (text_in[i] & 0x80))
        {   unicode = text_to_unicode((char *) (text_in+i));
            zscii = unicode_to_zscii(unicode);
            if (zscii != 5) write_zscii(zscii);
            else
            {   unicode_char_error(
                    "Character can only be used if declared in \
advance as part of 'Zcharacter table':", unicode);
            }
            i += textual_form_length - 1;
            continue;
        }

        /*  '@' is the escape character in Inform string notation: the various
            possibilities are:

                (printing only)
                @@decimalnumber  :  write this ZSCII char (0 to 1023)
                @twodigits       :  write the abbreviation string with this
                                    decimal number

                (any string context)
                @accentcode      :  this accented character: e.g.,
                                        for @'e write an E-acute
                @{...}           :  this Unicode char (in hex)              */

        if (text_in[i]=='@')
        {   if (text_in[i+1]=='@')
            {
                /*   @@...   */

                i+=2; j=atoi((char *) (text_in+i));
                switch(j)
                {   /* Prevent ~ and ^ from being translated to double-quote
                       and new-line, as they ordinarily would be */

                    case 94:   write_z_char_z(5); write_z_char_z(6);
                               write_z_char_z(94/32); write_z_char_z(94%32);
                               break;
                    case 126:  write_z_char_z(5); write_z_char_z(6);
                               write_z_char_z(126/32); write_z_char_z(126%32);
                               break;

                    default:   write_zscii(j); break;
                }
                while (isdigit(text_in[i])) i++; i--;
            }
            else if (isdigit(text_in[i+1])!=0)
            {   int d1, d2;

                /*   @..   */

                d1 = character_digit_value[text_in[i+1]];
                d2 = character_digit_value[text_in[i+2]];
                if ((d1 == 127) || (d1 >= 10) || (d2 == 127) || (d2 >= 10))
                    error("'@..' must have two decimal digits");
                else
                {   i+=2;
                    write_z_char_z(1); write_z_char_z(d1*10 + d2);
                }
            }
            else
            {
                /*   A string escape specifying an unusual character   */

                unicode = text_to_unicode((char *) (text_in+i));
                zscii = unicode_to_zscii(unicode);
                if (zscii != 5) write_zscii(zscii);
                else
                {   unicode_char_error(
                       "Character can only be used if declared in \
advance as part of 'Zcharacter table':", unicode);
                }
                i += textual_form_length - 1;
            }
        }
        else
        {   /*  Skip a character which has been over-written with the null
                value 1 earlier on                                           */

            if (text_in[i]!=1)
            {   if (text_in[i]==' ') write_z_char_z(0);
                else
                {   j = (int) text_in[i];
                    lookup_value = iso_to_alphabet_grid[j];
                    if (lookup_value < 0)
                    {   /*  The character isn't in the standard alphabets, so
                            we have to use the ZSCII 4-Z-char sequence */

                        if (lookup_value == -5)
                        {   /*  Character isn't in the ZSCII set at all */

                            unicode = iso_to_unicode(j);
                            unicode_char_error(
                                "Character can only be used if declared in \
advance as part of 'Zcharacter table':", unicode);
                            write_zscii(0x200 + unicode/0x100);
                            write_zscii(0x300 + unicode%0x100);
                        }
                        else write_zscii(-lookup_value);
                    }
                    else
                    {   /*  The character is in one of the standard alphabets:
                            write a SHIFT to temporarily change alphabet if
                            it isn't in alphabet 0, then write the Z-char    */

                        alphabet_used[lookup_value] = 'Y';
                        in_alphabet = lookup_value/26;
                        if (in_alphabet==1) write_z_char_z(4);  /* SHIFT to A1 */
                        if (in_alphabet==2) write_z_char_z(5);  /* SHIFT to A2 */
                        write_z_char_z(lookup_value%26 + 6);
                    }
                }
            }
        }
    }

    /*  Flush the Z-characters output buffer and set the "end" bit           */

    end_z_chars();

  }
  else {

    /* The text storage here is, of course, temporary. Compression
       will occur when we're finished compiling, so that all the
       clever Huffman stuff will work.
       In the stored text, we use "@@" to indicate @,
       "@0" to indicate a zero byte,
       "@ANNNN" to indicate an abbreviation,
       "@DNNNN" to indicate a dynamic string thing.
       "@UNNNN" to indicate a four-byte Unicode value (0x100 or higher).
       (NNNN is a four-digit hex number using the letters A-P... an
       ugly representation but a convenient one.) 
    */

    for (i=0; text_in[i]!=0; i++) {

      /*  Contract ".  " into ". " if double-space-removing switch set:
          likewise "?  " and "!  " if the setting is high enough. */
      if ((double_space_setting >= 1)
        && (text_in[i+1]==' ') && (text_in[i+2]==' ')) {
        if (text_in[i]=='.'
          || (double_space_setting >= 2 
            && (text_in[i]=='?' || text_in[i]=='!'))) {
          text_in[i+1] = text_in[i];
          i++;
        }
      }

      total_chars_trans++;

      /*  Try abbreviations if the economy switch set. We have to be in
          compression mode too, since the abbreviation mechanism is part
          of string decompression. */
      
      if ((economy_switch) && (compression_switch) && (!is_abbreviation)
        && ((k=abbrevs_lookup[text_in[i]])!=-1)
        && ((j=try_abbreviations_from(text_in, i, k)) != -1)) {
        char *cx = (char *)abbreviations_at+j*MAX_ABBREV_LENGTH;
        i += (strlen(cx)-1);
        write_z_char_g('@');
        write_z_char_g('A');
        write_z_char_g('A' + ((j >>12) & 0x0F));
        write_z_char_g('A' + ((j >> 8) & 0x0F));
        write_z_char_g('A' + ((j >> 4) & 0x0F));
        write_z_char_g('A' + ((j     ) & 0x0F));
      }
      else if (text_in[i] == '@') {
        if (text_in[i+1]=='@') {
          /* An ASCII code */
          i+=2; j=atoi((char *) (text_in+i));
          if (j == '@' || j == '\0') {
            write_z_char_g('@');
            if (j == 0) {
              j = '0';
              if (!compression_switch)
                warning("Ascii @@0 will prematurely terminate non-compressed \
string.");
            }
          }
          write_z_char_g(j);
          while (isdigit(text_in[i])) i++; i--;
        }
        else if (isdigit(text_in[i+1])) {
          int d1, d2;
          d1 = character_digit_value[text_in[i+1]];
          d2 = character_digit_value[text_in[i+2]];
          if ((d1 == 127) || (d1 >= 10) || (d2 == 127) || (d2 >= 10)) {
            error("'@..' must have two decimal digits");
          }
          else {
            if (!compression_switch)
              warning("'@..' print variable will not work in non-compressed \
string; substituting '   '.");
            i += 2;
            j = d1*10 + d2;
            if (j >= MAX_DYNAMIC_STRINGS) {
              memoryerror("MAX_DYNAMIC_STRINGS", MAX_DYNAMIC_STRINGS);
              j = 0;
            }
            if (j+1 >= no_dynamic_strings)
              no_dynamic_strings = j+1;
            write_z_char_g('@');
            write_z_char_g('D');
            write_z_char_g('A' + ((j >>12) & 0x0F));
            write_z_char_g('A' + ((j >> 8) & 0x0F));
            write_z_char_g('A' + ((j >> 4) & 0x0F));
            write_z_char_g('A' + ((j     ) & 0x0F));
          }
        }
        else {
          unicode = text_to_unicode((char *) (text_in+i));
          i += textual_form_length - 1;
          if (unicode >= 0 && unicode < 256) {
            write_z_char_g(unicode);
          }
          else {
            if (!compression_switch) {
              warning("Unicode characters will not work in non-compressed \
string; substituting '?'.");
              write_z_char_g('?');
            }
            else {
              j = unicode_entity_index(unicode);
              write_z_char_g('@');
              write_z_char_g('U');
              write_z_char_g('A' + ((j >>12) & 0x0F));
              write_z_char_g('A' + ((j >> 8) & 0x0F));
              write_z_char_g('A' + ((j >> 4) & 0x0F));
              write_z_char_g('A' + ((j     ) & 0x0F));
            }
          }
        }
      }
      else if (text_in[i] == '^')
        write_z_char_g(0x0A);
      else if (text_in[i] == '~')
        write_z_char_g('"');
      else if (character_set_unicode) {
        if (text_in[i] & 0x80) {
          unicode = text_to_unicode((char *) (text_in+i));
          i += textual_form_length - 1;
          if (unicode >= 0 && unicode < 256) {
            write_z_char_g(unicode);
          }
          else {
            if (!compression_switch) {
              warning("Unicode characters will not work in non-compressed \
string; substituting '?'.");
              write_z_char_g('?');
            }
            else {
              j = unicode_entity_index(unicode);
              write_z_char_g('@');
              write_z_char_g('U');
              write_z_char_g('A' + ((j >>12) & 0x0F));
              write_z_char_g('A' + ((j >> 8) & 0x0F));
              write_z_char_g('A' + ((j >> 4) & 0x0F));
              write_z_char_g('A' + ((j     ) & 0x0F));
            }
          }
        }
        else {
          write_z_char_g(text_in[i]);
        }
      }
      else {
        unicode = iso_to_unicode_grid[text_in[i]];
        if (unicode >= 0 && unicode < 256) {
          write_z_char_g(unicode);
        }
        else {
          if (!compression_switch) {
            warning("Unicode characters will not work in non-compressed \
string; substituting '?'.");
            write_z_char_g('?');
          }
          else {
            j = unicode_entity_index(unicode);
            write_z_char_g('@');
            write_z_char_g('U');
            write_z_char_g('A' + ((j >>12) & 0x0F));
            write_z_char_g('A' + ((j >> 8) & 0x0F));
            write_z_char_g('A' + ((j >> 4) & 0x0F));
            write_z_char_g('A' + ((j     ) & 0x0F));
          }
        }
      }
    }
    write_z_char_g(0);

  }

  if (text_out_overflow)
      return NULL;
  else
      return((uchar *) text_out_pc);
}

static int unicode_entity_index(int32 unicode)
{
  unicode_usage_t *uptr;
  int j;
  int buck = unicode % UNICODE_HASH_BUCKETS;

  for (uptr = unicode_usage_hash[buck]; uptr; uptr=uptr->next) {
    if (uptr->ch == unicode)
      break;
  }
  if (uptr) {
    j = (uptr - unicode_usage_entries);
  }
  else {
    if (no_unicode_chars >= MAX_UNICODE_CHARS) {
      memoryerror("MAX_UNICODE_CHARS", MAX_UNICODE_CHARS);
      j = 0;
    }
    else {
      j = no_unicode_chars;
      no_unicode_chars++;
      uptr = unicode_usage_entries + j;
      uptr->ch = unicode;
      uptr->next = unicode_usage_hash[buck];
      unicode_usage_hash[buck] = uptr;
    }
  }

  return j;
}

/* ------------------------------------------------------------------------- */
/*   Glulx compression code                                                  */
/* ------------------------------------------------------------------------- */


static void compress_makebits(int entnum, int depth, int prevbit,
  huffbitlist_t *bits);

/*   The compressor. This uses the usual Huffman compression algorithm. */
void compress_game_text()
{
  int entities=0, branchstart, branches;
  int numlive;
  int32 lx;
  int jx;
  int ch;
  int32 ix;
  huffbitlist_t bits;

  if (compression_switch) {

    /* How many entities have we currently got? Well, 256 plus the
       string-terminator plus Unicode chars plus abbrevations plus
       dynamic strings. */
    entities = 256+1;
    huff_unicode_start = entities;
    entities += no_unicode_chars;
    huff_abbrev_start = entities;
    if (economy_switch)
      entities += no_abbreviations;
    huff_dynam_start = entities;
    entities += no_dynamic_strings;

    if (entities > MAX_CHARACTER_SET)
      memoryerror("MAX_CHARACTER_SET",MAX_CHARACTER_SET);

    /* Characters */
    for (jx=0; jx<256; jx++) {
      huff_entities[jx].type = 2;
      huff_entities[jx].count = 0;
      huff_entities[jx].u.ch = jx;
    }
    /* Terminator */
    huff_entities[256].type = 1;
    huff_entities[256].count = 0;
    for (jx=0; jx<no_unicode_chars; jx++) {
      huff_entities[huff_unicode_start+jx].type = 4;
      huff_entities[huff_unicode_start+jx].count = 0;
      huff_entities[huff_unicode_start+jx].u.val = jx;
    }
    if (economy_switch) {
      for (jx=0; jx<no_abbreviations; jx++) {
        huff_entities[huff_abbrev_start+jx].type = 3;
        huff_entities[huff_abbrev_start+jx].count = 0;
        huff_entities[huff_abbrev_start+jx].u.val = jx;
      }
    }
    for (jx=0; jx<no_dynamic_strings; jx++) {
      huff_entities[huff_dynam_start+jx].type = 9;
      huff_entities[huff_dynam_start+jx].count = 0;
      huff_entities[huff_dynam_start+jx].u.val = jx;
    }
  }
  else {
    /* No compression; use defaults that will make it easy to check
       for errors. */
    no_huff_entities = 257;
    huff_unicode_start = 257;
    huff_abbrev_start = 257;
    huff_dynam_start = 257+MAX_ABBREVS;
    compression_table_size = 0;
  }

  if (temporary_files_switch) {
    fclose(Temp1_fp);
    Temp1_fp=fopen(Temp1_Name,"rb");
    if (Temp1_fp==NULL)
      fatalerror("I/O failure: couldn't reopen temporary file 1");
  }

  if (compression_switch) {

    for (lx=0, ix=0; lx<no_strings; lx++) {
      int escapelen=0, escapetype=0;
      int done=FALSE;
      int32 escapeval=0;
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
        huff_entities[ch].count++;
      }
    }

    numlive = 0;
    for (jx=0; jx<entities; jx++) {
      if (huff_entities[jx].count) {
        hufflist[numlive] = &(huff_entities[jx]);
        numlive++;
      }
    }

    branchstart = entities;
    branches = 0;

    while (numlive > 1) {
      int best1, best2;
      int best1num, best2num;
      huffentity_t *bran;

      if (hufflist[0]->count < hufflist[1]->count) {
        best1 = 0;
        best2 = 1;
      }
      else {
        best2 = 0;
        best1 = 1;
      }

      best1num = hufflist[best1]->count;
      best2num = hufflist[best2]->count;

      for (jx=2; jx<numlive; jx++) {
        if (hufflist[jx]->count < best1num) {
          best2 = best1;
          best2num = best1num;
          best1 = jx;
          best1num = hufflist[best1]->count;
        }
        else if (hufflist[jx]->count < best2num) {
          best2 = jx;
          best2num = hufflist[best2]->count;
        }
      }

      bran = &(huff_entities[branchstart+branches]);
      branches++;
      bran->type = 0;
      bran->count = hufflist[best1]->count + hufflist[best2]->count;
      bran->u.branch[0] = (hufflist[best1] - huff_entities);
      bran->u.branch[1] = (hufflist[best2] - huff_entities);
      hufflist[best1] = bran;
      if (best2 < numlive-1) {
        memmove(&(hufflist[best2]), &(hufflist[best2+1]), 
          ((numlive-1) - best2) * sizeof(huffentity_t *));
      }
      numlive--;
    }

    huff_entity_root = (hufflist[0] - huff_entities);

    for (ix=0; ix<MAXHUFFBYTES; ix++)
      bits.b[ix] = 0;
    compression_table_size = 12;

    no_huff_entities = 0; /* compress_makebits will total this up */
    compress_makebits(huff_entity_root, 0, -1, &bits);
  }

  /* Now, sadly, we have to compute the size of the string section,
     without actually doing the compression. */
  compression_string_size = 0;

  if (temporary_files_switch) {
    fseek(Temp1_fp, 0, SEEK_SET);
  }

  if (no_strings >= MAX_NUM_STATIC_STRINGS) 
    memoryerror("MAX_NUM_STATIC_STRINGS", MAX_NUM_STATIC_STRINGS);

  for (lx=0, ix=0; lx<no_strings; lx++) {
    int escapelen=0, escapetype=0;
    int done=FALSE;
    int32 escapeval=0;
    jx = 0; 
    compressed_offsets[lx] = compression_table_size + compression_string_size;
    compression_string_size++; /* for the type byte */
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
        jx += huff_entities[ch].depth;
        compression_string_size += (jx/8);
        jx = (jx % 8);
      }
      else {
        if (ch >= huff_dynam_start) {
          compression_string_size += 3;
        }
        else if (ch >= huff_unicode_start) {
          compiler_error("Abbreviation/Unicode in non-compressed string \
should be impossible.");
        }
        else
          compression_string_size += 1;
      }
    }
    if (compression_switch && jx)
      compression_string_size++;
  }

  done_compression = TRUE;
}

static void compress_makebits(int entnum, int depth, int prevbit,
  huffbitlist_t *bits)
{
  huffentity_t *ent = &(huff_entities[entnum]);
  char *cx;

  no_huff_entities++;
  ent->addr = compression_table_size;
  ent->depth = depth;
  ent->bits = *bits;
  if (depth > 0) {
    if (prevbit)
      ent->bits.b[(depth-1) / 8] |= (1 << ((depth-1) % 8));
  }

  switch (ent->type) {
  case 0:
    compression_table_size += 9;
    compress_makebits(ent->u.branch[0], depth+1, 0, &ent->bits);
    compress_makebits(ent->u.branch[1], depth+1, 1, &ent->bits);
    break;
  case 1:
    compression_table_size += 1;
    break;
  case 2:
    compression_table_size += 2;
    break;
  case 3:
    cx = (char *)abbreviations_at + ent->u.val*MAX_ABBREV_LENGTH;
    compression_table_size += (1 + 1 + strlen(cx));
    break;
  case 4:
  case 9:
    compression_table_size += 5;
    break;
  }
}

/* ------------------------------------------------------------------------- */
/*   The abbreviations optimiser                                             */
/*                                                                           */
/*   This is a very complex, memory and time expensive algorithm to          */
/*   approximately solve the problem of which abbreviation strings would     */
/*   minimise the total number of Z-chars to which the game text translates. */
/*   It is in some ways a quite separate program but remains inside Inform   */
/*   for compatibility with previous releases.                               */
/* ------------------------------------------------------------------------- */

typedef struct tlb_s
{   char text[4];
    int32 intab, occurrences;
} tlb;
static tlb *tlbtab;
static int32 no_occs;

static int32 *grandtable;
static int32 *grandflags;
typedef struct optab_s
{   int32  length;
    int32  popularity;
    int32  score;
    int32  location;
    char text[MAX_ABBREV_LENGTH];
} optab;
static optab *bestyet, *bestyet2;

static int pass_no;

static char *sub_buffer;

static void optimise_pass(void)
{   int32 i; int t1, t2;
    int32 j, j2, k, nl, matches, noflags, score, min, minat=0, x, scrabble, c;
    for (i=0; i<256; i++) bestyet[i].length=0;
    for (i=0; i<no_occs; i++)
    {   if ((*(tlbtab[i].text)!=(int) '\n')&&(tlbtab[i].occurrences!=0))
        {
#ifdef MAC_FACE
            if (i%((**g_pm_hndl).linespercheck) == 0)
            {   ProcessEvents (&g_proc);
                if (g_proc != true)
                {   free_arrays();
                    if (store_the_text)
                        my_free(&all_text,"transcription text");
                    longjmp (g_fallback, 1);
                }
            }
#endif
            printf("Pass %d, %4ld/%ld '%s' (%ld occurrences) ",
                pass_no, (long int) i, (long int) no_occs, tlbtab[i].text,
                (long int) tlbtab[i].occurrences);
            t1=(int) (time(0));
            for (j=0; j<tlbtab[i].occurrences; j++)
            {   for (j2=0; j2<tlbtab[i].occurrences; j2++) grandflags[j2]=1;
                nl=2; noflags=tlbtab[i].occurrences;
                while ((noflags>=2)&&(nl<=62))
                {   nl++;
                    for (j2=0; j2<nl; j2++)
                        if (all_text[grandtable[tlbtab[i].intab+j]+j2]=='\n')
                            goto FinishEarly;
                    matches=0;
                    for (j2=j; j2<tlbtab[i].occurrences; j2++)
                    {   if (grandflags[j2]==1)
                        {   x=grandtable[tlbtab[i].intab+j2]
                              - grandtable[tlbtab[i].intab+j];
                         if (((x>-nl)&&(x<nl))
                            || (memcmp(all_text+grandtable[tlbtab[i].intab+j],
                                       all_text+grandtable[tlbtab[i].intab+j2],
                                       nl)!=0))
                            {   grandflags[j2]=0; noflags--; }
                            else matches++;
                        }
                    }
                    scrabble=0;
                    for (k=0; k<nl; k++)
                    {   scrabble++;
                        c=all_text[grandtable[tlbtab[i].intab+j+k]];
                        if (c!=(int) ' ')
                        {   if (iso_to_alphabet_grid[c]<0)
                                scrabble+=2;
                            else
                                if (iso_to_alphabet_grid[c]>=26)
                                    scrabble++;
                        }
                    }
                    score=(matches-1)*(scrabble-2);
                    min=score;
                    for (j2=0; j2<256; j2++)
                    {   if ((nl==bestyet[j2].length)
                                && (memcmp(all_text+bestyet[j2].location,
                                       all_text+grandtable[tlbtab[i].intab+j],
                                       nl)==0))
                        {   j2=256; min=score; }
                        else
                        {   if (bestyet[j2].score<min)
                            {   min=bestyet[j2].score; minat=j2;
                            }
                        }
                    }
                    if (min!=score)
                    {   bestyet[minat].score=score;
                        bestyet[minat].length=nl;
                        bestyet[minat].location=grandtable[tlbtab[i].intab+j];
                        bestyet[minat].popularity=matches;
                        for (j2=0; j2<nl; j2++) sub_buffer[j2]=
                            all_text[bestyet[minat].location+j2];
                        sub_buffer[nl]=0;
                    }
                }
                FinishEarly: ;
            }
            t2=((int) time(0)) - t1;
            printf(" (%d seconds)\n",t2);
        }
    }
}

static int any_overlap(char *s1, char *s2)
{   int a, b, i, j, flag;
    a=strlen(s1); b=strlen(s2);
    for (i=1-b; i<a; i++)
    {   flag=0;
        for (j=0; j<b; j++)
            if ((0<=i+j)&&(i+j<=a-1))
                if (s1[i+j]!=s2[j]) flag=1;
        if (flag==0) return(1);
    }
    return(0);
}

#define MAX_TLBS 8000

extern void optimise_abbreviations(void)
{   int32 i, j, t, max=0, MAX_GTABLE;
    int32 j2, selected, available, maxat=0, nl;
    tlb test;

    printf("Beginning calculation of optimal abbreviations...\n");

    pass_no = 0;
    tlbtab=my_calloc(sizeof(tlb), MAX_TLBS, "tlb table"); no_occs=0;
    sub_buffer=my_calloc(sizeof(char), 4000, "sub_buffer");
    for (i=0; i<MAX_TLBS; i++) tlbtab[i].occurrences=0;

    bestyet=my_calloc(sizeof(optab), 256, "bestyet");
    bestyet2=my_calloc(sizeof(optab), 64, "bestyet2");

    bestyet2[0].text[0]='.';
    bestyet2[0].text[1]=' ';
    bestyet2[0].text[2]=0;

    bestyet2[1].text[0]=',';
    bestyet2[1].text[1]=' ';
    bestyet2[1].text[2]=0;

    for (i=0; all_text+i<all_text_top; i++)
    {
        if ((all_text[i]=='.') && (all_text[i+1]==' ') && (all_text[i+2]==' '))
        {   all_text[i]='\n'; all_text[i+1]='\n'; all_text[i+2]='\n';
            bestyet2[0].popularity++;
        }

        if ((all_text[i]=='.') && (all_text[i+1]==' '))
        {   all_text[i]='\n'; all_text[i+1]='\n';
            bestyet2[0].popularity++;
        }

        if ((all_text[i]==',') && (all_text[i+1]==' '))
        {   all_text[i]='\n'; all_text[i+1]='\n';
            bestyet2[1].popularity++;
        }
    }

    MAX_GTABLE=subtract_pointers(all_text_top,all_text)+1;
    grandtable=my_calloc(4*sizeof(int32), MAX_GTABLE/4, "grandtable");

    for (i=0, t=0; all_text+i<all_text_top; i++)
    {   test.text[0]=all_text[i];
        test.text[1]=all_text[i+1];
        test.text[2]=all_text[i+2];
        test.text[3]=0;
        if ((test.text[0]=='\n')||(test.text[1]=='\n')||(test.text[2]=='\n'))
            goto DontKeep;
        for (j=0; j<no_occs; j++)
            if (strcmp(test.text,tlbtab[j].text)==0)
                goto DontKeep;
        test.occurrences=0;
        for (j=i+3; all_text+j<all_text_top; j++)
        {
#ifdef MAC_FACE
            if (j%((**g_pm_hndl).linespercheck) == 0)
            {   ProcessEvents (&g_proc);
                if (g_proc != true)
                {   free_arrays();
                    if (store_the_text)
                        my_free(&all_text,"transcription text");
                    longjmp (g_fallback, 1);
                }
            }
#endif
            if ((all_text[i]==all_text[j])
                 && (all_text[i+1]==all_text[j+1])
                 && (all_text[i+2]==all_text[j+2]))
                 {   grandtable[t+test.occurrences]=j;
                     test.occurrences++;
                     if (t+test.occurrences==MAX_GTABLE)
                     {   printf("All %ld cross-references used\n",
                             (long int) MAX_GTABLE);
                         goto Built;
                     }
                 }
        }
        if (test.occurrences>=2)
        {   tlbtab[no_occs]=test;
            tlbtab[no_occs].intab=t; t+=tlbtab[no_occs].occurrences;
            if (max<tlbtab[no_occs].occurrences)
                max=tlbtab[no_occs].occurrences;
            no_occs++;
            if (no_occs==MAX_TLBS)
            {   printf("All %d three-letter-blocks used\n",
                    MAX_TLBS);
                goto Built;
            }
        }
        DontKeep: ;
    }

    Built:
    grandflags=my_calloc(sizeof(int), max, "grandflags");


    printf("Cross-reference table (%ld entries) built...\n",
        (long int) no_occs);
    /*  for (i=0; i<no_occs; i++)
            printf("%4d %4d '%s' %d\n",i,tlbtab[i].intab,tlbtab[i].text,
                tlbtab[i].occurrences);
    */

    for (i=0; i<64; i++) bestyet2[i].length=0; selected=2;
    available=256;
    while ((available>0)&&(selected<64))
    {   printf("Pass %d\n", ++pass_no);

        optimise_pass();
        available=0;
        for (i=0; i<256; i++)
            if (bestyet[i].score!=0)
            {   available++;
                nl=bestyet[i].length;
                for (j2=0; j2<nl; j2++) bestyet[i].text[j2]=
                    all_text[bestyet[i].location+j2];
                bestyet[i].text[nl]=0;
            }

    /*  printf("End of pass results:\n");
        printf("\nno   score  freq   string\n");
        for (i=0; i<256; i++)
            if (bestyet[i].score>0)
                printf("%02d:  %4d   %4d   '%s'\n", i, bestyet[i].score,
                    bestyet[i].popularity, bestyet[i].text);
    */

        do
        {   max=0;
            for (i=0; i<256; i++)
                if (max<bestyet[i].score)
                {   max=bestyet[i].score;
                    maxat=i;
                }

            if (max>0)
            {   bestyet2[selected++]=bestyet[maxat];

                printf(
                    "Selection %2ld: '%s' (repeated %ld times, scoring %ld)\n",
                    (long int) selected,bestyet[maxat].text,
                    (long int) bestyet[maxat].popularity,
                    (long int) bestyet[maxat].score);

                test.text[0]=bestyet[maxat].text[0];
                test.text[1]=bestyet[maxat].text[1];
                test.text[2]=bestyet[maxat].text[2];
                test.text[3]=0;

                for (i=0; i<no_occs; i++)
                    if (strcmp(test.text,tlbtab[i].text)==0)
                        break;

                for (j=0; j<tlbtab[i].occurrences; j++)
                {   if (memcmp(bestyet[maxat].text,
                               all_text+grandtable[tlbtab[i].intab+j],
                               bestyet[maxat].length)==0)
                    {   for (j2=0; j2<bestyet[maxat].length; j2++)
                            all_text[grandtable[tlbtab[i].intab+j]+j2]='\n';
                    }
                }

                for (i=0; i<256; i++)
                    if ((bestyet[i].score>0)&&
                        (any_overlap(bestyet[maxat].text,bestyet[i].text)==1))
                    {   bestyet[i].score=0;
                       /* printf("Discarding '%s' as overlapping\n",
                            bestyet[i].text); */
                    }
            }
        } while ((max>0)&&(available>0)&&(selected<64));
    }

    printf("\nChosen abbreviations (in Inform syntax):\n\n");
    for (i=0; i<selected; i++)
        printf("Abbreviate \"%s\";\n", bestyet2[i].text);

    text_free_arrays();
}

/* ------------------------------------------------------------------------- */
/*   The dictionary manager begins here.                                     */
/*                                                                           */
/*   Speed is extremely important in these algorithms.  If a linear-time     */
/*   routine were used to search the dictionary words so far built up, then  */
/*   Inform would crawl.                                                     */
/*                                                                           */
/*   Instead, the dictionary is stored as a binary tree, which is kept       */
/*   balanced with the red-black algorithm.                                  */
/* ------------------------------------------------------------------------- */
/*   A dictionary table similar to the Z-machine format is kept: there is a  */
/*   7-byte header (left blank here to be filled in at the                   */
/*   construct_storyfile() stage in "tables.c") and then a sequence of       */
/*   records, one per word, in the form                                      */
/*                                                                           */
/*        <Z-coded text>    <flags>   <verbnumber>     <adjectivenumber>     */
/*        4 or 6 bytes       byte        byte             byte               */
/*                                                                           */
/*   For Glulx, the form is instead: (But see below about Unicode-valued     */
/*   dictionaries and my heinie.)                                            */
/*                                                                           */
/*        <plain text>      <flags>   <verbnumber>     <adjectivenumber>     */
/*        DICT_WORD_SIZE     short       short            short              */
/*                                                                           */
/*   These records are stored in "accession order" (i.e. in order of their   */
/*   first being received by these routines) and only alphabetically sorted  */
/*   by construct_storyfile() (using the array below).                       */
/* ------------------------------------------------------------------------- */
/*                                                                           */
/*   Further notes about the data fields...                                  */
/*   The flags are currently:                                                */
/*     bit 0: word is used as a verb (in verb grammar)                       */
/*     bit 1: word is used as a meta verb                                    */
/*     bit 2: word is plural (set by '//p')                                  */
/*     bit 3: word is used as a preposition (in verb grammar)                */
/*     bit 6: set for all verbs, but not used by the parser?                 */
/*     bit 7: word is used as a noun (set for every word that appears in     */
/*       code or in an object property)                                      */
/*                                                                           */
/*   In grammar version 2, the third field (adjectivenumber) is unused (and  */
/*   zero).                                                                  */
/*                                                                           */
/*   The compiler generates special constants #dict_par1, #dict_par2,        */
/*   #dict_par3 to refer to the byte offsets of the three fields. In         */
/*   Z-code v3, these are 4/5/6; in v4+, they are 6/7/8. In Glulx, they      */
/*   are $DICT_WORD_SIZE+2/4/6, referring to the *low* bytes of the three    */
/*   fields. (The high bytes are $DICT_WORD_SIZE+1/3/5.)                     */
/* ------------------------------------------------------------------------- */

uchar *dictionary,                    /* (These two pointers are externally
                                         used only in "tables.c" when
                                         building the story-file)            */
    *dictionary_top;                  /* Pointer to next free record         */

int dict_entries;                     /* Total number of records entered     */

/* ------------------------------------------------------------------------- */
/*   dict_word is a typedef for a struct of 6 unsigned chars (defined in     */
/*   "header.h"): it holds the (4 or) 6 bytes of Z-coded text of a word.     */
/*   Usefully, because the PAD character 5 is < all alphabetic characters,   */
/*   alphabetic order corresponds to numeric order.  For this reason, the    */
/*   dict_word is called the "sort code" of the original text word.          */
/*                                                                           */
/*   ###- In modifying the compiler, I've found it easier to discard the     */
/*   typedef, and operate directly on uchar arrays of length DICT_WORD_SIZE. */
/*   In Z-code, DICT_WORD_SIZE will be 6, so the Z-code compiler will work   */
/*   as before. In Glulx, it can be any value up to MAX_DICT_WORD_SIZE.      */
/*   (That limit is defined as 40 in the header; it exists only for a few    */
/*   static buffers, and can be increased without using significant memory.) */
/*                                                                           */
/*   ###- Well, that certainly bit me on the butt, didn't it. In further     */
/*   modifying the compiler to generate a Unicode dictionary, I have to      */
/*   store four-byte values in the uchar array. This is handled by making    */
/*   the array size DICT_WORD_BYTES (which is DICT_WORD_SIZE*DICT_CHAR_SIZE).*/
/*   Then we store the 32-bit character value big-endian. This lets us       */
/*   continue to compare arrays bytewise, which is a nice simplification.    */
/* ------------------------------------------------------------------------- */

extern int compare_sorts(uchar *d1, uchar *d2)
{   int i;
    for (i=0; i<DICT_WORD_BYTES; i++) 
        if (d1[i]!=d2[i]) return((int)(d1[i]) - (int)(d2[i]));
    /* (since memcmp(d1, d2, DICT_WORD_BYTES); runs into a bug on some Unix 
       libraries) */
    return(0);
}

extern void copy_sorts(uchar *d1, uchar *d2)
{   int i;
    for (i=0; i<DICT_WORD_BYTES; i++) 
        d1[i] = d2[i];
}

static uchar prepared_sort[MAX_DICT_WORD_BYTES];     /* Holds the sort code
                                                        of current word */

static int number_and_case;

/* Also used by verbs.c */
static void dictionary_prepare_z(char *dword, uchar *optresult)
{   int i, j, k, k2, wd[13]; int32 tot;

    /* A rapid text translation algorithm using only the simplified rules
       applying to the text of dictionary entries: first produce a sequence
       of 6 (v3) or 9 (v4+) Z-characters                                     */

    number_and_case = 0;

    for (i=0, j=0; dword[j]!=0; i++, j++)
    {   if ((dword[j] == '/') && (dword[j+1] == '/'))
        {   for (j+=2; dword[j] != 0; j++)
            {   switch(dword[j])
                {   case 'p': number_and_case |= 4;  break;
                    default:
                        error_named("Expected 'p' after '//' \
to give number of dictionary word", dword);
                        break;
                }
            }
            break;
        }
        if (i>=9) break;

        k=(int) dword[j];
        if (k==(int) '\'')
            warning_named("Obsolete usage: use the ^ character for the \
apostrophe in", dword);
        if (k==(int) '^') k=(int) '\'';
        if (k=='\"') k='~';

        if (k==(int) '@' || (character_set_unicode && (k & 0x80)))
        {   int unicode = text_to_unicode(dword+j);
            if ((unicode < 128) && isupper(unicode)) unicode = tolower(unicode);
            k = unicode_to_zscii(unicode);
            j += textual_form_length - 1;
            if ((k == 5) || (k >= 0x100))
            {   unicode_char_error(
                   "Character can be printed but not input:", unicode);
                k = '?';
            }
            k2 = zscii_to_alphabet_grid[(uchar) k];
        }
        else
        {   if (isupper(k)) k = tolower(k);
            k2 = iso_to_alphabet_grid[(uchar) k];
        }

        if (k2 < 0)
        {   if ((k2 == -5) || (k2 <= -0x100))
                char_error("Character can be printed but not input:", k);
            else
            {   /* Use 4 more Z-chars to encode a ZSCII escape sequence      */

                wd[i++] = 5; wd[i++] = 6;
                k2 = -k2;
                wd[i++] = k2/32; wd[i] = k2%32;
            }
        }
        else
        {   alphabet_used[k2] = 'Y';
            if ((k2/26)!=0)
                wd[i++]=3+(k2/26);            /* Change alphabet for symbols */
            wd[i]=6+(k2%26);                  /* Write the Z character       */
        }
    }

    /* Fill up to the end of the dictionary block with PAD characters        */

    for (; i<9; i++) wd[i]=5;

    /* The array of Z-chars is converted to three 2-byte blocks              */

    tot = wd[2] + wd[1]*(1<<5) + wd[0]*(1<<10);
    prepared_sort[1]=tot%0x100;
    prepared_sort[0]=(tot/0x100)%0x100;
    tot = wd[5] + wd[4]*(1<<5) + wd[3]*(1<<10);
    prepared_sort[3]=tot%0x100;
    prepared_sort[2]=(tot/0x100)%0x100;
    tot = wd[8] + wd[7]*(1<<5) + wd[6]*(1<<10);
    prepared_sort[5]=tot%0x100;
    prepared_sort[4]=(tot/0x100)%0x100;

    /* Set the "end bit" on the 2nd (in v3) or the 3rd (v4+) 2-byte block    */

    if (version_number==3) prepared_sort[2]+=0x80;
                      else prepared_sort[4]+=0x80;

    if (optresult) copy_sorts(optresult, prepared_sort);
}

/* Also used by verbs.c */
static void dictionary_prepare_g(char *dword, uchar *optresult)
{ 
  int i, j, k;
  int32 unicode;

  number_and_case = 0;

  for (i=0, j=0; (dword[j]!=0); i++, j++) {
    if ((dword[j] == '/') && (dword[j+1] == '/')) {
      for (j+=2; dword[j] != 0; j++) {
        switch(dword[j]) {
        case 'p':
          number_and_case |= 4;  
          break;
        default:
          error_named("Expected 'p' after '//' \
to give gender or number of dictionary word", dword);
          break;
        }
      }
      break;
    }
    if (i>=DICT_WORD_SIZE) break;

    k= ((unsigned char *)dword)[j];
    if (k=='\'') 
      warning_named("Obsolete usage: use the ^ character for the \
apostrophe in", dword);
    if (k=='^') 
      k='\'';
    if (k=='~') /* as in iso_to_alphabet_grid */
      k='\"';

    if (k=='@' || (character_set_unicode && (k & 0x80))) {
      unicode = text_to_unicode(dword+j);
      j += textual_form_length - 1;
    }
    else {
      unicode = iso_to_unicode_grid[k];
    }

    if (DICT_CHAR_SIZE != 1 || (unicode >= 0 && unicode < 256)) {
      k = unicode;
    }
    else {
      error("The dictionary cannot contain Unicode characters beyond Latin-1. \
Define DICT_CHAR_SIZE=4 for a Unicode-compatible dictionary.");
      k = '?';
    }
    
    if (k >= (unsigned)'A' && k <= (unsigned)'Z')
      k += ('a' - 'A');

    if (DICT_CHAR_SIZE == 1) {
      prepared_sort[i] = k;
    }
    else {
      prepared_sort[4*i]   = (k >> 24) & 0xFF;
      prepared_sort[4*i+1] = (k >> 16) & 0xFF;
      prepared_sort[4*i+2] = (k >>  8) & 0xFF;
      prepared_sort[4*i+3] = (k)       & 0xFF;
    }
  }

  if (DICT_CHAR_SIZE == 1) {
    for (; i<DICT_WORD_SIZE; i++)
      prepared_sort[i] = 0;
  }
  else {
    for (; i<DICT_WORD_SIZE; i++) {
      prepared_sort[4*i]   = 0;
      prepared_sort[4*i+1] = 0;
      prepared_sort[4*i+2] = 0;
      prepared_sort[4*i+3] = 0;
    }
  }

  if (optresult) copy_sorts(optresult, prepared_sort);
}

extern void dictionary_prepare(char *dword, uchar *optresult)
{
  if (!glulx_mode)
    dictionary_prepare_z(dword, optresult);
  else
    dictionary_prepare_g(dword, optresult);
}

/* ------------------------------------------------------------------------- */
/*   The arrays below are all concerned with the problem of alphabetically   */
/*   sorting the dictionary during the compilation pass.                     */
/*   Note that it is not enough simply to apply qsort to the dictionary at   */
/*   the end of the pass: we need to ensure that no duplicates are ever      */
/*   created.                                                                */
/*                                                                           */
/*   dict_sort_codes[n]     the sort code of record n: i.e., of the nth      */
/*                          word to be entered into the dictionary, where    */
/*                          n counts upward from 0                           */
/*                          (n is also called the "accession number")        */
/*                                                                           */
/*   The tree structure encodes an ordering.  The special value VACANT means */
/*   "no node here": otherwise, node numbers are the same as accession       */
/*   numbers.  At all times, "root" holds the node number of the top of the  */
/*   tree; each node has up to two branches, such that the subtree of the    */
/*   left branch is always alphabetically before what's at the node, and     */
/*   the subtree to the right is always after; and all branches are coloured */
/*   either "black" or "red".  These colours are used to detect points where */
/*   the tree is growing asymmetrically (and therefore becoming inefficient  */
/*   to search).                                                             */
/* ------------------------------------------------------------------------- */

#define RED    'r'
#define BLACK  'b'
#define VACANT -1

static int root;
typedef struct dict_tree_node_s
{   int  branch[2];               /* Branch 0 is "left", 1 is "right" */
    char colour;                  /* The colour of the branch to the parent */
} dict_tree_node;

static dict_tree_node *dtree;

int   *final_dict_order;
static uchar *dict_sort_codes;

static void dictionary_begin_pass(void)
{
    /*  Leave room for the 7-byte header (added in "tables.c" much later)    */
    /*  Glulx has a 4-byte header instead. */

    if (!glulx_mode)
        dictionary_top=dictionary+7;
    else
        dictionary_top=dictionary+4;

    root = VACANT;
    dict_entries = 0;
}

static int fdo_count;
static void recursively_sort(int node)
{   if (dtree[node].branch[0] != VACANT)
        recursively_sort(dtree[node].branch[0]);
    final_dict_order[node] = fdo_count++;
    if (dtree[node].branch[1] != VACANT)
        recursively_sort(dtree[node].branch[1]);
}

extern void sort_dictionary(void)
{   int i;
    if (module_switch)
    {   for (i=0; i<dict_entries; i++)
            final_dict_order[i] = i;
        return;
    }

    if (root != VACANT)
    {   fdo_count = 0; recursively_sort(root);
    }
}

/* ------------------------------------------------------------------------- */
/*   If "dword" is in the dictionary, return its accession number plus 1;    */
/*   If not, return 0.                                                       */
/* ------------------------------------------------------------------------- */

static int dictionary_find(char *dword)
{   int at = root, n;

    dictionary_prepare(dword, NULL);

    while (at != VACANT)
    {   n = compare_sorts(prepared_sort, dict_sort_codes+at*DICT_WORD_BYTES);
        if (n==0) return at + 1;
        if (n>0) at = dtree[at].branch[1]; else at = dtree[at].branch[0];
    }
    return 0;
}

/* ------------------------------------------------------------------------- */
/*  Add "dword" to the dictionary with (x,y,z) as its data fields; unless    */
/*  it already exists, in which case OR the data with (x,y,z)                */
/*                                                                           */
/*  These fields are one byte each in Z-code, two bytes each in Glulx.       */
/*                                                                           */
/*  Returns: the accession number.                                           */
/* ------------------------------------------------------------------------- */

extern int dictionary_add(char *dword, int x, int y, int z)
{   int n; uchar *p;
    int ggfr = 0, gfr = 0, fr = 0, r = 0;
    int ggf = VACANT, gf = VACANT, f = VACANT, at = root;
    int a, b;
    int res=((version_number==3)?4:6);

    dictionary_prepare(dword, NULL);

    if (root == VACANT)
    {   root = 0; goto CreateEntry;
    }
    while (TRUE)
    {
        n = compare_sorts(prepared_sort, dict_sort_codes+at*DICT_WORD_BYTES);
        if (n==0)
        {
            if (!glulx_mode) {
                p = dictionary+7 + at*(3+res) + res;
                p[0]=(p[0])|x; p[1]=(p[1])|y; p[2]=(p[2])|z;
                if (x & 128) p[0] = (p[0])|number_and_case;
            }
            else {
                p = dictionary+4 + at*DICT_ENTRY_BYTE_LENGTH + DICT_ENTRY_FLAG_POS;
                p[0]=(p[0])|(x/256); p[1]=(p[1])|(x%256); 
                p[2]=(p[2])|(y/256); p[3]=(p[3])|(y%256); 
                p[4]=(p[4])|(z/256); p[5]=(p[5])|(z%256);
                if (x & 128) p[1] = (p[1]) | number_and_case;
            }
            return at;
        }
        if (n>0) r=1; else r=0;

        a = dtree[at].branch[0]; b = dtree[at].branch[1];
        if ((a != VACANT) && (dtree[a].colour == RED) &&
            (b != VACANT) && (dtree[b].colour == RED))
        {   dtree[a].colour = BLACK;
            dtree[b].colour = BLACK;

            dtree[at].colour = RED;

        /* A tree rotation may be needed to avoid two red links in a row:
           e.g.
             ggf   (or else gf is root)         ggf (or f is root)
              |                                  |
              gf                                 f
             / \(red)                           / \ (both red)
                f            becomes          gf   at
               / \(red)                      /  \ /  \
                  at
                 /  \

           In effect we rehang the "gf" subtree from "f".
           See the Technical Manual for further details.
        */

            if ((f != VACANT) && (gf != VACANT) && (dtree[f].colour == RED))
            {
              if (fr == gfr)
              { if (ggf == VACANT) root = f; else dtree[ggf].branch[ggfr] = f;
                dtree[gf].branch[gfr] = dtree[f].branch[1-fr];
                dtree[f].branch[1-fr] = gf;
                dtree[f].colour = BLACK;
                dtree[gf].colour = RED;
                gf = ggf; gfr = ggfr;
              }
              else
              { if (ggf == VACANT) root = at; else dtree[ggf].branch[ggfr] = at;
                dtree[at].colour = BLACK;
                dtree[gf].colour = RED;
                dtree[f].branch[fr] = dtree[at].branch[gfr];
                dtree[gf].branch[gfr] = dtree[at].branch[fr];
                dtree[at].branch[gfr] = f;
                dtree[at].branch[fr] = gf;

                r = 1-r; n = at; if (r==fr) at = f; else at = gf;
                f = n; gf = ggf; fr = 1-r; gfr = ggfr;
              }
            }
        }

        if (dtree[at].branch[r] == VACANT)
        {   dtree[at].colour = RED;

            if ((f != VACANT) && (gf != VACANT) && (dtree[f].colour == RED))
            { if (fr == gfr)
              { if (ggf == VACANT) root = f; else dtree[ggf].branch[ggfr] = f;
                dtree[gf].branch[gfr] = dtree[f].branch[1-fr];
                dtree[f].branch[1-fr] = gf;
                dtree[f].colour = BLACK;
                dtree[gf].colour = RED;
              }
              else
              { if (ggf == VACANT) root = at; else dtree[ggf].branch[ggfr] = at;
                dtree[at].colour = BLACK;
                dtree[gf].colour = RED;
                dtree[f].branch[fr] = dtree[at].branch[gfr];
                dtree[gf].branch[gfr] = dtree[at].branch[fr];
                dtree[at].branch[gfr] = f;
                dtree[at].branch[fr] = gf;

                r = 1-r; n = at; if (r==fr) at = f; else at = gf;
                f = n; gf = ggf;
              }
            }
            dtree[at].branch[r] = dict_entries;
            goto CreateEntry;
        }
        ggf = gf; gf = f; f = at; at = dtree[at].branch[r];
        ggfr = gfr; gfr = fr; fr = r;
    }

    CreateEntry:

    if (dict_entries==MAX_DICT_ENTRIES)
        memoryerror("MAX_DICT_ENTRIES",MAX_DICT_ENTRIES);

    dtree[dict_entries].branch[0] = VACANT;
    dtree[dict_entries].branch[1] = VACANT;
    dtree[dict_entries].colour    = BLACK;

    /*  Address in Inform's own dictionary table to write the record to      */

    if (!glulx_mode) {

        p = dictionary + (3+res)*dict_entries + 7;

        /*  So copy in the 4 (or 6) bytes of Z-coded text and the 3 data 
            bytes */

        p[0]=prepared_sort[0]; p[1]=prepared_sort[1];
        p[2]=prepared_sort[2]; p[3]=prepared_sort[3];
        if (version_number > 3)
          {   p[4]=prepared_sort[4]; p[5]=prepared_sort[5]; }
        p[res]=x; p[res+1]=y; p[res+2]=z;
        if (x & 128) p[res] = (p[res])|number_and_case;

        dictionary_top += res+3;

    }
    else {
        int i;
        p = dictionary + 4 + DICT_ENTRY_BYTE_LENGTH*dict_entries;
        p[0] = 0x60; /* type byte -- dict word */

        p += DICT_CHAR_SIZE;
        for (i=0; i<DICT_WORD_BYTES; i++)
          p[i] = prepared_sort[i];
        
        p += DICT_WORD_BYTES;
        p[0] = 0; p[1] = x;
        p[2] = y/256; p[3] = y%256;
        p[4] = 0; p[5] = z;
        if (x & 128) 
          p[1] |= number_and_case;
        
        dictionary_top += DICT_ENTRY_BYTE_LENGTH;

    }

    copy_sorts(dict_sort_codes+dict_entries*DICT_WORD_BYTES, prepared_sort);

    return dict_entries++;
}

/* ------------------------------------------------------------------------- */
/*   Used in "tables.c" for "Extend ... only", to renumber a verb-word to a  */
/*   new verb syntax of its own.  (Otherwise existing verb-words never       */
/*   change their verb-numbers.)                                             */
/* ------------------------------------------------------------------------- */

extern void dictionary_set_verb_number(char *dword, int to)
{   int i; uchar *p;
    int res=((version_number==3)?4:6);
    i=dictionary_find(dword);
    if (i!=0)
    {   
        if (!glulx_mode) {
            p=dictionary+7+(i-1)*(3+res)+res; 
            p[1]=to;
        }
        else {
            p=dictionary+4 + (i-1)*DICT_ENTRY_BYTE_LENGTH + DICT_ENTRY_FLAG_POS; 
            p[2]=to/256; p[3]=to%256;
        }
    }
}

/* ------------------------------------------------------------------------- */
/*   Tracing code for the dictionary: used not only by "trace" and text      */
/*   transcription, but also (in the case of "word_to_ascii") in a vital     */
/*   by the linker.                                                          */
/* ------------------------------------------------------------------------- */

static char *d_show_to;
static int d_show_total;

static void show_char(char c)
{   if (d_show_to == NULL) printf("%c", c);
    else
    {   int i = strlen(d_show_to);
        d_show_to[i] = c; d_show_to[i+1] = 0;
    }
}

extern void word_to_ascii(uchar *p, char *results)
{   int i, shift, cc, zchar; uchar encoded_word[9];
    encoded_word[0] = (((int) p[0])&0x7c)/4;
    encoded_word[1] = 8*(((int) p[0])&0x3) + (((int) p[1])&0xe0)/32;
    encoded_word[2] = ((int) p[1])&0x1f;
    encoded_word[3] = (((int) p[2])&0x7c)/4;
    encoded_word[4] = 8*(((int) p[2])&0x3) + (((int) p[3])&0xe0)/32;
    encoded_word[5] = ((int) p[3])&0x1f;
    if (version_number > 3)
    {   encoded_word[6] = (((int) p[4])&0x7c)/4;
        encoded_word[7] = 8*(((int) p[4])&0x3) + (((int) p[5])&0xe0)/32;
        encoded_word[8] = ((int) p[5])&0x1f;
    }

    shift = 0; cc = 0;
    for (i=0; i< ((version_number==3)?6:9); i++)
    {   zchar = encoded_word[i];

        if (zchar == 4) shift = 1;
        else
        if (zchar == 5) shift = 2;
        else
        {   if ((shift == 2) && (zchar == 6))
            {   zchar = 32*encoded_word[i+1] + encoded_word[i+2];
                i += 2;
                if ((zchar>=32) && (zchar<=126))
                    results[cc++] = zchar;
                else
                {   zscii_to_text(results+cc, zchar);
                    cc = strlen(results);
                }
            }
            else
            {   zscii_to_text(results+cc, (alphabet[shift])[zchar-6]);
                cc = strlen(results);
            }
            shift = 0;
        }
    }
    results[cc] = 0;
}

static void recursively_show_z(int node)
{   int i, cprinted, flags; uchar *p;
    char textual_form[32];
    int res = (version_number == 3)?4:6;

    if (dtree[node].branch[0] != VACANT)
        recursively_show_z(dtree[node].branch[0]);

    p = (uchar *)dictionary + 7 + (3+res)*node;

    word_to_ascii(p, textual_form);

    for (cprinted = 0; textual_form[cprinted]!=0; cprinted++)
        show_char(textual_form[cprinted]);
    for (; cprinted < 4 + ((version_number==3)?6:9); cprinted++)
        show_char(' ');

    if (d_show_to == NULL)
    {   for (i=0; i<3+res; i++) printf("%02x ",p[i]);

        flags = (int) p[res];
        if (flags & 128)
        {   printf("noun ");
            if (flags & 4)  printf("p"); else printf(" ");
            printf(" ");
        }
        else printf("       ");
        if (flags & 8)
        {   if (grammar_version_number == 1)
                printf("preposition:%d  ", (int) p[res+2]);
            else
                printf("preposition    ");
        }
        if ((flags & 3) == 3) printf("metaverb:%d  ", (int) p[res+1]);
        else if ((flags & 3) == 1) printf("verb:%d  ", (int) p[res+1]);
        printf("\n");
    }

    if (d_show_total++ == 5)
    {   d_show_total = 0;
        if (d_show_to != NULL)
        {   write_to_transcript_file(d_show_to);
            d_show_to[0] = 0;
        }
    }

    if (dtree[node].branch[1] != VACANT)
        recursively_show_z(dtree[node].branch[1]);
}

static void recursively_show_g(int node)
{
  warning("### Glulx dictionary-show not yet implemented.\n");
}

static void show_alphabet(int i)
{   int j, c; char chartext[8];

    for (j=0; j<26; j++)
    {   c = alphabet[i][j];

        if (alphabet_used[26*i+j] == 'N') printf("("); else printf(" ");

        zscii_to_text(chartext, c);
        printf("%s", chartext);

        if (alphabet_used[26*i+j] == 'N') printf(")"); else printf(" ");
    }
    printf("\n");
}

extern void show_dictionary(void)
{   printf("Dictionary contains %d entries:\n",dict_entries);
    if (dict_entries != 0)
    {   d_show_total = 0; d_show_to = NULL; 
        if (!glulx_mode)    
            recursively_show_z(root);
        else
            recursively_show_g(root);
    }
    printf("\nZ-machine alphabet entries:\n");
    show_alphabet(0);
    show_alphabet(1);
    show_alphabet(2);
}

extern void write_dictionary_to_transcript(void)
{   char d_buffer[81];

    sprintf(d_buffer, "\n[Dictionary contains %d entries:]\n", dict_entries);

    d_buffer[0] = 0; write_to_transcript_file(d_buffer);

    if (dict_entries != 0)
    {   d_show_total = 0; d_show_to = d_buffer; 
        if (!glulx_mode)    
            recursively_show_z(root);
        else
            recursively_show_g(root);
    }
    if (d_show_total != 0) write_to_transcript_file(d_buffer);
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_text_vars(void)
{   int j;
    bestyet = NULL;
    bestyet2 = NULL;
    tlbtab = NULL;
    grandtable = NULL;
    grandflags = NULL;
    no_chars_transcribed = 0;
    is_abbreviation = FALSE;
    put_strings_in_low_memory = FALSE;

    for (j=0; j<256; j++) abbrevs_lookup[j] = -1;

    total_zchars_trans = 0;

    dtree = NULL;
    final_dict_order = NULL;
    dict_sort_codes = NULL;
    dict_entries=0;

    initialise_memory_block(&static_strings_area);
}

extern void text_begin_pass(void)
{   abbrevs_lookup_table_made = FALSE;
    no_abbreviations=0;
    total_chars_trans=0; total_bytes_trans=0;
    if (store_the_text) all_text_top=all_text;
    dictionary_begin_pass();
    low_strings_top = low_strings;

    static_strings_extent = 0;
    no_strings = 0;
    no_dynamic_strings = 0;
    no_unicode_chars = 0;
}

/*  Note: for allocation and deallocation of all_the_text, see inform.c      */

extern void text_allocate_arrays(void)
{   abbreviations_at = my_malloc(MAX_ABBREVS*MAX_ABBREV_LENGTH,
        "abbreviations");
    abbrev_values    = my_calloc(sizeof(int), MAX_ABBREVS, "abbrev values");
    abbrev_quality   = my_calloc(sizeof(int), MAX_ABBREVS, "abbrev quality");
    abbrev_freqs     = my_calloc(sizeof(int),   MAX_ABBREVS, "abbrev freqs");

    dtree            = my_calloc(sizeof(dict_tree_node), MAX_DICT_ENTRIES,
                                 "red-black tree for dictionary");
    final_dict_order = my_calloc(sizeof(int),  MAX_DICT_ENTRIES,
                                 "final dictionary ordering table");
    dict_sort_codes  = my_calloc(DICT_WORD_BYTES, MAX_DICT_ENTRIES,
                                 "dictionary sort codes");

    if (!glulx_mode)
        dictionary = my_malloc(9*MAX_DICT_ENTRIES+7,
            "dictionary");
    else
        dictionary = my_malloc(DICT_ENTRY_BYTE_LENGTH*MAX_DICT_ENTRIES+4,
            "dictionary");

    strings_holding_area
         = my_malloc(MAX_STATIC_STRINGS,"static strings holding area");
    low_strings = my_malloc(MAX_LOW_STRINGS,"low (abbreviation) strings");

    huff_entities = NULL;
    hufflist = NULL;
    unicode_usage_entries = NULL;
    done_compression = FALSE;
    compression_table_size = 0;
    compressed_offsets = NULL;

    MAX_CHARACTER_SET = 0;

    if (glulx_mode) {
      if (compression_switch) {
        int ix;
        MAX_CHARACTER_SET = 257 + MAX_ABBREVS + MAX_DYNAMIC_STRINGS 
          + MAX_UNICODE_CHARS;
        huff_entities = my_calloc(sizeof(huffentity_t), MAX_CHARACTER_SET*2+1, 
          "huffman entities");
        hufflist = my_calloc(sizeof(huffentity_t *), MAX_CHARACTER_SET, 
          "huffman node list");
        unicode_usage_entries = my_calloc(sizeof(unicode_usage_t), 
          MAX_UNICODE_CHARS, "unicode entity entries");
        for (ix=0; ix<UNICODE_HASH_BUCKETS; ix++)
          unicode_usage_hash[ix] = NULL;
      }
      compressed_offsets = my_calloc(sizeof(int32), MAX_NUM_STATIC_STRINGS,
        "static strings index table");
    }
}

extern void text_free_arrays(void)
{
    my_free(&strings_holding_area, "static strings holding area");
    my_free(&low_strings, "low (abbreviation) strings");
    my_free(&abbreviations_at, "abbreviations");
    my_free(&abbrev_values,    "abbrev values");
    my_free(&abbrev_quality,   "abbrev quality");
    my_free(&abbrev_freqs,     "abbrev freqs");

    my_free(&dtree,            "red-black tree for dictionary");
    my_free(&final_dict_order, "final dictionary ordering table");
    my_free(&dict_sort_codes,  "dictionary sort codes");

    my_free(&dictionary,"dictionary");

    my_free(&compressed_offsets, "static strings index table");
    my_free(&hufflist, "huffman node list");
    my_free(&huff_entities, "huffman entities");
    my_free(&unicode_usage_entries, "unicode entity entities");

    deallocate_memory_block(&static_strings_area);
}

extern void ao_free_arrays(void)
{   my_free (&tlbtab,"tlb table");
    my_free (&sub_buffer,"sub_buffer");
    my_free (&bestyet,"bestyet");
    my_free (&bestyet2,"bestyet2");
    my_free (&grandtable,"grandtable");
    my_free (&grandflags,"grandflags");
}

/* ========================================================================= */
