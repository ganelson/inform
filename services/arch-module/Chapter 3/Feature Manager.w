[Features::] Feature Manager.

Creating, activating or deactivating compiler features.

@ "Features" are optional pieces of compiler functionality, which are given
textual names. They can be "activated" or "deactivated", that is, on or off.
For example, some of the interactive-fiction support in the Inform compiler
is provided by features which are deactivated for Basic Inform projects.
Incompletely implemented, or experimental, functions under development can
also be gated behind features which are deactivated by default, and activated
just for test projects.

It turns out to be convenient to have a hard-wired maximum number of these.
But since features are not things an author can create in source text, we always
know exactly how many there are.

@d MAX_COMPILER_FEATURES 32

=
typedef struct compiler_feature {
	struct text_stream *textual_name;
	struct compiler_feature *parent_feature;
	void (*activation_function)(void);
	int active;
	int permanently_active;
	int activation_function_run;
	CLASS_DEFINITION
} compiler_feature;

compiler_feature *Features::new(void (*starter)(void), text_stream *tname, compiler_feature *set) {
	compiler_feature *F = CREATE(compiler_feature);
	F->textual_name = Str::duplicate(tname);
	F->activation_function = starter;
	F->active = FALSE;
	F->parent_feature = set;
	F->activation_function_run = FALSE;
	if (F->allocation_id >= MAX_COMPILER_FEATURES)
		internal_error("too many features");
	return F;
}

@ With so few features in existence, there's no need to do this more efficiently:

=
compiler_feature *Features::from_name(text_stream *S) {
	compiler_feature *F;
	LOOP_OVER(F, compiler_feature)
		if (Str::eq_insensitive(F->textual_name, S))
			return F;
	return NULL;
}

@ The idea is that an inactive feature does nothing; it's as if that section of
code were not in the compiler at all. These provide convenient shorthand ways
to test that:

@d FEATURE_ACTIVE(name) Features::active(name##_feature)
@d FEATURE_INACTIVE(name) (Features::active(name##_feature) == FALSE)

=
int Features::active(compiler_feature *F) {
	return F->active;
}

void Features::list(OUTPUT_STREAM, int state, compiler_feature *except) {
	compiler_feature *F;
	int c = 0;
	LOOP_OVER(F, compiler_feature) if (F->active == state)
		if ((except == FALSE) || (Features::part_of(F, except) == FALSE)) {
			if (c > 0) WRITE(", ");
			WRITE("%S", F->textual_name);
			c++;
		}
}

@ In the code above, features are set up as inactive by default -- even "core",
which the compiler absolutely cannot live without. So //supervisor: Project Services//
calls the following before switching on optional things that it wants.

=
void Features::activate_bare_minimum(void) {
	compiler_feature *F;
	LOOP_OVER(F, compiler_feature)
		if ((F->permanently_active) && (F->active == FALSE))
			Features::activate(F);
}

void Features::make_permanently_active(compiler_feature *F) {
	if (F == NULL) internal_error("no feature");
	F->permanently_active = TRUE;
}

@ Most features are subordinate to a parent feature: for example, a dozen more
specific IF-related features are subordinate to the "interactive fiction" one.

=
int Features::part_of(compiler_feature *F, compiler_feature *G) {
	while ((F != G) && (F != NULL)) F = F->parent_feature;
	if (F == G) return TRUE;
	return FALSE;
}

@ Activating or deactivating a parent like that automatically activates
or deactivates its children.

=
void Features::activate(compiler_feature *F) {
	if ((F) && (F->active == FALSE)) {
		F->active = TRUE;
		Features::run_activation_function(F);
		compiler_feature *G;
		LOOP_OVER(G, compiler_feature)
			if (G->parent_feature == F)
				Features::activate(G);
	}
}

@ Whereas anything can be activated, some things cannot be deactivated, so the
following returns a success flag:

=
int Features::deactivate(compiler_feature *F) {
	if ((F) && (F->active)) {
		if (F->permanently_active) return FALSE;
		F->active = FALSE;
		compiler_feature *G;
		LOOP_OVER(G, compiler_feature)
			if (G->parent_feature == F)
				if (Features::deactivate(G) == FALSE)
					return FALSE;
	}
	return TRUE;
}

@ Every active feature gets to run its start function, if it provides one.
But this is postponed until //Features::run_activation_functions// is called;
at that point, every activated feature runs its function. If any feature is
activated after this point, its function runs immediately. (The point of the
postponement is that very early in Inform's run, the memory manager may not
yet be working, and so on.)

It's kind of incredible that C's grammar for round brackets is unambiguous.

=
int allow_activation_functions_to_be_run = FALSE;

void Features::allow_activation_functions(void) {
	allow_activation_functions_to_be_run = TRUE;
}

void Features::run_activation_functions(void) {
	compiler_feature *F;
	LOOP_OVER(F, compiler_feature)
		if (F->active)
			Features::run_activation_function(F);
}

void Features::run_activation_function(compiler_feature *F) {
	if ((allow_activation_functions_to_be_run) && (F) &&
		(F->activation_function_run == FALSE)) {
		F->activation_function_run = TRUE;
		if (F->activation_function) (*(F->activation_function))();
	}
}

@ Basic features which are present in all three Inform compiler tools:

=
compiler_feature *core_feature = NULL, *experimental_feature = NULL,
	*dialogue_feature = NULL, *concepts_feature = NULL;

void Features::activate_core(void) {
	core_feature = Features::new(NULL, I"core", NULL);
	Features::make_permanently_active(core_feature);

	experimental_feature = Features::new(NULL, I"experimental features", NULL);
	#ifdef IF_MODULE
	dialogue_feature = Features::new(&Dialogue::start, I"dialogue", experimental_feature);
	#endif
	#ifndef IF_MODULE
	dialogue_feature = Features::new(NULL, I"dialogue", experimental_feature);
	#endif
	concepts_feature = Features::new(NULL, I"concepts", dialogue_feature);
}
