How To Include This Module.

What to do to make use of the linguistics module in a new command-line tool.

@h Status.
The linguistics module is provided as one of the "services" suite of modules,
which means that it was built with a view to potential incorporation in
multiple tools. It can be found, for example, in //inform7// and
//linguistics-test//.

By convention, the modules considered as "services" have no dependencies on
other modules except for //foundation// and other "services" modules.

A tool can import //linguistics// only if it also imports //foundation//,
//words//, //syntax//, //inflections// and //lexicon//.

@h Importing the module.
We'll use the term "parent" to mean the tool which is importing //linguistics//,
that is, which will include its code and be able to use it. As with any
imported module,
(*) The contents page of the parent's web must identify and locate the
module:
= (text as Inweb)
Import: somepath/linguistics
=
(*) The parent must call |InflectionsModule::start()| just after it starts up, and
|InflectionsModule::end()| just before it shuts down. (But just after, and just
before, the corresponding calls to //foundation//.)

@h Meaning types.
This module tries to be agnostic about the actual meanings of words: it knows
about verbs, but not about what any specific verb means. The idea is that the
parent tool specifies that, with some type of its own. The constant
|VERB_MEANING_LINGUISTICS_TYPE| should be defined to what this actually is;
it should be the name of a class of objects. (If it isn't defined, then no
meaning is attached to verbs at all.)

For example, the //core// module sets:
= (text as Inweb)
	@d VERB_MEANING_LINGUISTICS_TYPE struct binary_predicate
=
The parent may also want to define |VERB_MEANING_UNIVERSAL|, which should be
a value of this type, and represents the "to relate" verb which can assert
any verb meaning -- for example, "X relates to Y by R". See //Verb Usages//.

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
	@d EXPRESS_SURPRISE_LINGUISTICS_CALLBACK Emotions::gosh
	
	=
	void Emotions::gosh(text_stream *OUT) {
	    WRITE("Good gracious!\n");
	}
=
The linguistics module has many callbacks, but they are all optional. The
following alphabetical list has references to fuller explanations:

(*) |ADAPTIVE_PERSON_LINGUISTICS_CALLBACK| returns the default person for adaptive
text generation; in Inform, this tends to be the value of the adaptive text viewpoint
property for the natural language of play. Similarly, |ADAPTIVE_NUMBER_LINGUISTICS_CALLBACK|
returns the number (singular or plural). See //VerbUsages::adaptive_person//.

(*) |ADJECTIVE_NAME_VETTING_LINGUISTICS_CALLBACK| should return |TRUE| if the given
name is acceptable as an adjective, and should otherwise print some sort of
error message and return |FALSE|. If this callback is not provided, all non-empty
names are acceptable. See //Adjectives::declare//.

(*) |ALLOW_VERB_IN_ASSERTIONS_LINGUISTICS_CALLBACK| and |ALLOW_VERB_LINGUISTICS_CALLBACK|
give the parent control over which forms of verbs are allowed: for examole, //core//
allows them in assertions only in the third person (singular or plural), whereas
it allows them in any form in non-assertion contexts. See
//VerbUsages::register_moods_of_verb//.

(*) |ADJECTIVE_COMPILATION_LINGUISTICS_CALLBACK|, if provided, should accompany a
declaration of a structure called |adjecttve_compilation_data|; this function should
then set up that data for the given adjective -- see //Adjectives::declare//.

(*) |ADJECTIVE_MEANING_LINGUISTICS_CALLBACK|, if provided, should accompany a
declaration of a structure called |adjective_meaning_data|; this function should
then set up that data for the given adjective -- see //Adjectives::declare//.

(*) |NOUN_COMPILATION_LINGUISTICS_CALLBACK|, if provided, should accompany a
declaration of a structure called |name_compilation_data|; this function should
then set up that data for the given noun -- see //Nouns::new_inner//.

(*) |NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK|, if provided, should accompany a
declaration of a structure called |name_resolution_data|; this function should
decide which possible reading of the meaning of a noun makes the best sense in
context -- see //Nouns::disambiguate//.

(*) |TRACING_LINGUISTICS_CALLBACK|, if provided, can return |TRUE| to allow
extensive details of verb parsing to be copied to the debugging log. See
//VerbPhrases::tracing//.

(*) |VERB_MEANING_REVERSAL_LINGUISTICS_CALLBACK| reverses the meaning of a verb:
in the sense that the reversal of "A knows B" would be "A is known by B",
or in other words "B knows A". See //VerbMeanings::reverse_VMT//.
 