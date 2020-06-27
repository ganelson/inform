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
	struct text_stream *any_package_of_this_type;
	int any_enclosure;
	int must_be_plug;
} location_requirement;

location_requirement HierarchyLocations::blank(void) {
	location_requirement req;
	req.any_submodule_package_of_this_identity = NULL;
	req.this_exact_package = NULL;
	req.this_exact_package_not_yet_created = -1;
	req.any_package_of_this_type = NULL;
	req.any_enclosure = FALSE;
	req.must_be_plug = FALSE;
	return req;
}

@ Here are the functions to create requirements:

=
location_requirement HierarchyLocations::local_submodule(submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.any_submodule_package_of_this_identity = sid;
	return req;
}

location_requirement HierarchyLocations::generic_submodule(inter_tree *I, submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.this_exact_package = Packaging::generic_submodule(I, sid);
	return req;
}

location_requirement HierarchyLocations::synoptic_submodule(inter_tree *I, submodule_identity *sid) {
	location_requirement req = HierarchyLocations::blank();
	req.this_exact_package = Packaging::synoptic_submodule(I, sid);
	return req;
}

location_requirement HierarchyLocations::any_package_of_type(text_stream *ptype_name) {
	location_requirement req = HierarchyLocations::blank();
	req.any_package_of_this_type = Str::duplicate(ptype_name);
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

location_requirement HierarchyLocations::plug(void) {
	location_requirement req = HierarchyLocations::blank();
	req.must_be_plug = TRUE;
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
	struct text_stream *package_type;
	struct name_translation trans;
	CLASS_DEFINITION
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

hierarchy_location *HierarchyLocations::con(inter_tree *I, int id, text_stream *name, name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new();
	hl->access_number = id;
	hl->access_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

hierarchy_location *HierarchyLocations::package(inter_tree *I, int id, text_stream *name, text_stream *ptype_name, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new();
	hl->access_number = id;
	hl->access_name = Str::duplicate(name);
	hl->requirements = req;
	hl->package_type = Str::duplicate(ptype_name);
	HierarchyLocations::index(I, hl);
	return hl;
}

hierarchy_location *HierarchyLocations::make_as(inter_tree *I, int id, text_stream *name, inter_name *iname) {
	hierarchy_location *hl = HierarchyLocations::new();
	hl->access_number = id;
	hl->access_name = Str::duplicate(name);
	hl->requirements = HierarchyLocations::this_package(InterNames::location(iname));
	hl->equates_to_iname = iname;
	HierarchyLocations::index(I, hl);
	return hl;
}

hierarchy_location *HierarchyLocations::func(inter_tree *I, int id, text_stream *name, name_translation nt, location_requirement req) {
	hierarchy_location *hl = CREATE(hierarchy_location);
	hl->access_number = id;
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->function_package_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

hierarchy_location *HierarchyLocations::datum(inter_tree *I, int id, text_stream *name, name_translation nt, location_requirement req) {
	hierarchy_location *hl = CREATE(hierarchy_location);
	hl->access_number = id;
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->datum_package_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

void HierarchyLocations::index(inter_tree *I, hierarchy_location *hl) {
	if (hl->access_number >= 0) I->site.hls_indexed_by_id[hl->access_number] = hl;
	if (hl->requirements.any_package_of_this_type == NULL) {
		Dictionaries::create(I->site.hls_indexed_by_name, hl->access_name);
		Dictionaries::write_value(I->site.hls_indexed_by_name, hl->access_name, (void *) hl);
	}
}

inter_name *HierarchyLocations::find(inter_tree *I, int id) {
	if ((id < 0) || (id >= NO_DEFINED_HL_VALUES) || (I->site.hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	return HierarchyLocations::hl_to_iname(I, I->site.hls_indexed_by_id[id]);
}

inter_name *HierarchyLocations::find_by_name(inter_tree *I, text_stream *name) {
	if (Str::len(name) == 0) internal_error("bad hl name");
	if (Dictionaries::find(I->site.hls_indexed_by_name, name))
		return HierarchyLocations::hl_to_iname(I, 
			(hierarchy_location *)
				Dictionaries::read_value(I->site.hls_indexed_by_name, name));
	return NULL;
}

inter_name *HierarchyLocations::function(inter_tree *I, package_request *R, text_stream *name, text_stream *trans) {
	inter_name *iname = Packaging::function(I, InterNames::explicitly_named(name, R), NULL);
	if (trans) Produce::change_translation(iname, trans);
	return iname;
}

inter_name *HierarchyLocations::hl_to_iname(inter_tree *I, hierarchy_location *hl) {
	if (hl->requirements.any_package_of_this_type) internal_error("NRL accessed inappropriately");
	if (hl->equates_to_iname == NULL) {
		if (hl->requirements.must_be_plug) {
			hl->equates_to_iname = InterNames::explicitly_named_in_template(I, hl->access_name);
		} else {
			if (hl->requirements.this_exact_package == NULL) {
				if (hl->requirements.this_exact_package_not_yet_created >= 0) {
					#ifdef CORE_MODULE
					hl->requirements.this_exact_package = Hierarchy::exotic_package(hl->requirements.this_exact_package_not_yet_created);
					#endif
					#ifndef CORE_MODULE
					internal_error("feature not available in inter");
					#endif
				} else internal_error("package can't be found");
			}
			if (Str::len(hl->function_package_name) > 0) {
				hl->equates_to_iname = Packaging::function_text(I,
					InterNames::explicitly_named(hl->function_package_name, hl->requirements.this_exact_package),
					hl->access_name);
			} else if (Str::len(hl->datum_package_name) > 0) {
				hl->equates_to_iname = Packaging::datum_text(I,
					InterNames::explicitly_named(hl->datum_package_name, hl->requirements.this_exact_package),
					hl->access_name);
			} else if ((hl->requirements.this_exact_package) && (hl->equates_to_iname == NULL)) {
				hl->equates_to_iname = InterNames::explicitly_named(hl->access_name, hl->requirements.this_exact_package);
			}
		}
		hl->requirements.this_exact_package = InterNames::location(hl->equates_to_iname);
		
		if (hl->trans.translate_to) Produce::change_translation(hl->equates_to_iname, hl->trans.translate_to);
	}
	return hl->equates_to_iname;
}

inter_name *HierarchyLocations::find_in_package(inter_tree *I, int id, package_request *P, wording W, inter_name *derive_from, int fix, text_stream *imposed_name) {
	if ((id < 0) || (id >= NO_DEFINED_HL_VALUES) || (I->site.hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	hierarchy_location *hl = I->site.hls_indexed_by_id[id];
	if ((hl->requirements.any_package_of_this_type == NULL) &&
		(hl->requirements.any_enclosure == FALSE)) internal_error("NRL accessed inappropriately");
	if (hl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else if ((P == NULL) || (P->eventual_type != PackageTypes::get(I, hl->requirements.any_package_of_this_type))) {
		LOG("AN: %S, FPN: %S\n", hl->access_name, hl->function_package_name);
		LOG("Have type: $3, required: %S\n", P->eventual_type, hl->requirements.any_package_of_this_type);
		internal_error("constant in wrong superpackage");
	}
	
	inter_name *iname = NULL;
	if (hl->trans.translate_to)  {
		text_stream *T = hl->trans.translate_to;
		@<Make the actual iname@>;
	} else if (hl->trans.by_imposition) {
		text_stream *T = NULL;	
		@<Make the actual iname@>;
	} else if (hl->trans.name_generator) {
		TEMPORARY_TEXT(T)
		inter_name *temp_iname = NULL;
		if (derive_from) {
			temp_iname = InterNames::derived(hl->trans.name_generator, derive_from, W);
		} else {
			temp_iname = InterNames::generated(hl->trans.name_generator, fix, W);
		}
		W = EMPTY_WORDING;
		WRITE_TO(T, "%n", temp_iname);
		@<Make the actual iname@>;
		DISCARD_TEXT(T)
	} else {
		text_stream *T = NULL;
		@<Make the actual iname@>;
	}
	
	if (hl->trans.then_make_unique) Produce::set_flag(iname, MAKE_NAME_UNIQUE);
	return iname;
}

@<Make the actual iname@> =
	if (Str::len(hl->function_package_name) > 0) {
		iname = Packaging::function(I,
			InterNames::explicitly_named(hl->function_package_name, P), NULL);
	} else {
		if (hl->trans.by_imposition) iname = InterNames::explicitly_named_with_memo(imposed_name, P, W);
		else if (Str::len(hl->access_name) == 0) iname = InterNames::explicitly_named_with_memo(T, P, W);
		else iname = InterNames::explicitly_named_with_memo(hl->access_name, P, W);
	}
	if ((Str::len(T) > 0) && (hl->access_name)) Produce::change_translation(iname, T);

@ =
package_request *HierarchyLocations::package_in_package(inter_tree *I, int id, package_request *P) {
	if ((id < 0) || (id >= NO_DEFINED_HL_VALUES) || (I->site.hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	hierarchy_location *hl = I->site.hls_indexed_by_id[id];

	if (P == NULL) internal_error("no superpackage");
	if (hl->package_type == NULL) internal_error("package_in_package used wrongly");
	if (hl->requirements.any_package_of_this_type) {
		if (P->eventual_type != PackageTypes::get(I, hl->requirements.any_package_of_this_type))
			internal_error("subpackage in wrong superpackage");
	} else if (hl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else internal_error("NRL accessed inappropriately");

	return Packaging::request(I, InterNames::explicitly_named(hl->access_name, P), PackageTypes::get(I, hl->package_type));
}

@h Hierarchy locations.

=
typedef struct hierarchy_attachment_point {
	int hap_id;
	struct text_stream *name_stem;
	struct text_stream *type;
	struct location_requirement requirements;
	CLASS_DEFINITION
} hierarchy_attachment_point;

void HierarchyLocations::index_ap(inter_tree *I, hierarchy_attachment_point *hap) {
	if (hap->hap_id >= 0) I->site.haps_indexed_by_id[hap->hap_id] = hap;
}

hierarchy_attachment_point *HierarchyLocations::ap(inter_tree *I, int hap_id, location_requirement req, text_stream *iterated_text, text_stream *ptype_name) {
	hierarchy_attachment_point *hap = CREATE(hierarchy_attachment_point);
	hap->hap_id = hap_id;
	hap->requirements = req;
	hap->name_stem = Str::duplicate(iterated_text);
	hap->type = Str::duplicate(ptype_name);
	HierarchyLocations::index_ap(I, hap);
	return hap;
}

package_request *HierarchyLocations::attach_new_package(inter_tree *I, compilation_module *C, package_request *R, int hap_id) {
	if ((hap_id < 0) || (hap_id >= NO_DEFINED_HAP_VALUES) || (I->site.haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = I->site.haps_indexed_by_id[hap_id];

	if (hap->requirements.any_submodule_package_of_this_identity) {
		#ifdef CORE_MODULE
		R = Packaging::request_submodule(I, C, hap->requirements.any_submodule_package_of_this_identity);
		#endif
		#ifndef CORE_MODULE
		internal_error("feature available only within inform7 compiler");
		#endif
	} else if (hap->requirements.this_exact_package)
		R = hap->requirements.this_exact_package;
	else if (hap->requirements.this_exact_package_not_yet_created >= 0) {
		#ifdef CORE_MODULE
		R = Hierarchy::exotic_package(hap->requirements.this_exact_package_not_yet_created);
		#endif
		#ifndef CORE_MODULE
		internal_error("feature available only within inform7 compiler");
		#endif
	} else if (hap->requirements.any_package_of_this_type) {
		if ((R == NULL) || (R->eventual_type != PackageTypes::get(I, hap->requirements.any_package_of_this_type)))
			internal_error("subpackage in wrong superpackage");
	}
	
	return Packaging::request(I, Packaging::make_iname_within(R, hap->name_stem), PackageTypes::get(I, hap->type));
}

@h Hierarchy metadata.

=
typedef struct hierarchy_metadatum {
	int hm_id;
	struct text_stream *key;
	struct location_requirement requirements;
	CLASS_DEFINITION
} hierarchy_metadatum;

void HierarchyLocations::index_md(inter_tree *I, hierarchy_metadatum *hmd) {
	if (hmd->hm_id >= 0) I->site.hmds_indexed_by_id[hmd->hm_id] = hmd;
}

hierarchy_metadatum *HierarchyLocations::metadata(inter_tree *I, int hm_id, location_requirement req, text_stream *key) {
	hierarchy_metadatum *hmd = CREATE(hierarchy_metadatum);
	hmd->hm_id = hm_id;
	hmd->requirements = req;
	hmd->key = Str::duplicate(key);
	HierarchyLocations::index_md(I, hmd);
	return hmd;
}

void HierarchyLocations::markup(inter_tree *I, package_request *R, int hm_id, text_stream *value) {
	if ((hm_id < 0) || (hm_id >= NO_DEFINED_HMD_VALUES) || (I->site.hmds_indexed_by_id[hm_id] == NULL))
		internal_error("invalid HMD request");
	hierarchy_metadatum *hmd = I->site.hmds_indexed_by_id[hm_id];

	int wrong = FALSE;
	if (hmd->requirements.any_submodule_package_of_this_identity) {
		wrong = TRUE;
	} else if (hmd->requirements.this_exact_package) {
		if (R != hmd->requirements.this_exact_package)
			wrong = TRUE;
	} else if (hmd->requirements.this_exact_package_not_yet_created >= 0) {
		#ifdef CORE_MODULE
		if (R != Hierarchy::exotic_package(hmd->requirements.this_exact_package_not_yet_created))
			wrong = TRUE;
		#endif
		#ifndef CORE_MODULE
		internal_error("feature available only within inform7 compiler");
		#endif
	} else if (hmd->requirements.any_package_of_this_type) {
		if ((R == NULL) || (R->eventual_type != PackageTypes::get(I, hmd->requirements.any_package_of_this_type)))
			wrong = TRUE;
	}
	if (wrong) internal_error("misapplied metadata");
	
	Produce::metadata(I, R, hmd->key, value);
}
