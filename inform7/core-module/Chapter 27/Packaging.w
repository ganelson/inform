[Packaging::] Packaging.

@h Package types.

= (early code)
inter_symbol *plain_ptype = NULL;
inter_symbol *code_ptype = NULL;
inter_symbol *module_ptype = NULL;
inter_symbol *function_ptype = NULL;
inter_symbol *verb_ptype = NULL;
inter_symbol *mverb_ptype = NULL;
inter_symbol *to_phrase_ptype = NULL;
inter_symbol *rule_ptype = NULL;
inter_symbol *request_ptype = NULL;
inter_symbol *response_ptype = NULL;
inter_symbol *adjective_ptype = NULL;
inter_symbol *adjective_meaning_ptype = NULL;
inter_symbol *instance_ptype = NULL;
inter_symbol *property_ptype = NULL;
inter_symbol *variable_ptype = NULL;
inter_symbol *kind_ptype = NULL;
inter_symbol *action_ptype = NULL;
inter_symbol *activity_ptype = NULL;
inter_symbol *rulebook_ptype = NULL;
inter_symbol *relation_ptype = NULL;

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
	verb_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_verb");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), verb_ptype, Emit::baseline(Emit::IRS()), NULL));
	mverb_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_mverb");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), mverb_ptype, Emit::baseline(Emit::IRS()), NULL));
	to_phrase_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_phrase");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), to_phrase_ptype, Emit::baseline(Emit::IRS()), NULL));
	rule_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_rule");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), rule_ptype, Emit::baseline(Emit::IRS()), NULL));
	request_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_request");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), request_ptype, Emit::baseline(Emit::IRS()), NULL));
	response_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_response");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), response_ptype, Emit::baseline(Emit::IRS()), NULL));
	adjective_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_adjective");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), adjective_ptype, Emit::baseline(Emit::IRS()), NULL));
	adjective_meaning_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_adjective_meaning");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), adjective_meaning_ptype, Emit::baseline(Emit::IRS()), NULL));
	instance_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_instance");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), instance_ptype, Emit::baseline(Emit::IRS()), NULL));
	property_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_property");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), property_ptype, Emit::baseline(Emit::IRS()), NULL));
	variable_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_variable");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), variable_ptype, Emit::baseline(Emit::IRS()), NULL));
	kind_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_kind");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), kind_ptype, Emit::baseline(Emit::IRS()), NULL));
	action_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_action");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), action_ptype, Emit::baseline(Emit::IRS()), NULL));
	activity_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_activity");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), activity_ptype, Emit::baseline(Emit::IRS()), NULL));
	rulebook_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_rulebook");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), rulebook_ptype, Emit::baseline(Emit::IRS()), NULL));
	relation_ptype = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), I"_relation");
	Emit::guard(Inter::PackageType::new_packagetype(Emit::IRS(), relation_ptype, Emit::baseline(Emit::IRS()), NULL));
}

@

@e VERB_PR_COUNTER from 0
@e MVERB_PR_COUNTER
@e FUNCTION_PR_COUNTER
@e FORM_PR_COUNTER
@e BLOCK_PR_COUNTER
@e TO_PHRASE_PR_COUNTER
@e RULE_PR_COUNTER
@e REQUEST_PR_COUNTER
@e RESPONSE_PR_COUNTER
@e ADJECTIVE_PR_COUNTER
@e ADJECTIVE_MEANING_PR_COUNTER
@e TASK_PR_COUNTER
@e BLOCK_CONSTANT_PR_COUNTER
@e PROPOSITION_PR_COUNTER
@e INSTANCE_PR_COUNTER
@e INLINE_PR_COUNTER
@e PROPERTY_PR_COUNTER
@e VARIABLE_PR_COUNTER
@e KIND_PR_COUNTER
@e ACTION_PR_COUNTER
@e ACTIVITY_PR_COUNTER
@e RULEBOOK_PR_COUNTER
@e RELATION_PR_COUNTER
@e SUBSTITUTION_PR_COUNTER
@e SUBSTITUTIONF_PR_COUNTER
@e MISC_PR_COUNTER

@e MAX_PR_COUNTER

=
typedef struct package_request {
	struct inter_name *eventual_name;
	struct inter_symbol *eventual_type;
	struct inter_package *actual_package;
	struct package_request *parent_request;
	struct inter_reading_state write_position;
	int counters[MAX_PR_COUNTER];
	MEMORY_MANAGEMENT
} package_request;

