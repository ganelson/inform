Version 1 of English Language by Graham Nelson begins here.

"To make English the language of play."

Use authorial modesty.

Section 1 - Modal verbs and contractions

To be able to is a verb.
To could is a verb.
To may is a verb.
To might is a verb.
To must is a verb.
To should is a verb.
To would is a verb.

To 're is a verb.
To 've is a verb.
To aren't is a verb.
To can't is a verb.
To don't is a verb.
To haven't is a verb.
To mustn't is a verb.
To mightn't is a verb.
To mayn't is a verb.
To wouldn't is a verb.
To couldn't is a verb.
To shouldn't is a verb.
To won't is a verb.

Section 1 - Grammatical definitions

The language of play is a natural language that varies. The language of play
is usually the English language.

A grammatical tense is a kind of value. The grammatical tenses are present tense,
past tense, perfect tense, past perfect tense and future tense.

A narrative viewpoint is a kind of value. The narrative viewpoints are first
person singular, second person singular, third person singular, first person
plural, second person plural, and third person plural.

A natural language has a narrative viewpoint called the adaptive text viewpoint.

The adaptive text viewpoint of the English language is first person plural.

A grammatical case is a kind of value. The grammatical cases are nominative
and accusative.

A grammatical gender is a kind of value. The grammatical genders are
neuter gender, masculine gender, feminine gender.

The story tense is a grammatical tense that varies.
The story tense variable translates into I6 as "story_tense".
The story viewpoint is a narrative viewpoint that varies.
The story viewpoint variable translates into I6 as "story_viewpoint".

To say regarding (item - an object): (- RegardingSingleObject({item}); -).

To say regarding (N - a number): (- RegardingNumber({N}); -).

To say regarding list writer internals: (- RegardingLWI(); -).

To say regarding (D - a description of objects): (-
	 	objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:D}) 
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		RegardingMarkedObjects();
	-).

To decide if the prior naming context is plural:
	(- ((prior_named_list >= 2) || (prior_named_noun && prior_named_noun has pluralname)) -).

Section 2 - Saying pronouns

To say we:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "I";
	if the story viewpoint is second person singular:
		say "you";
	if the story viewpoint is third person singular:
		if the player is male:
			say "he";
		otherwise:
			say "she";
	if the story viewpoint is first person plural:
		say "we";
	if the story viewpoint is second person plural:
		say "you";
	if the story viewpoint is third person plural:
		say "they".

To say us:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "me";
	if the story viewpoint is second person singular:
		say "you";
	if the story viewpoint is third person singular:
		if the player is male:
			say "him";
		otherwise:
			say "her";
	if the story viewpoint is first person plural:
		say "us";
	if the story viewpoint is second person plural:
		say "you";
	if the story viewpoint is third person plural:
		say "them".

To say ours:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "mine";
	if the story viewpoint is second person singular:
		say "yours";
	if the story viewpoint is third person singular:
		if the player is male:
			say "his";
		otherwise:
			say "hers";
	if the story viewpoint is first person plural:
		say "ours";
	if the story viewpoint is second person plural:
		say "yours";
	if the story viewpoint is third person plural:
		say "theirs".

To say ourselves:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "myself";
	if the story viewpoint is second person singular:
		say "yourself";
	if the story viewpoint is third person singular:
		if the player is male:
			say "himself";
		otherwise:
			say "herself";
	if the story viewpoint is first person plural:
		say "ourselves";
	if the story viewpoint is second person plural:
		say "yourselves";
	if the story viewpoint is third person plural:
		say "themselves".

To say our:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "my";
	if the story viewpoint is second person singular:
		say "your";
	if the story viewpoint is third person singular:
		if the player is male:
			say "his";
		otherwise:
			say "her";
	if the story viewpoint is first person plural:
		say "our";
	if the story viewpoint is second person plural:
		say "your";
	if the story viewpoint is third person plural:
		say "their".

To say We:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "I";
	if the story viewpoint is second person singular:
		say "You";
	if the story viewpoint is third person singular:
		if the player is male:
			say "He";
		otherwise:
			say "She";
	if the story viewpoint is first person plural:
		say "We";
	if the story viewpoint is second person plural:
		say "You";
	if the story viewpoint is third person plural:
		say "They".

To say Us:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "Me";
	if the story viewpoint is second person singular:
		say "You";
	if the story viewpoint is third person singular:
		if the player is male:
			say "Him";
		otherwise:
			say "Her";
	if the story viewpoint is first person plural:
		say "Us";
	if the story viewpoint is second person plural:
		say "You";
	if the story viewpoint is third person plural:
		say "Them".

To say Ours:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "Mine";
	if the story viewpoint is second person singular:
		say "Yours";
	if the story viewpoint is third person singular:
		if the player is male:
			say "His";
		otherwise:
			say "Hers";
	if the story viewpoint is first person plural:
		say "Ours";
	if the story viewpoint is second person plural:
		say "Yours";
	if the story viewpoint is third person plural:
		say "Theirs".

To say Ourselves:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "Myself";
	if the story viewpoint is second person singular:
		say "Yourself";
	if the story viewpoint is third person singular:
		if the player is male:
			say "Himself";
		otherwise:
			say "Herself";
	if the story viewpoint is first person plural:
		say "Ourselves";
	if the story viewpoint is second person plural:
		say "Yourselves";
	if the story viewpoint is third person plural:
		say "Themselves".

To say Our:
	now the prior named object is the player;
	if the story viewpoint is first person singular:
		say "My";
	if the story viewpoint is second person singular:
		say "Your";
	if the story viewpoint is third person singular:
		if the player is male:
			say "His";
		otherwise:
			say "Her";
	if the story viewpoint is first person plural:
		say "Our";
	if the story viewpoint is second person plural:
		say "Your";
	if the story viewpoint is third person plural:
		say "Their".

