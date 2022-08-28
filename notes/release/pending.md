# Pending

These will be added to release notes when the release is made.

## Bug fixes

- Inbuild no longer attempts to incrementally rebuild kits in the internal nest,
	which avoids sandboxing issues in the Linux Inform app: instead it trusts
	that whatever is in the internal nest has already been properly build

- Fix for Jira bug [I7-2182](https://inform7.atlassian.net/browse/I7-2190)
	"Internal error on a too large table of rankings"
	([commit 59a9f23](https://github.com/ganelson/inform/commit/59a9f239d7dcb11a287819f73b45d9039562d12f))
