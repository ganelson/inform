Miscellaneous Definitions.

A miscellany of properties, variables, rulebooks and activities. Whereas the
Standard Rules for interactive fiction are luxuriant in providing these, the
Basic Inform kernel is as small as it sensibly can be, with just a few of each.

@ =
Part Two - Miscellaneous Definitions

@h Properties.
The following declaration is misleading, since Inform doesn't read it
literally. "Variable initial value" is in fact the only property common
to global variables, a behind-the-scenes convenience. It's not visible
or useful in regular coding, and doesn't belong to objects.

=
An object has a value called variable initial value.

@ Objects do, however, have a wealth of properties to do with their naming.
"Specification" is special: it isn't compiled, but holds text used to
annotate the Kinds index. "Indefinite appearance text" is also an internal
property (it holds the text sometimes given in double-quotes immediately
after an object is created).

=
An object has a text called specification.
An object has a text called indefinite appearance text.
An object has a text called printed name.
An object has a text called printed plural name.
An object has a text called an indefinite article.
An object can be plural-named or singular-named. An object is usually singular-named.
An object can be proper-named or improper-named. An object is usually improper-named.
An object can be ambiguously plural.

@ These are Inter identifier names.

=
The indefinite article property is defined by Inter as "article".
The printed plural name property is defined by Inter as "plural".
The printed name property is defined by Inter as "short_name".
The plural-named property is defined by Inter as "pluralname".
The ambiguously plural property is defined by Inter as "ambigpluralname".
The proper-named property is defined by Inter as "proper".

@h Variables.
Most of the built-in kinds and kind constructors, such as "number" and
"list of K", are defined in special low-level files read in by Inform early
in its run -- not here. "Natural language" is an exception.

"Language of play" should no longer be taken to imply play; it's really the
natural language of our output text, if any. It affects how verbs conjugate,
and what "say N in words" does, for example.

=
A natural language is a kind of value.
The language of play is a natural language that varies.

@ The "parameter-object" is, as its hyphenated name suggests, an internal
implementation convenience. When a rulebook runs on a given value, it holds
that value. It is really an alias, not a fixed variable, and has whatever
kind is appropriate to the rulebook currently running. (In particular,
despite the definition below, it is not necessarily an object.)

=
The parameter-object is an object that varies.
The parameter-object variable is defined by Inter as "parameter_value".

@h Rulebooks.
The Standard Rules (for interactive fiction) create a wealth of rulebooks
and activities in order to model a fictional world. Here we are much more
sparing: a Basic Inform project begins with a very minimal number of rules.

The startup and shutdown rulebooks, and the "starting the virtual machine"
activity, are not normally used in Basic Inform, but need to be defined here
for technical reasons.

Be wary modifying these: rulebooks and activities must be defined in exactly
the right order, matching definitions both in the Inform 7 compiler and in the
template libraries. (Remember that creating an activity creates three rulebooks.)

These rules here are the ones which get the basic machinery working
to the point where it is safe to run arbitrary I7 source text. They necessarily
do very low-level things, and it is not guaranteed that I7 phrases will behave
to specification if executed before these early rules have finished. So it
is hazardous to obstruct or alter them.

(a) The "virtual machine startup rule" carries out necessary steps to
begin execution on the virtual machine in use: this entails relatively little
on the Z-machine versions 5 or 8, but can involve extensive work to get the
screen display working on Glulx or Z6.

(b) The "initialise memory rule" starts up the memory allocation heap,
if there is one, and sets some essential I6 variables. If there is any rule
not to meddle with, this is it.

(c) The "seed random number generator rule" seeds the RNG to a fixed value
if Inform has requested this (which it does in response to the |-rng| command
line switch, which is in turn used by the |intest| testing utility: it's a
way to make deterministic tests of programs which use random values).

(d) The "recover Glk objects rule" runs the object recovery process in order to
identify and pre-existing Glk objects after a restart.

(e) The "open built-in windows rule" opens the Glk windows; only after this
point is it safe to print anything.

=
Chapter - Startup

Startup rules is a rulebook.
The startup rulebook is accessible to Inter as "STARTUP_RB".
Startup rules have outcomes allow startup (success) and deny startup (failure).

Shutdown rules is a rulebook.
The shutdown rulebook is accessible to Inter as "SHUTDOWN_RB".

[Starting the virtual machine (documented at act_startvm) is an activity on nothing.]
Starting the virtual machine is an activity on nothing.
The starting the virtual machine activity is accessible to Inter as "STARTING_VIRTUAL_MACHINE_ACT".
The for starting the virtual machine rules have default no outcome.

First startup rule (this is the virtual machine startup rule):
	carry out the starting the virtual machine activity.

Section - Startup A (for Glulx only)

The start capturing startup text rule is listed in the before starting the virtual machine rules.
The start capturing startup text rule translates into Inter as "CAPTURE_STARTUP_TEXT_R".

The enable Glulx acceleration rule is listed in the before starting the virtual machine rules.
The enable Glulx acceleration rule translates into Inter as "FINAL_CODE_STARTUP_R".

Section - Startup B

The initialise memory rule is listed in the before starting the virtual machine rules.
The initialise memory rule translates into Inter as "INITIALISE_MEMORY_R".

The seed random number generator rule is listed in the before starting the virtual machine rules.
The seed random number generator rule translates into Inter as "SEED_RANDOM_NUMBER_GENERATOR_R".

Section - Startup C (for Z-Machine only)

The final code startup rule is listed in the for starting the virtual machine rules.
The final code startup rule translates into Inter  as "FINAL_CODE_STARTUP_R".

Section - Startup D (for Glulx only)

The recover Glk objects rule is listed in the before starting the virtual machine rules.
The recover Glk objects rule translates into Inter as "GGRecoverObjects".

@ These rules now set up the built in sound channels and windows.

=
The sound channel initialisation rule is listed in the for starting the virtual machine rules.
The sound channel initialisation rule translates into Inter as "SOUND_CHANNEL_INIT_R".

The open built-in windows rule is listed in the for starting the virtual machine rules.
The open built-in windows rule translates into Inter as "OPEN_BUILT_IN_WINDOWS_R".

The display captured startup text rule is listed in the for starting the virtual machine rules.
The display captured startup text rule translates into Inter as "END_CAPTURE_STARTUP_TEXT_R".

@ However, the two activities for printing names of objects are indeed
functional in Basic Inform.

=
Chapter - Printing activities

Printing the name of something (hidden in RULES command) (documented at act_pn) is an activity.
The printing the name activity is accessible to Inter as "PRINTING_THE_NAME_ACT".

The standard name printing rule is listed last in the for printing the name rulebook.
The standard name printing rule is defined by Inter as "STANDARD_NAME_PRINTING_R".

Printing the plural name of something (hidden in RULES command) (documented at act_ppn) is an activity.
The printing the plural name activity is accessible to Inter as "PRINTING_THE_PLURAL_NAME_ACT".

The standard printing the plural name rule is listed last in the for printing the
plural name rulebook.
The standard printing the plural name rule is defined by Inter as
"STANDARD_PLURAL_NAME_PRINTING_R".
