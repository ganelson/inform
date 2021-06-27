[MappingHints::] Mapping Hint Requests.

Special sentences giving layout or design hints on how to produce the World map
in the index and an EPS map.

@h Parsing sentences which set map parameters.
This happens in two passes: pass 1 before HTML mapping, pass 2 before EPS mapping.

@e TRAVERSE_FOR_MAP1_SMFT

=
void MappingHints::traverse_for_map_parameters(void) {
	SyntaxTree::traverse(Task::syntax_tree(), MappingHints::look_for_map_parameters);
}

void MappingHints::look_for_map_parameters(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down)) {
		MajorNodes::try_special_meaning(TRAVERSE_FOR_MAP1_SMFT, p->down);
	}
}

@ =
parse_node *index_map_with_p = NULL;

int MappingHints::index_map_with_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Index map with ..." */
		case ACCEPT_SMFT:
			<np-articled-list>(OW);
			V->next = <<rp>>;
			return TRUE;
		case TRAVERSE_FOR_MAP1_SMFT:
			MappingHints::new_map_hint_sentence(V->next);
			break;
	}
	return FALSE;
}

@ This conveniently filters instance names to accept only those of kind
"direction".

=
<direction-name> ::=
	<instance-of-object>		==> { pass 1 }; if (Instances::of_kind(RP[1], K_direction) == FALSE) return FALSE;

@ The subject noun phrase of sentences like this:

>> Index map with Chamber mapped north of Cave and EPS file.

is an articled list of subjects (in this case, two of them); each subject
is parsed with the following grammar, which is almost a mini-language in
itself.

=
<index-map-sentence-subject> ::=
	eps file |                                       ==> { EPSFILE_IMW, - }
	<direction-name> mapped as <direction-name> |    ==> { MAPPED_AS_IMW, -, <<instance:x>> = RP[1], <<instance:y>> = RP[2] }
	... mapped as ... |                              ==> @<Issue PM_MapDirectionClue problem@>
	<instance-of-object> mapped <map-positioning> |  ==> { MAPPED_IMW, -, <<instance:x>> = RP[1], <<instance:y>> = RP[2] }
	... mapped ... |                                 ==> @<Issue PM_MapPlacement problem@>
	<map-setting> set to <map-setting-value> |       ==> { MappingHints::setting(R[1]), -, <<scoping>> = R[1], <<msvtype>> = R[2] }
	<map-setting> set to ... |                       ==> @<Issue PM_MapSettingTooLong problem@>
	... set to ... |                                 ==> @<Issue PM_MapSettingOfUnknown problem@>
	rubric {<quoted-text-without-subs>} *** |        ==> { RUBRIC_IMW, - }
	...                                              ==> @<Issue PM_MapHintUnknown problem@>

<map-positioning> ::=
	<instance-of-object> of/from <instance-of-object> |  ==> { TRUE, RP[2], <<instance:dir>> = RP[1] }
	above <instance-of-object> |                         ==> { TRUE, RP[1], <<instance:dir>> = I_up }
	below <instance-of-object>                           ==> { TRUE, RP[1], <<instance:dir>> = I_down }

@<Issue PM_MapDirectionClue problem@> =
	StandardProblems::map_problem(_p_(PM_MapDirectionClue),
		index_map_with_p, "You can only say 'Index map with D mapped as E.' "
		"when D and E are directions.");
	==> { NO_IMW, - };

@<Issue PM_MapPlacement problem@> =
	StandardProblems::map_problem(_p_(PM_MapPlacement),
		index_map_with_p, "The map placement hint should either have the form 'Index map with X "
		"mapped east of Y' or 'Index map with X mapped above/below Y'.");
	==> { NO_IMW, - };

@<Issue PM_MapSettingTooLong problem@> =
	StandardProblems::map_problem(_p_(PM_MapSettingTooLong),
		index_map_with_p, "The value supplied has to be a single item, a number, a word "
		"or some text in double-quotes: this looks too long to be right.");
	==> { NO_IMW, - };

