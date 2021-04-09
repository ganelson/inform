[WherePredicates::] Everywhere, Nowhere and Here.

To define the unary predicates for some anaphoric location adjectives.

@ We extend the predicate calculus with three unary predicates corresponding
to the English words "everywhere", "nowhere" and "here". Each one of these
is the singleton member of its own predicate family.

= (early code)
up_family *everywhere_up_family = NULL;
up_family *nowhere_up_family = NULL;
up_family *here_up_family = NULL;

unary_predicate *everywhere_up = NULL;
unary_predicate *nowhere_up = NULL;
unary_predicate *here_up = NULL;

@ =
void WherePredicates::start(void) {
	everywhere_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(everywhere_up_family, STOCK_UPF_MTID, WherePredicates::stock_everywhere);
	METHOD_ADD(everywhere_up_family, LOG_UPF_MTID, WherePredicates::log_everywhere);
	METHOD_ADD(everywhere_up_family, TYPECHECK_UPF_MTID, WherePredicates::typecheck_everywhere);
	METHOD_ADD(everywhere_up_family, ASSERT_UPF_MTID, WherePredicates::assert_everywhere);
	METHOD_ADD(everywhere_up_family, SCHEMA_UPF_MTID, RTSpatial::schema_everywhere);

	nowhere_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(nowhere_up_family, STOCK_UPF_MTID, WherePredicates::stock_nowhere);
	METHOD_ADD(nowhere_up_family, LOG_UPF_MTID, WherePredicates::log_nowhere);
	METHOD_ADD(nowhere_up_family, TYPECHECK_UPF_MTID, WherePredicates::typecheck_nowhere);
	METHOD_ADD(nowhere_up_family, ASSERT_UPF_MTID, WherePredicates::assert_nowhere);
	METHOD_ADD(nowhere_up_family, SCHEMA_UPF_MTID, RTSpatial::schema_nowhere);

	here_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(here_up_family, STOCK_UPF_MTID, WherePredicates::stock_here);
	METHOD_ADD(here_up_family, LOG_UPF_MTID, WherePredicates::log_here);
	METHOD_ADD(here_up_family, TYPECHECK_UPF_MTID, WherePredicates::typecheck_here);
	METHOD_ADD(here_up_family, ASSERT_UPF_MTID, WherePredicates::assert_here);
	METHOD_ADD(here_up_family, SCHEMA_UPF_MTID, RTSpatial::schema_here);
}

@ And here are corresponding propositions, $here(x)$ and so on.

=
pcalc_prop *WherePredicates::everywhere_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(everywhere_up, t);
}

pcalc_prop *WherePredicates::nowhere_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(nowhere_up, t);
}

pcalc_prop *WherePredicates::here_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(here_up, t);
}

@ These are automatically created, not defined in source text:

=
void WherePredicates::stock_everywhere(up_family *self, int n) {
	if (n == 1) everywhere_up = UnaryPredicates::new(everywhere_up_family);
}
void WherePredicates::stock_nowhere(up_family *self, int n) {
	if (n == 1) nowhere_up = UnaryPredicates::new(nowhere_up_family);
}
void WherePredicates::stock_here(up_family *self, int n) {
	if (n == 1) here_up = UnaryPredicates::new(here_up_family);
}

@ Typechecking is a matter of verifying that these apply only to objects,
and generating better problem messages than the normal machinery would if not:

=
int WherePredicates::typecheck_everywhere(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = TypecheckPropositions::kind_of_term(&(prop->terms[0]), vta, tck);
	if (Kinds::compatible(actually_find, K_object) == NEVER_MATCH) {
		if (tck->log_to_I6_text)
			LOG("Term $0 is %u not an object\n", &(prop->terms[0]), actually_find);
		Problems::quote_kind(4, actually_find);
		StandardProblems::tcp_problem(_p_(PM_EverywhereMisapplied), tck,
			"that seems to say that a value - specifically, %4 - is everywhere. "
			"To Inform, everywhere means 'in every room', and only objects "
			"can be everywhere - in fact not even all of those, as it's a "
			"privilege reserved for backdrops. (For instance, 'The sky is a "
			"backdrop. The sky is everywhere.' is allowed.)");
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

int WherePredicates::typecheck_nowhere(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = TypecheckPropositions::kind_of_term(&(prop->terms[0]), vta, tck);
	if (Kinds::compatible(actually_find, K_object) == NEVER_MATCH) {
		if (tck->log_to_I6_text)
			LOG("Term $0 is %u not an object\n", &(prop->terms[0]), actually_find);
		Problems::quote_kind(4, actually_find);
		StandardProblems::tcp_problem(_p_(PM_NowhereMisapplied), tck,
			"that seems to say that a value - specifically, %4 - is nowhere. "
			"To Inform, nowhere means 'in no room', and only things can be "
			"nowhere. (For instance, 'Godot is nowhere.' is allowed - it means "
			"Godot exists, but is not initially part of the drama.)");
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@ It seems to be true that Inform never generates propositions which
apply "here" incorrectly, but just in case:

=
int WherePredicates::typecheck_here(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = TypecheckPropositions::kind_of_term(&(prop->terms[0]), vta, tck);
	if (Kinds::compatible(actually_find, K_object) == NEVER_MATCH) {
		if (tck->log_to_I6_text)
			LOG("Term $0 is %u not an object\n", &(prop->terms[0]), actually_find);
		Problems::quote_kind(4, actually_find);
		StandardProblems::tcp_problem(_p_(BelievedImpossible), tck,
			"that seems to say that a value - specifically, %4 - is here. "
			"To Inform, here means 'in the room we're talking about', so only "
			"objects can be 'here'.");
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@ "Everywhere" in an assertion would say that something is found in every room,
and for that we have to ask the Backdrops plugin to handle it.

=
void WherePredicates::assert_everywhere(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *prop) {
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantAssertNegatedEverywhere),
			"that seems to say that something isn't everywhere",
			"which is too vague. You must say where it is.");
		return;
	}
	inference_subject *subj = Assert::subject_of_term(prop->terms[0]);
	instance *ox = InstanceSubjects::to_object_instance(subj);
	Backdrops::infer_presence_everywhere(ox);
}

@ What is nowhere is not necessarily useless: it is probably something which
is out of play at the start of the narrative, but will appear later. So it
is meaningful to assert that something is nowhere.

=
void WherePredicates::assert_nowhere(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *prop) {
	inference_subject *subj = Assert::subject_of_term(prop->terms[0]);
	instance *ox = InstanceSubjects::to_object_instance(subj);
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"that seems to say that something isn't nowhere",
			"which is too vague. You must say where it is.");
		return;
	}
	if (ox == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"that seems to say that something generic is 'nowhere'",
			"which suggests it could some day have a physical location.");
		return;
	}
	Spatial::infer_presence_nowhere(ox);
}

@ "Here" means "in the current room", which is tricky on two counts: we need
to know what the current topic of conversation is, an anaphora, and also we
might not yet know what is and is not a room. So we record a special inference
and put the issue aside for now.

=
void WherePredicates::assert_here(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *prop) {
	inference_subject *subj = Assert::subject_of_term(prop->terms[0]);
	instance *ox = InstanceSubjects::to_object_instance(subj);
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"that seems to say that something isn't here",
			"which is too vague. You must say where it is.");
		return;
	}
	if (ox == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonInstanceHere),
			"that seems to say that something generic is 'here'",
			"which would give it a physical location. (It would be like saying "
			"'A number is here' - well, numbers are everywhere and nowhere.)");
		return;
	}
	Spatial::infer_presence_here(ox);
}

@ =
void WherePredicates::log_everywhere(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("everywhere");
}

void WherePredicates::log_nowhere(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("nowhere");
}

void WherePredicates::log_here(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("here");
}
