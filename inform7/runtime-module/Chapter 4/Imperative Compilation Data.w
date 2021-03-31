[IDCompilation::] Imperative Compilation Data.

Looking after imperative definitions.

@ Each 

As noted in the introduction to this chapter, a |phrase| structure is
created for each "To..." definition and each rule in the source text. It is
divided internally into five substructures, the IDTD, PHUD, PHRCD, PHSF
and PHOD.

@ And here is the structure. Note that the MOR and EFF are stored inside
the sub-structures, and aren't visible here; but they're relevant to the
code below.

=
typedef struct id_compilation_data {
	int inline_mor; /* one of the |*_MOR| values above */
	int inline_wn; /* word number of inline I6 definition, or |-1| if not inline */
	int compile_with_run_time_debugging; /* in the RULES command */
	int at_least_one_compiled_form_needed; /* do we still need to compile this? */
	struct compilation_unit *owning_module;
	struct inter_schema *inter_front; /* inline definition translated to inter, if possible */
	struct inter_schema *inter_back; /* inline definition translated to inter, if possible */
	int inter_defn_converted; /* has this been tried yet? */
	struct inter_name *ph_iname; /* or NULL for inline phrases */
	struct package_request *requests_package;
	struct ph_stack_frame stack_frame;
	int permit_all_outcomes; /* waive the usual restrictions on rule outcomes */
} id_compilation_data;

@

=
id_compilation_data IDCompilation::new_data(parse_node *p) {
	id_compilation_data phcd;
	phcd.inline_wn = -1;
	phcd.inter_front = NULL;
	phcd.inter_back = NULL;
	phcd.inter_defn_converted = FALSE;
	phcd.inline_mor = DONT_KNOW_MOR;
	phcd.ph_iname = NULL;
	phcd.owning_module = CompilationUnits::find(p);
	phcd.requests_package = NULL;
	phcd.at_least_one_compiled_form_needed = TRUE;
	phcd.compile_with_run_time_debugging = FALSE;
	phcd.stack_frame = Frames::new();
	phcd.permit_all_outcomes = FALSE;
	return phcd;
}

void IDCompilation::make_inline(id_body *idb, int inline_wn, int mor) {
	idb->compilation_data.inline_wn = inline_wn;
	idb->compilation_data.inline_mor = mor;
	idb->compilation_data.at_least_one_compiled_form_needed = FALSE;
}

@

=
void IDCompilation::prepare_stack_frame(id_body *body) {
	IDCompilation::initialise_stack_frame_from_type_data(
		&(body->compilation_data.stack_frame), &(body->type_data),
		IDTypeData::kind(&(body->type_data)), TRUE);
	if (PhraseOptions::allows_options(body))
		LocalVariables::options_parameter_is_needed(&(body->compilation_data.stack_frame));
}

@ Suppose Inform is compiling code to represent this:

>> To sort (T - table name) in (TC - table column) order: ...

On the stack frame for this code, "T" and "TC" will need to be local
variables -- that is, they will need to be locally available as names,
referring to the values which the phrase was called with.

In that simple example, the phrase preamble makes clear what the kinds of
"T" and "TC" should be, but it isn't always so simple. For example:

>> To add (new entry - K) to (L - list of values of kind K): ...

Here the preamble allows a wide range of kinds, and Inform compiles
different versions of the code for each value of K actually needed. So
the following routine is called with a particular kind to be used. For
instance, if the source text ever contains an invocation like:

>> add 14 to the list of scores;

then at some point Inform will have to compile a version of the phrase
which has the kind:
= (text)
	phrase (number, list of numbers) -> nothing
=
The routine below then dismantles that kind to extract the kinds of the
arguments, "number" and then "list of numbers", and creates local
variables "new entry" and "L" with those kinds.

