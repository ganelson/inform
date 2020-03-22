Volumes and Instructions.

Dual- versus single-volume mode, and how to write instructions files.

@h Model.
Conceptually, an Indoc project has either one or two volumes. The source for
each volume is a single UTF-8 encoded plain text file. In the core Inform
repository, there are two volumes, with the files being

	|Documentation/Writing with Inform.txt|
	|Documentation/The Recipe Book.txt|

These are independent books, with individual titles. It would seem simpler
just to make them two different Indoc projects, but in dual-volume mode,
Indoc can generate joint contents pages, and provide crosswise HTML links
between the two volumes.

The project can also include a number of "Examples", each being a single
text file such as:

	|Documentation/Examples/Prague.txt|

which is the source for an Inform example called "The Prague Job".
(These same text files are also used by Intest to test that all of the code
samples included in the Inform documentation actually work as claimed.)
There can be any number of examples, including none; Inform currently has 468.

Each volume is divided into a series of chapters, and each chapter into a
series of sections. Examples are always placed at the ends of sections;
note that in dual-volume mode, examples are (mostly) present in both volumes,
giving them two different locations. Thus, "The Prague Job" appears in section
"More general linkages" of chapter "Scenes" of volume "Writing with Inform",
and also in section "Scripted Scenes" of chapter "Time and Plot" of volume
"The Recipe Book".

@h Project instructions.
The main instructions file for an Indoc project is, as noted earlier, at:

	|Documentation/indoc-instructions.txt|

An instruction file is a UTF-8 encoded plain text file. Single instructions
occupy single lines (i.e., line breaks are significant). A white-space line,
or a line whose first non-white-space character is a |#|, are ignored.

The file should begin by specifying one or two volumes, and then, if they
will contain Examples in the above sense, by giving the special |examples|
instruction. Inform opens thus:

	|volume: Writing with Inform|
	|volume: The Inform Recipe Book (RB) = The Recipe Book.txt|
	|examples|

But a simpler, single-volume project might have just:

	|volume: Pandemonium 2.0 for Fun and Profit|

Each volume has a title, and Indoc automatically generates an abbreviation
for it: by default, it takes the capital letters from the title, so that it
abbreviates "Writing with Inform" to WI. That same method would have made
turned "The Inform Recipe Book" into TIRB, but because we didn't want that,
we supplied our own abbreviation RB instead.

The third, also optional, part of a |volume| instruction specifies the
leafname of the documentation source file for it. By default, this will be
the title plus |.txt|: for example, |Writing with Inform.txt|. But we can
use |= X| to specify that it should be |X| instead.

Two other project instructions exist:

If the project will contain images, then they will be looked for in a list
of places. Top of the list is a directory internal to Indoc which includes
some navigation icons such as |arrow-up.png|. The instruction |images: X|
adds the directory |X| to this source list.

Lastly, the cover image for the project can be specified with an instruction
such as:

	|cover: combined_cover.png|

This specifies a leafname which must exist in one of the image sources
mentioned above.

@h Durham Core metadata.
If the project needs to generate Epub books, then these will need to have
some basic DC ("Durham Core") metadata supplied. For example:

	|dc:title: Inform - A Design System for Interactive Fiction|
	|dc:creator: Graham Nelson and Emily Short|
	|dc:subject: Interactive Fiction|
	|dc:identifier: wwi-rb-combined|

The instruction |dc:KEY: VALUE| supplies a DC key-value pair.

@h Targets.
The instructions file typically begins as above, but then goes into a
block of general settings or instructions (for which see below); and
eventually gets around to describing one or more targets. A target
looks like so:

	|IDENTIFIER {|
	|	...|
	|}|

where |IDENTIFIER| is its name. Targets, as noted in the introduction,
are different forms of the documentation we might need to produce: Inform,
for example, has targets called |plain|, |website|, |linux_app| and so on.
What's important here is not that these are written to different locations
on disc (though they are) but that they have finicky little differences
in settings. The |...| stretch of lines can specify these. For example:

	|ebook {|
	|	granularity = 2|
	|	examples_mode = open|
	|	follow: epub-css-tweaks.txt|
	|}|

makes two specific settings and one instruction, all applying only for the
target |ebook|.

