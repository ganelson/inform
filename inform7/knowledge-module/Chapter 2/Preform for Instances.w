[InstancesPreform::] Preform for Instances.

To manage constant values of enumerated kinds or kinds of object.

@ Ordinarily these constants are read by the S-parser in the normal way that
all constants are read -- see //values// -- but it's occasionally useful to
bypass that and just parse text as an instance name and nothing else.

=
instance *InstancesPreform::parse_object(wording W) {
	parse_node *p;
	if (Wordings::empty(W)) return NULL;
	if (<s-literal>(W)) return NULL;
	p = Lexicon::retrieve(NOUN_MC, W);
	if (p == NULL) return NULL;
	noun_usage *nu = Nouns::disambiguate(p, FALSE);
	noun *nt = nu->noun_used;
	if (Nouns::is_proper(nt)) {
		parse_node *pn = RETRIEVE_POINTER_parse_node(Nouns::meaning(nt));
		if (Node::is(pn, CONSTANT_NT)) {
			kind *K = Node::get_kind_of_value(pn);
			if (Kinds::Behaviour::is_object(K))
				return Node::get_constant_instance(pn);
		}
	}
	return NULL;
}

@ The first internal matches only instances of kinds within the objects;
the second matches the others; and the third all instances, of whatever kind.

=
<instance-of-object> internal {
	instance *I = InstancesPreform::parse_object(W);
	if (I) { ==> { -, I }; return TRUE; }
	==> { fail nonterminal };
}

<instance-of-non-object> internal {
	parse_node *p = Lexicon::retrieve(NAMED_CONSTANT_MC, W);
	instance *I = Rvalues::to_instance(p);
	if (I) { ==> { -, I }; return TRUE; }
	==> { fail nonterminal };
}

<instance> internal {
	if (<s-literal>(W)) { ==> { fail nonterminal }; }
	W = Articles::remove_the(W);
	instance *I = InstancesPreform::parse_object(W);
	if (I) { ==> { -, I }; return TRUE; }
	parse_node *p = Lexicon::retrieve(NAMED_CONSTANT_MC, W);
	I = Rvalues::to_instance(p);
	if (I) { ==> { -, I }; return TRUE; }
	==> { fail nonterminal };
}
