[KindCommands::] Kind Commands.

To apply a given command to a given kind constructor.

@ =
void KindCommands::apply(single_kind_command stc, kind_constructor *con) {
	if (stc.completed) return;
	LOGIF(KIND_CREATIONS, "apply: %s (%d/%d/%S/%S) to %d/%S\n",
		stc.which_kind_command->text_of_command,
		stc.boolean_argument, stc.numeric_argument,
		stc.textual_argument, stc.constructor_argument,
		con->allocation_id, con->explicit_identifier);

	int tcc = stc.which_kind_command->opcode_number;

	@<Apply kind macros or transcribe kind templates on request@>;

	@<Most kind commands simply set a field in the constructor structure@>;
	@<A few kind commands contribute to linked lists in the constructor structure@>;
	@<And the rest fill in fields in the constructor structure in miscellaneous other ways@>;

	TEMPORARY_TEXT(cmd)
	WRITE_TO(cmd, "%s", stc.which_kind_command->text_of_command);
	NeptuneFiles::error(cmd, I"unimplemented kind command", stc.origin);
	DISCARD_TEXT(cmd)
}

@<Apply kind macros or transcribe kind templates on request@> =
	switch (tcc) {
		case invent_source_text_KCC:
			StarTemplates::note(stc.template_argument, con, stc.origin);
			return;
		case apply_macro_KCC:
			NeptuneMacros::play_back(stc.macro_argument, con, stc.origin);
			return;
	}

@

@d SET_BOOLEAN_FIELD(field) case field##_KCC: con->field = stc.boolean_argument; return;
@d SET_INTEGER_FIELD(field) case field##_KCC: con->field = stc.numeric_argument; return;
@d SET_TEXTUAL_FIELD(field) case field##_KCC: con->field = Str::duplicate(stc.textual_argument); return;
@d SET_CCM_FIELD(field) case field##_KCC: con->field = stc.ccm_argument; return;

@<Most kind commands simply set a field in the constructor structure@> =
	switch (tcc) {
		SET_BOOLEAN_FIELD(can_coincide_with_property)
		SET_BOOLEAN_FIELD(can_exchange)
		SET_BOOLEAN_FIELD(indexed_grey_if_empty)
		SET_BOOLEAN_FIELD(is_incompletely_defined)
		SET_BOOLEAN_FIELD(multiple_block)
		SET_BOOLEAN_FIELD(forbid_assertion_creation)

		SET_INTEGER_FIELD(heap_size_estimate)
		SET_INTEGER_FIELD(index_priority)
		SET_INTEGER_FIELD(small_block_size)

		SET_CCM_FIELD(constant_compilation_method)

		SET_TEXTUAL_FIELD(default_value)
		SET_TEXTUAL_FIELD(distinguishing_routine)
		SET_TEXTUAL_FIELD(documentation_reference)
		SET_TEXTUAL_FIELD(explicit_GPR_identifier)
		SET_TEXTUAL_FIELD(index_default_value)
		SET_TEXTUAL_FIELD(index_maximum_value)
		SET_TEXTUAL_FIELD(index_minimum_value)
		SET_TEXTUAL_FIELD(loop_domain_schema)
		SET_TEXTUAL_FIELD(recognition_routine)
		SET_TEXTUAL_FIELD(specification_text)
	}

