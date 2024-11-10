Version 2 of Basic Inform by Graham Nelson begins here.

"Basic Inform, included in every project, defines the basic framework
of Inform as a programming language."

Part One - Preamble

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

The verb to provide means the provision relation.

The verb to use in the imperative means the built-in use meaning.
The verb to include + in in the imperative means the built-in include-in meaning.
The verb to omit + from in the imperative means the built-in omit-from meaning.
The verb to test + with in the imperative means the built-in test-with meaning.

The verb to be greater than means the numerically-greater-than relation.
The verb to be less than means the numerically-less-than relation.
The verb to be at least means the numerically-greater-than-or-equal-to relation.
The verb to be at most means the numerically-less-than-or-equal-to relation.

The operator > means the numerically-greater-than relation.
The operator < means the numerically-less-than relation.
The operator >= means the numerically-greater-than-or-equal-to relation.
The operator <= means the numerically-less-than-or-equal-to relation.

Use ineffectual translates as a compiler feature.

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
Use no status window translates as the configuration flag NO_STATUS_WINDOW
	in BasicInformKit.
Use manual line input echoing translates as the configuration flag
	MANUAL_INPUT_ECHOING in BasicInformKit.

Use dynamic memory allocation of at least 8192 translates as the configuration
	value STACK_FRAME_CAPACITY in BasicInformKit.
Use maximum text length of at least 1024 translates as the configuration
	value TEXT_BUFFER_SIZE in BasicInformKit.
Use index figure thumbnails of at least 50 translates as a compiler feature.

Use dynamic memory allocation of at least 8192.

Use Inform 6 compiler option "$MAX_STACK_SIZE=65536".

Part Two - Miscellaneous Definitions

An abstract object is a kind of object.

An object has a value called variable initial value.

An object has a text called specification.

The specification of abstract object is "Can be used for objects which are purely
conceptual, like ideas, or are needed for internal book-keeping."

An object has a text called indefinite appearance text.
An object has a text called printed name.
An object has a text called printed plural name.
An object has a text called an indefinite article.
An object can be plural-named or singular-named. An object is usually singular-named.
An object can be proper-named or improper-named. An object is usually improper-named.
An object can be ambiguously plural.

The indefinite article property is defined by Inter as "article".
The printed plural name property is defined by Inter as "plural".
The printed name property is defined by Inter as "short_name".
The plural-named property is defined by Inter as "pluralname".
The ambiguously plural property is defined by Inter as "ambigpluralname".
The proper-named property is defined by Inter as "proper".

A natural language is a kind of value.
The language of play is a natural language that varies.

The parameter-object is an object that varies.
The parameter-object variable is defined by Inter as "parameter_value".

Chapter - Startup

Startup rules is a rulebook.
The startup rulebook is accessible to Inter as "STARTUP_RB".
Startup rules have outcomes allow startup (success) and deny startup (failure).

Shutdown rules is a rulebook.
The shutdown rulebook is accessible to Inter as "SHUTDOWN_RB".

Starting the virtual machine (documented at act_startvm) is an activity on nothing.
The starting the virtual machine activity is accessible to Inter as "STARTING_VIRTUAL_MACHINE_ACT".
The for starting the virtual machine rules have default no outcome.

First startup rule (this is the virtual machine startup rule):
	carry out the starting the virtual machine activity.

Section - Startup A (for Glulx only)

The recover Glk objects rule is listed first in the before starting the virtual machine rules. [5th]
The recover Glk objects rule translates into Inter as "GGRecoverObjects".

Section - Startup B

The seed random number generator rule is listed first in the before starting the virtual machine rules. [4th]
The seed random number generator rule translates into Inter as "SEED_RANDOM_NUMBER_GENERATOR_R".

The initialise memory rule is listed first in the before starting the virtual machine rules. [3rd]
The initialise memory rule translates into Inter as "INITIALISE_MEMORY_R".

The platform specific startup rule is listed first in the before starting the virtual machine rules. [2nd]
The platform specific startup rule translates into Inter as "PLATFORM_SPECIFIC_STARTUP_R".

Section - Startup C (for Glulx only)

The start capturing startup text rule is listed first in the before starting the virtual machine rules. [1st]
The start capturing startup text rule translates into Inter as "CAPTURE_STARTUP_TEXT_R".

The calculate hyperlink tag width rule is listed in the before starting the virtual machine rules. [6th]
The calculate hyperlink tag width rule translates into Inter as "CALCULATE_HYPERLINK_TAG_WIDTH_R".

The set default stylehints rule is listed in the before starting the virtual machine rules. [7th]
The set default stylehints rule translates into Inter as "SET_DEFAULT_STYLEHINTS_R".

The sound channel initialisation rule is listed in the for starting the virtual machine rules.
The sound channel initialisation rule translates into Inter as "SOUND_CHANNEL_INIT_R".

The open built in windows rule is listed in the for starting the virtual machine rules.
The open built in windows rule translates into Inter as "OPEN_BUILT_IN_WINDOWS_R".

The display captured startup text rule is listed in the for starting the virtual machine rules.
The display captured startup text rule translates into Inter as "END_CAPTURE_STARTUP_TEXT_R".

Chapter - Printing activities

Constructing the status line (documented at act_csl) is an activity.
The constructing the status line activity is accessible to Inter as "CONSTRUCTING_STATUS_LINE_ACT".

The standard redraw the status window from a table rule is listed in the for constructing the status line rules.
The standard redraw the status window from a table rule is defined by Inter as "REDRAW_STATUS_WINDOW_R".

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

Part Three - Phrasebook

Chapter 1 - Saying

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

To say (N - a number) in hexadecimal
	(documented at phs_inbase):
	(- PrintInBase({N}, 16); -).

To say (N - a number) in decimal
	(documented at phs_inbase):
	(- PrintInBase({N}, 10); -).

To say (N - a number) in octal
	(documented at phs_inbase):
	(- PrintInBase({N}, 8); -).

To say (N - a number) in binary
	(documented at phs_inbase):
	(- PrintInBase({N}, 2); -).

To say (N - a number) in base (B - a number)
	(documented at phs_inbase):
	(- PrintInBase({N}, {B}); -).

To say (N - a number) in (M - a number) digit/digits
	(documented at phs_indigits):
	(- PrintInBase({N}, 10, {M}); -).

To say (N - a number) in (M - a number) hexadecimal digit/digits
	(documented at phs_inbaseindigits):
	(- PrintInBase({N}, 16, {M}); -).

To say (N - a number) in (M - a number) decimal digit/digits
	(documented at phs_inbaseindigits):
	(- PrintInBase({N}, 10, {M}); -).

To say (N - a number) in (M - a number) octal digit/digits
	(documented at phs_inbaseindigits):
	(- PrintInBase({N}, 8, {M}); -).

To say (N - a number) in (M - a number) binary digit/digits
	(documented at phs_inbaseindigits):
	(- PrintInBase({N}, 2, {M}); -).

To say (N - a number) in (M - a number) base (B - a number) digit/digits
	(documented at phs_inbaseindigits):
	(- PrintInBase({N}, {B}, {M}); -).

To say (N - a number) in unsigned decimal
	(documented at phs_inunsigneddecimal):
	(- PrintInBase({N}, 10, 1); -).

To say (N - a number) in (M - a number) unsigned decimal digit/digits
	(documented at phs_inunsigneddecimaldigits):
	(- PrintInBase({N}, 10, {M}); -).

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

Section 3 - Saying Special Characters

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

Section 4 - Saying Line and Paragraph Breaks

To say line break -- running on
	(documented at phs_linebreak):
	(- new_line; -).
To say no line break -- running on
	(documented at phs_nolinebreak):
	do nothing.
To say conditional paragraph break -- running on
	(documented at phs_condparabreak):
	(- DivideParagraphPoint(); -).
To say paragraph break -- running on
	(documented at phs_parabreak):
	(- DivideParagraphPoint(); new_line; -).
To say run paragraph on -- running on
	(documented at phs_runparaon):
	(- RunParagraphOn(); -).
To decide if a paragraph break is pending
	(documented at ph_breakpending):
	(- (say__p) -).

Section 5 - Saying If and Otherwise

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

Section 6 - Saying one of

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
	(- {-segment-count}: -).
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

Section 7 - Saying Lists of Values

To say (L - a list of values) in brace notation
	(documented at phs_listbraced):
	(- LIST_OF_TY_Say({-by-reference:L}, 1); -).
To say (L - a list of objects) with definite articles
	(documented at phs_listdef):
	(- LIST_OF_TY_Say({-by-reference:L}, 2); -).
To say (L - a list of objects) with indefinite articles
	(documented at phs_listindef):
	(- LIST_OF_TY_Say({-by-reference:L}, 3); -).

Chapter 2 - Conditions and Variables

Section 1 - Conditions

To now (cn - condition)
	(documented at ph_now):
	(- {cn} -).
