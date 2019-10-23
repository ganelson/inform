[World::Inferences::] Inferences.

To manage the individual pieces of information gathered, with
varying degrees of certainty, from assertion sentences. This is mostly
information about which objects have what properties.

@h Definitions.

@ Inform reads a natural language description of a world. As it runs through, it
collects together the assertions made in this description (such as "On the
table is a hat"), which are sometimes vague (where is this table?), sometimes
imply further facts (the hat cannot be a room, and the table must be a
supporter) and are sometimes contradictory (if, for instance, "The hat is in
the hatbox" has also been read).

As we have seen, such sentences are reduced to logical propositions, then
asserted true, which results in a sequence of "inferences" being "drawn".
In this section, we see how inferences are stored and what drawing them
entails.

Each inference represents a single fact, associated with the "inference
subject" it concerns. For instance, if property P of object X has the value V,
that makes an inference about X; but if the fact is that two objects, X and Y,
are related, then that will often be an inference about the relation rather than
about X or Y.

As this last example shows, up to two other inference subjects can be connected
by the fact in question, besides the INFS to which it is attached.

@ There are only two main types of inference, though plugins can and do define
further types.

@d ARBITRARY_RELATION_INF 1 /* fact about an "arbitrary" relation */
@d PROPERTY_INF 2 /* fact about a property */

@ Not all information is positive, or certain. The likelihood of something
being true is measured on the five-point |*_CE| scale, though an inference
is never allowed to have |UNKNOWN_CE| status -- that would tell us nothing.

If $C$ is a certainty level, then we call its absolute value the "absolute
certainty". Thus there are only three absolute certainty levels: unknown,
likely and certain.

@ When a given sentence is being parsed, there is a prevailing mood of certainty
or uncertainty about the information implied by it, and this is stored in the
following global variable:

= (early code)
int prevailing_mood = UNKNOWN_CE;

@ This is the data structure used to store a single inference. Within the
stock of facts known about a given INFS, the individual inferences are
organised as linked lists; hence the |next| field.

=
typedef struct inference {
	int inference_type; /* see above */
	int certainty; /* see above */
	struct parse_node *inferred_from; /* from what sentence was this drawn? */
	int added_in_construction; /* or was this drawn during the model completion stage? */
	int inference_timestamp;

	struct inference_subject *infs_ref1; /* from 0 to 2 other INFSs are connected by this inference */
	struct inference_subject *infs_ref2;

	struct parse_node *spec_ref1; /* used by dynamic relations between non-subjects */
	struct parse_node *spec_ref2;

	struct property *inferred_property; /* property referred to, if any */
	struct parse_node *inferred_property_value; /* and its value, if any */

	struct inference *next; /* next in list of inferences on same subject */
	MEMORY_MANAGEMENT
} inference;

@h Creation.
The following routine coins a newly minted inference which is not yet attached
to any subject: but it will not stay unattached for long. Note that if nothing
has been said about likelihood, the sentence is assumed to be factually certain.

=
int inference_timer = 0;

inference *World::Inferences::create_inference(int type, int certitude) {
	PROTECTED_MODEL_PROCEDURE;
	if (certitude == UNKNOWN_CE) certitude = CERTAIN_CE;
	inference *new_i;
	new_i = CREATE(inference);
	new_i->inference_timestamp = inference_timer++;
	new_i->inference_type = type;
	new_i->certainty = certitude;
	new_i->infs_ref1 = NULL; new_i->infs_ref2 = NULL;
	new_i->spec_ref1 = NULL; new_i->spec_ref2 = NULL;
	new_i->inferred_property = NULL;
	new_i->inferred_property_value = NULL;
	new_i->inferred_from = current_sentence;
	new_i->added_in_construction = model_world_under_construction;
	new_i->next = NULL;
	return new_i;
}

@ Here are our two core inference types:

=
inference *World::Inferences::create_property_inference(inference_subject *infs,
	property *prn, parse_node *val) {
	PROTECTED_MODEL_PROCEDURE;
	inference *i = World::Inferences::create_inference(PROPERTY_INF, prevailing_mood);
	if (prevailing_mood == UNKNOWN_CE)
		i->certainty = InferenceSubjects::get_default_certainty(infs);
	i->inferred_property = prn;
	i->inferred_property_value = val;
	if (prn == NULL) internal_error("null property inference");
	return i;
}

inference *World::Inferences::create_relation_inference(inference_subject *infs0, inference_subject *infs1) {
	PROTECTED_MODEL_PROCEDURE;
	inference *i = World::Inferences::create_inference(ARBITRARY_RELATION_INF, prevailing_mood);
	i->infs_ref1 = World::Inferences::divert_infs(infs0);
	i->infs_ref2 = World::Inferences::divert_infs(infs1);
	return i;
}

inference *World::Inferences::create_relation_inference_spec(parse_node *spec0, parse_node *spec1) {
	PROTECTED_MODEL_PROCEDURE;
	inference *i = World::Inferences::create_inference(ARBITRARY_RELATION_INF, prevailing_mood);
	i->spec_ref1 = spec0;
	i->spec_ref2 = spec1;
	if ((spec0 == NULL) || (spec1 == NULL)) internal_error("malformed specified relation");
	return i;
}

@h Drawing inferences.
This is how the rest of Inform records fresh information about the world
model. To "draw" an inference is to create it as a structure and then
"join" it to the list of facts already known about its subject. (This
might not actually accept it; it might be redundant, or contradictory.)

The two core inferences:

=
void World::Inferences::draw_property(inference_subject *infs,
	property *prn, parse_node *val) {
	inference *i = World::Inferences::create_property_inference(infs, prn, val);
	World::Inferences::join_inference(i, infs);
}

void World::Inferences::draw_negated_property(inference_subject *infs,
	property *prn, parse_node *val) {
	inference *i = World::Inferences::create_property_inference(infs, prn, val);
	i->certainty = -i->certainty;
	World::Inferences::join_inference(i, infs);
}

void World::Inferences::draw_relation(binary_predicate *bp,
	inference_subject *infs0, inference_subject *infs1) {
	inference *i = World::Inferences::create_relation_inference(infs0, infs1);
	World::Inferences::join_inference(i, BinaryPredicates::as_subject(bp));
}

void World::Inferences::draw_relation_spec(binary_predicate *bp,
	parse_node *spec0, parse_node *spec1) {
	inference *i = World::Inferences::create_relation_inference_spec(spec0, spec1);
	World::Inferences::join_inference(i, BinaryPredicates::as_subject(bp));
}

@ And an all-purpose routine provided for plugins to draw customised
inferences of their own:

=
void World::Inferences::draw(int type, inference_subject *about,
	int certitude, inference_subject *infs0, inference_subject *infs1) {
	inference *i = World::Inferences::create_inference(type, certitude);
	i->infs_ref1 = World::Inferences::divert_infs(infs0); i->infs_ref2 = World::Inferences::divert_infs(infs1);
	World::Inferences::join_inference(i, about);
}

@h Reading inference data.
Once drawn, inferences are read-only, and the following access routines
allow them to be read.

=
int World::Inferences::get_timestamp(inference *i) {
	return i->inference_timestamp;
}

int World::Inferences::get_inference_type(inference *i) {
	return i->inference_type;
}

parse_node *World::Inferences::where_inferred(inference *i) {
	return i->inferred_from;
}

int World::Inferences::get_certainty(inference *i) {
	return i->certainty;
}

void World::Inferences::set_certainty(inference *i, int ce) {
	i->certainty = ce;
}

int World::Inferences::added_in_construction(inference *i) {
	return i->added_in_construction;
}

property *World::Inferences::get_property(inference *i) {
	return i->inferred_property;
}

parse_node *World::Inferences::get_property_value(inference *i) {
	return i->inferred_property_value;
}

parse_node *World::Inferences::set_property_value_kind(inference *i, kind *K) {
	ParseTree::set_kind_of_value(i->inferred_property_value, K);
	return i->inferred_property_value;
}

@ Core Inform deals only in INFSs, but plugins often use inferences concerned
only with objects (e.g., for the map), so we also provide a convenient abbreviated
way to extract just reference 1 in object form.

=
void World::Inferences::get_references(inference *i,
	inference_subject **infs1, inference_subject **infs2) {
	if (infs1) *infs1 = i->infs_ref1; if (infs2) *infs2 = i->infs_ref2;
}

void World::Inferences::get_references_spec(inference *i,
	parse_node **spec1, parse_node **spec2) {
	*spec1 = i->spec_ref1; *spec2 = i->spec_ref2;
}

instance *World::Inferences::get_reference_as_object(inference *i) {
	return InferenceSubjects::as_object_instance(i->infs_ref1);
}

@h Looping over inferences.
The following macro prototypes show how to loop through all of the inferences
known concerning a given inference subject, and of a given type. "Positive"
knowledge means that the inferences must have a certainty of likely or better.

@d POSITIVE_KNOWLEDGE_LOOP(inf, infs, type)
	for (inf = (infs)?(InferenceSubjects::get_inferences(World::Inferences::divert_infs(infs))):NULL; inf; inf = inf->next)
		if ((inf->inference_type == type) && (inf->certainty > 0))

@d KNOWLEDGE_LOOP(inf, infs, type)
	for (inf = (infs)?(InferenceSubjects::get_inferences(World::Inferences::divert_infs(infs))):NULL; inf; inf = inf->next)
		if (inf->inference_type == type)

@h Finding property states.

=
int World::Inferences::get_EO_state(inference_subject *infs, property *prn) {
	if ((prn == NULL) || (infs == NULL)) return UNKNOWN_CE;
	inference_subject *k;
	property *prnbar = NULL;
	if (Properties::is_either_or(prn)) prnbar = Properties::EitherOr::get_negation(prn);
	for (k = infs; k; k = InferenceSubjects::narrowest_broader_subject(k)) {
		inference *inf;
		KNOWLEDGE_LOOP(inf, k, PROPERTY_INF) {
			property *known = World::Inferences::get_property(inf);
			int c = World::Inferences::get_certainty(inf);
			if (known) {
				if ((prn == known) && (c != UNKNOWN_CE)) return c;
				if ((prnbar == known) && (c != UNKNOWN_CE)) return -c;
			}
		}
	}
	return UNKNOWN_CE;
}

int World::Inferences::get_EO_state_without_inheritance(inference_subject *infs, property *prn, parse_node **where) {
	if ((prn == NULL) || (infs == NULL)) return UNKNOWN_CE;
	property *prnbar = NULL;
	if (Properties::is_either_or(prn)) prnbar = Properties::EitherOr::get_negation(prn);
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF) {
		property *known = World::Inferences::get_property(inf);
		int c = World::Inferences::get_certainty(inf);
		if (known) {
			if ((prn == known) && (c != UNKNOWN_CE)) {
				if (where) *where = World::Inferences::where_inferred(inf);
				return c;
			}
			if ((prnbar == known) && (c != UNKNOWN_CE)) {
				if (where) *where = World::Inferences::where_inferred(inf);
				return -c;
			}
		}
	}
	return UNKNOWN_CE;
}

void World::Inferences::verify_prop_states(inference_subject *infs) {
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF) {
		property *prn = World::Inferences::get_property(inf);
		parse_node *val = World::Inferences::get_property_value(inf);
		kind *PK = Properties::Valued::kind(prn);
		kind *VK = Specifications::to_kind(val);
		if (Kinds::Compare::compatible(VK, PK) != ALWAYS_MATCH) {
			LOG("Property value given as $u not $u\n", VK, PK);
			current_sentence = inf->inferred_from;
			Problems::quote_source(1, current_sentence);
			Problems::quote_property(2, prn);
			Problems::quote_kind(3, VK);
			Problems::quote_kind(4, PK);
			Problems::Issue::handmade_problem(_p_(PM_LateInferenceProblem));
			Problems::issue_problem_segment(
				"You wrote %1, but that tries to set the value of the '%2' "
				"property to %3 - which must be wrong because this property "
				"has to be %4.");
			Problems::issue_problem_end();
		}
	}
}

