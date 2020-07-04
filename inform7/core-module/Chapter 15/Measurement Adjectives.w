[Properties::Measurement::] Measurement Adjectives.

To define adjectives such as large, wide or roomy, which make
implicit comparisons of the size of some numerical property, and which
(unlike other adjectives) lead to comparative and superlative forms.

@h Definitions.

@ A typical example would be:

>> Definition: A container is roomy if its carrying capacity is 10 or more.

Here the domain of the definition is "container", and we must assign
an adjective meaning for "roomy" which involves the comparison of a
property (here "carrying capacity") against a threshold value $t$ (here,
$t=10$). Each such definition allows the property value to belong to a
"region": we are looking for membership of $\lbrace x\mid x\leq t\rbrace$,
$\lbrace t\rbrace$ or $\lbrace x\mid x\geq t\rbrace$. The following constants
enumerate the possible shapes of this region.

@d MEASURE_T_OR_LESS -1
@d MEASURE_T_EXACTLY 0
@d MEASURE_T_OR_MORE 1

@ We then need to create the comparative form "roomier" as a relation, and the
superlative "roomiest" as a phrasal form -- not in general an adjective, since
its domain is too ambiguous in text such as:

>> if the canvas bag is roomiest, ...

which begs the question: roomiest out of what? All containers, or implicitly
some subcollection of them? So we avoid the problem by allowing superlatives
only when explicitly followed by a domain:

>> roomiest container in Heathrow Terminal 5

The word "roomy" is the headword, so called in the lexicography sense --
other forms are derived from it but they all appear under "roomy" in
the Phrasebook.

@ The implementation of measurement adjectives is tricksy for reasons of
timing during Inform's run: the names of kinds, properties and values become
available at different times; whereas we need the name of the adjective
itself to become available very early on. This is why the structure below
appears to record a lot of extraneous clutter apparently needed only
temporarily during parsing -- because parsing does not happen all at once,
and partial results have to be parked in the structure after one stage to
be picked up at the next.

At any rate, here's the structure:

=
typedef struct measurement_definition {
	struct parse_node *measurement_node; /* where the actual definition is */

	struct wording headword; /* adjective being defined (must be single word) */
	struct adjective_meaning *headword_as_adjective; /* which adjective meaning */
	struct wording superlative; /* its superlative form */

	struct property *prop; /* the property being compared, if any */
	struct wording name_of_property_to_compare; /* text of the name of the property to compare */
	struct inter_name *mdef_iname;

	int region_shape; /* one of the |MEASURE_T_*| constants */
	int region_threshold; /* numerical value of threshold (if any) */
	struct kind *region_kind; /* of this value */
	int region_threshold_evaluated; /* have we evaluated this one yet? */
	struct wording region_threshold_text; /* text of threshold value */

	int property_schema_written; /* I6 schema for testing written yet? */
	CLASS_DEFINITION
} measurement_definition;

@h Measurements.
Here are operators for checking whether we lie inside the domain, where
the LHS is the value being tested and the RHS is the constant $t$. In weak
comparison, $t$ itself is a member; in strict comparison, it isn't.

=
binary_predicate *Properties::Measurement::weak_comparison_bp(int shape) {
	binary_predicate *operator = NULL; /* solely to placate gcc */
	switch (shape) {
		case MEASURE_T_OR_MORE: operator = R_numerically_greater_than_or_equal_to; break;
		case MEASURE_T_EXACTLY: operator = R_equality; break;
		case MEASURE_T_OR_LESS: operator = R_numerically_less_than_or_equal_to; break;
		default: internal_error("unknown region for weak comparison");
	}
	return operator;
}

char *Properties::Measurement::strict_comparison(int shape) {
	char *operator = NULL; /* solely to placate gcc */
	switch (shape) {
		case MEASURE_T_OR_MORE: operator = ">"; break;
		case MEASURE_T_OR_LESS: operator = "<"; break;
		default: internal_error("unknown region for strict comparison");
	}
	return operator;
}

@ =
measurement_definition *Properties::Measurement::retrieve(property *prn, int shape) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition) {
		Properties::Measurement::validate(mdef);
		if ((Properties::Measurement::is_valid(mdef)) && (mdef->prop == prn) && (mdef->region_shape == shape))
			return mdef;
	}
	return NULL;
}

