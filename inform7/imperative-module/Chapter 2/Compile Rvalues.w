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
	if (Holsters::non_void_context(VH))
		Holsters::holster_pair(VH, LITERAL_IVAL, (inter_ti) N);

@ Whereas here, an instance is attached.

@<Compile a quantitative-compilation-mode constant@> =
	instance *I = Node::get_constant_instance(value);
	if (I) {
		if (Holsters::non_void_context(VH)) {
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
			if (Holsters::non_void_context(VH)) {
				Emit::holster_iname(VH, Hierarchy::find(SELF_HL));
			}
		} else if (Annotations::read_int(value, nothing_object_ANNOT)) {
			if (Holsters::non_void_context(VH))
				Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		} else {
			instance *I = Rvalues::to_instance(value);
			if (I) {
				inter_name *N = RTInstances::value_iname(I);
				if (N) Emit::holster_iname(VH, N);
			}
			parse_node *NB = Functions::line_being_compiled();
			if (NB) IXInstances::note_usage(I, NB);
		}
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_property) {
		@<Compile property constants@>;
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_relation) {
		binary_predicate *bp = Rvalues::to_binary_predicate(value);
		RTRelations::mark_as_needed(bp);
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
		rulebook *rb = Rvalues::to_rulebook(value);
		Emit::holster_iname(VH, rb->compilation_data.rb_id_iname);
		return;
	}
	if (Kinds::eq(kind_of_constant, K_rulebook_outcome)) {
		named_rulebook_outcome *rbno =
			Rvalues::to_named_rulebook_outcome(value);
		Emit::holster_iname(VH, RTRules::outcome_identifier(rbno));
		return;
	}
	if (Kinds::eq(kind_of_constant, K_table)) {
		table *t = Rvalues::to_table(value);
		Emit::holster_iname(VH, RTTables::identifier(t));
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_table_column) {
		table_column *tc = Rvalues::to_table_column(value);
		if (Holsters::non_void_context(VH))
			Emit::holster_iname(VH, RTTables::column_id(tc));
		return;
	}
	if (Kinds::eq(kind_of_constant, K_text)) {
		CompileRvalues::text(VH, value);
		return;
	}
	#ifdef IF_MODULE
	if ((K_understanding) && (Kinds::eq(kind_of_constant, K_understanding))) {
		if (Wordings::empty(Node::get_text(value)))
			internal_error("Text no longer available for CONSTANT/UNDERSTANDING");
		inter_ti v1 = 0, v2 = 0;
		RTParsing::compile_understanding(&v1, &v2, Node::get_text(value));
		if (Holsters::non_void_context(VH)) {
			Holsters::holster_pair(VH, v1, v2);
		}
		return;
	}
	#endif
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
		else Holsters::holster_pair(VH, LITERAL_IVAL, 0);
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

		if (Holsters::non_void_context(VH)) {
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
		if (Holsters::non_void_context(VH)) {
			Emit::holster_iname(VH, RTProperties::iname(prn));
		}
	}

@ Texts can be compiled in four different ways, so the following splits into
four cases. Note that responses take the form
= (text)
	"blah blah blah" ( letter )
=
so the penultimate word, if it's there, is the letter.

=
void CompileRvalues::text(value_holster *VH, parse_node *str) {
	if (Holsters::non_void_context(VH) == FALSE) internal_error("text in void context");
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
		if (Holsters::non_void_context(VH)) {
			Emit::holster_iname(VH, Node::get_explicit_iname(str));
		} else internal_error("unvalued SCG");
	} else {
		int A = Annotations::read_int(str, constant_number_ANNOT);
		if (Holsters::non_void_context(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, (inter_ti) A);
	}

@<This is a response text@> =
	int marker = <<r>>;
	if ((rule_being_compiled == NULL) ||
		(Rules::rule_allows_responses(rule_being_compiled) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ResponseContextWrong),
			"lettered responses can only be used in named rules",
			"not in any of the other contexts in which quoted text can appear.");
		return;
	}
	if (Rules::get_response(rule_being_compiled, marker)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ResponseDuplicated),
			"this duplicates a response letter",
			"which is not allowed: if a bracketed letter like (A) is used to mark "
			"some text as a response, then it can only occur once in its rule.");
		return;
	}
	Responses::set_via_source_text(VH, rule_being_compiled, marker, SW);

@<This is a text substitution@> =
	TextSubstitutions::text_substitution_cue(VH, SW);

@<This is an unescaped text literal@> =
	inter_name *val_iname = TextLiterals::to_value_unescaped(SW);
	Emit::holster_iname(VH, val_iname);

@<This is a regular text literal@> =
	inter_name *val_iname = TextLiterals::to_value(SW);
	Emit::holster_iname(VH, val_iname);
