# Inform 7

v10.1.0-alpha.1+6U37 'Krypton' (20 February 2022)

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

* inform7 - The core compiler in a natural-language design system for interactive fiction. - __10.1.0__ - [&#9733;&nbsp;Web](docs/inform7/index.html) - [&#9654;&nbsp;Documentation](docs/inform7/M-cu.html)
	* its modules [&#9733;&nbsp;inflections](docs/inflections-module/index.html), [&#9733;&nbsp;problems](docs/problems-module/index.html), [&#9733;&nbsp;linguistics](docs/linguistics-module/index.html), [&#9733;&nbsp;kinds](docs/kinds-module/index.html), [&#9733;&nbsp;core](docs/core-module/index.html), [&#9733;&nbsp;if](docs/if-module/index.html), [&#9733;&nbsp;multimedia](docs/multimedia-module/index.html), [&#9733;&nbsp;index](docs/index-module/index.html)
	* their unit test executables [&#9733;&nbsp;inflections-test](docs/inflections-test/index.html), [&#9733;&nbsp;problems-test](docs/problems-test/index.html), [&#9733;&nbsp;linguistics-test](docs/linguistics-test/index.html), [&#9733;&nbsp;kinds-test](docs/kinds-test/index.html)
* inblorb - The packaging stage of the Inform 7 system, which releases a story file in the blorbed format. - __4__ - [&#9733;&nbsp;Web](docs/inblorb/index.html) - [&#9654;&nbsp;Documentation](docs/inblorb/M-ui.html)
* inbuild - A simple build and package manager for the Inform tools. - __1__ - [&#9733;&nbsp;Web](docs/inbuild/index.html) - [&#9654;&nbsp;Documentation](docs/inbuild/M-ui.html)
	* its modules [&#9733;&nbsp;inbuild](docs/inbuild-module/index.html), [&#9733;&nbsp;arch](docs/arch-module/index.html), [&#9733;&nbsp;html](docs/html-module/index.html), [&#9733;&nbsp;words](docs/words-module/index.html), [&#9733;&nbsp;syntax](docs/syntax-module/index.html)
	* two unit test executables [&#9733;&nbsp;words-test](docs/words-test/index.html), [&#9733;&nbsp;syntax-test](docs/syntax-test/index.html)
* indoc - The documentation-formatter for the Inform 7 system. - __4__ - [&#9733;&nbsp;Web](docs/indoc/index.html) - [&#9654;&nbsp;Documentation](docs/indoc/M-iti.html)
* inpolicy - A lint-like tool to check up on various policies used in Inform source code. - __1__ - [&#9733;&nbsp;Web](docs/inpolicy/index.html) - [&#9654;&nbsp;Documentation](docs/inpolicy/M-ui.html)
* inrtps - A generator of HTML pages to show for run-time problem messages in Inform. - __2__ - [&#9733;&nbsp;Web](docs/inrtps/index.html) - [&#9654;&nbsp;Documentation](docs/inrtps/M-ui.html)
* inter - For handling intermediate Inform code. - __1__ - [&#9733;&nbsp;Web](docs/inter/index.html) - [&#9654;&nbsp;Documentation](docs/inter/M-ui.html)
	* its modules [&#9733;&nbsp;inter](docs/inter-module/index.html), [&#9733;&nbsp;codegen](docs/codegen-module/index.html)

Two webs give detailed expositions of the most important built-in Inform extensions (at the subtree inform7/extensions):

* basic_inform -  - ____ - [&#9733;&nbsp;Web](docs/basic_inform/index.html)
* standard_rules -  - ____ - [&#9733;&nbsp;Web](docs/standard_rules/index.html)

This repository also contains kits of Inter code (at the subtree inform7/Internal/Inter). These are libraries of code needed at run-time, and whose source is written in Inform 6 notation:

* BasicInformKit - Support for Inform as a programming language - [&#9733;&nbsp;Web](docs/BasicInformKit/index.html)
* WorldModelKit - Support for modelling space, time and actions in interactive fiction - [&#9733;&nbsp;Web](docs/WorldModelKit/index.html)
* EnglishLanguageKit - Support for English as the natural language used - [&#9733;&nbsp;Web](docs/EnglishLanguageKit/index.html)
* CommandParserKit - Support for parsing turn-by-turn commands in interactive fiction - [&#9733;&nbsp;Web](docs/CommandParserKit/index.html)
* BasicInformExtrasKit - Additional support needed only if the Standard Rules are not used - [&#9733;&nbsp;Web](docs/BasicInformExtrasKit/index.html)

The inform7 subtree further contains these primary resources:

* inform7/Internal/Extensions - Libraries of code. Inform 7
	* inform7/Internal/Extensions/Emily Short/Basic Help Menu.i7x - ____
	* inform7/Internal/Extensions/Emily Short/Basic Screen Effects.i7x - __7/140425__
	* inform7/Internal/Extensions/Emily Short/Complex Listing.i7x - __9__
	* inform7/Internal/Extensions/Emily Short/Glulx Entry Points.i7x - __10/140425__
	* inform7/Internal/Extensions/Emily Short/Glulx Image Centering.i7x - __4__
	* inform7/Internal/Extensions/Emily Short/Glulx Text Effects.i7x - __5/140516__
	* inform7/Internal/Extensions/Emily Short/Inanimate Listeners.i7x - ____
	* inform7/Internal/Extensions/Emily Short/Locksmith.i7x - __12__
	* inform7/Internal/Extensions/Emily Short/Menus.i7x - __3__
	* inform7/Internal/Extensions/Emily Short/Punctuation Removal.i7x - __5__
	* inform7/Internal/Extensions/Emily Short/Skeleton Keys.i7x - ____
	* inform7/Internal/Extensions/Eric Eve/Epistemology.i7x - __9__
	* inform7/Internal/Extensions/Graham Nelson/Approximate Metric Units.i7x - __1__
	* inform7/Internal/Extensions/Graham Nelson/English Language.i7x - __1__
	* inform7/Internal/Extensions/Graham Nelson/Metric Units.i7x - __2__
	* inform7/Internal/Extensions/Graham Nelson/Rideable Vehicles.i7x - __3__
	* inform7/Internal/Extensions/Graham Nelson/Unicode Character Names.i7x - ____
	* inform7/Internal/Extensions/Graham Nelson/Unicode Full Character Names.i7x - ____
* inform7/Internal/HTML - Files needed for generating extension documentation and the like
* inform7/Internal/Languages - Natural language definition bundles
* inform7/Internal/Templates - Template websites for Inform 7's 'release as a website' feature
	* inform7/Internal/Templates/Classic - An older, plainer website - ____
	* inform7/Internal/Templates/Standard - The default, more modern look - ____

The "resources" directory holds a number of non-executable items of use to the
Inform UI applications, and to Inform websites:

* Changes to Inform - A detailed change history of Inform 7. Ebook in Indoc format, stored at path resources/Changes.
* Writing with Inform and the Inform Recipe Book - The main Inform documentation, as seen in the apps, and in standalone Epubs. Ebook in Indoc format, stored at path resources/Documentation.
* resources/Outcome Pages - Inrtps uses these to generate HTML outcome pages (such as those showing Problem messages in the app)
* resources/Sample Projects - Two small interactive fictions, 'Disenchantment Bay' and 'Onyx', presented as samples in the app. Inform 7

Finally, the "retrospective" directory holds ANSI C source and resources needed
to build (some) previous versions of Inform 7. At present, this is only sketchily
put together.

### Resources copied here from elsewhere

Stable versions of the following are periodically copied into this repository,
but this is not where development on them is done, and no pull requests will
be accepted. (Note that these are not git submodules.)

* inform6 - The Inform 6 compiler (used by I7 as a code generator). - __1634__ - from [https://github.com/DavidKinder/Inform6], maintained by [David Kinder](https://github.com/DavidKinder)
	* inform6/Tests/Assistants/dumb-frotz - A dumb-terminal Z-machine interpreter. - unversioned: modified from [Alembic Petrofsky's 1998 Teletype port of Frotz](https://github.com/sussman/ircbot-collection/tree/master/dumb-frotz)
	* inform6/Tests/Assistants/dumb-glulx/glulxe - A dumb-terminal Glulx interpreter. - __0.5.4__ - [erkyrath/glulxe](https://github.com/erkyrath/glulxe), maintained by [Andrew Plotkin](https://github.com/erkyrath)
	* inform6/Tests/Assistants/dumb-glulx/cheapglk - A basic Glk implementation to support dumb-glulxe. - __1.0.6.__ - [erkyrath/cheapglk](https://github.com/erkyrath/cheapglk), maintained by [Andrew Plotkin](https://github.com/erkyrath)

* inblorb/Tests/Assistants/blorblib - Code for examining blorb files, including blorbscan, used here for validating inblorb's output in tests. - version 1.0.2 - by [Andrew Plotkin](https://github.com/erkyrath), but not currently elsewhere on Github

* inform7/Internal/Templates - Template websites for Inform 7's 'release as a website' feature
	* inform7/Internal/Templates/Parchment - Z-machine in Javascript - __Parchment for Inform 7 (2015-09-25)__ - from [https://github.com/curiousdannii/parchment], maintained by [Dannii Willis](https://github.com/curiousdannii)
	* inform7/Internal/Templates/Quixe - Glulx in Javascript - __Quixe for Inform 7 (v. 2.1.2)__ - from [https://github.com/erkyrath/quixe], maintained by [Andrew Plotkin](https://github.com/erkyrath)
	* inform7/Internal/Templates/Vorple - Multimedia in Javascript - __Vorple__ - from [https://github.com/vorple/inform7], maintained by [Juhana Leinonen](https://github.com/vorple)

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

This README.mk file was generated automatically by Inweb, and should not
be edited. To make changes, edit scripts/READMEscript.txt and re-generate.

