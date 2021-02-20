[Inferences::] Inferences.

An inference is a single datum about the world model, believed to be true or
untrue and with some degree of certainty.

@h Inferences.
This is quite a lightweight structure:

=
typedef struct inference {
	struct inference_family *family; /* see above */
	general_pointer data; /* details specific to the family */
	int certainty; /* any |*_CE| value other than |UNKNOWN_CE| */
	struct parse_node *inferred_from; /* from what sentence was this drawn? */
	int drawn_during_stage; /* or was this drawn during the model completion stage? */
	CLASS_DEFINITION
} inference;

@ The following routine coins a newly minted inference which is not yet attached
to any subject: but it will not stay unattached for long. Note that if nothing
has been said about likelihood, it is assumed to be factually certain.

=
inference *Inferences::create_inference(inference_family *f, general_pointer data,
	int certitude) {
	PROTECTED_MODEL_PROCEDURE;
	if (f == NULL) internal_error("inference orphaned");
	if (certitude == UNKNOWN_CE) certitude = CERTAIN_CE;
	inference *new_i = CREATE(inference);
	new_i->family = f;
	new_i->data = data;
	new_i->certainty = certitude;
	new_i->inferred_from = current_sentence;
	new_i->drawn_during_stage = World::current_building_stage();
	return new_i;
}

@h Access functions.
Once drawn, inferences are mostly read-only, but the following access routines
allow them to be read.

=
inference_family *Inferences::get_inference_type(inference *i) {
	return i->family;
}

parse_node *Inferences::where_inferred(inference *i) {
	return i->inferred_from;
}

int Inferences::get_certainty(inference *i) {
	return i->certainty;
}

int Inferences::during_stage(inference *i) {
	return i->drawn_during_stage;
}

@ This is very occasionally used in world modelling, when it has become
clear that an inference can be ignored.

=
void Inferences::render_impossible(inference *i) {
	i->certainty = IMPOSSIBLE_CE;
}

@h Looping over inferences.
The following macro prototypes show how to loop through all of the inferences
known concerning a given inference subject, and of a given type. "Positive"
knowledge means that the inferences must be more likely to be true than false.

@d POSITIVE_KNOWLEDGE_LOOP(inf, infs, type)
	LOOP_OVER_LINKED_LIST(inf, inference,
		(infs)?(InferenceSubjects::get_inferences(InferenceSubjects::divert(infs))):NULL)
		if ((inf->family == type) && (inf->certainty > 0))

@d KNOWLEDGE_LOOP(inf, infs, type)
	LOOP_OVER_LINKED_LIST(inf, inference,
		(infs)?(InferenceSubjects::get_inferences(InferenceSubjects::divert(infs))):NULL)
		if (inf->family == type)

@h Comparing inferences.
The following function is a little like |strcmp|, the standard C routine
for comparing strings. It compares two inferences |i1| and |i2| and returns
a value useful for sorting algorithms: 0 if equal, positive if |i1 < i2|,
negative if |i2 < i1|. This is a stable trichotomy; in particular,
|Inferences::cmp(i1, i2) == -Inferences::cmp(i2, i1)|.

With most sorting functions only the sign of the return value is significant,
but here the magnitude matters as well. It will always be one of the following.

"Topic" here means the basic fact being asserted. For example, an inference
that north from X is Y differs in topic from an inference that east from X is Z.
"Content" means what that fact is saying. For example, an inference that north
from X is Y differs in content from an inference that north from X is Z.

Inferences differ in Boolean content if the content in question can only have
two values. For example, an inference that a jar is open differs in Boolean
content from an inference that it is closed.

@d CI_DIFFER_IN_EXISTENCE 1 /* one exists, the other doesn't */
@d CI_DIFFER_IN_FAMILY 2
@d CI_DIFFER_IN_TOPIC 3
@d CI_DIFFER_IN_BOOLEAN_CONTENT 4
@d CI_DIFFER_IN_CONTENT 5
@d CI_DIFFER_IN_COPY_ONLY 6 /* these are different but duplicate inferences */
@d CI_IDENTICAL 0 /* these are pointers to the same inference in memory */

