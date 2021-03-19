[Visibility::] Property Visibility.

Some properties can be referred to in the player's commands.

@ "Visible" properties can be used to describe an object: for example, if
colour is a visible property of a car, then an individual instance of |K_car|
can be referred to by the player as GREEN CAR if and only if that instance has
the colour value "green".

Properly speaking it is not the property itself which is visible, but the
combination of property and its owner. So we record visibility by attaching
the following blob of data to a |property_permission|:

@d NO_VISIBILITY_LEVEL 0
@d REFERRING_TO_VISIBILITY_LEVEL 1
@d DESCRIBING_VISIBILITY_LEVEL 2

=
typedef struct parsing_pp_data {
	int visibility_level_in_parser; /* one of the |*_VISIBILITY_LEVEL| values above */
	struct wording visibility_condition; /* (at least if...?) */
	struct parse_node *visibility_sentence; /* where this is specified */
	CLASS_DEFINITION
} parsing_pp_data;

parsing_pp_data *Visibility::new_pp_data(property_permission *pp) {
	parsing_pp_data *pd = CREATE(parsing_pp_data);
	pd->visibility_level_in_parser = NO_VISIBILITY_LEVEL;
	pd->visibility_condition = EMPTY_WORDING;
	pd->visibility_sentence = NULL;
	return pd;
}

int Visibility::new_permission_notify(property_permission *new_pp) {
	CREATE_PLUGIN_PP_DATA(parsing, new_pp, Visibility::new_pp_data);
	return FALSE;
}

@ The following function sets the visibility level and condition for a given
property and owner, returning |FALSE| if the owner cannot in fact have that
property. There's a little dance here because perhaps we want to set visibility
for "open" when its negation "closed" has the permission, or vice versa.

=
int Visibility::set(property *pr, inference_subject *subj, int level, wording WHENW) {
	int upto = 1;
	if (Properties::is_either_or(pr) == FALSE) upto = 0;
	for (int parity = 0; parity <= upto; parity++) {
		property *seek_prn = (parity == 0)?pr:(EitherOrProperties::get_negation(pr));
		if ((seek_prn) && (PropertyPermissions::find(subj, seek_prn, TRUE))) {
			property_permission *pp = PropertyPermissions::grant(subj, seek_prn, FALSE);
			PP_PLUGIN_DATA(parsing, pp)->visibility_level_in_parser = level;
			PP_PLUGIN_DATA(parsing, pp)->visibility_condition = WHENW;
			PP_PLUGIN_DATA(parsing, pp)->visibility_sentence = current_sentence;
			return TRUE;
		}
	}
	return FALSE;
}

@ Does the property owner |subj| have any visible properties?

=
int Visibility::any_property_visible_to_subject(inference_subject *subj,
	int allow_inheritance) {
	property *pr;
	LOOP_OVER(pr, property) {
		property_permission *pp = PropertyPermissions::find(subj, pr, allow_inheritance);
		if ((pp) && (PP_PLUGIN_DATA(parsing, pp)->visibility_level_in_parser > 0))
			return TRUE;
	}
	return FALSE;
}

@ For what these levels actually mean, see the code for the run-time command parser
at //CommandParserKit: Parser//.

=
int Visibility::get_level(property_permission *pp) {
	return PP_PLUGIN_DATA(parsing, pp)->visibility_level_in_parser;
}

@ The condition text, if supplied, says that the property is only visible
if some condition holds.

For timing reasons, we don't parse this when it is first declared, but only
when we need it, which is now:

=
parse_node *Visibility::get_condition(property_permission *pp) {
	wording W = PP_PLUGIN_DATA(parsing, pp)->visibility_condition;
	if (Wordings::empty(W)) return NULL;
	parse_node *spec = NULL;
	if (<s-condition>(W)) spec = <<rp>>;
	else spec = Specifications::new_UNKNOWN(W);
	if (Dash::validate_conditional_clause(spec) == FALSE) {
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

@ Though currently unused, this function may be useful for debugging:

=
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
		Visibility::log_parsing_visibility(
			InferenceSubjects::narrowest_broader_subject(infs));
}
