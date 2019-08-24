[Produce::] Producing Inter.

@h Definitions.

@

=
inter_package *current_inter_routine = NULL;

inter_package *Produce::get_cir(void) {
	return current_inter_routine;
}

void Produce::set_cir(inter_package *P) {
	current_inter_routine = P;
}

void Produce::guard(inter_error_message *ERR) {
	if ((ERR) && (problem_count == 0)) { Inter::Errors::issue(ERR); /* internal_error("inter error"); */ }
}

inter_symbol *Produce::new_symbol(inter_symbols_table *T, text_stream *name) {
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if ((symb) && (Inter::Symbols::read_annotation(symb, HOLDING_IANN) == 1)) {
		Produce::annotate_symbol_i(symb, DELENDA_EST_IANN, 1);
		inter_tree_node *D = Inter::Symbols::definition(symb);
		Inter::Tree::remove_node(D);
		Inter::Symbols::undefine(symb);
		return symb;
	}
	return Inter::SymbolsTables::create_with_unique_name(T, name);
}

inter_symbol *Produce::define_symbol(inter_name *iname) {
	InterNames::to_symbol(iname);
	if (iname->symbol) {
		if (Inter::Symbols::is_predeclared(iname->symbol)) {
			Inter::Symbols::undefine(iname->symbol);
		}
	}
	if ((iname->symbol) && (Inter::Symbols::read_annotation(iname->symbol, HOLDING_IANN) == 1)) {
		if (Inter::Symbols::read_annotation(iname->symbol, DELENDA_EST_IANN) != 1) {
			Produce::annotate_symbol_i(iname->symbol, DELENDA_EST_IANN, 1);
			Inter::Symbols::strike_definition(iname->symbol);
		}
		return iname->symbol;
	}
	return iname->symbol;
}

inter_tree *Produce::tree(void) {
	return Inter::Bookmarks::tree(Packaging::at());
}

inter_symbols_table *Produce::main_scope(void) {
	return Inter::Packages::scope(Inter::Tree::main_package(Produce::tree()));
}

inter_symbols_table *Produce::connectors_scope(void) {
	return Inter::Packages::scope(Inter::Tree::connectors_package(Produce::tree()));
}

inter_symbols_table *Produce::global_scope(void) {
	return Inter::Tree::global_scope(Produce::tree());
}

inter_symbol *Produce::opcode(inter_t bip) {
	return Primitives::get(Produce::tree(), bip);
}

inter_t Produce::baseline(inter_bookmark *IBM) {
	if (IBM == NULL) return 0;
	if (Inter::Bookmarks::package(IBM) == NULL) return 0;
	if (Inter::Packages::is_rootlike(Inter::Bookmarks::package(IBM))) return 0;
	if (Inter::Packages::is_codelike(Inter::Bookmarks::package(IBM)))
		return (inter_t) Inter::Packages::baseline(Inter::Packages::parent(Inter::Bookmarks::package(IBM))) + 1;
	return (inter_t) Inter::Packages::baseline(Inter::Bookmarks::package(IBM)) + 1;
}

inter_bookmark Produce::bookmark(void) {
	inter_bookmark b = Inter::Bookmarks::snapshot(Packaging::at());
	return b;
}

inter_bookmark Produce::bookmark_at(inter_bookmark *IBM) {
	inter_bookmark b = Inter::Bookmarks::snapshot(IBM);
	return b;
}

void Produce::nop(void) {
	Produce::guard(Inter::Nop::new(Packaging::at(), Produce::baseline(Packaging::at()), NULL));
}

void Produce::nop_at(inter_bookmark *IBM) {
	Produce::guard(Inter::Nop::new(IBM, Produce::baseline(IBM) + 2, NULL));
}

void Produce::version(int N) {
	Produce::guard(Inter::Version::new(Packaging::at(), N, Produce::baseline(Packaging::at()), NULL));
}

