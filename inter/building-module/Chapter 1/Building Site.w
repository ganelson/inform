[Site::] Building Site.


@

The maximum here is beyond plenty: it's not the maximum hierarchical depth
of the Inter output, it's the maximum number of times that Inform interrupts
itself during compilation.

@d MAX_PACKAGING_ENTRY_DEPTH 128

@d MAX_CIP_STACK_SIZE 2

=
typedef struct building_site {
	struct inter_package *main_package;
	struct inter_package *connectors_package;
	struct inter_symbol *opcodes_set[MAX_BIPS];
	struct inter_bookmark pragmas_bookmark;
	struct inter_bookmark package_types_bookmark;
	struct inter_bookmark holdings_bookmark;
	struct inter_bookmark veneer_bookmark;
	struct inter_bookmark begin_bookmark;
	struct inter_bookmark locals_bookmark;
	struct inter_bookmark code_bookmark;
	struct dictionary *modules_indexed_by_name;
	struct package_request *main_pr;
	struct package_request *connectors_pr;
	struct package_request *veneer_pr;
	struct inter_package *current_inter_routine;
	struct packaging_state current_state;
	struct code_insertion_point cip_stack[MAX_CIP_STACK_SIZE];
	int cip_sp;
	struct inter_bookmark packaging_entry_stack[MAX_PACKAGING_ENTRY_DEPTH];
	int packaging_entry_sp;
	struct dictionary *hls_indexed_by_name;
	#ifndef NO_DEFINED_HL_VALUES
	#define NO_DEFINED_HL_VALUES 1
	#endif
	struct hierarchy_location *hls_indexed_by_id[NO_DEFINED_HL_VALUES];
	#ifndef NO_DEFINED_HAP_VALUES
	#define NO_DEFINED_HAP_VALUES 1
	#endif
	struct hierarchy_attachment_point *haps_indexed_by_id[NO_DEFINED_HAP_VALUES];
	#ifndef NO_DEFINED_HMD_VALUES
	#define NO_DEFINED_HMD_VALUES 1
	#endif
	struct hierarchy_metadatum *hmds_indexed_by_id[NO_DEFINED_HMD_VALUES];
	struct inter_symbol *veneer_symbols[MAX_VSYMBS];
	struct text_stream *veneer_symbol_names[MAX_VSYMBS];
	struct text_stream *veneer_symbol_translations[MAX_VSYMBS];
	struct dictionary *veneer_symbols_indexed_by_name;
} building_site;

@ =
void Site::clear(inter_tree *I) {
	building_site *B = &(I->site);
	B->main_package = NULL;
	B->connectors_package = NULL;
	for (int i=0; i<MAX_BIPS; i++) B->opcodes_set[i] = NULL;
	B->pragmas_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->package_types_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->holdings_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->veneer_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->begin_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->locals_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->code_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->modules_indexed_by_name = NULL;
	B->main_pr = NULL;
	B->connectors_pr = NULL;
	B->veneer_pr = NULL;
	B->current_inter_routine = NULL;
	B->current_state = Packaging::stateless();
	B->cip_sp = 0;
	B->packaging_entry_sp = 0;
	for (int i=0; i<NO_DEFINED_HL_VALUES; i++) B->hls_indexed_by_id[i] = NULL;
	B->hls_indexed_by_name = Dictionaries::new(512, FALSE);
	for (int i=0; i<NO_DEFINED_HAP_VALUES; i++) B->haps_indexed_by_id[i] = NULL;
	for (int i=0; i<NO_DEFINED_HMD_VALUES; i++) B->hmds_indexed_by_id[i] = NULL;
	B->veneer_symbols_indexed_by_name = Dictionaries::new(512, FALSE);
	for (int i=0; i<MAX_VSYMBS; i++) B->veneer_symbols[i] = NULL;
	Veneer::create_indexes(I);
	Packaging::initialise_state(I);
}

