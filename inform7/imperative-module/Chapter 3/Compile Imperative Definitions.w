[CompileImperativeDefn::] Compile Imperative Definitions.

Compiling an Inter function from the body of an imperative definition.

@h Compilation.
This is a short section, but the function //CompileImperativeDefn::go// sits
at the top of a mountain of code occupying most of the rest of this module.
That's a function called either from //Phrase Requests// or from here:

=
void CompileImperativeDefn::not_from_phrase(id_body *idb, int *i, int max_i,
	shared_variable_access_list *legible, rule *R) {
	if (idb->compilation_data.at_least_one_compiled_form_needed) {
		CompileImperativeDefn::go(idb, legible, NULL, R);
		CompileImperativeDefn::advance_progress_bar(idb, i, max_i);
		idb->compilation_data.at_least_one_compiled_form_needed = FALSE;
	}
}

void CompileImperativeDefn::advance_progress_bar(id_body *idb, int *i, int max_i) {
	if (idb->compilation_data.at_least_one_compiled_form_needed) {
		(*i)++;
		ProgressBar::update(4, ((float) (*i))/((float) max_i));
	}
}

@ Either way, all compilations of non-inline imperative bodies come through here:

=
void CompileImperativeDefn::go(id_body *idb, shared_variable_access_list *legible,
	to_phrase_request *req, rule *R) {
	parse_node *code_at = ImperativeDefinitions::body_at(idb);
	if (Node::is(code_at->next, DEFN_CONT_NT)) code_at = code_at->next;

	LOGIF(PHRASE_COMPILATION, "Compiling phrase:\n$T", code_at);

	current_sentence = code_at;
	stack_frame *frame = &(idb->compilation_data.id_stack_frame);
	inter_name *iname = req?(req->req_iname):(CompileImperativeDefn::iname(idb));
	inter_name *md_iname = req?(req->md_iname):NULL;

	@<Set up the stack frame for this compilation request@>;
	
	packaging_state save = Functions::begin_from_idb(iname, frame, idb);
	@<Compile some commentary about the function to follow@>;
	@<Compile the body of the function@>;
	Functions::end(save);

	if (md_iname) {
		TEMPORARY_TEXT(syn)
		WRITE_TO(syn, "%W", idb->head_of_defn->log_text);
		Emit::text_constant(md_iname, syn);
		DISCARD_TEXT(syn)
	}
	current_sentence = NULL;
}

@<Compile some commentary about the function to follow@> =
	if (req == NULL) {
		EmitCode::comment(I"No specific request");
	} else {
		TEMPORARY_TEXT(C)
		WRITE_TO(C, "Request %d: ", req->allocation_id);
		Kinds::Textual::write(C, PhraseRequests::kind_of_request(req));
		EmitCode::comment(C);
		DISCARD_TEXT(C)
	}
	ImperativeDefinitions::write_comment_describing(idb->head_of_defn);

@<Set up the stack frame for this compilation request@> =
	id_type_data *idtd = &(idb->type_data);

	kind *version_kind = NULL;
	if (req) version_kind = PhraseRequests::kind_of_request(req);
	else version_kind = IDTypeData::kind(idtd);
	CompileImperativeDefn::set_up_stack_frame_for_compilation(frame, idtd, version_kind, FALSE);

	if (req) Frames::set_kind_variables(frame,
		PhraseRequests::kind_variables_for_request(req));
	else Frames::set_kind_variables(frame, NULL);

	Frames::set_shared_variable_access_list(frame, legible);

	LocalVariableSlates::deallocate_all(frame); /* in case any are left from an earlier compile */
	PreformCache::warn_of_changes(); /* that local variables may have changed */

@<Compile the body of the function@> =
	current_sentence = code_at;
	if (RTRules::compile_test_head(idb, R) == FALSE) {
		if (code_at) {
			VerifyTree::verify_structure_from(code_at);
			CompileBlocksAndLines::full_definition_body(1, code_at->down, TRUE);
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
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
	kind *K = Frames::get_kind_returned();
	if (K) {
		if (DefaultValues::val(K, EMPTY_WORDING,
			"value decided by this phrase") != TRUE) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DefaultDecideFails),
				"it's not possible to decide such a value",
				"so this can't be allowed.");
			EmitCode::val_number(0);
		}
	} else {
		EmitCode::val_number(0); /* that is, "false" */
	}
	EmitCode::up();

