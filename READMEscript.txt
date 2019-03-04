@-> README.md
This is the main Inform 7 repository.
@-> docs/webs.html
@define details(program, purpose, manual)
	<li>
		<p><a href="@program/index.html"><spon class="sectiontitle">@program</span></a> -
		@version(@program)
		- <span class="purpose">@purpose</span>
		Documentation is <a href="@program/@manual.html">here</a>.</p>
	</li>
@end
@define extdetails(program, purpose, manual)
	<li>
		<p><a href="../@program/docs/webs.html"><spon class="sectiontitle">@program</span></a> -
		@version(@program)
		- <span class="purpose">@purpose</span>
		This has its own repository, with its own &#9733; Webs page.</p>
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
			@details('inblorb', 'The packaging stage of the Inform 7 system, which releases a story file in the blorbed format.', 'P-ui')
			@extdetails('intest', 'A text-based command-line tool for testing other command-line tools.')
		</ul>
		<hr>
		<p class="chapter">Command-line programs needed only to build Inform 7:</p>
		<ul class="sectionlist">
			@details('indoc', 'The documentation-formatter for the Inform 7 system.', 'P-iti')
			@details('inpolicy', 'A lint-like tool to check up on various policies used in Inform source code.', 'P-ui')
			@details('inrtps', 'A generator of HTML pages to show for run-time problem messages in Inform.', 'P-ui')
			@extdetails('inweb', 'A modern system for literate programming.')
		</ul>
		<hr>
	</body>
</html>
