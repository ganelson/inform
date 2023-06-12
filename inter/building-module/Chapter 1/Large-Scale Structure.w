[LargeScale::] Large-Scale Structure.

To manage the main, connectors and architecture packages of an Inter tree,
together with its major building blocks: modules and their submodules.

@h Structure data.
See //What This Module Does// for a description of the conventions set
by the functions below. Our task in this section is basically to make
|/main|, |/main/connectors| and |/main/architecture|, together with
modules such as |/main/BasicInformKit|, and their submodules, such as
|/main/BasicInformKit/activities|.

=
typedef struct site_structure_data {
	struct inter_package *main_package;
	struct package_request *main_request;

	struct inter_package *connectors_package;
	struct package_request *connectors_request;

	struct inter_package *architecture_package;
	struct package_request *architecture_request;
	struct inter_bookmark architecture_bookmark;

	struct inter_bookmark pragmas_bookmark;
	struct inter_bookmark package_types_bookmark;
	struct inter_bookmark origins_bookmark;

	struct dictionary *modules_indexed_by_name; /* of |module_request| */
	
	struct inter_symbol *text_literal_s;
} site_structure_data;

@ =
void LargeScale::clear_site_data(inter_tree *I) {
	building_site *B = &(I->site);

	B->strdata.main_package = NULL;
	B->strdata.main_request = NULL;

	B->strdata.connectors_package = NULL;
	B->strdata.connectors_request = NULL;

	B->strdata.architecture_package = NULL;
	B->strdata.architecture_request = NULL;
	B->strdata.architecture_bookmark = InterBookmark::at_start_of_this_repository(I);

	B->strdata.pragmas_bookmark = InterBookmark::at_start_of_this_repository(I);
	B->strdata.origins_bookmark = InterBookmark::at_start_of_this_repository(I);
	B->strdata.package_types_bookmark = InterBookmark::at_start_of_this_repository(I);

	B->strdata.modules_indexed_by_name = Dictionaries::new(32, FALSE);
	
	B->strdata.text_literal_s = NULL;
}

@ The three special packages |main|, |connectors| and |architectural| will be
created as needed. But we do not set the |main_package|, |connectors_package|
or |architecture_package| fields when they are created: instead we set these
fields whenever we detect that a package now exists with the relevant names.
This is so that the fields are correctly set even when an Inter tree is being
redd in from an external file, rather than only when created anew in memory.

It follows that |main|, |connectors| and |architectural| are reserved package
names, which cannot be used anywhere else in the tree.

=
void LargeScale::note_package_name(inter_tree *I, inter_package *pack, text_stream *N) {
	if (Str::eq(N, I"main")) I->site.strdata.main_package = pack;
	if (Str::eq(N, I"connectors")) I->site.strdata.connectors_package = pack;
	if (Str::eq(N, I"architectural")) I->site.strdata.architecture_package = pack;
}

@h main.
Here are functions to read |main|, possibly creating if necessary:

=
inter_package *LargeScale::main_package_if_it_exists(inter_tree *I) {
	if (I) return I->site.strdata.main_package;
	return NULL;
}

inter_package *LargeScale::main_package(inter_tree *I) {
	if (I) {
		if (I->site.strdata.main_package == NULL)
			Packaging::incarnate(LargeScale::main_request(I));
		return I->site.strdata.main_package;
	}
	return NULL;
}

package_request *LargeScale::main_request(inter_tree *I) {
	if (I->site.strdata.main_request == NULL)
		I->site.strdata.main_request =
			Packaging::request(I,
				InterNames::explicitly_named(I"main", NULL),
				LargeScale::package_type(I, I"_plain"));
	return I->site.strdata.main_request;
}

inter_symbols_table *LargeScale::main_scope(inter_tree *I) {
	return InterPackage::scope(LargeScale::main_package_if_it_exists(I));
}

@ This finds a symbol by searching every package in a tree. It is used only
to find a very few high-level resources defined at nearly the top of a tree; in
a typical Inform run it is called only about 30 times, always successfully.

=
inter_symbol *LargeScale::find_symbol_in_tree(inter_tree *I, text_stream *S) {
	inter_package *main_package = LargeScale::main_package_if_it_exists(I);
	if (main_package) return InterPackage::find_symbol_slowly(main_package, S);
	return NULL;
}

@h connectors.

