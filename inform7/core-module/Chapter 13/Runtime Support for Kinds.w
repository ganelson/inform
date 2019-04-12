[Kinds::RunTime::] Runtime Support for Kinds.

To compile I6 material needed at runtime to enable kinds
to function as they should.

@h Definitions.

@ In order to be able to give a reasonably complete description of a kind of
value at run-time, we need to store small data structures describing them,
and the following keeps track of which ones we need to make:

=
typedef struct runtime_kind_structure {
	struct kind *kind_described;
	struct parse_node *default_requested_here;
	int make_default;
	struct inter_name *rks_iname;
	struct inter_name *rks_dv_iname;
	MEMORY_MANAGEMENT
} runtime_kind_structure;

@h Kinds as I6 classes.
The noun is used to store the "classname" and "class-number". In the
compiled I6 code, some kinds will correspond to classes with systematic
names like |K24_musical_instrument|. The number 24 appearing there is the
class number; the whole text is the classname. These are used only for those
kinds being compiled to an I6 |Class|.

=
inter_name *Kinds::RunTime::I6_classname(kind *K) {
	if (Kinds::Compare::le(K, K_object)) return Kinds::RunTime::iname(K);
	internal_error("no I6 classname available");
	return NULL;
}

int Kinds::RunTime::I6_classnumber(kind *K) {
	noun *nt = Kinds::Behaviour::get_noun(K);
	if (nt == NULL) return 0;
	return Nouns::range_number(nt);
}

@h Default values.
When we create a new variable (or other storage object) of a given kind, but
never say what its value is to be, Inform tries to initialise it to the
"default value" for that kind.

The following should compile a default value for $K$, and return
(a) |TRUE| if it succeeded,
(b) |FALSE| if it failed (because $K$ had no values or no default could be
chosen), but no problem message has been issued about this, or
(c) |NOT_APPLICABLE| if it failed and issued a specific problem message.

=
int Kinds::RunTime::emit_default_value(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = Kinds::RunTime::compile_default_value_vh(&VH, K, W, storage_name);
	inter_t v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	Emit::array_generic_entry(v1, v2);
	return rv;
}
int Kinds::RunTime::emit_default_value_as_val(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = Kinds::RunTime::compile_default_value_vh(&VH, K, W, storage_name);
	Holsters::to_val_mode(&VH);
	return rv;
}
int Kinds::RunTime::compile_default_value_vh(value_holster *VH, kind *K,
	wording W, char *storage_name) {
	if (Kinds::Compare::eq(K, K_value))
		@<"Value" is too vague to be the kind of a variable@>;
	if (Kinds::Behaviour::definite(K) == FALSE)
		@<This is a kind not intended for end users at all@>;

	if ((Kinds::get_construct(K) == CON_list_of) ||
		(Kinds::Compare::eq(K, K_stored_action)) ||
		(Kinds::get_construct(K) == CON_phrase) ||
		(Kinds::get_construct(K) == CON_relation)) {
		if (Kinds::get_construct(K) == CON_list_of) {
			packaging_state save = Packaging::enter_current_enclosure();
			inter_name *N = Kinds::RunTime::begin_block_constant(K);
			inter_name *rks_symb = Kinds::RunTime::compile_default_value_inner(K);
			Emit::array_iname_entry(rks_symb);
			Emit::array_numeric_entry(0);
			Kinds::RunTime::end_block_constant(K);
			Packaging::exit(save);
			if (N) InterNames::holster(VH, N);
		} else if (Kinds::Compare::eq(K, K_stored_action)) {
			packaging_state save = Packaging::enter_current_enclosure();
			inter_name *N = Kinds::RunTime::begin_block_constant(K_stored_action);
			Kinds::RunTime::emit_block_value_header(K_stored_action, FALSE, 6);
			Emit::array_iname_entry(PL::Actions::double_sharp(PL::Actions::Wait()));
			Emit::array_numeric_entry(0);
			Emit::array_numeric_entry(0);
			#ifdef IF_MODULE
			Emit::array_iname_entry(Instances::iname(I_yourself));
			#endif
			#ifndef IF_MODULE
			Emit::array_numeric_entry(I"0");
			#endif
			Emit::array_numeric_entry(0);
			Emit::array_numeric_entry(0);
			Kinds::RunTime::end_block_constant(K_stored_action);
			Packaging::exit(save);
			if (N) InterNames::holster(VH, N);
		} else if (Kinds::get_construct(K) == CON_relation) {
			packaging_state save = Packaging::enter_current_enclosure();
			inter_name *N = Kinds::RunTime::begin_block_constant(K);
			Relations::compile_blank_relation(K);
			Kinds::RunTime::end_block_constant(K);
			Packaging::exit(save);
			if (N) InterNames::holster(VH, N);
		} else {
			inter_name *N = Kinds::RunTime::compile_default_value_inner(K);
			if (N) InterNames::holster(VH, N);
		}
		return TRUE;
	}

	if ((Kinds::get_construct(K) == CON_list_of) ||
		(Kinds::get_construct(K) == CON_phrase) ||
		(Kinds::get_construct(K) == CON_relation)) {
		inter_name *N = Kinds::RunTime::compile_default_value_inner(K);
		if (N) InterNames::holster(VH, N);
		return TRUE;
	}

	if (Kinds::Compare::eq(K, K_text)) {
		packaging_state save = Packaging::enter_current_enclosure();
		inter_name *N = Kinds::RunTime::begin_block_constant(K);
		Emit::array_iname_entry(InterNames::extern(PACKED_TEXT_STORAGE_EXNAMEF));
		Emit::array_iname_entry(InterNames::extern(EMPTY_TEXT_PACKED_EXNAMEF));
		Kinds::RunTime::end_block_constant(K);
		Packaging::exit(save);
		if (N) InterNames::holster(VH, N);
		return TRUE;
	}

	inter_t v1 = 0, v2 = 0;
	Kinds::RunTime::get_default_value(&v1, &v2, K);
	if (v1 != 0) {
		if (Holsters::data_acceptable(VH)) {
			Holsters::holster_pair(VH, v1, v2);
			return TRUE;
		}
		internal_error("thwarted on gdv inter");
	}

	if (Kinds::Compare::lt(K, K_object))
		@<The kind must have no instances, or it would have worked@>;

	return FALSE;
}