=
void IDCompilation::initialise_stack_frame_from_type_data(ph_stack_frame *phsf,
	id_type_data *idtd, kind *kind_in_this_compilation, int first) {
	if (Kinds::get_construct(kind_in_this_compilation) != CON_phrase)
		internal_error("no function kind");

	kind *args = NULL, *ret = NULL;
	Kinds::binary_construction_material(kind_in_this_compilation, &args, &ret);

	int N = IDTypeData::get_no_tokens(idtd);
	for (int i=0; i<N; i++) {
		kind *K;
		if (Kinds::get_construct(args) != CON_TUPLE_ENTRY) internal_error("bad tupling");
		Kinds::binary_construction_material(args, &K, &args);
		if (first) {
			LocalVariables::add_call_parameter(phsf, idtd->token_sequence[i].token_name, K);
		} else {
			local_variable *lvar = LocalVariables::get_ith_parameter(i);
			if (lvar) LocalVariables::set_kind(lvar, K);
		}
	}

	if (Kinds::eq(ret, K_nil)) Frames::set_kind_returned(phsf, NULL);
	else Frames::set_kind_returned(phsf, ret);
}

@ Some access functions:

=
int IDCompilation::compiled_inline(id_body *idb) {
	if (idb->compilation_data.inline_wn < 0) return FALSE;
	return TRUE;
}

wchar_t *IDCompilation::get_inline_definition(id_body *idb) {
	if (idb->compilation_data.inline_wn < 0)
		internal_error("tried to access inline definition of non-inline phrase");
	return Lexer::word_text(idb->compilation_data.inline_wn);
}

inter_schema *IDCompilation::get_inter_front(id_body *idb) {
	if (idb->compilation_data.inter_defn_converted == FALSE) {
		if (idb->compilation_data.inline_wn >= 0) {
			InterSchemas::from_inline_phrase_definition(IDCompilation::get_inline_definition(idb), &(idb->compilation_data.inter_front), &(idb->compilation_data.inter_back));
		}
		idb->compilation_data.inter_defn_converted = TRUE;
	}
	return idb->compilation_data.inter_front;
}

inter_schema *IDCompilation::get_inter_back(id_body *idb) {
	if (idb->compilation_data.inter_defn_converted == FALSE) {
		if (idb->compilation_data.inline_wn >= 0) {
			InterSchemas::from_inline_phrase_definition(IDCompilation::get_inline_definition(idb), &(idb->compilation_data.inter_front), &(idb->compilation_data.inter_back));
		}
		idb->compilation_data.inter_defn_converted = TRUE;
	}
	return idb->compilation_data.inter_back;
}

inter_name *IDCompilation::iname(id_body *idb) {
	if (idb->compilation_data.ph_iname == NULL) {
		package_request *PR = Hierarchy::package(idb->compilation_data.owning_module, ADJECTIVE_PHRASES_HAP);
		idb->compilation_data.ph_iname = Hierarchy::make_iname_in(DEFINITION_FN_HL, PR);
	}
	return idb->compilation_data.ph_iname;
}

@h Compilation.
The following is called to give us an opportunity to compile a routine defining
a phrase. As was mentioned in the introduction, "To..." phrases are sometimes
compiled multiple times, for different kinds of tokens, and are compiled in
response to "requests". All other phrases are compiled just once.

=
void IDCompilation::compile(id_body *idb, int *i, int max_i,
	stacked_variable_access_list *legible, to_phrase_request *req, rule *R) {
	if ((req) || (idb->compilation_data.at_least_one_compiled_form_needed)) {
		Routines::Compile::routine(idb, legible, req, R);
		if (idb->compilation_data.at_least_one_compiled_form_needed) {
			idb->compilation_data.at_least_one_compiled_form_needed = FALSE;
			(*i)++;
			ProgressBar::update(4, ((float) (*i))/((float) max_i));
		}
	}
}

@ This is to do with named outcomes of rules, whereby certain outcomes are
normally limited to the use of rules in particular rulebooks.

=
int IDCompilation::outcome_restrictions_waived(void) {
	if ((id_body_being_compiled) &&
		(id_body_being_compiled->compilation_data.permit_all_outcomes))
		return TRUE;
	return FALSE;
}
