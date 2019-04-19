[Packaging::] Packaging.

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
	struct linked_list *counters; /* of |submodule_request_counter| */
	MEMORY_MANAGEMENT
} package_request;

typedef struct submodule_request_counter {
	int counter_id;
	int counter_value;
	MEMORY_MANAGEMENT
} submodule_request_counter;

@ =
package_request *Packaging::request(inter_name *name, inter_symbol *pt) {
	package_request *R = CREATE(package_request);
	R->eventual_name = name;
	R->eventual_type = pt;
	R->actual_package = NULL;
	R->parent_request = InterNames::location(name);
	R->write_position = Inter::Bookmarks::new_IRS(Emit::repository());
	R->counters = NULL;
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

@h State, entry and exit.
PRs continue to be useful even after incarnation, though, because each one
also contains a "write position". This is where emitted Inter code will go;
and it means that not all of the code inside a package needs to be written
at the same time. We can come and go as we please, adding code to packages
all over the hierarchy, simply by switching to the write position in the
package we wsnt to extend next.

That switching is called "entering" a package. Every entry must be followed
by a matching exit, which restores the write position to where it was before
the entry. To restore state we need a way to record it, so:

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

@ The "current enclosure" ceases to be null the moment the |main| package
is created, and from then on, it is always an enclosing package:

=
void Packaging::initialise_IRS(inter_repository *I) {
	current_state.saved_IRS = Packaging::push_IRS(Inter::Bookmarks::new_IRS(I));
	current_state.saved_enclosure = NULL;
}

void Packaging::set_packaging_state(inter_reading_state *to, package_request *PR) {
	current_state.saved_IRS = to;
	while ((PR) && (PR->parent_request) &&
		(Inter::Symbols::read_annotation(PR->eventual_type, ENCLOSING_IANN) != 1))
		PR = PR->parent_request;
	current_state.saved_enclosure = PR;
}

void Packaging::move_write_position(inter_reading_state *to) {
	Packaging::set_packaging_state(to, Packaging::enclosure());
}

packaging_state Packaging::enter_home_of(inter_name *N) {
	return Packaging::enter(InterNames::location(N));
}

packaging_state Packaging::enter(package_request *R) {
	if (R == NULL) R = Hierarchy::main();
	LOGIF(PACKAGING, "Entering $X\n", R);
	packaging_state save = current_state;
	Packaging::incarnate(R);
	Packaging::set_packaging_state(&(R->write_position), Packaging::enclosure());
	inter_reading_state *bubble = Packaging::push_IRS(Emit::bookmark_bubble());
	Packaging::set_packaging_state(bubble, R);
	LOGIF(PACKAGING, "[%d] Current enclosure is $X\n", packaging_entry_sp, Packaging::enclosure());
	return save;
}

void Packaging::exit(packaging_state save) {
	Packaging::set_packaging_state(save.saved_IRS, save.saved_enclosure);
	Packaging::pop_IRS();
	LOGIF(PACKAGING, "[%d] Back to $X\n", packaging_entry_sp, Packaging::enclosure());
}

@h Incarnation.

=
inter_package *Packaging::incarnate(package_request *R) {
	if (R == NULL) internal_error("can't incarnate null request");
	if (R->actual_package == NULL) {
		LOGIF(PACKAGING, "Request to make incarnate $X\n", R);
		package_request *E = Packaging::enclosure(); // This will not change
		if (R->parent_request) {
			Packaging::incarnate(R->parent_request);
			inter_reading_state *save_IRS = Packaging::at();
			Packaging::set_packaging_state(&(R->parent_request->write_position), E);
			inter_reading_state snapshot = Emit::bookmark_bubble();
			Packaging::set_packaging_state(&snapshot, E);
			Emit::package(R->eventual_name, R->eventual_type, &(R->actual_package));
			R->write_position = Emit::bookmark_bubble();
			Packaging::set_packaging_state(save_IRS, E);
		} else {
			inter_reading_state snapshot = Emit::bookmark_bubble();
			inter_reading_state *save_IRS = Packaging::at();
			Packaging::set_packaging_state(&snapshot, E);
			Emit::package(R->eventual_name, R->eventual_type, &(R->actual_package));
			R->write_position = Emit::bookmark_bubble();
			Packaging::set_packaging_state(save_IRS, E);
		}
		LOGIF(PACKAGING, "Made incarnate $X bookmark $5\n", R, &(R->write_position));
	}
	return R->actual_package;
}

inter_symbols_table *Packaging::scope(inter_repository *I, inter_name *N) {
	if (N == NULL) internal_error("can't determine scope of null name");
	package_request *P = InterNames::location(N);
	if (P == NULL) return Inter::get_global_symbols(Emit::repository());
	return Inter::Packages::scope(Packaging::incarnate(P));
}

@ =
package_request *generic_pr = NULL;
package_request *Packaging::request_generic(void) {
	if (generic_pr == NULL)
		generic_pr = Packaging::request(
			InterNames::explicitly_named(I"generic", Hierarchy::resources()),
			PackageTypes::get(I"_module"));
	return generic_pr;
}

package_request *synoptic_pr = NULL;
package_request *Packaging::request_synoptic(void) {
	if (synoptic_pr == NULL)
		synoptic_pr = Packaging::request(
			InterNames::explicitly_named(I"synoptic", Hierarchy::resources()),
			PackageTypes::get(I"_module"));
	return synoptic_pr;
}

typedef struct submodule_identity {
	struct text_stream *submodule_name;
	MEMORY_MANAGEMENT
} submodule_identity;

submodule_identity *Packaging::register_submodule(text_stream *name) {
	submodule_identity *sid = CREATE(submodule_identity);
	sid->submodule_name = Str::duplicate(name);
	return sid;
}


typedef struct submodule_request {
	struct submodule_identity *which_submodule;
	struct package_request *where_found;
	MEMORY_MANAGEMENT
} submodule_request;

typedef struct submodule_requests {
	struct linked_list *submodules; /* of |submodule_identity| */
} submodule_requests;

package_request *Packaging::resources_for_new_submodule(text_stream *name, submodule_requests *SR) {
	inter_name *package_iname = InterNames::explicitly_named(name, Hierarchy::resources());
	package_request *P = Packaging::request(package_iname, PackageTypes::get(I"_module"));
	Packaging::initialise_submodules(SR);
	return P;
}

void Packaging::initialise_submodules(submodule_requests *SR) {
	SR->submodules = NEW_LINKED_LIST(submodule_request);
}

int generic_subpackages_initialised = FALSE;
submodule_requests generic_subpackages;
int synoptic_subpackages_initialised = FALSE;
submodule_requests synoptic_subpackages;

package_request *Packaging::request_resource(compilation_module *C, submodule_identity *sid) {
	submodule_requests *SR = NULL;
	package_request *parent = NULL;
	if (C) {
		SR = Modules::subpackages(C);
		parent = C->resources;
	} else {
		if (generic_subpackages_initialised == FALSE) {
			generic_subpackages_initialised = TRUE;
			Packaging::initialise_submodules(&generic_subpackages);
		}
		SR = &generic_subpackages;
		parent = Packaging::request_generic();
	}
	@<Handle the resource request@>;
}

package_request *Packaging::local_resource(submodule_identity *sid) {
	return Packaging::request_resource(Modules::find(current_sentence), sid);
}

package_request *Packaging::generic_resource(submodule_identity *sid) {
	if (generic_subpackages_initialised == FALSE) {
		generic_subpackages_initialised = TRUE;
		Packaging::initialise_submodules(&generic_subpackages);
	}
	submodule_requests *SR = &generic_subpackages;
	package_request *parent = Packaging::request_generic();
	@<Handle the resource request@>;
}

package_request *Packaging::synoptic_resource(submodule_identity *sid) {
	if (synoptic_subpackages_initialised == FALSE) {
		synoptic_subpackages_initialised = TRUE;
		Packaging::initialise_submodules(&synoptic_subpackages);
	}
	submodule_requests *SR = &synoptic_subpackages;
	package_request *parent = Packaging::request_synoptic();
	@<Handle the resource request@>;
}

@<Handle the resource request@> =
	submodule_request *sr;
	LOOP_OVER_LINKED_LIST(sr, submodule_request, SR->submodules)
		if (sid == sr->which_submodule)
			return sr->where_found;
	inter_name *iname = InterNames::explicitly_named(sid->submodule_name, parent);
	sr = CREATE(submodule_request);
	sr->which_submodule = sid;
	sr->where_found = Packaging::request(iname, PackageTypes::get(I"_submodule"));
	ADD_TO_LINKED_LIST(sr, submodule_request, SR->submodules);
	return sr->where_found;

@ 

@d MAX_PRCS 500

=
int no_pr_counters_registered = 0;
text_stream *pr_counter_names[MAX_PRCS];
int Packaging::register_counter(text_stream *name) {
	int id = no_pr_counters_registered++;
	if ((id < 0) || (id >= MAX_PRCS)) internal_error("out of range");
	pr_counter_names[id] = Str::duplicate(name);
	return id;
}

inter_name *Packaging::supply_iname(package_request *R, int what_for) {
	if (R == NULL) internal_error("no request");
	if ((what_for < 0) || (what_for >= no_pr_counters_registered)) internal_error("out of range");
	if (R->counters == NULL)
		R->counters = NEW_LINKED_LIST(submodule_request_counter);
	int N = -1;
	submodule_request_counter *src;
	LOOP_OVER_LINKED_LIST(src, submodule_request_counter, R->counters)
		if (src->counter_id == what_for) {
			N = ++(src->counter_value); break;
		}
	if (N < 0) {
		submodule_request_counter *src = CREATE(submodule_request_counter);
		src->counter_id = what_for;
		src->counter_value = 1;
		N = 1;
		ADD_TO_LINKED_LIST(src, submodule_request_counter, R->counters);
	}
	TEMPORARY_TEXT(P);
	WRITE_TO(P, "%S_%d", pr_counter_names[what_for], N);
	inter_name *iname = InterNames::explicitly_named(P, R);
	DISCARD_TEXT(P);
	return iname;
}

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

inter_name *Packaging::datum_text(inter_name *function_iname, text_stream *translation) {
	package_request *P = Packaging::request(function_iname, PackageTypes::get(I"_data"));
	inter_name *iname = InterNames::explicitly_named(translation, P);
	return iname;
}

int Packaging::housed_in_function(inter_name *iname) {
	if (iname == NULL) return FALSE;
	package_request *P = InterNames::location(iname);
	if (P == NULL) return FALSE;
	if (P->eventual_type == PackageTypes::function()) return TRUE;
	return FALSE;
}
