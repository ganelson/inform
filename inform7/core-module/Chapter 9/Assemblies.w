[Assertions::Assemblies::] Assemblies.

To build the complex multi-object assemblies which result from
allowing the source text to say things like "in every room is a vehicle".

@h Definitions.

@ Assemblies are made when an object of a given kind is created, and when
generalisations about that kind mean that further creations are also
needed. For instance: if a generalisation has said that every container
contains a shoe, then each time a container is created, we also need to
create a shoe, and assert a spatial relationship between them.

In practice we do this by a simple process which involves cutting and
pasting of subtrees of the parse tree, which motivates the following
data structure.

@ Generalisations are essentially fragments of parse tree stored for later use.
They handle sentences like

>> In every container is a coin.

which are done by recognising the prototype part ("in every container") in
the parse tree and grafting on a duplicate of the assembly part ("a coin")
in place of the |EVERY_NT| subtree ("every container"). Sometimes the EVERY
subtree is the whole prototype subtree ("Every coin is on a table"), in
which case |px| and |substitute_at| in the following structure coincide.

Each kind (in this example "container") keeps a linked list of the
generalisations which apply to it.

=
typedef struct generalisation {
	struct parse_node *look_for; /* prototype situation to look for */
	struct parse_node *what_to_make; /* subtree for what to assemble */
	struct parse_node *substitute_at; /* position under |look_for| of the EVERY node */
	struct generalisation *next; /* next in list of generalisations about kind */
	CLASS_DEFINITION
} generalisation;

@ For reasons to do with timing, each object needs to keep track of which
generalisations have and have not yet applied to it. In practice, this is
a list of pairs $(K, g)$ where $K$ is a kind and $g$ is the most recent one
applied from $K$'s list.

=
typedef struct application {
	struct inference_subject *generalisation_owner;
	struct generalisation *latest_applied;
	struct application *next;
} application;

@ These structures are combined in the following packet of data attached to
each inference subject:

=
typedef struct assemblies_data {
	struct generalisation *generalisation_list; /* kinds only: assembly instructions, if any */
	struct application *applications_so_far; /* instances only: progress */
	struct inference_subject *named_after; /* name derived from another: e.g. "Jane's nose" */
	struct wording named_after_text; /* text of the derived part, e.g. "nose" */
} assemblies_data;

@h Initialisation.

=
void Assertions::Assemblies::initialise_assemblies_data(assemblies_data *ad) {
	ad->generalisation_list = NULL;
	ad->applications_so_far = NULL;
	ad->named_after = NULL;
	ad->named_after_text = EMPTY_WORDING;
}

@ Setting the naming-after information.

=
void Assertions::Assemblies::name_object_after(inference_subject *infs, inference_subject *after, wording W) {
	assemblies_data *ad = InferenceSubjects::get_assemblies_data(infs);
	ad->named_after = after;
	ad->named_after_text = W;
}

@ And reading it again.

=
inference_subject *Assertions::Assemblies::what_this_is_named_after(inference_subject *infs) {
	assemblies_data *ad = InferenceSubjects::get_assemblies_data(infs);
	return ad->named_after;
}

wording Assertions::Assemblies::get_named_after_text(inference_subject *infs) {
	assemblies_data *ad = InferenceSubjects::get_assemblies_data(infs);
	return ad->named_after_text;
}

@h New generalisations.
Here a new generalisation is made. The |look_for| subtree contains the
|EVERY_NT| node, but it might be either at the top, as here:

>> Every container is in the Lumber Room.

or the first child of a |RELATIONSHIP_NT| node, as here:

>> In every container is a vehicle.

In the second case the |what_to_make| subtree is an |COMMON_NOUN_NT|, and in the
first it's a |RELATIONSHIP_NT| subtree.

