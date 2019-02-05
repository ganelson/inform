/* ------------------------------------------------------------------------- */
/*   "chars" : Character set mappings and the Z-machine alphabet table       */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */
/*  Inform uses six different character representations:                     */
/*                                                                           */
/*      ASCII      plain ASCII characters in range $20 to $7e                */
/*                     (unsigned 7-bit number)                               */
/*      Source     raw bytes from source code                                */
/*                     (unsigned 8-bit number)                               */
/*      ISO        plain ASCII or ISO 8859-1 to -9, according to value       */
/*                     character_set_setting == 0 or 1 to 9                  */
/*                 in Unicode mode (character_set_unicode), individual       */
/*                     UTF-8 bytes                                           */
/*                     (unsigned 8-bit number)                               */
/*      ZSCII      the Z-machine's character set                             */
/*                     (unsigned 10-bit number)                              */
/*      textual    such as the text @'e to mean e-acute                      */
/*                     or @$03a3 to mean capital Greek sigma                 */
/*                 in Unicode mode, the operations manipulating multibyte    */
/*                     UCS representations are included in text routines     */
/*                     (sequence of ASCII characters)                        */
/*      Unicode    a unifying character set holding all possible characters  */
/*                     Inform can ever deal with                             */
/*                     (unsigned 16-bit number)                              */
/*                                                                           */
/*  Conversion can always be made down this list, but generally not up.      */
/*  Note that all ASCII values are the same in any version of ISO            */
/*  and in Unicode.                                                          */
/*                                                                           */
/*  There is a seventh form: sequences of 5-bit "Z-chars" which encode       */
/*  ZSCII into the story file in compressed form.  Conversion of ZSCII to    */
/*  and from Z-char sequences, although it uses the alphabet table, is done  */
/*  in "text.c".                                                             */
/* ------------------------------------------------------------------------- */
/*  The main data structures need to be modified in mid-compilation, but     */
/*  several of them depend on each other, and must remain consistent;        */
/*  and rebuilding one sometimes uses conversion routines depending on       */
/*  information held in the others:                                          */
/*                                                                           */
/*      Structure                   If changed, need to rebuild:             */
/*      character_set_setting       source_to_iso_grid[]                     */
/*                                  zscii_to_unicode_grid[]                  */
/*                                  zscii_to_iso_grid[]                      */
/*                                  iso_to_unicode_grid[]                    */
/*      alphabet[][]                iso_to_alphabet_grid[]                   */
/*                                  zscii_to_alphabet_grid[]                 */
/*      zscii_to_unicode_grid[]     iso_to_alphabet_grid[]                   */
/*      source_to_iso_grid[]        <nothing>                                */
/*      iso_to_alphabet_grid[]      <nothing>                                */
/*      zscii_to_alphabet_grid[]    <nothing>                                */
/*      zscii_to_iso_grid[]         <nothing>                                */
/*                                                                           */
/*      (zscii_to_iso_grid[] is made whenever iso_to_alphabet_grid[] is      */
/*      made but does not depend on alphabet[].)                             */
/*                                                                           */
/*      Conversion routine          Makes use of:                            */
/*      iso_to_unicode              character_set_setting                    */
/*      unicode_to_zscii            character_set_setting                    */
/*                                  zscii_to_unicode_grid[]                  */
/*      zscii_to_unicode            character_set_setting                    */
/*                                  zscii_to_unicode_grid[]                  */
/*      text_to_unicode             <nothing>                                */
/*      zscii_to_text               character_set_setting                    */
/*                                  zscii_to_unicode_grid[]                  */
/*                                  zscii_to_iso_grid[]                      */
/*                                                                           */
/*  For example, if we want to change alphabet[][] then we can safely        */
/*  use any of the conversion routines while working on the change, but      */
/*  must rebuild the iso_to_alphabet_grid[] before allowing Inform to        */
/*  continue compiling.                                                      */
/* ------------------------------------------------------------------------- */

#include "header.h"

uchar source_to_iso_grid[0x100];       /* Filters source code into legal ISO */

int32 iso_to_unicode_grid[0x100];      /* Filters ISO into Unicode           */

int character_digit_value[128];        /* Parsing of binary, decimal and hex */

static char *accents =                 /* Standard 0.2 stock of accented...  */

   ":a:o:u:A:O:Uss>><<:e:i:y:E:I'a'e'i'o'u'y'A'E'I'O'U'Y`a`e`i`o`u\
`A`E`I`O`U^a^e^i^o^u^A^E^I^O^UoaoA/o/O~a~n~o~A~N~OaeAEcccCthetThEtLLoeOE!!??";

                                       /* ...characters, numbered upwards    */
                                       /* from 155                           */

/* ------------------------------------------------------------------------- */

uchar alphabet[3][27];                  /* The alphabet table. */

int alphabet_modified;                 /* Has the default been changed?      */

char alphabet_used[78];                /* Flags (holding 'N' or 'Y') for
                                          which of the Z-alphabet letters
                                          have actually been encrypted       */

/* ------------------------------------------------------------------------- */

int iso_to_alphabet_grid[0x100];

/* This array combines two conversion processes which have to run quickly:
   an ISO character n is being converted for text purposes into a stream
   of Z-chars (anything from 1 up to 8 of these).  Unicode but non-ISO
   characters are also converted from text, but far less often, and
   different (and slower) methods are used to carry this out.

   iso_to_alphabet_grid[n]
       =  i   if the character exists in ZSCII and is located at
              position i in the Z-machine alphabet (where 0 to 25
              give positions in A0, 26 to 51 in A1 and 52 to 77 in A2);

          -z  if the character exists in ZSCII as value z, but is not
              located anywhere in the Z-machine alphabet;

          -5  if the character does not exist in ZSCII.  (It will still
              be printable using an 8-Z-char sequence to encode it in
              Unicode form, but there's no ZSCII form.)

   Note that ISO tilde ~ is interpreted as ZSCII double-quote ",
   and ISO circumflex ^ is interpreted as ZSCII new-line, in accordance
   with the Inform syntax for strings.  This is automatic from the
   structure of alphabet[][]:

   alphabet[i][j] = the ZSCII code of letter j (0 to 25)
                        in alphabet i (0 to 2)

                    _except that_

                    alphabet[2][0] is ignored by the Z-machine and Inform
                                   (char 0 in A2 is an escape)
                    alphabet[2][1] is ignored by the Z-machine
                                   (char 1 in A2 means new-line)
                                   but used by Inform to hold ISO circumflex
                                   so that ^ is translated as new-line
                    alphabet[2][19] is used by Inform to hold ISO tilde
                                   so that ~ is translated as ": after
                                   compilation, when the alphabet table is
                                   written into the Z-machine, this entry
                                   is changed back to ".

   Note that the alphabet can only hold ZSCII values between 0 and 255.

   The array is dimensioned as [3][27], not [3][26], to make it easier to
   initialise using strcpy (see below), but the zero entries [x][26] are
   not used                                                                 */

int zscii_to_alphabet_grid[0x100];

/* The same, except that the index is a ZSCII character, not an ISO one.    */

int zscii_to_iso_grid[0x100];      /* Converts ZSCII between 0 and 255 to
                                      codes in current ISO set: or to 0 if
                                      code isn't in the current ISO set.    */

static void make_iso_to_alphabet_grid(void)
{   int i, j, k; int z;

    for (j=0; j<0x100; j++)
    {   zscii_to_iso_grid[j] = 0;
        zscii_to_alphabet_grid[j] = -j;
    }

    for (j=0; j<0x100; j++)
    {   iso_to_alphabet_grid[j]=-5;
        if ((j >= 0x20) && (j <= 0x7e))
        {   iso_to_alphabet_grid[j] = -j;
            zscii_to_iso_grid[j] = j;
        }
        if ((j >= 0xa1) && (j <= 0xff))
        {   z = unicode_to_zscii(iso_to_unicode(j));
            if (character_set_setting != 0)
                zscii_to_iso_grid[z] = j;
            iso_to_alphabet_grid[j] = -z;
        }
        iso_to_unicode_grid[j] = iso_to_unicode(j);
    }
    for (j=0; j<3; j++)
        for (k=(j<2?0:1); k<26; k++)
            {   i=(int) ((alphabet[j])[k]);
                zscii_to_alphabet_grid[i] = k + j*26;
                iso_to_alphabet_grid[zscii_to_iso_grid[i]] = k + j*26;
            }
}

