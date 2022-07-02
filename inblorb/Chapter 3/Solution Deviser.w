[Solution::] Solution Deviser.

To make a solution (.sol) file accompanying a release, if requested.

@h Skein storage.
A solution file is simply a list of commands which will win a work of IF,
starting from turn 1. In this section we will generate this list given the
Skein file for an Inform 7 project: to follow this code, it's useful first
to read the "Walkthrough solutions" section of the "Releasing" chapter
in the main Inform documentation.

We will need to parse the entire skein into a tree structure, in which each
node (including leaves) is one of the following structures. We expect the
Inform user to have annotated certain nodes with the text |***| (three
asterisks); the solution file will ignore all paths in the skein which do
not lead to one of these |***| nodes. The surviving nodes, those in lines
which do lead to |***| endings, are called "relevant".

Some knots have "branch descriptions", others do not. These are the
options where choices have to be made. The |branch_parent| and |branch_count|
fields are used to keep these labels: see below.

=
typedef struct skein_node {
	struct text_stream *id; /* uniquely identifying ID used within the Skein file */
	struct text_stream *command; /* text of the command at this node */
	struct text_stream *annotation; /* text of any annotation added by the user */
	int relevant; /* is this node within one of the "relevant" lines in the skein? */
	struct skein_node *branch_parent; /* the trunk of the branch description, if any, is this way */
	int branch_count; /* the leaf of the branch description, if any, is this number */
	struct skein_node *parent; /* within the Skein tree: |NULL| for the root only */
	struct skein_node *child; /* within the Skein tree: |NULL| if a leaf */
	struct skein_node *sibling; /* within the Skein tree: |NULL| if the final option from its parent */
	CLASS_DEFINITION
} skein_node;

@ The root of the Skein, representing the start position before any command
is typed, lives here:

=
skein_node *root_skn = NULL; /* only |NULL| when the tree is empty */

@h Walking through.
This section provides just one function to the rest of Inblorb: this one,
which implements the Blurb |solution| command.

Our method works in four steps. Steps 1 to 3 have a running time of O(K^2),
where K is the number of knots in the Skein, and step 4 is O(K log K),
so the process as a whole is O(K^2).

=
void Solution::walkthrough(filename *Skein_filename, filename *walkthrough_filename) {
	Solution::build_skein_tree(Skein_filename);
	if (root_skn == NULL) {
		BlorbErrors::error("there appear to be no threads in the Skein");
		return;
	}
	Solution::identify_relevant_lines();
	if (root_skn->relevant == FALSE) {
		BlorbErrors::error("no threads in the Skein have been marked '***'");
		return;
	}
	Solution::prune_irrelevant_lines();
	Solution::write_solution_file(walkthrough_filename);
}

@h Step 1: building the Skein tree.

=
skein_node *current_skein_node = NULL;

void Solution::build_skein_tree(filename *Skein_filename) {
	root_skn = NULL;
	current_skein_node = NULL;
	TextFiles::read(Skein_filename, FALSE, "can't open skein file", FALSE, Solution::read_skein_pass_1, 0, NULL);
	current_skein_node = NULL;
	TextFiles::read(Skein_filename, FALSE, "can't open skein file", FALSE, Solution::read_skein_pass_2, 0, NULL);
}

void Solution::read_skein_pass_1(text_stream *line, text_file_position *tfp, void *state) { Solution::read_skein_line(line, 1); }
void Solution::read_skein_pass_2(text_stream *line, text_file_position *tfp, void *state) { Solution::read_skein_line(line, 2); }

@ The Skein is stored as an XML file. Its format was devised by Andrew Hunter
in the early days of the Inform user interface for Mac OS X, and this was
then adopted by the user interface on other platforms, so that projects could
be freely exchanged between users regardless of their platforms. That makes
it a kind of standard, but it isn't at present a public or documented one.
We shall therefore make few assumptions about it.

