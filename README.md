# Inform 7

v10.1.0-beta+6U93 'Krypton' (28 April 2022)

## About Inform 7

Inform 7 (April 2006-) is a programming language for creating interactive
fiction, using natural language syntax. Using natural language and drawing on
ideas from linguistics and from literate programming, Inform is widely
used as a medium for literary writing, as a prototyping tool in the games
industry, and in education, both at school and university level (where
Inform is often assigned material for courses on digital narrative).
It has several times ranked in the top 100 most influential programming
languages according to the TIOBE index.

Inform is itself a literate program, one of the largest in the world. This
means that a complete presentation of the code, in human-readable form, is
continuously maintained alongside the code itself. So to read this, along with
technical documentation and other useful resources, turn to the companion
web page to this repository: &#9733; [Inform: The Program](https://ganelson.github.io/inform)

Writing and presenting Inform as a literate program was beyond the capabilities
of existing LP software, so a new system for LP called Inweb
has been spun off from Inform, and that has [its own repository](https://github.com/ganelson/inweb).

__Disclaimer__. Because this is a private repository (until the next public
release of Inform, when it will open), its GitHub pages server cannot be
enabled yet. As a result links marked &#9733; lead only to raw HTML
source, not to served web pages. They can in the mean time be browsed offline
as static HTML files stored in "docs".

## Licence and copyright

Except as noted, copyright in material in this repository (the "Package") is
held by Graham Nelson (the "Author"), who retains copyright so that there is
a single point of reference. As from the first date of this repository
becoming public, 28 April 2022, the Package is placed under the
[Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).
This is a highly permissive licence, used by Perl among other notable projects,
recognised by the Open Source Initiative as open and by the Free Software
Foundation as free in both senses.

For the avoidance of doubt, the Author makes the further grant that users of
the Package may make unlimited use of story files produced by the Package:
such story files are not derivative works of Inform and do not inherit the
Artistic License 2.0 as an obligation. (This further grant follows the
practice of projects like bison, which also copy substantial code into
their outputs.)

A condition of any pull-request being made (i.e., to make suggested amendments
to this software) is that, if the request is accepted, copyright on any contribution
made by it immediately transfers to the project's copyright-holder, Graham Nelson.
This is in order that there can be clear ownership. It does not apply to the
programs duplicated here from other repositories (such as dumb-frotz) or to the
Inform GUI apps: those have their own copyrights and licences.

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
	* [https://github.com/ptomato/inform7-ide](https://github.com/ptomato/inform7-ide) for Linux, maintained by [Philip Chimento](https://github.com/ptomato)

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
which runs nearly 2500 cases through the executables, but takes 10 minutes
on an 8-core desktop and half an hour on a 4-core laptop (which will sound
something like a helicopter taking off).

Current status: All tests should pass on Linux, MacOS and Windows.

## Reporting Issues

The old Inform bug tracker, powered by Mantis, has now closed, and its issues
and comments have been migrated to the new one, powered by Jira and hosted
[at the Atlassian website](https://inform7.atlassian.net/jira/software/c/projects/I7/issues).

The curator of the bug tracker is Brian Rushton, and the administrator is
Hugo Labrande.

Note that Inweb and Intest have their own bug trackers
([here](https://inform7.atlassian.net/jira/software/c/projects/INWEB/issues)
and [here](https://inform7.atlassian.net/jira/software/c/projects/INTEST/issues)).
Please do not report bugs on those to the Inform tracker, or vice versa.

## Pull Requests and Adding Features

Inform is only just emerging into the light of being open-source, but it is not
new software. It has a mature and well-used feature set, so that new or changed
functionality requires careful thought. For the moment, its future direction
remains in the hands of the original author. At some point a more formal process
may emerge, but for now community discussion of possible features is best kept
to the IF forum. In particular, please do not use the bug trackers to propose
new features.

Pull requests adding functionality or making any significant changes are therefore
not likely to be accepted from non-members of the Inform team without prior
agreement, unless they are clear-cut bug fixes or corrections of typos, broken
links, or similar. See also the note about copyright above.

The Inform licence is highly permissive, and forks which develop in quite different
ways are entirely within the rules. (But one of the few requirements of the
Artistic Licence is that such forks be given a name which is not simply "Inform 7",
to avoid confusion.)

## Inventory

**"I can't help feeling that if someone had asked me before the universe began
how it would turn out, I should have guessed something a bit less like an old
curiosity shop and a bit more like a formal French garden - an orderly
arrangement of straight avenues, circular walks, and geometrically shaped
trees and hedges."** (Michael Frayn)

Inform is not a single program, but an assemblage of programs and resources.
Some, including the inform7 compiler itself, are "literate programs", also
called "webs". The notation &#9733; marks these, and links are provided to
their human-readable forms. (This will be enabled when the repository
becomes public: GitHub Pages does not work on private repositories.)

### Source for command-line tools

This most important contents of this repository are the source webs for the
following command-line tools:

* inbuild - __version 10.1.0__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inbuild/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inbuild/M-ui.html)<br>A simple build and package manager for the Inform tools.
* inform7 - __version 10.1.0__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inform7/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inform7/M-cu.html)<br>The core compiler in a natural-language design system for interactive fiction.
* inter - __version 10.1.0__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inter/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inter/M-ui.html)<br>For handling intermediate Inform code.
* inblorb - __version 4__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inblorb/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inblorb/M-ui.html)<br>The packaging stage of the Inform 7 system, which releases a story file in the blorbed format.
* indoc - __version 4__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/indoc/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/indoc/M-iti.html)<br>The documentation-formatter for the Inform 7 system.
* inpolicy - __version 1__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inpolicy/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inpolicy/M-ui.html)<br>A lint-like tool to check up on various policies used in Inform source code.
* inrtps - __version 2__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inrtps/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inrtps/M-ui.html)<br>A generator of HTML pages to show for run-time problem messages in Inform.

