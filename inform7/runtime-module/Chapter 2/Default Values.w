[DefaultValues::] Default Values.

An unusual feature of Inform is that every kind has a default value, so that
it is impossible for any variable or property to be uninitialised.

@ The following should compile a default value for |K|, and return

(a) |TRUE| if it succeeded,
(b) |FALSE| if it failed (because $K$ had no values or no default could be
chosen), but no problem message has been issued about this, or
(c) |NOT_APPLICABLE| if it failed and issued a specific problem message.

The wording |W| and detail |storage_name| are used only to issue those problem
messages.

=
int DefaultValues::array_entry(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = DefaultValues::to_holster(&VH, K, W, storage_name, FALSE);
	inter_pair val = Holsters::unholster_to_pair(&VH);
	EmitArrays::generic_entry(val);
	return rv;
}
int DefaultValues::val(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = DefaultValues::to_holster(&VH, K, W, storage_name, FALSE);
	Holsters::unholster_to_code_val(Emit::tree(), &VH);
	return rv;
}
int DefaultValues::val_allowing_nothing(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = DefaultValues::to_holster(&VH, K, W, storage_name, TRUE);
	Holsters::unholster_to_code_val(Emit::tree(), &VH);
	return rv;
}
int DefaultValues::to_holster(value_holster *VH, kind *K,
	wording W, char *storage_name, int allow_nothing_object_as_default) {
	if (Kinds::eq(K, K_value))
		@<"Value" is too vague to be the kind of a variable@>;
	if (Kinds::Behaviour::definite(K) == FALSE)
		@<This is a kind not intended for end users at all@>;
	inter_pair def_val = DefaultValues::to_value_pair(K);
	if (InterValuePairs::is_undef(def_val) == FALSE) {
		if (Holsters::value_pair_allowed(VH)) {
			Holsters::holster_pair(VH, def_val);
			return TRUE;
		}
		internal_error("thwarted on gdv inter");
	}
	if (Kinds::Behaviour::is_subkind_of_object(K))
		@<The kind must have no instances, or it would have worked@>;
	return FALSE;
}

@<The kind must have no instances, or it would have worked@> =
	if (allow_nothing_object_as_default) {
		Holsters::holster_pair(VH, DefaultValues::to_value_pair(K_object));
		return TRUE;
	} else if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		Problems::quote_text(3, storage_name);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyKind2));
		Problems::issue_problem_segment(
			"I am unable to put any value into the %3 %1, which needs to be %2, because the "
			"world does not contain %2.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyKind));
		Problems::issue_problem_segment(
			"I am unable to find %2 to use here, because the world does not contain %2.");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@ The remaining problem messages are no longer seen, since better typechecking
higher up the compiler means that Inform no longer attempts to create variables
or properties with dubious kinds such as |value|.

@<This is a kind not intended for end users at all@> =
	if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create %1 with the kind of value '%2', because this is a kind "
			"of value which is not allowed as something to be stored in properties, "
			"variables and the like.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(1, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create a value of the kind '%1' because this is a kind of value "
			"which is not allowed as something to be stored in properties, variables and the "
			"like.");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@<"Value" is too vague to be the kind of a variable@> =
	Problems::quote_wording_as_source(1, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"I am unable to start %1 off with any value, because the instructions do not tell "
		"me what kind of value it should be (a number, a time, some text perhaps?).");
	Problems::issue_problem_end();
	return NOT_APPLICABLE;

@ The above functions all convert into this one, where the actual choice is made.
If no choice is possible, the function simply returns the |undef| value.

We begin with some special cases where the default value depends on circumstances,
or has to be constructed in a more elaborate way. For example, the default value
of "vehicle" will depend on what vehicles have been created in the source text.
We then turn to the more typical case of kinds whose defaults never change --
for example, the default value of |K_number| is always 0.

The test case |DefaultValues| may be helpful when tinkering with this.

