[PL::Parsing::Visibility::] Grammar Properties.

A plugin for the I6 run-time properties needed to support parsing.

@h Definitions.

@

= (early code)
property *P_name = NULL;
property *P_parse_name = NULL;
property *P_action_bitmap = NULL;

nonlocal_variable *real_location_VAR = NULL;
nonlocal_variable *actor_location_VAR = NULL;

nonlocal_variable *I6_noun_VAR = NULL;
nonlocal_variable *I6_second_VAR = NULL;
nonlocal_variable *I6_actor_VAR = NULL;

@ Every inference subject (in particular, every object and every kind of object)
contains a pointer to its own unique copy of the following structure:

=
typedef struct parsing_data {
	struct grammar_verb *understand_as_this_object; /* grammar for parsing the name at run-time */
	CLASS_DEFINITION
} parsing_data;

@ And every property permission likewise:

=
typedef struct parsing_pp_data {
	int visibility_level_in_parser; /* if so, does the run-time I6 parser recognise it? */
	struct wording visibility_condition; /* (at least if...?) */
	struct parse_node *visibility_sentence; /* where this is specified */
	CLASS_DEFINITION
} parsing_pp_data;

@h Initialising.

=
parsing_data *PL::Parsing::Visibility::new_data(inference_subject *subj) {
	parsing_data *pd = CREATE(parsing_data);
	pd->understand_as_this_object = NULL;
	return pd;
}

parsing_pp_data *PL::Parsing::Visibility::new_pp_data(property_permission *pp) {
	parsing_pp_data *pd = CREATE(parsing_pp_data);
	pd->visibility_level_in_parser = 0;
	pd->visibility_condition = EMPTY_WORDING;
	pd->visibility_sentence = NULL;
	return pd;
}

@h Plugin startup.

=
void PL::Parsing::Visibility::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_VARIABLE_NOTIFY, PL::Parsing::Visibility::parsing_new_variable_notify);
	PLUGIN_REGISTER(PLUGIN_NEW_SUBJECT_NOTIFY, PL::Parsing::Visibility::parsing_new_subject_notify);
	PLUGIN_REGISTER(PLUGIN_NEW_PERMISSION_NOTIFY, PL::Parsing::Visibility::parsing_new_permission_notify);
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Parsing::Visibility::parsing_complete_model);
	PLUGIN_REGISTER(PLUGIN_ESTIMATE_PROPERTY_USAGE, PL::Parsing::Visibility::parsing_estimate_property_usage);
}

int PL::Parsing::Visibility::parsing_new_subject_notify(inference_subject *subj) {
	CREATE_PF_DATA(parsing, subj, PL::Parsing::Visibility::new_data);
	return FALSE;
}

int PL::Parsing::Visibility::parsing_new_permission_notify(property_permission *new_pp) {
	CREATE_PLUGIN_PP_DATA(parsing, new_pp, PL::Parsing::Visibility::new_pp_data);
	return FALSE;
}

@ These are variable names to do with "Understand..." which Inform provides
special support for; it recognises the English names when they are defined by
the Standard Rules or, in the case of "the X understood", by Inform itself.
(So there is no need to translate this to other languages.)


=
<notable-parsing-variables> ::=
	<k-kind> understood |    ==> 0; <<kind:understood>> = RP[1]
	noun |    ==> 1
	location |    ==> 2
	actor-location |    ==> 3
	second noun |    ==> 4
	person asked |    ==> 5
	maximum score					==> 6

@ =
int PL::Parsing::Visibility::parsing_new_variable_notify(nonlocal_variable *var) {
	if (<notable-parsing-variables>(var->name)) {
		switch (<<r>>) {
			case 0:
				if (<<kind:understood>> == NonlocalVariables::kind(var)) {
					NonlocalVariables::set_I6_identifier(var, FALSE,
						NonlocalVariables::nve_from_iname(Hierarchy::find(PARSED_NUMBER_HL)));
					NonlocalVariables::set_I6_identifier(var, TRUE,
						NonlocalVariables::nve_from_iname(Hierarchy::find(PARSED_NUMBER_HL)));
					NonlocalVariables::allow_to_be_zero(var);
				}
				break;
			case 1: I6_noun_VAR = var; break;
			case 2: real_location_VAR = var; break;
			case 3: actor_location_VAR = var; break;
			case 4: I6_second_VAR = var; break;
			case 5: I6_actor_VAR = var; break;
			case 6: max_score_VAR = var;
				NonlocalVariables::make_initalisable(var); break;
		}
	}
	return FALSE;
}

