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

	int schemas_prepared; /* have schemas been prepared yet? */
	struct adjective_task_data task_data[NO_ATOM_TASKS + 1]; /* see below */

	int has_been_compiled_in_support_function; /* which may never happen */

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
	am->has_been_compiled_in_support_function = FALSE;
	am->schemas_prepared = FALSE;
	am->negated_from = NULL;
	AdjectiveMeanings::initialise_all_task_data(am);
	return am;
}

@ Or as the logical negation of an existing meaning (thus, "odd" for numbers
might be created as the negation of "even" for numbers):

=
adjective_meaning *AdjectiveMeanings::negate(adjective_meaning *other) {
	if (other->negated_from) internal_error("cannot negate an already negated AM");
	adjective_meaning *am = CREATE(adjective_meaning);
	am->defined_at = current_sentence;
	am->indexing_text = other->indexing_text;
	am->owning_adjective = NULL;
	am->domain = other->domain;
	am->family = other->family;
	am->family_specific_data = other->family_specific_data;
	am->has_been_compiled_in_support_function = FALSE;
	am->schemas_prepared = FALSE;
	am->negated_from = other;
	AdjectiveMeanings::negate_task_data(am, other);
	for (int i=1; i<=NO_ATOM_TASKS; i++) {
		int j = i;
		if (i == NOW_ATOM_TRUE_TASK) j = NOW_ATOM_FALSE_TASK;
		if (i == NOW_ATOM_FALSE_TASK) j = NOW_ATOM_TRUE_TASK;
		AdjectiveMeanings::copy_task_data(&(am->task_data[j]), &(other->task_data[i]));
		Calculus::Schemas::modify(&(am->task_data[j].call_to_support_function), "");
	}
	return am;
}

@h Task data.
When Inform needs to compile code for testing if an adjective is true as
applied to something, or to make it now true (or false), it does this by
compiling code for the associated unary predicate -- see
//The Adjectival Predicates//. What to compile depends on the meaning or
meanings which might apply; if it's this meaning, then we will need an
I6 schema to carry out one of three tasks, |TEST_ATOM_TASK|,
|NOW_ATOM_TRUE_TASK|, or |NOW_ATOM_FALSE_TASK|.

A meaning has one of these for each of the possible tasks:

=
typedef struct adjective_task_data {
	int task_mode; /* one of the |*_TASKMODE| constants: see below */
	struct i6_schema call_to_support_function; /* where |TRUE| */
	struct i6_schema code_to_perform; /* where |TRUE| */
} adjective_task_data;

void AdjectiveMeanings::initialise_task_data(adjective_task_data *atd) {
	atd->task_mode = NO_TASKMODE;
	Calculus::Schemas::modify(&(atd->code_to_perform), "");
	Calculus::Schemas::modify(&(atd->call_to_support_function), "");
}

void AdjectiveMeanings::copy_task_data(adjective_task_data *to, adjective_task_data *from) {
	to->task_mode = from->task_mode;
	to->code_to_perform = from->code_to_perform;
	to->call_to_support_function = from->call_to_support_function;
}

@ These functions set up the task data for a new meaning. Note the transposition,
so that a negated meaning has the |NOW_ATOM_TRUE_TASK| and |NOW_ATOM_FALSE_TASK|
switched around from the original.

=
void AdjectiveMeanings::initialise_all_task_data(adjective_meaning *am) {
	for (int i=1; i<=NO_ATOM_TASKS; i++)
		AdjectiveMeanings::initialise_task_data(&(am->task_data[i]));
}

void AdjectiveMeanings::negate_task_data(adjective_meaning *am, adjective_meaning *other) {
	for (int i=1; i<=NO_ATOM_TASKS; i++) {
		int j = i;
		if (i == NOW_ATOM_TRUE_TASK) j = NOW_ATOM_FALSE_TASK;
		if (i == NOW_ATOM_FALSE_TASK) j = NOW_ATOM_TRUE_TASK;
		AdjectiveMeanings::copy_task_data(&(am->task_data[j]), &(other->task_data[i]));
		Calculus::Schemas::modify(&(am->task_data[j].call_to_support_function), "");
	}
}

