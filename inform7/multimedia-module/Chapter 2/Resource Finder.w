[ResourceFinder::] Resource Finder.

To find resources such as sound and image files.

@h Resource finder.
This simple function is shared by the code for figures, sound effects and
internal data files. When Inform reads a sentence such as:
= (text as Inform 7)
	Sound of Organ is the file "Passacaglia.mid".
=
it looks for the file first in the |Sounds| folder of the materials for the
project, and then, if it isn't there, in the |Sounds| folder of the materials
for the extension in which the sentence occurs (if it occurs in an extension).
Here |"Sounds"| is what we will call the department name for sound effects.

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

	pathname *P1 = Pathnames::down(Task::resources_path(), department);
	pathname *P2 = E?(Pathnames::down(Extensions::materials_path(E), department)):NULL;
	if (P1) {
		filename *F = Filenames::in(P1, leaf);
		FILE *HANDLE = Filenames::fopen(F, "rb");
		if (HANDLE) {
			fclose(HANDLE);
			return F;
		}
	}
	if (P2) {
		filename *F = Filenames::in(P2, leaf);
		FILE *HANDLE = Filenames::fopen(F, "rb");
		if (HANDLE) {
			fclose(HANDLE);
			return F;
		}
	}

	if (check_resources_are_present == FALSE) return Filenames::in(P1, leaf);

	LOG("Tried in %p\n", P1);
	if (P2) LOG("And also in %p\n", P2);

	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_stream(3, department);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
	Problems::issue_problem_segment(
		"You wrote %1, which means I am looking for a file called %2, but I'm "
		"unable to find it. ");
	if (P2)
		Problems::issue_problem_segment(
			"The file should either be in the '%3' subfolder of the materials folder, "
			"or in the 'Materials/%3' subfolder of this extension.");
	else
		Problems::issue_problem_segment(
			"The file should be in the '%3' subfolder of the materials folder.");
	Problems::issue_problem_end();
	return NULL;
}