@<The kind must have no instances, or it would have worked@> =
	if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		Problems::quote_text(3, storage_name);
		Problems::Issue::handmade_problem(_p_(PM_EmptyKind2));
		Problems::issue_problem_segment(
			"I am unable to put any value into the %3 %1, which needs to be %2, "
			"because the world does not contain %2.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(2, K);
		Problems::Issue::handmade_problem(_p_(PM_EmptyKind));
		Problems::issue_problem_segment(
			"I am unable to find %2 to use here, because the world does not "
			"contain %2.");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@<This is a kind not intended for end users at all@> =
	if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		Problems::Issue::handmade_problem(_p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create %1 with the kind of value '%2', "
			"because this is a kind of value which is not allowed as "
			"something to be stored in properties, variables and the "
			"like. (See the Kinds index for which kinds of value "
			"are available. The ones which aren't available are really "
			"for internal use by Inform.)");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(1, K);
		Problems::Issue::handmade_problem(_p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create a value of the kind '%1' "
			"because this is a kind of value which is not allowed as "
			"something to be stored in properties, variables and the "
			"like. (See the Kinds index for which kinds of value "
			"are available. The ones which aren't available are really "
			"for internal use by Inform.)");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@<"Value" is too vague to be the kind of a variable@> =
	Problems::quote_wording_as_source(1, W);
	Problems::Issue::handmade_problem(_p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"I am unable to start %1 off with any value, because the "
		"instructions do not tell me what kind of value it should be "
		"(a number, a time, some text perhaps?).");
	Problems::issue_problem_end();
	return NOT_APPLICABLE;

@ This returns either valid I6 code for the value which is the default for
$K$, or else |NULL| if $K$ has no values, or no default can be chosen.

We bend the rules and allow |nothing| as the default value of all kinds of
objects when the source text is a roomless one used only to rerelease an old
I6 story file; this effectively suppresses problem messages which the
absence of rooms would otherwise result in.

=
void Kinds::RunTime::get_default_value(inter_t *v1, inter_t *v2, kind *K) {
	if (K == NULL) return;
	if (K->construct->stored_as) K = K->construct->stored_as;

	if (Kinds::Compare::eq(K, K_object)) { *v1 = LITERAL_IVAL; *v2 = 0; return; }

	instance *I;
	LOOP_OVER_INSTANCES(I, K) {
		inter_name *N = Instances::emitted_iname(I);
		inter_reading_state *IRS = Emit::IRS();
		InterNames::to_ival(IRS->read_into, IRS->current_package, v1, v2, N);
		return;
	}

	if (Kinds::Compare::lt(K, K_object)) {
		#ifdef IF_MODULE
		if (existing_story_file) { *v1 = LITERAL_IVAL; *v2 = 0; return; } /* see above */
		#endif
		return;
	}

	if (Kinds::Behaviour::is_an_enumeration(K)) return;

	if (Kinds::Compare::eq(K, K_rulebook_outcome)) {
		inter_reading_state *IRS = Emit::IRS();
		InterNames::to_ival(IRS->read_into, IRS->current_package, v1, v2, Rulebooks::Outcomes::get_default_value());
		return;
	}

	if (Kinds::Compare::eq(K, K_action_name)) {
		inter_name *wait = PL::Actions::double_sharp(PL::Actions::Wait());
		inter_reading_state *IRS = Emit::IRS();
		Inter::Symbols::to_data(IRS->read_into, IRS->current_package, InterNames::to_symbol(wait), v1, v2);
		return;
	}

	text_stream *name = K->construct->default_value;

	if (Str::len(name) == 0) return;

	inter_t val1 = 0, val2 = 0;
	if (Inter::Types::read_I6_decimal(name, &val1, &val2) == TRUE) {
		*v1 = val1; *v2 = val2; return;
	}

	inter_symbol *S = Emit::seek_symbol(Emit::main_scope(), name);
	if (S) {
		inter_reading_state *IRS = Emit::IRS();
		Inter::Symbols::to_data(IRS->read_into, IRS->current_package, S, v1, v2);
		return;
	}

	if (Str::eq(name, I"true")) { *v1 = LITERAL_IVAL; *v2 = 1; return; }
	if (Str::eq(name, I"false")) { *v1 = LITERAL_IVAL; *v2 = 0; return; }

	S = Emit::holding_symbol(Emit::main_scope(), name);
	if (S) {
		inter_reading_state *IRS = Emit::IRS();
		Inter::Symbols::to_data(IRS->read_into, IRS->current_package, S, v1, v2);
		return;
	}

	return;
}

@h Equality tests.
For most word-value kinds, it's easy to compare two values to see if they are
equal: all we need is the |==| operator. But for pointer-value kinds, that
would simply tell us whether they point to the same block of data on the
heap, whereas we need in fact to compare the blocks they point to. So the
kind system makes it possible for each individual kind to decide how values
should be compared, returning an I6 schema prototype to compare |*1| and |*2|.

What happens at run-time when we test to see if value V equals value W,
or change storage object S so that it now contains value T, depends on the
kind of values we are discussing. If there were only word-based values in
Inform (as was the case until September 2007), there would be little to
do here, as the comparison would simply compile to |V == W|, while the
storage would be a matter of either |S = W;| or some more exotic case
along the lines of |StorageRoutineWrite(S, W);|.

But once pointers to blocks are allowed, this becomes more interesting.
Now the comparison needs to be a deep one, that is, we want to test whether
two texts (say) have the same textual content -- not whether we are
holding two pointers to the same blocks in memory, which is what a simple
comparison would achieve. Such a test is called "deep comparison", and
similarly, we must assign by transferring the contents of the blocks of
data, not merely the pointer to them, which is a "deep copy".

=
text_stream *Kinds::RunTime::interpret_test_equality(kind *left, kind *right) {
	LOGIF(KIND_CHECKING, "Interpreting equality test of kinds $u, $u\n", left, right);

	if ((Kinds::Compare::eq(left, K_truth_state)) || (Kinds::Compare::eq(right, K_truth_state)))
		return I"(*1 && true) == (*2 && true)";

	kind_constructor *L = NULL, *R = NULL;
	if ((left) && (right)) { L = left->construct; R = right->construct; }

	kind_constructor_comparison_schema *dtcs;
	for (dtcs = L->first_comparison_schema; dtcs; dtcs = dtcs->next_comparison_schema) {
		if (Str::len(dtcs->comparator_unparsed) > 0) {
			dtcs->comparator = Kinds::Constructors::parse(dtcs->comparator_unparsed);
			Str::clear(dtcs->comparator_unparsed);
		}
		if (R == dtcs->comparator) return dtcs->comparison_schema;
	}

	if (Kinds::Constructors::uses_pointer_values(L)) {
		if (Kinds::Constructors::allow_word_as_pointer(L, R)) {
			pointer_allocation *pall =
				Frames::add_allocation(Kinds::base_construction(L),
					"*=-BlkValueCompare(*1, BlkValueCast(*##, *#2, *!2))==0");
			return Frames::pall_get_expanded_schema(pall);
		}
	}

	text_stream *cr = Kinds::Behaviour::get_comparison_routine(left);
	if ((Str::len(cr) == 0) ||
		(Str::eq_wide_string(cr, L"signed")) ||
		(Str::eq_wide_string(cr, L"UnsignedCompare"))) return I"*=-*1 == *2";
	return I"*=- *_1(*1, *2) == 0";
}

@h Casts at runtime.

=
int Kinds::RunTime::cast_call(OUTPUT_STREAM, kind *from, kind *to) {
	if (Kinds::Behaviour::cast_possible(from, to)) {
		if (Str::len(Kinds::Behaviour::get_name_in_template_code(to)) == 0) {
			WRITE("(");
			return TRUE;
		}
		if ((Kinds::FloatingPoint::uses_floating_point(from)) &&
			(Kinds::FloatingPoint::uses_floating_point(to))) {
			WRITE("(");
			return TRUE;
		}
		WRITE("%S_to_%S(",
			Kinds::Behaviour::get_name_in_template_code(from),
			Kinds::Behaviour::get_name_in_template_code(to));
		if (Kinds::Behaviour::uses_pointer_values(to)) {
			Frames::compile_allocation(OUT, to);
			WRITE(",");
		}
		return TRUE;
	}
	return FALSE;
}

int Kinds::RunTime::emit_cast_call(kind *from, kind *to, int *down) {
	if (Kinds::Behaviour::cast_possible(from, to)) {
		if (Str::len(Kinds::Behaviour::get_name_in_template_code(to)) == 0) {
			return TRUE;
		}
		if ((Kinds::FloatingPoint::uses_floating_point(from)) &&
			(Kinds::FloatingPoint::uses_floating_point(to))) {
			return TRUE;
		}
		TEMPORARY_TEXT(N);
		WRITE_TO(N, "%S_to_%S",
			Kinds::Behaviour::get_name_in_template_code(from),
			Kinds::Behaviour::get_name_in_template_code(to));
		inter_name *iname = InterNames::extern_name(N);
		DISCARD_TEXT(N);
		Emit::inv_call(InterNames::to_symbol(iname));
		*down = TRUE;
		Emit::down();
		if (Kinds::Behaviour::uses_pointer_values(to)) {
			Frames::emit_allocation(to);
		}
		return TRUE;
	}
	return FALSE;
}

@h IDs.
Sometimes a kind has to be stored as an I6 integer value at run-time. I6 is
typeless, so some of the routines and data structures in the I6 template need
these integer values to tell them what they are looking at. For instance, the
|ActionData| table records the kinds of the noun and second noun to which an
action applies.

We have two forms of description: strong and weak. Strong IDs really do
uniquely identify kinds, and thus distinguish "list of lists of texts" from
"list of numbers". Weak IDs are defined by:

Dogma. If a value $v$ has kind $K$, and we want to use it as a value
of kind $W$, then
(a) if $K$ and $W$ have different weak IDs then this is impossible;
(b) if they have equal weak IDs then run-time code can tell from $v$ alone
whether this is possible.

For instance, all objects have the same weak ID, but we can distinguish kinds
like "vehicle" by a test like |(v ofclass K27_vehicle)|; all lists have the
same weak ID, but the block of data for a list on the heap contains the strong
ID for the kind of list entries, so we can always find out dynamically what
sort of list it is.

(Intermediate kinds do not conform to Dogma, but this does not matter,
because they are made to order and are never assigned to storage objects
like variables. That's what makes them intermediate.)

Weak IDs have already appeared:

@d UNKNOWN_WEAK_ID 1

=
int Kinds::RunTime::weak_id(kind *K) {
	if (K == NULL) return UNKNOWN_WEAK_ID;
	return Kinds::Constructors::get_weak_ID(Kinds::get_construct(K));
}

@ And the following compiles an easier-on-the-eye form of the weak ID, but
which might occupy up to 31 characters, the maximum length of an I6 identifier:

=
void Kinds::RunTime::compile_weak_id(OUTPUT_STREAM, kind *K) {
	if (K == NULL) { WRITE("UNKNOWN_TY"); return; }
	kind_constructor *con = Kinds::get_construct(K);
	text_stream *sn = Kinds::Constructors::name_in_template_code(con);
	if (Str::len(sn) > 0) WRITE("%S", sn); else WRITE("%d", Kinds::RunTime::weak_id(K));
}

void Kinds::RunTime::emit_weak_id(kind *K) {
	if (K == NULL) { Emit::array_iname_entry(Kinds::Constructors::UNKNOWN_iname()); return; }
	kind_constructor *con = Kinds::get_construct(K);
	inter_name *iname = Kinds::Constructors::iname(con);
	if (iname) Emit::array_iname_entry(iname);
	else Emit::array_numeric_entry((inter_t) (Kinds::RunTime::weak_id(K)));
}

void Kinds::RunTime::emit_weak_id_as_val(kind *K) {
	if (K == NULL) internal_error("cannot emit null kind as val");
	kind_constructor *con = Kinds::get_construct(K);
	inter_name *iname = Kinds::Constructors::iname(con);
	if (iname) Emit::val_symbol(K_value, InterNames::to_symbol(iname));
	else Emit::val(K_value, LITERAL_IVAL, (inter_t) (Kinds::RunTime::weak_id(K)));
}

@ The strong ID is a faithful representation of the |kind| structure,
so we don't need access to its value for comparison purposes; we just need
to be able to compile it.

Clearly a single 16-bit integer isn't enough to represent the full range of
kinds. We could get closer to this if we used a trick like the one attributed to
Ritchie and Johnson in chapter 6.3 of the Dragon book (Aho, Sethi and Ullman,
"Compilers", 1986), where lower bits of a word store the base kind for the
underlying data and upper bits record constructors applied to this.

But instead we exploit the fact that integers and addresses are interchangeable
in I6. If a strong ID value |t| is in the range $1\leq t<H$, where $H$ is the
constant |BASE_KIND_HWM|, then it's an ID number in its own right. If not, it's
a pointer to a small array in memory: |t-->0| is the weak ID; |t-->1| is the
arity of the construction, which must be greater than 0 since otherwise we
wouldn't need the pointer; and |t-->2| and subsequent represent strong IDs
for the kinds constructed on. A simplification is that tuples are converted
out of their binary-tree structure into a flat list, which means that the
arity can be arbitrarily large and is not always 1 or 2.

For example, for a base kind like "number", the strong ID is the same as
the weak ID; both in this case will be equal to the compiled I6 constant |NUMBER_TY|.
But for a construction like "list of texts", the strong ID is a pointer to
the array |LIST_OF_TY 1 TEXT_TY|.

@ Strong IDs are a superset of weak IDs for base kinds like "number", but not
for constructions like "list of numbers", where the strong and weak IDs are
different values at run-time. The following general code is sufficient to turn a
strong ID into a weak one:

	|if ((strong >= 0) && (strong < BASE_KIND_HWM)) weak = strong;|
	|else weak = strong-->0;|

We must be careful with comparisons because a strong ID may be numerically
negative if it's a pointer into the upper half of virtual machine memory.

@ In order to make sure each distinct kind has a unique strong ID, we must
ensure that we always point to the same array every time the same construction
turns up. This means remembering everything we've seen, using a new structure:

=
void Kinds::RunTime::emit_strong_id(kind *K) {
	runtime_kind_structure *rks = Kinds::RunTime::get_rks(K);
	if (rks) {
		Emit::array_iname_entry(rks->rks_iname);
	} else {
		Kinds::RunTime::emit_weak_id(K);
	}
}

void Kinds::RunTime::emit_strong_id_as_val(kind *K) {
	runtime_kind_structure *rks = Kinds::RunTime::get_rks(K);
	if (rks) {
		Emit::val_symbol(K_value, InterNames::to_symbol(rks->rks_iname));
	} else {
		Kinds::RunTime::emit_weak_id_as_val(K);
	}
}

@ Thus the following routine must return |NULL| if $K$ is a kind whose weak
ID is the same as its strong ID -- if it's a base kind, in other words --
and otherwise return a pointer to a unique |runtime_kind_structure| for $K$.

Note that a |CON_TUPLE_ENTRY| node is recursed downwards through, to ensure
that its leaves are passed through |Kinds::RunTime::get_rks|, but no RKS structure is made
for it -- this is because none is needed, since we're going to roll up
tuple subtrees into flat arrays. Recall that |CON_TUPLE_ENTRY| nodes are
"punctuation", not base kinds in their own right. We can never see them
here except as a result of recursion.

=
runtime_kind_structure *Kinds::RunTime::get_rks(kind *K) {
	kind *divert = Kinds::Behaviour::stored_as(K);
	if (divert) K = divert;
	runtime_kind_structure *rks = NULL;
	if (K) {
		int arity = Kinds::arity_of_constructor(K);
		if (arity > 0) {
			if (Kinds::get_construct(K) != CON_TUPLE_ENTRY)
				@<Find or make a runtime kind structure for the kind@>;
			switch (arity) {
				case 1: {
					kind *k = Kinds::unary_construction_material(K);
					Kinds::RunTime::get_rks(k);
					break;
				}
				case 2: {
					kind *k = NULL, *l = NULL;
					Kinds::binary_construction_material(K, &k, &l);
					Kinds::RunTime::get_rks(k);
					Kinds::RunTime::get_rks(l);
					break;
				}
			}
		}
	}
	return rks;
}

@ The following implies a quadratic running time in the number of distinct
constructed kinds of value seen across the source text, which may become a
performance problem later on. But at present this number is surprisingly
small -- often less than 10. On the principle that premature optimisation
is the root of all evil, I'm leaving it quadratic.

@<Find or make a runtime kind structure for the kind@> =
	LOOP_OVER(rks, runtime_kind_structure)
		if (Kinds::Compare::eq(K, rks->kind_described))
			break;
	if (rks == NULL) @<Create a new runtime kind ID structure@>;

@ The following aims to provide helpful identifiers such as |KD7_list_of_texts|.
Sometime it succeeds. At all events it must provide unique ones which will
compile under Inform 6.

@<Create a new runtime kind ID structure@> =
	rks = CREATE(runtime_kind_structure);
	rks->kind_described = K;
	rks->make_default = FALSE;
	rks->default_requested_here = NULL;
	rks->rks_iname = InterNames::new(KIND_ID_INAMEF);
	package_request *PR = Kinds::Behaviour::package(K);
	Packaging::house(rks->rks_iname, PR);
	TEMPORARY_TEXT(TEMP);
	Kinds::Textual::write(TEMP, K);
	wording W = Feeds::feed_stream(TEMP);
	DISCARD_TEXT(TEMP);
	InterNames::attach_memo(rks->rks_iname, W);
	InterNames::to_symbol(rks->rks_iname);
	rks->rks_dv_iname = InterNames::one_off(I"default_value", PR);
	Inter::Symbols::set_flag(InterNames::to_symbol(rks->rks_dv_iname), MAKE_NAME_UNIQUE);

@ It's convenient to combine this system with one which constructs default
values for kinds, since both involve tracking constructions uniquely.

=
inter_name *Kinds::RunTime::compile_default_value_inner(kind *K) {
	Kinds::RunTime::precompile_default_value(K);
	runtime_kind_structure *rks = Kinds::RunTime::get_rks(K);
	if (rks == NULL) return NULL;
	return rks->rks_dv_iname;
}

int Kinds::RunTime::precompile_default_value(kind *K) {
	runtime_kind_structure *rks = Kinds::RunTime::get_rks(K);
	if (rks == NULL) return FALSE;
	rks->make_default = TRUE;
	if (rks->default_requested_here == NULL) rks->default_requested_here = current_sentence;
	return TRUE;
}

@ Convenient storage for some names.

=
inter_name *Kinds::RunTime::get_kind_GPR_iname(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *con = Kinds::get_construct(K);
	if (con->kind_GPR_iname == NULL) {
		package_request *R = Kinds::RunTime::package(K);
		con->kind_GPR_iname =
			Packaging::function(
				InterNames::one_off(I"gpr_fn", R),
				R,
				NULL);
		Inter::Symbols::set_flag(InterNames::to_symbol(con->kind_GPR_iname), MAKE_NAME_UNIQUE);
	}
	return con->kind_GPR_iname;
}

inter_name *Kinds::RunTime::get_instance_GPR_iname(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *con = Kinds::get_construct(K);
	if (con->instance_GPR_iname == NULL) {
		package_request *R = Kinds::RunTime::package(K);
		con->instance_GPR_iname =
			Packaging::function(
				InterNames::one_off(I"instance_gpr_fn", R),
				R,
				NULL);
		Inter::Symbols::set_flag(InterNames::to_symbol(con->instance_GPR_iname), MAKE_NAME_UNIQUE);
	}
	return con->instance_GPR_iname;
}

@ At the end of Inform's run, then, we have seen various interesting kinds
of value and compiled pointers to arrays representing them. But we haven't
compiled the arrays themselves; so we do that now.

Because these are recursive structures -- the array for a strong ID often
contains references to other strong ID arrays -- it may look as if there's
a risk of further RKS structures being generated, which might make the loop
behave oddly. But this doesn't happen because |Kinds::RunTime::get_rks| has already
recursively scanned through for us, so that if we have seen a construction
$K$, we have also seen its bases.

=
void Kinds::RunTime::compile_structures(void) {
	runtime_kind_structure *rks;
	LOOP_OVER(rks, runtime_kind_structure) {
		kind *K = rks->kind_described;
		@<Compile the runtime ID structure for this kind@>;
		if (rks->make_default) @<Compile a constructed default value for this kind@>;
	}
	@<Compile the default value finder@>;
}

@<Compile the runtime ID structure for this kind@> =
	package_request *PR = Kinds::Behaviour::package(K);
	packaging_state save = Packaging::enter(PR);
	Emit::named_array_begin(rks->rks_iname, K_value);
	Kinds::RunTime::emit_weak_id(K);
	@<Compile the list of strong IDs for the bases@>;
	Emit::array_end();
	Packaging::exit(save);

@<Compile the list of strong IDs for the bases@> =
	int arity = Kinds::arity_of_constructor(K);
	if (Kinds::get_construct(K) == CON_phrase) {
		arity--;
		kind *X = NULL, *result = NULL;
		Kinds::binary_construction_material(K, &X, &result);
		@<Expand out a tuple subtree into a simple array@>;
		Kinds::RunTime::emit_strong_id(result);
	} else if (Kinds::get_construct(K) == CON_combination) {
		arity--;
		kind *X = Kinds::unary_construction_material(K);
		@<Expand out a tuple subtree into a simple array@>;
	} else {
		@<Expand out regular bases@>;
	}

@<Expand out regular bases@> =
	Emit::array_numeric_entry((inter_t) arity);
	switch (arity) {
		case 1: {
			kind *X = Kinds::unary_construction_material(K);
			Kinds::RunTime::emit_strong_id(X);
			break;
		}
		case 2: {
			kind *X = NULL, *Y = NULL;
			Kinds::binary_construction_material(K, &X, &Y);
			Kinds::RunTime::emit_strong_id(X);
			Kinds::RunTime::emit_strong_id(Y);
			break;
		}
	}

@<Expand out a tuple subtree into a simple array@> =
	while (Kinds::get_construct(X) == CON_TUPLE_ENTRY) {
		arity++;
		Kinds::binary_construction_material(X, NULL, &X);
	}
	Emit::array_numeric_entry((inter_t) arity);
	X = Kinds::unary_construction_material(K);
	while (Kinds::get_construct(X) == CON_TUPLE_ENTRY) {
		arity++;
		kind *term = NULL;
		Kinds::binary_construction_material(X, &term, &X);
		Kinds::RunTime::emit_strong_id(term);
	}

@<Compile a constructed default value for this kind@> =
	inter_name *identifier = rks->rks_dv_iname;
	current_sentence = rks->default_requested_here;
	packaging_state save = Packaging::enter_home_of(identifier);
	if (Kinds::get_construct(K) == CON_phrase) {
		Phrases::Constants::compile_default_closure(identifier, K);
	} else if (Kinds::get_construct(K) == CON_relation) {
		Relations::compile_default_relation(identifier, K);
	} else if (Kinds::get_construct(K) == CON_list_of) {
		Lists::compile_default_list(identifier, K);
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, K);
		Problems::Issue::handmade_problem(_p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"While working on '%1', I needed to be able to make a default value "
			"for the kind '%2', but there's no obvious way to make one.");
		Problems::issue_problem_end();
	}
	Packaging::exit(save);

@<Compile the default value finder@> =
	packaging_state save = Routines::begin(Hierarchy::find(DEFAULTVALUEFINDER_NRL));
	inter_symbol *k_s = LocalVariables::add_named_call_as_symbol(I"k");
	runtime_kind_structure *rks;
	LOOP_OVER(rks, runtime_kind_structure) {
		kind *K = rks->kind_described;
		if (rks->make_default) {
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::val_symbol(K_value, k_s);
					Kinds::RunTime::emit_strong_id_as_val(K);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val_iname(K_value, rks->rks_dv_iname);
					Emit::up();
				Emit::up();
			Emit::up();
		}
	}
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val(K_number, LITERAL_IVAL, 0);
	Emit::up();
	Routines::end(save);

@h The heap.
Texts, lists and other flexibly-sized structures make use of a pool of
run-time storage called "the heap".

Management of the heap is delegated to runtime code in the template file
"Flex.i6t", so Inform itself needs to know surprisingly little about
how the job is done.

=
int total_heap_allocation = 0;

void Kinds::RunTime::ensure_basic_heap_present(void) {
	total_heap_allocation += 256; /* enough for the initial free-space block */
}

@ We need to provide a start-up routine which creates initial blocks of
data on the heap for any permanent storage objects (global variables,
property values, table entries, list items) of pointer-value kinds:

=
void Kinds::RunTime::compile_heap_allocator(void) {
	@<Compile a constant for the heap size needed@>;
}

@ By now, we know that we need at least |total_heap_allocation| bytes on the
heap, but the initial heap size has to be a power of 2, so we compute the
smallest such which is big enough. On Glulx, we then multiply by 4: one factor
of 2 is because the word size is twice as much -- words are 4-byte, not 2-byte
as on the Z-machine -- while the other is, basically, because we can, and
because we want to store text in particular using 2-byte characters (capable
of storing Unicode) rather than 1-byte characters as on the Z-machine. Glulx
has essentially no memory constraints compared with the Z-machine.

@<Compile a constant for the heap size needed@> =
	int max_heap = 1;
	if (total_heap_allocation < UseOptions::get_dynamic_memory_allocation())
		total_heap_allocation = UseOptions::get_dynamic_memory_allocation();
	while (max_heap < total_heap_allocation) max_heap = max_heap*2;
	if (VirtualMachines::is_16_bit())
		Kinds::RunTime::compile_nnci(Hierarchy::find(MEMORY_HEAP_SIZE_NRL), max_heap);
	else
		Kinds::RunTime::compile_nnci(Hierarchy::find(MEMORY_HEAP_SIZE_NRL), 4*max_heap);
	LOG("Providing for a total heap of %d, given requirement of %d\n",
		max_heap, total_heap_allocation);

@ =
inter_name *Kinds::RunTime::begin_block_constant(kind *K) {
	inter_name *N = Packaging::supply_iname(Packaging::current_enclosure(), BLOCK_CONSTANT_PR_COUNTER);
	Inter::Symbols::set_flag(InterNames::to_symbol(N), MAKE_NAME_UNIQUE);
	Emit::named_late_array_begin(N, K_value);
	return N;
}

void Kinds::RunTime::end_block_constant(kind *K) {
	Emit::array_end();
}

@ The following routine both compiles code to create a pointer value, and
also increments the heap allocation suitably. Each pointer-value kind comes
with an estimate of its likely size needs -- its exact size needs if it is
fixed in size, and a reasonable overestimate of typical usage if it is
flexible.

The |multiplier| is used when we need to calculate the size of, say, a
list of 20 texts. For the cases above, it's always 1.

=
typedef struct heap_allocation {
	struct kind *allocated_kind;
	int stack_offset;
} heap_allocation;

heap_allocation Kinds::RunTime::make_heap_allocation(kind *K, int multiplier,
	int stack_offset) {
	if (Kinds::Behaviour::uses_pointer_values(K) == FALSE)
		internal_error("unable to allocate heap storage for this kind of value");
	if (Kinds::Behaviour::get_heap_size_estimate(K) == 0)
		internal_error("no heap storage estimate for this kind of value");

	total_heap_allocation += (Kinds::Behaviour::get_heap_size_estimate(K) + 8)*multiplier;

	if (Kinds::get_construct(K) == CON_relation)
		Kinds::RunTime::precompile_default_value(K);

	heap_allocation ha;
	ha.allocated_kind = K;
	ha.stack_offset = stack_offset;
	return ha;
}

void Kinds::RunTime::emit_heap_allocation(heap_allocation ha) {
	if (ha.stack_offset >= 0) {
		inter_name *iname = InterNames::extern(BLKVALUECREATEONSTACK_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
		Emit::val(K_number, LITERAL_IVAL, (inter_t) ha.stack_offset);
		Kinds::RunTime::emit_strong_id_as_val(ha.allocated_kind);
		Emit::up();
	} else {
		inter_name *iname = InterNames::extern(BLKVALUECREATE_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
		Kinds::RunTime::emit_strong_id_as_val(ha.allocated_kind);
		Emit::up();
	}
}

@

@d BLK_FLAG_MULTIPLE 0x00000001
@d BLK_FLAG_16_BIT   0x00000002
@d BLK_FLAG_WORD     0x00000004
@d BLK_FLAG_RESIDENT 0x00000008
@d BLK_FLAG_TRUNCMULT 0x00000010

=
void Kinds::RunTime::emit_block_value_header(kind *K, int individual, int size) {
	if (individual == FALSE) Emit::array_numeric_entry(0);
	int n = 0, c = 1, w = 4;
	if (VirtualMachines::is_16_bit()) w = 2;
	while (c < (size + 3)*w) { n++; c = c*2; }
	int flags = BLK_FLAG_RESIDENT + BLK_FLAG_WORD;
	if (Kinds::get_construct(K) == CON_list_of) flags += BLK_FLAG_TRUNCMULT;
	if (Kinds::get_construct(K) == CON_relation) flags += BLK_FLAG_MULTIPLE;
	if (VirtualMachines::is_16_bit())
		Emit::array_numeric_entry((inter_t) (0x100*n + flags));
	else
		Emit::array_numeric_entry((inter_t) (0x1000000*n + 0x10000*flags));
	Kinds::RunTime::emit_weak_id(K);

	Emit::array_MPN_entry();
}

@h Run-time support for units and enumerations.
The following generates a small suite of I6 routines associated with
each such kind, and needed at run-time.

=
int Kinds::RunTime::base_represented_in_inter(kind *K) {
	if ((Kinds::Behaviour::is_kind_of_kind(K) == FALSE) &&
		(Kinds::is_proper_constructor(K) == FALSE) &&
		(K != K_nil)) return TRUE;
	return FALSE;
}

typedef struct kind_interaction {
	struct kind *noted_kind;
	struct inter_name *noted_iname;
	MEMORY_MANAGEMENT
} kind_interaction;

@ =
package_request *Kinds::RunTime::package(kind *K) {
	inter_name *iname = Kinds::RunTime::iname(K);
	return iname->eventual_owner;
}

@

@d MAX_KIND_ARITY 32

=
inter_name *Kinds::RunTime::iname(kind *K) {
	if (Kinds::RunTime::base_represented_in_inter(K) == FALSE) {
		kind_interaction *KI;
		LOOP_OVER(KI, kind_interaction)
			if (Kinds::Compare::eq(K, KI->noted_kind))
				return KI->noted_iname;
	}
	inter_name *S = Kinds::RunTime::iname_inner(K);
	if (Kinds::RunTime::base_represented_in_inter(K) == FALSE) {
		kind_interaction *KI = CREATE(kind_interaction);
		KI->noted_kind = K;
		KI->noted_iname = S;
		int arity = 0;
		kind *operands[MAX_KIND_ARITY];
		int icon = -1;
		inter_t idt = ROUTINE_IDT;
		if (Kinds::get_construct(K) == CON_description) @<Run out inter kind for description@>
		else if (Kinds::get_construct(K) == CON_list_of) @<Run out inter kind for list@>
		else if (Kinds::get_construct(K) == CON_phrase) @<Run out inter kind for phrase@>
		else if (Kinds::get_construct(K) == CON_rule) @<Run out inter kind for rule@>
		else if (Kinds::get_construct(K) == CON_rulebook) @<Run out inter kind for rulebook@>
		else if (Kinds::get_construct(K) == CON_table_column) @<Run out inter kind for column@>
		else if (Kinds::get_construct(K) == CON_relation) @<Run out inter kind for relation@>
		else {
			LOG("Unfortunate kind is: $u\n", K);
			internal_error("unable to represent kind in inter");
		}
		if (icon < 0) internal_error("icon unset");
		Emit::kind(S, idt, NULL, icon, arity, operands);
	}
	return S;
}

@<Run out inter kind for list@> =
	arity = 1;
	operands[0] = Kinds::unary_construction_material(K);
	icon = LIST_ICON;
	idt = LIST_IDT;

@<Run out inter kind for description@> =
	arity = 1;
	operands[0] = Kinds::unary_construction_material(K);
	icon = DESCRIPTION_ICON;

@<Run out inter kind for column@> =
	arity = 1;
	operands[0] = Kinds::unary_construction_material(K);
	icon = COLUMN_ICON;

@<Run out inter kind for relation@> =
	arity = 2;
	Kinds::binary_construction_material(K, &operands[0], &operands[1]);
	icon = RELATION_ICON;

@<Run out inter kind for phrase@> =
	icon = FUNCTION_ICON;
	kind *X = NULL, *result = NULL;
	Kinds::binary_construction_material(K, &X, &result);
	while (Kinds::get_construct(X) == CON_TUPLE_ENTRY) {
		kind *A = NULL;
		Kinds::binary_construction_material(X, &A, &X);
		operands[arity++] = A;
	}
	if (arity == 0) {
		operands[arity++] = NULL; /* void arguments */
	}
	operands[arity++] = result;

@<Run out inter kind for rule@> =
	arity = 2;
	Kinds::binary_construction_material(K, &operands[0], &operands[1]);
	icon = RULE_ICON;

@<Run out inter kind for rulebook@> =
	arity = 1;
	kind *X = NULL, *Y = NULL;
	Kinds::binary_construction_material(K, &X, &Y);
	operands[0] = Kinds::binary_construction(CON_phrase, X, Y);
	icon = RULEBOOK_ICON;

@ =
int object_kind_count = 1;
inter_name *Kinds::RunTime::iname_inner(kind *K) {
	if (Kinds::is_proper_constructor(K)) {
		return InterNames::constructed_kind_name(K);
	}
	if (Kinds::RunTime::base_represented_in_inter(K)) {
		return Kinds::RunTime::assure_iname_exists(K);
	}
	return NULL;
}

inter_name *Kinds::RunTime::assure_iname_exists(kind *K) {
	noun *nt = Kinds::Behaviour::get_noun(K);
	if (nt) {
		if (UseNouns::iname_set(nt) == FALSE) {
			inter_name *iname = InterNames::constructed_kind_name(K);
			UseNouns::noun_impose_identifier(nt, iname);
		}
	}
	return UseNouns::iname(nt);
}

@ =
void Kinds::RunTime::emit(kind *K) {
	if (K == NULL) internal_error("tried to emit null kind");
	if (InterNames::defined(Kinds::RunTime::iname(K))) return;
	inter_t dt = INT32_IDT;
	if (K == K_object) dt = ENUM_IDT;
	if (Kinds::Behaviour::is_an_enumeration(K)) dt = ENUM_IDT;
	if (K == K_truth_state) dt = INT2_IDT;
	if (K == K_text) dt = TEXT_IDT;
	if (K == K_table) dt = TABLE_IDT;
	kind *S = Kinds::Compare::super(K);
	if (S) {
		Kinds::RunTime::emit(S);
		dt = ENUM_IDT;
	}
	Emit::kind(Kinds::RunTime::iname(K), dt, S?Kinds::RunTime::iname(S):NULL, BASE_ICON, 0, NULL);
	if (K == K_object) InterNames::translate(Kinds::RunTime::iname(K), I"K0_kind");
}

void Kinds::RunTime::kind_declarations(void) {
	kind *K; inter_t c = 0;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::RunTime::base_represented_in_inter(K)) {
			Kinds::RunTime::emit(K);
			inter_name *iname = Kinds::RunTime::iname(K);
			InterNames::annotate_i(iname, WEAK_ID_IANN, (inter_t) Kinds::RunTime::weak_id(K));
			InterNames::annotate_i(iname, SOURCE_ORDER_IANN, c++);
		}
}

void Kinds::RunTime::compile_nnci(inter_name *name, int val) {
	packaging_state save = Packaging::enter_home_of(name);
	Emit::named_numeric_constant(name, (inter_t) val);
	Packaging::exit(save);
}

void Kinds::RunTime::compile_instance_counts(void) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K) {
		if ((Kinds::Behaviour::is_an_enumeration(K)) || (Kinds::Compare::le(K, K_object))) {
			package_request *PR = Kinds::Behaviour::package(K);
			packaging_state save = Packaging::enter(PR);
			inter_name *iname = InterNames::icount_name(K);
			Packaging::house(iname, PR);
			Emit::named_numeric_constant(iname, (inter_t) Instances::count(K));
			Packaging::exit(save);
		}
	}

	Kinds::RunTime::compile_nnci(Hierarchy::find(CCOUNT_BINARY_PREDICATE_NRL), NUMBER_CREATED(binary_predicate));
	Kinds::RunTime::compile_nnci(Hierarchy::find(CCOUNT_PROPERTY_NRL), NUMBER_CREATED(property));
	#ifdef IF_MODULE
	Kinds::RunTime::compile_nnci(Hierarchy::find(CCOUNT_ACTION_NAME_NRL), NUMBER_CREATED(action_name));
	#endif
	Kinds::RunTime::compile_nnci(Hierarchy::find(CCOUNT_QUOTATIONS_NRL), Strings::TextLiterals::CCOUNT_QUOTATIONS());
	Kinds::RunTime::compile_nnci(Hierarchy::find(MAX_FRAME_SIZE_NEEDED_NRL), max_frame_size_needed);
	Kinds::RunTime::compile_nnci(Hierarchy::find(RNG_SEED_AT_START_OF_PLAY_NRL), rng_seed_at_start_of_play);
	Kinds::RunTime::compile_nnci(Hierarchy::find(DEFAULT_SCORING_SETTING_NRL), FALSE);
}

