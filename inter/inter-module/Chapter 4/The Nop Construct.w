[Inter::Nop::] The Nop Construct.

Defining the nop construct.

@

@e NOP_IST

=
void Inter::Nop::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		NOP_IST, NULL,
		I"nop", I"nops");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES + INSIDE_PLAIN_PACKAGE + INSIDE_CODE_PACKAGE;
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Nop::write);
}

inter_error_message *Inter::Nop::new(inter_reading_state *IRS, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_0(IRS, NOP_IST, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(IRS->current_package, P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Nop::nop_out(inter_repository *I, inter_frame P) {
	P.data[ID_IFLD] = NOP_IST;
	return NULL;
}

void Inter::Nop::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	WRITE("nop");
}
