# Pending

These will be added to release notes when the release is made. This page
only hold bug fixes and other minor tweaks: anything larger is covered by
[Inform evolution](https://github.com/ganelson/inform-evolution) proposals.

## Featurettes arising from bug reports, but too small for Inform Evolution proposals

- This was reported as Jira bug [I7-2087](https://inform7.atlassian.net/browse/I7-2087)
	"three anonymous standard rules", but is arguably a feature request: that three
	rules in the Standard Rules should have names. All three are simple rules, two
	of them occurring early and late in the turn cycle to consider whether a scene
	change has happened, and one as the fallback rule making an action succeed if
	no rules have intervened in the process.
	```
	early scene changing stage
	late scene changing stage
	default action success rule
	```
- Errors occurring in I6-syntax code, either in `(- ... -)` inclusions into I7
	source text or in kit source code, are now reported more fully, with source
	references and links provided. (A feature request for this was filed as
	Jira bug [I7-2232](https://inform7.atlassian.net/browse/I7-2232).)

## Documentation

"Writing with Inform" and "The Recipe Book" benefit from a revision throughout to
remove unnecessary gender-binary language, mostly to do with pronouns attached
to "the player", or similar. The example `Blue or Pink` has become `Good or Evil`,
and now poses a moral rather than gender-based question.

## Bug fixes

- Fix for Jira bug [I7-2344](https://inform7.atlassian.net/browse/I7-2344)
	"inform7's -silence flag should imply -no-progress"
	([commit 687dba6](https://github.com/ganelson/inform/commit/687dba6857983420a76559cfed292cde0a2891fb))
- Fix for Jira bug [I7-2341](https://inform7.atlassian.net/browse/I7-2341)
	"You can `use dict_word_size of 12` and I7's ok with it, but then passes it
	on to I6 in lower case"
	([commit a011ec6](https://github.com/ganelson/inform/commit/a011ec67b900bf13d89ab73a46dc519b58c69906))
- Fix for Jira bug [I7-2335](https://inform7.atlassian.net/browse/I7-2335)
	"Several previously-legal forms of the Array directive no longer work in I6 inclusions in 10.1.2"
	([commit 4d97b49](https://github.com/ganelson/inform/commit/4d97b499cfd3e15650d1bba1e6e8c70c24a01fb2))
- Fix for Jira bug [I7-2334](https://inform7.atlassian.net/browse/I7-2334)
	"imbalanced parentheses in Definition by I6 Condition causes abject failure"
	([commit 5d45863](https://github.com/ganelson/inform/commit/5d4586387c6b7405cd45e43f04c984583cd76bb3))
- Fix for Jira bug [I7-2328](https://inform7.atlassian.net/browse/I7-2328)
	"Compiler hard-codes bad/deprecated Glulx acceleration instructions"
	([commit a2c1274](https://github.com/ganelson/inform/commit/a2c1274a39d87abe6da9fa7cae9dd8e7dc566ea6))
- Fix for Jira bug [I7-2329](https://inform7.atlassian.net/browse/I7-2329)
	"Colons in story title are not sanitised in release filenames"
	([commit f50a043](https://github.com/ganelson/inform/commit/f50a043fabf558ad3396bc1b97dfb13b93619305))
- Fix for Jira bug [I7-2306](https://inform7.atlassian.net/browse/I7-2306)
	"remaining arbitary ifdefs in kit code": also fixes an unreported bug in
	which the use options "Use numbered rules", "Use manual pronouns",
	"Use fast route-finding" and "Use slow route-finding" had ceased to have
	any effect; all taken care of in the implementation of IE-0018
	([commit 95e613c](https://github.com/ganelson/inform/commit/95e613cd6a2d4341823f16f1635e59136710090a))
- Fix for Jira bug [I7-2304](https://inform7.atlassian.net/browse/I7-2304)
	"switch(): first branch can't start with negative number"
	([commit 1c18007](https://github.com/ganelson/inform/commit/1c18007326bf6fb15c74a1d5742827a4d76a0c20))
- Fix for Jira bug [I7-2298](https://inform7.atlassian.net/browse/I7-2298)
	""to" in I6 switch statement is not recognized"
	([commit 04e526f](https://github.com/ganelson/inform/commit/04e526f0a676b89fa032d6c886a146499d5e7ae5))
- Fix for Jira bug [I7-2297](https://inform7.atlassian.net/browse/I7-2297)
	"Missing semicolon after I6 routine crashed compiler without explanation"
	([commit 4fb6e57](https://github.com/ganelson/inform/commit/4fb6e57b866eacd84d27e4752c7d0147fc982ac0))
- Fix for Jira bug [I7-2284](https://inform7.atlassian.net/browse/I7-2284)
	"Inter error" - arising from a sentence trying to use an either-or property
	in a way which would make it unheld by default, when an existing sentence
	already makes it held by default
	([commit 1fc5055](https://github.com/ganelson/inform/commit/1fc505507b52be19a09cc3898326952954620312))
- Fix for Jira bug [I7-2269](https://inform7.atlassian.net/browse/I7-2269)
	"Output of I6 floating point literals strips the '+', resulting in uncompilable I6"
	([commit 46349cb](https://github.com/ganelson/inform/commit/46349cb85c56116602c9245ee47e67ea08155d40))
- Fix for Jira bug [I7-2267](https://inform7.atlassian.net/browse/I7-2267)
	"I6 inclusion for which compiler hangs (using '::' operator)"
	([commit f46433c](https://github.com/ganelson/inform/commit/f46433c22cfd9d414b7c337f8ee58220fb9286cc))
- Fix for Jira bug [I7-2265](https://inform7.atlassian.net/browse/I7-2265)
	"Compiler fails on creating an instance of a specified kind with multiple parts"
	([commit af2531f](https://github.com/ganelson/inform/commit/af2531f4b2b4d1f59e4a9b45a8ddc274c94c7f77))
- Fix for Jira bug [I7-2264](https://inform7.atlassian.net/browse/I7-2264)
	"Cannot compile 'Verb meta' directive inside a kit"
	([commit cbe7012](https://github.com/ganelson/inform/commit/cbe7012fb6950932ebf2a4b9290f80bcd5970ad1)):
	actually a linker issue if multiple kits do this
- Fix for Jira bug [I7-2255](https://inform7.atlassian.net/browse/I7-2255)
	"Localization detail in Banner routine (uses preposition 'by' in English)"
	([commit ce2b7ba](https://github.com/ganelson/inform/commit/ce2b7ba15b0431caf295316ee6c9fa4843c7251f)): the English word
	`by` had been hard-wired, but is now printed using `BY__WD` instead, which
	in English is declared as `'by'` but in Spanish could be `'por'`, or in
	French `'par'`, for example
- Fix for Jira bug [I7-2247](https://inform7.atlassian.net/browse/I7-2247)
	"Internal error 'unowned' when using 'Understand'"
	([commit 3ebcac0](https://github.com/ganelson/inform/commit/3ebcac0b5dc58e9754de6b2c8dd85fad719e4629))
- Fix for Jira bug [I7-2242](https://inform7.atlassian.net/browse/I7-2242)
	"Creating kinds via tables fails"
	([commit 0038a2e](https://github.com/ganelson/inform/commit/0038a2e46f91fa104f65c7c910ff7097f1c09198))
- Fix for Jira bug [I7-2237](https://inform7.atlassian.net/browse/I7-2237)
	"Inform hangs when reading a Neptune file in a kit with no final newline"
	([commit 1cd75d8](https://github.com/ganelson/inform/commit/1cd75d8a4946ba10636a8ec474aded9716fffe9b))
- Fix for Jira bug [I7-2235](https://inform7.atlassian.net/browse/I7-2235)
	"List of action names ending with 23 bonus instances of waiting (i.e., action name 0)"
	([commit b5c35fb](https://github.com/ganelson/inform/commit/b5c35fb98e6603d2f49c95e8031189a7dda1f0c8)): in fact those were
	anonymous debugging actions from WorldModelKit, which are valid instances of
	`action name` (and need to be for type safety reasons), but which were not
	properly looped through or described. They now print as, e.g.,
	`performing kit action ##ShowRelations`. As a fringe benefit, of sorts, such
	actions now appear in the logging output of the ACTIONS command (except for
	the actions needed to switch ACTIONS on and off, which are deliberately
	excluded from this since they only add confusion to the story transcript).
- Fix for Jira bug [I7-2234](https://inform7.atlassian.net/browse/I7-2234)
	"Non-heading @ sections not supported in template files"
	(Inweb: [commit f2aaa32](https://github.com/ganelson/inweb/commit/f2aaa32479e14187679828e3e5696f5951b43b38))
- Fix for Jira bug [I7-2225](https://inform7.atlassian.net/browse/I7-2225)
	"Translating kinds into I6 doesn't work"
	(Inweb: [commit d608388](https://github.com/ganelson/inweb/commit/d608388d643a85d1aa3c88cfa1710b848bd5cb7e))
- Fix for Jira bug [I7-2142](https://inform7.atlassian.net/browse/I7-2142)
	"With 'the foo rule substitutes for the bar rule when...', the bar rule is
	suppressed but the foo rule isn't followed."
	([commit 11e1f75](https://github.com/ganelson/inform/commit/11e1f756c16aa17b31afd02ca2bb5f4e5abd3ac6))
- Fix for Jira bug [I7-2139](https://inform7.atlassian.net/browse/I7-2139)
	"Articles become part of relation name"
	([commit 85110a9](https://github.com/ganelson/inform/commit/85110a981a3d2419b3778eb383408de122c301a8))
- Fix for a "very old quirk of I7 where it generates a `story.gblorb.js` file for
	the interpreter website, but the filename is a lie. It's the base64-encoding
	of the `story.ulx` file, not the `story.gblorb`." (Andrew Plotkin, not from Jira)
- Cosmetic fixes not worth linking to (I7-2350, I7-2319, I7-2316, I7-2315, I7-2293, I7-2270, I7-2268, I7-2221)

## Bugs fixed in the course of feature additions

Work done on Inform evolution proposal [(IE-0015) World model enforcement](https://github.com/ganelson/inform-evolution/blob/main/proposals/0015-world-model-enforcement.md)
fixes a number of known anomalies in the way that the standard world model
handled containment, incorporation and so on. This enabled a number of bugs to
be closed:

- [I7-2296](https://inform7.atlassian.net/browse/I7-2296)
	on things being privately-named causing their printed names not to be used in room description
- [I7-2220](https://inform7.atlassian.net/browse/I7-2220)
	on the definition of holding
- [I7-2219](https://inform7.atlassian.net/browse/I7-2219)
	on directions being held
- [I7-2178](https://inform7.atlassian.net/browse/I7-2178)
	on "if x is held by a supporter" resulting in false negative
- [I7-2128](https://inform7.atlassian.net/browse/I7-2128)
	on holding relation tests failing for containment, support, or incorporation
- [I7-2046 = Mantis 2083](https://inform7.atlassian.net/browse/I7-2046)
	on when containers holding concealed items say they are "(empty)"
- [I7-2036 = Mantis 2073](https://inform7.atlassian.net/browse/I7-2036)
	on inconsistencies when containers or supporters holding concealed items are examined

Similarly, [(IE-0021) No automatic plural synonyms](https://github.com/ganelson/inform-evolution/blob/main/proposals/0021-no-automatic-plural-synonyms.md):

- [I7-1980](https://inform7.atlassian.net/browse/I7-1980)
	on understanding things by plural name of kind

## Note about intest

- On MacOS, `intest` is supplied inside the app for testing examples in the
	documentation of extension projects: a bug has been fixed which caused the
	test scripts in such examples to be wrongly extracted if characters appeared
	after the final double-quote of the test script (for example, any redundant
	white space). This isn't strictly speaking a core Inform bug fix, but it
	affects some users.
