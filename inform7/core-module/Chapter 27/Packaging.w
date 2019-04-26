[Packaging::] Packaging.

To manage requests to build Inter packages, and then to generate inames within
them; and to create modules and submodules.

@h Package requests.
In the same way that inames are created as shadows of eventual inter symbols,
and omly converted into the real thing on demand, "package requests" are
shadowy packages. The process of turning them into real inter packages is
called "incarnation".

@d MAX_PRCS_AT_ONCE 11

=
typedef struct package_request {
	struct inter_name *eventual_name;
	struct inter_symbol *eventual_type;
	struct inter_package *actual_package;
	struct package_request *parent_request;
	struct inter_reading_state write_position;
	struct linked_list *iname_generators; /* of |inter_name_generator| */
	MEMORY_MANAGEMENT
} package_request;

@ =
package_request *Packaging::request(inter_name *name, inter_symbol *pt) {
	package_request *R = CREATE(package_request);
	R->eventual_name = name;
	R->eventual_type = pt;
	R->actual_package = NULL;
	R->parent_request = InterNames::location(name);
	R->write_position = Inter::Bookmarks::new_IRS(Emit::repository());
	R->iname_generators = NULL;
	return R;
}

@ In the debugging log, package requests are printed in a form looking a
little like URLs, except that they run in the reverse order, innermost first
and outermost last: to make this more visually clear, backslashes rather
than forward slashes are used as dividers.