extern void map_new_zchar(int32 unicode)
{   /*  Attempts to enter the given Unicode character into the "alphabet[]"
        array, in place of one which has not so far been used in the
        compilation of the current file.  This may of course fail.           */

    int i, j; int zscii;

    zscii = unicode_to_zscii(unicode);

    /*  Out of ZSCII range?  */
    if ((zscii == 5) || (zscii >= 0x100))
    {   unicode_char_error(
            "Character must first be entered into Zcharacter table:", unicode);
        return;
    }

    /*  Already there?  */
    for (i=0;i<3;i++) for (j=0;j<26;j++)
        if (alphabet[i][j] == zscii) return;

    /*  A0 and A1 are never changed.  Try to find a place in alphabet A2:

        xx0123456789.,!?_#'~/\-:()
          ^^^^^^^^^^  ^^^^^ ^^^^^^

        The letters marked ^ are considered to be replaceable, as long as
        they haven't yet been used in any text already encoded, and haven't
        already been replaced.  The routine works along from the left, since
        numerals are more of a luxury than punctuation.                      */

    for (i=2; i<26; i++)
    {   if ((i == 12) || (i == 13) || (i == 19)) continue;
        if (alphabet_used[52+i] == 'N')
        {   alphabet_used[52+i] = 'Y';
            alphabet[2][i] = zscii;
            alphabet_modified = TRUE;
            make_iso_to_alphabet_grid();
            return;
        }
    }
}

extern void new_alphabet(char *text, int which_alph)
{
    /*  Called three times in succession, with which_alph = 0, 1, 2  */

    int i, j, zscii; int32 unicode;

    alphabet_modified = TRUE;

    if (which_alph == 2)
    {   i=3; alphabet[2][2] = '~';
    }
    else i=0;

    for (j=0; i<26; i++)
    {   if (text[j] == 0) goto WrongSizeError;

        unicode = text_to_unicode(text+j);
        j += textual_form_length;

        zscii = unicode_to_zscii(unicode);
        if ((zscii == 5) || (zscii >= 0x100))
            unicode_char_error("Character can't be used in alphabets unless \
entered into Zcharacter table", unicode);
        else alphabet[which_alph][i] = zscii;
    }

    if (text[j] != 0)
    {   WrongSizeError:
        if (which_alph == 2)
            error("Alphabet string must give exactly 23 characters");
        else
            error("Alphabet string must give exactly 26 characters");
    }

    if (which_alph == 2)
    {   int test_dups[0x100];
        for (i=0; i<0x100; i++) test_dups[i] = 0;
        for (i=0; i<3; i++) for (j=0; j<26; j++)
        {   if (test_dups[alphabet[i][j]]++ == 1)
                unicode_char_error("Character duplicated in alphabet:",
                    zscii_to_unicode(alphabet[i][j]));
        }

        make_iso_to_alphabet_grid();
    }
}

static void read_source_to_iso_file(uchar *uccg)
{   FILE *charset_file;
    char cs_buff[256];
    char *p;
    int i=0;

    charset_file=fopen(Charset_Map, "r");
    if (charset_file==NULL)
        fatalerror_named("Couldn't open character set mapping", Charset_Map);

    while (feof(charset_file)==0)
    {   if (fgets(cs_buff,256,charset_file)==0) break;

        switch (cs_buff[0])
        {   case '!': /* Ignore comments in file */
                break;
            case 'C': /* Set character set */
                character_set_setting = cs_buff[1]-'0';
                if ((character_set_setting < 0) || (character_set_setting > 9))
                {   fatalerror_named("Character set in mapping must be 0 to 9",
                        Charset_Map);
                }
                break;
            default:
                p = cs_buff;
                while ((i<256) && (p!=NULL))
                {
                    uccg[i++] = (uchar)atoi(p);
                    p = strchr(p,',');
                    if (p != NULL)
                        p++;
                }
                break;
        }
    }
    fclose(charset_file);
}

/* ========================================================================= */
/*   Conversion functions (without side effects)                             */
/* ------------------------------------------------------------------------- */
/*  (1) Source -> ISO                                                        */
/*                                                                           */
/*      00         remains 0 (meaning "end of file")                         */
/*      TAB        becomes SPACE                                             */
/*      0c         ("form feed") becomes '\n'                                */
/*      0d         becomes '\n'                                              */
/*      other control characters become '?'                                  */
/*      7f         becomes '?'                                               */
/*      80 to 9f   become '?'                                                */
/*      a0         (ISO "non-breaking space") becomes SPACE                  */
/*      ad         (ISO "soft hyphen") becomes '-'                           */
/*      any character undefined in ISO is mapped to '?'                      */
/*      In Unicode mode, characters 80 and upwards are preserved.            */
/*                                                                           */
/* ------------------------------------------------------------------------- */

static void make_source_to_iso_grid(void)
{   int n; uchar *uccg = (uchar *) source_to_iso_grid;

    for (n=0; n<0x100; n++) uccg[n] = (char) n;

    if (Charset_Map[0] != '\0')
        read_source_to_iso_file(uccg);
    else
    {   source_to_iso_grid[0] = (char) 0;
        for (n=1; n<32; n++) source_to_iso_grid[n] = '?';
        source_to_iso_grid[10] = '\n';
        source_to_iso_grid[12] = '\n';
        source_to_iso_grid[13] = '\n';
        source_to_iso_grid[127] = '?';
        source_to_iso_grid[TAB_CHARACTER] = ' ';

        if (character_set_unicode) /* No need to meddle with 8-bit for UTF-8 */
            return;

        for (n=0x80; n<0xa0; n++) source_to_iso_grid[n] = '?';
        source_to_iso_grid[0xa0] = ' ';
        source_to_iso_grid[0xad] = '-';

        switch(character_set_setting)
        {   case 0:
                for (n=0xa0; n<0x100; n++)
                     source_to_iso_grid[n] = '?';
                break;
            case 6:  /* Arabic */
                for (n=0xa0; n<0xc1; n++)
                    switch(n)
                    {   case 0xa0: case 0xa4: case 0xac: case 0xad:
                        case 0xbb: case 0xbf: break;
                        default: source_to_iso_grid[n] = '?';
                    }
                for (n=0xdb; n<0xe0; n++)
                     source_to_iso_grid[n] = '?';
                for (n=0xf3; n<0x100; n++)
                     source_to_iso_grid[n] = '?';
                break;
            case 7:  /* Greek */
                source_to_iso_grid[0xa4] = '?';
                source_to_iso_grid[0xa5] = '?';
                source_to_iso_grid[0xaa] = '?';
                source_to_iso_grid[0xae] = '?';
                source_to_iso_grid[0xd2] = '?';
                source_to_iso_grid[0xff] = '?';
                break;
            case 8:  /* Hebrew */
                source_to_iso_grid[0xa1] = '?';
                for (n=0xbf; n<0xdf; n++)
                     source_to_iso_grid[n] = '?';
                for (n=0xfb; n<0x100; n++)
                     source_to_iso_grid[n] = '?';
                break;
        }
    }
}

/* ------------------------------------------------------------------------- */
/*  (2) ISO -> Unicode                                                       */
/*                                                                           */
/*     Need not be rapid, as the results are mostly cached.                  */
/*     Always succeeds.                                                      */
/* ------------------------------------------------------------------------- */

