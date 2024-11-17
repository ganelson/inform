[PhraseRequests::] Phrase Requests.

To store and later fill requests to compile To... phrases.

@ "To..." phrases are compiled only when needed, and they can be compiled in
variant forms depending on the kinds of their arguments. Each of those forms
is compiled as a different function at runtime.[1] For example, given the
definition:

>> To judge (V - a value) against (W - a value): ...

the invocation:

>> judge 2 against "two";

would result in a request to compile a version of "to judge... against..."
with the kind |phrase (number, text) -> nothing|.

If the kind involves variables, the caller must also supply the current
values in force, so that there is no possible ambiguity in how we read K.

When we want to invoke "to judge... against...", then, we call one of the
following twp functions. It returns the iname of the function we should
call, and makes a note for later that it will need to compile that function.

[1] I believe this practice is called monomorphisation, and is also how Rust
and most C++ compilers handle the same issue.

=
inter_name *PhraseRequests::simple_request(id_body *idb, kind *req_kind) {
	return PhraseRequests::complex_request(idb, req_kind, NULL, EMPTY_WORDING);
}

inter_name *PhraseRequests::complex_request(id_body *idb, kind *req_kind,
	kind_variable_declaration *kvd, wording W) {
	if (IDTypeData::invoked_inline(idb))
		@<Avoid the need for a request by using an inline typeless Inter function@>;
	to_phrase_request *req = PhraseRequests::request_inner(idb, req_kind, kvd, W);
	return req->req_iname;
}

@ Suppose the phrase is defined inline, like so:
= (text as Inform 7)
To judge (V - a value) against (W - a value):
	(- JudgeAgainst({V}, {W}); -)
=
We then assume that |JudgeAgainst| is provided by some kit of Inter code, and
can handle values of any kind which this may produce. So we return its iname,
and do not make a request. If the definition is any more complex than this,
we simply give in and throw a problem.

@<Avoid the need for a request by using an inline typeless Inter function@> =
	TEMPORARY_TEXT(identifier)
	@<Extract an identifier from the inline definition@>;
	if (Str::len(identifier) == 0) @<Issue PM_PhraseNamedI6Failed@>;
	inter_name *symb = HierarchyLocations::find_by_name(Emit::tree(), identifier);
	DISCARD_TEXT(identifier)
	return symb;

@<Extract an identifier from the inline definition@> =
	inchar32_t *p = CompileImperativeDefn::get_inline_definition(idb);
	for (int i=0; p[i]; i++)
		if (Characters::isalpha(p[i])) {
			int j = 0;
			while (((Characters::isalpha(p[i])) ||
				(Characters::isdigit(p[i])) || (p[i] == '_')) && (j++ < 31))
				PUT_TO(identifier, p[i++]);
			break;
		}

@<Issue PM_PhraseNamedI6Failed@> =
	current_sentence = ImperativeDefinitions::body_at(idb);
	Problems::quote_source(1, current_sentence);
	Problems::quote_phrase(2, idb);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_PhraseNamedI6Failed));
	Problems::issue_problem_segment(
		"You wrote %1, defining the phrase '%2' with a piece of Inform 6 "
		"code, but also giving it a name as a function to be used in an "
		"equation, or in some functional programming context. That's only "
		"allowed if the I6 definition consists simply of a call to an "
		"I6 function - and this doesn't, so far as I can see.");
	Problems::issue_problem_end();
	WRITE_TO(identifier, "ErrorRecoverySymbol");

@ That function calls this one, which returns a //to_phrase_request// object
for the request needed.

=
typedef struct to_phrase_request {
	struct id_body *compile_from;
	struct kind *req_kind;
	struct kind *kv_interpretation[27];
	struct inter_name *req_iname;
	struct inter_name *md_iname;
	CLASS_DEFINITION
} to_phrase_request;

to_phrase_request *PhraseRequests::request_inner(id_body *idb, kind *K,
	kind_variable_declaration *kvd, wording W) {
	@<Issue a problem if K is still too vague@>;
	@<Check whether this request has already been made@>;
	@<Return a fresh request@>;
}

