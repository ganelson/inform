[I6TargetObjects::] Inform 6 Objects.

To declare I6 objects, classes, attributes and properties.

@ =
void I6TargetObjects::create_generator(code_generator *cgt) {
	METHOD_ADD(cgt, DECLARE_PROPERTY_MTID, I6TargetObjects::declare_property);
	METHOD_ADD(cgt, DECLARE_CLASS_MTID, I6TargetObjects::declare_class);
	METHOD_ADD(cgt, END_CLASS_MTID, I6TargetObjects::end_class);
	METHOD_ADD(cgt, DECLARE_VALUE_INSTANCE_MTID, I6TargetObjects::declare_value_instance);
	METHOD_ADD(cgt, DECLARE_INSTANCE_MTID, I6TargetObjects::declare_instance);
	METHOD_ADD(cgt, END_INSTANCE_MTID, I6TargetObjects::end_instance);
	METHOD_ADD(cgt, OPTIMISE_PROPERTY_MTID, I6TargetObjects::optimise_property_value);
	METHOD_ADD(cgt, ASSIGN_PROPERTY_MTID, I6TargetObjects::assign_property);
	METHOD_ADD(cgt, BEGIN_PROPERTIES_FOR_MTID, I6TargetObjects::begin_properties_for);
	METHOD_ADD(cgt, END_PROPERTIES_FOR_MTID, I6TargetObjects::end_properties_for);
	METHOD_ADD(cgt, ASSIGN_PROPERTIES_MTID, I6TargetObjects::assign_properties);
	METHOD_ADD(cgt, PSEUDO_OBJECT_MTID, I6TargetObjects::pseudo_object);
}

@ Because in I6 source code some properties aren't declared before use, it follows
that if not used by any object then they won't ever be created. This is a
problem since it means that I6 code can't refer to them, because it would need
to mention an I6 symbol which doesn't exist. To get around this, we create the
property names which don't exist as constant symbols with the harmless value
0; we do this right at the end of the compiled I6 code. (This is a standard I6
trick called "stubbing", these being "stub definitions".)

=
void I6TargetObjects::declare_property(code_generator *cgt, code_generation *gen, inter_symbol *prop_name, linked_list *all_forms) {
	inter_tree *I = gen->from;
	text_stream *inner_name = VanillaObjects::inner_property_name(gen, prop_name);

	int explicitly_defined_in_kit = FALSE;
	inter_symbol *p;
	LOOP_OVER_LINKED_LIST(p, inter_symbol, all_forms)
		if (Inter::Symbols::read_annotation(p, ASSIMILATED_IANN) >= 0)
			explicitly_defined_in_kit = TRUE;

	int make_attribute = NOT_APPLICABLE;
	if (Inter::Symbols::read_annotation(prop_name, EITHER_OR_IANN) == 1)
		@<Consider this property for attribute allocation@>;

	int t = 1, def = FALSE;

	if (make_attribute == TRUE) {
		inter_symbol *p;
		LOOP_OVER_LINKED_LIST(p, inter_symbol, all_forms)
			Inter::Symbols::set_flag(p, ATTRIBUTE_MARK_BIT);

		segmentation_pos saved = CodeGen::select(gen, constants_I7CGS);
		WRITE_TO(CodeGen::current(gen), "Attribute %S;\n", inner_name);
		CodeGen::deselect(gen, saved);
		t = 2;
		def = TRUE;
	} else {
		inter_symbol *p;
		LOOP_OVER_LINKED_LIST(p, inter_symbol, all_forms)
			Inter::Symbols::clear_flag(p, ATTRIBUTE_MARK_BIT);

		if (explicitly_defined_in_kit) {
			segmentation_pos saved = CodeGen::select(gen, predeclarations_I7CGS);
			WRITE_TO(CodeGen::current(gen), "Property %S;\n", inner_name);
			CodeGen::deselect(gen, saved);
			def = TRUE;
		} 
	}
	
	I6_GEN_DATA(subterfuge_count)++;
	segmentation_pos saved = CodeGen::select(gen, constants_I7CGS);
	WRITE_TO(CodeGen::current(gen), "Constant subterfuge_%d = %S;\n",
		I6_GEN_DATA(subterfuge_count), inner_name);
	CodeGen::deselect(gen, saved);

	TEMPORARY_TEXT(val)
	WRITE_TO(val, "%d", t);
	Generators::array_entry(gen, val, WORD_ARRAY_FORMAT);
	Str::clear(val);
	WRITE_TO(val, "subterfuge_%d", I6_GEN_DATA(subterfuge_count));
	Generators::array_entry(gen, val, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(val)

	if (def == FALSE) {
		saved = CodeGen::select(gen, property_stubs_I7CGS);
		WRITE_TO(CodeGen::current(gen), "#ifndef %S; Constant %S = 0; #endif;\n", inner_name, inner_name);
		CodeGen::deselect(gen, saved);
	}
}

@<Consider this property for attribute allocation@> =
	@<Any either/or property which can belong to a value instance is ineligible@>;
	@<An either/or property translated to an attribute declared in the I6 template must be chosen@>;
	@<Otherwise give away attribute slots on a first-come-first-served basis@>;

@ The dodge of using an attribute to store an either-or property won't work
for properties of value instances, because then the value-property-holder
object couldn't store the necessary table address (see next section). So we
must rule out any property which might belong to any value.

@<Any either/or property which can belong to a value instance is ineligible@> =
	inter_symbol *p;
	LOOP_OVER_LINKED_LIST(p, inter_symbol, all_forms) {
		inter_node_list *PL =
			Inter::Warehouse::get_frame_list(
				InterTree::warehouse(I),
				Inter::Property::permissions_list(p));
		if (PL == NULL) internal_error("no permissions list");
		inter_tree_node *X;
		LOOP_THROUGH_INTER_NODE_LIST(X, PL) {
			inter_symbol *owner_name =
				InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(X), X->W.data[OWNER_PERM_IFLD]);
			if (owner_name == NULL) internal_error("bad owner");
			inter_symbol *owner_kind = NULL;
			inter_tree_node *D = Inter::Symbols::definition(owner_name);
			if ((D) && (D->W.data[ID_IFLD] == INSTANCE_IST)) {
				owner_kind = Inter::Instance::kind_of(owner_name);
			} else {
				owner_kind = owner_name;
			}
			if (VanillaObjects::is_kind_of_object(owner_kind) == FALSE) make_attribute = FALSE;
		}
	}

