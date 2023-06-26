[RTCommandGrammarTokens::] Command Grammar Tokens.

Compiling single command parser tokens.

@ This section is a single function to compile a general token. Each of the
"handle..." paragraphs is a complete implementation ending with a |return|.
In code mode, we compile code to test for a match and jump to a given
|failure_label| if not, allowing execution to flow through if a match is made;
in array mode, we compile a single array entry to represent the token.

=
int ol_loop_counter = 0;
void RTCommandGrammarTokens::compile(gpr_kit *kit, cg_token *cgt, int code_mode,
	inter_symbol *failure_label, int consult_mode) {

	if (CGTokens::is_literal(cgt)) @<Handle a literal word token@>;

	binary_predicate *bp = cgt->token_relation;
	if (bp) @<Handle a relation token@>;

	parse_node *spec = cgt->what_token_describes;
	if (cgt->defined_by) spec = ParsingPlugin::rvalue_from_command_grammar(cgt->defined_by);

	if (CGTokens::is_I6_parser_token(cgt))
		@<Handle a built-in token@>;

	if (Specifications::is_description(spec))
		@<Handle a description token@>;

	if (cgt->defined_by)
		@<Handle an indirection through another grammar@>;

	if ((Node::is(spec, CONSTANT_NT)) && (Rvalues::is_object(spec)))
		@<Handle a constant object name token@>;

	internal_error("unimplemented token");
}

@ The easiest case: matching a single literal word.

@<Handle a literal word token@> =
	int wn = Wordings::first_wn(CGTokens::text(cgt));
	if (code_mode) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
				TEMPORARY_TEXT(N)
				WRITE_TO(N, "%N", wn);
				EmitCode::val_dword(N);
				DISCARD_TEXT(N)
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
	} else {
		TEMPORARY_TEXT(WT)
		WRITE_TO(WT, "%N", wn);
		EmitArrays::dword_entry(WT);
		DISCARD_TEXT(WT)
	}
	return;

@<Then jump to our doom@> =
	EmitCode::code();
	EmitCode::down();
		@<Jump to our doom@>;
	EmitCode::up();

@<Jump to our doom@> =
	EmitCode::inv(JUMP_BIP);
	EmitCode::down();
		EmitCode::lab(failure_label);
	EmitCode::up();

@ Relation tokens allow, say, "[something related by containment]" to be part
of the grammar for the name of an object. This means that parsing the name of
object X may involve looking for the names of other objects P, Q, R, ... which
are related to X; that may well mean performing a loop, and can be quite slow.
Any such loop must be made as efficiently as possible.

In general, these tokens appear in grammar which matches the name of an object.
Such grammar forms part of a |parse_name| function, which is why we are always
in code mode here, so that there is no array mode implementation to worry about.

There are hand-coded implementations for interactive fiction relations
involving the world model, and then there's a more general implementation for
other relations. For some relations, there's an extra test performed before
the main test (and both must pass, to make a match); for other relations,
there is only the main test.

In all of this code, the |self| pseudo-variable is set to the object X.

@<Handle a relation token@> =
	EmitCode::call(Hierarchy::find(ARTICLEDESCRIPTORS_HL));
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->w_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	if (bp == R_containment) {
		@<Extra test for a containment relation token@>;
	}
	if (bp == R_support) {
		@<Extra test for a support relation token@>;
	}
	if ((bp == a_has_b_predicate) || (bp == R_wearing) || (bp == R_carrying)) {
		@<Extra test for a having, wearing or carrying relation token@>;
	}
	if ((bp == R_containment) ||
		(bp == R_support) ||
		(bp == a_has_b_predicate) ||
		(bp == R_wearing) ||
		(bp == R_carrying)) {
		@<Main test for a possessive relation token@>;
	} else if (bp == R_incorporation) {
		@<Main test for an incorporation relation token@>;
	} else if ((BinaryPredicates::get_reversal(bp) == R_containment) ||
		(BinaryPredicates::get_reversal(bp) == R_support) ||
		(BinaryPredicates::get_reversal(bp) == a_has_b_predicate) ||
		(BinaryPredicates::get_reversal(bp) == R_wearing) ||
		(BinaryPredicates::get_reversal(bp) == R_carrying)) {
		if (BinaryPredicates::get_reversal(bp) == R_carrying) {
			@<Extra test for a reverse carrying relation token@>;
		}
		if (BinaryPredicates::get_reversal(bp) == R_wearing) {
			@<Extra test for a reverse wearing relation token@>;
		}
		@<Main test for a reverse possessive relation token@>;
	} else if (BinaryPredicates::get_reversal(bp) == R_incorporation) {
		@<Main test for a reverse incorporation relation token@>;
	} else {
	    @<Main test for a more general relation token@>;
	}
	return;