void Produce::metadata(package_request *P, text_stream *key, text_stream *value) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID), value);
	inter_name *iname = InterNames::explicitly_named(key, P);
	inter_symbol *key_name = Produce::define_symbol(iname);
	packaging_state save = Packaging::enter_home_of(iname);
	Produce::guard(Inter::Metadata::new(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), key_name), ID, Produce::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

inter_symbol *Produce::packagetype(text_stream *name, int enclosing) {
	inter_symbol *pt = Produce::new_symbol(Inter::Tree::global_scope(Produce::tree()), name);
	Produce::guard(Inter::PackageType::new_packagetype(Packaging::package_types(), pt, Produce::baseline(Packaging::package_types()), NULL));
	if (enclosing) Produce::annotate_symbol_i(pt, ENCLOSING_IANN, 1);
	return pt;
}

void Produce::comment(text_stream *text) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID), text);
	Produce::guard(Inter::Comment::new(Packaging::at(), Produce::baseline(Packaging::at()), NULL, ID));
}

inter_package *Produce::package(inter_name *iname, inter_symbol *ptype) {
	if (ptype == NULL) internal_error("no package type");
	inter_t B = Produce::baseline(Packaging::at());
	inter_package *IP = NULL;
	TEMPORARY_TEXT(hmm);
	WRITE_TO(hmm, "%n", iname);
	Produce::guard(Inter::Package::new_package_named(Packaging::at(), hmm, TRUE, ptype, B, NULL, &IP));
	DISCARD_TEXT(hmm);
	if (IP) Inter::Bookmarks::set_current_package(Packaging::at(), IP);
	return IP;
}

void Produce::annotate_symbol_t(inter_symbol *symb, inter_t annot_ID, text_stream *S) {
	Inter::Symbols::annotate_t(Inter::Packages::tree(symb->owning_table->owning_package), symb->owning_table->owning_package, symb, annot_ID, S);
}

void Produce::annotate_symbol_w(inter_symbol *symb, inter_t annot_ID, wording W) {
	TEMPORARY_TEXT(temp);
	WRITE_TO(temp, "%W", W);
	Inter::Symbols::annotate_t(Inter::Packages::tree(symb->owning_table->owning_package), symb->owning_table->owning_package, symb, annot_ID, temp);
	DISCARD_TEXT(temp);
}

void Produce::annotate_symbol_i(inter_symbol *symb, inter_t annot_ID, inter_t V) {
	Inter::Symbols::annotate_i(symb, annot_ID, V);
}

void Produce::annotate_iname_i(inter_name *N, inter_t annot_ID, inter_t V) {
	Inter::Symbols::annotate_i(InterNames::to_symbol(N), annot_ID, V);
}

void Produce::set_flag(inter_name *iname, int f) {
	Inter::Symbols::set_flag(InterNames::to_symbol(iname), f);
}

void Produce::clear_flag(inter_name *iname, int f) {
	Inter::Symbols::clear_flag(InterNames::to_symbol(iname), f);
}

void Produce::annotate_i(inter_name *iname, inter_t annot_ID, inter_t V) {
	if (iname) Produce::annotate_symbol_i(InterNames::to_symbol(iname), annot_ID, V);
}

void Produce::annotate_w(inter_name *iname, inter_t annot_ID, wording W) {
	if (iname) Produce::annotate_symbol_w(InterNames::to_symbol(iname), annot_ID, W);
}

int Produce::read_annotation(inter_name *iname, inter_t annot) {
	return Inter::Symbols::read_annotation(InterNames::to_symbol(iname), annot);
}


void Produce::change_translation(inter_name *iname, text_stream *new_text) {
	Inter::Symbols::set_translate(InterNames::to_symbol(iname), new_text);
}

text_stream *Produce::get_translation(inter_name *iname) {
	return Inter::Symbols::get_translate(InterNames::to_symbol(iname));
}

void Produce::code(void) {
	Produce::guard(Inter::Code::new(Produce::at(), Produce::level(), NULL));
}

void Produce::evaluation(void) {
	Produce::guard(Inter::Evaluation::new(Produce::at(), Produce::level(), NULL));
}

void Produce::reference(void) {
	Produce::guard(Inter::Reference::new(Produce::at(), Produce::level(), NULL));
}

