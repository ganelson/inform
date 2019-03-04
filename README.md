# Inform 7 version 7.10.1 'Krypton' (build 6Q21)

## About Inform 7

Inform 7 (April 2006-) is a programming language for creating interactive
fiction, using natural language syntax. Using natural language and drawing on
ideas from linguistics and from literate programming, Inform is widely
used as a medium for literary writing, as a prototyping tool in the games
industry, and in education, both at school and university level (where
Inform is often assigned material for courses on digital narrative).
It has twice ranked in the top 100 most influential programming languages
according to the TIOBE index.

## Repositories

This is the "core repository", holding source code for the compiler, and
for everything needed to run it on the command line. However:

* To build and test the compiler you also need Inweb and Intest, programs
spun out from the Inform project. These are __not included in the core
repository either as submodules or copies__, and have their own repositories.
If you are new to Inform core development, begin by cloning and building Inweb
as a stand-alone tool, then use that to build Intest, then return here.
	* [https://github.com/ganelson/inweb](https://github.com/ganelson/inweb), maintained by [Graham Nelson](https://github.com/ganelson)
	* [https://github.com/ganelson/intest](https://github.com/ganelson/intest), maintained by [Graham Nelson](https://github.com/ganelson)
* Most Inform authors use Inform as an app: for example, it is available
on the Mac App Store. While much of the UI design is the same across all
platforms, each app has its own code in its own repository. See:
	* [https://github.com/TobyLobster/Inform](https://github.com/TobyLobster/Inform) for MacOS, maintained by [Toby Nelson](https://github.com/TobyLobster)
	* [https://github.com/DavidKinder/Windows-Inform7](https://github.com/DavidKinder/Windows-Inform7) for Windows, maintained by [David Kinder](https://github.com/DavidKinder)
	* [https://github.com/ptomato/gnome-inform7](https://github.com/ptomato/gnome-inform7) for Linux, maintained by [Philip Chimento](https://github.com/ptomato)

## Inventory

Inform is not a single program: while the Inform 7 compiler builds to a single
executable file, this is only useful in concert with other tools (notably the
Inform 6 compiler and the Inblorb packager), with standard libraries of code
(called Extensions), with documentation, test cases and so on. This repository
assembles all those programs and resources, which fall into two categories:

### Resources for which this is the primary repository

This repository is where development is done on the following:

* inform7 - The core compiler in a natural-language design system for interactive fiction. Current version 7.10.1 'Krypton' (build 6Q21). Web of InC

* inblorb - The packaging stage of the Inform 7 system, which releases a story file in the blorbed format. Current version 4 'Duralumin'. Web of InC

* indoc - The documentation-formatter for the Inform 7 system. Current version 4 'Didache'. Web of InC

* inpolicy - A lint-like tool to check up on various policies used in Inform source code. Current version 1 'Plan A'. Web of InC

* inrtps - A generator of HTML pages to show for run-time problem messages in Inform. Current version 2 'Benefactive'. Web of InC

* inter - For handling intermediate Inform code Current version 1 'Axion'. Web of InC

* Changes to Inform - A detailed change history of Inform 7. Ebook in Indoc format, stored at path Changes.

* Writing with Inform and the Inform Recipe Book - The main Inform documentation, as seen in the apps, and in standalone Epubs. Ebook in Indoc format, stored at path Documentation.


Notes:

1. The "webs" above are literate programs. This means they can either be
"tangled" to executables, or "woven" to human-readable forms. The woven
forms can [all be browsed here](docs/webs.html). They aim to be much easier
to understand than raw source code found by spelunking through the repository.
2. "InC" is a slight extension of ANSI C99. These extensions are handled by
Inweb, which acts as a preprocessor. For more on InC, see the Inweb manual.

### Resources copied here from elsewhere

Stable versions of the following are periodically copied into this repository,
but this is not where development on them is done, and no pull requests will
be accepted. (Note that these are not git submodules.)

* inform6 - the Inform 6 compiler (used by I7 as a code generator) - from [https://github.com/DavidKinder/Inform6], maintained by [David Kinder](https://github.com/DavidKinder)


### Colophon

This README.mk file was generated automatically by Inpolicy, and should not
be edited. To make changes, edit READMEscript.txt and re-generate.

