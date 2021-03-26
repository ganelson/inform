[ImperativeDefinitions::] Imperative Definitions.

Each IMPERATIVE node in the syntax tree makes a definition of a phrase or rule.

@ When this function starts, the tree contains a number of top-level |IMPERATIVE_NT|
nodes with |INVOCATION_LIST_NT| nodes hanging from them, but we haven't looked at
any of the text in the |IMPERATIVE_NT| head nodes and therefore we have no idea what
they define. Some will be rules, some will define To... phrases, and so on.

=
typedef struct imperative_defn {
	struct imperative_defn_family *family;
	struct general_pointer family_specific_data;
	struct parse_node *at;
	struct phrase *defines;
	struct wording log_text;
	CLASS_DEFINITION
} imperative_defn;

typedef struct imperative_defn_family {
	struct text_stream *family_name;
	struct method_set *methods;
	CLASS_DEFINITION
} imperative_defn_family;

imperative_defn_family *AS_YET_UNKNOWN_EFF_family = NULL; /* used only temporarily */

imperative_defn_family *ImperativeDefinitions::new_family(text_stream *name) {
	imperative_defn_family *family = CREATE(imperative_defn_family);
	family->family_name = Str::duplicate(name);
	family->methods = Methods::new_set();
	return family;
}

@ |CLAIM_IMP_DEFN_MTID| is for deciding from the syntax of a preamble whether
this definition should belong to the family or not.

@e CLAIM_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(CLAIM_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

void ImperativeDefinitions::identify(imperative_defn *id) {
	imperative_defn_family *f;
	LOOP_OVER(f, imperative_defn_family)
		if (id->family == AS_YET_UNKNOWN_EFF_family)
			VOID_METHOD_CALL(f, CLAIM_IMP_DEFN_MTID, id);
}

@ |ASSESS_IMP_DEFN_MTID| is for parsing it in more detail, later on.

@e ASSESS_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(ASSESS_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

void ImperativeDefinitions::assess(imperative_defn *id) {
	VOID_METHOD_CALL(id->family, ASSESS_IMP_DEFN_MTID, id);
}

@ |NEW_PHRASE_IMP_DEFN_MTID| is for ...

@e NEW_PHRASE_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(NEW_PHRASE_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id, phrase *new_ph)

void ImperativeDefinitions::new_phrase(imperative_defn *id, phrase *new_ph) {
	VOID_METHOD_CALL(id->family, NEW_PHRASE_IMP_DEFN_MTID, id, new_ph);
}

@ |TO_RCD_IMP_DEFN_MTID| is for deciding from the syntax of a preamble whether
this definition should belong to the family or not.

@e TO_RCD_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(TO_RCD_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id, ph_runtime_context_data *rcd)

void ImperativeDefinitions::to_rcd(imperative_defn *id, ph_runtime_context_data *rcd) {
	VOID_METHOD_CALL(id->family, TO_RCD_IMP_DEFN_MTID, id, rcd);
}

@

=
int ImperativeDefinitions::goes_in_rulebooks(imperative_defn *id) {
	if (RuleFamily::is(id)) return TRUE;
	return FALSE;
}

@

=
void ImperativeDefinitions::create_families(void) {
	AS_YET_UNKNOWN_EFF_family       = ImperativeDefinitions::new_family(I"AS_YET_UNKNOWN_EFF");

	AdjectivalDefinitionFamily::create_family();

	ToPhraseFamily::create_family();

	RuleFamily::create_family();
}

@

=
imperative_defn *ImperativeDefinitions::make_imperative_definition(parse_node *p) {
	imperative_defn *id = CREATE(imperative_defn);
	id->at = p;
	id->defines = NULL;
	id->family = AS_YET_UNKNOWN_EFF_family;
	id->family_specific_data = NULL_GENERAL_POINTER;
	id->log_text = Node::get_text(p);
	current_sentence = p;
	ImperativeDefinitions::identify(id);
	return id;
}

@ =
void ImperativeDefinitions::find_phrases_and_rules(void) {
	int initial_problem_count = problem_count;

	int total = NUMBER_CREATED(imperative_defn), created = 0;
	imperative_defn *id;
	LOOP_OVER(id, imperative_defn) {
		created++;
		if ((created % 10) == 0)
			ProgressBar::update(3,
				((float) (created))/((float) (total)));
		current_sentence = id->at;			
		ImperativeDefinitions::assess(id);
		Phrases::create_from_preamble(id);
	}
	if (initial_problem_count < problem_count) return;

	Routines::ToPhrases::register_all();
	if (initial_problem_count < problem_count) return;

	phrase *ph;
	LOOP_OVER(ph, phrase) {
		current_sentence = ph->from->at;
		Frames::make_current(&(ph->stack_frame));
		ph->runtime_context_data =
			ImperativeDefinitions::to_runtime_context_data(ph->from);
		Frames::remove_current();
	}
	if (initial_problem_count < problem_count) return;

	RuleBookings::make_automatic_placements();
	if (initial_problem_count < problem_count) return;

	SyntaxTree::traverse(Task::syntax_tree(), ImperativeDefinitions::visit_to_parse_placements);
}

@

@e TRAVERSE_FOR_RULE_FILING_SMFT

=
void ImperativeDefinitions::visit_to_parse_placements(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) &&
		(p->down) &&
		(Node::get_type(p->down) == VERB_NT)) {
		prevailing_mood = Annotations::read_int(p->down, verbal_certainty_ANNOT);
		MajorNodes::try_special_meaning(TRAVERSE_FOR_RULE_FILING_SMFT, p->down);
	}
}

