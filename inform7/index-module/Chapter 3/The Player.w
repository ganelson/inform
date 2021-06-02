[IXPlayer::] The Player.

Indexing the player's initial position.

@ We explicitly mention the player in the World index, since otherwise it won't
usually appear anywhere.

=
void IXPlayer::index_object_further(OUTPUT_STREAM, instance *I, int depth, int details) {
	if ((I == start_room) && (I_yourself) &&
		(IXInstances::indexed_yet(I_yourself) == FALSE))
		IXPhysicalWorld::index(OUT, I_yourself, NULL, depth+1, details);
}

int IXPlayer::annotate_in_World_index(OUTPUT_STREAM, instance *I) {
	if (I == Player::get_start_room()) {
		WRITE(" - <i>room where play begins</i>");
		Index::DocReferences::link(OUT, I"ROOMPLAYBEGINS");
		return TRUE;
	}
	return FALSE;
}
