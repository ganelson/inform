P/champ: The Champollion Project.

This is a manifesto for the translation of Inform.

@h Preface.
Inform is one of the hardest programs in the world to internationalise, that
is, to adapt so that it can be used by speakers of many different languages.
Until February 2011, Inform could read only English natural language, and
the compiler was riddled with English-only assumptions. It contained nearly
1000 words of hard-coded English vocabulary, for instance, which the user
could do nothing to change. But that's no longer true, and it is time to
begin looking forward to a multilingual Inform.

It will be a big task to reach this goal, and will need a lot of help from
volunteers. A project as ambitious as this might as well have a name, so
let's call it Champollion, after Jean-Fran\c cois Champollion (1790-1832),
the decipherer of the Rosetta stone. (We shouldn't call it Rosetta since
there's already a technology of that name, to do with processor architectures
on Apple Macintosh computers.)

Saying "Inform runs in English" is too ambiguous. We need some definitions:

(a) The language of play is the natural language which an eventual player of a
story file will read and type.

(b) The source language is the natural language in which a source text is
written.

(c) The presentation language is the natural language used in Problem
messages, in the Index, and so on.

(d) The documentation language is the natural language in which the two
built-in manuals, {\it Writing with Inform} and {\it The Inform Recipe Book},
are written.

(e) The interface language is the natural language used by the Inform user
interface applications -- for menu items, window title bars, dialogue boxes
and such.

@ The situation at the end of 2010 was as follows:

(a) The language of play can be any of English, French, German, Italian, and
Spanish. An Inform author chooses this by including a suitable extension --
for example, "Include Italian by Massimo Stella". The low-level Inform 6
basis for run-time code has quite a good understanding of language, but
Inform 7 doesn't.

(b) English only.

(c) English only.

(d) English only, though people have occasionally written to the authors
to ask permission to translate parts of the documentation, so some work
may have been done on this.

(e) English only.

Internationalising Inform 7 has always been a long-term goal, and work has
quietly been going on towards this since 2006; but the next public build
will make a big move in this direction. We're circulating a draft of this
build to the current Inform translators well in advance, because it will
be a big and disruptive change. Existing language extensions will need to
be considerably extended, rearranged, and renamed. On the other hand,
Inform's much better understanding of linguistics will make the new language
extensions more powerful and flexible.

@ First of all, Inform now understands the concept of "natural language".
When it starts up, it looks for folders called "language bundles" in the
following places:

	|X.materials -> Languages|
	|Library -> Inform -> Languages|
	|and a folder built in to Inform|

where "X" is the name of the project being compiled. (In other words, the
rules for finding languages are exactly like those for finding extensions
or website templates; if you create a language bundle called "French" in
your materials folder, that takes precedence over a built-in one, and so on.)

Each language bundle is a single folder whose name must be the English name
for the language: for example, "French", not "Fran\c cais".

The language bundle {\it does not replace} the language extensions we already
have; Inform needs both. Bundles contain only a minimum amount of information,
and copies for the existing translations will all be built in to Inform.
Since the bundles will be part of core Inform, not in Extensions, translators
who want to make changes will have to submit them to the Inform team. My
hope is that (once we get them working) we will change these bundles very
little.

At present, each bundle folder contains:

(a) A 16 by 11 pixel PNG flag icon called |flag.png|.

(b) A very small file of metadata about the language, called |about.txt|. This
is a Unicode file, and contains at present just five pieces of information: (1)
the language's name in English; (2) its native name, in its own language; (3) how
the language would describe text written in itself; (4) the standard ISO 639-1
two-letter language code; and (5) the name of the translator, that is, the
author of the language extension. For example, for German:

	|1	German|
	|2	Deutsch|
	|3	in deutscher Sprache|
	|4	de|
	|5	Team GerX|

Standard flag icons are from:

	|http://www.famfamfam.com/lab/icons/flags/|

Standard language codes are from:

	|http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes|

The language code is written to a new |<language>| field in the iFiction
record of any game released; this enables IFDB to detect the language
automatically.

In future the bundle folder will be able to hold other useful resources:
translations of problem messages, for example.

The draft build for Inform has English, French, German, Italian and Spanish
bundles already included, so you don't need to make these.

