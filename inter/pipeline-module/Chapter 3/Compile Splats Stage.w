[CompileSplatsStage::] Compile Splats Stage.

To replace each splat node with a sequence of pure Inter nodes having the same
meaning, thus purging the tree of all raw I6 syntax entirely.

@h Basic idea.
Assimilation is a multi-stage process, but really this stage is the heart of it.
We expect that |resolve-conditional-compilation| has already run, so that the
splats in the tree represent directives which all have definite effect. With
the conditional compilation splats gone, we are left with these:
= (text)
ARRAY_I6DIR         ATTRIBUTE_I6DIR     CONSTANT_I6DIR      DEFAULT_I6DIR
FAKEACTION_I6DIR    GLOBAL_I6DIR        OBJECT_I6DIR        PROPERTY_I6DIR
ROUTINE_I6DIR       STUB_I6DIR          VERB_I6DIR
=
And we must turn those into splatless Inter code with the same effect. In some
cases, notably |ROUTINE_I6DIR| which contains an entire Inform 6-notation
function definition, that is quite a lot of work.

=
void CompileSplatsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"compile-splats", CompileSplatsStage::run, NO_STAGE_ARG, FALSE);
}

@ We divide the task up into three traverses:

(1) |PROPERTY_I6DIR|, |ATTRIBUTE_I6DIR|, |ROUTINE_I6DIR|, |STUB_I6DIR|;
(2) |DEFAULT_I6DIR|, |CONSTANT_I6DIR|, |FAKEACTION_I6DIR|, |OBJECT_I6DIR|, |VERB_I6DIR|, |ARRAY_I6DIR|;
(3) |GLOBAL_I6DIR|.

=
int CompileSplatsStage::run(pipeline_step *step) {
	compile_splats_state css;
	@<Initialise the CS state@>;
	inter_tree *I = step->ephemera.tree;
	InterTree::traverse(I, CompileSplatsStage::visitor1, &css, NULL, SPLAT_IST);
	InterTree::traverse(I, CompileSplatsStage::visitor2, &css, NULL, 0);
	int errors_found = CompileSplatsStage::function_bodies(step, &css, I);
	if (errors_found) return FALSE;
	InterTree::traverse(I, CompileSplatsStage::visitor3, &css, NULL, SPLAT_IST);
	return TRUE;
}

@ During this process, the following state is shared across all three traverses:

=
typedef struct compile_splats_state {
	struct pipeline_step *from_step;
	int no_assimilated_actions;
	int no_assimilated_directives;
	struct linked_list *function_bodies_to_compile; /* of |function_body_request| */
} compile_splats_state;

@<Initialise the CS state@> =
	css.from_step = step;
	css.no_assimilated_actions = 0;
	css.no_assimilated_directives = 0;
	css.function_bodies_to_compile = NEW_LINKED_LIST(function_body_request);

@ The three traverse functions share a great deal of their code, in fact. Note
that we set the assimilation package to be the module containing whatever splat
is being compiled.

=
void CompileSplatsStage::visitor1(inter_tree *I, inter_tree_node *P, void *state) {
	compile_splats_state *css = (compile_splats_state *) state;
	pipeline_step *step = css->from_step;
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = InterPackage::at_this_head(P);
		inter_symbol *ptype = InterPackage::type(pack);
		if (Str::eq(InterSymbol::identifier(ptype), I"_module"))
			step->pipeline->ephemera.assimilation_modules[step->tree_argument] = pack;
	}
	if (P->W.instruction[ID_IFLD] == SPLAT_IST) {
		inter_ti directive = P->W.instruction[PLM_SPLAT_IFLD];
		switch (directive) {
			case PROPERTY_I6DIR:
			case ATTRIBUTE_I6DIR:
				@<Assimilate definition@>;
				break;
			case ROUTINE_I6DIR:
			case STUB_I6DIR:
				@<Assimilate routine@>;
				break;
		}
	}
}

void CompileSplatsStage::visitor2(inter_tree *I, inter_tree_node *P, void *state) {
	compile_splats_state *css = (compile_splats_state *) state;
	pipeline_step *step = css->from_step;
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = InterPackage::at_this_head(P);
		inter_symbol *ptype = InterPackage::type(pack);
		if (Str::eq(InterSymbol::identifier(ptype), I"_module"))
			step->pipeline->ephemera.assimilation_modules[step->tree_argument] = pack;
	}
	if (P->W.instruction[ID_IFLD] == SPLAT_IST) {
		inter_ti directive = P->W.instruction[PLM_SPLAT_IFLD];
		switch (directive) {
			case ARRAY_I6DIR:
			case DEFAULT_I6DIR:
			case CONSTANT_I6DIR:
			case FAKEACTION_I6DIR:
			case OBJECT_I6DIR:
			case VERB_I6DIR:
				@<Assimilate definition@>;
				break;
		}
	}
}

void CompileSplatsStage::visitor3(inter_tree *I, inter_tree_node *P, void *state) {
	compile_splats_state *css = (compile_splats_state *) state;
	pipeline_step *step = css->from_step;
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = InterPackage::at_this_head(P);
		inter_symbol *ptype = InterPackage::type(pack);
		if (Str::eq(InterSymbol::identifier(ptype), I"_module"))
			step->pipeline->ephemera.assimilation_modules[step->tree_argument] = pack;
	}
	if (P->W.instruction[ID_IFLD] == SPLAT_IST) {
		inter_ti directive = P->W.instruction[PLM_SPLAT_IFLD];
		switch (directive) {
			case GLOBAL_I6DIR:
				@<Assimilate definition@>;
				break;
		}
	}
}

@h How definitions are assimilated.

@<Assimilate definition@> =
	match_results mr = Regexp::create_mr();
	text_stream *identifier = NULL, *value = NULL;
	int proceed = TRUE;
	@<Parse text of splat for identifier and value@>;
	if (proceed) {
		@<Insert sharps in front of fake action identifiers@>;
		@<Perhaps compile something from this splat@>;
		NodePlacement::remove(P);
	}
	Regexp::dispose_of(&mr);

@ This code is used for a range of different Inform 6 syntaxes which create
something with a given identifier name, and sometimes supply a value. For example,
= (text as Inform 6)
	Constant Italian_Meringue_Temperature = 121;
	Fake_Action Bake;
	Attribute split;
	Object Compass "compass";
=
The following finds the identifier as the second token, i.e., after the directive
keyword |Constant| or similar. Note that an |Object| declaration does not
meaningfully have a value, even though a third token is present.

