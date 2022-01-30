[InterNames::] Inter Namespace.

To manage references to Inter symbols which may or may not yet exist.

@h Introduction.
See //What This Module Does// for a fuller explanation, but briefly, an
//inter_name// or "iname" represents a symbol which will eventually exist,
but which may not exist at the moment -- indeed, may be placed inside a
package which also does not yet exist.

//inform7// and other code-generation tools can make many such inames, living
in equally shadowy //package_request//s, before any actual Inter is made at all.
Eventually, though, such tools usually make good on their promises and "incarnate"
their inames into actual |inter_symbol|s within actual |inter_package|s.

@h Generators.
Each inter name comes from a "generator". Some are one-shot, and produce just
one name before being discarded; others produce a numbered sequence of names
in a given pattern, counting upwards from 1 (|example_1|, |example_2|, ...);
and others still derive new names from existing ones (for example, turning
|fish| and |rumour| into |fishmonger| and |rumourmonger|).

@e UNIQUE_INGEN from 1
@e MULTIPLE_INGEN
@e DERIVED_INGEN

=
typedef struct inter_name_generator {
	int ingen;
	struct text_stream *name_stem;
	int no_generated; /* relevamt only for |MULTIPLE_INGEN| */
	struct text_stream *derived_prefix; /* relevamt only for |DERIVED_INGEN| */
	struct text_stream *derived_suffix; /* relevamt only for |DERIVED_INGEN| */
} inter_name_generator;

inter_name_generator *InterNames::single_use_generator(text_stream *name) {
	inter_name_generator *F = CREATE(inter_name_generator);
	F->ingen = UNIQUE_INGEN;
	F->name_stem = Str::duplicate(name);
	F->derived_prefix = NULL;
	return F;
}

inter_name_generator *InterNames::multiple_use_generator(text_stream *prefix,
	text_stream *stem, text_stream *suffix) {
	inter_name_generator *gen = InterNames::single_use_generator(stem);
	if (Str::len(prefix) > 0) {
		gen->ingen = DERIVED_INGEN;
		gen->derived_prefix = Str::duplicate(prefix);
	} else if (Str::len(suffix) > 0) {
		gen->ingen = DERIVED_INGEN;
		gen->derived_suffix = Str::duplicate(suffix);
	} else gen->ingen = MULTIPLE_INGEN;
	return gen;
}

@h Printing inames.
Inter names are stored not in textual form, but in terms of what would be
required to generate that text. (The memo field, which in principle allows
any text to be stored, is used only for a small proportion of inames.)

=
typedef struct inter_name {
	struct inter_name_generator *generated_by;
	int unique_number;
	struct inter_symbol *symbol;
	struct package_request *location_in_hierarchy;
	struct text_stream *memo;
	struct inter_name *derived_from;
} inter_name;

@ This implements the |%n| escape, which prints an iname:

=
void InterNames::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_name *iname = (inter_name *) vI;
	if (iname == NULL) WRITE("<no-inter-name>");
	else {
		if (iname->generated_by == NULL) internal_error("bad inter_name");
		switch (iname->generated_by->ingen) {
			case DERIVED_INGEN:
				WRITE("%S", iname->generated_by->derived_prefix);
				InterNames::writer(OUT, format_string, iname->derived_from);
				WRITE("%S", iname->generated_by->derived_suffix);
				break;
			case UNIQUE_INGEN:
				WRITE("%S", iname->generated_by->name_stem);
				break;
			case MULTIPLE_INGEN:
				WRITE("%S", iname->generated_by->name_stem);
				if (iname->unique_number >= 0) WRITE("%d", iname->unique_number);
				break;
			default: internal_error("unknown ingen");
		}
		if (Str::len(iname->memo) > 0) WRITE("_%S", iname->memo);
	}
}

