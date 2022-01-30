[InterPackage::] Packages.

To manage packages of inter code.

@h Introduction.
As noted in //What This Module Does//, the content in a tree is structured by
being placed in a nested hierarchy of boxes called "packages".

A package has a location in the tree defined by its |package_head| node: this
will be a |PACKAGE_IST| instruction. Every package has a name and a type. For
example, suppose we have:
= (text as Inter)
	A
	B
	package gadgets _paraphernalia          <-- package_head node
		symbol private misc ^is_electrical
		C
		D
		E
	F
	G
=
Here the Inter instructions C, D and E are the content of the package, which
is called "gadgets" and has the type |_paraphernalia|. Instructions A, B, F,
G , along with the |package| instruction, belong to the wider context. The
symbiol name |^is_electrical| is visible to C, D and E, but not to A, B, F,
and G: it belongs to the "scope" of the |gadgets| package, and is recorded
in its private symbols table.

The name |gadgets| is also a symbol but belongs to the wider scope (the A, B, ...
scope): it does not belong to the package's own symbols table, and in that
sense a package cannot see its own name.

@ Clearly a package involves more data than can be recorded in the |PACKAGE_IST|
instruction alone, so each package has a corresponding //inter_package// structure.
That structure is a resource belonging to the tree, so it's included in the
resource list of the tree's warehouse, and has a resource ID within it. See
//The Warehouse//.

=
typedef struct inter_package {
	struct inter_tree_node *package_head;
	struct inter_symbols_table *package_scope;
	inter_ti resource_ID;
	struct text_stream *package_name_t;
	int package_flags; /* a bitmap of the |*_PACKAGE_FLAG| bits */
	struct dictionary *name_lookup;
	CLASS_DEFINITION
} inter_package;

@ Do not call this directly to make a new package: it needs the resource ID |n|
to exist already, and that has to be allocated. So instead you could call
//InterWarehouse::create_package//, which calls this. But in fact what you
should really do is just to generate a |PACKAGE_IST| instruction, because
the package needs its head node too: everything will then automatically work.
See //InterPackage::new_package// for how to do that.

=
inter_package *InterPackage::new(inter_tree *I, inter_ti n) {
	inter_package *pack = CREATE(inter_package);
	pack->package_head = NULL;
	pack->package_scope = NULL;
	pack->package_flags = 0;
	pack->package_name_t = NULL;
	pack->resource_ID = n;
	pack->name_lookup = Dictionaries::new(INITIAL_INTER_SYMBOLS_ID_RANGE, FALSE);
	return pack;
}

@ //inter_package// structures and |PACKAGE_IST| instruction nodes correspond
to each other in a way which exactly matches, except for the root package.
For all other packages, these two operations are inverse to each other: 

(*) To get from a head node |H| to an |inter_package|, call //InterPackage::at_this_head//.
(*) To get from an |inter_package| |P| to a head node, call //InterPackage::head//.

The root package is a very special one-off case -- see //Inter Trees//: it
does not originate from any package instruction because it represents the
outermost box, that is, the top level of the hierarchy.

=
inter_tree_node *InterPackage::head(inter_package *pack) {
	if (pack == NULL) return NULL;
	if (InterPackage::is_a_root_package(pack)) return NULL;
	return pack->package_head;
}

@h Flags.
Packages with special behaviour are marked with flags. (Flags can also be used
as temporary markers when fooling with Inter code during pipeline processing.)

@d ROOT_PACKAGE_FLAG          1
@d FUNCTION_BODY_PACKAGE_FLAG 2
@d LINKAGE_PACKAGE_FLAG       4

@d USED_PACKAGE_FLAG          256
@d MARK_PACKAGE_FLAG          512

@ The |ROOT_PACKAGE_FLAG| is given only to the root package of a tree, so there
will only ever be one of these in any given tree.

=
int InterPackage::is_a_root_package(inter_package *pack) {
	if ((pack) && (pack->package_flags & ROOT_PACKAGE_FLAG)) return TRUE;
	return FALSE;
}

void InterPackage::mark_as_a_root_package(inter_package *pack) {
	if (pack) pack->package_flags |= ROOT_PACKAGE_FLAG;
}

