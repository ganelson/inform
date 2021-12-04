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
int compile_splats_stage_run_count = 0;
int CompileSplatsStage::run(pipeline_step *step) {
	if ((RunningPipelines::get_symbol(step, unchecked_kind_RPSYM) == NULL) ||
		(RunningPipelines::get_symbol(step, unchecked_function_RPSYM) == NULL) ||
		(RunningPipelines::get_symbol(step, truth_state_kind_RPSYM) == NULL) ||
		(RunningPipelines::get_symbol(step, list_of_unchecked_kind_RPSYM) == NULL)) {
	PipelineErrors::kit_error(
			"compile-splats cannot be used because essential kinds are missing", NULL);
		return FALSE;
	}
	compile_splats_state css;
	@<Initialise the CS state@>;
	inter_tree *I = step->ephemera.repository;
	InterTree::traverse(I, CompileSplatsStage::visitor1, &css, NULL, SPLAT_IST);
	InterTree::traverse(I, CompileSplatsStage::visitor2, &css, NULL, SPLAT_IST);
	CompileSplatsStage::function_bodies(&css, I);
	InterTree::traverse(I, CompileSplatsStage::visitor3, &css, NULL, SPLAT_IST);
	return TRUE;
}

@ During this process, the following state is shared across all three traverses:

=
typedef struct compile_splats_state {
	struct pipeline_step *from_step;
	int unique_run_ID;
	int no_assimilated_actions;
	int no_assimilated_directives;
} compile_splats_state;

@<Initialise the CS state@> =
	css.from_step = step;
	css.unique_run_ID = ++compile_splats_stage_run_count;
	css.no_assimilated_actions = 0;
	css.no_assimilated_directives = 0;

@ The three traverse functions share a great deal of their code, in fact. Note
that we always expect the kinds here to exist: see //New Stage//. Checking
that they do is probably redundant, in fact, but is fast and does no harm.

=
void CompileSplatsStage::visitor1(inter_tree *I, inter_tree_node *P, void *state) {
	compile_splats_state *css = (compile_splats_state *) state;
	pipeline_step *step = css->from_step;
	inter_ti directive = P->W.data[PLM_SPLAT_IFLD];
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

void CompileSplatsStage::visitor2(inter_tree *I, inter_tree_node *P, void *state) {
	compile_splats_state *css = (compile_splats_state *) state;
	pipeline_step *step = css->from_step;
	inter_ti directive = P->W.data[PLM_SPLAT_IFLD];
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

void CompileSplatsStage::visitor3(inter_tree *I, inter_tree_node *P, void *state) {
	compile_splats_state *css = (compile_splats_state *) state;
	pipeline_step *step = css->from_step;
	inter_ti directive = P->W.data[PLM_SPLAT_IFLD];
	switch (directive) {
		case GLOBAL_I6DIR:
			@<Assimilate definition@>;
			break;
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
		InterTree::remove_node(P);
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
	text_stream *S = Inode::ID_to_text(P, P->W.data[MATTER_SPLAT_IFLD]);
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
		if (Inter::Connectors::find_socket(I, identifier) == NULL) {
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
		content_at = CompileSplatsStage::template_submodule(I, step, submodule_name, P);
		@<Create a little package within that submodule to hold the content@>
	} else {
		content_at = Inter::Bookmarks::after_this_node(I, P);
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
		CompileSplatsStage::new_package_named(&content_at, subpackage_name, subpackage_type);
	Inter::Bookmarks::set_current_package(&content_at, subpackage);
	DISCARD_TEXT(subpackage_name)

@ Now we declare |made_s| as a symbol inside this package.

@<Declare the Inter symbol for what we will shortly make@> =	
	made_s = CompileSplatsStage::make_socketed_symbol(&content_at, identifier);
	if (made_s->equated_to) {
		inter_symbol *external_name = made_s->equated_to;
		external_name->equated_to = made_s;
		made_s->equated_to = NULL;
	}
	Inter::Symbols::annotate_i(made_s, ASSIMILATED_IANN, 1);
	if (directive == FAKEACTION_I6DIR) Inter::Symbols::annotate_i(made_s, FAKE_ACTION_IANN, 1);
	if (directive == OBJECT_I6DIR) Inter::Symbols::annotate_i(made_s, OBJECT_IANN, 1);
	if (directive == ATTRIBUTE_I6DIR) Inter::Symbols::annotate_i(made_s, EITHER_OR_IANN, 1);
	if (directive == VERB_I6DIR) Inter::Symbols::set_flag(made_s, MAKE_NAME_UNIQUE);

@<Declare a property ID symbol to go with it@> =
	inter_bookmark *IBM = &content_at;
	inter_symbol *id_s = CompileSplatsStage::make_socketed_symbol(IBM, I"property_id");	
	Inter::Symbols::set_flag(id_s, MAKE_NAME_UNIQUE);
	Produce::guard(Inter::Constant::new_numerical(IBM,
		InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), id_s),
		InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM),
			RunningPipelines::get_symbol(step, unchecked_kind_RPSYM)),
			LITERAL_IVAL, 0, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));

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
	inter_ti MID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), made_s);
	inter_ti KID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM),
		RunningPipelines::get_symbol(step, unchecked_kind_RPSYM));
	inter_ti B = (inter_ti) Inter::Bookmarks::baseline(IBM) + 1;
	inter_ti v1 = 0, v2 = 0;
	@<Assimilate a value@>;
	Produce::guard(Inter::Constant::new_numerical(IBM, MID, KID, v1, v2, B, NULL));