@ The schema for a task generates code to perform it. There are three strategies:

(*) produce a problem message, saying this is impossible;
(*) compile direct inline code;
(*) compile a function call to a function, which actually performs the task;

Those strategies correspond to the three |*_TASKMODE| constants.

By default, an adjective meaning is unable to perform any of the three tasks,
and the creator of it has to call //AdjectiveMeanings::make_schema// to say
otherwise. This puts us by default into |DIRECT_TASKMODE|, unless we're working
in the world of objects where run-time typechecking will be needed -- in which
case |VIA_SUPPORT_FUNCTION_TASKMODE|. But the creator can insist on the latter
anyway with a subsequent call to //AdjectiveMeanings::perform_task_via_function//.

@e NO_TASKMODE from 1
@e DIRECT_TASKMODE
@e VIA_SUPPORT_FUNCTION_TASKMODE

=
i6_schema *AdjectiveMeanings::make_schema(adjective_meaning *am, int T) {
	kind *K = AdjectiveMeaningDomains::get_kind(am);
	if (K == NULL) K = K_object;
	int via_support = DIRECT_TASKMODE;
	if (Kinds::Behaviour::is_object(K)) via_support = VIA_SUPPORT_FUNCTION_TASKMODE;
	am->task_data[T].task_mode = via_support;
	return &(am->task_data[T].code_to_perform);
}

void AdjectiveMeanings::perform_task_via_function(adjective_meaning *am, int T) {
	am->task_data[T].task_mode = VIA_SUPPORT_FUNCTION_TASKMODE;
}

@ And this function reads it back, automatically generating the function call
schema if it's needed.

=
i6_schema *AdjectiveMeanings::get_schema(adjective_meaning *am, int T) {
	AdjectiveMeanings::prepare_schemas(am, T);
	switch (am->task_data[T].task_mode) {
		case DIRECT_TASKMODE:
			return &(am->task_data[T].code_to_perform);
		case VIA_SUPPORT_FUNCTION_TASKMODE:
			if (Calculus::Schemas::empty(&(am->task_data[T].call_to_support_function)))
				@<Construct a schema for calling the support function@>;
			return &(am->task_data[T].call_to_support_function);
	}
	return NULL;
}

i6_schema *AdjectiveMeanings::get_schema_without_call(adjective_meaning *am, int T) {
	AdjectiveMeanings::prepare_schemas(am, T);
	switch (am->task_data[T].task_mode) {
		case DIRECT_TASKMODE:
		case VIA_SUPPORT_FUNCTION_TASKMODE:
			return &(am->task_data[T].code_to_perform);
	}
	return NULL;
}

@ Where the following is complicated by the need to respect negations; it may
be that the original adjective has a support routine defined, but that the
negation does not, and so must use those of the original.

@<Construct a schema for calling the support function@> =
	int task = T; char *negation_operator = "";
	adjective *use_adj = am->owning_adjective;
	if (am->negated_from) {
		use_adj = am->negated_from->owning_adjective;
		switch (T) {
			case TEST_ATOM_TASK: negation_operator = "~~"; break;
			case NOW_ATOM_TRUE_TASK: task = NOW_ATOM_FALSE_TASK; break;
			case NOW_ATOM_FALSE_TASK: task = NOW_ATOM_TRUE_TASK; break;
		}
	}
	inter_name *iname = RTAdjectives::iname(use_adj, task,
		RTKinds::weak_id(AdjectiveMeaningDomains::get_kind(am)));
	Calculus::Schemas::modify(&(am->task_data[T].call_to_support_function),
		"*=-(%s%n(*1))", negation_operator, iname);

@h Families of adjective meanings.
The above API would allow us to make fairly arbitrary one-off adjectives,
but in practice we have a number of distinct purposes and want to make a
whole pile of related adjectives for each one. So we actually create
adjective meanings in "families".

Each family is represented by an instance of the following:

=
typedef struct adjective_meaning_family {
	struct method_set *methods;
	int definition_claim_priority; /* 0 to 9: lower is better */
	CLASS_DEFINITION
} adjective_meaning_family;

adjective_meaning_family *AdjectiveMeanings::new_family(int N) {
	adjective_meaning_family *f = CREATE(adjective_meaning_family);
	f->definition_claim_priority = N;
	f->methods = Methods::new_set();
	return f;
}

@ Families provide a number of methods to tweak how adjectives behave,
and here goes. All of these methods are optional.

|CLAIM_DEFINITION_SENTENCE_ADJM_MTID| is an opportunity to say that a
definition in the source text is asking for this kind of adjective.
Suppose the source has a line like so:

>> Definition: A ... (called ...) is ... if ...

In place of the ellipses are respectively |DNW| (domain wording), |CALLW|
(the calling), |AW| (the adjective) and |CONW| (the condition). |sense| is
either 1, meaning that "if" was used (the condition has positive sense);
or -1, meaning that it was "unless" (a negative sense); or 0, meaning
that instead of a condition, a rule was supplied.

If the method is provided, it should look at these and decide if this is
the sort of adjective it wants to make. If so, it should return |TRUE|
and copy a pointer to the new adjective meaning into |result|. If not,
it should return |FALSE|.

Of course, only one family can take the prize, and so the sequence in which
the families are offered the chance to claim is significant. This sequence
is ascending order of the family's |definition_claim_priority| field.

@e CLAIM_DEFINITION_SENTENCE_ADJM_MTID

=
INT_METHOD_TYPE(CLAIM_DEFINITION_SENTENCE_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q, int sense,
	wording AW, wording DNW, wording CONW, wording CALLW)

adjective_meaning *AdjectiveMeanings::claim_definition(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	for (int priority = 0; priority < 10; priority++) {
		adjective_meaning_family *f;
		LOOP_OVER(f, adjective_meaning_family)
			if (f->definition_claim_priority == priority)
				@<Try the f family@>;
	}
	return NULL;
}

@<Try the f family@> =
	adjective_meaning *am = NULL;
	int rv = FALSE;
	INT_METHOD_CALL(rv, f, CLAIM_DEFINITION_SENTENCE_ADJM_MTID, &am, q, sense,
		AW, DNW, CONW, CALLW);
	if (rv) return am;

@ By default, an adjective meaning cannot be asserted, that is, said to be
true of something (an inference subject) in the model world. So if "fizzy"
is a newly created adjective, the sentence "The drink is fizzy" would be
rejected. But if the family for "fizzy" provides an |ASSERT_ADJM_MTID| method,
it's a different matter. The method should either return |FALSE| to decline
after all, or draw some inferences and then return |TRUE|.

|parity| is |TRUE| if the assertion claims the meaning |am| is true about the
subject |subj|, and otherwise |FALSE|.

@e ASSERT_ADJM_MTID

=
INT_METHOD_TYPE(ASSERT_ADJM_MTID, adjective_meaning_family *f, adjective_meaning *am,
	inference_subject *subj, int parity)

int AdjectiveMeanings::assert(adjective_meaning *am, inference_subject *subj,
	int parity) {
	if (am->negated_from) {
		am = am->negated_from; parity = (parity)?FALSE:TRUE;
	}
	int rv = FALSE;
	INT_METHOD_CALL(rv, am->family, ASSERT_ADJM_MTID, am, subj, parity);
	return rv;
}

@ Next, |PREPARE_SCHEMAS_ADJM_MTID|. Just before code is about to be
generated for the adjective to perform some task, this method is called.
The idea is that this is an opportunity to compile a schema for the adjective
at the last minute (as an alternative to having set the schemas up at
creation time), but there is no obligation.

@e PREPARE_SCHEMAS_ADJM_MTID

=
VOID_METHOD_TYPE(PREPARE_SCHEMAS_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, int task)