@ This is for |name| and |plural|.

=
int PL::Parsing::Visibility::parsing_estimate_property_usage(kind *k, int *words_used) {
	wording W = Kinds::Behaviour::get_name(k, FALSE);
	*words_used += Wordings::length(W);
	wording PW = Kinds::Behaviour::get_name(k, TRUE);
	*words_used += Wordings::length(PW);
	return FALSE;
}

@ Once the traverse is done, we can infer values for the two key I6 properties
for parsing:

=
int PL::Parsing::Visibility::parsing_complete_model(int stage) {
	if (stage == 5) {
		instance *I;
		P_name = Properties::Valued::new_nameless(I"name", K_text);
		Hierarchy::make_available(Emit::tree(), PL::Parsing::Visibility::name_name());
		P_parse_name = Properties::Valued::new_nameless(I"parse_name", K_value);
		P_action_bitmap = Properties::Valued::new_nameless(I"action_bitmap", K_value);
		Hierarchy::make_available(Emit::tree(), Properties::iname(P_action_bitmap));

		LOOP_OVER_OBJECT_INSTANCES(I) {
			inference_subject *subj = Instances::as_subject(I);
			@<Assert the I6 name property@>;
			@<Assert the I6 parse-name property@>;
			@<Assert the I6 action-bitmap property@>;
		}

		kind *K;
		LOOP_OVER_BASE_KINDS(K)
			if (Kinds::Compare::lt(K, K_object)) {
				inference_subject *subj = Kinds::Knowledge::as_subject(K);
				@<Assert the I6 parse-name property@>;
			}

		inference_subject *subj = Kinds::Knowledge::as_subject(K_thing);
		@<Assert the I6 action-bitmap property@>;
	}
	return FALSE;
}

inter_name *PL::Parsing::Visibility::name_name(void) {
	return Properties::iname(P_name);
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

@<Assert the I6 name property@> =
	if (PL::Naming::object_is_privately_named(I) == FALSE) {
		kind *K = Instances::to_kind(I);
		int from_kind = FALSE;
		package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, Instances::package(I));
		inter_name *name_array = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
		packaging_state save = Emit::named_array_begin(name_array, K_value);
		wording W = Instances::get_name_in_play(I, FALSE);
		if (Wordings::empty(W)) W = Kinds::Behaviour::get_name_in_play(K, FALSE, Projects::get_language_of_play(Task::project()));
		wording PW = Instances::get_name_in_play(I, TRUE);
		if (Wordings::empty(PW)) {
			from_kind = TRUE; PW = Kinds::Behaviour::get_name_in_play(K, TRUE, Projects::get_language_of_play(Task::project()));
		}

		LOOP_THROUGH_WORDING(j, W) {
			vocabulary_entry *ve = Lexer::word(j);
			ve = Preform::Nonparsing::replace_word(ve,
				<possessive-second-person>,
				<possessive-first-person>);
			wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
			TEMPORARY_TEXT(content);
			WRITE_TO(content, "%w", p);
			Emit::array_dword_entry(content);
			DISCARD_TEXT(content);
		}
		if (from_kind) /* see test case PM_PluralsFromKind */
			LOOP_THROUGH_WORDING(j, PW) {
				int additional = TRUE;
				LOOP_THROUGH_WORDING(k, W)
					if (compare_word(j, Lexer::word(k)))
						additional = FALSE;
				if (additional) {
					TEMPORARY_TEXT(content);
					WRITE_TO(content, "%w", Lexer::word_text(j));
					Emit::array_plural_dword_entry(content);
					DISCARD_TEXT(content);
				}
			}

		if (PF_I(parsing, I)->understand_as_this_object)
			PL::Parsing::Verbs::take_out_one_word_grammar(
				PF_I(parsing, I)->understand_as_this_object);

		inference_subject *infs;
		for (infs = Kinds::Knowledge::as_subject(Instances::to_kind(I));
			infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
			if (PF_S(parsing, infs)) {
				if (PF_S(parsing, infs)->understand_as_this_object)
					PL::Parsing::Verbs::take_out_one_word_grammar(
						PF_S(parsing, infs)->understand_as_this_object);
			}
		}

		Emit::array_end(save);
		Produce::annotate_i(name_array, INLINE_ARRAY_IANN, 1);
		Properties::Valued::assert(P_name, Instances::as_subject(I),
			Rvalues::from_iname(name_array), CERTAIN_CE);
	}

@ We attach numbered parse name routines as properties for any object
where grammar has specified a need. (By default, this will not happen.)

