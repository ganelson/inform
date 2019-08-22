[Instances::] Instances.

To manage constant values of enumerated kinds, including kinds of
object.

@h Definitions.

@ Instances are named constants of kinds which have a finite range (unlike
"number", say), and where the possibilities are entirely up to the source
text to specify (unlike "truth state", say), and where the values form
part of the model world, so that inferences can be made about them, and
properties attached to them, and so on (unlike "rulebook", say). For
example, in

>> Colour is a kind of value. The colours are red, blue and green.

three instances are created: "red", "blue" and "green", which are
constants of kind "colour" made to differ from all other known "colour"
values (including each other). Objects are instances too:

>> Peter carries a blue ball.

creates two instances of "object" (though the world-model-completion code
will eventually make them instances of the subkind "thing" unless other
evidence turns up to suggest otherwise).

=
typedef struct instance {
	struct noun *tag;
	struct package_request *instance_package;
	struct inter_name *instance_iname;
	int instance_emitted;
	struct parse_node *creating_sentence; /* sentence creating the instance */
	struct parse_node *instance_of_set_at; /* and identifying its kind */
	struct inference_subject *as_subject;

	int enumeration_index; /* within each kind, named constants are counted from 1 */
	struct general_pointer connection; /* to the data structure for a constant of a kind significant to Inform */
	struct adjectival_phrase *usage_as_aph; /* if this is a noun used adjectivally, like "red" */

	int index_appearances; /* how many times have I appeared thus far in the World index? */
	struct instance_usage *first_noted_usage;
	struct instance_usage *last_noted_usage;
	MEMORY_MANAGEMENT
} instance;

@ We are going to record uses of these in the index, so:

=
typedef struct instance_usage {
	struct parse_node *where_instance_used;
	struct instance_usage *next;
} instance_usage;

@ We record the one most recently made:

= (early code)
instance *latest_instance = NULL;

@ We also need to keep track of three in particular:

@d NO_GRAMMATICAL_GENDERS 3

=
int no_ggs_recorded = 0;
instance *grammatical_genders[NO_GRAMMATICAL_GENDERS];

@h Creation.
Since this is the first of several "protected model procedures" in the
Inform source, a brief explanation. Inform's world model is brought into being
by assertion sentences; these are converted to logical propositions; and
the propositions then "asserted", a formal process of arranging the world
so that they become true. Since some propositions assert the existence of
instances, the process sometimes means calling the following routine.
What makes it "protected" is that it is not allowed to be called from
anywhere else, and any attempt to do so will throw an internal error. (This
ensures that we don't accidentally break the rule that the model world is
fully specified by the propositions concerning it.)

=
instance *Instances::new(wording W, kind *K) {
	PROTECTED_MODEL_PROCEDURE;
	@<Simplify the initial kind of the instance@>;
	property *cp = Properties::Conditions::get_coinciding_property(K);
	instance *I = CREATE(instance);
	@<Initialise the instance except for its noun@>;
	@<Make a noun for the new instance@>;
	Instances::set_kind(I, K);
	@<Add the new instance to its enumeration@>;
	Instances::iname(I);
	latest_instance = I;
	LOGIF(OBJECT_CREATIONS, "Created instance: $O (kind $u) (inter %n)\n", I, K, Instances::iname(I));
	Plugins::Call::new_named_instance_notify(I);
	if ((Kinds::Compare::eq(K, K_grammatical_gender)) &&
		(no_ggs_recorded < NO_GRAMMATICAL_GENDERS))
		grammatical_genders[no_ggs_recorded++] = I;
	Assertions::Assemblies::satisfies_generalisations(I->as_subject);
	return I;
}

@ If we don't know the kind, we assume "object"; if we're asked for a kind
more specific than "object", we make it just "object". (It will be refined
later on.)

@<Simplify the initial kind of the instance@> =
	if (K == NULL) K = K_object;
	K = Kinds::weaken(K);

