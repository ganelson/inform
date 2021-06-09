[PluginManager::] Plugin Manager.

Creating, activating or deactivating plugins.

@ Plugins are optional extras for the Inform compiler: additions which can be
active or inactive on any given compilation run.

Except for one not-really-a-plugin called "core", each plugin is a piece of
functionality that can be "activated" or "deactivated". Plugins have an
ability to tweak or extend what the compiler does, giving it, for example,
an ability to reason about spatial relationships when the compiler is being
used for interactive fiction; or not, when it isn't.

There is no harm in this hard-wired maximum, since plugins are not things an
author can create in source text; we know exactly how many there are.

@d MAX_PLUGINS 32

=
typedef struct plugin {
	struct text_stream *textual_name;
	struct wording wording_name;
	struct plugin *parent_plugin;
	void (*activation_function)(void);
	int active;
	int permanently_active;
	CLASS_DEFINITION
} plugin;

plugin *PluginManager::new(void (*starter)(void), text_stream *tname, plugin *set) {
	plugin *P = CREATE(plugin);
	P->textual_name = Str::duplicate(tname);
	P->wording_name = Feeds::feed_text(tname);
	P->activation_function = starter;
	P->active = FALSE;
	P->parent_plugin = set;
	if (P->allocation_id >= MAX_PLUGINS) internal_error("Too many plugins");
	return P;
}

@ An inactive plugin does nothing; it's as if that section of code were not in
the compiler at all.

=
int PluginManager::active(plugin *P) {
	return P->active;
}

void PluginManager::list_plugins(OUTPUT_STREAM, int state) {
	plugin *P;
	int c = 0;
	LOOP_OVER(P, plugin) if (P->active == state) {
		if (c > 0) WRITE(", ");
		WRITE("%S", P->textual_name);
		c++;
	}
}

@ In the code above, plugins are set up as inactive by default -- even "core",
which the compiler absolutely cannot live without. So //supervisor: Project Services//
calls the following before switching on optional things that it wants.

=
void PluginManager::activate_bare_minimum(void) {
	plugin *P;
	LOOP_OVER(P, plugin)
		if ((P->permanently_active) && (P->active == FALSE))
			PluginManager::activate(P);
}

void PluginManager::make_permanently_active(plugin *P) {
	if (P == NULL) internal_error("no plugin");
	P->permanently_active = TRUE;
}

@ Most plugins are subordinate to a parent plugin: for example, a dozen more
specific IF-related plugins are subordinate to the "interactive fiction" one.
Activating or deactivating a parent like that automatically activates
or deactivates its children.

=
void PluginManager::activate(plugin *P) {
	if (P) {
		P->active = TRUE;
		plugin *Q;
		LOOP_OVER(Q, plugin)
			if (Q->parent_plugin == P)
				PluginManager::activate(Q);
	}
}

void PluginManager::deactivate(plugin *P) {
	if (P) {
		if (P->permanently_active)
			@<Issue problem for trying to remove the core@>
		else
			P->active = FALSE;
		plugin *Q;
		LOOP_OVER(Q, plugin)
			if (Q->parent_plugin == P)
				PluginManager::deactivate(Q);
	}
}

@<Issue problem for trying to remove the core@> =
	if (problem_count == 0)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(Untestable),
			"the core of the Inform language cannot be removed",
			"because then what should we do? What should we ever do?");
	return;

@ Every active plugin gets to run its start function, if it provides one.

It's kind of incredible that C's grammar for round brackets is unambiguous.

=
void PluginManager::start_plugins(void) {
	plugin *P;
	LOOP_OVER(P, plugin)
		if (P->active) {
			void (*start)() = (void (*)()) P->activation_function;
			if (start) (*start)();
		}
}

@ The names of the great plugins are hard-wired into the compiler rather
than being stored in Preform grammar, and they therefore cannot be translated
out of English. But this is intentional, for now at least. Authors are not
intended to be aware of plugins; it is really kits of Inter code which choose
which plugins are active.

However, because it is possible to have headings in Inform source text which
restrict material according to whether a plugin is active, we do need a
Preform nonterminal to parse them, and here it is.

=
<language-element> internal {
	plugin *P;
	LOOP_OVER(P, plugin)
		if (Wordings::match(P->wording_name, W)) {
			if (P->active == FALSE) {
				==> { FALSE, P };
			} else {
				==> { TRUE, P };
			}
			return TRUE;
		}
	==> { fail nonterminal };
}

@ It's convenient also to provide:

=
plugin *PluginManager::parse(text_stream *S) {
	plugin *P;
	LOOP_OVER(P, plugin)
		if (Str::eq_insensitive(P->textual_name, S))
			return P;
	return NULL;
}

@ Plugins affect the running of the compiler by inserting functions called plugs
into the following "plugin rulebooks" -- there's a mixed metaphor here, but
the idea is that they behave like Inform rulebooks. When a rulebook is called,
the compiler works through each plug until one of them returns something other
than |FALSE|.

Plugins should add plugs in their activation functions, by calling
//PluginManager::plug//, which has an interestingly vague type. The next
screenful of code looks like something of a workout for the C typechecker, but
it compiles under |clang| without even the |-Wpedantic| warning, and honestly
you're barely living as a C programmer if you never generate that one.

=
linked_list *plugin_rulebooks[NO_DEFINED_PLUG_VALUES+1]; /* of |void|, reprehensibly */

void PluginManager::start(void) {
	for (int i=0; i<=NO_DEFINED_PLUG_VALUES; i++)
		plugin_rulebooks[i] = NEW_LINKED_LIST(void);
}

void PluginManager::plug(int code, int (*R)()) {
	if (code > NO_DEFINED_PLUG_VALUES) internal_error("not a plugin call");
	void *vR = (void *) R;
	ADD_TO_LINKED_LIST(vR, void, plugin_rulebooks[code]);
}

@ The functions in //Plugin Calls// then make use of these macros, which are
the easiest way to persuade the C typechecker to allow variable arguments to
be passed in a portable way. Similarly, there are two macros not one because
C does not allow a void variable argument list.

We must take care that the variables introduced in the macro body do not mask
existing variables used in the arguments; the only way to do this is to give
them implausible names.

@d PLUGINS_CALL(code, args...) {
	void *R_plugin_pointer_XYZZY; /* no argument can have this name */
	LOOP_OVER_LINKED_LIST(R_plugin_pointer_XYZZY, void, plugin_rulebooks[code]) {
		int (*R_plugin_rule_ZOOGE)() = (int (*)()) R_plugin_pointer_XYZZY; /* or this one */
		int Q_plugin_return_PLUGH = (*R_plugin_rule_ZOOGE)(args); /* or this */
		if (Q_plugin_return_PLUGH) return Q_plugin_return_PLUGH;
	}
	return FALSE;
}

@d PLUGINS_CALLV(code) {
	void *R_plugin_pointer_XYZZY;
	LOOP_OVER_LINKED_LIST(R_plugin_pointer_XYZZY, void, plugin_rulebooks[code]) {
		int (*R_plugin_rule_ZOOGE)() = (int (*)()) R_plugin_pointer_XYZZY;
		int Q_plugin_return_PLUGH = (*R_plugin_rule_ZOOGE)();
		if (Q_plugin_return_PLUGH) return Q_plugin_return_PLUGH;
	}
	return FALSE;
}
