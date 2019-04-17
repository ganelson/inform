[Packaging::] Packaging.

@h Package types.

= (early code)
inter_symbol *plain_ptype = NULL;
inter_symbol *code_ptype = NULL;
inter_symbol *module_ptype = NULL;
inter_symbol *function_ptype = NULL;
inter_symbol *data_ptype = NULL;

@ =
void Packaging::emit_types(void) {
	plain_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_plain");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), plain_ptype, Emit::baseline(Emit::IRS()), NULL));

	code_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_code");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), code_ptype, Emit::baseline(Emit::IRS()), NULL));

	module_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_module");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), module_ptype, Emit::baseline(Emit::IRS()), NULL));

	function_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_function");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), function_ptype, Emit::baseline(Emit::IRS()), NULL));
	Emit::annotate_symbol_i(function_ptype, ENCLOSING_IANN, 1);

	data_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_data");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), data_ptype, Emit::baseline(Emit::IRS()), NULL));
	Emit::annotate_symbol_i(data_ptype, ENCLOSING_IANN, 1);
}

@

@d MAX_PRCS_AT_ONCE 11

=
typedef struct package_request {
	struct inter_name *eventual_name;
	struct inter_symbol *eventual_type;
	struct inter_package *actual_package;
	struct package_request *parent_request;
	struct inter_reading_state write_position;
	struct linked_list *counters; /* of |submodule_request_counter| */
	MEMORY_MANAGEMENT
} package_request;
typedef struct submodule_request_counter {
	int counter_id;
	int counter_value;
	MEMORY_MANAGEMENT
} submodule_request_counter;

@ =
package_request *Packaging::request(inter_name *name, package_request *parent, inter_symbol *pt) {
	package_request *R = CREATE(package_request);
	R->eventual_name = name;
	if (parent) name->eventual_owner = parent;
	R->eventual_type = pt;
	R->actual_package = NULL;
	R->parent_request = parent;
	R->write_position = Inter::Bookmarks::new_IRS(Emit::repository());
	R->counters = NULL;
	return R;
}

void Packaging::log(package_request *R) {
	if (R == NULL) LOG("<null-package>");
	else {
		int c = 0;
		while (R) {
			if (c++ > 0) LOG("\\");
			if (R->actual_package) LOG("%S(%d)", R->actual_package->package_name->symbol_name, R->allocation_id);
			else LOG("--(%d)", R->allocation_id);
			R = R->parent_request;
		}
	}
}

@ =
package_request *current_enclosure = NULL;

typedef struct packaging_state {
	inter_reading_state *saved_IRS;
	package_request *saved_enclosure;
} packaging_state;

packaging_state Packaging::stateless(void) {
	packaging_state PS;
	PS.saved_IRS = NULL;
	PS.saved_enclosure = NULL;
	return PS;
}

package_request *Packaging::home_of(inter_name *N) {
	return N->eventual_owner;
}

packaging_state Packaging::enter_home_of(inter_name *N) {
	return Packaging::enter(N->eventual_owner);
}

packaging_state Packaging::enter_current_enclosure(void) {
	return Packaging::enter(current_enclosure);
}

package_request *Packaging::current_enclosure(void) {
	return current_enclosure;
}

@

@d MAX_PACKAGING_ENTRY_DEPTH 32

=
int packaging_entry_sp = 0;
inter_reading_state packaging_entry_stack[MAX_PACKAGING_ENTRY_DEPTH];

packaging_state Packaging::enter(package_request *R) {
	LOGIF(PACKAGING, "Entering $X\n", R);

	inter_reading_state *IRS = Emit::IRS();
	Packaging::incarnate(R);
	Emit::move_write_position(&(R->write_position));
	if (packaging_entry_sp >= MAX_PACKAGING_ENTRY_DEPTH) internal_error("packaging entry too deep");
	packaging_entry_stack[packaging_entry_sp] = Emit::bookmark_bubble();
	Emit::move_write_position(&packaging_entry_stack[packaging_entry_sp]);
	packaging_entry_sp++;
	packaging_state PS;
	PS.saved_IRS = IRS;
	PS.saved_enclosure = current_enclosure;
	for (package_request *S = R; S; S = S->parent_request)
		if ((Inter::Symbols::read_annotation(S->eventual_type, ENCLOSING_IANN) == 1) ||
			(S->parent_request == NULL)) {
			current_enclosure = S;
			break;
		}
	LOGIF(PACKAGING, "[%d] Current enclosure is $X\n", packaging_entry_sp, current_enclosure);
	return PS;
}

