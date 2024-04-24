[Wiring::] The Wiring.

Wiring symbols in one package to meanings in another, and via plugs and sockets
even to packages in trees not yet loaded in.

@h Wiring to symbols.
"Wiring" is used to allow symbols in one package to refer to meanings defined
in another. Since meanings are defined by symbols, this is done by allowing a
symbol in one package to connect to a symbol in the other.

For example, suppose the variable |draconia| is defined in package |Y|, but
needs to be referred to in |X|. Then |X| will also contain a symbol |draconia|,
but rather than being defined there, it is wired to the one in |Y|:
= (text)
    +-----------------+        +-------------------------------+
    | Package X       |        | Package Y                     |
    |                 |        |                               |
    | draconia ~~~~~~~~~~~~+~~~~~> draconia                    |
    +-----------------+   /    | .....                         |
                          |    | variable K_int32 draconia = 3 |
                          |    +-------------------------------+
    +-----------------+   |
    | Package W       |   |
	|                 |   |
    | draconia ~~~~~~~~~~~/
    +-----------------+
=
We write |A ~~> B| as a picturesque notation; the wiring is supposed to look
coiled, or something like that. As this diagram shows, it can happen that more
than one symbol is wired to the same destination; but each individual symbol
can wire to at most one other.

=
typedef struct wiring_data {
	struct inter_symbol *connects_to;
	struct text_stream *wants_to_connect_to;
	int incoming_wire_count;
} wiring_data;

wiring_data Wiring::new_wiring_data(inter_symbol *S) {
	wiring_data wd;
	wd.connects_to = NULL;
	wd.wants_to_connect_to = NULL;
	wd.incoming_wire_count = 0;
	return wd;
}

@ If |A ~~> B| then |A| is said to be "wired", and |B| is what it is wired to.

=
int Wiring::is_wired(inter_symbol *S) {
	if (Wiring::wired_to(S)) return TRUE;
	return FALSE;
}

inter_symbol *Wiring::wired_to(inter_symbol *S) {
	if (S) return S->wiring.connects_to;
	return NULL;
}

@ This metaphor only goes so far: wiring is directional -- if A is wired to B then
B is not by virtue of that wired to A; and indeed, circuits are forbidden.

Nevertheless it does happen that we have a sequence of symbols each wired to
the next: |A ~~> B ~~> C ~~> ... ~~> X|. Following such cables, we must always
reach an end. On all these symbols, //Wiring::cable_end// returns |X|.

=
inter_symbol *Wiring::cable_end(inter_symbol *S) {
	while ((S) && (S->wiring.connects_to)) S = S->wiring.connects_to;
	return S;
}

@ In general, we have no means of following wiring backwards: that is, given
|B|, we cannot easily find all the |A| such that |A ~~> B|. What we can do is
to say how many such |A| exist, and it's useful to know when this count is 0,
because then we may be able safely to delete |B| as no longer needed.

=
int Wiring::has_no_incoming_connections(inter_symbol *S) {
	if ((S) && (S->wiring.incoming_wire_count == 0)) return TRUE;
	return FALSE;
}

@ Wiring must be performed with this function, or the incoming wire count may
be broken.

Metadata constants cannot be wired (or wired to), because they by definition
describe content in the current package. They are self-contained, and the meaning
of the program must not be changed by their removal.

Note that |S| may be unwired by calling |Wiring::wire_to(S, NULL)|.

=
void Wiring::wire_to(inter_symbol *S, inter_symbol *T) {
	if (S == NULL) internal_error("null symbol cannot be wired");
	if ((InterSymbol::is_metadata_key(S)) || ((T) && (InterSymbol::is_metadata_key(T))))
		internal_error("metadata keys cannot be wired");

	/* if S ~~> T already, return now, and do not increment the count for T */
	if (S->wiring.connects_to == T) return;

	/* if S ~~> U for some other U, decrement the count for U */
	if (S->wiring.connects_to) S->wiring.connects_to->wiring.incoming_wire_count--;

	/* make S ~~> T, and increment the count for T */
	S->wiring.connects_to = T;
	S->wiring.wants_to_connect_to = NULL;
	if (T) T->wiring.incoming_wire_count++;

	LOGIF(INTER_SYMBOLS, "Wired $3 to $3\n", S, T);
	@<Throw an internal error if a circuit was made@>;
	int c = 0;
	for (inter_symbol *W = S; W; W = W->wiring.connects_to, c++)
		if (c == 100) {
			c = 0;
			for (inter_symbol *W = S; ((W) && (c < 20)); W = W->wiring.connects_to, c++)
				LOG("%d. %S\n", c, InterSymbol::identifier(W));
			LOG("...");
			internal_error("probably made a circuit in wiring");
		}
}

