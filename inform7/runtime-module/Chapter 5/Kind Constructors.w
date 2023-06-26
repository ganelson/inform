[RTKindConstructors::] Kind Constructors.

Each kind constructor has an Inter package of resources.

@h Compilation data.

=
typedef struct kind_constructor_compilation_data {
	struct package_request *kc_package;
	struct inter_name *xref_iname;

	struct inter_name *weak_ID_iname;

	struct inter_name *first_instance_iname;
	struct inter_name *next_instance_iname;
	struct inter_name *base_IK_iname;
	struct inter_name *icount_iname;
	struct inter_name *instances_array_iname;
	struct inter_name *instance_list_iname;
	struct inter_name *indexing_fn_iname;

	struct inter_name *increment_fn_iname;
	struct inter_name *decrement_fn_iname;
	struct inter_name *default_value_fn_iname;
	struct inter_name *random_value_fn_iname;
	struct inter_name *comparison_fn_iname;
	struct inter_name *support_fn_iname;

	struct inter_name *print_fn_iname;
	struct inter_name *debug_print_fn_iname;
	struct inter_name *showme_fn_iname;

	struct inter_name *GPR_iname;
	struct inter_name *instance_GPR_iname;
	struct inter_name *recognition_only_GPR_iname;
	struct inter_name *distinguisher_function_iname;

	int declaration_sequence_number;
	int nonstandard_enumeration;
} kind_constructor_compilation_data;

kind_constructor_compilation_data RTKindConstructors::new_compilation_data(kind_constructor *kc) {
	kind_constructor_compilation_data kccd;
	kccd.kc_package = NULL;
	kccd.xref_iname = NULL;

	kccd.weak_ID_iname = NULL;

	kccd.first_instance_iname = NULL;
	kccd.next_instance_iname = NULL;
	kccd.base_IK_iname = NULL;
	kccd.icount_iname = NULL;
	kccd.instances_array_iname = NULL;
	kccd.instance_list_iname = NULL;
	kccd.indexing_fn_iname = NULL;

	kccd.increment_fn_iname = NULL;
	kccd.decrement_fn_iname = NULL;
	kccd.default_value_fn_iname = NULL;
	kccd.random_value_fn_iname = NULL;
	kccd.comparison_fn_iname = NULL;
	kccd.support_fn_iname = NULL;

	kccd.print_fn_iname = NULL;
	kccd.debug_print_fn_iname = NULL;
	kccd.showme_fn_iname = NULL;

	kccd.GPR_iname = NULL;
	kccd.instance_GPR_iname = NULL;
	kccd.recognition_only_GPR_iname = NULL;
	kccd.distinguisher_function_iname = NULL;

	kccd.declaration_sequence_number = -1;
	kccd.nonstandard_enumeration = FALSE;
	return kccd;
}

@h The package.
The Inter package for a kind constructor -- either a base kind, like "door"
or "number", or a derived kind like "list of ..." -- can appear more or less
anywhere in the Inter tree without making any real difference to the meaning
of the program, but we try to be tidy about where to put it.

=
package_request *RTKindConstructors::kind_package(kind *K) {
	return RTKindConstructors::package(K->construct);
}

package_request *RTKindConstructors::package(kind_constructor *kc) {
	if (kc->compilation_data.kc_package == NULL) {
		package_request *pack = NULL;
		if (kc->where_defined_in_source_text) {
			pack = Hierarchy::local_package_to(KIND_HAP, kc->where_defined_in_source_text);
		} else if (kc->superkind_set_at) {
			pack = Hierarchy::local_package_to(KIND_HAP, kc->superkind_set_at);
		} else {
			pack = Hierarchy::synoptic_package(KIND_HAP);
		}
		kc->compilation_data.kc_package = pack;
	}
	return kc->compilation_data.kc_package;
}

@ Neptune definitions of kinds refer to Inter functions by identifier name,
so we will need a way to turn those into inames:

=
inter_name *RTKindConstructors::iname_of_kit_function(kind *K, text_stream *identifier) {
	inter_name *iname = HierarchyLocations::find_by_name(Emit::tree(), identifier);
	if (iname == NULL) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
		Problems::quote_kind(1, K);
		Problems::quote_stream(2, identifier);
		Problems::issue_problem_segment(
			"The kind %1 is declared in a Neptune file to make use of a "
			"function called '%2', but this does not seem to exist.");
		Problems::issue_problem_end();
	}
	return iname;
}

@ These macros are convenient for caching the results of iname creation or lookup,
so that they need be done only once per kind:

@d RETURN_INAME_IN(kc, iname, creator)
	if (kc->compilation_data.iname == NULL) {
		kc->compilation_data.iname = creator;
	}
	return kc->compilation_data.iname;
@d RETURN_AVAILABLE_INAME_IN(kc, iname, creator)
	if (kc->compilation_data.iname == NULL) {
		kc->compilation_data.iname = creator;
		Hierarchy::make_available(kc->compilation_data.iname);
	}
	return kc->compilation_data.iname;

@ The "cross-reference iname" is used as a device to allow metadata from some
other package to point to this package without inconvenient namespace clashes.
A symbol is defined at this iname: only its location is meaningful, and its
value is never used.

=
inter_name *RTKindConstructors::xref_iname(kind_constructor *kc) {
	RETURN_INAME_IN(kc, xref_iname,
		Hierarchy::make_iname_in(KIND_XREF_SYMBOL_HL, RTKindConstructors::package(kc)))
}

@h Iname for the weak ID.
The "weak ID" for a kind is a runtime value identifying only its constructor.
This distinguishes base kinds -- for example, "number" and "text" have different
weak IDs -- but not derived kinds -- for example, "list of numbers" and
"list of texts" have the same weak ID. (For that, the "strong ID" is needed.)

An identifier like |NUMBER_TY|, then, begins life in a definition inside an
Neptune file; becomes attached to a constructor here; and finally winds up
back in Inter code, because we define it as the constant for the weak kind ID
of the kind which the constructor makes:

=
inter_name *RTKindConstructors::weak_ID_iname(kind_constructor *kc) {
	RETURN_AVAILABLE_INAME_IN(kc, weak_ID_iname,
		Hierarchy::make_iname_with_specific_translation(WEAK_ID_HL,
			RTKindIDs::identifier_for_weak_ID(kc), RTKindConstructors::package(kc)))
}

@h Inames to do with the range of values.

=
inter_name *RTKindConstructors::increment_fn_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, increment_fn_iname,
		Hierarchy::make_iname_in(INCREMENT_FN_HL, RTKindConstructors::package(kc)))
}

inter_name *RTKindConstructors::decrement_fn_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, decrement_fn_iname,
		Hierarchy::make_iname_in(DECREMENT_FN_HL, RTKindConstructors::package(kc)))
}

inter_name *RTKindConstructors::default_value_fn_iname(kind_constructor *kc) {
	RETURN_INAME_IN(kc, default_value_fn_iname,
		Hierarchy::make_iname_in(MKDEF_FN_HL, RTKindConstructors::package(kc)))
}

inter_name *RTKindConstructors::random_value_fn_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, random_value_fn_iname,
		Hierarchy::make_iname_in(RANGER_FN_HL, RTKindConstructors::package(kc)))
}

@ A comparison function, testing whether two runtime values of the kind are
equal, can be provided by a kit (defining a kind with a Neptune file), but
is not otherwise created:

=
int RTKindConstructors::comparison_function_provided_by_kit(kind *K) {
	if (K == NULL) return FALSE;
	text_stream *identifier = Kinds::Behaviour::get_comparison_routine(K);
	if (Str::len(identifier) > 0) return TRUE;
	return FALSE;
}

