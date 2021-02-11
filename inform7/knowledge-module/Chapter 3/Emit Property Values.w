[Properties::Emit::] Emit Property Values.

To feed the hierarchy of instances and their property values into Inter.

@h Emitting the property values.
The following routine is called on every kind which can have properties,
and also on every individual instance of those kinds. Superkinds are called
before subkinds, and kinds are called before their instances, but we don't
manage that here.

=
inter_ti cs_sequence_counter = 0;
void Properties::Emit::emit_subject(inference_subject *subj) {
	LOGIF(OBJECT_COMPILATION, "Compiling object definition for $j\n", subj);
	kind *K = Kinds::Knowledge::from_infs(subj);
	instance *I = Instances::from_infs(subj);

	int words_used = 0;
	if (K) Plugins::Call::estimate_property_usage(K, &words_used);

	inter_name *iname = NULL;
	if (K) iname = Kinds::RunTime::iname(K);
	else if (I) iname = Instances::emitted_iname(I);
	else internal_error("bad subject for emission");

	Produce::annotate_i(iname, DECLARATION_ORDER_IANN, cs_sequence_counter++);

	@<Compile the actual object@>;
	if (K) {
		World::Compile::set_rough_memory_usage(K, words_used);
		int nw = 0;
		for (inference_subject *infs = subj;
			infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
			kind *K2 = Kinds::Knowledge::from_infs(infs);
			if (K2) nw += World::Compile::get_rough_memory_usage(K2);
		}
		nw += 16;
		LOGIF(OBJECT_COMPILATION, "Rough size estimate: %d words\n", nw);
	}
	LOGIF(OBJECT_COMPILATION, "Compilation of $j complete\n", subj);
}

@ We need to compile |with| or |has| clauses for all the properties our
object will have, and we need to be careful not to compile them more than
once, even if there's more than one permission recorded for a given
property; so we do this with a "traverse" of the properties, in which
each one is marked when visited.

@<Compile the actual object@> =
	@<Annotate with the spatial depth@>;
	if ((I) && (Kinds::Behaviour::is_object(Instances::to_kind(I)))) words_used++;
	@<Append any inclusions the source text requested@>;
	Properties::begin_traverse();
	@<Emit inferred object properties@>;
	@<Emit permitted but unspecified object properties@>;

@<Annotate with the spatial depth@> =
	#ifdef IF_MODULE
	if ((I) && (Kinds::Behaviour::is_object(Instances::to_kind(I)))) {
		int AC = PL::Spatial::get_definition_depth(I);
		if (AC > 0) Produce::annotate_i(iname, ARROW_COUNT_IANN, (inter_ti) AC);
	}
	#endif

@ This is an ugly business, but the I7 language supports the injection of raw
I6 code into object bodies, and the I6 template does make use of this a little.
In an ideal world we would revoke this ability.

@<Append any inclusions the source text requested@> =
	TEMPORARY_TEXT(incl)
	Config::Inclusions::compile_inclusions_for_subject(incl, subj);
	if (Str::len(incl) > 0) Emit::append(iname, incl);
	DISCARD_TEXT(incl)

@ Now, here goes with the properties. We first compile clauses for those we
know about, then for any other properties which are permitted but apparently
not set. Note that we only look through knowledge and permissions associated
with |subj| itself; we've no need to look at those for its kind (and its kind's
kind, and so on) because the Inform 6 compiler automatically inherits those
through the |Class| hierarchy of I6 objects -- this is why we have made
the class hierarchy at I6 level exactly match the kind hierarchy at I7 level.

@<Emit inferred object properties@> =
	inference *inf;
	KNOWLEDGE_LOOP(inf, subj, PROPERTY_INF) {
		property *prn = World::Inferences::get_property(inf);
		current_sentence = World::Inferences::where_inferred(inf);
		LOGIF(OBJECT_COMPILATION, "Compiling property $Y\n", prn);
		words_used += Properties::Emit::emit_propertyvalue(subj, prn);
	}

@ We now wander through the permitted properties, even those which we have
no actual knowledge about.

@<Emit permitted but unspecified object properties@> =
	inference_subject *infs;
	for (infs = subj; infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		property_permission *pp;
		LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs) {
			property *prn = World::Permissions::get_property(pp);
			if ((infs == subj) ||
				(Kinds::Behaviour::uses_pointer_values(Properties::Valued::kind(prn))))
				words_used += Properties::Emit::emit_propertyvalue(subj, prn);
		}
	}

@ Either way, then, we end up here. The following works out what initial
value the property will have, and compiles a clause as appropriate.

