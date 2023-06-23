[Instances::] Instances.

To manage constant values of enumerated kinds or kinds of object.

@ Instances are named constants giving a finite range of possible values of
a kind,[1] where these are chosen by the author.[2] Instances are can have
properties, and can have inferences drawn about them: see //Instance Subjects//.

Most instances are created by assertions in the source text. For example:

>> Colour is a kind of value. The colours are red, blue and green.

creates three instances: "red", "blue" and "green", which enumerate the
possible range of "colour". Objects are instances too:

>> Peter carries a blue ball.

"Peter" and "blue ball" are initially created as instances of the kind "object",
but will later be deduced to be of kind "person" and "thing" respectively.
As this demonstrates, an instance can have its kind specialised (that is,
changed to a subkind of its current kind) after creation: see //Instances::set_kind//.

[1] So there are no instances of "number" or "text", for example.

[2] The values "true" and "false" do exhaust the possibilities for "truth state",
but these are hard-wired into Inform and are not instances, because "truth state"
is not an enumeration.

@ Note that the kind is not explicitly stored in the |instance| structure: it
has to be deduced from the position of the instance's subject in the subjects
hierarchy. See //Instances::to_kind//.

=
typedef struct instance {
	struct noun *as_noun; /* the name of the instance */
	struct adjective *as_adjective; /* if this is a noun used adjectivally, like "red" */
	struct inference_subject *as_subject; /* from which the kind can be deduced */

	struct parse_node *creating_sentence; /* sentence creating the instance */
	struct parse_node *where_kind_is_set; /* sentence identifying its kind */

	int enumeration_index; /* within each non-object kind, instances are counted from 1 */

	struct instance_compilation_data compilation_data; /* see //runtime: Instances// */
	CLASS_DEFINITION
} instance;

@ We record the one most recently made:

=
instance *latest_instance = NULL;

instance *Instances::latest(void) {
	return latest_instance;
}

@ And this is where they are made:

=
instance *Instances::new(wording W, kind *K) {
	PROTECTED_MODEL_PROCEDURE;
	@<Simplify the initial kind of the instance@>;
	instance *I = CREATE(instance);
	@<Initialise the instance@>;
	@<Add the new instance to its enumeration@>;

	LOGIF(OBJECT_CREATIONS, "Created instance: $O (kind %u) (inter %n)\n",
		I, K, RTInstances::value_iname(I));

	latest_instance = I;
	PluginCalls::new_named_instance_notify(I);
	if (Kinds::eq(K, K_grammatical_gender)) Instances::new_grammatical(I);

	Assertions::Assemblies::satisfies_generalisations(I->as_subject);
	return I;
}

@ If we don't know the kind, we assume "object"; if we're asked for a kind
more specific than "object", we nevertheless make it just "object" for now.
(It will be specialised later on.)

@<Simplify the initial kind of the instance@> =
	if (K == NULL) K = K_object;
	K = Kinds::weaken(K, K_object);

@<Initialise the instance@> =
	I->creating_sentence = current_sentence;
	I->where_kind_is_set = current_sentence;
	I->as_adjective = NULL;
	I->enumeration_index = 0;
	I->as_subject = InstanceSubjects::new(I, K);
	InstancesPreform::create_as_noun(I, K, W);
	Instances::set_kind(I, K);
	I->compilation_data = RTInstances::new_compilation_data(I);

@ The values in an enumerated kind such as our perpetual "colour" example
are numbered 1, 2, 3, ..., in order of creation. This is where we assign
those numbers, and also where we give corresponding adjectival meanings
in the kind in question is also a property.

There are two reasons why we don't do the same for objects: firstly, because
"object" has a whole hierarchy of subkinds, there's no unique numbering --
the same object may be thing number 17 but vehicle number 3 -- and secondly,
because we won't know the exact kind of objects until much later on; for now
the only thing we are sure of is that they are indeed objects. Enumeration
for objects within kinds is certainly useful, but it's harder to do and will
be done later on: see //runtime: Instance Counting//.

