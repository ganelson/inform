! Part of PunyInform: A small stdlib and parser for interactive fiction
! suitable for old-school computers such as the Commodore 64.
! Designed to be similar, but not identical, to the Inform 6 library.

! ######################### Parser
! PunyInform uses grammar version 2 which is easier to parse and economical

System_file;

[ _ReadPlayerInput p_no_prompt _result;
! #IfV5;
!   print "Width: ", HDR_SCREENWCHARS->0,"^";
! #EndIf;
#IfV5;
	style roman;
	@buffer_mode 0;
#EndIf;
	if(p_no_prompt == false) PrintMsg(MSG_PROMPT);
	! library entry routine
	AfterPrompt();
#IfV5;
	DrawStatusLine();
	buffer->1 = 0;
	@aread buffer parse -> _result;
	@buffer_mode 1;
#IfNot;
	@sread buffer parse;
#EndIf;
	num_words = parse -> 1;
	! Set word after last word in parse array to all zeroes, so it won't match any words.
	_result = 2 * (parse -> 1) + 1;
	parse-->_result = 0;
	parse-->(_result + 1) = 0;

	! call library entry routine
	BeforeParsing();
];

[ YesOrNo;
    for (::) {
        _ReadPlayerInput(true);
        if(parse -> 1 == 1) {
        	! one word reply
            if(parse --> 1 == 'yes' or 'y//') rtrue;
            if(parse --> 1 == 'no' or 'n//') rfalse;
        }
        PrintMsg(MSG_YES_OR_NO, true);
    }
];

#Ifdef OPTIONAL_ALLOW_WRITTEN_NUMBERS;
[ NumberWord p_o _i _n;
    ! try to parse  "one" up to "twenty".
    _n = LanguageNumbers-->0;
    for(_i = 1 : _i <= _n : _i = _i + 2)
        if (p_o == LanguageNumbers-->_i) return LanguageNumbers-->(_i+1);
    return 0;
];
#Endif;

[ TryNumber p_wordnum _i _j _num _len _mul _d _tot _digit;
	!  Takes word number p_wordnum and tries to parse it as an
	! unsigned decimal number, returning
	!
	!  -1000                if it is not a number
	!  the number           if it has between 1 and 4 digits
	!  10000                if it has 5 or more digits.
    _i = wn; wn = p_wordnum; _j = NextWord(); wn = _i;
#Ifdef OPTIONAL_ALLOW_WRITTEN_NUMBERS;
    _j = NumberWord(_j); if (_j >= 1) return _j;
#Endif;

    _i = p_wordnum*4+1; _j = parse->_i; _num = _j+buffer; _len = parse->(_i-1);

    ! allow for a entry point routine to override normal parsing
    _tot = ParseNumber(_num, _len); if(_tot ~= 0) return _tot;

	_i = _len;
	_mul=1; --_len;
    for (: _len >= 0 : _len--) {
        _digit = _num->_len;
        if(_digit < '0' || _digit > '9') jump baddigit;
		_d = _digit - '0';
        if(_i <= 4) _tot = _tot + _mul * _d; _mul = _mul * 10;
    }
   	if (_i > 4) return 10000;
    return _tot;
.baddigit;
	return -1000;
];

[ _CopyInputArray p_src_input_array p_dst_input_array _i;
	!_n = MAX_INPUT_CHARS + 3;
	for(_i = 0: : _i++) {
		p_dst_input_array->_i = p_src_input_array->_i;
		! abort when 0 found in the text, which starts
		! from 1 in v1-4, and from 2 in v5-v8.
#IfV5;
		if(p_dst_input_array->_i == 0 && _i>2) break;
#IfNot;
		if(p_dst_input_array->_i == 0 && _i>1) break;
#EndIf;
	}
];

[ _CopyParseArray p_src_parse_array p_dst_parse_array _n _i;
	!_n = 2 + 4 * (MAX_INPUT_WORDS + 1);
	_n = 2 + 4*p_src_parse_array->1;
	for(_i = 0: _i < _n: _i++)
		p_dst_parse_array->_i = p_src_parse_array->_i;
];

#IfDef DEBUG;

[ _PrintParseArray p_parse_array _i;
	print "PARSE_ARRAY: ", p_parse_array->1, " entries^";
	for(_i = 0 : _i < p_parse_array -> 1 : _i++) {
		print _i, ": wn ", (_i + 1),
		" dict ",((p_parse_array + 2 + _i * 4) --> 0),
		" (",(address) ((p_parse_array + 2 + _i * 4) --> 0),") ",
 		" len ",(p_parse_array + 2 + _i * 4) -> 2,
		" index ",(p_parse_array + 2 + _i * 4) -> 3, "^";
	}
];

[ _CheckPattern p_pattern _i _action_number _token_top _token_next _token_bottom;
	! action number is the first two bytes
	_action_number = p_pattern-->0;
	p_pattern = p_pattern + 2;
	action = _action_number & $3ff;
	action_reverse = (_action_number & $400 ~= 0);
!	print "Action#: ", action, " Reverse: ", reverse, "^";
	print "Action#: ", action, "^";

	for(_i = 0: : _i++) {
		if(p_pattern->0 == TT_END) break;
		_token_top = (p_pattern->0 & $c0)/64; ! top (2 bits)
		_token_next = (p_pattern->0 & $30)/16;  ! next (2 bits)
		_token_bottom = p_pattern->0 & $0f; ! bottom (4 bits)
		print "Token#: ", _i, " Type: ", p_pattern->0, " (top ", _token_top, ", next ",_token_next, ", bottom ",_token_bottom, ") data: " ,(p_pattern + 1)-->0;
		if((p_pattern + 1)-->0>4000) print" " ,(address) (p_pattern + 1)-->0;
		@new_line;
		p_pattern = p_pattern + 3;
	}
	! print ": ", i, " tokens^";
	return p_pattern + 1; ! skip TT_END
];
#EndIf;


! Keep the routines WordAddress, WordLength, NextWord and NextWordStopped just next to _CheckNoun,
! since they will typically be called from parse_name routines, which are called from _CheckNoun

[ WordAddress p_wordnum;  ! Absolute addr of 'wordnum' string in buffer
	return buffer + parse->(p_wordnum*4+1);
];

[ WordLength p_wordnum;     ! Length of 'wordnum' string in buffer
	return parse->(p_wordnum*4);
];

[ _PeekAtNextWord _i;
	_i = NextWord();
	--wn; ! wn was modified by NextWord, restore it
	return _i;
];

[ NextWord _i _j;
	if (wn <= 0 || wn > parse->1) { wn++; rfalse; }
	_i = wn*2-1; wn++;
	_j = parse-->_i;
	if (_j == ',//') _j = comma_word;
	if (_j == './/') _j = THEN_WORD;
	return _j;
];

[ NextWordStopped;
	if (wn > parse->1) { wn++; return -1; }
	return NextWord();
];

[ PronounNotice p_object;
	if(p_object == 0 or player or Directions) return;
	if(p_object has pluralname) return;
	if(p_object has animate) {
		if(p_object has female) herobj = p_object;
		else if(p_object has neuter) itobj = p_object;
		else himobj = p_object;
	} else itobj = p_object;
	!print "he ", himobj, " she ", herobj, " it ", itobj, "^";
];

[ _UserFilter _obj;
	!  UserFilter consults the user's filter (or checks on attribute)
	!  to see what already-accepted nouns are acceptable
    if(noun_filter > 0 && noun_filter < 49) {
        if (_obj has (noun_filter-1)) rtrue;
        rfalse;
    }
    noun = _obj;
    return indirect(noun_filter);
];

