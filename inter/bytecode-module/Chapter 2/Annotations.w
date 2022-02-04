[Inter::Annotations::] Annotations.

To mark symbols up with metadata.

@h Forms.

@e BOOLEAN_IATYPE from 1
@e INTEGER_IATYPE
@e TEXTUAL_IATYPE

@d MAX_IAFS 512

=
typedef struct inter_annotation_form {
	inter_ti annotation_ID;
	int iatype; /* one of the |*_IATYPE| constants above */
	struct text_stream *annotation_keyword;
	CLASS_DEFINITION
} inter_annotation_form;

inter_annotation_form *iafs_registered[MAX_IAFS];
int iafs_registered_initialised = FALSE;

inter_annotation_form *Inter::Annotations::form(inter_ti ID, text_stream *keyword, int iatype) {
	if (iafs_registered_initialised == FALSE) {
		for (int i=0; i<MAX_IAFS; i++)
			iafs_registered[i] = NULL;
		iafs_registered_initialised = TRUE;
	}
	if (ID >= MAX_IAFS) internal_error("ID out of range");
	if (iafs_registered[ID]) {
		if (Str::eq(keyword, iafs_registered[ID]->annotation_keyword))
			return iafs_registered[ID];
		return NULL;
	}
	iafs_registered[ID] = CREATE(inter_annotation_form);
	iafs_registered[ID]->annotation_ID = ID;
	iafs_registered[ID]->annotation_keyword = Str::duplicate(keyword);
	iafs_registered[ID]->iatype = iatype;
	return iafs_registered[ID];
}

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

void Inter::Annotations::add_to_set(int iatype, inter_annotation_set *set, inter_annotation A) {
	if (A.annot == invalid_IAF) internal_error("added invalid annotation");
	if (iatype >= 0) {
		if (iatype != A.annot->iatype) {
			WRITE_TO(STDERR, "Annotation %S (%d) should have type %d but used %d\n",
				A.annot->annotation_keyword, 
				A.annot->annotation_ID,
				A.annot->iatype, iatype);
			internal_error("added annotation with wrong type");
		}
	}
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

void Inter::Annotations::copy_set_to_symbol(inter_annotation_set *set, inter_symbol *S) {
	if (set)
		for (inter_annotation *A = set->anns; A; A = A->next)
			InterSymbol::annotate(A->annot->iatype, S, *A);
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

inter_annotation *Inter::Annotations::find(int iatype, const inter_annotation_set *set, inter_ti ID) {
	if ((iafs_registered_initialised == FALSE) || (ID >= MAX_IAFS)) return NULL;
	if ((iatype >= 0) && (iatype != iafs_registered[ID]->iatype)) {
		WRITE_TO(STDERR, "Annotation %S (%d) should have type %d but sought %d\n",
			iafs_registered[ID]->annotation_keyword, 
			iafs_registered[ID]->annotation_ID,
			iafs_registered[ID]->iatype, iatype);
		internal_error("sought IAF of wrong type");
	}
	if (set)
		for (inter_annotation *A = set->anns; A; A = A->next)
			if (A->annot->annotation_ID == ID)
				return A;
	return NULL;
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
	if ((iafs_registered_initialised) && (c1 < MAX_IAFS) && (iafs_registered[c1])) {
		inter_annotation IA;
		IA.annot = iafs_registered[c1];
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