@<Add the new instance to its enumeration@> =
	if (!(Kinds::Behaviour::is_object(K))) {
		if (Kinds::Behaviour::has_named_constant_values(K) == FALSE)
			internal_error("tried to make an instance value for impossible kind");
		I->enumeration_index = Kinds::Behaviour::new_enumerated_value(K);
		property *cp = Properties::property_with_same_name_as(K);
		if (cp) Instances::register_as_adjectival_constant(I, cp);
	}

@h Name and number.

=
wording Instances::get_name(instance *I, int plural) {
	if ((I == NULL) || (I->as_noun == NULL)) return EMPTY_WORDING;
	return Nouns::nominative(I->as_noun, plural);
}

wording Instances::get_name_in_play(instance *I, int plural) {
	if ((I == NULL) || (I->as_noun == NULL)) return EMPTY_WORDING;
	return Nouns::nominative_in_language(I->as_noun, plural,
		Projects::get_language_of_play(Task::project()));
}

noun *Instances::get_noun(instance *I) {
	return I->as_noun;
}

int Instances::get_numerical_value(instance *I) {
	return I->enumeration_index;
}

void Instances::write_name(OUTPUT_STREAM, instance *I) {
	wording W = Instances::get_name_in_play(I, FALSE);
	if (Wordings::nonempty(W)) {
		WRITE("%+W", W);
	} else {
		kind *K = Instances::to_kind(I);
		W = Kinds::Behaviour::get_name_in_play(K, FALSE,
			Projects::get_language_of_play(Task::project()));
		if (Wordings::nonempty(W)) WRITE("%+W", W);
		else WRITE("nameless");
	}
}

@h Subject and source references.

=
inference_subject *Instances::as_subject(instance *I) {
	if (I == NULL) return NULL;
	return I->as_subject;
}

adjective *Instances::as_adjective(instance *I) {
	if (I == NULL) return NULL;
	return I->as_adjective;
}

parse_node *Instances::get_creating_sentence(instance *I) {
	if (I == NULL) return NULL;
	return I->creating_sentence;
}

source_file *Instances::get_creating_file(instance *I) {
	if (I == NULL) return NULL;
	return Lexer::file_of_origin(
		Wordings::first_wn(Node::get_text(I->creating_sentence)));
}

@h Coincidence with property names.
Suppose, as always, we have:

>> Colour is a kind of value. The colours are red, white and blue. A door has a colour.

The third sentence causes the following to be called, for the kind "colour"
and the property "colour", whose names coincide:

=
void Instances::make_kind_coincident(kind *K, property *P) {
	Properties::mark_kind_as_having_same_name_as(K, P);
	Instances::update_adjectival_forms(P);
	if (Kinds::eq(K, K_grammatical_gender)) P_grammatical_gender = P;
}

@ That causes us to "update adjectival forms" for the property "colour",
a sort of general round-up to make sure that all of its possible applications
are covered by suitable adjectives. For instance, "red" must be registered
as an adjectival constant to cover doors. We will call this again if a further
use of colour turns up subsequently, e.g., in response to:

>> A vehicle has a colour.

=
void Instances::update_adjectival_forms(property *P) {
	if (Properties::is_either_or(P) == TRUE) return;
	kind *K = ValueProperties::kind(P);
	if (P == Properties::property_with_same_name_as(K)) {
		instance *I;
		LOOP_OVER_INSTANCES(I, K)
			Instances::register_as_adjectival_constant(I, P);
	}
}

@ So here is where we need to make "red", "white" or "blue" adjectives
specifying colour. And we will also call this if a further instance of colour
turns up subsequently, e.g., in response to

>> Mauve is a colour.

=
void Instances::register_as_adjectival_constant(instance *I, property *P) {
	property_permission *pp;
	LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, P) {
		inference_subject *infs = PropertyPermissions::get_subject(pp);
		InferenceSubjects::make_adj_const_domain(infs, I, P);
	}
}

