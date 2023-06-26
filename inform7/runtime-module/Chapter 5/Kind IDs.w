[RTKindIDs::] Kind IDs.

To compile the equations submodule for a compilation unit, which contains
_equation packages.

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

=
text_stream *RTKindIDs::identifier_for_weak_ID(kind_constructor *kc) {
	if (Str::len(kc->explicit_identifier) > 0) return kc->explicit_identifier;
	text_stream *invented = Str::new();
	WRITE_TO(invented, "WEAK_ID_%d", kc->allocation_id);
	return invented;
}

inter_name *RTKindIDs::weak_iname(kind *K) {
	if (K == NULL) return RTKindConstructors::weak_ID_iname(CON_UNKNOWN);
	if (Kinds::Behaviour::is_subkind_of_object(K)) K = K_object;
	kind_constructor *con = Kinds::get_construct(K);
	inter_name *iname = RTKindConstructors::weak_ID_iname(con);
	if (iname) return iname;
	LOG("%u has no weak ID iname\n", K);
	internal_error("kind has no weak ID iname");
	return NULL;
}

inter_name *RTKindIDs::weak_iname_of_constructor(kind_constructor *kc) {
	if (kc == NULL) return RTKindConstructors::weak_ID_iname(CON_UNKNOWN);
	if (Kinds::Behaviour::is_subkind_of_object(Kinds::base_construction(kc)))
		return RTKindIDs::weak_iname(K_object);
	return RTKindConstructors::weak_ID_iname(kc);
}

@ And the following compiles an easier-on-the-eye form of the weak ID, but
which might occupy up to 31 characters, the maximum length of an I6 identifier:

=
void RTKindIDs::write_weak_identifier(OUTPUT_STREAM, kind *K) {
	WRITE("%n", RTKindIDs::weak_iname(K));
}

void RTKindIDs::emit_weak_ID_as_val(kind *K) {
	EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K));
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
= (text as Inform 6)
	if ((strong >= 0) && (strong < BASE_KIND_HWM)) weak = strong;
	else weak = strong-->0;
=
We must be careful with comparisons because a strong ID may be numerically
negative if it's a pointer into the upper half of virtual machine memory.

@ In order to be able to give a reasonably complete description of a kind of
value at run-time, we need to store small data structures describing them,
and the following keeps track of which ones we need to make:

=
typedef struct runtime_kind_structure {
	struct kind *kind_described;
	struct parse_node *default_requested_here;
	int make_default;
	struct package_request *rks_package;
	struct inter_name *rks_iname;
	int default_created;
	struct inter_name *rks_dv_iname;
	CLASS_DEFINITION
} runtime_kind_structure;

@ In order to make sure each distinct kind has a unique strong ID, we must
ensure that we always point to the same array every time the same construction
turns up. This means remembering everything we've seen, using a new structure:

=
void RTKindIDs::strong_ID_array_entry(kind *K) {
	runtime_kind_structure *rks = RTKindIDs::get_rks(K);
	if (rks) {
		EmitArrays::iname_entry(rks->rks_iname);
	} else {
		EmitArrays::iname_entry(RTKindIDs::weak_iname(K));
	}
}

void RTKindIDs::emit_strong_ID_as_val(kind *K) {
	runtime_kind_structure *rks = RTKindIDs::get_rks(K);
	if (rks) {
		EmitCode::val_iname(K_value, rks->rks_iname);
	} else {
		RTKindIDs::emit_weak_ID_as_val(K);
	}
}

void RTKindIDs::define_constant_as_strong_id(inter_name *iname, kind *K) {
	runtime_kind_structure *rks = RTKindIDs::get_rks(K);
	if (rks) {
		Emit::iname_constant(iname, K_value, rks->rks_iname);
		return;
	}
	Emit::iname_constant(iname, K_value, RTKindIDs::weak_iname(K));
}

@ Thus the following routine must return |NULL| if $K$ is a kind whose weak
ID is the same as its strong ID -- if it's a base kind, in other words --
and otherwise return a pointer to a unique |runtime_kind_structure| for $K$.

Note that a |CON_TUPLE_ENTRY| node is recursed downwards through, to ensure
that its leaves are passed through |RTKindIDs::get_rks|, but no RKS structure is made
for it -- this is because none is needed, since we're going to roll up
tuple subtrees into flat arrays. Recall that |CON_TUPLE_ENTRY| nodes are
"punctuation", not base kinds in their own right. We can never see them
here except as a result of recursion.

