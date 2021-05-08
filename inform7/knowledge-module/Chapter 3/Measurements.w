[Measurements::] Measurements.

To define adjectives such as large, wide or roomy, which make implicit
comparisons of the size of some numerical property, and which lead to
comparative and superlative forms.

@h Measurements, regions and shapes.
A typical example would be:

>> Definition: A container is roomy if its carrying capacity is 10 or more.

Here the domain of the definition is "container", and we must assign an adjective
meaning for "roomy" which involves the comparison of a property (here "carrying
capacity") against a threshold value $t$ (here, $t=10$). "roomy" is said to
be the headword; the comparative form would be roomier, and the superlative
form roomiest. The comparative will make a relation -- see //Comparative Relations// --
while and the must be a phrase. It can't be an adjective, since its domain
would be too ambiguous in text such as:

>> if the canvas bag is roomiest, ...

which begs the question: roomiest out of what? All containers, or implicitly
some subcollection of them? So we avoid the problem by allowing superlatives
only when explicitly followed by a domain:

>> roomiest container in Heathrow Terminal 5

@ Each such definition allows the property value to belong to a "region", which
takes one of these three "shapes":

@d MEASURE_T_OR_LESS -1
@d MEASURE_T_EXACTLY 0
@d MEASURE_T_OR_MORE 1

@ Here are operators for checking whether we lie inside the domain, where
the LHS is the value being tested and the RHS is the constant $t$. In weak
comparison, $t$ itself is a member; in strict comparison, it isn't.

=
binary_predicate *Measurements::weak_comparison_bp(int shape) {
	binary_predicate *operator = NULL; /* solely to placate gcc */
	switch (shape) {
		case MEASURE_T_OR_MORE: operator = R_numerically_greater_than_or_equal_to; break;
		case MEASURE_T_EXACTLY: operator = R_equality; break;
		case MEASURE_T_OR_LESS: operator = R_numerically_less_than_or_equal_to; break;
		default: internal_error("unknown region for weak comparison");
	}
	return operator;
}

char *Measurements::strict_comparison(int shape) {
	char *operator = NULL; /* solely to placate clang */
	switch (shape) {
		case MEASURE_T_OR_MORE: operator = ">"; break;
		case MEASURE_T_OR_LESS: operator = "<"; break;
		default: internal_error("unknown region for strict comparison");
	}
	return operator;
}

@h Creation.
The implementation of measurement adjectives is tricksy for reasons of
timing during Inform's run: the names of kinds, properties and values become
available at different times; whereas we need the name of the adjective
itself to become available very early on. This is why the structure below
appears to record a lot of extraneous clutter apparently needed only
temporarily during parsing -- because parsing does not happen all at once,
and partial results have to be parked in the structure after one stage to
be picked up at the next.

At any rate, here goes:

=
typedef struct measurement_definition {
	struct parse_node *measurement_node; /* where the actual definition is */

	struct wording headword; /* adjective being defined (must be single word) */
	struct adjective_meaning *headword_as_adjective; /* which adjective meaning */
	struct wording superlative; /* its superlative form */

	struct property *prop; /* the property being compared, if any */
	struct wording name_of_property_to_compare; /* and its name */

	int region_shape; /* one of the |MEASURE_T_*| constants */
	int region_threshold; /* numerical value of threshold (if any) */
	struct kind *region_kind; /* of this value */
	int region_threshold_evaluated; /* have we evaluated this one yet? */
	struct wording region_threshold_text; /* text of threshold value */

	struct measurement_compilation_data compilation_data;
	CLASS_DEFINITION
} measurement_definition;

@ =
measurement_definition *Measurements::new(parse_node *q, wording AW, wording THRESW,
	property *prop, int shape, wording PRW) {
	measurement_definition *mdef = CREATE(measurement_definition);
	mdef->measurement_node = q;
	mdef->headword = Wordings::first_word(AW);
	mdef->region_threshold = 0;
	mdef->region_threshold_text = THRESW;
	mdef->region_threshold_evaluated = FALSE;
	mdef->prop = prop;
	mdef->region_shape = shape;
	mdef->name_of_property_to_compare = PRW;
	mdef->superlative = EMPTY_WORDING;
	mdef->headword_as_adjective = NULL;
	mdef->compilation_data = RTAdjectives::new_measurement_compilation_data(mdef);
	return mdef;
}

@ The following converts an mdef to a property and shape:

=
void Measurements::read_property_details(measurement_definition *mdef,
	property **prn, int *shape) {
	if (prn) *prn = mdef->prop;
	if (shape) *shape = mdef->region_shape;
}

@ And this does the inverse, albeit a little slowly:

=
measurement_definition *Measurements::retrieve(property *prn, int shape) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition) {
		Measurements::validate(mdef);
		if ((Measurements::is_valid(mdef)) && (mdef->prop == prn) &&
			(mdef->region_shape == shape))
			return mdef;
	}
	return NULL;
}