void Kinds::RunTime::compile_data_type_support_routines(void) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K) {
		if (Kinds::Compare::lt(K, K_object)) continue;
		if (Kinds::Behaviour::stored_as(K) == NULL)
			if (Kinds::Behaviour::is_an_enumeration(K)) {
				inter_name *printing_rule_name = Kinds::Behaviour::get_iname(K);
				@<Compile I6 printing routine for an enumerated kind@>;
				@<Compile the A and B routines for an enumerated kind@>;
				@<Compile random-ranger routine for this kind@>;
			}
	}
	LOOP_OVER_BASE_KINDS(K) {
		if (Kinds::Behaviour::is_built_in(K)) continue;
		if (Kinds::Compare::lt(K, K_object)) continue;
		if (Kinds::Behaviour::is_an_enumeration(K)) continue;
		if (Kinds::Behaviour::stored_as(K) == NULL) {
			inter_name *printing_rule_name = Kinds::Behaviour::get_iname(K);
			if (Kinds::Behaviour::is_quasinumerical(K)) {
				@<Compile I6 printing routine for a unit kind@>;
				@<Compile random-ranger routine for this kind@>;
			} else {
				@<Compile I6 printing routine for a vacant but named kind@>;
			}
		}
	}

	@<Compile a suite of I6 routines taking kind IDs as arguments@>;
}

