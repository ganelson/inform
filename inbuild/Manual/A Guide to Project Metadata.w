A Guide to Project Metadata.

Provisional documentation on giving Inform projects JSON-based metadata.

@h This is optional.
An Inform project does not normally need a metadata file to be used. At present,
the only circumstances where this file would be actually necessary would be
if the project needs to include non-standard kits of Inter code. (And even
then, it's not needed to specify the language-of-play kit to use, so merely
writing an Inform project to make a Spanish story, say, does not count as a
"non-standard" kit.)

@h JSON metadata for projects.
Like kits and language bundles, projects can be described by "metadata files"
written in JSON format.

Such a file must be called "project_metadata.json" and be placed in the materials
directory for the project. (Note: not the .inform directory.)

This is a JSON file very similar to the ones used for kit metadata: see //A Guide to Kits//,
which it is probably helpful to read before going much further with this.

For example:
= (text)
{
    "is": {
        "type": "project",
        "title": "St Anne Passion",
        "author": "Hermione Marmalade",
        "version": "3.2"
    },
    "needs": [ {
        "need": {
            "type": "kit",
            "title": "CommandParserKit"
        }
    }, {
        "need": {
            "type": "kit",
            "title": "ChoraleKit"
            "version": "4.1.1"
        }
    } ]
}
=
This example tells inbuild, and hence inform7, that the project is a command-parser
work of IF, but that it also needs an unusual extra kit called "ChoraleKit".
Moreover, it will build only with a version of that kit compatible (in the semantic
version number sense) with v4.1.1.

@ The |is| object identifies the project. Note that the type must be |"project"|,
and that the title and author must both be given, and must exactly match what
the bibliographic sentence at the top of the source text. (If the work is
anonymous or untitled, the author or title must be the empty text, but they
must still be given.) It is an error for the source text and the metadata file
to disagree about this, and inbuild and inform7 will halt with a problem message
if they do.

The |is.version| is optional. If given, it must be a valid semantic version
number. The major part of that semver is then used as the value of the
"release number" variable; this must not contradict what the source text says.
For example, if |is.version| is |"3.2"|, then an IF story if built from this
project would identify itself as Release 3. If the sentence contained
= (text as Inform 7)
The release number is 3.
=
that would cause no problems; but if it contained
= (text as Inform 7)
The release number is 5.
=
then Inform would halt with a problem message about the contradiction.

@ The |needs| object identifies any kits to be included with the project when
it is built, other than BasicInformKit.

So for a Basic Inform only project, which uses a version of the Inform language
with no IF-like ingredients, no command parser, and no world model, there is
no need to have a |needs| object at all. But for a more standard use of Inform
to make command-parser IF, CommandParserKit must be included, like so:
= (text)
    "needs": [ {
        "need": {
            "type": "kit",
            "title": "CommandParserKit"
        }
    } ]
=

Because kits can include other kits automatically, other kits may well be
included too (for example, the presence of CommandParserKit causes WorldModelKit
also to be used). Those additional kits also do not need to be specified here.
The language of play can also include kits automatically (for example, if the
language of play is English, then EnglishLanguageKit is included). That too does
not need to be specified.

@ Project metadata can also specify that given named compiler features should
be active or inactive when compiling this project. For example, suppose the
compiler has an experimental feature called |fruit cultivation|, switched
off by default, and a project needs to test this. It can do so by specifying:
= (text)
    "activates": [ "fruit cultivation" ],
=
Similarly for |"deactivates"|. Both clauses are optional and take a list of
feature names: those features must all exist inside the compiler, or a
problem will be thrown on compilation. (Note that the JSON here is identical
to that which kits can also offer: kits can also turn features on or off.)

@ Finally, note that the |-basic| switch at the Inbuild or Inform command line,
which signals that the project being compiled is for the Basic Inform language,
is still legal to use if a project metadata file exists, but only so long as
the metadata does not specify CommandParserKit or WorldModelKit: if it does,
use of |-basic| throws a problem.
