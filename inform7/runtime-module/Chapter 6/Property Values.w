[RTPropertyValues::] Property Values.

Compiling Inter property value instructions for the properties of instances
and kinds.

@h Of instances and kinds.
These are the only two functions to call from outside this section:

=
void RTPropertyValues::compile_values_for_instance(instance *I) {
	RTPropertyValues::emit_subject(Instances::as_subject(I));
}

void RTPropertyValues::compile_values_for_kind(kind *K) {
	RTPropertyValues::emit_subject(KindSubjects::from_kind(K));
	RTPropertyValues::check_kind_can_have_property(K);
}

@h Of subjects.
So this is the common code to handle both:

=
void RTPropertyValues::emit_subject(inference_subject *subj) {
	LOGIF(OBJECT_COMPILATION, "Compiling properties for $j\n", subj);
	current_sentence = subj->infs_created_at;
	packaging_state save = Packaging::enter(RTPropertyPermissions::home(subj));

	@<Append any inclusions the source text requested@>;
	RTPropertyValues::begin_traverse();
	@<Emit inferred object properties@>;
	@<Emit permitted but unspecified object properties@>;

	Packaging::exit(Emit::tree(), save);
	LOGIF(OBJECT_COMPILATION, "Compilation of $j complete\n", subj);
}

@ This is an ugly business, but the I7 language supports the injection of raw
Inter code into object bodies. In an ideal world we would revoke this ability;
the Standard Rules do not use it.

@<Append any inclusions the source text requested@> =
	inter_name *iname = RTPropertyPermissions::owner(subj);
	if (iname == NULL) internal_error("unsupported subject for emission");
	Interventions::make_for_subject(iname, subj);

@ Now, here goes with the properties:

@<Emit inferred object properties@> =
	inference *inf;
	KNOWLEDGE_LOOP(inf, subj, property_inf) {
		property *prn = PropertyInferences::get_property(inf);
		current_sentence = Inferences::where_inferred(inf);
		LOGIF(OBJECT_COMPILATION, "Compiling property $Y\n", prn);
		@<Emit the value of this property of the subject@>;
	}

@ We now wander through the permitted properties, even those which we have
no actual knowledge about.

@<Emit permitted but unspecified object properties@> =
	for (inference_subject *infs = subj; infs; infs =
		InferenceSubjects::narrowest_broader_subject(infs)) {
		property_permission *pp;
		LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs) {
			property *prn = PropertyPermissions::get_property(pp);
			if ((infs == subj) ||
				(Kinds::Behaviour::uses_block_values(ValueProperties::kind(prn))))
				@<Emit the value of this property of the subject@>;
		}
	}

@ Either way, then, we end up here. The following works out what initial
value the property will have, and compiles a clause as appropriate.

=
@<Emit the value of this property of the subject@> =
	if ((RTPropertyValues::visited_in_traverse(prn) == FALSE) &&
		(RTProperties::can_be_compiled(prn))) {
		if ((Properties::is_either_or(prn)) &&
			(RTProperties::stored_in_negation(prn)))
			prn = EitherOrProperties::get_negation(prn);
		packaging_state save = Packaging::enter(RTPropertyPermissions::home(subj));
		value_holster VH = Holsters::new(INTER_DATA_VHMODE);
		Properties::compile_inferred_value(&VH, subj, prn);
		inter_ti v1 = LITERAL_IVAL, v2 = 0;
		Holsters::unholster_to_pair(&VH, &v1, &v2);
		Emit::propertyvalue(prn, RTPropertyPermissions::owner(subj), v1, v2);
		Packaging::exit(Emit::tree(), save);
	}

@ The following provides a mechanism to tell whether we have visited a property
before. (Where visiting an either/or property also visits its negation.) This
ensures that we cannot compile the same property of the same subject twice.

=
int property_traverse_count = 0;
void RTPropertyValues::begin_traverse(void) {
	property_traverse_count++;
}

int RTPropertyValues::visited_in_traverse(property *prn) {
	if (prn->compilation_data.visited_on_traverse == property_traverse_count) return TRUE;
	prn->compilation_data.visited_on_traverse = property_traverse_count;
	if (Properties::is_either_or(prn)) {
		property *prnbar = EitherOrProperties::get_negation(prn);
		if (prnbar) prnbar->compilation_data.visited_on_traverse = property_traverse_count;
	}
	return FALSE;
}

@ This is a rather annoying provision, like everything to do with Inter
translation. But we don't want to hand the problem downstream to the code
generator; we want to deal with it now. The issue arises with source text like:

>> A keyword is a kind of value. The keywords are xyzzy, plugh. A keyword can be mentioned.

where "mentioned" is implemented for objects as an attribute in Inter.

That would make it impossible for the code-generator to store the property
instead in a flat array, which is how it will want to handle properties of
values. There are ways we could fix this, but property lookup needs to be fast,
and it seems best to reject the extra complexity needed.

=
void RTPropertyValues::check_kind_can_have_property(kind *K) {
	if (Kinds::Behaviour::is_object(K)) return;
	if (Kinds::Behaviour::definite(K) == FALSE) return;
	property *prn;
	property_permission *pp;
	instance *I_of;
	inference_subject *infs;
	LOOP_OVER_INSTANCES(I_of, K)
		for (infs = Instances::as_subject(I_of); infs;
			infs = InferenceSubjects::narrowest_broader_subject(infs))
			LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs)
				if (((prn = PropertyPermissions::get_property(pp))) &&
					(RTProperties::can_be_compiled(prn)) &&
					(problem_count == 0) &&
					(RTProperties::has_been_translated(prn)) &&
					(Properties::is_either_or(prn)))
					@<Bitch about our implementation woes, like it's not our fault@>;
}

@<Bitch about our implementation woes, like it's not our fault@> =
	current_sentence = PropertyPermissions::where_granted(pp);
	Problems::quote_source(1, current_sentence);
	Problems::quote_property(2, prn);
	Problems::quote_kind(3, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AnomalousProperty));
	Problems::issue_problem_segment(
		"Sorry, but I'm going to have to disallow the sentence %1, even "
		"though it asks for something reasonable. A very small number "
		"of either-or properties with meanings special to Inform, like '%2', "
		"are restricted so that only kinds of object can have them. Since "
		"%3 isn't a kind of object, it can't be said to be %2. %P"
		"Probably you only need to call the property something else. The "
		"built-in meaning would only make sense if it were a kind of object "
		"in any case, so nothing is lost. Sorry for the inconvenience, all "
		"the same; there are good implementation reasons.");
	Problems::issue_problem_end();
