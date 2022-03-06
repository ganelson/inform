! ==============================================================================
!   PARSER:  Front end to parser.
!
!   Supplied for use with Inform 6 -- Release 6/11 -- Serial number 040227
!
!   Copyright Graham Nelson 1993-2004 but freely usable (see manuals)
!
!   In your game file, Include three library files in this order:
!       Include "Parser";
!       Include "VerbLib";
!       Include "Grammar";
! ==============================================================================

System_file;

! ------------------------------------------------------------------------------

Constant LibSerial       "040227";
Constant LibRelease      "6/11";
Constant LIBRARY_VERSION  611;
Constant Grammar__Version 2;

Default COMMENT_CHARACTER '*';

#Ifdef INFIX;
Default DEBUG 0;
#Endif; ! INFIX

#Ifndef WORDSIZE;                   ! compiling with Z-code only compiler
Constant TARGET_ZCODE;
Constant WORDSIZE 2;
#Endif; ! WORDSIZE

#Ifdef TARGET_ZCODE;                ! offsets into Z-machine header

Constant HDR_ZCODEVERSION  $00;     ! byte
Constant HDR_TERPFLAGS     $01;     ! byte
Constant HDR_GAMERELEASE   $02;     ! word
Constant HDR_HIGHMEMORY    $04;     ! word
Constant HDR_INITIALPC     $06;     ! word
Constant HDR_DICTIONARY    $08;     ! word
Constant HDR_OBJECTS       $0A;     ! word
Constant HDR_GLOBALS       $0C;     ! word
Constant HDR_STATICMEMORY  $0E;     ! word
Constant HDR_GAMEFLAGS     $10;     ! word
Constant HDR_GAMESERIAL    $12;     ! six ASCII characters
Constant HDR_ABBREVIATIONS $18;     ! word
Constant HDR_FILELENGTH    $1A;     ! word
Constant HDR_CHECKSUM      $1C;     ! word
Constant HDR_TERPNUMBER    $1E;     ! byte
Constant HDR_TERPVERSION   $1F;     ! byte
Constant HDR_SCREENHLINES  $20;     ! byte
Constant HDR_SCREENWCHARS  $21;     ! byte
Constant HDR_SCREENWUNITS  $22;     ! word
Constant HDR_SCREENHUNITS  $24;     ! word
Constant HDR_FONTWUNITS    $26;     ! byte
Constant HDR_FONTHUNITS    $27;     ! byte
Constant HDR_ROUTINEOFFSET $28;     ! word
Constant HDR_STRINGOFFSET  $2A;     ! word
Constant HDR_BGCOLOUR      $2C;     ! byte
Constant HDR_FGCOLOUR      $2D;     ! byte
Constant HDR_TERMCHARS     $2E;     ! word
Constant HDR_PIXELSTO3     $30;     ! word
Constant HDR_TERPSTANDARD  $32;     ! two bytes
Constant HDR_ALPHABET      $34;     ! word
Constant HDR_EXTENSION     $36;     ! word
Constant HDR_UNUSED        $38;     ! two words
Constant HDR_INFORMVERSION $3C;     ! four ASCII characters

#Ifnot; ! TARGET_GLULX              ! offsets into Glulx header and start of ROM

Constant HDR_MAGICNUMBER   $00;     ! long word
Constant HDR_GLULXVERSION  $04;     ! long word
Constant HDR_RAMSTART      $08;     ! long word
Constant HDR_EXTSTART      $0C;     ! long word
Constant HDR_ENDMEM        $10;     ! long word
Constant HDR_STACKSIZE     $14;     ! long word
Constant HDR_STARTFUNC     $18;     ! long word
Constant HDR_DECODINGTBL   $1C;     ! long word
Constant HDR_CHECKSUM      $20;     ! long word
Constant ROM_INFO          $24;     ! four ASCII characters
Constant ROM_MEMORYLAYOUT  $28;     ! long word
Constant ROM_INFORMVERSION $2C;     ! four ASCII characters
Constant ROM_COMPVERSION   $30;     ! four ASCII characters
Constant ROM_GAMERELEASE   $34;     ! short word
Constant ROM_GAMESERIAL    $36;     ! six ASCII characters

#Endif; ! TARGET_

#Ifndef VN_1610;
Message fatalerror "*** Library 6/11 needs Inform v6.10 or later to work ***";
#Endif; ! VN_

Include "linklpa";

Fake_Action LetGo;
Fake_Action Receive;
Fake_Action ThrownAt;
Fake_Action Order;
Fake_Action TheSame;
Fake_Action PluralFound;
Fake_Action ListMiscellany;
Fake_Action Miscellany;
Fake_Action Prompt;
Fake_Action NotUnderstood;

#Ifdef NO_PLACES;
Fake_Action Places;
Fake_Action Objects;
#Endif; ! NO_PLACES

! ------------------------------------------------------------------------------

[ Main; InformLibrary.play(); ];

! ------------------------------------------------------------------------------

#Ifdef USE_MODULES;
Link "parserm";
#Ifnot;
Include "parserm";
#Endif; ! USE_MODULES

! ==============================================================================

Constant LIBRARY_PARSER;        ! for dependency checking

! ==============================================================================
