[HierarchyLocations::] Hierarchy Locations.

Location and naming rules for resources to be compiled in an Inter hierarchy.

@h Hierarchy locations.
A compiler such as //inform7// needs to create many different resources --
arrays, functions and so on -- and each one needs to be placed somewhere
in the hierarchy of an Inter tree, and given a name.

A //hierarchy_location// is an abstract way to specify the rules for doing
that. The compiler creates a mass of these objects, and they are then indexed
by unique IDs, their |access_number|s. The compiler can then, with essentially
no overhead, ask to create the resource with ID |JINXED_WIZARDS_HL| (say),
and the machinery below will work out where it is to go, and what it is to
be called -- |/synoptic/pangrams/jinxed_wizards_fn|, say.

This leads to greater consistency, less duplication of book-keeping code,
and the ability to have a sort of registry of where everything will go:
see //runtime: Hierarchy// for an example.

But it's also helpful when trying to use these resources. If the compiler needs
to make a function call to our hypothetical jinxed-wizards function, it can
simply use |HierarchyLocations::iname(JINXED_WIZARDS_HL)| to obtain an //inter_name//
for where that function is (if it already exists) or will be (if not).

=
typedef struct hierarchy_location {
	int access_number;
	struct text_stream *access_name;
	struct text_stream *function_package_name;
	struct text_stream *datum_package_name;
	struct location_requirement requirements;
	struct inter_name *equates_to_iname;
	struct text_stream *package_type;
	struct name_translation trans;
	CLASS_DEFINITION
} hierarchy_location;

hierarchy_location *HierarchyLocations::new(int id, location_requirement req) {
	hierarchy_location *hl = CREATE(hierarchy_location);
	hl->access_number = id;
	hl->access_name = NULL;
	hl->function_package_name = NULL;
	hl->datum_package_name = NULL;
	hl->equates_to_iname = NULL;
	hl->package_type = NULL;
	hl->trans = Translation::same();
	hl->requirements = req;
	return hl;
}

@ We provide an API of five creator functions for HLs. First, for a resource
like a constant[1] (possibly translated in some way: see //Translation//), and
which must be located at position |req|.

[1] Or a variable, or really anything self-contained under a single simple name
which is not a package of some kind.

=
hierarchy_location *HierarchyLocations::ctr(inter_tree *I, int id, text_stream *name,
	name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id, req);
	hl->access_name = Str::duplicate(name);
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

@ Second, the same thing but with no translation needed:

=
hierarchy_location *HierarchyLocations::con(inter_tree *I, int id, text_stream *name,
	location_requirement req) {
	return HierarchyLocations::ctr(I, id, name, Translation::same(), req);
}

@ Third, for a function, possibly translated in some way, again at |req|:

=
hierarchy_location *HierarchyLocations::fun(inter_tree *I, int id, text_stream *name,
	name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id, req);
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->function_package_name = Str::duplicate(name);
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

@ Fourth, for a package of a given type, which must live at |req|:

=
hierarchy_location *HierarchyLocations::pkg(inter_tree *I, int id, text_stream *name,
	text_stream *ptype_name, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id, req);
	hl->access_name = Str::duplicate(name);
	hl->package_type = Str::duplicate(ptype_name);
	HierarchyLocations::index(I, hl);
	return hl;
}

@ Finally, for a datum package:

=
hierarchy_location *HierarchyLocations::dat(inter_tree *I, int id, text_stream *name,
	name_translation nt, location_requirement req) {
	hierarchy_location *hl = HierarchyLocations::new(id, req);
	hl->access_name = Str::duplicate(nt.translate_to);
	hl->datum_package_name = Str::duplicate(name);
	hl->trans = nt;
	HierarchyLocations::index(I, hl);
	return hl;
}

@h Finding HLs by ID or name.
As noted above, HLs are identified with ID numbers for speed, and this means
that an array must be maintained so that the //hierarchy_location// for a
given ID can be found quickly. We also sometimes want to look them up by name,
which is slower, but the hashing used by a |dictionary| makes even that tolerable.

Both of these forms of lookup need an index to be kept, so HLs must be registered
for use with any tree which will need them, using the following.