=
void Solution::read_skein_line(text_stream *line, int pass) {
	TEMPORARY_TEXT(node_id)
	Solution::find_node_ID_in_tag(node_id, line, "item");
	if (pass == 1) {
		if (Str::len(node_id) > 0) @<Create a new skein tree node with this node ID@>;
		if (current_skein_node) {
			@<Look for a "command" tag and set the command text from it@>;
			@<Look for an "annotation" tag and set the annotation text from it@>;
		}
	} else {
		if (Str::len(node_id) > 0) current_skein_node = Solution::find_node_with_ID(node_id);
		if (current_skein_node) {
			TEMPORARY_TEXT(child_node_id)
			Solution::find_node_ID_in_tag(child_node_id, line, "child");
			if (Str::len(child_node_id) > 0) {
				skein_node *new_child = Solution::find_node_with_ID(child_node_id);
				if (new_child == NULL) {
					BlorbErrors::error("the skein file is malformed (B)");
					return;
				}
				@<Make the parent-child relationship@>;
			}
			DISCARD_TEXT(child_node_id)
		}
	}
	DISCARD_TEXT(node_id)
}

@ Note that the root is the first knot in the Skein file.

@<Create a new skein tree node with this node ID@> =
	current_skein_node = CREATE(skein_node);
	if (root_skn == NULL) root_skn = current_skein_node;
	current_skein_node->id = Str::duplicate(node_id);
	current_skein_node->command = Str::new();
	current_skein_node->annotation = Str::new();
	current_skein_node->branch_count = -1;
	current_skein_node->branch_parent = NULL;
	current_skein_node->parent = NULL;
	current_skein_node->child = NULL;
	current_skein_node->sibling = NULL;
	current_skein_node->relevant = FALSE;
	if (verbose_mode) PRINT("Creating knot with ID '%S'\n", node_id);

@ We make |new_child| the youngest child of |current_skein_mode|:

@<Make the parent-child relationship@> =
	new_child->parent = current_skein_node;
	new_child->sibling = NULL;
	if (current_skein_node->child == NULL) {
		current_skein_node->child = new_child;
	} else {
		skein_node *familial = current_skein_node->child;
		while (familial->sibling) familial = familial->sibling;
		familial->sibling = new_child;
	}

@<Look for a "command" tag and set the command text from it@> =
	text_stream *p = current_skein_node->command;
	if (Solution::find_text_of_tag(p, line, "command")) {
		if (verbose_mode) PRINT("Raw command '%S'\n", p);
		Solution::undo_XML_escapes_in_string(p);
		LOOP_THROUGH_TEXT(pos, p)
			Str::put(pos, Characters::toupper(Str::get(pos)));
		if (verbose_mode) PRINT("Processed command '%S'\n", p);
	}

@<Look for an "annotation" tag and set the annotation text from it@> =
	text_stream *p = current_skein_node->annotation;
	if (Solution::find_text_of_tag(p, line, "annotation")) {
		if (verbose_mode) PRINT("Raw annotation '%S'\n", p);
		Solution::undo_XML_escapes_in_string(p);
		if (verbose_mode) PRINT("Processed annotation '%S'\n", p);
	}

@ Try to find a node ID element attached to a particular tag on the line:

=
void Solution::find_node_ID_in_tag(OUTPUT_STREAM, text_stream *line, char *tag) {
	TEMPORARY_TEXT(prototype)
	WRITE_TO(prototype, "%%c*?<%s nodeId=\"(%%c*?)\"%%c*", tag);
	wchar_t prototype_Cs[128];
	Str::copy_to_wide_string(prototype_Cs, prototype, 128);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, line, prototype_Cs)) Str::copy(OUT, mr.exp[0]);
	else Str::clear(OUT);
	Regexp::dispose_of(&mr);
	DISCARD_TEXT(prototype)
}

@ Try to find the text of a particular tag on the line:

=
int Solution::find_text_of_tag(OUTPUT_STREAM, text_stream *line, char *tag) {
	TEMPORARY_TEXT(prototype)
	WRITE_TO(prototype, "%%c*?>(%%c*?)</%s%%c*", tag);
	match_results mr = Regexp::create_mr();
	wchar_t prototype_Cs[128];
	Str::copy_to_wide_string(prototype_Cs, prototype, 128);
	if (Regexp::match(&mr, line, prototype_Cs)) {
		DISCARD_TEXT(prototype)
		Str::copy(OUT, mr.exp[0]);
		Regexp::dispose_of(&mr);
		return TRUE;
	}
	DISCARD_TEXT(prototype)
	Str::clear(OUT);
	return FALSE;
}

@ This is not very efficient, but:

=
skein_node *Solution::find_node_with_ID(text_stream *id) {
	skein_node *skn;
	LOOP_OVER(skn, skein_node)
		if (Str::eq(id, skn->id) == 0)
			return skn;
	return NULL;
}

@ Finally, we needed the following string hackery:

=
void Solution::undo_XML_escapes_in_string(text_stream *p) {
	int i = 0, j = 0;
	while (Str::get_at(p, i)) {
		if (Str::get_at(p, i) == '&') {
			TEMPORARY_TEXT(xml_escape)
			int k=0;
			while ((Str::get_at(p, i+k) != 0) && (Str::get_at(p, i+k) != ';'))
				PUT_TO(xml_escape, Characters::tolower(Str::get_at(p, i + k++)));
			PUT_TO(xml_escape, Str::get_at(p, i+k));
			@<We have identified an XML escape@>;
			DISCARD_TEXT(xml_escape)
		}
		Str::put_at(p, j++, Str::get_at(p, i++));
	}
	Str::put_at(p, j++, 0);
}

@ Note that all other ampersand-escapes are passed through verbatim.

@<We have identified an XML escape@> =
	wchar_t c = 0;
	if (Str::eq_wide_string(xml_escape, L"&lt;")) c = '<';
	if (Str::eq_wide_string(xml_escape, L"&gt;")) c = '>';
	if (Str::eq_wide_string(xml_escape, L"&amp;")) c = '&';
	if (Str::eq_wide_string(xml_escape, L"&apos;")) c = '\'';
	if (Str::eq_wide_string(xml_escape, L"&quot;")) c = '\"';
	if (c) { Str::put_at(p, j++, c); i += Str::len(xml_escape); continue; }

@h Step 2: identify the relevant lines.
We aim to show how to reach all knots in the Skein annotated with text which
begins with three asterisks. (We trim those asterisks away from the annotation
once we spot them: they have served their purpose.) A knot is "relevant"
if and only if one of its (direct or indirect) children is marked with three
asterisks in this way.

=
void Solution::identify_relevant_lines(void) {
	skein_node *skn;
	LOOP_OVER(skn, skein_node) {
		text_stream *p = skn->annotation;
		if (verbose_mode) PRINT("Knot %S is annotated '%S'\n", skn->id, p);
		if ((Str::get_at(p, 0) == '*') && (Str::get_at(p, 1) == '*') && (Str::get_at(p, 2) == '*')) {
			int i = 3, j; while (Str::get_at(p, i) == ' ') i++;
			for (j=0; Str::get_at(p, i); i++) Str::put_at(p, j++, Str::get_at(p, i)); Str::put_at(p, j, 0);
			skein_node *knot;
			for (knot = skn; knot; knot = knot->parent) {
				knot->relevant = TRUE;
				if (verbose_mode) PRINT("Knot %S is relevant\n", knot->id);
			}
		}
	}
}

@h Step 3: pruning irrelevant lines out of the tree.
When the loop below concludes, the relevant nodes are exactly those in the
component of the tree root, because:

(a) No irrelevant node can be the child of a relevant one; and no
relevant node can be the child of an irrelevant one by definition. So the
tree falls into components each of which is fully relevant or fully not.
(b) Since we never break any relevant-parent-relevant-child relationships, the
number of components containing at least one relevant node is unchanged.
(c) Since the Skein is initially a tree and not a forest, we start with
just one component, and it contains the tree root, which is known to be
relevant (we would have given up with an error message if not).
(d) And therefore at the end of the loop the "tree" consists of a single
component headed by the tree root and containing all of the relevant nodes,
together with any number of other components each of which contains only
irrelevant ones.

=
void Solution::prune_irrelevant_lines(void) {
	skein_node *skn;
	LOOP_OVER(skn, skein_node)
		if ((skn->relevant == FALSE) && (skn->parent))
			@<Delete this node from its parent@>;
}

@<Delete this node from its parent@> =
	if (skn->parent->child == skn) {
		skn->parent->child = skn->sibling;
	} else {
		skein_node *skn2 = skn->parent->child;
		while ((skn2) && (skn2->sibling != skn)) skn2 = skn2->sibling;
		if ((skn2) && (skn2->sibling == skn)) skn2->sibling = skn->sibling;
	}
	skn->parent = NULL;
	skn->sibling = NULL;


