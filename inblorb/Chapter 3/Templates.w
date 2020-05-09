[Templates::] Templates.

To manage templates for website generation.

@h Templates and their paths.
Template paths define, in order of priority, where to look for templates.

=
typedef struct template_path {
	struct pathname *template_repository; /* pathname of folder of repository */
	CLASS_DEFINITION
} template_path;

@ Whereas templates are the things themselves.

=
typedef struct template {
	struct text_stream *template_name; /* e.g., "Standard" */
	struct template_path *template_location;
	struct filename *latest_use; /* filename most recently sought from it */
	CLASS_DEFINITION
} template;

@h Defining template paths.
The following implements the Blurb command "template path".

=
int no_template_paths = 0;
void Templates::new_path(pathname *P) {
	template_path *tp = CREATE(template_path);
	tp->template_repository = P;
	if (verbose_mode)
		PRINT("! Template search path %d: <%p>\n", ++no_template_paths, P);
}

@ The following searches for a named file in a named template, returning
the template path which holds the template if it exists. This might look a
pretty odd thing to do -- weren't we looking for the file itself? But the
answer is that |Templates::seek_file| is really used to detect
the presence of templates, not of files.

=
template_path *Templates::seek_file(text_stream *name, text_stream *leafname) {
	template_path *tp;
	LOOP_OVER(tp, template_path) {
		pathname *T = Pathnames::down(tp->template_repository, name);
		filename *possible = Filenames::in(T, leafname);
		if (TextFiles::exists(possible)) return tp;
	}
	return NULL;
}

@ And this is where that happens. Suppose we need to locate the template
"Molybdenum". We ought to do this by looking for a directory of that name
among the template paths, but searching for directories is a little tricky
to do in ANSI C in a way which will work on all platforms. So instead we
look for any of the four files which compulsorily ought to exist (or the
one which does in the case of an interpreter; those look rather like
website templates).

=
template *Templates::find_file(text_stream *name) {
	template *t;
	@<Is this a template we already know?@>;
	template_path *tp = Templates::seek_file(name, I"index.html");
	if (tp == NULL) tp = Templates::seek_file(name, I"source.html");
	if (tp == NULL) tp = Templates::seek_file(name, I"style.css");
	if (tp == NULL) tp = Templates::seek_file(name, I"(extras).txt");
	if (tp == NULL) tp = Templates::seek_file(name, I"(manifest).txt");
	if (tp) {
		t = CREATE(template);
		t->template_name = Str::duplicate(name);
		t->template_location = tp;
		return t;
	}
	return NULL;
}

@ It reduces pointless file accesses to cache the results, so:

@<Is this a template we already know?@> =
	LOOP_OVER(t, template)
		if (Str::eq(name, t->template_name))
			return t;

@h Searching for template files.
If we can't find the file |name| in the template specified, we try looking
inside "Standard" instead (if we can find a template of that name).

=
int template_doesnt_exist = FALSE;
filename *Templates::find_file_in_specific_template(text_stream *name, text_stream *needed) {
	template *t = Templates::find_file(name), *Standard = Templates::find_file(I"Standard");
	if (t == NULL) {
		if (template_doesnt_exist == FALSE) {
			BlorbErrors::errorf_1S(
				"Websites and play-in-browser interpreter web pages are created "
				"using named templates. (Basic examples are built into the Inform "
				"application. You can also create your own, putting them in the "
				"'Templates' subfolder of the project's Materials folder.) Each "
				"template has a name. On this Release, I tried to use the "
				"'%S' template, but couldn't find a copy of it anywhere.", name);
		}
		template_doesnt_exist = TRUE;
	}
	filename *path = Templates::try_single(t, needed);
	if ((path == NULL) && (Standard)) path = Templates::try_single(Standard, needed);
	return path;
}

@ Where, finally:

=
filename *Templates::try_single(template *t, text_stream *needed) {
	if (t == NULL) return NULL;

	pathname *T = Pathnames::down(t->template_location->template_repository, t->template_name);
	t->latest_use = Filenames::in(T, needed);
	if (verbose_mode) PRINT("! Trying <%f>\n", t->latest_use);
	if (TextFiles::exists(t->latest_use)) return t->latest_use;
	return NULL;
}