@ Here P, Q, R, ... would be objects inside X. This is consistent with the
world model only if X is a container, so we check that.

@<Extra test for a containment relation token@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NOT_BIP);
		EmitCode::down();
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(CONTAINER_HL));
			EmitCode::up();
		EmitCode::up();
		@<Then jump to our doom@>;
	EmitCode::up();

@ Here P, Q, R, ... would be objects on top of X. This is consistent with the
world model only if X is a supporter, so we check that.

@<Extra test for a support relation token@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NOT_BIP);
		EmitCode::down();
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(SUPPORTER_HL));
			EmitCode::up();
		EmitCode::up();
		@<Then jump to our doom@>;
	EmitCode::up();

@ Here P, Q, R, ... would be objects carried by X or worn by X. (The having
relation means either one.) This is consistent with the world model only if X
is a person, so we check that.

@<Extra test for a having, wearing or carrying relation token@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NOT_BIP);
		EmitCode::down();
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(ANIMATE_HL));
			EmitCode::up();
		EmitCode::up();
		@<Then jump to our doom@>;
	EmitCode::up();

@ And this is the main test for any of those relationships, i.e., where for
whatever reason the objects P, Q, R, ... are children of X in the object tree.
We call |TryGivenObject(P)|, then |TryGivenObject(Q)|, and so on, until one
of them succeeds or until all of them have failed.

That being so, the most efficient way to loop through P, Q, R, ... is with an
|OBJECTLOOP_BIP| construct, which is optimised for exactly this.

The local variable |rv| is used temporarily as a loop variable, but set back
to 0 after the loop finishes (win or lose). It would be cleaner to use a new
local variable here; but |parse_name| functions are desperately short of locals
because of the absolute cap on the number of those in the Z-machine VM. So we
recycle.

@<Main test for a possessive relation token@> =
	TEMPORARY_TEXT(L)
	WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
	inter_symbol *success_label = EmitCode::reserve_label(L);
	DISCARD_TEXT(L)

	EmitCode::inv(OBJECTLOOP_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::val_iname(K_value, RTKindDeclarations::iname(K_object));
		EmitCode::inv(IN_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->rv_s);
			EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			if (bp == R_carrying) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
						EmitCode::val_symbol(K_value, kit->rv_s);
						EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(CONTINUE_BIP);
					EmitCode::up();
				EmitCode::up();
			}
			if (bp == R_wearing) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(NOT_BIP);
					EmitCode::down();
						EmitCode::inv(PROPERTYVALUE_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
							EmitCode::val_symbol(K_value, kit->rv_s);
							EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
						EmitCode::up();
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(CONTINUE_BIP);
					EmitCode::up();
				EmitCode::up();
			}
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, kit->w_s);
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::inv(PLUS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, kit->w_s);
					EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->rv_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(GT_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(JUMP_BIP);
					EmitCode::down();
						EmitCode::lab(success_label);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::val_number(0);
	EmitCode::up();
	@<Jump to our doom@>;
	EmitCode::place_label(success_label);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::val_number(0);
	EmitCode::up();

@ Here P, Q, R, ..., are component parts of the object X, and this is not
represented using the VM's object tree but instead with oddball properties.
So we need a completely different implementation, using a |WHILE_BIP|
construct to work through P, Q, R, ... Again, though, we use |rv| as a
temporary loop counter, and we call |TryGivenObject(P)|, then |TryGivenObject(Q)|,
and so on until one of them matches.

@<Main test for an incorporation relation token@> =
	TEMPORARY_TEXT(L)
	WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
	inter_symbol *success_label = EmitCode::reserve_label(L);
	DISCARD_TEXT(L)
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::inv(PROPERTYVALUE_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
			EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_CHILD_HL));
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, kit->rv_s);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, kit->w_s);
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::inv(PLUS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, kit->w_s);
					EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->rv_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(GT_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(JUMP_BIP);
					EmitCode::down();
						EmitCode::lab(success_label);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->rv_s);
				EmitCode::inv(PROPERTYVALUE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
					EmitCode::val_symbol(K_value, kit->rv_s);
					EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_SIBLING_HL));
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::val_number(0);
	EmitCode::up();
	@<Jump to our doom@>;
	EmitCode::place_label(success_label);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::val_number(0);
	EmitCode::up();

@ That might seem to complete our work on the special IF world model relations...
but no, we're only halfway, because now we need to handle their reversals.

However, the reversals are easier and execute more quickly, because whereas X
can potentially carry many possible things P, Q, R, ..., it can only be carried
by at most one: P.

For this to be consistent in the world model, X must not have the "worn" property --
because then, of course, it would be worn by P and not carried by P:

@<Extra test for a reverse carrying relation token@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(PROPERTYVALUE_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
			EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
		EmitCode::up();
		@<Then jump to our doom@>;
	EmitCode::up();

@ Similarly, for X to be worn by P, X must have the "worn" property:

@<Extra test for a reverse wearing relation token@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NOT_BIP);
		EmitCode::down();
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
			EmitCode::up();
		EmitCode::up();
		@<Then jump to our doom@>;
	EmitCode::up();

@ And in all cases (except incorporation) P must be the object-tree parent of X:

@<Main test for a reverse possessive relation token@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::inv(PARENT_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit->w_s);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::inv(PLUS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->w_s);
			EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->rv_s);
				EmitCode::val_true();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::val_symbol(K_value, kit->w_s);
		EmitCode::up();
		@<Then jump to our doom@>;
	EmitCode::up();

@ So that just leaves incorporation, where the idea is the same, but where
properties rather than the object tree implement the relation.

@<Main test for a reverse incorporation relation token@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->rv_s);
		EmitCode::inv(PROPERTYVALUE_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
			EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_PARENT_HL));
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit->w_s);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::inv(PLUS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->w_s);
			EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->rv_s);
				EmitCode::val_true();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::val_symbol(K_value, kit->w_s);
		EmitCode::up();
		@<Then jump to our doom@>;
	EmitCode::up();

@ And now we really have disposed of the IF cases, and can turn to a general
relation. Here X will relate to some collection P, Q, R, ... of possibilities,
and we loop through them. There are three different implementations of the
loop head, which manages the "through them" part, and then a common implementation
of what to do in the loop -- i.e., test the possibility and jump to |success_label|
if it works.

@<Main test for a more general relation token@> =
	TEMPORARY_TEXT(L)
	WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
	inter_symbol *success_label = EmitCode::reserve_label(L);
	DISCARD_TEXT(L)

	if ((BinaryPredicates::get_test_function(bp)) ||
		(BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp))))
		@<Main test for a general relation by schema@>;
	if (ExplicitRelations::get_i6_storage_property(bp))
		@<Main test for a general relation by property@>;
	internal_error("unimplemented relation token");

@<Main test for a general relation by schema@> =
	i6_schema *i6s;
	int reverse = FALSE;
	i6s = BinaryPredicates::get_test_function(bp);
	LOGIF(GRAMMAR_CONSTRUCTION, "Read I6s $i from $2\n", i6s, bp);
	if ((i6s == NULL) &&
		(BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp)))) {
		reverse = TRUE;
		i6s = BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp));
		LOGIF(GRAMMAR_CONSTRUCTION, "But read I6s $i from reversal\n", i6s);
	}
	if (i6s) @<Open a general relation search loop using a schema@>;

@<Open a general relation search loop using a schema@> =
	kind *K = BinaryPredicates::term_kind(bp, 1);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		LOGIF(GRAMMAR_CONSTRUCTION, "Term 1 of BP is %u\n", K);
		EmitCode::inv(OBJECTLOOPX_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_iname(K_value, RTKindDeclarations::iname(K));
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						pcalc_term rv_term = Terms::new_constant(
							Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, kit->rv_lv));
						pcalc_term self_term = Terms::new_constant(
							Rvalues::new_self_object_constant());
						if (reverse)
							CompileSchemas::from_terms_in_val_context(i6s, &rv_term, &self_term);
						else
							CompileSchemas::from_terms_in_val_context(i6s, &self_term, &rv_term);
						EmitCode::val_false();
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(CONTINUE_BIP);
					EmitCode::up();
				EmitCode::up();
		@<Conclude the general relation search loop@>;
	} else internal_error("unimplemented for non-objects");
	return;

@<Main test for a general relation by property@> =
	property *prn = ExplicitRelations::get_i6_storage_property(bp);
	int reverse = FALSE;
	if (BinaryPredicates::is_the_wrong_way_round(bp)) reverse = TRUE;
	if (ExplicitRelations::get_form_of_relation(bp) == Relation_VtoO) {
		if (reverse) reverse = FALSE; else reverse = TRUE;
	}
	if (prn) {
		if (reverse) @<Open a general relation search loop using a reversed property@>
		else @<Open a general relation search loop using a forwards property@>;
	}

@<Open a general relation search loop using a reversed property@> =
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(PROPERTYEXISTS_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_value, RTProperties::iname(prn));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();

				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, kit->rv_s);
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
						EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->rv_s);
						EmitCode::val_false();
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						@<Jump to our doom@>;
					EmitCode::up();
				EmitCode::up();

		@<Conclude the general relation search loop@>;
		return;