void Properties::Measurement::read_property_details(measurement_definition *mdef,
	property **prn, int *shape) {
	if (prn) *prn = mdef->prop;
	if (shape) *shape = mdef->region_shape;
}

@ Inconveniently, at the time when we create a measurement to test if a subject
$S$ satisfies (say) $P(S) \in \lbrace x\mid x\geq t\rbrace$, we don't yet know
either the property $P$ or the threshold value $t$. That means the measurement
definition structure stands incomplete for a while. Filling it in is called
"validation", as follows.

=
void Properties::Measurement::validate_definitions(void) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition) Properties::Measurement::validate(mdef);
}

@ Where:

=
void Properties::Measurement::validate(measurement_definition *mdef) {
	if ((mdef->prop == NULL) && (Wordings::nonempty(mdef->name_of_property_to_compare)))
		@<Fill in the missing property name, P@>;
	if (mdef->region_threshold_evaluated == FALSE)
		@<Fill in the missing threshold value, t@>;
}

@ Here we either make $P$ valid, or leave it |NULL| and issue a problem.

@<Fill in the missing property name, P@> =
	if (<property-name>(mdef->name_of_property_to_compare)) mdef->prop = <<rp>>;
	else {
		mdef->prop = NULL;
		LOG("Validating mdef with headword %W... <%W>\n",
			mdef->headword, mdef->name_of_property_to_compare);
		StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingUnknownProperty),
			mdef->measurement_node,
			"that definition involves an unknown property",
			"assuming it was meant to be a definition in the form 'Definition: "
			"a container is large if its carrying capacity is 10 or more.'");
		return;
	}

@ Here we either make $t$ valid, or leave |mdef->region_threshold_evaluated| clear
and issue a problem.

@<Fill in the missing threshold value, t@> =
	mdef->region_kind = NULL;
	if (<s-literal>(mdef->region_threshold_text))
		mdef->region_kind = Rvalues::to_kind(<<rp>>);
	if (mdef->region_kind) {
		mdef->region_threshold = Rvalues::to_encoded_notation(<<rp>>);
		if ((Kinds::Behaviour::is_quasinumerical(mdef->region_kind) == FALSE) &&
			(mdef->region_shape != MEASURE_T_EXACTLY)) {
			StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingNonarithmeticKOV),
				mdef->measurement_node,
				"the property value given here has a kind which can't be "
				"subject to numerical comparisons",
				"so it doesn't make sense to talk about it being 'more' or "
				"'less'.");
			mdef->region_threshold = 0;
			return;
		}
		if (Kinds::Compare::compatible(mdef->region_kind,
			Properties::Valued::kind(mdef->prop)) != ALWAYS_MATCH) {
			StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingWrongKOV),
				mdef->measurement_node,
				"the property value given here is the wrong kind",
				"and does not match the property being looked at.");
			mdef->region_threshold = 0;
			return;
		}
	} else {
		LOG("Can't get literal from <%W>\n", mdef->region_threshold_text);
		StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingNonLiteral),
			mdef->measurement_node,
			"that definition is wrongly phrased",
			"assuming it was meant to be a grading adjective like 'Definition: a "
			"container is large if its carrying capacity is 10 or more.'");
		return;
	}
	mdef->region_threshold_evaluated = TRUE;

@ To recover safely from these errors, we would be wise to check:

=
int Properties::Measurement::is_valid(measurement_definition *mdef) {
	if ((mdef->prop == NULL) || (mdef->region_threshold_evaluated == FALSE)) return FALSE;
	return TRUE;
}

@h Adjectives arising from measurements.
Measurement adjectives are created when we parse a "Definition:" clause for
a new adjective, and then only when the definition has a particular form:

>> Definition: A container is roomy if its carrying capacity is 10 or more.

<measurement-adjective-definition> is used to parse the definition part,

>> its carrying capacity is 10 or more

The following grammar is a little sketchy because it's parsed very early in
Inform's run. Eventually, though, the text after the possessive is required
always to match <property-name>, and the text in the range must match
<s-literal>.

