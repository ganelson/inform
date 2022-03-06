! Part of PunyInform: A small stdlib and parser for interactive fiction
! suitable for old-school computers such as the Commodore 64.
! Designed to be similar, but not identical, to the Inform 6 library.
!
System_file;

!
! Simple string messages
!

#Ifndef MSG_TAKE_YOURSELF;
Constant MSG_TAKE_YOURSELF "You are always self-possessed.";
#EndIf;
#Ifndef MSG_TAKE_SCENERY;
Constant MSG_TAKE_SCENERY "That's hardly portable.";
#EndIf;
#Ifndef MSG_TAKE_STATIC;
Constant MSG_TAKE_STATIC "That's fixed in place.";
#EndIf;
#Ifndef MSG_TAKE_ALREADY_HAVE;
Constant MSG_TAKE_ALREADY_HAVE "You already have that.";
#EndIf;
#Ifndef MSG_TAKE_NO_CAPACITY;
Constant MSG_TAKE_NO_CAPACITY "You are carrying too many things already.";
#EndIf;
#Ifndef MSG_TAKE_SUCCESS;
Constant MSG_TAKE_SUCCESS "Taken.";
#EndIf;
#Ifndef MSG_EAT_INEDIBLE;
Constant MSG_EAT_INEDIBLE "That's plainly inedible.";
#EndIf;
#Ifndef MSG_DRINK_NOTHING_SUITABLE;
Constant MSG_DRINK_NOTHING_SUITABLE "There's nothing suitable to drink here.";
#EndIf;
#Ifndef MSG_DROP_DROPPED;
Constant MSG_DROP_DROPPED "Dropped.";
#EndIf;
#Ifndef MSG_OPEN_ALREADY;
Constant MSG_OPEN_ALREADY "It's already open.";
#Endif;
#Ifndef MSG_OPEN_LOCKED;
Constant MSG_OPEN_LOCKED "It seems to be locked.";
#Endif;
#Ifndef MSG_THROW_ANIMATE;
Constant MSG_THROW_ANIMATE "Futile.";
#Endif;
#Ifndef MSG_THROW_SUCCESS;
Constant MSG_THROW_SUCCESS "You lack the nerve when it comes to the crucial moment.";
#Endif;
#Ifndef MSG_SMELL_SUCCESS;
Constant MSG_SMELL_SUCCESS "You smell nothing unexpected.";
#Endif;
#Ifndef MSG_LISTEN_SUCCESS;
Constant MSG_LISTEN_SUCCESS "You hear nothing unexpected.";
#Endif;
#Ifndef MSG_TELL_PLAYER;
Constant MSG_TELL_PLAYER "You talk to yourself for a while.";
#Endif;
#Ifndef MSG_TELL_SUCCESS;
Constant MSG_TELL_SUCCESS "This provokes no reaction.";
#Endif;
#Ifndef MSG_ENTER_ALREADY;
Constant MSG_ENTER_ALREADY "But you are already there!";
#Endif;
#Ifndef MSG_EXIT_ALREADY;
Constant MSG_EXIT_ALREADY "But you aren't in anything at the moment!";
#Endif;
#Ifndef MSG_EXIT_NOT_ON;
Constant MSG_EXIT_NOT_ON "You aren't on that.";
#Endif;
#Ifndef MSG_EXIT_NOT_IN;
Constant MSG_EXIT_NOT_IN "You aren't in that.";
#Endif;
#Ifndef MSG_INVENTORY_EMPTY;
Constant MSG_INVENTORY_EMPTY "You are empty handed.";
#Endif;
#Ifndef MSG_GO_CANT_GO;
Constant MSG_GO_CANT_GO "You can't go that way.";
#Endif;
#Ifndef MSG_SAVE_SUCCESS;
Constant MSG_SAVE_SUCCESS "Ok.";
#Endif;
#Ifndef MSG_YES_OR_NO;
Constant MSG_YES_OR_NO "Please answer yes or no: ";
#Endif;
#Ifndef MSG_RESTART_CONFIRM;
Constant MSG_RESTART_CONFIRM "Are you sure you want to restart? ";
#Endif;
#Ifndef MSG_INSERT_ITSELF;
Constant MSG_INSERT_ITSELF "Cannot put something inside itself.";
#Endif;
#Ifndef MSG_INSERT_NOT_CONTAINER;
Constant MSG_INSERT_NOT_CONTAINER "That can't contain things.";
#Endif;
#Ifndef MSG_PUTON_NOT_SUPPORTER;
Constant MSG_PUTON_NOT_SUPPORTER "You can't put things on top of that.";
#Endif;
#Ifndef MSG_PUTON_ITSELF;
Constant MSG_PUTON_ITSELF "Cannot put something on itself.";
#Endif;
#Ifndef MSG_ATTACK_SUCCESS;
Constant MSG_ATTACK_SUCCESS "Violence isn't the answer to this one.";
#Endif;
#Ifndef MSG_FILL_NO_WATER;
Constant MSG_FILL_NO_WATER "But there's no water here to carry.";
#EndIf;
#Ifndef MSG_DIG_NO_USE;
Constant MSG_DIG_NO_USE "Digging would achieve nothing here.";
#EndIf;
#Ifndef MSG_WAIT_SUCCESS;
Constant MSG_WAIT_SUCCESS "Nothing happens.";
#EndIf;
#Ifndef MSG_TOUCH_SUCCESS;
Constant MSG_TOUCH_SUCCESS "You don't feel anything unexpected.";
#EndIf;
#Ifndef MSG_PUSHDIR_DEFAULT;
Constant MSG_PUSHDIR_DEFAULT "Is that the best you can think of?";
#EndIf;
#Ifndef MSG_JUMP;
Constant MSG_JUMP "You jump on the spot, fruitlessly.";
#EndIf;
#Ifndef MSG_REMOVE_SUCCESS;
Constant MSG_REMOVE_SUCCESS "Removed.";
#EndIf;
#Ifndef MSG_SEARCH_NOTHING_SPECIAL;
Constant MSG_SEARCH_NOTHING_SPECIAL "You find nothing special.";
#EndIf;
#Ifndef MSG_LOOKMODE_NORMAL;
Constant MSG_LOOKMODE_NORMAL "This game is now in its normal ~brief~ mode, which gives long descriptions of locations never before visited and short descriptions otherwise.";
#EndIf;
#Ifndef MSG_LOOKMODE_LONG;
Constant MSG_LOOKMODE_LONG "This game is now in its ~verbose~ mode, which always gives long descriptions of locations (even if you've been there before).";
#EndIf;
#Ifndef MSG_LOOKMODE_SHORT;
Constant MSG_LOOKMODE_SHORT "This game is now in its ~superbrief~ mode, which always gives short descriptions of locations (even if you haven't been there before).";
#EndIf;
#Ifndef MSG_PARSER_ONLY_TO_ANIMATE;
Constant MSG_PARSER_ONLY_TO_ANIMATE "You can only do that to something animate.";
#EndIf;
#Ifndef MSG_PARSER_NOT_MULTIPLE_VERB;
Constant MSG_PARSER_NOT_MULTIPLE_VERB "You can't use multiple objects with that verb.";
#EndIf;
#Ifndef MSG_PARSER_CANT_SEE_SUCH_THING;
Constant MSG_PARSER_CANT_SEE_SUCH_THING "You can't see any such thing.";
#EndIf;
#Ifndef MSG_PARSER_BAD_NUMBER;
Constant MSG_PARSER_BAD_NUMBER "I didn't understand that number.";
#EndIf;
#Ifndef MSG_PARSER_NO_INPUT;
Constant MSG_PARSER_NO_INPUT "Come again?";
#EndIf;
#Ifndef MSG_PARSER_UNKNOWN_SENTENCE;
Constant MSG_PARSER_UNKNOWN_SENTENCE "I don't understand that sentence.";
#EndIf;
#Ifndef MSG_PARSER_UNKNOWN_VERB;
Constant MSG_PARSER_UNKNOWN_VERB "That is not a verb I recognize.";
#EndIf;
#Ifndef MSG_NOTHOLDINGTHAT;
Constant MSG_NOTHOLDINGTHAT "You are not holding that!";
#EndIf;
#Ifndef MSG_PARSER_CANT_DISAMBIGUATE;
Constant MSG_PARSER_CANT_DISAMBIGUATE "I still don't understand what you are referring to.";
#EndIf;
#Ifndef MSG_PARSER_NOSUCHTHING;
Constant MSG_PARSER_NOSUCHTHING "You can't see any such thing.";
#EndIf;

