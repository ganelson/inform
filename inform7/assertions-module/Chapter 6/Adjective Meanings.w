[AdjectiveMeanings::] Adjective Meanings.

One individual meaning which an adjective can have.

@h Meanings.
For example, "odd" in the sense of numbers is a single meaning. Each meaning
is an instance of:

=
typedef struct adjective_meaning {
	struct adjective *owning_adjective; /* of which this is a meaning */

	struct adjective_domain_data domain; /* to what can this meaning be applied? */

	struct adjective_meaning_family *family;
	general_pointer family_specific_data; /* to the relevant structure */
	struct adjective_meaning *negated_from; /* if explicitly constructed as such */

	struct wording indexing_text; /* text to use in the Phrasebook index */
	struct parse_node *defined_at; /* from what sentence this came (if it did) */

	int schemas_prepared; /* optional flag to mark whether schemas prepared yet */
	struct adjective_task_data task_data[NO_ADJECTIVE_TASKS + 1];

	int support_function_compiled; /* temporary workspace used when compiling support routines */

	CLASS_DEFINITION
} adjective_meaning;

@ This can be created in two ways: straightforwardly --

=
adjective_meaning *AdjectiveMeanings::new(adjective_meaning_family *family,
	general_pointer details, wording W) {
	adjective_meaning *am = CREATE(adjective_meaning);
	am->defined_at = current_sentence;
	am->indexing_text = W;
	am->owning_adjective = NULL;
	am->domain = AdjectiveMeaningDomains::new_from_text(EMPTY_WORDING);
	am->family = family;
	am->family_specific_data = details;
	am->support_function_compiled = FALSE;
	am->schemas_prepared = FALSE;
	for (int i=1; i<=NO_ADJECTIVE_TASKS; i++) {
		am->task_data[i].task_via_support_routine = NOT_APPLICABLE;
		Calculus::Schemas::modify(&(am->task_data[i].i6s_for_runtime_task), "");
		Calculus::Schemas::modify(&(am->task_data[i].i6s_to_transfer_to_SR), "");
	}
	am->negated_from = NULL;
	return am;
}

@ Or as the logical negation of an existing meaning (thus, "odd" for numbers
might be created as the negation of "even" for numbers):

=
adjective_meaning *AdjectiveMeanings::negate(adjective_meaning *am) {
	if (am->negated_from) internal_error("cannot negate an already negated AM");
	adjective_meaning *neg = CREATE(adjective_meaning);
	neg->defined_at = current_sentence;
	neg->indexing_text = am->indexing_text;
	neg->owning_adjective = NULL;
	neg->domain = am->domain;
	neg->family = am->family;
	neg->family_specific_data = am->family_specific_data;
	neg->support_function_compiled = FALSE;
	neg->schemas_prepared = FALSE;
	for (int i=1; i<=NO_ADJECTIVE_TASKS; i++) {
		int j = i;
		if (i == NOW_ADJECTIVE_TRUE_TASK) j = NOW_ADJECTIVE_FALSE_TASK;
		if (i == NOW_ADJECTIVE_FALSE_TASK) j = NOW_ADJECTIVE_TRUE_TASK;
		neg->task_data[j].task_via_support_routine = am->task_data[i].task_via_support_routine;
		neg->task_data[j].i6s_for_runtime_task = am->task_data[i].i6s_for_runtime_task;
		Calculus::Schemas::modify(&(neg->task_data[j].i6s_to_transfer_to_SR), "");
	}
	neg->negated_from = am;
	return neg;
}

@ There are currently seven families of adjective meanings, each represented
by an instance of the following:

=
typedef struct adjective_meaning_family {
	struct method_set *methods;
	int parsing_priority;
	CLASS_DEFINITION
} adjective_meaning_family;

adjective_meaning_family *AdjectiveMeanings::new_family(int N) {
	adjective_meaning_family *f = CREATE(adjective_meaning_family);
	f->parsing_priority = N;
	f->methods = Methods::new_set();
	return f;
}

