Version 5 of Punctuation Removal by Emily Short begins here.

Use authorial modesty.

Section 1 - Wrappers

To remove stray punctuation:
	(- PunctuationStripping(); players_command = 100 + WordCount();  -)

To remove quotes:
	(- Quotestripping(); players_command = 100 + WordCount();  -)

To remove apostrophes:
	(- SingleQuotestripping(); players_command = 100 + WordCount();  -)

To remove question marks:
	(- Questionstripping(); players_command = 100 + WordCount(); -)
	
To remove exclamation points:
	(- ExclamationStripping(); players_command = 100 + WordCount(); -)
	
To remove periods:
	(- PeriodStripping(); players_command = 100 + WordCount();  -)
	
To resolve punctuated titles:
	(- DeTitler(); players_command = 100 + WordCount(); -)
	
Include (- 

[ Detitler i j buffer_length flag; 

#ifdef TARGET_ZCODE;
	buffer_length = buffer->1+(WORDSIZE-1);
#endif;
#ifdef TARGET_GLULX;
	buffer_length = (buffer-->0)+(WORDSIZE-1);
#endif; 
	for (i = WORDSIZE : i <= buffer_length: i++)
	{ 
		if ((buffer->i) == '.' && (i > WORDSIZE + 1)) 
		{ 
			! flag if the period follows Mr, Mrs, Dr, prof, rev, or st
			!
			! This is hackish, but our hearts are pure
			
			if ((buffer->(i-1)=='r') && (buffer->(i-2)=='m') && ((buffer->(i-3)==' ') || ((i-3) < WORDSIZE))) flag = 1;
			if ((buffer->(i-1)=='r') && (buffer->(i-2)=='d') && ((buffer->(i-3)==' ') || ((i-3) < WORDSIZE))) flag = 1;
			if ((buffer->(i-1)=='t') && (buffer->(i-2)=='s') && ((buffer->(i-3)==' ') || ((i-3) < WORDSIZE))) flag = 1;
			if ((buffer->(i-1)=='s') && (buffer->(i-2)=='r') && (buffer->(i-3)=='m') && ((buffer->(i-4)==' ') || ((i-4) < WORDSIZE))) flag = 1;
			if ((buffer->(i-1)=='v') && (buffer->(i-2)=='e') && (buffer->(i-3)=='r') && ((buffer->(i-4)==' ') || ((i-4) < WORDSIZE))) flag = 1;
			if ((buffer->(i-1)=='f') && (buffer->(i-2)=='o') && (buffer->(i-3)=='r') && (buffer->(i-4)=='p') && ((buffer->(i-5)==' ') || ((i-5) < WORDSIZE))) flag = 1;
			if (flag) buffer->i = ' ';   
		}
	}
	VM_Tokenise(buffer, parse);
]; 

-) 


Section 2 (for Z-machine only)