@<Parse text of splat for identifier and value@> =
	text_stream *S = Inode::ID_to_text(P, P->W.instruction[MATTER_SPLAT_IFLD]);
	if (directive == VERB_I6DIR) {
		if (Regexp::match(&mr, S, L" *%C+ (%c*?) *;%c*")) {
			identifier = I"assim_gv"; value = mr.exp[0];
		} else {
			LOG("Unable to parse start of VERB_I6DIR: '%S'\n", S); proceed = FALSE;
		}
	} else {
		if (Regexp::match(&mr, S, L" *%C+ *(%C+?)(--> *%c*?) *;%c*")) {
			identifier = mr.exp[0]; value = mr.exp[1];
		} else if (Regexp::match(&mr, S, L" *%C+ *(%C+?)(-> *%c*?) *;%c*")) {
			identifier = mr.exp[0]; value = mr.exp[1];
		} else if (Regexp::match(&mr, S, L" *%C+ (%C*?) *;%c*")) {
			identifier = mr.exp[0];
		} else if (Regexp::match(&mr, S, L" *%C+ (%C*) *= *(%c*?) *;%c*")) {
			identifier = mr.exp[0]; value = mr.exp[1];
		} else if (Regexp::match(&mr, S, L" *%C+ (%C*) (%c*?) *;%c*")) {
			identifier = mr.exp[0]; value = mr.exp[1];
		} else {
			LOG("Unable to parse start of constant: '%S'\n", S); proceed = FALSE;
		}
		if (directive == OBJECT_I6DIR) value = NULL;
	}
	Str::trim_all_white_space_at_end(identifier);

@ An eccentricity of Inform 6 syntax is that fake action names ought to be given
in the form |Fake_Action ##Bake|, but are not. The constant created by |Fake_Action Bake|
is nevertheless |##Bake|, so we take care of that here.

@<Insert sharps in front of fake action identifiers@> =
	if (directive == FAKEACTION_I6DIR) {
		text_stream *old = identifier;
		identifier = Str::new();
		WRITE_TO(identifier, "##%S", old);
	}

@ The Inform 6 directive
= (text as Inform 6)
	Default Vanilla_Pod 1;
=
is essentially equivalent to
= (text as Inform 6)
	#Ifndef Vanilla_Pod;
	Constant Vanilla_Pod = 1;
	#Endif;
=
So this is a piece of conditional compilation in disguise, and should perhaps
have been removed from the tree by the |resolve-conditional-compilation| stage. 
But in fact it's easier to handle it here.

@<Perhaps compile something from this splat@> =
	if (directive == DEFAULT_I6DIR) {
		if (Wiring::find_socket(I, identifier) == NULL) {
			directive = CONSTANT_I6DIR;
			@<Definitely compile something from this splat@>;
		}
	} else {
		@<Definitely compile something from this splat@>;
	}

@ So if we're here, we have reduced the possibilities to:
= (text)
ARRAY_I6DIR         ATTRIBUTE_I6DIR     CONSTANT_I6DIR      FAKEACTION_I6DIR
GLOBAL_I6DIR        OBJECT_I6DIR        PROPERTY_I6DIR		VERB_I6DIR
=
We basically do the same thing in all of these cases: decide where to put
the result, declare a symbol for it, and then define that symbol.

@<Definitely compile something from this splat@> =
	inter_bookmark content_at;
	@<Work out where in the Inter tree to put the material we are making@>;

	inter_symbol *made_s;
	@<Declare the Inter symbol for what we will shortly make@>;
	if ((directive == ATTRIBUTE_I6DIR) || (directive == PROPERTY_I6DIR))
	    @<Declare a property ID symbol to go with it@>;
	
	@<Make a definition for made_s@>;

@ So, for example, |Constant Vanilla_Pod = 1;| might result in the symbol
|Vanilla_Pod| being created and defined with a |CONSTANT_IST| Inter node,
all inside the package |/main/HypotheticalKit/constants/Vanilla_Pod_con|.

Which frankly looks over-engineered for a simple constant, but some of these
definitions are not so simple.

@<Work out where in the Inter tree to put the material we are making@> =
	text_stream *submodule_name = NULL;
	text_stream *suffix = NULL;
	inter_symbol *subpackage_type = NULL;
	@<Work out what submodule to put this new material into@>;
	if (Str::len(submodule_name) > 0) {
		content_at = CompileSplatsStage::make_submodule(I, step, submodule_name, P);
		@<Create a little package within that submodule to hold the content@>
	} else {
		content_at = InterBookmark::after_this_node(P);
	}

@<Work out what submodule to put this new material into@> =
	switch (directive) {
		case VERB_I6DIR:
			subpackage_type = RunningPipelines::get_symbol(step, command_ptype_RPSYM);
			submodule_name = I"commands"; suffix = NULL; break;
		case ARRAY_I6DIR:
			submodule_name = I"arrays"; suffix = I"arr"; break;
		case CONSTANT_I6DIR:
		case FAKEACTION_I6DIR:
		case OBJECT_I6DIR:
			submodule_name = I"constants"; suffix = I"con"; break;
		case GLOBAL_I6DIR:
			submodule_name = I"variables"; suffix = I"var"; break;
		case ATTRIBUTE_I6DIR:
		case PROPERTY_I6DIR:
			subpackage_type = RunningPipelines::get_symbol(step, property_ptype_RPSYM);
			submodule_name = I"properties"; suffix = I"prop"; break;
	}
	if ((Str::len(submodule_name) > 0) && (subpackage_type == NULL))
		subpackage_type = RunningPipelines::get_symbol(step, plain_ptype_RPSYM);

@ The practical effect of this is to create all the packages needed which are
not already there.

@<Create a little package within that submodule to hold the content@> =
	TEMPORARY_TEXT(subpackage_name)
	if (suffix) {
		WRITE_TO(subpackage_name, "%S_%S", identifier, suffix);
	} else {
		WRITE_TO(subpackage_name, "assimilated_directive_%d",
			++css->no_assimilated_directives);
	}
	inter_package *subpackage =
		Produce::make_subpackage(&content_at, subpackage_name, subpackage_type);
	InterBookmark::move_into_package(&content_at, subpackage);
	DISCARD_TEXT(subpackage_name)

@ Now we declare |made_s| as a symbol inside this package.

@<Declare the Inter symbol for what we will shortly make@> =	
	made_s = CompileSplatsStage::make_socketed_symbol(&content_at, identifier);
	if (Wiring::is_wired(made_s)) {
		inter_symbol *external_name = Wiring::wired_to(made_s);
		Wiring::wire_to(external_name, made_s);
		Wiring::wire_to(made_s, NULL);
	}
	SymbolAnnotation::set_b(made_s, ASSIMILATED_IANN, 1);
	if (directive == FAKEACTION_I6DIR) SymbolAnnotation::set_b(made_s, FAKE_ACTION_IANN, TRUE);
	if (directive == OBJECT_I6DIR) SymbolAnnotation::set_b(made_s, OBJECT_IANN, TRUE);
	if (directive == ATTRIBUTE_I6DIR) SymbolAnnotation::set_b(made_s, EITHER_OR_IANN, TRUE);
	if (directive == VERB_I6DIR) InterSymbol::set_flag(made_s, MAKE_NAME_UNIQUE_ISYMF);

@<Declare a property ID symbol to go with it@> =
	inter_bookmark *IBM = &content_at;
	inter_symbol *id_s = CompileSplatsStage::make_socketed_symbol(IBM, I"property_id");	
	InterSymbol::set_flag(id_s, MAKE_NAME_UNIQUE_ISYMF);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM), InterTypes::untyped());
	Produce::guard(Inter::Constant::new_numerical(IBM,
		InterSymbolsTable::id_from_symbol(I, InterBookmark::package(IBM), id_s),
		KID, InterValuePairs::number(0), (inter_ti) InterBookmark::baseline(IBM) + 1, NULL));

