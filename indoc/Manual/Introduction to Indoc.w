Introduction to Indoc.

What Indoc is, and its limited but complicated uses.

@ Intest is a command line tool for generating (mainly) HTML or EPUB format
documentation. A million of those have been written, and Indoc has no
ambition to replace them. It is needed because Inform 7's documentation
source consists of many small text files with idiosyncratic markup, while
its formatted HTML version needs to be indexed in elaborate ways.

Indoc is a purely command-line tool, used in building Inform but not in
running it: it's not present in the Inform UI apps.

If you have compiled the standard distribution of the command-line tools
for Inform then the Indoc executable will be at |indoc/Tangled/indoc/|.
Usage is very simple:

	|$ indoc/Tangled/indoc [OPTIONS] TARGET|

By default, Indoc reads its source documentation from a direction called
|Documentation| (with respect to the current working directory); the
option |-from X| changes this path to |X|, but in this manual we'll call
it |Documentation|.

In addition to documentation files, which will be described later, Indoc
also reads instruction files. At minimum it will read

	|Documentation/indoc-instructions.txt|

but the option |-instructions X| causes it to read |X| as well. Instructions
files mainly specify indexing notations, or CSS styles, or miscellaneous
settings, but they group these under named "targets". For example:

	|windows_app {|
	|	...|
	|}|

declares a target called |windows_app|. (This is the form of HTML needed for
use inside the Windows UI application for Inform.) The idea here is that
there is probably no single form of HTML needed -- it will be needed in
subtly different versions for different platforms: inside the app, as a
stand-alone website, inside an Epub ebook. These different forms are
called "targets". On any given run, Indoc generates a single target --
the one named on the command line.

The HTML produced is placed, by default, in the directory:

	|Documentation/Output|

This can be changed with the option |-to X|.

@ When it runs, Indoc needs to know where it is installed in the file
system. There is no completely foolproof, cross-platform way to know this
(on some Unixes, a program cannot determine its own location), so Indoc
decides by the following set of rules:

(a) If the user, at the command line, specified |-at P|, for some path
|P|, then we use that.
(b) Otherwise, if the host operating system can indeed tell us where the
executable is, we use that. This is currently implemented only on MacOS,
Windows and Linux.
(c) Otherwise, if the environment variable |$INDOC_PATH| exists and is
non-empty, we use that.
(d) And if all else fails, we assume that the location is |indoc|, with
respect to the current working directory.

If you're not sure what Indoc has decided and suspect it may be wrong,
running Indoc with the |-verbose| switch will cause it to print its belief
about its location as it starts up.

@ Perhaps the ugliest thing Indoc does is to rewrite the Standard Rules
extension, which comes supplied with Inform, so that its lines giving
cross-references to documentation contain accurate references. These
lines are special sentences such as:

	|Document kind_person at doc45 "3.17" "Men, women and animals".|

Indoc looks for a contiguous block of lines in the form

	|Document ... at doc12.|

and replaces it with a new block of lines containing up to date information.

This happens only if |-rewrite-standard-rules X| is specified, with |X| being
the filename of the Standard Rules.

@ As a program, Indoc began as a rat's nest of Perl in 2002, and you can still
see where the rats used to live. Like all too many quick-fix Perl scripts, it
was still in use ten years later. In 2012, I spent some time tidying it up to
generate better HTML, and made it a web (that is, a literate program). The
original had produced typically sloppy turn-of-the-century HTML, with tables
for layout and no CSS, and with many now-deprecated tags and elements. The
2012 edition, by contrast, needed to produce validatable XHTML 1.1 Strict in
order to make Epubs which read roughly correctly in today's ebook-readers, and
when they call this Strict they're not kidding. It took something like four
weeks of spare evenings.

Just as I was finishing up, John Siracusa described a not dissimilar task on
his then podcast (Hypercritical 85): "I was trying to think of a good analogy
for what happens when you're a programmer and you have this sort of task in
front of you. Is it, the cobbler's children have no shoes? ... You would
expect someone who is a programmer to make some awesome system which would
generate these three things. But when you're a programmer, you have the
ability to do whatever you want really, really quickly in the crappiest
possible way... And that's what I did. I wrote a series of incredibly
disgusting Perl scripts."

This made me feel better. (Also that, as it turned out, we both asked Liza
Daly for help when we got stuck trying to understand Epub: small world.)
Nevertheless, in 2016, Indoc was rewritten in C, using the then-new Foundation
library, and it received a further revision in 2019, when this documentation
was finally written, 17 years after the program it documents.