parse_node *World::Inferences::get_prop_state(inference_subject *infs, property *prn) {
	if ((prn == NULL) || (infs == NULL)) return NULL;
	inference_subject *k;
	for (k = infs; k; k = InferenceSubjects::narrowest_broader_subject(k)) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, k, PROPERTY_INF) {
			property *known = World::Inferences::get_property(inf);
			if (known == prn) return World::Inferences::get_property_value(inf);
		}
	}
	return NULL;
}

parse_node *World::Inferences::get_prop_state_at(inference_subject *infs, property *prn,
	parse_node **where) {
	if ((prn == NULL) || (infs == NULL)) return NULL;
	inference_subject *k;
	for (k = infs; k; k = InferenceSubjects::narrowest_broader_subject(k)) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, k, PROPERTY_INF) {
			property *known = World::Inferences::get_property(inf);
			if (known == prn) {
				if (where) *where = World::Inferences::where_inferred(inf);
				return World::Inferences::get_property_value(inf);
			}
		}
	}
	return NULL;
}

parse_node *World::Inferences::get_prop_state_without_inheritance(inference_subject *infs,
	property *prn, parse_node **where) {
	if ((prn == NULL) || (infs == NULL)) return NULL;
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF) {
		property *known = World::Inferences::get_property(inf);
		if (known == prn) {
			if (where) *where = World::Inferences::where_inferred(inf);
			return World::Inferences::get_property_value(inf);
		}
	}
	return NULL;
}