@<Make a definition for made_s@> =
	inter_bookmark *IBM = &content_at;
	switch (directive) {
		case CONSTANT_I6DIR:
		case FAKEACTION_I6DIR:
		case OBJECT_I6DIR:
			@<Make a scalar constant in Inter@>;
			break;
		case GLOBAL_I6DIR:
			@<Make a global variable in Inter@>;
			break;
		case PROPERTY_I6DIR:
			@<Make a general property in Inter@>;
			break;
		case ATTRIBUTE_I6DIR:
			@<Make an either-or property in Inter@>;
			break;
		case VERB_I6DIR:
		case ARRAY_I6DIR:
		    @<Make a list constant in Inter@>;
			break;
	}

@<Make a scalar constant in Inter@> =
	inter_ti MID = InterSymbolsTable::id_from_symbol(I, InterBookmark::package(IBM), made_s);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM), InterTypes::untyped());
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	inter_pair val = InterValuePairs::undef();
	@<Assimilate a value@>;
	Produce::guard(Inter::Constant::new_numerical(IBM, MID, KID, val, B, NULL));

@<Make a global variable in Inter@> =
	inter_ti MID = InterSymbolsTable::id_from_symbol(I, InterBookmark::package(IBM), made_s);
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	inter_pair val = InterValuePairs::undef();
	@<Assimilate a value@>;
	Produce::guard(Inter::Variable::new(IBM, MID, InterTypes::untyped(), val, B, NULL));

@<Make a general property in Inter@> =
	inter_ti MID = InterSymbolsTable::id_from_symbol(I, InterBookmark::package(IBM), made_s);
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	Produce::guard(Inter::Property::new(IBM, MID, InterTypes::untyped(), B, NULL));

@<Make an either-or property in Inter@> =
	inter_ti MID = InterSymbolsTable::id_from_symbol(I, InterBookmark::package(IBM), made_s);
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	Produce::guard(Inter::Property::new(IBM, MID,
		InterTypes::from_constructor_code(INT2_ITCONC), B, NULL));

@ A typical Inform 6 array declaration looks like this:
= (text as Inform 6)
	Array Example table 2 (-56) 17 "hey, I am typeless" ' ';
=

@d MAX_ASSIMILATED_ARRAY_ENTRIES 10000

@<Make a list constant in Inter@> =
	match_results mr = Regexp::create_mr();
	text_stream *conts = NULL;
	inter_ti annot = INVALID_IANN;
	@<Work out the format of the array and the string of contents@>;
	if (annot != INVALID_IANN) SymbolAnnotation::set_b(made_s, annot, TRUE);

	inter_ti v1_pile[MAX_ASSIMILATED_ARRAY_ENTRIES], v2_pile[MAX_ASSIMILATED_ARRAY_ENTRIES];
	int no_assimilated_array_entries = 0;
	if (directive == ARRAY_I6DIR)
		@<Compile the string of array contents into the pile of v1 and v2 values@>
	else
		@<Compile the string of command grammar contents into the pile of v1 and v2 values@>;

	inter_ti MID = InterSymbolsTable::id_from_symbol(I, InterBookmark::package(IBM), made_s);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM),
		InterTypes::from_constructor_code(LIST_ITCONC));
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	Produce::guard(Inter::Constant::new_list(IBM, MID, KID, no_assimilated_array_entries,
		v1_pile, v2_pile, B, NULL));
	Regexp::dispose_of(&mr);

@ At this point |value| is |table 2 (-56) 17 "hey, I am typeless" ' '|. We want
first to work out which of the several array formats this is (|TABLEARRAY_IANN|
in this instance), then the contents |2 (-56) 17 "hey, I am typeless" ' '|.

@<Work out the format of the array and the string of contents@> =
	if (directive == ARRAY_I6DIR) {
		if (Regexp::match(&mr, value, L" *--> *(%c*?) *")) {
			conts = mr.exp[0]; annot = INVALID_IANN;
		} else if (Regexp::match(&mr, value, L" *-> *(%c*?) *")) {
			conts = mr.exp[0]; annot = BYTEARRAY_IANN;
		} else if (Regexp::match(&mr, value, L" *table *(%c*?) *")) {
			conts = mr.exp[0]; annot = TABLEARRAY_IANN;
		} else if (Regexp::match(&mr, value, L" *buffer *(%c*?) *")) {
			conts = mr.exp[0]; annot = BUFFERARRAY_IANN;
		} else {
			LOG("Identifier = <%S>, Value = <%S>", identifier, value);
			PipelineErrors::kit_error("invalid Inform 6 array declaration", NULL);
		}
	} else {
		conts = value; annot = VERBARRAY_IANN;
	}

@ The contents text is now tokenised, and each token produces an array entry.

Although it is legal in Inform 6 to write arrays like, say.
= (text as Inform 6)
	Array Example --> 'a' + 2 (24);
=
where the entries are specified in a way using arithmetic operators, we won't
support that here: the standard Inform kits do not need it, and it's hard to
see why other kits would, either.

@<Compile the string of array contents into the pile of v1 and v2 values@> =
	string_position spos = Str::start(conts);
	int finished = FALSE;
	while (finished == FALSE) {
		TEMPORARY_TEXT(value)
		@<Extract a token@>;
		if (Str::eq(value, I"+"))
			PipelineErrors::kit_error("Inform 6 array declaration using operator '+'", NULL);
		if (Str::eq(value, I"-"))
			PipelineErrors::kit_error("Inform 6 array declaration using operator '-'", NULL);
		if (Str::eq(value, I"*"))
			PipelineErrors::kit_error("Inform 6 array declaration using operator '*'", NULL);
		if (Str::eq(value, I"/"))
			PipelineErrors::kit_error("Inform 6 array declaration using operator '/'", NULL);

		if (Str::len(value) > 0) {
			inter_pair val = InterValuePairs::undef();
			@<Assimilate a value@>;
			@<Add value to the entry pile@>;
		} else finished = TRUE;
		DISCARD_TEXT(value)
	}

@ In command grammar introduced by |Verb|, the tokens |*| and |/| can occur
without having any arithmetic meaning, so they must not be rejected. That's
really why we treat this case as different, though we also treat keywords
occurring after |->| markers as being action names, and introduce |##|s to
their names. Thus in:
= (text as Inform 6)
	Verb 'do' * 'something' -> Do;
=
the action name |Do| is converted automatically to |##Do|, the actual identifier
for the action.

@<Compile the string of command grammar contents into the pile of v1 and v2 values@> =
	string_position spos = Str::start(conts);
	int NT = 0, next_is_action = FALSE, finished = FALSE;
	while (finished == FALSE) {
		TEMPORARY_TEXT(value)
		if (next_is_action) WRITE_TO(value, "##");
		@<Extract a token@>;
		if (next_is_action) @<Ensure that a socket exists for this action name@>;
		next_is_action = FALSE;
		if ((NT++ == 0) && (Str::eq(value, I"meta"))) {
			SymbolAnnotation::set_b(made_s, METAVERB_IANN, TRUE);
		} else if (Str::len(value) > 0) {
			inter_pair val = InterValuePairs::undef();
			@<Assimilate a value@>;
			@<Add value to the entry pile@>;
			if (Str::eq(value, I"->")) next_is_action = TRUE;
		} else finished = TRUE;
		DISCARD_TEXT(value)
	}