To decide what truth state is whether or not (C - condition)
	(documented at ph_whether):
	(- ({C}) -).

Section 2 - Assigning Temporary Variables

To let (t - nonexisting variable) be (u - value)
	(assignment operation)
	(documented at ph_let): (-
		{-unprotect:t}
		{-copy:t:u}
	-).
To let (t - nonexisting variable) be (u - name of kind of value)
	(assignment operation)
	(documented at ph_letdefault): (-
		{-unprotect:t}
		{-initialise:t}
	-).
To let (t - nonexisting variable) be (u - description of relations of values
	of kind K to values of kind L)
	(assignment operation)
	(documented at ph_letrelation): (-
		{-unprotect:t}
		{-initialise:t}
		{-now-matches-description:t:u};
	-).
To let (t - nonexisting variable) be given by (Q - equation name)
	(documented at ph_letequation): (-
		{-unprotect:t}
		{-primitive-definition:solve-equation};
	-).

To let (t - existing variable) be (u - value)
	(assignment operation)
	(documented at ph_let): (-
	 	{-copy:t:u}
	-).
To let (t - existing variable) be given by (Q - equation name)
	(documented at ph_letequation): (-
		{-primitive-definition:solve-equation};
	-).

Section 3 - Increase and Decrease

To increase (S - storage) by (w - value)
	(assignment operation)
	(documented at ph_increase): (-
		{-copy:S:+w};
	-).
To decrease (S - storage) by (w - value)
	(assignment operation)
	(documented at ph_decrease): (-
		{-copy:S:-w};
	-).
To increment (S - storage)
	(documented at ph_increment): (-
		{-copy:S:+};
	-).
To decrement (S - storage)
	(documented at ph_decrement): (-
		{-copy:S:-};
	-).

Chapter 2 - Arithmetic

Section 1 - Arithmetic Operations

To decide which arithmetic value is (X - arithmetic value) + (Y - arithmetic value)
	(arithmetic operation 0)
	(documented at ph_plus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) plus (Y - arithmetic value)
	(arithmetic operation 0)
	(documented at ph_plus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) - (Y - arithmetic value)
	(arithmetic operation 1)
	(documented at ph_minus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) minus (Y - arithmetic value)
	(arithmetic operation 1)
	(documented at ph_minus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) * (Y - arithmetic value)
	(arithmetic operation 2)
	(documented at ph_times):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) times (Y - arithmetic value)
	(arithmetic operation 2)
	(documented at ph_times):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) multiplied by (Y - arithmetic value)
	(arithmetic operation 2)
	(documented at ph_times):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) / (Y - arithmetic value)
	(arithmetic operation 3)
	(documented at ph_divide):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) divided by (Y - arithmetic value)
	(arithmetic operation 3)
	(documented at ph_divide):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is remainder after dividing (X - arithmetic value)
	by (Y - arithmetic value)
	(arithmetic operation 4)
	(documented at ph_remainder):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) to the nearest (Y - arithmetic value)
	(arithmetic operation 5)
	(documented at ph_nearest):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is the square root of (X - arithmetic value)
	(arithmetic operation 6)
	(documented at ph_squareroot):
	(- ({-arithmetic-operation:X}) -).
To decide which arithmetic value is the cube root of (X - arithmetic value)
	(arithmetic operation 8)
	(documented at ph_cuberoot):
	(- ({-arithmetic-operation:X}) -).
To decide which arithmetic value is total (p - arithmetic value valued property)
	of (S - description of values)
	(arithmetic operation 12)
	(documented at ph_total):
	(- {-primitive-definition:total-of} -).

Section 2 - Saying Real Numbers (not for Z-machine)

To say (R - a real number) to (N - number) decimal places
	(documented at phs_realplaces):
	(- Float({R}, {N}); -).
To say (R - a real number) in decimal notation
	(documented at phs_decimal):
	(- FloatDec({R}); -).
To say (R - a real number) to (N - number) decimal places in decimal notation
	(documented at phs_decimalplaces):
	(- FloatDec({R}, {N}); -).
To say (R - a real number) in scientific notation
	(documented at phs_scientific):
	(- FloatExp({R}); -).
To say (R - a real number) to (N - number) decimal places in scientific notation
	(documented at phs_scientificplaces):
	(- FloatExp({R}, {N}); -).

Section 3 - Real Arithmetic (not for Z-machine)

To decide which real number is the reciprocal of (R - a real number)
	(documented at ph_reciprocal):
	(- REAL_NUMBER_TY_Reciprocal({R}) -).
To decide which real number is the absolute value of (R - a real number)
	(documented at ph_absolutevalue)
	(this is the abs function):
	(- REAL_NUMBER_TY_Abs({R}) -).
To decide which real number is the real square root of (R - a real number)
	(arithmetic operation 7)
	(documented at ph_realsquareroot)
	(this is the root function inverse to rsqr):
	(- REAL_NUMBER_TY_Root({R}) -).
To decide which real number is the real square of (R - a real number)
	(this is the rsqr function inverse to root):
	let x be given by x = R^2 where x is a real number;
	decide on x.
To decide which real number is the ceiling of (R - a real number)
	(documented at ph_ceiling)
	(this is the ceiling function):
	(- REAL_NUMBER_TY_Ceiling({R}) -).
To decide which real number is the floor of (R - a real number)
	(documented at ph_floor)
	(this is the floor function):
	(- REAL_NUMBER_TY_Floor({R}) -).
To decide which number is (R - a real number) to the/-- nearest whole number
	(documented at ph_nearestwholenumber)
	(this is the int function):
	(- REAL_NUMBER_TY_to_NUMBER_TY({R}) -).

Section 4 - Exponential Functions (not for Z-machine)

To decide which real number is the natural/-- logarithm of (R - a real number)
	(documented at ph_logarithm)
	(this is the log function inverse to exp):
	(- REAL_NUMBER_TY_Log({R}) -).
To decide which real number is the logarithm to base (N - a number) of (R - a real number)
	(documented at ph_logarithmto):
	(- REAL_NUMBER_TY_BLog({R}, {N}) -).
To decide which real number is the exponential of (R - a real number)
	(documented at ph_exp)
	(this is the exp function inverse to log):
	(- REAL_NUMBER_TY_Exp({R}) -).
To decide which real number is (R - a real number) to the power (P - a real number)
	(documented at ph_power):
	(- REAL_NUMBER_TY_Pow({R}, {P}) -).

Section 5 - Trigonometric Functions (not for Z-machine)

To decide which real number is (R - a real number) degrees
	(documented at ph_degrees):
	(- REAL_NUMBER_TY_Times({R}, $+0.0174532925) -).

To decide which real number is the sine of (R - a real number)
	(documented at ph_sine)
	(this is the sin function inverse to arcsin):
	(- REAL_NUMBER_TY_Sin({R}) -).
To decide which real number is the cosine of (R - a real number)
	(documented at ph_cosine)
	(this is the cos function inverse to arccos):
	(- REAL_NUMBER_TY_Cos({R}) -).
To decide which real number is the tangent of (R - a real number)
	(documented at ph_tangent)
	(this is the tan function inverse to arctan):
	(- REAL_NUMBER_TY_Tan({R}) -).
To decide which real number is the arcsine of (R - a real number)
	(documented at ph_arcsine)
	(this is the arcsin function inverse to sin):
	(- REAL_NUMBER_TY_Arcsin({R}) -).
To decide which real number is the arccosine of (R - a real number)
	(documented at ph_arccosine)
	(this is the arccos function inverse to cos):
	(- REAL_NUMBER_TY_Arccos({R}) -).
To decide which real number is the arctangent of (R - a real number)
	(documented at ph_arctangent)
	(this is the arctan function inverse to tan):
	(- REAL_NUMBER_TY_Arctan({R}) -).

Section 6 - Trigonometric Functions (not for Z-machine)

To decide which real number is the hyperbolic sine of (R - a real number)
	(documented at ph_hyperbolicsine)
	(this is the sinh function inverse to arcsinh):
	(- REAL_NUMBER_TY_Sinh({R}) -).
To decide which real number is the hyperbolic cosine of (R - a real number)
	(documented at ph_hyperboliccosine)
	(this is the cosh function inverse to arccosh):
	(- REAL_NUMBER_TY_Cosh({R}) -).
To decide which real number is the hyperbolic tangent of (R - a real number)
	(documented at ph_hyperbolictangent)
	(this is the tanh function inverse to arctanh):
	(- REAL_NUMBER_TY_Tanh({R}) -).
To decide which real number is the hyperbolic arcsine of (R - a real number)
	(documented at ph_hyperbolicarcsine)
	(this is the arcsinh function inverse to sinh):
	let x be given by x = log(R + root(R^2 + 1)) where x is a real number;
	decide on x.
To decide which real number is the hyperbolic arccosine of (R - a real number)
	(documented at ph_hyperbolicarccosine)
	(this is the arccosh function inverse to cosh):
	let x be given by x = log(R + root(R^2 - 1)) where x is a real number;
	decide on x.
