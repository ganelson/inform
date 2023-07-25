Documentation Markup.

How to mark up the plain-text source for Inform documentation.

@h Volume files.
Documentation source is written in UTF-8 encoded plain text files. Except
for the markup notations described below, these really are plain text,
using skipped lines as paragraph breaks, and tabs for indented quotations:
= (text as Indoc)
	This is a paragraph of some text, which
	extends over perhaps many lines. All of the
	standard letters are allowed:
	
	    The quick brown fox jumped over the lazy dog.
	    Jinxed wizards pluck ivy from my big quilt.
	    Jackdaws love my big sphinx of quartz.
	
	The second para begins here, after the
	skipped line.
=
Note that line breaks in quotations are respected, whereas in regular
paragraphs they are not, and are treated as ordinary white space.
Lines in quotations can be indented still further with more tabs, and
those margins are preserved.
= (text as Indoc)
	For example:
	
	    Instead of waiting when the prevailing wind is northwest:
	        say "A fresh gust of wind bowls you over.";
	        now the prevailing wind is east.
=
"Quotations", as this suggests, are often in fact code examples for some
programming language.

@ In general, plain text means just what it says. Raw HTML should not be
included in documentation; but the syntax <b>Bold</n> and <i>Italic</i> is
an exception.

@ Tables are formatted automatically whenever Indoc sees a pattern like this:
= (text as Indoc)
	    {*}Table 2 - Selected Elements
	    Element    Symbol  Atomic number
	    "Hydrogen" "H"     1
	    "Iron"     "Fe"    26
	    "Zinc"     "Zn"    30
	    "Uranium"  "U"     92
=
The top line is the title for the table, and then tab-delimited columns follow.

@ Recall that volumes are divided into chapters, which are themselves divided
into sections. A line in the form:
= (text as Indoc)
	[Chapter: CHAPTERTITLE] SECTIONTITLE
=
begins a new chapter, and simultaneously begins its first section; the first
line of a volume file must be of this form. For example,
= (text as Indoc)
	[Chapter: Things] Descriptions
=
When it's time for a new section within the same chapter, the simpler form:
= (text as Indoc)
	[x] SECTIONTITLE
=
is used. Note that although chapters and sections are both numbered, this
numbering is automatically applied by Indoc, and does not appear in the source.

The final paragraph of a section is allowed to take a special form:
= (text as Indoc)
	(See REFERENCE for PURPOSE.)
=
For example,
= (text as Indoc)
	(See Text with substitutions for more on varying what is printed.)
=
Here, the |REFERENCE| "Text with substitutions" is to another section in
the volume, having that title. Indoc will make this into a suitable link
in the generated HTML.

@ When a paragraph begins with |{CONTEXT:}|, it is included in the
generated documentation only for targets which match this context. A
context can be just a symbol created by |declare:| in the instructions
file, so for example:
= (text as Indoc)
	{Linux:}The top secret DRM decoder ring is not included under Debian...
=
would be included only if the instruction |declare: Linux| had been made
for the current target.

Contexts can however be compound, using the unary operator |^| (negation),
the binary |+| (conjunction), and binary |,| (disjunction), which associate
in that order. The simplest case is
= (text as Indoc)
	{^Linux:}The top secret DRM decoder ring is in the Goodies folder...
=
which is included if and only if |Linux| has not been declared. More elaborate
examples would be:
= (text as Indoc)
	{^alpha,beta+gamma:}
=
which is true if either |alpha| is undeclared, or if both |beta| and |gamma|
are declared; and
= (text as Indoc)
	{^(alpha,beta)+gamma:}
	{^alpha+^beta+gamma:}
=
which are both true if |alpha| and |beta| are undeclared but |gamma| is
declared.

@h Inform-specific markup.
A quotation beginning with |{*}| is given a "paste" button allowing its
content to be pasted into the Source pane of an Inform project -- though
of course, only for forms of the documentation appearing inside the Inform
UI app: it would be meaningless elsewhere.

A quotation beginning with |{**}| is a continuation of the previous
paste-this-in quotation.

@ In Inform documentation, the formal specification of a phrase can be
marked as in this example:
= (text as Indoc)
	{defn ph_randomdesc}a/-- random (description of values) ... value
	This phrase makes a uniformly random choice...
	...the result is the special value "nothing".
	{end}
=
The markers |{defn ph_randomdesc}| and |{end}|, which bookend the definition,
are invisible in the HTML output, but are used in the cross-referencing
material which Indoc produces for the benefit of Inform.

@ The Index pane, and problem messages, need to link into the documentation
inside the Inform app. We can prepare for this by tagging the opening line
of a section like so:
= (text as Indoc)
	[x] Rooms and the map {kind_room} {MAP} {PM_SameKindEquated}