@ The way that the source text chooses a language has changed. Up to now,
the user typed something like this:

>> Include French by Eric Forgeot.

With this draft build, the user doesn't type an inclusion sentence. Instead,
the language is indicated in the titling line. There are two alternatives:
either

>> "Les Filles du Calvaire" by Pierre Combescot (in French)

or

>> "Les Filles du Calvaire" par Pierre Combescot (en fran\c cais)

The first version says that the source text is in English, but that the
language of play will be French. The second version says that both are
in French. (This second version doesn't work yet, of course; but it's how
we will do things when we get there.)

@ Language extensions are extensions like any others, except that they have
to be named in a special way:

>> French Language by Eric Fourgeot
>> Italian Language by Massimo Stella

and so on. Thus the first change translators will need to make is to rename
the extension with "Language" added. Inform now has a built-in extension
called

>> English Language by Graham Nelson

and the previous attempt at this (English by David Fisher) has been withdrawn.
Note that all Inform projects automatically include English Language, even
projects which play in other languages.

When Inform reads this:

>> "Les Filles du Calvaire" by Pierre Combescot (in French)

it still automatically loads the Standard Rules and English Language, but
it also looks for an extension called French Language; if it finds this, it
will include it.

The English Language extension is not like other language extensions, so
don't use it as a model: instead, see the draft of French Language circulated
with this document.

@ New-style language extensions are more complicated than existing ones, and
they need to do more work. Inform aims to be able to tell stories in any
tense, and from any viewpoint, and in any language -- this is quite an
ambitious goal. It now has several kinds used for linguistics:

(a) "Natural language". An instance of this kind is created automatically
for each language bundle Inform can see. The default value is "English
language" (which Inform creates even if it can't find any bundles at all).
The variable "language of play" has this kind, and is set to the language
read and typed by the eventual player. It cannot be changed during play.

(b) "Grammatical gender". This is a kind with three instances: neuter gender,
masculine gender, feminine gender. The default value is neuter gender. For a
language like Danish where masc. and fem. have amalgamated into a "common"
gender, use masculine for this. Don't define extra genders; they won't work.
In a language with genders, every object has a grammatical gender as a property.
(Inform also automatically gives it the Inform 6 |female| or |neuter| attribute
to match, just as in previous builds.)

(c) "Grammatical tense". This has five instances by default: present tense,
past tense, perfect tense, past perfect tense, future tense. Language
extensions are allowed to create up to two additional tenses, but of course
they then have to go to extra work to show Inform how to use them. French
Language creates one extra, the past historic tense, as an example of this.
The variable "story tense" is set to the tense in which the story is
currently being printed: by default, the present tense, but this can be
changed during play -- for instance, there could be a dream sequence in the
future tense, or a memory of previous events told in the past tense.

(d) "Grammatical case". This is for noun cases such as nominative, dative,
and so on, for languages which use them. Inform's support for this is mostly
incomplete at present: the only cases are "nominative" and "accusative".
But you can add more.

(e) "Narrative viewpoint". The narrative viewpoints are first person singular,
second person singular, third person singular, first person plural, second
person plural, and third person plural. The variable "story viewpoint" holds
the one currently used, and can change during play.

For example, in English, the text

>> "[We] [open] [the noun], which [are] unlocked."

adapts itself automatically to story tense and story viewpoint as well as to
the gender and number of the noun:

>> You open the cupboard, which is unlocked.
>> He opened the cupboard, which was unlocked.
>> We have opened the boxes, which have been unlocked.

In languages with genders, a list of objects with mixed genders is masculine.
So, for example,

>> "[The list of things in the coffret]: [grand]."

could produce any of:

>> Le chien: grand.
>> La baguette: grande.
>> La baguette et la plume: grandes.
>> Le complet et la cravate: grands.

@ Once a language extension is in place, Inform also makes it possible to
write assertion sentences in the language of play. For example, here is part
of one of Eric Forgeot's examples of French Inform:

>> The Grand Hall de Fihnargaia is a room. Some gardes are men in Grand Hall de Fihnargaia.

This can now be written like so:

>> Le Grand Hall de Fihnargaia est une place. Des gardes sont hommes dans le Grand Hall.