@h Indexing properties of a subject.
This is where the detailed description of a given kind -- what properties it
has, and so on -- is generated.

=
void World::Inferences::index(OUTPUT_STREAM, inference_subject *infs, int brief) {
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF)
		if (World::Inferences::get_property(inf) == P_specification) {
			parse_node *spec = World::Inferences::get_property_value(inf);
			Index::dequote(OUT, Lexer::word_raw_text(Wordings::first_wn(ParseTree::get_text(spec))));
			HTML_TAG("br");
		}

	property *prn;
	LOOP_OVER(prn, property) Properties::set_indexed_already_flag(prn, FALSE);

	int c;
	for (c = CERTAIN_CE; c >= IMPOSSIBLE_CE; c--) {
		char *cert = "Text only put here to stop gcc -O2 wrongly reporting an error";
		if (c == UNKNOWN_CE) continue;
		switch(c) {
			case CERTAIN_CE:    cert = "Always"; break;
			case LIKELY_CE:     cert = "Usually"; break;
			case UNLIKELY_CE:   cert = "Usually not"; break;
			case IMPOSSIBLE_CE: cert = "Never"; break;
			case INITIALLY_CE:	cert = "Initially"; break;
		}
		World::Inferences::index_provided(OUT, infs, TRUE, c, cert, brief);
	}
	World::Inferences::index_provided(OUT, infs, FALSE, LIKELY_CE, "Can have", brief);
}

