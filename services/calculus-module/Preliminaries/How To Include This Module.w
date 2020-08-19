How To Include This Module.

What to do to make use of the calculus module in a new command-line tool.

@h Status.
The calculus module provided as one of the "services" suite of modules, which means
that it was built with a view to potential incorporation in multiple tools.

By convention, the modules considered as "services" have no dependencies on
other modules except for //foundation// and other "services" modules.

@h Importing the module.
We'll use the term "parent" to mean the tool which is importing //calculus//,
that is, which will include its code and be able to use it. As with any
imported module,
(*) The contents page of the parent's web must identify and locate the
module:
= (text as Inweb)
Import: somepath/calculus
=
(*) The parent must call |CalculusModule::start()| just after it starts up, and
|CalculusModule::end()| just before it shuts down. (But just after, and just
before, the corresponding calls to //foundation//.)
