[ParsingStages::] Parsing Stages.

Two stages which accept raw I6-syntax material in the parse tree, either from
imsertions made using Inform 7's low-level features, or after reading the
source code for a kit.

@ These stages have more in common than first appears. Both convert I6T-syntax
source code into a series of |SPLAT_IST| nodes in the Inter tree, with one
such node for each different directive in the I6T source.

The T in "I6T" stands for "template", which in the 2010s was a mechanism for
providing I6 code to I7. That's not the arrangement any more, but the syntax
(partly) lives on, and so does the name I6T. Still, it's really just the same
thing as Inform 6 code in an Inweb-style literate programming notation.

=
void ParsingStages::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"load-kit-source", ParsingStages::run_load_kit_source,
		KIT_STAGE_ARG, TRUE);	
	ParsingPipelines::new_stage(I"parse-insertions", ParsingStages::run_parse_insertions,
		NO_STAGE_ARG, FALSE);
}

@ The stage |load-kit-source K| takes the kit |K|, looks for its source code
(text files written in I6T syntax) and reads this in to the current Inter tree,
placing the resulting nodes in a new top-level module. A typical kit may
turn into anywhere from 50 to 2000 such nodes. Speed is not very important
here, since this is not part of the Inform 7 compilation pipeline.

=
int ParsingStages::run_load_kit_source(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	inter_package *main_package = LargeScale::main_package(I);
	@<Create a module to hold the Inter read in from this kit@>;
	simple_tangle_docket docket;
	@<Make a suitable simple tangler docket@>;
	SimpleTangler::tangle_web(&docket);
	return TRUE;
}

@ So for example if we are reading the source for WorldModelKit, then the
following creates the package |/main/WorldModelKit|, with package type |_module|.
It's into this module that the resulting |SPLAT_IST| nodes will be put.

@<Create a module to hold the Inter read in from this kit@> =
	inter_bookmark IBM = InterBookmark::at_end_of_this_package(main_package);
	inter_symbol *module_name = LargeScale::package_type(I, I"_module");
	inter_package *module_pack = NULL;
	Produce::guard(PackageInstruction::new_package_named(&IBM, step->step_argument, FALSE,
		module_name, 1, NULL, &module_pack));
	step->pipeline->ephemera.assimilation_modules[step->tree_argument] = module_pack;

@ The stage |parse-insertions| does the same thing, but on a much smaller scale,
and reading raw I6T source code from |LINK_IST| nodes in the Inter tree rather
than from an external file. Speed is not important here either, but only because
there will only be a few |LINK_IST| nodes to deal with, and with not much code
in them. They arise from low-level Inform 7 features such as
= (text as Inform 7)
Include (-
	[ CuriousFunction;
		print "Curious!";
	];
-).
=
The //inform7// code does not contain a compiler from I6T down to Inter, so
it can only leave us these unparsed fragments as |LINK_IST| nodes. We take
it from there.

=
int ParsingStages::run_parse_insertions(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	simple_tangle_docket docket;
	@<Make a suitable simple tangler docket@>;
	InterTree::traverse(I, ParsingStages::visit_insertions, &docket, NULL, LINK_IST);
	return TRUE;
}

void ParsingStages::visit_insertions(inter_tree *I, inter_tree_node *P, void *state) {
	text_stream *insertion = Inode::ID_to_text(P, P->W.instruction[TO_RAW_LINK_IFLD]);
	simple_tangle_docket *docket = (simple_tangle_docket *) state;
	inter_bookmark here = InterBookmark::after_this_node(P);
	docket->state = (void *) &here;
	SimpleTangler::tangle_text(docket, insertion);
}

@ So, then, both of those stages rely on making something called an simple
tangler docket, which is really just a collection of settings for the
simple tangler. That comes down to:

(a) the place to put any nodes generated,
(b) what to do with I6 source code, or with commands embedded in it, or errors
thrown by bad syntax in it, and
(c) which file-system paths to look inside when reading from files rather
than raw text in memory.

For (c), note that if a kit is in directory |K| then its source files are
in |K/Sections|.

@<Make a suitable simple tangler docket@> =
	inter_package *assimilation_package =
		step->pipeline->ephemera.assimilation_modules[step->tree_argument];
	if (assimilation_package == NULL) assimilation_package = LargeScale::main_package(I);
	inter_bookmark assimilation_point =
		InterBookmark::at_end_of_this_package(assimilation_package);
	docket = SimpleTangler::new_docket(
		&(ParsingStages::receive_raw),
		&(ParsingStages::receive_command),
		&(ParsingStages::receive_bplus),
		&(PipelineErrors::kit_error),
		step->ephemera.the_kit, &assimilation_point);

