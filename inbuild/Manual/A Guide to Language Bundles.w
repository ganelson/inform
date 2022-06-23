A Guide to Language Bundles.

Provisional documentation on language bundles.

@h About languages.
Like a "kit" or an "extension", a "language bundle" is a resource which Inbuild
can use. Language here means the human kind: English, French, Spanish and so on.

For each Inform project it looks at, Inbuild must determine:

(*) The "language of play" (LOP), which is the language printed by the story and
recognised in commands by the player.

(*) The "language of syntax" (LOS), which is the language the source text for the
story is written in.

Both are by default English. If the LOS is anything other than English, then the LOP
must be the same as the LOS. But English syntax has often been used to write
Inform stories with LOP other than English, and indeed this is the usual way to
write non-English stories. (It is an arduous process to make Inform work
with an LOS other than English, and the tool chain needs improvement in this
area. But Inbuild understands the necessary concepts, at least.)

The LOP is recorded on the Library Card index entry for an Inform project,
and is also included in the iFiction record of a released story.

@ Inbuild recognises the language of play by looking at the opening, or
"bibliographic", sentence of an Inform project. For many projects this
consists of a title and perhaps an author, like so:

>> "Why Didn't They Ask Evans?" by Agatha Christie

But it can optionally add a bracketed note giving the language:

>> "Le Port des brumes" by Georges Simenon (in French)

This bracketed note can take two forms. If it begins "in", then the rest must
be the English form of the name of a language -- in this instance, "French".
This must be a language for which Inbuild can find a language bundle (see below).
The LOP will be French, and the LOS will be English.

If the note does not begin "in", then it must be text recognised by a language
bundle visible to Inbuild (see below). For example:

>> "Le Port des brumes" by Georges Simenon (en français)

This time the LOP and LOS are both French. Inbuild was able to determine that
because the French language bundle picked up on the phrase "en français", which
Inbuild itself does not recognise.

@h Language bundles.
Inform can only compile a project whose LOP is other than English if it is
given extra resources to do so: the default installation covers only English.
In a typical situation, three resources are needed:

(*) A language bundle, such as "French".
(*) A kit of Inter code, such as "FrenchLanguageKit".
(*) An extension of Inform 7 source text, such as "French Language by Paul Mensonge".

Note: In fact at present the Inform installation does ship with language bundles
for English, French, German, Italian, Spanish and Swedish, but those other than
English are likely to be dropped from the core installation in a future release,
and we recommend that groups of translators begin to keep their own copies,
distributing those alongside the necessary kit and extension.

@ Language bundles should be stored in a subdirectory called "Languages",
either of an individual project's Materials directory (in which case they will
be visible just to that project) or in a so-called "nest" of resources. Language
bundles shipped in the core Inform distribution are at |inform7/Internal/Languages|.

Each language bundle is itself a directory, whose name must be the English name
of the language (for example, |French|). In v9 (and early betas of v10) of Inform,
this directory then contained a file of metadata called |about.txt|. This file
is now forbidden to exist, and instead there must be a file called |language_metadata.json|.
This is a JSON file very similar to the ones used for kit metadata: see //A Guide to Kits//,
which it is probably helpful to read before going much further with this.

For example:
= (text)
{
    "is": {
        "type": "language",
        "title": "French"
    },
    "needs": [ {
		"need": {
			"type": "kit",
			"title": "FrenchLanguageKit"
		}
	} ],
    "language-details": {
		"translated-name": "Français",
		"iso-639-1-code": "fr",
		"translated-syntax-cue": "en français"
    }
}
=
Note that at present language bundles have no authorship, so that the |"is"|
object does not give an |"author"| field. (This may change in later builds.)
Language bundles can have version numbers, like so:
= (text)
    "is": {
        "type": "language",
        "title": "French",
        "version": "2.3.17"
    },
=
But the English language kit shipped with Inform is not version-numbered.

@ A language bundle can only have unconditional "needs", each of which must
be a kit, and there always has to be at least one kit. If at all possible,
use exactly one kit, and give it a name in the form |WhateverLanguageKit|,
where |Whatever| is the English form of the language's name. Thus
|SpanishLanguageKit|, not |EspanolLanguageKit|.

The kits listed by a language bundle are automatically included by Inbuild
when compiling a project whose LOP is that language.

Note that a language bundle does not have an extension among its "needs". It
would be incorrect to write:
= (text)
    "needs": [ {
		"need": {
			"type": "kit",
			"title": "FrenchLanguageKit"
		}
	}, {
		"need": {
			"type": "extension",
			"title": "French Language",
			"author": "Paul Mensonge"
		}
	} ],
=
Although the extension is indeed necessary, it should be given in the "needs"
of the kit |FrenchLanguageKit|, not of the language bundle "French". Thus
= (text)
French --- needs --> FrenchLanguageKit --- needs --> French Language by Paul Mensonge
=

@ The |language-details.translated-name| field is required, and should the the
language as it is normally written in the language itself: thus, |Deutsch| not
|German|.

As its name suggests, the |language-details.iso-639-1-code| field should be
a valid ISO 639-1 code for the language in question -- a two-letter code such
as "de" (German) or "hr" (Croatian). See for example
//Wikipedia -> https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes// for a complete list.

The field |language-details.translated-syntax-cue| is optional. If given, it's
a "cue" to say that the LOS is this language: see above. For example, it might
be |en français|. Note however than this cue text must not start with the word
|in|, as that would lead to ambiguity about whether the LOP or the LOS is being
set. So, for example, |scritto in italiano| not |in italiano|.

If the user tries to build a project "scritto in italiano", then Inbuild will
read a file of Preform declarations called |Syntax.preform| inside the bundle:
in this example, at |Italian/Syntax.preform|. Should such a file not exist (or
not declare any nonterminals) then Inform will produce a problem like so:
= (text)
Problem. The project says that its syntax is written in a language other than
English (specifically, Italian), but the language bundle for that language does
not provide a file of Preform definitions.
=

@ Finally, there is a very sketchy ability for a language bundle to localise
the Index for a project: see e.g. |inform7/Internal/Languages/French/Index.txt|.
Note that this takes effect only if the user asks it to with a use option:
= (text as Inform 7)
Use French language index.
=
