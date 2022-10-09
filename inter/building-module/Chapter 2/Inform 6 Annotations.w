[I6Annotations::] Inform 6 Annotations.

Parsing Inform 6-syntax annotation markers.

@ Annotations are parsed into the following:

=
typedef struct I6_annotation {
	struct text_stream *identifier;
	struct linked_list *terms; /* of |I6_annotation_term| */
	struct I6_annotation *next;
	CLASS_DEFINITION
} I6_annotation;

typedef struct I6_annotation_term {
	struct text_stream *key;
	struct text_stream *value;
	CLASS_DEFINITION
} I6_annotation_term;

@ =
I6_annotation *I6Annotations::new(void) {
	I6_annotation *IA = CREATE(I6_annotation);
	IA->identifier = Str::new();
	IA->terms = NULL;
	IA->next = NULL;
	return IA;
}

@ Purely syntactic parsing is done with two calls. To see these exercised, try
the |building-test| test case |annotations|.

|I6Annotations::check| returns a character position |i| (counting from 0 at
the start of the text) if it can find a syntactically valid set of annotations
before |i|. Note that this can be the empty set. We return -1 if a purported
annotation appears (i.e., because the first non-whitespace character is |+|)
but what follows is not syntactically valid according to the rules in IE-0006.

Note that we only check syntax, not semantics: all kinds of unknown annotations
would pass this, provided they were properly punctuated.

=
int I6Annotations::check(text_stream *A) {
	return I6Annotations::unpack(A, NULL, TRUE);
}

@ |I6Annotations::parse(A)| parses a complete annotation, including its opening
|+| sign but with no junk at the end, into an |I6_annotation|. It returns |NULL|
if a syntax error is reached.

=
I6_annotation *I6Annotations::parse(text_stream *A) {
	I6_annotation *IA = I6Annotations::new();
	if (I6Annotations::unpack(A, IA, FALSE) == -1) return NULL;
	return IA;
}

@ Both use the same simple finite-state-machine parser.

@d NONPLUSSED_I6ASTATE 0    /* waiting for the |+| sign */
@d BEFORE_I6ASTATE 1        /* after the |+| sign, waiting for the identifier */
@d NAME_I6ASTATE 2          /* inside the identifier */
@d AFTER_I6ASTATE 3         /* after the identifier, waiting for another |+| or bracketed data */
@d QUOTED_I6ASTATE 4        /* inside quoted matter */

=
int I6Annotations::unpack(text_stream *A, I6_annotation *IA, int allow_tail) {
	int malformed = FALSE, state = NONPLUSSED_I6ASTATE;
	int i = 0, name_length = 0;
	for (; i<Str::len(A); i++) {
		wchar_t c = Str::get_at(A, i);
		if (Characters::is_whitespace(c)) {
			if (state == BEFORE_I6ASTATE) malformed = TRUE;
			if (state == NAME_I6ASTATE) state = AFTER_I6ASTATE;
		} else if (c == '+') {
			if (state == NONPLUSSED_I6ASTATE) state = BEFORE_I6ASTATE;
			else if (state == BEFORE_I6ASTATE) malformed = TRUE;
			else if (IA) {
				IA->next = I6Annotations::new();
				IA = IA->next;
			}
			state = BEFORE_I6ASTATE;
			name_length = 0;
		} else if (c == '(') {
			if ((state != NAME_I6ASTATE) && (state != AFTER_I6ASTATE)) malformed = TRUE;
			state = AFTER_I6ASTATE;
			int bl = 1; i++;
			TEMPORARY_TEXT(term)
			while (i<Str::len(A)) {
				wchar_t d = Str::get_at(A, i);
				if (state == QUOTED_I6ASTATE) {
					if (d == '\\') {
						i++; d = Str::get_at(A, i);
					} else if (d == '\'') {
						wchar_t n = Str::get_at(A, i+1);
						if ((Characters::is_whitespace(n) == FALSE) && (n != ',') && (n != ')'))
							malformed = TRUE;
						state = AFTER_I6ASTATE; i++; continue;
					}
					PUT_TO(term, d);
				} else {
					if (d == '\'') {
						wchar_t p = Str::get_at(A, i-1);
						if ((Characters::is_whitespace(p) == FALSE) && (p != ',') && (p != '('))
							malformed = TRUE;
						state = QUOTED_I6ASTATE; i++; continue;
					}
					if (d == '(') bl++;
					if (d == ')') bl--;
					if ((bl == 1) && (d == ',')) @<Parse term@>
					else if (bl > 0) PUT_TO(term, d);
				}
				if (bl == 0) { @<Parse term@>; break; }
				i++;
			}
			if (state == QUOTED_I6ASTATE) malformed = TRUE;
			if (bl != 0) malformed = TRUE;
			DISCARD_TEXT(term)
		} else {
			if (state == NONPLUSSED_I6ASTATE) break;
			if (state == AFTER_I6ASTATE) break;
			state = NAME_I6ASTATE;
			if (name_length++ == 0) {
				if ((c != '_') && (Characters::isalpha(c) == FALSE)) malformed = TRUE;
			} else {
				if ((c != '_') && (Characters::isalnum(c) == FALSE)) malformed = TRUE;
			}
			if (IA) PUT_TO(IA->identifier, c);
		}
	}
	if (malformed) return -1;
	while (Characters::is_whitespace(Str::get_at(A, i))) i++;
	if ((allow_tail == FALSE) && (Str::get_at(A, i))) return -1;
	if ((allow_tail == FALSE) && (state == NONPLUSSED_I6ASTATE)) return -1;
	return i;
}

@<Parse term@> =
	if (Str::len(term) > 0) {
		text_stream *K = Str::new();
		text_stream *V = Str::new();
		if (IA) {
			I6_annotation_term *term = CREATE(I6_annotation_term);
			if (IA->terms == NULL) IA->terms = NEW_LINKED_LIST(I6_annotation_term);
			ADD_TO_LINKED_LIST(term, I6_annotation_term, IA->terms);
			term->key = K;
			term->value = V;
		}
		for (int k=0, in_key=TRUE; k<Str::len(term); k++) {
			wchar_t c = Str::get_at(term, k);
			if (Characters::is_whitespace(c)) {
				if (in_key) {
					if (Str::len(K) == 0) continue;
					in_key = FALSE;
				}
				if (Str::len(V) == 0) continue;
			} else if (Characters::isalnum(c) == FALSE) {
				in_key = FALSE;
			}
			if (in_key) PUT_TO(K, c);
			else PUT_TO(V, c);
		}
		Str::clear(term);
		if (Str::len(K) == 0) malformed = TRUE;
		if (Str::len(V) == 0) {
			WRITE_TO(V, "%S", K);
			Str::clear(K);
			WRITE_TO(K, "_");
		}
		for (int k=0; k<Str::len(K); k++) {
			wchar_t c = Str::get_at(K, k);
			if (k == 0) {
				if ((c != '_') && (Characters::isalpha(c) == FALSE)) malformed = TRUE;
			} else {
				if ((c != '_') && (Characters::isalnum(c) == FALSE)) malformed = TRUE;
			}
		}
	}
