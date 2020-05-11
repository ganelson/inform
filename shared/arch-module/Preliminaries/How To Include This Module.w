How To Include This Module.

What to do to make use of the arch module in a new command-line tool.

@h Status.
The arch module provided as one of the "shared" Inform modules, which means
that it was built with a view to potential incorporation in multiple tools.
It can be found, for example, in //inform7//, //inbuild// and //arch-test//.

By convention, the modules considered as "shared" have no dependencies on
other modules except for //foundation// and other "shared" modules.

A tool can import //arch// only if it also imports //foundation//.

@h Importing the module.
We'll use the term "parent" to mean the tool which is importing //arch//,
that is, which will include its code and be able to use it. As with any
imported module,
(*) The contents page of the parent's web must identify and locate the
module:
= (text as Inweb)
Import: somepath/arch
=
(*) The parent must call |ArchModule::start()| just after it starts up, and
|ArchModule::end()| just before it shuts down. (But just after, and just
before, the corresponding calls to //foundation//.)
