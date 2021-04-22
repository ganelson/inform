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
	packaging_state save = EmitArrays::begin(at, K_value);
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
	int ts_value_iname_used;
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
While the function is always compiled, the small block is only compiled if
the value iname is ever actually requested. (Sometimes when making alternative
responses we just want to make the function.)

=
inter_name *TextSubstitutions::value_iname(text_substitution *ts) {
	ts->ts_value_iname_used = TRUE;
	return ts->ts_value_iname;
}

inter_name *TextSubstitutions::function_iname(text_substitution *ts) {
	return ts->ts_function_iname;
}

@ 

=
text_substitution *TextSubstitutions::new_text_substitution(wording W,
	stack_frame *frame, rule *R, int marker) {

	text_substitution *ts = CREATE(text_substitution);
	if (Sequence::function_resources_allowed() == FALSE)
		internal_error("Too late for further text substitutions");
	ts->unsubstituted_text = Wordings::first_word(W);
	ts->sentence_using_this = current_sentence;
	if (R) {
		ts->using_frame = NULL;
	} else {
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
	ts->ts_value_iname_used = FALSE;
	ts->ts_function_iname = Hierarchy::make_iname_in(TEXT_SUBSTITUTION_FN_HL, PR);

	ts->owning_point = current_sentence;
	id_body *idb = Functions::defn_being_compiled();
	if (idb) ts->owning_point = idb->head_of_defn->at;
	LOGIF(TEXT_SUBSTITUTIONS, "Requesting text routine %d %08x %W %08x\n",
		ts->allocation_id, (int) frame, W, R);
	return ts;
}

@h Compilation.

=
int TextSubstitutions::compilation_coroutine(void) {
	return TextSubstitutions::compile_as_needed(FALSE);
}

text_substitution *latest_ts_compiled = NULL;
int compiling_text_routines_mode = FALSE; /* used for better problem messages */
int TextSubstitutions::compile_as_needed(int in_response_mode) {
	Responses::compile_response_launchers();
	int N = 0;
	compiling_text_routines_mode = TRUE;
	while (TRUE) {
		text_substitution *ts;
		if (latest_ts_compiled == NULL) ts = FIRST_OBJECT(text_substitution);
		else ts = NEXT_OBJECT(latest_ts_compiled, text_substitution);
		if (ts == NULL) break;
		latest_ts_compiled = ts;
		int responding = FALSE;
		if (ts->responding_to_rule) responding = TRUE;
		if ((responding == in_response_mode) && (ts->tr_done_already == FALSE)) {
			ts->tr_done_already = TRUE;
			int makes_local_refs = TextSubstitutions::compile_function(ts);
			if (ts->ts_value_iname_used)
				TextSubstitutions::compile_value(ts->ts_value_iname, ts->ts_function_iname, makes_local_refs);
		}
		N++;
	}

	compiling_text_routines_mode = FALSE;
	return N;
}

int TextSubstitutions::currently_compiling(void) {
	return compiling_text_routines_mode;
}

@ We can now forget about the coroutine management, and just compile a single
text substitution. The main thing is to copy over references to local variables
from the stack frame creating this text substitution to the stack frame
compiling it.

=
text_substitution *current_ts_being_compiled = NULL;
int TextSubstitutions::compile_function(text_substitution *ts) {
	LOGIF(TEXT_SUBSTITUTIONS, "Compiling text routine %d %08x %W\n",
		ts->allocation_id, (int) (ts->using_frame), ts->unsubstituted_text);

	current_ts_being_compiled = ts;
	packaging_state save = Functions::begin(ts->ts_function_iname);
	stack_frame *frame = ts->using_frame;
	if ((ts->responding_to_rule) && (ts->responding_to_marker >= 0)) {
		response_message *resp = Rules::get_response(
			ts->responding_to_rule, ts->responding_to_marker);
		if (resp) frame = Responses::frame_for_response(resp);
	}
	if (frame) LocalVariableSlates::append(Frames::current_stack_frame(), frame);
	LocalVariables::monitor_local_parsing(Frames::current_stack_frame());

	@<Compile a say-phrase@>;

	int makes_local_references =
		LocalVariables::local_parsed_recently(Frames::current_stack_frame());
	if (makes_local_references) {
		Produce::push_code_position(Emit::tree(), Produce::begin_position(Emit::tree()), Inter::Bookmarks::snapshot(Emit::at()));
		LocalParking::retrieve(frame);
		Produce::pop_code_position(Emit::tree());
	}
	Functions::end(save);
	current_ts_being_compiled = NULL;
	return makes_local_references;
}

@ Of course, if we used Inform's standard phrase mechanism exactly, then
the whole thing would be circular, because that would once again generate
a request for a new text substitution to be compiled later...

@<Compile a say-phrase@> =
	if (TargetVMs::debug_enabled(Task::vm())) {
		EmitCode::inv(IFDEBUG_BIP);
		EmitCode::down();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_number, Hierarchy::find(SUPPRESS_TEXT_SUBSTITUTION_HL));
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

	parse_node *ts_code_block = Node::new(IMPERATIVE_NT);
	CompilationUnits::assign_to_same_unit(ts_code_block, ts->owning_point);
	ts_code_block->next = Node::new(UNKNOWN_NT);
	Node::set_text(ts_code_block->next, ts->unsubstituted_text);
	Annotations::write_int(ts_code_block->next, from_text_substitution_ANNOT, TRUE);
	ImperativeSubtrees::accept(ts_code_block);

	CompileBlocksAndLines::full_definition_body(0, ts_code_block->down, FALSE);

	EmitCode::rtrue();

@ See the "Responses" section for why, but we sometimes want to force
the coroutine to go through the whole queue once, then go back to the
start again -- which would be very inefficient except that in this mode
we aren't doing very much; most TSs will be passed quickly over.

=
void TextSubstitutions::compile_text_routines_in_response_mode(void) {
	latest_ts_compiled = NULL;
	TextSubstitutions::compile_as_needed(TRUE);
	latest_ts_compiled = NULL;
}

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
