Version 7/140425 of Basic Screen Effects by Emily Short begins here.

"Waiting for a keypress; clearing the screen. Also provides facilities for 
changing the foreground and background colors of text, when using the z-machine.
These abilities will not function under Glulx."

Use authorial modesty.

Section - Clearing the screen

To clear the/-- screen:
	(- VM_ClearScreen(0); -).

To clear only the/-- main screen:
	(- VM_ClearScreen(2); -).

To clear only the/-- status line:
	(- VM_ClearScreen(1); -).



Section - Waiting for key-presses, quitting suddenly

Include (-

! Wait for a safe non navigating key. The user might press Down/PgDn or use the mouse scroll wheel to scroll a page of text, so we will stop those key codes from continuing.
[ KeyPause key; 
	while ( 1 )
	{
		key = VM_KeyChar();
		#Ifdef TARGET_ZCODE;
		if ( key == 63 or 129 or 130 or 132 )
		{
			continue;
		}
		#Ifnot; ! TARGET_GLULX
		if ( key == -4 or -5 or -10 or -11 or -12 or -13 )
		{
			continue;
		}
		#Endif; ! TARGET_
		rfalse;
	}
];

[ SPACEPause i;
	while (i ~= 13 or 31 or 32)
	{
		i = VM_KeyChar();	
	}
];

! No longer used but included just in case
[ GetKey;
	return VM_KeyChar(); 
];

-).

[ Note that this no longer waits for *any* key, but only safe keys. The user might press Down/PgDn or use the mouse scroll wheel to scroll a page of text, so we will stop those key codes from continuing. ]
To wait for any key:
	(- KeyPause(); -).

To wait for the/-- SPACE key:
	(- SPACEPause(); -).

Pausing the game is an activity.

To pause the/-- game:
	carry out the pausing the game activity.

For pausing the game (this is the standard pausing the game rule):
	say "[paragraph break]Please press SPACE to continue." (A);
	wait for the SPACE key;
	clear the screen.

To stop the/-- game abruptly:
	(- quit; -).

To decide what number is the chosen letter:
	(- VM_KeyChar() -).



Section - Showing the current quotation

To show the/-- current quotation:
	(- ClearBoxedText(); -);



Section - Centering text on-screen

To center (quote - text):
	(- CenterPrintComplex({quote}); -).

To center (quote - text) at the/-- row (depth - a number):
	(- CenterPrint({quote}, {depth}); -).

Include (-

[ CenterPrint str depth i j len;
	font off;
	i = VM_ScreenWidth();
	len = TEXT_TY_CharacterLength(str);
	if (len > 63) len = 63;
	j = (i-len)/2 - 1;
	VM_MoveCursorInStatusLine(depth, j);
	print (I7_string) str; 
	font on;
];

[ CenterPrintComplex str i j len;
	font off;
	print "^"; 
	i = VM_ScreenWidth();
	len = TEXT_TY_CharacterLength(str);
	if (len > 63) len = 63;
	j = (i-len)/2 - 1;
	spaces j;
	print (I7_string) str; 
	font on;
];

-).

To decide what number is screen width:
	(- VM_ScreenWidth() -).

To decide what number is screen height:
	(- I7ScreenHeight() -).

Include (-

[ I7ScreenHeight i screen_height;
	i = 0->32;
	if (screen_height == 0 or 255) screen_height = 18;
	screen_height = screen_height - 7;
	return screen_height;
];

-).



Section - Customizing the status line

To deepen the/-- status line to (depth - a number) rows:
	(- DeepStatus({depth}); -).

To move the/-- cursor to (depth - a number):
	(- I7VM_MoveCursorInStatusLine({depth}); -).

To right align the/-- cursor to (depth - a number):
	(- RightAlign({depth}); -).

Include (- 

[ DeepStatus depth i screen_width;
    VM_StatusLineHeight(depth);
    screen_width = VM_ScreenWidth();
    #ifdef TARGET_GLULX;
        VM_ClearScreen(1);
    #ifnot;
        style reverse;
        for (i=1:i<depth+1:i++)
        {
             @set_cursor i 1;
             spaces(screen_width);
        } 
    #endif;
]; 

[ I7VM_MoveCursorInStatusLine depth;
	VM_MoveCursorInStatusLine(depth, 1);
];

[ RightAlign depth screen_width o n;
	screen_width = VM_ScreenWidth(); 
	n = (+ right alignment depth +);
	o = screen_width - n;
	VM_MoveCursorInStatusLine(depth, o);
];

-).

Table of Ordinary Status
left	central	right
"[location]"	""	"[score]/[turn count]" 

Status bar table is a table-name that varies. Status bar table is the Table of Ordinary Status.

To fill the/-- status bar/line with (selected table - a table-name):
	let __n be the number of rows in the selected table;
	deepen status line to __n rows;
	let __index be 1;
	repeat through selected table:
		move cursor to __index; 
		if there is left entry:
			say "[left entry]";
		if there is central entry:
			center central entry at row __index;
		if there is right entry:
			right align cursor to __index;
			say "[right entry]";
		increase __index by 1;

