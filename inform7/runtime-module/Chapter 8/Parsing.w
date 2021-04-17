[RTParsing::] Parsing.

@ 

=
void RTParsing::understood_variable(nonlocal_variable *var) {
	RTVariables::set_I6_identifier(var, FALSE,
		RTVariables::nve_from_iname(Hierarchy::find(PARSED_NUMBER_HL)));
	RTVariables::set_I6_identifier(var, TRUE,
		RTVariables::nve_from_iname(Hierarchy::find(PARSED_NUMBER_HL)));
}

@ The name property requires special care, partly over I6 eccentricities
such as the way that single-letter dictionary words can be misinterpreted
as characters (hence the double slash below), but also because something
called "your ..." in the source text -- "your nose", say -- needs to
be altered to "my ..." for purposes of parsing during play.

Note that |name| is additive in I6 terms, meaning that its values
accumulate from class down to instance: but we prevent this, by only
compiling |name| properties for instance objects directly. The practical
consequence is that we have to imitate this inheritance when it comes
to single-word grammar for things. Recall that a sentence like "Understand
"cube" as the block" formally creates a grammar line which ought to
be parsed as part of some elaborate |parse_name| property: but that for
efficiency's sake, we notice that "cube" is only one word and so put
it into the |name| property instead. And we need to perform the same trick
for the kinds we inherit from.

=
parse_node *RTParsing::name_property_array(instance *I, wording W, wording PW,
	int from_kind) {
	package_request *PR =
		Hierarchy::package_within(INLINE_PROPERTIES_HAP, RTInstances::package(I));
	inter_name *name_array = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	packaging_state save = EmitArrays::begin(name_array, K_value);

	LOOP_THROUGH_WORDING(j, W) {
		vocabulary_entry *ve = Lexer::word(j);
		ve = PreformUtilities::find_corresponding_word(ve,
			<second-person-possessive-pronoun-table>,
			<first-person-possessive-pronoun-table>);
		wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
		TEMPORARY_TEXT(content)
		WRITE_TO(content, "%w", p);
		EmitArrays::dword_entry(content);
		DISCARD_TEXT(content)
	}
	if (from_kind) /* see test case PM_PluralsFromKind */
		LOOP_THROUGH_WORDING(j, PW) {
			int additional = TRUE;
			LOOP_THROUGH_WORDING(k, W)
				if (compare_word(j, Lexer::word(k)))
					additional = FALSE;
			if (additional) {
				TEMPORARY_TEXT(content)
				WRITE_TO(content, "%w", Lexer::word_text(j));
				EmitArrays::plural_dword_entry(content);
				DISCARD_TEXT(content)
			}
		}

	if (PARSING_DATA(I)->understand_as_this_object)
		CommandGrammars::take_out_one_word_grammar(
			PARSING_DATA(I)->understand_as_this_object);

	inference_subject *infs;
	for (infs = KindSubjects::from_kind(Instances::to_kind(I));
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		if (PARSING_DATA_FOR_SUBJ(infs)) {
			if (PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_object)
				CommandGrammars::take_out_one_word_grammar(
					PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_object);
		}
	}

	EmitArrays::end(save);
	Produce::annotate_i(name_array, INLINE_ARRAY_IANN, 1);
	return Rvalues::from_iname(name_array);
}

inter_name *RTParsing::name_iname(void) {
	return RTProperties::iname(ParsingPlugin::name_property());
}

@ We cache grammar occurring in the source text in conditions, and so forth:

=
typedef struct cached_understanding {
	struct wording understanding_text; /* word range of the understanding text */
	struct inter_name *cu_iname; /* the runtime name for this |Consult_Grammar_N| routine */
	CLASS_DEFINITION
} cached_understanding;


void RTParsing::compile_understanding(inter_ti *val1, inter_ti *val2, wording W) {
	if (<subject-pronoun>(W)) { *val1 = LITERAL_IVAL; *val2 = 0; }
	else {
		cached_understanding *cu;
		LOOP_OVER(cu, cached_understanding)
			if (Wordings::match(cu->understanding_text, W)) {
				Emit::to_value_pair(val1, val2, cu->cu_iname);
				return;
			}
		command_grammar *cg = Understand::consultation(W);
		inter_name *iname = UnderstandGeneralTokens::consult_iname(cg);
		if (iname) {
			cu = CREATE(cached_understanding);
			cu->understanding_text = W;
			cu->cu_iname = iname;
			Emit::to_value_pair(val1, val2, iname);
		}
	}
}

