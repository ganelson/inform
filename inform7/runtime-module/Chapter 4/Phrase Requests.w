[PhraseRequests::] Phrase Requests.

To store and later fill requests to compile To... phrases.

@ "To" phrases are compiled only when they are needed, and they can be
compiled in variant forms depending on the kinds of their arguments; so
we use the following chits to keep track of what's outstanding:

=
typedef struct to_phrase_request {
	struct phrase *requested_phrase;
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
to_phrase_request *PhraseRequests::make_request(phrase *ph, kind *K,
	kind_variable_declaration *kvd, wording W) {
	if ((ph == NULL) || (K == NULL)) internal_error("bad request");

	int nr = 0;
	to_phrase_request *req;
	LOOP_OVER(req, to_phrase_request)
		if (ph == req->requested_phrase) {
			nr++;
			if (Kinds::eq(K, req->requested_exact_kind)) return req;
		}
	if (Kinds::Behaviour::semidefinite(K) == FALSE)
		@<Issue a problem message for undetermined kinds@>;

	req = CREATE(to_phrase_request);
	req->requested_exact_kind = K;
	req->requested_phrase = ph;
	compilation_unit *cm = CompilationUnits::current();
	if (ph->from->at) cm = CompilationUnits::find(ph->from->at);

	package_request *P = Hierarchy::package_within(REQUESTS_HAP, ph->requests_package);
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
	Problems::quote_source(1, Phrases::declaration_node(ph));
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
inter_name *PhraseRequests::make_iname(phrase *ph, kind *req_kind) {
	if (Phrases::TypeData::invoked_inline(ph)) {
		TEMPORARY_TEXT(identifier)
		wchar_t *p = Phrases::get_inline_definition(ph);
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
			current_sentence = Phrases::declaration_node(ph);
			Problems::quote_source(1, current_sentence);
			Problems::quote_phrase(2, ph);
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
		ph, req_kind, NULL, EMPTY_WORDING);
	return Routines::Compile::iname(ph, req);
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
		Phrases::compile(latest_request_granted->requested_phrase,
			i, max_i, NULL, latest_request_granted, NULL);
		N++;
	}
	return N;
}

@ In the course of doing this, |Phrases::compile| calls us back to ask us
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
