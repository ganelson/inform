[Properties::OfValues::] Properties of Values.

Two unrelated but minor support needs for properties of values which
are not objects.

@h In-table storage.
Some kinds of non-object are created by table, with the table columns holding the
relevant property values. The following structure indicates which column of
which table will store the property values at run-time, or else is left as
|-1, 0| if the property values aren't living inside a table structure.

=
typedef struct property_of_value_storage {
	struct inter_name *storage_table_iname; /* for the relevant column array */
	CLASS_DEFINITION
} property_of_value_storage;

property_of_value_storage *latest_povs = NULL; /* see below */

@ It's a little inconvenient to work out some elegant mechanism for the table
compilation code to tell each kind where it will be living, so instead we
rely on the fact that we're doing one at a time. The table-compiler simply
calls this routine to notify us of where the next batch of properties will be,
and we mark them down in the most recently created property permission.

=
property_of_value_storage *Properties::OfValues::get_storage(void) {
	property_of_value_storage *povs = CREATE(property_of_value_storage);
	povs->storage_table_iname = NULL;
	latest_povs = povs;
	return povs;
}

void Properties::OfValues::pp_set_table_storage(inter_name *store) {
if (store == NULL) internal_error("ugh");
	if (latest_povs) {
		latest_povs->storage_table_iname = store;
	}
}

@ The code generator will need to know these numbers, so we will annotate
the property-permission symbol accordingly:

=
inter_name *Properties::OfValues::annotate_table_storage(property_permission *pp) {
	property_of_value_storage *povs =
		RETRIEVE_POINTER_property_of_value_storage(PropertyPermissions::get_storage_data(pp));
	return povs->storage_table_iname;
}

@h Avoiding a hacky I6 problem.
This is a rather distasteful provision, like everything to do with I6
translation. But we don't want to hand the problem downstream to the code
generator; we want to deal with it now. The issue arises with source text like:

>> A keyword is a kind of value. The keywords are xyzzy, plugh. A keyword can be mentioned.

where "mentioned" is implemented for objects as an |Attribute| in the I6 sense.
That would make it impossible for the code-generator to store the property
instead in a flat array, which is how it will want to handle properties of
values. There are ways we could fix this, but property lookup needs to be fast,
and it seems best to reject the extra complexity needed.

=
void Properties::OfValues::check_allowable(kind *K) {
	if (Kinds::Behaviour::is_object(K)) return;
	if (Kinds::Behaviour::definite(K) == FALSE) return;
	property *prn;
	property_permission *pp;
	instance *I_of;
	inference_subject *infs;
	LOOP_OVER_INSTANCES(I_of, K)
		for (infs = Instances::as_subject(I_of); infs; infs = InferenceSubjects::narrowest_broader_subject(infs))
			LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs)
				if (((prn = PropertyPermissions::get_property(pp))) &&
					(Properties::can_be_compiled(prn)))
					@<Check that the property is allowable here@>;
}

@<Check that the property is allowable here@> =
	if ((problem_count == 0) &&
		(Properties::has_been_translated(prn)) &&
		(Properties::is_either_or(prn))) {
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
		return;
	}