@<Open a general relation search loop using a forwards property@> =
		kind *K = BinaryPredicates::term_kind(bp, 1);
		EmitCode::inv(OBJECTLOOPX_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_iname(K_value, RTKindDeclarations::iname(K));
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::inv(AND_BIP);
						EmitCode::down();
							EmitCode::inv(PROPERTYEXISTS_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
								EmitCode::val_symbol(K_value, kit->rv_s);
								EmitCode::val_iname(K_value, RTProperties::iname(prn));
							EmitCode::up();
							EmitCode::inv(EQ_BIP);
							EmitCode::down();
								EmitCode::inv(PROPERTYVALUE_BIP);
								EmitCode::down();
									EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
									EmitCode::val_symbol(K_value, kit->rv_s);
									EmitCode::val_iname(K_value, RTProperties::iname(prn));
								EmitCode::up();
								EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
							EmitCode::up();
						EmitCode::up();
						EmitCode::val_false();
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(CONTINUE_BIP);
					EmitCode::up();
				EmitCode::up();

		@<Conclude the general relation search loop@>;
		return;

@ Those three general relation searches all share the same loop-end code:

@<Conclude the general relation search loop@> =
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::up();

				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::inv(PLUS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->w_s);
						EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
						EmitCode::down();
							EmitCode::val_symbol(K_value, kit->rv_s);
							EmitCode::val_true();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();

				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(GT_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::val_symbol(K_value, kit->w_s);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(JUMP_BIP);
						EmitCode::down();
							EmitCode::lab(success_label);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();

			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_number(0);
		EmitCode::up();
		@<Jump to our doom@>;
		EmitCode::place_label(success_label);
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_number(0);
		EmitCode::up();

@ And this is one of the specially-worded convenience tokens like "[things]":

@<Handle a built-in token@> =
	inter_name *i6_token_iname = RTCommandGrammars::iname_for_I6_parser_token(cgt);
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->w_s);
			EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(ELEMENTARY_TT_HL));
				EmitCode::val_iname(K_value, i6_token_iname);
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_symbol(K_value, kit->w_s);
		EmitCode::up();
	} else {
		EmitArrays::iname_entry(i6_token_iname);
	}
	return;

@ This is for a token like "[an open door]" which describes a range of values.
The possibilities are, fortunately, much constrained by what typechecking allowed.

@<Handle a description token@> =
	if (Descriptions::is_qualified(spec)) @<Handle a qualified description token@>;

	kind *K = Specifications::to_kind(spec);
	if (Kinds::Behaviour::is_object(K)) @<Handle an unqualified common noun object token@>;
	if (K) @<Handle an unqualified common noun non-object token@>;

	internal_error("unimplemented description token");
	return;

@ For "[an open door]", say, where adjectives qualify the noun: there is no
option but to create a noun-filter token.

@<Handle a qualified description token@> =
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->w_s);
			NounFilterTokens::function_and_filter(cgt->noun_filter);
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_symbol(K_value, kit->w_s);
		EmitCode::up();
	} else {
		NounFilterTokens::array_entry(cgt->noun_filter);
	}
	return;

@ For "[door]", say, where there is just a common noun and it is a kind of
object, we again use a noun-filter token:

@<Handle an unqualified common noun object token@> =
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->w_s);
			NounFilterTokens::function_and_filter(cgt->noun_filter);
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_symbol(K_value, kit->w_s);
		EmitCode::up();
	} else {
		NounFilterTokens::array_entry(cgt->noun_filter);
	}
	return;

@ Here we have a token like "[number]", say.

@<Handle an unqualified common noun non-object token@> =
	inter_name *GPR = RTKindConstructors::GPR_iname(K);
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->w_s);
			EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
				EmitCode::val_iname(K_value, GPR);
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
		EmitCode::up();
	} else {
		EmitArrays::iname_entry(GPR);
	}
	return;

@ This is for a token like "[dingbats]", where that has itself been given a
grammar ("Understand "flower" as "[dingbats]"."). All we need do is to call
that token's own GPR.

@<Handle an indirection through another grammar@> =
	command_grammar *cg = cgt->defined_by;
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->w_s);
			EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
				EmitCode::val_iname(K_value, RTCommandGrammars::get_cg_token_iname(cg));
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, kit->rv_s);
					EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		EmitArrays::iname_entry(RTCommandGrammars::get_cg_token_iname(cg));
	}
	return;

@<Handle a constant object name token@> =
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->w_s);
			NounFilterTokens::function_and_filter(cgt->noun_filter);
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->rv_s);
			EmitCode::val_symbol(K_value, kit->w_s);
		EmitCode::up();
	} else {
		NounFilterTokens::array_entry(cgt->noun_filter);
	}
	return;