Include (-

[ PunctuationStripping i;
	for (i = 2 : i <= (buffer->1) + 1 : i++)
	{ 
		if ((buffer->i) == '"' or '?' or '!') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)


Include (-

[ SingleQuoteStripping i;
	for (i = 2 : i <= (buffer->1) + 1 : i++)
	{ 
		if ((buffer->i) == 39) 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)

Include (-

[ QuoteStripping i;
	for (i = 2 : i <= (buffer->1) + 1 : i++)
	{ 
		if ((buffer->i) == '"') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)
	
Include (-

[ Questionstripping i;
	for (i = 2 : i <= (buffer->1) + 1 : i++)
	{ 
		if ((buffer->i) == '?') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)

Include (-

[ ExclamationStripping i;
	for (i = 2 : i <= (buffer->1) + 1 : i++)
	{ 
		if ((buffer->i) == '!') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)

Include (-

[ PeriodStripping i j;
	for (i = 2 : i <= (buffer->1) + 1 : i++)
	{ 
		if ((buffer->i) == '.') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)

Section 3 (for Glulx only) 

Include (-

[ BufferOut i;   
	for (i = WORDSIZE : i <= (buffer-->0)+(WORDSIZE-1) : i++)
	{  
		print (char) (buffer->i);
	} 
];

[ PunctuationStripping i;
	for (i = WORDSIZE : i <= (buffer-->0)+(WORDSIZE-1) : i++)
	{ 
		if ((buffer->i) == '"' or '?' or '!') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)


Include (-

[ SingleQuoteStripping i;
	for (i = WORDSIZE : i <= (buffer-->0)+(WORDSIZE-1) : i++)	{ 
		if ((buffer->i) == 39) 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

[ QuoteStripping i;
	for (i = WORDSIZE : i <= (buffer-->0)+(WORDSIZE-1) : i++)	{ 
		if ((buffer->i) == '"') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)
	
Include (-

[ Questionstripping i;
	for (i = WORDSIZE : i <= (buffer-->0)+(WORDSIZE-1) : i++)
	{ 
		if ((buffer->i) == '?') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)

Include (-

[ ExclamationStripping i;
	for (i = WORDSIZE : i <= (buffer-->0)+(WORDSIZE-1) : i++)
	{ 
		if ((buffer->i) == '!') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)

Include (-

[ PeriodStripping i j;
	for (i = WORDSIZE : i <= (buffer-->0)+(WORDSIZE-1) : i++)
	{ 
		if ((buffer->i) == '.') 
		{	buffer->i = ' ';  
		}
	}
	VM_Tokenise(buffer, parse);
];

-)



Punctuation Removal ends here.

---- DOCUMENTATION ----

Punctuation Removal provides phrases for removing unwanted punctuation marks from the player's command before attempting to interpret it. These are

	remove exclamation points
	remove question marks
	remove quotes

and, to do all three of these things at once,

	remove stray punctuation.

Also provided, but not included in "remove stray punctuation", is

	remove periods

which we should use sparingly, since the player's command might reasonably include multiple actions separated by full stops. Similarly dangerous is

	remove apostrophes

A more common need is to be able to parse titles such as "mr." and "mrs." sensibly. Inform reads any full stop as the end of the sentence, which leads to such exchanges as 

	>x mr. sinister.
	You see nothing special about Mr. Sinister.

	That's not a verb I recognise.

because Inform has interpreted as though the player had typed

	>x mr.
	You see nothing special about Mr. Sinister.
	
	>sinister
	That's not a verb I recognise.

To get around this, we want to remove full stops only when they appear as parts of standard titles. "Punctuation Removal" provides the phrase

	resolve punctuated titles
	
which turns all instances in the player's command of "mr.", "mrs.", "prof.", "st.", "dr.", and "rev." into "mr", "mrs", "prof", "st", "dr", and "rev" respectively. Now (assuming Inform understands "mr" as referring to the correct character) we get such output as

	>x me. x mr. sinister. 
	As good-looking as ever.

	You see nothing special about Mr. Sinister.

These phrases should be used during the After reading a command activity, so for instance in a game designed to be very patient with the player's quirks:

	After reading a command:
		remove stray punctuation.

Or, if we have titled characters,

	After reading a command:
		resolve punctuated titles.
		
Example: * Patience - In which question and exclamation marks are pulled from the player's input.

	*: "Patience"
	
	Include Punctuation Removal by Emily Short.
	
	The Overpunctuation Arena is a room. "It's madness in here!! Fortunately, you have a lot of patience, right???"
	
	Understand "who is/are [text]" as inquiring about. Inquiring about is an action applying to one topic. Carry out inquiring about a topic listed in the Table of Answers: say "[reply entry][paragraph break]". Understand the command "what" as "who".
	
	Table of Answers
	topic	reply
	"patience"	"A virtue."
	"virtue" or "a virtue"	"A grace."
	"Grace" or "a grace"	"A little girl who doesn't wash her face."
	
	After reading a command:
		remove stray punctuation;
		if the player's command includes "&", replace the matched text with "and".
	
	Test me with "what is patience? / what is a virtue?! / what is grace???"
	
Example: * Abbreviation - In which titles such as Mr. and Dr. are correctly parsed.

	*: "Abbreviation"
	
	Include Punctuation Removal by Emily Short.

	Test me with "x me / x me. x mr. Sinister. / x rev. carl / x mrs. grey / x st. thomas / x prof. green / rev. carl, hello / rev., hello / specialist, hello / x specialist. x st. Aquinas. /  x st. x me"

	The Ecumenical Rod & Gun Club of Seventh Saint is a room. Mr Sinister is a man in Club. The printed name of Mr Sinister is "Mr. Sinister". 

	Reverend Carl is a man in Club. The printed name of Reverend Carl is "Rev. Carl". Understand "rev" as Reverend Carl. 

	St Thomas Aquinas is a man in Club. Understand "saint" as Thomas. The printed name of Aquinas is "St. Thomas Aquinas". 

	Mrs Grey is a woman in Club. The printed name of Grey is "Mrs. Grey".

	Professor Green is a man in Club. The printed name of Green is "Prof. Green". Understand "prof" as professor.

	Specialist Joan is a woman in the Club.

	After reading a command: resolve punctuated titles.

Example: ** Ownership - In which commands like EXAMINE JACK'S TIE are understood if Jack is wearing a tie, and otherwise not.

The trick here is that we want to write 

	Understand "[something related by reversed possession]'s" as a thing.

but this won't work, because Inform can't glue a token to an additional following set of characters. If, however, we make the apostrophe go away, we can match "[something related by reversed possession] s" -- an odd phrase, but one which the player is unlikely to type on his own in any other context:

	*: "Ownership"

	Include Punctuation Removal by Emily Short.
	
	Understand "[something related by reversed possession] s" as a thing.

	Jack wears a tie. Jack is in the Turret. The Turret is a room.

	After reading a command:
		remove apostrophes.
	
	Test me with "x jack's tie".

Note, though, that this kind of gambit should really be used cautiously and with awareness of what else the game is doing. If there are cases where the player should be using apostrophes, we'll want to write more restrictive rules about when to strip them away.