@ The rulebooks are now complete and final. It is time to
compile the Inter code which will provide the run-time definitions of all
these phrases. This will be a long task, and we can only do most of it now,
because more phrases will appear later.

=
int total_phrases_to_compile = 0;
int total_phrases_compiled = 0;
void ImperativeDefinitions::compile_first_block(void) {
	@<Count up the scale of the task@>;
	@<Compile definitions of rules in rulebooks@>;
	@<Compile definitions of rules left out of rulebooks@>;
	@<Compile phrases which define adjectives@>;
	@<Mark To... phrases which have definite kinds for future compilation@>;
	@<Throw problems for phrases with return kinds too vaguely defined@>;
	@<Throw problems for inline phrases named as constants@>;
}

@<Count up the scale of the task@> =
	total_phrases_compiled = 0;
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if (ph->at_least_one_compiled_form_needed)
			total_phrases_to_compile++;

@<Compile definitions of rules in rulebooks@> =
	rulebook *rb;
	LOOP_OVER(rb, rulebook)
		RTRules::compile_rule_phrases(rb,
			&total_phrases_compiled, total_phrases_to_compile);

@<Compile definitions of rules left out of rulebooks@> =
	rule *R;
	LOOP_OVER(R, rule)
		RTRules::compile_definition(R,
			&total_phrases_compiled, total_phrases_to_compile);

@ This doesn't compile all adjective definitions, only the ones which supply
a whole multi-step phrase to define them -- a relatively little-used feature
of Inform.

@<Compile phrases which define adjectives@> =
	imperative_defn *id;
	LOOP_OVER(id, imperative_defn)
		if (id->family == DEFINITIONAL_PHRASE_EFF_family)
			Phrases::compile(id->defines, &total_phrases_compiled,
				total_phrases_to_compile, NULL, NULL, NULL);
	RTAdjectives::compile_support_code();

@ As we'll see, it's legal in Inform to define "To..." phrases with vague
kinds: "To expose (X - a value)", for example. This can't be compiled as
vaguely as the definition implies, since there would be no way to know how
to store X. Instead, for each different kind of X which is actually needed,
a fresh version of the phrase is compiled -- one where X is a number, one
where it's a text, and so on. This is handled by making a "request" for the
phrase, indicating that a compiled version of it will be needed.

Since "To..." phrases are only compiled on request, we must remember to
request the boring ones with straightforward kinds ("To award (N - a number)
points", say). This is where we do it:

@<Mark To... phrases which have definite kinds for future compilation@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		kind *K = Phrases::TypeData::kind(&(ph->type_data));
		if (Kinds::Behaviour::definite(K)) {
			if (ph->at_least_one_compiled_form_needed)
				Routines::ToPhrases::make_request(ph, K, NULL, EMPTY_WORDING);
		}
	}