Note that Inform works out the genders and numbers from the articles and
kinds (it knows that "hommes", men, are masculine in gender; it knows that
"des" means a plural, and "une" means feminine singular, and so on).
Eric's example continues:

>> Some lampes are female device in Petit Couloir.

We can now write this as:

>> Des lampes (f) sont m\'ecanismes dans Petit Couloir.

"Des" doesn't tell Inform the gender of what it refers to, and Inform
doesn't know the word "lampe", so it doesn't know whether "Des lampes" is
a masculine plural or a feminine plural. To help with this, Inform has a new
feature: when an object is created, if its name ends (n), (f) or (m) then
Inform will give it neuter, female or male gender.

Inform also allows us to use numbers from the language of play. For example:

>> Un gateau is a kind of thing. Quatre gateaux sont dans Petit Couloir.

As this example shows, we still aren't ready to write everything in French,
but we get steadily closer. Here Inform does know that "gateau" is masculine,
so four objects will be created, each with the name "gateau" and the masculine
gender.

Finally, we can say that things are here, carried, or worn:

>> Des soldats (m) sont ici. Le ch\^apeau est port\'e. Le gadget est r\'ealis\'e.

@ To handle all of this, language extensions will now need to give Inform much
more information than in past builds. English is actually quite a simple case,
since it's not very inflected. In French, for example, "unlocked" would
also need to adapt, in order to agree with the gender and number of the
thing being opened. To do all of this, Inform needs much more help from
language extensions.

Firstly, they will need some rearrangement, and I suggest the following
heading structure.

@h Volume 1 - Settings.
This is a single short section, of new material. Some basic choices are made
here -- does the language have genders, does it have unusual tenses, and so
on.

@h Volume 2 - Language.
This contains the real linguistic work.

@h Part 2-1 - Determiners.

@h Chapter 2-1-1 - Articles.
There are three tasks here:

(a) We provide equivalents to the text substitutions "[The ...]", since it makes
text much more readable for very little work.

(b) We provide Preform grammar for definite and indefinite articles, and also
for a few useful words like "ici" (French for "here"). Preform grammar is
a new metalanguage inside Inform which expresses its syntax. This will
eventually be used so that language bundles can completely replace English as
the source text language, but that's for the future. Preform will not be
explained here: see the document {\it The English Syntax of Inform} for more
details.

(c) We provide the following Inform 6 constants, arrays, and routines, exactly
as in past builds:

	|LanguageAnimateGender|
	|LanguageInanimateGender|
	|LanguageContractionForms|
	|LanguageContraction|
	|LanguageArticles|
	|LanguageGNAsToArticles|

@h Chapter 2-1-2 - Numbers.
We include the I6 array |LanguageNumbers| and routine |LanguageNumber|, which
have not changed, but we also do something new: we include Preform grammar
for the names of the small ordinal and cardinal numbers.

@h Part 2-2 - Nouns.

@h Chapter 2-2-2 - Pronouns and possessives for the player.
English Language defines the following text substitutions:

	|"[We]" or "[we]"|
	|"[Us]" or "[us]"|
	|"[Our]" or "[our]"|
	|"[Ours]" or "[ours]"|
	|"[Ourselves]" or "[ourselves]"|

In this section we define equivalents. Note that the style has changed; we
are trying to avoid hyphenations, or names like |Him-or-Them|. (It isn't always
possible.) In French, they come out to:

	|"[Tu]" or "[tu]"|
	|"[Te]" or "[te]"|
	|"[Ton]" or "[ton]"|
	|"[Le tien]" or "[le tien]"|

and so on. A variable called "adaptive text viewpoint" tells Inform what
person these are written from -- in this case, second person singular; whereas
English uses second person plural.

@h Chapter 2-2-3 - Pronouns and possessives for other objects.
These are similar, but easier. They are named from the third-person viewpoint
with the same number as the adaptive text viewpoint; so in the case of French,
we'll go with third person singular. We define:

	|[celui] = that|
	|[il] = it as subject|
	|[le] = it as object|
	|[lui] = it as indirect object|
	|[son] = its as adjective, e.g., "its temperature"|
	|[le sien] = its as possessive pronoun, e.g., "that label is its"|