[ _CheckNoun p_parse_pointer _i _j _n _p _obj _matches _low_priority_match_obj _low_priority_match_len _current_word _name_array _name_array_len _best_score _result _stop;
#IfDef DEBUG_CHECKNOUN;
	print "Entering _CheckNoun!^";
#EndIf;
	! return 0 if no noun matches
	! return -n if more n matches found (n > 1)
	! else return object number
	! side effects:
	! - uses parser_check_multiple
	! - which_object
	!     - stores number of objects in -> 0
	!     - stores number of words consumed in -> 1
	!     - stores all matching nouns if more than one in -->1 ...

	! this is needed after a which question, so that we
	! can answer 'the pink book' and similar
	while(p_parse_pointer --> 0 == 'a//' or 'the' or 'an') {
		wn = wn + 1;
		p_parse_pointer = p_parse_pointer + 4;
	}

	if((((p_parse_pointer-->0) -> #dict_par1) & 128) == 0) {
		! this word doesn't have the noun flag set,
		! so it can't be part of a noun phrase
		return 0;
	}

#IfDef DEBUG;
	if(meta) {
		_name_array_len = Directions; _stop = top_object + 1;
	} else {
		_name_array_len = 0; _stop = scope_objects;
	}
	for(_i = _name_array_len: _i < _stop: _i++) {
		if(meta) _obj = _i; else _obj = scope-->_i;
#IfNot;
	_stop = scope_objects;
	for(_i = 0: _i < _stop: _i++) {
		_obj = scope-->_i;
#Endif;
		_n = wn;
		_p = p_parse_pointer;
		_current_word = p_parse_pointer-->0;
#IfDef DEBUG_CHECKNOUN;
		print "Testing ", (the) _obj, " _n is ", _n, "...^";
#EndIf;
		if((noun_filter == 0 || _UserFilter(_obj) ~= 0)) {
#IfDef DEBUG;
			! Problem: parse_name is an alias of sw_to, and debug verbs can
			! reference any object in the game, some of which are rooms.
			! Solution: If the object seems to be a room and the routine returns
			! a valid object id, or it prints something and then returns true,
			! don't consider it a match.
			if(_obj.parse_name ofclass Routine) {
				_j = wn;
				@output_stream 3 printbuffer;
				_result = _obj.parse_name();
				@output_stream -3;
				if(meta ~= 0 && parent(_obj) == 0
						&& ~~(_obj provides describe or life or found_in or capacity)
						&& (_result > Directions || _n + _result > parse->1
							|| (_result == 1 && printbuffer-->0 > 0))) {
					_result = 0;
				}
#IfNot;
			if(_obj.parse_name) {
				_j = wn;
				_result = _obj.parse_name();
#EndIf;
				if(_result == -1) jump try_name_match;
				_n = _n + _result; ! number of words consumed
				wn = _j;
				if(_n > wn) {
					if(meta == false && _obj has concealed or scenery) {
						! this is a non-debug verb and since the object
						! isn't obvious we don't consider it as an
						! option for a future "which X?" question.
						! However, we still remember it as last resort
						! if nothing else matches
						if(_low_priority_match_len < _n) {
							_low_priority_match_obj = _obj;
							_low_priority_match_len = _n;
#IfDef DEBUG_CHECKNOUN;
						print "concealed best score ", _low_priority_match_len, "^";
#EndIf;
						}
					} else if(_n == _best_score) {
						_matches++;
						which_object-->_matches = _obj;
#IfDef DEBUG_CHECKNOUN;
						print "Same best score ", _best_score, ". Matches are now ", _matches,"^";
#EndIf;
					} else if(_n > _best_score) {
#IfDef DEBUG_CHECKNOUN;
						print "New best score - matched with parse_name ", _n,"^";
#EndIf;
						_best_score = _n;
						_matches = 1;
						which_object-->1 = _obj;
					}
				}
			} else {
.try_name_match;
				@get_prop_addr _obj name -> _name_array;
				if(_name_array) {
					! Assembler equivalent of _name_array_len = _obj.#name / 2
					@get_prop_len _name_array -> _name_array_len;
#IfV5;
					@log_shift _name_array_len (-1) -> _name_array_len;
#IfNot;
					@div _name_array_len 2 -> _name_array_len;
#EndIf;

					while(_IsSentenceDivider(_p) == false) {
#IfV5;
						@scan_table _current_word _name_array _name_array_len -> _result ?success;
#IfNot;
						_j = 0;
						@dec _name_array_len; ! This is needed for the loop.
.next_word_in_name_prop;
						@loadw _name_array _j -> _result;
						@je _result _current_word ?success;
	!					if(_name_array-->_j == _current_word) jump success;
						@inc_chk _j _name_array_len ?~next_word_in_name_prop;
#EndIf;
						jump not_matched;
.success;
#IfV3;
						@inc _name_array_len; ! restore after loop
#EndIf;
#IfDef DEBUG_CHECKNOUN;
						print " - matched ", (address) _current_word,"^";
#EndIf;
						_n++;
						_p = _p + 4;
						_current_word = _p-->0;
						if(_n >= _best_score) {
							if(meta == false && _obj has concealed or scenery) {
								! this is a non-debug verb and since the object
								! isn't obvious we don't consider it as an
								! option for a future "which X?" question.
								! However, we still remember it as last resort
								! if nothing else matches
								if(_low_priority_match_len < _n) {
									_low_priority_match_obj = _obj;
									_low_priority_match_len = _n;
#IfDef DEBUG_CHECKNOUN;
						print "concealed best score ", _low_priority_match_len, "^";
#EndIf;
								}
							} else if(_n == _best_score) {
								_matches++;
								which_object-->_matches = _obj;
#IfDef DEBUG_CHECKNOUN;
								print "Same best score ", _best_score, ". Matches are now ", _matches,"^";
#EndIf;
							} else if(_n > _best_score) {
								_matches = 1;
#IfDef DEBUG_CHECKNOUN;
								print "New best score ", _n, ". Old score was ", _best_score,". Matches is now ",_matches,".^";
#EndIf;
								_best_score = _n;
								which_object-->1 = _obj;
							}
						}
					}
				}
			}
		}
.not_matched;
	}

	if((_matches == 0 && _low_priority_match_len > 0) ||
	   (_low_priority_match_len > _best_score)) {
		! only scenery or concealed objects matched.
		! or concealed was better match than visible objects
		_matches = 1;
		_best_score = _low_priority_match_len;
		which_object-->1 = _low_priority_match_obj;
	}

	which_object->0 = _matches;
	which_object->1 = _best_score - wn;

	if(_matches == 1) {
		_result = which_object-->1;
#IfDef DEBUG_CHECKNOUN;
		print "Matched a single object: ", (the) _result,
			", num words ", which_object->1, "^";
#EndIf;
		return _result;
	}
#IfDef DEBUG_CHECKNOUN;
				print "Matches: ", _matches,", num words ", which_object->1, "^";
#EndIf;
	if(_matches > 1) {
		return -_matches;
	}
	return 0;
];

[ _AskWhichNoun p_num_matching_nouns _i;
	print "Do you mean ";
	for(_i = 1 : _i <= p_num_matching_nouns : _i++) {
		if(_i > 1) {
			if(_i == p_num_matching_nouns) {
				print " or ";
			} else {
				print ", ";
			}
		}
		print (the) which_object --> _i;
	}
	print "?";
];

[ _GetNextNoun p_parse_pointer p_phase _noun _oldwn _num_words_in_nounphrase _pluralword _i _all_found;
	! try getting a noun from the <p_parse_pointer> entry in parse
	! return:
	!   <noun number> if found
	!   0  if no noun found (but we didn't write an error message)
	!   -1 if we should give up parsing completely (because
	!      the player has entered a new command line).
	!   -2 if parsing failed, and error message written
	!
	! Side effects:
	! - if found, then wn will be updated
	! - if plural matched, then parser_action set to ##PluralFound
	!
	! NOTE: you need to update parse_pointer after calling _GetNextNoun since
	! wn can change

	parser_action = 0;

	! special rule to avoid "all in"
	! (since 'in' in this combination is usually
	! a preposition but also matches a direction noun)
	if(p_parse_pointer-->0 == ALL_WORD &&
		(p_parse_pointer + 4)-->0 == 'in') {
		++wn;
		return 0;
	}

	! skip 'the', 'all' etc
	while(p_parse_pointer --> 0 == 'a//' or 'the' or 'an' or ALL_WORD or EXCEPT_WORD1 or EXCEPT_WORD2) {
		if(p_parse_pointer --> 0 == ALL_WORD) {
			parser_all_found = true; !TODO: do we really need the global?
			_all_found = true;
		}
#IfDef DEBUG_GETNEXTNOUN;
		print "skipping ",(address) p_parse_pointer --> 0,"^";
#Endif;
		++wn;
		p_parse_pointer = p_parse_pointer + 4;
	}

	! check for pronouns
	if(p_parse_pointer --> 0 == 'it' or 'him' or 'her') {
		switch(p_parse_pointer --> 0) {
		'it': _noun = itobj;
		'him': _noun = himobj;
		'her': _noun = herobj;
		}
		if(_noun == 0) {
			phase2_necessary = true;
			if(p_phase == PHASE2) {
				print "I don't know what ~",(address) p_parse_pointer --> 0, "~ refers to.^";
				return -2;
			}
		} else if(TestScope(_noun) == false) {
			phase2_necessary = true;
			if(p_phase == PHASE2) {
				print "You can't see ~",(address) p_parse_pointer --> 0, "~ (", (name) _noun, ") at the moment.^";
				return -2;
			}
	 	}
		++wn;
		return _noun;
	}

	! not a pronoun, continue
	_pluralword = ((p_parse_pointer-->0) -> #dict_par1) & 4;
#IfDef DEBUG_GETNEXTNOUN;
	print "Calling _CheckNoun(",p_parse_pointer,");^";
	if(p_parse_pointer-->0 > 2000) print (address) p_parse_pointer-->0, " ", _pluralword, "^";
#Endif;
#IfDef DEBUG_TIMER;
	timer2_start = $1c-->0;
#Endif;
	_noun = _CheckNoun(p_parse_pointer);
#IfDef DEBUG_TIMER;
	timer2_stop = $1c-->0 - timer2_start;
	print "[_CheckNoun took ",timer2_stop," jiffies]^";
#Endif;
	_num_words_in_nounphrase = which_object -> 1;

.recheck_noun;
	if(_noun < 0) {
		if(_pluralword || _all_found) {
			! we don't have to ask here, because the input was
			! "take books" or "take all books"
			phase2_necessary = true;
			parser_action = ##PluralFound;
			wn = wn + _num_words_in_nounphrase;
			return 0;
		}
		if(p_phase == PHASE1) {
			phase2_necessary = true;
			wn = wn + _num_words_in_nounphrase;
			return 1; ! a random noun in phase 1 just to avoid which? question
		}
		_AskWhichNoun(-_noun);
		! read a new line of input
		! I need to use parse since NextWord
		! for parse_name and others hardcode this
		! usage, so I first store the old input into
		! temp arrays that I will restore if I can
		! disambiguate successfully.
		_CopyInputArray(buffer, buffer2);
		_CopyParseArray(parse, parse2);
		@new_line;
		@new_line;
		_ReadPlayerInput();
		! is this a reply to the question?
		if((((parse + 2) --> 0) + DICT_BYTES_FOR_WORD)->0 & 1 == 0) {
			! the first word is not a verb. Assume
			! a valid reply and add the other
			! entry into parse, then retry

			! add the word we got stuck at to the temp parse buffer
			! this is to be able to handle a room with a transparent
			! box, a opaque box and a transparent chest, while
			! processing "take transparent". If the player responds
			! 'box' then we don't know if it is the transparent or
			! opqaue box unless we also add the 'transparent' word
			! before calling _CheckNoun

			_oldwn = wn; ! wn is used in _CheckNoun, so save it

			! since more than one word may be given we need to loop
			! over and test each word
			_CopyParseArray(parse, parse3);
			for(_i = 0 : _i < parse3 -> 1 : _i++) {
				!print "Testing ", (address) (parse3 + 2 + _i * 4) --> 0, "^";
				(parse + 2) --> 0 = (parse3 + 2 + _i * 4) --> 0;

				! note that we have to add this is correct order otherwise
				! parse_name routines may not work, so we need to test
				! both ways.

#IfDef DEBUG;
				!_PrintParseArray(parse);
#Endif;
				(parse + 6)-->0 = (parse2 + 2 + 4*(_oldwn - 1))-->0;
				if((parse + 6)-->0 == (parse + 2)-->0) {
					! don't allow repeated words (red red etc)
					(parse + 6) --> 0 = 0;
					parse->1 = 1;
				} else {
					parse->1 = 2;
				}
#IfDef DEBUG;
				!_PrintParseArray(parse);
#Endif;
				wn = 1;
				_noun = _CheckNoun(parse+2);
				if(_noun <= 0) {
					! the normal word order didn't work. Try the other way
					!print "testing other word order^";
#IfDef DEBUG;
					!_PrintParseArray(parse);
#Endif;
					(parse + 6)-->0 = (parse + 2)-->0;
					(parse + 2)-->0 = (parse2 + 2 + 4*(_oldwn - 1))-->0;
					if((parse + 6)-->0 == (parse + 2)-->0) {
						! don't allow repeated words (red red etc)
						(parse + 6) --> 0 = 0;
						parse->1 = 1;
					} else {
						parse->1 = 2;
					}
#IfDef DEBUG;
					!_PrintParseArray(parse);
#Endif;
					wn = 1;
					_noun = _CheckNoun(parse+2);
				}
				wn = _oldwn; ! restore wn after the _CheckNoun calls
				if(_noun > 0) {
					! we have successfully disambiguated the noun phrase.
					! now we need to restore the length of the
					! noun phrase so that it will be absorbed when we
					! return from the routine.
					! don't forget to restore the old arrays
					_CopyInputArray(buffer2, buffer);
					_CopyParseArray(parse2, parse);
					jump recheck_noun;
				}
			}
			PrintMsg(MSG_PARSER_CANT_DISAMBIGUATE);
			return -2;
		}
		! completely new input.
		return -1; ! start from the beginning
	} else if(_noun > 0) {
#IfDef DEBUG_GETNEXTNOUN;
		print "Noun match! ", _noun, " ", which_object->1, "^";
#EndIf;
		wn = wn + _num_words_in_nounphrase;
		return _noun;
	} else {
		! this is not a recognized word at all
#IfDef DEBUG_GETNEXTNOUN;
		print "it wasn't a noun^";
#EndIf;
		return 0;
	}
];

[ _UpdateNounSecond p_noun p_inp;
	if(num_noun_groups == 0) {
		noun = p_noun;
		inp1 = p_inp;
	} else if(num_noun_groups == 1){
		second = p_noun;
		inp2 = p_inp;
	}
	++num_noun_groups;
];

[ _IsSentenceDivider p_parse_pointer;
	! check if current parse block, indicated by p_parse_pointer,
	! is a period or other sentence divider
	return p_parse_pointer --> 0 == './/' or ',//' or 'and' or 'then';
];

[ ParseToken p_token_type p_token_data;
	! DM defines ParseToken as ParseToken(tokentype,tokendata)
	! ParseToken is similar to a general parse routine,
	! and returns GPR_FAIL, GPR_MULTIPLE, GPR_NUMBER,
	! GPR_PREPOSITION, GPR_REPARSE or the object number
	return _ParseToken(p_token_type, p_token_data, -PHASE1);
];

[ _GrabIfNotHeld p_noun;
	if(p_noun in player) return;
	print "(first taking ", (the) p_noun, ")^";
	keep_silent = true;
	PerformAction(##Take, p_noun);
	keep_silent = false;
	if(p_noun notin player) rtrue;
];

[ _CreatureTest obj;
	! Will this obj do for a "creature" token?
    if (actor ~= player) rtrue;
    if (obj has animate) rtrue;
    if (obj hasnt talkable) rfalse;
    rfalse;
];

[ _ParseToken p_pattern_pointer p_parse_pointer p_phase _noun _i _token _token_type _token_data;
	! ParseToken is similar to a general parse routine,
	! and returns GPR_FAIL, GPR_MULTIPLE, GPR_NUMBER,
	! GPR_PREPOSITION, GPR_REPARSE or the object number
	! However, it also taks the current grammar token as input
	! while a general parse routine takes no arguments.
	! (this is mostly to avoid recalculating the values from wn
	! when the calling routine already has them at hand)

	if(p_phase < 0) {
		! called from ParseToken (DM library API)
		p_phase = -p_phase;
		_token = p_pattern_pointer;
		_token_data = p_parse_pointer;
		p_parse_pointer = parse + 2 + 4 * (wn - 1);
		p_pattern_pointer = 0;
	} else {
		_token = (p_pattern_pointer -> 0);
		_token_data = (p_pattern_pointer + 1) --> 0;
	}
	_token_type = _token & $0f;
	! first set up filters, if any
	noun_filter = 0;
	if(_token_type == TT_ROUTINE_FILTER) {
		noun_filter = _token_data;
		_token_type = TT_OBJECT;
		_token_data = NOUN_OBJECT;
	} else if(_token_type == TT_ATTR_FILTER) {
		noun_filter = 1 + _token_data;
		_token_type = TT_OBJECT;
		_token_data = NOUN_OBJECT;
	} else if(_token_type == TT_SCOPE) {
		_token_type = TT_OBJECT;
		scope_routine = _token_data;
		! check what type of routine (single or multi)
		scope_stage = 1;
		_i = indirect(scope_routine);
		if(_i == 1)
			_token_data = MULTI_OBJECT;
		else
			_token_data = NOUN_OBJECT;
		! trigger add to scope
		scope_stage = 2;
		_UpdateScope();
		scope_stage = 0;
	} else if(_token_type == TT_PARSE_ROUTINE) {
		return  indirect(_token_data);
	}
	! then parse objects or prepositions
	if(_token_type == TT_PREPOSITION) {
#IfDef DEBUG_PARSETOKEN;
		print "Preposition: _token ", _token, " _token_type ", _token_type, ": data ", _token_data;
		if(_token_data > 1000) {
			print " '", (address) _token_data, "'";
		} else {
			print " (this is not a preposition!)";
		}
		@new_line;
#EndIf;
		if(p_parse_pointer --> 0 == _token_data) {
#IfDef DEBUG_PARSETOKEN;
			print "Match!^";
#EndIf;
			wn++;
			return GPR_PREPOSITION;
		}
#IfDef DEBUG_PARSETOKEN;
		print "Failed prep: ", p_parse_pointer, ": ", (address) p_parse_pointer --> 0, " doesn't match ", (address) _token_data, "^";
#EndIf;
		return GPR_FAIL;
	} else if(_token_type == TT_OBJECT) {
		! here _token_data will be one of
		! NOUN_OBJECT, HELD_OBJECT, MULTI_OBJECT, MULTIHELD_OBJECT,
		! MULTIEXCEPT_OBJECT, MULTIINSIDE_OBJECT, CREATURE_OBJECT,
		! SPECIAL_OBJECT, NUMBER_OBJECT or TOPIC_OBJECT
		!
		! remember if except or inside found, so we can filter later
		if(_token_data == MULTI_OBJECT or MULTIHELD_OBJECT or MULTIEXCEPT_OBJECT or MULTIINSIDE_OBJECT) {
			parser_check_multiple = _token_data;
		}

		if(_token_data == NOUN_OBJECT or HELD_OBJECT or CREATURE_OBJECT) {
			_noun = _GetNextNoun(p_parse_pointer, p_phase);
			if(_noun == -2) return GPR_FAIL;
			if(_noun == -1) return GPR_REPARSE;
			if(_noun == 0) {
				parser_unknown_noun_found = p_parse_pointer;
				return GPR_FAIL;
			}
			p_parse_pointer = parse + 2 + 4 * (wn - 1);
			if(_token_data == CREATURE_OBJECT && _CreatureTest(_noun) == 0)  {
				if(p_phase == PHASE2) {
					PrintMsg(MSG_PARSER_ONLY_TO_ANIMATE);
				}
				return GPR_FAIL;
			}
			if(_token_data == HELD_OBJECT && _noun notin player) {
				phase2_necessary = true;
				if(p_phase == PHASE2) {
					_GrabIfNotHeld(_noun);
					if(_noun notin player) {
						return GPR_FAIL;
					}
				}
			}
			return _noun;
		} else if(_token_data == MULTI_OBJECT or MULTIHELD_OBJECT or MULTIEXCEPT_OBJECT or MULTIINSIDE_OBJECT) {
			for(::) {
				_noun = _GetNextNoun(p_parse_pointer, p_phase);
				if(_noun == -2) return GPR_FAIL;
				if(_noun == -1) return GPR_REPARSE;
				if(_noun == 0) {
					! here it is either a plural, 'all' or not understood
					!
					if(parser_action == ##PluralFound) {
						! take books or take all books
						parser_all_found = true;
						! copy which_object to multiple_objects
						for(_i = 0: _i < which_object->0: _i++) {
							multiple_objects --> 0 = 1 + (multiple_objects --> 0);
							multiple_objects --> (multiple_objects --> 0) = which_object--> (_i + 1);
						}
#IfDef DEBUG_PARSETOKEN;
						print "adding plural ", which_object->0, " ", which_object->1, " ", multiple_objects --> 0, "^";
#Endif;
						! check if 'take all Xs but Y'
						p_parse_pointer = parse + 2 + 4 * (wn - 1);
						if(_PeekAtNextWord() == EXCEPT_WORD1 or EXCEPT_WORD2) {
							wn = wn + 1;
							! here we only want to consider the Xs
							! so we clear scope and copy Xs into scope
							! before GetNextNoun. Later we need to restore scope
							scope_objects = multiple_objects --> 0;
							for(_noun = 0: _noun < multiple_objects --> 0 : _noun++) {
								scope-->_noun = multiple_objects-->(_noun + 1);
							}
							_noun = _GetNextNoun(p_parse_pointer + 4, p_phase);
							_UpdateScope(player, true); ! restore scope
							if(_noun <= 0) {
								if(p_phase == PHASE2)
									PrintMsg(MSG_PARSER_NOTHING_TO_VERB);
								return GPR_FAIL;
							}
							parser_all_except_object = _noun;
							! allow 'take all Xs but Y one'
							p_parse_pointer = parse + 2 + 4 * (wn - 1);
							if(_PeekAtNextWord() == 'one') {
								wn = wn + 1;
							}
						}
						return GPR_MULTIPLE;
					}
					if(p_parse_pointer-->0 == ALL_WORD) {
						! take all etc.
						! note that 'all' has already updated
						! wn in GetNextNoun
						!
						! Add all reasonable objects in scope
						! to the multiple_objects array
						_AddMultipleNouns(_token_data);
						parser_all_found = true;
						if(multiple_objects --> 0 == 0) {
							if(p_phase == PHASE2) {
								PrintMsg(MSG_PARSER_NOTHING_TO_VERB);
								return GPR_FAIL;
							}
							return GPR_MULTIPLE;
						} else if(multiple_objects --> 0 == 1) {
							! single object
							_noun = multiple_objects --> 1;
							return _noun;
						} else {
							! multiple objects
							return GPR_MULTIPLE;
						}
					}
					parser_unknown_noun_found = p_parse_pointer;
					return GPR_FAIL;
				}
				! adding a single object
				p_parse_pointer = parse + 2 + 4 * (wn - 1);
				multiple_objects --> 0 = 1 + (multiple_objects --> 0);
				multiple_objects --> (multiple_objects --> 0) = _noun;
				! check if we should continue: and or comma
				! not followed by a verb
				if(_PeekAtNextWord() == comma_word or AND_WORD or THEN_WORD) {
					if((((parse + 2 ) --> (2 * wn)) + DICT_BYTES_FOR_WORD)->0 & 1 == 0) {
						! this is not a verb so we assume it is a list
						! of nouns instead. Continue to parse
						++wn;
						p_parse_pointer = p_parse_pointer + 4;
						!print "and followed by a noun^";
						continue;
					}
					!print "and followed by a verb^";
				}
				break;
			}
			if(multiple_objects --> 0 == 0) {
				! no nouns found, so this pattern didn't match
				return GPR_FAIL;
			}
			return GPR_MULTIPLE;
		} else if(_token_data == TOPIC_OBJECT) {
			consult_from = wn;
			consult_words = 0;
			! topic continues until end of line or
			! until the word matches the preposition
			! defined in the next pattern
			!print (p_pattern_pointer + 3) -> 0, "^"; ! token
			!print (p_pattern_pointer + 4) --> 0, "^"; ! token_data
			if(p_pattern_pointer ~= 0) {
				_i = (p_pattern_pointer + 4) --> 0; ! word to stop at
			} else {
				_i = NULL;
			}
			for(::) {
				++wn;
				++consult_words;
				p_parse_pointer = p_parse_pointer + 4;
				if(wn > parse->1 || p_parse_pointer --> 0 == _i) {
					! found the stop token, or end of line
					break;
				}
			}
			return GPR_NUMBER;
		} else if(_token_data == SPECIAL_OBJECT) {
			parsed_number = TryNumber(wn);
			special_word = NextWord(); ! will make wn++
			if(parsed_number == -1000) parsed_number = special_word;
			return GPR_NUMBER;
		} else if(_token_data == NUMBER_OBJECT) {
			parsed_number = TryNumber(wn++);
			return GPR_NUMBER;
		}
	}
];

[ _AddMultipleNouns p_multiple_objects_type   _i _addobj _obj _p _ceil;
	multiple_objects --> 0 = 0;
	for(_i = 0: _i < scope_objects: _i++) {
		_obj = scope-->_i;
		_addobj = false;
		switch(p_multiple_objects_type) {
		! MULTIEXCEPT_OBJECT, MULTIINSIDE_OBJECT:
		! we don't know yet know what 'second' is, so we
		! add all reasonable objects and filter later
		MULTIHELD_OBJECT, MULTIEXCEPT_OBJECT:
			_addobj = _obj in player;
		MULTI_OBJECT:
			_p = parent(_obj);
			_ceil = TouchCeiling(player);
			_addobj = false;
			if((_p == _ceil || (_p ~= 0 && _p in _ceil && _p has scenery or static && _p hasnt concealed && _p has container or supporter)) && _obj hasnt scenery or concealed or static or animate)
				_addobj = true;
		MULTIINSIDE_OBJECT:
			_p = parent(_obj);
			_ceil = TouchCeiling(player);
			_addobj = false;
			if(_p ~= 0 && _p has container or supporter && _obj hasnt scenery or concealed or static or animate)
				_addobj = true;
!			_addobj = _obj hasnt scenery or concealed or static or animate &&
!				(_p == 0 || parent(_p) == 0 || _p has container or supporter);
		}
		if(action == ##Take && _obj in player) _addobj = false;
		if(_addobj) {
			multiple_objects --> 0 = 1 + (multiple_objects --> 0);
			multiple_objects --> (multiple_objects --> 0) = _obj;
			!print "Adding ", (name) _obj, "^";
		}
	}
];

[ _PrintPartialMatch p_start p_stop _start _stop _i;
	_i = (parse-2+(4*p_start));
	_start = _i->3; ! index to input line for first word
	if(p_stop > parse -> 1) {
		_stop = buffer->0; ! until the end of the input
	} else {
		_i = (parse-2+(4*p_stop));
		_stop = _i->2 + _i->3; ! until the index of the stop word + its length
	}
	for(_i = _start: _i < _stop: _i ++) {
		if(buffer -> _i == 0) break;
		print (char) buffer -> _i;
	}
];

[ _PrintPartialMatchMessage _num_words;
	print "I only understood you as far as ~";
	_PrintPartialMatch(verb_wordnum, _num_words);
	"~ but then you lost me.";
];


[ _PrintUnknownWord _i;
	for(_i = 0: _i < parser_unknown_noun_found->2: _i++) {
		print (char) buffer->(_i + parser_unknown_noun_found->3);
	}
];


#IfDef OPTIONAL_GUESS_MISSING_NOUN;
Constant GUESS_CREATURE = 0;
Constant GUESS_HELD = 1;
Constant GUESS_CONTAINER = 2;
Constant GUESS_THING = 3;
Constant GUESS_DOOR = 4;
Array guess_object-->5;
Array guess_num_objects->5;
[ _GuessMissingNoun p_type p_prep p_nounphrase_num _assumed _exclude _i _noun;
	for(_i = 0: _i < 5: _i++) guess_num_objects->_i = 0;

	if(p_nounphrase_num == 1) {
		_assumed = noun;
	} else {
		_assumed = second;
		if(_assumed == 0) _assumed = noun;
		_exclude = noun;
	}

	for(_i = 0: _i < scope_objects: _i++) {
		_noun = scope-->_i;
		if(_noun == player) continue;
		if(ObjectIsInvisible(_noun)) continue;
		if(_noun has door && _noun ~= _exclude) {
			guess_object-->GUESS_DOOR = _noun;
			guess_num_objects->GUESS_DOOR = 1 + guess_num_objects->GUESS_DOOR;
		}
		if(_noun has container && _noun ~= _exclude) {
			guess_object-->GUESS_CONTAINER = _noun;
			guess_num_objects->GUESS_CONTAINER = 1 + guess_num_objects->GUESS_CONTAINER;
		}
		if(_noun has animate && _noun ~= _exclude) {
			guess_object-->GUESS_CREATURE = _noun;
			guess_num_objects->GUESS_CREATURE = 1 + guess_num_objects->GUESS_CREATURE;
		}
		if(_noun in player && _noun ~= _exclude) {
			guess_object-->GUESS_HELD = _noun;
			guess_num_objects->GUESS_HELD = 1 + guess_num_objects->GUESS_HELD;
		}
		if(_noun hasnt scenery or concealed && _noun ~= _exclude) {
			guess_object-->GUESS_THING = _noun;
			guess_num_objects->GUESS_THING = 1 + guess_num_objects->GUESS_THING;
		}
	}

	_noun = 0;
	switch(p_type) {
	HELD_OBJECT:
		if(guess_num_objects->GUESS_HELD == 1)
			_noun = guess_object-->GUESS_HELD;
	CREATURE_OBJECT:
		if(guess_num_objects->GUESS_CREATURE == 1)
			_noun = guess_object-->GUESS_CREATURE;
	default:
		if(_noun == 0 && guess_num_objects->GUESS_CONTAINER == 1 &&
			action == ##Open or ##Close) {
			_noun = guess_object-->GUESS_CONTAINER;
		}
		if(_noun == 0 && guess_num_objects->GUESS_DOOR == 1 &&
			action == ##Lock or ##Unlock or ##Open or ##Close) {
			_noun = guess_object-->GUESS_DOOR;
		}
		if(_noun == 0 && guess_num_objects->GUESS_THING == 1) {
			_noun = guess_object-->GUESS_THING;
		}
	}

	if(_noun == _assumed) _noun = 0;
	if(_noun) {
		print "(assuming ";
		if(p_prep) {
			print (address) (p_prep+1) --> 0, " ";
		} else {
		}
		print (the) _noun, ")^";
	}
	return _noun;
];

#EndIf;

[ _FixIncompleteSentenceOrComplain p_pattern _token _type _data _noun _prep _second _num_preps;
	! Called because sentence shorter than the pattern
	! Available data: wn, parse and p_pattern_token (last matched token)
	!
	! Either guess missing parts in the pattern and return true,
	! or print a suitable error message and return false
	!
	! INFORM:
	! lock: What do you want to lock?
	! lock door: What do you want to lock the toilet door with?
	! lock door with: What do you want to lock the toilet door with?
	! lock door on: I didn't understand that sentence.
	! give john: What do you want to give John?
	! jump at: I only understood you as far as wanting to jump.
	! jump over: What do you want to jump over?
	!
	! Inform tries the 'itobj' if second missing, and his/herobj
	! is creature missing (or if only one animate object in scope)

	! analyse the rest of the pattern to see if second and prep are expected
	for(_token = p_pattern + 3: _token->0 ~= TT_END: _token = _token + 3) {
		_type = _token -> 0;
		if(_type > 9) {
			_prep = _token;
		} else {
			if(_noun == 0) {
				_noun = _token;
			} else {
				_second = _token;
			}
		}
	}

	! try to guess missing parts in the pattern
	! return true if we could fix everything
#IfDef OPTIONAL_GUESS_MISSING_NOUN;
	if(_noun ~= 0 && noun == 0) noun = _GuessMissingNoun(_noun -> 2, 0, 1);
	if(_second ~= 0 && second == 0) second = _GuessMissingNoun(_second -> 2, _prep, 2);
	if((_noun == 0 || noun ~= 0) && (_second == 0 || second ~= 0)) {
		!print "message complete: ", noun, " ", second, "^";
		rtrue;
	}
#EndIf;

	! write an error message and return false
	print "I think you wanted to say ~";
	print (verbname) verb_word;
	for(_token = p_pattern + 3: _token->0 ~= TT_END: _token = _token + 3) {
		_type = _token -> 0;
		_data = (_token + 1) --> 0;
		if(_type > 9) {
			if(_num_preps == 0) print " ", (address) _data;
			++_num_preps;
		} else {
			if(_noun == 0) {
				if(second == 0) print " something"; else print " ", (name) second;
			} else {
				if(noun ~= 0) {
					_noun = 0; ! avoid repeat (and we don't need _noun anymore)
					print " ",(name) noun;
				} else if(_token->2 == CREATURE_OBJECT) {
					print " someone";
				} else {
					print " something";
				}
			}
		}
	}
	print "~. Please try again.^";
	rfalse;
];

[ _ParsePattern p_pattern p_phase _pattern_pointer _parse_pointer _noun _i _j _k _word;
	! Check if the current pattern will parse, with side effects if PHASE2
	! _ParsePattern will return:
	!   -1 if need to reparse
	!   0..99 how many words were matched before the match failed
	!   100 if perfect match
	wn = verb_wordnum + 1;
	_parse_pointer = parse + 2 + 4*(verb_wordnum);
	_pattern_pointer = p_pattern - 1;
	num_noun_groups = 0;
	noun = 0;
	second = 0;
	consult_from = 0;
	inp1 = 0;
	inp2 = 0;
	special_number = 0;
	special_word = 0;
	parsed_number = 0;
	multiple_objects --> 0 = 0;
	parser_check_multiple = 0;
	parser_unknown_noun_found = 0;
	parser_all_found = false;
	parser_all_except_object = 0;
	action = (p_pattern --> 0) & $03ff;
	action_reverse = ((p_pattern --> 0) & $400 ~= 0);
	phase2_necessary = false;

	while(true) {
		_pattern_pointer = _pattern_pointer + 3;
#IfDef DEBUG_PARSEPATTERN;
		print "TOKEN: ", _pattern_pointer -> 0, " wn ", wn, " _parse_pointer ", _parse_pointer, "^";
#EndIf;

		if(((_pattern_pointer -> 0) & $0f) == TT_END) {
			if(_IsSentenceDivider(_parse_pointer)) {
				wn++;
				return 100; ! pattern matched
			}
			if(wn == 1 + parse->1) {
				return 100; ! pattern matched
			}
			return wn - verb_wordnum; ! Fail because the grammar line ends here but not the input
		}
		if(wn >= 1 + parse->1) {
#IfDef DEBUG_PARSEPATTERN;
			print "Fail, since grammar line has not ended but player input has.^";
#EndIf;
			if(p_phase == PHASE2) {
				!print "You need to be more specific.^";
				if(_FixIncompleteSentenceOrComplain(p_pattern - 1)) {
					! sentence was corrected
					return 100;
				}
			};
			return wn - verb_wordnum;!Fail because input ends here but not the grammar line
		}
#IfDef DEBUG_PARSEPATTERN;
		print "Calling ParseToken: token ", _pattern_pointer->0," type ", (_pattern_pointer->0) & $f, ", data ", (_pattern_pointer + 1) --> 0,"^";
#EndIf;
		_noun = _ParseToken(_pattern_pointer, _parse_pointer, p_phase);
		! the parse routine can change wn, so update _parse_pointer
		_parse_pointer = parse + 2 + 4 * (wn - 1);

		switch(_noun) {
		GPR_FAIL:
			if(_pattern_pointer->0 == TOKEN_FIRST_PREP or TOKEN_MIDDLE_PREP) {
				! First or in the middle of a list of alternative prepositions
#IfDef DEBUG_PARSEPATTERN;
				print "Preposition failed, but more options available so reparsing^";
#Endif;
				continue; ! keep parsing
			}

			! write error messages if PHASE2 as needed
			if(_pattern_pointer->0 == TOKEN_LAST_PREP or TOKEN_SINGLE_PREP) {
				! bad preposition
				if(p_phase == PHASE2) PrintMsg(MSG_PARSER_UNKNOWN_SENTENCE);
			} else if(parser_unknown_noun_found ~= 0) {
				if(p_phase == PHASE2) {
					_word = parser_unknown_noun_found --> 0;
					if(scope_routine ~= 0) {
						scope_stage = 3;
						indirect(scope_routine);
					} else if(_word ~= 0) {
						! is it one of the location.name words?
						inp1 = -1;
						@get_prop_addr location name -> _k;
						if(_k) {
							@get_prop_len _k -> _j;
		#IfV5;
							@log_shift _j (-1) -> _j;
		#IfNot;
							@div _j 2 -> _j;
		#EndIf;
							for(_i = 0: _i < _j: _i++) {
								if(_word == (_k-->_i)) {
									inp1 = _i;
								}
							}
						}
						if(inp1 > -1) {
							print "You don't need to refer to ~";
							_PrintUnknownWord();
							print "~ in this game.^";
						} else if(_word == ALL_WORD) {
							PrintMsg(MSG_PARSER_NOT_MULTIPLE_VERB);
						} else {
							PrintMsg(MSG_PARSER_CANT_SEE_SUCH_THING);
						}
					} else {
						print "Sorry, I don't understand what ~";
						_PrintUnknownWord();
						print "~ means.^";
					}
				} else {
					! give higher score to unknown words matches
					! so that for examine 'get goblin' and 'take goblin'
					! works the same when goblin isn't in scope.
					wn = wn + 1;
				}
			}
			return wn - verb_wordnum; ! pattern didn't match
		GPR_PREPOSITION:
			! advance until the end of the list of prepositions
#IfDef DEBUG_PARSEPATTERN;
			print "-- preposition mached ", _pattern_pointer, " ", _pattern_pointer->0, "^";
#Endif;
			while(_pattern_pointer->0 ~= TOKEN_LAST_PREP or TOKEN_SINGLE_PREP) {
#IfDef DEBUG_PARSEPATTERN;
			print "-- increasing _pattern_pointer^";
#Endif;
				_pattern_pointer = _pattern_pointer + 3;
			}
		GPR_MULTIPLE:
			! multiple_objects contains the objects
			if(multiple_objects-->0 == 0) {
				_UpdateNounSecond(0, 0);
				! 'all' matched zero objects in scope. It is still a perfect
				! match of course but we need to force phase2 to write
				! a suitable message.
				phase2_necessary = true;
			} else {
				_UpdateNounSecond(multiple_objects-->1, multiple_objects-->1);
			}
		GPR_NUMBER:
			! parsed_number contains the new number
			if(p_phase == PHASE2 && parsed_number == -1000)  {
				PrintMsg(MSG_PARSER_BAD_NUMBER);
				return wn - verb_wordnum; ! bad match
			}
			_UpdateNounSecond(parsed_number, 1);
		GPR_REPARSE:
			return -1; ! the player_input and parse have changed
		default:
			! _noun was a valid noun
			_UpdateNounSecond(_noun, _noun);
		}
	}
	! we should never reach this line
	! the while(true) loop is only exited by return statements
];

[ _ParseAndPerformAction _word_data _verb_grammar _i _pattern _pattern_pointer _noun _score _best_score _best_pattern _action;
	! returns
	! 0: to reparse
	! 1/true: if error was found (so you can abort with "error...")
	! -n: if <n> words were used to find a match,
	!
	! taking periods and other sentence breaks into account.
	! For example, if the input is "l.l" then the parser
	! will stop after the first "l" has been mached, and
	! 1 is returned. If the input is "open box" then
	! the whole input is matched and 2 returned.

#IfDef DEBUG_TIMER;
	timer1_start = $1c-->0;
#Endif;
	if(_IsSentenceDivider(parse + 2))
		return -1;

	multiple_objects-->0 = 0;
	selected_direction_index = 0;
	selected_direction = 0;
	action = -1;
	meta = false;
	which_object->1 = 0;
	actor = player;
	noun = 0; ! needed since _ParsePattern not always called
	second = 0;

	if(scope_routine ~= 0) {
		! if true, then scope=Routine was executed
		! in the previous _ParseAndPerformAction,
		! which can have added stuff to the scope
	}
	scope_routine = 0; ! prepare for a new scope=Routine

	if(parse->1 < 1) {
		return PrintMsg(MSG_PARSER_NO_INPUT);
	}

	verb_wordnum = 1;

.reparse;
	verb_word = (parse - 2) --> (2 * verb_wordnum) ;
	if(UnsignedCompare(verb_word, (0-->HEADER_DICTIONARY)) == -1) {
		! Not a verb. Try the entry point routine before giving up
		verb_word = UnknownVerb(verb_word);
		if(verb_word == 0) {
			! unknown word
#IfDef DEBUG_PARSEANDPERFORM;
			print "Case 1, Word ", verb_word, "^";
#EndIf;
			if(actor ~= player) jump treat_bad_line_as_conversation;
			return PrintMsg(MSG_PARSER_UNKNOWN_VERB);
		}
	}

	_word_data = verb_word + DICT_BYTES_FOR_WORD;
	! check if it is a direction
	if((_word_data->0) & 1 == 0) { ! This word does not have the verb flag set.
		! try a direction instead
		wn = verb_wordnum;
		_i = Directions.parse_name();
		if(_i) {
			wn = wn + _i; ! number of words in direction command
			! check if separator or end of line
			_i = wn - 1; ! keep for error message since wn changed by NextWord
			_pattern = NextWord();
			if(_pattern == 0 or comma_word or THEN_WORD) {
				action = ##Go;
				noun = Directions;
				inp1 = Directions;
				jump parse_success;
			}
			! bad direction command, such as "n n"
			return _PrintPartialMatchMessage(_i);
		}
		! not a direction, check if beginning of a command
		_noun = _CheckNoun(parse+2);
		if(_noun > 0 && verb_wordnum == 1) {
			! The sentence starts with a noun, now
			! check if comma afterwards
			wn = wn + which_object->1;
			_pattern = NextWord();
			if(_pattern == comma_word) {
				jump conversation;
			}
		}
		if(actor ~= player) jump treat_bad_line_as_conversation;
		return PrintMsg(MSG_PARSER_UNKNOWN_VERB);

.conversation;
		if(_noun hasnt animate && _noun hasnt talkable) {
			return PrintMsg(MSG_PARSER_CANT_TALK, _noun);
		}
		! See http://www.inform-fiction.org/manual/html/s18.html
		! set actor
		actor = _noun;
		!print "Trying to talk to to ", (the) _noun, ".^";
		verb_wordnum = wn;
		jump reparse;
	}

	! Now it is known word, and it is not a direction, in the first position
	meta = (_word_data->0) & 2;

!   print "Parse array: ", parse, "^";
!   print "Word count: ", parse->0, "^";
!   print "Word 1: ", (parse + 2)-->0, "^";
!   print "Word 2: ", (parse + 6)-->0, "^";
!   print "Word 3: ", (parse + 10)-->0, "^";
	_i = 255 - (_word_data->1); ! was _verb_num
	_verb_grammar = (0-->HEADER_STATIC_MEM)-->_i;

#IfDef DEBUG_PARSEANDPERFORM;
	print "Verb#: ",_i,", meta ",meta,".^";
	print "Grammar address for this verb: ",_verb_grammar,"^";
	print "Number of patterns: ", _verb_grammar->0 ,"^";

	! First print all patterns, for debug purposes
	_pattern = _verb_grammar + 1;
	for(_i = 0 : _i < _verb_grammar->0: _i++) {
		print "############ Pattern ",_i," ",_pattern,"^";
		_pattern = _CheckPattern(_pattern);
	}
	@new_line;
#EndIf;

	! Phase 1: look for best pattern without side effects
	_best_score = 0;
	_best_pattern = 0;
	_pattern = _verb_grammar + 1;
	for(_i = 0 : _i < _verb_grammar->0 : _i++) {
#IfDef DEBUG_PARSEANDPERFORM;
		print "### PHASE 1: Pattern ",_i," address ", _pattern, "^";
#EndIf;
		scope_stage = 0;
		_score = _ParsePattern(_pattern, PHASE1);
		! reset scope if _ParsePattern messed with it
		if(scope_stage > 0)
			_UpdateScope(player, true);

#IfDef DEBUG_PARSEANDPERFORM;
		print "### PHASE 1: result ", _score, "^";
#EndIf;
		! note that _ParsePattern will never return -1 in PHASE1
		if(_score == 0) {
			! This pattern has failed.
#IfDef DEBUG_PARSEANDPERFORM;
			print "Pattern didn't match.^";
#EndIf;
		} else if(_score > _best_score) {
			_best_score = _score;
			_best_pattern = _pattern;
			! check if pefect match found
			if(_best_score == 100) break;
		}

		! Scan to the end of this pattern
		_pattern_pointer = _pattern + 2;
		while(_pattern_pointer -> 0 ~= TT_END) {
			_pattern_pointer = _pattern_pointer + 3;
		}
		_pattern = _pattern_pointer + 1;
	}

	! skip phase 2 if last pattern matched perfectly
	! (since all data is then already setup and there
	! are no side effects to consider)
#IfDef DEBUG_PARSEANDPERFORM;
	print "### After phase 1, _best_score = ", _best_score, ", phase2_necessary = ", phase2_necessary, "^";
#EndIf;
	if(_best_score == 100 && phase2_necessary == false) {
#IfDef DEBUG_PARSEANDPERFORM;
		print "### Skipping phase 2^";
#EndIf;
		jump parse_success;
	}

	if(_best_score < parse->1) {
		!_PrintPartialMatchMessage(_best_score);
		PrintMsg(MSG_PARSER_NOSUCHTHING);
		rtrue;
	}

	! Phase 2: reparse best pattern and ask for additional info if
	! needed (which book? etc)

#IfDef DEBUG_PARSEANDPERFORM;
	print "### PHASE 2: Pattern address ", _best_pattern, "^";
#EndIf;
	_score = _ParsePattern(_best_pattern, PHASE2);
#IfDef DEBUG_PARSEANDPERFORM;
	print "### PHASE 2: result ", _score, "^";
#EndIf;
	if(_score == -1) rfalse; ! force a complete reparse
	if(_score == 100) jump parse_success;
	action = -1; ! to stop each_turn etc.
	rtrue; ! ParsePattern wrote some error message

.treat_bad_line_as_conversation;
	! this is used when not understood and the actor is an NPC
	action = ##NotUnderstood;
	consult_from = wn;
	consult_words = parse->1 - wn + 1;
	special_number = TryNumber(wn);
	special_word = NextWord();
	! fall through to jump parse_success;

.parse_success;
	! we want to return how long the successfully sentence was
	! but wn can be destroyed by action routines, so store in _i
#IfDef DEBUG_TIMER;
	timer1_stop = $1c-->0 - timer1_start;
	print "[parsing took ",timer1_stop," jiffies]^";
#Endif;

	num_words_parsed = -(wn - 1);
	if(action_reverse) {
		_i = second;
		second = noun;
		noun = _i;
		inp1 = noun;
		inp2 = second;
	}

	! do some special transformations
	if(action == ##Tell && noun == player && actor ~= player) {
		! Convert "P, tell me about X" to "ask P about X"
		noun = actor; actor = player; action = ##Ask;
	}
	if(action == ##AskFor && noun ~= player && actor == player) {
		! Convert "ask P for X" to "P, give X to me"
		actor = noun; noun = second; second = player; action = ##Give;
	}

	! prepare noun and second to point at dictionary words
	! from the consult topic, if possible
	if(consult_from) {
		if(0 == noun or second) {
			for(_i=0 : _i < consult_words : _i++) {
				_noun = (parse-->(2 * (consult_from + _i) - 1));
				if(_noun ~= 'a' or 'an' or 'the') {
					if(noun==0)
						noun = _noun;
					else
						second = _noun;
					break;
				}
			}
		}
	}

	if(actor ~= player) {
		! The player's "orders" property can refuse to allow conversation
		! here, by returning true.  If not, the order is sent to the
		! other person's "orders" property.  If that also returns false,
		! then: if it was a misunderstood command anyway, it is converted
		! to an Answer action (thus "floyd, grrr" ends up as
		! "say grrr to floyd").  If it was a good command, it is finally
		! offered to the Order: part of the other person's "life"
		! property, the old-fashioned way of dealing with conversation.
		sw__var = action;
		if(RunRoutines(player, orders)) rtrue;
		if(RunRoutines(actor, orders)) rtrue;
		if(action == ##NotUnderstood) {
			second = actor;
			inp2=second;
			action = ##Answer;
			if(RunLife(actor, action)) rtrue;
		} else {
			if(RunLife(actor, ##Order)) rtrue;
		}
		PrintMsg(MSG_ORDERS_WONT);
		return num_words_parsed;
	}

	if(multiple_objects --> 0 == 0) {
		! single action
		if(inp1 > 1) PronounNotice(noun);
		PerformPreparedAction();
	} else {
		! multiple action
		! (a) check the multiple list isn't empty;
		! (b) warn the player if it has been cut short because too long;
		! (c) generate a sequence of actions from the list
		!     (stopping in the event of death or movement away).
		if(parser_check_multiple == MULTIINSIDE_OBJECT && second has container && second hasnt open) {
        	PrintMsg(MSG_PARSER_CONTAINER_ISNT_OPEN, second);
		} else {
			_score = 0;
			_action = action;
			for(_noun = 1: _noun <= multiple_objects --> 0 : _noun++) {
				action = _action; ! This may have been altered by a previous interation for multitokens
				inp1 = multiple_objects --> _noun;
				noun = inp1;

				! disallow objects mentioned in 'all except/but X' patterns
				if(noun == parser_all_except_object) continue;

				switch(parser_check_multiple) {
				MULTIEXCEPT_OBJECT:
					! stop us from putting X in X, for example
					! > take sack
					! > put all in sack
					if(noun == player) {
						PrintMsg(MSG_NOTHOLDINGTHAT);
						rtrue;
					}
					if(noun == second) continue;
				MULTIINSIDE_OBJECT:
					! stop us from trying to take things that are not in
					! the container
					if(noun notin second) {
						if(parser_all_found) continue;
					}
				}

				! don't try to drop things you don't carry
				if(action == ##Drop && noun notin player && parser_all_found) continue;

				! don't pick up the box when you are in it
				! however, if this is the only object then allow it to
				! get the 'you have to leave it' message.
				if(action == ##Take && noun == parent(player) && parser_all_found) continue;

				! don' pick up held objects if other objects available
				! however, if this is the only object then allow it to
				! get the 'you already have it' message.
                if(action == ##Take && noun in player && (multiple_objects --> 0 > 1 || parser_all_found)) continue;

				if(parser_all_found || multiple_objects --> 0 > 1) print (name) noun, ": ";
				if(inp1 > 1) PronounNotice(noun);
				PerformPreparedAction();
				++_score;
			}
			if(_score == 0) PrintMsg(MSG_PARSER_NOTHING_TO_VERB);
		}
	}
	return num_words_parsed;
];