=
<measurement-adjective-definition> ::=
	<possessive-third-person> ... is/are not ... |    ==> @<Issue PM_GradingMisphrased problem@>
	<possessive-third-person> {<property-name>} is/are <measurement-range> |    ==> R[3]; *XP = RP[2]
	<possessive-third-person> ... is/are <measurement-range>					==> R[2]; *XP = NULL

<measurement-range> ::=
	... or more |    ==> MEASURE_T_OR_MORE
	... or less |    ==> MEASURE_T_OR_LESS
	...					==> MEASURE_T_EXACTLY

@<Issue PM_GradingMisphrased problem@> =
	StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingMisphrased),
		NounPhrases::new_raw(W),
		"that definition is wrongly phrased",
		"assuming it was meant to be a grading adjective like 'Definition: a "
		"container is large if its carrying capacity is 10 or more.'");
	return FALSE;

@ =
adjective_meaning *Properties::Measurement::ADJ_parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense == 0) return NULL;

	if (<measurement-adjective-definition>(CONW) == FALSE) return NULL;
	int shape = <<r>>;
	wording PRW = GET_RW(<measurement-adjective-definition>, 1);
	wording THRESW = GET_RW(<measurement-range>, 1);
	property *prop = <<rp>>;

	@<Reject some overly elaborate attempts to define overly elaborate measurements@>;
	@<Allow an exact measurement to be created only if we can already parse the threshold@>;

	measurement_definition *mdef = CREATE(measurement_definition);
	@<Initialise the measurement definition@>;
	if (shape != MEASURE_T_EXACTLY) @<Create the superlative form@>;
	@<Create the adjectival meaning arising from this measurement@>;
	return mdef->headword_as_adjective;
}

@<Reject some overly elaborate attempts to define overly elaborate measurements@> =
	if (Wordings::length(AW) > 1) {
		if (shape != MEASURE_T_EXACTLY)
			StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_MultiwordGrading),
				q, "a grading adjective must be a single word",
				"as in 'Definition: a container is large if its carrying capacity is "
				"10 or more.': 'fairly large' would not be allowed because it would "
				"make no sense to talk about 'fairly larger' or 'fairly largest'.");
		return NULL;
	}

	if (Wordings::nonempty(CALLW)) {
		if (shape != MEASURE_T_EXACTLY)
			StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingCalled),
				q, "callings are not allowed when defining grading adjectives",
				"so 'Definition: a container is large if its carrying capacity is 10 "
				"or more.' is fine, but so 'Definition: a container (called the bag) "
				"is large if its carrying capacity is 10 or more.' is not - then again, "
				"there's very little call for it.");
		return NULL;
	}

	if (sense != 1) {
		if (shape != MEASURE_T_EXACTLY)
			StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingUnless),
				q, "'unless' is not allowed when defining grading adjectives",
				"so 'Definition: a container is large if its carrying capacity is 10 "
				"or more.' is fine, but so 'Definition: a container is modest unless "
				"its carrying capacity is 10 or more.' is not - of course a similar "
				"effect could be achieved by 'Definition: a container is modest if its "
				"carrying capacity is 9 or less.'");
		return NULL;
	}

@ Perhaps this is a good point to say why we allow any exact measurements at
all. After all, if we didn't, a definition like:

>> Definition: a person is handy if his carrying capacity is 7.

...would still work; and "handy" would then be created as a |CONDITION_KADJ|
adjective. So why not let that happen?

The answer is that our |MEASUREMENT_KADJ| adjectives behave exactly the same
at run-time, but can also be asserted true in the model world at compile-time.
In particular, we could write:

>> Peter is a handy person.

This can't be done with general |CONDITION_KADJ| adjectives, because conditions
can't normally be unravelled at compile time.

@<Allow an exact measurement to be created only if we can already parse the threshold@> =
	if (shape == MEASURE_T_EXACTLY) {
		if (<s-literal>(THRESW) == FALSE) return NULL;
	}