@<Make a global variable in Inter@> =
	inter_ti MID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), made_s);
	inter_ti KID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM),
		RunningPipelines::get_symbol(step, unchecked_kind_RPSYM));
	inter_ti B = (inter_ti) Inter::Bookmarks::baseline(IBM) + 1;
	inter_ti v1 = 0, v2 = 0;
	@<Assimilate a value@>;
	Produce::guard(Inter::Variable::new(IBM, MID, KID, v1, v2, B, NULL));

@<Make a general property in Inter@> =
	inter_ti MID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), made_s);
	inter_ti KID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM),
		RunningPipelines::get_symbol(step, unchecked_kind_RPSYM));
	inter_ti B = (inter_ti) Inter::Bookmarks::baseline(IBM) + 1;
	Produce::guard(Inter::Property::new(IBM, MID, KID, B, NULL));

@<Make an either-or property in Inter@> =
	inter_ti MID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), made_s);
	inter_ti KID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM),
		RunningPipelines::get_symbol(step, truth_state_kind_RPSYM));
	inter_ti B = (inter_ti) Inter::Bookmarks::baseline(IBM) + 1;
	Produce::guard(Inter::Property::new(IBM, MID, KID, B, NULL));

@ A typical Inform 6 array declaration looks like this:
= (text as Inform 6)
	Array Example table 2 (-56) 17 "hey, I am typeless" ' ';
=

@d MAX_ASSIMILATED_ARRAY_ENTRIES 10000

@<Make a list constant in Inter@> =
	match_results mr = Regexp::create_mr();
	text_stream *conts = NULL;
	inter_ti annot = 0;
	@<Work out the format of the array and the string of contents@>;
	if (annot != 0) Inter::Symbols::annotate_i(made_s, annot, 1);

	inter_ti v1_pile[MAX_ASSIMILATED_ARRAY_ENTRIES], v2_pile[MAX_ASSIMILATED_ARRAY_ENTRIES];
	int no_assimilated_array_entries = 0;
	if (directive == ARRAY_I6DIR)
		@<Compile the string of array contents into the pile of v1 and v2 values@>
	else
		@<Compile the string of command grammar contents into the pile of v1 and v2 values@>;

	inter_ti MID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), made_s);
	inter_ti KID = InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM),
		RunningPipelines::get_symbol(step, list_of_unchecked_kind_RPSYM));
	inter_ti B = (inter_ti) Inter::Bookmarks::baseline(IBM) + 1;
	Produce::guard(Inter::Constant::new_list(IBM, MID, KID, no_assimilated_array_entries,
		v1_pile, v2_pile, B, NULL));
	Regexp::dispose_of(&mr);

@ At this point |value| is |table 2 (-56) 17 "hey, I am typeless" ' '|. We want
first to work out which of the several array formats this is (|TABLEARRAY_IANN|
in this instance), then the contents |2 (-56) 17 "hey, I am typeless" ' '|.

