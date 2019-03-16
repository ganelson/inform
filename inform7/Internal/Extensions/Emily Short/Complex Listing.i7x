Version 9 of Complex Listing by Emily Short begins here.

"Complex Listing provides more sophisticated listing options: the ability to impose special ordering instructions on a list, and also the ability to change the delimiters of the list to produce different styles and effects."

[This version adds responses to its single rule, slightly updates the examples, and provides a new implementation of "order list by length" that takes into account that indexed text is now the same as regular text.]

Use authorial modesty.

Table of Scored Listing
output	assigned score
an object	a number
with 30 blank rows.
 
To empty out (selected table - a table-name):
	repeat through selected table
	begin;
		blank out the whole row;
	end repeat. 
		
An object can be marked for special listing or unmarked for special listing. An object is usually unmarked for special listing.
	
To prepare a/the/-- list of (selection - description of objects):
	now every thing is unmarked for special listing;
	now every direction is unmarked for special listing;
	now every room is unmarked for special listing;
	now every region is unmarked for special listing;
	repeat with item running through members of the selection:
		now the item is marked for special listing;
	register things marked for listing.
 
To register the/-- things marked for listing:
	empty out the Table of Scored Listing;
	repeat with item running through directions which are marked for special listing:
		choose a blank row in the Table of Scored Listing;
		now output entry is the item; 
		now item is unmarked for special listing; 
	repeat with item running through rooms which are marked for special listing:
		choose a blank row in the Table of Scored Listing;
		now output entry is the item; 
		now item is unmarked for special listing; 
	repeat with item running through things which are marked for special listing:
		choose a blank row in the Table of Scored Listing;
		now output entry is the item; 
		now item is unmarked for special listing.

Articulation style is a kind of value. The articulation styles are bare, definite and indefinite. The current articulation style is an articulation style that varies.

To say is-are the prepared list:
	now current articulation style is definite;
	say tabled verb;
	say prepared list.

To say is-are a prepared list:
	now current articulation style is indefinite;
	say tabled verb;
	say prepared list.

To say is-are prepared list:
	now current articulation style is bare;
	say tabled verb;
	say prepared list.

To say tabled verb:
	if the number of filled rows in the Table of Scored listing is greater than 1, say "are ";
	otherwise say "is ";

To say the prepared list:
	now current articulation style is definite;
	say prepared list.
	
To say a prepared list:
	now current articulation style is indefinite;
	say prepared list. 

To say prepared list:
	if the number of filled rows in the Table of Scored Listing is 0:
		say "nothing";
		rule fails;
	dump list;
	now current articulation style is bare.

To say prepared list delimited in (chosen style - a list style) style:
	now current articulation style is indefinite;
	now current list style is the chosen style;
	say prepared list.

To say a prepared list delimited in (chosen style - a list style) style:
	now current articulation style is indefinite;
	now current list style is the chosen style;
	say prepared list.

To say the prepared list delimited in (chosen style - a list style) style:
	now current articulation style is definite;
	now current list style is the chosen style;
	say prepared list.

To say is-are prepared list delimited in (chosen style - a list style) style:
	now current articulation style is indefinite;
	now current list style is the chosen style;
	say tabled verb;
	say prepared list.

To say is-are a prepared list delimited in (chosen style - a list style) style:
	now current articulation style is indefinite;
	now current list style is the chosen style;
	say tabled verb;
	say prepared list.

To say is-are the prepared list delimited in (chosen style - a list style) style:
	now current articulation style is definite;
	now current list style is the chosen style;
	say tabled verb;
	say prepared list.
	
To dump list:
	carry out the list arranging activity;
	say list of the Table of Scored Listing;
	now current list style is sequential;
	empty out Table of Scored Listing.
	
List arranging is an activity.

Rule for list arranging: 
	sort Table of Scored Listing in assigned score order.

To invert scored list:
	sort Table of Scored Listing in reverse assigned score order.
	
First delimiter is text that varies. Second delimiter is text that varies. Alternate second delimiter is text that varies. First delimiter is ", ". Second delimiter is ", and ". Alternate second delimiter is " and ".

List style is a kind of value. The list styles are defined by the Table of List Style Assignments.

Current list style is a list style that varies. 

