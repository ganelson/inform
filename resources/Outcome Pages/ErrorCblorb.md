# Failed

The application ran your source text through the Inform 7 compiler, as usual,
and then manufactured the final story file using Inform 6: all of this worked
fine. However, the "inblorb" packaging tool then failed to make the actual
release of the data out of your project. Its errors are written out on the
Console tab.

This almost never happens in normal usage, and is almost certainly the result of
a "Release along with..." sentence in the source having asked to do something
impossible. For instance, an attempt to release along with cover art will fail
if there's no cover art provided, or it has the wrong filename or is in the
wrong place. So the best thing to do is probably to look carefully at any
Release instructions in the source, and check them against the documentation.