@<Initialise the instance except for its noun@> =
	I->instance_package = NULL;
	I->instance_iname = NULL;
	I->instance_emitted = FALSE;
	I->creating_sentence = current_sentence;
	I->instance_of_set_at = current_sentence;
	I->usage_as_aph = NULL;
	I->enumeration_index = 0;
	I->connection = NULL_GENERAL_POINTER;
	I->index_appearances = 0;
	I->first_noted_usage = NULL;
	I->last_noted_usage = NULL;
	I->as_subject = InferenceSubjects::new(Kinds::Knowledge::as_subject(K),
		INST_SUB, STORE_POINTER_instance(I), CERTAIN_CE);

@ When we create instances of a kind whose name coincides with a property
used as a condition, as here:

>> A door can be ajar, sealed or wedged open.

we will need "ajar" and so on to be (in most contexts) adjectives rather
than nouns; so, even though they are instances, we give them blank nametags
to prevent them being parsed as nouns.

Otherwise, we have a choice of whether to allow ambiguous references or not.
Inform traditionally allows these for instances of object, but not for other
instances: thus "submarine green" (a colour, say) must be spelled out in
full, whereas a "tuna fish" (an object) can be called just "tuna".

@<Make a noun for the new instance@> =
	int exact_parsing = TRUE, any_parsing = TRUE;
	if ((cp) && (Properties::Conditions::of_what(cp))) any_parsing = FALSE;
	if (Kinds::Compare::le(K, K_object)) exact_parsing = FALSE;

	if (any_parsing) {
		if (exact_parsing)
			I->tag =
				Nouns::new_proper_noun(W, NEUTER_GENDER,
					REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT + ATTACH_TO_SEARCH_LIST_NTOPT,
					NAMED_CONSTANT_MC, Rvalues::from_instance(I));
		else
			I->tag =
				Nouns::new_proper_noun(W, NEUTER_GENDER,
					REGISTER_SINGULAR_NTOPT + ATTACH_TO_SEARCH_LIST_NTOPT,
					NOUN_MC, Rvalues::from_instance(I));
	} else {
		I->tag = Nouns::new_proper_noun(W, NEUTER_GENDER,
			REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT + ATTACH_TO_SEARCH_LIST_NTOPT,
			NOUN_HAS_NO_MC, NULL);
	}

@ The values in an enumerated kind such as our perpetual "colour" example
are numbered 1, 2, 3, ..., in order of creation. This is where we assign
those numbers, and also where we give corresponding adjectival meanings
in the kind in question is also a property.

There are two reasons why we don't do the same for objects: firstly, because
"object" has a whole hierarchy of subkinds, there's no unique numbering --
the same object may be thing number 17 but vehicle number 3 -- and secondly,
because we won't know the exact kind of objects until much later on; for now
the only thing we are sure of is that they are indeed objects. Enumerations
for objects within kinds is certainly useful, but it's harder to do and will
be done later on: see the "Instance Counts" plugin.

@<Add the new instance to its enumeration@> =
	if (!(Kinds::Compare::le(K, K_object))) {
		if (Kinds::Behaviour::has_named_constant_values(K) == FALSE)
			internal_error("tried to make an instance value for impossible kind");
		I->enumeration_index = Kinds::Behaviour::new_enumerated_value(K);
		if (cp) Instances::register_as_adjectival_constant(I, cp);
	}

@ =
parse_node *Instances::get_creating_sentence(instance *I) {
	if (I == NULL) return NULL;
	return I->creating_sentence;
}

@ =
source_file *Instances::get_creating_file(instance *I) {
	if (I == NULL) return NULL;
	return Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(I->creating_sentence)));
}

@h Coincidence with property names.
Suppose, as always, we have:

>> Colour is a kind of value. The colours are red, white and blue. A door has a colour.

The third sentence causes the following to be called, for the kind "colour"
and the property "colour", whose names coincide:

=
void Instances::make_kind_coincident(kind *K, property *P) {
	Properties::Conditions::set_coinciding_property(K, P);
	Instances::update_adjectival_forms(P);
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
	kind *K = Properties::Valued::kind(P);
	if (P == Properties::Conditions::get_coinciding_property(K)) {
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
		inference_subject *infs = World::Permissions::get_subject(pp);
		InferenceSubjects::make_adj_const_domain(infs, I, P);
	}
}

@h Logging.

=
void Instances::log(instance *I) {
	if (I== NULL) { LOG("<null instance>"); return; }
	if (Streams::I6_escapes_enabled(DL) == FALSE) LOG("I%d", I->allocation_id);
	Nouns::log(I->tag);
	if (!(Kinds::Compare::le(Instances::to_kind(I), K_object)))
		LOG("[$u]", Instances::to_kind(I));
}

@h As subjects.
Instances can be reasoned about, so they correspond to inference subjects.

=
int Instances::get_numerical_value(instance *I) {
	return I->enumeration_index;
}

inference_subject *Instances::as_subject(instance *I) {
	if (I == NULL) return NULL;
	return I->as_subject;
}

@h As mere names.

=
wording Instances::get_name(instance *I, int plural) {
	if ((I == NULL) || (I->tag == NULL)) return EMPTY_WORDING;
	return Nouns::get_name(I->tag, plural);
}

wording Instances::get_name_in_play(instance *I, int plural) {
	if ((I == NULL) || (I->tag == NULL)) return EMPTY_WORDING;
	return Nouns::get_name_in_play(I->tag, plural, language_of_play);
}

int Instances::full_name_includes(instance *I, vocabulary_entry *wd) {
	if (I == NULL) return FALSE;
	return Nouns::full_name_includes(I->tag, wd);
}

noun *Instances::get_noun(instance *I) {
	return I->tag;
}

text_stream *Instances::identifier(instance *I) {
	if (I == NULL) return I"nothing";
	return UseNouns::identifier(I->tag);
}

