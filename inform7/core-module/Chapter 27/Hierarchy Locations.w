[HierarchyLocations::] Hierarchy Locations.

@

=
typedef struct named_resource_location {
	int access_number;
	struct text_stream *access_name;
	struct text_stream *function_package_name;
	struct text_stream *datum_package_name;
	struct package_request *package;
	struct inter_symbol *package_type;
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
	nrl->package_type = NULL;
	nrl->equates_to_iname = NULL;
	nrl->exotic_package_identifier = -1;
	return nrl;
}

named_resource_location *HierarchyLocations::make(int id, text_stream *name, package_request *P) {
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

named_resource_location *HierarchyLocations::make_rulebook_within(int id, text_stream *name, inter_symbol *ptype) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->package_type = ptype;
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
	if (nrl->package_type == NULL) {
		Dictionaries::create(nrls_indexed_by_name, nrl->access_name);
		Dictionaries::write_value(nrls_indexed_by_name, nrl->access_name, (void *) nrl);
	}
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
	if (nrl->package_type) internal_error("NRL accessed inappropriately");
	if (nrl->equates_to_iname == NULL) {
		if (nrl->package == NULL) {
			if (nrl->exotic_package_identifier >= 0)
				nrl->package = Hierarchy::exotic_package(nrl->exotic_package_identifier);
			else internal_error("package can't be found'");
		}

		if (nrl->package == Hierarchy::template()) {
			packaging_state save = Packaging::enter(nrl->package);
			nrl->equates_to_iname = InterNames::one_off(nrl->access_name, Hierarchy::template());
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

package_request *HierarchyLocations::package_in_package(int id, package_request *P) {
	if (nrls_created == FALSE) HierarchyLocations::create_nrls();
	if ((id < 0) || (id >= MAX_HL) || (nrls_indexed_by_id[id] == NULL))
		internal_error("bad nrl ID");
	named_resource_location *nrl = nrls_indexed_by_id[id];
	if (nrl->package_type == NULL) internal_error("NRL accessed inappropriately");
	if ((P == NULL) || (P->eventual_type != nrl->package_type)) internal_error("subpackage in wrong superpackage");
	return Packaging::request(InterNames::one_off(nrl->access_name, P), P, nrl->package_type);
}

@

@e BOGUS_HAP from 0

=
typedef struct hierarchy_attachment_point {
	int submodule;
	int counter;
	struct inter_symbol *type;
	struct inter_symbol *super_type;
	int synoptic_flag;
	MEMORY_MANAGEMENT
} hierarchy_attachment_point;

hierarchy_attachment_point *haps_indexed_by_id[MAX_HAP];

int haps_created = FALSE;
void HierarchyLocations::create_haps(void) {
	haps_created = TRUE;
	for (int i=0; i<MAX_HAP; i++) haps_indexed_by_id[i] = NULL;
}

hierarchy_attachment_point *HierarchyLocations::ap(int ap_id, int submodule_id, text_stream *iterated_text, inter_symbol *ptype) {
	hierarchy_attachment_point *hap = CREATE(hierarchy_attachment_point);
	hap->submodule = submodule_id;
	hap->counter = Packaging::register_counter(iterated_text);
	hap->type = ptype;
	hap->super_type = NULL;
	hap->synoptic_flag = FALSE;
	if (haps_created == FALSE) HierarchyLocations::create_haps();
	if (ap_id >= 0) haps_indexed_by_id[ap_id] = hap;
	return hap;
}

hierarchy_attachment_point *HierarchyLocations::synoptic_ap(int ap_id, int submodule_id, text_stream *iterated_text, inter_symbol *ptype) {
	hierarchy_attachment_point *hap = HierarchyLocations::ap(ap_id, submodule_id, iterated_text, ptype);
	hap->synoptic_flag = TRUE;
	return hap;
}

hierarchy_attachment_point *HierarchyLocations::ap_within(int ap_id, inter_symbol *sptype, text_stream *iterated_text, inter_symbol *ptype) {
	hierarchy_attachment_point *hap = HierarchyLocations::ap(ap_id, -1, iterated_text, ptype);
	hap->super_type = sptype;
	return hap;
}

package_request *HierarchyLocations::resource_package(compilation_module *C, int hap_id) {
	if ((hap_id < 0) || (hap_id >= MAX_HAP) || (haps_created == FALSE) || (haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = haps_indexed_by_id[hap_id];
	package_request *R = Packaging::request_resource(C, hap->submodule);
	if (hap->synoptic_flag) internal_error("subpackage is synoptic");
	return Packaging::request(Packaging::supply_iname(R, hap->counter), R, hap->type);
}

package_request *HierarchyLocations::package(compilation_module *C, int hap_id) {
	if ((hap_id < 0) || (hap_id >= MAX_HAP) || (haps_created == FALSE) || (haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = haps_indexed_by_id[hap_id];
	if (hap->super_type) internal_error("subpackage in top-level submodule");
	package_request *R = Packaging::request_resource(C, hap->submodule);
	if (hap->synoptic_flag) internal_error("subpackage is synoptic");
	return Packaging::request(Packaging::supply_iname(R, hap->counter), R, hap->type);
}

package_request *HierarchyLocations::package_within(package_request *R, int hap_id) {
	if ((hap_id < 0) || (hap_id >= MAX_HAP) || (haps_created == FALSE) || (haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = haps_indexed_by_id[hap_id];
	if ((R == NULL) || (R->eventual_type != hap->super_type)) internal_error("subpackage in wrong superpackage");
	if (hap->synoptic_flag) internal_error("subpackage is synoptic");
	return Packaging::request(Packaging::supply_iname(R, hap->counter), R, hap->type);
}

package_request *HierarchyLocations::synoptic_package(int hap_id) {
	if ((hap_id < 0) || (hap_id >= MAX_HAP) || (haps_created == FALSE) || (haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = haps_indexed_by_id[hap_id];
	if (hap->synoptic_flag == FALSE) internal_error("subpackage not synoptic");
	package_request *R = Packaging::synoptic_resource(hap->submodule);
	return Packaging::request(Packaging::supply_iname(R, hap->counter), R, hap->type);
}
