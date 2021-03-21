[PluginCalls::] Plugin Calls.

The interface between the main compiler and its plugins.

@ The following set of functions is an API for the main compiler to consult
with the plugins; put another way, it is also an API for the plugins to
influence the main compiler. They do so by adding plugs to the relevant rulebooks:
see //PluginManager::plug//.

Nothing can prevent this from being a big old miscellany, so we take them by
compiler module, and within each module in alphabetical order.

@h Influencing core.
Called from //Task::advance_stage_to//. This allows plugins to run additional
production-line steps in compilation, and that is done mostly at the Inter
generation stage, to add extra arrays or functions needed at run-time to
support whatever feature the plugin implements. For example, the mapping plugin
compiles an array to hold the map during stage |INTER1_CSEQ|.

Because the following is called at the end of every main stage of compilation
except for |FINISHED_CSEQ|, it is called about 15 times in all, so it is
essential to check |stage| and act only on the right occasion. |debugging| is
|TRUE| if this is a debugging run, and allows a plugin to generate diagnostic
features if so.

A function attached to this plug should then ideally divide its work up into
major subtasks and call each one with the |BENCH| macro, so that the time it
takes will (if appreciable) be included in the //inform7: Performance Metrics//.

See //How To Compile// for the stages and their |*_CSEQ| numbers.

@e PRODUCTION_LINE_PLUG from 1

=
int PluginCalls::production_line(int stage, int debugging, stopwatch_timer *timer) {
	PLUGINS_CALL(PRODUCTION_LINE_PLUG, stage, debugging, timer);
}

@h Influencing assertions.
Called from //assertions: Refine Parse Tree// to ask if this node is a noun
phrase with special significance: for example, "below" is significant to the
mapping plugin. If so, the plugin should set the subject of the node to say
what it refers to, and return |TRUE|.

@e ACT_ON_SPECIAL_NPS_PLUG

=
int PluginCalls::act_on_special_NPs(parse_node *p) {
	PLUGINS_CALL(ACT_ON_SPECIAL_NPS_PLUG, p);
}

@ Called from //assertions: Assemblies//. Body-snatching is used only by the
"player" plugin, and is explained there; it handles the consequences of sentences
like "The player is Lord Collingwood".

@e DETECT_BODYSNATCHING_PLUG

=
int PluginCalls::detect_bodysnatching(inference_subject *body, int *snatcher,
	inference_subject **counterpart) {
	PLUGINS_CALL(DETECT_BODYSNATCHING_PLUG, body, snatcher, counterpart);
}

@ Called from //assertions: Assertions// to see if any plugin wants to
intepret a sentence its own way, either taking direct action or issuing a
more nuanced problem message than the usual machinery would have issued.
If so, the plugin should return |TRUE|, which both ensures that no other
plugin intervenes, and also tells //assertions// not to proceed further
with the sentence.

@e INTERVENE_IN_ASSERTION_PLUG

=
int PluginCalls::intervene_in_assertion(parse_node *px, parse_node *py) {
	PLUGINS_CALL(INTERVENE_IN_ASSERTION_PLUG, px, py);
}

@ Called from //assertions: The Creator// when a copular sentence may be
creating something. For example, the actions plugin needs this.

@e CREATION_PLUG

=
int PluginCalls::creation(parse_node *px, parse_node *py) {
	PLUGINS_CALL(CREATION_PLUG, px, py);
}

@ Called from //assertions: Assertions// when an unfamiliar node type appears
where a property value might be expected. For example, the actions plugin
uses this to deal with setting a property to an |ACTION_NT| node. To
intervene, set the node specification using //assertions: Refine Parse Tree//
and return |TRUE|; or return |FALSE| to let nature take its course.

@e UNUSUAL_PROPERTY_VALUE_PLUG

=
int PluginCalls::unusual_property_value(parse_node *py) {
	PLUGINS_CALL(UNUSUAL_PROPERTY_VALUE_PLUG, py);
}

@ Called from //assertions: The Creator// when an instance is being made in
an assembly, and its name may involve a genitive. For example, if the
assembly says "every person has a nose", then normally this would be called
something like "Mr Rogers's nose"; but the player plugin uses the following
to have "your nose" in the case of the player instance.

