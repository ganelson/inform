[CompileRvalues::] Compile Rvalues.

To compile rvalues into Inter value opcodes or array entries.

@ And so to the code for compiling constants.

=
void CompileRvalues::compile(value_holster *VH, parse_node *value) {
	switch(Node::get_type(value)) {
		case PHRASE_TO_DECIDE_VALUE_NT:
			CompileInvocations::list(VH,
				value->down->down, Node::get_text(value), FALSE);
			break;
		case CONSTANT_NT: {
			kind *kind_of_constant = Node::get_kind_of_value(value);
			int ccm = Kinds::Behaviour::get_constant_compilation_method(kind_of_constant);
			if ((ccm == NONE_CCM) && (Kinds::Behaviour::is_an_enumeration(kind_of_constant)))
				ccm = NAMED_CONSTANT_CCM;
			switch(ccm) {
				case NONE_CCM: /* constant values of this kind cannot exist */
					LOG("SP: $P; kind: %u\n", value, kind_of_constant);
					internal_error("Tried to compile CONSTANT SP for a disallowed kind");
					return;
				case LITERAL_CCM:        @<Compile a literal-compilation-mode constant@>; return;
				case NAMED_CONSTANT_CCM: @<Compile a quantitative-compilation-mode constant@>; return;
				case SPECIAL_CCM:        @<Compile a special-compilation-mode constant@>; return;
			}
			break;
		}
	}
}

@ There are three basic compilation modes.

Here, the literal-parser is used to resolve the text of the SP to an integer.
I6 is typeless, of course, so it doesn't matter that this is not necessarily
a number: all that matters is that the correct integer value is compiled.

@<Compile a literal-compilation-mode constant@> =
	int N = Rvalues::to_int(value);
	if (Holsters::value_pair_allowed(VH))
		Holsters::holster_pair(VH, InterValuePairs::number((inter_ti) N));

@ Whereas here, an instance is attached.

@<Compile a quantitative-compilation-mode constant@> =
	instance *I = Node::get_constant_instance(value);
	if (I) {
		if (Holsters::value_pair_allowed(VH)) {
			inter_name *N = RTInstances::value_iname(I);
			if (N) Emit::holster_iname(VH, N);
			else internal_error("no iname for instance");
		}
	} else internal_error("no instance");

@ Otherwise there are just miscellaneous different things to do in different
kinds of value:

@<Compile a special-compilation-mode constant@> =
	if (PluginCalls::compile_constant(VH, kind_of_constant, value))
		return;
	if (Kinds::get_construct(kind_of_constant) == CON_activity) {
		activity *act = Rvalues::to_activity(value);
		inter_name *N = RTActivities::iname(act);
		if (N) Emit::holster_iname(VH, N);
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_combination) {
		int NC = 0;
		for (parse_node *term = value->down; term; term = term->next) NC++;
		int NT = 0, downs = 0;
		for (parse_node *term = value->down; term; term = term->next) {
			NT++;
			if (NT < NC) {
				EmitCode::inv(SEQUENTIAL_BIP);
				EmitCode::down(); downs++;
			}
			CompileValues::to_code_val(term);
		}
		while (downs > 0) { EmitCode::up(); downs--; }
		return;
	}
	if (Kinds::eq(kind_of_constant, K_equation)) {
		equation *eqn = Rvalues::to_equation(value);
		inter_name *N = RTEquations::identifier(eqn);
		if (N) Emit::holster_iname(VH, N);
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_description) {
		Deferrals::compile_multiple_use_proposition(VH,
			value, Kinds::unary_construction_material(kind_of_constant));
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_list_of) {
		wording W = Node::get_text(value);
		literal_list *ll = Lists::find_literal(Wordings::first_wn(W) + 1);
		if (ll) {
			inter_name *N = ListLiterals::compile_literal_list(ll);
			if (N) Emit::holster_iname(VH, N);
		}
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_phrase) {
		constant_phrase *cphr = Rvalues::to_constant_phrase(value);
		inter_name *N = Closures::iname(cphr);
		if (N) Emit::holster_iname(VH, N);
		return;
	}
	if (Kinds::Behaviour::is_object(kind_of_constant)) {
		if (Annotations::read_int(value, self_object_ANNOT)) {
			if (Holsters::value_pair_allowed(VH)) {
				Emit::holster_iname(VH, Hierarchy::find(SELF_HL));
			}
		} else if (Annotations::read_int(value, nothing_object_ANNOT)) {
			if (Holsters::value_pair_allowed(VH))
				Holsters::holster_pair(VH, InterValuePairs::number(0));
		} else {
			instance *I = Rvalues::to_instance(value);
			if (I) {
				inter_name *N = RTInstances::value_iname(I);
				if (N) Emit::holster_iname(VH, N);
			}
			parse_node *NB = Functions::line_being_compiled();
			if (NB) RTInstances::note_usage(I, NB);
		}
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_property) {
		@<Compile property constants@>;
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_relation) {
		binary_predicate *bp = Rvalues::to_binary_predicate(value);
		inter_name *N = RTRelations::iname(bp);
		if (N) Emit::holster_iname(VH, N);
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_rule) {
		rule *R = Rvalues::to_rule(value);
		Emit::holster_iname(VH, RTRules::iname(R));
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_rulebook) {
		rulebook *B = Rvalues::to_rulebook(value);
		Emit::holster_iname(VH, RTRulebooks::id_iname(B));
		return;
	}
	if (Kinds::eq(kind_of_constant, K_rulebook_outcome)) {
		named_rulebook_outcome *rbno = Rvalues::to_named_rulebook_outcome(value);
		Emit::holster_iname(VH, RTRulebooks::nro_iname(rbno));
		return;
	}
	if (Kinds::eq(kind_of_constant, K_table)) {
		table *t = Rvalues::to_table(value);
		Emit::holster_iname(VH, RTTables::identifier(t));
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_table_column) {
		table_column *tc = Rvalues::to_table_column(value);
		if (Holsters::value_pair_allowed(VH))
			Emit::holster_iname(VH, RTTableColumns::id_iname(tc));
		return;
	}
	if (Kinds::eq(kind_of_constant, K_text)) {
		CompileRvalues::text(VH, value);
		return;
	}
	if ((K_understanding) && (Kinds::eq(kind_of_constant, K_understanding))) {
		if (Wordings::empty(Node::get_text(value)))
			internal_error("Text no longer available for CONSTANT/UNDERSTANDING");
		inter_pair val = CompileRvalues::compile_understanding(Node::get_text(value));
		if (Holsters::value_pair_allowed(VH)) Holsters::holster_pair(VH, val);
		return;
	}
	if (Kinds::eq(kind_of_constant, K_use_option)) {
		use_option *uo = Rvalues::to_use_option(value);
		Emit::holster_iname(VH, RTUseOptions::uo_iname(uo));
		return;
	}
	if (Kinds::eq(kind_of_constant, K_verb)) {
		verb_form *vf = Rvalues::to_verb_form(value);
		Emit::holster_iname(VH, RTVerbs::form_fn_iname(vf));
		return;
	}
	if (Kinds::eq(kind_of_constant, K_response)) {
		rule *R = Rvalues::to_rule(value);
		int c = Annotations::read_int(value, response_code_ANNOT);
		inter_name *iname = Responses::response_constant_iname(R, c);
		if (iname) Emit::holster_iname(VH, iname);
		else Holsters::holster_pair(VH, InterValuePairs::number(0));
		Rules::now_rule_needs_response(R, c, EMPTY_WORDING);
		return;
	}

	LOG("Kov is %u\n", kind_of_constant);
	internal_error("no special ccm provided");

@ The interesting, read "unfortunate", case is that of constant property
names. The curiosity here is that it's legal to store the nameless negation
of an either/or property in a "property" constant. This was purely so that
the following ungainly syntax works:

>> change X to not P;

Which is now gone anyway, in favour of "now", where all this is handled
better. The feature, if we can call it that, probably derives from the fact
that Inform 6 allows an attribute |attr| can be negated in sense in several
contexts by using a tilde: |~attr|.

@<Compile property constants@> =
	property *prn = Rvalues::to_property(value);
	if (prn == NULL) internal_error("PROPERTY SP with null property");

	if (Properties::is_either_or(prn)) {
		int parity = 1;
		property *prn_to_eval = prn;
		if (<negated-clause>(Node::get_text(value))) parity = -1;
		if (RTProperties::stored_in_negation(prn)) {
			parity = -parity;
			prn_to_eval = EitherOrProperties::get_negation(prn_to_eval);
		}

		if (Holsters::value_pair_allowed(VH)) {
			if (parity == 1) {
				Emit::holster_iname(VH, RTProperties::iname(prn_to_eval));
			} else {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(Untestable),
					"this refers to an either-or property with a negative "
					"that I can't unravel'",
					"which normally never happens. (Are you using 'change' "
					"instead of 'now'?");
			}
		}
	} else {
		if (Holsters::value_pair_allowed(VH)) {
			Emit::holster_iname(VH, RTProperties::iname(prn));
		}
	}

