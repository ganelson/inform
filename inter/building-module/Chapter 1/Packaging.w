[Packaging::] Packaging.

To manage requests to build Inter packages, and then to generate inames within
them; and to create modules and submodules.

@ The maximum here is beyond plenty: it's not the maximum hierarchical depth
of the Inter output, it's the maximum number of times that Inform interrupts
itself during compilation.

@d MAX_PACKAGING_ENTRY_DEPTH 128

=
typedef struct site_packaging_data {
	struct packaging_state current_state;
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
	struct inter_bookmark pragmas_bookmark;
	struct inter_bookmark package_types_bookmark;
} site_packaging_data;

void Packaging::clear_pdata(inter_tree *I) {
	building_site *B = &(I->site);
	B->spdata.current_state = Packaging::stateless();
	B->spdata.packaging_entry_sp = 0;
	for (int i=0; i<NO_DEFINED_HL_VALUES; i++) B->spdata.hls_indexed_by_id[i] = NULL;
	B->spdata.hls_indexed_by_name = Dictionaries::new(512, FALSE);
	for (int i=0; i<NO_DEFINED_HAP_VALUES; i++) B->spdata.haps_indexed_by_id[i] = NULL;
	Packaging::initialise_state(I);

	B->spdata.pragmas_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
	B->spdata.package_types_bookmark = Inter::Bookmarks::at_start_of_this_repository(I);
}

inter_bookmark *Packaging::pragmas(inter_tree *I) {
	return &(I->site.spdata.pragmas_bookmark);
}
void Packaging::set_pragmas(inter_tree *I, inter_bookmark IBM) {
	I->site.spdata.pragmas_bookmark = IBM;
}
inter_bookmark *Packaging::package_types(inter_tree *I) {
	return &(I->site.spdata.package_types_bookmark);
}
void Packaging::set_package_types(inter_tree *I, inter_bookmark IBM) {
	I->site.spdata.package_types_bookmark = IBM;
}

@h Package requests.
In the same way that inames are created as shadows of eventual inter symbols,
and omly converted into the real thing on demand, "package requests" are
shadowy packages. The process of turning them into real inter packages is
called "incarnation".

@d MAX_PRCS_AT_ONCE 11

=
typedef struct package_request {
	struct inter_tree *for_tree;
	struct inter_name *eventual_name;
	struct inter_symbol *eventual_type;
	struct inter_package *actual_package;
	struct package_request *parent_request;
	struct inter_bookmark write_position;
	struct linked_list *iname_generators; /* of |inter_name_generator| */
	CLASS_DEFINITION
} package_request;

@ =
package_request *Packaging::request(inter_tree *I, inter_name *name, inter_symbol *pt) {
	package_request *R = CREATE(package_request);
	R->for_tree = I;
	R->eventual_name = name;
	R->eventual_type = pt;
	R->actual_package = NULL;
	R->parent_request = InterNames::location(name);
	R->write_position = Inter::Bookmarks::at_start_of_this_repository(I);
	R->iname_generators = NULL;
	return R;
}

@ In the debugging log, package requests are printed in a form looking a
little like URLs, except that they run in the reverse order, innermost first
and outermost last: to make this more visually clear, backslashes rather
than forward slashes are used as dividers.

=
void Packaging::log(OUTPUT_STREAM, void *vR) {
	package_request *R = (package_request *) vR;
	if (R == NULL) LOG("<null-package>");
	else {
		int c = 0;
		while (R) {
			if (c++ > 0) LOG("\\");
			if (R->actual_package)
				LOG("%S", Inter::Packages::name(R->actual_package));
			else
				LOG("'%n'", R->eventual_name);
			R = R->parent_request;
		}
	}
}

@ The following allows a sequence of different inames to be generated inside a
package: for example, |Packaging::make_iname_within(R, I"acorn")| produces a
sequence of inames |acorn1|, |acorn2|, ..., as it's called over and over again.

=
inter_name *Packaging::make_iname_within(package_request *R, text_stream *what_for) {
	if (R == NULL) internal_error("no request");
	if (R->iname_generators == NULL)
		R->iname_generators = NEW_LINKED_LIST(inter_name_generator);

	inter_name_generator *gen;
	LOOP_OVER_LINKED_LIST(gen, inter_name_generator, R->iname_generators)
		if (Str::eq(what_for, gen->name_stem))
			return InterNames::generated_in(gen, -1, EMPTY_WORDING, R);

	gen = InterNames::multiple_use_generator(NULL, what_for, NULL);
	ADD_TO_LINKED_LIST(gen, inter_name_generator, R->iname_generators);
	return InterNames::generated_in(gen, -1, EMPTY_WORDING, R);
}

@ At any given time, emission of Inter is occurring to a particular position
(in some incarnated package) and in the context of a given enclosure. This
is summarised by the following state:

=
typedef struct packaging_state {
	struct inter_bookmark *saved_IRS;
	struct package_request *saved_enclosure;
} packaging_state;

@ It is not legal to write to the following state, which exists only to
initialise variables to neutral contents (and thus to avoid warnings
generated because clang is not able to prove that they will not be used
in an uninitialised state -- though in fact they will not).

=
packaging_state Packaging::stateless(void) {
	packaging_state PS;
	PS.saved_IRS = NULL;
	PS.saved_enclosure = NULL;
	return PS;
}

@ We will store the current state at all times in the building site:

=
inter_bookmark *Packaging::at(inter_tree *I) {
	return I->site.spdata.current_state.saved_IRS;
}

package_request *Packaging::enclosure(inter_tree *I) {
	return I->site.spdata.current_state.saved_enclosure;
}

@ States are intentionally very lightweight, and in particular they contain
pointers to the IBM structures rather than containing a copy thereof. But
those pointers have to point somewhere, and this is where: to a stack of
IBM structures.

=
inter_bookmark *Packaging::push_IRS(inter_tree *I, inter_bookmark IBM) {
	if (I->site.spdata.packaging_entry_sp >= MAX_PACKAGING_ENTRY_DEPTH)
		internal_error("packaging entry too deep");
	I->site.spdata.packaging_entry_stack[I->site.spdata.packaging_entry_sp] = IBM;
	return &(I->site.spdata.packaging_entry_stack[I->site.spdata.packaging_entry_sp++]);
}

void Packaging::pop_IRS(inter_tree *I) {
	if (I->site.spdata.packaging_entry_sp <= 0) internal_error("package stack underflow");
	I->site.spdata.packaging_entry_sp--;
}

@ The current state has the following invariant: the IBM part always points to
a validly initialised |inter_bookmark|, and the enclosure part is always
either |NULL| or a package request which has an enclosing package type. (In
fact, it is null only fleetingly: as soon as the |main| package is created,
very early on, the enclosure is always an enclosing package.)

=
void Packaging::initialise_state(inter_tree *I) {
	I->site.spdata.current_state.saved_IRS =
		Packaging::push_IRS(I, Inter::Bookmarks::at_start_of_this_repository(I));
	I->site.spdata.current_state.saved_enclosure = NULL;
}

void Packaging::set_state(inter_tree *I, inter_bookmark *to, package_request *PR) {
	I->site.spdata.current_state.saved_IRS = to;
	while ((PR) && (PR->parent_request) &&
		(Inter::Symbols::read_annotation(PR->eventual_type, ENCLOSING_IANN) != 1))
		PR = PR->parent_request;
	I->site.spdata.current_state.saved_enclosure = PR;
}

@h Bubbles.
Inter code is stored in memory as a singly-linked list. This is fast and
compact, but can make it awkward to insert material other than at the end,
particularly if one insertion leads to another close by, midway in the
process -- which is exactly what can happen when incarnating a nested set
of packages.

We avoid all such difficulties by placing "bubbles" at positions in the
linked list where we will later need to return and place new material.
A bubble is simply a pair of nops (no operations); any later inserted
material will be placed between them.

=
inter_bookmark Packaging::bubble(inter_tree *I) {
	Produce::nop(I);
	inter_bookmark b = Inter::Bookmarks::snapshot(Packaging::at(I));
	Produce::nop(I);
	return b;
}

inter_bookmark Packaging::bubble_at(inter_bookmark *IBM) {
	Produce::nop_at(IBM);
	inter_bookmark b = Inter::Bookmarks::snapshot(IBM);
	Produce::nop_at(IBM);
	return b;
}

@h Outside the packages.
The Inter specification calls for just a handful of resources to be placed
at the top level, outside even the |main| package. Using bubbles, we leave
room to insert those resources, then incarnate |main| and enter it.

=
void Packaging::outside_all_packages(inter_tree *I) {
	Packaging::initialise_state(I);
	Produce::version(I, 1);

	Produce::comment(I, I"Package types:");
	Packaging::set_package_types(I, Packaging::bubble(I));

	Produce::comment(I, I"Pragmas:");
	Packaging::set_pragmas(I, Packaging::bubble(I));

	Produce::comment(I, I"Primitives:");
	Primitives::declare_standard_set(I, Packaging::at(I));

	LargeScale::package_type(I, I"_plain"); // To ensure this is the first emitted ptype
	LargeScale::package_type(I, I"_code"); // And this the second
	LargeScale::package_type(I, I"_linkage"); // And this the third

	Packaging::enter(LargeScale::main_request(I)); // Which we never exit
}

@h Entry and exit.
Each PR contains a "write position". This is where emitted Inter code will go;
and it means that not all of the code inside a package needs to be written
at the same time. We can come and go as we please, adding code to packages
all over the hierarchy, simply by switching to the write position in the
package we wsnt to extend next.

