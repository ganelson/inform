# Failed

The application ran your source text through the Inform 7 compiler, as usual,
but the compiler unexpectedly failed. This should not happen even if your source
text is gibberish, so you may have uncovered a bug in the program.

When a program like the I7 compiler fails, it typically returns an error number:
this time, the number was 2, so I7 probably stopped because of a fatal
file-system error.

It is very unlikely that your computer is at fault. More likely causes are:

* disc space running out on the volume holding the project;
* trying to run a project from a read-only volume, such as a burned CD or DVD;
* trying to run a project which belongs to another user, whose files you have no permission to alter.

However, if you think it more likely that the Inform 7 compiler is at fault,
please check that you have the currently distributed build of the system: if you
have, please consider taking the time to fill out a bug report at the Inform bug
tracker (www.inform7.com/bugs).
