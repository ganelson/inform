[PerformanceStyles::] Performance Styles.

Manners of speaking, used in dialogue.

@ This feature, |performance styles|, is technically part of |dialogue|, not part of |if|.

=
void PerformanceStyles::start(void) {
	PerformanceStyles::declare_annotations();
	PluginCalls::plug(NEW_INSTANCE_NOTIFY_PLUG, PerformanceStyles::new_named_instance_notify);
	PluginCalls::plug(NEW_BASE_KIND_NOTIFY_PLUG, PerformanceStyles::new_base_kind_notify);
	PluginCalls::plug(COMPARE_CONSTANT_PLUG, PerformanceStyles::compare_CONSTANT);
}

@ Performance styles are the instances of a built-in enumeration kind, created by a
Neptune file belonging to //DialogueKit//, and this is recognised by its Inter
identifier |PERFORMANCE_STYLE_TY|.

= (early code)
kind *K_performance_style = NULL;

@ =
int PerformanceStyles::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, U"PERFORMANCE_STYLE_TY")) {
		K_performance_style = new_base; return TRUE;
	}
	return FALSE;
}

@

=
int PerformanceStyles::new_named_instance_notify(instance *I) {
	if ((K_scene) && (Kinds::eq(Instances::to_kind(I), K_performance_style))) {
		PerformanceStyles::new(I);
		return TRUE;
	}
	return FALSE;
}

@ =
parse_node *PerformanceStyles::rvalue_from_performance_style(performance_style *val) {
	CONV_FROM(performance_style, K_performance_style) }
performance_style *PerformanceStyles::rvalue_to_performance_style(parse_node *spec) {
	CONV_TO(performance_style) }

int PerformanceStyles::compare_CONSTANT(parse_node *spec1, parse_node *spec2, int *rv) {
	kind *K = Node::get_kind_of_value(spec1);
	if (Kinds::eq(K, K_performance_style)) {
		if (PerformanceStyles::rvalue_to_performance_style(spec1) ==
			PerformanceStyles::rvalue_to_performance_style(spec2)) {
			*rv = TRUE;
		}
		*rv = FALSE;
		return TRUE;
	}
	return FALSE;
}

@ This feature needs one extra syntax tree annotation:

@e constant_performance_style_ANNOT /* |performance_style|: for constant values */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(constant_performance_style, performance_style)

@ =
MAKE_ANNOTATION_FUNCTIONS(constant_performance_style, performance_style)

void PerformanceStyles::declare_annotations(void) {
	Annotations::declare_type(constant_performance_style_ANNOT,
		PerformanceStyles::write_constant_performance_style_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_performance_style_ANNOT);
}
void PerformanceStyles::write_constant_performance_style_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_performance_style(p))
		WRITE(" {performance_style: %I}", Node::get_constant_performance_style(p)->as_instance);
}

@ Internally, styles have the following additional data:

=
typedef struct performance_style {
	struct instance *as_instance; /* the constant for the name of the style */
	struct wording stem_of_name;
	CLASS_DEFINITION
} performance_style;

wording PerformanceStyles::get_name(performance_style *ps) {
	return Instances::get_name(ps->as_instance, FALSE);
}

@ The default style, created by the Standard Rules, is here:

=
performance_style *PS_spoken_normally = NULL;

performance_style *PerformanceStyles::default(void) {
	return PS_spoken_normally;
}

@ A feature called |xyzzy| generally has a hunk of subject data called |xyzzy_data|,
so we would normally have a structure called |performance_styles_data|, but in fact that
structure is just going to be //performance_style//. So:

@d performance_styles_data performance_style
@d PERFORMANCE_STYLES_DATA(subj) FEATURE_DATA_ON_SUBJECT(performance_styles, subj)

@ The following is called whenever a new instance of "performance style" is created:

=
void PerformanceStyles::new(instance *I) {
	performance_style *ps = CREATE(performance_style);
	@<Connect the performance style structure to the instance@>;
	@<Initialise the performance style structure@>;
	wording N = Instances::get_name(I, FALSE);
	if (<performance-style-name-convention>(N)) {
		ps->stem_of_name = GET_RW(<performance-style-name-convention>, 1);
		if ((<dialogue-line-clause>(ps->stem_of_name)) && (<<r>> != STYLE_DLC)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, ps->stem_of_name);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_AmbiguousPerformanceStyle));
			Problems::issue_problem_segment(
				"The sentence %1 creates a performance style which would have "
				"to be used by marking a line as '(%2)', but that already has "
				"a meaning as a line annotation, so this would be ambiguous. "
				"Call it something else?");
			Problems::issue_problem_end();
		}
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, N);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_NonspokenPerformanceStyle));
		Problems::issue_problem_segment(
			"The sentence %1 creates a performance style called '%2', "
			"but all performance style names have to begin with 'spoken' "
			"(for example, 'spoken quickly').");
		Problems::issue_problem_end();
	}
}

@ =
<performance-style-name-convention> ::=
	spoken ...

@

@<Initialise the performance style structure@> =
	ps->stem_of_name = EMPTY_WORDING;

@ This is a style name which Inform provides special support for; it recognises
the English name, so there is no need to translate this to other languages.

=
<notable-performance-styles> ::=
	spoken normally

@<Connect the performance style structure to the instance@> =
	ps->as_instance = I;
	ATTACH_FEATURE_DATA_TO_SUBJECT(performance_styles, I->as_subject, ps);
	wording W = Instances::get_name(I, FALSE);
	if (<notable-performance-styles>(W)) PS_spoken_normally = ps;

@ So we sometimes want to be able to get from an instance to its performance style
structure.

=
performance_style *PerformanceStyles::from_named_constant(instance *I) {
	if (K_performance_style == NULL) return NULL;
	kind *K = Instances::to_kind(I);
	if (Kinds::eq(K, K_performance_style))
		return FEATURE_DATA_ON_SUBJECT(performance_styles, I->as_subject);
	return NULL;
}

@ We parse the name of a style first by the regular excerpt parser, which
would pick up something like "spoken normally", and then by hand if that
fails, looking for the abbreviated form "normally". Speed isn't very important
here, since the only context in which the word "spoken" can be omitted is in
the bracketed clauses of a line, so the total number of calls to this function
will never be more than the number of dialogue lines in the story.

=
performance_style *PerformanceStyles::parse_style(wording CW) {
	if (<s-type-expression-uncached>(CW)) {
		parse_node *desc = <<rp>>;
		kind *K = Specifications::to_kind(desc);
		if (Kinds::eq(K, K_performance_style)) {
			instance *I = Rvalues::to_instance(desc);
			if (I) {
				performance_style *ps = PerformanceStyles::from_named_constant(I);
				if (ps) return ps;
			}
		}
	}

	performance_style *ps;
	LOOP_OVER(ps, performance_style)
		if (Wordings::match(CW, ps->stem_of_name))
			return ps;

	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, CW);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_LineInUnknownPerformanceStyle));
	Problems::issue_problem_segment(
		"The dialogue line %1 is apparently spoken in the style '%2', but that "
		"doesn't seem to correspond to any style I know of.");
	Problems::issue_problem_end();
	return NULL;
}