@<Issue PM_MapSettingOfUnknown problem@> =
	@<Actually issue PM_MapSettingOfUnknown problem@>;
	==> { NO_IMW, - };

@<Issue PM_MapHintUnknown problem@> =
	StandardProblems::map_problem(_p_(PM_MapHintUnknown),
		index_map_with_p, "The general form for this is 'Index map with ...' and then a "
		"list of clues, such as 'the Ballroom mapped east of the Terrace', "
		"or 'room-size of the Ballroom set to 100'.");
	==> { NO_IMW, - };

@ =
int MappingHints::setting(int N) {
	if (N == NO_IMW) return N;
	return SETTING_IMW;
}

@ Now we parse the setting to be set. For example,

>> title-size of the first room
>> border-size of level 1
>> room-outline-thickness of the Taj Mahal
>> title-size

=
<map-setting> ::=
	<map-parameter> of <map-setting-scope> |  ==> { R[2], -, <<wchar_t:partext>> = RP[1], <<parindex>> = R[1] }
	<map-parameter> |                         ==> { ENTIRE_MAP_SCOPE, -, <<wchar_t:partext>> = RP[1], <<parindex>> = R[1] }
	... of <map-setting-scope>                ==> @<Issue PM_MapSettingUnknown problem@>

<map-setting-scope> ::=
	<definite-article> <map-setting-scope-unarticled> |  ==> { pass 2 }
	<map-setting-scope-unarticled>                       ==> { pass 1 }

<map-setting-scope-unarticled> ::=
	first room |               ==> { FIRST_ROOM_MAP_SCOPE, - }
	level <cardinal-number> |  ==> { LEVEL_MAP_SCOPE, -, <<level>> = R[1] }
	<k-kind> |                 ==> { KIND_MAP_SCOPE, -, <<kind:kscope>> = RP[1] }
	<instance-of-object>       ==> { INSTANCE_MAP_SCOPE, -, <<instance:iscope>> = RP[1] }

@ The map parameters all have one-word, sometimes hyphenated, names, such
as the following:

>> vertical-spacing, monochrome, annotation-size

For now, at least, these are all in English only.

=
<map-parameter> internal {
	int i;
	wchar_t *parameter_name = Lexer::word_text(Wordings::first_wn(W));
	if ((Wordings::length(W) == 1) &&
		((i = EPSMap::get_map_variable_index_from_wchar(parameter_name))>=0)) {
		==> { i, parameter_name };
		return TRUE;
	}
	==> { fail nonterminal };
}

@<Issue PM_MapSettingUnknown problem@> =
	StandardProblems::map_problem(_p_(PM_MapSettingUnknown),
		index_map_with_p, "The parameter has to be one of the fixed named set given in "
		"the documentation, like 'room-name'. All parameters are one "
		"word, but many are hyphenated. (Also, note that 'colour' has the "
		"Canadian/English spelling, not the American one 'color'.)");
	==> { NO_IMW, - };

@ The value of map settings is as follows. In retrospect, the "booleans"
perhaps should just have been "true" and "false", not "on" and "off".
Never mind.

=
<map-setting-value> ::=
	<cardinal-number> |      ==> { INT_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }
	<quoted-text> |          ==> { TEXT_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }
	<map-setting-boolean> |  ==> { BOOL_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }
	<map-offset> |           ==> { OFF_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }; if (R[1] == ERRONEOUS_OFFSET_VALUE) return FALSE;
	###                      ==> { -1, -, <<msword>> = Wordings::first_wn(W) } /* leads to a problem message later */

<map-setting-boolean> ::=
	on |                     ==> { TRUE, - }
	off                      ==> { FALSE, - }

@ Map offsets have a cutesy notation: |10&-30|, for example, written as a
single word. The following nonterminal actually matches any single word
(so that problems can be caught later, not now), returning either a valid
offset or else the |ERRONEOUS_OFFSET_VALUE| sentinel.

