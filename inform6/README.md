# Inform 6

Inform 6 is a much earlier, more conventional programming language than
Inform 7. It is still used by the Inform toolchain, so it needs to be part
of this repository, but this is not its real home.

## Compiler

The directory |inform6| contains the most recent stable release made by the
[Inform 6 project](https://github.com/DavidKinder/Inform6), which is managed
by David Kinder. In an informal way, Andrew Plotkin is the lead developer.

The makefile for building this is inform6.mk, and places the executable in
the directory inform6/Tangled, just as if Inform 6 were an Inweb project -
though in fact it is not. It pre-dates everything else in the Inform toolchain,
and is not a literate program. To build just I6, set the working directory
to the outer inform6 directory, and then:

	make -f inform6/inform6.mk
	inform6/Tangled/inform6 -h

## Library

Stand-alone users of Inform 6 need a "library" of standing code in order to
get very much done: but the Inform 7 toolchain doesn't, and so no library
is included in this repository.

See [inform6lib](https://gitlab.com/DavidGriffith/inform6lib), or if you
have a minimalist bent, perhaps [PunyInform](https://github.com/johanberntsson/PunyInform).

## Test suite

A full-scale suite of tests for the Inform 6 compiler has been created by
Andrew Plotkin, and lives here: [Inform 6 compiler tests](https://github.com/erkyrath/Inform6-Testing).

This repository contains a conversion of that suite to use the Intest tool,
in line with other utilities in the Inform toolchain. See the Intest manual, but:

	../intest/Tangled/intest inform6 all

will run all (around 300) test cases, spreading the load across multiple cores
for speed. For example:

	../intest/Tangled/intest inform6 all
	inform6 -> cases: [1] [2] [3] [4] [5] [6] [7] [8] [9] [10] [11] [12] [13] [14] [15] [16] [17] [18] [19] [20] [21] [22] [23] [24] [25] [26] [27] [28] [29] [30] [31] [32] [33] [34] [35] [36] [37] [38] [39] [40] [41] [42] [43] [44] [45] [46] [47] [48] [49] [50] [51] [52] [53] [54] [55] [56] [57] [58] [59] [60] [61] [62] [63] [64] [65] [66] [67] [68] [69] [70] [71] [72] [73] [74] [75] [76] [77] [78] [79] [80] [81] [82] [83] [84] [85] [86] [87] [88] [89] [90] [91] [92] [93] [94] [95] [96] [97] [98] [99] [100] [101] [102] [103] [104] [105] [106] [107] [108] [109] [110] [111] [112] [113] [114] [115] [116] [117] [118] [119] [120] [121] [122] [123] [124] [125] [126] [127] [128] [129] [130] [131] [132] [133] [134] [135] [136] [137] [138] [139] [140] [141] [142] [143] [144] [145] [146] [147] [148] [149] [150] [151] [152] [153] [154] [155] [156] [157] [158] [159] [160] [161] [162] [163] [164] [165] [166] [167] [168] [169] [170] [171] [172] [173] [174] [175] [176] [177] [178] [179] [180] [181] [182] [183] [184] [185] [186] [187] [188] [189] [190] [191] [192] [193] [194] [195] [196] [197] [198] [199] [200] [201] [202] [203] [204] [205] [206] [207] [208] [209] [210] [211] [212] [213] [214] [215] [216] [217] [218] [219] [220] [221] [222] [223] [224] [225] [226] [227] [228] [229] [230] [231] [232] [233] [234] [235] [236] [237] [238] [239] [240] [241] [242] [243] [244] [245] [246] [247] [248] [249] [250] 
	inform6 -> problems: [251] [252] [253] [254] [255] [256] [257] [258] [259] [260] [261] [262] [263] [264] [265] [266] [267] [268] [269] [270] [271] [272] [273] [274] [275] [276] [277] [278] [279] [280] [281] [282] [283] [284] [285] [286] [287] [288] [289] [290] [291] [292] [293] [294] [295] [296] [297] [298] [299] [300] [301] [302] [303] [304] [305] [306] [307] 
	All 307 tests succeeded (time taken 0:04, 16 simultaneous threads)

Individual cases, such as large_object_short_name_test, can be run
like so:

	../intest/Tangled/intest inform6 large_object_short_name_test

To see the actual shell commands invoked, run with -verbose:

	../intest/Tangled/intest inform6 -verbose large_object_short_name_test

The test script is an Intest script called inform6.intest.

The tests themselves are divided in two: Test Cases contains those which are
expected to compile successfully, that is, where inform6 is expected to return
a successful exit code, and Test Errors, where it is expected to print errors
and return an unsuccessful exit. (Note that mere warnings do not do that.)

Each individual test is its own source file: for example, "box_quote_test.inf".
In Andrew Plotkin's original suite, the same source file is sometimes compiled
in anything up to a dozen or so different ways, making for multiple tests from
the same source file. But not here. Each individual test has its own name and
its own file. For example, the original test "forwardproptest.inf" is split
here into four: forwardproptest.inf, forwardproptest_ns-G.inf,
forwardproptest_ns.inf and forwardproptest-G.inf. Any test case whose name
ends "-G" is compiled to Glulx; all others are compiled to the Z-machine.

In addition, the test-setter can optionally specify two other things:

1. If the test is called NAME, the tester looks for _Settings/NAME.txt. If
this file exists, it is expected to contain the command-line options to give
to inform6. For example, it might read:

	-G -D $OMIT_UNUSED_ROUTINES=1

If no such file exists, then the settings are -G if the test name ends with
-G, and nothing at all if it doesn't.

2. If the test is called NAME, the tester looks for _Scripts/NAME.txt. If
this exists, it should be a list of typed commands, one per line, which are
piped through into the story file interpreter. Many of the tests here make
story files which print some text and then quit by themselves: a script is
needed only if the story expects command input.

The process of testing goes like this:

1. Run inform6 on the source file.

2. Write the console output (stdout and stderr combined) into _Console_Actual/NAME.txt.
This is expected to match _Console_Ideal/NAME.txt. If it doesn't, the test fails.
If the ideal output does not exist, the test halts saying so. Running the test
with the -bless option in Intest automatically trusts the actual console output
and copies it over to become the ideal. (-curse removes this; -rebless updates it
to a newer version.)

"Match" in this sense disregards (a) the inform6 version number as printed in
the opening line of its output, (b) the inform6 compilation date, and (c) the
duration in seconds of any abbreviation calculation output by the -u option.
For example:

	Inform 6.36 (24th January 2022)
	Beginning calculation of optimal abbreviations...
	Cross-reference table (70 entries) built...
	Pass 1
	Pass 1,    0/70 'tri' (7 occurrences)  (0.0000 seconds)	
	...

is deemed to match:

	Inform 6.39 (14th March 2027)
	Beginning calculation of optimal abbreviations...
	Cross-reference table (70 entries) built...
	Pass 1
	Pass 1,    0/70 'tri' (7 occurrences)  (0.0240 seconds)	
	...

3. Write an md5 hash of the story file to _md5_Actual/NAME.txt. This is the
same definition of "canonical hash" used by Andrew Plotkin's suite, which masks
off header bytes of the story file to do with date and version. Note that the
hashes produced here are identical to those produced by Andrew's Python script.

If the file _md5_Ideal/NAME.txt exists, the tester checks that the two match.
If they do, the test stops with a pass. The story file must be correct - it is
identical to a version known to be right. If they do not match, the test is
a fail.

4. So we only continue if there was no ideal hash. The story file is run either
through dumb-frotz or dumb-glulxe, command-line interpreters for our two
virtual machines. A command script is piped in if one has been provided (see
above). The transcript of output is stored in _Transcript_Actual/NAME.txt.
This is expected to match _Transcript_Ideal/NAME.txt. If it doesn't, the test fails.
If the ideal output does not exist, the test halts saying so. Running the test
with the -bless option in Intest automatically trusts the actual transcript
and copies it over to become the ideal. (-curse removes this; -rebless updates it
to a newer version.)

The suite contains transcripts even for those tests where ideal hashes are
provided: this is so that we can check that they are doing the right thing
even after a change to the compiler invalidates those hashes.

### Coverage and limitations

This test suite is a proper superset of the original, but please note:

1. large_opcode_text_test is not executed on dumb-frotz because the interpreter
cannot cope with the quantity of text in question, and would halt with a fatal
error. (But the test still checks the story file's md5.)

2. The two -k debugfile tests of Advent and the module compilation tests are
currently omitted. These are, barring accidents, the only aspects of any test
not faithfully reproduced from the original.
