[ExtensionVersioning::] Extension Versioning.

To ensure that the built-in extensions share version numbers with the core compiler.

@ This implements |-extension-versions|:

=
void ExtensionVersioning::show_versions(void) {
	semantic_version_number core_V = ExtensionVersioning::simplified_core_version();
	PRINT("Simplified core version is %v\n", &core_V);
	ExtensionVersioning::iterate(VersionNumbers::null());
}

@ And |-sync-extension-versions|:

=
void ExtensionVersioning::sync_versions(void) {
	semantic_version_number core_V = ExtensionVersioning::simplified_core_version();
	PRINT("Simplified core version is %v\n", &core_V);
	ExtensionVersioning::iterate(core_V);
}

semantic_version_number ExtensionVersioning::simplified_core_version(void) {
	web_md *inform7_web =
		WebMetadata::get_without_modules(Pathnames::from_text(I"inform7"), NULL);
	semantic_version_number V = inform7_web->version_number;
	V.prerelease_segments = NULL;
	V.build_metadata = NULL;
	return V;
}

@ Both use the following to work through the built-in kits:

=
void ExtensionVersioning::iterate(semantic_version_number set_to) {
	pathname *P = Pathnames::from_text(I"inform7/Internal/Extensions/Graham Nelson");
	linked_list *L = Directories::listing(P);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
		if (Platform::is_folder_separator(Str::get_last_char(entry))) {
			Str::delete_last_character(entry);
			pathname *X = Pathnames::down(P, entry);
			match_results mr = Regexp::create_mr();
			if (Regexp::match(&mr, entry, U"(%c+).i7xd")) {
				text_stream *raw_name = mr.exp[0];
				ExtensionVersioning::show_version(X, raw_name, set_to);
			}
			Regexp::dispose_of(&mr);
		}
	}
}

void ExtensionVersioning::show_version(pathname *P, text_stream *name,
	semantic_version_number set_to) {
	semantic_version_number V = ExtensionVersioning::read_version(P, name, set_to);
	PRINT("Extension %S has version %v\n", name, &V);
}

