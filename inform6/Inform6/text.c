/* ------------------------------------------------------------------------- */
/*   "text" : Text translation, the abbreviations optimiser, the dictionary  */
/*                                                                           */
/*   Part of Inform 6.44                                                     */
/*   copyright (c) Graham Nelson 1993 - 2025                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

uchar *low_strings;                    /* Allocated to low_strings_top       */
int32 low_strings_top;
static memory_list low_strings_memlist;

int32 static_strings_extent;           /* Number of bytes of static strings
                                          made so far */
uchar *static_strings_area;            /* Used to hold the static strings
                                          area so far
                                          Allocated to static_strings_extent */
memory_list static_strings_area_memlist;

static char *all_text;                 /* Text buffer holding the entire text
                                          of the game, when it is being
                                          recorded
                                          (Allocated to all_text_top) */
static memory_list all_text_memlist;
static int32 all_text_top;

int abbrevs_lookup_table_made,         /* The abbreviations lookup table is
                                          constructed when the first non-
                                          abbreviation string is translated:
                                          this flag is TRUE after that       */
    abbrevs_lookup[256];               /* Once this has been constructed,
                                          abbrevs_lookup[n] = the smallest
                                          number of any abbreviation beginning
                                          with ASCII character n, or -1
                                          if none of the abbreviations do    */
int no_abbreviations;                  /* No of abbreviations defined so far */
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
                                          is equal to compression_table_size).
                                          Allocated to no_strings at
                                          compress_game_text() time.         */
static memory_list compressed_offsets_memlist;

unicode_usage_t *unicode_usage_entries; /* Allocated to no_unicode_chars     */
static memory_list unicode_usage_entries_memlist;

#define UNICODE_HASH_BUCKETS (64)
static int unicode_usage_hash[UNICODE_HASH_BUCKETS];

static int unicode_entity_index(int32 unicode);

/* ------------------------------------------------------------------------- */
/*   Abbreviation arrays                                                     */
/* ------------------------------------------------------------------------- */

abbreviation *abbreviations;             /* Allocated up to no_abbreviations */
static memory_list abbreviations_memlist;

/* Memory to hold the text of any abbreviation strings declared.             */
static int32 abbreviations_totaltext;
static char *abbreviations_text;  /* Allocated up to abbreviations_totaltext */
static memory_list abbreviations_text_memlist;

static int *abbreviations_optimal_parse_schedule;
static memory_list abbreviations_optimal_parse_schedule_memlist;

static int *abbreviations_optimal_parse_scores;
static memory_list abbreviations_optimal_parse_scores_memlist;

/* ------------------------------------------------------------------------- */

int32 total_chars_trans,               /* Number of ASCII chars of text in   */
      total_bytes_trans,               /* Number of bytes of Z-code text out */
      zchars_trans_in_last_string;     /* Number of Z-chars in last string:
                                          needed only for abbrev efficiency
                                          calculation in "directs.c"         */
static int32 total_zchars_trans;       /* Number of Z-chars of text out
                                          (only used to calculate the above) */

static int zchars_out_buffer[3],       /* During text translation, a buffer of
                                          3 Z-chars at a time: when it's full
                                          these are written as a 2-byte word */
           zob_index;                  /* Index (0 to 2) into it             */

uchar *translated_text;                /* Area holding translated strings
                                          until they are moved into the
                                          static_strings_area below */
static memory_list translated_text_memlist;

static char *temp_symbol;              /* Temporary symbol name used while
                                          processing "@(...)".               */
static memory_list temp_symbol_memlist;


static int32 text_out_pos;             /* The "program counter" during text
                                          translation: the next position to
                                          write Z-coded text output to       */

static int32 text_out_limit;           /* The upper limit of text_out_pos
                                          during text translation (or -1
                                          for no limit)                      */

static int text_out_overflow;          /* During text translation, becomes
                                          true if text_out_pos tries to pass
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
{   int bubble_sort, j, k;
    char *p1, *p2;
    do
    {   bubble_sort = FALSE;
        for (j=0; j<no_abbreviations; j++)
            for (k=j+1; k<no_abbreviations; k++)
            {   p1=abbreviation_text(j);
                p2=abbreviation_text(k);
                if (strcmp(p1,p2)<0)
                {
                    abbreviation temp = abbreviations[j];
                    abbreviations[j] = abbreviations[k];
                    abbreviations[k] = temp;
                    bubble_sort = TRUE;
                }
            }
    } while (bubble_sort);

    for (j=no_abbreviations-1; j>=0; j--)
    {   p1=abbreviation_text(j);
        abbrevs_lookup[(uchar)p1[0]]=j;
        abbreviations[j].freq=0;
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

static int try_abbreviations_from(uchar *text, int i, int from)
{   int j, k; uchar *p, c;
    c=text[i];
    for (j=from;
         j<no_abbreviations;
         j++)
    {
        p=(uchar *)abbreviations_text+abbreviations[j].textpos;
        if (c != p[0]) break;
        if (text[i+1]==p[1])
        {   for (k=2; p[k]!=0; k++)
                if (text[i+k]!=p[k]) goto NotMatched;
            if (!glulx_mode) {
                for (k=0; p[k]!=0; k++) text[i+k]=1;
            }
            abbreviations[j].freq++;
            return(j);
            NotMatched: ;
        }
    }
    return(-1);
}

/* Create an abbreviation. */
extern void make_abbreviation(char *text)
{
    int alen;
    int32 pos;
    
    /* If -e mode is off, we won't waste space creating an abbreviation entry. */
    if (!economy_switch)
        return;

    alen = strlen(text);
    pos = abbreviations_totaltext;
    
    ensure_memory_list_available(&abbreviations_memlist, no_abbreviations+1);
    ensure_memory_list_available(&abbreviations_text_memlist, pos+alen+1);

    strcpy(abbreviations_text+pos, text);
    abbreviations_totaltext += (alen+1);

    abbreviations[no_abbreviations].textpos = pos;
    abbreviations[no_abbreviations].textlen = alen;
    abbreviations[no_abbreviations].value = compile_string(text, STRCTX_ABBREV);
    abbreviations[no_abbreviations].freq = 0;

    /*   The quality is the number of Z-chars saved by using this            */
    /*   abbreviation: note that it takes 2 Z-chars to print it.             */

    abbreviations[no_abbreviations].quality = zchars_trans_in_last_string - 2;

    if (abbreviations[no_abbreviations].quality <= 0) {
        warning_named("Abbreviation does not save any characters:", text);
    }
    
    no_abbreviations++;
}

/* Return a pointer to the (uncompressed) abbreviation text.
   This should be treated as temporary; it is only valid until the next
   make_abbreviation() call. */
extern char *abbreviation_text(int num)
{
    if (num < 0 || num >= no_abbreviations) {
        compiler_error("Invalid abbrev for abbreviation_text()");
        return "";
    }
    
    return abbreviations_text + abbreviations[num].textpos;
}

/* ------------------------------------------------------------------------- */
/*   The front end routine for text translation.                             */
/*   strctx indicates the purpose of the string. This is mostly used for     */
/*   informational output (gametext.txt), but we treat some string contexts  */
/*   specially during compilation.                                           */
/* ------------------------------------------------------------------------- */

/* TODO: When called from a print statement (parse_print()), it would be
   nice to detect if the generated string is exactly one character. In that
   case, we could return the character value and a flag to indicate the
   caller could use @print_char/@streamchar/@new_line/@streamunichar
   instead of printing a compiled string.

   We'd need a new STRCTX value or two to distinguish direct-printed strings
   from referenceable strings.

   Currently, parse_print() checks for the "^" case manually, which is a
   bit icky. */   
   
extern int32 compile_string(char *b, int strctx)
{   int32 i, j, k;
    uchar *c;
    int in_low_memory;

    if (execution_never_reaches_here) {
        /* No need to put strings into gametext.txt or the static/low
           strings areas. */
        if (strctx == STRCTX_GAME || strctx == STRCTX_GAMEOPC || strctx == STRCTX_LOWSTRING || strctx == STRCTX_INFIX) {
            /* VENEER and VENEEROPC are only used at the translate_text level,
               so we don't have to catch them here. */
            return 0;
        }
    }
    
    /* In Z-code, abbreviations go in the low memory pool (0x100). So
       do strings explicitly defined with the Lowstring directive.
       (In Glulx, the in_low_memory flag is ignored.) */
    in_low_memory = (strctx == STRCTX_ABBREV || strctx == STRCTX_LOWSTRING);

    if (!glulx_mode && in_low_memory)
    {
        k = translate_text(-1, b, strctx);
        if (k<0) {
            error("text translation failed");
            k = 0;
        }
        ensure_memory_list_available(&low_strings_memlist, low_strings_top+k);
        memcpy(low_strings+low_strings_top, translated_text, k);
        j = low_strings_top;
        low_strings_top += k;
        return(0x21+(j/2));
    }

    if (glulx_mode && done_compression)
        compiler_error("Tried to add a string after compression was done.");

    i = translate_text(-1, b, strctx);
    if (i < 0) {
        error("text translation failed");
        i = 0;
    }

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
            ensure_memory_list_available(&translated_text_memlist, i+2);
            translated_text[i++] = 0;
            translated_text[i++] = 0;
        }
    }

    j = static_strings_extent;

    ensure_memory_list_available(&static_strings_area_memlist, static_strings_extent+i);
    for (c=translated_text; c<translated_text+i;
         c++, static_strings_extent++)
        static_strings_area[static_strings_extent] = *c;

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
    
    if (text_out_limit >= 0) {
        if (text_out_pos+2 > text_out_limit) {
            text_out_overflow = TRUE;
            return;
        }
    }
    else {
        ensure_memory_list_available(&translated_text_memlist, text_out_pos+2);
    }
    
    translated_text[text_out_pos++] = j/256; translated_text[text_out_pos++] = j%256;
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
{
    zchars_trans_in_last_string=total_zchars_trans-zchars_trans_in_last_string;
    while (zob_index!=0) write_z_char_z(5);
    if (text_out_pos < 2) {
        /* Something went wrong. */
        text_out_overflow = TRUE;
        return;
    }
    translated_text[text_out_pos-2] += 128;
}