@e IRREGULAR_GENITIVE_IN_ASSEMBLY_PLUG

=
int PluginCalls::irregular_genitive(inference_subject *owner, text_stream *genitive,
	int *propriety) {
	PLUGINS_CALL(IRREGULAR_GENITIVE_IN_ASSEMBLY_PLUG, owner, genitive, propriety);
}

@ Called from //assertions: Booting Verbs// to give each plugin a chance to
create any special sentence meanings it would like to. For example, the
sounds plugin defines a special form of assertion sentence this way. The
plugin should always return |FALSE|, since otherwise it may gazump other
plugins and cause them to stop working.

@e MAKE_SPECIAL_MEANINGS_PLUG

=
int PluginCalls::make_special_meanings(void) {
	PLUGINS_CALLV(MAKE_SPECIAL_MEANINGS_PLUG);
}

@ Called from //assertions: Assertions// when it seems that the author wants
to create a property of something with a sentence like "A container has a
number called security rating." A plugin can intervene and act on that,
returning |TRUE| to stop the usual machinery. For example, the actions
plugin does this so that "The going action has a number called celerity"
can be intercepted to create an action variable, not a property.

@e OFFERED_PROPERTY_PLUG

=
int PluginCalls::offered_property(kind *K, parse_node *owner, parse_node *what) {
	PLUGINS_CALL(OFFERED_PROPERTY_PLUG, K, owner, what);
}

@ Called from //assertions: Assertions// when the specification pseudo-variable
is about to be set for something; the plugin can then intercept this.

@e OFFERED_SPECIFICATION_PLUG

=
int PluginCalls::offered_specification(parse_node *owner, wording W) {
	PLUGINS_CALL(OFFERED_SPECIFICATION_PLUG, owner, W);
}

@ Called from //assertions: Refine Parse Tree// to ask plugins if a noun phrase
has a noun implicit within it, even though none is explicitly given. For
example, the player plugin uses this to say that "initially carried" means
"...by the player", and sets the subject of the node to be the player character
instance.

@e REFINE_IMPLICIT_NOUN_PLUG

=
int PluginCalls::refine_implicit_noun(parse_node *p) {
	PLUGINS_CALL(REFINE_IMPLICIT_NOUN_PLUG, p);
}

@ Called from //assertions: Classifying Sentences// to give plugins the chance
of an early look at a newly-read assertion. For example, the map plugin uses
this to spot that a sentence will create a new direction.

@e NEW_ASSERTION_NOTIFY_PLUG

=
int PluginCalls::new_assertion_notify(parse_node *p) {
	PLUGINS_CALL(NEW_ASSERTION_NOTIFY_PLUG, p);
}

@ Called from //assertions: The Equality Relation Revisited// when we have
to decide if it's valid to ask or declare that two things are the same.
Returning |TRUE| says that it is always valid; returning |FALSE| leaves
it to the regular machinery. This plug can therefore only be used to permit
additional usages, not to restrict existing ones.

@e TYPECHECK_EQUALITY_PLUG

=
int PluginCalls::typecheck_equality(kind *K1, kind *K2) {
	PLUGINS_CALL(TYPECHECK_EQUALITY_PLUG, K1, K2);
}

@ Called from //assertions: Assertions// to warn plugins that a variable
is now being assigned a value by an explicit assertion sentence.

@e VARIABLE_VALUE_NOTIFY_PLUG

=
int PluginCalls::variable_set_warning(nonlocal_variable *q, parse_node *val) {
	PLUGINS_CALL(VARIABLE_VALUE_NOTIFY_PLUG, q, val);
}

@h Influencing values.
Called from //values: Rvalues// to allow plugins to help decide whether values
of the same kind would be equal if evaluated at runtime. For example, the
"scenes" plugin uses this to determine if two |K_scene| constants are equal.
To make a decision, set |rv| to either |TRUE| or |FALSE| and return |TRUE|.
To make no decision, return |FALSE|.

@e COMPARE_CONSTANT_PLUG

=
int PluginCalls::compare_constant(parse_node *c1, parse_node *c2, int *rv) {
	PLUGINS_CALL(COMPARE_CONSTANT_PLUG, c1, c2, rv);
}

