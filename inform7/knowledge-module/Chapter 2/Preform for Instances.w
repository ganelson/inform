[InstancesPreform::] Preform for Instances.

To manage constant values of enumerated kinds or kinds of object.

@ The first internal matches only instances of kinds within the objects;
the second matches the others; and the third all instances, of whatever kind.
Note that the return pointer from these nonterminals is to |instance|, not
to a |parse_node| holding a specification, as with the S-parser.

=
<instance-of-object> internal {
	W = Articles::remove_the(W);
	if (<s-object-instance>(W)) {
		==> { -, Rvalues::to_instance(<<rp>>) };
		return TRUE;
	}
	==> { fail nonterminal };
}

<instance-of-non-object> internal {
	W = Articles::remove_the(W);
	parse_node *p = Lexicon::retrieve(NAMED_CONSTANT_MC, W);
	instance *I = Rvalues::to_instance(p);
	if (I) {
		==> { -, I }; return TRUE;
	}
	==> { fail nonterminal };
}

<instance> ::=
	<instance-of-object> |     ==> { pass 1 }
	<instance-of-non-object>   ==> { pass 1 }
