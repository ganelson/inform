! ==============================================================================
!   LINKLV:  Link declarations of library variables.
!
!   Supplied for use with Inform 6 -- Release 6/11 -- Serial number 040227
!
!   Copyright Graham Nelson 1993-2004 but freely usable (see manuals)
!
!   This file is automatically Included in your game file by "verblibm" only if
!   you supply the -U compiler switch to use pre-compiled Modules.
! ==============================================================================

System_file;

! ------------------------------------------------------------------------------

Import global location;
Import global sline1;
Import global sline2;

Import global top_object;
Import global standard_interpreter;
Import global undo_flag;
Import global transcript_mode;

Import global xcommsdir;

Import global turns;
Import global the_time;
Import global time_rate;
Import global time_step;
Import global active_timers;

Import global score;
Import global last_score;
Import global notify_mode;
Import global places_score;
Import global things_score;

Import global player;
Import global deadflag;

Import global lightflag;
Import global real_location;
Import global visibility_ceiling;
Import global lookmode;
Import global print_player_flag;
Import global lastdesc;

Import global c_style;
Import global lt_value;
Import global listing_together;
Import global listing_size;
Import global wlf_indent;
Import global inventory_stage;
Import global inventory_style;
Import global pretty_flag;
Import global menu_nesting;
Import global menu_item;
Import global item_width;
Import global item_name;
Import global lm_n;
Import global lm_o;

#Ifdef DEBUG;
Import global debug_flag;
Import global x_scope_count;
#Endif; ! DEBUG

Import global action;
Import global inp1;
Import global inp2;
Import global noun;
Import global second;
Import global keep_silent;
Import global reason_code;
Import global receive_action;

Import global parser_trace;
Import global parser_action;
Import global parser_one;
Import global parser_two;
Import global parser_inflection;
Import global actor;
Import global actors_location;
Import global meta;
Import global multiflag;
Import global toomany_flag;

Import global special_word;
Import global special_number;
Import global parsed_number;
Import global consult_from;
Import global consult_words;
Import global notheld_mode;
Import global onotheld_mode;
Import global not_holding;
Import global etype;
Import global best_etype;
Import global nextbest_etype;
Import global pcount;
Import global pcount2;
Import global parameters;
Import global nsns;
Import global special_number1;
Import global special_number2;
Import global params_wanted;
Import global inferfrom;
Import global inferword;
Import global dont_infer;
Import global action_to_be;
Import global action_reversed;
Import global advance_warning;
Import global found_ttype;
Import global found_tdata;
Import global token_filter;
Import global lookahead;
Import global multi_mode;
Import global multi_wanted;
Import global multi_had;
Import global multi_context;
Import global indef_mode;
Import global indef_type;
Import global indef_wanted;
Import global indef_guess_p;
Import global indef_owner;
Import global indef_cases;
Import global indef_possambig;
Import global indef_nspec_at;
Import global allow_plurals;
Import global take_all_rule;
Import global pronoun_word;
Import global pronoun_obj;
Import global scope_reason;
Import global scope_token;
Import global scope_error;
Import global scope_stage;
Import global ats_flag;
Import global ats_hls;
Import global placed_in_flag;
Import global number_matched;
Import global number_of_classes;
Import global match_length;
Import global match_from;
Import global bestguess_score;
Import global wn;
Import global num_words;
Import global verb_word;
Import global verb_wordnum;
Import global usual_grammar_after;
Import global oops_from;
Import global saved_oops;
Import global held_back_mode;
Import global hb_wn;
Import global short_name_case;

#Ifdef EnglishNaturalLanguage;
Import global itobj;
Import global himobj;
Import global herobj;
Import global old_itobj;
Import global old_himobj;
Import global old_herobj;
#Endif; ! EnglishNaturalLanguage

! ==============================================================================