=
void Assertions::Assemblies::make_generalisation(parse_node *look_for, parse_node *what_to_make) {
	parse_node *EVERY_node = NULL;
	if (Node::get_type(look_for) == EVERY_NT) EVERY_node = look_for;
	else if ((look_for->down) && (Node::get_type(look_for->down) == EVERY_NT))
		EVERY_node = look_for->down;
	else internal_error("Generalisation without EVERY node");
	inference_subject *k = Node::get_subject(EVERY_node);
	if (k == NULL) internal_error("Malformed EVERY node");

	if ((Assertions::Assemblies::subtree_mentions_kind(look_for,k,0)) ||
		(Assertions::Assemblies::subtree_mentions_kind(what_to_make,k,0)))
		@<Issue an infinite regress of assemblies problem message@>;

	@<Forbid generalisation about fixed kinds@>;
	@<Forbid generalisation on both sides@>;
	@<If we have to make a kind qualified by adjectives, expand that into a suitable subtree@>;

	Node::set_text(EVERY_node, EMPTY_WORDING);

	generalisation *g = CREATE(generalisation);
	g->look_for = look_for;
	g->what_to_make = what_to_make;
	g->substitute_at = EVERY_node;

	@<Add this new generalisation to the list for the kind it applies to@>;

	Annotations::write_int(current_sentence, you_can_ignore_ANNOT, TRUE);

	LOGIF(ASSEMBLIES, "New generalisation made concerning $j:\nLook for: $T\nMake: $T\n",
		k, g->look_for, g->what_to_make);

	Assertions::Assemblies::ensure_all_generalisations_made(k);
}

@<Forbid generalisation about fixed kinds@> =
	kind *instance_kind = InferenceSubjects::as_nonobject_kind(k);
	if ((instance_kind) &&
		(Kinds::Compare::le(instance_kind, K_object) == FALSE) &&
		(Kinds::Behaviour::has_named_constant_values(instance_kind) == FALSE)) {
		LOG("$T", look_for);
		LOG("$T", what_to_make);
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_AssemblyOnFixedKind),
			"this generalisation can't be made",
			"because I only use generalisations to talk about values which can be "
			"created as needed, like things or scenes - not about those always "
			"existing in fixed ranges, like numbers or times.");
		return;
	}

@<Forbid generalisation on both sides@> =
	if ((what_to_make) && (Node::get_type(what_to_make->down) == EVERY_NT)) {
		LOG("$T", look_for);
		LOG("$T", what_to_make);
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_AssemblyOnBothSides),
			"this generalisation can't be made",
			"because it uses 'every' or some similar generalisation on both sides, "
			"which is too rich for my taste.");
		return;
	}

@<If we have to make a kind qualified by adjectives, expand that into a suitable subtree@> =
	parse_node *val = Node::get_evaluation(what_to_make);
	if ((val) && (Descriptions::is_adjectives_plus_kind(val))) {
		Assertions::Refiner::refine_from_simple_description(what_to_make, Node::duplicate(val));
	}

@<Add this new generalisation to the list for the kind it applies to@> =
	assemblies_data *ad = InferenceSubjects::get_assemblies_data(k);
	if (ad->generalisation_list == NULL)
		ad->generalisation_list = g;
	else {
		generalisation *g2 = ad->generalisation_list;
		while (g2->next) g2 = g2->next;
		g2->next = g;
	}
	g->next = NULL;

@<Issue an infinite regress of assemblies problem message@> =
	LOG("Generalisation:\n");
	LOG("$T", look_for);
	LOG("$T", what_to_make);
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_AssemblyRegress),
		"this generalisation would be too dangerous",
		"because it would lead to infinite regress in the assembly process. Sometimes "
		"this happens if you have set up matters with text like 'A container is in every "
		"container.'.");
	return;

@ This is used only in checking for infinite regress:

=
int Assertions::Assemblies::subtree_mentions_kind(parse_node *subtree, inference_subject *k, int level) {
	if ((Node::get_type(subtree) == COMMON_NOUN_NT) &&
			(Node::get_subject(subtree) == k)) return TRUE;
	if ((subtree->down) && (Assertions::Assemblies::subtree_mentions_kind(subtree->down, k, level+1)))
		return TRUE;
	if ((level>0) && (subtree->next) && (Assertions::Assemblies::subtree_mentions_kind(subtree->next, k, level)))
		return TRUE;
	return FALSE;
}