!
! complex messages (enumerated)
!

Default MSG_OPEN_YOU_CANT = 1;
Default MSG_CLOSE_YOU_CANT = 2;
Default MSG_ENTER_YOU_CANT = 3;
Default MSG_EXAMINE_NOTHING_SPECIAL = 4;
Default MSG_TAKE_ANIMATE = 5;
Default MSG_TAKE_PLAYER_PARENT = 6;
Default MSG_EAT_ANIMATE = 7;
Default MSG_DROP_NOT_HOLDING = 8;
Default MSG_OPEN_SUCCESS = 9;
Default MSG_CLOSE_SUCCESS = 10;
Default MSG_THROW_WORN = 11;
Default MSG_SHOW_NOT_HOLDING = 12;
Default MSG_SHOW_SUCCESS = 13;
Default MSG_GIVE_NOT_HOLDING = 14;
Default MSG_GIVE_SUCCESS = 15;
Default MSG_ASKFOR_SUCCESS = 16;
Default MSG_ASKTO_SUCCESS = 17;
Default MSG_ENTER_SUCCESS = 18;
Default MSG_EXIT_FIRST_LEAVE = 19;
Default MSG_ENTER_NOT_OPEN = 20;
Default MSG_EXIT_NOT_OPEN = 21;
Default MSG_EXIT_SUCCESS = 22;
Default MSG_INVENTORY_SUCCESS = 23;
Default MSG_GO_FIRST_LEAVE = 24;
Default MSG_GIVE_PLAYER 25;
Default MSG_SAVE_FAILED 26;
Default MSG_RESTORE_FAILED 27;
Default MSG_RESTART_FAILED 28;
Default MSG_INSERT_SUCCESS 29;
Default MSG_INSERT_NOT_OPEN 30;
Default MSG_ASK_SUCCESS 31;
Default MSG_ANSWER_SUCCESS 32;
Default MSG_RESTART_RESTORE_OR_QUIT 33;
Default MSG_AREYOUSUREQUIT 34;
Default MSG_WEAR_ALREADY_WORN 35;
Default MSG_WEAR_NOT_CLOTHING 36;
Default MSG_WEAR_NOT_HOLDING 37;
Default MSG_WEAR_SUCCESS 38;
Default MSG_INSERT_ALREADY 39;
Default MSG_INSERT_NO_ROOM 40;
Default MSG_PUTON_ALREADY 41;
Default MSG_PUTON_NO_ROOM 42;
Default MSG_PUTON_SUCCESS 43;
Default MSG_GO_DOOR_CLOSED 44;
Default MSG_SWITCH_ON_NOT_SWITCHABLE 45;
Default MSG_SWITCH_OFF_NOT_SWITCHABLE 46;
Default MSG_SWITCH_ON_ON 47;
Default MSG_SWITCH_OFF_NOT_ON 48;
Default MSG_SWITCH_ON_SUCCESS 49;
Default MSG_SWITCH_OFF_SUCCESS 50;
Default MSG_PUSH_STATIC 51;
Default MSG_PULL_STATIC 52;
Default MSG_TURN_STATIC 53;
Default MSG_PUSH_SCENERY 54;
Default MSG_PULL_SCENERY 55;
Default MSG_TURN_SCENERY 56;
Default MSG_PUSH_ANIMATE 57;
Default MSG_PULL_ANIMATE 58;
Default MSG_TURN_ANIMATE 59;
Default MSG_TURN_SUCCESS 60;
Default MSG_PUSH_SUCCESS 61;
Default MSG_PULL_SUCCESS 62;
Default MSG_YOU_HAVE_WON 63;
Default MSG_YOU_HAVE_DIED 64;
Default MSG_PARSER_NOTHING_TO_VERB 66;
Default MSG_TOUCHABLE_FOUND_CLOSED 67;
Default MSG_CONSULT_NOTHING_INTERESTING 68;
Default MSG_CUT_NO_USE 69;
Default MSG_SACK_PUTTING 70;
Default MSG_LOCK_NOT_A_LOCK 71;
Default MSG_LOCK_ALREADY_LOCKED 72;
Default MSG_LOCK_CLOSE_FIRST 73;
Default MSG_LOCK_KEY_DOESNT_FIT 74;
Default MSG_LOCK_SUCCESS 75;
Default MSG_DISROBE_NOT_WEARING 76;
Default MSG_DISROBE_SUCCESS 77;
Default MSG_REMOVE_CLOSED 78;
Default MSG_REMOVE_NOT_HERE 79;
Default MSG_SEARCH_IN_IT_ISARE 80;
Default MSG_SEARCH_ON_IT_ISARE 81;
Default MSG_SEARCH_EMPTY 82;
Default MSG_SEARCH_NOTHING_ON 83;
Default MSG_SEARCH_CANT_SEE_CLOSED 84;
Default MSG_EAT_SUCCESS = 85;
#IfDef OPTIONAL_FULL_SCORE;
Default MSG_FULLSCORE_START 86;
Default MSG_FULLSCORE_END 87;
#EndIf;
Default MSG_SCORE_SUCCESS 88;
Default MSG_UNLOCK_NOT_A_LOCK 89;
Default MSG_UNLOCK_ALREADY_UNLOCKED 90;
Default MSG_UNLOCK_KEY_DOESNT_FIT 91;
Default MSG_UNLOCK_SUCCESS 92;
Default MSG_ENTER_BAD_LOCATION 93;
Default MSG_PROMPT 94;
Default MSG_EXAMINE_DARK 95;
Default MSG_SEARCH_DARK 96;
Default MSG_EXAMINE_ONOFF 97;
Default MSG_ORDERS_WONT 98;
Default MSG_DROP_WORN 99;
Default MSG_INSERT_WORN 100;
Default MSG_PUTON_WORN 101;
Default MSG_TAKE_BELONGS 102;
Default MSG_TAKE_PART_OF 103;
Default MSG_TAKE_NOT_AVAILABLE 104;
Default MSG_PARSER_CONTAINER_ISNT_OPEN 105;
Default MSG_PARSER_NOT_HOLDING 106;
Default MSG_PARSER_CANT_TALK 107;
Default MSG_WAVE_NOTHOLDING 108;
Default MSG_JUMP_OVER 109;
Default MSG_TIE_DEFAULT 110;
Default MSG_CLOSE_NOT_OPEN 111;
Default MSG_RUB_DEFAULT 112;
Default MSG_SQUEEZE_DEFAULT 113;
Default MSG_EXAMINE_CLOSED 114;
Default MSG_EMPTY_IS_CLOSED 115;


