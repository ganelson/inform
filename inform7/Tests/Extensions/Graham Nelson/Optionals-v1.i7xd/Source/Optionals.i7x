Version 1 of Optionals by Graham Nelson begins here.

To decide which optional K is (X - value of kind K) as optional:
	(- (OPTIONAL_TY_Wrap({-new: optional K}, {X})) -).

To decide if (X - optional value) exists:
	(- (OPTIONAL_TY_Exists({-by-reference:X})) -).

To decide which K is (X - optional value of kind K) as value:
	(- (OPTIONAL_TY_Unwrap({-new: K}, {-by-reference:X})) -).

Optionals ends here.