@ A slightly bogus case first. If the source text declares a kind but never
gives any enumerated values or literal patterns, then such values will never
appear at run-time; but we need the printing routine to exist to avoid
compilation errors.

@<Compile I6 printing routine for a vacant but named kind@> =
	packaging_state save = Routines::begin(printing_rule_name);
	inter_symbol *value_s = LocalVariables::add_named_call_as_symbol(I"value");
	TEMPORARY_TEXT(C);
	WRITE_TO(C, "! weak kind ID: %d\n", Kinds::RunTime::weak_id(K));
	Emit::code_comment(C);
	DISCARD_TEXT(C);
	Emit::inv_primitive(print_interp);
	Emit::down();
		Emit::val_symbol(K_value, value_s);
	Emit::up();
	Routines::end(save);

@ A unit is printed back with its earliest-defined literal pattern used as
notation. If it had no literal patterns, it would come out as decimal numbers,
but at present this can't happen.

@<Compile I6 printing routine for a unit kind@> =
	if (LiteralPatterns::list_of_literal_forms(K))
		LiteralPatterns::printing_routine(printing_rule_name,
			LiteralPatterns::list_of_literal_forms(K));
	else {
		packaging_state save = Routines::begin(printing_rule_name);
		inter_symbol *value_s = LocalVariables::add_named_call_as_symbol(I"value");
		Emit::inv_primitive(print_interp);
		Emit::down();
			Emit::val_symbol(K_value, value_s);
		Emit::up();
		Routines::end(save);
	}