@<Initialise the measurement definition@> =
	mdef->measurement_node = q;
	mdef->headword = Wordings::first_word(AW);

	mdef->region_threshold = 0;
	mdef->region_threshold_text = THRESW;
	mdef->region_threshold_evaluated = FALSE;

	mdef->prop = prop;
	mdef->property_schema_written = FALSE;
	mdef->region_shape = shape;
	mdef->name_of_property_to_compare = PRW;

	mdef->superlative = EMPTY_WORDING; /* but it may be set below */
	mdef->headword_as_adjective = NULL; /* but it will certainly be set below */

	package_request *P = Hierarchy::package(Modules::current(), ADJECTIVE_MEANINGS_HAP);
	mdef->mdef_iname = Hierarchy::make_iname_in(MEASUREMENT_FN_HL, P);

@<Create the superlative form@> =
	mdef->superlative =
		Grading::make_superlative(mdef->headword, Task::language_of_syntax());
	@<Feed the preamble for the superlative phrase into the lexer@>;
	@<Feed the body of the superlative phrase into the lexer@>;
	Sentences::RuleSubtrees::register_recently_lexed_phrases();

@<Feed the preamble for the superlative phrase into the lexer@> =
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, " To decide which object is %N ( S - description of objects ) ",
		Wordings::first_wn(mdef->superlative));
	Sentences::make_node(Task::syntax_tree(),
		Feeds::feed_text(TEMP),
		':');
	DISCARD_TEXT(TEMP)

@<Feed the body of the superlative phrase into the lexer@> =
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, " (- {-primitive-definition:extremal%s%W}  -) ",
		Properties::Measurement::strict_comparison(mdef->region_shape),
		mdef->name_of_property_to_compare);
	Sentences::make_node(Task::syntax_tree(), Feeds::feed_text(TEMP), '.');
	DISCARD_TEXT(TEMP)

@<Create the adjectival meaning arising from this measurement@> =
	adjective_meaning *am = Adjectives::Meanings::new(MEASUREMENT_KADJ,
		STORE_POINTER_measurement_definition(mdef), Node::get_text(q));
	mdef->headword_as_adjective = am;
	Adjectives::Meanings::declare(am, AW, 3);
	Adjectives::Meanings::pass_task_to_support_routine(am, TEST_ADJECTIVE_TASK);
	Adjectives::Meanings::set_domain_text(am, DNW);

@ =
void Properties::Measurement::ADJ_compiling_soon(adjective_meaning *am,
	measurement_definition *mdef, int T) {
	if ((mdef->prop) && (mdef->region_threshold_evaluated) &&
		(mdef->property_schema_written == FALSE)) {
		i6_schema *sch = Adjectives::Meanings::set_i6_schema(
			mdef->headword_as_adjective, TEST_ADJECTIVE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "%n(*1)", mdef->mdef_iname);
		mdef->property_schema_written = TRUE;
	}
}

int Properties::Measurement::ADJ_compile(measurement_definition *mdef,
	int T, int emit_flag, ph_stack_frame *phsf) {
	return FALSE;
}

int Properties::Measurement::ADJ_assert(measurement_definition *mdef,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	Properties::Measurement::validate(mdef);
	if ((Properties::Measurement::is_valid(mdef)) && (mdef->prop) && (parity == TRUE)) {
		parse_node *val = NULL;
		if (<s-literal>(mdef->region_threshold_text)) val = <<rp>>;
		else internal_error("literal unreadable");
		World::Inferences::draw_property(infs_to_assert_on, mdef->prop, val);
		return TRUE;
	}
	return FALSE;
}

int Properties::Measurement::ADJ_index(OUTPUT_STREAM, measurement_definition *mdef) {
	return FALSE;
}

@h Support routines for measurement.

=
void Properties::Measurement::compile_MADJ_routines(void) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition)
		if (mdef->property_schema_written) {
			packaging_state save = Routines::begin(mdef->mdef_iname);
			local_variable *lv = LocalVariables::add_call_parameter(
				Frames::current_stack_frame(),
				EMPTY_WORDING,
				Adjectives::Meanings::get_domain(mdef->headword_as_adjective));
			parse_node *var = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, lv);
			parse_node *evaluated_prop = Lvalues::new_PROPERTY_VALUE(
				Rvalues::from_property(mdef->prop), var);
			parse_node *val = NULL;
			if (<s-literal>(mdef->region_threshold_text)) val = <<rp>>;
			else internal_error("literal unreadable");
			pcalc_prop *prop = Calculus::Atoms::binary_PREDICATE_new(
				Properties::Measurement::weak_comparison_bp(mdef->region_shape),
				Calculus::Terms::new_constant(evaluated_prop),
				Calculus::Terms::new_constant(val));
			if (Calculus::Propositions::Checker::type_check(prop,
				Calculus::Propositions::Checker::tc_problem_reporting(
					mdef->region_threshold_text,
					"be giving the boundary of the definition")) == ALWAYS_MATCH) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Calculus::Deferrals::emit_test_of_proposition(NULL, prop);
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::rtrue(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			}
			Produce::rfalse(Emit::tree());
			Routines::end(save);
		}
}

