[Responses::] Responses.

In this section we keep track of response texts.

@h Introduction.
Responses are texts -- which may be either literals or text substitutions --
occurring inside the body of rules, and marked out (A), (B), (C), ... within
that rule. This enables them to be manipulated or changed. For example:
= (text as Inform 7)
Report an actor taking (this is the standard report taking rule):
	if the action is not silent:
		if the actor is the player:
			say "Taken." (A);
		otherwise:
			say "[The actor] [pick] up [the noun]." (B).
=
In effect there is a two-element array attached to this rule, one holding
the current response (A), the other (B). These are identified by an index called
the "marker", which counts from 0: so (A) is 0, (B) is 1.

Those original appearances inside the rule are called the "cues". The texts are
stored as //Text Substitutions//, even if, as in example (A) here, they do not
actually involve any substituting. (It's simpler to have a common format, and in
any case these are the exception.) All of the difficulties attendant on text
substitutions apply here, too. Note, for example, that (B) refers to the "actor",
a shared variable which is not normally visible from here:
= (text as Inform 7)
To grab is a verb.
When play begins:
	now the standard report taking rule response (B) is "[The actor] [grab] [the noun]."
=
Here, "actor" has to be read in the context of the standard report taking rule's
stack frame, not in the stack for the "when play begins" rule.

Each time a cue is found, a |response_message| object is created, as follows:

=
typedef struct response_message {
	struct rule *the_rule; /* to which this is a response */
	int the_marker; /* 0 for A, 1 for B, and so on up */
	struct text_substitution *the_ts;
	struct stack_frame *original_stack_frame;
	struct inter_name *value_iname;
	struct inter_name *constant_iname;
	struct inter_name *launcher_iname;
	int launcher_compiled;
	int via_Inter; /* if responding to a rule defined by Inter code, not source text */
	int via_Inter_routine_compiled;
	CLASS_DEFINITION
} response_message;

@ Note that each response has its own package, which is stored inside the package
of the rule to which it responds.

It occasionally happens that assertion sentences have changed the wording of a
response long before any code is compiled, and therefore before this call,
through a sentence like:
= (text as Inform 7)
The print empty inventory rule response (A) is "I got nothing."
=
This would cause |RW|, the replacement wording, below to be |"I got nothing."|.

=
response_message *Responses::response_cue(rule *R, int marker, wording W, stack_frame *frame) {
	response_message *resp = CREATE(response_message);
	resp->original_stack_frame = frame;
	resp->the_rule = R;
	resp->the_marker = marker;
	resp->launcher_compiled = FALSE;
	resp->via_Inter = FALSE;
	resp->via_Inter_routine_compiled = FALSE;

	package_request *PR = Hierarchy::package_within(RESPONSES_HAP, RTRules::package(R));
	resp->constant_iname = Hierarchy::make_iname_in(AS_CONSTANT_HL, PR);
	resp->value_iname = Hierarchy::make_iname_in(AS_BLOCK_CONSTANT_HL, PR);
	resp->launcher_iname = Hierarchy::make_iname_in(LAUNCHER_HL, PR);

	Rules::set_response(R, marker, resp);

	wording RW = Rules::get_response_replacement_wording(R, marker);
	if (Wordings::nonempty(RW)) W = RW;
	resp->the_ts = TextSubstitutions::new_text_substitution(W, frame, R, marker);
	TextSubstitutions::value_iname(resp->the_ts);

	return resp;
}

@ Some access functions:

=
inter_name *Responses::response_launcher_iname(response_message *resp) {
	return resp->value_iname;
}

inter_name *Responses::response_constant_iname(rule *R, int marker) {
	response_message *resp = Rules::get_response(R, marker);
	if (resp == NULL) return NULL;
	if (resp->constant_iname == NULL) internal_error("no response value");
	return resp->constant_iname;
}

stack_frame *Responses::frame_for_response(rule *R, int marker) {
	response_message *resp = Rules::get_response(R, marker);
	if (resp == NULL) return NULL;
	return resp->original_stack_frame;
}

@h How rules gain responses.
There are two ways a rule can get a new response. Firstly, and the way most
Inform authors do it:
= (text as Inform 7)
say "[The actor] [pick] up [the noun]." (B).
=
Will cause //Responses::set_via_source_text// to be called. This compiles Inter
code suitable for the response to be called (i.e., printed), setting up the cue
and attaching it to its rule in the process.

Note the use of //imperative: Local Parking// to stash local values before the
evaluation: and see //TextSubstitutions::compile_function// for where those are
retrieved.