@<Compile I6 printing routine for an enumerated kind@> =
	packaging_state save = Routines::begin(printing_rule_name);
	inter_symbol *value_s = LocalVariables::add_named_call_as_symbol(I"value");

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, value_s);
		Emit::code();
		Emit::down();
			instance *I;
			LOOP_OVER_INSTANCES(I, K) {
				Emit::inv_primitive(case_interp);
				Emit::down();
					Emit::val_iname(K_value, Instances::iname(I));
					Emit::code();
					Emit::down();
						Emit::inv_primitive(print_interp);
						Emit::down();
							TEMPORARY_TEXT(CT);
							wording NW = Instances::get_name_in_play(I, FALSE);
							LOOP_THROUGH_WORDING(k, NW) {
								CompiledText::from_wide_string(CT, Lexer::word_raw_text(k), CT_RAW);
								if (k < Wordings::last_wn(NW)) WRITE_TO(CT, " ");
							}
							Emit::val_text(CT);
							DISCARD_TEXT(CT);
						Emit::up();
					Emit::up();
				Emit::up();
			}
			Emit::inv_primitive(default_interp); /* this default case should never be needed, unless the user has blundered at the I6 level: */
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(print_interp);
					Emit::down();
						TEMPORARY_TEXT(DT);
						wording W = Kinds::Behaviour::get_name(K, FALSE);
						WRITE_TO(DT, "<illegal ");
						if (Wordings::nonempty(W)) WRITE_TO(DT, "%W", W);
						else WRITE_TO(DT, "value");
						WRITE_TO(DT, ">");
						Emit::val_text(DT);
						DISCARD_TEXT(DT);
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Routines::end(save);