@ =
package_request *Packaging::request(inter_name *name, package_request *parent, inter_symbol *pt) {
	package_request *R = CREATE(package_request);
	R->eventual_name = name;
	if (parent) name->eventual_owner = parent;
	R->eventual_type = pt;
	R->actual_package = NULL;
	R->parent_request = parent;
	R->write_position = Inter::Bookmarks::new_IRS(Emit::repository());
	for (int i=0; i<MAX_PR_COUNTER; i++) R->counters[i] = 0;
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
		if ((S->eventual_type == function_ptype) ||
			(S->eventual_type == instance_ptype) ||
			(S->eventual_type == property_ptype) ||
			(S->eventual_type == variable_ptype) ||
			(S->eventual_type == action_ptype) ||
			(S->eventual_type == kind_ptype) ||
			(S->eventual_type == relation_ptype) ||
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
package_request *main_pr = NULL;
package_request *Packaging::request_main(void) {
	if (main_pr == NULL)
		main_pr = Packaging::request(InterNames::iname(main_INAME), NULL, plain_ptype);
	return main_pr;
}

package_request *resources_pr = NULL;
package_request *Packaging::request_resources(void) {
	if (resources_pr == NULL)
		resources_pr = Packaging::request(InterNames::iname(resources_INAME), Packaging::request_main(), plain_ptype);
	return resources_pr;
}

package_request *generic_pr = NULL;
package_request *Packaging::request_generic(void) {
	if (generic_pr == NULL)
		generic_pr = Packaging::request(InterNames::iname(generic_INAME), Packaging::request_resources(), module_ptype);
	return generic_pr;
}

package_request *template_pr = NULL;
package_request *Packaging::request_template(void) {
	if (template_pr == NULL)
		template_pr = Packaging::request(InterNames::iname(template_INAME), Packaging::request_resources(), module_ptype);
	return template_pr;
}

package_request *synoptic_pr = NULL;
package_request *Packaging::request_synoptic(void) {
	if (synoptic_pr == NULL)
		synoptic_pr = Packaging::request(InterNames::iname(synoptic_INAME), Packaging::request_resources(), module_ptype);
	return synoptic_pr;
}

@

@e KINDS_SUBPACKAGE from 0
@e CONJUGATIONS_SUBPACKAGE
@e RULES_SUBPACKAGE
@e PHRASES_SUBPACKAGE
@e ADJECTIVES_SUBPACKAGE
@e INSTANCES_SUBPACKAGE
@e PROPERTIES_SUBPACKAGE
@e VARIABLES_SUBPACKAGE
@e EXTENSIONS_SUBPACKAGE
@e ACTIONS_SUBPACKAGE
@e RULEBOOKS_SUBPACKAGE
@e ACTIVITIES_SUBPACKAGE
@e RELATIONS_SUBPACKAGE
@e GRAMMAR_SUBPACKAGE
@e TABLES_SUBPACKAGE
@e CHRONOLOGY_SUBPACKAGE
@e LISTING_SUBPACKAGE
@e EQUATIONS_SUBPACKAGE

@e MAX_SUBPACKAGE

=
typedef struct subpackage_requests {
	struct package_request *subs[MAX_SUBPACKAGE];
} subpackage_requests;

void Packaging::initialise_subpackages(subpackage_requests *SR) {
	for (int i=0; i<MAX_SUBPACKAGE; i++) SR->subs[i] = NULL;
}

package_request *Packaging::request_conjugations(compilation_module *C) {
	return Packaging::request_resource(C, CONJUGATIONS_SUBPACKAGE);
}

package_request *Packaging::request_kinds(compilation_module *C) {
	return Packaging::request_resource(C, KINDS_SUBPACKAGE);
}

int generic_subpackages_initialised = FALSE;
subpackage_requests generic_subpackages;
int synoptic_subpackages_initialised = FALSE;
subpackage_requests synoptic_subpackages;

package_request *Packaging::request_resource(compilation_module *C, int ix) {
	subpackage_requests *SR = NULL;
	package_request *parent = NULL;
	if (C) {
		SR = Modules::subpackages(C);
		parent = C->resources;
	} else {
		if (generic_subpackages_initialised == FALSE) {
			generic_subpackages_initialised = TRUE;
			Packaging::initialise_subpackages(&generic_subpackages);
		}
		SR = &generic_subpackages;
		parent = Packaging::request_generic();
	}
	@<Handle the resource request@>;
}

package_request *Packaging::synoptic_resource(int ix) {
	if (synoptic_subpackages_initialised == FALSE) {
		synoptic_subpackages_initialised = TRUE;
		Packaging::initialise_subpackages(&synoptic_subpackages);
	}
	subpackage_requests *SR = &synoptic_subpackages;
	package_request *parent = Packaging::request_synoptic();
	@<Handle the resource request@>;
}

@<Handle the resource request@> =
	if (SR->subs[ix] == NULL) {
		text_stream *N = NULL;
		switch (ix) {
			case KINDS_SUBPACKAGE: N = I"kinds"; break;
			case CONJUGATIONS_SUBPACKAGE: N = I"conjugations"; break;
			case RULES_SUBPACKAGE: N = I"rules"; break;
			case PHRASES_SUBPACKAGE: N = I"phrases"; break;
			case ADJECTIVES_SUBPACKAGE: N = I"adjectives"; break;
			case INSTANCES_SUBPACKAGE: N = I"instances"; break;
			case PROPERTIES_SUBPACKAGE: N = I"properties"; break;
			case VARIABLES_SUBPACKAGE: N = I"variables"; break;
			case EXTENSIONS_SUBPACKAGE: N = I"extensions"; break;
			case ACTIONS_SUBPACKAGE: N = I"actions"; break;
			case RULEBOOKS_SUBPACKAGE: N = I"rulebooks"; break;
			case ACTIVITIES_SUBPACKAGE: N = I"activities"; break;
			case RELATIONS_SUBPACKAGE: N = I"relations"; break;
			case GRAMMAR_SUBPACKAGE: N = I"grammar"; break;
			case TABLES_SUBPACKAGE: N = I"tables"; break;
			case CHRONOLOGY_SUBPACKAGE: N = I"chronology"; break;
			case LISTING_SUBPACKAGE: N = I"listing"; break;
			case EQUATIONS_SUBPACKAGE: N = I"equations"; break;
			default: internal_error("nameless resource");
		}
		inter_name *iname = InterNames::one_off(N, parent);
		SR->subs[ix] = Packaging::request(iname, parent, plain_ptype);
	}
	return SR->subs[ix];

@ =
inter_name *Packaging::supply_iname(package_request *R, int what_for) {
	if (R == NULL) internal_error("no request");
	if ((what_for < 0) || (what_for >= MAX_PR_COUNTER)) internal_error("out of range");
	TEMPORARY_TEXT(P);
	switch (what_for) {
		case VERB_PR_COUNTER: WRITE_TO(P, "verb"); break;
		case MVERB_PR_COUNTER: WRITE_TO(P, "mverb"); break;
		case FUNCTION_PR_COUNTER: WRITE_TO(P, "function"); break;
		case FORM_PR_COUNTER: WRITE_TO(P, "form"); break;
		case BLOCK_PR_COUNTER: WRITE_TO(P, "code_block"); break;
		case TO_PHRASE_PR_COUNTER: WRITE_TO(P, "phrase"); break;
		case RULE_PR_COUNTER: WRITE_TO(P, "rule"); break;
		case REQUEST_PR_COUNTER: WRITE_TO(P, "request"); break;
		case RESPONSE_PR_COUNTER: WRITE_TO(P, "response"); break;
		case ADJECTIVE_PR_COUNTER: WRITE_TO(P, "adjective"); break;
		case ADJECTIVE_MEANING_PR_COUNTER: WRITE_TO(P, "adjective_meaning"); break;
		case TASK_PR_COUNTER: WRITE_TO(P, "task"); break;
		case BLOCK_CONSTANT_PR_COUNTER: WRITE_TO(P, "block_constant"); break;
		case PROPOSITION_PR_COUNTER: WRITE_TO(P, "proposition"); break;
		case INSTANCE_PR_COUNTER: WRITE_TO(P, "instance"); break;
		case INLINE_PR_COUNTER: WRITE_TO(P, "inline_pval"); break;
		case PROPERTY_PR_COUNTER: WRITE_TO(P, "property"); break;
		case VARIABLE_PR_COUNTER: WRITE_TO(P, "variable"); break;
		case KIND_PR_COUNTER: WRITE_TO(P, "kind"); break;
		case ACTION_PR_COUNTER: WRITE_TO(P, "action"); break;
		case ACTIVITY_PR_COUNTER: WRITE_TO(P, "activity"); break;
		case RULEBOOK_PR_COUNTER: WRITE_TO(P, "rulebook"); break;
		case RELATION_PR_COUNTER: WRITE_TO(P, "relation"); break;
		case SUBSTITUTION_PR_COUNTER: WRITE_TO(P, "ts"); break;
		case SUBSTITUTIONF_PR_COUNTER: WRITE_TO(P, "ts_fn"); break;
		case MISC_PR_COUNTER: WRITE_TO(P, "misc_const"); break;
		default: internal_error("unimplemented");
	}
	WRITE_TO(P, "_%d", ++(R->counters[what_for]));
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
		Inter::Symbols::set_translate(InterNames::to_symbol(iname), T);
		DISCARD_TEXT(T);
	}
	return iname;
}

inter_name *Packaging::function_text(inter_name *function_iname, package_request *R2, text_stream *translation) {
	package_request *R3 = Packaging::request(function_iname, R2, function_ptype);
	inter_name *iname = InterNames::one_off(I"call", R3);
	Packaging::house(iname, R3);
	if (translation) {
		Inter::Symbols::set_translate(InterNames::to_symbol(iname), translation);
	}
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