#IfDef OPTIONAL_EXTENDED_VERBSET;
#Ifndef MSG_BURN_DEFAULT;
Constant MSG_BURN_DEFAULT "This dangerous act would achieve little.";
#EndIf;
#Ifndef MSG_BUY_DEFAULT;
Constant MSG_BUY_DEFAULT "Nothing is on sale.";
#EndIf;
#Ifndef MSG_EMPTY_WOULDNT_ACHIEVE;
Constant MSG_EMPTY_WOULDNT_ACHIEVE "That would scarcely empty anything.";
#EndIf;
#Ifndef MSG_RHETORICAL_QUESTION;
Constant	MSG_RHETORICAL_QUESTION "That was a rhetorical question.";
#EndIf;
#Ifndef MSG_PRAY_DEFAULT;
Constant MSG_PRAY_DEFAULT "Nothing practical results from your prayer.";
#EndIf;
#Ifndef MSG_SING_DEFAULT;
Constant MSG_SING_DEFAULT "Your singing is abominable.";
#EndIf;
#Ifndef MSG_SLEEP_DEFAULT;
Constant MSG_SLEEP_DEFAULT "You aren't feeling especially drowsy.";
#EndIf;
#Ifndef MSG_SORRY_DEFAULT;
Constant MSG_SORRY_DEFAULT "Oh, don't apologize.";
#EndIf;
#Ifndef MSG_SQUEEZE_YOURSELF;
Constant MSG_SQUEEZE_YOURSELF "Keep your hands to yourself.";
#EndIf;

