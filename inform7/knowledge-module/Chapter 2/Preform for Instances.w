[InstancesPreform::] Preform for Instances.

Preform grammar to parse names of instances.

@ When we create instances of a kind whose name coincides with a property
used as a condition, as here:

>> A door can be ajar, sealed or wedged open.

we will need "ajar" and so on to be (in most contexts) adjectives rather
than nouns; so, even though they are instances, we do not add those to
the lexicon.

Otherwise, we have a choice of whether to allow ambiguous references or not.
Inform traditionally allows these for instances of object, but not for other
instances: thus "submarine green" (a colour, say) must be spelled out in
full, whereas a "tuna fish" (an object) can be called just "tuna".

=
void InstancesPreform::create_as_noun(instance *I, kind *K, wording W) {
	int exact_parsing = TRUE, any_parsing = TRUE;
	property *cp = Properties::Conditions::get_coinciding_property(K);
	if ((cp) && (Properties::Conditions::of_what(cp))) any_parsing = FALSE;
	if (Kinds::Behaviour::is_object(K)) exact_parsing = FALSE;
	if (any_parsing) {
		if (exact_parsing)
			I->as_noun =
				Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
					NAMED_CONSTANT_MC, Rvalues::from_instance(I), Task::language_of_syntax());
		else
			I->as_noun =
				Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
					NOUN_MC, Rvalues::from_instance(I), Task::language_of_syntax());
	} else {
		I->as_noun = Nouns::new_proper_noun(W, NEUTER_GENDER, 0,
			NAMED_CONSTANT_MC, NULL, Task::language_of_syntax());
	}
	NameResolution::initialise(I->as_noun);
}

@ Since we store instance names in two different ways, we have to parse them
in two different ways, and here goes.

Two versions are provided. As usual, the nonterminals beginning with "s-"
return specification |parse_node| pointers; the ones without return |instance|
pointers.

=
<s-object-instance> internal {
	parse_node *p = Lexicon::retrieve(NOUN_MC, W);
	if (p) {
		noun_usage *nu = Nouns::disambiguate(p, FALSE);
		noun *nt = nu->noun_used;
		if (Nouns::is_proper(nt)) {
			instance *I = Rvalues::to_object_instance(
				RETRIEVE_POINTER_parse_node(Nouns::meaning(nt)));
			==> { -, Rvalues::from_instance(I) };
			return TRUE;
		}
	}
	==> { fail nonterminal };
}

<s-non-object-instance> internal {
	W = Articles::remove_the(W);
	parse_node *p = Lexicon::retrieve(NAMED_CONSTANT_MC, W);
	if (p) {
		==> { -, p }; return TRUE;
	}
	==> { fail nonterminal };
}

<s-instance> ::=
	<s-instance-of-object> |     ==> { pass 1 }
	<s-instance-of-non-object>   ==> { pass 1 }

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
	if (<s-non-object-instance>(W)) {
		==> { -, Rvalues::to_instance(<<rp>>) };
		return TRUE;
	}
	==> { fail nonterminal };
}

<instance> ::=
	<instance-of-object> |     ==> { pass 1 }
	<instance-of-non-object>   ==> { pass 1 }
