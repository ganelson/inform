Version 3 of Menus by Emily Short begins here.

"A table-based way to display full-screen menus to the player."

Use authorial modesty.

Include Basic Screen Effects by Emily Short.

Section 1

Menu depth is a number that varies. Menu depth is 0.

The endnode flag is a number that varies. The endnode flag is 0.

The current menu title is text that varies. The current menu title is "Instructions".

Table of Sample Options
title	subtable (table name)	description	toggle
"foo"	--	"bar"	a rule

Current menu is a table name that varies. The current menu is the Table of Sample Options.

Current menu selection is a number that varies. Current menu selection is 1.

Table of Menu Commands
number	effect
78	move down rule
110	move down rule
80	move up rule
112	move up rule
81	quit rule
113	quit rule
13	select rule
32	select rule
130	move down rule
129	move up rule
27	quit rule

This is the quit rule:  
	decrease the menu depth by 1;
	rule succeeds. 

This is the move down rule: 
	if current menu selection is less than the number of filled rows in the current menu, increase current menu selection by 1;
	reprint the current menu;
	make no decision.

This is the move up rule:
	if current menu selection is greater than 1, decrease current menu selection by 1;
	reprint the current menu;
	make no decision.

This is the select rule:  
	choose row current menu selection in the current menu;
	if there is a toggle entry
	begin;
		follow the toggle entry; reprint the current menu;
	otherwise;
		if there is a subtable entry
		begin;
			now the current menu title is title entry;
			now the current menu selection is 1; 
			now the current menu is subtable entry;
			show menu contents;
		otherwise;
			let the temporary title be the current menu title;
			now the current menu title is title entry;
			now the endnode flag is 1;
			redraw status line;
			now the endnode flag is 0;
			clear only the main screen;
			say "[variable letter spacing][description entry][paragraph break]";
			pause the game;
			now the current menu title is temporary title;
			reprint the current menu;
		end if;
	end if.
	

To redraw status line:
	(- DrawStatusLine(); -)

Displaying is an activity.

To reprint (selected menu - a table name):
	redraw status line;
	say fixed letter spacing;
	let __index be 1;
	clear only the main screen;
	repeat through selected menu
	begin;
		if __index is current menu selection, say " >"; otherwise say "  ";
		say " [title entry][line break]";
		increase __index by 1;
	end repeat;
	say variable letter spacing;

To show menu contents:
	increase the menu depth by 1;
	let temporary depth be the menu depth;
	let temporary menu be the current menu;
	let temporary title be the current menu title;
	let __x be 0;
	let __index be 0;
	while __index is not 1
	begin;
		now the current menu is the temporary menu; 
		let __n be 0;
		repeat through current menu
		begin;
			increase __n by 1;
			if title entry is current menu title, now current menu selection is __n;
		end repeat;
		now the current menu title is the temporary title; 
		reprint current menu;
		let __x be the chosen letter;
		if __x is a number listed in the Table of Menu Commands
		begin;
			follow the effect entry; 
			if temporary depth > menu depth
			begin;
				now __index is 1; 
			end if;
		end if;
	end while.

Rule for displaying (this is the basic menu contents rule): 
	now current menu selection is 1;
	show menu contents.

Rule for constructing the status line while displaying (this is the constructing status line while displaying rule):  
	if the endnode flag is 0,
		fill status bar with Table of Deep Menu Status;
	otherwise fill status bar with Table of Shallow Menu Status; 
	rule succeeds.

Table of Shallow Menu Status
left	central	right
""	"[current menu title]"	""


Table of Deep Menu Status
left	central	right
""	"[current menu title]"	""
""	""	" "
" N = Next"	""	"Q = [if menu depth > 1]Last Menu[otherwise]Quit Menu[end if]"
" P = Previous"	""	"ENTER = Select"

Table of Sample Hints
hint	used
"Sample Hint"	a number

