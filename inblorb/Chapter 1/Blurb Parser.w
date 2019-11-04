[Parser::] Blurb Parser.

Blurb is an interpreted language, and this is the interpreter for it.

@h Reading the file.
We divide the file into blurb commands at line breaks, so:

=
void Parser::parse_blurb_file(filename *F) {
	TextFiles::read(F, FALSE, "can't open blurb file", TRUE, Parser::interpret_line, 0, NULL);
	BlorbErrors::set_error_position(NULL);
}

@ The sequence of values enumerated here must correspond exactly to
indexes into the syntaxes table below.

@e author_COMMAND from 0
@e auxiliary_COMMAND
@e base64_COMMAND
@e copyright_COMMAND
@e cover_COMMAND
@e css_COMMAND
@e ifiction_COMMAND
@e ifiction_public_COMMAND
@e ifiction_file_COMMAND
@e interpreter_COMMAND
@e palette_COMMAND
@e palette_16_bit_COMMAND
@e palette_32_bit_COMMAND
@e picture_scaled_COMMAND
@e picture_COMMAND
@e picture_text_COMMAND
@e picture_noid_COMMAND
@e picture_with_alt_text_COMMAND
@e placeholder_COMMAND
@e project_folder_COMMAND
@e release_COMMAND
@e release_file_COMMAND
@e release_file_from_COMMAND
@e release_source_COMMAND
@e release_to_COMMAND
@e resolution_max_COMMAND
@e resolution_min_max_COMMAND
@e resolution_min_COMMAND
@e resolution_COMMAND
@e solution_COMMAND
@e solution_public_COMMAND
@e sound_music_COMMAND
@e sound_repeat_COMMAND
@e sound_forever_COMMAND
@e sound_song_COMMAND
@e sound_COMMAND
@e sound_text_COMMAND
@e sound_noid_COMMAND
@e sound_with_alt_text_COMMAND
@e source_COMMAND
@e source_public_COMMAND
@e status_COMMAND
@e status_alternative_COMMAND
@e status_instruction_COMMAND
@e storyfile_include_COMMAND
@e storyfile_COMMAND
@e storyfile_leafname_COMMAND
@e template_path_COMMAND
@e website_COMMAND

@ A single number specifying various possible combinations of operands. For
example, |NT_OPS| means "number, text". Clearly the list below is not
exhaustive of the possibilities, but these are the only ones arising for
Blurb commands.

@e VOID_OPS from 1
@e N_OPS
@e NN_OPS
@e NNN_OPS
@e NT_OPS
@e NTN_OPS
@e NTT_OPS
@e T_OPS
@e TT_OPS
@e TTN_OPS
@e TTT_OPS

@ Each legal command syntax is stored as one of these structures.

=
typedef struct blurb_command {
	char *explicated; /* plain English form of the command */
	wchar_t *prototype; /* regular expression prototype */
	int operands; /* one of the above |*_OPS| codes */
	int deprecated;
} blurb_command;

@ And here they all are. They are tested in the sequence given, and
the sequence must exactly match the numbering of the |*_COMMAND|
values above, since those are indexes into this table.

In blurb syntax, a line whose first non-white-space character is an
exclamation mark |!| is a comment, and is ignored. (This is the I6
comment character, too.) It appears in the table as a command
but, as we shall see, has no effect.

