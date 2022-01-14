[HierarchyLocations::] Hierarchy Locations.

@h Hierarchy locations.
A //hierarchy_location// is an abstract way to refer to a resource in an
Inter tree; note that it can describe a position which does not yet exist,
or indeed a resource which will never be created.

Each different HL has a unique ID, its |access_number|. The idea is that a
compiler such as //inform7// can look up, say, the ID |JINXED_WIZARDS_HL|,
and quickly determine that this resource should -- if and when created --
be called |JinxedWizards_fn|, and be in the package |/synoptic/kinds|,
and so forth. This is obviously useful when creating resources -- it's a
set of instructions, in effect, for what to call them and where to put them.

But it is also useful when cross-referencing those: for example, when
compiling a function call to |JinxedWizards_fn|. It enables such a call to
be compiled even when the function itself has not yet been created.

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

hierarchy_location *HierarchyLocations::new(int id) {
	hierarchy_location *hl = CREATE(hierarchy_location);
	hl->access_number = id;
	hl->access_name = NULL;
	hl->function_package_name = NULL;
	hl->datum_package_name = NULL;
	hl->equates_to_iname = NULL;
	hl->package_type = NULL;
	hl->trans = Translation::same();
	hl->requirements = LocationRequirements::blank();
	return hl;
}

@ We provide an API of five creator functions for HLs. First, for a resource
like a constant[1] (possibly translated in some way: see //Translation//), and
which must be located at position |req|.

[1] Or a variable, or really anything self-contained under a single simple name
which is not a package of some kind.

=
hierarchy_location *HierarchyLocations::ctr(inter_tree *I, int id, text_stream *name,
	name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id);
	hl->access_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

@ Second, the same thing but with no translation needed:

=
hierarchy_location *HierarchyLocations::con(inter_tree *I, int id, text_stream *name,
	location_requirement req) {
	return HierarchyLocations::ctr(I, id, name, Translation::same(), req);
}

@ Third, for a function, possibly translated in some way, again at |req|:

=
hierarchy_location *HierarchyLocations::fun(inter_tree *I, int id, text_stream *name,
	name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id);
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->function_package_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

@ Fourth, for a package of a given type, which must live at |req|:

=
hierarchy_location *HierarchyLocations::pkg(inter_tree *I, int id, text_stream *name,
	text_stream *ptype_name, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id);
	hl->access_name = Str::duplicate(name);
	hl->requirements = req;
	hl->package_type = Str::duplicate(ptype_name);
	HierarchyLocations::index(I, hl);
	return hl;
}

@ Finally, for a datum package:

=
hierarchy_location *HierarchyLocations::dat(inter_tree *I, int id, text_stream *name,
	name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id);
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->datum_package_name = Str::duplicate(name);
	hl->requirements = req;
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

@h Dealing with HLs.

=
void HierarchyLocations::index(inter_tree *I, hierarchy_location *hl) {
	if (hl->access_number >= 0) I->site.spdata.hls_indexed_by_id[hl->access_number] = hl;
	if (hl->requirements.any_package_of_this_type == NULL) {
		Dictionaries::create(I->site.spdata.hls_indexed_by_name, hl->access_name);
		Dictionaries::write_value(I->site.spdata.hls_indexed_by_name, hl->access_name, (void *) hl);
	}
}

