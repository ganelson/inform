[TextSubstitutions::] Text Substitutions.

In this section we compile text with substitutions.

@h Runtime representation.
Text substitutions arise from source text such as:
= (text as Inform 7)
	let Q be "the [fox speed] brown fox";
	say "Where has that [sleeping animal] got to?";
=
These both look like text substitutions, but only |the [fox speed] brown fox|
actually is one: |say| phrases are compiled directly, like so:
= (text as Inform 7)
	let Q be "the [fox speed] brown fox";
	say "Where has that ";
	say sleeping animal;
	say " got to?";
=
So we are concerned only with substitutions used as values. At run-time, these
are essentially the same as //Text Literals//, but where the content field in
the small block is a function pointer:
= (text)
	                    small block:
	Q ----------------> CONSTANT_PACKED_TEXT_STORAGE or CONSTANT_PERISHABLE_TEXT_STORAGE
	                    function
=
It is worth emphasising that this is a function. In an interpreted language
like Perl, an interpolation such as |"Deleted $file_count files"| is immediately
converted to text when it is executed; and even in some compiled languages
like Swift, the same is essentially true -- in that the text is compiled to
code which immediately produces the expanded version.

In Inform, however, a text substitution is instead compiled to a function which
can at some later time perform that expansion. This means it is, in effect, a
form of closure, and has to retain some memory of the environment in which it
came up. Consider for example:
= (text as Inform 7)
	let X be 17;
	write "remember [X]" to the file of Memos;
=
This is a context where it's clear what it means to refer to the local variable
|X| in the text. But this is less clear:
= (text as Inform 7)
	let the cage be a random container in the Discount Cage Warehouse;
	decide on "As bad as [a cage].";
=
The trouble is that |decide on| causes a return out of the current stack frame;
at which point the local variable |cage| will cease to exist, and it will then
not be possible to expand |"As bad as [a cage]."|. If we were pursuing closures
more seriously, we would have to capture |cage|, and then worry about garbage
collection.

Instead we call a substitution like this "perishable", and in cases of doubt
we expand this on the spot, i.e., inside the original stack frame.

=
void TextSubstitutions::compile_value(inter_name *at, inter_name *fn,
	int makes_local_references) {
	packaging_state save = EmitArrays::begin_unchecked(at);
	if (makes_local_references)
		EmitArrays::iname_entry(Hierarchy::find(CONSTANT_PERISHABLE_TEXT_STORAGE_HL));
	else
		EmitArrays::iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
	EmitArrays::iname_entry(fn);
	EmitArrays::end(save);
}

@h Cues.
The "cue" for a text substitution that is not a response is its original appearance:
like so:
= (text as Inform 7)
	let Q be "the [fox speed] brown fox";
=
When compiling this value, the following is called with |W| being the single-word
wording |"the [fox speed] brown fox"|.

=
void TextSubstitutions::text_substitution_cue(value_holster *VH, wording W) {
	text_substitution *ts = NULL;
	switch (VH->vhmode_wanted) {
		case INTER_VAL_VHMODE: @<Cue in value context@>; break;
		case INTER_DATA_VHMODE: @<Cue in data context@>; break;
		default: internal_error("cue in void context");
	}
}

@ The function call to TEXT_TY_EXPANDIFPERISHABLE_HL is unnecessary in the
case of a response to a rule, since those are never perishable.

@<Cue in value context@> =
	stack_frame *frame = NULL;
	if (rule_to_which_this_is_a_response) {
		@<Make the TS@>;
		inter_name *tin = TextSubstitutions::value_iname(ts);
		EmitCode::val_iname(K_value, tin);
	} else {
		if (frame == NULL) frame = Frames::current_stack_frame();
		int downs = LocalParking::park(frame);
		frame = Frames::boxed_frame(frame);
		@<Make the TS@>;
		inter_name *tin = TextSubstitutions::value_iname(ts);
		EmitCode::call(Hierarchy::find(TEXT_TY_EXPANDIFPERISHABLE_HL));
		EmitCode::down();
			Frames::emit_new_local_value(K_text);
			EmitCode::val_iname(K_value, tin);
		EmitCode::up();
		while (downs > 0) { EmitCode::up(); downs--; }
	}

@<Cue in data context@> =
	stack_frame *frame = NULL;
	@<Make the TS@>;
	inter_name *tin = TextSubstitutions::value_iname(ts);
	Emit::holster_iname(VH, tin);

@<Make the TS@> =
	ts = TextSubstitutions::new_text_substitution(W, frame,
		rule_to_which_this_is_a_response, response_marker_within_that_rule);