extern int iso_to_unicode(int iso)
{   int u = iso;
    switch(character_set_setting)
    {

  case 0: /* Plain ASCII only */
  break;

  case 1: /* ISO 8859-1: Latin1: west European */
  break;

  case 2: /* ISO 8859-2: Latin2: central European */

switch(iso)
{ case 0xA1: u=0x0104; break; /* LATIN CAP A WITH OGONEK */
  case 0xA2: u=0x02D8; break; /* BREVE */
  case 0xA3: u=0x0141; break; /* LATIN CAP L WITH STROKE */
  case 0xA5: u=0x013D; break; /* LATIN CAP L WITH CARON */
  case 0xA6: u=0x015A; break; /* LATIN CAP S WITH ACUTE */
  case 0xA9: u=0x0160; break; /* LATIN CAP S WITH CARON */
  case 0xAA: u=0x015E; break; /* LATIN CAP S WITH CEDILLA */
  case 0xAB: u=0x0164; break; /* LATIN CAP T WITH CARON */
  case 0xAC: u=0x0179; break; /* LATIN CAP Z WITH ACUTE */
  case 0xAE: u=0x017D; break; /* LATIN CAP Z WITH CARON */
  case 0xAF: u=0x017B; break; /* LATIN CAP Z WITH DOT ABOVE */
  case 0xB1: u=0x0105; break; /* LATIN SMALL A WITH OGONEK */
  case 0xB2: u=0x02DB; break; /* OGONEK */
  case 0xB3: u=0x0142; break; /* LATIN SMALL L WITH STROKE */
  case 0xB5: u=0x013E; break; /* LATIN SMALL L WITH CARON */
  case 0xB6: u=0x015B; break; /* LATIN SMALL S WITH ACUTE */
  case 0xB7: u=0x02C7; break; /* CARON */
  case 0xB9: u=0x0161; break; /* LATIN SMALL S WITH CARON */
  case 0xBA: u=0x015F; break; /* LATIN SMALL S WITH CEDILLA */
  case 0xBB: u=0x0165; break; /* LATIN SMALL T WITH CARON */
  case 0xBC: u=0x017A; break; /* LATIN SMALL Z WITH ACUTE */
  case 0xBD: u=0x02DD; break; /* DOUBLE ACUTE ACCENT */
  case 0xBE: u=0x017E; break; /* LATIN SMALL Z WITH CARON */
  case 0xBF: u=0x017C; break; /* LATIN SMALL Z WITH DOT ABOVE */
  case 0xC0: u=0x0154; break; /* LATIN CAP R WITH ACUTE */
  case 0xC3: u=0x0102; break; /* LATIN CAP A WITH BREVE */
  case 0xC5: u=0x0139; break; /* LATIN CAP L WITH ACUTE */
  case 0xC6: u=0x0106; break; /* LATIN CAP C WITH ACUTE */
  case 0xC8: u=0x010C; break; /* LATIN CAP C WITH CARON */
  case 0xCA: u=0x0118; break; /* LATIN CAP E WITH OGONEK */
  case 0xCC: u=0x011A; break; /* LATIN CAP E WITH CARON */
  case 0xCF: u=0x010E; break; /* LATIN CAP D WITH CARON */
  case 0xD0: u=0x0110; break; /* LATIN CAP D WITH STROKE */
  case 0xD1: u=0x0143; break; /* LATIN CAP N WITH ACUTE */
  case 0xD2: u=0x0147; break; /* LATIN CAP N WITH CARON */
  case 0xD5: u=0x0150; break; /* LATIN CAP O WITH DOUBLE ACUTE */
  case 0xD8: u=0x0158; break; /* LATIN CAP R WITH CARON */
  case 0xD9: u=0x016E; break; /* LATIN CAP U WITH RING ABOVE */
  case 0xDB: u=0x0170; break; /* LATIN CAP U WITH DOUBLE ACUTE */
  case 0xDE: u=0x0162; break; /* LATIN CAP T WITH CEDILLA */
  case 0xE0: u=0x0155; break; /* LATIN SMALL R WITH ACUTE */
  case 0xE3: u=0x0103; break; /* LATIN SMALL A WITH BREVE */
  case 0xE5: u=0x013A; break; /* LATIN SMALL L WITH ACUTE */
  case 0xE6: u=0x0107; break; /* LATIN SMALL C WITH ACUTE */
  case 0xE8: u=0x010D; break; /* LATIN SMALL C WITH CARON */
  case 0xEA: u=0x0119; break; /* LATIN SMALL E WITH OGONEK */
  case 0xEC: u=0x011B; break; /* LATIN SMALL E WITH CARON */
  case 0xEF: u=0x010F; break; /* LATIN SMALL D WITH CARON */
  case 0xF0: u=0x0111; break; /* LATIN SMALL D WITH STROKE */
  case 0xF1: u=0x0144; break; /* LATIN SMALL N WITH ACUTE */
  case 0xF2: u=0x0148; break; /* LATIN SMALL N WITH CARON */
  case 0xF5: u=0x0151; break; /* LATIN SMALL O WITH DOUBLE ACUTE */
  case 0xF8: u=0x0159; break; /* LATIN SMALL R WITH CARON */
  case 0xF9: u=0x016F; break; /* LATIN SMALL U WITH RING ABOVE */
  case 0xFB: u=0x0171; break; /* LATIN SMALL U WITH DOUBLE ACUTE */
  case 0xFE: u=0x0163; break; /* LATIN SMALL T WITH CEDILLA */
  case 0xFF: u=0x02D9; break; /* DOT ABOVE */
} break;

  case 3: /* ISO 8859-3: Latin3: central European */

switch(iso)
{ case 0xA1: u=0x0126; break; /* LATIN CAP H WITH STROKE */
  case 0xA2: u=0x02D8; break; /* BREVE */
  case 0xA6: u=0x0124; break; /* LATIN CAP H WITH CIRCUMFLEX */
  case 0xA9: u=0x0130; break; /* LATIN CAP I WITH DOT ABOVE */
  case 0xAA: u=0x015E; break; /* LATIN CAP S WITH CEDILLA */
  case 0xAB: u=0x011E; break; /* LATIN CAP G WITH BREVE */
  case 0xAC: u=0x0134; break; /* LATIN CAP J WITH CIRCUMFLEX */
  case 0xAF: u=0x017B; break; /* LATIN CAP Z WITH DOT ABOVE */
  case 0xB1: u=0x0127; break; /* LATIN SMALL H WITH STROKE */
  case 0xB6: u=0x0125; break; /* LATIN SMALL H WITH CIRCUMFLEX */
  case 0xB9: u=0x0131; break; /* LATIN SMALL DOTLESS I */
  case 0xBA: u=0x015F; break; /* LATIN SMALL S WITH CEDILLA */
  case 0xBB: u=0x011F; break; /* LATIN SMALL G WITH BREVE */
  case 0xBC: u=0x0135; break; /* LATIN SMALL J WITH CIRCUMFLEX */
  case 0xBF: u=0x017C; break; /* LATIN SMALL Z WITH DOT ABOVE */
  case 0xC5: u=0x010A; break; /* LATIN CAP C WITH DOT ABOVE */
  case 0xC6: u=0x0108; break; /* LATIN CAP C WITH CIRCUMFLEX */
  case 0xD5: u=0x0120; break; /* LATIN CAP G WITH DOT ABOVE */
  case 0xD8: u=0x011C; break; /* LATIN CAP G WITH CIRCUMFLEX */
  case 0xDD: u=0x016C; break; /* LATIN CAP U WITH BREVE */
  case 0xDE: u=0x015C; break; /* LATIN CAP S WITH CIRCUMFLEX */
  case 0xE5: u=0x010B; break; /* LATIN SMALL C WITH DOT ABOVE */
  case 0xE6: u=0x0109; break; /* LATIN SMALL C WITH CIRCUMFLEX */
  case 0xF5: u=0x0121; break; /* LATIN SMALL G WITH DOT ABOVE */
  case 0xF8: u=0x011D; break; /* LATIN SMALL G WITH CIRCUMFLEX */
  case 0xFD: u=0x016D; break; /* LATIN SMALL U WITH BREVE */
  case 0xFE: u=0x015D; break; /* LATIN SMALL S WITH CIRCUMFLEX */
  case 0xFF: u=0x02D9; break; /* DOT ABOVE */
} break;

  case 4: /* ISO 8859-4: Latin4: central European */

switch(iso)
{ case 0xA1: u=0x0104; break; /* LATIN CAP A WITH OGONEK */
  case 0xA2: u=0x0138; break; /* LATIN SMALL KRA */
  case 0xA3: u=0x0156; break; /* LATIN CAP R WITH CEDILLA */
  case 0xA5: u=0x0128; break; /* LATIN CAP I WITH TILDE */
  case 0xA6: u=0x013B; break; /* LATIN CAP L WITH CEDILLA */
  case 0xA9: u=0x0160; break; /* LATIN CAP S WITH CARON */
  case 0xAA: u=0x0112; break; /* LATIN CAP E WITH MACRON */
  case 0xAB: u=0x0122; break; /* LATIN CAP G WITH CEDILLA */
  case 0xAC: u=0x0166; break; /* LATIN CAP T WITH STROKE */
  case 0xAE: u=0x017D; break; /* LATIN CAP Z WITH CARON */
  case 0xB1: u=0x0105; break; /* LATIN SMALL A WITH OGONEK */
  case 0xB2: u=0x02DB; break; /* OGONEK */
  case 0xB3: u=0x0157; break; /* LATIN SMALL R WITH CEDILLA */
  case 0xB5: u=0x0129; break; /* LATIN SMALL I WITH TILDE */
  case 0xB6: u=0x013C; break; /* LATIN SMALL L WITH CEDILLA */
  case 0xB7: u=0x02C7; break; /* CARON */
  case 0xB9: u=0x0161; break; /* LATIN SMALL S WITH CARON */
  case 0xBA: u=0x0113; break; /* LATIN SMALL E WITH MACRON */
  case 0xBB: u=0x0123; break; /* LATIN SMALL G WITH CEDILLA */
  case 0xBC: u=0x0167; break; /* LATIN SMALL T WITH STROKE */
  case 0xBD: u=0x014A; break; /* LATIN CAP ENG */
  case 0xBE: u=0x017E; break; /* LATIN SMALL Z WITH CARON */
  case 0xBF: u=0x014B; break; /* LATIN SMALL ENG */
  case 0xC0: u=0x0100; break; /* LATIN CAP A WITH MACRON */
  case 0xC7: u=0x012E; break; /* LATIN CAP I WITH OGONEK */
  case 0xC8: u=0x010C; break; /* LATIN CAP C WITH CARON */
  case 0xCA: u=0x0118; break; /* LATIN CAP E WITH OGONEK */
  case 0xCC: u=0x0116; break; /* LATIN CAP E WITH DOT ABOVE */
  case 0xCF: u=0x012A; break; /* LATIN CAP I WITH MACRON */
  case 0xD0: u=0x0110; break; /* LATIN CAP D WITH STROKE */
  case 0xD1: u=0x0145; break; /* LATIN CAP N WITH CEDILLA */
  case 0xD2: u=0x014C; break; /* LATIN CAP O WITH MACRON */
  case 0xD3: u=0x0136; break; /* LATIN CAP K WITH CEDILLA */
  case 0xD9: u=0x0172; break; /* LATIN CAP U WITH OGONEK */
  case 0xDD: u=0x0168; break; /* LATIN CAP U WITH TILDE */
  case 0xDE: u=0x016A; break; /* LATIN CAP U WITH MACRON */
  case 0xE0: u=0x0101; break; /* LATIN SMALL A WITH MACRON */
  case 0xE7: u=0x012F; break; /* LATIN SMALL I WITH OGONEK */
  case 0xE8: u=0x010D; break; /* LATIN SMALL C WITH CARON */
  case 0xEA: u=0x0119; break; /* LATIN SMALL E WITH OGONEK */
  case 0xEC: u=0x0117; break; /* LATIN SMALL E WITH DOT ABOVE */
  case 0xEF: u=0x012B; break; /* LATIN SMALL I WITH MACRON */
  case 0xF0: u=0x0111; break; /* LATIN SMALL D WITH STROKE */
  case 0xF1: u=0x0146; break; /* LATIN SMALL N WITH CEDILLA */
  case 0xF2: u=0x014D; break; /* LATIN SMALL O WITH MACRON */
  case 0xF3: u=0x0137; break; /* LATIN SMALL K WITH CEDILLA */
  case 0xF9: u=0x0173; break; /* LATIN SMALL U WITH OGONEK */
  case 0xFD: u=0x0169; break; /* LATIN SMALL U WITH TILDE */
  case 0xFE: u=0x016B; break; /* LATIN SMALL U WITH MACRON */
  case 0xFF: u=0x02D9; break; /* DOT ABOVE */
} break;

  case 5: /* ISO 8859-5: Cyrillic */

switch(iso)
{ case 0xA1: u=0x0401; break; /* CYRILLIC CAP IO */
  case 0xA2: u=0x0402; break; /* CYRILLIC CAP DJE */
  case 0xA3: u=0x0403; break; /* CYRILLIC CAP GJE */
  case 0xA4: u=0x0404; break; /* CYRILLIC CAP UKRAINIAN IE */
  case 0xA5: u=0x0405; break; /* CYRILLIC CAP DZE */
  case 0xA6: u=0x0406; break; /* CYRILLIC CAP BYELORUSSIAN-UKRAINIAN I */
  case 0xA7: u=0x0407; break; /* CYRILLIC CAP YI */
  case 0xA8: u=0x0408; break; /* CYRILLIC CAP JE */
  case 0xA9: u=0x0409; break; /* CYRILLIC CAP LJE */
  case 0xAA: u=0x040A; break; /* CYRILLIC CAP NJE */
  case 0xAB: u=0x040B; break; /* CYRILLIC CAP TSHE */
  case 0xAC: u=0x040C; break; /* CYRILLIC CAP KJE */
  case 0xAE: u=0x040E; break; /* CYRILLIC CAP SHORT U */
  case 0xAF: u=0x040F; break; /* CYRILLIC CAP DZHE */
  case 0xB0: u=0x0410; break; /* CYRILLIC CAP A */
  case 0xB1: u=0x0411; break; /* CYRILLIC CAP BE */
  case 0xB2: u=0x0412; break; /* CYRILLIC CAP VE */
  case 0xB3: u=0x0413; break; /* CYRILLIC CAP GHE */
  case 0xB4: u=0x0414; break; /* CYRILLIC CAP DE */
  case 0xB5: u=0x0415; break; /* CYRILLIC CAP IE */
  case 0xB6: u=0x0416; break; /* CYRILLIC CAP ZHE */
  case 0xB7: u=0x0417; break; /* CYRILLIC CAP ZE */
  case 0xB8: u=0x0418; break; /* CYRILLIC CAP I */
  case 0xB9: u=0x0419; break; /* CYRILLIC CAP SHORT I */
  case 0xBA: u=0x041A; break; /* CYRILLIC CAP KA */
  case 0xBB: u=0x041B; break; /* CYRILLIC CAP EL */
  case 0xBC: u=0x041C; break; /* CYRILLIC CAP EM */
  case 0xBD: u=0x041D; break; /* CYRILLIC CAP EN */
  case 0xBE: u=0x041E; break; /* CYRILLIC CAP O */
  case 0xBF: u=0x041F; break; /* CYRILLIC CAP PE */
  case 0xC0: u=0x0420; break; /* CYRILLIC CAP ER */
  case 0xC1: u=0x0421; break; /* CYRILLIC CAP ES */
  case 0xC2: u=0x0422; break; /* CYRILLIC CAP TE */
  case 0xC3: u=0x0423; break; /* CYRILLIC CAP U */
  case 0xC4: u=0x0424; break; /* CYRILLIC CAP EF */
  case 0xC5: u=0x0425; break; /* CYRILLIC CAP HA */
  case 0xC6: u=0x0426; break; /* CYRILLIC CAP TSE */
  case 0xC7: u=0x0427; break; /* CYRILLIC CAP CHE */
  case 0xC8: u=0x0428; break; /* CYRILLIC CAP SHA */
  case 0xC9: u=0x0429; break; /* CYRILLIC CAP SHCHA */
  case 0xCA: u=0x042A; break; /* CYRILLIC CAP HARD SIGN */
  case 0xCB: u=0x042B; break; /* CYRILLIC CAP YERU */
  case 0xCC: u=0x042C; break; /* CYRILLIC CAP SOFT SIGN */
  case 0xCD: u=0x042D; break; /* CYRILLIC CAP E */
  case 0xCE: u=0x042E; break; /* CYRILLIC CAP YU */
  case 0xCF: u=0x042F; break; /* CYRILLIC CAP YA */
  case 0xD0: u=0x0430; break; /* CYRILLIC SMALL A */
  case 0xD1: u=0x0431; break; /* CYRILLIC SMALL BE */
  case 0xD2: u=0x0432; break; /* CYRILLIC SMALL VE */
  case 0xD3: u=0x0433; break; /* CYRILLIC SMALL GHE */
  case 0xD4: u=0x0434; break; /* CYRILLIC SMALL DE */
  case 0xD5: u=0x0435; break; /* CYRILLIC SMALL IE */
  case 0xD6: u=0x0436; break; /* CYRILLIC SMALL ZHE */
  case 0xD7: u=0x0437; break; /* CYRILLIC SMALL ZE */
  case 0xD8: u=0x0438; break; /* CYRILLIC SMALL I */
  case 0xD9: u=0x0439; break; /* CYRILLIC SMALL SHORT I */
  case 0xDA: u=0x043A; break; /* CYRILLIC SMALL KA */
  case 0xDB: u=0x043B; break; /* CYRILLIC SMALL EL */
  case 0xDC: u=0x043C; break; /* CYRILLIC SMALL EM */
  case 0xDD: u=0x043D; break; /* CYRILLIC SMALL EN */
  case 0xDE: u=0x043E; break; /* CYRILLIC SMALL O */
  case 0xDF: u=0x043F; break; /* CYRILLIC SMALL PE */
  case 0xE0: u=0x0440; break; /* CYRILLIC SMALL ER */
  case 0xE1: u=0x0441; break; /* CYRILLIC SMALL ES */
  case 0xE2: u=0x0442; break; /* CYRILLIC SMALL TE */
  case 0xE3: u=0x0443; break; /* CYRILLIC SMALL U */
  case 0xE4: u=0x0444; break; /* CYRILLIC SMALL EF */
  case 0xE5: u=0x0445; break; /* CYRILLIC SMALL HA */
  case 0xE6: u=0x0446; break; /* CYRILLIC SMALL TSE */
  case 0xE7: u=0x0447; break; /* CYRILLIC SMALL CHE */
  case 0xE8: u=0x0448; break; /* CYRILLIC SMALL SHA */
  case 0xE9: u=0x0449; break; /* CYRILLIC SMALL SHCHA */
  case 0xEA: u=0x044A; break; /* CYRILLIC SMALL HARD SIGN */
  case 0xEB: u=0x044B; break; /* CYRILLIC SMALL YERU */
  case 0xEC: u=0x044C; break; /* CYRILLIC SMALL SOFT SIGN */
  case 0xED: u=0x044D; break; /* CYRILLIC SMALL E */
  case 0xEE: u=0x044E; break; /* CYRILLIC SMALL YU */
  case 0xEF: u=0x044F; break; /* CYRILLIC SMALL YA */
  case 0xF0: u=0x2116; break; /* NUMERO SIGN */
  case 0xF1: u=0x0451; break; /* CYRILLIC SMALL IO */
  case 0xF2: u=0x0452; break; /* CYRILLIC SMALL DJE */
  case 0xF3: u=0x0453; break; /* CYRILLIC SMALL GJE */
  case 0xF4: u=0x0454; break; /* CYRILLIC SMALL UKRAINIAN IE */
  case 0xF5: u=0x0455; break; /* CYRILLIC SMALL DZE */
  case 0xF6: u=0x0456; break; /* CYRILLIC SMALL BYELORUSSIAN-UKRAINIAN I */
  case 0xF7: u=0x0457; break; /* CYRILLIC SMALL YI */
  case 0xF8: u=0x0458; break; /* CYRILLIC SMALL JE */
  case 0xF9: u=0x0459; break; /* CYRILLIC SMALL LJE */
  case 0xFA: u=0x045A; break; /* CYRILLIC SMALL NJE */
  case 0xFB: u=0x045B; break; /* CYRILLIC SMALL TSHE */
  case 0xFC: u=0x045C; break; /* CYRILLIC SMALL KJE */
  case 0xFD: u=0x00A7; break; /* SECTION SIGN */
  case 0xFE: u=0x045E; break; /* CYRILLIC SMALL SHORT U */
  case 0xFF: u=0x045F; break; /* CYRILLIC SMALL DZHE */
} break;

  case 6: /* ISO 8859-6: Arabic */

switch(iso)
{ case 0xAC: u=0x060C; break; /* ARABIC COMMA */
  case 0xBB: u=0x061B; break; /* ARABIC SEMICOLON */
  case 0xBF: u=0x061F; break; /* ARABIC QUESTION MARK */
  case 0xC1: u=0x0621; break; /* ARABIC HAMZA */
  case 0xC2: u=0x0622; break; /* ARABIC ALEF WITH MADDA ABOVE */
  case 0xC3: u=0x0623; break; /* ARABIC ALEF WITH HAMZA ABOVE */
  case 0xC4: u=0x0624; break; /* ARABIC WAW WITH HAMZA ABOVE */
  case 0xC5: u=0x0625; break; /* ARABIC ALEF WITH HAMZA BELOW */
  case 0xC6: u=0x0626; break; /* ARABIC YEH WITH HAMZA ABOVE */
  case 0xC7: u=0x0627; break; /* ARABIC ALEF */
  case 0xC8: u=0x0628; break; /* ARABIC BEH */
  case 0xC9: u=0x0629; break; /* ARABIC TEH MARBUTA */
  case 0xCA: u=0x062A; break; /* ARABIC TEH */
  case 0xCB: u=0x062B; break; /* ARABIC THEH */
  case 0xCC: u=0x062C; break; /* ARABIC JEEM */
  case 0xCD: u=0x062D; break; /* ARABIC HAH */
  case 0xCE: u=0x062E; break; /* ARABIC KHAH */
  case 0xCF: u=0x062F; break; /* ARABIC DAL */
  case 0xD0: u=0x0630; break; /* ARABIC THAL */
  case 0xD1: u=0x0631; break; /* ARABIC REH */
  case 0xD2: u=0x0632; break; /* ARABIC ZAIN */
  case 0xD3: u=0x0633; break; /* ARABIC SEEN */
  case 0xD4: u=0x0634; break; /* ARABIC SHEEN */
  case 0xD5: u=0x0635; break; /* ARABIC SAD */
  case 0xD6: u=0x0636; break; /* ARABIC DAD */
  case 0xD7: u=0x0637; break; /* ARABIC TAH */
  case 0xD8: u=0x0638; break; /* ARABIC ZAH */
  case 0xD9: u=0x0639; break; /* ARABIC AIN */
  case 0xDA: u=0x063A; break; /* ARABIC GHAIN */
  case 0xE0: u=0x0640; break; /* ARABIC TATWEEL */
  case 0xE1: u=0x0641; break; /* ARABIC FEH */
  case 0xE2: u=0x0642; break; /* ARABIC QAF */
  case 0xE3: u=0x0643; break; /* ARABIC KAF */
  case 0xE4: u=0x0644; break; /* ARABIC LAM */
  case 0xE5: u=0x0645; break; /* ARABIC MEEM */
  case 0xE6: u=0x0646; break; /* ARABIC NOON */
  case 0xE7: u=0x0647; break; /* ARABIC HEH */
  case 0xE8: u=0x0648; break; /* ARABIC WAW */
  case 0xE9: u=0x0649; break; /* ARABIC ALEF MAKSURA */
  case 0xEA: u=0x064A; break; /* ARABIC YEH */
  case 0xEB: u=0x064B; break; /* ARABIC FATHATAN */
  case 0xEC: u=0x064C; break; /* ARABIC DAMMATAN */
  case 0xED: u=0x064D; break; /* ARABIC KASRATAN */
  case 0xEE: u=0x064E; break; /* ARABIC FATHA */
  case 0xEF: u=0x064F; break; /* ARABIC DAMMA */
  case 0xF0: u=0x0650; break; /* ARABIC KASRA */
  case 0xF1: u=0x0651; break; /* ARABIC SHADDA */
  case 0xF2: u=0x0652; break; /* ARABIC SUKUN */
} break;

  case 7: /* ISO 8859-7: Greek */

switch(iso)
{ case 0xA1: u=0x02BD; break; /* MODIFIER REVERSED COMMA */
  case 0xA2: u=0x02BC; break; /* MODIFIER APOSTROPHE */
  case 0xAF: u=0x2015; break; /* HORIZONTAL BAR */
  case 0xB4: u=0x0384; break; /* GREEK TONOS */
  case 0xB5: u=0x0385; break; /* GREEK DIALYTIKA TONOS */
  case 0xB6: u=0x0386; break; /* GREEK CAP ALPHA WITH TONOS */
  case 0xB8: u=0x0388; break; /* GREEK CAP EPSILON WITH TONOS */
  case 0xB9: u=0x0389; break; /* GREEK CAP ETA WITH TONOS */
  case 0xBA: u=0x038A; break; /* GREEK CAP IOTA WITH TONOS */
  case 0xBC: u=0x038C; break; /* GREEK CAP OMICRON WITH TONOS */
  case 0xBE: u=0x038E; break; /* GREEK CAP UPSILON WITH TONOS */
  case 0xBF: u=0x038F; break; /* GREEK CAP OMEGA WITH TONOS */
  case 0xC0: u=0x0390; break; /* GREEK SMALL IOTA WITH DIALYTIKA AND TONOS */
  case 0xC1: u=0x0391; break; /* GREEK CAP ALPHA */
  case 0xC2: u=0x0392; break; /* GREEK CAP BETA */
  case 0xC3: u=0x0393; break; /* GREEK CAP GAMMA */
  case 0xC4: u=0x0394; break; /* GREEK CAP DELTA */
  case 0xC5: u=0x0395; break; /* GREEK CAP EPSILON */
  case 0xC6: u=0x0396; break; /* GREEK CAP ZETA */
  case 0xC7: u=0x0397; break; /* GREEK CAP ETA */
  case 0xC8: u=0x0398; break; /* GREEK CAP THETA */
  case 0xC9: u=0x0399; break; /* GREEK CAP IOTA */
  case 0xCA: u=0x039A; break; /* GREEK CAP KAPPA */
  case 0xCB: u=0x039B; break; /* GREEK CAP LAMDA */
  case 0xCC: u=0x039C; break; /* GREEK CAP MU */
  case 0xCD: u=0x039D; break; /* GREEK CAP NU */
  case 0xCE: u=0x039E; break; /* GREEK CAP XI */
  case 0xCF: u=0x039F; break; /* GREEK CAP OMICRON */
  case 0xD0: u=0x03A0; break; /* GREEK CAP PI */
  case 0xD1: u=0x03A1; break; /* GREEK CAP RHO */
  case 0xD3: u=0x03A3; break; /* GREEK CAP SIGMA */
  case 0xD4: u=0x03A4; break; /* GREEK CAP TAU */
  case 0xD5: u=0x03A5; break; /* GREEK CAP UPSILON */
  case 0xD6: u=0x03A6; break; /* GREEK CAP PHI */
  case 0xD7: u=0x03A7; break; /* GREEK CAP CHI */
  case 0xD8: u=0x03A8; break; /* GREEK CAP PSI */
  case 0xD9: u=0x03A9; break; /* GREEK CAP OMEGA */
  case 0xDA: u=0x03AA; break; /* GREEK CAP IOTA WITH DIALYTIKA */
  case 0xDB: u=0x03AB; break; /* GREEK CAP UPSILON WITH DIALYTIKA */
  case 0xDC: u=0x03AC; break; /* GREEK SMALL ALPHA WITH TONOS */
  case 0xDD: u=0x03AD; break; /* GREEK SMALL EPSILON WITH TONOS */
  case 0xDE: u=0x03AE; break; /* GREEK SMALL ETA WITH TONOS */
  case 0xDF: u=0x03AF; break; /* GREEK SMALL IOTA WITH TONOS */
  case 0xE0: u=0x03B0; break; /* GREEK SMALL UPSILON WITH DIALYTIKA AND TONOS */
  case 0xE1: u=0x03B1; break; /* GREEK SMALL ALPHA */
  case 0xE2: u=0x03B2; break; /* GREEK SMALL BETA */
  case 0xE3: u=0x03B3; break; /* GREEK SMALL GAMMA */
  case 0xE4: u=0x03B4; break; /* GREEK SMALL DELTA */
  case 0xE5: u=0x03B5; break; /* GREEK SMALL EPSILON */
  case 0xE6: u=0x03B6; break; /* GREEK SMALL ZETA */
  case 0xE7: u=0x03B7; break; /* GREEK SMALL ETA */
  case 0xE8: u=0x03B8; break; /* GREEK SMALL THETA */
  case 0xE9: u=0x03B9; break; /* GREEK SMALL IOTA */
  case 0xEA: u=0x03BA; break; /* GREEK SMALL KAPPA */
  case 0xEB: u=0x03BB; break; /* GREEK SMALL LAMDA */
  case 0xEC: u=0x03BC; break; /* GREEK SMALL MU */
  case 0xED: u=0x03BD; break; /* GREEK SMALL NU */
  case 0xEE: u=0x03BE; break; /* GREEK SMALL XI */
  case 0xEF: u=0x03BF; break; /* GREEK SMALL OMICRON */
  case 0xF0: u=0x03C0; break; /* GREEK SMALL PI */
  case 0xF1: u=0x03C1; break; /* GREEK SMALL RHO */
  case 0xF2: u=0x03C2; break; /* GREEK SMALL FINAL SIGMA */
  case 0xF3: u=0x03C3; break; /* GREEK SMALL SIGMA */
  case 0xF4: u=0x03C4; break; /* GREEK SMALL TAU */
  case 0xF5: u=0x03C5; break; /* GREEK SMALL UPSILON */
  case 0xF6: u=0x03C6; break; /* GREEK SMALL PHI */
  case 0xF7: u=0x03C7; break; /* GREEK SMALL CHI */
  case 0xF8: u=0x03C8; break; /* GREEK SMALL PSI */
  case 0xF9: u=0x03C9; break; /* GREEK SMALL OMEGA */
  case 0xFA: u=0x03CA; break; /* GREEK SMALL IOTA WITH DIALYTIKA */
  case 0xFB: u=0x03CB; break; /* GREEK SMALL UPSILON WITH DIALYTIKA */
  case 0xFC: u=0x03CC; break; /* GREEK SMALL OMICRON WITH TONOS */
  case 0xFD: u=0x03CD; break; /* GREEK SMALL UPSILON WITH TONOS */
  case 0xFE: u=0x03CE; break; /* GREEK SMALL OMEGA WITH TONOS */
} break;

  case 8: /* ISO 8859-8: Hebrew */

switch(iso)
{ case 0xAA: u=0x00D7; break; /* MULTIPLICATION SIGN */
  case 0xAF: u=0x203E; break; /* OVERLINE */
  case 0xBA: u=0x00F7; break; /* DIVISION SIGN */
  case 0xDF: u=0x2017; break; /* DOUBLE LOW LINE */
  case 0xE0: u=0x05D0; break; /* HEBREW ALEF */
  case 0xE1: u=0x05D1; break; /* HEBREW BET */
  case 0xE2: u=0x05D2; break; /* HEBREW GIMEL */
  case 0xE3: u=0x05D3; break; /* HEBREW DALET */
  case 0xE4: u=0x05D4; break; /* HEBREW HE */
  case 0xE5: u=0x05D5; break; /* HEBREW VAV */
  case 0xE6: u=0x05D6; break; /* HEBREW ZAYIN */
  case 0xE7: u=0x05D7; break; /* HEBREW HET */
  case 0xE8: u=0x05D8; break; /* HEBREW TET */
  case 0xE9: u=0x05D9; break; /* HEBREW YOD */
  case 0xEA: u=0x05DA; break; /* HEBREW FINAL KAF */
  case 0xEB: u=0x05DB; break; /* HEBREW KAF */
  case 0xEC: u=0x05DC; break; /* HEBREW LAMED */
  case 0xED: u=0x05DD; break; /* HEBREW FINAL MEM */
  case 0xEE: u=0x05DE; break; /* HEBREW MEM */
  case 0xEF: u=0x05DF; break; /* HEBREW FINAL NUN */
  case 0xF0: u=0x05E0; break; /* HEBREW NUN */
  case 0xF1: u=0x05E1; break; /* HEBREW SAMEKH */
  case 0xF2: u=0x05E2; break; /* HEBREW AYIN */
  case 0xF3: u=0x05E3; break; /* HEBREW FINAL PE */
  case 0xF4: u=0x05E4; break; /* HEBREW PE */
  case 0xF5: u=0x05E5; break; /* HEBREW FINAL TSADI */
  case 0xF6: u=0x05E6; break; /* HEBREW TSADI */
  case 0xF7: u=0x05E7; break; /* HEBREW QOF */
  case 0xF8: u=0x05E8; break; /* HEBREW RESH */
  case 0xF9: u=0x05E9; break; /* HEBREW SHIN */
  case 0xFA: u=0x05EA; break; /* HEBREW TAV */
} break;

  case 9: /* ISO 8859-9: Latin5: west European without Icelandic */

switch(iso)
{
  case 0xD0: u=0x011E; break; /* LATIN CAP G WITH BREVE */
  case 0xDD: u=0x0130; break; /* LATIN CAP I WITH DOT ABOVE */
  case 0xDE: u=0x015e; break; /* LATIN CAP S WITH CEDILLA */
  case 0xF0: u=0x011f; break; /* LATIN SMALL G WITH BREVE */
  case 0xFD: u=0x0131; break; /* LATIN SMALL DOTLESS I */
  case 0xFE: u=0x015f; break; /* LATIN SMALL S WITH CEDILLA */
} break;

    }
    return u;
}