@ An either/or property which has been deliberately equated to an I6
template attribute with a sentence like...

>> The fixed in place property translates into I6 as "static".

...is (we must assume) already declared as an |Attribute|, so we need to
remember that it's implemented as an attribute when compiling references
to it.

@<An either/or property translated to an attribute declared in the I6 template must be chosen@> =
	if (explicitly_defined_in_kit)
		make_attribute = TRUE;

@ We have in theory 48 Attribute slots to use up, that being the number
available in versions 5 and higher of the Z-machine, but the I6 template
layer consumes so many that only a few slots remain for the user's own
creations. Giving these away to the first-created properties is the
simplest way to allocate them, and in fact it works pretty well, because
the first such either/or properties tend to be created in extensions and
to be frequently used.

@d ATTRIBUTE_SLOTS_TO_GIVE_AWAY 11

@<Otherwise give away attribute slots on a first-come-first-served basis@> =
	if (make_attribute == NOT_APPLICABLE) {
		if (I6_GEN_DATA(attribute_slots_used)++ < ATTRIBUTE_SLOTS_TO_GIVE_AWAY)
			make_attribute = TRUE;
		else
			make_attribute = FALSE;
	}

@ =
void I6TargetObjects::declare_class(code_generator *cgt, code_generation *gen, text_stream *class_name, text_stream *printed_name, text_stream *super_class,
	segmentation_pos *saved) {
	*saved = CodeGen::select(gen, main_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Class %S\n", class_name);
	if (Str::len(super_class) > 0) WRITE("  class %S\n", super_class);
}

void I6TargetObjects::end_class(code_generator *cgt, code_generation *gen, text_stream *class_name, segmentation_pos saved) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";\n");
	CodeGen::deselect(gen, saved);
}

void I6TargetObjects::declare_value_instance(code_generator *cgt,
	code_generation *gen, text_stream *instance_name, text_stream *printed_name, text_stream *val) {
	Generators::declare_constant(gen, instance_name, NULL, RAW_GDCFORM, NULL, val);
}

@ For the I6 header syntax, see the DM4. Note that the "hardwired" short
name is intentionally made blank: we always use I6's |short_name| property
instead. I7's spatial plugin, if loaded (as it usually is), will have
annotated the Inter symbol for the object with an arrow count, that is,
a measure of its spatial depth. This we translate into I6 arrow notation.
If the spatial plugin wasn't loaded then we have no notion of containment,
all arrow counts are 0, and we define a flat sequence of free-standing objects.