Right alignment depth is a number that varies. Right alignment depth is 14.



Section - Color effects (for Z-machine only)

To say default letters:
	(- @set_colour 1 1; -)

To say red letters:
	(- @set_colour 3 0; -)

To say green letters:
	(- @set_colour 4 0; -)

To say yellow letters:
	(- @set_colour 5 0; -)

To say blue letters:
	(- @set_colour 6 0; -)

To say magenta letters:
	(- @set_colour 7 0; -)

To say cyan letters:
	(- @set_colour 8 0; -)

To say white letters:
	(- @set_colour 9 0; -)

To say black letters:
	(- @set_colour 2 0; -)

To turn the/-- background black:
	(- @set_colour 0 2; -);

To turn the/-- background red:
	(- @set_colour 0 3; -);

To turn the/-- background green:
	(- @set_colour 0 4; -);

To turn the/-- background yellow:
	(- @set_colour 0 5; -);

To turn the/-- background blue:
	(- @set_colour 0 6; -);

To turn the/-- background magenta:
	(- @set_colour 0 7; -);

To turn the/-- background cyan:
	(- @set_colour 0 8; -);

To turn the/-- background white:
	(- @set_colour 0 9; -);

Basic Screen Effects ends here.



---- DOCUMENTATION ----

Basic Screen Effects implements the following effects: pauses to wait for a keypress from the player; clearing the screen; changing the color of the foreground font; and changing the color of the background. Color changes function only on the Z-machine.

Chapter: Pauses, screen-clearing, and specially-placed text

Section: Clearing the screen

The following phrases are defined:

To clear the entire screen of everything it contains, including the status line,

	clear the screen.

To clear only one section of the screen, we also have:

	clear only the main screen.
	clear only the status line.
	
Section: Waiting for key-presses; quitting suddenly

To produce a pause until the player types any key:

	wait for any key.

To produce a pause until the player types SPACE, ignoring all other keys:

	wait for the SPACE key.

To give the player a message saying to press SPACE to continue, wait for a keypress, and then clear the screen before continuing the action:

	pause the game.

In extreme cases, we may want to end the game without allowing the player an opportunity to RESTART, RESTORE, or QUIT; to this end:

	stop game abruptly.
	
Section: Showing the current quotation

Show the current quotation displays whatever the author has selected with "display the boxed quotation...". Ordinarily boxed quotations appear when the prompt is printed, but this allows the author to show a boxed quote at another time. To achieve a splash-screen before the game proper begins, we could do something like this:

	When play begins:
		display the boxed quotation 
		"What's this room? I've forgotten my compass.
		Well, this'll be south-south-west parlour by living room.
		-- Philadelphia Story";
		show the current quotation;
		pause the game.
		
Section: Centering text on-screen

Similarly, we can display a phrase centered in the middle of the screen but without the background-coloration of the boxed quotation, like this:

	center "The Merchant of Venice";

Centering text puts the text on its own new line, since it would not make much sense otherwise. Note that centered text will always be set to fixed-width; font stylings such as bold and italic will not work. (If they did, they would throw off the centering; the screen model is insufficiently sophisticated to deal with centering non-fixed-width letters.)

If we want to make our own calculations using this information, the width of the screen can be checked at any time, like so:

	if the screen width is less than 75, say "The map will not display properly until you widen your screen." instead.
	
Section: Customizing the status line

We can also use a variation of the center command to position text in the status line. To produce a Trinity-style status line with the location, centered:

	Rule for constructing the status line:
		center "[location]" at row 1;
		rule succeeds.

For status lines of more than one row, we can create a table representing the overall appearance of the desired status line and then set that table as our status bar table. The following would build a two-line status bar with all sorts of information in it. (For a more practical demonstration involving a three-line compass rose, see the example below.)
 
	Table of Fancy Status
	left	central	right 
	" [location]"	"[time of day]"	"[score]"
	" [hair color of the suspect]"	"[eye color of the suspect]"	"[cash]"

	Rule for constructing the status line:
		fill status bar with Table of Fancy Status;
		rule succeeds.
 