To decide which real number is the hyperbolic arctangent of (R - a real number)
	(documented at ph_hyperbolicarctangent)
	(this is the arctanh function inverse to tanh):
	let x be given by x = 0.5*(log(1+R) - log(1-R)) where x is a real number;
	decide on x.

Chapter 3 - Control

Section 1 - Deciding Outcomes

To decide yes
	(documented at ph_yes):
	(- rtrue; -) - in to decide if only.
To decide no
	(documented at ph_no):
	(- rfalse; -) - in to decide if only.

To stop (documented at ph_stop):
	(- rtrue; -) - in to only.

To decide on (something - value)
	(documented at ph_decideon):
	(- return {-return-value:something}; -).

Section 2 - If and Unless

To if (c - condition) begin -- end conditional
	(documented at ph_if):
	(- {c}  -).
To unless (c - condition) begin -- end conditional
	(documented at ph_unless):
	(- (~~{c})  -).
To if (V - value) is begin -- end conditional
	(documented at ph_switch):
	(-  -).

To do nothing (documented at ph_nothing):
	(- ; -).

Section 3 - While and Repeat

To while (c - condition) begin -- end loop
	(documented at ph_while):
	(- while {c}  -).

To repeat with (loopvar - nonexisting K variable)
	running from (v - arithmetic value of kind K) to (w - K) begin -- end loop
	(documented at ph_repeat):
		(- for ({loopvar}={v}: {loopvar}<={w}: {loopvar}++)  -).
To repeat with (loopvar - nonexisting K variable)
	running from (v - enumerated value of kind K) to (w - K) begin -- end loop
	(documented at ph_repeat):
		(- for ({loopvar}={v}: {loopvar}<={w}: {loopvar}={-next-routine:K}({loopvar}))  -).
To repeat with (loopvar - nonexisting K variable)
	running through (OS - description of values of kind K) begin -- end loop
	(documented at ph_runthrough):
		(- {-primitive-definition:repeat-through} -).
To repeat with (loopvar - nonexisting object variable)
	running through (L - list of values) begin -- end loop
	(documented at ph_repeatlist):
		(- {-primitive-definition:repeat-through-list} -).

To repeat through (T - table name) begin -- end loop
	(documented at ph_repeattable): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=1, ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}<=TableRows({-my:1}):
			{-my:2}++, ct_0={-my:1}, ct_1={-my:2})
			if (TableRowIsBlank(ct_0, ct_1)==false)
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).
To repeat through (T - table name) in reverse order begin -- end loop
	(documented at ph_repeattablereverse): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=TableRows({-my:1}), ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}>=1:
			{-my:2}--, ct_0={-my:1}, ct_1={-my:2})
			if (TableRowIsBlank(ct_0, ct_1)==false)
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).
To repeat through (T - table name) in (TC - table column) order begin -- end loop
	(documented at ph_repeattablecol): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=TableNextRow({-my:1}, {TC}, 0, 1), ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}~=0:
			{-my:2}=TableNextRow({-my:1}, {TC}, {-my:2}, 1), ct_0={-my:1}, ct_1={-my:2})
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).
To repeat through (T - table name) in reverse (TC - table column) order begin -- end loop
	(documented at ph_repeattablecolreverse): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=TableNextRow({-my:1}, {TC}, 0, -1), ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}~=0:
			{-my:2}=TableNextRow({-my:1}, {TC}, {-my:2}, -1), ct_0={-my:1}, ct_1={-my:2})
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).

To repeat with (loopvar - nonexisting text variable)
	running through (F - internal file) begin -- end loop:
	(-
		for ({-my:1} = InternalFileIO_Line({-by-reference:loopvar}, {F}): {-my:1}:
			{-my:1} = InternalFileIO_Line({-by-reference:loopvar}, {F}))
			{-block}
	-).

Section 4 - Loop Flow

To break -- in loop
	(documented at ph_break):
	(- {-primitive-definition:break} -).
To next -- in loop
	(documented at ph_next):
	(- continue; -).

Section 5 - Run-Time Problems

To issue the run-time problem (pcode - text):
	(- IssueRTP({-rtp-code: pcode}, -1, {-rtp-location: pcode}); -).

Chapter 4 - Values

Section 1 - Enumerations

To decide which number is number of (S - description of values)
	(documented at ph_numberof):
	(- {-primitive-definition:number-of} -).
To decide what number is the numerical value of (X - enumerated value)
	(documented at ph_numericalvalue):
	(- {X} -).
To decide what number is the sequence number of (X - enumerated value of kind K)
	(documented at ph_sequencenumber):
	(- {-indexing-routine:K}({X}) -).
To decide which K is (name of kind of enumerated value K) after (X - K)
	(documented at ph_enumafter):
	(- {-next-routine:K}({X}) -).
To decide which K is (name of kind of enumerated value K) before (X - K)
	(documented at ph_enumbefore):
	(- {-previous-routine:K}({X}) -).
To decide which K is the first value of (name of kind of enumerated value K)
	(documented at ph_enumfirst):
	decide on the default value of K.
To decide which K is the last value of (name of kind of enumerated value K)
	(documented at ph_enumlast):
	decide on K before the default value of K.

Section 2 - Randomness

To decide which K is a/-- random (S - description of values of kind K)
	(documented at ph_randomdesc):
	(- {-primitive-definition:random-of} -).
To decide which K is a random (name of kind of arithmetic value K) between (first value - K) and (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide which K is a random (name of kind of arithmetic value K) from (first value - K) to (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide which K is a random (name of kind of enumerated value K) between (first value - K) and (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide which K is a random (name of kind of enumerated value K) from (first value - K) to (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide whether a random chance of (N - number) in (M - number) succeeds
	(documented at ph_randomchance):
	(- (GenerateRandomNumber(1, {M}) <= {N}) -).
To seed the random-number generator with (N - number)
	(documented at ph_seed):
	(- VM_Seed_RNG({N}); -).

Section 3 - Default Values

To decide what K is the default value of (V - name of kind of value of kind K)
	(documented at ph_defaultvalue):
	(- {-new:K} -).

Chapter 5 - Text

Section 1 - Breaking down text

To decide what number is the number of characters in (T - text)
	(documented at ph_numchars):
	(- TEXT_TY_BlobAccess({-by-reference:T}, CHR_BLOB) -).
To decide what number is the number of words in (T - text)
	(documented at ph_numwords):
	(- TEXT_TY_BlobAccess({-by-reference:T}, WORD_BLOB) -).
To decide what number is the number of punctuated words in (T - text)
	(documented at ph_numpwords):
	(- TEXT_TY_BlobAccess({-by-reference:T}, PWORD_BLOB) -).
To decide what number is the number of unpunctuated words in (T - text)
	(documented at ph_numupwords):
	(- TEXT_TY_BlobAccess({-by-reference:T}, UWORD_BLOB) -).
To decide what number is the number of lines in (T - text)
	(documented at ph_numlines):
	(- TEXT_TY_BlobAccess({-by-reference:T}, LINE_BLOB) -).
To decide what number is the number of paragraphs in (T - text)
	(documented at ph_numparas):
	(- TEXT_TY_BlobAccess({-by-reference:T}, PARA_BLOB) -).

To decide what text is character number (N - a number) in (T - text)
	(documented at ph_charnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, CHR_BLOB) -).
To decide what text is word number (N - a number) in (T - text)
	(documented at ph_wordnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, WORD_BLOB) -).
To decide what text is punctuated word number (N - a number) in (T - text)
	(documented at ph_pwordnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, PWORD_BLOB) -).
To decide what text is unpunctuated word number (N - a number) in (T - text)
	(documented at ph_upwordnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, UWORD_BLOB) -).
To decide what text is line number (N - a number) in (T - text)
	(documented at ph_linenum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, LINE_BLOB) -).
To decide what text is paragraph number (N - a number) in (T - text)
	(documented at ph_paranum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, PARA_BLOB) -).

To decide what text is the substituted form of (T - text)
	(documented at ph_subform):
	(- TEXT_TY_SubstitutedForm({-new:text}, {-by-reference:T}) -).

Section 2 - Matching and Replacing

To decide if (T - text) exactly matches the/-- text (find - text),
	case insensitively
	(documented at ph_exactlymatches):
	(- TEXT_TY_Replace_RE(CHR_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options},1) -).
To decide if (T - text) matches the/-- text (find - text),
	case insensitively
	(documented at ph_matches):
	(- TEXT_TY_Replace_RE(CHR_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options}) -).
To decide what number is number of times (T - text) matches the/-- text
	(find - text), case insensitively
	(documented at ph_nummatches):
	(- TEXT_TY_Replace_RE(CHR_BLOB,{-by-reference:T},{-by-reference:find},1,{phrase options}) -).

To replace the text (find - text) in (T - text) with (replace - text),
	case insensitively
	(documented at ph_replace):
	(- TEXT_TY_Replace_RE(CHR_BLOB, {-lvalue-by-reference:T}, {-by-reference:find},
		{-by-reference:replace}, {phrase options}); -).