=
blurb_command syntaxes[] = {
	{ "author \"name\"", L"author \"(%q*)\"", T_OPS, FALSE },
	{ "auxiliary \"filename\" \"description\" \"subfolder\"",
			L"auxiliary \"(%q*)\" \"(%q*)\" \"(%q*)\"", TTT_OPS, FALSE },
	{ "base64 \"filename\" to \"filename\"",
			L"base64 \"(%q*)\" to \"(%q*)\"", TT_OPS, FALSE },
	{ "copyright \"message\"", L"copyright \"(%q*)\"", T_OPS, FALSE },
	{ "cover \"filename\"", L"cover \"(%q*)\"", T_OPS, FALSE },
	{ "css", L"css", VOID_OPS, FALSE },
	{ "ifiction", L"ifiction", VOID_OPS, FALSE },
	{ "ifiction public", L"ifiction public", VOID_OPS, FALSE },
	{ "ifiction \"filename\" include", L"ifiction \"(%q*)\" include", T_OPS, FALSE },
	{ "interpreter \"interpreter-name\" \"vm-letter\"",
			L"interpreter \"(%q*)\" \"([gz])\"", TT_OPS, FALSE },
	{ "palette { details }", L"palette {(%c*?)}", T_OPS, TRUE },
	{ "palette 16 bit", L"palette 16 bit", VOID_OPS, TRUE },
	{ "palette 32 bit", L"palette 32 bit", VOID_OPS, TRUE },
	{ "picture ID \"filename\" scale ...",
			L"picture (%i+?) \"(%q*)\" scale (%c*)", TTT_OPS, TRUE },
	{ "picture N \"filename\"", L"picture (%d+) \"(%q*)\"", NT_OPS, FALSE },
	{ "picture ID \"filename\"", L"picture (%i+) \"(%q*)\"", TT_OPS, FALSE },
	{ "picture \"filename\"", L"picture \"(%q*)\"", T_OPS, FALSE },
	{ "picture N \"filename\" \"alt-text\"", L"picture %d \"(%q*)\" \"(%q*)\"", NTT_OPS, FALSE },
	{ "placeholder [name] = \"text\"", L"placeholder %[(%C+)%] = \"(%q*)\"", TT_OPS, FALSE },
	{ "project folder \"pathname\"", L"project folder \"(%q*)\"", T_OPS, FALSE },
	{ "release \"text\"", L"release \"(%q*)\"", T_OPS, FALSE },
	{ "release file \"filename\"", L"release file \"(%q*)\"", T_OPS, FALSE },
	{ "release file \"filename\" from \"template\"",
			L"release file \"(%q*)\" from \"(%q*)\"", TT_OPS, FALSE },
	{ "release source \"filename\" using \"filename\" from \"template\"",
			L"release source \"(%q*)\" using \"(%q*)\" from \"(%q*)\"", TTT_OPS, FALSE },
	{ "release to \"pathname\"", L"release to \"(%q*)\"", T_OPS, FALSE },
	{ "resolution NxN max NxN", L"resolution (%d+) max (%d+)", NN_OPS, TRUE },
	{ "resolution NxN min NxN max NxN", L"resolution (%d+) min (%d+) max (%d+)", NNN_OPS, TRUE },
	{ "resolution NxN min NxN", L"resolution (%d+) min (%d+)", NN_OPS, TRUE },
	{ "resolution NxN", L"resolution (%d+)", N_OPS, TRUE },
	{ "solution", L"solution", VOID_OPS, FALSE },
	{ "solution public", L"solution public", VOID_OPS, FALSE },
	{ "sound ID \"filename\" music", L"sound (%i+) \"(%q*)\" music", TT_OPS, TRUE },
	{ "sound ID \"filename\" repeat N",
			L"sound (%i+) \"(%q*)\" repeat (%d+)", TTN_OPS, TRUE },
	{ "sound ID \"filename\" repeat forever",
			L"sound (%i+) \"(%q*)\" repeat forever", TT_OPS, TRUE },
	{ "sound ID \"filename\" song", L"sound (%i+) \"(%q*)\" song", TT_OPS, TRUE },
	{ "sound N \"filename\"", L"sound (%d+) \"(%q*)\"", NT_OPS, FALSE },
	{ "sound ID \"filename\"", L"sound (%i+) \"(%q*)\"", TT_OPS, FALSE },
	{ "sound \"filename\"", L"sound \"(%q*)\"", T_OPS, FALSE },
	{ "sound N \"filename\" \"alt-text\"", L"sound (%d+) \"(%q*)\" \"(%q*)\"", NTT_OPS, FALSE },
	{ "source", L"source", VOID_OPS, FALSE },
	{ "source public", L"source public", VOID_OPS, FALSE },
	{ "status \"template\" \"filename\"", L"status \"(%q*)\" \"(%q*)\"", TT_OPS, FALSE },
	{ "status alternative ||link to Inform documentation||",
			L"status alternative ||(%c*)||", T_OPS, FALSE },
	{ "status instruction ||link to Inform source text||",
			L"status instruction ||(%c*)||", T_OPS, FALSE },
	{ "storyfile \"filename\" include", L"storyfile \"(%q*)\" include", T_OPS, FALSE },
	{ "storyfile \"filename\"", L"storyfile \"(%q*)\"", T_OPS, TRUE },
	{ "storyfile leafname \"leafname\"", L"storyfile leafname \"(%q*)\"", T_OPS, FALSE },
	{ "template path \"folder\"", L"template path \"(%q*)\"", T_OPS, FALSE },
	{ "website \"template\"", L"website \"(%q*)\"", T_OPS, FALSE },
	{ NULL, NULL, VOID_OPS, FALSE }
};

