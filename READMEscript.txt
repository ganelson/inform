@-> README.md
# Inform 7 @version(inform7)

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

@define primary(program)
* @program - @purpose(@program) - currently at @version(@program)
@end
@primary(inform7)
@primary(inblorb)
@primary(indoc)
@primary(inpolicy)
@primary(inrtps)
@primary(inter)

### Resources copied here from elsewhere

Stable versions of the following are periodically copied into this repository,
but this is not where development on them is done, and no pull requests will
be accepted. (Note that these are not git submodules.)

@define secondary(program, for, maintainer, username, repository)
* @program - @for - from [https://github.com/@username/@repository], maintained by [@maintainer](https://github.com/@username)
@end
@secondary(inform6, 'the Inform 6 compiler (used by I7 as a code generator)', 'David Kinder', DavidKinder, Inform6)

@-> docs/webs.html
@define web(program, manual)
	<li>
		<p><a href="@program/index.html"><spon class="sectiontitle">@program</span></a> -
		@version(@program)
		- <span class="purpose">@purpose(@program)</span>
		Documentation is <a href="@program/@manual.html">here</a>.</p>
	</li>
@end
@define subweb(owner, program)
	<li>
		<p>↳ <a href="docs/webs.html"><spon class="sectiontitle">@program</span></a> -
		<span class="purpose">@purpose(@owner/@program)</span></p>
	</li>
@end
@define mod(owner, module)
	<li>
		<p>↳ <a href="docs/@module-module/index.html"><spon class="sectiontitle">@module</span></a> (module) -
		<span class="purpose">@purpose(@owner/@module-module)</span></p>
	</li>
@end
@define extweb(program)
	<li>
		<p><a href="../@program/docs/webs.html"><spon class="sectiontitle">@program</span></a> -
		@version(@program)
		- <span class="purpose">@purpose(@program)</span>
		This has its own repository, with its own &#9733; Webs page.</p>
	</li>
@end
@define extsubweb(owner, program)
	<li>
		<p>↳ <a href="../@owner/docs/webs.html"><spon class="sectiontitle">@program</span></a> -
		<span class="purpose">@purpose(@owner/@program)</span></p>
	</li>
@end
@define extmod(owner, module)
	<li>
		<p>↳ <a href="../@owner/docs/@module-module/index.html"><spon class="sectiontitle">@module</span></a> (module) -
		<span class="purpose">@purpose(@owner/@module-module)</span></p>
	</li>
@end
<html>
	<head>
		<title>Inform &#9733; Webs</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta http-equiv="Content-Language" content="en-gb">
		<link href="inblorb/inweb.css" rel="stylesheet" rev="stylesheet" type="text/css">
	</head>

	<body>
		<ul class="crumbs"><li><b>&#9733;</b></li><li><b>Webs</b></li></ul>
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
		<p class="chapter">Command-line programs needed to use Inform 7:</p>
		<ul class="sectionlist">
			@web('inform7', 'P-p')
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
			@subweb('inform7', 'core-test')
			@mod('inform7', 'if')
			@mod('inform7', 'multimedia')
			@mod('inform7', 'index')
			@web('inter', 'P-ui')
			@mod('inter', 'inter')
			@mod('inter', 'codegen')
			@web('inform6', 'P-p')
			@web('inblorb', 'P-ui')
			@extweb('intest')
		</ul>
		<hr>
		<p class="chapter">Command-line programs needed only to build Inform 7:</p>
		<ul class="sectionlist">
			@web('indoc', 'P-iti')
			@web('inpolicy', 'P-ui')
			@web('inrtps', 'P-ui')
			@extweb('inweb')
			@extmod('inweb', 'foundation')
			@extsubweb('inweb', 'foundation-test')
		</ul>
		<hr>
	</body>
</html>
