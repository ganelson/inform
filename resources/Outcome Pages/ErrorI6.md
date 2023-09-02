# Failed

The application ran your source text through the Inform 7 compiler, as usual,
and it found no problems translating the source. Something must have gone wrong
all the same, because the second stage of the process - using the Inform 6
compiler to turn this translated source into a viable story file - turned up
errors. This should not happen. The errors are written out on the Console tab,
but will only make sense to experienced Inform 6 users (if even to them).

The best option now is probably to reword whatever was last changed and to try
again. Subsequent attempts will not be affected by the failure of this one, so
there is nothing to be gained by restarting the application or the computer. A
failed run should never damage the source text, so your work cannot be lost.

If you are using Inform 6 inclusions, these are the most likely culprits. You
might be using these without realising it if you are including an extension
which contains Inform 6 inclusions in order to work its magic: so if the problem
only seems to occur when a particular extension is in use, then that is probably
what is at fault, and you should contact the extension's author directly.

If not, then most likely the Inform 7 compiler is at fault. Please check that
you have the currently distributed build of the system: if you have, please
consider taking the time to fill out a bug report at the Inform bug tracker
(www.inform7.com/bugs).