@

@d MAX_NESTED_NOTEWORTHY_LEVELS 256
@d MAX_CIP_STACK_SIZE 2

=
typedef struct code_insertion_point {
	int inter_level;
	int noted_levels[MAX_NESTED_NOTEWORTHY_LEVELS];
	int noted_sp;
	int error_flag;
	inter_bookmark *insertion_bm;
	inter_bookmark saved_bm;
} code_insertion_point;

code_insertion_point cip_stack[MAX_CIP_STACK_SIZE];
int cip_sp = 0;

code_insertion_point Produce::new_cip(inter_bookmark *IBM) {
	code_insertion_point cip;
	cip.inter_level = (int) (Produce::baseline(IBM) + 2);
	cip.noted_sp = 2;
	cip.error_flag = FALSE;
	cip.insertion_bm = IBM;
	cip.saved_bm = Inter::Bookmarks::snapshot(Packaging::at());
	return cip;
}

inter_bookmark begin_bookmark;
inter_bookmark locals_bookmark;
inter_bookmark code_bookmark;

inter_bookmark *Produce::locals_bookmark(void) {
	return &locals_bookmark;
}

inter_package *Produce::block(packaging_state *save, inter_name *iname) {
	if (current_inter_routine) internal_error("nested routines");
	if (Packaging::at() == NULL) internal_error("no inter repository");
	if (save) {
		*save = Packaging::enter_home_of(iname);
		package_request *R = InterNames::location(iname);
		if ((R == NULL) || (R == Packaging::main())) {
			LOG("Routine outside of package: %n\n", iname);
			internal_error("routine outside of package");
		}
	}

	inter_name *block_iname = NULL;
	if (Packaging::housed_in_function(iname))
		block_iname = Packaging::make_iname_within(InterNames::location(iname), I"block");
	else internal_error("routine outside function package");
	inter_bookmark save_ib = Inter::Bookmarks::snapshot(Packaging::at());
	current_inter_routine = Produce::package(block_iname, PackageTypes::get(I"_code"));

//	current_inter_bookmark = Produce::bookmark();

	Produce::guard(Inter::Code::new(Packaging::at(),
		(int) Produce::baseline(Packaging::at()) + 1, NULL));

	begin_bookmark = Produce::bookmark();
	Inter::Bookmarks::set_placement(&begin_bookmark, IMMEDIATELY_AFTER_ICPLACEMENT);

	locals_bookmark = begin_bookmark;
	Inter::Bookmarks::set_placement(&locals_bookmark, BEFORE_ICPLACEMENT);

	code_bookmark = Produce::bookmark();
	code_insertion_point cip = Produce::new_cip(&code_bookmark);
	Produce::push_code_position(cip, save_ib);
	return current_inter_routine;
}

inter_name *Produce::kernel(inter_name *public_name) {
	if (Packaging::housed_in_function(public_name) == FALSE)
		internal_error("routine not housed in function");
	package_request *P = InterNames::location(public_name);
	inter_name *kernel_name = Packaging::make_iname_within(P, I"kernel");
	Produce::set_flag(kernel_name, MAKE_NAME_UNIQUE);
	return kernel_name;
}

void Produce::end_main_block(packaging_state save) {
	Packaging::exit(save);
}

void Produce::end_block(void) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	current_inter_routine = NULL;
	Produce::pop_code_position();
}

int Produce::emitting_routine(void) {
	if (current_inter_routine) return TRUE;
	return FALSE;
}

code_insertion_point Produce::begin_position(void) {
	code_insertion_point cip = Produce::new_cip(&begin_bookmark);
	return cip;
}

void Produce::push_code_position(code_insertion_point cip, inter_bookmark save_ib) {
	if (cip_sp >= MAX_CIP_STACK_SIZE) internal_error("CIP overflow");
	cip.saved_bm = save_ib;
	cip_stack[cip_sp++] = cip;
}

int Produce::level(void) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	return cip->inter_level;
}

