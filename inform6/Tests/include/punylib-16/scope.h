! Part of PunyInform: A small stdlib and parser for interactive fiction
! suitable for old-school computers such as the Commodore 64.
! Designed to be similar, but not identical, to the Inform 6 library.

! Routines to update what is in scope
! http://www.inform-fiction.org/manual/html/s32.html#p244
!

System_file;

[ _PerformAddToScope p_obj _add_obj _i _len _addr;
	_addr = p_obj.&add_to_scope;
	if(_addr) {
		! routine or a list of objects
		if(UnsignedCompare(_addr-->0, top_object) > 0) {
			RunRoutines(p_obj, add_to_scope);
		} else {
#IfDef DEBUG_SCOPE;
			print "add_to_scope for ", (name) p_obj, " is list of objects:^";
#EndIf;
			_len = p_obj.#add_to_scope / WORDSIZE;
			for(_i = 0: _i  < _len: _i++) {
				_add_obj =  _addr --> _i;
				if(_add_obj) {
					_PutInScope(_add_obj);
					_SearchScope(child(_add_obj));
#IfDef DEBUG_SCOPE;
					print _i, ": ", _add_obj, "^";
#EndIf;
				}
			}
		}
	}
];

[ _SearchScope p_obj p_risk_duplicate p_no_add _child _add_contents;
#IfDef DEBUG_SCOPE;
#IfDef DEBUG;
	if(p_obj) print "_SearchScope adding ",(object) p_obj," (", p_obj,") and siblings to scope. Action = ", (DebugAction) action, "^";
#IfNot;
	if(p_obj) print "_SearchScope adding ",(object) p_obj," (", p_obj,") and siblings to scope. Action = ", action, "^";
#EndIf;
#EndIf;
	while(p_obj) {
		if(scope_objects >= MAX_SCOPE) {
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
			RunTimeError(ERR_SCOPE_FULL);
#EndIf;
			return;
		}

		_PutInScope(p_obj, p_risk_duplicate);
!		scope-->(scope_objects++) = p_obj;

		! Add_to_scope
		if(p_no_add == 0) _PerformAddToScope(p_obj);

		_child = child(p_obj);
		_add_contents = _child ~= 0 && (p_obj has supporter || p_obj has transparent || (p_obj has container && p_obj has open));
		if(_add_contents) {
			_SearchScope(_child, p_risk_duplicate, p_no_add);
		}
		p_obj = sibling(p_obj);
	}
];

[_PutInScope p_obj p_risk_duplicate _i;
#IfDef DEBUG_SCOPE;
#IfDef DEBUG;
	if(p_obj) print "_PutInScope adding ",(object) p_obj," (", p_obj,") to scope. Action = ", (DebugAction) action, "^";
#IfNot;
	if(p_obj) print "_PutInScope adding ",(object) p_obj," (", p_obj,") to scope. Action = ", action, "^";
#EndIf;
#EndIf;
	if(p_risk_duplicate == 0) {
#IfV5;
		@scan_table p_obj scope scope_objects -> _i ?~not_found;
		return;
.not_found;
#IfNot;
		for(_i = 0: _i < scope_objects: _i++) {
			if(scope-->_i == p_obj) return;
		}
#EndIf;
	}
	! Check if there is room
	if(scope_objects >= MAX_SCOPE) {
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
		RunTimeError(ERR_SCOPE_FULL);
#EndIf;
		return;
	}
	! Add it
	scope-->(scope_objects++) = p_obj;
];

