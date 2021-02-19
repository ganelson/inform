[ConditionsOfSubjects::] Conditions of Subjects.

Properties which hold one of an enumerated set of named states of
something.

@ Condition here is meant in the sense of "What condition is this in?", not
the usual computer-science sense of "Is this true or false?". Here a subject
is in one of a finite number of possible states, as declared by a sentence like:

>> The cask can be wedged open, bolted closed or stoved in.

A property called the "cask condition" is created, whose value must be one of
these three named possibilities; and this is also the name of a new kind,
which is an enumeration of which these are the only three legal values.

@ =
typedef struct condition_of_subject {
	struct inference_subject *condition_of; /* is it a condition of an object? */
	int condition_anonymously_named; /* if so, is it named just "... condition"? */
	CLASS_DEFINITION	
} condition_of_subject;

condition_of_subject *ConditionsOfSubjects::new(inference_subject *subj, int anon) {
	condition_of_subject *cos = CREATE(condition_of_subject);
	cos->condition_of = subj;
	cos->condition_anonymously_named = anon;
	return cos;
}

@ And here we parse sentences like the example above. Despite the use of the
word "or", the set of option names is a little |AND_NT| subtree, of which
|set| is the head node. |subj| is the owner-to-be: in this example, the cask.
If the condition is one which already exists, having been created similarly
for something else, the wording of its name should be supplied in |cond_W|:
this should otherwise be the empty wording.

On exit, |already| should be set to |TRUE| if the enumerative values existed
already, i.e., if it was indeed a condition used before.

=
property *ConditionsOfSubjects::parse(inference_subject *infs, wording cond_W,
	parse_node *set, int *already) {
	int anon = FALSE;
	*already = FALSE;
	if (Wordings::empty(cond_W)) {
		kind *common_kind = NULL;
		wording common_kind_setting_opt_W = EMPTY_WORDING,
			wrong_kind_opt_W = EMPTY_WORDING;
		@<See if the options are all already values for some common kind@>;
		if (common_kind) @<Apparently so@>;
		@<Devise a name to give to this currently nameless condition@>;
		anon = TRUE;
	}
	@<Make a new kind and a new property with a coinciding name@>;
}

@ If one of the options is a value for an existing kind, then they all have
to be, and of the same kind. Any option which is not has its wording put
into |wrong_kind_opt_W|.

@<See if the options are all already values for some common kind@> =
	for (parse_node *option = set; option;
		option = (option->down)?(option->down->next):NULL) {
		wording opt_W = EMPTY_WORDING;
		if (Node::get_type(option) == AND_NT)
			opt_W = Node::get_text(option->down);
		else
			opt_W = Node::get_text(option);
		adjective *adj = Adjectives::parse(opt_W);
		if (adj) {
			instance *I = AdjectiveAmbiguity::has_enumerative_meaning(adj);
			kind *K = (I)?Instances::to_kind(I):NULL;
			if (common_kind == NULL) {
				common_kind = K;
				common_kind_setting_opt_W = opt_W;
			} else if (Kinds::eq(K, common_kind) == FALSE) {
				wrong_kind_opt_W = opt_W;
			}
		} else {
			wrong_kind_opt_W = opt_W;
		}
	}
	
@<Apparently so@> =
	property *prn = Properties::property_with_same_name_as(common_kind);
	if (Wordings::nonempty(wrong_kind_opt_W)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, common_kind);
		Problems::quote_wording(3, common_kind_setting_opt_W);
		Problems::quote_wording(4, wrong_kind_opt_W);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_MixedExistingConstants));
		Problems::issue_problem_segment(
			"In %1, one of the values you supply as a possibility is '%3', "
			"but this already has a meaning (as %2). This might be okay if "
			"every other possibility was also %2, but '%4' isn't.");
		Problems::issue_problem_end();
	} else if (prn == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, common_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(BelievedImpossible)); /* because it won't parse */
		Problems::issue_problem_segment(
			"In %1, every value you supply as a possibility is %2. "
			"That would be okay if it were a property which is a condition "
			"of something, but it isn't.");
		Problems::issue_problem_end();
	} else {
		*already = TRUE;
		return prn;
	}

@ The name is ideally the subject's name plus "condition": for instance,
"lounge table condition". But we need to be careful in case there are
multiple such conditions, because we don't want to duplicate the name. So
we begin by counting how many such already exist, and then append a number:
thus "lounge table condition", then "lounge table condition 2", and so on.

We could be more fanatical about this, if we wanted. The code here doesn't
guarantee uniqueness of the resulting name in all cases, because it's possible
for two subjects to have identical names. (But when that happens, it's unlikely
that different condition properties are given to them.) We won't obsess over
this because the point is only to help the user by minimising namespace
clashes; it isn't essential to Inform's running.

@<Devise a name to give to this currently nameless condition@> =
	int ct = 0;
	condition_of_subject *cos;
	LOOP_OVER(cos, condition_of_subject)
		if ((cos->condition_of == infs) && (cos->condition_anonymously_named))
			ct++;
	feed_t id = Feeds::begin();
	wording W2 = InferenceSubjects::get_name_text(infs);
	if (Wordings::nonempty(W2)) Feeds::feed_wording(W2);
	else Feeds::feed_C_string(L" nameless ");
	Feeds::feed_C_string(L" condition ");
	if (ct > 0) {
		TEMPORARY_TEXT(numb)
		WRITE_TO(numb, " %d ", ct+1);
		Feeds::feed_text(numb);
		DISCARD_TEXT(numb)
	}
	cond_W = Feeds::end(id);

@<Make a new kind and a new property with a coinciding name@> =
	pcalc_prop *prop = Propositions::Abstract::to_create_something(NULL, cond_W);
	prop = Propositions::concatenate(prop,
		Propositions::Abstract::to_make_a_kind(K_value));
	Assert::true(prop, prevailing_mood);

	property *prn = ValueProperties::obtain(cond_W);
	prn->value_data->as_condition_of_subject = ConditionsOfSubjects::new(infs, anon);
	return prn;

@ =
inference_subject *ConditionsOfSubjects::of_what(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) return NULL;
	if (prn->value_data->as_condition_of_subject == NULL) return NULL;
	return prn->value_data->as_condition_of_subject->condition_of;
}
