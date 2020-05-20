How To Include This Module.

What to do to make use of the problems module in a new command-line tool.

@h Status.
The problems module provided as one of the "services" suite of modules, which means
that it was built with a view to potential incorporation in multiple tools.
It can be found, for example, in //inform7// and //problems-test//.

By convention, the modules considered as "services" have no dependencies on
other modules except for //foundation// and other "services" modules.

A tool can import //problems// only if it also imports //foundation//,
//words// and //syntax//.

@h Importing the module.
We'll use the term "parent" to mean the tool which is importing //problems//,
that is, which will include its code and be able to use it. As with any
imported module,
(*) The contents page of the parent's web must identify and locate the
module:
= (text as Inweb)
Import: somepath/problems
=
(*) The parent must call |ProblemsModule::start()| just after it starts up, and
|ProblemsModule::end()| just before it shuts down. (But just after, and just
before, the corresponding calls to //foundation//.)

@h Using callbacks.
Shared modules like this one are tweaked in behaviour by defining "callback
functions". This means that the parent might provide a function of its own
which would answer a question put to it by the module, or take some action
on behalf of the module: it's a callback in the sense that the parent is
normally calling the module, but then the module calls the parent back to
ask for data or action.

The problems module has only a few callbacks, and they are all optional. The
following alphabetical list has references to fuller explanations:

@ |DESCRIBE_SOURCE_FILE_PROBLEMS_CALLBACK| can change the description of a
file used in problem messages; Inform uses this to say "the source text" or
"Standard Rules" rather than citing filenames. See //ProblemBuffer::copy_source_reference//.

@ |DOCUMENTATION_REFERENCE_PROBLEMS_CALLBACK| is invited to add a clickable
link to in-app documentation; if no callback function is provided, no
such links appear. See //Problems::problem_documentation_links//.

@ |ENDING_MESSAGE_PROBLEMS_CALLBACK| is called just before a problem message
is about to end, and can be used to append some extra wording. See
//Problems::issue_problem_end//.

@ |FIRST_PROBLEMS_CALLBACK| is called before the first problem in a run is
issued, and takes as an argument the |text_stream *| to which problems are
being written. See //Problems::show_problem_location//.

@ |GLOSS_EXTENSION_SOURCE_FILE_PROBLEMS_CALLBACK| is called to add a note
like "in the extension Locksmith by Emily Short"; see //Problems::show_problem_location//.

@ |INFORMATIONAL_ADDENDA_PROBLEMS_CALLBACK| is called just before a problems
report closes, to give it a chance to add informational messages. (//core//
uses this mechanism to append text such as "There were 3 rooms and 27 things.")
Such addenda are not problems, and do not affect the program's exit code.
See //ProblemBuffer::write_reports//.

@ |START_PROBLEM_FILE_PROBLEMS_CALLBACK| is called when //problems// wants
to open some kind of file for problem messages, with two arguments: the
filename |F| and the stream |P| to open to it. If the callback function wants
this to come to anything, it must perform the file-open, and write any header
material it would like. See //StandardProblems::start_problems_report//.

@ |WORDING_FOR_HEADING_NODE_PROBLEMS_CALLBACK| is called to ask what wording
should be used to describe a heading in problem messages. See
//Problems::show_problem_location//.