One last oddball thing is that direction objects have to be compiled in I6
as if they were spatially inside a special object called |Compass|. This doesn't
really make much conceptual sense, and I7 dropped the idea -- it has no
"compass".

=
void I6TargetObjects::declare_instance(code_generator *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name, text_stream *printed_name, int acount, int is_dir,
	segmentation_pos *saved) {
	*saved = CodeGen::select(gen, main_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S", class_name);
	for (int i=0; i<acount; i++) WRITE(" ->");
	WRITE(" %S", instance_name);
	if (is_dir) WRITE(" Compass");
}

void I6TargetObjects::end_instance(code_generator *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name, segmentation_pos saved) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";\n");
	CodeGen::deselect(gen, saved);
}

int I6TargetObjects::optimise_property_value(code_generator *cgt, code_generation *gen, inter_symbol *prop_name, inter_tree_node *X) {
	if (Inter::Symbols::is_stored_in_data(X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD])) {
		inter_symbol *S = InterSymbolsTables::symbol_from_data_pair_and_frame(X->W.data[DVAL1_PVAL_IFLD], X->W.data[DVAL2_PVAL_IFLD], X);
		if ((S) && (Inter::Symbols::read_annotation(S, INLINE_ARRAY_IANN) == 1)) {
			inter_tree_node *P = Inter::Symbols::definition(S);
			text_stream *OUT = CodeGen::current(gen);
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				if (i>DATA_CONST_IFLD) WRITE(" ");
				CodeGen::pair(gen, P, P->W.data[i], P->W.data[i+1]);
			}
			return TRUE;
		}
	}
	return FALSE;
}

void I6TargetObjects::assign_property(code_generator *cgt, code_generation *gen, inter_symbol *prop_name, text_stream *val) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *property_name = VanillaObjects::inner_property_name(gen, prop_name);
	if (Inter::Symbols::get_flag(prop_name, ATTRIBUTE_MARK_BIT)) {
		if (Str::eq(val, I"0")) WRITE("    has ~%S\n", property_name);
		else WRITE("    has %S\n", property_name);
	} else {
		WRITE("    with %S %S\n", property_name, val);
	}
}

segmentation_pos i6_ap_saved;
void I6TargetObjects::begin_properties_for(code_generator *cgt, code_generation *gen, inter_symbol *kind_name) {
	TEMPORARY_TEXT(instance_name)
	WRITE_TO(instance_name, "VPH_%d", VanillaObjects::weak_id(kind_name));
	Generators::declare_instance(gen, I"Object", instance_name, NULL, -1, FALSE, &i6_ap_saved);
	DISCARD_TEXT(instance_name)
	Inter::Symbols::set_flag(kind_name, KIND_WITH_PROPS_MARK_BIT);
}

void I6TargetObjects::assign_properties(code_generator *cgt, code_generation *gen, inter_symbol *kind_name, inter_symbol *prop_name, text_stream *array) {
	I6TargetObjects::assign_property(cgt, gen, prop_name, array);
}

void I6TargetObjects::end_properties_for(code_generator *cgt, code_generation *gen, inter_symbol *kind_name) {
	Generators::end_instance(gen, I"Object", NULL, i6_ap_saved);
}

void I6TargetObjects::pseudo_object(code_generator *cgt, code_generation *gen, text_stream *obj_name) {
	segmentation_pos saved = CodeGen::select(gen, main_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Object %S \"(%S object)\" has concealed;\n", obj_name, obj_name);
	CodeGen::deselect(gen, saved);
}

@ =
void I6TargetObjects::end_generation(code_generator *cgt, code_generation *gen) {
	if (I6_GEN_DATA(property_offsets_made) > 0) @<Complete the property offset creator@>;
	if (I6_GEN_DATA(DebugAttribute_seen) == FALSE) @<Compile a DebugAttribute function@>;
	if (I6_GEN_DATA(value_ranges_needed)) @<Compile the value_ranges array@>;
	if (I6_GEN_DATA(value_property_holders_needed)) @<Compile the value_property_holders array@>;
	@<Compile some property access code@>;
}