@ In normal use, wiring never exceeds a cable length of about 4, so 1000 is
plenty here.

@<Throw an internal error if a circuit was made@> =
	int c = 0;
	for (inter_symbol *W = S; W; W = W->wiring.connects_to, c++)
		if (c == 1000) {
			WRITE_TO(STDERR, "Wiring caused circuit:\n");
			c = 0;
			for (inter_symbol *W = S; ((W) && (c < 20)); W = W->wiring.connects_to, c++)
				WRITE_TO(STDERR, "%d. %S\n", c, InterSymbol::identifier(W));
			WRITE_TO(STDERR, "...");
			internal_error("made a circuit in wiring");
		}

@ If we do have a cable |A ~~> B ~~> ... ~~> X|, we can "shorten" this from |A|
by making |A ~~> X| directly. It will still be the case that |B ~~> ... ~~> X|,
of course. Assuming |B| is not |X|, the incoming count for |B| will decrement
and that for |X| increment.

=
void Wiring::shorten_wiring(inter_symbol *S) {
	inter_symbol *E = Wiring::cable_end(S);
	if ((S != E) && (Wiring::wired_to(S) != E)) Wiring::wire_to(S, E);
}

@h Wiring to names.
It is also possible to say that a symbol has a meaning whose location is not
yet known -- we can't have |A ~~> B| because we don't know where |B| is, and
maybe it does not even exist yet. All we know is that it will have a given
name, |T|. In this case, we write |A ~~> "ogron"| to say that |A| should one
day be wired to a |B| called |"ogron"|.

This is used mainly for plugs (see below), but also as a convenience when
reading Inter files in text format, since it enables forward references to be
made.

=
void Wiring::wire_to_name(inter_symbol *S, text_stream *T) {
	if (S == NULL) internal_error("null symbol cannot be wired");
	if (InterSymbol::is_metadata_key(S)) internal_error("metadata keys cannot be wired");
	if (Str::len(T) == 0) internal_error("symbols cannot be wired to the empty name");
	Wiring::wire_to(S, NULL);
	S->wiring.wants_to_connect_to = Str::duplicate(T);
}

int Wiring::is_wired_to_name(inter_symbol *S) {
	if ((S) && (Str::len(S->wiring.wants_to_connect_to) > 0)) return TRUE;
	return FALSE;
}

text_stream *Wiring::wired_to_name(inter_symbol *S) {
	if (S) return S->wiring.wants_to_connect_to;
	return NULL;
}

@h Plugs and sockets.
Now suppose a symbol in package |X| wants to refer to a meaning which
does not yet exist, and will in fact never exist in the current tree. (It will
be linked in from another tree later on.) For example, perhaps Inform 7 is
compiling a function body which needs to refer to |CreatePV|, a function
in BasicInformKit.