To replace the word (find - text) in (T - text) with
	(replace - text)
	(documented at ph_replacewordin):
	(- TEXT_TY_ReplaceText(WORD_BLOB, {-lvalue-by-reference:T}, {-by-reference:find}, {-by-reference:replace}); -).
To replace the punctuated word (find - text) in (T - text)
	with (replace - text)
	(documented at ph_replacepwordin):
	(- TEXT_TY_ReplaceText(PWORD_BLOB, {-lvalue-by-reference:T}, {-by-reference:find}, {-by-reference:replace}); -).

To replace character number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replacechar):
	(- TEXT_TY_ReplaceBlob(CHR_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace word number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replaceword):
	(- TEXT_TY_ReplaceBlob(WORD_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace punctuated word number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replacepword):
	(- TEXT_TY_ReplaceBlob(PWORD_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace unpunctuated word number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replaceupword):
	(- TEXT_TY_ReplaceBlob(UWORD_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace line number (N - a number) in (T - text) with (replace - text)
	(documented at ph_replaceline):
	(- TEXT_TY_ReplaceBlob(LINE_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace paragraph number (N - a number) in (T - text) with (replace - text)
	(documented at ph_replacepara):
	(- TEXT_TY_ReplaceBlob(PARA_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To decide what number is the first index of text match
	(documented at ph_textfirstindex):
	(- (match0_idx2 ~= 0) * (match0_idx + 1) -).
To decide what number is the last index of text match
	(documented at ph_textlastindex):
	(- match0_idx2 -).
To decide what number is the length of text match
	(documented at ph_textlength):
	(- (match0_idx2 - match0_idx) -).

Section 3 - Regular Expressions

To decide if (T - text) exactly matches the/-- regular expression (find - text),
	case insensitively
	(documented at ph_exactlymatchesre):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options},1) -).
To decide if (T - text) matches the/-- regular expression (find - text),
	case insensitively
	(documented at ph_matchesre):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options}) -).
To decide what text is text matching regular expression
	(documented at ph_matchtext):
	(- TEXT_TY_RE_GetMatchVar(0) -).
To decide what text is text matching subexpression (N - a number)
	(documented at ph_subexpressiontext):
	(- TEXT_TY_RE_GetMatchVar({N}) -).
To decide what number is the first index of subexpression (n - a number)
	(documented at ph_refirstindex):
	(- (RE_Subexpressions-->{n}-->RE_DATA2 ~= 0) * (RE_Subexpressions-->{n}-->RE_DATA1 + 1) -).
To decide what number is the last index of subexpression (n - a number)
	(documented at ph_relastindex):
	(- ((RE_Subexpressions-->{n}-->RE_DATA2 >= 0) * RE_Subexpressions-->{n}-->RE_DATA2) -).
To decide what number is the length of subexpression (n - a number)
	(documented at ph_relength):
	(- (RE_Subexpressions-->{n}-->RE_DATA2 - RE_Subexpressions-->{n}-->RE_DATA1) -).
To decide what number is number of times (T - text) matches the/-- regular expression
	(find - text),case insensitively
	(documented at ph_nummatchesre):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB,{-by-reference:T},{-by-reference:find},1,{phrase options}) -).
To replace the regular expression (find - text) in (T - text) with
	(replace - text), case insensitively
	(documented at ph_replacere):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB, {-lvalue-by-reference:T}, {-by-reference:find},
		{-by-reference:replace}, {phrase options}); -).

Section 4 - Casing of Text

To decide what text is (T - text) in lower case
	(documented at ph_lowercase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 0) -).
To decide what text is (T - text) in upper case
	(documented at ph_uppercase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 1) -).
To decide what text is (T - text) in title case
	(documented at ph_titlecase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 2) -).
To decide what text is (T - text) in sentence case
	(documented at ph_sentencecase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 3) -).
To decide if (T - text) is in lower case
	(documented at ph_inlower):
	(- TEXT_TY_CharactersOfCase({-by-reference:T}, 0) -).
To decide if (T - text) is in upper case
	(documented at ph_inupper):
	(- TEXT_TY_CharactersOfCase({-by-reference:T}, 1) -).

Section 5 - Adaptive Text

To say infinitive of (V - a verb)
	(documented at phs_infinitive):
	(- {V}(1); -).
To say past participle of (V - a verb)
	(documented at phs_pastpart):
	(- {V}(2); -).
To say present participle of (V - a verb)
	(documented at phs_prespart):
	(- {V}(3); -).

To say adapt (V - verb)
	(documented at phs_adapt):
	(- {V}(CV_POS, PNToVP(), story_tense); -).
To say adapt (V - verb) in (T - grammatical tense)
	(documented at phs_adaptt):
	(- {V}(CV_POS, PNToVP(), {T}); -).
To say adapt (V - verb) from (P - narrative viewpoint)
	(documented at phs_adaptv):
	(- {V}(CV_POS, {P}, story_tense); -).
To say adapt (V - verb) in (T - grammatical tense) from (P - narrative viewpoint)
	(documented at phs_adaptvt):
	(- {V}(CV_POS, {P}, {T}); -).
To say negate (V - verb)
	(documented at phs_negate):
	(- {V}(CV_NEG, PNToVP(), story_tense); -).
To say negate (V - verb) in (T - grammatical tense)
	(documented at phs_negatet):
	(- {V}(CV_NEG, PNToVP(), {T}); -).
To say negate (V - verb) from (P - narrative viewpoint)
	(documented at phs_negatev):
	(- {V}(CV_NEG, {P}, story_tense); -).
To say negate (V - verb) in (T - grammatical tense) from (P - narrative viewpoint)
	(documented at phs_negatevt):
	(- {V}(CV_NEG, {P}, {T}); -).

To decide which relation of objects is meaning of (V - a verb): (- {V}(CV_MEANING) -).

Chapter 6 - Data Structures

Section 1 - Tables

To choose a/the/-- row (N - number) in/from (T - table name)
	(documented at ph_chooserow):
	(- {-my:ct_0} = {T}; {-my:ct_1} = {N}; -).
To choose a/the/-- row with (TC - K valued table column) of (w - value of kind K)
	in/from (T - table name)
	(documented at ph_chooserowwith):
	(- {-my:ct_0} = {T}; {-my:ct_1} = TableRowCorr(ct_0, {TC}, {w}); -).
To choose a/the/-- blank row in/from (T - table name)
	(documented at ph_chooseblankrow):
	(- {-my:ct_0} = {T}; {-my:ct_1} = TableBlankRow(ct_0); -).
To choose a/the/-- random row in/from (T - table name)
	(documented at ph_chooserandomrow):
	(- {-my:ct_0} = {T}; {-my:ct_1} = TableRandomRow(ct_0); -).
To decide which number is number of rows in/from (T - table name)
	(documented at ph_numrows):
	(- TableRows({T}) -).
To decide which number is number of blank rows in/from (T - table name)
	(documented at ph_numblank):
	(- TableBlankRows({T}) -).
To decide which number is number of filled rows in/from (T - table name)
	(documented at ph_numfilled):
	(- TableFilledRows({T}) -).
To decide if there is (TR - table-reference)
	(documented at ph_thereis):
	(- ({-reference-exists:TR}) -).
To decide if there is no (TR - table-reference)
	(documented at ph_thereisno):
	(- ({-reference-exists:TR} == false) -).
To blank out (tr - table-reference)
	(documented at ph_blankout):
	(- {-by-reference-blank-out:tr}; -).
To blank out the/-- whole row
	(documented at ph_blankoutrow):
	(- TableBlankOutRow({-my:ct_0}, {-my:ct_1}); -).
To blank out the/-- whole (TC - table column) in/from/of (T - table name)
	(documented at ph_blankoutcol):
	(- TableBlankOutColumn({T}, {TC}); -).
To blank out the/-- whole of (T - table name)
	(documented at ph_blankouttable):
	(- TableBlankOutAll({T}); -).

To showme the contents of (T - table name)
	(documented at ph_showmetable):
	(- TableDebug({T}); -).
To say the/-- current table row
	(documented at phs_currenttablerow):
	(- TableRowDebug({-my:ct_0}, {-my:ct_1}); -).
To say row (N - number) in/from (T - table name)
	(documented at phs_tablerow):
	(- TableRowDebug({T}, {N}); -).
To say (TC - table column) in/from (T - table name)
	(documented at phs_tablecolumn):
	(- TableColumnDebug({T}, {TC}); -).

Section 2 - Sorting Tables

To sort (T - table name) in/into random order
	(documented at ph_sortrandom):
	(- TableShuffle({T}); -).
To sort (T - table name) in/into (TC - table column) order
	(documented at ph_sortcolumn):
	(- TableSort({T}, {TC}, SORT_ASCENDING); -).