@ Once the I6T reader has unpacked the literate-programming notation, it will
reduce the I6T code to pure Inform 6 source together with (perhaps) a handful of
commands in braces. Our docket must say what to do with each of these outputs.

The easy part: what to do when we find a command in I6T source. In pre-Inter
versions of Inform, when I6T was just a way of expressing Inform 6 code but
with some braced commands mixed in, there were lots of legal if enigmatic
syntaxes in use. Now those have all gone, so in all cases we issue an error:

=
void ParsingStages::receive_command(OUTPUT_STREAM, text_stream *command,
	text_stream *argument, simple_tangle_docket *docket) {
	if ((Str::eq_wide_string(command, L"plugin")) ||
		(Str::eq_wide_string(command, L"type")) ||
		(Str::eq_wide_string(command, L"open-file")) ||
		(Str::eq_wide_string(command, L"close-file")) ||
		(Str::eq_wide_string(command, L"lines")) ||
		(Str::eq_wide_string(command, L"endlines")) ||
		(Str::eq_wide_string(command, L"open-index")) ||
		(Str::eq_wide_string(command, L"close-index")) ||
		(Str::eq_wide_string(command, L"index-page")) ||
		(Str::eq_wide_string(command, L"index-element")) ||
		(Str::eq_wide_string(command, L"index")) ||
		(Str::eq_wide_string(command, L"log")) ||
		(Str::eq_wide_string(command, L"log-phase")) ||
		(Str::eq_wide_string(command, L"progress-stage")) ||
		(Str::eq_wide_string(command, L"counter")) ||
		(Str::eq_wide_string(command, L"value")) ||
		(Str::eq_wide_string(command, L"read-assertions")) ||
		(Str::eq_wide_string(command, L"callv")) ||
		(Str::eq_wide_string(command, L"call")) ||
		(Str::eq_wide_string(command, L"array")) ||
		(Str::eq_wide_string(command, L"marker")) ||
		(Str::eq_wide_string(command, L"testing-routine")) ||
		(Str::eq_wide_string(command, L"testing-command"))) {
		LOG("command: <%S> argument: <%S>\n", command, argument);
		(*(docket->error_callback))(
			"the template command '{-%S}' has been withdrawn in this version of Inform",
			command);
	} else {
		LOG("command: <%S> argument: <%S>\n", command, argument);
		(*(docket->error_callback))("no such {-command} as '%S'", command);
	}
}

@ We have similarly withdrawn the ability to write |(+| ... |+)| material
in kit files:

=
void ParsingStages::receive_bplus(text_stream *material, simple_tangle_docket *docket) {
	(*(docket->error_callback))(
		"use of (+ ... +) in kit source has been withdrawn: '%S'", material);
}

@ We very much do not ignore the raw I6 code read in, though. When the reader
gives us a chunk of this, we parse through it with a simple finite-state machine.
This can be summarised as "divide the code up at |;| boundaries, sending each
piece in turn to //ParsingStages::splat//". But of course we do not want to
react to semicolons in quoted text or comments, and in fact we also do not
want to react to semicolons used as statement dividers inside I6 routines (i.e.,
functions). So for example
= (text as Inform 6)
Global aspic = "this; and that";
! Don't react to this; I'm only a comment
[ Hello; print "Hello; goodbye.^"; ];
=
would be divided into just two splats,
= (text as Inform 6)
Global aspic = "this; and that";
=
and
= (text as Inform 6)
[ Hello; print "Hello; goodbye.^"; ];
=
(And the comment would be stripped out entirely.)

@d IGNORE_WS_I6TBIT 1
@d DQUOTED_I6TBIT 2
@d SQUOTED_I6TBIT 4
@d COMMENTED_I6TBIT 8
@d ROUTINED_I6TBIT 16
@d CONTENT_ON_LINE_I6TBIT 32

@d SUBORDINATE_I6TBITS
	(COMMENTED_I6TBIT + SQUOTED_I6TBIT + DQUOTED_I6TBIT + ROUTINED_I6TBIT)