### Kits shipped with Inform

The following webs are the source for kits of Inter code shipped with Inform (at the subtree inform7/Internal/Inter). Kits are libraries of code needed at run-time, and whose source is written in Inform 6 notation:

* BasicInformKit - Support for Inform as a programming language - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/BasicInformKit/index.html)
* WorldModelKit - Support for modelling space, time and actions in interactive fiction - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/WorldModelKit/index.html)
* EnglishLanguageKit - Support for English as the natural language used - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/EnglishLanguageKit/index.html)
* CommandParserKit - Support for parsing turn-by-turn commands in interactive fiction - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/CommandParserKit/index.html)
* BasicInformExtrasKit - Additional support needed only if the Standard Rules are not used - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/BasicInformExtrasKit/index.html)

### Extensions shipped with Inform

The following webs are the source for the two most important extensions shipped with Inform:

* [Basic Inform by Graham Nelson](inform7/extensions/basic_inform) - __v1__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/basic_inform/index.html)
* [Standard Rules by Graham Nelson](inform7/extensions/standard_rules) - __v6__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/standard_rules/index.html)

Other extensions shipped with Inform are not presented as webs, but as single files:

* [Basic Help Menu by Emily Short](<inform7/Internal/Extensions/Emily Short/Basic Help Menu.i7x>) - __v1__
* [Basic Screen Effects by Emily Short](<inform7/Internal/Extensions/Emily Short/Basic Screen Effects.i7x>) - __v8__
* [Complex Listing by Emily Short](<inform7/Internal/Extensions/Emily Short/Complex Listing.i7x>) - __v9__
* [Glulx Entry Points by Emily Short](<inform7/Internal/Extensions/Emily Short/Glulx Entry Points.i7x>) - __v11__
* [Glulx Image Centering by Emily Short](<inform7/Internal/Extensions/Emily Short/Glulx Image Centering.i7x>) - __v4__
* [Glulx Text Effects by Emily Short](<inform7/Internal/Extensions/Emily Short/Glulx Text Effects.i7x>) - __v6__
* [Inanimate Listeners by Emily Short](<inform7/Internal/Extensions/Emily Short/Inanimate Listeners.i7x>) - __v1__
* [Locksmith by Emily Short](<inform7/Internal/Extensions/Emily Short/Locksmith.i7x>) - __v13__
* [Menus by Emily Short](<inform7/Internal/Extensions/Emily Short/Menus.i7x>) - __v3__
* [Punctuation Removal by Emily Short](<inform7/Internal/Extensions/Emily Short/Punctuation Removal.i7x>) - __v5__
* [Skeleton Keys by Emily Short](<inform7/Internal/Extensions/Emily Short/Skeleton Keys.i7x>) - __v1__
* [Epistemology by Eric Eve](<inform7/Internal/Extensions/Eric Eve/Epistemology.i7x>) - __v9__
* [Approximate Metric Units by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Approximate Metric Units.i7x>) - __v1__
* [English Language by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/English Language.i7x>) - __v1__
* [Metric Units by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Metric Units.i7x>) - __v2__
* [Rideable Vehicles by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Rideable Vehicles.i7x>) - __v3__
* [Unicode Character Names by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Unicode Character Names.i7x>) - __v1__
* [Unicode Full Character Names by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Unicode Full Character Names.i7x>) - __v1__

### Website templates and interpreters shipped with Inform

