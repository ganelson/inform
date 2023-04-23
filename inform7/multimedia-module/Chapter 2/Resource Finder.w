[ResourceFinder::] Resource Finder.

To find resources such as sound and image files.

@h Resource finder.
This simple function is shared by the code for figures, sound effects and
internal data files. When Inform reads a sentence such as:
= (text as Inform 7)
	Sound of Organ is the file "Passacaglia.aiff".
=
it needs to find this file, which will either be in the materials for the
project, or in materials for the extension in which this sentence occurs
(if it occurs in an extension). In either case, it'll be in the |Sounds|
subdirectory. Here |"Sounds"| is what we will call the department name for
sound effects.

This code was introduced as part of the implementation of IE-0001, and for
the first time throws problem messages is named resources do not exist.

=
int check_resources_are_present = TRUE;

void ResourceFinder::set_mode(int val) {
	check_resources_are_present = val; /* set by |-resource-checking| at command line */
}

filename *ResourceFinder::find_resource(text_stream *department, text_stream *leaf, wording W) {
	inform_extension *E = NULL;
	if (Wordings::nonempty(W))
		E = Extensions::corresponding_to(Lexer::file_of_origin(Wordings::first_wn(W)));

	pathname *materials_dept = Pathnames::down(Task::resources_path(), department);
	pathname *extension_dept = E?(Pathnames::down(Extensions::materials_path(E), department)):NULL;
	if (extension_dept) @<Look for an extension resource@>;
	if (materials_dept) @<Look for a regular materials resource@>;

	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_stream(3, department);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
	Problems::issue_problem_segment(
		"You wrote %1, which means I am looking for a file called %2, but I'm "
		"unable to find it. ");
	if (extension_dept)
		Problems::issue_problem_segment(
			"The file should either be in the '%3' subfolder of the materials folder, "
			"or in the 'Materials/%3' subfolder of this extension.");
	else
		Problems::issue_problem_segment(
			"The file should be in the '%3' subfolder of the materials folder.");
	Problems::issue_problem_end();
	return NULL;
}

@ So here we're reading the line from an extension, say |Leipzig Organ Recitals|.
We first look for an audio file called something like
|Leipzig Organ Recitals-v1/Materials/Sounds/Passacaglia.aiff|. If that exists, then we
know this is a resource which the extension provides; but we still give the 
project a chance to override that with a file
|Project.materials/Sounds/Leipzig Organ Recitals/Passacaglia.aiff|,
which would be used in preference.

@<Look for an extension resource@> =
	filename *F = ResourceFinder::if_present(Filenames::in(extension_dept, leaf));
	if (F) {
		pathname *materials_override =
			Pathnames::down(materials_dept, E->as_copy->edition->work->title);
		filename *OF = ResourceFinder::if_present(Filenames::in(materials_override, leaf));
		if (OF) return OF;
		return F;
	}

@ Otherwise the resource is not provided by the extension in which the sentence
occurs, or else, the sentence does not occur in an extension. (Of course, this is
by far the most likely thing.) Here we just look in the project's materials folder,
so for example |Project.materials/Sounds/Passacaglia.aiff|.

@<Look for a regular materials resource@> =
	filename *F = Filenames::in(materials_dept, leaf);
	if (check_resources_are_present == FALSE) return F;
	F = ResourceFinder::if_present(F);
	if (F) return F;

@ This checks the existence of such a file on disc. We're not going to fret
over the possibility of accidentally opening a directory here.

=
filename *ResourceFinder::if_present(filename *F) {
	FILE *handle = Filenames::fopen(F, "rb");
	if (handle == NULL) return NULL;
	fclose(handle);
	return F;
}
