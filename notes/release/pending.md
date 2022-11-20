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

- Fix for Jira bug [I7-2139](https://inform7.atlassian.net/browse/I7-2139)
	"Articles become part of relation name"
	([commit 85110a9](https://github.com/ganelson/inform/commit/85110a981a3d2419b3778eb383408de122c301a8))
- Fix for Jira bug [I7-2234](https://inform7.atlassian.net/browse/I7-2234)
	"Non-heading @ sections not supported in template files"
	(Inweb: [commit f2aaa32](https://github.com/ganelson/inweb/commit/f2aaa32479e14187679828e3e5696f5951b43b38))
