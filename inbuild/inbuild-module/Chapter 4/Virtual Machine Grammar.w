[VMGrammar::] Virtual Machine Grammar.

Grammar for parsing natural language descriptions of a virtual machine.

@ This nonterminal corresponds to the Inbuild version number syntax in the
arch module: for example, it matches |2.7.6| or |3/990505|.

=
<version-number> internal 1 {
	TEMPORARY_TEXT(vtext);
	WRITE_TO(vtext, "%W", Wordings::first_wn(W));
	semantic_version_number V = VersionNumbers::from_text(vtext);
	int result = FALSE;
	if (VersionNumbers::is_null(V) == FALSE) {
		result = TRUE;
		semantic_version_number_holder *H = CREATE(semantic_version_number_holder);
		H->version = V;
		*XP = (void *) H;
	}
	DISCARD_TEXT(vtext);
	return result;
}

@ 

=
int VM_matching_error_thrown = FALSE; /* an error occurred during parsing */
text_stream *most_recent_VM_family_name = NULL; /* most recent major VM which matched, or null */
int version_can_be_inferred; /* from earlier in the word range parsed */
linked_list *VM_match_list = NULL;

@ The following nonterminal matches any valid description of a virtual machine,
with result |TRUE| if the current target VM matches that description and
|FALSE| if not.
=
<virtual-machine> internal {
	TEMPORARY_TEXT(vtext);
	WRITE_TO(vtext, "%W", W);
	compatibility_specification *C = Compatibility::from_text(vtext);
	if (C) { *XP = C; return TRUE; }
	*XP = NULL; return FALSE;

/*	VM_matching_error_thrown = FALSE;
	most_recent_VM_family_name = NULL;
	version_can_be_inferred = FALSE;
	VM_match_list = NEW_LINKED_LIST(format_vm);
	<vm-description-list>(W);
	if (VM_matching_error_thrown) { *XP = NULL; *X = FALSE; }
	else { *XP = (void *) VM_match_list; *X = TRUE; }
    return TRUE;
*/
}

@h Parsing VM restrictions.
Given a word range, we see what set of virtual machines it specifies. For example,
the result of calling

>> for Z-machine version 5 or 8 only

is a list of the v5 and v8 target VMs. The same result is produced by

>> for Z-machine versions 5 and 8 only

English being quirky that way.

The words "Z-machine" and "Glulx" are hard-wired so that they can't be
altered using Preform. (The Spanish for "Glulx", say, is "Glulx".) Preform
grammar is used first to split the list:

=
<vm-description-list> ::=
	... |											==> 0; return preform_lookahead_mode; /* match only when looking ahead */
	<vm-description-entry> <vm-description-tail> |	==> 0
	<vm-description-entry>							==> 0

<vm-description-tail> ::=
	, _and/or <vm-description-list> |
	_,/and/or <vm-description-list>

<vm-description-entry> ::=
	...												==> @<Parse latest term in word range list@>

@ Preform doesn't parse the VM names themselves, but it does pick up the
optional part about version numbering:

=
<version-identification> ::=
	version/versions <version-number>				==> 0; *XP = RP[1]

@<Parse latest term in word range list@> =
	semantic_version_number V = VersionNumbers::null();
	TEMPORARY_TEXT(name);
	WRITE_TO(name, "%W", Wordings::first_word(W));
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (Str::eq_insensitive(name, VM->family_name)) {
			most_recent_VM_family_name = Str::duplicate(VM->family_name);
			W = Wordings::trim_first_word(W);
		}
	@<Give up if no family name found in any term of the list so far@>;
	if (Wordings::nonempty(W)) {
		if (<version-identification>(W)) {
			semantic_version_number_holder *H = (semantic_version_number_holder *) <<rp>>;
			V = H->version;
			version_can_be_inferred = TRUE;
		} else if ((version_can_be_inferred) && (<version-number>(W))) {
			semantic_version_number_holder *H = (semantic_version_number_holder *) <<rp>>;
			V = H->version;
		} else {
			VM_matching_error_thrown = TRUE; return TRUE;
		}
		@<Score a match for this specific version of the family, if we know about it@>;
	} else {
		@<Score a match for every known version of the family@>;
	}
	DISCARD_TEXT(name);

@ The word "version" is sometimes implicit, but not after a family name.
Thus "Glulx 3" is not allowed: it has to be "Glulx version 3".

@<Detect family name, if given, and advance one word@> =
	TEMPORARY_TEXT(name);
	WRITE_TO(name, "%W", Wordings::first_wn(W));
	target_vm *VM;
	LOOP_OVER(VM, target_vm) {
		most_recent_VM_family_name = 
	  	if (Str::eq_insensitive(name, VM->family_name)) {
			most_recent_VM_family_name = VM->family_name;
			version_can_be_inferred = FALSE;
			break;
		}
	}

@ The variable |VM_matching_error_thrown| may have been set either on
this term or a previous one: for instance, if we are reading "Squirrel
versions 4 and 7" then at the second term, "7", no family is named
but the variable remains set from "Squirrel" having been parsed at the
first term.

@<Give up if no family name found in any term of the list so far@> =
    if (most_recent_VM_family_name == NULL) {
    	VM_matching_error_thrown = TRUE; return TRUE;
    }

@ We either make a run of matches:

@<Score a match for every known version of the family@> =
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (Str::eq_insensitive(VM->family_name, most_recent_VM_family_name))
			ADD_TO_LINKED_LIST(VM, target_VM, VM_match_list);

@ ...or else we make a single match, or even none at all. This would not be
an error: if the request was for "version 71 of Chipmunk", and we were
unable to compile to this VM (so that no such minor VM record appeared in
the table) then the situation might be that we are reading the requirements
of some extension used by other people, who have a later version of Inform
than us, and which does compile to that VM.

@<Score a match for this specific version of the family, if we know about it@> =
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->family_name, most_recent_VM_family_name)) &&
			(VersionNumbers::eq(VM->version, V)))
			ADD_TO_LINKED_LIST(VM, target_VM, VM_match_list);
