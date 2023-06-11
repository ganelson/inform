[Name::] Name Properties.

Small arrays of dictionary words which are values of the name property for objects.

@ In the runtime command parser, the names of objects are parsed as nouns using
the values of two properties: |name|, a simple array of dictionary words, and
|parse_name|, a GPR function. These properties can be assigned either to single
instances of kinds of object, or to the kinds themselves, so we store their
inames in data attached to an inference subject.

For a subject which is neither an object nor a kind of object, these names are
forever null.

=
typedef struct parsing_compilation_data {
	struct package_request *parsing_package;
	struct inter_name *name_array_iname;
	struct inter_name *parse_name_fn_iname;
} parsing_compilation_data;

@ I will be / PCD:

=
parsing_compilation_data Name::new_compilation_data(inference_subject *subj) {
	parsing_compilation_data pcd;
	pcd.parsing_package = NULL;
	pcd.name_array_iname = NULL;
	pcd.parse_name_fn_iname = NULL;
	return pcd;
}

@ A single package holds the |name| and/or |parse_name| of a single subject.

=
package_request *Name::package(inference_subject *subj) {
	if (PARSING_DATA_FOR_SUBJ(subj)->compilation_data.parsing_package == NULL)
		PARSING_DATA_FOR_SUBJ(subj)->compilation_data.parsing_package =
			Hierarchy::completion_package(OBJECT_NOUNS_HAP);
	return PARSING_DATA_FOR_SUBJ(subj)->compilation_data.parsing_package;
}

inter_name *Name::get_name_array_iname(inference_subject *subj) {
	if (PARSING_DATA_FOR_SUBJ(subj)->compilation_data.name_array_iname == NULL)
		PARSING_DATA_FOR_SUBJ(subj)->compilation_data.name_array_iname =
			Hierarchy::make_iname_in(NAME_ARRAY_HL, Name::package(subj));
	return PARSING_DATA_FOR_SUBJ(subj)->compilation_data.name_array_iname;
}

inter_name *Name::get_parse_name_fn_iname(inference_subject *subj) {
	if (PARSING_DATA_FOR_SUBJ(subj)->compilation_data.parse_name_fn_iname == NULL)
		PARSING_DATA_FOR_SUBJ(subj)->compilation_data.parse_name_fn_iname =
			Hierarchy::make_iname_in(PARSE_NAME_FN_HL, Name::package(subj));
	return PARSING_DATA_FOR_SUBJ(subj)->compilation_data.parse_name_fn_iname;
}

@ Note that a |name| is never given to a kind: only to an instance. This is
unlike customary practice when writing Inform 6 code, and is one of the few
ways in which I7-generated code does not mimic I6 practice in command parsing.[1]

We take special care to ensure that something called "your ..." in the source text
-- "your nose", say -- is altered to "my ..." for purposes of parsing during play.

[1] This is because we do not want to imitate the unusual feature of I6 which
makes |name| an "additive" property, i.e., in which arrays accumulate as objects
inherit from classes. The concept of additive properties does not exist in Inter.

=
parse_node *Name::name_property_array(instance *I, wording W, wording PW,
	int from_kind) {
	inter_name *name_array = Name::get_name_array_iname(I->as_subject);
	packaging_state save = EmitArrays::begin_inline(name_array, K_value);
	int entry_count = 0;

	LOOP_THROUGH_WORDING(j, W) {
		vocabulary_entry *ve = Lexer::word(j);
		ve = PreformUtilities::find_corresponding_word(ve,
			<second-person-possessive-pronoun-table>,
			<first-person-possessive-pronoun-table>);
		wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
		TEMPORARY_TEXT(content)
		WRITE_TO(content, "%w", p);
		EmitArrays::dword_entry(content); entry_count++;
		DISCARD_TEXT(content)
	}
	if (from_kind && !global_compilation_settings.no_auto_plural_names)
		LOOP_THROUGH_WORDING(j, PW) {
			int additional = TRUE;
			LOOP_THROUGH_WORDING(k, W)
				if (compare_word(j, Lexer::word(k)))
					additional = FALSE;
			if (additional) {
				TEMPORARY_TEXT(content)
				WRITE_TO(content, "%w", Lexer::word_text(j));
				EmitArrays::plural_dword_entry(content); entry_count++;
				DISCARD_TEXT(content)
			}
		}

	if (PARSING_DATA(I)->understand_as_this_subject)
		entry_count +=
			RTCommandGrammarLines::list_take_out_one_word_grammar(
				PARSING_DATA(I)->understand_as_this_subject);

	inference_subject *infs;
	for (infs = KindSubjects::from_kind(Instances::to_kind(I));
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		if (PARSING_DATA_FOR_SUBJ(infs)) {
			if (PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_subject)
				entry_count +=
					RTCommandGrammarLines::list_take_out_one_word_grammar(
						PARSING_DATA_FOR_SUBJ(infs)->understand_as_this_subject);
		}
	}

	if ((entry_count >= 32) && (TargetVMs::is_16_bit(Task::vm()))) {
		current_sentence = Instances::get_creating_sentence(I);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooManySynonymWords),
			"either this has a very long name, or too many uses of "
			"'understand ... as ...' have been made for the same thing",
			"exceeding the limit of 32. (This limit can be removed by "
			"switching the project to Glulx in the Settings.)");
	}

	EmitArrays::end(save);
	return Rvalues::from_iname(name_array);
}