inter_name *Instances::iname(instance *I) {
	if (I == NULL) return NULL;
	if (I->instance_iname == NULL) {
		I->instance_package = Hierarchy::local_package(INSTANCES_HAP);
		UseNouns::noun_compose_identifier(I->instance_package, I->tag, I->allocation_id);
		I->instance_iname = UseNouns::iname(I->tag);
		Hierarchy::markup_wording(I->instance_package, INSTANCE_NAME_HMD, Nouns::get_name(I->tag, FALSE));
	}
	return I->instance_iname;
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
			inter_name *N = Instances::iname(I);
			if (Str::len(I->tag->nt_I6_identifier) > 0) WRITE("%S", I->tag->nt_I6_identifier);
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

@h Parsing (instances only).
Ordinarily these constants are read by the S-parser in the normal way that
all constants are read -- see the next chapter -- but it's occasionally
useful to bypass that and just parse text as an instance name and nothing
else. (We don't need to filter explicitly for the kind because only
instances have excerpts registered under |NOUN_MC|.)

=
instance *Instances::parse_object(wording W) {
	parse_node *p;
	if (Wordings::empty(W)) return NULL;
	if (<s-literal>(W)) return NULL;
	p = ExParser::parse_excerpt(NOUN_MC, W);
	if (p == NULL) return NULL;
	noun *nt = Nouns::disambiguate(p, MAX_NOUN_PRIORITY);
	if (nt == NULL) return NULL;
	if (Nouns::priority(nt) != LOW_NOUN_PRIORITY) return NULL;
	parse_node *pn = RETRIEVE_POINTER_parse_node(Nouns::tag_holder(nt));
	if (ParseTree::is(pn, CONSTANT_NT)) {
		kind *K = ParseTree::get_kind_of_value(pn);
		if (Kinds::Compare::le(K, K_object))
			return ParseTree::get_constant_instance(pn);
	}
	return NULL;
}

@ The first internal matches only instances of kinds within the objects;
the second matches the others; and the third all instances, of whatever kind.

=
<instance-of-object> internal {
	instance *I = Instances::parse_object(W);
	if (I) { *XP = I; return TRUE; }
	return FALSE;
}

<instance-of-non-object> internal {
	parse_node *p = ExParser::parse_excerpt(NAMED_CONSTANT_MC, W);
	instance *I = Rvalues::to_instance(p);
	if (I) { *XP = I; return TRUE; }
	return FALSE;
}

<instance> internal {
	if (<s-literal>(W)) return FALSE;
	W = Articles::remove_the(W);
	instance *I = Instances::parse_object(W);
	if (I) { *XP = I; return TRUE; }
	parse_node *p = ExParser::parse_excerpt(NAMED_CONSTANT_MC, W);
	I = Rvalues::to_instance(p);
	if (I) { *XP = I; return TRUE; }
	return FALSE;
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
	return InferenceSubjects::as_kind(inherits_from);
}

int Instances::of_kind(instance *I, kind *match) {
	if ((I == NULL) || (match == NULL)) return FALSE;
	return Kinds::Compare::le(Instances::to_kind(I), match);
}

@ Ordinarily, instances never change their kind, but instances of "object"
are allowed to refine it. Such revisions are allowed to specialise the kind
(e.g., by changing a "person" to a "man") but not to contradict it
(e.g., by changing a "supporter" to a "container").

=
void Instances::set_kind(instance *I, kind *new) {
	PROTECTED_MODEL_PROCEDURE;
	if (I == NULL) {
		LOG("Tried to set kind to $u\n", new);
		internal_error("Tried to set the kind of a null object");
	}
	kind *existing = Instances::to_kind(I);
	int m = Kinds::Compare::compatible(existing, new);
	if (m == ALWAYS_MATCH) return;
	if (m == NEVER_MATCH) {
		LOG("Tried to set kind of $O (existing $u) to $u\n", I, existing, new);
		@<Issue a problem message for a contradictory change of kind@>;
		return;
	}
	Plugins::Call::set_kind_notify(I, new);
	InferenceSubjects::falls_within(I->as_subject, Kinds::Knowledge::as_subject(new));
	Assertions::Assemblies::satisfies_generalisations(I->as_subject);
	I->instance_of_set_at = current_sentence;
	LOGIF(KIND_CHANGES, "Setting kind of $O to $u\n", I, new);
}

@<Issue a problem message for a contradictory change of kind@> =
	if (current_sentence != I->instance_of_set_at) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_source(2, I->instance_of_set_at);
		Problems::quote_kind(3, new);
		Problems::quote_kind(4, existing);
		Problems::Issue::handmade_problem(_p_(PM_KindsIncompatible));
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
		Problems::Issue::handmade_problem(_p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"You wrote %1, which made me think the kind of %2 was %4, "
			"but for other reasons I now think it ought to be %3, and those "
			"are incompatible. (If %3 were a kind of %4 or vice versa "
			"there'd be no problem, but they aren't.)");
		Problems::issue_problem_end();
	}

@ =
parse_node *Instances::get_kind_set_sentence(instance *I) {
	return I->instance_of_set_at;
}

@h Iteration schemes.

@d LOOP_OVER_INSTANCES(I, K)
	LOOP_OVER(I, instance)
		if (Instances::of_kind(I, K))

@d LOOP_OVER_ENUMERATION_INSTANCES(I)
	LOOP_OVER(I, instance)
		if (Kinds::Behaviour::is_an_enumeration(Instances::to_kind(I)))

@d LOOP_OVER_OBJECT_INSTANCES(I)
	LOOP_OVER_INSTANCES(I, K_object)

@ The number of instances of a given kind makes a neat example:

=
int Instances::count(kind *K) {
	int c = 0;
	instance *I;
	LOOP_OVER_INSTANCES(I, K) c++;
	return c;
}

@h Connections.
Some of Inform's plugins give special meanings to particular kinds, in such
a way that they need to be given additional structure. For example, the
Scenes plugin needs to make instances of "scene" more than mere names:
each one has to have rulebooks attached, and conditions for starting and
ending, and so on. To achieve this, each instance is allowed to have a
single pointer to another data structure.

This mechanism is used only by plugins. For instances of Inform's core
kinds, including "object", the connection is always blank.

