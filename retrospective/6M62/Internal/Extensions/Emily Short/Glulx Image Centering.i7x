Version 4 of Glulx Image Centering (for Glulx only) by Emily Short begins here.

"Glulx Image Centering adds the ability to display an image that is centered (left/right) on the screen."

Include Glulx Text Effects by Emily Short.

Table of User Styles (continued)
style name	background color	color	first line indentation	fixed width	font weight	indentation	italic	justification	relative size	reversed
special-style-1	--	--	--	--	--	--	--	center-justified	--	--


To display (chosen figure - a figure-name) centered:
	say first custom style; say " ";
	display chosen figure inline;
	say " [line break]"; 
	say roman type; 
	
To display (chosen figure - a figure-name) inline:
	(- DrawInline({chosen figure}); -)

Include (-

[ DrawInline N;
	glk_image_draw(gg_mainwin, ResourceIDsOfFigures-->N,  imagealign_InlineUp, 0);
]; 

-)

Glulx Image Centering ends here.

---- Documentation ----

Glulx Image Centering adds the ability to display an image that is centered (left/right) on the screen. To do this, it uses up the first of the two available custom user text styles, defining it to be center-justified. 

To invoke Glulx Image Centering, we say

	display figure foo centered.

To display cover art in our game, we might include something like this:

	Include Glulx Image Centering by Emily Short. Include Basic Screen Effects by Emily Short.

	When play begins: 
		display figure of small cover centered;
		pause the game.

This would display a picture in the middle of the screen, then wait for a keypress, then clear the screen before going on with the game.

A word of warning: not all Glulx interpreters will necessarily handle this operation correctly. Authors are advised to check the performance of their game on a variety of interpreters, or have their beta-testers do so.

