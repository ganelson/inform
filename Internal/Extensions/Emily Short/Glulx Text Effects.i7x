Version 5/140516 of Glulx Text Effects (for Glulx only) by Emily Short begins here.

"Gives control over text formatting in Glulx."

[ Version 5 was rewritten by Dannii Willis ]

Use authorial modesty.



Chapter - Specifying styles

[ It is important that the values be specified precisely in the following orders, because otherwise the I6 assumptions about the relation of named values to number constants will be wrong. ]

A glulx text style is a kind of value.
The glulx text styles are all-styles, normal-style, italic-style, fixed-letter-spacing-style, header-style, bold-style, alert-style, note-style, blockquote-style, input-style, special-style-1 and special-style-2.

A text justification is a kind of value.
The text justifications are left-justified, left-right-justified, center-justified, and right-justified. 

A font weight is a kind of value.
The font weights are light-weight, regular-weight, and bold-weight.



Section - The Table of User Styles definition

[ This table is given its own section so that it can be replaced to add extra columns needed by other extensions (such as Flexible Windows) ]

Table of User Styles
style name (a glulx text style)	background color (a text)	color (a text)	first line indentation (a number)	fixed width (a truth state)	font weight (a font weight)	indentation (a number)	italic (a truth state)	justification (a text justification)	relative size (a number)	reversed (a truth state)
with 1 blank row



Chapter - Sorting the Table of User Styles

[ We sort the table of styles to combine style definitions together ]

Before starting the virtual machine (this is the sort the Table of User Styles rule):
	[ First change empty style names to all-styles ]
	repeat through the Table of User Styles:
		if there is no style name entry:
			now the style name entry is all-styles;
	sort the Table of User Styles in style name order;
	let row1 be 1;
	let row2 be 2;
	[ Overwrite the first row of each style with the specifications of subsequent rows of the style ]
	while row2 <= the number of rows in the Table of User Styles:
		choose row row2 in the Table of User Styles;
		if there is a style name entry:
			if (the style name in row row1 of the Table of User Styles) is the style name entry:
				if there is a background color entry:
					now the background color in row row1 of the Table of User Styles is the background color entry;
				if there is a color entry:
					now the color in row row1 of the Table of User Styles is the color entry;
				if there is a first line indentation entry:
					now the first line indentation in row row1 of the Table of User Styles is the first line indentation entry;
				if there is a fixed width entry:
					now the fixed width in row row1 of the Table of User Styles is the fixed width entry;
				if there is a font weight entry:
					now the font weight in row row1 of the Table of User Styles is the font weight entry;
				if there is a indentation entry:
					now the indentation in row row1 of the Table of User Styles is the indentation entry;
				if there is a italic entry:
					now the italic in row row1 of the Table of User Styles is the italic entry;
				if there is a justification entry:
					now the justification in row row1 of the Table of User Styles is the justification entry;
				if there is a relative size entry:
					now the relative size in row row1 of the Table of User Styles is the relative size entry;
				if there is a reversed entry:
					now the reversed in row row1 of the Table of User Styles is the reversed entry;
				blank out the whole row;
			otherwise:
				now row1 is row2;
		increment row2;



Chapter - Setting the styles - unindexed

Last before starting the virtual machine (this is the set text styles rule):
	repeat through the Table of User Styles:
		if there is a background color entry:
			set the background color for the style name entry to the background color entry;
		if there is a color entry:
			set the color for the style name entry to the color entry;
		if there is a first line indentation entry:
			set the first line indentation for the style name entry to the first line indentation entry;
		if there is a fixed width entry:
			set fixed width for the style name entry to the fixed width entry;
		if there is a font weight entry:
			set the font weight for the style name entry to the font weight entry;
		if there is a indentation entry:
			set the indentation for the style name entry to the indentation entry;
		if there is a italic entry:
			set italic for the style name entry to the italic entry;
		if there is a justification entry:
			set the justification for the style name entry to the justification entry;
		if there is a relative size entry:
			set the relative size for the style name entry to the relative size entry;
		if there is a reversed entry:
			set reversed for the style name entry to the reversed entry;

To set the background color for (style - a glulx text style) to (N - a text):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_BackColor, GTE_ConvertColour( {N} ) ); -).

To set the color for (style - a glulx text style) to (N - a text):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_TextColor, GTE_ConvertColour( {N} ) ); -).

To set the first line indentation for (style - a glulx text style) to (N - a number):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_ParaIndentation, {N} ); -).

To set fixed width for (style - a glulx text style) to (N - truth state):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_Proportional, ( {N} + 1 ) % 2 ); -).

To set the font weight for (style - a glulx text style) to (N - a font weight):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_Weight, {N} - 2 ); -).

To set the indentation for (style - a glulx text style) to (N - a number):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_Indentation, {N} ); -).

To set italic for (style - a glulx text style) to (N - a truth state):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_Oblique, {N} ); -).