@ The actions feature provides other kinds with idiosyncratic compilation needs,
if it is enabled.

=
int CompileRvalues::action_kinds(value_holster *VH, kind *K, parse_node *value) {
	if (Holsters::value_pair_allowed(VH) == FALSE) internal_error("action in void context");
	if (Kinds::eq(K, K_action_name)) {
		inter_name *N = RTActions::double_sharp(ARvalues::to_action_name(value));
		Emit::holster_iname(VH, N);
		return TRUE;
	}
	if (Kinds::eq(K, K_description_of_action)) {
		if (CompileValues::compiling_in_constant_mode()) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_APAsConstant),
				"this is a description of an action which is too vague to be used "
				"as a constant value",
				"and should either be something like 'taking action' (for the action "
				"in the abstract) or 'taking the beach ball' (for a definitely "
				"specific action), but not something like 'taking' or 'taking a "
				"container' which refer to a whole collection of possible actions.");
			return TRUE;
		}
		action_pattern *ap = Node::get_constant_action_pattern(value);
		RTActionPatterns::compile_pattern_match(ap);
		return TRUE;
	}
	if (Kinds::eq(K, K_stored_action)) {
		explicit_action *ea = Node::get_constant_explicit_action(value);
		if (CompileValues::compiling_in_constant_mode()) {
			Emit::holster_iname(VH, StoredActionLiterals::small_block(ea));
		} else {
			CompileRvalues::compile_explicit_action(ea, TRUE);
		}
		return TRUE;
	}
	return FALSE;
}

@ Texts can be compiled in four different ways, so the following splits into
four cases. Note that responses take the form
= (text)
	"blah blah blah" ( letter )
=
so the penultimate word, if it's there, is the letter.

=
void CompileRvalues::text(value_holster *VH, parse_node *str) {
	if (Holsters::value_pair_allowed(VH) == FALSE) internal_error("text in void context");
	if (Annotations::read_int(str, explicit_literal_ANNOT)) {
		@<This is an explicit text@>;
	} else {
		wording SW = Node::get_text(str);
		int unescaped = Annotations::read_int(str, text_unescaped_ANNOT);
		if (Wordings::empty(SW)) internal_error("text without wording");
		if ((Wordings::length(SW) >= 2) &&
			(<response-letter>(Wordings::one_word(Wordings::last_wn(SW)-1)))) {
			@<This is a response text@>;
		} else if ((unescaped == 0) &&
				(Vocabulary::test_flags(Wordings::first_wn(SW), TEXTWITHSUBS_MC))) {
			@<This is a text substitution@>;
		} else if (unescaped) {				
			@<This is an unescaped text literal@>;
		} else {
			@<This is a regular text literal@>;
		}
	}
}

@ Not explicit in the sense of an advisory sticker on an Eminem CD: explicit
in providing a text stream for its content, rather than a wording from the
source text. (This usually means it has been manufactured somewhere in the
compiler, rather than parsed from the source.)

@<This is an explicit text@> =
	if (Node::get_explicit_iname(str)) {
		if (Holsters::value_pair_allowed(VH)) {
			Emit::holster_iname(VH, Node::get_explicit_iname(str));
		} else internal_error("unvalued SCG");
	} else {
		int A = Annotations::read_int(str, constant_number_ANNOT);
		if (Holsters::value_pair_allowed(VH))
			Holsters::holster_pair(VH, InterValuePairs::number((inter_ti) A));
	}

@<This is a response text@> =
	rule *R = RTRules::rule_currently_being_compiled();
	int marker = <<r>>;
	if ((R == NULL) || (Rules::rule_allows_responses(R) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ResponseContextWrong),
			"lettered responses can only be used in named rules",
			"not in any of the other contexts in which quoted text can appear.");
		return;
	}
	if (Rules::get_response(R, marker)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ResponseDuplicated),
			"this duplicates a response letter",
			"which is not allowed: if a bracketed letter like (A) is used to mark "
			"some text as a response, then it can only occur once in its rule.");
		return;
	}
	Responses::set_via_source_text(VH, R, marker, SW);

