[ImperativeDefinitions::] Imperative Definitions.

Each IMPERATIVE node in the syntax tree makes a definition using imperative code.

@h The head.
Inform has several features -- most obviously rules and "To ..." phrases --
where something is created with top-level syntax with a shape like so:
= (text as Inform 7)
Some preamble text ending in a colon:
	a body of instructions;
	like so;
=
These are called "imperative definitions", and each one in the source text
is given its own //imperative_defn//: see //ImperativeDefinitions::new// below.

The body has to be a standard chunk of Inform 7 code, which, roughly speaking,
is in the same format whatever is being defined here. This in due course becomes
its |body_of_defn|. But the preamble text can be very varied, and no syntactic
marker tells us directly what sort of language feature is being defined.

To deal with this, each such language feature has its own //imperative_defn_family//;
and every //imperative_defn// belongs to just one family. So, for example, a
definition makes a "To..." phrase if its family is the one looked after by
//To Phrase Family//.

=
typedef struct imperative_defn {
	struct imperative_defn_family *family; /* what manner of thing is defined */
	struct general_pointer family_specific_data;
	struct parse_node *at; /* where this occurs in the syntax tree */
	struct phrase *body_of_defn;
	struct wording log_text;
	CLASS_DEFINITION
} imperative_defn;

@ This creator function is called on each |IMPERATIVE_NT| node in the syntax
tree, which is to say, at each place where the punctuation looks like the
shape shown above.

At this point, |p| has a number of |INVOCATION_LIST_NT| nodes hanging from it,
and those have been checked through for any early signs of trouble (see //Imperative Subtrees//).
But nobody has looked at the preamble text at all, and our first task is to
find out which family the definition belongs to, on the basis of that text.

=
imperative_defn *ImperativeDefinitions::new(parse_node *p) {
	imperative_defn *id = CREATE(imperative_defn);
	id->at = p;
	id->body_of_defn = NULL;
	id->family = NULL;
	id->family_specific_data = NULL_GENERAL_POINTER;
	id->log_text = Node::get_text(p);
	current_sentence = p;
	ImperativeDefinitionFamilies::identify(id);
	return id;
}

@ In our compiled code, it's useful to label functions with Inter comments:

=
void ImperativeDefinitions::write_comment_describing(imperative_defn *id) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "%~W:", id->log_text);
	Produce::comment(Emit::tree(), C);
	DISCARD_TEXT(C)
}

@ And similarly:

=
void ImperativeDefinitions::index_preamble(OUTPUT_STREAM, imperative_defn *id) {
	WRITE("%+W", id->log_text);
}

@ IDs are happened early on in Inform's run, at a time when many nouns have
not been created, so no very detailed parsing of the preamble is possible.
This second stage, called "assessment", takes place later and makes a more
detailed look possible.

=
void ImperativeDefinitions::assess_all(void) {
	int initial_problem_count = problem_count;
	@<Step 1 - Assess@>;
	@<Step 2 - Register@>;
	@<Step 3 - Make the runtime context data@>;
	@<Step 4 - Complete@>;
}

@<Step 1 - Assess@> =
	int total = NUMBER_CREATED(imperative_defn), created = 0;
	imperative_defn *id;
	LOOP_OVER(id, imperative_defn) {
		created++;
		if ((created % 10) == 0)
			ProgressBar::update(3,
				((float) (created))/((float) (total)));
		current_sentence = id->at;			
		ImperativeDefinitionFamilies::assess(id);
		if ((Node::is(id->at->next, DEFN_CONT_NT) == FALSE) && (id->at->down == NULL) &&
			(ImperativeDefinitionFamilies::allows_empty(id) == FALSE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_Undefined),
				"there doesn't seem to be any definition here",
				"so I can't see what this rule or phrase would do.");
		} else {
			id->body_of_defn = ImperativeDefinitions::new_body(id);
			ImperativeDefinitions::detect_inline(id);
			ImperativeDefinitionFamilies::given_body(id);
			Phrases::prepare_stack_frame(id->body_of_defn);
		}
	}
	if (initial_problem_count < problem_count) return;

@<Step 2 - Register@> =
	imperative_defn_family *idf;
	LOOP_OVER(idf, imperative_defn_family) {
		ImperativeDefinitionFamilies::register(idf);
		if (initial_problem_count < problem_count) return;
	}

@<Step 3 - Make the runtime context data@> =
	imperative_defn *id;
	LOOP_OVER(id, imperative_defn)
		id->body_of_defn->runtime_context_data =
			ImperativeDefinitionFamilies::to_phrcd(id);
	if (initial_problem_count < problem_count) return;

@<Step 4 - Complete@> =
	imperative_defn_family *idf;
	LOOP_OVER(idf, imperative_defn_family) {
		ImperativeDefinitionFamilies::assessment_complete(idf);
		if (initial_problem_count < problem_count) return;
	}