To say known hints from (hint booklet - table name):
	let __index be 0;
	clear only the main screen; 
	repeat through hint booklet
	begin;
		increase __index by 1;
		if there is a used entry
		begin;
			say "[__index]/[number of rows in hint booklet]: [hint entry][paragraph break]";
		otherwise;
			if __index is 1
			begin;
				now used entry is turn count;
				say "[__index]/[number of rows in hint booklet]: [hint entry][paragraph break]";
			end if;
		end if;
	end repeat; 
	say "Press SPACE to return to the menu or H to reveal another hint."


To say hints from (hint booklet - table name): 
	let __index be 0;
	clear only the main screen; 
	repeat through hint booklet
	begin;
		increase __index by 1;
		say "[__index]/[number of rows in hint booklet]: [hint entry][paragraph break]"; 
		if there is a used entry
		begin;
			do nothing;
		otherwise;
			now used entry is turn count;
			say "Press SPACE to return to the menu[if __index < number of rows in hint booklet] or H to reveal another hint[end if].";
			make no decision; 
		end if;  
	end repeat; 
	say "Press SPACE to return to the menu[if __index < number of rows in hint booklet] or H to reveal another hint[end if]."

This is the hint toggle rule:
	choose row current menu selection in the current menu;
	let the temporary title be the current menu title;
	now the current menu title is title entry;
	now the endnode flag is 1;
	redraw status line;
	now the endnode flag is 0;
	say known hints from the subtable entry; 
	let __index be 0;
	while __index < 1
	begin;
		let __x be the chosen letter;
		if __x is 13 or __x is 31 or __x is 32, let __index be 1;
		if __x is 72 or __x is 104, say hints from the subtable entry;
	end while;
	now the current menu title is temporary title.

Section 2 (for Glulx only) 

Table of Menu Commands (continued)
number	effect
-8		quit rule
-6		select rule
-5		move down rule
-4		move up rule

Menus ends here.

---- Documentation ----

"Menus" provides a table-based way to display menus to the player. The menu takes over the main screen of the game and prevents parser input while it is active. 

"Menus" is not suitable for contexts where we want the player to be able to choose a numbered option during regular play (such as a menu of conversation choices when talking to another character). It is intended rather for situations where we wish to give the player optional instructions or hints separated from the main game.

Any given menu option may do one (and only one) of the following three things:

1) display some text to the player, after which he can press a key to return to the menu. This tends to be useful for such menu options as "About this Game" and "Credits", where we have a few paragraphs of information that we would like to share.

2) trigger a secondary menu with additional options. The player may navigate this submenu, then return to the main menu. Submenus may be nested.

3) carry out a rule. This might perform any action, including making changes to the game state.

Menus are specified by tables, in which each row contains one of the menu options, together with instructions to Inform about how to behave when that option is selected. 

Each menu table should have columns called "title", "subtable", "description", and "toggle". 

"Title" should be the name of the option we want the player to see: "Credits", "Hints", "About This Game", and so on.

"Description" is the text that will be printed when the option is selected. We can fill it in with as much information as we like.

"Subtable" is used to create a submenu; this column holds the name of the table that specifies the menu. For instance:

	Table of Options
	title	subtable	description	toggle
	...
	"Settings"	Table of Setting Options	--	--

would create an option entitled "Settings", which the player could select to view a submenu of setting options. That submenu would in turn need its own table, thus

	Table of Setting Options
	title	subtable	description	toggle
	...

If we do not want a given option to trigger a new submenu, we should leave it as "--".

The "toggle" column contains the rule carried out when this option is chosen. In theory, this rule could be absolutely anything. In practice, the feature is mostly useful for giving the player a table of setting options which he can toggle on and off: for instance, we might provide the option "use verbose room descriptions", and then have the toggle rule change the game's internal settings about how room descriptions are displayed. (See the example attached for further guidance.)

It is only useful for a given option to have one of these three features -- a description or a subtable or a toggle element. In the event that more than one column is filled out, the game will obey the toggle rule in preference to creating a submenu, and create a submenu in preference to displaying description text. 