Note that HLs for plugs all have the ID -1, so those are indexed only by name.

=
void HierarchyLocations::index(inter_tree *I, hierarchy_location *hl) {
	int id = hl->access_number;
	if ((id >= 0) && (id < NO_DEFINED_HL_VALUES))
		I->site.shdata.HLs_indexed_by_id[id] = hl;
	if (hl->requirements.any_package_of_this_type == NULL) {
		Dictionaries::create(I->site.shdata.HLs_indexed_by_name, hl->access_name);
		Dictionaries::write_value(I->site.shdata.HLs_indexed_by_name,
			hl->access_name, (void *) hl);
	}
}

hierarchy_location *HierarchyLocations::id_to_HL(inter_tree *I, int id) {
	if ((id < 0) || (id >= NO_DEFINED_HL_VALUES)) internal_error("HL ID out of range");
	if (I->site.shdata.HLs_indexed_by_id[id] == NULL) internal_error("undeclared HL ID");
	return I->site.shdata.HLs_indexed_by_id[id];
}

hierarchy_location *HierarchyLocations::name_to_HL(inter_tree *I, text_stream *name) {
	if (Str::len(name) == 0) internal_error("empty HL name");
	if (Dictionaries::find(I->site.shdata.HLs_indexed_by_name, name) == NULL)
		return NULL;
	return (hierarchy_location *)
		Dictionaries::read_value(I->site.shdata.HLs_indexed_by_name, name);
}

@h Finding HLs representing one-off global resources.
The two functions here allow the client to get an iname for a resource which
occurs just once in the whole repository.

For example, |HierarchyLocations::iname(I, UN_BUILDING_HL)| might return the
iname |/main/generic/UN_building|. The package location, here |/main/generic|,
and the name, here |UN_building|, would both be specified explicitly in the HL.
So this is the simplest case.

In response to these requests, we actually never return the //hierarchy_location//
itself; our users don't care about that. We return the //inter_name// for the
resource in question.

=
inter_name *HierarchyLocations::iname(inter_tree *I, int id) {
	hierarchy_location *hl = HierarchyLocations::id_to_HL(I, id);
	@<Work out the iname for this HL@>;
}

inter_name *HierarchyLocations::name_to_iname(inter_tree *I, text_stream *name) {
	hierarchy_location *hl = HierarchyLocations::name_to_HL(I, name);
	if (hl == NULL) return NULL;
	@<Work out the iname for this HL@>;
}

@ The result of the following is cached in |hl->equates_to_iname|, so that
it only needs to be worked out once.

@<Work out the iname for this HL@> =
	if (hl->requirements.any_package_of_this_type)
		internal_error("this must be found with HierarchyLocations::iip");

	if (hl->equates_to_iname) return hl->equates_to_iname;

	if (hl->requirements.must_be_plug) @<Then make it a plug@>;
	
	package_request *pack;
	@<Work out and request the package to make this in@>;
	@<Make the iname inside this package@>;

@<Then make it a plug@> =
	hl->equates_to_iname = InterNames::explicitly_named_plug(I, hl->access_name);
	return hl->equates_to_iname;

@<Work out and request the package to make this in@> =
	pack = hl->requirements.this_exact_package;
	if (hl->requirements.this_exact_package_not_yet_created >= 0)
		@<Choose an exotic package instead@>;
	if (pack == NULL) internal_error("package can't be found");

@<Choose an exotic package instead@> =
	#ifdef CORE_MODULE
	pack = Hierarchy::exotic_package(hl->requirements.this_exact_package_not_yet_created);
	if (pack == NULL) internal_error("unable to determine package and therefore iname");
	#endif
	#ifndef CORE_MODULE
	internal_error("exotic packages are not available in inter");
	#endif

