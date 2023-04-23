Using Inpolicy.

A very short guide to a very small program.

@h What Inpolicy is.
Inpolicy is a command-line tool whose sole purpose is to help keep the
Inform 7 source code tidy. Unlike Inweb, Intest and Indoc, this tool
can't sensibly be used for any project other than Inform.

If you have compiled the standard distribution of the command-line tools
for Inform then the Inpolicy executable will be at |inpolicy/Tangled/inpolicy|.
Usage is very simple:
= (text as ConsoleText)
	$ inpolicy/Tangled/inpolicy POLICY
=
where |POLICY| is whatever we want to check. There are very few at present;
in some ways this program is a placeholder for future tightening-up of the
style rules.

@ When it runs, Inpolicy needs to know where it is installed in the file
system. There is no completely foolproof, cross-platform way to know this
(on some Unixes, a program cannot determine its own location), so Inpolicy
decides by the following set of rules:

(a) If the user, at the command line, specified |-at P|, for some path
|P|, then we use that.
(b) Otherwise, if the host operating system can indeed tell us where the
executable is, we use that. This is currently implemented only on MacOS,
Windows and Linux.
(c) Otherwise, if the environment variable |$INPOLICY_PATH| exists and is
non-empty, we use that.
(d) And if all else fails, we assume that the location is |inpolicy|, with
respect to the current working directory.

If you're not sure what Inpolicy has decided and suspect it may be wrong,
running Inpolicy with the |-verbose| switch will cause it to print its belief
about its location as it starts up.

@h Policies.
|-check-problems| makes a survey of (a) all of the Problem messages issued
within the Inform 7 compiler, (b) all of the Problem test cases, and (c) all
of the advisory references to Problems in the Inform documentation, and
attempts to match these up. It prints out a report, and concludes with either
"All is well" or a recommendation for changes. For example:
= (text as ConsoleText)
	1009 problem name(s) have been observed:
	    Problems actually existing (the source code refers to them):
	        906 problem(s) are named and in principle testable
	        81 problem(s) are 'BelievedImpossible', that is, no known source text causes them
	        14 problem(s) are 'Untestable', that is, not mechanically testable
	        8 problem(s) are '...', that is, they need to be give a name and a test case
	    Problems which should have test cases:
	        904 problem(s) have test cases
	        2 problem(s) have no test case yet:
	            PM_SuperfluousOf
	            PM_MisplacedFrom
	    Problems which are cross-referenced in 'Writing with Inform':
	        483 problem(s) are cross-referenced
	All is well.
=
As this example report shows, small sins are forgiven.

@ |-kit-versions| reports the version numbers of the five kits built in to an
Inform installation. The policy here is that these should always have version
numbers exactly matching that of the core |inform7| version number; so the
option |-sync-kit-versions| is provided to enforce this, by changing the
version numbers of the kits accordingly.
