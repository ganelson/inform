# Pending

These will be added to release notes when the release is made.

## Features

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

## Bug fixes

- Fix for Jira bug [I7-2329](https://inform7.atlassian.net/browse/I7-2329)
	"Colons in story title are not sanitised in release filenames"
	([commit f50a043](https://github.com/ganelson/inform/commit/f50a043fabf558ad3396bc1b97dfb13b93619305))
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
- Fix for Jira bug [I7-2139](https://inform7.atlassian.net/browse/I7-2139)
	"Articles become part of relation name"
	([commit 85110a9](https://github.com/ganelson/inform/commit/85110a981a3d2419b3778eb383408de122c301a8))
- Fix for a "very old quirk of I7 where it generates a `story.gblorb.js` file for
	the interpreter website, but the filename is a lie. It's the base64-encoding
	of the `story.ulx` file, not the `story.gblorb`." (Andrew Plotkin, not from Jira)
- Cosmetic fixes not worth linking to (I7-2319, I7-2316, I7-2315, I7-2270, I7-2268, I7-2221)

## Note about intest

- On MacOS, `intest` is supplied inside the app for testing examples in the
	documentation of extension projects: a bug has been fixed which caused the
	test scripts in such examples to be wrongly extracted if characters appeared
	after the final double-quote of the test script (for example, any redundant
	white space). This isn't strictly speaking a core Inform bug fix, but it
	affects some users.
