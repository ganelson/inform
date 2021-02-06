[PreformCache::] Simple Preform Cache.

A simple way to speed up repeated Preform parses of the same text.

@ Inform runs substantially faster if //values: The S-Parser// can cache
its findings: so, for instance, if Inform parses the text in words 507 to 511
once, it need not do so again in the same context.

We provide a cache, then, for Preform nonterminals whose return type is
|parse_node|. The cache takes the form of a modest ring buffer for each
of the contexts:

@d MAXIMUM_CACHE_SIZE 20 /* a Goldilocks value: too high slows us down, too low doesn't cache enough */
@d NUMBER_OF_CACHED_NONTERMINALS 5

=
typedef struct expression_cache {
	struct expression_cache_entry pe_cache[MAXIMUM_CACHE_SIZE];
	int pe_cache_size; /* number of entries used, 0 to |MAXIMUM_CACHE_SIZE| */
	int pe_cache_posn; /* next write position, 0 to |pe_cache_size| minus 1 */
} expression_cache;

typedef struct expression_cache_entry {
	struct wording cached_query; /* the word range whose parsing this is */
	struct parse_node *cached_result; /* and the result (quite possibly |UNKNOWN_NT|) */
} expression_cache_entry;

int expression_cache_has_been_used = FALSE;
expression_cache contextual_cache[NUMBER_OF_CACHED_NONTERMINALS];

@ =
parse_node *PreformCache::parse(wording W, int context, nonterminal *nt) {
	if (Wordings::empty(W)) return PreformCache::not_found(W);
	if ((context < 0) || (context >= NUMBER_OF_CACHED_NONTERMINALS))
		internal_error ("bad expression parsing context");
	@<Check the expression cache to see if we already know the answer@>;

	int unwanted = 0; parse_node *spec = NULL;
	int plm = preform_lookahead_mode;
	preform_lookahead_mode = FALSE;
	if (Preform::parse_nt_against_word_range(nt, W, &unwanted, (void **) &spec)) {
		if (Wordings::empty(Node::get_text(spec))) Node::set_text(spec, W);
	} else spec = PreformCache::not_found(W);
	preform_lookahead_mode = plm;

	@<Write the newly discovered specification to the cache for future use@>;
	VerifyTree::verify_structure_from(spec);

	return spec;
}

@ The following seeks a previously cached answer:

@<Check the expression cache to see if we already know the answer@> =
	expression_cache *ec = &(contextual_cache[context]);
	if (expression_cache_has_been_used == FALSE) {
		PreformCache::warn_of_changes(); /* this empties all the caches */
		expression_cache_has_been_used = TRUE;
	}
	for (int i=0; i<ec->pe_cache_size; i++)
		if (Wordings::eq(W, ec->pe_cache[i].cached_query))
			return ec->pe_cache[i].cached_result;

@ The cache expands until it reaches |MAXIMUM_CACHE_SIZE|; after that,
entries are written in a position cycling through the ring. In either case
it takes |MAXIMUM_CACHE_SIZE| further parses (not found in the cache) to
overwrite the one we put down now.

@<Write the newly discovered specification to the cache for future use@> =
	expression_cache *ec = &(contextual_cache[context]);
	ec->pe_cache[ec->pe_cache_posn].cached_query = W;
	ec->pe_cache[ec->pe_cache_posn].cached_result = spec;
	ec->pe_cache_posn++;
	if (ec->pe_cache_size < MAXIMUM_CACHE_SIZE) ec->pe_cache_size++;
	if (ec->pe_cache_posn == MAXIMUM_CACHE_SIZE) ec->pe_cache_posn = 0;

@ In Inform, this returns an UNKNOWN specification.

=
parse_node *PreformCache::not_found(wording W) {
	#ifdef UNKNOWN_PREFORM_RESULT_SYNTAX_CALLBACK
	return UNKNOWN_PREFORM_RESULT_SYNTAX_CALLBACK(W);
	#endif
	#ifndef UNKNOWN_PREFORM_RESULT_SYNTAX_CALLBACK
	return NULL;
	#endif
}

@ As with all caches, we have to be careful that the information does not fall
out of date. There are two things which can go wrong: the S-node in the cache
might be altered, perhaps as a result of the type-checker trying to force a
round peg into a square hole; or the stock of Inform's defined names might
change, so that the same text now has to be read differently.

The first problem can't be fixed here. It's tempting to try something like
flagging S-nodes which have been altered, and then ensuring that the
cache never serves up an altered result. But that fails for timing reasons --
by the time the S-node might be altered, pointers to it may exist
in multiple data structures already, because the cache might have served
it more than once by that time. (Not just a theoretical possibility -- tests
show that this does, albeit rarely, happen.) The brute force solution is to
serve a copy of the cache entry, and thus never send out the same pointer
twice. But this more than doubles the memory required to store S-nodes,
which is unacceptable, and also slows Inform down, because allocating memory
for all those copies is laborious. We therefore just have to be very careful
about modifying S-nodes which have arisen from parsing.

The second problem is easier. We require other parts of Inform which make
or unmake name definitions to warn us, by calling this routine. Definitions
are made and unmade relatively rarely, so the performance hit is small.

=
void PreformCache::warn_of_changes(void) {
	for (int i=0; i<NUMBER_OF_CACHED_NONTERMINALS; i++) {
		contextual_cache[i].pe_cache_size = 0;
		contextual_cache[i].pe_cache_posn = 0;
	}
}