This is done by having |CreatePV| in |X| wire to a special symbol called
a "plug" in a special package of the tree at |/main/connectors|.
(See //building: Large-Scale Structure// for more on this package.) That plug
is left dangling, in the sense that it is wired to the name |"CreatePV"|,
but that this name is unresolved.
= (text)
	MAIN TREE
    +-----------------+      +--------------------------+
    | Package X       |      | Package /main/connectors |
    |                 |      |                          |
    | CreatePV ~~~~~~~~~~~~~~~> _plug_BlkValueCreate ~~~~~~~> "CreatePV"
    +-----------------+      +--------------------------+
=

Meanwhile, suppose a second tree holds //BasicInformKit//. This looks like so:
= (text)
	BASICINFORMKIT TREE
    +-------------------+      +--------------------------+
    | Package Y         |      | Package /main/connectors |
    |                   |      |                          |   
    | CreatePV <~~~~~~~~~~~~~~~~ CreatePV <~~~~~~~~~~~~~~~~~~ "CreatePV"
    | .....             |      +--------------------------+
    | function defn     |
    | of CreatePV       |
    | function defn     |
    | of SecretFunction |
    +-------------------+
=
Package |Y| in this tree holds two function definitions, let's say: |CreatePV|
and |SecretFunction|. The latter is private to BasicInformKit, in that the linking
process in //pipeline// does not allow symbols in other trees to be wired to it.
But |CreatePV| is available. That is because the BasicInformKit provides
a "socket" to it.

Sockets, like plugs, live only in the |/main/connectors| package of a tree.
A typical tree will have both plugs and sockets; note that no plug will ever
have the same symbol name as any socket, because all plug names begin |_plug_...|
and no socket names do.

@ The point of this is that after //Transmigration// there will be a single
tree like so, which has merged the connectors from the two original trees,
and which now contains both |X| and |Y|. We can npw connect the plug
|_plug_BlkValueCreate| with the socket |CreatePV|:
= (text)
.. MERGED TREE ................................................
.  +-----------------+      +--------------------------+      .
.  | Package X       |      | Package /main/connectors |      .
.  |                 |      |                          |      .
.  | CreatePV ~~~~~~~~~~~~~~> _plug_BlkValueCreate ~~~~~~~\   .
.  +-----------------+      |                          |   \  .
.                           |                          |    | .
.  +-----------------+      |                          |    | .
.  | Package Y       |      |                          |    | .
.  |                 |      |                          |   /  .
.  | CreatePV <~~~~~~~~~~~~~~~ CreatePV <~~~~~~~~~~~~~~~~~/   .
.  | .....           |      +--------------------------+      .
.  | function defn   |                                        .
.  +-----------------+                                        .
...............................................................                                                         
=
The cable end from |CreatePV| in |X| is indeed the definition in |Y|,
and all is well.

Some sockets may never be used -- that would be a situation where one tree
offers a meaning as being available to other trees, but where nobody takes
up the offer. The only essential thing is that all plugs must find a socket.

@ Note the following consequences of this design:

(*) Every socket is always wired.
(*) Every plug is either wired to a socket, or to a name, in the hope that
it will one day be wired to a socket of that name.
(*) All uses of, say, |CreatePV| in the main tree are wired to a single
plug in its |/main/connectors| package.
(*) By looking at the incoming count of a plug or socket, we can see if it is
still needed -- if the count falls to 0, it is not.
(*) Connecting plugs to sockets is relatively fast, because only one package's
symbols table needs to be searched -- |/main/connectors|.
(*) Each tree can offer any number of meanings to other trees, but they are
identified by name only. If two packages in a tree both define functions called
|hulke|, then they cannot both be "exported" in this way, because the connectors
package can only contain one socket with the name |hulke|.
(*) But the flip side of that is that a tree wanting a meaning in some other
tree does not need to know the Inter hierarchy structure of that other tree,
or even its identity. This is a little like linking functions in C: a file
of object code can refer to |mystery_distant_function()| without any idea of
where that will come from.

@ To start with something simple: finding if a tree has a socket with a given
identifier name.

=
inter_symbol *Wiring::find_socket(inter_tree *I, text_stream *name) {
	inter_package *connectors = LargeScale::connectors_package_if_it_exists(I);
	inter_symbols_table *CT = InterPackage::scope(connectors);
	if (connectors) {
		inter_symbol *S = InterSymbolsTable::symbol_from_name_not_following(CT, name);
		if (InterSymbol::is_socket(S)) return S;
	}
	return NULL;
}

@ Now suppose our tree defines a meaning with a symbol |defn|, and we want to
offer that for the potential use of other trees. We call this function to create
a socket for it: the return value is a socket |S| for which |S ~~> defn|.

It is legal to call this more than once on the same |defn| and the same |name|,
in which case the second time does nothing, but it is an error to inconsistently
claim that |name| means two different symbols.

Note that during //Transmigration// there is a brief period when a socket in
one tree is wired to a socket in another; this is the only time a socket can
be wired to another connector.

=
inter_symbol *Wiring::socket(inter_tree *I, text_stream *name, inter_symbol *defn) {
	return Wiring::socket_inner(I, name, defn, FALSE);
}
inter_symbol *Wiring::socket_one_per_name_only(inter_tree *I, text_stream *name,
	inter_symbol *defn) {
	return Wiring::socket_inner(I, name, defn, TRUE);
}
inter_symbol *Wiring::socket_inner(inter_tree *I, text_stream *name, inter_symbol *defn,
	int allow_multiple_sockets_with_the_same_name) {
	if (defn == NULL) internal_error("tried to make socket for nothing");
	if (InterSymbol::is_socket(defn)) {
		if (I == InterPackage::tree(InterSymbol::package(defn))) {
			WRITE_TO(STDERR, "Socket '%S' ~~> socket ", name);
			InterSymbolsTable::write_symbol_URL(STDERR, defn);
			WRITE_TO(STDERR, " ~~> ");
			InterSymbolsTable::write_symbol_URL(STDERR, Wiring::cable_end(defn));
			WRITE_TO(STDERR, "\n");
			internal_error("tried to make socket for another socket in the same tree");
		}
	} else if (Wiring::is_wired(defn)) {
		WRITE_TO(STDERR, "Socket %S ~~> ", name);
		InterSymbolsTable::write_symbol_URL(STDERR, defn);
		WRITE_TO(STDERR, " ~~> ");
		InterSymbolsTable::write_symbol_URL(STDERR, Wiring::cable_end(defn));
		WRITE_TO(STDERR, "\n");
		internal_error("tried to make socket for wired symbol");
	}
	inter_package *connectors = LargeScale::ensure_connectors_package(I);
	inter_symbols_table *CT = InterPackage::scope(connectors);
	inter_symbol *socket = InterSymbolsTable::symbol_from_name_not_following(CT, name);
	if (socket) {
		if (InterSymbol::is_socket(socket) == FALSE)
			internal_error("tried to make socket with same name as a plug");
		if ((allow_multiple_sockets_with_the_same_name == FALSE) &&
			(Wiring::wired_to(socket) != defn)) {
			WRITE_TO(STDERR, "Socket %S has two defns\n", name);
			InterSymbolsTable::write_symbol_URL(STDERR, Wiring::wired_to(socket));
			WRITE_TO(STDERR, "\n");
			InterSymbolsTable::write_symbol_URL(STDERR, defn);
			WRITE_TO(STDERR, "\n");
			internal_error("tried to make inconsistent socket");
		}
	} else {
		socket = InterSymbolsTable::create_with_unique_name(CT, name);
		Wiring::make_socket_to(socket, defn);
		LOGIF(INTER_CONNECTORS, "Socket $3 ~~> $3\n", socket, defn);
	}
	return socket;
}

@ Which uses this function, to change an existing symbol into a socket. It
should only be used immediately after the symbol has been created.

=
void Wiring::make_socket_to(inter_symbol *S, inter_symbol *defn) {
	Wiring::wire_to(S, defn);
	InterSymbol::make_socket(S);
}

@ And similarly for plugs:

=
inter_symbol *Wiring::plug(inter_tree *I, text_stream *wanted) {
	inter_package *connectors = LargeScale::ensure_connectors_package(I);
	inter_symbols_table *CT = InterPackage::scope(connectors);
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "_plug_%S", wanted);
	inter_symbol *plug = InterSymbolsTable::symbol_from_name_not_following(CT, name);
	if (plug) {
		if (InterSymbol::is_plug(plug) == FALSE)
			internal_error("tried to make plug with same name as a socket");
	} else {
		plug = InterSymbolsTable::create_with_unique_name(CT, name);
		Wiring::make_plug_wanting_identifier(plug, wanted);
		LOGIF(INTER_CONNECTORS, "Plug $3 ~~> \"%S\"\n",
			plug, Wiring::name_sought_by_loose_plug(plug));
	}
	DISCARD_TEXT(name)
	return plug;
}