void Produce::set_level(int N) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	if (N < 2) {
		if (problem_count == 0) cip->error_flag = TRUE;
		N = 2;
	}
	while (cip->noted_sp > 0) {
		if (cip->noted_levels[cip->noted_sp-1] < N) break;
		cip->noted_sp--;
	}
	cip->inter_level = N;
}

void Produce::note_level(inter_symbol *from) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	if (cip->noted_sp >= MAX_NESTED_NOTEWORTHY_LEVELS) return;
	cip->noted_levels[cip->noted_sp++] = Produce::level();
}

void Produce::to_last_level(int delta) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	if (cip->noted_sp <= 0) {
		if (problem_count == 0) cip->error_flag = TRUE;
	} else {
		Produce::set_level(cip->noted_levels[cip->noted_sp-1] + delta);
	}
}

inter_bookmark *Produce::at(void) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	return cip_stack[cip_sp-1].insertion_bm;
}

void Produce::down(void) {
	Produce::set_level(Produce::level() + 1);
}

void Produce::up(void) {
	Produce::set_level(Produce::level() - 1);
}

void Produce::pop_code_position(void) {
	if (cip_sp <= 0) internal_error("CIP underflow");
	if (cip_stack[cip_sp-1].error_flag) {
		internal_error("bad inter hierarchy");
	}
	*(Packaging::at()) = cip_stack[cip_sp-1].saved_bm;
	cip_sp--;
}

void Produce::inv_assembly(text_stream *opcode) {
	inter_t SID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Produce::at()));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), SID);
	Str::copy(glob_storage, opcode);
	Produce::guard(Inter::Inv::new_assembly(Produce::at(), SID, (inter_t) Produce::level(), NULL));
}


void Produce::inv_primitive(inter_symbol *prim_symb) {
	inter_t bip = Primitives::to_bip(Produce::tree(), prim_symb);
	if ((bip == SWITCH_BIP) ||
		(bip == IF_BIP) ||
		(bip == IFELSE_BIP) ||
		(bip == FOR_BIP) ||
		(bip == WHILE_BIP) ||
		(bip == DO_BIP) ||
		(bip == OBJECTLOOP_BIP)) Produce::note_level(prim_symb);

	Produce::guard(Inter::Inv::new_primitive(Produce::at(), prim_symb, (inter_t) Produce::level(), NULL));
}

void Produce::inv_call(inter_symbol *prim_symb) {
	Produce::guard(Inter::Inv::new_call(Produce::at(), prim_symb, (inter_t) Produce::level(), NULL));
}

void Produce::inv_call_iname(inter_name *iname) {
	inter_symbol *prim_symb = InterNames::to_symbol(iname);
	Produce::guard(Inter::Inv::new_call(Produce::at(), prim_symb, (inter_t) Produce::level(), NULL));
}

void Produce::inv_indirect_call(int arity) {
	switch (arity) {
		case 0: Produce::inv_primitive(Produce::opcode(INDIRECT0_BIP)); break;
		case 1: Produce::inv_primitive(Produce::opcode(INDIRECT1_BIP)); break;
		case 2: Produce::inv_primitive(Produce::opcode(INDIRECT2_BIP)); break;
		case 3: Produce::inv_primitive(Produce::opcode(INDIRECT3_BIP)); break;
		case 4: Produce::inv_primitive(Produce::opcode(INDIRECT4_BIP)); break;
		default: internal_error("indirect function call with too many arguments");
	}
}

void Produce::rtrue(void) {
	Produce::inv_primitive(Produce::opcode(RETURN_BIP));
	Produce::down();
		Produce::val(K_value, LITERAL_IVAL, 1); /* that is, return "true" */
	Produce::up();
}

void Produce::rfalse(void) {
	Produce::inv_primitive(Produce::opcode(RETURN_BIP));
	Produce::down();
		Produce::val(K_value, LITERAL_IVAL, 0); /* that is, return "false" */
	Produce::up();
}

void Produce::push(inter_name *iname) {
	Produce::inv_primitive(Produce::opcode(PUSH_BIP));
	Produce::down();
	Produce::val_iname(K_value, iname);
	Produce::up();
}