=
inter_package *LargeScale::connectors_package_if_it_exists(inter_tree *I) {
	if (I) return I->site.strdata.connectors_package;
	return NULL;
}

inter_package *LargeScale::ensure_connectors_package(inter_tree *I) {
	if (I) {
		if (I->site.strdata.connectors_package == NULL)
			Packaging::incarnate(LargeScale::connectors_request(I));
		return I->site.strdata.connectors_package;
	}
	return NULL;
}

package_request *LargeScale::connectors_request(inter_tree *I) {
	if (I->site.strdata.connectors_request == NULL)
		I->site.strdata.connectors_request = 
			Packaging::request(I,
				InterNames::explicitly_named(I"connectors", LargeScale::main_request(I)),
				LargeScale::package_type(I, I"_linkage"));
	return I->site.strdata.connectors_request;
}

inter_symbols_table *LargeScale::connectors_scope(inter_tree *I) {
	return InterPackage::scope(LargeScale::connectors_package_if_it_exists(I));
}

@h architectural.
This is the only one of the big three which we put any material into in this
section of code; so we need a bookmark for where that material goes.

=
inter_package *LargeScale::architecture_package_if_it_exists(inter_tree *I) {
	if (I) return I->site.strdata.architecture_package;
	return NULL;
}

inter_package *LargeScale::architecture_package(inter_tree *I) {
	if (I) {
		if (I->site.strdata.architecture_package == NULL)
			Packaging::incarnate(LargeScale::architecture_request(I));
		return I->site.strdata.architecture_package;
	}
	return NULL;
}

package_request *LargeScale::architecture_request(inter_tree *I) {
	if (I->site.strdata.architecture_request == NULL) {
		I->site.strdata.architecture_request =
			Packaging::request(I,
				InterNames::explicitly_named(I"architectural", LargeScale::main_request(I)),
				LargeScale::package_type(I, I"_linkage"));
		packaging_state save = Packaging::enter(I->site.strdata.architecture_request);
		I->site.strdata.architecture_bookmark = Packaging::bubble(I);
		Packaging::exit(I, save);
	}
	return I->site.strdata.architecture_request;
}

@ There are two sorts of constant in |architectural|. One set is created only
on demand: if you look for |#grammar_table| you will find it, but if you never
look then it will never exist. These are used only for a handful of values
which are redefined by the //final// code-generator anyway: here we define
them as 0 -- meaninglessly, but they have to be set to something. They are
not, in fact, all constants -- |self| is a variable at runtime -- but again,
it's for the code-generator to define them as it would like, on a platform
by platform basis.

For speed, the names of the permitted veneer symbols are stored in a dictionary.
(This may not in fact be worth the overhead any longer: at one time there were
many more of these.)

=
dictionary *create_these_architectural_symbols_on_demand = NULL;

inter_symbol *LargeScale::find_architectural_symbol(inter_tree *I, text_stream *N) {
	inter_package *arch = LargeScale::architecture_package(I);
	inter_symbols_table *tab = InterPackage::scope(arch);
	inter_symbol *S = InterSymbolsTable::symbol_from_name(tab, N);
	if (S == NULL) {
		@<Ensure the on-demand dictionary exists@>;
		if (Dictionaries::find(create_these_architectural_symbols_on_demand, N))
			S = LargeScale::arch_constant_dec(I, N, InterTypes::unchecked(), 0);
	}	
	return S;
}

int LargeScale::is_veneer_symbol(inter_symbol *con_name) {
	if (con_name) {
		inter_package *home = InterSymbol::package(con_name);
		inter_tree *I = InterPackage::tree(home);
		if (home == LargeScale::architecture_package(I)) {
			text_stream *N = InterSymbol::identifier(con_name);
			if (Dictionaries::find(create_these_architectural_symbols_on_demand, N))
				return TRUE;
		}
	}
	return FALSE;
}

@<Ensure the on-demand dictionary exists@> =
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

@ The other architectural constants are the ones depending on the architecture
being compiled to. These always exist, and their values are known at compile time.

They mostly have obvious meanings, but a few notes:

(1) |WORDSIZE| is the number of bytes in a word.

(2) |NULL|, in our runtime, is -1, and not 0 as it would be in C.

(3) |IMPROBABLE_VALUE| is one which is unlikely even if possible to be a
genuine I7 value. The efficiency of runtime code handling tables depends on
how well chosen this is: it would ran badly if we chose 1, for instance.

