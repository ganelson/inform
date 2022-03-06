! ext_flags.h, a library extension for PunyInform by Fredrik Ramsberg, adapted 
! from flags.h by Adam Cadre.

! This is a simple system to provide on/off flags that only take up one bit of
! memory; thus, there's no need to waste memory (and global variables) by
! declaring a variable such as "doneflag" or some such, allocating an entire
! sixteen bits to a variable that will never be anything other than 0 or 1.

! Here's how to use it in your programs. After inclusing globals.h, 
! set the constant FLAG_COUNT to the number of flags you need, then include
! ext_flags.h.
!
! When you start using a new flag, create a constant with a descriptive name.
! You may also want to add a comment, or keep a list on the side regarding
! the meaning of each flag.

! Constant F_FED_PARROT 0; ! Has the parrot been fed?
! Constant F_TICKET_OK 1; ! Has Hildegard booked her plane tickets with the correct credit card?
! Constant F_SAVED_CAT 2;   ! Has the player saved the cat in the tree?

! You get the idea. Note that the first flag is flag #0.

! Setting a flag on or off means calling the routine SetFlag(flag#) or
! ClearFlag(flag#). To indicate that the player has saved the cat,
! call "SetFlag(F_SAVED_CAT);", and to turn off that flag, call
! "ClearFlag(F_SAVED_CAT);"  (Minus the quote marks, of course.)

! Testing a flag is accomplished by calling FlagIsSet or FlagIsClear. So if you have
! a piece of code that should only be run if the parrot has been fed, you would
! enclose it in an "if (FlagIsSet(F_FED_PARROT)) { ... }" statement.
! Naturally, you can test if a flag is clear by calling FlagIsClear instead.

System_file;

Array flag_powers static ->
	$$00000001
	$$00000010
	$$00000100
	$$00001000
	$$00010000
	$$00100000
	$$01000000
	$$10000000;

Array game_flags -> FLAG_COUNT / 8 + (FLAG_COUNT & 7 > 0);

[ SetFlag p_x _y;
#IfV5;
	@log_shift p_x (-3) -> _y;
#IfNot;
	_y = p_x / 8;
#EndIf;
	game_flags -> _y = game_flags -> _y | flag_powers -> (p_x & 7);
];

[ ClearFlag p_x _y;
#IfV5;
	@log_shift p_x (-3) -> _y;
#IfNot;
	_y = p_x / 8;
#EndIf;
	game_flags -> _y = game_flags -> _y & ~ flag_powers -> (p_x & 7);
];

[ FlagIsSet p_x _y;
#IfV5;
	@log_shift p_x (-3) -> _y;
#IfNot;
	_y = p_x / 8;
#EndIf;
	return (game_flags -> _y & flag_powers -> (p_x & 7) > 0);
];

[ FlagIsClear p_x _y;
#IfV5;
	@log_shift p_x (-3) -> _y;
#IfNot;
	_y = p_x / 8;
#EndIf;
	return (game_flags -> _y & flag_powers -> (p_x & 7) == 0);
];
