# Inform 6 ran out of memory

The application ran your source text through the Inform 7 compiler, as usual,
and it found no problems translating the source as far as a sort of
intermediate-level code - a program for Inform 6, which would ordinarily then be
used to make the final working IF.

Unfortunately, the program must have been too demanding for Inform 6 to handle,
because it reported that one of its memory settings had been broken. These are
upper limits, usually on the number of things of a particular sort which can be
created, or on the amount of memory available for a given purpose.

To get around this, look at the actual output produced by Inform 6 to see which
memory setting was broken. For instance, suppose it said:

	The memory setting MAX_PROP_TABLE_SIZE (which is 30000 at present) has been exceeded.

You then need to amend your Inform 7 source text to take account of this, by
adding a sentence like the following:

	Use MAX_PROP_TABLE_SIZE of 50000.

With sentences like this, you can make Inform 6 raise its limits until there's
no longer any problem.
