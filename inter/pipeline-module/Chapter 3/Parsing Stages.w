[ParsingStages::] Parsing Stages.

Two stages which accept raw I6-syntax material in the parse tree, either from
insertions made using Inform 7's low-level features, or after reading the
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
	TEMPORARY_TEXT(namespacename)
	simple_tangle_docket docket;
	@<Make a suitable simple tangler docket@>;
	SimpleTangler::tangle_web(&docket);
	DISCARD_TEXT(namespacename)
	return TRUE;
}

@ So for example if we are reading the source for WorldModelKit, then the
following creates the package |/main/WorldModelKit|, with package type |_module|.
It's into this module that the resulting |SPLAT_IST| nodes will be put.

@<Create a module to hold the Inter read in from this kit@> =
	inter_bookmark IBM = InterBookmark::at_end_of_this_package(main_package);
	inter_symbol *module_name = LargeScale::package_type(I, I"_module");
	inter_package *module_pack = NULL;
	Produce::guard(PackageInstruction::new(&IBM, step->step_argument,
		InterTypes::unchecked(), FALSE, module_name, 1, NULL, &module_pack));
	step->pipeline->ephemera.assimilation_modules[step->tree_argument] = module_pack;

@ The stage |parse-insertions| does the same thing, but on a much smaller scale,
and reading raw I6T source code from |INSERT_IST| nodes in the Inter tree rather
than from an external file. Speed is not important here either, but only because
there will only be a few |INSERT_IST| nodes to deal with, and with not much code
in them. They arise from low-level Inform 7 features such as
= (text as Inform 7)
Include (-
	[ CuriousFunction;
		print "Curious!";
	];
-).
=
The //inform7// code does not contain a compiler from I6T down to Inter, so
it can only leave us these unparsed fragments as |INSERT_IST| nodes. We take
it from there.

=
typedef struct rpi_state {
	struct simple_tangle_docket *docket;
	struct pipeline_step *step;
} rpi_state;

int ParsingStages::run_parse_insertions(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	TEMPORARY_TEXT(namespacename)
	simple_tangle_docket docket;
	@<Make a suitable simple tangler docket@>;
	rpi_state rpis;
	rpis.docket = &docket;
	rpis.step = step;
	InterTree::traverse(I, ParsingStages::visit_insertions, &rpis, NULL, INSERT_IST);
	DISCARD_TEXT(namespacename)
	return TRUE;
}

void ParsingStages::visit_insertions(inter_tree *I, inter_tree_node *P, void *state) {
	text_stream *insertion = InsertInstruction::insertion(P);
	rpi_state *rpis = (rpi_state *) state;
	simple_tangle_docket *docket = rpis->docket;
	inter_bookmark here = InterBookmark::after_this_node(P);
	rpi_docket_state *docket_state = (rpi_docket_state *) docket->state;
	docket_state->assimilation_point = &here;
	docket_state->provenance = InsertInstruction::provenance(P);
	SimpleTangler::tangle_text(docket, insertion);
	text_stream *replacing = InsertInstruction::replacing(P);
	if (Str::len(replacing) > 0) {
		linked_list *L = rpis->step->pipeline->ephemera.replacements_list[rpis->step->tree_argument];
		ADD_TO_LINKED_LIST(replacing, text_stream, L);
	}
}

@ So, then, both of those stages rely on making something called a simple
tangler docket, which is really just a collection of settings for the
simple tangler. That comes down to:

(a) the place to put any nodes generated,
(b) what to do with I6 source code, or with commands embedded in it, or errors
thrown by bad syntax in it, and
(c) which file-system paths to look inside when reading from files rather
than raw text in memory.

For (c), note that if a kit is in directory |K| then its source files are
in |K/Sections|.

@ =
typedef struct rpi_docket_state {
	struct inter_bookmark *assimilation_point;
	struct text_stream *namespace;
	struct text_provenance provenance;
} rpi_docket_state;

@<Make a suitable simple tangler docket@> =
	inter_package *assimilation_package =
		step->pipeline->ephemera.assimilation_modules[step->tree_argument];
	if (assimilation_package == NULL) assimilation_package = LargeScale::main_package(I);
	inter_bookmark assimilation_point =
		InterBookmark::at_end_of_this_package(assimilation_package);
	rpi_docket_state state;
	state.assimilation_point = &assimilation_point;
	state.namespace = namespacename;
	state.provenance = Provenance::nowhere();
	docket = SimpleTangler::new_docket(
		&(ParsingStages::receive_raw),
		&(ParsingStages::receive_command),
		&(ParsingStages::receive_bplus),
		&(ParsingStages::line_marker),
		&(I6Errors::issue),
		step->ephemera.the_kit, &state);

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

@ This is used to place I6 comments showing the provenance of the tangled text:

=
void ParsingStages::line_marker(text_stream *material, simple_tangle_docket *docket) {
	WRITE_TO(material, "! LINEMARKER %d %f\n", docket->current_start_line, docket->current_filename);
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
@d NOTE_LINES_I6TBIT 64

@d SUBORDINATE_I6TBITS
	(COMMENTED_I6TBIT + SQUOTED_I6TBIT + DQUOTED_I6TBIT + ROUTINED_I6TBIT)

=
void ParsingStages::receive_raw(text_stream *S, simple_tangle_docket *docket) {
	text_stream *R = Str::new();
	int mode = IGNORE_WS_I6TBIT + NOTE_LINES_I6TBIT;
	rpi_docket_state *state = (rpi_docket_state *) docket->state;
	int lc = Provenance::get_line(state->provenance);
	for (int pos = 0; pos < Str::len(S); pos++) {
		wchar_t c = Str::get_at(S, pos);
		if ((c == 10) || (c == 13)) { c = '\n'; lc++; }
		if ((c == '!') && (Str::includes_at(S, pos, I"! LINEMARKER "))) {
			text_stream *file_text = Str::new();
			TEMPORARY_TEXT(number_text)
			int in_number = TRUE;
			for (pos = pos + 13; pos < Str::len(S); pos++) {
				wchar_t c = Str::get_at(S, pos);
				if ((c == 10) || (c == 13)) break;
				if ((c == ' ') && (in_number)) { in_number = FALSE; continue; }
				if (in_number) PUT_TO(number_text, c);
				else PUT_TO(file_text, c);
			}
			lc = Str::atoi(number_text, 0);
			state->provenance = Provenance::at_file_and_line(file_text, lc);
			DISCARD_TEXT(number_text)
			continue;
		}
		if (mode & IGNORE_WS_I6TBIT) {
			if ((c == '\n') || (Characters::is_whitespace(c))) continue;
			mode -= IGNORE_WS_I6TBIT;
			if (mode & NOTE_LINES_I6TBIT) {
				mode -= NOTE_LINES_I6TBIT;
				Provenance::set_line(&(state->provenance), lc);
			}
		}
		if ((c == '!') && (!(mode & (DQUOTED_I6TBIT + SQUOTED_I6TBIT)))) {
			mode = mode | COMMENTED_I6TBIT;
		}
		if (mode & COMMENTED_I6TBIT) {
			if (c == '\n') mode -= COMMENTED_I6TBIT;
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
			Provenance::set_line(&(state->provenance), lc);
			mode = IGNORE_WS_I6TBIT + NOTE_LINES_I6TBIT;
		}
	}
	ParsingStages::splat(R, docket);
	Provenance::set_line(&(state->provenance), lc);
	Str::clear(S);
}

@ Each of those "splats", provided it is not entirely white space, becomes a
|SPLAT_IST| node in the tree at the current insertion point recorded in the
state being carried in the docket.

Note that this function empties the splat buffer |R| before exiting.

=
void ParsingStages::splat(text_stream *R, simple_tangle_docket *docket) {
	if (Str::len(R) > 0) {
		rpi_docket_state *state = (rpi_docket_state *) docket->state;
		I6Errors::set_current_location(state->provenance);

		TEMPORARY_TEXT(A)
		@<Find annotation, if any@>;
		inter_ti I6_dir = 0;

		@<Find directive@>;
		if (I6_dir != WHITESPACE_PLM) @<Splat the directive@>
		else if (A) {
			I6_annotation *IA = I6Annotations::parse(A);
			if ((IA) && (Str::eq_insensitive(IA->identifier, I"namespace"))) {
				@<Respond to a change of namespace@>;
			} else {
				 I6Errors::issue(
					"the annotation '%S' seems not to apply to any directive: "
					"only '+namespace' can do that", A);
			}
			I6Errors::clear_current_location();
		}
		Str::clear(R);
		DISCARD_TEXT(A)
	}
}

@<Find annotation, if any@> =
	int verdict = I6Annotations::check(R);
	if (verdict == -1) {
		I6Errors::issue("this +annotation is malformed: '%S'", R);
	} else {
		for (int i=0; i<verdict; i++) PUT_TO(A, Str::get_at(R, i));
		Str::trim_white_space(A);
		Str::delete_n_characters(R, verdict);
	}

@ A |SPLAT_IST| node should record which sort of Inform 6 directive it contains,
assuming we know that. We will recognise only the following set, and use |MYSTERY_PLM|
for anything else. If the splat doesn't appear to be a directive at all, we leave
the directive type as 0.

@<Find directive@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, R, L" *(%[) *(%c*);%c*")) {
		I6_dir = ROUTINE_PLM;
	} else if (Regexp::match(&mr, R, L" *#*(%C+) *(%c*);%c*")) {
		     if (Str::eq_insensitive(mr.exp[0], I"Ifdef"))      I6_dir = IFDEF_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Ifndef"))     I6_dir = IFNDEF_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Iftrue"))     I6_dir = IFTRUE_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Ifnot"))      I6_dir = IFNOT_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Endif"))      I6_dir = ENDIF_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"OrigSource")) I6_dir = ORIGSOURCE_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Stub"))       I6_dir = STUB_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Constant"))    I6_dir = CONSTANT_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Global"))      I6_dir = GLOBAL_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Array"))       I6_dir = ARRAY_PLM;

		else if (Str::eq_insensitive(mr.exp[0], I"Attribute"))   I6_dir = ATTRIBUTE_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Property"))    I6_dir = PROPERTY_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Verb"))        I6_dir = VERB_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Fake_action")) I6_dir = FAKEACTION_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Object"))      I6_dir = OBJECT_PLM;
		else if (Str::eq_insensitive(mr.exp[0], I"Default"))     I6_dir = DEFAULT_PLM;
		else I6_dir = MYSTERY_PLM;
	} else {
		I6_dir = WHITESPACE_PLM;
		LOOP_THROUGH_TEXT(pos, R)
			if ((Characters::is_whitespace(Str::get(pos)) == FALSE) &&
				(Str::get(pos) != ';'))
				I6_dir = MYSTERY_PLM;
	}
	if (I6_dir == MYSTERY_PLM) {
		int known = FALSE;
		     if (Str::eq_insensitive(mr.exp[0], I"Ifv3"))        known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Ifv5"))        known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Iffalse"))     known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Abbreviate"))  known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Dictionary"))  known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Import"))      known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Link"))        known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Lowstring"))   known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Message"))     known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Replace"))     known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Switches"))    known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Trace"))       known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Undef"))       known = TRUE;
		else if (Str::eq_insensitive(mr.exp[0], I"Version"))     known = TRUE;
		if (known)
			I6Errors::issue(
				"this Inform 6 directive is not supported in kits or '(-' inclusions: '%S' "
				"(only #Ifdef, #Ifndef, #Iftrue, #Ifnot, #Endif, #OrigSource, #Stub, Constant, Global, "
				"Array, Attribute, Property, Verb, Fake_action, Object, Default are "
				"supported)", R);
		else
			I6Errors::issue("this is not an Inform 6 directive", R);
	}
	Regexp::dispose_of(&mr);