These are templates used by Inform to release story files within a website:

* [Classic](inform7/Internal/Templates/Classic.i7x) - An older, plainer website
* [Standard](inform7/Internal/Templates/Standard.i7x) - The default, more modern look

These are Javascript interpreters used to release such websites in a form which can play the story files interactively online:

* inform7/Internal/Templates - Template websites for Inform 7's 'release as a website' feature
* inform7/Internal/Templates/Parchment - Z-machine in Javascript - __Parchment for Inform 7 (2022.4)__ - from [https://github.com/curiousdannii/parchment], maintained by [Dannii Willis](https://github.com/curiousdannii)
* inform7/Internal/Templates/Quixe - Glulx in Javascript - __Quixe for Inform 7 (v. 2.2.0)__ - from [https://github.com/erkyrath/quixe], maintained by [Andrew Plotkin](https://github.com/erkyrath)

### Documentation shipped with Inform

Two books come with the Inform apps. The source code for these books is in indoc format: the indoc tool makes those into ePubs, mini-websites, or the pseudo-websites inside the apps.

* __Changes to Inform__ - A detailed change history of Inform 7. Ebook in Indoc format, stored at path resources/Changes.
* __Writing with Inform and the Inform Recipe Book__ - The main Inform documentation, as seen in the apps, and in standalone Epubs. Ebook in Indoc format, stored at path resources/Documentation.

In addition, there are:

* resources/Outcome Pages - Inrtps uses these to generate HTML outcome pages (such as those showing Problem messages in the app)
* resources/Sample Projects - Two small interactive fictions, 'Disenchantment Bay' and 'Onyx', presented as samples in the app

### Retrospective builds of Inform

New in 2022 is the ability for apps to use past instead of present versions of the
core Inform software when compiling a project. This means the core software distribution
needs to contain some form of those past versions - at minimum, the extensions and
compiler tools for (say) versions 9.1, 9.2 and 9.3.

That material is held in the "retrospective" directory. Note that documentation
from past versions (e.g., past versions of "Writing with Inform") is not included.

### Resources copied here from elsewhere

Stable versions of the following are periodically copied into this repository,
but this is not where development on them is done, and no pull requests will
be accepted. (Note that these are not git submodules.)

* inform6 - The Inform 6 compiler (used by I7 as a code generator). - __1636__ - from [https://github.com/DavidKinder/Inform6], maintained by [David Kinder](https://github.com/DavidKinder)
	* inform6/Tests/Assistants/dumb-frotz - A dumb-terminal Z-machine interpreter. - unversioned: modified from [Alembic Petrofsky's 1998 Teletype port of Frotz](https://github.com/sussman/ircbot-collection/tree/master/dumb-frotz)
	* inform6/Tests/Assistants/dumb-glulx/glulxe - A dumb-terminal Glulx interpreter. - __0.5.4__ - [erkyrath/glulxe](https://github.com/erkyrath/glulxe), maintained by [Andrew Plotkin](https://github.com/erkyrath)
	* inform6/Tests/Assistants/dumb-glulx/cheapglk - A basic Glk implementation to support dumb-glulxe. - __1.0.6.__ - [erkyrath/cheapglk](https://github.com/erkyrath/cheapglk), maintained by [Andrew Plotkin](https://github.com/erkyrath)

* inblorb/Tests/Assistants/blorblib - Code for examining blorb files, including blorbscan, used here for validating inblorb's output in tests. - version 1.0.2 - by [Andrew Plotkin](https://github.com/erkyrath), but not currently elsewhere on Github

### Binary resources (such as image files)

* resources/Imagery/app_images - icons for the Inform app and its many associated files, in MacOS format
* resources/Imagery/bg_images - background textures used in the Index generated by Inform
* resources/Imagery/doc_images - miscellaneous images needed by the documentation
* resources/Imagery/map_icons - images needed for the World pane of the Index generated by Inform
* resources/Imagery/outcome_images - images used on outcome pages
* resources/Imagery/scene_icons - images needed for the Scenes pane of the Index generated by Inform
* resources/Internal/Miscellany - default cover art, the Introduction to IF and Postcard PDFs

### Other files and folders in this repository

* docs - Woven forms of the webs, for serving by GitHub Pages
* scripts/inform.giscript - Inweb uses this to generate the .gitignore file at the root of the repository
* scripts/inform.mkscript - Inweb uses this to generate the makefile at the root of the repository
* scripts/inform.rmscript - Inweb uses this to generate the README.md file you are now reading

### Colophon

This README.mk file was generated automatically by Inweb, and should not
be edited. To make changes, edit inform.rmscript and re-generate.