@<Make the iname inside this package@> =
	if (Str::len(hl->function_package_name) > 0) {
		hl->equates_to_iname = Packaging::function(I,
			InterNames::explicitly_named(hl->function_package_name, pack),
			hl->access_name);
	} else if (Str::len(hl->datum_package_name) > 0) {
		hl->equates_to_iname = Packaging::datum_text(I,
			InterNames::explicitly_named(hl->datum_package_name, pack),
			hl->access_name);
	} else {
		hl->equates_to_iname = InterNames::explicitly_named(hl->access_name, pack);
	}
	
	if (hl->trans.translate_to)
		InterNames::set_translation(hl->equates_to_iname, hl->trans.translate_to);

	return hl->equates_to_iname;

@h Finding HLs representing resources in families of packages.
Suppose we want to have packages representing, say, South American countries, and
the compiler wants to create a constant |capital_city| in each of these packages.

There will be a single HL supplying the rules to do this, but multiple inames
will be produced as the compiler makes multiple calls:
= (text as InC)
	... HierarchyLocations::make_iname_in(I, CAPITAL_CITY_HL, uruguay_package) ...
	... HierarchyLocations::make_iname_in(I, CAPITAL_CITY_HL, peru_package) ...
	... HierarchyLocations::make_iname_in(I, CAPITAL_CITY_HL, chile_package) ...
=

=
inter_name *HierarchyLocations::make_iname_in(inter_tree *I, int id, package_request *P) {
	return HierarchyLocations::iip(I, id, P, EMPTY_WORDING, NULL, -1, NULL,
		DEFAULT_INAME_TRUNCATION);
}

@ That might, say, produce constants with the Inter symbols like so:
= (text as InC)
	/main/south_america/uruguay/capital_city
	/main/south_america/peru/capital_city
	/main/south_america/chile/capital_city
=
When final code is generated from these, the constants will probably end up
with bland identifiers like |capital_city_U1|, |capital_city_U2|, and so on.
If we don't want that, we can make an exception like so:
= (text as InC)
	... HierarchyLocations::make_iname_in(I, CAPITAL_CITY_HL, uruguay_package) ...
	... HierarchyLocations::make_iname_with_specific_translation(I, CAPITAL_CITY_HL,
		I"Lima", peru_package) ...
	... HierarchyLocations::make_iname_in(I, CAPITAL_CITY_HL, chile_package) ...
=
Our three capitals would then translate to |capital_city_U1|, |Lima|, and
|capital_city_U2|.

=
inter_name *HierarchyLocations::make_iname_with_specific_translation(inter_tree *I, int id,
	text_stream *translation, package_request *P) {
	return HierarchyLocations::iip(I, id, P, EMPTY_WORDING, NULL, -1, translation,
		DEFAULT_INAME_TRUNCATION);
}

@ Sometimes we want the name itself to be more meaningful, or at least, more
legible when Inter code is printed out. We can do that by attaching a "memo"
of wording to its name. For example, if |W| is the wording "Uruguay", then
calling:
= (text as InC)
	HierarchyLocations::make_iname_with_memo(I, COUNTRY_HL, uruguay_package, W)
=
might produce the iname |/main/south_america/uruguay/C3_uruguay|; a subsequent
call in a different package, with a different wording, might then produce
|/main/south_america/uruguay/C4_trinidad_and_tobago|, and so on. (The choice of
|C| as the prefix would be made in the HL, which specifies naming conventions.)

=
inter_name *HierarchyLocations::make_iname_with_memo(inter_tree *I, int id,
	package_request *P, wording W) {
	return HierarchyLocations::iip(I, id, P, W, NULL, -1, NULL,
		DEFAULT_INAME_TRUNCATION);
}
inter_name *HierarchyLocations::make_iname_with_shorter_memo(inter_tree *I, int id,
	package_request *P, wording W) {
	return HierarchyLocations::iip(I, id, P, W, NULL, -1, NULL,
		DEFAULT_INAME_TRUNCATION - 5);
}

@ Note that the HL, in this example |COUNTRY_HL|, keeps track of how many of
these inames it has made, so that it can increment the index number -- in those
two cases, 3 and then 4. If we need to override this with a specific number |x|
for some reason, we can use this variant:

=
inter_name *HierarchyLocations::make_iname_with_memo_and_value(inter_tree *I,
	int id, package_request *P, wording W, int x) {
	return HierarchyLocations::iip(I, id, P, W, NULL, x, NULL,
		DEFAULT_INAME_TRUNCATION);
}

