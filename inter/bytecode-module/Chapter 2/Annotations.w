[SymbolAnnotation::] Annotations.

To mark symbols up with metadata.

@h The possible annotations.
Each annotation marks a symbol with a choice of //inter_annotation_form// and
an associated value. That value can be of three possible data types: boolean
(in effect, the annotation is either made or not), integer (the value is an
associated number), or textual (it's a text).

Each annotation has a keyword used in textual Inter code: these by convention
always begin with |__|.

@e BOOLEAN_IATYPE from 1
@e INTEGER_IATYPE
@e TEXTUAL_IATYPE

=
typedef struct inter_annotation_form {
	inter_ti annotation_ID;
	int iatype; /* one of the |*_IATYPE| constants above */
	struct text_stream *annotation_keyword;
	CLASS_DEFINITION
} inter_annotation_form;

@ We need rapid conversion between the annotation ID numbers, which range from
0 upwards, to their corresponding //inter_annotation_form//s.

Note that //SymbolAnnotation::declare// returns |FALSE| if two contradictory
definitions are made for the same ID. This is impossible when creating the
canonical set (see below), but is used to detect errors when binary Inter is
read in which had used an inconsistent set of annotations.

@d MAX_IAFS 64

=
inter_annotation_form *invalid_IAF = NULL;
inter_annotation_form *iafs_registered[MAX_IAFS];
int iafs_registered_initialised = FALSE;

int SymbolAnnotation::declare(inter_ti ID, text_stream *keyword, int iatype) {
	if (iafs_registered_initialised == FALSE) {
		for (int i=0; i<MAX_IAFS; i++) iafs_registered[i] = NULL;
		iafs_registered_initialised = TRUE;
	}
	if (ID >= MAX_IAFS) internal_error("ID out of range");
	if (iafs_registered[ID]) {
		if (Str::eq(keyword, iafs_registered[ID]->annotation_keyword)) return TRUE;
		return FALSE;
	}
	iafs_registered[ID] = CREATE(inter_annotation_form);
	iafs_registered[ID]->annotation_ID = ID;
	iafs_registered[ID]->annotation_keyword = Str::duplicate(keyword);
	iafs_registered[ID]->iatype = iatype;
	if (ID == INVALID_IANN) invalid_IAF = iafs_registered[ID];
	return TRUE;
}

@h Canonical annotations.
The set of annotations used by the Inform tool suite is as follows.

@e INVALID_IANN from 0

@e ASSIMILATED_IANN
@e FAKE_ACTION_IANN
@e OBJECT_IANN
@e PRIVATE_IANN
@e KEEPING_IANN

@e C_ARRAY_ADDRESS_IANN
@e I6_GLOBAL_OFFSET_IANN
@e OBJECT_KIND_COUNTER_IANN

@e APPEND_IANN
@e INNER_PROPERTY_NAME_IANN
@e TRANSLATION_IANN
@e REPLACING_IANN
@e NAMESPACE_IANN

@ The special annotation |__invalid|, with ID |INVALID_IANN|, is never given to
any symbol: it's used to mean "do not make an annotation".

=
void SymbolAnnotation::declare_canonical_annotations(void) {
	SymbolAnnotation::declare(INVALID_IANN,  I"__invalid", INTEGER_IATYPE);

	SymbolAnnotation::declare(ASSIMILATED_IANN,         I"__assimilated",         BOOLEAN_IATYPE);
	SymbolAnnotation::declare(FAKE_ACTION_IANN,         I"__fake_action",         BOOLEAN_IATYPE);
	SymbolAnnotation::declare(OBJECT_IANN,              I"__object",              BOOLEAN_IATYPE);
	SymbolAnnotation::declare(PRIVATE_IANN,             I"__private",             BOOLEAN_IATYPE);
	SymbolAnnotation::declare(KEEPING_IANN,             I"__keeping",             BOOLEAN_IATYPE);

	SymbolAnnotation::declare(APPEND_IANN,              I"__append",              TEXTUAL_IATYPE);
	SymbolAnnotation::declare(INNER_PROPERTY_NAME_IANN, I"__inner_property_name", TEXTUAL_IATYPE);
	SymbolAnnotation::declare(TRANSLATION_IANN,         I"__translation",         TEXTUAL_IATYPE);
	SymbolAnnotation::declare(REPLACING_IANN,           I"__replacing",           TEXTUAL_IATYPE);
	SymbolAnnotation::declare(NAMESPACE_IANN,           I"__my",                  TEXTUAL_IATYPE);

	SymbolAnnotation::declare(C_ARRAY_ADDRESS_IANN,     I"__array_address",       INTEGER_IATYPE);
	SymbolAnnotation::declare(I6_GLOBAL_OFFSET_IANN,    I"__global_offset",       INTEGER_IATYPE);
	SymbolAnnotation::declare(OBJECT_KIND_COUNTER_IANN, I"__object_kind_counter", INTEGER_IATYPE);
}

@ This is printed when //inter// is run with the |-annotations| switch.

=
void SymbolAnnotation::show_annotations(OUTPUT_STREAM) {
	WRITE("  Code     Annotation              Type of value\n");
	for (int ID=0; ID<MAX_IAFS; ID++) {
		inter_annotation_form *IC = iafs_registered[ID];
		if ((IC) && (ID != INVALID_IANN)) {
			WRITE("  %4x     %S", ID, IC->annotation_keyword);
			for (int j = Str::len(IC->annotation_keyword); j<24; j++) PUT(' ');
			switch (IC->iatype) {
				case BOOLEAN_IATYPE: WRITE("none (boolean)\n"); break;
				case INTEGER_IATYPE: WRITE("integer\n"); break;
				case TEXTUAL_IATYPE: WRITE("text\n"); break;
				default: WRITE("unknown type\n"); break;
			}
		}
	}	
}

@h API for making annotations.

=
void SymbolAnnotation::set_b(inter_symbol *S, inter_ti annot_ID, inter_ti n) {
	if ((n != FALSE) && (n != TRUE)) internal_error("non-boolean annotation value");
	inter_annotation IA = SymbolAnnotation::from_pair(annot_ID, n);
	SymbolAnnotation::set(BOOLEAN_IATYPE, S, IA);
}

void SymbolAnnotation::set_i(inter_symbol *S, inter_ti annot_ID, inter_ti n) {
	inter_annotation IA = SymbolAnnotation::from_pair(annot_ID, n);
	SymbolAnnotation::set(INTEGER_IATYPE, S, IA);
}

void SymbolAnnotation::set_t(inter_tree *I, inter_package *owner, inter_symbol *S,
	inter_ti annot_ID, text_stream *text) {
	inter_ti n = InterWarehouse::create_text(InterTree::warehouse(I), owner);
	Str::copy(InterWarehouse::get_text(InterTree::warehouse(I), n), text);
	inter_annotation IA = SymbolAnnotation::from_pair(annot_ID, n);
	SymbolAnnotation::set(TEXTUAL_IATYPE, S, IA);
}

void SymbolAnnotation::set(int iatype, inter_symbol *S, inter_annotation IA) {
	if (S == NULL) internal_error("annotated null symbol");
	if (iatype == -1) iatype = IA.annot->iatype;
	SymbolAnnotation::write_to_set(iatype, &(S->annotations), IA);
}

@h API for reading annotations.
An important convention here is that the default value for a boolean annotation
is |FALSE|, whereas for an integer it is -1.

=
int SymbolAnnotation::get_b(const inter_symbol *S, inter_ti ID) {
	int found = FALSE;
	inter_ti val = SymbolAnnotation::read_from_set(BOOLEAN_IATYPE, &(S->annotations), ID, &found);
	if (found) return (int) val;
	return FALSE;
}

int SymbolAnnotation::get_i(const inter_symbol *S, inter_ti ID) {
	int found = FALSE;
	inter_ti val = SymbolAnnotation::read_from_set(INTEGER_IATYPE, &(S->annotations), ID, &found);
	if (found) return (int) val;
	return -1;
}

text_stream *SymbolAnnotation::get_t(inter_symbol *S, inter_tree *I, inter_ti ID) {
	int found = FALSE;
	inter_ti val = SymbolAnnotation::read_from_set(TEXTUAL_IATYPE, &(S->annotations), ID, &found);
	if (found) return InterWarehouse::get_text(InterTree::warehouse(I), val);
	return NULL;
}

@h Internal representation.
We can express an annotation either with an //inter_annotation// structure or
with a pair of |inter_ti| values:

=
typedef struct inter_annotation {
	struct inter_annotation_form *annot;
	inter_ti annot_value;
} inter_annotation;

inter_annotation SymbolAnnotation::value_annotation(inter_annotation_form *IAF, inter_ti V) {
	inter_annotation IA;
	IA.annot = IAF;
	IA.annot_value = V;
	return IA;
}

inter_annotation SymbolAnnotation::invalid_annotation(void) {
	inter_annotation IA;
	IA.annot = invalid_IAF;
	IA.annot_value = 0;
	return IA;
}

int SymbolAnnotation::is_invalid(inter_annotation IA) {
	if ((IA.annot == NULL) || (IA.annot->annotation_ID == INVALID_IANN)) return TRUE;
	return FALSE;
}

@ Conversions:

=
inter_annotation SymbolAnnotation::from_pair(inter_ti c1, inter_ti c2) {
	if ((iafs_registered_initialised) && (c1 < MAX_IAFS) && (iafs_registered[c1])) {
		inter_annotation IA;
		IA.annot = iafs_registered[c1];
		IA.annot_value = c2;
		return IA;
	}
	return SymbolAnnotation::invalid_annotation();
}

void SymbolAnnotation::to_pair(inter_annotation IA, inter_ti *c1, inter_ti *c2) {
	*c1 = IA.annot->annotation_ID;
	*c2 = IA.annot_value;
}

@ An "annotation set" is what it sounds like: a set (with no meaningful sequence)
containing annotations. Each annotation ID can occur at most once during the set.
A set is initially empty. Each //inter_symbol// has an annotation set, but they
are also used when parsing textual Inter, which is why we don't assume that we
are working on a symbol here.

For efficiency's sake, we store boolean annotation values in a bitmap, and any
others in a linked list whose ordering has no meaning.

=
typedef struct inter_annotation_set {
	int boolean_annotations;
	struct linked_list *other_annotations; /* of |inter_annotation| */
} inter_annotation_set;

inter_annotation_set SymbolAnnotation::new_annotation_set(void) {
	inter_annotation_set set;
	set.boolean_annotations = 0;
	set.other_annotations = NULL;
	return set;
}

int SymbolAnnotation::nonempty(inter_annotation_set *set) {
	if ((set) &&
		((set->boolean_annotations != 0) ||
			(LinkedLists::len(set->other_annotations))))
		return TRUE;
	return FALSE;
}

@ To write an annotation to a set. Note that it is legal to write an annotation
which the set already has: in that case, the new value replaces the old one.
So writing |__arrow_count=12| and then |__arrow_count=7| results in a value of 7.

=
void SymbolAnnotation::write_to_set(int iatype, inter_annotation_set *set, inter_annotation A) {
	if (A.annot->annotation_ID == INVALID_IANN) internal_error("added invalid annotation");
	if (iatype != A.annot->iatype) {
		WRITE_TO(STDERR, "Annotation %S (%d) should have type %d but used %d\n",
			A.annot->annotation_keyword,  A.annot->annotation_ID, A.annot->iatype, iatype);
		internal_error("added annotation with wrong type");
	}
	if (iatype == BOOLEAN_IATYPE) {
		if (A.annot_value) set->boolean_annotations |=   (1 << A.annot->annotation_ID) ;
		              else set->boolean_annotations &= (~(1 << A.annot->annotation_ID));
	} else {
		inter_annotation *NA;
		if (set->other_annotations) {
			LOOP_OVER_LINKED_LIST(NA, inter_annotation, set->other_annotations)
				if (NA->annot == A.annot) {
					NA->annot_value = A.annot_value;
					return;
				}
		} else {
			set->other_annotations = NEW_LINKED_LIST(inter_annotation);
		}
		NA = CREATE(inter_annotation);
		NA->annot = A.annot;
		NA->annot_value = A.annot_value;
		ADD_TO_LINKED_LIST(NA, inter_annotation, set->other_annotations);
	}
}

@ To read an annotation. |found| is set to |TRUE| if the annotation exists for
the set, and |FALSE| otherwise. Note that every set contains all of the boolean
annotations, since they are stored in a bitmap which is always present.

=
inter_ti SymbolAnnotation::read_from_set(int iatype, const inter_annotation_set *set,
	inter_ti ID, int *found) {
	if ((iafs_registered_initialised == FALSE) || (ID >= MAX_IAFS)) {
		*found = FALSE;
		return 0;
	}
	if (iatype != iafs_registered[ID]->iatype) {
		WRITE_TO(STDERR, "Annotation %S (%d) should have type %d but sought %d\n",
			iafs_registered[ID]->annotation_keyword, iafs_registered[ID]->annotation_ID,
			iafs_registered[ID]->iatype, iatype);
		internal_error("sought IAF of wrong type");
	}
	if (set) {
		if (iatype == BOOLEAN_IATYPE) {
			if (set->boolean_annotations & (1 << ID)) { *found = TRUE; return TRUE; }
			else                                      { *found = TRUE; return FALSE; }
		} else {
			if (set->other_annotations) {
				inter_annotation *A;
				LOOP_OVER_LINKED_LIST(A, inter_annotation, set->other_annotations)
					if (A->annot->annotation_ID == ID) {
						*found = TRUE;
						return A->annot_value;
					}
			}
		}
	}
	*found = FALSE;
	return 0;
}

@ After parsing some annotations in textual Inter, and forming a set of those,
we then want to impose these on some new symbol:

=
void SymbolAnnotation::copy_set_to_symbol(inter_annotation_set *set, inter_symbol *S) {
	if (set) {
		S->annotations.boolean_annotations |= set->boolean_annotations;
		if (set->other_annotations) {
			inter_annotation *A;
			LOOP_OVER_LINKED_LIST(A, inter_annotation, set->other_annotations)
				SymbolAnnotation::set(A->annot->iatype, S, *A);
		}
	}
}

@ Annotation sets can be written out as text. Note that booleans are only written
if true, because if false then they are indistinguishable from not being there at all.

=
void SymbolAnnotation::write_annotations(OUTPUT_STREAM, inter_tree_node *F, inter_symbol *S) {
	if (S) SymbolAnnotation::write_set(OUT, &(S->annotations), F);
}

void SymbolAnnotation::write_set(OUTPUT_STREAM, inter_annotation_set *set, inter_tree_node *F) {
	if (set) {
		for (int b=1, c=0; c<30; b *= 2, c++)
			if (set->boolean_annotations & b)
				SymbolAnnotation::write_annotation(OUT, F, SymbolAnnotation::from_pair((inter_ti) c, TRUE));
		if (set->other_annotations) {
			inter_annotation *A;
			LOOP_OVER_LINKED_LIST(A, inter_annotation, set->other_annotations)
				SymbolAnnotation::write_annotation(OUT, F, *A);
		}
	}
}

void SymbolAnnotation::write_annotation(OUTPUT_STREAM, inter_tree_node *F, inter_annotation IA) {
	WRITE(" %S", IA.annot->annotation_keyword);
	switch (IA.annot->iatype) {
		case TEXTUAL_IATYPE:
			WRITE("=");
			TextualInter::write_text(OUT, Inode::ID_to_text(F, IA.annot_value));
			break;
		case INTEGER_IATYPE:
			WRITE("=%d", IA.annot_value);
			break;
		case BOOLEAN_IATYPE:
			break;
	}
}

@ And annotations can also be parsed, with the same syntax:

=
inter_annotation SymbolAnnotation::read_annotation(inter_tree *I, text_stream *text,
	inter_error_location *eloc, inter_error_message **E) {
	inter_ti val = TRUE;
	int iatype = BOOLEAN_IATYPE;
	*E = NULL;
	LOOP_THROUGH_TEXT(P, text)
		if (Str::get(P) == '=') {
			if (Str::get(Str::forward(P)) == '"') {
				TEMPORARY_TEXT(parsed_text)
				inter_error_message *EP = TextualInter::parse_literal_text(parsed_text,
					text, P.index+2, Str::len(text)-2, NULL);
				inter_warehouse *warehouse = InterTree::warehouse(I);
				val = InterWarehouse::create_text(warehouse, InterTree::root_package(I));
				Str::copy(InterWarehouse::get_text(warehouse, val), parsed_text);
				DISCARD_TEXT(parsed_text)
				if (EP) *E = EP;
				iatype = TEXTUAL_IATYPE;
			} else {
				val = (inter_ti) Str::atoi(text, P.index + 1);
				iatype = INTEGER_IATYPE;
			}
			Str::truncate(text, P.index);
		}

	inter_annotation_form *IAF;
	LOOP_OVER(IAF, inter_annotation_form)
		if (Str::eq(text, IAF->annotation_keyword)) {
			if (IAF->iatype != iatype)
				*E = InterErrors::quoted(I"wrong sort of value for annotation",
					IAF->annotation_keyword, eloc);
			inter_annotation IA;
			IA.annot = IAF;
			IA.annot_value = val;
			return IA;
		}
	*E = InterErrors::quoted(I"unrecognised annotation", text, eloc);
	return SymbolAnnotation::invalid_annotation();
}
