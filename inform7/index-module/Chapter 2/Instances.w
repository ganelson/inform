[IXInstances::] Instances.

To index instances.

@ Each instance includes the following additional data:

=
typedef struct instance_index_data {
	int index_appearances; /* how many times have I appeared thus far in the World index? */
} instance_index_data;

@ =
void IXInstances::initialise_iid(instance *I) {
	I->iid.index_appearances = 0;
}

@h Noun usage.
This simply avoids repetitions in the World index:

=
void IXInstances::increment_indexing_count(instance *I) {
	I->iid.index_appearances++;
}

int IXInstances::indexed_yet(instance *I) {
	if (I->iid.index_appearances > 0) return TRUE;
	return FALSE;
}