=
void Instances::set_connection(instance *I, general_pointer gp) {
	I->connection = gp;
}

general_pointer Instances::get_connection(instance *I) {
	return I->connection;
}

@h Indexing count.
This simply avoids repetitions in the World index.

=
void Instances::increment_indexing_count(instance *I) {
	I->index_appearances++;
}

int Instances::indexed_yet(instance *I) {
	if (I->index_appearances > 0) return TRUE;
	return FALSE;
}

@ Not every instance has a name, which is a nuisance for the index:

=
void Instances::index_name(OUTPUT_STREAM, instance *I) {
	wording W = Instances::get_name_in_play(I, FALSE);
	if (Wordings::nonempty(W)) {
		WRITE("%+W", W);
		return;
	}
	kind *K = Instances::to_kind(I);
	W = Kinds::Behaviour::get_name_in_play(K, FALSE, language_of_play);
	if (Wordings::nonempty(W)) {
		WRITE("%+W", W);
		return;
	}
	WRITE("nameless");
}

@ =
void Instances::note_usage(instance *I, parse_node *NB) {
	if (I->last_noted_usage) {
		if (NB == I->last_noted_usage->where_instance_used) return;
	}
	instance_usage *IU = CREATE(instance_usage);
	IU->where_instance_used = NB;
	IU->next = NULL;
	if (I->last_noted_usage == NULL) {
		I->first_noted_usage = IU;
		I->last_noted_usage = IU;
	} else {
		I->last_noted_usage->next = IU;
		I->last_noted_usage = IU;
	}
}

void Instances::index_usages(OUTPUT_STREAM, instance *I) {
	int k = 0;
	instance_usage *IU = I->first_noted_usage;
	for (; IU; IU = IU->next) {
		parse_node *at = IU->where_instance_used;
		if (at) {
			source_file *sf = Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(at)));
			if (sf == primary_source_file) {
				k++;
				if (k == 1) {
					HTMLFiles::open_para(OUT, 1, "tight");
					WRITE("<i>mentioned in rules:</i> ");
				} else WRITE("; ");
				Index::link(OUT, Wordings::first_wn(ParseTree::get_text(at)));
			}
		}
	}
	if (k > 0) HTML_CLOSE("p");
}

@h As subjects.
Some methods for instances as inference subjects:

=
wording Instances::SUBJ_get_name_text(inference_subject *from) {
	instance *I = InferenceSubjects::as_nc(from);
	return Instances::get_name(I, FALSE);
}

general_pointer Instances::SUBJ_new_permission_granted(inference_subject *from) {
	return STORE_POINTER_property_of_value_storage(
		Properties::OfValues::get_storage());
}

void Instances::SUBJ_complete_model(inference_subject *infs) {
}

void Instances::SUBJ_check_model(inference_subject *infs) {
}

@ See below.

=
void Instances::SUBJ_make_adj_const_domain(inference_subject *S,
	instance *I, property *P) {
	Instances::make_adj_const_domain(I, P, NULL, InferenceSubjects::as_instance(S));
}

@ Since all instances are single values, testing for inclusion under such a
subject is very simple:

=
int Instances::SUBJ_emit_element_of_condition(inference_subject *infs, inter_symbol *t0_s) {
	instance *I = InferenceSubjects::as_nc(infs);
	Emit::inv_primitive(Produce::opcode(EQ_BIP));
	Emit::down();
		Emit::val_symbol(K_value, t0_s);
		Emit::val_iname(K_value, Instances::iname(I));
	Emit::up();
	return TRUE;
}

@ Here's how to place the instance objects in order. The ordering is used not
only for compilation, but also for instance counting (e.g., marking the
black gate as the 8th instance of "door"), so it's needed earlier than
the compilation phase, too.

Code wanting to create an ordering should first call |begin_sequencing_objects|
and then send the objects, in turn, via |place_this_object_next|.

They are stored as a linked list with the links in an array indexed by the
allocation IDs of the objects.