@ It's quite hard to get this, but if you supply the empty list written as
a constant to a phrase which uses a kind variable in the form "list of K",
then K would have be just "value", since Inform doesn't know what the empty
list is a list of. The result would be:

@<Issue a problem if K is still too vague@> =
	if ((idb == NULL) || (K == NULL)) internal_error("bad request");
	if (Kinds::Behaviour::semidefinite(K) == FALSE) {
		LOG("Kind K = %u\n", K);
		Problems::quote_source(1, ImperativeDefinitions::body_at(idb));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UndeterminedKind));
		if (Wordings::empty(W)) {
			Problems::issue_problem_segment(
				"The phrase %1 needs to be used in such a way that I know what kinds "
				"of values go into it.");
		} else {
			Problems::quote_wording_as_source(2, W);
			Problems::issue_problem_segment(
				"The phrase %1 needs to be used in such a way that I know what kinds "
				"of values go into it; so I'm not sure how to make sense of it from %2.");
		}
		Problems::issue_problem_end();
	}

@<Check whether this request has already been made@> =
	to_phrase_request *req;
	LOOP_OVER(req, to_phrase_request)
		if (idb == req->compile_from)
			if (Kinds::eq(K, req->req_kind))
				return req;

@<Return a fresh request@> =
	to_phrase_request *req = CREATE(to_phrase_request);
	req->req_kind = K;
	req->compile_from = idb;
	Latticework::unpack_kvd(req->kv_interpretation, kvd);
	package_request *P = Hierarchy::package_within(REQUESTS_HAP,
		CompileImperativeDefn::requests_package(idb));
	req->req_iname = Hierarchy::make_iname_in(PHRASE_FN_HL, P);
	req->md_iname = Hierarchy::make_iname_in(PHRASE_SYNTAX_MD_HL, P);
	text_stream *desc = Str::new();
	WRITE_TO(desc, "phrase request (%u) for '%W'",
		K, Node::get_text(req->compile_from->head_of_defn->at));
	Sequence::queue(&PhraseRequests::compilation_agent,
		STORE_POINTER_to_phrase_request(req), desc);
	return req;

@ Two access functions:

=
kind *PhraseRequests::kind_of_request(to_phrase_request *req) {
	if (req == NULL) internal_error("null request");
	return req->req_kind;
}

kind **PhraseRequests::kind_variables_for_request(to_phrase_request *req) {
	if (req == NULL) internal_error("null request");
	return req->kv_interpretation;
}

@ The following agent acts on a pending requests for phrase compilation: see
//core: How To Compile//.

=
void PhraseRequests::compilation_agent(compilation_subtask *task) {
	to_phrase_request *req = RETRIEVE_POINTER_to_phrase_request(task->data);
	CompileImperativeDefn::go(req->compile_from, NULL, req, NULL);
	CompileImperativeDefn::advance_progress_bar(req->compile_from,
		&total_phrases_compiled, total_phrases_to_compile);
	req->compile_from->compilation_data.at_least_one_compiled_form_needed = FALSE;
}

@ In Basic Inform, only, execution begins at the "To..." phrase "To begin", and
this is done by compiling a "submain" function which calls the function for
that phrase. This provides a neat example of how to make a phrase request:

=
void PhraseRequests::invoke_to_begin(void) {
	if (Task::begin_execution_at_to_begin()) {
		inter_name *iname = Hierarchy::find(SUBMAIN_HL);
		packaging_state save = Functions::begin(iname);
		imperative_defn *beginner = ToPhraseFamily::to_begin();
		if (beginner) {
			inter_name *begin_fn =
				PhraseRequests::simple_request(
					beginner->body_of_defn,
					Kinds::function_kind(0, NULL, K_nil));
			EmitCode::call(begin_fn);
		}
		Functions::end(save);
		Hierarchy::make_available(iname);
	}
}