@h Substitutions.
Each substitution creates an object like so:

=
typedef struct text_substitution {
	struct wording unsubstituted_text; /* including the substitutions in squares */
	int tr_done_already; /* has been compiled */
	struct parse_node *sentence_using_this; /* where this occurs in source */
	struct parse_node *owning_point; /* shows which compilation unit this belongs to */
	int local_names_existed_at_usage_time; /* remember in case of problems */
	struct stack_frame *using_frame; /* for cases where possible */

	struct inter_name *ts_value_iname; /* the I6 array for this */
	struct inter_name *ts_function_iname; /* the routine to implement it */

	struct rule *responding_to_rule;
	int responding_to_marker;

	CLASS_DEFINITION
} text_substitution;

@ Two inames are involved here:
= (text)
	                        small block:
	value ----------------> CONSTANT_PACKED_TEXT_STORAGE or CONSTANT_PERISHABLE_TEXT_STORAGE
	                        function ----------------------> ...
=

=
inter_name *TextSubstitutions::value_iname(text_substitution *ts) {
	return ts->ts_value_iname;
}

inter_name *TextSubstitutions::function_iname(text_substitution *ts) {
	return ts->ts_function_iname;
}

@ Note that this function is called both when cues are detected (above), and
also when responses are created -- see //Responses//.

=
text_substitution *TextSubstitutions::new_text_substitution(wording W,
	stack_frame *frame, rule *R, int marker) {

	text_substitution *ts = CREATE(text_substitution);
	ts->unsubstituted_text = Wordings::first_word(W);
	ts->sentence_using_this = current_sentence;
	ts->using_frame = NULL;
	if (R == NULL) {
		stack_frame new_frame = Frames::new();
		ts->using_frame = Frames::boxed_frame(&new_frame);
		if (frame) LocalVariableSlates::append(ts->using_frame, frame);
	}
	ts->responding_to_rule = R;
	ts->responding_to_marker = marker;
	ts->tr_done_already = FALSE;

	ts->local_names_existed_at_usage_time = FALSE;
	if ((Functions::defn_being_compiled()) &&
		(LocalVariableSlates::size(Frames::current_stack_frame()) > 0))
		ts->local_names_existed_at_usage_time = TRUE;

	package_request *P = Emit::current_enclosure();
	if (R) P = RTRules::package(R);
	package_request *PR = Hierarchy::package_within(LITERALS_HAP, P);
	ts->ts_value_iname = Hierarchy::make_iname_in(TEXT_SUBSTITUTION_HL, PR);
	ts->ts_function_iname = Hierarchy::make_iname_in(TEXT_SUBSTITUTION_FN_HL, PR);

	ts->owning_point = current_sentence;
	id_body *idb = Functions::defn_being_compiled();
	if (idb) ts->owning_point = idb->head_of_defn->at;

	text_stream *desc = Str::new();
	WRITE_TO(desc, "text substitution '%W'", W);
	Sequence::queue(&TextSubstitutions::compilation_agent,
		STORE_POINTER_text_substitution(ts), desc);

	LOGIF(TEXT_SUBSTITUTIONS, "Requesting text routine %d for %W, R = %d\n",
		ts->allocation_id, W, (R)?(R->allocation_id):(-1));
	return ts;
}

