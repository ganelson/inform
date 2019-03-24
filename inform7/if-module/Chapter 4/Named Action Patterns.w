[PL::Actions::Patterns::Named::] Named Action Patterns.

A named action pattern is a named categorisation of actions, such as
"acting suspiciously", which is a disjunction of action patterns (stored in
a linked list).

@h Definitions.

=
typedef struct named_action_pattern {
	struct noun *name;
	struct action_pattern *first; /* list of APs defining this NAP */
	struct wording text_of_declaration;
	struct inter_name *nap_iname; /* for an I6 routine to test this NAP */
	MEMORY_MANAGEMENT
} named_action_pattern;

@ =
named_action_pattern *PL::Actions::Patterns::Named::nap_new(wording W) {
	named_action_pattern *nap = CREATE(named_action_pattern);
	nap->first = NULL;
	nap->text_of_declaration = W;
	nap->name = Nouns::new_proper_noun(W, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		NAMED_AP_MC, Rvalues::from_named_action_pattern(nap));

	compilation_module *C = Modules::find(current_sentence);
	package_request *PR = Packaging::request_resource(C, GRAMMAR_SUBPACKAGE);
	nap->nap_iname = Packaging::function(
		InterNames::one_off(I"nap_fn", PR),
		PR,
		InterNames::new(NAMED_ACTION_PATTERN_INAMEF));
	return nap;
}

named_action_pattern *PL::Actions::Patterns::Named::by_name(wording W) {
	parse_node *p = ExParser::parse_excerpt(NAMED_AP_MC, W);
	if (p) return Rvalues::to_named_action_pattern(p);
	return NULL;
}

inter_name *PL::Actions::Patterns::Named::identifier(named_action_pattern *nap) {
	return nap->nap_iname;
}

void PL::Actions::Patterns::Named::add(action_pattern *app, wording W) {
	app->entered_into_NAP_here = current_sentence;
	named_action_pattern *nap;

	nap = PL::Actions::Patterns::Named::by_name(W);
	if (nap) {
		action_pattern *list;
		list = nap->first; while (list->next) list = list->next;
		list->next = app;
		return;
	}

	nap = PL::Actions::Patterns::Named::nap_new(W);
	nap->first = app;
}

int PL::Actions::Patterns::Named::within_action_context(named_action_pattern *nap, action_name *an) {
	action_pattern *ap;
	for (ap = nap->first; ap; ap = ap->next)
		if (PL::Actions::Patterns::within_action_context(ap, an)) return TRUE;
	return FALSE;
}

void PL::Actions::Patterns::Named::index(OUTPUT_STREAM) {
	named_action_pattern *nap;
	action_pattern *ap;
	int num_naps = NUMBER_CREATED(named_action_pattern);

	if (num_naps == 0) {
		HTML_OPEN("p");
		WRITE("No names for kinds of action have yet been defined.");
		HTML_CLOSE("p");
	}

	LOOP_OVER(nap, named_action_pattern) {
		HTML_OPEN("p"); WRITE("<b>%+W</b>", Nouns::nominative(nap->name));
		Index::link(OUT, Wordings::first_wn(nap->text_of_declaration));
		HTML_TAG("br");
		ap = nap->first;
		WRITE("&nbsp;&nbsp;<i>defined as any of the following acts:</i>\n");
		while (ap != NULL) {
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;%+W", ap->text_of_pattern);
			Index::link(OUT, Wordings::first_wn(ap->text_of_pattern));
			ap = ap->next;
		}
		HTML_CLOSE("p");
	}
}

void PL::Actions::Patterns::Named::compile(void) {
	named_action_pattern *nap;
	action_pattern *ap;
	LOOP_OVER(nap, named_action_pattern) {
		packaging_state save = Routines::begin(nap->nap_iname);
		ap = nap->first;
		while (ap != NULL) {
			current_sentence = ap->entered_into_NAP_here;
			Emit::inv_primitive(if_interp);
			Emit::down();
				PL::Actions::Patterns::emit_pattern_match(*ap, TRUE);
				Emit::code();
				Emit::down();
					Emit::rtrue();
				Emit::up();
			Emit::up();
			ap = ap->next;
		}
		Emit::rfalse();
		Routines::end(save);
	}
}

void PL::Actions::Patterns::Named::index_for_extension(OUTPUT_STREAM, source_file *sf, extension_file *ef) {
	named_action_pattern *nap;
	int kc = 0;
	LOOP_OVER(nap, named_action_pattern)
		if (Lexer::file_of_origin(Wordings::first_wn(nap->text_of_declaration)) == ef->read_into_file)
			kc = Extensions::Documentation::document_headword(OUT, kc, ef, "Kinds of action", I"kind of action",
				nap->text_of_declaration);
	if (kc != 0) HTML_CLOSE("p");
}