@h Making new inames.
We can now make a new iname, which is easy unless there's a memo to attach.
For example, attaching the wording "printing the name of a dark room" to
an iname which would otherwise just be |V12| produces |V12_printing_the_name_of_a_da|.
Memos exist largely to make the Inter code easier for human eyes to read,
as in this case, but sometimes, as with kind names like |K2_thing|, they're
needed because template or explicit I6 inclusion code makes references to them.

Although most inter names are eventually used to create symbols in the
Inter hierarchy's symbols table, this does not happen immediately, and
for some inames it never will.

=
inter_name *InterNames::new(inter_name_generator *F, package_request *R, wording W) {
	inter_name *iname = CREATE(inter_name);
	iname->generated_by = F;
	iname->unique_number = 0;
	iname->symbol = NULL;
	iname->derived_from = NULL;
	iname->location_in_hierarchy = R;
	if (Wordings::empty(W)) {
		iname->memo = NULL;
	} else {
		iname->memo = Str::new();
		@<Fill the memo with up to 28 characters of text from the given wording@>;
		@<Ensure that the name, as now extended by the memo, is a legal Inter identifier@>;
	}
	return iname;
}

@<Fill the memo with up to 28 characters of text from the given wording@> =
	int c = 0;
	LOOP_THROUGH_WORDING(j, W) {
		/* identifier is at this point 32 chars or fewer in length: add at most 30 more */
		if (c++ > 0) WRITE_TO(iname->memo, " ");
		if (Wide::len(Lexer::word_text(j)) > 30)
			WRITE_TO(iname->memo, "etc");
		else WRITE_TO(iname->memo, "%N", j);
		if (Str::len(iname->memo) > 32) break;
	}
	Str::truncate(iname->memo, 28); /* it was at worst 62 chars in size, but is now truncated to 28 */

@<Ensure that the name, as now extended by the memo, is a legal Inter identifier@> =
	Identifiers::purify(iname->memo);
	TEMPORARY_TEXT(NBUFF)
	WRITE_TO(NBUFF, "%n", iname);
	int L = Str::len(NBUFF);
	DISCARD_TEXT(NBUFF)
	if (L > 28) Str::truncate(iname->memo, Str::len(iname->memo) - (L - 28));

@ That creation function should be called only by these, which in turn must
be called only from within the current chapter. First, the single-shot cases,
where the caller wants a single name with fixed wording (but possibly with
a memo to attach):

=
inter_name *InterNames::explicitly_named_with_memo(text_stream *name, package_request *R,
	wording W) {
	return InterNames::new(InterNames::single_use_generator(name), R, W);
}

inter_name *InterNames::explicitly_named(text_stream *name, package_request *R) {
	return InterNames::explicitly_named_with_memo(name, R, EMPTY_WORDING);
}

inter_name *InterNames::explicitly_named_plug(inter_tree *I, text_stream *name) {
	inter_name *iname = InterNames::explicitly_named(name, LargeScale::connectors_request(I));
	inter_symbol *plug = Wiring::find_plug(I, name);
	if (plug == NULL) plug = Wiring::plug(I, name);
	iname->symbol = plug;
	return iname;
}

@ Second, the generated or derived cases:

=
inter_name *InterNames::multiple(inter_name_generator *G, package_request *R, wording W) {
	if (G == NULL) internal_error("no generator");
	if (G->ingen == UNIQUE_INGEN) internal_error("not a generator name");
	inter_name *iname = InterNames::new(G, R, W);
	if (G->ingen != DERIVED_INGEN) iname->unique_number = ++G->no_generated;
	return iname;
}

inter_name *InterNames::generated_in(inter_name_generator *G, int fix, wording W,
	package_request *R) {
	inter_name *iname = InterNames::multiple(G, R, W);
	if (fix != -1) iname->unique_number = fix;
	return iname;
}

inter_name *InterNames::generated(inter_name_generator *G, int fix, wording W) {
	return InterNames::generated_in(G, fix, W, NULL);
}