/* Glulx handles this much more simply -- compression is done elsewhere. */
static void write_z_char_g(int i)
{
    ASSERT_GLULX();
    if (text_out_limit >= 0) {
        if (text_out_pos+1 > text_out_limit) {
            text_out_overflow = TRUE;
            return;
        }
    }
    else {
        ensure_memory_list_available(&translated_text_memlist, text_out_pos+1);
    }
    total_zchars_trans++;
    translated_text[text_out_pos++] = i;
    total_bytes_trans++;  
}

/* Helper routine to compute the weight, in units, of a character handled by the Z-Machine */
static int zchar_weight(int c)
{
    int lookup;
    if (c == ' ') return 1;
    lookup = iso_to_alphabet_grid[c];
    if (lookup < 0) return 4;
    if (lookup < 26) return 1;
    return 2;
}

/* ------------------------------------------------------------------------- */
/*   The main routine "text.c" provides to the rest of Inform: the text      */
/*   translator. s_text is the source text and the return value is the       */
/*   number of bytes translated.                                             */
/*   The translated text will be stored in translated_text.                  */
/*                                                                           */
/*   If p_limit is >= 0, the text length will not exceed that many bytes.    */
/*   If the translation tries to overflow this boundary, the return value    */
/*   will be -1. (You should display an error and not read translated_text.) */
/*                                                                           */
/*   If p_limit is negative, any amount of text is accepted (up to int32     */
/*   anyway).                                                                */
/*                                                                           */
/*   Note that the source text may be corrupted by this routine.             */
/* ------------------------------------------------------------------------- */

