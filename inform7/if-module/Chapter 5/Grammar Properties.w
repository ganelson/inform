[Visibility::] Grammar Properties.

A plugin for the I6 run-time properties needed to support parsing.

@h Definitions.

@

= (early code)
property *P_parse_name = NULL;
property *P_action_bitmap = NULL;


@ Every inference subject (in particular, every object and every kind of object)
contains a pointer to its own unique copy of the following structure:

@d PARSING_DATA(I) PLUGIN_DATA_ON_INSTANCE(parsing, I)
@d PARSING_DATA_FOR_SUBJ(S) PLUGIN_DATA_ON_SUBJECT(parsing, S)

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
parsing_data *Visibility::new_data(inference_subject *subj) {
	parsing_data *pd = CREATE(parsing_data);
	pd->understand_as_this_object = NULL;
	return pd;
}

parsing_pp_data *Visibility::new_pp_data(property_permission *pp) {
	parsing_pp_data *pd = CREATE(parsing_pp_data);
	pd->visibility_level_in_parser = 0;
	pd->visibility_condition = EMPTY_WORDING;
	pd->visibility_sentence = NULL;
	return pd;
}

int Visibility::new_permission_notify(property_permission *new_pp) {
	CREATE_PLUGIN_PP_DATA(parsing, new_pp, Visibility::new_pp_data);
	return FALSE;
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
int Visibility::seek(property *pr, inference_subject *subj,
	int level, wording WHENW) {
	int parity, upto = 1;
	if (Properties::is_either_or(pr) == FALSE) upto = 0;
	for (parity = 0; parity <= upto; parity++) {
		property *seek_prn = (parity == 0)?pr:(EitherOrProperties::get_negation(pr));
		if (seek_prn == NULL) continue;
		if (PropertyPermissions::find(subj, seek_prn, TRUE) == NULL) continue;
		property_permission *pp = PropertyPermissions::grant(subj, seek_prn, FALSE);
		PP_PLUGIN_DATA(parsing, pp)->visibility_level_in_parser = level;
		PP_PLUGIN_DATA(parsing, pp)->visibility_sentence = current_sentence;
		PP_PLUGIN_DATA(parsing, pp)->visibility_condition = WHENW;
		return TRUE;
	}
	return FALSE;
}

int Visibility::any_property_visible_to_subject(inference_subject *subj, int allow_inheritance) {
	property *pr;
	LOOP_OVER(pr, property) {
		property_permission *pp =
			PropertyPermissions::find(subj, pr, allow_inheritance);
		if ((pp) && (PP_PLUGIN_DATA(parsing, pp)->visibility_level_in_parser > 0))
			return TRUE;
	}
	return FALSE;
}

int Visibility::get_level(property_permission *pp) {
	return PP_PLUGIN_DATA(parsing, pp)->visibility_level_in_parser;
}

parse_node *Visibility::get_condition(property_permission *pp) {
	parse_node *spec;
	if (Wordings::empty(PP_PLUGIN_DATA(parsing, pp)->visibility_condition)) return NULL;
	spec = NULL;
	if (<s-condition>(PP_PLUGIN_DATA(parsing, pp)->visibility_condition)) spec = <<rp>>;
	else spec = Specifications::new_UNKNOWN(PP_PLUGIN_DATA(parsing, pp)->visibility_condition);
	if (Dash::validate_conditional_clause(spec) == FALSE) {
		LOG("$T", spec);
		current_sentence = PP_PLUGIN_DATA(parsing, pp)->visibility_sentence;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadVisibilityWhen),
			"the condition after 'when' makes no sense to me",
			"although otherwise this worked - it is only the part after 'when' "
			"which I can't follow.");
		PP_PLUGIN_DATA(parsing, pp)->visibility_condition = EMPTY_WORDING;
		return NULL;
	}
	return spec;
}

void Visibility::log_parsing_visibility(inference_subject *infs) {
	LOG("Permissions for $j:\n", infs);
	property_permission *pp = NULL;
	LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs) {
		LOG("$Y: visibility %d, condition %W\n",
			PropertyPermissions::get_property(pp),
			PP_PLUGIN_DATA(parsing, pp)->visibility_level_in_parser,
			PP_PLUGIN_DATA(parsing, pp)->visibility_condition);
	}
	if (InferenceSubjects::narrowest_broader_subject(infs))
		Visibility::log_parsing_visibility(InferenceSubjects::narrowest_broader_subject(infs));
}
