[ExtensionCensus::] Census.

To conduct a census of all installed extensions installed.

@h Beginning.
Each census begins by creating an object:

=
typedef struct extension_census {
	struct linked_list *search_list; /* of |inbuild_nest| */
	struct linked_list *census_data; /* of |extension_census_datum| */
	struct linked_list *raw_data; /* of |inbuild_search_result| */
	int no_census_errors;
	CLASS_DEFINITION
} extension_census;

@ Here |proj| will be null in case (a), and will be the project just
compiled in case (b).

=
extension_census *ExtensionCensus::new(inform_project *proj) {
	extension_census *C = CREATE(extension_census);
	
	if (proj == NULL) {
		C->search_list = Projects::nest_list(proj);
	} else {
		C->search_list = NEW_LINKED_LIST(inbuild_nest);
		ADD_TO_LINKED_LIST(C->search_list, inbuild_nest, proj->search_list);
		inbuild_nest *N;
		linked_list *L = Supervisor::shared_nest_list();
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, L)
			if (Nests::get_tag(N) == INTERNAL_NEST_TAG)
				ADD_TO_LINKED_LIST(N, inbuild_nest, C->search_list);
	}
	C->census_data = NEW_LINKED_LIST(extension_census_datum);
	C->raw_data = NEW_LINKED_LIST(inbuild_search_result);
	C->no_census_errors = 0;
	return C;
}

@ Each census object has its own search path for nests -- for case (a) the
shared search path, for (b) the project's search path.

=
pathname *ExtensionCensus::internal_path(extension_census *C) {
	inbuild_nest *N = NULL;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, C->search_list)
		if (Nests::get_tag(N) == INTERNAL_NEST_TAG)
			return ExtensionManager::path_within_nest(N);
	return NULL;
}

pathname *ExtensionCensus::external_path(extension_census *C) {
	inbuild_nest *N = NULL;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, C->search_list)
		if (Nests::get_tag(N) == EXTERNAL_NEST_TAG)
			return ExtensionManager::path_within_nest(N);
	return NULL;
}

@h Census data.
For each inhabitant found, so to speak, an instance of //extension_census_datum//
is created. (These are called ECDs below.)

=
typedef struct extension_census_datum {
	struct inbuild_search_result *found_as;
	int overriding_a_built_in_extension; /* not built in, but overriding one which is */
	struct extension_census_datum *next; /* next one in lexicographic order */
	CLASS_DEFINITION
} extension_census_datum;

@ An ECD is actually a wrapper for an //inform_extension// object in disguise,
since the //inbuild_search_result// found that.

=
text_stream *ExtensionCensus::ecd_rubric(extension_census_datum *ecd) {
	return Extensions::get_rubric(Extensions::from_copy(ecd->found_as->copy));
}

int ExtensionCensus::installation_region(extension_census_datum *ecd) {
	if (Nests::get_tag(ecd->found_as->nest) == MATERIALS_NEST_TAG) return 0;
	if (Nests::get_tag(ecd->found_as->nest) == INTERNAL_NEST_TAG) return 1;
	if (ecd->overriding_a_built_in_extension) return 2;
	return 3;
}

int ExtensionCensus::ecd_used(extension_census_datum *ecd) {
	inform_extension *E = Extensions::from_copy(ecd->found_as->copy);
	return E->has_historically_been_used;
}

@h Performing the census.
For some reason a census often makes a good story (cf. Luke 2:1-5), but here
there's disappointingly little to tell, because the work is all done by a
single call to //Nests::search_for//.

=
extension_census *ExtensionCensus::perform(inform_project *proj) {
	extension_census *C = ExtensionCensus::new(proj);
	inbuild_requirement *req = Requirements::anything_of_genre(extension_genre);
	Nests::search_for(req, C->search_list, C->raw_data);
	
	inbuild_search_result *R;
	LOOP_OVER_LINKED_LIST(R, inbuild_search_result, C->raw_data) {
		C->no_census_errors += LinkedLists::len(R->copy->errors_reading_source_text);
		int overridden_by_an_extension_already_found = FALSE;
		@<See if already known from existing data@>;
		if (overridden_by_an_extension_already_found == FALSE)
			@<Add to the census data@>;
	}
	return C;
}

@ Recall that the higher-priority materials and external nests are scanned
first, so if we find that our new extension has the same title and author as
one already known, it must be one that is overridden.

@<See if already known from existing data@> =
	extension_census_datum *other;
	LOOP_OVER_LINKED_LIST(other, extension_census_datum, C->census_data)
		if ((Works::match(R->copy->edition->work,
			other->found_as->copy->edition->work)) &&
			((Nests::get_tag(other->found_as->nest) == INTERNAL_NEST_TAG) ||
				(Nests::get_tag(R->nest) == INTERNAL_NEST_TAG))) {
			other->overriding_a_built_in_extension = TRUE;
			overridden_by_an_extension_already_found = TRUE;
		}

@ Assuming the new extension was not overridden in this way, we come here.
Because we didn't check the version number text for validity, it might
through being invalid be longer than we expect: in case this is so, we
truncate it.

@<Add to the census data@> =
	extension_census_datum *ecd = CREATE(extension_census_datum);
	ecd->found_as = R;
	ecd->overriding_a_built_in_extension = FALSE;
	ecd->next = NULL;
