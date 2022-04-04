Performance Metrics.

Typical memory consumption, running time, and other statistics.

@h Introduction.
Whenever //intest// runs the |GenerateDiagnostics-G| test case, it runs
Inform with the |-diagnostics| switch set, so that the compiler writes some
statistics out to a set of text files. Those are used to generate the current
page, so what you're looking at is likely to be an up-to-date measurement of
how //inform7// spends its time. The source text being compiled is the
"Patient Zero" example from the Inform documentation, a distressing tale
about ice cream, but which is fairly representative of smallish source texts.
Performance scales roughly linearly with the size of the source text.

@h Running time.
The following tabulates all main stages of compilation (see //core: How To Compile//)
which take more than 1/1000th of the total running time.

= (hyperlinked undisplayed text from Figures/timings-diagnostics.txt)

@h Memory consumption.
The following gives some idea of which classes of object have the most
instances, and also of how Inform's memory tends to be used in practice.
Entries with a dash instead of a percentage are negligible, in that they
represent less than 1/1000th of the total.

= (undisplayed text from Figures/memory-diagnostics.txt)

@h Preform grammar.
The full annotated description of the Preform grammar (see //words: About Preform//),
with optimisation details and hit/miss statistics added, is also long: it's
roughly 10,000 lines of text, so we won't quote it in full here. This is a
sample, showing the nonterminal used to parse literals in Inform 7 source text:

= (undisplayed text from Figures/preform-summary.txt)

The unabridged grammar is here:

= (download preform-diagnostics.txt "Preform diagnostics file")

@h Syntax tree.
A full printout of the syntax tree is a roughly 20,000-line text file, and again
is too long to quote in full. This is a summary, showing just the portion of
tree from the main source text, that is, with the content of extensions
excluded, and with the content of |IMPERATIVE_NT| also cut. It still makes
for a lengthy read:

= (undisplayed text from Figures/syntax-summary.txt)

The unabridged tree is here:

= (download syntax-diagnostics.txt "Complete syntax tree")