@ The following lists off the properties of the kind, with the given
state of being boolean, and the given certainty levels:

=
int World::Inferences::has_or_can_have(inference_subject *infs, property *prn) {
	if (Properties::is_either_or(prn)) {
		int has = World::Inferences::get_EO_state(infs, prn);
		if ((has == UNKNOWN_CE) && (World::Permissions::find(infs, prn, TRUE))) {
			if (Properties::EitherOr::stored_in_negation(prn))
				return LIKELY_CE;
			else
				return UNLIKELY_CE;
		}
		return has;
	}
	if (World::Permissions::find(infs, prn, TRUE)) return LIKELY_CE;
	return UNKNOWN_CE;
}

void World::Inferences::index_provided(OUTPUT_STREAM, inference_subject *infs, int bool, int c, char *cert, int brief) {
	int f = TRUE;
	property *prn;
	LOOP_OVER(prn, property) {
		if (Properties::is_shown_in_index(prn) == FALSE) continue;
		if (Properties::get_indexed_already_flag(prn)) continue;
		if (Properties::is_either_or(prn) != bool) continue;

		int state = World::Inferences::has_or_can_have(infs, prn);
		if (state != c) continue;
		int inherited_state = World::Inferences::has_or_can_have(
			InferenceSubjects::narrowest_broader_subject(infs), prn);
		if ((state == inherited_state) && (brief)) continue;

		if (f) { WRITE("<i>%s</i> ", cert); f = FALSE; }
		else WRITE(", ");
		WRITE("%+W", prn->name);
		Properties::set_indexed_already_flag(prn, TRUE);

		if (Properties::is_either_or(prn)) {
			property *prnbar = Properties::EitherOr::get_negation(prn);
			if (prnbar) {
				WRITE(" <i>not</i> %+W", prnbar->name);
				Properties::set_indexed_already_flag(prnbar, TRUE);
			}
		} else {
			kind *K = Properties::Valued::kind(prn);
			if (K) {
				WRITE(" (<i>"); Kinds::Textual::write(OUT, K); WRITE("</i>)");
			}
		}
	}
	if (f == FALSE) {
		WRITE(".");
		HTML_TAG("br");
	}
}

@h Indexing properties of a specific subject.
This only tells about specific property settings for a given instance.

