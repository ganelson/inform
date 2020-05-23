How To Include This Module.

What to do to make use of the inflections module in a new command-line tool.

@h Status.
The inflections module is provided as one of the "services" suite of modules,
which means that it was built with a view to potential incorporation in
multiple tools. It can be found, for example, in //inform7// and
//inflections-test//.

By convention, the modules considered as "services" have no dependencies on
other modules except for //foundation// and other "services" modules.

A tool can import //inflections// only if it also imports //foundation//,
//words// and //syntax//.

@h Importing the module.
We'll use the term "parent" to mean the tool which is importing //inflections//,
that is, which will include its code and be able to use it. As with any
imported module,
(*) The contents page of the parent's web must identify and locate the
module:
= (text as Inweb)
Import: somepath/inflections
=
(*) The parent must call |InflectionsModule::start()| just after it starts up, and
|InflectionsModule::end()| just before it shuts down. (But just after, and just
before, the corresponding calls to //foundation//.)
