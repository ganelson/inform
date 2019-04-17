[HierarchyLocations::] Hierarchy Locations.

@

=
typedef struct location_requirement {
	struct submodule_identity *this_local_submodule;
	struct package_request *this_mundane_package;
	int this_exotic_package;
	struct inter_symbol *any_package_of_this_type;
	int any_enclosure;
} location_requirement;

location_requirement HierarchyLocations::blank(void) {
	location_requirement req;
	req.this_local_submodule = NULL;
	req.this_mundane_package = NULL;
	req.this_exotic_package = -1;
	req.any_package_of_this_type = NULL;
	req.any_enclosure = FALSE;
	return req;
}

location_requirement HierarchyLocations::local_submodule(submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.this_local_submodule = sid;
	return req;
}

location_requirement HierarchyLocations::generic_submodule(submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.this_mundane_package = Packaging::generic_resource(sid);
	return req;
}

location_requirement HierarchyLocations::synoptic_submodule(submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.this_mundane_package = Packaging::synoptic_resource(sid);
	return req;
}

location_requirement HierarchyLocations::any_package_of_type(text_stream *ptype_name) {
	location_requirement req = HierarchyLocations::blank();
	req.any_package_of_this_type = HierarchyLocations::ptype(ptype_name);
	return req;
}

location_requirement HierarchyLocations::any_enclosure(void) {
	location_requirement req = HierarchyLocations::blank();
	req.any_enclosure = TRUE;
	return req;
}

location_requirement HierarchyLocations::this_package(package_request *P) {
	location_requirement req = HierarchyLocations::blank();
	req.this_mundane_package = P;
	return req;
}

location_requirement HierarchyLocations::this_exotic_package(int N) {
	location_requirement req = HierarchyLocations::blank();
	req.this_exotic_package = N;
	return req;
}

typedef struct named_resource_location {
	int access_number;
	struct text_stream *access_name;
	struct text_stream *function_package_name;
	struct text_stream *datum_package_name;
	struct location_requirement requirements;
	struct inter_name *equates_to_iname;
	struct inter_symbol *package_type;
	struct name_translation trans;
	MEMORY_MANAGEMENT
} named_resource_location;

named_resource_location *HierarchyLocations::new(void) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = -1;
	nrl->access_name = NULL;
	nrl->function_package_name = NULL;
	nrl->datum_package_name = NULL;
	nrl->equates_to_iname = NULL;
	nrl->package_type = NULL;
	nrl->trans = Translation::same();
	nrl->requirements = HierarchyLocations::blank();
	return nrl;
}

