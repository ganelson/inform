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
In fact, many of the definitions below are handled slightly differently in
the |srules| template files, to avoid the need for conditional compilation
(and thus to enable the template to be assimilated just once); but we
continue to give them the traditional constant names, for the sake of any
third-party extensions using these.

=
Use command line echoing translates as (- Constant ECHO_COMMANDS; -).
Use full-length room descriptions translates as (- #IFNDEF I7_LOOKMODE; Constant I7_LOOKMODE = 2; #ENDIF; -).
Use abbreviated room descriptions translates as (- #IFNDEF I7_LOOKMODE; Constant I7_LOOKMODE = 3; #ENDIF; -).
Use scoring translates as (- #IFNDEF USE_SCORING; Constant USE_SCORING = 1; #ENDIF; -).
Use no scoring translates as (- #IFNDEF USE_SCORING; Constant USE_SCORING = 0; #ENDIF; -).
Use manual pronouns translates as (- Constant MANUAL_PRONOUNS; -).
Use undo prevention translates as (- Constant PREVENT_UNDO; -).
Use VERBOSE room descriptions translates as (- Constant DEFAULT_VERBOSE_DESCRIPTIONS; -).
Use BRIEF room descriptions translates as (- Constant DEFAULT_BRIEF_DESCRIPTIONS; -).
Use SUPERBRIEF room descriptions translates as (- Constant DEFAULT_SUPERBRIEF_DESCRIPTIONS; -).

@ This setting is to do with the command parser's handling of multiple objects.
Essentially it means that "take all" can pick up at most 100 items.

=
Use maximum things understood at once of at least 100 translates as
	(- Constant MATCH_LIST_WORDS = {N}; -).
Use maximum things understood at once of at least 100.