@h Tasks and their schemas.

=
typedef struct adjective_task_data {
	int task_via_support_routine;
	struct i6_schema i6s_to_transfer_to_SR; /* where |TRUE| */
	struct i6_schema i6s_for_runtime_task; /* where |TRUE| */
} adjective_task_data;

@ What are adjectives for? Since an adjective is a unary predicate, it can be
thought of as an assignment from its domain set to the set of two possibilities:
true, false. Thus one sense of "open" maps doors to true if they are currently
open, false if they are closed.

There are altogether five things we might want to do with an adjective:

(1) Test whether it is true at any given point during play.
(2) Assert that it is true at the start of play.
(3) Assert that it is false at the start of play.
(4) Assert that it is now to be true from this point on during play.
(5) Assert that it is now to be false from this point on during play.

We do not need to test whether it is false, since we need only test whether
it is true and negate the result.

Adjectives for which all five of these operations can be carried out are
the exception rather than the rule. "Open" is an example:

>> [1] if the marble door is open, ...
>> [2] The marble door is open.
>> [3] The marble door is not open.
>> [4] now the marble door is open;
>> [5] now the marble door is not open;

Every adjective in practice supports (1), testing for truth, but this is
not required by the code below. Many adjectives -- properly speaking, many
senses of an adjective -- only support testing: "empty" in the sense of
texts, for instance.

Of the five possibilities, (1), (4) and (5) happen at run-time. These are
called "tasks" and are identified by the following constants. While in
theory an adjective's handling code can compile anything it likes to carry
out these tasks, in practice most are defined by providing an I6 schema,
which is why the |adjective_meaning| structure contains these -- see below.

@d NO_ADJECTIVE_TASKS 3

@d TEST_ADJECTIVE_TASK 1 /* test if currently true */
@d NOW_ADJECTIVE_TRUE_TASK 2 /* assert now true */
@d NOW_ADJECTIVE_FALSE_TASK 3 /* assert now false */

@h Testing and asserting in play.
Now for testing, making true and making false in play. We won't be there when
the story file is played, of course, so what we have to do is to compile code
to perform the test or force the state.

In fact what we do is to supply an I6 schema, which for this purpose is
simply the text of I6 code in which the escape |*1| represents the value
to which the adjective is applied. In the example of "open" for containers,
we might choose:
= (text)
	if the sack is open, ...  -->   (Adj_53_t1_v61(*1))
	now the sack is open; ...  -->   Adj_53_t2_v61(*1)
	now the sack is not open; ...  -->   Adj_53_t3_v61(*1)
=
These schemas call an I6 routine called a "support routine". The names
here are schematic: "open" on this run was APH number 53, the run-time
tasks to perform were task 1, task 2 and task 3, and the sense of the
adjective was the one applying to domain 61 -- which in this example run
was the weak ID of "object". In other words, these are routines to "test
open in the sense of objects", "now open in the sense of objects", and
"now not open in the sense of objects".

If we make a choice like that, then we say that the task is provided
"via a support routine". We need not do so: for instance,
= (text)
	if the Entire Game is happening, ...  -->  (scene_status->(*1 - 1)==1)
=
is an example where the sense of "happening" for scenes can be tested
directly using a schema, without calling a support routine. And clearly
support routines only put off the problem, because we will also have to
compile the routine itself. So why use them? The answer is that in
complicated situations where run-time type checking is needed, they
avoid duplication of code, and can make repeated use of the |*1| value
without repeating any side-effects produced by the calculation of this
value. They also make the code simpler for human eyes to read.

@ When an AM has been declared, the provider can choose to set an I6
schema for it, for any of the tasks, immediately; or can wait and do it
later; or can choose not to do it, and instead provide code which
generates a suitable schema on the fly. If at whatever stage the
provider does set an I6 schema for a task, it should call the following.