inter_name *RTKindConstructors::comparison_fn_iname(kind *K) {
	if (RTKindConstructors::comparison_function_provided_by_kit(K) == FALSE)
		return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, comparison_fn_iname,
		RTKindConstructors::iname_of_kit_function(K,
			Kinds::Behaviour::get_comparison_routine(K)))
}

@ And similarly for a support function, which can carry out a range of useful
tasks to do with block values (creating values, copying values and so on).
This too exists only if a kit provides it, but (anomalously) the kit does not
need to specify its name in a Neptune file: instead the name is that of the
kind's weak ID plus |_Support|. For example, |TEXT_TY_Support|.

=
int RTKindConstructors::support_function_provided_by_kit(kind *K) {
	if (K == NULL) return FALSE;
	if (RTKindConstructors::support_fn_iname(K)) return TRUE;
	return FALSE;
}

inter_name *RTKindConstructors::support_fn_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, support_fn_iname,
		RTKindConstructors::create_support_fn_iname(kc))
}

inter_name *RTKindConstructors::create_support_fn_iname(kind_constructor *kc) {
	TEMPORARY_TEXT(N)
	WRITE_TO(N, "%S_Support", kc->explicit_identifier);
	inter_name *iname = HierarchyLocations::find_by_name(Emit::tree(), N);
	DISCARD_TEXT(N)
	return iname;
}

@h Inames to do with enumerative kinds.
For kinds of object, constants for the first instance, and a property for the
next instance: this enables rapid looping through all instances at runtime.

=
inter_name *RTKindConstructors::first_instance_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, first_instance_iname,
		Hierarchy::derive_iname_in_translating(FIRST_INSTANCE_HL,
			RTKindDeclarations::iname(K), RTKindConstructors::package(kc)))
}

inter_name *RTKindConstructors::next_instance_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, next_instance_iname,
		Hierarchy::derive_iname_in_translating(NEXT_INSTANCE_HL,
			RTKindDeclarations::iname(K), RTKindConstructors::package(kc)))
}

@ The "base IK iname" is not in fact used as the definition of anything: it
exists for other inames to be derived from it. See //Instance Counting//.

=
inter_name *RTKindConstructors::base_IK_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, base_IK_iname,
		RTKindConstructors::create_base_IK_iname(K))
}

inter_name *RTKindConstructors::create_base_IK_iname(kind *K) {
	package_request *pack = RTKindConstructors::kind_package(K);
	int N = Kinds::Behaviour::get_range_number(K), hl = -1;
	switch (N) {
		case 1: hl = BASE_IK_1_HL; break;
		case 2: hl = BASE_IK_2_HL; break;
		case 3: hl = BASE_IK_3_HL; break;
		case 4: hl = BASE_IK_4_HL; break;
		case 5: hl = BASE_IK_5_HL; break;
		case 6: hl = BASE_IK_6_HL; break;
		case 7: hl = BASE_IK_7_HL; break;
		case 8: hl = BASE_IK_8_HL; break;
		case 9: hl = BASE_IK_9_HL; break;
		case 10: hl = BASE_IK_10_HL; break;
	}
	if (hl >= 1) return Hierarchy::make_iname_in(hl, pack);

	return Hierarchy::derive_iname_in_translating(BASE_IK_HL,
		RTKindDeclarations::iname(K), pack);
}

@ The "icount" is a genuine constant, currently defined for each enumeration
and each kind of object. The naming system here is potentially problematic:
"figure name" counts out as |ICOUNT_FIGURE_NAME|, "door" as |ICOUNT_DOOR|,
and so on. This is potentially open to namespace clashes, given the truncation
to 31 characters, but for kinds whose names fit into that length without
truncation, there should never be any problem.

All the same,icounts should probably be used only when necessary, and |WorldModelKit|
no longer uses the icounts for any kinds of object, where clashes are more
plausible.

=
inter_name *RTKindConstructors::icount_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, icount_iname,
		RTKindConstructors::create_icount_iname(K))
}

inter_name *RTKindConstructors::create_icount_iname(kind *K) {
	package_request *pack = RTKindConstructors::kind_package(K);
	TEMPORARY_TEXT(ICN)
	WRITE_TO(ICN, "ICOUNT_");
	Kinds::Textual::write(ICN, K);
	Str::truncate(ICN, 31);
	LOOP_THROUGH_TEXT(pos, ICN) {
		Str::put(pos, Characters::toupper(Str::get(pos)));
		if (Characters::isalnum(Str::get(pos)) == FALSE) Str::put(pos, '_');
	}
	inter_name *iname = Hierarchy::make_iname_with_specific_translation(ICOUNT_HL,
		InterSymbolsTable::render_identifier_unique(LargeScale::main_scope(Emit::tree()), ICN),
		pack);
	Hierarchy::make_available(iname);
	DISCARD_TEXT(ICN)
	return iname;
}

@ For nonstandard enumerations, we need an array holding the valid values.

=
inter_name *RTKindConstructors::instances_array_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, instances_array_iname,
		Hierarchy::derive_iname_in_translating(INSTANCES_ARRAY_HL,
			RTKindDeclarations::iname(K), RTKindConstructors::package(kc)))
}

@ Sometimes we want to cache the constant list produced by "list of doors",
say -- an Inform 7 list. This means that if there are multiple mentions of
the "list of doors", we will only compile the constant once. It goes here:

=
inter_name *RTKindConstructors::list_iname(kind_constructor *kc) {
	return kc->compilation_data.instance_list_iname;
}
void RTKindConstructors::set_list_iname(kind_constructor *kc, inter_name *iname) {
	kc->compilation_data.instance_list_iname = iname;
}

@ Non-standard enumerations need a function which, given a value, returns its
sequence position in the enumeration:

=
inter_name *RTKindConstructors::indexing_fn_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, indexing_fn_iname,
		Hierarchy::make_iname_in(INDEXING_FN_HL, RTKindConstructors::package(kc)))
}

@h Inames to do with printing.
Note that all kinds of object share a common print function.

=
inter_name *RTKindConstructors::printing_fn_iname(kind *K) {
	if (K == NULL) K = K_number;
	if (K == NULL) internal_error("null kind has no printing routine");
	K = Kinds::weaken(K, K_object);

	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, print_fn_iname,
		RTKindConstructors::obtain_printing_fn_iname(K))
}

@ This innocuous-looking function has been the cause of considerable grief over
the years because of the overlapping alternatives in play (where the kind came
from, who should write the function, where it should be in the Inter tree, who
gets to choose its identifier, and whether it is available to kit code through
the linker). This is the cleanest expression I can get:

=
inter_name *RTKindConstructors::obtain_printing_fn_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	package_request *pack = RTKindConstructors::package(kc);
	text_stream *X = kc->print_identifier;

	@<If the synoptic module wants to compile this printing function, let it@>;

	if ((Kinds::Behaviour::comes_from_Neptune(K) == FALSE) ||
		(Kinds::Behaviour::is_an_enumeration(K)))
		@<This runtime module will compile the printing function@>
	else
		@<The printing function can be found in a kit@>;
}

@ For example, "use option" currently falls into this case:

@<If the synoptic module wants to compile this printing function, let it@> =
	inter_name *synoptic_iname =
		SynopticHierarchy::printing_function_iname(Emit::tree(), K);
	if (synoptic_iname) return synoptic_iname;

@ For example, "scene" currently falls into this case:

@<This runtime module will compile the printing function@> =
	if (Str::len(X) > 0) {
		inter_name *iname = Hierarchy::make_iname_in(PRINT_FN_HL, pack);
		InterNames::set_translation(iname, X);
		Hierarchy::make_available(iname);
		return iname;
	} else {
		return Hierarchy::make_iname_in(PRINT_DASH_FN_HL, pack);
	}