@ So here |value| is something like |##ScriptOn|, an action name. Maybe that has
already been defined in the kit currently being compiked, in which case a socket
for it already exists; but maybe not, in which case we have to create the
action. This will be a package at, say, |/main/HypotheticalKit/actions/assim_action_1|
with three things in it:

(a) an ID, |action_id|;
(b) the action name, |##ScriptOn|;
(c) the function to carry out the action, |ScriptOnSub|.

@<Ensure that a socket exists for this action name@> =
	if (Wiring::find_socket(I, value) == NULL) {
		inter_bookmark IBM_d = CompileSplatsStage::make_submodule(I, step, I"actions", P);
		inter_bookmark *IBM = &IBM_d;
		
		inter_package *action_package;
		@<Make a package for the new action, inside the actions submodule@>;
		InterBookmark::move_into_package(IBM, action_package);

		@<Make an action_id symbol in the action package@>;
		@<Make the actual double-sharped action symbol@>;
		@<Make a symbol equated to the function carrying out the action@>;
	}

@<Make a package for the new action, inside the actions submodule@> =		
	inter_symbol *ptype = RunningPipelines::get_symbol(step, action_ptype_RPSYM);
	if (ptype == NULL) ptype = RunningPipelines::get_symbol(step, plain_ptype_RPSYM);
	TEMPORARY_TEXT(an)
	WRITE_TO(an, "assim_action_%d", ++css->no_assimilated_actions);
	action_package = Produce::make_subpackage(IBM, an, ptype);
	DISCARD_TEXT(an)

@ Each action package has to contain an |action_id| symbol, which will eventually
be defined as a unique ID for the action. But those unique IDs can only be
assigned at link time -- at this stage we cannot know what other actions exist
in other compilation units. So we create |action_id| equal just to 0 for now.

@<Make an action_id symbol in the action package@> =
	inter_package *pack = InterBookmark::package(IBM);
	inter_symbol *action_id_s = InterSymbolsTable::create_with_unique_name(
		InterBookmark::scope(IBM), I"action_id");
	inter_ti MID = InterSymbolsTable::id_from_symbol(I, pack, action_id_s);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM), InterTypes::untyped());
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	Produce::guard(Inter::Constant::new_numerical(IBM, MID, KID, InterValuePairs::number(0), B, NULL));
	InterSymbol::set_flag(action_id_s, MAKE_NAME_UNIQUE_ISYMF);

@<Make the actual double-sharped action symbol@> =
	inter_package *pack = InterBookmark::package(IBM);
	inter_symbol *action_s = CompileSplatsStage::make_socketed_symbol(IBM, value);
	inter_ti MID = InterSymbolsTable::id_from_symbol(I, pack, action_s);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM), InterTypes::untyped());
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	Produce::guard(Inter::Constant::new_numerical(IBM, MID, KID, InterValuePairs::number(10000), B, NULL));
	SymbolAnnotation::set_b(action_s, ACTION_IANN, 1);

@ The Inter convention is that an action package should contain a function
to carry it out; for |##ScriptOn|, this would be called |ScriptOnSub|. In fact
we don't actually define it here! We assume it has already been compiled, and
that we can therefore simply create the function name |ScriptOnSub| here,
equating it to a function definition elsewhere.

@<Make a symbol equated to the function carrying out the action@> =
	TEMPORARY_TEXT(fn_name)
	WRITE_TO(fn_name, "%SSub", value);
	Str::delete_first_character(fn_name);
	Str::delete_first_character(fn_name);
	inter_symbol *fn_s =
		InterSymbolsTable::create_with_unique_name(InterBookmark::scope(IBM), fn_name);
	inter_symbol *existing_fn_s = Wiring::find_socket(I, fn_name);
	if (existing_fn_s) Wiring::wire_to(fn_s, existing_fn_s);
	DISCARD_TEXT(fn_name)

@<Assimilate a value@> =
	if (Str::len(value) > 0) {
		val = CompileSplatsStage::value(step, IBM, value,
			(directive == VERB_I6DIR)?TRUE:FALSE);
	} else {
		val = InterValuePairs::number(0);
	}

@<Add value to the entry pile@> =
	if (no_assimilated_array_entries >= MAX_ASSIMILATED_ARRAY_ENTRIES) {
		PipelineErrors::kit_error("excessively long Verb or Extend", NULL);
		break;
	}
	v1_pile[no_assimilated_array_entries] = InterValuePairs::to_word1(val);
	v2_pile[no_assimilated_array_entries] = InterValuePairs::to_word2(val);
	no_assimilated_array_entries++;

@<Extract a token@> =
	int squoted = FALSE, dquoted = FALSE, bracketed = 0;
	while ((Str::in_range(spos)) && (Characters::is_whitespace(Str::get(spos))))
		spos = Str::forward(spos);
	while (Str::in_range(spos)) {
		wchar_t c = Str::get(spos);
		if ((Characters::is_whitespace(c)) && (squoted == FALSE) &&
			(dquoted == FALSE) && (bracketed == 0)) break;
		if ((c == '\'') && (dquoted == FALSE)) squoted = (squoted)?FALSE:TRUE;
		if ((c == '\"') && (squoted == FALSE)) dquoted = (dquoted)?FALSE:TRUE;
		if ((c == '(') && (dquoted == FALSE) && (squoted == FALSE)) bracketed++;
		if ((c == ')') && (dquoted == FALSE) && (squoted == FALSE)) bracketed--;
		PUT_TO(value, c);
		spos = Str::forward(spos);
	}

@h How functions are assimilated.
Functions in Inform 6 are usually called "routines", and have a syntax like so:
= (text as Inform 6)
	[ Example x y tmp;
	   tmp = x*y;
	   print "Product seems to be ", tmp, ".^";
	];
=
We are concerned more with the surround than with the contents of the function
in this section.

@<Assimilate routine@> =
	text_stream *identifier = NULL, *local_var_names = NULL, *body = NULL;
	match_results mr = Regexp::create_mr();
	if (P->W.instruction[PLM_SPLAT_IFLD] == ROUTINE_I6DIR) @<Parse the routine header@>;
	if (P->W.instruction[PLM_SPLAT_IFLD] == STUB_I6DIR) @<Parse the stub directive@>;
	if (identifier) {
		@<Turn this into a function package@>;
		NodePlacement::remove(P);
	}

@<Parse the routine header@> =
	text_stream *S = Inode::ID_to_text(P, P->W.instruction[MATTER_SPLAT_IFLD]);
	if (Regexp::match(&mr, S, L" *%[ *(%i+) *; *(%c*)")) {
		identifier = mr.exp[0]; body = mr.exp[1];
	} else if (Regexp::match(&mr, S, L" *%[ *(%i+) *(%c*?); *(%c*)")) {
		identifier = mr.exp[0]; local_var_names = mr.exp[1]; body = mr.exp[2];
	} else {
		PipelineErrors::kit_error("invalid Inform 6 routine declaration", NULL);
	}

