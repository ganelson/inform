[Site::] Building Site.


@


@d MAX_CIP_STACK_SIZE 2

=
typedef struct building_site {
	struct inter_package *main_package;
	struct inter_package *connectors_package;
	struct inter_package *assimilation_package;
	struct inter_bookmark pragmas_bookmark;
	struct inter_bookmark package_types_bookmark;
	struct inter_bookmark veneer_bookmark;
	struct inter_bookmark begin_bookmark;
	struct inter_bookmark locals_bookmark;
	struct inter_bookmark code_bookmark;
	struct package_request *main_pr;
	struct package_request *connectors_pr;
	struct package_request *veneer_pr;
	struct inter_package *current_inter_routine;
	struct code_insertion_point cip_stack[MAX_CIP_STACK_SIZE];
	int cip_sp;

	struct site_packaging_data spdata;

	struct inter_symbol *opcodes_set[MAX_BIPS];

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
	B->assimilation_package = NULL;
	for (int i=0; i<MAX_BIPS; i++) B->opcodes_set[i] = NULL;
	B->pragmas_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->package_types_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->veneer_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->begin_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->locals_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->code_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->main_pr = NULL;
	B->connectors_pr = NULL;
	B->veneer_pr = NULL;
	B->current_inter_routine = NULL;
	B->cip_sp = 0;
	B->veneer_symbols_indexed_by_name = Dictionaries::new(512, FALSE);
	for (int i=0; i<MAX_VSYMBS; i++) B->veneer_symbols[i] = NULL;
	for (int i=0; i<MAX_VSYMBS; i++) B->veneer_symbol_names[i] = NULL;
	for (int i=0; i<MAX_VSYMBS; i++) B->veneer_symbol_translations[i] = NULL;
	Veneer::create_indexes(I);
	Packaging::clear_pdata(I);
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

inter_symbol *Site::get_opcode(inter_tree *I, inter_ti bip) {
	return I->site.opcodes_set[bip];
}

void Site::set_opcode(inter_tree *I, inter_ti bip, inter_symbol *S) {
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
	if (I) {
		inter_package *P = I->site.connectors_package;
		if (P) return P;
		P = Inter::Packages::by_url(I, I"/main/connectors");
		if (P) I->site.connectors_package = P;
		return P;
	}
	return NULL;
}

inter_package *Site::ensure_connectors_package(inter_tree *I) {
	if (I == NULL) internal_error("no tree for connectors");
	inter_package *connectors = Site::connectors_package(I);
	if (connectors == NULL) {
		connectors = Site::make_linkage_package(I, I"connectors");
		Site::set_connectors_package(I, connectors);
		Inter::Packages::make_linklike(connectors);
	}
	return connectors;
}

inter_package *Site::make_linkage_package(inter_tree *I, text_stream *name) {
	inter_package *P = Inter::Packages::by_name(Site::main_package(I), name);
	if (P == NULL) {
		inter_symbol *linkage = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_linkage");
		if (linkage == NULL) internal_error("no linkage ptype");
		inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(Site::main_package(I));
		Inter::Package::new_package(&IBM, name, linkage,
			(inter_ti) Inter::Bookmarks::baseline(&IBM)+1, NULL, &P);
	}
	if (P == NULL) internal_error("unable to create package");
	return P;
}

void Site::set_main_package(inter_tree *I, inter_package *M) {
	if (I == NULL) internal_error("no tree"); 
	I->site.main_package = M;
}

void Site::set_connectors_package(inter_tree *I, inter_package *M) {
	if (I == NULL) internal_error("no tree"); 
	I->site.connectors_package = M;
}

inter_package *Site::assimilation_package(inter_tree *I) {
	if (I == NULL) internal_error("no tree"); 
	return I->site.assimilation_package;
}

inter_package *Site::ensure_assimilation_package(inter_tree *I, inter_symbol *plain_ptype_symbol) {
	if (I == NULL) internal_error("no tree"); 
	if (I->site.assimilation_package == NULL) {
		inter_package *main_package = Site::main_package(I);
		inter_package *t_p = Inter::Packages::by_name(main_package, I"template");
		#ifdef PIPELINE_MODULE
		if (t_p == NULL) {
			inter_bookmark in_main = Inter::Bookmarks::at_end_of_this_package(main_package);
			t_p = CompileSplatsStage::new_package_named(&in_main, I"template", plain_ptype_symbol);
		}
		#endif
		I->site.assimilation_package = t_p;
	}
	return I->site.assimilation_package;
}

void Site::set_assimilation_package(inter_tree *I, inter_package *M) {
	if (I == NULL) internal_error("no tree"); 
	I->site.assimilation_package = M;
}

package_request *Site::main_request(inter_tree *I) {
	if (I->site.main_pr == NULL)
		I->site.main_pr = Packaging::request(I, InterNames::explicitly_named(I"main", NULL),
			PackageTypes::get(I, I"_plain"));
	return I->site.main_pr;
}

package_request *Site::connectors_request(inter_tree *I) {
	if (I->site.connectors_pr == NULL) {
		module_package *T = Packaging::get_unit(I, I"connectors", I"_linkage");
		I->site.connectors_pr = T->the_package;
	}
	return I->site.connectors_pr;
}

package_request *Site::veneer_request(inter_tree *I) {
	if (I->site.veneer_pr == NULL) {
		module_package *T = Packaging::get_unit(I, I"veneer", I"_linkage");
		I->site.veneer_pr = T->the_package;
		packaging_state save = Packaging::enter(I->site.veneer_pr);
		I->site.veneer_bookmark = Packaging::bubble(I);
		Packaging::exit(I, save);
	}
	return I->site.veneer_pr;
}
inter_bookmark *Site::veneer_bookmark(inter_tree *I) {
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