=
<map-offset> internal 1 {
	==> { MappingHints::parse_eps_map_offset(W), - };
	return TRUE;
}

@ The one part of the grammar not explicitly spelled out above was what to do
with the optional text which follows a rubric. This is a sequence of any of
the following:

=
<map-rubric> ::=
	size <cardinal-number> *** |               ==> { RUBRIC_SIZE, -, <<rsize>> = R[1], <<edge>> = Wordings::first_wn(WR[1]) }
	font {<quoted-text-without-subs>} *** |    ==> { RUBRIC_FONT, -, <<rfont>> = R[1], <<edge>> = Wordings::first_wn(WR[2]) }
	colour {<quoted-text-without-subs>} *** |  ==> { RUBRIC_COLOUR, -, <<rcol>> = R[1], <<edge>> = Wordings::first_wn(WR[2]) }
	at <map-offset> from ... |                 ==> { RUBRIC_OFFSET, -, <<roff>> = R[1], <<edge>> = Wordings::first_wn(WR[1]) }
	at <map-offset> ***                        ==> { RUBRIC_POSITION, -, <<roff>> = R[1], <<edge>> = Wordings::first_wn(WR[1]) }

@

@d NO_IMW 0
@d EPSFILE_IMW 1
@d MAPPED_AS_IMW 2
@d MAPPED_IMW 3
@d SETTING_IMW 4
@d RUBRIC_IMW 5

@d RUBRIC_SIZE 1
@d RUBRIC_FONT 2
@d RUBRIC_COLOUR 3
@d RUBRIC_OFFSET 4
@d RUBRIC_POSITION 5
@d FIRST_ROOM_MAP_SCOPE 1
@d LEVEL_MAP_SCOPE 2
@d KIND_MAP_SCOPE 3
@d INSTANCE_MAP_SCOPE 4
@d ENTIRE_MAP_SCOPE 5

=
void MappingHints::new_map_hint_sentence(parse_node *p) {
	if (Node::get_type(p) == AND_NT) {
		MappingHints::new_map_hint_sentence(p->down);
		MappingHints::new_map_hint_sentence(p->down->next);
		return;
	}
	current_sentence = p;
	index_map_with_p = p;

	<index-map-sentence-subject>(Node::get_text(p));
	switch (<<r>>) {
		case EPSFILE_IMW: write_EPS_format_map = TRUE;
			break;
		case MAPPED_AS_IMW: @<Parse "Index map with starboard mapped as east"-style sentences@>;
			break;
		case MAPPED_IMW: @<Parse "Index map with Ballroom mapped north of the Hallway"-style sentences@>;
			break;
		case SETTING_IMW: @<Parse "Index map with room size of Ballroom set to 72"-style sentences@>;
			break;
		case RUBRIC_IMW:
			@<Parse "Index map with rubric "Here Be Dragons""-style sentences@>;
			break;
	}
}

@<Parse "Index map with starboard mapped as east"-style sentences@> =
	MappingHints::map_direction_as_if(<<instance:x>>, <<instance:y>>);

@<Parse "Index map with Ballroom mapped north of the Hallway"-style sentences@> =
	if (Instances::of_kind(<<instance:dir>>, K_direction) == FALSE) {
		StandardProblems::map_problem(_p_(PM_MapPlacementDirection),
			p, "The direction given as a hint for map placement wasn't "
			"one that I know of.");
		return;
	}

	instance *I = <<instance:x>>;
	instance *I2 = <<instance:y>>;
	instance *exit = <<instance:dir>>;

	if ((I == NULL) || (Spatial::object_is_a_room(I) == FALSE)) {
		StandardProblems::map_problem(_p_(PM_MapFromNonRoom),
			p, "The first-named thing must be a room (beware ambiguities!).");
		return;
	}
	if ((I2 == NULL) || (Spatial::object_is_a_room(I2) == FALSE)) {
		StandardProblems::map_problem(_p_(PM_MapToNonRoom),
			p, "The second-named thing must be a room (beware ambiguities!).");
		return;
	}
	if (PL::SpatialMap::direction_is_lateral(MAP_DATA(exit)->direction_index) == FALSE) {
		StandardProblems::map_problem(_p_(PM_MapNonLateral),
			p, "The direction given as a hint for map placement must be "
			"a lateral direction (not up, down, above, below, inside "
			"or outside).");
		return;
	}
	MappingHints::map_next_to(I, exit, I2);

