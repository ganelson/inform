[PhraseRequests::] Phrase Requests.

To store and later fill requests to compile To... phrases.

@ "To" phrases are compiled only when they are needed, and they can be
compiled in variant forms depending on the kinds of their arguments; so
we use the following chits to keep track of what's outstanding:

=
typedef struct to_phrase_request {
	struct id_body *requested_phrase;
	struct kind *requested_exact_kind;
	struct kind *kind_variables_interpretation[27];
	struct inter_name *req_iname;
	CLASS_DEFINITION
} to_phrase_request;

@h Logical priority of To phrases.

@h Compilation requests.
Here's how a request is made. The kind supplied should be that which the phrase
has in this version: for example, given the definition

>> To judge (V - a value) against (W - a value): ...

the invocation

>> judge 2 against "two";

would result in a call to this routine where K was set to:
= (text)
	phrase (number, text) -> nothing
=
If the kind involves variables, the caller must also supply the current
values in force, so that there is no possible ambiguity in how we read K.

=
to_phrase_request *PhraseRequests::make_request(id_body *idb, kind *K,
	kind_variable_declaration *kvd, wording W) {
	if ((idb == NULL) || (K == NULL)) internal_error("bad request");

	int nr = 0;
	to_phrase_request *req;
	LOOP_OVER(req, to_phrase_request)
		if (idb == req->requested_phrase) {
			nr++;
			if (Kinds::eq(K, req->requested_exact_kind)) return req;
		}
	if (Kinds::Behaviour::semidefinite(K) == FALSE)
		@<Issue a problem message for undetermined kinds@>;

	req = CREATE(to_phrase_request);
	req->requested_exact_kind = K;
	req->requested_phrase = idb;
	compilation_unit *cm = CompilationUnits::current();
	if (ImperativeDefinitions::body_at(idb))
		cm = CompilationUnits::find(ImperativeDefinitions::body_at(idb));

	package_request *P = Hierarchy::package_within(REQUESTS_HAP, idb->compilation_data.requests_package);
	req->req_iname = Hierarchy::make_localised_iname_in(PHRASE_FN_HL, P, cm);

	for (int i=0; i<27; i++) req->kind_variables_interpretation[i] = NULL;
	for (; kvd; kvd=kvd->next)
		req->kind_variables_interpretation[kvd->kv_number] = kvd->kv_value;

	return req;
}

@ It's quite hard to get this, but if you supply the empty list written as
a constant to a phrase which uses a kind variable in the form "list of K",
then K would have be just "value", since Inform doesn't know what the empty
list is a list of. The result would be:

@<Issue a problem message for undetermined kinds@> =
	Problems::quote_source(1, ImperativeDefinitions::body_at(idb));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UndeterminedKind));
	if (Wordings::empty(W)) {
		Problems::issue_problem_segment(
			"The phrase %1 needs to be used in such a way that I know "
			"what kinds of values go into it.");
	} else {
		Problems::quote_wording_as_source(2, W);
		Problems::issue_problem_segment(
			"The phrase %1 needs to be used in such a way that I know "
			"what kinds of values go into it; so I'm not sure how to "
			"make sense of it from %2.");
	}
	Problems::issue_problem_end();

@ The following puts together an I6 identifier for a phrase, and also handles
the case of an inline definition which happens to consist of a call to an
I6 routine.

=
inter_name *PhraseRequests::make_iname(id_body *idb, kind *req_kind) {
	if (IDTypeData::invoked_inline(idb)) {
		TEMPORARY_TEXT(identifier)
		wchar_t *p = IDCompilation::get_inline_definition(idb);
		int found = FALSE;
		for (int i=0; p[i]; i++)
			if (Characters::isalpha(p[i])) {
				int j = 0;
				while (((Characters::isalpha(p[i])) || (Characters::isdigit(p[i])) || (p[i] == '_')) && (j++ < 31))
					PUT_TO(identifier, p[i++]);
				found = TRUE;
				break;
			}
		if (found == FALSE) {
			current_sentence = ImperativeDefinitions::body_at(idb);
			Problems::quote_source(1, current_sentence);
			Problems::quote_phrase(2, idb);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PhraseNamedI6Failed));
			Problems::issue_problem_segment(
				"You wrote %1, defining the phrase '%2' with a piece of Inform 6 "
				"code, but also giving it a name as a function to be used in an "
				"equation, or in some functional programming context. That's only "
				"allowed if the I6 definition consists simply of a call to an "
				"I6 function - and this doesn't, so far as I can see.");
			Problems::issue_problem_end();
			WRITE_TO(identifier, "ErrorRecoverySymbol");
		}
		inter_name *symb = Produce::find_by_name(Emit::tree(), identifier);
		DISCARD_TEXT(identifier)
		return symb;
	}
	to_phrase_request *req = PhraseRequests::make_request(
		idb, req_kind, NULL, EMPTY_WORDING);
	return Routines::Compile::iname(idb, req);
}

@ In the course of doing this, |IDCompilation::compile| calls us back to ask us
to write a comment about this:

=
void PhraseRequests::comment_on_request(to_phrase_request *req) {
	if (req == NULL) Produce::comment(Emit::tree(), I"No specific request");
	else {
		TEMPORARY_TEXT(C)
		WRITE_TO(C, "Request %d: ", req->allocation_id);
		Kinds::Textual::write(C, req->requested_exact_kind);
		Produce::comment(Emit::tree(), C);
		DISCARD_TEXT(C)
	}
}

@ It also needs access to:

=
kind *PhraseRequests::kind_of_request(to_phrase_request *req) {
	if (req == NULL) internal_error("null request");
	return req->requested_exact_kind;
}

kind **PhraseRequests::kind_variables_for_request(to_phrase_request *req) {
	if (req == NULL) internal_error("null request");
	return req->kind_variables_interpretation;
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
void PhraseRequests::compile_as_needed(void) {
	int repeat = TRUE;
	while (repeat) {
		repeat = FALSE;
		if (PhraseRequests::compilation_coroutine(
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

@ The following coroutine compiles any pending requests for phrase compilation
since the last time it was called.

=
to_phrase_request *latest_request_granted = NULL;
int PhraseRequests::compilation_coroutine(int *i, int max_i) {
	int N = 0;
	while (TRUE) {
		to_phrase_request *req;
		if (latest_request_granted == NULL) req = FIRST_OBJECT(to_phrase_request);
		else req = NEXT_OBJECT(latest_request_granted, to_phrase_request);
		if (req == NULL) break;

		latest_request_granted = req;
		IDCompilation::compile(latest_request_granted->requested_phrase,
			i, max_i, NULL, latest_request_granted, NULL);
		N++;
	}
	return N;
}

@h Basic mode main.

=
void PhraseRequests::invoke_to_begin(void) {
	if (Task::begin_execution_af_to_begin()) {
		inter_name *iname = Hierarchy::find(SUBMAIN_HL);
		packaging_state save = Routines::begin(iname);
		imperative_defn *beginner = ToPhraseFamily::to_begin();
		if (beginner) {
			kind *void_kind = Kinds::function_kind(0, NULL, K_nil);
			inter_name *IS = Routines::Compile::iname(beginner->body_of_defn,
				PhraseRequests::make_request(beginner->body_of_defn,
					void_kind, NULL, EMPTY_WORDING));
			Produce::inv_call_iname(Emit::tree(), IS);
		}
		Routines::end(save);
		Hierarchy::make_available(Emit::tree(), iname);
	}
}
