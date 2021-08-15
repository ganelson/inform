[CInputOutputModel::] C Input-Output Model.

How C programs print text out, really.

@h Setting up the model.

=
void CInputOutputModel::initialise(code_generation_target *cgt) {
}

void CInputOutputModel::initialise_data(code_generation *gen) {
}

void CInputOutputModel::begin(code_generation *gen) {
}

void CInputOutputModel::end(code_generation *gen) {
}

@

=
int CInputOutputModel::compile_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case INVERSION_BIP:	     break; /* we won't support this in C */
		case SPACES_BIP:		 WRITE("for (int j = "); INV_A1; WRITE("; j >= 0; j--) printf(\" \")"); break;
		case FONT_BIP:           WRITE("i7_font("); INV_A1; WRITE(")"); break;
		case STYLEROMAN_BIP:     WRITE("i7_style(i7_roman)"); break;
		case STYLEBOLD_BIP:      WRITE("i7_style(i7_bold)"); break;
		case STYLEUNDERLINE_BIP: WRITE("i7_style(i7_underline)"); break;
		case STYLEREVERSE_BIP:   WRITE("i7_style(i7_reverse)"); break;
		case PRINT_BIP:          WRITE("i7_print_C_string("); INV_A1_PRINTMODE; WRITE(")"); break;
		case PRINTRET_BIP:       WRITE("i7_print_C_string("); INV_A1_PRINTMODE; WRITE("); return 1"); break;
		case PRINTCHAR_BIP:      WRITE("i7_print_char("); INV_A1; WRITE(")"); break;
		case PRINTNAME_BIP:      WRITE("i7_print_name("); INV_A1; WRITE(")"); break;
		case PRINTOBJ_BIP:       WRITE("i7_print_object("); INV_A1; WRITE(")"); break;
		case PRINTPROPERTY_BIP:  WRITE("i7_print_property("); INV_A1; WRITE(")"); break;
		case PRINTNUMBER_BIP:    WRITE("i7_print_decimal("); INV_A1; WRITE(")"); break;
		case PRINTNLNUMBER_BIP:  WRITE("i7_print_number("); INV_A1; WRITE(")"); break;
		case PRINTDEF_BIP:       WRITE("i7_print_def_art("); INV_A1; WRITE(")"); break;
		case PRINTCDEF_BIP:      WRITE("i7_print_cdef_art("); INV_A1; WRITE(")"); break;
		case PRINTINDEF_BIP:     WRITE("i7_print_indef_art("); INV_A1; WRITE(")"); break;
		case PRINTCINDEF_BIP:    WRITE("i7_print_cindef_art("); INV_A1; WRITE(")"); break;
		case BOX_BIP:            WRITE("i7_print_box("); INV_A1_BOXMODE; WRITE(")"); break;
		case READ_BIP:           WRITE("i7_read("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;

		default: 				 return NOT_APPLICABLE;
	}
	return FALSE;
}

@

= (text to inform7_clib.h)
#define i7_bold 1
#define i7_roman 2
#define i7_underline 3
#define i7_reverse 4

void i7_style(int what) {
}

void i7_font(int what) {
}

void i7_print_decimal(i7val x) {
	printf("%d", (int) x);
}

void i7_print_char(i7val x) {
	printf("%c", (int) x);
}

void i7_print_C_string(char *c_string) {
	if (c_string)
		for (int i=0; c_string[i]; i++)
			i7_print_char((i7val) c_string[i]);
}

void i7_print_def_art(i7val x) {
	printf("Unimplemented: i7_print_def_art.\n");
}

void i7_print_cdef_art(i7val x) {
	printf("Unimplemented: i7_print_cdef_art.\n");
}

void i7_print_indef_art(i7val x) {
	printf("Unimplemented: i7_print_indef_art.\n");
}

void i7_print_name(i7val x) {
	printf("Unimplemented: i7_print_name.\n");
}

void i7_print_object(i7val x) {
	printf("Unimplemented: i7_print_object.\n");
}

void i7_print_property(i7val x) {
	printf("Unimplemented: i7_print_property.\n");
}

void i7_print_box(i7val x) {
	printf("Unimplemented: i7_print_box.\n");
}

void i7_read(i7val x) {
	printf("Unimplemented: i7_read.\n");
}
=
