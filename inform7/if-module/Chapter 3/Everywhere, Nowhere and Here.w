[WherePredicates::] Everywhere, Nowhere and Here.

To define the unary predicates for some anaphoric location adjectives.

@

= (early code)
up_family *everywhere_up_family = NULL;
up_family *nowhere_up_family = NULL;
up_family *here_up_family = NULL;

unary_predicate *everywhere_up = NULL;
unary_predicate *nowhere_up = NULL;
unary_predicate *here_up = NULL;

@h Start.

=
void WherePredicates::start(void) {
	everywhere_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(everywhere_up_family, STOCK_UPF_MTID, WherePredicates::stock_everywhere);
	METHOD_ADD(everywhere_up_family, LOG_UPF_MTID, WherePredicates::log_everywhere);
	nowhere_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(nowhere_up_family, STOCK_UPF_MTID, WherePredicates::stock_nowhere);
	METHOD_ADD(nowhere_up_family, LOG_UPF_MTID, WherePredicates::log_nowhere);
	here_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(here_up_family, STOCK_UPF_MTID, WherePredicates::stock_here);
	METHOD_ADD(here_up_family, LOG_UPF_MTID, WherePredicates::log_here);
	#ifdef CORE_MODULE
	METHOD_ADD(everywhere_up_family, TYPECHECK_UPF_MTID, WherePredicates::typecheck_everywhere);
	METHOD_ADD(everywhere_up_family, ASSERT_UPF_MTID, WherePredicates::assert_everywhere);
	METHOD_ADD(everywhere_up_family, SCHEMA_UPF_MTID, WherePredicates::schema_everywhere);
	METHOD_ADD(nowhere_up_family, TYPECHECK_UPF_MTID, WherePredicates::typecheck_nowhere);
	METHOD_ADD(nowhere_up_family, ASSERT_UPF_MTID, WherePredicates::assert_nowhere);
	METHOD_ADD(nowhere_up_family, SCHEMA_UPF_MTID, WherePredicates::schema_nowhere);
	METHOD_ADD(here_up_family, TYPECHECK_UPF_MTID, WherePredicates::typecheck_here);
	METHOD_ADD(here_up_family, ASSERT_UPF_MTID, WherePredicates::assert_here);
	METHOD_ADD(here_up_family, SCHEMA_UPF_MTID, WherePredicates::schema_here);
	#endif
}

@h Initial stock.
This relation is hard-wired in, and it is made in a slightly special way
since (alone among binary predicates) it has no distinct reversal.

=
void WherePredicates::stock_everywhere(up_family *self, int n) {
	if (n == 1) {
		everywhere_up = UnaryPredicates::new(everywhere_up_family);
	}
}
void WherePredicates::stock_nowhere(up_family *self, int n) {
	if (n == 1) {
		nowhere_up = UnaryPredicates::new(nowhere_up_family);
	}
}
void WherePredicates::stock_here(up_family *self, int n) {
	if (n == 1) {
		here_up = UnaryPredicates::new(here_up_family);
	}
}

pcalc_prop *WherePredicates::everywhere_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(everywhere_up, t);
}

pcalc_prop *WherePredicates::nowhere_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(nowhere_up, t);
}

pcalc_prop *WherePredicates::here_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(here_up, t);
}

#ifdef CORE_MODULE
int WherePredicates::typecheck_everywhere(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = Propositions::Checker::kind_of_term(&(prop->terms[0]), vta, tck);
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
#endif

#ifdef CORE_MODULE
int WherePredicates::typecheck_nowhere(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = Propositions::Checker::kind_of_term(&(prop->terms[0]), vta, tck);
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
#endif

@ It seems to be true that Inform never generates propositions which
apply "here" incorrectly, but just in case:

=
#ifdef CORE_MODULE
int WherePredicates::typecheck_here(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = Propositions::Checker::kind_of_term(&(prop->terms[0]), vta, tck);
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
#endif

@ EVERYWHERE declares that something is found
in every room. While we could simply deduce that the object must be a
backdrop (and set the kind to make it so), this is such an extreme business,
so rarely needed, that it seems better to make the user spell out that
we're dealing with a backdrop. So we play dumb.

=
#ifdef CORE_MODULE
void WherePredicates::assert_everywhere(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *prop) {
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantAssertNegatedEverywhere),
			"that seems to say that something isn't everywhere",
			"which is too vague. You must say where it is.");
		return;
	}
	#ifdef IF_MODULE
	inference_subject *subj = Assert::subject_of_term(prop->terms[0]);
	instance *ox = Instances::object_from_infs(subj);
	PL::Backdrops::infer_presence_everywhere(ox);
	#endif
}
#endif

@ NOWHERE is similar:

=
#ifdef CORE_MODULE
void WherePredicates::assert_nowhere(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *prop) {
	inference_subject *subj = Assert::subject_of_term(prop->terms[0]);
	instance *ox = Instances::object_from_infs(subj);
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
	#ifdef IF_MODULE
	PL::Spatial::infer_presence_nowhere(ox);
	#endif
}
#endif

@ HERE means "this object is in the current room", which is not as easy to
resolve as it looks, because at this point we don't know for certain what
will be a room and what won't. So we record a special inference and put the
problem aside for now.

=
#ifdef CORE_MODULE
void WherePredicates::assert_here(up_family *self, unary_predicate *up,
	int now_negated, pcalc_prop *prop) {
	inference_subject *subj = Assert::subject_of_term(prop->terms[0]);
	instance *ox = Instances::object_from_infs(subj);
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
	#ifdef IF_MODULE
	PL::Spatial::infer_presence_here(ox);
	#endif
}
#endif

@ Note that |FoundEverywhere| is a template routine existing
to provide a common value of the I6 |found_in| property -- common that is
to all backdrops which are currently everywhere.

=
#ifdef CORE_MODULE
void WherePredicates::schema_everywhere(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "BackdropEverywhere(*1)");
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema, "MoveObject(*1, FoundEverywhere); MoveFloatingObjects();");
			break;
		case NOW_ATOM_FALSE_TASK:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantChangeEverywhere),
				"not being 'everywhere' is not something which can be changed "
				"during play using 'now'",
				"because it's not exact enough about what needs to be done.");
			asch->schema = NULL; break;
	}
}
#endif

#ifdef CORE_MODULE
void WherePredicates::schema_nowhere(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "LocationOf(*1) == nothing");
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema, "RemoveFromPlay(*1);");
			break;
		case NOW_ATOM_FALSE_TASK:
			Calculus::Schemas::modify(asch->schema, "MoveObject(*1, real_location, 1, false);");
			break;
	}
}
#endif

@ In fact, at present "here" predicates are never included in propositions to
be compiled, so this code is never used.

=
#ifdef CORE_MODULE
void WherePredicates::schema_here(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "LocationOf(*1) == location");
			break;
		case NOW_ATOM_TRUE_TASK:
		case NOW_ATOM_FALSE_TASK:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"being 'here' is not something which can be changed during play",
				"so it cannot be brought about or cancelled out with 'now'.");
			asch->schema = NULL; break;
	}
}
#endif

void WherePredicates::log_everywhere(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("everywhere");
}

void WherePredicates::log_nowhere(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("nowhere");
}

void WherePredicates::log_here(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("here");
}
