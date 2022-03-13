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
G , along with the |package| instruction itself, belong to the wider context. The
symbiol name |^is_electrical| is visible to C, D and E, but not to A, B, F,
and G: it belongs to the "scope" of the |gadgets| package, and is recorded
in its private symbols table.

Note that the package head node is outside the package. So although the name
|gadgets| is also a symbol, it belongs to the wider scope (the A, B, ...
scope): it does not appear in the package's own symbols table, and in that
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
	int package_flags; /* a bitmap of the |*_PACKAGE_FLAG| bits */
	inter_ti resource_ID; /* within the warehouse for the tree holding the package */
	CLASS_DEFINITION
} inter_package;

@ Do not call this directly to make a new package: it needs the resource ID |n|
to exist already, and that has to be allocated. So instead you could call
//InterWarehouse::create_package//, which calls this. But in fact what you
should really do is just to generate a |PACKAGE_IST| instruction, because
the package needs its head node too: everything will then automatically work.
See //PackageInstruction::new// for how to do that.

=
inter_package *InterPackage::new(inter_tree *I, inter_ti n) {
	inter_package *pack = CREATE(inter_package);
	pack->package_head = NULL;
	pack->package_scope = NULL;
	pack->package_flags = 0;
	pack->resource_ID = n;
	return pack;
}

inter_ti InterPackage::warehouse_ID(inter_package *pack) {
	if (pack == NULL) return 0;
	return pack->resource_ID;
}

@ //inter_package// structures and |PACKAGE_IST| instruction nodes correspond
to each other in a way which exactly matches, except for the root package.
For all other packages, these two operations are inverse to each other: 

(*) To get from a head node to its package, call //PackageInstruction::at_this_head//.
(*) To get from a package to its head node, call //InterPackage::head//.

The root package is a very special one-off case -- see //Inter Trees//: it
does not originate from any package instruction because it represents the
outermost box, that is, the top level of the hierarchy.

=
inter_tree_node *InterPackage::head(inter_package *pack) {
	if (pack == NULL) return NULL;
	if (InterPackage::is_a_root_package(pack)) return NULL;
	return pack->package_head;
}

inter_tree *InterPackage::tree(inter_package *pack) {
	if (pack == NULL) return NULL;
	return pack->package_head->tree;
}

@ The following function relies on an important rule of the road: that the
parent node of a package head node must be another package head node (except
of course at the very top of the tree).

It follows that we can get from a package to its next outermost package (its
"parent") by taking its head node, taking the node-parent of that, and then
finding the package with that head.

=
inter_package *InterPackage::parent(inter_package *pack) {
	if (pack) {
		if (InterPackage::is_a_root_package(pack)) return NULL;
		inter_tree_node *D = InterPackage::head(pack);
		inter_tree_node *P = InterTree::parent(D);
		if (P == NULL) return NULL;
		return PackageInstruction::at_this_head(P);
	}
	return NULL;
}

@ The baseline level for a package is the level in the hierarchy of its root
node, or is 0 for the root package.

=
int InterPackage::baseline(inter_package *P) {
	if (P == NULL) return 0;
	if (InterPackage::is_a_root_package(P)) return 0;
	return Inode::get_level(InterPackage::head(P));
}

@h Naming.
The name of a package is by definition the name of its symbol, which can be
extracted from the bytecode of its |package| instruction, stored at the head-node.
(And the root package, which has no head-node, has the empty name.)

=
text_stream *InterPackage::name(inter_package *pack) {
	if (pack) {
		inter_symbol *S = PackageInstruction::name_symbol(pack);
		if (S) return InterSymbol::identifier(S);
	}
	return NULL;
}

@h Type.

=
inter_symbol *InterPackage::type(inter_package *pack) {
	if (pack == NULL) return NULL;
	inter_tree_node *D = pack->package_head;
	return PackageInstruction::get_type_of(Inode::tree(D), D);
}

@h Scope.
The symbols table of local names within scope for the package.

=
void InterPackage::set_scope(inter_package *P, inter_symbols_table *T) {
	if (P == NULL) internal_error("null package");
	P->package_scope = T;
	if (T) T->owning_package = P;
}

@ This function is the inverse of //InterSymbolsTable::package//:

=
inter_symbols_table *InterPackage::scope(inter_package *pack) {
	if (pack == NULL) return NULL;
	return pack->package_scope;
}

@ The following searches recursively: i.e., not just the package's scope, but
also the scope of all its subpackages. This is a slow operation, but there is
no need for it to be fast: it is used only very sparingly.