@ As noted above, there are timing issues here, and the initial state of a
//measurement_definition// leaves much to be filled in later. This is called
"validation", and is to some extent performed on demand. The following tries
to validate everything:

=
void Measurements::validate_definitions(void) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition)
		Measurements::validate(mdef);
}

@ But we can also try to validate just one at a time:

=
void Measurements::validate(measurement_definition *mdef) {
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
		StandardProblems::definition_problem(Task::syntax_tree(),
			_p_(PM_GradingUnknownProperty),
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
			StandardProblems::definition_problem(Task::syntax_tree(),
				_p_(PM_GradingNonarithmeticKOV),
				mdef->measurement_node,
				"the property value given here has a kind which can't be "
				"subject to numerical comparisons",
				"so it doesn't make sense to talk about it being 'more' or "
				"'less'.");
			mdef->region_threshold = 0;
			return;
		}
		if (Kinds::compatible(mdef->region_kind,
			ValueProperties::kind(mdef->prop)) != ALWAYS_MATCH) {
			StandardProblems::definition_problem(Task::syntax_tree(),
				_p_(PM_GradingWrongKOV),
				mdef->measurement_node,
				"the property value given here is the wrong kind",
				"and does not match the property being looked at.");
			mdef->region_threshold = 0;
			return;
		}
	} else {
		LOG("Can't get literal from <%W>\n", mdef->region_threshold_text);
		StandardProblems::definition_problem(Task::syntax_tree(),
			_p_(PM_GradingNonLiteral),
			mdef->measurement_node,
			"that definition is wrongly phrased",
			"assuming it was meant to be a grading adjective like 'Definition: a "
			"container is large if its carrying capacity is 10 or more.'");
		return;
	}
	mdef->region_threshold_evaluated = TRUE;

@ To recover safely from these errors, we would be wise to check:

=
int Measurements::is_valid(measurement_definition *mdef) {
	if ((mdef->prop == NULL) || (mdef->region_threshold_evaluated == FALSE))
		return FALSE;
	return TRUE;
}

@h Comparative forms.
For timing reasons, these are made all at once, and later than when the headword
adjectives and superlatives are made.

=
void Measurements::create_comparatives(void) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition) {
		Measurements::validate(mdef);
		if ((Measurements::is_valid(mdef)) &&
			(mdef->region_shape != MEASURE_T_EXACTLY)) {
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
	inter_name *identifier = RTProperties::iname(mdef->prop);
	char *operation = Measurements::strict_comparison(mdef->region_shape);
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
	bp = BinaryPredicates::make_pair(property_comparison_bp_family,
		BPTerms::new(NULL), BPTerms::new(NULL),
		relname, NULL, NULL,
		schema_to_compare_property_values, WordAssemblages::lit_1(quiddity));
	DISCARD_TEXT(relname)
	ComparativeRelations::initialise(bp, mdef->region_shape, mdef->prop);
	Measurements::register_comparative(comparative_form, bp);

@h Late registration of prepositions comparing properties.
The following routines, used only when all the properties have been
created, make suitable comparatives ("bigger than", etc.) and
prepositional usages to test property-equality ("the same height as").

=
void Measurements::register_comparative(wording W, binary_predicate *root) {
	verb_meaning vm = VerbMeanings::regular(root);
	preposition *prep =
		Prepositions::make(PreformUtilities::merge(<comparative-property-construction>, 0,
			WordAssemblages::lit_1(Lexer::word(Wordings::first_wn(W)))),
			FALSE, current_sentence);
	Verbs::add_form(copular_verb, prep, NULL, vm, SVO_FS_BIT);
}

@ When the source text creates a measurement adjective such as "tall", the
following is used to construct the comparative form, "taller than":

=
<comparative-property-construction> ::=
	... than