@<Assert the I6 parse-name property@> =
	inter_name *S = PL::Parsing::Tokens::General::compile_parse_name_property(subj);
	if (S)
		Properties::Valued::assert(P_parse_name, subj,
			Rvalues::from_iname(S), CERTAIN_CE);

@ The action bitmap is an array of bits attached to each object, one
for each action, which records whether that action has yet applied
successfully to that object. This is used at run-time to handle past
tense conditions such as "the jewels have been taken". Note that
we give the bitmap in the class definition associated with "thing"
to ensure that it will be inherited by all I6 objects of this class,
i.e., all I6 objects corresponding to I7 things.

@<Assert the I6 action-bitmap property@> =
	if (InferenceSubjects::is_within(subj, Kinds::Knowledge::as_subject(K_room)) == FALSE) {
		instance *I = InferenceSubjects::as_instance(subj);
		inter_name *S = PL::Actions::compile_action_bitmap_property(I);
		Properties::Valued::assert(P_action_bitmap, subj,
			Rvalues::from_iname(S), CERTAIN_CE);
	}

@h Visible properties.
A visible property is one which can be used to describe an object: for
instance, if colour is a visible property of a car, then it can be called
"green car" if and only if the current value of the colour of the car is
"green".

Properly speaking it is not the property which is visible, but the
combination of property and object (or kind): thus the following test
depends on a property permission and not a mere property.

=
int PL::Parsing::Visibility::seek(property *pr, inference_subject *subj,
	int level, wording WHENW) {
	int parity, upto = 1;
	if (Properties::is_either_or(pr) == FALSE) upto = 0;
	for (parity = 0; parity <= upto; parity++) {
		property *seek_prn = (parity == 0)?pr:(Properties::EitherOr::get_negation(pr));
		if (seek_prn == NULL) continue;
		if (World::Permissions::find(subj, seek_prn, TRUE) == NULL) continue;
		property_permission *pp = World::Permissions::grant(subj, seek_prn, FALSE);
		PLUGIN_PP(parsing, pp)->visibility_level_in_parser = level;
		PLUGIN_PP(parsing, pp)->visibility_sentence = current_sentence;
		PLUGIN_PP(parsing, pp)->visibility_condition = WHENW;
		return TRUE;
	}
	return FALSE;
}

int PL::Parsing::Visibility::any_property_visible_to_subject(inference_subject *subj, int allow_inheritance) {
	property *pr;
	LOOP_OVER(pr, property) {
		property_permission *pp =
			World::Permissions::find(subj, pr, allow_inheritance);
		if ((pp) && (PLUGIN_PP(parsing, pp)->visibility_level_in_parser > 0))
			return TRUE;
	}
	return FALSE;
}

int PL::Parsing::Visibility::get_level(property_permission *pp) {
	return PLUGIN_PP(parsing, pp)->visibility_level_in_parser;
}

parse_node *PL::Parsing::Visibility::get_condition(property_permission *pp) {
	parse_node *spec;
	if (Wordings::empty(PLUGIN_PP(parsing, pp)->visibility_condition)) return NULL;
	spec = NULL;
	if (<s-condition>(PLUGIN_PP(parsing, pp)->visibility_condition)) spec = <<rp>>;
	else spec = Specifications::new_UNKNOWN(PLUGIN_PP(parsing, pp)->visibility_condition);
	if (Dash::validate_conditional_clause(spec) == FALSE) {
		LOG("$T", spec);
		current_sentence = PLUGIN_PP(parsing, pp)->visibility_sentence;
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_BadVisibilityWhen),
			"the condition after 'when' makes no sense to me",
			"although otherwise this worked - it is only the part after 'when' "
			"which I can't follow.");
		PLUGIN_PP(parsing, pp)->visibility_condition = EMPTY_WORDING;
		return NULL;
	}
	return spec;
}

void PL::Parsing::Visibility::log_parsing_visibility(inference_subject *infs) {
	LOG("Permissions for $j:\n", infs);
	property_permission *pp = NULL;
	LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs) {
		LOG("$Y: visibility %d, condition %W\n",
			World::Permissions::get_property(pp),
			PLUGIN_PP(parsing, pp)->visibility_level_in_parser,
			PLUGIN_PP(parsing, pp)->visibility_condition);
	}
	if (InferenceSubjects::narrowest_broader_subject(infs))
		PL::Parsing::Visibility::log_parsing_visibility(InferenceSubjects::narrowest_broader_subject(infs));
}