@h Step 4: writing the solution file.

=
void Solution::write_solution_file(filename *walkthrough_filename) {
	text_stream TO_struct;
	text_stream *SOL = &TO_struct;
	if (STREAM_OPEN_TO_FILE(SOL, walkthrough_filename, UTF8_ENC) == FALSE)
		BlorbErrors::fatal_fs("can't open solution text file for output", walkthrough_filename);
	WRITE_TO(SOL, "Solution to \""); Placeholders::write(SOL, I"TITLE");
	WRITE_TO(SOL, "\" by "); Placeholders::write(SOL, I"AUTHOR"); WRITE_TO(SOL, "\n\n");
	Solution::recursively_solve(SOL, root_skn, NULL);
	STREAM_CLOSE(SOL);
}

@ The following prints commands to the solution file from the position |skn| --
which means just after typing its command -- with the aim of reaching all
relevant endings we can get to from there.

=
void Solution::recursively_solve(OUTPUT_STREAM, skein_node *skn, skein_node *last_branch) {
	@<Follow the skein down until we reach a divergence, if we do@>;
	@<Print the various alternatives from this knot where the threads diverge@>;
	@<Show the solutions down each of these alternative lines in turn@>;
}

@ If there's only a single option from here, we could print it and then
call |Solution::recursively_solve| down from it. That would make the code shorter and
clearer, perhaps, but it would clobber the C stack: our recursion depth
might be into the tens of thousands on long solution files. So we tail-recurse
instead of calling ourselves, so to speak, and just run down the thread
until we reach a choice. (If we never do reach a choice, we can return --
there is nowhere else to reach.)

@<Follow the skein down until we reach a divergence, if we do@> =
	while ((skn->child == NULL) || (skn->child->sibling == NULL)) {
		if (skn->child == NULL) return;
		if (skn->child->sibling == NULL) {
			skn = skn->child;
			Solution::write_command(OUT, skn, NORMAL_COMMAND);
		}
	}

@ Thus we are here only when there are at least two alternative commands
we might use from position |skn|.

@<Print the various alternatives from this knot where the threads diverge@> =
	WRITE("Choice:\n");
	int branch_counter = 1;
	skein_node *option;
	for (option = skn->child; option; option = option->sibling)
		if (option->child == NULL) {
			Solution::write_command(OUT, option, BRANCH_TO_END_COMMAND);
		} else {
			option->branch_count = branch_counter++;
			option->branch_parent = last_branch;
			Solution::write_command(OUT, option, BRANCH_TO_LINE_COMMAND);
		}

@<Show the solutions down each of these alternative lines in turn@> =
	skein_node *option;
	for (option = skn->child; option; option = option->sibling)
		if (option->child) {
			WRITE("\nBranch (");
			Solution::write_branch_name(OUT, option);
			WRITE(")\n");
			Solution::recursively_solve(OUT, option, option);
		}

@h Writing individual commands and branch descriptions.

@d NORMAL_COMMAND 1
@d BRANCH_TO_END_COMMAND 2
@d BRANCH_TO_LINE_COMMAND 3

=
void Solution::write_command(OUTPUT_STREAM, skein_node *cmd_skn, int form) {
	if (form != NORMAL_COMMAND) WRITE("  ");
	WRITE("%S", cmd_skn->command);
	if (form != NORMAL_COMMAND) {
		WRITE(" -> ");
		if (form == BRANCH_TO_LINE_COMMAND) {
			WRITE("go to branch (");
			Solution::write_branch_name(OUT, cmd_skn);
			WRITE(")");
		}
		else WRITE("end");
	}
	if (Str::len(cmd_skn->annotation) > 0) WRITE(" ... %S", cmd_skn->annotation);
	WRITE("\n");
}

@ For instance, at the third option from a thread which ran back to being
the second option from a thread which ran back to being the seventh option
from the original position, the following would print "7.2.3". Note that
only the knots representing the positions after commands which make a choice
are labelled in this way.

=
void Solution::write_branch_name(OUTPUT_STREAM, skein_node *skn) {
	if (skn->branch_parent) {
		Solution::write_branch_name(OUT, skn->branch_parent);
		WRITE(".");
	}
	WRITE("%d", skn->branch_count);
}
