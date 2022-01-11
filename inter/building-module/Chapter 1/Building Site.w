[Site::] Building Site.


@

=
typedef struct building_site {
	struct inter_package *main_package;
	struct package_request *main_pr;

	struct inter_package *connectors_package;
	struct package_request *connectors_pr;

	struct inter_package *architecture_package;
	struct inter_bookmark architecture_bookmark;
	struct package_request *architecture_request;

	struct inter_package *assimilation_package;
	struct inter_bookmark pragmas_bookmark;
	struct inter_bookmark package_types_bookmark;
	struct inter_package *current_inter_routine;

	struct site_packaging_data spdata;

	struct inter_symbol *opcodes_set[MAX_BIPS];

	struct site_production_data sprdata;
} building_site;

@ =
void Site::clear(inter_tree *I) {
	building_site *B = &(I->site);
	B->main_package = NULL;
	B->connectors_package = NULL;
	B->architecture_package = NULL;
	B->assimilation_package = NULL;
	for (int i=0; i<MAX_BIPS; i++) B->opcodes_set[i] = NULL;
	B->pragmas_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->package_types_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->architecture_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	Produce::clear_prdata(I);
	B->main_pr = NULL;
	B->connectors_pr = NULL;
	B->architecture_request = NULL;
	B->current_inter_routine = NULL;
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

inter_symbol *Site::get_opcode(inter_tree *I, inter_ti bip) {
	return I->site.opcodes_set[bip];
}

void Site::set_opcode(inter_tree *I, inter_ti bip, inter_symbol *S) {
	I->site.opcodes_set[bip] = S;
}

void Site::note_package_name(inter_tree *I, inter_package *pack, text_stream *N) {
	if (Str::eq(N, I"main")) I->site.main_package = pack;
	if (Str::eq(N, I"connectors")) I->site.connectors_package = pack;
	if (Str::eq(N, I"veneer")) I->site.architecture_package = pack;
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

package_request *Site::main_request(inter_tree *I) {
	if (I->site.main_pr == NULL)
		I->site.main_pr =
			Packaging::request(I,
				InterNames::explicitly_named(I"main", NULL),
				PackageTypes::get(I, I"_plain"));
	return I->site.main_pr;
}

inter_package *Site::connectors_package_if_it_exists(inter_tree *I) {
	if (I) return I->site.connectors_package;
	return NULL;
}

inter_package *Site::ensure_connectors_package(inter_tree *I) {
	if (I) {
		if (I->site.connectors_package == NULL) {
			Packaging::incarnate(Site::connectors_request(I));
			Inter::Packages::make_linklike(I->site.connectors_package);
		}
		return I->site.connectors_package;
	}
	return NULL;
}

package_request *Site::connectors_request(inter_tree *I) {
	if (I->site.connectors_pr == NULL) {
		module_package *T = Packaging::get_unit(I, I"connectors", I"_linkage");
		I->site.connectors_pr = T->the_package;
	}
	return I->site.connectors_pr;
}

package_request *Site::architecture_request(inter_tree *I) {
	if (I->site.architecture_request == NULL) {
		module_package *T = Packaging::get_unit(I, I"veneer", I"_linkage");
		I->site.architecture_request = T->the_package;
		packaging_state save = Packaging::enter(I->site.architecture_request);
		I->site.architecture_bookmark = Packaging::bubble(I);
		Packaging::exit(I, save);
	}
	return I->site.architecture_request;
}

inter_package *Site::architecture_package_if_it_exists(inter_tree *I) {
	if (I) return I->site.architecture_package;
	return NULL;
}

inter_package *Site::architecture_package(inter_tree *I) {
	if (I) {
		if (I->site.architecture_package == NULL) {
			Packaging::incarnate(Site::architecture_request(I));
		}
		return I->site.architecture_package;
	}
	return NULL;
}

inter_bookmark *Site::architecture_bookmark(inter_tree *I) {
	Site::architecture_request(I);
	return &(I->site.architecture_bookmark);
}

dictionary *create_these_architectural_symbols_on_demand = NULL;

inter_symbol *Site::find_architectural_symbol(inter_tree *I, text_stream *N,
	inter_symbol *unchecked_kind_symbol) {
	inter_package *arch = Site::architecture_package(I);
	inter_symbols_table *tab = Inter::Packages::scope(arch);
	inter_symbol *S = InterSymbolsTables::symbol_from_name(tab, N);
	if (S == NULL) {
		if (create_these_architectural_symbols_on_demand == NULL) {
			create_these_architectural_symbols_on_demand = Dictionaries::new(16, TRUE);
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"#dictionary_table");
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"#actions_table");
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"#grammar_table");
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"self");
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"Routine");
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"String");
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"Class");
			Dictionaries::create(create_these_architectural_symbols_on_demand, I"Object");
		}
		if (Dictionaries::find(create_these_architectural_symbols_on_demand, N)) {
			S = InterSymbolsTables::symbol_from_name_creating(tab, N);
			Inter::Symbols::annotate_i(S, VENEER_IANN, 1);

			inter_bookmark *IBM = Site::architecture_bookmark(I);
			Produce::guard(Inter::Constant::new_numerical(IBM,
				InterSymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), arch, S),
				InterSymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), arch, unchecked_kind_symbol),
				LITERAL_IVAL, 0,
				(inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
		}	
	}	
	return S;
}