A status bar table must always have left, central, and right columns, and we must provide the rule for constructing the status line. Otherwise, Inform will use the default status line behavior. The position of the right hand side is set to 14 spaces from the end by default (matching Inform's default status line), but it is possible to change this by altering the value of the variable called right alignment depth; so we might for instance say

	When play begins: now right alignment depth is 30.

for the purpose of moving what is printed on the right side inward. Note that right alignment depth will only affect the behavior of status bar tables of the kind described here; it will have no effect on Inform's default handling of the right hand status line variable.

Chapter: Color effects (available on the Z-machine only)

Section: Changing the background color

To turn the background black (or red, green, yellow, blue, white, magenta, or cyan):

	turn the background black. 
	turn the background red. 

...and so on. This only applies to what is typed from that point in the game onward. If we wish to turn the entire background a new color at once (and this is usually desirable), we should set the background and then clear the screen, so:

	turn the background black;
	clear the screen.

Section: Changing the font color

Finally, font colors can be changed with say (color) letters, where the same range of colors may be used as for the background. So for instance

	say "There is a [red letters]piping hot[default letters] pie on the table."

We should be careful with color effects. Some older interpreters do not deal well with color, and part of the audience plays interactive fiction on black and white devices or via a screenreader. The phrase "say default letters" restores whatever background and foreground are normal on this system. It is not safe to assume that the player is necessarily using one particular color scheme; black-on-white, white-on-black, and white-on-blue are all relatively common.

Finally, as hinted by the section title, these color effects only work when compiling to the Z-machine. Glulx has a different and not exactly symmetrical way of handling fonts and colors, which takes a bit more setting up; if we want color effects for Glulx, we should look at the extension Glulx Text Effects, also included with Inform. 

Thanks to Eric Eve for the biplatform patches to this extension.

Example: * The High Note - Faking the player typing a specific command at the prompt.

A gimmick used occasionally in IF is to offer the player a command prompt, but then to force a specific command -- that is, whatever keystrokes the player makes, to print the command we want him to type, and then carry on with the game as though he had done so. The trick is that we're not really offering a command line at all; we just print the prompt, wait for a keystroke, print the first letter of our command, wait for another keystroke, print the next letter, and so on, until the player has hit enough keys to have "typed" the command we wanted him to type.

This is an easily overused effect, but here is how we might do it, using Basic Screen Effects: 

	*: "The High Note"

	The Edge of the Stage is a room.

	When play begins:
		say "You stand in the footlights, looking out over the assembled multitude, dimly recognizing the Grand Duke seated in his box, and the Grand Duke's mistress in hers; and try to remember (through two bottles of brandy and an ill-advised champagne) how your part begins. You've relied often enough on sheer instinct to carry you through; but this time might just be the time it fails... [line break]";
		fake command;
		say "Yes: the high C . It begins there...";
		pause the game.

	Include Basic Screen Effects by Emily Short.

	To fake command:
		say "[line break][command prompt] [bold type]";
		wait for any key;
		say "s";
		wait for any key;
		say "i";
		wait for any key;
		say "n";
		wait for any key;
		say "g";
		wait for any key;
		say roman type;
		say line break; 
		
We could rig this up more elegantly, if we were going to do it a lot, with tables of characters to print or something along those lines; but this shows clearly how the trick works. 

The example is included because several authors have expressed interest in doing this, but it's worth being a little cautious about -- the more games use such a ploy, the less surprising and interesting the gimmick becomes for the player.

Example: ** Pillaged Village - A status bar showing unvisited rooms in a colored compass rose.

Note that attempting to compile this example for Glulx will fail, because it uses color effects available only on the Z-machine.

	*: "Pillaged Village" by Lars Thurgoodson.
	
	Include Basic Screen Effects by Emily Short.

	The story headline is "An interactive looting".

	The Viking Longship is west of the Seashore. The Seashore is west of the Burning Village. The Shrine of the Green Man is northwest of the Burning Village. The Shattered Fort is southwest of the Burning Village. The Treetop is above the Shrine.

	When play begins:
		center "[story title]";
		center "[story headline]";
		center "by [story author]";
		leave space;
		center "Press SPACE to begin.";
		wait for the SPACE key;
		clear the screen;
		leave space.

	To turn screen black:
		say white letters;
		turn the background black;
		clear the screen;
		leave space;
	
	To turn screen white:
		turn the background white;
		say black letters;
		clear the screen;
		leave space.

	To leave space:
		say paragraph break;
		say paragraph break;
		say paragraph break;
		say paragraph break. 
	
	Table of Fancy Status
	left	central	right 
	" [if in darkness]Darkness[otherwise][location][end if]"	""	"[top rose]"
	" "	""	"[middle rose]"
	" Rooms searched: [number of rooms which are visited]/[number of rooms]"	""	"[bottom rose]"
 	
	To say red reverse:
		turn the background red.
		
	To say black reverse:
		turn the background black.
	
	To say white reverse:
		turn the background white. 

	To say rose (way - a direction):
		let place be the room way from the location;
		if the place is a room, say "[if the place is unvisited][red reverse][end if][way abbreviation][default letters]"; otherwise say "[way spacing]"; 

	To say (way - a direction) abbreviation:
		choose row with a chosen way of way in the Table of Various Directions;
		say abbrev entry.
		
	To say (way - a direction) spacing:
		choose row with a chosen way of way in the Table of Various Directions;
		say spacing entry.

	Table of Various Directions
	chosen way	abbrev	spacing
	up	"U   "	"    "
	northwest	"NW"	"  "
	north	" N "	"    "
	northeast	"NE"	"  "
	east	" E"	"  "
	west	"W "	"  "
	southeast	"SE"	"  "
	south	" S "	"   "
	southwest	"SW"	"  "
	down	"D   "	"    "
		
	To say top rose:
		say "[rose up][rose northwest][rose north][rose northeast]".
	
	To say middle rose: 
		say "    [rose west] . [rose east]"; 
	
	To say bottom rose:
		say "[rose down][rose southwest][rose south][rose southeast]".
	 	
	Rule for constructing the status line:
		fill status bar with Table of Fancy Status;
		say default letters;
		rule succeeds.

