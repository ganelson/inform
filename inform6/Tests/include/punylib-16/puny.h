! PunyInform: A small stdlib and parser for interactive fiction
! suitable for old-school computers such as the Commodore 64.
! Designed to be similar, but not identical, to the Inform 6 library.
!
! Reference documentation
! DM: http://www.inform-fiction.org/manual/html/dm4index.html
! Tech: https://www.inform-fiction.org/source/tm/TechMan.txt
! Z-machine: https://www.inform-fiction.org/zmachine/standards/z1point1
!
! Public routines (described in DM, available for a game developer)
! LIBRARY ROUTINES:
! - CommonAncestor
! - DrawStatusLine
! - IndirectlyContains
! - InScope
! - LoopOverScope
! - NextWord
! - NextWordStopped
! - NumberWord
! - ObjectIsUntouchable
! - PlayerTo
! - ParseToken
! - PlaceInScope
! - PronounNotice
! - ScopeWithin
! - SetTime
! - TestScope
! - TryNumber
! - WordAddress
! - WordLength
! - YesOrNo
! OTHERS:
! - PrintOrRun
! - RunRoutines
! PRINT UTILITIES:
! - CTheyreorThats
! - ItorThem
! - IsOrAre
! PUNYINFORM ONLY:
! - OnOff
! - ObjectIsInvisible
! - PrintMsg
! - RunTimeError

! comment/uncomment to restrict default debug messages behaviour
! (all can be overridden by adding them in the game source)
!Constant DEBUG_SCOPE;
!Constant DEBUG_CHECKNOUN;
!Constant DEBUG_GETNEXTNOUN;
!Constant DEBUG_PARSETOKEN;
!Constant DEBUG_PARSEPATTERN;
!Constant DEBUG_PARSEANDPERFORM;

System_file;

Include "messages.h";


! ######################### Include utility files

Include "scope.h";
Include "grammar.h";

! ######################### Helper routines
[ UnsignedCompare p_x p_y _u _v;
	if (p_x == p_y) return 0;
	if (p_x < 0 && p_y >= 0) return 1;
	if (p_x >= 0 && p_y < 0) return -1;
	_u = p_x&~WORD_HIGHBIT; _v = p_y&~WORD_HIGHBIT;
	if (_u > _v) return 1;
	return -1;
];

[ IndirectlyContains p_o1 p_o2;
	! Does o1 indirectly contain o2?  (Same as testing if o1 is one of the ancestors of o2.)
	while (p_o2 ~= 0) {
		if (p_o1 == p_o2) rtrue;
		!        if (p_o2 ofclass Class) rfalse;
		p_o2 = parent(p_o2);
	}
	rfalse;
];

[ CommonAncestor p_o1 p_o2 _i _j;
    ! Find the nearest object indirectly containing o1 and o2,
    ! or return 0 if there is no common ancestor.
    _i = p_o1;
    while (_i) {
        _j = p_o2;
        while (_j) {
            if (_j == _i) return _i;
            _j = parent(_j);
        }
        _i = parent(_i);
    }
    return 0;
];

[ SetTime p_time p_step;
	the_time = p_time;
	time_rate = p_step;
	time_step = 0;
	if(p_step < 0) time_step = -p_step;
];

#IfV5;

Array cursor_pos --> 2;

[ _StatusLineHeight p_height;
	if (statusline_current_height ~= p_height) {
		@split_window p_height;
		statusline_current_height = p_height;
	}
];


[ _MoveCursor line column;  ! 1-based postion on text grid
	if (~~statuswin_current) {
		@set_window 1;
		if (clr_on && clr_bgstatus > 1) {
			@set_colour clr_fgstatus clr_bgstatus;
		} else {
			style reverse;
		}
	}
	if (line == 0) {
		line = 1;
		column = 1;
	}
	@set_cursor line column;
	statuswin_current = true;
];

[ _MainWindow;
	if (statuswin_current) {
		if (clr_on && clr_bgstatus > 1) {
			@set_colour clr_fg clr_bg;
		} else {
			style roman;
		}
		@set_window 0;
	}
	statuswin_current = false;
];


Array TenSpaces -> "          ";

[ _PrintSpacesOrMoveBack p_col p_string _current_col;
	p_col = (HDR_SCREENWCHARS->0) - p_col;

	@get_cursor cursor_pos;
	_current_col = cursor_pos --> 1;

	if(_current_col > p_col || cursor_pos --> 0 > 1) {
		_MoveCursor(1, p_col);
		rtrue;
	}

	p_col = p_col - _current_col;
	while(p_col > 10) {
		@print_table TenSpaces 10;
		p_col = p_col - 10;
	}
	@print_table TenSpaces p_col;
	if(p_string)
		print (string) p_string;
];

Constant ONE_SPACE_STRING = " ";

