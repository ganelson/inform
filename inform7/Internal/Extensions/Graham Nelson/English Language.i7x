Version 3 of English Language by Graham Nelson begins here.

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

Section 2 - Fallback definitions (not for interactive fiction language element)

A natural language is a kind of value.

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
The story tense variable is defined by Inter as "story_tense".
The story viewpoint is a narrative viewpoint that varies.
The story viewpoint variable is defined by Inter as "story_viewpoint".

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

Section - Preferred printing gender (for interactive fiction language element)

Prefer neuter gender is a truth state that varies.
Prefer neuter gender is usually true.
The preferred animate gender is a grammatical gender which varies.
The preferred animate gender is usually masculine gender.  [Matches old-fashioned English.]

To decide which grammatical gender is the printing gender for (o - an object):
	[not male or female, always use "it"]
	if o is not male and o is not female:
		decide on neuter gender;
	[neuter and prefer neuter gender, always use "it"]
	if o is neuter and prefer neuter gender is true:
		decide on neuter gender;
	[female and male, use preferred animate gender]
	if o is female and o is male:
		decide on preferred animate gender;
	[classic male; and non-neuter or male overrrides neuter]
	if o is male:
		decide on masculine gender;
	[classic female; and non-neuter or female overrrides neuter]
	if o is female:
		decide on feminine gender.

Section - Saying viewpoint pronouns (for interactive fiction language element)

To say we:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "I";
		-- second person singular: say "you";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "he";
				-- the feminine gender: say "she";
				-- the neuter gender: say "it";
		-- first person plural: say "we";
		-- second person plural: say "you";
		-- third person plural: say "they";

To say us:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "me";
		-- second person singular: say "you";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "him";
				-- the feminine gender: say "her";
				-- the neuter gender: say "it";
		-- first person plural: say "us";
		-- second person plural: say "you";
		-- third person plural: say "them";

To say ours:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "mine";
		-- second person singular: say "yours";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "his";
				-- the feminine gender: say "hers";
				-- the neuter gender: say "its";
		-- first person plural: say "ours";
		-- second person plural: say "yours";
		-- third person plural: say "theirs";

To say ourselves:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "myself";
		-- second person singular: say "yourself";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "himself";
				-- the feminine gender: say "herself";
				-- the neuter gender: say "itself";
		-- first person plural: say "ourselves";
		-- second person plural: say "yourselves";
		-- third person plural: say "themselves";

To say our:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "my";
		-- second person singular: say "your";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "his";
				-- the feminine gender: say "her";
				-- the neuter gender: say "its";
		-- first person plural: say "our";
		-- second person plural: say "your";
		-- third person plural: say "their";

To say We:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "I";
		-- second person singular: say "You";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "He";
				-- the feminine gender: say "She";
				-- the neuter gender: say "It";
		-- first person plural: say "We";
		-- second person plural: say "You";
		-- third person plural: say "They";

To say Us:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "Me";
		-- second person singular: say "You";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "Him";
				-- the feminine gender: say "Her";
				-- the neuter gender: say "It";
		-- first person plural: say "Us";
		-- second person plural: say "You";
		-- third person plural: say "Them";

To say Ours:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "Mine";
		-- second person singular: say "Yours";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "His";
				-- the feminine gender: say "Hers";
				-- the neuter gender: say "Its";
		-- first person plural: say "Ours";
		-- second person plural: say "Yours";
		-- third person plural: say "Theirs";

To say Ourselves:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "Myself";
		-- second person singular: say "Yourself";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "Himself";
				-- the feminine gender: say "Herself";
				-- the neuter gender: say "Itself";
		-- first person plural: say "Ourselves";
		-- second person plural: say "Yourselves";
		-- third person plural: say "Themselves";