[ _UpdateScope p_actor p_force _start_pos _i _initial_scope_objects _current_scope_objects;
	if(p_actor == 0) p_actor = player;

	if(scope_stage == 2) {
		! call scope_routine to add objects, then abort if it returns true
		scope_objects = 0;
		if(indirect(scope_routine)) rtrue;

		! keep going, but set modified to force update of the normal scope
		scope_modified = true;
	}

	! check if scope is already calculated
#IfDef DEBUG_SCOPE;
	print "*** Call to UpdateScope for ", (the) p_actor, "^";;
#EndIf;
	if(scope_pov == p_actor && scope_modified == false && p_force == false) return;

	scope_pov = p_actor;

	! give entry routine a chance to override
	if(InScope(p_actor)) rtrue;

	_start_pos = ScopeCeiling(p_actor);


	if(scope_stage == 2) {
		! if scope_stage == 2, then scope_routine has already added
		! some objects that we don't want to overwrite
		_initial_scope_objects = scope_objects;
	} else {
		scope_objects = 0;
	}

	! the directions are always in scope
	_PutInScope(Directions);

	! if we are in a container, add it to scope
	if(_start_pos ~= location) {
		_PutInScope(_start_pos);
!		scope-->(scope_objects++) = _start_pos;
	}

	if(location == thedark && p_actor == player) {
		! only the player's possessions are in scope
		_PutInScope(player);
		_SearchScope(child(player), true, true);
	} else {
		! Add all in player location (which may be inside an object)
		_SearchScope(child(_start_pos), true, true);
	}

	_current_scope_objects = scope_objects;
	for(_i = _initial_scope_objects : _i < _current_scope_objects : _i++)
		_PerformAddToScope(scope-->_i);

	scope_modified = false;
#IfDef DEBUG_SCOPE;
	print "*** Updated scope from ", (the) _start_pos, ". Found ", scope_objects, " objects.^";
#EndIf;
];

[GetScopeCopy p_actor _i;
	if(p_actor == 0)
		p_actor = player;

	_UpdateScope(p_actor);
	for(_i = 0: _i < scope_objects: _i++)
		scope_copy-->_i = scope-->_i;
	return scope_objects;
];

[ ScopeCeiling p_actor p_stop_before _parent;
	! this routine is in I6 stdlib, but not in DM
	!
    for(:: p_actor = _parent) {
        _parent = parent(p_actor);
        !   print "Examining ", p_actor, "(", (object) p_actor, ") whose parent is ", _parent, "(", (object) _parent, ")...^";
        if(_parent == 0 or p_stop_before || (p_actor has container && p_actor hasnt transparent or open)) {
            return p_actor;
        }
    }
];

[ TouchCeiling p_actor _parent;
	! this routine is in I6 stdlib, but not in DM
	!
    for(:: p_actor = _parent) {
        _parent = parent(p_actor);
        !   print "Examining ", p_actor, "(", (object) p_actor, ") whose parent is ", _parent, "(", (object) _parent, ")...^";
        if(_parent == 0 || (p_actor has container && p_actor hasnt open)) {
            return p_actor;
        }
    }
];

[ LoopOverScope p_routine p_actor _i _scope_count;
	! DM: LoopOverScope(R,actor)
	! Calls routine p_routine(obj) for each object obj in scope for the
	! given actor. If no actor is given, the actor defaults to be the player.
	! No return value
	if(p_actor == 0)
		p_actor = player;

	_UpdateScope(p_actor);
	_scope_count = GetScopeCopy(p_actor);

	for(_i = 0: _i < _scope_count: _i++) p_routine(scope_copy-->_i);
];

Constant PlaceInScope = _PutInScope;

! [ PlaceInScope p_obj _i;
	! ! DM: PlaceInScope(obj)
	! ! Used in “scope routines” (only) when scope_stage is set to 2 (only).
	! ! Places obj in scope for the token currently being parsed. No other
	! ! objects are placed in scope as a result of this, unlike the case of
	! ! ScopeWithin. No return value

	! ! skip if already added
! #IfV5;
	! @scan_table p_obj scope scope_objects -> _i ?~not_found;
	! return;
! .not_found;
! #IfNot;
	! for(_i = 0: _i < scope_objects: _i++) {
		! if(scope-->_i == p_obj) return;
	! }
! #EndIf;
	! ! add it
	! if(scope_objects >= MAX_SCOPE) {
! #IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
		! RunTimeError(ERR_SCOPE_FULL);
! #EndIf;
		! return;
	! }
	! scope-->(scope_objects++) = p_obj;
! ];

[ ScopeWithin p_obj _i;
	! DM: ScopeWithin(obj)
	! Used in “scope routines” (only) when scope_stage is set to 2 (only).
	! Places the contents of obj in scope for the token currently being
	! parsed, and applies the rules of scope recursively so that contents of
	! see-through objects are also in scope, as is anything added to scope.
	! No return value

	! is there a child?
	p_obj = child(p_obj);
	if(p_obj == nothing) return;

	! skip if already added
	for(_i = 0: _i < scope_objects: _i++) {
		if(scope-->_i == p_obj) return;
	}

	! add all children
	_SearchScope(child(p_obj));
];

