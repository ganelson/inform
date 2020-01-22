Preamble.

The titling line and rubric, use options and a few other
technicalities before the Standard Rules get properly started.

@h Title.
Every Inform 7 extension begins with a standard titling line and a
rubric text, and the Standard Rules are no exception:

=
Version [[Version Number]] of the Standard Rules by Graham Nelson begins here.

"The Standard Rules, included in every project, define the basic framework
of kinds, actions and phrases which make Inform what it is."

@h Verbs.
And now miscellaneous other important verbs. Note the plus notation, new
in May 2016, which marks for a second object phrase, and is thus only
useful for built-in meanings.

=
The verb to begin when means the built-in scene-begins-when meaning.
The verb to end when means the built-in scene-ends-when meaning.
The verb to end + when means the built-in scene-ends-when meaning.

@ Verbs used as imperatives: "Test ... with ...", for example.

=
The verb to test + with in the imperative means the built-in test-with meaning.
The verb to understand + as in the imperative means the built-in understand-as meaning.
The verb to release along with in the imperative means the built-in release-along-with meaning.
The verb to index map with in the imperative means the built-in index-map-with meaning.

@ We can now make definitions of miscellaneous options: none are used by default,
but all translate into I6 constant definitions if used. (These are constants
whose values are used in the I6 library or in the template layer, which is
how they have effect.)

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

@ This setting is to do with the Inform parser's handling of multiple objects.

=
Use maximum things understood at once of at least 100 translates as
	(- Constant MATCH_LIST_WORDS = {N}; -).

Use maximum things understood at once of at least 100.

@ That's it for the verbs with special internal meanings.

=
The verb to provide means the provision relation.
