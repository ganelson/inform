[Site::] Building Site.


@

=
typedef struct building_site {
	struct inter_package *main_package;
	struct package_request *main_request;

	struct inter_package *connectors_package;
	struct package_request *connectors_request;

	struct inter_package *architecture_package;
	struct package_request *architecture_request;
	struct inter_bookmark architecture_bookmark;

	struct inter_bookmark pragmas_bookmark;
	struct inter_bookmark package_types_bookmark;

	struct inter_symbol *primitives_by_BIP[MAX_BIPS];

	struct site_packaging_data spdata;
	struct site_production_data sprdata;
} building_site;

@ =
void Site::clear(inter_tree *I) {
	building_site *B = &(I->site);

	B->main_package = NULL;
	B->main_request = NULL;

	B->connectors_package = NULL;
	B->connectors_request = NULL;

	B->architecture_package = NULL;
	B->architecture_request = NULL;
	B->architecture_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);

	B->pragmas_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->package_types_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);

	for (int i=0; i<MAX_BIPS; i++) B->primitives_by_BIP[i] = NULL;

	Produce::clear_prdata(I);
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
	return I->site.primitives_by_BIP[bip];
}

void Site::set_opcode(inter_tree *I, inter_ti bip, inter_symbol *S) {
	I->site.primitives_by_BIP[bip] = S;
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
	if (I->site.main_request == NULL)
		I->site.main_request =
			Packaging::request(I,
				InterNames::explicitly_named(I"main", NULL),
				PackageTypes::get(I, I"_plain"));
	return I->site.main_request;
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
	if (I->site.connectors_request == NULL) {
		module_package *T = Packaging::get_unit(I, I"connectors", I"_linkage");
		I->site.connectors_request = T->the_package;
	}
	return I->site.connectors_request;
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
	inter_symbol *uks) {
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
			S = Site::arch_constant(I, N, uks, 0);			
			Inter::Symbols::annotate_i(S, VENEER_IANN, 1);
		}	
	}	
	return S;
}

inter_symbol *Site::arch_constant(inter_tree *I, text_stream *N,
	inter_symbol *uks, inter_ti val) {
	inter_package *arch = Site::architecture_package(I);
	inter_symbols_table *tab = Inter::Packages::scope(arch);
	inter_symbol *S = InterSymbolsTables::symbol_from_name_creating(tab, N);
	Inter::Symbols::annotate_i(S, ARCHITECTURAL_IANN, 1);
	inter_bookmark *IBM = Site::architecture_bookmark(I);
	Produce::guard(Inter::Constant::new_numerical(IBM,
		InterSymbolsTables::id_from_symbol(I, arch, S),
		InterSymbolsTables::id_from_symbol(I, arch, uks),
		LITERAL_IVAL, val,
		(inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
	return S;
}

inter_symbol *Site::arch_constant_hex(inter_tree *I, text_stream *N,
	inter_symbol *uks, inter_ti val) {
	inter_symbol *S = Site::arch_constant(I, N, uks, val);
	Inter::Symbols::annotate_i(S, HEX_IANN, 1);
	return S;
}

inter_symbol *Site::arch_constant_signed(inter_tree *I, text_stream *N,
	inter_symbol *uks, int val) {
	inter_symbol *S = Site::arch_constant(I, N, uks, (inter_ti) val);
	Inter::Symbols::annotate_i(S, SIGNED_IANN, 1);
	return S;
}

@ These constants mostly have obvious meanings, but a few notes:

(1) |NULL|, in our runtime, is -1, and not 0 as it would be in C. This is
emitted as "unchecked" to avoid the value being rejected as being too large,
as it would be if it were viewed as a signed rather than unsigned integer.

(2) |IMPROBABLE_VALUE| is one which is unlikely even if possible to be a
genuine I7 value. The efficiency of runtime code handling tables depends on
how well chosen this is: it would ran badly if we chose 1, for instance.

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
	inter_architecture *current_architecture, inter_symbol *uks) {
	if (current_architecture == NULL) internal_error("no architecture set");
	int Z = Architectures::is_16_bit(current_architecture);
	int D = Architectures::debug_enabled(current_architecture);

	if (Z) {
		Site::arch_constant(I, I"WORDSIZE", uks,                        2);
		Site::arch_constant_hex(I, I"NULL", uks,                   0xffff);
		Site::arch_constant_hex(I, I"WORD_HIGHBIT", uks,           0x8000);
		Site::arch_constant_hex(I, I"WORD_NEXTTOHIGHBIT", uks,     0x4000);
		Site::arch_constant_hex(I, I"IMPROBABLE_VALUE", uks,       0x7fe3);
		Site::arch_constant(I, I"MAX_POSITIVE_NUMBER", uks,         32767);
		Site::arch_constant_signed(I, I"MIN_NEGATIVE_NUMBER", uks, -32768);
		Site::arch_constant(I, I"TARGET_ZCODE", uks,                    1);
	} else {
		Site::arch_constant(I, I"WORDSIZE", uks,                             4);
		Site::arch_constant_hex(I, I"NULL", uks,                    0xffffffff);
		Site::arch_constant_hex(I, I"WORD_HIGHBIT", uks,            0x80000000);
		Site::arch_constant_hex(I, I"WORD_NEXTTOHIGHBIT", uks,      0x40000000);
		Site::arch_constant_hex(I, I"IMPROBABLE_VALUE", uks,        0xdeadce11);
		Site::arch_constant(I, I"MAX_POSITIVE_NUMBER", uks,         2147483647);
		Site::arch_constant_signed(I, I"MIN_NEGATIVE_NUMBER", uks, -2147483648);
		Site::arch_constant(I, I"INDIV_PROP_START", uks,                     0);
		Site::arch_constant(I, I"TARGET_GLULX", uks,                         1);
	}

	if (D) Site::arch_constant(I, I"DEBUG", uks, 1);
}