@ Called from //values: Rvalues// to allow plugins to compile rvalues in
eccentric ways of their own: not in fact just for the whimsy of it, but to
make it possible for plugins to support base kinds of their own. For example,
the "actions" plugin needs this to deal with the "stored action" kind.

@e COMPILE_CONSTANT_PLUG

=
int PluginCalls::compile_constant(value_holster *VH, kind *K, parse_node *spec) {
	PLUGINS_CALL(COMPILE_CONSTANT_PLUG, VH, K, spec);
}

@ Called from //values: Conditions// to allow plugins to compile conditions in
their own way. For example, the "actions" plugin needs this to compile matches
of the current action against an action pattern.

@e COMPILE_CONDITION_PLUG

=
int PluginCalls::compile_condition(value_holster *VH, parse_node *spec) {
	PLUGINS_CALL(COMPILE_CONDITION_PLUG, VH, spec);
}

@ Called from //values: Specifications// to ask if there is some reason why
a rule about |I1| should be thought broader in scope than one about |I2|. This
is used by the regions plugin when one is a sub-region of the other. This is
expected to behave as a |strcmp|-like sorting function, with a positive
return value saying |I1| is broader, negative |I2|, or zero that they are equal.

@e MORE_SPECIFIC_PLUG

=
int PluginCalls::more_specific(instance *I1, instance *I2) {
	PLUGINS_CALL(MORE_SPECIFIC_PLUG, I1, I2);
}

@ Called from //values: Constants and Descriptions// to give plugins a chance
to parse text which might otherwise be meaningless (or mean something different)
and make it a "composite noun-quantifier" such as "everywhere" or "nothing".
The main compiler does not recognise "everywhere" because it has no concept
of space, but the spatial plugin does, and this is how.

@e PARSE_COMPOSITE_NQS_PLUG

=
int PluginCalls::parse_composite_NQs(wording *W, wording *DW,
	quantifier **quantifier_used, kind **some_kind) {
	PLUGINS_CALL(PARSE_COMPOSITE_NQS_PLUG, W, DW, quantifier_used, some_kind);
}

@h Influencing knowledge.
Called from //knowledge: The Model World// to invite the plugin to participate
in stages I to V of the completion process. This may involve using contextual
reasoning to draw further inferences.

@e COMPLETE_MODEL_PLUG

=
int PluginCalls::complete_model(int stage) {
	PLUGINS_CALL(COMPLETE_MODEL_PLUG, stage);
}

@ Called from //knowledge: Inference Subjects// to invite the plugin to
create any additional inference subjects it might want to reason about. In
practice, this tends to be used to create preliminary subjects to stand in
for significant kinds before those kinds are ready to be created.

@e CREATE_INFERENCE_SUBJECTS_PLUG

=
int PluginCalls::create_inference_subjects(void) {
	PLUGINS_CALLV(CREATE_INFERENCE_SUBJECTS_PLUG);
}

@ Called from //knowledge: Indefinite Appearance// to ask the plugins what
inferences, if any, to draw from a double-quoted text standing as an entire
sentence. The |infs| is the subject which was being talked about at the time
the text was quoted, and therefore presumably is what the text should describe.

@e DEFAULT_APPEARANCE_PLUG

=
int PluginCalls::default_appearance(inference_subject *infs, parse_node *txt) {
	PLUGINS_CALL(DEFAULT_APPEARANCE_PLUG, infs, txt);
}

@ Called from //knowledge: Inferences// when an inference is drawn about
something. This does not, of course, necessarily mean that this will actually
be the property of something: the inference might turn out to be mistaken. The
mapping plugin uses this to infer further that if something is said to be a
map connection to somewhere else, then it is probably a room.

@e INFERENCE_DRAWN_NOTIFY_PLUG

=
int PluginCalls::inference_drawn(inference *I, inference_subject *subj) {
	PLUGINS_CALL(INFERENCE_DRAWN_NOTIFY_PLUG, I, subj);
}

@ Called from //knowledge: Kind Subjects//. Early in the run, before some kinds
are created, placeholder inference subjects are created to stand in for them;
this call enables plugins to recognise certain texts as referring to those.

@e NAME_TO_EARLY_INFS_PLUG