=
int Inferences::cmp(inference *i1, inference *i2) {
	if (i1 == i2) return CI_IDENTICAL;
	if (i1 == NULL) return CI_DIFFER_IN_EXISTENCE;
	if (i2 == NULL) return -CI_DIFFER_IN_EXISTENCE;
	int c = Inferences::measure_family(i1->family) -
			Inferences::measure_family(i2->family);
	if (c > 0) return CI_DIFFER_IN_FAMILY; if (c < 0) return -CI_DIFFER_IN_FAMILY;
	
	c = Inferences::family_specific_cmp(i1, i2); if (c != 0) return c;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY;
	if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;

	return CI_IDENTICAL;
}

@ Funny story: until 2019, inference comparison ran by using pointer
subtraction when comparing, say, subject references, on the principle that the
ordering doesn't really matter so long as it is definite and stable during a
run. But in the late 2010s, desktop operating systems such as MacOS Mojave
began to randomize the address space of all executables, to make it harder for
attackers to exploit buffer overflow bugs. As a result, although //Inferences::cmp//
continued to make definite orderings, they would be randomly different from
one run to another. Inform's output remained functionally correct, but the
generated I6 code would subtly differ from run to run. And so we instead now
incur the cost of looking up allocation IDs. Those count from 0, so we add 1
to differentiate them from the null pointer, which scores 0.

Pointer subtraction is, in any case, frowned on in all the best houses, so this
was probably a good thing.

=
int Inferences::measure_family(inference_family *F) {
	if (F) return 1 + F->allocation_id;
	return 0;
}
int Inferences::measure_property(property *P) {
	if (P) return 1 + P->allocation_id;
	return 0;
}
int Inferences::measure_inf(inference *I) {
	if (I) return 1 + I->allocation_id;
	return 0;
}
int Inferences::measure_infs(inference_subject *IS) {
	if (IS) return 1 + IS->allocation_id;
	return 0;
}
int Inferences::measure_pn(parse_node *N) {
	if (N) return 1 + N->allocation_id;
	return 0;
}

@h Joining an inference to a subject.
Each inference subject has a list of inferences concerning it. The process
of adding a new one is called "joining".

If we simply added it blindly to the end of the list, we might heap up all
kinds of contradictions or redundancies, so we use the above comparison
function to keep a tidy list in which neither can appear. The following code
looks simple enough, but took a long time to get right.

The loop here completes if and only if the inference is safely joined to the
list; that is, if it is found to contradict or duplicate existing knowledge,
then the function exits without completing the loop.

=
void Inferences::join_inference(inference *inf, inference_subject *infs) {
	PROTECTED_MODEL_PROCEDURE;
	if (inf == NULL) internal_error("joining null inference");
	if (infs == NULL) internal_error("joining to null inference subject");
	infs = InferenceSubjects::divert(infs);

	linked_list *SL = InferenceSubjects::get_inferences(infs);
	inference *existing;
	int insertion_point = 0;
	LOOP_OVER_LINKED_LIST(existing, inference, SL) {
		int c = Inferences::cmp(inf, existing);
		if (c == CI_IDENTICAL) internal_error("inference joined twice");
		int level_of_disagreement = abs(c);
		if (level_of_disagreement > CI_DIFFER_IN_TOPIC)
			@<These relate to the same basic fact and one must exclude the other@>;
		if (c < 0) @<Insert the newly-drawn inference here@>;
		insertion_point++;
	}
	@<Insert the newly-drawn inference here@>;	
}

@<Insert the newly-drawn inference here@> =
	LinkedLists::insert(SL, insertion_point, inf);
	Inferences::report_inference(inf, infs, "drawn");
	PluginCalls::inference_drawn(inf, infs);
	return;

@ For example, we would be here if |inf| said that the carrying capacity of
the Canopus jar was 10, and |existing| said it was 12: these inferences concern
the same basic fact, i.e., what the carrying capacity of the jar is.