#Ifndef MSG_SWIM_DEFAULT;
Constant MSG_SWIM_DEFAULT "There's not enough water to swim in.";
#EndIf;
#Ifndef MSG_SWING_DEFAULT;
Constant MSG_SWING_DEFAULT "There's nothing sensible to swing here.";
#EndIf;
#Ifndef MSG_TASTE_DEFAULT;
Constant MSG_TASTE_DEFAULT "You taste nothing unexpected.";
#EndIf;
#Ifndef MSG_THINK_DEFAULT;
Constant MSG_THINK_DEFAULT "What a good idea.";
#EndIf;
#Ifndef MSG_WAVEHANDS_DEFAULT;
Constant MSG_WAVEHANDS_DEFAULT "You wave, feeling foolish.";
#EndIf;
#Ifndef MSG_WAKE_SUCCESS;
Constant MSG_WAKE_SUCCESS "The dreadful truth is, this is not a dream.";
#Endif;
#Ifndef MSG_WAKEOTHER_SUCCESS;
Constant MSG_WAKEOTHER_SUCCESS "That seems unnecessary.";
#Endif;
#Ifndef MSG_KISS_PLAYER;
Constant MSG_KISS_PLAYER "If you think that'll help.";
#Endif;
#Ifndef MSG_KISS_SUCCESS;
Constant MSG_KISS_SUCCESS "Keep your mind on the game.";
#Endif;
#Ifndef MSG_MILD_DEFAULT;
Constant MSG_MILD_DEFAULT "Quite.";
#EndIf;
#Ifndef MSG_STRONG_DEFAULT;
Constant MSG_STRONG_DEFAULT "Real adventurers do not use such language.";
#EndIf;