=
int PluginCalls::name_to_early_infs(wording W, inference_subject **infs) {
	PLUGINS_CALL(NAME_TO_EARLY_INFS_PLUG, W, infs);
}

@ Called from //knowledge: Kind Subjects// to warn plugins about a new kind,
which in practice enables them to spot from the name that it is actually a kind
they want to provide built-in support for: thus the actions plugin reacts to
the name "stored action", for example. |K| is the newcomer, |super| its super-kind,
if any; |d| and |W| are alternate forms of that name -- |d| will be useful if the
kind was created by a kit (such as "number"), |W| if it came from Inform 7
source text (such as "container").

@e NEW_BASE_KIND_NOTIFY_PLUG

=
int PluginCalls::new_base_kind_notify(kind *K, kind *super, text_stream *d, wording W) {
	PLUGINS_CALL(NEW_BASE_KIND_NOTIFY_PLUG, K, d, W);
}

@ Called from //knowledge: Instances// to warn plugins that a new instance has
been created. For example, the figures plugin needs to know this so that it
can see when a new illustration has been created.

At the time this is called, the exact kind of an instance may not be knowm,
if that instance is an object: so beware of relying on the kind unless you're
sure you're not dealing with an object.

@e NEW_INSTANCE_NOTIFY_PLUG

=
int PluginCalls::new_named_instance_notify(instance *nc) {
	PLUGINS_CALL(NEW_INSTANCE_NOTIFY_PLUG, nc);
}

@ Called from //knowledge: Property Permissions// to warn plugins that a subject
has been given permission to hold a property; the parsing plugin, for example,
uses this to attach a visibility flag.

@e NEW_PERMISSION_NOTIFY_PLUG

=
int PluginCalls::new_permission_notify(property_permission *pp) {
	PLUGINS_CALL(NEW_PERMISSION_NOTIFY_PLUG, pp);
}

@ Called from //knowledge: Properties// to warn plugins that a property has
been created, which they can use to spot properties with special significance
to them.

@e NEW_PROPERTY_NOTIFY_PLUG

=
int PluginCalls::new_property_notify(property *prn) {
	PLUGINS_CALL(NEW_PROPERTY_NOTIFY_PLUG, prn);
}

@ Called from //knowledge: Inference Subjects// to warn plugins that a subject
has been created, which they can use to spot subjects with special significance
to them.

@e NEW_SUBJECT_NOTIFY_PLUG

=
int PluginCalls::new_subject_notify(inference_subject *subj) {
	PLUGINS_CALL(NEW_SUBJECT_NOTIFY_PLUG, subj);
}

@ Called from //knowledge: Nonlocal Variables// to warn plugins that a new
variable has been created, which they can use to spot variables with special
significance to them.

@e NEW_VARIABLE_NOTIFY_PLUG

=
int PluginCalls::new_variable_notify(nonlocal_variable *q) {
	PLUGINS_CALL(NEW_VARIABLE_NOTIFY_PLUG, q);
}

@ Called from //knowledge: Instances// to warn plugins that the kind of an
instance is about to be set. This happens most often when the instance is
created, but can also happen again, refining the kind to a subkind, when
the instance is an object.

@e SET_KIND_NOTIFY_PLUG

=
int PluginCalls::set_kind_notify(instance *I, kind *k) {
	PLUGINS_CALL(SET_KIND_NOTIFY_PLUG, I, k);
}

@ Called from //knowledge: Kind Subjects// when one kind of object is made a
subkind of another, as for example when "container" is a made a subkind of
"thing". The plugin should return |TRUE| if it wishes to forbid this,
and if so, it had better throw a problem message, or the user will be
mystified.

This can be used to forbid certain kinds having subkinds, as for example the
regions plugin does with the "region" kind.

@e SET_SUBKIND_NOTIFY_PLUG

=
int PluginCalls::set_subkind_notify(kind *sub, kind *super) {
	PLUGINS_CALL(SET_SUBKIND_NOTIFY_PLUG, sub, super);
}

@h Influencing the imperative plugin.
Called from //imperative: Rule Bookings// to give plugins a chance to move
automatically placed rules from one rulebook to another. The actions plugin
uses this to break up what would otherwise be unwieldy before and after
rulebooks into smaller ones for each action.

