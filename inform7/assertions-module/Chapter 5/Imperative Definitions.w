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
	struct id_body *body_of_defn;
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
	LOGIF(PHRASE_CREATIONS, "Creating imperative definition: <%W>\n", id->log_text);
	current_sentence = p;
	ImperativeDefinitionFamilies::identify(id);
	return id;
}

@ In our compiled code, it's useful to label functions with Inter comments:

=
void ImperativeDefinitions::write_comment_describing(imperative_defn *id) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "%~W:", id->log_text);
	EmitCode::comment(C);
	DISCARD_TEXT(C)
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
			CompileImperativeDefn::initialise_stack_frame(id->body_of_defn);
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
	id_body *idb;
	LOOP_OVER(idb, id_body)
		if (idb->compilation_data.at_least_one_compiled_form_needed)
			total_phrases_to_compile++;

@h The body.
During assessment, then, each //imperative_defn// is given a body, which
is one of these. It represents the body of the definition -- that is, the
Inform 7 source text written underneath the heading.

=
typedef struct id_body {
	struct imperative_defn *head_of_defn;
	struct id_type_data type_data;
	struct id_runtime_context_data runtime_context_data;
	struct id_compilation_data compilation_data;
	CLASS_DEFINITION
} id_body;

id_body *ImperativeDefinitions::new_body(imperative_defn *id) {
	LOGIF(PHRASE_CREATIONS, "Creating body: <%W>\n", id->log_text);
	id_body *body = CREATE(id_body);
	body->head_of_defn = id;
	body->runtime_context_data = RuntimeContextData::new();
	body->type_data = IDTypeData::new();
	body->compilation_data = CompileImperativeDefn::new_data(id->at);
	return body;
}

@ Definition bodies can be written in two different ways. In one way, the
body is a list of instructions to follow. For example:
= (text as Inform 7)
To decide which real number is the hyperbolic arccosine of (R - a real number):
	let x be given by x = log(R + root(R^2 - 1)) where x is a real number;
	decide on x.
=
Here there are two instructions. Each is an "invocation" of a "To..." phrase;
and the whole definition will ultimately be compiled to an Inter function.[1]
Invoking this phrase with source text like "hyperbolic arccosine of pi" then
compiles to a call to that function.

In the other way, the body has just one entry, written in |(-| and |-)|
markers, showing directly what Inter code the definition would create if
it were invoked. For example:
= (text as Inform 7)
To decide which real number is the hyperbolic sine of (R - a real number):
	(- REAL_NUMBER_TY_Sinh({R}) -).
=
Here the definition itself compiles nothing: there is no Inter function at
run-time to perform "hyperbolic sine". Instead, an invocation such as
"hyperbolic sine of pi" results in Inter code being compiled which follows
the pattern in the |(-| and |-)| markers. See //imperative// for how this is done.

The second sort of definition is called "inline", because an invocation of it
results in code being compiled inline -- i.e., within the current function,
rather than calling out to an another function. Inline definitions can do
things which regular definitions can't. For example:
= (text as Inform 7)
To decide yes
	(- rtrue; -) - in to decide if only.
=
Invoking this compiles to a single instruction, returning |true| from the
current Inter function. But it would make no sense to do that if the function
were required to return, say, an object. So this particular inline definition
is marked "in to decide if only", meaning that it can only be used in the
bodies of "To decide if..." phrases. This is the |DECIDES_CONDITION_MOR|
("manner of return").

[1] Or perhaps to more than one, if the kinds are given indefinitely, so
that the definition is a prototype rather than a specific function.

@ The following Preform detects an inline body. Note that the lexer takes
text like |(- rtrue; -)| and converts it into just two words, the marker
|(-| and then the inline matter all as a single word: here, |rtrue; |.

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
		id_body *idb = id->body_of_defn;
		IDTypeData::make_inline(&(idb->type_data));
		CompileImperativeDefn::make_inline(idb, inline_wn, mor);
	}
}

@<Inline is for To... phrases only@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InlineRule),
		"only 'to...' phrases can be given inline Inform 6 definitions",
		"and in particular rules and adjective definitions can't.");

@ It is not clear that this restriction is needed any longer -- the compiler
works fine if it is removed -- but it keeps us on the side of sanity. Long
inline definitions would be very inefficient -- those should use code in an
Inter kit instead.

@d MAX_INLINE_DEFN_LENGTH 1024

@<Forbid overly long inline definitions@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InlineTooLong),
		"the inline definition of this 'to...' phrase is too long",
		"using a quantity of Inform 6 code which exceeds the fairly small limit allowed. You "
		"will need either to write the phrase definition in Inform 7, or to call an I6 routine "
		"which you define elsewhere with an 'Include ...'.");

@ That completes the process of creation. Here's how we log them:

=
void ImperativeDefinitions::log_body(id_body *idb) {
	if (idb == NULL) { LOG("RULE:NULL"); return; }
	LOG("%n", CompileImperativeDefn::iname(idb));
}

void ImperativeDefinitions::log_body_fuller(id_body *idb) {
	IDTypeData::log_briefly(&(idb->type_data));
}

void ImperativeDefinitions::write_HTML_representation(OUTPUT_STREAM, id_body *idb, int format) {
	IDTypeData::write_HTML_representation(OUT, &(idb->type_data), format, NULL);
}

parse_node *ImperativeDefinitions::header_at(imperative_defn *id) {
	if (id == NULL) return NULL;
	return id->at;
}

parse_node *ImperativeDefinitions::body_at(id_body *idb) {
	return idb->head_of_defn->at;
}