@h Summary.
For the |-help| information:

=
void Parser::summarise_blurb(void) {
	PRINT("\nThe blurbfile is a script of commands, one per line, in these forms:\n");
	for (int t=0; syntaxes[t].prototype; t++)
		if (syntaxes[t].deprecated == FALSE)
			PRINT("  %s\n", syntaxes[t].explicated);
	PRINT("\nThe following syntaxes, though legal in Blorb 2001, are not supported:\n");
	for (int t=0; syntaxes[t].prototype; t++)
		if (syntaxes[t].deprecated == TRUE)
			PRINT("  %s\n", syntaxes[t].explicated);
}

@h The interpreter.
The following routine is called for each line of the blurb file in sequence,
including any blank lines.

=
void Parser::interpret_line(text_stream *command, text_file_position *tf, void *state) {
	BlorbErrors::set_error_position(tf);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, command, L" *(%c*?) *")) Str::copy(command, mr.exp[0]);
	if (Str::len(command) == 0) return; /* thus skip a line containing only blank space */
	if (Str::get_first_char(command) == '!') return; /* thus skip a comment line */

	if (verbose_mode) PRINT("! %03d: %S\n", TextFiles::get_line_count(tf), command);

	int num1 = 0, num2 = 0, num3 = 0, outcome = -1; /* which of the legal command syntaxes is used */
	TEMPORARY_TEXT(text1);
	TEMPORARY_TEXT(text2);
	TEMPORARY_TEXT(text3);
	@<Parse the command and set operands appropriately@>;
	@<Take action on the command@>;
	DISCARD_TEXT(text1);
	DISCARD_TEXT(text2);
	DISCARD_TEXT(text3);
	Regexp::dispose_of(&mr);
}

@ Here we set |outcome| to the index in the syntaxes table of the line matched,
or leave it as $-1$ if no match can be made. Text and number operands are
copied in |text1|, |num1|, ..., accordingly.

@<Parse the command and set operands appropriately@> =
	for (int t=0; syntaxes[t].prototype; t++)
		if (Regexp::match(&mr, command, syntaxes[t].prototype)) {
			switch (syntaxes[t].operands) {
				case VOID_OPS: break;
				case T_OPS:		Str::copy(text1, mr.exp[0]); break;
				case TT_OPS:	Str::copy(text1, mr.exp[0]);
								Str::copy(text2, mr.exp[1]); break;
				case TTN_OPS:	Str::copy(text1, mr.exp[0]);
								Str::copy(text2, mr.exp[1]);
								num1 = Str::atoi(mr.exp[2], 0); break;
				case N_OPS:		num1 = Str::atoi(mr.exp[0], 0); break;
				case NN_OPS:	num1 = Str::atoi(mr.exp[0], 0);
								num2 = Str::atoi(mr.exp[1], 0); break;
				case NT_OPS:	num1 = Str::atoi(mr.exp[0], 0);
								Str::copy(text1, mr.exp[1]); break;
				case NTT_OPS:	num1 = Str::atoi(mr.exp[0], 0);
								Str::copy(text1, mr.exp[1]);
								Str::copy(text2, mr.exp[2]); break;
				case NTN_OPS:	num1 = Str::atoi(mr.exp[0], 0);
								Str::copy(text1, mr.exp[1]);
								num2 = Str::atoi(mr.exp[2], 0); break;
				case NNN_OPS:	num1 = Str::atoi(mr.exp[0], 0);
								num2 = Str::atoi(mr.exp[1], 0);
								num3 = Str::atoi(mr.exp[2], 0); break;
				case TTT_OPS:	Str::copy(text1, mr.exp[0]);
								Str::copy(text2, mr.exp[1]);
								Str::copy(text3, mr.exp[2]); break;
				default:		internal_error("unknown operand type");
			}
			outcome = t; break;
		}

	if (outcome == -1) {
		BlorbErrors::error_1S("not a valid blurb command", command);
		return;
	}
	if (syntaxes[outcome].deprecated) {
		BlorbErrors::error_1("this Blurb syntax is no longer supported",
			syntaxes[outcome].explicated);
		return;
	}