=
void ParsingStages::receive_raw(text_stream *S, simple_tangle_docket *docket) {
	text_stream *R = Str::new();
	int mode = IGNORE_WS_I6TBIT;
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == 10) || (c == 13)) c = '\n';
		if (mode & IGNORE_WS_I6TBIT) {
			if ((c == '\n') || (Characters::is_whitespace(c))) continue;
			mode -= IGNORE_WS_I6TBIT;
		}
		if ((c == '!') && (!(mode & (DQUOTED_I6TBIT + SQUOTED_I6TBIT)))) {
			mode = mode | COMMENTED_I6TBIT;
		}
		if (mode & COMMENTED_I6TBIT) {
			if (c == '\n') {
				mode -= COMMENTED_I6TBIT;
				if (!(mode & CONTENT_ON_LINE_I6TBIT)) continue;
			}
			else continue;
		}
		if ((c == '[') && (!(mode & SUBORDINATE_I6TBITS))) {
			mode = mode | ROUTINED_I6TBIT;
		}
		if (mode & ROUTINED_I6TBIT) {
			if ((c == ']') && (!(mode & (DQUOTED_I6TBIT + SQUOTED_I6TBIT + COMMENTED_I6TBIT))))
				mode -= ROUTINED_I6TBIT;
		}
		if ((c == '\'') && (!(mode & (DQUOTED_I6TBIT + COMMENTED_I6TBIT)))) {
			if (mode & SQUOTED_I6TBIT) mode -= SQUOTED_I6TBIT;
			else mode = mode | SQUOTED_I6TBIT;
		}
		if ((c == '\"') && (!(mode & (SQUOTED_I6TBIT + COMMENTED_I6TBIT)))) {
			if (mode & DQUOTED_I6TBIT) mode -= DQUOTED_I6TBIT;
			else mode = mode | DQUOTED_I6TBIT;
		}
		if (c != '\n') {
			if (Characters::is_whitespace(c) == FALSE)
				mode = mode | CONTENT_ON_LINE_I6TBIT;
		} else {
			if (mode & CONTENT_ON_LINE_I6TBIT) mode = mode - CONTENT_ON_LINE_I6TBIT;
			else if (!(mode & SUBORDINATE_I6TBITS)) continue;
		}
		PUT_TO(R, c);
		if ((c == ';') && (!(mode & SUBORDINATE_I6TBITS))) {
			ParsingStages::splat(R, docket);
			mode = IGNORE_WS_I6TBIT;
		}
	}
	ParsingStages::splat(R, docket);
	Str::clear(S);
}

@ Each of those "splats", provided it is not entirely white space, becomes a
|SPLAT_IST| node in the tree at the current insertion point recorded in the
state being carried in the docket.

Note that this function empties the splat buffer |R| before exiting.

=
void ParsingStages::splat(text_stream *R, simple_tangle_docket *docket) {
	if (Str::len(R) > 0) {
		inter_ti I6_dir = 0;
		@<Find directive@>;
		if (I6_dir != WHITESPACE_I6DIR) {
			inter_bookmark *IBM = (inter_bookmark *) docket->state;
			PUT_TO(R, '\n');
			inter_ti SID = InterWarehouse::create_text(
				InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
			text_stream *textual_storage =
				InterWarehouse::get_text(InterBookmark::warehouse(IBM), SID);
			Str::copy(textual_storage, R);
			Produce::guard(SplatInstruction::new(IBM, SID, I6_dir,
				(inter_ti) (InterBookmark::baseline(IBM) + 1), NULL));
		}
		Str::clear(R);
	}
}

@ A |SPLAT_IST| node should record which sort of Inform 6 directive it contains,
assuming we know that. We will recognise only the following set, and use |MYSTERY_I6DIR|
for anything else. If the splat doesn't appear to be a directive at all, we leave
the directive type as 0.

@<Find directive@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, R, L" *(%C+) *(%c*);%c*")) {
		     if (Str::eq_insensitive(mr.exp[0], I"#ifdef"))      I6_dir = IFDEF_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"#ifndef"))     I6_dir = IFNDEF_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"#iftrue"))     I6_dir = IFTRUE_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"#ifnot"))      I6_dir = IFNOT_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"#endif"))      I6_dir = ENDIF_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"#stub"))       I6_dir = STUB_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Constant"))    I6_dir = CONSTANT_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Global"))      I6_dir = GLOBAL_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Array"))       I6_dir = ARRAY_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"["))           I6_dir = ROUTINE_I6DIR;

		else if (Str::eq_insensitive(mr.exp[0], I"Attribute"))   I6_dir = ATTRIBUTE_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Property"))    I6_dir = PROPERTY_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Verb"))        I6_dir = VERB_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Fake_action")) I6_dir = FAKEACTION_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Object"))      I6_dir = OBJECT_I6DIR;
		else if (Str::eq_insensitive(mr.exp[0], I"Default"))     I6_dir = DEFAULT_I6DIR;
		else I6_dir = MYSTERY_I6DIR;
	} else {
		int I6_dir = WHITESPACE_I6DIR;
		LOOP_THROUGH_TEXT(pos, R)
			if (Characters::is_whitespace(Str::get(pos)) == FALSE)
				I6_dir = 0;
	}
	Regexp::dispose_of(&mr);

@ And that's it: the result of these stages is just to break the I6T source they
found up into individual directives, and put them into the tree as |SPLAT_IST| nodes.
No effort has been made yet to see what directives they are. Subsequent stages
will handle that.