@h The kind of an instance.
By this of course we mean the most specific kind to which an instance
belongs: if we write

>> Kathy is a woman.

then the Kathy instance is also a person, a thing, an object and a value,
but when we talk about the kind of Kathy, we mean "woman".

Note that this is not stored as a field in the instance structure, because
that would be redundant. Inform already knows which subjects are more
specialised than which other ones, and by making a call, we can find out.

=
kind *Instances::to_kind(instance *I) {
	if (I == NULL) return NULL;
	inference_subject *inherits_from = InferenceSubjects::narrowest_broader_subject(I->as_subject);
	return KindSubjects::to_kind(inherits_from);
}

int Instances::of_kind(instance *I, kind *match) {
	if ((I == NULL) || (match == NULL)) return FALSE;
	return Kinds::conforms_to(Instances::to_kind(I), match);
}

@ Ordinarily, instances never change their kind, but instances of "object"
are allowed to refine it. Such revisions are allowed to specialise the kind
(e.g., by changing a "person" to a "man") but not to contradict it
(e.g., by changing a "supporter" to a "container").

=
void Instances::set_kind(instance *I, kind *new) {
	PROTECTED_MODEL_PROCEDURE;
	if (I == NULL) {
		LOG("Tried to set kind to %u\n", new);
		internal_error("Tried to set the kind of a null object");
	}
	kind *existing = Instances::to_kind(I);
	int m = Kinds::compatible(existing, new);
	if (m == ALWAYS_MATCH) return;
	if (m == NEVER_MATCH) {
		LOG("Tried to set kind of $O (existing %u) to %u\n", I, existing, new);
		@<Issue a problem message for a contradictory change of kind@>;
		return;
	}
	PluginCalls::set_kind_notify(I, new);
	InferenceSubjects::falls_within(I->as_subject, KindSubjects::from_kind(new));
	Assertions::Assemblies::satisfies_generalisations(I->as_subject);
	I->where_kind_is_set = current_sentence;
	LOGIF(KIND_CHANGES, "Setting kind of $O to %u\n", I, new);
}

@<Issue a problem message for a contradictory change of kind@> =
	if (current_sentence != I->where_kind_is_set) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_source(2, I->where_kind_is_set);
		Problems::quote_kind(3, new);
		Problems::quote_kind(4, existing);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindsIncompatible));
		Problems::issue_problem_segment(
			"You wrote %1, but that seems to contradict %2, as %3 and %4 "
			"are incompatible. (If %3 were a kind of %4 or vice versa "
			"there'd be no problem, but they aren't.)");
		Problems::issue_problem_end();
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_object(2, I);
		Problems::quote_kind(3, new);
		Problems::quote_kind(4, existing);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"You wrote %1, which made me think the kind of %2 was %4, "
			"but for other reasons I now think it ought to be %3, and those "
			"are incompatible. (If %3 were a kind of %4 or vice versa "
			"there'd be no problem, but they aren't.)");
		Problems::issue_problem_end();
	}

@ =
parse_node *Instances::get_kind_set_sentence(instance *I) {
	return I->where_kind_is_set;
}

@h Iterating through instances of a kind.
The number of instances of a given kind makes a neat example of a commonly
needed loop.

@d LOOP_OVER_INSTANCES(I, K)
	LOOP_OVER(I, instance)
		if (Instances::of_kind(I, (K)))

=
int Instances::count(kind *K) {
	int c = 0;
	instance *I;
	LOOP_OVER_INSTANCES(I, K) c++;
	return c;
}

@h Instances of grammatical gender.
//assertions: The Creator// needs to know the names of the grammatical genders,
so we keep track of them here.

@d NO_GRAMMATICAL_GENDERS 3

=
int no_ggs_recorded = 0;
instance *grammatical_genders[NO_GRAMMATICAL_GENDERS];