@<Complete the property offset creator@> =
	segmentation_pos saved = CodeGen::select(gen, property_offset_creator_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	OUTDENT;
	WRITE("];\n");
	CodeGen::deselect(gen, saved);

@<Compile a DebugAttribute function@> =
	segmentation_pos saved = CodeGen::select(gen, routines_at_eof_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("[ DebugAttribute a anames str;\n");
	WRITE("    print \"<attribute \", a, \">\";\n");
	WRITE("];\n");
	CodeGen::deselect(gen, saved);

@<Compile the value_ranges array@> =
	segmentation_pos saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Array value_ranges --> 0");
	inter_symbol *max_weak_id = InterSymbolsTables::url_name_to_symbol(gen->from, NULL, 
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = Inter::Symbols::evaluate_to_int(max_weak_id);
		for (int w=1; w<M; w++) {
			int written = FALSE;
			inter_symbol *kind_name;
			LOOP_OVER_LINKED_LIST(kind_name, inter_symbol, gen->kinds_in_declaration_order) {
				if (VanillaObjects::weak_id(kind_name) == w) {
					if (Inter::Symbols::get_flag(kind_name, KIND_WITH_PROPS_MARK_BIT)) {
						written = TRUE;
						WRITE(" %d", Inter::Kind::instance_count(kind_name));
					}
				}
			}
			if (written == FALSE) WRITE(" 0");
		}
		WRITE(";\n");
	}
	CodeGen::deselect(gen, saved);

@<Compile the value_property_holders array@> =
	segmentation_pos saved = CodeGen::select(gen, predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Array value_property_holders --> 0");
	inter_symbol *max_weak_id = InterSymbolsTables::url_name_to_symbol(gen->from, NULL, 
		I"/main/synoptic/kinds/BASE_KIND_HWM");
	if (max_weak_id) {
		int M = Inter::Symbols::evaluate_to_int(max_weak_id);
		for (int w=1; w<M; w++) {
			int written = FALSE;
			inter_symbol *kind_name;
			LOOP_OVER_LINKED_LIST(kind_name, inter_symbol, gen->kinds_in_declaration_order) {
				if (VanillaObjects::weak_id(kind_name) == w) {
					if (Inter::Symbols::get_flag(kind_name, KIND_WITH_PROPS_MARK_BIT)) {
						written = TRUE;
						WRITE(" VPH_%d", w);
					}
				}
			}
			if (written == FALSE) WRITE(" 0");
		}
		WRITE(";\n");
	}
	CodeGen::deselect(gen, saved);

@<Compile some property access code@> =
	segmentation_pos saved = CodeGen::select(gen, routines_at_eof_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("[ _final_read_pval o p a t;\n");
	WRITE("    t = p-->0; p = p-->1; ! print \"has \", o, \" \", p, \"^\";\n");
	WRITE("    if (t == 2) { if (o has p) a = 1; return a; }\n");
	WRITE("    if ((o provides p) && (o.p)) rtrue; rfalse;\n");
	WRITE("];\n");
	WRITE("[ _final_write_eopval o p v t;\n");
	WRITE("    t = p-->0; p = p-->1; ! print \"give \", o, \" \", p, \"^\";\n");
	WRITE("    if (t == 2) { if (v) give o p; else give o ~p; }\n");
	WRITE("    else { if (o provides p) o.p = v; }\n");
	WRITE("];\n");
	WRITE("[ _final_message0 o p q x a rv;\n");
	WRITE("    ! print \"Message send \", (the) o, \" --> \", p, \" \", p-->1, \" addr \", o.(p-->1), \"^\";\n");
	WRITE("    q = p-->1; a = o.q; if (metaclass(a) == Object) rv = a; else if (a) { x = self; self = o; rv = indirect(a); self = x; } ! print \"Message = \", rv, \"^\";\n");
	WRITE("    return rv;\n");
	WRITE("];\n");
	WRITE("Constant i7_lvalue_SET = 1;\n");
	WRITE("Constant i7_lvalue_PREDEC = 2;\n");
	WRITE("Constant i7_lvalue_POSTDEC = 3;\n");
	WRITE("Constant i7_lvalue_PREINC = 4;\n");
	WRITE("Constant i7_lvalue_POSTINC = 5;\n");
	WRITE("Constant i7_lvalue_SETBIT = 6;\n");
	WRITE("Constant i7_lvalue_CLEARBIT = 7;\n");
	CodeGen::deselect(gen, saved);