=
inter_pair DefaultValues::to_value_pair(kind *K) {
	if (K == NULL) return InterValuePairs::undef();
	@<Constructed kinds stored as block values@>;
	@<Base kinds stored as block values@>;
	@<Object@>;
	@<Kinds which have instances@>;
	@<Kinds of object which have no instances@>;
	@<Rulebook outcome@>;
	@<Action name@>;
	text_stream *textual_description = K->construct->default_value;
	@<Block values not known to the compiler@>;
	if (Str::len(textual_description) > 0) {
		@<Kinds whose default values are set by Neptune files@>;
	}
	return InterValuePairs::undef();
}

@ These cases are special because different default values are needed for
different constructions with the same constructor: the default phrase
from numbers to numbers is not the same as the one from texts to numbers,
for example.

In two cases here we need to compile something, which we stash inside the
package for the associated //runtime_kind_structure//.

Something to look out for is that when the kind holds block values, stored by
reference, and when that kind is of values which may change, we need to return
a fresh copy each time. This applies in particular to lists and relations,
which are data structures which start out empty but may then grow. So they need
different pointers each time, to different copies of the empty object. (In
the case of lists, it's sufficient to return a new small block each time,
which each wrap the same large block.) Phrases do not have this issue since
they cannot be modified at runtime.

@<Constructed kinds stored as block values@> =
	if (Kinds::get_construct(K) == CON_relation)
		return Emit::to_value_pair(RelationLiterals::default(K));
	if (Kinds::get_construct(K) == CON_list_of) {
		runtime_kind_structure *rks = RTKindIDs::get_rks(K);
		inter_name *dv = RTKindIDs::default_value_from_rks(rks);
		if (rks->default_created == FALSE) {
			rks->default_created = TRUE;
			ListLiterals::default_large_block(dv, K);
		}
		return Emit::to_value_pair(ListLiterals::small_block(dv));
	}
	if (Kinds::get_construct(K) == CON_phrase) {
		runtime_kind_structure *rks = RTKindIDs::get_rks(K);
		inter_name *dv = RTKindIDs::default_value_from_rks(rks);
		if (rks->default_created == FALSE) {
			rks->default_created = TRUE;
			Closures::compile_default_closure(dv, K);
		}
		return Emit::to_value_pair(dv);
	}

@ Text has the same "new one each time" issue as lists and relations have;
stored action does not. Stored actions, again, cannot be modified at runtime.

@<Base kinds stored as block values@> =
	if (Kinds::eq(K, K_stored_action))
		return Emit::to_value_pair(StoredActionLiterals::default());
	if (Kinds::eq(K, K_version_number))
		return Emit::to_value_pair(VersionNumberLiterals::default());
	if (Kinds::eq(K, K_text))
		return Emit::to_value_pair(TextLiterals::default_text());

@ The default value of |K_object| is |nothing|, which is represented at runtime
as the number 0.

@<Object@> =
	if (Kinds::eq(K, K_object))
		return InterValuePairs::number(0);

@ For an enumeration or a subkind of object such as "thing", the default value
is the first one created. That makes for an interesting edge case when there
are no instances, as for example if the author writes:
= (text as Inform 7)
A postage stamp is a kind of thing.
The most valued stamp is a postage stamp that varies.
=
...but never creates any postage stamps. The following will then fail to
find any instances...

@<Kinds which have instances@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K) {
		inter_name *N = RTInstances::value_iname(I);
		return Emit::to_value_pair(N);
	}
	if (Kinds::Behaviour::is_an_enumeration(K))
		return InterValuePairs::undef();

@ ...and that will take us here. Ordinarily we just |return|, triggering a
problem message higher up because we couldn't find a default value.

But we bend the rules and allow |nothing| as the default value of all kinds of
objects when the source text is a roomless one used only to rerelease an old
Z-machine story file; this effectively suppresses problem messages which the
absence of rooms would otherwise result in.

@<Kinds of object which have no instances@> =
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		if (Task::wraps_existing_storyfile())
			return InterValuePairs::number(0);
		return InterValuePairs::undef();
	}

@ Rulebook outcomes are very nearly an enumeration, too, and follow the same
conventions.

@<Rulebook outcome@> =
	if (Kinds::eq(K, K_rulebook_outcome))
		return Emit::to_value_pair(RTRulebooks::default_outcome_iname());

@ Whereas the default action name is |##Wait|. This is handled as a special
case to avoid having to parse double-sharp notation below.