instance *Instances::grammatical(int g) {
	if (no_ggs_recorded != NO_GRAMMATICAL_GENDERS) return NULL;
	return grammatical_genders[g-1];
}

void Instances::new_grammatical(instance *I) {
	if (no_ggs_recorded < NO_GRAMMATICAL_GENDERS)
		grammatical_genders[no_ggs_recorded++] = I;
}

@h Instances specified in Neptune files.

=
void Instances::make_instances_from_Neptune(void) {
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		linked_list *L = KindConstructors::instances(kc);
		kind_constructor_instance *kci;
		inter_ti current_val = 1;
		int first_val = TRUE;
		LOOP_OVER_LINKED_LIST(kci, kind_constructor_instance, L) {
			wording W = Feeds::feed_text(kci->natural_language_name);
			kind *K = Kinds::base_construction(kc);
			pcalc_prop *prop = Propositions::Abstract::to_create_something(K, W);
			Assert::true(prop, CERTAIN_CE);
			instance *I = Instances::latest();
			if (kci->value_specified) {
				if ((current_val >= (inter_ti) kci->value) && (first_val == FALSE)) {
					Problems::quote_object(1, I);
					Problems::quote_kind(2, K);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
					Problems::issue_problem_segment(
						"A kit defined an instance %1 of a kind called %2, but this "
						"has a numerical value which is equal to or greater than that "
						"of its predecessor. Instances in a kit have to be defined "
						"in evaluation order.");
					Problems::issue_problem_end();
				}
				current_val = (inter_ti) kci->value;
			}
			RTKindConstructors::set_explicit_runtime_instance_value(K, I, current_val);
			RTInstances::set_translation(I, kci->identifier);
			// LOG("From kit: %W = %S = %d -> $O\n", W, kci->identifier, current_val, I);
			current_val++;
			first_val = FALSE;
		}
	}
}

@h Logging.

=
void Instances::log(instance *I) {
	Instances::write(DL, I);
}

void Instances::write(OUTPUT_STREAM, instance *I) {
	if (I== NULL) { WRITE("<null instance>"); return; }
	if (Streams::I6_escapes_enabled(DL) == FALSE) WRITE("I%d", I->allocation_id);
	Nouns::write(OUT, I->as_noun);
	if (!(Kinds::Behaviour::is_object(Instances::to_kind(I)))) {
		WRITE("[");
		Kinds::Textual::write(OUT, Instances::to_kind(I));
		WRITE("]");
	}
}

@h Writer.

=
void Instances::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	instance *I = (instance *) vI;
	if (I == NULL) WRITE("nothing");
	else switch (format_string[0]) {
		case 'I': /* bare |%I| means the same as |%+I|, so fall through to... */
		case '+': @<Write the instance raw@>; break;
		case '-': @<Write the instance with normalised casing@>; break;
		case '~': {
			inter_name *N = RTInstances::value_iname(I);
			if (Str::len(NounIdentifiers::identifier(I->as_noun)) > 0)
				WRITE("%S", NounIdentifiers::identifier(I->as_noun));
			else WRITE("%n", N);
			break;
		}
		default: internal_error("bad %I modifier");
	}
}

@<Write the instance raw@> =
	wording W = Instances::get_name(I, FALSE);
	if (Wordings::nonempty(W)) WRITE("%+W", W);
	else {
		WRITE("nameless ");
		kind *K = Instances::to_kind(I);
		W = Kinds::Behaviour::get_name(K, FALSE);
		if (Wordings::nonempty(W)) WRITE("%+W", W);
	}

@<Write the instance with normalised casing@> =
	wording W = Instances::get_name(I, FALSE);
	if (Wordings::nonempty(W)) WRITE("%W", W);
	else {
		WRITE("nameless ");
		kind *K = Instances::to_kind(I);
		W = Kinds::Behaviour::get_name(K, FALSE);
		if (Wordings::nonempty(W)) WRITE("%W", W);
	}
