[Inflect::] English Inflections.

To define how English nouns and verbs are inflected.

@h Noun inflections.
The following trie looks at the start of a word, which we assume to be a
noun, and decides whether to use the indefinite article "a" or "an".
This is much more complicated than simply looking for a vowel as the first
letter, as people often think until they try a few cases.

The following was compiled by Toby Nelson with the aid of a pronunciation
dictionary and the "Official Scrabble Wordlist".

=
<singular-noun-to-its-indefinite-article> ::=
	<en-trie-indef-a> |
	<en-trie-indef-b> |
	<en-trie-indef-c>

@ Exceptions to the exceptions:

=
<en-trie-indef-a> ::=
	oneir*          an |
	onero*          an |
	ukiyo-e         an |         /* Japanese style of 17th-19th cent. printmaking */
	urao*           an |
	urial*          an |
	uvarovite*      an           /* a rare emerald-green garnet, Ca3Cr2(SiO4)3 */

@ Then the exceptions:

=
<en-trie-indef-b> ::=
	eu*             a |         /* e.g., euphoria, eulogy */
	ewe*            a |         /* female sheep */
	ewftes          a |         /* Spens. form of an eft lizard */
	ewghen          a |         /* made of yew, i.e., yewen */
	ewk             a |
	houri           a |
	once*           a |         /* a Once and Future King */
	one*            a |         /* but still use an for oneir- and onero- */
	onst            a |         /* dialect form of once */
	oui*            a |         /* e.g., a Ouija board or a ouistiti (a marmoset) */
	u               a |         /* the letter U */
	u-*             a |         /* e.g., U-boats */
	u'*             a |         /* e.g., u's */
	uakari          a |         /* the South American monkey */
	ub*             a |         /* e.g., ubiquitous */
	udal*           a |
	udomet*         a |
	uey             a |         /* colloquial for "U-turn", as in "he pulled a uey" */
	ueys            a |
	ufo*            a |
	uganda*         a |         /* the country Uganda */
	ugr*            a |
	uint*           a |
	uk*             a |
	ulex            a |         /* the genus of gorse */
	uli*            a |
	ulo*            a |
	ulu*            a |
	una             a |         /* from "una corda", the musical term */
	unabomb*        a |         /* the so-called Unabomber */
	unalist         a |
	unanimit*       a |
	unanimous*      a |
	unesco          a |         /* the United Nations cultural body */
	unescos         a |
	unia*           a |
	unic*           a |
	unif*           a |
	unig*           a |
	unil*           a |
	unio*           a |
	unip*           a |
	uniq*           a |
	unis*           a |
	unit*           a |
	univ*           a |
	upas*           a |
	ura*            a |
	ure*            a |
	uri*            a |
	uru*            a |
	usa*            a |
	use*            a |
	usi*            a |
	usu*            a |
	utas*           a |
	ute*            a |
	uti*            a |
	uto*            a |
	utr*            a |
	uttoxeter*      a |         /* the English town of Uttoxeter */
	uva*            a |
	uvu*            a

@ And finally the basic rules:

=
<en-trie-indef-c> ::=
	a*              an |
	e*              an |
	i*              an |
	o*              an |
	u*              an |
	f               an |
	f's             an |
	f-*             an |
	fbi             an |
	fo              an |
	frs             an |
	h               an |
	h's             an |
	h-*             an |         /* e.g., H-bomb */
	haute*          an |         /* e.g., haute cuisine, hauteur */
	heir*           an |
	hono*           an |         /* e.g., honorific, honorary doctorate */
	hour*           an |
	l               an |
	l's             an |
	l-*             an |         /* e.g., L-plate */
	m               an |
	m's             an |
	m-*             an |         /* e.g., M-ration */
	n               an |
	n's             an |
	n-*             an |         /* e.g., N-dimensional manifold */
	r               an |
	r's             an |
	r-*             an |
	rac             an |         /* Royal Automobile Club */
	raf             an |         /* Royal Air Force */
	rspca           an |         /* Royal Society for the Prevention of Cruelty to Animals */
	rsvp            an |
	s               an |
	s's             an |
	s-*             an |
	x               an |
	x's             an |
	x-*             an |         /* e.g., X-ray */
	xmas*           an |
	yb*             an |         /* these are mostly obs., Spens., and/or arch. */
	yc*             an |
	yd*             an |
	yf*             an |
	yg*             an |
	ym*             an |
	yn*             an |
	yp*             an |         /* e.g., ypsilon */
	yr*             an |
	ys*             an |
	yt*             an |         /* e.g., Ytterbium, Yttrium */
	yw*             an