named_resource_location *HierarchyLocations::con(int id, text_stream *name, name_translation nt, location_requirement req) {
	named_resource_location *nrl = HierarchyLocations::new();
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->requirements = req;
	nrl->trans = nt;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::package(int id, text_stream *name, text_stream *ptype_name, location_requirement req) {
	named_resource_location *nrl = HierarchyLocations::new();
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->requirements = req;
	nrl->package_type = HierarchyLocations::ptype(ptype_name);
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_as(int id, text_stream *name, inter_name *iname) {
	named_resource_location *nrl = HierarchyLocations::new();
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->requirements = HierarchyLocations::this_package(iname->eventual_owner);
	nrl->equates_to_iname = iname;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::func(int id, text_stream *name, name_translation nt, location_requirement req) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(nt.translate_to);
	nrl->function_package_name = Str::duplicate(name);
	nrl->requirements = req;
	nrl->trans = nt;
	HierarchyLocations::index(nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::datum(int id, text_stream *name, name_translation nt, location_requirement req) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(nt.translate_to);
	nrl->datum_package_name = Str::duplicate(name);
	nrl->requirements = req;
	nrl->trans = nt;
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
	if (nrl->requirements.any_package_of_this_type == NULL) {
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
	inter_name *iname = Packaging::function(InterNames::make(name, R), R, NULL);
	if (trans) InterNames::change_translation(iname, trans);
	return iname;
}

inter_name *HierarchyLocations::nrl_to_iname(named_resource_location *nrl) {
	if (nrl->requirements.any_package_of_this_type) internal_error("NRL accessed inappropriately");
	if (nrl->equates_to_iname == NULL) {
		if (nrl->requirements.this_mundane_package == NULL) {
			if (nrl->requirements.this_exotic_package >= 0)
				nrl->requirements.this_mundane_package = Hierarchy::exotic_package(nrl->requirements.this_exotic_package);
			else internal_error("package can't be found'");
		}
		if (nrl->requirements.this_mundane_package == Hierarchy::template()) {
			packaging_state save = Packaging::enter(nrl->requirements.this_mundane_package);
			nrl->equates_to_iname = InterNames::make(nrl->access_name, Hierarchy::template());
			nrl->equates_to_iname->symbol = Emit::extern(nrl->access_name, K_value);
			Packaging::exit(save);
		} else if (Str::len(nrl->function_package_name) > 0) {
			nrl->equates_to_iname = Packaging::function_text(
				InterNames::make(nrl->function_package_name, nrl->requirements.this_mundane_package),
				nrl->requirements.this_mundane_package,
				nrl->access_name);
		} else if (Str::len(nrl->datum_package_name) > 0) {
			nrl->equates_to_iname = Packaging::datum_text(
				InterNames::make(nrl->datum_package_name, nrl->requirements.this_mundane_package),
				nrl->requirements.this_mundane_package,
				nrl->access_name);
		} else if ((nrl->requirements.this_mundane_package) && (nrl->equates_to_iname == NULL)) {
			nrl->equates_to_iname = InterNames::make(nrl->access_name, nrl->requirements.this_mundane_package);
		}

		nrl->equates_to_iname = Hierarchy::post_process(nrl->access_number, nrl->equates_to_iname);
		nrl->requirements.this_mundane_package = Packaging::home_of(nrl->equates_to_iname);
	}
	return nrl->equates_to_iname;
}

inter_name *HierarchyLocations::find_in_package(int id, package_request *P, wording W, compilation_module *C, inter_name *derive_from, int fix, text_stream *imposed_name) {
	if (nrls_created == FALSE) HierarchyLocations::create_nrls();
	if ((id < 0) || (id >= MAX_HL) || (nrls_indexed_by_id[id] == NULL))
		internal_error("bad nrl ID");
	named_resource_location *nrl = nrls_indexed_by_id[id];
	if ((nrl->requirements.any_package_of_this_type == NULL) &&
		(nrl->requirements.any_enclosure == FALSE)) internal_error("NRL accessed inappropriately");
	if (nrl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else if ((P == NULL) || (P->eventual_type != nrl->requirements.any_package_of_this_type)) {
		if (P != Hierarchy::template()) {
			LOG("AN: %S, FPN: %S\n", nrl->access_name, nrl->function_package_name);
			LOG("Have type: $3, required: $3\n", P->eventual_type, nrl->requirements.any_package_of_this_type);
			internal_error("constant in wrong superpackage");
		}
	}
	
	inter_name *iname = NULL;
	if (nrl->trans.translate_to)  {
		text_stream *T = nrl->trans.translate_to;
		@<Make the actual iname@>;
	} else if (nrl->trans.by_imposition) {
		text_stream *T = NULL;	
		@<Make the actual iname@>;
	} else if (nrl->trans.name_generator) {
		TEMPORARY_TEXT(T);
		inter_name *temp_iname = NULL;
		if (derive_from) {
			temp_iname = InterNames::new_derived_f(nrl->trans.name_generator, derive_from);
		} else {
			temp_iname = InterNames::new_f(nrl->trans.name_generator, fix);
		}
		if (!Wordings::empty(W)) {
			InterNames::attach_memo(temp_iname, W);
			W = EMPTY_WORDING;
		}
		WRITE_TO(T, "%n", temp_iname);
		@<Make the actual iname@>;
		DISCARD_TEXT(T);
	} else {
		text_stream *T = NULL;
		@<Make the actual iname@>;
	}
	
	if (nrl->trans.then_make_unique) InterNames::set_flag(iname, MAKE_NAME_UNIQUE);
	return iname;
}

@<Make the actual iname@> =
	if (Str::len(nrl->function_package_name) > 0) {
		iname = Packaging::function_text(
				InterNames::make(nrl->function_package_name, P),
				P,
				NULL);
	} else {
		if (nrl->trans.by_imposition) iname = InterNames::make(imposed_name, P);
		else if (Str::len(nrl->access_name) == 0) iname = InterNames::make(T, P);
		else iname = InterNames::make(nrl->access_name, P);
	}
	if (!Wordings::empty(W)) InterNames::attach_memo(iname, W);
	if ((Str::len(T) > 0) && (nrl->access_name)) InterNames::change_translation(iname, T);

@ =
package_request *HierarchyLocations::package_in_package(int id, package_request *P) {
	if (nrls_created == FALSE) HierarchyLocations::create_nrls();
	if ((id < 0) || (id >= MAX_HL) || (nrls_indexed_by_id[id] == NULL))
		internal_error("bad nrl ID");
	named_resource_location *nrl = nrls_indexed_by_id[id];

	if (P == NULL) internal_error("no superpackage");
	if (nrl->package_type == NULL) internal_error("package_in_package used wrongly");
	if (nrl->requirements.any_package_of_this_type) {
		if (P->eventual_type != nrl->requirements.any_package_of_this_type)
			internal_error("subpackage in wrong superpackage");
	} else if (nrl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else internal_error("NRL accessed inappropriately");

	return Packaging::request(InterNames::make(nrl->access_name, P), P, nrl->package_type);
}

=
typedef struct hierarchy_attachment_point {
	int hap_id;
	int counter;
	struct inter_symbol *type;
	struct location_requirement requirements;
	MEMORY_MANAGEMENT
} hierarchy_attachment_point;

hierarchy_attachment_point *haps_indexed_by_id[MAX_HAP];

int haps_created = FALSE;
void HierarchyLocations::create_haps(void) {
	haps_created = TRUE;
	for (int i=0; i<MAX_HAP; i++) haps_indexed_by_id[i] = NULL;
}

void HierarchyLocations::index_ap(hierarchy_attachment_point *hap) {
	if (haps_created == FALSE) HierarchyLocations::create_haps();
	if (hap->hap_id >= 0) haps_indexed_by_id[hap->hap_id] = hap;
}

hierarchy_attachment_point *HierarchyLocations::ap(int ap_id, location_requirement req, text_stream *iterated_text, text_stream *ptype_name) {
	hierarchy_attachment_point *hap = CREATE(hierarchy_attachment_point);
	hap->hap_id = ap_id;
	hap->requirements = req;
	hap->counter = Packaging::register_counter(iterated_text);
	hap->type = HierarchyLocations::ptype(ptype_name);
	HierarchyLocations::index_ap(hap);
	return hap;
}

package_request *HierarchyLocations::attach_new_package(compilation_module *C, package_request *R, int hap_id) {
	if ((hap_id < 0) || (hap_id >= MAX_HAP) || (haps_created == FALSE) || (haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = haps_indexed_by_id[hap_id];

	if (hap->requirements.this_local_submodule)
		R = Packaging::request_resource(C, hap->requirements.this_local_submodule);
	else if (hap->requirements.this_mundane_package)
		R = hap->requirements.this_mundane_package;
	else if (hap->requirements.this_exotic_package >= 0)
		R = Hierarchy::exotic_package(hap->requirements.this_exotic_package);
	else if (hap->requirements.any_package_of_this_type) {
		if (R != Hierarchy::template())
			if ((R == NULL) || (R->eventual_type != hap->requirements.any_package_of_this_type))
				internal_error("subpackage in wrong superpackage");
	}
	
	return Packaging::request(Packaging::supply_iname(R, hap->counter), R, hap->type);
}

@

=
dictionary *ptypes_indexed_by_name = NULL;

int ptypes_created = FALSE;
inter_symbol *HierarchyLocations::ptype(text_stream *name) {
	if (ptypes_created == FALSE) {
		ptypes_created = TRUE;
		ptypes_indexed_by_name = Dictionaries::new(512, FALSE);
	}
	if (Dictionaries::find(ptypes_indexed_by_name, name))
		return (inter_symbol *) Dictionaries::read_value(ptypes_indexed_by_name, name);
	inter_symbol *new_ptype = Emit::packagetype(name, TRUE);
	Dictionaries::create(ptypes_indexed_by_name, name);
	Dictionaries::write_value(ptypes_indexed_by_name, name, (void *) new_ptype);
	return new_ptype;
}