@h The assembly process.
As noticed above, it's useful to have a routine which brings up to date the
application of generalisations. When this routine completes, every object
of a given kind has undergone every generalisation applicable to it exactly once.

=
void Assertions::Assemblies::ensure_all_generalisations_made(inference_subject *k) {
	inference_subject *infs;
	LOOP_OVER(infs, inference_subject)
		if ((InferenceSubjects::is_within(infs, k)) && (InferenceSubjects::domain(infs) == NULL))
			Assertions::Assemblies::satisfies_generalisations(infs);
}

@ Clearly one reason we might need to bring generalisations up to date is if
the kind of an object is determined, because that potentially expands the set of
generalisations applicable to it. But it's needlessly slow to apply a full
refresh when we know the only object which can be affected, so in that
situation we call just |Assertions::Assemblies::satisfies_generalisations| on the object in question.

=
void Assertions::Assemblies::satisfies_generalisations(inference_subject *infs) {
	if (InferenceSubjects::domain(infs)) return;
	inference_subject *k;
	for (k = InferenceSubjects::narrowest_broader_subject(infs); k; k = InferenceSubjects::narrowest_broader_subject(k)) {
		application *app;
		for (app = InferenceSubjects::get_assemblies_data(infs)->applications_so_far; app; app = app->next)
			if (app->generalisation_owner == k)
				break;
		@<Apply generalisations about K which have not yet been applied@>;
	}
}

@ At this point |app| points to the record of which generalisations in $K$
have been applied to the object so far, or is |NULL| if none of $K$'s
generalisation has ever been applied to it.

@<Apply generalisations about K which have not yet been applied@> =
	generalisation *ignore_up_to = (app)?(app->latest_applied):NULL;
	generalisation *g;
	for (g = InferenceSubjects::get_assemblies_data(k)->generalisation_list; g; g=g->next) {
		if (ignore_up_to) {
			if (g == ignore_up_to) ignore_up_to = NULL;
			continue;
		}
		if (app == NULL) @<Create a new record for this previously unapplied kind@>;
		app->latest_applied = g;
		Assertions::Assemblies::satisfies_generalisation(infs, g);
	}

@<Create a new record for this previously unapplied kind@> =
	app = CREATE(application);
	app->generalisation_owner = k;
	app->next = InferenceSubjects::get_assemblies_data(infs)->applications_so_far;
	InferenceSubjects::get_assemblies_data(infs)->applications_so_far = app;

@ It's worth a brief pause to think about the time and storage needed by the
above. Let $N$ be the number of objects, and $H$ the maximum depth of the kinds
hierarchy; while in theory $H$ might be $O(N)$, it's more likely to be about
$\log_2 N$ if the kinds hierarchy is balanced, and in practice even for very
large Inform source texts $H$ is never larger than 7 or 8.

The storage required to record $G$ generalisations is proportional to $G$,
since each appears only in a single linked list and is recorded in a single
structure instance. We clearly won't do better than that.

The storage required to record which generalisations have so far applied to
which objects is $O(HN)$, since each object stores about $12H$ bytes of data,
which is significantly better than a bitmap recording all pairs of generalisations
and objects (which would be $O(GN)$). The running time of |Assertions::Assemblies::satisfies_generalisations|
applied to object $X$ is $O(G_X H^2)$, where $G_X$ is the number of generalisations
which can be applied to $X$. In the course of compilation this is called once
each time the kind of $X$ is changed -- at most $H$ times -- and once each time
a new generalisation applicable to $X$ is added -- at most $G_X$ times. So we
have a total time consumption of $O(G_X^2 H^2 + G_X H^3)$. In practice the
constants are low, $G_X$ is very small compared to the size of the source
text, and so is $H$.

