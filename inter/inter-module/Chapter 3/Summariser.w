[Inter::Summary::] Summariser.

Printing a summary of the contents of a repository.

@ =
void Inter::Summary::write(OUTPUT_STREAM, inter_repository *I) {
	if (I == NULL) internal_error("no repository");
	Inter::Summary::write_r(OUT, I, NULL, 0);
	if (I) Inter::Summary::write_r(OUT, I, Inter::Packages::main(I), 0);
}

void Inter::Summary::write_r(OUTPUT_STREAM, inter_repository *I, inter_package *pack, int L) {
	if (pack) {
		if (pack->codelike_package) return;
		for (int j=0; j<L; j++) WRITE("  ");
		WRITE("%S %S\n", pack->package_name->symbol_name, Inter::Packages::type(pack)->symbol_name);
		L++;
	}
	int counts[MAX_INTER_CONSTRUCTS];
	for (int i=0; i<MAX_INTER_CONSTRUCTS; i++) counts[i] = 0;
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I)
		if (Inter::Packages::container(P) == pack) {
			int what = (int) P.data[ID_IFLD];
			if (what == PACKAGE_IST) {
				inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
				inter_package *which = Inter::Package::which(package_name);
				if ((which) && (which->codelike_package == FALSE)) continue;
			}
			counts[what]++;
		}
	counts[COMMENT_IST] = 0;
	counts[NOP_IST] = 0;
	int c = 0;
	for (int i=0; i<MAX_INTER_CONSTRUCTS; i++) if (counts[i] > 0) c++;
	int d = 0;
	for (int i=0; i<MAX_INTER_CONSTRUCTS; i++) if (counts[i] > 0) {
		if (d++ > 0) WRITE("; ");
		else for (int j=0; j<L; j++) WRITE("  ");
		WRITE("%d %S", counts[i], (counts[i] == 1)?(IC_lookup[i]->singular_name):(IC_lookup[i]->plural_name));
	}
	if (d > 0) WRITE("\n");
	if (pack)
		for (inter_package *Q = pack->child_package; Q; Q = Q->next_package)
			Inter::Summary::write_r(OUT, I, Q, L);
}