@ For example, "rulebook outcome" currently falls into this case:

@<The printing function can be found in a kit@> =
	inter_name *iname = NULL;
	if (Str::len(X) > 0) {
		return iname = RTKindConstructors::iname_of_kit_function(K, X);
	} else {
		return iname = RTKindConstructors::iname_of_kit_function(K, I"DecimalNumber");
	}

@ This is the variant used when printing values as part of the output of the
ACTIONS debugging command, for example. It's the same as the regular printing
function unless the Neptune definition for a kind says otherwise.

=
inter_name *RTKindConstructors::debug_print_fn_iname(kind *K) {
	if (K == NULL) K = K_number;
	if (K == NULL) internal_error("null kind has no printing routine");
	K = Kinds::weaken(K, K_object);

	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, debug_print_fn_iname,
		RTKindConstructors::obtain_debug_print_fn_iname(K))
}

inter_name *RTKindConstructors::obtain_debug_print_fn_iname(kind *K) {
	text_stream *identifier = K->construct->ACTIONS_identifier;
	if (Str::len(identifier) > 0)
		return RTKindConstructors::iname_of_kit_function(K, identifier);
	return RTKindConstructors::printing_fn_iname(K);
}

@ And a few kinds also need a special function to improve the results of
SHOWME, or the phrase "showme", also for debugging purposes.

=
inter_name *RTKindConstructors::showme_fn_iname(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, showme_fn_iname,
		Hierarchy::make_iname_in(SHOWME_FN_HL, RTKindConstructors::kind_package(K)))
}

@h Inames to do with the command parser.
The command parser is not present in Basic Inform projects, so we do nothing
in this area unless the parsing plugin activates and calls the following:

=
int GPR_compilation_enabled = FALSE;

void RTKindConstructors::enable_parsing(void) {
	GPR_compilation_enabled = TRUE;
}
int RTKindConstructors::GPR_compilation_enabled(void) {
	return GPR_compilation_enabled;
}

@ "GPR" is old Inform jargon for "general parsing routine", a function which
examines words produced by the command parser to match them as the name of
an instance of the kind. See //Kind GPRs// for more.

When kits create kinds using Neptune files, they will often supply their own
GPR functions, and if they do then we use those rather than construct our own.

=
int RTKindConstructors::GPR_provided_by_kit(kind *K) {
	if (K == NULL) return FALSE;
	text_stream *identifier = Kinds::Behaviour::GPR_identifier(K);
	if (Str::len(identifier) > 0) return TRUE;
	return FALSE;
}

inter_name *RTKindConstructors::GPR_iname(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, GPR_iname, RTKindConstructors::create_GPR_iname(K))
}

inter_name *RTKindConstructors::create_GPR_iname(kind *K) {
	if (RTKindConstructors::GPR_provided_by_kit(K))
		return RTKindConstructors::iname_of_kit_function(K,
			Kinds::Behaviour::GPR_identifier(K));
	kind_constructor *kc = Kinds::get_construct(K);
	return Hierarchy::make_iname_in(GPR_FN_HL, RTKindConstructors::package(kc));
}

@ Some kinds have a few supplementary GPRs as well. Enumerations have the
following, for parsing non-standard names for instances:

=
inter_name *RTKindConstructors::instance_GPR_iname(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, instance_GPR_iname,
		Hierarchy::make_iname_in(INSTANCE_GPR_FN_HL, RTKindConstructors::package(kc)))
}

@ A recognition-only GPR is used for matching specific data in the course of
parsing names of objects, but not as a grammar token in its own right. If this
exists at all, it is provided by a kit and named in a Neptune command.

=
int RTKindConstructors::recognition_only_GPR_provided_by_kit(kind *K) {
	if (K == NULL) return FALSE;
	text_stream *identifier = Kinds::Behaviour::recognition_only_GPR_identifier(K);
	if (Str::len(identifier) > 0) return TRUE;
	return FALSE;
}

inter_name *RTKindConstructors::recognition_only_GPR_iname(kind *K) {
	if (RTKindConstructors::recognition_only_GPR_provided_by_kit(K) == FALSE)
		return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, recognition_only_GPR_iname,
		RTKindConstructors::iname_of_kit_function(K,
			Kinds::Behaviour::recognition_only_GPR_identifier(K)))
}

@ Same exact deal with the "distinguisher function" for a kind, also used
in parsing. See //Parse Name Properties//.

=
int RTKindConstructors::distinguisher_function_provided_by_kit(kind *K) {
	if (K == NULL) return FALSE;
	text_stream *identifier = Kinds::Behaviour::get_distinguisher(K);
	if (Str::len(identifier) > 0) return TRUE;
	return FALSE;
}

inter_name *RTKindConstructors::distinguisher_function_iname(kind *K) {
	if (RTKindConstructors::distinguisher_function_provided_by_kit(K) == FALSE)
		return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	RETURN_INAME_IN(kc, distinguisher_function_iname,
		RTKindConstructors::iname_of_kit_function(K,
			Kinds::Behaviour::get_distinguisher(K)))
}

@h Miscellaneous utility functions.

=
int RTKindConstructors::is_subkind_of_object(kind_constructor *kc) {
	if (Kinds::Behaviour::is_subkind_of_object(Kinds::base_construction(kc)))
		return TRUE;
	return FALSE;
}

int RTKindConstructors::is_object(kind_constructor *kc) {
	if (Kinds::Behaviour::is_object(Kinds::base_construction(kc))) return TRUE;
	return FALSE;
}

@ The following works for all enumerations, standard or not:

=
int RTKindConstructors::enumeration_size(kind *K) {
	if (K == NULL) return 0;
	kind_constructor *kc = Kinds::get_construct(K);
	if (KindConstructors::is_an_enumeration(kc)) return kc->next_free_value - 1;
	return 0;
}

@ Non-standard enumeration occurs when a kit defines an enumerative kind with
runtime values other than 1, 2, 3, ...; an instance which has other than the
expected runtime value is called "out of order", and a kind is a "non-standard
enumeration" if it has an out of order instance.

=
void RTKindConstructors::set_explicit_runtime_instance_value(kind *K, instance *I,
	inter_ti val) {
	kind_constructor *kc = Kinds::get_construct(K);
	RTInstances::set_explicit_runtime_value(I, val);
	if (RTInstances::out_of_place(I))
		kc->compilation_data.nonstandard_enumeration = TRUE;
}

int RTKindConstructors::is_nonstandard_enumeration(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	return kc->compilation_data.nonstandard_enumeration;
}

@ The following function is useful when compiling lists of the valid values
for an enumeration.

A little dubiously, for a standard enumeration ("Colour is a kind of value. The
colours are red, green and blue."), the entries are just the numbers 1, 2, 3, ...
That never seems a good use of memory, but it is still more efficient to store
one copy of this than to have to construct it frequently at runtime.

For a nonstandard enumeration, the entries are more interesting. They essentially
duplicate the instances array, but again, it's more efficient to take the memory
overhead.

=
void RTKindConstructors::make_enumeration_entries(kind *K) {
	if (RTKindConstructors::is_nonstandard_enumeration(K)) {
		instance *I;
		LOOP_OVER_INSTANCES(I, K)
			EmitArrays::iname_entry(RTInstances::value_iname(I));		
	} else {
		int N = RTKindConstructors::enumeration_size(K);
		for (int i = 1; i <= N; i++)
			EmitArrays::numeric_entry((inter_ti) i);
	}
}

@h Assigning declaration sequence numbers.
These provide a sequencing useful to code-generators, with superkinds earlier
in the sequence than subkinds -- which may not be true of source code ordering.

=
inter_ti kind_sequence_counter = 0;

void RTKindConstructors::assign_declaration_sequence_numbers(void) {
	int N = 0;
	RTKindConstructors::assign_dsn_r(&N, KindSubjects::from_kind(K_object));
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		if ((kc == CON_KIND_VARIABLE) || (kc == CON_INTERMEDIATE)) continue;
		kind *K = Kinds::base_construction(kc);
		if ((RTKindDeclarations::base_represented_in_Inter(K)) &&
			(KindSubjects::has_properties(K)) &&
			(Kinds::Behaviour::is_object(K) == FALSE))
			K->construct->compilation_data.declaration_sequence_number = N++;
	}
}