@<Splat the directive@> =
	inter_bookmark *IBM = state->assimilation_point;
	PUT_TO(R, '\n');
	filename *F = NULL;
	inter_ti lc = 0;
	if (Provenance::is_somewhere(state->provenance)) {
		F = Provenance::get_filename(state->provenance);
		lc = (inter_ti) Provenance::get_line(state->provenance);
	}
	Produce::guard(SplatInstruction::new(IBM, R, I6_dir, A, state->namespace,
		F, lc, (inter_ti) (InterBookmark::baseline(IBM) + 1), NULL));

@ So the following picks up |+namespace(Whatever)| annotations, which do not
apply to any directive.

@<Respond to a change of namespace@> =
	Str::clear(state->namespace);
	int private = NOT_APPLICABLE;
	I6_annotation_term *term;
	LOOP_OVER_LINKED_LIST(term, I6_annotation_term, IA->terms) {
		if (Str::eq_insensitive(term->key, I"_")) {
			WRITE_TO(state->namespace, "%S", term->value);
		} else if (Str::eq_insensitive(term->key, I"access")) {
			if (Str::eq_insensitive(term->value, I"private")) private = TRUE;
			else if (Str::eq_insensitive(term->value, I"public")) private = FALSE;
			else I6Errors::issue(
				"in a +namespace annotation, the 'access' must be 'private' or "
				"'public', not '%S'", term->value);
		} else {
			I6Errors::issue(
				"the +namespace annotation does not take the term '%S'", term->key);
		}
	}
	@<Vet the new namespace name@>;
	if (private == TRUE) PUT_TO(state->namespace, '-');
	if (private == FALSE) PUT_TO(state->namespace, '+');

@<Vet the new namespace name@> =
	int bad_name = FALSE;
	for (int i=0; i<Str::len(state->namespace); i++) {
		wchar_t c = Str::get_at(state->namespace, i);
		if (i == 0) {
			if (Characters::isalpha(c) == FALSE) bad_name = TRUE;
		} else {
			if ((Characters::isalnum(c) == FALSE) && (c != '_')) bad_name = TRUE;
		}
	}
	if (bad_name)
		 I6Errors::issue(
			"the namespace '%S' is not allowed: namespace names should begin "
			"with a letter and contain only alphanumeric characters or '_'",
			state->namespace);
	if (Str::len(state->namespace) == 0)
		 I6Errors::issue(
			"'+namespace()' is not allowed: use '+namespace(main);' to return "
			"to the global namespace", NULL);
	if (Str::eq(state->namespace, I"main")) Str::clear(state->namespace);
	else if (Str::eq_insensitive(state->namespace, I"main"))
		 I6Errors::issue(
			"'+namespace(...)' names are case-sensitive: use 'main', not '%S', "
			"to return to the global namespace", state->namespace);
	if (Str::eq(state->namespace, I"replaced")) {
		 I6Errors::issue(
			"the namespace 'replaced' is reserved, and cannot be used directly", NULL);
		Str::clear(state->namespace);
	}

@ And that's it: the result of these stages is just to break the I6T source they
found up into individual directives, and put them into the tree as |SPLAT_IST| nodes.
No effort has been made yet to see what directives they are. Subsequent stages
will handle that.