(4) Exactly one of the symbols |TARGET_ZCODE| or |TARGET_GLULX| is defined,
and given the notional value 1, though its only purpose is to enable conditional
compilation to work (see //pipeline: Resolve Conditional Compilation Stage//);
so its importance is whether or not it is defined, not what value it has. Note
that these names are now a little anachronistic, and they should perhaps be
renamed |TARGET_16BIT| and |TARGET_32BIT| respectively. For example, C code
can happily be generated from an Inter tree containing |TARGET_GLULX|, even
though that code will never produce a program running on the Glulx VM.

(5) And similarly for |DEBUG|, which again exists to enable conditional
compilation when building kits.

=
void LargeScale::make_architectural_definitions(inter_tree *I,
	inter_architecture *current_architecture) {
	if (current_architecture == NULL) internal_error("no architecture set");
	inter_type type = InterTypes::unchecked();
	if (Architectures::is_16_bit(current_architecture)) {
		LargeScale::arch_constant_dec(I,    I"CHARSIZE", type,                      1);
		LargeScale::arch_constant_dec(I,    I"WORDSIZE", type,                      2);
		LargeScale::arch_constant_hex(I,    I"NULL", type,                     0xffff);
		LargeScale::arch_constant_hex(I,    I"WORD_HIGHBIT", type,             0x8000);
		LargeScale::arch_constant_hex(I,    I"WORD_NEXTTOHIGHBIT", type,       0x4000);
		LargeScale::arch_constant_hex(I,    I"IMPROBABLE_VALUE", type,         0x7fe3);
		LargeScale::arch_constant_dec(I,    I"MAX_POSITIVE_NUMBER", type,       32767);
		LargeScale::arch_constant_signed(I, I"MIN_NEGATIVE_NUMBER", type,      -32768);
		LargeScale::arch_constant_dec(I,    I"TARGET_ZCODE", type,                  1);
	} else {
		LargeScale::arch_constant_dec(I,    I"CHARSIZE", type,                      4);
		LargeScale::arch_constant_dec(I,    I"WORDSIZE", type,                      4);
		LargeScale::arch_constant_hex(I,    I"NULL", type,                 0xffffffff);
		LargeScale::arch_constant_hex(I,    I"WORD_HIGHBIT", type,         0x80000000);
		LargeScale::arch_constant_hex(I,    I"WORD_NEXTTOHIGHBIT", type,   0x40000000);
		LargeScale::arch_constant_hex(I,    I"IMPROBABLE_VALUE", type,     0xdeadce11);
		LargeScale::arch_constant_dec(I,    I"MAX_POSITIVE_NUMBER", type,  2147483647);
		LargeScale::arch_constant_signed(I, I"MIN_NEGATIVE_NUMBER", type, -2147483648);
		LargeScale::arch_constant_dec(I,    I"TARGET_GLULX", type,                  1);
	}

	if (Architectures::debug_enabled(current_architecture))
		LargeScale::arch_constant_dec(I, I"DEBUG", type, 1);
}

@ The functions above use the following tiny API to create architectural constants:

=
inter_symbol *LargeScale::arch_constant(inter_tree *I, text_stream *N,
	inter_type type, inter_pair val) {
	inter_package *arch = LargeScale::architecture_package(I);
	inter_symbols_table *tab = InterPackage::scope(arch);
	inter_symbol *S = InterSymbolsTable::symbol_from_name_creating(tab, N);
	inter_bookmark *IBM = &(I->site.strdata.architecture_bookmark);
	Produce::guard(ConstantInstruction::new(IBM, S, type, val,
		(inter_ti) InterBookmark::baseline(IBM) + 1, NULL));
	return S;
}

inter_symbol *LargeScale::arch_constant_dec(inter_tree *I, text_stream *N,
	inter_type type, inter_ti val) {
	inter_symbol *S = LargeScale::arch_constant(I, N, type,
		InterValuePairs::number_in_base(val, 10));
	return S;
}

inter_symbol *LargeScale::arch_constant_hex(inter_tree *I, text_stream *N,
	inter_type type, inter_ti val) {
	inter_symbol *S = LargeScale::arch_constant(I, N, type,
		InterValuePairs::number_in_base(val, 16));
	return S;
}

inter_symbol *LargeScale::arch_constant_signed(inter_tree *I, text_stream *N,
	inter_type type, int val) {
	inter_symbol *S = LargeScale::arch_constant(I, N, type,
		InterValuePairs::signed_number(val));
	return S;
}

@ This falls back on the main package, but really, should be used only for
things which ought to be in |architectural|:

=
inter_symbol *LargeScale::architectural_symbol(inter_tree *I, text_stream *name) {
	inter_symbol *symbol = NULL;
	inter_package *P = LargeScale::architecture_package_if_it_exists(I);
	if (P) symbol = InterSymbolsTable::symbol_from_name(InterPackage::scope(P), name);
	if (symbol) return symbol;
	P = LargeScale::main_package_if_it_exists(I);
	if (P) symbol = InterSymbolsTable::symbol_from_name(InterPackage::scope(P), name);
	return symbol;
}

@h Modules.
Modules are identified by name, and each one produces an instance of the
following.

=
typedef struct module_request {
	struct package_request *where_found;
	struct linked_list *submodules; /* of |submodule_request| */
	CLASS_DEFINITION
} module_request;

@ The tree's module dictionary is used to ensure that repeated calls with the
same module name return the same |module_request|.

=
module_request *LargeScale::module_request(inter_tree *I, text_stream *name) {
	dictionary *D = I->site.strdata.modules_indexed_by_name;
	if (Dictionaries::find(D, name))
		return (module_request *) Dictionaries::read_value(D, name);
	module_request *new_module = CREATE(module_request);
	new_module->where_found =
		Packaging::request(I,
			InterNames::explicitly_named(name, LargeScale::main_request(I)),
			LargeScale::package_type(I, I"_module"));
	new_module->submodules = NEW_LINKED_LIST(submodule_request);
	Dictionaries::create(D, name);
	Dictionaries::write_value(D, name, (void *) new_module);
	return new_module;
}

@h Submodules.
The idea here is that each module could define, say, some variables, placing
them in a submodule for that purpose. As a result, there will be a "variables only"
submodule found in several modules. Such flavours of submodule are preset --
we allow only a few of these: see //runtime: Hierarchy// for the set used by
//inform7// -- and they must be specified in advance of use, with the following.

For the moment, at least, |submodule_identity| is really just a textual name
like |variables| but in a fancy wrapper.

=
typedef struct submodule_identity {
	struct text_stream *submodule_name;
	CLASS_DEFINITION
} submodule_identity;

submodule_identity *LargeScale::register_submodule_identity(text_stream *name) {
	submodule_identity *sid;
	LOOP_OVER(sid, submodule_identity)
		if (Str::eq(sid->submodule_name, name))
			return sid;
	sid = CREATE(submodule_identity);
	sid->submodule_name = Str::duplicate(name);
	return sid;
}

@ Armed with such an identity, the following can be called to return the relevant
submodule of a given module, creating it if it does not already exist.

=
package_request *LargeScale::generic_submodule(inter_tree *I, submodule_identity *sid) {
	return LargeScale::request_submodule_of(I, LargeScale::module_request(I, I"generic"), sid);
}

package_request *LargeScale::synoptic_submodule(inter_tree *I, submodule_identity *sid) {
	return LargeScale::request_submodule_of(I, LargeScale::module_request(I, I"synoptic"), sid);
}

package_request *LargeScale::completion_submodule(inter_tree *I, submodule_identity *sid) {
	return LargeScale::request_submodule_of(I, LargeScale::module_request(I, I"completion"), sid);
}

@ Those in turn all make use of this back-end function:

=
typedef struct submodule_request {
	struct package_request *where_found;
	struct submodule_identity *which_submodule;
	CLASS_DEFINITION
} submodule_request;

package_request *LargeScale::request_submodule_of(inter_tree *I, module_request *M,
	submodule_identity *sid) {
	submodule_request *sr;
	LOOP_OVER_LINKED_LIST(sr, submodule_request, M->submodules)
		if (sid == sr->which_submodule)
			return sr->where_found;
	inter_name *iname = InterNames::explicitly_named(sid->submodule_name, M->where_found);
	sr = CREATE(submodule_request);
	sr->which_submodule = sid;
	sr->where_found = Packaging::request(I, iname, LargeScale::package_type(I, I"_submodule"));
	ADD_TO_LINKED_LIST(sr, submodule_request, M->submodules);
	return sr->where_found;
}

@h Pragmas.
There's very little to say here:

=
void LargeScale::emit_pragma(inter_tree *I, text_stream *target, text_stream *content) {
	Produce::guard(PragmaInstruction::new(&(I->site.strdata.pragmas_bookmark),
		target, content, 0, NULL));
}

@h Origins.
Or here:

=
void LargeScale::emit_origin(inter_tree *I, inter_symbol *origin, text_stream *fn) {
	Produce::guard(OriginInstruction::new(&(I->site.strdata.origins_bookmark),
		origin, fn, 0, NULL));
}

@h Package types.
Or indeed here. Package types are created on request; looking for |_octopus|
would create it if it didn't already exist. So although the Inform tools do
use a conventional set of package types, they are not itemised here.

However, note the lines relating to enclosure. An "enclosing" package is
one where the compiler keeps all resources needed by the contents of the
package, within that package. For example, if a function in an enclosing
package refers to a literal piece of text, then the necessary Inter array
holding that text must also be somewhere in the package.

It seems tidy to make all packages enclosing, and in fact (after much
experiment) Inform nearly does that. But |_code| packages have to be an
exception, because the Inter specification doesn't allow constants (and
therefore arrays) to be defined inside |_code| packages. This is where that
exception is made.