@ The |FUNCTION_BODY_PACKAGE_FLAG| is given to function bodies. Note that the code
of each function always occupies a single package, which contains nothing else.
Subsidiary parts of the function -- what are called "code blocks" in C, like
loop bodies -- are not subpackages of this: a code package has no subpackages.

=
int InterPackage::is_a_function_body(inter_package *pack) {
	if ((pack) && (pack->package_flags & FUNCTION_BODY_PACKAGE_FLAG)) return TRUE;
	return FALSE;
}

void InterPackage::mark_as_a_function_body(inter_package *pack) {
	if (pack) pack->package_flags |= FUNCTION_BODY_PACKAGE_FLAG;
}

@ The |LINKAGE_PACKAGE_FLAG| is given only to a few top-level packages which
behave differently during the transmigration process used in linking trees
together. This is not the place to explain: see //building: Large-Scale Structure//.

=
int InterPackage::is_a_linkage_package(inter_package *pack) {
	if ((pack) && (pack->package_flags & LINKAGE_PACKAGE_FLAG)) return TRUE;
	return FALSE;
}

void InterPackage::mark_as_a_linkage_package(inter_package *pack) {
	if (pack) pack->package_flags |= LINKAGE_PACKAGE_FLAG;
}

@ |MARK_PACKAGE_FLAG| is ephemeral and typically used to mark that something
has already been done on a given package, so that it won't be done twice.
At the start of such a process, call this.

=
void InterPackage::unmark_all(void) {
	inter_package *pack;
	LOOP_OVER(pack, inter_package)
		InterPackage::clear_flag(pack, MARK_PACKAGE_FLAG);
}











inter_tree *default_ptree = NULL;

inter_tree *InterPackage::tree(inter_package *pack) {
	if (default_ptree) return default_ptree;
	if (pack == NULL) return NULL;
	return pack->package_head->tree;
}

text_stream *InterPackage::name(inter_package *pack) {
	if (pack == NULL) return NULL;
	return pack->package_name_t;
}

inter_package *InterPackage::parent(inter_package *pack) {
	if (pack) {
		if (InterPackage::is_a_root_package(pack)) return NULL;
		inter_tree_node *D = InterPackage::head(pack);
		inter_tree_node *P = InterTree::parent(D);
		if (P == NULL) return NULL;
		return InterPackage::at_this_head(P);
	}
	return NULL;
}

void InterPackage::set_scope(inter_package *P, inter_symbols_table *T) {
	if (P == NULL) internal_error("null package");
	P->package_scope = T;
	if (T) T->owning_package = P;
}

void InterPackage::set_name(inter_package *Q, inter_package *P, text_stream *N) {
	if (P == NULL) internal_error("null package");
	if (N == NULL) internal_error("null package name");
	P->package_name_t = Str::duplicate(N);
	if (Str::len(N) > 0) {
		LargeScale::note_package_name(InterPackage::tree(P), P, N);
		InterPackage::add_subpackage_name(Q, P);
	}
}

void InterPackage::add_subpackage_name(inter_package *Q, inter_package *P) {
	if (Q == NULL) internal_error("no parent supplied");
	text_stream *N = P->package_name_t;
	dict_entry *de = Dictionaries::find(Q->name_lookup, N);
	if (de) {
		LOG("This would be the second '%S' in $6\n", N, Q);
		internal_error("duplicated package name");
	}
	Dictionaries::create(Q->name_lookup, N);
	Dictionaries::write_value(Q->name_lookup, N, (void *) P);
}

void InterPackage::remove_subpackage_name(inter_package *Q, inter_package *P) {
	if (Q == NULL) internal_error("no parent supplied");
	text_stream *N = P->package_name_t;
	dict_entry *de = Dictionaries::find(Q->name_lookup, N);
	if (de) {
		Dictionaries::write_value(Q->name_lookup, N, NULL);
	}
}

void InterPackage::log(OUTPUT_STREAM, void *vp) {
	inter_package *pack = (inter_package *) vp;
	InterPackage::write_url_name(OUT, pack);
}

inter_package *InterPackage::basics(inter_tree *I) {
	return InterPackage::by_url(I, I"/main/generic/basics");
}

