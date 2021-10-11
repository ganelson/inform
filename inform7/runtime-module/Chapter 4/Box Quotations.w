[BoxQuotations::] Box Quotations.

In this section we compile text constants.

@ It's a little strange to be writing, in 2012, code to handle an
idiosyncratic one-off form of text called a "quotation", just to match an
idiosyncratic feature of Inform 1 from 1993 which was in turn matching an
idiosyncratic feature of version 4 of the Z-machine from 1985 which, in turn,
existed only to serve the needs of an unusual single work of IF called
"Trinity". But here we are.

=
typedef struct box_quotation {
	struct inter_name *function_iname;
	struct inter_name *seen_flag_iname;
	struct text_stream *content;
	int function_compiled;
	CLASS_DEFINITION
} box_quotation;

void BoxQuotations::new(value_holster *VH, wording W) {
	box_quotation *bq = CREATE(box_quotation);
	bq->function_iname = Enclosures::new_iname(BOX_QUOTATIONS_HAP, BOX_QUOTATION_FN_HL);
	bq->seen_flag_iname = Enclosures::new_iname(BOX_QUOTATIONS_HAP, BOX_FLAG_HL);
	bq->function_compiled = FALSE;
	bq->content = Str::new();
	TranscodeText::bq_from_wide_string(bq->content, Lexer::word_text(Wordings::first_wn(W)));
	if (Str::len(bq->content) == 0)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EmptyQuotationBox),
			"a boxed quotation can't be empty",
			"though I suppose you could make it consist of just a few spaces "
			"to get a similar effect if you really needed to.");
	text_stream *desc = Str::new();
	WRITE_TO(desc, "box quotation '%W'", W);
	Sequence::queue(&BoxQuotations::compilation_agent, STORE_POINTER_box_quotation(bq), desc);
	if (VH) Emit::holster_iname(VH, bq->function_iname);
}

@ The box functions are then compiled in due course by the following agent
(see //core: How To Compile//). The reason they weren't simply compiled earlier
is that a function was already being compiled at the time, and you can't
compile two functions at the same time.

The "box function", which displays the quotation, roughly translates to:
= (text)
	if (flag == false) {
		flag = true;
		box "The quotation here.";
	}
=
and ensures that the quotation displays only once. The flag is stored as a
tiny array inside the same enclosure as the box function.

=
void BoxQuotations::compilation_agent(compilation_subtask *t) {
	box_quotation *bq = RETRIEVE_POINTER_box_quotation(t->data);
	packaging_state save = EmitArrays::begin_word(bq->seen_flag_iname, K_number);
	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);

	save = Functions::begin(bq->function_iname);
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, bq->seen_flag_iname);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::reference();
				EmitCode::down();
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, bq->seen_flag_iname);
						EmitCode::val_number(0);
					EmitCode::up();
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
			EmitCode::inv(BOX_BIP);
			EmitCode::down();
				EmitCode::val_text(bq->content);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	
	Functions::end(save);
}