=
inter_symbol *LargeScale::package_type(inter_tree *I, text_stream *name) {
	inter_symbols_table *scope = InterTree::global_scope(I);
	inter_symbol *ptype = InterSymbolsTable::symbol_from_name(scope, name);
	if (ptype == NULL) {
		ptype = InterSymbolsTable::create_with_unique_name(scope, name);
		Produce::guard(PackageTypeInstruction::new(
			&(I->site.strdata.package_types_bookmark), ptype, 0, NULL));
	}
	return ptype;
}

int LargeScale::package_type_enclosing(inter_symbol *ptype) {
	if (ptype == NULL) return FALSE;
	if (Str::eq(InterSymbol::identifier(ptype), I"_code")) return FALSE;
	return TRUE;
}

@h Outside the packages.
The Inter specification calls for just a handful of resources to be placed
at the top level, outside even the |main| package. Using bubbles, we leave
room to insert those resources, then incarnate |main| and enter it.

=
void LargeScale::begin_new_tree(inter_tree *I) {
	Packaging::initialise_state(I);

	Produce::comment(I, I"Package types:");
	I->site.strdata.package_types_bookmark = Packaging::bubble(I);

	Produce::comment(I, I"Origins:");
	I->site.strdata.origins_bookmark = Packaging::bubble(I);

	Produce::comment(I, I"Pragmas:");
	I->site.strdata.pragmas_bookmark = Packaging::bubble(I);

	Produce::comment(I, I"Primitives:");
	Primitives::declare_standard_set(I, Packaging::at(I));

	LargeScale::package_type(I, I"_plain");   // To ensure this is the first emitted ptype
	LargeScale::package_type(I, I"_code");    // And this the second
	LargeScale::package_type(I, I"_linkage"); // And this the third

	Packaging::enter(LargeScale::main_request(I)); // Which we never exit
}