That switching is called "entering" a package. Every entry must be followed
by a matching exit, which restores the write position to where it was before
the entry. (The one exception is that the entry into |main|, made above,
is never followed by an exit.)

=
packaging_state Packaging::enter_home_of(inter_name *N) {
	return Packaging::enter(InterNames::location(N));
}

packaging_state Packaging::enter(package_request *R) {
	LOGIF(PACKAGING, "Entering $X\n", R);
	packaging_state save = R->for_tree->site.spdata.current_state;
	Packaging::incarnate(R);
	Packaging::set_state(R->for_tree, &(R->write_position), Packaging::enclosure(R->for_tree));
	inter_bookmark *bubble = Packaging::push_IRS(R->for_tree, Packaging::bubble(R->for_tree));
	Packaging::set_state(R->for_tree, bubble, R);
	LOGIF(PACKAGING, "[%d] Current enclosure is $X\n", R->for_tree->site.spdata.packaging_entry_sp, Packaging::enclosure(R->for_tree));
	return save;
}

void Packaging::exit(inter_tree *I, packaging_state save) {
	Packaging::set_state(I, save.saved_IRS, save.saved_enclosure);
	Packaging::pop_IRS(I);
	LOGIF(PACKAGING, "[%d] Back to $X\n", I->site.spdata.packaging_entry_sp, Packaging::enclosure(I));
}

@h Incarnation.
The subtlety here is that if a package is incarnated, its parent must be
incarnated first, and we need to make sure that their bubbles do not lie
inside each other: if they did, material compiled to the parent and to the
child would end up interleaved, in a way which violates the Inter
specification.

=
inter_package *Packaging::incarnate(package_request *R) {
	if (R == NULL) internal_error("can't incarnate null request");
	if (R->actual_package == NULL) {
		LOGIF(PACKAGING, "Request to make incarnate $X\n", R);
		inter_tree *I = R->for_tree;
		package_request *E = Packaging::enclosure(I); // This will not change
		if (R->parent_request) {
			Packaging::incarnate(R->parent_request);
			inter_bookmark *save_IRS = Packaging::at(I);
			Packaging::set_state(I, &(R->parent_request->write_position), E);
			inter_bookmark package_bubble = Packaging::bubble(I);
			Packaging::set_state(I, &package_bubble, E);
			R->actual_package = Produce::package(I, R->eventual_name, R->eventual_type);
			R->write_position = Packaging::bubble(I);
			Packaging::set_state(I, save_IRS, E);
		} else {
			inter_bookmark package_bubble = Packaging::bubble(I);
			package_bubble = Packaging::bubble(I);
			inter_bookmark *save_IRS = Packaging::at(I);
			Packaging::set_state(I, &package_bubble, E);
			R->actual_package = Produce::package(I, R->eventual_name, R->eventual_type);
			R->write_position = Packaging::bubble(I);
			Packaging::set_state(I, save_IRS, E);
		}
		LOGIF(PACKAGING, "Made incarnate $X bookmark $5\n", R, &(R->write_position));
	}
	return R->actual_package;
}

@h Functions.
Inter code has a standard layout for functions: an outer, enclosing, package of type
|_function|, inside which is an iname |call| for the actual code to call. All such
functions are produced by the following routines:

=
inter_name *Packaging::function(inter_tree *I, inter_name *function_iname, inter_name *temp_iname) {
	package_request *P = Packaging::request(I, function_iname, LargeScale::package_type(I, I"_function"));
	inter_name *iname = InterNames::explicitly_named(I"call", P);
	if (temp_iname) {
		TEMPORARY_TEXT(T)
		WRITE_TO(T, "%n", temp_iname);
		Produce::change_translation(iname, T);
		DISCARD_TEXT(T)
	}
	return iname;
}

inter_name *Packaging::function_text(inter_tree *I, inter_name *function_iname, text_stream *translation) {
	package_request *P = Packaging::request(I, function_iname, LargeScale::package_type(I, I"_function"));
	inter_name *iname = InterNames::explicitly_named(I"call", P);
	if (translation)
		Produce::change_translation(iname, translation);
	return iname;
}

int Packaging::housed_in_function(inter_tree *I, inter_name *iname) {
	if (iname == NULL) return FALSE;
	package_request *P = InterNames::location(iname);
	if (P == NULL) return FALSE;
	if (P->eventual_type == LargeScale::package_type(I, I"_function")) return TRUE;
	return FALSE;
}

@ Datum is very similar.

=
inter_name *Packaging::datum_text(inter_tree *I, inter_name *function_iname, text_stream *translation) {
	package_request *P = Packaging::request(I, function_iname, LargeScale::package_type(I, I"_data"));
	inter_name *iname = InterNames::explicitly_named(translation, P);
	return iname;
}
