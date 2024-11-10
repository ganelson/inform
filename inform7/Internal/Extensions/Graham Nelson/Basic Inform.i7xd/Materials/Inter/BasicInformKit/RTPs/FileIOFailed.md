# Error handling external file

Interactive fiction is generally handled by a virtual machine, a special computer provided in software which operates in its own closed little world. The Z-machine family of virtual machines does not provide access to external files at all; the Glulx VM does, but of course many things can go wrong. Perhaps a given file cannot be found, or perhaps the VM attempts to write to a file held open by another application, or perhaps the host computer runs out of disc space.