and similarly for its capitalised forms.

@h Chapter 2-2-4 - Directions.
Here we use a new feature of Inform:

>> North translates into French as le nord.

This allows a language extension to give a French name to a kind or instance
which already has an English name: in this case, the direction "north",
which is created by the Standard Rules. The French name is the one used in
play, both for printing and for command parsing. Note the article "le",
which tells Inform the gender and number of the name (singular, masculine).
This is all much easier than writing:

>> The printed name of north is "nord". North is male. Understand "nord" as north.

If there are abbreviated names for directions, this is where to put them:

>> Understand "nord-est/nordest" or "ne" as northeast.

@h Chapter 2-2-5 - Kinds.
This is new material. We give translations of the names of all kinds of
objects created in the Standard Rules or other built-in extensions.
For example,

>> A player's holdall translates into French as un fourre-tout.

Note an important change: language extensions are now expected to translate
for every extension built in to Inform, not just the Standard Rules. I've
given each such extension a section number (2-2-5-1, and so on).

@h Chapter 2-2-6 - Plurals.
This is new material. We must give Inform instructions on how to form the
plural of a noun, and we do this by writing a "trie" using Preform grammar.

For more on tries, it may be helpful to see how Inform defines English
inflections, since that's a simple case. See {\it The English Syntax
of Inform} for more details.

The circulated draft of "French Language" defines a method like so:

(a) a list of about 25 irregular plurals, such as "pneu" to "pneus";
(b) a general rule based on noun endings, such as that a noun ending in "eu"
normally forms a plural by adding "x" -- for example "neveu" becomes
"neveux";
(c) a default rule to use if none of these apply -- add "s".

It's important to be as thorough as possible in covering irregularities and
exceptions. (The ten most commonly used verbs in English and French, for
example, are all irregular; but the writer will expect them to work.)

@h Chapter 2-2-7 - Cases.
This will be significant for languages like German, but for French there's
nothing to do. This part of Inform's adaptive text support is still being
worked on.

@h Chapter 2-2-8 - Times of day.
Inclusions of the I6 routines |PrintTimeOfDay|, |PrintTimeOfDayEnglish|,
and |LanguageTimeOfDay|. These have not changed.

@h Part 2-3 - Adjectives.
This is new material. Adjectives in Inform can have six different forms:
neuter singular, neuter plural, masculine singular, masculine plural, feminine
singular, feminine plural. In English all six forms are always the same, but
that's not true in most other languages. Once again, we use tries to work
from a base form (neuter singular) to the other five. For example, in
French, suppose we start with "nouveau" as our base.

(a) The neuter singular is just "nouveau".

(b) The trie |<adjective-to-plural>| makes the neuter plural (n.p.), but we
don't worry about this, because French doesn't use neuters anyway.

(c) The trie |<adjective-to-masculine-singular>| converts the n.s. to the
m.s., but in French it doesn't change anything, i.e., we use the base text
of the adjective as the m.s.

(d) The trie |<adjective-to-feminine-singular>| converts the n.s. to the
f.s., turning "nouveau" into "nouvelle".

(e) The trie |<adjective-to-masculine-plural>| converts the m.s. to the m.p.,
turning "nouveau" into "nouveaux".

(f) The trie |<adjective-to-feminine-plural>| converts the f.s. to the f.p.,
turning "nouvelle" into "nouvelles".

A useful feature for adjectives: the following source text --

>> "Sample" (in French)
>> Conjugatorium is a room.
>> Test adjective (internal) with informatif.