@h Compilation.
Functions for substitutions are then compiled in due course by the following agent
(see //core: How To Compile//):

=
int compiling_text_routines_mode = FALSE; /* used for better problem messages */
void TextSubstitutions::compilation_agent(compilation_subtask *t) {
	text_substitution *ts = RETRIEVE_POINTER_text_substitution(t->data);
	int save = compiling_text_routines_mode;
	compiling_text_routines_mode = TRUE;
	int makes_local_refs = TextSubstitutions::compile_function(ts);
	TextSubstitutions::compile_value(ts->ts_value_iname,
		ts->ts_function_iname, makes_local_refs);
	compiling_text_routines_mode = save;
}

int TextSubstitutions::currently_compiling(void) {
	return compiling_text_routines_mode;
}

@ The main thing is to copy over references to local variables from the stack
frame creating this text substitution to the stack frame compiling it.

=
text_substitution *current_ts_being_compiled = NULL;
int TextSubstitutions::compile_function(text_substitution *ts) {
	LOGIF(TEXT_SUBSTITUTIONS, "Compiling text routine %d %W\n", ts->allocation_id,
		ts->unsubstituted_text);

	current_ts_being_compiled = ts;
	packaging_state save = Functions::begin(ts->ts_function_iname);
	stack_frame *frame = NULL;
	@<Give the function access to shared variables visible to its user@>;

	LocalVariables::monitor_local_parsing(Frames::current_stack_frame());
	@<Compile some debugging text@>;
	@<Compile a say-phrase@>;
	int makes_local_references =
		LocalVariables::local_parsed_recently(Frames::current_stack_frame());
	if (makes_local_references) @<Insert code at start of function to retrieve parked values@>;

	Functions::end(save);
	current_ts_being_compiled = NULL;
	return makes_local_references;
}

@<Give the function access to shared variables visible to its user@> =
	frame = Responses::frame_for_response(ts->responding_to_rule, ts->responding_to_marker);
	if (frame == NULL) frame = ts->using_frame;
	if (frame) LocalVariableSlates::append(Frames::current_stack_frame(), frame);

@ In DEBUG mode, there's an option to print the unsubstituted text instead --
note the |rtrue| here, which stops the function from proceeding.

@<Compile some debugging text@> =
	if (TargetVMs::debug_enabled(Task::vm())) {
		EmitCode::inv(IFDEBUG_BIP);
		EmitCode::down();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_number,
						Hierarchy::find(SUPPRESS_TEXT_SUBSTITUTION_HL));
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(PRINT_BIP);
						EmitCode::down();
							TEMPORARY_TEXT(S)
							WRITE_TO(S, "%W", ts->unsubstituted_text);
							EmitCode::val_text(S);
							DISCARD_TEXT(S)
						EmitCode::up();
						EmitCode::rtrue();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}

@ Of course, if we used Inform's standard phrase mechanism exactly, then
the whole thing would be circular, because that would once again generate
a request for a new text substitution to be compiled later...

@<Compile a say-phrase@> =
	parse_node *ts_code_block = Node::new(IMPERATIVE_NT);
	CompilationUnits::assign_to_same_unit(ts_code_block, ts->owning_point);
	ts_code_block->next = Node::new(UNKNOWN_NT);
	Node::set_text(ts_code_block->next, ts->unsubstituted_text);
	Annotations::write_int(ts_code_block->next, from_text_substitution_ANNOT, TRUE);
	ImperativeSubtrees::accept(ts_code_block);

	CompileBlocksAndLines::full_definition_body(0, ts_code_block->down, FALSE);

	EmitCode::rtrue();

@ Where a text substitution refers to local variables in the caller,
//imperative: Local Parking// is used to pass it the current values of those
locals; and this means that the function must begin by retrieving those values.
But since we have already compiled most of the function, we have to go back to
the start temporarily to insert this extra code.

@<Insert code at start of function to retrieve parked values@> =
	Produce::push_new_code_position(Emit::tree(),
		Produce::function_body_start_bookmark(Emit::tree()));
	LocalParking::retrieve(frame);
	Produce::pop_code_position(Emit::tree());

@h It may be worth adding.
Finally, the following clarifies problem messages arising from the issue of
local names being used in substitutions, since this often confuses newcomers:

@d ENDING_MESSAGE_PROBLEMS_CALLBACK TextSubstitutions::append_text_substitution_proviso

=
int it_is_not_worth_adding = FALSE; /* To suppress the "It may be worth adding..." */

int TextSubstitutions::is_it_worth_adding(void) {
	return it_is_not_worth_adding;
}
void TextSubstitutions::it_is_worth_adding(void) {
	it_is_not_worth_adding = FALSE;
}
void TextSubstitutions::it_is_not_worth_adding(void) {
	it_is_not_worth_adding = TRUE;
}

@ =
void TextSubstitutions::append_text_substitution_proviso(void) {
	if (it_is_not_worth_adding) return;
	if (compiling_text_routines_mode == FALSE) return;
	if ((current_ts_being_compiled) &&
		(current_ts_being_compiled->local_names_existed_at_usage_time)) {
		Frames::log(Frames::current_stack_frame());
		Problems::quote_wording(9, current_ts_being_compiled->unsubstituted_text);
		Problems::issue_problem_segment(
			" %PIt may be worth adding that this problem arose in text "
			"which both contains substitutions and is also being used as "
			"a value - being put into a variable, or used as one of the "
			"ingredients in a phrase other than 'say'. Because that means "
			"it needs to be used in places outside its immediate context, "
			"it is not allowed to refer to any 'let' values or phrase "
			"options - those are temporary things, long gone by the time it "
			"would need to be printed.");
	}
}
