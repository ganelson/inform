# Failed

The application ran your source text through the Inform 7 compiler, as usual,
but the compiler unexpectedly failed. This should not happen even if your source
text is gibberish, so you may have uncovered a bug in the program.

When a program like the I7 compiler fails, it typically returns an error number:
this time, the number was 11, and that probably indicates that the compiler
failed to manage its data structures properly. Perhaps you created a complicated
situation on which it has not been fully tested.

The best option now is probably to reword whatever was last changed and to try
again. Subsequent attempts will not be affected by the failure of this one, so
there is nothing to be gained by restarting the application or the computer. A
failed run should never damage the source text, so your work cannot be lost.

If you think it likely that the Inform 7 compiler is at fault, please check that
you have the currently distributed build of the system: if you have, please
consider taking the time to fill out a bug report at the Inform bug tracker
(www.inform7.com/bugs). If you think the fault may be due to a problem in an
extension you're using, then please contact the extension's author directly.