=
instance **objects_in_compilation_list = NULL;
instance *first_object_in_compilation_list = NULL;
instance *last_object_in_compilation_list = NULL;

void Instances::begin_sequencing_objects(void) {
	int i, nc = NUMBER_CREATED(instance);
	if (objects_in_compilation_list == NULL) {
		objects_in_compilation_list = (instance **)
			(Memory::I7_calloc(nc, sizeof(instance *), OBJECT_COMPILATION_MREASON));
	}
	for (i=0; i<nc; i++) objects_in_compilation_list[i] = NULL;
	first_object_in_compilation_list = NULL;
	last_object_in_compilation_list = NULL;
}

void Instances::place_this_object_next(instance *I) {
	if (last_object_in_compilation_list == NULL)
		first_object_in_compilation_list = I;
	else
		objects_in_compilation_list[last_object_in_compilation_list->allocation_id] = I;
	last_object_in_compilation_list = I;
}

@ For instance, here we put them in order of definition, which is the default.
Note that only instances, not kinds, appear.

=
void Instances::place_objects_in_definition_sequence(void) {
	Instances::begin_sequencing_objects();
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		Instances::place_this_object_next(I);
}

@ And we read the order back using these macros:

@d FIRST_IN_COMPILATION_SEQUENCE first_object_in_compilation_list
@d NEXT_IN_COMPILATION_SEQUENCE(I) objects_in_compilation_list[I->allocation_id]
@d LOOP_OVER_OBJECTS_IN_COMPILATION_SEQUENCE(I)
	for (I=FIRST_IN_COMPILATION_SEQUENCE; I; I=NEXT_IN_COMPILATION_SEQUENCE(I))

@ Compilation looks tricky only because we need to compile instances in a
set order which is not the order of their creation. (This is because objects
must be compiled in containment-tree traversal order in the final Inform 6
code.) So in reply to a request to compile all instances, we first delegate
the object instances, then compile the non-object ones (all just constant
declarations) and finally return |TRUE| to indicate that the task is finished.

=
int Instances::SUBJ_compile_all(void) {
	instance *I;
	LOOP_OVER_OBJECTS_IN_COMPILATION_SEQUENCE(I)
		Instances::SUBJ_compile(Instances::as_subject(I));
	LOOP_OVER(I, instance)
		if (Kinds::Compare::le(Instances::to_kind(I), K_object) == FALSE)
			Instances::SUBJ_compile(Instances::as_subject(I));
	#ifdef IF_MODULE
	PL::Naming::compile_small_names();
	#endif
	return TRUE;
}

@ Either way, the actual compilation happens here:

=
void Instances::SUBJ_compile(inference_subject *infs) {
	instance *I = InferenceSubjects::as_nc(infs);
	Instances::emitted_iname(I);
	Properties::emit_instance_permissions(I);
	Properties::Emit::emit_subject(infs);
}

inter_name *Instances::emitted_iname(instance *I) {
	if (I == NULL) return NULL;
	inter_name *iname = Instances::iname(I);
	if (I->instance_emitted == FALSE) {
		I->instance_emitted = TRUE;
		Emit::instance(iname, Instances::to_kind(I), I->enumeration_index);
	}
	return iname;
}

package_request *Instances::package(instance *I) {
	Instances::iname(I); // Thus forcing this to exist...
	return I->instance_package;
}