/* ------------------------------------------------------------------------- */
/*  (3) Unicode -> ZSCII and vice versa                                      */
/*                                                                           */
/*     Need not be rapid, as the results are mostly cached.                  */
/*     Unicode chars which can't be fitted into ZSCII are converted to the   */
/*     value 5 (the pad character used in the dictionary and elsewhere).     */
/* ------------------------------------------------------------------------- */

int zscii_defn_modified, zscii_high_water_mark;

int32 zscii_to_unicode_grid[0x61];

static void zscii_unicode_map(int zscii, int32 unicode)
{   if ((zscii < 155) || (zscii > 251))
    {   compiler_error("Attempted to map a Unicode character into the ZSCII \
set at an illegal position");
        return;
    }
    zscii_to_unicode_grid[zscii-155] = unicode;
    zscii_defn_modified = TRUE;
}

int default_zscii_highset_sizes[] = { 69, 69, 81, 71, 82, 92, 48, 71, 27, 62 };

int32 default_zscii_to_unicode_c01[]
    = { /* (This ordering is important, unlike those for other char sets)
           The 69 characters making up the default Unicode translation
           table (see the Z-Machine Standard 1.0). */

        0xe4, /* a-diaeresis */ 0xf6, /* o-diaeresis */ 0xfc, /* u-diaeresis */
        0xc4, /* A-diaeresis */ 0xd6, /* O-diaeresis */ 0xdc, /* U-diaeresis */
        0xdf, /* sz-ligature */ 0xbb, /* >> */ 0xab, /* << */
        0xeb, /* e-diaeresis */ 0xef, /* i-diaeresis */ 0xff, /* y-diaeresis */
        0xcb, /* E-diaeresis */ 0xcf, /* I-diaeresis */ 0xe1, /* a-acute */
        0xe9, /* e-acute */ 0xed, /* i-acute */ 0xf3, /* o-acute */
        0xfa, /* u-acute */ 0xfd, /* y-acute */ 0xc1, /* A-acute */
        0xc9, /* E-acute */ 0xcd, /* I-acute */ 0xd3, /* O-acute */
        0xda, /* U-acute */ 0xdd, /* Y-acute */ 0xe0, /* a-grave */
        0xe8, /* e-grave */ 0xec, /* i-grave */ 0xf2, /* o-grave */
        0xf9, /* u-grave */ 0xc0, /* A-grave */ 0xc8, /* E-grave */
        0xcc, /* I-grave */ 0xd2, /* O-grave */ 0xd9, /* U-grave */
        0xe2, /* a-circumflex */ 0xea, /* e-circumflex */
        0xee, /* i-circumflex */ 0xf4, /* o-circumflex */
        0xfb, /* u-circumflex */ 0xc2, /* A-circumflex */
        0xca, /* E-circumflex */ 0xce, /* I-circumflex */
        0xd4, /* O-circumflex */ 0xdb, /* U-circumflex */
        0xe5, /* a-ring */ 0xc5, /* A-ring */
        0xf8, /* o-slash */ 0xd8, /* O-slash */
        0xe3, /* a-tilde */ 0xf1, /* n-tilde */ 0xf5, /* o-tilde */
        0xc3, /* A-tilde */ 0xd1, /* N-tilde */ 0xd5, /* O-tilde */
        0xe6, /* ae-ligature */ 0xc6, /* AE-ligature */
        0xe7, /* c-cedilla */ 0xc7, /* C-cedilla */
        0xfe, /* thorn */ 0xf0, /* eth */ 0xde, /* Thorn */ 0xd0, /* Eth */
        0xa3, /* pound symbol */
        0x0153, /* oe-ligature */ 0x0152, /* OE-ligature */
        0xa1, /* inverted ! */ 0xbf /* inverted ? */ };

