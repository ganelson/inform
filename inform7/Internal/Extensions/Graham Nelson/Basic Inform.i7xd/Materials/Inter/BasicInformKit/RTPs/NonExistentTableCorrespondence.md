# Attempt to look up a non-existent correspondence in table

This problem is probably the one most often seen when dealing with tables, and is usually a symptom that one has forgotten to worry about an unlikely case. It happens when, for instance, we look up `the fruit corresponding to a seed count of 10 in the Table of Fruits` but the value 10 never occurs in any row of that table, so that there is no such fruit. If we don't know for certain that this won't happen, we can always check by testing `if there is a fruit corresponding to a seed count of 10 in the Table of Fruits`.
