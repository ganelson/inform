Preamble.

Basic Inform is like a boot program for a computer that is starting up: it
sets up the compiler to implement the familiar language, beginning with
basic verbs and use options.

@h Title.
Every Inform 7 extension begins with a standard titling line and a
rubric text, and this is no exception:

=
Version [[Version Number]] of Basic Inform by Graham Nelson begins here.

"Basic Inform, included in every project, defines the basic framework
of Inform as a programming language."

Part One - Preamble

@h Verbs.
The first task is to create the verbs which enable us to do everything
else. The first sentence should really read "The verb to mean means the
built-in verb-means meaning", but that would be circular. So Inform
starts with two verbs built in, "to mean" and "to be", with "to mean"
having the built-in "verb-means meaning", and "to be" initially having
no meaning at all.

=
The verb to mean means the meaning relation.

The verb to be means the built-in new-verb meaning.
The verb to be means the built-in new-plural meaning.
The verb to be means the built-in new-activity meaning.
The verb to be means the built-in new-action meaning.
The verb to be means the built-in new-adjective meaning.
The verb to be means the built-in new-either-or meaning.
The verb to be means the built-in accessible-to-inter meaning.
The verb to be means the built-in defined-by-inter meaning.
The verb to be means the built-in defined-by-table meaning.
The verb to be means the built-in rule-listed-in meaning.
The verb to be means the built-in new-figure meaning.
The verb to be means the built-in new-sound meaning.
The verb to be means the built-in new-file meaning.
The verb to be means the built-in episode meaning.
The verb to be means the built-in declares-licence meaning.
The verb to be means the equality relation.

@ We allow "imply" as a synonym for "mean".

=
The verb to imply means the built-in verb-means meaning.
The verb to imply means the meaning relation.

@ And now miscellaneous other important verbs. Note the plus notation, new
in May 2016, which marks for a second object phrase, and is thus only
useful for built-in meanings.

=
The verb to be able to be means the built-in can-be meaning.

The verb to have means the possession relation.

The verb to specify means the built-in specifies-notation meaning.

The verb to relate means the built-in new-relation meaning.
The verb to relate means the universal relation.

The verb to substitute for means the built-in rule-substitutes-for meaning.

The verb to do means the built-in rule-does-nothing meaning.
The verb to do + if means the built-in rule-does-nothing-if meaning.
The verb to do + when means the built-in rule-does-nothing-if meaning.
The verb to do + unless means the built-in rule-does-nothing-unless meaning.

The verb to translate into + as means the built-in translates-into-unicode meaning.
The verb to translate into + as means the built-in translates-into-i6 meaning.
The verb to translate into + as means the built-in translates-into-language meaning.

The verb to translate as means the built-in use-translates meaning.

The verb to provide means the provision relation.

@ Next, the verbs used as imperatives:

=
The verb to use in the imperative means the built-in use meaning.
The verb to include + in in the imperative means the built-in include-in meaning.
The verb to omit + from in the imperative means the built-in omit-from meaning.
The verb to test + with in the imperative means the built-in test-with meaning.

@ We might as well declare these numerical comparisons now, too, though
they're not needed for any of the world-building work.

=
The verb to be greater than means the numerically-greater-than relation.
The verb to be less than means the numerically-less-than relation.
The verb to be at least means the numerically-greater-than-or-equal-to relation.
The verb to be at most means the numerically-less-than-or-equal-to relation.

@ And these have symbolic equivalents as operators, declared using the
following syntax. Operators are unlike other verbs in that they have no
inflected forms and exist only in the present tense.

=
The operator > means the numerically-greater-than relation.
The operator < means the numerically-less-than relation.
The operator >= means the numerically-greater-than-or-equal-to relation.
The operator <= means the numerically-less-than-or-equal-to relation.

@h Use Options.
The following has no effect, and exists only to be a default non-value for
"use option" variables, should anyone ever create them:

=
Use ineffectual translates as a compiler feature.

@ We can now make definitions of miscellaneous options: none are used by default,
but all translate into I6 constant definitions if used. (These are constants
whose values are used in the I6 library or in the template layer, which is
how they have effect.)

=
Use American dialect translates as the configuration flag AMERICAN_DIALECT
	in BasicInformKit.
Use the serial comma translates as the configuration flag SERIAL_COMMA
	in BasicInformKit.
Use memory economy translates as the configuration flag MEMORY_ECONOMY
	in BasicInformKit.
Use engineering notation translates as a compiler feature.
Use printed engineering notation translates as the configuration flag
	PRINT_ENGINEER_EXPS in BasicInformKit.
Use predictable randomisation translates as the configuration flag FIX_RNG
	in BasicInformKit.
Use numbered rules translates as the configuration flag NUMBERED_RULES
	in BasicInformKit.
Use no deprecated features translates as the configuration flag NO_DEPRECATED
	in BasicInformKit.
Use authorial modesty translates as the configuration flag AUTHORIAL_MODESTY
	in BasicInformKit.
Use command line echoing translates as the configuration flag ECHO_COMMANDS
	in BasicInformKit.
Use dictionary resolution of at least 6 translates as the configuration value
	DICT_RESOLUTION in BasicInformKit.
Use no automatic plural synonyms translates as the configuration flag
	NO_AUTO_PLURAL_NAMES in BasicInformKit.

@ These, on the other hand, are settings used by the dynamic memory management
code, which runs in I6 as part of the template layer. Each setting translates
to an I6 constant declaration, with the value chosen being substituted for
|{N}|.

The "dynamic memory allocation" defined here is slightly misleading, in
that the memory is only actually consumed in the event that any of the
kinds needing to use the heap is actually employed in the source
text being compiled. (8192 bytes may not sound much these days, but in the
tight array space of the Z-machine it's quite a large commitment, and we
want to avoid it whenever possible.)

=
Use dynamic memory allocation of at least 8192 translates as the configuration
	value STACK_FRAME_CAPACITY in BasicInformKit.
Use maximum text length of at least 1024 translates as the configuration
	value TEXT_BUFFER_SIZE in BasicInformKit.
Use index figure thumbnails of at least 50 translates as a compiler feature.

Use dynamic memory allocation of at least 8192.

@ At one point many maxima were set via Inform 6 compiler options, but those
became redundant with v6.36 of the I6 compiler, and we now require at least
v6.42 anyway for other reasons; so those settings have now been removed.

What remains is the maximum stack capacity on the Glulx virtual machine.
I6 currently sets this by default to 4096, which the I6 source code says is
"about enough for 90 nested function calls with 8 locals each". I7 by
default asks 16 times that, and even then this is a use option, so that it
can be raised by users if necessary.

=
Use Inform 6 compiler option "$MAX_STACK_SIZE=65536".