@<Action name@> =
	if (Kinds::eq(K, K_action_name)) {
		inter_name *wait = RTActions::double_sharp(ActionsPlugin::default_action_name());
		return Emit::to_value_pair(wait);
	}

@ If we reach here, we need to take care of a block value not anticipated by
the compiler, i.e., one created in the Neptune files of some kit. We interpret
the absence of any specified default value as meaning "fill a small block with
all zeros", and otherwise we look for a comma-separated list to fill it.

@<Block values not known to the compiler@> =
	if (Kinds::Behaviour::uses_block_values(K)) {
		inter_name *small_block = Enclosures::new_small_block_for_constant();
		packaging_state save = EmitArrays::begin_unchecked(small_block);
		int extent = Kinds::Behaviour::get_short_block_size(K);
		int long_extent = Kinds::Behaviour::get_long_block_size(K);
		if (long_extent == 0)
			TheHeap::emit_short_block_only_value_header(K);
		else
			TheHeap::emit_block_value_header(K, FALSE, extent);
		if (Str::len(textual_description) == 0) {
			for (int i=0; i<extent; i++)
				EmitArrays::numeric_entry(0);
		} else {
			int err = FALSE, count = 0;
			TEMPORARY_TEXT(term)
			for (int i=0, state=1; i<Str::len(textual_description); i++) {
				inchar32_t c = Str::get_at(textual_description, i);
				switch (state) {
					case 1: /* waiting for term */
						if (c == ' ') break;
						if (c == ',') { err = TRUE; break; }
						PUT_TO(term, c); state = 2;
						break;
					case 2: /* reading term */
						if (c == ' ') { @<Complete term@>; state = 3; break; }
						if (c == ',') { @<Complete term@>; state = 1; break; }
						PUT_TO(term, c);
						break;
					case 3: /* waiting for comma */
						if (c == ' ') break;
						if (c == ',') { state = 1; break; }
						err = TRUE; PUT_TO(term, c); state = 2;
						break;
				}
			}
			@<Complete term@>;
			DISCARD_TEXT(term)
			if (count != extent) err = TRUE;
			if (err) {
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
				Problems::quote_kind(1, K);
				Problems::quote_stream(2, textual_description);
				Problems::quote_number(3, &extent);
				Problems::issue_problem_segment(
					"I am unable to create default values for the kind %1, because the "
					"the default value given in its Neptune definition, '%2', is not a "
					"comma-separated list of the right number of values for its short "
					"block extent (i.e., %3), with all of those being numbers or symbol names.");
				Problems::issue_problem_end();
			}
		}
		EmitArrays::end(save);
		return Emit::to_value_pair(small_block);
	}

@<Complete term@> =
	if (Str::len(term) > 0) {
		inter_pair val = DefaultValues::from_Neptune_term(term, K);
		if (InterValuePairs::is_undef(val)) {
			err = TRUE;
			EmitArrays::numeric_entry(0);
		} else {
			EmitArrays::generic_entry(val);
		}
		Str::clear(term);
		count++;
	}

@ Now we reach the most general case, where the default value is something fixed
and specified by a brief textual description taken from a Neptune file.

@<Kinds whose default values are set by Neptune files@> =
	return DefaultValues::from_Neptune_term(textual_description, K);

@ That description has to be very simple: a literal number, |true|, |false|, or an
identifier name which the linker will be able to find -- maybe a function name,
maybe an array, maybe a constant.

This is faster than it looks, but still not fast, and there would be a case to
cache the result. But if so be careful: it would only be safe to cache the
numerical results, because only those are the same in all packages. Symbol
names, for example, are not.

=
inter_pair DefaultValues::from_Neptune_term(text_stream *textual_description, kind *K) {
	inter_pair val = InterValuePairs::number_from_I6_notation(textual_description, NULL);
	if (InterValuePairs::is_undef(val) == FALSE) return val;

	if (Str::eq(textual_description, I"true")) return InterValuePairs::number(1);
	if (Str::eq(textual_description, I"false")) return InterValuePairs::number(0);

	int hl = Hierarchy::kind_default(Kinds::get_construct(K), textual_description);
	return Emit::to_value_pair(Hierarchy::find(hl));
}
