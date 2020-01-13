Version 1/191002 of Basic Inform by Graham Nelson begins here.

"Basic Inform, included in every project, defines the basic framework
of Inform as a programming language."

Part One - Preamble

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

The verb to mean means the meaning relation.

The verb to imply means the built-in verb-means meaning.
The verb to imply means the meaning relation.

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

The verb to use in the imperative means the built-in use meaning.
The verb to include + in in the imperative means the built-in include-in meaning.
The verb to omit + from in the imperative means the built-in omit-from meaning.
The verb to document + at in the imperative means the built-in document-at meaning.

Use ineffectual translates as (- ! Use ineffectual does nothing. -).

Use American dialect translates as (- Constant DIALECT_US; -).
Use the serial comma translates as (- Constant SERIAL_COMMA; -).
Use memory economy translates as (- Constant MEMORY_ECONOMY; -).
Use engineering notation translates as (- Constant USE_E_NOTATION = 0; -).
Use unabbreviated object names translates as (- Constant UNABBREVIATED_OBJECT_NAMES = 0; -).
Use command line echoing translates as (- Constant ECHO_COMMANDS; -).
Use predictable randomisation translates as (- Constant FIX_RNG; -).
Use fast route-finding translates as (- Constant FAST_ROUTE_FINDING; -).
Use slow route-finding translates as (- Constant SLOW_ROUTE_FINDING; -).
Use numbered rules translates as (- Constant NUMBERED_RULES; -).
Use telemetry recordings translates as (- Constant TELEMETRY_ON; -).
Use no deprecated features translates as (- Constant NO_DEPRECATED_FEATURES; -).
Use gn testing version translates as (- Constant GN_TESTING_VERSION; -).
Use authorial modesty translates as (- Constant AUTHORIAL_MODESTY; -).

Use dynamic memory allocation of at least 8192 translates as
	(- Constant DynamicMemoryAllocation = {N}; -).
Use maximum text length of at least 1024 translates as
	(- Constant TEXT_TY_BufferSize = {N}+3; -).
Use index figure thumbnails of at least 50 translates as
	(- Constant MAX_FIGURE_THUMBNAILS_IN_INDEX = {N}; -).

Use dynamic memory allocation of at least 8192.

Use interactive fiction language elements. Use multimedia language elements.

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

An object has a value called variable initial value.

An object has a text called specification.
An object has a text called indefinite appearance text.
An object has a text called list grouping key.

An object has a text called printed name.
An object has a text called printed plural name.
An object has a text called an indefinite article.
An object can be plural-named or singular-named. An object is usually singular-named.
An object can be proper-named or improper-named. An object is usually improper-named.
An object can be ambiguously plural.

The indefinite article property translates into I6 as "article".
The printed plural name property translates into I6 as "plural".
The printed name property translates into I6 as "short_name".
The plural-named property translates into I6 as "pluralname".
The ambiguously plural property translates into I6 as "ambigpluralname".
The proper-named property translates into I6 as "proper".

A natural language is a kind of value.
The language of play is a natural language that varies.

Startup rules is a rulebook. [0]
Startup rules have outcomes allow startup (success) and deny startup (failure).
Shutdown rules is a rulebook. [1]

Starting the virtual machine (documented at act_startvm) is an activity.

The enable Glulx acceleration rule is listed first in for starting the virtual machine.

The enable Glulx acceleration rule translates into I6 as "ENABLE_GLULX_ACCEL_R".

Printing the name of something (documented at act_pn) is an activity. [0]

The standard name printing rule is listed last in the for printing the name rulebook.
The standard name printing rule translates into I6 as "STANDARD_NAME_PRINTING_R".

Printing the plural name of something (documented at act_ppn) is an activity. [1]

The standard printing the plural name rule is listed last in the for printing the plural name rulebook.
The standard printing the plural name rule translates into I6 as "STANDARD_PLURAL_NAME_PRINTING_R".

Part Two - Phrasebook

Section 1 - Saying Values

To say (val - sayable value of kind K)
	(documented at ph_say):
	(- {-say:val:K} -).
To say (something - number) in words
	(documented at phs_numwords):
	(- print (number) say__n=({something}); -).
To say s
	(documented at phs_s):
	(- STextSubstitution(); -).

To showme (val - value)
	(documented at ph_showme):
	(- {-show-me:val} -).

Section 2 - Saying Names

To say a (something - object)
	(documented at phs_a):
	(- print (a) {something}; -).
To say an (something - object)
	(documented at phs_a):
	(- print (a) {something}; -).
To say A (something - object)
	(documented at phs_A):
	(- CIndefArt({something}); -).
To say An (something - object)
	(documented at phs_A):
	(- CIndefArt({something}); -).
To say the (something - object)
	(documented at phs_the):
	(- print (the) {something}; -).
To say The (something - object)
	(documented at phs_The):
	(- print (The) {something}; -).

Section SR5/1/3 - Saying - Say if and otherwise

To say if (c - condition)
	(documented at phs_if): (-
	if (~~({c})) jump {-label:Say};
		-).
To say unless (c - condition)
	(documented at phs_unless): (-
	if ({c}) jump {-label:Say};
		-).
To say otherwise/else if (c - condition)
	(documented at phs_elseif): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say}; if (~~({c})) jump {-label:Say};
		-).
To say otherwise/else unless (c - condition)
	(documented at phs_elseunless): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say}; if ({c}) jump {-label:Say};
		-).
