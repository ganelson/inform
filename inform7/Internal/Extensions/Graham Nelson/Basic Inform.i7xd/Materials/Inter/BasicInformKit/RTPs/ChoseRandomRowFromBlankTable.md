# Attempt to choose a random row in an entirely blank table

Inform allows us to create tables with one or more blank rows to be filled in during the course of play. Blank rows effectively don't exist when it comes to reading information, so the choice of a random row always excludes them. As a result it will fail if every row in the table is blank, and that is what has happened here.

Typically this happens if you have, say, a table containing details of some randomised events which can happen in the course of play: when you want one to happen, you choose a random row and act on what's in it; to make sure the same event will never happen again, you blank that row out. If you have 10 different events, but call upon this process 11 times, then on the 11th time the table will be entirely blank and this problem will turn up. You can guard against this with a test such as `if the number of filled rows in the Table of Incidents is not 0, ...`