@<Work out the format of the array and the string of contents@> =
	if (directive == ARRAY_I6DIR) {
		if (Regexp::match(&mr, value, L" *--> *(%c*?) *")) {
			conts = mr.exp[0]; annot = 0;
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
			inter_ti v1 = 0, v2 = 0;
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
		if (next_is_action) CompileSplatsStage::ensure_action(css, I, step, P, value);
		next_is_action = FALSE;
		if ((NT++ == 0) && (Str::eq(value, I"meta"))) {
			Inter::Symbols::annotate_i(made_s, METAVERB_IANN, 1);
		} else if (Str::len(value) > 0) {
			inter_ti v1 = 0, v2 = 0;
			@<Assimilate a value@>;
			@<Add value to the entry pile@>;
			if (Str::eq(value, I"->")) next_is_action = TRUE;
		} else finished = TRUE;
		DISCARD_TEXT(value)
	}

@<Assimilate a value@> =
	if (Str::len(value) > 0) {
		CompileSplatsStage::value(I, step, Inter::Bookmarks::package(IBM), IBM, value, &v1, &v2,
			(directive == VERB_I6DIR)?TRUE:FALSE);
	} else {
		v1 = LITERAL_IVAL; v2 = 0;
	}

@<Add value to the entry pile@> =
	if (no_assimilated_array_entries >= MAX_ASSIMILATED_ARRAY_ENTRIES) {
		PipelineErrors::kit_error("excessively long Verb or Extend", NULL);
		break;
	}
	v1_pile[no_assimilated_array_entries] = v1;
	v2_pile[no_assimilated_array_entries] = v2;
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
	text_stream *identifier = NULL, *chain = NULL, *body = NULL;
	match_results mr = Regexp::create_mr();
	if (P->W.data[PLM_SPLAT_IFLD] == ROUTINE_I6DIR) @<Parse the routine header@>;
	if (P->W.data[PLM_SPLAT_IFLD] == STUB_I6DIR) @<Parse the stub directive@>;
	if (identifier) @<Act on parsed header@>;

@<Parse the routine header@> =
	text_stream *S = Inode::ID_to_text(P, P->W.data[MATTER_SPLAT_IFLD]);
	if (Regexp::match(&mr, S, L" *%[ *(%i+) *; *(%c*)")) {
		identifier = mr.exp[0]; body = mr.exp[1];
	} else if (Regexp::match(&mr, S, L" *%[ *(%i+) *(%c*?); *(%c*)")) {
		identifier = mr.exp[0]; chain = mr.exp[1]; body = mr.exp[2];
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
	text_stream *S = Inode::ID_to_text(P, P->W.data[MATTER_SPLAT_IFLD]);
	if (Regexp::match(&mr, S, L" *%C+ *(%i+) (%d+);%c*")) {
		identifier = mr.exp[0];
		chain = Str::new();
		int N = Str::atoi(mr.exp[1], 0);
		if ((N<0) || (N>15)) N = 1;
		for (int i=1; i<=N; i++) WRITE_TO(chain, "x%d ", i);
		body = Str::duplicate(I"rfalse; ];");
	} else PipelineErrors::kit_error("invalid Inform 6 Stub declaration", NULL);

@<Act on parsed header@> =
	inter_bookmark content_at = CompileSplatsStage::template_submodule(I, step, I"functions", P);
	inter_bookmark *IBM = &content_at;

	inter_symbol *fnt = RunningPipelines::get_symbol(step, function_ptype_RPSYM);
	if (fnt == NULL) fnt = RunningPipelines::get_symbol(step, plain_ptype_RPSYM);

	TEMPORARY_TEXT(fname)
	WRITE_TO(fname, "%S_fn", identifier);
	inter_package *FP = CompileSplatsStage::new_package_named(IBM, fname, fnt);
	DISCARD_TEXT(fname)

	inter_bookmark outer_save = Inter::Bookmarks::snapshot(IBM);
	Inter::Bookmarks::set_current_package(IBM, FP);

	TEMPORARY_TEXT(bname)
	WRITE_TO(bname, "%S_B", identifier);
	inter_package *IP = CompileSplatsStage::new_package_named(IBM, bname, RunningPipelines::get_symbol(step, code_ptype_RPSYM));
	DISCARD_TEXT(bname)

	inter_bookmark inner_save = Inter::Bookmarks::snapshot(IBM);
	Inter::Bookmarks::set_current_package(IBM, IP);
	inter_bookmark block_bookmark = Inter::Bookmarks::snapshot(IBM);

	if (chain) {
		string_position spos = Str::start(chain);
		while (TRUE) {
			TEMPORARY_TEXT(value)
			@<Extract a token@>;
			if (Str::len(value) == 0) break;
			inter_symbol *loc_name = InterSymbolsTables::create_with_unique_name(Inter::Packages::scope(IP), value);
			Inter::Symbols::local(loc_name);
			Produce::guard(Inter::Local::new(IBM, loc_name, RunningPipelines::get_symbol(step, unchecked_kind_RPSYM), 0, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
			DISCARD_TEXT(value)
		}
	}

	Produce::guard(Inter::Code::new(IBM, (int) (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
	if (Str::len(body) > 0) {
		int L = Str::len(body) - 1;
		while ((L>0) && (Str::get_at(body, L) != ']')) L--;
		while ((L>0) && (Characters::is_whitespace(Str::get_at(body, L-1)))) L--;
		Str::truncate(body, L);
		CompileSplatsStage::routine_body(css, IBM, IP, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, body, block_bookmark);
	}

	*IBM = inner_save;

	inter_symbol *rsymb = CompileSplatsStage::make_socketed_symbol(IBM, identifier);
	Inter::Symbols::annotate_i(rsymb, ASSIMILATED_IANN, 1);
	Produce::guard(Inter::Constant::new_function(IBM,
		InterSymbolsTables::id_from_symbol(I, FP, rsymb),
		InterSymbolsTables::id_from_symbol(I, FP, RunningPipelines::get_symbol(step, unchecked_function_RPSYM)),
		IP,
		(inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));

	*IBM = outer_save;

	CompileSplatsStage::install_socket(I, rsymb, rsymb->symbol_name);
	InterTree::remove_node(P);

@ =
inter_package *CompileSplatsStage::new_package_named(inter_bookmark *IBM, text_stream *name, inter_symbol *ptype) {
	inter_package *P = NULL;
	Produce::guard(Inter::Package::new_package_named(IBM, name, TRUE,
		ptype, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL, &P));
	return P;
}

void CompileSplatsStage::install_socket(inter_tree *I, inter_symbol *con_name, text_stream *aka_text) {
	inter_symbol *socket = Inter::Connectors::find_socket(I, aka_text);
	if (socket == NULL) Inter::Connectors::socket(I, aka_text, con_name);
}

inter_symbol *CompileSplatsStage::make_socketed_symbol(inter_bookmark *IBM, text_stream *identifier) {
	inter_symbol *new_symbol = InterSymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(IBM), identifier);
	CompileSplatsStage::install_socket(Inter::Bookmarks::tree(IBM), new_symbol, identifier);
	return new_symbol;
}

@ =
void CompileSplatsStage::ensure_action(compile_splats_state *css, inter_tree *I, pipeline_step *step, inter_tree_node *P, text_stream *value) {
	if (Inter::Connectors::find_socket(I, value) == NULL) {
		inter_bookmark IBM_d = CompileSplatsStage::template_submodule(I, step, I"actions", P);
		inter_bookmark *IBM = &IBM_d;
		inter_symbol *ptype = RunningPipelines::get_symbol(step, action_ptype_RPSYM);
		if (ptype == NULL) ptype = RunningPipelines::get_symbol(step, plain_ptype_RPSYM);
		TEMPORARY_TEXT(an)
		WRITE_TO(an, "assim_action_%d", ++css->no_assimilated_actions);
		Inter::Bookmarks::set_current_package(IBM, CompileSplatsStage::new_package_named(IBM, an, ptype));
		DISCARD_TEXT(an)
		inter_symbol *aid_s = InterSymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(IBM), I"action_id");
		Produce::guard(Inter::Constant::new_numerical(IBM,
			InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), aid_s),
			InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), RunningPipelines::get_symbol(step, unchecked_kind_RPSYM)),
			LITERAL_IVAL, 0, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
		Inter::Symbols::set_flag(aid_s, MAKE_NAME_UNIQUE);
		inter_symbol *asymb = CompileSplatsStage::make_socketed_symbol(IBM, value);
		TEMPORARY_TEXT(unsharped)
		WRITE_TO(unsharped, "%SSub", value);
		Str::delete_first_character(unsharped);
		Str::delete_first_character(unsharped);
		inter_symbol *txsymb = Inter::Connectors::find_socket(I, unsharped);
		inter_symbol *xsymb = InterSymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(IBM), unsharped);
		if (txsymb) InterSymbolsTables::equate(xsymb, txsymb);
		DISCARD_TEXT(unsharped)
		Produce::guard(Inter::Constant::new_numerical(IBM,
			InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), asymb),
			InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(IBM), RunningPipelines::get_symbol(step, unchecked_kind_RPSYM)),
			LITERAL_IVAL, 10000, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
		Inter::Symbols::annotate_i(asymb, ACTION_IANN, 1);
	}
}

@ =
void CompileSplatsStage::value(inter_tree *I, pipeline_step *step, inter_package *pack, inter_bookmark *IBM, text_stream *S, inter_ti *val1, inter_ti *val2, int Verbal) {
	int sign = 1, base = 10, from = 0, to = Str::len(S)-1, bad = FALSE;
	if ((Str::get_at(S, from) == '\'') && (Str::get_at(S, to) == '\'')) {
		from++;
		to--;
		TEMPORARY_TEXT(dw)
		LOOP_THROUGH_TEXT(pos, S) {
			if (pos.index < from) continue;
			if (pos.index > to) continue;
			int c = Str::get(pos);
			PUT_TO(dw, c);
		}
		inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
		Str::copy(glob_storage, dw);
		*val1 = DWORD_IVAL; *val2 = ID;
		DISCARD_TEXT(dw)
		return;
	}
	if ((Str::get_at(S, from) == '"') && (Str::get_at(S, to) == '"')) {
		from++;
		to--;
		TEMPORARY_TEXT(dw)
		LOOP_THROUGH_TEXT(pos, S) {
			if (pos.index < from) continue;
			if (pos.index > to) continue;
			int c = Str::get(pos);
			PUT_TO(dw, c);
		}
		inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
		Str::copy(glob_storage, dw);
		*val1 = LITERAL_TEXT_IVAL; *val2 = ID;
		DISCARD_TEXT(dw)
		return;
	}
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
		*val1 = LITERAL_IVAL; *val2 = (inter_ti) N; return;
	}
	if (Str::eq(S, I"true")) {
		*val1 = LITERAL_IVAL; *val2 = 1; return;
	}
	if (Str::eq(S, I"false")) {
		*val1 = LITERAL_IVAL; *val2 = 0; return;
	}

	if (Verbal) {
		if (Str::eq(S, I"*")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_divider_RPSYM, I"VERB_DIRECTIVE_DIVIDER"), val1, val2); return;
		}
		if (Str::eq(S, I"->")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_result_RPSYM, I"VERB_DIRECTIVE_RESULT"), val1, val2); return;
		}
		if (Str::eq(S, I"reverse")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_reverse_RPSYM, I"VERB_DIRECTIVE_REVERSE"), val1, val2); return;
		}
		if (Str::eq(S, I"/")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_slash_RPSYM, I"VERB_DIRECTIVE_SLASH"), val1, val2); return;
		}
		if (Str::eq(S, I"special")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_special_RPSYM, I"VERB_DIRECTIVE_SPECIAL"), val1, val2); return;
		}
		if (Str::eq(S, I"number")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_number_RPSYM, I"VERB_DIRECTIVE_NUMBER"), val1, val2); return;
		}
		if (Str::eq(S, I"noun")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_noun_RPSYM, I"VERB_DIRECTIVE_NOUN"), val1, val2); return;
		}
		if (Str::eq(S, I"multi")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_multi_RPSYM, I"VERB_DIRECTIVE_MULTI"), val1, val2); return;
		}
		if (Str::eq(S, I"multiinside")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_multiinside_RPSYM, I"VERB_DIRECTIVE_MULTIINSIDE"), val1, val2); return;
		}
		if (Str::eq(S, I"multiheld")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_multiheld_RPSYM, I"VERB_DIRECTIVE_MULTIHELD"), val1, val2); return;
		}
		if (Str::eq(S, I"held")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_held_RPSYM, I"VERB_DIRECTIVE_HELD"), val1, val2); return;
		}
		if (Str::eq(S, I"creature")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_creature_RPSYM, I"VERB_DIRECTIVE_CREATURE"), val1, val2); return;
		}
		if (Str::eq(S, I"topic")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_topic_RPSYM, I"VERB_DIRECTIVE_TOPIC"), val1, val2); return;
		}
		if (Str::eq(S, I"multiexcept")) {
			Inter::Symbols::to_data(I, pack, RunningPipelines::ensure_symbol(step, verb_directive_multiexcept_RPSYM, I"VERB_DIRECTIVE_MULTIEXCEPT"), val1, val2); return;
		}
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, S, L"scope=(%i+)")) {
			inter_symbol *symb = Inter::Connectors::find_socket(I, mr.exp[0]);
			while ((symb) && (symb->equated_to)) symb = symb->equated_to;
			if (symb) {
				if (Inter::Symbols::read_annotation(symb, SCOPE_FILTER_IANN) != 1)
					Inter::Symbols::annotate_i(symb, SCOPE_FILTER_IANN, 1);
				Inter::Symbols::to_data(I, pack, symb, val1, val2); return;
			}
		}
		if (Regexp::match(&mr, S, L"noun=(%i+)")) {
			inter_symbol *symb = Inter::Connectors::find_socket(I, mr.exp[0]);
			while ((symb) && (symb->equated_to)) symb = symb->equated_to;
			if (symb) {
				if (Inter::Symbols::read_annotation(symb, NOUN_FILTER_IANN) != 1)
					Inter::Symbols::annotate_i(symb, NOUN_FILTER_IANN, 1);
				Inter::Symbols::to_data(I, pack, symb, val1, val2); return;
			}
		}
	}

	inter_symbol *symb = Inter::Connectors::find_socket(I, S);
	if (symb) {
		Inter::Symbols::to_data(I, pack, symb, val1, val2); return;
	}

	inter_schema *sch = InterSchemas::from_text(S, FALSE, 0, NULL);
	inter_symbol *mcc_name = CompileSplatsStage::compute_constant(I, step, pack, IBM, sch);
	Inter::Symbols::to_data(I, pack, mcc_name, val1, val2);
}