@h Symbols.
The instruction |declare: SYMBOL| creates the symbol |SYMBOL|. These exist
so that we can mark certain paragraphs of documentation as being present in
only some of the targets.

For example, we might want Linux installation instructions to appear only
in the Linux version of a manual. To do that, we'll need the symbol:

	|linux_app {|
	|	...|
	|	declare: Linux|
	|	...|
	|}|

In the documentation, we could then mark up a paragraph like so:

	|{Linux:}To install, first...|

The symbol |indoc| is always declared, but by default no other symbols are.
Lastly, |undeclare: SYMBOL| removes a symbol.

@h Other instructions.
|follow: I| tells Indoc to follow the instructions file |I|. This works
rather like |#include| in C, or similar languages. If the |follow:| is
included inside a target block, then it affects only that target. On
other targets, the file |I| won't even be opened, and need never exist.

|css:| specifies additional CSS (Cascading Style Sheet) styling. This
will be needed only if, for example, unusual indexing features are used,
in which different categories of index entry need different visual styling.
For example,

	|css: span.indextitle ++ {|
	|	font-style: italic;|
	|}|

Here the material between the braces is pure CSS, not Indoc syntax. The
notation |++| here tells Indoc that an entirely new CSS style is being
created; |+| would supply new lines to an existing style.

|index: NOTATION = CATEGORY OPTION| defines a new indexing markup notation;
for example,

	|index: ^{@headword} = name (invert)|

says that markup notations like |^{@Andrew Plotkin}| put a name into the index,
which should be an index entry of category |name|, and should be inverted,
in that it will be alphabetised under "Plotkin, Andrew". The text |headword|
in the prototype is where the entry text should appear in the notation.

@h Miscellaneous settings.
There are a great many of these, but most are set to sensible defaults,
and it is not compulsory to set any of them. Lines such as

	|SETTING = VALUE|

change the default settings if need be. Here is an A-Z list; they're really
too miscellaneous to be grouped usefully by subject matter.

|alphabetization| sets the index sorting algorithm. The default is
|letter-by-letter|; the alternative is |word-by-word|. The difference is
that letter-by-letter would ignore word divisions and sort in the order
"peach", "peachpit", "peach tree"; whereas word-by-word would go for
"peach", "peach tree", "peachpit". 

|assume_Public_Library| can be |yes| or |no|. The default is |no|. This
specifies whether special HTML links to the Public Library will be valid;
outside of Inform UI apps, the answer is definitely no.

|change_logs_directory| is the path to a directory holding Inform release
change log files. By default, this will be |Documentation/Change Logs|.

|contents_leafname| is the (unextended) leafname to give the HTML contents
page. The default is |index|.

|contents_expandable| can be |yes| or |no|. The default is |no|. This sets
whether Javascript-powered "expand" buttons are to be used in the contents
page, and has effect only on the Midnight navigation design.

|css_source_file| is the filename of the CSS style sheet to use. The default
is the |base.css| file included in the Indoc distribution.

|definitions_filename| is the filename to use if you would like Indoc to
output a special file of Inform phrase definitions, for use by Inform itself
when it generates indexes. The default for this is |definitions.html|. This
has nothing to do with the |definitions_index_filename|.

|definitions_index_filename| is the leafname to use for the General Index
in the documentation. The default is |general_index.html|. This
has nothing to do with the |definitions_filename|.

|destination| is the directory into which output is generated. The default
is |Documentation/Output|. Note that specifying |-to X| at the command line
overrides this setting: if |-to| is used, |destination| is ignored.

|examples_directory| is the directory holding the Example files. The default
is |Documentation/Examples|.

|examples_alphabetical_leafname| is the leafname to use for the alphabetical
index of examples in the documentation. The default is |examples_alphabetical.html|.

|examples_granularity| is 1, 2, or 3. It can never be less than |granularity|,
and by default is equal to it. It specifies where examples should appear:
at the end of the relevant volume (1), chapter (2), or section (3).

|examples_mode| is |open| or |openable|, and is by default |open|. Open means
that an example has its full contents visible by default; openable means that
the contents are hidden behind a Javascript-powered button which causes them
to be revealed.

|examples_numerical_leafname| is the leafname to use for the numerical
index of examples in the documentation. The default is |examples_numerical.html|.