@<Parse "Index map with rubric "Here Be Dragons""-style sentences@> =
	wording RW = GET_RW(<index-map-sentence-subject>, 1);
	wording RESTW = GET_RW(<index-map-sentence-subject>, 2);
	Word::dequote(Wordings::first_wn(RW));
	wchar_t *annotation =  Lexer::word_text(Wordings::first_wn(RW));
	int point_size = 12; /* 12-point type */
	wchar_t *font = L"<font>"; /* meaning the default font */
	wchar_t *colour = L"000000"; /* black */
	int at_offset = 10001; /* the offset $(1, 1)$ */
	instance *offset_from = NULL;
	int i = Wordings::first_wn(RESTW);
	while (i <= Wordings::last_wn(RESTW)) {
		if (<map-rubric>(Wordings::from(RESTW, i))) {
			i = <<edge>>;
			switch (<<r>>) {
				case RUBRIC_SIZE:
					point_size = <<rsize>>;
					break;
				case RUBRIC_FONT:
					Word::dequote(<<rfont>>);
					font = Lexer::word_text(<<rfont>>);
					break;
				case RUBRIC_COLOUR:
					@<Make a rubric colour setting@>; break;
				case RUBRIC_OFFSET:
				case RUBRIC_POSITION:
					@<Make a rubric offset setting@>; break;
			}
		} else {
			StandardProblems::map_problem(_p_(PM_MapBadRubric),
				p, "Unfortunately the details of that rubric seem to be "
				"in error (a lame message, but an accurate one).");
			break;
		}
	}
	MappingHints::make_rubric(annotation, point_size, font, colour, at_offset, offset_from);

@<Make a rubric colour setting@> =
	Word::dequote(<<rcol>>);
	wchar_t *thec = HTML::translate_colour_name(Lexer::word_text(<<rcol>>));
	if (thec == NULL) {
		StandardProblems::map_problem(_p_(PM_MapUnknownColour), p, "There's no such map colour.");
		return;
	}
	colour = thec;

@<Make a rubric offset setting@> =
	if (<<roff>> == ERRONEOUS_OFFSET_VALUE) {
		StandardProblems::map_problem(_p_(PM_MapUnknownOffset), p, "There's no such offset.");
		return;
	}
	at_offset = <<roff>>;

	if (<<r>> == RUBRIC_OFFSET) {
		wording RW = Wordings::from(Node::get_text(p), i);
		instance *I = NULL;
		if (<instance-of-object>(RW)) I = <<rp>>;
		i = Wordings::last_wn(RESTW) + 1;
		if (I == NULL) {
			StandardProblems::map_problem(_p_(PM_MapUnknownOffsetBase),
				p, "There's no such room to be offset from.");
			return;
		}
		offset_from = I;
	}

@ Finally, then, sentences which set parameters for the EPS map-maker.

@<Parse "Index map with room size of Ballroom set to 72"-style sentences@> =
	int scope_level = 1000000;
	instance *scope_I = NULL;
	kind *scope_k = NULL;
	@<Determine the scope for which the parameter is being set@>;
	wchar_t *parameter_name = <<wchar_t:partext>>;
	int index_of_parameter = <<parindex>>;
	@<Check that the value has the right type for this map parameter, and set it@>;

