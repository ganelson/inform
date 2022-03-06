! ######################### Grammar + Actions

! ---------------------
! Base verbs
! ---------------------

Verb 'answer' 'say' 'shout' 'speak'
    * topic 'to' creature                       -> Answer;

Verb 'ask'
	* creature 'about' topic                    -> Ask
	* creature 'for' noun                       -> AskFor
	* creature 'to' topic                       -> AskTo
	* 'that' creature topic                     -> AskTo;

Verb 'attack' 'break' 'crack' 'destroy'
     'fight' 'hit' 'kill' 'murder' 'punch'
     'smash' 'thump' 'torture' 'wreck'
    * noun                                      -> Attack
    * noun 'with' held                          -> Attack;

Verb 'climb' 'scale'
	* 'into'/'onto' noun                        -> Enter
	* 'out' 'of'/'from' noun                    -> Exit;

Verb 'close' 'cover' 'shut'
	* noun                                      -> Close
	* 'off' noun                                -> SwitchOff;

Verb 'cut' 'chop' 'prune' 'slice'
	* noun                                      -> Cut
	* noun 'with' held                          -> Attack;

Verb 'dig'
	* noun                                      -> Dig
	* noun 'with' held                          -> Dig;

Verb 'drink' 'sip' 'swallow'
    * noun                                      -> Drink;

Verb 'drop' 'discard' 'throw'
	* multiheld                                 -> Drop
	* multiexcept 'in'/'into'/'down' noun       -> Insert
	* held 'at'/'against'/'on'/'onto' noun      -> ThrowAt;

Verb 'eat'
    * held                                      -> Eat;

Verb 'enter'
	* noun                                      -> Enter;

Verb 'examine' 'x//'
	* noun -> Examine;

Verb 'exit' 'leave'
	*                                           -> Exit
	* noun                                      -> Exit;

Verb 'fill'
	* noun                                      -> Fill;

Verb 'get'
  * 'out'/'off'/'up' 'of'/'from' noun         -> Exit
  * 'up'/'out'                                -> Exit
  * multi                                     -> Take
  * 'in'/'into'/'on'/'onto' noun              -> Enter
  * 'off' noun                                -> GetOff
  * multiinside 'from'/'off' noun             -> Remove;

Verb 'give' 'feed' 'offer' 'pay'
	* held 'to' creature                        -> Give
	* creature held                             -> Give reverse
	* 'over' held 'to' creature                 -> Give;

[ ADirection;
	return (noun == Directions);
];

Verb 'go'
	* noun=ADirection                           -> Go
	* noun                                      -> Enter;

Verb 'insert'
    * multiexcept 'in'/'into' noun              -> Insert;

Verb 'inventory' 'i//'
	* -> Inv;

Verb 'jump'
	*                                           -> Jump
	* 'over' noun                               -> JumpOver
	* 'into'/'onto' noun                        -> Enter
	* 'out' 'of'/'from' noun                    -> Exit
	* 'off' noun                                -> Exit;

Verb 'listen'
	*                                           -> Listen
	* 'to' noun                                 -> Listen;

Verb 'lock'
	* noun 'with' held                          -> Lock;

Verb 'look' 'l//'
	*                                           -> Look
	* 'at' noun                                 -> Examine
	* 'in'/'inside' noun						-> Search;

Verb 'open' 'uncover' 'unwrap'
	* noun                                      -> Open
	* noun 'with' held                          -> Unlock;

Verb 'pick'
	* 'up' multi                                -> Take
	* multi 'up'                                -> Take;

Verb 'pull' 'drag'
    * noun                                      -> Pull;

Verb 'push' 'clear' 'move' 'press' 'shift'
    * noun                                      -> Push
    * noun noun                                 -> PushDir
    * noun 'to' noun                            -> Transfer;

Verb 'put'
	* multiexcept 'in'/'inside'/'into' noun     -> Insert
	* multiexcept 'on'/'onto' noun              -> PutOn
	* 'on' held									-> Wear;

Verb 'read'
	* noun                                      -> Examine
	* 'about' topic 'in' noun                   -> Consult
	* topic 'in' noun                           -> Consult;

Verb 'remove'
	* held                                      -> Disrobe
	* multi                                     -> Take
	* multiinside 'from' noun                   -> Remove;

Verb 'rub' 'clean' 'dust' 'polish' 'scrub' 'shine' 'sweep' 'wipe'
	* noun                                      -> Rub;

Verb 'search'
	* noun                                      -> Search;

Verb 'shed' 'disrobe' 'doff'
	* held                                      -> Disrobe;

Verb 'show' 'display' 'present'
	* creature held                             -> Show reverse
	* held 'to' creature                        -> Show;

Verb 'sit' 'lie'
	* 'on' 'top' 'of' noun                      -> Enter
	* 'on'/'in'/'inside' noun                   -> Enter;

Verb 'smell'
	*                                           -> Smell
	* noun                                      -> Smell;

Verb 'stand'
	*                                           -> Exit
	* 'up'                                      -> Exit
	* 'on' noun                                 -> Enter;

Verb 'switch'
	* noun                                      -> SwitchOn
	* noun 'on'                                 -> SwitchOn
	* noun 'off'                                -> SwitchOff
	* 'on' noun                                 -> SwitchOn
	* 'off' noun                                -> SwitchOff;

Verb 'take' 'carry' 'hold'
	* multi                                     -> Take
	* 'off' worn                                -> Disrobe
	* multiinside 'from'/'off' noun             -> Remove
	* 'inventory'                               -> Inv;

Verb 'tell'
	* creature 'about' topic                    -> Tell
	* creature 'to' topic                       -> AskTo;

Verb 'tie' 'attach' 'fasten' 'fix'
	* noun                                      -> Tie
	* noun 'to' noun                            -> Tie;

Verb 'touch'
	* noun                                      -> Touch;

Verb 'turn' 'rotate' 'screw' 'twist' 'unscrew'
	* noun                                      -> Turn
	* noun 'on'                                 -> SwitchOn
	* noun 'off'                                -> SwitchOff
	* 'on' noun                                 -> SwitchOn
	* 'off' noun                                -> SwitchOff;

Verb 'unlock'
	* noun 'with' held                          -> Unlock;

Verb 'wait' 'z'
    *                                           -> Wait;

Verb 'wear'
	* held										-> Wear;