inter_bookmark *Site::pragmas(inter_tree *I) {
	return &(I->site.pragmas_bookmark);
}
void Site::set_pragmas(inter_tree *I, inter_bookmark IBM) {
	I->site.pragmas_bookmark = IBM;
}
inter_bookmark *Site::package_types(inter_tree *I) {
	return &(I->site.package_types_bookmark);
}
void Site::set_package_types(inter_tree *I, inter_bookmark IBM) {
	I->site.package_types_bookmark = IBM;
}
inter_bookmark *Site::holdings(inter_tree *I) {
	return &(I->site.holdings_bookmark);
}
void Site::set_holdings(inter_tree *I, inter_bookmark IBM) {
	I->site.holdings_bookmark = IBM;
}
inter_bookmark *Site::begin(inter_tree *I) {
	return &(I->site.begin_bookmark);
}
void Site::set_begin(inter_tree *I, inter_bookmark IBM) {
	I->site.begin_bookmark = IBM;
}
inter_bookmark *Site::locals(inter_tree *I) {
	return &(I->site.locals_bookmark);
}
void Site::set_locals(inter_tree *I, inter_bookmark IBM) {
	I->site.locals_bookmark = IBM;
}
inter_bookmark *Site::code(inter_tree *I) {
	return &(I->site.code_bookmark);
}
void Site::set_code(inter_tree *I, inter_bookmark IBM) {
	I->site.code_bookmark = IBM;
}

inter_symbol *Site::get_opcode(inter_tree *I, inter_t bip) {
	return I->site.opcodes_set[bip];
}

void Site::set_opcode(inter_tree *I, inter_t bip, inter_symbol *S) {
	I->site.opcodes_set[bip] = S;
}

inter_package *Site::main_package(inter_tree *I) {
	if (I) {
		if (I->site.main_package == NULL)
			Packaging::incarnate(Site::main_request(I));
		return I->site.main_package;
	}
	return NULL;
}

inter_package *Site::main_package_if_it_exists(inter_tree *I) {
	if (I) return I->site.main_package;
	return NULL;
}

inter_package *Site::connectors_package(inter_tree *I) {
	if (I) return I->site.connectors_package;
	return NULL;
}

void Site::set_main_package(inter_tree *I, inter_package *M) {
	if (I == NULL) internal_error("no tree"); 
	I->site.main_package = M;
}

void Site::set_connectors_package(inter_tree *I, inter_package *M) {
	if (I == NULL) internal_error("no tree"); 
	I->site.connectors_package = M;
}

dictionary *Site::modules_dictionary(inter_tree *I) {
	if (I->site.modules_indexed_by_name == NULL) {
		I->site.modules_indexed_by_name = Dictionaries::new(512, FALSE);
	}
	return I->site.modules_indexed_by_name;
}

package_request *Site::main_request(inter_tree *I) {
	if (I->site.main_pr == NULL)
		I->site.main_pr = Packaging::request(I, InterNames::explicitly_named(I"main", NULL),
			PackageTypes::get(I, I"_plain"));
	return I->site.main_pr;
}

package_request *Site::connectors_request(inter_tree *I) {
	if (I->site.connectors_pr == NULL) {
		module_package *T = Packaging::get_module(I, I"connectors");
		I->site.connectors_pr = T->the_package;
	}
	return I->site.connectors_pr;
}

package_request *Site::veneer_request(inter_tree *I) {
	if (I->site.veneer_pr == NULL) {
		module_package *T = Packaging::get_module(I, I"veneer");
		I->site.veneer_pr = T->the_package;
		packaging_state save = Packaging::enter(I->site.veneer_pr);
		I->site.veneer_bookmark = Packaging::bubble(I);
		Packaging::exit(I, save);
	}
	return I->site.veneer_pr;
}
inter_bookmark *Site::veneer_booknark(inter_tree *I) {
	Site::veneer_request(I);
	return &(I->site.veneer_bookmark);
}
inter_symbol *Site::veneer_symbol(inter_tree *I, int ix) {
	inter_symbol *symb = Veneer::find_by_index(I, ix, Produce::kind_to_symbol(NULL));
	return symb;
}

inter_package *Site::get_cir(inter_tree *I) {
	return I->site.current_inter_routine;
}

void Site::set_cir(inter_tree *I, inter_package *P) {
	I->site.current_inter_routine = P;
}