=
This applies three tags to the section: |kind_room|, |MAP| and |PM_SameKindEquated|.
These are used by Inform for the helpful links in the Index or in problem
messages: for example, if the user generates the problem |PM_SameKindEquated|
(this is its internal designation, of course), a link will appear, and it
will be to this section, "Rooms and the map".

@h Indexing.
Indoc volumes are indexed in the same sort of way that books are, and
the author has to mark up indexing terms as they arise. The notation
for this is an elaboration of a scheme devised by Knuth for the TeX Book.
At its simplest,
= (text as Indoc)
	I am the ^{walrus}.
=
becomes simply
= (text as Indoc)
	I am the walrus.
=
in the generated HTML, but the position of the last word is added to a
new head-word in the index, "walrus". Where a double |^| is used, the
index entry is invisible in the text itself, and only the position is
marked. Thus
= (text as Indoc)
	I am the ^{walrus}.^^{Beatles}
=
A much more detailed description now follows.

@ Some generalities first. The index consists of "headwords", the terms being
indexed (which may or may not be just one word). Each headword is followed by
a comma-separated list of links to sections of the books - both books are
indexed, not just one. Links to the primary volume have the form "5.4"; links
to the secondary are the same, but italicised. The list of links is always
ordered numerically within the primary volume.

Headwords are alphabetized in a way which excludes initial "a", "an" or "the";
if the first word is a number from 1 to 12, it's replaced by the spelled
version (thus "3 A.M." appears as if "three A.M."); other numbers are sorted
numerically - thus "Zone 10" appears after "Zone 9", not after "Zone 1"; and
any bracketed text is ignored for alphabetisation purposes - so "(leaf) tea"
is alphabetised as if it were "tea".

Each headword has a "category". These categories must be defined in the
instructions file, using |index:|. An index entry is defined by both headword
and category in combination, so "description" with category "property" is
different from "description" with category "standard", and they appear on
different lines in the index.

In terms of CSS, index entries occupy paragraphs of class |indexentry|.
Text of an entry of category C is in a span of class |indexC| (so for example,
an entry of category "name" is in a span of class |indexname|). The links
are in spans of class |indexlink| for the primary volume, |indexlinkalt|
for the secondary.

@ If no categories are defined, there's no index. The instruction needed is:
= (text as Indoc)
	index: notation = name (options)
=
Notation is how indoc should recognise material to index; name is the name
of the category; the options, which are optional, specify anything special
about the category. There are three sorts of notation. The first is the
caret-and-brace form, for example:
= (text as Indoc)
	index: ^{`headword} = name (invert)
	index: ^{headword} = standard
=
With these notations in place, a sentence in the documentation can be
marked up like so:
= (text as Indoc)
	The inventor of ^{literate programming} is ^{`Donald Knuth}.^^{archaisms}
=
Indexable terms always start with one or two carets and then material in
braces. One caret means the copy in braces is part of the book; two means
it isn't. Thus the above sentence typesets as
= (text as Indoc)
	The inventor of literate programming is Donald Knuth.
=
A few points to note. The notations are sought in definition order, which
is why we defined ^{`headword} before ^{headword}. In general, the notation
has to be given in the form
= (text as Indoc)
	^{LheadwordR}
=
where |L| and |R| are clumps of 0 or more characters; for example,
|^{+headword+}| would be legal, as would |^{''headword---}|. (It is best
to avoid underscores, asterisks, and of course braces.)

The catch-all |^{headword}| notation has to refer to the category called
"standard", and should be defined last.

Indexing can be inserted into the body text of either volume, or in the
example files. However, they can't be placed in headings of any kind, or
in indented sample code paragraphs.

In general the index hyperlinks are to the top of the section cited, e.g., a
link to 3.2 goes to the top of section 3.2; or to the example cited, usually
at the bottom of some section; except that links to a phrase definition (in
Inform) go straight to its tinted box.

@ The options for categories are as follows:

Because the name category is marked |(invert)|, its entries are inverted.
Thus |^{Donald Knuth}| actually indexes as "Knuth, Donald", alphabetised
under K not D. Inversion is not performed if the text already contains a comma.
This can override wrong guesses. Thus:
= (text as Indoc)
	Extensions are managed by ^{`Justin de Vesine}.
