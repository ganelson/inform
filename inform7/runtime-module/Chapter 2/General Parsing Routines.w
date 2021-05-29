[GPRs::] General Parsing Routines.

To compile "general parsing routines", or GPRs, which are runtime functions
used to match noun phrases in the command parser.

@h Introduction.
At runtime, the command parser handles noun phrases in two ways. Simple
nouns for an object are handled by giving it a |name| property listing
some dictionary words which could refer to it -- see //Name Properties//.

More complex nouns are handled with Inter functions called "general parsing
routines", or GPRs: the term is traditional and goes back to Inform 1 to 6.
GPRs are used for parsing values of kinds other than objects, too; in
particular, each notation for a literal value needs its own GPR -- see
//Literal Patterns//.

The GPRs compiled automatically by today's Inform follow the same conventions
and specification, so the tutorials in the Inform 6 manual, the DM4, may help
tp explain what we do in this section of code. No tutorials are needed today
because in Inform 7 all of the many GPRs in a typical story file are compiled
automatically, so that the story's author is not really aware of them at all.

To compile a GPR, Inform has to:
(*) work out where to put it, i.e., choose an |inter_name|;
(*) open a function body there;
(*) use a //gpr_kit// to give it local variables as needed;
(*) compile a "GPR head";
(*) compile code which actually looks at the stream of command words;
(*) compile a "GPR tail";
(*) and close the function body.

The "head" and "tail" parts of a GPR come in several sorts, compiled by functions
below, and they need to match each other.

@h GPR kits.
Since GPRs are needed for several different purposes, we provide a general
API for compiling them, based around the idea of a "GPR kit" -- slogan, it's
everything you need to compile your own GPR.

This is not an elegant structure. It mainly keeps track of the many local
variables needed inside GPRs, which tend to be large, wrangly functions:

=
typedef struct gpr_kit {
	inter_symbol *cur_addr_s;
	inter_symbol *cur_len_s;
	inter_symbol *cur_word_s;
	inter_symbol *f_s;
	inter_symbol *g_s;
	inter_symbol *group_wn_s;
	inter_symbol *instance_s;
	inter_symbol *matched_number_s;
	inter_symbol *mid_word_s;
	inter_symbol *n_s;
	inter_symbol *original_wn_s;
	inter_symbol *pass_s;
	inter_symbol *pass1_n_s;
	inter_symbol *pass2_n_s;
	inter_symbol *range_from_s;
	inter_symbol *range_words_s;
	inter_symbol *rv_s;
	local_variable *rv_lv;
	inter_symbol *sgn_s;
	inter_symbol *spn_s;
	inter_symbol *ss_s;
	inter_symbol *tot_s;
	inter_symbol *try_from_wn_s;
	inter_symbol *v_s;
	inter_symbol *w_s;
	inter_symbol *wpos_s;
	inter_symbol *x_s;
	
	inter_symbol *fail_label;
	int label_count;
	int current_grammar_block;
	int GV_IS_VALUE_instance_mode;
} gpr_kit;

@ The idea is to create a new kit which is initially empty:

=
gpr_kit GPRs::new_kit(void) {
	gpr_kit kit;
	kit.cur_addr_s = NULL;
	kit.cur_len_s = NULL;
	kit.cur_word_s = NULL;
	kit.f_s = NULL;
	kit.g_s = NULL;
	kit.group_wn_s = NULL;
	kit.instance_s = NULL;
	kit.matched_number_s = NULL;
	kit.mid_word_s = NULL;
	kit.n_s = NULL;
	kit.original_wn_s = NULL;
	kit.pass_s = NULL;
	kit.pass1_n_s = NULL;
	kit.pass2_n_s = NULL;
	kit.range_from_s = NULL;
	kit.range_words_s = NULL;
	kit.rv_s = NULL;
	kit.rv_lv = NULL;
	kit.sgn_s = NULL;
	kit.spn_s = NULL;
	kit.ss_s = NULL;
	kit.tot_s = NULL;
	kit.try_from_wn_s = NULL;
	kit.v_s = NULL;
	kit.w_s = NULL;
	kit.wpos_s = NULL;
	kit.x_s = NULL;
	
	kit.fail_label = NULL;
	kit.label_count = 0;
	kit.current_grammar_block = 0;
	kit.GV_IS_VALUE_instance_mode = FALSE;
	return kit;
}

