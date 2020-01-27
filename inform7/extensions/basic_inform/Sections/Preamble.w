Preamble.

Basic Inform is like a boot program for a computer that is starting up: it
sets up the compiler to implement the familiar language, beginning with
basic verbs and use options.

@h Title.
Every Inform 7 extension begins with a standard titling line and a
rubric text, and this are no exception:

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
no meaning at all. (We need "to be" because this enables us to conjugate
forms of "mean" such as "X is meant by": note the "is".)

So we actually start by defining the copular verb "to be". This has a
dozen special meanings, all valid only in assertion sentences, as well
as its regular one.

=
The verb to be means the built-in new-verb meaning.
The verb to be means the built-in new-plural meaning.
The verb to be means the built-in new-activity meaning.
The verb to be means the built-in new-action meaning.
The verb to be means the built-in new-adjective meaning.
The verb to be means the built-in new-either-or meaning.
The verb to be means the built-in defined-by-table meaning.
The verb to be means the built-in rule-listed-in meaning.
The verb to be means the built-in new-figure meaning.
The verb to be means the built-in new-sound meaning.
The verb to be means the built-in new-file meaning.
The verb to be means the built-in episode meaning.
The verb to be means the equality relation.

@ Unfinished business: the other meaning of "mean", and "imply" as
a synonym for it.

=
The verb to mean means the meaning relation.

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

@ We might as well declare these numerical comparisons now, too, though
they're not needed for any of the world-building work. (The verbal usages |<|,
|>|, |<=| and |>=| are built into Inform; those would be the same in any
language, and are unlike other verbs since they have no inflected forms for
non-present tenses.)

=
The verb to be greater than means the numerically-greater-than relation.
The verb to be less than means the numerically-less-than relation.
The verb to be at least means the numerically-greater-than-or-equal-to relation.
The verb to be at most means the numerically-less-than-or-equal-to relation.

@h Use Options.
The following has no effect, and exists only to be a default non-value for
"use option" variables, should anyone ever create them:

=
Use ineffectual translates as (- ! Use ineffectual does nothing. -).

@ We can now make definitions of miscellaneous options: none are used by default,
but all translate into I6 constant definitions if used. (These are constants
whose values are used in the I6 library or in the template layer, which is
how they have effect.)

=
Use American dialect translates as (- Constant DIALECT_US; -).
Use the serial comma translates as (- Constant SERIAL_COMMA; -).
Use memory economy translates as (- Constant MEMORY_ECONOMY; -).
Use engineering notation translates as (- Constant USE_E_NOTATION = 0; -).
Use unabbreviated object names translates as (- Constant UNABBREVIATED_OBJECT_NAMES = 0; -).
Use predictable randomisation translates as (- Constant FIX_RNG; -).
Use fast route-finding translates as (- Constant FAST_ROUTE_FINDING; -).
Use slow route-finding translates as (- Constant SLOW_ROUTE_FINDING; -).
Use numbered rules translates as (- Constant NUMBERED_RULES; -).
Use telemetry recordings translates as (- Constant TELEMETRY_ON; -).
Use no deprecated features translates as (- Constant NO_DEPRECATED_FEATURES; -).
Use gn testing version translates as (- Constant GN_TESTING_VERSION; -).
Use authorial modesty translates as (- Constant AUTHORIAL_MODESTY; -).

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
Use dynamic memory allocation of at least 8192 translates as
	(- Constant DynamicMemoryAllocation = {N}; -).
Use maximum text length of at least 1024 translates as
	(- Constant TEXT_TY_BufferSize = {N}+3; -).
Use index figure thumbnails of at least 50 translates as
	(- Constant MAX_FIGURE_THUMBNAILS_IN_INDEX = {N}; -).

Use dynamic memory allocation of at least 8192.

@ Some Inform 7 projects are rather heavy-duty by the expectations of the
Inform 6 compiler (which it uses as a code-generator): I6 was written fifteen
years earlier, when computers were unimaginably smaller and slower. So many
of its default memory settings need to be raised to higher maxima.

Note that the Z-machine cannot accommodate more than 255 verbs, so this is
the highest |MAX_VERBS| setting we can safely make here.

The |MAX_LOCAL_VARIABLES| setting is suppressed by I7 if we're compiling
to the Z-machine, because it's only legal in I6 when compiling to Glulx.

=
Use ALLOC_CHUNK_SIZE of 32000.
Use MAX_ARRAYS of 10000.
Use MAX_CLASSES of 200.
Use MAX_VERBS of 255.
Use MAX_LABELS of 10000.
Use MAX_ZCODE_SIZE of 500000.
Use MAX_STATIC_DATA of 180000.
Use MAX_PROP_TABLE_SIZE of 200000.
Use MAX_INDIV_PROP_TABLE_SIZE of 20000.
Use MAX_STACK_SIZE of 65536.
Use MAX_SYMBOLS of 20000.
Use MAX_EXPRESSION_NODES of 256.
Use MAX_LABELS of 200000.
Use MAX_LOCAL_VARIABLES of 256.