Default MSG_BLOW_DEFAULT 300;
Default MSG_EMPTY_CANT_CONTAIN 301;
Default MSG_WAVE_DEFAULT 302;
Default MSG_EMPTY_ALREADY_EMPTY 303;
Default MSG_SET_DEFAULT 304;
Default MSG_SET_TO_DEFAULT 305;
#EndIf;



Default LibraryMessages 0;


[ PrintMsg p_msg p_arg_1 p_arg_2;
	if(p_msg ofclass String)
		print_ret (string) p_msg;

	if(p_msg > 999) {
		LibraryMessages(p_msg, p_arg_1, p_arg_2);
		rtrue;
	}

	! Not a string, there should be code for the message here
	switch(p_msg) {
	MSG_TURN_SUCCESS, MSG_PUSH_SUCCESS, MSG_PULL_SUCCESS:
		"Nothing obvious happens.";
#IfDef SACK_OBJECT;
#IfTrue MSG_SACK_PUTTING < 1000;
	MSG_SACK_PUTTING:
		"(putting ", (the) p_arg_1, " into ", (the) SACK_OBJECT, " to make room)";
#EndIf;
#EndIf;
#IfTrue MSG_PROMPT < 1000;
	MSG_PROMPT:
		print "> ";
		rtrue;
#EndIf;
#IfTrue MSG_INVENTORY_SUCCESS < 1000;
	MSG_INVENTORY_SUCCESS:
		if(PrintContents("You're carrying ", player)) print ".^";
		rtrue;
#EndIf;
#IfTrue MSG_EXAMINE_NOTHING_SPECIAL < 1000;
	MSG_EXAMINE_NOTHING_SPECIAL:
		"There is nothing special about ", (the) noun, ".";
#EndIf;
	MSG_PUSH_STATIC, MSG_PULL_STATIC, MSG_TURN_STATIC:
		print_ret (CTheyreorThats) noun, " fixed in place.";
	MSG_TURN_SCENERY, MSG_PUSH_SCENERY, MSG_PULL_SCENERY:
		"What a concept!";
	MSG_TURN_ANIMATE, MSG_PUSH_ANIMATE, MSG_PULL_ANIMATE:
		"That would be less than courteous.";
	MSG_TURN_STATIC, MSG_PUSH_STATIC, MSG_PULL_STATIC:
		"You are unable to.";
	MSG_DROP_NOT_HOLDING, MSG_SHOW_NOT_HOLDING, MSG_GIVE_NOT_HOLDING,
		MSG_WEAR_NOT_HOLDING:
		"You aren't holding ", (ItorThem) noun, ".";
	MSG_OPEN_YOU_CANT, MSG_CLOSE_YOU_CANT, MSG_ENTER_YOU_CANT,
		MSG_LOCK_NOT_A_LOCK, MSG_UNLOCK_NOT_A_LOCK, MSG_WEAR_NOT_CLOTHING:
		"That doesn't seem to be something you can ", (verbname) p_arg_1, ".";
	MSG_TAKE_ANIMATE, MSG_EAT_ANIMATE:
		"I don't suppose ", (the) noun, " would care for that.";
	MSG_TAKE_PLAYER_PARENT, MSG_GO_FIRST_LEAVE, MSG_EXIT_FIRST_LEAVE:
		"First, you'd have to leave ", (the) p_arg_1, ".";
	MSG_OPEN_SUCCESS, MSG_CLOSE_SUCCESS, MSG_ENTER_SUCCESS, MSG_LOCK_SUCCESS,
		MSG_UNLOCK_SUCCESS, MSG_EXIT_SUCCESS:
		"You ", (verbname) p_arg_1, " ", (the) noun, ".";
	MSG_GIVE_SUCCESS, MSG_SHOW_SUCCESS:
		print_ret (The) second, " doesn't seem interested.";
	MSG_ASKFOR_SUCCESS, MSG_ASKTO_SUCCESS:
		print_ret (The) noun, " has better things to do.";
	MSG_ENTER_NOT_OPEN, MSG_EXIT_NOT_OPEN, MSG_INSERT_NOT_OPEN, MSG_GO_DOOR_CLOSED:
		"You can't, since ",(the) p_arg_1, " is closed.";
#IfTrue MSG_GIVE_PLAYER < 1000;
	MSG_GIVE_PLAYER:
		"You already have ", (ItorThem) noun, ".";
#EndIf;
	MSG_SAVE_FAILED, MSG_RESTORE_FAILED, MSG_RESTART_FAILED:
		"Failed ", (verbname) verb_word, ".";
	MSG_INSERT_ALREADY, MSG_PUTON_ALREADY:
		"Already there.";
	MSG_INSERT_NO_ROOM, MSG_PUTON_NO_ROOM:
		"There is no more room.";
#IfTrue MSG_INSERT_SUCCESS < 1000;
	MSG_INSERT_SUCCESS:
		"You put ", (the) noun, " into ", (the) second, ".";
#EndIf;
#IfTrue MSG_PUTON_SUCCESS < 1000;
	MSG_PUTON_SUCCESS:
		"You put ", (the) noun, " on ", (the) second, ".";
#EndIf;
	MSG_ASK_SUCCESS, MSG_ANSWER_SUCCESS:
		"There is no reply.";
#IfTrue MSG_WEAR_ALREADY_WORN < 1000;
	MSG_WEAR_ALREADY_WORN:
		"You are already wearing ", (ItorThem) noun, ".";
#EndIf;
#IfTrue MSG_WEAR_SUCCESS < 1000;
	MSG_WEAR_SUCCESS:
		"You are now wearing ", (the) noun, ".";
#EndIf;
#IfTrue MSG_DISROBE_NOT_WEARING < 1000;
	MSG_DISROBE_NOT_WEARING:
		"You're not wearing ", (the) noun, ".";
#EndIf;
#IfTrue MSG_DISROBE_SUCCESS < 1000;
	MSG_DISROBE_SUCCESS:
		"You take off ", (the) noun, ".";
#EndIf;
	MSG_SWITCH_ON_NOT_SWITCHABLE, MSG_SWITCH_OFF_NOT_SWITCHABLE:
		print_ret (CTheyreorThats) noun, " not something you can switch.";
	MSG_SWITCH_ON_ON, MSG_SWITCH_OFF_NOT_ON:
		print_ret (CTheyreorThats) noun, " already ", (OnOff) noun, ". ";
	MSG_SWITCH_ON_SUCCESS, MSG_SWITCH_OFF_SUCCESS:
		"You switch ", (the) noun, " ", (OnOff) noun, ". ";
	MSG_DROP_WORN, MSG_INSERT_WORN, MSG_PUTON_WORN, MSG_THROW_WORN:
		"First you'd have to take off ", (the) noun, ".";
#IfTrue MSG_PARSER_NOTHING_TO_VERB < 1000;
	MSG_PARSER_NOTHING_TO_VERB:
		"There is nothing to ",  (verbname) verb_word,".";
#EndIf;
	MSG_PARSER_NOT_HOLDING, MSG_WAVE_NOTHOLDING:
		print_ret "But you are not holding ", (the) p_arg_1, ".";
#IfTrue MSG_PARSER_CANT_TALK < 1000;
	MSG_PARSER_CANT_TALK:
		print_ret "You can't talk to ", (the) p_arg_1, ".";
#EndIf;
	MSG_TOUCHABLE_FOUND_CLOSED, MSG_PARSER_CONTAINER_ISNT_OPEN, MSG_CLOSE_NOT_OPEN:
		print_ret (CObjIs) p_arg_1, "n't open.";
#IfTrue MSG_CONSULT_NOTHING_INTERESTING < 1000;
	MSG_CONSULT_NOTHING_INTERESTING:
		"You discover nothing of interest in ", (the) second, ".";
#EndIf;
	MSG_CUT_NO_USE, MSG_JUMP_OVER, MSG_TIE_DEFAULT:
		"You would achieve nothing by this.";
	MSG_LOCK_ALREADY_LOCKED, MSG_UNLOCK_ALREADY_UNLOCKED:
		print_ret (CObjIs) noun, " already ", (verbname) p_arg_1, "ed.";
#IfTrue MSG_LOCK_CLOSE_FIRST < 1000;
	MSG_LOCK_CLOSE_FIRST:
		"First you'd have to close ", (the) noun, ".";
#EndIf;
	MSG_LOCK_KEY_DOESNT_FIT, MSG_UNLOCK_KEY_DOESNT_FIT:
		print_ret (The) second, " doesn't seem to fit the lock.";
	MSG_EXAMINE_CLOSED, MSG_REMOVE_CLOSED, MSG_EMPTY_IS_CLOSED:
		print_ret (The) p_arg_1, " ", (isorare) p_arg_1, " closed.";
#IfTrue MSG_REMOVE_NOT_HERE < 1000;
	MSG_REMOVE_NOT_HERE:
		"But ", (the) noun, " isn't there now.";
#EndIf;
#IfTrue MSG_SEARCH_IN_IT_ISARE < 1000;
	MSG_SEARCH_IN_IT_ISARE:
		print "In ";
		SearchInOnNoun();
		rtrue;
#EndIf;
#IfTrue MSG_SEARCH_ON_IT_ISARE < 1000;
	MSG_SEARCH_ON_IT_ISARE:
		print "On ";
		SearchInOnNoun();
		rtrue;
#EndIf;
#IfTrue MSG_SEARCH_EMPTY < 1000;
	MSG_SEARCH_EMPTY:
		print_ret (CObjIs) noun, " empty.";
#EndIf;
#IfTrue MSG_SEARCH_NOTHING_ON < 1000;
	MSG_SEARCH_NOTHING_ON:
		"There is nothing on ", (the) noun, ".";
#EndIf;
#IfTrue MSG_SEARCH_CANT_SEE_CLOSED < 1000;
	MSG_SEARCH_CANT_SEE_CLOSED:
		"You can't see inside, since ", (the) noun, " is closed.";
#EndIf;
#IfTrue MSG_EXAMINE_ONOFF < 1000;
	MSG_EXAMINE_ONOFF:
		print_ret (The) noun, " ", (IsOrAre) noun, " currently switched ", (onoff) noun, ".";
#EndIf;
#IfTrue MSG_EAT_SUCCESS < 1000;
	MSG_EAT_SUCCESS:
		"You eat ", (the) noun, ". Not bad.";
#EndIf;
MSG_RUB_DEFAULT, MSG_SQUEEZE_DEFAULT:
	"You achieve nothing by this.";
#IfTrue MSG_ORDERS_WONT < 1000;
	MSG_ORDERS_WONT:
		print_ret (The) actor, " has better things to do.";
#EndIf;
#IfTrue MSG_TAKE_NOT_AVAILABLE < 1000;
	MSG_TAKE_NOT_AVAILABLE:
		print_ret (CObjIs) noun, " not available.";
#EndIf;
#IfTrue MSG_TAKE_BELONGS < 1000;
	MSG_TAKE_BELONGS:
		print_ret (The) p_arg_1, " seems to belong to ", (the) p_arg_2, ".";
#EndIf;
#IfTrue MSG_TAKE_PART_OF < 1000;
	MSG_TAKE_PART_OF:
		print_ret (The) p_arg_1, " seems to be part of ", (the) p_arg_2, ".";
#EndIf;
	MSG_EXAMINE_DARK, MSG_SEARCH_DARK:
		"But it's dark.";
#IfTrue MSG_SCORE_SUCCESS < 1000;
	MSG_SCORE_SUCCESS:
		if (deadflag) print "In that game you"; else print "You have so far";
		print " scored ", score, " out of a possible ", MAX_SCORE, ", in ", turns, " turn";
		if(turns ~= 1) print "s";
		rtrue;
#EndIf;
#IfDef OPTIONAL_FULL_SCORE;
#IfTrue MSG_FULLSCORE_START < 1000;
	MSG_FULLSCORE_START:
		print "The score ";
		if(deadflag) print "wa"; else print "i";
		"s made up as follows:";
#EndIf;
#IfTrue MSG_FULLSCORE_END < 1000;
	MSG_FULLSCORE_END:
		"total (out of ", MAX_SCORE, ")";
#EndIf;
#EndIf;
#IfTrue MSG_RESTART_RESTORE_OR_QUIT < 1000;
	MSG_RESTART_RESTORE_OR_QUIT:
		print "^Would you like to RESTART, RESTORE";
#EndIf;
#IfDef OPTIONAL_FULL_SCORE;
		print ", give the FULL score for that game";
#EndIf;
		if(deadflag == 2 && AMUSING_PROVIDED == 0) print ", see some suggestions for AMUSING things to do";
		print " or QUIT? ";
		rtrue;
#IfTrue MSG_AREYOUSUREQUIT < 1000;
	MSG_AREYOUSUREQUIT: ! print and rtrue to avoid newline
		print "Are you sure you want to quit? ";
		rtrue;
#EndIf;
#IfTrue MSG_YOU_HAVE_WON < 1000;
	MSG_YOU_HAVE_WON: ! print and rtrue to avoid newline
 		print "You have won.";
 		rtrue;
#EndIf;
#IfTrue MSG_YOU_HAVE_DIED < 1000;
	MSG_YOU_HAVE_DIED: ! print and rtrue to avoid newline
		print "You have died.";
		rtrue;
#EndIf;
#IfTrue MSG_ENTER_BAD_LOCATION < 1000;
	MSG_ENTER_BAD_LOCATION:
		print "You have to ";
		if(player notin location && ~~IndirectlyContains(parent(player), noun))
			print "leave ", (the) parent(player);
		else
			print "enter ", (the) parent(noun);
		" first.";
#EndIf;


#IfDef OPTIONAL_EXTENDED_VERBSET;
#IfTrue MSG_BLOW_DEFAULT < 1000;
	MSG_BLOW_DEFAULT:
		"You can't usefully blow ", (the) noun, ".";
#EndIf;
#IfTrue MSG_EMPTY_CANT_CONTAIN < 1000;
	MSG_EMPTY_CANT_CONTAIN:
		print_ret (The) p_arg_1, " can't contain things.";
#EndIf;
#IfTrue MSG_EMPTY_ALREADY_EMPTY < 1000;
	MSG_EMPTY_ALREADY_EMPTY:
		print_ret (The) p_arg_1, " ", (isorare) p_arg_1, " empty already.";
#EndIf;
#IfTrue MSG_SET_DEFAULT < 1000;
	MSG_SET_DEFAULT:
		"No, you can't set ", (thatorthose) noun, ".";
#EndIf;
#IfTrue MSG_SET_TO_DEFAULT < 1000;
	MSG_SET_TO_DEFAULT:
		"No, you can't set ", (thatorthose) noun, " to anything.";
#EndIf;
#IfTrue MSG_WAVE_DEFAULT < 1000;
	MSG_WAVE_DEFAULT:
		"You look ridiculous waving ", (the) noun, ".";
#EndIf;
#EndIf;

default:
		! No code found. Print an error message.
		RuntimeError(ERR_UNKNOWN_MSGNO);
	}
];

