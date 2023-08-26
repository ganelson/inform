# The list-writer has run out of memory

The list-writer is the mechanism which prints lists of objects, for instance from the text substitution `[list of open doors]` or as part of a room description. It has enough memory to cope with lists holding every object there is, plus a little more besides, but if you try to print a list where every term for some reason lists substantial further lists as part of its own text, it's possible to overwhelm the list-writer. That seems to have happened here: sorry.