To sort (T - table name) in/into reverse (TC - table column) order
	(documented at ph_sortcolumnreverse):
	(- TableSort({T}, {TC}, SORT_DESCENDING); -).
To sort (T - table name) with (cf - phrase (table name, number, number) -> number)
	(documented at ph_sorttablephrase):
	(- TableSort({T}, 0, SORT_ASCENDING, 0, {cf}-->1); -).

Section 3 - Lists

To add (new entry - K) to (L - list of values of kind K), if absent
	(documented at ph_addtolist):
	(- LIST_OF_TY_InsertItem({-lvalue-by-reference:L}, {new entry}, 0, 0, {phrase options}); -).

To add (new entry - K) at entry (E - number) in/from (L - list of values of kind K), if absent
	(documented at ph_addatentry):
	(- LIST_OF_TY_InsertItem({-lvalue-by-reference:L}, {new entry}, 1, {E}, {phrase options}); -).

To add (LX - list of Ks) to (L - list of values of kind K), if absent
	(documented at ph_addlisttolist):
	(- LIST_OF_TY_AppendList({-lvalue-by-reference:L}, {-by-reference:LX}, 0, 0, {phrase options}); -).

To add (LX - list of Ks) at entry (E - number) in/from (L - list of values of kind K)
	(documented at ph_addlistatentry):
	(- LIST_OF_TY_AppendList({-lvalue-by-reference:L}, {-by-reference:LX}, 1, {E}, 0); -).

To remove (existing entry - K) in/from (L - list of values of kind K), if present
	(documented at ph_remfromlist):
	(- LIST_OF_TY_RemoveValue({-lvalue-by-reference:L}, {existing entry}, {phrase options}); -).

To remove (N - list of Ks) in/from (L - list of values of kind K), if present
	(documented at ph_remlistfromlist):
	(- LIST_OF_TY_Remove_List({-lvalue-by-reference:L}, {-by-reference:N}, {phrase options}); -).

To remove entry (N - number) in/from (L - list of values), if present
	(documented at ph_rementry):
	(- LIST_OF_TY_RemoveItemRange({-lvalue-by-reference:L}, {N}, {N}, {phrase options}); -).

To remove entries (N - number) to (N2 - number) in/from (L - list of values), if present
	(documented at ph_rementries):
	(- LIST_OF_TY_RemoveItemRange({-lvalue-by-reference:L}, {N}, {N2}, {phrase options}); -).

To decide if (N - K) is listed in (L - list of values of kind K)
	(documented at ph_islistedin):
	(- (LIST_OF_TY_FindItem({-by-reference:L}, {N})) -).

To decide if (N - K) is not listed in (L - list of values of kind K)
	(documented at ph_isnotlistedin):
	(- (LIST_OF_TY_FindItem({-by-reference:L}, {N}) == false) -).

To decide what list of Ks is the list of (D - description of values of kind K)
	(documented at ph_listofdesc):
	(- {-new-list-of:list of K} -).

Section 4 - Length of lists

To decide what number is the number of entries in/of/from (L - a list of values)
	(documented at ph_numberentries):
	(- LIST_OF_TY_GetLength({-by-reference:L}) -).
To truncate (L - a list of values) to (N - a number) entries/entry
	(documented at ph_truncate):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, -1, 1); -).
To truncate (L - a list of values) to the/-- first (N - a number) entries/entry
	(documented at ph_truncatefirst):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, -1, 1); -).
To truncate (L - a list of values) to the/-- last (N - a number) entries/entry
	(documented at ph_truncatelast):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, -1, -1); -).
To extend (L - a list of values) to (N - a number) entries/entry
	(documented at ph_extend):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, 1); -).
To change (L - a list of values) to have (N - a number) entries/entry
	(documented at ph_changelength):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, 0); -).

Section 5 - List operations

To reverse (L - a list of values)
	(documented at ph_reverselist):
	(- LIST_OF_TY_Reverse({-lvalue-by-reference:L}); -).
To rotate (L - a list of values)
	(documented at ph_rotatelist):
	(- LIST_OF_TY_Rotate({-lvalue-by-reference:L}, 0); -).
To rotate (L - a list of values) backwards
	(documented at ph_rotatelistback):
	(- LIST_OF_TY_Rotate({-lvalue-by-reference:L}, 1); -).
To sort (L - a list of values)
	(documented at ph_sortlist):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, SORT_ASCENDING); -).
To sort (L - a list of values) in/into reverse order
	(documented at ph_sortlistreverse):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, SORT_DESCENDING); -).
To sort (L - a list of values of kind K) with (cf - phrase (K, K) -> number)
	(documented at ph_sortlistphrase):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, SORT_ASCENDING, 0, 0, {cf}-->1); -).
To sort (L - a list of values) in/into random order
	(documented at ph_sortlistrandom):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, SORT_LIST_RANDOM); -).
To sort (L - a list of objects) in/into (P - property) order
	(documented at ph_sortlistproperty):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, SORT_ASCENDING, {P}, {-property-holds-block-value:P}); -).
To sort (L - a list of objects) in/into reverse (P - property) order
	(documented at ph_sortlistpropertyreverse):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, SORT_DESCENDING, {P}, {-property-holds-block-value:P}); -).

Section 6 - Relations

To show relation (R - relation)
	(documented at ph_showrelation):
	(- {-show-me:R}; RelationTest({-by-reference:R}, RELS_SHOW); -).

To decide which object is next step via (R - relation of objects)
	from (O1 - object) to (O2 - object)
	(documented at ph_nextstep):
	(- RelationRouteTo({-by-reference:R},{O1},{O2},false) -).
To decide which number is number of steps via (R - relation of objects)
	from (O1 - object) to (O2 - object)
	(documented at ph_numbersteps):
	(- RelationRouteTo({-by-reference:R},{O1},{O2},true) -).

To decide which list of Ks is list of (name of kind of value K)
	that/which/whom (R - relation of Ks to values of kind L) relates
	(documented at ph_leftdomain):
	(- RelationTest({-by-reference:R}, RELS_LIST, {-new:list of K}, RLIST_ALL_X) -).

To decide which list of Ls is list of (name of kind of value L)
	to which/whom (R - relation of values of kind K to Ls) relates
	(documented at ph_rightdomain):
	(- RelationTest({-by-reference:R}, RELS_LIST, {-new:list of L}, RLIST_ALL_Y) -). [1]

To decide which list of Ls is list of (name of kind of value L)
	that/which/whom (R - relation of values of kind K to Ls) relates to
	(documented at ph_rightdomain):
	(- RelationTest({-by-reference:R}, RELS_LIST, {-new:list of L}, RLIST_ALL_Y) -). [2]

To decide which list of Ks is list of (name of kind of value K) that/which/who
	relate to (Y - L) by (R - relation of Ks to values of kind L)
	(documented at ph_leftlookuplist):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ALL_X, {Y}, {-new:list of K}) -).

To decide which list of Ls is list of (name of kind of value L) to which/whom (X - K)
	relates by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookuplist):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ALL_Y, {X}, {-new:list of L}) -). [1]

To decide which list of Ls is list of (name of kind of value L)
	that/which/whom (X - K) relates to by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookuplist):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ALL_Y, {X}, {-new:list of L}) -). [2]

To decide whether (name of kind of value K) relates to (Y - L) by
	(R - relation of Ks to values of kind L)
	(documented at ph_ifright):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {Y}, RLANY_CAN_GET_X) -).

To decide whether (X - K) relates to (name of kind of value L) by
	(R - relation of values of kind K to Ls)
	(documented at ph_ifleft):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {X}, RLANY_CAN_GET_Y) -).

To decide which K is (name of kind of value K) that/which/who relates to
	(Y - L) by (R - relation of Ks to values of kind L)
	(documented at ph_leftlookup):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {Y}, RLANY_GET_X) -).

To decide which L is (name of kind of value L) to which/whom (X - K)
	relates by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookup):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {X}, RLANY_GET_Y) -). [1]

To decide which L is (name of kind of value L) that/which/whom (X - K)
	relates to by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookup):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {X}, RLANY_GET_Y) -). [2]

Chapter 7 - Functional Programming

Section 1 - Applying Functions

To decide whether (val - K) matches (desc - description of values of kind K)
	(documented at ph_valuematch):
	(- {-primitive-definition:description-application} -).

To decide what K is (function - phrase nothing -> value of kind K) applied
	(documented at ph_applied0):
	(- {-primitive-definition:function-application} -).

To decide what L is (function - phrase value of kind K -> value of kind L)
	applied to (input - K)
	(documented at ph_applied1):
	(- {-primitive-definition:function-application} -).

To decide what M is (function - phrase (value of kind K, value of kind L) -> value of kind M)
	applied to (input - K) and (second input - L)
	(documented at ph_applied2):
	(- {-primitive-definition:function-application} -).

To decide what N is (function - phrase (value of kind K, value of kind L, value of kind M) -> value of kind N)
	applied to (input - K) and (second input - L) and (third input - M)
	(documented at ph_applied3):
	(- {-primitive-definition:function-application} -).