void RTKindConstructors::assign_dsn_r(int *N, inference_subject *within) {
	kind *K = KindSubjects::to_kind(within);
	K->construct->compilation_data.declaration_sequence_number = (*N)++;
	inference_subject *subj;
	LOOP_OVER(subj, inference_subject)
		if ((InferenceSubjects::narrowest_broader_subject(subj) == within) &&
			(InferenceSubjects::is_a_kind_of_object(subj)))
			RTKindConstructors::assign_dsn_r(N, subj);
}

@h Compilation.
Deep breath now...

=
void RTKindConstructors::compile(void) {
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		if ((kc == CON_KIND_VARIABLE) || (kc == CON_INTERMEDIATE)) continue;
		kind *K = Kinds::base_construction(kc);
		package_request *pack = RTKindConstructors::package(kc);
		@<Make identification constants@>;
		@<Apply general metadata@>;
		@<Make constants, arrays and functions as needed@>;
		@<Apply further metadata needed only for indexing@>;
	}
	RTKindConstructors::apply_multiplication_rule_metadata();
}

@h Part I: Identification.

@<Make identification constants@> =
	@<Make cross-referencing constant@>;
	@<Make weak ID constant@>;

@<Make weak ID constant@> =
	Emit::numeric_constant(RTKindConstructors::weak_ID_iname(kc), 0);
	Hierarchy::make_available(RTKindConstructors::weak_ID_iname(kc));

@ See above: the value of this constant can be anything at all, since only
its position in the Inter hierarchy matters. But 561 is the smallest Carmichael
number, which is good enough for me.

@<Make cross-referencing constant@> =
	Emit::numeric_constant(RTKindConstructors::xref_iname(kc), 561);

@h Part II: General metadata.

@<Apply general metadata@> =
	@<Make weak and strong ID metadata@>;
	@<Apply conformance metadata@>;
	@<Apply name metadata@>;
	@<Apply location metadata, for kinds created in the source text@>;
	@<Apply declaration sequence number metadata@>;
	@<Apply specification metadata@>;
	@<Apply metadata categorising this kind in various ways@>;
	if (RTKindConstructors::is_subkind_of_object(kc)) {
		@<Apply kind metadata@>;
		@<Apply superkind metadata@>;
	}
	if (KindConstructors::is_an_enumeration(kc)) {
		@<Apply domain size metadata@>;
	}
	if ((Kinds::Behaviour::is_an_enumeration(K)) || (Kinds::Behaviour::is_object(K))) {
		@<Apply instance count metadata@>;
	}

@<Make weak and strong ID metadata@> =
	inter_name *weak_iname = RTKindIDs::weak_iname_of_constructor(kc);
	if (weak_iname == NULL) internal_error("no iname for weak ID");
	Hierarchy::apply_metadata_from_iname(pack, KIND_WEAK_ID_MD_HL, weak_iname);
	Hierarchy::apply_metadata_from_iname(pack, KIND_STRONG_ID_MD_HL,
		RTKindConstructors::weak_ID_iname(kc));

@ Four forms of the name: one always present, and a best effort to describe the
constructor wherever it came from; the second only present if a natural-language
form of the name exists; and the other two are more prettily printed for the index.

@<Apply name metadata@> =
	wording W = KindConstructors::get_name(kc, FALSE);
	if (Wordings::nonempty(W)) {
		Hierarchy::apply_metadata_from_wording(pack, KIND_NAME_MD_HL, W);
		Hierarchy::apply_metadata_from_raw_wording(pack, KIND_PNAME_MD_HL, W);
	} else if (Str::len(kc->explicit_identifier) > 0) {
		Hierarchy::apply_metadata(pack, KIND_NAME_MD_HL, kc->explicit_identifier);
	} else {
		Hierarchy::apply_metadata(pack, KIND_NAME_MD_HL, I"(anonymous kind)");
	}
	TEMPORARY_TEXT(SN)
	RTKindConstructors::index_name(SN, K, FALSE);
	if (Str::len(SN) > 0) Hierarchy::apply_metadata(pack, KIND_INDEX_SINGULAR_MD_HL, SN);
	DISCARD_TEXT(SN)
	TEMPORARY_TEXT(PN)
	RTKindConstructors::index_name(PN, K, TRUE);
	if (Str::len(PN) > 0) Hierarchy::apply_metadata(pack, KIND_INDEX_PLURAL_MD_HL, PN);
	DISCARD_TEXT(PN)

@<Apply location metadata, for kinds created in the source text@> =
	if (kc->where_defined_in_source_text)
		Hierarchy::apply_metadata_from_number(pack, KIND_AT_MD_HL,
			(inter_ti) Wordings::first_wn(Node::get_text(kc->where_defined_in_source_text)));

@<Apply declaration sequence number metadata@> =
	if (kc->compilation_data.declaration_sequence_number >= 0)
		Hierarchy::apply_metadata_from_number(pack, KIND_DECLARATION_ORDER_MD_HL,
			(inter_ti) kc->compilation_data.declaration_sequence_number);

@ This text can come either from the value of the specification pseudo-property,
or can come from the Neptune file creating a kind.

@<Apply specification metadata@> =
	inference *inf;
	int made_exp = FALSE;
	KNOWLEDGE_LOOP(inf, KindSubjects::from_kind(K), property_inf)
		if (PropertyInferences::get_property(inf) == P_specification) {
			parse_node *spec = PropertyInferences::get_value(inf);
			TEMPORARY_TEXT(exp)
			IndexUtilities::dequote(exp,
				Lexer::word_raw_text(Wordings::first_wn(Node::get_text(spec))));
			Hierarchy::apply_metadata(pack, KIND_SPECIFICATION_MD_HL, exp);
			DISCARD_TEXT(exp)
			made_exp = TRUE;
			break;
		}
	if ((made_exp == FALSE) && (RTKindConstructors::is_subkind_of_object(kc) == FALSE)) {
		text_stream *exp = Kinds::Behaviour::get_specification_text(K);
		if (Str::len(exp) > 0)
			Hierarchy::apply_metadata(pack, KIND_SPECIFICATION_MD_HL, exp);
	}

@<Apply metadata categorising this kind in various ways@> =
	if (KindConstructors::is_base(kc))
		Hierarchy::apply_metadata_from_number(pack, KIND_IS_BASE_MD_HL, 1);
	if (KindConstructors::is_proper_constructor(kc))
		Hierarchy::apply_metadata_from_number(pack, KIND_IS_PROPER_MD_HL, 1);
	if (KindConstructors::is_arithmetic(kc))
		Hierarchy::apply_metadata_from_number(pack, KIND_IS_QUASINUMERICAL_MD_HL, 1);
	if (RTKindConstructors::is_object(kc))
		Hierarchy::apply_metadata_from_number(pack, KIND_IS_OBJECT_MD_HL, 1);
	if (RTKindConstructors::is_subkind_of_object(kc))
		Hierarchy::apply_metadata_from_number(pack, KIND_IS_SKOO_MD_HL, 1);
	if (KindConstructors::is_definite(kc))
		Hierarchy::apply_metadata_from_number(pack, KIND_IS_DEF_MD_HL, 1);
	if (KindConstructors::uses_block_values(kc))
		Hierarchy::apply_metadata_from_number(pack, KIND_HAS_BV_MD_HL, 1);
	if (Deferrals::has_finite_domain(K))
		Hierarchy::apply_metadata_from_number(pack, KIND_FINITE_DOMAIN_MD_HL, 1);
	if ((KindSubjects::has_properties(K)) &&
		(RTKindConstructors::is_nonstandard_enumeration(K) == FALSE)) 
		Hierarchy::apply_metadata_from_number(pack, KIND_HAS_PROPERTIES_MD_HL, 1);
	if (Kinds::Behaviour::is_understandable(K))
		Hierarchy::apply_metadata_from_number(pack, KIND_UNDERSTANDABLE_MD_HL, 1);
	if (Kinds::eq(K, K_players_holdall))
		Hierarchy::apply_metadata_from_number(pack, RUCKSACK_CLASS_MD_HL, 1);