=
void World::Inferences::index_specific(OUTPUT_STREAM, inference_subject *infs) {
	property *prn; int k = 0;
	LOOP_OVER(prn, property)
		if (Properties::is_shown_in_index(prn))
			if (Properties::is_either_or(prn)) {
				if (World::Permissions::find(infs, prn, TRUE)) {
					parse_node *P = NULL;
					int S = World::Inferences::get_EO_state_without_inheritance(infs, prn, &P);
					property *prnbar = Properties::EitherOr::get_negation(prn);
					if ((prnbar) && (S < 0)) continue;
					if (S != UNKNOWN_CE) {
						k++;
						if (k == 1) HTMLFiles::open_para(OUT, 1, "hanging");
						else WRITE("; ");
						if (S < 0) WRITE("not ");
						WRITE("%+W", prn->name);
						if (P) Index::link(OUT, Wordings::first_wn(ParseTree::get_text(P)));
					}
				}
			}
	if (k > 0) HTML_CLOSE("p");
	LOOP_OVER(prn, property)
		if (Properties::is_shown_in_index(prn))
			if (Properties::is_either_or(prn) == FALSE)
				if (World::Permissions::find(infs, prn, TRUE)) {
					parse_node *P = NULL;
					parse_node *S = World::Inferences::get_prop_state_without_inheritance(infs, prn, &P);
					if ((S) && (Wordings::nonempty(ParseTree::get_text(S)))) {
						HTMLFiles::open_para(OUT, 1, "hanging");
						WRITE("%+W: ", prn->name);
						HTML::begin_colour(OUT, I"000080");
						WRITE("%+W", ParseTree::get_text(S));
						HTML::end_colour(OUT);
						if (P) Index::link(OUT, Wordings::first_wn(ParseTree::get_text(P)));
						HTML_CLOSE("p");
					}
				}
}

@h Comparing inferences.
The following routine is a little like |strcmp|, the standard C routine
for comparing strings, in that it compares two inferences and returns a
value useful for sorting algorithms: 0 if equal, positive if |i1 < i2|,
negative if |i2 < i1|. This is a stable trichotomy; in particular,

	|World::Inferences::compare_inferences(I, J) == -World::Inferences::compare_inferences(J, I)|

for all pairs of inference pointers |I| and |J|.

More importantly, though, it measures how similar the two inferences are,
because the return value is always plus or minus one of the following.
The notation |CI_DIFFER_IN_WHATEVER| means that the two inferences do
not differ on all lower-order tests; thus, the higher the absolute value,
the more similar the inferences are. (|CI_IDENTICAL|, 0, is a special case;
this is returned only when the two inferences are literally the same
structure, i.e., |I == J|. Merely containing identical data is not enough.)

By convention, a pair of attached either/or properties which are negations of
each other -- say "open" and "closed" -- are treated as if they were the
same property but with different values.

@d CI_DIFFER_IN_EXISTENCE 1
@d CI_DIFFER_IN_TYPE 2
@d CI_DIFFER_IN_PROPERTY 3
@d CI_DIFFER_IN_INFS2 4
@d CI_DIFFER_IN_INFS1 5
@d CI_DIFFER_IN_PROPERTY_VALUE 6
@d CI_DIFFER_IN_COPY_ONLY 7
@d CI_IDENTICAL 0

@ Funny story: until 2019, this routine ran by using pointer subtraction when
comparing, for example, the INFS references in the inferences, on the principle
that the ordering doesn't really matter so long as it is definite and stable
during a run. But in the late 2010s, desktop operating systems such as MacOS
Mojave began to randomize the address space of all executables, to make it
harder for attackers to exploit buffer overflow bugs. As a result, although
the following routine continued to make definite orderings, they would be
randomly different from one run to another. Inform's output remained
functionally correct, but the generated I6 code would subtly differ from
run to run. And so we instead now incur the cost of looking up allocation IDs,
and indeed of storing those for inference structures.

Pointer subtraction is, in any case, frowned on in all the best houses, so this
was probably a good thing.