int32 default_zscii_to_unicode_c2[]
    = { /* The 81 accented letters in Latin2 */
        0x0104, 0x0141, 0x013D, 0x015A, 0x0160, 0x015E, 0x0164, 0x0179,
        0x017D, 0x017B, 0x0154, 0x00C1, 0x00C2, 0x0102, 0x00C4, 0x0139,
        0x0106, 0x00C7, 0x010C, 0x00C9, 0x0118, 0x00CB, 0x011A, 0x00CD,
        0x00CE, 0x010E, 0x0110, 0x0143, 0x0147, 0x00D3, 0x00D4, 0x0150,
        0x00D6, 0x0158, 0x016E, 0x00DA, 0x0170, 0x00DC, 0x00DD, 0x0162,
        0x0105, 0x0142, 0x013E, 0x015B, 0x0161, 0x015F, 0x0165, 0x017A,
        0x017E, 0x017C, 0x00DF, 0x0155, 0x00E1, 0x00E2, 0x0103, 0x00E4,
        0x013A, 0x0107, 0x00E7, 0x010D, 0x00E9, 0x0119, 0x00EB, 0x011B,
        0x00ED, 0x00EE, 0x010F, 0x0111, 0x0144, 0x0148, 0x00F3, 0x00F4,
        0x0151, 0x00F6, 0x0159, 0x016F, 0x00FA, 0x0171, 0x00FC, 0x00FD,
        0x0163 };