@<Apply kind metadata@> =
	Hierarchy::apply_metadata_from_iname(pack,
		KIND_CLASS_MD_HL, RTKindDeclarations::iname(Kinds::base_construction(kc)));

@<Apply superkind metadata@> =
	kind *super_K = Latticework::super(K);
	TEMPORARY_TEXT(SK)
	WRITE_TO(SK, "%u", super_K);
	Hierarchy::apply_metadata(pack, INDEX_SUPERKIND_MD_HL, SK);
	DISCARD_TEXT(SK)
	Hierarchy::apply_metadata_from_iname(pack, SUPERKIND_MD_HL,
		RTKindConstructors::weak_ID_iname(super_K->construct));

@<Apply domain size metadata@> =
	Hierarchy::apply_metadata_from_number(pack, KIND_DSIZE_MD_HL,
		(inter_ti) RTKindConstructors::enumeration_size(K));

@<Apply instance count metadata@> =
	if (Instances::count(K) > 0)
		Hierarchy::apply_metadata_from_number(pack, KIND_INSTANCE_COUNT_MD_HL,
			(inter_ti) Instances::count(K));

@h Part III: Constants, arrays and functions.

@<Make constants, arrays and functions as needed@> =
	if ((Kinds::Behaviour::is_an_enumeration(K)) || (Kinds::Behaviour::is_object(K))) {
		@<Make icount constant@>;
		if (RTKindConstructors::is_nonstandard_enumeration(K)) {
			@<Make instances array@>;
		}
		if (Kinds::eq(K, K_room)) {
			@<Make FW-matrix size constant@>;
			@<Make NUM_ROOMS constant@>;
		}
		if (Kinds::eq(K, K_door)) {
			@<Make NUM_DOORS constant@>;
		}
	}
	if (Kinds::Behaviour::is_an_enumeration(K)) {
		@<Compile the increment and decrement functions for an enumerated kind@>;
		@<Compile random-value function for this kind@>;
		@<Compile indexing function for this kind@>;
	}
	if ((Kinds::Behaviour::is_built_in(K) == FALSE) &&
		(Kinds::Behaviour::is_quasinumerical(K))) {
		@<Compile random-value function for this kind@>;
	}
	if (KindConstructors::uses_block_values(kc)) {
		@<Apply support function metadata@>;
	}
	if ((RTKindConstructors::is_subkind_of_object(kc) == FALSE) &&
		(KindConstructors::is_definite(kc)) &&
		(KindConstructors::uses_signed_comparisons(kc) == FALSE)) {
		@<Apply comparison function metadata@>;
	}
	if (Kinds::Behaviour::definite(K)) {
		@<Apply make-default-value function metadata@>;
		@<Compile make-default-value function@>;
	}
	if (RTKindConstructors::is_subkind_of_object(kc) == FALSE) {
		@<Apply printing function metadata@>;
		if (Kinds::Behaviour::is_an_enumeration(K)) {
			@<Compile printing function for an enumerated kind@>;
		}
		if ((Kinds::Behaviour::is_built_in(K) == FALSE) &&
			(Kinds::Behaviour::is_an_enumeration(K) == FALSE)) {
			if (Kinds::Behaviour::is_quasinumerical(K)) {
				@<Compile printing function for a unit kind@>;
			} else {
				@<Compile printing function for a vacant but named kind@>;
			}
		}
	}
	if ((Kinds::Behaviour::is_object(K)) && (RTShowmeCommand::needed_for_kind(K))) {
		@<Apply SHOWME function metadata@>;
		@<Compile SHOWME function@>;
	}
	if ((RTKindConstructors::GPR_compilation_enabled()) &&
		(RTKindConstructors::GPR_provided_by_kit(K) == FALSE)) {
		if (Kinds::Behaviour::is_an_enumeration(K)) {
			@<Compile enumeration GPR@>;
		} else if (Kinds::Behaviour::is_quasinumerical(K)) {
			@<Compile quasinumerical GPR@>;
		}
	}

@<Make icount constant@> =
	inter_name *iname = RTKindConstructors::icount_iname(K);
	Emit::numeric_constant(iname, (inter_ti) Instances::count(K));

@<Make instances array@> =
	inter_name *array_iname = RTKindConstructors::instances_array_iname(K);
	Hierarchy::make_available(array_iname);
	packaging_state save = EmitArrays::begin_word(array_iname, K_value);
	EmitArrays::numeric_entry((inter_ti) Instances::count(K));
	RTKindConstructors::make_enumeration_entries(K);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	Hierarchy::apply_metadata_from_iname(RTKindConstructors::kind_package(K),
		ENUMERATION_ARRAY_MD_HL, array_iname);

@ This improbable-looking constant is the size of storage to allocate for the
route-finding algorithm in |WorldModelKit|. If the fast algorithm is used,
more storage is needed than for the slow one, and the default choice is fast
on 32-bit platforms, slow on 16-bit, where memory is scarcer. We're declaring
the constant here because this is too tricky a bit of conditional compilation
to be handled inside the kit itself.

@<Make FW-matrix size constant@> =
	inter_name *iname = 
		Hierarchy::make_iname_in(FWMATRIX_SIZE_HL, RTKindConstructors::kind_package(K));
	Hierarchy::make_available(iname);
	inter_ti val = 0;
	if (TargetVMs::is_16_bit(Task::vm()) == FALSE)
		val = (inter_ti) (Instances::count(K)*Instances::count(K));
	if (global_compilation_settings.fast_route_finding)
		val = (inter_ti) (Instances::count(K)*Instances::count(K));
	if (global_compilation_settings.slow_route_finding)
		val = 0;
	if (val <= 1) val = 2;
	Emit::numeric_constant(iname, (inter_ti) val);

@<Make NUM_DOORS constant@> =
	inter_name *iname = 
		Hierarchy::make_iname_in(NUM_DOORS_HL, RTKindConstructors::kind_package(K));
	Hierarchy::make_available(iname);
	Emit::numeric_constant(iname, (inter_ti) Instances::count(K));

@<Make NUM_ROOMS constant@> =
	inter_name *iname = 
		Hierarchy::make_iname_in(NUM_ROOMS_HL, RTKindConstructors::kind_package(K));
	Hierarchy::make_available(iname);
	Emit::numeric_constant(iname, (inter_ti) Instances::count(K));

@ The suite of standard routines provided for enumerative types is a little
like the one in Ada (|T'Succ|, |T'Pred|, and so on).

If the type is called, say, |T1_colour|, then we have:

(a) |A_T1_colour(v)| advances to the next valid value for the type,
wrapping around to the first from the last;
(b) |B_T1_colour(v)| goes back to the previous valid value for the type,
wrapping around to the last from the first, so that it is the inverse function
to |A_T1_colour(v)|.

