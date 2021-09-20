/* Symbols derived mechanically from Inform 7 source: do not edit */

/* (1) Instance IDs */


/* (2) Values of enumerated kinds */

#define i7_I_German_language 1
#define i7_I_Italian_language 2
#define i7_I_English_language 3
#define i7_I_French_language 4
#define i7_I_Swedish_language 5
#define i7_I_Spanish_language 6
#define i7_I_present_tense 1
#define i7_I_past_tense 2
#define i7_I_perfect_tense 3
#define i7_I_past_perfect_tense 4
#define i7_I_future_tense 5
#define i7_I_first_person_singular 1
#define i7_I_second_person_singular 2
#define i7_I_third_person_singular 3
#define i7_I_first_person_plural 4
#define i7_I_second_person_plural 5
#define i7_I_third_person_plural 6
#define i7_I_nominative 1
#define i7_I_accusative 2
#define i7_I_neuter_gender 1
#define i7_I_masculine_gender 2
#define i7_I_feminine_gender 3

/* (3) Kind IDs */

#define i7_K_object 8

/* (4) Action IDs */


/* (5) Property IDs */

#define i7_P_vector 56
#define i7_P_KD_Count 58
#define i7_P_indefinite_article 39
#define i7_P_printed_plural_name 52
#define i7_P_printed_name 55
#define i7_P_plural_named 27
#define i7_P_ambiguously_plural 28
#define i7_P_proper_named 29
#define i7_P_variable_initial_value 76
#define i7_P_specification 77
#define i7_P_indefinite_appearance_text 78
#define i7_P_adaptive_text_viewpoint 75

/* (6) Variable IDs */

#define i7_V_language_of_play 1
#define i7_V_unicode_gestalt_ok 2
#define i7_V_formal_rv 3
#define i7_V_formal_par0 4
#define i7_V_formal_par1 5
#define i7_V_formal_par2 6
#define i7_V_formal_par3 7
#define i7_V_formal_par4 8
#define i7_V_formal_par5 9
#define i7_V_formal_par6 10
#define i7_V_formal_par7 11
#define i7_V_unicode_temp 12
#define i7_V_I7SFRAME 13
#define i7_V_TEXT_TY_RE_Err 14
#define i7_V_prior_named_noun 15
#define i7_V_prior_named_list 16
#define i7_V_prior_named_list_gender 17
#define i7_V_story_tense 18
#define i7_V_story_viewpoint 19
#define i7_V_say__p 20
#define i7_V_say__pc 21
#define i7_V_say__pc_save 22
#define i7_V_say__n 23
#define i7_V_say__comp 24
#define i7_V_los_rv 25
#define i7_V_parameter_object 26
#define i7_V_parameter_value 27
#define i7_V_property_to_be_totalled 28
#define i7_V_property_loop_sign 29
#define i7_V_suppress_scope_loops 30
#define i7_V_temporary_value 31
#define i7_V_clr_fg 32
#define i7_V_clr_bg 33
#define i7_V_clr_fgstatus 34
#define i7_V_clr_bgstatus 35
#define i7_V_clr_on 36
#define i7_V_statuswin_current 37
#define i7_V_suppress_text_substitution 38
#define i7_V_deadflag 39
#define i7_V_statuswin_cursize 40
#define i7_V_statuswin_size 41
#define i7_V_debug_rules 42
#define i7_V_debug_rule_nesting 43
#define i7_V_reason_the_action_failed 44
#define i7_V_indef_mode 45
#define i7_V_standard_interpreter 46
#define i7_V_gg_mainwin 47
#define i7_V_gg_statuswin 48
#define i7_V_gg_quotewin 49
#define i7_V_gg_scriptfref 50
#define i7_V_gg_scriptstr 51
#define i7_V_gg_savestr 52
#define i7_V_gg_commandstr 53
#define i7_V_gg_command_reading 54
#define i7_V_gg_foregroundchan 55
#define i7_V_gg_backgroundchan 56
#define i7_V_I7S_Tab 57
#define i7_V_I7S_Col 58
#define i7_V_I7S_Dir 59
#define i7_V_I7S_Swap 60
#define i7_V_I7S_Comp 61
#define i7_V_MStack_Top 62
#define i7_V_MStack_Frame_Extent 63
#define i7_V_process_rulebook_count 64
#define i7_V_debugging_rules 65
#define i7_V_RawBufferAddress 66
#define i7_V_RawBufferSize 67
#define i7_V_TEXT_TY_CastPrimitiveNesting 68
#define i7_V_TEXT_TY_RE_Trace 69
#define i7_V_TEXT_TY_RE_RewindCount 70
#define i7_V_LIST_OF_TY_Sort_cf 71
#define i7_V_caps_mode 72
#define i7_V_short_name_case 73
#define i7_V_activities_sp 74
#define i7_V_inhibit_flag 75
#define i7_V_saved_debug_rules 76

/* (7) Function IDs */

#define i7_F_say_no_line_break____running_on xfn_i7_mgl_call_U119
#define i7_F_decide_which_real_number_is_the_real_square_of_X xfn_i7_mgl_call_U120
#define i7_F_decide_which_real_number_is_the_hyperbolic_arcsine_of_X xfn_i7_mgl_call_U121
#define i7_F_decide_which_real_number_is_the_hyperbolic_arccosine_of_X xfn_i7_mgl_call_U122
#define i7_F_decide_which_real_number_is_the_hyperbolic_arctangent_of_X xfn_i7_mgl_call_U123
#define i7_F_begin xfn_i7_mgl_call_U165
#define i7_F_run_the_collatz_algorithm_on_X xfn_i7_mgl_call_U166
i7word_t xfn_i7_mgl_call_U119(i7process_t *proc);
i7word_t xfn_i7_mgl_call_U120(i7process_t *proc, i7word_t p0);
i7word_t xfn_i7_mgl_call_U121(i7process_t *proc, i7word_t p0);
i7word_t xfn_i7_mgl_call_U122(i7process_t *proc, i7word_t p0);
i7word_t xfn_i7_mgl_call_U123(i7process_t *proc, i7word_t p0);
i7word_t xfn_i7_mgl_call_U165(i7process_t *proc);
i7word_t xfn_i7_mgl_call_U166(i7process_t *proc, i7word_t p0);