[ AnswerSub;
	if (second > 1 && RunLife(second,##Answer) ~= 0) rfalse;
	PrintMsg(MSG_ANSWER_SUCCESS);
];

[ AskSub;
	if (RunLife(noun,##Ask) ~= 0) rfalse;
	PrintMsg(MSG_ASK_SUCCESS);
];

[ AskToSub;
	PrintMsg(MSG_ASKTO_SUCCESS);
];

[ AskForSub;
	if (noun == player) <<Inv>>;
	PrintMsg(MSG_ASKFOR_SUCCESS);
];

[ AttackSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun has animate && RunLife(noun, ##Attack) ~= 0) rfalse;
	PrintMsg(MSG_ATTACK_SUCCESS);
];

[ CloseSub;
	if(ObjectIsUntouchable(noun)) return;
	if(noun hasnt openable) { PrintMsg(MSG_CLOSE_YOU_CANT, 'close'); rtrue; }
	if(noun hasnt open) { PrintMsg(MSG_CLOSE_NOT_OPEN, noun); rtrue; }
	give noun ~open;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	if(AfterRoutines()) rtrue;
	if (keep_silent) return;
	PrintMsg(MSG_CLOSE_SUCCESS, 'close');
];

[ ConsultSub;
	PrintMsg(MSG_CONSULT_NOTHING_INTERESTING);
];

[ CutSub;
	PrintMsg(MSG_CUT_NO_USE);
];

[ DigSub;
	PrintMsg(MSG_DIG_NO_USE);
];

[ DisrobeSub;
    if (noun notin player || noun hasnt worn) { PrintMsg(MSG_DISROBE_NOT_WEARING); rtrue; }
    give noun ~worn;
    if (AfterRoutines()) rtrue;
    if (keep_silent) rtrue;
    PrintMsg(MSG_DISROBE_SUCCESS);
];

[ DrinkSub;
	PrintMsg(MSG_DRINK_NOTHING_SUITABLE);
];

[ DropSub _p;
	if(noun notin player) { PrintMsg(MSG_DROP_NOT_HOLDING); rtrue; }
	if(noun has worn) { PrintMsg(MSG_DROP_WORN); rtrue; }
	_p = parent(player);
	if(_p ~= location) <<Insert noun _p>>;
	move noun to parent(player);
	give noun moved;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	if(AfterRoutines()) rtrue;
	if(keep_silent) return;
	PrintMsg(MSG_DROP_DROPPED);
];

[ EatSub;
	if(ObjectIsUntouchable(noun)) return;
	if(noun has animate) { PrintMsg(MSG_EAT_ANIMATE); rtrue; }
	if(noun hasnt edible) { PrintMsg(MSG_EAT_INEDIBLE); rtrue; }
	remove noun;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	PrintMsg(MSG_EAT_SUCCESS);
];

[ EnterSub _door_dir;
	if(noun has door) {
		_door_dir = noun.door_dir;
		if(UnsignedCompare(_door_dir, top_object) > 0) {
			_door_dir = noun.door_dir();
		}
		! Convert to fake object
		_door_dir = DirPropToFakeObj(_door_dir);
		<<Go _door_dir>>;
	}
	if(noun hasnt enterable) { PrintMsg(MSG_ENTER_YOU_CANT, 'enter'); rtrue; }
	if(player in noun) { PrintMsg(MSG_ENTER_ALREADY); rtrue; }
	if(noun has container && noun hasnt open) { PrintMsg(MSG_ENTER_NOT_OPEN, noun); rtrue; }
	if(parent(noun) ~= parent(player)) { PrintMsg(MSG_ENTER_BAD_LOCATION); rtrue; }
	PlayerTo(noun, true);
	if(AfterRoutines()) rtrue;
	if (keep_silent) return;
	PrintMsg(MSG_ENTER_SUCCESS, 'enter');
];

[ ExamineSub x;
	if(location == thedark) {
		PrintMsg(MSG_EXAMINE_DARK);
		rtrue;
	}
    if (noun.description == 0) {
        if (noun has container) {
            if (noun has open or transparent) <<Search noun>>;
            else { PrintMsg(MSG_EXAMINE_CLOSED, noun); rtrue;	}
		}
        if (noun has switchable) { PrintMsg(MSG_EXAMINE_ONOFF); rtrue; }
		PrintMsg(MSG_EXAMINE_NOTHING_SPECIAL);
    }
	x = PrintOrRun(noun, description);
	if (x < 2 && noun has switchable) PrintMsg(MSG_EXAMINE_ONOFF);
	AfterRoutines();
];

[ ExitSub;
	if(noun == 0) noun = parent(player);
	if(player in location) { PrintMsg(MSG_EXIT_ALREADY); rtrue; }
	if(player notin noun) {
		if(IndirectlyContains(noun, player)) { PrintMsg(MSG_EXIT_FIRST_LEAVE, parent(player)); rtrue; }
		if(noun has supporter) { PrintMsg(MSG_EXIT_NOT_ON); rtrue; }
		PrintMsg(MSG_EXIT_NOT_IN);
		rtrue;
	}
	if(noun has container && noun hasnt open) { PrintMsg(MSG_EXIT_NOT_OPEN, noun); rtrue; }
	PlayerTo(parent(noun), true);
	if(AfterRoutines()) rtrue;
	if (keep_silent) return;
	PrintMsg(MSG_EXIT_SUCCESS, 'leave');
];

[ FillSub;
	PrintMsg(MSG_FILL_NO_WATER);
];

[ GetOffSub;
	if (parent(player) == noun) <<Exit>>;
	PrintMsg(MSG_EXIT_NOT_ON); rtrue;
];


[ GiveSub;
	if(ObjectIsUntouchable(second)) return;
	if (parent(noun) ~= player) { PrintMsg(MSG_GIVE_NOT_HOLDING); rtrue; }
	if (second == player)  { PrintMsg(MSG_GIVE_PLAYER); rtrue; }
	if (RunLife(second, ##Give) ~= 0) rfalse;
	PrintMsg(MSG_GIVE_SUCCESS);
];

[ GoSub _prop;
	! when called Directions have been set properly
	_prop = selected_direction;
#IfTrue RUNTIME_ERRORS > RTE_MINIMUM;
	if(_prop == 0) return RuntimeError(ERR_INVALID_DIR_PROP);
#EndIf;

	GoDir(_prop);
];

[ InsertSub _ancestor;
	receive_action = ##Insert;
	if(ObjectIsUntouchable(second)) return;
	if (parent(noun) == second) { PrintMsg(MSG_INSERT_ALREADY); rtrue; }
	_ancestor = CommonAncestor(noun, second);
	if (_ancestor == noun) { PrintMsg(MSG_INSERT_ITSELF); rtrue; }
	if (second ~= _ancestor && second has container && second hasnt open) {
		PrintMsg(MSG_INSERT_NOT_OPEN, second);
		rtrue;
	}

	_GrabIfNotHeld(noun);
	if (noun notin player) rtrue;
	if(noun has worn) { PrintMsg(MSG_INSERT_WORN); rtrue; }

	! run before on receiver
#IfDef DEBUG;
	if(debug_flag & 1) print "(", (name) second, ").before()^";
#EndIf;
	action = ##Receive;
	if(RunRoutines(second, before) ~= 0) { action = ##Insert; rtrue; }
	action = ##Insert;

	if (second hasnt container) { PrintMsg(MSG_INSERT_NOT_CONTAINER); rtrue; }
	if (_AtFullCapacity(second)) { PrintMsg(MSG_INSERT_NO_ROOM); rtrue; }

	move noun to second;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;

	! run after on object
	if(AfterRoutines()) rtrue;

	! run after on receiver
#IfDef DEBUG;
	if(debug_flag & 1) print "(", (name) second, ").after()^";
#EndIf;
	action = ##Receive;
	if(RunRoutines(second, after) ~= 0) { action = ##Insert; rtrue; }
	action = ##Insert;

	if (keep_silent) return;
	PrintMsg(MSG_INSERT_SUCCESS);
];

[ InvSub;
	if(child(player) == 0) { PrintMsg(MSG_INVENTORY_EMPTY); rtrue; }
    PrintMsg(MSG_INVENTORY_SUCCESS);
	AfterRoutines();
];

[ JumpSub;
	PrintMsg(MSG_JUMP);
];

[ JumpOverSub;
	PrintMsg(MSG_JUMP_OVER);
];

[ ListenSub;
    PrintMsg(MSG_LISTEN_SUCCESS);
];

[ LockSub;
	if (ObjectIsUntouchable(noun)) return;
	if (ObjectIsUntouchable(second)) return;
	if (noun hasnt lockable) { PrintMsg(MSG_LOCK_NOT_A_LOCK, 'lock'); rtrue; }
	if (noun has locked)  { PrintMsg(MSG_LOCK_ALREADY_LOCKED, 'lock'); rtrue; }
	if (noun has open) { PrintMsg(MSG_LOCK_CLOSE_FIRST); rtrue; }
	if (RunRoutines(noun, with_key) ~= second) { PrintMsg(MSG_LOCK_KEY_DOESNT_FIT); rtrue; }
	give noun locked;
	if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	PrintMsg(MSG_LOCK_SUCCESS, 'lock');
];

[ LookSub _old_lookmode;
	_old_lookmode = lookmode;
	lookmode = 2; ! force long description
	Look();
	lookmode = _old_lookmode;
];

[ OpenSub;
	if(ObjectIsUntouchable(noun)) return;
	if(noun hasnt openable) { PrintMsg(MSG_OPEN_YOU_CANT, 'open'); rtrue; }
	if(noun has locked) { PrintMsg(MSG_OPEN_LOCKED); rtrue; }
	if(noun has open) { PrintMsg(MSG_OPEN_ALREADY); rtrue; }
	give noun open;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	if(AfterRoutines()) rtrue;
	if (keep_silent) return;
	PrintMsg(MSG_OPEN_SUCCESS, 'open');
];

[ PullSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun has static)   { PrintMsg(MSG_PULL_STATIC); rtrue; }
	if (noun has scenery)  { PrintMsg(MSG_PULL_SCENERY); rtrue; }
	if (noun has animate)  { PrintMsg(MSG_PULL_ANIMATE); rtrue; }
	PrintMsg(MSG_PULL_SUCCESS); !Nothing obvious happens
];

[ PushSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun has static)   { PrintMsg(MSG_PUSH_STATIC); rtrue; }
	if (noun has scenery)  { PrintMsg(MSG_PUSH_SCENERY); rtrue; }
	if (noun has animate)  { PrintMsg(MSG_PUSH_ANIMATE); rtrue; }
	PrintMsg(MSG_PUSH_SUCCESS);
];

[ PushDirSub;
	PrintMsg(MSG_PUSHDIR_DEFAULT);
];

[ PutOnSub _ancestor;
	receive_action = ##PutOn;

	if (ObjectIsUntouchable(second)) return;
	if (parent(noun) == second) { PrintMsg(MSG_PUTON_ALREADY); rtrue; }
	_ancestor = CommonAncestor(noun, second);
	if (_ancestor == noun) { PrintMsg(MSG_PUTON_ITSELF); rtrue; }
	_GrabIfNotHeld(noun);
	if(noun notin player) rtrue;
	if(noun has worn) { PrintMsg(MSG_PUTON_WORN); rtrue; }

	! run before on receiver
#IfDef DEBUG;
	if(debug_flag & 1) print "(", (name) second, ").before()^";
#EndIf;
	action = ##Receive;
	if(RunRoutines(second, before) ~= 0) { action = ##PutOn; rtrue; }
	action = ##PutOn;

	if (second hasnt supporter) { PrintMsg(MSG_PUTON_NOT_SUPPORTER); rtrue; }
	if (_AtFullCapacity(second)) { PrintMsg(MSG_PUTON_NO_ROOM); rtrue; }

	move noun to second;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;

	! run after on receiver
#IfDef DEBUG;
	if(debug_flag & 1) print "(", (name) second, ").after()^";
#EndIf;
	action = ##Receive;
	if(RunRoutines(second, after) ~= 0) { action = ##PutOn; rtrue; }
	action = ##PutOn;

	if(AfterRoutines()) rtrue;
	if (keep_silent) return;
	PrintMsg(MSG_PUTON_SUCCESS);
];

[ RemoveSub _i;
	_i = parent(noun);
	if (_i has container && _i hasnt open) { PrintMsg(MSG_REMOVE_CLOSED, _i); rtrue; }
	if (_i ~= second) { PrintMsg(MSG_REMOVE_NOT_HERE); rtrue; }
	if (_i has animate) { PrintMsg(MSG_TAKE_ANIMATE); rtrue; }
	if(TryToTakeNoun() == 1) rtrue;
	action = ##Remove; if (AfterRoutines()) rtrue;
	action = ##Take;   if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	PrintMsg(MSG_REMOVE_SUCCESS);
];

[ RubSub;
	PrintMsg(MSG_RUB_DEFAULT);
];

[ SearchSub _f _i;
	if(location == thedark) { PrintMsg(MSG_SEARCH_DARK); rtrue; }
	if (ObjectIsUntouchable(noun)) return;
	objectloop(_i in noun) if(_i hasnt concealed && _i hasnt scenery) _f++;
	if(noun has supporter) {
		if(_f == 0)
			PrintMsg(MSG_SEARCH_NOTHING_ON);
		else
			PrintMsg(MSG_SEARCH_ON_IT_ISARE);
		rtrue;
	}
	if(noun hasnt container) { PrintMsg(MSG_SEARCH_NOTHING_SPECIAL); rtrue; }
	if(noun hasnt transparent && noun hasnt open) {
		PrintMsg(MSG_SEARCH_CANT_SEE_CLOSED); rtrue;
	}
	if(AfterRoutines()) rtrue;
	if(_f == 0)
		PrintMsg(MSG_SEARCH_EMPTY);
	else
		PrintMsg(MSG_SEARCH_IN_IT_ISARE);
];

[ ShowSub;
	if (parent(noun) ~= player) { PrintMsg(MSG_SHOW_NOT_HOLDING); rtrue; }
	if (second == player) <<Examine noun>>;
	if (RunLife(second, ##Show) ~= 0) rfalse;
	PrintMsg(MSG_SHOW_SUCCESS);
];

[ SmellSub;
	if(ObjectIsUntouchable(noun)) return;
	PrintMsg(MSG_SMELL_SUCCESS);
];

[ SwitchOffSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun hasnt switchable) { PrintMsg(MSG_SWITCH_OFF_NOT_SWITCHABLE); rtrue; }
	if (noun hasnt on)         { PrintMsg(MSG_SWITCH_OFF_NOT_ON); rtrue; }
	give noun ~on;
	if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	PrintMsg(MSG_SWITCH_OFF_SUCCESS);
];

[ SwitchOnSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun hasnt switchable) { PrintMsg(MSG_SWITCH_ON_NOT_SWITCHABLE); rtrue; }
	if (noun has on)           { PrintMsg(MSG_SWITCH_ON_ON); rtrue; }
	give noun on;
	if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	PrintMsg(MSG_SWITCH_ON_SUCCESS);
];

[ TakeSub;
	if(TryToTakeNoun() == 1) rtrue;
	if(AfterRoutines()) rtrue;
	if (keep_silent) return;
	PrintMsg(MSG_TAKE_SUCCESS);
];

[ TieSub;
	PrintMsg(MSG_TIE_DEFAULT);
];

[ TellSub;
	if (noun == player) { PrintMsg(MSG_TELL_PLAYER); rtrue; }
	if (RunLife(noun, ##Tell) ~= 0) rfalse;
	PrintMsg(MSG_TELL_SUCCESS);
];

[ ThrowAtSub;
	_GrabIfNotHeld(noun);
	if(noun notin player) rtrue;
	if(ObjectIsUntouchable(second)) return;
	if(noun has worn) { PrintMsg(MSG_THROW_WORN); rtrue; }
	if(second > 1) {
#IfDef DEBUG;
		if(debug_flag & 1) print "(", (name) second, ").before()^";
#EndIf;
		action = ##ThrownAt;
		if (RunRoutines(second, before) ~= 0) { action = ##ThrowAt; rtrue; }
		action = ##ThrowAt;
	}
	if(second hasnt animate) { PrintMsg(MSG_THROW_ANIMATE); rtrue; }
	if(RunLife(second,##ThrowAt) ~= 0) rfalse;
	PrintMsg(MSG_THROW_SUCCESS);
];

[ TouchSub;
	if(ObjectIsUntouchable(noun)) return;
	PrintMsg(MSG_TOUCH_SUCCESS);
];

[ TransferSub;
	_GrabIfNotHeld(noun);
	if (noun notin player) rtrue;
	if (second has supporter) <<PutOn noun second>>;
	!if (second == d_obj) <<Drop noun>>;
	<Insert noun second>;
];

[ TurnSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun has static)   { PrintMsg(MSG_TURN_STATIC); rtrue; }
	if (noun has scenery)  { PrintMsg(MSG_TURN_SCENERY); rtrue; }
	if (noun has animate)  { PrintMsg(MSG_TURN_ANIMATE); rtrue; }
	PrintMsg(MSG_TURN_SUCCESS);
];

[ UnlockSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun hasnt lockable) { PrintMsg(MSG_UNLOCK_NOT_A_LOCK, 'unlock'); rtrue; }
	if (noun hasnt locked)  { PrintMsg(MSG_UNLOCK_ALREADY_UNLOCKED, 'unlock'); rtrue; }
	if (RunRoutines(noun, with_key) ~= second) { PrintMsg(MSG_UNLOCK_KEY_DOESNT_FIT); rtrue; }
	give noun ~locked;
	if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	PrintMsg(MSG_UNLOCK_SUCCESS, 'unlock');
];

[ WaitSub;
    PrintMsg(MSG_WAIT_SUCCESS);
];

[ WearSub;
	if (parent(noun) ~= player) { PrintMsg(MSG_WEAR_NOT_HOLDING); rtrue; }
	if (noun has worn) { PrintMsg(MSG_WEAR_ALREADY_WORN); rtrue; }
	if (noun hasnt clothing) { PrintMsg(MSG_WEAR_NOT_CLOTHING, 'wear'); rtrue; }
	give noun worn;
	if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	PrintMsg(MSG_WEAR_SUCCESS);
];


! ---------------------
! Extended verbs
! ---------------------

#IfDef OPTIONAL_EXTENDED_VERBSET;

Verb 'blow'
	* held                                      -> Blow;

Verb 'bother' 'curses' 'darn' 'drat'
	*                                           -> Mild
	* topic                                     -> Mild;

Verb 'burn' 'light'
	* noun                                      -> Burn
	* noun 'with' held                          -> Burn;

Verb 'buy' 'purchase'
	* noun                                      -> Buy;

Verb 'consult'
	* noun 'about' topic                        -> Consult
	* noun 'on' topic                           -> Consult;

Verb 'empty'
	* noun                                      -> Empty
	* 'out' noun                                -> Empty
	* noun 'out'                                -> Empty
	* noun 'to'/'into'/'on'/'onto' noun         -> EmptyT;

Verb 'in' 'inside'
	*                                           -> GoIn;

Verb 'kiss' 'embrace' 'hug'
    * creature                                  -> Kiss;

Verb 'no'
	*                                           -> No;

Verb 'peel'
	* noun                                      -> Take
	* 'off' noun                                -> Take;

Verb 'pray'
    *                                           -> Pray;

Verb 'pry' 'prise' 'prize' 'lever' 'jemmy' 'force'
	* noun 'with' held                          -> Unlock
	* 'apart'/'open' noun 'with' held           -> Unlock
	* noun 'apart'/'open' 'with' held           -> Unlock;

Verb 'set' 'adjust'
	* noun                                      -> Set
	* noun 'to' special                         -> SetTo;

Verb 'shit' 'damn' 'fuck' 'sod'
	*                                           -> Strong
	* topic                                     -> Strong;

Verb 'sing'
	*                                           -> Sing;

Verb 'sleep' 'nap'
	*                                           -> Sleep;

Verb 'sorry'
	*                                           -> Sorry;

Verb 'squeeze' 'squash'
	* noun                                      -> Squeeze;

Verb 'swim' 'dive'
	*                                           -> Swim;

Verb 'swing'
	* noun                                      -> Swing
	* 'on' noun                                 -> Swing;

Verb 'taste'
	* noun                                      -> Taste;

Verb 'think'
	*                                           -> Think;

Verb 'transfer'
	* noun 'to' noun                            -> Transfer;

Verb 'wake' 'awake' 'awaken'
    *                                           -> Wake
    * 'up'                                      -> Wake
    * creature                                  -> WakeOther
    * creature 'up'                             -> WakeOther
    * 'up' creature                             -> WakeOther;

Verb 'wave'
	*                                           -> WaveHands
	* noun                                      -> Wave;

Verb 'yes' 'y//'
	*                                           -> Yes;

[ BlowSub;
	PrintMsg(MSG_BLOW_DEFAULT);
];

[ BurnSub;
	PrintMsg(MSG_BURN_DEFAULT);
];

[ BuySub;
	PrintMsg(MSG_BUY_DEFAULT);
];

[ EmptySub;
	<EmptyT noun FAKE_D_OBJ>;
];

[ EmptyTSub _i _j _k _flag _recipient;
	if(noun == second) { PrintMsg(MSG_EMPTY_WOULDNT_ACHIEVE); rtrue; }
	if(ObjectIsUntouchable(noun) || ObjectIsUntouchable(second)) return;
!		_recipient = TouchCeiling(player);
	if(selected_direction ~= d_to) {
!	else {
		_recipient = second;
		if(second hasnt supporter) {
  		if(second hasnt container) { PrintMsg(MSG_EMPTY_CANT_CONTAIN, second); rtrue; }
  		if(second hasnt open) { PrintMsg(MSG_EMPTY_IS_CLOSED, second); rtrue; }
		}
	}
	_i = child(noun); _k = children(noun);
	if(_i == 0) { PrintMsg(MSG_EMPTY_ALREADY_EMPTY, noun); rtrue; }
	while(_i ~= 0) {
		_j = sibling(_i);
		_flag = 0;
		if(ObjectIsUntouchable(noun)) _flag = 1;
		if(noun hasnt container) _flag = 1;
		if(noun hasnt open) _flag = 1;
		if(selected_direction ~= d_to) {
			if(second hasnt supporter) {
				if(second hasnt container) _flag = 1;
				if(second hasnt open) _flag = 1;
			}
		}
		if(_k-- == 0) _flag = 1;
		if(_flag) break;
		if(keep_silent == 0) print (name) _i, ": ";
		if(selected_direction == d_to) {
	    _GrabIfNotHeld(_i);
			<Drop _i>;
		} else
			<Transfer _i _recipient>;
		_i = _j;
	}
];

[ GoInSub;
	! shortcut to <<Go in>>
	<Go FAKE_IN_OBJ>;
];

[ KissSub;
    if (ObjectIsUntouchable(noun)) return;
    if (RunLife(noun, ##Kiss) ~= 0) rfalse;
    if (noun == player) { PrintMsg(MSG_KISS_PLAYER); rtrue; }
    PrintMsg(MSG_KISS_SUCCESS);
];

[ MildSub;
	PrintMsg(MSG_MILD_DEFAULT);
];

[ NoSub;
	PrintMsg(MSG_RHETORICAL_QUESTION);
];

[ PraySub;
	PrintMsg(MSG_PRAY_DEFAULT);
];

[ SetSub;
	PrintMsg(MSG_SET_DEFAULT);
];

[ SetToSub;
	PrintMsg(MSG_SET_TO_DEFAULT);
];

[ SingSub;
	PrintMsg(MSG_SING_DEFAULT);
];

[ SleepSub;
	PrintMsg(MSG_SLEEP_DEFAULT);
];

[ SorrySub;
	PrintMsg(MSG_SORRY_DEFAULT);
];

[ StrongSub;
	PrintMsg(MSG_STRONG_DEFAULT);
];

[ SqueezeSub;
	if (ObjectIsUntouchable(noun)) return;
	if (noun has animate) { PrintMsg(MSG_SQUEEZE_YOURSELF); rtrue; }
	PrintMsg(MSG_SQUEEZE_DEFAULT);
];

[ SwimSub;
	PrintMsg(MSG_SWIM_DEFAULT);
];

[ SwingSub;
	PrintMsg(MSG_SWING_DEFAULT);
];

[ TasteSub;
	if (ObjectIsUntouchable(noun)) return;
	PrintMsg(MSG_TASTE_DEFAULT);
];

[ ThinkSub;
	PrintMsg(MSG_THINK_DEFAULT);
];

[ WakeSub;
    PrintMsg(MSG_WAKE_SUCCESS);
];

[ WakeOtherSub;
    if (ObjectIsUntouchable(noun)) return;
    if (RunLife(noun, ##WakeOther) ~= 0) rfalse;
    PrintMsg(MSG_WAKEOTHER_SUCCESS);
];

[ WaveSub;
    if(parent(noun) ~= player) { PrintMsg(MSG_WAVE_NOTHOLDING, noun); rtrue; }
    PrintMsg(MSG_WAVE_DEFAULT);
];

[ WaveHandsSub;
	PrintMsg(MSG_WAVEHANDS_DEFAULT);
];

[ YesSub;
	PrintMsg(MSG_RHETORICAL_QUESTION);
];

#EndIf;

! ---------------------
! Base meta verbs
! ---------------------

Verb meta 'again' 'g//'
    *                                           -> Again;

Verb meta 'brief' 'normal'
	*                                           -> LookModeNormal;

#IfDef OPTIONAL_FULL_SCORE;
Verb meta 'fullscore' 'full'
    *                                           -> FullScore
    * 'score'                                   -> FullScore;
#EndIf;

Verb meta 'notify'
	*                                           -> NotifyOn
	* 'on'                                      -> NotifyOn
	* 'off'                                     -> NotifyOff;

Verb meta 'oops'
    *                                           -> Oops
    * special                                   -> OopsCorrection;

Verb meta 'restart'
	*                                           -> Restart;

Verb meta 'restore'
	*                                           -> Restore;

Verb meta 'save'
	*                                           -> Save;

Verb meta 'score'
    *                                           -> Score;

Verb meta 'superbrief' 'short'
	*                                           -> LookModeShort;

Verb meta 'verbose' 'long'
	*                                           -> LookModeLong;

Verb meta 'version'
	*                                           -> Version;

Verb meta 'quit' 'q//'
	*                                           -> Quit;

[ AgainSub;
	! nothing here - this is taken care of in the main game loop instead
];

#IfDef OPTIONAL_FULL_SCORE;
[ FullScoreSub _i;
	ScoreSub();
	new_line;
	PrintMsg(MSG_FULLSCORE_START);
#IfDef TASKS_PROVIDED;
	for(_i=0 : _i<NUMBER_TASKS : _i++)
		if (task_done->_i == 1) {
		PANum(task_scores->(_i));
		PrintTaskName(_i);
	}
#IfNot;
	_i = 0; ! Avoid warning
#EndIf;
	if(things_score ~= 0) {
		PANum(things_score);
		print "finding sundry items^";
	}
	if(places_score ~= 0) {
		PANum(places_score);
		print "visiting various places^";
	}
	@new_line;
	PANum(score);
	PrintMsg(MSG_FULLSCORE_END);
];
#EndIf;

[ LookModeNormalSub;
	lookmode=1;
	PrintMsg(MSG_LOOKMODE_NORMAL);
];

[ LookModeLongSub;
	lookmode=2;
	PrintMsg(MSG_LOOKMODE_LONG);
];

[ LookModeShortSub;
	lookmode=3;
	PrintMsg(MSG_LOOKMODE_SHORT);
];

[ NotifyOnSub;
	notify_mode = 1;
	"Score notification on.";
];

[ NotifyOffSub;
	notify_mode = 0;
	"Score notification off.";
];

[ OopsSub;
	"Think nothing of it.";
];

[ OopsCorrectionSub;
	! nothing here - this is taken care of in the main game loop instead
];

[ QuitSub;
	PrintMsg(MSG_AREYOUSUREQUIT);
	if(YesOrNo()) {
		deadflag = GS_QUIT;
	}
];

[ RestartSub;
    PrintMsg(MSG_RESTART_CONFIRM);
	if(YesOrNo()) {
		@restart;
        PrintMsg(MSG_RESTART_FAILED);
	}
];

#IfV3;
[ RestoreSub;
	@restore ?restore_success; ! can't use @restore because of compiler test
	PrintMsg(MSG_RESTORE_FAILED);
	rtrue;
.restore_success; ! This is never reached, since a successful restore continues after save opcode.
#IfNot;
[ RestoreSub _flag;
	@restore -> _flag;
	! must have failed here so no need to check the flag
	PrintMsg(MSG_RESTORE_FAILED);
#EndIf;
];

#IfV3;
[ SaveSub;
	@save ?save_success;
	PrintMsg(MSG_SAVE_FAILED);
	rtrue;
.save_success;
    PrintMsg(MSG_SAVE_SUCCESS);
#IfNot;
[ SaveSub _result;
	@save -> _result;
	if(_result == 0) { PrintMsg(MSG_SAVE_FAILED); rtrue; }
	PrintMsg(MSG_SAVE_SUCCESS); ! _result = 1: save ok, 2: Restore ok
#EndIf;
];

[ ScoreSub;
	PrintMsg(MSG_SCORE_SUCCESS);
	PrintRank();
];

[ Banner _i;
	if(Story ~= 0) {
#IfV5;
		style bold;
#EndIf;
		print (string) Story;
#IfV5;
		style roman;
#EndIf;
		if(Headline ~= 0) print (string) Headline;
    }
	print "Release ", (0-->1) & $03ff, " / Serial number ";
	for (_i = 18:_i < 24: _i++) print (char) 0->_i;
	print " / Inform v";
	inversion;
	print " PunyInform v", PUNYINFORM_MAJOR_VERSION, (char) '.', PUNYINFORM_MINOR_VERSION;
#IfDef DEBUG;
	print " D";
#EndIf;
	@new_line;
];

[ VersionSub;
	Banner();
];

! ---------------------
! Extended meta verbs
! ---------------------

#IfDef OPTIONAL_EXTENDED_METAVERBS;
Constant HDR_GAMEFLAGS     $10;
Global transcript_mode = false;        ! true when game scripting is on
Global xcommsdir = false;              ! true if command recording is on

Verb meta 'noscript' 'unscript'
	*                                           -> ScriptOff;

#Ifndef NO_PLACES;
Verb meta 'objects'
	*                                           -> Objects;
Verb meta 'places'
	*                                           -> Places;
#Endif; ! NO_PLACES

Verb meta 'recording'
	*                                           -> CommandsOn
	* 'on'                                      -> CommandsOn
	* 'off'                                     -> CommandsOff;

Verb meta 'replay'
	*                                           -> CommandsRead;

Verb meta 'script' 'transcript'
	*                                           -> ScriptOn
	* 'on'                                      -> ScriptOn
	* 'off'                                     -> ScriptOff;

Verb meta 'verify'
	*                                           -> Verify;

[ CommandsOnSub;
	@output_stream 4;
	xcommsdir = 1;
	"[Command recording on.]";
];

[ CommandsOffSub;
	if (xcommsdir == 1) @output_stream -4;
	xcommsdir = 0;
	"[Command recording off.]";
];

[ CommandsReadSub;
	@input_stream 1;
	xcommsdir = 2;
	"[Replaying commands.]";
];

#Ifndef NO_PLACES;
[ PlacesSub i j k;
	print "You have visited: ";
	objectloop(i has visited) if(parent(i) == 0) j++;
	objectloop(i has visited) {
		if(parent(i) == 0) {
			print (name) i; k++;
			if (k == j) { print ".^"; return; }
			if (k == j-1) print " and ";
			else          print ", ";
		}
	}
];

[ ObjectsSub i j f;
	print "Objects you have handled: ";
	objectloop (i has moved) {
		j = parent(i);
		if(j) {
			if(f == 0) @new_line;
			f = 1;
			print "- ", (the) i, "   ";
			if (j == player) {
				if (i has worn) {
					print "(worn)";
				} else {
					print "(held)";
				}
			} else if(j has animate) print "(given away)";
			else if(j has visited) print "(in ", (name) j, ")";
			else if(j has container) print "(inside ", (the) j, ")";
			else if(j has supporter) print "(on ", (the) j, ")";
			else if(j has enterable) print "(in ", (the) j, ")";
			else print "(lost)";
			@new_line;
		}
	}
	if(f == 0) "none.";
];
#Endif; ! NO_PLACES

[ ScriptOnSub;
	transcript_mode = ((HDR_GAMEFLAGS-->0) & 1);
	if (transcript_mode) "Transcripting is already on.";
	@output_stream 2;
	if (((HDR_GAMEFLAGS-->0) & 1) == 0) "Attempt to begin transcript failed.";
	print "Start of a transcript of^";
	Banner();
	transcript_mode = true;
];

[ ScriptOffSub;
	transcript_mode = ((HDR_GAMEFLAGS-->0) & 1);
	if (transcript_mode == false) "Transcripting is already off.";
	print "^End of transcript.^";
	@output_stream -2;
	if ((HDR_GAMEFLAGS-->0) & 1) "Attempt to end transcript failed.";
	transcript_mode = false;
];

[ VerifySub;
	@verify ?Vmaybe;
	jump Vwrong;
.Vmaybe;
	"The game file has verified as intact.";
.Vwrong;
	"The game file did not verify as intact, and may be corrupt.";
];


#EndIf;

! ---------------------
! Debug verbs
! ---------------------

#IfDef DEBUG;
Verb meta 'pronoun' 'pronouns'
    *                                           -> Pronouns;

Verb meta 'random'
	*                                           -> RandomSeed
	* special                                   -> RandomSeed
	* 'seed' number                             -> RandomSeed;

Verb meta 'scope'
	*                                           -> Scope
	* noun                                      -> Scope;

Verb meta 'purloin'
	* noun										-> Purloin;

Verb meta 'tree'
	*											-> Tree
	* noun										-> Tree;

Verb meta 'gonear'
	* noun										-> GoNear;

Verb meta 'routines' 'messages'
	*                                           -> RoutinesOn
	* 'on'                                      -> RoutinesOn
	* 'off'                                     -> RoutinesOff;

Verb meta 'actions'
	*                                           -> ActionsOn
	* 'on'                                      -> ActionsOn
	* 'off'                                     -> ActionsOff;

Verb meta 'timers' 'daemons'
	*                                           -> TimersOn
	* 'on'                                      -> TimersOn
	* 'off'                                     -> TimersOff;


Global scope_cnt;

[ GoNearSub _obj;
	_obj = noun;
	while(parent(_obj) ~= 0) _obj = parent(_obj);
	PlayerTo(_obj);
];

[ PronounsSub;
	print "Pronouns: it ", (name) itobj, ", he ", (name) himobj, ", she ", (name) herobj, "^";
];

[ PurloinSub;
	if(noun == player) { PrintMsg(MSG_TAKE_YOURSELF); rtrue; }
	if(IndirectlyContains(noun, player)) { PrintMsg(MSG_TAKE_PLAYER_PARENT, noun); rtrue; }

	move noun to player;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;
	"Purloined.";
];

[ RandomSeedSub _i;
	! sets the random seed, making randomness predictable
	! also a test of special and number, thus the fancy grammar
	!print special_word, " ", special_number," ",parsed_number,"^";
	if(special_word ~=0) "You can't send randomness to an object!";
	_i = parsed_number;
	if(_i == 0) _i = 100; ! either 'xxxx' (unknown special) or '0'
	random(-_i);
	"The random seed is set to ", _i, ".";
];

[ _ScopeSubHelper p_obj;
	print scope_cnt++,": ", (a) p_obj, " (", p_obj, ")";
	if(ObjectIsUntouchable(p_obj, true)) print " [untouchable]";
	if(ObjectIsInvisible(p_obj, true)) print " [invisible]";
	@new_line;
];

[ ScopeSub;
	scope_cnt = 1;
	LoopOverScope(_ScopeSubHelper, noun);
	if(scope_cnt == 0) "Nothing in scope.^";
];

[ TreeSub _obj _p;
	_obj = noun;
	if(_obj==0) _obj = real_location;
	print (name) _obj;
	_p = parent(_obj);
	if(_p) {
		print " (";
		if(_p has supporter)
			@print_char 'o';
		else
			@print_char 'i';
		print "n ", (name) _p, ")";
	}
	@new_line;
	TreeSubHelper(_obj, 1);
];

[TreeSubHelper p_parent p_indent _x _i;
	objectloop(_x in p_parent) {
		for(_i = 0 : _i < p_indent : _i++) print "  ";
		print (name) _x, "^";
		if(child(_x)) TreeSubHelper(_x, p_indent + 1);
	}
];

[ RoutinesOnSub;  debug_flag = debug_flag | 1;  "[Message listing on.]"; ];

[ RoutinesOffSub; debug_flag = debug_flag & 14; "[Message listing off.]"; ];

[ ActionsOnSub;   debug_flag = debug_flag | 2;  "[Action listing on.]"; ];

[ ActionsOffSub;  debug_flag = debug_flag & 13; "[Action listing off.]"; ];

[ TimersOnSub;    debug_flag = debug_flag | 4;  "[Timers listing on.]"; ];

[ TimersOffSub;   debug_flag = debug_flag & 11; "[Timers listing off.]"; ];


#EndIf;

! ---------------------
! HELP ROUTINES
! ---------------------

[ _ListObjsMsg;
	print "^You can ";
	if(also_flag) print "also ";
	print "see ";
];

[ _ListObjsInOnMsg p_parent;
	if(p_parent has supporter) print "^On "; else print "^In ";
	print (the) p_parent, " you can ";
	if(also_flag) print "also ";
	print "see ";
];

[ Look _obj _top_ceil _ceil _initial_found _describe_room _you_can_see_1 _you_can_see_2 _desc_prop _last_level _action;
	@new_line;
	if((lookmode == 1 && location hasnt visited) || lookmode == 2) _describe_room = true;
#IfV5;
	style bold;
#EndIf;
	! write the room name
	if(location == thedark)
		_ceil = location;
	else
		_ceil = ScopeCeiling(player, _last_level);
	_top_ceil = _ceil;

	if(_ceil == location) {
#IfDef OPTIONAL_FULL_SCORE;
		if(location has scored && location hasnt visited) {
			score = score + ROOM_SCORE;
			places_score = places_score + ROOM_SCORE;
		}
#EndIf;
		_PrintObjName(location);
	} else {
		print (The) _ceil;
	}
#IfV5;
	style roman;
#EndIf;
	if(location == thedark) {
		@new_line;
		PrintOrRun(location, description);
	} else {
		_obj = parent(player);
		while(_obj ~= _ceil or 0) {
			if(_obj has supporter)
				print " (on ";
			else
				print " (in ";
			print (the) _obj, ")";
			_obj = parent(_obj);
		}
		while(_ceil ~= player or 0) {
			if(_describe_room) {
				if(_ceil == location) {
					@new_line;
					PrintOrRun(_ceil, description);
				} else if(_ceil.inside_description ~= 0 or NULL) {
					@new_line;
					PrintOrRun(_ceil, inside_description);
				}
			} else if(_ceil == location)
				@new_line;

			also_flag = false;
			! write intial and describe messages in a new paragraph
			objectloop(_obj in _ceil) {
				give _obj workflag;
				if(_obj.&describe) {
					if(PrintOrRun(_obj, describe, 0)) {
						_initial_found = true;
						give _obj ~workflag;
						also_flag = true;
						continue;
					}
				}
				if(_obj has container or door) {
					if(_obj has open) {
						_desc_prop = when_open;
					} else {
						_desc_prop = when_closed;
					}
				} else if(_obj has switchable) {
					if(_obj has on) {
						_desc_prop = when_on;
					} else {
						_desc_prop = when_off;
					}
				} else {
					_desc_prop = initial;
				}
				if(_obj.&_desc_prop && (_obj hasnt moved || _desc_prop == when_off)) { ! Note: when_closed in an alias of when_off
					_initial_found = true;
					give _obj ~workflag;
					@new_line;
					PrintOrRun(_obj, _desc_prop);
					also_flag = true;
				}
			}

			! write any remaining objects in a new paragraph
			if(parent(_ceil) == 0) {
				_you_can_see_1 = _ListObjsMsg;
				_you_can_see_2 = " here.^";
			} else {
				_you_can_see_1 = _ListObjsInOnMsg;
				_you_can_see_2 = ".^";
			}

			if(PrintContents(_you_can_see_1, _ceil, true)) print (string) _you_can_see_2;
			_ceil = ScopeCeiling(player, _ceil);
		} ! for(::)
	}
	! finally, call the optional library entry routine
	LookRoutine();
	_action = action; action = ##Look;
	AfterRoutines();
	action = _action;

	if(_top_ceil == location)
		give location visited;
];

#IfnDef PrintRank;
[ PrintRank; "."; ];
#EndIf;

#IfDef OPTIONAL_FULL_SCORE;
#IfDef TASKS_PROVIDED;
[ Achieved num;
    if (task_done->num == 0) {
        task_done->num = 1;
        score = score + task_scores->num;
    }
];
#EndIf;
[ PANum p_m _n;
	print "  ";
	_n = p_m;
	if(_n < 0)    { _n = -p_m; _n = _n*10; }
	if(_n < 10)   { print "   "; jump Panuml; }
	if(_n < 100)  { print "  "; jump Panuml; }
	if(_n < 1000) { print " "; }
.Panuml;
	print p_m, " ";
];
#EndIf;

[ TryToTakeNoun _i _k _ancestor _after_recipient;
    ! Try to transfer the given item to the player: return false
    ! if successful, true if unsuccessful, printing a suitable message
    ! in the latter case.
    ! People cannot ordinarily be taken.
    if(noun == player) { PrintMsg(MSG_TAKE_YOURSELF); rtrue; }
    if(noun has animate) { PrintMsg(MSG_TAKE_ANIMATE); rtrue; }

	_ancestor = CommonAncestor(player, noun);

    if (_ancestor == 0) {
        _i = _ObjectScopedBySomething(noun);
        if (_i) _ancestor = CommonAncestor(player, _i);
    }

	if(noun in player) { PrintMsg(MSG_TAKE_ALREADY_HAVE); rtrue; }
	if(ObjectIsUntouchable(noun, false, true)) rtrue;
	if(IndirectlyContains(noun, player)) { PrintMsg(MSG_TAKE_PLAYER_PARENT, noun); rtrue; }

	! The item is now known to be accessible.

    ! Consult the immediate possessor of the item, if it's in a container
    ! which the actor is not in.

    _i = parent(noun);
    if (_i && _i ~= _ancestor && (_i has container or supporter)) {
        _after_recipient = _i;
#IfDef DEBUG;
		if(debug_flag & 1) print "(", (name) _i, ").before()^";
#EndIf;
        _k = action; action = ##LetGo;
        if (RunRoutines(_i, before)) { action = _k; rtrue; }
        action = _k;
    }

	if(noun has scenery) { PrintMsg(MSG_TAKE_SCENERY); rtrue; }
    if(noun has static) { PrintMsg(MSG_TAKE_STATIC); rtrue; }

    if(_AtFullCapacity(player)) { PrintMsg(MSG_TAKE_NO_CAPACITY); rtrue; }

#IfDef OPTIONAL_FULL_SCORE;
	if(noun hasnt moved && noun has scored) {
		score = score + OBJECT_SCORE;
		things_score = things_score + OBJECT_SCORE;
	}
#EndIf;
	move noun to player;
	give noun moved ~concealed;
#IfDef OPTIONAL_MANUAL_SCOPE;
	scope_modified = true;
#EndIf;

	! Send "after" message to the object letting go of the item, if any.

	if (_after_recipient) {
#IfDef DEBUG;
		if(debug_flag & 1) print "(", (name) _after_recipient, ").after()^";
#EndIf;
		_k = action; action = ##LetGo;
		if (RunRoutines(_after_recipient, after)) { action = _k; rtrue; }
		action = _k;
	}

	rfalse;
];

[ GoDir p_property _new_location _door_to _vehicle _vehicle_mode;
	if(parent(player) ~= real_location) {
		! special rule when in enterable (veichles)
		! before routine for the object is called with Go dir, and returns
		! 0   to disallow the movement, printing a refusal;
		! 1   to allow the movement, moving vehicle and player;
		! 2   to disallow but print and do nothing; or
		! 3   to allow but print and do nothing.
		_vehicle = parent(player);
#IfDef DEBUG;
		if(debug_flag & 1) print "(", (name) _vehicle, ").before()^";
#EndIf;
		_vehicle_mode = RunRoutines(_vehicle, before);
		if(_vehicle_mode == 0) { PrintMsg(MSG_GO_FIRST_LEAVE, parent(player)); rtrue; }
		if(_vehicle_mode == 2 or 3) rtrue;
	}
	!if(player notin location) { PrintMsg(MSG_GO_FIRST_LEAVE, parent(player)); rtrue; }
	if(real_location provides p_property) {
		@get_prop real_location p_property -> _new_location; ! works in z3 and z5
	}
	if(_new_location ofclass String)
		print_ret (string) _new_location;
	if(UnsignedCompare(_new_location, top_object) > 0) {
		_new_location = real_location.p_property();
		if(_new_location == 1)
			rtrue;
	}

	! Check for a door
	if(_new_location ~= 0 && _new_location has door) {
		! The destination is in fact a door
		if(_new_location has concealed)
			_new_location = 0;
		else {
			if(_new_location hasnt open) { PrintMsg(MSG_GO_DOOR_CLOSED, _new_location); rtrue; }
			_door_to = _new_location.door_to;
			if(UnsignedCompare(_door_to, top_object) > 0) {
				_new_location = _new_location.door_to();
!				print "GoDir, door leads to ", (the) _new_location, "^";
				if(_new_location == 1)
					rtrue;
			} else
				_new_location = _door_to;
		}
	}

	! If _new_location is 0, we tell the player they can't go there and exit
	if(_new_location == 0) {
		if(real_location provides cant_go) {
			print_ret (string) real_location.cant_go;
		}
        PrintMsg(MSG_GO_CANT_GO);
		rtrue;
	}

	action = ##Going;
	if (RunRoutines(_new_location, before) ~= 0) { action = ##Go; rtrue; }
	action = ##Go;

	if(_vehicle_mode == 1) {
		move _vehicle to _new_location;
		_new_location = _vehicle;
	}
	PlayerTo(_new_location, true);
	if(deadflag ~= GS_PLAYING) rtrue;
	if (AfterRoutines()) rtrue;
	if (keep_silent) rtrue;
	Look();
];


[ VerbName p_v ;
	! first give entry routine a chance to override
	if(PrintVerb(p_v)) return;

#IfV3;
	switch(p_v) {
		'restart': print "restart"; return;
		'restore': print "restore"; return;
		'display': print "display"; return;
		'present': print "present"; return;
		'destroy': print "destroy"; return;
		'torture': print "torture"; return;
		'unscrew': print "unscrew"; return;
#IfDef OPTIONAL_EXTENDED_VERBSET;
		'embrace': print "embrace"; return;
#EndIf;
		'x//', 'examine': print "examine"; return;
		'i//', 'inventory': print "inventory"; return;
		'l//': print "look"; return;
		'z//': print "wait"; return;
		'q//': print "quit"; return;
		'g//': print "again"; return;
	}
#IfNot;
	switch(p_v) {
		'x//': print "examine"; return;
		'i//': print "inventory"; return;
		'l//': print "look"; return;
		'z//': print "wait"; return;
		'q//': print "quit"; return;
		'g//': print "again"; return;
	}
#EndIf;

	print (address) p_v;
];