@<Determine the scope for which the parameter is being set@> =
	int bad_scope = FALSE;
	switch (<<scoping>>) {
		case FIRST_ROOM_MAP_SCOPE: {
			instance *first = Spatial::get_benchmark_room();
			if (first) scope_I = first;
			break;
		}
		case LEVEL_MAP_SCOPE:
			scope_level = <<level>>;
			break;
		case KIND_MAP_SCOPE:
			scope_k = <<kind:kscope>>;
			if (Kinds::Behaviour::is_subkind_of_object(scope_k) == FALSE) scope_k = NULL;
			if ((scope_k) &&
				((Kinds::Behaviour::is_object_of_kind(scope_k, K_room)) ||
					(Kinds::Behaviour::is_object_of_kind(scope_k, K_region)))) {
				LOGIF(SPATIAL_MAP, "Setting for kind %u\n", scope_k);
			} else bad_scope = TRUE;
			break;
		case INSTANCE_MAP_SCOPE:
			if ((Spatial::object_is_a_room(<<instance:iscope>>)) ||
				(Regions::object_is_a_region(<<instance:iscope>>)))
				scope_I = <<instance:iscope>>;
			if (scope_I) {
				LOGIF(SPATIAL_MAP, "Setting for object $O\n", scope_I);
			} else bad_scope = TRUE;
			break;
		case ENTIRE_MAP_SCOPE:
			scope_k = K_room;
			break;
	}

	if (bad_scope) {
		@<Actually issue PM_MapSettingOfUnknown problem@>;
		return;
	}

@<Actually issue PM_MapSettingOfUnknown problem@> =
	StandardProblems::map_problem(_p_(PM_MapSettingOfUnknown),
		index_map_with_p, "The parameter has to be 'of' either 'the first room' "
		"or a specific named room (beware ambiguities!) or "
		"a level such as 'level 0' (the first room is by "
		"definition on level 0), or a region, or a kind of room.");