@ Another of Inform 6's shabby notations for conditional compilation in disguise
is the |Stub| directive, which looks like so:
= (text as Inform 6)
	Stub Example 2;
=
This means "if no |Example| routine exists, create one now, and give it two
local variables". Such a stub routine contains no code, so it doesn't matter
what these variables are called, of course. We rewrite so that it's as if the
kit code had written:
= (text as Inform 6)
	[ Example x1 x2;
		rfalse;
	];
=
Note that here the compilation is unconditional. Because kits are precompiled,
there's no sensible way to provide these only if they are not elsewhere
provided. So this is no longer a useful directive, and it continues to be
supported only to avoid throwing errors.

@<Parse the stub directive@> =
	text_stream *S = Inode::ID_to_text(P, P->W.instruction[MATTER_SPLAT_IFLD]);
	if (Regexp::match(&mr, S, L" *%C+ *(%i+) (%d+);%c*")) {
		identifier = mr.exp[0];
		local_var_names = Str::new();
		int N = Str::atoi(mr.exp[1], 0);
		if ((N<0) || (N>15)) N = 1;
		for (int i=1; i<=N; i++) WRITE_TO(local_var_names, "x%d ", i);
		body = Str::duplicate(I"rfalse; ];");
	} else PipelineErrors::kit_error("invalid Inform 6 Stub declaration", NULL);

@ Function packages have a standardised shape in Inter, and though this is a
matter of convention rather than a requirement, we will follow it here. So
our |Example| function would be called at |/main/HypotheticalKit/functions/Example_fn/call|.
The following makes two packages:

(a) The "outer package", |/main/HypotheticalKit/functions/Example_fn|, which
holds all resources other than code needed by the function; and within it

(b) The "inner package", |/main/HypotheticalKit/functions/Example_fn/Example_B|,
which contains the actual code.

These have package types |_function| and |_code| respectively.

@<Turn this into a function package@> =
	inter_bookmark content_at = CompileSplatsStage::make_submodule(I, step, I"functions", P);
	inter_bookmark *IBM = &content_at;
	inter_package *OP, *IP; /* outer and inner packages */
	@<Create the outer function package@>;
	@<Create an inner package for the code@>;
	@<Create a symbol for calling the function@>;

@<Create the outer function package@> =
	inter_symbol *fnt = RunningPipelines::get_symbol(step, function_ptype_RPSYM);
	if (fnt == NULL) fnt = RunningPipelines::get_symbol(step, plain_ptype_RPSYM);
	TEMPORARY_TEXT(fname)
	WRITE_TO(fname, "%S_fn", identifier);
	OP = Produce::make_subpackage(IBM, fname, fnt);
	DISCARD_TEXT(fname)

@<Create an inner package for the code@> =
	InterBookmark::move_into_package(IBM, OP);
	TEMPORARY_TEXT(bname)
	WRITE_TO(bname, "%S_B", identifier);
	IP = Produce::make_subpackage(IBM, bname,
		RunningPipelines::get_symbol(step, code_ptype_RPSYM));
	DISCARD_TEXT(bname)
	inter_bookmark inner_save = InterBookmark::snapshot(IBM);
	InterBookmark::move_into_package(IBM, IP);
	inter_bookmark block_bookmark = InterBookmark::snapshot(IBM);
	if (local_var_names) @<Create local variables within the inner package@>;
	@<Create the outermost code block inside the inner package@>;
	if (Str::len(body) > 0) @<Compile actual code into this code block@>;
	*IBM = inner_save;

@<Create local variables within the inner package@> =
	string_position spos = Str::start(local_var_names);
	while (TRUE) {
		TEMPORARY_TEXT(value)
		@<Extract a token@>;
		if (Str::len(value) == 0) break;
		inter_symbol *loc_name =
			InterSymbolsTable::create_with_unique_name(InterPackage::scope(IP), value);
		InterSymbol::make_local(loc_name);
		inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
		Produce::guard(Inter::Local::new(IBM, loc_name, InterTypes::untyped(), B, NULL));
		DISCARD_TEXT(value)
	}

@<Create the outermost code block inside the inner package@> =
	Produce::guard(Inter::Code::new(IBM,
		(int) (inter_ti) InterBookmark::baseline(IBM) + 1, NULL));

@<Compile actual code into this code block@> =
	int L = Str::len(body) - 1;
	while ((L>0) && (Str::get_at(body, L) != ']')) L--;
	while ((L>0) && (Characters::is_whitespace(Str::get_at(body, L-1)))) L--;
	Str::truncate(body, L);
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	CompileSplatsStage::function_body(css, IBM, IP, B, body, block_bookmark, identifier);

@<Create a symbol for calling the function@> =
	inter_symbol *function_name_s =
		CompileSplatsStage::make_socketed_symbol(IBM, identifier);
	SymbolAnnotation::set_b(function_name_s, ASSIMILATED_IANN, 1);
	inter_ti MID = InterSymbolsTable::id_from_symbol(I, OP, function_name_s);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM),
		InterTypes::from_constructor_code(FUNCTION_ITCONC));
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	Produce::guard(Inter::Constant::new_function(IBM, MID, KID, IP, B, NULL));

@h Plumbing.
Some convenient Inter utilities.

First, we make a symbol, and also install a socket to it. This essentially
means that it will be visible to code outside of the current kit, making it a
function, variable or constant which can be called or accessed from other
kits or from the main program. (Compare C, where a function declared as |static|
is visible only inside the current compilation unit; one declared without that
keyword can be linked to.)

Note that if there is already a socket of the same name, we do not attempt to
install another one. This will not in practice lead to problems, because the
identifiers supplied to this function all come from identifiers in Inter kits,
which have a single global namespace for functoons and variables anyway.

=
inter_symbol *CompileSplatsStage::make_socketed_symbol(inter_bookmark *IBM,
	text_stream *identifier) {
	inter_symbol *new_symbol = InterSymbolsTable::create_with_unique_name(
		InterBookmark::scope(IBM), identifier);
	if (Wiring::find_socket(InterBookmark::tree(IBM), identifier) == NULL)
		Wiring::socket(InterBookmark::tree(IBM), identifier, new_symbol);
	return new_symbol;
}

@ Syppose we are assimilating |HypotheticalKit|, and we want to make sure that
the package |/main/HypotheticalKit/whatevers| exists. Here |/main/HypotheticalKit|
is a package of type |_module|, and |/main/HypotheticalKit/whatevers| should be
a |_submodule|. Then we call this function, with |name| set to "whatevers".
The return value is a bookmark to where we can write new code in the submodule.

Note that if the submodule already exists, there is nothing to create, and so
we simply return a bookmark at the end of the existing submodule.

The function tries to fail safe in the remote contingency that the package type
|_submodule| does not exist in the current tree. But if the tree has been
properly initialised with the |new| stage, then it will. Similarly, it will
fail safe if an assimilation package has not been set -- but this is very
unlikely to happen: see above.