=
void Responses::set_via_source_text(value_holster *VH, rule *R, int marker, wording SW) {
	stack_frame *frame = Frames::current_stack_frame();
	int downs = LocalParking::park(frame);
	response_message *resp =
		Responses::response_cue(R, marker, SW, Frames::boxed_frame(frame));
	EmitCode::val_iname(K_value, Responses::response_launcher_iname(resp));
	while (downs > 0) { EmitCode::up(); downs--; }
}

@ Secondly, a lower-level technique used by extensions to give responses even
to rules defined in Inter kits rather than by source text:
= (text as Inform 7)
The requested actions require persuasion rule translates into Inter as
	"REQUESTED_ACTIONS_REQUIRE_R" with
	 "[The noun] [have] better things to do." (A).
=
Which causes the following to be called:

=
void Responses::set_via_translation(rule *R, int marker, wording SW) {
	response_message *resp = Responses::response_cue(R, marker, SW, NULL);
	resp->via_Inter = TRUE;
}

@h Compilation.
Values and launchers for responses are then compiled in due course by the
following coroutine (see //core: How To Compile//):

=
int Responses::compilation_coroutine(void) {
	int N = 0;
	response_message *resp;
	LOOP_OVER(resp, response_message) {
		if (resp->launcher_compiled == FALSE) {
			resp->launcher_compiled = TRUE;
			N++;
			@<Compile resources needed by this response@>;
		}
		if ((resp->via_Inter) && (resp->via_Inter_routine_compiled == FALSE)) {
			response_message *r2;
			LOOP_OVER(r2, response_message)
				if (r2->the_rule == resp->the_rule)
					r2->via_Inter_routine_compiled = TRUE;
			N++;
			@<Compile the response-handler function for this rule@>;
		}
	}
	return N;
}

@ Each response compiles to a text value like so:
= (text)
	                        small block:
	value ----------------> CONSTANT_PACKED_TEXT_STORAGE
	                        launcher function ----------------------> ...
=
Thus, printing this value at runtime calls the launcher function. This in
turn runs the "issuing the response text" activity, though it does it via
a function defined in //BasicInformKit//.

@<Compile resources needed by this response@> =
	text_substitution *ts = resp->the_ts;
	inter_name *ts_value_iname = TextSubstitutions::value_iname(ts);
	inter_name *rc_iname =
		Responses::response_constant_iname(resp->the_rule, resp->the_marker);
	Emit::response(rc_iname, resp->the_rule, resp->the_marker, ts_value_iname);

	TextLiterals::compile_value_to(resp->value_iname, resp->launcher_iname);

	packaging_state save = Functions::begin(resp->launcher_iname);

	inter_name *iname = Responses::response_constant_iname(
		resp->the_rule, resp->the_marker);

	inter_name *rname = Hierarchy::find(RESPONSEVIAACTIVITY_HL);
	EmitCode::call(rname);
	EmitCode::down();
	EmitCode::val_iname(K_value, iname);
	EmitCode::up();

	Functions::end(save);

@ Something skated over above is that responses can also be created when the
source text defines a rule only as an Inter routine. For example:
= (text as Inform 7)
The hack mode rule translates into Inter as "HACK_MODE_ON_R" with "Hack mode on." (A).
=
Responses like this one are "via Inter", and they cause us to create a handler
function for the rule, called (say) |HACK_MODE_ON_RM|. The rule then calls:
= (text as Inform 6)
	HACK_MODE_ON_RM('A');
=
to produce response (A), or alternatively
= (text as Inform 6)
	HACK_MODE_ON_RM('a');
=
to return the current text of (A) without printing it. Speed is not of the essence;
and note that the response-handler is created in the package for the rule to which
it responds.

@<Compile the response-handler function for this rule@> =
	inter_name *responder_iname = RTRules::get_handler_definition(resp->the_rule);
	packaging_state save = Functions::begin(responder_iname);
	inter_symbol *code_s = LocalVariables::new_other_as_symbol(I"code");
	inter_symbol *val_s = LocalVariables::new_other_as_symbol(I"val");
	inter_symbol *val2_s = LocalVariables::new_other_as_symbol(I"val2");
	inter_symbol *s_s = LocalVariables::new_internal_as_symbol(I"s");
	inter_symbol *s2_s = LocalVariables::new_internal_as_symbol(I"s2");
	inter_symbol *s3_s = LocalVariables::new_internal_as_symbol(I"s3");
	inter_symbol *str_s = LocalVariables::new_internal_as_symbol(I"str");
	inter_symbol *f_s = LocalVariables::new_internal_as_symbol(I"f");

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			EmitCode::inv(GE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, code_s);
				EmitCode::val_number((inter_ti) 'a');
			EmitCode::up();
			EmitCode::inv(LE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, code_s);
				EmitCode::val_number((inter_ti) 'z');
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, f_s);
				EmitCode::val_true();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, code_s);
				EmitCode::inv(MINUS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, code_s);
					EmitCode::val_number((inter_ti) ('a'-'A'));
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, s_s);
		EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, s2_s);
		EmitCode::val_iname(K_value, Hierarchy::find(SECOND_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, s3_s);
		EmitCode::val_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
		EmitCode::val_symbol(K_value, val_s);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_object, Hierarchy::find(SECOND_HL));
		EmitCode::val_symbol(K_value, val2_s);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
		EmitCode::val_symbol(K_value, val_s);
	EmitCode::up();

	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, code_s);
		EmitCode::code();
		EmitCode::down();
			response_message *r2;
			LOOP_OVER(r2, response_message) {
				if (r2->the_rule == resp->the_rule) {
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_number((inter_ti) ('A' + r2->the_marker));
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, str_s);
								EmitCode::val_iname(K_value, r2->value_iname);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				}
			}
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, str_s);
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, f_s);
				EmitCode::val_false();
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::call(Hierarchy::find(TEXT_TY_SAY_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, str_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
		EmitCode::val_symbol(K_value, s_s);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_object, Hierarchy::find(SECOND_HL));
		EmitCode::val_symbol(K_value, s2_s);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
		EmitCode::val_symbol(K_value, s3_s);
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, str_s);
	EmitCode::up();

	Functions::end(save);

