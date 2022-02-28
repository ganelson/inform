[InterErrors::] Inter Errors.

To issue error messages arising from loading incorrect Inter code from files.

@ We use the following relatively lightweight structure to represent a position
where an error has occurred, in reading in Inter either from a text or binary file:

=
typedef struct inter_error_location {
	struct text_file_position *error_tfp;
	struct text_stream *error_line;
	struct filename *error_interb;
	size_t error_offset;
} inter_error_location;

@ These two possibilities have two creators. Note that neither of these requires
any memory to be allocated, so they return quickly and cannot cause memory leaks.
So it's no problem to manufacture an //inter_error_location// for each location
in the tree we look at.

=
inter_error_location InterErrors::file_location(text_stream *line, text_file_position *tfp) {
	inter_error_location eloc;
	eloc.error_tfp = tfp;
	eloc.error_line = line;
	eloc.error_interb = NULL;
	eloc.error_offset = 0;
	return eloc;
}

inter_error_location InterErrors::interb_location(filename *F, size_t at) {
	inter_error_location eloc;
	eloc.error_tfp = NULL;
	eloc.error_line = NULL;
	eloc.error_interb = F;
	eloc.error_offset = at;
	return eloc;
}

@ Every actual error message is defined by an instance of the following, which
includes its location. (The point of making these is that errors might be passed
higher up the call stack before being issued, and can be issued in a variety
of ways.)

=
typedef struct inter_error_message {
	struct inter_error_location error_at;
	struct text_stream *error_body;
	struct text_stream *error_quote;
	CLASS_DEFINITION
} inter_error_message;

@ There are just two sorts of message: those quoting some text, and those not.

=
inter_error_message *InterErrors::quoted(text_stream *err, text_stream *quote, inter_error_location *eloc) {
	inter_error_message *iem = InterErrors::plain(err, eloc);
	iem->error_quote = Str::duplicate(quote);
	return iem;
}

inter_error_message *InterErrors::plain(text_stream *err, inter_error_location *eloc) {
	inter_error_message *iem = CREATE(inter_error_message);
	iem->error_body = Str::duplicate(err);
	iem->error_quote = NULL;
	if (eloc) iem->error_at = *eloc;
	return iem;
}

@ The textual form of an error can be output to |STDERR| and also the Inform 7
debugging log at the same time, if there is one:

=
void InterErrors::issue(inter_error_message *iem) {
	if (iem == NULL) internal_error("no error to issue");
	InterErrors::issue_to(STDERR, iem);
	#ifdef CORE_MODULE
	LOG("Inter error:\n");
	InterErrors::issue_to(DL, iem);
	#endif
}

void InterErrors::issue_to(OUTPUT_STREAM, inter_error_message *iem) {
	TEMPORARY_TEXT(E)
	WRITE_TO(E, "%S", iem->error_body);
	if (iem->error_quote)
		WRITE_TO(E, ": '%S'", iem->error_quote);
	inter_error_location eloc = iem->error_at;
	if (eloc.error_interb) {
		WRITE("%f, position %08x: ", eloc.error_interb, eloc.error_offset);
	}
	if (eloc.error_tfp)
		Errors::in_text_file_S(E, eloc.error_tfp);
	else
		Errors::in_text_file_S(E, NULL);
	if (eloc.error_line)
		WRITE(">--> %S\n", eloc.error_line);
	DISCARD_TEXT(E)
}

@ This shows a debugger-like backtrace: this isn't done for every Inter error,
but only in cases where at least a superficially plausible Inter program does
exist. See //InterConstruct::tree_lint//.

=
void InterErrors::backtrace(OUTPUT_STREAM, inter_tree_node *F) {
	inter_tree_node *X = F;
	int n = 0;
	while (TRUE) {
		X = InterTree::parent(X);
		if (X == NULL) break;
		n++;
	}
	for (int i = n; i >= 0; i--) {
		inter_tree_node *X = F;
		int m = 0;
		while (TRUE) {
			inter_tree_node *Y = InterTree::parent(X);
			if (Y == NULL) break;
			if (m == i) {
				if (i == 0) {
					WRITE("%2d. ** ", n);
				} else {
					WRITE("%2d.    ", (n-i));
				}
				InterConstruct::write_construct_text_allowing_nop(OUT, X);
				break;
			}
			X = Y;
			m++;
		}
	}
	LOOP_THROUGH_INTER_CHILDREN(C, F) {
		WRITE("%2d.    ", (n+1));
		InterConstruct::write_construct_text_allowing_nop(OUT, C);
	}
}