inter_symbol *CompileSplatsStage::compute_constant(inter_tree *I, pipeline_step *step, inter_package *pack, inter_bookmark *IBM, inter_schema *sch) {

	inter_symbol *try = CompileSplatsStage::compute_constant_r(I, step, pack, IBM, sch->node_tree);
	if (try) return try;

	InterSchemas::log(DL, sch);
	LOG("Forced to glob: %S\n", sch->converted_from);
	WRITE_TO(STDERR, "Forced to glob: %S\n", sch->converted_from);
	internal_error("Reduced to glob in assimilation");

	inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(glob_storage, sch->converted_from);

	inter_symbol *mcc_name = CompileSplatsStage::computed_constant_symbol(pack);
	Produce::guard(Inter::Constant::new_numerical(IBM,
		InterSymbolsTables::id_from_symbol(I, pack, mcc_name),
		InterSymbolsTables::id_from_symbol(I, pack, RunningPipelines::get_symbol(step, unchecked_kind_RPSYM)), GLOB_IVAL, ID,
		(inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));

	return mcc_name;
}

inter_symbol *CompileSplatsStage::compute_constant_r(inter_tree *I, pipeline_step *step, inter_package *pack, inter_bookmark *IBM, inter_schema_node *isn) {
	if (isn->isn_type == SUBEXPRESSION_ISNT) 
		return CompileSplatsStage::compute_constant_r(I, step, pack, IBM, isn->child_node);
	if (isn->isn_type == OPERATION_ISNT) {
		inter_ti op = 0;
		if (isn->isn_clarifier == PLUS_BIP) op = CONSTANT_SUM_LIST;
		else if (isn->isn_clarifier == TIMES_BIP) op = CONSTANT_PRODUCT_LIST;
		else if (isn->isn_clarifier == MINUS_BIP) op = CONSTANT_DIFFERENCE_LIST;
		else if (isn->isn_clarifier == DIVIDE_BIP) op = CONSTANT_QUOTIENT_LIST;
		else if (isn->isn_clarifier == UNARYMINUS_BIP)
			return CompileSplatsStage::compute_constant_unary_operation(I, step, pack, IBM, isn->child_node);
		else return NULL;
		inter_symbol *i1 = CompileSplatsStage::compute_constant_r(I, step, pack, IBM, isn->child_node);
		inter_symbol *i2 = CompileSplatsStage::compute_constant_r(I, step, pack, IBM, isn->child_node->next_node);
		if ((i1 == NULL) || (i2 == NULL)) return NULL;
		return CompileSplatsStage::compute_constant_binary_operation(op, I, step, pack, IBM, i1, i2);
	}
	if (isn->isn_type == EXPRESSION_ISNT) {
		inter_schema_token *t = isn->expression_tokens;
		if (t->next) {
			if (t->next->next) return NULL;
			inter_symbol *i1 = CompileSplatsStage::compute_constant_eval(I, step, pack, IBM, t);
			inter_symbol *i2 = CompileSplatsStage::compute_constant_eval(I, step, pack, IBM, t->next);
			if ((i1 == NULL) || (i2 == NULL)) return NULL;
			return CompileSplatsStage::compute_constant_binary_operation(CONSTANT_SUM_LIST, I, step, pack, IBM, i1, i2);
		}
		return CompileSplatsStage::compute_constant_eval(I, step, pack, IBM, t);
	}
	return NULL;
}

inter_symbol *CompileSplatsStage::compute_constant_eval(inter_tree *I, pipeline_step *step, inter_package *pack, inter_bookmark *IBM, inter_schema_token *t) {
	inter_ti v1 = UNDEF_IVAL, v2 = 0;
	switch (t->ist_type) {
		case IDENTIFIER_ISTT: {
			inter_symbol *symb = Inter::Connectors::find_socket(I, t->material);
			if (symb) return symb;
			return Inter::Connectors::plug(I, t->material);
		}
		case NUMBER_ISTT:
		case BIN_NUMBER_ISTT:
		case HEX_NUMBER_ISTT:
			if (t->constant_number >= 0) { v1 = LITERAL_IVAL; v2 = (inter_ti) t->constant_number; }
			else if (Inter::Types::read_int_in_I6_notation(t->material, &v1, &v2) == FALSE)
				internal_error("bad number");
			break;
	}
	if (v1 == UNDEF_IVAL) return NULL;
	inter_symbol *mcc_name = CompileSplatsStage::computed_constant_symbol(pack);
	Produce::guard(Inter::Constant::new_numerical(IBM,
		InterSymbolsTables::id_from_symbol(I, pack, mcc_name),
		InterSymbolsTables::id_from_symbol(I, pack, RunningPipelines::get_symbol(step, unchecked_kind_RPSYM)), v1, v2,
		(inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL));
	return mcc_name;
}

inter_symbol *CompileSplatsStage::compute_constant_unary_operation(inter_tree *I, pipeline_step *step, inter_package *pack, inter_bookmark *IBM, inter_schema_node *operand1) {
	inter_symbol *i1 = CompileSplatsStage::compute_constant_r(I, step, pack, IBM, operand1);
	if (i1 == NULL) return NULL;
	inter_symbol *mcc_name = CompileSplatsStage::computed_constant_symbol(pack);
	inter_tree_node *array_in_progress =
		Inode::fill_3(IBM, CONSTANT_IST, InterSymbolsTables::id_from_IRS_and_symbol(IBM, mcc_name), InterSymbolsTables::id_from_symbol(I, pack, RunningPipelines::get_symbol(step, unchecked_kind_RPSYM)), CONSTANT_DIFFERENCE_LIST, NULL, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1);
	int pos = array_in_progress->W.extent;
	if (Inode::extend(array_in_progress, 4) == FALSE)
		internal_error("can't extend frame");
	array_in_progress->W.data[pos] = LITERAL_IVAL; array_in_progress->W.data[pos+1] = 0;
	Inter::Symbols::to_data(I, pack, i1, &(array_in_progress->W.data[pos+2]), &(array_in_progress->W.data[pos+3]));
	Produce::guard(Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), array_in_progress));
	Inter::Bookmarks::insert(IBM, array_in_progress);
	return mcc_name;
}