=
int World::Inferences::compare_inferences(inference *i1, inference *i2) {
	if (i1 == i2) return CI_IDENTICAL;
	if (i1 == NULL) return CI_DIFFER_IN_EXISTENCE;
	if (i2 == NULL) return -CI_DIFFER_IN_EXISTENCE;
	int c = i1->inference_type - i2->inference_type;
	if (c > 0) return CI_DIFFER_IN_TYPE; if (c < 0) return -CI_DIFFER_IN_TYPE;
	property *pr1 = i1->inferred_property;
	property *pr2 = i2->inferred_property;
	if ((pr1) && (Properties::is_either_or(pr1)) &&
		(pr2) && (Properties::is_either_or(pr2)) &&
		((pr1 == Properties::EitherOr::get_negation(pr2)) ||
		 (pr2 == Properties::EitherOr::get_negation(pr1)))) pr2 = pr1;
	c = World::Inferences::measure_property(pr1) - World::Inferences::measure_property(pr2);
	if (c > 0) return CI_DIFFER_IN_PROPERTY; if (c < 0) return -CI_DIFFER_IN_PROPERTY;
	c = World::Inferences::measure_infs(i1->infs_ref2) - World::Inferences::measure_infs(i2->infs_ref2);
	if (c > 0) return CI_DIFFER_IN_INFS2; if (c < 0) return -CI_DIFFER_IN_INFS2;
	c = World::Inferences::measure_infs(i1->infs_ref1) - World::Inferences::measure_infs(i2->infs_ref1);
	if (c > 0) return CI_DIFFER_IN_INFS1; if (c < 0) return -CI_DIFFER_IN_INFS1;
	c = World::Inferences::measure_pn(i1->spec_ref2) - World::Inferences::measure_pn(i2->spec_ref2);
	if (c > 0) return CI_DIFFER_IN_INFS2; if (c < 0) return -CI_DIFFER_IN_INFS2;
	c = World::Inferences::measure_pn(i1->spec_ref1) - World::Inferences::measure_pn(i2->spec_ref1);
	if (c > 0) return CI_DIFFER_IN_INFS1; if (c < 0) return -CI_DIFFER_IN_INFS1;
	c = World::Inferences::measure_inf(i1) - World::Inferences::measure_inf(i2);
	parse_node *val1 = i1->inferred_property_value;
	parse_node *val2 = i2->inferred_property_value;
	if ((i1->inferred_property != i2->inferred_property) ||
		((val1) && (val2) && (Rvalues::compare_CONSTANT(val1, val2) == FALSE))) {
		if (c > 0) return CI_DIFFER_IN_PROPERTY_VALUE;
		if (c < 0) return -CI_DIFFER_IN_PROPERTY_VALUE;
	}
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

int World::Inferences::measure_property(property *P) {
	if (P) return 1 + P->allocation_id;
	return 0;
}
int World::Inferences::measure_inf(inference *I) {
	if (I) return 1 + I->allocation_id;
	return 0;
}
int World::Inferences::measure_infs(inference_subject *IS) {
	if (IS) return 1 + IS->allocation_id;
	return 0;
}
int World::Inferences::measure_pn(parse_node *N) {
	if (N) return 1 + N->allocation_id;
	return 0;
}

int infs_diversion = TRUE;
void World::Inferences::diversion_on(void) {
	infs_diversion = TRUE;
}
void World::Inferences::diversion_off(void) {
	infs_diversion = FALSE;
}

inference_subject *World::Inferences::divert_infs(inference_subject *infs) {
	#ifdef IF_MODULE
	if (infs_diversion)
		if ((I_yourself) && (player_VAR) &&
			(infs == Instances::as_subject(I_yourself))) {
			parse_node *val = NonlocalVariables::get_initial_value(player_VAR);
			inference_subject *divert = InferenceSubjects::from_specification(val);
			if (divert) return divert;
		}
	#endif
	return infs;
}

@h Joining an inference to what is known about an object.
As the above will have made clear, it is not altogether easy to join a new
inference to the linked list of inferences which belong to a given subject: we
can't simply put it at the end of the list. The following routine looks simple
enough, but was a difficult one to get right.

The loop here completes if and only if the inference is safely joined to the
list; that is, if it is found to contradict or duplicate existing knowledge,
then the routine exits without completing the loop.

=
void World::Inferences::join_inference(inference *i, inference_subject *infs) {
	PROTECTED_MODEL_PROCEDURE;
	if (i == NULL) internal_error("joining null inference");
	if (infs == NULL) internal_error("joining to null inference subject");

	infs = World::Inferences::divert_infs(infs);

	int inserted = FALSE;
	inference *list, *prev;
	for (prev = NULL, list = InferenceSubjects::get_inferences(infs);
		(list) && (inserted == FALSE); prev = list, list = list->next) {

		int c = World::Inferences::compare_inferences(i, list);
		int d = c; if (d < 0) d = -d;
		int icl = i->certainty; if (icl < 0) icl = -icl;
		int lcl = list->certainty; if (lcl < 0) lcl = -lcl;

		int affinity_threshold;
		@<Determine the affinity threshold, which depends on the inference type@>;
		if (d >= affinity_threshold) {
			@<These relate to the same basic fact and one must exclude the other@>;
			return;
		}

		if (c<0) @<Insert the newly-drawn inference before this list position@>;
	}
	if (inserted == FALSE) @<Insert the newly-drawn inference before this list position@>;

	World::Inferences::report_inference(i, infs, "drawn");
	if (i->inference_type == PROPERTY_INF)
		Plugins::Call::property_value_notify(
			i->inferred_property, i->inferred_property_value);
}

@<Insert the newly-drawn inference before this list position@> =
	if (prev == NULL) InferenceSubjects::set_inferences(infs, i); else prev->next = i;
	i->next = list; inserted = TRUE;

@ The first question we must answer is when our two inferences are talking
about what is basically the same fact. We do this by requiring that the
absolute value of the |World::Inferences::compare_inferences| score -- which will always be
one of the |CI_*| constants enumerated above -- must exceed some threshold.
(Recall that higher scores mean greater similarity; the perfect |CI_IDENTICAL|
is not possible here.)

The threshold depends on what type of inference we're looking at, but it's
always at least half-way down the list, so we can be certain that

	|i->inference_type == list->inference_type|

(and therefore it's unambiguous what we mean by the type of inference being
looked at). For two property inferences to be talking about the same fact,
they might still differ in the property value -- one might say the carrying
capacity of a table is 10 and the other that it's 15, for example -- so
the threshold is set low enough for a score of |CI_DIFFER_IN_PROPERTY_VALUE|
still to get in. But with an arbitrary relation threshold, two inferences
never talk about the same fact unless they're essentially identical.

We set the affinity threshold purposely low for customised inferences
belonging to plugins (at present, anyway).

@<Determine the affinity threshold, which depends on the inference type@> =
	switch (list->inference_type) {
		case PROPERTY_INF: affinity_threshold = CI_DIFFER_IN_PROPERTY_VALUE; break;
		case ARBITRARY_RELATION_INF: affinity_threshold = CI_DIFFER_IN_COPY_ONLY; break;
		default: affinity_threshold = CI_DIFFER_IN_INFS1; break;
	}

@ So, let's suppose our new inference |i| is sufficiently close to the our
existing one, |list|. What then?

@<These relate to the same basic fact and one must exclude the other@> =
	if (icl != lcl) @<They have different certainties, so take the more certain to be true@>
	else {
		int contradiction_flag = FALSE;
		@<They are equally certain, so determine whether or not they contradict each other@>;
		if (contradiction_flag) {
			if (icl == CERTAIN_CE) @<Contradictions of certainty are forbidden, so issue a problem@>;
			if ((icl == LIKELY_CE) && (InferenceSubjects::get_default_certainty(infs) == LIKELY_CE))
				@<Later uncertain data beats earlier, for subjects which generalise about whole domains@>;
		}
		World::Inferences::report_inference(i, infs, "redundant");
	}

@ Where:

@<They have different certainties, so take the more certain to be true@> =
	if (lcl > icl) {
		World::Inferences::report_inference(i, infs, "discarded (we already know better)");
	} else {
		i->next = list->next;
		if (prev == NULL) InferenceSubjects::set_inferences(infs, i); else prev->next = i;
		World::Inferences::report_inference(i, infs, "replaced existing less certain one");
	}

@ Note that certainties opposite in sign reverse the issue of whether a
contradiction has occurred. The following, after all, do not conflict:

>> The box is always open. The box is never closed.

These will cause |contradiction_flag| to be initially set, below, but then
flipped back again because the certainties are opposite.

With an arbitrary relation inference, contradictions never occur. (Those
are always required to be positive in sense, i.e., with positive certainty,
and so clashed are impossible.)

@<They are equally certain, so determine whether or not they contradict each other@> =
	switch (list->inference_type) {
		case PROPERTY_INF:
			if (d == CI_DIFFER_IN_PROPERTY_VALUE) contradiction_flag = TRUE;
			break;
		default:
			if (Plugins::Call::inferences_contradict(list, i, d)) contradiction_flag = TRUE;
			break;
	}

	if (list->certainty == -i->certainty) contradiction_flag = (contradiction_flag)?FALSE:TRUE;

@<Contradictions of certainty are forbidden, so issue a problem@> =
	World::Inferences::report_inference(i, infs, "contradiction");
	World::Inferences::report_inference(list, infs, "with");
	if ((list->inference_type != PROPERTY_INF) &&
		(list->inference_type != ARBITRARY_RELATION_INF) &&
		(Plugins::Call::explain_contradiction(list, i, d, infs))) return;
	if (i->inference_type == PROPERTY_INF) {
		if (i->inferred_property == P_variable_initial_value)
		Problems::Issue::two_sentences_problem(_p_(PM_VariableContradiction),
			list->inferred_from,
			"this looks like a contradiction",
			"because the initial value of this variable seems to be being set "
			"in each of these sentences, but with a different outcome.");
		else {
			if (Properties::is_value_property(i->inferred_property)) {
				binary_predicate *bp =
					Properties::Valued::get_stored_relation(i->inferred_property);
				if (bp) {
					if (Wordings::match(ParseTree::get_text(current_sentence), ParseTree::get_text(list->inferred_from))) {
						Problems::quote_source(1, current_sentence);
						Problems::quote_relation(3, bp);
						Problems::quote_subject(4, infs);
						Problems::quote_spec(5, i->inferred_property_value);
						Problems::quote_spec(6, list->inferred_property_value);
						Problems::Issue::handmade_problem(_p_(PM_RelationContradiction2));
						Problems::issue_problem_segment(
							"I'm finding a contradiction at the sentence %1, "
							"because it means I can't set up %3. "
							"On the one hand, %4 should relate to %5, but on the other "
							"hand to %6, and this is a relation which doesn't allow "
							"such clashes.");
						Problems::issue_problem_end();
					} else {
						Problems::quote_source(1, current_sentence);
						Problems::quote_source(2, list->inferred_from);
						Problems::quote_relation(3, bp);
						Problems::quote_subject(4, infs);
						Problems::quote_spec(5, i->inferred_property_value);
						Problems::quote_spec(6, list->inferred_property_value);
						Problems::Issue::handmade_problem(_p_(PM_RelationContradiction));
						Problems::issue_problem_segment(
							"I'm finding a contradiction at the sentences %1 and %2, "
							"because between them they set up rival versions of %3. "
							"On the one hand, %4 should relate to %5, but on the other "
							"hand to %6, and this is a relation which doesn't allow "
							"such clashes.");
						Problems::issue_problem_end();
					}
					return;
				}
			}
			Problems::Issue::two_sentences_problem(_p_(PM_PropertyContradiction),
				list->inferred_from,
				"this looks like a contradiction",
				"because the same property seems to be being set in each of these sentences, "
				"but with a different outcome.");
		}
	} else
		#ifdef IF_MODULE
		if (i->inference_type == IS_ROOM_INF) {
		Problems::Issue::two_sentences_problem(_p_(PM_WhenIsARoomNotARoom),
			list->inferred_from,
			"this looks like a contradiction",
			"because apparently something would have to be both a room and not a "
			"room at the same time.");
	} else
		#endif
		Problems::Issue::two_sentences_problem(_p_(PM_Contradiction),
			list->inferred_from,
			"this looks like a contradiction",
			"which might be because I have misunderstood what was meant to be the subject "
			"of one or both of those sentences.");
	return;

@ When talking about kinds or kinds of value, we allow new merely likely
information to displace old; but not when talking about specific objects or
values, when the initial information stands. (This is to make it easier for
people to change the effect of extensions which create kinds and specify their
likely properties.)

@<Later uncertain data beats earlier, for subjects which generalise about whole domains@> =
	i->next = list->next;
	if (prev == NULL) InferenceSubjects::set_inferences(infs, i); else prev->next = i;
	World::Inferences::report_inference(i, infs, "replaced existing also only likely one");
	return;

@h Logging inferences.
We keep the debugging log file more than usually well informed about what
goes on with inferences, as there is obviously great potential for mystifying
bugs if inferences are incorrectly ignored.

=
void World::Inferences::report_inference(inference *i, inference_subject *infs, char *what_happened) {
	LOGIF(INFERENCES, ":::: %s: $j - $I\n", what_happened, infs, i);
}

@ And more generally:

=
void World::Inferences::log_kind(int it) {
	switch(it) {
		case ARBITRARY_RELATION_INF: LOG("ARBITRARY_RELATION_INF"); break;
		case PROPERTY_INF: LOG("PROPERTY_INF"); break;
		default: Plugins::Call::log_inference_type(it); break;
	}
}

void World::Inferences::log(inference *in) {
	if (in == NULL) { LOG("<null-inference>"); return; }
	World::Inferences::log_kind(in->inference_type);
	LOG("-");
	switch(in->certainty) {
		case IMPOSSIBLE_CE: LOG("Impossible "); break;
		case UNLIKELY_CE: LOG("Unlikely "); break;
		case UNKNOWN_CE: LOG("<No information> "); break;
		case LIKELY_CE: LOG("Likely "); break;
		case CERTAIN_CE: LOG("Certain "); break;
		default: LOG("<unknown-certainty>"); break;
	}
	if (in->inferred_property) LOG("(%W)", in->inferred_property->name);
	if (in->inferred_property_value) LOG("-1:$P", in->inferred_property_value);
	if (in->infs_ref1) LOG("-1:$j", in->infs_ref1);
	if (in->infs_ref2) LOG("-2:$j", in->infs_ref2);
	if (in->spec_ref1) LOG("-s1:$P", in->spec_ref1);
	if (in->spec_ref2) LOG("-s2:$P", in->spec_ref2);
}
