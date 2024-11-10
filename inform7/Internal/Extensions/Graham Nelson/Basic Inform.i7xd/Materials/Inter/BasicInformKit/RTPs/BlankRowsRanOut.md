# Attempt to choose a blank row in a table with none left

Inform allows us to create tables with one or more blank rows to be filled in during the course of play. In any given table the number of blank rows can go down (if we write to an entry on a blank row, it is no longer blank) or up (if we blank out an existing non-blank row), but it will certainly be limited. So if we go on trying to choose blank rows and filling them in, we will eventually run out. This is the run-time problem which announces that.

In particular, of course, you would see this message if you tried to choose a blank row in a table which never had any blank rows to start with.
