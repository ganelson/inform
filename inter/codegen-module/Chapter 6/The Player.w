[IXPlayer::] The Player.

Indexing the player's initial position.

@ We explicitly mention the player in the World index, since otherwise it won't
usually appear anywhere.

=
void IXPlayer::index_object_further(OUTPUT_STREAM, faux_instance *I, int depth, int details) {
	faux_instance *yourself = IXInstances::yourself();
	if ((I == IXInstances::start_room()) && (yourself) &&
		(IXInstances::indexed_yet(yourself) == FALSE))
		IXPhysicalWorld::index(OUT, yourself, depth+1, details);
}

int IXPlayer::annotate_in_World_index(OUTPUT_STREAM, faux_instance *I) {
	if (I == IXInstances::start_room()) {
		WRITE(" - <i>room where play begins</i>");
		Index::DocReferences::link(OUT, I"ROOMPLAYBEGINS");
		return TRUE;
	}
	return FALSE;
}