void Wiring::make_plug_wanting_identifier(inter_symbol *S, text_stream *wanted) {
	Wiring::wire_to_name(S, wanted);
	InterSymbol::make_plug(S);
}

@ An unwired plug -- i.e., wired to a name but not to an actual symbol -- is
said to be "loose".

=
int Wiring::is_loose_plug(inter_symbol *S) {
	if ((InterSymbol::is_plug(S)) && (Wiring::is_wired(S) == FALSE)) return TRUE;
	return FALSE;
}

text_stream *Wiring::name_sought_by_loose_plug(inter_symbol *S) {
	if (Wiring::is_loose_plug(S)) return Wiring::wired_to_name(S);
	return NULL;
}

@ And here at last is the connection:

=
void Wiring::connect_plugs_to_sockets(inter_tree *I) {
 	inter_package *connectors = LargeScale::connectors_package_if_it_exists(I);
 	if (connectors) {
 		inter_symbols_table *ST = InterPackage::scope(connectors);
 		LOOP_OVER_SYMBOLS_TABLE(S, ST) {
			if (Wiring::is_loose_plug(S)) {
				text_stream *name = Wiring::name_sought_by_loose_plug(S);
				inter_symbol *socket = Wiring::find_socket(I, name);
				if (socket) Wiring::wire_plug(S, socket);
				else {
					int last_tick = -1;
					for (int i=0; i<Str::len(name); i++)
						if (Str::get_at(name, i) == '`') {
							last_tick = i;
						}
					if (last_tick >= 0) {
						if ((Str::prefix_eq(name, I"implied`", 8)) ||
							(Str::prefix_eq(name, I"main`", 5))) {
							TEMPORARY_TEXT(N)
							TEMPORARY_TEXT(NS)
							for (int i=8; i<last_tick; i++)
								PUT_TO(NS, Str::get_at(name, i));
							if (Str::eq(NS, I"main")) Str::clear(NS);
							for (int i=last_tick+1; i<Str::len(name); i++)
								PUT_TO(N, Str::get_at(name, i));
							socket = Wiring::find_socket(I, N);
							if (socket) {
								LOGIF(INTER_CONNECTORS, "Wire implied plug '%S' to socket with global name: $3\n", 
									name, S);
								Wiring::wire_plug(S, socket);
							}
							DISCARD_TEXT(N)
							DISCARD_TEXT(NS)
						}
					}
				}
			}
		}
	}
}