void Produce::pull(inter_name *iname) {
	Produce::inv_primitive(Produce::opcode(PULL_BIP));
	Produce::down();
	Produce::ref_iname(K_value, iname);
	Produce::up();
}

void Produce::val(kind *K, inter_t val1, inter_t val2) {
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for val");
	Produce::guard(Inter::Val::new(Produce::at(), val_kind, Produce::level(), val1, val2, NULL));
}

void Produce::val_nothing(void) {
	Produce::val(K_value, LITERAL_IVAL, 0);
}

void Produce::lab(inter_symbol *L) {
	Produce::guard(Inter::Lab::new(Produce::at(), L, (inter_t) Produce::level(), NULL));
}

inter_symbol *Produce::reserve_label(text_stream *lname) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	if (Str::get_first_char(lname) != '.') {
		TEMPORARY_TEXT(dotted);
		WRITE_TO(dotted, ".%S", lname);
		inter_symbol *lab_name = Produce::reserve_label(dotted);
		DISCARD_TEXT(dotted);
		return lab_name;
	}
	inter_symbol *lab_name = Produce::local_exists(lname);
	if (lab_name) return lab_name;
	lab_name = Produce::new_local_symbol(current_inter_routine, lname);
	Inter::Symbols::label(lab_name);
	return lab_name;
}

void Produce::place_label(inter_symbol *lab_name) {
	Produce::guard(Inter::Label::new(Produce::at(), lab_name, (inter_t) Produce::level(), NULL));
}

inter_symbol *Produce::local_exists(text_stream *lname) {
	return Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope(current_inter_routine), lname);
}

inter_symbol *Produce::seek_symbol(inter_symbols_table *T, text_stream *name) {
	return Inter::SymbolsTables::symbol_from_name(T, name);
}

text_stream *current_splat = NULL;

text_stream *Produce::begin_splat(void) {
	Produce::end_splat();
	if (current_splat == NULL) current_splat = Str::new();
	return current_splat;
}

void Produce::end_splat(void) {
	if (current_splat) {
		int L = Str::len(current_splat);
		if ((L > 1) ||
			((L == 1) && (Str::get_first_char(current_splat) != '\n'))) {
			Produce::entire_splat(current_splat, 0);
		}
		Str::clear(current_splat);
	}
}

void Produce::entire_splat(text_stream *content, inter_t level) {
	if (Str::len(content) == 0) return;
	inter_t SID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), SID);
	Str::copy(glob_storage, content);

	if (level > Produce::baseline(Packaging::at())) {
		Produce::guard(Inter::Splat::new(Produce::at(), SID, 0, level, 0, NULL));
	} else {
		Produce::guard(Inter::Splat::new(Packaging::at(), SID, 0, level, 0, NULL));
	}
}

void Produce::entire_splat_code(text_stream *content) {
	Produce::entire_splat(content, (inter_t) Produce::level());
}

void Produce::write_bytecode(filename *F) {
	if (Packaging::at() == NULL) internal_error("no inter repository");
	Inter::Binary::write(F, Produce::tree());
}

int glob_count = 0;

void Produce::glob_value(inter_t *v1, inter_t *v2, text_stream *glob, char *clue) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID);
	Str::copy(glob_storage, glob);
	*v1 = GLOB_IVAL;
	*v2 = ID;
	LOG("Glob (I7/%s): %S\n", clue, glob);
	glob_count++;
	internal_error("Reduced to glob in generation");
}

void Produce::text_value(inter_t *v1, inter_t *v2, text_stream *text) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	text_stream *text_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID);
	Str::copy(text_storage, text);
	*v1 = LITERAL_TEXT_IVAL;
	*v2 = ID;
}

int Produce::glob_count(void) {
	return glob_count;
}

void Produce::real_value(inter_t *v1, inter_t *v2, double g) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID);
	if (g > 0) WRITE_TO(glob_storage, "+");
	WRITE_TO(glob_storage, "%g", g);
	*v1 = REAL_IVAL;
	*v2 = ID;
}

