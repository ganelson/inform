[Properties::Appearance::] Indefinite Appearance.

To look after the indefinite appearance pseudo-property, used when
the source text comments on something with a sentence consisting only of a
double-quoted literal text.

@h Inference.
The "indefinite appearance text" is a property given to something by the
A-parser when it appears as a double-quoted sentence with no other explanation.
For instance:

>> The drapery is in the Crypt. "The drapery hangs, poignantly waiting to fall."

This text will probably become a property of the drapery, but which property
depends on the drapery's kind. That means we can't decide until after the
source text is fully read, because we won't be certain of kinds until then.
So as an interim measure the text is inferred into a pseudo-property called
"indefinite appearance".

=
void Properties::Appearance::infer(inference_subject *infs, parse_node *spec) {
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, property_inf)
		if (PropertyInferences::get_property(inf) == P_indefinite_appearance_text)
			@<Issue a problem for a second appearance@>;

	prevailing_mood = CERTAIN_CE;
	if ((KindSubjects::to_kind(infs)) &&
		(InferenceSubjects::is_within(infs, KindSubjects::from_kind(K_object))))
		prevailing_mood = LIKELY_CE;
	Properties::Valued::assert(P_indefinite_appearance_text, infs, spec, prevailing_mood);
}

@ ...but we produce a firm and explicit problem message if somebody sets it
ambiguously.

@<Issue a problem for a second appearance@> =
	StandardProblems::infs_contradiction_problem(_p_(PM_TwoAppearances),
		Inferences::where_inferred(inf), current_sentence, infs,
		"seems to have two different descriptions",
		"perhaps because you intended the second description to apply to something "
		"mentioned in between, but declared it in such a way that it was never the "
		"subject of an assertion. For instance, 'The Forest Clearing is northeast of "
		"the Woods.' makes the Forest Clearing the current room being discussed, but "
		"'Northeast of the Woods is the Forest Clearing.' leaves the room under "
		"discussion unchanged, because the Forest Clearing is not the subject of "
		"the sentence.");
	return;

@h Reallocation.
Later, then, during model completion, we will have to make those decisions
about what property the indefinite appearance text should go into. This is
called "reallocation", and as can be seen the method is:

(a) See if any plugin wants to take action;
(b) And otherwise reallocate to the "description" property, if that is
available;
(c) But otherwise give up and issue a problem message.

=
void Properties::Appearance::reallocate(inference_subject *infs) {
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, property_inf) {
		if (PropertyInferences::get_property(inf) == P_indefinite_appearance_text) {
			parse_node *txt = PropertyInferences::get_value(inf);
			current_sentence = Inferences::where_inferred(inf);
			if (Plugins::Call::default_appearance(infs, txt) == FALSE) {
				if ((P_description) &&
					(PropertyPermissions::find(infs, P_description, TRUE))) {
					Properties::Valued::assert(P_description, infs, txt, CERTAIN_CE);
				} else StandardProblems::inference_problem(_p_(PM_IndefiniteTextMeaningless),
					infs, inf, "is not allowed",
					"i.e., you can't write a double-quoted piece of text as a "
					"sentence all by itself here. Some kinds or kinds of value "
					"are allowed this - objects and scenes, for instance - but "
					"most are not. (They would need to provide a 'description' "
					"property.)");
			}
		}
	}
}