[ DrawStatusLine _width _visibility_ceiling _h _pm;
	! For wide screens (67+ columns):
	! * print a space before room name, and "Score: xxx  Moves: xxxx" to the right.
	! * Room names up to 39 characters are never truncated.
	! For narrow screens:
	! * No space before room name
	! * Print "Score: xxx/yyyy", "xxx/yyyy", "xxx" or nothing, depending on screen width
	! * Room names up to 21 characters are never truncated. On a 40 column screen, room names up to 24 characters are never truncated.

	! If there is no player location, we shouldn't try to draw status window
	if (location == nothing || parent(player) == nothing)
		return;

	_width = HDR_SCREENWCHARS->0;

	_StatusLineHeight(statusline_height);
	_MoveCursor(1, 1); ! This also sets the upper window as active.
	if(_width > 66) @print_char ' ';

!     _MoveCursor(1, 2);
!     if (location == thedark) {
!         print (name) location;
!     }
!     else {
!         FindVisibilityLevels();
!         if (visibility_ceiling == location)
	_visibility_ceiling = ScopeCeiling(player);
! print (object) _visibility_ceiling;
	if (location == thedark || _visibility_ceiling == location)
		_PrintObjName(location); ! If it's light, location == real_location
	else
		print (The) _visibility_ceiling;

	if (sys_statusline_flag) {
		! Statusline should show time rather than score
		if (_width > 29) {
			if (_width > 39) {
				if (_width > 66) {
					! Width is 67-, print "Time: 12:34 pm" with some space to the right
					_PrintSpacesOrMoveBack(20, TIME__TX);
				} else {
					! Width is 40-66, print "Time: 12:34 pm" at right edge
					_PrintSpacesOrMoveBack(15, TIME__TX);
				}
			} else {
				! Width is 30-, print "12:34 pm" at right edge
				_PrintSpacesOrMoveBack(9, ONE_SPACE_STRING);
			}
			_h = status_field_1;
			if (_h > 11) {
				_pm = true;
			}
			if (_h > 12) {
				_h = _h - 12;
			}
!			if (_h<10)
!				@print_char ' ';
			print _h;
			@print_char ':';
			if (status_field_2<10)
				@print_char '0';
			print status_field_2;
			if (_pm)
				print " pm";
			else
				print " am";
		}
	} else {
		! Statusline should show score rather than time
		if (_width > 24) {
			if (_width < 30) {
				! Width is 25-29, only print score as "0", no moves
				_PrintSpacesOrMoveBack(3, ONE_SPACE_STRING);
				print status_field_1;
			} else {
				if (_width > 66) {
					! Width is 67-, print "Score: 0 Moves: 0"
					_PrintSpacesOrMoveBack(28, SCORE__TX);
					print status_field_1;
					_PrintSpacesOrMoveBack(14, MOVES__TX);
				} else {
					if (_width > 36) {
						! Width is 37-66, print "Score: 0/0"
						_PrintSpacesOrMoveBack(15, SCORE__TX);
					} else {
						! Width is 29-35, print "0/0"
						_PrintSpacesOrMoveBack(9, ONE_SPACE_STRING);
					}
					print status_field_1;
					@print_char '/';
				}
				print status_field_2;
			}
		}
	}
	! Regardless of what kind of status line we have printed, print spaces to the end.
	_PrintSpacesOrMoveBack(-1);
	_MainWindow(); ! set_window
];
#EndIf;

[ _AtFullCapacity p_s _obj _k;
    if (p_s == player) {
        objectloop (_obj in p_s)
            if (_obj hasnt worn) _k++;
    } else
        _k = children(p_s);
#IfDef SACK_OBJECT;
	if (_k < RunRoutines(p_s, capacity) || (p_s == player && _RoomInSack())) rfalse;
#IfNot;
	if (_k < RunRoutines(p_s, capacity)) rfalse;
#EndIf;
];

#IfDef SACK_OBJECT;
[ _RoomInSack _obj _ks;
    if (SACK_OBJECT in player) {
        for (_obj=youngest(player) : _obj : _obj=elder(_obj))
            if (_obj ~= SACK_OBJECT && _obj hasnt worn or light) {
                _ks = keep_silent;
                keep_silent = 1;
                <Insert _obj SACK_OBJECT>;
                keep_silent = _ks;
                if (_obj in SACK_OBJECT) {
                    if (keep_silent == 0) PrintMsg(MSG_SACK_PUTTING, _obj);
                    rtrue;
                }
            }
    }
    rfalse;
];
#EndIf;

[ PrintShortName o;
    if (o == 0) { print "nothing"; rtrue; }
    switch (metaclass(o)) {
      Routine:  print "<routine ", o, ">"; rtrue;
      String:   print "<string ~", (string) o, "~>"; rtrue;
      nothing:  print "<illegal object number ", o, ">"; rtrue;
    }
    if (o.short_name ~= 0 && PrintOrRun(o, short_name, true) ~= 0) rtrue;
    print (object) o;
];

[ _PrintObjName p_obj p_form;
	if(p_obj hasnt proper) {
		if(p_form == FORM_CDEF) {
			print "The ";
		} else if(p_form == FORM_DEF) {
			print "the ";
		} else if(p_form == FORM_INDEF) {
			if(p_obj.&article) {
				PrintOrRun(p_obj, article, true);
				print " ";
			}
			else if(p_obj has pluralname)
				print "some ";
			else
				print "a ";
		}
		! print " "; ! not ok, adds space in room name
	}
	PrintShortName(p_obj);
];

[ _PrintAfterEntry p_obj;
	if(p_obj has container && P_obj hasnt open) print " (which is closed)";
	if(p_obj has container && (p_obj has open || p_obj has transparent)) {
		if(child(p_obj) == nothing)
			print " (which is empty)";
		else
			if(PrintContents(" (which contains ", p_obj)) print ")";
	}
	if(p_obj has supporter && child(p_obj) ~= nothing) {
		if(PrintContents(" (on which is ", p_obj)) print ")";
	}
!	if(p_obj has light && action == ##Inv) print " (providing light)";
	if(p_obj has light) print " (providing light)";
	if(p_obj has worn && action == ##Inv) print " (worn)";
];

[ PrintContents p_first_text p_obj p_check_workflag _obj _printed_first_text _printed_any_objects _last_obj;
!   print "Objectlooping...^";
	objectloop(_obj in p_obj) {
!   print "Considering ", (object) _obj, "...^";
!   if(_obj has concealed) print "Is concealed."; else print "Isnt concealed.";
		if(_obj hasnt concealed && _obj hasnt scenery &&
			_obj ~= parent(player) &&  ! don't print container when player in it
			(p_check_workflag == false || _obj has workflag)) {
!			(_obj.&describe == 0 || _obj notin parent(player)) &&
!			(_obj has moved || _obj.initial == 0 || _obj notin parent(player))) {
			if(_printed_first_text == 0) {
				if(p_first_text ofclass String)
					print (string) p_first_text;
				else if(p_first_text ~= 0)
					p_first_text(p_obj);
				_printed_first_text = 1;
			}
			! Push obj onto queue, printing the object that is shifted out, if any
			if(_last_obj) {
				if(_printed_any_objects) print ", ";
				_PrintContentsPrintAnObj(_last_obj);
				_printed_any_objects = 1;
			}
			_last_obj = _obj;
		}
	}
	if(_last_obj) {
		if(_printed_any_objects) print " and ";
		_PrintContentsPrintAnObj(_last_obj);
	}

	return _printed_first_text;
];

[ _PrintContentsPrintAnObj p_obj _inv _skip;
	if(p_obj.invent ~= 0) {
		_inv = true;
		inventory_stage = 1;
		_skip = PrintOrRun(p_obj, invent, true);
	}
	if(_skip == false) {
		_PrintObjName(p_obj, FORM_INDEF);
		if(_inv) {
			inventory_stage = 2;
			if(PrintOrRun(p_obj, invent, true)) rtrue;
		}
		_PrintAfterEntry(p_obj);
	}
];
[ RunRoutines p_obj p_prop p_switch;
	if(p_switch == 0) sw__var = action; else sw__var = p_switch;
	if (p_obj.&p_prop == 0 && p_prop >= INDIV_PROP_START) rfalse;
	return p_obj.p_prop();
];


[ PrintOrRun p_obj p_prop p_no_string_newline _val;
	_val = p_obj.p_prop;
	if (p_obj.#p_prop > WORDSIZE || _val ofclass Routine) return RunRoutines(p_obj, p_prop);
	if(_val ofclass String) {
		print (string) p_obj.p_prop;
		if(p_no_string_newline == 0) @new_line;
	}
];

[ _InitFloatingObjects _i _k _stop;
	_stop = top_object + 1;
	for(_i = Directions : _i < _stop : _i++) {
		if(_i.&found_in) {
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
			if(_k >= MAX_FLOATING_OBJECTS) {
				RunTimeError(ERR_TOO_MANY_FLOATING);
				rtrue;
			}
#EndIf;
			floating_objects-->(_k++) = _i;
		}
	}
];

[ MoveFloatingObjects _i _j _len _obj _present;
	while((_obj = floating_objects-->_i) ~= 0 && _obj hasnt absent) {
		_len = _obj.#found_in;
		if(_len == 2 && UnsignedCompare(_obj.found_in, top_object) > 0) {
			_present = RunRoutines(_obj, found_in);
		} else {
			_present = 0;
			_j = _obj.&found_in;
#IfV5;
			@log_shift _len (-1) -> _len;
			@scan_table real_location _j _len -> _present ?~no_success; ! The position is only a throw-away value here.
			_present = 1;
.no_success;
#IfNot;
			_len = _len / 2;
			_len = _len - 1;
.next_value;
				if(_j-->_len == real_location) {
					_present = 1;
					jump after_loop;
				}
			@dec_chk _len 0 ?~next_value;
.after_loop;
#EndIf;

		}
		if(_present)
			move _obj to real_location;
		else
			remove _obj;
		_i++;
	}
];

[ PlayerTo p_loc p_flag _old_loc _old_real_loc _old_lookmode _old_parent _vc _old_vc;
!	print "PlayerTo, moving player to ", (the) p_loc, ".^";
	_old_loc = location;
	_old_real_loc = real_location;
	move Player to p_loc;
	real_location = superparent(p_loc);
	location = real_location;
	scope_modified = true;
	MoveFloatingObjects();
	_UpdateDarkness();
.recheck_vc;
	_old_vc = visibility_ceiling;
	if(location == thedark)
		_vc = thedark;
	else {
		_vc = ScopeCeiling(player);
	}
	if(_vc == location)
		visibility_ceiling = _vc;

	if(visibility_ceiling == location && visibility_ceiling ~= _old_vc) {
		if(location provides initial) {
			_old_parent = parent(player);
			location.initial();
			if(parent(player) ~= _old_parent)
				jump recheck_vc;
		}
		if(location ~= thedark)
			NewRoom();
	}

	if(_old_real_loc ~= real_location && location == thedark && _old_loc == thedark) {
		! we have moved between dark rooms
		! give entry point a chance to react
		DarkToDark();
	}
	_old_lookmode = lookmode;
	if(p_flag==false)
		lookmode = 2;
	if(p_flag==false or 2 && deadflag == GS_PLAYING)
		<Look>;
	lookmode = _old_lookmode;
];

[ Superparent p_obj _parent;
	while(true) {
		_parent = parent(p_obj);
		if(_parent == 0)
			return p_obj;
		p_obj = _parent;
	}
];

[ _UpdateDarkness p_look _ceil _old_darkness _darkness;
	if(location == thedark) _old_darkness = true;
	_ceil = ScopeCeiling(player);
	_darkness = ~~_LookForLightInObj(_ceil, _ceil);
	if(_darkness) {
		location = thedark;
	} else {
		location = real_location;
		if(_old_darkness == true && p_look == true)
			<Look>;
	}
];

[ _LookForLightInObj p_obj p_ceiling _o;
!	print "_LookForLightInObj, Examining: ", (the) p_obj, "^";
	if(p_obj has light) rtrue;
	if(p_obj == p_ceiling || p_obj has transparent || p_obj has supporter || (p_obj has container && p_obj has open))
		objectloop(_o in p_obj)
			if(_LookForLightInObj(_o))
				rtrue;
	rfalse;
];

Include "parser.h";

[ ActionPrimitive; indirect(#actions_table-->action); ];

[ PerformPreparedAction;
#IfDef DEBUG;
	if(debug_flag & 2) TraceAction(action, noun, second);
#EndIf;
	if ((BeforeRoutines() == false) && action < 4096) {
		ActionPrimitive();
		return true; ! could run the command
	}
	return false; ! failed to run (stopped by BeforeRoutines)
];

[ RunEachTurn _i _obj _scope_count;
	! Loop over the scope to find possible react_before routines
	! to run in each object, if it's found stop the action by returning true
#IfDef DEBUG;
	if(debug_flag & 1 && location.&each_turn ~= 0) print "(", (name) location, ").each_turn()^";
#EndIf;
#Ifndef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	_scope_count = GetScopeCopy();
	RunRoutines(location, each_turn);
	for(_i = 0: _i < _scope_count: _i++) {
		_obj = scope_copy-->_i;
		if(_obj.&each_turn ~= 0) {
#IfDef DEBUG;
			if(debug_flag & 1) print "(", (name) _obj, ").each_turn()^";
#EndIf;
#Ifndef OPTIONAL_MANUAL_SCOPE;
			! Assume that every each_turn routine may have modified the scope
			scope_modified = true;
#EndIf;
			RunRoutines(_obj, each_turn);
		}
	}
];

[ BeforeRoutines _i _obj _scope_count;
	! react_before - Loops over the scope to find possible react_before routines
	! to run in each object, if it's found stop the action by returning true
#IfnDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	_scope_count = GetScopeCopy();
#IfDef GamePreRoutine;
#IfDef DEBUG;
	if(debug_flag & 1) print "GamePreRoutine()^";
#EndIf;
	if(GamePreRoutine()) rtrue;
#EndIf;

#IfDef DEBUG;
	if(debug_flag & 1) print "player.orders()^";
#EndIf;
#Ifndef OPTIONAL_MANUAL_SCOPE;
	! Assume that every routine may modify the scope
	scope_modified = true;
#EndIf;
	if(RunRoutines(player, orders)) rtrue;

	for(_i = 0: _i < _scope_count: _i++) {
		_obj = scope_copy-->_i;
		if (_obj provides react_before) {
#IfDef DEBUG;
			if(debug_flag & 1) print "(", (name) _obj, ").react_before()^";
#EndIf;
#Ifndef OPTIONAL_MANUAL_SCOPE;
			! Assume that every routine may modify the scope
			scope_modified = true;
#EndIf;
			if(RunRoutines(_obj, react_before)) {
				rtrue;
			}
		}
	}
#IfDef DEBUG;
	if(debug_flag & 1) print "(", (name) location, ").before()^";
#EndIf;
	if(location provides before) {
#Ifndef OPTIONAL_MANUAL_SCOPE;
		! Assume that every routine may modify the scope
		scope_modified = true;
#EndIf;
		if(RunRoutines(location, before)) rtrue;
	}
	if(inp1 > 1) {
#IfDef DEBUG;
		if(debug_flag & 1) print "(", (name) inp1, ").before()^";
#EndIf;
		if(inp1 provides before) {
#Ifndef OPTIONAL_MANUAL_SCOPE;
			! Assume that every routine may modify the scope
			scope_modified = true;
#EndIf;
			if(RunRoutines(inp1, before)) rtrue;
		}
	}
	rfalse;
];

[ AfterRoutines _i _obj _scope_count;
	! react_after - Loops over the scope to find possible react_before routines
	! to run in each object, if it's found stop the action by returning true
#IfnDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	_scope_count = GetScopeCopy();

	for(_i = 0: _i < _scope_count: _i++) {
		_obj = scope_copy-->_i;
		if (_obj provides react_after) {
#IfDef DEBUG;
			if(debug_flag & 1) print "(", (name) _obj, ").react_after()^";
#EndIf;
#Ifndef OPTIONAL_MANUAL_SCOPE;
			! Assume that every routine may modify the scope
			scope_modified = true;
#EndIf;
			if(RunRoutines(_obj, react_after))
				rtrue;
		}
	}
#IfDef DEBUG;
	if(debug_flag & 1) print "(", (name) location, ").after()^";
#EndIf;
	if(location provides after) {
#Ifndef OPTIONAL_MANUAL_SCOPE;
		! Assume that every routine may modify the scope
		scope_modified = true;
#EndIf;
		if(RunRoutines(location, after)) rtrue;
	}
	if(inp1 > 1) {
#IfDef DEBUG;
		if(debug_flag & 1) print "(", (name) inp1, ").after()^";
#EndIf;
		if(inp1 provides after) {
#Ifndef OPTIONAL_MANUAL_SCOPE;
			! Assume that every routine may modify the scope
			scope_modified = true;
#EndIf;
			if(RunRoutines(inp1, after)) rtrue;
		}
	}
#IfDef GamePostRoutine;
#IfDef DEBUG;
	if(debug_flag & 1) print "GamePostRoutine()^";
#EndIf;
#Ifndef OPTIONAL_MANUAL_SCOPE;
	! Assume that every routine may modify the scope
	scope_modified = true;
#EndIf;
	return GamePostRoutine();
#IfNot;
	rfalse;
#EndIf;
];

[ RunLife p_actor p_reason;
#IfDef DEBUG;
	if(debug_flag & 1 && p_actor provides life) print "(", (name) p_actor, ").life()^";
#EndIf;
#Ifndef OPTIONAL_MANUAL_SCOPE;
	! Assume that every routine may modify the scope
	scope_modified = true;
#EndIf;
    return RunRoutines(p_actor, life, p_reason);
];

[ DirPropToFakeObj p_dir_prop;
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
	if(p_dir_prop < N_TO_CONST || p_dir_prop > OUT_TO_CONST)
		RunTimeError(ERR_NOT_DIR_PROP);
#EndIf;
	return p_dir_prop - N_TO_CONST + FAKE_N_OBJ;
];

[ FakeObjToDirProp p_fake_obj;
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
	if(p_fake_obj < FAKE_N_OBJ || p_fake_obj > FAKE_OUT_OBJ)
		RunTimeError(ERR_NOT_FAKE_OBJ);
#EndIf;
	return p_fake_obj - FAKE_N_OBJ + N_TO_CONST;
];

[ _SetDirectionIfIsFakeDir p_obj p_noun_no _idx;
	if(p_obj >= FAKE_N_OBJ && p_obj <= FAKE_OUT_OBJ) {
		_idx = p_obj - FAKE_N_OBJ;
		selected_direction_index = _idx + 1;
		selected_direction = _idx + N_TO_CONST;
		if(p_noun_no == 1)
			noun = Directions;
		else
			second = Directions;
	}
];

#IfDef DEBUG;
[ DebugParameter _w;
    print _w;
    if (_w >= 1 && _w <= top_object) print " (", (name) _w, ")";
    if (UnsignedCompare(_w, dict_start) >= 0 &&
            UnsignedCompare(_w, dict_end) < 0 &&
            (_w - dict_start) % dict_entry_size == 0)
        print " ('", (address) _w, "')";
];

[ DebugAction a anames;
    if (a >= 4096) { print "<fake action ", a-4096, ">"; return; }
    anames = #identifiers_table;
    anames = anames + 2*(anames-->0) + 2*48;
    print (string) anames-->a;
];

[ TraceAction p_action p_noun p_second;
	print "[ Action ", (DebugAction) p_action;
    if (p_noun ~= 0)   print " with noun ", (DebugParameter) p_noun;
    if (p_second ~= 0) print " and second ", (DebugParameter) p_second;
    print "]^";
];

#EndIf;

[ PerformAction p_action p_noun p_second _sa _sn _ss _sdi _sd _sinp1 _sinp2 _result;
	_sa = action; _sn = noun; _ss = second; _sinp1 = inp1; _sinp2 = inp2; _sdi = selected_direction_index; _sd = selected_direction;
	action = p_action; noun = p_noun; second = p_second; inp1 = p_noun; inp2 = p_second;
	selected_direction_index = 0; selected_direction = 0;
	_SetDirectionIfIsFakeDir(noun, 1);
	_SetDirectionIfIsFakeDir(second, 2);
	_result = PerformPreparedAction();
	action = _sa; noun = _sn; second = _ss; selected_direction_index = _sdi; selected_direction = _sd; inp1 = _sinp1; inp2 = _sinp2;
	return _result;
];

[ R_Process p_action p_noun p_second _s1 _s2;
	_s1 = inp1; _s2 = inp2;
	inp1 = p_noun; inp2 = p_second;
	PerformAction(p_action, p_noun, p_second);
	inp1 = _s1; inp2 = _s2;
];

[ CDefArt p_obj _result;
	_result = _PrintObjName(p_obj, FORM_CDEF);
];

[ DefArt p_obj _result;
	_result = _PrintObjName(p_obj, FORM_DEF);
];

[ IndefArt p_obj _result;
	_result = _PrintObjName(p_obj, FORM_INDEF);
];

[ StartTimer p_obj p_timer;
	StartDaemon(p_obj, p_obj, p_timer);
];

[ StartDaemon p_obj p_array_val p_timer _i;
	if(p_array_val == 0)
		p_array_val = WORD_HIGHBIT + p_obj;
	for (_i=0 : _i<active_timers : _i++)
		if (the_timers-->_i == p_array_val) rfalse;
	_i = active_timers++;
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
	if (_i >= MAX_TIMERS) RunTimeError(ERR_TOO_MANY_TIMERS_DAEMONS);
#EndIf;
	if (p_timer > 0) {
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
		if (p_obj.&time_left == 0) {
			RunTimeError(ERR_OBJECT_HASNT_PROPERTY); return;
		} else
#EndIf;
			p_obj.time_left = p_timer;
	}
#IfDef DEBUG;
	if(debug_flag & 4) {
		print "[ Starting ";
		if(p_array_val > 0)
			print "timer ", (DebugParameter) p_obj, " with time_left = ", p_timer;
		else
			print "daemon ", (DebugParameter) p_obj;
		print "]^";
	}
#EndIf;
	the_timers-->_i = p_array_val;
];

[ StopTimer p_obj;
	StopDaemon(p_obj, p_obj);
];

[ StopDaemon p_obj p_array_val _i;
	if(p_array_val == 0)
		p_array_val = WORD_HIGHBIT + p_obj;
	for (_i=0 : _i<active_timers : _i++)
		if (the_timers-->_i == p_array_val) jump FoundTSlot4;
	rfalse;
.FoundTSlot4;
#IfDef DEBUG;
	if(debug_flag & 4) {
		print "[ Stopping ";
		if(p_array_val > 0)
			print "timer ";
		else
			print "daemon ";
		print (DebugParameter) p_obj, "]^";
	}
#EndIf;
	if (p_obj == p_array_val) { ! This is a timer, not a daemon
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
		if (p_obj.&time_left == 0) {
			RunTimeError(ERR_OBJECT_HASNT_PROPERTY); return;
		} else
#EndIf;
			p_obj.time_left = 0;
	}
	if(_i <= current_timer)
		current_timer--;
	for (_i=_i + 1: _i < active_timers : _i++)
		the_timers-->(_i - 1) = the_timers-->_i;
	active_timers--;
];

[ RunTimersAndDaemons _j _t;
#IfnDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	for (current_timer=0 : current_timer<active_timers : current_timer++) {
		if (deadflag >= GS_DEAD) return;
		_j = the_timers-->current_timer;
#IfDef DEBUG;
		if(debug_flag & 4) {
			print "[ Running ";
			if(_j > 0) {
				print "timer ", (DebugParameter) _j;
				if(_j.time_left > 0)
					print " with time_left = ", _j.time_left;
				else
					print ": time_out";
			} else
				print "daemon ", (DebugParameter) (_j & ~WORD_HIGHBIT);
			print "]^";
		}
#EndIf;

#Ifndef OPTIONAL_MANUAL_SCOPE;
		! Assume that every routine may modify the scope
		scope_modified = true;
#EndIf;
		if (_j < 0) RunRoutines(_j & ~WORD_HIGHBIT, daemon);
		else {
			_t = _j.time_left;
			if (_t == 0) {
				StopTimer(_j);
				RunRoutines(_j, time_out);
			} else {
				_t--;
				_j.time_left = _t;
			}
		}
	}
];

#IfV3;
! These routines are implemented by Veneer, but the default implementations give compile errors for z3

! [ Print__PName prop p size cla i;
	 ! if (prop & $c000)
	 ! {   cla = #classes_table-->(prop & $ff);
		 ! print (name) cla, "::";
		 ! if ((prop & $8000) == 0) prop = (prop & $3f00)/$100;
		 ! else
		 ! {   prop = (prop & $7f00)/$100;
			 ! i = cla.3;
			 ! while ((i-->0 ~= 0) && (prop>0))
			 ! {   i = i + i->2 + 3;
				 ! prop--;
			 ! }
			 ! prop = (i-->0) & $7fff;
		 ! }
	 ! }
	 ! p = #identifiers_table;
	 ! size = p-->0;
	 ! if (prop<=0 || prop>=size || p-->prop==0)
		 ! print "<number ", prop, ">";
	 ! else print (string) p-->prop;
 ! ];

! [ FindIndivPropValue p_obj p_property _x _prop_id;
	! _x = p_obj.3;
	! if (_x == 0) rfalse;
	! !  print "Table for ", (object) obj, " is at ", (hex) x, "^";
	! while (true) {
		! _prop_id = _x-->0;
		! if(_prop_id == 0) break;
		! if(_prop_id & 32767 == p_property) break;
		! ! print (hex) x-->0, " (", (property) x-->0, ")  length ", x->2, ": ";
		! !       for (n = 0: n< (x->2)/2: n++)
		! !           print (hex) (x+3)-->n, " ";
		! !       @new_line;
		! _x = _x + _x->2 + 3;
	! }
	! return _x;
! ];

! [ RV__Pr p_object p_property _value _address;
	! if(p_object == 0) {
		! print "*Error: Tried to read property ";
		! Print__PName(p_property);
		! " of nothing.*";
	! }
	! if(p_object provides p_property) {
		! if(p_property >= INDIV_PROP_START) {
			! _address = FindIndivPropValue(p_object, p_property);
			! return (_address + 3)-->0;
		! }
		! @get_prop p_object p_property -> _value;
		! return _value;
	! }
	! print "[Error: Tried to read undefined property ";
	! Print__PName(p_property);
	! print " of ";
	! PrintShortName(p_object);
	! print "]";
	! rfalse;
! ];

!      CA__Pr:  call, that is, print-or-run-or-read, a property:
!                      this exactly implements obj..prop(...).  Note that
!                      classes (members of Class) have 5 built-in properties
!                      inherited from Class: create, recreate, destroy,
!                      remaining and copy.  Implementing these here prevents
!                      the need for a full metaclass inheritance scheme.      */

[ CA__Pr obj id a    x z s s2 n m;
! print "CA_Pr obj = ", obj,", id = ", id,", a = ", a, "^";
	if (obj < 1 || obj > #largest_object-255) {
		switch(Z__Region(obj)) {
			2:
			if (id == call) {
				s = sender; sender = self; self = obj;
				#ifdef action;sw__var=action;#endif;
				x = indirect(obj, a);
				self = sender; sender = s; return x;
			}
			jump Call__Error;
			3:
			if (id == print) { @print_paddr obj; rtrue; }
			if (id == print_to_array) {
				@output_stream 3 a; @print_paddr obj; @output_stream -3;
				return a-->0;
			}
			jump Call__Error;
		}
		jump Call__Error;
	}
! print "CA_Pr(2) obj = ", obj,", id = ", id,", a = ", a, "^";
!   @check_arg_count 3 ?~A__x;y++;@check_arg_count 4 ?~A__x;y++;
!   @check_arg_count 5 ?~A__x;y++;@check_arg_count 6 ?~A__x;y++;
!   @check_arg_count 7 ?~A__x;y++;@check_arg_count 8 ?~A__x;y++;.A__x;
!   #ifdef INFIX;if (obj has infix__watching) n=1;#endif;
	#ifdef DEBUG;if (debug_flag & 1 ~= 0) n=1;#endif;
!   if (n==1) {
!     n=debug_flag & 1; debug_flag=debug_flag-n;
!     print "[ ~", (name) obj, "~.", (property) id, "(";
!     switch(y) {
!     1:
!       print a; 2: print a,",",b; 3: print a,",",b,",",c;
!     4:
!       print a,",",b,",",c,",",d;
!     5:
!       print a,",",b,",",c,",",d,",",e;
!     6:
!       print a,",",b,",",c,",",d,",",e,",",f;
!     }
!     print ") ]^"; debug_flag = debug_flag + n;
!   }
	if (id > 0 && id < INDIV_PROP_START) {
!   print "CA_Pr OK obj = ", obj,", id = ", id,", a = ", a, "^";
		x = obj.&id;
		if (x==0) {
			x=$000a-->0 + 2*(id-1); n=2;
		} else n = obj.#id;
	} else {
		if (id>=64 && id<69 && obj in Class) {
!     print "CA_Pr ERROR0 obj = ", obj,", id = ", id,", a = ", a, "^";
			RT__Err("Class create etc", obj, id); return;
!     return Cl__Ms(obj,id,y,a,b,c);
		}
!   print "CA_Pr(2.1) obj = ", obj,", id = ", id,", n = ", n, "^";
		x = obj..&id;
!   print "CA_Pr(2.2) obj = ", obj,", id = ", id,", x = ", x, "^";
		if (x == 0) {
!     print "CA_Pr ERROR1 obj = ", obj,", id = ", id,", a = ", a, "^";
			.Call__Error;
			RT__Err("send message", obj, id); return;
		}
!   print "Reading n at ", x-1,": ", 0->(x-1), "^";
		n = 0->(x-1);
		if (id&$C000==$4000)
		switch (n&$C0) { 0: n=1; $40: n=2; $80: n=n&$3F; }
	}
! print "CA_Pr(3) obj = ", obj,", id = ", id,", a = ", a, "^";
	for (:2*m<n:m++) {
!   print "Considering routine at ", x+2*m,": ", x-->m, "^";
		if (x-->m==$ffff) rfalse;
		switch(Z__Region(x-->m)) {
		2:
			s = sender; sender = self; self = obj; s2 = sw__var;
!       switch(y) {
!       0:
!         z = indirect(x-->m);
!       1:
			z = indirect(x-->m, a);
!       2:
!         z = indirect(x-->m, a, b);
!       3:
!       z = indirect(x-->m, a, b, c);
!       4:
!         z = indirect(x-->m, a, b, c, d);
!       5:
!         z = indirect(x-->m, a, b, c, d, e);
!       6:
!         z = indirect(x-->m, a, b, c, d, e, f);
!       }
			self = sender; sender = s; sw__var = s2;
			if (z ~= 0) return z;
		3:
			print_ret (string) x-->m;
		default:
			return x-->m;
		}
	}
	rfalse;
];

[ Cl__Ms;
	rfalse;
];
#EndIf;

#IfTrue RUNTIME_ERRORS < RTE_VERBOSE;
[RT__Err err_no par1 par2;
	print "Inform error: ";
	if(err_no ofclass String)
		print (string) err_no, " - ";
	else
		print_ret err_no;
	print_ret " (", par1, ", ", par2, ")";
];
#EndIf;


Object selfobj "you"
	with
		name 'me' 'myself' 'self',
		short_name  "yourself",
		description "As good-looking as ever.",
		before NULL,
		after NULL,
		life NULL,
		each_turn NULL,
		time_out NULL,
		! describe NULL, ! TODO: uncommenting causes erorr LookSub
		add_to_scope 0,
		capacity MAX_CARRIED,
		parse_name 0,
		orders 0,
		number 0,
		before_implicit NULL,
	has concealed animate proper transparent;

Object thedark "Darkness"
	with
		initial 0,
		description "It is pitch dark here!",
 		short_name 0;

[ _UpdateScoreOrTime;
	if (sys_statusline_flag == 0) {
		status_field_1 = score;
		status_field_2 = turns;
	} else {
		status_field_1 = the_time/60;
		status_field_2 = the_time%60;
	}
];

[ main _i _j _copylength _sentencelength _parsearraylength _score _again_saved _parser_oops;

#IfDef OPTION_DEBUG_VERBS;
	dict_start = HDR_DICTIONARY-->0;
	dict_entry_size = dict_start->(dict_start->0 + 1);
	dict_start = dict_start + dict_start->0 + 4;
	dict_end = dict_start + (dict_start - 2)-->0 * dict_entry_size;
#EndIf;

	parse->0 = MAX_INPUT_WORDS;
#IfV5;
    buffer->0 = MAX_INPUT_CHARS;
#IfNot;
    buffer->0 = MAX_INPUT_CHARS - 1;
#EndIf;

	top_object = #largest_object-255;
	sys_statusline_flag = ( ($1->0) & 2 ) / 2;

	player = selfobj;
	deadflag = GS_PLAYING;
	score = 0;
#IfDef OPTIONAL_FULL_SCORE;
	places_score = 0;
	things_score = 0;
#IfDef TASKS_PROVIDED;
	for(_i = 0 : _i < NUMBER_TASKS : _i++) task_done->_i = 0;
#EndIf;
#EndIf;

	_j = Initialise();

	objectloop (_i in player) give _i moved ~concealed;

	if(_j ~= 2) Banner();

	_InitFloatingObjects(); ! after initialise since location set there
	if(parent(player) == 0) { _i = location; location = 0; PlayerTo(_i); }

	@new_line;
	while(deadflag == GS_PLAYING) {
		scope_modified = false; ! avoid automatic scope updates during parsing

		_UpdateScoreOrTime();
		if(_sentencelength > 0) @new_line;

		_UpdateScope(player, true);
		_score = score;
		if(parse->1 == 0) {
			_ReadPlayerInput();
		}
		_parser_oops = parser_unknown_noun_found;
.do_it_again;
		_sentencelength = _ParseAndPerformAction();
		if(action == ##OopsCorrection) {
			if(_again_saved && _parser_oops > 0) {
				!print "Oops not implemented^";
				_CopyInputArray(buffer2, buffer);
				_CopyParseArray(parse2, parse);
				_parser_oops-->0 = special_word;
				_again_saved = false;
				jump do_it_again;
			} else {
				print "Sorry, that can't be corrected.^";
			}
		}
		if(action == ##Again) {
			! restore from the 'again' buffers and reparse
			if(_again_saved) {
				_CopyInputArray(buffer2, buffer);
				_CopyParseArray(parse2, parse);
				jump do_it_again;
			} else {
				print "You can hardly repeat that.^";
			}
		} else {
			! store the current buffer to 'again'
			_again_saved = true;
			_CopyInputArray(buffer, buffer2);
			_CopyParseArray(parse, parse2);
		}

		if(_sentencelength <= 0) _sentencelength = -_sentencelength;
		else _sentencelength = parse->1;
		if(action >= 0 && meta == false) {
			RunTimersAndDaemons();
			RunEachTurn();
			TimePasses();
            turns++;
            if (the_time ~= NULL) {
				if (time_rate >= 0) the_time=the_time+time_rate;
				else {
					time_step--;
					if (time_step == 0) {
						the_time++;
						time_step = -time_rate;
					}
				}
				the_time = the_time % 1440;
			}
        }

        if(deadflag ~= GS_PLAYING && deadflag ~= GS_WIN) {
        	! we died somehow, use entry routine to give
        	! a chance of resurrection
        	AfterLife();
		}

        if(deadflag == GS_PLAYING && _score < score && notify_mode == true) {
        	print "^[The score has just gone up by ";
        	if(score - _score == 1) {
        		print "one point.]^";
			} else {
        		print score - _score, " points.]^";
			}
		}

		_parsearraylength = parse->1;
		if(_parsearraylength > _sentencelength) {
			! the first sentence in the input  has been parsed
			! and executed. Now remove it from parse so that
			! the next sentence can be parsed
			_copylength = 2 * _parsearraylength + 1;
			for(_i = 1, _j = 2 * _sentencelength + 1: _j < _copylength: _i++, _j++)
				parse-->_i = parse-->_j;

			parse->1 = _parsearraylength - _sentencelength;
		} else {
			! the input was just one sentence
			parse->1 = 0;
		}
		_UpdateDarkness(true);
	}
	_UpdateScoreOrTime();
	print "^^  *** ";
	if(deadflag == GS_QUIT) @quit;
	if(deadflag == GS_WIN) PrintMsg(MSG_YOU_HAVE_WON);
	else if(deadflag == GS_DEAD) PrintMsg(MSG_YOU_HAVE_DIED);
	else if(deadflag >= GS_DEATHMESSAGE) DeathMessage();
	print "  ***^";
	for (::) {
		PrintMsg(MSG_RESTART_RESTORE_OR_QUIT);
		_ReadPlayerInput(true);
		switch(parse-->1) {
		'restart': @restart;
		'restore': RestoreSub();
#IfDef OPTIONAL_FULL_SCORE;
		'full': FullScoreSub();
#EndIf;
		'amusing': Amusing();
		'quit': @quit;
		}
	}
];

! provide entry point routines if the user hasn't already:
! Routines marked NO are not supported in Puny, usually
! because the implementations differ too much.
!
#Stub AfterLife       0;
#Stub AfterPrompt     0;
#Stub Amusing         0;
#Stub BeforeParsing   0;
#Stub DarkToDark      0;
#Stub DeathMessage    0;
#Stub GamePostRoutine 0;
#Stub GamePreRoutine  0;
#Stub InScope         1;
#Stub LookRoutine     0;
#Stub NewRoom         0;
#Stub ParseNumber     2;
#Stub PrintTaskName   1;
#Stub PrintVerb       1;
#Stub TimePasses      0;
#Stub UnknownVerb     1;
!NO #Stub ChooseObjects   2;
!NO #Stub ParserError     1;
