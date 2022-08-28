# Pending

These will be added to release notes when the release is made.

## Bug fixes

- Inbuild no longer attempts to incrementally rebuild kits in the internal nest,
	which avoids sandboxing issues in the Linux Inform app: instead it trusts
	that whatever is in the internal nest has already been properly build

- Fix for Jira bug [I7-2190](https://inform7.atlassian.net/browse/I7-2190)
	"Internal error on a too large table of rankings"
	([commit 59a9f23](https://github.com/ganelson/inform/commit/59a9f239d7dcb11a287819f73b45d9039562d12f))

- Fix for Jira bug [I7-2185](https://inform7.atlassian.net/browse/I7-2185)
	"Valued property with negative certainty causes internal error"
	([commit 2173d4b](https://github.com/ganelson/inform/commit/2173d4b8630b5f3472fc173223d13f729d6e8799))

- Fix for Jira bug [I7-2192](https://inform7.atlassian.net/browse/I7-2192)
	"'Use memory economy' causes Inform 6 error"
	([commit 52baf6c](https://github.com/ganelson/inform/commit/52baf6cfc18d053d8b49b9331d1aef72a8662db7))

- Fix for Jira bug [I7-2193](https://inform7.atlassian.net/browse/I7-2193)
	"Internal error when using the call() syntax in an Inform 6 inclusion"
	([commit c9e740b](https://github.com/ganelson/inform/commit/c9e740b086083581ac48d341cd2eb7bc5b0ae1a7))