=
inter_symbol *InterPackage::find_symbol_slowly(inter_package *P, text_stream *S) {
	inter_symbol *found = InterSymbolsTable::symbol_from_name(InterPackage::scope(P), S);
	if (found) return found;
	inter_tree_node *D = InterPackage::head(P);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (Inode::is(C, PACKAGE_IST)) {
			inter_package *Q = PackageInstruction::at_this_head(C);
			found = InterPackage::find_symbol_slowly(Q, S);
			if (found) return found;
		}
	}
	return NULL;
}

@h Packages as containers.
For any node, the innermost package containing that node is called its
"container"; but this is null at the root of the tree, i.e., it is never
equal to the special root package.

=
inter_package *InterPackage::container(inter_tree_node *P) {
	if (P == NULL) return NULL;
	inter_package *pack = Inode::get_package(P);
	if (InterPackage::is_a_root_package(pack)) return NULL;
	return pack;
}

inter_symbols_table *InterPackage::scope_of(inter_tree_node *P) {
	inter_package *pack = InterPackage::container(P);
	if (pack) return pack->package_scope;
	return Inode::globals(P);
}

@h Flags.
Packages with special behaviour are marked with flags. (Flags can also be used
as temporary markers when fooling with Inter code during pipeline processing.)

@d ROOT_PACKAGE_FLAG          1
@d FUNCTION_BODY_PACKAGE_FLAG 2
@d LINKAGE_PACKAGE_FLAG       4

@d PERSISTENT_PACKAGE_FLAGS   255

@d USED_PACKAGE_FLAG          256
@d MARK_PACKAGE_FLAG          512

=
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

@ These are used when reading and writing binary Inter files: because of course
the data in the flags must persist when files are written out and read back again.

=
int InterPackage::get_persistent_flags(inter_package *P) {
	if (P == NULL) internal_error("no package");
	return P->package_flags & PERSISTENT_PACKAGE_FLAGS;
}

void InterPackage::set_persistent_flags(inter_package *P, int x) {
	if (P == NULL) internal_error("no package");
	P->package_flags =
		(P->package_flags & (~PERSISTENT_PACKAGE_FLAGS)) | (x & PERSISTENT_PACKAGE_FLAGS);
}

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

@h Subpackages and URLs.
A package is uniquely identifiable (within its tree) by its textual URL, in the
form |/main/whatever/example1/this|. The following goes from an //inter_package//
to its URL, which is particularly handy for the debugging log:

=
void InterPackage::write_URL(OUTPUT_STREAM, inter_package *P) {
	if (P == NULL) { WRITE("<none>"); return; }
	inter_package *chain[MAX_URL_SYMBOL_NAME_DEPTH];
	int chain_length = 0;
	while (P) {
		if (chain_length >= MAX_URL_SYMBOL_NAME_DEPTH)
			internal_error("package nesting too deep");
		chain[chain_length++] = P;
		P = InterPackage::parent(P);
	}
	for (int i=chain_length-1; i>=0; i--) WRITE("/%S", InterPackage::name(chain[i]));
}

void InterPackage::log(OUTPUT_STREAM, void *vp) {
	inter_package *pack = (inter_package *) vp;
	InterPackage::write_URL(OUT, pack);
}

@ The other direction, parsing a URL into its corresponding //inter_package//, is
necessarily slower, and we perform it as little as possible. The following looks
for a subpackage called |name| within the parent package |P|:

=
inter_package *InterPackage::from_name(inter_package *P, text_stream *name) {
	if (P == NULL) return NULL;
	if (P == P->package_head->tree->root_package) {
		if (Str::eq(name, I"main"))
			return LargeScale::main_package_if_it_exists(P->package_head->tree);
	} else {
		inter_symbol *S = InterSymbolsTable::symbol_from_name_not_following(
			P->package_scope, name);
		if (S) return PackageInstruction::at_this_head(S->definition);
	}
	return NULL;
}

@ And that is the key tool needed for the following. Note that if there is an
initial slash, the URL is absolute, with respect to the top of the tree; and
otherwise it is construed as a single name. (So searching for |this/that|
could never succeed: without the initial slash, this would have to be the name
of a single package, and slashes can't be part of package names.)

=
inter_package *InterPackage::from_URL(inter_tree *I, text_stream *S) {
	if (Str::get_first_char(S) == '/') {
		inter_package *at_P = I->root_package;
		TEMPORARY_TEXT(C)
		LOOP_THROUGH_TEXT(P, S) {
			wchar_t c = Str::get(P);
			if (c == '/') {
				if (Str::len(C) > 0) {
					at_P = InterPackage::from_name(at_P, C);
					if (at_P == NULL) return NULL;
				}
				Str::clear(C);
			} else {
				PUT_TO(C, c);
			}
		}
		inter_package *pack = InterPackage::from_name(at_P, C);
		DISCARD_TEXT(C)
		return pack;
	}
	return InterPackage::from_name(I->root_package, S);
}