void Packaging::exit(packaging_state PS) {
	current_enclosure = PS.saved_enclosure;
	packaging_entry_sp--;
	LOGIF(PACKAGING, "[%d] Back to $X\n", packaging_entry_sp, current_enclosure);
	Emit::move_write_position(PS.saved_IRS);
}

inter_package *Packaging::incarnate(package_request *R) {
	if (R == NULL) internal_error("can't incarnate null request");
	if (R->actual_package == NULL) {
		LOGIF(PACKAGING, "Request to make incarnate $X\n", R);
		if (R->parent_request) Packaging::incarnate(R->parent_request);

		inter_reading_state *save_IRS = NULL;
		if (R->parent_request)
			save_IRS = Emit::move_write_position(&(R->parent_request->write_position));
		inter_reading_state snapshot = Emit::bookmark_bubble();
		inter_reading_state *save_save_IRS = Emit::move_write_position(&snapshot);
		Emit::package(R->eventual_name, R->eventual_type, &(R->actual_package));
		R->write_position = Emit::bookmark_bubble();
		Emit::move_write_position(save_save_IRS);
		if (R->parent_request)
			Emit::move_write_position(save_IRS);
		LOGIF(PACKAGING, "Made incarnate $X bookmark $5\n", R, &(R->write_position));
	}
	return R->actual_package;
}

inter_symbols_table *Packaging::scope(inter_repository *I, inter_name *N) {
	if (N == NULL) internal_error("can't determine scope of null name");
	if (N->eventual_owner == NULL) return Inter::get_global_symbols(Emit::repository());
	return Inter::Packages::scope(Packaging::incarnate(N->eventual_owner));
}

@ =
package_request *generic_pr = NULL;
package_request *Packaging::request_generic(void) {
	if (generic_pr == NULL)
		generic_pr = Packaging::request(
			InterNames::one_off(I"generic", Hierarchy::resources()),
			Hierarchy::resources(), module_ptype);
	return generic_pr;
}

package_request *synoptic_pr = NULL;
package_request *Packaging::request_synoptic(void) {
	if (synoptic_pr == NULL)
		synoptic_pr = Packaging::request(
			InterNames::one_off(I"synoptic", Hierarchy::resources()),
			Hierarchy::resources(), module_ptype);
	return synoptic_pr;
}

typedef struct submodule_identity {
	struct text_stream *submodule_name;
	MEMORY_MANAGEMENT
} submodule_identity;

submodule_identity *Packaging::register_submodule(text_stream *name) {
	submodule_identity *sid = CREATE(submodule_identity);
	sid->submodule_name = Str::duplicate(name);
	return sid;
}


typedef struct submodule_request {
	struct submodule_identity *which_submodule;
	struct package_request *where_found;
	MEMORY_MANAGEMENT
} submodule_request;

typedef struct submodule_requests {
	struct linked_list *submodules; /* of |submodule_identity| */
} submodule_requests;

package_request *Packaging::resources_for_new_submodule(text_stream *name, submodule_requests *SR) {
	inter_name *package_iname = InterNames::one_off(name, Hierarchy::resources());
	package_request *P = Packaging::request(package_iname, Hierarchy::resources(), module_ptype);
	Packaging::initialise_submodules(SR);
	return P;
}

void Packaging::initialise_submodules(submodule_requests *SR) {
	SR->submodules = NEW_LINKED_LIST(submodule_request);
}

int generic_subpackages_initialised = FALSE;
submodule_requests generic_subpackages;
int synoptic_subpackages_initialised = FALSE;
submodule_requests synoptic_subpackages;

package_request *Packaging::request_resource(compilation_module *C, submodule_identity *sid) {
	submodule_requests *SR = NULL;
	package_request *parent = NULL;
	if (C) {
		SR = Modules::subpackages(C);
		parent = C->resources;
	} else {
		if (generic_subpackages_initialised == FALSE) {
			generic_subpackages_initialised = TRUE;
			Packaging::initialise_submodules(&generic_subpackages);
		}
		SR = &generic_subpackages;
		parent = Packaging::request_generic();
	}
	@<Handle the resource request@>;
}

package_request *Packaging::local_resource(submodule_identity *sid) {
	return Packaging::request_resource(Modules::find(current_sentence), sid);
}

package_request *Packaging::generic_resource(submodule_identity *sid) {
	if (generic_subpackages_initialised == FALSE) {
		generic_subpackages_initialised = TRUE;
		Packaging::initialise_submodules(&generic_subpackages);
	}
	submodule_requests *SR = &generic_subpackages;
	package_request *parent = Packaging::request_generic();
	@<Handle the resource request@>;
}

