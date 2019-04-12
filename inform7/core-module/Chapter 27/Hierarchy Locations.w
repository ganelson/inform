[HierarchyLocations::] Hierarchy Locations.

@

=
typedef struct named_resource_location {
	int access_number;
	struct text_stream *access_name;
	struct text_stream *function_package_name;
	struct text_stream *datum_package_name;
	struct package_request *package;
	struct inter_name *equates_to_iname;
	MEMORY_MANAGEMENT
} named_resource_location;

named_resource_location *nrls_indexed_by_id[MAX_HL];
dictionary *nrls_indexed_by_name = NULL;

named_resource_location *HierarchyLocations::make_in(int id, text_stream *name, package_request *P) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->function_package_name = NULL;
	nrl->datum_package_name = NULL;
	nrl->package = P;
	nrl->equates_to_iname = NULL;
	if (id >= 0) nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, name);
	Dictionaries::write_value(nrls_indexed_by_name, name, (void *) nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_as(int id, text_stream *name, inter_name *iname) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->function_package_name = NULL;
	nrl->datum_package_name = NULL;
	nrl->package = iname->eventual_owner;
	nrl->equates_to_iname = iname;
	if (id >= 0) nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, name);
	Dictionaries::write_value(nrls_indexed_by_name, name, (void *) nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_on_demand(int id, text_stream *name) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->function_package_name = NULL;
	nrl->datum_package_name = NULL;
	nrl->package = NULL;
	nrl->equates_to_iname = NULL;
	if (id >= 0) nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, name);
	Dictionaries::write_value(nrls_indexed_by_name, name, (void *) nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_function(int id, text_stream *name, text_stream *call_name, package_request *P) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(call_name);
	nrl->function_package_name = Str::duplicate(name);
	nrl->datum_package_name = NULL;
	nrl->package = P;
	nrl->equates_to_iname = NULL;
	if (id >= 0) nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, call_name);
	Dictionaries::write_value(nrls_indexed_by_name, call_name, (void *) nrl);
	return nrl;
}

named_resource_location *HierarchyLocations::make_datum(int id, text_stream *name, text_stream *datum_name, package_request *P) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(datum_name);
	nrl->function_package_name = NULL;
	nrl->datum_package_name = Str::duplicate(name);
	nrl->package = P;
	nrl->equates_to_iname = NULL;
	if (id >= 0) nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, datum_name);
	Dictionaries::write_value(nrls_indexed_by_name, datum_name, (void *) nrl);
	return nrl;
}

int nrls_created = FALSE;
void HierarchyLocations::create_nrls(void) {
	nrls_created = TRUE;
	for (int i=0; i<MAX_HL; i++) nrls_indexed_by_id[i] = NULL;
	nrls_indexed_by_name = Dictionaries::new(512, FALSE);
	Hierarchy::establish();
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
		if (nrl->package == Packaging::request_template()) {
			packaging_state save = Packaging::enter(nrl->package);
			nrl->equates_to_iname = InterNames::one_off(nrl->access_name, Packaging::request_template());
			nrl->equates_to_iname->symbol = Emit::extern(nrl->access_name, K_value);
			Packaging::exit(save);
			return nrl->equates_to_iname;
		}
		if (Str::len(nrl->function_package_name) > 0) {
			nrl->equates_to_iname = Packaging::function_text(
				InterNames::one_off(nrl->function_package_name, nrl->package),
				nrl->package,
				nrl->access_name);
			nrl->package = Packaging::home_of(nrl->equates_to_iname);
		}
		if (Str::len(nrl->datum_package_name) > 0) {
			nrl->equates_to_iname = Packaging::datum_text(
				InterNames::one_off(nrl->datum_package_name, nrl->package),
				nrl->package,
				nrl->access_name);
			nrl->package = Packaging::home_of(nrl->equates_to_iname);
		}
		if ((nrl->package) && (nrl->equates_to_iname == NULL))
			nrl->equates_to_iname = InterNames::one_off(nrl->access_name, nrl->package);
		switch (nrl->access_number) {
			case THESAME_HL:
			case PLURALFOUND_HL:
			case PARENT_HL:
			case CHILD_HL:
			case SIBLING_HL:
			case THEDARK_HL:
			case FLOAT_NAN_HL:
			case RESPONSETEXTS_HL: {
				packaging_state save = Packaging::enter_home_of(nrl->equates_to_iname);
				Emit::named_numeric_constant(nrl->equates_to_iname, 0);
				Packaging::exit(save);
				break;
			}
			case SELF_HL: {
				packaging_state save = Packaging::enter_home_of(nrl->equates_to_iname);
				Emit::variable(nrl->equates_to_iname, K_value, UNDEF_IVAL, 0, I"self");
				Packaging::exit(save);
				break;
			}
			
			case NOTHING_HL:
				nrl->package = Kinds::Behaviour::package(K_object);
				break;
			case OBJECT_HL:
				nrl->equates_to_iname = Kinds::RunTime::I6_classname(K_object);
				break;
			case TESTUSEOPTION_HL:
				nrl->equates_to_iname = HierarchyLocations::function(
					Kinds::RunTime::package(K_use_option), I"test_fn", nrl->access_name);
				break;
			case TABLEOFTABLES_HL:
				nrl->package = Kinds::Behaviour::package(K_table);
				break;
			case TABLEOFVERBS_HL:
				nrl->package = Kinds::Behaviour::package(K_verb);
				break;
			case CAPSHORTNAME_HL:
				nrl->package = Kinds::Behaviour::package(K_object);
				break;
			case RESOURCEIDSOFFIGURES_HL:
				nrl->package = Kinds::Behaviour::package(K_figure_name);
				break;
			case RESOURCEIDSOFSOUNDS_HL:
				nrl->package = Kinds::Behaviour::package(K_sound_name);
				break;
			case NO_USE_OPTIONS_HL:
				nrl->package = Kinds::Behaviour::package(K_use_option);
				break;
			case DECIMAL_TOKEN_INNER_HL:
				nrl->equates_to_iname = HierarchyLocations::function(
					Kinds::RunTime::package(K_number), I"gpr_fn", nrl->access_name);
				break;
			case TIME_TOKEN_INNER_HL:
				nrl->equates_to_iname = HierarchyLocations::function(
					Kinds::RunTime::package(K_time), I"gpr_fn", nrl->access_name);
				break;
			case TRUTH_STATE_TOKEN_INNER_HL:
				nrl->equates_to_iname = HierarchyLocations::function(
					Kinds::RunTime::package(K_truth_state), I"gpr_fn", nrl->access_name);
				break;
			case COMMANDPROMPTTEXT_HL:
				nrl->equates_to_iname = HierarchyLocations::function(
					Packaging::home_of(NonlocalVariables::iname(command_prompt_VAR)),
					I"command_prompt_text_fn", nrl->access_name);				
				break;
		}
		if (nrl->equates_to_iname == NULL)
			nrl->equates_to_iname = InterNames::one_off(nrl->access_name, nrl->package);
		if (nrl->package == NULL)
			nrl->package = Packaging::home_of(nrl->equates_to_iname);
	}
	return nrl->equates_to_iname;
}
