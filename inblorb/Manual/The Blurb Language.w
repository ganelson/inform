The Blurb Language.

A specification for the Blurb language, which describes how to package up
a work of interactive fiction.

@h What Blurb is.
"Blurb" is a mini-language for specifying how the materials in a work
of IF should be packaged up for release. It was originally codified in 2001
as a standard way to describe how a blorb file should be put together, but
it was extended in 2005 and again in 2008 so that it could also organise
accompanying files released along with the blorb.

The original Blurb language was documented in chapter 43 of the DM4
(i.e., the "Inform Designer's Manual", fourth edition, 2001); for clarity,
we will call that language "Blurb 2001". Today's Blurb language is a little
different. Some features of Blurb 2001 are deprecated and no longer used,
while numerous other syntaxes are new. Because of this the DM4 specification
is no longer useful, so we will give a full description below of Blurb as
it currently stands.

@h Some simple examples.
This first script instructs Inblorb to carry out its mission -- it makes a
simple Blorb wrapping up a story file with bibliographic data, but nothing
more, and nothing else is released.
= (text as Blurb)
	storyfile "/Users/gnelson/Examples/Zinc.inform/Build/output.ulx" include
	ifiction "/Users/gnelson/Examples/Zinc.inform/Metadata.iFiction" include
=
These two lines tell Inblorb to include the story file and the iFiction
record respectively.

@ A more ambitious Blorb can be made like so:
= (text as Blurb)
	storyfile leafname "Audiophilia.gblorb"
	storyfile "/Users/gnelson/Examples/Audiophilia.inform/Build/output.ulx" include
	ifiction "/Users/gnelson/Examples/Audiophilia.inform/Metadata.iFiction" include
	cover "/Users/gnelson/Examples/Audiophilia Materials/Cover.png"
	picture 1 "/Users/gnelson/Examples/Audiophilia Materials/Cover.png"
	sound 3 "/Users/gnelson/Examples/Audiophilia Materials/Sounds/Powermac.aiff"
	sound 4 "/Users/gnelson/Examples/Audiophilia Materials/Sounds/Bach.ogg"
=
The cover image is included only once, but declaring it as picture 1 makes it
available to the story file for display internally as well as externally.
Resource ID 2, apparently skipped, is in fact the story file.

@ And here's a very short script, which makes Inblorb generate a solution
file from the Skein of a project:
= (text as Blurb)
	project folder "/Users/gnelson/Examples/Zinc.inform"
	release to "/Users/gnelson/Examples/Zinc Materials/Release"
	solution
=
This time no blorb file is made. The opening line tells Inblorb which Inform
project we're dealing with, allowing it to look at the various files inside --
its Skein, for instance, which is used to create a solution. The second line
tells Inblorb where to put all of its output -- everything it makes. Only
the third line directly causes Inblorb to do anything.

@ More ambitiously, this time we'll make a website for a project, but again
without making a blorb:
= (text as Blurb)
	project folder "/Users/gnelson/Examples/Audiophilia.inform"
	release to "/Users/gnelson/Examples/Audiophilia Materials/Release"
	placeholder [IFID] = "AD5648BA-18A2-48A6-9554-4F6C53484824"
	placeholder [RELEASE] = "1"
	placeholder [YEAR] = "2009"
	placeholder [TITLE] = "Audiophilia"
	placeholder [AUTHOR] = "Graham Nelson"
	placeholder [BLURB] = "A test project for sound effect production."
	template path "/Users/gnelson/Library/Inform/Templates"
	css
	website "Standard"
=
The first novelty here is the setting of placeholders. These are named pieces
of text which appear on the website being generated: where the text "[RELEASE]"
appears in the template, Inblorb writes the value we've set for it, in this
case "1". Some of these values look like numbers, but to Inblorb they all
hold text. A few placeholder names are reserved by Inblorb for its own use,
and it will produce errors if we try to set those, but none of those in
this example is reserved.

Template paths tell Inblorb where to find templates. Any number of these
can be set -- including none at all, but if so then commands needing a
named template, like |website|, can't be used. Inblorb looks for any
template it needs by trying each template path in turn (the earliest
defined having the highest priority). The blurb files produced by |inform7|
in its |-release| mode contain a chain of three template paths, for the
individual project folder, the user's library of installed templates, and
the built-in stock inside the Inform user interface application,
respectively.

The command |css| tells Inblorb that it is allowed to use CSS styles to
make its web pages more appealing to look at: this results in generally
better HTML, easier to use in other contexts, too.

All of that set things up so that the |website| command could be used,
which actually does something -- it creates a website in the release-to
location, taking its design from the template named. If we were to add
any of these commands --
= (text as Blurb)
	source public
	solution public
	ifiction public