=
int Properties::Emit::emit_propertyvalue(inference_subject *know, property *prn) {
	package_request *R = NULL;
	instance *I = Instances::from_infs(know);
	if (I) R = Instances::package(I);
	kind *K = Kinds::Knowledge::from_infs(know);
	if (K) R = Kinds::Behaviour::package(K);
	int storage_cost = 0;
	if ((Properties::visited_in_traverse(prn) == FALSE) &&
		(Properties::can_be_compiled(prn))) {
		if ((Properties::is_either_or(prn)) &&
			(Properties::EitherOr::stored_in_negation(prn)))
			prn = Properties::EitherOr::get_negation(prn);
		value_holster VH = Holsters::new(INTER_DATA_VHMODE);
		Properties::compile_inferred_value(&VH, know, prn);
		@<Now emit a propertyvalue@>;
	}
	return storage_cost;
}

@<Now emit a propertyvalue@> =
	instance *as_I = Instances::from_infs(know);
	kind *as_K = Kinds::Knowledge::from_infs(know);
	inter_ti v1 = LITERAL_IVAL, v2 = (inter_ti) FALSE;
	property *in = prn;

	Holsters::unholster_pair(&VH, &v1, &v2);

	if ((Properties::is_either_or(prn)) && (Properties::EitherOr::implemented_as_attribute(prn))) {
		if (Properties::EitherOr::stored_in_negation(prn)) {
			in = Properties::EitherOr::get_negation(prn);
			v2 = (inter_ti) (v2)?FALSE:TRUE;
		}
	}
	if (as_I) Emit::instance_propertyvalue(in, as_I, v1, v2);
	else Emit::propertyvalue(in, as_K, v1, v2);

@h Attribute allocation.
At some later stage the business of deciding which properties are stored
at I6 run-time as attributes will be solely up to the code generator.
For now, though, we make a parallel decision here.

=
void Properties::Emit::allocate_attributes(void) {
	int slots_given_away = 0;
	property *prn;
	LOOP_OVER(prn, property) {
		if ((Properties::is_either_or(prn)) &&
			(Properties::EitherOr::stored_in_negation(prn) == FALSE)) {
			int make_attribute = NOT_APPLICABLE;
			@<Any either/or property which some value can hold is ineligible@>;
			@<An either/or property translated to an existing attribute must be chosen@>;
			@<Otherwise give away attribute slots on a first-come-first-served basis@>;
			Properties::EitherOr::implement_as_attribute(prn, make_attribute);
		}
	}
}

@<Any either/or property which some value can hold is ineligible@> =
	property_permission *pp;
	LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn) {
		inference_subject *infs = World::Permissions::get_subject(pp);
		if ((InferenceSubjects::is_an_object(infs) == FALSE) &&
			(InferenceSubjects::is_a_kind_of_object(infs) == FALSE))
			make_attribute = FALSE;
	}

@<An either/or property translated to an existing attribute must be chosen@> =
	if (Properties::has_been_translated(prn)) make_attribute = TRUE;

@<Otherwise give away attribute slots on a first-come-first-served basis@> =
	if (make_attribute == NOT_APPLICABLE) {
		if (slots_given_away++ < ATTRIBUTE_SLOTS_TO_GIVE_AWAY)
			make_attribute = TRUE;
		else
			make_attribute = FALSE;
	}

@h Rapid run-time testing.
The preferred way to access either/or properties of an object at run-time
is to use the pair of routines |GetEitherOrProperty| or
|SetEitherOrProperty|, defined in the I6 template, because that way
suitable run-time problems are generated for mistaken accesses. But if we
want the fastest possible access and know that it will be valid, we can use
the following.

=
void Properties::Emit::emit_iname_has_property(kind *K, inter_name *N, property *prn) {
	Properties::Emit::emit_has_property(K, InterNames::to_symbol(N), prn);
}
void Properties::Emit::emit_has_property(kind *K, inter_symbol *S, property *prn) {
	if (Properties::EitherOr::implemented_as_attribute(prn)) {
		if (Properties::EitherOr::stored_in_negation(prn)) {
			Produce::inv_primitive(Emit::tree(), NOT_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), HAS_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K, S);
					Produce::val_iname(Emit::tree(), K_value, Properties::iname(Properties::EitherOr::get_negation(prn)));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), HAS_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K, S);
				Produce::val_iname(Emit::tree(), K_value, Properties::iname(prn));
			Produce::up(Emit::tree());
		}
	} else {
		if (Properties::EitherOr::stored_in_negation(prn)) {
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K, S);
					Produce::val_iname(Emit::tree(), K_value, Properties::iname(Properties::EitherOr::get_negation(prn)));
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K, S);
					Produce::val_iname(Emit::tree(), K_value, Properties::iname(prn));
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
			Produce::up(Emit::tree());
		}
	}
}