Table of List Style Assignments
list style	first delimiter	second delimiter	alternate second delimiter	indefinite name phrase	definite name phrase
sequential	", "	"[if the serial comma option is active],[end if] and "	" and "	"[a current listed object]"	"[the current listed object]"
disjunctive	", "	"[if the serial comma option is active],[end if] or "	" or "	"[a current listed object]"	"[the current listed object]"
semi-colon	"; "	"; "	" and "	"[a current listed object]"	"[the current listed object]"
comma	", "	", "	" and "	"[a current listed object]"	"[the current listed object]"
null	" "	" "	" and "	"[current listed object]"	"[current listed object]"
hyperconnective	" and "	" and "	" and "	"[a current listed object]"	"[the current listed object]"
fragmentary	". "	". "	". "	"[A current listed object]"	"[The current listed object]" 
enumerated	"; "	"; "	"; "	"([current enumeration]) [a current listed object]"	"([current enumeration]) [the current listed object]"

To decide what number is the current enumeration:
	let N be 1 + current listing total;
	decrease N by current listing index;
	decide on N.

To order list by length:
	repeat through Table of Scored Listing:
		let name be the printed name of the output entry;
		let count be the number of characters in name;
		now assigned score entry is count.

Current listing total is a number that varies. Current listing index is a number that varies. Current listed object is an object that varies.

To say a/the/-- list of (selected table - a table-name): 
	now current listing total is the number of filled rows in the selected table;
	now current listing index is current listing total;
	repeat through selected table:
		now current listed object is output entry;
		let wording be "";
		if the current articulation style is definite:
			let wording be the definite name phrase corresponding to a list style of the current list style in the Table of List Style Assignments;
		otherwise:
			let wording be the indefinite name phrase corresponding to a list style of the current list style in the Table of List Style Assignments;
		if the current listed object is a direction:
			say "[current listed object]";
		otherwise if the current articulation style is bare:
			say "[current listed object]";
		otherwise:
			say "[wording]";
		decrease current listing index by 1;
		carry out the delimiting a list activity.

Delimiting a list is an activity.

Rule for delimiting a list (this is the standard delimiting rule):
	choose row with list style of current list style in the Table of List Style Assignments;
	if current listing index is 1:
		if current listing total > 2, say "[second delimiter entry]" (A);
		otherwise say "[alternate second delimiter entry]" (B);
	otherwise:
		if current listing index > 0, say "[first delimiter entry]" (C).

Complex Listing ends here.

---- DOCUMENTATION ----

Complex Listing provides two significant abilities: the ability to change the way a list is delimited (that is, to use semi-colons, sentence fragments, dashes, or othermore exotic techniques, instead of the usual commas with a final "and"); and the ability to determine an ordering for the list according to criteria of our choosing.

(Because Complex Listing is relatively powerful, the complete description of what it does may be a bit daunting, especially for less experienced users. It may be more congenial to skip down to the examples and then return to the full instructions later.)

Chapter: Basic listing features

There are three stages to setting up and printing a complex list: marking the items we are going to include; arranging the list in order; and printing the list.

Section: Preparing a list

First we must

	prepare a list of (whatever criteria)
	
For instance, we might say

	prepare a list of furry animals which are visible.
	
This marks the items that are going to be in our list. If we prefer, we may also do this task by hand by changing the desired items to "marked for special listing" (and undesired items to "unmarked for special listing"). If we do the task by hand, we must finish with 

	register things marked for listing.