=
inter_bookmark CompileSplatsStage::make_submodule(inter_tree *I, pipeline_step *step,
	text_stream *name, inter_tree_node *P) {
	if (RunningPipelines::get_symbol(step, submodule_ptype_RPSYM)) {
		inter_package *module_pack =
			step->pipeline->ephemera.assimilation_modules[step->tree_argument];
		if (module_pack) {
			inter_package *submodule_package = InterPackage::from_name(module_pack, name);
			if (submodule_package == NULL) {
				inter_bookmark IBM = InterBookmark::after_this_node(P);
				submodule_package = Produce::make_subpackage(&IBM, name,
					RunningPipelines::get_symbol(step, submodule_ptype_RPSYM));
				if (submodule_package == NULL) internal_error("could not create submodule");
			}
			return InterBookmark::at_end_of_this_package(submodule_package);
		}
	}
	return InterBookmark::after_this_node(P);
}

@h Inform 6 expressions in constant context.
The following takes the text of a constant written in Inform 6 syntax, and
stored in |S|, and compiles it to an Inter bytecode value pair. The meaning of
these depends on the package they will end up living in, so that must be supplied
as |pack|.

The flag |Verbal| is set if the expression came from a |Verb| directive, i.e.,
from command parser grammar: slightly different syntax applies there.

=
inter_pair CompileSplatsStage::value(pipeline_step *step, inter_bookmark *IBM, text_stream *S,
	int Verbal) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	int from = 0, to = Str::len(S)-1;
	if ((Str::get_at(S, from) == '\'') && (Str::get_at(S, to) == '\'')) {
		if (to - from == 2)
			@<Parse this as a literal character@>
		else if (Str::eq(S, I"'\\''"))
			@<Parse this as a literal single quotation mark@>
		else
			@<Parse this as a single-quoted command grammar word@>;
	}
	if ((Str::get_at(S, from) == '"') && (Str::get_at(S, to) == '"'))
		@<Parse this as a double-quoted string literal@>;
	if (((Str::get_at(S, from) == '$') && (Str::get_at(S, from+1) == '+')) ||
		((Str::get_at(S, from) == '$') && (Str::get_at(S, from+1) == '-')))
		@<Parse this as a real literal@>;
	@<Attempt to parse this as a hex, binary or decimal literal@>;
	@<Attempt to parse this as a boolean literal@>;
	if (Verbal) @<Attempt to parse this as a command grammar token@>;
    @<Attempt to parse this as an identifier name for something already defined by this kit@>;
	@<Parse this as a possibly computed value@>;
}

@<Parse this as a literal character@> =
	wchar_t c = Str::get_at(S, from + 1);
	return InterValuePairs::number((inter_ti) c);

@<Parse this as a literal single quotation mark@> =
	return InterValuePairs::number((inter_ti) '\'');

@<Parse this as a single-quoted command grammar word@> =
	inter_ti plural = FALSE; int before_slashes = TRUE;
	TEMPORARY_TEXT(dw)
	LOOP_THROUGH_TEXT(pos, S)
		if ((pos.index > from) && (pos.index < to)) {
			if ((Str::get(pos) == '/') && (Str::get(Str::forward(pos)) == '/'))
				before_slashes = FALSE;
			if (before_slashes) {
				PUT_TO(dw, Str::get(pos));
			} else {
				if (Str::get(pos) == 'p') plural = TRUE;
			}
		}
	inter_pair val;
	if (plural) val = InterValuePairs::from_plural_dword_at(I, pack, dw);
	else val = InterValuePairs::from_singular_dword_at(I, pack, dw);
	DISCARD_TEXT(dw)
	return val;

@<Parse this as a double-quoted string literal@> =
	TEMPORARY_TEXT(dw)
	LOOP_THROUGH_TEXT(pos, S)
		if ((pos.index > from) && (pos.index < to))
			PUT_TO(dw, Str::get(pos));
	inter_pair val = InterValuePairs::from_text_at(I, pack, dw);
	DISCARD_TEXT(dw)
	return val;

@<Parse this as a real literal@> =
	TEMPORARY_TEXT(rw)
	LOOP_THROUGH_TEXT(pos, S)
		if ((pos.index > from + 1) && (pos.index <= to))
			PUT_TO(rw, Str::get(pos));
	inter_pair val = InterValuePairs::from_real_text_at(I, pack, rw);
	DISCARD_TEXT(rw)
	return val;

@<Attempt to parse this as a hex, binary or decimal literal@> =
	int sign = 1, base = 10, bad = FALSE;
	if ((Str::get_at(S, from) == '(') && (Str::get_at(S, to) == ')')) { from++; to--; }
	while (Characters::is_whitespace(Str::get_at(S, from))) from++;
	while (Characters::is_whitespace(Str::get_at(S, to))) to--;
	if (Str::get_at(S, from) == '-') { sign = -1; from++; }
	else if (Str::get_at(S, from) == '$') {
		from++; base = 16;
		if (Str::get_at(S, from) == '$') {
			from++; base = 2;
		}
	}
	long long int N = 0;
	LOOP_THROUGH_TEXT(pos, S) {
		if (pos.index < from) continue;
		if (pos.index > to) continue;
		int c = Str::get(pos), d = 0;
		if ((c >= 'a') && (c <= 'z')) d = c-'a'+10;
		else if ((c >= 'A') && (c <= 'Z')) d = c-'A'+10;
		else if ((c >= '0') && (c <= '9')) d = c-'0';
		else { bad = TRUE; break; }
		if (d > base) { bad = TRUE; break; }
		N = base*N + (long long int) d;
		if (pos.index > 34) { bad = TRUE; break; }
	}
	if (bad == FALSE) {
		N = sign*N;
		return InterValuePairs::number((inter_ti) N);
	}

@<Attempt to parse this as a boolean literal@> =
	if (Str::eq(S, I"true"))  return InterValuePairs::number(1);
	if (Str::eq(S, I"false")) return InterValuePairs::number(0);

@<Attempt to parse this as a command grammar token@> =
	if (Str::eq(S, I"*"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_divider_RPSYM, I"VERB_DIRECTIVE_DIVIDER"));
	if (Str::eq(S, I"->"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_result_RPSYM, I"VERB_DIRECTIVE_RESULT"));
	if (Str::eq(S, I"reverse"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_reverse_RPSYM, I"VERB_DIRECTIVE_REVERSE"));
	if (Str::eq(S, I"/"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_slash_RPSYM, I"VERB_DIRECTIVE_SLASH"));
	if (Str::eq(S, I"special"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_special_RPSYM, I"VERB_DIRECTIVE_SPECIAL"));
	if (Str::eq(S, I"number"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_number_RPSYM, I"VERB_DIRECTIVE_NUMBER"));
	if (Str::eq(S, I"noun"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_noun_RPSYM, I"VERB_DIRECTIVE_NOUN"));
	if (Str::eq(S, I"multi"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_multi_RPSYM, I"VERB_DIRECTIVE_MULTI"));
	if (Str::eq(S, I"multiinside"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_multiinside_RPSYM, I"VERB_DIRECTIVE_MULTIINSIDE"));
	if (Str::eq(S, I"multiheld"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_multiheld_RPSYM, I"VERB_DIRECTIVE_MULTIHELD"));
	if (Str::eq(S, I"held"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_held_RPSYM, I"VERB_DIRECTIVE_HELD"));
	if (Str::eq(S, I"creature"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_creature_RPSYM, I"VERB_DIRECTIVE_CREATURE"));
	if (Str::eq(S, I"topic"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_topic_RPSYM, I"VERB_DIRECTIVE_TOPIC"));
	if (Str::eq(S, I"multiexcept"))
		return InterValuePairs::p_from_symbol(I, pack, RunningPipelines::ensure_symbol(step,
			verb_directive_multiexcept_RPSYM, I"VERB_DIRECTIVE_MULTIEXCEPT"));
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, S, L"scope=(%i+)")) {
		inter_symbol *symb = Wiring::cable_end(Wiring::find_socket(I, mr.exp[0]));
		if (symb) {
			if (SymbolAnnotation::get_b(symb, SCOPE_FILTER_IANN) == FALSE)
				SymbolAnnotation::set_b(symb, SCOPE_FILTER_IANN, TRUE);
			return InterValuePairs::p_from_symbol(I, pack, symb);
		}
	}
	if (Regexp::match(&mr, S, L"noun=(%i+)")) {
		inter_symbol *symb = Wiring::cable_end(Wiring::find_socket(I, mr.exp[0]));
		if (symb) {
			if (SymbolAnnotation::get_b(symb, NOUN_FILTER_IANN) == FALSE)
				SymbolAnnotation::set_b(symb, NOUN_FILTER_IANN, TRUE);
			return InterValuePairs::p_from_symbol(I, pack, symb);
		}
	}