@h Adjectival uses of instances.
Some constant names can be used adjectivally, but not others. This happens
when their kind's name coincides with a name for a property, as might for
instance happen with "colour". In other words, because it is reasonable
that a ball might have a colour, we can declare that "the ball is green",
or speak of "something blue": whereas we are not allowed to use "score to
beat" adjectivally since (a) it is a variable, and (b) "number" is not a
coinciding property: we would not ordinarily write "the ball is 4". (A
quirk in English does allow this, implicitly construing number as an age
property, but we don't go there in Inform.)

These adjectives are easy to handle:

=
adjectival_phrase *Instances::get_adjectival_phrase(instance *I) {
	return I->usage_as_aph;
}

adjective_meaning *Instances::ADJ_parse(parse_node *pn,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	return NULL;
}

void Instances::ADJ_compiling_soon(adjective_meaning *am, instance *I, int T) {
}

int Instances::ADJ_compile(instance *I, int T, int emit_flag, ph_stack_frame *phsf) {
	return FALSE;
}

@ Asserting such an adjective simply asserts its property. We refuse to assert
the falseness of such an adjective since it's unclear what to infer from, e.g.,
"the ball is not green": we would need to give it a colour, and there's no
good basis for choosing which.

=
int Instances::ADJ_assert(instance *I,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	if (parity == FALSE) return FALSE;
	property *P = Properties::Conditions::get_coinciding_property(Instances::to_kind(I));
	if (P == NULL) internal_error("enumerative adjective on non-property");
	World::Inferences::draw_property(infs_to_assert_on, P, Rvalues::from_instance(I));
	return TRUE;
}

@ Some pretty-printing for the index, and we're done.

=
int Instances::ADJ_index(OUTPUT_STREAM, instance *I) {
	property *P = Properties::Conditions::get_coinciding_property(Instances::to_kind(I));
	if (Properties::Conditions::of_what(P) == NULL) {
		if (Properties::permission_list(P)) {
			WRITE("(of "); World::Permissions::index(OUT, P); WRITE(") ");
		}
		WRITE("having this %+W", P->name);
	} else {
		WRITE("a condition which is otherwise ");
		kind *K = Instances::to_kind(I);
		int no_alts = Instances::count(K) - 1, i = 0;
		instance *alt;
		LOOP_OVER_INSTANCES(alt, K)
			if (alt != I) {
				WRITE("</i>");
				WRITE("%+W", Instances::get_name(alt, FALSE));
				WRITE("<i>");
				i++;
				if (i == no_alts-1) WRITE(" or ");
				else if (i < no_alts) WRITE(", ");
			}
	}
	return TRUE;
}

@h Adjectival domains.
Let's reconstruct the chain of events, shall we? It has been found that an
instance, though a noun, must be used as an adjective: for example, "red".
Inform has run through the permissions for the property ("colour") in
question, and found that, say, it's a property of doors, scenes and also
a single piece of litmus paper. Each of these three is an inference subject,
so |InferenceSubjects::make_adj_const_domain| was called for each in turn.
By different means, those calls all ended up by passing the buck onto the
following routine: twice with the domain |set| being a kind (door and then
scene), once with |set| being null and |singleton| being an instance
(the litmus paper).

=
void Instances::make_adj_const_domain(instance *I, property *P,
	kind *set, instance *singleton) {
	kind *D = NULL;
	@<Find the kind domain within which the adjective applies@>;
	adjective_meaning *am = NULL;
	@<Create the adjective meaning for this use of the instance@>;
	@<Write I6 schemas for asserting and testing this use of the instance@>;
}

@<Find the kind domain within which the adjective applies@> =
	if (singleton) D = Instances::to_kind(singleton);
	else if (set) D = set;
	if (D == NULL) internal_error("No adjectival constant domain");

@<Create the adjective meaning for this use of the instance@> =
	wording NW = Instances::get_name(I, FALSE);
	am = Adjectives::Meanings::new(ENUMERATIVE_KADJ,
		STORE_POINTER_instance(I), NW);
	I->usage_as_aph = Adjectives::Meanings::declare(am, NW, 4);
	if (singleton) Adjectives::Meanings::set_domain_from_instance(am, singleton);
	else if (set) Adjectives::Meanings::set_domain_from_kind(am, set);

@<Write I6 schemas for asserting and testing this use of the instance@> =
	i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
	Calculus::Schemas::modify(sch,
		"GProperty(%k, *1, %n) == %d",
			D, Properties::iname(P), I->enumeration_index);
	sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, FALSE);
	Calculus::Schemas::modify(sch,
		"WriteGProperty(%k, *1, %n, %d)",
			D, Properties::iname(P), I->enumeration_index);
