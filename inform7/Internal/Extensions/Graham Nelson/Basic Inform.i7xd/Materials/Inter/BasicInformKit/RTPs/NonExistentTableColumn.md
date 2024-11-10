# Attempt to look up a non-existent column in the table

Suppose there are two tables, the `Table of Fruits` and the `Table of Fowls`, and suppose that the former has a column called `seeds`. Inform will (mostly) translate a request to talk about the `seeds entry` in a row of the `Table of Fowls`, but such a request can't make sense: the other table has the `seeds` column but this one doesn't. This problem will be detected at run-time, and this is the message which then appears.