@<Attempt to parse this as an identifier name for something already defined by this kit@> =
	inter_symbol *symb = Wiring::find_socket(I, S);
	if (symb) {
		return InterValuePairs::p_from_symbol(I, pack, symb);
	}

@ At this point, maybe the reason we haven't yet recognised the constant |S| is
that it's a computation like |6 + MAX_WEEBLES*4|. This is quite legal in Inform 6,
and the compiler performs constant-folding to evaluate them: so that's what we will
emulate now. In practice, we are only going to understand fairly simple computations,
but that will be enough for the kits normally used with Inform.

We do this by parsing |S| into a schema, whose tree will look roughly like this:
= (text)
	PLUS_BIP
		6
		TIMES_BIP
			MAX_WEEBLES
			4
=
We then recurse down through this tree, constructing an Inter symbol for a
constant which evaluates to the result of each operation. Here, then, we
first define |Computed_Constant_Value_1| as the multiplication, then define
|Computed_Constant_Value_2| as the addition, and that is what we use as our
answer. Since we recurse depth-first, the subsidiary results are always made
before they are needed.

@<Parse this as a possibly computed value@> =
	inter_schema *sch = ParsingSchemas::from_text(S);
	inter_symbol *result_s =
		CompileSplatsStage::compute_r(step, IBM, sch->node_tree);
	if (result_s == NULL)
		PipelineErrors::kit_error("Inform 6 constant in kit too complex", S);
	return InterValuePairs::p_from_symbol(I, pack, result_s);

@ So this is the recursion. Note that we calculate $-x$ as $0 - x$, thus
reducing unary subtraction to a case of binary subtraction.

=
inter_symbol *CompileSplatsStage::compute_r(pipeline_step *step,
	inter_bookmark *IBM, inter_schema_node *isn) {
	if (isn->isn_type == SUBEXPRESSION_ISNT) 
		return CompileSplatsStage::compute_r(step, IBM, isn->child_node);
	if (isn->isn_type == OPERATION_ISNT) {
		inter_ti op = 0;
		if (isn->isn_clarifier == PLUS_BIP) op = CONSTANT_SUM_LIST;
		else if (isn->isn_clarifier == TIMES_BIP) op = CONSTANT_PRODUCT_LIST;
		else if (isn->isn_clarifier == MINUS_BIP) op = CONSTANT_DIFFERENCE_LIST;
		else if (isn->isn_clarifier == DIVIDE_BIP) op = CONSTANT_QUOTIENT_LIST;
		else if (isn->isn_clarifier == UNARYMINUS_BIP) @<Calculate unary minus@>
		else return NULL;
		@<Calculate binary operation@>;
	}
	if (isn->isn_type == EXPRESSION_ISNT) {
		inter_schema_token *t = isn->expression_tokens;
		if ((t == NULL) || (t->next)) internal_error("malformed EXPRESSION_ISNT");
		return CompileSplatsStage::compute_eval(step, IBM, t);
	}
	return NULL;
}

@<Calculate binary operation@> =
	inter_symbol *i1 = CompileSplatsStage::compute_r(step, IBM, isn->child_node);
	inter_symbol *i2 = CompileSplatsStage::compute_r(step, IBM, isn->child_node->next_node);
	if ((i1 == NULL) || (i2 == NULL)) return NULL;
	return CompileSplatsStage::compute_binary_op(op, step, IBM, i1, i2);

@<Calculate unary minus@> =
	inter_symbol *i2 = CompileSplatsStage::compute_r(step, IBM, isn->child_node);
	if (i2 == NULL) return NULL;
	return CompileSplatsStage::compute_binary_op(CONSTANT_DIFFERENCE_LIST, step, IBM, NULL, i2);

@ The binary operation $x + y$ is "calculated" by forming a constant list with
two entries, $x$ and $y$, and marking this list in Inter as a list whose meaning
is the sum of the entries. (And similarly for the other three operations.) This
is a sort of lazy evaluation: it means that the actual calculation will be done
in whatever context Inter is being compiled for -- for example, if all of this
Inter is compiled to ANSI C, then it will eventually be a C compiler which
actually works out the numerical value of $x + y$.

Why do we do this? Why not simply calculate now, and get an explicit answer?
The trouble is that one of $x$ or $y$ might be some symbol whose value is itself
created by the downstream compiler. The meaning of this is the same on all
platforms: the value is not.

There would be a case for optimising the following function to fold constants
in cases where we can confidently do so (being careful of overflows and
mindful of the word size), i.e., when $x$ and $y$ are literal numbers or
symbols defined as literal numbers. That would produce more elegant Inter.
But not really more efficient Inter.

=
inter_symbol *CompileSplatsStage::compute_binary_op(inter_ti op, pipeline_step *step,
	inter_bookmark *IBM, inter_symbol *i1, inter_symbol *i2) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_symbol *result_s = CompileSplatsStage::new_ccv_symbol(pack);
	inter_ti MID = InterSymbolsTable::id_from_symbol_at_bookmark(IBM, result_s);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM), InterTypes::untyped());
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	inter_tree_node *pair_list = Inode::new_with_3_data_fields(IBM, CONSTANT_IST, MID, KID, op, NULL, B);
	int pos = pair_list->W.extent;
	Inode::extend_instruction_by(pair_list, 4);
	if (i1) {
		InterValuePairs::from_symbol(I, pack, i1,
			&(pair_list->W.instruction[pos]), &(pair_list->W.instruction[pos+1]));
	} else {
		pair_list->W.instruction[pos] = LITERAL_IVAL; pair_list->W.instruction[pos+1] = 0;
	}
	if (i2) {
		InterValuePairs::from_symbol(I, pack, i2,
			&(pair_list->W.instruction[pos+2]), &(pair_list->W.instruction[pos+3]));
	} else {
		pair_list->W.instruction[pos+2] = LITERAL_IVAL; pair_list->W.instruction[pos+3] = 0;
	}
	Produce::guard(Inter::Verify::instruction(InterBookmark::package(IBM), pair_list));
	NodePlacement::move_to_moving_bookmark(pair_list, IBM);
	return result_s;
}