[ SearchInOnNoun;
	print (the) noun, " is ";
	if(PrintContents(0, noun)) print ".^";
];

[OnOff obj;
	if(obj has on) print "on";
	else print "off";
	return;
];

[ CTheyreorThats obj;
	if (obj == player)			 { print "You're"; return; }
	if (obj has pluralname)		{ print "They're"; return; }
	if (obj has animate) {
		if (obj has female)		{ print "She's"; return; }
		else if (obj hasnt neuter) { print "He's"; return; }
	}
	print "That's";
];

[ IsorAre obj;
	if (obj has pluralname || obj == player) print "are"; else print "is";
];

[ ThatorThose obj;
	if (obj has pluralname || obj == player) print "those"; else print "that";
];

[ ItorThem obj;
	if (obj == player) { print "yourself"; rtrue; }
	if (obj has pluralname) { print "them"; rtrue; }
	if (obj has animate) {
		if (obj has female) { print "her"; rtrue; }
		else if (obj hasnt neuter) { print "him"; rtrue; }
	}
	print "it";
];

[ CObjIs p_obj;
	print (The) p_obj, " ", (isorare) p_obj;
];

!
! Error messages
!
Constant ERR_TOO_MANY_TIMERS_DAEMONS 1;
Constant ERR_OBJECT_HASNT_PROPERTY 2;
Constant ERR_SCOPE_FULL 3;
Constant ERR_UNKNOWN_MSGNO 4;
Constant ERR_INVALID_DIR_PROP 5;
Constant ERR_TOO_MANY_FLOATING 6;
Constant ERR_NOT_DIR_PROP 7;
Constant ERR_NOT_FAKE_OBJ 8;

[RunTimeError p_err;
	print "[Puny error: ";
	if(p_err ofclass string)
		print (string) p_err;
	else {
#IfTrue RUNTIME_ERRORS == RTE_VERBOSE;
		switch(p_err) {
		ERR_TOO_MANY_TIMERS_DAEMONS:
			print "Too many timers/daemons";
		ERR_OBJECT_HASNT_PROPERTY:
			print "Object lacks that property";
		ERR_SCOPE_FULL:
			print "Scope full";
		ERR_UNKNOWN_MSGNO:
			print "Unknown message#";
		ERR_INVALID_DIR_PROP:
			print "Invalid direction prop in GoSub";
		ERR_TOO_MANY_FLOATING:
			print "Too many floating objects";
		ERR_NOT_DIR_PROP:
			print "DirPropToFakeObj called with non-dirprop";
		ERR_NOT_FAKE_OBJ:
			print "FakeObjToDirProp called with non-fakeobj";
		default:
			print "Unknown error (", p_err, ")";
		}
#IfNot;
		print p_err;
#EndIf;
	}
	"]";
];