|examples_thematic_leafname| is the leafname to use for the thematic
index of examples in the documentation. The default is |examples_thematic.html|.

|format| is the most important of all the settings, and is |HTML| or |text|,
but by default |HTML| unless the target name is |plain|, in which case |text|.

|granularity| is 1, 2, or 3. The default is 3 unless the target is called
|webpage| or |plain|, in which case it is 1. This specifies how much the
documentation is broken down into pieces. 1 means "each volume in a single
HTML file"; 2 means "each chapter", 3 means "each section". Low granularity
means fewer but larger files, high granularity more but smaller files.

|html_for_Inform_application| can be |yes| or |no|. The default is |no|. This
specifies whether the HTML is for use inside the Inform UI application, and
can therefore use links with the special HTTP transports only available there.

|images_copy| can be |yes| or |no|. The default is |yes|. In this mode,
any needed image files are copied into place into the |images_path|. (The
alternative assumes they are already there, and should be used if |images_path|
is some URL external to the HTML being generated.)

|images_path| is where the generated HTML expects to find its image files.
The default is |~~/Images/|, where |~~| means the destination directory:
that is, the default is a subdirectory called |Images| of the destination.

|inform_definitions_mode| can be |yes| or |no|. The default is |no|. This
is cosmetic, and provides extra styling on lines of documentation giving the
syntax for Inform phrases.

|javascript| can be |yes| or |no|. The default is |yes|. This indicates
whetber Indoc is allowed to compile Javascript, or has to stick to inactive
HTML.

|javascript_paste_method| can be |none|, |Andrew| or |David|. The default
is |none|. The difference relates to how "paste Inform source" links are
implemented inside the Inform application: |Andrew| mode is suitable for
most platforms, but |David| is needed for Windows.

|link_to_extensions_index| is meaningful only if |html_for_Inform_application|
is set, and specifies the URL of the Extensions index inside the app.

|manifest_leafname| is meaningful only if |html_for_Inform_application|
is set, and is by default |manifest.txt|. This provides a cross-reference
list of files generated by Indoc.

|navigation| is the design used for navigation links in the HTML produced.
There are currently six designs, called |architect|, |lacuna|, |midnight|,
|roadsign|, |twilight|, and |unsigned|; the default is |roadsign|, though
inside the Inform applications, the design chosen is usually |architect|.
If the format is |text| not |HTML|, then the design is always |lacuna|.

|retina_images| can be |yes| or |no|. The default is |no|. This indicates
whether MacOS/iOS "retina" versions of the paste and create icons are
available: |paste@2x.png| and |create@2x.png| respectively.

|support_creation| can be |yes| or |no|. The default is |no|. This indicates
whether the Examples have a "create" button which creates a new Inform
project demonstrating them in action; this can only be done in the UI apps,
so it should always be |no| unless |html_for_Inform_application| is |yes|.

|suppress_fonts| can be |yes| or |no|. The default is |no|. If |yes|, this
strips out lists of fonts to use in CSS, leaving only whether they are
|monospace| or not.

|toc_granularity| is 1, 2, or 3. It can never be less than |granularity|,
and by default is 3. It shows the level of detail in the table of contents: 1
means volumes, 2 means volumes and chapters, 3 goes down to sections.

|top_and_tail| specifies a prototype HTML file to follow for the more
important HTML pages generated by Indoc. The default is not to. If
this exists, it can provide a surround for the HTML we generate -- for
example, it can contain website-specific navigation, or a banner across
the top. The prototype should somewhere include the text |[TEXT]|, and
this will be replaced with whatever Indoc generates.

|top_and_tail_sections| is the same as |top_and_tail|, but for individual
section files.

|treat_code_as_verbatim| can be |yes| or |no|. The default is |yes|. This
affects the styling of marked-up code material in documentation. Without
it, code markup is largely unavailable.

|wrapper| can be |EPUB|, |zip| or |none|. The default is |none|. The wrapper
is put around the whole mass of generated HTML; |EPUB| makes the result an
Epub-format ebook.

|XHTML| can be |yes| or |no|. The default is |no|. This forces the HTML we
produce to conform to XHTML 1.1 Strict. If the |wrapper| is |EPUB|, then
this is automatically set to |yes|.