The main point, then, is that the mechanism above is much, much faster than
repeatedly checking each generalisation against each object, for a cost of
$O(G^2N)$.

@ So here we get on with the actual construction: we apply |g| to |infs|. What
we actually do is to insert new sentences after the current one.

=
int implicit_recursion_exception = FALSE; /* thrown when we've gone into infinite regress */
void Assertions::Assemblies::satisfies_generalisation(inference_subject *infs, generalisation *g) {
	inference_subject *counterpart = NULL; int snatcher = FALSE;
	if (Plugins::Call::detect_bodysnatching(infs, &snatcher, &counterpart)) {
		LOGIF(ASSEMBLIES, "Body-snatcher found! Subj $j, snatcher %d, counterpart $j\n",
			infs, snatcher, counterpart);
		if (snatcher) return;
	}
	inference_subject *infs_k = Node::get_subject(g->substitute_at);
	@<Throw the infinite regress exception if the current sentence makes too many things@>;

	parse_node *new_sentence = Node::new(SENTENCE_NT);

	/* mark this sentence as implicit, and increase its generation count: */
	Node::set_implicit_in_creation_of(new_sentence, infs);
	Annotations::write_int(new_sentence, implicitness_count_ANNOT,
		Annotations::read_int(current_sentence, implicitness_count_ANNOT) + 1);
	Node::set_text(new_sentence, Node::get_text(current_sentence));

	/* temporarily make the |EVERY_NT| node refer to the specific new |infs|: */
	Assertions::Refiner::noun_from_infs(g->substitute_at, infs);

	/* make the new sentence an assertion: */
	new_sentence->down = Node::new(VERB_NT);
	Annotations::write_int(new_sentence->down, verb_id_ANNOT, ASSERT_VB);
	new_sentence->down->next = Node::new(CREATED_NT);
	Node::copy_subtree(g->look_for, new_sentence->down->next, 0);
	new_sentence->down->next->next = Node::new(CREATED_NT);
	Node::copy_subtree(g->what_to_make, new_sentence->down->next->next, 0);
	new_sentence->down->next->next->next = NULL;

	/* restore the |EVERY_NT| node, now that the tree containing it has been copied: */
	Node::set_type(g->substitute_at, EVERY_NT);
	Node::set_subject(g->substitute_at, infs_k);

	/* insert this sentence after the current assembly position: */
	new_sentence->next = assembly_position->next;
	assembly_position->next = new_sentence;
	assembly_position = new_sentence;

	LOGIF(ASSEMBLIES,
		"Subject $j satisfies generalisation %d (from $j), making sentence:\n$T",
		infs, g->allocation_id, infs_k, new_sentence);
}

@ The "implicitness count" is a generation count, where the sentences
from the original source text are generation 0, and any sentences created
from those are generation 1, and so on. This should never be more than a
dozen or so, and if it becomes large than we can be pretty sure that the
machinery is in infinite regress, e.g., because each $K$ must contain an
$L$ but each $L$ must contain a $K$.

@d MAX_ASSEMBLY_SIZE 500

@<Throw the infinite regress exception if the current sentence makes too many things@> =
	if (implicit_recursion_exception) return;
	if (Annotations::read_int(current_sentence, implicitness_count_ANNOT) >= MAX_ASSEMBLY_SIZE) {
		implicit_recursion_exception = TRUE;
		Problems::quote_source(1, current_sentence);
		Problems::quote_subject(2, infs_k);
		int max = MAX_ASSEMBLY_SIZE;
		Problems::quote_number(3, &max);
		Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_AssemblyLoop));
		Problems::issue_problem_segment(
			"Making a new %2 seems to result in an assembly which can never end, "
			"or which at any rate led to some %3 further constructions "
			"before I panicked. This problem tends to occur if instructions "
			"are given which cause kinds to create each other forever: "
			"for instance, 'Every device is on a supporter. Every supporter "
			"is in a container. Every container is part of a device.'");
		Problems::issue_problem_end();
		return;
	}