@ The suite of standard routines provided for enumerative types is a little
like the one in Ada (|T'Succ|, |T'Pred|, and so on).

If the type is called, say, |T1_colour|, then we have:

(a) |A_T1_colour(v)| advances to the next valid value for the type,
wrapping around to the first from the last;
(b) |B_T1_colour(v)| goes back to the previous valid value for the type,
wrapping around to the last from the first, so that it is the inverse function
to |A_T1_colour(v)|.

@<Compile the A and B routines for an enumerated kind@> =
	int instance_count = 0;
	instance *I;
	LOOP_OVER_INSTANCES(I, K) instance_count++;

	inter_name *iname_i = Kinds::Behaviour::get_inc_iname(K);
	packaging_state save = Routines::begin(iname_i);
	@<Implement the A routine@>;
	Routines::end(save);

	inter_name *iname_d = Kinds::Behaviour::get_dec_iname(K);
	save = Routines::begin(iname_d);
	@<Implement the B routine@>;
	Routines::end(save);

@ There should be a blue historical plaque on the wall here: this was the
first routine implemented by emitting Inter code, on 12 November 2017.

@<Implement the A routine@> =
	inter_symbol *x = LocalVariables::create_and_declare(I"x", K);

	Emit::inv_primitive(return_interp);
	Emit::down();

	if (instance_count <= 1) {
		Emit::val_symbol(K, x);
	} else {
		Emit::cast(K_number, K);
		Emit::down();
			Emit::inv_primitive(plus_interp);
			Emit::down();
				Emit::inv_primitive(modulo_interp);
				Emit::down();
					Emit::cast(K, K_number);
					Emit::down();
						Emit::val_symbol(K, x);
					Emit::up();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) instance_count);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, 1);
			Emit::up();
		Emit::up();
	}

	Emit::up();