@ The actual work, then, is done by this function, which returns the version
number of the kit stored at the path |kit|; if |set_to| is other than null,
the kit's version is changed to |set_to|, and this value returned. In both
cases, the kit's JSON metadata file is read in; in the second case, it is
then written back out, modified to include the new version number. (Note
that no file write occurs unless an actual change is needed: if |set_to|
is the same as the version it already has, there's no need to rewrite.)

=
semantic_version_number ExtensionVersioning::read_version(pathname *X, text_stream *name,
	semantic_version_number set_to) {
	filename *F = Filenames::in(X, I"extension_metadata.json");
	TEMPORARY_TEXT(contents)
	TextFiles::read(F, FALSE, "unable to read file of JSON metadata", TRUE,
		&ExtensionVersioning::read_metadata_file_helper, NULL, contents);
	text_file_position tfp = TextFiles::at(F, 1);
	JSON_value *value = JSON::decode(contents, &tfp);
	if ((value) && (value->JSON_type == ERROR_JSONTYPE)) {
		Errors::at_position("Syntax error in metadata file for extension", F, 1);
		return VersionNumbers::null();
	}
	DISCARD_TEXT(contents)
	
	JSON_value *is = JSON::look_up_object(value, I"is");
	if (is == NULL) {
		Errors::at_position("Semantic error in metadata file for extension", F, 1);
		return VersionNumbers::null();
	}
	JSON_value *version = JSON::look_up_object(is, I"version");
	semantic_version_number V = VersionNumbers::null();
	if (version) {
		V = VersionNumbers::from_text(version->if_string);
		if (VersionNumbers::is_null(V)) {
			Errors::at_position("Malformed version number in metadata file for extension", F, 1);
			return VersionNumbers::null();
		}
	}
	if (VersionNumbers::is_null(set_to) == FALSE) {
		@<If necessary impose the new version in metadata file@>;
		@<If necessary impose the new version in directory name@>;
		@<If necessary impose the new version in extension header@>;
	}
	return V;
}

@ The following test used to be just |VersionNumbers::ne(set_to, V)|, but this,
because it properly followed the semver standard, regarded them as equal if they
differed only in the build code -- so |10.1.0-beta+6V20| would not be updated to
|10.1.0-beta+6V44|, for example. We now force a sync if there is any textual
difference at all.

@<If necessary impose the new version in metadata file@> =
	TEMPORARY_TEXT(a)
	TEMPORARY_TEXT(b)
	WRITE_TO(a, "%v", &set_to);
	WRITE_TO(b, "%v", &V);
	if (Str::ne(a, b))
		@<Change the version to set_to@>;
	DISCARD_TEXT(a)
	DISCARD_TEXT(b)

@ We change the JSON object for the kit's metadata (at object.is.version), and
then encode the object out as a new version of the file:

@<Change the version to set_to@> =
	if (version == NULL) {
		version = JSON::new_string(I"");
		JSON::add_to_object(is, I"version", version);
	}
	PRINT("Rewriting %f to impose version number %v (was %v)\n", F, &set_to, &V);
	Str::clear(version->if_string);
	WRITE_TO(version->if_string, "%v", &set_to);
	text_stream JSON_struct; text_stream *OUT = &JSON_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("unable to open metadata file for output: %f", F);
	JSON::encode(OUT, value);
	STREAM_CLOSE(OUT);
	V = set_to;

@ Note that the following currently does nothing, which is intentional. It's
more practical for the built-in extensions not to have version numbers in their
directory names, since that makes make-files more stable.

@<If necessary impose the new version in directory name@> =
	TEMPORARY_TEXT(correct_name)
	TEMPORARY_TEXT(flattened)
	WRITE_TO(flattened, "%v", &set_to);
	LOOP_THROUGH_TEXT(pos, flattened)
		if (Str::get(pos) == '.')
			Str::put(pos, '_');
	WRITE_TO(correct_name, "%S-v%S.i7xd", name, flattened);
	DISCARD_TEXT(flattened)
	if ((FALSE) && (Str::ne(Pathnames::directory_name(X), correct_name))) {
		pathname *XC = Pathnames::down(Pathnames::up(X), correct_name);
		Pathnames::move_directory(X, XC);
		X = XC;
		PRINT("Renaming directory to %p\n", X);
	}
	DISCARD_TEXT(correct_name)

@

@<If necessary impose the new version in extension header@> =
	TEMPORARY_TEXT(leaf)
	WRITE_TO(leaf, "%S.i7x", name);
	filename *F = Filenames::in(Pathnames::down(X, I"Source"), leaf);
	DISCARD_TEXT(leaf)
	TEMPORARY_TEXT(source)
	TextFiles::read(F, FALSE, "unable to read file of extension source", TRUE,
		&ExtensionVersioning::read_metadata_file_helper, NULL, source);

	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, source, U"(Version )(%d%C*?)( of %c*)")) {
		semantic_version_number sourced = VersionNumbers::from_text(mr.exp[1]);
		TEMPORARY_TEXT(a)
		TEMPORARY_TEXT(b)
		WRITE_TO(a, "%v", &set_to);
		WRITE_TO(b, "%v", &sourced);
		if (Str::ne(a, b))
			@<Change the version in the extension to set_to@>;
		DISCARD_TEXT(a)
		DISCARD_TEXT(b)
	}
	Regexp::dispose_of(&mr);
	DISCARD_TEXT(source)

@<Change the version in the extension to set_to@> =
	PRINT("Rewriting opening line of %f\n", F);
	text_stream S_struct; text_stream *OUT = &S_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("unable to open extension source for output: %f", F);
	WRITE("%S%v", mr.exp[0], &set_to);
	int pos = Str::len(mr.exp[0]) + Str::len(mr.exp[1]);
	for (int i=pos; i<Str::len(source); i++)
		PUT(Str::get_at(source, i));
	STREAM_CLOSE(OUT);

@

=
void ExtensionVersioning::read_metadata_file_helper(text_stream *text, text_file_position *tfp,
	void *v_state) {
	text_stream *contents = (text_stream *) v_state;
	WRITE_TO(contents, "%S\n", text);
}
