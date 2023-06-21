[Calculus::Schemas::] Compilation Schemas.

To manage prototype pieces of code for use in code-generation.

@h Schemas.
The calculus module should not in any direct way be involved in code
generation; on the other hand, predicates and quantifiers need eventually to
result in compiled code, and that code will look different for different
predicates. There has to be some way to systematically handle those differences.

Code in the Inform compiler is generated largely from "schemas", which are
small model pieces of code used with variations in different settings. There
are two different data structures for these:

(a) An |i6_schema| uses textual notation based on the syntax of the C-like
language Inform 6; to be used, this must be converted to
(b) An |inter_schema|, which is a partly compiled form of the same, and
has a tree structure closer to the final Inter code.

For inter schemas and how the conversion of (a) to (b) is done, see the
Inform compiler source at //building: Inter Schemas//. If this calculus
module is used outside of Inform, of course, no |inter_schema| will exist.

A simple example of an |i6_schema| might use the notation |*1 == *2|; this
will ultimately compile to a test that two quantities are numerically equal.
As this example shows, |*| is an escape character. See //building: Parsing Inter Schemas//;
|*1| is an example of what is called an "abbreviated command" there.

@ The //i6_schema// structure is very simple, then. Schemas can be of unlimited
length, but we want to be able to create and dispose of them quickly and to
avoid unnecessary stream memory claims. So each |i6_schema| structure contains
a fixed block of storage for the first few characters. (In fact, long ones are
never needed in practice, but we must avoid any risk of buffer overrun for safety.)

@d TYPICAL_I6_SCHEMA_LENGTH 128 /* in practice 40 is plenty */

=
typedef struct i6_schema {
	wchar_t prototype_storage[TYPICAL_I6_SCHEMA_LENGTH]; /* used just to make space for... */
	struct text_stream prototype; /* ...this */
	int no_quoted_inames;
	#ifdef CORE_MODULE
	struct inter_schema *compiled;
	struct inter_name *quoted_inames[2];
	#endif
} i6_schema;

@h Annotated schemas.
It is sometimes convenient to carry around a schema together with calculus
terms for what will go into |*1| and |*2| when it is expanded, and with a
few other contextual details. 

=
typedef struct annotated_i6_schema {
	struct i6_schema *schema;
	int negate_schema; /* true if atom is to be tested with the opposite parity */
	struct pcalc_term pt0; /* terms on which the I6 schema is to be expanded */
	struct pcalc_term pt1;
	int involves_action_variables;
} annotated_i6_schema;

@ And here it is, before being annotated...

=
annotated_i6_schema Calculus::Schemas::blank_asch(void) {
	annotated_i6_schema asch;
	asch.schema = Calculus::Schemas::new(" ");
	asch.negate_schema = FALSE;
	asch.pt0 = Terms::new_variable(0);
	asch.pt1 = Terms::new_variable(0);
	asch.involves_action_variables = FALSE;
	return asch;
}

@h Building schemas.
When schemas are generated inside Inform, they often look as if they have an
even more elaborate syntax, with escapes like |%s| in them. But this is because
they are generated with the following |printf|-style function. Those |%| escapes
are expanded now, when the schema is created, and not later when code is generated
from it. For example, the function call:
= (text as InC)
Calculus::Schemas::new("*1.%n = *2.%n", X, Y)
=
might produce a schema whose |prototype| text came out as
= (text)
*1.x100 = *2.y62
=
...supposing that |x100| and |y62| were the Inter identifiers for whatever was
referred to by the |inter_name| values |X| and |Y| supplied in the arguments.
Here then is that |printf|-like function:

=
int unique_qi_counter = 0; /* quoted iname count */

i6_schema *Calculus::Schemas::new(char *fmt, ...) {
	va_list ap; /* the variable argument list signified by the dots */
	i6_schema *sch = CREATE(i6_schema);
	sch->prototype = Streams::new_buffer(TYPICAL_I6_SCHEMA_LENGTH, sch->prototype_storage);
	sch->no_quoted_inames = 0;
	text_stream *OUT = &(sch->prototype);
	@<Process the varargs into schema prototype text@>;
	va_end(ap); /* macro to end variable argument processing */
	#ifdef CORE_MODULE
	sch->compiled = ParsingSchemas::from_i6s(&(sch->prototype),
		sch->no_quoted_inames, (void **) sch->quoted_inames);
	#endif
	return sch;
}

@ And this is a variation for modifying an existing schema:

