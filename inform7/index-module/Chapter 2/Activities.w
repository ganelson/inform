[IXActivities::] Activities.

To index activities.

@ 

=
typedef struct activity_indexing_data {
	int activity_indexed; /* has this been indexed yet? */
	struct wording av_documentation_symbol; /* cross-reference to HTML documentation, if any */
	struct activity_crossref *cross_references;
} activity_indexing_data;

typedef struct activity_crossref {
	struct id_body *rule_dependent;
	struct activity_crossref *next;
} activity_crossref;

@ =
activity_indexing_data IXActivities::new_indexing_data(activity *av, wording doc) {
	activity_indexing_data aid;
	aid.activity_indexed = FALSE;
	aid.av_documentation_symbol = doc;
	aid.cross_references = NULL;
	return aid;
}

void IXActivities::annotate_list_for_cross_references(activity_list *avl, id_body *idb) {
	for (; avl; avl = avl->next)
		if (avl->activity) {
			activity *av = avl->activity;
			activity_crossref *acr = CREATE(activity_crossref);
			acr->next = av->indexing_data.cross_references;
			av->indexing_data.cross_references = acr;
			acr->rule_dependent = idb;
		}
}