inter_symbol *CompileSplatsStage::compute_constant_binary_operation(inter_ti op, inter_tree *I, pipeline_step *step, inter_package *pack, inter_bookmark *IBM, inter_symbol *i1, inter_symbol *i2) {
	inter_symbol *mcc_name = CompileSplatsStage::computed_constant_symbol(pack);
	inter_tree_node *array_in_progress =
		Inode::fill_3(IBM, CONSTANT_IST, InterSymbolsTables::id_from_IRS_and_symbol(IBM, mcc_name), InterSymbolsTables::id_from_symbol(I, pack, RunningPipelines::get_symbol(step, unchecked_kind_RPSYM)), op, NULL, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1);
	int pos = array_in_progress->W.extent;
	if (Inode::extend(array_in_progress, 4) == FALSE)
		internal_error("can't extend frame");
	Inter::Symbols::to_data(I, pack, i1, &(array_in_progress->W.data[pos]), &(array_in_progress->W.data[pos+1]));
	Inter::Symbols::to_data(I, pack, i2, &(array_in_progress->W.data[pos+2]), &(array_in_progress->W.data[pos+3]));
	Produce::guard(Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), array_in_progress));
	Inter::Bookmarks::insert(IBM, array_in_progress);
	return mcc_name;
}

int ccs_count = 0;
inter_symbol *CompileSplatsStage::computed_constant_symbol(inter_package *pack) {
	TEMPORARY_TEXT(NN)
	WRITE_TO(NN, "Computed_Constant_Value_%d", ccs_count++);
	inter_symbol *mcc_name = InterSymbolsTables::symbol_from_name_creating(Inter::Packages::scope(pack), NN);
	Inter::Symbols::set_flag(mcc_name, MAKE_NAME_UNIQUE);
	DISCARD_TEXT(NN)
	return mcc_name;
}