void Produce::real_value_from_text(inter_t *v1, inter_t *v2, text_stream *S) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '$')
			PUT_TO(glob_storage, Str::get(pos));
	*v1 = REAL_IVAL;
	*v2 = ID;
}

void Produce::dword_value(inter_t *v1, inter_t *v2, text_stream *glob) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID);
	Str::copy(glob_storage, glob);
	*v1 = DWORD_IVAL;
	*v2 = ID;
}

void Produce::plural_dword_value(inter_t *v1, inter_t *v2, text_stream *glob) {
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Produce::tree()), Inter::Bookmarks::package(Packaging::at()));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Tree::warehouse(Produce::tree()), ID);
	Str::copy(glob_storage, glob);
	*v1 = PDWORD_IVAL;
	*v2 = ID;
}

void Produce::val_iname(kind *K, inter_name *iname) {
	if (iname == NULL) {
		if (problem_count == 0) internal_error("no iname");
		else Produce::val(K_value, LITERAL_IVAL, 0);
	} else {
		Produce::val_symbol(K, InterNames::to_symbol(iname));
	}
}

void Produce::val_symbol(kind *K, inter_symbol *s) {
	inter_t val1 = 0, val2 = 0;
	inter_bookmark *IBM = Packaging::at();
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), s, &val1, &val2);
	Produce::val(K, val1, val2);
}

void Produce::val_text(text_stream *S) {
	inter_t v1 = 0, v2 = 0;
	Produce::text_value(&v1, &v2, S);
	Produce::val(K_value, v1, v2);
}

void Produce::val_char(wchar_t c) {
	Produce::val(K_value, LITERAL_IVAL, (inter_t) c);
}

void Produce::val_real(double g) {
	inter_t v1 = 0, v2 = 0;
	Produce::real_value(&v1, &v2, g);
	Produce::val(K_value, v1, v2);
}

void Produce::val_real_from_text(text_stream *S) {
	inter_t v1 = 0, v2 = 0;
	Produce::real_value_from_text(&v1, &v2, S);
	Produce::val(K_value, v1, v2);
}

void Produce::val_dword(text_stream *S) {
	inter_t v1 = 0, v2 = 0;
	Produce::dword_value(&v1, &v2, S);
	Produce::val(K_value, v1, v2);
}

void Produce::ref(kind *K, inter_t val1, inter_t val2) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for ref");
	Produce::guard(Inter::Ref::new(Produce::at(), val_kind, Produce::level(), val1, val2, NULL));
}

void Produce::ref_iname(kind *K, inter_name *iname) {
	Produce::ref_symbol(K, InterNames::to_symbol(iname));
}

void Produce::ref_symbol(kind *K, inter_symbol *s) {
	inter_t val1 = 0, val2 = 0;
	inter_bookmark *IBM = Packaging::at();
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), s, &val1, &val2);
	Produce::ref(K, val1, val2);
}

inter_symbol *Produce::new_local_symbol(inter_package *rpack, text_stream *name) {
	return Inter::SymbolsTables::create_with_unique_name(Inter::Packages::scope(rpack), name);
}

inter_symbol *Produce::kind_to_symbol(kind *K) {
	#ifdef CORE_MODULE
	if (K == NULL) return unchecked_interk;
	if (K == K_value) return unchecked_interk; /* for error recovery */
	return InterNames::to_symbol(Kinds::RunTime::iname(K));
	#endif
	#ifndef CORE_MODULE
	inter_symbol *plug = Inter::Connectors::find_plug(Produce::tree(), I"K_unchecked");
	if (plug == NULL) plug = Inter::Connectors::plug(Produce::tree(), I"K_unchecked");
	return plug;
	#endif
}

inter_name *Produce::find_by_name(text_stream *name) {
	if (Str::len(name) == 0) internal_error("empty extern");
	inter_name *try = HierarchyLocations::find_by_name(name);
	if (try == NULL) {
		HierarchyLocations::con(-1, name, Translation::same(), HierarchyLocations::plug());
		try = HierarchyLocations::find_by_name(name);
	}
	return try;
}