Note that any AM working on objects always has to go via a support
routine -- this is because, thanks to weak domain-checking, there may
be run-time type-checking code to apply. In other cases, the provider
can choose to go via a support routine or not.

=
i6_schema *AdjectiveMeanings::set_i6_schema(adjective_meaning *am,
	int T, int via_support) {
	kind *K = AdjectiveMeaningDomains::get_kind(am);
	if (K == NULL) K = K_object;
	if (Kinds::Behaviour::is_object(K)) via_support = TRUE;
	am->task_data[T].task_via_support_routine = via_support;
	return &(am->task_data[T].i6s_for_runtime_task);
}


@ The following is needed when making sense of the I6-to-I7 escape sequence
|(+ adj +)|, where |adj| is the name of an adjective. Since I6 is typeless,
there's no good way to choose which sense of the adjective is meant, so we
don't know which routine to expand out. The convention is: a meaning for
objects, if there is one; otherwise the first-declared meaning.

=
int AdjectiveMeanings::write_adjective_test_routine(value_holster *VH, adjective *adj) {
	i6_schema *sch;
	int weak_id = RTKinds::weak_id(K_object);
	sch = AdjectiveAmbiguity::schema_for_task(adj, NULL,
		TEST_ADJECTIVE_TASK);
	if (sch == NULL) {
		adjective_meaning *am = AdjectiveAmbiguity::first_meaning(adj);
		if (am == NULL) return FALSE;
		kind *am_kind = AdjectiveMeaningDomains::get_kind(am);
		if (am_kind == NULL) return FALSE;
		weak_id = RTKinds::weak_id(am_kind);
	}
	Produce::val_iname(Emit::tree(), K_value,
		RTAdjectives::iname(adj, TEST_ADJECTIVE_TASK, weak_id));
	return TRUE;
}

@ The following instructs an AM to use a support routine to handle a given
task.

=
void AdjectiveMeanings::pass_task_to_support_routine(adjective_meaning *am,
	int T) {
	AdjectiveMeanings::set_i6_schema(am, T, TRUE);
}

@ Note that the |task_via_support_routine| values are not flags: they can be
|TRUE| (allowed, done via support routine), |FALSE| (allowed, done directly)
or |NOT_APPLICABLE| (the task certainly can't be done). If none of the
applicable meanings for the adjective are able to perform the task at
run-time, we return |NULL| as our schema, and the code-generator will use
that to issue a suitable problem message.

=
i6_schema *AdjectiveMeanings::schema_for_task(adjective_meaning *am, int T) {
	AdjectiveMeanings::prepare_schemas(am, T);
	switch (am->task_data[T].task_via_support_routine) {
		case FALSE: return &(am->task_data[T].i6s_for_runtime_task);
		case TRUE:
			if (Calculus::Schemas::empty(&(am->task_data[T].i6s_to_transfer_to_SR)))
				@<Construct a schema for this adjective, using the standard routine naming@>;
			return &(am->task_data[T].i6s_to_transfer_to_SR);
	}
	return NULL;
}

@ Where the following is complicated by the need to respect negations; it may
be that the original adjective has a support routine defined, but that the
negation does not, and so must use those of the original.

@<Construct a schema for this adjective, using the standard routine naming@> =
	int task = T; char *negation_operator = "";
	adjective *use_adj = am->owning_adjective;
	if (am->negated_from) {
		use_adj = am->negated_from->owning_adjective;
		switch (T) {
			case TEST_ADJECTIVE_TASK: negation_operator = "~~"; break;
			case NOW_ADJECTIVE_TRUE_TASK: task = NOW_ADJECTIVE_FALSE_TASK; break;
			case NOW_ADJECTIVE_FALSE_TASK: task = NOW_ADJECTIVE_TRUE_TASK; break;
		}
	}
	inter_name *iname = RTAdjectives::iname(use_adj, task,
		RTKinds::weak_id(AdjectiveMeaningDomains::get_kind(am)));
	Calculus::Schemas::modify(&(am->task_data[T].i6s_to_transfer_to_SR), "*=-(%s%n(*1))",
		negation_operator, iname);

@h Kinds of adjectives.
This is where |inweb|'s use of C rather than |C++| or Python as a base
language becomes a little embarrassing: we really want to have seven or
eight subclasses of an "adjective" class, and provide a group of methods.
Instead we simulate this with the following clumsy code. (More elegant
code using pointers to functions would trip up |inweb|'s structure-element
usage checking.)

To define a new kind of adjective, first allocate it a new |*_KADJ|
constant (see above). Then declare functions to handle the following
methods.

@ 1. |*_KADJ_parse|. This enables the kind of adjective to claim a definition
which the user has explicitly written, like so:

>> Definition: A ... (called ...) is ... if ...

In place of the ellipses are the adjective name, domain name, condition
text and (optionally) also the calling name. The routine should return a
pointer to the AM it creates, if it does want to claim the definition;
and |NULL| if it doesn't want it. |sense| is either $1$, meaning that
"if" was used (the condition has positive sense); or $-1$, meaning
that it was "unless" (a negative sense); or $0$, meaning that instead
of a condition, a rule was supplied. (Most kinds of adjective will only
claim if the sense is $1$; some never claim at all.)

@e PARSE_ADJM_MTID

=
INT_METHOD_TYPE(PARSE_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW)

adjective_meaning *AdjectiveMeanings::parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	for (int priority = 0; priority < 10; priority++) {
		adjective_meaning_family *f;
		LOOP_OVER(f, adjective_meaning_family)
			if (f->parsing_priority == priority)
				@<Try the f family@>;
	}
	return NULL;
}

