[HierarchyLocations::] Hierarchy Locations.

@h Requirements.
Inform's code for compiling resources to different positions in the Inter hierarchy
is quite defensively written, in order to keep everything to a fairly tightly
specified schema.

The following is really a union: a requirement should have exactly one of the
following fields set.

=
typedef struct location_requirement {
	struct submodule_identity *any_submodule_package_of_this_identity;
	struct package_request *this_exact_package;
	int this_exact_package_not_yet_created;
	struct inter_symbol *any_package_of_this_type;
	int any_enclosure;
} location_requirement;

location_requirement HierarchyLocations::blank(void) {
	location_requirement req;
	req.any_submodule_package_of_this_identity = NULL;
	req.this_exact_package = NULL;
	req.this_exact_package_not_yet_created = -1;
	req.any_package_of_this_type = NULL;
	req.any_enclosure = FALSE;
	return req;
}

@ Here are the functions to create requirements:

=
location_requirement HierarchyLocations::local_submodule(submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.any_submodule_package_of_this_identity = sid;
	return req;
}

location_requirement HierarchyLocations::generic_submodule(submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.this_exact_package = Packaging::generic_submodule(sid);
	return req;
}

location_requirement HierarchyLocations::synoptic_submodule(submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.this_exact_package = Packaging::synoptic_submodule(sid);
	return req;
}

location_requirement HierarchyLocations::any_package_of_type(text_stream *ptype_name) {
	location_requirement req = HierarchyLocations::blank();
	req.any_package_of_this_type = PackageTypes::get(ptype_name);
	return req;
}

location_requirement HierarchyLocations::any_enclosure(void) {
	location_requirement req = HierarchyLocations::blank();
	req.any_enclosure = TRUE;
	return req;
}

location_requirement HierarchyLocations::this_package(package_request *P) {
	location_requirement req = HierarchyLocations::blank();
	req.this_exact_package = P;
	return req;
}

location_requirement HierarchyLocations::this_exotic_package(int N) {
	location_requirement req = HierarchyLocations::blank();
	req.this_exact_package_not_yet_created = N;
	return req;
}

@h Hierarchy locations.

=
typedef struct hierarchy_location {
	int access_number;
	struct text_stream *access_name;
	struct text_stream *function_package_name;
	struct text_stream *datum_package_name;
	struct location_requirement requirements;
	struct inter_name *equates_to_iname;
	struct inter_symbol *package_type;
	struct name_translation trans;
	MEMORY_MANAGEMENT
} hierarchy_location;

hierarchy_location *HierarchyLocations::new(void) {
	hierarchy_location *hl = CREATE(hierarchy_location);
	hl->access_number = -1;
	hl->access_name = NULL;
	hl->function_package_name = NULL;
	hl->datum_package_name = NULL;
	hl->equates_to_iname = NULL;
	hl->package_type = NULL;
	hl->trans = Translation::same();
	hl->requirements = HierarchyLocations::blank();
	return hl;
}

hierarchy_location *HierarchyLocations::con(int id, text_stream *name, name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new();
	hl->access_number = id;
	hl->access_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(hl);
	return hl;
}

hierarchy_location *HierarchyLocations::package(int id, text_stream *name, text_stream *ptype_name, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new();
	hl->access_number = id;
	hl->access_name = Str::duplicate(name);
	hl->requirements = req;
	hl->package_type = PackageTypes::get(ptype_name);
	HierarchyLocations::index(hl);
	return hl;
}

hierarchy_location *HierarchyLocations::make_as(int id, text_stream *name, inter_name *iname) {
	hierarchy_location *hl = HierarchyLocations::new();
	hl->access_number = id;
	hl->access_name = Str::duplicate(name);
	hl->requirements = HierarchyLocations::this_package(InterNames::location(iname));
	hl->equates_to_iname = iname;
	HierarchyLocations::index(hl);
	return hl;
}

hierarchy_location *HierarchyLocations::func(int id, text_stream *name, name_translation nt, location_requirement req) {
	hierarchy_location *hl = CREATE(hierarchy_location);
	hl->access_number = id;
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->function_package_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(hl);
	return hl;
}

hierarchy_location *HierarchyLocations::datum(int id, text_stream *name, name_translation nt, location_requirement req) {
	hierarchy_location *hl = CREATE(hierarchy_location);
	hl->access_number = id;
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->datum_package_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(hl);
	return hl;
}