@h Data about compilation.
Each imperative definition body has the following data attached to it. 

=
typedef struct id_compilation_data {
	struct stack_frame id_stack_frame;
	int at_least_one_compiled_form_needed; /* do we still need to compile this? */

	/* for inline definitions only: */
	int inline_mor; /* inline manner of return */
	int inline_wn; /* word number of inline definition, or |-1| if not inline */
	struct inter_schema *inline_front_schema; /* inline definition translated to inter, if possible */
	struct inter_schema *inline_back_schema; /* inline definition translated to inter, if possible */
	int inter_defn_converted; /* has this been tried yet? */

	/* for non-inline definitions only: */
	struct package_request *requests_package;
	struct linked_list *label_namespaces; /* of |label_namespace| */
	int compile_with_run_time_debugging; /* in the RULES command */
	struct inter_name *ph_iname; /* or NULL for inline phrases */
} id_compilation_data;

@ =
id_compilation_data CompileImperativeDefn::new_data(parse_node *p) {
	id_compilation_data phcd;
	phcd.id_stack_frame = Frames::new();
	phcd.at_least_one_compiled_form_needed = TRUE;

	phcd.inline_wn = -1;
	phcd.inline_front_schema = NULL;
	phcd.inline_back_schema = NULL;
	phcd.inter_defn_converted = FALSE;
	phcd.inline_mor = DONT_KNOW_MOR;

	phcd.ph_iname = NULL;
	phcd.label_namespaces = NEW_LINKED_LIST(label_namespace);
	phcd.requests_package = NULL;
	phcd.compile_with_run_time_debugging = FALSE;
	return phcd;
}

@ An iname can, for convenience, be attached. For "To..." phrases, no iname
is attached; it will be different in each different instantiation of the
definition. But for rules and adjective definitions, this is useful:

=
void CompileImperativeDefn::set_iname(id_body *idb, inter_name *iname) {
	idb->compilation_data.ph_iname = iname;
}

inter_name *CompileImperativeDefn::iname(id_body *idb) {
	return idb->compilation_data.ph_iname;
}

@ Definition bodies with an inline definition use these functions, and are
never run through //CompileImperativeDefn::go// at all:

=
int CompileImperativeDefn::is_inline(id_body *idb) {
	if (idb->compilation_data.inline_wn < 0) return FALSE;
	return TRUE;
}

void CompileImperativeDefn::make_inline(id_body *idb, int inline_wn, int mor) {
	idb->compilation_data.inline_wn = inline_wn;
	idb->compilation_data.inline_mor = mor;
	idb->compilation_data.at_least_one_compiled_form_needed = FALSE;
}

wchar_t *CompileImperativeDefn::get_inline_definition(id_body *idb) {
	if (idb->compilation_data.inline_wn < 0)
		internal_error("tried to access inline definition of non-inline phrase");
	return Lexer::word_text(idb->compilation_data.inline_wn);
}

inter_schema *CompileImperativeDefn::get_front_schema(id_body *idb) {
	@<Construct the schemas from the inline text if this has not yet been done@>;
	return idb->compilation_data.inline_front_schema;
}

inter_schema *CompileImperativeDefn::get_back_schema(id_body *idb) {
 	@<Construct the schemas from the inline text if this has not yet been done@>;
 	return idb->compilation_data.inline_back_schema;
}

@<Construct the schemas from the inline text if this has not yet been done@> =
	if (idb->compilation_data.inter_defn_converted == FALSE) {
		if (idb->compilation_data.inline_wn >= 0) {
			ParsingSchemas::from_inline_phrase_definition(
				CompileImperativeDefn::get_inline_definition(idb),
				&(idb->compilation_data.inline_front_schema),
				&(idb->compilation_data.inline_back_schema),
				Provenance::nowhere());
			CompileImperativeDefn::issue_schema_errors(current_sentence,
				idb->compilation_data.inline_front_schema,
				idb->compilation_data.inline_back_schema);
		}
		idb->compilation_data.inter_defn_converted = TRUE;
	}

