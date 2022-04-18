[LoadBinaryKitsStage::] Load Binary Kits Stage.

Reading other Inter trees as binary files, and attaching them at given points
in the main Inter tree.

@ Inform 7 compiles source text to a single "main" Inter tree. That tree must
then be joined with other Inter trees for kits such as BasicInformKit, a
process called "linking", for want of a better word.[1]

Only the //supervisor// module knows which kits need to be linked in; the main
Inter tree doesn't contain this information.[2]

[1] Unlike the C linking process, it is not symmetrical. One Inter tree is
made by //inter//, and the others by //inter//, for one thing.

[2] Just as a C-compiled binary may be made by linking |alpha.o|, |beta.o| and
|gamma.o| together, but the fact that these are the three |*.o| files needed
to make the finished article is recorded only in the makefile for the program.
It's a matter for the build process and not for the compiler.

@ The list of Inter trees to link with is worked out by the //supervisor//,
which calls the following function to obtain a way to record each "requirement":

=
typedef struct attachment_instruction {
	struct pathname *location;
	struct text_stream *attachment_point;
	CLASS_DEFINITION
} attachment_instruction;

attachment_instruction *LoadBinaryKitsStage::new_requirement(pathname *P, text_stream *attach) {
	attachment_instruction *link = CREATE(attachment_instruction);
	link->location = P;
	link->attachment_point = Str::duplicate(attach);
	return link;
}

@ Linking begins with the following stage. Note that the list of requirements
made by //supervisor// is now stored in |step->ephemera.requirements_list|.

=
void LoadBinaryKitsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"load-binary-kits",
		LoadBinaryKitsStage::run, NO_STAGE_ARG, FALSE);
}

int LoadBinaryKitsStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	attachment_instruction *req;
	LOOP_OVER_LINKED_LIST(req, attachment_instruction, step->ephemera.requirements_list) {
		inter_tree *sidecar = InterTree::new();
		@<Load the Inter for the kit into the sidecar@>;
		@<Look for duplicate definitions@>;
		@<Migrate the bulk of the code from the sidecar to the main tree@>;
	}
	Wiring::connect_plugs_to_sockets(I);
	return TRUE;
}

@ A kit will, if properly prepared, contain a binary Inter file for each possible
architecture which may be needed. For testing purposes, the following actually
allows a textual Inter file to be used instead, but this isn't intended for
regular users: it would be quite slow to read in.

@<Load the Inter for the kit into the sidecar@> =
	inter_architecture *A = PipelineModule::get_architecture();
	if (A == NULL) Errors::fatal("no -architecture given");
	filename *arch_file = Architectures::canonical_binary(req->location, A);
	if (TextFiles::exists(arch_file) == FALSE)
		internal_error("no arch file for requirement");
	if (BinaryInter::test_file(arch_file)) BinaryInter::read(sidecar, arch_file);
	else TextualInter::read(sidecar, arch_file);		

@<Look for duplicate definitions@> =
	inter_package *sidecar_connectors =
		LargeScale::connectors_package_if_it_exists(sidecar);
	if (sidecar_connectors) {
		inter_symbols_table *T = InterPackage::scope(sidecar_connectors);
		LOOP_OVER_SYMBOLS_TABLE(S, T) {
			if (InterSymbol::is_socket(S)) {
				text_stream *defn_name = InterSymbol::identifier(S);
				inter_symbol *rival = Wiring::find_socket(I, defn_name);
				if (rival) {
					inter_symbol *sidecar_end = Wiring::cable_end(S);
					inter_symbol *rival_end = Wiring::cable_end(rival);
					if (InterSymbol::get_flag(rival_end, PERMIT_NAME_CLASH_ISYMF) == FALSE)
						@<A clash of definitions seems to have occurred@>;
				}
			}
		}
	}

@<A clash of definitions seems to have occurred@> =
	LOGIF(INTER_CONNECTORS, "Rival definitions of '%S':\nkit: $3\ntree: $3\n",
		defn_name, rival_end, Wiring::cable_end(S));
	int override = FALSE;
	linked_list *L = step->pipeline->ephemera.replacements_list[step->tree_argument];
	text_stream *N;
	LOOP_OVER_LINKED_LIST(N, text_stream, L)
		if (Str::eq(N, defn_name)) override = TRUE;
	if (override == FALSE) {
		int r_val = ConstantInstruction::evaluate_to_int(rival_end);
		int s_val = ConstantInstruction::evaluate_to_int(sidecar_end);
		if ((r_val == s_val) && (r_val != -1)) override = TRUE;
	}
	if (override) @<Override the new definition with the existing one@>
	else @<Throw an error for the duplication@>;

@ The following (unfortunately) has to do something subtle. We need the definition
of |defn_name| to be the one in the main tree; that means |sidecar_end| has to have
its present definition struck, i.e., removed entirely from the |sidecar| tree.
This may remove something as simple as a single constant definition, or as large
as a huge package holding the body of a function. Then, |sidecar_end| has to
be redefined as something in the main tree. But since transmigration has not yet
happened, we can't just wire it there. We have to wire it to a plug with name
|defn_tree| instead; and then after transmigration this will be connected to a
socket in the main tree connecting to |rival_end|.

But even that isn't quite enough. We can't allow the |connectors| package of
|sidecar| to contain a socket name which is the same as a socket name in the
|connectors| package of the main tree |I|. It might seem that we can just delete
the now-unwanted socket wired to the old definition; but we cannot, because other
symbols in the same kit might already be wired to it. So we keep the old socket,
but rename it with a name which will avoid name collisions, striking it out of
the symbols table dictionary.

@<Override the new definition with the existing one@> =
	if (InterSymbolsTable::unname(T, defn_name) == FALSE)
		internal_error("cannot strike socket name");
	inter_symbol *plug = Wiring::plug(sidecar, defn_name);
	InterSymbol::strike_definition(sidecar_end);
	Wiring::wire_to(sidecar_end, plug);
	LOGIF(INTER_CONNECTORS, "After overriding the kit definition, we have:\n");
	LOGIF(INTER_CONNECTORS, "Socket renamed as $3 ~~> $3\n", S, Wiring::cable_end(S));
	LOGIF(INTER_CONNECTORS, "A new plug $3\n", plug);
	LOGIF(INTER_CONNECTORS, "Kit defn symbol $3 ~~> $3\n",
		sidecar_end, Wiring::cable_end(sidecar_end));

@<Throw an error for the duplication@> =
	TEMPORARY_TEXT(E)
	WRITE_TO(E,
		"found a second definition of the name '%S' when loading '%S'",
		defn_name, req->attachment_point);
	PipelineErrors::error_with(step, "%S", E);
	DISCARD_TEXT(E)

@ The "attachment point" for the kit will be something like |/main/BasicInformKit|.
(This point will be different for each different kit in the requirements list:
others might include |/main/CommandParserKit|, and so on.) We take that package out
of the sidecar and put it into the main tree.

@<Migrate the bulk of the code from the sidecar to the main tree@> =
	inter_package *pack = InterPackage::from_URL(sidecar, req->attachment_point);
	if (pack == NULL) {
		WRITE_TO(STDERR, "sought attachment material at: %S\n", req->attachment_point);
		internal_error("unable to find attachment point package");
	}
	Transmigration::move(pack, LargeScale::main_package(I), FALSE);	
