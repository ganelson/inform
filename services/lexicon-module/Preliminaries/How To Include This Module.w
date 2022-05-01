How To Include This Module.

What to do to make use of the lexicon module in a new command-line tool.

@h Status.
The lexicon module is provided as one of the "services" suite of modules,
which means that it was built with a view to potential incorporation in
multiple tools. It can be found, for example, in //inform7// and
//linguistics-test//.

By convention, the modules considered as "services" have no dependencies on
other modules except for //foundation// and other "services" modules.

A tool can import //lexicon// only if it also imports //foundation//,
//words//, //syntax// and //inflections//.

@h Importing the module.
We'll use the term "parent" to mean the tool which is importing //lexicon//,
that is, which will include its code and be able to use it. As with any
imported module,
(*) The contents page of the parent's web must identify and locate the
module:
= (text as Inweb)
Import: somepath/lexicon
=
(*) The parent must call |LexiconModule::start()| just after it starts up, and
|LexiconModule::end()| just before it shuts down. (But just after, and just
before, the corresponding calls to //foundation//.)

@h Defining parsing methods.
When lexicon entries are registered (see //lexicon: Lexicon//), they are
assigned "meaning codes", and these affect the way that parsing is done.
The user should define |EXACT_PARSING_BITMAP|, |SUBSET_PARSING_BITMAP|
and |PARAMETRISED_PARSING_BITMAP| to be sums of the meaning codes for
which these methods are used -- see //Parse Excerpts//.

For example, the parent could define |INGREDIENTS_MC| and |RECIPES_MC| to
have two different namespaces, and then define |EXACT_PARSING_BITMAP| to
be |INGREDIENTS_MC + RECIPES_MC| to make both of them parsed exactly.

Minimal default settings are made if the parent doesn't create these
constants.

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
	@d EXPRESS_SURPRISE_LEXICON_CALLBACK Emotions::gosh
	
	=
	void Emotions::gosh(text_stream *OUT) {
	    WRITE("Zowie!\n");
	}
=
The lexicon module has many callbacks, but they are all optional. The
following alphabetical list has references to fuller explanations:

(*) |EM_CASE_SENSITIVITY_TEST_LEXICON_CALLBACK|, |EM_ALLOW_BLANK_TEST_LEXICON_CALLBACK|
and |EM_IGNORE_DEFINITE_ARTICLE_TEST_LEXICON_CALLBACK| can all make excerpts
parse in slightly different ways. //core// sets all of these to return |TRUE|
for say phrases, and |FALSE| for everything else. See //Lexicon::retrieve//
and //Lexicon::register//.

(*) |PARSE_EXACTLY_LEXICON_CALLBACK| is called when an excerpt is about to be
parsed in "subset mode" -- allowing just a subset of its words to be used,
i.e., not requiring exact wording. This function can refuse to allow that in
certain cases. See //Lexicon::retrieve//.

(*) |PROBLEM_LEXICON_CALLBACK| is called when an error is found, and can
prevent this from being issued to the terminal as an error message: see
//ExcerptMeanings::problem_handler//.