void AdjectiveMeanings::prepare_schemas(adjective_meaning *am, int task) {
	VOID_METHOD_CALL(am->family, PREPARE_SCHEMAS_ADJM_MTID, am, task);
	am->schemas_prepared = TRUE;
}

@ |GENERATE_IN_SUPPORT_FUNCTION_ADJM_MTID| offers a way to bypass the usual code
generation process. It is called on only when //runtime: Adjectives// is
compiling a support function -- and therefore it will never be called on if
the adjective doesn't perform this task with a support function; see above.

It is called twice, first with |emit_flag| set to |FALSE|; it should do nothing,
but return |TRUE| to indicate that it wants to generate wacky code of its own.
On the second call, |emit_flag| will be |TRUE|, and this time the method should
follow through on its earlier promise.

If the method is not provided or returns |FALSE|, then the code will be generated
from the schema in the normal way.

As with schemas, |T| is the task to be performed.

If |emit_flag| is |TRUE|, then code should actually be generated, and within
the given stack frame. If it is |FALSE|, the function should simply return
whether it is able to do this or not.

@e GENERATE_IN_SUPPORT_FUNCTION_ADJM_MTID

=
INT_METHOD_TYPE(GENERATE_IN_SUPPORT_FUNCTION_ADJM_MTID, adjective_meaning_family *f,
	adjective_meaning *am, int T, int emit_flag, ph_stack_frame *phsf)

@ This dual behaviour means there are two function calls invoking it:

=
int AdjectiveMeanings::generate_in_support_function(adjective_meaning *am,
	int T, ph_stack_frame *phsf) {
	int rv = AdjectiveMeanings::nscg_inner(am, T, TRUE, phsf);
	am->has_been_compiled_in_support_function = TRUE;
	return rv;
}

int AdjectiveMeanings::can_generate_in_support_function(adjective_meaning *am, int T) {
	return AdjectiveMeanings::nscg_inner(am, T, FALSE, NULL);
}

int AdjectiveMeanings::nscg_inner(adjective_meaning *am, int T, int emit_flag,
	ph_stack_frame *phsf) {
	AdjectiveMeanings::prepare_schemas(am, T);
	@<Use the I6 schema instead to compile the task, if one exists@>;
	int rv = FALSE;
	INT_METHOD_CALL(rv, am->family, GENERATE_IN_SUPPORT_FUNCTION_ADJM_MTID, am, T,
		emit_flag, phsf);
	return rv;
}

@ Because we are inside the support function, we need to call 
//AdjectiveMeanings::get_schema_without_call// not //AdjectiveMeanings::get_schema// --
otherwise, we would be given the schema for a function call to the very thing
we are now trying to compile, and the result would be code which recursed
forever.

The stack frame for the support function has a single variable "it" as number 0,
and we set |*1| to be this parameter. This is in fact the term we are performing
the task on. |*2| is unset.

@<Use the I6 schema instead to compile the task, if one exists@> =
	i6_schema *sch = AdjectiveMeanings::get_schema_without_call(am, T);
	if (Calculus::Schemas::empty(sch) == FALSE) {
		if (emit_flag) {
			parse_node *it_var = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING,
				LocalVariables::it_variable());
			pcalc_term it_term = Terms::new_constant(it_var);
			EmitSchemas::emit_expand_from_terms(sch, &it_term, NULL, FALSE);
		}
		return TRUE;
	}

@ At last, something simpler. |INDEX_ADJM_MTID|, if provided, should print
a description suitable for use in the lexicon part of the index, and return
|TRUE|. If not provided, or it returns |FALSE|, something sensible is done
instead; this is only an opportunity to improve the wording.

Note that this is only called for the positive sense of an adjective meaning,
not for one which is the negated form of another.

@e INDEX_ADJM_MTID

=
INT_METHOD_TYPE(INDEX_ADJM_MTID, adjective_meaning_family *f, text_stream *OUT,
	adjective_meaning *am)

int AdjectiveMeanings::nonstandard_index_entry(OUTPUT_STREAM, adjective_meaning *am) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, am->family, INDEX_ADJM_MTID, OUT, am);
	return rv;
}
