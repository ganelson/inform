[GroupTogether::] Group Together.

The "group together" phrase in the Standard Rules needs support functions, which
are compiled within the user's enclosure.

@ This section exists to support usages such as:
= (text as Inform 7)
	group containers together;
	group keys together, giving articles;
	group coins together as "filthy lucre";
=
At the Inter level, the different groupings of an object are stored in a text
property called |list_together|.[1] That's fine for the |"filthy lucre"| case,
but for the other two usages we will have to make a text substitution, in order
to have a valid value here. It's those substitutions which concern us here:
= (text)
                      small block:
	----------------> CONSTANT_PACKED_TEXT_STORAGE
                      GTF function
=
A critical point is that even if the GTF functions do the same thing as each
other (and they likely do -- there are only two possibilities), we need to
compile a different function each time, so that //BasicInformKit// can
distinguish them as values. Thus:
= (text as Inform 7)
	group woodwind instruments together;
	group brass instruments together;
=
must compile to
= (text)
                      small block:
	----------------> CONSTANT_PACKED_TEXT_STORAGE
                      GTF function 1
	----------------> CONSTANT_PACKED_TEXT_STORAGE
                      GTF function 2
=
even though GTF functions 1 and 2 are identical; we need them to be at different
addresses in memory.

[1] For backwards compatibility with Inform 6, where this same feature was called
"list together" and not "group together".

=
typedef struct group_together_function {
	struct inter_name *text_value_iname;
	struct inter_name *printing_fn_iname;
	int articles_bit; /* list with indefinite articles, or not */
	CLASS_DEFINITION
} group_together_function;

@ When //imperative: Compile Invocations Inline// wants a new GTF, it calls the
following, which returns a text literal to print a listing grouped as asked.

=
inter_name *GroupTogether::new(int include_articles) {
	group_together_function *gtf = CREATE(group_together_function);
	gtf->printing_fn_iname =
		Enclosures::new_iname(GROUPS_TOGETHER_HAP, GROUP_TOGETHER_FN_HL);
	gtf->text_value_iname = TextLiterals::small_block(gtf->printing_fn_iname);
	gtf->articles_bit = include_articles;
	text_stream *desc = Str::new();
	WRITE_TO(desc, "group together '%n'", gtf->printing_fn_iname);
	Sequence::queue(&GroupTogether::compilation_agent,
		STORE_POINTER_group_together_function(gtf), desc);
	return gtf->text_value_iname;
}

@ Again, see the DM4; this all continues to follow Inform 6 conventions.

=
void GroupTogether::compilation_agent(compilation_subtask *t) {
	group_together_function *gtf = RETRIEVE_POINTER_group_together_function(t->data);
	packaging_state save = Functions::begin(gtf->printing_fn_iname);
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(INVENTORY_STAGE_HL));
			EmitCode::val_number(1);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(SETBIT_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(ENGLISH_BIT_HL));
			EmitCode::up();
			if (!(gtf->articles_bit)) {
			EmitCode::inv(SETBIT_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(NOARTICLE_BIT_HL));
			EmitCode::up();
			}
			EmitCode::inv(CLEARBIT_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(NEWLINE_BIT_HL));
			EmitCode::up();
			EmitCode::inv(CLEARBIT_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(INDENT_BIT_HL));
			EmitCode::up();

		EmitCode::up();
	EmitCode::up();

	EmitCode::rfalse();
	Functions::end(save);
}