@ Finally, it's often useful to "derive" a name: to say that a resource in a
given package |P| should have a name based on the name of an existing iname.
For example, the HL |POPULATION_HL| might have the rule that names are made
by suffixing |_POP| to an existing iname. Calling //HierarchyLocations::derive_iname_in//
might then produce a name like |C3_uruguay_POP|, derived from the existing iname
|C3_uruguay|.

=
inter_name *HierarchyLocations::derive_iname_in(inter_tree *I, int id, inter_name *from, 
	package_request *P) {
	return HierarchyLocations::iip(I, id, P, EMPTY_WORDING, from, -1, NULL,
		DEFAULT_INAME_TRUNCATION);
}

@ And this variant form ensures that any translation already made to |from|
is transferred to a similarly derived translation name for the result.

=
inter_name *HierarchyLocations::derive_iname_in_translating(inter_tree *I, int id,
	inter_name *from, package_request *P) {
	inter_name *iname = HierarchyLocations::iip(I, id, P, EMPTY_WORDING, from, -1, NULL,
		DEFAULT_INAME_TRUNCATION);
	TEMPORARY_TEXT(F)
	WRITE_TO(F, "%n", from);
	if (Str::ne(F, InterNames::get_translation(from))) {
		hierarchy_location *hl = HierarchyLocations::id_to_HL(I, id);
		if ((hl->trans.name_generator) && (from)) {
			TEMPORARY_TEXT(T)
			WRITE_TO(T, "%S", InterNames::get_translation(from));
			TEMPORARY_TEXT(TT)
			Str::truncate(T,
				30  - Str::len(hl->trans.name_generator->derived_prefix)
					- Str::len(hl->trans.name_generator->derived_suffix));
			WRITE_TO(TT, "%S%S%S",
				hl->trans.name_generator->derived_prefix,
				T,
				hl->trans.name_generator->derived_suffix);
			InterNames::set_translation(iname, Str::duplicate(TT));
			DISCARD_TEXT(T)
			DISCARD_TEXT(TT)
		}
	}
	DISCARD_TEXT(F)
	return iname;
}

@ All of the above use this command back-end:

=
inter_name *HierarchyLocations::iip(inter_tree *I, int id, package_request *P,
	wording W, inter_name *derive_from, int fix, text_stream *imposed_name,
	int truncation) {
	hierarchy_location *hl = HierarchyLocations::id_to_HL(I, id);

	@<Verify that the proposed package P meets requirements@>;
	
	inter_name *iname = NULL;
	if (hl->trans.translate_to)  {
		text_stream *T = hl->trans.translate_to;
		@<Make the actual iname@>;
	} else if (hl->trans.by_imposition) {
		text_stream *T = NULL;	
		@<Make the actual iname@>;
	} else if (hl->trans.name_generator) {
		TEMPORARY_TEXT(T)
		inter_name *temp_iname =
			(derive_from) ? InterNames::derived(hl->trans.name_generator, derive_from, W)
			              : InterNames::generated(hl->trans.name_generator, fix, W);
		W = EMPTY_WORDING;
		WRITE_TO(T, "%n", temp_iname);
		@<Make the actual iname@>;
		DISCARD_TEXT(T)
	} else {
		text_stream *T = NULL;
		@<Make the actual iname@>;
	}
	
	if (hl->trans.then_make_unique) InterNames::set_flag(iname, MAKE_NAME_UNIQUE_ISYMF);
	return iname;
}

@ We do nothing to change matters here. But an HL can specify that it may only
be used to generate inames in, say, a package of type |_country|: and an
internal error is thrown if this is violated. So compliance is not automatic,
but it is at least policed.