inter_name *InterNames::derived(inter_name_generator *G, inter_name *from, wording W) {
	if (G->ingen != DERIVED_INGEN) internal_error("not a derived generator");
	inter_name *iname = InterNames::multiple(G, from->location_in_hierarchy, W);
	iname->derived_from = from;
	return iname;
}

@ Now that inames have been created, we allow their locations to be read:

=
package_request *InterNames::location(inter_name *iname) {
	if (iname == NULL) return NULL;
	return iname->location_in_hierarchy;
}

inter_symbols_table *InterNames::scope(inter_name *iname) {
	if (iname == NULL) internal_error("can't determine scope of null name");
	package_request *P = InterNames::location(iname);
	if (P == NULL) internal_error("can't determine scope of unlocated name");
	return InterPackage::scope(Packaging::incarnate(P));
}

@h Incarnation of inames to symbols.
Incarnation matches up an //inter_name// with its corresponding |inter_symbol|,
and is performed on demand. This leaves it as late as possible, and means that
inames which are never needed are never incarnated.

=
inter_symbol *InterNames::to_symbol(inter_name *iname) {
	if (iname->symbol == NULL) {
		TEMPORARY_TEXT(identifier)
		WRITE_TO(identifier, "%n", iname);
		inter_symbols_table *T = InterNames::scope(iname);
		iname->symbol = InterSymbolsTables::create_with_unique_name(T, identifier);
		DISCARD_TEXT(identifier)
	}
	return iname->symbol;
}

text_stream *InterNames::to_text(inter_name *iname) {
	if (iname == NULL) return NULL;
	return InterNames::to_symbol(iname)->symbol_name;
}

@h Definition.
An iname is defined if its symbol has a definition. Note that incarnating
an iname creates a symbol which is initially undefined, so this test is not the
same as testing whether the iname has been incarnated.

=
int InterNames::is_defined(inter_name *iname) {
	if (iname == NULL) return FALSE;
	inter_symbol *S = InterNames::to_symbol(iname);
	if (Inter::Symbols::is_defined(S)) return TRUE;
	return FALSE;
}

inter_symbol *InterNames::define(inter_name *iname) {
	inter_symbol *S = InterNames::to_symbol(iname);
	if ((S) && (Inter::Symbols::is_predeclared(S))) Inter::Symbols::undefine(S);
	return S;
}

@h Annotation.
Note that these functions all force an iname to be incarnated.

=
void InterNames::annotate_i(inter_name *iname, inter_ti annot_ID, inter_ti V) {
	Inter::Symbols::annotate_i(InterNames::to_symbol(iname), annot_ID, V);
}

void InterNames::annotate_w(inter_name *iname, inter_ti annot_ID, wording W) {
	inter_symbol *S = InterNames::to_symbol(iname);
	TEMPORARY_TEXT(temp)
	WRITE_TO(temp, "%W", W);
	Inter::Symbols::annotate_t(InterPackage::tree(S->owning_table->owning_package),
		S->owning_table->owning_package, S, annot_ID, temp);
	DISCARD_TEXT(temp)
}

int InterNames::read_annotation(inter_name *iname, inter_ti annot) {
	inter_symbol *S = InterNames::to_symbol(iname);
	return Inter::Symbols::read_annotation(S, annot);
}

void InterNames::set_flag(inter_name *iname, int f) {
	Inter::Symbols::set_flag(InterNames::to_symbol(iname), f);
}

void InterNames::clear_flag(inter_name *iname, int f) {
	Inter::Symbols::clear_flag(InterNames::to_symbol(iname), f);
}

void InterNames::set_translation(inter_name *iname, text_stream *new_text) {
	Inter::Symbols::set_translate(InterNames::to_symbol(iname), new_text);
}

text_stream *InterNames::get_translation(inter_name *iname) {
	return Inter::Symbols::get_translate(InterNames::to_symbol(iname));
}