hierarchy_location *hls_indexed_by_id[MAX_HL];
dictionary *hls_indexed_by_name = NULL;

int hls_created = FALSE;
void HierarchyLocations::create_hls(void) {
	hls_created = TRUE;
	for (int i=0; i<MAX_HL; i++) hls_indexed_by_id[i] = NULL;
	hls_indexed_by_name = Dictionaries::new(512, FALSE);
	Hierarchy::establish();
}

void HierarchyLocations::index(hierarchy_location *hl) {
	if (hls_created == FALSE) HierarchyLocations::create_hls();
	if (hl->access_number >= 0) hls_indexed_by_id[hl->access_number] = hl;
	if (hl->requirements.any_package_of_this_type == NULL) {
		Dictionaries::create(hls_indexed_by_name, hl->access_name);
		Dictionaries::write_value(hls_indexed_by_name, hl->access_name, (void *) hl);
	}
}

inter_name *HierarchyLocations::find(int id) {
	if (hls_created == FALSE) HierarchyLocations::create_hls();
	if ((id < 0) || (id >= MAX_HL) || (hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	return HierarchyLocations::hl_to_iname(hls_indexed_by_id[id]);
}

inter_name *HierarchyLocations::find_by_name(text_stream *name) {
	if (Str::len(name) == 0) internal_error("bad hl name");
	if (hls_created == FALSE) HierarchyLocations::create_hls();
	if (Dictionaries::find(hls_indexed_by_name, name))
		return HierarchyLocations::hl_to_iname(
			(hierarchy_location *)
				Dictionaries::read_value(hls_indexed_by_name, name));
	return NULL;
}

inter_name *HierarchyLocations::function(package_request *R, text_stream *name, text_stream *trans) {
	inter_name *iname = Packaging::function(InterNames::explicitly_named(name, R), NULL);
	if (trans) Emit::change_translation(iname, trans);
	return iname;
}

inter_name *HierarchyLocations::hl_to_iname(hierarchy_location *hl) {
	if (hl->requirements.any_package_of_this_type) internal_error("NRL accessed inappropriately");
	if (hl->equates_to_iname == NULL) {
		if (hl->requirements.this_exact_package == NULL) {
			if (hl->requirements.this_exact_package_not_yet_created >= 0)
				hl->requirements.this_exact_package = Hierarchy::exotic_package(hl->requirements.this_exact_package_not_yet_created);
			else internal_error("package can't be found'");
		}
		if (hl->requirements.this_exact_package == Hierarchy::template()) {
			hl->equates_to_iname = InterNames::explicitly_named_in_template(hl->access_name);
		} else if (Str::len(hl->function_package_name) > 0) {
			hl->equates_to_iname = Packaging::function_text(
				InterNames::explicitly_named(hl->function_package_name, hl->requirements.this_exact_package),
				hl->access_name);
		} else if (Str::len(hl->datum_package_name) > 0) {
			hl->equates_to_iname = Packaging::datum_text(
				InterNames::explicitly_named(hl->datum_package_name, hl->requirements.this_exact_package),
				hl->access_name);
		} else if ((hl->requirements.this_exact_package) && (hl->equates_to_iname == NULL)) {
			hl->equates_to_iname = InterNames::explicitly_named(hl->access_name, hl->requirements.this_exact_package);
		}

		hl->equates_to_iname = Hierarchy::post_process(hl->access_number, hl->equates_to_iname);
		hl->requirements.this_exact_package = InterNames::location(hl->equates_to_iname);
	}
	return hl->equates_to_iname;
}

inter_name *HierarchyLocations::find_in_package(int id, package_request *P, wording W, compilation_module *C, inter_name *derive_from, int fix, text_stream *imposed_name) {
	if (hls_created == FALSE) HierarchyLocations::create_hls();
	if ((id < 0) || (id >= MAX_HL) || (hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	hierarchy_location *hl = hls_indexed_by_id[id];
	if ((hl->requirements.any_package_of_this_type == NULL) &&
		(hl->requirements.any_enclosure == FALSE)) internal_error("NRL accessed inappropriately");
	if (hl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else if ((P == NULL) || (P->eventual_type != hl->requirements.any_package_of_this_type)) {
		if (P != Hierarchy::template()) {
			LOG("AN: %S, FPN: %S\n", hl->access_name, hl->function_package_name);
			LOG("Have type: $3, required: $3\n", P->eventual_type, hl->requirements.any_package_of_this_type);
			internal_error("constant in wrong superpackage");
		}
	}
	
	inter_name *iname = NULL;
	if (hl->trans.translate_to)  {
		text_stream *T = hl->trans.translate_to;
		@<Make the actual iname@>;
	} else if (hl->trans.by_imposition) {
		text_stream *T = NULL;	
		@<Make the actual iname@>;
	} else if (hl->trans.name_generator) {
		TEMPORARY_TEXT(T);
		inter_name *temp_iname = NULL;
		if (derive_from) {
			temp_iname = InterNames::derived(hl->trans.name_generator, derive_from, W);
		} else {
			temp_iname = InterNames::generated(hl->trans.name_generator, fix, W);
		}
		W = EMPTY_WORDING;
		WRITE_TO(T, "%n", temp_iname);
		@<Make the actual iname@>;
		DISCARD_TEXT(T);
	} else {
		text_stream *T = NULL;
		@<Make the actual iname@>;
	}
	
	if (hl->trans.then_make_unique) Emit::set_flag(iname, MAKE_NAME_UNIQUE);
	return iname;
}

@<Make the actual iname@> =
	if (Str::len(hl->function_package_name) > 0) {
		iname = Packaging::function(
			InterNames::explicitly_named(hl->function_package_name, P), NULL);
	} else {
		if (hl->trans.by_imposition) iname = InterNames::explicitly_named_with_memo(imposed_name, P, W);
		else if (Str::len(hl->access_name) == 0) iname = InterNames::explicitly_named_with_memo(T, P, W);
		else iname = InterNames::explicitly_named_with_memo(hl->access_name, P, W);
	}
	if ((Str::len(T) > 0) && (hl->access_name)) Emit::change_translation(iname, T);

@ =
package_request *HierarchyLocations::package_in_package(int id, package_request *P) {
	if (hls_created == FALSE) HierarchyLocations::create_hls();
	if ((id < 0) || (id >= MAX_HL) || (hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	hierarchy_location *hl = hls_indexed_by_id[id];

	if (P == NULL) internal_error("no superpackage");
	if (hl->package_type == NULL) internal_error("package_in_package used wrongly");
	if (hl->requirements.any_package_of_this_type) {
		if (P->eventual_type != hl->requirements.any_package_of_this_type)
			internal_error("subpackage in wrong superpackage");
	} else if (hl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else internal_error("NRL accessed inappropriately");

	return Packaging::request(InterNames::explicitly_named(hl->access_name, P), hl->package_type);
}

@h Hierarchy locations.

=
typedef struct hierarchy_attachment_point {
	int hap_id;
	struct text_stream *name_stem;
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

hierarchy_attachment_point *HierarchyLocations::ap(int hap_id, location_requirement req, text_stream *iterated_text, text_stream *ptype_name) {
	hierarchy_attachment_point *hap = CREATE(hierarchy_attachment_point);
	hap->hap_id = hap_id;
	hap->requirements = req;
	hap->name_stem = Str::duplicate(iterated_text);
	hap->type = PackageTypes::get(ptype_name);
	HierarchyLocations::index_ap(hap);
	return hap;
}

package_request *HierarchyLocations::attach_new_package(compilation_module *C, package_request *R, int hap_id) {
	if ((hap_id < 0) || (hap_id >= MAX_HAP) || (haps_created == FALSE) || (haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = haps_indexed_by_id[hap_id];

	if (hap->requirements.any_submodule_package_of_this_identity)
		R = Packaging::request_submodule(C, hap->requirements.any_submodule_package_of_this_identity);
	else if (hap->requirements.this_exact_package)
		R = hap->requirements.this_exact_package;
	else if (hap->requirements.this_exact_package_not_yet_created >= 0)
		R = Hierarchy::exotic_package(hap->requirements.this_exact_package_not_yet_created);
	else if (hap->requirements.any_package_of_this_type) {
		if (R != Hierarchy::template())
			if ((R == NULL) || (R->eventual_type != hap->requirements.any_package_of_this_type))
				internal_error("subpackage in wrong superpackage");
	}
	
	return Packaging::request(Packaging::make_iname_within(R, hap->name_stem), hap->type);
}