@ So much for recursing down through the nodes of the Inter schema. Here are
the leaves:

=
inter_symbol *CompileSplatsStage::compute_eval(pipeline_step *step,
	inter_bookmark *IBM, inter_schema_token *t) {
	inter_tree *I = InterBookmark::tree(IBM);
	switch (t->ist_type) {
		case NUMBER_ISTT:
		case BIN_NUMBER_ISTT:
		case HEX_NUMBER_ISTT: @<This leaf is a literal number of some kind@>;
		case IDENTIFIER_ISTT: @<This leaf is a symbol name@>;
	}
	return NULL;
}

@<This leaf is a literal number of some kind@> =
	inter_package *pack = InterBookmark::package(IBM);
	inter_pair val;
	if (t->constant_number >= 0) {
		val = InterValuePairs::number((inter_ti) t->constant_number);
	} else {
		val = InterValuePairs::read_int_in_I6_notation(t->material);
		if (InterValuePairs::is_undef(val))
			return NULL;
	}
	inter_symbol *result_s = CompileSplatsStage::new_ccv_symbol(pack);
	inter_ti MID = InterSymbolsTable::id_from_symbol_at_bookmark(IBM, result_s);
	inter_ti KID = InterTypes::to_TID(InterBookmark::scope(IBM), InterTypes::untyped());
	inter_ti B = (inter_ti) InterBookmark::baseline(IBM) + 1;
	Produce::guard(Inter::Constant::new_numerical(IBM, MID, KID, val, B, NULL));
	return result_s;

@ This is the harder case by far, despite the brevity of the following code.
Here we run into, say, |MAX_ELEPHANTS|, some identifier which clearly refers
to something defined elsewhere. If it has already been defined in the kit
being compiled, then there's a socket of that name already, and we can use
that as the answer; similarly if it's an architectural constant such as |WORDSIZE|.
Otherwise we must assume it will be declared either later or in another
compilation unit, so we create a plug called |MAX_ELEPHANTS| and let the
linker stage worry about what it means later on.

@<This leaf is a symbol name@> =
	inter_symbol *result_s = LargeScale::find_architectural_symbol(I, t->material);
	if (result_s) return result_s;
	result_s = Wiring::find_socket(I, t->material);
	if (result_s) return result_s;
	return Wiring::plug(I, t->material);

@ The above algorithm needs a lot of names for partial results of expressions,
all of which have to become Inter symbols. It really doesn't matter what these
are called.

=
int ccs_count = 0;
inter_symbol *CompileSplatsStage::new_ccv_symbol(inter_package *pack) {
	TEMPORARY_TEXT(NN)
	WRITE_TO(NN, "Computed_Constant_Value_%d", ccs_count++);
	inter_symbol *result_s =
		InterSymbolsTable::symbol_from_name_creating(InterPackage::scope(pack), NN);
	InterSymbol::set_flag(result_s, MAKE_NAME_UNIQUE_ISYMF);
	DISCARD_TEXT(NN)
	return result_s;
}

@h Delegating the work of compiling function bodies.
Function bodies are by far the hardest things to compile. We delegate this first
by storing up a list of requests to do the work:

=
typedef struct function_body_request {
	struct inter_bookmark position;
	struct inter_bookmark block_bookmark;
	struct package_request *enclosure;
	struct inter_package *block_package;
	int pass2_offset;
	struct text_stream *body;
	struct text_stream *identifier;
	CLASS_DEFINITION
} function_body_request;

int CompileSplatsStage::function_body(compile_splats_state *css, inter_bookmark *IBM,
	inter_package *block_package, inter_ti offset, text_stream *body, inter_bookmark bb,
	text_stream *identifier) {
	if (Str::is_whitespace(body)) return FALSE;
	function_body_request *req = CREATE(function_body_request);
	req->block_bookmark = bb;
	req->enclosure = Packaging::enclosure(InterBookmark::tree(IBM));
	req->position = Packaging::bubble_at(IBM);
	req->block_package = block_package;
	req->pass2_offset = (int) offset - 2;
	req->body = Str::duplicate(body);
	req->identifier = Str::duplicate(identifier);
	ADD_TO_LINKED_LIST(req, function_body_request, css->function_bodies_to_compile);
	return TRUE;
}

@ ...Playing back through those requests here. Note that we turn the entire
contents of the function -- which can be very large, for example in the Inform
kit |CommandParserKit| -- as a single gigantic Inter schema |sch|.

=
int CompileSplatsStage::function_bodies(pipeline_step *step, compile_splats_state *css,
	inter_tree *I) {
	int errors_occurred = FALSE;
	function_body_request *req;
	LOOP_OVER_LINKED_LIST(req, function_body_request, css->function_bodies_to_compile) {
		LOGIF(SCHEMA_COMPILATION, "=======\n\nFunction (%S) len %d: '%S'\n\n",
			InterPackage::name(req->block_package), Str::len(req->body), req->body);
		inter_schema *sch = ParsingSchemas::from_text(req->body);
		if (LinkedLists::len(sch->parsing_errors) > 0) {
			CompileSplatsStage::report_kit_errors(sch, req);
		} else {
			if (Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) InterSchemas::log(DL, sch);
			@<Compile this function body@>;
		}
		if (LinkedLists::len(sch->parsing_errors) > 0) errors_occurred = TRUE;
	}
	return errors_occurred;
}

@ And then we emit Inter code equivalent to |sch|:

@<Compile this function body@> =
	Produce::set_function(I, req->block_package);
	Packaging::set_state(I, &(req->position), req->enclosure);
	Produce::push_new_code_position(I, &(req->position));
	value_holster VH = Holsters::new(INTER_VOID_VHMODE);
	inter_symbols_table *scope1 = InterPackage::scope(req->block_package);
	inter_package *module_pack =
		step->pipeline->ephemera.assimilation_modules[step->tree_argument];
	inter_symbols_table *scope2 = InterPackage::scope(module_pack);
	identifier_finder finder = IdentifierFinders::common_names_only();
	IdentifierFinders::next_priority(&finder, scope1);
	IdentifierFinders::next_priority(&finder, scope2);
	EmitInterSchemas::emit(I, &VH, sch, finder, NULL, NULL, NULL);
	CompileSplatsStage::report_kit_errors(sch, req);
	Produce::pop_code_position(I);
	Produce::set_function(I, NULL);

@ Either parsing or emitting can throw errors, so at both stages:

=
void CompileSplatsStage::report_kit_errors(inter_schema *sch, function_body_request *req) {
	if (LinkedLists::len(sch->parsing_errors) > 0) {
		schema_parsing_error *err;
		LOOP_OVER_LINKED_LIST(err, schema_parsing_error, sch->parsing_errors) {
			TEMPORARY_TEXT(msg)
			WRITE_TO(msg, "in function '%S': %S", req->identifier, err->message);
			PipelineErrors::kit_error("kit source error %S", msg);
			DISCARD_TEXT(msg)
		}
	}
}