@<Compile the increment and decrement functions for an enumerated kind@> =
	int instance_count = Instances::count(K);

	inter_name *iname_i = RTKindConstructors::increment_fn_iname(K);
	packaging_state save = Functions::begin(iname_i);
	@<Implement the A routine@>;
	Functions::end(save);

	inter_name *iname_d = RTKindConstructors::decrement_fn_iname(K);
	save = Functions::begin(iname_d);
	@<Implement the B routine@>;
	Functions::end(save);

@ There should be a blue historical plaque on the wall here: this was the
first function ever implemented by emitting Inter code, on 12 November 2017.

@<Implement the A routine@> =
	local_variable *lv_x = LocalVariables::new_other_parameter(I"x");
	LocalVariables::set_kind(lv_x, K);
	inter_symbol *x = LocalVariables::declare(lv_x);

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();

	if (instance_count <= 1) {
		EmitCode::val_symbol(K, x);
	} else if (RTKindConstructors::is_nonstandard_enumeration(K)) {
		EmitCode::call(Hierarchy::find(NEXT_ENUM_VAL_HL));
		EmitCode::down();
			EmitCode::val_symbol(K, x);
			EmitCode::val_iname(K_value, RTKindConstructors::instances_array_iname(K));
		EmitCode::up();
	} else {
		EmitCode::cast(K_number, K);
		EmitCode::down();
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(MODULO_BIP);
				EmitCode::down();
					EmitCode::cast(K, K_number);
					EmitCode::down();
						EmitCode::val_symbol(K, x);
					EmitCode::up();
					EmitCode::val_number((inter_ti) instance_count);
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
	}

	EmitCode::up();

@ And this was the second, a few minutes later.

@<Implement the B routine@> =
	local_variable *lv_x = LocalVariables::new_other_parameter(I"x");
	LocalVariables::set_kind(lv_x, K);
	inter_symbol *x = LocalVariables::declare(lv_x);

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();

	if (instance_count <= 1) {
		EmitCode::val_symbol(K, x);
	} else if (RTKindConstructors::is_nonstandard_enumeration(K)) {
		EmitCode::call(Hierarchy::find(PREV_ENUM_VAL_HL));
		EmitCode::down();
			EmitCode::val_symbol(K, x);
			EmitCode::val_iname(K_value, RTKindConstructors::instances_array_iname(K));
		EmitCode::up();
	} else {
		EmitCode::cast(K_number, K);
		EmitCode::down();
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(MODULO_BIP);
				EmitCode::down();

				if (instance_count > 2) {
					EmitCode::inv(PLUS_BIP);
					EmitCode::down();
						EmitCode::cast(K, K_number);
						EmitCode::down();
							EmitCode::val_symbol(K, x);
						EmitCode::up();
						EmitCode::val_number((inter_ti) instance_count-2);
					EmitCode::up();
				} else {
					EmitCode::cast(K, K_number);
					EmitCode::down();
						EmitCode::val_symbol(K, x);
					EmitCode::up();
				}

					EmitCode::val_number((inter_ti) instance_count);
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
	}

	EmitCode::up();

@ And here we add:

(a) |R_T1_colour()| returns a uniformly random choice of the valid
values of the given type. (For a unit, this will be a uniformly random positive
value, which will probably not be useful.)
(b) |R_T1_colour(a, b)| returns a uniformly random choice in between |a|
and |b| inclusive.

@<Compile random-value function for this kind@> =
	inter_name *iname_r = RTKindConstructors::random_value_fn_iname(K);
	packaging_state save = Functions::begin(iname_r);
	inter_symbol *a_s = LocalVariables::new_other_as_symbol(I"a");
	inter_symbol *b_s = LocalVariables::new_other_as_symbol(I"b");

	if (RTKindConstructors::is_nonstandard_enumeration(K)) {
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::call(Hierarchy::find(RANDOM_ENUM_VAL_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindConstructors::instances_array_iname(K));
				EmitCode::val_symbol(K_value, a_s);
				EmitCode::val_symbol(K_value, b_s);
			EmitCode::up();
		EmitCode::up();
	} else {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, a_s);
					EmitCode::val_number(0);
				EmitCode::up();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, b_s);
					EmitCode::val_number(0);
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::inv(RANDOM_BIP);
					EmitCode::down();
						if (Kinds::Behaviour::is_quasinumerical(K))
							EmitCode::val_iname(K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
						else
							EmitCode::val_number((inter_ti) RTKindConstructors::enumeration_size(K));
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, a_s);
				EmitCode::val_symbol(K_value, b_s);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, b_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		inter_symbol *smaller = NULL, *larger = NULL;

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(GT_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, a_s);
				EmitCode::val_symbol(K_value, b_s);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					smaller = b_s; larger = a_s;
					@<Formula for range@>;
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			smaller = a_s; larger = b_s;
			@<Formula for range@>;
		EmitCode::up();
	}
	Functions::end(save);

@<Formula for range@> =
	EmitCode::inv(PLUS_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, smaller);
		EmitCode::inv(MODULO_BIP);
		EmitCode::down();
			EmitCode::inv(RANDOM_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
			EmitCode::up();
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(MINUS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, larger);
					EmitCode::val_symbol(K_value, smaller);
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<Compile indexing function for this kind@> =
	inter_name *iname_r = RTKindConstructors::indexing_fn_iname(K);
	packaging_state save = Functions::begin(iname_r);
	inter_symbol *a_s = LocalVariables::new_other_as_symbol(I"a");

	if (RTKindConstructors::is_nonstandard_enumeration(K)) {
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::call(Hierarchy::find(INDEX_OF_ENUM_VAL_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindConstructors::instances_array_iname(K));
				EmitCode::val_symbol(K_value, a_s);
			EmitCode::up();
		EmitCode::up();
	} else {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(OR_BIP);
			EmitCode::down();
				EmitCode::inv(LT_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, a_s);
					EmitCode::val_number(0);
				EmitCode::up();
				EmitCode::inv(GT_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, a_s);
					EmitCode::val_number((inter_ti) RTKindConstructors::enumeration_size(K));
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_number(0);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, a_s);
		EmitCode::up();
	}
	Functions::end(save);

@<Apply support function metadata@> =
	inter_name *iname = RTKindConstructors::support_fn_iname(K);
	if (iname) Hierarchy::apply_metadata_from_iname(pack, KIND_SUPPORT_FN_MD_HL, iname);
	else internal_error("kind with block values but no support function");

@<Apply comparison function metadata@> =
	inter_name *iname = RTKindConstructors::comparison_fn_iname(K);
	if (iname) Hierarchy::apply_metadata_from_iname(pack, KIND_CMP_FN_MD_HL, iname);
	else internal_error("kind with no comparison function");

@<Apply make-default-value function metadata@> =
	inter_name *iname = RTKindConstructors::default_value_fn_iname(kc);
	Hierarchy::apply_metadata_from_iname(pack, KIND_MKDEF_FN_MD_HL, iname);

@<Compile make-default-value function@> =
	inter_name *default_value_fn_iname = RTKindConstructors::default_value_fn_iname(kc);
	packaging_state save = Functions::begin(default_value_fn_iname);
	inter_symbol *sk_s = LocalVariables::new_other_as_symbol(I"sk");
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		if (KindConstructors::uses_block_values(kc)) {
			inter_name *iname = Hierarchy::find(BLKVALUECREATE_HL);
			EmitCode::call(iname);
			EmitCode::down();
				EmitCode::val_symbol(K_value, sk_s);
			EmitCode::up();
		} else {
			if (RTKindConstructors::is_subkind_of_object(kc))
				EmitCode::val_false();
			else
				DefaultValues::val(Kinds::base_construction(kc),
					EMPTY_WORDING, "default value");
		}
	EmitCode::up();
	Functions::end(save);

@<Apply printing function metadata@> =
	inter_name *printing_rule_name =
		RTKindConstructors::printing_fn_iname(Kinds::base_construction(kc));
	if (printing_rule_name)
		Hierarchy::apply_metadata_from_iname(pack, KIND_PRINT_FN_MD_HL,
			printing_rule_name);

@ A slightly bogus printing function first. If the source text declares a kind
but never gives any enumerated values or literal patterns, then such values will
never appear at run-time; but we need the printing routine to exist to avoid
compilation errors.

@<Compile printing function for a vacant but named kind@> =
	inter_name *printing_rule_name = RTKindConstructors::printing_fn_iname(K);
	packaging_state save = Functions::begin(printing_rule_name);
	inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "weak kind ID: %n\n", RTKindIDs::weak_iname(K));
	EmitCode::comment(C);
	DISCARD_TEXT(C)
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, value_s);
	EmitCode::up();
	Functions::end(save);