-- causes Inform to print out all six forms for the adjective given, in this
case, "informatif" (which doesn't have to be one defined already).

@h Part 2-4 - Verbs.
This is the most challenging part of the language extension to write. We
have to explain to Inform how to construct every person, in every tense,
of every verb in the language, even highly irregular ones. English and
French are contrasting here: English has very little inflection in the
verb, but has about 640 irregular verbs, and has spelling rules which
depend on pronunciation; French has only about half as many irregulars,
but gives them an enormous variety of word endings.

@h Chapter 2-4-1 - Verb conjugations.
Preform grammar is used in three different ways in Inform: to specify simple
syntax; or to specify a trie, a device for altering word endings; or to
specify a verb conjugation. It's an extremely flexible notation, allowing
us to construct multiple stems and then apply endings depending on tense,
mood (active or passive), sense (positive or negative), person, number;
and we can mark certain words, such as participles, as needing adjectival
agreement. This means that

>> In French craindre is a verb.

will automatically create a text substitution "[craignis]" which can
come out in about 100 different forms: "a crainte" (a female person has
been feared), "craignirent" (third-person plural past historic active),
and so on. But we only get these benefits by writing an exhaustively
detailed description; for French, it took 2200 lines of Preform code.

See {\it The English Syntax of Inform} and "French Language" for
explanations of the notation here.

A useful feature for testing verb conjugation: the following source text --

>> "Sample" (in French)
>> Conjugatorium is a room.
>> Test verb (internal) with avoir.

-- causes Inform to print out its full conjugation for the verb "avoir"
in French, and of course any verb can be placed there, including one which
Inform doesn't otherwise define.

@h Chapter 2-4-2 - Meaningful verbs.
"Meaningful" verbs are the ones which are defined with a meaning, like this:

>> In French avoir is a verb meaning to have.

We write a definition like this corresponding to each verb defined by Inform:
to be, to have, to relate, to provide, to contain, and so on.

Once again this chapter is divided by sections, one section on each built-in
extension which defines verbs.

@h Chapter 2-4-3 - Prepositions.
And this is similar, but for prepositions:

>> In French \^etre voisin de is a verb meaning to be adjacent to.

@h Volume 3 - Responses.
The main task of a language extension used to be to write many Inform
constants:

	|Constant CANTGO__TX = "Je ne peux pas aller dans cette direction.";|

and to define a huge I6 routine called |LanguageLM|, providing about 300
"library messages". (If you wanted multiple viewpoints, you had to define
the routine several times over.) However, the use of library messages wasn't
universal across the Standard Rules, so translations used to have to replace a
few rules from SR as well. Lastly, it was only possible to translate the text
from the SR, not from, for example, useful built-in extensions like Locksmith
or Rideable Vehicles.

All of that is changed. The |*__TX| constants no longer exist; all rules in
the SR and other built-in extensions are routed through the new Responses
system. These are all written in adaptive text so that they can appear in
any tense, and so on. Library messages were numbered by action; responses
are lettered (A, B, C, ...) within each named rule.

@h Part 3-1 - Responses.
This is where we write out the responses in our new language. The draft
"French Language" extension doesn't do this: a French speaker will have
to fill all of this in, which really means converting the text from the
old I6 format to the newer, and much more readable, I7 format. Here
are some samples. We first define a meaningless verb and adjective, just
so that Inform will be able to adapt them:

>> In French passer is a verb. In French ouvert is an adjective.

And now we set two responses:

>> Standard report waiting rule response (A) is "Le temps [passes]...".

>> Can't open what's already open rule response (A) is "[regarding the noun][Il] [es] déjà [ouvert]."

The RESPONSES testing command can help a great deal with this. For example,

	|RESPONSES SET 1|

produces all of the definitions of the English messages, which you can cut
and paste before you start translating.

@h Part 3-2 - The Final Question.
Translations used to replace the little section in the Standard Rules which
defined options for the final question. This is no longer necessary, because
a new feature of Inform allows tables to be replaced:

	|Table of Final Question Options (replaced)|
	|final question wording	...|
	|"RECOMMENCER"			...|
	|...|

That replacement table occupies this part.

@h Volume 4 - Command parsing.
The remainder of the extension consists of material which hasn't changed.

@h Part 4-1 - Pronouns and possessives in commands.
The Inform 6 definitions |LanguagePronouns| and |LanguageDescriptors|.

@h Part 4-2 - Understand grammar.
This is where the "Understand" sentences should appear:

>> Understand "mode court" as preferring abbreviated room descriptions.

and so on. Note that by default the English command grammar still exists;
you need to remove it if you don't want to allow English verbs.

This should also include grammar for the other built-in extensions (e.g.,
for "Rideable Vehicles"), but the draft French Language doesn't yet do so.

@h Part 4-3 - Command parser internals.
I6 definitions |LanguageVerb|, |LanguageVerbLikesAdverb| and
|LanguageVerbMayBeName|; and the keywords used by the parser (|AGAIN1__WD|,
and so on).

@h Part 4-4 - Informese translation of commands.
The Inform 6 |LanguageToInformese| routine, and any supporting I6 code it
needs.

@h Source text language: future developments.
The ultimate goal is to be able to write the source text in the language
of play. French Inform users will simply type their IF in French, and
play the result in French; and similarly for other languages, of course.
But this goal is still some way away.

At present, the plan is to do this in three phases:

(1) In Phase 1, the current draft build of Inform will be released.
This will make the adaptive text and responses features available to users,
but it will break all existing language extensions. So the draft build is
being given to translators to give them a head-start in making new-style
language extensions. Phase 1 will be complete when we have good-quality language
extensions for all the main European languages currently supported: French,
German, Italian and Spanish. German will need the most work, since noun
inflection isn't yet finished.

(2) In Phase 2, a source text called "Rosetta" will be written, using the
entire syntax of Inform. Volunteers will then be asked to translate Rosetta
into their own languages, just as if they were translating a piece of text
like a newspaper article. This will probably be quite boring to do, but it
needs to be done well; the choices made might affect Inform for a long way
into the future. Up to a point, of course, the translation should follow the
English quite closely -- but it's important that German source text should
read as natural to a German person, and so on. We don't want the whole thing
to end up reading like a Japanese camera manual. Phase 2 will be complete when
we have Rosetta in every language.

(3) In Phase 3, we use the Rosetta translations to write Preform syntax
(and possibly other definitions) for languages other than English. Phase
3 will be complete when Inform can compile Rosetta in every language.

As we make progress towards this goal, we will also want to do something
about the languages used for presentation and documentation.

@h The presentation language. The main issue here is to do with Problem
messages -- there are about 750 of them. At least the common ones need to be
translated for two reasons; first, because we want people who don't know
English well to be able to use Inform; second, because they often refer to
correct Inform syntax. For example:

{\narrower ...this seems to give something a name which consists only of an article,
that is, "a", "an", "the" or "some". This is not allowed since the
potential for confusion is too high. (If you need, say, a room which
the player sees as just "A", you can get this effect with: "A-Room is
a room with printed name "A"".)}

If Inform is reading French source text then this message will be issued
when somebody gives something the name "une", for example; so it will be
very misleading in English.

Since 2008 or so, Inform has issued problem messages in a systematic way,
giving each different message its own unique identifier -- for example,
|PM_NoSuchPublicRelease|. These IDs are called "sigils". They never
appear on screen and will not be translated, of course. Instead, Inform
will allow translators to provide a file which gives a translation for each
sigil. (In fact, it will allow them to translate only some problem messages:
those which are translated will be used on screen, but with an icon allowing
the user to see the English version instead; and those which haven't been
translated will be given in English only.) Inform internally generates
Problem messages using text like:

	|While working on '%1', I needed to be able to make a default value|
	|for the kind '%2', but there's no obvious way to make one.|

So it should be fairly straightforward to enable Inform to read in other-language
versions of these messages from a file in the language bundle.

Testing these problem messages is another matter. We have a suite of 750
test cases which generate them, and an automated tool, |intest|, for checking
that they are all correctly produced, but those test cases are all written
in English. If you want to test the French version of |PM_NoSuchPublicRelease|,
you'll first have to translate its test case into French.

@h The documentation language. Inform generates the HTML form of its manuals
used in the applications from a marked-up plain text version, using a special
tool called |indoc|. In principle, there's no reason why the plain text
version shouldn't be run through |indoc| as well, though there are some
practical issues to sort out about where the HTML will be stored -- perhaps,
once again, in the relevant language bundle.

However, it's not a small task to translate whole books -- not to mention
the many, many Examples - and since the documentation has to talk about the
source syntax, we really shouldn't even start this process until the syntax
for each language has been worked out.

@h The interface language. This should be quite easy to change, though it's our
lowest priority. Mac OS X, Windows and Gnome for Linux all provide standard
ways to do this. The inconvenient point is that they are different ways on
each platform, so the work needs to be done three times.