int32 default_zscii_to_unicode_c3[]
    = { /* The 71 accented letters in Latin3 */
        0x0126, 0x0124, 0x0130, 0x015E, 0x011E, 0x0134, 0x017B, 0x0127,
        0x0125, 0x0131, 0x015F, 0x011F, 0x0135, 0x017C, 0x00C0, 0x00C1,
        0x00C2, 0x00C4, 0x010A, 0x0108, 0x00C7, 0x00C8, 0x00C9, 0x00CA,
        0x00CB, 0x00CC, 0x00CD, 0x00CE, 0x00CF, 0x00D1, 0x00D2, 0x00D3,
        0x00D4, 0x0120, 0x00D6, 0x011C, 0x00D9, 0x00DA, 0x00DB, 0x00DC,
        0x016C, 0x015C, 0x00DF, 0x00E0, 0x00E1, 0x00E2, 0x00E4, 0x010B,
        0x0109, 0x00E7, 0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED,
        0x00EE, 0x00EF, 0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x0121, 0x00F6,
        0x011D, 0x00F9, 0x00FA, 0x00FB, 0x00FC, 0x016D, 0x015D };

int32 default_zscii_to_unicode_c4[]
    = { /* The 82 accented letters in Latin4 */
        0x0104, 0x0138, 0x0156, 0x0128, 0x013B, 0x0160, 0x0112, 0x0122,
        0x0166, 0x017D, 0x0105, 0x0157, 0x0129, 0x013C, 0x0161, 0x0113,
        0x0123, 0x0167, 0x014A, 0x017E, 0x014B, 0x0100, 0x00C1, 0x00C2,
        0x00C3, 0x00C4, 0x00C5, 0x00C6, 0x012E, 0x010C, 0x00C9, 0x0118,
        0x00CB, 0x0116, 0x00CD, 0x00CE, 0x012A, 0x0110, 0x0145, 0x014C,
        0x0136, 0x00D4, 0x00D5, 0x00D6, 0x00D8, 0x0172, 0x00DA, 0x00DB,
        0x00DC, 0x0168, 0x016A, 0x00DF, 0x0101, 0x00E1, 0x00E2, 0x00E3,
        0x00E4, 0x00E5, 0x00E6, 0x012F, 0x010D, 0x00E9, 0x0119, 0x00EB,
        0x0117, 0x00ED, 0x00EE, 0x012B, 0x0111, 0x0146, 0x014D, 0x0137,
        0x00F4, 0x00F5, 0x00F6, 0x00F8, 0x0173, 0x00FA, 0x00FB, 0x00FC,
        0x0169, 0x016B };