@ A unit is printed back with its earliest-defined literal pattern used as
notation. If it had no literal patterns, it would come out as decimal numbers,
but at present this can't happen.

@<Compile printing function for a unit kind@> =
	inter_name *printing_rule_name = RTKindConstructors::printing_fn_iname(K);
	if (LiteralPatterns::list_of_literal_forms(K))
		RTLiteralPatterns::printing_routine(printing_rule_name,
			LiteralPatterns::list_of_literal_forms(K));
	else {
		packaging_state save = Functions::begin(printing_rule_name);
		inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, value_s);
		EmitCode::up();
		Functions::end(save);
	}

@<Compile printing function for an enumerated kind@> =
	inter_name *printing_rule_name = RTKindConstructors::printing_fn_iname(K);
	packaging_state save = Functions::begin(printing_rule_name);
	inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");

	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, value_s);
		EmitCode::code();
		EmitCode::down();
			instance *I;
			LOOP_OVER_INSTANCES(I, K) {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, RTInstances::value_iname(I));
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(PRINT_BIP);
						EmitCode::down();
							TEMPORARY_TEXT(CT)
							wording NW = Instances::get_name_in_play(I, FALSE);
							LOOP_THROUGH_WORDING(k, NW) {
								TranscodeText::from_wide_string(CT, Lexer::word_raw_text(k), CT_RAW);
								if (k < Wordings::last_wn(NW)) WRITE_TO(CT, " ");
							}
							EmitCode::val_text(CT);
							DISCARD_TEXT(CT)
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			}
			EmitCode::inv(DEFAULT_BIP); /* this default case should never be needed */
			EmitCode::down();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						TEMPORARY_TEXT(DT)
						wording W = Kinds::Behaviour::get_name(K, FALSE);
						WRITE_TO(DT, "<illegal ");
						if (Wordings::nonempty(W)) WRITE_TO(DT, "%W", W);
						else WRITE_TO(DT, "value");
						WRITE_TO(DT, ">");
						EmitCode::val_text(DT);
						DISCARD_TEXT(DT)
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	Functions::end(save);

@<Apply SHOWME function metadata@> =
	inter_name *iname = RTKindConstructors::showme_fn_iname(K);
	Hierarchy::apply_metadata_from_iname(RTKindConstructors::kind_package(K),
		KIND_SHOWME_MD_HL, iname);

@<Compile SHOWME function@> =
	inter_name *iname = RTKindConstructors::showme_fn_iname(K);
	RTShowmeCommand::compile_kind_showme_fn(iname, K);

@<Compile enumeration GPR@> =
	text_stream *desc = Str::new();
	WRITE_TO(desc, "GPR for enumeration kind %u", K);
	Sequence::queue(&KindGPRs::enumeration_agent, STORE_POINTER_kind(K), desc);

@<Compile quasinumerical GPR@> =
	text_stream *desc = Str::new();
	WRITE_TO(desc, "GPR for quasinumerical kind %u", K);
	Sequence::queue(&KindGPRs::quasinumerical_agent, STORE_POINTER_kind(K), desc);

@<Apply conformance metadata@> =
	kind *K2;
	LOOP_OVER_BASE_KINDS(K2) {
		if ((Kinds::Behaviour::is_kind_of_kind(K2)) && (Kinds::conforms_to(K, K2))
			 && (Kinds::eq(K2, K_pointer_value) == FALSE)
			 && (Kinds::eq(K2, K_stored_value) == FALSE)) {
			package_request *R =
				Hierarchy::package_within(KIND_CONFORMANCE_HAP, pack);
			Hierarchy::apply_metadata_from_iname(R, CONFORMED_TO_MD_HL,
				RTKindConstructors::xref_iname(K2->construct));
		}
	}

@h Part IV: Indexing metadata.

@<Apply further metadata needed only for indexing@> =
	@<Apply documentation reference metadata@>;
	if (Kinds::is_proper_constructor(K)) {
		@<Apply variance metadata for the index@>;
	}
	@<Apply priority metadata for the index@>;
	@<Apply shading metadata for the index@>;
	@<Apply default value metadata for the index@>;
	if ((Kinds::Behaviour::is_quasinumerical(K)) && (Kinds::is_intermediate(K) == FALSE)) {
		@<Apply maximum and minimum values metadata for the index@>;
		@<Apply dimensions metadata for the index@>;
	}
	@<Apply literal notation metadata for the index@>;
	@<Apply inferences metadata for the index@>;

@ A documentation reference can be supplied literally by a Neptune file, or
can be implicit in the name of the kind.

@<Apply documentation reference metadata@> =
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		wording W = Kinds::Behaviour::get_name(K, FALSE);
		if (Wordings::nonempty(W)) {
			TEMPORARY_TEXT(temp)
			WRITE_TO(temp, "kind_%N", Wordings::first_wn(W));
			if (DocReferences::validate_if_possible(temp))
				Kinds::Behaviour::set_documentation_reference(K, temp);
			DISCARD_TEXT(temp)
		}
	}
	text_stream *DR = Kinds::Behaviour::get_documentation_reference(K);
	if (Str::len(DR) > 0)
		Hierarchy::apply_metadata(pack, KIND_DOCUMENTATION_MD_HL, DR);

@ This is just a textual description of what's going on with the terms
in a constructor, for the index.

@<Apply variance metadata for the index@> =
	TEMPORARY_TEXT(CONS)
	int i, a = KindConstructors::arity(Kinds::get_construct(K));
	if ((a == 2) &&
		(KindConstructors::variance(Kinds::get_construct(K), 0) ==
			KindConstructors::variance(Kinds::get_construct(K), 1)))
		a = 1;
	for (i=0; i<a; i++) {
		if (i > 0) WRITE_TO(CONS, ", ");
		if (KindConstructors::variance(Kinds::get_construct(K), i) > 0)
			WRITE_TO(CONS, "covariant");
		else
			WRITE_TO(CONS, "contravariant");
		if (a > 1) WRITE_TO(CONS, " in %c", 'K'+i);
	}
	Hierarchy::apply_metadata(pack, KIND_INDEX_VARIANCE_MD_HL, CONS);
	DISCARD_TEXT(CONS)	

@<Apply priority metadata for the index@> =
	Hierarchy::apply_metadata_from_number(pack, KIND_INDEX_PRIORITY_MD_HL,
		(inter_ti) Kinds::Behaviour::get_index_priority(K));

@<Apply shading metadata for the index@> =
	if ((RTKindConstructors::enumeration_size(K) == 0) &&
		(Kinds::Behaviour::indexed_grey_if_empty(K)))
		Hierarchy::apply_metadata_from_number(pack, KIND_SHADED_MD_HL, 1);

