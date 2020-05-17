Performance Metrics.

Typical memory consumption, running time, and other statistics.

@h Introduction.
Whenever //intest// runs the |GenerateDiagnostics-G| test case, it runs
Inform with the |-diagnostics| switch set, so that the compiler writes some
statistics out to a set of text files. Those are used to generate the current
page, so what you're looking at is likely to be an up-to-date measurement of
how //inform7// spends its time. The source text being compiled is the
"Patient Zero" example from the Inform documentation, which is fairly
representative of smallish source texts.

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