extern int32 translate_text(int32 p_limit, char *s_text, int strctx)
{   int i, j, k, in_alphabet, lookup_value, is_abbreviation;
    int32 unicode; int zscii;
    uchar *text_in;

    if (p_limit >= 0) {
        ensure_memory_list_available(&translated_text_memlist, p_limit);
    }
    
    /* For STRCTX_ABBREV, the string being translated is itself an
       abbreviation string, so it can't make use of abbreviations. Set
       the is_abbreviation flag to indicate this.
       The compiler has historically set this flag for the Lowstring
       directive as well -- the in_low_memory and is_abbreviation flag were
       always the same. I am preserving that convention. */
    is_abbreviation = (strctx == STRCTX_ABBREV || strctx == STRCTX_LOWSTRING);


    /*  Cast the input and output streams to unsigned char: text_out_pos will
        advance as bytes of Z-coded text are written, but text_in doesn't    */

    text_in     = (uchar *) s_text;
    text_out_pos = 0;
    text_out_limit = p_limit;
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

    /*  If we're storing the whole game text to memory, then add this text.
        We will put two newlines between each text and four at the very end.
        (The optimise code does a lot of sloppy text[i+2], so the extra
        two newlines past all_text_top are necessary.) */

    if ((!is_abbreviation) && (store_the_text))
    {   int addlen = strlen(s_text);
        ensure_memory_list_available(&all_text_memlist, all_text_top+addlen+5);
        sprintf(all_text+all_text_top, "%s\n\n\n\n", s_text);
        /* Advance past two newlines. */
        all_text_top += (addlen+2);
    }

    if (transcript_switch) {
        /* Omit veneer strings, unless we're using the new transcript format, which includes everything. */
        if ((!veneer_mode) || TRANSCRIPT_FORMAT == 1) {
            int label = strctx;
            if (veneer_mode) {
                if (label == STRCTX_GAME)
                    label = STRCTX_VENEER;
                else if (label == STRCTX_GAMEOPC)
                    label = STRCTX_VENEEROPC;
            }
            write_to_transcript_file(s_text, label);
        }
    }
    
    /* Computing the optimal way to parse strings to insert abbreviations with dynamic programming */
    /*  (ref: R.A. Wagner , "Common phrases and minimum-space text storage", Commun. ACM, 16 (3) (1973)) */
    /* We compute this optimal way here; it's stored in abbreviations_optimal_parse_schedule */
    if (economy_switch)
    {   
        uchar *q, c;
        int l, min_score, from;
        int text_in_length;

        text_in_length = strlen( (char*) text_in);
        ensure_memory_list_available(&abbreviations_optimal_parse_schedule_memlist, text_in_length);
        ensure_memory_list_available(&abbreviations_optimal_parse_scores_memlist, text_in_length+1);
        
        abbreviations_optimal_parse_scores[text_in_length] = 0;
        for(j=text_in_length-1; j>=0; j--)
        {   /* Initial values: empty schedule, score = just write the letter without abbreviating. */
            abbreviations_optimal_parse_schedule[j] = -1;
            min_score = zchar_weight(text_in[j]) + abbreviations_optimal_parse_scores[j+1];
            /* If there's an abbreviation starting with that letter... */
            if ( (from = abbrevs_lookup[text_in[j]]) != -1)
            {
                c = text_in[j];
                /* Loop on all abbreviations starting with what is in c. */
                for (k=from;
                     k<no_abbreviations;
                     k++)
                {
                    q=(uchar *)abbreviations_text+abbreviations[k].textpos;
                    if (c!=q[0]) break;
                    /* Let's compare; we also keep track of the length of the abbreviation. */
                    for (l=1; q[l]!=0; l++)
                    {    if (text_in[j+l]!=q[l]) {goto NotMatched;}
                    }
                    /* We have a match (length l), but is it smaller in size? */
                    if (min_score > 2 + abbreviations_optimal_parse_scores[j+l])
                    {   /* It is indeed smaller, so let's write it down in our schedule. */
                        min_score = 2 + abbreviations_optimal_parse_scores[j+l];
                        abbreviations_optimal_parse_schedule[j] = k;
                    }
                    NotMatched: ;
                }
            }
            /* We gave it our best, this is the smallest we got. */
            abbreviations_optimal_parse_scores[j] = min_score;
        }
    }


    
    if (!glulx_mode) {

        /*  The empty string of Z-text is illegal, since it can't carry an end
            bit: so we translate an empty string of ASCII text to just the
            pad character 5.  Printing this causes nothing to appear on screen. */
    
        if (text_in[0]==0) write_z_char_z(5);
    
        /*  Loop through the characters of the null-terminated input text: note
            that if 1 is written over a character in the input text, it is
            afterwards ignored  */
    
        for (i=0; text_in[i]!=0; i++)
        {   total_chars_trans++;
    
            /*  Contract ".  " into ". " if double-space-removing switch set:
                likewise "?  " and "!  " if the setting is high enough */
    
            if ((double_space_setting >= 1)
                && (text_in[i+1]==' ') && (text_in[i+2]==' '))
            {   if (text_in[i]=='.') text_in[i+2]=1;
                if (double_space_setting >= 2)
                {   if (text_in[i]=='?') text_in[i+2]=1;
                    if (text_in[i]=='!') text_in[i+2]=1;
                }
            }
    
            /*  Try abbreviations if the economy switch set. */
            /*  Look at the abbreviation schedule to see if we should abbreviate here. */
            /*  Note: Just because the schedule has something doesn't mean we should abbreviate there; */
            /*  sometimes you abbreviate before because it's better. If we have already replaced the */
            /*  char by a '1', it means we're in the middle of an abbreviation; don't try to abbreviate then. */
            if ((economy_switch) && (!is_abbreviation) && text_in[i] != 1 &&
                ((j = abbreviations_optimal_parse_schedule[i]) != -1))
            {
                /* Fill with 1s, which will get ignored by everyone else. */
                uchar *p = (uchar *)abbreviation_text(j);
                for (k=0; p[k]!=0; k++) text_in[i+k]=1;
                /* Actually write the abbreviation in the story file. */
                abbreviations[j].freq++;
                /* Abbreviations run from MAX_DYNAMIC_STRINGS to 96. */
                j += MAX_DYNAMIC_STRINGS;
                write_z_char_z(j/32+1); write_z_char_z(j%32);
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
    
                    @@decimalnumber  :  write this ZSCII char (0 to 1023)
                    @twodigits or    :  write the abbreviation string with this
                    @(digits)           decimal number
                    @(symbol)        :  write the abbreviation string with this
                                        (constant) value
                    @accentcode      :  this accented character: e.g.,
                                            for @'e write an E-acute
                    @{...}           :  this Unicode char (in hex)          */
    
            if (text_in[i]=='@')
            {   if (text_in[i+1]=='@')
                {
                    /*   @@... (ascii value)  */
    
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
                    while (isdigit(text_in[i])) i++;
                    i--;
                }
                else if (text_in[i+1]=='(')
                {
                    /*   @(...) (dynamic string)   */
                    int len = 0, digits = 0;
                    i += 2;
                    /* This accepts "12xyz" as a symbol, which it really isn't,
                       but that just means it won't be found. */
                    while ((text_in[i] == '_' || isalnum(text_in[i]))) {
                        char ch = text_in[i++];
                        if (isdigit(ch)) digits++;
                        ensure_memory_list_available(&temp_symbol_memlist, len+1);
                        temp_symbol[len++] = ch;
                    }
                    ensure_memory_list_available(&temp_symbol_memlist, len+1);
                    temp_symbol[len] = '\0';
                    j = -1;
                    /* We would like to parse temp_symbol as *either* a decimal
                       number or a constant symbol. */
                    if (text_in[i] != ')' || len == 0) {
                        error("'@(...)' abbreviation must contain a symbol");
                    }
                    else if (digits == len) {
                        /* all digits; parse as decimal */
                        j = atoi(temp_symbol);
                    }
                    else {
                        int sym = get_symbol_index(temp_symbol);
                        if (sym < 0 || (symbols[sym].flags & UNKNOWN_SFLAG) || symbols[sym].type != CONSTANT_T || symbols[sym].marker) {
                            error_named("'@(...)' abbreviation expected a known constant value, but contained", temp_symbol);
                        }
                        else {
                            symbols[sym].flags |= USED_SFLAG;
                            j = symbols[sym].value;
                        }
                    }
                    if (!glulx_mode && j >= 96) {
                        error_max_dynamic_strings(j);
                        j = -1;
                    }
                    if (j >= MAX_DYNAMIC_STRINGS) {
                        error_max_dynamic_strings(j);
                        j = -1;
                    }
                    if (j >= 0) {
                        write_z_char_z(j/32+1); write_z_char_z(j%32);
                    }
                    else {
                        write_z_char_z(' '); /* error fallback */
                    }
                }
                else if (isdigit(text_in[i+1])!=0)
                {   int d1, d2;
    
                    /*   @.. (dynamic string)   */
    
                    d1 = character_digit_value[text_in[i+1]];
                    d2 = character_digit_value[text_in[i+2]];
                    if ((d1 == 127) || (d1 >= 10) || (d2 == 127) || (d2 >= 10))
                        error("'@..' must have two decimal digits");
                    else
                    {
                        if (strctx == STRCTX_ABBREV || strctx == STRCTX_LOWSTRING)
                            warning("The Z-machine standard does not allow dynamic strings inside an abbreviation or dynamic string.");
                        j = d1*10 + d2;
                        if (!glulx_mode && j >= 96) {
                            error_max_dynamic_strings(j);
                            j = -1;
                        }
                        if (j >= MAX_DYNAMIC_STRINGS) {
                            /* Shouldn't get here with two digits */
                            error_max_dynamic_strings(j);
                            j = -1;
                        }
                        i+=2;
                        if (j >= 0) {
                            write_z_char_z(j/32+1); write_z_char_z(j%32);
                        }
                        else {
                            write_z_char_z(' '); /* error fallback */
                        }
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
    
        /*  Flush the Z-characters output buffer and set the "end" bit  */
    
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
                char *cx = abbreviation_text(j);
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
                    while (isdigit(text_in[i])) i++;
                    i--;
                }
                else if (text_in[i+1]=='(') {
                    int len = 0, digits = 0;
                    i += 2;
                    /* This accepts "12xyz" as a symbol, which it really isn't,
                       but that just means it won't be found. */
                    while ((text_in[i] == '_' || isalnum(text_in[i]))) {
                        char ch = text_in[i++];
                        if (isdigit(ch)) digits++;
                        ensure_memory_list_available(&temp_symbol_memlist, len+1);
                        temp_symbol[len++] = ch;
                    }
                    ensure_memory_list_available(&temp_symbol_memlist, len+1);
                    temp_symbol[len] = '\0';
                    j = -1;
                    /* We would like to parse temp_symbol as *either* a decimal
                       number or a constant symbol. */
                    if (text_in[i] != ')' || len == 0) {
                        error("'@(...)' abbreviation must contain a symbol");
                    }
                    else if (digits == len) {
                        /* all digits; parse as decimal */
                        j = atoi(temp_symbol);
                    }
                    else {
                        int sym = get_symbol_index(temp_symbol);
                        if (sym < 0 || (symbols[sym].flags & UNKNOWN_SFLAG) || symbols[sym].type != CONSTANT_T || symbols[sym].marker) {
                            error_named("'@(...)' abbreviation expected a known constant value, but contained", temp_symbol);
                        }
                        else {
                            symbols[sym].flags |= USED_SFLAG;
                            j = symbols[sym].value;
                        }
                    }
                    if (j >= MAX_DYNAMIC_STRINGS) {
                        error_max_dynamic_strings(j);
                        j = -1;
                    }
                    if (j+1 >= no_dynamic_strings)
                        no_dynamic_strings = j+1;
                    if (j >= 0) {
                        write_z_char_g('@');
                        write_z_char_g('D');
                        write_z_char_g('A' + ((j >>12) & 0x0F));
                        write_z_char_g('A' + ((j >> 8) & 0x0F));
                        write_z_char_g('A' + ((j >> 4) & 0x0F));
                        write_z_char_g('A' + ((j     ) & 0x0F));
                    }
                    else {
                        write_z_char_g(' '); /* error fallback */
                    }
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
                            error_max_dynamic_strings(j);
                            j = -1;
                        }
                        if (j+1 >= no_dynamic_strings)
                            no_dynamic_strings = j+1;
                        if (j >= 0) {
                            write_z_char_g('@');
                            write_z_char_g('D');
                            write_z_char_g('A' + ((j >>12) & 0x0F));
                            write_z_char_g('A' + ((j >> 8) & 0x0F));
                            write_z_char_g('A' + ((j >> 4) & 0x0F));
                            write_z_char_g('A' + ((j     ) & 0x0F));
                        }
                        else {
                            write_z_char_g(' '); /* error fallback */
                        }
                    }
                }
                else {
                    unicode = text_to_unicode((char *) (text_in+i));
                    i += textual_form_length - 1;
                    if (unicode == '@' || unicode == '\0') {
                        write_z_char_g('@');
                        write_z_char_g(unicode ? '@' : '0');
                    }
                    else if (unicode >= 0 && unicode < 256) {
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
        zchars_trans_in_last_string=total_zchars_trans-zchars_trans_in_last_string;

    }

    if (text_out_overflow)
        return -1;
    else
        return text_out_pos;
}

static int unicode_entity_index(int32 unicode)
{
    int j;
    int buck = unicode % UNICODE_HASH_BUCKETS;

    for (j = unicode_usage_hash[buck]; j >= 0; j=unicode_usage_entries[j].next) {
        if (unicode_usage_entries[j].ch == unicode)
            break;
    }
    if (j < 0) {
        ensure_memory_list_available(&unicode_usage_entries_memlist, no_unicode_chars+1);
        j = no_unicode_chars++;
        unicode_usage_entries[j].ch = unicode;
        unicode_usage_entries[j].next = unicode_usage_hash[buck];
        unicode_usage_hash[buck] = j;
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
    int max_char_set;
    huffbitlist_t bits;

    if (compression_switch) {
        max_char_set = 257 + no_abbreviations + no_dynamic_strings + no_unicode_chars;

        huff_entities = my_calloc(sizeof(huffentity_t), max_char_set*2+1, 
                                  "huffman entities");
        hufflist = my_calloc(sizeof(huffentity_t *), max_char_set, 
                             "huffman node list");

        /* How many entities have we currently got? Well, 256 plus the
           string-terminator plus Unicode chars plus abbreviations plus
           dynamic strings. */
        entities = 256+1;
        huff_unicode_start = entities;
        entities += no_unicode_chars;
        huff_abbrev_start = entities;
        if (economy_switch)
            entities += no_abbreviations;
        huff_dynam_start = entities;
        entities += no_dynamic_strings;

        if (entities > max_char_set)
            compiler_error("Too many entities for max_char_set");

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
        huff_dynam_start = 257+no_abbreviations;
        compression_table_size = 0;
    }

    if (compression_switch) {

        for (lx=0, ix=0; lx<no_strings; lx++) {
            int escapelen=0, escapetype=0;
            int done=FALSE;
            int32 escapeval=0;
            while (!done) {
                ch = static_strings_area[ix];
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

    ensure_memory_list_available(&compressed_offsets_memlist, no_strings);

    for (lx=0, ix=0; lx<no_strings; lx++) {
        int escapelen=0, escapetype=0;
        int done=FALSE;
        int32 escapeval=0;
        jx = 0; 
        compressed_offsets[lx] = compression_table_size + compression_string_size;
        compression_string_size++; /* for the type byte */
        while (!done) {
            ch = static_strings_area[ix];
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
        cx = abbreviation_text(ent->u.val);
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

/* The complete game text. */
static char *opttext;
static int32 opttextlen;

typedef struct tlb_s
{   char text[4];
    int32 intab, occurrences;
} tlb;
static tlb *tlbtab; /* Three-letter blocks (allocated up to no_occs) */
static memory_list tlbtab_memlist;
static int32 no_occs;

static int32 *grandtable;
static int32 *grandflags;
typedef struct optab_s
{   int32  length;
    int32  popularity;
    int32  score;
    int32  location;
    char  *text; /* allocated to textsize, min 4 */
    int32  textsize;
} optab;
static int32 MAX_BESTYET;
static optab *bestyet; /* High-score entries (up to MAX_BESTYET used/allocated) */
static optab *bestyet2; /* The selected entries (up to selected used; allocated to MAX_ABBREVS) */

static void optab_copy(optab *dest, const optab *src)
{
    dest->length = src->length;
    dest->popularity = src->popularity;
    dest->score = src->score;
    dest->location = src->location;
    if (src->length+1 > dest->textsize) {
        int32 oldsize = dest->textsize;
        dest->textsize = (src->length+1)*2;
        my_realloc(&dest->text, oldsize, dest->textsize, "bestyet2.text");
    }
    strcpy(dest->text, src->text);
}

static int pass_no;

static void optimise_pass(void)
{
    TIMEVALUE t1, t2;
    float duration;
    int32 i;
    int32 j, j2, k, nl, matches, noflags, score, min, minat=0, x, scrabble, c;
    for (i=0; i<MAX_BESTYET; i++) bestyet[i].length=0;
    for (i=0; i<no_occs; i++)
    {   if ((*(tlbtab[i].text)!=(int) '\n')&&(tlbtab[i].occurrences!=0))
        {
#ifdef MAC_FACE
            if (i%((**g_pm_hndl).linespercheck) == 0)
            {   ProcessEvents (&g_proc);
                if (g_proc != true)
                {   ao_free_arrays();
                    longjmp (g_fallback, 1);
                }
            }
#endif
            if (optabbrevs_trace_setting >= 2) {
                printf("Pass %d, %4ld/%ld '%s' (%ld occurrences) ",
                    pass_no, (long int) i, (long int) no_occs, tlbtab[i].text,
                    (long int) tlbtab[i].occurrences);
            }
            TIMEVALUE_NOW(&t1);
            for (j=0; j<tlbtab[i].occurrences; j++)
            {   for (j2=0; j2<tlbtab[i].occurrences; j2++) grandflags[j2]=1;
                nl=2; noflags=tlbtab[i].occurrences;
                while (noflags>=2)
                {   nl++;
                    for (j2=0; j2<nl; j2++)
                        if (opttext[grandtable[tlbtab[i].intab+j]+j2]=='\n')
                            goto FinishEarly;
                    matches=0;
                    for (j2=j; j2<tlbtab[i].occurrences; j2++)
                    {   if (grandflags[j2]==1)
                        {   x=grandtable[tlbtab[i].intab+j2]
                              - grandtable[tlbtab[i].intab+j];
                         if (((x>-nl)&&(x<nl))
                            || (memcmp(opttext+grandtable[tlbtab[i].intab+j],
                                       opttext+grandtable[tlbtab[i].intab+j2],
                                       nl)!=0))
                            {   grandflags[j2]=0; noflags--; }
                            else matches++;
                        }
                    }
                    scrabble=0;
                    for (k=0; k<nl; k++)
                    {   scrabble++;
                        c=opttext[grandtable[tlbtab[i].intab+j+k]];
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
                    for (j2=0; j2<MAX_BESTYET; j2++)
                    {   if ((nl==bestyet[j2].length)
                                && (memcmp(opttext+bestyet[j2].location,
                                       opttext+grandtable[tlbtab[i].intab+j],
                                       nl)==0))
                        {   j2=MAX_BESTYET; min=score; }
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
                    }
                }
                FinishEarly: ;
            }
            if (optabbrevs_trace_setting >= 2) {
                TIMEVALUE_NOW(&t2);
                duration = TIMEVALUE_DIFFERENCE(&t1, &t2);
                printf(" (%.4f seconds)\n", duration);
            }
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

extern void optimise_abbreviations(void)
{   int32 i, j, tcount, max=0, MAX_GTABLE;
    int32 j2, selected, available, maxat=0, nl;

    if (opttext == NULL)
        return;

    /* We insist that the first two abbreviations will be ". " and ", ". */
    if (MAX_ABBREVS < 2)
        return;

    /* Note that it's safe to access opttext[opttextlen+2]. There are
       two newlines and a null beyond opttextlen. */
    
    printf("Beginning calculation of optimal abbreviations...\n");

    pass_no = 0;

    initialise_memory_list(&tlbtab_memlist,
        sizeof(tlb), 1000, (void**)&tlbtab,
        "three-letter-blocks buffer");
    
    no_occs=0;

    /* Not sure what the optimal size is for MAX_BESTYET. The original code always created 64 abbreviations and used MAX_BESTYET=256. I'm guessing that 4*MAX_ABBREVS is reasonable. */
    MAX_BESTYET = 4 * MAX_ABBREVS;
    
    bestyet=my_calloc(sizeof(optab), MAX_BESTYET, "bestyet");
    for (i=0; i<MAX_BESTYET; i++) {
        bestyet[i].length = 0;
        bestyet[i].popularity = 0;
        bestyet[i].score = 0;
        bestyet[i].location = 0;
        bestyet[i].textsize = 4;
        bestyet[i].text = my_malloc(bestyet[i].textsize, "bestyet.text");
    }

    bestyet2=my_calloc(sizeof(optab), MAX_ABBREVS, "bestyet2");
    for (i=0; i<MAX_ABBREVS; i++) {
        bestyet2[i].length = 0;
        bestyet2[i].popularity = 0;
        bestyet2[i].score = 0;
        bestyet2[i].location = 0;
        bestyet2[i].textsize = 4;
        bestyet2[i].text = my_malloc(bestyet2[i].textsize, "bestyet2.text");
    }

    bestyet2[0].text[0]='.';
    bestyet2[0].text[1]=' ';
    bestyet2[0].text[2]=0;

    bestyet2[1].text[0]=',';
    bestyet2[1].text[1]=' ';
    bestyet2[1].text[2]=0;

    selected=2;

    for (i=0; i<opttextlen; i++)
    {
        if ((opttext[i]=='.') && (opttext[i+1]==' ') && (opttext[i+2]==' '))
        {   opttext[i]='\n'; opttext[i+1]='\n'; opttext[i+2]='\n';
            bestyet2[0].popularity++;
        }

        if ((opttext[i]=='.') && (opttext[i+1]==' '))
        {   opttext[i]='\n'; opttext[i+1]='\n';
            bestyet2[0].popularity++;
        }

        if ((opttext[i]==',') && (opttext[i+1]==' '))
        {   opttext[i]='\n'; opttext[i+1]='\n';
            bestyet2[1].popularity++;
        }
    }

    MAX_GTABLE=opttextlen+1;
    grandtable=my_calloc(4*sizeof(int32), MAX_GTABLE/4, "grandtable");

    for (i=0, tcount=0; i<opttextlen; i++)
    {
        tlb test;
        test.text[0]=opttext[i];
        test.text[1]=opttext[i+1];
        test.text[2]=opttext[i+2];
        test.text[3]=0;
        if ((test.text[0]=='\n')||(test.text[1]=='\n')||(test.text[2]=='\n'))
            goto DontKeep;
        for (j=0; j<no_occs; j++) {
            if (strcmp(test.text,tlbtab[j].text)==0)
                goto DontKeep;
        }
        test.occurrences=0;
        test.intab=0;
        for (j=i+3; j<opttextlen; j++)
        {
#ifdef MAC_FACE
            if (j%((**g_pm_hndl).linespercheck) == 0)
            {   ProcessEvents (&g_proc);
                if (g_proc != true)
                {   ao_free_arrays();
                    longjmp (g_fallback, 1);
                }
            }
#endif
            if ((opttext[i]==opttext[j])
                 && (opttext[i+1]==opttext[j+1])
                 && (opttext[i+2]==opttext[j+2]))
                 {   grandtable[tcount+test.occurrences]=j;
                     test.occurrences++;
                     if (tcount+test.occurrences==MAX_GTABLE)
                     {   printf("All %ld cross-references used\n",
                             (long int) MAX_GTABLE);
                         goto Built;
                     }
                 }
        }
        if (test.occurrences>=2)
        {
            ensure_memory_list_available(&tlbtab_memlist, no_occs+1);
            tlbtab[no_occs]=test;
            tlbtab[no_occs].intab=tcount;
            tcount += tlbtab[no_occs].occurrences;
            if (max<tlbtab[no_occs].occurrences)
                max=tlbtab[no_occs].occurrences;
            no_occs++;
        }
        DontKeep: ;
    }

    Built:
    grandflags=my_calloc(sizeof(int), max, "grandflags");


    if (optabbrevs_trace_setting >= 1) {
        printf("Cross-reference table (%ld entries) built...\n",
            (long int) no_occs);
    }
    /*  for (i=0; i<no_occs; i++)
            printf("%4d %4d '%s' %d\n",i,tlbtab[i].intab,tlbtab[i].text,
                tlbtab[i].occurrences);
    */

    for (i=0; i<MAX_ABBREVS; i++) bestyet2[i].length=0;
    available=MAX_BESTYET;
    while ((available>0)&&(selected<MAX_ABBREVS))
    {
        pass_no++;
        if (optabbrevs_trace_setting >= 1) {
            printf("Pass %d\n", pass_no);
        }
        
        optimise_pass();
        available=0;
        for (i=0; i<MAX_BESTYET; i++)
            if (bestyet[i].score!=0)
            {   available++;
                nl=bestyet[i].length;
                if (nl+1 > bestyet[i].textsize) {
                    int32 oldsize = bestyet[i].textsize;
                    bestyet[i].textsize = (nl+1)*2;
                    my_realloc(&bestyet[i].text, oldsize, bestyet[i].textsize, "bestyet.text");
                }
                for (j2=0; j2<nl; j2++) bestyet[i].text[j2]=
                    opttext[bestyet[i].location+j2];
                bestyet[i].text[nl]=0;
            }

    /*  printf("End of pass results:\n");
        printf("\nno   score  freq   string\n");
        for (i=0; i<MAX_BESTYET; i++)
            if (bestyet[i].score>0)
                printf("%02d:  %4d   %4d   '%s'\n", i, bestyet[i].score,
                    bestyet[i].popularity, bestyet[i].text);
    */

        do
        {   max=0;
            for (i=0; i<MAX_BESTYET; i++)
                if (max<bestyet[i].score)
                {   max=bestyet[i].score;
                    maxat=i;
                }

            if (max>0)
            {
                char testtext[4];
                optab_copy(&bestyet2[selected++], &bestyet[maxat]);

                if (optabbrevs_trace_setting >= 1) {
                    printf(
                        "Selection %2ld: '%s' (repeated %ld times, scoring %ld)\n",
                        (long int) selected,bestyet[maxat].text,
                        (long int) bestyet[maxat].popularity,
                        (long int) bestyet[maxat].score);
                }

                testtext[0]=bestyet[maxat].text[0];
                testtext[1]=bestyet[maxat].text[1];
                testtext[2]=bestyet[maxat].text[2];
                testtext[3]=0;

                for (i=0; i<no_occs; i++)
                    if (strcmp(testtext,tlbtab[i].text)==0)
                        break;

                for (j=0; j<tlbtab[i].occurrences; j++)
                {   if (memcmp(bestyet[maxat].text,
                               opttext+grandtable[tlbtab[i].intab+j],
                               bestyet[maxat].length)==0)
                    {   for (j2=0; j2<bestyet[maxat].length; j2++)
                            opttext[grandtable[tlbtab[i].intab+j]+j2]='\n';
                    }
                }

                for (i=0; i<MAX_BESTYET; i++)
                    if ((bestyet[i].score>0)&&
                        (any_overlap(bestyet[maxat].text,bestyet[i].text)==1))
                    {   bestyet[i].score=0;
                       /* printf("Discarding '%s' as overlapping\n",
                            bestyet[i].text); */
                    }
            }
        } while ((max>0)&&(available>0)&&(selected<MAX_ABBREVS));
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
/*   For Glulx, the form is instead: (See below about Unicode-valued         */
/*   dictionaries and DICT_WORD_BYTES.)                                      */
/*                                                                           */
/*        <tag>  <plain text>    <flags>  <verbnumber>   <adjectivenumber>   */
/*         $60    DICT_WORD_BYTES short    short          short              */
/*                                                                           */
/*   These records are stored in "accession order" (i.e. in order of their   */
/*   first being received by these routines) and only alphabetically sorted  */
/*   by construct_storyfile() (using the array below).                       */
/* ------------------------------------------------------------------------- */
/*                                                                           */
/*   Further notes about the data fields...                                  */
/*                                                                           */
/*   The flags in the first field are as defined in header.h                 */
/*   (*_DFLAG values).                                                       */
/*                                                                           */
/*   In grammar version 2, the third field (adjectivenumber) is unused (and  */
/*   zero). It may be omitted entirely with the ZCODE_LESS_DICT_DATA option. */
/*                                                                           */
/*   The compiler generates special constants #dict_par1, #dict_par2,        */
/*   #dict_par3 to refer to the byte offsets of the three fields. In         */
/*   Z-code v3, these are 4/5/6; in v4+, they are 6/7/8. In Glulx, they      */
/*   are $DICT_WORD_SIZE+2/4/6, referring to the *low* bytes of the three    */
/*   fields. (The high bytes are $DICT_WORD_SIZE+1/3/5.)                     */
/* ------------------------------------------------------------------------- */

uchar *dictionary;                    /* (These two variables are externally
                                         used only in "tables.c" when
                                         building the story-file)            */
static memory_list dictionary_memlist;
int32 dictionary_top;                 /* Position of the next free record
                                         in dictionary (i.e., the current
                                         number of bytes)                    */

int dict_entries;                     /* Total number of records entered     */

/* ------------------------------------------------------------------------- */
/*   dict_word was originally a typedef for a struct of 6 unsigned chars.    */
/*   It held the (4 or) 6 bytes of Z-coded text of a word.                   */
/*   Usefully, because the PAD character 5 is < all alphabetic characters,   */
/*   alphabetic order corresponds to numeric order.  For this reason, the    */
/*   dict_word is called the "sort code" of the original text word.          */
/*                                                                           */
/*   In modifying the compiler for Glulx, I found it easier to discard the   */
/*   typedef, and operate directly on uchar arrays of length DICT_WORD_SIZE. */
/*   In Z-code, DICT_WORD_SIZE will be 6, so the Z-code compiler will work   */
/*   as before. In Glulx, it can be any value.                               */
/*                                                                           */
/*   In further modifying the compiler to generate a Unicode dictionary,     */
/*   I have to store four-byte values in the uchar array. We make the array  */
/*   size DICT_WORD_BYTES (which is DICT_WORD_SIZE*DICT_CHAR_SIZE).          */
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

static memory_list prepared_sort_memlist;
static uchar *prepared_sort;    /* Holds the sort code of current word */

static int prepared_dictflags_pos;  /* Dict flags set by the current word */
static int prepared_dictflags_neg;  /* Dict flags *not* set by the word */

/* Also used by verbs.c */
static void dictionary_prepare_z(char *dword, uchar *optresult)
{   int i, j, k, k2, wd[13];
    int32 tot;
    int negflag;

    /* A rapid text translation algorithm using only the simplified rules
       applying to the text of dictionary entries: first produce a sequence
       of 6 (v3) or 9 (v4+) Z-characters                                     */

    int dictsize = (version_number==3) ? 6 : 9;

    /* Flag to set if a dict word is truncated. We only do this if
       DICT_TRUNCATE_FLAG, however. */
    int truncflag = (DICT_TRUNCATE_FLAG ? TRUNC_DFLAG : NONE_DFLAG);

    /* Will be set to suppress dict flags if we're past the size limit.
       But only if LONG_DICT_FLAG_BUG. */
    int truncbug = FALSE;

    prepared_dictflags_pos = 0;
    prepared_dictflags_neg = 0;

    for (i=0, j=0; dword[j]!=0; j++)
    {
        if ((dword[j] == '/') && (dword[j+1] == '/'))
        {
            /* The rest of the word is dict flags. Run through them. */
            negflag = FALSE;
            for (j+=2; dword[j] != 0; j++)
            {
                if (truncbug) continue; /* do not set flags */
                switch(dword[j])
                {
                    case '~':
                        if (!dword[j+1])
                            error_named("'//~' with no flag character (psn) in dict word", dword);
                        negflag = !negflag;
                        break;
                    case 'p':
                        if (!negflag)
                            prepared_dictflags_pos |= PLURAL_DFLAG;
                        else
                            prepared_dictflags_neg |= PLURAL_DFLAG;
                        negflag = FALSE;
                        break;
                    case 's':
                        if (!negflag)
                            prepared_dictflags_pos |= SING_DFLAG;
                        else
                            prepared_dictflags_neg |= SING_DFLAG;
                        negflag = FALSE;
                        break;
                    case 'n':
                        if (!negflag)
                            prepared_dictflags_pos |= NOUN_DFLAG;
                        else
                            prepared_dictflags_neg |= NOUN_DFLAG;
                        negflag = FALSE;
                        break;
                    default:
                        error_named("Expected flag character (psn~) after '//' in dict word", dword);
                        break;
                }
            }
            break;
        }

        /* LONG_DICT_FLAG_BUG emulates the old behavior where we stop looping
           at dictsize. */
        if (LONG_DICT_FLAG_BUG && i>=dictsize)
            truncbug = TRUE;

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
            {   /* Use 4 more Z-chars to encode a ZSCII escape sequence.
                   If the last character can't be written, set TRUNC flag. */
                if (i<dictsize)
                    wd[i++] = 5;
                if (i<dictsize)
                    wd[i++] = 6;
                k2 = -k2;
                if (i<dictsize)
                    wd[i++] = k2/32;
                if (i<dictsize)
                    wd[i++] = k2%32;
                else
                    prepared_dictflags_pos |= truncflag;
            }
        }
        else
        {   alphabet_used[k2] = 'Y';
            if ((k2/26)!=0 && i<dictsize)
                wd[i++]=3+(k2/26);            /* Change alphabet for symbols */
            if (i<dictsize)
                wd[i++]=6+(k2%26);            /* Write the Z character       */
            else
                prepared_dictflags_pos |= truncflag;
        }
    }

    if (i > dictsize)
        compiler_error("dict word buffer overflow");

    /* Fill up to the end of the dictionary block with PAD characters
       (for safety, we right-pad to 9 chars even in V3)                      */

    for (; i<9; i++) wd[i]=5;

    /* The array of Z-chars is converted to two or three 2-byte blocks       */
    ensure_memory_list_available(&prepared_sort_memlist, DICT_WORD_BYTES);
    
    tot = wd[2] + wd[1]*(1<<5) + wd[0]*(1<<10);
    prepared_sort[1]=tot%0x100;
    prepared_sort[0]=(tot/0x100)%0x100;
    tot = wd[5] + wd[4]*(1<<5) + wd[3]*(1<<10);
    prepared_sort[3]=tot%0x100;
    prepared_sort[2]=(tot/0x100)%0x100;
    if (version_number==3)
        tot = 0;
    else
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
    int negflag;

    /* Flag to set if a dict word is truncated. We only do this if
       DICT_TRUNCATE_FLAG, however. */
    int truncflag = (DICT_TRUNCATE_FLAG ? TRUNC_DFLAG : NONE_DFLAG);

    /* Will be set to suppress dict flags if we're past the size limit.
       But only if LONG_DICT_FLAG_BUG. */
    int truncbug = FALSE;

    prepared_dictflags_pos = 0;
    prepared_dictflags_neg = 0;

    for (i=0, j=0; (dword[j]!=0); j++) {
        if ((dword[j] == '/') && (dword[j+1] == '/')) {
            /* The rest of the word is dict flags. Run through them. */
            negflag = FALSE;
            for (j+=2; dword[j] != 0; j++) {
                if (truncbug) continue; /* do not set flags */
                switch(dword[j]) {
                case '~':
                    if (!dword[j+1])
                        error_named("'//~' with no flag character (psn) in dict word", dword);
                    negflag = !negflag;
                    break;
                case 'p':
                    if (!negflag)
                        prepared_dictflags_pos |= PLURAL_DFLAG;
                    else
                        prepared_dictflags_neg |= PLURAL_DFLAG;
                    negflag = FALSE;
                    break;
                case 's':
                    if (!negflag)
                        prepared_dictflags_pos |= SING_DFLAG;
                    else
                        prepared_dictflags_neg |= SING_DFLAG;
                    negflag = FALSE;
                    break;
                case 'n':
                    if (!negflag)
                        prepared_dictflags_pos |= NOUN_DFLAG;
                    else
                        prepared_dictflags_neg |= NOUN_DFLAG;
                    negflag = FALSE;
                    break;
                default:
                    error_named("Expected flag character (psn~) after '//' in dict word", dword);
                    break;
                }
            }
            break;
        }

        /* LONG_DICT_FLAG_BUG emulates the old behavior where we stop looping
           at DICT_WORD_SIZE. */
        if (LONG_DICT_FLAG_BUG && i>=DICT_WORD_SIZE)
            truncbug = TRUE;

        k= ((uchar *)dword)[j];
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
    
        if (k >= 'A' && k <= 'Z')
            k += ('a' - 'A');

        ensure_memory_list_available(&prepared_sort_memlist, DICT_WORD_BYTES);
    
        if (DICT_CHAR_SIZE == 1) {
            if (i<DICT_WORD_SIZE)
                prepared_sort[i++] = k;
            else
                prepared_dictflags_pos |= truncflag;          
        }
        else {
            if (i<DICT_WORD_SIZE) {
                prepared_sort[4*i]   = (k >> 24) & 0xFF;
                prepared_sort[4*i+1] = (k >> 16) & 0xFF;
                prepared_sort[4*i+2] = (k >>  8) & 0xFF;
                prepared_sort[4*i+3] = (k)       & 0xFF;
                i++;
            }
            else {
                prepared_dictflags_pos |= truncflag;          
            }
        }
    }

    if (i > DICT_WORD_SIZE)
        compiler_error("dict word buffer overflow");

    /* Right-pad with zeroes */
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

static dict_tree_node *dtree;     /* Allocated to dict_entries */
static memory_list dtree_memlist;

static uchar *dict_sort_codes;  /* Allocated to dict_entries*DICT_WORD_BYTES */
static memory_list dict_sort_codes_memlist;

int   *final_dict_order;          /* Allocated at sort_dictionary() time */

static void dictionary_begin_pass(void)
{
    /*  Leave room for the 7-byte header (added in "tables.c" much later)    */
    /*  Glulx has a 4-byte header instead. */

    if (!glulx_mode)
        dictionary_top = 7;
    else
        dictionary_top = 4;

    ensure_memory_list_available(&dictionary_memlist, dictionary_top);
    
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
{    
    final_dict_order = my_calloc(sizeof(int), dict_entries, "final dictionary ordering table");
    
    if (root != VACANT)
    {   fdo_count = 0; recursively_sort(root);
    }
}

/* ------------------------------------------------------------------------- */
/*   If "dword" is in the dictionary, return its accession number;           */
/*   If not, return -1.                                                      */
/* ------------------------------------------------------------------------- */

extern int dictionary_find(char *dword)
{   int at = root, n;

    dictionary_prepare(dword, NULL);

    while (at != VACANT)
    {   n = compare_sorts(prepared_sort, dict_sort_codes+at*DICT_WORD_BYTES);
        if (n==0) return at;
        if (n>0) at = dtree[at].branch[1]; else at = dtree[at].branch[0];
    }
    return -1;
}

/* ------------------------------------------------------------------------- */
/*  Add "dword" to the dictionary with (flag1,flag2,flag3) as its data       */
/*  fields; unless it already exists, in which case OR the data fields with  */
/*  those flags.                                                             */
/*                                                                           */
/*  These fields are one byte each in Z-code, two bytes each in Glulx.       */
/*                                                                           */
/*  Returns: the accession number.                                           */
/* ------------------------------------------------------------------------- */

extern int dictionary_add(char *dword, int flag1, int flag2, int flag3)
{   int n; uchar *p;
    int ggfr = 0, gfr = 0, fr = 0, r = 0;
    int ggf = VACANT, gf = VACANT, f = VACANT, at = root;
    int a, b;
    int res=((version_number==3)?4:6);

    /* Fill in prepared_sort and prepared_dictflags. */
    dictionary_prepare(dword, NULL);

    /* Adjust flag1 according to prepared_dictflags. */
    flag1 &= (~prepared_dictflags_neg);
    flag1 |= prepared_dictflags_pos;

    if (DICT_IMPLICIT_SINGULAR) {
        /* If we have //n but not //p, that implies //s. Unless //s is
           explicitly forbidden. */
        if ((flag1 & NOUN_DFLAG) && !(flag1 & PLURAL_DFLAG) && !(prepared_dictflags_neg & SING_DFLAG)) {
            flag1 |= SING_DFLAG;
        }
    }

    if (root == VACANT)
    {   root = 0; goto CreateEntry;
    }
    while (TRUE)
    {
        n = compare_sorts(prepared_sort, dict_sort_codes+at*DICT_WORD_BYTES);
        if (n==0)
        {
            if (!glulx_mode) {
                p = dictionary+7 + at*DICT_ENTRY_BYTE_LENGTH + res;
                p[0] |= flag1; p[1] |= flag2;
                if (!ZCODE_LESS_DICT_DATA)
                    p[2] |= flag3;
            }
            else {
                p = dictionary+4 + at*DICT_ENTRY_BYTE_LENGTH + DICT_ENTRY_FLAG_POS;
                p[0] |= (flag1/256); p[1] |= (flag1%256); 
                p[2] |= (flag2/256); p[3] |= (flag2%256); 
                p[4] |= (flag3/256); p[5] |= (flag3%256);
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

    ensure_memory_list_available(&dtree_memlist, dict_entries+1);
    ensure_memory_list_available(&dict_sort_codes_memlist, (dict_entries+1)*DICT_WORD_BYTES);

    dtree[dict_entries].branch[0] = VACANT;
    dtree[dict_entries].branch[1] = VACANT;
    dtree[dict_entries].colour    = BLACK;

    /*  Address in Inform's own dictionary table to write the record to      */

    if (!glulx_mode) {

        ensure_memory_list_available(&dictionary_memlist, dictionary_top + DICT_ENTRY_BYTE_LENGTH);
        p = dictionary + DICT_ENTRY_BYTE_LENGTH*dict_entries + 7;

        /*  So copy in the 4 (or 6) bytes of Z-coded text and the 3 data 
            bytes */

        p[0]=prepared_sort[0]; p[1]=prepared_sort[1];
        p[2]=prepared_sort[2]; p[3]=prepared_sort[3];
        if (version_number > 3)
        {   p[4]=prepared_sort[4]; p[5]=prepared_sort[5]; }
        p[res]=flag1; p[res+1]=flag2;
        if (!ZCODE_LESS_DICT_DATA) p[res+2]=flag3;

        dictionary_top += DICT_ENTRY_BYTE_LENGTH;

    }
    else {
        int i;
        ensure_memory_list_available(&dictionary_memlist, dictionary_top + DICT_ENTRY_BYTE_LENGTH);
        p = dictionary + 4 + DICT_ENTRY_BYTE_LENGTH*dict_entries;
        p[0] = 0x60; /* type byte -- dict word */

        p += DICT_CHAR_SIZE;
        for (i=0; i<DICT_WORD_BYTES; i++)
            p[i] = prepared_sort[i];
        
        p += DICT_WORD_BYTES;
        p[0] = (flag1/256); p[1] = (flag1%256);
        p[2] = (flag2/256); p[3] = (flag2%256);
        p[4] = (flag3/256); p[5] = (flag3%256);
        
        dictionary_top += DICT_ENTRY_BYTE_LENGTH;

    }

    copy_sorts(dict_sort_codes+dict_entries*DICT_WORD_BYTES, prepared_sort);

    return dict_entries++;
}

/* ------------------------------------------------------------------------- */
/*   Used for "Verb" and "Extend ... only", to initially set or renumber a   */
/*   verb-word to a new Inform verb index.                                   */
/*   The verb number is inverted (we count down from $FF/$FFFF) and stored   */
/*   in #dict_par2.                                                          */
/* ------------------------------------------------------------------------- */

extern void dictionary_set_verb_number(int dictword, int infverb)
{
    int flag2 = ((glulx_mode)?(0xffff-infverb):(0xff-infverb));
    if (dictword >= 0 && dictword < dict_entries)
    {
        uchar *p;
        if (!glulx_mode) {
            int res = ((version_number==3)?4:6);
            p=dictionary+7+dictword*DICT_ENTRY_BYTE_LENGTH+res; 
            p[1]=flag2;
        }
        else {
            p=dictionary+4 + dictword*DICT_ENTRY_BYTE_LENGTH + DICT_ENTRY_FLAG_POS; 
            p[2]=flag2/256; p[3]=flag2%256;
        }
    }
}

/* ------------------------------------------------------------------------- */
/*   Tracing code for the dictionary: used by "trace" and text               */
/*   transcription.                                                          */
/* ------------------------------------------------------------------------- */

/* In the dictionary-showing code, if d_show_buf is NULL, the text is
   printed directly. (The "Trace dictionary" directive does this.)
   If d_show_buf is not NULL, we add words to it (reallocing if necessary)
   until it's a page-width. (The -r "gametext.txt" option does this.)
*/
static char *d_show_buf = NULL;
static int d_show_size; /* allocated size */
static int d_show_len;  /* current length */

/* Print a byte to the screen or d_show_buf (see above). The caller
   is responsible for character encoding. */
static void show_char(uchar c)
{
    if (d_show_buf == NULL) {
        printf("%c", c);
    }
    else {
        if (d_show_len+2 >= d_show_size) {
            int newsize = 2 * d_show_len + 16;
            my_realloc(&d_show_buf, d_show_size, newsize, "dictionary display buffer");
            d_show_size = newsize;
        }
        d_show_buf[d_show_len++] = c;
        d_show_buf[d_show_len] = '\0';
    }
}

/* Display a Unicode character in user-readable form. This uses the same
   character encoding as the source code (determined by the -C option). */
static void show_uchar(uint32 c)
{
    char buf[16];
    int ix;
    
    if (c < 0x80) {
        /* ASCII always works */
        show_char(c);
        return;
    }
    if (character_set_unicode) {
        /* UTF-8 the character */
        if (c < 0x80) {
            show_char(c);
        }
        else if (c < 0x800) {
            show_char((0xC0 | ((c & 0x7C0) >> 6)));
            show_char((0x80 |  (c & 0x03F)     ));
        }
        else if (c < 0x10000) {
            show_char((0xE0 | ((c & 0xF000) >> 12)));
            show_char((0x80 | ((c & 0x0FC0) >>  6)));
            show_char((0x80 |  (c & 0x003F)      ));
        }
        else if (c < 0x200000) {
            show_char((0xF0 | ((c & 0x1C0000) >> 18)));
            show_char((0x80 | ((c & 0x03F000) >> 12)));
            show_char((0x80 | ((c & 0x000FC0) >>  6)));
            show_char((0x80 |  (c & 0x00003F)      ));
        }
        else {
            show_char('?');
        }
        return;
    }
    if (character_set_setting == 1 && c < 0x100) {
        /* Fits in Latin-1 */
        show_char(c);
        return;
    }
    /* Supporting other character_set_setting is harder; not currently implemented. */
    
    /* Use the escaped form */
    sprintf(buf, "@{%x}", c);
    for (ix=0; buf[ix]; ix++)
        show_char(buf[ix]);
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
    else
    {
        encoded_word[6] = encoded_word[7] = encoded_word[8] = 0;
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

/* Print a dictionary word to stdout. 
   (This assumes that d_show_buf is null.)
 */
void print_dict_word(int node)
{
    uchar *p;
    int cprinted;
    
    if (!glulx_mode) {
        char textual_form[32];
        p = (uchar *)dictionary + 7 + DICT_ENTRY_BYTE_LENGTH*node;
        
        word_to_ascii(p, textual_form);
        
        for (cprinted = 0; textual_form[cprinted]!=0; cprinted++)
            show_uchar((uchar)textual_form[cprinted]);
    }
    else {
        p = (uchar *)dictionary + 4 + DICT_ENTRY_BYTE_LENGTH*node;
        
        for (cprinted = 0; cprinted<DICT_WORD_SIZE; cprinted++)
        {
            uint32 ch;
            if (DICT_CHAR_SIZE == 1)
                ch = p[1+cprinted];
            else
                ch = (p[4*cprinted+4] << 24) + (p[4*cprinted+5] << 16) + (p[4*cprinted+6] << 8) + (p[4*cprinted+7]);
            if (!ch)
                break;
            show_uchar(ch);
        }
    }
}

static void recursively_show_z(int node, int level)
{   int i, cprinted, flags; uchar *p;
    char textual_form[32];
    int res = (version_number == 3)?4:6; /* byte length of encoded text */

    if (dtree[node].branch[0] != VACANT)
        recursively_show_z(dtree[node].branch[0], level);

    p = (uchar *)dictionary + 7 + DICT_ENTRY_BYTE_LENGTH*node;

    word_to_ascii(p, textual_form);

    for (cprinted = 0; textual_form[cprinted]!=0; cprinted++)
        show_uchar((uchar)textual_form[cprinted]);
    for (; cprinted < 4 + ((version_number==3)?6:9); cprinted++)
        show_char(' ');

    /* The level-1 info can only be printfed (d_show_buf must be null). */
    if (d_show_buf == NULL && level >= 1)
    {
        if (level >= 2) {
            for (i=0; i<DICT_ENTRY_BYTE_LENGTH; i++) printf("%02x ",p[i]);
        }

        flags = (int) p[res];
        if (flags & NOUN_DFLAG)
            printf("noun ");
        else
            printf("     ");
        if (flags & PLURAL_DFLAG)
            printf("p ");
        else
            printf("  ");
        if (flags & SING_DFLAG)
            printf("s ");
        else
            printf("  ");
        if (DICT_TRUNCATE_FLAG) {
            if (flags & TRUNC_DFLAG)
                printf("tr ");
            else
                printf("   ");
        }
        if (flags & PREP_DFLAG)
        {   if (grammar_version_number == 1)
                printf("preposition:%d  ", (int) p[res+2]);
            else
                printf("preposition    ");
        }
        if (flags & META_DFLAG)
            printf("meta");
        if (flags & VERB_DFLAG)
            printf("verb:%d  ", (int) p[res+1]);
        printf("\n");
    }

    /* Show five words per line in classic TRANSCRIPT_FORMAT; one per line in the new format. */
    if (d_show_buf && (d_show_len >= 64 || TRANSCRIPT_FORMAT == 1))
    {
        write_to_transcript_file(d_show_buf, STRCTX_DICT);
        d_show_len = 0;
    }

    if (dtree[node].branch[1] != VACANT)
        recursively_show_z(dtree[node].branch[1], level);
}

static void recursively_show_g(int node, int level)
{   int i, cprinted;
    uchar *p;

    if (dtree[node].branch[0] != VACANT)
        recursively_show_g(dtree[node].branch[0], level);

    p = (uchar *)dictionary + 4 + DICT_ENTRY_BYTE_LENGTH*node;

    for (cprinted = 0; cprinted<DICT_WORD_SIZE; cprinted++)
    {
        uint32 ch;
        if (DICT_CHAR_SIZE == 1)
            ch = p[1+cprinted];
        else
            ch = (p[4*cprinted+4] << 24) + (p[4*cprinted+5] << 16) + (p[4*cprinted+6] << 8) + (p[4*cprinted+7]);
        if (!ch)
            break;
        show_uchar(ch);
    }
    for (; cprinted<DICT_WORD_SIZE+4; cprinted++)
        show_char(' ');

    /* The level-1 info can only be printfed (d_show_buf must be null). */
    if (d_show_buf == NULL && level >= 1)
    {   int flagpos = (DICT_CHAR_SIZE == 1) ? (DICT_WORD_SIZE+1) : (DICT_WORD_BYTES+4);
        int flags = (p[flagpos+0] << 8) | (p[flagpos+1]);
        int verbnum = (p[flagpos+2] << 8) | (p[flagpos+3]);
        if (level >= 2) {
            for (i=0; i<DICT_ENTRY_BYTE_LENGTH; i++) printf("%02x ",p[i]);
        }
        if (flags & NOUN_DFLAG)
            printf("noun ");
        else
            printf("     ");
        if (flags & PLURAL_DFLAG)
            printf("p ");
        else
            printf("  ");
        if (flags & SING_DFLAG)
            printf("s ");
        else
            printf("  ");
        if (DICT_TRUNCATE_FLAG) {
            if (flags & TRUNC_DFLAG)
                printf("tr ");
            else
                printf("   ");
        }
        if (flags & PREP_DFLAG)
            printf("preposition    ");
        if (flags & META_DFLAG)
            printf("meta");
        if (flags & VERB_DFLAG)
            printf("verb:%d  ", verbnum);
        printf("\n");
    }

    /* Show five words per line in classic TRANSCRIPT_FORMAT; one per line in the new format. */
    if (d_show_buf && (d_show_len >= 64 || TRANSCRIPT_FORMAT == 1))
    {
        write_to_transcript_file(d_show_buf, STRCTX_DICT);
        d_show_len = 0;
    }

    if (dtree[node].branch[1] != VACANT)
        recursively_show_g(dtree[node].branch[1], level);
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

extern void show_dictionary(int level)
{
    /* Level 0: show words only. Level 1: show words and flags.
       Level 2: also show bytes.*/
    printf("Dictionary contains %d entries:\n",dict_entries);
    if (dict_entries != 0)
    {   d_show_len = 0; d_show_buf = NULL; 
        if (!glulx_mode)    
            recursively_show_z(root, level);
        else
            recursively_show_g(root, level);
    }
    if (!glulx_mode)
    {
        printf("\nZ-machine alphabet entries:\n");
        show_alphabet(0);
        show_alphabet(1);
        show_alphabet(2);
    }
}

extern void write_dictionary_to_transcript(void)
{
    d_show_size = 80; /* initial size */
    d_show_buf = my_malloc(d_show_size, "dictionary display buffer");

    write_to_transcript_file("", STRCTX_INFO);
    sprintf(d_show_buf, "[Dictionary contains %d entries:]", dict_entries);
    write_to_transcript_file(d_show_buf, STRCTX_INFO);
    
    d_show_len = 0;

    if (dict_entries != 0)
    {
        if (!glulx_mode)    
            recursively_show_z(root, 0);
        else
            recursively_show_g(root, 0);
    }
    if (d_show_len != 0) write_to_transcript_file(d_show_buf, STRCTX_DICT);

    my_free(&d_show_buf, "dictionary display buffer");
    d_show_len = 0; d_show_buf = NULL;
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_text_vars(void)
{   int j;

    opttext = NULL;
    opttextlen = 0;
    bestyet = NULL;
    bestyet2 = NULL;
    tlbtab = NULL;
    grandtable = NULL;
    grandflags = NULL;

    translated_text = NULL;
    temp_symbol = NULL;
    all_text = NULL;

    for (j=0; j<256; j++) abbrevs_lookup[j] = -1;

    total_zchars_trans = 0;

    dictionary = NULL;
    dictionary_top = 0;
    dtree = NULL;
    final_dict_order = NULL;
    dict_sort_codes = NULL;
    prepared_sort = NULL;
    dict_entries=0;

    static_strings_area = NULL;
    abbreviations_optimal_parse_schedule = NULL;
    abbreviations_optimal_parse_scores = NULL;

    compressed_offsets = NULL;
    huff_entities = NULL;
    hufflist = NULL;
    unicode_usage_entries = NULL;
}

extern void text_begin_pass(void)
{   abbrevs_lookup_table_made = FALSE;
    no_abbreviations=0;
    abbreviations_totaltext=0;
    total_chars_trans=0; total_bytes_trans=0;
    all_text_top=0;
    dictionary_begin_pass();
    low_strings_top = 0;

    static_strings_extent = 0;
    no_strings = 0;
    no_dynamic_strings = 0;
    no_unicode_chars = 0;
}

/*  Note: for allocation and deallocation of all_the_text, see inform.c      */

extern void text_allocate_arrays(void)
{
    int ix;

    initialise_memory_list(&translated_text_memlist,
        sizeof(uchar), 8000, (void**)&translated_text,
        "translated text holding area");
    
    initialise_memory_list(&temp_symbol_memlist,
        sizeof(char), 32, (void**)&temp_symbol,
        "temporary symbol name");
    
    initialise_memory_list(&all_text_memlist,
        sizeof(char), 0, (void**)&all_text,
        "transcription text for optimise");
    
    initialise_memory_list(&static_strings_area_memlist,
        sizeof(uchar), 128, (void**)&static_strings_area,
        "static strings area");
    
    initialise_memory_list(&abbreviations_text_memlist,
        sizeof(char), 64, (void**)&abbreviations_text,
        "abbreviation text");

    initialise_memory_list(&abbreviations_memlist,
        sizeof(abbreviation), 64, (void**)&abbreviations,
        "abbreviations");

    initialise_memory_list(&abbreviations_optimal_parse_schedule_memlist,
        sizeof(int), 0, (void**)&abbreviations_optimal_parse_schedule,
        "abbreviations optimal parse schedule");
    initialise_memory_list(&abbreviations_optimal_parse_scores_memlist,
        sizeof(int), 0, (void**)&abbreviations_optimal_parse_scores,
        "abbreviations optimal parse scores");
    
    initialise_memory_list(&dtree_memlist,
        sizeof(dict_tree_node), 1500, (void**)&dtree,
        "red-black tree for dictionary");
    initialise_memory_list(&dict_sort_codes_memlist,
        sizeof(uchar), 1500*DICT_WORD_BYTES, (void**)&dict_sort_codes,
        "dictionary sort codes");
    initialise_memory_list(&prepared_sort_memlist,
        sizeof(uchar), DICT_WORD_BYTES, (void**)&prepared_sort,
        "prepared sort buffer");

    final_dict_order = NULL; /* will be allocated at sort_dictionary() time */

    /* The exact size will be 7+7*num for z3, 7+9*num for z4+, 
       4+DICT_ENTRY_BYTE_LENGTH*num for Glulx. But this is just an initial
       allocation; we don't have to be precise. */
    initialise_memory_list(&dictionary_memlist,
        sizeof(uchar), 1000*DICT_ENTRY_BYTE_LENGTH, (void**)&dictionary,
        "dictionary");

    initialise_memory_list(&low_strings_memlist,
        sizeof(uchar), 1024, (void**)&low_strings,
        "low (abbreviation) strings");

    d_show_buf = NULL;
    d_show_size = 0;
    d_show_len = 0;

    huff_entities = NULL;
    hufflist = NULL;
    unicode_usage_entries = NULL;
    done_compression = FALSE;
    compression_table_size = 0;
    compressed_offsets = NULL;

    initialise_memory_list(&unicode_usage_entries_memlist,
        sizeof(unicode_usage_t), 0, (void**)&unicode_usage_entries,
        "unicode entity entries");

    /* hufflist and huff_entities will be allocated at compress_game_text() time. */

    /* This hash table is only used in Glulx */
    for (ix=0; ix<UNICODE_HASH_BUCKETS; ix++)
        unicode_usage_hash[ix] = -1;
    
    initialise_memory_list(&compressed_offsets_memlist,
        sizeof(int32), 0, (void**)&compressed_offsets,
        "static strings index table");
}

extern void extract_all_text()
{
    /* optimise_abbreviations() is called after free_arrays(). Therefore,
       we need to preserve the text transcript where it will not be
       freed up. We do this by copying the pointer to opttext. */
    opttext = all_text;
    opttextlen = all_text_top;

    /* Re-init all_text_memlist. This causes it to forget all about the
       old pointer. Deallocating it in text_free_arrays() will be a no-op. */
    initialise_memory_list(&all_text_memlist,
        sizeof(char), 0, (void**)&all_text,
        "dummy transcription text");
}

extern void text_free_arrays(void)
{
    deallocate_memory_list(&translated_text_memlist);
    deallocate_memory_list(&temp_symbol_memlist);
    
    deallocate_memory_list(&all_text_memlist);
    
    deallocate_memory_list(&low_strings_memlist);
    deallocate_memory_list(&abbreviations_text_memlist);
    deallocate_memory_list(&abbreviations_memlist);

    deallocate_memory_list(&abbreviations_optimal_parse_schedule_memlist);
    deallocate_memory_list(&abbreviations_optimal_parse_scores_memlist);

    deallocate_memory_list(&dtree_memlist);
    deallocate_memory_list(&dict_sort_codes_memlist);
    deallocate_memory_list(&prepared_sort_memlist);
    my_free(&final_dict_order, "final dictionary ordering table");

    deallocate_memory_list(&dictionary_memlist);

    deallocate_memory_list(&compressed_offsets_memlist);
    my_free(&hufflist, "huffman node list");
    my_free(&huff_entities, "huffman entities");
    
    deallocate_memory_list(&unicode_usage_entries_memlist);

    deallocate_memory_list(&static_strings_area_memlist);
}

extern void ao_free_arrays(void)
{
    /* Called only after optimise_abbreviations() runs. */

    int32 i;
    if (bestyet) {
        for (i=0; i<MAX_BESTYET; i++) {
            my_free(&bestyet[i].text, "bestyet.text");
        }
    }
    if (bestyet2) {
        for (i=0; i<MAX_ABBREVS; i++) {
            my_free(&bestyet2[i].text, "bestyet2.text");
        }
    }
    
    my_free (&opttext,"stashed transcript for optimisation");
    my_free (&bestyet,"bestyet");
    my_free (&bestyet2,"bestyet2");
    my_free (&grandtable,"grandtable");
    my_free (&grandflags,"grandflags");

    deallocate_memory_list(&tlbtab_memlist);
    
    /* This was re-inited, so we should re-deallocate it. */
    deallocate_memory_list(&all_text_memlist);
}

/* ========================================================================= */