@ The command is now fully parsed, and is one that we support. We can act.

@<Take action on the command@> =
	switch (outcome) {
		case author_COMMAND:
			Placeholders::set_to(I"AUTHOR", text1, 0);
			Writer::author_chunk(text1);
			break;
		case auxiliary_COMMAND: Links::create_auxiliary_file(text1, text2, text3); break;
		case base64_COMMAND:
			Requests::request_2(BASE64_REQ, text1, text2, FALSE); break;
		case copyright_COMMAND: Writer::copyright_chunk(text1); break;
		case cover_COMMAND: @<Declare which file is the cover art@>; break;
		case css_COMMAND: use_css_code_styles = TRUE; break;
		case ifiction_file_COMMAND: Writer::metadata_chunk(Filenames::from_text(text1)); break;
		case ifiction_COMMAND: Requests::request_1(IFICTION_REQ, I"", TRUE); break;
		case ifiction_public_COMMAND: Requests::request_1(IFICTION_REQ, I"", FALSE); break;
		case interpreter_COMMAND:
			Placeholders::set_to(I"INTERPRETERVMIS", text2, 0);
			Requests::request_1(INTERPRETER_REQ, text1, FALSE); break;
		case picture_COMMAND: Writer::picture_chunk(num1, Filenames::from_text(text1), I""); break;
		case picture_text_COMMAND: Writer::picture_chunk_text(text1, Filenames::from_text(text2)); break;
		case picture_noid_COMMAND: Writer::picture_chunk_text(I"", Filenames::from_text(text1)); break;
		case picture_with_alt_text_COMMAND: Writer::picture_chunk(num1, Filenames::from_text(text1), text2); break;
		case placeholder_COMMAND: Placeholders::set_to(text1, text2, 0); break;
		case project_folder_COMMAND: project_folder = Pathnames::from_text(text1); break;
		case release_COMMAND:
			Placeholders::set_to_number(I"RELEASE", num1);
			Writer::release_chunk(num1);
			break;
		case release_file_COMMAND: {
			filename *to_release = Filenames::from_text(text1);
			TEMPORARY_TEXT(leaf);
			WRITE_TO(leaf, "%S", Filenames::get_leafname(to_release));
			Requests::request_3(COPY_REQ, text1, leaf, I"--", FALSE);
			DISCARD_TEXT(leaf);
			break;
		}
		case release_file_from_COMMAND:
			Requests::request_2(RELEASE_FILE_REQ, text1, text2, FALSE); break;
		case release_to_COMMAND:
			release_folder = Pathnames::from_text(text1);
			@<Make pathname placeholders in three different formats@>;
			break;
		case release_source_COMMAND:
			Requests::request_3(RELEASE_SOURCE_REQ, text1, text2, text3, FALSE); break;
		case solution_COMMAND: Requests::request_1(SOLUTION_REQ, I"", TRUE); break;
		case solution_public_COMMAND: Requests::request_1(SOLUTION_REQ, I"", FALSE); break;
		case sound_COMMAND: Writer::sound_chunk(num1, Filenames::from_text(text1), I""); break;
		case sound_text_COMMAND: Writer::sound_chunk_text(text1, Filenames::from_text(text2)); break;
		case sound_noid_COMMAND: Writer::sound_chunk_text(I"", Filenames::from_text(text1)); break;
		case sound_with_alt_text_COMMAND: Writer::sound_chunk(num1, Filenames::from_text(text1), text2); break;
		case source_COMMAND: Requests::request_1(SOURCE_REQ, I"", TRUE); break;
		case source_public_COMMAND: Requests::request_1(SOURCE_REQ, I"", FALSE); break;
		case status_COMMAND:
			status_template = Filenames::from_text(text1);
			status_file = Filenames::from_text(text2);
			break;
		case status_alternative_COMMAND: Requests::request_1(ALTERNATIVE_REQ, text1, FALSE); break;
		case status_instruction_COMMAND: Requests::request_1(INSTRUCTION_REQ, text1, FALSE); break;
		case storyfile_include_COMMAND: Writer::executable_chunk(Filenames::from_text(text1)); break;
		case storyfile_leafname_COMMAND: Placeholders::set_to(I"STORYFILE", text1, 0); break;
		case template_path_COMMAND: Templates::new_path(Pathnames::from_text(text1)); break;
		case website_COMMAND: Requests::request_1(WEBSITE_REQ, text1, FALSE); break;

		default: BlorbErrors::error_1S("***", command); BlorbErrors::fatal("*** command unimplemented ***\n");
	}

