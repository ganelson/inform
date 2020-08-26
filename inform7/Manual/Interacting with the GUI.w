Interacting with the GUI.

A few notes on how the GUI apps should use the Inform command line.

@h How the application should install extensions.
When the Inform 7 application looks at a file chosen by the user to
be installed, it should look at the first line. (Note that this might have
any of |0a|, |0d|, |0a0d|, |0d0a|, or Unicode line division as its line
ending: and that the file might, or might not, begin with a Unicode BOM,
"byte order marker", code. Characters within the line will be encoded as
UTF-8, though -- except possibly for some exotic forms of space -- they
will all be found in the ISO Latin-1 set.) The first line is required to
have one of the following forms, possibly with white space before or after,
but definitely without line breaks before:

>> Locksmith Extra by Emily Short begins here.

>> Version 2 of Locksmith Extra by Emily Short begins here.

>> Version 060430 of Locksmith Extra by Emily Short begins here.

>> Version 2/060430 of Locksmith Extra by Emily Short begins here.

If the name of the extension finishes with a bracketed clause, that
should be disregarded. Such clauses are used to specify virtual machine
requirements, at present, and could conceivably be used for other purposes
later, so let's reserve them now.

>> Version 2 of Glulx Text Effects (for Glulx only) by Emily Short begins here.

The application should reject (that is, politely refuse to install) any
purported extension file whose first line does not conform to the above.

Ignoring any version number given, the Inform application should then
store the file in the external extensions area. For instance,

	|~/Library/Inform/Extensions/Emily Short/Glulx Text Effects| (OS X)
	|My Documents\Inform\Extensions\Emily Short\Glulx Text Effects| (Windows)

Note that the file will probably not have the right name initially, and
will need to be renamed as well as moved. (Note the lack of a file
extension.) The subfolders |Inform|, |Extensions| and |Emily Short| must be
created if not already present.

If to install such an extension would result in over-writing an extension
already present at that filename, the user should be given a warning and
asked if he wants to proceed.

However, note that it is not an error to install an extension with
the same name and author as one in the built-in extensions folder. This
does not result in overwriting, since the newly installed version will live
in the external area, not the built-in area.

An extension may be uninstalled simply by deleting the file: but the
application must not allow the user to uninstall any extension from
the built-in area. We must assume that the latter could be on a read-only
disc, or could be part of a cryptographically signed application bundle.

@h The extension census.
The Inform application should run Inform in "census mode" in order to
keep extension documentation up to date. Inform should be run in census mode
on three occasions:

(a) when the Inform application starts up;
(b) when the Inform application installs a new extension;
(c) when the Inform application uninstalls an extension.

When |inform7| is run in "census mode", it should be run with the command |-census|.
All output from Inform should be ignored, including its return code: ideally,
not even a fatal error should provoke a reaction from the application. If the
census doesn't work for some file-system reason, never mind -- it's not
mission-critical.

@h What happens in census mode.
The census has two purposes: first, to create provisional documentation
where needed for new and unused extensions; and second, to create the
following index files in the external documentation area (not in
the external extension area):
= (text)
	.../Extensions.html
	.../ExtIndex.html
=
Documentation for any individual extension is stored at, e.g.,
= (text)
	.../Extensions/Victoria Saxe-Coburg-Gotha/Werewolves.html
=
Inform can generate such a file, for an individual extension, in two ways: (a)
provisionally, with much less detail, and (b) fully. Whenever it
successfully compiles a work using extension X, it rewrites the
documentation for X fully, and updates both the two indexing pages.

When Inform runs in |-census| mode, what it does is to scan for all extensions.
If Inform finds a valid extension with no documentation page, it writes a
provisional one; and again, it updates both the two indexing pages.

(Inform in fact runs a census on every compilation, as well, so |-census| runs
do nothing "extra" that a normal run of Inform does not also do. On every
census, Inform automatically checks for misfiled or broken extensions, and
places a descriptive report of what's wrong on the |Extensions.html| index
page -- if people move around or edit extensions by hand, they may run into
these errors.)