@<These relate to the same basic fact and one must exclude the other@> =
	int inf_sureness = abs(inf->certainty);
	int existing_sureness = abs(existing->certainty);
	if (existing_sureness > inf_sureness) {
		Inferences::report_inference(inf, infs, "discarded (we already know better)");
	} else if (existing_sureness < inf_sureness) {
		LinkedLists::set_entry(insertion_point, SL, inf);
		Inferences::report_inference(inf, infs, "replaced existing less certain one");
		PluginCalls::inference_drawn(inf, infs);
	} else {
		int contradiction_flag = FALSE;
		@<Determine whether or not they contradict each other@>;
		if (contradiction_flag) {
			if (inf_sureness == CERTAIN_CE)
				@<Contradictions of certainty are forbidden, so issue a problem@>;
			if ((inf_sureness == LIKELY_CE) &&
				(InferenceSubjects::get_default_certainty(infs) == LIKELY_CE))
				@<Later generalisations beat earlier ones@>;
			Inferences::report_inference(inf, infs, "discarded as a harmless contradiction");
		} else {
			Inferences::report_inference(inf, infs, "discarded as redundant");
		}
	}
	return;

@ In general, if two inferences give different content on the same topic, then
they contradict each other if they are both positive, but not if only one of
them is:
= (text as Inform 7)
North of Oxford is Banbury. North of Oxford is Abingdon.      CONTRADICTION!
East of Oxford is Cowley. East of Oxford is not Kidlington.   NO CONTRADICTION!
=
But there is a subtlety when both inferences are negative: it comes down to
whether one value being false forces any alternative to be true, i.e., to
whether the details are Boolean. Consider:
= (text as Inform 7)
The box is not open. The box is not closed.                   CONTRADICTION!
The bag can be red, blue or green.
The bag is not green. The bag is not blue.                    NO CONTRADICTION!
=
In practice, Inform steers authors away from making negative assertions, so
this last subtlety doesn't arise in that form, but it does matter for inferences
drawn in world-modelling. For example, a single object O may have three
different inferences saying that it is not part of X, Y or Z respectively;
these are not mutually contradictory.[1]

[1] They differ in content but do not differ in Boolean content, because the
choice of what to be part of has more than two possible outcomes.

@<Determine whether or not they contradict each other@> =
	if ((existing->certainty > 0) && (inf->certainty > 0)) {
		contradiction_flag = FALSE;
		if ((level_of_disagreement == CI_DIFFER_IN_CONTENT) ||
			(level_of_disagreement == CI_DIFFER_IN_BOOLEAN_CONTENT))
			contradiction_flag = TRUE;
	}
	if ((existing->certainty > 0) && (inf->certainty < 0)) {
		contradiction_flag = TRUE;
		if ((level_of_disagreement == CI_DIFFER_IN_CONTENT) ||
			(level_of_disagreement == CI_DIFFER_IN_BOOLEAN_CONTENT))
			contradiction_flag = FALSE;
	}
	if ((existing->certainty < 0) && (inf->certainty > 0)) {
		contradiction_flag = TRUE;
		if ((level_of_disagreement == CI_DIFFER_IN_CONTENT) ||
			(level_of_disagreement == CI_DIFFER_IN_BOOLEAN_CONTENT))
			contradiction_flag = FALSE;
	}
	if ((existing->certainty < 0) && (inf->certainty < 0)) {
		contradiction_flag = FALSE;
		if (level_of_disagreement == CI_DIFFER_IN_BOOLEAN_CONTENT)
			contradiction_flag = TRUE;	
	}

@<Contradictions of certainty are forbidden, so issue a problem@> =
	Inferences::report_inference(inf, infs, "contradiction");
	Inferences::report_inference(existing, infs, "with");
	if (Inferences::explain_contradiction(existing, inf, level_of_disagreement, infs))
		return;
	StandardProblems::two_sentences_problem(_p_(PM_Contradiction),
		existing->inferred_from,
		"this looks like a contradiction",
		"which might be because I have misunderstood what was meant to be the subject "
		"of one or both of those sentences.");
	return;

