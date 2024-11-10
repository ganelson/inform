# Attempt to look up a non-existent entry in table

Inform allows us to create tables with blank entries, having no value at all: sometimes these are written `--`, but sometimes they are literally left blank in the original source text. We are not allowed to read such an entry, and this is the problem which turns up if we do. (Whereas we *are* allowed to write to it, making it no longer blank if we do.)