@<Try the f family@> =
	adjective_meaning *am = NULL;
	int rv = FALSE;
	INT_METHOD_CALL(rv, f, PARSE_ADJM_MTID, &am, q, sense, AW, DNW, CONW, CALLW);
	if (rv) return am;

@ 2. |*_KADJ_compiling_soon|. This warns the adjective that it will shortly be
needed in compilation, that is, that code will soon be compiled which uses it.
This advance warning is an opportunity to compile a schema for the adjective
at the last minute, but there is no obligation. There is also no return value.

@e PREPARE_SCHEMAS_ADJM_MTID

=
VOID_METHOD_TYPE(PREPARE_SCHEMAS_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, int T)

void AdjectiveMeanings::prepare_schemas(adjective_meaning *am, int T) {
	VOID_METHOD_CALL(am->family, PREPARE_SCHEMAS_ADJM_MTID, am, T);
	am->schemas_prepared = TRUE;
}

@ 3. |*_KADJ_compile|. We should now either compile code which, in the
given stack frame and writing code to the given file handle, carries out the
given task for the adjective, and return |TRUE|; or return |FALSE| to
tell Inform that the task is impossible.

Note that if an adjective has defined a schema to handle the task, then its
|*_KADJ_compile| is not needed and not consulted.

@e COMPILE_ADJM_MTID

=
int AdjectiveMeanings::emit_meaning(adjective_meaning *am, int T, ph_stack_frame *phsf) {
	int rv = AdjectiveMeanings::compile_inner(am, T, TRUE, phsf);
	am->support_function_compiled = TRUE;
	return rv;
}

int AdjectiveMeanings::compilation_possible(adjective_meaning *am, int T) {
	return AdjectiveMeanings::compile_inner(am, T, FALSE, NULL);
}

INT_METHOD_TYPE(COMPILE_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, int T, int emit_flag, ph_stack_frame *phsf)

int AdjectiveMeanings::compile_inner(adjective_meaning *am, int T, int emit_flag, ph_stack_frame *phsf) {
	AdjectiveMeanings::prepare_schemas(am, T);
	@<Use the I6 schema instead to compile the task, if one exists@>;
	int rv = FALSE;
	INT_METHOD_CALL(rv, am->family, COMPILE_ADJM_MTID, am, T, emit_flag, phsf);
	return rv;
}