If making a diversion, the plugin should write the new rulebook into |new_owner|
and return |TRUE|; and otherwise |FALSE|.

@e PLACE_RULE_PLUG

=
int PluginCalls::place_rule(rule *R, rulebook *original_owner, rulebook **new_owner) {
	PLUGINS_CALL(PLACE_RULE_PLUG, R, original_owner, new_owner);
}

@ Called from //imperative: Rulebooks//. This is very similar, but runs in all cases,
and not only for automatic placement.

@e RULE_PLACEMENT_NOTIFY_PLUG

=
int PluginCalls::rule_placement_notify(rule *R, rulebook *original_owner, int side, rule *ref_rule) {
	PLUGINS_CALL(RULE_PLACEMENT_NOTIFY_PLUG, R, original_owner, side, ref_rule);
}

@

@e COMPILE_TEST_HEAD_PLUG

=
int PluginCalls::compile_test_head(phrase *ph, rule *R, int *tests) {
	PLUGINS_CALL(COMPILE_TEST_HEAD_PLUG, ph, R, tests);
}

@

@e COMPILE_TEST_TAIL_PLUG

=
int PluginCalls::compile_test_tail(phrase *ph, rule *R) {
	PLUGINS_CALL(COMPILE_TEST_TAIL_PLUG, ph, R);
}

@h Influencing the actions plugin.
We now have a whole run of functions called only by the actions plugin, and
therefore only when it is active.

Called from //if: Actions Plugin// to signal that a new action has been
created. For example, the going plugin uses this to spot the arrival of "going".

@e NEW_ACTION_NOTIFY_PLUG

=
int PluginCalls::new_action_notify(action_name *an) {
	PLUGINS_CALL(NEW_ACTION_NOTIFY_PLUG, an);
}

@ Called from //if: Action Pattern Clauses// to invite plugins to change the
action pattern clause ID associated with a given action variable. This may be
needed in order to cross-reference between multiple such clauses, as with
the going action variables.

@e DIVERT_AP_CLAUSE_PLUG

=
int PluginCalls::divert_AP_clause_ID(stacked_variable *stv, int *id) {
	*id = -1;
	PLUGINS_CALL(DIVERT_AP_CLAUSE_PLUG, stv, id);
}

@ Called from //if: Action Pattern Clauses// to ask plugins to print a helpful
name for the debugging log for any new clause ID |C| which they have created.

@e WRITE_AP_CLAUSE_ID_PLUG

=
int PluginCalls::write_AP_clause_ID(OUTPUT_STREAM, int C) {
	PLUGINS_CALL(WRITE_AP_CLAUSE_ID_PLUG, OUT, C);
}

@ Called from //if: Action Pattern Clauses// to ask for the |*_APCA| aspect
for the clause ID |C|, where |C| is a new clause ID created by the plugin. If
this is not given, then the aspect will be |MISC_APCA|.

@e ASPECT_OF_AP_CLAUSE_ID_PLUG

=
int PluginCalls::aspect_of_AP_clause_ID(int C, int *A) {
	PLUGINS_CALL(ASPECT_OF_AP_CLAUSE_ID_PLUG, C, A);
}

@ Called from //if: Action Pattern Clauses// to give plugins a chance to
decide which AP is more specific, on the basis of the extra clauses defined
in the plugin.

If the plugin recognises the patterns as ways to describe an action it knows
about, it can choose to take the decision, storing either 1 or -1 in
|rv|, and returning |TRUE|. If it instead stores 0 in |rv|, it can also
choose to set |ignore_in|, which tells the usual machinery not to judge on the
basis of the |[in: ...]| clause in the pattern.

If the plugin sees nothing relevant about the patterns, it should return |FALSE|
to let the usual machinery take its course.

@e COMPARE_AP_SPECIFICITY_PLUG

=
int PluginCalls::compare_AP_specificity(action_pattern *ap1, action_pattern *ap2,
	int *rv, int *ignore_in) {
	PLUGINS_CALL(COMPARE_AP_SPECIFICITY_PLUG, ap1, ap2, rv, ignore_in);
}

@ Called from //if: Action Pattern Clauses// to notify plugins that a clause
matching an action variable has just been added to an action pattern.

@e NEW_AP_CLAUSE_PLUG