To say Our:
	now the prior named object is the player;
	if the story viewpoint is:
		-- first person singular: say "My";
		-- second person singular: say "Your";
		-- third person singular:
			if printing gender for the player is:
				-- the masculine gender: say "His";
				-- the feminine gender: say "Her";
				-- the neuter gender: say "Its";
		-- first person plural: say "Our";
		-- second person plural: say "Your";
		-- third person plural: say "Their";

Section - Saying item pronouns (for interactive fiction language element only)

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
		otherwise:
			if printing gender for the item is:
				-- the masculine gender: say "he";
				-- the feminine gender: say "she";
				-- the neuter gender: say "that";
	otherwise:
		let the item be the prior named object;
		if the prior naming context is plural:
			say "those";
		otherwise if the item is the player:
			say "[we]";
		otherwise:
			if printing gender for the item is:
				-- the masculine gender: say "him";
				-- the feminine gender: say "her";
				-- the neuter gender: say "that";

To say Those in (case - grammatical case):
	if the case is nominative:
		let the item be the prior named object;
		if the prior naming context is plural:
			say "Those";
		otherwise if the item is the player:
			say "[We]";
		otherwise:
			if printing gender for the item is:
				-- the masculine gender: say "He";
				-- the feminine gender: say "She";
				-- the neuter gender: say "That";
	otherwise:
		let the item be the prior named object;
		if the prior naming context is plural:
			say "Those";
		otherwise if the item is the player:
			say "[We]";
		otherwise:
			if printing gender for the item is:
				-- the masculine gender: say "Him";
				-- the feminine gender: say "Her";
				-- the neuter gender: say "That";

To say they:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "they";
	otherwise if the item is the player:
		say "[we]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "he";
			-- the feminine gender: say "she";
			-- the neuter gender: say "it";

To say They:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "They";
	otherwise if the item is the player:
		say "[We]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "He";
			-- the feminine gender: say "She";
			-- the neuter gender: say "It";

To say their:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "their";
	otherwise if the item is the player:
		say "[our]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "his";
			-- the feminine gender: say "her";
			-- the neuter gender: say "its";

To say Their:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Their";
	otherwise if the item is the player:
		say "[Our]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "His";
			-- the feminine gender: say "Her";
			-- the neuter gender: say "Its";

To say them:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "them";
	otherwise if the item is the player:
		say "[us]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "him";
			-- the feminine gender: say "her";
			-- the neuter gender: say "it";

To say Them:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Them";
	otherwise if the item is the player:
		say "[Us]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "Him";
			-- the feminine gender: say "Her";
			-- the neuter gender: say "It";

To say theirs:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "theirs";
	otherwise if the item is the player:
		say "[ours]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "his";
			-- the feminine gender: say "hers";
			-- the neuter gender: say "its";

To say Theirs:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Theirs";
	otherwise if the item is the player:
		say "[Ours]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "His";
			-- the feminine gender: say "Hers";
			-- the neuter gender: say "Its";

To say themselves:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "themselves";
	otherwise if the item is the player:
		say "[ourselves]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "himself";
			-- the feminine gender: say "herself";
			-- the neuter gender: say "itself";

To say Themselves:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "Themselves";
	otherwise if the item is the player:
		say "[Ourselves]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "Himself";
			-- the feminine gender: say "Herself";
			-- the neuter gender: say "Itself";

[Note the difference in the neuter gender between /they're/ -> that's and /they/ /'re/ -> they're]
To say they're:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "they";
	otherwise if the item is the player:
		say "[we]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "he";
			-- the feminine gender: say "she";
			-- the neuter gender: say "that";
	say "['re]".

To say They're:
	let the item be the prior named object;
	if the prior naming context is plural:
		say "They";
	otherwise if the item is the player:
		say "[We]";
	otherwise:
		if printing gender for the item is:
			-- the masculine gender: say "He";
			-- the feminine gender: say "She";
			-- the neuter gender: say "That";
	say "['re]".

Section - Saying non-referential pronouns (for interactive fiction language element only)

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

Section - Saying possessives (for interactive fiction language element only)

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
