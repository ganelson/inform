@-> ../README.md
# Inform 7 @version(inform7)

## About Inform 7

Inform 7 (April 2006-) is a programming language for creating interactive
fiction, using natural language syntax. Using natural language and drawing on
ideas from linguistics and from literate programming, Inform is widely
used as a medium for literary writing, as a prototyping tool in the games
industry, and in education, both at school and university level (where
Inform is often assigned material for courses on digital narrative).
It has several times ranked in the top 100 most influential programming
languages according to the TIOBE index.

The architecture is as follows. The "front end" of Inform7 turns natural
language source text into an intermediate representation called "Inter".
The "back end", which can also be compiled as an independent tool also
called Inter, performs code generation to turn inter into Inform 6 code.
Inform 6, the final form of the original Inform project (1993-2001), then
compiles this to a "story file" for one of two virtual machines, "Glulx"
or "the Z-machine". On a release compilation, a further tool called Inblorb
packages this up as a stand-alone website or download.

__Disclaimer__. Because this is a private repository (until the next public
release of Inform, when it will open), its GitHub pages server cannot be
enabled yet. As a result links marked &#9733; below lead only to raw HTML
source, not to served web pages. They can in the mean time be browsed offline
as static HTML files stored in "docs".

## Licence

Except as noted, copyright in material in this repository (the "Package") is
held by Graham Nelson (the "Author"), who retains copyright so that there is
a single point of reference. As from the first date of this repository
becoming public, the Package is placed under the [Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).
This is a highly permissive licence, used by Perl among other notable projects,
recognised by the Open Source Initiative as open and by the Free Software
Foundation as free in both senses.

For the avoidance of doubt, the Author makes the further grant that users of
the Package may make unlimited use of story files produced by the Package:
such story files are not derivative works of Inform and do not inherit the
Artistic License 2.0 as an obligation. (This further grant follows the
practice of projects like bison, which also copy substantial code into
their outputs.)

## Repositories

This is the "core repository", holding source code for the compiler, and
for everything needed to run it on the command line. However:

* To build and test the compiler you also need Inweb and Intest, programs
spun out from the Inform project. These are __not included in the core
repository either as submodules or copies__, and have their own repositories.
	* [https://github.com/ganelson/inweb](https://github.com/ganelson/inweb), maintained by [Graham Nelson](https://github.com/ganelson)
	* [https://github.com/ganelson/intest](https://github.com/ganelson/intest), maintained by [Graham Nelson](https://github.com/ganelson)
* Most Inform authors use Inform as an app: for example, it is available
on the Mac App Store. While much of the UI design is the same across all
platforms, each app has its own code in its own repository. See:
	* [https://github.com/TobyLobster/Inform](https://github.com/TobyLobster/Inform) for MacOS, maintained by [Toby Nelson](https://github.com/TobyLobster)
	* [https://github.com/DavidKinder/Windows-Inform7](https://github.com/DavidKinder/Windows-Inform7) for Windows, maintained by [David Kinder](https://github.com/DavidKinder)
	* [https://github.com/ptomato/gnome-inform7](https://github.com/ptomato/gnome-inform7) for Linux, maintained by [Philip Chimento](https://github.com/ptomato)

## Build Instructions

Make a directory in which to work: let's call this "work". Then:

* Change the current directory to "work": "cd work"
* Build Inweb as "work/inweb": see its repository [here](https://github.com/ganelson/inweb)
* Build Intest as "work/intest": see its repository [here](https://github.com/ganelson/intest)
* Clone Inform as "work/inform": "git clone https://github.com/ganelson/inform.git"
* Change the current directory to this: "cd inform"
* Run a first-build script: "bash scripts/first.sh"
* Check executables have compiled: "inblorb/Tangled/inblorb -help"
* Run a single test case: "../intest/Tangled/intest inform7 -show Acidity".

If that passes, probably all is well. The definitive test is "make check",
which runs nearly 2000 cases through the executables, but takes 10 minutes
on an 8-core desktop and half an hour on a 4-core laptop (which will sound
something like a helicopter taking off).

## Inventory

**"I can't help feeling that if someone had asked me before the universe began
how it would turn out, I should have guessed something a bit less like an old
curiosity shop and a bit more like a formal French garden — an orderly
arrangement of straight avenues, circular walks, and geometrically shaped
trees and hedges."** (Michael Frayn)

Inform is not a single program, but an assemblage of programs and resources.
Some, including the inform7 compiler itself, are "literate programs", also
called "webs". The notation &#9733; marks these, and links are provided to
their human-readable forms. (This will be enabled when the repository
becomes public: GitHub Pages does not work on private repositories.)

### Resources for which this is the primary repository

This repository is where development is done on the following executables:

@define primary(program, language)
* @program - @purpose(@program) - __@version(@program)__ - [&#9733;&nbsp;Web](docs/@program/index.html)
@end
@define primaryd(program, language, doc)
* @program - @purpose(@program) - __@version(@program)__ - [&#9733;&nbsp;Web](docs/@program/index.html) - [&#9654;&nbsp;Documentation](docs/@program/@doc.html)
@end
@define primaryl(program, language, purp)
* @program - @purp - [&#9733;&nbsp;Web](docs/@program/index.html)
@end
@define book(title, path, topic)
* @title - @topic. Ebook in Indoc format, stored at path @path.
@end
@define extension(path)
	* @path - __@version(@path)__
@end
@primaryd(inform7, 'Web of InC', 'P-cu')
	* its modules [&#9733;&nbsp;words](docs/words-module/index.html), [&#9733;&nbsp;inflections](docs/inflections-module/index.html), [&#9733;&nbsp;syntax](docs/syntax-module/index.html), [&#9733;&nbsp;problems](docs/problems-module/index.html), [&#9733;&nbsp;linguistics](docs/linguistics-module/index.html), [&#9733;&nbsp;kinds](docs/kinds-module/index.html), [&#9733;&nbsp;core](docs/core-module/index.html), [&#9733;&nbsp;if](docs/if-module/index.html), [&#9733;&nbsp;multimedia](docs/multimedia-module/index.html), [&#9733;&nbsp;index](docs/index-module/index.html)
	* their unit test executables [&#9733;&nbsp;words-test](docs/words-test/index.html), [&#9733;&nbsp;inflections-test](docs/inflections-test/index.html), [&#9733;&nbsp;syntax-test](docs/syntax-test/index.html), [&#9733;&nbsp;problems-test](docs/problems-test/index.html), [&#9733;&nbsp;linguistics-test](docs/linguistics-test/index.html), [&#9733;&nbsp;kinds-test](docs/kinds-test/index.html)
@primaryd(inblorb, 'Web of InC', 'P-ui')
@primaryd(indoc, 'Web of InC', 'P-iti')
@primaryd(inpolicy, 'Web of InC', 'P-ui')
@primaryd(inrtps, 'Web of InC', 'P-ui')
@primaryd(inter, 'Web of InC', 'P-ui')
	* its modules [&#9733;&nbsp;inter](docs/inter-module/index.html), [&#9733;&nbsp;codegen](docs/codegen-module/index.html)

Two webs give detailed expositions of the most important built-in Inform extensions (at the subtree inform7/extensions):

@primary(basic_inform, 'Web of Inform 7')
@primary(standard_rules, 'Web of Inform 7')

This repository also contains kits of Inter code (at the subtree inform7/Internal/Inter). These are libraries of code needed at run-time, and whose source is written in Inform 6 notation:

@primaryl(BasicInformKit, 'Web of Inform 6', 'Support for Inform as a programming language')
@primaryl(WorldModelKit, 'Web of Inform 6', 'Support for modelling space, time and actions in interactive fiction')
@primaryl(EnglishLanguageKit, 'Web of Inform 6', 'Support for English as the natural language used')
@primaryl(CommandParserKit, 'Web of Inform 6', 'Support for parsing turn-by-turn commands in interactive fiction')
@primaryl(BasicInformExtrasKit, 'Web of Inform 6', 'Additional support needed only if the Standard Rules are not used')

The inform7 subtree further contains these primary resources:

* inform7/Internal/Extensions - Libraries of code. Inform 7
@extension('inform7/Internal/Extensions/Emily Short/Basic Help Menu.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Basic Screen Effects.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Complex Listing.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Glulx Entry Points.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Glulx Image Centering.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Glulx Text Effects.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Inanimate Listeners.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Locksmith.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Menus.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Punctuation Removal.i7x')
@extension('inform7/Internal/Extensions/Emily Short/Skeleton Keys.i7x')
@extension('inform7/Internal/Extensions/Eric Eve/Epistemology.i7x')
@extension('inform7/Internal/Extensions/Graham Nelson/Approximate Metric Units.i7x')
@extension('inform7/Internal/Extensions/Graham Nelson/English Language.i7x')
@extension('inform7/Internal/Extensions/Graham Nelson/Metric Units.i7x')
@extension('inform7/Internal/Extensions/Graham Nelson/Rideable Vehicles.i7x')
@extension('inform7/Internal/Extensions/Graham Nelson/Unicode Character Names.i7x')
@extension('inform7/Internal/Extensions/Graham Nelson/Unicode Full Character Names.i7x')
* inform7/Internal/HTML - Files needed for generating extension documentation and the like
* inform7/Internal/Languages - Natural language definition bundles
* inform7/Internal/Templates - Template websites for Inform 7's 'release as a website' feature
@define itemplate(program, for)
	* @program - @for - __@version(@program)__
@end
@itemplate('inform7/Internal/Templates/Classic', 'An older, plainer website')
@itemplate('inform7/Internal/Templates/Standard', 'The default, more modern look')

The "resources" directory holds a number of non-executable items of use to the
Inform UI applications, and to Inform websites:

@book('Changes to Inform', 'resources/Changes', 'A detailed change history of Inform 7')
@book('Writing with Inform and the Inform Recipe Book', 'resources/Documentation', 'The main Inform documentation, as seen in the apps, and in standalone Epubs')
* resources/Outcome Pages - Inrtps uses these to generate HTML outcome pages (such as those showing Problem messages in the app)
* resources/Sample Projects - Two small interactive fictions, 'Disenchantment Bay' and 'Onyx', presented as samples in the app. Inform 7

Finally, the "retrospective" directory holds ANSI C source and resources needed
to build (some) previous versions of Inform 7. At present, this is only sketchily
put together.

### Resources copied here from elsewhere

Stable versions of the following are periodically copied into this repository,
but this is not where development on them is done, and no pull requests will
be accepted. (Note that these are not git submodules.)

@define secondary(program, for, maintainer, username, repository)
* @program - @for - __@version(@program)__ - from [https://github.com/@username/@repository], maintained by [@maintainer](https://github.com/@username)
@end
@secondary(inform6, 'The Inform 6 compiler (used by I7 as a code generator).', 'David Kinder', DavidKinder, Inform6)
	* inform6/Tests/Assistants/dumb-frotz - A dumb-terminal Z-machine interpreter. - unversioned: modified from [Alembic Petrofsky's 1998 Teletype port of Frotz](https://github.com/sussman/ircbot-collection/tree/master/dumb-frotz)
	* inform6/Tests/Assistants/dumb-glulx/glulxe - A dumb-terminal Glulx interpreter. - __@version(inform6/Tests/Assistants/dumb-glulx/glulxe)__ - [erkyrath/glulxe](https://github.com/erkyrath/glulxe), maintained by [Andrew Plotkin](https://github.com/erkyrath)
	* inform6/Tests/Assistants/dumb-glulx/cheapglk - A basic Glk implementation to support dumb-glulxe. - __@version(inform6/Tests/Assistants/dumb-glulx/cheapglk)__ - [erkyrath/cheapglk](https://github.com/erkyrath/cheapglk), maintained by [Andrew Plotkin](https://github.com/erkyrath)

* inblorb/Tests/Assistants/blorblib - Code for examining blorb files, including blorbscan, used here for validating inblorb's output in tests. - version 1.0.2 - by [Andrew Plotkin](https://github.com/erkyrath), but not currently elsewhere on Github

@define template(program, for, maintainer, username, repository)
	* @program - @for - __@version(@program)__ - from [https://github.com/@username/@repository], maintained by [@maintainer](https://github.com/@username)
@end
* inform7/Internal/Templates - Template websites for Inform 7's 'release as a website' feature
@template('inform7/Internal/Templates/Parchment', 'Z-machine in Javascript', 'Dannii Willis', curiousdannii, parchment)
@template('inform7/Internal/Templates/Quixe', 'Glulx in Javascript', 'Andrew Plotkin', erkyrath, quixe)
@template('inform7/Internal/Templates/Vorple', 'Multimedia in Javascript', 'Juhana Leinonen', vorple, inform7)

### Binary resources (such as image files)

* resources/Imagery/app_images - icons for the Inform app and its many associated files, in MacOS format
* resources/Imagery/bg_images - background textures used in the Index generated by Inform
* resources/Imagery/doc_images - miscellaneous images needed by the documentation
* resources/Imagery/map_icons - images needed for the World pane of the Index generated by Inform
* resources/Imagery/outcome_images - images used on outcome pages
* resources/Imagery/scene_icons - images needed for the Scenes pane of the Index generated by Inform
* resources/Internal/Miscellany - default cover art, the Introduction to IF and Postcard PDFs

### Other files and folders in this repository

* docs - Woven forms of the webs, for serving by GitHub Pages (**not yet added**)
* scripts/gitignorescript.txt - Inweb uses this to generate the .gitignore file at the root of the repository
* scripts/makescript.txt - Inweb uses this to generate a makefile at the root of the repository
* scripts/READMEscript.txt - Inpolicy uses this to generate the README.md file for the repository

### Colophon

This README.mk file was generated automatically by Inpolicy, and should not
be edited. To make changes, edit scripts/READMEscript.txt and re-generate.

@-> ../docs/webs.html
@define web(program, manual)
	<li>
		<p>&#9733; <a href="@program/index.html"><spon class="sectiontitle">@program</span></a> -
		@version(@program)
		- <span class="purpose">@purpose(@program)</span>
		Documentation is <a href="@program/@manual.html">here</a>.</p>
	</li>
@end
@define webt(program, purp)
	<li>
		<p>&#9733; <a href="@program/index.html"><spon class="sectiontitle">@program</span></a> -
		<span class="purpose">@purp</span></p>
	</li>
@end
@define xweb(program)
	<li>
		<p>&#9733; <a href="@program/index.html"><spon class="sectiontitle">@program</span></a> -
		@version(inform7/extensions/@program)
		- <span class="purpose">@purpose(inform7/extensions/@program)</span></p>
	</li>
@end
@define subweb(owner, program)
	<li>
		<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;↳ &#9733; <a href="@program/index.html"><spon class="sectiontitle">@program</span></a> -
		<span class="purpose"><i>@purpose(@owner/@program) (Not compiled in Inform itself.)</i></span></p>
	</li>
@end
@define mod(owner, module)
	<li>
		<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;↳ &#9733; <a href="@module-module/index.html"><spon class="sectiontitle">@module</span></a> (module of inform7) -
		<span class="purpose">@purpose(@owner/@module-module)</span></p>
	</li>
@end
@define modi(owner, module)
	<li>
		<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;↳ &#9733; <a href="@module-module/index.html"><spon class="sectiontitle">@module</span></a> (module of both inform7 and inter) -
		<span class="purpose">@purpose(@owner/@module-module)</span></p>
	</li>
@end
@define extweb(program, explanation)
	<li>
		<p>&#9733; <a href="../../@program/docs/webs.html"><spon class="sectiontitle">@program</span></a> -
		@explanation</p>
	</li>
@end
<html>
	<head>
		<title>Inform &#9733; Webs for ganelson/inform</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta http-equiv="Content-Language" content="en-gb">
		<link href="inblorb/inweb.css" rel="stylesheet" rev="stylesheet" type="text/css">
	</head>

	<body>
		<ul class="crumbs"><li><a href="https://github.com/ganelson/inform"><b>&#9733 Webs for ganelson/inform</b></a></li></ul>
		<p class="purpose">Human-readable source code.</p>
		<hr>
		<p class="chapter">
This GitHub project was written as a literate program, powered by a LP tool
called Inweb. While almost all programs at Github are open to inspection, most
are difficult for new readers to navigate, and are not structured for extended
reading. By contrast, a "web" (the term goes back to Knuth: see
<a href="https://en.wikipedia.org/wiki/Literate_programming">Wikipedia</a>)
is designed to be read by humans in its "woven" form, and to be compiled or
run by computers in its "tangled" form.
These pages showcase the woven form, and are for human eyes only.</p>
		<hr>
		<p class="chapter">The main Inform 7 compiler, front end and back end:</p>
		<ul class="sectionlist">
			@web('inform7', 'P-cu')
			@mod('inform7', 'words')
			@subweb('inform7', 'words-test')
			@mod('inform7', 'inflections')
			@subweb('inform7', 'inflections-test')
			@mod('inform7', 'syntax')
			@subweb('inform7', 'syntax-test')
			@mod('inform7', 'problems')
			@subweb('inform7', 'problems-test')
			@mod('inform7', 'linguistics')
			@subweb('inform7', 'linguistics-test')
			@mod('inform7', 'kinds')
			@subweb('inform7', 'kinds-test')
			@mod('inform7', 'core')
			@mod('inform7', 'if')
			@mod('inform7', 'multimedia')
			@mod('inform7', 'index')
			@web('inter', 'P-ui')
			@modi('inter', 'inter')
			@modi('inter', 'building')
			@modi('inter', 'codegen')
		</ul>
		<hr>
		<p class="chapter">The two extensions (though their use is compulsory) which, though themselves written in Inform, create the Inform language:</p>
		<ul class="sectionlist">
			@xweb('basic_inform')
			@xweb('standard_rules')
		</ul>
		<hr>
		<p class="chapter">The kits of Inter code which support low-level features of the language:</p>
		<ul class="sectionlist">
			@webt('BasicInformKit', 'support for Inform as a programming language.')
			@webt('WorldModelKit', 'support for modelling space, time and actions in interactive fiction.')
			@webt('EnglishLanguageKit', 'support for English as the natural language used.')
			@webt('CommandParserKit', 'support for parsing turn-by-turn commands in interactive fiction.')
			@webt('BasicInformExtrasKit', 'additional support needed only if the Standard Rules are not used.')
		</ul>
		<hr>
		<p class="chapter">Other webs in this repository:</p>
		<ul class="sectionlist">
			@web('inblorb', 'P-ui')
			@web('indoc', 'P-iti')
			@web('inpolicy', 'P-ui')
			@web('inrtps', 'P-ui')
		</ul>
		<hr>
		<p class="chapter">Rekated webs in other repositories:</p>
		<ul class="sectionlist">
			@extweb('intest', 'A tool used for testing some of the above.')
			@extweb('inweb', 'The literate programming tool needed to compile the above: also includes the Foundation module of standard code used in all the above.')
		</ul>
		<hr>
	</body>
</html>