To say otherwise
	(documented at phs_otherwise): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say};
		-).
To say else
	(documented at phs_otherwise): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say};
		-).
To say end if
	(documented at phs_endif): (-
	.{-label:Say}{-counter-up:Say}; .{-label:SayX}{-counter-up:SayX};
		-).
To say end unless
	(documented at phs_endunless): (-
	.{-label:Say}{-counter-up:Say}; .{-label:SayX}{-counter-up:SayX};
		-).

Section SR5/1/4 - Saying - Say one of

To say one of -- beginning say_one_of (documented at phs_oneof): (-
	{-counter-makes-array:say_one_of}
	{-counter-makes-array:say_one_flag}
	if ({-counter-storage:say_one_flag}-->{-counter:say_one_flag} == false) {
		{-counter-storage:say_one_of}-->{-counter:say_one_of} = {-final-segment-marker}({-counter-storage:say_one_of}-->{-counter:say_one_of}, {-segment-count});
	 	{-counter-storage:say_one_flag}-->{-counter:say_one_flag} = true;
	}
	if (say__comp == false) {-counter-storage:say_one_flag}-->{-counter:say_one_flag}{-counter-up:say_one_flag} = false;
	switch (({-counter-storage:say_one_of}-->{-counter:say_one_of}{-counter-up:say_one_of})%({-segment-count}+1)-1)
{-open-brace}
		0: -).
To say or -- continuing say_one_of (documented at phs_or):
	(- @nop; {-segment-count}: -).
To say at random -- ending say_one_of with marker I7_SOO_RAN (documented at phs_random):
	(- {-close-brace} -).
To say purely at random -- ending say_one_of with marker I7_SOO_PAR (documented at phs_purelyrandom):
	(- {-close-brace} -).
To say then at random -- ending say_one_of with marker I7_SOO_TRAN (documented at phs_thenrandom):
	(- {-close-brace} -).
To say then purely at random -- ending say_one_of with marker I7_SOO_TPAR (documented at phs_thenpurelyrandom):
	(- {-close-brace} -).
To say sticky random -- ending say_one_of with marker I7_SOO_STI (documented at phs_sticky):
	(- {-close-brace} -).
To say as decreasingly likely outcomes -- ending say_one_of with marker I7_SOO_TAP (documented at phs_decreasing):
	(- {-close-brace} -).
To say in random order -- ending say_one_of with marker I7_SOO_SHU (documented at phs_order):
	(- {-close-brace} -).
To say cycling -- ending say_one_of with marker I7_SOO_CYC (documented at phs_cycling):
	(- {-close-brace} -).
To say stopping -- ending say_one_of with marker I7_SOO_STOP (documented at phs_stopping):
	(- {-close-brace} -).

To say first time -- beginning say_first_time (documented at phs_firsttime):
	(- {-counter-makes-array:say_first_time}
	if ((say__comp == false) && (({-counter-storage:say_first_time}-->{-counter:say_first_time}{-counter-up:say_first_time})++ == 0)) {-open-brace}
		-).
To say only -- ending say_first_time (documented at phs_firsttime):
	(- {-close-brace} -).

Section SR5/1/5 - Saying - Paragraph control

To say line break -- running on
	(documented at phs_linebreak):
	(- new_line; -).
To say no line break -- running on
	(documented at phs_nolinebreak): do nothing.
To say conditional paragraph break -- running on
	(documented at phs_condparabreak):
	(- DivideParagraphPoint(); -).
To say command clarification break -- running on
	(documented at phs_clarifbreak):
	(- CommandClarificationBreak(); -).
To say paragraph break -- running on
	(documented at phs_parabreak):
	(- DivideParagraphPoint(); new_line; -).
To say run paragraph on -- running on
	(documented at phs_runparaon):
	(- RunParagraphOn(); -).
To say run paragraph on with special look spacing -- running on
	(documented at phs_runparaonsls):
	(- SpecialLookSpacingBreak(); -).
To decide if a paragraph break is pending
	(documented at ph_breakpending):
	(- (say__p) -).

Section SR5/1/6 - Saying - Special characters

To say bracket -- running on
	(documented at phs_bracket):
	(- print "["; -).
To say close bracket -- running on
	(documented at phs_closebracket):
	(- print "]"; -).
To say apostrophe/' -- running on
	(documented at phs_apostrophe):
	(- print "'"; -).
To say quotation mark -- running on
	(documented at phs_quotemark):
	(- print "~"; -).

Section SR5/1/7 - Saying - Fonts and visual effects

To say bold type -- running on
	(documented at phs_bold):
	(- style bold; -).
To say italic type -- running on
	(documented at phs_italic):
	(- style underline; -).
To say roman type -- running on
	(documented at phs_roman):
	(- style roman; -).
To say fixed letter spacing -- running on
	(documented at phs_fixedspacing):
	(- font off; -).
To say variable letter spacing -- running on
	(documented at phs_varspacing):
	(- font on; -).

Section SR5/3/8 - Control phrases - Stop or go

To do nothing (documented at ph_nothing):
	(- ; -).
To stop (documented at ph_stop):
	(- rtrue; -) - in to only.

To decide what K is the default value of (V - name of kind of value of kind K)
	(documented at ph_defaultvalue):
	(- {-new:K} -).

Basic Inform ends here.

---- DOCUMENTATION ----

Unlike other extensions, the Standard Rules are compulsorily included
with every project. They define the phrases, kinds and relations which
are basic to Inform, and which are described throughout the documentation.

