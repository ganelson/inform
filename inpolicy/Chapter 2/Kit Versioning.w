[KitVersioning::] Kit Versioning.

To ensure that the built-in kits share version numbers with the core compiler.

@ This implements |-kit-versions|:

=
void KitVersioning::show_versions(void) {
	web_md *inform7_web =
		WebMetadata::get_without_modules(Pathnames::from_text(I"inform7"), NULL);
	semantic_version_number core_V = inform7_web->version_number;
	PRINT("Core version is %v\n", &core_V);
	KitVersioning::iterate(VersionNumbers::null());
}

@ And |-sync-kit-versions|:

=
void KitVersioning::sync_versions(void) {
	web_md *inform7_web =
		WebMetadata::get_without_modules(Pathnames::from_text(I"inform7"), NULL);
	semantic_version_number core_V = inform7_web->version_number;
	PRINT("inform7 web has version %v\n", &core_V);
	KitVersioning::iterate(core_V);
}

@ Both use the following to work through the built-in kits:

=
void KitVersioning::iterate(semantic_version_number set_to) {
	KitVersioning::show_version(I"WorldModelKit", set_to);
	KitVersioning::show_version(I"EnglishLanguageKit", set_to);
	KitVersioning::show_version(I"CommandParserKit", set_to);
	KitVersioning::show_version(I"BasicInformKit", set_to);
	KitVersioning::show_version(I"Architecture16Kit", set_to);
	KitVersioning::show_version(I"Architecture32Kit", set_to);
}

void KitVersioning::show_version(text_stream *name, semantic_version_number set_to) {
	pathname *P = Pathnames::from_text(I"inform7/Internal/Inter");
	P = Pathnames::down(P, name);
	semantic_version_number V = KitVersioning::read_version(P, set_to);
	PRINT("Kit %S has version %v\n", name, &V);
}

@ The actual work, then, is done by this function, which returns the version
number of the kit stored at the path |kit|; if |set_to| is other than null,
the kit's version is changed to |set_to|, and this value returned. In both
cases, the kit's JSON metadata file is read in; in the second case, it is
then written back out, modified to include the new version number. (Note
that no file write occurs unless an actual change is needed: if |set_to|
is the same as the version it already has, there's no need to rewrite.)

=
semantic_version_number KitVersioning::read_version(pathname *kit, semantic_version_number set_to) {
	filename *F = Filenames::in(kit, I"kit_metadata.json");
	TEMPORARY_TEXT(contents)
	TextFiles::read(F, FALSE, "unable to read file of JSON metadata", TRUE,
		&KitVersioning::read_metadata_file_helper, NULL, contents);
	text_file_position tfp = TextFiles::at(F, 1);
	JSON_value *value = JSON::decode(contents, &tfp);
	if ((value) && (value->JSON_type == ERROR_JSONTYPE)) {
		Errors::at_position("Syntax error in metadata file for kit", F, 1);
		return VersionNumbers::null();
	}
	DISCARD_TEXT(contents)
	
	JSON_value *is = JSON::look_up_object(value, I"is");
	if (is == NULL) {
		Errors::at_position("Semantic error in metadata file for kit", F, 1);
		return VersionNumbers::null();
	}
	JSON_value *version = JSON::look_up_object(is, I"version");
	semantic_version_number V = VersionNumbers::null();
	if (version) {
		V = VersionNumbers::from_text(version->if_string);
		if (VersionNumbers::is_null(V)) {
			Errors::at_position("Malformed version number in metadata file for kit", F, 1);
			return VersionNumbers::null();
		}
	}
	if (VersionNumbers::is_null(set_to) == FALSE)
		@<Decide whether to impose the new version@>;
	return V;
}

@ The following test used to be just |VersionNumbers::ne(set_to, V)|, but this,
because it properly followed the semver standard, regarded them as equal if they
differed only in the build code -- so |10.1.0-beta+6V20| would not be updated to
|10.1.0-beta+6V44|, for example. We now force a sync if there is any textual
difference at all.

@<Decide whether to impose the new version@> =
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

@

=
void KitVersioning::read_metadata_file_helper(text_stream *text, text_file_position *tfp,
	void *v_state) {
	text_stream *contents = (text_stream *) v_state;
	WRITE_TO(contents, "%S\n", text);
}