int32 default_zscii_to_unicode_c5[]
    = { /* The 92 accented letters in Cyrillic */
        0x0401, 0x0402, 0x0403, 0x0404, 0x0405, 0x0406, 0x0407, 0x0408,
        0x0409, 0x040A, 0x040B, 0x040C, 0x040E, 0x040F, 0x0410, 0x0411,
        0x0412, 0x0413, 0x0414, 0x0415, 0x0416, 0x0417, 0x0418, 0x0419,
        0x041A, 0x041B, 0x041C, 0x041D, 0x041E, 0x041F, 0x0420, 0x0421,
        0x0422, 0x0423, 0x0424, 0x0425, 0x0426, 0x0427, 0x0428, 0x0429,
        0x042A, 0x042B, 0x042C, 0x042D, 0x042E, 0x042F, 0x0430, 0x0431,
        0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437, 0x0438, 0x0439,
        0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F, 0x0440, 0x0441,
        0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447, 0x0448, 0x0449,
        0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F, 0x0451, 0x0452,
        0x0453, 0x0454, 0x0455, 0x0456, 0x0457, 0x0458, 0x0459, 0x045A,
        0x045B, 0x045C, 0x045E, 0x045F };

int32 default_zscii_to_unicode_c6[]
    = { /* The 48 accented letters in Arabic */
        0x060C, 0x061B, 0x061F, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625,
        0x0626, 0x0627, 0x0628, 0x0629, 0x062A, 0x062B, 0x062C, 0x062D,
        0x062E, 0x062F, 0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635,
        0x0636, 0x0637, 0x0638, 0x0639, 0x063A, 0x0640, 0x0641, 0x0642,
        0x0643, 0x0644, 0x0645, 0x0646, 0x0647, 0x0648, 0x0649, 0x064A,
        0x064B, 0x064C, 0x064D, 0x064E, 0x064F, 0x0650, 0x0651, 0x0652 };

int32 default_zscii_to_unicode_c7[]
    = { /* The 71 accented letters in Greek */
        0x0384, 0x0385, 0x0386, 0x0388, 0x0389, 0x038A, 0x038C, 0x038E,
        0x038F, 0x0390, 0x0391, 0x0392, 0x0393, 0x0394, 0x0395, 0x0396,
        0x0397, 0x0398, 0x0399, 0x039A, 0x039B, 0x039C, 0x039D, 0x039E,
        0x039F, 0x03A0, 0x03A1, 0x03A3, 0x03A4, 0x03A5, 0x03A6, 0x03A7,
        0x03A8, 0x03A9, 0x03AA, 0x03AB, 0x03AC, 0x03AD, 0x03AE, 0x03AF,
        0x03B0, 0x03B1, 0x03B2, 0x03B3, 0x03B4, 0x03B5, 0x03B6, 0x03B7,
        0x03B8, 0x03B9, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BE, 0x03BF,
        0x03C0, 0x03C1, 0x03C2, 0x03C3, 0x03C4, 0x03C5, 0x03C6, 0x03C7,
        0x03C8, 0x03C9, 0x03CA, 0x03CB, 0x03CC, 0x03CD, 0x03CE };

int32 default_zscii_to_unicode_c8[]
    = { /* The 27 accented letters in Hebrew */
        0x05D0, 0x05D1, 0x05D2, 0x05D3, 0x05D4, 0x05D5, 0x05D6, 0x05D7,
        0x05D8, 0x05D9, 0x05DA, 0x05DB, 0x05DC, 0x05DD, 0x05DE, 0x05DF,
        0x05E0, 0x05E1, 0x05E2, 0x05E3, 0x05E4, 0x05E5, 0x05E6, 0x05E7,
        0x05E8, 0x05E9, 0x05EA };

int32 default_zscii_to_unicode_c9[]
    = { /* The 62 accented letters in Latin5 */
        0x00C0, 0x00C1, 0x00C2, 0x00C3, 0x00C4, 0x00C5, 0x00C6, 0x00C7,
        0x00C8, 0x00C9, 0x00CA, 0x00CB, 0x00CC, 0x00CD, 0x00CE, 0x00CF,
        0x011E, 0x00D1, 0x00D2, 0x00D3, 0x00D4, 0x00D5, 0x00D6, 0x00D8,
        0x00D9, 0x00DA, 0x00DB, 0x00DC, 0x0130, 0x015E, 0x00DF, 0x00E0,
        0x00E1, 0x00E2, 0x00E3, 0x00E4, 0x00E5, 0x00E6, 0x00E7, 0x00E8,
        0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED, 0x00EE, 0x00EF, 0x011F,
        0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x00F5, 0x00F6, 0x00F8, 0x00F9,
        0x00FA, 0x00FB, 0x00FC, 0x0131, 0x015F, 0x00FF };

static void make_unicode_zscii_map(void)
{   int i;

    for (i=0; i<0x61; i++) zscii_to_unicode_grid[i] = '?';

    zscii_high_water_mark
        = default_zscii_highset_sizes[character_set_setting];

    for (i=0; i<zscii_high_water_mark; i++)
    {   switch(character_set_setting)
        {   case 0:
            case 1: zscii_unicode_map(i+155, default_zscii_to_unicode_c01[i]);
                    break;
            case 2: zscii_unicode_map(i+155, default_zscii_to_unicode_c2[i]);
                    break;
            case 3: zscii_unicode_map(i+155, default_zscii_to_unicode_c3[i]);
                    break;
            case 4: zscii_unicode_map(i+155, default_zscii_to_unicode_c4[i]);
                    break;
            case 5: zscii_unicode_map(i+155, default_zscii_to_unicode_c5[i]);
                    break;
            case 6: zscii_unicode_map(i+155, default_zscii_to_unicode_c6[i]);
                    break;
            case 7: zscii_unicode_map(i+155, default_zscii_to_unicode_c7[i]);
                    break;
            case 8: zscii_unicode_map(i+155, default_zscii_to_unicode_c8[i]);
                    break;
            case 9: zscii_unicode_map(i+155, default_zscii_to_unicode_c9[i]);
                    break;
        }
    }
    if (character_set_setting < 2) zscii_defn_modified = FALSE;
    make_iso_to_alphabet_grid();
}