To set the justification for (style - a glulx text style) to (N - a text justification):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_Justification, {N} - 1 ); -).

To set the relative size for (style - a glulx text style) to (N - a number):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_Size, {N} ); -).

To set reversed for (style - a glulx text style) to (N - a truth state):
	(- GTE_SetStylehint( wintype_TextBuffer, {style}, stylehint_ReverseColor, {N} ); -).

Include (-
[ GTE_SetStylehint wintype style hint N i;
	if ( style == (+ all-styles +) )
	{
		for ( i = 0: i < style_NUMSTYLES : i++ )
		{
			glk_stylehint_set( wintype, i, hint, N );
		}
	}
	else
	{
		glk_stylehint_set( wintype, style - 2, hint, N );
	}
];
-).

[ Previously you would have to manually convert colours to their integer values, but in version 5 the extension will do it for you. Short (#FFF) web colours aren't supported. ]

Include (-
[ GTE_ConvertColour txt p1 cp1 dsize i ch progress;
	! Transmute the text
	cp1 = txt-->0;
	p1 = TEXT_TY_Temporarily_Transmute( txt );
	dsize = BlkValueLBCapacity( txt );
	for ( i = 0 : i < dsize : i++ )
	{
		! Decode the hex characters
		ch = BlkValueRead( txt, i );
		if ( ch == 0 )
		{
			break;
		}
		else if ( ch > 47 && ch < 58 )
		{
			progress = progress * 16 + ch - 48;
		}
		else if ( ch > 64 && ch < 71 )
		{
			progress = progress * 16 + ch - 55;
		}
		else if ( ch > 96 && ch < 103 )
		{
			progress = progress * 16 + ch - 87;
		}
	}
	! Clean up and return
	TEXT_TY_Untransmute( txt, p1, cp1 );
	return progress;
];
-).



Chapter - Additional style phrases

To say alert style:
	(- glk_set_style( style_Alert ); -).

To say blockquote style:
	(- glk_set_style( style_BlockQuote ); -).

To say header style:
	(- glk_set_style( style_Header ); -).

To say input style:
	(- glk_set_style( style_Input ); -).

To say note style:
	(- glk_set_style( style_Note ); -).

To say special-style-1:
	(- glk_set_style( style_User1 ); -).
To say special style 1:
	(- glk_set_style( style_User1 ); -).
To say first special/custom style:
	(- glk_set_style( style_User1 ); -).

To say special-style-2:
	(- glk_set_style( style_User2 ); -).
To say special style 2:
	(- glk_set_style( style_User2 ); -).
To say second special/custom style:
	(- glk_set_style( style_User2 ); -).



Glulx Text Effects ends here.



---- Documentation ----

Glulx Text Effects provides an easy way to set up special text effects for Glulx. 



Chapter: Styles in Glulx

Unlike the Z-Machine, which allows arbitrary combinations of features (such as color and boldness) to be applied to text, Glulx requires the author to define and then use text styles.

There are eleven of these styles:

	Table of styles
	normal-style	the style used for regular text
	italic-style	used for italic text (this is what the "[italic type]" phrase uses)
	bold-style	used for bold text (this is what the "[bold type]" phrase uses)
	fixed-letter-spacing-style	used for monospaced text (this is what the "[fixed letter spacing]" phrase uses)
	alert-style	used when printing an end of game message such as "*** You have died. ***"
	blockquote-style	used for printing box quotations
	header-style	used to print the title of the game
	input-style	used for the player's own input
	note-style	used for messages such as "[Your score has increased by one point.]"
	special-style-1	these two styles are not used by Inform, and you are free to use them for any purpose you want
	special-style-2

Additionally, when defining styles you can set "all-styles" which will define all eleven styles at once.



Chapter: Style features

Each text style has the following features:

	Table of style features
	background color	specifies the background color of the text
	color	specifies the color of the text itself
	fixed width	a truth state (default: false). If true then the text will be displayed with a fixed width (monospace) font
	font weight	specifies the weight of the font. Can be set to "light-weight", "regular-weight" (the default), or "bold-weight"
	indentation	a number (default: 0) specifying the number of units of indentation for the whole block of text. Units are defined by interpreter, but are often equivalent to spaces
	first line indentation	a number (default: 0) specifying additional indentation for the first line of the text block
	italic	a truth state (default: false). If true then the text will be displayed in italics
	justification	can be set to "left-justified", "center-justified", "right-justified", or "left-right-justified" for justified on the left and right (often called full justification)
	relative size	a number (default: 0) specifying how many font sizes above or below the browser's default a style should be set to
	reversed	a truth state (default: false). If true then the foreground and background colors of the text will be reversed. This is most commonly used for the status line

Not all interpreters support all of these features. Notably, Gargoyle does not support justification or font sizes. If the interpreter does not support one of the features it will just be quietly ignored.



Chapter: Defining styles

To define the features each style should have, add a table continuation to the Table of User Styles in your code. For example:

	Table of User Styles (continued)
	style name	color	italic	relative size
	all-styles	"#FF0000"	true	--
	header-style	"#0000FF"	false	1
	special-style-1	"#00FF00"

This definition table above will make everything red and italics, except for the title which will be blue and a size bigger. Special style 1 is set to green, but it won't be used without the author manually turning it on.

Your table continuation does not need to include every column in the Table of User Styles, nor does it need to define every style. You can also continue the table multiple times, and even define a style in multiple places; if you do then the definitions will be combined together. If you do not want to set a feature for a style you can leave it blank with "--".

Colors are defined by specifying a web (CSS) color in a text. Web colors specify the red/green/blue components of a color in hexadecimal, and a correctly specified color will be 6 characters long (with an optional # at the beginning.) Note that short (#000) web colors are not supported.

If you use a color many times you can define it as a text constant, and then use that in the table:

	Red is always "#FF0000".
	
	Table of User Styles (continued)
	style name	color
	special-style-1	red



Chapter: Using the styles

You may invoke the text styles by using the following phrases

	Table of style phrases
	normal-style	"[roman type]"
	italic-style	"[italic type]"
	bold-style	"[bold type]"
	fixed-letter-spacing-style	"[fixed letter spacing]" (Return to regular variable spaced type with either "[variable letter spacing]" or just "[roman type]")
	alert-style	"[alert style]"
	blockquote-style	"[blockquote style]"
	header-style	"[header style]"
	input-style	"[input style]"
	note-style	"[note style]"
	special-style-1	"[special-style-1]", "[first special style]", or "[first custom style]" (there are multiple options to support older code)
	special-style-2	"[special-style-2]", "[second special style]", or "[second custom style]"



Chapter: About this extension

This extension was originally by Emily Short. Version 5 was rewritten by Dannii Willis.

The latest version of this extension can be found at <https://github.com/i7/extensions>. This extension is released under the Creative Commons Attribution licence. Bug reports, feature requests or questions can be made at <https://github.com/i7/extensions/issues>.



Example: * Gaudy - A visually overpowering exercise in modifying all the built-in text styles.

	*: "Gaudy"
	
	Include Version 5 of Glulx Text Effects by Emily Short.	
	
	Use scoring.
	
	Texty Room is a room. "This is a room of [bold type]bold[roman type] and [italic type]italic[roman type] texts as well as messages in [fixed letter spacing]fixed width[variable letter spacing] text."
	
	Table of User Styles (continued)
	style name	relative size	color	background color
	italic-style	-1	"#0000FF" [ blue ]	--
	fixed-letter-spacing-style	--	"#444444" [ dark-grey ]	--
	header-style	10	--	--
	bold-style	2	"#888888" [ medium-grey ]	"#80DAEB"
	alert-style	5	"#FF0000" [ red ]
	note-style	--	"#00FF00" [ green ]
	blockquote-style	--	"#FFFF00" [ yellow ]
	input-style	-1	"#FF00FF" [ magenta ]
	
	Instead of waiting:
		increase the score by 5.
	
	Instead of jumping:
		end the story finally.
	
	Every turn:
		display the boxed quotation "Tempus fugit." 
	
	Test me with "z / z / z / jump".



Example: ** The Gallic War - An excuse to print a large, fancily-formatted bit of text using custom styles.

	*: "The Gallic War" by Julius Caesar.

	The story headline is "An interactive campaign".
	
	Lessons is a room.

	Include Glulx Text Effects by Emily Short.
	Include Basic Screen Effects by Emily Short.

	Table of User Styles (continued)
	style name	justification	italic	indentation	first line indentation	font weight	color
	special-style-2	left-right-justified	true	15	-4	light-weight	"#888888" [ medium-grey ]

	When play begins:
		now the left hand status line is "";
		now right hand status line is "";
		say "[second custom style]Gallia est omnis divisa in partes tres, quarum unam incolunt Belgae, aliam Aquitani, tertiam qui ipsorum lingua Celtae, nostra Galli appellantur. Hi omnes lingua, institutis, legibus inter se differunt. Gallos ab Aquitanis Garumna flumen, a Belgis Matrona et Sequana dividit. 

Horum omnium fortissimi sunt Belgae, propterea quod a cultu atque humanitate provinciae longissime absunt, minimeque ad eos mercatores saepe commeant atque ea quae ad effeminandos animos pertinent important, proximique sunt Germanis, qui trans Rhenum incolunt, quibuscum continenter bellum gerunt. Qua de causa Helvetii quoque reliquos Gallos virtute praecedunt, quod fere cotidianis proeliis cum Germanis contendunt, cum aut suis finibus eos prohibent aut ipsi in eorum finibus bellum gerunt.";
		pause the game;
		say roman type;
		now the left hand status line is "[location]";
		now the right hand status line is "[turn count]".

	Bank of the Garumna is a room.