@ Whatever is defined probably wants to compile the body of the definition
into at least one (and perhaps more than one) Inter function:

=
int total_phrases_to_compile = 0;
int total_phrases_compiled = 0;
void ImperativeDefinitions::compile_first_block(void) {
	@<Count up the scale of the task@>;
	imperative_defn_family *idf;
	LOOP_OVER(idf, imperative_defn_family)
		if (idf->compile_last == FALSE)
			ImperativeDefinitionFamilies::compile(idf,
				&total_phrases_compiled, total_phrases_to_compile);
	LOOP_OVER(idf, imperative_defn_family)
		if (idf->compile_last)
			ImperativeDefinitionFamilies::compile(idf,
				&total_phrases_compiled, total_phrases_to_compile);
}

@<Count up the scale of the task@> =
	total_phrases_compiled = 0;
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if (ph->compilation_data.at_least_one_compiled_form_needed)
			total_phrases_to_compile++;

@h The body.

=
typedef struct phrase {
	struct imperative_defn *from;
	struct ph_type_data type_data;
	struct ph_options_data options_data;
	struct ph_runtime_context_data runtime_context_data;
	struct ph_compilation_data compilation_data;
	CLASS_DEFINITION
} phrase;

@ The life of a |phrase| structure begins when we look at the parse-tree
representation of its declaration in the source text.

A phrase is inline if and only if its definition consists of a single
invocation which is given as verbatim I6.

=
phrase *ImperativeDefinitions::new_body(imperative_defn *id) {
	parse_node *p = id->at;
	if ((p == NULL) || (Node::get_type(p) != IMPERATIVE_NT))
		internal_error("a phrase preamble should be at a IMPERATIVE_NT node");
	LOGIF(PHRASE_CREATIONS, "Creating phrase: <%W>\n", id->log_text);
	phrase *body = CREATE(phrase);
	body->from = id;
	body->options_data = Phrases::Options::new(EMPTY_WORDING);
	body->runtime_context_data = Phrases::Context::new();
	body->type_data = Phrases::TypeData::new();
	body->compilation_data = Phrases::new_compilation_data(id->at);
	return body;
}

@ Inline definitions open with a raw Inform 6 inclusion. The lexer processes
those as two words: first |(-|, which serves as a marker, and then the raw
text of the inclusion treated as a single "word".

Some inline definitions also mark themselves to be included only in To phrases
of the right sort: it makes no sense to respond "yes" to a phrase "To decide
what number is...", for instance.

=
<inline-phrase-definition> ::=
	(- ### - in to only | 			 ==> { DECIDES_NOTHING_MOR, - }
	(- ### - in to decide if only |  ==> { DECIDES_CONDITION_MOR, - }
	(- ### - in to decide only |     ==> { DECIDES_VALUE_MOR, - }
	(- ### |                         ==> { DONT_KNOW_MOR, - }
	(- ### ...                       ==> @<Issue PM_TailAfterInline problem@>

@<Issue PM_TailAfterInline problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TailAfterInline),
		"some unexpected text appears after the tail of an inline definition",
		"placed within '(-' and '-)' markers to indicate that it is written in "
		"Inform 6. Here, there seems to be something extra after the '-)'.");
	==> { fail nonterminal };

@ =
void ImperativeDefinitions::detect_inline(imperative_defn *id) {
	parse_node *p = id->at;
	int inline_wn = -1, mor = DONT_KNOW_MOR;
	if ((p->down) && (p->down->down) && (p->down->down->next == NULL) &&
		(<inline-phrase-definition>(Node::get_text(p->down->down)))) {
		inline_wn = Wordings::first_wn(GET_RW(<inline-phrase-definition>, 1));
		mor = <<r>>;
	}
	if (inline_wn >= 0) {
		if (Wide::len(Lexer::word_text(inline_wn)) >= MAX_INLINE_DEFN_LENGTH)
			@<Forbid overly long inline definitions@>;
		if (ImperativeDefinitionFamilies::allows_inline(id) == FALSE)
			@<Inline is for To... phrases only@>;
		phrase *ph = id->body_of_defn;
		Phrases::TypeData::make_inline(&(ph->type_data));
		Phrases::make_inline(ph, inline_wn, mor);
	}
}

@<Forbid overly long inline definitions@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InlineTooLong),
		"the inline definition of this 'to...' phrase is too long",
		"using a quantity of Inform 6 code which exceeds the fairly small limit "
		"allowed. You will need either to write the phrase definition in Inform 7, "
		"or to call an I6 routine which you define elsewhere with an 'Include ...'.");

@<Inline is for To... phrases only@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InlineRule),
		"only 'to...' phrases can be given inline Inform 6 definitions",
		"and in particular rules and adjective definitions can't.");
