[Basics::] Basics.

Some fundamental definitions.

@h Build identity.
First we define the build, using a notation which tangles out to the current
build number as specified in the contents section of this web.

@d INTOOL_NAME "inpolicy"

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e known_problem_MT
@e version_MT
@e project_MT
@e macro_MT
@e macro_tokens_MT

@ And then expand:

=
ALLOCATE_INDIVIDUALLY(known_problem)
ALLOCATE_INDIVIDUALLY(version)
ALLOCATE_INDIVIDUALLY(project)
ALLOCATE_INDIVIDUALLY(macro)
ALLOCATE_INDIVIDUALLY(macro_tokens)
