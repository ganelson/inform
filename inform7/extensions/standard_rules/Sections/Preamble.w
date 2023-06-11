Preamble.

The titling line and rubric, use options and a few other preliminaries before
the Standard Rules get properly started.

@h Title.
Every Inform 7 extension begins with a standard titling line and a
rubric text, and the Standard Rules are no exception:

=
Version [[Version Number]] of the Standard Rules by Graham Nelson begins here.

"The Standard Rules, included in every project, define phrases, actions and
activities for interactive fiction."

Part One - Preamble

@h Verbs.
This continues the built-in verbs (i.e. those with meaning built in to the
Inform compiler), adding those which are relevant only to IF.

Note the plus notation, added in May 2016, which marks for a second object
phrase, and is thus only useful for built-in meanings.

=
The verb to begin when means the built-in scene-begins-when meaning.
The verb to end when means the built-in scene-ends-when meaning.
The verb to end + when means the built-in scene-ends-when meaning.

@ Verbs used as imperatives: "Understand ... as ...", for example.

=
The verb to understand + as in the imperative means the built-in understand-as meaning.
The verb to release along with in the imperative means the built-in release-along-with meaning.
The verb to index map with in the imperative means the built-in index-map-with meaning.

@h Use Options.
Three sets of overlapping options. In each case, the first given is the default
value, and any attempt to set contradictory values throws a problem.

=
Use full-length room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 2 in WorldModelKit.
Use abbreviated room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 3 in WorldModelKit.
Use VERBOSE room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 2 in WorldModelKit.
Use BRIEF room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 1 in WorldModelKit.
Use SUPERBRIEF room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 3 in WorldModelKit.

Use no scoring translates as the configuration value
	SCORING = 0 in WorldModelKit.
Use scoring translates as the configuration value
	SCORING = 1 in WorldModelKit.

Use default route-finding translates as the configuration value
	ROUTE_FINDING = 0 in WorldModelKit.
Use fast route-finding translates as the configuration value
	ROUTE_FINDING = 1 in WorldModelKit.
Use slow route-finding translates as the configuration value
	ROUTE_FINDING = 2 in WorldModelKit.

@ This setting is to do with the command parser's handling of multiple objects.
Essentially it means that "take all" can pick up at most 100 items. The setting
"belongs" to WorldModelKit, not CommandParserKit, because it affects actions
as well as their parsing from text.

=
Use maximum things understood at once of at least 100 translates as the
	configuration value MULTI_OBJ_LIST_SIZE in WorldModelKit.

@ These are more straightforwardly ways to configure the command parser:

=
Use manual pronouns translates as the configuration flag
	MANUAL_PRONOUNS in CommandParserKit.
Use undo prevention translates as the configuration flag
	UNDO_PREVENTION in CommandParserKit.
Use unabbreviated object names translates as the configuration flag
	UNABBREVIATED_NAMES in CommandParserKit.