Example: * Tabulation - A simple table of hints and help (see also Basic Help Menu).

For instance our Table of Options might look like this:

	*: "Tabulation" by Secretive J.
	
	Include Menus by Emily Short.

	Table of Options
	title	subtable (table name)	description	toggle
	"Introduction to [story title]"	--	"This is a simple demonstration [story genre] game."	a rule
	"Settings"	Table of Setting Options	--	--
	"About the Author"	--	"[story author] is too reclusive to wish to disseminate any information. Sorry."	--
	"Hints"	Table of Hints	--	--

	Table of Setting Options
	title	subtable (table name)	description	toggle
	"[if notify mode is on]Score notification on[otherwise]Score notification off[end if]"	--	--	switch notification status rule

	To decide whether notify mode is on:
		(- notify_mode -);

	This is the switch notification status rule:
		if notify mode is on, try switching score notification off;
		otherwise try switching score notification on.

	[After each activation of the toggle rule, the menu redraws itself, so the player will see "score notification on" change to "score notification off" (and vice versa).]

	[Menus also provides for the case where we would like to display hints and give the player the option of revealing more and more detailed instructions. To this end, there is a special form for tables that lead to hints and tables which contain the hints themselves. The table leading to hints should look like this:]

	Table of Hints
	title	subtable	description	toggle
	"How do I reach the mastodon's jawbone?"	Table of Mastodon Hints		""	hint toggle rule
	"How can I make Leaky leave me alone?"	Table of Leaky Hints	""	hint toggle rule

	[where the toggle is always "hint toggle rule", and the subtable is always a table containing the hints themselves. A table of hints consists of just two columns, and one of those is for internal bookkeepping and should be initialized to contain a number. So:]

	Table of Mastodon Hints
	hint	used
	"Have you tried Dr. Seaton's Patent Arm-Lengthening Medication?"	a number
	"It's in the pantry."
	"Under some cloths."	

	Table of Leaky Hints
	hint	used
	"Perhaps it would help if you knew something about Leaky's personality."
	"Have you read the phrenology text in the library?"	
	"Have you found Dr. Seaton's plaster phrenology head?"	
	"Now you just need a way to compare this to Leaky's skull."	
	"Too bad he won't sit still."	
	"But he has been wearing a hat. Perhaps you could do something with that."
	"You'll need to get it off his head first."	
	"Have you found the fishing pole?"	
	"And the wire?"	
	"Wait on the balcony until Leaky passes by underneath on his way to the Greenhouse."	
	"FISH FOR THE HAT WITH THE HOOK ON THE WIRE."	
	"Now you'll have to find out what the hat tells you."	
	"Putting it on the phrenology head might allow you to compare."	
	"Of course, if you do that, you'll reshape the felt. Hope you saved a game!"
	"You need a way to preserve the stiffness of the hat."	
	"Have you found the plaster of paris?"	
	"And the water?"	
	"And the kettle?"	

	[...etc. (Hints 19-135 omitted for brevity.)]

	[Because the toggle rule is always consulted when the player selects an option and before any other default behavior occurs, we can use this rule to override normal menu behavior more or less however we like. The hint toggle rule is just one example.]

	[Finally, if we wanted to create a HELP command that would summon our menu, we would then add this:]

	Understand "help" or "hint" or "hints" or "about" or "info" as asking for help.

	Asking for help is an action out of world.
	
	Carry out asking for help:
		now the current menu is the Table of Options; 
		carry out the displaying activity;
		clear the screen;
		try looking.
		
	The Cranial Capacity Calculation Chamber is a room. Leaky is a man in the Chamber. Leaky wears a pair of overalls and some muddy boots. He is carrying a fishing rod.

The displaying activity displays whatever is set as the current menu, so we must set the current menu before activating the activity. Afterward it is a good idea to clear the screen before returning to regular play.