@<Apply default value metadata for the index@> =
	TEMPORARY_TEXT(IDV)
	instance *I;
	LOOP_OVER_INSTANCES(I, K) {
		Instances::write_name(IDV, I);
		break;
	}
	if (Str::len(IDV) == 0) {
		text_stream *text = Kinds::Behaviour::get_index_default_value(K);
		if (Str::eq(text, I"<0-in-literal-pattern>"))
			@<Index the constant 0 but use the default literal pattern@>
		else if (Str::eq(text, I"<first-constant>"))
			WRITE_TO(IDV, "--");
		else
			WRITE_TO(IDV, "%S", text);
	}
	Hierarchy::apply_metadata(pack, KIND_INDEX_DEFAULT_MD_HL, IDV);
	DISCARD_TEXT(IDV)

@ For every quasinumeric kind the default value is 0, but we don't want to
index just "0" because that means 0-as-a-number: we want it to come out
as "0 kg", "0 hectares", or whatever is appropriate.

@<Index the constant 0 but use the default literal pattern@> =
	if (LiteralPatterns::list_of_literal_forms(K))
		LiteralPatterns::index_value(IDV,
			LiteralPatterns::list_of_literal_forms(K), 0);
	else
		WRITE_TO(IDV, "--");

@<Apply maximum and minimum values metadata for the index@> =
	TEMPORARY_TEXT(OUT)
	@<Index the minimum positive value for a quasinumerical kind@>;
	Hierarchy::apply_metadata(pack, MIN_VAL_INDEX_MD_HL, OUT);
	Str::clear(OUT);
	@<Index the maximum positive value for a quasinumerical kind@>;
	Hierarchy::apply_metadata(pack, MAX_VAL_INDEX_MD_HL, OUT);
	Str::clear(OUT);
	DISCARD_TEXT(OUT)

@<Index the minimum positive value for a quasinumerical kind@> =
	if (Kinds::eq(K, K_number)) WRITE("1");
	else {
		text_stream *p = Kinds::Behaviour::get_index_minimum_value(K);
		if (Str::len(p) > 0) WRITE("%S", p);
		else LiteralPatterns::index_value(OUT,
			LiteralPatterns::list_of_literal_forms(K), 1);
	}

@<Index the maximum positive value for a quasinumerical kind@> =
	if (Kinds::eq(K, K_number)) {
		if (TargetVMs::is_16_bit(Task::vm())) WRITE("32767");
		else WRITE("2147483647");
	} else {
		text_stream *p = Kinds::Behaviour::get_index_maximum_value(K);
		if (Str::len(p) > 0) WRITE("%S", p);
		else {
			if (TargetVMs::is_16_bit(Task::vm()))
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(K), 32767);
			else
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(K), 2147483647);
		}
	}

@<Apply dimensions metadata for the index@> =
	TEMPORARY_TEXT(OUT)
	if (Kinds::Dimensions::dimensionless(K) == FALSE) {
		unit_sequence *deriv = Kinds::Behaviour::get_dimensional_form(K);
		Kinds::Dimensions::index_unit_sequence(OUT, deriv, TRUE);
	}
	Hierarchy::apply_metadata(pack, DIMENSIONS_INDEX_MD_HL, OUT);
	DISCARD_TEXT(OUT)

@<Apply literal notation metadata for the index@> =
	if (LiteralPatterns::list_of_literal_forms(K)) {
		TEMPORARY_TEXT(LF)
		LiteralPatterns::index_all(LF, K);
		Hierarchy::apply_metadata(pack, KIND_INDEX_NOTATION_MD_HL, LF);
		DISCARD_TEXT(LF)
	}

@<Apply inferences metadata for the index@> =
	RTInferences::index(pack, KIND_BRIEF_INFERENCES_MD_HL, KindSubjects::from_kind(K), TRUE);
	RTInferences::index(pack, KIND_INFERENCES_MD_HL, KindSubjects::from_kind(K), FALSE);

@h Pretty-printing names for the index.

=
void RTKindConstructors::index_name(OUTPUT_STREAM, kind *K, int plural) {
	wording W = Kinds::Behaviour::get_name(K, plural);
	if (Wordings::nonempty(W)) {
		if (Kinds::is_proper_constructor(K)) {
			@<Index the constructor text@>;
		} else {
			WRITE("%W", W);
		}
	}
}

@<Index the constructor text@> =
	int length = Wordings::length(W), w1 = Wordings::first_wn(W), tinted = TRUE;
	int i, first_stroke = -1, last_stroke = -1;
	for (i=0; i<length; i++) {
		if (Lexer::word(w1+i) == STROKE_V) {
			if (first_stroke == -1) first_stroke = i;
			last_stroke = i;
		}
	}
	int from = 0, to = length-1;
	if (last_stroke >= 0) from = last_stroke+1; else tinted = FALSE;
	if (tinted) HTML::begin_span(OUT, I"indexgrey");
	for (i=from; i<=to; i++) {
		int j, untinted = FALSE;
		for (j=0; j<first_stroke; j++)
			if (Lexer::word(w1+j) == Lexer::word(w1+i))
				untinted = TRUE;
		if (untinted) HTML::end_span(OUT);
		if (i>from) WRITE(" ");
		if (Lexer::word(w1+i) == CAPITAL_K_V) WRITE("K");
		else if (Lexer::word(w1+i) == CAPITAL_L_V) WRITE("L");
		else WRITE("%V", Lexer::word(w1+i));
		if (untinted) HTML::begin_span(OUT, I"indexgrey");
	}
	if (tinted) HTML::end_span(OUT);

@h Metadata about multiplication.
This is used only for indexing.

=
void RTKindConstructors::apply_multiplication_rule_metadata(void) {
	kind *L, *R, *O;
	int wn;
	LOOP_OVER_MULTIPLICATIONS(L, R, O, wn) {
		package_request *pack = Hierarchy::completion_package(MULTIPLICATION_RULE_HAP);
		if (wn >= 0) Hierarchy::apply_metadata_from_number(pack, SET_AT_MD_HL, (inter_ti) wn);
		TEMPORARY_TEXT(OUT)
		WRITE_TO(OUT, "%u", L);
		Hierarchy::apply_metadata(pack, LEFT_OPERAND_MD_HL, OUT);
		Str::clear(OUT);
		WRITE_TO(OUT, "%u", R);
		Hierarchy::apply_metadata(pack, RIGHT_OPERAND_MD_HL, OUT);
		Str::clear(OUT);
		WRITE_TO(OUT, "%u", O);
		Hierarchy::apply_metadata(pack, RESULT_MD_HL, OUT);
		Str::clear(OUT);
		LiteralPatterns::index_benchmark_value(OUT, L);
		Hierarchy::apply_metadata(pack, LEFT_OPERAND_BM_MD_HL, OUT);
		Str::clear(OUT);
		LiteralPatterns::index_benchmark_value(OUT, R);
		Hierarchy::apply_metadata(pack, RIGHT_OPERAND_BM_MD_HL, OUT);
		Str::clear(OUT);
		LiteralPatterns::index_benchmark_value(OUT, O);
		Hierarchy::apply_metadata(pack, RESULT_BM_MD_HL, OUT);
		DISCARD_TEXT(OUT)
	}
}

@h Property permissions for kinds.

=
void RTKindConstructors::compile_permissions(void) {
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		if ((kc == CON_KIND_VARIABLE) || (kc == CON_INTERMEDIATE)) continue;
		kind *K = Kinds::base_construction(kc);
		if (RTKindDeclarations::base_represented_in_Inter(K)) {
			RTPropertyPermissions::emit_kind_permissions(K);
			RTPropertyValues::compile_values_for_kind(K);
		}
	}
}