@ =
void CompileImperativeDefn::issue_schema_errors(parse_node *from,
	inter_schema *sch1, inter_schema *sch2) {
	int E = LinkedLists::len(sch1->parsing_errors);
	if (sch2) E += LinkedLists::len(sch2->parsing_errors);
	if (E > 0) {
		Problems::quote_source(1, from);
		Problems::quote_stream(4, sch1->converted_from);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_InlineSchemaErrors));
		Problems::issue_problem_segment(
			"In %1, syntax error(s) were found in the '(-' ... '-)' schema '%4':");
		schema_parsing_error *err;
		int ec = 1;
		if ((sch1) && (sch1->parsing_errors))
			LOOP_OVER_LINKED_LIST(err, schema_parsing_error, sch1->parsing_errors) {
				Problems::quote_number(2, &ec);
				Problems::quote_stream(3, err->message);
				Problems::issue_problem_segment("%P (%2). %3");
				ec++;
			}
		if ((sch2) && (sch2->parsing_errors))
			LOOP_OVER_LINKED_LIST(err, schema_parsing_error, sch2->parsing_errors) {
				Problems::quote_number(2, &ec);
				Problems::quote_stream(3, err->message);
				Problems::issue_problem_segment("%P (%2). %3");
				ec++;
			}
		Problems::issue_problem_end();
	}
}

@ Non-inline compilation is sometimes the result of filling requests for
instantiation. The different requested versions then appear in the requests
package for the function:

=
void CompileImperativeDefn::prepare_for_requests(id_body *idb) {
	idb->compilation_data.requests_package =
		Hierarchy::local_package_to(PHRASES_HAP, idb->head_of_defn->at);
}
package_request *CompileImperativeDefn::requests_package(id_body *idb) {
	return idb->compilation_data.requests_package;
}

@h Preparing the stack frame.
The stack frame needs to be made ready for compilation. The following
is called immediately the |body| is created.

=
void CompileImperativeDefn::initialise_stack_frame(id_body *body) {
	stack_frame *frame = &(body->compilation_data.id_stack_frame);
	CompileImperativeDefn::set_up_stack_frame_for_compilation(frame, &(body->type_data),
		IDTypeData::kind(&(body->type_data)), TRUE);
	if (PhraseOptions::allows_options(body))
		LocalVariables::options_parameter_is_needed(frame);
}

@ However, //CompileImperativeDefn::set_up_stack_frame_for_compilation// is also
called each time the definition is compiled: note that if a definition is being
instantiated for multiple different kinds, |kind_in_this_compilation| will
vary, and will not be the same as the one supplied in
//CompileImperativeDefn::initialise_stack_frame//.

=
void CompileImperativeDefn::set_up_stack_frame_for_compilation(stack_frame *frame,
	id_type_data *idtd, kind *kind_in_this_compilation, int first) {
	if (Kinds::get_construct(kind_in_this_compilation) != CON_phrase)
		internal_error("not a function kind");

	kind *args = NULL, *ret = NULL;
	Kinds::binary_construction_material(kind_in_this_compilation, &args, &ret);

	int N = IDTypeData::get_no_tokens(idtd);
	for (int i=0; i<N; i++) {
		if (Kinds::get_construct(args) != CON_TUPLE_ENTRY) internal_error("bad tupling");
		kind *K;
		Kinds::binary_construction_material(args, &K, &args);
		if (first) {
			LocalVariables::new_call_parameter(frame, idtd->token_sequence[i].token_name, K);
		} else {
			local_variable *lvar = LocalVariables::get_ith_parameter(frame, i);
			if (lvar) LocalVariables::set_kind(lvar, K);
		}
	}

	if (Kinds::eq(ret, K_nil)) Frames::set_kind_returned(frame, NULL);
	else Frames::set_kind_returned(frame, ret);
}
