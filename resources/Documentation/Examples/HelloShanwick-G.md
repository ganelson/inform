Example: ** Hello Shanwick
Location: Parts corresponding to kinds
RecipeLocation: The Passage Of Time
Index: International aviation alphabet
Description: Aircraft tail numbers using the international aviation alphabet.
For: Glulx

^^{units of measure: defining: with parts of a kind of value} ^^{defining: units of measure with parts: with parts of a kind of value} ^^{|corresponding to: in defining units of measure} ^^{kinds: of value: in defining units of measure}

Since 1956, pilots have identified their aircraft over radio channels using a standard international alphabet, which has several names and numerous parent organisations. It goes like so:

	{*}"Hello Shanwick"
	
	The international aviation alphabet is a kind of value. Alpha, Bravo,
	Charlie, Delta, Echo, Foxtrot, Golf, Hotel, India, Juliet, Kilo, Lima, Mike,
	November, Oscar, Papa, Quebec, Romeo, Sierra, Tango, Uniform, Victor,
	Whiskey, X-ray, Yankee, Zulu is the international aviation alphabet.

(Some people spell `Alfa` and `Juliett`. Those people need help.) European civil aircraft are normally given "tail numbers" like this:

	{**}A tail number is a kind of value.
	
	<country>-<first><second><third><fourth> specifies a tail number
	with parts
		country (values "A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z",
			corresponding to the international aviation alphabet),
		first (values "A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z",
			corresponding to the international aviation alphabet),
		second (values "A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z",
			corresponding to the international aviation alphabet),
		third (values "A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z",
			corresponding to the international aviation alphabet),
		fourth (values "A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z",
			corresponding to the international aviation alphabet).

	To say callsign of (T - tail number):
		say "[country part of T] [first part of T] [second part of T] [third part of T] [fourth part of T]".

This is all a little clumsy and repetitious, but no matter, because now we can write assertions like, say, `The Mont Blanc rescue helicopter is always F-ZBQG.` Or:

	{**}Flight Deck is a room.
	
	"Douglas smoothly intones, 'Hello Shanwick, this is [callsign of G-ERTI].'"

which prints out as:

``` transcript
Douglas smoothly intones, "Hello Shanwick, this is Golf Echo Romeo Tango India".
```
