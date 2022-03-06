! ext_cheap_scenery.h, a library extension for PunyInform by Fredrik Ramsberg
!
! This library extension provides a way to implement simple scenery objects 
! which can only be examined, using just a single object for the entire game.
! This helps keep both the object count and the dynamic memory usage down.
!
! To use it, include this file after globals.h. Then add a property called 
! cheap_scenery to the locations where you want to add cheap scenery objects.
! You can add up to ten cheap scenery objects to one location in this way. For 
! each scenery object, specify, in this order, one adjective, one noun, and one
! description string or a routine to print one. Instead of an adjective, you
! may give a synonym to the noun. If no adjective or synonym is needed, 
! use the value 1 in that position.
! 
! Note: If you want to use this library extension is a Z-code version 3 game, 
! you must NOT declare cheap_scenery as a common property, or it will only be 
! able to hold one scenery object instead of ten.
!
! If you want to use the same description for a scenery object in several locations,
! declare a constant to hold that string, and refer to the constant in each location.
!
! Before including this extension, you can also define a string or routine called 
! SceneryReply. If you do, it will be used whenever the player does something to a 
! scenery object other than examining it. If it's a string, it's printed. If it's a
! routine it's called. If the routine prints something, it should return true, 
! otherwise false. 
!
! Example usage:

! [SceneryReply;
!   Push:
!     "Now how would you do that?";
!   default:
!     rfalse;
! ];
!
! Include "ext_cheap_scenery.h";
!
! Constant SCN_WATER = "The water is so beautiful this time of year, all clear and glittering.";
! [SCN_SUN; 
!   deadflag = 1;
!   "As you stare right into the sun, you feel a burning sensation in your eyes. 
!     After a while, all goes black. With no eyesight, you have little hope of
!     completing your investigations."; 
! ];
!
! Object RiverBank "River Bank"
!   with
!	 description "The river is quite wide here. The sun reflects in the blue water, the birds are 
!      flying high up above.",
!	 cheap_scenery
!      'blue' 'water' SCN_WATER
!      'bird' 'birds' "They seem so careless."
!      1 'sun' SCN_SUN,
!   has light;


System_file;

#IfnDef RUNTIME_ERRORS;
Constant RUNTIME_ERRORS = 2;
#EndIf;
#IfnDef RTE_MINIMUM;
Constant RTE_MINIMUM = 0;
Constant RTE_NORMAL = 1;
Constant RTE_VERBOSE = 2;
#EndIf;

Object CheapScenery "object"
	with
		article "an",
		number 0,
		parse_name [ _w1 _w2 _i _sw1 _sw2 _len;
			_w1 = NextWordStopped();
			_w2 = NextWordStopped();
			_i = 0;
			_len = location.#cheap_scenery / 2;
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
#IfTrue RUNTIME_ERRORS == RTE_VERBOSE;
			if(_len % 3 > 0)
				"ERROR: cheap_scenery property of current location has incorrect # of values!^";
#IfNot;
			if(_len % 3 > 0)
				"ERROR: cheap_scenery #1!^";
#EndIf;
			while(_i < _len) {
				_sw1 = location.&cheap_scenery-->(_i+2);
#IfTrue RUNTIME_ERRORS == RTE_VERBOSE;
				if(~~(_sw1 ofclass String or Routine))
					"ERROR: Element ", _i+2, " in cheap_scenery property of current location is not a string or routine!^",
						"Element: ", (name) _sw1, "^";
#IfNot;
				if(~~(_sw1 ofclass String or Routine))
					"ERROR: cheap_scenery #2!^";
#EndIf;

				_i = _i + 3;
			}
			_i = 0;
#endif;
			while(_i < _len) {
				_sw1 = location.&cheap_scenery-->_i;
				_sw2 = location.&cheap_scenery-->(_i+1);
				if(_w1 == _sw1 && _w2 == _sw2) {
					self.number = _i;
					return 2;
				}
				if(_w1 == _sw1 or _sw2) {
					self.number = _i;
					return 1;
				}
				_i = _i + 3;
			}
			! It would make sense to return 0 here, but property
			! routines return 0 by default anyway.
		],
		description [ _k;
			_k = location.&cheap_scenery-->(self.number + 2);
			if(_k ofclass Routine) {
				_k();
				rtrue;
			}
			print_ret (string) _k;
		],
		before [;
			Examine, Search:
				rfalse;
			default:
				#ifdef SceneryReply;
				if(SceneryReply ofclass string)
					print_ret (string) SceneryReply;
				if(SceneryReply())
					rtrue;
				#endif;
				"No need to concern yourself with that.";
		],
		found_in [;
			if(location provides cheap_scenery) rtrue;
		],
	has concealed scenery;

	