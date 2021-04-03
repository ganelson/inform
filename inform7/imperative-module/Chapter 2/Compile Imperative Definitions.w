[CompileImperativeDefn::] Compile Imperative Definitions.

Compiling an Inter function from the body of an imperative definition.

@ This is a short section, but the function //CompileImperativeDefn::go// sits
at the top of a mountain of code occupying most of the rest of this module.

=
void CompileImperativeDefn::go(id_body *idb, shared_variable_access_list *legible,
	to_phrase_request *req, rule *R) {
	parse_node *code_at = ImperativeDefinitions::body_at(idb);
	if (Node::is(code_at->next, DEFN_CONT_NT)) code_at = code_at->next;

	LOGIF(PHRASE_COMPILATION, "Compiling phrase:\n$T", code_at);

	current_sentence = code_at;
	CompilationUnits::set_current(code_at);

	stack_frame *frame = &(idb->compilation_data.id_stack_frame);
	inter_name *iname = req?(req->req_iname):(IDCompilation::iname(idb));

	@<Set up the stack frame for this compilation request@>;
	@<Compile some commentary about the function to follow@>;
	
	packaging_state save = Functions::begin_from_idb(iname, frame, idb);
	@<Compile the body of the routine@>;
	Functions::end(save);

	current_sentence = NULL;
	CompilationUnits::set_current(NULL);
}

@<Compile some commentary about the function to follow@> =
	if (req == NULL) {
		Produce::comment(Emit::tree(), I"No specific request");
	} else {
		TEMPORARY_TEXT(C)
		WRITE_TO(C, "Request %d: ", req->allocation_id);
		Kinds::Textual::write(C, PhraseRequests::kind_of_request(req));
		Produce::comment(Emit::tree(), C);
		DISCARD_TEXT(C)
	}
	ImperativeDefinitions::write_comment_describing(idb->head_of_defn);

@<Set up the stack frame for this compilation request@> =
	id_type_data *idtd = &(idb->type_data);

	kind *version_kind = NULL;
	if (req) version_kind = PhraseRequests::kind_of_request(req);
	else version_kind = IDTypeData::kind(idtd);
	IDCompilation::initialise_stack_frame_from_type_data(frame, idtd, version_kind, FALSE);

	if (req) Frames::set_kind_variables(frame,
		PhraseRequests::kind_variables_for_request(req));
	else Frames::set_kind_variables(frame, NULL);

	Frames::set_shared_variable_access_list(frame, legible);

	LocalVariableSlates::deallocate_all(frame); /* in case any are left from an earlier compile */
	PreformCache::warn_of_changes(); /* that local variables may have changed */

@<Compile the body of the routine@> =
	current_sentence = code_at;
	if (RTRules::compile_test_head(idb, R) == FALSE) {
		if (code_at) {
			VerifyTree::verify_structure_from(code_at);
			CompileBlocksAndLines::full_definition_body(1, code_at->down);
			VerifyTree::verify_structure_from(code_at);
		}
		current_sentence = code_at;
		RTRules::compile_test_tail(idb, R);

		@<Compile a terminal return statement@>;
	}

@ In Inter, all functions must return a value: in Inform 7, some phrases do not.
If we are compiling a function to perform such a phrase, we have it return 0.
This value will almost certainly be thrown away, but it seems clearest to make
it 0 in all cases.

Otherwise, if execution reaches the end of our function, we return the default
value for its return kind: for example, the empty text for |K_text|.

@<Compile a terminal return statement@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
	kind *K = Frames::get_kind_returned();
	if (K) {
		if (RTKinds::emit_default_value_as_val(K, EMPTY_WORDING,
			"value decided by this phrase") != TRUE) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DefaultDecideFails),
				"it's not possible to decide such a value",
				"so this can't be allowed.");
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		}
	} else {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0); /* that is, "false" */
	}
	Produce::up(Emit::tree());