inter_symbol *InterPackage::search_exhaustively(inter_package *P, text_stream *S) {
	inter_symbol *found = InterSymbolsTables::symbol_from_name(InterPackage::scope(P), S);
	if (found) return found;
	inter_tree_node *D = InterPackage::head(P);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.instruction[ID_IFLD] == PACKAGE_IST) {
			inter_package *Q = InterPackage::at_this_head(C);
			found = InterPackage::search_exhaustively(Q, S);
			if (found) return found;
		}
	}
	return NULL;
}

inter_symbol *InterPackage::search_main_exhaustively(inter_tree *I, text_stream *S) {
	return InterPackage::search_exhaustively(LargeScale::main_package(I), S);
}

inter_symbol *InterPackage::search_resources(inter_tree *I, text_stream *S) {
	inter_package *main_package = LargeScale::main_package_if_it_exists(I);
	if (main_package) {
		inter_tree_node *D = InterPackage::head(main_package);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.instruction[ID_IFLD] == PACKAGE_IST) {
				inter_package *Q = InterPackage::at_this_head(C);
				inter_symbol *found = InterPackage::search_exhaustively(Q, S);
				if (found) return found;
			}
		}
	}
	return NULL;
}

inter_ti InterPackage::to_PID(inter_package *P) {
	if (P == NULL) return 0;
	return P->resource_ID;
}

inter_package *InterPackage::container(inter_tree_node *P) {
	if (P == NULL) return NULL;
	inter_package *pack = Inode::get_package(P);
	if (InterPackage::is_a_root_package(pack)) return NULL;
	return pack;
}

inter_symbols_table *InterPackage::scope(inter_package *pack) {
	if (pack == NULL) return NULL;
	return pack->package_scope;
}

inter_symbols_table *InterPackage::scope_of(inter_tree_node *P) {
	inter_package *pack = InterPackage::container(P);
	if (pack) return pack->package_scope;
	return Inode::globals(P);
}

int InterPackage::baseline(inter_package *P) {
	if (P == NULL) return 0;
	if (InterPackage::is_a_root_package(P)) return 0;
	return Inter::Defn::get_level(InterPackage::head(P));
}

void InterPackage::make_names_exist(inter_package *P) {
	while (P) P = InterPackage::parent(P);
}

void InterPackage::write_url_name(OUTPUT_STREAM, inter_package *P) {
	if (P == NULL) { WRITE("<none>"); return; }
	inter_package *chain[MAX_URL_SYMBOL_NAME_DEPTH];
	int chain_length = 0;
	while (P) {
		if (chain_length >= MAX_URL_SYMBOL_NAME_DEPTH) internal_error("package nesting too deep");
		chain[chain_length++] = P;
		P = InterPackage::parent(P);
	}
	for (int i=chain_length-1; i>=0; i--) WRITE("/%S", InterPackage::name(chain[i]));
}

int InterPackage::get_flag(inter_package *P, int f) {
	if (P == NULL) internal_error("no package");
	return (P->package_flags & f)?TRUE:FALSE;
}

void InterPackage::set_flag(inter_package *P, int f) {
	if (P == NULL) internal_error("no package");
	P->package_flags = P->package_flags | f;
}

void InterPackage::clear_flag(inter_package *P, int f) {
	if (P == NULL) internal_error("no package");
	if (P->package_flags & f) P->package_flags = P->package_flags - f;
}

inter_package *InterPackage::by_name(inter_package *P, text_stream *name) {
	if (P == NULL) return NULL;
	dict_entry *de = Dictionaries::find(P->name_lookup, name);
	if (de) return (inter_package *) Dictionaries::read_value(P->name_lookup, name);
	return NULL;
}

inter_package *InterPackage::by_url(inter_tree *I, text_stream *S) {
	if (Str::get_first_char(S) == '/') {
		inter_package *at_P = I->root_package;
		TEMPORARY_TEXT(C)
		LOOP_THROUGH_TEXT(P, S) {
			wchar_t c = Str::get(P);
			if (c == '/') {
				if (Str::len(C) > 0) {
					at_P = InterPackage::by_name(at_P, C);
					if (at_P == NULL) return NULL;
				}
				Str::clear(C);
			} else {
				PUT_TO(C, c);
			}
		}
		inter_package *pack = InterPackage::by_name(at_P, C);
		DISCARD_TEXT(C)
		return pack;
	}
	return InterPackage::by_name(I->root_package, S);
}
