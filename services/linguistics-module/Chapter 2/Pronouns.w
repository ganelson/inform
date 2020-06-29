[Pronouns::] Pronouns.

Preform grammar for the pronouns.

@h Pronouns.
Note also that there is no //noun// object representing "pronoun".

=
<pronoun> ::=
	<nominative-pronoun> |      ==> R[1]
	<accusative-pronoun>        ==> R[1]

<nominative-pronoun> ::=
	it/he/she |                 ==> 1 /* singular */
	they                        ==> 2 /* plural */

<accusative-pronoun> ::=
	it/him/her |                ==> 1 /* singular */
	them                        ==> 2 /* plural */

@ Inform uses these not only for parsing but also to inflect text. For example,
if every person is given a nose, the player will see it as "my nose" not
"your nose". Inform handles such inflections by converting a pronoun in
one grammar into its corresponding pronoun in another (in this case, first
person to second person).

=
<possessive-first-person> ::=
	my |                        ==> 1 /* singular */
	our                         ==> 2 /* plural */

<possessive-second-person> ::=
	your |                      ==> 1 /* singular */
	your                        ==> 2 /* plural */

<possessive-third-person> ::=
	its/his/her |               ==> 1 /* singular */
	their                       ==> 2 /* plural */