=
void Packaging::log(package_request *R) {
	if (R == NULL) LOG("<null-package>");
	else {
		int c = 0;
		while (R) {
			if (c++ > 0) LOG("\\");
			if (R->actual_package)
				LOG("%S", R->actual_package->package_name->symbol_name);
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
	inter_reading_state *saved_IRS;
	package_request *saved_enclosure;
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

@ We will store the current state at all times in the following:

=
packaging_state current_state;

inter_reading_state *Packaging::at(void) {
	return current_state.saved_IRS;
}

package_request *Packaging::enclosure(void) {
	return current_state.saved_enclosure;
}

@ States are intentionally very lightweight, and in particular they contain
pointers to the IRS structures rather than containing a copy thereof. But
those pointers have to point somewhere, and this is where: to a stack of
IRS structures.

The maximum here is beyond plenty: it's not the maximum hierarchical depth
of the Inter output, it's the maximum number of times that Inform interrupts
itself during compilation.

@d MAX_PACKAGING_ENTRY_DEPTH 128

=
int packaging_entry_sp = 0;
inter_reading_state packaging_entry_stack[MAX_PACKAGING_ENTRY_DEPTH];

inter_reading_state *Packaging::push_IRS(inter_reading_state IRS) {
	if (packaging_entry_sp >= MAX_PACKAGING_ENTRY_DEPTH)
		internal_error("packaging entry too deep");
	packaging_entry_stack[packaging_entry_sp] = IRS;
	return &(packaging_entry_stack[packaging_entry_sp++]);
}

void Packaging::pop_IRS(void) {
	if (packaging_entry_sp <= 0) internal_error("package stack underflow");
	packaging_entry_sp--;
}

@ The current state has the following invariant: the IRS part always points to
a validly initialised |inter_reading_state|, and the enclosure part is always
either |NULL| or a package request which has an enclosing package type. (In
fact, it is null only fleetingly: as soon as the |main| package is created,
very early on, the enclosure is always an enclosing package.)

=
void Packaging::initialise_state(inter_repository *I) {
	current_state.saved_IRS = Packaging::push_IRS(Inter::Bookmarks::new_IRS(I));
	current_state.saved_enclosure = NULL;
}

void Packaging::set_state(inter_reading_state *to, package_request *PR) {
	current_state.saved_IRS = to;
	while ((PR) && (PR->parent_request) &&
		(Inter::Symbols::read_annotation(PR->eventual_type, ENCLOSING_IANN) != 1))
		PR = PR->parent_request;
	current_state.saved_enclosure = PR;
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
inter_reading_state Packaging::bubble(void) {
	Emit::nop();
	inter_reading_state b = Emit::bookmark();
	Emit::nop();
	return b;
}

@h Outside the packages.
The Inter specification calls for just a handful of resources to be placed
at the top level, outside even the |main| package. Using bubbles, we leave
room to insert those resources, then incarnate |main| and enter it.

=
inter_reading_state pragmas_bookmark;
inter_reading_state package_types_bookmark;
inter_reading_state holdings_bookmark;

void Packaging::outside_all_packages(void) {
	Emit::version(1);

	Emit::comment(I"Package types:");
	package_types_bookmark = Packaging::bubble();
	PackageTypes::get(I"_plain"); // To ensure this is the first emitted ptype
	PackageTypes::get(I"_code"); // And this the second

	Emit::comment(I"Pragmas:");
	pragmas_bookmark = Packaging::bubble();

	Emit::comment(I"Primitives:");
	Primitives::emit(Emit::repository(), Packaging::at());

	Packaging::enter(Hierarchy::main()); // Which we never exit
	holdings_bookmark = Packaging::bubble();
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
	packaging_state save = current_state;
	Packaging::incarnate(R);
	Packaging::set_state(&(R->write_position), Packaging::enclosure());
	inter_reading_state *bubble = Packaging::push_IRS(Packaging::bubble());
	Packaging::set_state(bubble, R);
	LOGIF(PACKAGING, "[%d] Current enclosure is $X\n", packaging_entry_sp, Packaging::enclosure());
	return save;
}

void Packaging::exit(packaging_state save) {
	Packaging::set_state(save.saved_IRS, save.saved_enclosure);
	Packaging::pop_IRS();
	LOGIF(PACKAGING, "[%d] Back to $X\n", packaging_entry_sp, Packaging::enclosure());
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
		package_request *E = Packaging::enclosure(); // This will not change
		if (R->parent_request) {
			Packaging::incarnate(R->parent_request);
			inter_reading_state *save_IRS = Packaging::at();
			Packaging::set_state(&(R->parent_request->write_position), E);
			inter_reading_state package_bubble = Packaging::bubble();
			Packaging::set_state(&package_bubble, E);
			Emit::package(R->eventual_name, R->eventual_type, &(R->actual_package));
			R->write_position = Packaging::bubble();
			Packaging::set_state(save_IRS, E);
		} else {
			inter_reading_state package_bubble = Packaging::bubble();
			inter_reading_state *save_IRS = Packaging::at();
			Packaging::set_state(&package_bubble, E);
			Emit::package(R->eventual_name, R->eventual_type, &(R->actual_package));
			R->write_position = Packaging::bubble();
			Packaging::set_state(save_IRS, E);
		}
		LOGIF(PACKAGING, "Made incarnate $X bookmark $5\n", R, &(R->write_position));
	}
	return R->actual_package;
}

@h Modules.
With the code above, then, we can get the Inter hierarchy of packages set up
as far as creating |main|. After that the Hierarchy code takes over, but it
calls the routines below to assist. It will want to create a number of "modules"
and, within them, "submodules".

Modules are identified by name: |generic|, |Standard_Rules|, and so on. The
following creates modules on demand.

=
dictionary *modules_indexed_by_name = NULL;
int modules_created = FALSE;

typedef struct module_package {
	struct package_request *the_package;
	struct linked_list *submodules; /* of |submodule_request| */
	MEMORY_MANAGEMENT
} module_package;

module_package *Packaging::get_module(text_stream *name) {
	if (modules_created == FALSE) {
		modules_created = TRUE;
		modules_indexed_by_name = Dictionaries::new(512, FALSE);
	}
	if (Dictionaries::find(modules_indexed_by_name, name))
		return (module_package *) Dictionaries::read_value(modules_indexed_by_name, name);
	
	module_package *new_module = CREATE(module_package);
	new_module->the_package =
		Packaging::request(
			InterNames::explicitly_named(name, Hierarchy::main()),
			PackageTypes::get(I"_module"));
	new_module->submodules = NEW_LINKED_LIST(submodule_request);
	Dictionaries::create(modules_indexed_by_name, name);
	Dictionaries::write_value(modules_indexed_by_name, name, (void *) new_module);
	return new_module;
}

@h Submodules.
Submodules have names such as |properties|, and the idea is that the same submodule
(or rather, submodules with the same name) can be found in multiple modules. The
different sorts of submodule are identified by |submodule_identity| pointers, though
as it turns out, this is presently just a wrapper for a name.

=
typedef struct submodule_identity {
	struct text_stream *submodule_name;
	MEMORY_MANAGEMENT
} submodule_identity;

submodule_identity *Packaging::register_submodule(text_stream *name) {
	submodule_identity *sid = CREATE(submodule_identity);
	sid->submodule_name = Str::duplicate(name);
	return sid;
}

@ Once the Hierarchy code has registered a submodule, it can request an existing
module to have this submodule. It should call one of the following four functions:

=
package_request *Packaging::request_submodule(compilation_module *C, submodule_identity *sid) {
	if (C == NULL) return Packaging::generic_submodule(sid);
	return Packaging::new_submodule_inner(Modules::inter_presence(C), sid);
}

package_request *Packaging::local_submodule(submodule_identity *sid) {
	return Packaging::request_submodule(Modules::find(current_sentence), sid);
}

package_request *Packaging::generic_submodule(submodule_identity *sid) {
	return Packaging::new_submodule_inner(Packaging::get_module(I"generic"), sid);
}

package_request *Packaging::synoptic_submodule(submodule_identity *sid) {
	return Packaging::new_submodule_inner(Packaging::get_module(I"synoptic"), sid);
}

@ Those in turn all make use of this back-end function:

=
typedef struct submodule_request {
	struct submodule_identity *which_submodule;
	struct package_request *where_found;
	MEMORY_MANAGEMENT
} submodule_request;

package_request *Packaging::new_submodule_inner(module_package *M, submodule_identity *sid) {
	submodule_request *sr;
	LOOP_OVER_LINKED_LIST(sr, submodule_request, M->submodules)
		if (sid == sr->which_submodule)
			return sr->where_found;
	inter_name *iname = InterNames::explicitly_named(sid->submodule_name, M->the_package);
	sr = CREATE(submodule_request);
	sr->which_submodule = sid;
	sr->where_found = Packaging::request(iname, PackageTypes::get(I"_submodule"));
	ADD_TO_LINKED_LIST(sr, submodule_request, M->submodules);
	return sr->where_found;
}

@h Functions.
Inter code has a standard layout for functions: an outer, enclosing, package of type
|_function|, inside which is an iname |call| for the actual code to call. All such
functions are produced by the following routines:

=
inter_name *Packaging::function(inter_name *function_iname, inter_name *temp_iname) {
	package_request *P = Packaging::request(function_iname, PackageTypes::function());
	inter_name *iname = InterNames::explicitly_named(I"call", P);
	if (temp_iname) {
		TEMPORARY_TEXT(T);
		WRITE_TO(T, "%n", temp_iname);
		Emit::change_translation(iname, T);
		DISCARD_TEXT(T);
	}
	return iname;
}

inter_name *Packaging::function_text(inter_name *function_iname, text_stream *translation) {
	package_request *P = Packaging::request(function_iname, PackageTypes::function());
	inter_name *iname = InterNames::explicitly_named(I"call", P);
	if (translation)
		Emit::change_translation(iname, translation);
	return iname;
}

int Packaging::housed_in_function(inter_name *iname) {
	if (iname == NULL) return FALSE;
	package_request *P = InterNames::location(iname);
	if (P == NULL) return FALSE;
	if (P->eventual_type == PackageTypes::function()) return TRUE;
	return FALSE;
}

@ Datum is very similar.

=
inter_name *Packaging::datum_text(inter_name *function_iname, text_stream *translation) {
	package_request *P = Packaging::request(function_iname, PackageTypes::get(I"_data"));
	inter_name *iname = InterNames::explicitly_named(translation, P);
	return iname;
}