@ There's then one function and one array left to compile:

=
void Responses::compile_synoptic_resources(void) {
	@<Compile the PrintResponse routine@>;
	@<Compile the Response Divisions array@>;
}

@ This is in effect a big switch statement, so it's not fast; but as usual
with printing routines it really doesn't need to be. Given a response value,
say |R_14_RESP_B|, we print its current text, say response (B) for |R_14|.

@<Compile the PrintResponse routine@> =
	inter_name *printing_rule_name = Kinds::Behaviour::get_iname(K_response);
	packaging_state save = Functions::begin(printing_rule_name);
	inter_symbol *R_s = LocalVariables::new_other_as_symbol(I"R");
	response_message *resp;
	LOOP_OVER(resp, response_message) {
		inter_name *iname = Responses::response_constant_iname(resp->the_rule,
			resp->the_marker);
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, R_s);
				EmitCode::val_iname(K_value, iname);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::call(Hierarchy::find(RULEPRINTINGRULE_HL));
				EmitCode::down();
					EmitCode::val_iname(K_value, RTRules::iname(resp->the_rule));
				EmitCode::up();
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(I" response (");
				EmitCode::up();
				EmitCode::inv(PRINTCHAR_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) ('A' + resp->the_marker));
				EmitCode::up();
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(I")");
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}
	Functions::end(save);

@ The following array is used only by the testing command RESPONSES, and
enables the Inter template to print out all known responses at run-time,
divided up by the extensions containing the rules which produce them.

@<Compile the Response Divisions array@> =
	inter_name *iname = Hierarchy::find(RESPONSEDIVISIONS_HL);
	packaging_state save = EmitArrays::begin(iname, K_value);
	inform_extension *group_E = NULL;
	@<Make a ResponseDivisions entry@>;
	LOOP_OVER(group_E, inform_extension)
		@<Make a ResponseDivisions entry@>;
	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	Hierarchy::make_available(iname);

	inter_name *iname2 = Hierarchy::find(RESPONSEDIVISIONS2_HL);
	Produce::annotate_i(iname2, SYNOPTIC_IANN, 1);
	save = EmitArrays::begin(iname2, K_value);
	EmitArrays::end(save);
	Hierarchy::make_available(iname2);

@<Make a ResponseDivisions entry@> =
	rule *R;
	int tally = 0, contiguous_match = FALSE, no_cms = 0;
	LOOP_OVER(R, rule)
		for (int marker = 0; marker < 26; marker++)
			if (Rules::get_response(R, marker)) {
				tally++;
				inform_extension *E = Extensions::corresponding_to(
					Lexer::file_of_origin(Wordings::first_wn(R->name)));
				if (E == group_E) @<Start a possible run of matches@>
				else @<End a possible run of matches@>;
			}
	@<End a possible run of matches@>;

@<Start a possible run of matches@> =
	if (contiguous_match == FALSE) {
		contiguous_match = TRUE;
		if ((no_cms++ == 0) && (E)) {
			TEMPORARY_TEXT(QT)
			WRITE_TO(QT, "%<X", E->as_copy->edition->work);
			EmitArrays::text_entry(QT);
			DISCARD_TEXT(QT)
		} else
			EmitArrays::iname_entry(Hierarchy::find(EMPTY_TEXT_PACKED_HL));
		EmitArrays::numeric_entry((inter_ti) (tally));
	}

@<End a possible run of matches@> =
	if (contiguous_match) {
		EmitArrays::numeric_entry((inter_ti) (tally-1));
		contiguous_match = FALSE;
	}