void Wiring::wire_plug(inter_symbol *plug, inter_symbol *to) {
	if (plug == NULL) internal_error("no plug");
	if (InterSymbol::is_socket(to) == FALSE) internal_error("not a socket");
	LOGIF(INTER_CONNECTORS, "Plug $3 ~~> socket $3\n", plug, to);
	Wiring::wire_to(plug, to);
}

@ For debugging:

=
void Wiring::log_connectors(inter_tree *I) {
	LOG("Connectors in tree %d:\n", I->allocation_id);
	LOG_INDENT;
	inter_package *connectors = LargeScale::connectors_package_if_it_exists(I);
	if (connectors) {
		inter_symbols_table *T = InterPackage::scope(connectors);
		if (T == NULL) internal_error("package with no symbols");
		LOOP_OVER_SYMBOLS_TABLE(S, T) {
			if (InterSymbol::is_socket(S)) {
				LOG("Socket (%dx ~~>) $3 ~~> $3\n", S->wiring.incoming_wire_count,
					S, Wiring::wired_to(S));
			} else if (InterSymbol::is_plug(S)) {
				if (Wiring::is_wired(S)) {
					LOG("Wired plug (%dx ~~>) $3 ~~> $3\n",
						S->wiring.incoming_wire_count, S, Wiring::wired_to(S));
				} else {
					LOG("Loose plug (%dx ~~>) $3 ~~> \"%S\"\n",
						S->wiring.incoming_wire_count, S,
						Wiring::name_sought_by_loose_plug(S));
				}
			} else {
				LOG("Anomalous $3\n", S);
			}
		}
	}
	LOG_OUTDENT;
}