@<Verify that the proposed package P meets requirements@> =
	if ((hl->requirements.any_package_of_this_type == NULL) &&
		(hl->requirements.any_enclosure == FALSE))
		internal_error("this must be found with HierarchyLocations::iname");

	if (hl->requirements.any_enclosure) {
		if (LargeScale::package_type_enclosing(P->eventual_type) == FALSE)
			internal_error("subpackage not in enclosing superpackage");
	} else if (P == NULL) {
		internal_error("iname in null package");
	} else if (P->eventual_type !=
		LargeScale::package_type(I, hl->requirements.any_package_of_this_type)) {
		LOG("Access name: %S, function: %S\n",
			hl->access_name, hl->function_package_name);
		LOG("Have type: $3, required: %S\n",
			P->eventual_type, hl->requirements.any_package_of_this_type);
		internal_error("iname in superpackage of the wrong type");
	}

@<Make the actual iname@> =
	if (Str::len(hl->function_package_name) > 0) {
		iname = Packaging::function(I,
			InterNames::explicitly_named(hl->function_package_name, P), NULL);
	} else if (hl->trans.by_imposition) {
		iname = InterNames::explicitly_named_with_memo(imposed_name, P, W, truncation);
	} else if (Str::len(hl->access_name) == 0) {
		iname = InterNames::explicitly_named_with_memo(T, P, W, truncation);
	} else {
		iname = InterNames::explicitly_named_with_memo(hl->access_name, P, W, truncation);
	}
	if ((Str::len(T) > 0) && (hl->access_name)) InterNames::set_translation(iname, T);

@h Making one-off subpackages.
This is used very little. (In //inform7//, currently only for making the packages
holding built-in activity or action rulebooks.)

=
package_request *HierarchyLocations::subpackage(inter_tree *I, int id, package_request *P) {
	hierarchy_location *hl = HierarchyLocations::id_to_HL(I, id);

	if (P == NULL) internal_error("no superpackage");
	if (hl->package_type == NULL) internal_error("HL does not specify a type");
	if (hl->requirements.any_package_of_this_type) {
		if (P->eventual_type !=
			LargeScale::package_type(I, hl->requirements.any_package_of_this_type))
			internal_error("subpackage in superpackage of wrong type");
	} else if (hl->requirements.any_enclosure) {
		if (LargeScale::package_type_enclosing(P->eventual_type) == FALSE)
			internal_error("subpackage not in enclosing superpackage");
	} else internal_error("HL does not call for a package");

	return Packaging::request(I,
		InterNames::explicitly_named(hl->access_name, P),
		LargeScale::package_type(I, hl->package_type));
}

@h Making packages systematically at attachment points.
This is used a great deal. Instead of making a single iname, or a single package,
we want to make a family of packages, sequentially numbered in some way, at a
given position in the hierarchy. Such families are created at "hierarchy
attachment points", and the process of adding another package to the family
is called "attachment".

Like HLs, HAPs are identified by number, but this is a different and independent
numbering system.

=
typedef struct hierarchy_attachment_point {
	int hap_id;
	struct text_stream *name_stem;
	struct text_stream *type;
	struct location_requirement requirements;
	CLASS_DEFINITION
} hierarchy_attachment_point;

@ Once again, these are indexed for speedy retrieval by ID number:

=
hierarchy_attachment_point *HierarchyLocations::att(inter_tree *I, int id,
	text_stream *stem, text_stream *ptype_name, location_requirement req) {
	if ((id < 0) || (id >= NO_DEFINED_HAP_VALUES)) internal_error("HAP ID out of range");
	hierarchy_attachment_point *hap = CREATE(hierarchy_attachment_point);
	hap->hap_id = id;
	hap->requirements = req;
	hap->name_stem = Str::duplicate(stem);
	hap->type = Str::duplicate(ptype_name);
	I->site.shdata.HAPs_indexed_by_id[hap->hap_id] = hap;
	return hap;
}

hierarchy_attachment_point *HierarchyLocations::id_to_HAP(inter_tree *I, int id) {
	if ((id < 0) || (id >= NO_DEFINED_HAP_VALUES)) internal_error("HAP ID out of range");
	if (I->site.shdata.HAPs_indexed_by_id[id] == NULL) internal_error("undeclared HAP ID");
	return I->site.shdata.HAPs_indexed_by_id[id];
}

@ The API is now very simple. |HierarchyLocations::attach_new_package(I, M, R, id)|
attaches another package. R and M need only be specified if the location requirements
of the HAL do not imply a definite position already; M is meaningful only if the
requirements are to put everything in a submodule of a given module, and then M
is that module. For example:
= (text as InC)
	vf_req = Hierarchy::package_within(I, NULL, R, VERB_FORMS_HAP);
