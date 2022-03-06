! ==============================================================================
!   VERBLIB:  Front end to standard verbs library.
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

Default AMUSING_PROVIDED 1;
Default MAX_CARRIED      100;
Default MAX_SCORE        0;
Default NUMBER_TASKS     1;
Default OBJECT_SCORE     4;
Default ROOM_SCORE       5;
Default SACK_OBJECT      0;
Default TASKS_PROVIDED   1;

#Ifndef task_scores;
! Constant MAKE__TS;
! #Endif;
! #Ifdef MAKE__TS;
Array  task_scores -> 0 0 0 0;
#Endif;

Array  task_done -> NUMBER_TASKS;

#Ifndef LibraryMessages;
Object LibraryMessages;
#Endif;

#Ifndef NO_PLACES;
[ ObjectsSub; Objects1Sub(); ];
[ PlacesSub;  Places1Sub(); ];
#Endif; ! NO_PLACES

#Ifdef USE_MODULES;
Link "verblibm";
#Ifnot;
Include "verblibm";
#Endif; ! USE_MODULES

! ==============================================================================

Constant LIBRARY_VERBLIB;       ! for dependency checking

! ==============================================================================
