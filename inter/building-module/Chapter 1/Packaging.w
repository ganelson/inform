[Packaging::] Packaging.

To manage references to Inter packages which may or may not yet exist.

@h Package requests.
See //What This Module Does// for a fuller explanation, but briefly, a package
request represents a package which will eventually exist, if it does not exist
already. //inform7// and other code-generation tools can make elaborate
shadowy hierarchies of such requests, with equally shadowy //inter_name//s
within them representing symbols which also do not exist yet. Eventually,
though, such tools need to make good on their promises and "incarnate" them.

=
typedef struct package_request {
	struct inter_tree *tree;
	struct inter_name *eventual_name;
	struct inter_symbol *eventual_type;
	struct package_request *parent_request;
	struct inter_bookmark write_position;
	struct linked_list *iname_generators; /* of |inter_name_generator| */
	struct inter_package *actual_package; /* |NULL| until this is incarnated */
	CLASS_DEFINITION
} package_request;

@ =
package_request *Packaging::request(inter_tree *I, inter_name *name, inter_symbol *pt) {
	package_request *R = CREATE(package_request);
	R->tree = I;
	R->eventual_name = name;
	R->eventual_type = pt;
	R->parent_request = InterNames::location(name);
	R->write_position = InterBookmark::at_start_of_this_repository(I);
	R->iname_generators = NULL;
	R->actual_package = NULL;
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

@h The packaging state.
At any given time, Inter code is being produced at a particular position
(in some incarnated package) and in the context of a given enclosure -- see
//LargeScale::package_type//. This is summarised by the following state:

=
typedef struct packaging_state {
	struct inter_bookmark *saved_bookmark;
	struct package_request *saved_enclosure;
} packaging_state;

@ It is not legal to make any use of the following state, which exists only to
initialise variables to neutral contents (and thus to avoid warnings generated
because our C compiler is not able to prove that they will never be used in an
uninitialised state -- though in fact they will not).

=
packaging_state Packaging::stateless(void) {
	packaging_state PS;
	PS.saved_bookmark = NULL;
	PS.saved_enclosure = NULL;
	return PS;
}

@ States are intentionally very lightweight, and in particular they contain
pointers to the bookmark structures rather than containing a copy thereof. But
those pointers have to point somewhere, and this is where: to a stack of
bookmarks.

The maximum here is beyond plenty: it's not the maximum hierarchical depth
of the Inter output, it's the maximum number of times that Inform interrupts
itself during compilation.

@d MAX_PACKAGING_ENTRY_DEPTH 128

=
inter_bookmark *Packaging::push_state(inter_tree *I, inter_bookmark IBM) {
	if (I->site.spdata.packaging_entry_sp >= MAX_PACKAGING_ENTRY_DEPTH)
		internal_error("package stack overflow");
	I->site.spdata.packaging_entry_stack[I->site.spdata.packaging_entry_sp] = IBM;
	return &(I->site.spdata.packaging_entry_stack[I->site.spdata.packaging_entry_sp++]);
}

void Packaging::pop_state(inter_tree *I) {
	if (I->site.spdata.packaging_entry_sp <= 0)
		internal_error("package stack underflow");
	I->site.spdata.packaging_entry_sp--;
}

@ We store the current state at all times in the building site, and it has the
following invariant:

(*) The |saved_bookmark| always points to a validly initialised |inter_bookmark|;
(*) The |saved_enclosure| is always either |NULL| or points to a package of a
type which is enclosing.

In fact, |saved_enclosure| is |NULL| only fleetingly: as soon as the |main|
package is created, very early on, the enclosure is always an enclosing package.

=
inter_bookmark *Packaging::at(inter_tree *I) {
	return I->site.spdata.current_state.saved_bookmark;
}

void Packaging::set_at(inter_tree *I, inter_bookmark to) {
	*(I->site.spdata.current_state.saved_bookmark) = to;
}

package_request *Packaging::enclosure(inter_tree *I) {
	return I->site.spdata.current_state.saved_enclosure;
}

void Packaging::initialise_state(inter_tree *I) {
	I->site.spdata.current_state.saved_bookmark =
		Packaging::push_state(I, InterBookmark::at_start_of_this_repository(I));
	I->site.spdata.current_state.saved_enclosure = NULL;
}

@ When we set the state, |saved_enclosure| becomes the smallest package containing
(or equal to) |PR|.

=
void Packaging::set_state(inter_tree *I, inter_bookmark *to, package_request *PR) {
	I->site.spdata.current_state.saved_bookmark = to;
	while ((PR) && (PR->parent_request) &&
		(Inter::Symbols::read_annotation(PR->eventual_type, ENCLOSING_IANN) != 1))
		PR = PR->parent_request;
	I->site.spdata.current_state.saved_enclosure = PR;
}

@h Bubbles.
Inter code is stored in memory as a linked list. This is fast and compact, but
can make it awkward to insert material other than at the end, particularly if
one insertion leads to another close by, midway in the process -- which is
exactly what can happen when incarnating a nested set of packages.

It is also tricky to bookmark positions if nearby code may later be rewritten
or removed, as sometimes happens. A bookmark meaning "after this |INV_IST|
instruction here" would be rendered invalid if that instruction were for some
reason removed.

Finally, because bookmarks can only refer to existing instruction positions,
it is difficult to place a bookmark in an empty package.

We avoid all these difficulties by placing "bubbles" at positions in the
linked list where we will later need to return and place new material.
A bubble is simply a pair of |NOP_IST| (no operation) instructions; any
later inserted material will be placed between them. For example:
= (text)
	...
	inv Whatever
	nop                                       } this is the bubble
		<--- bookmark position is here        }
	nop	                                      }
	...
=

To insert a bubble at the current write-position:

=
inter_bookmark Packaging::bubble(inter_tree *I) {
	Produce::nop(I);
	inter_bookmark b = InterBookmark::snapshot(Packaging::at(I));
	Produce::nop(I);
	return b;
}

@ To insert a bubble somewhere else:

=
inter_bookmark Packaging::bubble_at(inter_bookmark *IBM) {
	Produce::nop_at(IBM, 2);
	inter_bookmark b = InterBookmark::snapshot(IBM);
	Produce::nop_at(IBM, 2);
	return b;
}

@ It's true that the Inter hierarchy does become fairly carbonated with these
bubbles, which costs us some memory; but in practice they cause no real speed
overhead, because |nop| instructions are so quickly skipped over.

@h Entry and exit.
Each PR contains a "write position". This is where emitted Inter code will go;
and it means that not all of the code inside a package needs to be written
at the same time. We can come and go as we please, adding code to packages
all over the hierarchy, simply by switching to the write position in the
package we wsnt to extend next.

That switching is called "entering" a package. Every entry must be followed
by a matching exit, which restores the write position to where it was before
the entry. (The one exception is that the very first entry, into |main| --
see //LargeScale::begin_new_tree// -- is never followed by an exit.)

=
packaging_state Packaging::enter_home_of(inter_name *N) {
	return Packaging::enter(InterNames::location(N));
}

packaging_state Packaging::enter(package_request *R) {
	LOGIF(PACKAGING, "Entering $X\n", R);
	packaging_state save = R->tree->site.spdata.current_state;
	Packaging::incarnate(R);
	Packaging::set_state(R->tree, &(R->write_position), Packaging::enclosure(R->tree));
	inter_bookmark *bubble = Packaging::push_state(R->tree, Packaging::bubble(R->tree));
	Packaging::set_state(R->tree, bubble, R);
	LOGIF(PACKAGING, "[%d] Current enclosure is $X\n",
		R->tree->site.spdata.packaging_entry_sp, Packaging::enclosure(R->tree));
	return save;
}

void Packaging::exit(inter_tree *I, packaging_state save) {
	Packaging::set_state(I, save.saved_bookmark, save.saved_enclosure);
	Packaging::pop_state(I);
	LOGIF(PACKAGING, "[%d] Back to $X\n",
		I->site.spdata.packaging_entry_sp, Packaging::enclosure(I));
}

@h Incarnation.
The subtlety here is that if a package is incarnated, its parent must be
incarnated first, and we need to make sure that their write-position bubbles do
not lie inside each other: if they did, material compiled to the parent and to
the child would end up interleaved.

=
inter_package *Packaging::incarnate(package_request *R) {
	if (R == NULL) internal_error("can't incarnate null request");
	if (R->actual_package == NULL) {
		LOGIF(PACKAGING, "Request to make incarnate $X\n", R);
		inter_tree *I = R->tree;
		package_request *E = Packaging::enclosure(I); // This will not change
		if (R->parent_request) {
			Packaging::incarnate(R->parent_request);
			inter_bookmark *save_IRS = Packaging::at(I);
			Packaging::set_state(I, &(R->parent_request->write_position), E);
			inter_bookmark package_bubble = Packaging::bubble(I);
			Packaging::set_state(I, &package_bubble, E);
			R->actual_package = Produce::make_and_set_package(I, R->eventual_name, R->eventual_type);
			R->write_position = Packaging::bubble(I);
			Packaging::set_state(I, save_IRS, E);
		} else {
			inter_bookmark package_bubble = Packaging::bubble(I);
			package_bubble = Packaging::bubble(I);
			inter_bookmark *save_IRS = Packaging::at(I);
			Packaging::set_state(I, &package_bubble, E);
			R->actual_package = Produce::make_and_set_package(I, R->eventual_name, R->eventual_type);
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
functions are produced by the following:

=
inter_name *Packaging::function(inter_tree *I, inter_name *function_iname,
	text_stream *translation) {
	package_request *P = 
		Packaging::request(I, function_iname, LargeScale::package_type(I, I"_function"));
	inter_name *iname = InterNames::explicitly_named(I"call", P);
	if (translation) InterNames::set_translation(iname, translation);
	return iname;
}

int Packaging::housed_in_function(inter_tree *I, inter_name *iname) {
	if (iname == NULL) return FALSE;
	package_request *P = InterNames::location(iname);
	if (P == NULL) return FALSE;
	if (P->eventual_type == LargeScale::package_type(I, I"_function")) return TRUE;
	return FALSE;
}

@ Datum packages.
These are very similar.

=
inter_name *Packaging::datum_text(inter_tree *I, inter_name *function_iname,
	text_stream *identifier) {
	package_request *P =
		Packaging::request(I, function_iname, LargeScale::package_type(I, I"_data"));
	inter_name *iname = InterNames::explicitly_named(identifier, P);
	return iname;
}

@h Generating inames.
The following allows a sequence of different inames to be generated inside a
package: for example, |Packaging::make_iname_within(R, I"acorn")| produces a
sequence of inames |acorn1|, |acorn2|, ..., as it's called over and over again.

The linked list here is invariably short, in practice, often with only 1 entry,
and so this naive algorithm is probably faster than using a hashed dictionary
of name stems.

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

@h Bookkeeping.

=
typedef struct site_packaging_data {
	struct packaging_state current_state;
	struct inter_bookmark packaging_entry_stack[MAX_PACKAGING_ENTRY_DEPTH];
	int packaging_entry_sp;
} site_packaging_data;

void Packaging::clear_site_data(inter_tree *I) {
	building_site *B = &(I->site);
	B->spdata.current_state = Packaging::stateless();
	B->spdata.packaging_entry_sp = 0;
	Packaging::initialise_state(I);
}
