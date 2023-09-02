# Ran Out of Space

The application ran your source text through the Inform 7 compiler, as usual,
and it found no problems translating the source. This process results in what's
called a "story file", which is a program for a small virtual computer.
Unfortunately, the story file for this source text was too big for that virtual
machine: there's just too much of it.

Inform can produce story files for several different virtual computers, and the
one used by the current project can be selected using the Settings panel. If you
are currently using the "Z-machine" format, try switching the project to "Glulx"
format (you can make this change at the Settings panel), and limits like this
will probably not bother you again. Although Z-machine story files used to be
much more widely playable than Glulx ones, these days Glulx interpreters are
widely available, so it's probably not worth making big sacrifices to stay
within the Z-machine memory size.
