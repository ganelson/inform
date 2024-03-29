[Certainty::] Adverbs of Certainty.

Adverbs such as "usually" or "initially".

@ Inform uses the following scale to measure how certain it is that something
is true:

@d IMPOSSIBLE_CE -2
@d UNLIKELY_CE -1
@d UNKNOWN_CE 0
@d LIKELY_CE 1
@d CERTAIN_CE 2

@ A special certainty level is used for a temporal sense of certainty:

@d INITIALLY_CE 3

@ =
void Certainty::write(OUTPUT_STREAM, int level) {
	switch (level) {
		case IMPOSSIBLE_CE: WRITE("impossible"); break;
		case UNLIKELY_CE: WRITE("unlikely"); break;
		case UNKNOWN_CE: WRITE("(no certainty level)"); break;
		case LIKELY_CE: WRITE("likely"); break;
		case CERTAIN_CE: WRITE("certain"); break;
		case INITIALLY_CE: WRITE("initial"); break;
	}
}

@ Certainty adverbs are found mainly in regular sentences:

>> A door is usually open.

They are syntactically legal in existential sentences too, though in English
this usually expresses emphasis rather than a measure of probability: consider
"there certainly are men in the room". Inform allows this, in any case. In
conditions, Inform is more picky. For example, in assertions one can write

>> A box is usually closed. (1)

but in conditions one can't write

>> if a box is usually closed, ... (2)

This is because (1) is essentially a statement about the future, not the
present or the past, whereas conditions like (2) must always be determinable at
once: run-time code cannot know what will generally happen, only what is now
the case and what has been the case in the past.

=
<certainty> ::=
	always/certainly |  ==> { CERTAIN_CE, - }
	usually/normally |  ==> { LIKELY_CE, - }
	rarely/seldom |     ==> { UNLIKELY_CE, - }
	never |             ==> { IMPOSSIBLE_CE, - }
	initially           ==> { INITIALLY_CE, - }
