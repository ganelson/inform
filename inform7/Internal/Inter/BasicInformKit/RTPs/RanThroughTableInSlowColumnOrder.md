# Attempt to repeat through a table in a tricky column order

It's very convenient to use `repeat through T in C order`, where C is a column in the table T, but this isn't very efficient - it runs quite slowly, in fact, especially if the table has many rows. The problem isn't usually too bad, if the data stored in the column is simple (numbers, for instance), but it becomes chronic if there are texts, lists or other exotica there.

The secret is to sort the table first, which is much more efficient, and then repeat through it. For example, instead of `repeat through the Table of Responses in customised quip order`, first `sort the Table of Responses in customised quip order` and then just `repeat through the Table of Responses`.
