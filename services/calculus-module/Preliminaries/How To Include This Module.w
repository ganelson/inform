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

@h Using callbacks.
Shared modules like this one are tweaked in behaviour by defining "callback
functions". This means that the parent might provide a function of its own
which would answer a question put to it by the module, or take some action
on behalf of the module: it's a callback in the sense that the parent is
normally calling the module, but then the module calls the parent back to
ask for data or action.

The parent must indicate which function to use by defining a constant with
a specific name as being equal to that function's name. A fictional example
would be
= (text as Inweb)
	@d EXPRESS_SURPRISE_CALCULUS_CALLBACK Emotions::zowie
	
	=
	void Emotions::zowie(text_stream *OUT) {
	    WRITE("Zowie!\n");
	}
=
The calculus module has only a few callbacks and all are optional. The
following alphabetical list has references to fuller explanations:

(*) |BINARY_PREDICATE_CREATED_CALCULUS_CALLBACK|, if provided, is called whenever
a binary predicate is created. (The Inform compiler uses this opportunity to
register its textual name, if it has one.) See //BinaryPredicates::make_pair//.

(*) |DETECT_NOTHING_CALCULUS_CALLBACK|. The Inform run-time has a constant called
|nothing| which acts as a default value for objects, indicating an absence of
any object. The existence of this enables some propositions to be simplified.
If provided, the function should test whether the supplied constant is |nothing|.
See //Simplifications::nothing_constant// and //Binding::substitute_nothing_in_term//.

(*) |PROBLEM_CALCULUS_CALLBACK| is called when a proposition is mis-constructed,
and can prevent the resulting warning from being issued to the terminal as an
error message: see //TypecheckPropositions::problem//.

(*) |PRODUCE_NOTHING_VALUE_CALCULUS_CALLBACK| can provide the |nothing| constant;
see above, and see //Simplifications::not_related_to_something//.

@ In addition, the following value can optionally be defined:

(*) |VERB_MEANING_UNIVERSAL_CALCULUS_RELATION| should be the universal relation,
that is, the binary predicate which defines "relates". This requires specialist
type-checking: see //TypecheckPropositions::type_check_binary_predicate//.