Section 3 - Further pronouns

To say those:
	say those in the accusative.

To say Those:
	say Those in the nominative.

To say those in (case - grammatical case):
	if the case is nominative:
		let the item be the prior named object;
		if the prior naming context is plural:
			say "those";
		otherwise if the item is the player:
			say "[we]";
		otherwise if the item is a male person and item is not neuter:
			say "he";
		otherwise if the item is a female person and item is not neuter:
			say "she";
		otherwise:
			say "that";
	otherwise:
		let the item be the prior named object;
		if the prior naming context is plural:
			say "those";
		otherwise if the item is the player:
			say "[we]";
		otherwise if the item is a male person and item is not neuter:
			say "him";
		otherwise if the item is a female person and item is not neuter:
			say "her";
		otherwise:
			say "that".

To say Those in (case - grammatical case):
	if the case is nominative:
		let the item be the prior named object;
		if the prior naming context is plural:
			say "Those";
		otherwise if the item is the player:
			say "[We]";
		otherwise if the item is a male person and item is not neuter:
			say "He";
		otherwise if the item is a female person and item is not neuter:
			say "She";
		otherwise:
			say "That";
	otherwise:
		let the item be the prior named object;
		if the prior naming context is plural:
			say "Those";
		otherwise if the item is the player:
			say "[We]";
		otherwise if the item is a male person and item is not neuter:
			say "Him";
		otherwise if the item is a female person and item is not neuter:
			say "Her";
		otherwise:
			say "That";

To say they:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "they";
	otherwise if the item is the player:
		say "[we]";
	otherwise if the item is a male person and item is not neuter:
		say "he";
	otherwise if the item is a female person and item is not neuter:
		say "she";
	otherwise:
		say "it";

To say They:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "They";
	otherwise if the item is the player:
		say "[We]";
	otherwise if the item is a male person and item is not neuter:
		say "He";
	otherwise if the item is a female person and item is not neuter:
		say "She";
	otherwise:
		say "It";

To say their:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "their";
	otherwise if the item is the player:
		say "[our]";
	otherwise if the item is a male person and item is not neuter:
		say "his";
	otherwise if the item is a female person and item is not neuter:
		say "her";
	otherwise:
		say "its";

To say Their:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Their";
	otherwise if the item is the player:
		say "[Our]";
	otherwise if the item is a male person and item is not neuter:
		say "His";
	otherwise if the item is a female person and item is not neuter:
		say "Her";
	otherwise:
		say "Its";

To say them:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "them";
	otherwise if the item is the player:
		say "[us]";
	otherwise if the item is a male person and item is not neuter:
		say "him";
	otherwise if the item is a female person and item is not neuter:
		say "her";
	otherwise:
		say "it";

To say Them:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Them";
	otherwise if the item is the player:
		say "[Us]";
	otherwise if the item is a male person and item is not neuter:
		say "Him";
	otherwise if the item is a female person and item is not neuter:
		say "Her";
	otherwise:
		say "It";

To say theirs:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "theirs";
	otherwise if the item is the player:
		say "[ours]";
	otherwise if the item is a male person and item is not neuter:
		say "his";
	otherwise if the item is a female person and item is not neuter:
		say "hers";
	otherwise:
		say "its";

To say Theirs:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Theirs";
	otherwise if the item is the player:
		say "[Ours]";
	otherwise if the item is a male person and item is not neuter:
		say "His";
	otherwise if the item is a female person and item is not neuter:
		say "Hers";
	otherwise:
		say "Its";

To say themselves:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "themselves";
	otherwise if the item is the player:
		say "[ourselves]";
	otherwise if the item is a male person and item is not neuter:
		say "himself";
	otherwise if the item is a female person and item is not neuter:
		say "herself";
	otherwise:
		say "itself";

To say Themselves:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Themselves";
	otherwise if the item is the player:
		say "[Ourselves]";
	otherwise if the item is a male person and item is not neuter:
		say "Himself";
	otherwise if the item is a female person and item is not neuter:
		say "Herself";
	otherwise:
		say "Itself";

To say they're:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "they";
	otherwise if the item is the player:
		say "[we]";
	otherwise if the item is a male person and item is not neuter:
		say "he";
	otherwise if the item is a female person and item is not neuter:
		say "she";
	otherwise:
		say "that";
	say "['re]".

To say They're:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "They";
	otherwise if the item is the player:
		say "[We]";
	otherwise if the item is a male person and item is not neuter:
		say "He";
	otherwise if the item is a female person and item is not neuter:
		say "She";
	otherwise:
		say "That";
	say "['re]".

To say It:
	say "[regarding nothing]It".

To say There:
	say "[regarding nothing]There".

To say it:
	say "[regarding nothing]it".

To say there:
	say "[regarding nothing]there".

To say It's:
	say "[regarding nothing]It['re]".

To say There's:
	say "[regarding nothing]There['re]".

To say it's:
	say "[regarding nothing]it['re]".

To say there's:
	say "[regarding nothing]there['re]".

To say possessive:
	let the item be the prior named object;
	if the item is the player:
		say "[our]";
	otherwise if the prior naming context is plural:
		say "[the item][apostrophe]";
	otherwise:
		say "[the item][apostrophe]s";

To say Possessive:
	let the item be the prior named object;
	if the item is the player:
		say "[Our]";
	otherwise if the prior naming context is plural:
		say "[The item][apostrophe]";
	otherwise:
		say "[The item][apostrophe]s".

English Language ends here.
