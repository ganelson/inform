Using Inter.

Using Inter at the command line.

@h What Inter does.
The command-line executable Inter packages up the back end of the Inform 7
compiler into a stand-alone tool, and enables that back end to be used more
flexibly. For example, it can read or write either textual or binary inter
code, and can convert between them. It can also perform any of the numerous
code-generation stages on the code it reads, in any sequence. In short, it
aims to be a Swiss Army knife for inter code.

Because of that, it's possible to test code-generation stages individually:
we can read in some inter code from a text file, perform a single stage on
it, and write it out as text again. This gives us a very helpful window into
what Inform is doing; it also provides a test-bed for future optimisation,
or for future applications of inter code.

@h Command-line usage.
If you have compiled the standard distribution of the command-line tools
for Inform then the Inter executable will be at |inter/Tangled/inter|.
The usage is:

	|$ inter/Tangled/inter FILE1 FILE2 ... [OPTIONS]|

Though multiple files can be supplied, it's usual to supply just one.

Such files can be in either textual or binary form, and Inter automatically
detects which by looking at their contents. (Conventionally, such files
have the filename extension |.intert| or |.interb| respectively, but that's
not how Inter decides.)

@ Inter has three basic modes. In the first, when no options are supplied,
Inter simply verifies its input for correctness: that is, to see if the inter
code supplied conforms to the inter specification. It returns the exit code 0
if all is well, and issues error messages and returns 1 if not.

@ In the second mode, Inter converts from textual to binary form or vice
versa. The option |-binary X| writes a binary form of the inter to file |X|,
and |-textual X| writes a text form. So, for example,

	|$ inter/Tangled/inter my.intert -binary my.interb|

converts |my.intert| (a textual inter file) to its binary equivalent
|my.interb|, and conversely:

	|$ inter/Tangled/inter my.interb -textual my.intert|

@ In the third and most flexible mode, Inter runs the supplied code through
a "chain" of processing stages. The chain, which must contain at least
one stage, is a textual list of comma-separated stage names. For example,

	|resolve-conditional-compilation,assimilate,make-identifiers-unique|

is a valid three-stage chain. The command to do this is then:

	|$ inter/Tangled/inter my.intert -inter 'CHAIN'|

where |CHAIN| is the chain description.

In practice, this will only be useful if you can access the result, so it's
normal for the final stage to output something: perhaps Inform 6 code, perhaps
textual inter. For example:

	|$ inter/Tangled/inter in.intert -inter 'parse-linked-matter, generate-inter:out.intert'|

Two more options may be helpful to supplement this: |-domain D| sets the
directory |D| to be the default location for reading and writing inter files;
and |-template T| tells Inter that it can find the I6T template files at
the file system location |T|. (Some code-generation stages import these.)