@h Convenient types.
This structure is used for text literals, which are two-word data structures.
The necessary typename is created on demand: this amounts to writing
|typename text_literal struct int32 unchecked|.

=
inter_type LargeScale::text_literal_type(inter_tree *I) {
	inter_symbol *text_literal_s = I->site.strdata.text_literal_s;
	if (text_literal_s == NULL) {
		inter_package *pack = InterPackage::from_URL(I, I"/main/generic");
		if (pack == NULL) internal_error("no main/generic");
		inter_bookmark in_generic = InterBookmark::at_end_of_this_package(pack);
		inter_ti operands[2];
		operands[0] = InterTypes::to_TID_at(&in_generic,
			InterTypes::from_constructor_code(INT32_ITCONC));
		operands[1] = InterTypes::to_TID_at(&in_generic, InterTypes::unchecked());
		text_literal_s =
			InterSymbolsTable::create_with_unique_name(
				InterBookmark::scope(&in_generic), I"text_literal");
		TypenameInstruction::new(&in_generic, text_literal_s,
			STRUCT_ITCONC, NULL, 2, operands,
			(inter_ti) InterBookmark::baseline(&in_generic) + 1, NULL);
		I->site.strdata.text_literal_s = text_literal_s;
	}
	return InterTypes::from_type_name(text_literal_s);
}