This sets up a table, called the Table of Scored Listing, which contains all the items that we are going to describe in our list, in two columns: output (the thing that is going to be named) and assigned score (the value we've given this item to order it with respect to everything else). (In versions prior to version three, it was necessary to register things marked for listing even after preparing a list. This is no longer the case.)

Things marked for listing are registered automatically if we say "prepare a list of...".

Section: Ordering the list

At this point we may optionally choose to arrange the list in order in some way. One approach is to write our own phrase to go through the Table of Scored Listing and assign scores to each item. 

For instance, we might write a phrase to order the Table of Scored Listing according to the monetary value of items, their current relevance to the plot, their size, etc., etc., etc. -- it can be anything we want to include for the purpose of adding nuance to the descriptive prose. We can already

	order list by length.
	
to arrange according to the number of letters in the name of the item. (This is built into the extension not because it is inherently more interesting than all the other ordering principles we might apply, but because it is mildly annoying to program, so it seemed best to provide it pre-written.)

The list arranging activity automatically sorts the Table according to its assigned score entry, but like all activities this can be overwritten if we would rather do something else; so that one could instruct the list arranging activity to sort the table randomly or in inverse order, if so desired.

Section: Printing the list

Now we're ready to use the list, which we may do by saying "[prepared list]". At that point the items in the list will be printed in the order we have established (without any article, matching the behavior of "[list]"), and the table cleared. Failing to prepare the table properly before listing it may cause bugs, though if it finds itself entirely empty it will say "nothing" rather than giving run-time errors. There are the following variants as well:

	say "[the prepared list]."
	say "[a prepared list]."
	
which tell Inform to use definite or indefinite articles; and 

	say "[is-are the prepared list]."
	say "[is-are a prepared list]."
	say "[is-are prepared list]."

which add the appropriate verb, just as with regular list-saying.

Chapter: Customizing Complex Listing

Section: The concept of list styles

This is also the juncture at which we may change the delimiters of the text. Complex Listing has a Table of List Style Assignments which lists different ways in which a list may be configured, and it may be reasonable simply to show what this looks like: 

	Table of List Style Assignments
	list style	first delimiter	second delimiter	alternate second delimiter	indefinite name phrase	definite name phrase
	sequential	", "	"[if the serial comma option is active],[end if] and "	" and "	"[a current listed object]"	"[the current listed object]"
	disjunctive	", "	"[if the serial comma option is active],[end if] or "	" or "	"[a current listed object]"	"[the current listed object]"
	semi-colon	"; "	"; "	" and "	"[a current listed object]"	"[the current listed object]" 
	comma	", "	", "	" and "	"[a current listed object]"	"[the current listed object]"
	null	" "	" "	" and "	"[current listed object]"	"[current listed object]"
	hyperconnective	" and "	" and "	" and "	"[a current listed object]"	"[the current listed object]"
	fragmentary	". "	". "	". "	"[A current listed object]"	"[The current listed object]" 
	enumerated	"; "	"; "	"; "	"([current enumeration]) [a current listed object]"	"([current enumeration]) [the current listed object]"

The first delimiter appears between all but the last pair of items in a list. The second delimiter appears between the last pair of items in a list of three or more things; and the alternate second delimiter appears between the last pair in a list of exactly two things. (This is because we may want "the fish and the donkey" but "the cat, the fish, and the donkey".) 

The indefinite name phrase instructs Inform in how to say the name of the object if there's an indefinite article, and the definite name phrase if there's a definite article. Notice that this is not wholly consistent, because, for instance, in fragmentary-style listing each item receives its own sentence fragment and a capitalized definite article, rather than the usual uncapitalized one.

Section: Pre-defined list styles

"Sequential" is the default mode of listing and conforms with Inform's usual "thing, thing, thing[,] and thing" list style. It obeys the serial comma use option just as ordinary listing does. If no delimiter is specified, the list will be written in this manner. "Disjunctive" style, though not very flashy, is likely to be the most useful alternate mode, since it replaces the usual "and" with an "or", appropriate for offering the player options or asking him questions. Most of the others are perhaps self-explanatory. "Enumerated" presents a list with each element numbered, and "[current enumeration]" may be used elsewhere to indicate the number of the item currently being listed.

To pick a special delimiter, we use phrases like

	say " [the prepared list delimited in comma style]."
	say " [a prepared list delimited in hyperconnective style]."

and we may also add our own variations simply by continuing the table in our own code.

Section: Delimiting the list in our own way

Of course, there are times when even this does not give adequate flexibility. This whole process is carried out by the "delimiting a list" activity, and if we want, we can write our own rules for delimiting a list. The current version looks like this:

	Rule for delimiting a list (this is the standard delimiting rule):
		choose row with list style of current list style in the Table of List Style Assignments;
		if current listing index is 1
		begin;
			if current listing total > 2, say "[second delimiter entry]";
			otherwise say "[alternate second delimiter entry]";
		otherwise;
			if current listing index > 0, say "[first delimiter entry]";
		end if.

But if we liked we could replace this with more complicated logic to apply under some circumstances; for instance, instructions to group items in different numbers of combinations so that we generate lists like "a chicken, a horse, a duck; a red hen; a heron." This gets increasingly detailed and picky, but provides significant leverage towards writing routines that will generate human-like prose.

Section: Say list of... and Empty out... phrases

In the providing these functions, Complex Listing also defines some other phrases that the author may find useful even when not actually saying prepared lists.

	say list of (any table name)
	
will do the printing-and-delimiting on any table name containing an output column, in case we want to write lists of objects from some other table. And then

	empty out (any table name)

strips blank every entry of every row of that table, and should not be used casually.

Example: * Which of These Things Is Not Like the Others? - Arranging items in room descriptions so that the most unusual objects are always at the back of the list.

A common descriptive strategy in listing numerous objects is to save the most astonishing or interesting items for last. In this example, we arrange it so that the most peculiar items in a room are always included at the end of the list, no matter in what order they have been taken or dropped.

	*: "Which of These Things is Not Like the Others?"

	Include Complex Listing by Emily Short. 

	Use the serial comma.

	Rule for writing a paragraph about something:
		prepare a list of the unmentioned other things in the location; 
		set off the odd things;
		say "[We] [can] see here [a prepared list]."
		 
	Definition: a thing is other if it is not the player.
	
	To set off the odd things:
		repeat through the Table of Scored Listing:
			if the output entry is at home, now the assigned score entry is 0;
			otherwise now the assigned score entry is 1;
			if the output entry is the skull, now the assigned score entry is 10.

	Definition: a thing is at home if the location of it suits it. Definition: a thing is astonishing if it is not at home.

	Suitability relates one room to various things. The verb to suit (it suits, they suit, it suited, it is suited) implies the suitability relation.

	The Schoolroom is a room. The pencil, the paper, the eraser, and the clipboard are things in the Schoolroom. The Schoolroom suits the pencil, the paper, the eraser, the clipboard, and the social studies textbook.

	The social studies textbook is in the Hall. The Hall is west of the Schoolroom. The poster of the principal is in the Hall. The Hall suits the poster and the discarded pass. 

	The Cafeteria is west of the Hall. The lunch tray, the carton of chocolate milk, and the discarded pass are in the Cafeteria. The Cafeteria suits the tray and the milk.

	The polished skull is in the Cafeteria.

	Test me with "get all / w / drop all / look / get all / w / drop all / look".

Example: * Taxidermy - Arranging a list so that the items in the list are presented in order from shortest name to longest name, and separated by commas with no "and".

	*: "Taxidermy"

	Include Complex Listing by Emily Short.

	The Stuffed Room is a room. "Your father's study, a taxidermist's retreat, in which he could withdraw from the noisy, tumultuous presence of the living. Sometimes you would catch him in here walking from object to object, gently rubbing more fur off the balding heads, even once kissing the nose of a formaldehyded moose; which made you doubt whether you could ever compete for his attention, even when standing very very very still." An aardvark, a capybara, a dingo, an iguana, a joey are in the Stuffed Room.

	Use the serial comma.

	Rule for writing a paragraph about something in the Stuffed Room:
		say "Your eye is drawn inexplicably to [a random other thing in the Stuffed Room], about which there hovers, however briefly, a kind of holy significance, a spiritual spotlight. ";
		prepare a list of the unmentioned other things in the Stuffed Room; 
		order list by length;
		say "What here can compare: [the prepared list delimited in comma style]?"
	 	
	Definition: a thing is other if it is not the player.
	
	Test me with "look / get joey / look / drop all".

Example: * Split Lark - Adding a delimiter so that items in a list can be set off from one another with dashes.

Imagine we've gotten the (somewhat frightening) idea of writing a game about Emily Dickinson, in appropriate narrative style. Obviously, mere commas are not up to the task, so we add a new entry to the Table of List Style Assignments:

	*: "Split Lark"

	Include Complex Listing by Emily Short. 

	Use the serial comma.

	Table of List Style Assignments (continued)
	list style	first delimiter	second delimiter	alternate second delimiter	indefinite name phrase	definite name phrase
	dashed	" -- "	" -- and then "	" -- and -- "	"[a current listed object]"	"[the current listed object]"

	Instead of taking inventory:
		prepare a list of things carried by the player; 
		say "Your possessions are few and small -- in your hands [is-are a prepared list delimited in dashed style]."
	 	
	Definition: a thing is other if it is not the player.

	The Grassy Field is a room. The player carries a pencil and a roll of music, food for two birds.
	
	Test me with "i / drop pencil / i / drop all / i".
	
Ideally we would also check to see whether the player was carrying anything before printing that "few and small" bit. But we leave it out here so that we can also see what Complex Listing does when it hits an empty list -- namely, print "nothing", just as the regular lister does.