typedef struct routine_body_request {
	int assimilation_pass;
	struct inter_bookmark position;
	struct inter_bookmark block_bookmark;
	struct package_request *enclosure;
	struct inter_package *block_package;
	int pass2_offset;
	struct text_stream *body;
	CLASS_DEFINITION
} routine_body_request;

int rb_splat_count = 1;
int CompileSplatsStage::routine_body(compile_splats_state *css,
	inter_bookmark *IBM, inter_package *block_package, inter_ti offset, text_stream *body, inter_bookmark bb) {
	if (Str::is_whitespace(body)) return FALSE;
	routine_body_request *req = CREATE(routine_body_request);
	req->assimilation_pass = css->unique_run_ID;
	req->block_bookmark = bb;
	req->enclosure = Packaging::enclosure(Inter::Bookmarks::tree(IBM));
	req->position = Packaging::bubble_at(IBM);
	req->block_package = block_package;
	req->pass2_offset = (int) offset - 2;
	req->body = Str::duplicate(body);
	return TRUE;
}

void CompileSplatsStage::function_bodies(compile_splats_state *css, inter_tree *I) {
	routine_body_request *req;
	LOOP_OVER(req, routine_body_request)
		if (req->assimilation_pass == css->unique_run_ID) {
			LOGIF(SCHEMA_COMPILATION, "=======\n\nRoutine (%S) len %d: '%S'\n\n", Inter::Packages::name(req->block_package), Str::len(req->body), req->body);
			inter_schema *sch = InterSchemas::from_text(req->body, FALSE, 0, NULL);
		
			if (Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) {
				if (sch == NULL) LOG("NULL SCH\n");
				else if (sch->node_tree == NULL) {
					LOG("Lint fail: Non-empty text but empty scheme\n");
					internal_error("inter schema empty");
				} else InterSchemas::log(DL, sch);
			}
		
			Site::set_cir(I, req->block_package);
			Packaging::set_state(I, &(req->position), req->enclosure);
			Produce::push_code_position(I, Produce::new_cip(I, &(req->position)), Inter::Bookmarks::snapshot(Packaging::at(I)));
			value_holster VH = Holsters::new(INTER_VOID_VHMODE);
			inter_symbols_table *scope1 = Inter::Packages::scope(req->block_package);
			inter_package *template_package = Site::assimilation_package(I);
			inter_symbols_table *scope2 = Inter::Packages::scope(template_package);
			EmitInterSchemas::emit(I, &VH, sch, NULL, scope1, scope2, NULL, NULL);
			Produce::pop_code_position(I);
			Site::set_cir(I, NULL);
		}
}

inter_bookmark CompileSplatsStage::template_submodule(inter_tree *I, pipeline_step *step,
	text_stream *name, inter_tree_node *P) {
	if (RunningPipelines::get_symbol(step, submodule_ptype_RPSYM)) {
		inter_package *template_package = Site::ensure_assimilation_package(I, RunningPipelines::get_symbol(step, plain_ptype_RPSYM));
		inter_package *t_p = Inter::Packages::by_name(template_package, name);
		if (t_p == NULL) {
			inter_bookmark IBM = Inter::Bookmarks::after_this_node(I, P);
			t_p = CompileSplatsStage::new_package_named(&IBM, name, RunningPipelines::get_symbol(step, submodule_ptype_RPSYM));
		}
		if (t_p == NULL) internal_error("failed to define");
		return Inter::Bookmarks::at_end_of_this_package(t_p);
	}
	return Inter::Bookmarks::after_this_node(I, P);
}
