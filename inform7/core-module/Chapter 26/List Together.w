[ListTogether::] List Together.

To write support code for the Standard Library's "group together"
phrases.

@h Definitions.

@ This section exists to support phrases such as:

>> To group (OS - description of objects) together giving articles: ...

For obscure reasons to do with the Inform 6 property |list_together|
(see DM4 for details), each such usage needs to define a small I6
routine. The code here manages that.

The only data stored is a single bit, saying whether to give articles or not:

=
typedef struct list_together_routine {
	struct inter_name *ltr_array_iname;
	struct inter_name *ltr_routine_iname;
	int articles_bit; /* if false, add |NOARTICLE_BIT| to the I6 listing style */
	MEMORY_MANAGEMENT
} list_together_routine;

@h Creation.
When the inline compiler wants a new LTR, it calls the following, which
prints the name of a routine to be compiled later.

=
inter_name *ListTogether::new(int include_articles) {
	list_together_routine *ltr = CREATE(list_together_routine);
	package_request *PR = Hierarchy::local_package(LISTS_TOGETHER_HAP);
	ltr->ltr_routine_iname = Hierarchy::make_iname_in(LIST_TOGETHER_FN_HL, PR);
	ltr->ltr_array_iname = Hierarchy::make_iname_in(LIST_TOGETHER_ARRAY_HL, PR);

	ltr->articles_bit = include_articles;
	return ltr->ltr_array_iname;
}

@h Compilation.
And here's later. Note that there are only two possible routines made
here, and we keep compiling them over and over, with different names. That
looks wasteful, but we do it so that the routine addresses can be used as
distinct values of the |list_together| property at run-time, because this
is significant to the run-time list-printing code.

=
list_together_routine *latest_ltr_compiled = NULL;

int ListTogether::compilation_coroutine(void) {
	int N = 0;
	while (TRUE) {
		list_together_routine *ltr = FIRST_OBJECT(list_together_routine);
		if (latest_ltr_compiled)
			ltr = NEXT_OBJECT(latest_ltr_compiled, list_together_routine);
		if (ltr == NULL) break;
		@<Compile the actual LTR@>;
		latest_ltr_compiled = ltr;
		N++;
	}
	return N;
}

@ Again, see the DM4.

@<Compile the actual LTR@> =
	packaging_state save = Routines::begin(ltr->ltr_routine_iname);
	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(eq_interp);
		Emit::down();
			Emit::val_iname(K_value, Hierarchy::find(INVENTORY_STAGE_HL));
			Emit::val(K_number, LITERAL_IVAL, 1);
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(setbit_interp);
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				Emit::val_iname(K_value, Hierarchy::find(ENGLISH_BIT_HL));
			Emit::up();
			if (!(ltr->articles_bit)) {
			Emit::inv_primitive(setbit_interp);
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				Emit::val_iname(K_value, Hierarchy::find(NOARTICLE_BIT_HL));
			Emit::up();
			}
			Emit::inv_primitive(clearbit_interp);
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				Emit::val_iname(K_value, Hierarchy::find(NEWLINE_BIT_HL));
			Emit::up();
			Emit::inv_primitive(clearbit_interp);
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(C_STYLE_HL));
				Emit::val_iname(K_value, Hierarchy::find(INDENT_BIT_HL));
			Emit::up();

		Emit::up();
	Emit::up();

	Emit::rfalse();
	Routines::end(save);

	save = Emit::named_array_begin(ltr->ltr_array_iname, K_value);
	Emit::array_iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
	Emit::array_iname_entry(ltr->ltr_routine_iname);
	Emit::array_end(save);
