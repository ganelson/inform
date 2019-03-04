[Readme::] Readme Writeme.

To construct Readme and similar files.

@

=
typedef struct write_state {
	struct text_stream *OUT;
	int file_open;
	struct text_stream the_file;
	struct macro *current_definition;
} write_state;

typedef struct macro {
	struct text_stream *name;
	struct text_stream *content;
	struct macro_tokens tokens;
	MEMORY_MANAGEMENT
} macro;

typedef struct macro_tokens {
	struct macro *bound_to;
	struct text_stream *pars[8];
	int no_pars;
	struct macro_tokens *down;
	MEMORY_MANAGEMENT
} macro_tokens;

macro_tokens *mt_stack = NULL;

void Readme::write(filename *from) {
	write_state ws;
	ws.OUT = STDOUT;
	ws.file_open = FALSE;
	ws.current_definition = NULL;
	TextFiles::read(from, FALSE, "unable to read template file", TRUE,
		&Readme::write_line, NULL, (void *) &ws);
	Readme::close(&ws);
}

@ 

=
void Readme::write_line(text_stream *text, text_file_position *tfp, void *state) {
	write_state *ws = (write_state *) state;
	text_stream *OUT = ws->OUT;

	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L" *@end *")) {
		if (ws->current_definition == NULL) Errors::in_text_file("@end without @define", tfp);
		else ws->current_definition = NULL;
		Regexp::dispose_of(&mr);
		return;
	}
	if (ws->current_definition) {
		WRITE_TO(ws->current_definition->content, "%S\n", text);
		Regexp::dispose_of(&mr);
		return;
	}
	if (Regexp::match(&mr, text, L" *@define (%i+)(%c*)")) {
		if (ws->current_definition) Errors::in_text_file("@define without @end", tfp);
		else {
			ws->current_definition = CREATE(macro);
			ws->current_definition->name = Str::duplicate(mr.exp[0]);
			ws->current_definition->tokens = Readme::parse_token_list(mr.exp[1], tfp);
			ws->current_definition->content = Str::new();
		}
		Regexp::dispose_of(&mr);
		return;
	}
	if (Regexp::match(&mr, text, L" *@-> *(%c+?) *")) {
		pathname *P = Filenames::get_path_to(tfp->text_file_filename);
		filename *F = Filenames::from_text_relative(P, mr.exp[0]);
		WRITE_TO(STDOUT, "inpolicy: %f --> %f\n", tfp->text_file_filename, F);
		Readme::close(ws);
		if (Streams::open_to_file(&(ws->the_file), F, UTF8_ENC) == FALSE)
			Errors::fatal_with_file("can't write readme file", F);
		ws->file_open = TRUE;
		ws->OUT = &(ws->the_file);
		Regexp::dispose_of(&mr);
		return;
	}
	Readme::expand(ws, OUT, text, tfp);
	Readme::expand(ws, OUT, I"\n", tfp);
	Regexp::dispose_of(&mr);
}

void Readme::expand(write_state *ws, text_stream *OUT, text_stream *text, text_file_position *tfp) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L"(%c*?)@(%i+)(%c*)")) {
		Readme::expand(ws, OUT, mr.exp[0], tfp);
		macro_tokens mt = Readme::parse_token_list(mr.exp[2], tfp);
		mt.down = mt_stack;
		mt_stack = &mt;
		Readme::command(ws, OUT, mr.exp[1], tfp);
		mt_stack = mt.down;
		Readme::expand(ws, OUT, mr.exp[2], tfp);
	} else {
		WRITE("%S", text);
	}
	Regexp::dispose_of(&mr);
}

@ =
macro_tokens Readme::parse_token_list(text_stream *chunk, text_file_position *tfp) {
	macro_tokens mt;
	mt.no_pars = 0;
	mt.down = NULL;
	mt.bound_to = NULL;
	if (Str::get_first_char(chunk) == '(') {
		int x = 1, bl = 1, from = 1, quoted = FALSE;
		while ((bl > 0) && (Str::get_at(chunk, x) != 0)) {
			wchar_t c = Str::get_at(chunk, x);
			if (c == '\'') {
				quoted = quoted?FALSE:TRUE;
			} else if (quoted == FALSE) {
				if (c == '(') bl++;
				else if (c == ')') {
					bl--;
					if (bl == 0) @<Recognise token@>;
				} else if ((c == ',') && (bl == 1)) @<Recognise token@>;
			}
			x++;
		}
		Str::delete_n_characters(chunk, x);
	}
	return mt;
}

@<Recognise token@> =
	int n = mt.no_pars;
	if (n >= 8) Errors::in_text_file("too many parameters", tfp);
	else {
		mt.pars[n] = Str::new();
		for (int j=from; j<x; j++) PUT_TO(mt.pars[n], Str::get_at(chunk, j));
		Str::trim_white_space(mt.pars[n]);
		if ((Str::get_first_char(mt.pars[n]) == '\'') && (Str::get_last_char(mt.pars[n]) == '\'')) {
			Str::delete_first_character(mt.pars[n]);
			Str::delete_last_character(mt.pars[n]);
		}
		mt.no_pars++;
	}
	from = x+1;

@ =
void Readme::command(write_state *ws, text_stream *OUT, text_stream *command, text_file_position *tfp) {	
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, command, L"version")) {
		if (mt_stack->no_pars != 1) Errors::in_text_file("@version takes 1 parameter", tfp);
		else {
			TEMPORARY_TEXT(program);
			Readme::expand(ws, program, mt_stack->pars[0], tfp);
			project *P = Inversion::read(program, TRUE);
			DISCARD_TEXT(program);
			if (P->current_version) {
				WRITE("version %S '%S'", P->current_version->number, P->current_version->name);
				if (Str::ne(P->current_version->build_code, I"9Z99"))
					WRITE(" (build %S)", P->current_version->build_code);
			}
		}
		Regexp::dispose_of(&mr);
		return;
	}
	if (Regexp::match(&mr, command, L"purpose")) {
		if (mt_stack->no_pars != 1) Errors::in_text_file("@purpose takes 1 parameter", tfp);
		else {
			TEMPORARY_TEXT(program);
			Readme::expand(ws, program, mt_stack->pars[0], tfp);
			project *P = Inversion::read(program, TRUE);
			DISCARD_TEXT(program);
			WRITE("%S", P->purpose);
		}
		Regexp::dispose_of(&mr);
		return;
	}
	macro_tokens *stack = mt_stack;
	while (stack) {
		macro *in = stack->bound_to;
		if (in)
			for (int n = 0; n < in->tokens.no_pars; n++)
				if (Str::eq(in->tokens.pars[n], command)) {
					if (n < stack->no_pars) {
						Readme::expand(ws, OUT, stack->pars[n], tfp);
						Regexp::dispose_of(&mr);
						return;
					}
				}
		stack = stack->down;
	}
	macro *M;
	LOOP_OVER(M, macro)
		if (Str::eq(M->name, command)) {
			mt_stack->bound_to = M;
			Readme::expand(ws, OUT, M->content, tfp);
			Regexp::dispose_of(&mr);
			return;
		}
	Errors::in_text_file("no such @-command", tfp);
	WRITE_TO(STDERR, "(command is '%S')\n", command);
	Regexp::dispose_of(&mr);
}

@ =
void Readme::close(write_state *ws) {
	if (ws->file_open) {
		ws->file_open = FALSE;
	}
}