@<This is a text substitution@> =
	TextSubstitutions::text_substitution_cue(VH, SW);

@<This is an unescaped text literal@> =
	inter_name *val_iname = TextLiterals::to_value_unescaped(SW);
	Emit::holster_iname(VH, val_iname);

@<This is a regular text literal@> =
	inter_name *val_iname = TextLiterals::to_value(SW);
	Emit::holster_iname(VH, val_iname);

@ Values for "understanding" refer to command grammar. We cache them as they
occur in the source text because they can compile to a fairly large slice of
code, and we don't want to repeat that:

=
typedef struct cached_understanding {
	struct wording understanding_text; /* word range of the understanding text */
	struct inter_name *cu_iname; /* function to test this */
	CLASS_DEFINITION
} cached_understanding;

inter_pair CompileRvalues::compile_understanding(wording W) {
	if (<subject-pronoun>(W)) {
		return InterValuePairs::number(0);
	} else {
		cached_understanding *cu;
		LOOP_OVER(cu, cached_understanding)
			if (Wordings::match(cu->understanding_text, W))
				return Emit::to_value_pair(cu->cu_iname);
		command_grammar *cg = Understand::consultation(W);
		inter_name *iname = RTCommandGrammars::get_consult_fn_iname(cg);
		if (iname == NULL) internal_error("no consultation iname");
		cu = CREATE(cached_understanding);
		cu->understanding_text = W;
		cu->cu_iname = iname;
		return Emit::to_value_pair(iname);
	}
}

@ Explicit actions can be compiled either as a "try" invocation or as the
constant value of a stored action. Either way it calls the runtime function
|TryAction|, for which see //WorldModelKit//; this function takes five
arguments, plus an optional sixth for where to store rather than process the
action.

=
void CompileRvalues::compile_explicit_action(explicit_action *ea, int as_value) {
	parse_node *n = ea->first_noun; /* the noun */
	parse_node *s = ea->second_noun; /* the second noun */
	parse_node *a = ea->actor; /* the actor */

	if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(n, K_understanding)) &&
		(<subject-pronoun>(Node::get_text(n)) == FALSE))
		n = Rvalues::from_wording(Node::get_text(n));
	if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(s, K_understanding)) &&
		(<subject-pronoun>(Node::get_text(s)) == FALSE))
		s = Rvalues::from_wording(Node::get_text(s));

	action_name *an = ea->action;

	int flag_bits = 0;
	if (Kinds::eq(Specifications::to_kind(n), K_text)) flag_bits += 16;
	if (Kinds::eq(Specifications::to_kind(s), K_text)) flag_bits += 32;
	if (flag_bits > 0) TheHeap::ensure_basic_heap_present();

	if (ea->request) flag_bits += 1;

	EmitCode::call(Hierarchy::find(TRYACTION_HL));
	EmitCode::down();
		EmitCode::val_number((inter_ti) flag_bits);
		if (a) CompileRvalues::compile_ea_parameter(a, K_object);
		else EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
		EmitCode::val_iname(K_action_name, RTActions::double_sharp(an));
		if (n) CompileRvalues::compile_ea_parameter(n, ActionSemantics::kind_of_noun(an));
		else EmitCode::val_number(0);
		if (s) CompileRvalues::compile_ea_parameter(s, ActionSemantics::kind_of_second(an));
		else EmitCode::val_number(0);
		if (as_value) {
			EmitCode::call(Hierarchy::find(STORED_ACTION_TY_CURRENT_HL));
			EmitCode::down();
				Frames::emit_new_local_value(K_stored_action);
			EmitCode::up();
		}
	EmitCode::up();
}

@ Which requires the following. Note that if the action expects to see a
|K_understanding|, then we typecheck in a way which will not cause an unwanted
silent cast to |K_text|; but type-safety is not violated.

=
void CompileRvalues::compile_ea_parameter(parse_node *term, kind *required_kind) {
	if ((K_understanding) && (Kinds::eq(required_kind, K_understanding))) {
		kind *K = Specifications::to_kind(term);
		if ((Kinds::compatible(K, K_understanding)) ||
			(Kinds::compatible(K, K_text)))
			required_kind = NULL;
	}
	if (Dash::check_value(term, required_kind))
		CompileValues::to_code_val_of_kind(term, K_object);
}