@ And this was the second, a few minutes later.

@<Implement the B routine@> =
	inter_symbol *x = LocalVariables::create_and_declare(I"x", K);

	Emit::inv_primitive(return_interp);
	Emit::down();

	if (instance_count <= 1) {
		Emit::val_symbol(K, x);
	} else {
		Emit::cast(K_number, K);
		Emit::down();
			Emit::inv_primitive(plus_interp);
			Emit::down();
				Emit::inv_primitive(modulo_interp);
				Emit::down();

				if (instance_count > 2) {
					Emit::inv_primitive(plus_interp);
					Emit::down();
						Emit::cast(K, K_number);
						Emit::down();
							Emit::val_symbol(K, x);
						Emit::up();
						Emit::val(K_number, LITERAL_IVAL, (inter_t) instance_count-2);
					Emit::up();
				} else {
					Emit::cast(K, K_number);
					Emit::down();
						Emit::val_symbol(K, x);
					Emit::up();
				}

					Emit::val(K_number, LITERAL_IVAL, (inter_t) instance_count);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, 1);
			Emit::up();
		Emit::up();
	}

	Emit::up();

@ And here we add:

(a) |R_T1_colour()| returns a uniformly random choice of the valid
values of the given type. (For a unit, this will be a uniformly random positive
value, which will probably not be useful.)
(b) |R_T1_colour(a, b)| returns a uniformly random choice in between |a|
and |b| inclusive.

@<Compile random-ranger routine for this kind@> =
	inter_name *iname_r = Kinds::Behaviour::get_ranger_iname(K);
	packaging_state save = Routines::begin(iname_r);
	inter_symbol *a_s = LocalVariables::add_named_call_as_symbol(I"a");
	inter_symbol *b_s = LocalVariables::add_named_call_as_symbol(I"b");

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(and_interp);
		Emit::down();
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::val_symbol(K_value, a_s);
				Emit::val(K_number, LITERAL_IVAL, 0);
			Emit::up();
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::val_symbol(K_value, b_s);
				Emit::val(K_number, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(return_interp);
			Emit::down();
				Emit::inv_primitive(random_interp);
				Emit::down();
					if (Kinds::Behaviour::is_quasinumerical(K))
						Emit::val_iname(K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_NRL));
					else
						Emit::val(K_number, LITERAL_IVAL, (inter_t) Kinds::Behaviour::get_highest_valid_value_as_integer(K));
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(eq_interp);
		Emit::down();
			Emit::val_symbol(K_value, a_s);
			Emit::val_symbol(K_value, b_s);
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(return_interp);
			Emit::down();
				Emit::val_symbol(K_value, b_s);
			Emit::up();
		Emit::up();
	Emit::up();

	inter_symbol *smaller = NULL, *larger = NULL;

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(gt_interp);
		Emit::down();
			Emit::val_symbol(K_value, a_s);
			Emit::val_symbol(K_value, b_s);
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(return_interp);
			Emit::down();
				smaller = b_s; larger = a_s;
				@<Formula for range@>;
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(return_interp);
	Emit::down();
		smaller = a_s; larger = b_s;
		@<Formula for range@>;
	Emit::up();

	Routines::end(save);

@<Formula for range@> =
	Emit::inv_primitive(plus_interp);
	Emit::down();
		Emit::val_symbol(K_value, smaller);
		Emit::inv_primitive(modulo_interp);
		Emit::down();
			Emit::inv_primitive(random_interp);
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_NRL));
			Emit::up();
			Emit::inv_primitive(plus_interp);
			Emit::down();
				Emit::inv_primitive(minus_interp);
				Emit::down();
					Emit::val_symbol(K_value, larger);
					Emit::val_symbol(K_value, smaller);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, 1);
			Emit::up();
		Emit::up();
	Emit::up();

@h Further runtime support.
These last routines are synoptic: they take the ID number of the kind as an
argument, so there is only one of each routine.

@<Compile a suite of I6 routines taking kind IDs as arguments@> =
	@<Compile PrintKindValuePair@>;
	@<Compile DefaultValueOfKOV@>;
	@<Compile KOVComparisonFunction@>;
	@<Compile KOVDomainSize@>;
	@<Compile KOVIsBlockValue@>;
	@<Compile KOVSupportFunction@>;

@ |PrintKindValuePair(K, V)| prints out the value |V|, declaring its kind to
be |K|. (Since I6 is typeless and in general the kind of |V| cannot be
deduced from its value alone, |K| must explicitly be supplied.)

@<Compile PrintKindValuePair@> =
	packaging_state save = Routines::begin(Hierarchy::find(PRINTKINDVALUEPAIR_NRL));
	inter_symbol *k_s = LocalVariables::add_named_call_as_symbol(I"k");
	inter_symbol *v_s = LocalVariables::add_named_call_as_symbol(I"v");
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, k_s);
		inter_name *iname = InterNames::extern(KINDATOMIC_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
			Emit::val_symbol(K_value, k_s);
		Emit::up();
	Emit::up();

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, k_s);
		Emit::code();
		Emit::down();

	LOOP_OVER_BASE_KINDS(K) {
		if (Kinds::Compare::lt(K, K_object)) continue;
			Emit::inv_primitive(case_interp);
			Emit::down();
				Kinds::RunTime::emit_weak_id_as_val(K);
				Emit::code();
				Emit::down();
					inter_name *pname = Kinds::Behaviour::get_iname(K);
					Emit::inv_call(InterNames::to_symbol(pname));
					Emit::down();
						Emit::val_symbol(K_value, v_s);
					Emit::up();
				Emit::up();
			Emit::up();
	}

			Emit::inv_primitive(default_interp);
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_symbol(K_value, v_s);
					Emit::up();
				Emit::up();
			Emit::up();

		Emit::up();
	Emit::up();
	Routines::end(save);

@ |DefaultValueOfKOV(K)| returns the default value for kind |K|: it's needed,
for instance, when increasing the size of a list of $K$ to include new entries,
which have to be given some type-safe value to start out at.

@<Compile DefaultValueOfKOV@> =
	packaging_state save = Routines::begin(Hierarchy::find(DEFAULTVALUEOFKOV_NRL));
	inter_symbol *sk_s = LocalVariables::add_named_call_as_symbol(I"sk");
	local_variable *k = LocalVariables::add_internal_local_c(I"k", "weak kind ID");
	inter_symbol *k_s = LocalVariables::declare_this(k, FALSE, 8);
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, k_s);
		inter_name *iname = InterNames::extern(KINDATOMIC_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
			Emit::val_symbol(K_value, sk_s);
		Emit::up();
	Emit::up();

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, k_s);
		Emit::code();
		Emit::down();

	LOOP_OVER_BASE_KINDS(K) {
		if (Kinds::Compare::lt(K, K_object)) continue;
		if (Kinds::Behaviour::definite(K)) {
			Emit::inv_primitive(case_interp);
			Emit::down();
				Kinds::RunTime::emit_weak_id_as_val(K);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						if (Kinds::Behaviour::uses_pointer_values(K)) {
							inter_name *iname = InterNames::extern(BLKVALUECREATE_EXNAMEF);
							Emit::inv_call(InterNames::to_symbol(iname));
							Emit::down();
								Emit::val_symbol(K_value, sk_s);
							Emit::up();
						} else {
							Kinds::RunTime::emit_default_value_as_val(K, EMPTY_WORDING, "list entry");
						}
					Emit::up();
				Emit::up();
			Emit::up();
		}
	}

			Emit::inv_primitive(default_interp);
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val(K_value, LITERAL_IVAL, 0);
					Emit::up();
				Emit::up();
			Emit::up();

		Emit::up();
	Emit::up();
	Routines::end(save);

