S/inrtps: The inrtps Manual.

A manual for inrtps, the generator for run-time problem message
HTML pages (displayed by the interface application when an RTP occurs).

@ |inrtps| is a command line tool which reads a file of the text of all the
run-time problem messages, combines this with a model HTML file, and uses
these to generate a set of HTML files, one for each problem.

@ Code compiled by I7 will sometimes throw a run-time problem: for
instance, if the story file tries to divide by 0. The story file will print
up a run-time problem message of a very concise kind, like so:

	|*** Run-time problem P17: You can't divide by zero.|

(|P17| is the ``code number'' for the message.) If the story file is
running in a typical interpreter, that will be the end of the matter, but
if it runs in the Inform application's built-in interpreter then the
appearance of such text will be noticed and will cause Inform to open a
suitably explanatory page in the panel alongside Game. This will be an HTML
page called

	|RTP_P17.html|

kept in a folder somewhere inside the application. Clearly there will be
a fair number of possible errors, and we don't want to have to build these
HTML pages by hand. |inrtps| automates their generation.

@ This is the simplest and least configurable of the tools in the
suite. It has two possible forms, thus:

	|inrtps from to -font|

	|inrtps from to -nofont|

The first two arguments are names of folders.

@ The |from| folder is expected to contain two files:

	|from/model.html|
	|from/texts.txt|

The texts file is a plain text file explaining each RTP in turn. The first
line of an RTP has a special format identifying it: the remaining lines
give the explanation, and a skipped (i.e., blank) line divides each RTP
from the next. For instance:

	|P17 - Can't divide by zero|
	|A number cannot be divided by 0: similarly, we cannot take the remainder|
	|after dividing something by 0.|

The model file is a standard HTML file, except that it can contain four
escape codes, which |inrtps| expands (in a |sed|-like fashion). Thus:

(a) |*1| expands to the code number of the message.
(b) |*2| expands to the full textual explanation.
(c) |*3| expands to a short title for the message.
(d) |*4| expands to font settings inside a |<font ...>| tag. (This will be
blank if |nofont| is set, or will choose a Helvetica-like font if |font| is