To apply (function - phrase nothing -> nothing)
	(documented at ph_apply0):
	(- {-primitive-definition:function-application}; -).

To apply (function - phrase value of kind K -> nothing)
	to (input - K)
	(documented at ph_apply1):
	(- {-primitive-definition:function-application}; -).

To apply (function - phrase (value of kind K, value of kind L) -> nothing)
	to (input - K) and (second input - L)
	(documented at ph_apply2):
	(- {-primitive-definition:function-application}; -).

To apply (function - phrase (value of kind K, value of kind L, value of kind M) -> nothing)
	to (input - K) and (second input - L) and (third input - M)
	(documented at ph_apply3):
	(- {-primitive-definition:function-application}; -).

Section 2 - Working with Lists

To decide what list of L is (function - phrase K -> value of kind L) applied to (original list - list of values of kind K)
	(documented at ph_appliedlist):
	let the result be a list of Ls;
	repeat with item running through the original list:
		let the mapped item be the function applied to the item;
		add the mapped item to the result;
	decide on the result.

To decide what K is the (function - phrase (K, K) -> K) reduction of (original list - list of values of kind K)
	(documented at ph_reduction):
	let the total be a K;
	let the count be 0;
	repeat with item running through the original list:
		increase the count by 1;
		if the count is 1, now the total is the item;
		otherwise now the total is the function applied to the total and the item;
	decide on the total.

To decide what list of K is the filter to (criterion - description of Ks) of
	(full list - list of values of kind K)
	(documented at ph_filter):
	let the filtered list be a list of K;
	repeat with item running through the full list:
		if the item matches the criterion:
			add the item to the filtered list;
	decide on the filtered list.

Chapter 8 - Rulebooks and Activities

Section 1 - Carrying out Activities

To carry out the (A - activity on nothing) activity
	(documented at ph_carryout):
	(- CarryOutActivity({A}); -).
To carry out the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_carryoutwith):
	(- CarryOutActivity({A}, {val}); -).
To continue the activity
	(documented at ph_continueactivity):
	(- rfalse; -) - in to only.

Section 2 - Advanced Activities

To begin the (A - activity on nothing) activity
	(documented at ph_beginactivity):
	(- BeginActivity({A}); -).
To begin the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_beginactivitywith):
	(- BeginActivity({A}, {val}); -).
To decide whether handling (A - activity) activity
	(documented at ph_handlingactivity):
	(- (~~(ForActivity({A}))) -).
To decide whether handling (A - activity on value of kind K) activity with (val - K)
	(documented at ph_handlingactivitywith):
	(- (~~(ForActivity({A}, {val}))) -).
To end the (A - activity on nothing) activity
	(documented at ph_endactivity):
	(- EndActivity({A}); -).
To end the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_endactivitywith):
	(- EndActivity({A}, {val}); -).
To abandon the (A - activity on nothing) activity
	(documented at ph_abandonactivity):
	(- AbandonActivity({A}); -).
To abandon the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_abandonactivitywith):
	(- AbandonActivity({A}, {val}); -).

Section 3 - Following Rules

To follow (RL - a rule)
	(documented at ph_follow):
	(- FollowRulebook({RL}); -).
To follow (RL - value of kind K based rule producing a value) for (V - K)
	(documented at ph_followfor):
	(- FollowRulebook({RL}, {V}, true); -).
To follow (RL - a nothing based rule)
	(documented at ph_follow):
	(- FollowRulebook({RL}); -).
To decide what K is the (name of kind K) produced by (RL - rule producing a value of kind K)
	(documented at ph_producedby):
	(- ResultOfRule({RL}, 0, true, {-strong-kind:K}) -).
To decide what L is the (name of kind L) produced by (RL - value of kind K based rule
	producing a value of kind L) for (V - K)
	(documented at ph_producedbyfor):
	(- ResultOfRule({RL}, {V}, true, {-strong-kind:L}) -).
To decide what K is the (name of kind K) produced by (RL - nothing based rule producing a value of kind K)
	(documented at ph_producedby):
	(- ResultOfRule({RL}, 0, true, {-strong-kind:K}) -).
To abide by (RL - a rule)
	(documented at ph_abide):
	(- if (FollowRulebook({RL})) rtrue; -) - in to only.
To abide by (RL - value of kind K based rule producing a value) for (V - K)
	(documented at ph_abidefor):
	(- if (FollowRulebook({RL}, {V}, true)) rtrue; -) - in to only.
To abide by (RL - a nothing based rule)
	(documented at ph_abide):
	(- if (FollowRulebook({RL})) rtrue; -) - in to only.

Section 4 - Success and Failure

To make no decision
	(documented at ph_nodecision): (- rfalse; -) - in to only.
To rule succeeds
	(documented at ph_succeeds):
	(- RulebookSucceeds(); rtrue; -) - in to only.
To rule fails
	(documented at ph_fails):
	(- RulebookFails(); rtrue; -) - in to only.
To rule succeeds with result (val - a value)
	(documented at ph_succeedswith):
	(- RulebookSucceeds({-strong-kind:rule-return-kind},{-return-value-from-rule:val}); rtrue; -) - in to only.
To decide if rule succeeded
	(documented at ph_succeeded):
	(- (RulebookSucceeded()) -).
To decide if rule failed
	(documented at ph_failed):
	(- (RulebookFailed()) -).
To decide which rulebook outcome is the outcome of the rulebook
	(documented at ph_rulebookoutcome):
	(- (ResultOfRule()) -).

Chapter 9 - Basic Input/Output

Section 1 - Saying Fonts and Visual Effects

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

To say reverse mode -- running on:
	(- VM_SetReverseMode(1); -).
To say reverse mode off -- running on:
	(- VM_SetReverseMode(0); -).

Section 2 - Basic Colours

To set the foreground/-- colour/color/-- to (C - basic colour):
	(- VM_SetWindowColours({C}, BASIC_COLOUR_CURRENT); -).

To say (C - basic colour) letters:
	(- VM_SetWindowColours({C}, BASIC_COLOUR_CURRENT); -).

To set the background colour/color/-- to (C - basic colour):
	(- VM_SetWindowColours(BASIC_COLOUR_CURRENT, {C}); -).

To reset the screen/window colours/colors:
	(- VM_SetWindowColours(BASIC_COLOUR_DEFAULT, BASIC_COLOUR_DEFAULT); -).

To say default colours/colors:
	(- VM_SetWindowColours(BASIC_COLOUR_DEFAULT, BASIC_COLOUR_DEFAULT); -).

Section 3 - RGB Colours (for Glulx only)

RGB colour is a kind of value.
#<red level><green level><blue level> specifies a RGB colour with parts
	red level (2 hexadecimal digits),
	green level (2 hexadecimal digits) and
	blue level (2 hexadecimal digits).

To set the foreground/-- colour/color/-- to (C - RGB colour):
	(- VM_SetWindowColours({C}, BASIC_COLOUR_CURRENT); -).

To say (C - RGB colour) letters:
	(- VM_SetWindowColours({C}, BASIC_COLOUR_CURRENT); -).

To set the background colour/color/-- to (C - RGB colour):
	(- VM_SetWindowColours(BASIC_COLOUR_CURRENT, {C}); -).

Section 4 - Basic Window Effects

To clear the/-- screen:
	(- VM_ClearScreen(0); -).

To clear only/-- the/-- main screen:
	(- VM_ClearScreen(2); -).

To clear only/-- the/-- status line:
	(- VM_ClearScreen(1); -).

To decide what number is the/-- screen height:
	(- VM_ScreenHeight() -).

To decide what number is the/-- screen width:
	(- VM_ScreenWidth() -).

Section 5 - Pausing the game

[ Exclude navigation keys ]
To wait for any key:
	while 1 is 1:
		let code be the code of the next pressed key;
		if code is:
			-- the down key:
				next;
			-- the page down key:
				next;
			-- the page up key:
				next;
			-- the up key:
				next;
			-- unicode U+003F [?, which might be used for an unknown character]:
				next;
			-- otherwise:
				break;

[ Technically the space or return key ]
To wait for the/-- SPACE key/bar:
	while 1 is 1:
		let code be the code of the next pressed key;
		if code is:
			-- unicode U+0020 [space]:
				break;
			-- the return key:
				break;

To pause the game/story:
	say "[paragraph break]Please press SPACE to continue.";
	wait for the space key;
	clear the screen;

To stop the game/story abruptly:
	(- quit; -).

To show the/-- current quotation:
	(- ClearBoxedText(); -).

Section 6 - Keyboard Input

To decide what unicode character is the code of the next pressed key:
	(- VM_KeyChar() -).

To prompt the player to enter a line of text:
	(- VM_ReadKeyboard(buffer2); -).

To say the/-- player's text input:
	(- VM_PrintBuffer(buffer2); -).