@ We only ever set the frontispiece as resource number 1, since Inform
has the assumption that the cover art is image number 1 built in.

@<Declare which file is the cover art@> =
	Placeholders::set_to(I"BIGCOVER", text1, 0);
	cover_exists = TRUE;
	cover_is_in_JPEG_format = FALSE;
	filename *cover_filename = Filenames::from_text(text1);
	if (Filenames::guess_format(cover_filename) == FORMAT_PERHAPS_JPEG)
		cover_is_in_JPEG_format = TRUE;
	Writer::frontispiece_chunk(1);
	if (Str::eq_wide_string(Filenames::get_leafname(cover_filename), L"DefaultCover.jpg"))
		default_cover_used = TRUE;
	Placeholders::set_to(I"SMALLCOVER", text1, 0);

@ Here, |text1| is the pathname of the Release folder. If we suppose that
Inblorb is being run from Inform, then this folder is a subfolder of the
Materials folder for an I7 project. It follows that we can obtain the
pathname to the Materials folder by trimming the leaf and the final separator.
That makes the |MATERIALSFOLDERPATH| placeholder. We then set |MATERIALSFOLDER|
to the name of the Materials folder, e.g., "Spaceman Spiff Materials".

However, we also need two variants on the pathname, one to be supplied to the
Javascript function |openUrl| and one to |fileUrl|. For platform dependency
reasons these need to be manipulated to deal with awkward characters.

@<Make pathname placeholders in three different formats@> =
	pathname *Release = Pathnames::from_text(text1);
	pathname *Materials = Pathnames::up(Release);

	TEMPORARY_TEXT(as_txt);
	WRITE_TO(as_txt, "%p", Materials);
	Placeholders::set_to(I"MATERIALSFOLDERPATH", as_txt, 0);
	DISCARD_TEXT(as_txt);

	Placeholders::set_to(I"MATERIALSFOLDER",
		Pathnames::directory_name(Materials), 0);

	Parser::qualify_placeholder(
		I"MATERIALSFOLDERPATHOPEN",
		I"MATERIALSFOLDERPATHFILE",
		I"MATERIALSFOLDERPATH");

@ And here that very "qualification" routine. The placeholder |original| contains
the pathname to a folder, a pathname which might contain spaces or backslashes,
and which needs to be quoted as a literal Javascript string supplied to
either the function |openUrl| or the function |fileUrl|. Depending on the
platform in use, this may entail escaping spaces or reversing slashes in the
pathname in order to make versions for these two functions to use.

=
void Parser::qualify_placeholder(text_stream *openUrl_path, text_stream *fileUrl_path,
	text_stream *original) {
	text_stream *OU = Placeholders::read(openUrl_path);
	text_stream *FU = Placeholders::read(fileUrl_path);
	LOOP_THROUGH_TEXT(P, original) {
		int c = Str::get(P);
		if (c == ' ') {
			if (escape_openUrl) WRITE_TO(OU, "%%2520");
			else PUT_TO(OU, c);
			if (escape_fileUrl) WRITE_TO(FU, "%%2520");
			else PUT_TO(FU, c);
		} else if (c == '\\') {
			if (reverse_slash_openUrl) PUT_TO(OU, '/');
			else PUT_TO(OU, c);
			if (reverse_slash_fileUrl) PUT_TO(FU, '/');
			else PUT_TO(FU, c);
		} else {
			PUT_TO(OU, c);
			PUT_TO(FU, c);
		}
	}
}