=
indexes "Vesine, Justin de" (filed under V); but
= (text as Indoc)
	Extensions are managed by Justin de Vesine.^^{`de Vesine, Justin}
=
indexes "de Vesine, Justin" (filed under D).

An option in double-quotes becomes a gloss text for the category. What
that means is that this text is added as a gloss, in small type, after
every index entry of that category, using the CSS span |indexgloss|.
(By default, a category doesn't have a gloss.) Thus we might get index
entries like
= (text as Indoc)
	grouping together something  activity  18.14
=
with "activity" being the gloss text.

The option |(bracketed)| causes the index entry to be rendered with bracketed
material in a CSS span called |indexCbracketed|, where C is the category name.
For example, the Inform 7 Indoc instructions go on to say:
= (text as Indoc)
	css: span.indexphrasebracketed ++ {
		color: #8080ff;
	}
=
The practical effect is that the index entry:
= (text as Indoc)
	(name of kind) after (enumerated value)  phrase  11.18
=
has the bracketed parts tinted in a light blue for de-emphasis.

The option |(under {lemma})| causes all entries for this category to be
subentries of |{lemma}| - see below.

@ The second sort of notation is by documentation tag. An instruction like so:
= (text as Indoc)
	index: {act_} = activity ("activity")
=
This tells Indoc to pick up the tags used for links in the Inform app (see
above) and turn them into index entries too: in this case, any tag beginning
with |act_| will be turned into an index entry of category "activity" for the
section in question, using the title of the section as the text of the entry,
flattened in case. The practical effect, then, is that all activities are
automatically indexed.

@ There are also two built-in sources of index entries, though they have
to be activated to appear. The Indoc instructions for Inform activate both:
= (text as Indoc)
	index: definition = phrase ("phrase") (bracketed)
	index: example = example ("example")
=
"definition" isn't really a notation; it tells indoc to make an index entry
out of every phrase definition in the manual. Similarly, "example" makes
an index entry for every example.

@ If an entry's text contains a colon (with substantive material either side),
that's taken as a marker that something is a subentry. Thus:
= (text as Indoc)
	^{reptiles: snakes}
=
creates something like
= (text as Indoc)
	reptiles
	    snakes 3.7
=
while typesetting just "snakes". For example,
= (text as Indoc)
	"Why did it have to be ^{reptiles: snakes}?" mused Indy.
=
comes out as
= (text as Indoc)
	"Why did it have to be snakes?" mused Indy.
=
Sub-entries can be arbitrarily deep; there can be, but need not be, index
entries for the super-entry (in this case "reptiles").

We can also force every entry of a given category to fall as a subentry.
For example:
= (text as Indoc)
	index: ^{~headword} = reptilian (under {reptiles})
=
means that:
= (text as Indoc)
	"Why did it have to be ^{~snakes}?" mused Indy.
=
once again makes "snakes" a subentry of "reptiles".

Note the difference between these two examples:
= (text as Indoc)
	^{people: `Donald Knuth}
=
makes
= (text as Indoc)
	people    (category "standard")
	    Knuth, Donald    (category "name")
=
whereas
= (text as Indoc)
	^{`Donald Knuth: literate programming}
=
makes
= (text as Indoc)
	Knuth, Donald    (category "name")
	    literate programming    (category "standard")
=
This is because Indoc parses |{A:B}| as if it were parsing |{A}| and |{B}|
individually, to determine the categories of the superentry and subentry.

@ Lastly, an entry in the form:
= (text as Indoc)
	^{reptiles <-- crocodiles <-- alligators}
=
tells indoc to index "reptiles" here, in the usual way, but also to add
cross-references "crocodiles, see reptiles" and "alligators, see reptiles"
at the appropriate places under C and A.

@h Example files.
Recall that each Example provided with the documentation -- usually a
sample program -- has its own source file. For example, in the standard
Inform repository, the example Alpaca Farm lives in:
= (text)
	Documentation/Examples/AlpacaFarm.txt
=
Example files are just like volume files except that they open with a
special header of metadata. In this example, it's:
= (text)
	Example: * Alpaca Farm
	Location: New commands for old grammar
	RecipeLocation: Clarification and Correction
	Index: USE action which divines rational behavior for a wide range of possible nouns
	Description: A generic USE action which behaves sensibly with a range of different objects.
	For: Z-Machine
=
Line 1 is required to take the form |Example: *** TITLE|, for some number of
asterisks between one and four - a measure of difficulty/complexity. By
convention the filename will be the same as the title but with punctuation
removed, but that is just a convention, and any filename can be used.

After line 1, further metadata lines can optionally appear, in any order, and then there
should be a skipped (i.e. completely blank) line before the body of the example
appears.

The possible metadata lines are:

(a) |Location: SECTION| gives the section name which an example should go into,
in the primary volume, if there are two. (For Inform, that's "Writing with Inform".)

(b) |RecipeLocation: SECTION| similarly for the secondary volume. (For Inform,
that's "The Recipe Book".)

(c) |Index: ENTRY| gives the example this explanatory index entry in the alphabetical
index of examples.

(d) |Description: DESC| gives some text to use in the example heading, to explain
what it exemplifies.

(e) |For: PLATFORM| is to do with testing the example, and is ignored by |indoc|.

(f) |Subtitle: SUBTITLE| is used only for examples occurring in numbered sequences,
where the same idea is elaborated in successive examples. For example:

= (text)
	Example: * Port Royal 2
	Subtitle: With one-way connections added
=