@<Throw problems for phrases with return kinds too vaguely defined@> =
	phrase *ph;
	LOOP_OVER(ph, phrase) {
		kind *KR = Phrases::TypeData::get_return_kind(&(ph->type_data));
		if ((Kinds::Behaviour::semidefinite(KR) == FALSE) &&
			(Phrases::TypeData::arithmetic_operation(ph) == -1)) {
			current_sentence = Phrases::declaration_node(ph);
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReturnKindVague));
			Problems::issue_problem_segment(
				"The declaration %1 tries to set up a phrase which decides a "
				"value which is too vaguely described. For example, 'To decide "
				"which number is the target: ...' is fine, because 'number' "
				"is clear about what kind of value should emerge; but 'To "
				"decide which value is the target: ...' is not clear enough.");
			Problems::issue_problem_end();
		}
		for (int k=1; k<=26; k++)
			if ((Kinds::Behaviour::involves_var(KR, k)) &&
				(Phrases::TypeData::tokens_contain_variable(&(ph->type_data), k) == FALSE)) {
				current_sentence = Phrases::declaration_node(ph);
				TEMPORARY_TEXT(var_letter)
				PUT_TO(var_letter, 'A'+k-1);
				Problems::quote_source(1, current_sentence);
				Problems::quote_stream(2, var_letter);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReturnKindUndetermined));
				Problems::issue_problem_segment(
					"The declaration %1 tries to set up a phrase which decides a "
					"value which is too vaguely described, because it involves "
					"a kind variable (%2) which it can't determine through "
					"usage.");
				Problems::issue_problem_end();
				DISCARD_TEXT(var_letter)
		}
	}

@<Throw problems for inline phrases named as constants@> =
	phrase *ph;
	LOOP_OVER(ph, phrase)
		if ((Phrases::TypeData::invoked_inline(ph)) &&
			(ToPhraseFamily::has_name_as_constant(ph->from))) {
			current_sentence = Phrases::declaration_node(ph);
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NamedInline));
			Problems::issue_problem_segment(
				"The declaration %1 tries to give a name to a phrase which is "
				"defined using inline Inform 6 code in (- markers -). Such "
				"phrases can't be named and used as constants because they "
				"have no independent existence, being instead made fresh "
				"each time they are used.");
			Problems::issue_problem_end();
		}

@ The twilight gathers, but our work is far from done. Recall that we have
accumulated compilation requests for "To..." phrases, but haven't actually
acted on them yet.

We have to do this in quite an open-ended way, because compiling one phrase
can easily generate fresh requests for others. For instance, suppose we have
the definition "To expose (X - a value)" in play, and suppose that when
compiling the phrase "To advertise", Inform runs into the line "expose the
hoarding text". This causes it to issue a compilation request for "To expose
(X - a text)". Perhaps we've compiled such a form already, but perhaps we
haven't. Compilation therefore goes on until all requests have been dealt
with.

Compiling phrases also produces the need for other pieces of code to be
generated -- for example, suppose our phrase being compiled, "To advertise",
includes the text:

>> let Z be "Two for the price of one! Just [expose price]!";

We are going to need to compile "Two for the price of one! Just [expose price]!"
later on, in its own text substitution routine; but notice that it contains
the need for "To expose (X - a number)", and that will generate a further
phrase request.

Because of this and similar problems, it's impossible to compile all the
phrases alone: we must compile phrases, then things arising from them, then
phrases arising from those, then things arising from the phrases arising
from those, and so on, until we're done. The process is therefore structured
as a set of "coroutines" which each carry out as much as they can and then
hand over to the others to generate more work.

=
void ImperativeDefinitions::compile_as_needed(void) {
	rule *R;
	LOOP_OVER(R, rule)
		RTRules::compile_definition(R,
			&total_phrases_compiled, total_phrases_to_compile);
	int repeat = TRUE;
	while (repeat) {
		repeat = FALSE;
		if (Routines::ToPhrases::compilation_coroutine(
			&total_phrases_compiled, total_phrases_to_compile) > 0)
			repeat = TRUE;
		if (ListTogether::compilation_coroutine() > 0)
			repeat = TRUE;
		#ifdef IF_MODULE
		if (LoopingOverScope::compilation_coroutine() > 0)
			repeat = TRUE;
		#endif
		if (Strings::TextSubstitutions::compilation_coroutine(FALSE) > 0)
			repeat = TRUE;
		if (Propositions::Deferred::compilation_coroutine() > 0)
			repeat = TRUE;
	}
}

@ In our compiled code, it's useful to label routines with I6 comments:

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

@h How the PHUD translates into a PHRCD.
Recall that in the early afternoon, the PHUD for a rule phrase is translated
into a PHRCD, that is, a set of instructions about the circumstances for
the rule to fire.

As will be seen, about six-sevenths of the code is given over to choosing good
problem messages when the PHUD is malformed -- these are some of the most
seen problems in Inform. A couple of variables are needed just for that:

=

@ =
ph_runtime_context_data ImperativeDefinitions::to_runtime_context_data(imperative_defn *id) {
	ph_runtime_context_data phrcd = Phrases::Context::new();
	ImperativeDefinitions::to_rcd(id, &phrcd);
	return phrcd;
}
