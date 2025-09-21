# Inform 6

This is Inform 6.44, copyright (c) Graham Nelson 1993 - 2025, a compiler for
interactive fiction (text adventure games).

Release notes, manuals, executables and more are available from
https://ifarchive.org/indexes/if-archive/infocom/compilers/inform6/.

## Introduction

Back in the late 1980s, people began investigating the format of Infocom's
text adventures. Infocom used a standard format that defined a virtual
machine, which has come to be known as the Z-Machine, to allow them to be
able to port their games to many different computers. This investigation lead
to the creation of open source implementations of the Z-Machine, such as the
InfoTaskForce interpreter, Zip, Frotz, and many others.

In 1993, Graham Nelson released the first version of Inform, which compiled a
somewhat C-like language ("Inform") to the Z-Machine. In the years that
followed this led to the creation of hundreds of free games by a community
that had sprung up based around the Usenet group rec.arts.int-fiction.

The latest version of Inform is [Inform 7](http://inform7.com/), but Inform 6
still lives on, both as the code generator used by Inform 7, and as a language
and compiler in its own right. Inform 6 is now considered stable and only has
bugs fixed and minor, non-breaking features added, but development continues.

## Using Inform 6

To use the compiler, you will need an executable. There are
[pre-built executables](https://ifarchive.org/indexes/if-archive/infocom/compilers/inform6/executables/)
available, or you can compile the source yourself. There is no makefile as
compilation does not really need one: all that is required is a C compiler and
for it to be invoked with something like

      cc -O2 -o inform *.c

Suitable defaults for various operating systems can be selected by defining
the appropriate symbol, a list of which are near the top of the "header.h"
file (under "Our host machine or OS for today is..."). For example, to compile
for Windows, use

      cc -DPC_WIN32 -O2 -o inform *.c

To write a work of interactive fiction with Inform 6, you will also need a
version of the Inform 6 library.
[Stable versions](https://ifarchive.org/indexes/if-archive/infocom/compilers/inform6/library/)
of the library are available, and development of the library continues in a
[separate project](https://gitlab.com/DavidGriffith/inform6lib).

More resources and documentation, including the Inform Designer's Manual, are
available from the [Inform 6 web site](https://www.inform-fiction.org/).