=
runtime_kind_structure *RTKindIDs::get_rks(kind *K) {
	runtime_kind_structure *rks = NULL;
	if (K) {
		int arity = Kinds::arity_of_constructor(K);
		if (arity > 0) {
			if (Kinds::get_construct(K) != CON_TUPLE_ENTRY)
				@<Find or make a runtime kind structure for the kind@>;
			switch (arity) {
				case 1: {
					kind *k = Kinds::unary_construction_material(K);
					RTKindIDs::get_rks(k);
					break;
				}
				case 2: {
					kind *k = NULL, *l = NULL;
					Kinds::binary_construction_material(K, &k, &l);
					RTKindIDs::get_rks(k);
					RTKindIDs::get_rks(l);
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
		if (Kinds::eq(K, rks->kind_described))
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
	rks->rks_package = Hierarchy::local_package(DERIVED_KIND_HAP);
	TEMPORARY_TEXT(TEMP)
	Kinds::Textual::write(TEMP, K);
	wording W = Feeds::feed_text(TEMP);
	rks->rks_iname = Hierarchy::make_iname_with_memo(DK_KIND_HL, rks->rks_package, W);
	DISCARD_TEXT(TEMP)
	rks->default_created = FALSE;
	rks->rks_dv_iname = NULL;

@ It's convenient to combine this system with one which constructs default
values for kinds, since both involve tracking constructions uniquely.

=
inter_name *RTKindIDs::default_value_from_rks(runtime_kind_structure *rks) {
	if (rks) {
		rks->make_default = TRUE;
		if (rks->default_requested_here == NULL)
			rks->default_requested_here = current_sentence;
		if (rks->rks_dv_iname == NULL)
			rks->rks_dv_iname =
				Hierarchy::make_iname_in(DK_DEFAULT_VALUE_HL, rks->rks_package);
		return rks->rks_dv_iname;
	}
	return NULL;
}

@ At the end of Inform's run, then, we have seen various interesting kinds
of value and compiled pointers to arrays representing them. But we haven't
compiled the arrays themselves; so we do that now.

Because these are recursive structures -- the array for a strong ID often
contains references to other strong ID arrays -- it may look as if there's
a risk of further RKS structures being generated, which might make the loop
behave oddly. But this doesn't happen because |RTKindIDs::get_rks| has already
recursively scanned through for us, so that if we have seen a construction
$K$, we have also seen its bases.

=
void RTKindIDs::compile_structures(void) {
	runtime_kind_structure *rks;
	LOOP_OVER(rks, runtime_kind_structure) {
		kind *K = rks->kind_described;
		@<Compile the runtime ID structure for this kind@>;
	}
	@<Annotate rks package@>;
}

@<Compile the runtime ID structure for this kind@> =
	packaging_state save = EmitArrays::begin_word(rks->rks_iname, K_value);
	EmitArrays::iname_entry(RTKindIDs::weak_iname(K));
	@<Compile the list of strong IDs for the bases@>;
	EmitArrays::end(save);

@<Compile the list of strong IDs for the bases@> =
	int arity = Kinds::arity_of_constructor(K);
	if (Kinds::get_construct(K) == CON_phrase) {
		arity--;
		kind *X = NULL, *result = NULL;
		Kinds::binary_construction_material(K, &X, &result);
		@<Expand out a tuple subtree into a simple array@>;
		RTKindIDs::strong_ID_array_entry(result);
	} else if (Kinds::get_construct(K) == CON_combination) {
		arity--;
		kind *X = Kinds::unary_construction_material(K);
		@<Expand out a tuple subtree into a simple array@>;
	} else {
		@<Expand out regular bases@>;
	}

@<Expand out regular bases@> =
	EmitArrays::numeric_entry((inter_ti) arity);
	switch (arity) {
		case 1: {
			kind *X = Kinds::unary_construction_material(K);
			RTKindIDs::strong_ID_array_entry(X);
			break;
		}
		case 2: {
			kind *X = NULL, *Y = NULL;
			Kinds::binary_construction_material(K, &X, &Y);
			RTKindIDs::strong_ID_array_entry(X);
			RTKindIDs::strong_ID_array_entry(Y);
			break;
		}
	}

@<Expand out a tuple subtree into a simple array@> =
	while (Kinds::get_construct(X) == CON_TUPLE_ENTRY) {
		arity++;
		Kinds::binary_construction_material(X, NULL, &X);
	}
	EmitArrays::numeric_entry((inter_ti) arity);
	X = Kinds::unary_construction_material(K);
	while (Kinds::get_construct(X) == CON_TUPLE_ENTRY) {
		arity++;
		kind *term = NULL;
		Kinds::binary_construction_material(X, &term, &X);
		RTKindIDs::strong_ID_array_entry(term);
	}

@<Annotate rks package@> =
	runtime_kind_structure *rks;
	LOOP_OVER(rks, runtime_kind_structure) {
		inter_name *md_iname = Hierarchy::make_iname_in(DK_NEEDED_MD_HL,
			rks->rks_package);
		if (rks->make_default) {
			Emit::numeric_constant(md_iname, (inter_ti) 1);
		} else {
			Emit::numeric_constant(md_iname, (inter_ti) 0);
		}
		Emit::iname_constant(Hierarchy::make_iname_in(DK_STRONG_ID_HL,
			rks->rks_package), K_value, rks->rks_iname);
	}

@h Introspection.
Our runtime code is only capable of very limited introspection: given a
value known to be some kind of object, it can test what kind that is. This
is done with Inter's |OFCLASS_BIP| primitive, and note that this refers to
the kind the way that Inter does -- i.e., by means of the symbol used as
an identifier in the declaration of that kind.

Testing |X ofclass ID|, where |ID| is either the strong or the weak ID, does
not work, and in fact there is in general no way to take a value at runtime
and produce its strong or weak ID. In other words, this works only for
objects. But it is also only needed for objects.

This function, then, would have |subj| equal to the subject for the kind
"container" in order to test the condition ${\it container}(x)$. It returns
|TRUE| if code was required to perform that test, |FALSE| if the test was
already true and required no code. That will in fact happen if |subj| is
not a kind of object, because then the typechecker will have proved already
that the value $x$ has this kind -- in other words, the checking will have
been done at compile time.

=
int RTKindIDs::emit_element_of_condition(inference_subject_family *family,
	inference_subject *subj, inter_symbol *t0_s) {
	kind *K = KindSubjects::to_kind(subj);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		EmitCode::inv(OFCLASS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, t0_s);
			EmitCode::val_iname(K_value, RTKindDeclarations::iname(K));
		EmitCode::up();
		return TRUE;
	}
	if (Kinds::eq(K, K_object)) {
		EmitCode::val_symbol(K_value, t0_s);
		return TRUE;
	}
	return FALSE;
}
