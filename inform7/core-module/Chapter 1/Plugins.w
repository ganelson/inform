[PluginManager::] Plugins.

Plugins are optional extras for the Inform compiler: additions which can be
active or inactive on any given compilation run.

@ Except for one not-really-a-plugin called "core", each plugin is a piece of
functionality that can be "activated" or "deactivated". Plugins have an
ability to tweak or extend what the compiler does, giving it, for example,
an ability to reason about spatial relationships when the compiler is being
used for interactive fiction; or not, when it isn't.

=
void PluginManager::start(void) {
	PluginCalls::initialise_calls();
}

@

@d MAX_PLUGINS 32

=
typedef struct plugin {
	struct text_stream *textual_name;
	struct wording wording_name;
	struct plugin *parent_plugin;
	void (*starter_routine)(void);
	int active;
	CLASS_DEFINITION
} plugin;

plugin *PluginManager::new(void (*starter)(void), text_stream *tname, plugin *set) {
	plugin *P = CREATE(plugin);
	P->textual_name = Str::duplicate(tname);
	P->wording_name = Feeds::feed_text(tname);
	P->starter_routine = starter;
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

void PluginManager::list_plugins(OUTPUT_STREAM, char *label, int state) {
	plugin *P;
	int c = 0;
	WRITE("%s: ", label);
	LOOP_OVER(P, plugin) if (P->active == state) {
		if (c > 0) WRITE(", ");
		WRITE("%S", P->textual_name);
		c++;
	}
	if (c == 0) WRITE("<i>none</i>");
	WRITE(".\n");
}

@ In the code above, plugins are set up as inactive by default -- even "core",
which the compiler absolutely cannot live without. See //supervisor: Project Services//
for how the set of active plugins for a compilation is determined in practice;
note, in particularly, that it wisely chooses to activate the core.

Most plugins are subordinate to a parent plugin: for example, a dozen more
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
				Q->active = TRUE;
	}
}

void PluginManager::deactivate(plugin *P) {
	if (P) {
		P->active = FALSE;
		plugin *Q;
		LOOP_OVER(Q, plugin)
			if (Q->parent_plugin == P) {
				if (Q == core_plugin)
					@<Issue problem for trying to remove the core@>
				else Q->active = FALSE;
		}
	}
}

@<Issue problem for trying to remove the core@> =
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
			void (*start)() = (void (*)()) P->starter_routine;
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
