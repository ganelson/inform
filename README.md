# Inform 7

[Version](notes/versioning.md): 10.2.0-beta+6W67 'Krypton' (26 June 2023)

## About Inform

Inform is a programming language for creating interactive fiction, using natural
language syntax. Using natural language and drawing on ideas from linguistics
and from literate programming, Inform is widely used as a medium for literary
writing, as a prototyping tool in the games industry, and in education, both at
school and university level (where Inform is often assigned material for courses
on digital narrative). It has several times ranked in the top 100 most
influential programming languages according to the TIOBE index. Created in April
2006, it was open-sourced in April 2022.

Inform is itself a literate program ([written with inweb](https://github.com/ganelson/inweb)),
one of the largest in the world. This means that a human-readable form of the
code is continuously maintained alongside it: see &#9733; [Inform: The Program](https://ganelson.github.io/inform)

Software in this repository is [copyright Graham Nelson 2006-2022](notes/copyright.md)
except where otherwise stated, and available under the [Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).

To consult...                     | Turn to...
--------------------------------- | -----------------------------------------
Brief news about ongoing work     | [notes/working_notes.md](notes/working_notes.md)
Licencing and copyright policy    | [notes/copyright.md](notes/copyright.md)
Branching and versioning policy   | [notes/versioning.md](notes/versioning.md)
Language evolution policy         | [https://github.com/ganelson/inform-evolution](https://github.com/ganelson/inform-evolution)
Version history and release notes | [notes/version_history.md](notes/version_history.md)
Pending changes not yet released  | [notes/release/pending.md](notes/release/pending.md)

## Repositories

This is the "core Inform" repository, holding source code for the compiler, and
for everything needed to run it on the command line. However:

* To build and test the compiler on the command line you also need Inweb and
Intest, programs spun out from the Inform project, with their own repositories:
	* [https://github.com/ganelson/inweb](https://github.com/ganelson/inweb)
	* [https://github.com/ganelson/intest](https://github.com/ganelson/intest)
* Most Inform authors use Inform as an app, not at the command line. While
the UI looks similar on each platform, they are independent code-bases and each
has its own repository:
	* [https://github.com/TobyLobster/Inform](https://github.com/TobyLobster/Inform) for MacOS, maintained by [Toby Nelson](https://github.com/TobyLobster)
	* [https://github.com/DavidKinder/Windows-Inform7](https://github.com/DavidKinder/Windows-Inform7) for Windows, maintained by [David Kinder](https://github.com/DavidKinder)
	* [https://github.com/ptomato/inform7-ide](https://github.com/ptomato/inform7-ide) for Linux, maintained by [Philip Chimento](https://github.com/ptomato)
* Proposals for changes to Inform are at the repository:
	* [https://github.com/ganelson/inform-evolution](https://github.com/ganelson/inform-evolution)
* The server-side content for the Inform Public Library (a selection of downloadable
extensions displayed within the apps) is here:
	* [https://github.com/ganelson/inform-public-library](https://github.com/ganelson/inform-public-library)

## Build Instructions

**Caution**: The `main` branch of this repository generally holds "unstable", that is,
unreleased work-in-progress versions of Inform. See [notes/versioning.md](notes/versioning.md).

Make a directory in which to work: let's call this `work`. Then:

* Change the current directory to `work`: `cd work`
* Build Inweb as `work/inweb`: see its repository [here](https://github.com/ganelson/inweb)
* Build Intest as `work/intest`: see its repository [here](https://github.com/ganelson/intest)
* Clone Inform as `work/inform`: `git clone https://github.com/ganelson/inform.git`
* Change the current directory to this: `cd inform`
* Run a first-build script: `bash scripts/first.sh`
* Check executables have compiled: `inblorb/Tangled/inblorb -help`
* Run a single test case: `../intest/Tangled/intest inform7 -show Acidity`.
* If you have time (between 5 mins and 2 hours, depending on your system), `make check`
to run the full suite of 2500 test cases.

**Caution again**: `inform7` is written in standard C99, but is a challengingly
large task for a C compiler, and we have now seen two different cases where `gcc`
generates incorrect code
(see Jira bugs [I7-2108](https://inform7.atlassian.net/browse/I7-2108) and
[I7-2282](https://inform7.atlassian.net/jira/software/c/projects/I7/issues/I7-2282)).
In each case, recent versions of `clang` compile correct code.
We recommend compiling the core Inform tools with `clang` rather than `gcc` if possible.

## Issues and Contributions

The 2006-2021 Inform bug tracker, powered by Mantis, has now closed, and its issues
and comments have been migrated to a [a Jira tracker](https://inform7.atlassian.net/jira/software/c/projects/I7/issues).
The curator of the bug tracker is Brian Rushton, and the administrator is
Hugo Labrande.

Note that Inweb and Intest have their own bug trackers
([here](https://inform7.atlassian.net/jira/software/c/projects/INWEB/issues)
and [here](https://inform7.atlassian.net/jira/software/c/projects/INTEST/issues)).
Please do not report bugs on those to the Inform tracker, or vice versa.

Members of the Inform community are welcome to open pull requests on this
repository to address minor issues - for example, to fix bugs at the tracker,
or to correct clear-cut typos or other errors. Contributions of this sort do
not need [an Inform Evolution proposal](https://github.com/ganelson/inform-evolution),
but anything on a larger scale is likely to.

## Inventory of this Repository

**"I can't help feeling that if someone had asked me before the universe began
how it would turn out, I should have guessed something a bit less like an old
curiosity shop and a bit more like a formal French garden - an orderly
arrangement of straight avenues, circular walks, and geometrically shaped
trees and hedges."** (Michael Frayn)

Inform is not a single program, but an assemblage of programs and resources.
Some, including the inform7 compiler itself, are "literate programs", also
called "webs". The notation &#9733; marks these, and links are provided to
their human-readable forms.

### Source for command-line tools

This most important contents of this repository are the source webs for the
following command-line tools:

* inbuild - __version 10.2.0__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inbuild/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inbuild/M-ui.html)<br>A simple build and package manager for the Inform tools.
* inform7 - __version 10.2.0__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inform7/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inform7/M-cu.html)<br>The core compiler in a natural-language design system for interactive fiction.
* inter - __version 10.2.0__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inter/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inter/M-ui.html)<br>For handling intermediate Inform code.
* inblorb - __version 4.1__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inblorb/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inblorb/M-ui.html)<br>The packaging stage of the Inform 7 system, which releases a story file in the blorbed format.
* indoc - __version 4__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/indoc/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/indoc/M-iti.html)<br>The documentation-formatter for the Inform 7 system.
* inpolicy - __version 1__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inpolicy/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inpolicy/M-ui.html)<br>A lint-like tool to check up on various policies used in Inform source code.
* inrtps - __version 2__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/inrtps/index.html) - [&#9654;&nbsp;Documentation](https://ganelson.github.io/inform/inrtps/M-ui.html)<br>A generator of HTML pages to show for run-time problem messages in Inform.

### Kits shipped with Inform

The following webs are the source for kits of Inter code shipped with Inform (at the subtree inform7/Internal/Inter). Kits are libraries of code needed at run-time, and whose source is written in Inform 6 notation:

* BasicInformKit - Support for Inform as a programming language - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/BasicInformKit/index.html)
* Architecture16Kit - Support for running on 16-bit platforms - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/Architecture16Kit/index.html)
* Architecture32Kit - Support for running on 32-bit platforms - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/Architecture32Kit/index.html)
* WorldModelKit - Support for modelling space, time and actions in interactive fiction - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/WorldModelKit/index.html)
* EnglishLanguageKit - Support for English as the natural language used - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/EnglishLanguageKit/index.html)
* CommandParserKit - Support for parsing turn-by-turn commands in interactive fiction - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/CommandParserKit/index.html)
* DialogueKit - Additional support for dialogue (under construction) - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/DialogueKit/index.html)

### Extensions shipped with Inform

The following webs are the source for the two most important extensions shipped with Inform:

* [Basic Inform by Graham Nelson](inform7/extensions/basic_inform) - __v2__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/basic_inform/index.html)
* [Standard Rules by Graham Nelson](inform7/extensions/standard_rules) - __v7__ - [&#9733;&nbsp;Web](https://ganelson.github.io/inform/standard_rules/index.html)

Other extensions shipped with Inform are not presented as webs, but as single files:

* [Basic Help Menu by Emily Short](<inform7/Internal/Extensions/Emily Short/Basic Help Menu.i7x>) - __v1__
* [Basic Screen Effects by Emily Short](<inform7/Internal/Extensions/Emily Short/Basic Screen Effects.i7x>) - __v9__
* [Complex Listing by Emily Short](<inform7/Internal/Extensions/Emily Short/Complex Listing.i7x>) - __v9__
* [Glulx Image Centering by Emily Short](<inform7/Internal/Extensions/Emily Short/Glulx Image Centering.i7x>) - __v4__
* [Glulx Text Effects by Emily Short](<inform7/Internal/Extensions/Emily Short/Glulx Text Effects.i7x>) - __v6__
* [Inanimate Listeners by Emily Short](<inform7/Internal/Extensions/Emily Short/Inanimate Listeners.i7x>) - __v2__
* [Locksmith by Emily Short](<inform7/Internal/Extensions/Emily Short/Locksmith.i7x>) - __v14__
* [Menus by Emily Short](<inform7/Internal/Extensions/Emily Short/Menus.i7x>) - __v3__
* [Punctuation Removal by Emily Short](<inform7/Internal/Extensions/Emily Short/Punctuation Removal.i7x>) - __v6__
* [Skeleton Keys by Emily Short](<inform7/Internal/Extensions/Emily Short/Skeleton Keys.i7x>) - __v1__
* [Epistemology by Eric Eve](<inform7/Internal/Extensions/Eric Eve/Epistemology.i7x>) - __v9__
* [Approximate Metric Units by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Approximate Metric Units.i7x>) - __v1__
* [English Language by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/English Language.i7x>) - __v2__
* [Metric Units by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Metric Units.i7x>) - __v2__
* [Rideable Vehicles by Graham Nelson](<inform7/Internal/Extensions/Graham Nelson/Rideable Vehicles.i7x>) - __v3__

### Website templates and interpreters shipped with Inform

These are templates used by Inform to release story files within a website:

* [Classic](inform7/Internal/Templates/Classic) - An older, plainer website
* [Standard](inform7/Internal/Templates/Standard) - The default, more modern look

These are Javascript interpreters used to release such websites in a form which can play the story files interactively online:

* inform7/Internal/Templates - Template websites for Inform 7's 'release as a website' feature
* inform7/Internal/Templates/Parchment - Z-machine in Javascript - __Parchment for Inform 7 (2022.8)__ - from [https://github.com/curiousdannii/parchment], maintained by [Dannii Willis](https://github.com/curiousdannii)
* inform7/Internal/Templates/Quixe - Glulx in Javascript - __Quixe for Inform 7 (v. 2.2.1)__ - from [https://github.com/erkyrath/quixe], maintained by [Andrew Plotkin](https://github.com/erkyrath)

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

* inform6 - The Inform 6 compiler (used by I7 as a code generator). - __1641__ - from [https://github.com/DavidKinder/Inform6], maintained by [David Kinder](https://github.com/DavidKinder)
	* inform6/Tests/Assistants/dumb-frotz - A dumb-terminal Z-machine interpreter. - unversioned: modified from [Alembic Petrofsky's 1998 Teletype port of Frotz](https://github.com/sussman/ircbot-collection/tree/master/dumb-frotz)
	* inform6/Tests/Assistants/dumb-glulx/glulxe - A dumb-terminal Glulx interpreter. - __0.6.0__ - [erkyrath/glulxe](https://github.com/erkyrath/glulxe), maintained by [Andrew Plotkin](https://github.com/erkyrath)
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

This README.md file was generated automatically by Inweb, and should not
be edited. To make changes, edit inform.rmscript and re-generate.