@ When talking about kinds or kinds of value, we allow new merely likely
information to displace old; but not when talking about specific objects or
values, when the initial information stands. (This is to make it easier for
people to change the effect of extensions which create kinds and specify their
likely properties.)

@<Later generalisations beat earlier ones@> =
	LinkedLists::set_entry(insertion_point, SL, inf);
	Inferences::report_inference(inf, infs, "replaced existing also only likely one");
	PluginCalls::inference_drawn(inf, infs);
	return;

@h Logging inferences.
We keep the debugging log file more than usually well informed about what
goes on with inferences, as there is obviously great potential for mystifying
bugs if inferences are incorrectly ignored.

=
void Inferences::report_inference(inference *inf, inference_subject *infs,
	char *what_happened) {
	LOGIF(INFERENCES, ":::: %s: $j - $I\n", what_happened, infs, inf);
}

void Inferences::log_family(inference_family *f) {
	if (f == NULL) LOG("<null inference family>");
	else LOG("%S", f->log_name);
}

void Inferences::log(inference *in) {
	if (in == NULL) { LOG("<null-inference>"); return; }
	Inferences::log_family(in->family);
	LOG("-");
	switch(in->certainty) {
		case IMPOSSIBLE_CE: LOG("Impossible "); break;
		case UNLIKELY_CE: LOG("Unlikely "); break;
		case UNKNOWN_CE: LOG("<No information> "); break;
		case LIKELY_CE: LOG("Likely "); break;
		case CERTAIN_CE: LOG("Certain "); break;
		default: LOG("<unknown-certainty>"); break;
	}
	Inferences::log_family_details(in);
}

@h Inference families.
Every inference belongs to a family, and different families have different
rules, provided by method calls.

=
typedef struct inference_family {
	struct method_set *methods;
	struct text_stream *log_name;
	CLASS_DEFINITION
} inference_family;

inference_family *Inferences::new_family(text_stream *name) {
	inference_family *f = CREATE(inference_family);
	f->methods = Methods::new_set();
	f->log_name = Str::duplicate(name);
	return f;
}

@ Inference families support the following methods, all optional. First:

@e LOG_DETAILS_INF_MTID

=
VOID_METHOD_TYPE(LOG_DETAILS_INF_MTID, inference_family *f, inference *inf)

void Inferences::log_family_details(inference *inf) {
	VOID_METHOD_CALL(inf->family, LOG_DETAILS_INF_MTID, inf);
}

@ This is called when //Inferences::cmp// is comparing two inferences which both
belong to this family. It should return one of the values described in the
documentation for that function; if it isn't provided, then the inferences will
automatically be considered as either duplicative or contradictory.

@e COMPARE_INF_MTID

=
INT_METHOD_TYPE(COMPARE_INF_MTID, inference_family *f, inference *inf1, inference *inf2)

int Inferences::family_specific_cmp(inference *inf1, inference *inf2) {
	int rv = 0;
	INT_METHOD_CALL(rv, inf1->family, COMPARE_INF_MTID, inf1, inf2);
	return rv;
}

@ When a contradiction arises that requires a problem message, this method is
called to give it the chance to issue a better-phrased one. If it does, it
should return |TRUE|. If it does not exist, or returns |FALSE|, a generic
contradiction problem is generated as usual.

@e EXPLAIN_CONTRADICTION_INF_MTID

=
INT_METHOD_TYPE(EXPLAIN_CONTRADICTION_INF_MTID, inference_family *f,
	inference *A, inference *B, int similarity, inference_subject *subj)

int Inferences::explain_contradiction(inference *A, inference *B,
	int similarity, inference_subject *subj) {
	int rv = 0;
	INT_METHOD_CALL(rv, A->family, EXPLAIN_CONTRADICTION_INF_MTID, A, B, similarity, subj);
	return rv;
}