@<Check that the value has the right type for this map parameter, and set it@> =
	int type_wanted = EPSMap::global()->values[index_of_parameter].parameter_data_type;
	int type_found = <<msvtype>>;
	char *i_wanted_a = "";
	int wn = <<msword>>;
	switch(type_wanted) {
		case INT_MDT: i_wanted_a = "an integer";
			if (type_found == INT_MDT) {
				MappingHints::put_mp(parameter_name, scope_level, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case OFF_MDT: i_wanted_a = "an offset in the form 34&-450";
			if (type_found == OFF_MDT) {
				MappingHints::put_mp(parameter_name, scope_level, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case BOOL_MDT: i_wanted_a = "'on' or 'off'";
			if (type_found == BOOL_MDT) {
				MappingHints::put_mp(parameter_name, scope_level, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case TEXT_MDT: i_wanted_a = "some text in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				MappingHints::put_mp(parameter_name, scope_level, scope_I, scope_k, Lexer::word_text(wn), 0);
				return;
			}
			break;
		case FONT_MDT: i_wanted_a = "a font name in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				MappingHints::put_mp(parameter_name, scope_level, scope_I, scope_k, Lexer::word_text(wn), 0);
				return;
			}
			break;
		case COL_MDT: i_wanted_a = "a colour name in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				wchar_t *col = HTML::translate_colour_name(Lexer::word_text(wn));
				if (col) {
					MappingHints::put_mp(parameter_name, scope_level, scope_I, scope_k, col, 0);
					return;
				}
			}
			break;
		default: internal_error("Unexpected map parameter data type");
	}
	StandardProblems::map_problem_wanted_but(_p_(PM_MapSettingTypeFailed),
		p, i_wanted_a, wn);

@ 

=
typedef struct mapping_hint {
	struct instance *from;
	struct instance *to;
	struct instance *dir;
	struct instance *as_dir;
	
	wchar_t *name;
	int scope_level;
	struct instance *scope_I;
	wchar_t *put_string;
	int put_integer;

	wchar_t *annotation;
	int point_size;
	wchar_t *font;
	wchar_t *colour;
	int at_offset;
	struct instance *offset_from;
	
	CLASS_DEFINITION
} mapping_hint;

mapping_hint *MappingHints::new_hint(void) {
	mapping_hint *hint = CREATE(mapping_hint);
	hint->from = NULL;
	hint->to = NULL;
	hint->dir = NULL;
	hint->as_dir = NULL;
	hint->name = NULL;
	hint->scope_level = 1000000;
	hint->scope_I = NULL;
	hint->put_string = NULL;
	hint->put_integer = 0;

	hint->annotation = NULL;
	hint->point_size = 0;
	hint->font = NULL;
	hint->colour = NULL;
	hint->at_offset = 0;
	hint->offset_from = NULL;

	return hint;
}

void MappingHints::map_direction_as_if(instance *I, instance *I2) {
	mapping_hint *hint = MappingHints::new_hint();
	hint->dir = I; hint->as_dir = I2;
}

void MappingHints::map_next_to(instance *I, instance *exit, instance *I2) {
	mapping_hint *hint = MappingHints::new_hint();
	hint->dir = exit; hint->from = I; hint->to = I2;
}

int MappingHints::obj_in_region(instance *I, instance *reg) {
	if ((I == NULL) || (reg == NULL)) return FALSE;
	if (Regions::enclosing(I) == reg) return TRUE;
	return MappingHints::obj_in_region(Regions::enclosing(I), reg);
}

void MappingHints::put_mp(wchar_t *name, int scope_level, instance *scope_I,
	kind *scope_k, wchar_t *put_string, int put_integer) {
	if (scope_I) {
		if (Regions::object_is_a_region(scope_I)) {
			instance *rm;
			LOOP_OVER_INSTANCES(rm, K_room)
				if (MappingHints::obj_in_region(rm, scope_I))
					MappingHints::put_mp(name, scope_level, rm, NULL, put_string, put_integer);
			return;
		}
		if (Spatial::object_is_a_room(scope_I) == FALSE) return;
	}
	if (scope_k) {
		instance *I;
		LOOP_OVER_INSTANCES(I, scope_k)
			MappingHints::put_mp(name, scope_level, I, NULL, put_string, put_integer);
		return;
	}

	mapping_hint *hint = MappingHints::new_hint();
	hint->name = name;
	hint->scope_level = scope_level;
	hint->scope_I = scope_I;
	hint->put_string = put_string;
	hint->put_integer = put_integer;
}

void MappingHints::make_rubric(wchar_t *annotation, int point_size, wchar_t *font,
	wchar_t *colour, int at_offset, instance *offset_from) {
	mapping_hint *hint = MappingHints::new_hint();
	hint->annotation = annotation;
	hint->point_size = point_size;
	hint->font = font;
	hint->colour = colour;
	hint->at_offset = at_offset;
	hint->offset_from = offset_from;
}

@h Offset notation.
The offset parameter $(x, y)$ is stored as the integer $10000y + x$. Except
for the error value, we are required to have $-9999 \leq x, y \leq 9999$, and
the syntax to specify this is two literal numbers divided by an ampersand.
For instance, |28&-125| means $(28, -125)$ which is stored as $-1249972$.

@d ERRONEOUS_OFFSET_VALUE 100000000

=
int MappingHints::parse_eps_map_offset(wording W) {
	TEMPORARY_TEXT(offs)
	WRITE_TO(offs, "%W", Wordings::one_word(Wordings::first_wn(W)));
	if (Str::len(offs) >= 30) return ERRONEOUS_OFFSET_VALUE;
	match_results mr = Regexp::create_mr();
	int xbit = 0, ybit = 0;
	if (Regexp::match(&mr, offs, L"(%c*?)&(%c*)")) {
		xbit = Str::atoi(mr.exp[0], 0), ybit = Str::atoi(mr.exp[1], 0);
		Regexp::dispose_of(&mr);
	} else return ERRONEOUS_OFFSET_VALUE;
	DISCARD_TEXT(offs)
	return xbit + ybit*10000;
}