=
-- then the website would be graced with these additions.

@ The previous examples all involved Inform projects, but Inblorb can also
deal with stand-alone files of Inform source text -- notably extensions.
For example, here we make a website out of an extension:
= (text as Blurb)
	release to "Test Site"
	placeholder [TITLE] = "Locksmith"
	placeholder [AUTHOR] = "Emily Short"
	placeholder [RUBRIC] = "Implicit handling of doors and... (...and so on)"
	template path "/Users/gnelson/Library/Inform/Templates"
	css
	release file "style.css" from "Extended"
	release file "index.html" from "Extended"
	release file "Extensions/Emily Short/Locksmith.i7x"
	release source "Extensions/Emily Short/Locksmith.i7x" using "extsrc.html" from "Extended"
=
This time we're using a template called "Extended", and the script tells
Inblorb exactly what to do with it. The "release file... from..." command
tells Inblorb to extract the named file from this template and to copy it
into the release folder -- if it's a ".html" file, placeholders are
substituted with their values. The simpler form, "release file ...", just
tells Inblorb to copy that actual file -- here, it puts a copy of the
extension itself into the release folder. The final line produces a run
of pages, in all likelihood, for the source and documentation of the
extension, with the design drawn from "Extended" again.

("Extended" isn't supplied inside Inform; it's a template we're using to
help generate the Inform website, rather than something meant for end users.
There's nothing very special about it, in any case.)

@h Specification of the Blurb language.
A blorb script should be a text file, using the Unicode character set and
encoded as UTF-8 without a byte order marker -- in other words, a plain
text file. It consists of lines of up to 10239 bytes in length each,
divided by any of the four line-end markers in common use (|CR|, |LF|,
|CR LF| or |LF CR|), though the same line-end marker should be used
throughout the file.

Each command occupies one and only one line of text. (In Blorb 2001, the
now-deprecated |palette| command could occupy multiple lines, but Inblorb
will choke on such a usage.) Lines are permitted to be empty or to contain
only white space. Lines whose first non-white-space character is an
exclamation mark are treated as comments, that is, ignored. "White space"
means spaces and tab characters. An entirely empty blurb file, containing
nothing but white space, is perfectly legal though useless.

In the following description:

|<string>| means any text within double-quotes, not
containing either double-quote or new-line characters, of up to 2048 bytes.

|<filename>| means any double-quoted filename.

|<number>| means a decimal number in the range 0 to 32767.

|<id>| means either nothing at all, or a |<number>|,
or a sequence of up to 20 letters, digits or underscore characters |_|.

|<dim>| indicates screen dimensions, and must take the form
|<number>||x||<number>|.

|<ratio>| is a fraction in the form
|<number>|/|<number>|. 0/0 is legal but
otherwise both numbers must be positive.

|<colour>| is a colour expressed as six hexadecimal digits,
as in some HTML tags: for instance |F5DEB3| is the colour of wheat, with red
value |F5| (on a scale |00|, none, to |FF|, full), green value |DE| and blue
value |B3|. Hexadecimal digits may be given in either upper or lower case.

@ The full set of commands is as follows. First, core commands for making
a blorb:
= (text as Blurb)
	author <string>
=
Adds this author name to the file.
= (text as Blurb)
	copyright <string>
=
Adds this copyright declaration to the blorb file. It would normally consist of
short text such as "(c) J. Mango Pineapple 2007" rather than a lengthy legal
discourse.
= (text as Blurb)
	release <number>
=
Gives this release number to the blorb file.
= (text as Blurb)
	auxiliary <filename> <string>
=
Tells us that an auxiliary file -- for instance, a PDF manual -- is associated
with the release but will not be embedded directly into the blorb file. For
instance,
= (text as Blurb)
	auxiliary "map.png" "Black Pete's treasure map"
=
The string should be a textual description of the contents. Every auxiliary
file should have a filename including an extension usefully describing its
format, as in ".png": if there is no extension, then the auxiliary resource
is assumed to be a mini-website housed in a subfolder with this name.
= (text as Blurb)
	ifiction <filename> include
=
The file should be a valid iFiction record for the work. This is an XML file
specified in the Treaty of Babel, a cross-IF-system standard for specifying
bibliographic data; it will be embedded into the blorb.
= (text as Blurb)
	storyfile <filename>    ... unsupported by Inblorb
	storyfile <filename> include
=
Specifies the filename of the story file which these resources are being
attached to. Blorb 2001 allowed for blorbs to be made which held everything
to do with the release except the story file; that way a release
might consist of one story file plus one Blorb file containing its pictures
and sounds. The Blorb file would then contain a note of the release number,
serial code and checksum of the associated story file so that an
interpreter can try to match up the two files at run-time. If the |include|
option is used, however, the entire story file is embedded within the Blorb
file, so that game and resources are all bound up in one single file.
Inblorb always does this, and does not support |storyfile| without
|include|.

@ Second, now-deprecated commands describing our ideal screen display:
= (text as Blurb)
	palette 16 bit    ... unsupported by Inblorb
	palette 32 bit    ... unsupported by Inblorb
	palette { <colour-1> ... <colour-N> }    ... unsupported by Inblorb
=
Blorb allows designers to signal to the interpreter that a particular
colour-scheme is in use. The first two options simply suggest that the
pictures are best displayed using at least 16-bit, or 32-bit, colours. The
third option specifies colours used in the pictures in terms of
red/green/blue levels, and the braces allow the sequence of colours to
continue over many lines. At least one and at most 256 colours may be
defined in this way. This is only a "clue" to the interpreter; see the
Blorb specification for details.
= (text as Blurb)
	resolution <dim>    ... unsupported by Inblorb
	resolution <dim> min <dim>    ... unsupported by Inblorb
	resolution <dim> max <dim>    ... unsupported by Inblorb
	resolution <dim> min <dim> max <dim>    ... unsupported by Inblorb
=
Allows the designer to signal a preferred screen size, in real pixels, in
case the interpreter should have any choice over this. The minimum and
maximum values are the extreme values at which the designer thinks the game
will be playable: they're optional, the default values being 0 by 0 and
infinity by infinity.

@ Third, commands for adding audiovisual resources:
= (text as Blurb)
	sound <id> <filename>
	sound <id> <filename> repeat <number>    ... unsupported by Inblorb
	sound <id> <filename> repeat forever    ... unsupported by Inblorb
	sound <id> <filename> music    ... unsupported by Inblorb
	sound <id> <filename> song    ... unsupported by Inblorb
=
Tells us to take a sound sample from the named file and make it the sound
effect with the given number. Most forms of |sound| are now deprecated:
repeat information (the number of repeats to be played) is meaningful
only with Z-machine version 3 story files using sound effects, and Inform 7
does not generate those; the |music| and |song| keywords specify unusual
sound formats. Nowadays the straight |sound| command should always
be used regardless of format.
= (text as Blurb)
	picture <id> <filename>
	picture <id> <filename> scale <ratio>    ... unsupported by Inblorb
	picture <id> <filename> scale min <ratio>    ... unsupported by Inblorb
	picture <id> <filename> scale <ratio> min <ratio>    ... unsupported by Inblorb
=
(and so on) is a similar command for images. In 2001, the image file was required
to be a PNG, but it can now alternatively be a JPEG.

Optionally, the designer can specify a scale factor at which the
interpreter will display the image -- or, alternatively, a range of
acceptable scale factors, from which the interpreter may choose its own
scale factor. (By default an image is not scaleable and an interpreter must
display it pixel-for-pixel.) There are three optional scale factors given:
the preferred scale factor, the minimum and the maximum allowed. The
minimum and maximum each default to the preferred value if not given, and
the default preferred scale factor is 1. Scale factors are expressed as
fractions: so for instance,
= (text as Blurb)
	picture "flag/png" scale 3/1
=
means "always display three times its normal size", whereas
= (text as Blurb)
	picture "backdrop/png" scale min 1/10 max 8/1
=
means"you can display this anywhere between one tenth normal size and
eight times normal size, but if possible it ought to be just its normal
size".

Inblorb does not support any of the scaled forms of |picture|. As with
the exotic forms of |sound|, they now seem pass\'e. We no longer need to
worry too much about the size of the blorb file, nor about screens with
very low resolution; an iPhone today has a screen resolution close to that
of a typical desktop of 2001.
= (text as Blurb)
	cover <filename>
=
specifies that this is the cover art; it must also be declared with a
|picture| command in the usual way, and must have picture ID 1.

@ Three commands help us to specify locations.
= (text as Blurb)
	project folder <filename>
=
Tells Inblorb to look for associated resources, such as the Skein file,
within this Inform project.
= (text as Blurb)
	release to <filename>
=
Tells Inblorb that all of its output should go into this folder. (Well,
except that the blorb file itself will be written to the location specified
in the command line arguments, but see the description above of how Inblorb
then contrives to move it.) The folder must already exist, and Inblorb
won't create it. Under some circumstances Inform will seem to be creating
the release folder if it doesn't already exist, but that's always the work
of |inform7|, not Inblorb.
= (text as Blurb)
	template path <filename>
=
Sets a search path for templates -- a folder in which to look for them. There
can be any number of template paths set, and Inblorb checks them in order
of declaration (i.e., most important first).

@ Next we come to commands for specifying what Inblorb should release.
At present it has seven forms of output: Blorb file, solution file, source
text, iFiction record, miscellaneous file, website and interpreter.

No explicit single command causes a Blorb file to be generated; it will be
made automatically if one of the above commands to include the story file,
pictures, etc., is present in the script, and otherwise not generated.
= (text as Blurb)
	solution
	solution public
=
causes a solution file to be generated in the release folder. The mechanism
for this is described in "Writing with Inform". The difference between
the two commands affects only a website also being made, if one is: a
public solution will be included in its links, thus being made available
to the public who read the website.
= (text as Blurb)
	ifiction
	ifiction public
=
is similar, but for the iFiction record of the project.
= (text as Blurb)
	source
	source public
=
is again similar, but here there's a twist. If the source is public, then
Inblorb doesn't just include it on a website: it generates multiple HTML
pages to show it off in HTML form, as well as including the plain text
original.

Miscellaneous files can be released like so:
= (text as Blurb)
	release file <filename>
=
Here Inblorb acts as no more than a file-copy utility; a verbatim copy of
the named file is placed in the release folder.

@ Finally we come to web pages.
= (text as Blurb)
	css
=
enables the use of CSS-defined styles within the HTML generated by Inblorb.
This has an especially marked effect when Inblorb is generating HTML
versions of Inform source text, and is a good thing. Unless there is
reason not to, every blurb script generating websites ought to contain
this command.
= (text as Blurb)
	release file <filename> from <template>
=
causes the named file to be found from the given template. If it can't be
found in that template, Inblorb tries to find it from a template called
"Standard". If it isn't there either, or Inblorb can't find any template
called "Standard" in any of its template paths (see above), then an
error message is produced. But if all goes well the file is copied into
the release folder. If it has the file extension ".html" (in lower case,
and using that exact form, i.e., not ".HTM" or some other variation)
then any placeholders in the file will be expanded with their values.
A few reserved placeholders have special effects, causing Inblorb to
expand interesting text in their places -- see "Writing with Inform"
for more on this.
= (text as Blurb)
	release source <filename>| using |<filename> from <template>
=
makes Inblorb convert the Inform source text in the first filename into a
suite of web pages using the style of the given file from the given template.
= (text as Blurb)
	website <template>
=
saves the best until last: it makes a complete website for an Inform project,
using the named template. This means that the CSS file is copied into place
(assuming |css| is used), the "index.html" is released from the template,
the source of the project is run through |release source| using "source.html"
from the template (assuming |source public| is used), and any extra files
specified in the template's "(extras.txt)" are released as well. See
"Writing with Inform" for more.

@ An optional addition for a website is to incorporate a playable-in-browser
form of the story, by base64-encoding the story file within a Javascript
wrapper, then calling an interpreter such as Parchment.

The encoding part is taken care of by:
= (text as Blurb)
	base64 <filename> to <filename>
=
This performs an RFC 1113-standard encoding on the binary file in (almost
always our story file) into a textual base-64 file out. The file is topped
and tailed with the text in placeholders |[BASESIXTYFOURTOP]| and |[BASESIXTYFOURTAIL]|,
allowing Javascript wrapper code to surround the encoded data.

The interpreter itself is copied into place in the Release folder in a
process rather like the construction of a website from a template. The
necessary blurb command is:
= (text as Blurb)
	interpreter <interpreter-name> <vm-letter>
=
Interpreter names are like template names; Inform often uses "Parchment".
The VM letter should be "g" if we need this to handle a Glulx story file
(blorbed up), or "z" if we need it to handle a Z-machine story file.
(This needs to be said because Inform doesn't have a way of knowing which
formats a given interpreter can handle; so it has to leave checking to
Inblorb to do. Thus, if an Inform user tries to release a Z-machine-only
interpreter with a Glulx story file, it's Inblorb which issues the error,
not Inform itself.)

@ Finally (really finally this time), three commands to do with the
"status" page, an HTML page written by Inblorb to report back on
what it has done. If requested, this is constructed for reading within
the Inform application -- it is not a valid HTML page in other
contexts, and expects to have access to Javascript functions provided
by Inform, and so on.
= (text as Blurb)
	status <template> <filename>
	status alternative <link to Inform documentation>
	status instruction <link to Inform source text>
=
The first simply requests the page to be made. It's made from a single
template file, but in exactly the same way that website pages are generated
from website templates -- that is, placeholders are expanded. The second
filename is where to write the result.

The other two commands allow Inform to insert information which Inblorb
otherwise has no access to: options for fancy release tricks not currently
being used (with links to the documentation on them), and links to source
text "Release along with..." sentences.
