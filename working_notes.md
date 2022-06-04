# Ongoing work: a few notes

This rudimentary blog-like page is to provide brief notes on changes to the
Inform code base made between formal releases, and is only likely to be useful
to people experimenting with unreleased builds of Inform.

## Current status

The next formal release is v10.1.0. We are coming to the end of the beta period
for that, and are concentrating on bug fixes, improvements to compatibility
with old extensions, and making sure that concepts being introduced by 10.1
are set up in a way we can live with. Work also continues on the GUI apps,
notably the MacOS app, which is being modernised to support Dark Mode.

## News items

### Kit metadata respecified as JSON (4 June 2022)

Kits are new in 10.1, and are documented in the Inbuild manual, which has been
rewritten today: see [A Guide to Kits](https://ganelson.github.io/inform/inbuild/M-agtk.html)

The change today is that the "kit_metadata.txt" file has now changed format and
name, to become "kit_metadata.json". This JSON format is a work in progress and
is likely to become a uniform way to describe resources used by Inbuild (extensions,
language bundles, interpreters, website templates, and so on): the point of having
such a format is to prepare the way for Inbuild to understand remote resources
somewhere on the Internet. For now JSON metadata files exist only for kits, but
some of the plumbing has been put in for general resources to have them.

This required new APIs in the foundation library at the Inweb repository to
read, write and validate JSON files: see the new section [JSON](https://ganelson.github.io/inweb/foundation-module/4-jsn.html).
You'll therefore need to pull the latest Inweb in order to build the latest Inform.

The current set of requirements for what Inbuild will read as resource metadata is
at [inform7/Internal/Miscellany/metadata.jsonr]. There are also a few semantic
constraints: see [JSON Metadata](https://ganelson.github.io/inform/supervisor-module/2-jm.html)

### Versioning policy for the built-in kits (4 June 2022)

There are currently five kits supplied in the Inform installation: 

	WorldModelKit
	EnglishLanguageKit
	CommandParserKit
	BasicInformKit
	BasicInformExtrasKit

Up to now these had no version numbers, but we want to encourage all kits to
have semantic version numbers, so we should comply with that ourselves.

In practice these kits are tightly coupled to the main compiler: (a) many bug fixes
in Inform which users think of as compiler fixes are in fact changes to these kits;
and (b) in normal circumstances people will never want to use the kits from one
build with the compiler from another. So the most useful way to describe the version
of a built-in kit is to identify which compiler release it came with.

As a policy decision, the version numbers of these five kits are therefore going
to be the same as those of the main compiler. (Today, that's "10.1.0-beta+6V21".)

This is enforced by changes to the makescript used when updating the main compiler's
version number, which uses a new feature |-sync-kit-versions| of the Inpolicy tool.
For its implementation, see: [[Kit Versioning](https://ganelson.github.io/inform/inpolicy/2-kv.html)

User-written kits not included in the Inform installation should not do this.
They won't be tied to particular compiler releases, and should have their own
semantic version numbers reflecting their own history of development.

### Incorporation of "6M62 Patches" (31 May 2022)

In recent years Inform users have been keeping an extension called "6M62 Patches",
which contained a small selection of bug fixes to the template files of Inform 6
code in build 6M62 (i.e., Inform version 9.3). Those template files have now
become kits, the Inform 6 code has become Inter code, and changes to the way the
"Include..." sentence works mean that "6M62 Patches" is not compatible with v10.1.

It would be easy enough to fix that, but there is now no need: all bug fixes
in "6M62 Patches" have been adopted in the kits for v10.1. Any old project which
included "6M62 Patches" can now stop doing so.

It was a real public service to create and maintain "6M62 Patches", and we thank
everyone who contributed to it: their work lives on.
