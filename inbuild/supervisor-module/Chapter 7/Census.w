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
	C->search_list = Projects::nest_list(proj);
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
	return Extensions::get_rubric(ExtensionManager::from_copy(ecd->found_as->copy));
}

int ExtensionCensus::installation_region(extension_census_datum *ecd) {
	if (Nests::get_tag(ecd->found_as->nest) == MATERIALS_NEST_TAG) return 0;
	if (Nests::get_tag(ecd->found_as->nest) == INTERNAL_NEST_TAG) return 1;
	if (ecd->overriding_a_built_in_extension) return 2;
	return 3;
}

int ExtensionCensus::ecd_used(extension_census_datum *ecd) {
	inform_extension *E = ExtensionManager::from_copy(ecd->found_as->copy);
	return E->has_historically_been_used;
}

@ The following give some sorting criteria, and are functions fit to be
handed to |qsort|.

=
int ExtensionCensus::compare_ecd_by_title(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	inform_extension *E1 = ExtensionManager::from_copy(e1->found_as->copy);
	inform_extension *E2 = ExtensionManager::from_copy(e2->found_as->copy);
	return Extensions::compare_by_title(E2, E1);
}

int ExtensionCensus::compare_ecd_by_author(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	inform_extension *E1 = ExtensionManager::from_copy(e1->found_as->copy);
	inform_extension *E2 = ExtensionManager::from_copy(e2->found_as->copy);
	return Extensions::compare_by_author(E2, E1);
}

int ExtensionCensus::compare_ecd_by_installation(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	int d = ExtensionCensus::installation_region(e1) -
		ExtensionCensus::installation_region(e2);
	if (d != 0) return d;
	inform_extension *E1 = ExtensionManager::from_copy(e1->found_as->copy);
	inform_extension *E2 = ExtensionManager::from_copy(e2->found_as->copy);
	return Extensions::compare_by_edition(E1, E2);
}

int ExtensionCensus::compare_ecd_by_date(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	inform_extension *E1 = ExtensionManager::from_copy(e1->found_as->copy);
	inform_extension *E2 = ExtensionManager::from_copy(e2->found_as->copy);
	return Extensions::compare_by_date(E1, E2);
}

int ExtensionCensus::compare_ecd_by_length(const void *ecd1, const void *ecd2) {
	extension_census_datum *e1 = *((extension_census_datum **) ecd1);
	extension_census_datum *e2 = *((extension_census_datum **) ecd2);
	inform_extension *E1 = ExtensionManager::from_copy(e1->found_as->copy);
	inform_extension *E2 = ExtensionManager::from_copy(e2->found_as->copy);
	return Extensions::compare_by_length(E1, E2);
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