@h Comparative forms.
For timing reasons, these are made all at once, and later than when the headword
adjectives and superlatives are made.

=
void Properties::Measurement::create_comparatives(void) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition) {
		Properties::Measurement::validate(mdef);
		if ((Properties::Measurement::is_valid(mdef)) && (mdef->region_shape != MEASURE_T_EXACTLY)) {
			wording H = mdef->headword; /* word number of, e.g., "tall" */
			wording comparative_form = Grading::make_comparative(H,
				Task::language_of_syntax()); /* "taller than" */
			vocabulary_entry *quiddity =
				Lexer::word(Wordings::first_wn(
					Grading::make_quiddity(H, Task::language_of_syntax()))); /* "tallness" */
			i6_schema *schema_to_compare_property_values;

			@<Work out property comparison schema@>;
			@<Construct a BP named for the quiddity and tested using the comparative schema@>;
		}
	}
}

@ This schema compares the property values:

@<Work out property comparison schema@> =
	inter_name *identifier = Properties::iname(mdef->prop);
	char *operation = Properties::Measurement::strict_comparison(mdef->region_shape);
	schema_to_compare_property_values =
		Calculus::Schemas::new("(*1.%n %s *2.%n)", identifier, operation, identifier);

@ The relation arising from "tall" would be called the "tallness relation", for
instance. Note that we don't say anything about the domain of $x$ and $y$
in $T(x, y)$. That's because we a value property like "height" may exist
for more than one kind of object, and there is not necessarily any unifying
kind of value $K$ such all objects satisfying $K$ possess a height and all
others do not. (That's intentional: it is Inform's one concession towards
multiple-inheritance, and it allows containers and doors to share lockability
behaviour despite being of mutually incompatible kinds.)

@<Construct a BP named for the quiddity and tested using the comparative schema@> =
	binary_predicate *bp;
	TEMPORARY_TEXT(relname)
	WRITE_TO(relname, "%V", quiddity);
	bp = BinaryPredicates::make_pair(PROPERTY_COMPARISON_KBP,
		BinaryPredicates::new_term(NULL), BinaryPredicates::new_term(NULL),
		relname, NULL, NULL, NULL,
		schema_to_compare_property_values, WordAssemblages::lit_1(quiddity));
	DISCARD_TEXT(relname)
	BinaryPredicates::set_comparison_details(bp, mdef->region_shape, mdef->prop);
	Properties::Measurement::register_comparative(comparative_form, bp);

@h Late registration of prepositions comparing properties.
The following routines, used only when all the properties have been
created, make suitable comparatives ("bigger than", etc.) and
prepositional usages to test property-equality ("the same height as").

=
void Properties::Measurement::register_comparative(wording W, binary_predicate *root) {
	set_where_created = current_sentence;
	verb_meaning vm = VerbMeanings::regular(root);
	preposition *prep =
		Prepositions::make(PreformUtilities::merge(<comparative-property-construction>, 0,
			WordAssemblages::lit_1(Lexer::word(Wordings::first_wn(W)))), FALSE);
	Verbs::add_form(copular_verb, prep, NULL, vm, SVO_FS_BIT);
}

@ When the source text creates a measurement adjective, such as:

>> A man is tall if his height is 6 feet or more.

Inform also creates a comparative form of the adjective as a preposition:

=
<comparative-property-construction> ::=
	... than						/* Peter is taller than Claude */

@ And when Inform creates a value property, that also makes a preposition:

=
<same-property-as-construction> ::=
	the same ... as					/* if Peter is the same height as Claude */