=
void Calculus::Schemas::modify(i6_schema *sch, char *fmt, ...) {
	va_list ap; /* the variable argument list signified by the dots */
	sch->prototype = Streams::new_buffer(TYPICAL_I6_SCHEMA_LENGTH, sch->prototype_storage);
	sch->no_quoted_inames = 0;
	text_stream *OUT = &(sch->prototype);
	@<Process the varargs into schema prototype text@>;
	va_end(ap); /* macro to end variable argument processing */
	#ifdef CORE_MODULE
	sch->compiled = ParsingSchemas::from_i6s(&(sch->prototype),
		sch->no_quoted_inames, (void **) sch->quoted_inames);
	#endif
}

@ And another:

=
void Calculus::Schemas::append(i6_schema *sch, char *fmt, ...) {
	va_list ap; /* the variable argument list signified by the dots */
	text_stream *OUT = &(sch->prototype);
	@<Process the varargs into schema prototype text@>;
	va_end(ap); /* macro to end variable argument processing */
	#ifdef CORE_MODULE
	sch->compiled = ParsingSchemas::from_i6s(&(sch->prototype),
		sch->no_quoted_inames, (void **) sch->quoted_inames);
	#endif
}

@ Either way, the schema's prototype is written as follows:

@<Process the varargs into schema prototype text@> =
	char *p;
	va_start(ap, fmt); /* macro to begin variable argument processing */
	for (p = fmt; *p; p++) {
		switch (*p) {
			case '%': @<Recognise schema-format escape sequences@>; break;
			default: PUT(*p); break;
		}
	}

@ We recognise only a few escapes here: |%%|, a literal percentage sign; |%d|,
an integer; |%s|, a C string; |%S|, a text stream; and three which are higher-level:
(a) |%k| takes a |kind| parameter and expands to its weak ID;
(b) |%L| takes a |local_variable| and expands to its identifier;
(c) |%n| takes an |inter_name|, which expands more cautiously in a way which
stores the actual |inter_name| reference: it is possible for two different
global values to have different |inter_name|s but the same identifier text,
so it would not be safe to store only the textual identifier.

@<Recognise schema-format escape sequences@> =
	p++;
	switch (*p) {
		case 'd': WRITE("%d", va_arg(ap, int)); break;
		case 'k':
			#ifdef CORE_MODULE
			RTKindIDs::write_weak_identifier(OUT, va_arg(ap, kind *));
			#endif
			break;
		case 'L':
			#ifdef CORE_MODULE
			WRITE("%~L", va_arg(ap, local_variable *)); break;
			#endif
			break;
		case 'n': {
			int N = sch->no_quoted_inames++;
			if (N >= 2) internal_error("too many inter_name quotes");
			#ifdef CORE_MODULE
			sch->quoted_inames[N] = (inter_name *) va_arg(ap, inter_name *);
			#endif
			WRITE("QUOTED_INAME_%d_%08x", N, unique_qi_counter++);
			break;
		}
		case 'N': WRITE("%N", va_arg(ap, int)); break;
		case 's': WRITE("%s", va_arg(ap, char *)); break;
		case 'S': WRITE("%S", va_arg(ap, text_stream *)); break;
		case '%': PUT('%'); break;
		default:
			fprintf(stderr, "*** Bad schema format: <%s> ***\n", fmt);
			internal_error("Unknown % string escape in schema format");
	}

@h Emptiness.
A schema is empty if its prototype is the empty text.

=
int Calculus::Schemas::empty(i6_schema *sch) {
	if (sch == NULL) return TRUE;
	if (Str::len(&(sch->prototype)) == 0) return TRUE;
	return FALSE;
}

@h Logging schemas.
The fact that I6 schemas are not much more than string makes them easy to log:

=
void Calculus::Schemas::log(i6_schema *sch) {
	Calculus::Schemas::write(DL, sch);
}

void Calculus::Schemas::write(OUTPUT_STREAM, i6_schema *sch) {
	if (sch == NULL) WRITE("<null schema>");
	else WRITE("<schema: %S>", &(sch->prototype));
}

void Calculus::Schemas::log_applied(i6_schema *sch, pcalc_term *pt1) {
	Calculus::Schemas::write_applied(DL, sch, pt1);
}

void Calculus::Schemas::write_applied(OUTPUT_STREAM, i6_schema *sch, pcalc_term *pt1) {
	if (sch == NULL) { WRITE("<null schema>"); return; }
	else {
		WRITE("<%S : ", &(sch->prototype));
		Terms::write(OUT, pt1);
		WRITE(">");
	}
}