@ We expand the I6 schema, placing the "it" variable -- a nameless call
parameter which is always local variable number 0 for this stack frame --
into |*1|.

@<Use the I6 schema instead to compile the task, if one exists@> =
	if (Calculus::Schemas::empty(&(am->task_data[T].i6s_for_runtime_task)) == FALSE) {
		if (emit_flag) {
			parse_node *it_var = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING,
				LocalVariables::it_variable());
			pcalc_term it_term = Terms::new_constant(it_var);
			EmitSchemas::emit_expand_from_terms(&(am->task_data[T].i6s_for_runtime_task), &it_term, NULL, FALSE);
		}
		return TRUE;
	}

@ 4. |*_KADJ_assert|. We should now either take action to ensure that
the adjective will hold (or not hold, according to |parity|) for the given
object or value; or return |FALSE| to tell Inform that this cannot be
asserted, which will trigger a problem message.

@e ASSERT_ADJM_MTID

=
INT_METHOD_TYPE(ASSERT_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, inference_subject *infs_to_assert_on,
	parse_node *val_to_assert_on, int parity)

int AdjectiveMeanings::assert_single(adjective_meaning *am,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	if (am->negated_from) {
		am = am->negated_from; parity = (parity)?FALSE:TRUE;
	}
	int rv = FALSE;
	INT_METHOD_CALL(rv, am->family, ASSERT_ADJM_MTID, am, infs_to_assert_on,
		val_to_assert_on, parity);
	return rv;
}

@ 5. |*_KADJ_index|. This should print a description of the adjective to the
index, for use in the Phrasebook lexicon. Note that it is only needed where
the AM has been constructed positively, that is, it is not needed if the
AM was made as a negation of something else.

Note also that if the AM was defined with any indexing text then that will
be printed if the routine does nothing better.

@e INDEX_ADJM_MTID

=
INT_METHOD_TYPE(INDEX_ADJM_MTID, adjective_meaning_family *f, text_stream *OUT,
	adjective_meaning *am)

void AdjectiveMeanings::print_to_index(OUTPUT_STREAM, adjective_meaning *am) {
	@<Index the domain of validity of the AM@>;
	if (am->negated_from) {
		wording W = Adjectives::get_nominative_singular(am->negated_from->owning_adjective);
		WRITE(" opposite of </i>%+W<i>", W);
	} else {
		int rv = FALSE;
		INT_METHOD_CALL(rv, am->family, INDEX_ADJM_MTID, OUT, am);
		if ((rv == FALSE) && (Wordings::nonempty(am->indexing_text)))
			WRITE("%+W", am->indexing_text);
	}
	if (Wordings::nonempty(am->indexing_text))
		Index::link(OUT, Wordings::first_wn(am->indexing_text));
}

@ This is supposed to imitate dictionaries, distinguishing meanings by
concisely showing their usage. Thus "empty" would have indexed entries
prefaced "(of a rulebook)", "(of an activity)", and so on.

@<Index the domain of validity of the AM@> =
	if (am->domain.domain_infs)
		WRITE("(of </i>%+W<i>) ", InferenceSubjects::get_name_text(am->domain.domain_infs));

@h Parsing for adaptive text.

=
<adaptive-adjective> internal {
	if (Projects::get_language_of_play(Task::project()) == DefaultLanguage::get(NULL)) return FALSE;
	adjective *adj;
	LOOP_OVER(adj, adjective) {
		wording AW = Clusters::get_form_general(adj->adjective_names, Projects::get_language_of_play(Task::project()), 1, -1);
		if (Wordings::match(AW, W)) {
			==> { FALSE, adj};
			return TRUE;
		}
	}
	==> { fail nonterminal };
}

