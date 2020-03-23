[Basics::] Basics.

Some fundamental definitions.

@h Build identity.
First we define the build, using a notation which tangles out to the current
build number as specified in the contents section of this web.

@d INTOOL_NAME "inpolicy"

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e known_problem_MT

@ And then expand:

=
ALLOCATE_INDIVIDUALLY(known_problem)
