[Inter::Annotations::] Annotations.

To mark symbols up with metadata.

@h Forms.

=
typedef struct inter_annotation_form {
	inter_ti annotation_ID;
	int textual_flag;
	struct text_stream *annotation_keyword;
	CLASS_DEFINITION
} inter_annotation_form;

typedef struct inter_annotation {
	struct inter_annotation_form *annot;
	inter_ti annot_value;
	struct inter_annotation *next;
} inter_annotation;

typedef struct inter_annotation_set {
	struct inter_annotation *anns;
} inter_annotation_set;

inter_annotation_form *invalid_IAF = NULL;
inter_annotation_form *name_IAF = NULL;
inter_annotation_form *inner_pname_IAF = NULL;

@ =
inter_annotation_set Inter::Annotations::new_set(void) {
	inter_annotation_set set;
	set.anns = NULL;
	return set;
}

void Inter::Annotations::add_to_set(inter_annotation_set *set, inter_annotation A) {
	inter_annotation *NA = CREATE(inter_annotation);
	NA->annot = A.annot;
	NA->annot_value = A.annot_value;
	NA->next = NULL;
	inter_annotation *L = set->anns;
	if (L) {
		while ((L) && (L->next)) L = L->next;
		L->next = NA;
	} else {
		set->anns = NA;
	}
}

void Inter::Annotations::remove_from_set(inter_annotation_set *set, inter_ti annot_ID) {
	if (set) {
		inter_annotation *prev = NULL;
		for (inter_annotation *L = set->anns; L; L = L->next) {
			if (L->annot->annotation_ID == annot_ID) {
				if (prev) prev->next = L->next;
				else set->anns = L->next;
				break;
			}
			prev = L;
		}
	}
}

void Inter::Annotations::copy_set_to_symbol(inter_annotation_set *set, inter_symbol *S) {
	if (set)
		for (inter_annotation *A = set->anns; A; A = A->next)
			InterSymbol::annotate(S, *A);
}

void Inter::Annotations::transpose_set(inter_annotation_set *set, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	for (inter_annotation *A = set->anns; A; A = A->next)
		Inter::Defn::transpose_annotation(A, grid, grid_extent, E);
}

void Inter::Annotations::write_set(OUTPUT_STREAM, inter_annotation_set *set, inter_tree_node *F) {
	for (inter_annotation *A = set->anns; A; A = A->next)
		Inter::Defn::write_annotation(OUT, F, *A);
}

int Inter::Annotations::exist(inter_annotation_set *set) {
	if ((set) && (set->anns)) return TRUE;
	return FALSE;
}

inter_annotation *Inter::Annotations::find(const inter_annotation_set *set, inter_ti ID) {
	if (set)
		for (inter_annotation *A = set->anns; A; A = A->next)
			if (A->annot->annotation_ID == ID)
				return A;
	return NULL;
}

inter_annotation_form *Inter::Annotations::form(inter_ti ID, text_stream *keyword, int textual) {
	inter_annotation_form *IAF;
	LOOP_OVER(IAF, inter_annotation_form)
		if (Str::eq(keyword, IAF->annotation_keyword)) {
			if (IAF->annotation_ID == ID)
				return IAF;
			else
				return NULL;
		}

	IAF = CREATE(inter_annotation_form);
	IAF->annotation_ID = ID;
	IAF->annotation_keyword = Str::duplicate(keyword);
	IAF->textual_flag = textual;
	return IAF;
}

inter_annotation Inter::Annotations::invalid_annotation(void) {
	inter_annotation IA;
	IA.annot = invalid_IAF;
	IA.annot_value = 0;
	return IA;
}

inter_annotation Inter::Annotations::value_annotation(inter_annotation_form *IAF, inter_ti V) {
	inter_annotation IA;
	IA.annot = IAF;
	IA.annot_value = V;
	return IA;
}

int Inter::Annotations::is_invalid(inter_annotation IA) {
	if ((IA.annot == NULL) || (IA.annot->annotation_ID == INVALID_IANN)) return TRUE;
	return FALSE;
}
inter_annotation Inter::Annotations::from_bytecode(inter_ti c1, inter_ti c2) {
	inter_annotation_form *IAF;
	LOOP_OVER(IAF, inter_annotation_form)
		if (c1 == IAF->annotation_ID) {
			inter_annotation IA;
			IA.annot = IAF;
			IA.annot_value = c2;
			return IA;
		}
	return Inter::Annotations::invalid_annotation();
}

void Inter::Annotations::set_to_bytecode(FILE *fh, inter_annotation_set *set) {
	unsigned int c = 0;
	for (inter_annotation *A = set->anns; A; A = A->next) c++;
	BinaryFiles::write_int32(fh, c);
	for (inter_annotation *A = set->anns; A; A = A->next) {
		inter_ti c1 = 0, c2 = 0;
		Inter::Annotations::to_bytecode(*A, &c1, &c2);
		BinaryFiles::write_int32(fh, (unsigned int) c1);
		BinaryFiles::write_int32(fh, (unsigned int) c2);
	}
}

void Inter::Annotations::to_bytecode(inter_annotation IA, inter_ti *c1, inter_ti *c2) {
	*c1 = IA.annot->annotation_ID;
	*c2 = IA.annot_value;
}