package_request *Packaging::synoptic_resource(submodule_identity *sid) {
	if (synoptic_subpackages_initialised == FALSE) {
		synoptic_subpackages_initialised = TRUE;
		Packaging::initialise_submodules(&synoptic_subpackages);
	}
	submodule_requests *SR = &synoptic_subpackages;
	package_request *parent = Packaging::request_synoptic();
	@<Handle the resource request@>;
}

@<Handle the resource request@> =
	submodule_request *sr;
	LOOP_OVER_LINKED_LIST(sr, submodule_request, SR->submodules)
		if (sid == sr->which_submodule)
			return sr->where_found;
	inter_name *iname = InterNames::one_off(sid->submodule_name, parent);
	sr = CREATE(submodule_request);
	sr->which_submodule = sid;
	sr->where_found = Packaging::request(iname, parent, plain_ptype);
	ADD_TO_LINKED_LIST(sr, submodule_request, SR->submodules);
	return sr->where_found;

@ 

@d MAX_PRCS 500

=
int no_pr_counters_registered = 0;
text_stream *pr_counter_names[MAX_PRCS];
int Packaging::register_counter(text_stream *name) {
	int id = no_pr_counters_registered++;
	if ((id < 0) || (id >= MAX_PRCS)) internal_error("out of range");
	pr_counter_names[id] = Str::duplicate(name);
	return id;
}

inter_name *Packaging::supply_iname(package_request *R, int what_for) {
	if (R == NULL) internal_error("no request");
	if ((what_for < 0) || (what_for >= no_pr_counters_registered)) internal_error("out of range");
	if (R->counters == NULL)
		R->counters = NEW_LINKED_LIST(submodule_request_counter);
	int N = -1;
	submodule_request_counter *src;
	LOOP_OVER_LINKED_LIST(src, submodule_request_counter, R->counters)
		if (src->counter_id == what_for) {
			N = ++(src->counter_value); break;
		}
	if (N < 0) {
		submodule_request_counter *src = CREATE(submodule_request_counter);
		src->counter_id = what_for;
		src->counter_value = 1;
		N = 1;
		ADD_TO_LINKED_LIST(src, submodule_request_counter, R->counters);
	}
	TEMPORARY_TEXT(P);
	WRITE_TO(P, "%S_%d", pr_counter_names[what_for], N);
	inter_name *iname = InterNames::one_off(P, R);
	DISCARD_TEXT(P);
	return iname;
}

inter_name *Packaging::function(inter_name *function_iname, package_request *R2, inter_name *temp_iname) {
	package_request *R3 = Packaging::request(function_iname, R2, function_ptype);
	inter_name *iname = InterNames::one_off(I"call", R3);
	Packaging::house(iname, R3);
	if (temp_iname) {
		TEMPORARY_TEXT(T);
		WRITE_TO(T, "%n", temp_iname);
		InterNames::change_translation(iname, T);
		DISCARD_TEXT(T);
	}
	return iname;
}

inter_name *Packaging::function_text(inter_name *function_iname, package_request *R2, text_stream *translation) {
	package_request *R3 = Packaging::request(function_iname, R2, function_ptype);
	inter_name *iname = InterNames::one_off(I"call", R3);
	Packaging::house(iname, R3);
	if (translation)
		InterNames::change_translation(iname, translation);
	return iname;
}

inter_name *Packaging::datum_text(inter_name *function_iname, package_request *R2, text_stream *translation) {
	package_request *R3 = Packaging::request(function_iname, R2, data_ptype);
	inter_name *iname = InterNames::one_off(translation, R3);
	Packaging::house(iname, R3);
	return iname;
}

void Packaging::house(inter_name *iname, package_request *at) {
	if (iname == NULL) internal_error("can't house null name");
	if (at == NULL) internal_error("can't house nowhere");
	iname->eventual_owner = at;
}

void Packaging::house_with(inter_name *iname, inter_name *landlord) {
	if (iname == NULL) internal_error("can't house null name");
	if (landlord == NULL) internal_error("can't house with nobody");
	iname->eventual_owner = landlord->eventual_owner;
}

int Packaging::houseed_in_function(inter_name *iname) {
	if (iname == NULL) return FALSE;
	if (iname->eventual_owner == NULL) return FALSE;
	if (iname->eventual_owner->eventual_type == function_ptype) return TRUE;
	return FALSE;
}
