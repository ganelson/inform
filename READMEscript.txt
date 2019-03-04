@-> README.md
This is the main Inform 7 repository.
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
