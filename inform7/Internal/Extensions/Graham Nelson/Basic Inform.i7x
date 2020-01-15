Version 1 of Basic Inform by Graham Nelson begins here.

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

Section 7 - Saying Fonts and Visual Effects

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

Section 8 - Saying Lists of Values

To say (L - a list of values) in brace notation
	(documented at phs_listbraced):
	(- LIST_OF_TY_Say({-by-reference:L}, 1); -).
To say (L - a list of objects) with definite articles
	(documented at phs_listdef):
	(- LIST_OF_TY_Say({-by-reference:L}, 2); -).
To say (L - a list of objects) with indefinite articles
	(documented at phs_listindef):
	(- LIST_OF_TY_Say({-by-reference:L}, 3); -).

Chapter 2

Section 1 - Making Conditions True

To now (cn - condition)
	(documented at ph_now):
	(- {cn} -).

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
To decide which number is (R - a real number) to the nearest whole number
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

To decide on (something - value)
	(documented at ph_decideon):
	(- return {-return-value:something}; -).

Chapter 4 - Values

Section 1 - Enumerations

To decide which number is number of (S - description of values)
	(documented at ph_numberof):
	(- {-primitive-definition:number-of} -).
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

Chapter 5 - Data Structures

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
To blank out the whole row
	(documented at ph_blankoutrow):
	(- TableBlankOutRow({-my:ct_0}, {-my:ct_1}); -).
To blank out the whole (TC - table column) in/from/of (T - table name)
	(documented at ph_blankoutcol):
	(- TableBlankOutColumn({T}, {TC}); -).
To blank out the whole of (T - table name)
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
	(- TableSort({T}, {TC}, 1); -).
To sort (T - table name) in/into reverse (TC - table column) order
	(documented at ph_sortcolumnreverse):
	(- TableSort({T}, {TC}, -1); -).

Section SR5/3/8 - Control phrases - Stop or go

To do nothing (documented at ph_nothing):
	(- ; -).
To stop (documented at ph_stop):
	(- rtrue; -) - in to only.

To decide what K is the default value of (V - name of kind of value of kind K)
	(documented at ph_defaultvalue):
	(- {-new:K} -).

Section SR5/2/6 - Values - Truth states

To decide what truth state is whether or not (C - condition)
	(documented at ph_whether):
	(- ({C}) -).

Basic Inform ends here.

---- DOCUMENTATION ----

Unlike other extensions, the Standard Rules are compulsorily included
with every project. They define the phrases, kinds and relations which
are basic to Inform, and which are described throughout the documentation.