@<A few kind commands contribute to linked lists in the constructor structure@> =
	if (tcc == compatible_with_KCC) {
		#ifdef CORE_MODULE
		if ((Str::eq(stc.constructor_argument, I"SNIPPET_TY")) &&
			(FEATURE_INACTIVE(parsing))) return;
		#endif
		kind_constructor_casting_rule *dtcr = CREATE(kind_constructor_casting_rule);
		dtcr->next_casting_rule = con->first_casting_rule;
		con->first_casting_rule = dtcr;
		dtcr->cast_from_kind_unparsed = Str::duplicate(stc.constructor_argument);
		dtcr->cast_from_kind = NULL;
		return;
	}
	if (tcc == conforms_to_KCC) {
		kind_constructor_instance_rule *dti = CREATE(kind_constructor_instance_rule);
		dti->next_instance_rule = con->first_instance_rule;
		con->first_instance_rule = dti;
		dti->instance_of_this_unparsed = Str::duplicate(stc.constructor_argument);
		dti->instance_of_this = NULL;
		return;
	}
	if (tcc == comparison_schema_KCC) {
		kind_constructor_comparison_schema *dtcs = CREATE(kind_constructor_comparison_schema);
		dtcs->next_comparison_schema = con->first_comparison_schema;
		con->first_comparison_schema = dtcs;
		dtcs->comparator_unparsed = Str::duplicate(stc.constructor_argument);
		dtcs->comparator = NULL;
		dtcs->comparison_schema = Str::duplicate(stc.textual_argument);
		return;
	}
	if (tcc == instance_KCC) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, stc.textual_argument, L" *(%c+?) *= *(%C+) *= *(%C+) *")) {
			kind_constructor_instance *kci = CREATE(kind_constructor_instance);
			kci->natural_language_name = Str::duplicate(mr.exp[0]);
			kci->identifier = Str::duplicate(mr.exp[1]);
			int bad = FALSE;
			kci->value = KindCommands::parse_literal_number(mr.exp[2], &bad);
			kci->value_specified = TRUE;
			if (bad) {
				NeptuneFiles::error(stc.textual_argument,
					I"value after the final '=' is not a valid Inform 6 literal", stc.origin);
				kci->value = 0;
				kci->value_specified = FALSE;
			}
			ADD_TO_LINKED_LIST(kci, kind_constructor_instance, con->instances);	
		} else if (Regexp::match(&mr, stc.textual_argument, L" *(%c+?) *= *(%C+) *")) {
			kind_constructor_instance *kci = CREATE(kind_constructor_instance);
			kci->natural_language_name = Str::duplicate(mr.exp[0]);
			kci->identifier = Str::duplicate(mr.exp[1]);
			kci->value = 0;
			kci->value_specified = FALSE;
			ADD_TO_LINKED_LIST(kci, kind_constructor_instance, con->instances);	
		} else {
			NeptuneFiles::error(stc.textual_argument,
				I"instance not in form NAME = IDENTIFIER = VALUE", stc.origin);
		}
		Regexp::dispose_of(&mr);
		return;
	}

@<And the rest fill in fields in the constructor structure in miscellaneous other ways@> =
	switch (tcc) {
		case terms_KCC:
			@<Parse the constructor arity text@>;
			return;
		case comparison_routine_KCC:
			if (Str::len(stc.textual_argument) > 31)
				NeptuneFiles::error(stc.textual_argument, I"overlong identifier", stc.origin);
			else con->comparison_routine = Str::duplicate(stc.textual_argument);
			return;
		case printing_routine_KCC:
			if (Str::len(stc.textual_argument) > 31) 
				NeptuneFiles::error(stc.textual_argument, I"overlong identifier", stc.origin);
			else con->print_identifier = Str::duplicate(stc.textual_argument);
			return;
		case printing_routine_for_debugging_KCC:
			if (Str::len(stc.textual_argument) > 31)
				NeptuneFiles::error(stc.textual_argument, I"overlong identifier", stc.origin);
			else con->ACTIONS_identifier = Str::duplicate(stc.textual_argument);
			return;
		case singular_KCC: case plural_KCC: {
			vocabulary_entry **array; int length;
			WordAssemblages::as_array(&(stc.vocabulary_argument), &array, &length);
			if (length == 1) {
				Kinds::mark_vocabulary_as_kind(array[0], Kinds::base_construction(con));
			} else {
				for (int i=0; i<length; i++) {
					Vocabulary::set_flags(array[i], KIND_SLOW_MC);
					NTI::mark_vocabulary(array[i], <k-kind>);
				}
				if (con->group != PROPER_CONSTRUCTOR_GRP) {
					vocabulary_entry *ve = WordAssemblages::hyphenated(&(stc.vocabulary_argument));
					if (ve) Kinds::mark_vocabulary_as_kind(ve, Kinds::base_construction(con));
				}
			}
			feed_t id = Feeds::begin();
			for (int i=0; i<length; i++)
				Feeds::feed_C_string(Vocabulary::get_exemplar(array[i], FALSE));
			wording LW = Feeds::end(id);
			if (tcc == singular_KCC) {
				int ro = 0;
				if (con->group != PROPER_CONSTRUCTOR_GRP)
					ro = ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT;
				NATURAL_LANGUAGE_WORDS_TYPE *L = NULL;
				#ifdef CORE_MODULE
				L = Task::language_of_syntax();
				#endif
				noun *nt =
					Nouns::new_common_noun(LW, NEUTER_GENDER, ro,
					KIND_SLOW_MC, STORE_POINTER_kind_constructor(con), L);
				con->dt_tag = nt;
			} else {
				NATURAL_LANGUAGE_WORDS_TYPE *L = NULL;
				#ifdef CORE_MODULE
				L = Task::language_of_syntax();
				#endif
				Nouns::set_nominative_plural_in_language(con->dt_tag, LW, L);
			}
			return;
		}
	}