@ |KOVComparisonFunction(K)| returns either the address of a function to
perform a comparison between two values, or else 0 to signal that no
special sort of comparison is needed. (In which case signed numerical
comparison will be used.) The function |F| may be used in a sorting algorithm,
so it must have no side-effects. |F(x,y)| should return 1 if $x>y$,
0 if $x=y$ and $-1$ if $x<y$. Note that it is not permitted to return 0
unless the two values are genuinely equal.

@<Compile KOVComparisonFunction@> =
	packaging_state save = Routines::begin(Hierarchy::find(KOVCOMPARISONFUNCTION_NRL));
	LocalVariables::add_named_call(I"k");
	local_variable *k = LocalVariables::add_internal_local_c(I"k", "weak kind ID");
	inter_symbol *k_s = LocalVariables::declare_this(k, FALSE, 8);
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, k_s);
		inter_name *iname = InterNames::extern(KINDATOMIC_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
			Emit::val_symbol(K_value, k_s);
		Emit::up();
	Emit::up();

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, k_s);
		Emit::code();
		Emit::down();

	LOOP_OVER_BASE_KINDS(K) {
		if (Kinds::Compare::lt(K, K_object)) continue;
		if ((Kinds::Behaviour::definite(K)) &&
			(Kinds::Behaviour::uses_signed_comparisons(K) == FALSE)) {
			Emit::inv_primitive(case_interp);
			Emit::down();
				Kinds::RunTime::emit_weak_id_as_val(K);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						inter_name *iname = Kinds::Behaviour::get_comparison_routine_as_iname(K);
						Emit::val_iname(K_value, iname);
					Emit::up();
				Emit::up();
			Emit::up();
		}
	}

			Emit::inv_primitive(default_interp);
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val(K_value, LITERAL_IVAL, 0);
					Emit::up();
				Emit::up();
			Emit::up();

		Emit::up();
	Emit::up();
	Routines::end(save);

@<Compile KOVDomainSize@> =
	packaging_state save = Routines::begin(Hierarchy::find(KOVDOMAINSIZE_NRL));
	local_variable *k = LocalVariables::add_internal_local_c(I"k", "weak kind ID");
	inter_symbol *k_s = LocalVariables::declare_this(k, FALSE, 8);
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, k_s);
		inter_name *iname = InterNames::extern(KINDATOMIC_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
			Emit::val_symbol(K_value, k_s);
		Emit::up();
	Emit::up();

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, k_s);
		Emit::code();
		Emit::down();

	LOOP_OVER_BASE_KINDS(K) {
		if (Kinds::Compare::lt(K, K_object)) continue;
		if (Kinds::Behaviour::is_an_enumeration(K)) {
			Emit::inv_primitive(case_interp);
			Emit::down();
				Kinds::RunTime::emit_weak_id_as_val(K);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val(K_value, LITERAL_IVAL, (inter_t)
							Kinds::Behaviour::get_highest_valid_value_as_integer(K));
					Emit::up();
				Emit::up();
			Emit::up();
		}
	}

			Emit::inv_primitive(default_interp);
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val(K_value, LITERAL_IVAL, 0);
					Emit::up();
				Emit::up();
			Emit::up();

		Emit::up();
	Emit::up();
	Routines::end(save);

@ |KOVIsBlockValue(K)| is true if and only if |K| is the I6 ID of a kind
storing pointers to blocks on the heap.

@<Compile KOVIsBlockValue@> =
	packaging_state save = Routines::begin(Hierarchy::find(KOVISBLOCKVALUE_NRL));
	inter_symbol *k_s = LocalVariables::add_named_call_as_symbol(I"k");
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, k_s);
		inter_name *iname = InterNames::extern(KINDATOMIC_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
			Emit::val_symbol(K_value, k_s);
		Emit::up();
	Emit::up();

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, k_s);
		Emit::code();
		Emit::down();
		LOOP_OVER_BASE_KINDS(K) {
			if (Kinds::Compare::lt(K, K_object)) continue;
			if (Kinds::Behaviour::uses_pointer_values(K)) {
				Emit::inv_primitive(case_interp);
				Emit::down();
					Kinds::RunTime::emit_weak_id_as_val(K);
					Emit::code();
					Emit::down();
						Emit::rtrue();
					Emit::up();
				Emit::up();
			}
		}
		Emit::up();
	Emit::up();
	Emit::rfalse();
	Routines::end(save);

@ |KOVSupportFunction(K)| returns the address of the specific support function
for a pointer-value kind |K|, or returns 0 if |K| is not such a kind. For what
such a function does, see "BlockValues.i6t".

@<Compile KOVSupportFunction@> =
	packaging_state save = Routines::begin(Hierarchy::find(KOVSUPPORTFUNCTION_NRL));
	inter_symbol *k_s = LocalVariables::add_named_call_as_symbol(I"k");
	inter_symbol *fail_s = LocalVariables::add_named_call_as_symbol(I"fail");

	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, k_s);
		inter_name *iname = InterNames::extern(KINDATOMIC_EXNAMEF);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
			Emit::val_symbol(K_value, k_s);
		Emit::up();
	Emit::up();

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, k_s);
		Emit::code();
		Emit::down();

	LOOP_OVER_BASE_KINDS(K) {
		if (Kinds::Behaviour::uses_pointer_values(K)) {
			Emit::inv_primitive(case_interp);
			Emit::down();
				Kinds::RunTime::emit_weak_id_as_val(K);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						inter_name *iname = Kinds::Behaviour::get_support_routine_as_iname(K);
						Emit::val_iname(K_value, iname);
					Emit::up();
				Emit::up();
			Emit::up();
		}
	}
		Emit::up();
	Emit::up();

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::val_symbol(K_value, fail_s);
		Emit::code();
		Emit::down();
			Emit::inv_call(InterNames::to_symbol(InterNames::extern(BLKVALUEERROR_EXNAMEF)));
			Emit::down();
				Emit::val_symbol(K_value, fail_s);
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::rfalse();
	Routines::end(save);

@ Code for printing names of kinds at run-time. This needn't run quickly, and
making it a routine rather than using an array saves a few bytes of precious
Z-machine array space.

=
void Kinds::RunTime::I7_Kind_Name_routine(void) {
	kind *K;
	packaging_state save = Routines::begin(Hierarchy::find(I7_KIND_NAME_NRL));
	inter_symbol *k_s = LocalVariables::add_named_call_as_symbol(I"k");
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Compare::lt(K, K_object)) {
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::val_symbol(K_value, k_s);
					Emit::val_iname(K_value, Kinds::RunTime::I6_classname(K));
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(print_interp);
					Emit::down();
						TEMPORARY_TEXT(S);
						WRITE_TO(S, "%+W", Kinds::Behaviour::get_name(K, FALSE));
						Emit::val_text(S);
						DISCARD_TEXT(S);
					Emit::up();
				Emit::up();
			Emit::up();
		}
	Routines::end(save);
}

@ =
int VM_non_support_problem_issued = FALSE;
void Kinds::RunTime::notify_of_use(kind *K) {
	if (VirtualMachines::supports(K) == FALSE) {
		if (VM_non_support_problem_issued == FALSE) {
			VM_non_support_problem_issued = TRUE;
			Problems::Issue::handmade_problem(_p_(PM_KindRequiresGlulx));
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind(2, K);
			Problems::issue_problem_segment(
				"You wrote %1, but with the settings for this project as they are, "
				"I'm unable to make use of %2. (Try changing to Glulx on the Settings "
				"panel; that should fix it.)");
			Problems::issue_problem_end();

		}
	}
}