@ Lastly, we define the constants |WORDSIZE|, |DEBUG| (if applicable) and
either |TARGET_ZCODE| or |TARGET_GLULX|, as appropriate. These really now mean
"target 16-bit" or "target 32-bit", and their names are a hangover from when
Inform 7 could only work with Inform 6. The reason we need to define these
is so that if a kit is parsed from source and added to this tree, we will then
be able to resolve conditional compilation matter placed inside, e.g.,
|#ifdef TARGET_ZCODE;| ... |#endif;| directives.

For now, at least, these live in the package |main/veneer|.

=
void Site::make_architectural_definitions(inter_tree *I,
	inter_architecture *current_architecture, inter_symbol *unchecked_kind_symbol) {
	if (current_architecture == NULL) internal_error("no architecture set");
	int Z = Architectures::is_16_bit(current_architecture);
	int D = Architectures::debug_enabled(current_architecture);

	inter_package *veneer_p = Site::architecture_package(I);
	inter_bookmark *in_veneer = Site::architecture_bookmark(I);
	inter_symbol *vi_unchecked =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(in_veneer), I"K_unchecked");
	Wiring::wire_to(vi_unchecked, unchecked_kind_symbol);

	inter_symbol *con_name = InterSymbolsTables::create_with_unique_name(
		Inter::Bookmarks::scope(in_veneer), I"WORDSIZE");
	Inter::Constant::new_numerical(in_veneer,
		InterSymbolsTables::id_from_symbol(I, veneer_p, con_name),
		InterSymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
		LITERAL_IVAL, (Z)?2:4,
		(inter_ti) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	inter_symbol *target_name = InterSymbolsTables::create_with_unique_name(
		Inter::Bookmarks::scope(in_veneer), (Z)?I"TARGET_ZCODE":I"TARGET_GLULX");
	Inter::Constant::new_numerical(in_veneer,
		InterSymbolsTables::id_from_symbol(I, veneer_p, target_name),
		InterSymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
		LITERAL_IVAL, 1,
		(inter_ti) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	if (D) {
		inter_symbol *D_name = InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(in_veneer), I"DEBUG");
		Inter::Constant::new_numerical(in_veneer,
			InterSymbolsTables::id_from_symbol(I, veneer_p, D_name),
			InterSymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
			LITERAL_IVAL, 1,
			(inter_ti) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	}
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

inter_package *Site::get_cir(inter_tree *I) {
	return I->site.current_inter_routine;
}

void Site::set_cir(inter_tree *I, inter_package *P) {
	I->site.current_inter_routine = P;
}