@<Parse the constructor arity text@> =
	int c = 0;
	string_position pos = Str::start(stc.textual_argument);
	while (TRUE) {
		while (Characters::is_space_or_tab(Str::get(pos))) pos = Str::forward(pos);
		if (Str::get(pos) == 0) break;
		if (Str::get(pos) == ',') { c++; pos = Str::forward(pos); continue; }
		if (c >= 2) { c=1; break; }
		TEMPORARY_TEXT(wd)
		while ((!Characters::is_space_or_tab(Str::get(pos))) && (Str::get(pos) != ',')
			&& (Str::get(pos) != 0)) {
			PUT_TO(wd, Str::get(pos)); pos = Str::forward(pos);
		}
		if (Str::len(wd) > 0) {
			if (Str::eq_wide_string(wd, L"covariant")) con->variance[c] = COVARIANT;
			else if (Str::eq_wide_string(wd, L"contravariant")) con->variance[c] = CONTRAVARIANT;
			else if (Str::eq_wide_string(wd, L"optional")) con->tupling[c] = ALLOW_NOTHING_TUPLING;
			else if (Str::eq_wide_string(wd, L"list")) con->tupling[c] = ARBITRARY_TUPLING;
			else NeptuneFiles::error(wd, I"illegal constructor-arity keyword", stc.origin);
		}
		DISCARD_TEXT(wd)
	}
	con->constructor_arity = c+1;

@ This is used for parsing the values of enumeration members in |instance|
commands:

=
int KindCommands::parse_literal_number(text_stream *S, int *bad) {
	*bad = FALSE;
	int sign = 1, base = 10, from = 0, to = Str::len(S)-1;
	if ((Str::get_at(S, from) == '(') && (Str::get_at(S, to) == ')')) { from++; to--; }
	while (Characters::is_whitespace(Str::get_at(S, from))) from++;
	while (Characters::is_whitespace(Str::get_at(S, to))) to--;
	if (Str::get_at(S, from) == '-') { sign = -1; from++; }
	else if (Str::get_at(S, from) == '$') {
		from++; base = 16;
		if (Str::get_at(S, from) == '$') {
			from++; base = 2;
		}
	}
	long long int N = 0;
	LOOP_THROUGH_TEXT(pos, S) {
		if (pos.index < from) continue;
		if (pos.index > to) continue;
		int c = Str::get(pos), d = 0;
		if ((c >= 'a') && (c <= 'z')) d = c-'a'+10;
		else if ((c >= 'A') && (c <= 'Z')) d = c-'A'+10;
		else if ((c >= '0') && (c <= '9')) d = c-'0';
		else { *bad = TRUE; break; }
		if (d > base) { *bad = TRUE; break; }
		N = base*N + (long long int) d;
		if (pos.index > 34) { *bad = TRUE; break; }
	}
	if (*bad == FALSE) {
		N = sign*N;
		return (int) N;
	}
	return -1;
}