[ TestScope p_obj p_actor _i;
	! DM: TestScope(obj,actor)
	! Tests whether the object obj is in scope to the given actor. If no
	! actor is given, the actor is assumed to be the player.
	! The routine returns true or false.
	!print "TestScope ", (object) p_obj, "^";
	if(p_actor == 0)
		p_actor = player;

	_UpdateScope(p_actor);

	! special case for debugging verbs; everything is in scope
	if(meta) rtrue;

	_UpdateScope(p_actor);
	for(_i = 0: _i < scope_objects: _i++) {
		if(scope-->_i == p_obj) rtrue;
	}
	rfalse;
];

[ _ObjectScopedBySomething p_item _i _j _k _l _m;
	_i = p_item;
	objectloop (_j .& add_to_scope) {
		_l = _j.&add_to_scope;
		if (_l-->0 ofclass Routine) continue;
#IfV5;
		_k = _j.#add_to_scope;
		@log_shift _k (-1) -> _k;
		@scan_table _i _l _k -> _m ?~failed;
		return _j;
.failed;
#IfNot;
		_k = (_j.#add_to_scope)/WORDSIZE;
		for (_m=0 : _m<_k : _m++) if (_l-->_m == _i) return _j;
#EndIf;
	}
	rfalse;
];



[ _FindBarrier p_ancestor p_obj p_dontprint;
	while (p_obj ~= p_ancestor) {
		if (_g_check_take && p_obj hasnt container && p_obj hasnt supporter) {
                        ! We're going to return true here, we just need to write the correct message
                        ! But if we don't need to print anything, just return now
                        if (p_dontprint) rtrue;

			if (p_obj has animate) {
				PrintMsg(MSG_TAKE_BELONGS, _g_item, p_obj); rtrue;
			}
			if (p_obj has transparent) {
				PrintMsg(MSG_TAKE_PART_OF, _g_item, p_obj); rtrue;
			}
			PrintMsg(MSG_TAKE_NOT_AVAILABLE); rtrue;
		}
		if(p_obj has container && p_obj hasnt open &&
			(_g_check_visible == false || p_obj hasnt transparent)) {
			if(p_dontprint == false) PrintMsg(MSG_TOUCHABLE_FOUND_CLOSED, p_obj);
			_g_check_visible = false;
			rtrue;
		}
		p_obj = parent(p_obj);
	}
	rfalse;
];

[ ObjectIsUntouchable p_item p_dontprint p_checktake _ancestor _i;
	! DM: ObjectIsUntouchable(obj,flag)
	! Determines whether any solid barrier, that is, any container that is
	! not open, lies between the player and obj. If flag is true, this
	! routine never prints anything; otherwise it prints a message like
	! “You can't, because ! … is in the way.” if any barrier is found.
	! The routine returns true if a barrier is found, false if not.

	_g_item = p_item;
	_g_check_take = p_checktake;

	_UpdateScope(player);

	_ancestor = CommonAncestor(player, p_item);
	if(_ancestor == 0) {
		_ancestor = p_item;
		while (_ancestor && (_i = _ObjectScopedBySomething(_ancestor)) == 0)
			_ancestor = parent(_ancestor);
		if(_i ~= 0) {
			if(ObjectIsUntouchable(_i, p_dontprint, p_checktake)) {
				! Item immediately added to scope
				_g_check_visible = false;
				rtrue;
			}
		}
	} else if(player ~= _ancestor) {
		_g_check_take = 0;
		if(_FindBarrier(_ancestor, parent(player), p_dontprint)) {
			! First, a barrier between the player and the ancestor.  The player
			! can only be in a sequence of enterable objects, and only closed
			! containers form a barrier.
			_g_check_visible = false;
			rtrue;
		}
		_g_check_take = p_checktake;
    }

	! Second, a barrier between the item and the ancestor.  The item can
	! be carried by someone, part of a piece of machinery, in or on top
	! of something and so on.
	if (p_item ~= _ancestor && _FindBarrier(_ancestor, parent(p_item), p_dontprint)) {
		_g_check_visible = false;
		rtrue;
	}
	_g_check_visible = false;
    rfalse;
];

[ ObjectIsInvisible p_item p_dontprint;
	_g_check_visible = true;
	return ObjectIsUntouchable(p_item, p_dontprint);
];