inter_name *HierarchyLocations::find(inter_tree *I, int id) {
	if ((id < 0) || (id >= NO_DEFINED_HL_VALUES) || (I->site.spdata.hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	return HierarchyLocations::hl_to_iname(I, I->site.spdata.hls_indexed_by_id[id]);
}

inter_name *HierarchyLocations::find_by_name(inter_tree *I, text_stream *name) {
	if (Str::len(name) == 0) internal_error("bad hl name");
	if (Dictionaries::find(I->site.spdata.hls_indexed_by_name, name))
		return HierarchyLocations::hl_to_iname(I, 
			(hierarchy_location *)
				Dictionaries::read_value(I->site.spdata.hls_indexed_by_name, name));
	return NULL;
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
	if ((id < 0) || (id >= NO_DEFINED_HL_VALUES) || (I->site.spdata.hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	hierarchy_location *hl = I->site.spdata.hls_indexed_by_id[id];
	if ((hl->requirements.any_package_of_this_type == NULL) &&
		(hl->requirements.any_enclosure == FALSE)) internal_error("NRL accessed inappropriately");
	if (hl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else if (P == NULL) {
		internal_error("constant in null package");
	} else if (P->eventual_type != LargeScale::package_type(I, hl->requirements.any_package_of_this_type)) {
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
	if ((id < 0) || (id >= NO_DEFINED_HL_VALUES) || (I->site.spdata.hls_indexed_by_id[id] == NULL))
		internal_error("bad hl ID");
	hierarchy_location *hl = I->site.spdata.hls_indexed_by_id[id];

	if (P == NULL) internal_error("no superpackage");
	if (hl->package_type == NULL) internal_error("package_in_package used wrongly");
	if (hl->requirements.any_package_of_this_type) {
		if (P->eventual_type != LargeScale::package_type(I, hl->requirements.any_package_of_this_type))
			internal_error("subpackage in wrong superpackage");
	} else if (hl->requirements.any_enclosure) {
		if (Inter::Symbols::read_annotation(P->eventual_type, ENCLOSING_IANN) != 1)
			internal_error("subpackage not in enclosing superpackage");
	} else internal_error("NRL accessed inappropriately");

	return Packaging::request(I, InterNames::explicitly_named(hl->access_name, P), LargeScale::package_type(I, hl->package_type));
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
	if (hap->hap_id >= 0) I->site.spdata.haps_indexed_by_id[hap->hap_id] = hap;
}

hierarchy_attachment_point *HierarchyLocations::att(inter_tree *I, int hap_id, text_stream *iterated_text, text_stream *ptype_name, location_requirement req) {
	hierarchy_attachment_point *hap = CREATE(hierarchy_attachment_point);
	hap->hap_id = hap_id;
	hap->requirements = req;
	hap->name_stem = Str::duplicate(iterated_text);
	hap->type = Str::duplicate(ptype_name);
	HierarchyLocations::index_ap(I, hap);
	return hap;
}

#ifdef CORE_MODULE
package_request *HierarchyLocations::attach_new_package(inter_tree *I, compilation_unit *C, package_request *R, int hap_id) {
	if ((hap_id < 0) || (hap_id >= NO_DEFINED_HAP_VALUES) || (I->site.spdata.haps_indexed_by_id[hap_id] == NULL))
		internal_error("invalid HAP request");
	hierarchy_attachment_point *hap = I->site.spdata.haps_indexed_by_id[hap_id];
	if (hap->requirements.must_be_main_source_text) {
		R = hap->requirements.this_exact_package;
	} else if (hap->requirements.any_submodule_package_of_this_identity) {
		if (C == NULL) R = LargeScale::generic_submodule(I, hap->requirements.any_submodule_package_of_this_identity);
		else R = LargeScale::request_submodule_of(I, CompilationUnits::to_module_package(C), hap->requirements.any_submodule_package_of_this_identity);
	} else if (hap->requirements.this_exact_package) {
		R = hap->requirements.this_exact_package;
	} else if (hap->requirements.this_exact_package_not_yet_created >= 0) {
		R = Hierarchy::exotic_package(hap->requirements.this_exact_package_not_yet_created);
	} else if (hap->requirements.any_package_of_this_type) {
		if ((R == NULL) || (R->eventual_type != LargeScale::package_type(I, hap->requirements.any_package_of_this_type)))
			internal_error("subpackage in wrong superpackage");
	}
	
	return Packaging::request(I, Packaging::make_iname_within(R, hap->name_stem), LargeScale::package_type(I, hap->type));
}
#endif
