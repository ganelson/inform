[Properties::Conditions::] Condition Properties.

Properties which hold one of an enumerated set of named states of
something.

@ Some valued properties are "conditions", in the sense of "What
condition is this in?": for instance the sentence

>> The cask can be wedged open, bolted closed or stoved in.

sets up a new property called the "cask condition", whose value must be one of
these three named possibilities. (A new kind of value is set up whose three
possible values these are.)

@ =
void Properties::Conditions::initialise(property *prn) {
	prn->condition_of = NULL;
	prn->condition_anonymously_named = FALSE;
}

@ =
property *Properties::Conditions::new(inference_subject *infs, wording NW, parse_node *set, int *already) {
	int anon = FALSE;
	wording W = NW;
	*already = FALSE;
	if (Wordings::empty(NW)) {
		kind *common_kind = NULL;
		int mixed_kind = FALSE, some_new = FALSE;
		wording CKW = EMPTY_WORDING, NKW = EMPTY_WORDING;
		for (parse_node *option = set; option; option = (option->down)?(option->down->next):NULL) {
			wording PW = EMPTY_WORDING;
			if (Node::get_type(option) == AND_NT)
				PW = Node::get_text(option->down);
			else
				PW = Node::get_text(option);
			adjective *adj = Adjectives::parse(PW);
			if (adj) {
				instance *I = Adjectives::Meanings::has_ENUMERATIVE_meaning(adj);
				kind *K = (I)?Instances::to_kind(I):NULL;
				if (common_kind == NULL) {
					common_kind = K;
					CKW = PW;
				} else {
					if (Kinds::eq(K, common_kind) == FALSE) {
						mixed_kind = TRUE;
						NKW = PW;
					}
				}
			} else {
				some_new = TRUE; NKW = PW;
			}
		}
		if (common_kind) {
			property *prn = Properties::Conditions::get_coinciding_property(common_kind);
			if (Wordings::nonempty(NKW)) {
				Problems::quote_source(1, current_sentence);
				Problems::quote_kind(2, common_kind);
				Problems::quote_wording(3, CKW);
				Problems::quote_wording(4, NKW);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_MixedExistingConstants));
				Problems::issue_problem_segment(
					"In %1, one of the values you supply as a possibility is '%3', "
					"but this already has a meaning (as %2). This might be okay if "
					"every other possibility was also %2, but '%4' isn't.");
				Problems::issue_problem_end();
			} else if (prn == NULL) {
				Problems::quote_source(1, current_sentence);
				Problems::quote_kind(2, common_kind);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible)); /* because it won't parse */
				Problems::issue_problem_segment(
					"In %1, every value you supply as a possibility is %2. "
					"That would be okay if it were a property which is a condition "
					"of something, but it isn't.");
				Problems::issue_problem_end();
			} else {
				*already = TRUE;
				return prn;
			}
		}
		@<Devise a name to give to this currently nameless condition@>;
		anon = TRUE;
	}

	pcalc_prop *prop = Calculus::Propositions::Abstract::to_create_something(NULL, W);
	prop = Calculus::Propositions::concatenate(prop,
		Calculus::Propositions::Abstract::to_make_a_kind(K_value));
	Calculus::Propositions::Assert::assert_true(prop, prevailing_mood);

	property *prn = Properties::Valued::obtain(W);
	prn->either_or = FALSE;
	prn->condition_of = infs;
	prn->condition_anonymously_named = anon;
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

(And at present it seems very unlikely that conditions would ever be applied to
nameless subjects.)

@<Devise a name to give to this currently nameless condition@> =
	int ct = 0;
	property *prn;
	LOOP_OVER(prn, property)
		if ((prn->condition_of == infs) && (prn->condition_anonymously_named))
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
	W = Feeds::end(id);

@ =
inference_subject *Properties::Conditions::of_what(property *prn) {
	if ((prn == NULL) || (prn->either_or)) return NULL;
	return prn->condition_of; /* which will be null if not a condition property */
}

@h Coincidence.
Coincidence of kinds and properties occurs where a kind has the same name
exactly as a property, allowing the same name to be used grammatically in
two different contexts. We say that the kind and the property "coincide".
In particular, this happens with conditions:

>> Brightness is a kind of value. The brightnesses are guttering, weak, radiant and blazing. The lantern has a brightness. The lantern is blazing.

Here "brightness" becomes the name of a new kind, but "brightness" also
becomes the name of a property.

=
int Properties::Conditions::name_can_coincide_with_property(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->can_coincide_with_property;
}

property *Properties::Conditions::get_coinciding_property(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->coinciding_property;
}

void Properties::Conditions::set_coinciding_property(kind *K, property *P) {
	if (K == NULL) return;
	K->construct->coinciding_property = P;
}