@h Plural inflections.
The following takes a single word, assumes it to be a noun which meaningfully
has a plural, and modifies it to the plural form. ("Golf" is a noun which
doesn't sensibly have a plural; the algorithm here would return "golves".)

The trie here was derived from a partial implementation of Damian Conway's
algorithm: see his paper "An Algorithmic Approach to English
Pluralization", online at his website. The use of tries makes this somewhat
faster than Conway's reference implementation, which for clarity's sake
consists of a long sequence of regular-expression matches.

Conway divides plurals into modern and classical forms, and in cases where a
noun has both, we take the modern form. Thus "phalanxes", not "phalanges".
Because we focus on single words, we also omit prepositional phrases ("under
water") and position names qualified by following adjectives ("procurator
fiscal", "postmaster general"). Otherwise we omit only two cases, both
involving capitalised proper nouns: nationality adjectives used as if they were
nouns ("I saw two Japanese walking into the airport") and names of people used
as if they were count nouns for a category of people like the one named ("We
need more Wills, more Henrys.") -- these are not likely to arise much in Inform
usage, and they are awkward to implement with our tries because they depend on
prefix as well as suffix and require case-dependency.

In its written form (as of November 2009, anyway), Conway's paper omits an
important step from Algorithm 1, though it's present in his Perl implementation:
the regular case of a sibilant suffix. (Ironically, this means that as stated
Algorithm 1 pluralizes "suffix" incorrectly, as "suffixs".) I have filled
this omission. I have also amended step 11, which considers the regular plural
of a sibilant plus "o" suffix to include an "e", so that Conway produces
"torsoes", "bozoes"; we will have "torsos" and "bozos".

=
<singular-noun-to-its-plural> ::=
	... <en-trie-plural-uninflected> |
	... <en-trie-plural-pronouns> |
	... <en-trie-plural-irregular> |
	... <en-trie-plural-irregular-inflections> |
	... <en-trie-plural-assimilated-classical-inflections> |
	... <en-trie-plural-irregular-o-suffixes> |
	... <en-trie-plural-regular-inflections> |
	... <en-trie-plural-append-s>

@ See Conway's table A.2. The following nouns, mostly names of kinds of animal,
have the same plural as singular form: for example, chamois, salmon, goldfish.

=
<en-trie-plural-uninflected> ::=
	*fish           0 |
	*ois            0 |
	*sheep          0 |
	*deer           0 |
	*pox            0 |
	*itis           0 |
	bison           0 |
	flounder        0 |
	pliers          0 |
	bream           0 |
	gallows         0 |
	proceedings     0 |
	breeches        0 |
	graffiti        0 |
	rabies          0 |
	britches        0 |
	headquarters    0 |
	salmon          0 |
	carp            0 |
	herpes          0 |
	scissors        0 |
	chassis         0 |
	high-jinks      0 |
	sea-bass        0 |
	clippers        0 |
	homework        0 |
	series          0 |
	cod             0 |
	innings         0 |
	shears          0 |
	contretemps     0 |
	jackanapes      0 |
	species         0 |
	corps           0 |
	mackerel        0 |
	swine           0 |
	debris          0 |
	measles         0 |
	trout           0 |
	diabetes        0 |
	mews            0 |
	tuna            0 |
	djinn           0 |
	mumps           0 |
	whiting         0 |
	eland           0 |
	news            0 |
	wildebeest      0 |
	elk             0 |
	pincers         0

@ We may as well pluralise pronouns while we're at it.

=
<en-trie-plural-pronouns> ::=
	i               we |
	you             you |
	thou            you |
	she             they |
	he              they |
	it              they |
	they            they |
	me              us |
	you             you |
	thee            you |
	her             them |
	him             them |
	it              them |
	them            them |
	myself          ourselves |
	yourself        yourself |
	thyself         yourself |
	herself         themselves |
	himself         themselves |
	itself          themselves |
	themself        themselves |
	oneself         oneselves

@ We now reach Conway step 4. These are irregular plurals mostly coming
from archaisms.

=
<en-trie-plural-irregular> ::=
	beef            beefs |            /* we neglect the classical "beeves" */
	brother         brothers |      /* and "brethren" */
	child           children |
	cow             cows |            /* and "kine" */
	ephemeris       ephemerides |
	genie           genies |        /* and "genii" */
	money           moneys |        /* and "monies" */
	mongoose        mongooses |
	mythos          mythoi |
	octopus         octopuses |     /* and "octopodes" */
	ox              oxen |
	soliloquy       soliloquies |
	trilby          trilbys

@ Step 5. Now we reach a batch of irregular but fairly general inflected
endings; for example, protozoon to protozoa, or metamorphosis to metamorphoses.
Note that we differ from Conway in pluralizing blouse as blouses, not blice,
and human as humans, not humen.

=
<en-trie-plural-irregular-inflections> ::=
	*human          humans |           /* Step 5 begins here */
	*man            3men | 
	*blouse         2ses |
	*louse          5lice |
	*mouse          5mice |
	*tooth          5teeth |
	*goose          5geese |
	*foot           4feet |
	*zoon           4zoa |
	*cis            3ces |
	*sis            3ses |
	*xis            3xes

@ Step 6. These are inflections from Latin and Greek which have survived
into modern English:

=
<en-trie-plural-assimilated-classical-inflections> ::=
	alumna          alumnae |            /* from table A.10 */
	alga            algae |
	vertebra        vertebrae |
	codex           codices |            /* from table A.14 */
	murex           murices |
	silex           silices |
	aphelion        aphelia |            /* from table A.19 */
	hyperbaton      hyperbata |
	perihelion      perihelia |
	asyndeton       asyndeta |
	noumenon        noumena |
	phenomenon      phenomena |
	criterion       criteria |
	organon         organa |
	prolegomenon    prolegomena |
	agendum         agenda |            /* from table A.20 */
	datum           data |
	extremum        extrema |
	bacterium       bacteria |
	desideratum     desiderata |
	stratum         strata |
	candelabrum     candelabra |
	erratum         errata |
	ovum            ova

@ Step 11a. (We're not implementing Conway's steps in sequence: see below.)
These -o endings are mostly loan words from Romance languages whose original
inflections are assimilated.

=
<en-trie-plural-irregular-o-suffixes> ::=
	albino          albinos |
	alto            altos |
	archipelago     archipelagos |
	armadillo       armadillos |
	basso           bassos |
	canto           cantos |
	commando        commandos |
	contralto       contraltos |
	crescendo       crescendos |
	ditto           dittos |
	dynamo          dynamos |
	embryo          embryos |
	fiasco          fiascos |
	generalissimo   generalissimos |
	ghetto          ghettos |
	guano           guanos |
	inferno         infernos |
	jumbo           jumbos |
	lingo           lingos |
	lumbago         lumbagos |
	magneto         magnetos |
	manifesto       manifestos |
	medico          medicos |
	octavo          octavos |
	photo           photos |
	pro             pros |
	quarto          quartos |
	rhino           rhinos |
	solo            solos |
	soprano         sopranos |
	stylo           stylos |
	tempo           tempos

@ Conway steps 8 to 11. These are regular inflections depending only on
word endings.

=
<en-trie-plural-regular-inflections> ::=
	*ch             0es |         /* Step 8: "church" to "churches" */
	*sh             0es |         /* "rush" to "rushes" */
	*ss             0es |         /* "dress" to "dresses" */
	*alf            1ves |         /* Step 9: "calf" to "calves" */
	*elf            1ves |         /* "self" to "selves" */
	*olf            1ves |         /* "wolf" to "wolves" */
	*eaf            1ves |         /* "sheaf" to "sheaves" */
	*arf            1ves |         /* "wharf" to "wharves" */
	*nife           2ves |         /* "knife" to "knives" */
	*life           2ves |         /* "life" to "lives" */
	*wife           2ves |         /* "wife" to "wives" */
	*ax             0es |         /* Sibilant additions: "fax" to "faxes" */
	*ex             0es |         /* "sex" to "sexes" */
	*ix             0es |         /* "Weetabix" to "Weetabixes" */
	*ox             0es |         /* "fox" to "foxes" */
	*ux             0es |         /* "flux" to "fluxes" */
	*as             0es |         /* "gas" to "gases" */
	*es             0es |
	*is             0es |         /* "mantis" to "mantises" */
	*os             0es |         /* "thermos" to "thermoses" */
	*us             0es |         /* "abacus" to "abacuses" */
	*az             0es |
	*ez             0es |         /* "fez" to "fezes" */
	*iz             0es |
	*oz             0es |
	*uz             0es |
	*zz             0es |
	*ay             0s |            /* Step 10 begins here */
	*by             1ies |
	*cy             1ies |
	*dy             1ies |
	*ey             0s |
	*fy             1ies |
	*gy             1ies |
	*hy             1ies |
	*iy             0s |
	*jy             1ies |
	*ky             1ies |
	*ly             1ies |
	*my             1ies |
	*ny             1ies |
	*oy             0s |
	*py             1ies |
	*qy             1ies |
	*ry             1ies |
	*sy             1ies |
	*ty             1ies |
	*uy             0s |
	*vy             1ies |
	*wy             1ies |
	*xy             1ies |
	*yy             1ies |
	*zy             1ies |
	*ao             0s |            /* Step 11b begins here */
	*bo             1oes |
	*co             1oes |
	*do             1oes |
	*eo             0s |
	*fo             1oes |
	*go             1oes |
	*ho             1oes |
	*io             0s |
	*jo             1oes |
	*ko             1oes |
	*lo             1oes |
	*mo             1oes |
	*no             1oes |
	*oo             0s |
	*po             1oes |
	*qo             1oes |
	*ro             1oes |
	*so             0s |
	*to             1oes |
	*uo             0s |
	*vo             1oes |
	*wo             1oes |
	*xo             0s |
	*yo             1oes |
	*zo             0s

@ Lastly, the fallback if none of the above cases match: append an -s, of
course.

=
<en-trie-plural-append-s> ::=
	*               0s                /* Step 13 */

@h Verb inflections.
"Le verbe est l'âme d'une langue" (attributed to Georges Duhamel). And the
care of the soul is, of course, complicated. For example, the source text can
say something like this:

>> The verb to flaunt means to wear.

This tells Inform that a new verb's infinitive is "flaunt", but not how
to construct its other parts. We will use Preform grammar not only to
define how to construct English verbs, but also in a way enabling it to
be used with other languages too.

Inform uses five different tenses (present, past, present perfect, past
perfect, and future), three persons, two numbers, two senses (true
and false), and two voices (active and passive); in addition, it keeps
track of the infinitive, past participle and present participle of a verb.
Altogether that makes 123 potentially different versions of the original
text. But of course there's a great deal of duplication in this, and
almost all of the versions can be made using a much smaller number of
genuinely different inflected versions of the word.

Our general strategy works like this:

(a) Identify one or more verbs as being too irregular to fit into any
pattern, and handle those as special cases.

(b) For all other verbs, identify a set of inflected forms which covers all
of the possibilities we need to make, and write a trie to handle each one.

(c) Try to use a single conjugation to show how these forms are used, that
is, how the different word forms map onto the possible tenses, persons,
numbers, and so on.

@ This gives us a certain amount of choice. What exactly is "too irregular"?
In French, are all -er, -ir, and -re verbs "regular"? (Consider "aller",
for example.) In English, it's possible to say that there are seven or so
classes of verbs, all regular by their own standards; but most people say
there's just one class of verb, and then irregular exceptions.

Our approach will follow Greenbaum, "Oxford English Grammar", at 4.14.
Like Greenbaum, we will use the term "form type" for the different possible
inflected versions of a verb word. The verb "to be" has eight form
types (be, am, is, are, was, were, been, being), but it's unique in that
respect -- so this is one we will consider to be "too irregular", and will
handle as a special case.

All other English verbs have five form types, though in many cases two or more
of these have the same spelling. These we will number as follows, for reasons
which will become clear below:

(1) Infinitive: flaunt.
(2) Present participle: flaunting.
(3) Past participle: flaunted.
(5) Third person singular present (or just "present"): flaunts.
(6) Third person singular past (or just "past"): flaunted.

In regular verbs the past and past participle are the same, as they are here:
he flaunted (past); he had flaunted (past participle). But English has around
600 commonly occurring irregular verbs in which they are different, sometimes
unpredictably so: he went (past); he had gone (past participle). Irregularity
sometimes makes these forms coincide rather than making them different: for
example, to set has just three distinct forms -- to set, he sets, he set, he
had set, setting.

@ Form types are numbered from 0 up to, potentially, a constant
called |MAX_FORM_TYPES|. (This is so large that there shouldn't ever be need
for more.) Form type 0 is always the original text, and is used as the basis
from which the others are generated. For English verbs Inform always sets form
type 0 to the infinitive, but this needn't be true if it's more natural in
other languages to do something else.

We then reserve form types 1 to 3 for infinitive, present participle, and past
participle, respectively, and this is required to be the case in all
languages. Form type 4 is reserved for the "adjoint infinitive": if we
are given the English base text "be able to see", for example, this will
be recognised (see below) as "be able to" plus "see", and "see" will
be the "adjoint infinitive". For most verbs, we won't use it.

That means that form types 5 and upward are free to be used as needed by
each language. English needs two: the present (5) and past (6) forms.

@d BASE_FORM_TYPE 0
@d INFINITIVE_FORM_TYPE 1
@d PRESENT_PARTICIPLE_FORM_TYPE 2
@d PAST_PARTICIPLE_FORM_TYPE 3
@d ADJOINT_INFINITIVE_FORM_TYPE 4
@d MAX_FORM_TYPES 123

@ We're now ready to write the |<verb-conjugation-instructions>|. This is
a block which looks at the infinitive of the verb and decides which of
several conjugations should be used. Badly irregular verbs get
conjugations of their own, and others are grouped together. In French,
for example, we might use this block of instructions to divide into different
cases for -er, -ir, and -re verbs.

Each row takes the form of a pattern of words to match, followed by a
nonterminal giving the conjugation to use if a match is made. Matches
are literal except:

(a) The tail |...| means any string of one or more words, but can only be used
as the tail. Any text matching it is written into the adjoint infinitive.
So |be able to ...| matches "be able to touch" and sets the adjoint
infinitive to "touch".

(b) A pattern written in the form |-xyz| matches the tail of a verb. This
isn't useful for English, but in French it neatly spots classes of verbs:
for example, |-er| detects first-conjugation verbs such as "donner".

Note that we have to make sure every possible infinitive text matches at
least one line, and the best way to ensure that is to finish up with |...|
as the last pattern -- this matches anything.

@ The instructions for English are quite concise, except for the presence
of the awkward contracted informal forms of verbs. (These aren't used in
Inform assertion sentences, but are needed for text substitutions.)

=
<verb-conjugation-instructions> ::=
	be              <to-be-conjugation> |
	be able to ...  <to-be-able-to-auxiliary> |
	be able to      <to-be-able-to-conjugation> |
	could           <modal-conjugation> |
	may             <modal-conjugation> |
	might           <modal-conjugation> |
	must            <modal-conjugation> |
	should          <modal-conjugation> |
	would           <modal-conjugation> |
	auxiliary-have  <to-have-conjugation> |
	do              <to-do-conjugation> |
	're             <contracted-to-be-conjugation> |
	've             <contracted-to-have-conjugation> |
	aren't          <arent-conjugation> |
	can't           <cant-modal-conjugation> |
	don't           <informal-negated-modal-conjugation> |
	haven't         <informal-negated-modal-conjugation> |
	mayn't          <informal-negated-modal-conjugation> |
	mightn't        <informal-negated-modal-conjugation> |
	mustn't         <informal-negated-modal-conjugation> |
	wouldn't        <informal-negated-modal-conjugation> |
	couldn't        <informal-negated-modal-conjugation> |
	shouldn't       <informal-negated-modal-conjugation> |
	won't           <informal-negated-modal-conjugation> |
	...             <regular-verb-conjugation>

@ We will start with two auxiliary verbs, that is, verbs used to construct
forms of other verbs. The first is "to have"; as we'll see, English uses
this to construct perfect tenses:

>> Peter has opened the gate. Jane had closed it.

"To have" doesn't really mean that anybody possessed anything here, except
perhaps a history. It's simply used in conjunction with the past participle
("opened" and "closed") to form a tense. Verbs like this are called
"auxiliary".

But it's not actually true, despite what concise grammars say, that English
uses "to have" here; it uses a slight variation which differs in the negated
forms. We write

>> I have not taken the lantern.

rather than

>> I do not have taken the lantern.

which strictly speaking ought to be correct. Inform handles this by using a
modified form of "to have", which we'll call "to auxiliary-have", which
differs only in its negative forms. We're only going to give this present
and past tenses since it's never needed except as an auxiliary.

Anyway, this is an example of a "conjugation". The purpose of this is to
set a few special verb forms -- such as the present and past participles --
and then give a recipe to make all of the many forms which the verb can
take within sentences. The verb forms are numbered -- see above -- and
the recipe is called a "tabulation". We'll specify the format for this
below, when we get to a more complicated example, but briefly: this one
sets the present participle (2) to "having", the past participle (3) to
"had", and then names |<to-have-tabulation>| as the tabulation. The
text doesn't have to be a single word, and some ingenious tricks are
possible to form it from other verb forms; see below.

The marker |<auxiliary-verb-only>| means that this form of "have" can
only be accessed from other verb conjugations, not via a text substitution
for "[have]".

=
<to-have-conjugation> ::=
	2 having |
	3 had |
	<auxiliary-verb-only> |
	<not-instance-of-verb-at-run-time> |
	<to-have-tabulation>

@ Tabulations give instructions for how to construct 120 possible versions
of the verb. These are divided up first into active and passive "voices":

>> Peter carries the lantern. [Active.]
>> The lantern is carried by Peter. [Passive.]

This makes two sets of 60. Each set contains five tenses, which in English
are present (1), past (2), perfect (3), past perfect (4) and future (5).

>> Peter carries the lantern. [1]
>> Peter carried the lantern. [2]
>> Peter has carried the lantern. [3]
>> Peter had carried the lantern. [4]
>> Peter will carry the lantern. [5]

This makes five sets of 12. In each set there are six persons: first person
singular, second person singular, third person singular, first person plural,
second person plural, third person plural. We always write them in that order:

>> I carry the lantern. [1PS]
>> You carry the lantern. [2PS]
>> He carries the lantern. [3PS]
>> We carry the lantern. [1PP]
>> You [more than one person] carry the lantern. [2PP]
>> They carry the lantern. [3PP]

And that makes six sets of 2: the positive sense and the negative.

>> I carry the lantern. [Positive.]
>> I do not carry the lantern. [Negative]

To sum up, two voices times five tenses times six persons times two senses,
which makes 120 versions in all.

A tabulation is best thought of as a short program to make these. Inform starts
out with all 120 versions blank, and each tabulation step sets one or more
versions. It's perfectly legal for later steps to override earlier ones;
and it's legal to leave some versions unset, marking them not to be used.
(We're going to ignore all of the passives and three of the active tenses,
so we're only going to set 48 versions, in the case of auxiliary-to-have.)

Each step consists of a selector, followed by a text. The selector simply
chooses which of the 120 forms to set. The selector always begins with "a"
or "p", meaning active or passive; it can then optionally give a digit from
1 to 5, narrowing down to a given tense; and it can optionally give a plus or
minus sign, narrowing down to positive or negative senses. In the following,
for example, |a2+| means active voice (a), past tense (2), positive (|+|).
This nails down the selection to just 6 versions of the verb.

The text is used literally, except for the following:

(a) The numbers 1, 2, 3, ..., expand into the verb forms with those numbers.
For example, 2 expands into the present participle for the verb. If the
number is followed by an open bracket, then an infinitive, then a close
bracket, then it expands to the verb form for that verb. For example, the
following expands to "sought":
= (text as InC)
	3 ( seek )
=
(b) Text in the form |1+xyz| expands into verb form 1 but with the letters
"xyz" added. For example, |1+ed| for the verb "to mark" would expand to
"marked", since 1 is the infinitive form. This feature is much more useful
in heavily inflected languages like French.

(c) If a bracket, an infinitive, then a close bracket, is given, it expands
to the corresponding version of that verb. For example, the step
|a1+ ( grab ) back| sets the positive present-tense versions of a verb to
"I grab back", "you grab back", "he grabs back", and so on. Note that
the matching persons are used, i.e., if we're expanding this to make the
first person singular, we use the first person singular of the verb we're
borrowing. Finally, we can change the tense by placing a tense marker inside
the open brackets: |a3+ ( t1 have ) grabbed| sets the perfects to "I have
grabbed", "you have grabbed", and so on -- without the tense marker it
would have been "I have have had grabbed", because "have" would expand
to its perfect tense and not its present tense. The |t1| means present tense;
|t2| means past tense, and so on.

(d) If a nonterminal name is given, then it will be set of six texts; these
are used for the six persons.

A simple example, then, which uses only feature (d) of these exotica:

=
<to-have-tabulation> ::=
	a1+        <to-have-present> |
	a1-        <to-have-present> not |
	a2+        had |
	a2-        had not

@ And this is an example of splitting into cases for the six persons,
1PS, 2PS, 3PS, 1PP, 2PP, 3PP. I have, you have, he has, we have, you have,
they have. (This is more excitingly varied in other languages, of course.)

=
<to-have-present> ::=
	have | have | has | have | have | have

@ Next we have "to do", which is like "to have" in being fairly regular,
as irregular verbs go. But we treat this as a special case because, again,
we're going to need as an auxiliary verb when forming negatives ("Peter
does not wear the hat" -- note the "does not"). But this time we give
the full treatment, creating all 60 active forms.

For the passive, though, we do something new. The selector |p*| is actually
a way to set all 60 passive forms (which would normally be written |p|), but
it tells Inform to use "to be" as an auxiliary. When we write the |p*|
step:
= (text as InC)
	p*     done by
=
the effect is the same as writing:
= (text as InC)
	p      ( be ) done by
=
The difference is that Inform more efficiently implements the |p*| version,
by implementing "done by" as if it were a preposition rather than as part
of a verb. This parses more quickly and makes English passive forms play
more nicely with implied uses of "to be". For example, in

>> number of things carried by the player (1)

Inform has to infer the meaning

>> number of things which are carried by the player (2)

and it can only do this if it recognises "carried by" as being prepositional
in nature, like "on" or "in". In other words, if we wrote the |p| step
above instead of the |p*| step, (2) would still work but (1) would not. (We
may have to revisit this for languages other than English.)

=
<to-do-conjugation> ::=
	2         doing |
	3         done |
	<to-do-tabulation>

<to-do-tabulation> ::=
	a1+       <to-do-present> |
	a1-       <to-do-present> not |
	a2+       did |
	a2-       did not |
	a3        ( t1 auxiliary-have ) done |
	a4        ( t2 auxiliary-have ) done |
	a5+       will do |
	a5-       will not do |
	p*        done by

<to-do-present> ::=
	do | do | does | do | do | do

@ Regular English verbs, then, look like so. We will, for the first time,
make heavy use of our numbered verb forms: for example, for the verb
"to take", they would be "take" (1), "taking" (2), "taken" (3),
"takes" (5) and "took" (6). We start with the infinitive ("take")
in verb form 1, but (2), (3), (5) and (6) are initially blank -- we have
to make them somehow.

We do this by giving their definitions not as fixed wording, as we did
for the verbs above, but as tries which act on the infinitive to produce
a wording. For example, |<en-trie-present-participle>| is a trie which
performs:
= (text as InC)
	take --> taking
=
We will have to define these tries below. Note that the infinitive can consist
of multiple words; if so, the first word is run through the tries, and the
remaining words are left alone. For example, "grab onto" would be inflected
to "grabs onto", "grabbing onto" and so on.

=
<regular-verb-conjugation> ::=
	2         <en-trie-present-participle> |
	3         <en-trie-past-participle> |
	5         <en-trie-present-verb-form> |
	6         <en-trie-past> |
	<regular-verb-tabulation>

@ Here we see our auxiliary verbs in use. For the negated present tense,
"Peter does not carry the ball"; for the negated past tense, "Peter did
not carry the ball" -- in both cases, this is "to do" plus the infinitive
"take". For the perfect tenses, "to have" plus the past participle --
"Peter has carried the ball", "Peter had carried the ball". For the
future tense, "will" plus the infinitive -- "Peter will carry the ball".
(We're actually not going to implement this as a verb because all its
forms are just "will", and because "to will" also means "to leave
a bequest".)

=
<regular-verb-tabulation> ::=
	a1+       <regular-verb-present> |
	a1-       ( do ) 1 |
	a2+       6 |
	a2-       ( do ) 1 |
	a3        ( t1 auxiliary-have ) 3 |
	a4        ( t2 auxiliary-have ) 3 |
	a5+       will 1 |
	a5-       will not 1 |
	p*        3 by

@ This looks odd, but what it says is that the present tense of a regular
English verb is always the infinitive (I take, you take, we take, and so on)
except for third person singular (he takes), which is different. (It's usually
what the plural of the infinitive would be if the infinitive were a noun,
as we'll see.)

=
<regular-verb-present> ::=
	1 | 1 | 5 | 1 | 1 | 1

@ Now for our most irregular verb: "to be".

=
<to-be-conjugation> ::=
	2 being |
	3 been |
	<to-be-tabulation>

<to-be-tabulation> ::=
	a1+       <to-be-present> |
	a1-       <to-be-present> not |
	a2+       <to-be-past> |
	a2-       <to-be-past> not |
	a3        ( t1 auxiliary-have ) been |
	a4        ( t2 auxiliary-have ) been |
	a5+       will be |
	a5-       will not be

<to-be-present> ::=
	am | are | is | are | are | are

<to-be-past> ::=
	was | were | was | were | were | were

@ Except for tense formation (Peter "will" take the ball), the most common
modal verb which can be used in Inform source text is "can". For example:

>> the number of people who can see the King

This is modal because it makes the seeing only a possibility, not an actuality.
An awkward thing about modal verbs in English is that they are deficient,
that is, not all their forms even exist. "Can" has no infinitive. ("To can"
means to put food into a sealed metal container, which isn't the same thing
at all.) "Can" also has no perfect or future tenses. On the other hand, it
does have inflected present and past tenses, and we need to implement that.
So we will invent the infinitive form "be able to", and make the verb from
that, but using "can" and "could" instead of "is able to" and "was able
to". "Can" is rather irregular as a verb: the third person singular doesn't
inflect ("he can", not "he cans"), and the negative is written "cannot"
instead of "can not", presumably because we find the two "n"s awkward
to elide, so we always pronounce it that way and the spelling now follows.

=
<to-be-able-to-conjugation> ::=
	2         <en-trie-present-participle> |
	3         <en-trie-past-participle> |
	<to-be-able-to-tabulation>

<to-be-able-to-tabulation> ::=
	a1+       can ++1 |
	a1-       cannot ++1 |
	a2+       could ++1 |
	a2-       could not ++1 |
	a3        ( t1 auxiliary-have ) been able to ++1 |
	a4        ( t2 auxiliary-have ) been able to ++1 |
	a5+       will be able to ++1 |
	a5-       will not be able to ++1

@ Inform has only a simple understanding of what "can" means, so it doesn't
allow the source text to use "can" in combination with arbitrary verbs.
Instead, each legal combination has to be declared explicitly:

>> To be able to reach is a verb meaning ...

Inform implements all of this by passing "be able to reach" through the
same verb-conjugation mechanisms as all other verbs ("take", "see", and
so on). But at least the conjugation used is now simple. Recall that when
the instructions grammar, right back at the start of this discussion of
verbs, chooses which conjugation to use, it converts the text matching
the wild-card |...| into the "adjoint infinitive" form (4). We get to
this conjugation by matching
= (text as InC)
	be able to ...
=
so, for example, "be able to reach" results in 4 being set to "reach".

Note also the construction |3 ( 4 )| in the passive. The 3 means "take the
past participle of the verb in brackets", and the 4 means that the text of
this verb's infinitive is the contents of verb form 4. So, for example,
for "be able to reach", |3 ( 4 )| expands to |3 ( reach )| which expands
to "reached", and we get passive forms like "Peter can be reached by
Jane".

=
<to-be-able-to-auxiliary> ::=
	2        <en-trie-present-participle> |
	3        <en-trie-past-participle> |
	<to-be-able-to-auxiliary-tabulation>

<to-be-able-to-auxiliary-tabulation> ::=
	a        ( be able to ) 4 |
	p        ( be able to ) be 3 ( 4 ) by

@ The following handles the other English modal verbs ("might", "should"
and so on) surprisingly easily. The notation |++1| means that the verb
being modified should appear in verb form 1, and so on: for example,
"might not lead" as "might not" plus form 1 of "to lead", i.e., "lead".

=
<modal-conjugation> ::=
	2         <en-trie-present-participle> |
	3         <en-trie-past-participle> |
	<modal-tabulation>

<modal-tabulation> ::=
	a1+       4 ++1 |
	a1-       4 not ++1 |
	a2+       4 have ++2 |
	a2-       4 not have ++2 |
	a3+       4 have ++2 |
	a3-       4 not have ++2 |
	a4+       4 have ++2 |
	a4-       4 not have ++2 |
	a5+       4 ++1 |
	a5-       4 not ++1

@ That completes our basic kit of verbs nicely. What's left is used only
for generating text at run-time -- for printing adaptive messages, that is;
none of these oddball exceptional cases is otherwise used as a verb in
Inform source text. None of them has any meaning to Inform.

Inform could fairly easily support the contractions "isn't", "aren't",
"wasn't", "can't" and so on, but we've chosen not to do so. They save
very little typing, and they greatly change the aesthetic style of Inform
source text without changing its functionality. (If we allowed them, some
authors would use them all the time, and other authors never, but others
still would mix them incoherently.)

But we still want people to be able to write adaptive text which uses
these contracted forms: otherwise, how could we write classic messages
like

>> You can't go that way.

and have them adapt to other tenses and viewpoints?

First we'll tackle "to 's", the contracted form of "to be": I'm, you're,
and so on. Exactly how these contractions are used in different tenses is
something that varies with different dialects of English -- for example,
"you'll not take the ball" is now a little obsolete except in rural
dialects -- and we aren't even going to try to cope with that.

=
<contracted-to-be-conjugation> ::=
	2 being |
	3 been |
	<not-instance-of-verb-at-run-time> |
	<contracted-to-be-tabulation>

<contracted-to-be-tabulation> ::=
	a1+        <contracted-to-be-present> |
	a1-        <contracted-to-be-present> not |
	a2+        <contracted-to-be-past> |
	a2-        <contracted-to-be-past-negated> |
	a3+        <contracted-to-have-present> been |
	a3-        <contracted-to-have-present> not been |
	a4+        'd been |
	a4-        'd not been |
	a5+        'll be |
	a5-        'll not be

<contracted-to-be-present> ::=
	'm | 're | 's | 're | 're | 're

<contracted-to-be-past> ::=
	was | were | was | were | were | were

<contracted-to-be-past-negated> ::=
	wasn't | weren't | wasn't | weren't | weren't | weren't

@ And now "to 've", the contracted form of "to have". A subtle dialect
point here concerns the negated present tense:

>> Sorry, I don't have a clue. [US]
>> Sorry, I haven't got a clue. [British]
>> Sorry, I haven't a clue. [British, but antiquated]
>> Sorry, I didn't have a clue. [US or British]
>> Sorry, I hadn't got a clue. [British]

But the American forms are becoming more common in British English, so we'll
go with those.

=
<contracted-to-have-conjugation> ::=
	2 having |
	3 had |
	<not-instance-of-verb-at-run-time> |
	<contracted-to-have-tabulation>

<contracted-to-have-tabulation> ::=
	a1+        <contracted-to-have-present> |
	a1-        <contracted-to-have-present> not |
	a2+        had |
	a2-        hadn't |
	a3+        <contracted-to-have-present> had |
	a3-        <contracted-to-have-present> not had |
	a4+        'd had |
	a4-        'd not had |
	a5+        'll have |
	a5-        'll not have

<contracted-to-have-present> ::=
	've | 've | 's | 've | 've | 've

@ Now we come to "aren't", a negated form of "to be", but where the
contraction occurs between the verb and the "not" rather than between
the subject and the verb.

Again, Inform doesn't know or care what this means. We're simply going to teach
it to conjugate it as if it were a verb in its own right. So "to aren't" will be
conjugated "I am not", "you aren't", "he isn't", and so on. (We don't
say "I amn't", possibly because the "mn" is too awkward, but possibly
also because we'd more likely say "I'm not". Because this would make the
spacing awkwardly difficult -- we would need to backspace -- we won't take
that option here.)

=
<arent-conjugation> ::=
	2 <en-trie-present-participle> |
	3 <en-trie-past-participle> |
	<not-instance-of-verb-at-run-time> |
	<arent-tabulation>

<arent-tabulation> ::=
	a1+        <arent-present> |
	a2+        <arent-past> |
	a3+        <arent-perfect> |
	a4+        hadn't been |
	a5+        won't be

<arent-present> ::=
	am not | aren't | isn't | aren't | aren't | aren't

<arent-past> ::=
	wasn't | weren't | wasn't | weren't | weren't | weren't

<arent-perfect> ::=
	haven't been |    haven't been | hasn't been | haven't been | haven't been | haven't been

@ And finally: the contracted informal negatives of various modal verbs which
it's useful to be able to print, like the "can't" in

>> You can't go that way.

English has more modal verbs than one tends to remember, and the definition
of "modal" itself arguable. This is the best we can do.

=
<informal-negated-modal-conjugation> ::=
	2         <en-trie-present-participle> |
	3         <en-trie-past-participle> |
	5         <en-trie-modal-contracted-past> |
	6         <en-trie-modal-contracted-future> |
	7         <en-trie-modal-contracted-present> |
	<not-instance-of-verb-at-run-time> |
	<informal-negated-modal-tabulation>

<informal-negated-modal-tabulation> ::=
	a1+        <informal-negated-modal-present> ++1 |
	a2+        5 ++2 |
	a3+        5 ++2 |
	a4+        5 ++2 |
	a5+        6 ++1

<informal-negated-modal-present> ::=
	1 | 1 | 7 | 1 | 1 | 1

@ Together with special rules for can't, which is inevitably slightly different:

=
<cant-modal-conjugation> ::=
	2         <en-trie-present-participle> |
	3         <en-trie-past-participle> |
	<not-instance-of-verb-at-run-time> |
	<cant-modal-tabulation>

<cant-modal-tabulation> ::=
	a1+        can't ++1 |
	a2+        couldn't ++1 |
	a3+        ( t1 haven't ) been able to ++1 |
	a4+        ( t2 haven't ) been able to ++1 |
	a5+        won't be able to ++1

@ We have special tries just to list the forms of the cases we will
deal with. Tries can do fancy things (see below), but here they act just as
a look-up table: for example, "won't" has present "won't", past
"wouldn't" and future "won't".

Note that results of tries normally have to be single words; but that plus
signs can be used if we absolutely have to introduce spaces.

=
<en-trie-modal-contracted-present> ::=
	can't       can't |
	don't       doesn't |
	haven't     hasn't |
	won't       won't |
	mayn't      mayn't |
	mightn't    mightn't |
	mustn't     mustn't |
	wouldn't    wouldn't |
	couldn't    couldn't |
	shouldn't   shouldn't

<en-trie-modal-contracted-past> ::=
	can't       couldn't |
	don't       didn't |
	haven't     hadn't |
	won't       wouldn't |
	mayn't      mayn't+have |
	mightn't    mightn't+have |
	mustn't     mustn't+have |
	wouldn't    wouldn't+have |
	couldn't    couldn't+have |
	shouldn't   shouldn't+have

<en-trie-modal-contracted-future> ::=
	can't       won't+be+able+to |
	don't       won't |
	haven't     won't+have |
	won't       won't |
	mayn't      mayn't |
	mightn't    mightn't |
	mustn't     mustn't |
	wouldn't    wouldn't |
	couldn't    couldn't |
	shouldn't   shouldn't

@ That's the end of the conjugations -- the easy part, it turns out. We now
need to create the four tries to make verb forms out of the infinitive:
the present participle, the past participle, the third-person singular
present tense, and the past tense.

We'll start with the present participle. This is actually quite hard,
because in some cases it depends on pronunciation rather than spelling.
Greenbaum's "Oxford English Grammar" summarises the general rules at
4.16, as follows:

(a) If the base ends in -e but not -ee, -oe or -ye, drop the final -e before
adding -ing: thus drive to driving, but see to seeing, dye to dyeing, and so on.

(b) If the base ends in -ie, as well as dropping the -e, also change the -i
to -y: thus die to dying, untie to untying.

(c) If the base ends in a stressed syllable whose spelling ends with a single
vowel and then a single consonant, then double the consonant before adding -ing.
Thus tip to tipping (not tiping), but break to breaking (not breakking).

(d) If the base ends in a vowel and then -c, add -king. This is not quite the
same as consonant doubling and doesn't depend on the stress; thus mimic to
mimicking, picnic to picnicking.

These are fairly clear-cut rules, though English doesn't enforce them in all
cases, so that most dictionaries let you say either focusing or focussing, for
example, and either gluing or glueing (note that rule (a) drops the -e from
-ue endings, but it's not at all clear why this case should be different,
which may be why people are doubtful here); and in America participles like
traveling or programing or worshiping are allowed by some people (with -l, -m,
-me, -p endings), but they aren't universal. Inform will stick to traditional
English as described above.

The tricky thing is that (c) is really a phonetic rule, not a spelling rule.
For example, we need to count a final -y and -w as vowels, not consonants,
because that's what they sound like. But at least that can be read from the
spelling, whereas the presence or absence of stress can't. An English word
generally stresses just one syllable, and always stresses at least one, so
a monosyllabic word is always stressed. With a polysyllabic word, there's
no easy way to tell. Consider deter to deterring (stress on second syllable
of deter), but meter to metering (stress on first syllable of meter).

@ The following algorithm is due to Toby Nelson, who produced it from a
dictionary of 14,689 English verbs, some of them quite obscure (to torpefy,
anyone? to spuilzie? to cachinnate?). It's essentially a more detailed
version of Greenbaum's rules above.

=
<en-trie-present-participle> ::=
	... <en-trie-irregular-present-participle> |
	... <en-trie-irregular-compound-present-participle> |
	... <en-trie-regular-a-present-participle> |
	... <en-trie-regular-b-present-participle> |
	... <en-trie-regular-c-present-participle>

@ First of all there are some irregular cases -- some for the usual suspects,
but others for oddball verbs where English breaks the normal phonetic rules
for the sake of clarity. For example, the participle of "singe" ought to
be "singing", but in fact we write "singeing", purely to make it different
from the act of producing a song.

=
<en-trie-irregular-present-participle> ::=
	boob      0ing   |
	had       0ding  |
	quad      0ding  |
	quod      0ding  |
	squid     0ding  |
	whid      0ding  |
	ballad    0ing   |
	salad     0ing   |
	invalid   0ing   |
	ref       0fing  |
	stravaig  0ing   |
	scoog     0ing   |
	scoug     0ing   |
	yak       0king  |
	yok       0king  |
	lek       0king  |
	trek      0king  |
	spaniel   0ling  |
	vermeil   0ling  |
	madam     0ing   |
	buckram   0ing   |
	hem       0ming  |
	emblem    0ing   |
	item      0ing   |
	slalom    0ing   |
	alarum    0ing   |
	possum    0ing   |
	chalan    0ing   |
	challan   0ing   |
	tyran     0ning  |
	den       0ning  |
	hen       0ning  |
	ken       0ning  |
	misken    0ning  |
	pen       0ning  |
	unpen     0ning  |
	sten      0ning  |
	in        0ning  |
	gin       0ning  |
	begin     0ning  |
	bin       0ning  |
	sin       0ning  |
	damaskin  0ing   |
	trampolin 0ing   |
	chagrin   0ing   |
	satin     0ing   |
	on        0ning  |
	con       0ning  |
	don       0ning  |
	kon       0ning  |
	fillip    0ing   |
	turnip    0ing   |
	sip       0ping  |
	cop       0ping  |
	lop       0ping  |
	clop      0ping  |
	flop      0ping  |
	plop      0ping  |
	slop      0ping  |
	galop     0ping  |
	up        0ping  |
	cup       0ping  |
	gar       0ring  |
	mortar    0ing   |
	sker      0ring  |
	deter     0ring  |
	inter     0ring  |
	disinter  0ring  |
	reinter   0ring  |
	aver      0ring  |
	abhor     0ring  |
	vor       0ring  |
	demur     0ring  |
	fur       0ring  |
	smur      0ring  |
	caucus    0ing   |
	sus       0sing  |
	combat    0ing   |
	ballat    0ing   |
	curat     0ing   |
	quadrat   0ing   |
	bet       0ting  |
	abet      0ting  |
	fet       0ting  |
	fidget    0ing   |
	target    0ing   |
	crochet   0ing   |
	epithet   0ing   |
	ratchet   0ing   |
	let       0ting  |
	blet      0ting  |
	leaflet   0ting  |
	relet     0ting  |
	sublet    0ting  |
	underlet  0ting  |
	net       0ting  |
	benet     0ting  |
	overnet   0ting  |
	pet       0ting  |
	spet      0ting  |
	ret       0ting  |
	aret      0ting  |
	fret      0ting  |
	regret    0ting  |
	basset    0ing   |
	closet    0ing   |
	corset    0ing   |
	cosset    0ing   |
	gusset    0ing   |
	posset    0ing   |
	roset     0ing   |
	russet    0ing   |
	briquet   0ting  |
	coquet    0ting  |
	duet      0ting  |
	parquet   0ting  |
	covet     0ing   |
	unrivet   0ing   |
	velvet    0ing   |
	discomfit 0ing   |
	profit    0ing   |
	limit     0ing   |
	delimit   0ing   |
	vomit     0ing   |
	rit       0ting  |
	frit      0ting  |
	grit      0ting  |
	bit       0ting  |
	dit       0ting  |
	kit       0ting  |
	sit       0ting  |
	besit     0ting  |
	outsit    0ting  |
	resit     0ting  |
	picot     0ing   |
	ballot    0ing   |
	pilot     0ing   |
	parrot    0ing   |
	debut     0ing   |
	brut      0ing   |
	div       0ing   |
	ante      0ing   | /* miscellaneous -e exceptions */
	be        0ing   |
	binge     0ing   |
	birdie    0ing   |
	centre    0ing   |
	chasse    0ing   |
	cicerone  0ing   |
	dele      0ing   |
	ensilage  0ing   |
	facsimile 0ing   |
	glace     0ing   |
	jeelie    0ing   |
	longe     0ing   |
	lunge     0ing   |
	ouglie    0ing   |
	peenge    0ing   |
	pie       0ing   |
	quaere    0ing   |
	queue     0ing   |
	recce     0ing   |
	route     0ing   |
	reroute   0ing   |
	restringe 0ing   |
	saute     0eing  |
	schappe   0ing   |
	segue     0ing   |
	singe     0ing   |
	sortie    0ing   |
	stymie    0ing   |
	winge     0ing   |
	swinge    0ing   |
	tinge     0ing   |
	unbe      0ing   |
	vise      0ing   |
	vogue     1ing   |
	whinge    0ing   |
	aleye     1ing   | /* a few -ye exceptions */
	baye      1ing   |
	herye     1ing   |
	nye       1ing   |
	rallye    1ing   |
	reaedifye 1ing   |
	stye      1ing   |
	undersaye 1ing

@ Now some exceptional forms where consonant doubling doesn't occur:

=
<en-trie-irregular-compound-present-participle> ::=
	*<gosyz>ie  0ing   |   /* e.g. boogieing */
	*ae         0ing   |   /* e.g. spaeing */
	*quit       0ting  |   /* acquitting, quitting, requitting */
	*uret       0ting  |   /* carburetting, sulphuretting */
	*budget     0ing   |   /* budgeting, underbudgeting */
	*efer       0ring  |   /* deferring, preferring, referring */
	*nfer       0ring  |   /* conferring, inferring */
	*sfer       0ring  |   /* retransferring, transferring */
	*bias       0sing  |   /* biassing, unbiassing */
	*bishop     0ing   |   /* bishoping, unbishoping */
	*woman      0ing   |   /* womaning, unwomaning */
	*jambok     0king  |   /* jambokking, sjambokking */
	*alog       0ing   |   /* dialoging, cataloging */
	*daub       0ing       /* daubing, bedaubing */

@ And now rules for consonant doubling:

=
<en-trie-regular-a-present-participle> ::=
	*<aeiouy>b             0bing      |
	*<dglmpw>ad            0ding      |
	*<bhlnrtw>ed           0ding      |
	*<bklr>id              0ding      |
	*<cdghlnprst>od        0ding      |
	*<bchmprtw>ud          0ding      |
	*uf                    0fing      |
	*<aeiouy>g             0ging      |
	*<bcdhiklmnprstuv>al   0ling      |
	*<bcdfghkmnprstuvwz>el 0ling      |
	*<cfmnrtv>il           0ling      |
	*<bcrtv>ol             0ling      |
	*<cn>ul                0ling      |
	*<bcdghjlprw>am        0ming      |
	*<glt>em               0ming      |
	*<dhklnrw>im           0ming      |
	*lom                   0ming      |
	*<bcghlmrstv>um        0ming      |
	*<bcflmptvw>an         0ning      |
	*<ry>en                0ning      |
	*<dhklprtw>in          0ning      |
	*<fw>on                0ning      |
	*<dfghprst>un          0ning      |
	*<cdghjlmnprstwyz>ap   0ping      |
	*<klprt>ep             0ping      |
	*<dhklnprtuyz>ip       0ping      |
	*<bdhmprstuw>op        0ping      |
	*<dhpst>up             0ping      |
	*yp                    0ping      |
	*<bcfhjmnptw>ar        0ring      |
	*<fhmst>ir             0ring      |
	*dor                   0ring      |
	*<bclp>ur              0ring      |
	*<bgmpv>as             0sing      |
	*<mnrsu>es             0sing      |
	*<hmpw>is              0sing      |
	*<bcds>os              0sing      |
	*<bclm>us              0sing      |
	*<bcfhlmprtuvw>at      0ting      |
	*<ghjstvw>et           0ting      |
	*<fhlmnptw>it          0ting      |
	*<bcdhjlnprstw>ot      0ting      |
	*<bcghjlmnprt>ut       0ting      |
	*<ei>v                 0ving      |
	*iz                    0zing

@ Finally:

=
<en-trie-regular-b-present-participle> ::=
    *<aeiou>c    0king      |
    *<eoy>e      0ing       |
    *ie          2ying

<en-trie-regular-c-present-participle> ::=
    *e           1ing       |
    *            0ing

@ Next the past participle. As noted above, for most verbs this is the same
as the past (e.g., he agreed and it was agreed); but there's a list of
exceptions for Anglo-Saxon survivals (e.g., he chose and it was chosen).
The exceptional cases were derived from Wikipedia's catalogue of irregular
English verbs as it stood in May 2011, with a few archaisms and obscenities
removed.

=
<en-trie-past-participle> ::=
	<en-trie-irregular-past-participle> |
	<en-trie-past>

<en-trie-irregular-past-participle> ::=
	be          been |
	have        had |
	do          did |
	arise       arisen |
	awake       awoken |
	bear        borne |
	beat        beaten |
	become      become |
	befall      befallen |
	beget       begotten |
	begin       begun |
	bespeak     bespoken |
	bite        bitten |
	blow        blown |
	break       broken |
	browbeat    browbeaten |
	choose      chosen |
	cleave      cloven |
	come        come |
	dive        dived |
	draw        drawn |
	drink       drunk |
	drive       driven |
	eat         eaten |
	fall        fallen |
	fly         flown |
	forbear     forborne |
	forbid      forbidden |
	forego      foregone |
	foreknow    foreknown |
	forelie     forlain |
	forerun     forerun |
	foresee     foreseen |
	forget      forgotten |
	forgive     forgiven |
	forgo       forgone |
	forsake     forsaken |
	forswear    forsworn |
	freeze      frozen |
	ghostwrite  ghostwritten |
	give        given |
	go          gone |
	grow        grown |
	hew         hewn |
	hide        hidden |
	interweave  interwoven |
	know        known |
	lade        laden |
	misbecome   misbecome |
	misbeget    misbegotten |
	mischoose   mischosen |
	misdo       misdone |
	misget      misgotten |
	misgive     misgiven |
	misknow     misknown |
	misshape    misshapen |
	misspeak    misspoken |
	mistake     mistaken |
	miswrite    miswritten |
	mow         mown |
	outdo       outdone |
	outgrow     outgrown |
	outgrow     outgrown |
	outrun      outrun |
	outshine    outshone |
	outswear    outsworn |
	outthrow    outthrown |
	overbear    overborne |
	overblow    overblown |
	overclothe  overclad |
	overcome    overcome |
	overdo      overdone |
	overdraw    overdrawn |
	overdrink   overdrunk |
	overdrive   overdriven |
	overeat     overeaten |
	overfly     overflown |
	overgrow    overgrown |
	overlie     overlain |
	override    overridden |
	overrun     overrun |
	oversee     overseen |
	oversew     oversewn |
	overshake   overshaken |
	overstride  overstridden |
	overtake    overtaken |
	overwear    overworn |
	overwrite   overwritten |
	partake     partaken |
	plead       pled |
	redo        redone |
	redraw      redrawn |
	regrow      regrown |
	rerun       rerun |
	resing      resung |
	retake      retaken |
	retread     retrodden |
	rewrite     rewritten |
	ride        ridden |
	ring        rung |
	rise        risen |
	rive        riven |
	run         run |
	saw         sawn |
	see         seen |
	sew         sewn |
	shake       shaken |
	shave       shaven |
	shear       shorn |
	shine       shone |
	shoe        shodden |
	show        shown |
	shrink      shrunk |
	shrive      shriven |
	sing        sung |
	sink        sunk |
	slay        slain |
	smite       smitten |
	sow         sown |
	speak       spoken |
	spin        spun |
	spit        spit |
	spring      sprung |
	steal       stolen |
	stink       stunk |
	stride      stridden |
	bestride    bestridden |
	strike      stricken |
	strive      striven |
	swear       sworn |
	swell       swollen |
	take        taken |
	tear        torn |
	thrive      thriven |
	throw       thrown |
	tread       trodden |
	underbear   underborne |
	underdo     underdone |
	underdraw   underdrawn |
	undergo     undergone |
	undergrow   undergrown |
	underrun    underrun |
	undertake   undertaken |
	underwrite  underwritten |
	undo        undone |
	wake        woken |
	wear        worn |
	weave       woven |
	withdraw    withdrawn |
	wring       wrung |
	write       written

@ That's the mandatory participles sorted out; so now we move on to the two
additional verb forms used by English. First, the present form: a curiosity
of English is that this is almost always formed as if it were the plural of the
infinitive -- thus "touch" becomes "touches". There are just a handful
of exceptions to this.

=
<en-trie-present-verb-form> ::=
	<en-trie-irregular-third-person-present> |
	... <singular-noun-to-its-plural>

<en-trie-irregular-third-person-present> ::=
	be          is |
	have        has |
	do          does

@ Second, the past. This is harder. Once again we have a catalogue of
Anglo-Saxon past forms (e.g., he chose, not he chooses); and after those
are out of the way, the rules are the same as for the present participle,
except for adding -ed instead of -ing. The tricky part, again, is spotting
when to double the consonant, which again depends on stress.

=
<en-trie-past> ::=
	... <en-trie-irregular-past> |
	... <en-trie-irregular-compound-past> |
	... <en-trie-regular-a-past> |
	... <en-trie-regular-b-past> |
	... <en-trie-regular-c-past>

<en-trie-irregular-past> ::=
	be     was |
	do     did |
	go     went |
	in     0ned |
	on     0ned |
	up     0ped |
	bet    bet |
	abet   0ted |
	bid    bid |
	bin    0ned |
	bit    0ted |
	buy    bought |
	con    0ned |
	cop    0ped |
	cup    0ped |
	cut    cut |
	den    0ned |
	dig    dug |
	dit    0ted |
	div    0ed |
	don    0ned |
	eat    ate |
	fet    0ted |
	fit    fitted |
	fly    flew |
	fur    0red |
	gar    0red |
	get    got |
	gin    0ned |
	had    0ded |
	hem    0med |
	hen    0ned |
	hit    hit |
	ken    0ned |
	kit    0ted |
	kon    0ned |
	lay    laid |
	lek    0ked |
	let    let |
	let    0ted |
	lop    0ped |
	net    0ted |
	ante   0ed |
	nye    1ed |
	pay    paid |
	pen    penned |
	pet    0ted |
	pie    1ed |
	put    put |
	ref    0fed |
	ret    0ted |
	aret   0ted |
	rid    rid |
	rit    0ted |
	run    ran |
	say    said |
	see    saw |
	set    set |
	sin    0ned |
	sip    0ped |
	sit    sat |
	sus    0sed |
	aver   0red |
	vor    0red |
	wed    wedded |
	wet    wetted |
	win    won |
	yak    0ked |
	yok    0ked |
	baye   1ed |
	bear   bore |
	beat   beat |
	bend   bent |
	abhor  0red |
	abide  abided |
	bide    bided |
	bind    bound |
	bite    bit |
	blet    0ted |
	blow    blew |
	boob    0ed |
	brut    0ed |
	burn    burnt |
	cast    cast |
	clop    0ped |
	come    came |
	deal    dealt |
	dele    1ed |
	dive    dove |
	drag    dragged |
	draw    drew |
	duet    0ted |
	fall    fell |
	feed    fed |
	feel    felt |
	find    found |
	flee    fled |
	flop    0ped |
	fret    0ted |
	frit    0ted |
	give    gave |
	grit    0ted |
	grow    grew |
	hang    hung |
	have    had |
	hear    heard |
	hide    hid |
	hold    held |
	hurt    hurt |
	item    0ed |
	keep    kept |
	knit    knit |
	know    knew |
	lade    laded |
	lead    led |
	lend    lent |
	aleye   1ed |
	lose    lost |
	make    made |
	mean    meant |
	meet    met |
	plop    0ped |
	quad    0ded |
	quit    quit |
	quod    0ded |
	read    read |
	redo    redid |
	rend    rent |
	ride    rode |
	ring    rang |
	arise   arose |
	rise    rose |
	rive    rove |
	seek    sought |
	sell    sold |
	send    sent |
	shed    shed |
	shoe    shoed |
	shut    shut |
	sing    sang |
	sink    sank |
	sker    0red |
	slip    slipped |
	slit    slit |
	slop    0ped |
	smur    0red |
	spet    0ted |
	spin    span |
	spit    spat |
	sten    0ned |
	stye    1ed |
	swim    swam |
	take    took |
	tear    tore |
	tell    told |
	trek    0ked |
	unbe    1ed |
	undo    undid |
	vise    1ed |
	awake   awoke |
	wake    woke |
	wear    wore |
	weep    wept |
	whid    0ded |
	wind    wound |
	beget    begot |
	begin    began |
	benet    0ted |
	beset    beset |
	besit    0ted |
	binge    1ed |
	bleed    bled |
	break    broke |
	breed    bred |
	bring    brought |
	build    built |
	burst    burst |
	catch    caught |
	cling    clung |
	covet    0ed |
	creep    crept |
	curat    0ed |
	debut    0ed |
	demur    0red |
	deter    0red |
	drink    drank |
	drive    drove |
	fight    fought |
	fling    flung |
	forgo    forwent |
	galop    0ped |
	glace    0ed |
	grind    ground |
	herye    1ed |
	hoise    hoist |
	inlay    inlaid |
	input    input |
	inset    inset |
	inter    0red |
	kneel    knelt |
	alarum   0ed |
	leave    left |
	light    lit |
	limit    0ed |
	longe    1ed |
	lunge    1ed |
	madam    0ed |
	misdo    misdid |
	outdo    outdid |
	picot    0ed |
	pilot    0ed |
	prove    proved |
	queue    1ed |
	reave    reft |
	recce    1ed |
	recut    recut |
	relet    0ted |
	repay    repaid |
	rerun    reran |
	reset    reset |
	resit    0ted |
	roset    0ed |
	route    1ed |
	salad    0ed |
	satin    0ed |
	saute    0ed |
	scoog    0ed |
	scoug    0ed |
	segue    1ed |
	shake    shook |
	shall    should |
	shape    shaped |
	shave    shaved |
	shine    shined |
	shoot    shot |
	singe    1ed |
	sleep    slept |
	slide    slid |
	sling    slung |
	slink    slunk |
	smite    smote |
	speak    spoke |
	speed    sped |
	spell    spelt |
	spend    spent |
	split    split |
	squid    0ded |
	stand    stood |
	steal    stole |
	stick    stuck |
	sting    stung |
	stink    stank |
	swear    swore |
	sweep    swept |
	swing    swung |
	teach    taught |
	think    thought |
	throw    threw |
	tinge    1ed |
	tread    trod |
	tyran    0ned |
	unpen    0ned |
	unset    unset |
	upset    upset |
	vogue    1ed |
	vomit    0ed |
	weave    wove |
	winge    1ed |
	worth    worth |
	wring    wrang |
	write    wrote |
	ballad    0ed |
	ballat    0ed |
	ballot    0ed |
	basset    0ed |
	become    became |
	befall    befell |
	behold    beheld |
	birdie    1ed |
	caucus    0ed |
	centre    1ed |
	chalan    0ed |
	chasse    1ed |
	choose    chose |
	cleave    clove |
	closet    0ed |
	clothe    clothed |
	combat    0ed |
	coquet    0ted |
	corset    0ed |
	cosset    0ed |
	emblem    0ed |
	fidget    0ed |
	fillip    0ed |
	forbid    forbade |
	forego    forewent |
	forget    forgot |
	freeze    froze |
	gusset    0ed |
	jeelie    1ed |
	misfit    misfitted |
	misget    misgot |
	mishit    mishit |
	misken    0ned |
	mislay    mislaid |
	missay    missaid |
	misset    misset |
	mortar    0ed |
	naysay    naysaid |
	ouglie    1ed |
	outbid    outbid |
	output    output |
	outrun    outran |
	outsit    outsat |
	overdo    overdid |
	parrot    0ed |
	peenge    1ed |
	posset    0ed |
	possum    0ed |
	prepay    prepaid |
	preset    preset |
	profit    0ed |
	quaere    1ed |
	rallye    1ed |
	recast    recast |
	redraw    redrew |
	regret    0ted |
	regrow    regrew |
	re-lay    re-laid |
	remake    remade |
	reread    reread |
	resell    resold |
	resend    resent |
	resing    resang |
	retake    retook |
	retell    retold |
	rewind    rewound |
	russet    0ed |
	shrink    shrank |
	shrive    shrove |
	slalom    0ed |
	sortie    1ed |
	spread    spread |
	spring    sprang |
	stride    strode |
	strike    struck |
	string    strung |
	strive    strove |
	stymie    1ed |
	sublet    sublet |
	sunset    sunset |
	swinge    1ed |
	target    0ed |
	thrive    throve |
	turnip    0ed |
	unbend    unbent |
	unbind    unbound |
	unhear    unheard |
	unmake    unmade |
	unwind    unwound |
	uphold    upheld |
	velvet    0ed |
	waylay    waylaid |
	whinge    1ed |
	writhe    writhed |
	beseech    besought |
	bespeak    bespoke |
	briquet    0ted |
	buckram    0ed |
	chagrin    0ed |
	challan    0ed |
	crochet    0ed |
	delimit    0ed |
	epithet    0ed |
	forbear    forbore |
	forelay    forelaid |
	forelie    forlay |
	forerun    foreran |
	foresee    foresaw |
	forgive    forgave |
	forsake    forsook |
	gainsay    gainsaid |
	inbreed    inbred |
	invalid    0ed |
	leaflet    0ted |
	lipread    lipread |
	miscast    miscast |
	misdeal    misdealt |
	misfeed    misfed |
	misgive    misgave |
	mishear    misheard |
	mishold    misheld |
	miskeep    miskept |
	misknow    misknew |
	mislead    misled |
	misread    misread |
	missend    missent |
	mistake    mistook |
	outgrow    outgrew |
	outride    outrode |
	outsell    outsold |
	outswim    outswam |
	outtell    outtold |
	outwear    outwore |
	overbid    overbid |
	overbuy    overbought |
	overeat    overate |
	overfly    overflew |
	overhit    overhit |
	overlay    overlaid |
	overlie    overlay |
	overnet    0ted |
	overpay    overpaid |
	overrun    overran |
	oversee    oversaw |
	overset    overset |
	parquet    0ted |
	partake    partook |
	podcast    podcast |
	precast    precast |
	quadrat    0ed |
	ratchet    0ed |
	rebuild    rebuilt |
	reinter    0red |
	reroute    1ed |
	reshoot    reshot |
	rethink    rethought |
	retread    retrod |
	rewrite    rewrote |
	schappe    1ed |
	spaniel    0led |
	underdo    underdid |
	undergo    underwent |
	unrivet    0ed |
	vermeil    0led |
	webcast    webcast |
	backbite    backbit |
	bespread    bespread |
	bestride    bestrode |
	browbeat    browbeat |
	cicerone    1ed |
	crosscut    crosscut |
	damaskin    0ed |
	disinter    0red |
	ensilage    1ed |
	forecast    forecast |
	foreknow    foreknew |
	foretell    foretold |
	forswear    forswore |
	intercut    intercut |
	misbeget    misbegot |
	misshape    misshaped |
	misshoot    misshot |
	misspeak    misspoke |
	misspell    misspelt |
	misspend    misspent |
	miswrite    miswrote |
	outdrink    outdrunk |
	outfight    outfought |
	outshine    outshone |
	outspend    outspent |
	outswear    outswore |
	outthink    outthought |
	outthrow    outthrew |
	overbear    overbore |
	overbend    overbent |
	overblow    overblew |
	overcast    overcast |
	overcome    overcame |
	overdraw    overdrew |
	overfeed    overfed |
	overgrow    overgrew |
	overhang    overhung |
	overhear    overheard |
	overlend    overlent |
	override    overrode |
	oversell    oversold |
	overslip    overslipped |
	overtake    overtook |
	overwear    overwore |
	sightsee    sightsaw |
	stravaig    0ed |
	telecast    telecast |
	unclothe    unclothed |
	underbid    underbid |
	underbuy    underbought |
	undercut    undercut |
	underdig    underdug |
	underlay    underlaid |
	underlet    0ted |
	underlie    underlaid |
	underpay    underpaid |
	underrun    underran |
	unfreeze    unfroze |
	withdraw    withdrew |
	withhold    withheld |
	broadcast    broadcast |
	discomfit    0ed |
	facsimile    1ed |
	misbecome    misbecame |
	mischoose    mischose |
	outthrust    outthrust |
	overbreed    overbred |
	overbuild    overbuilt |
	overdrink    overdrank |
	overdrive    overdrove |
	overshake    overshook |
	overshine    overshone |
	overshoot    overshot |
	oversleep    overslept |
	overslide    overslid |
	overspend    overspent |
	overswing    overswung |
	overwrite    overwrote |
	proofread    proofread |
	reaedifye    1ed |
	restringe    1ed |
	simulcast    simulcast |
	trampolin    0ed |
	underbear    underbore |
	underbind    underbound |
	undercast    undercast |
	underdraw    underdrew |
	underfeed    underfed |
	undergrow    undergrew |
	underhang    underhung |
	undersaye    1ed |
	undersell    undersold |
	undertake    undertook |
	withstand    withstood |
	ghostwrite    ghostwrote |
	interbreed    interbred |
	interweave    interwove |
	overclothe    overclothed |
	overstride    overstrode |
	underbuild    underbuilt |
	undershoot    undershot |
	underspend    underspent |
	understand    understood |
	underwrite    underwrote |
	underclothe    underclothed |
	misunderstand    misunderstood

<en-trie-irregular-compound-past> ::=
	*<gosyz>ie 1ed   |   /* e.g. boogied  */
	*ae        1ed   |   /* e.g. spaed  */
	*quit     0ted   |   /* acquitted , quitted , requitted  */
	*uret     0ted   |   /* carburetted , sulphuretted  */
	*budget   0ed    |   /* budgeted , underbudgeted  */
	*efer     0red   |   /* deferred , preferred , referred  */
	*nfer     0red   |   /* conferred , inferred  */
	*sfer     0red   |   /* retransferred , transferred  */
	*bias     0sed   |   /* biassed , unbiassed  */
	*bishop   0ed    |   /* bishoped , unbishoped  */
	*woman    0ed    |   /* womaned , unwomaned  */
	*jambok   0ked   |   /* jambokked , sjambokked  */
	*alog     0ed    |   /* dialoged , cataloged  */
	*daub     0ed        /* daubed , bedaubed  */

<en-trie-regular-a-past> ::=
	*<aeiouy>b             0bed       |
	*<dglmpw>ad            0ded       |
	*<bhlnrtw>ed           0ded       |
	*<bklr>id              0ded       |
	*<cdghlnprst>od        0ded       |
	*<bchmprtw>ud          0ded       |
	*uf                    0fed       |
	*<aeiouy>g             0ged       |
	*<bcdhiklmnprstuv>al   0led       |
	*<bcdfghkmnprstuvwz>el 0led       |
	*<cfmnrtv>il           0led       |
	*<bcrtv>ol             0led       |
	*<cn>ul                0led       |
	*<bcdghjlprw>am        0med       |
	*<glt>em               0med       |
	*<dhklnrw>im           0med       |
	*lom                   0med       |
	*<bcghlmrstv>um        0med       |
	*<bcflmptvw>an         0ned       |
	*<ry>en                0ned       |
	*<dhklprtw>in          0ned       |
	*<fw>on                0ned       |
	*<dfghprst>un          0ned       |
	*<cdghjlmnprstwyz>ap   0ped       |
	*<klprt>ep             0ped       |
	*<dhklnprtuyz>ip       0ped       |
	*<bdhmprstuw>op        0ped       |
	*<dhpst>up             0ped       |
	*yp                    0ped       |
	*<bcfhjmnptw>ar        0red       |
	*<fhmst>ir             0red       |
	*dor                   0red       |
	*<bclp>ur              0red       |
	*<bgmpv>as             0sed       |
	*<mnrsu>es             0sed       |
	*<hmpw>is              0sed       |
	*<bcds>os              0sed       |
	*<bclm>us              0sed       |
	*<bcfhlmprtuvw>at      0ted       |
	*<ghjstvw>et           0ted       |
	*<fhlmnptw>it          0ted       |
	*<bcdhjlnprstw>ot      0ted       |
	*<bcghjlmnprt>ut       0ted       |
	*<ei>v                 0ved       |
	*iz                    0zed

<en-trie-regular-b-past> ::=
    *<aeiou>c    0ked  |   /* magicked */
    *<eioy>e     1ed   |   /* dried */
    *<aeiou>y     0ed      /* played, conveyed, convoyed, guyed, preyed */

<en-trie-regular-c-past> ::=
    *e           1ed   |
    *y           1ied  |   /* shied, tried */
    *            0ed

@h Present to past participles.
Sentences like

>> The verb to carry means the carrying relation.

are only one way in which Inform creates new verbs; it also implicitly creates
verbs when actions are declared:

>> Smoothing is an action applying to one thing.

Verbs like this are not stored in anything like the full conjugations above;
the action knows just two forms of its verb, the present and past participles.
This time the base text is the present participle ("smoothing"); the other
inflection we need is the past participle ("smoothed"), and we need a trie
which generates it from the present. This process is called "pasturising",
which is, er, not actually an approved term from linguistics.

English is replete with exceptions -- "catching" must become "caught",
not "catched", for instance -- so this trie consists of about 460 special
cases followed by two general rules.

=
<pasturise-participle> ::=
	<en-trie-pasturise-exceptions> |
	... <en-trie-pasturise-regular-y> |
	... <en-trie-pasturise-regular>

<en-trie-pasturise-exceptions> ::=
	abiding         abided |
	alighting       alighted |
	arising         arisen |
	awaking         awakened |
	backbiting      backbitten |
	backsliding     backslidden |
	bearing         born |
	beating         beaten |
	becoming        become |
	befalling       befallen |
	begeting        begotten |
	begining        begun |
	beholding       beheld |
	bending         bent |
	bereaving       bereaved |
	beseeching      besought |
	besetting       beset |
	bestrewing      bestrewn |
	betting         bet |
	betaking        betaken |
	bethinking      bethought |
	binding         bound |
	biting          bitten |
	bleeding        bled |
	blowing         blown |
	breaking        broken |
	breeding        bred |
	bringing        brought |
	broadcasting    broadcast |
	browbeating     browbeaten |
	building        built |
	burning         burned |
	bursting        burst |
	busting         busted |
	buying          bought |
	casting         cast |
	catching        caught |
	chiding         chided |
	choosing        chosen |
	claping         clapped |
	clinging        clung |
	clothing        clothed |
	coming          come |
	costing         cost |
	creeping        crept |
	crossbreeding   crossbred |
	cutting         cut |
	daring          dared |
	daydreaming     daydreamed |
	dealing         dealt |
	digging         dug |
	dighting        dighted |
	disproving      disproved |
	diving          dived |
	doing           done |
	drawing         drawn |
	dreaming        dreamed |
	drinking        drunk |
	driving         driven |
	dwelling        dwelt |
	eating          eaten |
	enwinding       enwound |
	falling         fallen |
	feeding         fed |
	feeling         felt |
	fighting        fought |
	finding         found |
	fitting         fitted |
	fleeing         fled |
	flinging        flung |
	flying          flown |
	forbearing      forborne |
	forbiding       forbidden |
	fordoing        fordone |
	forecasting     forecast |
	foregoing       foregone |
	foreknowing     foreknown |
	foreruning      forerun |
	foreseeing      foreseen |
	foreshowing     foreshown |
	forespeaking    forespoken |
	foretelling     foretold |
	forgetting      forgotten |
	forgiving       forgiven |
	forsaking       forsaken |
	forswearing     forsworn |
	fraughting      fraught |
	freezing        frozen |
	frostbiting     frostbitten |
	gainsaying      gainsaid |
	getting         got |
	gilding         gilded |
	giving          given |
	going           gone |
	grinding        ground |
	growing         grown |
	halterbreaking  halterbroken |
	hamstringing    hamstrung |
	hand-feeding    hand-fed |
	handwriting     handwritten |
	hanging         hung |
	hearing         heard |
	heaving         heaved |
	hewing          hewn |
	hiding          hidden |
	hitting         hit |
	holding         held |
	hurting         hurt |
	inbreeding      inbred |
	inlaying        inlaid |
	inputing        input |
	insetting       inset |
	interbreeding   interbred |
	intercutting    intercut |
	interlaying     interlaid |
	intersetting    interset |
	interweaving    interwoven |
	interwinding    interwound |
	inweaving       inwoven |
	jerry-building  jerry-built |
	keeping         kept |
	kneeling        knelt |
	knitting        knitted |
	knowing         known |
	lading          laden |
	landsliding     landslid |
	laying          laid |
	leading         led |
	leaning         leaned |
	leaping         leaped |
	learning        learned |
	leaving         left |
	lending         lent |
	letting         let |
	lieing          lain |
	lighting        lit |
	lip-reading     lip-read |
	losing          lost |
	making          made |
	meaning         meant |
	meeting         met |
	misbecoming     misbecome |
	miscasting      miscast |
	miscutting      miscut |
	misdealing      misdealt |
	misdoing        misdone |
	mishearing      misheard |
	mishitting      mishit |
	mislaying       mislaid |
	misleading      misled |
	mislearning     mislearned |
	misreading      misread |
	missaying       missaid |
	missending      missent |
	missetting      misset |
	misspeaking     misspoken |
	misspelling     misspelled |
	misspending     misspent |
	misswearing     missworn |
	mistaking       mistaken |
	misteaching     mistaught |
	mistelling      mistold |
	misthinking     misthought |
	misunderstanding  misunderstood |
	miswearing      misworn |
	misweding       miswed |
	miswriting      miswritten |
	mowing          mowed |
	offsetting      offset |
	outbiding       outbid |
	outbreeding     outbred |
	outdoing        outdone |
	outdrawing      outdrawn |
	outdrinking     outdrunk |
	outdriving      outdriven |
	outfighting     outfought |
	outflying       outflown |
	outgrowing      outgrown |
	outlaying       outlaid |
	outleaping      outleaped |
	outputing       output |
	outriding       outridden |
	outruning       outrun |
	outseeing       outseen |
	outselling      outsold |
	outshining      outshined |
	outshooting     outshot |
	outsinging      outsung |
	outsitting      outsat |
	outsleeping     outslept |
	outsmelling     outsmelled |
	outspeaking     outspoken |
	outspeeding     outsped |
	outspending     outspent |
	outspining      outspun |
	outspringing    outsprung |
	outstanding     outstood |
	outswearing     outsworn |
	outswiming      outswum |
	outtelling      outtold |
	outthinking     outthought |
	outthrowing     outthrown |
	outwearing      outworn |
	outwinding      outwound |
	outwriting      outwritten |
	overbearing     overborne |
	overbiding      overbid |
	overbreeding    overbred |
	overbuilding    overbuilt |
	overbuying      overbought |
	overcasting     overcast |
	overcoming      overcome |
	overcutting     overcut |
	overdoing       overdone |
	overdrawing     overdrawn |
	overdrinking    overdrunk |
	overeating      overeaten |
	overfeeding     overfed |
	overhanging     overhung |
	overhearing     overheard |
	overlaying      overlaid |
	overleaping     overleaped |
	overlieing      overlain |
	overpaying      overpaid |
	overriding      overridden |
	overruning      overrun |
	overseeing      overseen |
	overselling     oversold |
	oversetting     overset |
	oversewing      oversewn |
	overshooting    overshot |
	oversleeping    overslept |
	oversowing      oversown |
	overspeaking    overspoken |
	overspending    overspent |
	overspilling    overspilled |
	overspining     overspun |
	overspreading   overspread |
	overspringing   oversprung |
	overstanding    overstood |
	overstrewing    overstrewn |
	overstriding    overstridden |
	overstriking    overstruck |
	overtaking      overtaken |
	overthinking    overthought |
	overthrowing    overthrown |
	overwearing     overworn |
	overwinding     overwound |
	overwriting     overwritten |
	partaking       partaken |
	paying          paid |
	pleading        pleaded |
	praying         prayed |
	prebuilding     prebuilt |
	predoing        predone |
	premaking       premade |
	prepaying       prepaid |
	preselling      presold |
	presetting      preset |
	preshrinking    preshrunk |
	presplitting    presplit |
	proofreading    proofread |
	proving         proven |
	putting         put |
	quick-freezing  quick-frozen |
	quiting         quit |
	reading         read |
	reawaking       reawaken |
	rebiding        rebid |
	rebinding       rebound |
	rebroadcasting  rebroadcast |
	rebuilding      rebuilt |
	recasting       recast |
	recutting       recut |
	redealing       redealt |
	redoing         redone |
	redrawing       redrawn |
	reeving         reeved |
	refitting       refitted |
	regrinding      reground |
	regrowing       regrown |
	rehanging       rehung |
	rehearing       reheard |
	reknitting      reknitted |
	relearning      relearned |
	relighting      relit |
	remaking        remade |
	rending         rent |
	repaying        repaid |
	rereading       reread |
	reruning        rerun |
	reselling       resold |
	resending       resent |
	resetting       reset |
	resewing        resewn |
	retaking        retaken |
	reteaching      retaught |
	retearing       retorn |
	retelling       retold |
	rethinking      rethought |
	retreading      retread |
	retrofitting    retrofitted |
	rewaking        rewaken |
	rewearing       reworn |
	reweaving       rewoven |
	reweding        rewed |
	reweting        rewet |
	rewining        rewon |
	rewinding       rewound |
	rewriting       rewritten |
	riding          rid |
	riding          ridden |
	ringing         rung |
	rising          risen |
	riving          riven |
	roughcasting    roughcast |
	running         run |
	sand-casting    sand-cast |
	sawing          sawed |
	saying          said |
	seeing          seen |
	seeking         sought |
	self-feeding    self-fed |
	self-sowing     self-sown |
	selling         sold |
	sending         sent |
	setting         set |
	sewing          sewn |
	shaking         shaken |
	shaving         shaved |
	shearing        sheared |
	sheding         shed |
	shining         shined |
	shoeing         shoed |
	shooting        shot |
	showing         shown |
	shrinking       shrunk |
	shriving        shriven |
	shutting        shut |
	sight-reading   sight-read |
	singing         sung |
	sinking         sunk |
	siting          sat |
	skywriting      skywritten |
	sleeping        slept |
	sliding         slid |
	slinging        slung |
	slinking        slinked |
	slitting        slit |
	smelling        smelled |
	smiting         smitten |
	sneaking        sneaked |
	sowing          sown |
	speaking        spoken |
	speeding        sped |
	spelling        spelled |
	spending        spent |
	spilling        spilled |
	spinning        spun |
	spitting        spit |
	splitting       split |
	spoiling        spoiled |
	spoon-feeding   spoon-fed |
	spreading       spread |
	springing       sprung |
	stall-feeding   stall-fed |
	standing        stood |
	staving         staved |
	stealing        stolen |
	sticking        stuck |
	stinging        stung |
	stinking        stunk |
	strewing        strewn |
	striding        stridden |
	striking        struck |
	stringing       strung |
	striping        stripped |
	striving        striven |
	subletting      sublet |
	sunburning      sunburned |
	swearing        sworn |
	sweating        sweat |
	sweeping        swept |
	swelling        swollen |
	swiming         swum |
	swinging        swung |
	taking          taken |
	teaching        taught |
	tearing         torn |
	telecasting     telecast |
	telling         told |
	test-driving    test-driven |
	test-flying     test-flown |
	thinking        thought |
	thriving        thrived |
	throwing        thrown |
	thrusting       thrust |
	treading        trodden |
	troubleshooting troubleshot |
	typecasting     typecast |
	typesetting     typeset |
	typewriting     typewritten |
	unbearing       unborn |
	unbending       unbent |
	unbinding       unbound |
	unbuilding      unbuilt |
	underbiding     underbid |
	underbuying     underbought |
	undercutting    undercut |
	underfeeding    underfed |
	undergoing      undergone |
	underlaying     underlaid |
	underletting    underlet |
	underlieing     underlain |
	underruning     underrun |
	underselling    undersold |
	undershooting   undershot |
	underspending   underspent |
	understanding   understood |
	undertaking     undertaken |
	underthrusting  underthrust |
	underwriting    underwritten |
	undoing         undone |
	undrawing       undrawn |
	unfreezing      unfrozen |
	unhanging       unhung |
	unhiding        unhidden |
	unholding       unheld |
	unknitting      unknitted |
	unlading        unladen |
	unlaying        unlaid |
	unlearning      unlearned |
	unmaking        unmade |
	unreeving       unreeved |
	unsaying        unsaid |
	unsewing        unsewn |
	unslinging      unslung |
	unspining       unspun |
	unsticking      unstuck |
	unstringing     unstrung |
	unswearing      unsworn |
	unteaching      untaught |
	unthinking      unthought |
	unweaving       unwoven |
	unwinding       unwound |
	unwriting       unwritten |
	upholding       upheld |
	upsetting       upset |
	vexing          vexed |
	waking          woken |
	waylaying       waylaid |
	wearing         worn |
	weaving         woven |
	weding          wed |
	weeping         wept |
	wetting         wet |
	wining          won |
	winding         wound |
	withdrawing     withdrawn |
	withholding     withheld |
	withstanding    withstood |
	wringing        wrung |
	writing         written

<en-trie-pasturise-regular-y> ::=
	*aying          3ed    |        /* e.g., "slaying" to "slayed" */
	*eying          3ed    |        /* e.g., "preying" to "preyed" */
	*oying          3ed    |        /* e.g., "toying" to "toyed" */
	*ying           4ied         /* e.g., "verifying" to "verified" */

<en-trie-pasturise-regular> ::=
	*ing            3ed         /* e.g., "smashing" to "smashed" */

@h Adjective agreements.
English doesn't inflect adjectives at all (let's not argue about "blond"
and "blonde"), so the following are just stubs.

=
<adjective-to-plural> ::=
	*                0

<adjective-to-masculine-singular> ::=
	*                0

<adjective-to-feminine-singular> ::=
	*                0

<adjective-to-masculine-plural> ::=
	*                0

<adjective-to-feminine-plural> ::=
	*                0

@ Grading of adjectives is more interesting. These spelling rules are taken
from the Oxford English Grammar at 4.24, "Gradability and comparison".
Something we can't easily implement is that a final vowel plus consonant
doesn't result in doubling the consonant (in the way that "big" becomes
"bigger") if that closing syllable is unstressed, but fortunately this is
rare in English adjectives.

=
<adjective-to-comparative> ::=
	good                                  better |
	well                                  better |
	bad                                   worse |
	far                                   farther |
	*e                                    1er |     /* e.g. "close" to "closer" */
	*<bcdfghkmlnprstvwxyz>y               1ier |    /* e.g. "ugly" to "uglier" */
	*<aeiou><aeiou><bcdfghkmlnprstvxyz>   0er |     /* e.g. "cheap" to "cheaper" not "cheapper" */
	*<aeiou><bcdfghkmlnprstvxyz>          0+er |    /* e.g. "fit" to "fitter" */
	*                                     0er

<adjective-to-superlative> ::=
	good                                  best |
	well                                  best |
	bad                                   worst |
	far                                   farthest |
	*e                                    1est |
	*<bcdfghkmlnprstvwxyz>y               1iest |
	*<aeiou><aeiou><bcdfghkmlnprstvxyz>   0est |
	*<aeiou><bcdfghkmlnprstvxyz>          0+est |
	*                                     0est

@ To the best of my knowledge there's no technical term for "the noun which
is formed from an adjective to refer to the quality it measures", so the
Inform source code calls this the "quiddity". English permits several
competing forms of these to be constructed, depending on the adjective's
spelling (for example, "brutal" can become "brutality", but "small" can't
become "smallity"), but in general, except for Anglo-Saxon cases, the "-ness"
suffix seems universally possible. For simplicity we'll use that; note the
OEG's warning at 9.21 that this avoids problems where these forms, though
notionally equivalent, have diverged in meaning: e.g., "casualty" should
mean the same as "casualness", but no longer does. The "-ness" form is
sometimes less elegant, but never means the wrong thing.

=
<adjective-to-quiddity> ::=
	*ong                            3ength |    /* e.g. "strong" to "strength" */
	*<bcdfghkmlnprstvwxyz>y         1iness |    /* e.g. "happy" to "happiness" */
	*                               0ness

@ English has almost no noun cases at all, with the only exceptions being
Anglo-Saxon pronouns (thus we distinguish "they" and "them" as nominative
and accusative, for example); and pronouns we handle separately in any
case. We won't bother to distinguish gender:

=
<grammatical-case-names> ::=
	nominative | accusative

<noun-declension> ::=
	*    <en-noun-declension-group> <en-noun-declension-tables>

@ And the sorting into groups sorts everything into "group 1", the only group:

=
<en-noun-declension-group> ::=
	*            1

<en-noun-declension-tables> ::=
	<en-noun-declension-uninflected>

@ And in this single group, nominative and accusative forms are identical
to the stem in both singular and plural.

=
<en-noun-declension-uninflected> ::=
	0 | 0 |
	0 | 0

@ English articles only inflect slightly, to show indefinite plurals; they
don't distinguish nominative from accusative.

=
<article-declension> ::=
	*           <en-article-declension>

<en-article-declension> ::=
	a           a    a
	            some some |
	the         the  the
	            the  the