The delete key is always unicode U+0008. [Both the Z-Machine and Glulx standards call it the delete key, even though backspace is perhaps more accurate.]
The down key is always unicode U+2193.
The end key is always unicode U+21F2.
The escape key is always unicode U+001B.
The f1 key is always unicode U+EF01.
The f2 key is always unicode U+EF02.
The f3 key is always unicode U+EF03.
The f4 key is always unicode U+EF04.
The f5 key is always unicode U+EF05.
The f6 key is always unicode U+EF06.
The f7 key is always unicode U+EF07.
The f8 key is always unicode U+EF08.
The f9 key is always unicode U+EF09.
The f10 key is always unicode U+EF0A.
The f11 key is always unicode U+EF0B.
The f12 key is always unicode U+EF0C.
The home key is always unicode U+21F1.
The left key is always unicode U+2190.
The page down key is always unicode U+21DF.
The page up key is always unicode U+21DE.
The return key is always unicode U+000A.
The right key is always unicode U+2192.
The tab key is always unicode U+0009.
The unknown key is always unicode U+FFFD.
The up key is always unicode U+2191.

Section 7 - The Status Window

To redraw the/-- status bar/line/window:
	(- DrawStatusLine(); -).

The status window table is a table-name that varies.
The status window table variable translates into Inter as "status_window_table".

To fill/redraw the/-- status bar/line/window with (new status table - a table-name), once only:
	let old status window table be the status window table;
	now the status window table is new status table;
	redraw the status window;
	if once only:
		now the status window table is the old status window table;

To move the status bar/line/window cursor to row (row - number) and/-- column/col (col - number):
	(- VM_MoveCursorInStatusLine({row}, {col}); -).

To set the status bar/line/window to (rows - number) row/rows:
	(- VM_StatusLineHeight({rows}); -).

Chapter 10 - External Files (not for Z-machine)

Section 1 - Files of Text

To write (T - text) to (FN - external file)
	(documented at ph_writetext):
	(- FileIO_PutContents({FN}, {T}, false); -).
To append (T - text) to (FN - external file)
	(documented at ph_appendtext):
	(- FileIO_PutContents({FN}, {T}, true); -).
To say text of (FN - external file)
	(documented at ph_saytext):
	(- FileIO_PrintContents({FN}); say__p = 1; -).

Section 2 - Files of Data

To read (filename - external file) into (T - table name)
	(documented at ph_readtable):
	(- FileIO_GetTable({filename}, {T}); -).
To write (filename - external file) from (T - table name)
	(documented at ph_writetable):
	(- FileIO_PutTable({filename}, {T}); -).

Section 3 - File Handling

To decide if (filename - external file) exists
	(documented at ph_fileexists):
	(- (FileIO_Exists({filename}, false)) -).
To decide if ready to read (filename - external file)
	(documented at ph_fileready):
	(- (FileIO_Ready({filename}, false)) -).
To mark (filename - external file) as ready to read
	(documented at ph_markfileready):
	(- FileIO_MarkReady({filename}, true); -).
To mark (filename - external file) as not ready to read
	(documented at ph_markfilenotready):
	(- FileIO_MarkReady({filename}, false); -).

Chapter 11 - Use Options

Section 1 - Numerical Value

To decide what number is the numerical value of (U - a use option):
	(- USE_OPTION_VALUES-->({U}) -).

Part Four - Glulx and Glk (for Glulx only)

Chapter - Version numbers

To decide which number is the major version of (V - version number):
	(- (VERSION_NUMBER_TY_Extract({V}, 0)) -).
To decide which number is the minor version of (V - version number):
	(- (VERSION_NUMBER_TY_Extract({V}, 1)) -).
To decide which number is the patch version of (V - version number):
	(- (VERSION_NUMBER_TY_Extract({V}, 2)) -).

Chapter - Glk and Glulx feature testing

Definition: a glk feature is supported rather than unsupported if I6 routine
	"GlkFeatureTest" says so (it is supported by the interpreter).

To decide what version number is the glk version number/--
	(documented at ph_glkversion):
	(- VERSION_NUMBER_TY_NewFromPacked(Cached_Glk_Gestalts-->gestalt_Version) -).

Definition: a glulx feature is supported rather than unsupported if I6 routine
	"GlulxFeatureTest" says so (it is supported by the interpreter).

To decide what version number is the glulx version number/--:
	(- VERSION_NUMBER_TY_NewFromPacked(Cached_Glulx_Gestalts-->GLULX_GESTALT_GlulxVersion) -).

To decide what version number is the interpreter version number/--:
	(- VERSION_NUMBER_TY_NewFromPacked(Cached_Glulx_Gestalts-->GLULX_GESTALT_TerpVersion) -).

Chapter - Glk windows

A Glk window is a kind of abstract object.
The glk window kind is accessible to Inter as "K_Glk_Window".
The specification of a glk window is "Models the Glk window system."

A glk window has a glk window type called the window type.
The window type property translates into Inter as "glk_window_type".

A glk window has a number called the rock number.
The rock number property translates into Inter as "glk_rock".

A glk window has a number called the glk window handle.
The glk window handle property translates into Inter as "glk_ref".

Definition: a glk window is on-screen rather than off-screen if the glk window handle of it is not 0.

A graphics window is a kind of glk window.
The window type of a graphics window is graphics window type.
A text buffer window is a kind of glk window.
The window type of a text buffer window is text buffer window type.
A text grid window is a kind of glk window.
The window type of a text grid window is text grid window type.

The main window is a text buffer window.
The main window object is accessible to Inter as "Main_Window".

The status window is a text grid window.
The status window object is accessible to Inter as "Status_Window".

The quote window is a text buffer window.
The quote window object is accessible to Inter as "Quote_Window".

Section - Glk windows

To clear (win - a glk window)
	(documented at ph_glkwindowclear):
	(- WindowClear({win}); -).

To focus (win - a glk window)
	(documented at ph_glkwindowfocus):
	(- WindowFocus({win}); -).

To decide what number is the height of (win - a glk window)
	(documented at ph_glkwindowheight):
	(- WindowGetSize({win}, 1) -).

To decide what number is the width of (win - a glk window)
	(documented at ph_glkwindowwidth):
	(- WindowGetSize({win}, 0) -).

To set (win - a glk window) cursor to row (row - a number) and/-- column/col (col - a number)
	(documented at ph_glksetcursor):
	(- WindowMoveCursor({win}, {col}, {row}); -).

Chapter - Glk events

To decide what glk event is (evtype - glk event type) glk event:
	(- GLK_EVENT_TY_New({-new: glk event}, {evtype}) -).

To decide what glk event is a/-- character event with (C - unicode character):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_CharInput, 0, MapUnicodeToGlkKeyCode({C})) -).
To decide what glk event is a/-- character event with (C - unicode character) in (win - glk window)
	(documented at ph_glkcharacterevent):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_CharInput, {win}, MapUnicodeToGlkKeyCode({C})) -).

To decide what glk event is a/-- line event with (T - text):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_LineInput, 0, 0, 0, {-by-reference:T}) -).
To decide what glk event is a/-- line event with (T - text) in (win - glk window)
	(documented at ph_glklineevent):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_LineInput, {win}, 0, 0, {-by-reference:T}) -).

To decide what glk event is a/-- mouse event for/of/with x (x - number) and/-- y (y - a number) coordinates/--:
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, 0, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with x (x - number) and/-- y (y - a number) coordinates/-- in (win - glk window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, {win}, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with row (y - number) and/-- column/col (x - a number):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, 0, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with row (y - number) and/-- column/col (x - a number) in (win - glk window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, {win}, {x}, {y}) -).

To decide what glk event is a/-- hyperlink event for/of/with (val - number):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_Hyperlink, 0, {val}) -).
To decide what glk event is a/-- hyperlink event for/of/with (val - number) in (win - glk window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_Hyperlink, {win}, {val}) -).

To decide what glk event type is type of (ev - glk event)
	(documented at ph_glkeventtype):
	(- GLK_EVENT_TY_Type({ev}) -).

To decide what glk window is window of (ev - glk event)
	(documented at ph_glkeventwindow):
	(- GLK_EVENT_TY_Window({ev}) -).

To decide what unicode character is the character value of (ev - glk event)
	(documented at ph_glkeventcharactervalue):
	(- GLK_EVENT_TY_Value1({ev}) -).

To decide what number is the x coordinate of (ev - glk event):
	(- GLK_EVENT_TY_Value1({ev}) -).
To decide what number is the y coordinate of (ev - glk event):
	(- GLK_EVENT_TY_Value2({ev}) -).
To decide what number is the row of (ev - glk event):
	(- GLK_EVENT_TY_Value2({ev}) -).
To decide what number is the column of (ev - glk event):
	(- GLK_EVENT_TY_Value1({ev}) -).

To decide what number is the hyperlink value of (ev - glk event):
	(- GLK_EVENT_TY_Value1({ev}) -).