@ Then, if you then need a local variable in the GPR you're making, declare it
and write its symbol to the appropriate field. But this is best done with the
following convenience functions.

=
void GPRs::add_standard_vars(gpr_kit *kit) {
	kit->group_wn_s = LocalVariables::new_internal_as_symbol(I"group_wn");
	kit->v_s = LocalVariables::new_internal_as_symbol(I"v");
	kit->w_s = LocalVariables::new_internal_as_symbol(I"w");
	kit->rv_lv = LocalVariables::new_internal(I"rv");
	kit->rv_s = LocalVariables::declare(kit->rv_lv);
}

void GPRs::add_instance_var(gpr_kit *kit) {
	kit->instance_s = LocalVariables::new_other_as_symbol(I"instance");
}

void GPRs::add_range_vars(gpr_kit *kit) {
	kit->range_from_s = LocalVariables::new_internal_commented_as_symbol(I"range_from",
		I"call parameter: word number of snippet start");
	kit->range_words_s = LocalVariables::new_internal_commented_as_symbol(I"range_words",
		I"call parameter: snippet length");
}

void GPRs::add_original_var(gpr_kit *kit) {
	kit->original_wn_s = LocalVariables::new_internal_as_symbol(I"original_wn");
}

void GPRs::add_LP_vars(gpr_kit *kit) {
	kit->wpos_s = LocalVariables::new_internal_as_symbol(I"wpos");
	kit->mid_word_s = LocalVariables::new_internal_as_symbol(I"mid_word");
	kit->matched_number_s = LocalVariables::new_internal_as_symbol(I"matched_number");
	kit->cur_word_s = LocalVariables::new_internal_as_symbol(I"cur_word");
	kit->cur_len_s = LocalVariables::new_internal_as_symbol(I"cur_len");
	kit->cur_addr_s = LocalVariables::new_internal_as_symbol(I"cur_addr");
	kit->sgn_s = LocalVariables::new_internal_as_symbol(I"sgn");
	kit->tot_s = LocalVariables::new_internal_as_symbol(I"tot");
	kit->f_s = LocalVariables::new_internal_as_symbol(I"f");
	kit->x_s = LocalVariables::new_internal_as_symbol(I"x");
}

void GPRs::add_parse_name_vars(gpr_kit *kit) {
	kit->original_wn_s = LocalVariables::new_internal_commented_as_symbol(I"original_wn",
		I"first word of text parsed");
	kit->group_wn_s = LocalVariables::new_internal_commented_as_symbol(I"group_wn",
		I"first word matched against A/B/C/... disjunction");
	kit->try_from_wn_s = LocalVariables::new_internal_commented_as_symbol(I"try_from_wn",
		I"position to try matching from");
	kit->n_s = LocalVariables::new_internal_commented_as_symbol(I"n",
		I"number of words matched");
	kit->f_s = LocalVariables::new_internal_commented_as_symbol(I"f",
		I"flag: sufficiently good match found to justify success");
	kit->w_s = LocalVariables::new_internal_commented_as_symbol(I"w",
		I"for use by individual grammar lines");
	kit->rv_lv = LocalVariables::new_internal(I"rv");
	kit->rv_s = LocalVariables::declare(kit->rv_lv);
	kit->g_s = LocalVariables::new_internal_commented_as_symbol(I"g",
		I"temporary: success flag for parsing visibles");
	kit->ss_s = LocalVariables::new_internal_commented_as_symbol(I"ss",
		I"temporary: saves 'self' in distinguishing visibles");
	kit->spn_s = LocalVariables::new_internal_commented_as_symbol(I"spn",
		I"temporary: saves 'parsed_number' in parsing visibles");
	kit->pass_s = LocalVariables::new_internal_commented_as_symbol(I"pass",
		I"pass counter (1 to 3)");
	kit->pass1_n_s = LocalVariables::new_internal_commented_as_symbol(I"pass1_n",
		I"value of n recorded during pass 1");
	kit->pass2_n_s = LocalVariables::new_internal_commented_as_symbol(I"pass2_n",
		I"value of n recorded during pass 2");
}

void GPRs::begin_line(gpr_kit *kit) {
	if (kit) kit->label_count++;
	if (kit) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".Fail_%d", kit->label_count);
		kit->fail_label = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)
		kit->current_grammar_block++;
	}
}
