[HierarchyLocations::] Hierarchy Locations.

@

=
typedef struct named_resource_location {
	int access_number;
	struct text_stream *access_name;
	struct text_stream *function_package_name;
	struct text_stream *datum_package_name;
	struct package_request *package;
	int exotic_package_identifier;
	struct inter_name *equates_to_iname;
	MEMORY_MANAGEMENT
} named_resource_location;

named_resource_location *HierarchyLocations::new(void) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = -1;
	nrl->access_name = NULL;
	nrl->function_package_name = NULL;
	nrl->datum_package_name = NULL;
	nrl->package = NULL;
	nrl->equates_to_iname = NULL;
	nrl->exotic_package_identifier = -1;
	return nrl;
}

named_resource_location *HierarchyLocations::make_in(int id, text_stream *name, package_request *P) {
	named_resource_location *nrl = HierarchyLocations::new();
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->package = P;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_in_exotic(int id, text_stream *name, int x) {
	named_resource_location *nrl = HierarchyLocations::new();
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->exotic_package_identifier = x;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_as(int id, text_stream *name, inter_name *iname) {
	named_resource_location *nrl = HierarchyLocations::new();
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->package = iname->eventual_owner;
	nrl->equates_to_iname = iname;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_function(int id, text_stream *name, text_stream *call_name, package_request *P) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(call_name);
	nrl->function_package_name = Str::duplicate(name);
	nrl->package = P;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_function_in_exotic(int id, text_stream *name, text_stream *call_name, int x) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(call_name);
	nrl->function_package_name = Str::duplicate(name);
	nrl->exotic_package_identifier = x;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_datum(int id, text_stream *name, text_stream *datum_name, package_request *P) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(datum_name);
	nrl->datum_package_name = Str::duplicate(name);
	nrl->package = P;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_datum_in_exotic(int id, text_stream *name, text_stream *datum_name, int x) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(datum_name);
	nrl->datum_package_name = Str::duplicate(name);
	nrl->exotic_package_identifier = x;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *nrls_indexed_by_id[MAX_HL];
dictionary *nrls_indexed_by_name = NULL;

int nrls_created = FALSE;
void HierarchyLocations::create_nrls(void) {
	nrls_created = TRUE;
	for (int i=0; i<MAX_HL; i++) nrls_indexed_by_id[i] = NULL;
	nrls_indexed_by_name = Dictionaries::new(512, FALSE);
	Hierarchy::establish();
}

void HierarchyLocations::index(named_resource_location *nrl) {
	if (nrls_created == FALSE) HierarchyLocations::create_nrls();
	if (nrl->access_number >= 0) nrls_indexed_by_id[nrl->access_number] = nrl;
	Dictionaries::create(nrls_indexed_by_name, nrl->access_name);
	Dictionaries::write_value(nrls_indexed_by_name, nrl->access_name, (void *) nrl);
}

inter_name *HierarchyLocations::find(int id) {
	if (nrls_created == FALSE) HierarchyLocations::create_nrls();
	if ((id < 0) || (id >= MAX_HL) || (nrls_indexed_by_id[id] == NULL))
		internal_error("bad nrl ID");
	return HierarchyLocations::nrl_to_iname(nrls_indexed_by_id[id]);
}

inter_name *HierarchyLocations::find_by_name(text_stream *name) {
	if (Str::len(name) == 0) internal_error("bad nrl name");
	if (nrls_created == FALSE) HierarchyLocations::create_nrls();
	if (Dictionaries::find(nrls_indexed_by_name, name))
		return HierarchyLocations::nrl_to_iname(
			(named_resource_location *)
				Dictionaries::read_value(nrls_indexed_by_name, name));
	return NULL;
}

inter_name *HierarchyLocations::function(package_request *R, text_stream *name, text_stream *trans) {
	inter_name *iname = Packaging::function(InterNames::one_off(name, R), R, NULL);
	if (trans) Inter::Symbols::set_translate(InterNames::to_symbol(iname), trans);
	return iname;
}

inter_name *HierarchyLocations::nrl_to_iname(named_resource_location *nrl) {
	if (nrl->equates_to_iname == NULL) {
		if (nrl->package == NULL) {
			if (nrl->exotic_package_identifier >= 0)
				nrl->package = Hierarchy::exotic_package(nrl->exotic_package_identifier);
			else internal_error("package can't be found'");
		}

		if (nrl->package == Packaging::request_template()) {
			packaging_state save = Packaging::enter(nrl->package);
			nrl->equates_to_iname = InterNames::one_off(nrl->access_name, Packaging::request_template());
			nrl->equates_to_iname->symbol = Emit::extern(nrl->access_name, K_value);
			Packaging::exit(save);
		} else if (Str::len(nrl->function_package_name) > 0) {
			nrl->equates_to_iname = Packaging::function_text(
				InterNames::one_off(nrl->function_package_name, nrl->package),
				nrl->package,
				nrl->access_name);
		} else if (Str::len(nrl->datum_package_name) > 0) {
			nrl->equates_to_iname = Packaging::datum_text(
				InterNames::one_off(nrl->datum_package_name, nrl->package),
				nrl->package,
				nrl->access_name);
		} else if ((nrl->package) && (nrl->equates_to_iname == NULL)) {
			nrl->equates_to_iname = InterNames::one_off(nrl->access_name, nrl->package);
		}

		nrl->equates_to_iname = Hierarchy::post_process(nrl->access_number, nrl->equates_to_iname);
		nrl->package = Packaging::home_of(nrl->equates_to_iname);
	}
	return nrl->equates_to_iname;
}