=
int PluginCalls::new_action_variable_clause(action_pattern *ap, ap_clause *apoc) {
	PLUGINS_CALL(NEW_AP_CLAUSE_PLUG, ap, apoc);
}

@ Called from //if: Parse Clauses// to give plugins a chance to intervene in
the normal process of evaluating the meaning of text in an action pattern
clause: for example, in parsing "going nowhere", the going plugin uses this
to detect that the |NOUN_AP_CLAUSE|, with text "nowhere", should not be parsed
normally. What it does it to set a bit in the bitmap |bits|, which it will pick
up again and act upon when reacting to |ACT_ON_ANL_ENTRY_OPTIONS_PLUG|.

If the plugin does not set a bit in |bits|, the normal machinery parses the
text of the clause in the normal way.

@e PARSE_AP_CLAUSE_PLUG

int PluginCalls::parse_AP_clause(action_name *an, anl_clause *c, int *bits) {
	PLUGINS_CALL(PARSE_AP_CLAUSE_PLUG, an, c, bits);
}

@ Called from //if: Parse Clauses// to give plugins a chance to intervene in
the type-checking process for a clause. Ordinarily, this would just check that
the contents have the right kind: if matching an action variable of kind |K|
then it must be a value compatible with |K| or a description of such.

By returning |TRUE|, a plugin can instead take responsibility for the decision
itself, bypassing that. The |outcome| should then be set |TRUE| (it's valid)
or |FALSE| (it isn't).

@e VALIDATE_AP_CLAUSE_PLUG

=
int PluginCalls::validate_AP_clause(action_name *an, anl_clause *c, int *outcome) {
	PLUGINS_CALL(VALIDATE_AP_CLAUSE_PLUG, an, c, outcome);
}

@ Called from //if: Parse Clauses// to deal with the options bitmap set
previously by a |PARSE_AP_CLAUSE_PLUG| call: see above.

@e ACT_ON_ANL_ENTRY_OPTIONS_PLUG

=
int PluginCalls::act_on_ANL_entry_options(anl_entry *entry, int entry_options, int *fail) {
	PLUGINS_CALL(ACT_ON_ANL_ENTRY_OPTIONS_PLUG, entry, entry_options, fail);
}

@ Called from //runtime: Action Patterns// when assembling the requirement
clauses for compiling a mattern match; this gives plugins a chance to act
extra stipulations, which are not explicit in clauses already in the pattern.

@e SET_PATTERN_MATCH_REQUIREMENTS_PLUG

=
int PluginCalls::set_pattern_match_requirements(action_pattern *ap, int *cpm,
	int needed[MAX_CPM_CLAUSES], ap_clause *needed_apoc[MAX_CPM_CLAUSES]) {
	PLUGINS_CALL(SET_PATTERN_MATCH_REQUIREMENTS_PLUG, ap, cpm, needed, needed_apoc);
}

@ Called from //runtime: Action Patterns// when compiling any additional
requirements set by |SET_PATTERN_MATCH_REQUIREMENTS_PLUG|.

@e COMPILE_PATTERN_MATCH_CLAUSE_PLUG

=
int PluginCalls::compile_pattern_match_clause(value_holster *VH, action_pattern *ap,
	int cpmc) {
	PLUGINS_CALL(COMPILE_PATTERN_MATCH_CLAUSE_PLUG, VH, ap, cpmc);
}

@h Influencing index.
Called from //index: Index Physical World// to add something (if it wishes)
to the index description of an instance in the spatial model. For example,
the regions plugin uses this to put colour chips next to names of regions.

@e ADD_TO_WORLD_INDEX_PLUG

=
int PluginCalls::add_to_World_index(OUTPUT_STREAM, instance *O) {
	PLUGINS_CALL(ADD_TO_WORLD_INDEX_PLUG, OUT, O);
}

@ Called from //index: Index Physical World// to add something (if it wishes)
to the textual description of an instance in the spatial model. For example,
the mapping plugin uses this to say where a door leads.

@e ANNOTATE_IN_WORLD_INDEX_PLUG

int PluginCalls::annotate_in_World_index(OUTPUT_STREAM, instance *O) {
	PLUGINS_CALL(ANNOTATE_IN_WORLD_INDEX_PLUG, OUT, O);
}