extern void new_zscii_character(int32 u, int plus_flag)
{   if (plus_flag == FALSE)
        zscii_high_water_mark = 0;
    if (zscii_high_water_mark == 0x61)
        error("No more room in the Zcharacter table");
    else zscii_unicode_map(155 + zscii_high_water_mark++, u);
}

extern void new_zscii_finished(void)
{   make_iso_to_alphabet_grid();
}

extern int unicode_to_zscii(int32 u)
{   int i;
    if (u < 0x7f) return u;
    for (i=0; i<zscii_high_water_mark; i++)
        if (zscii_to_unicode_grid[i] == u) return i+155;
    return 5;
}

extern int32 zscii_to_unicode(int z)
{   if (z < 0x80) return z;
    if ((z >= 155) && (z <= 251)) return zscii_to_unicode_grid[z-155];
    return '?';
}

/* ------------------------------------------------------------------------- */
/*  (4) Text -> Unicode                                                      */
/*                                                                           */
/*  This routine is not used for ordinary text compilation as it is too      */
/*  slow, but it's useful for handling @ string escapes, or to avoid writing */
/*  special code when speed is not especially required.                      */
/*  Note that the two string escapes which can define Unicode are:           */
/*                                                                           */
/*      @..      where .. is an accent                                       */
/*  and @{...}   where ... specifies a Unicode char in hexadecimal           */
/*               (1 to 4 digits long)                                        */
/*                                                                           */
/*  If either syntax is malformed, an error is generated                     */
/*  and the Unicode (= ISO = ASCII) character value of '?' is returned       */
/*                                                                           */
/*  In Unicode mode (character_set_unicode is true), this handles UTF-8      */
/*  decoding as well as @-expansion. (So it's called when an '@' appears     */
/*  *and* when a high-bit character appears.)                                */
/* ------------------------------------------------------------------------- */

int textual_form_length;

extern int32 text_to_unicode(char *text)
{   int i;

    if (text[0] != '@')
    {   if (character_set_unicode)
        {   if (text[0] & 0x80) /* 8-bit */
            {   switch (text[0] & 0xF0)
                {   case 0xf0:
                        error_named("Inform does not currently support Unicode characters beyond $FFFF:", text);
                        textual_form_length = 1;
                        return '?';
                        break;
                    case 0xe0: /* 3-byte UTF-8 string */
                        textual_form_length = 3;
                        if ((text[1] & 0xc0) != 0x80 || (text[2] & 0xc0) != 0x80)
                        {   error("Invalid 3-byte UTF-8 string.");
                            return '?';
                        }
                        return (text[0] & 0x0f) << 12
                            | (text[1] & 0x3f) << 6
                            | (text[2] & 0x3f);
                        break;
                    case 0xc0: /* 2-byte UTF-8 string */ 
                    case 0xd0:
                        textual_form_length = 2;
                        if ((text[1] & 0xc0) != 0x80)
                        {   error("Invalid 2-byte UTF-8 string.");
                            return '?';
                        }
                        return (text[0] & 0x1f) << 6
                            | (text[1] & 0x3f);
                        break;
                    default: /* broken */
                        error("Invalid UTF-8 string.");
                        textual_form_length = 1;
                        return '?';
                        break;
                }
            }
            else /* nice 7-bit */
            {   textual_form_length = 1;
                return (uchar) text[0];
            }
        }
        else
        {
            textual_form_length = 1;
            return iso_to_unicode((uchar) text[0]);
        }
    }

    if ((isdigit(text[1])) || (text[1] == '@'))
    {   ebf_error("'@' plus an accent code or '@{...}'", text);
        textual_form_length = 1;
        return '?';
    }

    if (text[1] != '{')
    {   for (i=0; accents[i] != 0; i+=2)
            if ((text[1] == accents[i]) && (text[2] == accents[i+1]))
            {   textual_form_length = 3;
                return default_zscii_to_unicode_c01[i/2];
            }

        {   char uac[4];
            uac[0]='@'; uac[1]=text[1]; uac[2]=text[2]; uac[3]=0;
            error_named("No such accented character as", uac);
        }
    }
    else
    {   int32 total = 0;
        int d=0; i=1;
        while (text[++i] != '}')
        {   if (text[i] == 0)
            {   error("'@{' without matching '}'");
                total = '?'; break;
            }
            if (i == 6)
            {   error("At most four hexadecimal digits allowed in '@{...}'");
                total = '?'; break;
            }
            d = character_digit_value[(uchar)text[i]];
            if (d == 127)
            {   error("'@{...}' may only contain hexadecimal digits");
                total = '?'; break;
            }
            total = total*16 + d;
        }
        while ((text[i] != '}') && (text[i] != 0)) i++;
        if (text[i] == '}') i++;
        textual_form_length = i;
        return total;
    }

    textual_form_length = 1;
    return '?';
}

/* ------------------------------------------------------------------------- */
/*  (5) Zscii -> Text                                                        */
/*                                                                           */
/*  Used for printing out dictionary contents into the text transcript file  */
/*  or on-screen (in response to the Trace dictionary directive).            */
/*  In either case, output uses the same ISO set as the source code.         */
/* ------------------------------------------------------------------------- */

extern void zscii_to_text(char *text, int zscii)
{   int i;
    int32 unicode;

    if ((zscii < 0x100) && (zscii_to_iso_grid[zscii] != 0))
    {   text[0] = zscii_to_iso_grid[zscii]; text[1] = 0; return;
    }

    unicode = zscii_to_unicode(zscii);
    for (i=0;i<69;i++)
        if (default_zscii_to_unicode_c01[i] == unicode)
        {   text[0] = '@';
            text[1] = accents[2*i];
            text[2] = accents[2*i+1];
            text[3] = 0; return;
        }
    sprintf(text, "@{%x}", unicode);
}

/* ========================================================================= */

extern char *name_of_iso_set(int s)
{   switch(s)
    {   case 1: return "Latin1";
        case 2: return "Latin2";
        case 3: return "Latin3";
        case 4: return "Latin4";
        case 5: return "Cyrillic";
        case 6: return "Arabic";
        case 7: return "Greek";
        case 8: return "Hebrew";
        case 9: return "Latin5";
    }
    return "Plain ASCII";
}

extern void change_character_set(void)
{   make_source_to_iso_grid();
    make_unicode_zscii_map();
}

/* ------------------------------------------------------------------------- */
/*   Case translation of standard Roman letters within ISO                   */
/* ------------------------------------------------------------------------- */

extern void make_lower_case(char *str)
{   int i;
    for (i=0; str[i]!=0; i++)
        if ((((uchar)str[i])<128) && (isupper(str[i]))) str[i]=tolower(str[i]);
}

extern void make_upper_case(char *str)
{   int i;
    for (i=0; str[i]!=0; i++)
        if ((((uchar)str[i])<128) && (islower(str[i]))) str[i]=toupper(str[i]);
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_chars_vars(void)
{   int n;
    for (n=0; n<128; n++) character_digit_value[n] = 127;
    character_digit_value['0'] = 0;
    character_digit_value['1'] = 1;
    character_digit_value['2'] = 2;
    character_digit_value['3'] = 3;
    character_digit_value['4'] = 4;
    character_digit_value['5'] = 5;
    character_digit_value['6'] = 6;
    character_digit_value['7'] = 7;
    character_digit_value['8'] = 8;
    character_digit_value['9'] = 9;
    character_digit_value['a'] = 10;
    character_digit_value['b'] = 11;
    character_digit_value['c'] = 12;
    character_digit_value['d'] = 13;
    character_digit_value['e'] = 14;
    character_digit_value['f'] = 15;
    character_digit_value['A'] = 10;
    character_digit_value['B'] = 11;
    character_digit_value['C'] = 12;
    character_digit_value['D'] = 13;
    character_digit_value['E'] = 14;
    character_digit_value['F'] = 15;

    strcpy((char *) alphabet[0], "abcdefghijklmnopqrstuvwxyz");
    strcpy((char *) alphabet[1], "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    strcpy((char *) alphabet[2], " ^0123456789.,!?_#'~/\\-:()");

    alphabet_modified = FALSE;

    for (n=0; n<78; n++) alphabet_used[n] = 'N';

    change_character_set();
}

extern void chars_begin_pass(void)
{
}

extern void chars_allocate_arrays(void)
{
}

extern void chars_free_arrays(void)
{
}

/* ========================================================================= */
