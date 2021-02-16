[RelationInferences::] Relation Inferences.

Inferences that a relation holds between two subjects or values.

@ We will make:

= (early code)
inference_family *arbitrary_relation_inf = NULL;

@

=
void RelationInferences::start(void) {
	arbitrary_relation_inf = Inferences::new_family(I"arbitrary_relation_inf", CI_DIFFER_IN_COPY_ONLY);
}