=
attaches a new verb form package inside |R|. |VERB_FORMS_HAP| has already been
declared with //HierarchyLocations::att//, and has stem |"form"| and type |"_verb_form"|.
So the outcome might be a package called, say, |form_16| of type |_verb_form|
inside of |R|; and then on the next call |form_17|, and so on.

=
package_request *HierarchyLocations::attach_new_package(inter_tree *I,
	module_request *M, package_request *R, int hap_id) {
	hierarchy_attachment_point *hap = HierarchyLocations::id_to_HAP(I, hap_id);
	if (hap->requirements.any_submodule_package_of_this_identity) {
		if (M) R = LargeScale::request_submodule_of(I, M,
					   hap->requirements.any_submodule_package_of_this_identity);
		else   R = LargeScale::generic_submodule(I,
					   hap->requirements.any_submodule_package_of_this_identity);
	} else if (hap->requirements.this_exact_package) {
		R = hap->requirements.this_exact_package;
	} else if (hap->requirements.this_exact_package_not_yet_created >= 0) {
		#ifdef CORE_MODULE
		R = Hierarchy::exotic_package(hap->requirements.this_exact_package_not_yet_created);
		#endif
		#ifndef CORE_MODULE
		internal_error("exotic packages are not available in inter");
		#endif
	} else if (hap->requirements.any_package_of_this_type) {
		if ((R == NULL) ||
			(R->eventual_type != LargeScale::package_type(I,
				hap->requirements.any_package_of_this_type)))
			internal_error("subpackage in wrong superpackage");
	}
	
	return Packaging::request(I,
		Packaging::make_iname_within(R, hap->name_stem),
		LargeScale::package_type(I, hap->type));
}

@h Bookkeeping.
The following is a little clumsily defined to allow for the possibility that
this code is being compiled within a tool which defines no HLs or HAPs.

=
typedef struct site_hierarchy_data {
	struct dictionary *HLs_indexed_by_name;
	#ifndef NO_DEFINED_HL_VALUES
	#define NO_DEFINED_HL_VALUES 1
	#endif
	struct hierarchy_location *HLs_indexed_by_id[NO_DEFINED_HL_VALUES];
	#ifndef NO_DEFINED_HAP_VALUES
	#define NO_DEFINED_HAP_VALUES 1
	#endif
	struct hierarchy_attachment_point *HAPs_indexed_by_id[NO_DEFINED_HAP_VALUES];
} site_hierarchy_data;

void HierarchyLocations::clear_site_data(inter_tree *I) {
	building_site *B = &(I->site);
	B->shdata.HLs_indexed_by_name = Dictionaries::new(512, FALSE);
	for (int i=0; i<NO_DEFINED_HL_VALUES; i++) B->shdata.HLs_indexed_by_id[i] = NULL;
	for (int i=0; i<NO_DEFINED_HAP_VALUES; i++) B->shdata.HAPs_indexed_by_id[i] = NULL;
}

@h Finding inames by name.

=
inter_name *HierarchyLocations::find_by_name(inter_tree *I, text_stream *name) {
	if (Str::len(name) == 0) internal_error("empty extern");
	inter_name *try = HierarchyLocations::name_to_iname(I, name);
	if (try == NULL) {
		HierarchyLocations::con(I, -1, name, LocationRequirements::plug());
		try = HierarchyLocations::name_to_iname(I, name);
	}
	return try;
}

inter_name *HierarchyLocations::find_by_implied_name(inter_tree *I, text_stream *name,
	text_stream *from_namespace) {
	if (Str::len(name) == 0) internal_error("empty extern");
	inter_name *try = HierarchyLocations::name_to_iname(I, name);
	if (try == NULL) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "implied`%S`%S", from_namespace, name);
		HierarchyLocations::con(I, -1, N, LocationRequirements::plug());
		try = HierarchyLocations::name_to_iname(I, N);
		DISCARD_TEXT(N)
	}
	return try;
}