To decide what text is the text of (ev - glk event)
	(documented at ph_glkeventtextvalue):
	(- GLK_EVENT_TY_Text({ev}, {-new: text}) -).

The glk event handling rules is a glk event type based rulebook.
The glk event handling rules is accessible to Inter as "GLK_EVENT_HANDLING_RB".

The glk event handling rulebook has a glk event called the event.

The current glk event initialiser is a glk event variable.
The current glk event initialiser variable is defined by Inter as "current_glk_event".

First glk event handling rule for a glk event type
	(this is the set glk event processing variables rule):
	now the event is the current glk event initialiser.

To process (ev - glk event):
	(- GLK_EVENT_TY_Process({ev}); rtrue; -).

Glk event handling rule for a screen resize event (this is the redraw the status line rule):
	redraw the status window;

Chapter - Hyperlinks

A hyperlink tag is a kind of value.

The hyperlink handling rules is a hyperlink tag based rulebook.
The hyperlink handling rules is accessible to Inter as "HYPERLINK_HANDLING_RB".

The handle hyperlinks rule is listed in the glk event handling rules.
The handle hyperlinks rule is defined by Inter as "HANDLE_HYPERLINK_R".

To say link (T - hyperlink tag):
	(- MakeTaggedHyperlink({T}); -).

To say link (T - hyperlink tag) for/of/with (V - value of kind K):
	(- MakeTaggedHyperlink({T}, {-by-reference:V}, {-strong-kind:K}); -).

To say end link:
	(- if (Cached_Glk_Gestalts-->gestalt_Hyperlinks) { glk_set_hyperlink(0); } -).

To decide what K is hyperlink value as a/an (name of kind of value K):
	(- (hyperlink_value) -).


Rule hyperlink is a hyperlink tag.

To say link (R - rule):
	(- MakeTaggedHyperlink((+ rule hyperlink +), {-by-reference:R}, RULE_TY); -).

Hyperlink handling rule for a rule hyperlink (this is the rule hyperlink rule):
	follow hyperlink value as a rule;

Keypress hyperlink is a hyperlink tag.

To say link (C - unicode character):
	(- MakeTaggedHyperlink((+ keypress hyperlink +), {-by-reference:C}, UNICODE_CHARACTER_TY); -).

Hyperlink handling rule for a keypress hyperlink (this is the keypress hyperlink rule):
	process a character event for (hyperlink value as a unicode character) in (window of the current glk event);

Chapter - Suspending and resuming input

A glk window has a text input status.
The text input status property translates into Inter as "text_input_status".
A glk window can be requesting mouse input.
The requesting mouse input property translates into Inter as "requesting_mouse".

To suspend text input in (win - a glk window), without input echoing:
	(- SuspendTextInput({win}, {phrase options}); -).

To resume text input in (win - a glk window):
	(- ResumeTextInput({win}); -).

To decide what text is the current line input of (w - glk window):
	(- WindowBufferCopyToText({w}, {-new:text}) -).

To set the current line input of (w - glk window) to (t - text):
	(- WindowBufferSet({w}, {-by-reference:t}); -).

Chapter - Glk object recovery

The current glk object rock number is a number that varies.
The current glk object rock number variable translates into Inter as "current_glk_object_rock".
The current glk object reference number is a number that varies.
The current glk object reference number variable translates into Inter as "current_glk_object_reference".

The reset glk references rules is a rulebook.
The reset glk references rules is accessible to Inter as "RESET_GLK_REFERENCES_RB".
The identify glk windows rules is a rulebook.
The identify glk windows rules is accessible to Inter as "IDENTIFY_WINDOWS_RB".
The identify glk streams rules is a rulebook.
The identify glk streams rules is accessible to Inter as "IDENTIFY_STREAMS_RB".
The identify glk filerefs rules is a rulebook.
The identify glk filerefs rules is accessible to Inter as "IDENTIFY_FILEREFS_RB".
The identify glk sound channels rules is a rulebook.
The identify glk sound channels rules is accessible to Inter as "IDENTIFY_SCHANNELS_RB".
The glk object updating rules is a rulebook.
The glk object updating rules is accessible to Inter as "GLK_OBJECT_UPDATING_RB".

The reset glk references for built in objects rule is listed first in the reset glk references rules.
The reset glk references for built in objects rule translates into Inter as "RESET_GLK_REFERENCES_R".

The cache gestalts rule is listed in the reset glk references rules.
The cache gestalts rule translates into Inter as "CACHE_GESTALTS_R".

The identify built in windows rule is listed first in the identify glk windows rules.
The identify built in windows rule translates into Inter as "IDENTIFY_WINDOWS_R".

The identify built in streams rule is listed first in the identify glk streams rules.
The identify built in streams rule translates into Inter as "IDENTIFY_STREAMS_R".

The identify built in filerefs rule is listed first in the identify glk filerefs rules.
The identify built in filerefs rule translates into Inter as "IDENTIFY_FILEREFS_R".

The identify built in sound channels rule is listed first in the identify glk sound channels rules.
The identify built in sound channels rule translates into Inter as "IDENTIFY_SCHANNELS_R".

The stop built in sound channels rule is listed in the glk object updating rules.
The stop built in sound channels rule translates into Inter as "STOP_SCHANNELS_R".

Part Five - Adjectival Definitions

Section 1 - Miscellaneous Useful Adjectives

Definition: a number is even rather than odd if the remainder after dividing it by 2 is 0.
Definition: a number is positive if it is greater than zero.
Definition: a number is negative if it is less than zero.

Definition: a text is empty rather than non-empty if I6 routine
	"TEXT_TY_Empty" says so (it contains no characters).

Definition: a text is substituted rather than unsubstituted if I6 routine
	"TEXT_TY_IsSubstituted" says so (any square-bracketed text substitutions
	in it have been made).

Definition: a table name is empty rather than non-empty if the number of filled rows in it is 0.
Definition: a table name is full rather than non-full if the number of blank rows in it is 0.

Definition: a nothing based rulebook is empty rather than non-empty if I6 routine
	"RulebookEmpty" says so (it contains no rules, so that following it does
	nothing and makes no decision).

Definition: an activity on nothing is empty rather than non-empty if I6 routine
	"ActivityEmpty" says so (its before, for and after rulebooks are all empty).
Definition: an activity on nothing is going on if I6 routine "TestActivity" says so (one
	of its three rulebooks is currently being run).

Definition: a list of values is empty rather than non-empty if I6 routine
	"LIST_OF_TY_Empty" says so (it contains no entries).

Definition: a use option is active rather than inactive if I6 routine
	"TestUseOption" says so (it has been requested in the source text).

Definition: a verb is modal rather than non-modal if I6 routine "VerbIsModal"
	says so (it modifies the likelihood of another verb happening, rather than
	being meaningful itself).

Definition: a verb is meaningful rather than meaningless if I6 routine "VerbIsMeaningful"
	says so (it has a meaning in Inform as a relation, rather than existing only to be
	printed out).

Section 2 - Adjectives for Relations

Definition: a relation is equivalence if I6 routine
	"RELATION_TY_EquivalenceAdjective" makes it so (it is an equivalence
	relation, that is, it relates in groups).

Definition: a relation is symmetric if I6 routine
	"RELATION_TY_SymmetricAdjective" makes it so (it is a symmetric relation,
	that is, it's always true that X is related to Y if and only if Y is
	related to X).

Definition: a relation is one-to-one if I6 routine
	"RELATION_TY_OToOAdjective" makes it so (it is a one-to-one relation,
	that is, any given X can relate to only one Y, and vice versa).

Definition: a relation is one-to-various if I6 routine
	"RELATION_TY_OToVAdjective" makes it so (it is a one-to-various
	relation, that is, any given Y has only one X such that X relates to Y).

Definition: a relation is various-to-one if I6 routine
	"RELATION_TY_VToOAdjective" makes it so (it is a various-to-one
	relation, that is, any given X relates to only one Y).

Definition: a relation is various-to-various if I6 routine
	"RELATION_TY_VToVAdjective" makes it so (it is a
	various-to-various relation, that is, there are no limitations on how many
	X can relate to a given Y, or vice versa).

Definition: a relation is empty rather than non-empty if I6 routine
	"RELATION_TY_Empty" makes it so (it does not relate any values, that is,
	R(x,y) is false for all x and y).

Section 3 - Adjectives for Real Numbers (not for Z-machine)

Definition: a real number is positive if it is greater than zero.
Definition: a real number is negative if it is less than zero.
Definition: a real number is infinite rather than finite if it is plus infinity
	or it is minus infinity.
Definition: a real number is nonexistent rather than existent if I6 routine
	"REAL_NUMBER_TY_Nan" says so (it results from an impossible calculation,
	like the square root of minus one).

Basic Inform ends here.

---- DOCUMENTATION ----

Unlike other extensions, Basic Inform is compulsorily included with every
project. It defines the phrases, kinds and relations which are basic to
Inform, and which are described throughout the documentation.

